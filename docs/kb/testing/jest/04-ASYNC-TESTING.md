---
id: jest-04-async-testing
topic: jest
file_role: practical
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [jest-01-fundamentals, javascript-promises]
related_topics: [async-javascript, promises, api-testing, database-testing]
embedding_keywords: [jest, async, promises, async-await, testing-promises, resolves, rejects, done-callback, asynchronous-testing, api-testing, database-testing]
last_reviewed: 2025-11-14
---

# Async Testing with Jest

<!-- Query: "How to test async functions in Jest?" -->
<!-- Query: "Jest async await testing" -->
<!-- Query: "Testing promises with Jest" -->
<!-- Query: "How to test API calls in Jest?" -->

## 1. Purpose

Master asynchronous testing in Jest to confidently test API calls, database operations, AI streaming, and other async code. This guide covers all async patterns used in Appmelia Bloom.

**What You'll Learn:**
- **async/await pattern** (recommended approach)
- **Promise matchers** (.resolves, .rejects)
- **Callback testing** (done parameter)
- **Concurrent operations** (Promise.all, Promise.race)
- **Error handling** in async tests
- **Real-world patterns** for API routes, database queries, and AI agents

**Prerequisites:**
- Basic Jest knowledge (see `01-FUNDAMENTALS.md`)
- Understanding of JavaScript Promises and async/await

**Why This Matters:**
> ~80% of Bloom's test suite involves async code: Prisma queries, Next.js API routes, Anthropic AI calls, and file operations. Mastering async testing is essential for reliable test coverage.

---

## 2. Mental Model / Problem Statement

### The Async Testing Challenge

Asynchronous code introduces timing complexity to tests:

```typescript
// ❌ WRONG: Test completes before async operation finishes
test('fetches user data', () => {
  fetchUser('123').then(user => {
    expect(user.name).toBe('Alice'); // Never runs!
  });
  // Test exits immediately, assertion never executes
});
```

**Problems with naive async testing:**
- **Race conditions**: Test completes before assertions run
- **False positives**: Tests pass because they never check results
- **Uncaught rejections**: Errors swallowed silently
- **Flaky tests**: Intermittent failures due to timing issues

### Jest's Async Solution: Three Patterns

Jest provides three ways to handle async code, each with trade-offs:

```
Pattern          | Use Case                    | Readability | Error Handling
-----------------|----------------------------|-------------|---------------
async/await      | Modern code (recommended)  | ⭐⭐⭐⭐⭐    | ⭐⭐⭐⭐⭐
.resolves/.rejects| Promise-specific tests    | ⭐⭐⭐⭐     | ⭐⭐⭐⭐⭐
done callback    | Legacy code, callbacks     | ⭐⭐        | ⭐⭐⭐
```

### Key Mental Models

**1. Test Lifecycle with Async**
```
Test Start → Wait for Promise → Assert → Test End
           ↑__________________|
           Jest waits here if you signal async operation
```

Jest knows to wait when you:
- Return a Promise
- Use async/await
- Call the `done()` callback

**2. Error Propagation**
```typescript
// ✅ Async errors are caught and reported
await expect(failingFunction()).rejects.toThrow('Error message');

// ❌ Without await, errors are swallowed
expect(failingFunction()).rejects.toThrow('Error message'); // Doesn't work!
```

**3. The "Return or Await" Rule**
```typescript
// ✅ GOOD: Return the promise
test('example 1', () => {
  return fetchData().then(data => expect(data).toBeDefined());
});

// ✅ GOOD: Await the promise
test('example 2', async () => {
  const data = await fetchData();
  expect(data).toBeDefined();
});

// ❌ BAD: Neither return nor await
test('example 3', () => {
  fetchData().then(data => expect(data).toBeDefined());
  // Test exits immediately!
});
```

---

## 3. Golden Path

### Recommended: async/await Pattern

**Use async/await for 95% of async tests.** It's the most readable, maintainable, and error-proof approach.

#### Golden Path Template

