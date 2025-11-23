---
id: playwright-framework-integration-patterns
topic: playwright
file_role: framework
profile: full
difficulty_level: intermediate-to-advanced
kb_version: 3.1
prerequisites: [playwright-01-fundamentals]
related_topics: [nextjs, prisma, typescript]
embedding_keywords: [playwright, nextjs, prisma, framework-integration, testing-patterns]
last_reviewed: 2025-11-14
---

# Playwright Framework Integration Patterns

<!-- Query: "How do I test Next.js App Router with Playwright?" -->
<!-- Query: "How to set up per-worker databases for Playwright?" -->
<!-- Query: "How to test authenticated routes in Next.js with Playwright?" -->

## 1. Purpose

Real-world Playwright integration patterns specifically for Next.js 16, Prisma 5.22.0, and TypeScript 5.9.3 projects. This file provides production-ready patterns used in the Bloom project and applicable to similar stacks.

**When to use this file:**
- Integrating Playwright with Next.js App Router
- Setting up database testing with Prisma
- Testing authenticated workflows
- Writing type-safe tests with TypeScript
- Implementing per-worker test isolation

## 2. Next.js Integration

### 2.1 Testing App Router Pages

Next.js 16 App Router introduces server components, client components, and streaming. Testing these requires specific patterns.

#### Example 1 – Pedagogical: Basic App Router Page Test

```typescript
import { test, expect } from '@playwright/test';

test('homepage renders server component', async ({ page }) => {
  await page.goto('/');

  // Server-rendered content appears immediately
  await expect(page.locator('h1')).toHaveText('Welcome to Bloom');

  // Check meta tags (server-side)
  const title = await page.title();
  expect(title).toBe('Bloom - AI ROI Discovery');
});
```

#### Example 2 – Realistic Synthetic: Testing Server + Client Components

```typescript
test('dashboard loads server data and hydrates client components', async ({ page }) => {
  await page.goto('/dashboard');

  // Server-rendered data (appears in HTML source)
  await expect(page.locator('[data-testid="user-name"]')).toHaveText('John Doe');

  // Client component hydration (interactive after JS loads)
  const interactiveButton = page.getByRole('button', { name: 'Start Workshop' });
  await expect(interactiveButton).toBeEnabled();

  // Click triggers client-side interaction
  await interactiveButton.click();
  await expect(page).toHaveURL('/workshop/new');
});
```

#### Example 3 – Framework Integration: Testing Streaming and Suspense

```typescript
test('handles streaming server components', async ({ page }) => {
  await page.goto('/sessions');

  // Loading state appears first (Suspense fallback)
  await expect(page.locator('[data-testid="sessions-loading"]')).toBeVisible();

  // Wait for streamed content to arrive
  await page.waitForLoadState('networkidle');

  // Sessions list appears after streaming completes
  await expect(page.locator('[data-testid="sessions-list"]')).toBeVisible();
  const sessionCount = await page.locator('[data-testid="session-item"]').count();
  expect(sessionCount).toBeGreaterThan(0);
});
```

### 2.2 Testing Server Actions

Server Actions in Next.js 16 are async functions that run on the server. Test them via form submissions and UI interactions.

#### Pattern: Testing Form with Server Action

```typescript
test('submits form via server action', async ({ page }) => {
  await page.goto('/workshop/new');

  // Fill form
  await page.getByLabel('Organization Name').fill('Acme Corp');
  await page.getByLabel('Industry').selectOption('technology');

  // Submit triggers server action
  const submitButton = page.getByRole('button', { name: 'Start Workshop' });
  await submitButton.click();

  // Wait for server action to complete and redirect
  await page.waitForURL('**/workshop/**');

  // Verify data was saved (check UI reflects it)
  await expect(page.getByText('Acme Corp')).toBeVisible();
});
```

#### Pattern: Testing Validation Errors from Server Action

