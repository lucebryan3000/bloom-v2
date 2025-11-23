#!/usr/bin/env bash
# =============================================================================
# File: phases/11-quality/33-eslint-prettier.sh
# Purpose: Configure ESLint + Prettier
# Creates: .eslintrc.json, .prettierrc
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

readonly SCRIPT_ID="33"
readonly SCRIPT_NAME="eslint-prettier"
readonly SCRIPT_DESCRIPTION="Configure ESLint and Prettier"

usage() { cat <<EOF
Usage: $(basename "$0") [OPTIONS]
$SCRIPT_DESCRIPTION
EOF
}

main() {
    parse_common_args "$@"
    init_logging "$SCRIPT_NAME"

    log_step "Installing ESLint and Prettier dependencies"
    require_pnpm
    add_dependency "prettier" "true"
    add_dependency "eslint-config-prettier" "true"
    add_dependency "eslint-plugin-jsx-a11y" "true"

    log_step "Creating .prettierrc"

    local prettier='{
  "semi": true,
  "singleQuote": false,
  "tabWidth": 2,
  "trailingComma": "es5",
  "printWidth": 80,
  "plugins": []
}'

    write_file ".prettierrc" "$prettier"

    log_step "Creating .prettierignore"

    local prettierignore='node_modules
.next
build
dist
coverage
*.min.js
pnpm-lock.yaml
'

    write_file ".prettierignore" "$prettierignore"

    log_step "Updating ESLint config"

    if [[ -f ".eslintrc.json" ]]; then
        log_skip ".eslintrc.json exists"
    else
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
        write_file ".eslintrc.json" "$eslint"
    fi

    log_step "Adding format scripts"
    add_npm_script "format" "prettier --write ."
    add_npm_script "format:check" "prettier --check ."

    log_success "Script $SCRIPT_ID completed"
}

main "$@"
