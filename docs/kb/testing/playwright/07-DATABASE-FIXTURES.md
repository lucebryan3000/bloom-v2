---
id: playwright-07-database-fixtures
topic: playwright
file_role: practical
profile: full
difficulty_level: advanced
kb_version: 3.1
prerequisites: [playwright-01-fundamentals, prisma-basics]
related_topics: [database-testing, fixtures, test-data, prisma, test-isolation]
embedding_keywords: [playwright, database, fixtures, test-data, prisma, per-worker-db, factories, seeding, cleanup, sqlite-wal]
last_reviewed: 2025-11-14
---

# Database Fixtures & Test Data Management

<!-- Query: "How do I set up per-worker databases for Playwright?" -->
<!-- Query: "How to create test fixtures for Prisma models?" -->
<!-- Query: "How to prevent database conflicts in parallel Playwright tests?" -->
<!-- Query: "SQLite WAL mode considerations for Playwright testing?" -->

## 1. Purpose

**What This File Covers:**

This file provides comprehensive patterns for managing test databases, fixtures, and data in Playwright E2E tests, specifically for Bloom's Next.js 16 + Prisma 5.22.0 + SQLite stack.

**Key Topics:**

- **Per-worker database isolation** - Prevent conflicts in parallel test execution
- **Test fixtures and factories** - Create reusable, type-safe test data
- **Database cleanup strategies** - Keep tests independent and fast
- **Seeding patterns** - Establish baseline data for test scenarios
- **Prisma integration** - Leverage Prisma Client in test fixtures
- **SQLite WAL mode** - Special considerations for Bloom's journal mode
- **Bloom-specific fixtures** - Sessions, Users, Organizations, ROI Reports, etc.

**Who Should Read This:**

- Developers writing E2E tests that interact with the database
- Engineers implementing test infrastructure for Bloom
- Anyone debugging flaky tests caused by database state
- Team members migrating from shared database to isolated database testing

**When to Use This File:**

- Setting up Playwright test infrastructure from scratch
- Adding database-dependent E2E tests
- Debugging "database is locked" errors in parallel tests
- Creating reusable test data factories
- Optimizing test performance with cleanup strategies

---

## 2. Mental Model / Problem Statement

### 2.1 The Parallel Testing Problem

**Problem:**

Playwright runs tests in parallel across multiple workers for speed. With a shared database, this causes:

```
Worker 1: Creates session "Test Session"
Worker 2: Creates session "Test Session" → Conflict!
Worker 3: Deletes all sessions → Worker 1's test fails!
```

**Symptoms:**

- `SQLITE_BUSY: database is locked` errors
- Flaky tests (pass alone, fail in parallel)
- Data contamination between tests
- Unpredictable test results

**Solution:**

Each Playwright worker gets its own isolated SQLite database:

```
Worker 0 → test-0.db (isolated)
Worker 1 → test-1.db (isolated)
Worker 2 → test-2.db (isolated)
Worker 3 → test-3.db (isolated)
```

### 2.2 Test Data Lifecycle

**Three Phases:**

```typescript
// Phase 1: Setup (beforeEach or fixture)
const session = await createTestSession();

// Phase 2: Test (your test code)
await page.goto(`/sessions/${session.id}`);
expect(...);

// Phase 3: Cleanup (afterEach or auto-cleanup)
await deleteTestSession(session.id);
```

**Isolation Principles:**

1. **Each test starts with a clean database** (or known baseline)
2. **Tests never depend on data from other tests**
3. **Cleanup happens automatically** (never rely on manual cleanup)
4. **Factory functions provide consistent data** (avoid magic values)

### 2.3 SQLite WAL Mode Considerations

**Bloom's Configuration:**

```bash
DATABASE_URL="file:./bloom.db?mode=wal"
```

**WAL (Write-Ahead Logging) Characteristics:**

