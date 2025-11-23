---
id: playwright-quick-reference
topic: playwright
file_role: quickref
profile: full
difficulty_level: all-levels
kb_version: 3.1
prerequisites: []
related_topics: [testing, e2e-testing]
embedding_keywords: [playwright, cheat-sheet, syntax, quick-reference, selectors, assertions]
last_reviewed: 2025-11-14
---

# Playwright Quick Reference

<!-- Query: "How do I select elements in Playwright?" -->
<!-- Query: "What are the best Playwright assertions?" -->
<!-- Query: "How to wait for elements in Playwright?" -->

## Purpose

This is the most-accessed file in the Playwright KB. Use it for quick syntax lookups, common patterns, and rapid problem-solving while coding tests.

## Installation & Setup

### Initial Installation

```bash
# Install Playwright
npm install -D @playwright/test

# Install browsers (Chromium, Firefox, WebKit)
npx playwright install

# Install system dependencies (Linux/Ubuntu)
npx playwright install-deps

# Verify installation
npx playwright --version
```

### Project Initialization

```bash
# Initialize Playwright in existing project
npm init playwright@latest

# This creates:
# - playwright.config.ts
# - tests/ directory
# - tests-examples/ directory
# - .github/workflows/playwright.yml (optional)
```

### Bloom Project Setup

```bash
# In Bloom project
cd /home/user/bloom

# Install (if not already installed)
npm install -D @playwright/test@1.56.1

# Run tests
npm run test:e2e

# Or directly
npx playwright test
```

---

## Basic Test Structure

### Minimal Test

```typescript
import { test, expect } from '@playwright/test';

test('basic test', async ({ page }) => {
  await page.goto('https://example.com');
  await expect(page).toHaveTitle(/Example/);
});
```

### Test with Describe Block

```typescript
import { test, expect } from '@playwright/test';

test.describe('Feature: User Login', () => {
  test('should allow valid login', async ({ page }) => {
    await page.goto('/login');
    await page.getByLabel('Email').fill('user@example.com');
    await page.getByLabel('Password').fill('password123');
    await page.getByRole('button', { name: 'Login' }).click();

    await expect(page).toHaveURL('/dashboard');
  });

  test('should reject invalid credentials', async ({ page }) => {
    await page.goto('/login');
    await page.getByLabel('Email').fill('bad@example.com');
    await page.getByLabel('Password').fill('wrong');
    await page.getByRole('button', { name: 'Login' }).click();

    await expect(page.getByText('Invalid credentials')).toBeVisible();
  });
});
```

### Test with Hooks

```typescript
test.describe('Dashboard Tests', () => {
  test.beforeAll(async () => {
    // Runs once before all tests in this describe block
    console.log('Setting up test suite');
  });

  test.afterAll(async () => {
    // Runs once after all tests in this describe block
    console.log('Tearing down test suite');
  });

  test.beforeEach(async ({ page }) => {
    // Runs before each test
    await page.goto('/dashboard');
  });

  test.afterEach(async ({ page }) => {
    // Runs after each test
    await page.close();
  });

  test('test 1', async ({ page }) => {
    // Test code
  });

  test('test 2', async ({ page }) => {
    // Test code
  });
});
```

---

## Navigation

### Basic Navigation

```typescript
// Navigate to URL
await page.goto('https://example.com');
await page.goto('/relative/path');

// Navigate with options
await page.goto('https://example.com', {
  waitUntil: 'networkidle', // 'load' | 'domcontentloaded' | 'networkidle'
  timeout: 30000,
});

// Back and forward
await page.goBack();
await page.goForward();

// Reload
await page.reload();
await page.reload({ waitUntil: 'networkidle' });
```

### Wait for Navigation

```typescript
// Wait for URL
await page.waitForURL('**/dashboard');
await page.waitForURL(/.*dashboard.*/);
await page.waitForURL('http://localhost:3001/dashboard', {
  timeout: 5000,
});

// Wait for load state
await page.waitForLoadState('load');
await page.waitForLoadState('domcontentloaded');
await page.waitForLoadState('networkidle');

// Navigate and wait
const [response] = await Promise.all([
  page.waitForNavigation(),
  page.click('a[href="/next-page"]'),
]);
```

