#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SH="${SCRIPT_DIR%/*}/lib/common.sh"
[[ -f "${COMMON_SH}" ]] || { echo "ERROR: common.sh not found" >&2; exit 1; }
. "${COMMON_SH}"

SCRIPT_KEY="foundation/init-package-engines.sh"

usage() { cat <<EOF
Set engines field in package.json for Node ${NODE_VERSION} and pnpm ${PNPM_VERSION}.
EOF
}

main() {
    parse_common_args "$@"
    [[ "${SHOW_HELP}" == "true" ]] && { usage; exit 0; }

    log_info "=== Setting Package Engines ==="
    cd "${PROJECT_ROOT:-.}"

    if grep -q '"engines"' package.json 2>/dev/null; then
        log_info "SKIP: engines already set in package.json"
    elif [[ "${DRY_RUN:-false}" != "true" ]]; then
        node -e "
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
pkg.engines = { node: '>=${NODE_VERSION}.0.0', pnpm: '>=${PNPM_VERSION}.0.0' };
pkg.packageManager = 'pnpm@${PNPM_VERSION}.0.0';
fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
"
        log_info "Set engines: node >=${NODE_VERSION}, pnpm >=${PNPM_VERSION}"
    fi

    mark_script_success "${SCRIPT_KEY}"
    log_success "Package engines configuration complete"
}

main "$@"
