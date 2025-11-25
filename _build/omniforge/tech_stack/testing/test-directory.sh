#!/usr/bin/env bash
# =============================================================================
# tech_stack/testing/test-directory.sh - Test Directory Structure
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Phase: 4 (Extensions & Quality)
# Purpose: Creates standardized test directory structure for unit and integration tests
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"

readonly SCRIPT_ID="testing/test-directory"
readonly SCRIPT_NAME="Test Directory Structure"

# Check if already completed
if has_script_succeeded "${SCRIPT_ID}"; then
    log_skip "${SCRIPT_NAME} (already completed)"
    exit 0
fi

log_step "${SCRIPT_NAME}"

: "${PROJECT_ROOT:?PROJECT_ROOT not set}"
cd "$INSTALL_DIR"

# Default test directory (configurable via omni.settings.sh)
SRC_TEST_DIR="${SRC_TEST_DIR:-__tests__}"

# Create test directory structure
log_info "Creating test directory structure..."

mkdir -p "${SRC_TEST_DIR}"
mkdir -p "${SRC_TEST_DIR}/unit"
mkdir -p "${SRC_TEST_DIR}/integration"
mkdir -p "${SRC_TEST_DIR}/fixtures"
mkdir -p "${SRC_TEST_DIR}/mocks"

log_ok "Created ${SRC_TEST_DIR}/ directory structure"

# Create README for test directory
if [[ ! -f "${SRC_TEST_DIR}/README.md" ]]; then
    cat > "${SRC_TEST_DIR}/README.md" <<'EOF'
# Tests

This directory contains all test files for the project.

## Structure

```
__tests__/
├── unit/           # Unit tests for individual functions/components
├── integration/    # Integration tests for combined functionality
├── fixtures/       # Test data and fixtures
├── mocks/          # Mock implementations and stubs
└── setup.ts        # Global test setup
```

## Running Tests

```bash
# Run all tests
pnpm test

# Run tests in watch mode
pnpm test:watch

# Run tests with coverage
pnpm test:coverage

# Run specific test file
pnpm test path/to/test.spec.ts
```

## Naming Conventions

- Unit tests: `*.test.ts` or `*.spec.ts`
- Integration tests: `*.integration.test.ts`
- Test fixtures: `*.fixture.ts`
EOF
    log_ok "Created ${SRC_TEST_DIR}/README.md"
fi

# Create example unit test
if [[ ! -f "${SRC_TEST_DIR}/unit/example.test.ts" ]]; then
    cat > "${SRC_TEST_DIR}/unit/example.test.ts" <<'EOF'
import { describe, it, expect } from 'vitest';

describe('Example Unit Tests', () => {
  it('should pass basic assertion', () => {
    expect(1 + 1).toBe(2);
  });

  it('should handle string operations', () => {
    const greeting = 'Hello, World!';
    expect(greeting).toContain('Hello');
  });
});
EOF
    log_ok "Created ${SRC_TEST_DIR}/unit/example.test.ts"
fi

# Create example integration test
if [[ ! -f "${SRC_TEST_DIR}/integration/example.integration.test.ts" ]]; then
    cat > "${SRC_TEST_DIR}/integration/example.integration.test.ts" <<'EOF'
import { describe, it, expect } from 'vitest';

describe('Example Integration Tests', () => {
  it('should demonstrate integration test structure', () => {
    // Integration tests typically test multiple components together
    const input = { value: 10 };
    const processed = { ...input, doubled: input.value * 2 };

    expect(processed.value).toBe(10);
    expect(processed.doubled).toBe(20);
  });
});
EOF
    log_ok "Created ${SRC_TEST_DIR}/integration/example.integration.test.ts"
fi

mark_script_success "${SCRIPT_ID}"
log_ok "${SCRIPT_NAME} complete"
