# Deploy — Oracle Cloud (free) + Cloudflare (free)

Arquitetura:

```
Internet → Cloudflare (DNS, SSL, DDoS, WAF)
              ↓ Cloudflare Tunnel (conexão de SAÍDA do cloudflared)
          VM Oracle: front:3000 · back:3001 · bot:3003 (interno)
```

Nenhuma porta aberta na VM além do SSH. Substitua `SEU_DOMINIO` pelo seu domínio.

---

## 1. Criar a VM na Oracle

Console Oracle → Compute → Instances → **Create instance**:

- **Image:** Ubuntu 24.04 (aarch64)
- **Shape:** `VM.Standard.A1.Flex` — **2 OCPUs / 12 GB RAM** (limite Always Free atual)
- **Boot volume:** 50–100 GB (o free tier dá 200 GB no total)
- **SSH key:** cole sua chave pública
- Rede: pode deixar a VCN padrão. **Não abra portas** além da 22 (default)

> Se der "Out of capacity" no shape A1: tente outro Availability Domain, ou horários alternativos. Persistindo, tente diariamente — a capacidade free é disputada.

Acesse: `ssh ubuntu@IP_DA_VM`

## 2. Instalar Docker

```bash
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker ubuntu
exit   # reconecte para o grupo valer
```

## 3. Clonar o projeto

Os repos `pizzaria-back` e `whats-pizza-bot` são privados. Crie um **fine-grained PAT** no GitHub (Settings → Developer settings → Fine-grained tokens) com acesso **read-only de Contents** aos 3 repos, e:

```bash
git config --global credential.helper store
git clone --recurse-submodules https://github.com/Davi64Lima/pizzaria-suite.git
# usuário: Davi64Lima · senha: o PAT (fica salvo para os próximos pulls)
cd pizzaria-suite
```

## 4. Configurar o domínio na Cloudflare

1. Dashboard Cloudflare → **Add a domain** → informe `SEU_DOMINIO` → plano **Free**
2. No seu registrador (Registro.br etc.), troque os **nameservers** pelos dois que a Cloudflare indicar (propaga em minutos a algumas horas)

## 5. Criar o túnel

1. [Zero Trust](https://one.dash.cloudflare.com) → **Networks → Tunnels → Create a tunnel** → tipo `cloudflared` → nomeie (ex: `pizzaria`)
2. Em "Install and run a connector", escolha **Docker** e copie apenas o **token** (string longa após `--token`)
3. Aba **Public Hostnames**, crie os dois:

| Subdomain | Domain | Service |
|---|---|---|
| `admin` | SEU_DOMINIO | `http://front:3000` |
| `api` | SEU_DOMINIO | `http://back:3001` |

> `front` e `back` são os nomes dos serviços na rede do Docker Compose — o cloudflared roda dentro dela.

## 6. Configurar o `.env`

```bash
cp .env.example .env
nano .env
```

Produção:

```env
SHARED_API_KEY=<openssl rand -hex 32>
JWT_SECRET=<openssl rand -hex 32>
ADMIN_EMAIL=seu@email.com
ADMIN_PASSWORD=<senha forte>
ADMIN_PHONE=55DDDNUMERO
NEXT_PUBLIC_API_BASE_URL=https://api.SEU_DOMINIO
CORS_ORIGIN=https://admin.SEU_DOMINIO
ALLOWED_NUMBERS=*
ATTENDANT_NUMBER=55DDDNUMERO
TUNNEL_TOKEN=<token do passo 5>
```

## 7. Subir tudo

```bash
docker compose --profile prod up -d --build   # primeiro build demora ~5-10 min
docker compose exec back npm run seed          # cria o admin
docker compose logs -f bot                     # escaneie o QR com o WhatsApp da pizzaria
```

QR: WhatsApp → Configurações → Dispositivos conectados → Conectar dispositivo. A sessão fica no volume `wwebjs-auth` (não pede QR de novo em restart).

## 8. Validar

- `https://admin.SEU_DOMINIO` → login com o admin do seed → dashboard e kanban
- Manda mensagem pro WhatsApp da pizzaria → faz um pedido → aparece no kanban
- Arrasta o pedido no kanban → cliente recebe a notificação com o código

## Operação

```bash
# atualizar após novos commits
git pull --recurse-submodules && docker compose --profile prod up -d --build

# logs
docker compose logs -f back|front|bot|cloudflared

# backup do banco (SQLite no volume back-data)
docker compose exec back sh -c "cp /data/dev.db /data/backup-$(date +%F).db"
```

## Hardening opcional (recomendado)

- **Cloudflare Access** na frente de `admin.SEU_DOMINIO` (Zero Trust → Access): exige e-mail autorizado ANTES de chegar na aplicação — grátis até 50 usuários
- Regra WAF de rate limit no endpoint `api.SEU_DOMINIO/auth/login`
- Desativar SSH por senha (`PasswordAuthentication no`) — na Oracle já vem assim por padrão
