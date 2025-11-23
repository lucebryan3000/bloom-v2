---
id: playwright-patterns
topic: playwright
file_role: patterns
profile: full
difficulty_level: intermediate-advanced
kb_version: 3.1
prerequisites: [playwright-basics, javascript, typescript]
related_topics: [testing, nextjs, react]
embedding_keywords: [patterns, examples, integration, best-practices, testing-patterns]
last_reviewed: 2025-11-13
---

# Playwright Framework Integration Patterns

**Purpose**: Production-ready Playwright testing patterns and integration examples.

> **Note**: For project-specific patterns, see [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md)

---

## 📋 Table of Contents

1. [Next.js Integration](#nextjs-integration)
2. [React Component Testing](#react-component-testing)
3. [API Testing Patterns](#api-testing-patterns)
4. [Database Isolation](#database-isolation)
5. [CI/CD Integration](#cicd-integration)

---

## Next.js Integration

### Pattern 1: Testing Next.js Pages

```typescript
import { test, expect } from '@playwright/test';

test('homepage loads correctly', async ({ page }) => {
 await page.goto('/');

 // Check server-rendered content
 await expect(page.locator('h1')).toContainText('Welcome');

 // Check client-side hydration
 await expect(page.locator('[data-testid="interactive-element"]')).toBeVisible;
});
```

### Pattern 2: Testing API Routes

```typescript
test('API route returns correct data', async ({ request }) => {
 const response = await request.get('/api/users');

 expect(response.ok).toBeTruthy;
 const data = await response.json;
 expect(data).toHaveProperty('users');
});
```

---

## React Component Testing

### Pattern 3: Testing Forms

```typescript
test('form submission works', async ({ page }) => {
 await page.goto('/contact');

 await page.fill('[name="name"]', 'John Doe');
 await page.fill('[name="email"]', 'john@example.com');
 await page.click('button[type="submit"]');

 await expect(page.locator('.success-message')).toBeVisible;
});
```

### Pattern 4: Testing State Updates

```typescript
test('counter increments', async ({ page }) => {
 await page.goto('/counter');

 const counter = page.locator('[data-testid="count"]');
 await expect(counter).toHaveText('0');

 await page.click('button:has-text("Increment")');
 await expect(counter).toHaveText('1');
});
```

---

## API Testing Patterns

### Pattern 5: Mocking API Responses

```typescript
test('handles API errors gracefully', async ({ page }) => {
 await page.route('/api/data', route => {
 route.fulfill({
 status: 500,
 body: JSON.stringify({ error: 'Server error' })
 });
 });

 await page.goto('/dashboard');
 await expect(page.locator('.error-message')).toBeVisible;
});
```

### Pattern 6: Testing Authentication

```typescript
test('protected route redirects to login', async ({ page }) => {
 await page.goto('/dashboard');

 await page.waitForURL('/login');
 expect(page.url).toContain('/login');
});
```

---

## Database Isolation

### Pattern 7: Per-Test Database Setup

```typescript
import { test as base } from '@playwright/test';

export const test = base.extend({
 // Create isolated database per test
 isolatedDB: async ({}, use) => {
 const dbPath = `./test-dbs/${Date.now}.db`;
 // Setup database
 await use(dbPath);
 // Cleanup
 await fs.unlink(dbPath);
 }
});
```

---

## CI/CD Integration

### Pattern 8: GitHub Actions

```yaml
name: E2E Tests
on: [push, pull_request]

jobs:
 test:
 runs-on: ubuntu-latest
 steps:
 - uses: actions/checkout@v3
 - uses: actions/setup-node@v3
 - run: npm ci
 - run: npx playwright install --with-deps
 - run: npm run test:e2e
- uses: actions/upload-artifact@v3
 if: always
 with:
 name: playwright-report
 path: _build/test/reports/playwright-html/
```

---

## Best Practices

1. **Use Data Test IDs**: Prefer `data-testid` over CSS selectors
2. **Isolate Tests**: Each test should be independent
3. **Use Fixtures**: Share setup logic via Playwright fixtures
4. **Mock External APIs**: Don't depend on external services
5. **Parallelize**: Run tests in parallel for speed

---

## Related Files

- **Quick Syntax**: [QUICK-REFERENCE.md](./QUICK-REFERENCE.md)
- **Complete Guide**: [PLAYWRIGHT-COMPREHENSIVE-GUIDE.md](./PLAYWRIGHT-COMPREHENSIVE-GUIDE.md)
- **Project Patterns**: [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md)
- **Overview**: [README.md](./README.md)
- **Navigation**: [INDEX.md](./INDEX.md)

---

**All examples are production-ready patterns. Adapt them to your project needs!**
