---
id: jest-quick-reference
topic: jest
file_role: quickref
profile: full
difficulty_level: all-levels
kb_version: 3.1
prerequisites: []
related_topics: [testing, typescript]
embedding_keywords: [jest, cheat-sheet, syntax, quick-reference, commands]
last_reviewed: 2025-11-14
---

# Jest Quick Reference

## Basic Test Structure

```typescript
describe('ComponentName', () => {
  it('should do something', () => {
    expect(actual).toBe(expected);
  });

  test('alternative syntax', () => {
    expect(result).toEqual(value);
  });
});
```

## Common Matchers

### Equality
```typescript
expect(value).toBe(expected);              // ===
expect(value).toEqual(expected);           // deep equality
expect(value).toStrictEqual(expected);     // strict deep equality
expect(value).not.toBe(unexpected);        // negation
```

### Truthiness
```typescript
expect(value).toBeTruthy();
expect(value).toBeFalsy();
expect(value).toBeNull();
expect(value).toBeUndefined();
expect(value).toBeDefined();
```

### Numbers
```typescript
expect(value).toBeGreaterThan(n);
expect(value).toBeGreaterThanOrEqual(n);
expect(value).toBeLessThan(n);
expect(value).toBeLessThanOrEqual(n);
expect(value).toBeCloseTo(0.3, 5);         // floating point
```

### Strings
```typescript
expect(str).toMatch(/pattern/);
expect(str).toMatch('substring');
expect(str).toContain('text');
```

### Arrays & Iterables
```typescript
expect(array).toContain(item);
expect(array).toHaveLength(n);
expect(array).toEqual(expect.arrayContaining([items]));
```

### Objects
```typescript
expect(obj).toHaveProperty('key');
expect(obj).toHaveProperty('key', value);
expect(obj).toMatchObject({ subset });
```

## Async Testing

### Promises
```typescript
// Using async/await (recommended)
test('async test', async () => {
  const data = await fetchData();
  expect(data).toBe('value');
});

// Using .resolves
test('resolves to value', async () => {
  await expect(fetchData()).resolves.toBe('value');
});

// Using .rejects
test('rejects with error', async () => {
  await expect(fetchData()).rejects.toThrow('Error');
});
```

### Callbacks
```typescript
test('callback test', (done) => {
  function callback(data) {
    expect(data).toBe('value');
    done();
  }
  fetchData(callback);
});
```

## Mocking

### Mock Functions
```typescript
const mockFn = jest.fn();
mockFn.mockReturnValue(42);
mockFn.mockResolvedValue('async value');
mockFn.mockRejectedValue(new Error('fail'));

expect(mockFn).toHaveBeenCalled();
expect(mockFn).toHaveBeenCalledTimes(2);
expect(mockFn).toHaveBeenCalledWith(arg1, arg2);
expect(mockFn).toHaveBeenLastCalledWith(arg);
```

### Module Mocking
```typescript
// Mock entire module
jest.mock('./module');

// Mock specific module
jest.mock('./module', () => ({
  functionName: jest.fn(() => 'mocked value')
}));

// Partial mock
jest.mock('./module', () => ({
  ...jest.requireActual('./module'),
  specificFunction: jest.fn()
}));
```

### Spies
```typescript
const spy = jest.spyOn(object, 'method');
spy.mockImplementation(() => 'new value');
spy.mockRestore();  // restore original
```

## Setup & Teardown

```typescript
beforeAll(() => {
  // runs once before all tests
});

afterAll(() => {
  // runs once after all tests
});

beforeEach(() => {
  // runs before each test
});

afterEach(() => {
  // runs after each test
});
```

## Test Organization

```typescript
describe.only('focused suite', () => {
  // only this suite runs
});

it.skip('skipped test', () => {
  // this test is skipped
});

it.todo('future test');

it.each([
  [1, 2, 3],
  [2, 3, 5],
])('adds %i + %i to equal %i', (a, b, expected) => {
  expect(a + b).toBe(expected);
});
```

## React Testing Library

```typescript
import { render, screen, fireEvent } from '@testing-library/react';

test('renders component', () => {
  render(<Component />);

  const element = screen.getByText(/text/i);
  expect(element).toBeInTheDocument();

  fireEvent.click(screen.getByRole('button'));

  await screen.findByText('async content');
});
```

