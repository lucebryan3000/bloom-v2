#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Try to load Omniforge common helpers if they exist
if [ -f "${REPO_ROOT}/_build/omniforge/lib/common.sh" ]; then
  # shellcheck source=/dev/null
  source "${REPO_ROOT}/_build/omniforge/lib/common.sh"
else
  log()   { echo "[redis-setup] $*"; }
  warn()  { echo "[redis-setup][WARN] $*" >&2; }
  error() { echo "[redis-setup][ERROR] $*" >&2; exit 1; }
fi

cd "${REPO_ROOT}"

########################################
# 1) Install Node dependencies
########################################

log "Installing Redis client + optional BullMQ support via pnpm…"

if ! command -v pnpm >/dev/null 2>&1; then
  error "pnpm is not installed or not on PATH. Aborting."
fi

pnpm add ioredis bullmq @types/ioredis -D

########################################
# 2) Ensure docker/services directory
########################################

SERVICES_DIR="${REPO_ROOT}/docker/services"
mkdir -p "${SERVICES_DIR}"

REDIS_YML="${SERVICES_DIR}/redis.yml"

if [ -f "${REDIS_YML}" ]; then
  warn "Redis service fragment already exists at docker/services/redis.yml; skipping creation."
else
  log "Creating docker/services/redis.yml…"

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

  docker compose -f docker-compose.yml -f docker/services/redis.yml up -d redis
"
