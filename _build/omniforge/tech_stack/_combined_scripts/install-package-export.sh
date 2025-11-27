#!/usr/bin/env bash
#!meta
# id: _combined_scripts/install-package-export.sh
# name: package-export.sh - Install export deps
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
#     - exceljs
#     - html2canvas
#     - jspdf
#     - types-exceljs
#   dev_packages:
#     -
#!endmeta

# =============================================================================
# tech_stack/_combined_scripts/install-package-export.sh - Install export deps
# =============================================================================
#
# Dependencies:
#   - jspdf
#   - html2canvas
#   - exceljs
#   - @types/exceljs
#

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"
if command -v parse_stack_flags >/dev/null 2>&1; then
    parse_stack_flags "$@"
fi
source "${SCRIPT_DIR}/../_lib/pkg-install.sh"

readonly SCRIPT_ID="_combined/install-package-export"
readonly SCRIPT_NAME="Install Export Dependencies"

if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_skip "DRY_RUN: skipping ${SCRIPT_NAME}"
    exit 0
fi

log_step "${SCRIPT_NAME}"
cd "${INSTALL_DIR}"

DEPS=("${PKG_JSPDF}" "${PKG_HTML2CANVAS}" "${PKG_EXCELJS}" "${PKG_TYPES_EXCELJS}")

log_info "Installing export deps: ${DEPS[*]}"
if ! pkg_install_retry "${DEPS[@]}"; then
    log_error "Failed to install export deps"
    exit 1
fi

pkg_verify_all "jspdf" "html2canvas" "exceljs" "@types/exceljs" || {
    log_error "Package verification failed"
    exit 1
}

log_ok "${SCRIPT_NAME} complete"
