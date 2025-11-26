#!/usr/bin/env bash
# =============================================================================
# tech_stack/docker/docker-compose-pg.sh - Full Development Stack
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Phase: 1 (Infrastructure)
# Profile: ALL (always created)
#
# Creates:
#   - docker-compose.yml (development stack)
#   - docker-compose.prod.yml (production override)
#   - scripts/docker-dev.sh (helper commands)
#
# Services:
#   - app: Next.js development container
#   - postgres: PostgreSQL with pgvector
#   - redis: (optional) caching layer
#
# Requires:
#   - PROJECT_ROOT, APP_NAME, NODE_VERSION
#   - DB_NAME, DB_USER, DB_PASSWORD, DB_PORT
#   - POSTGRES_VERSION, PGVECTOR_IMAGE (optional)
# Contract:
#   Inputs: APP_NAME, APP_ENV_FILE, DB_NAME, DB_USER, DB_PASSWORD (.env), PGVECTOR_IMAGE, NODE_VERSION
#   Outputs: docker-compose.yml, docker-compose.prod.yml, scripts/docker-dev.sh, Makefile, db init SQL
#   Runtime: Compose definitions for app + database; bootstrap-only (used by docker compose)
# =============================================================================
#
# Dependencies:
#   - docker
#   - docker compose
#   - postgres image
#

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"

readonly SCRIPT_ID="docker/docker-compose-pg"
readonly SCRIPT_NAME="Docker Compose Stack"

# =============================================================================
# PREFLIGHT
# =============================================================================

log_step "${SCRIPT_NAME} - Preflight"

if has_script_succeeded "${SCRIPT_ID}"; then
    log_skip "${SCRIPT_NAME} (already completed)"
    exit 0
fi

# Verify required variables
: "${PROJECT_ROOT:?PROJECT_ROOT not set}"
: "${APP_NAME:?APP_NAME not set}"
: "${NODE_VERSION:=20}"
: "${PNPM_VERSION:=9}"
: "${DB_NAME:?DB_NAME not set}"
: "${DB_USER:?DB_USER not set}"
: "${DB_HOST:=postgres}"
: "${DB_PORT:=5432}"
: "${POSTGRES_VERSION:=16}"
: "${PGVECTOR_IMAGE:=pgvector/pgvector:pg${POSTGRES_VERSION}}"
: "${ENABLE_REDIS:=false}"

secrets_ensure_core_env

ENV_FILE_PATH="${APP_ENV_FILE:-.env}"

log_info "Compose image pins: app base node:${NODE_VERSION}-alpine, postgres image ${PGVECTOR_IMAGE}"

cd "$INSTALL_DIR"

# Container name prefix (lowercase, no special chars)
CONTAINER_PREFIX="${APP_NAME,,}"
CONTAINER_PREFIX="${CONTAINER_PREFIX// /_}"

# =============================================================================
# DOCKER COMPOSE (DEVELOPMENT)
# =============================================================================

log_step "Creating docker-compose.yml"

if [[ ! -f "docker-compose.yml" ]]; then
    cat > docker-compose.yml <<EOF
# =============================================================================
# ${APP_NAME} - Development Docker Compose
# =============================================================================
# Full development stack with hot reload
#
# Commands:
#   docker compose up -d        # Start all services
#   docker compose logs -f app  # Follow app logs
#   docker compose down         # Stop all services
#   docker compose down -v      # Stop and remove volumes
# =============================================================================

