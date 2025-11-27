#!/usr/bin/env bash
#!meta
# id: _combined_scripts/install-package-typescript.sh
# name: package-typescript.sh - Install TypeScript deps
# phase: 0
# phase_name: Project Foundation
# profile_tags:
#   - tech_stack
#   - _combined_scripts
# uses_from_omni_config:
# uses_from_omni_settings:
#   - INSTALL_DIR
#   - NODE_OPTIONS
#   - PNPM_FLAGS
# top_flags:
#   - --dry-run
#   - --skip-install
#   - --dev-only
#   - --no-dev
#   - --force
#   - --no-verify
# dependencies:
#   packages:
#     - typescript
#     - types-node
#     - types-react
#     - types-react-dom
#     - zod
#   dev_packages:
#     - typescript
#     - types-node
#     - types-react
#     - types-react-dom
#     - zod
#!endmeta

# =============================================================================
# tech_stack/_combined_scripts/install-package-typescript.sh - Install TypeScript deps
# =============================================================================
# Installs typescript and type definitions using cache-aware installer.
# Expects package.json to exist (created by install-package-package-json.sh).
# =============================================================================
#
# Dependencies:
#   - typescript
#   - @types/node
#   - @types/react
#   - @types/react-dom
#

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"
if command -v parse_stack_flags >/dev/null 2>&1; then
    parse_stack_flags "$@"
fi
source "${SCRIPT_DIR}/../_lib/pkg-install.sh"

readonly SCRIPT_ID="_combined/install-package-typescript"
readonly SCRIPT_NAME="Install TypeScript + Types"

if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_skip "DRY_RUN: skipping ${SCRIPT_NAME}"
    exit 0
fi

log_step "${SCRIPT_NAME}"

cd "${INSTALL_DIR}"

RUNTIME_PKGS=("zod")
DEV_DEPS=("${PKG_TYPESCRIPT}" "${PKG_TYPES_NODE}" "${PKG_TYPES_REACT}" "${PKG_TYPES_REACT_DOM}")

log_info "Installing runtime deps: ${RUNTIME_PKGS[*]}"
pkg_install "${RUNTIME_PKGS[@]}" || {
    log_error "Failed to install runtime TypeScript deps"
    exit 1
}

log_info "Installing dev deps: ${DEV_DEPS[*]}"
PNPM_FLAGS_OVERRIDE="${PNPM_FLAGS:-}" NODE_OPTIONS="${NODE_OPTIONS:-}" pkg_install_dev "${DEV_DEPS[@]}" || {
    log_error "Failed to install TypeScript/type definitions"
    exit 1
}

log_info "Verifying TypeScript install..."
pkg_verify_all "typescript" || {
    log_error "Package verification failed"
    exit 1
}

log_ok "${SCRIPT_NAME} complete"