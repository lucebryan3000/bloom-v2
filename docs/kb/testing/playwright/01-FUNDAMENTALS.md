---
id: playwright-01-fundamentals
topic: playwright
file_role: fundamentals
profile: full
difficulty_level: beginner
kb_version: 3.1
prerequisites: [javascript-basics, typescript-basics, web-basics]
related_topics: [testing, e2e-testing, browser-automation]
embedding_keywords: [playwright, fundamentals, e2e-testing, browser-automation, testing-basics, test-isolation, fixtures, auto-waiting, locators, selectors, browser-contexts]
last_reviewed: 2025-11-14
---

# Playwright Fundamentals

<!-- Query Pattern: playwright fundamentals, e2e testing basics, playwright architecture -->
<!-- Query Pattern: when to use playwright vs jest, playwright auto-waiting -->
<!-- Query Pattern: playwright fixtures, test isolation, browser contexts -->

## 1. Purpose

**What This File Covers:**

This file establishes the foundational mental models and core concepts for Playwright end-to-end (E2E) testing. It answers:

- **What is E2E testing** and why does it matter?
- **Why Playwright** over alternatives (Selenium, Cypress, Puppeteer)?
- **How Playwright works** - architecture, browser contexts, pages, and fixtures
- **The auto-waiting philosophy** - why Playwright is more reliable
- **Test isolation and parallelism** - how to run tests safely and fast
- **When to use Playwright vs Jest** - the right tool for the right job
- **Bloom's E2E testing approach** - our specific conventions and patterns

**Who Should Read This:**

- Developers new to Playwright or E2E testing
- Anyone writing tests for Bloom's workshop UI, session management, or Melissa chat interface
- Engineers migrating from Selenium, Cypress, or other E2E frameworks
- Team members needing to understand Bloom's testing strategy

**Prerequisites:**

- Basic JavaScript/TypeScript knowledge
- Familiarity with web concepts (DOM, HTTP, async/await)
- Understanding of Next.js 16 (helpful but not required)

**Related Documents:**

- `02-SELECTORS-LOCATORS.md` - Deep dive into finding elements
- `03-API-TESTING.md` - Testing APIs with Playwright
- `04-VISUAL-REGRESSION.md` - Screenshot comparison testing
- `QUICK-REFERENCE.md` - Syntax cheat sheet
- `/docs/ARCHITECTURE.md` - Bloom's overall testing strategy

---

## 2. Mental Model / Problem Statement

<!-- Query Pattern: e2e testing philosophy, testing pyramid, playwright vs unit tests -->
<!-- Query Pattern: playwright architecture, browser contexts, pages -->

### 2.1 What is End-to-End Testing?

**Definition:**

End-to-end (E2E) testing validates the entire application flow from the user's perspective. Unlike unit tests (which test individual functions) or integration tests (which test module interactions), E2E tests simulate real user behavior in a real browser.

**Example User Flow:**

```
User Journey: Complete a Bloom ROI Discovery Workshop

1. Navigate to /workshop
2. Click "Start New Session"
3. Enter organization name
4. Chat with Melissa (AI agent)
5. Answer ROI questions
6. Review confidence scores
7. Export PDF report
```

An E2E test would automate this entire journey, asserting that each step works correctly.

### 2.2 The Testing Pyramid

```
         /\
        /  \  E2E Tests (Slow, High Value)
       /────\
      /      \  Integration Tests (Medium Speed, Medium Value)
     /────────\
    /          \  Unit Tests (Fast, Low-to-Medium Value)
   /────────────\
```

**Best Practices:**

- **70% Unit Tests**: Fast, focused, cheap to maintain
- **20% Integration Tests**: Test module boundaries, API contracts
- **10% E2E Tests**: Critical user paths only

**Bloom's Critical E2E Paths:**

1. **Complete workshop session** (new user)
2. **Resume existing session** (returning user)
3. **Export ROI report** (PDF, Excel, JSON)
4. **Settings management** (branding, sessions, monitoring)
5. **Authentication flow** (login, logout, session persistence)

### 2.3 Why Playwright?

**Comparison:**

| Feature | Playwright | Cypress | Selenium | Puppeteer |
|---------|-----------|---------|----------|-----------|
| **Cross-browser** | ✅ Chromium, Firefox, WebKit | ⚠️ Chromium, Firefox (limited WebKit) | ✅ All browsers | ❌ Chromium only |
| **Auto-waiting** | ✅ Built-in | ✅ Built-in | ❌ Manual waits | ⚠️ Limited |
| **Network mocking** | ✅ Full HAR support | ✅ Good | ❌ Limited | ✅ Good |
| **Parallel execution** | ✅ Native support | ⚠️ Paid feature | ✅ Manual setup | ⚠️ Manual setup |
| **TypeScript support** | ✅ First-class | ✅ Good | ⚠️ Limited | ✅ Good |
| **Trace viewer** | ✅ Best-in-class | ❌ No | ❌ No | ❌ No |
| **Speed** | ⚡ Fast | ⚡ Fast | 🐢 Slow | ⚡ Fast |
| **Maturity** | 2020 (Microsoft) | 2015 | 2004 | 2017 (Google) |

**Why Bloom Chose Playwright:**

1. **Auto-waiting reduces flakiness** - No `cy.wait(5000)` or `await page.waitFor()`
2. **True browser isolation** - Each test gets a fresh browser context (cookies, storage, cache)
3. **Powerful debugging** - Trace viewer shows screenshots, network logs, DOM snapshots
4. **Cross-browser testing** - Validate on Safari (WebKit), Firefox, Chrome
5. **API testing built-in** - Use same framework for UI and API tests
6. **TypeScript-first** - Excellent type safety and autocomplete

### 2.4 Playwright Architecture

**Three Key Concepts:**

```typescript
// 1. Browser - The actual browser instance
const browser = await chromium.launch();

// 2. Browser Context - Isolated session (cookies, storage, cache)
//    Think: "Incognito window"
const context = await browser.newContext();

// 3. Page - A single tab within the context
const page = await context.newPage();
```

**Why This Matters:**

- **Browser**: Heavy to create (~500ms). Share across all tests in a worker.
- **Context**: Lightweight (~50ms). Create one per test for isolation.
- **Page**: Very fast (~10ms). Create as needed within a test.

**Bloom's Default Setup:**

```typescript
// playwright.config.ts
export default defineConfig({
  use: {
    // Every test gets a fresh browser context
    // (Playwright does this automatically with fixtures)
    baseURL: 'http://localhost:3001',
    trace: 'on-first-retry', // Capture traces on failure
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
  // Parallel execution across 4 workers
  workers: process.env.CI ? 2 : 4,
});
```

### 2.5 Auto-Waiting Philosophy

**The Problem with Manual Waits:**

```typescript
// ❌ BAD: Flaky, slow, unreliable
await page.click('#submit-button');
await page.waitForTimeout(5000); // What if it loads in 6 seconds?
expect(await page.textContent('.result')).toBe('Success');
```

**Playwright's Solution:**

```typescript
// ✅ GOOD: Auto-waits until element is ready
await page.click('#submit-button'); // Waits for: visible, enabled, stable
await expect(page.locator('.result')).toHaveText('Success'); // Retries for 5s
```

**What Auto-Waiting Checks:**

1. **Element exists** in DOM
2. **Element is visible** (not `display: none` or `visibility: hidden`)
3. **Element is enabled** (not `disabled` attribute)
4. **Element is stable** (not animating or moving)
5. **Element receives events** (not covered by another element)

