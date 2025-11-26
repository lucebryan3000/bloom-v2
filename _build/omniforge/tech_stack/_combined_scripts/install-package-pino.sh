#!/usr/bin/env bash
# =============================================================================
# tech_stack/_combined_scripts/install-package-pino.sh - Install Pino deps
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"
source "${SCRIPT_DIR}/../_lib/pkg-install.sh"

readonly SCRIPT_ID="_combined/install-package-pino"
readonly SCRIPT_NAME="Install Pino Logger Deps"

log_step "${SCRIPT_NAME}"
cd "${INSTALL_DIR}"

DEPS=("${PKG_PINO}" "${PKG_PINO_PRETTY}")

log_info "Installing pino deps: ${DEPS[*]}"
if ! pkg_install_retry "${DEPS[@]}"; then
    log_error "Failed to install pino deps"
    exit 1
fi

pkg_verify_all "pino" "pino-pretty" || {
    log_error "Package verification failed"
    exit 1
}

log_ok "${SCRIPT_NAME} complete"
