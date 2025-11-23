---
id: playwright-08-parallel-isolation
topic: playwright
file_role: advanced
profile: full
difficulty_level: advanced
kb_version: 3.1
prerequisites: [playwright-01-fundamentals, playwright-07-database-fixtures]
related_topics: [parallel-testing, test-isolation, workers]
embedding_keywords: [playwright, parallel, workers, test-isolation, per-worker-database]
last_reviewed: 2025-11-14
---

# Parallel Execution & Test Isolation

## 1. Purpose

Master parallel test execution, worker isolation, and per-worker databases.

## 2. Mental Model / Problem Statement

<!-- Query Pattern: playwright parallelism, test isolation, worker processes -->
<!-- Query Pattern: parallel testing strategy, test interference, shared state -->

### 2.1 The Parallelism Challenge

**The Problem:**

E2E tests are slow. A typical Bloom workshop test might take 15-30 seconds:
- Navigate to page (~1s)
- Fill form fields (~2s)
- Wait for AI responses (~10-15s)
- Verify results (~2s)
- Export report (~5s)

With 50 tests running serially: **~12-25 minutes total**

**The Solution: Parallel Execution**

Run tests simultaneously across multiple worker processes:
- 4 workers = **~3-6 minutes** (75% faster)
- 8 workers = **~2-4 minutes** (85% faster)

**But parallelism introduces new problems:**

1. **Database conflicts**: Two tests write to same session
2. **Port conflicts**: Both tests try to use port 3001
3. **Race conditions**: Test A deletes data Test B needs
4. **Non-deterministic failures**: Tests pass alone, fail together
5. **Resource contention**: CPU, memory, disk I/O limits

### 2.2 Playwright's Process Model

**Three Levels of Isolation:**

```
┌─────────────────────────────────────────────────┐
│ Test Run (npx playwright test)                 │
│                                                 │
│  ┌───────────────────┐  ┌───────────────────┐  │
│  │ Worker 1          │  │ Worker 2          │  │
│  │ (Node process)    │  │ (Node process)    │  │
│  │                   │  │                   │  │
│  │  ┌─────────────┐  │  │  ┌─────────────┐  │  │
│  │  │ Test 1      │  │  │  │ Test 3      │  │  │
│  │  │ Browser Ctx │  │  │  │ Browser Ctx │  │  │
│  │  └─────────────┘  │  │  └─────────────┘  │  │
│  │                   │  │                   │  │
│  │  ┌─────────────┐  │  │  ┌─────────────┐  │  │
│  │  │ Test 2      │  │  │  │ Test 4      │  │  │
│  │  │ Browser Ctx │  │  │  │ Browser Ctx │  │  │
│  │  └─────────────┘  │  │  └─────────────┘  │  │
│  │                   │  │                   │  │
│  │  Browser Instance │  │  Browser Instance │  │
│  └───────────────────┘  └───────────────────┘  │
│                                                 │
│  Shared: Database, Dev Server (port 3001)      │
└─────────────────────────────────────────────────┘
```

**Key Concepts:**

1. **Worker**: Independent Node.js process
   - Runs multiple tests sequentially
   - Shares browser instance across tests
   - Has its own fixture instances (worker-scoped)
   - Can have its own database connection

2. **Browser Context**: Isolated browser session
   - Fresh cookies, storage, cache per test
   - Lightweight (~50ms to create)
   - Automatic cleanup after test

3. **Shared Resources**: Require synchronization
   - Database (shared across all workers)
   - Dev server (single instance on port 3001)
   - File system (test artifacts, logs)

### 2.3 Test Isolation Strategies

**Three Approaches to Prevent Test Interference:**

**Strategy 1: Unique Data Per Test**
```typescript
// Each test creates unique data (no conflicts)
test('test 1', async ({ page, request }) => {
  const uniqueName = `Test-${Date.now()}-${Math.random()}`;
  const session = await request.post('/api/sessions', {
    data: { organizationName: uniqueName },
  });
  // Safe: No other test will use this name
});
```

**Strategy 2: Per-Worker Databases**
```typescript
// Each worker gets its own database file
// Worker 1: bloom-test-worker-1.db
// Worker 2: bloom-test-worker-2.db
// No database-level conflicts possible
```

**Strategy 3: Test Cleanup**
```typescript
// Clean up after each test
test('test 1', async ({ page, request }) => {
  const session = await createSession(request);
  // ... test logic ...
  await request.delete(`/api/sessions/${session.id}`); // Cleanup
});
```

### 2.4 Worker-Scoped vs Test-Scoped Fixtures

**Mental Model: Setup Cost vs Isolation**

