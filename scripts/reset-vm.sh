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

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CLEAR='\033[0m'

echo -e "${RED}================================================================${CLEAR}"
echo -e "${RED}   RESET COMPLETO DA VM — Gerência de Configuração de Software  ${CLEAR}"
echo -e "${RED}   Isso vai apagar containers, volumes e imagens do projeto     ${CLEAR}"
echo -e "${RED}================================================================${CLEAR}"

confirmar_reset() {
  if [ "${CONFIRM_RESET:-}" = "RESETAR" ]; then
    return 0
  fi

  if [ -t 0 ]; then
    echo -e "\n${YELLOW}Tem certeza? Isso apaga containers, volumes e imagens do projeto.${CLEAR}"
    read -r -p "Digite RESETAR para confirmar: " confirmacao
    [ "$confirmacao" = "RESETAR" ]
    return
  fi

  echo -e "${YELLOW}Sem terminal interativo. Use:${CLEAR}"
  echo -e "  ${BLUE}CONFIRM_RESET=RESETAR curl -fsSL .../reset-vm.sh | bash${CLEAR}"
  return 1
}

if ! confirmar_reset; then
  echo -e "${GREEN}Cancelado. Nada foi alterado.${CLEAR}"
  exit 0
fi

REPO_DIR="$(resolve_repo_dir)"

echo -e "\n${YELLOW}[1/4] Derrubando containers do projeto...${CLEAR}"
for dir in "$REPO_DIR" "$DEFAULT_REPO_DIR" "$HOME/projeto" "$HOME/gerencia"; do
  if [ -d "$dir" ]; then
    echo -e "  Compose down em ${BLUE}$dir${CLEAR}"
    compose_down_all "$dir"
  fi
done
stop_gerencia_containers
echo -e "  ${GREEN}✓ Containers removidos${CLEAR}"

echo -e "\n${YELLOW}[2/4] Removendo imagens Docker do projeto...${CLEAR}"
remove_gerencia_images
echo -e "  ${GREEN}✓ Imagens removidas${CLEAR}"

echo -e "\n${YELLOW}[3/4] Limpando volumes órfãos...${CLEAR}"
docker_cmd volume prune -f 2>/dev/null || true
echo -e "  ${GREEN}✓ Volumes limpos${CLEAR}"

echo -e "\n${YELLOW}[4/4] Status final...${CLEAR}"
echo -e "\n${BLUE}Containers ativos:${CLEAR}"
docker_cmd ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "  Nenhum."

echo -e "\n${GREEN}================================================================${CLEAR}"
echo -e "${GREEN}   VM resetada. Pronta para demonstração.                       ${CLEAR}"
echo -e "${GREEN}================================================================${CLEAR}"
echo -e "\nPróximo passo:"
echo -e "${BLUE}curl -fsSL https://raw.githubusercontent.com/lucasgiovanella/gerencia/main/scripts/setup-vm.sh | bash${CLEAR}\n"