**Timeout Defaults:**

- **Actions** (click, fill, select): 30 seconds
- **Assertions** (expect): 5 seconds
- **Navigation** (goto): 30 seconds

**Customizing Timeouts:**

```typescript
// Per-action timeout
await page.click('#slow-button', { timeout: 60000 }); // 60s

// Per-assertion timeout
await expect(page.locator('.slow-element')).toHaveText('Done', { timeout: 10000 });

// Global timeout (playwright.config.ts)
export default defineConfig({
  timeout: 60000, // 60s per test
  expect: {
    timeout: 10000, // 10s per assertion
  },
});
```

### 2.6 Test Isolation

**The Golden Rule:**

> Every test must be independent. Test order must not matter.

**Why Isolation Matters:**

```typescript
// ❌ BAD: Test 2 depends on Test 1
test('create session', async ({ page }) => {
  await page.goto('/workshop');
  await page.fill('#org-name', 'Acme Corp');
  await page.click('#start-session');
  // Session ID stored in global variable 😱
});

test('resume session', async ({ page }) => {
  // Assumes session from previous test exists
  await page.goto(`/workshop?session=${globalSessionId}`);
  // FAILS if test runs in isolation!
});
```

```typescript
// ✅ GOOD: Each test is self-contained
test('create session', async ({ page }) => {
  await page.goto('/workshop');
  await page.fill('#org-name', 'Acme Corp');
  await page.click('#start-session');
  await expect(page.locator('.session-title')).toHaveText('Acme Corp');
});

test('resume session', async ({ page, request }) => {
  // Create session via API for this test
  const session = await request.post('/api/sessions', {
    data: { organizationName: 'Acme Corp' },
  });
  const { id } = await session.json();

  // Now test the resume flow
  await page.goto(`/workshop?session=${id}`);
  await expect(page.locator('.session-title')).toHaveText('Acme Corp');
});
```

**Playwright's Isolation Guarantees:**

1. **Fresh browser context per test** (clean cookies, storage, cache)
2. **Parallel execution** without interference
3. **Test-scoped fixtures** (page, context, request)

### 2.7 Fixtures: Playwright's Dependency Injection

**What are Fixtures?**

Fixtures are Playwright's way of providing setup/teardown logic and shared resources to tests.

**Built-in Fixtures:**

```typescript
test('example', async ({ page, context, request, browser }) => {
  // `page` - Fresh page in a fresh context
  // `context` - Isolated browser context
  // `request` - API request client
  // `browser` - The actual browser instance
});
```

**How Fixtures Work:**

1. **Setup**: Fixture is created before the test
2. **Test runs**: Test receives the fixture
3. **Teardown**: Fixture is cleaned up after the test

**Example: Custom Fixture for Authenticated User**

```typescript
// tests/fixtures.ts
import { test as base } from '@playwright/test';

type Fixtures = {
  authenticatedPage: Page;
};

export const test = base.extend<Fixtures>({
  authenticatedPage: async ({ page }, use) => {
    // Setup: Log in
    await page.goto('/login');
    await page.fill('#email', 'test@example.com');
    await page.fill('#password', 'password123');
    await page.click('#login-button');
    await expect(page.locator('.user-avatar')).toBeVisible();

    // Provide page to test
    await use(page);

    // Teardown: Log out
    await page.click('.user-avatar');
    await page.click('#logout');
  },
});

// tests/dashboard.spec.ts
import { test } from './fixtures';

test('view dashboard', async ({ authenticatedPage: page }) => {
  await page.goto('/dashboard');
  await expect(page.locator('.dashboard-title')).toBeVisible();
});
```

### 2.8 When to Use Playwright vs Jest

<!-- Query Pattern: playwright vs jest, when to use e2e tests, unit test vs e2e -->

**Decision Matrix:**

| Scenario | Use Jest | Use Playwright |
|----------|----------|----------------|
| **Testing a utility function** | ✅ | ❌ |
| **Testing React component rendering** | ✅ (RTL) | ❌ |
| **Testing API endpoint logic** | ✅ | ⚠️ (Can use Playwright for E2E API tests) |
| **Testing user navigation flow** | ❌ | ✅ |
| **Testing UI interactions (clicks, forms)** | ⚠️ (Limited) | ✅ |
| **Testing authentication flow** | ❌ | ✅ |
| **Testing responsive design** | ❌ | ✅ |
| **Testing cross-browser behavior** | ❌ | ✅ |
| **Testing real network requests** | ❌ | ✅ |

**Examples:**

```typescript
// ✅ JEST: Testing ROI calculation logic
// tests/unit/roi-calculator.test.ts
import { calculateNPV } from '@/lib/roi/calculator';

describe('calculateNPV', () => {
  it('calculates net present value correctly', () => {
    const cashFlows = [1000, 2000, 3000];
    const discountRate = 0.1;
    const initialInvestment = 5000;

    const npv = calculateNPV(cashFlows, discountRate, initialInvestment);

    expect(npv).toBeCloseTo(735.54, 2);
  });
});
```

```typescript
// ✅ PLAYWRIGHT: Testing workshop completion flow
// tests/e2e/workshop.spec.ts
import { test, expect } from '@playwright/test';

test('complete workshop session', async ({ page }) => {
  await page.goto('/workshop');

  // Start session
  await page.fill('#organization-name', 'Acme Corp');
  await page.click('#start-session');

  // Chat with Melissa
  await page.fill('#chat-input', 'We want to automate invoice processing');
  await page.click('#send-message');
  await expect(page.locator('.melissa-response')).toContainText('How many invoices');

  // Answer ROI questions
  await page.fill('#chat-input', 'About 500 per month');
  await page.click('#send-message');

  // Wait for ROI calculation
  await expect(page.locator('.roi-summary')).toBeVisible({ timeout: 10000 });
  await expect(page.locator('.npv-value')).toContainText('$');
});
```

**Bloom's Testing Strategy:**

1. **Unit tests (Jest)**: ROI calculations, utility functions, data transformations
2. **Integration tests (Jest + Supertest)**: API endpoints, database operations
3. **E2E tests (Playwright)**: Critical user paths, full workflow validation

---

## 3. Golden Path

<!-- Query Pattern: playwright best practices, recommended approach, bloom testing conventions -->

### 3.1 Bloom's Playwright Conventions

**File Structure:**

```
tests/
├── e2e/
│   ├── workshop/
│   │   ├── new-session.spec.ts
│   │   ├── resume-session.spec.ts
│   │   └── export-report.spec.ts
│   ├── settings/
│   │   ├── branding.spec.ts
│   │   └── monitoring.spec.ts
│   └── auth/
│       └── login.spec.ts
├── fixtures/
│   ├── authenticated-user.ts
│   ├── test-session.ts
│   └── index.ts
└── utils/
    ├── create-test-session.ts
    └── seed-database.ts
```

**Naming Conventions:**

- **Test files**: `*.spec.ts` (e.g., `workshop.spec.ts`)
- **Fixtures**: `*.ts` in `tests/fixtures/`
- **Utilities**: `*.ts` in `tests/utils/`
- **Test names**: Describe user action (e.g., "complete workshop session")

### 3.2 Recommended Test Structure

**The AAA Pattern:**

