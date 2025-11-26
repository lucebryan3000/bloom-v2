#!/usr/bin/env bash
# =============================================================================
# tech_stack/_combined_scripts/install-package-drizzle.sh - Install Drizzle deps
# =============================================================================
# Installs drizzle orm/kit/postgres with retry and pnpm throttling.
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"
source "${SCRIPT_DIR}/../_lib/pkg-install.sh"

readonly SCRIPT_ID="_combined/install-package-drizzle"
readonly SCRIPT_NAME="Install Drizzle Packages"

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
