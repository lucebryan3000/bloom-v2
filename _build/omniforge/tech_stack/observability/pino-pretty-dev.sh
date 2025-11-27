#!/usr/bin/env bash
#!meta
# id: observability/pino-pretty-dev.sh
# name: pino pretty dev
# phase: 2
# phase_name: Core Features
# profile_tags:
#   - tech_stack
#   - observability
# uses_from_omni_config:
#   - ENABLE_OBSERVABILITY
# uses_from_omni_settings:
#   - PROJECT_ROOT
#   - INSTALL_DIR
#   - PKG_PINO_PRETTY
# required_vars:
#   - PROJECT_ROOT
#   - INSTALL_DIR
#   - PKG_PINO_PRETTY
# top_flags:
# dependencies:
#   packages:
#     - pino-pretty
#   dev_packages: []
#!endmeta

# =============================================================================
# observability/pino-pretty-dev.sh - Pino Pretty Dev Dependency
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Phase: 2 (Core Features)
# Purpose: Adds pino-pretty as a dev dependency for local development
#
# Note: This script only installs the dev dependency. The actual integration
# is handled by pino-logger.sh which configures the transport.
# =============================================================================
#
# Dependencies:
#   - pino-pretty (dev)
#

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"
if command -v parse_stack_flags >/dev/null 2>&1; then
    parse_stack_flags "$@"
fi
source "${SCRIPT_DIR}/../_lib/pkg-install.sh"

readonly SCRIPT_ID="observability/pino-pretty-dev"
readonly SCRIPT_NAME="Pino Pretty (Dev)"

if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_skip "DRY_RUN: skipping ${SCRIPT_NAME}"
    exit 0
fi

# =============================================================================
# PREFLIGHT
# =============================================================================

log_step "${SCRIPT_NAME} - Preflight"

# Check if already completed
if has_script_succeeded "${SCRIPT_ID}"; then
    log_skip "${SCRIPT_NAME} (already completed)"
    exit 0
fi

# Verify PROJECT_ROOT is set
if [[ -z "${PROJECT_ROOT:-}" ]]; then
    log_error "PROJECT_ROOT not set"
    exit 1
fi

# Verify project directory exists
if [[ ! -d "$INSTALL_DIR" ]]; then
    log_error "Project directory does not exist: $INSTALL_DIR"
    exit 1
fi

cd "$INSTALL_DIR"

# =============================================================================
# DEPENDENCY INSTALLATION
# =============================================================================

log_step "Installing pino-pretty (dev dependency)"

# pino-pretty package
PINO_PRETTY_PKG="${PKG_PINO_PRETTY:-pino-pretty}"

# Show cache status
pkg_preflight_check "${PINO_PRETTY_PKG}"

# Install as dev dependency
log_info "Installing ${PINO_PRETTY_PKG} as dev dependency..."
if ! pkg_verify_all "${PINO_PRETTY_PKG}"; then
    if ! pkg_install_dev_retry "${PINO_PRETTY_PKG}"; then
        log_error "Failed to install ${PINO_PRETTY_PKG}"
        exit 1
    fi
else
    log_skip "${PINO_PRETTY_PKG} already installed"
fi

# Verify installation
log_info "Verifying installation..."
pkg_verify "${PINO_PRETTY_PKG}" || {
    log_error "Package verification failed"
    exit 1
}

log_ok "pino-pretty installed"

# =============================================================================
# MARK SUCCESS
# =============================================================================

mark_script_success "${SCRIPT_ID}"
log_ok "${SCRIPT_NAME} complete"
