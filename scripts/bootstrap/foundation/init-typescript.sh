#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SH="${SCRIPT_DIR%/*}/lib/common.sh"
[[ -f "${COMMON_SH}" ]] || { echo "ERROR: common.sh not found" >&2; exit 1; }
. "${COMMON_SH}"

SCRIPT_KEY="foundation/init-typescript.sh"

usage() { cat <<EOF
Configure TypeScript with strict mode and path aliases.
Uses: PKG_TYPESCRIPT, PKG_TYPES_NODE, PKG_TYPES_REACT, PKG_TYPES_REACT_DOM
EOF
}

main() {
    parse_common_args "$@"
    [[ "${SHOW_HELP}" == "true" ]] && { usage; exit 0; }

    log_info "=== Configuring TypeScript ==="
    cd "${PROJECT_ROOT:-.}"

    add_dependency "${PKG_TYPESCRIPT}" true
    add_dependency "${PKG_TYPES_NODE}" true
    add_dependency "${PKG_TYPES_REACT}" true
    add_dependency "${PKG_TYPES_REACT_DOM}" true

    if [[ -f "tsconfig.json" ]] && grep -q '"strict": true' tsconfig.json; then
        log_info "SKIP: tsconfig.json already has strict mode"
    elif [[ "${DRY_RUN:-false}" != "true" ]]; then
        node -e "
const fs = require('fs');
const cfg = JSON.parse(fs.readFileSync('tsconfig.json', 'utf8'));
cfg.compilerOptions = { ...cfg.compilerOptions, strict: true, baseUrl: '.', paths: { '@/*': ['./src/*'] } };
fs.writeFileSync('tsconfig.json', JSON.stringify(cfg, null, 2) + '\n');
"
        log_info "Updated tsconfig.json with strict mode"
    fi

    mark_script_success "${SCRIPT_KEY}"
    log_success "TypeScript configuration complete"
}

main "$@"
