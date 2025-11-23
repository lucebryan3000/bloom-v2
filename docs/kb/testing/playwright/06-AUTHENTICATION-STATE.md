---
id: playwright-06-authentication-state
topic: playwright
file_role: practical
profile: full
difficulty_level: intermediate-to-advanced
kb_version: 3.1
prerequisites: [playwright-01-fundamentals]
related_topics: [authentication, session-management, cookies]
embedding_keywords: [playwright, authentication, session, cookies, storageState, auth-testing, nextauth, jwt, session-testing]
last_reviewed: 2025-11-14
---

# Playwright Authentication & State Management

**Part 6 of 11 - The Playwright Knowledge Base**

<!-- Query Pattern: playwright authentication, session management, auth state -->
<!-- Query Pattern: nextauth testing, jwt testing, cookie authentication -->
<!-- Query Pattern: storageState, global setup auth, authenticated tests -->

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

Master authentication testing, session state management, and multi-user scenarios in Playwright for the Bloom application.

**What You'll Learn:**

- **Global auth setup** with `storageState` for test speed optimization
- **NextAuth v4 testing patterns** (JWT strategy, session cookies)
- **Bloom's editKey cookie pattern** for session-level edit permissions
- **Multi-role testing** (user, admin, super_admin, viewer)
- **Session persistence** validation and cross-tab synchronization
- **Cookie manipulation** for auth state control
- **Testing unauthenticated flows** and auth failures

**Why This Matters:**

- **Performance**: Reusing auth state saves 5-10 seconds per test
- **Reliability**: Consistent auth setup prevents flaky tests
- **Coverage**: Test role-based permissions and session edge cases
- **Security**: Validate auth boundaries and session expiration

**Bloom-Specific Context:**

Bloom uses **two authentication layers**:

1. **User Authentication**: NextAuth v4 with JWT strategy (30-day sessions)
2. **Session Edit Rights**: HMAC-signed `editKey` cookies (browser-based permissions)

This guide covers testing both layers.

---

## 2. Mental Model / Problem Statement

### The Authentication Testing Challenge

**Problem:**

Every E2E test that requires authentication must:
1. Navigate to login page
2. Fill email/password fields
3. Click submit
4. Wait for redirect
5. Verify auth success

**This takes 5-10 seconds per test.** With 50 tests, you waste 4-8 minutes just logging in.

**Solution: Authentication State Reuse**

```typescript
// ❌ SLOW: Login in every test (5-10s per test)
test('view sessions', async ({ page }) => {
  await page.goto('/auth/signin');
  await page.getByLabel('Email').fill('admin@bloom.test');
  await page.getByLabel('Password').fill('SecurePass123!');
  await page.getByRole('button', { name: 'Sign In' }).click();
  await page.waitForURL('/workshop');

  // Now test starts...
});

// ✅ FAST: Reuse stored auth state (instant)
test('view sessions', async ({ page }) => {
  // Already authenticated via global setup
  await page.goto('/sessions');

  // Test starts immediately
});
```

### Playwright's storageState Mechanism

**How It Works:**

```typescript
// 1. Global Setup: Login once, save auth state
async function globalSetup() {
  const browser = await chromium.launch();
  const page = await browser.newPage();

  await page.goto('/auth/signin');
  await page.getByLabel('Email').fill('admin@bloom.test');
  await page.getByLabel('Password').fill('SecurePass123!');
  await page.getByRole('button', { name: 'Sign In' }).click();
  await page.waitForURL('/workshop');

  // Save cookies + localStorage + sessionStorage
  await page.context().storageState({ path: 'auth-states/admin.json' });

  await browser.close();
}

// 2. Tests: Load auth state before each test
test.use({ storageState: 'auth-states/admin.json' });

test('test runs with admin auth', async ({ page }) => {
  // Already has admin cookies/localStorage
});
```

**What Gets Saved:**

