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
