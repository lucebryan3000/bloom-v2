---
id: jest-09-performance-optimization
topic: jest
file_role: advanced
profile: full
difficulty_level: advanced
kb_version: 3.1
prerequisites: [jest-01-fundamentals, jest-11-config-operations]
related_topics: [performance, optimization, ci-cd]
embedding_keywords: [jest, performance, optimization, parallel-testing, test-speed]
last_reviewed: 2025-11-14
---

# Jest Performance Optimization

**Speed Up Test Execution Through Parallelization, Caching, and Smart Configuration**

---

## 1. Purpose

This guide covers optimization strategies for Jest test suites, focusing on:
- **Parallel execution**: Maximizing CPU utilization across test workers
- **Intelligent caching**: Leveraging Jest's built-in cache for faster reruns
- **Selective testing**: Running only tests affected by code changes
- **Setup optimization**: Reducing overhead in beforeEach/afterEach hooks
- **Import minimization**: Speeding up module resolution and initialization
- **Mock efficiency**: Optimizing mock creation and cleanup
- **CI/CD tuning**: Environment-specific optimizations

**Performance Impact**: Proper optimization can reduce test suite execution from minutes to seconds.

---

## 2. Mental Model / Problem Statement

### Why Tests Slow Down

**Common Bottlenecks**:
1. **Serial execution**: Default Jest runs tests in parallel, but improper configuration limits this
2. **Module loading**: Large imports (entire libraries) vs. targeted imports
3. **Setup/teardown overhead**: Expensive operations in beforeEach/afterEach run repeatedly
4. **Database operations**: SQLite connections, migrations, seed data for every test
5. **Unmocked external services**: Network calls, file I/O, third-party APIs
6. **Cache misses**: Rebuilding transformed modules on every run
7. **Large test suites**: 1000+ tests without proper parallelization

### Performance Hierarchy

```
Fastest → Slowest
─────────────────
1. Cached, unchanged tests (skipped via --onlyChanged)
2. Parallel execution across workers (maxWorkers optimization)
3. Optimized imports (tree-shaking, selective imports)
4. Efficient mocks (module-level, not per-test)
5. Minimal setup/teardown (shared fixtures)
6. Database operations (in-memory SQLite)
7. Real I/O operations (file system, network)
```

### Bloom Context

**Current Scale** (as of Nov 2025):
- Database: 18 active sessions, 1 organization, 0 ROI reports
- Test suite: Growing with each feature (sessions, ROI, Melissa AI)
- Database: SQLite with WAL mode (better concurrent performance)
- CI/CD: Need fast feedback loops for feature development

**Goal**: Keep test suite under 30 seconds locally, under 60 seconds in CI.

---

## 3. Golden Path

### 3.1 Parallel Execution Configuration

**jest.config.js**:
```javascript
module.exports = {
  // Optimal worker count (default: CPU cores - 1)
  maxWorkers: process.env.CI ? 2 : '50%',

  // Run tests in parallel (default: true)
  runInBand: false, // Only use for debugging

  // Maximum concurrent workers
  maxConcurrency: 5, // For describe/test.concurrent blocks
};
```

**Worker Tuning**:
```bash
# Local development (use half of CPU cores)
jest --maxWorkers=50%

# CI environment (fixed worker count to avoid memory issues)
jest --maxWorkers=2

# Debugging (serial execution)
jest --runInBand
```

**Rule of Thumb**:
- **Local**: `50%` or `CPU_CORES - 1` (leave room for IDE, browser)
- **CI**: Fixed count (2-4) to control memory usage
- **Memory-constrained**: Lower workers if hitting OOM errors

### 3.2 Test Caching Strategy

**Enable Transform Caching**:
```javascript
// jest.config.js
module.exports = {
  cache: true, // Default: true
  cacheDirectory: '/tmp/jest_cache', // Custom cache location

  // Clear cache if config changes
  clearMocks: true,
  resetMocks: false, // Don't clear cache between tests
};
```

