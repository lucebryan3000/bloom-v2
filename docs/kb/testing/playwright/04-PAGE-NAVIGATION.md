---
id: playwright-04-page-navigation
topic: playwright
file_role: core
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [playwright-01-fundamentals, playwright-02-selectors-locators]
related_topics: [navigation, routing, multi-page, url-assertions]
embedding_keywords: [playwright, navigation, routing, page-navigation, multi-page-testing, goto, waitForURL, waitForNavigation, url-testing, query-parameters, hash-navigation]
last_reviewed: 2025-11-14
---

# Playwright Page Navigation

<!-- Query: "How do I navigate between pages in Playwright?" -->
<!-- Query: "How to test Next.js routing with Playwright?" -->
<!-- Query: "How to wait for navigation in Playwright?" -->
<!-- Query: "How to test URL parameters and hash fragments?" -->

## Table of Contents
1. [Purpose](#1-purpose)
2. [Mental Model / Problem Statement](#2-mental-model--problem-statement)
3. [Golden Path](#3-golden-path)
4. [Variations & Trade-Offs](#4-variations--trade-offs)
5. [Examples](#5-examples)
6. [Common Pitfalls](#6-common-pitfalls)
7. [AI Pair Programming Notes](#7-ai-pair-programming-notes)

---

## 1. Purpose

Master navigation patterns, URL assertions, and multi-page testing scenarios in Playwright. This file is essential for testing complex user journeys, routing logic, and navigation flows.

**What You'll Learn:**
- `page.goto()` navigation patterns and options
- URL waiting and navigation tracking (`waitForURL`, `waitForNavigation`)
- Browser history manipulation (back, forward, reload)
- Query parameters and hash fragment testing
- Multi-page flows and navigation assertions
- Next.js 16 App Router navigation patterns
- Bloom workshop navigation flows (start session → chat → export)

**Why This Matters:**
- **User Journeys**: Test realistic multi-step workflows
- **Routing Logic**: Validate Next.js routing and redirects
- **State Management**: Ensure URL params persist correctly
- **SEO & Deep Linking**: Test shareable URLs and query params

**Read this file when:**
- Writing tests that span multiple pages
- Testing workshop session flows (Bloom-specific)
- Validating routing and redirects
- Testing URL-based state (filters, search, pagination)

---

## 2. Mental Model / Problem Statement

### The Challenge: Reliable Multi-Page Testing

Traditional E2E testing tools struggle with navigation timing:

```typescript
// ❌ OLD WAY (Selenium): Manual waits, race conditions
await driver.get('http://localhost:3001/workshop');
await driver.wait(until.titleIs('Workshop'), 5000); // Brittle
await driver.findElement(By.id('start-button')).click();
await driver.wait(until.urlContains('/session/'), 10000); // Guess timeout
```

**Problems:**
- **Race conditions**: Page may not be fully loaded
- **Brittle waits**: Hardcoded timeouts break under slow network
- **No network idle detection**: JavaScript may still be loading
- **Navigation state unclear**: Did navigation complete?

### Playwright's Solution: Smart Navigation Handling

**Auto-Waiting for Navigation:**
Playwright automatically waits for navigation events when triggered by user actions:

```typescript
// ✅ PLAYWRIGHT WAY: Automatic navigation detection
await page.goto('/workshop'); // Waits for load event by default
await page.getByRole('button', { name: 'Start Session' }).click();
// ✅ Automatically waits for navigation to complete if click triggers route change
```

**Navigation Events Playwright Tracks:**
1. **`load`** - Page fully loaded (default wait)
2. **`domcontentloaded`** - DOM ready (faster, but scripts may still be loading)
3. **`networkidle`** - No network activity for 500ms (useful for SPAs)
4. **`commit`** - Navigation committed (earliest event)

### Mental Model: "Navigation is Async, Playwright Handles It"

**Key Insights:**
- **Explicit navigation** (`page.goto()`) always waits for page load
- **Implicit navigation** (clicking links/buttons) auto-waits if navigation happens
- **URL assertions** (`waitForURL`) are safer than timing-based waits
- **Next.js App Router** uses client-side navigation (not full page reloads)

**Bloom-Specific Context:**

Bloom uses Next.js 16 App Router, which means:
- **Initial page load**: Full page load (use `page.goto()`)
- **Subsequent navigation**: Client-side routing (React Router-like behavior)
- **Workshop flow**: `/workshop` → `/workshop/session/{id}` → `/workshop/session/{id}/report`
- **Settings tabs**: `/settings?tab=monitoring` (query params, no navigation)

---

## 3. Golden Path

### Recommended Navigation Strategy

**1. Use `page.goto()` for Initial Navigation**

```typescript
// ✅ BEST: Explicit navigation with auto-waiting
await page.goto('/workshop');

// ✅ GOOD: Wait for network idle (useful for SPAs)
await page.goto('/workshop', { waitUntil: 'networkidle' });

// ✅ GOOD: Relative URLs work if baseURL is configured
await page.goto('/settings'); // Uses baseURL from playwright.config.ts
```

**2. Use `waitForURL()` for Navigation Assertions**

```typescript
// ✅ BEST: Wait for specific URL pattern
await page.getByRole('button', { name: 'Start Session' }).click();
await page.waitForURL(/\/workshop\/session\/.+/);

// ✅ GOOD: Wait for exact URL
await page.waitForURL('/workshop/session/abc123');

// ✅ GOOD: Wait for query params
await page.waitForURL('/settings?tab=monitoring');
```

**3. Use `expect(page).toHaveURL()` for Verification**

```typescript
// ✅ BEST: Assertion with auto-retry
await expect(page).toHaveURL('/workshop');

// ✅ GOOD: Regex pattern for dynamic URLs
await expect(page).toHaveURL(/\/sessions\/[a-zA-Z0-9]+/);

// ✅ GOOD: Partial URL match
await expect(page).toHaveURL(/\/settings/);
```

**4. Use Browser History for Multi-Step Flows**

```typescript
// ✅ BEST: Test back/forward navigation
await page.goto('/workshop');
await page.getByRole('link', { name: 'Settings' }).click();
await expect(page).toHaveURL('/settings');

await page.goBack(); // Navigate back
await expect(page).toHaveURL('/workshop');

await page.goForward(); // Navigate forward
await expect(page).toHaveURL('/settings');
```

**5. Use `page.reload()` for State Testing**

```typescript
// ✅ BEST: Test persistence after refresh
await page.goto('/workshop/session/abc123');
await page.getByLabel('Organization Name').fill('Acme Corp');

await page.reload(); // Refresh page
await expect(page.getByLabel('Organization Name')).toHaveValue('Acme Corp');
```

---

## 4. Variations & Trade-Offs

### 4.1 Navigation Methods

| Method | Use Case | Auto-Waits | Notes |
|--------|----------|------------|-------|
| `goto(url)` | Initial page load | ✅ Yes | Default: waits for `load` event |
| `goBack()` | Browser back button | ✅ Yes | Waits for navigation to complete |
| `goForward()` | Browser forward button | ✅ Yes | Waits for navigation to complete |
| `reload()` | Page refresh | ✅ Yes | Waits for page reload |
| `click()` on link | User-triggered navigation | ✅ Yes (if navigation occurs) | Auto-detects navigation |
| `setContent()` | Set HTML directly | ❌ No | For testing static HTML |

#### `page.goto()` Options

```typescript
// Default: Wait for 'load' event (DOM + resources loaded)
await page.goto('/workshop');

// Wait for DOM only (faster, but scripts may still be loading)
await page.goto('/workshop', { waitUntil: 'domcontentloaded' });

// Wait for network idle (no requests for 500ms)
await page.goto('/workshop', { waitUntil: 'networkidle' });

// Wait for navigation commit (earliest, riskiest)
await page.goto('/workshop', { waitUntil: 'commit' });

// Custom timeout (default is 30s)
await page.goto('/workshop', { timeout: 60000 });

// Handle redirects
const response = await page.goto('/old-url');
console.log(response?.url()); // Final URL after redirects
```

**Recommendation for Bloom:**
- Use default `load` for most pages
- Use `networkidle` for `/workshop` (Melissa chat may load async data)
- Use `domcontentloaded` only when testing fast page appearance

### 4.2 URL Waiting Strategies

| Method | Use Case | Trade-Off |
|--------|----------|-----------|
| `waitForURL(url)` | Wait for exact URL | Blocks until URL matches |
| `waitForURL(regex)` | Wait for URL pattern | Flexible, works with dynamic IDs |
| `expect(page).toHaveURL()` | Assert URL with retry | Best for assertions |
| `waitForNavigation()` | Wait for any navigation | ⚠️ Deprecated, use `waitForURL()` |

```typescript
// ✅ EXACT URL MATCH
await page.waitForURL('/workshop');

// ✅ REGEX PATTERN (best for dynamic URLs)
await page.waitForURL(/\/workshop\/session\/[a-zA-Z0-9]+/);

// ✅ FUNCTION PREDICATE (advanced filtering)
await page.waitForURL(url => url.pathname === '/workshop' && url.searchParams.has('id'));

// ✅ TIMEOUT OVERRIDE
await page.waitForURL('/workshop', { timeout: 10000 });

// ❌ DEPRECATED: waitForNavigation (use waitForURL instead)
// await page.waitForNavigation(); // Don't use this
```

### 4.3 Query Parameters & Hash Fragments

**Query Parameters:**

```typescript
// Navigate with query params
await page.goto('/settings?tab=monitoring');

// Assert query params
await expect(page).toHaveURL('/settings?tab=monitoring');

// Extract query params
const url = new URL(page.url());
const tab = url.searchParams.get('tab');
expect(tab).toBe('monitoring');

// Test multiple query params
await page.goto('/sessions?status=active&sort=date');
await expect(page).toHaveURL(/status=active/);
await expect(page).toHaveURL(/sort=date/);
```

**Hash Fragments:**

```typescript
// Navigate with hash
await page.goto('/help#faq');

// Assert hash
await expect(page).toHaveURL('/help#faq');

// Extract hash
const hash = new URL(page.url()).hash;
expect(hash).toBe('#faq');

// Test hash navigation (no page reload)
await page.getByRole('link', { name: 'Pricing' }).click();
await expect(page).toHaveURL('/help#pricing');
```

### 4.4 Redirect Handling

```typescript
// Test redirect behavior
const response = await page.goto('/old-path');

// Check if redirected
expect(response?.status()).toBe(301); // Permanent redirect
expect(response?.url()).toBe('http://localhost:3001/new-path');

// Verify final URL
await expect(page).toHaveURL('/new-path');

// Test redirect chain
await page.goto('/redirect-1'); // Redirects to /redirect-2
await page.waitForURL('/final-destination');
```

### 4.5 Multi-Page Scenarios

**Opening New Tabs:**

```typescript
// Wait for new page to open
const pagePromise = context.waitForEvent('page');
await page.getByRole('link', { name: 'Open in New Tab' }).click();
const newPage = await pagePromise;

// Interact with new page
await newPage.waitForLoadState();
await expect(newPage).toHaveURL('/new-tab-content');

// Close new page
await newPage.close();
```

**Multiple Pages:**

```typescript
// Create multiple pages
const page1 = await context.newPage();
const page2 = await context.newPage();

await page1.goto('/workshop');
await page2.goto('/settings');

// Switch between pages
await page1.bringToFront();
await page1.getByRole('button', { name: 'Start' }).click();

await page2.bringToFront();
await page2.getByRole('button', { name: 'Save' }).click();
```

---

## 5. Examples

### Example 1: Bloom Workshop Navigation Flow

**Scenario:** User starts a new session, chats with Melissa, and exports a report.

```typescript
test('complete workshop navigation flow', async ({ page }) => {
  // 1. Navigate to workshop landing page
  await page.goto('/workshop');
  await expect(page).toHaveURL('/workshop');
  await expect(page.getByRole('heading', { name: 'Bloom Workshop' })).toBeVisible();

  // 2. Start new session
  await page.getByRole('button', { name: 'Start New Session' }).click();

  // 3. Wait for session creation (dynamic URL with session ID)
  await page.waitForURL(/\/workshop\/session\/[a-zA-Z0-9]+/);

  // 4. Extract session ID from URL
  const url = new URL(page.url());
  const sessionId = url.pathname.split('/').pop();
  expect(sessionId).toMatch(/^[a-zA-Z0-9]+$/);

  // 5. Fill organization details
  await page.getByLabel('Organization Name').fill('Acme Corp');
  await page.getByLabel('Industry').selectOption('Technology');
  await page.getByRole('button', { name: 'Continue' }).click();

  // 6. Verify navigation to chat interface (same URL, different view)
  await expect(page.getByRole('heading', { name: 'Chat with Melissa' })).toBeVisible();

  // 7. Complete chat (may trigger URL change to report)
  await page.getByPlaceholder('Type your message').fill('What is our ROI?');
  await page.getByRole('button', { name: 'Send' }).click();

  // 8. Wait for report generation (may navigate to /report)
  await page.waitForURL(/\/workshop\/session\/.+\/report/, { timeout: 10000 });

  // 9. Verify report page
  await expect(page.getByRole('heading', { name: 'ROI Report' })).toBeVisible();

  // 10. Export report (triggers download, no navigation)
  const downloadPromise = page.waitForEvent('download');
  await page.getByRole('button', { name: 'Export PDF' }).click();
  const download = await downloadPromise;
  expect(download.suggestedFilename()).toMatch(/\.pdf$/);
});
```

### Example 2: Settings Tab Navigation (Query Parameters)

**Scenario:** Navigate between settings tabs using query parameters.

```typescript
test('settings tab navigation with query params', async ({ page }) => {
  // Navigate to default settings tab
  await page.goto('/settings');
  await expect(page).toHaveURL('/settings'); // No ?tab= param = default tab

  // Click "Monitoring" tab (client-side navigation, updates URL)
  await page.getByRole('tab', { name: 'Monitoring' }).click();
  await expect(page).toHaveURL('/settings?tab=monitoring');

  // Click "Branding" tab
  await page.getByRole('tab', { name: 'Branding' }).click();
  await expect(page).toHaveURL('/settings?tab=branding');

  // Direct navigation to specific tab
  await page.goto('/settings?tab=sessions');
  await expect(page.getByRole('tab', { name: 'Sessions' })).toHaveAttribute('aria-selected', 'true');

  // Test invalid tab parameter (should default to first tab)
  await page.goto('/settings?tab=invalid');
  await expect(page.getByRole('tab', { name: 'General' })).toHaveAttribute('aria-selected', 'true');
});
```

### Example 3: Session Resume (Browser History)

**Scenario:** Test back/forward navigation preserves session state.

```typescript
test('session state persists across navigation', async ({ page }) => {
  // Start session
  await page.goto('/workshop');
  await page.getByRole('button', { name: 'Start New Session' }).click();
  await page.waitForURL(/\/workshop\/session\/.+/);

  // Fill in some data
  await page.getByLabel('Organization Name').fill('Acme Corp');
  await page.getByLabel('Industry').selectOption('Technology');

  // Navigate away
  await page.getByRole('link', { name: 'Help' }).click();
  await expect(page).toHaveURL('/help');

  // Go back to session
  await page.goBack();
  await page.waitForURL(/\/workshop\/session\/.+/);

  // Verify data persisted (from localStorage/sessionStorage or API)
  await expect(page.getByLabel('Organization Name')).toHaveValue('Acme Corp');
  await expect(page.getByLabel('Industry')).toHaveValue('Technology');
});
```

### Example 4: Page Reload Persistence

**Scenario:** Test that session data survives page refresh.

```typescript
test('session data persists after page reload', async ({ page }) => {
  // Create session and fill data
  await page.goto('/workshop');
  await page.getByRole('button', { name: 'Start New Session' }).click();
  await page.waitForURL(/\/workshop\/session\/.+/);

  const sessionUrl = page.url();

  await page.getByLabel('Organization Name').fill('Acme Corp');
  await page.getByRole('button', { name: 'Save' }).click();
  await expect(page.getByText('Saved successfully')).toBeVisible();

  // Reload page
  await page.reload();
  await page.waitForLoadState('networkidle');

  // Verify still on same URL
  expect(page.url()).toBe(sessionUrl);

  // Verify data persisted (from database or server session)
  await expect(page.getByLabel('Organization Name')).toHaveValue('Acme Corp');
});
```

### Example 5: Multi-Page Flow (New Tab)

**Scenario:** User opens help documentation in new tab.

```typescript
test('open help in new tab without losing session', async ({ context, page }) => {
  // Start session
  await page.goto('/workshop');
  await page.getByRole('button', { name: 'Start New Session' }).click();
  await page.waitForURL(/\/workshop\/session\/.+/);

  const sessionUrl = page.url();

  // Fill some data
  await page.getByLabel('Organization Name').fill('Acme Corp');

  // Open help in new tab (target="_blank" link)
  const pagePromise = context.waitForEvent('page');
  await page.getByRole('link', { name: 'Need Help?' }).click(); // Has target="_blank"
  const helpPage = await pagePromise;

  // Wait for help page to load
  await helpPage.waitForLoadState();
  await expect(helpPage).toHaveURL('/help');

  // Original page should still be on session URL with data intact
  await expect(page).toHaveURL(sessionUrl);
  await expect(page.getByLabel('Organization Name')).toHaveValue('Acme Corp');

  // Close help tab
  await helpPage.close();

  // Main page still functional
  await page.getByLabel('Industry').selectOption('Technology');
  await expect(page.getByLabel('Industry')).toHaveValue('Technology');
});
```

### Example 6: Hash Fragment Navigation

**Scenario:** Navigate to specific section on help page using hash.

```typescript
test('hash fragment navigation on help page', async ({ page }) => {
  // Navigate to help page
  await page.goto('/help');
  await expect(page).toHaveURL('/help');

  // Click on FAQ link (should scroll to #faq section, no page reload)
  await page.getByRole('link', { name: 'FAQ' }).click();
  await expect(page).toHaveURL('/help#faq');

  // Verify scrolled to section
  const faqSection = page.locator('#faq');
  await expect(faqSection).toBeInViewport();

  // Direct navigation with hash
  await page.goto('/help#pricing');
  await expect(page).toHaveURL('/help#pricing');

  const pricingSection = page.locator('#pricing');
  await expect(pricingSection).toBeInViewport();
});
```

### Example 7: Redirect Testing

**Scenario:** Test that old URLs redirect to new URLs.

```typescript
test('redirects from legacy URLs', async ({ page }) => {
  // Navigate to old URL (should redirect)
  const response = await page.goto('/old-workshop');

  // Verify redirect status code
  expect(response?.status()).toBe(301); // Permanent redirect

  // Verify final URL
  await expect(page).toHaveURL('/workshop');

  // Verify page content loaded correctly
  await expect(page.getByRole('heading', { name: 'Bloom Workshop' })).toBeVisible();
});
```

### Example 8: 404 Error Page

**Scenario:** Test that invalid URLs show proper error page.

```typescript
test('shows 404 page for invalid routes', async ({ page }) => {
  // Navigate to non-existent page
  const response = await page.goto('/this-page-does-not-exist');

  // Verify 404 status
  expect(response?.status()).toBe(404);

  // Verify 404 page content
  await expect(page.getByRole('heading', { name: '404' })).toBeVisible();
  await expect(page.getByText('Page not found')).toBeVisible();

  // Verify navigation to home works
  await page.getByRole('link', { name: 'Go Home' }).click();
  await expect(page).toHaveURL('/');
});
```

---

## 6. Common Pitfalls

### Pitfall 1: Not Waiting for URL Changes

**Problem:**
```typescript
// ❌ BAD: No wait for navigation
await page.getByRole('button', { name: 'Start Session' }).click();
expect(page.url()).toContain('/session/'); // May fail if navigation is slow
```

**Solution:**
```typescript
// ✅ GOOD: Wait for URL change
await page.getByRole('button', { name: 'Start Session' }).click();
await page.waitForURL(/\/session\/.+/);
expect(page.url()).toContain('/session/'); // Safe
```

### Pitfall 2: Using `waitForNavigation()` (Deprecated)

**Problem:**
```typescript
// ❌ BAD: Deprecated method
await Promise.all([
  page.waitForNavigation(), // Deprecated
  page.getByRole('link', { name: 'Next' }).click(),
]);
```

**Solution:**
```typescript
// ✅ GOOD: Use waitForURL()
await page.getByRole('link', { name: 'Next' }).click();
await page.waitForURL('/next-page');
```

### Pitfall 3: Hardcoding Full URLs

**Problem:**
```typescript
// ❌ BAD: Hardcoded hostname
await page.goto('http://localhost:3001/workshop');
await expect(page).toHaveURL('http://localhost:3001/workshop');
```

**Solution:**
```typescript
// ✅ GOOD: Use baseURL from config + relative paths
await page.goto('/workshop');
await expect(page).toHaveURL('/workshop');
```

### Pitfall 4: Race Conditions with Client-Side Routing

**Problem:**
```typescript
// ❌ BAD: Assumes instant navigation (Next.js client-side routing)
await page.getByRole('link', { name: 'Settings' }).click();
expect(page.getByRole('heading', { name: 'Settings' })).toBeVisible(); // May fail
```

**Solution:**
```typescript
// ✅ GOOD: Wait for navigation AND element visibility
await page.getByRole('link', { name: 'Settings' }).click();
await page.waitForURL('/settings');
await expect(page.getByRole('heading', { name: 'Settings' })).toBeVisible();
```

### Pitfall 5: Not Handling Redirects

**Problem:**
```typescript
// ❌ BAD: Assumes no redirect
await page.goto('/workshop');
await expect(page).toHaveURL('/workshop'); // May fail if redirected to /workshop?onboarding=true
```

**Solution:**
```typescript
// ✅ GOOD: Use regex or check final URL
await page.goto('/workshop');
await expect(page).toHaveURL(/\/workshop/); // Matches with query params
```

### Pitfall 6: Ignoring Network Idle for SPAs

**Problem:**
```typescript
// ❌ BAD: May not wait for async data
await page.goto('/workshop', { waitUntil: 'load' });
await expect(page.getByText('Recent Sessions')).toBeVisible(); // May fail if data loads async
```

**Solution:**
```typescript
// ✅ GOOD: Wait for network idle
await page.goto('/workshop', { waitUntil: 'networkidle' });
await expect(page.getByText('Recent Sessions')).toBeVisible();
```

### Pitfall 7: Not Testing Back/Forward Navigation

**Problem:**
Not testing browser history can miss state bugs:

```typescript
// ❌ BAD: Only tests forward navigation
test('navigate to settings', async ({ page }) => {
  await page.goto('/');
  await page.getByRole('link', { name: 'Settings' }).click();
  await expect(page).toHaveURL('/settings');
});
```

**Solution:**
```typescript
// ✅ GOOD: Test back/forward navigation
test('navigate to settings and back', async ({ page }) => {
  await page.goto('/');
  await page.getByRole('link', { name: 'Settings' }).click();
  await expect(page).toHaveURL('/settings');

  await page.goBack();
  await expect(page).toHaveURL('/');

  await page.goForward();
  await expect(page).toHaveURL('/settings');
});
```

---

## 7. AI Pair Programming Notes

**When to use navigation testing:**
- ✅ Multi-step user flows (workshop session creation → chat → report)
- ✅ Routing logic validation (redirects, 404 pages, deep links)
- ✅ URL-based state (filters, pagination, tabs)
- ✅ Browser history (back/forward button behavior)
- ✅ Cross-page persistence (localStorage, session state)

**When NOT to use navigation testing:**
- ❌ Single-page interactions (use interaction/assertion tests)
- ❌ API-only tests (use API testing patterns)
- ❌ Unit tests for routing logic (use Jest)

**Best Practices for AI-Assisted Testing:**

1. **Start with user journeys**: "User starts workshop → completes chat → exports report"
2. **Use regex for dynamic URLs**: `/\/session\/[a-zA-Z0-9]+/` instead of exact match
3. **Wait for URL changes**: Always use `waitForURL()` after actions that trigger navigation
4. **Test both directions**: Forward navigation AND back/forward buttons
5. **Verify content after navigation**: Don't just check URL, verify page loaded correctly
6. **Use `networkidle` for SPAs**: Bloom uses Next.js App Router (client-side routing)

**Bloom-Specific Patterns:**

```typescript
// Pattern 1: Workshop session navigation
await page.goto('/workshop');
await page.getByRole('button', { name: 'Start New Session' }).click();
await page.waitForURL(/\/workshop\/session\/.+/);

// Pattern 2: Settings tab switching (query params, no full navigation)
await page.goto('/settings');
await page.getByRole('tab', { name: 'Monitoring' }).click();
await expect(page).toHaveURL('/settings?tab=monitoring');

// Pattern 3: Session resume (dynamic URL with session ID)
const sessionUrl = page.url(); // e.g., /workshop/session/abc123
await page.goto(sessionUrl);
await expect(page.getByLabel('Organization Name')).toHaveValue('Acme Corp');
```

**Debugging Navigation Issues:**

```typescript
// Log current URL
console.log('Current URL:', page.url());

// Log navigation events
page.on('framenavigated', frame => {
  console.log('Navigated to:', frame.url());
});

// Check response status
const response = await page.goto('/workshop');
console.log('Status:', response?.status());
console.log('Final URL:', response?.url());
```

---

## Related Documentation

- `01-FUNDAMENTALS.md` - Playwright architecture and auto-waiting
- `02-SELECTORS-LOCATORS.md` - Finding elements on pages
- `03-INTERACTIONS-ASSERTIONS.md` - Interacting with page elements
- `05-API-TESTING.md` - Testing API endpoints
- `/docs/ARCHITECTURE.md` - Bloom's routing architecture

---

## Last Updated

2025-11-14
