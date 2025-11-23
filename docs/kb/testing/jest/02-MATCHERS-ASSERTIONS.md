---
id: jest-02-matchers-assertions
topic: jest
file_role: core
profile: full
difficulty_level: beginner-to-intermediate
kb_version: 3.1
prerequisites: [jest-01-fundamentals]
related_topics: [testing, assertions, type-safety]
embedding_keywords: [jest, matchers, assertions, expect, toBe, toEqual, toStrictEqual, toBeTruthy, toContain, toThrow, resolves, rejects]
last_reviewed: 2025-11-14
---

# Jest Matchers & Assertions

## 1. Purpose

Master Jest's assertion library to write precise, maintainable tests. This guide covers all built-in matchers, async assertions, custom matchers, and TypeScript integration patterns used in Appmelia Bloom.

**What You'll Learn:**
- Complete `expect()` API reference with real-world examples
- When to use `toBe` vs `toEqual` vs `toStrictEqual`
- Type-safe assertion patterns for TypeScript projects
- Async testing with `.resolves` and `.rejects`
- Custom matcher creation and usage
- Common pitfalls and how to avoid them

**Prerequisites:** Basic Jest knowledge (see `01-FUNDAMENTALS.md`)

---

## 2. Mental Model / Problem Statement

### The Assertion Challenge

Testing requires making precise claims about code behavior. Poor assertions lead to:
- **False positives**: Tests pass when they shouldn't
- **Flaky tests**: Random failures due to imprecise matching
- **Hard-to-debug failures**: Unclear error messages
- **Type unsafety**: Runtime errors in TypeScript tests

### Jest's Solution: Rich Matcher Library

Jest provides 50+ matchers organized by data type and assertion intent:

```
Assertion Intent → Matcher Selection → Clear Failure Messages

Example:
"Is this the exact same object?" → toBe() → Expected object identity
"Does this object have these properties?" → toMatchObject() → Property mismatch details
"Does this async function succeed?" → resolves.toBe() → Async resolution/rejection info
```

### Key Mental Models

**1. Equality Spectrum**
```
toBe()           →  Strictest  →  Object.is() equality (reference)
toEqual()        →  Medium     →  Deep value equality
toStrictEqual()  →  Strict     →  Deep equality + undefined checks
toMatchObject()  →  Loosest    →  Partial property matching
```

**2. Matcher Modifiers**
```
expect(x).toBe(y)              // Direct assertion
expect(x).not.toBe(y)          // Negation
expect(promise).resolves.toBe(y)   // Async success
expect(promise).rejects.toThrow()  // Async failure
```

**3. Error Message Priority**
- Matchers are designed to provide helpful failure messages
- Use specific matchers over generic ones for better debugging
- Custom matchers should return descriptive messages

---

## 3. Golden Path

### Recommended Matcher Selection Strategy

**Step 1: Identify Data Type**
```typescript
// Primitive → toBe()
expect(count).toBe(5);

// Object/Array → toEqual()
expect(user).toEqual({ id: '1', name: 'Test' });

// String pattern → toMatch() or toContain()
expect(message).toContain('error');

// Number range → toBeGreaterThan() / toBeLessThan()
expect(response.time).toBeLessThan(200);

// Async → resolves/rejects
await expect(fetchData()).resolves.toEqual(expectedData);
```

**Step 2: Choose Specificity Level**
```typescript
// ❌ Too generic
expect(result).toBeTruthy();

// ✅ Specific and clear
expect(result.status).toBe('success');
expect(result.data).toHaveLength(3);
```

**Step 3: Add Type Safety (TypeScript)**
```typescript
import { Session, SessionStatus } from '@prisma/client';

// ✅ Type-safe assertion
const session: Session = await createSession();
expect(session.status).toBe<SessionStatus>('active');
expect(session.duration).toBeGreaterThan(0);
```

### Golden Path Template

```typescript
describe('Golden Path Test Structure', () => {
  test('specific behavior with clear assertions', async () => {
    // Arrange: Set up test data
    const input = { name: 'Test' };

    // Act: Perform action
    const result = await performAction(input);

    // Assert: Use specific matchers
    expect(result).toBeDefined();
    expect(result.id).toMatch(/^[a-z0-9]+$/);
    expect(result.name).toBe(input.name);
    expect(result.createdAt).toBeInstanceOf(Date);
  });
});
```

