# Pizzaria Suite

Este projeto é uma aplicação integrada que consiste em três componentes principais: um bot para gerenciar pedidos de pizza, uma interface web para os usuários interagirem com o sistema e um backend que gerencia a lógica de negócios e a comunicação com o banco de dados.

## Estrutura do Projeto

```
pizzaria-suite
├── apps
│   ├── whats-pizza-bot       # Código do bot que gerencia pedidos de pizza
│   ├── pizzaria-front         # Frontend da aplicação
│   └── pizzaria-back          # Backend da aplicação
├── scripts
│   └── dev.sh                 # Script para iniciar os aplicativos
├── package.json               # Configuração do npm
└── README.md                  # Documentação do projeto
```

## Rodando com Docker (recomendado)

1. **Clone com submódulos:**
   ```bash
   git clone --recurse-submodules https://github.com/Davi64Lima/pizzaria-suite.git
   cd pizzaria-suite
   ```

2. **Configure as variáveis:**
   ```bash
   cp .env.example .env
   # edite SHARED_API_KEY, JWT_SECRET, ALLOWED_NUMBERS etc.
   ```

3. **Suba tudo:**
   ```bash
   docker compose up --build -d
   ```

4. **Crie o admin inicial e escaneie o QR do WhatsApp:**
   ```bash
   docker compose exec back npm run seed
   docker compose logs -f bot   # QR code aparece aqui
   ```

Portas: front `:3000` · back `:3001` · bot `:3003`. Banco (SQLite) e sessão do WhatsApp ficam em volumes (`back-data`, `bot-data`, `wwebjs-auth`).

## Rodando sem Docker (dev)

Instale as dependências (`npm install` em cada app), copie os `.env.example` de cada app para `.env` e use:
```bash
./scripts/dev.sh
```

## Componentes do Projeto

- **whats-pizza-bot:** Este componente é responsável por gerenciar os pedidos de pizza. Ele inclui a lógica para gerar e ler um QR code, além de se comunicar com os outros serviços.

- **pizzaria-front:** Este é o frontend da aplicação, onde os usuários podem interagir com o sistema de pedidos de forma intuitiva.

- **pizzaria-back:** O backend gerencia a lógica de negócios e a comunicação com o banco de dados, garantindo que os pedidos sejam processados corretamente.

## Contribuições

Contribuições são bem-vindas! Sinta-se à vontade para abrir issues ou pull requests para melhorias e correções.