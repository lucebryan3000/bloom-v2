#!/usr/bin/env bash
# =============================================================================
# foundation/init-typescript.sh - TypeScript Configuration
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Phase: 0 (Foundation)
# Note: TypeScript setup is handled by core/nextjs.sh which creates tsconfig.json
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

# TypeScript is configured by core/nextjs.sh
# This script validates and enhances the configuration

if [[ ! -f "${INSTALL_DIR}/tsconfig.json" ]]; then
    log_warn "tsconfig.json not found - run init-nextjs.sh first"
    exit 1
fi

log_info "Enhancing tsconfig.json with exclusion patterns..."

# Add exclusions for common non-source directories to prevent compilation errors
# Using jq to safely modify JSON (fallback to basic sed if jq not available)
if command -v jq &>/dev/null; then
    # Use jq for safe JSON modification
    jq '.exclude += [
        "_AppModules-Luce/**/*",
        "_build/**/*",
        "**/*.backup.ts",
        "**/*.old.ts",
        "**/archive/**/*",
        "**/backup/**/*"
    ] | .exclude |= unique' \
    "${INSTALL_DIR}/tsconfig.json" > "${INSTALL_DIR}/tsconfig.json.tmp" \
    && mv "${INSTALL_DIR}/tsconfig.json.tmp" "${INSTALL_DIR}/tsconfig.json"

    log_ok "Added exclusion patterns using jq"
else
    # Fallback: manual JSON editing (less safe but works)
    log_warn "jq not found - using fallback method"

    # Check if exclude already has our patterns
    if ! grep -q "_AppModules-Luce" "${INSTALL_DIR}/tsconfig.json"; then
        # Add exclusions before the closing bracket of exclude array
        sed -i '/"exclude": \[/,/\]/ {
            /\]/ i\    "_AppModules-Luce/**/*",\n    "_build/**/*",\n    "**/*.backup.ts",\n    "**/*.old.ts",\n    "**/archive/**/*",\n    "**/backup/**/*",
        }' "${INSTALL_DIR}/tsconfig.json"

        log_ok "Added exclusion patterns using sed"
    else
        log_skip "Exclusion patterns already present"
    fi
fi

log_ok "tsconfig.json validated and enhanced"

mark_script_success "${SCRIPT_ID}"
log_ok "${SCRIPT_NAME} complete"