---

## 4. Variations & Trade-Offs

### Equality Matchers Comparison

#### `toBe()` - Reference Equality
**Use for:** Primitives, object identity
**Trade-off:** Strictest, but fails for objects with same values

```typescript
// ✅ Primitives
expect(5).toBe(5);
expect('hello').toBe('hello');
expect(true).toBe(true);

// ❌ Objects (different references)
expect({ a: 1 }).toBe({ a: 1 }); // FAILS

// ✅ Object identity
const obj = { a: 1 };
expect(obj).toBe(obj); // PASSES
```

#### `toEqual()` - Deep Value Equality
**Use for:** Objects, arrays (default choice)
**Trade-off:** Ignores `undefined` properties, compares values not references

```typescript
// ✅ Objects and arrays
expect({ a: 1, b: 2 }).toEqual({ a: 1, b: 2 });
expect([1, 2, 3]).toEqual([1, 2, 3]);

// ⚠️ Ignores undefined
expect({ a: 1, b: undefined }).toEqual({ a: 1 }); // PASSES

// ✅ Nested structures
expect({
  user: { id: '1', profile: { name: 'Test' } }
}).toEqual({
  user: { id: '1', profile: { name: 'Test' } }
});
```

#### `toStrictEqual()` - Strict Deep Equality
**Use for:** When undefined matters, strict type checking
**Trade-off:** Most restrictive, catches more edge cases

```typescript
// ✅ Checks undefined properties
expect({ a: 1, b: undefined }).toStrictEqual({ a: 1, b: undefined });
expect({ a: 1 }).not.toStrictEqual({ a: 1, b: undefined });

// ✅ Checks array sparseness
expect([1, , 3]).not.toStrictEqual([1, undefined, 3]);

// ✅ Best for TypeScript strict mode
const session: Session = {
  id: 'abc',
  status: 'active',
  metadata: undefined, // Explicitly undefined
};
expect(session).toStrictEqual({
  id: 'abc',
  status: 'active',
  metadata: undefined,
});
```

#### `toMatchObject()` - Partial Matching
**Use for:** Subset assertions, ignoring extra properties
**Trade-off:** Loosest, good for API responses with variable fields

```typescript
// ✅ Partial object matching
expect({
  id: '1',
  name: 'Test',
  email: 'test@example.com',
  createdAt: new Date(),
}).toMatchObject({
  id: '1',
  name: 'Test',
});

// ✅ Nested partial matching
expect({
  user: { id: '1', name: 'Test', admin: false },
  session: { token: 'xyz', expires: Date.now() },
}).toMatchObject({
  user: { id: '1' },
  session: { token: 'xyz' },
});
```

### When to Use Each

| Scenario | Matcher | Reason |
|----------|---------|--------|
| Compare primitive values | `toBe()` | Fast, clear intent |
| Compare objects/arrays | `toEqual()` | Standard deep comparison |
| TypeScript strict mode | `toStrictEqual()` | Catches undefined edge cases |
| API response validation | `toMatchObject()` | Ignore timestamps, extra fields |
| Object reference check | `toBe()` | Verify same instance |

---

## 5. Examples

### Example 1 – Pedagogical: All Matcher Categories

#### Equality Matchers
```typescript
describe('Equality Matchers', () => {
  test('toBe - primitive equality', () => {
    const count = 5;
    expect(count).toBe(5);
    expect(count).not.toBe(6);
  });

  test('toEqual - object equality', () => {
    const user = { id: '1', name: 'Alice' };
    expect(user).toEqual({ id: '1', name: 'Alice' });

    // Works with nested objects
    const session = {
      user: { id: '1' },
      settings: { theme: 'dark' },
    };
    expect(session).toEqual({
      user: { id: '1' },
      settings: { theme: 'dark' },
    });
  });

  test('toStrictEqual - strict object equality', () => {
    // Fails if undefined properties differ
    expect({ a: 1, b: undefined }).toStrictEqual({
      a: 1,
      b: undefined,
    });

    expect({ a: 1 }).not.toStrictEqual({ a: 1, b: undefined });
  });
});
```