```typescript
test('displays server action validation errors', async ({ page }) => {
  await page.goto('/workshop/new');

  // Submit without required fields
  await page.getByRole('button', { name: 'Start Workshop' }).click();

  // Server action returns errors displayed in UI
  await expect(page.getByText('Organization name is required')).toBeVisible();
  await expect(page.getByText('Industry is required')).toBeVisible();

  // Fix errors
  await page.getByLabel('Organization Name').fill('Test Corp');
  await page.getByLabel('Industry').selectOption('technology');

  // Submit should succeed now
  await page.getByRole('button', { name: 'Start Workshop' }).click();
  await expect(page).toHaveURL(/\/workshop\/.+/);
});
```

### 2.3 Testing API Routes

Next.js App Router API routes are in `app/api/` directory. Test them with the `request` fixture or via UI interactions that call them.

#### Pattern: Direct API Route Testing

```typescript
test('GET /api/sessions returns sessions list', async ({ request }) => {
  const response = await request.get('/api/sessions');

  expect(response.ok()).toBeTruthy();
  expect(response.status()).toBe(200);

  const data = await response.json();
  expect(data).toHaveProperty('sessions');
  expect(Array.isArray(data.sessions)).toBe(true);
});

test('POST /api/sessions creates new session', async ({ request }) => {
  const response = await request.post('/api/sessions', {
    data: {
      organizationName: 'Test Org',
      industry: 'technology',
    },
  });

  expect(response.status()).toBe(201);

  const session = await response.json();
  expect(session).toHaveProperty('id');
  expect(session.organizationName).toBe('Test Org');
});
```

#### Pattern: Testing API Routes via UI

```typescript
test('UI interaction calls API and updates state', async ({ page }) => {
  await page.goto('/sessions');

  // Intercept API request
  const responsePromise = page.waitForResponse('**/api/sessions');

  // Trigger UI action that calls API
  await page.getByRole('button', { name: 'Refresh' }).click();

  // Wait for API response
  const response = await responsePromise;
  expect(response.status()).toBe(200);

  // Verify UI updated with API data
  await expect(page.getByText('Sessions updated')).toBeVisible();
});
```

### 2.4 Testing Route Handlers with Different HTTP Methods

```typescript
test.describe('Session API Route Handlers', () => {
  test('GET retrieves session', async ({ request }) => {
    // Create session first
    const createResponse = await request.post('/api/sessions', {
      data: { organizationName: 'Test', industry: 'tech' },
    });
    const { id } = await createResponse.json();

    // GET the session
    const response = await request.get(`/api/sessions/${id}`);
    expect(response.ok()).toBeTruthy();

    const session = await response.json();
    expect(session.id).toBe(id);
    expect(session.organizationName).toBe('Test');
  });

  test('PATCH updates session', async ({ request }) => {
    // Create session
    const createResponse = await request.post('/api/sessions', {
      data: { organizationName: 'Original', industry: 'tech' },
    });
    const { id } = await createResponse.json();

    // Update session
    const updateResponse = await request.patch(`/api/sessions/${id}`, {
      data: { organizationName: 'Updated' },
    });
    expect(updateResponse.ok()).toBeTruthy();

    // Verify update
    const session = await updateResponse.json();
    expect(session.organizationName).toBe('Updated');
  });

  test('DELETE removes session', async ({ request }) => {
    // Create session
    const createResponse = await request.post('/api/sessions', {
      data: { organizationName: 'ToDelete', industry: 'tech' },
    });
    const { id } = await createResponse.json();

    // Delete session
    const deleteResponse = await request.delete(`/api/sessions/${id}`);
    expect(deleteResponse.ok()).toBeTruthy();

    // Verify deletion
    const getResponse = await request.get(`/api/sessions/${id}`);
    expect(getResponse.status()).toBe(404);
  });
});
```

### 2.5 Testing Middleware and Redirects

```typescript
test('middleware redirects unauthenticated users to login', async ({ page, context }) => {
  // Clear any existing auth state
  await context.clearCookies();

  // Try to access protected route
  await page.goto('/dashboard');

  // Should redirect to login
  await page.waitForURL('**/login**');
  expect(page.url()).toContain('/login');
});

test('middleware allows authenticated users through', async ({ page, context }) => {
  // Set auth cookie/token
  await context.addCookies([{
    name: 'next-auth.session-token',
    value: 'valid-token',
    domain: 'localhost',
    path: '/',
  }]);

  // Access protected route
  await page.goto('/dashboard');

  // Should not redirect
  await expect(page).toHaveURL('**/dashboard');
  await expect(page.locator('h1')).toContainText('Dashboard');
});
```