- **Better concurrency**: Multiple readers + 1 writer (vs DELETE mode's exclusive locks)
- **Creates auxiliary files**: `*.db-wal` and `*.db-shm`
- **Requires cleanup**: WAL files must be deleted with database
- **Journal checkpoints**: Periodic flushes to main database

**Test Implications:**

```typescript
// ❌ WRONG: Only deletes main database file
fs.unlinkSync(dbPath);

// ✅ CORRECT: Deletes all WAL-related files
fs.unlinkSync(dbPath);
fs.unlinkSync(`${dbPath}-wal`);
fs.unlinkSync(`${dbPath}-shm`);
```

### 2.4 Fixture Patterns vs Factory Patterns

**Fixtures (Playwright-managed):**

```typescript
// Automatically setup/teardown by test framework
test('with fixture', async ({ db, testSession }) => {
  // testSession already created and will auto-cleanup
  await page.goto(`/sessions/${testSession.id}`);
});
```

**Factories (Manual creation):**

```typescript
// Explicit control over creation
test('with factory', async ({ db }) => {
  const session = await new SessionFactory(db).create();

  await page.goto(`/sessions/${session.id}`);

  // Manual cleanup if needed
  await db.session.delete({ where: { id: session.id } });
});
```

**Trade-offs:**

| Pattern | Pros | Cons |
|---------|------|------|
| **Fixtures** | Auto-cleanup, less boilerplate | Less flexible, harder to customize |
| **Factories** | Full control, reusable | More boilerplate, manual cleanup |

**Golden Rule:** Use **fixtures** for common patterns, **factories** for custom scenarios.

---

## 3. Golden Path: Per-Worker Database Setup

### 3.1 Directory Structure

```
tests/
├── fixtures/
│   ├── database.ts          # Per-worker DB fixture
│   ├── factories.ts         # Test data factories
│   └── seed.ts              # Baseline seed data
├── e2e/
│   └── sessions.spec.ts     # Tests using fixtures
└── setup/
    └── global-setup.ts      # One-time setup
```

### 3.2 Step 1: Per-Worker Database Fixture

Create `tests/fixtures/database.ts`:

```typescript
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
  // Worker-scoped fixture (runs once per worker, shared across tests)
  dbPath: [
    async ({}, use, workerInfo) => {
      const dbDir = path.join(process.cwd(), '.test-dbs');

      // Create directory if it doesn't exist
      if (!fs.existsSync(dbDir)) {
        fs.mkdirSync(dbDir, { recursive: true });
      }

      // Each worker gets unique database file
      const dbPath = path.join(dbDir, `test-worker-${workerInfo.workerIndex}.db`);

      // Set environment variable for Prisma
      const databaseUrl = `file:${dbPath}`;
      process.env.DATABASE_URL = databaseUrl;

      // Run migrations to create schema
      console.log(`[Worker ${workerInfo.workerIndex}] Creating database: ${dbPath}`);
      execSync('npx prisma migrate deploy', {
        env: { ...process.env, DATABASE_URL: databaseUrl },
        stdio: 'inherit',
      });

      // Provide database path to tests
      await use(dbPath);

      // Cleanup: Delete worker database and WAL files
      console.log(`[Worker ${workerInfo.workerIndex}] Cleaning up database: ${dbPath}`);
      const filesToDelete = [dbPath, `${dbPath}-wal`, `${dbPath}-shm`];

      filesToDelete.forEach((file) => {
        if (fs.existsSync(file)) {
          fs.unlinkSync(file);
        }
      });
    },
    { scope: 'worker' }, // Runs once per worker
  ],

  // Test-scoped fixture (new instance per test)
  db: [
    async ({ dbPath }, use) => {
      // Create Prisma client connected to worker database
      const prisma = new PrismaClient({
        datasources: {
          db: { url: `file:${dbPath}` },
        },
        // Disable logging in tests (unless debugging)
        log: process.env.DEBUG ? ['query', 'error', 'warn'] : ['error'],
      });

      // Connect to database
      await prisma.$connect();

      // Provide Prisma client to test
      await use(prisma);

      // Disconnect after test
      await prisma.$disconnect();
    },
    { scope: 'test' }, // New instance per test
  ],
});

export { expect } from '@playwright/test';
```

### 3.3 Step 2: Database Cleanup Strategy

Add to `tests/fixtures/database.ts`:

```typescript
// Add cleanup hook to ensure test isolation
test.afterEach(async ({ db }) => {
  // Delete all data in reverse dependency order
  // This ensures foreign key constraints are satisfied

  // Level 5: Deepest dependencies
  await db.artifact.deleteMany();
  await db.txLog.deleteMany();
  await db.toolCall.deleteMany();
  await db.runStep.deleteMany();

  // Level 4: Run-related
  await db.rOIReport.deleteMany();
  await db.run.deleteMany();

  // Level 3: Session-related
  await db.response.deleteMany();
  await db.sessionFile.deleteMany();
  await db.sessionMemory.deleteMany();
  await db.sessionInstructions.deleteMany();
  await db.reportExport.deleteMany();
  await db.reportShare.deleteMany();
  await db.session.deleteMany();

  // Level 2: Organization-related
  await db.auditLog.deleteMany();
  await db.user.deleteMany();
  await db.brandingAsset.deleteMany();
  await db.brandingVersion.deleteMany();
  await db.brandingConfig.deleteMany();
  await db.melissaConfig.deleteMany();
  await db.playwrightConfig.deleteMany();

  // Level 1: Top-level
  await db.organization.deleteMany();
  await db.playbook.deleteMany();
  await db.questionTemplate.deleteMany();
  await db.industryBenchmark.deleteMany();

  // Security & System tables
  await db.securityEvent.deleteMany();
  await db.aPIKey.deleteMany();
  await db.rolePermission.deleteMany();
  await db.twoFactorAuth.deleteMany();
  await db.permission.deleteMany();
  await db.encryptedData.deleteMany();

  // Testing & Scheduling
  await db.testRun.deleteMany();
  await db.taskExecution.deleteMany();
  await db.scheduledTask.deleteMany();
  await db.logConfiguration.deleteMany();
});
```

### 3.4 Step 3: Seed Baseline Data (Optional)

Create `tests/fixtures/seed.ts`:

```typescript
import { PrismaClient, Organization, User } from '@prisma/client';

export type SeedData = {
  organization: Organization;
  user: User;
};

/**
 * Seeds baseline data needed by most tests
 * Call in beforeEach if tests need default org/user
 */
export async function seedDatabase(db: PrismaClient): Promise<SeedData> {
  // Create default organization
  const organization = await db.organization.create({
    data: {
      name: 'Test Organization',
      industry: 'technology',
      size: 'medium',
      maxUsers: 10,
      maxSessions: 100,
      maxApiCalls: 10000,
      billingStatus: 'active',
      subscriptionTier: 'free',
    },
  });

  // Create default user
  const user = await db.user.create({
    data: {
      email: 'test@example.com',
      name: 'Test User',
      password: '$2b$10$abcdefghijklmnopqrstuvwxyz1234567890', // Hashed "password123"
      role: 'user',
      organizationId: organization.id,
    },
  });

  return { organization, user };
}
```

### 3.5 Step 4: Using the Fixture

Create `tests/e2e/sessions.spec.ts`:

```typescript
import { test, expect } from '../fixtures/database';
import { seedDatabase } from '../fixtures/seed';

test.describe('Session Management', () => {
  // Optional: Seed baseline data before each test
  test.beforeEach(async ({ db }) => {
    await seedDatabase(db);
  });

  test('creates new session in isolated database', async ({ db, page }) => {
    // Create session directly in database
    const session = await db.session.create({
      data: {
        title: 'Test Session',
        status: 'active',
        customerName: 'Acme Corp',
        customerIndustry: 'technology',
        contextComplete: false,
      },
    });

    // Navigate to session page
    await page.goto(`/sessions/${session.id}`);

    // Verify UI displays database data
    await expect(page.getByText('Test Session')).toBeVisible();
    await expect(page.getByText('Acme Corp')).toBeVisible();

    // Database cleanup happens automatically in afterEach
  });

  test('database is clean at start of each test', async ({ db }) => {
    // Verify no sessions exist (cleanup from previous test)
    const sessionCount = await db.session.count();
    expect(sessionCount).toBe(0);

    // Create session
    await db.session.create({
      data: {
        title: 'New Session',
        status: 'active',
      },
    });

    // Now count is 1
    const newCount = await db.session.count();
    expect(newCount).toBe(1);
  });
});
```

---

## 4. Variations & Trade-Offs

### 4.1 Cleanup Strategies Comparison

#### Strategy A: afterEach Cleanup (Recommended for Bloom)

**Pattern:**

```typescript
test.afterEach(async ({ db }) => {
  await db.session.deleteMany();
  await db.user.deleteMany();
  await db.organization.deleteMany();
});
```

**Pros:**
- ✅ Simple and explicit
- ✅ Works with all Prisma operations
- ✅ Easy to debug
- ✅ Compatible with WAL mode

**Cons:**
- ❌ Slower than alternatives (multiple DELETE queries)
- ❌ Must maintain correct deletion order (foreign keys)

**Best for:** Bloom's E2E tests (clarity over speed, few tests)

#### Strategy B: Transaction Rollback

**Pattern:**

```typescript
test('rollback example', async ({ db }) => {
  await db.$transaction(async (tx) => {
    const session = await tx.session.create({ data: {...} });

    // Do test assertions
    expect(session.id).toBeDefined();

    // Throw to rollback
    throw new Error('Rollback transaction');
  });
});
```

**Pros:**
- ✅ Fastest (no actual DELETE queries)
- ✅ No deletion order concerns

**Cons:**
- ❌ Complicated test structure
- ❌ Can't test real commit behavior
- ❌ Doesn't work for UI tests (app can't see uncommitted data)

