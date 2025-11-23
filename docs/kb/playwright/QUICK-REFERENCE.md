---
id: playwright-quick-reference
topic: playwright
file_role: quickref
profile: full
difficulty_level: all-levels
kb_version: 3.1
prerequisites: ['javascript', 'testing-basics']
related_topics: ['testing', 'e2e', 'automation']
embedding_keywords: [playwright, quick-reference, cheat-sheet, syntax]
last_reviewed: 2025-11-13
---

# Playwright Quick Reference Card

**For fast lookup while writing tests**

## Installation (One-Time Setup)

```bash
npm install -D @playwright/test # Install Playwright
npx playwright install --with-deps # Install browsers + dependencies
npx playwright codegen http://localhost:3001 # Auto-generate tests
```

---

## Running Tests

| Command | Purpose |
|---------|---------|
| `npm run test:e2e` | Run all tests headless |
| `npx playwright test --headed` | Run with visible browser |
| `npx playwright test --debug` | Interactive debugging |
| `npx playwright test --ui` | Watch mode with UI |
| `npx playwright test -g "test name"` | Run specific test |
| `npx playwright test e2e/specs/chat.spec.ts` | Run specific file |
| `npx playwright test --workers=1` | Run sequentially |
| `npx playwright test --project=firefox` | Test specific browser |
| `npx playwright test --trace on` | Record execution traces |
| `npx playwright show-trace trace.zip` | View trace in viewer |

---

## Locators (Element Selection)

### Best Practices (Most to Least Resilient)

```typescript
// ✅ 1. Role-based (most resilient)
page.getByRole('button', { name: 'Submit' })
page.getByRole('heading', { level: 1 })
page.getByRole('link', { name: /sign in/i })

// ✅ 2. Text content
page.getByText('Welcome')
page.getByText(/sign [Ii]n/)

// ✅ 3. Form labels
page.getByLabel('Email address')

// ✅ 4. Placeholders
page.getByPlaceholder('user@example.com')

// ✅ 5. Alt text
page.getByAltText('Product image')

// ✅ 6. Test IDs (explicit contract)
page.getByTestId('submit-button')

// ❌ Avoid: Brittle selectors
page.locator('.form > div:nth-child(2) > button')
page.locator('xpath=//button[@id="submit"]')
```

### Filtering & Chaining

```typescript
// Filter by text
page.locator('tr').filter({ hasText: 'John' })

// Chain locators
page.getByRole('dialog').getByRole('button')

// Multiple conditions
page.locator('input').and(page.locator('[required]'))

// Alternative selectors
page.locator('button:has-text("Save")').or(page.locator('button:has-text("Update")'))

// Count matching
await page.locator('tr').count
```

---

## Basic Test Structure

```typescript
import { test, expect } from '@playwright/test';

test.describe('Feature', => {
 test.beforeEach(async ({ page }) => {
 // Setup before each test
 await page.goto('/');
 });

 test('should do something', async ({ page }) => {
 // Arrange
 const element = page.getByRole('button', { name: 'Click' });

 // Act
 await element.click;

 // Assert
 await expect(page.locator('.result')).toContainText('Success');
 });

 test('another test', async ({ page }) => {
 // Tests run independently
 });
});
```

---

## Common Actions

```typescript
// Navigation
await page.goto('/path')
await page.goBack
await page.goForward
await page.reload

// Clicks
await page.click('button')
await element.click
await page.dblclick('button')
await page.rightClick('button')

// Text input
await page.fill('input[type=email]', 'user@example.com')
await element.type('hello', { delay: 100 })
await element.clear

// Select dropdown
await page.selectOption('select', 'option-value')

// File upload
await page.setInputFiles('input[type=file]', './file.pdf')

// Keyboard
await page.press('Enter')
await page.keyboard.press('ArrowDown')
await page.keyboard.type('Hello')

// Hover
await element.hover

// Drag and drop
await source.dragTo(target)

// Scroll
await page.evaluate( => window.scrollTo(0, document.body.scrollHeight))
```