### 2.6 Testing Dynamic Routes

```typescript
test('dynamic route [id] renders correct session', async ({ page, request }) => {
  // Create session to get real ID
  const response = await request.post('/api/sessions', {
    data: { organizationName: 'Dynamic Test', industry: 'tech' },
  });
  const { id } = await response.json();

  // Navigate to dynamic route
  await page.goto(`/sessions/${id}`);

  // Verify correct data loaded
  await expect(page.locator('[data-testid="session-name"]')).toHaveText('Dynamic Test');
  await expect(page.locator('[data-testid="session-id"]')).toHaveText(id);
});

test('catch-all route [...slug] handles multiple segments', async ({ page }) => {
  await page.goto('/docs/guides/getting-started');

  await expect(page.locator('[data-testid="breadcrumb"]')).toContainText('docs / guides / getting-started');
});
```

---

## 3. Prisma Integration

### 3.1 Per-Worker Database Pattern (Production Pattern)

**Problem:** Multiple Playwright workers running in parallel can cause database conflicts with SQLite.

**Solution:** Each worker gets its own isolated database.

#### Pattern: Per-Worker Database Fixture

```typescript
// fixtures/database.ts
import { test as base, PlaywrightWorkerOptions } from '@playwright/test';
import { PrismaClient } from '@prisma/client';
import { execSync } from 'child_process';
import path from 'path';
import fs from 'fs';

type DatabaseFixtures = {
  db: PrismaClient;
  dbPath: string;
};

export const test = base.extend<{}, DatabaseFixtures>({
  // Worker-scoped fixture (runs once per worker)
  dbPath: [async ({}, use, workerInfo) => {
    const dbDir = path.join(process.cwd(), '.test-dbs');
    if (!fs.existsSync(dbDir)) {
      fs.mkdirSync(dbDir, { recursive: true });
    }

    const dbPath = path.join(dbDir, `test-${workerInfo.workerIndex}.db`);

    // Set environment variable for this worker
    process.env.DATABASE_URL = `file:${dbPath}`;

    // Run migrations
    execSync('npx prisma migrate deploy', {
      env: { ...process.env, DATABASE_URL: `file:${dbPath}` },
    });

    await use(dbPath);

    // Cleanup: Delete worker database
    if (fs.existsSync(dbPath)) {
      fs.unlinkSync(dbPath);
    }
  }, { scope: 'worker' }],

  db: [async ({ dbPath }, use) => {
    const prisma = new PrismaClient({
      datasources: {
        db: { url: `file:${dbPath}` },
      },
    });

    await use(prisma);
    await prisma.$disconnect();
  }, { scope: 'worker' }],
});

export { expect } from '@playwright/test';
```

#### Pattern: Using Per-Worker Database

```typescript
import { test, expect } from './fixtures/database';

test('creates session in isolated database', async ({ db, page }) => {
  // Create data directly in database
  const session = await db.session.create({
    data: {
      organizationName: 'Test Org',
      industry: 'technology',
      status: 'active',
    },
  });

  // Navigate to page that uses this data
  await page.goto(`/sessions/${session.id}`);

  // Verify UI displays database data
  await expect(page.getByText('Test Org')).toBeVisible();
});

test('database is isolated between tests', async ({ db }) => {
  // Each test starts with a clean database
  const count = await db.session.count();
  expect(count).toBe(0); // Always 0 at test start

  // Create data
  await db.session.create({
    data: {
      organizationName: 'Isolated',
      industry: 'tech',
      status: 'active',
    },
  });

  const newCount = await db.session.count();
  expect(newCount).toBe(1);
});
```

### 3.2 Test Fixtures and Factories

Create reusable data factories for consistent test data.

#### Pattern: Prisma Data Factory

