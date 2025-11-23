---
id: jest-07-database-testing
topic: jest
file_role: practical
profile: full
difficulty_level: advanced
kb_version: 3.1
prerequisites: [jest-01-fundamentals, jest-03-mocking-spies, prisma-basics]
related_topics: [database-testing, prisma, sqlite, fixtures]
embedding_keywords: [jest, database-testing, prisma, sqlite, test-fixtures, test-data]
last_reviewed: 2025-11-14
---

# Database Testing with Jest

<!-- Query: "How do I test Prisma database operations?" -->
<!-- Query: "Testing database queries with Jest" -->
<!-- Query: "How to create test fixtures for database tests?" -->
<!-- Query: "SQLite testing with Prisma and Jest" -->

## 1. Purpose

This guide teaches you how to test database operations with Jest, Prisma, and SQLite. You'll learn:

- **Testing Prisma queries** (create, read, update, delete) with real and mocked databases
- **Test fixtures and factories** for generating consistent test data
- **Database cleanup strategies** to prevent test pollution and flakiness
- **Transaction testing** and rollback strategies
- **Testing relationships** (one-to-many, many-to-many) in Prisma models
- **Mocking Prisma Client** for fast unit tests vs real database integration tests
- **SQLite WAL mode considerations** specific to Bloom's configuration
- **Real Bloom examples**: Sessions, Messages, ROI Reports, Organizations

**When to use this guide:**
- Writing tests for database models and queries
- Creating test data factories
- Debugging flaky database tests
- Setting up test database isolation
- Testing complex Prisma queries with joins

**Related guides:**
- `03-MOCKING-SPIES.md` - For mocking Prisma Client in unit tests
- `06-API-TESTING.md` - For testing API routes that use databases
- `FRAMEWORK-INTEGRATION-PATTERNS.md` - For Prisma integration patterns

---

## 2. Mental Model / Problem Statement

<!-- Query: "Unit tests vs integration tests for databases" -->
<!-- Query: "When to mock Prisma vs use real database?" -->
<!-- Query: "Database testing mental model" -->

### 2.1 The Database Testing Spectrum

Database tests exist on a spectrum from **mocked** to **real**:

```
Unit Tests                    Integration Tests              E2E Tests
─────────────────────────────────────────────────────────────────────
│                             │                              │
│ Mock Prisma Client:         │ Real test database:          │ Real prod database:
│ - Fast (< 10ms)             │ - Medium (50-200ms)          │ - Slow (100-1000ms)
│ - No setup needed           │ - Requires setup/teardown    │ - Full environment
│ - Test logic only           │ - Test queries + DB          │ - Test migrations
│ - Can't catch SQL bugs      │ - Catches real bugs          │ - Catches config bugs
│                             │                              │
│ RECOMMENDED FOR:            │ RECOMMENDED FOR:             │ RECOMMENDED FOR:
│ - Business logic            │ - Complex queries            │ - Migration validation
│ - Validation rules          │ - Relationships              │ - Deployment smoke tests
│ - Error handling            │ - Transactions               │ - Production debugging
└─────────────────────────────┴──────────────────────────────┴─────────────────────
```

**Bloom's Testing Strategy:**

1. **Unit tests (Mocked Prisma)**: Fast tests for business logic (70% of tests)
2. **Integration tests (Real SQLite)**: Tests for complex queries and relationships (25% of tests)
3. **E2E tests (Real database + API)**: Full workflow tests via Playwright (5% of tests)

### 2.2 Prisma Test Isolation Strategies

**Problem:** Tests that share a database can interfere with each other.

**Solution:** Choose an isolation strategy:

| Strategy | Speed | Isolation | Complexity | Best For |
|----------|-------|-----------|------------|----------|
| **Separate test DB per run** | Medium | Perfect | Low | CI/CD pipelines |
| **Transactions with rollback** | Fast | Perfect | Medium | Unit tests |
| **Cleanup in afterEach** | Medium | Good | Low | Integration tests |
| **In-memory SQLite** | Very Fast | Perfect | Low | Unit tests |
| **Mocked Prisma Client** | Fastest | Perfect | Medium | Pure logic tests |