### Common Queries
```typescript
screen.getByText('text');
screen.getByRole('button');
screen.getByLabelText('label');
screen.getByPlaceholderText('placeholder');
screen.getByTestId('test-id');

// Async variants
await screen.findByText('text');

// Query variants (returns null if not found)
screen.queryByText('text');
```

## Common Commands

```bash
# Run all tests
npm test

# Run in watch mode
npm test -- --watch

# Run specific file
npm test -- path/to/file

# Run with coverage
npm test -- --coverage

# Update snapshots
npm test -- -u

# Run tests matching pattern
npm test -- --testNamePattern="pattern"
```

## Configuration (jest.config.js)

```javascript
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',  // or 'jsdom' for React
  roots: ['<rootDir>/src'],
  testMatch: ['**/__tests__/**/*.ts', '**/*.test.ts'],
  collectCoverageFrom: [
    'src/**/*.{ts,tsx}',
    '!src/**/*.d.ts',
  ],
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80,
    },
  },
};
```

## TypeScript Integration

```typescript
// Type-safe mocks
const mockUser = {
  id: '1',
  name: 'Test User',
} satisfies User;

// Typed mock functions
const mockFn = jest.fn<ReturnType<typeof fn>, Parameters<typeof fn>>();

// Mock module with types
jest.mock<typeof import('./module')>('./module');
```

## Environment Variables

```typescript
process.env.NODE_ENV = 'test';
process.env.API_URL = 'http://test-api.example.com';
```

## Common Patterns

### Testing Errors
```typescript
expect(() => {
  throw new Error('error');
}).toThrow('error');

expect(() => fn()).toThrow(TypeError);
```

### Testing Promises
```typescript
await expect(promise).resolves.toBe(value);
await expect(promise).rejects.toThrow();
```

### Snapshot Testing
```typescript
expect(component).toMatchSnapshot();
expect(data).toMatchInlineSnapshot(`"expected"`);
```

## Custom Matchers

### Creating Custom Matchers
```typescript
expect.extend({
  toBeWithinRange(received, floor, ceiling) {
    const pass = received >= floor && received <= ceiling;
    if (pass) {
      return {
        message: () => `expected ${received} not to be within range ${floor} - ${ceiling}`,
        pass: true,
      };
    } else {
      return {
        message: () => `expected ${received} to be within range ${floor} - ${ceiling}`,
        pass: false,
      };
    }
  },
});

test('numeric ranges', () => {
  expect(100).toBeWithinRange(90, 110);
});
```

### TypeScript Custom Matchers
```typescript
declare global {
  namespace jest {
    interface Matchers<R> {
      toBeWithinRange(floor: number, ceiling: number): R;
    }
  }
}
```

## Advanced Mocking Patterns

### Mock Implementation Per Call
```typescript
const mockFn = jest
  .fn()
  .mockReturnValueOnce('first call')
  .mockReturnValueOnce('second call')
  .mockReturnValue('default');

expect(mockFn()).toBe('first call');
expect(mockFn()).toBe('second call');
expect(mockFn()).toBe('default');
```

### Mock Implementation with Arguments
```typescript
const mockFn = jest.fn((x) => x * 2);
expect(mockFn(5)).toBe(10);

// Or use mockImplementation
mockFn.mockImplementation((x) => x * 3);
expect(mockFn(5)).toBe(15);
```

### Mock Getters and Setters
```typescript
const obj = {
  _value: 0,
  get value() {
    return this._value;
  },
  set value(val) {
    this._value = val;
  },
};

jest.spyOn(obj, 'value', 'get').mockReturnValue(42);
jest.spyOn(obj, 'value', 'set').mockImplementation(() => {});
```

### Mock Class Instances
```typescript
// Mock constructor
jest.mock('./SomeClass');
import SomeClass from './SomeClass';

const mockInstance = {
  method: jest.fn(),
};

(SomeClass as jest.Mock).mockImplementation(() => mockInstance);

// Usage
const instance = new SomeClass();
instance.method();
expect(mockInstance.method).toHaveBeenCalled();
```

### Mock ES6 Classes
```typescript
export default class SoundPlayer {
  constructor() {
    this.name = 'Player';
  }
  playSoundFile(fileName: string) {
    console.log('Playing', fileName);
  }
}

// In test file
jest.mock('./SoundPlayer'); // This is hoisted

import SoundPlayer from './SoundPlayer';

test('mock class', () => {
  const mockPlaySoundFile = jest.fn();
  (SoundPlayer as jest.Mock).mockImplementation(() => {
    return {
      playSoundFile: mockPlaySoundFile,
    };
  });

  const player = new SoundPlayer();
  player.playSoundFile('song.mp3');
  expect(mockPlaySoundFile).toHaveBeenCalledWith('song.mp3');
});
```

