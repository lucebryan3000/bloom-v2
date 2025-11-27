#!/usr/bin/env bash
#!meta
# id: _combined_scripts/install-package-auth.sh
# name: package-auth.sh - Install Auth deps
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
#     - auth-drizzle-adapter
#     - next-auth
#   dev_packages:
#     -
#!endmeta

# =============================================================================
# tech_stack/_combined_scripts/install-package-auth.sh - Install Auth deps
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"
if command -v parse_stack_flags >/dev/null 2>&1; then
    parse_stack_flags "$@"
fi
source "${SCRIPT_DIR}/../_lib/pkg-install.sh"

readonly SCRIPT_ID="_combined/install-package-auth"
readonly SCRIPT_NAME="Install Auth.js Dependencies"

if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_skip "DRY_RUN: skipping ${SCRIPT_NAME}"
    exit 0
fi

log_step "${SCRIPT_NAME}"
cd "${INSTALL_DIR}"

DEPS=("${PKG_NEXT_AUTH}" "${PKG_AUTH_DRIZZLE_ADAPTER}")

log_info "Installing auth deps: ${DEPS[*]}"
if ! pkg_install_retry "${DEPS[@]}"; then
    log_error "Failed to install auth deps"
    exit 1
fi

pkg_verify_all "next-auth" "@auth/drizzle-adapter" || {
    log_error "Package verification failed"
    exit 1
}

log_ok "${SCRIPT_NAME} complete"
