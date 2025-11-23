#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SH="${SCRIPT_DIR%/*}/lib/common.sh"
[[ -f "${COMMON_SH}" ]] || { echo "ERROR: common.sh not found" >&2; exit 1; }
. "${COMMON_SH}"

SCRIPT_KEY="foundation/init-directory-structure.sh"

usage() { cat <<EOF
Create hybrid domain/feature directory structure for ${APP_NAME}.
Creates: src/features, src/lib, src/db, src/schemas, src/prompts, tests/
EOF
}

main() {
    parse_common_args "$@"
    [[ "${SHOW_HELP}" == "true" ]] && { usage; exit 0; }

    log_info "=== Creating Directory Structure ==="
    cd "${PROJECT_ROOT:-.}"

    local dirs=(
        "src/components" "src/components/ui" "src/components/layout"
        "src/db" "src/db/migrations"
        "src/lib" "src/lib/stores" "src/lib/jobs"
        "src/prompts" "src/schemas" "src/hooks"
        "src/features/chat" "src/features/review" "src/features/report"
        "src/features/projects" "src/features/settings"
        "src/app/(auth)" "src/app/workspace" "src/app/reports" "src/app/settings" "src/app/api"
        "tests/unit" "tests/integration" "tests/e2e" "tests/fixtures"
    )

    for dir in "${dirs[@]}"; do
        ensure_dir "${dir}"
        if [[ "${DRY_RUN:-false}" != "true" && ! -f "${dir}/.gitkeep" ]]; then
            touch "${dir}/.gitkeep"
        fi
    done

    mark_script_success "${SCRIPT_KEY}"
    log_success "Directory structure created"
}

main "$@"
