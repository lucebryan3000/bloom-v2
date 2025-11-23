#!/usr/bin/env bash
# =============================================================================
# File: phases/11-quality/34-husky-lintstaged.sh
# Purpose: Set up Husky + lint-staged for pre-commit hooks
# Creates: .husky/pre-commit, lint-staged config
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

readonly SCRIPT_ID="34"
readonly SCRIPT_NAME="husky-lintstaged"
readonly SCRIPT_DESCRIPTION="Set up Husky and lint-staged"

usage() { cat <<EOF
Usage: $(basename "$0") [OPTIONS]
$SCRIPT_DESCRIPTION
EOF
}

main() {
    parse_common_args "$@"
    init_logging "$SCRIPT_NAME"

    log_step "Installing Husky and lint-staged"
    require_pnpm
    add_dependency "husky" "true"
    add_dependency "lint-staged" "true"

    log_step "Adding lint-staged config to package.json"

    if [[ "$DRY_RUN" != "true" ]]; then
        node -e '
const fs = require("fs");
const pkg = JSON.parse(fs.readFileSync("package.json", "utf8"));
pkg["lint-staged"] = {
  "*.{js,jsx,ts,tsx}": ["eslint --fix", "prettier --write"],
  "*.{json,md,yml,yaml}": ["prettier --write"]
};
fs.writeFileSync("package.json", JSON.stringify(pkg, null, 2) + "\n");
'
        log_success "Added lint-staged config"
    fi

    log_step "Adding prepare script"
    add_npm_script "prepare" "husky"

    log_step "Creating Husky hooks"

    if [[ "$DRY_RUN" != "true" ]]; then
        # Initialize husky
        run_cmd "pnpm exec husky init" || true

        # Create pre-commit hook
        ensure_dir ".husky"
        echo "pnpm exec lint-staged" > .husky/pre-commit
        chmod +x .husky/pre-commit
        log_success "Created pre-commit hook"
    fi

    log_success "Script $SCRIPT_ID completed"
}

main "$@"
