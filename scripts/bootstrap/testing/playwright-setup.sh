#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SH="${SCRIPT_DIR%/*}/lib/common.sh"
[[ -f "${COMMON_SH}" ]] || { echo "ERROR: common.sh not found" >&2; exit 1; }
. "${COMMON_SH}"

SCRIPT_KEY="testing/playwright-setup.sh"

main() {
    parse_common_args "$@"
    [[ "${SHOW_HELP}" == "true" ]] && { echo "Setup Playwright"; exit 0; }

    if [[ "${ENABLE_TEST_INFRA:-true}" != "true" ]]; then
        log_info "SKIP: Test infrastructure disabled via ENABLE_TEST_INFRA"
        mark_script_success "${SCRIPT_KEY}"
        return 0
    fi

    log_info "=== Setting up Playwright ==="
    cd "${PROJECT_ROOT:-.}"

    add_dependency "@playwright/test" "true"

    local playwright_config='import { defineConfig, devices } from "@playwright/test";

export default defineConfig({
  testDir: "./e2e",
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: [
    ["html", { open: "never" }],
    ["list"],
  ],
  use: {
    baseURL: process.env.PLAYWRIGHT_TEST_BASE_URL || "http://localhost:3000",
    trace: "on-first-retry",
    screenshot: "only-on-failure",
  },
  projects: [
    {
      name: "chromium",
      use: { ...devices["Desktop Chrome"] },
    },
    {
      name: "firefox",
      use: { ...devices["Desktop Firefox"] },
    },
    {
      name: "webkit",
      use: { ...devices["Desktop Safari"] },
    },
    {
      name: "mobile-chrome",
      use: { ...devices["Pixel 5"] },
    },
  ],
  webServer: {
    command: "pnpm dev",
    url: "http://localhost:3000",
    reuseExistingServer: !process.env.CI,
    timeout: 120000,
  },
});
'
    write_file_if_missing "playwright.config.ts" "${playwright_config}"

    ensure_dir "e2e"

    local example_test='import { test, expect } from "@playwright/test";

test.describe("Home Page", () => {
  test("should load successfully", async ({ page }) => {
    await page.goto("/");
    await expect(page).toHaveTitle(/./);
  });

  test("should be accessible", async ({ page }) => {
    await page.goto("/");
    // Basic accessibility check - ensure main content exists
    await expect(page.locator("body")).toBeVisible();
  });
});

test.describe("Navigation", () => {
  test("should navigate between pages", async ({ page }) => {
    await page.goto("/");
    // Add navigation tests as routes are created
  });
});
'
    write_file_if_missing "e2e/home.spec.ts" "${example_test}"

    local e2e_fixtures='import { test as base } from "@playwright/test";

interface Fixtures {
  authenticatedPage: void;
}

export const test = base.extend<Fixtures>({
  authenticatedPage: async ({ page }, use) => {
    // Setup authentication if needed
    // await page.goto("/login");
    // await page.fill("input[name=email]", "test@example.com");
    // await page.click("button[type=submit]");
    await use();
  },
});

export { expect } from "@playwright/test";
'
    write_file_if_missing "e2e/fixtures.ts" "${e2e_fixtures}"

    add_npm_script "test:e2e" "playwright test"
    add_npm_script "test:e2e:ui" "playwright test --ui"
    add_npm_script "test:e2e:debug" "playwright test --debug"

    log_info "Note: Run 'pnpm exec playwright install' to install browsers"

    mark_script_success "${SCRIPT_KEY}"
    log_success "Playwright setup complete"
}

main "$@"