### Multi-Page Navigation

```typescript
test('open new tab', async ({ context, page }) => {
  // Click link that opens new tab
  const [newPage] = await Promise.all([
    context.waitForEvent('page'),
    page.click('a[target="_blank"]'),
  ]);

  // Work with new page
  await newPage.waitForLoadState();
  expect(newPage.url()).toContain('new-page');

  // Close new page
  await newPage.close();
});
```

---

## Selectors & Locators

### Locator Hierarchy (Best Practices)

```typescript
// ✅ 1. Role-based (MOST RESILIENT)
page.getByRole('button', { name: 'Submit' })
page.getByRole('heading', { name: 'Dashboard' })
page.getByRole('link', { name: 'Learn more' })
page.getByRole('textbox', { name: 'Username' })
page.getByRole('checkbox', { name: 'Accept terms' })
page.getByRole('radio', { name: 'Option A' })
page.getByRole('listitem')
page.getByRole('row')
page.getByRole('cell')

// With level (for headings)
page.getByRole('heading', { level: 1 })

// With pressed/checked state
page.getByRole('button', { name: 'Menu', pressed: true })
page.getByRole('checkbox', { checked: true })

// ✅ 2. Text content
page.getByText('Welcome')
page.getByText('Sign In', { exact: true })
page.getByText(/sign [Ii]n/) // Case-insensitive regex
page.getByText('Welcome', { exact: false }) // Partial match

// ✅ 3. Labels (for form fields)
page.getByLabel('Email address')
page.getByLabel('Password')
page.getByLabel(/email/i)

// ✅ 4. Placeholders
page.getByPlaceholder('Enter your email')
page.getByPlaceholder(/username/i)

// ✅ 5. Alt text (for images)
page.getByAltText('Product photo')
page.getByAltText(/screenshot/i)

// ✅ 6. Title attributes
page.getByTitle('Close')
page.getByTitle(/tooltip/i)

// ✅ 7. Test IDs (explicit test contract)
page.getByTestId('submit-button')
page.getByTestId('user-profile')

// ⚠️ Use sparingly: CSS selectors
page.locator('.class-name')
page.locator('#id')
page.locator('button.primary')
page.locator('[data-custom="value"]')

// ⚠️ Use sparingly: XPath
page.locator('xpath=//button[@type="submit"]')
page.locator('xpath=//div[contains(@class, "modal")]')

// ❌ AVOID: Brittle selectors
page.locator('div > div > button:nth-child(3)')
page.locator('body > div.container > form > div:nth-of-type(2)')
```

### Locator Chaining

```typescript
// Filter by text
const submitButton = page.getByRole('button').filter({ hasText: 'Submit' });

// Filter by another locator
const activeItem = page.locator('.item').filter({
  has: page.locator('.status.active'),
});

// Get by nth
const firstButton = page.getByRole('button').first();
const lastButton = page.getByRole('button').last();
const secondButton = page.getByRole('button').nth(1); // 0-indexed

// Count
const buttonCount = await page.getByRole('button').count();

// All
const allButtons = await page.getByRole('button').all();
for (const button of allButtons) {
  console.log(await button.textContent());
}
```

### Locator Scoping

```typescript
// Scope to parent element
const form = page.locator('form#login');
await form.getByLabel('Email').fill('user@example.com');
await form.getByLabel('Password').fill('password');
await form.getByRole('button', { name: 'Submit' }).click();

// Multiple levels
const modal = page.locator('[role="dialog"]');
const modalForm = modal.locator('form');
await modalForm.getByLabel('Name').fill('John Doe');
```

### Locator Filters

```typescript
// Has text
page.getByRole('listitem').filter({ hasText: 'Active' });

// Has element
page.getByRole('listitem').filter({
  has: page.locator('.status-indicator.active'),
});

// Has not text
page.getByRole('listitem').filter({ hasNotText: 'Inactive' });

// Combining filters
page.getByRole('listitem')
  .filter({ hasText: 'Product' })
  .filter({ has: page.locator('.in-stock') })
  .first();
```

