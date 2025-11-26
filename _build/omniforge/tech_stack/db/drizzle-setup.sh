#!/usr/bin/env bash
# =============================================================================
# db/drizzle-setup.sh - Drizzle ORM Setup
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Phase: 1 (Infrastructure)
# Wraps: core/database.sh
#
# This script delegates to the consolidated core/database.sh implementation.
# =============================================================================
#
# Dependencies:
#   - delegates to core/database (drizzle-orm, postgres)
#

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TECH_STACK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"

# Delegate to consolidated implementation
# Ensure database client exists in container mode
if [[ -n "${INSIDE_OMNI_DOCKER:-}" ]]; then
    ensure_db_client "postgres"
fi

exec "${TECH_STACK_DIR}/core/database.sh" "$@"
