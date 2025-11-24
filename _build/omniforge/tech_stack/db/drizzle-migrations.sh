#!/usr/bin/env bash
# =============================================================================
# db/drizzle-migrations.sh - Database Migrations Setup
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Phase: 1 (Infrastructure)
# Purpose: Configure Drizzle migration scripts and directory structure
#
# Creates:
#   - drizzle/ directory for migration files
#   - Migration npm scripts in package.json
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"

readonly SCRIPT_ID="db/drizzle-migrations"
readonly SCRIPT_NAME="Drizzle Migrations"

# Check if already completed
if has_script_succeeded "${SCRIPT_ID}"; then
    log_skip "${SCRIPT_NAME} (already completed)"
    exit 0
fi

log_step "${SCRIPT_NAME}"

: "${PROJECT_ROOT:?PROJECT_ROOT not set}"
cd "$INSTALL_DIR"

# Create migrations directory
mkdir -p drizzle

# Create .gitkeep to track empty dir
if [[ ! -f "drizzle/.gitkeep" ]]; then
    touch drizzle/.gitkeep
    log_ok "Created drizzle/ migrations directory"
else
    log_skip "drizzle/ directory already exists"
fi

# Create migration helper script
if [[ ! -f "drizzle/migrate.ts" ]]; then
    cat > drizzle/migrate.ts << 'EOF'
/**
 * Database Migration Runner
 * Usage: pnpm db:migrate
 */

import { drizzle } from 'drizzle-orm/postgres-js';
import { migrate } from 'drizzle-orm/postgres-js/migrator';
import postgres from 'postgres';

const connectionString = process.env.DATABASE_URL ||
  `postgresql://${process.env.DB_USER}:${process.env.DB_PASSWORD}@${process.env.DB_HOST || 'localhost'}:${process.env.DB_PORT || 5432}/${process.env.DB_NAME}`;

async function runMigrations() {
  console.log('Running migrations...');

  const sql = postgres(connectionString, { max: 1 });
  const db = drizzle(sql);

  await migrate(db, { migrationsFolder: './drizzle' });

  console.log('Migrations complete!');
  await sql.end();
  process.exit(0);
}

runMigrations().catch((err) => {
  console.error('Migration failed:', err);
  process.exit(1);
});
EOF
    log_ok "Created drizzle/migrate.ts"
fi

mark_script_success "${SCRIPT_ID}"
log_ok "${SCRIPT_NAME} complete"
