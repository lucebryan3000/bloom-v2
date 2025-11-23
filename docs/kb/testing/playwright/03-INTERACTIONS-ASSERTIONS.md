---
id: playwright-03-interactions-assertions
topic: playwright
file_role: core
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [playwright-01-fundamentals, playwright-02-selectors-locators]
related_topics: [interactions, assertions, expect, auto-waiting]
embedding_keywords: [playwright, interactions, assertions, click, fill, expect, toBeVisible, auto-waiting, web-first]
last_reviewed: 2025-11-14
---

# Playwright Interactions & Assertions

<!-- Query: "How do I interact with elements in Playwright?" -->
<!-- Query: "What are Playwright's best practices for assertions?" -->
<!-- Query: "How does auto-waiting work in Playwright?" -->
<!-- Query: "How to test form interactions in Playwright?" -->

## 1. Purpose

Master Playwright's interaction methods (click, fill, type, check, select) and assertion strategies (web-first assertions, auto-waiting, soft assertions). This file is critical for writing reliable E2E tests that interact with UI elements and verify expected behavior.

**Read this file when:**
- Writing tests that interact with forms, buttons, or user input
- Verifying UI state and element properties
- Understanding why tests are flaky or timing out
- Implementing workshop chat interactions or session management tests

**This file covers:**
- All interaction methods with real examples
- Web-first assertion philosophy and auto-waiting behavior
- Timeout configuration and custom waits
- Soft assertions for non-blocking checks
- Bloom workshop-specific patterns (chat, forms, navigation)

---

## 2. Mental Model / Problem Statement

### The Challenge: Reliable User Interaction Testing

Traditional E2E testing tools require manual waits and explicit synchronization:
```typescript
// OLD WAY (Selenium, Puppeteer without helpers)
await driver.findElement(By.id('button')); // Find element
await driver.wait(until.elementIsVisible(button), 5000); // Wait for visible
await driver.wait(until.elementIsEnabled(button), 5000); // Wait for enabled
await button.click(); // Finally click
```

**Problems:**
- Manual waits are brittle (too short = flaky, too long = slow)
- Race conditions when elements load asynchronously
- Tests fail when network is slow or UI updates delay
- Assertions on elements that may not be ready yet

### Playwright's Solution: Auto-Waiting + Web-First Assertions

**Auto-Waiting Philosophy:**
Playwright automatically waits for elements to be actionable before performing actions:
1. **Element exists** in DOM
2. **Element is visible** (not `display: none` or `visibility: hidden`)
3. **Element is stable** (not animating or moving)
4. **Element receives events** (not covered by another element)
5. **Element is enabled** (not `disabled` attribute for buttons/inputs)

```typescript
// PLAYWRIGHT WAY
await page.getByRole('button', { name: 'Submit' }).click();
// ✅ Automatically waits for button to be clickable (visible, enabled, stable)
```

**Web-First Assertions:**
Assertions wait for the expected condition to be met:
```typescript
// ✅ Waits up to 5 seconds (default timeout) for element to become visible
await expect(page.getByText('Success')).toBeVisible();

// ❌ NO auto-waiting (old assertion style)
expect(await page.getByText('Success').isVisible()).toBe(true);
```

### Mental Model: "Actions and Assertions Wait, You Don't Have To"

**Key Insight:** Trust Playwright's auto-waiting. Don't add manual `waitForTimeout()` unless absolutely necessary.

**When auto-waiting happens:**
- ✅ `locator.click()` - waits for clickable
- ✅ `locator.fill()` - waits for writable
- ✅ `expect(locator).toBeVisible()` - waits for visible
- ✅ `locator.check()` - waits for checkbox to be checkable

**When auto-waiting does NOT happen:**
- ❌ `locator.isVisible()` - returns current state immediately
- ❌ `locator.count()` - returns current count immediately
- ❌ `page.evaluate()` - executes JavaScript immediately

**Rule of Thumb:**
- Use `await expect(locator).toXXX()` for assertions (auto-waits)
- Use `await locator.action()` for interactions (auto-waits)
- Avoid `await locator.isXXX()` in assertions (no auto-wait)

---

## 3. Golden Path

### Recommended Interaction & Assertion Strategy

**1. Use Role-Based Selectors (Accessible)**
```typescript
// ✅ BEST: Accessible, resilient to UI changes
await page.getByRole('button', { name: 'Submit' }).click();
await page.getByRole('textbox', { name: 'Email' }).fill('user@example.com');
await page.getByLabel('Remember me').check();
```

**2. Use Web-First Assertions**
```typescript
// ✅ BEST: Auto-waits, retries, clear intent
await expect(page.getByText('Welcome back')).toBeVisible();
await expect(page.getByRole('heading', { name: 'Dashboard' })).toBeVisible();
await expect(page.getByLabel('Username')).toHaveValue('john');
```

**3. Chain Actions Logically**
```typescript
// ✅ BEST: Clear sequence, auto-waits at each step
test('user can complete workshop session', async ({ page }) => {
  await page.goto('/workshop');

  // Start session
  await page.getByRole('button', { name: 'Start New Session' }).click();

  // Fill in organization details
  await page.getByLabel('Organization Name').fill('Acme Corp');
  await page.getByLabel('Industry').selectOption('Technology');

  // Verify session started
  await expect(page.getByText('Session started')).toBeVisible();
  await expect(page).toHaveURL(/\/workshop\/session\/.+/);
});
```