```
Test-Scoped (default):
┌─────────┬─────────┬─────────┐
│ Test 1  │ Test 2  │ Test 3  │
├─────────┼─────────┼─────────┤
│ Setup   │ Setup   │ Setup   │ ← Repeated 3 times
│ Test    │ Test    │ Test    │
│ Cleanup │ Cleanup │ Cleanup │
└─────────┴─────────┴─────────┘

Pros: Perfect isolation, tests can't interfere
Cons: Slower (3x setup overhead)

Worker-Scoped:
┌───────────────────────────────┐
│       Worker 1                │
├───────────────────────────────┤
│ Setup (once)                  │
├─────────┬─────────┬─────────┤
│ Test 1  │ Test 2  │ Test 3  │ ← Share setup
└─────────┴─────────┴─────────┘
│ Cleanup (once)                │
└───────────────────────────────┘

Pros: Faster (1x setup overhead)
Cons: Tests share state, risk of interference
```

**When to Use Each:**

- **Test-scoped**: Default choice, safest
  - Authentication state that tests modify
  - Database fixtures that tests mutate
  - File uploads, temporary files

- **Worker-scoped**: Performance optimization
  - Read-only shared data (e.g., benchmark datasets)
  - Expensive setup (e.g., seeding large databases)
  - Cached authentication tokens (if immutable)

## 3. Golden Path

<!-- Query Pattern: bloom parallel testing, playwright configuration, best practices -->

### 3.1 Bloom's Parallel Testing Configuration

**Current Configuration** (from `/home/user/bloom/playwright.config.ts`):

```typescript
export default defineConfig({
  // Parallel execution settings
  workers: process.env.CI ? 1 : undefined,
  // CI: 1 worker (serial, more stable)
  // Local: undefined (defaults to 50% of CPU cores)

  // Retry settings
  retries: process.env.CI ? 2 : 0,
  // CI: Retry flaky tests up to 2 times
  // Local: No retries (failures are immediate)

  // Shared dev server
  webServer: {
    command: 'npm run dev:simple',
    url: 'http://localhost:3001',
    reuseExistingServer: !process.env.CI, // Reuse on local, fresh on CI
    timeout: 120 * 1000, // 2 minutes to start
  },

  // Shared base URL
  use: {
    baseURL: 'http://localhost:3001',
  },
});
```

**Why These Settings:**

1. **CI: Serial execution** (`workers: 1`)
   - More stable (no race conditions)
   - Easier to debug failures
   - Consistent resource usage
   - Trade-off: Slower (~20-30 minutes for full suite)

2. **Local: Parallel execution** (`workers: undefined`)
   - Defaults to `Math.floor(os.cpus().length / 2)`
   - 8-core machine = 4 workers
   - Faster feedback (~5-10 minutes for full suite)
   - Trade-off: Requires careful test isolation

### 3.2 Recommended Parallel Testing Workflow

**Step 1: Write Isolated Tests**

```typescript
// ✅ GOOD: Self-contained test
test('create workshop session', async ({ page, request }) => {
  // 1. Create unique test data
  const uniqueName = `TestOrg-${Date.now()}`;

  // 2. Perform test actions
  await page.goto('/workshop');
  await page.getByLabel('Organization Name').fill(uniqueName);
  await page.getByRole('button', { name: 'Start Session' }).click();

  // 3. Verify results
  await expect(page.locator('.session-header')).toContainText(uniqueName);

  // 4. Cleanup (optional but recommended)
  const sessionId = page.url().match(/session=([^&]+)/)?.[1];
  if (sessionId) {
    await request.delete(`/api/sessions/${sessionId}`);
  }
});
```

**Step 2: Use Fixtures for Common Setup**

```typescript
// tests/fixtures/test-session.ts
import { test as base, expect } from '@playwright/test';
import type { APIRequestContext } from '@playwright/test';

// Define fixture types
type TestFixtures = {
  testSession: { id: string; organizationName: string };
};

// Extend base test with custom fixture
export const test = base.extend<TestFixtures>({
  testSession: async ({ request }, use) => {
    // Setup: Create session via API
    const uniqueName = `TestOrg-${Date.now()}-${Math.random()}`;
    const response = await request.post('/api/sessions', {
      data: { organizationName: uniqueName, industry: 'Technology' },
    });

    if (!response.ok()) {
      throw new Error(`Failed to create test session: ${response.status()}`);
    }

    const session = await response.json();

    // Provide session to test
    await use(session);

    // Teardown: Delete session
    await request.delete(`/api/sessions/${session.id}`);
  },
});

export { expect };
```

**Usage:**

```typescript
// tests/workshop/resume-session.spec.ts
import { test, expect } from '../fixtures/test-session';

test('resume existing session', async ({ page, testSession }) => {
  // testSession is automatically created and cleaned up
  await page.goto(`/workshop?session=${testSession.id}`);
  await expect(page.locator('.session-header')).toContainText(testSession.organizationName);
});
```