**Cache Commands**:
```bash
# Use cache (default)
npm test

# Clear cache and run
npm test -- --clearCache
npm test -- --no-cache

# Check cache size
du -sh /tmp/jest_cache
```

**When to Clear Cache**:
- Jest config changes (transformers, moduleNameMapper)
- Dependency version updates (major versions)
- Unexplained test failures (rare, but happens)
- Switching branches with major structural changes

### 3.3 Selective Testing

**Git-Aware Testing**:
```bash
# Run only tests related to changed files
npm test -- --onlyChanged

# Since specific commit/branch
npm test -- --changedSince=origin/main
npm test -- --changedSince=HEAD~3

# Show which tests would run
npm test -- --listTests --changedSince=main
```

**Watch Mode Optimization**:
```bash
# Interactive watch mode (runs only changed tests)
npm test -- --watch

# Watch all tests
npm test -- --watchAll

# Watch with coverage
npm test -- --watch --coverage
```

**package.json scripts**:
```json
{
  "scripts": {
    "test": "jest",
    "test:changed": "jest --onlyChanged",
    "test:watch": "jest --watch",
    "test:ci": "jest --maxWorkers=2 --coverage --ci"
  }
}
```

### 3.4 Setup/Teardown Optimization

**❌ Bad: Expensive Setup Per Test**
```typescript
describe('SessionService', () => {
  let db: PrismaClient;

  beforeEach(async () => {
    // SLOW: New DB connection + migrations per test
    db = new PrismaClient();
    await db.$executeRaw`DELETE FROM Session`;
    await seedDatabase(db); // Expensive!
  });

  afterEach(async () => {
    await db.$disconnect();
  });
});
```

**✅ Good: Shared Setup, Test-Specific Data**
```typescript
describe('SessionService', () => {
  // Shared DB connection (once per file)
  const db = new PrismaClient();

  beforeAll(async () => {
    // Run migrations once
    await migrateDatabase();
  });

  beforeEach(async () => {
    // Only clean data, not schema
    await db.session.deleteMany();
  });

  afterAll(async () => {
    // Cleanup once
    await db.$disconnect();
  });

  it('creates session', async () => {
    // Create only what you need
    const session = await createTestSession({ title: 'Test' });
    expect(session).toBeDefined();
  });
});
```

**Key Principles**:
- `beforeAll`/`afterAll`: Expensive setup (DB connections, server startup)
- `beforeEach`/`afterEach`: Cheap data cleanup only
- Lazy initialization: Create resources only when needed
- Shared fixtures: Import test data, don't generate dynamically

### 3.5 Import Optimization

**❌ Bad: Large, Unused Imports**
```typescript
import * as _ from 'lodash'; // Entire library!
import * as fs from 'fs'; // All file system methods
import { PrismaClient } from '@prisma/client'; // Heavy ORM
```

**✅ Good: Targeted Imports**
```typescript
import { pick, omit } from 'lodash'; // Only what you need
import { readFileSync } from 'fs'; // Specific method
import type { PrismaClient } from '@prisma/client'; // Type-only import
```

**Tree-Shaking in Tests**:
```typescript
// Use ES modules (better tree-shaking)
import { calculateROI } from '@/lib/roi/calculator';

// Avoid CommonJS (no tree-shaking)
const calculator = require('@/lib/roi/calculator');
```

**Mock Heavy Dependencies**:
```typescript
// Mock Prisma globally (avoid loading entire client)
jest.mock('@prisma/client', () => ({
  PrismaClient: jest.fn().mockImplementation(() => ({
    session: {
      findMany: jest.fn(),
      create: jest.fn(),
    },
  })),
}));
```

### 3.6 Mock Optimization

**❌ Bad: Mock Creation Per Test**
```typescript
describe('API', () => {
  it('test 1', () => {
    jest.mock('@/lib/db'); // SLOW: Hoisted, but re-evaluated
    // test logic
  });

  it('test 2', () => {
    jest.mock('@/lib/db'); // Duplicate mock
    // test logic
  });
});
```

