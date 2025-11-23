#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SH="${SCRIPT_DIR%/*}/lib/common.sh"
[[ -f "${COMMON_SH}" ]] || { echo "ERROR: common.sh not found" >&2; exit 1; }
. "${COMMON_SH}"

SCRIPT_KEY="docker/docker-pnpm-cache.sh"

main() {
    parse_common_args "$@"
    [[ "${SHOW_HELP}" == "true" ]] && { echo "Create .dockerignore for pnpm cache optimization"; exit 0; }

    log_info "=== Creating .dockerignore ==="
    cd "${PROJECT_ROOT:-.}"

    local dockerignore="node_modules
.pnpm-store
.next
out
build
dist
coverage
.git
.gitignore
.env
.env.local
.env.*.local
*.log
Dockerfile*
docker-compose*.yml
.dockerignore
scripts
_build
*.md
docs
test-results
playwright-report
"

    write_file_if_missing ".dockerignore" "${dockerignore}"
    mark_script_success "${SCRIPT_KEY}"
    log_success ".dockerignore created"
}

main "$@"
