#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SH="${SCRIPT_DIR%/*}/lib/common.sh"
[[ -f "${COMMON_SH}" ]] || { echo "ERROR: common.sh not found" >&2; exit 1; }
. "${COMMON_SH}"

SCRIPT_KEY="quality/husky-lintstaged.sh"

main() {
    parse_common_args "$@"
    [[ "${SHOW_HELP}" == "true" ]] && { echo "Setup Husky and lint-staged"; exit 0; }

    if [[ "${ENABLE_CODE_QUALITY:-true}" != "true" ]]; then
        log_info "SKIP: Code quality disabled via ENABLE_CODE_QUALITY"
        mark_script_success "${SCRIPT_KEY}"
        return 0
    fi

    log_info "=== Setting up Husky and lint-staged ==="
    cd "${PROJECT_ROOT:-.}"

    add_dependency "husky" "true"
    add_dependency "lint-staged" "true"

    local lintstaged='{
  "*.{js,jsx,ts,tsx}": [
    "eslint --fix",
    "prettier --write"
  ],
  "*.{json,md,yml,yaml}": [
    "prettier --write"
  ],
  "*.css": [
    "prettier --write"
  ]
}'
    write_file_if_missing ".lintstagedrc" "${lintstaged}"

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "DRY RUN: Would initialize husky"
    else
        if [[ -d ".git" ]]; then
            run_cmd "pnpm exec husky init" || true

            ensure_dir ".husky"

            local pre_commit='#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

pnpm lint-staged
'
            write_file_if_missing ".husky/pre-commit" "${pre_commit}"
            chmod +x ".husky/pre-commit" 2>/dev/null || true

            local commit_msg='#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

# Conventional commits validation (optional)
# npx --no -- commitlint --edit "$1"
'
            write_file_if_missing ".husky/commit-msg" "${commit_msg}"
            chmod +x ".husky/commit-msg" 2>/dev/null || true
        else
            log_warn "Not a git repository, skipping husky init"
        fi
    fi

    add_npm_script "prepare" "husky"
    add_npm_script "lint-staged" "lint-staged"

    mark_script_success "${SCRIPT_KEY}"
    log_success "Husky and lint-staged setup complete"
}

main "$@"