```json
{
  "cookies": [
    {
      "name": "next-auth.session-token",
      "value": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "domain": "localhost",
      "path": "/",
      "expires": 1735660800,
      "httpOnly": true,
      "secure": false,
      "sameSite": "Lax"
    },
    {
      "name": "bloom-editKey-abc123",
      "value": "550e8400-e29b-41d4-a716-446655440000.a3f2b9c8",
      "domain": "localhost",
      "path": "/",
      "httpOnly": true,
      "sameSite": "Strict"
    }
  ],
  "origins": [
    {
      "origin": "http://localhost:3001",
      "localStorage": [
        { "name": "theme", "value": "dark" }
      ],
      "sessionStorage": []
    }
  ]
}
```

### Bloom's Dual Authentication Model

**Layer 1: User Authentication (NextAuth JWT)**

```typescript
// User Session (lib/auth/config.ts)
interface UserSession {
  user: {
    id: string;
    email: string;
    name: string;
    role: 'user' | 'admin' | 'super_admin' | 'viewer';
    organizationId: string;
    permissions: string[];
  };
  expires: string; // 30 days
}

// Cookie: next-auth.session-token
// Strategy: JWT (stateless)
// Expiry: 30 days
// Refresh: 24 hours
```

**Layer 2: Session Edit Rights (HMAC editKey)**

```typescript
// EditKey Cookie (lib/utils/session-auth.ts)
// Format: <uuid>.<signature>
// Example: "550e8400-e29b-41d4-a716-446655440000.a3f2b9c8"

// Cookie: bloom-editKey-{sessionId}
// Strategy: HMAC-signed UUID
// Expiry: Session lifetime (no expiration)
// Scope: Specific session only
```

**Why Two Layers?**

1. **User Auth**: Controls app access and organization scope
2. **Session Edit**: Controls who can modify a specific workshop session

**Test Implication:**

You must test BOTH authenticated users AND editKey holders:

```typescript
// Scenario 1: Authenticated user WITH editKey (session creator)
test('creator can edit session', async ({ page }) => {
  // Has both: next-auth.session-token + bloom-editKey-{id}
});

// Scenario 2: Authenticated user WITHOUT editKey (viewer)
test('viewer cannot edit session', async ({ page }) => {
  // Has only: next-auth.session-token
  // Lacks: bloom-editKey-{id}
});

// Scenario 3: Unauthenticated user (public share link)
test('anonymous can view shared session', async ({ page }) => {
  // No auth cookies, but has share link token
});
```

---

## 3. Golden Path

### Pattern 1: Global Setup for Auth State

**File: `tests/setup/global-auth-setup.ts`**

