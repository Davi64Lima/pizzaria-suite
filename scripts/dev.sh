#!/bin/bash

# Iniciar o backend
cd apps/pizzaria-back
npm start &

# Iniciar o frontend
cd ../pizzaria-front
npm start &

# Iniciar o bot
cd ../whats-pizza-bot
npm start &

# Aguardar um momento para garantir que os serviços estejam iniciados
sleep 5

# Abrir o frontend no navegador padrão
xdg-open http://localhost:3000  # Altere a porta se necessário

# Manter o script em execução
wait