```typescript
// fixtures/factories.ts
import { PrismaClient } from '@prisma/client';

export class SessionFactory {
  constructor(private db: PrismaClient) {}

  async createSession(overrides: Partial<Session> = {}) {
    return await this.db.session.create({
      data: {
        organizationName: overrides.organizationName ?? 'Default Org',
        industry: overrides.industry ?? 'technology',
        status: overrides.status ?? 'active',
        createdAt: overrides.createdAt ?? new Date(),
        ...overrides,
      },
    });
  }

  async createSessionWithMessages(messageCount = 3) {
    const session = await this.createSession();

    for (let i = 0; i < messageCount; i++) {
      await this.db.message.create({
        data: {
          sessionId: session.id,
          role: i % 2 === 0 ? 'user' : 'assistant',
          content: `Message ${i + 1}`,
        },
      });
    }

    return session;
  }
}

export class UserFactory {
  constructor(private db: PrismaClient) {}

  async createUser(overrides: Partial<User> = {}) {
    return await this.db.user.create({
      data: {
        email: overrides.email ?? `user${Date.now()}@example.com`,
        name: overrides.name ?? 'Test User',
        ...overrides,
      },
    });
  }
}
```

#### Pattern: Using Factories in Tests

```typescript
import { test, expect } from './fixtures/database';
import { SessionFactory, UserFactory } from './fixtures/factories';

test('displays session with messages', async ({ db, page }) => {
  const factory = new SessionFactory(db);

  // Create session with 5 messages
  const session = await factory.createSessionWithMessages(5);

  // Navigate to session
  await page.goto(`/sessions/${session.id}`);

  // Verify messages appear
  const messages = page.locator('[data-testid="message"]');
  await expect(messages).toHaveCount(5);
});

test('user can create multiple sessions', async ({ db, page }) => {
  const userFactory = new UserFactory(db);
  const sessionFactory = new SessionFactory(db);

  // Create user
  const user = await userFactory.createUser({
    email: 'john@example.com',
    name: 'John Doe',
  });

  // Create sessions for user
  await sessionFactory.createSession({ userId: user.id, organizationName: 'Org 1' });
  await sessionFactory.createSession({ userId: user.id, organizationName: 'Org 2' });
  await sessionFactory.createSession({ userId: user.id, organizationName: 'Org 3' });

  // Navigate to user's sessions
  await page.goto(`/users/${user.id}/sessions`);

  // Verify all sessions appear
  await expect(page.getByText('Org 1')).toBeVisible();
  await expect(page.getByText('Org 2')).toBeVisible();
  await expect(page.getByText('Org 3')).toBeVisible();
});
```

### 3.3 Database Cleanup Strategies

#### Strategy 1: Per-Test Cleanup (Simple)

```typescript
test.afterEach(async ({ db }) => {
  // Delete all data after each test
  await db.message.deleteMany();
  await db.session.deleteMany();
  await db.user.deleteMany();
});
```

#### Strategy 2: Transaction Rollback (Fast, but limited)

```typescript
test('use transaction that rolls back', async ({ db }) => {
  await db.$transaction(async (tx) => {
    // All operations in transaction
    const session = await tx.session.create({
      data: { organizationName: 'Test', industry: 'tech', status: 'active' },
    });

    // Do tests
    expect(session.id).toBeDefined();

    // Transaction automatically rolls back at end of test
    throw new Error('Rollback'); // Forces rollback
  });
});
```

#### Strategy 3: Snapshot and Restore (Advanced)

```typescript
// Save database state before test
test.beforeEach(async ({ dbPath }) => {
  const snapshotPath = `${dbPath}.snapshot`;
  fs.copyFileSync(dbPath, snapshotPath);
});

// Restore database state after test
test.afterEach(async ({ dbPath }) => {
  const snapshotPath = `${dbPath}.snapshot`;
  fs.copyFileSync(snapshotPath, dbPath);
  fs.unlinkSync(snapshotPath);
});
```

### 3.4 Seeding Test Data

