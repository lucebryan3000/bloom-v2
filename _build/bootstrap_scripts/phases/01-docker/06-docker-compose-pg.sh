#!/usr/bin/env bash
# =============================================================================
# File: phases/01-docker/06-docker-compose-pg.sh
# Purpose: Generate docker-compose.yml with web and PostgreSQL (pgvector) services
# Assumes: Project root exists
# Creates: docker-compose.yml
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

# =============================================================================
# METADATA
# =============================================================================
readonly SCRIPT_ID="06"
readonly SCRIPT_NAME="docker-compose-pg"
readonly SCRIPT_DESCRIPTION="Generate docker-compose.yml with web and PostgreSQL pgvector services"

# =============================================================================
# USAGE
# =============================================================================
usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

$SCRIPT_DESCRIPTION

OPTIONS:
    -h, --help      Show this help message and exit
    -n, --dry-run   Show what would be done without making changes
    -v, --verbose   Enable verbose output
    -f, --force     Overwrite existing docker-compose.yml

EXAMPLES:
    $(basename "$0")              # Create docker-compose.yml
    $(basename "$0") --dry-run    # Preview content
    $(basename "$0") --force      # Overwrite existing file

WHAT THIS SCRIPT DOES:
    1. Creates docker-compose.yml with web and db services
    2. Configures PostgreSQL 16 with pgvector extension
    3. Sets up volume for data persistence
    4. Configures healthchecks for both services
    5. Sets up networking and environment variables

EOF
}

# =============================================================================
# MAIN LOGIC
# =============================================================================
main() {
    local force=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--force) force=true; shift ;;
            *) break ;;
        esac
    done

    parse_common_args "$@"
    init_logging "$SCRIPT_NAME"

    log_step "Starting docker-compose.yml generation"

    # Step 1: Check for existing file
    log_step "Checking for existing docker-compose.yml"

    if [[ -f "docker-compose.yml" && "$force" != "true" ]]; then
        log_skip "docker-compose.yml exists"
        log_info "Use --force to overwrite"
        return 0
    fi

    # Step 2: Generate docker-compose.yml
    log_step "Generating docker-compose.yml"

    local compose_content='# =============================================================================
# Bloom2 Docker Compose Configuration
# PostgreSQL 16 with pgvector + Next.js Web App
# =============================================================================

version: "3.9"

services:
  # ---------------------------------------------------------------------------
  # PostgreSQL Database with pgvector
  # ---------------------------------------------------------------------------
  db:
    image: pgvector/pgvector:pg16
    container_name: bloom2-db
    restart: unless-stopped
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-bloom2}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-bloom2_dev_password}
      POSTGRES_DB: ${POSTGRES_DB:-bloom2_db}
    ports:
      - "127.0.0.1:5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./scripts/db/init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-bloom2} -d ${POSTGRES_DB:-bloom2_db}"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 10s
    networks:
      - bloom2-network

  # ---------------------------------------------------------------------------
  # Next.js Web Application
  # ---------------------------------------------------------------------------
  web:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: bloom2-web
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      NODE_ENV: production
      DATABASE_URL: postgresql://${POSTGRES_USER:-bloom2}:${POSTGRES_PASSWORD:-bloom2_dev_password}@db:5432/${POSTGRES_DB:-bloom2_db}
      NEXT_PUBLIC_APP_URL: ${NEXT_PUBLIC_APP_URL:-http://localhost:3000}
      AUTH_SECRET: ${AUTH_SECRET:-change_this_in_production}
      AUTH_TRUST_HOST: "true"
      # AI Provider (set in .env)
      ANTHROPIC_API_KEY: ${ANTHROPIC_API_KEY:-}
    depends_on:
      db:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:3000/api/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    networks:
      - bloom2-network

# =============================================================================
# Volumes
# =============================================================================
volumes:
  postgres_data:
    driver: local

# =============================================================================
# Networks
# =============================================================================
networks:
  bloom2-network:
    driver: bridge
'

    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry "Create docker-compose.yml"
        log_info "Content preview:"
        echo "$compose_content"
    else
        echo "$compose_content" > docker-compose.yml
        log_success "Created docker-compose.yml"
    fi

    # Step 3: Create DB init script directory
    log_step "Creating database initialization script"

    ensure_dir "scripts/db"

    local init_sql='-- =============================================================================
-- Bloom2 Database Initialization
-- This script runs on first container start
-- =============================================================================

-- Enable pgvector extension for semantic search capabilities
CREATE EXTENSION IF NOT EXISTS vector;

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Log successful initialization
DO $$
BEGIN
    RAISE NOTICE '\''Bloom2 database initialized with pgvector extension'\'';
END $$;
'

    write_file "scripts/db/init.sql" "$init_sql"

    # Step 4: Create .env.example
    log_step "Creating .env.example"

    local env_example='# =============================================================================
# Bloom2 Environment Variables
# Copy this file to .env and fill in your values
# =============================================================================

# Database
POSTGRES_USER=bloom2
POSTGRES_PASSWORD=bloom2_dev_password
POSTGRES_DB=bloom2_db
DATABASE_URL=postgresql://bloom2:bloom2_dev_password@localhost:5432/bloom2_db

# Application
NEXT_PUBLIC_APP_URL=http://localhost:3000
NODE_ENV=development

# Authentication
AUTH_SECRET=generate_a_secure_random_string_here
AUTH_TRUST_HOST=true

# AI Provider
ANTHROPIC_API_KEY=your_anthropic_api_key_here
'

    write_file ".env.example" "$env_example"

    log_success "Script $SCRIPT_ID completed"
}

main "$@"
