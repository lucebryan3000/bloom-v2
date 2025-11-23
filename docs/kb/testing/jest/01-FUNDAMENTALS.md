---
id: jest-01-fundamentals
topic: jest
file_role: fundamentals
profile: full
difficulty_level: beginner-to-intermediate
kb_version: 3.1
prerequisites: [javascript-basics, typescript-basics]
related_topics: [testing, tdd, react-testing-library]
embedding_keywords: [jest, fundamentals, testing, test-driven-development, unit-testing, test-structure, test-lifecycle, describe, it, expect]
last_reviewed: 2025-11-14
---

# Jest Fundamentals

<!-- Query: "How do I get started with Jest?" -->
<!-- Query: "What is Jest and how does it work?" -->
<!-- Query: "Jest test structure basics" -->

## 1. Purpose

This file covers core Jest concepts and mental models. Read this first to understand:

- **What Jest is** and why it's designed the way it is
- **How Jest executes tests** and manages test isolation
- **Fundamental test structure** (describe, it/test, expect)
- **Test lifecycle hooks** (beforeEach, afterEach, beforeAll, afterAll)
- **When to use unit vs integration tests** in Jest
- **Bloom project-specific testing approach** with Next.js 16 + TypeScript + Prisma

If you're new to Jest or testing in general, start here. If you need quick syntax reference, see `QUICK-REFERENCE.md`.

---

## 2. Mental Model / Problem Statement

<!-- Query: "Jest philosophy and design principles" -->
<!-- Query: "How does Jest differ from other test frameworks?" -->

### 2.1 What is Jest?

Jest is a **delightful JavaScript testing framework** with a focus on simplicity. Created by Facebook (now Meta), it's become the de facto standard for testing JavaScript applications, particularly React projects.

**Core Philosophy:**
- **Zero Configuration**: Works out of the box for most JavaScript projects
- **Fast & Isolated**: Runs tests in parallel with isolated test environments
- **Developer Experience**: Rich error messages, watch mode, and interactive CLI
- **Batteries Included**: Built-in assertions, mocking, coverage, and snapshot testing
- **Universal**: Works with TypeScript, React, Node.js, Next.js, and more

### 2.2 The Testing Mental Model

Think of Jest tests as **executable documentation** that:

1. **Describe behavior** ("When user clicks submit...")
2. **Set up context** ("Given a logged-in user...")
3. **Exercise the code** ("When they submit the form...")
4. **Verify outcomes** ("Then the data should be saved")

Jest tests follow the **Arrange-Act-Assert** (AAA) pattern:

```typescript
test('calculates total correctly', () => {
  // ARRANGE: Set up the test data and dependencies
  const calculator = new Calculator();
  const numbers = [1, 2, 3, 4, 5];

  // ACT: Execute the code under test
  const result = calculator.sum(numbers);

  // ASSERT: Verify the outcome
  expect(result).toBe(15);
});
```

### 2.3 Test Isolation: The Foundation

**Critical Concept**: Every Jest test runs in **complete isolation**. Tests:
- Cannot affect each other
- Run in a random order (by default)
- Have their own module scope
- Start with a clean slate

This isolation is what makes tests reliable and prevents "flaky tests" (tests that pass sometimes and fail other times).

**Why This Matters:**
```typescript
// ❌ BAD: Tests that depend on each other
let userCount = 0;

test('creates first user', () => {
  userCount++;
  expect(userCount).toBe(1);
});

test('creates second user', () => {
  userCount++; // Assumes previous test ran first!
  expect(userCount).toBe(2); // FLAKY: May fail if tests run in different order
});

// ✅ GOOD: Independent tests
test('creates first user', () => {
  let userCount = 0;
  userCount++;
  expect(userCount).toBe(1);
});

test('creates second user', () => {
  let userCount = 0;
  userCount++;
  expect(userCount).toBe(1); // Each test starts fresh
});
```

### 2.4 Jest's Test Runner Architecture

Understanding how Jest runs tests helps you write better tests:

1. **Discovery Phase**: Jest finds all test files matching `*.test.ts`, `*.spec.ts`, or files in `__tests__/` directories
2. **Module Loading**: Jest creates isolated module environments for each test file
3. **Test Execution**: Runs tests in parallel (by default) across multiple workers
4. **Assertion Evaluation**: Checks expectations and reports failures
5. **Teardown**: Cleans up resources and resets state

**Key Insight**: Jest doesn't just run your tests sequentially. It:
- Runs test **files** in parallel (each in a separate Node process)
- Runs test **cases** within a file sequentially
- Provides hooks to control setup/teardown timing

---

## 3. Golden Path

<!-- Query: "Recommended Jest testing approach" -->
<!-- Query: "Best practices for Jest test structure" -->
<!-- Query: "How to organize Jest tests" -->

### 3.1 Test File Organization

**Bloom Project Standard:**

```
project-root/
├── __tests__/              # Main test directory
│   ├── api/                # API endpoint tests
│   ├── components/         # React component tests
│   ├── lib/                # Business logic tests
│   ├── stores/             # State management tests
│   └── utils/              # Utility function tests
├── tests/                  # Legacy/integration tests
│   ├── integration/
│   ├── unit/
│   └── e2e/               # Playwright tests (excluded from Jest)
└── src/
    └── components/
        └── Button/
            ├── Button.tsx
            └── Button.test.tsx  # Collocated tests (alternative)
```

**Naming Conventions:**
- Test files: `*.test.ts` or `*.test.tsx` (Jest)
- E2E files: `*.spec.ts` (Playwright, excluded from Jest via `testPathIgnorePatterns`)
- Test suites: Match the file they're testing (`calculator.ts` → `calculator.test.ts`)

### 3.2 Basic Test Structure

The fundamental building block is the **test case**:

