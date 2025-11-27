#!/usr/bin/env bash
#!meta
# id: auth/authjs-setup.sh
# name: authjs setup
# phase: 2
# phase_name: Core Features
# profile_tags:
#   - tech_stack
#   - auth
# uses_from_omni_config:
#   - ENABLE_AUTHJS
# uses_from_omni_settings:
#   - PROJECT_ROOT
#   - INSTALL_DIR
# required_vars:
#   - PROJECT_ROOT
#   - INSTALL_DIR
# top_flags:
# dependencies:
#   packages: []
#   dev_packages: []
#!endmeta

# =============================================================================
# tech_stack/auth/authjs-setup.sh - Auth.js Setup Wrapper
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Phase: 2
# Purpose: Wrapper script that delegates Auth.js setup to core/auth.sh
# =============================================================================
#
# Dependencies:
#   - delegates to core/auth (next-auth, @auth/drizzle-adapter)
#

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"
if command -v parse_stack_flags >/dev/null 2>&1; then
    parse_stack_flags "$@"
fi

readonly SCRIPT_ID="auth/authjs-setup"
readonly SCRIPT_NAME="Auth.js Setup"

if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_skip "DRY_RUN: skipping ${SCRIPT_NAME}"
    exit 0
fi

# Check if already completed
if has_script_succeeded "${SCRIPT_ID}"; then
    log_skip "${SCRIPT_NAME} (already completed)"
    exit 0
fi

log_step "${SCRIPT_NAME}"

# Delegate to core implementation
exec "${SCRIPT_DIR}/../core/auth.sh"
