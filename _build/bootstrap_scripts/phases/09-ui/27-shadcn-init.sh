#!/usr/bin/env bash
# =============================================================================
# File: phases/09-ui/27-shadcn-init.sh
# Purpose: Initialize shadcn/ui with Tailwind
# Creates: components.json, base components
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

readonly SCRIPT_ID="27"
readonly SCRIPT_NAME="shadcn-init"
readonly SCRIPT_DESCRIPTION="Initialize shadcn/ui component library"

usage() { cat <<EOF
Usage: $(basename "$0") [OPTIONS]
$SCRIPT_DESCRIPTION
EOF
}

main() {
    parse_common_args "$@"
    init_logging "$SCRIPT_NAME"

    log_step "Checking for existing shadcn config"
    if [[ -f "components.json" ]]; then
        log_skip "shadcn/ui already initialized"
        return 0
    fi

    log_step "Creating shadcn/ui configuration"

    local components_json='{
  "$schema": "https://ui.shadcn.com/schema.json",
  "style": "default",
  "rsc": true,
  "tsx": true,
  "tailwind": {
    "config": "tailwind.config.ts",
    "css": "src/app/globals.css",
    "baseColor": "slate",
    "cssVariables": true,
    "prefix": ""
  },
  "aliases": {
    "components": "@/components",
    "utils": "@/lib/utils",
    "ui": "@/components/ui",
    "lib": "@/lib",
    "hooks": "@/hooks"
  }
}'

    write_file "components.json" "$components_json"

    log_step "Creating UI components directory"
    ensure_dir "src/components/ui"
    add_gitkeep "src/components/ui"

    log_step "Creating hooks directory"
    ensure_dir "src/hooks"
    add_gitkeep "src/hooks"

    log_info "Run 'pnpm dlx shadcn@latest add button' to add components"
    log_success "Script $SCRIPT_ID completed"
}

main "$@"
