#!/usr/bin/env bash
# =============================================================================
# tech_stack/_combined_scripts/install-package-next.sh - Install Next.js + React deps
# =============================================================================
# Installs next/react/react-dom using cache-aware installer. Expects package.json
# to exist (created by install-package-package-json.sh).
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"
source "${SCRIPT_DIR}/../_lib/pkg-install.sh"

readonly SCRIPT_ID="_combined/install-package-next"
readonly SCRIPT_NAME="Install Next.js + React"

log_step "${SCRIPT_NAME}"

cd "${INSTALL_DIR}"

DEPS=("${PKG_NEXT}" "${PKG_REACT}" "${PKG_REACT_DOM}")

log_info "Installing deps: ${DEPS[*]}"
pkg_install "${DEPS[@]}" || {
    log_error "Failed to install Next.js/React deps"
    exit 1
}

log_info "Verifying installed packages..."
pkg_verify_all "next" "react" || {
    log_error "Package verification failed"
    exit 1
}

log_ok "${SCRIPT_NAME} complete"
