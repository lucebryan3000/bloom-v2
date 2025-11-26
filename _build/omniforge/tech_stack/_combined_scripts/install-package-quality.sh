#!/usr/bin/env bash
#!meta
# id: _combined_scripts/install-package-quality.sh
# name: package-quality.sh - Install lint/format deps
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
#     - eslint
#     - eslint-config-prettier
#     - eslint-plugin-jsx-a11y
#     - husky
#     - lint-staged
#     - prettier
#     - prettier-plugin-tailwind
#     - typescript-eslint-parser
#     - typescript-eslint-plugin
#   dev_packages:
#     - eslint
#     - eslint-config-prettier
#     - eslint-plugin-jsx-a11y
#     - husky
#     - lint-staged
#     - prettier
#     - prettier-plugin-tailwind
#     - typescript-eslint-parser
#     - typescript-eslint-plugin
#!endmeta

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
