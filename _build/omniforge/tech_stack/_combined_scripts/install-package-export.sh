#!/usr/bin/env bash
# =============================================================================
# tech_stack/_combined_scripts/install-package-export.sh - Install export deps
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"
source "${SCRIPT_DIR}/../_lib/pkg-install.sh"

readonly SCRIPT_ID="_combined/install-package-export"
readonly SCRIPT_NAME="Install Export Dependencies"

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
