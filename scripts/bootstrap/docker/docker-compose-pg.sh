#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SH="${SCRIPT_DIR%/*}/lib/common.sh"
[[ -f "${COMMON_SH}" ]] || { echo "ERROR: common.sh not found" >&2; exit 1; }
. "${COMMON_SH}"

SCRIPT_KEY="docker/docker-compose-pg.sh"

main() {
    parse_common_args "$@"
    [[ "${SHOW_HELP}" == "true" ]] && { echo "Create docker-compose.yml with PostgreSQL ${POSTGRES_VERSION} + pgvector"; exit 0; }

    log_info "=== Creating docker-compose.yml ==="
    cd "${PROJECT_ROOT:-.}"

    local compose="version: \"3.9\"
services:
  db:
    image: ${PGVECTOR_IMAGE}
    container_name: ${APP_NAME}-db
    restart: unless-stopped
    environment:
      POSTGRES_USER: \${POSTGRES_USER:-${DB_USER}}
      POSTGRES_PASSWORD: \${POSTGRES_PASSWORD:-${DB_PASSWORD}}
      POSTGRES_DB: \${POSTGRES_DB:-${DB_NAME}}
    ports:
      - \"127.0.0.1:${DB_PORT}:5432\"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: [\"CMD-SHELL\", \"pg_isready -U \${POSTGRES_USER:-${DB_USER}} -d \${POSTGRES_DB:-${DB_NAME}}\"]
      interval: 10s
      timeout: 5s
      retries: 5

  web:
    build: .
    container_name: ${APP_NAME}-web
    restart: unless-stopped
    ports:
      - \"3000:3000\"
    environment:
      NODE_ENV: production
      DATABASE_URL: postgresql://\${POSTGRES_USER:-${DB_USER}}:\${POSTGRES_PASSWORD:-${DB_PASSWORD}}@db:5432/\${POSTGRES_DB:-${DB_NAME}}
      AUTH_SECRET: \${AUTH_SECRET:-change_this}
      AUTH_TRUST_HOST: \"true\"
      ANTHROPIC_API_KEY: \${ANTHROPIC_API_KEY:-}
    depends_on:
      db:
        condition: service_healthy

volumes:
  postgres_data:
"

    write_file_if_missing "docker-compose.yml" "${compose}"

    ensure_dir "scripts/db"
    local init_sql="CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";
"
    write_file_if_missing "scripts/db/init.sql" "${init_sql}"

    mark_script_success "${SCRIPT_KEY}"
    log_success "docker-compose.yml created"
}

main "$@"