### Partial Module Mocking
```typescript
// utils.ts
export const add = (a: number, b: number) => a + b;
export const subtract = (a: number, b: number) => a - b;
export const multiply = (a: number, b: number) => a * b;

// test file
jest.mock('./utils', () => ({
  ...jest.requireActual('./utils'),
  multiply: jest.fn((a, b) => 100), // Only mock this function
}));

import { add, multiply } from './utils';

test('partial mock', () => {
  expect(add(2, 3)).toBe(5); // Real implementation
  expect(multiply(2, 3)).toBe(100); // Mocked
});
```

### Mock Default and Named Exports
```typescript
// module.ts
export default function defaultFunc() {
  return 'default';
}
export const namedFunc = () => 'named';

// test
jest.mock('./module', () => ({
  __esModule: true,
  default: jest.fn(() => 'mocked default'),
  namedFunc: jest.fn(() => 'mocked named'),
}));
```

### Mock Node Modules
```typescript
// Mock fs module
jest.mock('fs');
import fs from 'fs';

(fs.readFileSync as jest.Mock).mockReturnValue('file contents');
```

### Mock Dynamic Imports
```typescript
jest.mock('./module', () => ({
  __esModule: true,
  default: jest.fn(),
}));

test('dynamic import', async () => {
  const module = await import('./module');
  expect(module.default).toBeDefined();
});
```

## Timer Mocking

### Fake Timers
```typescript
jest.useFakeTimers();

test('timer test', () => {
  const callback = jest.fn();
  setTimeout(callback, 1000);

  // Fast-forward time
  jest.advanceTimersByTime(1000);
  expect(callback).toHaveBeenCalled();
});

// Run all timers
jest.runAllTimers();

// Run only currently pending timers
jest.runOnlyPendingTimers();

// Clear all timers
jest.clearAllTimers();

// Restore real timers
jest.useRealTimers();
```

### Modern Timer Mocking
```typescript
jest.useFakeTimers({ legacyFakeTimers: false });

test('modern timers', async () => {
  const callback = jest.fn();

  setTimeout(callback, 100);
  await jest.advanceTimersByTimeAsync(100);

  expect(callback).toHaveBeenCalled();
});
```

### Date Mocking
```typescript
jest.useFakeTimers().setSystemTime(new Date('2025-01-01'));

test('date mocking', () => {
  expect(new Date().toISOString()).toMatch(/2025-01-01/);
});
```

## Snapshot Testing Advanced

### Property Matchers
```typescript
expect(user).toMatchSnapshot({
  id: expect.any(String),
  createdAt: expect.any(Date),
});
```

### Inline Snapshots
```typescript
expect(data).toMatchInlineSnapshot(`
  Object {
    "name": "Test",
    "value": 42,
  }
`);
```

### Snapshot Serializers
```typescript
// Custom serializer
expect.addSnapshotSerializer({
  test: (val) => val && val.hasOwnProperty('$$typeof'),
  print: (val) => `ReactElement<${val.type}>`,
});
```

### Update Specific Snapshots
```bash
npm test -- -u --testNamePattern="test name"
```

## Test Lifecycle Hooks

### Execution Order
```typescript
describe('suite', () => {
  beforeAll(() => console.log('1 - beforeAll'));
  afterAll(() => console.log('1 - afterAll'));
  beforeEach(() => console.log('1 - beforeEach'));
  afterEach(() => console.log('1 - afterEach'));

  test('test', () => console.log('1 - test'));

  describe('nested', () => {
    beforeAll(() => console.log('2 - beforeAll'));
    afterAll(() => console.log('2 - afterAll'));
    beforeEach(() => console.log('2 - beforeEach'));
    afterEach(() => console.log('2 - afterEach'));

    test('test', () => console.log('2 - test'));
  });
});

// Output:
// 1 - beforeAll
// 1 - beforeEach
// 1 - test
// 1 - afterEach
// 2 - beforeAll
// 1 - beforeEach
// 2 - beforeEach
// 2 - test
// 2 - afterEach
// 1 - afterEach
// 2 - afterAll
// 1 - afterAll
```

