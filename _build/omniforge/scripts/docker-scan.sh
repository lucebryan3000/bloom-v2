#!/usr/bin/env bash
# =============================================================================
# docker-scan.sh - Read-only scan of Docker artifacts for this project
# =============================================================================
# Reports:
#   - Containers (running + exited)
#   - Images
#   - Volumes
#   - Networks
#   - Bind-mount host directories (esp. under project root)
#   - Compose files and service status
#   - Project-local logs/data dirs (heuristic)
#
# This script is READ-ONLY: it does not remove anything.
# =============================================================================

set -euo pipefail

# Detect project root (git repo if available, otherwise current dir)
if git rev-parse --show-toplevel >/dev/null 2>&1; then
  PROJECT_ROOT="$(git rev-parse --show-toplevel)"
else
  PROJECT_ROOT="$(pwd)"
fi

PROJECT_NAME_DEFAULT="$(basename "$PROJECT_ROOT")"
PROJECT_NAME="${PROJECT_NAME:-$PROJECT_NAME_DEFAULT}"

echo "──────────────────────────────────────────────"
echo "  Docker Artifact Scan for Project: $PROJECT_NAME"
echo "  Project root: $PROJECT_ROOT"
echo "──────────────────────────────────────────────"
echo

# docker availability
if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: docker CLI not found in PATH. Install Docker or adjust PATH."
  exit 1
fi

# docker compose (plugin or standalone)
DOCKER_COMPOSE_CMD=""
if docker compose version >/dev/null 2>&1; then
  DOCKER_COMPOSE_CMD="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
  DOCKER_COMPOSE_CMD="docker-compose"
fi

join_by() { local IFS="$1"; shift; echo "$*"; }

# 1) Containers
echo "① Containers (running + exited)"
echo "───────────────────────────────"
CONTAINER_IDS=()
while IFS= read -r cid; do CONTAINER_IDS+=("$cid"); done < <(
  docker ps -a --format '{{.ID}} {{.Names}} {{.Labels}}' \
    | grep -i "$PROJECT_NAME" \
    | awk '{print $1}'
)
if [ "${#CONTAINER_IDS[@]}" -eq 0 ]; then
  echo "No containers found matching project name '$PROJECT_NAME'."
else
  echo "Containers related to '$PROJECT_NAME':"
  docker ps -a --format '  - {{.ID}}  {{.Names}}  ({{.Status}})' \
    | grep -i "$PROJECT_NAME" || true
fi
echo

# 2) Images
echo "② Images"
echo "────────"
IMAGE_IDS=()
while IFS= read -r iid; do IMAGE_IDS+=("$iid"); done < <(
  docker images --format '{{.ID}} {{.Repository}}:{{.Tag}}' \
    | grep -i "$PROJECT_NAME" \
    | awk '{print $1}'
)
if [ "${#IMAGE_IDS[@]}" -eq 0 ]; then
  echo "No images found matching project name '$PROJECT_NAME'."
else
  echo "Images related to '$PROJECT_NAME':"
  docker images --format '  - {{.Repository}}:{{.Tag}}  ({{.ID}})  {{.Size}}' \
    | grep -i "$PROJECT_NAME" || true
fi
echo

# 3) Volumes
echo "③ Volumes"
echo "─────────"
VOLUME_NAMES=()
while IFS= read -r vname; do VOLUME_NAMES+=("$vname"); done < <(
  docker volume ls --format '{{.Name}}' | grep -i "$PROJECT_NAME" || true
)
if [ "${#VOLUME_NAMES[@]}" -eq 0 ]; then
  echo "No volumes found matching project name '$PROJECT_NAME'."
else
  echo "Named volumes related to '$PROJECT_NAME':"
  for v in "${VOLUME_NAMES[@]}"; do
    echo "  - $v"
    docker volume inspect "$v" 2>/dev/null | sed 's/^/      /' | head -n 10
  done
fi
echo

# 4) Networks
echo "④ Networks"
echo "──────────"
NETWORK_NAMES=()
while IFS= read -r nname; do NETWORK_NAMES+=("$nname"); done < <(
  docker network ls --format '{{.Name}}' | grep -i "$PROJECT_NAME" || true
)
if [ "${#NETWORK_NAMES[@]}" -eq 0 ]; then
  echo "No docker networks found matching project name '$PROJECT_NAME'."
