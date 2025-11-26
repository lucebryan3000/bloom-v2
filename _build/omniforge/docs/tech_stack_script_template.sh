#!/usr/bin/env bash
# =============================================================================
# Canonical tech_stack script template
# Copy this file into _build/omniforge/tech_stack/<area>/<script>.sh and fill
# in metadata, package lists, and content blocks. Keep ASCII-only.
# =============================================================================

#!meta
# id: area/example            # unique id (path-like)
# name: Example Script        # human-readable name
# phase: 1                    # numeric phase
# phase_name: Infrastructure  # descriptive phase name
# profile_tags: ["ALL"]        # profile tags that include this script
# description: >
#   Short description of what this script installs/configures.
# uses_from_omni_config:
#   - APP_NAME        # application name
#   - APP_DESCRIPTION # short description
# uses_from_omni_settings:
#   - INSTALL_DIR     # project install directory
#   - SRC_LIB_DIR     # source lib directory
# top_flags:
#   - --dry-run       # plan only, no writes
#   - --skip-install  # generate files only, skip package install
#   - --no-verify     # skip post-install verification
# all_flags:
#   - --dry-run
#   - --skip-install
#   - --dev-only
#   - --no-dev
#   - --force
#   - --no-verify
# env_vars:
#   - OMNI_STACK_DRY_RUN
#   - OMNI_STACK_SKIP_INSTALL
#   - OMNI_STACK_DEV_ONLY
#   - OMNI_STACK_NO_DEV
#   - OMNI_STACK_FORCE
#   - OMNI_STACK_NO_VERIFY
#   - OMNI_EXAMPLE_SKIP      # script-specific overrides (adjust prefix)
# dependencies:
#   packages:
#     - pkg-one
#   dev_packages:
#     - pkg-one-dev
#!endmeta

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_ROOT="${SCRIPT_DIR%/tech_stack/*}/tech_stack"
source "${SCRIPT_DIR}/../../lib/common.sh"
source "${SCRIPT_DIR}/../_lib/pkg-install.sh"

readonly SCRIPT_ID="area/example"
readonly SCRIPT_NAME="Example Script"
readonly SCRIPT_PREFIX="EXAMPLE"  # used by parse_stack_flags env defaults

# Parse shared flags (requires parse_stack_flags in lib/common.sh)
if command -v parse_stack_flags >/dev/null 2>&1; then
    parse_stack_flags "$@"
else
    # Minimal fallback to avoid failures if helper is missing
    DRY_RUN=false; SKIP_INSTALL=false; DEV_ONLY=false; NO_DEV=false; FORCE=false; NO_VERIFY=false
fi

# =============================================================================
# PREFLIGHT
# =============================================================================

log_step "${SCRIPT_NAME} - Preflight"

# Honor script-specific skip env if desired
if [[ "${OMNI_${SCRIPT_PREFIX}_SKIP:-}" == "1" ]]; then
    log_skip "${SCRIPT_NAME} (skipped via env)"
    exit 0
fi

if ! ${FORCE:-false} && has_script_succeeded "${SCRIPT_ID}"; then
    log_skip "${SCRIPT_NAME} (already completed)"
    exit 0
fi

: "${PROJECT_ROOT:?PROJECT_ROOT not set}"
: "${INSTALL_DIR:?INSTALL_DIR not set}"
cd "${INSTALL_DIR}"

# =============================================================================
# INSTALL
# =============================================================================

RUNTIME_DEPS=("pkg-one")
DEV_DEPS=("pkg-one-dev")

if ! ${SKIP_INSTALL:-false}; then
    log_step "Installing packages"
    pkg_preflight_check "${RUNTIME_DEPS[@]}" "${DEV_DEPS[@]}"

    if [[ ${#RUNTIME_DEPS[@]} -gt 0 ]] && ! ${NO_DEV:-false}; then
        ${DRY_RUN:-false} || pkg_install "${RUNTIME_DEPS[@]}"
    fi

    if [[ ${#DEV_DEPS[@]} -gt 0 ]] && ! ${NO_DEV:-false}; then
        ${DRY_RUN:-false} || pkg_install_dev "${DEV_DEPS[@]}"
    fi
else
    log_skip "Package installation (skip-install flag)"
fi

# =============================================================================
# CONFIG/FILES
# =============================================================================

log_step "Generating files"
if ${DRY_RUN:-false}; then
    log_info "[dry-run] Would create/update files here"
else
    # Create or update files as needed
    : # placeholder for file writes (cat > file <<'EOF' ... EOF)
fi

# =============================================================================
# VERIFY
# =============================================================================

if ! ${NO_VERIFY:-false}; then
    log_step "Verifying installation"
    # Add checks (e.g., pkg_verify_all "pkg-one" "pkg-one-dev")
else
    log_skip "Verification (no-verify flag)"
fi

# =============================================================================
# MARK SUCCESS
# =============================================================================

if ! ${DRY_RUN:-false}; then
    mark_script_success "${SCRIPT_ID}"
    log_ok "${SCRIPT_NAME} complete"
else
    log_info "[dry-run] Success marker not written"
fi
