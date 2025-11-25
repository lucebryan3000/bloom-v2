#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

if [ -f "${REPO_ROOT}/_build/omniforge/lib/common.sh" ]; then
  # shellcheck source=/dev/null
  source "${REPO_ROOT}/_build/omniforge/lib/common.sh"
else
  log()   { echo "[meilisearch-setup] $*"; }
  warn()  { echo "[meilisearch-setup][WARN] $*" >&2; }
  error() { echo "[meilisearch-setup][ERROR] $*" >&2; exit 1; }
fi

cd "${REPO_ROOT}"

if ! command -v pnpm >/dev/null 2>&1; then
  error "pnpm is not installed or not on PATH. Aborting."
fi

########################################
# 1) Install Meilisearch JS client
########################################

log "Installing Meilisearch client…"
pnpm add meilisearch -D

########################################
# 2) Docker service fragment
########################################

SERVICES_DIR="${REPO_ROOT}/docker/services"
mkdir -p "${SERVICES_DIR}"

MEILI_YML="${SERVICES_DIR}/meilisearch.yml"

if [ -f "${MEILI_YML}" ]; then
  warn "Meilisearch docker fragment already exists at docker/services/meilisearch.yml; skipping."
else
  log "Creating docker/services/meilisearch.yml…"

  cat > "${MEILI_YML}" <<'YAML'
services:
  meilisearch:
    image: getmeili/meilisearch:latest
    container_name: ${COMPOSE_PROJECT_NAME:-app}-meilisearch
    environment:
      MEILI_NO_ANALYTICS: "true"
      MEILI_MASTER_KEY: ${MEILI_MASTER_KEY:-devkey}
    ports:
      - "${MEILI_PORT:-7700}:7700"
    volumes:
      - meili_data:/meili_data
    networks:
      - appnet

volumes:
  meili_data:

networks:
  appnet:
    external: false
YAML
fi

########################################
# 3) Env wiring
########################################

ENV_FILE="${REPO_ROOT}/.env.local"
touch "${ENV_FILE}"

add_env_var() {
  local key="$1"
  local default="$2"

  if grep -q "^${key}=" "${ENV_FILE}"; then
    warn "Env var ${key} already exists in .env.local; leaving as-is."
  else
    echo "${key}=${default}" >> "${ENV_FILE}"
    log "Added ${key} to .env.local"
  fi
}

add_env_var "MEILI_HOST" "http://meilisearch:7700"
add_env_var "MEILI_MASTER_KEY" "devkey"
add_env_var "MEILI_PORT" "7700"

log "Meilisearch setup complete.

To run:

  docker compose -f docker-compose.yml -f docker/services/meilisearch.yml up -d meilisearch

Web console: http://localhost:7700
"
