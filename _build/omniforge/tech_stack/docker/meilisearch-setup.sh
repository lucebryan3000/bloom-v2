#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OMNI_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

if [ -f "${OMNI_ROOT}/lib/common.sh" ]; then
  # shellcheck source=/dev/null
  source "${OMNI_ROOT}/lib/common.sh"
  source "${OMNI_ROOT}/tech_stack/_lib/pkg-install.sh"
else
  log()   { echo "[meilisearch-setup] $*"; }
  warn()  { echo "[meilisearch-setup][WARN] $*" >&2; }
  error() { echo "[meilisearch-setup][ERROR] $*" >&2; exit 1; }
fi

resolve_project_path() {
  local path="$1"
  local base="${PROJECT_ROOT:-${OMNI_ROOT}/..}"
  if [[ "$path" = /* ]]; then
    echo "$path"
  else
    echo "${base%/}/${path#./}"
  fi
}

display_project_path() {
  local abs="$1"
  local base="${PROJECT_ROOT:-${OMNI_ROOT}/..}"
  if [[ "$abs" == "$base"* ]]; then
    echo "./${abs#$base/}"
  else
    echo "$abs"
  fi
}

cd "${INSTALL_DIR}"

########################################
# 1) Install Meilisearch JS client
########################################

log "Installing Meilisearch client…"
pkg_install_dev "meilisearch"

########################################
# 2) Docker service fragment
########################################

SERVICES_DIR="$(resolve_project_path "${DOCKER_SERVICES_DIR:-docker/services}")"
mkdir -p "${SERVICES_DIR}"

MEILI_YML="${SERVICES_DIR}/meilisearch.yml"
MEILI_YML_DISPLAY="$(display_project_path "${MEILI_YML}")"

if [ -f "${MEILI_YML}" ]; then
  warn "Meilisearch docker fragment already exists at ${MEILI_YML_DISPLAY}; skipping."
else
  log "Creating ${MEILI_YML_DISPLAY}…"

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

ENV_FILE="$(secrets_resolve_env_file "${APP_ENV_FILE:-.env}")"
log_step "Ensuring Meilisearch env vars in ${ENV_FILE}"

ensure_env_var "MEILI_HOST" "http://meilisearch:7700" "$ENV_FILE"
ensure_env_var "MEILI_MASTER_KEY" "devkey" "$ENV_FILE"
ensure_env_var "MEILI_PORT" "7700" "$ENV_FILE"

log "Meilisearch setup complete.

To run:

  docker compose -f ${DOCKER_COMPOSE_FILE:-docker-compose.yml} -f ${MEILI_YML_DISPLAY} up -d meilisearch

Web console: http://localhost:7700
"