---

## Interactions

### Click

```typescript
// Basic click
await page.getByRole('button').click();
await page.click('.submit-btn');

// Click with options
await page.click('.button', {
  button: 'right', // 'left' | 'right' | 'middle'
  clickCount: 2, // Double-click
  delay: 100, // ms between mousedown and mouseup
  position: { x: 10, y: 10 }, // Click offset
  modifiers: ['Shift'], // 'Alt' | 'Control' | 'Meta' | 'Shift'
  force: true, // Skip actionability checks
  timeout: 5000,
});

// Click on specific coordinates
await page.mouse.click(100, 200);

// Click and wait for navigation
await Promise.all([
  page.waitForNavigation(),
  page.click('a[href="/next-page"]'),
]);
```

### Type & Fill

```typescript
// Fill (clears then types)
await page.getByLabel('Email').fill('user@example.com');
await page.fill('input[name="email"]', 'user@example.com');

// Type (types without clearing)
await page.getByLabel('Search').type('playwright testing');

// Type with delay (simulates human typing)
await page.type('input', 'slow typing', { delay: 100 });

// Clear field
await page.getByLabel('Email').clear();
await page.fill('input', ''); // Alternative

// Press keys
await page.getByLabel('Search').press('Enter');
await page.press('input', 'Control+A');
await page.press('input', 'Backspace');

// Type special characters
await page.keyboard.type('Hello!');
await page.keyboard.press('Tab');
await page.keyboard.press('Shift+Tab');
```

### Select

```typescript
// Select by value
await page.selectOption('select#country', 'us');

// Select by label
await page.selectOption('select#country', { label: 'United States' });

// Select by index
await page.selectOption('select', { index: 2 });

// Select multiple
await page.selectOption('select[multiple]', ['us', 'uk', 'ca']);

// Get selected value
const value = await page.locator('select').inputValue();
```

### Checkbox & Radio

```typescript
// Check
await page.getByLabel('Accept terms').check();
await page.check('input[type="checkbox"]');

// Uncheck
await page.getByLabel('Newsletter').uncheck();
await page.uncheck('input[type="checkbox"]');

// Set checked state
await page.getByLabel('Agree').setChecked(true);
await page.setChecked('input', false);

// Check if checked
const isChecked = await page.getByLabel('Terms').isChecked();

// Radio buttons
await page.getByLabel('Option A').check();
```

### Hover

```typescript
// Hover over element
await page.getByRole('button').hover();
await page.hover('.menu-item');

// Hover with position
await page.hover('.element', { position: { x: 10, y: 10 } });

// Hover and wait for tooltip
await page.hover('.info-icon');
await expect(page.getByRole('tooltip')).toBeVisible();
```

### Drag & Drop

```typescript
// Drag and drop
await page.dragAndDrop('#source', '#target');

// Drag and drop with position
await page.dragAndDrop('#source', '#target', {
  sourcePosition: { x: 0, y: 0 },
  targetPosition: { x: 100, y: 100 },
});

// Manual drag
await page.locator('#source').hover();
await page.mouse.down();
await page.locator('#target').hover();
await page.mouse.up();
```

### Upload Files

```typescript
// Single file
await page.setInputFiles('input[type="file"]', 'path/to/file.pdf');

// Multiple files
await page.setInputFiles('input[type="file"]', [
  'file1.pdf',
  'file2.pdf',
]);

// From buffer
await page.setInputFiles('input[type="file"]', {
  name: 'test.txt',
  mimeType: 'text/plain',
  buffer: Buffer.from('file content'),
});

// Remove files
await page.setInputFiles('input[type="file"]', []);
```

### Focus

```typescript
// Focus element
await page.getByLabel('Email').focus();
await page.focus('input');

// Check if focused
const isFocused = await page.locator('input').isFocused();

// Blur (remove focus)
await page.locator('input').blur();
```