```typescript
import { MelissaAgent } from '@/lib/melissa/agent';
import { prisma } from '@/lib/db/client';

describe('MelissaAgent', () => {
  // ✅ Standard async test structure
  test('creates agent with session', async () => {
    // ARRANGE: Set up test data
    const session = await prisma.session.create({
      data: {
        id: 'test-session-1',
        organizationId: 'org-1',
        status: 'active',
      },
    });

    // ACT: Perform async operation
    const agent = await MelissaAgent.create({
      sessionId: session.id,
      organizationId: 'org-1',
    });

    // ASSERT: Verify results
    expect(agent).toBeDefined();
    expect(agent.sessionId).toBe('test-session-1');
  });

  // ✅ Multiple async operations in sequence
  test('processes complete conversation flow', async () => {
    const agent = await MelissaAgent.create({
      sessionId: 'test-session-2',
      organizationId: 'org-1',
    });

    const response1 = await agent.processMessage('I want to automate invoicing');
    expect(response1.phase).toBe('discovery');

    const response2 = await agent.processMessage('We spend 20 hours per week');
    expect(response2.extractedMetrics).toHaveProperty('timeInvestment');

    // Verify database state
    const session = await prisma.session.findUnique({
      where: { id: 'test-session-2' },
      include: { responses: true },
    });
    expect(session?.responses).toHaveLength(2);
  });

  // ✅ Error handling with try/catch
  test('handles missing API key gracefully', async () => {
    const originalKey = process.env.ANTHROPIC_API_KEY;
    delete process.env.ANTHROPIC_API_KEY;

    await expect(
      MelissaAgent.create({ sessionId: 'test', organizationId: 'org-1' })
    ).rejects.toThrow('ANTHROPIC_API_KEY environment variable is required');

    process.env.ANTHROPIC_API_KEY = originalKey;
  });
});
```

### Testing Database Operations

```typescript
import { checkDatabaseConnection, cleanupDatabase } from '@/lib/db/utils';
import { BenchmarkService } from '@/lib/roi/benchmarks';

describe('Database Operations', () => {
  // ✅ Test connection health check
  test('verifies database connection', async () => {
    const isConnected = await checkDatabaseConnection();
    expect(isConnected).toBe(true);
  });

  // ✅ Test CRUD operations
  test('creates and retrieves benchmark', async () => {
    const service = new BenchmarkService();

    // Create
    const created = await prisma.industryBenchmark.create({
      data: {
        industry: 'healthcare',
        metric: 'automation_potential',
        value: 0.75,
        source: 'Test Data',
        year: 2024,
      },
    });

    // Retrieve
    const benchmark = await service.getBenchmark('healthcare', 'automation_potential');

    expect(benchmark).toMatchObject({
      industry: 'healthcare',
      metric: 'automation_potential',
      value: 0.75,
    });

    // Cleanup
    await prisma.industryBenchmark.delete({ where: { id: created.id } });
  });

  // ✅ Test transactions
  test('creates session with user atomically', async () => {
    const result = await prisma.$transaction(async (tx) => {
      const user = await tx.user.create({
        data: {
          email: 'test@example.com',
          name: 'Test User',
        },
      });

      const session = await tx.session.create({
        data: {
          organizationId: 'org-1',
          userId: user.id,
          status: 'active',
        },
      });

      return { user, session };
    });

    expect(result.user.email).toBe('test@example.com');
    expect(result.session.userId).toBe(result.user.id);
  });
});
```

### Testing Next.js API Routes

```typescript
import { POST } from '@/app/api/melissa/chat/route';
import { NextRequest } from 'next/server';

describe('POST /api/melissa/chat', () => {
  // ✅ Test successful API call
  test('processes chat message', async () => {
    const request = new NextRequest('http://localhost:3001/api/melissa/chat', {
      method: 'POST',
      body: JSON.stringify({
        sessionId: 'test-session',
        message: 'I want to automate data entry',
      }),
    });

    const response = await POST(request);
    const data = await response.json();

    expect(response.status).toBe(200);
    expect(data).toHaveProperty('message');
    expect(data).toHaveProperty('phase');
    expect(data.needsUserInput).toBe(true);
  });

  // ✅ Test validation errors
  test('returns 400 for invalid input', async () => {
    const request = new NextRequest('http://localhost:3001/api/melissa/chat', {
      method: 'POST',
      body: JSON.stringify({
        sessionId: '', // Invalid: empty string
        message: 'Test',
      }),
    });

    const response = await POST(request);
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toBe('validation_error');
  });

  // ✅ Test error handling
  test('handles database errors', async () => {
    // Mock Prisma to throw error
    jest.spyOn(prisma.session, 'findUnique').mockRejectedValue(
      new Error('Database connection failed')
    );

    const request = new NextRequest('http://localhost:3001/api/melissa/chat', {
      method: 'POST',
      body: JSON.stringify({
        sessionId: 'test-session',
        message: 'Test',
      }),
    });

    const response = await POST(request);

    expect(response.status).toBe(503);
  });
});
```