**4. Verify State After Actions**
```typescript
// ✅ BEST: Assert expected outcome after interaction
await page.getByRole('button', { name: 'Delete' }).click();
await expect(page.getByText('Item deleted successfully')).toBeVisible();
await expect(page.getByText('My Item')).not.toBeVisible();
```

**5. Use Soft Assertions for Non-Critical Checks**
```typescript
// ✅ BEST: Continue test even if optional elements are missing
test('homepage has expected content', async ({ page }) => {
  await page.goto('/');

  // Critical assertion (test fails if this fails)
  await expect(page).toHaveTitle(/Bloom/);

  // Optional checks (logged but don't fail test)
  await expect.soft(page.getByRole('banner')).toBeVisible();
  await expect.soft(page.getByRole('navigation')).toBeVisible();
  await expect.soft(page.getByText('Welcome')).toBeVisible();
});
```

---

## 4. Variations & Trade-Offs

### Interaction Methods

#### **4.1 Click Variations**

| Method | Use Case | Trade-Off |
|--------|----------|-----------|
| `click()` | Standard click (most common) | Waits for actionability, scrolls into view |
| `dblclick()` | Double-click interactions | Less common, may need custom handling |
| `click({ force: true })` | Bypass actionability checks | ⚠️ Dangerous: Clicks even if element is covered |
| `click({ position: { x, y } })` | Click specific coordinates | Brittle: Breaks if element size changes |
| `click({ button: 'right' })` | Context menu | Good for testing right-click menus |
| `dispatchEvent('click')` | Programmatic click | No auto-waiting, bypasses user interaction |

**Recommendation:** Use `click()` without options 99% of the time. Only use `force: true` as a last resort.

```typescript
// ✅ PREFERRED: Standard click with auto-waiting
await page.getByRole('button', { name: 'Save' }).click();

// ⚠️ USE SPARINGLY: Force click (bypasses visibility checks)
await page.getByRole('button', { name: 'Hidden Button' }).click({ force: true });

// ✅ GOOD: Right-click for context menu
await page.getByText('File.txt').click({ button: 'right' });
await expect(page.getByRole('menuitem', { name: 'Delete' })).toBeVisible();
```

#### **4.2 Text Input Variations**

| Method | Behavior | Use Case |
|--------|----------|----------|
| `fill(text)` | Clears field, then types | Standard form input (RECOMMENDED) |
| `type(text)` | Types character-by-character | Slow, use for testing autocomplete |
| `pressSequentially(text)` | Types with delays between chars | Simulates human typing, triggers events |
| `setInputFiles(files)` | Upload files | File upload fields |

**Recommendation:** Use `fill()` for speed, `pressSequentially()` for realistic typing simulation.

```typescript
// ✅ FAST: Immediate fill (best for most cases)
await page.getByLabel('Email').fill('user@example.com');

// ✅ REALISTIC: Character-by-character with delays
await page.getByLabel('Search').pressSequentially('laptop', { delay: 100 });
await expect(page.getByRole('option', { name: 'MacBook' })).toBeVisible();

// ✅ FILE UPLOAD
await page.getByLabel('Upload CV').setInputFiles('/path/to/resume.pdf');
```

#### **4.3 Selection Variations**

| Method | Element Type | Use Case |
|--------|--------------|----------|
| `selectOption(value)` | `<select>` dropdown | Standard dropdown selection |
| `check()` | Checkbox or radio | Check/select checkbox |
| `uncheck()` | Checkbox | Uncheck checkbox |
| `setChecked(true/false)` | Checkbox | Set explicit state |

```typescript
// ✅ DROPDOWN: Select by value, label, or index
await page.getByLabel('Country').selectOption('US'); // By value
await page.getByLabel('Country').selectOption({ label: 'United States' }); // By label
await page.getByLabel('Country').selectOption({ index: 1 }); // By index

// ✅ CHECKBOX: Check or uncheck
await page.getByLabel('Accept terms').check();
await page.getByLabel('Subscribe to newsletter').uncheck();

// ✅ RADIO: Select specific option
await page.getByLabel('Credit Card').check();
```

#### **4.4 Keyboard & Mouse Variations**

```typescript
// KEYBOARD
await page.keyboard.press('Enter'); // Single key
await page.keyboard.press('Control+A'); // Modifier + key
await page.keyboard.type('Hello'); // Type string
await page.keyboard.down('Shift'); // Hold key
await page.keyboard.up('Shift'); // Release key

// MOUSE
await page.mouse.move(100, 200); // Move to coordinates
await page.mouse.click(100, 200); // Click at coordinates
await page.mouse.wheel(0, 100); // Scroll

// HOVER
await page.getByRole('button', { name: 'More' }).hover();
await expect(page.getByText('Tooltip text')).toBeVisible();
```

### Assertion Variations

#### **4.5 Visibility Assertions**

| Assertion | Meaning | Use Case |
|-----------|---------|----------|
| `toBeVisible()` | Element is visible to user | Standard visibility check |
| `toBeHidden()` | Element is not visible | Check element is hidden |
| `not.toBeVisible()` | Element is not visible | Synonym for `toBeHidden()` |
| `toBeAttached()` | Element exists in DOM | Check DOM presence (even if hidden) |

```typescript
// ✅ VISIBLE: Element is displayed and visible
await expect(page.getByText('Success')).toBeVisible();

// ✅ HIDDEN: Element is not visible (may still be in DOM)
await expect(page.getByText('Error')).toBeHidden();

// ✅ IN DOM: Element exists but may be hidden
await expect(page.getByTestId('hidden-panel')).toBeAttached();
```