```typescript
// Single test
test('description of what is being tested', () => {
  // Test implementation
});

// Or using 'it' (alias for 'test')
it('should do something specific', () => {
  // Test implementation
});
```

**Best Practice**: Use `test()` for simple cases, `it()` when building readable specifications with `describe()`.

### 3.3 Grouping Tests with describe()

Use `describe()` blocks to organize related tests:

```typescript
describe('Calculator', () => {
  describe('addition', () => {
    it('should add two positive numbers', () => {
      expect(2 + 2).toBe(4);
    });

    it('should add negative numbers', () => {
      expect(-2 + -3).toBe(-5);
    });

    it('should handle zero', () => {
      expect(0 + 5).toBe(5);
    });
  });

  describe('division', () => {
    it('should divide two numbers', () => {
      expect(10 / 2).toBe(5);
    });

    it('should throw when dividing by zero', () => {
      expect(() => divide(10, 0)).toThrow();
    });
  });
});
```

**Why This Matters:**
- **Readability**: Clear hierarchy of tests
- **Organization**: Group related functionality
- **Scoped Setup**: Use lifecycle hooks per group
- **Better Error Messages**: "Calculator > addition > should add two positive numbers" is clearer than "test #3"

### 3.4 Test Lifecycle Hooks

Jest provides hooks to run code at specific points in the test lifecycle:

```typescript
describe('Database operations', () => {
  let db: Database;

  // Runs ONCE before ALL tests in this describe block
  beforeAll(async () => {
    db = await connectDatabase();
  });

  // Runs BEFORE EACH test in this describe block
  beforeEach(async () => {
    await db.clear(); // Start with clean state
  });

  // Runs AFTER EACH test in this describe block
  afterEach(async () => {
    await db.rollback(); // Clean up changes
  });

  // Runs ONCE after ALL tests in this describe block
  afterAll(async () => {
    await db.disconnect();
  });

  test('creates a record', async () => {
    const record = await db.create({ name: 'Test' });
    expect(record.id).toBeDefined();
  });

  test('updates a record', async () => {
    const record = await db.create({ name: 'Original' });
    await db.update(record.id, { name: 'Updated' });
    const updated = await db.find(record.id);
    expect(updated.name).toBe('Updated');
  });
});
```

**Hook Execution Order:**

```
beforeAll()           // Once at start
  beforeEach()        // Before test 1
    test('first')
  afterEach()         // After test 1
  beforeEach()        // Before test 2
    test('second')
  afterEach()         // After test 2
afterAll()            // Once at end
```

**Golden Rule**: Use lifecycle hooks to ensure test isolation, not to share state between tests.

### 3.5 The Three-Part Test Structure (AAA)

**Arrange-Act-Assert** is the gold standard for test clarity:

```typescript
test('calculates ROI correctly', () => {
  // ARRANGE: Set up test data and dependencies
  const calculator = new ROICalculator();
  const inputs = {
    weeklyHours: 20,
    teamSize: 5,
    hourlyRate: 50,
    automationPercentage: 60,
    timeframe: 36
  };

  // ACT: Execute the code under test
  const result = calculator.calculate(inputs);

  // ASSERT: Verify the outcome
  expect(result.totalROI).toBeGreaterThan(0);
  expect(result.paybackPeriod).toBeLessThan(24);
  expect(result.confidenceScore).toBeGreaterThanOrEqual(0);
  expect(result.confidenceScore).toBeLessThanOrEqual(100);
});
```

**Why This Structure Works:**
1. **Readability**: Clear separation of concerns
2. **Maintainability**: Easy to see what's being tested
3. **Debuggability**: Obvious where to look when tests fail
4. **Documentation**: Self-documenting test intent

### 3.6 Expectations (Assertions)

Jest uses `expect()` for assertions. Common matchers:

```typescript
// Equality
expect(value).toBe(42);              // Strict equality (===)
expect(object).toEqual({ a: 1 });    // Deep equality
expect(value).toBeNull();            // Null check
expect(value).toBeUndefined();       // Undefined check
expect(value).toBeDefined();         // Not undefined

// Truthiness
expect(value).toBeTruthy();          // Boolean true
expect(value).toBeFalsy();           // Boolean false

// Numbers
expect(value).toBeGreaterThan(10);
expect(value).toBeLessThanOrEqual(100);
expect(value).toBeCloseTo(0.3, 5);   // Floating point comparison

// Strings
expect(string).toMatch(/regex/);
expect(string).toContain('substring');

// Arrays and iterables
expect(array).toContain(item);
expect(array).toHaveLength(3);

// Objects
expect(object).toHaveProperty('key');
expect(object).toHaveProperty('nested.key', value);

// Functions
expect(() => fn()).toThrow();
expect(() => fn()).toThrow(Error);
expect(() => fn()).toThrow('error message');

// Promises
await expect(promise).resolves.toBe(value);
await expect(promise).rejects.toThrow();
```

### 3.7 Async Testing Patterns

Jest fully supports async code. Three patterns:

**Pattern 1: Async/Await (Recommended)**
```typescript
test('fetches user data', async () => {
  const user = await fetchUser(123);
  expect(user.name).toBe('Alice');
});
```

**Pattern 2: Return Promise**
```typescript
test('fetches user data', () => {
  return fetchUser(123).then(user => {
    expect(user.name).toBe('Alice');
  });
});
```

**Pattern 3: Done Callback (Legacy, Avoid)**
```typescript
test('fetches user data', (done) => {
  fetchUser(123).then(user => {
    expect(user.name).toBe('Alice');
    done();
  });
});
```

**Golden Rule**: Always use async/await for async tests. It's clearer and catches forgotten `await` statements.

### 3.8 Mocking Basics

Jest provides powerful mocking capabilities:

