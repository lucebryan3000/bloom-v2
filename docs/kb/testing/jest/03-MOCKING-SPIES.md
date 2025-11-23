---
id: jest-03-mocking-spies
topic: jest
file_role: core
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [jest-01-fundamentals, jest-02-matchers-assertions]
related_topics: [testing, mocking, test-doubles]
embedding_keywords: [jest, mocking, spies, stubs, test-doubles, jest.fn, jest.mock]
last_reviewed: 2025-11-14
---

# Jest Mocking & Spies

**Part 3 of 11 - The Jest Knowledge Base**

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

Master Jest's mocking capabilities to isolate code under test, control external dependencies, and verify interactions. Mocking is essential for:

- **Isolation**: Test units in isolation without real database, API, or file system
- **Control**: Deterministic test results by controlling dependency behavior
- **Speed**: Fast tests by replacing slow operations (database queries, network calls)
- **Verification**: Assert that functions were called with correct arguments
- **Simulation**: Test error conditions and edge cases that are hard to trigger with real dependencies

**Critical for Bloom**: Mocking Prisma database calls, Next.js modules, Anthropic AI API, and external services.

---

## 2. Mental Model / Problem Statement

### The Test Isolation Problem

Real dependencies create problems in tests:

```typescript
// ❌ PROBLEM: Testing with real dependencies
async function getUserEmail(userId: string): Promise<string> {
  const user = await prisma.user.findUnique({ where: { id: userId } });
  return user?.email || '';
}

// This test has problems:
it('should return user email', async () => {
  // ❌ Requires real database connection
  // ❌ Requires database to be seeded with specific user
  // ❌ Slow (database round-trip)
  // ❌ Brittle (fails if database is down)
  // ❌ Not isolated (other tests can affect this one)
  const email = await getUserEmail('user-123');
  expect(email).toBe('test@example.com');
});
```

### The Solution: Test Doubles

**Test doubles** replace real dependencies with controlled substitutes:

```typescript
// ✅ SOLUTION: Mock the database dependency
import { prisma } from '@/lib/prisma';

jest.mock('@/lib/prisma', () => ({
  prisma: {
    user: {
      findUnique: jest.fn(),
    },
  },
}));

it('should return user email', async () => {
  // ✅ Fast (no database)
  // ✅ Isolated (no external dependencies)
  // ✅ Deterministic (controlled data)
  // ✅ Verifiable (can assert mock was called)

  (prisma.user.findUnique as jest.Mock).mockResolvedValue({
    id: 'user-123',
    email: 'test@example.com',
  });

  const email = await getUserEmail('user-123');

  expect(email).toBe('test@example.com');
  expect(prisma.user.findUnique).toHaveBeenCalledWith({
    where: { id: 'user-123' },
  });
});
```

### Types of Test Doubles

1. **Mock**: Full replacement with behavior verification
   ```typescript
   const mockFn = jest.fn().mockReturnValue(42);
   mockFn(1, 2, 3);
   expect(mockFn).toHaveBeenCalledWith(1, 2, 3); // Verifies interaction
   ```

2. **Spy**: Wraps real function to observe calls while preserving behavior
   ```typescript
   const spy = jest.spyOn(console, 'log').mockImplementation();
   console.log('test');
   expect(spy).toHaveBeenCalledWith('test');
   spy.mockRestore(); // Restore original
   ```

3. **Stub**: Returns predetermined values (subset of mock functionality)
   ```typescript
   const stub = jest.fn().mockReturnValue('fixed-response');
   ```

4. **Fake**: Working implementation with shortcuts (e.g., in-memory database)
   ```typescript
   const fakeDb = {
     users: new Map(),
     findUser: (id: string) => fakeDb.users.get(id),
   };
   ```

### Mental Model: The Three Questions

Ask these when deciding what to mock:

1. **Is it an external dependency?** (database, API, file system) → **Mock it**
2. **Is it slow?** (>100ms) → **Mock it**
3. **Is it non-deterministic?** (random, dates, network) → **Mock it**
4. **Is it the code under test?** → **Don't mock it** (test real implementation)

---

## 3. Golden Path

### Recommended Mocking Workflow for Bloom

#### Step 1: Identify Dependencies to Mock

```typescript
// Function under test with dependencies
import { prisma } from '@/lib/prisma';
import { generateText } from 'ai';
import { sendEmail } from '@/lib/email';

export async function createUserAndNotify(
  email: string,
  name: string
): Promise<User> {
  // Dependency 1: Database (Prisma)
  const user = await prisma.user.create({
    data: { email, name },
  });

  // Dependency 2: AI (Vercel AI SDK)
  const welcome = await generateText({
    model: anthropic('claude-sonnet-4'),
    prompt: `Generate welcome message for ${name}`,
  });

  // Dependency 3: External service (Email)
  await sendEmail({
    to: email,
    subject: 'Welcome!',
    body: welcome.text,
  });

  return user;
}
```

