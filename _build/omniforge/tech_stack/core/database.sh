#!/usr/bin/env bash
#!meta
# id: core/database.sh
# name: PostgreSQL + Drizzle ORM
# phase: 1
# phase_name: Infrastructure & Database
# profile_tags:
#   - tech_stack
#   - core
# uses_from_omni_config:
#   - APP_NAME
#   - DB_HOST
#   - DB_NAME
#   - DB_PASSWORD
#   - DB_PORT
#   - DB_USER
# uses_from_omni_settings:
#   - PROJECT_ROOT
#   - INSTALL_DIR
#   - POSTGRES_VERSION
# required_vars:
#   - PROJECT_ROOT
#   - INSTALL_DIR
#   - POSTGRES_VERSION
# top_flags:
# dependencies:
#   packages:
#     - drizzle-kit
#     - drizzle-orm
#     - postgres
#     - @neondatabase/serverless
#   dev_packages:
#     - drizzle-kit
#!endmeta
# Docs:
#   - https://orm.drizzle.team/docs/kit-overview
#   - https://orm.drizzle.team/docs/overview
#   - https://www.npmjs.com/package/postgres



# =============================================================================
# tech_stack/core/database.sh - PostgreSQL + Drizzle ORM
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Phase: 1 (Database)
# Profile: ALL (always installed)
#
# Installs:
#   - drizzle-orm (TypeScript ORM)
#   - drizzle-kit (migrations CLI)
#   - postgres (PostgreSQL client)
#   - @neondatabase/serverless (optional serverless driver)
#
# Dependencies:
#   - drizzle-orm
#   - drizzle-kit
#   - postgres
#   - @neondatabase/serverless (optional)
#
# Creates:
#   - drizzle.config.ts
#   - src/db/index.ts (connection)
#   - src/db/schema/index.ts (schema exports)
#   - Docker compose for local PostgreSQL
#
# Requires:
#   - PROJECT_ROOT, DB_NAME, DB_USER, DB_PASSWORD, DB_HOST, DB_PORT
# Contract:
#   Inputs: PROJECT_ROOT, DB_NAME, DB_USER, DB_PASSWORD (.env), DB_HOST, DB_PORT, APP_ENV_FILE
#   Outputs: drizzle.config.ts, src/db/index.ts, src/db/schema/index.ts, drizzle/ dir, .env (ensures DB_* + DATABASE_URL)
#   Runtime: Generates database scaffolding; depends on compose services for Postgres
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"
if command -v parse_stack_flags >/dev/null 2>&1; then
    parse_stack_flags "$@"
fi
source "${SCRIPT_DIR}/../_lib/pkg-install.sh"

readonly SCRIPT_ID="core/database"
readonly SCRIPT_NAME="PostgreSQL + Drizzle ORM"

if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_skip "DRY_RUN: skipping ${SCRIPT_NAME}"
    exit 0
fi

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
: "${DB_NAME:?DB_NAME not set}"
: "${DB_USER:?DB_USER not set}"
: "${DB_HOST:=localhost}"
: "${DB_PORT:=5432}"

secrets_ensure_core_env

cd "$INSTALL_DIR"

# =============================================================================
# DEPENDENCY INSTALLATION
# =============================================================================

log_step "Installing database dependencies"

DEPS=("drizzle-orm" "postgres")
DEV_DEPS=("drizzle-kit")

pkg_preflight_check "${DEPS[@]}" "${DEV_DEPS[@]}"

if ! pkg_verify_all "${DEPS[@]}"; then
    if ! pkg_install_retry "${DEPS[@]}"; then
        log_error "Failed to install database dependencies"
        exit 1
    fi
else
    log_skip "Database dependencies already installed"
fi

if ! pkg_verify_all "${DEV_DEPS[@]}"; then
    if ! pkg_install_dev_retry "${DEV_DEPS[@]}"; then
        log_error "Failed to install drizzle-kit"
        exit 1
    fi
else
    log_skip "Drizzle dev dependencies already installed"
fi

log_ok "Database dependencies installed"

# =============================================================================
# DRIZZLE CONFIGURATION
# =============================================================================

log_step "Creating Drizzle configuration"

if [[ ! -f "drizzle.config.ts" ]]; then
    cat > drizzle.config.ts <<EOF
import { defineConfig } from 'drizzle-kit';