```typescript
// Mock a function
const mockFn = jest.fn();
mockFn.mockReturnValue(42);
expect(mockFn()).toBe(42);
expect(mockFn).toHaveBeenCalled();

// Mock a module
jest.mock('@/lib/database');
import { query } from '@/lib/database';
(query as jest.Mock).mockResolvedValue({ rows: [] });

// Spy on a method
const spy = jest.spyOn(object, 'method');
spy.mockReturnValue('mocked');
object.method(); // Returns 'mocked'
spy.mockRestore(); // Restore original
```

See `02-MOCKING-SPIES.md` for comprehensive mocking patterns.

---

## 4. Variations & Trade-Offs

<!-- Query: "When to use different testing strategies in Jest" -->
<!-- Query: "Unit vs integration tests in Jest" -->

### 4.1 Test Granularity: Unit vs Integration

**Unit Tests:**
- Test a **single function or class** in isolation
- Mock all dependencies
- Fast execution (< 100ms)
- High coverage, narrow scope

```typescript
// Unit test: Tests ROI calculation logic only
test('calculates annual savings', () => {
  const calculator = new ROICalculator();
  const result = calculator.calculateAnnualSavings({
    weeklyHours: 40,
    hourlyRate: 25,
    automationPercentage: 100
  });
  expect(result).toBe(52000); // 40 * 52 weeks * $25 * 100%
});
```

**Integration Tests:**
- Test **multiple components working together**
- Use real dependencies (or realistic fakes)
- Slower execution (100ms - 1s)
- Lower coverage, broader scope

```typescript
// Integration test: Tests calculator + database interaction
test('saves ROI calculation to database', async () => {
  const calculator = new ROICalculator();
  const db = new Database(); // Real database connection

  const inputs = { /* ... */ };
  const result = calculator.calculate(inputs);

  await db.saveROIReport(result);
  const saved = await db.findROIReport(result.id);

  expect(saved.totalROI).toBe(result.totalROI);
});
```

**Trade-Offs:**

| Aspect | Unit Tests | Integration Tests |
|--------|-----------|-------------------|
| Speed | Very fast (< 100ms) | Slower (100ms - 1s) |
| Isolation | Complete | Partial |
| Confidence | Lower (narrow scope) | Higher (realistic) |
| Debugging | Easy (pinpoint failures) | Harder (multiple suspects) |
| Maintenance | Low (stable interfaces) | Higher (complex setup) |
| Coverage | High (exhaustive cases) | Lower (happy paths) |

**Bloom Approach**: Favor unit tests for business logic, integration tests for API endpoints and database operations.

### 4.2 Test Organization Strategies

**Strategy 1: Centralized Test Directory** (Bloom uses this)
```
__tests__/
├── api/
├── components/
├── lib/
└── utils/
```

**Pros:**
- Clear separation of tests from source
- Easy to exclude from build
- Consistent location

**Cons:**
- Less obvious which file is being tested
- Longer import paths

**Strategy 2: Collocated Tests**
```
src/
└── components/
    └── Button/
        ├── Button.tsx
        ├── Button.test.tsx
        └── Button.module.css
```

**Pros:**
- Tests live next to code
- Easier to find related tests
- Encourages testing

**Cons:**
- Mixes source and test files
- May confuse build tools

**Trade-Off**: Bloom uses centralized tests for clarity, but either approach works if applied consistently.

### 4.3 describe() Nesting: How Deep?

**Shallow Nesting (1-2 levels):**
```typescript
describe('Calculator', () => {
  test('adds numbers', () => { /* ... */ });
  test('subtracts numbers', () => { /* ... */ });
});
```

**Deep Nesting (3+ levels):**
```typescript
describe('Calculator', () => {
  describe('addition', () => {
    describe('with positive numbers', () => {
      test('adds two numbers', () => { /* ... */ });
      test('adds many numbers', () => { /* ... */ });
    });
    describe('with negative numbers', () => {
      test('adds negative numbers', () => { /* ... */ });
    });
  });
});
```

**Trade-Off:**
- **Shallow**: Simpler structure, harder to organize many tests
- **Deep**: Clear categorization, can become over-engineered

**Bloom Guideline**: Use 2-3 levels maximum. If you need more, consider splitting the test file.

### 4.4 beforeEach vs beforeAll

**Use beforeEach when:**
- Setting up mutable state
- Creating fresh instances
- Ensuring test isolation

```typescript
describe('User repository', () => {
  let db: Database;

  beforeEach(async () => {
    db = await createTestDatabase();
    await db.migrate();
  });

  afterEach(async () => {
    await db.destroy();
  });

  // Each test gets a fresh database
});
```

**Use beforeAll when:**
- Setting up expensive, immutable resources
- Connecting to services
- One-time initialization

```typescript
describe('API client', () => {
  let server: TestServer;

  beforeAll(async () => {
    server = await startTestServer();
  });

  afterAll(async () => {
    await server.stop();
  });

  // All tests share the same server
});
```

**Trade-Off:**
- `beforeEach`: Slower, but safer (guaranteed isolation)
- `beforeAll`: Faster, but riskier (shared state can leak)

**Golden Rule**: When in doubt, use `beforeEach`. Speed is rarely the bottleneck, but flaky tests are expensive.

### 4.5 Skipping and Focusing Tests

**Skip tests temporarily:**
```typescript
test.skip('this test is broken', () => {
  // Will not run
});

describe.skip('entire suite', () => {
  // All tests skipped
});
```

**Focus on specific tests:**
```typescript
test.only('debug this test', () => {
  // ONLY this test will run
});

describe.only('debug this suite', () => {
  // Only tests in this suite
});
```

**Trade-Off:**
- `.skip`: Good for temporary disabling, bad if forgotten (stale tests)
- `.only`: Great for debugging, **dangerous in CI** (may hide failures)

