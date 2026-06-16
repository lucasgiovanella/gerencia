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

echo -e "\n${YELLOW}[1/4] Criando diretório e clonando repositório...${CLEAR}"
echo -e "  Destino: ${BLUE}$REPO_DIR${CLEAR}"
if [ -d "$REPO_DIR/.git" ]; then
  echo -e "  Repositório já existe. Atualizando código..."
else
  echo -e "  Clonando ${BLUE}$REPO_URL${CLEAR}..."
fi
ensure_repo_dir "$REPO_DIR"
cd "$REPO_DIR"
echo -e "  ${GREEN}✓ Repositório pronto em $REPO_DIR${CLEAR}"

echo -e "\n${YELLOW}[2/4] Configurando ambiente (.env)...${CLEAR}"
if [ ! -f .env ]; then
  if [ -f .env.example ]; then
    cp .env.example .env
  else
    cat > .env <<'EOF'
DB_HOST=db
DB_PORT=5432
DB_NAME=gerencia_db
DB_USER=postgres
DB_PASS=postgres
EOF
  fi
  echo -e "  ${GREEN}✓ .env criado${CLEAR}"
else
  echo -e "  ${GREEN}✓ .env já existente${CLEAR}"
fi

compose_up() {
  local env_name="$1"
  local compose_file="$2"
  local port="$3"

  echo -e "\n${YELLOW}Subindo ${env_name}...${CLEAR}"
  echo -e "  Arquivo: ${BLUE}$compose_file${CLEAR}"
  echo -e "  Porta:   ${BLUE}$port${CLEAR}"

  if ! docker_cmd compose -f "$compose_file" up -d --build; then
    echo -e "${RED}Falha ao subir ${env_name}.${CLEAR}"
    docker_cmd compose -f "$compose_file" ps -a || true
    docker_cmd compose -f "$compose_file" logs --tail=50 || true
    exit 1
  fi

  echo -e "  ${GREEN}✓ ${env_name} no ar${CLEAR}"
}

echo -e "\n${YELLOW}[3/4] Build, volumes e containers — Homologação...${CLEAR}"
compose_up "Homologação" "docker-compose.homolog.yml" "3001"

echo -e "\n${YELLOW}[4/4] Build, volumes e containers — Produção...${CLEAR}"
compose_up "Produção" "docker-compose.prod.yml" "3002"

HOMOLOG_URL="http://${VM_PUBLIC_IP}:3001"
PROD_URL="http://${VM_PUBLIC_IP}:3002"

echo -e "\n${GREEN}================================================================${CLEAR}"
echo -e "${GREEN}             SETUP CONCLUÍDO COM SUCESSO!                       ${CLEAR}"
echo -e "${GREEN}================================================================${CLEAR}"

echo -e "\n${YELLOW}Containers ativos:${CLEAR}"
docker_cmd ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "NAMES|gerencia_" || docker_cmd ps

echo -e "\n${YELLOW}Imagens criadas:${CLEAR}"
docker_cmd images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | grep -E "REPOSITORY|gerencia" || docker_cmd images | head -5

echo -e "\n${YELLOW}Volumes criados:${CLEAR}"
docker_cmd volume ls | grep -iE "gerencia|pgdata" || echo "  (nenhum volume nomeado encontrado)"

echo -e "\n${YELLOW}Acesso à aplicação:${CLEAR}"
echo -e "  ${BLUE}Homologação:${CLEAR} $HOMOLOG_URL"
echo -e "  ${BLUE}Produção:${CLEAR}    $PROD_URL"
echo -e "\n${YELLOW}Login do sistema:${CLEAR} ${GREEN}admin${CLEAR} / ${GREEN}admin123${CLEAR}"
echo -e "================================================================\n"
