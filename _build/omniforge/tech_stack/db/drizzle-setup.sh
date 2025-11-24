#!/usr/bin/env bash
# =============================================================================
# db/drizzle-setup.sh - Drizzle ORM Setup
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Phase: 1 (Infrastructure)
# Wraps: core/01-database.sh
#
# This script delegates to the consolidated core/01-database.sh implementation.
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TECH_STACK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Delegate to consolidated implementation
exec "${TECH_STACK_DIR}/core/01-database.sh" "$@"