```typescript
import { chromium, FullConfig } from '@playwright/test';
import fs from 'fs/promises';
import path from 'path';

/**
 * Global Authentication Setup
 *
 * Runs ONCE before all tests to create auth states for different user roles.
 * Saves storageState JSON files for reuse across tests.
 */
async function globalAuthSetup(config: FullConfig) {
  const baseURL = config.projects[0].use.baseURL || 'http://localhost:3001';
  const authDir = path.join(process.cwd(), 'tests/fixtures/auth-states');

  // Ensure auth directory exists
  await fs.mkdir(authDir, { recursive: true });

  console.log('🔐 Setting up authentication states...');

  // Setup 1: Admin User
  await setupAuthState({
    baseURL,
    email: 'admin@bloom.test',
    password: 'AdminPass123!',
    outputPath: path.join(authDir, 'admin.json'),
    label: 'Admin',
  });

  // Setup 2: Regular User
  await setupAuthState({
    baseURL,
    email: 'user@bloom.test',
    password: 'UserPass123!',
    outputPath: path.join(authDir, 'user.json'),
    label: 'User',
  });

  // Setup 3: Viewer (Read-Only)
  await setupAuthState({
    baseURL,
    email: 'viewer@bloom.test',
    password: 'ViewerPass123!',
    outputPath: path.join(authDir, 'viewer.json'),
    label: 'Viewer',
  });

  console.log('✅ Authentication states ready\n');
}

interface AuthSetupOptions {
  baseURL: string;
  email: string;
  password: string;
  outputPath: string;
  label: string;
}

async function setupAuthState(options: AuthSetupOptions): Promise<void> {
  const { baseURL, email, password, outputPath, label } = options;

  const browser = await chromium.launch();
  const context = await browser.newContext();
  const page = await context.newPage();

  try {
    // 1. Navigate to login page
    await page.goto(`${baseURL}/auth/signin`);

    // 2. Fill credentials
    await page.getByLabel('Email').fill(email);
    await page.getByLabel('Password').fill(password);

    // 3. Submit login form
    await page.getByRole('button', { name: 'Sign In' }).click();

    // 4. Wait for redirect to workshop (successful auth)
    await page.waitForURL(/\/(workshop|sessions)/);

    // 5. Verify auth cookie exists
    const cookies = await context.cookies();
    const authCookie = cookies.find(c => c.name === 'next-auth.session-token');

    if (!authCookie) {
      throw new Error(`${label}: Auth cookie not found after login`);
    }

    // 6. Save storage state (cookies + localStorage + sessionStorage)
    await context.storageState({ path: outputPath });

    console.log(`✅ ${label} auth state saved`);

  } catch (error) {
    console.error(`❌ ${label} auth setup failed:`, error);
    throw error;
  } finally {
    await browser.close();
  }
}

export default globalAuthSetup;
```

**Configuration: `playwright.config.ts`**

```typescript
export default defineConfig({
  // Run global auth setup before tests
  globalSetup: require.resolve('./tests/setup/global-auth-setup'),

  // Define projects for different auth states
  projects: [
    {
      name: 'authenticated-admin',
      use: {
        storageState: 'tests/fixtures/auth-states/admin.json',
      },
    },
    {
      name: 'authenticated-user',
      use: {
        storageState: 'tests/fixtures/auth-states/user.json',
      },
    },
    {
      name: 'unauthenticated',
      use: {
        storageState: { cookies: [], origins: [] }, // Empty state
      },
    },
  ],
});
```

### Pattern 2: Testing with Auth State

**File: `tests/sessions/list.spec.ts`**

```typescript
import { test, expect } from '@playwright/test';

// All tests in this file run as authenticated admin
test.use({ storageState: 'tests/fixtures/auth-states/admin.json' });

test.describe('Session List (Admin)', () => {
  test('should display all sessions', async ({ page }) => {
    await page.goto('/sessions');

    // No login needed - already authenticated via storageState
    await expect(page.getByRole('heading', { name: 'Sessions' })).toBeVisible();

    // Verify user info displayed
    await expect(page.getByText('admin@bloom.test')).toBeVisible();
  });

  test('should allow creating new session', async ({ page }) => {
    await page.goto('/sessions');

    const createButton = page.getByRole('button', { name: 'New Session' });
    await expect(createButton).toBeVisible();
    await expect(createButton).toBeEnabled();
  });
});
```

### Pattern 3: Testing Bloom's EditKey Cookie

**File: `tests/sessions/edit-permissions.spec.ts`**