---

## Assertions

### Page Assertions

```typescript
// Title
await expect(page).toHaveTitle('Dashboard');
await expect(page).toHaveTitle(/Dashboard/);

// URL
await expect(page).toHaveURL('http://localhost:3001/dashboard');
await expect(page).toHaveURL(/\/dashboard/);
await expect(page).toHaveURL('**/dashboard');

// Current URL (non-assertion)
expect(page.url()).toBe('http://localhost:3001/');
expect(page.url()).toContain('/dashboard');
```

### Element Visibility

```typescript
// Visible
await expect(page.getByText('Welcome')).toBeVisible();
await expect(page.locator('.modal')).toBeVisible();

// Hidden
await expect(page.getByText('Loading...')).toBeHidden();
await expect(page.locator('.spinner')).not.toBeVisible();

// Check visibility without waiting
const isVisible = await page.locator('.element').isVisible();
```

### Element State

```typescript
// Enabled
await expect(page.getByRole('button')).toBeEnabled();

// Disabled
await expect(page.getByRole('button')).toBeDisabled();

// Checked
await expect(page.getByLabel('Accept')).toBeChecked();
await expect(page.getByLabel('Reject')).not.toBeChecked();

// Focused
await expect(page.getByLabel('Email')).toBeFocused();

// Editable
await expect(page.locator('input')).toBeEditable();
await expect(page.locator('input[readonly]')).not.toBeEditable();

// Empty
await expect(page.locator('input')).toBeEmpty();
```

### Text & Content

```typescript
// Has text (exact match)
await expect(page.locator('h1')).toHaveText('Dashboard');

// Contains text (partial match)
await expect(page.locator('h1')).toContainText('Dash');

// Regex
await expect(page.locator('.count')).toHaveText(/\d+/);

// Multiple elements
await expect(page.locator('.item')).toHaveText(['Item 1', 'Item 2', 'Item 3']);

// Get text content
const text = await page.locator('h1').textContent();
expect(text).toBe('Dashboard');

// Inner text
const innerText = await page.locator('h1').innerText();
```

### Attributes

```typescript
// Has attribute
await expect(page.locator('img')).toHaveAttribute('alt', 'Logo');
await expect(page.locator('a')).toHaveAttribute('href', /\/dashboard/);

// Has class
await expect(page.locator('.item')).toHaveClass('active');
await expect(page.locator('.item')).toHaveClass(/active/);

// Has multiple classes
await expect(page.locator('.item')).toHaveClass(['item', 'active', 'selected']);

// Get attribute
const href = await page.locator('a').getAttribute('href');
expect(href).toBe('/dashboard');
```

### Values

```typescript
// Input value
await expect(page.getByLabel('Email')).toHaveValue('user@example.com');
await expect(page.locator('input')).toHaveValue(/.*@example\.com/);

// Get value
const value = await page.locator('input').inputValue();
expect(value).toBe('user@example.com');
```

### Count

```typescript
// Count elements
await expect(page.locator('.item')).toHaveCount(5);
await expect(page.getByRole('listitem')).toHaveCount(10);

// Get count
const count = await page.locator('.item').count();
expect(count).toBe(5);

// At least one
await expect(page.locator('.item').count()).toBeGreaterThan(0);
```

### Screenshots

```typescript
// Screenshot assertion (visual regression)
await expect(page).toHaveScreenshot('homepage.png');

// Element screenshot
await expect(page.locator('.widget')).toHaveScreenshot('widget.png');

// With options
await expect(page).toHaveScreenshot('page.png', {
  maxDiffPixels: 100,
  threshold: 0.2,
});
```

### Custom Matchers

```typescript
// Soft assertions (don't stop test on failure)
await expect.soft(page.locator('h1')).toHaveText('Title');
await expect.soft(page.locator('p')).toContainText('content');

// Poll until assertion passes
await expect.poll(async () => {
  const response = await page.request.get('/api/status');
  return response.status();
}).toBe(200);

// Negation
await expect(page.locator('.error')).not.toBeVisible();
```