**Best for:** Unit tests for database logic only

#### Strategy C: Database Snapshot & Restore

**Pattern:**

```typescript
test.beforeEach(async ({ dbPath }) => {
  const snapshot = `${dbPath}.snapshot`;
  fs.copyFileSync(dbPath, snapshot);
  fs.copyFileSync(`${dbPath}-wal`, `${snapshot}-wal`);
  fs.copyFileSync(`${dbPath}-shm`, `${snapshot}-shm`);
});

test.afterEach(async ({ dbPath }) => {
  const snapshot = `${dbPath}.snapshot`;
  fs.copyFileSync(snapshot, dbPath);
  fs.copyFileSync(`${snapshot}-wal`, `${dbPath}-wal`);
  fs.copyFileSync(`${snapshot}-shm`, `${dbPath}-shm`);
  fs.unlinkSync(snapshot);
  fs.unlinkSync(`${snapshot}-wal`);
  fs.unlinkSync(`${snapshot}-shm`);
});
```

**Pros:**
- ✅ Very fast for large datasets
- ✅ Perfect restoration of baseline state

**Cons:**
- ❌ Complex WAL file handling
- ❌ Requires file system operations
- ❌ May miss checkpoint issues

**Best for:** Tests with heavy seeding requirements

### 4.2 Seeding Approaches

