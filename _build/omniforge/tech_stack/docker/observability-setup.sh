#!/usr/bin/env bash
#!meta
# id: docker/observability-setup.sh
# name: observability-setup
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
#   - DOCKER_PROMETHEUS_DIR
#   - DOCKER_SERVICES_DIR
#   - GRAFANA_PASSWORD
#   - GRAFANA_USER
#   - INSTALL_DIR
#   - OMNI_ROOT
#   - PROJECT_ROOT
#   - PROM_CONFIG
#   - PROM_CONFIG_DISPLAY
#   - PROM_DIR
#   - PROM_STACK_YML
#   - PROM_STACK_YML_DISPLAY
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
#   - prom-client (dev dependency)
#   - docker compose
#   - prom/prometheus image
#   - grafana/grafana image
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OMNI_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

if [ -f "${OMNI_ROOT}/lib/common.sh" ]; then
  # shellcheck source=/dev/null
  source "${OMNI_ROOT}/lib/common.sh"
  source "${OMNI_ROOT}/tech_stack/_lib/pkg-install.sh"
else
  log()   { echo "[observability-setup] $*"; }
  warn()  { echo "[observability-setup][WARN] $*" >&2; }
  error() { echo "[observability-setup][ERROR] $*" >&2; exit 1; }
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
# 1) Install prom-client for Node
########################################

log "Installing prom-client for application metrics…"
pkg_install_dev "prom-client"

########################################
# 2) Prometheus + Grafana compose fragment
########################################

SERVICES_DIR="$(resolve_project_path "${DOCKER_SERVICES_DIR:-docker/services}")"
PROM_DIR="$(resolve_project_path "${DOCKER_PROMETHEUS_DIR:-docker/prometheus}")"
mkdir -p "${SERVICES_DIR}" "${PROM_DIR}"

PROM_CONFIG="${PROM_DIR}/prometheus.yml"
PROM_STACK_YML="${SERVICES_DIR}/observability.yml"
PROM_CONFIG_DISPLAY="$(display_project_path "${PROM_CONFIG}")"
PROM_STACK_YML_DISPLAY="$(display_project_path "${PROM_STACK_YML}")"

if [ ! -f "${PROM_CONFIG}" ]; then
  log "Creating ${PROM_CONFIG_DISPLAY}…"
  cat > "${PROM_CONFIG}" <<'YAML'
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: "app"
    metrics_path: /metrics
    static_configs:
      - targets: ["web:3000"]
YAML
else
  warn "Prometheus config already exists; leaving as-is."
fi

if [ -f "${PROM_STACK_YML}" ]; then
  warn "Observability stack already exists at ${PROM_STACK_YML_DISPLAY}; skipping."
else
  log "Creating ${PROM_STACK_YML_DISPLAY}…"

  cat > "${PROM_STACK_YML}" <<YAML
services:
  prometheus:
    image: prom/prometheus:latest
    container_name: ${COMPOSE_PROJECT_NAME:-app}-prometheus
    volumes:
      - ${PROM_CONFIG_DISPLAY:-./docker/prometheus/prometheus.yml}:/etc/prometheus/prometheus.yml:ro
    ports:
      - "9090:9090"
    networks:
      - appnet

  grafana:
    image: grafana/grafana:latest
    container_name: ${COMPOSE_PROJECT_NAME:-app}-grafana
    env_file:
      - .env
    environment:
      GF_SECURITY_ADMIN_USER: ${GRAFANA_USER}
      GF_SECURITY_ADMIN_PASSWORD: ${GRAFANA_PASSWORD}
    ports:
      - "3001:3000"
    networks:
      - appnet
    depends_on:
      - prometheus

networks:
  appnet:
    external: false
YAML
fi

ENV_FILE="$(secrets_resolve_env_file "${APP_ENV_FILE:-.env}")"
log_step "Ensuring Grafana credentials in ${ENV_FILE}"

ensure_env_var "GRAFANA_USER" "admin" "$ENV_FILE"
ensure_random_secret "GRAFANA_PASSWORD" "$ENV_FILE" 16

log "Prometheus + Grafana setup complete.

To run dashboards:

  docker compose -f ${DOCKER_COMPOSE_FILE:-docker-compose.yml} -f ${PROM_STACK_YML_DISPLAY} up -d prometheus grafana

Grafana: http://localhost:3001
Prometheus: http://localhost:9090

Remember to expose /metrics from your Next.js/Node server using prom-client.
"