#### **4.6 Text & Value Assertions**

| Assertion | Checks | Use Case |
|-----------|--------|----------|
| `toHaveText(text)` | Exact text match | Verify exact text content |
| `toContainText(text)` | Partial text match | Verify text contains substring |
| `toHaveValue(value)` | Input value | Verify form field value |
| `toHaveAttribute(name, value)` | HTML attribute | Verify data-* or other attributes |

```typescript
// ✅ EXACT TEXT
await expect(page.getByRole('heading')).toHaveText('Welcome to Bloom');

// ✅ CONTAINS TEXT
await expect(page.getByRole('heading')).toContainText('Bloom');

// ✅ INPUT VALUE
await expect(page.getByLabel('Email')).toHaveValue('user@example.com');

// ✅ ATTRIBUTE
await expect(page.getByRole('link')).toHaveAttribute('href', '/dashboard');
await expect(page.getByTestId('user-id')).toHaveAttribute('data-user-id', '123');
```

#### **4.7 State Assertions**

| Assertion | Checks | Use Case |
|-----------|--------|----------|
| `toBeEnabled()` | Element is enabled | Verify button/input is clickable |
| `toBeDisabled()` | Element is disabled | Verify button/input is not clickable |
| `toBeChecked()` | Checkbox/radio is checked | Verify selection state |
| `toBeEditable()` | Input is writable | Verify field is not readonly |
| `toBeFocused()` | Element has focus | Verify focus management |

```typescript
// ✅ ENABLED/DISABLED
await expect(page.getByRole('button', { name: 'Submit' })).toBeEnabled();
await expect(page.getByRole('button', { name: 'Delete' })).toBeDisabled();

// ✅ CHECKED STATE
await expect(page.getByLabel('Remember me')).toBeChecked();
await expect(page.getByLabel('Subscribe')).not.toBeChecked();

// ✅ FOCUS
await page.getByLabel('Email').focus();
await expect(page.getByLabel('Email')).toBeFocused();
```

#### **4.8 Count & Multiple Elements**

```typescript
// ✅ COUNT: Exact number of elements
await expect(page.getByRole('listitem')).toHaveCount(5);

// ✅ AT LEAST: Minimum number
const items = page.getByRole('listitem');
expect(await items.count()).toBeGreaterThan(0);

// ✅ NONE: No matching elements
await expect(page.getByText('Error')).toHaveCount(0);
```

### Timeout Trade-Offs

| Approach | Timeout | Use Case |
|----------|---------|----------|
| Default | 5 seconds | Most assertions and actions |
| Custom per-assertion | `{ timeout: 10000 }` | Slow-loading elements |
| Global config | `expect.timeout` in config | Project-wide default |
| Infinite | `{ timeout: 0 }` | ⚠️ Dangerous: Never times out |

```typescript
// ✅ DEFAULT: 5 seconds (from playwright.config.ts)
await expect(page.getByText('Loading...')).toBeVisible();

// ✅ CUSTOM: 10 seconds for slow API call
await expect(page.getByText('Results loaded')).toBeVisible({ timeout: 10000 });

// ✅ IMMEDIATE: No wait (check current state)
await expect(page.getByText('Instant')).toBeVisible({ timeout: 0 });
```

---

## 5. Examples

### Example 1 – Pedagogical: Form Interaction Basics

**Scenario:** Test a simple login form with username, password, and submit button.

```typescript
import { test, expect } from '@playwright/test';

test.describe('Login Form Interactions', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/login');
  });

  test('should fill and submit login form', async ({ page }) => {
    // STEP 1: Locate and fill username field
    const usernameInput = page.getByLabel('Username');
    await usernameInput.fill('john.doe');

    // Verify the value was set
    await expect(usernameInput).toHaveValue('john.doe');

    // STEP 2: Locate and fill password field
    const passwordInput = page.getByLabel('Password');
    await passwordInput.fill('secret123');

    // Verify password is masked (type="password")
    await expect(passwordInput).toHaveAttribute('type', 'password');

    // STEP 3: Check "Remember me" checkbox
    const rememberCheckbox = page.getByLabel('Remember me');
    await rememberCheckbox.check();

    // Verify checkbox is checked
    await expect(rememberCheckbox).toBeChecked();

    // STEP 4: Click submit button
    const submitButton = page.getByRole('button', { name: 'Log In' });
    await submitButton.click();

    // STEP 5: Verify successful login (redirected to dashboard)
    await expect(page).toHaveURL('/dashboard');
    await expect(page.getByText('Welcome, john.doe')).toBeVisible();
  });

  test('should show validation errors for empty fields', async ({ page }) => {
    // Click submit without filling fields
    await page.getByRole('button', { name: 'Log In' }).click();

    // Verify validation errors are visible
    await expect(page.getByText('Username is required')).toBeVisible();
    await expect(page.getByText('Password is required')).toBeVisible();

    // Verify form is still on login page
    await expect(page).toHaveURL('/login');
  });

  test('should toggle password visibility', async ({ page }) => {
    const passwordInput = page.getByLabel('Password');
    const toggleButton = page.getByRole('button', { name: 'Show password' });

    // Initially password should be hidden (type="password")
    await expect(passwordInput).toHaveAttribute('type', 'password');

    // Click toggle button
    await toggleButton.click();

    // Password should now be visible (type="text")
    await expect(passwordInput).toHaveAttribute('type', 'text');
    await expect(toggleButton).toHaveText('Hide password');

    // Click again to hide
    await toggleButton.click();
    await expect(passwordInput).toHaveAttribute('type', 'password');
  });

  test('should disable submit button while submitting', async ({ page }) => {
    await page.getByLabel('Username').fill('john.doe');
    await page.getByLabel('Password').fill('secret123');

    const submitButton = page.getByRole('button', { name: 'Log In' });

    // Button should be enabled before submit
    await expect(submitButton).toBeEnabled();

    // Click submit
    await submitButton.click();

    // Button should be disabled during submission
    // (assumes form shows loading state)
    await expect(submitButton).toBeDisabled();

    // Wait for navigation to complete
    await page.waitForURL('/dashboard');
  });
});
```