```typescript
test('descriptive test name', async ({ page }) => {
  // === ARRANGE ===
  // Set up test data and navigate to page
  await page.goto('/workshop');

  // === ACT ===
  // Perform user actions
  await page.fill('#organization-name', 'Acme Corp');
  await page.click('#start-session');

  // === ASSERT ===
  // Verify expected outcomes
  await expect(page.locator('.session-title')).toHaveText('Acme Corp');
  await expect(page.locator('.melissa-greeting')).toBeVisible();
});
```

**Best Practices:**

1. **Use `test.describe()` for grouping**:
   ```typescript
   test.describe('Workshop Session Management', () => {
     test('create new session', async ({ page }) => { /* ... */ });
     test('resume existing session', async ({ page }) => { /* ... */ });
     test('delete session', async ({ page }) => { /* ... */ });
   });
   ```

2. **Use `test.beforeEach()` for shared setup**:
   ```typescript
   test.describe('Authenticated Routes', () => {
     test.beforeEach(async ({ page }) => {
       // Log in before each test
       await page.goto('/login');
       await page.fill('#email', 'test@example.com');
       await page.fill('#password', 'password123');
       await page.click('#login-button');
     });

     test('view dashboard', async ({ page }) => {
       await page.goto('/dashboard');
       // Already logged in from beforeEach
     });
   });
   ```

3. **Use descriptive assertions**:
   ```typescript
   // ❌ Generic assertion
   expect(await page.locator('.status').textContent()).toBe('Active');

   // ✅ Specific Playwright assertion with auto-retry
   await expect(page.locator('.status')).toHaveText('Active');
   ```

### 3.3 Selector Strategy

**Priority Order:**

1. **User-facing attributes** (aria-label, role, text content)
2. **Data attributes** (`data-testid`)
3. **IDs** (`#element-id`)
4. **Classes** (`.element-class`) - Last resort

**Examples:**

```typescript
// ✅ BEST: User-facing (resilient to implementation changes)
await page.getByRole('button', { name: 'Start Session' }).click();
await page.getByLabel('Organization Name').fill('Acme Corp');
await page.getByText('Welcome to Bloom').click();

// ✅ GOOD: Test-specific attribute
await page.locator('[data-testid="session-card"]').click();

// ⚠️ ACCEPTABLE: Unique ID
await page.locator('#start-session-button').click();

// ❌ AVOID: Brittle class selector
await page.locator('.btn.btn-primary.btn-lg.mt-4').click();
```

**See:** `02-SELECTORS-LOCATORS.md` for comprehensive selector guidance.

### 3.4 API Setup for E2E Tests

**Use API to Create Test Data:**

```typescript
test('resume session', async ({ page, request }) => {
  // Create session via API (fast, reliable)
  const response = await request.post('/api/sessions', {
    data: {
      organizationName: 'Test Corp',
      industry: 'Technology',
    },
  });
  const session = await response.json();

  // Test the UI for resuming
  await page.goto(`/workshop?session=${session.id}`);
  await expect(page.locator('.session-title')).toHaveText('Test Corp');
});
```

**Why This Approach:**

- **Faster**: API calls are 10-100x faster than UI automation
- **More reliable**: No UI flakiness during setup
- **Better isolation**: Each test creates its own data
- **Easier debugging**: Setup failures are distinct from test failures

### 3.5 Handling Async Operations

**Waiting for Network Requests:**

```typescript
// Wait for specific API call
await Promise.all([
  page.waitForResponse(resp => resp.url().includes('/api/sessions')),
  page.click('#start-session'),
]);

// Wait for multiple requests
await Promise.all([
  page.waitForResponse('/api/sessions'),
  page.waitForResponse('/api/organizations'),
  page.click('#load-data'),
]);
```

**Waiting for Navigation:**

```typescript
// Wait for page navigation
await Promise.all([
  page.waitForURL('/dashboard'),
  page.click('#go-to-dashboard'),
]);
```

**Custom Waiters:**

```typescript
// Wait for custom condition
await page.waitForFunction(() => {
  return document.querySelectorAll('.session-card').length > 0;
});

// Wait for element state
await page.locator('.spinner').waitFor({ state: 'hidden' });
```

### 3.6 Debugging Tests

**Running Tests with Debug Mode:**

```bash
# Open Playwright Inspector
npx playwright test --debug

# Run specific test with debug
npx playwright test workshop.spec.ts --debug

# Run in headed mode (see browser)
npx playwright test --headed

# Run with slow motion (easier to follow)
npx playwright test --headed --slow-mo=1000
```

**Using Trace Viewer:**

```bash
# Generate trace on failure (default in Bloom)
npx playwright test

# Open trace viewer
npx playwright show-trace trace.zip
```

**Trace viewer shows:**

- Screenshots at each step
- Network requests/responses
- Console logs
- DOM snapshots
- Action timeline

**Adding Debug Statements:**

```typescript
test('debug example', async ({ page }) => {
  await page.goto('/workshop');

  // Pause execution (opens inspector)
  await page.pause();

  // Take screenshot
  await page.screenshot({ path: 'debug.png' });

  // Print page HTML
  console.log(await page.content());

  // Print element text
  console.log(await page.locator('.title').textContent());
});
```

---

## 4. Variations & Trade-Offs

<!-- Query Pattern: playwright test strategies, test organization, parallel execution -->

### 4.1 Serial vs Parallel Execution

**Parallel (Default):**

```typescript
// playwright.config.ts
export default defineConfig({
  workers: 4, // Run 4 tests simultaneously
});

// Tests run in parallel automatically
test('test 1', async ({ page }) => { /* ... */ });
test('test 2', async ({ page }) => { /* ... */ });
test('test 3', async ({ page }) => { /* ... */ });
```

**Serial (When Needed):**

```typescript
// Force tests to run one at a time
test.describe.serial('Database Migrations', () => {
  test('run migration', async ({ page }) => { /* ... */ });
  test('verify schema', async ({ page }) => { /* ... */ });
  test('rollback migration', async ({ page }) => { /* ... */ });
});
```

**Trade-offs:**

| Parallel | Serial |
|----------|--------|
| ✅ Fast (4x speedup with 4 workers) | ❌ Slow (1x speed) |
| ✅ Better test isolation | ✅ Easier to debug |
| ⚠️ Requires careful isolation | ✅ Tests can share state |
| ⚠️ Harder to debug race conditions | ✅ Predictable execution order |

**When to Use Serial:**

- Tests that modify shared state (database schema, global config)
- Tests that must run in specific order (rare, usually indicates bad test design)
- Debugging flaky tests (easier to reproduce)

### 4.2 Fixture Scope

**Test-scoped (Default):**

```typescript
// New fixture instance for each test
test('test 1', async ({ page }) => { /* Fresh page */ });
test('test 2', async ({ page }) => { /* Fresh page */ });
```

**Worker-scoped:**

```typescript
// One fixture instance per worker (shared across tests)
export const test = base.extend<{}, { workerStorageState: string }>({
  workerStorageState: [async ({ browser }, use) => {
    // Setup once per worker
    const context = await browser.newContext();
    const page = await context.newPage();
    await page.goto('/login');
    await page.fill('#email', 'test@example.com');
    await page.fill('#password', 'password123');
    await page.click('#login-button');

    // Save auth state
    await context.storageState({ path: 'auth.json' });
    await context.close();

    await use('auth.json');
  }, { scope: 'worker' }],
});
```

**Trade-offs:**

| Test-scoped | Worker-scoped |
|-------------|---------------|
| ✅ Perfect isolation | ⚠️ Shared state across tests |
| ❌ Slower (setup per test) | ✅ Faster (setup once) |
| ✅ Easier to reason about | ⚠️ Tests can interfere |
| ✅ Safer for parallel execution | ⚠️ Requires careful cleanup |

