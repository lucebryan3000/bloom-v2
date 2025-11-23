---
id: jest-10-advanced-patterns
topic: jest
file_role: advanced
profile: full
difficulty_level: advanced
kb_version: 3.1
prerequisites: [jest-01-fundamentals, jest-03-mocking-spies]
related_topics: [testing-patterns, advanced-testing, test-architecture]
embedding_keywords: [jest, advanced-patterns, testing-strategies, test-architecture, custom-matchers, test-factories, parameterized-tests]
last_reviewed: 2025-11-14
---

# Advanced Jest Testing Patterns

**Part 10 of 11 - The Jest Knowledge Base**

<!-- Query: "How do I write custom Jest matchers?" -->
<!-- Query: "What are test factories and how do I use them?" -->
<!-- Query: "How to organize large test suites in Jest?" -->
<!-- Query: "Jest parameterized tests with test.each" -->

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

Master advanced Jest patterns for building scalable, maintainable test suites:

- **Custom Matchers**: Domain-specific assertions for better readability and reusability
- **Test Factories**: Generate test data consistently and reduce boilerplate
- **Parameterized Tests**: Run the same test with multiple inputs using `test.each`
- **Test Organization**: Structure large test suites for maintainability
- **Global Setup/Teardown**: Configure test environment once for all tests
- **Custom Reporters**: Create custom test output and CI/CD integrations
- **Coverage Configuration**: Advanced coverage strategies and thresholds

**Critical for Bloom**: Testing ROI calculations, session workflows, and complex business logic with reusable patterns.

---

## 2. Mental Model / Problem Statement

### 2.1 The Test Maintenance Problem

As test suites grow, common issues emerge:

```typescript
// ❌ PROBLEM: Repetitive, hard-to-maintain tests
describe('Session ROI calculations', () => {
  it('calculates high-confidence ROI correctly', () => {
    const session = {
      id: 'session-1',
      userId: 'user-1',
      organizationId: 'org-1',
      title: 'Test Session',
      status: 'completed',
      startedAt: new Date('2025-01-01'),
      completedAt: new Date('2025-01-01'),
      transcript: '...',
      // ... 20+ more fields
    };

    const roiReport = {
      id: 'roi-1',
      sessionId: 'session-1',
      totalValue: 150000,
      confidence: 0.92,
      // ... 15+ more fields
    };

    // ❌ Repetitive setup
    // ❌ Brittle (changes to schema break all tests)
    // ❌ Unclear intent (what's important vs boilerplate?)
    expect(roiReport.confidence).toBeGreaterThan(0.9);
    expect(roiReport.totalValue).toBeGreaterThan(100000);
  });

  it('calculates medium-confidence ROI correctly', () => {
    // ❌ Copy-paste same setup with minor changes
    const session = { /* ... same 20+ fields */ };
    const roiReport = { /* ... same 15+ fields, different values */ };
    // ...
  });
});
```

### 2.2 The Solution: Advanced Patterns

**Advanced patterns solve these problems:**

1. **Custom Matchers**: Domain-specific assertions
   ```typescript
   expect(roiReport).toHaveHighConfidence(); // Clear intent
   ```

2. **Test Factories**: Reusable data builders
   ```typescript
   const session = createTestSession({ status: 'completed' }); // Focus on what matters
   ```

3. **Parameterized Tests**: Test multiple cases efficiently
   ```typescript
   test.each([
     [0.95, 'high'],
     [0.75, 'medium'],
     [0.45, 'low'],
   ])('confidence %f should be classified as %s', (score, level) => {
     // Test runs 3 times with different inputs
   });
   ```

4. **Test Organization**: Logical grouping and shared context
   ```typescript
   describe('ROI Calculator', () => {
     describe('with complete data', () => { /* ... */ });
     describe('with missing fields', () => { /* ... */ });
   });
   ```

---

## 3. Golden Path

### 3.1 Custom Matchers (Domain-Specific Assertions)

**Create reusable matchers for domain concepts:**