**Key Concepts Demonstrated:**
- `fill()` for text inputs
- `check()` for checkboxes
- `click()` for buttons
- `toHaveValue()` for input values
- `toBeChecked()` for checkbox state
- `toBeEnabled()/toBeDisabled()` for button state
- `toHaveAttribute()` for HTML attributes

---

### Example 2 – Realistic Synthetic: Multi-Step Form with Dropdown & File Upload

**Scenario:** Test a complex job application form with text inputs, dropdown, file upload, and multi-step navigation.

```typescript
import { test, expect } from '@playwright/test';
import path from 'path';

test.describe('Job Application Form', () => {
  test('should complete multi-step application', async ({ page }) => {
    await page.goto('/careers/apply');

    // ========================================
    // STEP 1: Personal Information
    // ========================================
    await expect(page.getByRole('heading', { name: 'Personal Information' })).toBeVisible();

    // Fill personal details
    await page.getByLabel('First Name').fill('Jane');
    await page.getByLabel('Last Name').fill('Smith');
    await page.getByLabel('Email').fill('jane.smith@example.com');
    await page.getByLabel('Phone').fill('+1-555-0123');

    // Select country from dropdown
    await page.getByLabel('Country').selectOption('United States');

    // Verify selected value
    await expect(page.getByLabel('Country')).toHaveValue('US');

    // Click Next
    await page.getByRole('button', { name: 'Next' }).click();

    // ========================================
    // STEP 2: Work Experience
    // ========================================
    await expect(page.getByRole('heading', { name: 'Work Experience' })).toBeVisible();

    // Fill work experience
    await page.getByLabel('Current Job Title').fill('Senior Developer');
    await page.getByLabel('Company').fill('Tech Corp');
    await page.getByLabel('Years of Experience').selectOption('5-10');

    // Select multiple skills (checkboxes)
    await page.getByLabel('JavaScript').check();
    await page.getByLabel('TypeScript').check();
    await page.getByLabel('React').check();

    // Verify checkboxes are checked
    await expect(page.getByLabel('JavaScript')).toBeChecked();
    await expect(page.getByLabel('TypeScript')).toBeChecked();
    await expect(page.getByLabel('React')).toBeChecked();

    // Click Next
    await page.getByRole('button', { name: 'Next' }).click();

    // ========================================
    // STEP 3: Documents
    // ========================================
    await expect(page.getByRole('heading', { name: 'Upload Documents' })).toBeVisible();

    // Upload resume (file upload)
    const resumePath = path.join(__dirname, 'fixtures', 'resume.pdf');
    await page.getByLabel('Resume (PDF)').setInputFiles(resumePath);

    // Verify file name appears
    await expect(page.getByText('resume.pdf')).toBeVisible();

    // Optional: Upload cover letter
    const coverLetterPath = path.join(__dirname, 'fixtures', 'cover-letter.pdf');
    await page.getByLabel('Cover Letter (Optional)').setInputFiles(coverLetterPath);

    // Click Next
    await page.getByRole('button', { name: 'Next' }).click();

    // ========================================
    // STEP 4: Review & Submit
    // ========================================
    await expect(page.getByRole('heading', { name: 'Review Application' })).toBeVisible();

    // Verify all entered data is displayed correctly
    await expect(page.getByText('Jane Smith')).toBeVisible();
    await expect(page.getByText('jane.smith@example.com')).toBeVisible();
    await expect(page.getByText('Senior Developer at Tech Corp')).toBeVisible();
    await expect(page.getByText('resume.pdf')).toBeVisible();

    // Accept terms and conditions
    await page.getByLabel('I agree to the terms and conditions').check();

    // Verify submit button is now enabled
    const submitButton = page.getByRole('button', { name: 'Submit Application' });
    await expect(submitButton).toBeEnabled();

    // Submit application
    await submitButton.click();

    // ========================================
    // STEP 5: Confirmation
    // ========================================
    await expect(page).toHaveURL(/\/application\/confirmation/);
    await expect(page.getByRole('heading', { name: 'Application Submitted' })).toBeVisible();
    await expect(page.getByText('Thank you for your application')).toBeVisible();

    // Verify confirmation number is displayed
    await expect(page.getByText(/Confirmation #: [A-Z0-9]+/)).toBeVisible();
  });

  test('should allow going back to previous steps', async ({ page }) => {
    await page.goto('/careers/apply');

    // Fill Step 1
    await page.getByLabel('First Name').fill('Jane');
    await page.getByLabel('Last Name').fill('Smith');
    await page.getByRole('button', { name: 'Next' }).click();

    // Now on Step 2
    await expect(page.getByRole('heading', { name: 'Work Experience' })).toBeVisible();

    // Click Back button
    await page.getByRole('button', { name: 'Back' }).click();

    // Should be back on Step 1 with data preserved
    await expect(page.getByRole('heading', { name: 'Personal Information' })).toBeVisible();
    await expect(page.getByLabel('First Name')).toHaveValue('Jane');
    await expect(page.getByLabel('Last Name')).toHaveValue('Smith');
  });

  test('should show error for invalid email format', async ({ page }) => {
    await page.goto('/careers/apply');

    // Enter invalid email
    await page.getByLabel('Email').fill('invalid-email');
    await page.getByLabel('First Name').click(); // Trigger validation by clicking elsewhere

    // Verify error message
    await expect(page.getByText('Please enter a valid email address')).toBeVisible();

    // Next button should be disabled
    await expect(page.getByRole('button', { name: 'Next' })).toBeDisabled();
  });
});
```