**Dependencies to mock:**
- ✅ `prisma` - External database
- ✅ `generateText` - External AI API (slow, costs money)
- ✅ `sendEmail` - External email service

#### Step 2: Set Up Mocks Before Imports

```typescript
// ✅ CRITICAL: Mock modules BEFORE importing code under test

// Mock Prisma
jest.mock('@/lib/prisma', () => ({
  prisma: {
    user: {
      create: jest.fn(),
    },
  },
}));

// Mock AI SDK
jest.mock('ai', () => ({
  generateText: jest.fn(),
}));

// Mock email service
jest.mock('@/lib/email', () => ({
  sendEmail: jest.fn(),
}));

// NOW import code under test
import { createUserAndNotify } from '@/lib/users';
import { prisma } from '@/lib/prisma';
import { generateText } from 'ai';
import { sendEmail } from '@/lib/email';
```

#### Step 3: Configure Mock Behavior

```typescript
describe('createUserAndNotify', () => {
  beforeEach(() => {
    // Reset mocks before each test
    jest.clearAllMocks();
  });

  it('should create user and send welcome email', async () => {
    // Arrange: Configure mock return values
    (prisma.user.create as jest.Mock).mockResolvedValue({
      id: 'user-123',
      email: 'test@example.com',
      name: 'Test User',
    });

    (generateText as jest.Mock).mockResolvedValue({
      text: 'Welcome, Test User!',
      usage: { promptTokens: 50, completionTokens: 10 },
    });

    (sendEmail as jest.Mock).mockResolvedValue(undefined);

    // Act: Call function under test
    const user = await createUserAndNotify('test@example.com', 'Test User');

    // Assert: Verify return value
    expect(user).toMatchObject({
      id: 'user-123',
      email: 'test@example.com',
      name: 'Test User',
    });

    // Assert: Verify interactions
    expect(prisma.user.create).toHaveBeenCalledWith({
      data: { email: 'test@example.com', name: 'Test User' },
    });

    expect(generateText).toHaveBeenCalledWith(
      expect.objectContaining({
        prompt: expect.stringContaining('Test User'),
      })
    );

    expect(sendEmail).toHaveBeenCalledWith({
      to: 'test@example.com',
      subject: 'Welcome!',
      body: 'Welcome, Test User!',
    });
  });
});
```

#### Step 4: Clean Up After Tests

```typescript
describe('createUserAndNotify', () => {
  beforeEach(() => {
    jest.clearAllMocks(); // Clear call history and mock state
  });

  afterEach(() => {
    jest.restoreAllMocks(); // Restore spies (if using jest.spyOn)
  });

  afterAll(() => {
    jest.resetModules(); // Clear module cache (if needed)
  });
});
```

### Mock Cleanup Commands

```typescript
// Clear mock call history and results (keeps mock implementations)
jest.clearAllMocks();
mockFn.mockClear();

// Reset mock to initial state (removes implementations, resets call history)
jest.resetAllMocks();
mockFn.mockReset();

// Restore original implementation (for spies)
jest.restoreAllMocks();
mockFn.mockRestore();

// Clear module cache (forces re-evaluation of modules)
jest.resetModules();
```

**Golden Path Recommendation:**
- Use `jest.clearAllMocks()` in `beforeEach` for most tests
- Use `jest.restoreAllMocks()` in `afterEach` when using spies
- Use `jest.resetModules()` sparingly (only when testing module initialization)

---

## 4. Variations & Trade-Offs

### 4.1 jest.fn() vs jest.spyOn()

#### jest.fn() - Create a Mock Function

**When to use:** Creating new mock functions, replacing entire modules

```typescript
// Create standalone mock
const mockCallback = jest.fn((x) => x + 1);
mockCallback(1); // Returns 2

// Replace module function
jest.mock('@/lib/utils', () => ({
  calculateTax: jest.fn(),
}));
```

**Pros:**
- Complete control over behavior
- No original implementation to worry about
- Can define behavior before function exists

**Cons:**
- Doesn't preserve original function
- Must manually define all behavior
- Can't easily toggle between real/mock

#### jest.spyOn() - Spy on Existing Function

**When to use:** Observing calls while preserving original behavior, partial mocking

```typescript
// Spy on existing function
const consoleSpy = jest.spyOn(console, 'log').mockImplementation();
console.log('test');
expect(consoleSpy).toHaveBeenCalled();
consoleSpy.mockRestore();

// Spy but keep original behavior
const mathSpy = jest.spyOn(Math, 'random');
Math.random(); // Returns real random number
expect(mathSpy).toHaveBeenCalled();
mathSpy.mockRestore();
```

**Pros:**
- Can preserve original behavior
- Easy to restore original
- Good for partial mocking

**Cons:**
- Requires object/method to exist
- Must remember to restore
- Can't spy on module exports directly (need default export object)