**✅ Good: Module-Level Mocks**
```typescript
// At top of file (hoisted automatically)
jest.mock('@/lib/db');
jest.mock('@/lib/melissa/agent');

describe('API', () => {
  beforeEach(() => {
    // Only reset mock state, not definition
    jest.clearAllMocks();
  });

  it('test 1', () => {
    // Use existing mock
  });
});
```

**Mock Factories for Reuse**:
```typescript
// __mocks__/prisma.ts
export const mockPrismaClient = {
  session: {
    findMany: jest.fn().mockResolvedValue([]),
    create: jest.fn().mockResolvedValue({ id: '1', title: 'Test' }),
  },
  $disconnect: jest.fn(),
};

// test file
import { mockPrismaClient } from '../__mocks__/prisma';

jest.mock('@prisma/client', () => ({
  PrismaClient: jest.fn(() => mockPrismaClient),
}));
```

---

## 4. Variations & Trade-Offs

### Parallel vs Serial Execution

| Approach | Speed | Memory | Use Case |
|----------|-------|--------|----------|
| `maxWorkers=50%` | Fast | Medium | Local development |
| `maxWorkers=2` | Medium | Low | CI/CD (limited resources) |
| `--runInBand` | Slow | Low | Debugging, SQLite conflicts |

**When to Use Serial** (`--runInBand`):
- Debugging specific test failures
- SQLite database locking issues (rare with WAL mode)
- Investigating race conditions
- Limited RAM (< 2GB available)

### Caching Trade-Offs

| Strategy | Speed | Safety | Use Case |
|----------|-------|--------|----------|
| Full caching | Fastest | Medium | Stable codebase |
| `--no-cache` | Slow | High | Debugging, CI verification |
| `--clearCache` | Medium | High | After major changes |

**Bloom Recommendation**: Enable caching by default, clear only when needed.

### Selective Testing Strategies

```bash
# Strategy 1: Changed files only (fastest)
jest --onlyChanged

# Strategy 2: Affected tests via coverage map (smart)
jest --findRelatedTests src/lib/roi/calculator.ts

# Strategy 3: Test suite subset (manual control)
jest --testPathPattern=api

# Strategy 4: Full suite (slowest, most thorough)
jest
```

---

## 5. Examples

### 5.1 Bloom-Specific: Session Service Tests

```typescript
// tests/lib/session-service.test.ts
import { PrismaClient } from '@prisma/client';
import { createSession, resumeSession } from '@/lib/session-service';

describe('SessionService Performance', () => {
  let db: PrismaClient;

  // Shared connection (once per file)
  beforeAll(async () => {
    db = new PrismaClient({
      datasources: { db: { url: process.env.DATABASE_URL } },
    });
  });

  // Quick data cleanup
  beforeEach(async () => {
    await db.session.deleteMany({ where: { title: { startsWith: 'Test' } } });
  });

  afterAll(async () => {
    await db.$disconnect();
  });

  // Fast tests (no expensive setup)
  it('creates session in < 100ms', async () => {
    const start = Date.now();
    const session = await createSession(db, { title: 'Test Session' });
    const duration = Date.now() - start;

    expect(session).toBeDefined();
    expect(duration).toBeLessThan(100); // Performance assertion
  });

  it('resumes session without re-querying', async () => {
    // Shared fixture (created once, used multiple times)
    const session = await createSession(db, { title: 'Test Resume' });

    // Multiple tests use same session (no recreation)
    const resumed1 = await resumeSession(db, session.id);
    const resumed2 = await resumeSession(db, session.id);

    expect(resumed1.id).toBe(session.id);
    expect(resumed2.id).toBe(session.id);
  });
});
```