#### Approach A: No Seeding (Start Empty)

```typescript
test('no seed example', async ({ db }) => {
  // Database is completely empty
  const orgCount = await db.organization.count();
  expect(orgCount).toBe(0);

  // Create everything you need
  const org = await db.organization.create({ data: {...} });
  const user = await db.user.create({ data: { organizationId: org.id, ... } });
});
```

**Best for:** Tests that need custom data structures

#### Approach B: Minimal Baseline Seeding

```typescript
test.beforeEach(async ({ db }) => {
  // Seed only essentials (org + user)
  await seedDatabase(db);
});

test('uses seeded data', async ({ db }) => {
  // Organization and user already exist
  const user = await db.user.findFirst();
  expect(user).toBeDefined();
});
```

**Best for:** Most Bloom tests (common baseline)

#### Approach C: Full Dataset Seeding

```typescript
test.beforeEach(async ({ db }) => {
  await seedDatabase(db); // Org + User
  await seedSessions(db, 10); // 10 sessions
  await seedROIReports(db, 5); // 5 reports
  await seedBenchmarks(db); // Industry data
});
```

**Best for:** Tests that need realistic data volumes

---

## 5. Examples: Bloom-Specific Factories

### 5.1 Factory Pattern Base Class

Create `tests/fixtures/factories.ts`:

```typescript
import { PrismaClient } from '@prisma/client';

/**
 * Base factory with helper methods
 */
export abstract class BaseFactory<T> {
  constructor(protected db: PrismaClient) {}

  /**
   * Generate unique ID suffix (timestamp + random)
   */
  protected uid(): string {
    return `${Date.now()}-${Math.random().toString(36).substring(7)}`;
  }

  /**
   * Generate unique email
   */
  protected uniqueEmail(prefix = 'user'): string {
    return `${prefix}-${this.uid()}@example.com`;
  }

  /**
   * Generate unique name
   */
  protected uniqueName(prefix = 'Test'): string {
    return `${prefix} ${this.uid()}`;
  }
}
```

### 5.2 Organization Factory

```typescript
export class OrganizationFactory extends BaseFactory<Organization> {
  /**
   * Create organization with sensible defaults
   */
  async create(overrides: Partial<Prisma.OrganizationCreateInput> = {}) {
    return await this.db.organization.create({
      data: {
        name: overrides.name ?? this.uniqueName('Org'),
        industry: overrides.industry ?? 'technology',
        size: overrides.size ?? 'medium',
        maxUsers: overrides.maxUsers ?? 10,
        maxSessions: overrides.maxSessions ?? 100,
        maxApiCalls: overrides.maxApiCalls ?? 10000,
        billingStatus: overrides.billingStatus ?? 'active',
        subscriptionTier: overrides.subscriptionTier ?? 'free',
        ...overrides,
      },
    });
  }

  /**
   * Create organization with full branding config
   */
  async createWithBranding(overrides: Partial<Prisma.OrganizationCreateInput> = {}) {
    const org = await this.create(overrides);

    await this.db.brandingConfig.create({
      data: {
        organizationId: org.id,
        primaryColor: '#2563EB',
        secondaryColor: '#7C3AED',
        accentColor: '#EC4899',
        fontFamily: 'Inter',
        template: 'modern',
        createdBy: 'system',
        updatedBy: 'system',
      },
    });

    return org;
  }

  /**
   * Create enterprise organization
   */
  async createEnterprise(overrides: Partial<Prisma.OrganizationCreateInput> = {}) {
    return await this.create({
      size: 'enterprise',
      maxUsers: 1000,
      maxSessions: 10000,
      maxApiCalls: 1000000,
      subscriptionTier: 'enterprise',
      ...overrides,
    });
  }
}
```