**Trade-off Decision Matrix:**

| Scenario | Use | Reason |
|----------|-----|--------|
| Mock entire module | `jest.fn()` | Complete replacement needed |
| Mock Prisma client | `jest.fn()` | No original to preserve |
| Mock external API | `jest.fn()` | Prevent real network calls |
| Observe console output | `jest.spyOn()` | May want to see logs during debugging |
| Test if function called | Either | Both support call assertions |
| Partial class mock | `jest.spyOn()` | Keep some real methods |

### 4.2 Module Mocking Strategies

#### Strategy 1: Full Module Mock (Most Common for Bloom)

```typescript
// Mock entire module with custom implementation
jest.mock('@/lib/prisma', () => ({
  prisma: {
    user: {
      create: jest.fn(),
      findUnique: jest.fn(),
      update: jest.fn(),
    },
  },
}));
```

**Use when:**
- Mocking external dependencies (Prisma, AI SDK, email)
- Need complete control
- Don't want any real behavior

#### Strategy 2: Partial Module Mock

```typescript
// Keep some real exports, mock others
jest.mock('@/lib/utils', () => ({
  ...jest.requireActual('@/lib/utils'),
  expensiveCalculation: jest.fn(() => 42), // Mock this
  // Other exports use real implementation
}));
```

**Use when:**
- Module has mix of pure and impure functions
- Want to mock slow functions but keep fast helpers
- Testing integration between mocked and real code

#### Strategy 3: Manual Mock (Advanced)

```typescript
// Create __mocks__/@/lib/prisma.ts
export const prisma = {
  user: {
    create: jest.fn(),
    findUnique: jest.fn(),
  },
};

// In test file
jest.mock('@/lib/prisma'); // Automatically uses __mocks__ version
```

**Use when:**
- Same mock used across many test files
- Complex mock setup
- Want to version control mock implementation

#### Strategy 4: Conditional Mock (Testing)

```typescript
// Use environment variable to toggle mocking
const isProd = process.env.NODE_ENV === 'production';

if (!isProd) {
  jest.mock('@/lib/analytics', () => ({
    trackEvent: jest.fn(),
  }));
}
```

**Use when:**
- Different behavior in test vs. production
- Integration tests that need real implementations

### 4.3 Mock Implementation Patterns

#### Pattern 1: mockReturnValue (Synchronous)

```typescript
const mockFn = jest.fn().mockReturnValue(42);
mockFn(); // Returns 42
mockFn(); // Returns 42 (always same value)
```

#### Pattern 2: mockResolvedValue (Async Success)

```typescript
const mockFn = jest.fn().mockResolvedValue({ id: '123' });
await mockFn(); // Returns Promise<{ id: '123' }>
```

**✅ Use for Bloom:** Mocking successful Prisma queries, AI responses

```typescript
(prisma.user.findUnique as jest.Mock).mockResolvedValue({
  id: 'user-123',
  email: 'test@example.com',
});
```

#### Pattern 3: mockRejectedValue (Async Failure)

```typescript
const mockFn = jest.fn().mockRejectedValue(new Error('Database error'));
await mockFn(); // Throws Error
```

**✅ Use for Bloom:** Testing error handling

```typescript
(generateText as jest.Mock).mockRejectedValue(
  new Error('Anthropic API rate limit')
);
```

#### Pattern 4: mockImplementation (Custom Logic)

```typescript
const mockFn = jest.fn().mockImplementation((a, b) => a + b);
mockFn(2, 3); // Returns 5
```

**✅ Use for Bloom:** Mocking complex logic, conditional behavior

```typescript
(prisma.user.findUnique as jest.Mock).mockImplementation(({ where }) => {
  if (where.id === 'user-123') {
    return Promise.resolve({ id: 'user-123', email: 'test@example.com' });
  }
  return Promise.resolve(null);
});
```

#### Pattern 5: Multiple Return Values

```typescript
const mockFn = jest
  .fn()
  .mockReturnValueOnce('first')
  .mockReturnValueOnce('second')
  .mockReturnValue('default');

mockFn(); // 'first'
mockFn(); // 'second'
mockFn(); // 'default'
mockFn(); // 'default'
```

**✅ Use for Bloom:** Testing retry logic, pagination

```typescript
(generateText as jest.Mock)
  .mockRejectedValueOnce(new Error('Timeout'))
  .mockResolvedValueOnce({ text: 'Success after retry' });
```

---

## 5. Examples

### Example 1 – Pedagogical: Basic Mock Function

