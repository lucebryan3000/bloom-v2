# Node.js Testing

```yaml
id: nodejs_09_testing
topic: Node.js
file_role: Testing with Jest, unit tests, integration tests, mocking, TDD
profile: full
difficulty_level: intermediate
kb_version: v3.1
prerequisites:
  - Fundamentals (01-FUNDAMENTALS.md)
  - Async Programming (02-ASYNC-PROGRAMMING.md)
  - Modules (04-MODULES.md)
related_topics:
  - Best Practices (11-BEST-PRACTICES.md)
  - Error Handling (08-ERROR-HANDLING.md)
embedding_keywords:
  - nodejs testing
  - jest
  - unit tests
  - integration tests
  - mocking
  - test driven development
  - tdd
last_reviewed: 2025-11-17
```

## Testing Overview

**Testing strategies:**

1. **Unit Tests** - Test individual functions/modules
2. **Integration Tests** - Test module interactions
3. **End-to-End Tests** - Test complete workflows
4. **Mocking** - Isolate code under test

**Popular test frameworks:**
- **Jest** - Zero-config,built-in mocking (recommended)
- **Mocha** - Flexible, requires assertion library
- **AVA** - Minimal, concurrent test runner
- **Tap** - Test Anything Protocol
- **Vitest** - Fast, Vite-powered

## Jest Setup

### Installation

```bash
# Install Jest
npm install --save-dev jest

# TypeScript support
npm install --save-dev @types/jest ts-jest

# Configure Jest for TypeScript
npx ts-jest config:init
```

### package.json

```json
{
  "scripts": {
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage"
  },
  "jest": {
    "testEnvironment": "node",
    "coveragePathIgnorePatterns": ["/node_modules/"],
    "testMatch": ["**/__tests__/**/*.test.js"]
  }
}
```

## Unit Tests

### Basic Test Structure

```javascript
// math.js
export function add(a, b) {
  return a + b;
}

export function subtract(a, b) {
  return a - b;
}

export function divide(a, b) {
  if (b === 0) {
    throw new Error('Division by zero');
  }
  return a / b;
}

// math.test.js
import { add, subtract, divide } from './math.js';

describe('Math functions', () => {
  describe('add', () => {
    it('should add two positive numbers', () => {
      expect(add(2, 3)).toBe(5);
    });

    it('should add negative numbers', () => {
      expect(add(-2, -3)).toBe(-5);
    });

    it('should handle zero', () => {
      expect(add(0, 5)).toBe(5);
    });
  });

  describe('subtract', () => {
    it('should subtract two numbers', () => {
      expect(subtract(5, 3)).toBe(2);
    });
  });

  describe('divide', () => {
    it('should divide two numbers', () => {
      expect(divide(6, 2)).toBe(3);
    });

    it('should throw error on division by zero', () => {
      expect(() => divide(6, 0)).toThrow('Division by zero');
    });
  });
});
```

### Jest Matchers

```javascript
// Equality
expect(value).toBe(4); // Strict equality (===)
expect(value).toEqual({ name: 'Alice' }); // Deep equality
expect(value).not.toBe(null);

// Truthiness
expect(value).toBeTruthy();
expect(value).toBeFalsy();
expect(value).toBeNull();
expect(value).toBeUndefined();
expect(value).toBeDefined();

// Numbers
expect(value).toBeGreaterThan(3);
expect(value).toBeGreaterThanOrEqual(3.5);
expect(value).toBeLessThan(5);
expect(value).toBeLessThanOrEqual(4.5);
expect(value).toBeCloseTo(0.3); // Floating point

// Strings
expect(string).toMatch(/pattern/);
expect(string).toContain('substring');

// Arrays
expect(array).toContain('item');
expect(array).toHaveLength(3);
expect(array).toEqual(expect.arrayContaining([1, 2]));

// Objects
expect(object).toHaveProperty('key');
expect(object).toHaveProperty('key', 'value');
expect(object).toMatchObject({ key: 'value' });

// Exceptions
expect(() => fn()).toThrow();
expect(() => fn()).toThrow(Error);
expect(() => fn()).toThrow('error message');

// Promises
await expect(promise).resolves.toBe(value);
await expect(promise).rejects.toThrow(Error);
```

## Async Testing

### Testing Promises