**When to Use Worker-scoped:**

- Expensive setup (e.g., seeding large datasets)
- Authentication state (see `storageState` pattern)
- Read-only shared resources

### 4.3 Headed vs Headless

**Headless (Default):**

```typescript
// playwright.config.ts
export default defineConfig({
  use: {
    headless: true, // No visible browser
  },
});
```

**Headed (For Development):**

```bash
# Run with visible browser
npx playwright test --headed

# Or configure in playwright.config.ts
export default defineConfig({
  use: {
    headless: false,
  },
});
```

**Trade-offs:**

| Headless | Headed |
|----------|--------|
| ✅ Faster (~20% speedup) | ❌ Slower |
| ✅ Works in CI/CD | ⚠️ Requires display server |
| ❌ Harder to debug | ✅ Easier to debug |
| ✅ Lower resource usage | ❌ Higher resource usage |

**Best Practice:**

- **Development**: Use `--headed` when writing/debugging tests
- **CI/CD**: Always use headless
- **Bloom convention**: Headless by default, override with `--headed` flag

### 4.4 Test Granularity

**Fine-grained (Many Small Tests):**

```typescript
test('fill organization name', async ({ page }) => {
  await page.goto('/workshop');
  await page.fill('#organization-name', 'Acme Corp');
  await expect(page.locator('#organization-name')).toHaveValue('Acme Corp');
});

test('click start session', async ({ page }) => {
  await page.goto('/workshop');
  await page.fill('#organization-name', 'Acme Corp');
  await page.click('#start-session');
  await expect(page.locator('.session-title')).toBeVisible();
});

test('verify Melissa greeting', async ({ page }) => {
  await page.goto('/workshop');
  await page.fill('#organization-name', 'Acme Corp');
  await page.click('#start-session');
  await expect(page.locator('.melissa-greeting')).toContainText('Hello');
});
```

**Coarse-grained (Few Large Tests):**

```typescript
test('complete workshop session', async ({ page }) => {
  // Start session
  await page.goto('/workshop');
  await page.fill('#organization-name', 'Acme Corp');
  await page.click('#start-session');

  // Chat with Melissa
  await page.fill('#chat-input', 'We automate invoices');
  await page.click('#send-message');
  await expect(page.locator('.melissa-response')).toBeVisible();

  // Answer questions
  await page.fill('#chat-input', '500 per month');
  await page.click('#send-message');

  // Review ROI
  await expect(page.locator('.roi-summary')).toBeVisible();
  await expect(page.locator('.npv-value')).toContainText('$');
});
```

**Trade-offs:**

| Fine-grained | Coarse-grained |
|--------------|----------------|
| ✅ Easier to debug failures | ❌ Harder to debug failures |
| ✅ More focused assertions | ⚠️ Many assertions per test |
| ❌ Lots of duplication | ✅ Less duplication |
| ❌ Slower (repeated setup) | ✅ Faster (less setup) |
| ⚠️ Tests may be too atomic | ✅ Tests match user journeys |

**Bloom's Recommendation:**

- **Critical paths**: Use coarse-grained tests (e.g., "complete workshop session")
- **Edge cases**: Use fine-grained tests (e.g., "handle invalid organization name")
- **Balance**: Aim for 5-15 user actions per test

---

## 5. Examples

<!-- Query Pattern: playwright examples, test examples, bloom e2e tests -->

### Example 1 – Pedagogical: Basic Page Navigation

**Purpose**: Demonstrate core Playwright concepts for absolute beginners.

**Scenario**: Navigate to the workshop page and verify basic elements.

```typescript
// tests/e2e/workshop/basic-navigation.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Workshop Page - Basic Navigation', () => {
  test('should load workshop page and display title', async ({ page }) => {
    // === ARRANGE ===
    // Navigate to the workshop page
    await page.goto('/workshop');

    // === ASSERT ===
    // Verify page loaded correctly
    await expect(page).toHaveTitle(/Bloom Workshop/);
    await expect(page.locator('h1')).toContainText('ROI Discovery Workshop');
  });

  test('should display organization name input field', async ({ page }) => {
    // === ARRANGE ===
    await page.goto('/workshop');

    // === ASSERT ===
    // Verify input field exists and is visible
    const orgNameInput = page.getByLabel('Organization Name');
    await expect(orgNameInput).toBeVisible();
    await expect(orgNameInput).toBeEnabled();
    await expect(orgNameInput).toHaveAttribute('placeholder', 'Enter your organization name');
  });

  test('should fill organization name and verify value', async ({ page }) => {
    // === ARRANGE ===
    await page.goto('/workshop');

    // === ACT ===
    // Fill in the organization name
    await page.getByLabel('Organization Name').fill('Acme Corporation');

    // === ASSERT ===
    // Verify the value was set correctly
    await expect(page.getByLabel('Organization Name')).toHaveValue('Acme Corporation');
  });

  test('should enable start session button when name is provided', async ({ page }) => {
    // === ARRANGE ===
    await page.goto('/workshop');

    // === ASSERT ===
    // Initially, button should be disabled
    const startButton = page.getByRole('button', { name: 'Start Session' });
    await expect(startButton).toBeDisabled();

    // === ACT ===
    // Fill in organization name
    await page.getByLabel('Organization Name').fill('Acme Corporation');

    // === ASSERT ===
    // Button should now be enabled
    await expect(startButton).toBeEnabled();
  });
});
```

**Key Concepts Demonstrated:**

1. **Test structure**: `test.describe()` for grouping, `test()` for individual tests
2. **Navigation**: `page.goto('/workshop')`
3. **Locators**: `page.getByLabel()`, `page.getByRole()`, `page.locator()`
4. **Assertions**: `expect(page).toHaveTitle()`, `expect(locator).toBeVisible()`
5. **Auto-waiting**: All actions wait automatically for elements to be ready

### Example 2 – Realistic Synthetic: Create Workshop Session

**Purpose**: Realistic test that combines multiple user actions in a typical workflow.

**Scenario**: User creates a new workshop session, answers initial questions, and verifies session creation.

