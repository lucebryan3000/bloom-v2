#!/usr/bin/env bash
#!meta
# id: _combined_scripts/install-package-tailwind.sh
# name: package-tailwind.sh - Install Tailwind deps
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
#     - autoprefixer
#     - class-variance-authority
#     - clsx
#     - lucide-react
#     - postcss
#     - tailwindcss
#     - tailwind-merge
#   dev_packages:
#     - autoprefixer
#     - class-variance-authority
#     - clsx
#     - lucide-react
#     - postcss
#     - tailwindcss
#     - tailwind-merge
#!endmeta

# =============================================================================
# tech_stack/_combined_scripts/install-package-tailwind.sh - Install Tailwind deps
# =============================================================================
#
# Dependencies:
#   - tailwindcss
#   - postcss
#   - autoprefixer
#   - class-variance-authority
#   - clsx
#   - tailwind-merge
#   - lucide-react
#

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"
if command -v parse_stack_flags >/dev/null 2>&1; then
    parse_stack_flags "$@"
fi
source "${SCRIPT_DIR}/../_lib/pkg-install.sh"

readonly SCRIPT_ID="_combined/install-package-tailwind"
readonly SCRIPT_NAME="Install Tailwind + shadcn deps"

if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_skip "DRY_RUN: skipping ${SCRIPT_NAME}"
    exit 0
fi

log_step "${SCRIPT_NAME}"
cd "${INSTALL_DIR}"

DEV_DEPS=(
  "${PKG_TAILWINDCSS}"
  "${PKG_POSTCSS}"
  "${PKG_AUTOPREFIXER}"
  "${PKG_CLASS_VARIANCE_AUTHORITY}"
  "${PKG_CLSX}"
  "${PKG_TAILWIND_MERGE}"
  "${PKG_LUCIDE_REACT}"
  "@tailwindcss/postcss"
)

log_info "Installing Tailwind/shadcn dev deps: ${DEV_DEPS[*]}"
if ! pkg_install_dev_retry "${DEV_DEPS[@]}"; then
    log_error "Failed to install Tailwind/shadcn deps"
    exit 1
fi

pkg_verify_all "tailwindcss" "postcss" "autoprefixer" "clsx" "tailwind-merge" "lucide-react" "@tailwindcss/postcss" || {
    log_error "Package verification failed"
    exit 1
}

log_ok "${SCRIPT_NAME} complete"