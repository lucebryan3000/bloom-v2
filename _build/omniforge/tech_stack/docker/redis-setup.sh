#!/usr/bin/env bash
#!meta
# id: docker/redis-setup.sh
# name: redis-setup
# phase: 0
# phase_name: Project Foundation
# profile_tags:
#   - tech_stack
#   - docker
# uses_from_omni_config:
# uses_from_omni_settings:
#   - APP_ENV_FILE
#   - COMPOSE_PROJECT_NAME
#   - DOCKER_COMPOSE_FILE
#   - DOCKER_SERVICES_DIR
#   - INSTALL_DIR
#   - OMNI_ROOT
#   - PROJECT_ROOT
#   - REDIS_PORT
#   - REDIS_YML
#   - REDIS_YML_DISPLAY
#   - SERVICES_DIR
# top_flags:
#   - --dry-run
#   - --skip-install
#   - --dev-only
#   - --no-dev
#   - --force
#   - --no-verify
# dependencies:
#   packages:
#     -
#   dev_packages:
#     -
#!endmeta

set -euo pipefail
#
# Dependencies:
#   - docker
#   - docker compose
#   - redis:7 image
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OMNI_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Try to load Omniforge common helpers if they exist
if [ -f "${OMNI_ROOT}/lib/common.sh" ]; then
  # shellcheck source=/dev/null
  source "${OMNI_ROOT}/lib/common.sh"
  source "${OMNI_ROOT}/tech_stack/_lib/pkg-install.sh"
else
  log()   { echo "[redis-setup] $*"; }
  warn()  { echo "[redis-setup][WARN] $*" >&2; }
  error() { echo "[redis-setup][ERROR] $*" >&2; exit 1; }
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
# 1) Install Node dependencies
########################################

log "Installing Redis client + optional BullMQ support…"
pkg_install_dev "ioredis" "bullmq" "@types/ioredis"

########################################
# 2) Ensure docker/services directory
########################################

SERVICES_DIR="$(resolve_project_path "${DOCKER_SERVICES_DIR:-docker/services}")"
mkdir -p "${SERVICES_DIR}"

REDIS_YML="${SERVICES_DIR}/redis.yml"
REDIS_YML_DISPLAY="$(display_project_path "${REDIS_YML}")"

if [ -f "${REDIS_YML}" ]; then
  warn "Redis service fragment already exists at ${REDIS_YML_DISPLAY}; skipping creation."
else
  log "Creating ${REDIS_YML_DISPLAY}…"

  cat > "${REDIS_YML}" <<'YAML'
services:
  redis:
    image: redis:7
    container_name: ${COMPOSE_PROJECT_NAME:-app}-redis
    restart: unless-stopped
    command: ["redis-server", "--appendonly", "yes"]
    ports:
      - "${REDIS_PORT:-6379}:6379"
    volumes:
      - redis_data:/data
    networks:
      - appnet

volumes:
  redis_data:

networks:
  appnet:
    external: false
YAML
fi

########################################
# 3) Append env vars to primary app .env
########################################

ENV_FILE="$(secrets_resolve_env_file "${APP_ENV_FILE:-.env}")"
log_step "Ensuring Redis env vars in ${ENV_FILE}"

enhance_env_var() {
  local key="$1"
  local default="$2"
  ensure_env_var "$key" "$default" "$ENV_FILE"
}

enhance_env_var "REDIS_HOST" "redis"
enhance_env_var "REDIS_PORT" "6379"
enhance_env_var "REDIS_URL" "redis://redis:6379"

log "Redis setup complete.

To run with Redis in dev:

  docker compose -f ${DOCKER_COMPOSE_FILE:-docker-compose.yml} -f ${REDIS_YML_DISPLAY} up -d redis
"
