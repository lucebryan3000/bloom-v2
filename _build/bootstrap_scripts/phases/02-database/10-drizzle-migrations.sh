#!/usr/bin/env bash
# =============================================================================
# File: phases/02-database/10-drizzle-migrations.sh
# Purpose: Configure migration scripts and infrastructure
# Assumes: Drizzle ORM configured, schema exists
# Creates: Migration helper scripts, npm commands
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

# =============================================================================
# METADATA
# =============================================================================
readonly SCRIPT_ID="10"
readonly SCRIPT_NAME="drizzle-migrations"
readonly SCRIPT_DESCRIPTION="Configure Drizzle migration infrastructure"

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
    $(basename "$0")              # Configure migrations
    $(basename "$0") --dry-run    # Preview changes

WHAT THIS SCRIPT DOES:
    1. Creates migration directory structure
    2. Adds migration helper script for container startup
    3. Configures npm scripts for migration workflow
    4. Creates migration README with usage instructions

EOF
}

# =============================================================================
# MAIN LOGIC
# =============================================================================
main() {
    parse_common_args "$@"
    init_logging "$SCRIPT_NAME"

    log_step "Starting migration configuration"

    # Step 1: Check prerequisites
    log_step "Checking prerequisites"
    require_file "package.json" "Initialize project first"
    require_file "drizzle.config.ts" "Run 08-drizzle-setup.sh first"

    # Step 2: Create migrations directory
    log_step "Creating migrations directory"

    ensure_dir "src/db/migrations"
    add_gitkeep "src/db/migrations"

    # Step 3: Create migration runner script
    log_step "Creating migration runner script"

    ensure_dir "scripts"

    local migrate_script='#!/usr/bin/env bash
# =============================================================================
# Run Drizzle migrations
# Used during container startup and CI/CD
# =============================================================================

set -euo pipefail

echo "Running database migrations..."

# Wait for database to be ready
MAX_RETRIES=30
RETRY_INTERVAL=2

for i in $(seq 1 $MAX_RETRIES); do
    if node -e "
        const postgres = require('\''postgres'\'');
        const sql = postgres(process.env.DATABASE_URL);
        sql\`SELECT 1\`.then(() => {
            sql.end();
            process.exit(0);
        }).catch(() => process.exit(1));
    " 2>/dev/null; then
        echo "Database is ready!"
        break
    fi

    if [ $i -eq $MAX_RETRIES ]; then
        echo "Error: Database not ready after $MAX_RETRIES attempts"
        exit 1
    fi

    echo "Waiting for database... (attempt $i/$MAX_RETRIES)"
    sleep $RETRY_INTERVAL
done

# Run migrations
echo "Applying migrations..."
pnpm db:migrate

echo "Migrations complete!"
'

    write_file "scripts/migrate.sh" "$migrate_script"

    # Make script executable
    if [[ "$DRY_RUN" != "true" && -f "scripts/migrate.sh" ]]; then
        chmod +x scripts/migrate.sh
        log_success "Made scripts/migrate.sh executable"
    fi

    # Step 4: Create seed script placeholder
    log_step "Creating seed script placeholder"

    local seed_script='#!/usr/bin/env bash
# =============================================================================
# Seed database with initial data
# =============================================================================

set -euo pipefail

echo "Seeding database..."

# Run TypeScript seed file
pnpm tsx src/db/seed.ts

echo "Seeding complete!"
'

    write_file "scripts/seed.sh" "$seed_script"

    if [[ "$DRY_RUN" != "true" && -f "scripts/seed.sh" ]]; then
        chmod +x scripts/seed.sh
    fi

    # Step 5: Create TypeScript seed file
    log_step "Creating seed file template"

    local seed_ts='import { db } from "./index";
import { featureFlags, appSettings, users } from "./schema";

/**
 * Seed the database with initial data
 *
 * Run with: pnpm db:seed
 */
async function seed() {
  console.log("Starting database seed...");

  // Seed feature flags
  await db
    .insert(featureFlags)
    .values([
      {
        key: "ai_streaming",
        name: "AI Streaming Responses",
        description: "Enable streaming responses from Melissa AI",
        enabled: true,
      },
      {
        key: "pdf_export",
        name: "PDF Export",
        description: "Enable PDF report generation",
        enabled: true,
      },
      {
        key: "excel_export",
        name: "Excel Export",
        description: "Enable Excel data export",
        enabled: true,
      },
    ])
    .onConflictDoNothing();

  // Seed app settings
  await db
    .insert(appSettings)
    .values([
      {
        key: "app_name",
        value: JSON.stringify("Bloom2"),
        description: "Application display name",
        valueType: "string",
      },
      {
        key: "default_confidence_threshold",
        value: JSON.stringify(0.7),
        description: "Minimum confidence score for auto-approval",
        valueType: "number",
      },
    ])
    .onConflictDoNothing();

  console.log("Database seeded successfully!");
}

seed()
  .catch((error) => {
    console.error("Seed failed:", error);
    process.exit(1);
  })
  .finally(async () => {
    process.exit(0);
  });
'

    write_file "src/db/seed.ts" "$seed_ts"

    # Step 6: Add seed script to package.json
    log_step "Adding seed script to package.json"

    add_npm_script "db:seed" "tsx src/db/seed.ts"

    # Step 7: Install tsx for running TypeScript
    log_step "Installing tsx for TypeScript execution"

    add_dependency "tsx" "true"

    # Step 8: Create migrations README
    log_step "Creating migrations README"

    local readme_content='# Database Migrations

## Overview

This directory contains Drizzle ORM migrations for Bloom2.

## Commands

```bash
# Generate migration from schema changes
pnpm db:generate

# Apply pending migrations
pnpm db:migrate

# Push schema directly (development only)
pnpm db:push

# Open Drizzle Studio (database browser)
pnpm db:studio

# Seed database with initial data
pnpm db:seed
```

## Workflow

1. Modify `src/db/schema.ts`
2. Run `pnpm db:generate` to create migration
3. Review generated SQL in `src/db/migrations/`
4. Run `pnpm db:migrate` to apply

## Container Startup

Migrations are automatically applied on container startup via `scripts/migrate.sh`.

## Notes

- Never edit migration files after they have been applied to production
- Use `pnpm db:push` only in development for rapid iteration
- Always review generated migrations before applying
'

    write_file "src/db/migrations/README.md" "$readme_content"

    log_success "Script $SCRIPT_ID completed"
}

main "$@"