```typescript
// tests/helpers/custom-matchers.ts
import { expect } from '@jest/globals';
import type { MatcherFunction } from 'expect';

// Custom matcher for ROI confidence levels
const toHaveHighConfidence: MatcherFunction<[threshold?: number]> =
  function (actual, threshold = 0.8) {
    const roiReport = actual as { confidence: number };

    if (typeof roiReport.confidence !== 'number') {
      return {
        pass: false,
        message: () => 'Expected ROI report to have a confidence score',
      };
    }

    const pass = roiReport.confidence >= threshold;

    return {
      pass,
      message: () =>
        pass
          ? `Expected confidence ${roiReport.confidence} to be below ${threshold}`
          : `Expected confidence ${roiReport.confidence} to be at least ${threshold}`,
    };
  };

// Custom matcher for valid session states
const toBeValidSession: MatcherFunction = function (actual) {
  const session = actual as any;
  const validStatuses = ['active', 'completed', 'abandoned'];

  const errors: string[] = [];

  if (!session.id) errors.push('Missing session ID');
  if (!validStatuses.includes(session.status)) {
    errors.push(`Invalid status: ${session.status}`);
  }
  if (session.status === 'completed' && !session.completedAt) {
    errors.push('Completed session missing completedAt timestamp');
  }

  const pass = errors.length === 0;

  return {
    pass,
    message: () =>
      pass
        ? 'Expected session to be invalid'
        : `Session validation failed:\n${errors.join('\n')}`,
  };
};

// Register custom matchers
expect.extend({
  toHaveHighConfidence,
  toBeValidSession,
});

// TypeScript type definitions
declare module 'expect' {
  interface Matchers<R> {
    toHaveHighConfidence(threshold?: number): R;
    toBeValidSession(): R;
  }
}
```

**Usage:**
```typescript
import './helpers/custom-matchers';

it('generates high-confidence ROI report', () => {
  const report = generateROIReport(sessionData);

  expect(report).toHaveHighConfidence(); // Clean, readable
  expect(report).toHaveHighConfidence(0.9); // Custom threshold
});

it('creates valid session', () => {
  const session = createSession({ title: 'New Workshop' });

  expect(session).toBeValidSession(); // All validation in one assertion
});
```

### 3.2 Test Factories (Builder Pattern)

**Create factory functions for test data:**

```typescript
// tests/factories/session-factory.ts
import { Session, User, Organization } from '@prisma/client';

type DeepPartial<T> = {
  [P in keyof T]?: T[P] extends object ? DeepPartial<T[P]> : T[P];
};

// Base factory with sensible defaults
export function createTestSession(
  overrides: DeepPartial<Session> = {}
): Session {
  const baseSession: Session = {
    id: `session-${Date.now()}`,
    userId: 'user-default',
    organizationId: 'org-default',
    title: 'Test Session',
    status: 'active',
    startedAt: new Date('2025-01-01T10:00:00Z'),
    completedAt: null,
    transcript: null,
    metadata: null,
    customerName: 'Acme Corp',
    customerIndustry: 'Technology',
    customerSize: '50-200',
    facilitatorName: 'Jane Doe',
    attendees: JSON.stringify([
      { name: 'John Smith', role: 'CTO' },
    ]),
    focusArea: null,
    contextComplete: true,
    currentPhase: 1,
    totalPhases: 5,
    progress: 0.2,
    estimatedTimeRemaining: 12,
    lastMessageAt: new Date('2025-01-01T10:05:00Z'),
    createdAt: new Date('2025-01-01T10:00:00Z'),
    updatedAt: new Date('2025-01-01T10:05:00Z'),
  };

  return {
    ...baseSession,
    ...overrides,
  };
}

// Specialized factory methods
export function createCompletedSession(
  overrides: DeepPartial<Session> = {}
): Session {
  return createTestSession({
    status: 'completed',
    completedAt: new Date('2025-01-01T10:15:00Z'),
    progress: 1.0,
    estimatedTimeRemaining: 0,
    ...overrides,
  });
}

export function createAbandonedSession(
  overrides: DeepPartial<Session> = {}
): Session {
  return createTestSession({
    status: 'abandoned',
    completedAt: null,
    progress: 0.6,
    ...overrides,
  });
}

// Builder pattern for complex scenarios
export class SessionBuilder {
  private session: DeepPartial<Session> = {};

  withUser(userId: string): this {
    this.session.userId = userId;
    return this;
  }

  withOrganization(orgId: string): this {
    this.session.organizationId = orgId;
    return this;
  }

  withTitle(title: string): this {
    this.session.title = title;
    return this;
  }

  completed(): this {
    this.session.status = 'completed';
    this.session.completedAt = new Date();
    this.session.progress = 1.0;
    return this;
  }

  withCustomer(name: string, industry: string): this {
    this.session.customerName = name;
    this.session.customerIndustry = industry;
    return this;
  }

  build(): Session {
    return createTestSession(this.session);
  }
}

// ROI Report Factory
export function createTestROIReport(overrides = {}) {
  return {
    id: `roi-${Date.now()}`,
    sessionId: 'session-default',
    totalValue: 150000,
    confidence: 0.85,
    npv: 120000,
    irr: 0.45,
    paybackPeriod: 18,
    assumptions: JSON.stringify({
      laborCostPerHour: 75,
      hoursImpacted: 2000,
      implementationCost: 50000,
    }),
    metrics: JSON.stringify({
      efficiency_gain: 0.3,
      time_saved_hours: 600,
    }),
    createdAt: new Date(),
    updatedAt: new Date(),
    ...overrides,
  };
}
```