**Bloom CI Check**: We fail builds if `.only` is found in committed code.

---

## 5. Examples

<!-- Query: "Jest test examples for beginners" -->
<!-- Query: "Real-world Jest testing examples" -->

### Example 1 – Pedagogical: Basic Test Structure

**Scenario**: Learn the fundamentals with the simplest possible test.

```typescript
// sum.ts
export function sum(a: number, b: number): number {
  return a + b;
}

// sum.test.ts
import { sum } from './sum';

// Single test case
test('adds 1 + 2 to equal 3', () => {
  expect(sum(1, 2)).toBe(3);
});

// Multiple related tests
describe('sum function', () => {
  test('adds positive numbers', () => {
    expect(sum(1, 2)).toBe(3);
    expect(sum(5, 7)).toBe(12);
  });

  test('adds negative numbers', () => {
    expect(sum(-1, -2)).toBe(-3);
  });

  test('adds zero', () => {
    expect(sum(0, 5)).toBe(5);
    expect(sum(5, 0)).toBe(5);
  });

  test('handles floating point', () => {
    expect(sum(0.1, 0.2)).toBeCloseTo(0.3, 5);
  });
});
```

**Learning Points:**
1. `test()` defines a single test case
2. `describe()` groups related tests
3. `expect()` makes assertions
4. `.toBe()` for exact equality, `.toBeCloseTo()` for floats

**Running This Test:**
```bash
# Run all tests
npm test

# Run specific file
npm test sum.test.ts

# Watch mode
npm test -- --watch
```

---

### Example 2 – Realistic Synthetic: Business Logic Testing

**Scenario**: Test a realistic ROI calculator with proper setup and edge cases.

```typescript
// lib/roi/calculator.ts
export interface ROIInputs {
  weeklyHours: number;
  teamSize: number;
  hourlyRate: number;
  automationPercentage: number;
  implementationCost: number;
  timeframe: number; // months
}

export interface ROIResult {
  annualSavings: number;
  totalROI: number;
  paybackPeriod: number;
  confidenceScore: number;
}

export class ROICalculator {
  calculate(inputs: ROIInputs): ROIResult {
    const annualSavings = this.calculateAnnualSavings(inputs);
    const totalROI = this.calculateTotalROI(inputs, annualSavings);
    const paybackPeriod = this.calculatePaybackPeriod(inputs, annualSavings);
    const confidenceScore = this.calculateConfidence(inputs);

    return {
      annualSavings,
      totalROI,
      paybackPeriod,
      confidenceScore
    };
  }

  private calculateAnnualSavings(inputs: ROIInputs): number {
    const { weeklyHours, teamSize, hourlyRate, automationPercentage } = inputs;
    const weeksPerYear = 52;
    return weeklyHours * weeksPerYear * teamSize * hourlyRate * (automationPercentage / 100);
  }

  private calculateTotalROI(inputs: ROIInputs, annualSavings: number): number {
    const totalSavings = annualSavings * (inputs.timeframe / 12);
    return ((totalSavings - inputs.implementationCost) / inputs.implementationCost) * 100;
  }

  private calculatePaybackPeriod(inputs: ROIInputs, annualSavings: number): number {
    const monthlySavings = annualSavings / 12;
    return inputs.implementationCost / monthlySavings;
  }

  private calculateConfidence(inputs: ROIInputs): number {
    // Simplified: penalize high automation percentages
    let score = 100;
    if (inputs.automationPercentage > 80) score -= 20;
    if (inputs.automationPercentage > 90) score -= 20;
    return Math.max(0, score);
  }
}

// __tests__/lib/roi/calculator.test.ts
import { ROICalculator } from '@/lib/roi/calculator';
import type { ROIInputs } from '@/lib/roi/calculator';

describe('ROICalculator', () => {
  let calculator: ROICalculator;

  beforeEach(() => {
    calculator = new ROICalculator();
  });

  describe('calculate()', () => {
    it('should calculate complete ROI metrics', () => {
      const inputs: ROIInputs = {
        weeklyHours: 20,
        teamSize: 5,
        hourlyRate: 50,
        automationPercentage: 60,
        implementationCost: 50000,
        timeframe: 36
      };

      const result = calculator.calculate(inputs);

      expect(result.annualSavings).toBe(156000); // 20 * 52 * 5 * 50 * 0.6
      expect(result.totalROI).toBeGreaterThan(0);
      expect(result.paybackPeriod).toBeGreaterThan(0);
      expect(result.confidenceScore).toBeGreaterThanOrEqual(0);
      expect(result.confidenceScore).toBeLessThanOrEqual(100);
    });

    it('should handle zero automation percentage', () => {
      const inputs: ROIInputs = {
        weeklyHours: 20,
        teamSize: 5,
        hourlyRate: 50,
        automationPercentage: 0,
        implementationCost: 50000,
        timeframe: 36
      };

      const result = calculator.calculate(inputs);

      expect(result.annualSavings).toBe(0);
      expect(result.totalROI).toBeLessThan(0); // Negative ROI
    });

    it('should penalize unrealistic automation percentages', () => {
      const realistic: ROIInputs = {
        weeklyHours: 20,
        teamSize: 5,
        hourlyRate: 50,
        automationPercentage: 60,
        implementationCost: 50000,
        timeframe: 36
      };

      const unrealistic: ROIInputs = {
        ...realistic,
        automationPercentage: 95
      };

      const realisticResult = calculator.calculate(realistic);
      const unrealisticResult = calculator.calculate(unrealistic);

      expect(realisticResult.confidenceScore).toBeGreaterThan(
        unrealisticResult.confidenceScore
      );
    });
  });

  describe('edge cases', () => {
    it('should handle very high hourly rates', () => {
      const inputs: ROIInputs = {
        weeklyHours: 10,
        teamSize: 1,
        hourlyRate: 200,
        automationPercentage: 50,
        implementationCost: 25000,
        timeframe: 24
      };

      const result = calculator.calculate(inputs);

      expect(result.annualSavings).toBe(52000); // 10 * 52 * 1 * 200 * 0.5
    });

    it('should handle large teams', () => {
      const inputs: ROIInputs = {
        weeklyHours: 5,
        teamSize: 50,
        hourlyRate: 50,
        automationPercentage: 30,
        implementationCost: 100000,
        timeframe: 24
      };

      const result = calculator.calculate(inputs);

      expect(result.annualSavings).toBeGreaterThan(0);
      expect(result.paybackPeriod).toBeGreaterThan(0);
    });

    it('should calculate reasonable payback periods', () => {
      const inputs: ROIInputs = {
        weeklyHours: 30,
        teamSize: 4,
        hourlyRate: 50,
        automationPercentage: 60,
        implementationCost: 40000,
        timeframe: 48
      };

      const result = calculator.calculate(inputs);

      // With good ROI, payback should be < 36 months
      expect(result.paybackPeriod).toBeGreaterThan(0);
      expect(result.paybackPeriod).toBeLessThan(60);
    });
  });

  describe('calculateAnnualSavings()', () => {
    it('should calculate annual savings correctly', () => {
      const inputs: ROIInputs = {
        weeklyHours: 40,
        teamSize: 1,
        hourlyRate: 25,
        automationPercentage: 100,
        implementationCost: 0,
        timeframe: 24
      };

      const result = calculator.calculate(inputs);

      // 40 hours/week * 52 weeks * 1 person * $25/hour * 100%
      expect(result.annualSavings).toBe(52000);
    });

    it('should scale with team size', () => {
      const singlePerson: ROIInputs = {
        weeklyHours: 20,
        teamSize: 1,
        hourlyRate: 50,
        automationPercentage: 100,
        implementationCost: 0,
        timeframe: 24
      };

      const fivePerson: ROIInputs = {
        ...singlePerson,
        teamSize: 5
      };

      const singleResult = calculator.calculate(singlePerson);
      const fiveResult = calculator.calculate(fivePerson);

      expect(fiveResult.annualSavings).toBe(singleResult.annualSavings * 5);
    });
  });
});
```