```typescript
// fixtures/seed.ts
import { PrismaClient } from '@prisma/client';

export async function seedDatabase(db: PrismaClient) {
  // Create baseline data for all tests
  const organization = await db.organization.create({
    data: {
      name: 'Default Organization',
      industry: 'technology',
    },
  });

  const user = await db.user.create({
    data: {
      email: 'test@example.com',
      name: 'Test User',
      organizationId: organization.id,
    },
  });

  return { organization, user };
}

// Use in tests
test.beforeEach(async ({ db }) => {
  await seedDatabase(db);
});

test('uses seeded data', async ({ db, page }) => {
  // Seeded organization already exists
  const org = await db.organization.findFirst({
    where: { name: 'Default Organization' },
  });

  expect(org).toBeDefined();

  await page.goto('/');
  await expect(page.getByText('Default Organization')).toBeVisible();
});
```

---

## 4. Authentication Integration

### 4.1 NextAuth Testing

#### Pattern: Global Setup for Auth State

```typescript
// global-setup.ts
import { chromium, FullConfig } from '@playwright/test';

async function globalSetup(config: FullConfig) {
  const browser = await chromium.launch();
  const page = await browser.newPage();

  // Navigate to login
  await page.goto('http://localhost:3001/login');

  // Fill credentials
  await page.getByLabel('Email').fill('test@example.com');
  await page.getByLabel('Password').fill('password123');

  // Submit login
  await page.getByRole('button', { name: 'Sign in' }).click();

  // Wait for authentication
  await page.waitForURL('**/dashboard');

  // Save auth state
  await page.context().storageState({ path: '.auth/user.json' });

  await browser.close();
}

export default globalSetup;
```

#### Pattern: Configure in playwright.config.ts

```typescript
export default defineConfig({
  globalSetup: require.resolve('./global-setup'),
  use: {
    // All tests use this auth state by default
    storageState: '.auth/user.json',
  },
});
```

#### Pattern: Testing Unauthenticated State

```typescript
test.use({ storageState: { cookies: [], origins: [] } });

test('unauthenticated user redirects to login', async ({ page }) => {
  await page.goto('/dashboard');

  // Should redirect
  await page.waitForURL('**/login');
  expect(page.url()).toContain('/login');
});
```

### 4.2 Multiple User Roles

```typescript
// Setup multiple auth states
// admin-setup.ts
async function adminSetup() {
  const browser = await chromium.launch();
  const page = await browser.newPage();

  await page.goto('http://localhost:3001/login');
  await page.getByLabel('Email').fill('admin@example.com');
  await page.getByLabel('Password').fill('admin123');
  await page.getByRole('button', { name: 'Sign in' }).click();
  await page.waitForURL('**/admin');

  await page.context().storageState({ path: '.auth/admin.json' });
  await browser.close();
}

// Use in tests
test.describe('Admin Features', () => {
  test.use({ storageState: '.auth/admin.json' });

  test('admin can access admin panel', async ({ page }) => {
    await page.goto('/admin');
    await expect(page.locator('h1')).toHaveText('Admin Panel');
  });
});

test.describe('User Features', () => {
  test.use({ storageState: '.auth/user.json' });

  test('user cannot access admin panel', async ({ page }) => {
    await page.goto('/admin');
    await page.waitForURL('**/forbidden');
  });
});
```

### 4.3 Session Management Testing

```typescript
test('session persists across page reloads', async ({ page }) => {
  await page.goto('/dashboard');

  // Verify logged in
  await expect(page.getByText('Welcome, Test User')).toBeVisible();

  // Reload page
  await page.reload();

  // Session should persist
  await expect(page.getByText('Welcome, Test User')).toBeVisible();
});

test('logout clears session', async ({ page, context }) => {
  await page.goto('/dashboard');

  // Click logout
  await page.getByRole('button', { name: 'Logout' }).click();

  // Should redirect to login
  await page.waitForURL('**/login');

  // Try to access protected route
  await page.goto('/dashboard');

  // Should redirect back to login (no session)
  await page.waitForURL('**/login');
});

test('session expires after timeout', async ({ page }) => {
  await page.goto('/dashboard');

  // Modify session cookie to be expired
  const cookies = await page.context().cookies();
  const sessionCookie = cookies.find(c => c.name.includes('session'));

  if (sessionCookie) {
    await page.context().addCookies([{
      ...sessionCookie,
      expires: Date.now() / 1000 - 3600, // Expired 1 hour ago
    }]);
  }

  // Reload page
  await page.reload();

  // Should redirect to login (expired session)
  await page.waitForURL('**/login');
});
```