```typescript
import { test, expect } from '@playwright/test';
import { generateSignedUUID } from '@/lib/utils/session-auth';

test.describe('Session Edit Permissions', () => {
  test.use({ storageState: 'tests/fixtures/auth-states/admin.json' });

  test('session creator can edit (has editKey)', async ({ page, context }) => {
    // 1. Create new session (receives editKey cookie automatically)
    await page.goto('/workshop');
    await page.getByRole('button', { name: 'Start New Session' }).click();
    await page.getByLabel('Organization Name').fill('Test Corp');
    await page.getByRole('button', { name: 'Begin Workshop' }).click();

    // 2. Extract session ID from URL
    await page.waitForURL(/\/workshop\/session\/([a-zA-Z0-9_-]+)/);
    const sessionId = page.url().match(/\/session\/([a-zA-Z0-9_-]+)/)?.[1];
    expect(sessionId).toBeDefined();

    // 3. Verify editKey cookie exists for this session
    const cookies = await context.cookies();
    const editKeyCookie = cookies.find(c => c.name === `bloom-editKey-${sessionId}`);
    expect(editKeyCookie).toBeDefined();
    expect(editKeyCookie!.httpOnly).toBe(true);
    expect(editKeyCookie!.sameSite).toBe('Strict');

    // 4. Verify can edit session
    const editButton = page.getByRole('button', { name: 'Edit Context' });
    await expect(editButton).toBeVisible();
    await expect(editButton).toBeEnabled();
  });

  test('viewer cannot edit (lacks editKey)', async ({ page, context }) => {
    // 1. Create session as admin
    const sessionId = await createSession(page);

    // 2. Remove editKey cookie (simulate different user viewing session)
    await context.clearCookies();

    // 3. Restore user auth but NOT editKey
    await context.addCookies(
      JSON.parse(
        await fs.readFile('tests/fixtures/auth-states/user.json', 'utf-8')
      ).cookies.filter((c: any) => !c.name.startsWith('bloom-editKey-'))
    );

    // 4. Visit session as viewer
    await page.goto(`/workshop/session/${sessionId}`);

    // 5. Verify edit controls are disabled
    const editButton = page.getByRole('button', { name: 'Edit Context' });
    await expect(editButton).not.toBeVisible(); // Hidden for viewers

    // 6. Verify read-only mode indicator
    await expect(page.getByText('Read-only view')).toBeVisible();
  });

  test('editKey tampering detected', async ({ page, context }) => {
    // 1. Create session
    const sessionId = await createSession(page);

    // 2. Get original editKey cookie
    const cookies = await context.cookies();
    const originalCookie = cookies.find(c => c.name === `bloom-editKey-${sessionId}`)!;

    // 3. Tamper with editKey (change signature)
    await context.addCookies([{
      ...originalCookie,
      value: originalCookie.value.replace(/\.[a-f0-9]+$/, '.FAKESIGNATURE'),
    }]);

    // 4. Attempt edit operation
    await page.goto(`/workshop/session/${sessionId}`);
    await page.getByRole('button', { name: 'Edit Context' }).click();

    // 5. Expect 403 Forbidden
    await expect(page.getByText('Permission denied')).toBeVisible();
  });
});

async function createSession(page: Page): Promise<string> {
  await page.goto('/workshop');
  await page.getByRole('button', { name: 'Start New Session' }).click();
  await page.getByLabel('Organization Name').fill('Test Corp');
  await page.getByRole('button', { name: 'Begin Workshop' }).click();
  await page.waitForURL(/\/workshop\/session\/([a-zA-Z0-9_-]+)/);
  return page.url().match(/\/session\/([a-zA-Z0-9_-]+)/)?.[1]!;
}
```

### Pattern 4: Testing Multiple User Roles

**File: `tests/admin/permissions.spec.ts`**

```typescript
import { test, expect } from '@playwright/test';

test.describe('Role-Based Permissions', () => {
  test('admin can access admin panel', async ({ page }) => {
    // Use admin auth state
    await page.goto('/settings', {
      storageState: 'tests/fixtures/auth-states/admin.json',
    });

    await expect(page.getByRole('heading', { name: 'Settings' })).toBeVisible();
    await expect(page.getByRole('tab', { name: 'Monitoring' })).toBeVisible();
  });

  test('regular user cannot access admin panel', async ({ page }) => {
    // Use user auth state
    await page.goto('/settings', {
      storageState: 'tests/fixtures/auth-states/user.json',
    });

    // Expect redirect or 403 error
    await expect(page.getByText('Access Denied')).toBeVisible();
  });

  test('viewer has read-only access', async ({ page }) => {
    await page.goto('/sessions', {
      storageState: 'tests/fixtures/auth-states/viewer.json',
    });

    // Can view sessions
    await expect(page.getByRole('heading', { name: 'Sessions' })).toBeVisible();

    // Cannot create sessions
    const createButton = page.getByRole('button', { name: 'New Session' });
    await expect(createButton).toBeDisabled();
  });
});
```

