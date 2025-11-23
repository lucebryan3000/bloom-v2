#!/usr/bin/env bash
# =============================================================================
# File: phases/00-foundation/04-init-directory-structure.sh
# Purpose: Create the hybrid domain/feature directory structure for Bloom2
# Assumes: Project root exists with package.json
# Creates: src/features, src/lib, src/db, src/schemas, src/prompts, tests/
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

# =============================================================================
# METADATA
# =============================================================================
readonly SCRIPT_ID="04"
readonly SCRIPT_NAME="init-directory-structure"
readonly SCRIPT_DESCRIPTION="Create Bloom2 hybrid domain/feature directory structure"

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
    $(basename "$0")              # Create directory structure
    $(basename "$0") --dry-run    # Preview directories to create

WHAT THIS SCRIPT DOES:
    Creates the following directory structure:

    src/
    ├── app/              (Next.js 15 routes - created by Next.js)
    ├── components/       (Reusable UI components)
    ├── db/               (Drizzle schema and client)
    ├── features/         (Business domain modules)
    │   ├── chat/
    │   ├── review/
    │   ├── report/
    │   ├── projects/
    │   └── settings/
    ├── lib/              (Shared utilities)
    ├── prompts/          (Melissa AI prompts)
    └── schemas/          (Zod validation schemas)

    tests/
    ├── unit/
    ├── integration/
    └── e2e/

EOF
}

# =============================================================================
# MAIN LOGIC
# =============================================================================
main() {
    parse_common_args "$@"
    init_logging "$SCRIPT_NAME"

    log_step "Starting directory structure creation"

    # Step 1: Check prerequisites
    log_step "Checking prerequisites"
    require_file "package.json" "Run 01-init-nextjs15.sh first"

    # Step 2: Create src directories
    log_step "Creating src directories"

    # Core directories
    ensure_dir "src/components"
    ensure_dir "src/db"
    ensure_dir "src/db/migrations"
    ensure_dir "src/lib"
    ensure_dir "src/prompts"
    ensure_dir "src/schemas"

    # Feature directories (business domains)
    local features=("chat" "review" "report" "projects" "settings")
    for feature in "${features[@]}"; do
        ensure_dir "src/features/$feature"
    done

    # App routes (some may exist from Next.js init)
    ensure_dir "src/app/(auth)"
    ensure_dir "src/app/workspace"
    ensure_dir "src/app/reports"
    ensure_dir "src/app/settings"
    ensure_dir "src/app/api"

    # Step 3: Create test directories
    log_step "Creating test directories"

    ensure_dir "tests/unit"
    ensure_dir "tests/integration"
    ensure_dir "tests/e2e"

    # Step 4: Add .gitkeep files to empty directories
    log_step "Adding .gitkeep files"

    local dirs_needing_gitkeep=(
        "src/components"
        "src/db/migrations"
        "src/lib"
        "src/prompts"
        "src/schemas"
        "src/features/chat"
        "src/features/review"
        "src/features/report"
        "src/features/projects"
        "src/features/settings"
        "tests/unit"
        "tests/integration"
        "tests/e2e"
    )

    for dir in "${dirs_needing_gitkeep[@]}"; do
        add_gitkeep "$dir"
    done

    # Step 5: Create placeholder index files
    log_step "Creating placeholder index files"

    # src/lib/index.ts
    local lib_index='/**
 * Shared utilities and helpers for Bloom2
 *
 * This module exports common utilities used across the application.
 */

// Export utilities as they are created
// export * from "./logger";
// export * from "./rateLimiter";
// export * from "./sessionState";
'
    write_file "src/lib/index.ts" "$lib_index"

    # src/schemas/index.ts
    local schemas_index='/**
 * Zod validation schemas for Bloom2
 *
 * All input validation should use schemas from this module.
 */

// Export schemas as they are created
// export * from "./env";
// export * from "./chat";
// export * from "./metrics";
// export * from "./projects";
// export * from "./settings";
'
    write_file "src/schemas/index.ts" "$schemas_index"

    # src/prompts/index.ts
    local prompts_index='/**
 * Melissa AI prompts for Bloom2
 *
 * Prompts-as-code for consistent AI behavior.
 */

// Export prompts as they are created
// export * from "./system";
// export * from "./discovery";
// export * from "./quantification";
// export * from "./validation";
// export * from "./synthesis";
'
    write_file "src/prompts/index.ts" "$prompts_index"

    # src/db/index.ts placeholder
    local db_index='/**
 * Database client and Drizzle ORM exports
 *
 * This module provides the database connection and typed client.
 */

// Database client will be configured by 11-db-client-index.sh
// export { db } from "./client";
// export * from "./schema";
'
    write_file "src/db/index.ts" "$db_index"

    # Step 6: Verify structure
    log_step "Verifying directory structure"

    if [[ "$DRY_RUN" != "true" ]]; then
        local expected_dirs=(
            "src/components"
            "src/db"
            "src/features/chat"
            "src/lib"
            "src/prompts"
            "src/schemas"
            "tests/unit"
        )

        local all_exist=true
        for dir in "${expected_dirs[@]}"; do
            if [[ ! -d "$dir" ]]; then
                log_error "Expected directory not found: $dir"
                all_exist=false
            fi
        done

        if [[ "$all_exist" == "true" ]]; then
            log_success "All directories created successfully"
        else
            log_error "Some directories are missing"
            exit 1
        fi
    fi

    # Display structure
    log_info "Directory structure created:"
    if command -v tree &> /dev/null && [[ "$DRY_RUN" != "true" ]]; then
        tree -L 3 src tests 2>/dev/null || true
    fi

    log_success "Script $SCRIPT_ID completed"
}

main "$@"
