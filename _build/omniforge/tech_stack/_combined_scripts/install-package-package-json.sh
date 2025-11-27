#!/usr/bin/env bash
#!meta
# id: _combined_scripts/install-package-package-json.sh
# name: package-package-json.sh - Initialize package.json
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
#     -
#   dev_packages:
#     -
#!endmeta

# =============================================================================
# tech_stack/_combined_scripts/install-package-package-json.sh - Initialize package.json
# =============================================================================
# Creates a minimal package.json if missing and ensures workspace is ready
# for subsequent package installs. Uses cache-aware installers indirectly.
# =============================================================================
#
# Dependencies:
#   - none (bootstrap package.json)
#

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"
if command -v parse_stack_flags >/dev/null 2>&1; then
    parse_stack_flags "$@"
fi

readonly SCRIPT_ID="_combined/install-package-package-json"
readonly SCRIPT_NAME="Initialize package.json"

if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_skip "DRY_RUN: skipping ${SCRIPT_NAME}"
    exit 0
fi

log_step "${SCRIPT_NAME}"

mkdir -p "${INSTALL_DIR}"
cd "${INSTALL_DIR}"

if [[ ! -f "package.json" ]]; then
    cat > package.json <<EOF
{
  "name": "full-stack-app",
  "version": "0.1.0",
  "private": true,
  "type": "module"
}
EOF
    log_ok "Created package.json"
else
    log_skip "package.json already exists"
fi

log_ok "${SCRIPT_NAME} complete"
