#!/usr/bin/env bash
# =============================================================================
# tech_stack/_combined_scripts/install-package-testing.sh - Install testing deps
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"
source "${SCRIPT_DIR}/../_lib/pkg-install.sh"

readonly SCRIPT_ID="_combined/install-package-testing"
readonly SCRIPT_NAME="Install Testing Dependencies"

log_step "${SCRIPT_NAME}"
cd "${INSTALL_DIR}"

DEV_DEPS=(
  "${PKG_VITEST}"
  "${PKG_VITEJS_PLUGIN_REACT}"
  "${PKG_TESTING_LIBRARY_REACT}"
  "${PKG_TESTING_LIBRARY_JEST_DOM}"
  "${PKG_JSDOM}"
  "${PKG_PLAYWRIGHT}"
)

log_info "Installing testing deps: ${DEV_DEPS[*]}"
if ! pkg_install_dev_retry "${DEV_DEPS[@]}"; then
    log_error "Failed to install testing deps"
    exit 1
fi

pkg_verify_all "vitest" "@playwright/test" "@testing-library/react" "@testing-library/jest-dom" "jsdom" || {
    log_error "Package verification failed"
    exit 1
}

log_ok "${SCRIPT_NAME} complete"