**Usage:**
```typescript
import { createTestSession, createCompletedSession, SessionBuilder } from './factories/session-factory';

describe('Session workflow', () => {
  it('processes completed sessions', () => {
    // Simple factory
    const session = createCompletedSession();
    expect(session.status).toBe('completed');
  });

  it('handles multi-user sessions', () => {
    // Builder pattern for complex setup
    const session = new SessionBuilder()
      .withTitle('Enterprise Workshop')
      .withOrganization('org-enterprise')
      .withCustomer('Big Corp', 'Finance')
      .completed()
      .build();

    expect(session.customerName).toBe('Big Corp');
  });

  it('creates default session quickly', () => {
    // Minimal override
    const session = createTestSession({ title: 'Quick Test' });
    expect(session).toBeValidSession();
  });
});
```

### 3.3 Parameterized Tests (test.each / describe.each)

**Test multiple scenarios with same logic:**

```typescript
// Array of arrays syntax
describe('ROI confidence classification', () => {
  test.each([
    [0.95, 'high'],
    [0.85, 'high'],
    [0.80, 'high'],
    [0.75, 'medium'],
    [0.60, 'medium'],
    [0.50, 'medium'],
    [0.45, 'low'],
    [0.30, 'low'],
    [0.10, 'low'],
  ])('confidence score %f should classify as %s', (score, expectedLevel) => {
    const level = classifyConfidence(score);
    expect(level).toBe(expectedLevel);
  });
});

// Table syntax (more readable)
describe('ROI calculation scenarios', () => {
  test.each`
    totalValue | implementationCost | expectedNPV | description
    ${200000}  | ${50000}          | ${150000}   | ${'high-value project'}
    ${100000}  | ${80000}          | ${20000}    | ${'marginal ROI'}
    ${50000}   | ${60000}          | ${-10000}   | ${'negative ROI'}
  `('$description: calculates NPV correctly', ({ totalValue, implementationCost, expectedNPV }) => {
    const npv = calculateNPV(totalValue, implementationCost);
    expect(npv).toBe(expectedNPV);
  });
});

// Parameterized describe blocks
describe.each([
  ['active', false],
  ['completed', true],
  ['abandoned', false],
])('Session with status %s', (status, shouldHaveReport) => {
  let session: Session;

  beforeEach(() => {
    session = createTestSession({ status });
  });

  it(`${shouldHaveReport ? 'should' : 'should not'} have ROI report`, () => {
    const hasReport = canGenerateROIReport(session);
    expect(hasReport).toBe(shouldHaveReport);
  });
});
```

### 3.4 Test Organization Patterns

**Structure for large test suites:**

```typescript
// tests/lib/roi/calculator.test.ts
describe('ROI Calculator', () => {
  // Shared context at top level
  let calculator: ROICalculator;

  beforeEach(() => {
    calculator = new ROICalculator();
  });

  // Logical grouping by feature/scenario
  describe('NPV calculation', () => {
    describe('with complete data', () => {
      it('calculates positive NPV', () => { /* ... */ });
      it('calculates negative NPV', () => { /* ... */ });
    });

    describe('with missing data', () => {
      it('throws error for missing total value', () => { /* ... */ });
      it('uses default discount rate', () => { /* ... */ });
    });
  });

  describe('IRR calculation', () => {
    describe('for profitable projects', () => {
      it('finds IRR above discount rate', () => { /* ... */ });
    });

    describe('for unprofitable projects', () => {
      it('returns null for negative cash flows', () => { /* ... */ });
    });
  });

  describe('confidence scoring', () => {
    // Nested context
    describe('with high-quality inputs', () => {
      beforeEach(() => {
        // Setup specific to high-quality tests
      });

      it('assigns high confidence', () => { /* ... */ });
    });

    describe('with incomplete inputs', () => {
      it('reduces confidence score', () => { /* ... */ });
    });
  });
});
```

### 3.5 Global Setup and Teardown

**Configure test environment once:**

