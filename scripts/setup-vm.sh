#!/bin/bash
set -e

# Cores para formatação de output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CLEAR='\033[0m'

echo -e "${BLUE}================================================================${CLEAR}"
echo -e "${BLUE}   Setup da VM - Gerência de Configuração de Software (Univates)  ${CLEAR}"
echo -e "${BLUE}================================================================${CLEAR}"

# 1. Atualização do sistema
echo -e "\n${YELLOW}[1/6] Atualizando pacotes do sistema...${CLEAR}"
sudo apt-get update && sudo apt-get upgrade -y

# 2. Instalação de dependências e Docker + Docker Compose
echo -e "\n${YELLOW}[2/6] Instalando dependências e o Docker...${CLEAR}"
sudo apt-get install -y ca-certificates curl gnupg

# Configurando chave GPG do Docker se não existir
if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg
fi

# Adicionando repositório oficial do Docker se não existir
if [ ! -f /etc/apt/sources.list.d/docker.list ]; then
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update
fi

# Instalando pacotes do Docker
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 3. Permissões do Docker para o usuário atual
echo -e "\n${YELLOW}[3/6] Configurando permissões do Docker para o usuário...${CLEAR}"
sudo usermod -aG docker $USER

# 4. Clonagem do Repositório
echo -e "\n${YELLOW}[4/6] Configurando diretório do projeto...${CLEAR}"
REPO_DIR="$HOME/projeto"
REPO_URL="https://github.com/lucasgiovanella/gerencia.git"

if [ -d "$REPO_DIR" ]; then
  echo -e "Diretório $REPO_DIR já existe. Atualizando código via Git..."
  cd "$REPO_DIR"
  git fetch --all
  # Tenta fazer pull, caso contrário avisa
  git pull || echo -e "${YELLOW}Aviso: Não foi possível fazer git pull direto. Verifique a branch local.${CLEAR}"
else
  echo -e "Clonando o repositório $REPO_URL para $REPO_DIR..."
  git clone "$REPO_URL" "$REPO_DIR"
  cd "$REPO_DIR"
fi

# 5. Configuração do ambiente (.env)
echo -e "\n${YELLOW}[5/6] Configurando variáveis de ambiente (.env)...${CLEAR}"
if [ ! -f .env ]; then
  if [ -f .env.example ]; then
    cp .env.example .env
    echo -e "${GREEN}Arquivo .env criado a partir de .env.example.${CLEAR}"
  else
    echo -e "DB_HOST=db\nDB_PORT=5432\nDB_NAME=gerencia_db\nDB_USER=postgres\nDB_PASS=postgres\n" > .env
    echo -e "${GREEN}Arquivo .env básico criado.${CLEAR}"
  fi
else
  echo -e "Arquivo .env já existente. Nenhuma alteração feita."
fi

# 6. Inicialização dos containers de Homologação e Produção
echo -e "\n${YELLOW}[6/6] Subindo ambientes via Docker Compose...${CLEAR}"

echo -e "\n${BLUE}Subindo Homologação (Porta 3001)...${CLEAR}"
sudo docker compose -f docker-compose.homolog.yml up -d --build

echo -e "\n${BLUE}Subindo Produção (Porta 3002)...${CLEAR}"
sudo docker compose -f docker-compose.prod.yml up -d --build

# Resumo Final de Status
echo -e "\n${GREEN}================================================================${CLEAR}"
echo -e "${GREEN}             SETUP CONCLUÍDO COM SUCESSO!                       ${CLEAR}"
echo -e "${GREEN}================================================================${CLEAR}"
echo -e "\nStatus dos Containers:"
sudo docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo -e "\nURLs de acesso:"
echo -e "- ${BLUE}Homologação:${CLEAR} http://localhost:3001"
echo -e "- ${BLUE}Produção:${CLEAR}    http://localhost:3002"

echo -e "\n${YELLOW}Instruções Importantes:${CLEAR}"
echo -e "1. As permissões de grupo do Docker foram adicionadas para o usuário: ${GREEN}$USER${CLEAR}."
echo -e "   Para executar comandos do docker sem 'sudo', faça logout e login novamente na VM."
echo -e "2. Se precisar configurar a chave do Resend (e-mails), edite o arquivo ${BLUE}~/projeto/.env${CLEAR}."
echo -e "================================================================\n"