**Step 3: Run Tests Locally with Parallelism**

```bash
# Run all tests (parallel, default workers)
npx playwright test

# Run with specific worker count
npx playwright test --workers=2

# Run single test (useful for debugging)
npx playwright test workshop/create-session.spec.ts

# Run in serial mode (same as CI)
npx playwright test --workers=1
```

**Step 4: Debug Parallel Test Failures**

If a test fails in parallel but passes in isolation:

```bash
# 1. Run the failing test alone to confirm isolation
npx playwright test --grep "create workshop session"

# 2. Run in serial mode to check for timing issues
npx playwright test --workers=1

# 3. Enable trace to debug interactions
npx playwright test --trace on

# 4. Check for shared state (look for global variables, singletons)
# Search codebase for:
# - Global variables (let/const outside functions)
# - Singletons that cache state
# - Database queries without WHERE clauses
```

### 3.3 Bloom's Per-Worker Database Pattern (Recommended)

**Goal:** Eliminate database conflicts by giving each worker its own SQLite file.

**Implementation:**

```typescript
// playwright.config.ts
import { defineConfig } from '@playwright/test';

export default defineConfig({
  workers: process.env.CI ? 1 : 4,

  // Use worker-scoped fixture for per-worker database
  globalSetup: './tests/setup/global-setup.ts',

  use: {
    // Each worker gets its own database via environment variable
    // Worker 1: DATABASE_URL=file:./bloom-test-worker-1.db
    // Worker 2: DATABASE_URL=file:./bloom-test-worker-2.db
  },
});
```

```typescript
// tests/setup/worker-setup.ts (worker-scoped fixture)
import { test as base } from '@playwright/test';
import { PrismaClient } from '@prisma/client';
import { execSync } from 'child_process';
import fs from 'fs';

type WorkerFixtures = {
  workerDatabase: PrismaClient;
};

export const test = base.extend<{}, WorkerFixtures>({
  // Worker-scoped fixture (runs once per worker)
  workerDatabase: [async ({}, use, workerInfo) => {
    const workerIndex = workerInfo.workerIndex;
    const dbPath = `./bloom-test-worker-${workerIndex}.db`;
    const databaseUrl = `file:${dbPath}`;

    // 1. Create fresh database for this worker
    process.env.DATABASE_URL = databaseUrl;
    execSync('npx prisma migrate deploy', { stdio: 'inherit' });

    // 2. Create Prisma client
    const prisma = new PrismaClient({ datasources: { db: { url: databaseUrl } } });
    await prisma.$connect();

    // 3. Seed with base data (optional)
    await seedTestData(prisma);

    // Provide to tests
    await use(prisma);

    // 4. Cleanup
    await prisma.$disconnect();
    if (fs.existsSync(dbPath)) {
      fs.unlinkSync(dbPath);
    }
  }, { scope: 'worker' }],
});

async function seedTestData(prisma: PrismaClient) {
  // Add base data that all tests can use (read-only)
  await prisma.organization.create({
    data: { name: 'Default Org', industry: 'Technology' },
  });
}
```

**Usage:**

```typescript
import { test, expect } from './setup/worker-setup';

test('create session', async ({ page, workerDatabase }) => {
  // workerDatabase is specific to this worker (no conflicts)
  const session = await workerDatabase.session.create({
    data: { organizationName: 'Test Org' },
  });

  await page.goto(`/workshop?session=${session.id}`);
  await expect(page.locator('.session-header')).toBeVisible();
});
```

**Benefits:**

- **Zero database conflicts**: Each worker has isolated database
- **Faster tests**: No waiting for database locks
- **Easier debugging**: Worker 1's data doesn't affect Worker 2
- **Parallel safety**: Can run unlimited workers without issues

**Trade-offs:**

- **Setup complexity**: More boilerplate code
- **Disk usage**: N database files (usually small, <10MB each)
- **CI cost**: Each worker needs database setup time (~2-5s)

## 4. Variations & Trade-Offs

<!-- Query Pattern: parallel testing strategies, worker configuration, trade-offs -->

### 4.1 Worker Count Strategies

**Strategy 1: 50% of CPU Cores (Playwright Default)**

```typescript
workers: undefined, // Math.floor(os.cpus().length / 2)
```

**Pros:**
- Balances speed and stability
- Leaves CPU for dev server, browser rendering
- Works well on most machines

**Cons:**
- Not optimized for specific workload
- May be too conservative on high-core machines

**Use When:** Default choice for most projects

---

**Strategy 2: 100% of CPU Cores (Maximum Speed)**

```typescript
workers: os.cpus().length,
```

**Pros:**
- Maximum parallelism
- Fastest test execution (on CPU-bound tests)

**Cons:**
- Higher resource contention
- Dev server may slow down
- Potential for more flaky tests due to resource starvation

