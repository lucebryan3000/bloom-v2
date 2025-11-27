#!/usr/bin/env bash
#!meta
# id: _combined_scripts/install-package-react-to-print.sh
# name: package-react-to-print.sh - Install react-to-print
# phase: 0
# phase_name: Project Foundation
# profile_tags:
#   - tech_stack
#   - _combined_scripts
# uses_from_omni_config:
# uses_from_omni_settings:
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
#     - -react-to-print
#     - react-to-print
#   dev_packages:
#     -
#!endmeta

# =============================================================================
# tech_stack/_combined_scripts/install-package-react-to-print.sh - Install react-to-print
# =============================================================================
#
# Dependencies:
#   - react-to-print
#

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"
if command -v parse_stack_flags >/dev/null 2>&1; then
    parse_stack_flags "$@"
fi
source "${SCRIPT_DIR}/../_lib/pkg-install.sh"

readonly SCRIPT_ID="_combined/install-package-react-to-print"
readonly SCRIPT_NAME="Install react-to-print"

if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_skip "DRY_RUN: skipping ${SCRIPT_NAME}"
    exit 0
fi

log_step "${SCRIPT_NAME}"
cd "${INSTALL_DIR}"

DEPS=("${PKG_REACT_TO_PRINT:-react-to-print}")

log_info "Installing react-to-print..."
if ! pkg_install_retry "${DEPS[@]}"; then
    log_error "Failed to install react-to-print"
    exit 1
fi

pkg_verify_all "react-to-print" || {
    log_error "Package verification failed"
    exit 1
}

log_ok "${SCRIPT_NAME} complete"