**Key Concepts Demonstrated:**
- Multi-step form navigation
- `selectOption()` for dropdowns
- `setInputFiles()` for file uploads
- Multiple checkboxes with `check()`
- Form validation and error states
- Data persistence across steps
- Conditional button enabling/disabling

---

### Example 3 – Framework Integration (Next.js): Bloom Workshop Chat Interaction

**Scenario:** Test Melissa AI chat interface in the Bloom workshop, including message input, sending, and response handling.

```typescript
import { test, expect } from '@playwright/test';

test.describe('Bloom Workshop Chat Interface', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to workshop and start a new session
    await page.goto('/workshop');
    await page.getByRole('button', { name: 'Start New Session' }).click();

    // Wait for session to be created
    await expect(page).toHaveURL(/\/workshop\/session\/.+/);
    await expect(page.getByText(/Melissa/i)).toBeVisible();
  });

  test('should send message and receive AI response', async ({ page }) => {
    // STEP 1: Locate chat input (Monaco Editor or textarea)
    const chatInput = page.getByRole('textbox', { name: /message|chat|type/i })
      .or(page.locator('[data-testid="chat-input"]'));

    // Verify input is visible and enabled
    await expect(chatInput).toBeVisible();
    await expect(chatInput).toBeEnabled();

    // STEP 2: Type a message
    const userMessage = 'We want to reduce customer support costs';
    await chatInput.fill(userMessage);

    // Verify the text was entered
    await expect(chatInput).toHaveValue(userMessage);

    // STEP 3: Send the message
    const sendButton = page.getByRole('button', { name: /send|submit/i });
    await expect(sendButton).toBeEnabled();
    await sendButton.click();

    // STEP 4: Verify user message appears in chat
    await expect(page.getByText(userMessage)).toBeVisible({ timeout: 2000 });

    // STEP 5: Wait for AI response
    // Look for typing indicator first
    const typingIndicator = page.getByText(/melissa is typing|thinking/i);
    if (await typingIndicator.isVisible().catch(() => false)) {
      await expect(typingIndicator).toBeVisible();
    }

    // Wait for AI response to appear (may take 5-10 seconds)
    const aiResponse = page.locator('.message-bubble')
      .filter({ has: page.locator('[data-sender="assistant"]') })
      .last();

    await expect(aiResponse).toBeVisible({ timeout: 15000 });

    // Verify response contains expected content
    await expect(aiResponse).toContainText(/customer|support|cost|ROI/i);

    // STEP 6: Verify input is cleared after sending
    await expect(chatInput).toHaveValue('');
    await expect(sendButton).toBeEnabled();
  });

  test('should handle Enter key to send message', async ({ page }) => {
    const chatInput = page.getByRole('textbox', { name: /message|chat/i });

    // Type message
    await chatInput.fill('How do I calculate ROI?');

    // Press Enter to send (without clicking Send button)
    await chatInput.press('Enter');

    // Verify message was sent
    await expect(page.getByText('How do I calculate ROI?')).toBeVisible();

    // Wait for AI response
    await expect(page.locator('.message-bubble').last()).toBeVisible({ timeout: 15000 });
  });

  test('should disable send button when input is empty', async ({ page }) => {
    const chatInput = page.getByRole('textbox', { name: /message|chat/i });
    const sendButton = page.getByRole('button', { name: /send/i });

    // Initially, input is empty, send button should be disabled
    await expect(chatInput).toHaveValue('');
    await expect(sendButton).toBeDisabled();

    // Type some text
    await chatInput.fill('Test message');
    await expect(sendButton).toBeEnabled();

    // Clear the text
    await chatInput.fill('');
    await expect(sendButton).toBeDisabled();
  });

  test('should show message history on page reload', async ({ page }) => {
    // Send a message
    const chatInput = page.getByRole('textbox', { name: /message|chat/i });
    await chatInput.fill('Our team size is 50 people');
    await page.getByRole('button', { name: /send/i }).click();

    // Wait for response
    await expect(page.locator('.message-bubble').last()).toBeVisible({ timeout: 15000 });

    // Get current session URL
    const sessionUrl = page.url();

    // Reload the page
    await page.reload();

    // Verify message history persists
    await expect(page.getByText('Our team size is 50 people')).toBeVisible();

    // Verify session URL is the same
    expect(page.url()).toBe(sessionUrl);
  });

  test('should scroll to bottom when new messages arrive', async ({ page }) => {
    // Send multiple messages to create scrollable content
    for (let i = 1; i <= 5; i++) {
      const chatInput = page.getByRole('textbox', { name: /message|chat/i });
      await chatInput.fill(`Message ${i}: Tell me about workflow automation`);
      await page.getByRole('button', { name: /send/i }).click();

      // Wait a bit between messages
      await page.waitForTimeout(1000);
    }

    // Verify latest message is visible (auto-scrolled to bottom)
    await expect(page.getByText(/Message 5/)).toBeVisible();

    // Verify chat container is scrolled to bottom
    const chatContainer = page.locator('[data-testid="chat-messages"]')
      .or(page.locator('.chat-container'));

    const isAtBottom = await chatContainer.evaluate((el) => {
      return Math.abs(el.scrollHeight - el.scrollTop - el.clientHeight) < 10;
    });

    expect(isAtBottom).toBeTruthy();
  });
});

test.describe('Bloom Session Management', () => {
  test('should create new session with organization details', async ({ page }) => {
    await page.goto('/workshop');

    // Click "New Session" button
    await page.getByRole('button', { name: /new session|start/i }).click();

    // Fill in organization details modal/form
    await page.getByLabel('Organization Name').fill('Acme Corporation');
    await page.getByLabel('Industry').selectOption('Technology');
    await page.getByLabel('Team Size').fill('100');

    // Optional: Select session type (if available)
    const sessionTypeRadio = page.getByLabel('ROI Discovery Workshop');
    if (await sessionTypeRadio.isVisible().catch(() => false)) {
      await sessionTypeRadio.check();
    }

    // Start the session
    await page.getByRole('button', { name: /start|create/i }).click();

    // Verify session created and redirected
    await expect(page).toHaveURL(/\/workshop\/session\/.+/);
    await expect(page.getByText('Acme Corporation')).toBeVisible();
    await expect(page.getByText(/melissa/i)).toBeVisible();
  });

  test('should pause and resume session', async ({ page }) => {
    // Start a session
    await page.goto('/workshop');
    await page.getByRole('button', { name: /start/i }).click();
    await expect(page).toHaveURL(/\/workshop\/session\/.+/);

    // Send a message
    await page.getByRole('textbox').fill('We need automation');
    await page.getByRole('button', { name: /send/i }).click();

    // Wait for response
    await page.waitForTimeout(2000);

    // Pause session
    await page.getByRole('button', { name: /pause|save/i }).click();

    // Verify pause confirmation
    await expect(page.getByText(/paused|saved/i)).toBeVisible();

    // Navigate away
    await page.goto('/workshop');

    // Resume session from list
    const sessionCard = page.locator('.session-card').first();
    await sessionCard.getByRole('button', { name: /resume|continue/i }).click();

    // Verify session resumed with history
    await expect(page).toHaveURL(/\/workshop\/session\/.+/);
    await expect(page.getByText('We need automation')).toBeVisible();
  });
});
```

