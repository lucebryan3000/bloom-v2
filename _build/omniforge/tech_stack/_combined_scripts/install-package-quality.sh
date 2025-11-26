#!/usr/bin/env bash
# =============================================================================
# tech_stack/_combined_scripts/install-package-quality.sh - Install lint/format deps
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"
source "${SCRIPT_DIR}/../_lib/pkg-install.sh"

readonly SCRIPT_ID="_combined/install-package-quality"
readonly SCRIPT_NAME="Install Lint/Format Dependencies"

log_step "${SCRIPT_NAME}"
cd "${INSTALL_DIR}"

DEV_DEPS=(
  "${PKG_ESLINT}"
  "${PKG_ESLINT_CONFIG_PRETTIER}"
  "${PKG_ESLINT_PLUGIN_JSX_A11Y}"
  "${PKG_TYPESCRIPT_ESLINT_PLUGIN}"
  "${PKG_TYPESCRIPT_ESLINT_PARSER}"
  "${PKG_PRETTIER}"
  "${PKG_PRETTIER_PLUGIN_TAILWIND}"
  "${PKG_HUSKY}"
  "${PKG_LINT_STAGED}"
)

log_info "Installing quality deps: ${DEV_DEPS[*]}"
if ! pkg_install_dev_retry "${DEV_DEPS[@]}"; then
    log_error "Failed to install quality deps"
    exit 1
fi

pkg_verify_all "eslint" "prettier" "husky" "lint-staged" || {
    log_error "Package verification failed"
    exit 1
}

log_ok "${SCRIPT_NAME} complete"