```typescript
// tests/e2e/workshop/create-session.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Workshop Session Creation', () => {
  test('should create new session and start conversation with Melissa', async ({ page }) => {
    // === ARRANGE ===
    await page.goto('/workshop');

    // === ACT - Part 1: Fill Session Details ===
    await page.getByLabel('Organization Name').fill('Acme Corporation');
    await page.getByLabel('Industry').selectOption('Technology');

    // Take screenshot for documentation
    await page.screenshot({ path: 'test-results/01-session-form.png' });

    // === ACT - Part 2: Start Session ===
    await page.getByRole('button', { name: 'Start Session' }).click();

    // === ASSERT - Part 1: Verify Session Created ===
    // URL should change to include session ID
    await expect(page).toHaveURL(/\/workshop\?session=[a-zA-Z0-9]+/);

    // Session header should show organization name
    await expect(page.locator('.session-header .organization-name')).toHaveText('Acme Corporation');

    // === ASSERT - Part 2: Verify Melissa Greeting ===
    // Melissa should greet the user
    const melissaGreeting = page.locator('.melissa-message').first();
    await expect(melissaGreeting).toBeVisible({ timeout: 10000 });
    await expect(melissaGreeting).toContainText('Hello');
    await expect(melissaGreeting).toContainText('Acme Corporation');

    // Chat input should be enabled
    await expect(page.getByLabel('Chat message')).toBeEnabled();

    // === ACT - Part 3: Send First Message ===
    const chatInput = page.getByLabel('Chat message');
    await chatInput.fill('We want to automate our invoice processing workflow');
    await page.getByRole('button', { name: 'Send' }).click();

    // === ASSERT - Part 3: Verify Message Sent ===
    // User message should appear
    const userMessage = page.locator('.user-message').last();
    await expect(userMessage).toContainText('automate our invoice processing');

    // Melissa should respond
    const melissaResponse = page.locator('.melissa-message').nth(1);
    await expect(melissaResponse).toBeVisible({ timeout: 15000 }); // AI response may take time

    // Response should acknowledge the topic
    await expect(melissaResponse).toMatch(/invoice|processing|automat/i);

    // === ASSERT - Part 4: Verify Session Persistence ===
    // Session should be saved (check via API)
    const sessionId = page.url().match(/session=([a-zA-Z0-9]+)/)?.[1];
    expect(sessionId).toBeTruthy();

    const response = await page.request.get(`/api/sessions/${sessionId}`);
    expect(response.ok()).toBeTruthy();

    const sessionData = await response.json();
    expect(sessionData.organizationName).toBe('Acme Corporation');
    expect(sessionData.industry).toBe('Technology');
    expect(sessionData.messages).toHaveLength(3); // Greeting + User + Melissa
  });

  test('should handle network errors gracefully', async ({ page }) => {
    // === ARRANGE ===
    // Intercept API calls and simulate failure
    await page.route('/api/sessions', route => {
      route.fulfill({
        status: 500,
        body: JSON.stringify({ error: 'Database connection failed' }),
      });
    });

    await page.goto('/workshop');

    // === ACT ===
    await page.getByLabel('Organization Name').fill('Test Corp');
    await page.getByRole('button', { name: 'Start Session' }).click();

    // === ASSERT ===
    // Error message should appear
    const errorMessage = page.locator('.error-notification');
    await expect(errorMessage).toBeVisible();
    await expect(errorMessage).toContainText('Failed to create session');

    // Form should remain filled (user doesn't lose data)
    await expect(page.getByLabel('Organization Name')).toHaveValue('Test Corp');

    // User can retry
    await page.unroute('/api/sessions'); // Remove intercept
    await page.getByRole('button', { name: 'Start Session' }).click();
    await expect(page).toHaveURL(/\/workshop\?session=/);
  });

  test('should validate required fields', async ({ page }) => {
    // === ARRANGE ===
    await page.goto('/workshop');

    // === ACT ===
    // Try to submit without filling required fields
    const startButton = page.getByRole('button', { name: 'Start Session' });

    // === ASSERT ===
    // Button should be disabled
    await expect(startButton).toBeDisabled();

    // === ACT ===
    // Fill only organization name
    await page.getByLabel('Organization Name').fill('A');

    // === ASSERT ===
    // Button should still be disabled (min length: 3 characters)
    await expect(startButton).toBeDisabled();

    // === ACT ===
    // Fill valid organization name
    await page.getByLabel('Organization Name').fill('Acme');

    // === ASSERT ===
    // Button should now be enabled
    await expect(startButton).toBeEnabled();
  });
});
```

**Key Concepts Demonstrated:**

1. **Multi-step workflow**: Complete user journey from form to chat
2. **API assertions**: Verify backend state using `page.request`
3. **Network interception**: Mock API failures with `page.route()`
4. **Error handling**: Test error states and recovery
5. **Form validation**: Test required fields and validation rules
6. **Screenshots**: Capture state for documentation/debugging
7. **Async waits**: Handle AI responses with appropriate timeouts

### Example 3 – Framework Integration: Next.js + Bloom Patterns

**Purpose**: Demonstrate Bloom-specific patterns for testing Next.js 16 features.

**Scenario**: Test resume session functionality using Bloom's conventions and Next.js patterns.