#### Truthiness Matchers
```typescript
describe('Truthiness Matchers', () => {
  test('truthiness checks', () => {
    expect(true).toBeTruthy();
    expect(1).toBeTruthy();
    expect('hello').toBeTruthy();
    expect({}).toBeTruthy();

    expect(false).toBeFalsy();
    expect(0).toBeFalsy();
    expect('').toBeFalsy();
    expect(null).toBeFalsy();
    expect(undefined).toBeFalsy();
  });

  test('null and undefined checks', () => {
    const value = null;
    expect(value).toBeNull();
    expect(value).not.toBeUndefined();
    expect(value).toBeDefined(); // null is defined

    let unassigned;
    expect(unassigned).toBeUndefined();
    expect(unassigned).not.toBeDefined();
  });
});
```

#### Number Matchers
```typescript
describe('Number Matchers', () => {
  test('comparison matchers', () => {
    const score = 85;
    expect(score).toBeGreaterThan(80);
    expect(score).toBeGreaterThanOrEqual(85);
    expect(score).toBeLessThan(90);
    expect(score).toBeLessThanOrEqual(85);
  });

  test('floating point comparison', () => {
    const result = 0.1 + 0.2;

    // ❌ This fails due to floating point precision
    // expect(result).toBe(0.3);

    // ✅ Use toBeCloseTo for floating point
    expect(result).toBeCloseTo(0.3);
    expect(result).toBeCloseTo(0.3, 5); // 5 decimal places
  });

  test('special number values', () => {
    expect(NaN).toBeNaN();
    expect(10 / 0).not.toBeNaN();

    expect(Number.POSITIVE_INFINITY).not.toBeFinite();
    expect(Number.NEGATIVE_INFINITY).not.toBeFinite();
    expect(42).toBeFinite();
  });
});
```

#### String Matchers
```typescript
describe('String Matchers', () => {
  test('substring matching', () => {
    const message = 'Error: Failed to fetch data';

    expect(message).toContain('Error');
    expect(message).toContain('fetch');
    expect(message).not.toContain('Success');
  });

  test('regex matching', () => {
    const email = 'user@example.com';
    expect(email).toMatch(/^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$/);

    const sessionId = 'sess_abc123xyz';
    expect(sessionId).toMatch(/^sess_[a-z0-9]+$/);
  });

  test('string length', () => {
    const password = 'secret123';
    expect(password).toHaveLength(9);
    expect(password.length).toBeGreaterThanOrEqual(8);
  });
});
```

#### Array and Iterable Matchers
```typescript
describe('Array Matchers', () => {
  test('array contains item', () => {
    const tags = ['typescript', 'jest', 'testing'];

    expect(tags).toContain('jest');
    expect(tags).not.toContain('mocha');
  });

  test('array length', () => {
    const items = [1, 2, 3, 4, 5];
    expect(items).toHaveLength(5);
  });

  test('array containing (subset)', () => {
    const users = [
      { id: '1', name: 'Alice' },
      { id: '2', name: 'Bob' },
      { id: '3', name: 'Charlie' },
    ];

    expect(users).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ name: 'Alice' }),
        expect.objectContaining({ name: 'Charlie' }),
      ])
    );
  });

  test('array matching (order matters)', () => {
    expect([1, 2, 3]).toEqual([1, 2, 3]);
    expect([1, 2, 3]).not.toEqual([3, 2, 1]);
  });
});
```

#### Object Matchers
```typescript
describe('Object Matchers', () => {
  test('object has property', () => {
    const user = { id: '1', name: 'Alice', email: 'alice@example.com' };

    expect(user).toHaveProperty('id');
    expect(user).toHaveProperty('name', 'Alice');
    expect(user).toHaveProperty('email');
  });

  test('nested property', () => {
    const session = {
      user: { id: '1', profile: { name: 'Alice' } },
    };

    expect(session).toHaveProperty('user.profile.name');
    expect(session).toHaveProperty('user.profile.name', 'Alice');
    expect(session).toHaveProperty(['user', 'profile', 'name'], 'Alice');
  });

  test('object contains subset', () => {
    const response = {
      status: 200,
      data: { id: '1', name: 'Test' },
      timestamp: Date.now(),
    };

    expect(response).toMatchObject({
      status: 200,
      data: { id: '1' },
    });
  });

  test('object keys', () => {
    const obj = { a: 1, b: 2, c: 3 };
    expect(Object.keys(obj)).toEqual(['a', 'b', 'c']);
    expect(Object.keys(obj)).toHaveLength(3);
  });
});
```

