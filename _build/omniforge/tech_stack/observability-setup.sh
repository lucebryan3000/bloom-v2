#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

if [ -f "${REPO_ROOT}/_build/omniforge/lib/common.sh" ]; then
  # shellcheck source=/dev/null
  source "${REPO_ROOT}/_build/omniforge/lib/common.sh"
else
  log()   { echo "[observability-setup] $*"; }
  warn()  { echo "[observability-setup][WARN] $*" >&2; }
  error() { echo "[observability-setup][ERROR] $*" >&2; exit 1; }
fi

cd "${REPO_ROOT}"

if ! command -v pnpm >/dev/null 2>&1; then
  error "pnpm is not installed or not on PATH. Aborting."
fi

########################################
# 1) Install prom-client for Node
########################################

log "Installing prom-client for application metrics…"
pnpm add prom-client -D

########################################
# 2) Prometheus + Grafana compose fragment
########################################

SERVICES_DIR="${REPO_ROOT}/docker/services"
PROM_DIR="${REPO_ROOT}/docker/prometheus"
mkdir -p "${SERVICES_DIR}" "${PROM_DIR}"

PROM_CONFIG="${PROM_DIR}/prometheus.yml"
PROM_STACK_YML="${SERVICES_DIR}/observability.yml"

if [ ! -f "${PROM_CONFIG}" ]; then
  log "Creating docker/prometheus/prometheus.yml…"
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
  warn "Observability stack already exists at docker/services/observability.yml; skipping."
else
  log "Creating docker/services/observability.yml…"

  cat > "${PROM_STACK_YML}" <<'YAML'
services:
  prometheus:
    image: prom/prometheus:latest
    container_name: ${COMPOSE_PROJECT_NAME:-app}-prometheus
    volumes:
      - ./docker/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
    ports:
      - "9090:9090"
    networks:
      - appnet

  grafana:
    image: grafana/grafana:latest
    container_name: ${COMPOSE_PROJECT_NAME:-app}-grafana
    environment:
      GF_SECURITY_ADMIN_USER: ${GRAFANA_USER:-admin}
      GF_SECURITY_ADMIN_PASSWORD: ${GRAFANA_PASSWORD:-admin}
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

ENV_FILE="${REPO_ROOT}/.env.local"
touch "${ENV_FILE}"

if ! grep -q "^GRAFANA_USER=" "${ENV_FILE}"; then
  echo "GRAFANA_USER=admin" >> "${ENV_FILE}"
  log "Added GRAFANA_USER to .env.local"
fi

if ! grep -q "^GRAFANA_PASSWORD=" "${ENV_FILE}"; then
  echo "GRAFANA_PASSWORD=admin" >> "${ENV_FILE}"
  log "Added GRAFANA_PASSWORD to .env.local"
fi

log "Prometheus + Grafana setup complete.

To run dashboards:

  docker compose -f docker-compose.yml -f docker/services/observability.yml up -d prometheus grafana

Grafana: http://localhost:3001
Prometheus: http://localhost:9090

Remember to expose /metrics from your Next.js/Node server using prom-client.
"
