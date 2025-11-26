#!/usr/bin/env bash
# =============================================================================
# tech_stack/_combined_scripts/install-package-package-json.sh - Initialize package.json
# =============================================================================
# Creates a minimal package.json if missing and ensures workspace is ready
# for subsequent package installs. Uses cache-aware installers indirectly.
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"

readonly SCRIPT_ID="_combined/install-package-package-json"
readonly SCRIPT_NAME="Initialize package.json"

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