services:
  # ---------------------------------------------------------------------------
  # Application (Next.js)
  # ---------------------------------------------------------------------------
  app:
    build:
      context: .
      dockerfile: Dockerfile.dev
    container_name: ${CONTAINER_PREFIX}_app
    restart: unless-stopped
    ports:
      - "3000:3000"
    volumes:
      # Mount source for hot reload
      - .:/workspace
      # Preserve node_modules from container
      - /workspace/node_modules
      # Named volume for pnpm store
      - pnpm_store:/root/.local/share/pnpm/store
    working_dir: /workspace
    env_file:
      - ${ENV_FILE_PATH}
    environment:
      - NODE_ENV=development
      - NEXT_TELEMETRY_DISABLED=1
      - WATCHPACK_POLLING=true
    depends_on:
      postgres:
        condition: service_healthy
    networks:
      - ${CONTAINER_PREFIX}_network

  # ---------------------------------------------------------------------------
  # PostgreSQL (with pgvector)
  # ---------------------------------------------------------------------------
  postgres:
    image: ${PGVECTOR_IMAGE}
    container_name: ${CONTAINER_PREFIX}_postgres
    restart: unless-stopped
    env_file:
      - ${ENV_FILE_PATH}
    environment:
      POSTGRES_DB: \${DB_NAME}
      POSTGRES_USER: \${DB_USER}
      POSTGRES_PASSWORD: \${DB_PASSWORD}
    ports:
      - "\${DB_PORT:-${DB_PORT}}:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      # Optional: init scripts
      - ./scripts/db/init:/docker-entrypoint-initdb.d:ro
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U \${DB_USER:-${DB_USER}} -d \${DB_NAME:-${DB_NAME}}"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 10s
    networks:
      - ${CONTAINER_PREFIX}_network
EOF

    # Add Redis if enabled
    if [[ "${ENABLE_REDIS}" == "true" ]]; then
        cat >> docker-compose.yml <<EOF

  # ---------------------------------------------------------------------------
  # Redis (Caching)
  # ---------------------------------------------------------------------------
  redis:
    image: redis:7-alpine
    container_name: ${CONTAINER_PREFIX}_redis
    restart: unless-stopped
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - ${CONTAINER_PREFIX}_network
EOF
    fi

    # Networks and volumes
    cat >> docker-compose.yml <<EOF

# =============================================================================
# Networks
# =============================================================================
networks:
  ${CONTAINER_PREFIX}_network:
    driver: bridge

# =============================================================================
# Volumes
# =============================================================================
volumes:
  postgres_data:
    driver: local
  pnpm_store:
    driver: local
EOF

    if [[ "${ENABLE_REDIS}" == "true" ]]; then
        cat >> docker-compose.yml <<EOF
  redis_data:
    driver: local
EOF
    fi

    log_ok "Created docker-compose.yml"
else
    log_skip "docker-compose.yml already exists"
fi

# =============================================================================
# DOCKER COMPOSE PRODUCTION OVERRIDE
# =============================================================================

log_step "Creating docker-compose.prod.yml"

if [[ ! -f "docker-compose.prod.yml" ]]; then
    cat > docker-compose.prod.yml <<EOF
# =============================================================================
# ${APP_NAME} - Production Docker Compose Override
# =============================================================================
# Use with: docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
# =============================================================================

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    restart: always
    environment:
      - NODE_ENV=production
    volumes: []  # No source mounting in production
    deploy:
      resources:
        limits:
          memory: 1G
        reservations:
          memory: 512M

  postgres:
    restart: always
    deploy:
      resources:
        limits:
          memory: 512M
        reservations:
          memory: 256M
EOF
    log_ok "Created docker-compose.prod.yml"
else
    log_skip "docker-compose.prod.yml already exists"
fi

# =============================================================================
# HELPER SCRIPTS
# =============================================================================

log_step "Creating Docker helper scripts"

mkdir -p scripts/db/init

# Docker dev helper script
if [[ ! -f "scripts/docker-dev.sh" ]]; then
    cat > scripts/docker-dev.sh <<'EOF'
#!/usr/bin/env bash
# =============================================================================
# Docker Development Helper Commands
# =============================================================================

set -euo pipefail

COMPOSE_FILE="docker-compose.yml"

usage() {
    cat << HELP
Docker Development Commands

Usage: ./scripts/docker-dev.sh <command>

Commands:
  up          Start all services
  down        Stop all services
  restart     Restart all services
  logs        Follow all logs
  logs-app    Follow app logs only
  shell       Open shell in app container
  db-shell    Open psql shell
  db-reset    Reset database (WARNING: destroys data)
  clean       Remove containers, volumes, and images
  status      Show container status
HELP
}

