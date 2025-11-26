#!/usr/bin/env bash
# =============================================================================
# tech_stack/_combined_scripts/install-package-react-to-print.sh - Install react-to-print
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"
source "${SCRIPT_DIR}/../_lib/pkg-install.sh"

readonly SCRIPT_ID="_combined/install-package-react-to-print"
readonly SCRIPT_NAME="Install react-to-print"

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