### 5.3 User Factory

```typescript
export class UserFactory extends BaseFactory<User> {
  /**
   * Create user (requires organizationId)
   */
  async create(
    organizationId: string,
    overrides: Partial<Prisma.UserCreateInput> = {}
  ) {
    return await this.db.user.create({
      data: {
        email: overrides.email ?? this.uniqueEmail(),
        name: overrides.name ?? this.uniqueName('User'),
        password: overrides.password ?? '$2b$10$defaulthashedpassword',
        role: overrides.role ?? 'user',
        organizationId,
        ...overrides,
      },
    });
  }

  /**
   * Create admin user
   */
  async createAdmin(
    organizationId: string,
    overrides: Partial<Prisma.UserCreateInput> = {}
  ) {
    return await this.create(organizationId, {
      role: 'admin',
      ...overrides,
    });
  }

  /**
   * Create super admin user
   */
  async createSuperAdmin(
    organizationId: string,
    overrides: Partial<Prisma.UserCreateInput> = {}
  ) {
    return await this.create(organizationId, {
      role: 'super_admin',
      email: overrides.email ?? this.uniqueEmail('admin'),
      ...overrides,
    });
  }
}
```

### 5.4 Session Factory

```typescript
export class SessionFactory extends BaseFactory<Session> {
  /**
   * Create basic session
   */
  async create(overrides: Partial<Prisma.SessionCreateInput> = {}) {
    return await this.db.session.create({
      data: {
        title: overrides.title ?? this.uniqueName('Session'),
        status: overrides.status ?? 'active',
        customerName: overrides.customerName ?? this.uniqueName('Customer'),
        customerIndustry: overrides.customerIndustry ?? 'technology',
        contextComplete: overrides.contextComplete ?? false,
        ...overrides,
      },
    });
  }

  /**
   * Create session with user and organization
   */
  async createWithUser(userId: string, organizationId: string) {
    return await this.create({
      userId,
      organizationId,
      facilitatorName: 'Test Facilitator',
      contextComplete: true,
    });
  }

  /**
   * Create session with messages (responses)
   */
  async createWithMessages(messageCount = 3, overrides: Partial<Prisma.SessionCreateInput> = {}) {
    const session = await this.create(overrides);

    for (let i = 0; i < messageCount; i++) {
      await this.db.response.create({
        data: {
          sessionId: session.id,
          questionId: `q-${i + 1}`,
          question: `Test Question ${i + 1}?`,
          answer: `Test Answer ${i + 1}`,
          confidence: 0.8 + (Math.random() * 0.2), // 0.8-1.0
        },
      });
    }

    return session;
  }

  /**
   * Create completed session with ROI report
   */
  async createWithROIReport(overrides: Partial<Prisma.SessionCreateInput> = {}) {
    const session = await this.create({
      status: 'completed',
      completedAt: new Date(),
      contextComplete: true,
      ...overrides,
    });

    await this.db.rOIReport.create({
      data: {
        sessionId: session.id,
        totalROI: 150.5,
        netPresentValue: 125000.0,
        internalRateReturn: 0.35,
        paybackPeriod: 8, // months
        confidenceScore: 85.0,
        confidenceFactors: JSON.stringify({
          completeness: 0.9,
          quality: 0.85,
          historical: 0.8,
          industry: 0.85,
          assumptions: 0.8,
        }),
      },
    });

    return session;
  }

  /**
   * Create session with full workshop context
   */
  async createWithContext() {
    const session = await this.create({
      customerName: 'Acme Corporation',
      customerIndustry: 'manufacturing',
      employeeCount: 250,
      customerLocation: 'San Francisco, CA',
      problemStatement: 'Reduce manual invoice processing time',
      department: 'Finance',
      customerContact: 'john.doe@acme.com',
      fiscalYearStart: 'January',
      annualRevenue: '$50M-$100M',
      contextComplete: true,
    });

    // Add memory
    await this.db.sessionMemory.create({
      data: {
        sessionId: session.id,
        content: 'Customer is focused on automating invoice processing. Currently 10 hours/week manual work.',
      },
    });

    // Add instructions
    await this.db.sessionInstructions.create({
      data: {
        sessionId: session.id,
        content: '# Instructions\n\nFocus on ROI for invoice automation project.',
        format: 'markdown',
      },
    });

    return session;
  }
}
```