**Learning Points:**
1. Use `beforeEach()` to create fresh calculator instances
2. Group tests by method (`describe('calculate()')`)
3. Test edge cases separately (`describe('edge cases')`)
4. Use descriptive test names ("should handle zero automation percentage")
5. Verify multiple properties of complex results
6. Test relationships between inputs (scaling, proportions)

---

### Example 3 – Framework Integration: Next.js + React Testing Library

**Scenario**: Test a Next.js React component that fetches data and displays UI.

```typescript
// components/home/Hero.tsx
'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';

interface Session {
  id: string;
  status: 'active' | 'completed';
  startedAt: string;
  completedAt: string | null;
  responseCount: number;
}

export function Hero() {
  const [activeSession, setActiveSession] = useState<Session | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function checkActiveSession() {
      try {
        const response = await fetch('/api/sessions?status=active');
        const data = await response.json();
        if (data.sessions.length > 0) {
          setActiveSession(data.sessions[0]);
        }
      } catch (error) {
        console.error('Failed to check active session:', error);
      } finally {
        setLoading(false);
      }
    }

    checkActiveSession();
  }, []);

  return (
    <section className="hero">
      <h1>AI-Guided ROI Discovery — in 15 Minutes</h1>
      <p>Turn one messy workflow into a quantified business case</p>

      <div className="cta-buttons">
        <Link href="/workshop" className="btn-primary">
          Start 15-Minute Discovery
        </Link>

        {!loading && activeSession && (
          <Link href={`/workshop/${activeSession.id}`} className="btn-secondary">
            Resume Session
          </Link>
        )}
      </div>

      <div className="trust-badges">
        <span>No prep required</span>
        <span>Executive-ready output</span>
        <span>Private by design</span>
      </div>
    </section>
  );
}

// __tests__/components/home/Hero.test.tsx
import { render, screen, waitFor } from '@testing-library/react';
import { Hero } from '@/components/home/Hero';

// Mock global fetch
global.fetch = jest.fn();

describe('Hero Component', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('renders headline and subhead', () => {
    (global.fetch as jest.Mock).mockResolvedValueOnce({
      json: async () => ({ sessions: [] })
    });

    render(<Hero />);

    expect(
      screen.getByText(/AI-Guided ROI Discovery — in 15 Minutes/i)
    ).toBeInTheDocument();
    expect(
      screen.getByText(/Turn one messy workflow into a quantified business case/i)
    ).toBeInTheDocument();
  });

  it('shows Start Discovery button', () => {
    (global.fetch as jest.Mock).mockResolvedValueOnce({
      json: async () => ({ sessions: [] })
    });

    render(<Hero />);

    const startButton = screen.getByText(/Start 15-Minute Discovery/i);
    expect(startButton).toBeInTheDocument();
    expect(startButton).toHaveAttribute('href', '/workshop');
  });

  it('does not show Resume Session button when no active session', async () => {
    (global.fetch as jest.Mock).mockResolvedValueOnce({
      json: async () => ({ sessions: [] })
    });

    render(<Hero />);

    await waitFor(() => {
      expect(screen.queryByText(/Resume Session/i)).not.toBeInTheDocument();
    });
  });

  it('shows Resume Session button when active session exists', async () => {
    (global.fetch as jest.Mock).mockResolvedValueOnce({
      json: async () => ({
        sessions: [
          {
            id: 'WS-TEST-123',
            status: 'active',
            startedAt: new Date().toISOString(),
            completedAt: null,
            responseCount: 0
          }
        ]
      })
    });

    render(<Hero />);

    await waitFor(() => {
      const resumeButton = screen.getByText(/Resume Session/i);
      expect(resumeButton).toBeInTheDocument();
      expect(resumeButton).toHaveAttribute('href', '/workshop/WS-TEST-123');
    });
  });

  it('displays trust badges', () => {
    (global.fetch as jest.Mock).mockResolvedValueOnce({
      json: async () => ({ sessions: [] })
    });

    render(<Hero />);

    expect(screen.getByText(/No prep required/i)).toBeInTheDocument();
    expect(screen.getByText(/Executive-ready output/i)).toBeInTheDocument();
    expect(screen.getByText(/Private by design/i)).toBeInTheDocument();
  });

  it('handles API errors gracefully', async () => {
    const consoleError = jest.spyOn(console, 'error').mockImplementation();
    (global.fetch as jest.Mock).mockRejectedValueOnce(new Error('Network error'));

    render(<Hero />);

    await waitFor(() => {
      expect(consoleError).toHaveBeenCalledWith(
        'Failed to check active session:',
        expect.any(Error)
      );
    });

    // Component should still render
    expect(screen.getByText(/Start 15-Minute Discovery/i)).toBeInTheDocument();

    consoleError.mockRestore();
  });
});
```

