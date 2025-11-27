#!/usr/bin/env bash
#!meta
# id: db/drizzle-setup.sh
# name: drizzle-setup
# phase: 1
# phase_name: Infrastructure & Database
# profile_tags:
#   - tech_stack
#   - db
# uses_from_omni_config:
#   - DB_NAME
#   - DB_USER
#   - DB_PASSWORD
#   - DB_HOST
#   - DB_PORT
# uses_from_omni_settings:
#   - PROJECT_ROOT
#   - INSTALL_DIR
#   - POSTGRES_VERSION
#   - INSIDE_OMNI_DOCKER
#   - TECH_STACK_DIR
# required_vars:
#   - PROJECT_ROOT
#   - INSTALL_DIR
#   - POSTGRES_VERSION
#   - INSIDE_OMNI_DOCKER
#   - TECH_STACK_DIR
# top_flags:
# dependencies:
#   packages:
#     - drizzle-orm
#     - postgres
#   dev_packages:
#     - drizzle-kit
#!endmeta

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
if command -v parse_stack_flags >/dev/null 2>&1; then
    parse_stack_flags "$@"
fi

if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_skip "DRY_RUN: skipping Drizzle setup (delegates to core/database.sh)"
    exit 0
fi

# Delegate to consolidated implementation
# Ensure database client exists in container mode
if [[ -n "${INSIDE_OMNI_DOCKER:-}" ]]; then
    ensure_db_client "postgres"
fi

exec "${TECH_STACK_DIR}/core/database.sh" "$@"