---

## 4. Variations & Trade-Offs

### Pattern 1: async/await (Recommended)

**When to Use:** Default choice for all modern async code

**Pros:**
- Most readable and maintainable
- Natural error handling with try/catch
- Easy to debug with stack traces
- Works with all async patterns

**Cons:**
- Requires ES2017+ (not an issue in modern projects)

```typescript
test('async/await example', async () => {
  const data = await fetchData();
  expect(data).toBeDefined();

  const processed = await processData(data);
  expect(processed.status).toBe('success');
});
```

### Pattern 2: .resolves / .rejects Matchers

**When to Use:**
- Single promise assertions
- Testing promise rejection cases
- Cleaner syntax for simple tests

**Pros:**
- Concise for single assertions
- Explicit about promise expectations
- Automatic error handling

**Cons:**
- Cannot easily chain multiple operations
- Limited flexibility for complex scenarios

```typescript
describe('.resolves and .rejects matchers', () => {
  // ✅ Test promise resolution
  test('fetches user successfully', async () => {
    await expect(fetchUser('123')).resolves.toEqual({
      id: '123',
      name: 'Alice',
    });
  });

  // ✅ Test promise rejection
  test('throws on invalid user ID', async () => {
    await expect(fetchUser('invalid')).rejects.toThrow('User not found');
  });

  // ✅ Chain multiple matchers
  test('returns array with specific length', async () => {
    await expect(fetchUsers()).resolves.toHaveLength(5);
  });

  // ✅ Test rejection message
  test('validates benchmark inputs', async () => {
    const service = new BenchmarkService();

    await expect(
      service.getBenchmark('', 'metric')
    ).rejects.toThrow(/industry.*required/i);
  });
});
```

**Important:** Always use `await` with .resolves/.rejects!

```typescript
// ❌ WRONG: Missing await
expect(fetchData()).resolves.toBeDefined();
// Test completes immediately, assertion never runs

// ✅ CORRECT: With await
await expect(fetchData()).resolves.toBeDefined();
```

### Pattern 3: done Callback (Legacy)

**When to Use:**
- Testing legacy callback-based code
- Event listeners and streams
- Rare cases where async/await doesn't fit

**Pros:**
- Works with callback-based APIs
- Explicit test completion control

**Cons:**
- Easy to forget calling done()
- Harder to debug
- Less readable than async/await

```typescript
describe('done callback pattern', () => {
  // ✅ Testing callback-based API
  test('processes callback', (done) => {
    fetchDataWithCallback((error, data) => {
      expect(error).toBeNull();
      expect(data).toBeDefined();
      done(); // Must call done() to complete test
    });
  });

  // ✅ Testing error callbacks
  test('handles callback errors', (done) => {
    fetchDataWithCallback((error, data) => {
      expect(error).toBeDefined();
      expect(error.message).toBe('Network error');
      done();
    });
  });

  // ✅ Testing event emitters
  test('emits event', (done) => {
    const emitter = new EventEmitter();

    emitter.on('data', (data) => {
      expect(data.status).toBe('complete');
      done();
    });

    emitter.emit('data', { status: 'complete' });
  });

  // ❌ Common mistake: forgetting done()
  test('WILL TIMEOUT', (done) => {
    fetchData().then(data => {
      expect(data).toBeDefined();
      // Forgot to call done() - test will timeout!
    });
  });
});
```

**Migration Tip:** Convert callback-based tests to async/await:

```typescript
// Before (callback)
test('old way', (done) => {
  fetchData((error, data) => {
    expect(error).toBeNull();
    expect(data).toBeDefined();
    done();
  });
});

// After (async/await with promisify)
import { promisify } from 'util';
const fetchDataAsync = promisify(fetchData);

test('new way', async () => {
  const data = await fetchDataAsync();
  expect(data).toBeDefined();
});
```

### Pattern 4: Testing Promise.all (Concurrent Operations)