---

## Waiting & Assertions

### Wait For Conditions

```typescript
// Wait for element visible
await page.waitForSelector('.element')

// Wait for function
await page.waitForFunction( => document.querySelectorAll('tr').length > 0)

// Wait for navigation
await Promise.all([
 page.waitForNavigation,
 page.click('a'),
])

// Wait for network
await page.waitForLoadState('networkidle')
await page.waitForLoadState('domcontentloaded')

// Wait for response
const response = await page.waitForResponse('**/api/data')

// Wait for timeout
await page.waitForTimeout(1000) // ⚠️ Avoid hard waits!
```

### Web-First Assertions (Auto-Wait)

```typescript
// Visibility
await expect(element).toBeVisible
await expect(element).toBeHidden

// Text content
await expect(element).toContainText('text')
await expect(element).toHaveText('exact text')

// Value
await expect(input).toHaveValue('john')

// Attributes
await expect(button).toBeEnabled
await expect(button).toBeDisabled
await expect(element).toHaveClass('active')
await expect(element).toHaveAttribute('href', '/path')

// Count
await expect(page.locator('tr')).toHaveCount(3)

// Title & URL
await expect(page).toHaveTitle('Page Title')
await expect(page).toHaveURL('/path')
```

---

## Page Objects Pattern

```typescript
// e2e/helpers/page-objects/LoginPage.ts
import { Page, Locator } from '@playwright/test';

export class LoginPage {
 readonly page: Page;
 readonly emailInput: Locator;
 readonly passwordInput: Locator;
 readonly submitButton: Locator;

 constructor(page: Page) {
 this.page = page;
 this.emailInput = page.getByLabel('Email');
 this.passwordInput = page.getByLabel('Password');
 this.submitButton = page.getByRole('button', { name: 'Login' });
 }

 async goto {
 await this.page.goto('/login');
 }

 async login(email: string, password: string) {
 await this.emailInput.fill(email);
 await this.passwordInput.fill(password);
 await this.submitButton.click;
 }
}

// Usage in test
import { test, expect } from '@playwright/test';
import { LoginPage } from './page-objects/LoginPage';

test('should login successfully', async ({ page }) => {
 const loginPage = new LoginPage(page);
 await loginPage.goto;
 await loginPage.login('user@example.com', 'password');
 await expect(page).toHaveURL('/dashboard');
});
```

---

## Fixtures (Test Dependencies)

```typescript
import { test as base, expect } from '@playwright/test';
import { LoginPage } from './helpers/page-objects/LoginPage';

// Define custom fixtures
type TestFixtures = {
 loginPage: LoginPage;
 authenticatedPage: Page;
};

export const test = base.extend<TestFixtures>({
 loginPage: async ({ page }, use) => {
 const loginPage = new LoginPage(page);
 await use(loginPage);
 // Cleanup
 },

 authenticatedPage: async ({ page }, use) => {
 await page.goto('/login');
 await page.getByLabel('Email').fill('user@example.com');
 await page.getByLabel('Password').fill('password');
 await page.getByRole('button', { name: 'Login' }).click;
 await page.waitForURL('/dashboard');
 await use(page);
 },
});

export { expect };

// Usage
import { test, expect } from './fixtures';

test('access dashboard', async ({ authenticatedPage }) => {
 // Already logged in!
 await expect(authenticatedPage).toHaveURL('/dashboard');
});
```

---

## API Mocking & Interception

```typescript
// Mock response
await page.route('**/api/users', (route) => {
 route.fulfill({
 status: 200,
 contentType: 'application/json',
 body: JSON.stringify([{ id: 1, name: 'John' }]),
 });
});

// Modify request
await page.route('**/api/**', (route) => {
 const request = route.request;
 route.continue({
 headers: {...request.headers, 'X-Custom': 'value' },
 });
});

// Abort request
await page.route('**/analytics', (route) => {
 route.abort;
});

// Conditional mocking
await page.route('**/api/data', (route) => {
 if (route.request.method === 'GET') {
 route.fulfill({ status: 200, body: '[]' });
 } else {
 route.continue;
 }
});

// Log all requests
page.on('request', (request) => {
 console.log('>> ', request.method, request.url);
});

// Wait for specific response
const responsePromise = page.waitForResponse('**/api/users');
await page.click('button');
const response = await responsePromise;
const data = await response.json;
```