**Key Concepts Demonstrated:**
- Real Bloom workshop patterns
- Chat input interaction (Monaco Editor or textarea)
- Keyboard events (`press('Enter')`)
- Conditional button states (enabled/disabled based on input)
- Waiting for async AI responses with custom timeouts
- Page reload and state persistence
- Auto-scrolling verification
- Multi-step session creation workflow
- Session pause/resume functionality

---

## 6. Common Pitfalls

### Pitfall 1: Using Non-Web-First Assertions (No Auto-Wait)

**❌ WRONG:**
```typescript
// This does NOT auto-wait! It checks current state immediately.
expect(await page.getByText('Success').isVisible()).toBe(true);
```

**✅ CORRECT:**
```typescript
// This auto-waits up to 5 seconds for element to become visible
await expect(page.getByText('Success')).toBeVisible();
```

**Why:** `isVisible()` returns a boolean immediately without waiting. If the element hasn't appeared yet, the test will fail even though it might appear 1 second later. Web-first assertions (`toBeVisible()`) automatically retry until the condition is met or timeout occurs.

---

### Pitfall 2: Using `waitForTimeout()` Instead of Auto-Waiting

**❌ WRONG:**
```typescript
await page.getByRole('button', { name: 'Save' }).click();
await page.waitForTimeout(2000); // Arbitrary wait
await expect(page.getByText('Saved')).toBeVisible();
```

**✅ CORRECT:**
```typescript
await page.getByRole('button', { name: 'Save' }).click();
// No manual wait needed! Assertion auto-waits for element
await expect(page.getByText('Saved')).toBeVisible();
```

**Why:** `waitForTimeout()` is brittle. If the operation takes 1.5 seconds, you waste 0.5 seconds. If it takes 2.5 seconds, your test fails. Auto-waiting is faster and more reliable.

**Rare Exception:** Only use `waitForTimeout()` for testing time-based UI behaviors (e.g., "notification auto-dismisses after 3 seconds").

---

### Pitfall 3: Force-Clicking Hidden Elements

**❌ WRONG:**
```typescript
// Element is covered by modal, but force-click it anyway
await page.getByRole('button', { name: 'Delete' }).click({ force: true });
```

**✅ CORRECT:**
```typescript
// Close the modal first, then click
await page.getByRole('button', { name: 'Close Modal' }).click();
await page.getByRole('button', { name: 'Delete' }).click();
```

**Why:** `force: true` bypasses actionability checks. It will click even if the element is covered, invisible, or disabled. This masks real bugs where users can't interact with the element.

**Rare Exception:** Testing drag-and-drop or canvas interactions where elements may legitimately overlap.

---

### Pitfall 4: Not Verifying State After Actions

**❌ WRONG:**
```typescript
// Click delete button, but don't verify deletion happened
await page.getByRole('button', { name: 'Delete' }).click();
// Test ends here... did it actually delete?
```

**✅ CORRECT:**
```typescript
// Click delete and verify expected outcome
await page.getByRole('button', { name: 'Delete' }).click();
await expect(page.getByText('Item deleted')).toBeVisible();
await expect(page.getByText('My Item')).not.toBeVisible();
```