**Learning Points:**
1. **Mock global APIs**: Use `jest.fn()` to mock `fetch`
2. **Test async rendering**: Use `waitFor()` for async state updates
3. **Test conditional rendering**: Verify elements appear/disappear based on state
4. **Test error handling**: Mock failures and verify graceful degradation
5. **Clean up mocks**: Use `beforeEach()` to reset mocks between tests
6. **Test accessibility**: Use `screen.getByText()` (queries by visible text)

**Bloom-Specific Patterns:**
- Mock API responses for all component tests
- Use React Testing Library queries (`getByText`, `queryByText`)
- Test both success and error paths
- Verify links have correct `href` attributes

---

## 6. Common Pitfalls

<!-- Query: "Common Jest testing mistakes" -->
<!-- Query: "Jest testing anti-patterns" -->
<!-- Query: "How to avoid flaky tests in Jest" -->

### Pitfall 1: Tests That Depend on Each Other

❌ **WRONG:**
```typescript
let userId: string;

test('creates user', async () => {
  userId = await createUser({ name: 'Alice' });
  expect(userId).toBeDefined();
});

test('updates user', async () => {
  // BREAKS if previous test didn't run or failed
  await updateUser(userId, { name: 'Bob' });
  const user = await getUser(userId);
  expect(user.name).toBe('Bob');
});
```

✅ **CORRECT:**
```typescript
describe('User operations', () => {
  let userId: string;

  beforeEach(async () => {
    // Each test gets a fresh user
    userId = await createUser({ name: 'Alice' });
  });

  test('creates user', () => {
    expect(userId).toBeDefined();
  });

  test('updates user', async () => {
    await updateUser(userId, { name: 'Bob' });
    const user = await getUser(userId);
    expect(user.name).toBe('Bob');
  });
});
```

**Why**: Tests run in parallel and in random order. Dependencies create flaky tests.

---

### Pitfall 2: Forgetting to await Async Operations

❌ **WRONG:**
```typescript
test('fetches user data', () => {
  const user = fetchUser(123); // Returns Promise, not user!
  expect(user.name).toBe('Alice'); // TypeError: Cannot read property 'name' of undefined
});
```

✅ **CORRECT:**
```typescript
test('fetches user data', async () => {
  const user = await fetchUser(123);
  expect(user.name).toBe('Alice');
});
```

**Why**: Async functions return Promises. Without `await`, you're testing the Promise object, not the resolved value.

---

### Pitfall 3: Testing Implementation Details

❌ **WRONG:**
```typescript
test('Counter component', () => {
  const { container } = render(<Counter />);
  const button = container.querySelector('.increment-button'); // Testing CSS class
  expect(button?.className).toContain('btn-primary'); // Testing style
});
```

✅ **CORRECT:**
```typescript
test('Counter component', () => {
  render(<Counter />);
  const button = screen.getByRole('button', { name: /increment/i });
  fireEvent.click(button);
  expect(screen.getByText('Count: 1')).toBeInTheDocument();
});
```

**Why**: Tests should verify behavior, not implementation. CSS classes and DOM structure can change; user-visible behavior shouldn't.

---

### Pitfall 4: Over-Mocking

❌ **WRONG:**
```typescript
test('calculates total price', () => {
  const calculator = new PriceCalculator();
  jest.spyOn(calculator, 'calculateTax').mockReturnValue(10);
  jest.spyOn(calculator, 'calculateShipping').mockReturnValue(5);
  jest.spyOn(calculator, 'calculateDiscount').mockReturnValue(3);

  const total = calculator.calculateTotal();
  expect(total).toBe(12); // What are we even testing?
});
```

✅ **CORRECT:**
```typescript
test('calculates total price', () => {
  const calculator = new PriceCalculator();
  const total = calculator.calculateTotal({
    subtotal: 100,
    taxRate: 0.1,
    shippingZone: 'domestic',
    discountCode: 'SAVE10'
  });

  expect(total).toBeCloseTo(101.5, 2); // Test actual logic
});
```

**Why**: Over-mocking makes tests useless. They pass even when the real code is broken.

**Rule of Thumb**: Mock I/O (network, database, filesystem), not business logic.

---

### Pitfall 5: Vague Test Names

❌ **WRONG:**
```typescript
test('works', () => { /* ... */ });
test('test 1', () => { /* ... */ });
test('handles input', () => { /* ... */ });
```

