#!/usr/bin/env bash
# =============================================================================
# tech_stack/features/testing.sh - Vitest + Playwright Testing
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Phase: Features
# Profile: standard+
#
# Installs (dev):
#   - vitest (unit testing)
#   - @testing-library/react (component testing)
#   - playwright (e2e testing)
#   - @playwright/test (test runner)
#
# Creates:
#   - vitest.config.ts
#   - playwright.config.ts
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"
source "${SCRIPT_DIR}/../_lib/pkg-install.sh"

readonly SCRIPT_ID="features/testing"
readonly SCRIPT_NAME="Vitest + Playwright Testing"

# =============================================================================
# PREFLIGHT
# =============================================================================

log_step "${SCRIPT_NAME} - Preflight"

# Check if already completed
if has_script_succeeded "${SCRIPT_ID}"; then
    log_skip "${SCRIPT_NAME} (already completed)"
    exit 0
fi

# Verify PROJECT_ROOT is set
if [[ -z "${PROJECT_ROOT:-}" ]]; then
    log_error "PROJECT_ROOT not set"
    exit 1
fi

# Verify project directory exists
if [[ ! -d "$PROJECT_ROOT" ]]; then
    log_error "Project directory does not exist: $PROJECT_ROOT"
    exit 1
fi

cd "$PROJECT_ROOT"

# =============================================================================
# DEPENDENCY INSTALLATION
# =============================================================================

log_step "Installing testing dependencies"

DEV_DEPS=("${PKG_VITEST}" "${PKG_TESTING_LIBRARY_REACT}" "${PKG_PLAYWRIGHT}")

# Show cache status
pkg_preflight_check "${DEV_DEPS[@]}"

# Install dev dependencies
log_info "Installing test framework dependencies..."
pkg_install_dev "${DEV_DEPS[@]}" || {
    log_error "Failed to install testing dependencies"
    exit 1
}

# Verify installation
log_info "Verifying installation..."
pkg_verify_all "${PKG_VITEST}" "${PKG_TESTING_LIBRARY_REACT}" "${PKG_PLAYWRIGHT}" || {
    log_error "Package verification failed"
    exit 1
}

log_ok "Testing dependencies installed"

# =============================================================================
# VITEST CONFIGURATION
# =============================================================================

log_step "Creating Vitest configuration"

if [[ ! -f "vitest.config.ts" ]]; then
    cat > vitest.config.ts <<'EOF'
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  test: {
    // Environment
    environment: 'jsdom',

    // Globals (describe, it, expect without imports)
    globals: true,

    // Setup files
    setupFiles: ['./${SRC_TEST_DIR}/setup.ts'],

    // Include patterns
    include: ['src/**/*.{test,spec}.{ts,tsx}'],

    // Exclude patterns
    exclude: ['node_modules', '${E2E_DIR}/**/*'],

    // Coverage
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      exclude: [
        'node_modules/',
        '${SRC_TEST_DIR}/',
        '**/*.d.ts',
        '**/*.config.{ts,js}',
      ],
    },
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
});
EOF
    log_ok "Created vitest.config.ts"
else
    log_skip "vitest.config.ts already exists"
fi

# Create test setup file
mkdir -p "${SRC_TEST_DIR}"

if [[ ! -f "${SRC_TEST_DIR}/setup.ts" ]]; then
    cat > "${SRC_TEST_DIR}/setup.ts" <<'EOF'
import '@testing-library/jest-dom/vitest';

// Global test setup
beforeAll(() => {
  // Setup code that runs before all tests
});

afterAll(() => {
  // Cleanup code that runs after all tests
});

// Mock window.matchMedia for tests that use media queries
Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: (query: string) => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: () => {},
    removeListener: () => {},
    addEventListener: () => {},
    removeEventListener: () => {},
    dispatchEvent: () => false,
  }),
});
EOF
    log_ok "Created ${SRC_TEST_DIR}/setup.ts"
fi

# =============================================================================
# PLAYWRIGHT CONFIGURATION
# =============================================================================

log_step "Creating Playwright configuration"

if [[ ! -f "playwright.config.ts" ]]; then
    cat > playwright.config.ts <<'EOF'
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  // Test directory
  testDir: './${E2E_DIR}',

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
    baseURL: '${DEV_SERVER_URL}',

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
    // Mobile viewports
    {
      name: 'mobile-chrome',
      use: { ...devices['Pixel 5'] },
    },
    {
      name: 'mobile-safari',
      use: { ...devices['iPhone 12'] },
    },
  ],

  // Development server
  webServer: {
    command: 'pnpm dev',
    url: '${DEV_SERVER_URL}',
    reuseExistingServer: !process.env.CI,
    timeout: 120 * 1000,
  },
});
EOF
    log_ok "Created playwright.config.ts"
else
    log_skip "playwright.config.ts already exists"
fi

# Create e2e directory with example test
mkdir -p "${E2E_DIR}"

if [[ ! -f "${E2E_DIR}/home.spec.ts" ]]; then
    cat > "${E2E_DIR}/home.spec.ts" <<'EOF'
import { test, expect } from '@playwright/test';

test.describe('Home Page', () => {
  test('should display welcome message', async ({ page }) => {
    await page.goto('/');
    await expect(page.locator('h1')).toBeVisible();
  });

  test('should have correct title', async ({ page }) => {
    await page.goto('/');
    await expect(page).toHaveTitle(/My App/);
  });
});
EOF
    log_ok "Created ${E2E_DIR}/home.spec.ts"
fi

# =============================================================================
# NPM SCRIPTS
# =============================================================================

log_step "Adding test scripts to package.json"

# Add test scripts if pkg_add_script is available
if command -v pkg_add_script &>/dev/null || type pkg_add_script &>/dev/null; then
    pkg_add_script "test" "vitest"
    pkg_add_script "test:ui" "vitest --ui"
    pkg_add_script "test:coverage" "vitest --coverage"
    pkg_add_script "test:e2e" "playwright test"
    pkg_add_script "test:e2e:ui" "playwright test --ui"
    log_ok "Added test scripts"
else
    log_warn "pkg_add_script not available, skipping script additions"
fi

# =============================================================================
# MARK SUCCESS
# =============================================================================

mark_script_success "${SCRIPT_ID}"
log_ok "${SCRIPT_NAME} complete"