---

## Waiting

### Auto-Waiting (Built-in)

Playwright automatically waits for elements to be actionable before performing actions:

```typescript
// These all auto-wait up to 30 seconds (default timeout)
await page.click('button'); // Waits for: attached, visible, enabled, stable
await page.fill('input', 'text'); // Waits for: attached, visible, enabled
await expect(element).toBeVisible(); // Waits and retries
```

### Explicit Waits

```typescript
// Wait for selector
await page.waitForSelector('.element');
await page.waitForSelector('.element', { state: 'attached' }); // 'attached' | 'detached' | 'visible' | 'hidden'

// Wait for URL
await page.waitForURL('**/dashboard');
await page.waitForURL(/dashboard/);

// Wait for load state
await page.waitForLoadState(); // Default: 'load'
await page.waitForLoadState('domcontentloaded');
await page.waitForLoadState('networkidle'); // No network activity for 500ms

// Wait for function
await page.waitForFunction(() => window.innerWidth < 768);
await page.waitForFunction(() => document.querySelector('.done'));

// Wait for timeout (AVOID - use only as last resort)
await page.waitForTimeout(1000); // Wait 1 second
```

### Network Waits

```typescript
// Wait for response
const responsePromise = page.waitForResponse('**/api/data');
await page.click('button');
const response = await responsePromise;
expect(response.status()).toBe(200);

// Wait for request
const requestPromise = page.waitForRequest('**/api/save');
await page.click('button');
const request = await requestPromise;

// Wait for response with predicate
const response = await page.waitForResponse(
  res => res.url().includes('/api/') && res.status() === 200
);

// Wait for multiple responses
const [response1, response2] = await Promise.all([
  page.waitForResponse('**/api/users'),
  page.waitForResponse('**/api/posts'),
  page.click('button'),
]);
```

### Element Waits

```typescript
// Wait for element to be visible
await page.locator('.element').waitFor({ state: 'visible' });

// Wait for element to be hidden
await page.locator('.spinner').waitFor({ state: 'hidden' });

// Wait for element to be attached
await page.locator('.dynamic').waitFor({ state: 'attached' });

// Wait for element to be detached
await page.locator('.removed').waitFor({ state: 'detached' });
```

---

## Network

### Intercept Requests

```typescript
// Listen to all requests
page.on('request', request => {
  console.log('>>', request.method(), request.url());
});

// Listen to all responses
page.on('response', response => {
  console.log('<<', response.status(), response.url());
});

// Listen to request failures
page.on('requestfailed', request => {
  console.log('Failed:', request.url());
});
```

### Mock/Route Requests

```typescript
// Mock API response
await page.route('**/api/users', route => {
  route.fulfill({
    status: 200,
    contentType: 'application/json',
    body: JSON.stringify({ users: [{ id: 1, name: 'John' }] }),
  });
});

// Mock from file
await page.route('**/api/data', route => {
  route.fulfill({
    path: 'mocks/data.json',
  });
});

// Abort request
await page.route('**/*.{png,jpg,jpeg}', route => route.abort());

// Continue with modifications
await page.route('**/api/**', route => {
  route.continue({
    headers: {
      ...route.request().headers(),
      'Authorization': 'Bearer token',
    },
  });
});

// Unroute
await page.unroute('**/api/users');
```

### API Testing (Request Context)

```typescript
test('API test', async ({ request }) => {
  // GET request
  const response = await request.get('/api/users');
  expect(response.ok()).toBeTruthy();
  const data = await response.json();
  expect(data).toHaveProperty('users');

  // POST request
  const createResponse = await request.post('/api/users', {
    data: { name: 'John', email: 'john@example.com' },
  });
  expect(createResponse.status()).toBe(201);

  // PUT request
  await request.put('/api/users/1', {
    data: { name: 'Jane' },
  });

  // DELETE request
  await request.delete('/api/users/1');

  // With headers
  await request.get('/api/protected', {
    headers: {
      'Authorization': 'Bearer token',
    },
  });
});
```

