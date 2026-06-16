#!/bin/bash

# Diretório do projeto na VM (CI e scripts usam o mesmo caminho).
DEFAULT_REPO_DIR="/home/univates/gerencia"

docker_cmd() {
  if docker info >/dev/null 2>&1; then
    docker "$@"
  else
    sudo docker "$@"
  fi
}

resolve_repo_dir() {
  if [ -n "${REPO_DIR:-}" ]; then
    echo "$REPO_DIR"
    return
  fi

  for candidate in "$DEFAULT_REPO_DIR" "$HOME/gerencia" "$HOME/projeto"; do
    if [ -d "$candidate" ]; then
      echo "$candidate"
      return
    fi
  done

  echo "$DEFAULT_REPO_DIR"
}

compose_down_all() {
  local dir="$1"
  [ -d "$dir" ] || return 0
  cd "$dir"

  for file in docker-compose.homolog.yml docker-compose.prod.yml docker-compose.yml; do
    if [ -f "$file" ]; then
      docker_cmd compose -f "$file" down --volumes --remove-orphans 2>/dev/null || true
    fi
  done
}

stop_gerencia_containers() {
  local ids
  ids="$(docker_cmd ps -aq --filter "name=gerencia_" 2>/dev/null || true)"
  if [ -n "$ids" ]; then
    docker_cmd rm -f $ids 2>/dev/null || true
  fi
}

remove_gerencia_images() {
  docker_cmd images --format "{{.Repository}}:{{.Tag}} {{.ID}}" 2>/dev/null \
    | grep -iE "gerencia|projeto-app|flyway" \
    | awk '{print $2}' \
    | xargs -r docker_cmd rmi -f 2>/dev/null || true
}