```typescript
describe('Concurrent Operations', () => {
  // ✅ Test parallel database queries
  test('fetches multiple benchmarks concurrently', async () => {
    const service = new BenchmarkService();

    const [healthcare, finance, manufacturing] = await Promise.all([
      service.getIndustryBenchmarks('healthcare'),
      service.getIndustryBenchmarks('finance'),
      service.getIndustryBenchmarks('manufacturing'),
    ]);

    expect(healthcare).toBeInstanceOf(Array);
    expect(finance).toBeInstanceOf(Array);
    expect(manufacturing).toBeInstanceOf(Array);
  });

  // ✅ Test that all promises resolve
  test('creates multiple sessions concurrently', async () => {
    const promises = [1, 2, 3].map(i =>
      prisma.session.create({
        data: {
          organizationId: 'org-1',
          status: 'active',
        },
      })
    );

    const sessions = await Promise.all(promises);

    expect(sessions).toHaveLength(3);
    sessions.forEach(session => {
      expect(session.status).toBe('active');
    });
  });

  // ✅ Test that any failure rejects all
  test('handles partial failure in batch', async () => {
    const promises = [
      prisma.session.create({ data: { organizationId: 'org-1', status: 'active' } }),
      prisma.session.create({ data: { organizationId: '', status: 'active' } }), // Invalid
      prisma.session.create({ data: { organizationId: 'org-1', status: 'active' } }),
    ];

    await expect(Promise.all(promises)).rejects.toThrow();
  });
});
```

### Pattern 5: Testing Promise.race (Timeout Patterns)

```typescript
describe('Promise.race patterns', () => {
  // ✅ Test timeout logic
  test('times out slow operations', async () => {
    const slowOperation = new Promise(resolve =>
      setTimeout(() => resolve('slow'), 5000)
    );

    const timeout = new Promise((_, reject) =>
      setTimeout(() => reject(new Error('Timeout')), 1000)
    );

    await expect(Promise.race([slowOperation, timeout]))
      .rejects.toThrow('Timeout');
  });

  // ✅ Test fastest response wins
  test('uses first available cache', async () => {
    const redisCache = new Promise(resolve =>
      setTimeout(() => resolve('redis-data'), 100)
    );

    const memoryCache = new Promise(resolve =>
      setTimeout(() => resolve('memory-data'), 50)
    );

    const result = await Promise.race([redisCache, memoryCache]);
    expect(result).toBe('memory-data');
  });
});
```

---

## 5. Examples

### Example 1: Testing AI Agent (Complex Async Flow)

```typescript
import { MelissaAgent } from '@/lib/melissa/agent';
import { MELISSA_GREETING } from '@/lib/melissa/constants';

describe('MelissaAgent Integration', () => {
  let agent: MelissaAgent;
  let sessionId: string;

  beforeEach(async () => {
    // Setup: Create session and agent
    sessionId = `test-${Date.now()}`;

    await prisma.session.create({
      data: {
        id: sessionId,
        organizationId: 'test-org',
        status: 'active',
      },
    });

    agent = await MelissaAgent.create({
      sessionId,
      organizationId: 'test-org',
    });
  });

  afterEach(async () => {
    // Cleanup: Remove test data
    await prisma.session.delete({ where: { id: sessionId } });
  });

  test('initializes with greeting', async () => {
    const response = await agent.processMessage('__INIT__');

    expect(response.message).toContain('Melissa');
    expect(response.phase).toBe('greeting');
    expect(response.needsUserInput).toBe(true);
  });

  test('extracts time investment metric', async () => {
    await agent.processMessage('__INIT__');

    const response = await agent.processMessage(
      'We spend about 20 hours per week on manual data entry'
    );

    expect(response.extractedMetrics).toHaveProperty('timeInvestment');
    expect(response.extractedMetrics.timeInvestment).toBeGreaterThan(0);
    expect(response.confidence).toBeGreaterThan(0);
  });

  test('handles multi-turn conversation', async () => {
    await agent.processMessage('__INIT__');

    const turns = [
      'I want to automate invoice processing',
      'We have a team of 5 people',
      'They spend 4 hours per day on this',
      'Each person costs about $50 per hour',
    ];

    for (const turn of turns) {
      const response = await agent.processMessage(turn);
      expect(response).toHaveProperty('message');
      expect(response.phase).toBeDefined();
    }

    const state = agent.getState();
    expect(state.transcript).toHaveLength(turns.length + 1); // +1 for init
  });

  test('transitions through phases', async () => {
    await agent.processMessage('__INIT__');
    expect(agent.getState().phase).toBe('greeting');

    await agent.processMessage('I want to automate data entry');
    expect(agent.getState().phase).toBe('discovery');

    // Provide all required metrics
    await agent.processMessage('We spend 20 hours weekly');
    await agent.processMessage('Team of 5 people');
    await agent.processMessage('Cost is $50 per hour');

    const state = agent.getState();
    expect(['validation', 'calculation', 'summary']).toContain(state.phase);
  });
});
```

