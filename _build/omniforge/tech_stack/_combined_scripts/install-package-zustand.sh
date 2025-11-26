#!/usr/bin/env bash
#!meta
# id: _combined_scripts/install-package-zustand.sh
# name: package-zustand.sh - Install Zustand deps
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
#     - zustand
#   dev_packages:
#     -
#!endmeta

# =============================================================================
# tech_stack/_combined_scripts/install-package-zustand.sh - Install Zustand deps
# =============================================================================
#
# Dependencies:
#   - zustand
#

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"
source "${SCRIPT_DIR}/../_lib/pkg-install.sh"

readonly SCRIPT_ID="_combined/install-package-zustand"
readonly SCRIPT_NAME="Install Zustand"

log_step "${SCRIPT_NAME}"
cd "${INSTALL_DIR}"

DEPS=("${PKG_ZUSTAND}")

log_info "Installing zustand deps: ${DEPS[*]}"
if ! pkg_install_retry "${DEPS[@]}"; then
    log_error "Failed to install zustand"
    exit 1
fi

pkg_verify_all "zustand" || {
    log_error "Package verification failed"
    exit 1
}

log_ok "${SCRIPT_NAME} complete"
