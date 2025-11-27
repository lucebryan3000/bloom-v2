#!/usr/bin/env bash
#!meta
# id: docker/docker-pnpm-cache.sh
# name: docker-pnpm-cache
# phase: 1
# phase_name: Infrastructure & Database
# profile_tags:
#   - tech_stack
#   - docker
# uses_from_omni_config:
# uses_from_omni_settings:
#   - PROJECT_ROOT
#   - INSTALL_DIR
# required_vars:
#   - PROJECT_ROOT
#   - INSTALL_DIR
# top_flags:
# dependencies:
#   packages: []
#   dev_packages: []
#!endmeta

# =============================================================================
# tech_stack/docker/docker-pnpm-cache.sh - Docker Build Optimization
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Phase: 1 (Infrastructure)
# Profile: ALL (always created)
#
# Creates:
#   - .docker/cache-config.sh (build cache settings)
#   - Makefile (common Docker commands)
#   - GitHub Actions Docker workflow (optional)
#
# Optimizations:
#   - BuildKit cache mounts for pnpm
#   - Layer caching strategies
#   - Multi-platform build support
#
# Requires:
#   - PROJECT_ROOT, APP_NAME
# =============================================================================
#
# Dependencies:
#   - docker BuildKit/buildx
#   - pnpm
#

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"
if command -v parse_stack_flags >/dev/null 2>&1; then
    parse_stack_flags "$@"
fi

readonly SCRIPT_ID="docker/docker-pnpm-cache"
readonly SCRIPT_NAME="Docker Build Optimization"

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
: "${APP_NAME:?APP_NAME not set}"
: "${NODE_VERSION:=20}"
: "${PNPM_VERSION:=9}"

cd "$INSTALL_DIR"

# Container name/image prefix
IMAGE_NAME="${APP_NAME,,}"
IMAGE_NAME="${IMAGE_NAME// /-}"

# =============================================================================
# DOCKER CONFIG DIRECTORY
# =============================================================================

log_step "Creating Docker configuration directory"

mkdir -p .docker

# Build cache configuration
cat > .docker/cache-config.sh <<'EOF'
#!/usr/bin/env bash
# =============================================================================
# Docker Build Cache Configuration
# =============================================================================
# Source this file before running docker build for optimized caching
#
# Usage:
#   source .docker/cache-config.sh
#   docker build $DOCKER_BUILD_ARGS -t myapp:latest .
# =============================================================================

# Enable BuildKit
export DOCKER_BUILDKIT=1

# BuildKit cache directory
export BUILDKIT_CACHE_DIR="${HOME}/.cache/docker-buildkit"

# Common build arguments with cache mounts
DOCKER_BUILD_ARGS=(
    --build-arg BUILDKIT_INLINE_CACHE=1
    --cache-from "type=local,src=${BUILDKIT_CACHE_DIR}"
    --cache-to "type=local,dest=${BUILDKIT_CACHE_DIR},mode=max"
)

# For multi-platform builds
DOCKER_PLATFORM_ARGS=(
    --platform linux/amd64,linux/arm64
)

# Export as string for simple use
export DOCKER_BUILD_ARGS="${DOCKER_BUILD_ARGS[*]}"
export DOCKER_PLATFORM_ARGS="${DOCKER_PLATFORM_ARGS[*]}"

echo "[INFO] Docker BuildKit enabled with cache at: ${BUILDKIT_CACHE_DIR}"
EOF

chmod +x .docker/cache-config.sh
log_ok "Created .docker/cache-config.sh"

# =============================================================================
# MAKEFILE FOR DOCKER COMMANDS
# =============================================================================

log_step "Creating Makefile"

if [[ ! -f "Makefile" ]]; then
    cat > Makefile <<EOF
# =============================================================================
# ${APP_NAME} - Docker Build Commands
# =============================================================================
# Usage: make <target>
# =============================================================================

.PHONY: help dev prod build push clean logs shell db-shell test