**Use When:** Tests are CPU-bound and short-lived

---

**Strategy 3: Fixed Worker Count (Consistent Performance)**

```typescript
workers: 4, // Always 4 workers, regardless of CPU count
```

**Pros:**
- Predictable performance across machines
- Easier to reproduce CI behavior locally
- Prevents overwhelming low-spec machines

**Cons:**
- Not optimized for specific machine
- Wastes capacity on high-core machines

**Use When:** Team has varied hardware specs

---

**Strategy 4: Serial Execution (Maximum Stability)**

```typescript
workers: 1, // No parallelism
```

**Pros:**
- Eliminates race conditions
- Easier to debug
- Predictable resource usage
- Required for tests with shared state

**Cons:**
- Very slow (no speed benefit)

**Use When:** CI, debugging flaky tests, or tests require serial execution

---

### 4.2 fullyParallel vs Default Behavior

**Default Behavior: Parallel Files, Serial Tests**

```typescript
// playwright.config.ts (default)
export default defineConfig({
  workers: 4,
  // Each test FILE runs in parallel, tests WITHIN a file run serially
});
```

**Example:**

```
Worker 1: file1.spec.ts → test1 → test2 → test3 (serial)
Worker 2: file2.spec.ts → test1 → test2 → test3 (serial)
Worker 3: file3.spec.ts → test1 → test2 → test3 (serial)
Worker 4: file4.spec.ts → test1 → test2 → test3 (serial)
```

**fullyParallel: Every Test Runs in Parallel**

```typescript
// playwright.config.ts
export default defineConfig({
  fullyParallel: true, // All tests run in parallel
  workers: 4,
});
```

**Example:**

```
Worker 1: file1.spec.ts/test1, file2.spec.ts/test3
Worker 2: file1.spec.ts/test2, file3.spec.ts/test1
Worker 3: file1.spec.ts/test3, file3.spec.ts/test2
Worker 4: file2.spec.ts/test1, file2.spec.ts/test2
```

**Trade-offs:**

| Default (File-level Parallelism) | fullyParallel: true |
|----------------------------------|---------------------|
| ✅ Tests in same file run sequentially | ✅ Maximum parallelism |
| ✅ Safer for tests that share `beforeEach` | ✅ Best for large test suites |
| ⚠️ Slower if one file has many tests | ⚠️ Requires perfect test isolation |
| ✅ Easier to debug within a file | ⚠️ Harder to debug shared state issues |

**Recommendation for Bloom:**

```typescript
// Use default (file-level parallelism)
// fullyParallel: false (or omit)

// Reason: Bloom tests often share beforeEach setup within files
// Example: workshop tests all need authentication
```

### 4.3 Retry Strategies

**Strategy 1: No Retries (Development)**

```typescript
retries: 0,
```

**Pros:** Failures are immediate, forces fixing flaky tests
**Cons:** Single transient failure fails entire run
**Use When:** Local development

---

**Strategy 2: Limited Retries (CI)**

```typescript
retries: 2, // Retry up to 2 times (max 3 attempts total)
```

**Pros:** Tolerates transient failures (network, timing)
**Cons:** May hide genuinely flaky tests
**Use When:** CI/CD environments

---

**Strategy 3: Selective Retries (Per-Test)**

```typescript
test('flaky API test', async ({ page }) => {
  // Retry this specific test up to 3 times
  test.info().annotations.push({ type: 'retries', description: '3' });
  // ... test logic
});

// Or use test.describe.configure
test.describe.configure({ retries: 3 });
test.describe('Flaky Tests', () => {
  // All tests in this block get 3 retries
});
```

**Pros:** Targeted approach, stable tests run once
**Cons:** More config complexity
**Use When:** Known flaky tests (e.g., AI API calls)

## 5. Examples

<!-- Query Pattern: playwright parallel examples, worker fixtures, database isolation -->

### Example 1 – Pedagogical: Basic Parallel Test Isolation

**Purpose:** Demonstrate the simplest parallel-safe test pattern.

```typescript
// tests/basic-parallel.spec.ts
import { test, expect } from '@playwright/test';

// These tests run in parallel safely because they use unique data
test.describe('Parallel Safe Tests', () => {
  test('create session 1', async ({ page }) => {
    const uniqueName = `TestOrg-${Date.now()}-1`;

    await page.goto('/workshop');
    await page.getByLabel('Organization Name').fill(uniqueName);
    await page.getByRole('button', { name: 'Start Session' }).click();

    // Verify using the unique name
    await expect(page.locator('.session-header')).toContainText(uniqueName);
  });

  test('create session 2', async ({ page }) => {
    const uniqueName = `TestOrg-${Date.now()}-2`;

    await page.goto('/workshop');
    await page.getByLabel('Organization Name').fill(uniqueName);
    await page.getByRole('button', { name: 'Start Session' }).click();

    // No conflict with test 1 (different name)
    await expect(page.locator('.session-header')).toContainText(uniqueName);
  });

  test('create session 3', async ({ page }) => {
    const uniqueName = `TestOrg-${Date.now()}-3`;

    await page.goto('/workshop');
    await page.getByLabel('Organization Name').fill(uniqueName);
    await page.getByRole('button', { name: 'Start Session' }).click();

    await expect(page.locator('.session-header')).toContainText(uniqueName);
  });
});

// Run with: npx playwright test basic-parallel.spec.ts --workers=3
// All 3 tests run simultaneously without conflicts
```