---

## 5. TypeScript Integration

### 5.1 Type-Safe Page Objects

```typescript
// page-objects/SessionPage.ts
import { Page, Locator, expect } from '@playwright/test';
import type { Session } from '@prisma/client';

export class SessionPage {
  readonly page: Page;
  readonly sessionName: Locator;
  readonly industry: Locator;
  readonly status: Locator;
  readonly startWorkshopButton: Locator;
  readonly messagesList: Locator;

  constructor(page: Page) {
    this.page = page;
    this.sessionName = page.locator('[data-testid="session-name"]');
    this.industry = page.locator('[data-testid="session-industry"]');
    this.status = page.locator('[data-testid="session-status"]');
    this.startWorkshopButton = page.getByRole('button', { name: 'Start Workshop' });
    this.messagesList = page.locator('[data-testid="messages-list"]');
  }

  async goto(sessionId: string): Promise<void> {
    await this.page.goto(`/sessions/${sessionId}`);
    await this.page.waitForLoadState('networkidle');
  }

  async verifySessionDetails(session: Partial<Session>): Promise<void> {
    if (session.organizationName) {
      await expect(this.sessionName).toHaveText(session.organizationName);
    }
    if (session.industry) {
      await expect(this.industry).toHaveText(session.industry);
    }
    if (session.status) {
      await expect(this.status).toHaveText(session.status);
    }
  }

  async startWorkshop(): Promise<void> {
    await this.startWorkshopButton.click();
    await this.page.waitForURL('**/workshop/**');
  }

  async getMessageCount(): Promise<number> {
    return await this.messagesList.locator('[data-testid="message"]').count();
  }

  async sendMessage(content: string): Promise<void> {
    await this.page.getByLabel('Message').fill(content);
    await this.page.getByRole('button', { name: 'Send' }).click();

    // Wait for message to appear
    await expect(this.messagesList.getByText(content)).toBeVisible();
  }
}
```

#### Using Type-Safe Page Object

```typescript
import { test, expect } from './fixtures/database';
import { SessionPage } from './page-objects/SessionPage';
import { SessionFactory } from './fixtures/factories';

test('session page displays correct data', async ({ page, db }) => {
  const factory = new SessionFactory(db);
  const session = await factory.createSession({
    organizationName: 'TypeScript Corp',
    industry: 'software',
    status: 'active',
  });

  const sessionPage = new SessionPage(page);
  await sessionPage.goto(session.id);

  // Type-safe verification
  await sessionPage.verifySessionDetails(session);

  // Type-safe interactions
  await sessionPage.startWorkshop();
});
```

### 5.2 Typed Fixtures

```typescript
// fixtures/typed-fixtures.ts
import { test as base } from '@playwright/test';
import { SessionPage } from '../page-objects/SessionPage';
import { WorkshopPage } from '../page-objects/WorkshopPage';
import type { Session, User } from '@prisma/client';

type PageFixtures = {
  sessionPage: SessionPage;
  workshopPage: WorkshopPage;
};

type DataFixtures = {
  testSession: Session;
  testUser: User;
};

export const test = base.extend<PageFixtures & DataFixtures>({
  sessionPage: async ({ page }, use) => {
    await use(new SessionPage(page));
  },

  workshopPage: async ({ page }, use) => {
    await use(new WorkshopPage(page));
  },

  testSession: async ({ db }, use) => {
    const factory = new SessionFactory(db);
    const session = await factory.createSession();
    await use(session);

    // Cleanup
    await db.session.delete({ where: { id: session.id } });
  },

  testUser: async ({ db }, use) => {
    const factory = new UserFactory(db);
    const user = await factory.createUser();
    await use(user);

    // Cleanup
    await db.user.delete({ where: { id: user.id } });
  },
});

export { expect } from '@playwright/test';
```

#### Using Typed Fixtures

