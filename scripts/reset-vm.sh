#!/bin/bash
set -e

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CLEAR='\033[0m'

echo -e "${RED}================================================================${CLEAR}"
echo -e "${RED}   RESET COMPLETO DA VM — Gerência de Configuração de Software  ${CLEAR}"
echo -e "${RED}   Isso vai apagar TUDO relacionado ao projeto                  ${CLEAR}"
echo -e "${RED}================================================================${CLEAR}"

# Confirmação obrigatória
echo -e "\n${YELLOW}Tem certeza? Isso apaga containers, volumes, imagens e o repositório.${CLEAR}"
read -p "Digite RESETAR para confirmar: " confirmacao

if [ "$confirmacao" != "RESETAR" ]; then
  echo -e "${GREEN}Cancelado. Nada foi alterado.${CLEAR}"
  exit 0
fi

echo -e "\n${YELLOW}[1/5] Derrubando containers do projeto...${CLEAR}"
REPO_DIR="$HOME/projeto"

if [ -d "$REPO_DIR" ]; then
  cd "$REPO_DIR"

  # Derruba cada ambiente se existir
  if [ -f docker-compose.homolog.yml ]; then
    sudo docker compose -f docker-compose.homolog.yml down --volumes --remove-orphans 2>/dev/null || true
    echo -e "  ${GREEN}✓ Homologação derrubada${CLEAR}"
  fi

  if [ -f docker-compose.prod.yml ]; then
    sudo docker compose -f docker-compose.prod.yml down --volumes --remove-orphans 2>/dev/null || true
    echo -e "  ${GREEN}✓ Produção derrubada${CLEAR}"
  fi

  if [ -f docker-compose.yml ]; then
    sudo docker compose down --volumes --remove-orphans 2>/dev/null || true
    echo -e "  ${GREEN}✓ Dev local derrubado${CLEAR}"
  fi
else
  echo -e "  Diretório $REPO_DIR não encontrado. Pulando."
fi

echo -e "\n${YELLOW}[2/5] Removendo imagens Docker do projeto...${CLEAR}"
sudo docker images --format "{{.Repository}} {{.ID}}" | grep -E "gerencia|flyway" | awk '{print $2}' | xargs -r sudo docker rmi -f 2>/dev/null || true
echo -e "  ${GREEN}✓ Imagens removidas${CLEAR}"

echo -e "\n${YELLOW}[3/5] Limpando volumes órfãos...${CLEAR}"
sudo docker volume prune -f 2>/dev/null || true
echo -e "  ${GREEN}✓ Volumes limpos${CLEAR}"

echo -e "\n${YELLOW}[4/5] Removendo o repositório clonado...${CLEAR}"
if [ -d "$REPO_DIR" ]; then
  rm -rf "$REPO_DIR"
  echo -e "  ${GREEN}✓ ~/projeto removido${CLEAR}"
else
  echo -e "  Nada para remover."
fi

echo -e "\n${YELLOW}[5/5] Removendo configuração de sudo sem senha (opcional)...${CLEAR}"
if [ -f /etc/sudoers.d/docker-nopasswd ]; then
  sudo rm -f /etc/sudoers.d/docker-nopasswd
  echo -e "  ${GREEN}✓ Regra sudo removida${CLEAR}"
else
  echo -e "  Nenhuma regra encontrada."
fi

# Status final
echo -e "\n${BLUE}Containers ativos após reset:${CLEAR}"
sudo docker ps --format "table {{.Names}}\t{{.Status}}" 2>/dev/null || echo "  Nenhum."

echo -e "\n${GREEN}================================================================${CLEAR}"
echo -e "${GREEN}   VM resetada com sucesso. Pronta para demonstração.           ${CLEAR}"
echo -e "${GREEN}================================================================${CLEAR}"
echo -e "\nPróximo passo — rodar o setup do zero:"
echo -e "${BLUE}curl -fsSL https://raw.githubusercontent.com/lucasgiovanella/gerencia/main/scripts/setup-vm.sh | bash${CLEAR}\n"