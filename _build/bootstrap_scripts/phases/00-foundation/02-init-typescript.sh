#!/usr/bin/env bash
# =============================================================================
# File: phases/00-foundation/02-init-typescript.sh
# Purpose: Ensure TypeScript is configured correctly with strict mode
# Assumes: Next.js project exists (package.json present)
# Creates/Modifies: tsconfig.json
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

# =============================================================================
# METADATA
# =============================================================================
readonly SCRIPT_ID="02"
readonly SCRIPT_NAME="init-typescript"
readonly SCRIPT_DESCRIPTION="Configure TypeScript with strict mode and path aliases"

# =============================================================================
# USAGE
# =============================================================================
usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

$SCRIPT_DESCRIPTION

OPTIONS:
    -h, --help      Show this help message and exit
    -n, --dry-run   Show what would be done without making changes
    -v, --verbose   Enable verbose output

EXAMPLES:
    $(basename "$0")              # Configure TypeScript
    $(basename "$0") --dry-run    # Preview changes

WHAT THIS SCRIPT DOES:
    1. Installs TypeScript and type definitions if missing
    2. Configures tsconfig.json with strict mode
    3. Sets up path aliases (@/*)
    4. Enables recommended compiler options

EOF
}

# =============================================================================
# MAIN LOGIC
# =============================================================================
main() {
    parse_common_args "$@"
    init_logging "$SCRIPT_NAME"

    log_step "Starting TypeScript configuration"

    # Step 1: Check prerequisites
    log_step "Checking prerequisites"
    require_pnpm
    require_file "package.json" "Run 01-init-nextjs15.sh first"

    # Step 2: Install TypeScript dependencies
    log_step "Installing TypeScript dependencies"

    add_dependency "typescript" "true"
    add_dependency "@types/node" "true"
    add_dependency "@types/react" "true"
    add_dependency "@types/react-dom" "true"

    # Step 3: Configure tsconfig.json
    log_step "Configuring tsconfig.json"

    local tsconfig_content='{
  "compilerOptions": {
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [
      {
        "name": "next"
      }
    ],
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    },
    "forceConsistentCasingInFileNames": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "exactOptionalPropertyTypes": true
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}'

    if [[ -f "tsconfig.json" ]]; then
        log_info "tsconfig.json exists, updating with strict settings"
        if [[ "$DRY_RUN" == "true" ]]; then
            log_dry "Update tsconfig.json with strict mode"
        else
            # Use node to merge configs
            node -e "
const fs = require('fs');
const existing = JSON.parse(fs.readFileSync('tsconfig.json', 'utf8'));
const updates = {
    compilerOptions: {
        ...existing.compilerOptions,
        strict: true,
        baseUrl: '.',
        paths: { '@/*': ['./src/*'] },
        forceConsistentCasingInFileNames: true,
        noUncheckedIndexedAccess: true,
        noImplicitReturns: true,
        noFallthroughCasesInSwitch: true,
        noUnusedLocals: true,
        noUnusedParameters: true
    }
};
const merged = { ...existing, ...updates, compilerOptions: { ...existing.compilerOptions, ...updates.compilerOptions } };
fs.writeFileSync('tsconfig.json', JSON.stringify(merged, null, 2) + '\n');
"
            log_success "Updated tsconfig.json with strict settings"
        fi
    else
        write_file "tsconfig.json" "$tsconfig_content"
    fi

    # Step 4: Verify configuration
    log_step "Verifying TypeScript configuration"

    if [[ "$DRY_RUN" != "true" ]]; then
        if grep -q '"strict": true' tsconfig.json; then
            log_success "TypeScript strict mode enabled"
        else
            log_warn "Could not verify strict mode - please check tsconfig.json manually"
        fi
    fi

    log_success "Script $SCRIPT_ID completed"
}

main "$@"