### Example 2: Testing API Routes with Error Cases

```typescript
import { POST } from '@/app/api/roi/calculate/route';
import { NextRequest } from 'next/server';

describe('POST /api/roi/calculate', () => {
  const validPayload = {
    sessionId: 'test-session',
    timeInvestment: 20,
    teamSize: 5,
    hourlyRate: 50,
    automationPotential: 0.75,
  };

  test('calculates ROI successfully', async () => {
    const request = new NextRequest('http://localhost:3001/api/roi/calculate', {
      method: 'POST',
      body: JSON.stringify(validPayload),
    });

    const response = await POST(request);
    const data = await response.json();

    expect(response.status).toBe(200);
    expect(data).toHaveProperty('roi');
    expect(data).toHaveProperty('npv');
    expect(data).toHaveProperty('paybackPeriod');
    expect(data.roi).toBeGreaterThan(0);
  });

  test('validates required fields', async () => {
    const invalidPayload = {
      sessionId: 'test-session',
      // Missing required fields
    };

    const request = new NextRequest('http://localhost:3001/api/roi/calculate', {
      method: 'POST',
      body: JSON.stringify(invalidPayload),
    });

    const response = await POST(request);
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toBe('validation_error');
    expect(data.details).toBeInstanceOf(Array);
  });

  test('handles database connection errors', async () => {
    // Mock database error
    jest.spyOn(prisma, '$connect').mockRejectedValue(
      new Error('Connection failed')
    );

    const request = new NextRequest('http://localhost:3001/api/roi/calculate', {
      method: 'POST',
      body: JSON.stringify(validPayload),
    });

    const response = await POST(request);

    expect(response.status).toBe(503);
  });

  test('times out slow calculations', async () => {
    jest.setTimeout(10000); // Increase timeout for this test

    const largePayload = {
      ...validPayload,
      projectionYears: 100, // Intentionally slow
    };

    const request = new NextRequest('http://localhost:3001/api/roi/calculate', {
      method: 'POST',
      body: JSON.stringify(largePayload),
    });

    const timeout = new Promise((_, reject) =>
      setTimeout(() => reject(new Error('Calculation timeout')), 5000)
    );

    await expect(
      Promise.race([POST(request), timeout])
    ).rejects.toThrow('Calculation timeout');
  }, 10000);
});
```

### Example 3: Testing Database Transactions

```typescript
import { prisma } from '@/lib/db/client';

describe('Database Transactions', () => {
  test('rolls back on error', async () => {
    const initialCount = await prisma.session.count();

    try {
      await prisma.$transaction(async (tx) => {
        // Create valid session
        await tx.session.create({
          data: {
            organizationId: 'org-1',
            status: 'active',
          },
        });

        // Create invalid session (will fail)
        await tx.session.create({
          data: {
            organizationId: '', // Invalid: empty string
            status: 'active',
          },
        });
      });
    } catch (error) {
      // Expected to fail
    }

    // Verify rollback: count should be unchanged
    const finalCount = await prisma.session.count();
    expect(finalCount).toBe(initialCount);
  });

  test('commits on success', async () => {
    const initialCount = await prisma.session.count();

    await prisma.$transaction(async (tx) => {
      await tx.session.create({
        data: {
          organizationId: 'org-1',
          status: 'active',
        },
      });

      await tx.session.create({
        data: {
          organizationId: 'org-2',
          status: 'active',
        },
      });
    });

    const finalCount = await prisma.session.count();
    expect(finalCount).toBe(initialCount + 2);
  });
});
```

### Example 4: Testing Concurrent Database Operations

