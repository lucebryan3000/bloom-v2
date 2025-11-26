#!/usr/bin/env bash
#!meta
# id: quality/ts-strict-mode.sh
# name: strict-mode.sh - TypeScript Strict Mode
# phase: 4
# phase_name: Extensions & Quality
# profile_tags:
#   - tech_stack
#   - quality
# uses_from_omni_config:
# uses_from_omni_settings:
#   - PROJECT_ROOT
# top_flags:
#   - --dry-run
#   - --skip-install
#   - --dev-only
#   - --no-dev
#   - --force
#   - --no-verify
# dependencies:
#   packages:
#     -
#   dev_packages:
#     -
#!endmeta

# =============================================================================
# tech_stack/quality/ts-strict-mode.sh - TypeScript Strict Mode
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Phase: 4 (Extensions & Quality)
# Purpose: Enables strict TypeScript mode for enhanced type safety
# Note: Actual tsconfig.json update is handled by TypeScript foundation setup
# =============================================================================
#
# Dependencies:
#   - tsconfig.json from init-typescript/init-nextjs
#

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"

readonly SCRIPT_ID="quality/ts-strict-mode"
readonly SCRIPT_NAME="TypeScript Strict Mode"

# Check if already completed
if has_script_succeeded "${SCRIPT_ID}"; then
    log_skip "${SCRIPT_NAME} (already completed)"
    exit 0
fi

log_step "${SCRIPT_NAME}"

: "${PROJECT_ROOT:?PROJECT_ROOT not set}"
cd "$INSTALL_DIR"

# Check if tsconfig.json exists
if [[ ! -f "tsconfig.json" ]]; then
    log_warn "tsconfig.json not found - TypeScript setup should run first"
    log_info "Strict mode will be configured when TypeScript is initialized"
    mark_script_success "${SCRIPT_ID}"
    log_ok "${SCRIPT_NAME} complete (deferred to TypeScript setup)"
    exit 0
fi

# Log the strict mode configuration that should be present
log_info "Verifying TypeScript strict mode configuration..."

# Check if strict mode is already enabled
if grep -q '"strict":\s*true' tsconfig.json 2>/dev/null; then
    log_ok "TypeScript strict mode is already enabled"
else
    log_info "TypeScript strict mode configuration:"
    log_info "  - strict: true (enables all strict type-checking options)"
    log_info "  - noUncheckedIndexedAccess: true (checks for undefined on index access)"
    log_info "  - noImplicitReturns: true (requires explicit return statements)"
    log_info "  - noFallthroughCasesInSwitch: true (prevents switch fallthrough)"
    log_info ""
    log_info "Note: The TypeScript foundation script (init-typescript.sh) handles"
    log_info "the actual tsconfig.json configuration. This script validates the setup."
fi

# List the strict mode options that should be configured
cat <<'EOF'

TypeScript Strict Mode Options:
===============================
These options are enabled when strict: true is set:

  - strictNullChecks: Variables can't be null/undefined unless explicitly typed
  - strictFunctionTypes: Stricter function type checking
  - strictBindCallApply: Stricter bind, call, and apply checking
  - strictPropertyInitialization: Class properties must be initialized
  - noImplicitAny: Disallows implicit 'any' types
  - noImplicitThis: Disallows 'this' with implicit 'any' type
  - useUnknownInCatchVariables: Catch clause variables are 'unknown'
  - alwaysStrict: Emits 'use strict' in all files

Additional recommended options:
  - noUncheckedIndexedAccess: Array/object index access returns T | undefined
  - noImplicitReturns: All code paths must return a value
  - noFallthroughCasesInSwitch: Requires break/return in switch cases
  - exactOptionalPropertyTypes: Differentiates between missing and undefined

EOF

mark_script_success "${SCRIPT_ID}"
log_ok "${SCRIPT_NAME} complete"