**Bloom uses:** In-memory SQLite for fast tests + cleanup in `afterEach` for integration tests.

### 2.3 SQLite WAL Mode and Testing

Bloom uses **SQLite in WAL (Write-Ahead Logging) mode** for better concurrent read/write performance.

**What this means for testing:**

```sql
-- WAL mode allows:
✅ Multiple readers at once
✅ One writer + multiple readers
❌ Multiple writers (will block/retry)
```

**Testing implications:**

- **Parallel tests**: Use separate database files per worker (Jest's `--maxWorkers`)
- **Database locks**: Properly close connections in `afterAll()` to avoid locks
- **WAL files**: `.db-wal` and `.db-shm` files are created (normal behavior)
- **Cleanup**: Always disconnect Prisma before deleting test databases

```typescript
// ✅ CORRECT: Proper cleanup prevents "database locked" errors
afterAll(async () => {
  await prisma.$disconnect(); // Close connections first
  // Now safe to delete test database
});
```

### 2.4 The Test Data Lifecycle

Every database test follows this lifecycle:

```typescript
describe("Database Test", () => {
  // SETUP PHASE (once per test suite)
  beforeAll(async () => {
    // 1. Create test database
    // 2. Run migrations
    // 3. Create Prisma client
  });

  // SETUP PHASE (before each test)
  beforeEach(async () => {
    // 4. Seed minimal required data
    // 5. Clear previous test data (optional)
  });

  // TEST PHASE
  it("should create a session", async () => {
    // 6. Arrange: Create test data
    // 7. Act: Execute database operation
    // 8. Assert: Verify results
  });

  // TEARDOWN PHASE (after each test)
  afterEach(async () => {
    // 9. Clean up test data (delete created records)
  });

  // TEARDOWN PHASE (once per test suite)
  afterAll(async () => {
    // 10. Disconnect Prisma client
    // 11. Delete test database (optional)
  });
});
```

---

## 3. Golden Path

<!-- Query: "Best practices for Prisma testing" -->
<!-- Query: "How to structure database tests" -->
<!-- Query: "Recommended database testing approach" -->

### 3.1 Recommended Test Setup for Bloom

**File structure:**

```
__tests__/
├── db/
│   ├── sessions.test.ts         # Session model tests
│   ├── roi-reports.test.ts      # ROI report tests
│   ├── responses.test.ts        # Response tests
│   └── helpers/
│       ├── test-db.ts           # Test database setup
│       ├── factories.ts         # Test data factories
│       └── cleanup.ts           # Cleanup utilities
├── fixtures/
│   ├── sessions.json            # Static test data
│   └── organizations.json       # Seed data
└── integration/
    └── api-with-db.test.ts      # Full API + DB tests
```

### 3.2 Test Database Setup (Real SQLite)

**Best practice:** Use a separate in-memory database for each test suite.

```typescript
// __tests__/db/helpers/test-db.ts
import { PrismaClient } from '@prisma/client';
import { execSync } from 'child_process';
import * as fs from 'fs';
import * as path from 'path';

// Generate unique database file for this test run
const testDbPath = path.join(
  __dirname,
  `../../../test-dbs/test-${Date.now()}-${Math.random().toString(36).substring(7)}.db`
);

export async function setupTestDatabase(): Promise<PrismaClient> {
  // Ensure test-dbs directory exists
  const dir = path.dirname(testDbPath);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }

  // Set DATABASE_URL for migrations
  process.env.DATABASE_URL = `file:${testDbPath}`;

  // Run migrations to create schema
  execSync('npx prisma migrate deploy', {
    env: { ...process.env, DATABASE_URL: `file:${testDbPath}` }
  });

  // Create Prisma client with test database
  const prisma = new PrismaClient({
    datasources: {
      db: {
        url: `file:${testDbPath}?mode=wal` // Enable WAL mode
      }
    }
  });

  return prisma;
}

export async function teardownTestDatabase(prisma: PrismaClient): Promise<void> {
  // Disconnect first (prevents "database locked" errors)
  await prisma.$disconnect();

  // Delete test database files
  try {
    if (fs.existsSync(testDbPath)) fs.unlinkSync(testDbPath);
    if (fs.existsSync(`${testDbPath}-wal`)) fs.unlinkSync(`${testDbPath}-wal`);
    if (fs.existsSync(`${testDbPath}-shm`)) fs.unlinkSync(`${testDbPath}-shm`);
  } catch (error) {
    console.error('Failed to delete test database:', error);
  }
}
```

### 3.3 Test Data Factories (Recommended Pattern)

**Best practice:** Use factory functions to generate consistent test data.

```typescript
// __tests__/db/helpers/factories.ts
import { PrismaClient } from '@prisma/client';
import { faker } from '@faker-js/faker'; // npm install -D @faker-js/faker

export interface SessionFactory {
  userId?: string;
  organizationId?: string;
  title?: string;
  status?: string;
  customerName?: string;
  problemStatement?: string;
  employeeCount?: number;
}

export class TestDataFactory {
  constructor(private prisma: PrismaClient) {}

  /**
   * Create an organization with sensible defaults
   */
  async createOrganization(overrides?: Partial<any>) {
    return await this.prisma.organization.create({
      data: {
        name: overrides?.name || faker.company.name(),
        industry: overrides?.industry || 'technology',
        size: overrides?.size || 'medium',
        maxUsers: overrides?.maxUsers || 10,
        maxSessions: overrides?.maxSessions || 100,
        maxApiCalls: overrides?.maxApiCalls || 10000,
        billingStatus: overrides?.billingStatus || 'active',
        subscriptionTier: overrides?.subscriptionTier || 'free',
        ...overrides
      }
    });
  }

  /**
   * Create a user with sensible defaults
   */
  async createUser(organizationId: string, overrides?: Partial<any>) {
    return await this.prisma.user.create({
      data: {
        email: overrides?.email || faker.internet.email(),
        name: overrides?.name || faker.person.fullName(),
        role: overrides?.role || 'user',
        organizationId,
        password: overrides?.password || 'hashed_password_here',
        ...overrides
      }
    });
  }

  /**
   * Create a session with sensible defaults
   */
  async createSession(overrides?: SessionFactory) {
    return await this.prisma.session.create({
      data: {
        title: overrides?.title || 'Test Session',
        status: overrides?.status || 'active',
        userId: overrides?.userId || null,
        organizationId: overrides?.organizationId || null,
        customerName: overrides?.customerName || faker.company.name(),
        problemStatement: overrides?.problemStatement || 'Test problem',
        employeeCount: overrides?.employeeCount || faker.number.int({ min: 10, max: 1000 }),
        contextComplete: true,
        startedAt: new Date(),
        ...overrides
      }
    });
  }

  /**
   * Create a session with responses and ROI report
   */
  async createCompleteSession(overrides?: SessionFactory) {
    const session = await this.createSession(overrides);

    // Add responses
    await this.prisma.response.createMany({
      data: [
        {
          sessionId: session.id,
          questionId: 'q1',
          question: 'What process are you optimizing?',
          answer: 'Invoice processing',
          confidence: 0.9
        },
        {
          sessionId: session.id,
          questionId: 'q2',
          question: 'How many hours per week?',
          answer: '20 hours',
          confidence: 0.85
        }
      ]
    });

    // Add ROI report
    const report = await this.prisma.rOIReport.create({
      data: {
        sessionId: session.id,
        totalROI: 150.5,
        netPresentValue: 125000,
        internalRateReturn: 35.2,
        paybackPeriod: 12,
        totalCostOwnership: 50000,
        confidenceScore: 85.5
      }
    });

    return { session, report };
  }

  /**
   * Clean up all test data
   */
  async cleanup() {
    // Delete in reverse order of dependencies
    await this.prisma.rOIReport.deleteMany({});
    await this.prisma.response.deleteMany({});
    await this.prisma.session.deleteMany({});
    await this.prisma.user.deleteMany({});
    await this.prisma.organization.deleteMany({});
  }
}
```

### 3.4 Standard Test Pattern for Prisma Queries

**Pattern 1: Testing CRUD operations**

```typescript
// __tests__/db/sessions.test.ts
import { setupTestDatabase, teardownTestDatabase } from './helpers/test-db';
import { TestDataFactory } from './helpers/factories';
import { PrismaClient } from '@prisma/client';

describe('Session Database Operations', () => {
  let prisma: PrismaClient;
  let factory: TestDataFactory;

  beforeAll(async () => {
    prisma = await setupTestDatabase();
    factory = new TestDataFactory(prisma);
  });

  afterEach(async () => {
    await factory.cleanup(); // Clean up after each test
  });

  afterAll(async () => {
    await teardownTestDatabase(prisma);
  });

  describe('CREATE operations', () => {
    it('should create a session with required fields', async () => {
      // Arrange
      const sessionData = {
        title: 'ROI Discovery Session',
        status: 'active',
        customerName: 'Acme Corp',
        problemStatement: 'Manual invoice processing'
      };

      // Act
      const session = await prisma.session.create({
        data: sessionData
      });

      // Assert
      expect(session).toBeDefined();
      expect(session.id).toBeTruthy();
      expect(session.title).toBe(sessionData.title);
      expect(session.status).toBe('active');
      expect(session.startedAt).toBeInstanceOf(Date);
    });

    it('should create a session with relationships', async () => {
      // Arrange
      const org = await factory.createOrganization();
      const user = await factory.createUser(org.id);

      // Act
      const session = await prisma.session.create({
        data: {
          title: 'Test Session',
          userId: user.id,
          organizationId: org.id
        },
        include: {
          user: true,
          organization: true
        }
      });

      // Assert
      expect(session.user).toBeDefined();
      expect(session.user?.id).toBe(user.id);
      expect(session.organization).toBeDefined();
      expect(session.organization?.id).toBe(org.id);
    });
  });

  describe('READ operations', () => {
    it('should find a session by id', async () => {
      // Arrange
      const created = await factory.createSession({
        title: 'Find Me'
      });

      // Act
      const found = await prisma.session.findUnique({
        where: { id: created.id }
      });

      // Assert
      expect(found).toBeDefined();
      expect(found?.id).toBe(created.id);
      expect(found?.title).toBe('Find Me');
    });

    it('should filter sessions by status', async () => {
      // Arrange
      await factory.createSession({ status: 'active' });
      await factory.createSession({ status: 'active' });
      await factory.createSession({ status: 'completed' });

      // Act
      const activeSessions = await prisma.session.findMany({
        where: { status: 'active' }
      });

      // Assert
      expect(activeSessions).toHaveLength(2);
      activeSessions.forEach(session => {
        expect(session.status).toBe('active');
      });
    });

    it('should include nested relationships', async () => {
      // Arrange
      const { session } = await factory.createCompleteSession();

      // Act
      const found = await prisma.session.findUnique({
        where: { id: session.id },
        include: {
          responses: true,
          roiReport: true
        }
      });

      // Assert
      expect(found?.responses).toHaveLength(2);
      expect(found?.roiReport).toBeDefined();
      expect(found?.roiReport?.totalROI).toBe(150.5);
    });
  });

  describe('UPDATE operations', () => {
    it('should update a session status', async () => {
      // Arrange
      const session = await factory.createSession({ status: 'active' });

      // Act
      const updated = await prisma.session.update({
        where: { id: session.id },
        data: {
          status: 'completed',
          completedAt: new Date()
        }
      });

      // Assert
      expect(updated.status).toBe('completed');
      expect(updated.completedAt).toBeInstanceOf(Date);
    });

    it('should increment employee count', async () => {
      // Arrange
      const session = await factory.createSession({ employeeCount: 100 });

      // Act
      const updated = await prisma.session.update({
        where: { id: session.id },
        data: {
          employeeCount: { increment: 50 }
        }
      });

      // Assert
      expect(updated.employeeCount).toBe(150);
    });
  });

  describe('DELETE operations', () => {
    it('should delete a session', async () => {
      // Arrange
      const session = await factory.createSession();

      // Act
      await prisma.session.delete({
        where: { id: session.id }
      });

      // Assert
      const found = await prisma.session.findUnique({
        where: { id: session.id }
      });
      expect(found).toBeNull();
    });

    it('should cascade delete responses when session is deleted', async () => {
      // Arrange
      const { session } = await factory.createCompleteSession();

      // Act
      await prisma.session.delete({
        where: { id: session.id }
      });

      // Assert
      const responses = await prisma.response.findMany({
        where: { sessionId: session.id }
      });
      expect(responses).toHaveLength(0);
    });
  });
});
```

---

## 4. Variations & Trade-Offs

<!-- Query: "When to use real database vs mocked Prisma?" -->
<!-- Query: "Database testing strategies comparison" -->
<!-- Query: "Prisma mocking approaches" -->

### 4.1 Mocked Prisma Client vs Real Database

**Approach 1: Mocked Prisma Client (Fast Unit Tests)**

✅ **Pros:**
- Very fast (< 10ms per test)
- No database setup required
- Can simulate any error condition
- Perfect isolation between tests

❌ **Cons:**
- Won't catch SQL syntax errors
- Won't catch migration issues
- Won't test actual Prisma behavior
- More mocking code to maintain

**When to use:** Testing business logic, validation, error handling

```typescript
// Example: Mocked Prisma for testing validation logic
import { PrismaClient } from '@prisma/client';
import { mockDeep, mockReset, DeepMockProxy } from 'jest-mock-extended';

const prismaMock = mockDeep<PrismaClient>() as DeepMockProxy<PrismaClient>;

beforeEach(() => {
  mockReset(prismaMock);
});

it('should validate session status before update', async () => {
  // Arrange
  prismaMock.session.findUnique.mockResolvedValue({
    id: 'session-1',
    status: 'completed',
    // ... other fields
  } as any);

  // Act & Assert
  await expect(
    updateSessionStatus('session-1', 'active')
  ).rejects.toThrow('Cannot reactivate completed session');
});
```

**Approach 2: Real Test Database (Integration Tests)**

✅ **Pros:**
- Tests actual database behavior
- Catches SQL and schema issues
- Tests relationships and joins
- More confidence in production behavior

❌ **Cons:**
- Slower (50-200ms per test)
- Requires setup and teardown
- Can have test data pollution
- Harder to simulate errors

**When to use:** Testing complex queries, relationships, transactions

```typescript
// Example: Real database for testing relationships
it('should load session with all relationships', async () => {
  // Real database test (as shown in section 3.4)
  const { session } = await factory.createCompleteSession();

  const loaded = await prisma.session.findUnique({
    where: { id: session.id },
    include: {
      responses: true,
      roiReport: true,
      user: true,
      organization: true
    }
  });

  expect(loaded?.responses).toBeDefined();
  expect(loaded?.roiReport).toBeDefined();
});
```

### 4.2 Transaction Testing Strategies

**Strategy 1: Manual Transaction Rollback**

```typescript
it('should rollback transaction on error', async () => {
  await expect(
    prisma.$transaction(async (tx) => {
      // Create session
      await tx.session.create({
        data: { title: 'Test' }
      });

      // This will fail and rollback everything
      throw new Error('Simulated error');
    })
  ).rejects.toThrow('Simulated error');

  // Verify rollback
  const sessions = await prisma.session.findMany();
  expect(sessions).toHaveLength(0);
});
```

**Strategy 2: Nested Transaction Testing**

```typescript
it('should create session with responses atomically', async () => {
  const result = await prisma.$transaction(async (tx) => {
    const session = await tx.session.create({
      data: { title: 'ROI Session' }
    });

    await tx.response.createMany({
      data: [
        { sessionId: session.id, questionId: 'q1', question: 'Q1', answer: 'A1' },
        { sessionId: session.id, questionId: 'q2', question: 'Q2', answer: 'A2' }
      ]
    });

    return tx.session.findUnique({
      where: { id: session.id },
      include: { responses: true }
    });
  });

  expect(result?.responses).toHaveLength(2);
});
```

---

## 5. Examples

<!-- Query: "Bloom database test examples" -->
<!-- Query: "Real-world Prisma test examples" -->

### 5.1 Testing Session Creation with Context Data

```typescript
describe('Session Context Management', () => {
  it('should create session with complete context data', async () => {
    // Arrange
    const contextData = {
      title: 'Invoice Processing ROI',
      customerName: 'Acme Manufacturing',
      customerIndustry: 'manufacturing',
      customerLocation: 'Chicago, IL',
      problemStatement: 'Manual invoice entry taking 40 hours/week',
      department: 'Finance',
      employeeCount: 250,
      annualRevenue: '$50M-$100M',
      fiscalYearStart: 'January',
      contextComplete: true
    };

    // Act
    const session = await prisma.session.create({
      data: contextData
    });

    // Assert
    expect(session.customerName).toBe('Acme Manufacturing');
    expect(session.employeeCount).toBe(250);
    expect(session.contextComplete).toBe(true);
  });

  it('should query sessions by problem statement keywords', async () => {
    // Arrange
    await factory.createSession({
      problemStatement: 'Manual invoice processing is slow'
    });
    await factory.createSession({
      problemStatement: 'Data entry automation needed'
    });
    await factory.createSession({
      problemStatement: 'Invoice approval workflow'
    });

    // Act
    const invoiceSessions = await prisma.session.findMany({
      where: {
        problemStatement: {
          contains: 'invoice'
        }
      }
    });

    // Assert
    expect(invoiceSessions).toHaveLength(2);
  });
});
```

### 5.2 Testing ROI Report Relationships

```typescript
describe('ROI Report with Session', () => {
  it('should create ROI report linked to session', async () => {
    // Arrange
    const session = await factory.createSession();

    // Act
    const report = await prisma.rOIReport.create({
      data: {
        sessionId: session.id,
        totalROI: 225.8,
        netPresentValue: 185000,
        internalRateReturn: 42.5,
        paybackPeriod: 8,
        confidenceScore: 87.2
      }
    });

    // Assert
    const sessionWithReport = await prisma.session.findUnique({
      where: { id: session.id },
      include: { roiReport: true }
    });

    expect(sessionWithReport?.roiReport).toBeDefined();
    expect(sessionWithReport?.roiReport?.totalROI).toBe(225.8);
  });

  it('should enforce one-to-one relationship (session can have only one report)', async () => {
    // Arrange
    const session = await factory.createSession();
    await prisma.rOIReport.create({
      data: {
        sessionId: session.id,
        totalROI: 100,
        confidenceScore: 80
      }
    });

    // Act & Assert - Creating second report for same session should fail
    await expect(
      prisma.rOIReport.create({
        data: {
          sessionId: session.id,
          totalROI: 200,
          confidenceScore: 90
        }
      })
    ).rejects.toThrow(); // Unique constraint violation
  });
});
```

### 5.3 Testing Organization and User Relationships

```typescript
describe('Organization Multi-Tenancy', () => {
  it('should isolate sessions by organization', async () => {
    // Arrange
    const org1 = await factory.createOrganization({ name: 'Org 1' });
    const org2 = await factory.createOrganization({ name: 'Org 2' });

    await factory.createSession({ organizationId: org1.id });
    await factory.createSession({ organizationId: org1.id });
    await factory.createSession({ organizationId: org2.id });

    // Act
    const org1Sessions = await prisma.session.findMany({
      where: { organizationId: org1.id }
    });

    // Assert
    expect(org1Sessions).toHaveLength(2);
  });

  it('should cascade delete sessions when organization is deleted', async () => {
    // Arrange
    const org = await factory.createOrganization();
    await factory.createSession({ organizationId: org.id });
    await factory.createSession({ organizationId: org.id });

    // Act
    await prisma.organization.delete({
      where: { id: org.id }
    });

    // Assert
    const orphanedSessions = await prisma.session.findMany({
      where: { organizationId: org.id }
    });
    expect(orphanedSessions).toHaveLength(0);
  });
});
```

---

## 6. Common Pitfalls

<!-- Query: "Database testing mistakes to avoid" -->
<!-- Query: "Prisma testing common errors" -->

### 6.1 Not Disconnecting Prisma Client

❌ **WRONG: Forgetting to disconnect**

```typescript
afterAll(async () => {
  // Missing: await prisma.$disconnect();
  // This causes "database locked" errors and resource leaks
});
```

✅ **CORRECT: Always disconnect**

```typescript
afterAll(async () => {
  await prisma.$disconnect(); // Always disconnect
});
```

**Why this matters:** Unclosed connections lock the database file and prevent cleanup.

### 6.2 Test Data Pollution

❌ **WRONG: Tests depend on previous test data**

```typescript
it('should find 3 sessions', async () => {
  // This assumes data from previous tests exists
  const sessions = await prisma.session.findMany();
  expect(sessions).toHaveLength(3); // Flaky!
});
```

✅ **CORRECT: Each test creates its own data**

```typescript
it('should find 3 sessions', async () => {
  // Create data within the test
  await factory.createSession();
  await factory.createSession();
  await factory.createSession();

  const sessions = await prisma.session.findMany();
  expect(sessions).toHaveLength(3); // Reliable
});
```

### 6.3 Not Testing Relationship Constraints

❌ **WRONG: Not testing foreign key constraints**

```typescript
it('should create response', async () => {
  const response = await prisma.response.create({
    data: {
      sessionId: 'non-existent-id', // This will fail!
      questionId: 'q1',
      question: 'Test',
      answer: 'Test'
    }
  });
});
```

✅ **CORRECT: Test constraint violations**

```typescript
it('should fail to create response without valid session', async () => {
  await expect(
    prisma.response.create({
      data: {
        sessionId: 'non-existent-id',
        questionId: 'q1',
        question: 'Test',
        answer: 'Test'
      }
    })
  ).rejects.toThrow(); // Foreign key constraint
});
```

### 6.4 Overly Complex Factories

❌ **WRONG: Factory creates too much data**

```typescript
async createSession() {
  const org = await this.createOrganization();
  const user = await this.createUser(org.id);
  const session = await this.prisma.session.create({
    data: { userId: user.id, organizationId: org.id }
  });
  // Creates 10 responses, 5 files, branding config...
  // Way more than most tests need!
  return session;
}
```

✅ **CORRECT: Minimal factories with optional extensions**

```typescript
async createSession(overrides?: { withResponses?: boolean; withReport?: boolean }) {
  const session = await this.prisma.session.create({
    data: { title: 'Test' }
  });

  if (overrides?.withResponses) {
    await this.addResponses(session.id);
  }

  if (overrides?.withReport) {
    await this.addReport(session.id);
  }

  return session;
}
```

---

## 7. AI Pair Programming Notes

**Critical for Bloom:**
- Session CRUD operations
- ROI report calculations
- User/organization relationships
- Multi-tenant data isolation

**Load with:**
- `FRAMEWORK-INTEGRATION-PATTERNS.md` (Prisma section)
- `06-API-TESTING.md` (for API + DB integration tests)

**Common AI prompts:**

1. "Using the factory pattern from `docs/kb/testing/jest/07-DATABASE-TESTING.md`, create test data for a complete ROI workshop session with responses and report."

2. "Following the cleanup strategy in `07-DATABASE-TESTING.md`, help me prevent test data pollution in my session tests."

3. "Using the real database approach from `07-DATABASE-TESTING.md`, write integration tests for the session API with Prisma queries."

## Last Updated

2025-11-14