### 5.5 ROI Report Factory

```typescript
export class ROIReportFactory extends BaseFactory<ROIReport> {
  /**
   * Create ROI report (requires sessionId or runId)
   */
  async create(
    options: { sessionId?: string; runId?: string },
    overrides: Partial<Prisma.ROIReportCreateInput> = {}
  ) {
    if (!options.sessionId && !options.runId) {
      throw new Error('ROIReport requires either sessionId or runId');
    }

    return await this.db.rOIReport.create({
      data: {
        sessionId: options.sessionId,
        runId: options.runId,
        totalROI: overrides.totalROI ?? 150.0,
        netPresentValue: overrides.netPresentValue ?? 120000.0,
        internalRateReturn: overrides.internalRateReturn ?? 0.32,
        paybackPeriod: overrides.paybackPeriod ?? 9,
        totalCostOwnership: overrides.totalCostOwnership ?? 50000.0,
        confidenceScore: overrides.confidenceScore ?? 82.5,
        confidenceFactors: overrides.confidenceFactors ?? JSON.stringify({
          completeness: 0.85,
          quality: 0.8,
          historical: 0.82,
          industry: 0.83,
          assumptions: 0.8,
        }),
        ...overrides,
      },
    });
  }

  /**
   * Create high-confidence ROI report
   */
  async createHighConfidence(options: { sessionId?: string; runId?: string }) {
    return await this.create(options, {
      totalROI: 200.0,
      confidenceScore: 92.0,
      confidenceFactors: JSON.stringify({
        completeness: 0.95,
        quality: 0.92,
        historical: 0.9,
        industry: 0.92,
        assumptions: 0.91,
      }),
    });
  }

  /**
   * Create low-confidence ROI report
   */
  async createLowConfidence(options: { sessionId?: string; runId?: string }) {
    return await this.create(options, {
      totalROI: 75.0,
      confidenceScore: 55.0,
      confidenceFactors: JSON.stringify({
        completeness: 0.6,
        quality: 0.55,
        historical: 0.5,
        industry: 0.55,
        assumptions: 0.55,
      }),
    });
  }
}
```

### 5.6 Playbook & Run Factory

```typescript
export class PlaybookFactory extends BaseFactory<Playbook> {
  async create(overrides: Partial<Prisma.PlaybookCreateInput> = {}) {
    return await this.db.playbook.create({
      data: {
        name: overrides.name ?? this.uniqueName('Playbook'),
        slug: overrides.slug ?? `playbook-${this.uid()}`,
        version: overrides.version ?? '1.0.0',
        status: overrides.status ?? 'active',
        meta: overrides.meta ?? JSON.stringify({ category: 'test' }),
        schema: overrides.schema ?? JSON.stringify({ steps: [] }),
        templateMd: overrides.templateMd ?? '# Test Playbook\n\nTest content.',
        ...overrides,
      },
    });
  }
}

export class RunFactory extends BaseFactory<Run> {
  async create(
    playbookId: string,
    overrides: Partial<Prisma.RunCreateInput> = {}
  ) {
    return await this.db.run.create({
      data: {
        playbookId,
        userId: overrides.userId,
        organizationId: overrides.organizationId,
        outcome: overrides.outcome ?? 'in_progress',
        meta: overrides.meta ?? JSON.stringify({ piiAllowed: false }),
        ...overrides,
      },
    });
  }

  async createCompleted(playbookId: string) {
    return await this.create(playbookId, {
      outcome: 'completed',
      endedAt: new Date(),
      summary: 'Test run completed successfully',
    });
  }
}
```

### 5.7 Using Factories in Tests