```typescript
// Basic mock function creation and assertions
describe('Mock Function Basics', () => {
  it('should track calls and arguments', () => {
    // Create mock
    const mockCallback = jest.fn((x) => x * 2);

    // Use mock
    const result1 = mockCallback(5);
    const result2 = mockCallback(10);

    // Assert return values
    expect(result1).toBe(10);
    expect(result2).toBe(20);

    // Assert call count
    expect(mockCallback).toHaveBeenCalledTimes(2);

    // Assert specific calls
    expect(mockCallback).toHaveBeenNthCalledWith(1, 5);
    expect(mockCallback).toHaveBeenNthCalledWith(2, 10);

    // Assert last call
    expect(mockCallback).toHaveBeenLastCalledWith(10);

    // Inspect mock state
    expect(mockCallback.mock.calls).toEqual([[5], [10]]);
    expect(mockCallback.mock.results).toEqual([
      { type: 'return', value: 10 },
      { type: 'return', value: 20 },
    ]);
  });

  it('should support different return values', () => {
    const mock = jest
      .fn()
      .mockReturnValueOnce('first')
      .mockReturnValueOnce('second')
      .mockReturnValue('default');

    expect(mock()).toBe('first');
    expect(mock()).toBe('second');
    expect(mock()).toBe('default');
    expect(mock()).toBe('default');
  });

  it('should support custom implementations', () => {
    const mock = jest.fn((a, b) => a + b);

    expect(mock(1, 2)).toBe(3);
    expect(mock(5, 10)).toBe(15);
    expect(mock).toHaveBeenCalledTimes(2);
  });
});
```

### Example 2 – Realistic: Mocking Prisma Database

```typescript
// Mock Prisma client
jest.mock('@/lib/prisma', () => ({
  prisma: {
    session: {
      create: jest.fn(),
      findUnique: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
    },
  },
}));

import { prisma } from '@/lib/prisma';
import { createSession, getSession, completeSession } from '@/lib/sessions';

describe('Session Service with Prisma Mocks', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('createSession', () => {
    it('should create session with valid data', async () => {
      const mockSession = {
        id: 'session-123',
        userId: 'user-123',
        organizationId: 'org-123',
        status: 'active',
        startedAt: new Date(),
        metadata: {},
      };

      (prisma.session.create as jest.Mock).mockResolvedValue(mockSession);

      const result = await createSession({
        userId: 'user-123',
        organizationId: 'org-123',
      });

      expect(result).toEqual(mockSession);
      expect(prisma.session.create).toHaveBeenCalledWith({
        data: {
          userId: 'user-123',
          organizationId: 'org-123',
          status: 'active',
        },
      });
    });

    it('should handle database errors', async () => {
      (prisma.session.create as jest.Mock).mockRejectedValue(
        new Error('Database connection failed')
      );

      await expect(
        createSession({
          userId: 'user-123',
          organizationId: 'org-123',
        })
      ).rejects.toThrow('Database connection failed');
    });
  });

  describe('getSession', () => {
    it('should return session if found', async () => {
      const mockSession = {
        id: 'session-123',
        userId: 'user-123',
        status: 'active',
      };

      (prisma.session.findUnique as jest.Mock).mockResolvedValue(mockSession);

      const result = await getSession('session-123');

      expect(result).toEqual(mockSession);
      expect(prisma.session.findUnique).toHaveBeenCalledWith({
        where: { id: 'session-123' },
      });
    });

    it('should return null if not found', async () => {
      (prisma.session.findUnique as jest.Mock).mockResolvedValue(null);

      const result = await getSession('nonexistent');

      expect(result).toBeNull();
    });
  });

  describe('completeSession', () => {
    it('should update session status to completed', async () => {
      const mockUpdated = {
        id: 'session-123',
        status: 'completed',
        completedAt: new Date(),
      };

      (prisma.session.update as jest.Mock).mockResolvedValue(mockUpdated);

      const result = await completeSession('session-123');

      expect(result.status).toBe('completed');
      expect(prisma.session.update).toHaveBeenCalledWith({
        where: { id: 'session-123' },
        data: { status: 'completed', completedAt: expect.any(Date) },
      });
    });
  });
});
```

### Example 3 – Bloom Integration: Mocking AI SDK (Vercel AI + Anthropic)