#### Exception Matchers
```typescript
describe('Exception Matchers', () => {
  test('function throws error', () => {
    const throwError = () => {
      throw new Error('Something went wrong');
    };

    expect(throwError).toThrow();
    expect(throwError).toThrow(Error);
    expect(throwError).toThrow('Something went wrong');
    expect(throwError).toThrow(/went wrong/);
  });

  test('specific error type', () => {
    class ValidationError extends Error {
      constructor(message: string) {
        super(message);
        this.name = 'ValidationError';
      }
    }

    const validate = () => {
      throw new ValidationError('Invalid input');
    };

    expect(validate).toThrow(ValidationError);
    expect(validate).toThrow('Invalid input');
  });

  test('function does not throw', () => {
    const safeFunction = () => {
      return 'success';
    };

    expect(safeFunction).not.toThrow();
  });
});
```

#### Async Matchers
```typescript
describe('Async Matchers', () => {
  test('promise resolves', async () => {
    const fetchData = () => Promise.resolve('data');

    await expect(fetchData()).resolves.toBe('data');
    await expect(fetchData()).resolves.toBeDefined();
  });

  test('promise rejects', async () => {
    const fetchData = () => Promise.reject(new Error('Failed'));

    await expect(fetchData()).rejects.toThrow();
    await expect(fetchData()).rejects.toThrow('Failed');
    await expect(fetchData()).rejects.toThrow(Error);
  });

  test('async function success', async () => {
    async function getData() {
      return { id: '1', value: 42 };
    }

    await expect(getData()).resolves.toEqual({
      id: '1',
      value: 42,
    });
  });

  test('async function failure', async () => {
    async function fetchUser(id: string) {
      if (!id) throw new Error('ID required');
      return { id };
    }

    await expect(fetchUser('')).rejects.toThrow('ID required');
  });
});
```

---

### Example 2 – Realistic Synthetic: Session Testing

