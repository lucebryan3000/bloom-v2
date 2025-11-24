#!/usr/bin/env bash
# =============================================================================
# tech_stack/testing/playwright-setup.sh - Playwright E2E Setup
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Phase: 4 (Extensions & Quality)
# Purpose: Creates Playwright e2e test configuration and directory structure
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"

readonly SCRIPT_ID="testing/playwright-setup"
readonly SCRIPT_NAME="Playwright E2E Setup"

# Check if already completed
if has_script_succeeded "${SCRIPT_ID}"; then
    log_skip "${SCRIPT_NAME} (already completed)"
    exit 0
fi

log_step "${SCRIPT_NAME}"

: "${PROJECT_ROOT:?PROJECT_ROOT not set}"
cd "$PROJECT_ROOT"

# Default e2e directory
E2E_DIR="${E2E_DIR:-e2e}"

# Create e2e directory structure
log_info "Creating Playwright e2e directory structure..."
mkdir -p "${E2E_DIR}"
mkdir -p "${E2E_DIR}/fixtures"
mkdir -p "${E2E_DIR}/pages"

# Create playwright.config.ts if it doesn't exist
if [[ ! -f "playwright.config.ts" ]]; then
    log_info "Creating playwright.config.ts..."
    cat > playwright.config.ts <<'EOF'
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  // Test directory
  testDir: './e2e',

  // Run tests in parallel
  fullyParallel: true,

  // Fail the build on test.only
  forbidOnly: !!process.env.CI,

  // Retry failed tests
  retries: process.env.CI ? 2 : 0,

  // Workers
  workers: process.env.CI ? 1 : undefined,

  // Reporter
  reporter: process.env.CI ? 'github' : 'html',

  // Shared settings
  use: {
    // Base URL
    baseURL: 'http://localhost:3000',

    // Trace on first retry
    trace: 'on-first-retry',

    // Screenshot on failure
    screenshot: 'only-on-failure',
  },

  // Projects for different browsers
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
    },
  ],

  // Development server
  webServer: {
    command: 'pnpm dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
    timeout: 120 * 1000,
  },
});
EOF
    log_ok "Created playwright.config.ts"
else
    log_skip "playwright.config.ts already exists"
fi

# Create example e2e test if it doesn't exist
if [[ ! -f "${E2E_DIR}/example.spec.ts" ]]; then
    log_info "Creating example e2e test..."
    cat > "${E2E_DIR}/example.spec.ts" <<'EOF'
import { test, expect } from '@playwright/test';

test.describe('Example E2E Tests', () => {
  test('homepage loads successfully', async ({ page }) => {
    await page.goto('/');
    await expect(page).toHaveTitle(/.*/);
  });

  test('page has main content', async ({ page }) => {
    await page.goto('/');
    await expect(page.locator('main')).toBeVisible();
  });
});
EOF
    log_ok "Created ${E2E_DIR}/example.spec.ts"
fi

# Create .gitignore for playwright artifacts
if [[ ! -f "${E2E_DIR}/.gitignore" ]]; then
    cat > "${E2E_DIR}/.gitignore" <<'EOF'
# Playwright
test-results/
playwright-report/
playwright/.cache/
EOF
    log_ok "Created ${E2E_DIR}/.gitignore"
fi

mark_script_success "${SCRIPT_ID}"
log_ok "${SCRIPT_NAME} complete"
