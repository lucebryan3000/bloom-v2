#!/usr/bin/env bash
#!meta
# id: quality/verify-build.sh
# name: verify build
# phase: 4
# phase_name: Extensions & Quality
# profile_tags:
#   - tech_stack
#   - quality
# uses_from_omni_config:
#   - ENABLE_CODE_QUALITY
# uses_from_omni_settings:
#   - PROJECT_ROOT
#   - INSTALL_DIR
# required_vars:
#   - PROJECT_ROOT
#   - INSTALL_DIR
# top_flags:
# dependencies:
#   packages: []
#   dev_packages: []
#!endmeta

# =============================================================================
# quality/verify-build.sh - Build Verification & Baseline Testing
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Phase: 4 (Extensions & Quality)
# Purpose: Verify project builds successfully and run baseline tests
# =============================================================================
#
# Dependencies:
#   - pnpm
#   - project dependencies installed
#

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"
if command -v parse_stack_flags >/dev/null 2>&1; then
    parse_stack_flags "$@"
fi

readonly SCRIPT_ID="quality/verify-build"
readonly SCRIPT_NAME="Build Verification & Testing"

if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_skip "DRY_RUN: skipping ${SCRIPT_NAME}"
    exit 0
fi

# Set PROJECT_ROOT if not already set (for standalone execution)
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "${SCRIPT_DIR}/../../../.." && pwd)}"

# Check if already completed
if has_script_succeeded "${SCRIPT_ID}"; then
    log_skip "${SCRIPT_NAME} (already completed)"
    exit 0
fi

log_step "${SCRIPT_NAME}"

# Ensure logs directory exists
mkdir -p "${INSTALL_DIR}/logs"

# =============================================================================
# Step 1: TypeScript Type Check
# =============================================================================

# =============================================================================
# Step 1: Clean stale build artifacts/ownership
# =============================================================================

log_info "Cleaning stale .next artifacts..."

# If a previous build created root-owned files (e.g., via container), clear them
if [[ -d "${INSTALL_DIR}/.next" ]]; then
    if rm -rf "${INSTALL_DIR}/.next"; then
        log_ok "Removed existing .next directory"
    else
        log_warn "Could not remove .next; attempting to reset permissions"
        if chmod -R u+rwX "${INSTALL_DIR}/.next" 2>/dev/null && rm -rf "${INSTALL_DIR}/.next"; then
            log_ok "Reset permissions and removed .next"
        else
            # Fallback: if docker compose is available, try removing inside the app container
            if command -v docker &>/dev/null && docker compose ps app &>/dev/null; then
                log_warn "Attempting to remove .next via docker compose exec app"
                if docker compose exec app sh -c "rm -rf /workspace/.next" >/dev/null 2>&1; then
                    log_ok "Removed .next via docker compose exec"
                else
                    log_error "Failed to clean .next; please remove it manually"
                    exit 1
                fi
            else
                log_error "Failed to clean .next; please remove it manually"
                exit 1
            fi
        fi
    fi
else
    log_skip ".next not present"
fi

# =============================================================================
# Step 2: Production Build (generates .next/types for typed routing)
# =============================================================================

log_info "Building production bundle..."

if NODE_ENV=production pnpm build 2>&1 | tee "${INSTALL_DIR}/logs/build.log"; then
    log_ok "Production build succeeded"
else
    log_error "Production build failed"
    log_error "See logs/build.log for details"
    exit 1
fi

# =============================================================================
# Step 3: TypeScript Type Check (after build so .next/types exist)
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
# Step 4: Baseline Tests (if test suite exists)
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
# Step 5: E2E Smoke Test (if Playwright installed)
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
# Step 6: Generate Verification Report
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