```typescript
import { Session, SessionStatus } from '@prisma/client';
import { createSession, updateSession, validateSessionDuration } from '@/lib/sessions';

describe('Session Management - Matcher Examples', () => {
  describe('Session Creation', () => {
    test('creates session with correct structure', async () => {
      const session = await createSession({
        userId: 'user_123',
        organizationId: 'org_456',
      });

      // Type-safe assertions
      expect(session).toBeDefined();
      expect(session.id).toMatch(/^sess_[a-z0-9]+$/);
      expect(session.status).toBe<SessionStatus>('pending');
      expect(session.userId).toBe('user_123');
      expect(session.organizationId).toBe('org_456');

      // Date assertions
      expect(session.createdAt).toBeInstanceOf(Date);
      expect(session.updatedAt).toBeInstanceOf(Date);
      expect(session.createdAt.getTime()).toBeLessThanOrEqual(Date.now());

      // Nullable field assertions
      expect(session.completedAt).toBeNull();
      expect(session.roiScore).toBeNull();

      // Object structure
      expect(session).toMatchObject({
        userId: 'user_123',
        status: 'pending',
      });
    });

    test('creates session with default values', async () => {
      const session = await createSession({
        userId: 'user_123',
      });

      // Partial matching - ignores extra fields
      expect(session).toMatchObject({
        userId: 'user_123',
        status: 'pending',
      });

      // Verify defaults
      expect(session.duration).toBe(0);
      expect(session.metadata).toEqual({});
    });
  });

  describe('Session Updates', () => {
    test('updates session status', async () => {
      const original = await createSession({ userId: 'user_123' });
      const updated = await updateSession(original.id, {
        status: 'active',
      });

      // Compare specific fields
      expect(updated.id).toBe(original.id);
      expect(updated.status).toBe('active');
      expect(updated.status).not.toBe(original.status);

      // Updated timestamp changed
      expect(updated.updatedAt.getTime()).toBeGreaterThan(
        original.updatedAt.getTime()
      );

      // Created timestamp unchanged
      expect(updated.createdAt).toEqual(original.createdAt);
    });

    test('completes session with ROI data', async () => {
      const session = await createSession({ userId: 'user_123' });
      const completed = await updateSession(session.id, {
        status: 'completed',
        roiScore: 0.85,
        completedAt: new Date(),
      });

      expect(completed.status).toBe('completed');
      expect(completed.roiScore).toBeCloseTo(0.85, 2);
      expect(completed.roiScore).toBeGreaterThan(0);
      expect(completed.roiScore).toBeLessThanOrEqual(1);
      expect(completed.completedAt).toBeInstanceOf(Date);
      expect(completed.completedAt).not.toBeNull();
    });
  });

  describe('Session Validation', () => {
    test('validates session duration', () => {
      const validSessions = [
        { duration: 900 },  // 15 minutes
        { duration: 600 },  // 10 minutes
        { duration: 1200 }, // 20 minutes
      ];

      validSessions.forEach((session) => {
        expect(() => validateSessionDuration(session.duration)).not.toThrow();
      });
    });

    test('rejects invalid duration', () => {
      const invalidDurations = [0, -100, 3600];

      invalidDurations.forEach((duration) => {
        expect(() => validateSessionDuration(duration)).toThrow();
        expect(() => validateSessionDuration(duration)).toThrow(
          /Invalid duration/
        );
      });
    });

    test('validates session metadata', () => {
      const metadata = {
        source: 'web',
        version: '1.0.0',
        tags: ['onboarding', 'demo'],
      };

      expect(metadata).toHaveProperty('source');
      expect(metadata.source).toBe('web');
      expect(metadata.tags).toContain('onboarding');
      expect(metadata.tags).toHaveLength(2);
      expect(metadata.tags).toEqual(
        expect.arrayContaining(['demo', 'onboarding'])
      );
    });
  });

  describe('Session Queries', () => {
    test('finds active sessions', async () => {
      const sessions = await findActiveSessions('org_123');

      expect(sessions).toBeInstanceOf(Array);
      expect(sessions.length).toBeGreaterThan(0);

      sessions.forEach((session) => {
        expect(session.status).toBe('active');
        expect(session.organizationId).toBe('org_123');
        expect(session.completedAt).toBeNull();
      });
    });

    test('returns empty array when no sessions found', async () => {
      const sessions = await findActiveSessions('nonexistent_org');

      expect(sessions).toEqual([]);
      expect(sessions).toHaveLength(0);
    });
  });

  describe('Error Handling', () => {
    test('throws error for invalid session ID', async () => {
      await expect(
        updateSession('invalid_id', { status: 'active' })
      ).rejects.toThrow();

      await expect(
        updateSession('invalid_id', { status: 'active' })
      ).rejects.toThrow('Session not found');
    });

    test('throws error for duplicate session', async () => {
      const createDuplicate = async () => {
        await createSession({ userId: 'user_123', externalId: 'ext_123' });
        await createSession({ userId: 'user_123', externalId: 'ext_123' });
      };

      await expect(createDuplicate()).rejects.toThrow(/duplicate/i);
    });
  });
});
```

---

### Example 3 – Framework Integration: ROI Calculator

