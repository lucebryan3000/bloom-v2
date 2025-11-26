#!/usr/bin/env bash
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

readonly SCRIPT_ID="auth/authjs-setup"
readonly SCRIPT_NAME="Auth.js Setup"

# Check if already completed
if has_script_succeeded "${SCRIPT_ID}"; then
    log_skip "${SCRIPT_NAME} (already completed)"
    exit 0
fi

log_step "${SCRIPT_NAME}"

# Delegate to core implementation
exec "${SCRIPT_DIR}/../core/auth.sh"