```typescript
// Mock Vercel AI SDK
jest.mock('ai', () => ({
  generateText: jest.fn(),
}));

import { generateText } from 'ai';
import { LLMService } from '@/lib/services/LLMService';

describe('LLMService with AI SDK Mocks', () => {
  let service: LLMService;

  beforeEach(() => {
    service = new LLMService();
    jest.clearAllMocks();
  });

  describe('generateQuestion', () => {
    it('should generate question with 4 options', async () => {
      // Mock successful AI response
      const mockResponse = {
        text: JSON.stringify({
          question: 'What is your primary business goal?',
          options: [
            'Increase revenue',
            'Reduce costs',
            'Improve efficiency',
            'Expand market share',
          ],
          recommended: 'Increase revenue',
          rationale: 'Most common goal for businesses',
          confidence: 0.85,
        }),
        usage: {
          promptTokens: 500,
          completionTokens: 100,
        },
      };

      (generateText as jest.Mock).mockResolvedValue(mockResponse);

      const question = await service.generateQuestion({
        playbookId: 'playbook-123',
        stepIdx: 0,
      });

      expect(question).toMatchObject({
        question: 'What is your primary business goal?',
        options: expect.arrayContaining([
          'Increase revenue',
          'Reduce costs',
        ]),
      });

      // Verify AI was called correctly
      expect(generateText).toHaveBeenCalledWith(
        expect.objectContaining({
          model: expect.anything(),
          prompt: expect.stringContaining('playbook-123'),
        })
      );
    });

    it('should handle AI API rate limiting', async () => {
      // Mock rate limit error
      (generateText as jest.Mock).mockRejectedValue(
        new Error('Rate limit exceeded')
      );

      // Should fall back to default question
      const question = await service.generateQuestion({
        playbookId: 'playbook-123',
        stepIdx: 0,
      });

      expect(question.context?.error).toContain('fallback');
      expect(question.options).toHaveLength(4);
    });

    it('should retry on timeout', async () => {
      // First call times out, second succeeds
      (generateText as jest.Mock)
        .mockRejectedValueOnce(new Error('Timeout'))
        .mockResolvedValueOnce({
          text: JSON.stringify({
            question: 'Retry succeeded',
            options: ['A', 'B', 'C', 'D'],
            recommended: 'A',
            rationale: 'Test',
            confidence: 0.8,
          }),
          usage: { promptTokens: 500, completionTokens: 100 },
        });

      const question = await service.generateQuestion({
        playbookId: 'playbook-123',
        stepIdx: 0,
      });

      expect(question.question).toBe('Retry succeeded');
      expect(generateText).toHaveBeenCalledTimes(2);
    });

    it('should track token usage for cost estimation', async () => {
      (generateText as jest.Mock).mockResolvedValue({
        text: JSON.stringify({
          question: 'Test?',
          options: ['A', 'B', 'C', 'D'],
          recommended: 'A',
          rationale: 'Test',
          confidence: 0.8,
        }),
        usage: {
          promptTokens: 1000,
          completionTokens: 200,
        },
      });

      const question = await service.generateQuestion({
        playbookId: 'playbook-123',
        stepIdx: 0,
      });

      expect(question.context?.llm_usage).toMatchObject({
        prompt_tokens: 1000,
        completion_tokens: 200,
        total_tokens: 1200,
        cost_est_usd: expect.any(Number),
      });
    });
  });
});
```

### Example 4 – Next.js Module Mocking

```typescript
// Mock Next.js navigation
jest.mock('next/navigation', () => ({
  useRouter: jest.fn(),
  usePathname: jest.fn(),
  useSearchParams: jest.fn(),
}));

import { useRouter, usePathname } from 'next/navigation';
import { render, screen, fireEvent } from '@testing-library/react';
import { SessionNavigator } from '@/components/SessionNavigator';

describe('SessionNavigator with Next.js Mocks', () => {
  const mockPush = jest.fn();
  const mockReplace = jest.fn();

  beforeEach(() => {
    jest.clearAllMocks();

    (useRouter as jest.Mock).mockReturnValue({
      push: mockPush,
      replace: mockReplace,
      back: jest.fn(),
    });

    (usePathname as jest.Mock).mockReturnValue('/session/123');
  });

  it('should navigate to next step', () => {
    render(<SessionNavigator sessionId="123" currentStep={1} />);

    const nextButton = screen.getByRole('button', { name: /next/i });
    fireEvent.click(nextButton);

    expect(mockPush).toHaveBeenCalledWith('/session/123?step=2');
  });

  it('should replace URL without adding history', () => {
    render(<SessionNavigator sessionId="123" currentStep={1} />);

    const replaceButton = screen.getByRole('button', { name: /replace/i });
    fireEvent.click(replaceButton);

    expect(mockReplace).toHaveBeenCalledWith('/session/123?step=1');
    expect(mockPush).not.toHaveBeenCalled();
  });
});
```

### Example 5 – Spying on Console and Global Objects

```typescript
describe('Logging and Console Spies', () => {
  let consoleLogSpy: jest.SpyInstance;
  let consoleErrorSpy: jest.SpyInstance;

  beforeEach(() => {
    // Spy on console methods
    consoleLogSpy = jest.spyOn(console, 'log').mockImplementation();
    consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation();
  });

  afterEach(() => {
    // Restore original console
    consoleLogSpy.mockRestore();
    consoleErrorSpy.mockRestore();
  });

  it('should log debug information', () => {
    const debugLog = (message: string) => {
      console.log(`[DEBUG] ${message}`);
    };

    debugLog('Test message');

    expect(consoleLogSpy).toHaveBeenCalledWith('[DEBUG] Test message');
    expect(consoleLogSpy).toHaveBeenCalledTimes(1);
  });

  it('should log errors', () => {
    const handleError = (error: Error) => {
      console.error('Error occurred:', error.message);
    };

    handleError(new Error('Test error'));

    expect(consoleErrorSpy).toHaveBeenCalledWith(
      'Error occurred:',
      'Test error'
    );
  });

  it('should allow real console.log during debugging', () => {
    consoleLogSpy.mockRestore(); // Restore for this test

    console.log('This will actually print during test run');

    // Re-mock for other tests in beforeEach
  });
});
```