---

## 4. Variations & Trade-Offs

### Approach 1: Global Setup (Recommended)

**When to Use:**
- Most tests require authentication
- Multiple test files need same auth state
- Want maximum performance (login once, reuse everywhere)

**Pros:**
- **Fastest**: Login once in global setup, reuse across all tests
- **Consistent**: All tests use same auth state
- **Simple**: No per-test login logic

**Cons:**
- **Initial setup complexity**: Requires global setup file
- **Stale state**: If auth changes, must regenerate auth state files
- **Debugging**: Harder to debug auth issues (state is pre-generated)

**Implementation:**

```typescript
// playwright.config.ts
export default defineConfig({
  globalSetup: './tests/setup/global-auth-setup.ts',
  projects: [
    {
      name: 'authenticated',
      use: { storageState: 'auth-states/admin.json' },
    },
  ],
});

// tests/example.spec.ts
test('runs with global auth', async ({ page }) => {
  // Already authenticated
});
```

### Approach 2: Per-Test Login (Flexibility)

**When to Use:**
- Testing login flow itself
- Need fresh auth state per test
- Testing auth expiration or session refresh

**Pros:**
- **Flexible**: Each test controls its own auth
- **Isolated**: Test failures don't affect other tests
- **Explicit**: Clear what auth state each test uses

**Cons:**
- **Slow**: 5-10 seconds per test for login
- **Repetitive**: Same login code in every test
- **Flaky**: Network issues during login can fail tests

**Implementation:**

```typescript
test('fresh login per test', async ({ page }) => {
  // Login for this test only
  await page.goto('/auth/signin');
  await page.getByLabel('Email').fill('admin@bloom.test');
  await page.getByLabel('Password').fill('SecurePass123!');
  await page.getByRole('button', { name: 'Sign In' }).click();
  await page.waitForURL('/workshop');

  // Now test starts
});
```

### Approach 3: Fixture-Based Auth (Hybrid)

**When to Use:**
- Want flexibility of per-test auth with DRY code
- Need different auth states in same test file
- Testing multi-user scenarios

**Pros:**
- **DRY**: Login logic centralized in fixture
- **Flexible**: Can use different auth states per test
- **Reusable**: Share auth logic across test files

**Cons:**
- **Slower than global**: Still logs in per test
- **Setup complexity**: Requires fixture definition

**Implementation:**

```typescript
// tests/fixtures/auth.ts
import { test as base } from '@playwright/test';

export const test = base.extend({
  adminPage: async ({ page }, use) => {
    // Login as admin
    await page.goto('/auth/signin');
    await page.getByLabel('Email').fill('admin@bloom.test');
    await page.getByLabel('Password').fill('AdminPass123!');
    await page.getByRole('button', { name: 'Sign In' }).click();
    await page.waitForURL('/workshop');

    await use(page);
  },

  userPage: async ({ page }, use) => {
    // Login as user
    await page.goto('/auth/signin');
    await page.getByLabel('Email').fill('user@bloom.test');
    await page.getByLabel('Password').fill('UserPass123!');
    await page.getByRole('button', { name: 'Sign In' }).click();
    await page.waitForURL('/workshop');

    await use(page);
  },
});

// tests/example.spec.ts
import { test } from './fixtures/auth';

test('admin can access settings', async ({ adminPage }) => {
  await adminPage.goto('/settings');
  // adminPage is already authenticated as admin
});

test('user cannot access settings', async ({ userPage }) => {
  await userPage.goto('/settings');
  // userPage is authenticated as regular user
});
```