```typescript
describe('Concurrent Session Creation', () => {
  test('handles concurrent creates with retry logic', async () => {
    // Simulate multiple users creating sessions simultaneously
    const createSession = async (orgId: string) => {
      let retries = 3;

      while (retries > 0) {
        try {
          return await prisma.session.create({
            data: {
              organizationId: orgId,
              status: 'active',
            },
          });
        } catch (error) {
          if (retries === 1) throw error;
          retries--;
          await new Promise(resolve => setTimeout(resolve, 100));
        }
      }
    };

    const promises = Array.from({ length: 10 }, (_, i) =>
      createSession(`org-${i}`)
    );

    const sessions = await Promise.all(promises);

    expect(sessions).toHaveLength(10);

    const uniqueOrgs = new Set(sessions.map(s => s.organizationId));
    expect(uniqueOrgs.size).toBe(10);
  });
});
```

---

## 6. Common Pitfalls

### Pitfall 1: Forgetting to Return or Await

```typescript
// ❌ WRONG: Test completes before assertion
test('broken test', () => {
  fetchData().then(data => {
    expect(data).toBeDefined();
  });
  // Test exits immediately!
});

// ✅ FIX 1: Return the promise
test('fixed with return', () => {
  return fetchData().then(data => {
    expect(data).toBeDefined();
  });
});

// ✅ FIX 2: Use async/await (better)
test('fixed with async/await', async () => {
  const data = await fetchData();
  expect(data).toBeDefined();
});
```

### Pitfall 2: Missing await on .resolves/.rejects

```typescript
// ❌ WRONG: Missing await
test('broken promise test', () => {
  expect(fetchData()).resolves.toBeDefined();
  // Assertion never runs!
});

// ✅ CORRECT: With await
test('fixed promise test', async () => {
  await expect(fetchData()).resolves.toBeDefined();
});
```

### Pitfall 3: Not Handling Promise Rejections

```typescript
// ❌ WRONG: Unhandled rejection crashes test
test('will crash', async () => {
  const data = await fetchData(); // Throws error
  expect(data).toBeDefined();
});

// ✅ FIX 1: Use try/catch
test('handles error', async () => {
  try {
    await fetchData();
    fail('Should have thrown');
  } catch (error) {
    expect(error.message).toBe('Network error');
  }
});

// ✅ FIX 2: Use .rejects (cleaner)
test('handles error better', async () => {
  await expect(fetchData()).rejects.toThrow('Network error');
});
```

### Pitfall 4: Incorrect Test Timeout Configuration

```typescript
// ❌ WRONG: Slow test without timeout adjustment
test('slow operation', async () => {
  const result = await verySlowOperation(); // Takes 10 seconds
  expect(result).toBeDefined();
}); // Will timeout at default 5 seconds

// ✅ CORRECT: Increase timeout for specific test
test('slow operation', async () => {
  const result = await verySlowOperation();
  expect(result).toBeDefined();
}, 15000); // 15 second timeout

// ✅ BETTER: Set timeout for entire suite
describe('Slow operations', () => {
  jest.setTimeout(30000); // 30 seconds for all tests

  test('operation 1', async () => {
    await slowOp1();
  });

  test('operation 2', async () => {
    await slowOp2();
  });
});
```

### Pitfall 5: Race Conditions in Database Tests

```typescript
// ❌ WRONG: Tests affect each other
describe('Session tests', () => {
  test('creates session', async () => {
    const session = await prisma.session.create({
      data: { id: 'shared-id', organizationId: 'org-1', status: 'active' },
    });
    expect(session.id).toBe('shared-id');
  });

  test('updates session', async () => {
    // Assumes previous test ran and created 'shared-id'
    const session = await prisma.session.update({
      where: { id: 'shared-id' },
      data: { status: 'completed' },
    });
    expect(session.status).toBe('completed'); // FLAKY!
  });
});

// ✅ CORRECT: Independent tests with setup/teardown
describe('Session tests', () => {
  let sessionId: string;

  beforeEach(async () => {
    const session = await prisma.session.create({
      data: { organizationId: 'org-1', status: 'active' },
    });
    sessionId = session.id;
  });

  afterEach(async () => {
    await prisma.session.delete({ where: { id: sessionId } });
  });

  test('creates session', async () => {
    const session = await prisma.session.findUnique({
      where: { id: sessionId },
    });
    expect(session).toBeDefined();
  });

  test('updates session', async () => {
    const session = await prisma.session.update({
      where: { id: sessionId },
      data: { status: 'completed' },
    });
    expect(session.status).toBe('completed');
  });
});
```

