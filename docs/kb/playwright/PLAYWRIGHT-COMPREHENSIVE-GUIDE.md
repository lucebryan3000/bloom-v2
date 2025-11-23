---
id: playwright-playwright-comprehensive-guide
topic: playwright
file_role: guide
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: ['javascript', 'testing-basics']
related_topics: ['testing', 'e2e', 'automation']
embedding_keywords: [playwright, guide, tutorial, comprehensive]
last_reviewed: 2025-11-13
---

# Playwright Testing: Comprehensive Guide for Next.js Projects on Ubuntu

**Last Updated**: November 8, 2025
**Author**: Technical Team
**Status**: Production-Ready

## Table of Contents

1. [Quick Start](#quick-start)
2. [Installation & Setup on Ubuntu](#installation--setup-on-ubuntu)
3. [Core Concepts](#core-concepts)
4. [Writing Effective Tests](#writing-effective-tests)
5. [Configuration Deep Dive](#configuration-deep-dive)
6. [Running Tests Headless](#running-tests-headless)
7. [Performance & Parallelization](#performance--parallelization)
8. [Debugging & Troubleshooting](#debugging--troubleshooting)
9. [Best Practices](#best-practices)
10. [Common Pitfalls & Solutions](#common-pitfalls--solutions)
11. [Project-Specific Examples](#project-specific-examples)
12. [CI/CD Integration](#cicd-integration)

---

## Quick Start

### Install Playwright in Your Project

```bash
# Install Playwright and required browsers
npm install -D @playwright/test

# Install browser binaries and system dependencies
npx playwright install --with-deps

# Verify installation
npx playwright --version
```

### Generate First Test

```bash
# Codegen automatically records user interactions and generates test code
npx playwright codegen http://localhost:3001
```

### Run Tests

```bash
# Run all tests headless (default)
npm run test:e2e

# Run specific test file
npx playwright test e2e/specs/smoke/homepage.spec.ts

# Run with UI mode (watch mode with browser view)
npx playwright test --ui

# Run with headed mode (see browser window)
npx playwright test --headed
```

---

## Installation & Setup on Ubuntu

### System Prerequisites

Ubuntu requires system dependencies for browsers to run:

```bash
# Option 1: Automatic installation (recommended)
npx playwright install-deps

# Option 2: Manual installation of dependencies
sudo apt-get update
sudo apt-get install -y \
 libgtk-3-0 \
 libgbm1 \
 libxss1 \
 libasound2 \
 libxshmfence1 \
 fonts-dejavu \
 libgconf-2-4 \
 libpango-1.0-0 \
 libpango-gobject-0 \
 libxi6
```

### Browser Installation

```bash
# Install all browsers (Chromium, Firefox, WebKit)
npx playwright install

# Install specific browser
npx playwright install webkit

# Install only headless shell (lightweight, CI-friendly)
npx playwright install --only-shell

# List installed browsers
npx playwright install --list
```

### Custom Browser Cache Location

```bash
# Set custom cache directory
export PLAYWRIGHT_BROWSERS_PATH=/opt/playwright-browsers

# Verify
npx playwright install
```

### Environment Variables

```bash
#.env.test (for test-specific configuration)
PLAYWRIGHT_TEST_BASE_URL=http://localhost:3001
PLAYWRIGHT_HEADLESS=true
DEBUG=pw:api # Enable debug logging
PLAYWRIGHT_SKIP_BROWSER_GC=0 # Allow browser garbage collection
```

---

## Core Concepts

### Browser Launch Modes

#### Headless Mode (Default - for CI/Automation)

```typescript
import { test, expect } from '@playwright/test';

test('run in headless mode', async ({ browser }) => {
 // Default: headless=true (no visible browser window)
 const context = await browser.newContext;
 const page = await context.newPage;
 await page.goto('http://localhost:3001');

 expect(await page.title).toBeTruthy;
});
```

#### Headed Mode (Development/Debugging)

```bash
# See browser window during test execution
npx playwright test --headed

# Or configure in code
import { defineConfig } from '@playwright/test';

export default defineConfig({
 use: {
 headless: false, // Opens browser window
 },
});
```

### Page Objects & Fixtures

Page Objects encapsulate element selectors and interactions:

```typescript
// e2e/helpers/page-objects/HomePage.ts
import { Page, Locator } from '@playwright/test';

export class HomePage {
 readonly page: Page;
 readonly chatInput: Locator;
 readonly sendButton: Locator;
 readonly messageContainer: Locator;

 constructor(page: Page) {
 this.page = page;
 this.chatInput = page.getByPlaceholder('Type your message...');
 this.sendButton = page.getByRole('button', { name: 'Send' });
 this.messageContainer = page.locator('[data-testid="messages"]');
 }

 async goto {
 await this.page.goto('/');
 await this.page.waitForLoadState('networkidle');
 }

 async sendMessage(text: string) {
 await this.chatInput.fill(text);
 await this.sendButton.click;
 await this.messageContainer.waitFor({ state: 'visible' });
 }

 async getMessages {
 const messages = await this.messageContainer
.locator('div')
.allTextContents;
 return messages;
 }
}
```

### Test Fixtures

Fixtures provide test-scoped resources:

```typescript
// e2e/fixtures.ts
import { test as base } from '@playwright/test';
import { HomePage } from './helpers/page-objects/HomePage';

type TestFixtures = {
 homePage: HomePage;
};

export const test = base.extend<TestFixtures>({
 homePage: async ({ page }, use) => {
 const homePage = new HomePage(page);
 await homePage.goto;
 await use(homePage);
 // Cleanup after test
 },
});

export { expect } from '@playwright/test';
```

### Using Fixtures in Tests

```typescript
import { test, expect } from './fixtures';

test('send message', async ({ homePage }) => {
 await homePage.sendMessage('Hello!');
 const messages = await homePage.getMessages;
 expect(messages).toContain('Hello!');
});
```

---

## Writing Effective Tests

### Locator Strategy Hierarchy

Choose locators in this order (most to least resilient):

```typescript
// ✅ 1. Role-based (most resilient to UI changes)
page.getByRole('button', { name: 'Submit' })
page.getByRole('heading', { level: 1 })

// ✅ 2. Text content
page.getByText('Welcome')
page.getByText(/Sign [Ii]n/) // Regex support

// ✅ 3. Form labels
page.getByLabel('Email address')

// ✅ 4. Placeholders
page.getByPlaceholder('user@example.com')

// ✅ 5. Alt text (images)
page.getByAltText('Product screenshot')

// ✅ 6. Title attributes
page.getByTitle('Close dialog')

// ✅ 7. Test IDs (explicit testing contract)
page.getByTestId('submit-button')

// ❌ Avoid: Brittle CSS/XPath
page.locator('.container > div:nth-child(2) > button')
page.locator('xpath=//button[@id="submit"]')
```

### Web-First Assertions

Use assertions that automatically wait and retry:

```typescript
// ✅ Good: Assertions wait up to 5 seconds
await expect(page.locator('.spinner')).not.toBeVisible;
await expect(page).toHaveTitle('Dashboard');
await expect(page.getByRole('button')).toContainText('Logout');

// ❌ Bad: Immediate checks, fail if element isn't ready
const isVisible = await page.locator('.spinner').isVisible;
if (isVisible) { /* test fails */ }
```

### Filtering & Chaining Locators

```typescript
// Filter by text
const row = page.locator('table >> tbody >> tr').filter({ hasText: 'John' });

// Chain locators
const button = page
.getByRole('dialog', { name: 'Confirm' })
.getByRole('button', { name: 'Yes' });

// Use.and for simultaneous conditions
const input = page
.locator('input')
.and(page.locator('[required]'));

// Use.or for alternatives
const button = page
.getByRole('button', { name: 'Save' })
.or(page.getByRole('button', { name: 'Update' }));

// Count matching elements
const count = await page.locator('li').count;
```

### Example: Complete Test

```typescript
// e2e/specs/smoke/chat-complete.spec.ts
import { test, expect } from '@playwright/test';
import { WorkshopPage } from '../../helpers/page-objects/WorkshopPage';

test.describe('Chat Interface Complete Test', => {
 let workshopPage: WorkshopPage;

 test.beforeEach(async ({ page }) => {
 workshopPage = new WorkshopPage(page);
 await workshopPage.goto;

 // Verify page loaded
 await expect(page.locator('h1')).toContainText('this project');
 });

 test('should send message and receive response', async ({ page }) => {
 // Send message
 await workshopPage.sendMessage('What is ROI?');

 // Wait for response (with timeout)
 await page.waitForTimeout(2000);

 // Verify response appears
 const responses = await workshopPage.getMessages;
 expect(responses.length).toBeGreaterThan(1);

 // Verify message contains expected content
 const lastMessage = responses[responses.length - 1];
 expect(lastMessage.toLowerCase).toContain('roi');
 });

 test('should display session ID', async ({ page }) => {
 const sessionId = await workshopPage.getSessionId;

 // Session ID format validation
 expect(sessionId).toMatch(/^(WS-\d{8}-\d+|[a-z0-9]{20,})$/i);
 });

 test('should load within acceptable time', async ({ page }) => {
 const startTime = performance.now;
 await workshopPage.goto;
 const loadTime = performance.now - startTime;

 // Page should load within 10 seconds
 expect(loadTime).toBeLessThan(10000);
 });
});
```

---

## Configuration Deep Dive

### Basic Configuration (playwright.config.ts)

```typescript
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
 // Test discovery
 testDir: './e2e/specs',
 testMatch: '**/*.spec.ts',
 testIgnore: '**/node_modules/**',

 // Execution settings
 fullyParallel: true, // Run all tests in parallel
 workers: 1, // ⚠️ Set to 1 for database tests!
 retries: process.env.CI ? 2: 0, // Retry in CI
 timeout: 30 * 1000, // 30 seconds per test
 globalTimeout: 30 * 60 * 1000, // 30 minutes total

 // Reporters
 reporter: [
 ['html', { outputFolder: '_build/test/reports/playwright-html' }],
 ['json', { outputFile: '_build/test/reports/playwright-results.json' }],
 ['junit', { outputFile: '_build/test/reports/playwright-junit.xml' }],
 ['list'],
 ],

 // Server setup
 webServer: {
 command: 'npm run dev',
 url: 'http://localhost:3001',
 reuseExistingServer: !process.env.CI,
 timeout: 120 * 1000,
 },

 use: {
 baseURL: 'http://localhost:3001',
 headless: true,
 trace: 'on-first-retry', // Record traces only on retry
 screenshot: 'only-on-failure',
 video: 'retain-on-failure',
 actionTimeout: 10 * 1000,
 navigationTimeout: 30 * 1000,
 },

 projects: [
 {
 name: 'chromium',
 use: {...devices['Desktop Chrome'] },
 },
 {
 name: 'firefox',
 use: {...devices['Desktop Firefox'] },
 },
 ],
});
```

### Production-Grade Configuration (with Global Setup)

```typescript
// playwright.config.ts
export default defineConfig({
 globalSetup: './e2e/global-setup.ts',
 globalTeardown: './e2e/global-teardown.ts',

 //... rest of config
});

// e2e/global-setup.ts
import { chromium, FullConfig } from '@playwright/test';

async function globalSetup(config: FullConfig) {
 console.log('🔧 Running global setup...');

 // Initialize test database
 const { initTestDatabase, seedTestDatabase } = await import(
 './helpers/test-database'
 );
 await initTestDatabase;
 await seedTestDatabase;

 // Optional: Start test server in background
 // const server = await startTestServer;

 console.log('✅ Global setup complete');
}

export default globalSetup;

// e2e/global-teardown.ts
async function globalTeardown {
 console.log('🧹 Running global teardown...');

 const { cleanupTestDatabase } = await import(
 './helpers/test-database'
 );
 await cleanupTestDatabase(false);

 console.log('✅ Global teardown complete');
}

export default globalTeardown;
```

### Environment-Specific Configuration

```typescript
// playwright.config.ts
const isCI = !!process.env.CI;

export default defineConfig({
 // Development: Parallel, headed for debugging
 // CI: Sequential, headless, with retries

 workers: isCI ? 1: undefined,
 retries: isCI ? 2: 0,
 headless: isCI ? true: false,

 webServer: {
 reuseExistingServer: !isCI,
 },
});
```

---

## Running Tests Headless

### Default Headless Execution

```bash
# Tests run in headless mode by default
npm run test:e2e

# Verify headless mode is active
npx playwright test --headed=false
```

### Headless with Debug Output

```bash
# See detailed debug logs
DEBUG=pw:* npm run test:e2e

# Debug specific modules
DEBUG=pw:browser,pw:api npm run test:e2e

# Save logs to file
DEBUG=pw:api npm run test:e2e 2>&1 | tee test-debug.log
```

### Headless with Traces (for post-mortem debugging)

```typescript
// Configure in playwright.config.ts
export default defineConfig({
 use: {
 trace: 'on-first-retry', // Record traces when tests retry
 },
});

// Command line
npx playwright test --trace on

// View trace after test
npx playwright show-trace trace.zip
```

### Ubuntu-Specific Headless Settings

```bash
# Ensure display server isn't needed
export DISPLAY=

# Disable GPU rendering (faster headless)
export CHROMIUM_FLAGS='--disable-gpu --disable-software-rasterizer'

# Run tests
npm run test:e2e
```

### Troubleshooting Headless Issues

```bash
# Check if Xvfb is running (if needed)
ps aux | grep Xvfb

# Start Xvfb for headed tests
Xvfb:99 -screen 0 1024x768x24 &
export DISPLAY=:99

# Run tests with verbose browser logging
DEBUG=pw:browser npm run test:e2e
```

---

## Performance & Parallelization

### Worker Configuration

```typescript
// playwright.config.ts

// ✅ Development: Use parallel workers for speed
workers: undefined, // Default: CPU count

// ✅ CI: Use single worker for reliability
workers: process.env.CI ? 1: undefined,

// ✅ Custom: Set specific number
workers: 4,

// ✅ Percentage-based
workers: '50%', // Use 50% of CPU cores
```

### Database Isolation for Parallel Tests

**Problem**: SQLite only allows 1 writer at a time. Parallel tests fail with lock contention.

**Solution 1**: Use per-worker databases

```typescript
// e2e/helpers/test-database.ts
import { test as baseTest } from '@playwright/test';

export const test = baseTest.extend({
 dbPath: async ({ }, use, info) => {
 // Each worker gets its own database
 const path = `./prisma/test-${info.parallelIndex}.db`;
 await use(path);
 // Cleanup after
 },
});
```

**Solution 2**: Run database tests sequentially

```typescript
// e2e/specs/database.spec.ts
import { test } from '@playwright/test';

test.describe.serial('Database operations', => {
 test('test 1', async ({ page }) => {
 // Only one test runs at a time
 });

 test('test 2', async ({ page }) => {
 // Waits for test 1 to complete
 });
});
```

**Solution 3**: Mock API responses instead

```typescript
// e2e/specs/chat.spec.ts
import { test, expect } from '@playwright/test';

test('should send message', async ({ page }) => {
 // Intercept API calls instead of using real database
 await page.route('**/api/sessions/**', (route) => {
 route.abort('blockedbyelient');
 });

 // Use mocked responses
 await page.route('**/api/melissa/chat', (route) => {
 route.fulfill({
 status: 200,
 body: JSON.stringify({ response: 'Test response' }),
 });
 });

 // Test proceeds with mocked data
});
```

### Test Sharding (Distribute across machines)

```bash
# Run tests on machine 1 (1/3)
npx playwright test --shard=1/3

# Run tests on machine 2 (2/3)
npx playwright test --shard=2/3

# Run tests on machine 3 (3/3)
npx playwright test --shard=3/3
```

---

## Debugging & Troubleshooting

### Playwright Inspector

```bash
# Start interactive test runner
npx playwright test --debug

# In VS Code extension
# Click "Debug test" next to test name
```

### Using Traces for Post-Mortem Analysis

```typescript
// playwright.config.ts
export default defineConfig({
 use: {
 trace: 'on-first-retry', // Capture trace when test retries
 },
});

// View trace
npx playwright show-trace path/to/trace.zip
```

**What traces show:**
- Actions timeline (what Playwright did)
- Screenshots and DOM snapshots
- Console logs and network requests
- Exact locator used for each interaction
- Error messages and stack traces

### Screenshot & Video Capture

```typescript
export default defineConfig({
 use: {
 screenshot: 'only-on-failure', // Capture screenshots on failure
 video: 'retain-on-failure', // Record video on failure
 },
});

// View videos
// Output at: test-results/test-name/video.webm
```

### Common Debugging Commands

```bash
# Enable all debug logs
DEBUG=pw:* npm run test:e2e

# Debug specific module
DEBUG=pw:api npm run test:e2e

# See browser launch details
DEBUG=pw:browser npm run test:e2e

# See network activity
DEBUG=pw:protocol npm run test:e2e

# Save debug output to file
DEBUG=pw:api npm run test:e2e > debug.log 2>&1
```

### Handling Flaky Tests

```typescript
test.describe('Flaky tests', => {
 test.describe.configure({ retries: 2 });

 test('retry on failure', async ({ page }) => {
 // This test can retry up to 2 times
 });

 test.only.slow('slow test', async ({ page }) => {
 // Timeout = 3x normal (90 seconds instead of 30)
 });
});
```

---

## Best Practices

### 1. Test Isolation

Each test must be independent:

```typescript
test.beforeEach(async ({ page }) => {
 // Reset state before each test
 await page.goto('/');
 await page.evaluate( => {
 localStorage.clear;
 sessionStorage.clear;
 });
});

test('test 1', async ({ page }) => {
 // Can run in any order
});

test('test 2', async ({ page }) => {
 // Doesn't depend on test 1
});
```

### 2. Use Web-First Assertions

```typescript
// ✅ Good: Auto-waits up to 5 seconds
await expect(page.locator('.loader')).not.toBeVisible;

// ❌ Bad: Immediate check
const visible = await page.locator('.loader').isVisible;
if (visible) { /* fails */ }
```

### 3. Wait for Navigation and Network

```typescript
// Wait for navigation
await Promise.all([
 page.waitForNavigation,
 page.click('a[href="/about"]'),
]);

// Wait for network idle
await page.waitForLoadState('networkidle');

// Wait for specific response
const responsePromise = page.waitForResponse('**/api/sessions/**');
await page.click('button');
const response = await responsePromise;
```

### 4. Keep Tests Focused

```typescript
// ✅ Good: Single assertion
test('should display email on profile', async ({ page }) => {
 await expect(page.getByTestId('email')).toContainText('user@example.com');
});

// ❌ Bad: Multiple concerns
test('profile page', async ({ page }) => {
 await expect(page.getByTestId('email')).toContainText('user@example.com');
 await expect(page.getByTestId('name')).toContainText('John');
 await expect(page.getByTestId('avatar')).toBeVisible;
 // Too many assertions in one test
});
```

### 5. Mock External Dependencies

```typescript
test('should handle API failure gracefully', async ({ page }) => {
 // Mock API response
 await page.route('**/api/external/**', (route) => {
 route.abort('failed');
 });

 await page.goto('/');

 // Verify error handling
 await expect(page.locator('[data-testid="error-message"]'))
.toContainText('Failed to load data');
});
```

### 6. Use Descriptive Test Names

```typescript
// ✅ Good: Descriptive
test('should display validation error when email is invalid', async ({ page }) => {
 //...
});

// ❌ Bad: Vague
test('email validation', async ({ page }) => {
 //...
});
```

---

## Common Pitfalls & Solutions

### Pitfall 1: SQLite + Parallel Tests

**Problem**: All test workers hammer SQLite simultaneously, causing lock contention and timeouts.

```typescript
// ❌ Bad configuration
export default defineConfig({
 workers: undefined, // Unlimited parallelism
 fullyParallel: true,
});
```

**Solution**:

```typescript
// ✅ Good configuration
export default defineConfig({
 workers: 1, // Single worker for SQLite tests
 fullyParallel: false, // Run tests sequentially

 // OR use per-worker databases:
 webServer: {
 env: {
 TEST_DB_PATH: process.env.PLAYWRIGHT_WORKER_INDEX
 ? `test-${process.env.PLAYWRIGHT_WORKER_INDEX}.db`
: 'test.db',
 },
 },
});
```

### Pitfall 2: Memory Leaks in Long Test Runs

**Problem**: Dev server memory grows unbounded during test execution.

**Solution**: Add resource limits

```bash
# Set memory limit for Node process
node --max-old-space-size=4096 /path/to/next-dev

# OR in package.json
"dev": "NODE_OPTIONS='--max-old-space-size=4096' next dev"
```

### Pitfall 3: Brittle Locators

**Problem**: Tests break when UI implementation changes.

```typescript
// ❌ Brittle: Depends on DOM structure
page.locator('div.container > div:nth-child(2) > button')

// ✅ Resilient: Uses semantic selectors
page.getByRole('button', { name: 'Submit' })
```

### Pitfall 4: Race Conditions in Async Code

**Problem**: Test continues before async operation completes.

```typescript
// ❌ Bad: Doesn't wait for navigation
await page.click('a');
await page.goto('/'); // May not have navigated yet

// ✅ Good: Wait for navigation
await Promise.all([
 page.waitForNavigation,
 page.click('a'),
]);
```

### Pitfall 5: Hard-Coded Waits

**Problem**: Tests are slow and flaky.

```typescript
// ❌ Bad: Always waits 5 seconds
await page.waitForTimeout(5000);

// ✅ Good: Waits for actual condition
await expect(page.locator('.loaded')).toBeVisible;
```

### Pitfall 6: Test Data Pollution

**Problem**: One test's data affects another.

```typescript
// ❌ Bad: Shared test data
let userId = '123';

test('test 1', async ({ page }) => {
 userId = '456'; // Modifies shared state
});

test('test 2', async ({ page }) => {
 // userId might be '456' instead of '123'
});

// ✅ Good: Isolated test data
test('test 1', async ({ page }) => {
 const userId = '456'; // Local variable
});

test('test 2', async ({ page }) => {
 const userId = '123'; // Independent
});
```

---

## Project-Specific Examples

### Example 1: Testing this project Workshop Flow

```typescript
// e2e/specs/smoke/workshop-flow.spec.ts
import { test, expect } from '@playwright/test';
import { WorkshopPage } from '../../helpers/page-objects/WorkshopPage';

test.describe('this project Workshop Flow', => {
 test('should complete 15-minute workshop', async ({ page }) => {
 const demo = new WorkshopPage(page);
 await demo.goto;

 // Verify workshop initialized
 const sessionId = await demo.getSessionId;
 expect(sessionId).toBeTruthy;

 // Send first question
 await demo.sendMessage('What is our main business metric?');
 await page.waitForTimeout(2000);

 // Verify response contains ROI-related content
 const messages = await demo.getMessages;
 expect(messages.length).toBeGreaterThan(0);

 // Track time (15-minute target)
 const startTime = Date.now;

 // Simulate workshop interaction
 await demo.sendMessage('Revenue: $1M annually');
 await demo.sendMessage('Cost of initiative: $200K');

 const elapsedTime = (Date.now - startTime) / 1000 / 60;
 console.log(`Workshop duration: ${elapsedTime.toFixed(2)} minutes`);
 });
});
```

### Example 2: Testing Chat Interface with Response Verification

```typescript
// e2e/specs/integration/chat-melissa.spec.ts
import { test, expect } from '@playwright/test';
import { HomePage } from '../../helpers/page-objects/HomePage';

test.describe('Melissa AI Chat', => {
 test('should parse ROI metrics from conversation', async ({ page, context }) => {
 const home = new HomePage(page);
 await home.goto;

 // Mock Melissa API to return structured response
 await page.route('**/api/melissa/chat', (route) => {
 route.fulfill({
 status: 200,
 contentType: 'application/json',
 body: JSON.stringify({
 response: 'Based on your metrics, your NPV is $800K with 18% IRR.',
 metrics: {
 npv: 800000,
 irr: 0.18,
 paybackPeriod: 2.5,
 },
 }),
 });
 });

 // Send message
 await home.sendMessage('Calculate ROI');

 // Wait for response
 const responseElement = page.locator('[data-testid="melissa-response"]');
 await expect(responseElement).toContainText('NPV');
 await expect(responseElement).toContainText('IRR');
 });
});
```

### Example 3: Testing Export Functionality

```typescript
// e2e/specs/smoke/export.spec.ts
import { test, expect } from '@playwright/test';
import fs from 'fs';
import path from 'path';

test.describe('Export Functionality', => {
 test('should export report as PDF', async ({ page, context }) => {
 await page.goto('/workshop/123/report');

 // Wait for PDF download
 const downloadPromise = context.waitForEvent('download');
 await page.click('button:has-text("Export PDF")');
 const download = await downloadPromise;

 // Verify download
 const fileName = await download.suggestedFilename;
 expect(fileName).toContain('.pdf');

 // Save and verify file
 const filePath = path.join('./downloads', fileName);
 await download.saveAs(filePath);

 const stats = fs.statSync(filePath);
 expect(stats.size).toBeGreaterThan(0);
 });

 test('should export data as JSON', async ({ page }) => {
 await page.goto('/workshop/123/report');

 // Mock JSON endpoint
 const responsePromise = page.waitForResponse('**/api/export/json');
 await page.click('button:has-text("Export JSON")');
 const response = await responsePromise;

 expect(response.status).toBe(200);
 const data = await response.json;

 expect(data).toHaveProperty('npv');
 expect(data).toHaveProperty('irr');
 expect(data).toHaveProperty('recommendations');
 });
});
```

---

## CI/CD Integration

### GitHub Actions Example

```yaml
#.github/workflows/playwright.yml
name: Playwright Tests

on:
 push:
 branches: [main, develop]
 pull_request:
 branches: [main, develop]

jobs:
 test:
 runs-on: ubuntu-latest
 timeout-minutes: 60

 services:
 postgres:
 image: postgres:14
 env:
 POSTGRES_PASSWORD: postgres
 options: >-
 --health-cmd pg_isready
 --health-interval 10s
 --health-timeout 5s
 --health-retries 5

 steps:
 - uses: actions/checkout@v4

 - name: Setup Node.js
 uses: actions/setup-node@v4
 with:
 node-version: '22'
 cache: 'npm'

 - name: Install dependencies
 run: npm ci

 - name: Install Playwright browsers
 run: npx playwright install --with-deps

 - name: Run Playwright tests
 run: npm run test:e2e
 env:
 CI: true
 DATABASE_URL: ${{ secrets.DATABASE_URL }}

 - name: Upload test results
 if: always
 uses: actions/upload-artifact@v4
 with:
 name: playwright-report
 path: _build/test/reports/playwright-html/

 - name: Upload test videos
 if: failure
 uses: actions/upload-artifact@v4
 with:
 name: test-videos
 path: _build/test/artifacts/test-results/
```

### Docker Example

```dockerfile
# Dockerfile.test
FROM node:22-bookworm

WORKDIR /app

# Install Playwright system dependencies
RUN apt-get update && apt-get install -y \
 libgtk-3-0 \
 libgbm1 \
 libxss1 \
 libasound2 \
 && rm -rf /var/lib/apt/lists/*

COPY package*.json./
RUN npm ci

# Install Playwright browsers
RUN npx playwright install --with-deps

COPY..

# Run tests
CMD ["npm", "run", "test:e2e"]
```

```bash
# Run tests in Docker
docker build -f Dockerfile.test -t app-tests.
docker run --rm app-tests

# With volume for reports
docker run --rm \
 -v $(pwd)/_build:/app/_build \
 app-tests
```

---

## Reference Documentation

- **Official Docs**: https://playwright.dev/docs/intro
- **API Reference**: https://playwright.dev/docs/api/class-playwright
- **Best Practices**: https://playwright.dev/docs/best-practices
- **Debugging**: https://playwright.dev/docs/debug
- **CI/CD Guide**: https://playwright.dev/docs/ci

---

## Quick Command Reference

```bash
# Test execution
npm run test:e2e # Run all tests
npx playwright test --headed # Run with visible browser
npx playwright test --debug # Interactive debugging
npx playwright test --ui # Watch mode with UI
npx playwright test --trace on # Record execution traces

# Installation & setup
npx playwright install # Install browsers
npx playwright install-deps # Install system dependencies
npx playwright codegen URL # Record test generation

# Debugging & inspection
npx playwright show-trace trace.zip # View test trace
DEBUG=pw:* npm run test:e2e # Enable all debug logs
npx playwright test --screenshot on # Always capture screenshots

# Configuration
npx playwright test --workers=1 # Run sequentially
npx playwright test --project=firefox # Run specific browser
npx playwright test --grep @smoke # Run tests tagged @smoke
npx playwright test --shard=1/3 # Run 1/3 of tests
```

---

## Troubleshooting Checklist

- [ ] System dependencies installed: `npx playwright install-deps`
- [ ] Browsers installed: `npx playwright install --with-deps`
- [ ] Dev server running: `npm run dev` (if using webServer config)
- [ ] Correct baseURL in config: `http://localhost:3001`
- [ ] Workers set to 1 for database tests
- [ ] No hard-coded `await page.waitForTimeout`
- [ ] Using web-first assertions: `await expect`
- [ ] Tests are isolated: No shared state
- [ ] Using semantic locators: `getByRole`, `getByText`
- [ ] Memory limits set: `--max-old-space-size=4096`

---

**Last Updated**: November 8, 2025
**Maintained by**: Technical Team
**Version**: 1.0.0
