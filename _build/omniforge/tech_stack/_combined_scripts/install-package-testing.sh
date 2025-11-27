#!/usr/bin/env bash
#!meta
# id: _combined_scripts/install-package-testing.sh
# name: package-testing.sh - Install testing deps
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
#     - jsdom
#     - playwright
#     - testing-library-jest-dom
#     - testing-library-react
#     - vitejs-plugin-react
#     - vitest
#   dev_packages:
#     - jsdom
#     - playwright
#     - testing-library-jest-dom
#     - testing-library-react
#     - vitejs-plugin-react
#     - vitest
#!endmeta

# =============================================================================
# tech_stack/_combined_scripts/install-package-testing.sh - Install testing deps
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"
if command -v parse_stack_flags >/dev/null 2>&1; then
    parse_stack_flags "$@"
fi
source "${SCRIPT_DIR}/../_lib/pkg-install.sh"

readonly SCRIPT_ID="_combined/install-package-testing"
readonly SCRIPT_NAME="Install Testing Dependencies"

if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_skip "DRY_RUN: skipping ${SCRIPT_NAME}"
    exit 0
fi

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