### Scoped Hooks
```typescript
describe('suite', () => {
  beforeEach(() => {
    // Runs for all tests in this suite
  });

  describe('nested', () => {
    beforeEach(() => {
      // Runs only for tests in this nested suite (after parent beforeEach)
    });
  });
});
```

## Test Isolation and Cleanup

### Reset Mocks
```typescript
beforeEach(() => {
  jest.clearAllMocks(); // Clear call history
  jest.resetAllMocks(); // Clear + reset implementation
  jest.restoreAllMocks(); // Restore original implementation
});
```

### Manual Cleanup
```typescript
afterEach(() => {
  // Clean up resources
  jest.clearAllTimers();
  jest.restoreAllMocks();
});
```

## Parameterized Tests

### test.each with Arrays
```typescript
test.each([
  [1, 1, 2],
  [1, 2, 3],
  [2, 1, 3],
])('.add(%i, %i) = %i', (a, b, expected) => {
  expect(a + b).toBe(expected);
});
```

### test.each with Objects
```typescript
test.each([
  { a: 1, b: 1, expected: 2 },
  { a: 1, b: 2, expected: 3 },
  { a: 2, b: 1, expected: 3 },
])('.add($a, $b) = $expected', ({ a, b, expected }) => {
  expect(a + b).toBe(expected);
});
```

### describe.each
```typescript
describe.each([
  { name: 'User', role: 'user' },
  { name: 'Admin', role: 'admin' },
])('$name permissions', ({ name, role }) => {
  test(`${name} has correct role`, () => {
    expect(role).toBeTruthy();
  });
});
```

### Template Literals
```typescript
test.each`
  a    | b    | expected
  ${1} | ${1} | ${2}
  ${1} | ${2} | ${3}
  ${2} | ${1} | ${3}
`('$a + $b = $expected', ({ a, b, expected }) => {
  expect(a + b).toBe(expected);
});
```

## Coverage Configuration

### Coverage Thresholds
```javascript
// jest.config.js
module.exports = {
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80,
    },
    './src/components/': {
      branches: 90,
      functions: 90,
      lines: 90,
      statements: 90,
    },
    './src/utils/**/*.ts': {
      branches: 100,
      functions: 100,
      lines: 100,
      statements: 100,
    },
  },
};
```

### Collect Coverage From
```javascript
collectCoverageFrom: [
  'src/**/*.{js,jsx,ts,tsx}',
  '!src/**/*.d.ts',
  '!src/**/*.stories.tsx',
  '!src/**/__tests__/**',
  '!src/**/index.ts',
],
```

### Coverage Reporters
```javascript
coverageReporters: ['text', 'lcov', 'html', 'json-summary'],
```

## Next.js Specific Patterns

### Testing API Routes (App Router)
```typescript
import { POST } from '@/app/api/users/route';
import { NextRequest } from 'next/server';

test('POST /api/users', async () => {
  const request = new NextRequest('http://localhost:3000/api/users', {
    method: 'POST',
    body: JSON.stringify({ name: 'Test' }),
  });

  const response = await POST(request);
  const data = await response.json();

  expect(response.status).toBe(201);
  expect(data.name).toBe('Test');
});
```

### Testing Server Components
```typescript
import { render } from '@testing-library/react';
import ServerComponent from '@/app/components/ServerComponent';

// Mock server-side data fetching
jest.mock('@/lib/db', () => ({
  fetchData: jest.fn().mockResolvedValue({ data: 'test' }),
}));

test('server component', async () => {
  const { container } = render(await ServerComponent());
  expect(container).toHaveTextContent('test');
});
```

### Testing Server Actions
```typescript
import { createUser } from '@/app/actions/users';

jest.mock('@/lib/db');
import { prisma } from '@/lib/db';

test('createUser action', async () => {
  const mockCreate = jest.fn().mockResolvedValue({
    id: '1',
    name: 'Test',
  });

  (prisma.user.create as jest.Mock) = mockCreate;

  const formData = new FormData();
  formData.append('name', 'Test');

  const result = await createUser(formData);

  expect(result.id).toBe('1');
  expect(mockCreate).toHaveBeenCalledWith({
    data: { name: 'Test' },
  });
});
```

