#!/usr/bin/env bash
#!meta
# id: _combined_scripts/install-package-drizzle.sh
# name: package-drizzle.sh - Install Drizzle deps
# phase: 0
# phase_name: Project Foundation
# profile_tags:
#   - tech_stack
#   - _combined_scripts
# uses_from_omni_config:
# uses_from_omni_settings:
#   - INSTALL_DIR
# required_vars:
#   - INSTALL_DIR
# top_flags:
#   - --dry-run
#   - --skip-install
#   - --dev-only
#   - --no-dev
#   - --force
#   - --no-verify
# dependencies:
#   packages:
#     - drizzle-kit
#     - drizzle-orm
#     - postgres-js
#   dev_packages:
#     -
#!endmeta

# =============================================================================
# tech_stack/_combined_scripts/install-package-drizzle.sh - Install Drizzle deps
# =============================================================================
# Installs drizzle orm/kit/postgres with retry and pnpm throttling.
# =============================================================================
#
# Dependencies:
#   - drizzle-orm
#   - drizzle-kit
#   - postgres
#

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"
if command -v parse_stack_flags >/dev/null 2>&1; then
    parse_stack_flags "$@"
fi
source "${SCRIPT_DIR}/../_lib/pkg-install.sh"

readonly SCRIPT_ID="_combined/install-package-drizzle"
readonly SCRIPT_NAME="Install Drizzle Packages"

if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_skip "DRY_RUN: skipping ${SCRIPT_NAME}"
    exit 0
fi

log_step "${SCRIPT_NAME}"
cd "${INSTALL_DIR}"

DEPS=("${PKG_DRIZZLE_ORM}" "${PKG_DRIZZLE_KIT}" "${PKG_POSTGRES_JS}")

log_info "Installing deps: ${DEPS[*]}"
if ! pkg_install_retry "${DEPS[@]}"; then
    log_error "Failed to install Drizzle deps"
    exit 1
fi

log_info "Verifying installed packages..."
pkg_verify_all "drizzle-orm" "drizzle-kit" "postgres" || {
    log_error "Package verification failed"
    exit 1
}

log_ok "${SCRIPT_NAME} complete"