### Approach 4: API-Based Auth (Advanced)

**When to Use:**
- NextAuth API supports programmatic login
- Want to skip UI login form
- Need to set up complex auth scenarios

**Pros:**
- **Fastest**: Direct API call (no UI interaction)
- **Reliable**: No UI flakiness
- **Flexible**: Can set custom JWT claims

**Cons:**
- **Couples to API**: Breaks if API changes
- **Less realistic**: Doesn't test login UI
- **Setup complexity**: Requires API endpoint access

**Implementation:**

```typescript
test('API-based login', async ({ page, request }) => {
  // 1. Login via API
  const response = await request.post('/api/auth/callback/credentials', {
    data: {
      email: 'admin@bloom.test',
      password: 'AdminPass123!',
      callbackUrl: '/workshop',
    },
  });

  // 2. Extract session cookie from response
  const cookies = response.headers()['set-cookie'];
  const sessionToken = cookies
    .split(';')
    .find((c: string) => c.includes('next-auth.session-token'));

  // 3. Set cookie in browser context
  await page.context().addCookies([{
    name: 'next-auth.session-token',
    value: sessionToken.split('=')[1],
    domain: 'localhost',
    path: '/',
  }]);

  // 4. Now page requests will be authenticated
  await page.goto('/sessions');
});
```

---

## 5. Examples

### Example 1: Testing Session Persistence

**Scenario:** Verify auth session persists across page reloads and navigation

```typescript
test('session persists across navigation', async ({ page, context }) => {
  test.use({ storageState: 'tests/fixtures/auth-states/admin.json' });

  // 1. Navigate to protected page
  await page.goto('/sessions');
  await expect(page.getByText('admin@bloom.test')).toBeVisible();

  // 2. Reload page
  await page.reload();
  await expect(page.getByText('admin@bloom.test')).toBeVisible();

  // 3. Navigate to different page
  await page.goto('/workshop');
  await expect(page.getByText('admin@bloom.test')).toBeVisible();

  // 4. Verify session cookie still valid
  const cookies = await context.cookies();
  const sessionCookie = cookies.find(c => c.name === 'next-auth.session-token');
  expect(sessionCookie).toBeDefined();
  expect(new Date(sessionCookie!.expires * 1000)).toBeGreaterThan(new Date());
});
```

### Example 2: Testing Session Expiration

**Scenario:** Verify expired sessions redirect to login

```typescript
test('expired session redirects to login', async ({ page, context }) => {
  // 1. Set expired session cookie
  await context.addCookies([{
    name: 'next-auth.session-token',
    value: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.EXPIRED',
    domain: 'localhost',
    path: '/',
    expires: Math.floor(Date.now() / 1000) - 3600, // 1 hour ago
    httpOnly: true,
    sameSite: 'Lax',
  }]);

  // 2. Attempt to access protected page
  await page.goto('/sessions');

  // 3. Expect redirect to login
  await page.waitForURL('/auth/signin');
  await expect(page.getByText('Session expired')).toBeVisible();
});
```

### Example 3: Testing 2FA Flow

**Scenario:** Test two-factor authentication with TOTP code

```typescript
test('2FA login flow', async ({ page }) => {
  // 1. Login with email/password
  await page.goto('/auth/signin');
  await page.getByLabel('Email').fill('admin@bloom.test');
  await page.getByLabel('Password').fill('AdminPass123!');
  await page.getByRole('button', { name: 'Sign In' }).click();

  // 2. Expect 2FA prompt
  await expect(page.getByText('Enter 2FA Code')).toBeVisible();

  // 3. Generate TOTP code (using test secret)
  const totp = generateTOTP('JBSWY3DPEHPK3PXP'); // Test 2FA secret

  // 4. Enter TOTP code
  await page.getByLabel('Authentication Code').fill(totp);
  await page.getByRole('button', { name: 'Verify' }).click();

  // 5. Expect successful login
  await page.waitForURL('/workshop');
  await expect(page.getByText('admin@bloom.test')).toBeVisible();
});

function generateTOTP(secret: string): string {
  const speakeasy = require('speakeasy');
  return speakeasy.totp({
    secret,
    encoding: 'base32',
  });
}
```

