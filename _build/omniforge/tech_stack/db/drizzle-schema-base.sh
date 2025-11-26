#!/usr/bin/env bash
# =============================================================================
# db/drizzle-schema-base.sh - Base Schema Definitions
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Phase: 1 (Infrastructure)
# Purpose: Create base Drizzle schema files
#
# Creates foundational schema tables (users, sessions, etc.)
# =============================================================================
#
# Dependencies:
#   - drizzle-orm
#

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"

readonly SCRIPT_ID="db/drizzle-schema-base"
readonly SCRIPT_NAME="Drizzle Base Schema"

# Check if already completed
if has_script_succeeded "${SCRIPT_ID}"; then
    log_skip "${SCRIPT_NAME} (already completed)"
    exit 0
fi

log_step "${SCRIPT_NAME}"

: "${PROJECT_ROOT:?PROJECT_ROOT not set}"
cd "$INSTALL_DIR"

# Create schema directory
mkdir -p "${SRC_DB_DIR:-src/db}/schema"

# Create users schema
if [[ ! -f "${SRC_DB_DIR:-src/db}/schema/users.ts" ]]; then
    cat > "${SRC_DB_DIR:-src/db}/schema/users.ts" << 'EOF'
import { pgTable, text, timestamp, uuid } from 'drizzle-orm/pg-core';

export const users = pgTable('users', {
  id: uuid('id').primaryKey().defaultRandom(),
  email: text('email').notNull().unique(),
  name: text('name'),
  passwordHash: text('password_hash'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

export type User = typeof users.$inferSelect;
export type NewUser = typeof users.$inferInsert;
EOF
    log_ok "Created users schema"
else
    log_skip "users schema already exists"
fi

# Update schema index to export users
SCHEMA_INDEX="${SRC_DB_DIR:-src/db}/schema/index.ts"
if [[ -f "$SCHEMA_INDEX" ]]; then
    if ! grep -q "export \* from './users'" "$SCHEMA_INDEX"; then
        # Remove placeholder and add users export
        sed -i.bak '/^export const _placeholder/d' "$SCHEMA_INDEX"
        echo "export * from './users';" >> "$SCHEMA_INDEX"
        rm -f "${SCHEMA_INDEX}.bak"
        log_ok "Updated schema index"
    fi
fi

mark_script_success "${SCRIPT_ID}"
log_ok "${SCRIPT_NAME} complete"
