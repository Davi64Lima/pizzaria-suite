# Deploy — Hetzner Cloud (CAX11) + Cloudflare (free)

Arquitetura:

```
Internet → Cloudflare (DNS, SSL, DDoS, WAF)
              ↓ Cloudflare Tunnel (conexão de SAÍDA do cloudflared)
          Servidor Hetzner: front:3000 · back:3001 · bot:3003 (interno)
```

Nenhuma porta aberta no servidor além do SSH. Substitua `SEU_DOMINIO` pelo seu domínio.

---

## 1. Criar o servidor na Hetzner

[console.hetzner.cloud](https://console.hetzner.cloud) → **New project** (ex: `pizzaria`) → **Add server**:

- **Location:** Falkenstein ou Helsinki (mais baratas; latência não é fator — o tráfego entra pela Cloudflare)
- **Image:** Ubuntu 24.04
- **Type:** **Arm64 (Ampere)** → **CAX11** (2 vCPU, 4 GB, 40 GB) — €5,99/mês
- **Networking:** marque **IPv4** (+ ~€0,60/mês) e IPv6
  - Alternativa: IPv6-only economiza o IPv4 — só se sua internet tiver IPv6 (teste em test-ipv6.com), senão você não acessa o SSH
- **SSH key:** cole sua chave pública
- **Firewall** (grátis, recomendado): crie um com regra inbound única — TCP 22 (SSH). Todo o resto entra pelo túnel
- **Backups** (opcional): +20% (~€1,20/mês) por snapshots automáticos — vale pelo preço
- Nomeie (ex: `pizzaria`) → **Create & Buy now**

Acesse: `ssh root@IP_DO_SERVIDOR`

> Ficou na Oracle free? O guia funciona igual — só o passo 1 muda (VM A1.Flex, usuário `ubuntu`).

## 2. Instalar Docker

```bash
apt update && apt install -y curl git
curl -fsSL https://get.docker.com | sh
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
3. Aba **Public Hostnames**, crie os três:

| Subdomain | Domain | Service |
|---|---|---|
| (vazio / `@`) | SEU_DOMINIO | `http://front:3000` |
| `admin` | SEU_DOMINIO | `http://front:3000` |
| `api` | SEU_DOMINIO | `http://back:3001` |

> `front` e `back` são os nomes dos serviços na rede do Docker Compose — o cloudflared roda dentro dela.
>
> **Loja x Admin:** o apex (`SEU_DOMINIO`) e o `admin.SEU_DOMINIO` batem no mesmo `front`, mas o middleware isola por host: no apex só a **loja** aparece (a raiz `/`), e `admin.` só serve o **painel**. Acessar `/admin` pelo apex redireciona pra loja; acessar a raiz pelo `admin.` cai no painel. Proteja o `admin.` com **Cloudflare Access** por cima disso.

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
# CORS precisa liberar o admin E a loja (apex), separados por vírgula
CORS_ORIGIN=https://admin.SEU_DOMINIO,https://SEU_DOMINIO
ALLOWED_NUMBERS=*
ATTENDANT_NUMBER=55DDDNUMERO
TUNNEL_TOKEN=<token do passo 5>
# Loja: número da pizzaria (com DDI, só dígitos) pro link do WhatsApp
STORE_WHATSAPP_NUMBER=55DDDNUMERO
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
- SSH: criando o servidor com chave SSH, a Hetzner já desativa login por senha; mantenha o firewall só com a porta 22

## Deploy automático (CI/CD)

O workflow `.github/workflows/deploy.yml` (no repo `pizzaria-suite`) faz o deploy sozinho: a cada push na `main` do suite — ou pelo botão **Run workflow** na aba Actions — ele conecta via SSH no servidor e roda `git pull` + `submodule update` + `docker compose up -d --build`.

Fluxo de trabalho passa a ser: commit/push nos apps → bump do ponteiro no suite (`git add apps && git commit && git push`) → o resto acontece sozinho.

### 1. Chave SSH dedicada para o CI

No seu computador, gere um par só para o deploy (sem passphrase):

```bash
ssh-keygen -t ed25519 -C "github-deploy" -f ~/.ssh/pizzaria_deploy -N ""
```

No servidor, autorize a chave pública:

```bash
cat ~/.ssh/pizzaria_deploy.pub | ssh root@IP_DO_SERVIDOR 'cat >> ~/.ssh/authorized_keys'
```

### 2. Usuário dedicado de deploy (não use root)

Rodar CI como `root` é risco desnecessário. Crie um usuário `deploy` com acesso só ao SSH e ao Docker. **Como root:**

```bash
adduser --disabled-password --gecos "" deploy   # sem senha: entra só por chave
usermod -aG docker deploy                        # docker sem sudo

mkdir -p /home/deploy/.ssh
nano /home/deploy/.ssh/authorized_keys           # cole a chave PÚBLICA do CI (pizzaria_deploy.pub)
chown -R deploy:deploy /home/deploy/.ssh
chmod 700 /home/deploy/.ssh
chmod 600 /home/deploy/.ssh/authorized_keys
```

Clone o suite na home do `deploy`. Como o compose fixa `name: pizzaria-suite`, ele controla os **mesmos** containers/volumes já existentes (banco e sessão do WhatsApp preservados):

```bash
cp /root/pizzaria-suite/.env /tmp/.env && chown deploy /tmp/.env   # como root

su - deploy
git config --global credential.helper store
git clone --recurse-submodules https://github.com/Davi64Lima/pizzaria-suite.git
#   usuário: Davi64Lima · senha: PAT (fica salvo, para os submódulos privados)
cp /tmp/.env ~/pizzaria-suite/.env && rm /tmp/.env
cd ~/pizzaria-suite && docker compose --profile prod up -d --build   # valida docker + git
```

### 3. Secrets no GitHub

Em `pizzaria-suite` → **Settings → Secrets and variables → Actions → New repository secret**. Atenção: o campo **Name** é só o nome (ex: `DEPLOY_HOST`); o valor vai no campo de baixo, **sem aspas**.

| Name | Valor |
|---|---|
| `DEPLOY_HOST` | IP do servidor (ex: `188.245.46.53`) |
| `DEPLOY_USER` | `deploy` |
| `DEPLOY_SSH_KEY` | conteúdo de `~/.ssh/pizzaria_deploy` (a chave **privada**, completa) |
| `DEPLOY_PORT` | `22` |

Pronto: dispare o primeiro deploy em **Actions → Deploy → Run workflow** para validar a conexão. O `cd ~/pizzaria-suite` do workflow resolve para `/home/deploy/pizzaria-suite`.
