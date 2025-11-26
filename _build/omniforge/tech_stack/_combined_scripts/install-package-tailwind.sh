#!/usr/bin/env bash
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
source "${SCRIPT_DIR}/../_lib/pkg-install.sh"

readonly SCRIPT_ID="_combined/install-package-tailwind"
readonly SCRIPT_NAME="Install Tailwind + shadcn deps"

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
)

log_info "Installing Tailwind/shadcn dev deps: ${DEV_DEPS[*]}"
if ! pkg_install_dev_retry "${DEV_DEPS[@]}"; then
    log_error "Failed to install Tailwind/shadcn deps"
    exit 1
fi

pkg_verify_all "tailwindcss" "postcss" "autoprefixer" "clsx" "tailwind-merge" "lucide-react" || {
    log_error "Package verification failed"
    exit 1
}

log_ok "${SCRIPT_NAME} complete"