**Why:** Just because you clicked a button doesn't mean the action succeeded. Always assert the expected outcome.

---

### Pitfall 5: Incorrect Checkbox/Radio Interaction

**❌ WRONG:**
```typescript
// Trying to click() a checkbox (works, but not semantic)
await page.getByLabel('Accept terms').click();
```

**✅ CORRECT:**
```typescript
// Use check() for checkboxes (more semantic, clearer intent)
await page.getByLabel('Accept terms').check();
```

**Why:** `check()` is idempotent (safe to call multiple times) and expresses intent clearly. `click()` toggles the checkbox, so calling it twice would uncheck it.

**Note:** For radio buttons, use `check()` as well (not `click()`).

---

### Pitfall 6: Not Handling File Uploads Correctly

**❌ WRONG:**
```typescript
// Trying to click file input and type path
await page.getByLabel('Upload').click();
await page.keyboard.type('/path/to/file.pdf');
```

**✅ CORRECT:**
```typescript
// Use setInputFiles() for file uploads
await page.getByLabel('Upload').setInputFiles('/path/to/file.pdf');
```

**Why:** File inputs don't accept keyboard input for security reasons. Use `setInputFiles()` to programmatically select files.

---

### Pitfall 7: Confusing `fill()` vs `type()` vs `pressSequentially()`

| Method | Speed | Use Case |
|--------|-------|----------|
| `fill()` | Instant | Standard form input (RECOMMENDED) |
| `type()` | Slow (deprecated) | ❌ Use `pressSequentially()` instead |
| `pressSequentially()` | Slow (realistic typing) | Testing autocomplete, character limits |

**❌ WRONG:**
```typescript
// Using type() (deprecated in newer Playwright versions)
await page.getByLabel('Email').type('user@example.com');
```

**✅ CORRECT (Fast):**
```typescript
// Use fill() for speed
await page.getByLabel('Email').fill('user@example.com');
```

**✅ CORRECT (Realistic Typing):**
```typescript
// Use pressSequentially() to simulate human typing
await page.getByLabel('Search').pressSequentially('laptop', { delay: 100 });
await expect(page.getByRole('option', { name: 'MacBook' })).toBeVisible();
```

---

### Pitfall 8: Not Using Soft Assertions for Optional Checks

**❌ WRONG:**
```typescript
// Test fails if logo is missing, even if it's not critical
await expect(page.getByAltText('Logo')).toBeVisible();
await expect(page.getByRole('heading')).toBeVisible(); // Never runs if logo fails
```

**✅ CORRECT:**
```typescript
// Logo is optional, don't fail test if missing
await expect.soft(page.getByAltText('Logo')).toBeVisible();
// Test continues even if logo assertion fails
await expect(page.getByRole('heading')).toBeVisible();
```

**Why:** Soft assertions log failures but don't stop test execution. Use for non-critical checks (e.g., optional UI elements, analytics tracking).

---

### Pitfall 9: Hardcoding Timeouts Instead of Using Config

**❌ WRONG:**
```typescript
// Hardcoded timeout in every assertion
await expect(page.getByText('Loading...')).toBeVisible({ timeout: 10000 });
await expect(page.getByText('Data loaded')).toBeVisible({ timeout: 10000 });
```

**✅ CORRECT:**
```typescript
// Set timeout in playwright.config.ts
export default defineConfig({
  expect: {
    timeout: 10000, // Default 10 seconds for all assertions
  },
});

// Then in tests, just use default
await expect(page.getByText('Loading...')).toBeVisible();
await expect(page.getByText('Data loaded')).toBeVisible();
```

**Why:** Centralized configuration makes it easy to adjust timeouts globally. Only override per-assertion when needed.

---

### Pitfall 10: Not Waiting for Navigation After Form Submit

**❌ WRONG:**
```typescript
await page.getByRole('button', { name: 'Submit' }).click();
// Immediately try to assert on new page (may fail due to race condition)
await expect(page.getByText('Success')).toBeVisible();
```

**✅ CORRECT:**
```typescript
await page.getByRole('button', { name: 'Submit' }).click();
// Wait for navigation to complete
await page.waitForURL('/success');
// Now assert on new page
await expect(page.getByText('Success')).toBeVisible();
```

**Alternative (Auto-Wait with Assertion):**
```typescript
await page.getByRole('button', { name: 'Submit' }).click();
// This waits for URL to match pattern
await expect(page).toHaveURL('/success');
await expect(page.getByText('Success')).toBeVisible();
```

**Why:** After clicking submit, the page may navigate. Assertions on the new page may fail if you don't wait for navigation to complete.

---

## 7. AI Pair Programming Notes

### When to Load This File

**Load this file when:**
- Writing or debugging E2E tests that interact with UI elements
- Implementing tests for forms, buttons, inputs, dropdowns, checkboxes
- Troubleshooting flaky tests (likely due to timing/waiting issues)
- Adding assertions to verify UI state or element properties
- Testing Bloom workshop chat, session management, or settings interactions

**Combine with:**
- `02-SELECTORS-LOCATORS.md` - For finding elements before interacting with them
- `QUICK-REFERENCE.md` - For syntax lookup and common patterns
- `01-FUNDAMENTALS.md` - For understanding Playwright's architecture and mental models
- `09-DEBUGGING-TROUBLESHOOTING.md` - When tests fail or behave unexpectedly

### Key Concepts for AI Code Generation