### Testing Middleware
```typescript
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';
import { middleware } from '@/middleware';

test('middleware redirects unauthenticated users', async () => {
  const request = new NextRequest('http://localhost:3000/protected', {
    headers: { cookie: '' },
  });

  const response = await middleware(request);

  expect(response?.status).toBe(307);
  expect(response?.headers.get('location')).toContain('/login');
});
```

## React Testing Library Advanced

### User Events (Recommended over fireEvent)
```typescript
import userEvent from '@testing-library/user-event';

test('user interactions', async () => {
  const user = userEvent.setup();
  render(<Component />);

  await user.type(screen.getByRole('textbox'), 'Hello');
  await user.click(screen.getByRole('button'));
  await user.selectOptions(screen.getByRole('listbox'), 'option1');
  await user.upload(screen.getByLabelText('Upload'), file);
});
```

### Custom Render Function
```typescript
// test-utils.tsx
import { render, RenderOptions } from '@testing-library/react';
import { ReactElement } from 'react';
import { ThemeProvider } from '@/components/ThemeProvider';

const AllTheProviders = ({ children }: { children: React.ReactNode }) => {
  return <ThemeProvider>{children}</ThemeProvider>;
};

const customRender = (
  ui: ReactElement,
  options?: Omit<RenderOptions, 'wrapper'>
) => render(ui, { wrapper: AllTheProviders, ...options });

export * from '@testing-library/react';
export { customRender as render };
```

### Testing Hooks
```typescript
import { renderHook, waitFor } from '@testing-library/react';
import { useCounter } from '@/hooks/useCounter';

test('useCounter', async () => {
  const { result } = renderHook(() => useCounter());

  expect(result.current.count).toBe(0);

  act(() => {
    result.current.increment();
  });

  await waitFor(() => {
    expect(result.current.count).toBe(1);
  });
});
```

### Waiting for Elements
```typescript
// Wait for element to appear
const element = await screen.findByText('Loading complete');

// Wait for element to disappear
await waitForElementToBeRemoved(() => screen.queryByText('Loading...'));

// Custom wait
await waitFor(() => {
  expect(screen.getByText('Done')).toBeInTheDocument();
}, { timeout: 3000 });
```

### Query Priority
```typescript
// Preferred (accessible to all users)
screen.getByRole('button', { name: /submit/i });
screen.getByLabelText('Username');
screen.getByPlaceholderText('Enter username');
screen.getByText('Submit');

// Less preferred (relies on implementation details)
screen.getByDisplayValue('current value');

// Last resort (brittle)
screen.getByTestId('submit-button');
```

### Debugging
```typescript
import { screen, prettyDOM } from '@testing-library/react';

// Print DOM
screen.debug();

// Print specific element
screen.debug(screen.getByRole('button'));

// Print with max length
screen.debug(undefined, 20000);

// Get pretty DOM
console.log(prettyDOM(element));
```

## Prisma Testing Patterns

### Mock Prisma Client
```typescript
import { PrismaClient } from '@prisma/client';
import { mockDeep, mockReset, DeepMockProxy } from 'jest-mock-extended';

export const prisma = mockDeep<PrismaClient>();

beforeEach(() => {
  mockReset(prisma);
});

// In tests
test('create user', async () => {
  const mockUser = { id: '1', name: 'Test', email: 'test@example.com' };
  prisma.user.create.mockResolvedValue(mockUser);

  const result = await createUser({ name: 'Test', email: 'test@example.com' });
  expect(result).toEqual(mockUser);
});
```

### Prisma Singleton Pattern
```typescript
// lib/db/singleton.ts
import { PrismaClient } from '@prisma/client';
import { mockDeep, DeepMockProxy } from 'jest-mock-extended';

export type MockContext = {
  prisma: DeepMockProxy<PrismaClient>;
};

export const createMockContext = (): MockContext => {
  return {
    prisma: mockDeep<PrismaClient>(),
  };
};
```

### Transaction Testing
```typescript
test('transaction rollback', async () => {
  const mockTransaction = prisma.$transaction as jest.Mock;

  mockTransaction.mockImplementation(async (callback) => {
    const tx = mockDeep<PrismaClient>();
    return callback(tx);
  });

  await expect(performTransactionWork()).rejects.toThrow();
  expect(mockTransaction).toHaveBeenCalled();
});
```

## Environment Setup

