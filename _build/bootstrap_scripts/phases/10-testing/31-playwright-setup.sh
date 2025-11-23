#!/usr/bin/env bash
# =============================================================================
# File: phases/10-testing/31-playwright-setup.sh
# Purpose: Install and configure Playwright for E2E tests
# Creates: playwright.config.ts, test scripts
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

readonly SCRIPT_ID="31"
readonly SCRIPT_NAME="playwright-setup"
readonly SCRIPT_DESCRIPTION="Install and configure Playwright E2E testing"

usage() { cat <<EOF
Usage: $(basename "$0") [OPTIONS]
$SCRIPT_DESCRIPTION
EOF
}

main() {
    parse_common_args "$@"
    init_logging "$SCRIPT_NAME"

    log_step "Installing Playwright"
    require_pnpm
    add_dependency "@playwright/test" "true"

    log_step "Creating playwright.config.ts"

    local playwright_config='import { defineConfig, devices } from "@playwright/test";

export default defineConfig({
  testDir: "./tests/e2e",
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: "html",
  use: {
    baseURL: process.env.PLAYWRIGHT_BASE_URL || "http://localhost:3000",
    trace: "on-first-retry",
  },
  projects: [
    {
      name: "chromium",
      use: { ...devices["Desktop Chrome"] },
    },
  ],
  webServer: {
    command: "pnpm dev",
    url: "http://localhost:3000",
    reuseExistingServer: !process.env.CI,
  },
});
'

    write_file "playwright.config.ts" "$playwright_config"

    log_step "Creating example E2E test"
    ensure_dir "tests/e2e"

    local example_test='import { test, expect } from "@playwright/test";

test.describe("Home Page", () => {
  test("should load successfully", async ({ page }) => {
    await page.goto("/");
    await expect(page).toHaveTitle(/Bloom/);
  });
});
'

    write_file "tests/e2e/home.spec.ts" "$example_test"

    log_step "Adding E2E test scripts"
    add_npm_script "test:e2e" "playwright test"
    add_npm_script "test:e2e:ui" "playwright test --ui"

    log_info "Run 'pnpm exec playwright install' to download browsers"
    log_success "Script $SCRIPT_ID completed"
}

main "$@"