**Key Concepts:**
- Unique data per test (`Date.now()` + counter)
- No shared state between tests
- Safe for full parallelism

---

### Example 2 – Realistic Synthetic: Worker-Scoped Database Fixture

**Purpose:** Show Bloom's per-worker database pattern in action.

```typescript
// tests/fixtures/worker-database.ts
import { test as base } from '@playwright/test';
import { PrismaClient } from '@prisma/client';
import { execSync } from 'child_process';
import fs from 'fs';
import path from 'path';

type WorkerFixtures = {
  db: PrismaClient; // Each worker gets its own Prisma instance
};

export const test = base.extend<{}, WorkerFixtures>({
  db: [async ({}, use, workerInfo) => {
    const workerIndex = workerInfo.workerIndex;
    const dbFile = `bloom-test-worker-${workerIndex}.db`;
    const dbPath = path.resolve(__dirname, '../../', dbFile);
    const databaseUrl = `file:${dbPath}`;

    console.log(`[Worker ${workerIndex}] Setting up database: ${dbPath}`);

    // 1. Set environment variable for this worker
    process.env.DATABASE_URL = databaseUrl;

    // 2. Run migrations to create schema
    execSync('npx prisma migrate deploy', {
      env: { ...process.env, DATABASE_URL: databaseUrl },
      stdio: 'inherit',
    });

    // 3. Create Prisma client
    const prisma = new PrismaClient({
      datasources: { db: { url: databaseUrl } },
    });
    await prisma.$connect();

    console.log(`[Worker ${workerIndex}] Database ready`);

    // Provide to tests
    await use(prisma);

    // 4. Cleanup
    console.log(`[Worker ${workerIndex}] Cleaning up database`);
    await prisma.$disconnect();

    // Delete database file
    if (fs.existsSync(dbPath)) {
      fs.unlinkSync(dbPath);
    }
    if (fs.existsSync(`${dbPath}-journal`)) {
      fs.unlinkSync(`${dbPath}-journal`);
    }
  }, { scope: 'worker' }], // Worker-scoped: runs once per worker
});

export { expect } from '@playwright/test';
```

**Usage:**

```typescript
// tests/workshop/parallel-sessions.spec.ts
import { test, expect } from '../fixtures/worker-database';

test.describe('Parallel Session Tests', () => {
  test('create session via API', async ({ db }) => {
    // db is specific to this worker's database
    const session = await db.session.create({
      data: {
        organizationName: 'Test Org API',
        industry: 'Technology',
        status: 'active',
      },
    });

    expect(session.id).toBeTruthy();
    expect(session.organizationName).toBe('Test Org API');
  });

  test('query sessions', async ({ db }) => {
    // Create test data in THIS worker's database
    await db.session.create({
      data: { organizationName: 'Query Test', industry: 'Healthcare' },
    });

    const sessions = await db.session.findMany({
      where: { organizationName: 'Query Test' },
    });

    expect(sessions).toHaveLength(1);
  });

  test('delete session', async ({ db }) => {
    const session = await db.session.create({
      data: { organizationName: 'Delete Test', industry: 'Finance' },
    });

    await db.session.delete({ where: { id: session.id } });

    const deleted = await db.session.findUnique({ where: { id: session.id } });
    expect(deleted).toBeNull();
  });
});

// Run with: npx playwright test parallel-sessions.spec.ts --workers=3
// Each worker has its own database file (no conflicts)
```

**Benefits:**
- Zero database lock errors
- Tests can run in any order
- Safe for unlimited parallelism

---

### Example 3 – Framework Integration: Bloom Full Stack Parallel Testing

**Purpose:** Combine all patterns for production-ready parallel testing.

