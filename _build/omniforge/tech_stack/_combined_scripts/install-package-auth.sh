#!/usr/bin/env bash
# =============================================================================
# tech_stack/_combined_scripts/install-package-auth.sh - Install Auth deps
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"
source "${SCRIPT_DIR}/../_lib/pkg-install.sh"

readonly SCRIPT_ID="_combined/install-package-auth"
readonly SCRIPT_NAME="Install Auth.js Dependencies"

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
