#!/usr/bin/env bash
# =============================================================================
# File: phases/00-foundation/03-init-package-engines.sh
# Purpose: Set engines field in package.json to Node 20 and pnpm 9
# Assumes: package.json exists
# Modifies: package.json
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

# =============================================================================
# METADATA
# =============================================================================
readonly SCRIPT_ID="03"
readonly SCRIPT_NAME="init-package-engines"
readonly SCRIPT_DESCRIPTION="Set Node.js and pnpm version requirements in package.json"

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
    $(basename "$0")              # Set engine requirements
    $(basename "$0") --dry-run    # Preview changes

WHAT THIS SCRIPT DOES:
    1. Adds or updates 'engines' field in package.json
    2. Sets Node.js requirement to >=20.0.0
    3. Sets pnpm requirement to >=9.0.0
    4. Adds packageManager field for pnpm

EOF
}

# =============================================================================
# MAIN LOGIC
# =============================================================================
main() {
    parse_common_args "$@"
    init_logging "$SCRIPT_NAME"

    log_step "Starting package engines configuration"

    # Step 1: Check prerequisites
    log_step "Checking prerequisites"
    require_file "package.json" "Run 01-init-nextjs15.sh first"

    # Step 2: Check if engines already configured
    log_step "Checking existing engines configuration"

    if grep -q '"engines"' package.json && grep -q '"node".*">=20' package.json; then
        log_skip "Engines already configured for Node 20+"
    else
        log_step "Configuring engines field"

        if [[ "$DRY_RUN" == "true" ]]; then
            log_dry "Add engines: { node: '>=20.0.0', pnpm: '>=9.0.0' }"
        else
            node -e "
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
pkg.engines = {
    node: '>=20.0.0',
    pnpm: '>=9.0.0'
};
fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
"
            log_success "Added engines field to package.json"
        fi
    fi

    # Step 3: Add packageManager field
    log_step "Configuring packageManager field"

    if grep -q '"packageManager"' package.json; then
        log_skip "packageManager already configured"
    else
        if [[ "$DRY_RUN" == "true" ]]; then
            log_dry "Add packageManager: 'pnpm@9.0.0'"
        else
            # Get current pnpm version
            local pnpm_version
            pnpm_version=$(pnpm --version 2>/dev/null || echo "9.0.0")

            node -e "
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
pkg.packageManager = 'pnpm@$pnpm_version';
fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
"
            log_success "Added packageManager field: pnpm@$pnpm_version"
        fi
    fi

    # Step 4: Display final engines config
    log_step "Verifying configuration"

    if [[ "$DRY_RUN" != "true" ]]; then
        log_info "Current engines configuration:"
        node -e "
const pkg = JSON.parse(require('fs').readFileSync('package.json', 'utf8'));
console.log('  engines:', JSON.stringify(pkg.engines || {}, null, 4));
console.log('  packageManager:', pkg.packageManager || 'not set');
"
    fi

    log_success "Script $SCRIPT_ID completed"
}

main "$@"