### Example 4: Testing Multi-Tab Session Sync

**Scenario:** Verify logout in one tab logs out all tabs

```typescript
test('logout syncs across tabs', async ({ browser }) => {
  const context = await browser.newContext({
    storageState: 'tests/fixtures/auth-states/admin.json',
  });

  // 1. Open two tabs
  const page1 = await context.newPage();
  const page2 = await context.newPage();

  await page1.goto('/sessions');
  await page2.goto('/workshop');

  // 2. Verify both tabs authenticated
  await expect(page1.getByText('admin@bloom.test')).toBeVisible();
  await expect(page2.getByText('admin@bloom.test')).toBeVisible();

  // 3. Logout from first tab
  await page1.getByRole('button', { name: 'Profile' }).click();
  await page1.getByRole('menuitem', { name: 'Sign Out' }).click();

  // 4. Verify first tab redirected to login
  await page1.waitForURL('/auth/signin');

  // 5. Reload second tab - should also redirect to login
  await page2.reload();
  await page2.waitForURL('/auth/signin');

  await context.close();
});
```

---

## 6. Common Pitfalls

### Pitfall 1: Forgetting to Set storageState

**Problem:**

```typescript
// ❌ WRONG: Test expects auth but doesn't set storageState
test('view sessions', async ({ page }) => {
  await page.goto('/sessions');
  // Page redirects to /auth/signin because no auth cookies
  await expect(page.getByRole('heading', { name: 'Sessions' })).toBeVisible();
  // ❌ FAILS: Heading not found, on login page instead
});
```

**Solution:**

```typescript
// ✅ CORRECT: Set storageState for authenticated tests
test.use({ storageState: 'tests/fixtures/auth-states/admin.json' });

test('view sessions', async ({ page }) => {
  await page.goto('/sessions');
  await expect(page.getByRole('heading', { name: 'Sessions' })).toBeVisible();
  // ✅ PASSES: Already authenticated
});
```

### Pitfall 2: Stale Auth State Files

**Problem:**

Auth state files generated yesterday may have expired JWT tokens today.

```typescript
// ❌ WRONG: Using stale auth state from days ago
test.use({ storageState: 'auth-states/admin.json' }); // Generated 5 days ago

test('view sessions', async ({ page }) => {
  await page.goto('/sessions');
  // Session expired, redirects to login
});
```

**Solution:**

Regenerate auth states in global setup (runs before every test run):

```typescript
// ✅ CORRECT: Global setup regenerates fresh auth states
export default defineConfig({
  globalSetup: './tests/setup/global-auth-setup.ts', // Runs before tests
  projects: [
    {
      name: 'authenticated',
      use: { storageState: 'auth-states/admin.json' }, // Fresh state
    },
  ],
});
```

### Pitfall 3: Cookie Domain Mismatch

**Problem:**

Auth cookies set for `localhost` don't work when testing against `127.0.0.1`.

```typescript
// ❌ WRONG: Cookie domain mismatch
// Cookie set for: localhost
// Testing against: 127.0.0.1
await page.goto('http://127.0.0.1:3001/sessions');
// Auth fails because cookie domain doesn't match
```

**Solution:**

Use consistent domain in auth setup and tests:

```typescript
// ✅ CORRECT: Consistent domain
const baseURL = 'http://localhost:3001'; // Use same domain everywhere

// In global setup
await page.goto(`${baseURL}/auth/signin`);

// In tests
await page.goto('/sessions'); // Uses baseURL from config
```

### Pitfall 4: Testing Login UI with storageState

**Problem:**

Can't test login flow if already authenticated via storageState.