```typescript
import { calculateROI, calculateNPV, calculateIRR } from '@/lib/roi/calculator';
import { ROIInput, ROIResult } from '@/lib/roi/types';

describe('ROI Calculator - Advanced Matcher Patterns', () => {
  describe('ROI Calculation', () => {
    test('calculates basic ROI correctly', () => {
      const input: ROIInput = {
        investment: 10000,
        returns: [3000, 4000, 5000],
        timeframe: 3,
      };

      const result = calculateROI(input);

      // Numeric assertions with precision
      expect(result.roi).toBeCloseTo(0.2, 2); // 20% ROI
      expect(result.roi).toBeGreaterThan(0);
      expect(result.roi).toBeFinite();

      // Result structure
      expect(result).toMatchObject({
        roi: expect.any(Number),
        npv: expect.any(Number),
        irr: expect.any(Number),
        paybackPeriod: expect.any(Number),
      });

      // Type-safe property checks
      expect(result).toHaveProperty('roi');
      expect(result).toHaveProperty('confidence');
      expect(result.confidence).toBeGreaterThanOrEqual(0);
      expect(result.confidence).toBeLessThanOrEqual(1);
    });

    test('handles negative ROI', () => {
      const input: ROIInput = {
        investment: 10000,
        returns: [1000, 1000, 1000],
        timeframe: 3,
      };

      const result = calculateROI(input);

      expect(result.roi).toBeLessThan(0);
      expect(result.roi).toBeCloseTo(-0.7, 1); // -70% loss
      expect(result.paybackPeriod).toBeGreaterThan(input.timeframe);
    });

    test('calculates with confidence scores', () => {
      const input: ROIInput = {
        investment: 10000,
        returns: [3000, 4000, 5000],
        timeframe: 3,
        dataQuality: 'high',
        historicalData: true,
      };

      const result = calculateROI(input);

      expect(result.confidence).toBeCloseTo(0.85, 2);
      expect(result.confidence).toBeGreaterThan(0.8);

      // Confidence metadata
      expect(result.confidenceFactors).toMatchObject({
        dataQuality: 'high',
        historicalData: true,
      });
    });
  });

  describe('NPV Calculation', () => {
    test('calculates NPV with discount rate', () => {
      const cashFlows = [1000, 2000, 3000];
      const discountRate = 0.1;

      const npv = calculateNPV(cashFlows, discountRate);

      expect(npv).toBeGreaterThan(0);
      expect(npv).toBeLessThan(cashFlows.reduce((a, b) => a + b, 0));
      expect(npv).toBeCloseTo(4815.9, 1);
    });

    test('handles zero discount rate', () => {
      const cashFlows = [1000, 2000, 3000];
      const npv = calculateNPV(cashFlows, 0);

      expect(npv).toBe(6000);
      expect(npv).toEqual(cashFlows.reduce((a, b) => a + b, 0));
    });

    test('throws error for invalid discount rate', () => {
      const cashFlows = [1000, 2000];

      expect(() => calculateNPV(cashFlows, -0.5)).toThrow();
      expect(() => calculateNPV(cashFlows, 2)).toThrow(/rate must be/i);
    });
  });

  describe('IRR Calculation', () => {
    test('calculates IRR accurately', () => {
      const cashFlows = [-10000, 3000, 4000, 5000];
      const irr = calculateIRR(cashFlows);

      expect(irr).toBeGreaterThan(0);
      expect(irr).toBeLessThan(1);
      expect(irr).toBeCloseTo(0.163, 3); // ~16.3% IRR
    });

    test('returns undefined for no solution', () => {
      const cashFlows = [-10000, 100, 100, 100];
      const irr = calculateIRR(cashFlows);

      expect(irr).toBeUndefined();
    });

    test('handles edge cases', () => {
      // All positive cash flows
      expect(() => calculateIRR([1000, 2000, 3000])).toThrow();

      // All negative cash flows
      expect(() => calculateIRR([-1000, -2000, -3000])).toThrow();

      // Empty array
      expect(() => calculateIRR([])).toThrow(/at least/i);
    });
  });

  describe('Complex ROI Scenarios', () => {
    test('calculates multi-year projections', () => {
      const input: ROIInput = {
        investment: 50000,
        returns: Array(5).fill(15000), // 5 years of returns
        timeframe: 5,
        discountRate: 0.08,
      };

      const result = calculateROI(input);

      // Array of yearly results
      expect(result.yearlyBreakdown).toBeInstanceOf(Array);
      expect(result.yearlyBreakdown).toHaveLength(5);

      result.yearlyBreakdown.forEach((year, index) => {
        expect(year).toMatchObject({
          year: index + 1,
          cashFlow: expect.any(Number),
          cumulativeROI: expect.any(Number),
          npv: expect.any(Number),
        });
      });

      // Cumulative ROI increases over time
      const rois = result.yearlyBreakdown.map((y) => y.cumulativeROI);
      for (let i = 1; i < rois.length; i++) {
        expect(rois[i]).toBeGreaterThan(rois[i - 1]);
      }
    });

    test('compares multiple scenarios', () => {
      const scenarios = [
        { name: 'Conservative', returns: [2000, 2000, 2000] },
        { name: 'Moderate', returns: [3000, 3000, 3000] },
        { name: 'Aggressive', returns: [5000, 5000, 5000] },
      ];

      const results = scenarios.map((scenario) =>
        calculateROI({
          investment: 10000,
          returns: scenario.returns,
          timeframe: 3,
        })
      );

      // Compare results
      expect(results).toHaveLength(3);
      expect(results[0].roi).toBeLessThan(results[1].roi);
      expect(results[1].roi).toBeLessThan(results[2].roi);

      // All positive
      results.forEach((result) => {
        expect(result.roi).toBeGreaterThan(0);
      });
    });
  });

  describe('Async ROI Calculations', () => {
    test('fetches historical data and calculates ROI', async () => {
      const calculateWithHistory = async (orgId: string) => {
        const history = await fetchHistoricalData(orgId);
        return calculateROI({
          investment: 10000,
          returns: history.averageReturns,
          timeframe: 3,
        });
      };

      await expect(
        calculateWithHistory('org_123')
      ).resolves.toMatchObject({
        roi: expect.any(Number),
        confidence: expect.any(Number),
      });
    });

    test('handles calculation errors gracefully', async () => {
      const calculateWithInvalidData = async () => {
        const data = await fetchInvalidData();
        return calculateROI(data);
      };

      await expect(calculateWithInvalidData()).rejects.toThrow();
      await expect(calculateWithInvalidData()).rejects.toThrow(
        /invalid input/i
      );
    });
  });
});
```