```typescript
// tests/e2e/workshop/resume-session.spec.ts
import { test, expect } from '@playwright/test';
import { createTestSession } from '../utils/create-test-session';

test.describe('Resume Workshop Session', () => {
  test('should resume existing session from URL', async ({ page, request }) => {
    // === ARRANGE ===
    // Create session via API (Bloom pattern: use API for test data)
    const session = await createTestSession(request, {
      organizationName: 'Resume Test Corp',
      industry: 'Healthcare',
      messages: [
        {
          role: 'assistant',
          content: 'Hello! Welcome back to your session.',
        },
        {
          role: 'user',
          content: 'We want to automate patient records.',
        },
        {
          role: 'assistant',
          content: 'Great! How many records do you process monthly?',
        },
      ],
    });

    // === ACT ===
    // Navigate to session URL (Next.js 16 pattern with query params)
    await page.goto(`/workshop?session=${session.id}`);

    // === ASSERT - Part 1: Session Loaded ===
    // Session header should show correct organization
    await expect(page.locator('.session-header .organization-name')).toHaveText('Resume Test Corp');

    // Industry badge should be visible
    await expect(page.locator('.industry-badge')).toHaveText('Healthcare');

    // === ASSERT - Part 2: Message History Loaded ===
    // Should show all 3 previous messages
    await expect(page.locator('.melissa-message')).toHaveCount(2);
    await expect(page.locator('.user-message')).toHaveCount(1);

    // Messages should have correct content
    const messages = page.locator('.chat-message');
    await expect(messages.nth(0)).toContainText('Welcome back');
    await expect(messages.nth(1)).toContainText('automate patient records');
    await expect(messages.nth(2)).toContainText('How many records');

    // === ACT - Part 2: Continue Conversation ===
    await page.getByLabel('Chat message').fill('About 1000 records per month');
    await page.getByRole('button', { name: 'Send' }).click();

    // === ASSERT - Part 3: New Message Persisted ===
    // Wait for Melissa's response
    await expect(page.locator('.melissa-message')).toHaveCount(3, { timeout: 15000 });

    // Verify new message was saved to database
    const updatedSession = await request.get(`/api/sessions/${session.id}`);
    const sessionData = await updatedSession.json();
    expect(sessionData.messages).toHaveLength(5); // 3 original + 1 user + 1 assistant

    // === ASSERT - Part 4: Next.js Metadata ===
    // Verify page title includes organization name
    await expect(page).toHaveTitle(/Resume Test Corp/);

    // Verify Open Graph meta tags (for sharing)
    const ogTitle = page.locator('meta[property="og:title"]');
    await expect(ogTitle).toHaveAttribute('content', /Resume Test Corp/);
  });

  test('should handle invalid session ID gracefully', async ({ page }) => {
    // === ACT ===
    // Navigate to non-existent session
    await page.goto('/workshop?session=invalid-session-id');

    // === ASSERT ===
    // Should redirect to new session page
    await expect(page).toHaveURL('/workshop');

    // Should show error notification
    const errorNotification = page.locator('.error-notification');
    await expect(errorNotification).toBeVisible();
    await expect(errorNotification).toContainText('Session not found');

    // User can create new session
    await page.getByLabel('Organization Name').fill('New Session Corp');
    await page.getByRole('button', { name: 'Start Session' }).click();
    await expect(page).toHaveURL(/\/workshop\?session=/);
  });

  test('should preserve session across page reloads', async ({ page, request }) => {
    // === ARRANGE ===
    const session = await createTestSession(request, {
      organizationName: 'Reload Test Corp',
    });

    await page.goto(`/workshop?session=${session.id}`);

    // === ACT ===
    // Send a message
    await page.getByLabel('Chat message').fill('Test message before reload');
    await page.getByRole('button', { name: 'Send' }).click();
    await expect(page.locator('.user-message')).toHaveCount(1);

    // Reload the page (simulates user hitting refresh)
    await page.reload();

    // === ASSERT ===
    // Session should still be loaded
    await expect(page.locator('.session-header .organization-name')).toHaveText('Reload Test Corp');

    // Previous message should still be visible
    await expect(page.locator('.user-message')).toContainText('Test message before reload');

    // User can continue chatting
    await page.getByLabel('Chat message').fill('Test message after reload');
    await page.getByRole('button', { name: 'Send' }).click();
    await expect(page.locator('.user-message')).toHaveCount(2);
  });

  test('should show loading state while fetching session', async ({ page, request }) => {
    // === ARRANGE ===
    const session = await createTestSession(request, {
      organizationName: 'Loading Test Corp',
    });

    // Slow down the API response to test loading state
    await page.route(`/api/sessions/${session.id}`, async route => {
      await new Promise(resolve => setTimeout(resolve, 2000)); // 2s delay
      await route.continue();
    });

    // === ACT ===
    await page.goto(`/workshop?session=${session.id}`);

    // === ASSERT ===
    // Loading spinner should be visible
    const loadingSpinner = page.locator('.loading-spinner');
    await expect(loadingSpinner).toBeVisible();

    // Session content should not be visible yet
    await expect(page.locator('.session-header')).not.toBeVisible();

    // Wait for loading to complete
    await expect(loadingSpinner).not.toBeVisible({ timeout: 5000 });

    // Session should now be visible
    await expect(page.locator('.session-header .organization-name')).toHaveText('Loading Test Corp');
  });

  test('should support browser back/forward navigation', async ({ page, request }) => {
    // === ARRANGE ===
    const session1 = await createTestSession(request, {
      organizationName: 'Session 1',
    });
    const session2 = await createTestSession(request, {
      organizationName: 'Session 2',
    });

    // === ACT ===
    // Navigate to first session
    await page.goto(`/workshop?session=${session1.id}`);
    await expect(page.locator('.session-header .organization-name')).toHaveText('Session 1');

    // Navigate to second session
    await page.goto(`/workshop?session=${session2.id}`);
    await expect(page.locator('.session-header .organization-name')).toHaveText('Session 2');

    // Use browser back button
    await page.goBack();

    // === ASSERT ===
    // Should return to first session
    await expect(page).toHaveURL(new RegExp(session1.id));
    await expect(page.locator('.session-header .organization-name')).toHaveText('Session 1');

    // Use browser forward button
    await page.goForward();

    // Should return to second session
    await expect(page).toHaveURL(new RegExp(session2.id));
    await expect(page.locator('.session-header .organization-name')).toHaveText('Session 2');
  });
});

// === TEST UTILITY: Create Test Session ===
// tests/utils/create-test-session.ts

import { APIRequestContext } from '@playwright/test';

interface CreateSessionOptions {
  organizationName: string;
  industry?: string;
  messages?: Array<{
    role: 'user' | 'assistant';
    content: string;
  }>;
}

export async function createTestSession(
  request: APIRequestContext,
  options: CreateSessionOptions
) {
  const response = await request.post('/api/sessions', {
    data: {
      organizationName: options.organizationName,
      industry: options.industry || 'Technology',
    },
  });

  if (!response.ok()) {
    throw new Error(`Failed to create test session: ${response.status()}`);
  }

  const session = await response.json();

  // Add messages if provided
  if (options.messages && options.messages.length > 0) {
    await request.post(`/api/sessions/${session.id}/messages`, {
      data: {
        messages: options.messages,
      },
    });
  }

  return session;
}
```

**Key Bloom Patterns Demonstrated:**

1. **API-first test data creation**: Use `createTestSession()` utility
2. **Next.js 16 query params**: Test URL handling with session IDs
3. **Message persistence**: Verify database state via API
4. **Next.js metadata**: Test page titles and Open Graph tags
5. **Error handling**: Test invalid session IDs and 404 responses
6. **Loading states**: Test async data fetching with delays
7. **Browser navigation**: Test back/forward button support
8. **Page reloads**: Test session persistence across refreshes

**Bloom-Specific Conventions:**

- Test utilities in `tests/utils/`
- API assertions using `page.request`
- Loading states with `.loading-spinner`
- Error notifications with `.error-notification`
- Session headers with `.session-header .organization-name`

---

## 6. Common Pitfalls

<!-- Query Pattern: playwright common mistakes, playwright antipatterns, playwright best practices -->

### Pitfall 1: Using `waitForTimeout()` Instead of Auto-Waiting

**❌ WRONG: Hard-coded waits**

```typescript
test('flaky test with manual waits', async ({ page }) => {
  await page.goto('/workshop');
  await page.click('#start-session');

  // BAD: Hard-coded 5-second wait
  await page.waitForTimeout(5000);

  // What if it loads in 6 seconds? Test fails.
  // What if it loads in 1 second? Test wastes 4 seconds.
  expect(await page.locator('.session-title').textContent()).toBe('Welcome');
});
```

**✅ CORRECT: Use auto-waiting assertions**

```typescript
test('reliable test with auto-waiting', async ({ page }) => {
  await page.goto('/workshop');
  await page.click('#start-session');

  // GOOD: Retries for up to 5 seconds (default timeout)
  await expect(page.locator('.session-title')).toHaveText('Welcome');

  // If it loads in 1 second, test passes immediately.
  // If it takes 4 seconds, test still passes.
  // If it takes >5 seconds, test fails with clear error.
});
```

**Why This Matters:**

- Hard-coded waits are the #1 cause of flaky tests
- Auto-waiting makes tests faster and more reliable
- Clear timeout errors help debugging

### Pitfall 2: Using Fragile CSS Selectors

**❌ WRONG: Implementation-dependent selectors**

```typescript
test('fragile selectors', async ({ page }) => {
  await page.goto('/workshop');

  // BAD: Breaks if CSS classes change
  await page.locator('.btn.btn-primary.btn-lg.mt-4.px-6').click();

  // BAD: Breaks if DOM structure changes
  await page.locator('.container > div:nth-child(2) > button:first-child').click();

  // BAD: Generic class name
  await page.locator('.button').click(); // Which button???
});
```

**✅ CORRECT: User-facing selectors**

```typescript
test('resilient selectors', async ({ page }) => {
  await page.goto('/workshop');

  // GOOD: User-facing attribute (aria-label)
  await page.getByLabel('Organization Name').fill('Acme Corp');

  // GOOD: User-facing role and name
  await page.getByRole('button', { name: 'Start Session' }).click();

  // GOOD: Test-specific attribute
  await page.locator('[data-testid="session-card"]').click();

  // GOOD: Unique ID (if necessary)
  await page.locator('#start-session-button').click();
});
```

**Why This Matters:**

- User-facing selectors survive refactoring
- Tests document how users interact with the app
- Tests break only when user experience changes (which is intentional)

### Pitfall 3: Not Isolating Tests

**❌ WRONG: Tests depend on each other**

```typescript
let sessionId: string;

test('create session', async ({ page }) => {
  await page.goto('/workshop');
  await page.fill('#org-name', 'Acme Corp');
  await page.click('#start-session');

  // BAD: Storing state in global variable
  sessionId = page.url().match(/session=([^&]+)/)?.[1]!;
});

test('resume session', async ({ page }) => {
  // BAD: Depends on previous test
  await page.goto(`/workshop?session=${sessionId}`);
  // FAILS if run in isolation or if previous test fails!
});
```