### 5.2 CI/CD Optimization (GitHub Actions)

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0 # For --changedSince

      - uses: actions/setup-node@v3
        with:
          node-version: 18
          cache: 'npm'

      - run: npm ci

      # Strategy 1: Run only changed tests (PRs)
      - name: Test Changed Files
        if: github.event_name == 'pull_request'
        run: npm test -- --changedSince=origin/${{ github.base_ref }} --maxWorkers=2

      # Strategy 2: Full suite (main branch)
      - name: Test All
        if: github.event_name == 'push' && github.ref == 'refs/heads/main'
        run: npm test -- --coverage --maxWorkers=2

      # Cache Jest cache directory
      - uses: actions/cache@v3
        with:
          path: /tmp/jest_cache
          key: jest-cache-${{ runner.os }}-${{ hashFiles('**/jest.config.js') }}
```

### 5.3 Local Development Workflow

```bash
# Initial run (full suite, establish baseline)
npm test

# During development (watch mode, only changed)
npm test -- --watch

# Before commit (changed tests + coverage)
npm test -- --onlyChanged --coverage

# Debugging specific test
npm test -- --runInBand session-service.test.ts
```

---

## 6. Common Pitfalls

### ❌ Pitfall 1: Over-Parallelization
```javascript
// Bad: Too many workers = memory thrashing
maxWorkers: 16 // On 4-core machine!
```
**Fix**: Use `50%` or `CPU_CORES - 1`.

### ❌ Pitfall 2: Ignoring Cache
```bash
# Bad: Clearing cache every run
npm test -- --no-cache
```
**Fix**: Only clear when debugging or after major changes.

### ❌ Pitfall 3: Expensive Global Setup
```typescript
// Bad: beforeEach does heavy work
beforeEach(async () => {
  await seedDatabase(); // 1000+ rows per test!
});
```
**Fix**: Use `beforeAll` or minimal test-specific data.

### ❌ Pitfall 4: SQLite Locking in Parallel
```typescript
// Bad: Multiple workers writing to same DB
// Each worker hits database lock
```
**Fix**: Use WAL mode (already enabled in Bloom) or per-worker databases.

### ❌ Pitfall 5: Unmocked Network Calls
```typescript
// Bad: Real API calls in tests
const response = await fetch('https://api.example.com');
```
**Fix**: Mock all external dependencies.

### ❌ Pitfall 6: Running All Tests in Watch Mode
```bash
# Bad: Reruns 1000+ tests on every change
npm test -- --watchAll
```
**Fix**: Use `--watch` (runs only related tests).

---

## 7. AI Pair Programming Notes

### When to Load This Document
- Tests are taking > 30 seconds locally
- CI/CD pipeline is slow (> 5 minutes)
- Adding new test suites and want to avoid slowdowns
- Database tests are causing timeouts
- Need to optimize before scaling test coverage

### Claude Prompt Examples

```
"Optimize our Jest test suite - currently takes 2 minutes locally.
Check maxWorkers, caching, and setup/teardown patterns."

"Why are my Session tests slow? Each test takes 500ms+.
Review beforeEach/afterEach hooks and database setup."

"Set up CI/CD testing with --changedSince for PR checks
and full suite for main branch pushes."

"Mock Prisma client globally to avoid loading entire ORM in tests."
```

### Key Metrics to Track
- **Test duration**: Total time for full suite
- **Per-test time**: Average test execution (aim for < 100ms)
- **Cache hit rate**: How often Jest uses cached transforms
- **Worker efficiency**: CPU utilization during parallel runs
- **CI/CD time**: From push to test completion

### Bloom-Specific Considerations
- SQLite with WAL mode: Parallel-friendly, but still prefer serial for DB migrations
- Current scale (18 sessions): Performance not critical yet, but establish patterns now
- Future ROI calculations: May need test fixtures for complex scenarios
- Melissa AI tests: Mock Anthropic API (avoid real calls, rate limits, costs)

---

## Last Updated

2025-11-14
