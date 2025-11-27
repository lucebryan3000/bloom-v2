#!/usr/bin/env bash
#!meta
# id: docker/meilisearch-setup.sh
# name: meilisearch-setup
# phase: 1
# phase_name: Infrastructure & Database
# profile_tags:
#   - tech_stack
#   - docker
# uses_from_omni_config:
#   - ENABLE_MEILI
# uses_from_omni_settings:
#   - PROJECT_ROOT
#   - INSTALL_DIR
# required_vars:
#   - PROJECT_ROOT
#   - INSTALL_DIR
# top_flags:
# dependencies:
#   packages: []
#   dev_packages: []
#!endmeta

set -euo pipefail
#
# Dependencies:
#   - docker
#   - docker compose
#   - getmeili/meilisearch image
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OMNI_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

if [ -f "${OMNI_ROOT}/lib/common.sh" ]; then
  # shellcheck source=/dev/null
  source "${OMNI_ROOT}/lib/common.sh"
  source "${OMNI_ROOT}/tech_stack/_lib/pkg-install.sh"
  if command -v parse_stack_flags >/dev/null 2>&1; then
    parse_stack_flags "$@"
  fi
else
  log()   { echo "[meilisearch-setup] $*"; }
  warn()  { echo "[meilisearch-setup][WARN] $*" >&2; }
  error() { echo "[meilisearch-setup][ERROR] $*" >&2; exit 1; }
  log_skip() { log "$@"; }
  log_step() { log "[STEP] $*"; }
fi

if ! command -v log_skip >/dev/null 2>&1; then
  log_skip() { log "$@"; }
fi
if ! command -v log_step >/dev/null 2>&1; then
  log_step() { log "[STEP] $*"; }
fi

if [[ "${DRY_RUN:-false}" == "true" ]]; then
  log_skip "DRY_RUN: skipping meilisearch-setup"
  exit 0
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