✅ **CORRECT:**
```typescript
test('calculates ROI with 60% automation correctly', () => { /* ... */ });
test('throws error when dividing by zero', () => { /* ... */ });
test('renders loading state while fetching user data', () => { /* ... */ });
```

**Why**: Test names are documentation. "works" tells you nothing when it fails.

**Template**: `should <expected behavior> when <specific condition>`

---

### Pitfall 6: Not Cleaning Up Mocks and Spies

❌ **WRONG:**
```typescript
test('first test', () => {
  jest.spyOn(console, 'log').mockImplementation();
  // ... test code ...
  // Forgot to restore!
});

test('second test', () => {
  console.log('This will not appear!'); // Still mocked from previous test
});
```

✅ **CORRECT:**
```typescript
describe('Console logging', () => {
  let consoleLogSpy: jest.SpyInstance;

  beforeEach(() => {
    consoleLogSpy = jest.spyOn(console, 'log').mockImplementation();
  });

  afterEach(() => {
    consoleLogSpy.mockRestore();
  });

  test('first test', () => {
    // ... test code ...
  });

  test('second test', () => {
    console.log('This works correctly');
  });
});
```

**Why**: Mocks and spies persist across tests unless explicitly restored, causing interference.

---

### Pitfall 7: Floating Point Comparison with toBe()

❌ **WRONG:**
```typescript
test('calculates 0.1 + 0.2', () => {
  expect(0.1 + 0.2).toBe(0.3); // FAILS! JavaScript floating point: 0.30000000000000004
});
```

✅ **CORRECT:**
```typescript
test('calculates 0.1 + 0.2', () => {
  expect(0.1 + 0.2).toBeCloseTo(0.3, 5); // Precision: 5 decimal places
});
```

**Why**: JavaScript floating point arithmetic has precision limits. Use `toBeCloseTo()` for decimal comparisons.

---

### Pitfall 8: Testing Too Many Things in One Test

❌ **WRONG:**
```typescript
test('user workflow', async () => {
  // Creates user
  const user = await createUser({ name: 'Alice' });
  expect(user.id).toBeDefined();

  // Updates user
  await updateUser(user.id, { email: 'alice@example.com' });
  const updated = await getUser(user.id);
  expect(updated.email).toBe('alice@example.com');

  // Deletes user
  await deleteUser(user.id);
  await expect(getUser(user.id)).rejects.toThrow();

  // If any step fails, you don't know which one!
});
```

✅ **CORRECT:**
```typescript
describe('User operations', () => {
  let userId: string;

  beforeEach(async () => {
    const user = await createUser({ name: 'Alice' });
    userId = user.id;
  });

  test('creates user with ID', () => {
    expect(userId).toBeDefined();
  });

  test('updates user email', async () => {
    await updateUser(userId, { email: 'alice@example.com' });
    const user = await getUser(userId);
    expect(user.email).toBe('alice@example.com');
  });

  test('deletes user', async () => {
    await deleteUser(userId);
    await expect(getUser(userId)).rejects.toThrow();
  });
});
```

**Why**: One test, one concern. When a mega-test fails, debugging is painful.

**Rule**: If your test has more than 3-4 assertions, consider splitting it.

---

### Pitfall 9: Using .only() or .skip() in Committed Code

❌ **WRONG:**
```typescript
test.only('debug this one test', () => {
  // Oops, committed with .only()
  // CI will only run this test, hiding other failures!
});

test.skip('broken test, will fix later', () => {
  // Skipped tests accumulate and are forgotten
});
```

✅ **CORRECT:**
```typescript
// Remove .only() before committing
test('properly focused test', () => {
  // All tests run in CI
});

// Fix or delete skipped tests
test('previously broken, now fixed', () => {
  // Fixed and re-enabled
});
```

**Bloom Prevention**: Our pre-commit hooks and CI fail if `.only()` or `.skip()` are detected.

---

### Pitfall 10: Not Testing Error Cases

❌ **WRONG:**
```typescript
test('divides two numbers', () => {
  expect(divide(10, 2)).toBe(5);
  expect(divide(100, 4)).toBe(25);
  // What about divide(10, 0)?
});
```

✅ **CORRECT:**
```typescript
describe('divide()', () => {
  test('divides two numbers', () => {
    expect(divide(10, 2)).toBe(5);
    expect(divide(100, 4)).toBe(25);
  });

  test('throws when dividing by zero', () => {
    expect(() => divide(10, 0)).toThrow('Cannot divide by zero');
  });

  test('handles negative numbers', () => {
    expect(divide(-10, 2)).toBe(-5);
    expect(divide(10, -2)).toBe(-5);
  });
});
```

**Why**: Error paths are often the buggiest code. Test them explicitly.

**Rule**: Every function that can throw or return an error should have error case tests.

---

## 7. AI Pair Programming Notes

<!-- Query: "How to use Jest with AI coding assistants" -->
<!-- Query: "Best practices for AI-assisted Jest testing" -->

### When to Load This File

Load `01-FUNDAMENTALS.md` when:
- Starting a new testing task
- Learning Jest for the first time
- Debugging test structure or lifecycle issues
- Setting up a new test suite
- Teaching others about Jest

### Combine With

**For Complete Jest Knowledge:**
- `QUICK-REFERENCE.md` – Syntax cheat sheet and common patterns
- `02-MATCHERS-ASSERTIONS.md` – All Jest matchers and when to use them
- `03-MOCKING-SPIES.md` – Comprehensive mocking guide

**For Specific Use Cases:**
- `04-ASYNC-TESTING.md` – Promises, async/await, timers
- `05-REACT-COMPONENT-TESTING.md` – React Testing Library integration
- `06-API-TESTING.md` – Testing Next.js API routes and endpoints
- `FRAMEWORK-INTEGRATION-PATTERNS.md` – Next.js, Prisma, TypeScript patterns