```typescript
import { test, expect } from '../fixtures/database';
import {
  OrganizationFactory,
  UserFactory,
  SessionFactory,
  ROIReportFactory,
} from '../fixtures/factories';

test.describe('Session with ROI Report', () => {
  test('displays session with high-confidence ROI report', async ({ db, page }) => {
    // Setup: Create org, user, session, and report
    const orgFactory = new OrganizationFactory(db);
    const userFactory = new UserFactory(db);
    const sessionFactory = new SessionFactory(db);
    const roiFactory = new ROIReportFactory(db);

    const org = await orgFactory.create({ name: 'Test Corp' });
    const user = await userFactory.create(org.id, { name: 'John Doe' });
    const session = await sessionFactory.createWithUser(user.id, org.id);
    const roi = await roiFactory.createHighConfidence({ sessionId: session.id });

    // Test: Navigate to session
    await page.goto(`/sessions/${session.id}`);

    // Assert: Verify session details
    await expect(page.getByText('Test Corp')).toBeVisible();
    await expect(page.getByText('John Doe')).toBeVisible();

    // Assert: Verify ROI report
    await expect(page.getByText(/ROI.*200\.0/)).toBeVisible();
    await expect(page.getByText(/Confidence.*92/)).toBeVisible();
  });

  test('creates session with messages using factory', async ({ db }) => {
    const sessionFactory = new SessionFactory(db);

    // Create session with 5 messages
    const session = await sessionFactory.createWithMessages(5, {
      customerName: 'Factory Corp',
    });

    // Verify session created
    expect(session.id).toBeDefined();
    expect(session.customerName).toBe('Factory Corp');

    // Verify messages created
    const messages = await db.response.findMany({
      where: { sessionId: session.id },
    });
    expect(messages).toHaveLength(5);
  });
});
```

---

## 6. Common Pitfalls

### Pitfall 1: Forgetting WAL File Cleanup

**Problem:**

```typescript
// ❌ WRONG: Only deletes main database file
if (fs.existsSync(dbPath)) {
  fs.unlinkSync(dbPath);
}
// WAL files left behind, accumulate over time
```

**Symptom:** `.test-dbs/` directory grows large, disk space issues

**Solution:**

```typescript
// ✅ CORRECT: Delete all SQLite files
const filesToDelete = [
  dbPath,
  `${dbPath}-wal`,
  `${dbPath}-shm`,
  `${dbPath}-journal`, // For DELETE mode (if switching modes)
];

filesToDelete.forEach((file) => {
  if (fs.existsSync(file)) {
    try {
      fs.unlinkSync(file);
    } catch (error) {
      console.warn(`Failed to delete ${file}:`, error);
    }
  }
});
```

### Pitfall 2: Incorrect Foreign Key Deletion Order

**Problem:**

```typescript
// ❌ WRONG: Deleting parent before child
test.afterEach(async ({ db }) => {
  await db.organization.deleteMany(); // Fails! Sessions reference orgs
  await db.session.deleteMany();
});
```

**Error:** `Foreign key constraint failed`

**Solution:**

```typescript
// ✅ CORRECT: Delete children first, then parents
test.afterEach(async ({ db }) => {
  // Delete sessions first (child)
  await db.session.deleteMany();

  // Then delete organization (parent)
  await db.organization.deleteMany();
});

// Or use cascade deletes in schema (recommended)
// prisma/schema.prisma:
// session Session @relation(onDelete: Cascade)
```

### Pitfall 3: Sharing Database State Between Tests

**Problem:**

```typescript
// ❌ WRONG: Creating data in test.beforeAll (shared across tests)
test.beforeAll(async ({ db }) => {
  await db.organization.create({ data: {...} });
});

test('test 1', async ({ db }) => {
  // Modifies shared organization
  await db.organization.update({ where: {...}, data: {...} });
});

test('test 2', async ({ db }) => {
  // Expects organization in original state - FAILS!
});
```

**Solution:**

```typescript
// ✅ CORRECT: Create data in beforeEach (fresh per test)
test.beforeEach(async ({ db }) => {
  await seedDatabase(db); // Fresh data per test
});
```

### Pitfall 4: Not Awaiting Prisma Operations

**Problem:**

```typescript
// ❌ WRONG: Forgetting await
test('create session', async ({ db }) => {
  db.session.create({ data: {...} }); // Missing await!

  const count = await db.session.count();
  expect(count).toBe(1); // Fails! Session not created yet
});
```

**Solution:**

```typescript
// ✅ CORRECT: Always await Prisma operations
test('create session', async ({ db }) => {
  await db.session.create({ data: {...} });

  const count = await db.session.count();
  expect(count).toBe(1); // ✅ Passes
});
```

### Pitfall 5: Database Locked Errors with WAL Mode

**Problem:**

```typescript
// ❌ WRONG: Multiple Prisma clients to same database
const db1 = new PrismaClient({ datasources: { db: { url: dbUrl } } });
const db2 = new PrismaClient({ datasources: { db: { url: dbUrl } } });

await db1.session.create({...}); // Works
await db2.session.create({...}); // May fail: SQLITE_BUSY
```

**Solution:**

