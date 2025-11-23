#!/usr/bin/env bash
# =============================================================================
# File: phases/02-database/08-drizzle-setup.sh
# Purpose: Install and configure Drizzle ORM + drizzle-kit + postgres.js
# Assumes: Next.js project exists with package.json
# Creates: drizzle.config.ts, installs dependencies
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

# =============================================================================
# METADATA
# =============================================================================
readonly SCRIPT_ID="08"
readonly SCRIPT_NAME="drizzle-setup"
readonly SCRIPT_DESCRIPTION="Install and configure Drizzle ORM with postgres.js"

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
    $(basename "$0")              # Install and configure Drizzle
    $(basename "$0") --dry-run    # Preview changes

WHAT THIS SCRIPT DOES:
    1. Installs drizzle-orm and postgres.js driver
    2. Installs drizzle-kit as dev dependency
    3. Creates drizzle.config.ts configuration file
    4. Sets up connection to Docker Compose PostgreSQL

EOF
}

# =============================================================================
# MAIN LOGIC
# =============================================================================
main() {
    parse_common_args "$@"
    init_logging "$SCRIPT_NAME"

    log_step "Starting Drizzle ORM setup"

    # Step 1: Check prerequisites
    log_step "Checking prerequisites"
    require_pnpm
    require_file "package.json" "Initialize project first"

    # Step 2: Install Drizzle ORM and postgres.js
    log_step "Installing Drizzle ORM dependencies"

    add_dependency "drizzle-orm"
    add_dependency "postgres"

    # Step 3: Install drizzle-kit (dev dependency)
    log_step "Installing drizzle-kit"

    add_dependency "drizzle-kit" "true"

    # Step 4: Create drizzle.config.ts
    log_step "Creating drizzle.config.ts"

    local drizzle_config='import type { Config } from "drizzle-kit";

/**
 * Drizzle Kit Configuration
 *
 * Used for migrations and schema introspection.
 * Connection details come from environment variables.
 */
export default {
  schema: "./src/db/schema.ts",
  out: "./src/db/migrations",
  dialect: "postgresql",
  dbCredentials: {
    url: process.env.DATABASE_URL!,
  },
  // Verbose logging during development
  verbose: true,
  // Strict mode for safer migrations
  strict: true,
} satisfies Config;
'

    write_file "drizzle.config.ts" "$drizzle_config"

    # Step 5: Add npm scripts for database operations
    log_step "Adding database scripts to package.json"

    add_npm_script "db:generate" "drizzle-kit generate"
    add_npm_script "db:migrate" "drizzle-kit migrate"
    add_npm_script "db:push" "drizzle-kit push"
    add_npm_script "db:studio" "drizzle-kit studio"
    add_npm_script "db:drop" "drizzle-kit drop"

    # Step 6: Verify installation
    log_step "Verifying Drizzle installation"

    if [[ "$DRY_RUN" != "true" ]]; then
        if has_dependency "drizzle-orm" && has_dependency "postgres"; then
            log_success "Drizzle ORM and postgres.js installed"
        else
            log_error "Dependencies not properly installed"
            exit 1
        fi

        if [[ -f "drizzle.config.ts" ]]; then
            log_success "drizzle.config.ts created"
        fi
    fi

    log_success "Script $SCRIPT_ID completed"
}

main "$@"