```typescript
import { test, expect } from './fixtures/typed-fixtures';

test('typed fixtures provide type safety', async ({
  sessionPage,
  workshopPage,
  testSession,
  testUser,
}) => {
  // All fixtures are fully typed
  await sessionPage.goto(testSession.id);

  // TypeScript knows these properties exist
  console.log(testUser.email); // ✅ Type-safe
  console.log(testSession.organizationName); // ✅ Type-safe

  // Type errors caught at compile time
  // console.log(testUser.invalidProp); // ❌ Compile error
});
```

### 5.3 Type-Safe API Testing

```typescript
// types/api.ts
export type CreateSessionRequest = {
  organizationName: string;
  industry: string;
};

export type SessionResponse = {
  id: string;
  organizationName: string;
  industry: string;
  status: string;
  createdAt: string;
};

export type ApiError = {
  error: string;
  message: string;
  statusCode: number;
};

// tests/api/sessions.spec.ts
import { test, expect } from '@playwright/test';
import type { CreateSessionRequest, SessionResponse, ApiError } from '../types/api';

test('POST /api/sessions with type safety', async ({ request }) => {
  const payload: CreateSessionRequest = {
    organizationName: 'TypeScript Test',
    industry: 'technology',
  };

  const response = await request.post('/api/sessions', {
    data: payload,
  });

  expect(response.ok()).toBeTruthy();

  const session = await response.json() as SessionResponse;

  // Type-safe assertions
  expect(session.id).toBeDefined();
  expect(session.organizationName).toBe(payload.organizationName);
  expect(session.industry).toBe(payload.industry);
  expect(session.status).toBe('draft');
});

test('handles API errors with type safety', async ({ request }) => {
  const response = await request.post('/api/sessions', {
    data: {}, // Invalid payload
  });

  expect(response.ok()).toBeFalsy();

  const error = await response.json() as ApiError;

  // Type-safe error handling
  expect(error.error).toBe('validation_error');
  expect(error.message).toContain('required');
  expect(error.statusCode).toBe(400);
});
```

---

## 6. Common Pitfalls

### Pitfall 1: Not Waiting for Hydration

**Problem:**
```typescript
// ❌ WRONG: Clicking before client-side JavaScript loads
test('quick click', async ({ page }) => {
  await page.goto('/');
  await page.getByRole('button', { name: 'Interactive' }).click(); // May fail!
});
```

**Solution:**
```typescript
// ✅ CORRECT: Wait for element to be actionable
test('wait for hydration', async ({ page }) => {
  await page.goto('/');
  await page.waitForLoadState('networkidle'); // Wait for JS to load

  const button = page.getByRole('button', { name: 'Interactive' });
  await expect(button).toBeEnabled(); // Ensures hydration complete
  await button.click();
});
```

### Pitfall 2: Race Conditions with Server Actions

**Problem:**
```typescript
// ❌ WRONG: Not waiting for server action to complete
test('submit form', async ({ page }) => {
  await page.goto('/form');
  await page.getByRole('button', { name: 'Submit' }).click();
  // Immediately check for success message - may not be there yet!
  await expect(page.getByText('Success')).toBeVisible(); // Flaky!
});
```

**Solution:**
```typescript
// ✅ CORRECT: Wait for navigation or network response
test('submit form correctly', async ({ page }) => {
  await page.goto('/form');

  // Option 1: Wait for navigation
  await Promise.all([
    page.waitForURL('**/success'),
    page.getByRole('button', { name: 'Submit' }).click(),
  ]);

  // Option 2: Wait for network request
  const responsePromise = page.waitForResponse('**/api/submit');
  await page.getByRole('button', { name: 'Submit' }).click();
  const response = await responsePromise;
  expect(response.status()).toBe(200);

  await expect(page.getByText('Success')).toBeVisible();
});
```

### Pitfall 3: Database Isolation Issues

**Problem:**
```typescript
// ❌ WRONG: Tests interfere with each other
test('test 1', async ({ page }) => {
  // Creates session in shared database
  await page.goto('/sessions/new');
  // ...
});

test('test 2', async ({ page }) => {
  // Expects empty database, but test 1 left data!
  await page.goto('/sessions');
  const count = await page.locator('.session').count();
  expect(count).toBe(0); // Fails!
});
```

