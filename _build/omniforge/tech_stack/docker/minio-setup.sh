#!/usr/bin/env bash
#!meta
# id: docker/minio-setup.sh
# name: minio-setup
# phase: 1
# phase_name: Infrastructure & Database
# profile_tags:
#   - tech_stack
#   - docker
# uses_from_omni_config:
#   - ENABLE_MINIO
# uses_from_omni_settings:
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
#   - minio/minio image
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
  log()   { echo "[minio-setup] $*"; }
  warn()  { echo "[minio-setup][WARN] $*" >&2; }
  error() { echo "[minio-setup][ERROR] $*" >&2; exit 1; }
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
  log_skip "DRY_RUN: skipping minio-setup"
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
# 1) Install Node MinIO client
########################################

log "Installing MinIO/S3 client for Node…"
pkg_install_dev "minio"

########################################
# 2) Docker service fragment
########################################

SERVICES_DIR="$(resolve_project_path "${DOCKER_SERVICES_DIR:-docker/services}")"
mkdir -p "${SERVICES_DIR}"

MINIO_YML="${SERVICES_DIR}/minio.yml"
MINIO_YML_DISPLAY="$(display_project_path "${MINIO_YML}")"

if [ -f "${MINIO_YML}" ]; then
  warn "MinIO docker fragment already exists at ${MINIO_YML_DISPLAY}; skipping."
else
  log "Creating ${MINIO_YML_DISPLAY}…"

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

  docker compose -f ${DOCKER_COMPOSE_FILE:-docker-compose.yml} -f ${MINIO_YML_DISPLAY} up -d minio

Console will be at: http://localhost:9001
"