```typescript
// tests/setup/global-setup.ts
import { PrismaClient } from '@prisma/client';

export default async function globalSetup() {
  console.log('🔧 Global test setup...');

  // Initialize test database
  const prisma = new PrismaClient({
    datasourceUrl: process.env.TEST_DATABASE_URL,
  });

  // Run migrations
  await prisma.$executeRawUnsafe('PRAGMA journal_mode=WAL');

  // Seed reference data (if needed)
  await prisma.organization.create({
    data: {
      id: 'org-test-default',
      name: 'Test Organization',
      industry: 'Technology',
    },
  });

  await prisma.$disconnect();

  console.log('✅ Global setup complete');
}
```

```typescript
// tests/setup/global-teardown.ts
export default async function globalTeardown() {
  console.log('🧹 Global test teardown...');

  // Cleanup resources
  // Close connections
  // Remove temp files

  console.log('✅ Global teardown complete');
}
```

```javascript
// jest.config.js
module.exports = {
  globalSetup: '<rootDir>/tests/setup/global-setup.ts',
  globalTeardown: '<rootDir>/tests/setup/global-teardown.ts',
  setupFilesAfterEnv: ['<rootDir>/tests/setup/jest-setup.ts'],
};
```

```typescript
// tests/setup/jest-setup.ts (runs before each test file)
import '@testing-library/jest-dom';
import './helpers/custom-matchers';

// Increase timeout for integration tests
jest.setTimeout(10000);

// Mock environment variables
process.env.NODE_ENV = 'test';
process.env.DATABASE_URL = 'file:./test.db';
```

---

## 4. Variations & Trade-Offs

### 4.1 Factory Patterns

| Pattern | Best For | Trade-Off |
|---------|----------|-----------|
| **Simple Factory Function** | Quick test data, minimal variation | Less flexible, can become bloated |
| **Builder Pattern** | Complex objects, fluent API | More code, overkill for simple cases |
| **Trait-Based Factories** | Reusable combinations | Learning curve, indirection |

### 4.2 Parameterized Test Approaches

| Approach | Pros | Cons |
|----------|------|------|
| **test.each(array)** | Simple, minimal syntax | Harder to read complex data |
| **test.each`table`** | Readable, self-documenting | Verbose for simple cases |
| **describe.each** | Group related scenarios | Adds nesting complexity |

### 4.3 Custom Matchers vs Helpers

```typescript
// Custom Matcher (better for reusability)
expect(report).toHaveHighConfidence();

// Helper Function (better for complex logic)
assertValidROIReport(report, { minConfidence: 0.8 });
```

**When to use custom matchers:**
- Common assertions across test files
- Better error messages needed
- Domain-specific concepts

**When to use helper functions:**
- Complex validation logic
- Need to return values
- Testing setup/teardown

---

## 5. Examples

### 5.1 Complete Test Suite with All Patterns

```typescript
// tests/lib/melissa/workshop.test.ts
import { createTestSession, SessionBuilder } from '../factories/session-factory';
import '../helpers/custom-matchers';
import { WorkshopFacilitator } from '@/lib/melissa/workshop';

describe('WorkshopFacilitator', () => {
  let facilitator: WorkshopFacilitator;

  beforeEach(() => {
    facilitator = new WorkshopFacilitator();
  });

  describe('session progression', () => {
    // Parameterized test for phase transitions
    test.each`
      currentPhase | action           | expectedPhase | shouldSucceed
      ${1}         | ${'advance'}     | ${2}          | ${true}
      ${2}         | ${'advance'}     | ${3}          | ${true}
      ${5}         | ${'advance'}     | ${5}          | ${false}
      ${3}         | ${'retreat'}     | ${2}          | ${true}
      ${1}         | ${'retreat'}     | ${1}          | ${false}
    `(
      'phase $currentPhase -> $action -> phase $expectedPhase (success: $shouldSucceed)',
      ({ currentPhase, action, expectedPhase, shouldSucceed }) => {
        const session = createTestSession({ currentPhase });

        const result = action === 'advance'
          ? facilitator.advancePhase(session)
          : facilitator.retreatPhase(session);

        if (shouldSucceed) {
          expect(result.phase).toBe(expectedPhase);
        } else {
          expect(result.error).toBeDefined();
        }
      }
    );
  });

  describe('ROI data extraction', () => {
    it('extracts complete ROI data from transcript', () => {
      // Using builder pattern for complex setup
      const session = new SessionBuilder()
        .withTitle('Manufacturing Efficiency Workshop')
        .withCustomer('Acme Manufacturing', 'Manufacturing')
        .completed()
        .build();

      session.transcript = JSON.stringify([
        { role: 'user', content: 'We process 500 orders per day' },
        { role: 'assistant', content: 'What is the average processing time?' },
        { role: 'user', content: 'About 15 minutes per order' },
      ]);

      const roiData = facilitator.extractROIData(session);

      // Custom matcher
      expect(roiData).toHaveHighConfidence(0.7);

      // Standard assertions
      expect(roiData.metrics).toHaveProperty('orders_per_day', 500);
      expect(roiData.metrics).toHaveProperty('processing_time_minutes', 15);
    });
  });
});
```