### Example 6 – Mock Timers (setTimeout, setInterval, Date)

```typescript
describe('Timer Mocks', () => {
  beforeEach(() => {
    jest.useFakeTimers();
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  it('should wait for timeout', () => {
    const callback = jest.fn();

    setTimeout(callback, 1000);

    expect(callback).not.toHaveBeenCalled();

    // Fast-forward time by 1000ms
    jest.advanceTimersByTime(1000);

    expect(callback).toHaveBeenCalledTimes(1);
  });

  it('should handle interval', () => {
    const callback = jest.fn();

    setInterval(callback, 100);

    jest.advanceTimersByTime(250);

    expect(callback).toHaveBeenCalledTimes(2);

    jest.advanceTimersByTime(100);

    expect(callback).toHaveBeenCalledTimes(3);
  });

  it('should mock Date.now()', () => {
    const now = Date.now();

    jest.setSystemTime(new Date('2025-01-01T00:00:00Z'));

    expect(Date.now()).toBe(new Date('2025-01-01T00:00:00Z').getTime());
    expect(Date.now()).not.toBe(now);
  });

  it('should test session timeout (Bloom example)', async () => {
    const onTimeout = jest.fn();
    const SESSION_TIMEOUT = 15 * 60 * 1000; // 15 minutes

    const startSession = () => {
      setTimeout(onTimeout, SESSION_TIMEOUT);
    };

    startSession();

    // Fast-forward 14 minutes - should not timeout
    jest.advanceTimersByTime(14 * 60 * 1000);
    expect(onTimeout).not.toHaveBeenCalled();

    // Fast-forward 1 more minute - should timeout
    jest.advanceTimersByTime(1 * 60 * 1000);
    expect(onTimeout).toHaveBeenCalledTimes(1);
  });
});
```

### Example 7 – Partial Module Mock (Keep Some Real Exports)

```typescript
// Real module: @/lib/utils.ts
export function add(a: number, b: number): number {
  return a + b;
}

export async function expensiveCalculation(n: number): Promise<number> {
  // Expensive operation that takes 5 seconds
  await new Promise((resolve) => setTimeout(resolve, 5000));
  return n * n;
}

export function formatNumber(n: number): string {
  return n.toLocaleString();
}

// Test file: Partial mock
jest.mock('@/lib/utils', () => ({
  ...jest.requireActual('@/lib/utils'),
  expensiveCalculation: jest.fn(), // Mock only this function
}));

import { add, expensiveCalculation, formatNumber } from '@/lib/utils';

describe('Partial Module Mock', () => {
  it('should use real implementation for add and formatNumber', () => {
    expect(add(2, 3)).toBe(5); // Real implementation
    expect(formatNumber(1000)).toBe('1,000'); // Real implementation
  });

  it('should use mock for expensive calculation', async () => {
    (expensiveCalculation as jest.Mock).mockResolvedValue(100);

    const result = await expensiveCalculation(10);

    expect(result).toBe(100); // Mocked value
    expect(expensiveCalculation).toHaveBeenCalledWith(10);
    // No 5-second delay!
  });
});
```

### Example 8 – Factory Functions for Reusable Mocks

```typescript
// tests/mocks/prisma.ts - Reusable mock factory
export function mockPrismaUser(overrides = {}) {
  return {
    id: 'user-123',
    email: 'test@example.com',
    name: 'Test User',
    createdAt: new Date('2025-01-01'),
    ...overrides,
  };
}

export function mockPrismaSession(overrides = {}) {
  return {
    id: 'session-123',
    userId: 'user-123',
    organizationId: 'org-123',
    status: 'active',
    startedAt: new Date(),
    metadata: {},
    ...overrides,
  };
}

// In test files
import { mockPrismaUser, mockPrismaSession } from '@/tests/mocks/prisma';

describe('User Service', () => {
  it('should handle user with custom email', () => {
    const user = mockPrismaUser({ email: 'custom@example.com' });

    expect(user.email).toBe('custom@example.com');
    expect(user.id).toBe('user-123'); // Default value
  });

  it('should create session with custom status', () => {
    const session = mockPrismaSession({ status: 'completed' });

    expect(session.status).toBe('completed');
  });
});
```

---

## 6. Common Pitfalls

### Pitfall 1: Mocking After Import

```typescript
// ❌ WRONG: Import before mock
import { prisma } from '@/lib/prisma';
jest.mock('@/lib/prisma');

// Module is already imported with real implementation!
// Mock has no effect
```