**✅ CORRECT: Each test is self-contained**

```typescript
test('create session', async ({ page }) => {
  await page.goto('/workshop');
  await page.fill('#org-name', 'Acme Corp');
  await page.click('#start-session');

  // GOOD: Only assert on this test's behavior
  await expect(page.locator('.session-title')).toHaveText('Acme Corp');
});

test('resume session', async ({ page, request }) => {
  // GOOD: Create test data via API
  const session = await request.post('/api/sessions', {
    data: { organizationName: 'Acme Corp' },
  });
  const { id } = await session.json();

  // Now test resume flow independently
  await page.goto(`/workshop?session=${id}`);
  await expect(page.locator('.session-title')).toHaveText('Acme Corp');
});
```

**Why This Matters:**

- Tests can run in any order
- Tests can run in parallel
- Test failures are isolated and easier to debug

### Pitfall 4: Not Handling Async Operations Properly

**❌ WRONG: Race conditions**

```typescript
test('race condition', async ({ page }) => {
  await page.goto('/workshop');

  // BAD: Click triggers API call, but we don't wait for it
  page.click('#load-data'); // Missing await!

  // BAD: Assertion runs before API call completes
  await expect(page.locator('.data-loaded')).toBeVisible();
  // FLAKY: Sometimes passes, sometimes fails
});
```

**✅ CORRECT: Wait for async operations**

```typescript
test('proper async handling', async ({ page }) => {
  await page.goto('/workshop');

  // GOOD: Wait for click action to complete
  await page.click('#load-data');

  // GOOD: Assertion auto-waits for element
  await expect(page.locator('.data-loaded')).toBeVisible();

  // BETTER: Explicitly wait for network request
  await Promise.all([
    page.waitForResponse('/api/sessions'),
    page.click('#load-data'),
  ]);
  await expect(page.locator('.data-loaded')).toBeVisible();
});
```

**Why This Matters:**

- Prevents race conditions and flaky tests
- Makes test behavior predictable
- Easier to debug when failures occur

### Pitfall 5: Overly Broad Selectors

**❌ WRONG: Ambiguous selectors**

```typescript
test('ambiguous selectors', async ({ page }) => {
  await page.goto('/workshop');

  // BAD: Multiple buttons on page
  await page.locator('button').click(); // Which button?

  // BAD: Multiple inputs
  await page.locator('input').fill('Acme Corp'); // Which input?

  // BAD: Multiple elements with same class
  await expect(page.locator('.badge')).toHaveText('Active'); // Which badge?
});
```

**✅ CORRECT: Specific selectors**

```typescript
test('specific selectors', async ({ page }) => {
  await page.goto('/workshop');

  // GOOD: Specific role and name
  await page.getByRole('button', { name: 'Start Session' }).click();

  // GOOD: Specific label
  await page.getByLabel('Organization Name').fill('Acme Corp');

  // GOOD: Filter by text content
  await expect(page.locator('.badge').filter({ hasText: 'Active' })).toBeVisible();

  // GOOD: Use first() if you know it's the first match
  await expect(page.locator('.badge').first()).toHaveText('Active');
});
```

**Why This Matters:**

- Prevents selecting the wrong element
- Tests are more maintainable
- Error messages are clearer when tests fail

### Pitfall 6: Not Using Fixtures for Shared Setup

**❌ WRONG: Repeated setup code**

```typescript
test('test 1 with authentication', async ({ page }) => {
  // BAD: Repeated login code
  await page.goto('/login');
  await page.fill('#email', 'test@example.com');
  await page.fill('#password', 'password123');
  await page.click('#login-button');

  // Actual test
  await page.goto('/dashboard');
  await expect(page.locator('.dashboard-title')).toBeVisible();
});

test('test 2 with authentication', async ({ page }) => {
  // BAD: Same login code duplicated
  await page.goto('/login');
  await page.fill('#email', 'test@example.com');
  await page.fill('#password', 'password123');
  await page.click('#login-button');

  // Actual test
  await page.goto('/settings');
  await expect(page.locator('.settings-title')).toBeVisible();
});
```

**✅ CORRECT: Use fixtures**

```typescript
// tests/fixtures/authenticated-user.ts
import { test as base } from '@playwright/test';

export const test = base.extend({
  authenticatedPage: async ({ page }, use) => {
    // Setup: Log in once
    await page.goto('/login');
    await page.fill('#email', 'test@example.com');
    await page.fill('#password', 'password123');
    await page.click('#login-button');
    await expect(page.locator('.user-avatar')).toBeVisible();

    // Provide page to test
    await use(page);

    // Teardown: Log out
    await page.click('.user-avatar');
    await page.click('#logout');
  },
});

// tests/dashboard.spec.ts
import { test } from './fixtures/authenticated-user';

test('view dashboard', async ({ authenticatedPage: page }) => {
  // GOOD: No login code needed
  await page.goto('/dashboard');
  await expect(page.locator('.dashboard-title')).toBeVisible();
});

test('view settings', async ({ authenticatedPage: page }) => {
  // GOOD: Authentication handled by fixture
  await page.goto('/settings');
  await expect(page.locator('.settings-title')).toBeVisible();
});
```

**Why This Matters:**

- Reduces code duplication
- Makes tests more readable
- Easier to update shared setup logic

### Pitfall 7: Not Mocking External Dependencies

**❌ WRONG: Tests depend on external services**

```typescript
test('send email notification', async ({ page }) => {
  await page.goto('/workshop');

  // BAD: Actually sends email via SendGrid API
  await page.click('#send-notification');

  // FLAKY: Depends on:
  // - SendGrid API availability
  // - Network connectivity
  // - API rate limits
  // - Email delivery timing
});
```

**✅ CORRECT: Mock external services**

```typescript
test('send email notification', async ({ page }) => {
  // GOOD: Mock SendGrid API
  await page.route('**/api.sendgrid.com/**', route => {
    route.fulfill({
      status: 200,
      body: JSON.stringify({ success: true }),
    });
  });

  await page.goto('/workshop');
  await page.click('#send-notification');

  // GOOD: Test UI feedback, not actual email delivery
  await expect(page.locator('.notification-success')).toHaveText('Email sent successfully');
});
```

**Why This Matters:**

- Tests run reliably without external dependencies
- Tests run faster (no network latency)
- No accidental side effects (e.g., sending real emails)

### Pitfall 8: Not Cleaning Up Test Data

**❌ WRONG: Test data accumulates**

```typescript
test('create session', async ({ page }) => {
  await page.goto('/workshop');
  await page.fill('#org-name', 'Test Corp');
  await page.click('#start-session');

  // BAD: Session remains in database after test
  // After 1000 test runs, database has 1000 test sessions!
});
```

**✅ CORRECT: Clean up test data**

```typescript
test('create session', async ({ page, request }) => {
  await page.goto('/workshop');
  await page.fill('#org-name', 'Test Corp');
  await page.click('#start-session');

  // Get session ID
  const sessionId = page.url().match(/session=([^&]+)/)?.[1];

  // GOOD: Clean up after test
  await request.delete(`/api/sessions/${sessionId}`);
});

// BETTER: Use fixtures for automatic cleanup
export const test = base.extend({
  testSession: async ({ request }, use) => {
    // Create session
    const response = await request.post('/api/sessions', {
      data: { organizationName: 'Test Corp' },
    });
    const session = await response.json();

    // Provide session to test
    await use(session);

    // Automatic cleanup
    await request.delete(`/api/sessions/${session.id}`);
  },
});
```

