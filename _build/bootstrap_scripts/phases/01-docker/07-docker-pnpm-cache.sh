#!/usr/bin/env bash
# =============================================================================
# File: phases/01-docker/07-docker-pnpm-cache.sh
# Purpose: Optimize Docker builds for pnpm cache efficiency
# Assumes: Dockerfile exists
# Creates: .dockerignore, updates Dockerfile if needed
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

# =============================================================================
# METADATA
# =============================================================================
readonly SCRIPT_ID="07"
readonly SCRIPT_NAME="docker-pnpm-cache"
readonly SCRIPT_DESCRIPTION="Optimize Docker builds with .dockerignore and pnpm cache"

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

EXAMPLES:
    $(basename "$0")              # Create .dockerignore
    $(basename "$0") --dry-run    # Preview changes

WHAT THIS SCRIPT DOES:
    1. Creates .dockerignore with appropriate exclusions
    2. Excludes node_modules, .next, .git, logs, etc.
    3. Ensures efficient Docker layer caching
    4. Adds development-only files to ignore list

EOF
}

# =============================================================================
# MAIN LOGIC
# =============================================================================
main() {
    parse_common_args "$@"
    init_logging "$SCRIPT_NAME"

    log_step "Starting Docker optimization"

    # Step 1: Create .dockerignore
    log_step "Creating .dockerignore"

    local dockerignore_content='# =============================================================================
# Bloom2 Docker Ignore
# Files and directories excluded from Docker build context
# =============================================================================

# Dependencies (reinstalled in container)
node_modules
.pnpm-store

# Build outputs (rebuilt in container)
.next
out
build
dist

# Version control
.git
.gitignore

# IDE and editor files
.idea
.vscode
*.swp
*.swo
.DS_Store

# Environment files (secrets should not be in image)
.env
.env.local
.env.development.local
.env.test.local
.env.production.local
.env*.local

# Logs
logs
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*
.pnpm-debug.log*

# Testing
coverage
.nyc_output
test-results
playwright-report
blob-report

# Documentation (not needed in runtime)
*.md
!README.md
docs

# Docker files (prevent recursive builds)
Dockerfile*
docker-compose*.yml
.dockerignore

# Scripts and tooling
scripts
_build
Makefile

# Misc
*.pem
*.key
.turbo
.vercel
'

    if [[ -f ".dockerignore" ]]; then
        log_skip ".dockerignore exists"
        # Check if it has essential entries
        if ! grep -q "node_modules" .dockerignore; then
            log_warn ".dockerignore missing 'node_modules' - consider updating"
        fi
    else
        write_file ".dockerignore" "$dockerignore_content"
    fi

    # Step 2: Create development docker-compose override
    log_step "Creating docker-compose.override.yml for development"

    local compose_override='# =============================================================================
# Bloom2 Docker Compose Override (Development)
# This file is automatically loaded alongside docker-compose.yml in development
# =============================================================================

version: "3.9"

services:
  web:
    build:
      context: .
      dockerfile: Dockerfile
      target: deps  # Use deps stage for faster dev rebuilds
    volumes:
      # Mount source code for hot reloading
      - .:/app
      - /app/node_modules  # Prevent overwriting container node_modules
      - /app/.next  # Prevent overwriting container build cache
    environment:
      NODE_ENV: development
    command: pnpm dev
    ports:
      - "3000:3000"

  db:
    ports:
      - "5432:5432"  # Expose to host for local tooling
'

    write_file "docker-compose.override.yml" "$compose_override"

    # Step 3: Create Makefile for common Docker commands
    log_step "Creating Makefile for Docker commands"

    local makefile_content='.PHONY: build up down logs shell db-shell clean

# Build the Docker images
build:
	docker compose build

# Start all services
up:
	docker compose up -d

# Start with logs attached
up-logs:
	docker compose up

# Stop all services
down:
	docker compose down

# View logs
logs:
	docker compose logs -f

# View web logs only
logs-web:
	docker compose logs -f web

# Shell into web container
shell:
	docker compose exec web sh

# Shell into database
db-shell:
	docker compose exec db psql -U bloom2 -d bloom2_db

# Clean up containers, volumes, and images
clean:
	docker compose down -v --rmi local

# Rebuild and restart
rebuild: down build up

# Database migrations
db-migrate:
	docker compose exec web pnpm db:migrate

# Generate database migrations
db-generate:
	docker compose exec web pnpm db:generate
'

    write_file "Makefile" "$makefile_content"

    # Step 4: Verify optimizations
    log_step "Verifying Docker optimizations"

    if [[ "$DRY_RUN" != "true" ]]; then
        local checks_passed=true

        if [[ ! -f ".dockerignore" ]]; then
            log_error "Missing .dockerignore"
            checks_passed=false
        fi

        if [[ -f "Dockerfile" ]] && grep -q "mount=type=cache" Dockerfile; then
            log_success "Dockerfile uses cache mounts"
        fi

        if [[ "$checks_passed" == "true" ]]; then
            log_success "Docker optimizations configured"
        fi
    fi

    log_success "Script $SCRIPT_ID completed"
}

main "$@"