```typescript
// ✅ CORRECT: Mock before import
jest.mock('@/lib/prisma', () => ({
  prisma: {
    user: { findUnique: jest.fn() },
  },
}));

import { prisma } from '@/lib/prisma';
// Now prisma is the mocked version
```

**Fix:** Always call `jest.mock()` at the top of the file before any imports.

### Pitfall 2: Forgetting to Clear Mocks Between Tests

```typescript
// ❌ WRONG: Mock state carries over between tests
describe('User Service', () => {
  it('should create user', async () => {
    (prisma.user.create as jest.Mock).mockResolvedValue({ id: '123' });
    await createUser({ email: 'test@example.com' });
    expect(prisma.user.create).toHaveBeenCalledTimes(1);
  });

  it('should update user', async () => {
    (prisma.user.update as jest.Mock).mockResolvedValue({ id: '123' });
    await updateUser('123', { name: 'Updated' });

    // ❌ FAILS: prisma.user.create still shows 1 call from previous test!
    expect(prisma.user.create).toHaveBeenCalledTimes(0);
  });
});
```

```typescript
// ✅ CORRECT: Clear mocks in beforeEach
describe('User Service', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('should create user', async () => {
    (prisma.user.create as jest.Mock).mockResolvedValue({ id: '123' });
    await createUser({ email: 'test@example.com' });
    expect(prisma.user.create).toHaveBeenCalledTimes(1);
  });

  it('should update user', async () => {
    (prisma.user.update as jest.Mock).mockResolvedValue({ id: '123' });
    await updateUser('123', { name: 'Updated' });

    // ✅ PASSES: Mock was cleared
    expect(prisma.user.create).toHaveBeenCalledTimes(0);
  });
});
```

### Pitfall 3: Not Restoring Spies

```typescript
// ❌ WRONG: Spy affects other tests
describe('Console Tests', () => {
  it('should spy on console.log', () => {
    const spy = jest.spyOn(console, 'log').mockImplementation();
    console.log('test');
    expect(spy).toHaveBeenCalled();
    // ❌ Forgot to restore!
  });

  it('should log normally', () => {
    console.log('This will NOT print!'); // Still mocked from previous test
  });
});
```

```typescript
// ✅ CORRECT: Restore spies
describe('Console Tests', () => {
  let consoleSpy: jest.SpyInstance;

  afterEach(() => {
    consoleSpy?.mockRestore();
  });

  it('should spy on console.log', () => {
    consoleSpy = jest.spyOn(console, 'log').mockImplementation();
    console.log('test');
    expect(consoleSpy).toHaveBeenCalled();
  });

  it('should log normally', () => {
    console.log('This WILL print!'); // Restored
  });
});
```

### Pitfall 4: Mocking the Code Under Test

```typescript
// ❌ WRONG: Mocking what you're testing
jest.mock('@/lib/sessions', () => ({
  createSession: jest.fn().mockResolvedValue({ id: '123' }),
}));

import { createSession } from '@/lib/sessions';

it('should create session', async () => {
  const session = await createSession({ userId: '123' });

  // ❌ This test is meaningless!
  // You're testing the mock, not the real implementation
  expect(session.id).toBe('123');
});
```

```typescript
// ✅ CORRECT: Mock dependencies, test real code
jest.mock('@/lib/prisma', () => ({
  prisma: {
    session: { create: jest.fn() },
  },
}));

import { createSession } from '@/lib/sessions'; // Real implementation
import { prisma } from '@/lib/prisma'; // Mocked dependency

it('should create session', async () => {
  (prisma.session.create as jest.Mock).mockResolvedValue({
    id: 'session-123',
  });

  const session = await createSession({ userId: 'user-123' });

  // ✅ Testing real createSession implementation
  // with mocked database dependency
  expect(session.id).toBe('session-123');
  expect(prisma.session.create).toHaveBeenCalled();
});
```

### Pitfall 5: Incorrect Async Mock Syntax

```typescript
// ❌ WRONG: Using mockReturnValue for async function
const mockFn = jest.fn().mockReturnValue({ id: '123' });
await mockFn(); // Returns { id: '123' }, NOT Promise<{ id: '123' }>

// Causes "TypeError: Cannot read property 'then' of undefined"
```

```typescript
// ✅ CORRECT: Use mockResolvedValue for promises
const mockFn = jest.fn().mockResolvedValue({ id: '123' });
await mockFn(); // Returns Promise<{ id: '123' }>

// For errors
const errorMock = jest.fn().mockRejectedValue(new Error('Failed'));
await errorMock(); // Throws Error
```

### Pitfall 6: Over-Mocking (Testing Implementation Details)