### Typical Context Bundles

**Learning Bundle:**
```
docs/kb/testing/jest/01-FUNDAMENTALS.md
docs/kb/testing/jest/QUICK-REFERENCE.md
docs/kb/testing/jest/02-MATCHERS-ASSERTIONS.md
```

**React Testing Bundle:**
```
docs/kb/testing/jest/01-FUNDAMENTALS.md
docs/kb/testing/jest/05-REACT-COMPONENT-TESTING.md
docs/kb/testing/jest/FRAMEWORK-INTEGRATION-PATTERNS.md
```

**API Testing Bundle:**
```
docs/kb/testing/jest/01-FUNDAMENTALS.md
docs/kb/testing/jest/06-API-TESTING.md
docs/kb/testing/jest/03-MOCKING-SPIES.md
```

### AI Prompt Templates

**Generate Unit Test:**
```
Load docs/kb/testing/jest/01-FUNDAMENTALS.md and docs/kb/testing/jest/QUICK-REFERENCE.md.

Generate a comprehensive unit test suite for the following code:
[paste code]

Follow these requirements:
- Use TypeScript
- Include describe/it structure
- Test happy path and edge cases
- Use beforeEach for setup
- Follow Bloom testing conventions
```

**Fix Failing Test:**
```
Load docs/kb/testing/jest/01-FUNDAMENTALS.md.

This test is failing:
[paste test code]

Error message:
[paste error]

Diagnose the issue and provide a fix. Explain what was wrong.
```

**Review Test Quality:**
```
Load docs/kb/testing/jest/01-FUNDAMENTALS.md.

Review this test suite for quality:
[paste test code]

Check for:
- Test isolation
- Proper use of lifecycle hooks
- Avoiding common pitfalls
- Clear test names
- Appropriate mocking
```

### What AI Should Avoid

**Deprecated Patterns:**
- Using `done()` callback for async tests (use async/await instead)
- Using `jest.mock()` hoisting issues (explicitly mock before imports)
- Using `.toBe()` for objects or arrays (use `.toEqual()`)
- Using `.toBe()` for floats (use `.toBeCloseTo()`)

**Bloom-Specific Avoidance:**
- Don't use `.only()` or `.skip()` in generated tests (CI will fail)
- Don't use relative imports for `@/` aliased paths
- Don't create tests in `tests/e2e/` (that's for Playwright)
- Don't use `.spec.ts` extension (Jest uses `.test.ts`)

### Common AI-Generated Test Issues

**Issue 1: Over-Complicated Setup**
AI often generates overly complex `beforeEach()` blocks. Simplify:

```typescript
// ❌ AI-generated (too complex)
beforeEach(() => {
  // 50 lines of setup for every test
});

// ✅ Simplified (only shared setup)
beforeEach(() => {
  // Only what ALL tests need
});

test('specific case', () => {
  // Test-specific setup here
});
```

**Issue 2: Missing Edge Cases**
AI tends to only test happy paths. Always add:
- Error cases
- Boundary conditions (0, -1, null, undefined, empty arrays)
- Edge inputs (very large numbers, special characters)

**Issue 3: Vague Assertions**
AI often generates weak assertions:

```typescript
// ❌ Weak
expect(result).toBeDefined();

// ✅ Specific
expect(result.totalROI).toBeGreaterThan(0);
expect(result.paybackPeriod).toBeCloseTo(18.5, 1);
```

### Bloom-Specific Jest Configuration

When generating tests, AI should be aware of our Jest config:

```javascript
// jest.config.cjs
{
  testEnvironment: 'jest-environment-jsdom', // For React components
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/$1' // Path alias support
  },
  testMatch: [
    '**/__tests__/**/*.test.[jt]s?(x)',
    '**/?(*.)+test.[jt]s?(x)'
  ],
  testPathIgnorePatterns: [
    '<rootDir>/tests/e2e/', // Playwright tests excluded
  ],
  coverageThreshold: {
    global: {
      lines: 80,
      statements: 80,
      branches: 70,
      functions: 70
    }
  }
}
```

**Implications:**
- Use `@/` imports, not relative paths
- React components can use DOM APIs
- Must hit 80% line coverage for most code
- Don't create `.spec.ts` files (they're for Playwright)

### Verification Checklist for AI-Generated Tests

Before accepting AI-generated tests, verify:

- [ ] Tests are independent (no shared mutable state)
- [ ] Async operations use async/await
- [ ] No `.only()` or `.skip()` in code
- [ ] Test names are descriptive
- [ ] Error cases are tested
- [ ] Mocks are cleaned up in `afterEach()`
- [ ] Floating point comparisons use `toBeCloseTo()`
- [ ] Objects/arrays use `toEqual()`, not `toBe()`
- [ ] Coverage meets thresholds (80% lines, 70% branches)
- [ ] Tests follow AAA pattern (Arrange-Act-Assert)

---

## Last Updated

2025-11-14

**Changelog:**
- Initial comprehensive fundamentals guide created per v3.1 playbook
- Added 3-tier example system (pedagogical, realistic, framework integration)
- Included 10 common pitfalls with ❌/✅ examples
- Added AI pair programming notes with prompt templates
- Integrated Bloom project-specific patterns and configuration
- Added query pattern comments for RAG retrieval

**Next Steps:**
- See `02-MATCHERS-ASSERTIONS.md` for complete matcher reference
- See `03-MOCKING-SPIES.md` for advanced mocking patterns
- See `QUICK-REFERENCE.md` for quick syntax lookup
- See `FRAMEWORK-INTEGRATION-PATTERNS.md` for Next.js/Prisma/TypeScript integration

**Contributing:**
If you discover new fundamental concepts, anti-patterns, or best practices, update this file and increment `last_reviewed` date.
