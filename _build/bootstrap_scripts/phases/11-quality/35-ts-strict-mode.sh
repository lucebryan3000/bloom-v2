#!/usr/bin/env bash
# =============================================================================
# File: phases/11-quality/35-ts-strict-mode.sh
# Purpose: Enable TypeScript strict mode and additional checks
# Modifies: tsconfig.json
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

readonly SCRIPT_ID="35"
readonly SCRIPT_NAME="ts-strict-mode"
readonly SCRIPT_DESCRIPTION="Enable TypeScript strict mode"

usage() { cat <<EOF
Usage: $(basename "$0") [OPTIONS]
$SCRIPT_DESCRIPTION
EOF
}

main() {
    parse_common_args "$@"
    init_logging "$SCRIPT_NAME"

    log_step "Configuring TypeScript strict mode"
    require_file "tsconfig.json" "Initialize TypeScript first"

    if [[ "$DRY_RUN" != "true" ]]; then
        node -e '
const fs = require("fs");
const tsconfig = JSON.parse(fs.readFileSync("tsconfig.json", "utf8"));

tsconfig.compilerOptions = {
  ...tsconfig.compilerOptions,
  strict: true,
  noUncheckedIndexedAccess: true,
  noImplicitReturns: true,
  noFallthroughCasesInSwitch: true,
  noUnusedLocals: true,
  noUnusedParameters: true,
  forceConsistentCasingInFileNames: true,
};

fs.writeFileSync("tsconfig.json", JSON.stringify(tsconfig, null, 2) + "\n");
'
        log_success "Enabled strict TypeScript settings"
    fi

    log_step "Adding type-check script"
    add_npm_script "typecheck" "tsc --noEmit"

    log_success "Script $SCRIPT_ID completed"
}

main "$@"
