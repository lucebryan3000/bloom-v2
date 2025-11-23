#!/usr/bin/env bash
# =============================================================================
# File: phases/01-docker/05-docker-multistage.sh
# Purpose: Generate a multi-stage Dockerfile for Bloom2 (builder + runtime)
# Assumes: Project root with package.json
# Creates: Dockerfile
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

# =============================================================================
# METADATA
# =============================================================================
readonly SCRIPT_ID="05"
readonly SCRIPT_NAME="docker-multistage"
readonly SCRIPT_DESCRIPTION="Generate multi-stage Dockerfile for Node 20 + pnpm"

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
    -f, --force     Overwrite existing Dockerfile

EXAMPLES:
    $(basename "$0")              # Create Dockerfile
    $(basename "$0") --dry-run    # Preview Dockerfile content
    $(basename "$0") --force      # Overwrite existing Dockerfile

WHAT THIS SCRIPT DOES:
    1. Creates a multi-stage Dockerfile optimized for Next.js 15
    2. Uses Node 20 Alpine as base image
    3. Leverages pnpm for efficient builds
    4. Implements build cache optimization
    5. Creates minimal production image

EOF
}

# =============================================================================
# MAIN LOGIC
# =============================================================================
main() {
    local force=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--force) force=true; shift ;;
            *) break ;;
        esac
    done

    parse_common_args "$@"
    init_logging "$SCRIPT_NAME"

    log_step "Starting Dockerfile generation"

    # Step 1: Check prerequisites
    log_step "Checking prerequisites"
    require_file "package.json" "Initialize project first"

    # Step 2: Check for existing Dockerfile
    log_step "Checking for existing Dockerfile"

    if [[ -f "Dockerfile" && "$force" != "true" ]]; then
        local size
        size=$(wc -c < Dockerfile)
        if [[ "$size" -gt 100 ]]; then
            log_skip "Dockerfile exists and is non-empty"
            log_info "Use --force to overwrite"
            return 0
        fi
    fi

    # Step 3: Generate Dockerfile
    log_step "Generating Dockerfile"

    local dockerfile_content='# =============================================================================
# Bloom2 Multi-Stage Dockerfile
# Optimized for Next.js 15 + pnpm + Node 20
# =============================================================================

# -----------------------------------------------------------------------------
# Stage 1: Dependencies
# -----------------------------------------------------------------------------
FROM node:20-alpine AS deps

# Install pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

WORKDIR /app

# Copy package files for dependency installation
COPY package.json pnpm-lock.yaml* ./

# Install dependencies
RUN --mount=type=cache,id=pnpm,target=/root/.local/share/pnpm/store \
    pnpm install --frozen-lockfile

# -----------------------------------------------------------------------------
# Stage 2: Builder
# -----------------------------------------------------------------------------
FROM node:20-alpine AS builder

RUN corepack enable && corepack prepare pnpm@latest --activate

WORKDIR /app

# Copy dependencies from deps stage
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Set production environment
ENV NEXT_TELEMETRY_DISABLED=1
ENV NODE_ENV=production

# Build the application
RUN pnpm build

# -----------------------------------------------------------------------------
# Stage 3: Production Runner
# -----------------------------------------------------------------------------
FROM node:20-alpine AS runner

WORKDIR /app

# Set production environment
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Create non-root user for security
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs

# Copy built assets
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

# Set correct permissions
RUN chown -R nextjs:nodejs /app

# Switch to non-root user
USER nextjs

# Expose port
EXPOSE 3000

# Set hostname
ENV HOSTNAME="0.0.0.0"
ENV PORT=3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000/api/health || exit 1

# Start the application
CMD ["node", "server.js"]
'

    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry "Create Dockerfile with multi-stage build"
        log_info "Dockerfile content preview:"
        echo "$dockerfile_content" | head -50
        echo "... (truncated)"
    else
        echo "$dockerfile_content" > Dockerfile
        log_success "Created Dockerfile"
    fi

    # Step 4: Update next.config for standalone output
    log_step "Configuring Next.js for standalone output"

    if [[ -f "next.config.js" || -f "next.config.mjs" || -f "next.config.ts" ]]; then
        local config_file
        if [[ -f "next.config.ts" ]]; then
            config_file="next.config.ts"
        elif [[ -f "next.config.mjs" ]]; then
            config_file="next.config.mjs"
        else
            config_file="next.config.js"
        fi

        if grep -q "output.*standalone" "$config_file" 2>/dev/null; then
            log_skip "Standalone output already configured"
        else
            log_info "Note: Add 'output: \"standalone\"' to $config_file for Docker builds"
        fi
    fi

    log_success "Script $SCRIPT_ID completed"
}

main "$@"
