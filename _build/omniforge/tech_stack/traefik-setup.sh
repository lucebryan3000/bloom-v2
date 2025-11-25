#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

if [ -f "${REPO_ROOT}/_build/omniforge/lib/common.sh" ]; then
  # shellcheck source=/dev/null
  source "${REPO_ROOT}/_build/omniforge/lib/common.sh"
else
  log()   { echo "[traefik-setup] $*"; }
  warn()  { echo "[traefik-setup][WARN] $*" >&2; }
  error() { echo "[traefik-setup][ERROR] $*" >&2; exit 1; }
fi

cd "${REPO_ROOT}"

SERVICES_DIR="${REPO_ROOT}/docker/services"
TRAEFIK_DIR="${REPO_ROOT}/docker/traefik"
mkdir -p "${SERVICES_DIR}" "${TRAEFIK_DIR}"

TRAEFIK_YML="${SERVICES_DIR}/traefik.yml"

########################################
# 1) Static Traefik config
########################################

TRAEFIK_CONFIG="${TRAEFIK_DIR}/traefik.yml"

if [ -f "${TRAEFIK_CONFIG}" ]; then
  warn "Traefik config already exists at docker/traefik/traefik.yml; skipping."
else
  log "Creating docker/traefik/traefik.yml…"
  cat > "${TRAEFIK_CONFIG}" <<'YAML'
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
  warn "Traefik docker fragment already exists at docker/services/traefik.yml; skipping."
else
  log "Creating docker/services/traefik.yml…"

  cat > "${TRAEFIK_YML}" <<'YAML'
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
      - ./docker/traefik/traefik.yml:/etc/traefik/traefik.yml:ro
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
      docker compose -f docker-compose.yml -f docker/services/traefik.yml up -d traefik
"