```javascript
// user-service.js
export async function fetchUser(id) {
  const response = await fetch(`/api/users/${id}`);
  if (!response.ok) {
    throw new Error('User not found');
  }
  return response.json();
}

// user-service.test.js
import { fetchUser } from './user-service.js';

describe('fetchUser', () => {
  it('should fetch user by id', async () => {
    const user = await fetchUser(1);
    expect(user).toHaveProperty('id', 1);
    expect(user).toHaveProperty('name');
  });

  it('should throw error for invalid user', async () => {
    await expect(fetchUser(999)).rejects.toThrow('User not found');
  });

  // Alternative syntax
  it('should fetch user (promise syntax)', () => {
    return fetchUser(1).then(user => {
      expect(user.id).toBe(1);
    });
  });
});
```

### Testing Callbacks

```javascript
// file-reader.js
import fs from 'fs';

export function readConfig(callback) {
  fs.readFile('config.json', 'utf8', (err, data) => {
    if (err) {
      callback(err);
    } else {
      try {
        const config = JSON.parse(data);
        callback(null, config);
      } catch (parseErr) {
        callback(parseErr);
      }
    }
  });
}

// file-reader.test.js
import { readConfig } from './file-reader.js';

describe('readConfig', () => {
  it('should read config file', (done) => {
    readConfig((err, config) => {
      expect(err).toBeNull();
      expect(config).toHaveProperty('version');
      done(); // Signal test complete
    });
  });

  it('should handle file not found', (done) => {
    readConfig((err, config) => {
      expect(err).toBeTruthy();
      expect(config).toBeUndefined();
      done();
    });
  });
});
```

## Mocking

### Mock Functions

```javascript
// ✅ GOOD - Mock function
const mockFn = jest.fn();

mockFn('arg1', 'arg2');
mockFn('arg3');

expect(mockFn).toHaveBeenCalled();
expect(mockFn).toHaveBeenCalledTimes(2);
expect(mockFn).toHaveBeenCalledWith('arg1', 'arg2');
expect(mockFn).toHaveBeenLastCalledWith('arg3');

// Mock return values
const mockFn = jest.fn()
  .mockReturnValue(42)
  .mockReturnValueOnce(1)
  .mockReturnValueOnce(2);

console.log(mockFn()); // 1
console.log(mockFn()); // 2
console.log(mockFn()); // 42

// Mock async functions
const mockAsync = jest.fn()
  .mockResolvedValue('success')
  .mockRejectedValueOnce(new Error('fail'));

await expect(mockAsync()).rejects.toThrow('fail');
await expect(mockAsync()).resolves.toBe('success');
```

### Mock Modules

```javascript
// api.js
export async function fetchData() {
  const response = await fetch('/api/data');
  return response.json();
}

// user-controller.js
import { fetchData } from './api.js';

export async function getUsers() {
  const data = await fetchData();
  return data.users;
}

// user-controller.test.js
import { getUsers } from './user-controller.js';
import { fetchData } from './api.js';

// Mock the entire module
jest.mock('./api.js');

describe('getUsers', () => {
  it('should return users from API', async () => {
    // Setup mock
    fetchData.mockResolvedValue({
      users: [{ id: 1, name: 'Alice' }],
    });

    const users = await getUsers();

    expect(users).toHaveLength(1);
    expect(users[0]).toEqual({ id: 1, name: 'Alice' });
    expect(fetchData).toHaveBeenCalledTimes(1);
  });
});
```

### Partial Mocks

```javascript
// Mock specific functions
jest.mock('./api.js', () => ({
  ...jest.requireActual('./api.js'),
  fetchData: jest.fn(),
}));

// Mock with implementation
jest.mock('./logger.js', () => ({
  log: jest.fn((msg) => console.log(`[MOCK] ${msg}`)),
  error: jest.fn(),
}));
```

### Mocking fs Module

```javascript
import fs from 'fs';

jest.mock('fs');

describe('File operations', () => {
  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should read file', async () => {
    const mockData = 'file contents';
    fs.promises.readFile.mockResolvedValue(mockData);

    const data = await readConfigFile();

    expect(data).toBe(mockData);
    expect(fs.promises.readFile).toHaveBeenCalledWith('config.json', 'utf8');
  });

  it('should handle file not found', async () => {
    const error = new Error('ENOENT');
    error.code = 'ENOENT';
    fs.promises.readFile.mockRejectedValue(error);

    await expect(readConfigFile()).rejects.toThrow('ENOENT');
  });
});
```

## Test Lifecycle

```javascript
describe('Test lifecycle', () => {
  beforeAll(() => {
    // Runs once before all tests
    console.log('Setup database connection');
  });

  afterAll(() => {
    // Runs once after all tests
    console.log('Close database connection');
  });

  beforeEach(() => {
    // Runs before each test
    console.log('Clear test data');
  });

  afterEach(() => {
    // Runs after each test
    jest.clearAllMocks();
  });

  it('test 1', () => {
    expect(true).toBe(true);
  });

  it('test 2', () => {
    expect(true).toBe(true);
  });
});
```