### Setup Files
```javascript
// jest.setup.js
import '@testing-library/jest-dom';

// Global test utilities
global.fetch = jest.fn();

// Mock environment variables
process.env.DATABASE_URL = 'file:./test.db';
process.env.NODE_ENV = 'test';

// Suppress console errors in tests
global.console = {
  ...console,
  error: jest.fn(),
  warn: jest.fn(),
};
```

### Setup Files After Env
```javascript
// jest.setup-after-env.js
// Runs after test framework is installed

// Extend matchers
expect.extend({
  // Custom matchers
});

// Set test timeout
jest.setTimeout(10000);
```

## TypeScript Patterns

### Type-Safe Mock Data
```typescript
import { User } from '@prisma/client';

const mockUser: User = {
  id: '1',
  name: 'Test User',
  email: 'test@example.com',
  createdAt: new Date(),
  updatedAt: new Date(),
};

// Or use satisfies for partial mocks
const partialUser = {
  id: '1',
  name: 'Test',
} satisfies Partial<User>;
```

### Generic Mock Functions
```typescript
function createMockFn<T extends (...args: any[]) => any>(
  impl?: T
): jest.MockedFunction<T> {
  return jest.fn(impl) as jest.MockedFunction<T>;
}

// Usage
const mockFetch = createMockFn<typeof fetch>();
```

### Mocking with Type Inference
```typescript
import { mocked } from 'jest-mock';
import { fetchUser } from './api';

jest.mock('./api');

test('typed mock', async () => {
  const mockedFetch = mocked(fetchUser);
  mockedFetch.mockResolvedValue({ id: '1', name: 'Test' });

  const user = await fetchUser('1');
  expect(user.name).toBe('Test');
});
```

## CLI Commands Reference

### Running Tests
```bash
# Run all tests
npm test

# Run in watch mode
npm test -- --watch

# Run specific file
npm test -- user.test.ts

# Run matching pattern
npm test -- --testPathPattern=user

# Run tests with specific name
npm test -- --testNamePattern="creates user"

# Run only changed tests
npm test -- --onlyChanged

# Run tests related to changed files
npm test -- --changedSince=main

# Run with coverage
npm test -- --coverage

# Run with coverage for specific files
npm test -- --coverage --collectCoverageFrom="src/utils/**"

# Run in CI mode (no watch)
npm test -- --ci

# Run with specific config
npm test -- --config=jest.config.ci.js

# Run in band (no parallelization)
npm test -- --runInBand

# Max workers
npm test -- --maxWorkers=4

# Verbose output
npm test -- --verbose

# Silent output
npm test -- --silent

# Show configuration
npx jest --showConfig

# Clear cache
npx jest --clearCache
```

### Snapshot Commands
```bash
# Update all snapshots
npm test -- -u

# Update snapshots for specific test
npm test -- -u --testNamePattern="user profile"

# Interactive snapshot update
npm test -- --watch
# Then press 'i' to update interactively
```

### Coverage Commands
```bash
# Generate coverage report
npm test -- --coverage

# Coverage with specific reporters
npm test -- --coverage --coverageReporters=html --coverageReporters=text

# Open coverage report
open coverage/lcov-report/index.html
```

### Watch Mode Commands
```bash
# Watch mode
npm test -- --watch

# In watch mode:
# Press 'a' to run all tests
# Press 'f' to run only failed tests
# Press 'o' to run only changed tests
# Press 'p' to filter by filename pattern
# Press 't' to filter by test name pattern
# Press 'q' to quit
# Press 'i' to update failing snapshots interactively
```

## Configuration Examples

### Basic TypeScript Config
```javascript
// jest.config.js
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/src'],
  testMatch: ['**/__tests__/**/*.ts', '**/?(*.)+(spec|test).ts'],
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/src/$1',
  },
  setupFilesAfterEnv: ['<rootDir>/jest.setup.ts'],
  collectCoverageFrom: [
    'src/**/*.ts',
    '!src/**/*.d.ts',
    '!src/**/__tests__/**',
  ],
};
```

### Next.js Config
```javascript
// jest.config.js
const nextJest = require('next/jest');

const createJestConfig = nextJest({
  dir: './',
});

const customJestConfig = {
  setupFilesAfterEnv: ['<rootDir>/jest.setup.js'],
  testEnvironment: 'jest-environment-jsdom',
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/$1',
  },
  testMatch: [
    '**/__tests__/**/*.[jt]s?(x)',
    '**/?(*.)+(spec|test).[jt]s?(x)',
  ],
  collectCoverageFrom: [
    'app/**/*.{js,jsx,ts,tsx}',
    'components/**/*.{js,jsx,ts,tsx}',
    'lib/**/*.{js,jsx,ts,tsx}',
    '!**/*.d.ts',
    '!**/node_modules/**',
    '!**/.next/**',
  ],
};

module.exports = createJestConfig(customJestConfig);
```

