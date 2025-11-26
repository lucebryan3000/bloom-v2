#!/usr/bin/env bash
# =============================================================================
# tech_stack/_combined_scripts/install-package-ai.sh - Install AI SDK deps
# =============================================================================
# Installs ai SDK packages with retry and pnpm throttling.
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"
source "${SCRIPT_DIR}/../_lib/pkg-install.sh"

readonly SCRIPT_ID="_combined/install-package-ai"
readonly SCRIPT_NAME="Install Vercel AI SDK"

log_step "${SCRIPT_NAME}"
cd "${INSTALL_DIR}"

DEPS=("${PKG_VERCEL_AI}" "${PKG_AI_SDK_OPENAI}" "${PKG_AI_SDK_ANTHROPIC}")

log_info "Installing AI deps: ${DEPS[*]}"
if ! pkg_install_retry "${DEPS[@]}"; then
    log_error "Failed to install AI deps"
    exit 1
fi

log_info "Verifying installed packages..."
pkg_verify_all "ai" "@ai-sdk/openai" "@ai-sdk/anthropic" || {
    log_error "Package verification failed"
    exit 1
}

log_ok "${SCRIPT_NAME} complete"
