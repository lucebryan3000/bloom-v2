#!/usr/bin/env bash
# =============================================================================
# tech_stack/_combined_scripts/install-package-pgboss.sh - Install pg-boss
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"
source "${SCRIPT_DIR}/../_lib/pkg-install.sh"

readonly SCRIPT_ID="_combined/install-package-pgboss"
readonly SCRIPT_NAME="Install pg-boss"

log_step "${SCRIPT_NAME}"
cd "${INSTALL_DIR}"

DEPS=("${PKG_PG_BOSS}")

log_info "Installing pg-boss..."
if ! pkg_install_retry "${DEPS[@]}"; then
    log_error "Failed to install pg-boss"
    exit 1
fi

pkg_verify_all "pg-boss" || {
    log_error "Package verification failed"
    exit 1
}

log_ok "${SCRIPT_NAME} complete"