---

## Multiple Elements

### Iterate Over Elements

```typescript
// Get all elements
const items = page.locator('.item');
const count = await items.count();

// Iterate with for loop
for (let i = 0; i < count; i++) {
  const item = items.nth(i);
  const text = await item.textContent();
  console.log(text);
}

// Get all at once
const allItems = await items.all();
for (const item of allItems) {
  await item.click();
}

// Get all text contents
const texts = await items.allTextContents();
console.log(texts); // ['Item 1', 'Item 2', ...]
```

### Filter Elements

```typescript
// Filter by text
const activeItems = page.locator('.item').filter({ hasText: 'Active' });

// Filter by another locator
const completedTasks = page.locator('.task').filter({
  has: page.locator('.status.completed'),
});

// Multiple filters
const result = page.locator('.item')
  .filter({ hasText: 'Product' })
  .filter({ has: page.locator('.in-stock') })
  .first();
```

### Get Specific Elements

```typescript
// First element
const first = page.locator('.item').first();

// Last element
const last = page.locator('.item').last();

// Nth element (0-indexed)
const second = page.locator('.item').nth(1);
const third = page.locator('.item').nth(2);

// Check if element exists
const count = await page.locator('.item').count();
if (count > 0) {
  await page.locator('.item').first().click();
}
```

---

## Fixtures

### Built-in Fixtures

```typescript
// Page fixture
test('test with page', async ({ page }) => {
  await page.goto('/');
});

// Context fixture
test('test with context', async ({ context }) => {
  const page = await context.newPage();
  await page.goto('/');
});

// Browser fixture
test('test with browser', async ({ browser }) => {
  const context = await browser.newContext();
  const page = await context.newPage();
  await page.goto('/');
});

// Request fixture (API testing)
test('API test', async ({ request }) => {
  const response = await request.get('/api/users');
});

// Browser name
test('browser-specific test', async ({ browserName }) => {
  test.skip(browserName === 'webkit', 'Not supported in WebKit');
});
```

### Custom Fixtures

```typescript
// Define custom fixture
import { test as base } from '@playwright/test';

type MyFixtures = {
  todoPage: TodoPage;
};

export const test = base.extend<MyFixtures>({
  todoPage: async ({ page }, use) => {
    const todoPage = new TodoPage(page);
    await todoPage.goto();
    await use(todoPage);
    // Cleanup code here
  },
});

export { expect } from '@playwright/test';
```

### Using Custom Fixtures

```typescript
import { test, expect } from './fixtures';

test('use custom fixture', async ({ todoPage }) => {
  await todoPage.addTodo('Buy milk');
  await expect(todoPage.todos).toHaveCount(1);
});
```

---

## Hooks

### Test Hooks

```typescript
test.beforeAll(async () => {
  // Runs once before all tests in the file
  console.log('Setup test suite');
});

test.afterAll(async () => {
  // Runs once after all tests in the file
  console.log('Cleanup test suite');
});

test.beforeEach(async ({ page }) => {
  // Runs before each test
  await page.goto('/');
});

test.afterEach(async ({ page }) => {
  // Runs after each test
  // Cleanup happens automatically, but you can add custom cleanup
});
```

### Describe Hooks

```typescript
test.describe('Feature Suite', () => {
  test.beforeAll(async () => {
    // Runs once before all tests in this describe block
  });

  test.afterAll(async () => {
    // Runs once after all tests in this describe block
  });

  test.beforeEach(async ({ page }) => {
    // Runs before each test in this describe block
  });

  test.afterEach(async () => {
    // Runs after each test in this describe block
  });

  test('test 1', async ({ page }) => {});
  test('test 2', async ({ page }) => {});
});
```

---

## Test Organization

### Basic Organization

```typescript
// Group tests
test.describe('Login Feature', () => {
  test('valid login', async ({ page }) => {});
  test('invalid login', async ({ page }) => {});
});

// Nested groups
test.describe('User Management', () => {
  test.describe('Create User', () => {
    test('with valid data', async ({ page }) => {});
    test('with invalid data', async ({ page }) => {});
  });

  test.describe('Delete User', () => {
    test('existing user', async ({ page }) => {});
    test('non-existent user', async ({ page }) => {});
  });
});
```

