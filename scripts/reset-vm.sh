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
echo -e "${RED}   Apaga containers, imagens, volumes e diretório do projeto      ${CLEAR}"
echo -e "${RED}================================================================${CLEAR}"

confirmar_reset() {
  if [ "${CONFIRM_RESET:-}" = "RESETAR" ] || [ "${1:-}" = "RESETAR" ] || [ "${1:-}" = "-y" ] || [ "${1:-}" = "--yes" ]; then
    return 0
  fi

  if [ -t 0 ]; then
    echo -e "\n${YELLOW}Isso apaga TUDO do projeto: containers, imagens, volumes e pastas.${CLEAR}"
    read -r -p "Digite RESETAR para confirmar: " confirmacao
    [ "$confirmacao" = "RESETAR" ]
    return
  fi

  echo -e "${YELLOW}Sem terminal interativo. Use:${CLEAR}"
  echo -e "  ${BLUE}curl -fsSL .../reset-vm.sh | CONFIRM_RESET=RESETAR bash${CLEAR}"
  echo -e "  ${BLUE}bash scripts/reset-vm.sh RESETAR${CLEAR}"
  return 1
}

if ! confirmar_reset "$@"; then
  echo -e "${GREEN}Cancelado. Nada foi alterado.${CLEAR}"
  exit 0
fi

REPO_DIR="$(resolve_repo_dir)"

echo -e "\n${YELLOW}[1/5] Derrubando containers...${CLEAR}"
while IFS= read -r dir; do
  if [ -d "$dir" ]; then
    echo -e "  Compose down em ${BLUE}$dir${CLEAR}"
    compose_down_all "$dir"
  fi
done < <(repo_dir_candidates)
stop_gerencia_containers
echo -e "  ${GREEN}✓ Containers removidos${CLEAR}"

echo -e "\n${YELLOW}[2/5] Removendo volumes...${CLEAR}"
remove_gerencia_volumes
echo -e "  ${GREEN}✓ Volumes removidos${CLEAR}"

echo -e "\n${YELLOW}[3/5] Removendo imagens...${CLEAR}"
remove_gerencia_images
echo -e "  ${GREEN}✓ Imagens removidas${CLEAR}"

echo -e "\n${YELLOW}[4/5] Removendo diretórios do projeto...${CLEAR}"
while IFS= read -r removed; do
  echo -e "  ${GREEN}✓ $removed removido${CLEAR}"
done < <(remove_repo_dirs)

if [ -d "$REPO_DIR" ]; then
  echo -e "  ${RED}Aviso: $REPO_DIR ainda existe.${CLEAR}"
else
  echo -e "  ${GREEN}✓ Nenhum diretório do projeto restante${CLEAR}"
fi

echo -e "\n${YELLOW}[5/5] Verificação final...${CLEAR}"
echo -e "\n${BLUE}Containers:${CLEAR}"
if docker_cmd ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null | grep -q gerencia; then
  docker_cmd ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep gerencia || true
else
  echo "  Nenhum container gerencia_* ativo."
fi

echo -e "\n${BLUE}Imagens do projeto:${CLEAR}"
if docker_cmd images 2>/dev/null | grep -qiE "gerencia|projeto-app"; then
  docker_cmd images | grep -iE "gerencia|projeto-app" || true
else
  echo "  Nenhuma imagem do projeto."
fi

echo -e "\n${BLUE}Diretório padrão (${DEFAULT_REPO_DIR}):${CLEAR}"
if [ -d "$DEFAULT_REPO_DIR" ]; then
  echo -e "  ${RED}Ainda existe${CLEAR}"
else
  echo -e "  ${GREEN}Removido${CLEAR}"
fi

echo -e "\n${GREEN}================================================================${CLEAR}"
echo -e "${GREEN}   VM resetada. Pronta para o setup do zero.                    ${CLEAR}"
echo -e "${GREEN}================================================================${CLEAR}"
echo -e "\nPróximo passo:"
echo -e "${BLUE}curl -fsSL https://raw.githubusercontent.com/lucasgiovanella/gerencia/main/scripts/setup-vm.sh | bash${CLEAR}"
echo -e "${BLUE}bash scripts/setup-vm.sh${CLEAR}\n"
