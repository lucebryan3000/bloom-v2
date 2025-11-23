#!/usr/bin/env bash
# =============================================================================
# File: phases/00-foundation/01-init-nextjs15.sh
# Purpose: Initialize a new Next.js 15 App Router project using pnpm
# Assumes: Node.js 20+, pnpm installed, running from project root
# Creates: package.json, src/app/, next.config.js, tailwind.config.js
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

# =============================================================================
# METADATA
# =============================================================================
readonly SCRIPT_ID="01"
readonly SCRIPT_NAME="init-nextjs15"
readonly SCRIPT_DESCRIPTION="Initialize Next.js 15 App Router project with pnpm"

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
    $(basename "$0")              # Initialize Next.js project
    $(basename "$0") --dry-run    # Preview what would be created

WHAT THIS SCRIPT DOES:
    1. Checks for existing project (package.json, src/app)
    2. Creates Next.js 15 project with TypeScript, Tailwind, App Router
    3. Ensures .gitignore includes standard Node/Next artifacts
    4. Configures project for pnpm

EOF
}

# =============================================================================
# MAIN LOGIC
# =============================================================================
main() {
    parse_common_args "$@"
    init_logging "$SCRIPT_NAME"

    log_step "Starting Next.js 15 initialization"

    # Step 1: Check prerequisites
    log_step "Checking prerequisites"
    require_node_version 20
    require_pnpm

    # Step 2: Check if project already exists
    log_step "Checking for existing project"

    if [[ -f "package.json" && -d "src/app" ]]; then
        log_skip "Next.js project already initialized"
        log_info "Found package.json and src/app directory"
        return 0
    fi

    # Step 3: Initialize Next.js project
    log_step "Creating Next.js 15 project"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry "pnpm create next-app@latest . --typescript --tailwind --eslint --app --src-dir --import-alias '@/*' --use-pnpm"
    else
        # Create project in current directory
        pnpm create next-app@latest . \
            --typescript \
            --tailwind \
            --eslint \
            --app \
            --src-dir \
            --import-alias "@/*" \
            --use-pnpm \
            --no-git
        log_success "Next.js 15 project created"
    fi

    # Step 4: Ensure .gitignore exists and is complete
    log_step "Configuring .gitignore"

    local gitignore_content="# Dependencies
node_modules
.pnpm-store

# Next.js
.next
out
build

# Testing
coverage
.nyc_output

# Misc
.DS_Store
*.pem
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*
.pnpm-debug.log*

# Local env files
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# Vercel
.vercel

# TypeScript
*.tsbuildinfo
next-env.d.ts

# IDE
.idea
.vscode
*.swp
*.swo

# Logs
logs/
*.log

# Playwright
/test-results/
/playwright-report/
/blob-report/
/playwright/.cache/
"

    if [[ -f ".gitignore" ]]; then
        log_skip ".gitignore exists"
        # Check if key entries are missing and append if needed
        if ! grep -q "node_modules" .gitignore; then
            append_file ".gitignore" "$gitignore_content"
        fi
    else
        write_file ".gitignore" "$gitignore_content"
    fi

    # Step 5: Final verification
    log_step "Verifying installation"

    if [[ "$DRY_RUN" != "true" ]]; then
        if [[ -f "package.json" && -d "src/app" ]]; then
            log_success "Next.js 15 project initialized successfully"
        else
            log_error "Verification failed - expected files not found"
            exit 1
        fi
    fi

    log_success "Script $SCRIPT_ID completed"
}

main "$@"