```typescript
// tests/fixtures/bloom-fixtures.ts
import { test as base, expect as baseExpect } from '@playwright/test';
import { PrismaClient } from '@prisma/client';
import type { APIRequestContext } from '@playwright/test';

// Define all fixture types
type TestFixtures = {
  cleanupSessions: string[]; // Track sessions to delete
};

type WorkerFixtures = {
  workerDb: PrismaClient;
};

// Extend base test with Bloom-specific fixtures
export const test = base.extend<TestFixtures, WorkerFixtures>({
  // Worker-scoped: Per-worker database
  workerDb: [async ({}, use, workerInfo) => {
    // ... (same as Example 2)
  }, { scope: 'worker' }],

  // Test-scoped: Session cleanup tracker
  cleanupSessions: async ({}, use) => {
    const sessionIds: string[] = [];

    // Provide array to test
    await use(sessionIds);

    // Cleanup all sessions created during test
    if (sessionIds.length > 0) {
      const prisma = new PrismaClient();
      await prisma.session.deleteMany({
        where: { id: { in: sessionIds } },
      });
      await prisma.$disconnect();
    }
  },
});

// Export custom expect with Bloom-specific matchers
export const expect = baseExpect;
```

**Helper Functions:**

```typescript
// tests/utils/session-helpers.ts
import type { APIRequestContext } from '@playwright/test';

export async function createTestSession(
  request: APIRequestContext,
  cleanupTracker: string[],
  organizationName?: string
) {
  const uniqueName = organizationName || `TestOrg-${Date.now()}-${Math.random()}`;

  const response = await request.post('/api/sessions', {
    data: {
      organizationName: uniqueName,
      industry: 'Technology',
    },
  });

  if (!response.ok()) {
    throw new Error(`Failed to create session: ${response.status()}`);
  }

  const session = await response.json();

  // Track for cleanup
  cleanupTracker.push(session.id);

  return session;
}
```

**Complete Test:**

```typescript
// tests/workshop/parallel-workshop.spec.ts
import { test, expect } from '../fixtures/bloom-fixtures';
import { createTestSession } from '../utils/session-helpers';

test.describe('Workshop Parallel Tests', () => {
  test('complete workshop flow - user 1', async ({ page, request, cleanupSessions }) => {
    // Create session (automatically tracked for cleanup)
    const session = await createTestSession(request, cleanupSessions, 'User1 Corp');

    // Navigate to session
    await page.goto(`/workshop?session=${session.id}`);

    // Chat with Melissa
    await page.getByLabel('Chat message').fill('We automate invoices');
    await page.getByRole('button', { name: 'Send' }).click();

    // Verify response
    await expect(page.locator('.melissa-message').last()).toBeVisible({ timeout: 15000 });

    // Session is automatically cleaned up after test
  });

  test('complete workshop flow - user 2', async ({ page, request, cleanupSessions }) => {
    // Runs in parallel with test 1 (no conflicts)
    const session = await createTestSession(request, cleanupSessions, 'User2 Corp');

    await page.goto(`/workshop?session=${session.id}`);

    await page.getByLabel('Chat message').fill('We need better reporting');
    await page.getByRole('button', { name: 'Send' }).click();

    await expect(page.locator('.melissa-message').last()).toBeVisible({ timeout: 15000 });
  });

  test('resume session - user 3', async ({ page, request, cleanupSessions }) => {
    // Create session with initial messages
    const session = await createTestSession(request, cleanupSessions, 'User3 Corp');

    // Add messages via API
    await request.post(`/api/sessions/${session.id}/messages`, {
      data: {
        messages: [
          { role: 'user', content: 'Initial question' },
          { role: 'assistant', content: 'Initial response' },
        ],
      },
    });

    // Test resume flow
    await page.goto(`/workshop?session=${session.id}`);

    // Verify history loaded
    await expect(page.locator('.user-message')).toContainText('Initial question');
    await expect(page.locator('.melissa-message')).toContainText('Initial response');
  });
});

// Run with: npx playwright test parallel-workshop.spec.ts --workers=4
// All 3 tests run in parallel safely:
// - Each creates unique session
// - Automatic cleanup prevents database bloat
// - Per-worker database eliminates conflicts
```

**Output:**

```
Running 3 tests using 3 workers

[Worker 0] Setting up database: bloom-test-worker-0.db
[Worker 1] Setting up database: bloom-test-worker-1.db
[Worker 2] Setting up database: bloom-test-worker-2.db

  ✓ complete workshop flow - user 1 (12s)
  ✓ complete workshop flow - user 2 (11s)
  ✓ resume session - user 3 (8s)

[Worker 0] Cleaning up database
[Worker 1] Cleaning up database
[Worker 2] Cleaning up database

3 passed (12s)  ← Much faster than serial (31s)
```

## 6. Common Pitfalls

<!-- Query Pattern: playwright parallel pitfalls, test isolation mistakes, race conditions -->

### Pitfall 1: Database Lock Errors (SQLite-Specific)

**❌ WRONG: Shared SQLite database with many workers**

```typescript
// playwright.config.ts
workers: 8, // 8 workers all hitting same bloom.db file

// Tests fail with: SQLITE_BUSY: database is locked
```

**Why:** SQLite allows only one writer at a time. With many workers, tests queue up waiting for locks.

