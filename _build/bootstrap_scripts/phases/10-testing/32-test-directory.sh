#!/usr/bin/env bash
# =============================================================================
# File: phases/10-testing/32-test-directory.sh
# Purpose: Create test directory structure with .gitkeep
# Creates: tests/unit, tests/integration, tests/e2e
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

readonly SCRIPT_ID="32"
readonly SCRIPT_NAME="test-directory"
readonly SCRIPT_DESCRIPTION="Create test directory structure"

usage() { cat <<EOF
Usage: $(basename "$0") [OPTIONS]
$SCRIPT_DESCRIPTION
EOF
}

main() {
    parse_common_args "$@"
    init_logging "$SCRIPT_NAME"

    log_step "Creating test directories"

    local dirs=("tests/unit" "tests/integration" "tests/e2e" "tests/fixtures")
    for dir in "${dirs[@]}"; do
        ensure_dir "$dir"
        add_gitkeep "$dir"
    done

    log_step "Creating example unit test"

    local example_unit='import { describe, it, expect } from "vitest";

describe("Example", () => {
  it("should pass", () => {
    expect(1 + 1).toBe(2);
  });
});
'
    write_file "tests/unit/example.test.ts" "$example_unit"

    log_success "Script $SCRIPT_ID completed"
}

main "$@"