**Solution:**
```typescript
// ✅ CORRECT: Use per-worker databases or cleanup
import { test, expect } from './fixtures/database';

test.afterEach(async ({ db }) => {
  await db.session.deleteMany();
});

test('test 1 with cleanup', async ({ page, db }) => {
  const session = await db.session.create({
    data: { organizationName: 'Test', industry: 'tech', status: 'active' },
  });
  await page.goto(`/sessions/${session.id}`);
  // Test runs in isolation
});

test('test 2 with cleanup', async ({ page, db }) => {
  // Starts with clean database
  const count = await db.session.count();
  expect(count).toBe(0); // ✅ Passes!
});
```

### Pitfall 4: Not Handling Async Params (Next.js 16)

**Problem:**
```typescript
// ❌ WRONG: Assumes params are synchronous
// In Next.js API route
export async function GET(request: NextRequest, { params }: { params: { id: string } }) {
  const { id } = params; // Type error in Next.js 16!
  // ...
}
```

**Solution:**
```typescript
// ✅ CORRECT: Await params Promise
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params; // ✅ Correct for Next.js 16
  // ...
}
```

### Pitfall 5: Hardcoded Timeouts

**Problem:**
```typescript
// ❌ WRONG: Arbitrary wait times
test('wait for data', async ({ page }) => {
  await page.goto('/data');
  await page.waitForTimeout(3000); // Flaky!
  await expect(page.getByText('Data loaded')).toBeVisible();
});
```

**Solution:**
```typescript
// ✅ CORRECT: Wait for specific conditions
test('wait for data correctly', async ({ page }) => {
  await page.goto('/data');

  // Wait for network request
  await page.waitForResponse('**/api/data');

  // Or wait for element
  await expect(page.getByText('Data loaded')).toBeVisible({
    timeout: 10000, // Explicit timeout if needed
  });
});
```

---

## 7. AI Pair Programming Notes

### When to Load This File

Load `FRAMEWORK-INTEGRATION-PATTERNS.md` when:
- Writing tests for Next.js App Router features
- Setting up database testing infrastructure
- Implementing authentication tests
- Need real-world production patterns
- Debugging framework-specific test issues

### Combine With

- **QUICK-REFERENCE.md**: For Playwright syntax
- **01-FUNDAMENTALS.md**: For core concepts
- **06-AUTHENTICATION-STATE.md**: For deeper auth patterns
- **07-DATABASE-FIXTURES.md**: For advanced database patterns
- **11-CONFIG-OPERATIONS.md**: For configuration details

### Common AI Prompts

```
"Using FRAMEWORK-INTEGRATION-PATTERNS.md, set up per-worker database testing for our Next.js 16 + Prisma project."

"Reference FRAMEWORK-INTEGRATION-PATTERNS.md section 2.2. Write a test for a Next.js server action that validates form data."

"Following the patterns in FRAMEWORK-INTEGRATION-PATTERNS.md, create a type-safe page object for our workshop page."

"Use FRAMEWORK-INTEGRATION-PATTERNS.md section 4 to implement NextAuth testing with multiple user roles."
```

### Framework-Specific Best Practices

1. **Next.js 16**: Always await params in dynamic routes
2. **Prisma**: Use per-worker databases for parallel testing
3. **TypeScript**: Leverage type-safe page objects and fixtures
4. **Server Actions**: Wait for navigation or network responses
5. **Authentication**: Use global setup for auth states

---

## Related Files

- **[QUICK-REFERENCE.md](./QUICK-REFERENCE.md)**: Quick syntax lookups
- **[01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md)**: Core Playwright concepts
- **[06-AUTHENTICATION-STATE.md](./06-AUTHENTICATION-STATE.md)**: Auth patterns
- **[07-DATABASE-FIXTURES.md](./07-DATABASE-FIXTURES.md)**: Database patterns
- **[README.md](./README.md)**: Overview
- **[INDEX.md](./INDEX.md)**: Full navigation

---

## Last Updated

2025-11-14
