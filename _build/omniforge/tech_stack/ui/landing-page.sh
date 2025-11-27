#!/usr/bin/env bash
#!meta
# id: ui/landing-page.sh
# name: OmniForge landing page (manifest-driven)
# phase: 3
# phase_name: User Interface
# profile_tags:
#   - tech_stack
#   - ui
# uses_from_omni_config:
#   - ENABLE_SHADCN
# uses_from_omni_settings:
#   - PROJECT_ROOT
#   - INSTALL_DIR
# required_vars:
#   - PROJECT_ROOT
#   - INSTALL_DIR
# top_flags:
# dependencies:
#   packages: []
#   dev_packages: []
#!endmeta

# =============================================================================
# tech_stack/ui/landing-page.sh - Install manifest-driven landing page
# =============================================================================
# Copies the OmniForge-branded landing page template into src/app/page.tsx.
# The template reads omni.manifest.json at runtime and falls back gracefully
# when the manifest is missing/invalid.
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"
if command -v parse_stack_flags >/dev/null 2>&1; then
    parse_stack_flags "$@"
fi

readonly SCRIPT_ID="ui/landing-page"
readonly SCRIPT_NAME="OmniForge Landing Page"

if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_skip "DRY_RUN: skipping ${SCRIPT_NAME}"
    exit 0
fi

log_step "${SCRIPT_NAME}"
: "${PROJECT_ROOT:?PROJECT_ROOT not set}"
cd "${INSTALL_DIR}"

TEMPLATE_PATH="${SCRIPTS_DIR}/templates/next/page.tsx"
TARGET_PATH="src/app/page.tsx"

if [[ ! -f "${TEMPLATE_PATH}" ]]; then
    log_error "Landing page template not found at ${TEMPLATE_PATH}"
    exit 1
fi

ensure_dir "$(dirname "${TARGET_PATH}")"
cp "${TEMPLATE_PATH}" "${TARGET_PATH}"
log_ok "Installed manifest-driven landing page to ${TARGET_PATH}"

mark_script_success "${SCRIPT_ID}"
log_ok "${SCRIPT_NAME} complete"
