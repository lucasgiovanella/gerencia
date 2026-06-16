#!/bin/bash
set -e

COMMON_URL="https://raw.githubusercontent.com/lucasgiovanella/gerencia/main/scripts/common.sh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)"

load_common() {
  if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/common.sh" ]; then
    # shellcheck source=common.sh
    source "$SCRIPT_DIR/common.sh"
    return
  fi
  if [ -f "./scripts/common.sh" ]; then
    # shellcheck source=common.sh
    source "./scripts/common.sh"
    return
  fi
  local tmp
  tmp="$(mktemp)"
  curl -fsSL "$COMMON_URL" -o "$tmp"
  # shellcheck source=/dev/null
  source "$tmp"
  rm -f "$tmp"
}

load_common

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CLEAR='\033[0m'

echo -e "${BLUE}================================================================${CLEAR}"
echo -e "${BLUE}   Setup da VM - Gerência de Configuração de Software (Univates)  ${CLEAR}"
echo -e "${BLUE}================================================================${CLEAR}"

if ! command -v docker >/dev/null 2>&1; then
  echo -e "${RED}Docker não encontrado. Instale o Docker antes de rodar este script.${CLEAR}"
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  echo -e "${RED}Git não encontrado. Instale o Git antes de rodar este script.${CLEAR}"
  exit 1
fi

REPO_DIR="$(resolve_repo_dir)"
REPO_URL="https://github.com/lucasgiovanella/gerencia.git"

echo -e "\n${YELLOW}[1/3] Repositório em ${BLUE}$REPO_DIR${CLEAR}..."

if [ -d "$REPO_DIR/.git" ]; then
  cd "$REPO_DIR"
  git fetch --all
  git pull origin main || git pull || echo -e "${YELLOW}Aviso: git pull falhou. Verifique a branch.${CLEAR}"
elif [ -d "$REPO_DIR" ]; then
  echo -e "${RED}Diretório existe mas não é um repositório Git: $REPO_DIR${CLEAR}"
  exit 1
else
  mkdir -p "$(dirname "$REPO_DIR")"
  git clone "$REPO_URL" "$REPO_DIR"
  cd "$REPO_DIR"
fi

echo -e "\n${YELLOW}[2/3] Configurando .env...${CLEAR}"
if [ ! -f .env ]; then
  if [ -f .env.example ]; then
    cp .env.example .env
    echo -e "${GREEN}.env criado a partir de .env.example.${CLEAR}"
  else
    cat > .env <<'EOF'
DB_HOST=db
DB_PORT=5432
DB_NAME=gerencia_db
DB_USER=postgres
DB_PASS=postgres
EOF
    echo -e "${GREEN}.env básico criado.${CLEAR}"
  fi
else
  echo -e ".env já existente."
fi

compose_up() {
  local env_name="$1"
  local compose_file="$2"

  echo -e "\n${BLUE}Subindo ${env_name} (${compose_file})...${CLEAR}"
  if ! docker_cmd compose -f "$compose_file" up -d --build; then
    echo -e "${RED}Falha ao subir ${env_name}.${CLEAR}"
    docker_cmd compose -f "$compose_file" ps -a || true
    docker_cmd compose -f "$compose_file" logs --tail=50 || true
    exit 1
  fi
}

echo -e "\n${YELLOW}[3/3] Subindo ambientes Docker...${CLEAR}"
compose_up "Homologação (porta 3001)" "docker-compose.homolog.yml"
compose_up "Produção (porta 3002)" "docker-compose.prod.yml"

echo -e "\n${GREEN}================================================================${CLEAR}"
echo -e "${GREEN}             SETUP CONCLUÍDO COM SUCESSO!                       ${CLEAR}"
echo -e "${GREEN}================================================================${CLEAR}"
echo -e "\nContainers:"
docker_cmd ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo -e "\nURLs (VM):"
echo -e "- ${BLUE}Homologação:${CLEAR} http://177.44.248.109:3001"
echo -e "- ${BLUE}Produção:${CLEAR}    http://177.44.248.109:3002"
echo -e "\nLogin: ${GREEN}admin${CLEAR} / ${GREEN}admin123${CLEAR}"
echo -e "================================================================\n"
