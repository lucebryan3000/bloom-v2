#!/usr/bin/env bash
#!meta
# id: docker/dockerfile-multistage.sh
# name: dockerfile-multistage
# phase: 1
# phase_name: Infrastructure & Database
# profile_tags:
#   - tech_stack
#   - docker
# uses_from_omni_config:
#   - APP_NAME
# uses_from_omni_settings:
#   - PROJECT_ROOT
#   - INSTALL_DIR
#   - NODE_VERSION
# top_flags:
# dependencies:
#   packages: []
#   dev_packages: []
#!endmeta

# =============================================================================
# tech_stack/docker/dockerfile-multistage.sh - Production Dockerfile Generator
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Phase: 1 (Infrastructure)
# Profile: ALL (always created)
#
# Creates:
#   - Dockerfile (multistage production build)
#   - Dockerfile.dev (development with hot reload)
#   - .dockerignore (build context exclusions)
#
# Requires:
#   - PROJECT_ROOT, APP_NAME, NODE_VERSION, PNPM_VERSION
# Contract:
#   Inputs: APP_NAME, NODE_VERSION, PNPM_VERSION
#   Outputs: Dockerfile (prod), Dockerfile.dev (dev), .dockerignore
#   Runtime: Template generation for Docker builds; bootstrap-only
# =============================================================================
#
# Dependencies:
#   - docker build (multi-stage)
#

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"
if command -v parse_stack_flags >/dev/null 2>&1; then
    parse_stack_flags "$@"
fi

readonly SCRIPT_ID="docker/dockerfile-multistage"
readonly SCRIPT_NAME="Dockerfile Generator"

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

log_info "Resolved Node image tag: node:${NODE_VERSION}-alpine (pnpm ${PNPM_VERSION})"

cd "$INSTALL_DIR"

# =============================================================================
# PRODUCTION DOCKERFILE (MULTISTAGE)
# =============================================================================

log_step "Creating production Dockerfile"

if [[ ! -f "Dockerfile" ]]; then
    cat > Dockerfile <<EOF
# =============================================================================
# ${APP_NAME} - Production Dockerfile
# =============================================================================
# Multistage build for optimized production image
# Build: docker build -t ${APP_NAME,,}:latest .
# Run:   docker run -p 3000:3000 ${APP_NAME,,}:latest
# =============================================================================

# -----------------------------------------------------------------------------
# Stage 1: Dependencies
# -----------------------------------------------------------------------------
FROM node:${NODE_VERSION}-alpine AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app

# Install pnpm
RUN corepack enable && corepack prepare pnpm@${PNPM_VERSION} --activate

# Copy package files
COPY package.json pnpm-lock.yaml* ./

# Install dependencies (production only for smaller image)
RUN pnpm install --frozen-lockfile --prod=false

# -----------------------------------------------------------------------------
# Stage 2: Builder
# -----------------------------------------------------------------------------
FROM node:${NODE_VERSION}-alpine AS builder
WORKDIR /app

RUN corepack enable && corepack prepare pnpm@${PNPM_VERSION} --activate

# Copy dependencies from deps stage
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Build arguments for environment
ARG NEXT_PUBLIC_APP_URL
ARG DATABASE_URL

# Disable telemetry during build
ENV NEXT_TELEMETRY_DISABLED=1

# Build the application
RUN pnpm build

# -----------------------------------------------------------------------------
# Stage 3: Runner (Production)
# -----------------------------------------------------------------------------
FROM node:${NODE_VERSION}-alpine AS runner
WORKDIR /app

# Security: Run as non-root user
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs

# Set production environment
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

# Copy only necessary files from builder
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

# Set ownership
RUN chown -R nextjs:nodejs /app

USER nextjs

EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000/api/health || exit 1

CMD ["node", "server.js"]
EOF
    log_ok "Created Dockerfile (multistage production)"
else
    log_skip "Dockerfile already exists"
fi

# =============================================================================
# DEVELOPMENT DOCKERFILE
# =============================================================================

log_step "Creating development Dockerfile"

if [[ ! -f "Dockerfile.dev" ]]; then
    cat > Dockerfile.dev <<EOF
# =============================================================================
# ${APP_NAME} - Development Dockerfile
# =============================================================================
# Development container with hot reload and full tooling
# Build: docker build -f Dockerfile.dev -t ${APP_NAME,,}:dev .
# Run:   docker compose up
# =============================================================================

FROM node:${NODE_VERSION}-alpine

WORKDIR /workspace

# Install system dependencies needed by OmniForge scripts
RUN apk add --no-cache bash git jq curl openssl libc6-compat

# Install pnpm globally
RUN corepack enable && corepack prepare pnpm@${PNPM_VERSION} --activate

# Copy package files first for better caching
COPY package.json pnpm-lock.yaml* ./

# Install all dependencies (including devDependencies)
RUN pnpm install --frozen-lockfile

# Don't copy source - mounted as volume for hot reload
# COPY . .

# Development environment
ENV NODE_ENV=development
ENV NEXT_TELEMETRY_DISABLED=1
ENV WATCHPACK_POLLING=true

EXPOSE 3000

# Default command for development
CMD ["pnpm", "dev"]
EOF
    log_ok "Created Dockerfile.dev (development)"
else
    log_skip "Dockerfile.dev already exists"
fi

# =============================================================================
# DOCKERIGNORE
# =============================================================================

log_step "Creating .dockerignore"

if [[ ! -f ".dockerignore" ]]; then
    cat > .dockerignore <<'EOF'
# =============================================================================
# .dockerignore - Docker Build Context Exclusions
# =============================================================================

# Version control & secrets
.git
.gitignore
.gitmodules
.env
.env.local
.env.development
.env.production
.env*.local

# IDE & editors
.vscode/
.idea/
*.swp
*.swo

# Dependencies & build artifacts (rebuilt in container)
node_modules
.next/
dist/
out/
coverage/
.pnpm-store/

# Database volumes
postgres_data/
*.db
*.sqlite

# Logs & temp files
*.log
npm-debug.log*
pnpm-debug.log*
.DS_Store
Thumbs.db

# Tests & documentation (not needed in prod image)
tests/
__tests__/
*.test.ts
*.spec.ts
playwright-report/
test-results/

# Development & build tooling
_build/
docs/
*.md
!README.md
Makefile

# Docker files (prevent recursive context)
Dockerfile*
docker-compose*.yml
.dockerignore
EOF
    log_ok "Created .dockerignore"
else
    log_skip ".dockerignore already exists"
fi

# =============================================================================
# UPDATE NEXT.JS CONFIG FOR STANDALONE
# =============================================================================

log_step "Ensuring Next.js standalone output config"

if [[ -f "next.config.ts" ]]; then
    if ! grep -q "output.*standalone" next.config.ts 2>/dev/null; then
        log_warn "Add 'output: \"standalone\"' to next.config.ts for Docker optimization"
    else
        log_ok "next.config.ts already has standalone output"
    fi
elif [[ -f "next.config.js" ]]; then
    if ! grep -q "output.*standalone" next.config.js 2>/dev/null; then
        log_warn "Add 'output: \"standalone\"' to next.config.js for Docker optimization"
    else
        log_ok "next.config.js already has standalone output"
    fi
else
    log_warn "No next.config.ts/js found - create one with output: 'standalone' for Docker"
fi

# =============================================================================
# MARK SUCCESS
# =============================================================================

mark_script_success "${SCRIPT_ID}"
log_ok "${SCRIPT_NAME} complete"