### Pitfall 6: Not Cleaning Up Async Resources

```typescript
// ❌ WRONG: Leaking database connections
describe('Database tests', () => {
  test('test 1', async () => {
    const client = await getDbClient();
    const data = await client.query('SELECT * FROM users');
    // Connection never closed!
  });
});

// ✅ CORRECT: Cleanup in afterEach
describe('Database tests', () => {
  let client: DbClient;

  beforeEach(async () => {
    client = await getDbClient();
  });

  afterEach(async () => {
    await client.disconnect();
  });

  test('test 1', async () => {
    const data = await client.query('SELECT * FROM users');
    expect(data).toBeDefined();
  });
});

// ✅ ALSO CORRECT: Cleanup in finally block
test('test with cleanup', async () => {
  const client = await getDbClient();

  try {
    const data = await client.query('SELECT * FROM users');
    expect(data).toBeDefined();
  } finally {
    await client.disconnect();
  }
});
```

### Pitfall 7: Infinite Retry Loops

```typescript
// ❌ WRONG: Infinite loop on persistent failure
test('will hang forever', async () => {
  let success = false;

  while (!success) {
    try {
      await fetchData();
      success = true;
    } catch (error) {
      // Retry forever!
    }
  }
});

// ✅ CORRECT: Limited retries with timeout
test('retries with limit', async () => {
  let retries = 3;
  let lastError;

  while (retries > 0) {
    try {
      const data = await fetchData();
      expect(data).toBeDefined();
      return; // Success
    } catch (error) {
      lastError = error;
      retries--;
      if (retries > 0) {
        await new Promise(resolve => setTimeout(resolve, 1000));
      }
    }
  }

  throw lastError; // Failed after all retries
}, 10000);
```

---

## 7. AI Pair Programming Notes

### Quick Reference for AI Assistants

When generating async tests:

1. **Default to async/await** unless there's a specific reason not to
2. **Always include error cases** - test both success and failure paths
3. **Clean up resources** in afterEach or finally blocks
4. **Use realistic test data** from the Bloom domain (sessions, users, benchmarks)
5. **Add timeouts** for tests that might be slow (> 5 seconds)

### Common Bloom Async Patterns

```typescript
// Pattern: Melissa Agent Testing
const agent = await MelissaAgent.create({ sessionId, organizationId });
const response = await agent.processMessage('user input');

// Pattern: Database Query
const session = await prisma.session.findUnique({ where: { id } });

// Pattern: API Route Testing
const request = new NextRequest(url, { method: 'POST', body: JSON.stringify(data) });
const response = await POST(request);
const json = await response.json();

// Pattern: Error Handling
await expect(operation()).rejects.toThrow('Error message');

// Pattern: Transaction
await prisma.$transaction(async (tx) => {
  await tx.session.create({ data });
  await tx.user.update({ where, data });
});
```

### Bloom-Specific Test Utilities

```typescript
// Helper: Create test session
async function createTestSession(overrides = {}) {
  return await prisma.session.create({
    data: {
      organizationId: 'test-org',
      status: 'active',
      ...overrides,
    },
  });
}

// Helper: Cleanup test data
async function cleanupTestData(sessionId: string) {
  await prisma.response.deleteMany({ where: { sessionId } });
  await prisma.session.delete({ where: { id: sessionId } });
}

// Helper: Wait for condition (polling)
async function waitFor(condition: () => Promise<boolean>, timeout = 5000) {
  const start = Date.now();

  while (Date.now() - start < timeout) {
    if (await condition()) return;
    await new Promise(resolve => setTimeout(resolve, 100));
  }

  throw new Error('Timeout waiting for condition');
}
```

### When to Use Each Pattern

| Use Case | Pattern | Example |
|----------|---------|---------|
| Standard async operation | async/await | `const data = await fetchData();` |
| Single promise assertion | .resolves/.rejects | `await expect(fetch()).resolves.toBe(data);` |
| Legacy callbacks | done callback | `test('cb', (done) => cb(() => done()));` |
| Parallel operations | Promise.all | `await Promise.all([op1(), op2()]);` |
| Timeout logic | Promise.race | `await Promise.race([op(), timeout()]);` |
| Database transaction | async tx | `await prisma.$transaction(async tx => ...);` |
| API route | NextRequest/Response | `const res = await POST(request);` |

---

## Last Updated

2025-11-14