```typescript
// ❌ ANTI-PATTERN: Over-specifying mock expectations
it('should process user data', async () => {
  const mockUser = { id: '123', name: 'Test' };
  (prisma.user.findUnique as jest.Mock).mockResolvedValue(mockUser);

  await processUser('123');

  // ❌ Too specific - brittle test
  expect(prisma.user.findUnique).toHaveBeenCalledWith({
    where: { id: '123' },
    include: {
      posts: true,
      comments: true,
      likes: true,
    },
    orderBy: { createdAt: 'desc' },
    take: 10,
  });

  // If implementation changes query structure, test breaks
  // even if behavior is correct
});
```

```typescript
// ✅ BETTER: Test behavior, not implementation
it('should process user data', async () => {
  const mockUser = { id: '123', name: 'Test' };
  (prisma.user.findUnique as jest.Mock).mockResolvedValue(mockUser);

  const result = await processUser('123');

  // ✅ Test outputs and side effects
  expect(result).toMatchObject({ id: '123', processed: true });

  // ✅ Verify function was called (don't over-specify args)
  expect(prisma.user.findUnique).toHaveBeenCalledWith(
    expect.objectContaining({
      where: { id: '123' },
    })
  );
});
```

### Pitfall 7: Module Mock Hoisting Issues

```typescript
// ❌ PROBLEM: Dynamic mock values don't work
const userId = 'dynamic-123';

jest.mock('@/lib/prisma', () => ({
  prisma: {
    user: {
      findUnique: jest.fn().mockResolvedValue({ id: userId }), // ❌ userId is undefined!
    },
  },
}));

// jest.mock() is hoisted to top of file before userId is defined
```

```typescript
// ✅ SOLUTION 1: Use jest.fn() without implementation, configure in test
jest.mock('@/lib/prisma', () => ({
  prisma: {
    user: {
      findUnique: jest.fn(),
    },
  },
}));

it('should use dynamic user ID', () => {
  const userId = 'dynamic-123';

  (prisma.user.findUnique as jest.Mock).mockResolvedValue({ id: userId });

  // Now userId is available
});
```

```typescript
// ✅ SOLUTION 2: Use factory function
jest.mock('@/lib/prisma', () => {
  const actual = jest.requireActual('@/lib/prisma');
  return {
    ...actual,
    prisma: {
      user: {
        findUnique: jest.fn(),
      },
    },
  };
});
```

---

## 7. AI Pair Programming Notes

### When to Load This File

- **Load when:** Writing tests that need mocking (database, APIs, external services)
- **Combine with:**
  - `02-MATCHERS-ASSERTIONS.md` for assertion syntax
  - `04-ASYNC-TESTING.md` for async/await patterns
  - `06-API-TESTING.md` for mocking HTTP requests
  - `07-DATABASE-TESTING.md` for Prisma-specific mocking patterns

### Critical Patterns for Bloom

1. **Always mock Prisma in unit tests**
   ```typescript
   jest.mock('@/lib/prisma', () => ({
     prisma: { /* mock methods */ },
   }));
   ```

2. **Always mock AI SDK (Vercel AI + Anthropic)**
   ```typescript
   jest.mock('ai', () => ({
     generateText: jest.fn(),
   }));
   ```

3. **Always mock external services (email, analytics)**
   ```typescript
   jest.mock('@/lib/email', () => ({
     sendEmail: jest.fn(),
   }));
   ```

4. **Always clear mocks in beforeEach**
   ```typescript
   beforeEach(() => {
     jest.clearAllMocks();
   });
   ```

### AI Prompting Tips

**Good prompt:**
> "Write a Jest test for the `createSession` function. Mock the Prisma client to return a session object. Test both success and error cases."

**Bad prompt:**
> "Test createSession" (too vague, AI might use real database)

**Good prompt:**
> "Mock the Anthropic AI SDK call to return a fixed question with 4 options. Test that the LLM service correctly parses the response."

### Common AI Mistakes to Watch For

1. ❌ AI mocks after imports (hoisting issue)
2. ❌ AI forgets `jest.clearAllMocks()` in `beforeEach`
3. ❌ AI uses `mockReturnValue` instead of `mockResolvedValue` for async
4. ❌ AI mocks the code under test instead of dependencies
5. ❌ AI over-specifies mock call expectations (brittle tests)

### Bloom-Specific Mocking Checklist

- [ ] Prisma client mocked for all database operations
- [ ] AI SDK mocked for all LLM calls (don't waste API credits in tests!)
- [ ] Next.js router/navigation mocked for routing tests
- [ ] Date/timers mocked for time-dependent tests (session timeout)
- [ ] Console spies used (not mocked) for logging verification
- [ ] All mocks cleared in `beforeEach`
- [ ] All spies restored in `afterEach`

---

## Last Updated

2025-11-14

---

**Next Steps:**
- For async testing patterns: See `04-ASYNC-TESTING.md`
- For API route testing: See `06-API-TESTING.md`
- For Prisma mocking patterns: See `07-DATABASE-TESTING.md`
- For quick reference: See `QUICK-REFERENCE.md`