# Configuration
IMAGE_NAME := ${IMAGE_NAME}
REGISTRY := ghcr.io/\$(shell git config --get remote.origin.url | sed 's/.*github.com[:/]\\([^/]*\\).*/\\1/' | tr '[:upper:]' '[:lower:]')
VERSION := \$(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")

# Enable BuildKit
export DOCKER_BUILDKIT=1

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*\$\$' \$(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\\033[36m%-15s\\033[0m %s\\n", \$\$1, \$\$2}'

# ---------------------------------------------------------------------------
# Development
# ---------------------------------------------------------------------------

dev: ## Start development stack
	docker compose up -d
	@echo "Development server: http://localhost:3000"

dev-build: ## Rebuild and start development stack
	docker compose up -d --build

dev-down: ## Stop development stack
	docker compose down

dev-clean: ## Stop and remove all volumes
	docker compose down -v

logs: ## Follow all logs
	docker compose logs -f

logs-app: ## Follow app logs only
	docker compose logs -f app

shell: ## Open shell in app container
	docker compose exec app sh

db-shell: ## Open PostgreSQL shell
	docker compose exec postgres psql -U \$\${DB_USER:-postgres} -d \$\${DB_NAME:-app}

# ---------------------------------------------------------------------------
# Production Build
# ---------------------------------------------------------------------------

build: ## Build production image
	docker build \\
		--build-arg BUILDKIT_INLINE_CACHE=1 \\
		-t \$(IMAGE_NAME):latest \\
		-t \$(IMAGE_NAME):\$(VERSION) \\
		.

build-no-cache: ## Build production image without cache
	docker build --no-cache -t \$(IMAGE_NAME):latest .

prod: ## Run production container locally
	docker run --rm -p 3000:3000 \\
		--env-file .env.production \\
		\$(IMAGE_NAME):latest

# ---------------------------------------------------------------------------
# Registry Operations
# ---------------------------------------------------------------------------

push: build ## Push to container registry
	docker tag \$(IMAGE_NAME):latest \$(REGISTRY)/\$(IMAGE_NAME):latest
	docker tag \$(IMAGE_NAME):\$(VERSION) \$(REGISTRY)/\$(IMAGE_NAME):\$(VERSION)
	docker push \$(REGISTRY)/\$(IMAGE_NAME):latest
	docker push \$(REGISTRY)/\$(IMAGE_NAME):\$(VERSION)

# ---------------------------------------------------------------------------
# Utilities
# ---------------------------------------------------------------------------

test: ## Run tests in container
	docker compose exec app pnpm test

lint: ## Run linting in container
	docker compose exec app pnpm lint

clean: ## Remove all project containers and images
	docker compose down -v --rmi local
	docker image prune -f

prune: ## Deep clean Docker system (WARNING: affects all projects)
	docker system prune -af --volumes
EOF
    log_ok "Created Makefile"
else
    log_skip "Makefile already exists"
fi

# =============================================================================
# GITHUB ACTIONS DOCKER WORKFLOW
# =============================================================================

log_step "Creating GitHub Actions Docker workflow"

mkdir -p .github/workflows

if [[ ! -f ".github/workflows/docker.yml" ]]; then
    cat > .github/workflows/docker.yml <<EOF
# =============================================================================
# Docker Build & Push Workflow
# =============================================================================
# Builds and pushes Docker images to GitHub Container Registry
# Triggers on: push to main, tags, pull requests
# =============================================================================

name: Docker Build

on:
  push:
    branches: [main]
    tags: ['v*']
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: \${{ github.repository }}

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Login to Container Registry
        if: github.event_name != 'pull_request'
        uses: docker/login-action@v3
        with:
          registry: \${{ env.REGISTRY }}
          username: \${{ github.actor }}
          password: \${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: \${{ env.REGISTRY }}/\${{ env.IMAGE_NAME }}
          tags: |
            type=ref,event=branch
            type=ref,event=pr
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=sha

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          push: \${{ github.event_name != 'pull_request' }}
          tags: \${{ steps.meta.outputs.tags }}
          labels: \${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
          build-args: |
            BUILDKIT_INLINE_CACHE=1

      - name: Generate SBOM
        if: github.event_name != 'pull_request'
        uses: anchore/sbom-action@v0
        with:
          image: \${{ env.REGISTRY }}/\${{ env.IMAGE_NAME }}:sha-\${{ github.sha }}
          format: spdx-json
          output-file: sbom.spdx.json

      - name: Upload SBOM
        if: github.event_name != 'pull_request'
        uses: actions/upload-artifact@v4
        with:
          name: sbom
          path: sbom.spdx.json
EOF
    log_ok "Created .github/workflows/docker.yml"
else
    log_skip ".github/workflows/docker.yml already exists"
fi

# =============================================================================
# ENV EXAMPLE UPDATE
# =============================================================================

log_step "Updating .env.example with Docker variables"

if [[ -f ".env.example" ]]; then
    if ! grep -q "DOCKER_BUILDKIT" .env.example 2>/dev/null; then
        cat >> .env.example <<'EOF'

# Docker Configuration
DOCKER_BUILDKIT=1
COMPOSE_DOCKER_CLI_BUILD=1
EOF
        log_ok "Added Docker variables to .env.example"
    else
        log_skip "Docker variables already in .env.example"
    fi
fi

# =============================================================================
# MARK SUCCESS
# =============================================================================

mark_script_success "${SCRIPT_ID}"
log_ok "${SCRIPT_NAME} complete"