**1. Always Use Web-First Assertions**
```typescript
// ✅ AI should generate this
await expect(page.getByText('Success')).toBeVisible();

// ❌ AI should NEVER generate this
expect(await page.getByText('Success').isVisible()).toBe(true);
```

**2. Trust Auto-Waiting (No Manual Waits)**
```typescript
// ✅ AI should generate this
await page.getByRole('button').click();
await expect(page.getByText('Saved')).toBeVisible();

// ❌ AI should AVOID this
await page.getByRole('button').click();
await page.waitForTimeout(2000);
await expect(page.getByText('Saved')).toBeVisible();
```

**3. Prefer Semantic Selectors**
```typescript
// ✅ AI should prefer this
await page.getByRole('button', { name: 'Submit' }).click();
await page.getByLabel('Email').fill('user@example.com');

// ⚠️ AI should avoid this (brittle)
await page.locator('#submit-btn').click();
await page.locator('input[name="email"]').fill('user@example.com');
```

**4. Always Verify Outcomes**
```typescript
// ✅ AI should include verification
await page.getByRole('button', { name: 'Delete' }).click();
await expect(page.getByText('Deleted successfully')).toBeVisible();

// ❌ AI should NOT stop here
await page.getByRole('button', { name: 'Delete' }).click();
// Missing verification!
```

**5. Use Appropriate Assertion Methods**
```typescript
// ✅ Text content
await expect(page.getByRole('heading')).toHaveText('Dashboard');

// ✅ Input values
await expect(page.getByLabel('Email')).toHaveValue('user@example.com');

// ✅ Element state
await expect(page.getByRole('button')).toBeEnabled();
await expect(page.getByLabel('Accept')).toBeChecked();

// ✅ Visibility
await expect(page.getByText('Success')).toBeVisible();
```

### Common AI Generation Patterns

**Pattern 1: Form Interaction**
```typescript
// AI should generate complete flow with verification
test('should fill form', async ({ page }) => {
  await page.goto('/form');

  // Fill fields
  await page.getByLabel('Name').fill('John Doe');
  await page.getByLabel('Email').fill('john@example.com');

  // Verify values set
  await expect(page.getByLabel('Name')).toHaveValue('John Doe');
  await expect(page.getByLabel('Email')).toHaveValue('john@example.com');

  // Submit
  await page.getByRole('button', { name: 'Submit' }).click();

  // Verify success
  await expect(page.getByText('Form submitted')).toBeVisible();
});
```

**Pattern 2: Multi-Step Workflow**
```typescript
// AI should break down into clear steps with comments
test('should complete workflow', async ({ page }) => {
  // STEP 1: Start workflow
  await page.goto('/workflow');
  await page.getByRole('button', { name: 'Start' }).click();

  // STEP 2: Fill details
  await page.getByLabel('Organization').fill('Acme Corp');
  await page.getByRole('button', { name: 'Next' }).click();

  // STEP 3: Verify completion
  await expect(page).toHaveURL(/\/workflow\/complete/);
  await expect(page.getByText('Workflow completed')).toBeVisible();
});
```

**Pattern 3: Async Operations with Custom Timeout**
```typescript
// AI should recognize slow operations and add custom timeout
test('should wait for slow API response', async ({ page }) => {
  await page.goto('/data');
  await page.getByRole('button', { name: 'Load Data' }).click();

  // AI should add longer timeout for slow operations
  await expect(page.getByText('Data loaded')).toBeVisible({ timeout: 15000 });
});
```

### Debugging Hints for AI

**When test fails with "Element not visible":**
1. Check if element selector is correct (use `02-SELECTORS-LOCATORS.md`)
2. Increase timeout if element takes longer to appear: `{ timeout: 10000 }`
3. Check if element is hidden by CSS or covered by another element
4. Use `page.pause()` to debug interactively

**When test fails with "Element not clickable":**
1. Verify element is not disabled: `await expect(element).toBeEnabled()`
2. Check if element is covered by modal or overlay
3. Ensure element is visible: `await expect(element).toBeVisible()`
4. Try scrolling to element: `await element.scrollIntoViewIfNeeded()`

**When test is flaky (sometimes passes, sometimes fails):**
1. Remove any `waitForTimeout()` calls
2. Use web-first assertions instead of manual waits
3. Check for race conditions (async operations completing at different times)
4. Increase timeout if operation is legitimately slow

### Quick Command Reference

```typescript
// INTERACTIONS
await page.getByRole('button').click();              // Click
await page.getByLabel('Email').fill('text');         // Fill input
await page.getByLabel('Search').pressSequentially('query', { delay: 100 }); // Type with delay
await page.getByLabel('Accept').check();             // Check checkbox
await page.getByLabel('Country').selectOption('US'); // Select dropdown
await page.getByLabel('Upload').setInputFiles('path'); // File upload
await page.getByRole('button').hover();              // Hover
await page.keyboard.press('Enter');                  // Keyboard

// ASSERTIONS
await expect(page.getByText('Success')).toBeVisible();        // Visible
await expect(page.getByRole('button')).toBeEnabled();         // Enabled
await expect(page.getByLabel('Email')).toHaveValue('text');   // Input value
await expect(page.getByRole('heading')).toHaveText('Title');  // Text content
await expect(page.getByLabel('Accept')).toBeChecked();        // Checked
await expect(page).toHaveURL('/success');                     // URL
await expect(page).toHaveTitle(/Page Title/);                 // Page title

// SOFT ASSERTIONS (non-blocking)
await expect.soft(page.getByText('Optional')).toBeVisible();
```

---

## Last Updated

2025-11-14