---

## 6. Common Pitfalls

### Pitfall 1: Using `toBe()` for Objects

**Problem:**
```typescript
// ❌ FAILS - Different object references
const user = { id: '1', name: 'Alice' };
expect(user).toBe({ id: '1', name: 'Alice' });
```

**Solution:**
```typescript
// ✅ Use toEqual() for value equality
expect(user).toEqual({ id: '1', name: 'Alice' });

// ✅ Or toStrictEqual() for strict checks
expect(user).toStrictEqual({ id: '1', name: 'Alice' });
```

---

### Pitfall 2: Forgetting `await` with Async Matchers

**Problem:**
```typescript
// ❌ Test passes even if promise rejects
test('async test', () => {
  expect(fetchData()).resolves.toBe('data'); // Missing await!
});
```

**Solution:**
```typescript
// ✅ Always await async matchers
test('async test', async () => {
  await expect(fetchData()).resolves.toBe('data');
});
```

---

### Pitfall 3: Floating Point Comparison

**Problem:**
```typescript
// ❌ FAILS due to floating point precision
expect(0.1 + 0.2).toBe(0.3);
```

**Solution:**
```typescript
// ✅ Use toBeCloseTo() for floating point numbers
expect(0.1 + 0.2).toBeCloseTo(0.3);
expect(0.1 + 0.2).toBeCloseTo(0.3, 5); // 5 decimal precision
```

---

### Pitfall 4: Testing Exceptions Without Wrapping

**Problem:**
```typescript
// ❌ FAILS - Error thrown immediately, not caught by Jest
const throwError = () => {
  throw new Error('Oops');
};

expect(throwError()); // Error thrown here!
```

**Solution:**
```typescript
// ✅ Pass function reference, don't call it
expect(throwError).toThrow();
expect(throwError).toThrow('Oops');

// ✅ Or wrap in arrow function
expect(() => throwError()).toThrow();
```

---

### Pitfall 5: Ignoring `undefined` Properties

**Problem:**
```typescript
// ❌ Passes but properties differ
expect({ a: 1 }).toEqual({ a: 1, b: undefined });
```

**Solution:**
```typescript
// ✅ Use toStrictEqual() to catch undefined differences
expect({ a: 1 }).not.toStrictEqual({ a: 1, b: undefined });

// ✅ Or be explicit about undefined
expect({ a: 1, b: undefined }).toStrictEqual({
  a: 1,
  b: undefined,
});
```

---

### Pitfall 6: Over-Generic Assertions

**Problem:**
```typescript
// ❌ Too vague, passes for many unintended values
expect(response).toBeTruthy();
expect(data).toBeDefined();
```

**Solution:**
```typescript
// ✅ Be specific about expected values
expect(response.status).toBe(200);
expect(data).toEqual({ id: '1', name: 'Test' });
expect(data.items).toHaveLength(5);
```

---

### Pitfall 7: Testing Private Implementation Details

**Problem:**
```typescript
// ❌ Tests internal structure, not behavior
expect(component.state.counter).toBe(0);
expect(component._internalMethod).toBeDefined();
```

**Solution:**
```typescript
// ✅ Test public API and behavior
expect(component.getCount()).toBe(0);
expect(component.render()).toContain('Count: 0');
```

---

### Pitfall 8: Not Negating Properly