```typescript
// ✅ CORRECT: Use single Prisma client per worker
// Fixture ensures one client per worker
test('use provided db fixture', async ({ db }) => {
  // db is singleton per worker
  await db.session.create({...}); // Always works
});
```

### Pitfall 6: Hardcoded IDs in Factories

**Problem:**

```typescript
// ❌ WRONG: Hardcoded IDs cause conflicts
async create() {
  return await this.db.organization.create({
    data: {
      name: 'Test Org', // Same name every time!
      email: 'test@example.com', // Unique constraint violation!
    },
  });
}
```

**Solution:**

```typescript
// ✅ CORRECT: Generate unique values
async create(overrides = {}) {
  return await this.db.organization.create({
    data: {
      name: overrides.name ?? this.uniqueName('Org'),
      email: overrides.email ?? this.uniqueEmail('org'),
      ...overrides,
    },
  });
}
```

### Pitfall 7: Not Testing with Production-Like Data

**Problem:**

```typescript
// ❌ WRONG: Minimal test data doesn't reveal issues
test('display sessions', async ({ db, page }) => {
  await db.session.create({ data: { title: 'Test' } });
  // Only 1 session - doesn't test pagination, performance, etc.
});
```

**Solution:**

```typescript
// ✅ CORRECT: Test with realistic data volumes
test('display sessions with realistic data', async ({ db, page }) => {
  const sessionFactory = new SessionFactory(db);

  // Create 50 sessions to test pagination
  for (let i = 0; i < 50; i++) {
    await sessionFactory.create({ title: `Session ${i}` });
  }

  await page.goto('/sessions');

  // Verify pagination works
  await expect(page.getByText('1 / 5')).toBeVisible(); // Page 1 of 5
});
```

---

## 7. AI Pair Programming Notes

### When to Load This File

Load `07-DATABASE-FIXTURES.md` when:

- **Setting up test infrastructure** - Need per-worker database pattern
- **Creating test data factories** - Want reusable, type-safe fixtures
- **Debugging flaky tests** - Database state or locking issues
- **Writing E2E tests** - Tests interact with Prisma database
- **Optimizing test performance** - Cleanup strategies, seeding patterns

### Combine With

- **[FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md)**: Section 3 for per-worker patterns
- **[01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md)**: For core Playwright concepts
- **[08-PARALLEL-ISOLATION.md](./08-PARALLEL-ISOLATION.md)**: For parallel execution patterns
- **[09-DEBUGGING-TROUBLESHOOTING.md](./09-DEBUGGING-TROUBLESHOOTING.md)**: For debugging database issues
- **[/docs/ARCHITECTURE.md](/docs/ARCHITECTURE.md)**: For Bloom's testing strategy

### Common AI Prompts

```
"Using 07-DATABASE-FIXTURES.md, set up per-worker SQLite databases for our Playwright tests with WAL mode cleanup."

"Reference 07-DATABASE-FIXTURES.md section 5.4. Create a factory for Bloom sessions with messages and ROI reports."

"Following 07-DATABASE-FIXTURES.md patterns, implement afterEach cleanup for our test suite with correct foreign key order."

"Use 07-DATABASE-FIXTURES.md section 4 to choose the right cleanup strategy for our test requirements."
```

### Key Takeaways

1. **Per-worker isolation**: Each Playwright worker = separate SQLite database
2. **WAL mode cleanup**: Delete `.db`, `.db-wal`, and `.db-shm` files
3. **Factories over magic values**: Use factories for consistent, unique test data
4. **afterEach cleanup**: Simple, reliable, recommended for Bloom
5. **Foreign key order**: Delete children before parents
6. **Type safety**: Leverage Prisma types in factories
7. **Realistic data**: Test with production-like data volumes

### Bloom-Specific Notes

- **SQLite WAL mode**: Bloom uses `?mode=wal`, remember to clean up WAL files
- **18 active sessions**: Consider creating factories for common patterns
- **No completed ROI reports yet**: Factories help create test data until production data exists
- **Prisma 5.22.0**: All patterns tested with this version
- **Next.js 16**: Per-worker databases compatible with App Router server components

---

## Related Files

- **[FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md)**: Next.js + Prisma integration
- **[01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md)**: Playwright core concepts
- **[08-PARALLEL-ISOLATION.md](./08-PARALLEL-ISOLATION.md)**: Parallel test execution
- **[09-DEBUGGING-TROUBLESHOOTING.md](./09-DEBUGGING-TROUBLESHOOTING.md)**: Debugging guide
- **[README.md](./README.md)**: Playwright KB overview
- **[INDEX.md](./INDEX.md)**: Full navigation

---

## Last Updated

2025-11-14
