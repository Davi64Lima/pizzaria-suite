# Monitoramento (local, via SSH)

Painéis de status do servidor, **todos amarrados em `127.0.0.1`** — nada é exposto à
internet nem passa pela Cloudflare. Você acessa por um túnel SSH a partir do seu
computador.

| Painel | Para quê | Porta local |
|---|---|---|
| Portainer | Gerenciar containers (restart, imagens, volumes) | 9000 |
| Netdata | Métricas: CPU, RAM, disco, rede (tempo real + histórico) | 19999 |
| Uptime Kuma | Uptime dos serviços + alertas | 3005 |
| Dozzle | Logs ao vivo dos containers | 8888 |

## Subir (no servidor, como `deploy`)

```bash
cd ~/pizzaria-suite/monitoring
docker compose up -d
docker compose ps
```

## Acessar (do seu computador)

Abre o túnel SSH (deixa esse terminal aberto enquanto usa):

```bash
ssh -N \
  -L 9000:localhost:9000 \
  -L 19999:localhost:19999 \
  -L 3005:localhost:3005 \
  -L 8888:localhost:8888 \
  deploy@188.245.46.53
```

Depois, no navegador:

- Portainer → http://localhost:9000  (na 1ª vez cria o usuário admin em até 5 min)
- Netdata → http://localhost:19999
- Uptime Kuma → http://localhost:3005
- Dozzle → http://localhost:8888

## Configurar o Uptime Kuma

Na UI, adicione monitores HTTP(s) para os serviços — o caminho mais simples é
apontar para as URLs públicas (que passam pela Cloudflare, testando a ponta a ponta):

- `https://api.SEU_DOMINIO/health`  (back)
- `https://admin.SEU_DOMINIO`       (front)

Configure notificação (Telegram, e-mail, Slack...) em Settings → Notifications
para ser avisado quando algo cair.

## Parar / atualizar

```bash
cd ~/pizzaria-suite/monitoring
docker compose pull && docker compose up -d   # atualizar
docker compose down                           # parar (mantém os volumes/dados)
```

## Notas

- Projeto Docker separado (`pizzaria-monitoring`): o deploy do CI do suite não mexe aqui.
- Consumo aproximado: ~400 MB de RAM no total. Confira em `docker stats`.
- Como o firewall da Hetzner só libera a porta 22, mesmo que algo escutasse em
  `0.0.0.0` estaria bloqueado — mas aqui já amarramos tudo em `127.0.0.1` por garantia.