### Test Annotations

```typescript
// Skip test
test.skip('not implemented yet', async ({ page }) => {});

// Skip conditionally
test('conditional skip', async ({ page, browserName }) => {
  test.skip(browserName === 'webkit', 'Not supported in WebKit');
  // Test code
});

// Only run this test
test.only('focused test', async ({ page }) => {});

// Mark as fixme (skipped in test list)
test.fixme('known bug', async ({ page }) => {});

// Mark as slow (3x timeout)
test.slow('slow test', async ({ page }) => {
  // Test code
});

// Conditional slow
test('conditional slow', async ({ page }) => {
  test.slow(process.env.CI === 'true');
  // Test code
});

// Fail test (expect it to fail)
test.fail('known failure', async ({ page }) => {});
```

### Tagging Tests

```typescript
// Tag with describe
test.describe('@smoke', () => {
  test('critical test 1', async ({ page }) => {});
  test('critical test 2', async ({ page }) => {});
});

// Run tagged tests
// npx playwright test --grep @smoke
// npx playwright test --grep-invert @slow
```

---

## Screenshots & Videos

### Screenshots

```typescript
// Full page screenshot
await page.screenshot({ path: 'screenshot.png' });

// Element screenshot
await page.locator('.header').screenshot({ path: 'header.png' });

// Full page (including scrolled content)
await page.screenshot({ path: 'full.png', fullPage: true });

// Screenshot to buffer
const buffer = await page.screenshot();

// Screenshot with options
await page.screenshot({
  path: 'screenshot.png',
  fullPage: true,
  type: 'jpeg',
  quality: 80,
});
```

### Automatic Screenshots

```typescript
// Configure in playwright.config.ts
export default defineConfig({
  use: {
    screenshot: 'only-on-failure', // 'off' | 'on' | 'only-on-failure'
  },
});
```

### Videos

```typescript
// Configure in playwright.config.ts
export default defineConfig({
  use: {
    video: 'retain-on-failure', // 'off' | 'on' | 'retain-on-failure' | 'on-first-retry'
  },
});

// Get video path in test
test('test with video', async ({ page }, testInfo) => {
  await page.goto('/');
  // Test code
  const videoPath = await page.video()?.path();
  console.log('Video saved to:', videoPath);
});
```

---

## Authentication

### Save Auth State

```typescript
// global-setup.ts
import { chromium, FullConfig } from '@playwright/test';

async function globalSetup(config: FullConfig) {
  const browser = await chromium.launch();
  const page = await browser.newPage();

  await page.goto('http://localhost:3001/login');
  await page.getByLabel('Email').fill('user@example.com');
  await page.getByLabel('Password').fill('password123');
  await page.getByRole('button', { name: 'Login' }).click();

  await page.waitForURL('**/dashboard');
  await page.context().storageState({ path: 'auth.json' });

  await browser.close();
}

export default globalSetup;
```

### Use Auth State

```typescript
// playwright.config.ts
export default defineConfig({
  use: {
    storageState: 'auth.json',
  },
  globalSetup: require.resolve('./global-setup'),
});

// Or per-test
test('authenticated test', async ({ browser }) => {
  const context = await browser.newContext({
    storageState: 'auth.json',
  });
  const page = await context.newPage();
  await page.goto('/dashboard');
});
```

### Multiple Auth States

```typescript
// fixtures.ts
export const test = base.extend({
  adminPage: async ({ browser }, use) => {
    const context = await browser.newContext({
      storageState: 'admin-auth.json',
    });
    const page = await context.newPage();
    await use(page);
    await context.close();
  },

  userPage: async ({ browser }, use) => {
    const context = await browser.newContext({
      storageState: 'user-auth.json',
    });
    const page = await context.newPage();
    await use(page);
    await context.close();
  },
});
```