**✅ CORRECT: Per-worker databases or serial execution**

```typescript
// Option 1: Use per-worker databases (see Example 2)
workers: 8, // Each worker has bloom-test-worker-N.db

// Option 2: Reduce workers for shared database
workers: process.env.CI ? 1 : 2, // Fewer writers = fewer conflicts
```

---

### Pitfall 2: Global State / Shared Singletons

**❌ WRONG: Singleton pattern in test code**

```typescript
// tests/utils/session-manager.ts (ANTI-PATTERN)
class SessionManager {
  private static instance: SessionManager;
  private currentSession: string | null = null;

  static getInstance() {
    if (!this.instance) {
      this.instance = new SessionManager();
    }
    return this.instance;
  }

  setSession(id: string) {
    this.currentSession = id; // BAD: Shared across tests!
  }
}

// Test 1 (Worker 1)
test('test 1', async ({ page }) => {
  const manager = SessionManager.getInstance();
  manager.setSession('session-1');
  // ...
});

// Test 2 (Worker 1, runs after Test 1)
test('test 2', async ({ page }) => {
  const manager = SessionManager.getInstance();
  // manager.currentSession might still be 'session-1' from Test 1!
});
```

**✅ CORRECT: Test-scoped or worker-scoped fixtures**

```typescript
// Use fixtures instead of singletons
export const test = base.extend({
  sessionManager: async ({}, use) => {
    const manager = new SessionManager(); // Fresh instance per test
    await use(manager);
  },
});
```

---

### Pitfall 3: Not Awaiting Async Operations

**❌ WRONG: Missing await in parallel context**

```typescript
test('missing await', async ({ page }) => {
  page.goto('/workshop'); // ❌ Missing await!

  // Race condition: Next line runs before page loads
  await page.fill('#org-name', 'Test'); // Might fail intermittently
});
```

**Why:** In parallel execution, timing issues are amplified. A test that "works" serially may fail in parallel.

**✅ CORRECT: Always await async operations**

```typescript
test('proper await', async ({ page }) => {
  await page.goto('/workshop'); // ✅
  await page.fill('#org-name', 'Test');
});
```

---

### Pitfall 4: Tests Depend on Execution Order

**❌ WRONG: Test 2 assumes Test 1 ran first**

```typescript
test('test 1: create session', async ({ page }) => {
  await page.goto('/workshop');
  await page.fill('#org-name', 'Shared Org');
  await page.click('#start-session');
});

test('test 2: use session', async ({ page }) => {
  // ❌ Assumes "Shared Org" session exists from Test 1
  await page.goto('/workshop');
  await page.locator('[data-session-name="Shared Org"]').click();
});
```

**Why:** In parallel mode, Test 2 might run before Test 1, or in a different worker (different database).

**✅ CORRECT: Each test creates its own data**

```typescript
test('test 1: create session', async ({ page }) => {
  await page.goto('/workshop');
  await page.fill('#org-name', 'Org1');
  await page.click('#start-session');
});

test('test 2: use session', async ({ page, request }) => {
  // ✅ Create session via API for this test
  const session = await request.post('/api/sessions', {
    data: { organizationName: 'Org2' },
  });
  const { id } = await session.json();

  await page.goto(`/workshop?session=${id}`);
});
```

---

### Pitfall 5: Not Cleaning Up Test Data

**❌ WRONG: Tests accumulate data**

```typescript
test('create 100 sessions', async ({ request }) => {
  for (let i = 0; i < 100; i++) {
    await request.post('/api/sessions', {
      data: { organizationName: `Test${i}` },
    });
  }
  // ❌ Sessions remain in database after test
});

// After 10 test runs: 1000 sessions in database!
```

**Why:** Database grows unbounded, slowing down queries and consuming disk.

**✅ CORRECT: Cleanup after each test**

```typescript
test('create 100 sessions', async ({ request }) => {
  const sessionIds: string[] = [];

  for (let i = 0; i < 100; i++) {
    const response = await request.post('/api/sessions', {
      data: { organizationName: `Test${i}` },
    });
    const { id } = await response.json();
    sessionIds.push(id);
  }

  // Cleanup
  for (const id of sessionIds) {
    await request.delete(`/api/sessions/${id}`);
  }
});
```

---

### Pitfall 6: Hardcoding Worker-Specific Values

**❌ WRONG: Hardcoded port or file paths**

```typescript
test('test with hardcoded port', async ({ page }) => {
  // ❌ What if another worker is using port 3002?
  await page.goto('http://localhost:3002/workshop');
});
```

**✅ CORRECT: Use baseURL from config**

```typescript
test('test with baseURL', async ({ page }) => {
  // ✅ Uses configured baseURL (http://localhost:3001)
  await page.goto('/workshop');
});
```

---