**Problem:**
```typescript
// ❌ Double negative, confusing
expect(value).not.not.toBe(true);
```

**Solution:**
```typescript
// ✅ Use positive assertion
expect(value).toBe(true);
```

---

### Pitfall 9: Array Order Assumptions

**Problem:**
```typescript
// ❌ Fails if order changes
const tags = getRandomTags();
expect(tags).toEqual(['typescript', 'jest', 'testing']);
```

**Solution:**
```typescript
// ✅ Use arrayContaining for order-independent checks
expect(tags).toEqual(
  expect.arrayContaining(['typescript', 'jest', 'testing'])
);

// ✅ Or sort before comparing
expect(tags.sort()).toEqual(['jest', 'testing', 'typescript'].sort());
```

---

### Pitfall 10: Misusing `toMatchObject()` for Exact Matches

**Problem:**
```typescript
// ❌ Passes even with extra properties
expect({ a: 1, b: 2, c: 3 }).toMatchObject({ a: 1 });
// This passes, but you expected exact match
```

**Solution:**
```typescript
// ✅ Use toEqual() or toStrictEqual() for exact matches
expect({ a: 1, b: 2, c: 3 }).toEqual({ a: 1, b: 2, c: 3 });
```

---

## 7. AI Pair Programming Notes

### Loading Strategy

**Load this file when:**
- Writing assertions for any test
- Debugging test failures with unclear error messages
- Choosing between `toBe()`, `toEqual()`, and `toStrictEqual()`
- Testing async functions or promises
- Creating custom matchers

**Bundle with:**
- `QUICK-REFERENCE.md` - Quick syntax lookup
- `01-FUNDAMENTALS.md` - Basic Jest concepts
- `04-ASYNC-TESTING.md` - Async patterns in depth

### Prompt Patterns

```typescript
"Load docs/kb/testing/jest/02-MATCHERS-ASSERTIONS.md and explain
which matcher to use for comparing this ROI calculation result."

"Using the matcher examples from 02-MATCHERS-ASSERTIONS.md,
write assertions for this Session object that check:
- All required fields are present
- Status is one of the valid enum values
- Timestamps are valid Date objects
- ROI score is between 0 and 1"

"Reference the Common Pitfalls section in 02-MATCHERS-ASSERTIONS.md
to fix this failing test."
```

### Key Takeaways for AI

1. **Prefer specific matchers over generic ones**
   - `expect(x).toBe(5)` over `expect(x).toBeTruthy()`
   - `expect(arr).toHaveLength(3)` over `expect(arr.length).toBe(3)`

2. **Always await async matchers**
   - `await expect(promise).resolves.toBe(x)`
   - `await expect(asyncFn()).rejects.toThrow()`

3. **Use correct equality matcher**
   - Primitives → `toBe()`
   - Objects/Arrays → `toEqual()` (default)
   - Strict checks → `toStrictEqual()`
   - Partial matching → `toMatchObject()`

4. **Floating point numbers need `toBeCloseTo()`**
   - Never use `toBe()` for `0.1 + 0.2`

5. **Wrap exception tests in functions**
   - `expect(() => throwError()).toThrow()`
   - NOT `expect(throwError()).toThrow()`

### Anti-Patterns to Avoid

```typescript
// ❌ Don't do this
expect(result).toBe({ a: 1 }); // Use toEqual()
expect(promise).resolves.toBe(x); // Missing await
expect(0.1 + 0.2).toBe(0.3); // Use toBeCloseTo()
expect(throwError()).toThrow(); // Pass function reference
expect(x).toBeTruthy(); // Too generic

// ✅ Do this instead
expect(result).toEqual({ a: 1 });
await expect(promise).resolves.toBe(x);
expect(0.1 + 0.2).toBeCloseTo(0.3);
expect(throwError).toThrow();
expect(x).toBe(expectedValue);
```

### TypeScript Tips

```typescript
// ✅ Type-safe assertions
const session: Session = await createSession();
expect(session.status).toBe<SessionStatus>('active');

// ✅ Use satisfies for mock data
const mockUser = {
  id: '1',
  name: 'Test',
} satisfies Partial<User>;

// ✅ Type guards in assertions
expect(result).toBeDefined();
// TypeScript now knows result is not undefined
expect(result.data).toHaveLength(3);
```

---

## Last Updated

2025-11-14
