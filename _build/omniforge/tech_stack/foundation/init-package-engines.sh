#!/usr/bin/env bash
#!meta
# id: foundation/init-package-engines.sh
# name: init-package-engines
# phase: 0
# phase_name: Project Foundation
# profile_tags:
#   - tech_stack
#   - foundation
# uses_from_omni_config:
# uses_from_omni_settings:
#   - PROJECT_ROOT
#   - INSTALL_DIR
#   - NODE_VERSION
# required_vars:
#   - PROJECT_ROOT
#   - INSTALL_DIR
#   - NODE_VERSION
# top_flags:
# dependencies:
#   packages: []
#   dev_packages: []
#!endmeta

# =============================================================================
# foundation/init-package-engines.sh - Node/pnpm Engine Constraints
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Phase: 0 (Foundation)
# Purpose: Ensure package.json has correct engine constraints
#
# Verifies and updates the "engines" field in package.json to match
# the versions specified in omni.settings.sh.
# =============================================================================
#
# Dependencies:
#   - none (jq optional)
#

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"
if command -v parse_stack_flags >/dev/null 2>&1; then
    parse_stack_flags "$@"
fi

readonly SCRIPT_ID="foundation/init-package-engines"
readonly SCRIPT_NAME="Package Engine Constraints"

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

# Verify PROJECT_ROOT
: "${PROJECT_ROOT:?PROJECT_ROOT not set}"
cd "$INSTALL_DIR"

# Verify package.json exists
if [[ ! -f "package.json" ]]; then
    log_error "package.json not found - run init-nextjs.sh first"
    exit 1
fi

# Check if engines field exists and is correct
if command -v jq &>/dev/null; then
    current_node=$(jq -r '.engines.node // "not set"' package.json)
    expected_node=">=${NODE_VERSION:-20}.0.0"

    if [[ "$current_node" == "$expected_node" ]]; then
        log_ok "Engine constraints already set correctly"
    else
        log_info "Updating engine constraints..."
        jq --arg node "$expected_node" '.engines.node = $node' package.json > package.json.tmp
        mv package.json.tmp package.json
        log_ok "Updated engines.node to ${expected_node}"
    fi
else
    log_warn "jq not available, skipping engine validation"
fi

mark_script_success "${SCRIPT_ID}"
log_ok "${SCRIPT_NAME} complete"
