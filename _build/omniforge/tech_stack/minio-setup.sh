#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

if [ -f "${REPO_ROOT}/_build/omniforge/lib/common.sh" ]; then
  # shellcheck source=/dev/null
  source "${REPO_ROOT}/_build/omniforge/lib/common.sh"
else
  log()   { echo "[minio-setup] $*"; }
  warn()  { echo "[minio-setup][WARN] $*" >&2; }
  error() { echo "[minio-setup][ERROR] $*" >&2; exit 1; }
fi

cd "${REPO_ROOT}"

if ! command -v pnpm >/dev/null 2>&1; then
  error "pnpm is not installed or not on PATH. Aborting."
fi

########################################
# 1) Install Node MinIO client
########################################

log "Installing MinIO/S3 client for Node…"
pnpm add minio -D

########################################
# 2) Docker service fragment
########################################

SERVICES_DIR="${REPO_ROOT}/docker/services"
mkdir -p "${SERVICES_DIR}"

MINIO_YML="${SERVICES_DIR}/minio.yml"

if [ -f "${MINIO_YML}" ]; then
  warn "MinIO docker fragment already exists at docker/services/minio.yml; skipping."
else
  log "Creating docker/services/minio.yml…"

  cat > "${MINIO_YML}" <<'YAML'
services:
  minio:
    image: minio/minio:latest
    container_name: ${COMPOSE_PROJECT_NAME:-app}-minio
    command: server /data --console-address ":9001"
    environment:
      MINIO_ROOT_USER: ${MINIO_ROOT_USER:-minioadmin}
      MINIO_ROOT_PASSWORD: ${MINIO_ROOT_PASSWORD:-minioadmin}
    ports:
      - "${MINIO_PORT:-9000}:9000"
      - "${MINIO_CONSOLE_PORT:-9001}:9001"
    volumes:
      - minio_data:/data
    networks:
      - appnet

volumes:
  minio_data:

networks:
  appnet:
    external: false
YAML
fi

########################################
# 3) Env wiring
########################################

ENV_FILE="$(secrets_resolve_env_file "${APP_ENV_FILE:-.env}")"
log_step "Ensuring MinIO env vars in ${ENV_FILE}"

seed_env_var() {
  local key="$1"
  local default="$2"
  ensure_env_var "$key" "$default" "$ENV_FILE"
}

seed_env_var "MINIO_ENDPOINT" "minio"
seed_env_var "MINIO_PORT" "9000"
seed_env_var "MINIO_ACCESS_KEY" "minioadmin"
seed_env_var "MINIO_SECRET_KEY" "minioadmin"
seed_env_var "MINIO_USE_SSL" "false"
seed_env_var "EXPORT_BUCKET_NAME" "bloom-exports"

log "MinIO setup complete.

To run:

  docker compose -f docker-compose.yml -f docker/services/minio.yml up -d minio

Console will be at: http://localhost:9001
"