export default defineConfig({
  schema: './src/db/schema/index.ts',
  out: './drizzle',
  dialect: 'postgresql',
  dbCredentials: {
    host: process.env.DB_HOST || '${DB_HOST}',
    port: Number(process.env.DB_PORT) || ${DB_PORT},
    user: process.env.DB_USER || '${DB_USER}',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || '${DB_NAME}',
    ssl: process.env.DB_SSL === 'true',
  },
  verbose: true,
  strict: true,
});
EOF
    log_ok "Created drizzle.config.ts"
else
    log_skip "drizzle.config.ts already exists"
fi

# =============================================================================
# DATABASE CONNECTION
# =============================================================================

log_step "Creating database connection module"

mkdir -p src/db/schema

if [[ ! -f "src/db/index.ts" ]]; then
    cat > src/db/index.ts <<'EOF'
/**
 * Database Connection
 * Provides typed database client using Drizzle ORM
 */

import { drizzle } from 'drizzle-orm/postgres-js';
import postgres from 'postgres';
import * as schema from './schema';

// Connection string from environment
const connectionString = process.env.DATABASE_URL ||
  `postgresql://${process.env.DB_USER}:${process.env.DB_PASSWORD}@${process.env.DB_HOST || 'localhost'}:${process.env.DB_PORT || 5432}/${process.env.DB_NAME}`;

// PostgreSQL client
// For serverless, use { max: 1 }
const client = postgres(connectionString, {
  max: 10,
  idle_timeout: 20,
  connect_timeout: 10,
});

// Drizzle instance with schema
export const db = drizzle(client, { schema });

// Export types
export type Database = typeof db;
export { schema };
EOF
    log_ok "Created src/db/index.ts"
fi

# Schema index
if [[ ! -f "src/db/schema/index.ts" ]]; then
    cat > src/db/schema/index.ts <<'EOF'
/**
 * Database Schema Exports
 * Add schema tables here as they are created
 */

// Example:
// export * from './users';
// export * from './posts';

// Placeholder export to prevent empty module error
export const _placeholder = true;
EOF
    log_ok "Created src/db/schema/index.ts"
fi

# =============================================================================
# DOCKER COMPOSE (LOCAL DEVELOPMENT)
# =============================================================================

log_step "Creating Docker Compose for local PostgreSQL"

if [[ ! -f "docker-compose.yml" ]]; then
    cat > docker-compose.yml <<EOF
# Local Development Database
# Start: docker compose up -d
# Stop: docker compose down
# Reset: docker compose down -v

services:
  postgres:
    image: postgres:${POSTGRES_VERSION}-alpine
    container_name: ${APP_NAME}_postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: ${DB_NAME}
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: \${DB_PASSWORD:-postgres}
    ports:
      - "${DB_PORT}:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER} -d ${DB_NAME}"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  postgres_data:
EOF
    log_ok "Created docker-compose.yml"
else
    log_skip "docker-compose.yml already exists"
fi

# =============================================================================
# PACKAGE.JSON SCRIPTS
# =============================================================================

log_step "Adding database scripts to package.json"

# Add drizzle scripts if not present
if command -v jq &>/dev/null && [[ -f "package.json" ]]; then
    # Check if scripts exist
    if ! jq -e '.scripts["db:generate"]' package.json &>/dev/null; then
        jq '.scripts += {
          "db:generate": "drizzle-kit generate",
          "db:migrate": "drizzle-kit migrate",
          "db:push": "drizzle-kit push",
          "db:studio": "drizzle-kit studio"
        }' package.json > package.json.tmp && mv package.json.tmp package.json
        log_ok "Added database scripts to package.json"
    else
        log_skip "Database scripts already in package.json"
    fi
else
    log_warn "jq not available, skipping package.json script updates"
fi

# =============================================================================
# ENV TEMPLATE
# =============================================================================

log_step "Creating .env.example for database"

if [[ ! -f ".env.example" ]]; then
    cat > .env.example <<EOF
# Database Configuration
DB_HOST=${DB_HOST}
DB_PORT=${DB_PORT}
DB_NAME=${DB_NAME}
DB_USER=${DB_USER}
DB_PASSWORD=your_secure_password_here
DB_SSL=false

# Connection URL (alternative to individual vars)
DATABASE_URL=postgresql://\${DB_USER}:\${DB_PASSWORD}@\${DB_HOST}:\${DB_PORT}/\${DB_NAME}
EOF
    log_ok "Created .env.example"
fi

# =============================================================================
# MARK SUCCESS
# =============================================================================

mark_script_success "${SCRIPT_ID}"
log_ok "${SCRIPT_NAME} complete"