### Multi-Project Config
```javascript
// jest.config.js
module.exports = {
  projects: [
    {
      displayName: 'unit',
      testMatch: ['**/__tests__/unit/**/*.test.ts'],
      testEnvironment: 'node',
    },
    {
      displayName: 'integration',
      testMatch: ['**/__tests__/integration/**/*.test.ts'],
      testEnvironment: 'node',
      setupFilesAfterEnv: ['<rootDir>/jest.setup.integration.ts'],
    },
    {
      displayName: 'e2e',
      testMatch: ['**/__tests__/e2e/**/*.test.ts'],
      testEnvironment: 'jsdom',
      setupFilesAfterEnv: ['<rootDir>/jest.setup.e2e.ts'],
    },
  ],
};
```

## Common Troubleshooting

### Module Resolution Issues
```javascript
// Add to jest.config.js
moduleNameMapper: {
  '^@/(.*)$': '<rootDir>/src/$1',
  '\\.(css|less|scss|sass)$': 'identity-obj-proxy',
  '\\.(jpg|jpeg|png|gif|svg)$': '<rootDir>/__mocks__/fileMock.js',
},
```

### ESM Module Issues
```javascript
// Add to jest.config.js
transform: {
  '^.+\\.tsx?$': ['ts-jest', {
    useESM: true,
  }],
},
extensionsToTreatAsEsm: ['.ts', '.tsx'],
```

### Async Cleanup Warnings
```typescript
// Add cleanup in afterEach
afterEach(async () => {
  await cleanup();
  jest.clearAllTimers();
});
```

### Memory Leaks
```bash
# Run with leak detection
npm test -- --detectLeaks

# Limit workers to prevent OOM
npm test -- --maxWorkers=2
```

## Best Practices Checklist

### Test Organization
- [ ] Use descriptive test names
- [ ] Group related tests with `describe`
- [ ] One assertion per test (when possible)
- [ ] Arrange-Act-Assert pattern

### Mocking
- [ ] Mock at the module boundary
- [ ] Reset mocks between tests
- [ ] Don't mock what you're testing
- [ ] Use `jest.spyOn` for partial mocks

### Async Testing
- [ ] Use async/await over callbacks
- [ ] Always await async operations
- [ ] Set appropriate timeouts
- [ ] Handle promise rejections

### Coverage
- [ ] Aim for 80%+ coverage
- [ ] Focus on critical paths
- [ ] Don't chase 100% blindly
- [ ] Review coverage reports regularly

### Performance
- [ ] Keep tests fast (<100ms each)
- [ ] Avoid unnecessary setup
- [ ] Use `--onlyChanged` in development
- [ ] Run slow tests in parallel

## AI Pair Programming Notes

When using this reference with AI:

### Loading Strategy
- **First Load**: This file (QUICK-REFERENCE.md) for syntax and common patterns
- **Deep Dive**: Load specific numbered files (01-11) for detailed explanations
- **Framework Work**: Combine with FRAMEWORK-INTEGRATION-PATTERNS.md for Next.js/React/Prisma

### Prompt Patterns
```
"Load docs/kb/testing/jest/QUICK-REFERENCE.md and explain how to test this API route."

"Using the Jest Quick Reference, write tests for this component with RTL patterns."

"Reference the Prisma mocking patterns in QUICK-REFERENCE.md to test this database function."
```

### What to Avoid
- Don't use `done()` callbacks (use async/await)
- Don't mock entire React Testing Library
- Don't use `jest.resetModules()` in global hooks
- Don't use `--forceExit` to hide cleanup issues

### Common Bundles
1. **Component Testing**: QUICK-REFERENCE.md + 05-REACT-TESTING.md
2. **API Testing**: QUICK-REFERENCE.md + 06-API-TESTING.md + FRAMEWORK-INTEGRATION-PATTERNS.md
3. **Database Testing**: QUICK-REFERENCE.md + 07-DATABASE-TESTING.md + FRAMEWORK-INTEGRATION-PATTERNS.md

## Last Updated

2025-11-14
