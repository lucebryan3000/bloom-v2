#!/usr/bin/env bash
# =============================================================================
# db/db-client-index.sh - Database Client Index Exports
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Phase: 1 (Infrastructure)
# Purpose: Create unified database client exports
#
# Creates/Updates:
#   - src/db/index.ts with all exports
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"

readonly SCRIPT_ID="db/db-client-index"
readonly SCRIPT_NAME="Database Client Index"

# Check if already completed
if has_script_succeeded "${SCRIPT_ID}"; then
    log_skip "${SCRIPT_NAME} (already completed)"
    exit 0
fi

log_step "${SCRIPT_NAME}"

: "${PROJECT_ROOT:?PROJECT_ROOT not set}"
cd "$INSTALL_DIR"

# Ensure db directory exists
mkdir -p "${SRC_DB_DIR:-src/db}"

# Verify db/index.ts exists (should be created by core/01-database)
if [[ ! -f "${SRC_DB_DIR:-src/db}/index.ts" ]]; then
    log_warn "src/db/index.ts not found - creating basic export"
    cat > "${SRC_DB_DIR:-src/db}/index.ts" << 'EOF'
/**
 * Database Client Exports
 * Re-exports all database utilities
 */

export * from './schema';

// Note: Database connection should be added by core/01-database.sh
// If you see this comment, run the database setup first.
EOF
    log_ok "Created ${SRC_DB_DIR:-src/db}/index.ts"
else
    log_skip "${SRC_DB_DIR:-src/db}/index.ts already exists"
fi

mark_script_success "${SCRIPT_ID}"
log_ok "${SCRIPT_NAME} complete"