---

## Debugging

```bash
# Enable all debug logs
DEBUG=pw:* npm run test:e2e

# Debug specific area
DEBUG=pw:api npm run test:e2e
DEBUG=pw:browser npm run test:e2e

# Save to file
DEBUG=pw:* npm run test:e2e > debug.log 2>&1

# Interactive debugging
npx playwright test --debug

# Trace viewer (after test)
npx playwright show-trace trace.zip

# Screenshots
npx playwright test --screenshot on

# Videos
npx playwright test --video on
```

---

## Configuration Essentials

```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
 testDir: './e2e/specs',
 testMatch: '**/*.spec.ts',
 fullyParallel: true,
 workers: process.env.CI ? 1: undefined,
 retries: process.env.CI ? 2: 0,
 timeout: 30 * 1000,

 use: {
 baseURL: 'http://localhost:3001',
 headless: true,
 trace: 'on-first-retry',
 screenshot: 'only-on-failure',
 video: 'retain-on-failure',
 },

 webServer: {
 command: 'npm run dev',
 url: 'http://localhost:3001',
 reuseExistingServer: !process.env.CI,
 },

 projects: [
 { name: 'chromium', use: {...devices['Desktop Chrome'] } },
 { name: 'firefox', use: {...devices['Desktop Firefox'] } },
 ],
});
```

---

## Best Practices Checklist

- [ ] Use semantic locators: `getByRole`, `getByText`
- [ ] Avoid hard waits: `await page.waitForTimeout`
- [ ] Use web-first assertions: `await expect`
- [ ] Keep tests isolated: No shared state
- [ ] One assertion per test: Focus on single behavior
- [ ] Mock external APIs: Don't test third-party
- [ ] Use page objects: Encapsulate selectors
- [ ] Use fixtures: Share test setup
- [ ] Test user interactions: Not implementation details
- [ ] Run tests frequently: Catch regressions early

---

## Common Pitfalls

| ❌ Problem | ✅ Solution |
|-----------|-----------|
| Tests randomly fail | Use explicit waits: `await expect.toBeVisible` |
| Hard to find elements | Use role-based locators: `getByRole('button')` |
| Tests interfere with each other | Isolate state in `beforeEach` |
| Tests are slow | Mock external APIs, parallel workers |
| Memory leaks in long runs | Set memory limit: `--max-old-space-size=4096` |
| SQLite lock errors | Set `workers: 1` for database tests |
| Flaky assertions | Use auto-waiting assertions, not `.isVisible` |

---

## Framework-Specific Quick Tips

```typescript
// Test workshop session
const sessionId = await page.locator('[data-testid="session-id"]').textContent;

// Mock Melissa response
await page.route('**/api/melissa/chat', (route) => {
 route.fulfill({
 status: 200,
 body: JSON.stringify({
 response: 'Test response from Melissa',
 confidence: 0.85,
 }),
 });
});

// Wait for ROI report
await expect(page.locator('[data-testid="roi-report"]')).toBeVisible;

// Export report
const downloadPromise = page.context.waitForEvent('download');
await page.click('[data-testid="export-pdf"]');
const download = await downloadPromise;

// Test database operations (single worker!)
npx playwright test --workers=1
```

---

## Resources

- 📖 [Full Playwright Guide](./PLAYWRIGHT-COMPREHENSIVE-GUIDE.md)
- 🌸 [Framework-Specific Patterns](./FRAMEWORK-INTEGRATION-PATTERNS.md)
- 🔗 [Official Docs](https://playwright.dev/docs/intro)
- 🎬 <!-- Build report link (generated at runtime) -->

---

**Print this card or pin it to your desk!**

Last Updated: November 8, 2025