**Why This Matters:**

- Prevents database bloat
- Tests remain fast
- CI/CD environments stay clean

---

## 7. AI Pair Programming Notes

<!-- Query Pattern: playwright ai assistance, playwright code generation, playwright debugging tips -->

### When to Load This File

**Load `01-FUNDAMENTALS.md` when:**

- User asks: "How do I get started with Playwright?"
- User asks: "What's the difference between Playwright and Jest?"
- User asks: "How do I write an E2E test?"
- User asks: "Why are my Playwright tests flaky?"
- User mentions: "auto-waiting", "test isolation", "fixtures", "browser contexts"
- User is writing their first Playwright test for Bloom
- User needs to understand Playwright architecture

### Combine With

- `02-SELECTORS-LOCATORS.md` - When user asks about finding elements
- `03-API-TESTING.md` - When user wants to test APIs with Playwright
- `04-VISUAL-REGRESSION.md` - When user wants to test visual changes
- `QUICK-REFERENCE.md` - When user needs syntax reminders
- `/docs/ARCHITECTURE.md` - When discussing Bloom's overall testing strategy

### Do NOT Combine With

- `../jest/` - Jest and Playwright serve different purposes
- `/docs/kb/typescript/` - Unless specifically discussing TypeScript+Playwright patterns

### Code Generation Guidelines

**When generating Playwright tests:**

1. **Use Bloom conventions**:
   ```typescript
   // ✅ Bloom pattern
   await page.getByRole('button', { name: 'Start Session' }).click();

   // ❌ Not Bloom pattern
   await page.locator('.btn-primary').click();
   ```

2. **Always use auto-waiting**:
   ```typescript
   // ✅ Auto-waiting
   await expect(page.locator('.title')).toHaveText('Welcome');

   // ❌ Manual waiting
   await page.waitForTimeout(5000);
   expect(await page.locator('.title').textContent()).toBe('Welcome');
   ```

3. **Create test data via API**:
   ```typescript
   // ✅ API setup
   const session = await request.post('/api/sessions', { data: { ... } });

   // ❌ UI setup (slow, brittle)
   await page.goto('/workshop');
   await page.fill('...');
   await page.click('...');
   ```

4. **Use descriptive test names**:
   ```typescript
   // ✅ Descriptive
   test('should create session and display Melissa greeting', async ({ page }) => {

   // ❌ Vague
   test('test 1', async ({ page }) => {
   ```

5. **Include AAA comments**:
   ```typescript
   test('example', async ({ page }) => {
     // === ARRANGE ===
     // Setup code

     // === ACT ===
     // Actions

     // === ASSERT ===
     // Verifications
   });
   ```

### Debugging Assistance

**When user reports flaky tests:**

1. **Check for manual waits**:
   ```typescript
   // Search for anti-patterns
   await page.waitForTimeout(...)  // ❌ Remove these
   await new Promise(resolve => setTimeout(...))  // ❌ Remove these
   ```

2. **Check for race conditions**:
   ```typescript
   // Look for missing await
   page.click(...)  // ❌ Should be: await page.click(...)
   ```

3. **Check for shared state**:
   ```typescript
   // Look for global variables
   let sessionId: string;  // ❌ Tests should not share state
   ```

4. **Suggest using trace viewer**:
   ```bash
   npx playwright test --trace on
   npx playwright show-trace trace.zip
   ```

### Common Questions & Answers

**Q: "How long should my E2E tests be?"**
A: Aim for 5-15 user actions per test. Test complete user journeys, not atomic operations.

**Q: "Should I test every possible scenario?"**
A: No. E2E tests are expensive. Test critical paths (10% of total tests). Use Jest for edge cases.

**Q: "How do I handle authentication?"**
A: Use `storageState` to save auth once and reuse. See worker-scoped fixtures example above.

**Q: "My tests are slow. How do I speed them up?"**
A: 1) Use API for test data, 2) Run in parallel, 3) Use `storageState` for auth, 4) Mock external APIs.

**Q: "Should I use `page.locator()` or `page.getByRole()`?"**
A: Prefer `getByRole()`, `getByLabel()`, `getByText()` for user-facing selectors. Use `locator()` with `data-testid` as fallback.

**Q: "How do I test responsive design?"**
A: Use `page.setViewportSize()` to test different screen sizes:
```typescript
await page.setViewportSize({ width: 375, height: 667 }); // Mobile
await page.setViewportSize({ width: 1920, height: 1080 }); // Desktop
```

**Q: "How do I test dark mode?"**
A: Use `page.emulateMedia()`:
```typescript
await page.emulateMedia({ colorScheme: 'dark' });
```

**Q: "Can I run Playwright tests in CI/CD?"**
A: Yes! Playwright works great in CI. Use headless mode and Docker containers. See Bloom's GitHub Actions config.

### Anti-Patterns to Avoid

When reviewing user code, look for these anti-patterns:

1. **Hard-coded waits** (`waitForTimeout`)
2. **Fragile selectors** (CSS classes, nth-child)
3. **Shared state** (global variables between tests)
4. **Missing await** (race conditions)
5. **No test isolation** (tests depend on each other)
6. **Testing implementation details** (internal state, private methods)
7. **Not using fixtures** (repeated setup code)
8. **Not mocking external services** (flaky tests)

### Refactoring Suggestions

When user has working but suboptimal code:

1. **Extract test utilities**:
   ```typescript
   // Before: Repeated code
   test('test 1', async ({ page, request }) => {
     const response = await request.post('/api/sessions', { ... });
     const session = await response.json();
   });

   // After: Utility function
   test('test 1', async ({ page, request }) => {
     const session = await createTestSession(request, { ... });
   });
   ```

2. **Use Page Object Model for complex pages**:
   ```typescript
   // Before: Inline selectors
   await page.getByLabel('Organization Name').fill('Acme');
   await page.getByRole('button', { name: 'Start Session' }).click();

   // After: Page object
   const workshopPage = new WorkshopPage(page);
   await workshopPage.startSession('Acme');
   ```

3. **Extract fixtures for common setup**:
   ```typescript
   // Before: Repeated authentication
   test('test 1', async ({ page }) => {
     await login(page);
     // ...
   });

   // After: Fixture
   test('test 1', async ({ authenticatedPage: page }) => {
     // Already logged in
   });
   ```

---

## Last Updated

2025-11-14

**Changelog:**

- Initial comprehensive KB created following v3.1 playbook
- Added 7-section structure: Purpose, Mental Model, Golden Path, Variations, Examples, Pitfalls, AI Notes
- Included 3-tier examples: Pedagogical, Realistic Synthetic, Framework Integration
- Added 8 common pitfalls with ❌ Wrong / ✅ Correct examples
- Integrated Bloom-specific patterns and conventions
- Added comprehensive query patterns for RAG system
- Included Next.js 16 integration examples
- Added debugging and troubleshooting guidance

**Related ADRs:**

- ADR-004: Next.js 16 Async Params Pattern (affects URL handling in tests)
- ADR-001: SQLite WAL Mode (affects database setup in tests)

**Version**: 3.1
**Profile**: Full
**Estimated Reading Time**: 25-30 minutes
**Target Audience**: Beginner to Intermediate Playwright users