else
  echo "Networks related to '$PROJECT_NAME':"
  for n in "${NETWORK_NAMES[@]}"; do
    echo "  - $n"
    docker network inspect "$n" 2>/dev/null | sed 's/^/      /' | head -n 12
  done
fi
echo

# 5) Bind-mount host paths
echo "⑤ Bind-mount host paths (from containers)"
echo "──────────────────────────────────────────"
BIND_PATHS=()
if [ "${#CONTAINER_IDS[@]}" -eq 0 ]; then
  echo "No project containers detected; skipping bind-mount scan."
else
  for cid in "${CONTAINER_IDS[@]}"; do
    while IFS= read -r src; do BIND_PATHS+=("$src"); done < <(
      docker inspect "$cid" \
        | grep '"Type": "bind"' -n -A 4 \
        | grep '"Source":' \
        | sed -E 's/.*"Source": "([^"]+)".*/\1/' || true
    )
  done
fi
if [ "${#BIND_PATHS[@]}" -eq 0 ]; then
  echo "No bind-mount paths found from project containers."
else
  mapfile -t BIND_PATHS_UNIQ < <(printf "%s\n" "${BIND_PATHS[@]}" | sort -u)
  echo "Bind-mount host paths used by project containers:"
  for p in "${BIND_PATHS_UNIQ[@]}"; do
    prefix="  -"
    if [[ "$p" == "$PROJECT_ROOT"* ]]; then
      prefix="  *"  # highlight paths inside project
    fi
    echo "$prefix $p"
  done
  echo
  echo "(* paths starting with '*' are inside the project root.)"
fi
echo

# 6) Compose info
echo "⑥ Compose / stack files"
echo "───────────────────────"
cd "$PROJECT_ROOT"
COMPOSE_FILES=()
if [ -f "docker-compose.yml" ]; then COMPOSE_FILES+=("docker-compose.yml"); fi
if [ -f "compose.yml" ]; then COMPOSE_FILES+=("compose.yml"); fi
if [ "${#COMPOSE_FILES[@]}" -eq 0 ]; then
  echo "No docker-compose.yml or compose.yml found in project root."
else
  echo "Compose file(s) in project root:"
  for f in "${COMPOSE_FILES[@]}"; do
    echo "  - $PROJECT_ROOT/$f"
  done
  if [ -n "$DOCKER_COMPOSE_CMD" ]; then
    echo
    echo "Compose services (from ${COMPOSE_FILES[0]}):"
    $DOCKER_COMPOSE_CMD ps --all || true
  else
    echo
    echo "NOTE: docker compose / docker-compose not detected, skipping compose status."
  fi
fi
echo

# 7) Project-local logs & data
echo "⑦ Project-local logs & data directories"
echo "───────────────────────────────────────"
LOG_DIRS=()
DATA_DIRS=()
if [ -d "$PROJECT_ROOT/logs" ]; then LOG_DIRS+=("$PROJECT_ROOT/logs"); fi
for candidate in "data" "db_data" "meili_data" "redis_data" "postgres_data"; do
  if [ -d "$PROJECT_ROOT/$candidate" ]; then DATA_DIRS+=("$PROJECT_ROOT/$candidate"); fi
done
if [ "${#LOG_DIRS[@]}" -eq 0 ] && [ "${#DATA_DIRS[@]}" -eq 0 ]; then
  echo "No obvious log or data directories detected under project root."
else
  if [ "${#LOG_DIRS[@]}" -gt 0 ]; then
    echo "Log directories:"
    for d in "${LOG_DIRS[@]}"; do echo "  - $d"; done
  fi
  if [ "${#DATA_DIRS[@]}" -gt 0 ]; then
    echo
    echo "Data directories:"
    for d in "${DATA_DIRS[@]}"; do echo "  - $d"; done
  fi
fi
echo

# 8) Summary
echo "──────────────────────────────────────────────"
echo "Scan complete."
echo "This was a READ-ONLY scan. No containers, images,"
echo "volumes, networks, or files were removed."
echo
echo "Use this report as a guide for what to stop/remove/prune"
echo "after a Docker deploy for: $PROJECT_NAME"
echo "──────────────────────────────────────────────"