```typescript
// ❌ WRONG: Testing login while already logged in
test.use({ storageState: 'auth-states/admin.json' });

test('login with invalid password shows error', async ({ page }) => {
  await page.goto('/auth/signin');
  // Redirects to /workshop because already logged in
  // Can't test login UI
});
```

**Solution:**

Use empty storageState for login tests:

```typescript
// ✅ CORRECT: Empty auth state for login tests
test.use({ storageState: { cookies: [], origins: [] } });

test('login with invalid password shows error', async ({ page }) => {
  await page.goto('/auth/signin');
  await page.getByLabel('Email').fill('admin@bloom.test');
  await page.getByLabel('Password').fill('WrongPassword');
  await page.getByRole('button', { name: 'Sign In' }).click();

  await expect(page.getByText('Invalid credentials')).toBeVisible();
});
```

### Pitfall 5: Not Waiting for Auth Redirect

**Problem:**

Login succeeds but test continues before redirect completes.

```typescript
// ❌ WRONG: Not waiting for redirect
await page.getByRole('button', { name: 'Sign In' }).click();
// Test continues immediately, but redirect hasn't happened yet
await expect(page.getByRole('heading', { name: 'Sessions' })).toBeVisible();
// ❌ FAILS: Still on login page
```

**Solution:**

Wait for URL change after login:

```typescript
// ✅ CORRECT: Wait for redirect
await page.getByRole('button', { name: 'Sign In' }).click();
await page.waitForURL(/\/(workshop|sessions)/); // Wait for redirect
await expect(page.getByRole('heading', { name: 'Sessions' })).toBeVisible();
// ✅ PASSES: On correct page
```

---

## 7. AI Pair Programming Notes

**When to Load This File:**

- User asks: "How do I test authentication in Playwright?"
- User asks: "How to handle NextAuth in E2E tests?"
- User asks: "How to test multiple user roles?"
- User asks: "How to reuse auth state across tests?"
- User mentions: `storageState`, session cookies, JWT testing

**Key Bloom Patterns to Remember:**

1. **Dual Auth Model**: NextAuth JWT (user) + HMAC editKey (session)
2. **Global Setup**: Generate fresh auth states before tests
3. **Role Testing**: admin, user, super_admin, viewer
4. **Cookie Validation**: Test editKey signature verification

**Related Files:**

- `lib/auth/config.ts` - NextAuth configuration
- `lib/utils/session-auth.ts` - EditKey generation/validation
- `tests/setup/global-auth-setup.ts` - Auth state generation
- `playwright.config.ts` - Project configuration

**Common Tasks:**

1. **Add new user role to tests:**
   - Add role to `global-auth-setup.ts`
   - Create test user in database seed
   - Add project in `playwright.config.ts`

2. **Test session edit permissions:**
   - Create session (gets editKey)
   - Clear cookies, restore user auth (simulate viewer)
   - Verify edit controls hidden

3. **Test auth expiration:**
   - Set expired cookie with `context.addCookies()`
   - Navigate to protected page
   - Verify redirect to `/auth/signin`

**Performance Optimization:**

```typescript
// Fast: 50 tests × 0.1s = 5 seconds
test.use({ storageState: 'auth-states/admin.json' });

// Slow: 50 tests × 5s = 250 seconds
test.beforeEach(async ({ page }) => {
  await loginViaUI(page); // 5 seconds per test
});
```

**Decision Tree:**

```
Need auth in tests?
├─ Yes, most tests need auth
│  └─ Use: Global Setup + storageState (Pattern 1)
├─ Testing login UI itself
│  └─ Use: Empty storageState (Pitfall 4)
├─ Need multiple roles in one test
│  └─ Use: Fixture-Based Auth (Approach 3)
└─ Testing auth expiration
   └─ Use: Per-Test Cookie Manipulation (Example 2)
```

---

## Last Updated

2025-11-14 - Comprehensive Bloom authentication patterns added
