#!/usr/bin/env bash
# =============================================================================
# foundation/init-typescript.sh - TypeScript Configuration
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Phase: 0 (Foundation)
# Note: TypeScript setup is handled by core/00-nextjs.sh which creates tsconfig.json
#
# This script is a no-op since TypeScript config is part of the Next.js setup.
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"

readonly SCRIPT_ID="foundation/init-typescript"
readonly SCRIPT_NAME="TypeScript Configuration"

# Check if already completed
if has_script_succeeded "${SCRIPT_ID}"; then
    log_skip "${SCRIPT_NAME} (already completed)"
    exit 0
fi

log_step "${SCRIPT_NAME}"

# TypeScript is configured by core/00-nextjs.sh
# This script validates the configuration exists

if [[ -f "${PROJECT_ROOT}/tsconfig.json" ]]; then
    log_ok "tsconfig.json already exists (created by init-nextjs.sh)"
else
    log_warn "tsconfig.json not found - run init-nextjs.sh first"
    exit 1
fi

mark_script_success "${SCRIPT_ID}"
log_ok "${SCRIPT_NAME} complete"