### 5.2 Advanced Custom Reporter

```typescript
// tests/reporters/bloom-reporter.ts
import type { Reporter, Test, TestResult } from '@jest/reporters';

class BloomTestReporter implements Reporter {
  private startTime: number = 0;

  onRunStart() {
    this.startTime = Date.now();
    console.log('🌸 Bloom Test Suite Started');
  }

  onTestResult(_test: Test, testResult: TestResult) {
    const { numPassingTests, numFailingTests, testFilePath } = testResult;

    if (numFailingTests > 0) {
      console.log(`❌ ${testFilePath}: ${numFailingTests} failed`);
    } else {
      console.log(`✅ ${testFilePath}: ${numPassingTests} passed`);
    }
  }

  onRunComplete() {
    const duration = Date.now() - this.startTime;
    console.log(`\n🌸 Bloom Test Suite Complete in ${duration}ms`);
  }
}

export default BloomTestReporter;
```

```javascript
// jest.config.js
module.exports = {
  reporters: [
    'default',
    '<rootDir>/tests/reporters/bloom-reporter.ts',
  ],
};
```

---

## 6. Common Pitfalls

### ❌ Pitfall 1: Over-Abstracting Factories

```typescript
// ❌ TOO ABSTRACT: Hard to understand what's being created
const session = createEntity('session')
  .with('completed')
  .and('highROI')
  .generate();

// ✅ BETTER: Clear, explicit
const session = createCompletedSession({
  roiReport: createTestROIReport({ totalValue: 200000 })
});
```

### ❌ Pitfall 2: Parameterized Tests Without Context

```typescript
// ❌ BAD: What do these numbers mean?
test.each([
  [0.8, true],
  [0.6, false],
])('test %f returns %s', (a, b) => {
  expect(check(a)).toBe(b);
});

// ✅ GOOD: Clear parameter names and descriptions
test.each`
  confidence | shouldGenerate | reason
  ${0.8}     | ${true}        | ${'high confidence triggers generation'}
  ${0.6}     | ${false}       | ${'medium confidence requires review'}
`('$reason', ({ confidence, shouldGenerate }) => {
  const result = shouldAutoGenerateReport(confidence);
  expect(result).toBe(shouldGenerate);
});
```

### ❌ Pitfall 3: Custom Matchers That Do Too Much

```typescript
// ❌ BAD: Matcher has side effects
expect(session).toSaveAndValidate(); // Saves to DB?!

// ✅ GOOD: Matchers only assert
expect(session).toBeValidSession();
saveSession(session); // Separate action
```

### ❌ Pitfall 4: Shared State in Factories

```typescript
// ❌ BAD: Shared counter can cause test order issues
let sessionCounter = 0;
function createSession() {
  return { id: `session-${sessionCounter++}` }; // ⚠️ Shared state
}

// ✅ GOOD: Use timestamps or unique IDs
function createSession() {
  return { id: `session-${Date.now()}-${Math.random()}` };
}
```

---

## 7. AI Pair Programming Notes

**When working with AI on advanced Jest patterns:**

- **For Custom Matchers**: "Create a custom Jest matcher for validating ROI reports with confidence thresholds"
- **For Factories**: "Generate a test factory for Session objects with builder pattern support"
- **For Parameterized Tests**: "Convert these 5 similar tests into a parameterized test.each"
- **For Organization**: "Suggest a better test organization structure for this 500-line test file"

**AI Strengths:**
- Generating boilerplate factory code
- Converting repetitive tests to parameterized versions
- Suggesting custom matcher implementations
- Identifying test organization patterns

**AI Limitations:**
- May over-abstract (review for simplicity)
- Might not understand domain-specific validation rules
- Can create overly complex factories (prefer simple)

**Best Practice**: Ask AI to explain trade-offs between different patterns for your specific use case.

---

## Last Updated

2025-11-14