---

## Configuration

### Basic Config (playwright.config.ts)

```typescript
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  timeout: 30 * 1000,
  expect: {
    timeout: 5000,
  },
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',

  use: {
    baseURL: 'http://localhost:3001',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },

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

  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3001',
    reuseExistingServer: !process.env.CI,
  },
});
```

### Bloom Project Config

```typescript
// playwright.config.ts
export default defineConfig({
  testDir: './e2e/specs',
  timeout: 30 * 1000,
  fullyParallel: false, // Sequential for SQLite
  workers: 1, // One worker for database safety
  retries: process.env.CI ? 2 : 0,

  reporter: [
    ['html', { outputFolder: '_build/test/reports/playwright-html' }],
    ['json', { outputFile: '_build/test/reports/playwright-json/results.json' }],
  ],

  use: {
    baseURL: 'http://localhost:3001',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    actionTimeout: 10000,
  },

  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
  ],

  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3001',
    reuseExistingServer: !process.env.CI,
    timeout: 120000,
  },
});
```

---

## Commands

### Run Tests

```bash
# Run all tests
npx playwright test

# Run specific file
npx playwright test tests/example.spec.ts

# Run tests matching pattern
npx playwright test tests/login

# Run in headed mode
npx playwright test --headed

# Run in debug mode
npx playwright test --debug

# Run with UI mode
npx playwright test --ui

# Run specific project
npx playwright test --project=chromium

# Run with grep
npx playwright test --grep @smoke
npx playwright test --grep-invert @slow

# Run with workers
npx playwright test --workers=4

# Update snapshots
npx playwright test --update-snapshots
```

### Reports & Debugging

```bash
# Show HTML report
npx playwright show-report

# Show trace viewer
npx playwright show-trace trace.zip

# Generate trace
npx playwright test --trace on

# Codegen (record tests)
npx playwright codegen http://localhost:3001

# Codegen with auth
npx playwright codegen --load-storage=auth.json http://localhost:3001
```

### Installation

```bash
# Install Playwright
npm install -D @playwright/test

# Install browsers
npx playwright install

# Install system dependencies
npx playwright install-deps

# List browsers
npx playwright install --list
```

---

## AI Pair Programming Notes

### When to Load This File

Load `QUICK-REFERENCE.md` when:
- Writing new tests and need syntax reminder
- Looking up specific Playwright API
- Debugging test failures
- Need quick examples

### Combine With

- **01-FUNDAMENTALS.md**: For deeper understanding of concepts
- **FRAMEWORK-INTEGRATION-PATTERNS.md**: For Next.js/Bloom-specific patterns
- **02-SELECTORS-LOCATORS.md**: For advanced selector strategies
- **03-INTERACTIONS-ASSERTIONS.md**: For complex interactions

### Common AI Prompts

```
"Using QUICK-REFERENCE.md, write a test that:
1. Navigates to /login
2. Fills email and password
3. Clicks submit
4. Asserts redirect to /dashboard"

"Reference QUICK-REFERENCE.md selectors section. Update this test to use
role-based selectors instead of CSS selectors."

"Using QUICK-REFERENCE.md network section, mock the /api/users endpoint
to return an empty array."
```

### What to Avoid

- **Hard-coded waits**: Use `expect()` assertions instead of `waitForTimeout()`
- **Brittle selectors**: Prefer role-based and semantic selectors
- **No assertions**: Always include assertions to verify behavior
- **Flaky tests**: Use auto-waiting and web-first assertions

---

## Related Files

- **[01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md)**: Core concepts and mental models
- **[FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md)**: Real-world patterns
- **[02-SELECTORS-LOCATORS.md](./02-SELECTORS-LOCATORS.md)**: Advanced selectors
- **[03-INTERACTIONS-ASSERTIONS.md](./03-INTERACTIONS-ASSERTIONS.md)**: Detailed interactions
- **[README.md](./README.md)**: Overview and getting started
- **[INDEX.md](./INDEX.md)**: Full table of contents

---

## Last Updated

2025-11-14