### Pitfall 7: Using test.only or test.skip in Committed Code

**❌ WRONG: Commit test.only or test.skip**

```typescript
test.only('debug this test', async ({ page }) => {
  // ❌ Only this test runs! All others skipped.
});

test.skip('broken test', async ({ page }) => {
  // ❌ Silently skipped in CI
});
```

**Why:**
- `test.only`: Breaks parallel execution (only 1 test runs)
- `test.skip`: Masks failing tests, reduces coverage

**✅ CORRECT: Use config to prevent this**

```typescript
// playwright.config.ts
export default defineConfig({
  forbidOnly: !!process.env.CI, // Fail CI if test.only exists
});
```

## 7. AI Pair Programming Notes

<!-- Query Pattern: playwright parallel ai assistance, worker debugging, isolation patterns -->

### When to Load This File

**Load `08-PARALLEL-ISOLATION.md` when:**

- User asks: "Why are my Playwright tests failing in parallel?"
- User asks: "How do I speed up my E2E tests?"
- User mentions: "database is locked", "SQLITE_BUSY", "race condition"
- User asks: "What are worker-scoped fixtures?"
- User wants to implement per-worker databases
- User is configuring `workers`, `fullyParallel`, or `retries`
- User reports: "Test passes alone, fails with others"

### Combine With

- `01-FUNDAMENTALS.md` - For test isolation basics
- `07-DATABASE-FIXTURES.md` - For database setup patterns
- `09-DEBUGGING-TROUBLESHOOTING.md` - For debugging parallel failures
- `/docs/ARCHITECTURE.md` - For Bloom's overall testing strategy

### Code Generation Guidelines

**When generating parallel-safe tests:**

1. **Always use unique data**:
   ```typescript
   const uniqueName = `Test-${Date.now()}-${Math.random()}`;
   ```

2. **Prefer fixtures over global state**:
   ```typescript
   // ✅ Fixture (isolated per test)
   export const test = base.extend({ db: async ({}, use) => { ... } });

   // ❌ Global singleton (shared across tests)
   const dbManager = DatabaseManager.getInstance();
   ```

3. **Include cleanup**:
   ```typescript
   const session = await createSession();
   await use(session);
   await deleteSession(session.id); // Cleanup
   ```

4. **Use worker-scoped for expensive setup**:
   ```typescript
   { scope: 'worker' } // Runs once per worker, not per test
   ```

### Debugging Parallel Test Failures

**When user reports parallel failures:**

1. **Reproduce in serial mode**:
   ```bash
   npx playwright test --workers=1
   ```
   If passes: Likely race condition or shared state
   If fails: Bug in test or application

2. **Check for shared state**:
   - Global variables
   - Singletons
   - Database queries without unique identifiers

3. **Enable verbose logging**:
   ```bash
   DEBUG=pw:api npx playwright test --workers=2
   ```

4. **Suggest per-worker databases**:
   Point user to Example 2 in this file

### Common Questions & Answers

**Q: "Should I use fullyParallel or default?"**
A: Default (file-level parallelism) is safer. Use `fullyParallel: true` only if every test is perfectly isolated.

**Q: "How many workers should I use?"**
A: Start with default (`Math.floor(cpus / 2)`). Reduce if seeing database locks or resource issues.

**Q: "My tests fail with SQLITE_BUSY. What do I do?"**
A: Use per-worker databases (Example 2) or reduce workers to 1-2.

**Q: "Should I use worker-scoped or test-scoped fixtures?"**
A: Default to test-scoped. Use worker-scoped only for expensive, read-only setup.

**Q: "How do I debug a test that only fails in parallel?"**
A: 1) Run alone (`--grep "test name"`), 2) Run in serial (`--workers=1`), 3) Check for shared state, 4) Use trace viewer (`--trace on`).

## Last Updated

2025-11-14

**Changelog:**

- Initial comprehensive KB created following v3.1 playbook
- Added 7-section structure with parallel execution focus
- Included per-worker database pattern for Bloom
- Added 3-tier examples: Pedagogical, Realistic, Framework Integration
- Covered 7 common pitfalls with solutions
- Integrated Bloom's actual playwright.config.ts settings
- Added worker-scoped vs test-scoped fixture patterns
- Included debugging strategies for parallel test failures

**Related Files:**

- `01-FUNDAMENTALS.md` - Test isolation basics
- `07-DATABASE-FIXTURES.md` - Database setup patterns
- `09-DEBUGGING-TROUBLESHOOTING.md` - Debugging guidance
- `/home/user/bloom/playwright.config.ts` - Actual Bloom configuration

**Version**: 3.1
**Profile**: Full
**Estimated Reading Time**: 20-25 minutes
**Target Audience**: Intermediate to Advanced Playwright users
**Line Count**: ~1300 lines (comprehensive coverage)