## Integration Tests

```javascript
// database.js
export class Database {
  async connect() { /* ... */ }
  async query(sql) { /* ... */ }
  async close() { /* ... */ }
}

// user-repository.js
export class UserRepository {
  constructor(db) {
    this.db = db;
  }

  async findById(id) {
    const rows = await this.db.query('SELECT * FROM users WHERE id = ?', [id]);
    return rows[0];
  }

  async create(user) {
    await this.db.query('INSERT INTO users (name, email) VALUES (?, ?)', [
      user.name,
      user.email,
    ]);
  }
}

// user-repository.test.js
import { Database } from './database.js';
import { UserRepository } from './user-repository.js';

describe('UserRepository integration tests', () => {
  let db;
  let repository;

  beforeAll(async () => {
    db = new Database();
    await db.connect();
    repository = new UserRepository(db);
  });

  afterAll(async () => {
    await db.close();
  });

  beforeEach(async () => {
    // Clear test data
    await db.query('DELETE FROM users');
  });

  it('should create and find user', async () => {
    await repository.create({ name: 'Alice', email: 'alice@example.com' });

    const user = await repository.findById(1);

    expect(user).toMatchObject({
      name: 'Alice',
      email: 'alice@example.com',
    });
  });
});
```

## Snapshot Testing

```javascript
// component.js
export function generateHTML(data) {
  return `
    <div class="user-card">
      <h2>${data.name}</h2>
      <p>${data.email}</p>
    </div>
  `.trim();
}

// component.test.js
import { generateHTML } from './component.js';

describe('generateHTML', () => {
  it('should match snapshot', () => {
    const html = generateHTML({ name: 'Alice', email: 'alice@example.com' });
    expect(html).toMatchSnapshot();
  });
});

// First run creates snapshot file
// Subsequent runs compare against snapshot
// Update snapshots with: jest --updateSnapshot
```

## Coverage

```bash
# Run tests with coverage
npm run test:coverage

# View coverage report
open coverage/lcov-report/index.html
```

```javascript
// jest.config.js
export default {
  collectCoverageFrom: [
    'src/**/*.{js,ts}',
    '!src/**/*.test.{js,ts}',
    '!src/**/__tests__/**',
  ],
  coverageThresholds: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80,
    },
  },
};
```

## Test-Driven Development (TDD)

```javascript
// 1. Write test first (RED)
describe('Calculator', () => {
  it('should add two numbers', () => {
    const calc = new Calculator();
    expect(calc.add(2, 3)).toBe(5);
  });
});

// 2. Write minimal code to pass (GREEN)
class Calculator {
  add(a, b) {
    return a + b;
  }
}

// 3. Refactor (REFACTOR)
class Calculator {
  add(a, b) {
    this.validateNumber(a);
    this.validateNumber(b);
    return a + b;
  }

  validateNumber(n) {
    if (typeof n !== 'number') {
      throw new TypeError('Must be a number');
    }
  }
}
```

## AI Pair Programming Notes

**When writing tests:**

1. **Test behavior, not implementation** - Test what, not how
2. **One assertion per test** - Keeps tests focused
3. **Use descriptive test names** - Explain what should happen
4. **Arrange-Act-Assert** - Structure tests clearly
5. **Mock external dependencies** - Isolate code under test
6. **Test edge cases** - null, undefined, empty, large values
7. **Clean up after tests** - Reset state, close connections
8. **Run tests in isolation** - Tests shouldn't depend on each other
9. **Aim for high coverage** - But don't chase 100%
10. **Write tests first** (TDD) - Drives better design

**Common testing mistakes:**
- Testing implementation details
- Too many assertions in one test
- Not testing error cases
- Forgetting to clean up resources
- Sharing state between tests
- Mocking too much (testing mocks, not code)
- Not running tests before commits
- Ignoring failing tests
- Poor test naming (test1, test2)
- Not testing async code properly

## Next Steps

1. **10-PERFORMANCE.md** - Performance testing
2. **11-BEST-PRACTICES.md** - Testing best practices
3. **08-ERROR-HANDLING.md** - Testing error conditions

## Additional Resources

- Jest Documentation: https://jestjs.io/
- Testing Library: https://testing-library.com/
- Test Coverage: https://istanbul.js.org/
- TDD Guide: https://testdriven.io/
- Mocha: https://mochajs.org/
