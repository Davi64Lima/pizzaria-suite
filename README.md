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

## Instruções de Configuração

1. **Clone o repositório:**
   ```bash
   git clone <URL_DO_REPOSITORIO>
   cd pizzaria-suite
   ```

2. **Instale as dependências:**
   Para cada um dos aplicativos, navegue até o diretório correspondente e execute:
   ```bash
   npm install
   ```

3. **Inicie os aplicativos:**
   Utilize o script `dev.sh` para iniciar todos os aplicativos simultaneamente:
   ```bash
   ./scripts/dev.sh
   ```

4. **Acesse a interface web:**
   Após iniciar os aplicativos, a interface do `pizzaria-front` será aberta automaticamente no seu navegador padrão.

## Componentes do Projeto

- **whats-pizza-bot:** Este componente é responsável por gerenciar os pedidos de pizza. Ele inclui a lógica para gerar e ler um QR code, além de se comunicar com os outros serviços.

- **pizzaria-front:** Este é o frontend da aplicação, onde os usuários podem interagir com o sistema de pedidos de forma intuitiva.

- **pizzaria-back:** O backend gerencia a lógica de negócios e a comunicação com o banco de dados, garantindo que os pedidos sejam processados corretamente.

## Contribuições

Contribuições são bem-vindas! Sinta-se à vontade para abrir issues ou pull requests para melhorias e correções.