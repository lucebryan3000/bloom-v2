#!/usr/bin/env bash
#!meta
# id: docker/traefik-setup.sh
# name: traefik-setup
# phase: 0
# phase_name: Project Foundation
# profile_tags:
#   - tech_stack
#   - docker
# uses_from_omni_config:
# uses_from_omni_settings:
#   - COMPOSE_PROJECT_NAME
#   - DOCKER_COMPOSE_FILE
#   - DOCKER_SERVICES_DIR
#   - DOCKER_TRAEFIK_DIR
#   - OMNI_ROOT
#   - PROJECT_ROOT
#   - SERVICES_DIR
#   - TRAEFIK_CONFIG_DISPLAY
#   - TRAEFIK_CONFIG_PATH
#   - TRAEFIK_DIR
#   - TRAEFIK_YML
#   - TRAEFIK_YML_DISPLAY
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
#   - traefik image
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OMNI_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

if [ -f "${OMNI_ROOT}/lib/common.sh" ]; then
  # shellcheck source=/dev/null
  source "${OMNI_ROOT}/lib/common.sh"
else
  log()   { echo "[traefik-setup] $*"; }
  warn()  { echo "[traefik-setup][WARN] $*" >&2; }
  error() { echo "[traefik-setup][ERROR] $*" >&2; exit 1; }
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

cd "${PROJECT_ROOT:-${OMNI_ROOT}/..}"

SERVICES_DIR="$(resolve_project_path "${DOCKER_SERVICES_DIR:-docker/services}")"
TRAEFIK_DIR="$(resolve_project_path "${DOCKER_TRAEFIK_DIR:-docker/traefik}")"
mkdir -p "${SERVICES_DIR}" "${TRAEFIK_DIR}"

TRAEFIK_YML="${SERVICES_DIR}/traefik.yml"
TRAEFIK_YML_DISPLAY="$(display_project_path "${TRAEFIK_YML}")"
TRAEFIK_CONFIG_PATH="${TRAEFIK_DIR}/traefik.yml"
TRAEFIK_CONFIG_DISPLAY="$(display_project_path "${TRAEFIK_CONFIG_PATH}")"

########################################
# 1) Static Traefik config
########################################

if [ -f "${TRAEFIK_CONFIG_PATH}" ]; then
  warn "Traefik config already exists at ${TRAEFIK_CONFIG_DISPLAY}; skipping."
else
  log "Creating ${TRAEFIK_CONFIG_DISPLAY}…"
  cat > "${TRAEFIK_CONFIG_PATH}" <<'YAML'
entryPoints:
  web:
    address: ":80"
  websecure:
    address: ":443"

providers:
  docker:
    exposedByDefault: false

api:
  dashboard: true
YAML
fi

########################################
# 2) Docker service fragment
########################################

if [ -f "${TRAEFIK_YML}" ]; then
  warn "Traefik docker fragment already exists at ${TRAEFIK_YML_DISPLAY}; skipping."
else
  log "Creating ${TRAEFIK_YML_DISPLAY}…"

  cat > "${TRAEFIK_YML}" <<YAML
services:
  traefik:
    image: traefik:v3.1
    container_name: ${COMPOSE_PROJECT_NAME:-app}-traefik
    command:
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--api.dashboard=true"
    ports:
      - "80:80"
      - "443:443"
      - "8080:8080"    # dashboard
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ${TRAEFIK_CONFIG_DISPLAY:-./docker/traefik/traefik.yml}:/etc/traefik/traefik.yml:ro
    networks:
      - appnet

networks:
  appnet:
    external: false
YAML
fi

log "Traefik setup complete.

Next steps:

  - Label your web service in docker-compose with:
      labels:
        - \"traefik.enable=true\"
        - \"traefik.http.routers.app.rule=Host(`localhost`)\"
        - \"traefik.http.routers.app.entrypoints=web\"
        - \"traefik.http.services.app.loadbalancer.server.port=3000\"

  - Run:
      docker compose -f ${DOCKER_COMPOSE_FILE:-docker-compose.yml} -f ${TRAEFIK_YML_DISPLAY} up -d traefik
"
