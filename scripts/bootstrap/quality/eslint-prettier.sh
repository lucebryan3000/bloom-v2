#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SH="${SCRIPT_DIR%/*}/lib/common.sh"
[[ -f "${COMMON_SH}" ]] || { echo "ERROR: common.sh not found" >&2; exit 1; }
. "${COMMON_SH}"

SCRIPT_KEY="quality/eslint-prettier.sh"

main() {
    parse_common_args "$@"
    [[ "${SHOW_HELP}" == "true" ]] && { echo "Setup ESLint and Prettier"; exit 0; }

    if [[ "${ENABLE_CODE_QUALITY:-true}" != "true" ]]; then
        log_info "SKIP: Code quality disabled via ENABLE_CODE_QUALITY"
        mark_script_success "${SCRIPT_KEY}"
        return 0
    fi

    log_info "=== Setting up ESLint and Prettier ==="
    cd "${PROJECT_ROOT:-.}"

    add_dependency "prettier" "true"
    add_dependency "eslint-config-prettier" "true"
    add_dependency "eslint-plugin-jsx-a11y" "true"

    local prettier='{
  "semi": true,
  "singleQuote": false,
  "tabWidth": 2,
  "trailingComma": "es5",
  "printWidth": 100,
  "plugins": []
}'
    write_file_if_missing ".prettierrc" "${prettier}"

    local prettierignore='node_modules
.next
build
dist
coverage
*.min.js
pnpm-lock.yaml
.env*
'
    write_file_if_missing ".prettierignore" "${prettierignore}"

    if [[ ! -f ".eslintrc.json" ]]; then
        local eslint='{
  "extends": [
    "next/core-web-vitals",
    "next/typescript",
    "plugin:jsx-a11y/recommended",
    "prettier"
  ],
  "plugins": ["jsx-a11y"],
  "rules": {
    "@typescript-eslint/no-unused-vars": ["error", { "argsIgnorePattern": "^_" }],
    "jsx-a11y/anchor-is-valid": "off"
  }
}'
        write_file_if_missing ".eslintrc.json" "${eslint}"
    else
        log_info "SKIP: .eslintrc.json already exists"
    fi

    add_npm_script "format" "prettier --write ."
    add_npm_script "format:check" "prettier --check ."

    mark_script_success "${SCRIPT_KEY}"
    log_success "ESLint and Prettier setup complete"
}

main "$@"
