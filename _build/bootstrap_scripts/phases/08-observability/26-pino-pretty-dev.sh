#!/usr/bin/env bash
# =============================================================================
# File: phases/08-observability/26-pino-pretty-dev.sh
# Purpose: Add dev logging convenience scripts
# Creates: npm scripts for log viewing
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

readonly SCRIPT_ID="26"
readonly SCRIPT_NAME="pino-pretty-dev"
readonly SCRIPT_DESCRIPTION="Add dev logging convenience scripts"

usage() { cat <<EOF
Usage: $(basename "$0") [OPTIONS]
$SCRIPT_DESCRIPTION
EOF
}

main() {
    parse_common_args "$@"
    init_logging "$SCRIPT_NAME"

    log_step "Adding logging scripts"
    require_file "package.json"

    add_npm_script "logs:pretty" "pino-pretty"
    add_npm_script "logs:docker" "docker compose logs -f web | pnpm logs:pretty"

    log_info "Usage: docker compose logs -f web | pnpm logs:pretty"
    log_success "Script $SCRIPT_ID completed"
}

main "$@"
