#!/bin/bash

# Diretório do projeto na VM (CI e scripts usam o mesmo caminho).
DEFAULT_REPO_DIR="/home/univates/gerencia"
VM_PUBLIC_IP="${VM_PUBLIC_IP:-177.44.248.109}"
REPO_URL="https://github.com/lucasgiovanella/gerencia.git"

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
  echo "$DEFAULT_REPO_DIR"
}

repo_dir_candidates() {
  local paths=(
    "/home/univates/gerencia"
    "/home/univates/projeto"
    "/root/projeto"
    "/root/gerencia"
  )

  if [ -n "${REPO_DIR:-}" ]; then
    paths+=("$REPO_DIR")
  fi

  paths+=("$HOME/projeto" "$HOME/gerencia")

  printf '%s\n' "${paths[@]}" | awk '!seen[$0]++ && $0 != ""'
}

remove_repo_dir() {
  local dir="$1"

  [ -n "$dir" ] || return 0
  [ -d "$dir" ] || return 0

  chmod -R u+w "$dir" 2>/dev/null || true
  rm -rf -- "$dir" 2>/dev/null || true

  if [ -e "$dir" ]; then
    echo "FALHA:$dir"
    return 1
  fi

  echo "OK:$dir"
}

remove_repo_dirs() {
  local dir result
  cd / || exit 1

  while IFS= read -r dir; do
    result="$(remove_repo_dir "$dir" || true)"
    if [ -n "$result" ]; then
      echo "$result"
    fi
  done < <(repo_dir_candidates)
}

compose_down_all() {
  local dir="$1"
  [ -d "$dir" ] || return 0
  (
    cd "$dir"
    for file in docker-compose.homolog.yml docker-compose.prod.yml docker-compose.yml; do
      if [ -f "$file" ]; then
        docker_cmd compose -f "$file" down --volumes --remove-orphans 2>/dev/null || true
      fi
    done
  )
}

stop_gerencia_containers() {
  local ids
  ids="$(docker_cmd ps -aq --filter "name=gerencia_" 2>/dev/null || true)"
  if [ -n "$ids" ]; then
    # shellcheck disable=SC2086
    docker_cmd rm -f $ids 2>/dev/null || true
  fi

  ids="$(docker_cmd ps -aq --filter "name=projeto" 2>/dev/null || true)"
  if [ -n "$ids" ]; then
    # shellcheck disable=SC2086
    docker_cmd rm -f $ids 2>/dev/null || true
  fi
}

remove_gerencia_images() {
  local ids
  ids="$(docker_cmd images -q --filter "reference=*gerencia*" 2>/dev/null || true)"
  if [ -n "$ids" ]; then
    # shellcheck disable=SC2086
    docker_cmd rmi -f $ids 2>/dev/null || true
  fi

  docker_cmd images --format "{{.Repository}}:{{.Tag}} {{.ID}}" 2>/dev/null \
    | grep -iE "gerencia|projeto-app|flyway" \
    | awk '{print $2}' \
    | xargs -r docker_cmd rmi -f 2>/dev/null || true

  docker_cmd image prune -f 2>/dev/null || true
}

remove_gerencia_volumes() {
  local vols
  vols="$(docker_cmd volume ls -q 2>/dev/null \
    | grep -iE 'gerencia|pgdata_homolog|pgdata_prod|projeto' || true)"
  if [ -n "$vols" ]; then
    # shellcheck disable=SC2086
    docker_cmd volume rm -f $vols 2>/dev/null || true
  fi
  docker_cmd volume prune -f 2>/dev/null || true
}

ensure_repo_dir() {
  local repo_dir="$1"

  if [ -d "$repo_dir/.git" ]; then
    (
      cd "$repo_dir"
      git fetch --all
      git checkout main 2>/dev/null || true
      git pull origin main || git pull || true
    )
    return 0
  fi

  if [ -d "$repo_dir" ]; then
    rm -rf "$repo_dir"
  fi

  mkdir -p "$(dirname "$repo_dir")"
  git clone "$REPO_URL" "$repo_dir"
}
