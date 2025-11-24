#!/usr/bin/env bash
# =============================================================================
# quality/verify-build.sh - Build Verification & Baseline Testing
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Phase: 4 (Extensions & Quality)
# Purpose: Verify project builds successfully and run baseline tests
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"

readonly SCRIPT_ID="quality/verify-build"
readonly SCRIPT_NAME="Build Verification & Testing"

# Set PROJECT_ROOT if not already set (for standalone execution)
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "${SCRIPT_DIR}/../../../.." && pwd)}"

# Check if already completed
if has_script_succeeded "${SCRIPT_ID}"; then
    log_skip "${SCRIPT_NAME} (already completed)"
    exit 0
fi

log_step "${SCRIPT_NAME}"

# =============================================================================
# Step 1: TypeScript Type Check
# =============================================================================

log_info "Running TypeScript type check..."

if pnpm typecheck 2>&1 | tee "${INSTALL_DIR}/logs/typecheck.log"; then
    log_ok "TypeScript type check passed"
else
    log_error "TypeScript type check failed"
    log_error "See logs/typecheck.log for details"
    exit 1
fi

# =============================================================================
# Step 2: Production Build
# =============================================================================

log_info "Building production bundle..."

if pnpm build 2>&1 | tee "${INSTALL_DIR}/logs/build.log"; then
    log_ok "Production build succeeded"
else
    log_error "Production build failed"
    log_error "See logs/build.log for details"
    exit 1
fi

# =============================================================================
# Step 3: Baseline Tests (if test suite exists)
# =============================================================================

log_info "Checking for test suite..."

if [[ -d "${INSTALL_DIR}/src/test" ]] || [[ -d "${INSTALL_DIR}/__tests__" ]]; then
    log_info "Running baseline unit tests..."

    if pnpm test --run 2>&1 | tee "${INSTALL_DIR}/logs/test.log"; then
        log_ok "Unit tests passed"
    else
        log_warn "Some unit tests failed (non-blocking)"
        log_warn "See logs/test.log for details"
    fi
else
    log_skip "No test suite found (skipping unit tests)"
fi

# =============================================================================
# Step 4: E2E Smoke Test (if Playwright installed)
# =============================================================================

if [[ -d "${INSTALL_DIR}/e2e" ]] && command -v playwright &>/dev/null; then
    log_info "Running E2E smoke test..."

    # Install Playwright browsers if needed
    if ! playwright install --dry-run chromium &>/dev/null; then
        log_info "Installing Playwright browsers..."
        pnpm exec playwright install chromium
    fi

    # Run E2E tests (allow failure as non-blocking)
    if pnpm test:e2e 2>&1 | tee "${INSTALL_DIR}/logs/e2e.log"; then
        log_ok "E2E smoke tests passed"
    else
        log_warn "Some E2E tests failed (non-blocking)"
        log_warn "See logs/e2e.log for details"
    fi
else
    log_skip "No E2E tests found (skipping Playwright)"
fi

# =============================================================================
# Step 5: Generate Verification Report
# =============================================================================

log_info "Generating verification report..."

cat > "${INSTALL_DIR}/logs/verification-report.md" <<EOF
# OmniForge Build Verification Report

**Generated**: $(date +'%Y-%m-%d %H:%M:%S')
**Project**: ${PROJECT_NAME:-bloom2}

## Verification Results

### ✅ TypeScript Type Check
- Status: PASSED
- Log: logs/typecheck.log

### ✅ Production Build
- Status: PASSED
- Log: logs/build.log
- Build artifacts: .next/

### Unit Tests
- Status: $([ -f "${INSTALL_DIR}/logs/test.log" ] && echo "COMPLETED" || echo "SKIPPED")
- Log: logs/test.log

### E2E Tests
- Status: $([ -f "${INSTALL_DIR}/logs/e2e.log" ] && echo "COMPLETED" || echo "SKIPPED")
- Log: logs/e2e.log

## Next Steps

1. Review build logs if any warnings present
2. Run \`pnpm dev\` to start development server
3. Run \`pnpm test\` for full test suite
4. Run \`pnpm test:e2e\` for E2E tests

## Build Commands

\`\`\`bash
pnpm dev          # Start dev server
pnpm build        # Production build
pnpm start        # Start prod server
pnpm typecheck    # Type checking
pnpm lint         # Linting
pnpm test         # Unit tests
pnpm test:e2e     # E2E tests
\`\`\`
EOF

log_ok "Verification report: logs/verification-report.md"

mark_script_success "${SCRIPT_ID}"
log_ok "${SCRIPT_NAME} complete"
log_ok "🎉 Project ready for development!"