case "${1:-}" in
    up)
        docker compose -f "$COMPOSE_FILE" up -d
        echo "Services started. View logs: docker compose logs -f"
        ;;
    down)
        docker compose -f "$COMPOSE_FILE" down
        ;;
    restart)
        docker compose -f "$COMPOSE_FILE" restart
        ;;
    logs)
        docker compose -f "$COMPOSE_FILE" logs -f
        ;;
    logs-app)
        docker compose -f "$COMPOSE_FILE" logs -f app
        ;;
    shell)
        docker compose -f "$COMPOSE_FILE" exec app sh
        ;;
    db-shell)
        docker compose -f "$COMPOSE_FILE" exec postgres psql -U "${DB_USER:-postgres}" -d "${DB_NAME:-app}"
        ;;
    db-reset)
        echo "WARNING: This will destroy all database data!"
        read -p "Continue? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker compose -f "$COMPOSE_FILE" down -v
            docker compose -f "$COMPOSE_FILE" up -d postgres
            echo "Database reset. Waiting for healthy state..."
            sleep 5
        fi
        ;;
    clean)
        docker compose -f "$COMPOSE_FILE" down -v --rmi local
        ;;
    status)
        docker compose -f "$COMPOSE_FILE" ps
        ;;
    *)
        usage
        exit 1
        ;;
esac
EOF
    chmod +x scripts/docker-dev.sh
    log_ok "Created scripts/docker-dev.sh"
else
    log_skip "scripts/docker-dev.sh already exists"
fi

# Host Makefile with common Docker commands
log_step "Creating Docker Makefile"

if [[ ! -f "Makefile" ]]; then
    cat > Makefile <<'EOF'
COMPOSE_FILE ?= docker-compose.yml

.PHONY: compose-up compose-down dev build test logs shell

compose-up:
	 docker compose -f $(COMPOSE_FILE) up -d app postgres

compose-down:
	 docker compose -f $(COMPOSE_FILE) down

dev: compose-up
	 docker compose -f $(COMPOSE_FILE) exec app pnpm dev

build: compose-up
	 docker compose -f $(COMPOSE_FILE) exec app pnpm build

test: compose-up
	 docker compose -f $(COMPOSE_FILE) exec app pnpm test

logs:
	 docker compose -f $(COMPOSE_FILE) logs -f app

shell: compose-up
	 docker compose -f $(COMPOSE_FILE) exec app sh
EOF
    log_ok "Created Makefile for Docker workflows"
else
    log_skip "Makefile already exists"
fi

# PostgreSQL init script (enables pgvector)
if [[ ! -f "scripts/db/init/01-extensions.sql" ]]; then
    cat > scripts/db/init/01-extensions.sql <<'EOF'
-- =============================================================================
-- PostgreSQL Initialization: Extensions
-- =============================================================================
-- This script runs automatically when the PostgreSQL container initializes
-- for the first time (empty data volume).

-- Enable pgvector for AI embeddings
CREATE EXTENSION IF NOT EXISTS vector;

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable pg_trgm for fuzzy text search
CREATE EXTENSION IF NOT EXISTS pg_trgm;
EOF
    log_ok "Created scripts/db/init/01-extensions.sql"
fi

# =============================================================================
# PACKAGE.JSON SCRIPTS
# =============================================================================

log_step "Adding Docker scripts to package.json"

if command -v jq &>/dev/null && [[ -f "package.json" ]]; then
    if ! jq -e '.scripts["docker:up"]' package.json &>/dev/null; then
        jq '.scripts += {
          "docker:up": "docker compose up -d",
          "docker:down": "docker compose down",
          "docker:logs": "docker compose logs -f",
          "docker:shell": "docker compose exec app sh",
          "docker:db": "docker compose exec postgres psql -U $DB_USER -d $DB_NAME",
          "docker:reset": "./scripts/docker-dev.sh db-reset"
        }' package.json > package.json.tmp && mv package.json.tmp package.json
        log_ok "Added Docker scripts to package.json"
    else
        log_skip "Docker scripts already in package.json"
    fi
else
    log_warn "jq not available, skipping package.json script updates"
fi

# =============================================================================
# MARK SUCCESS
# =============================================================================

mark_script_success "${SCRIPT_ID}"
log_ok "${SCRIPT_NAME} complete"
