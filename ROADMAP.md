# Roadmap — Pizzaria Suite

> Mapeamento de melhorias e pendências. Gerado em 13/07/2026, após o refactor `admin-only` do front (branch `refactor/admin-only`).

## 🔴 Crítico (segurança)

1. **Endpoints de orders, flavors e upload sem autenticação no back.** Só `products` usa guard. Hoje qualquer pessoa pode listar, alterar status e deletar pedidos direto na API. Aplicar `JwtAuthGuard` em tudo que é administrativo.
2. **`POST /auth/register` aberto.** Qualquer um cria usuário e ganha acesso ao admin. Fechar o endpoint (seed/CLI para criar admin) ou adicionar roles no modelo `User` e restringir.
3. **API REST do bot (porta 3003) sem autenticação.** `/api/messages/send` e `/broadcast` permitem enviar WhatsApp arbitrário para qualquer número. Adicionar API key compartilhada entre front/back e bot.
4. **CORS liberado (`cors: true`)** no back. Restringir à origem do front em produção.

## ⚙️ pizzaria-back

- Adicionar roles (`ADMIN`/`CUSTOMER`) no modelo `User` e guards por role
- `products`, `customer`, `address` e `payment` são `Json` no `Order` — considerar normalizar (relações com `Product`/`Address`) para relatórios e integridade
- Sem paginação em `GET /orders` e `GET /products` — vai degradar com volume
- Sem testes reais (só scaffold do Nest) — priorizar e2e de orders e auth
- Trocar `console.log` por logger estruturado (Logger do Nest ou pino)
- Documentar API com Swagger (`@nestjs/swagger`)
- Garantir que `prisma/dev.db` está fora do versionamento e criar seed (`prisma/seed.ts`) com usuário admin + sabores
- Notificação WhatsApp hoje parte do front (kanban chama o bot) — mover para o back (ao atualizar status, o back chama o bot). Elimina inconsistência se o status for alterado por outra via

## 🖥️ pizzaria-front (pós admin-only)

- `AdminSidebar` tem link para `/admin/settings`, mas a página não existe — criar ou remover o link
- Sem feedback visual de erro/sucesso nas ações do kanban (sonner foi removido junto com a área pública; adicionar toasts se necessário)
- Sem refresh token — sessão expira e o usuário só descobre no 401
- Sem testes de componente/e2e
- `PROJETO-STATUS.md` está desatualizado (descreve a área pública removida) — atualizar ou apagar
- Rodar `npm install` após o refactor para limpar deps removidas do lockfile (keen-slider, js-cookie, sonner, next-themes)

## 🤖 whats-pizza-bot

- **Sessões em memória (`Map`)** — reiniciar o bot perde todas as conversas em andamento. Persistir em arquivo/SQLite/Redis
- **`allowedNumbers` com 1 número hardcoded como fallback** — o bot só atende esse número (modo dev). Definir estratégia de produção (liberar todos + antispam)
- Fluxo "3 - Falar com atendente" só reseta a sessão — não notifica nenhum atendente. Integrar com grupo/numero da equipe
- Parser de itens é rígido (formato `sabor, tamanho, qtd`) — sem tolerância a variações; considerar melhorar matching ou botões/listas do WhatsApp
- Cliente não recebe o **código do pedido** na confirmação (necessário para rastreio) nem o total calculado
- `whatsapp-web.js` é não-oficial (emula o WhatsApp Web): risco de quebra/ban. Avaliar migração para WhatsApp Cloud API oficial
- Sem retry/fila quando o back está fora (hoje só grava em `orders-log.json`)
- Sem testes

## 🔗 Integração & infra

- **Docker Compose** para subir back + front + bot com um comando (o `dev.sh` depende de setup manual)
- **CI (GitHub Actions)** em cada repo: lint + typecheck + testes + build
- Padronizar branch principal (hoje: back=`master`, front=`develop`, bot=`main`)
- Remover `dev copy.db` da raiz da pasta (backup manual solto)
- Rastreio público de pedido foi removido do front — se voltar, o endpoint `GET /orders/:hash` já existe; pode virar página standalone ou consulta via bot (digitar o código no WhatsApp)
- Atualizar README do suite (fluxo de env vars, portas: back 3001, bot 3003, front 3000)

## Sequência sugerida

1. Segurança (guards no back, fechar register, API key no bot, CORS)
2. Back manda notificação de status (tira do front) + código do pedido na confirmação do bot
3. Persistência de sessão do bot + fluxo de atendente
4. Docker Compose + CI
5. Testes (e2e do back primeiro)
6. Normalizar Order + paginação + Swagger
