---
id: testing-readme
topic: testing
file_role: overview
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: []
related_topics: ['testing']
embedding_keywords: [testing, overview, introduction, getting-started]
last_reviewed: 2025-11-13
---

# Testing Comprehensive Knowledge Base

Welcome to the comprehensive testing knowledge base for Jest, React Testing Library, Playwright, and integration testing. This KB covers all testing approaches used in this application.

## 📚 Documentation Structure (10-Part Series)

### **Quick Navigation**
- **<!-- [INDEX.md](./INDEX.md) -->** - Complete index with learning paths
- **<!-- [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) -->** - Cheat sheet for quick lookups
- **<!-- [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md) -->** - this project test patterns
- **<!-- <!-- <!-- [TESTING-HANDBOOK.md](./TESTING-HANDBOOK.md) --> (file not created) --> (File not yet created) -->** - Comprehensive reference

### **Core Topics (10 Files)**

| # | Topic | File | Focus |
|---|-------|------|-------|
| 1 | **Fundamentals** | <!-- <!-- <!-- [01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md) --> (file not created) --> (File not yet created) --> | Testing principles, types |
| 2 | **Jest** | <!-- <!-- <!-- <!-- [02-JEST.md](./02-JEST.md) --> (file not created) --> (file not created) --> (File not yet created) --> | Unit testing with Jest |
| 3 | **React Testing** | <!-- <!-- <!-- <!-- [03-REACT-TESTING-LIBRARY.md](./03-REACT-TESTING-LIBRARY.md) --> (file not created) --> (file not created) --> (File not yet created) --> | Component testing |
| 4 | **Playwright** | <!-- <!-- <!-- <!-- [04-PLAYWRIGHT.md](./04-PLAYWRIGHT.md) --> (file not created) --> (file not created) --> (File not yet created) --> | E2E testing |
| 5 | **Integration** | <!-- <!-- <!-- [05-INTEGRATION-TESTING.md](./05-INTEGRATION-TESTING.md) --> (file not created) --> (File not yet created) --> | API, database tests |
| 6 | **Mocking** | <!-- <!-- <!-- <!-- [06-MOCKING.md](./06-MOCKING.md) --> (file not created) --> (file not created) --> (File not yet created) --> | Mocks, stubs, spies |
| 7 | **Async Testing** | <!-- <!-- <!-- <!-- [07-ASYNC-TESTING.md](./07-ASYNC-TESTING.md) --> (file not created) --> (file not created) --> (File not yet created) --> | Promises, timers |
| 8 | **Coverage** | <!-- <!-- <!-- [08-COVERAGE.md](./08-COVERAGE.md) --> (file not created) --> (File not yet created) --> | Code coverage |
| 9 | **CI/CD** | <!-- <!-- <!-- [09-CI-CD.md](./09-CI-CD.md) --> (file not created) --> (File not yet created) --> | Continuous integration |
| 10 | **Best Practices** | <!-- <!-- <!-- [10-BEST-PRACTICES.md](./10-BEST-PRACTICES.md) --> (file not created) --> (File not yet created) --> | Patterns, anti-patterns |

---

## 🚀 Getting Started

### Installation
```bash
# Jest + React Testing Library (already in this project)
npm install -D jest @testing-library/react @testing-library/jest-dom
npm install -D @testing-library/user-event

# Playwright (already in this project)
npm install -D @playwright/test
npx playwright install
```

### First Unit Test
```typescript
// __tests__/utils/math.test.ts
import { add } from '@/lib/utils/math';

describe('add', => {
 it('adds two numbers', => {
 expect(add(2, 3)).toBe(5);
 });

 it('handles negative numbers', => {
 expect(add(-1, 1)).toBe(0);
 });
});
```

### First Component Test
```typescript
// __tests__/components/Button.test.tsx
import { render, screen, fireEvent } from '@testing-library/react';
import { Button } from '@/components/ui/Button';

describe('Button', => {
 it('renders with text', => {
 render(<Button>Click me</Button>);
 expect(screen.getByText('Click me')).toBeInTheDocument;
 });

 it('calls onClick when clicked', => {
 const handleClick = jest.fn;
 render(<Button onClick={handleClick}>Click</Button>);

 fireEvent.click(screen.getByRole('button'));
 expect(handleClick).toHaveBeenCalledTimes(1);
 });
});
```

### First E2E Test
```typescript
// tests/e2e/home.spec.ts
import { test, expect } from '@playwright/test';

test('home page loads', async ({ page }) => {
 await page.goto('/');
 await expect(page.locator('h1')).toContainText('Welcome');
});

test('can navigate to settings', async ({ page }) => {
 await page.goto('/');
 await page.click('text=Settings');
 await expect(page).toHaveURL('/settings');
});
```

---

## 📋 Common Tasks

### "I need to test a function"
1. Read: **<!-- <!-- <!-- <!-- [02-JEST.md](./02-JEST.md) --> (file not created) --> (file not created) --> (File not yet created) -->**
2. Examples: **[QUICK-REFERENCE.md - Jest](./QUICK-REFERENCE.md#jest)**

### "I need to test a component"
1. Read: **<!-- <!-- <!-- <!-- [03-REACT-TESTING-LIBRARY.md](./03-REACT-TESTING-LIBRARY.md) --> (file not created) --> (file not created) --> (File not yet created) -->**
2. Patterns: **[FRAMEWORK-INTEGRATION-PATTERNS.md - Components](./FRAMEWORK-INTEGRATION-PATTERNS.md#component-tests)**

### "I need to test user flows"
1. Read: **<!-- <!-- <!-- <!-- [04-PLAYWRIGHT.md](./04-PLAYWRIGHT.md) --> (file not created) --> (file not created) --> (File not yet created) -->**
2. Examples: **[FRAMEWORK-INTEGRATION-PATTERNS.md - E2E](./FRAMEWORK-INTEGRATION-PATTERNS.md#e2e-tests)**

### "I need to mock an API"
1. Read: **<!-- <!-- <!-- <!-- [06-MOCKING.md](./06-MOCKING.md) --> (file not created) --> (file not created) --> (File not yet created) -->**
2. Patterns: **[QUICK-REFERENCE.md - Mocking](./QUICK-REFERENCE.md#mocking)**

### "I need to test async code"
1. Read: **<!-- <!-- <!-- <!-- [07-ASYNC-TESTING.md](./07-ASYNC-TESTING.md) --> (file not created) --> (file not created) --> (File not yet created) -->**
2. Examples: **[FRAMEWORK-INTEGRATION-PATTERNS.md - Async](./FRAMEWORK-INTEGRATION-PATTERNS.md#async-tests)**

---

## 🎯 Testing Pyramid

```
 /\
 / \ E2E Tests (Playwright)
 /____\ - Few, slow, high confidence
 / \ - Test critical user paths
 / \
 /__________\ Integration Tests (API, DB)
 / \ - Moderate number, moderate speed
 / \ - Test feature integration
 /________________\
/ \ Unit Tests (Jest)
 - Many, fast, focused
 - Test individual functions
```

### Test Distribution (this project Target)
- **Unit Tests**: 70% (fast, focused)
- **Integration Tests**: 20% (moderate)
- **E2E Tests**: 10% (slow, critical paths)

---

## 🎯 Key Principles

### 1. **Test Behavior, Not Implementation**
```typescript
// ✅ Good - Test what user sees
test('shows error message on invalid email', async => {
 render(<LoginForm />);
 await userEvent.type(screen.getByLabelText('Email'), 'invalid');
 await userEvent.click(screen.getByRole('button', { name: /submit/i }));

 expect(screen.getByText(/invalid email/i)).toBeInTheDocument;
});

// ❌ Bad - Test implementation details
test('sets emailError state', => {
 const { result } = renderHook( => useLoginForm);
 act( => {
 result.current.setEmail('invalid');
 });

 expect(result.current.emailError).toBe('Invalid email');
});
```

### 2. **Write Independent Tests**
```typescript
// ✅ Good - Each test is independent
describe('Counter', => {
 it('starts at 0', => {
 render(<Counter />);
 expect(screen.getByText('0')).toBeInTheDocument;
 });

 it('increments when clicked', => {
 render(<Counter />);
 fireEvent.click(screen.getByRole('button'));
 expect(screen.getByText('1')).toBeInTheDocument;
 });
});

// ❌ Bad - Tests depend on each other
let counter: number;
it('starts at 0', => {
 counter = 0;
 expect(counter).toBe(0);
});
it('increments', => {
 counter++; // Depends on previous test
 expect(counter).toBe(1);
});
```

### 3. **Use Descriptive Test Names**
```typescript
// ✅ Good - Clear what's being tested
describe('SessionStore', => {
 describe('addMessage', => {
 it('adds message to messages array', => {});
 it('updates lastMessageTime', => {});
 it('throws error if session not found', => {});
 });
});

// ❌ Bad - Unclear test purpose
describe('SessionStore', => {
 it('test 1', => {});
 it('works', => {});
 it('does stuff', => {});
});
```

### 4. **Clean Up After Tests**
```typescript
// ✅ Good - Cleanup in afterEach
describe('Database tests', => {
 afterEach(async => {
 await prisma.session.deleteMany;
 await prisma.user.deleteMany;
 });

 it('creates session', async => {
 // Test creates data
 });
});

// ❌ Bad - No cleanup, tests pollute database
describe('Database tests', => {
 it('creates session', async => {
 await prisma.session.create({ data: testData });
 // Data left in database
 });
});
```

### 5. **Mock External Dependencies**
```typescript
// ✅ Good - Mock external API
jest.mock('@/lib/api/anthropic', => ({
 chat: jest.fn.mockResolvedValue({ message: 'Hello' }),
}));

test('displays AI response', async => {
 render(<Chat />);
 // Test without calling real API
});

// ❌ Bad - Call real external services
test('displays AI response', async => {
 render(<Chat />);
 // Makes real API call - slow, flaky, costs money
});
```

---

## 📊 Test Commands (this project)

```bash
# Run all tests
npm test

# Unit tests only
npm run test:unit

# Integration tests
npm run test:integration

# E2E tests (Playwright)
npm run test:e2e

# Watch mode
npm test -- --watch

# Coverage
npm run test:coverage

# Specific file
npm test Button.test.tsx

# Update snapshots
npm test -- -u
```

---

## ⚠️ Common Issues & Solutions

### "Tests are flaky"
**Cause**: Race conditions, timing issues
**Fix**: Use proper async utilities
```typescript
// ✅ Good - Wait for elements
await waitFor( => {
 expect(screen.getByText('Loaded')).toBeInTheDocument;
});

// ❌ Bad - No waiting
expect(screen.getByText('Loaded')).toBeInTheDocument; // May fail
```

### "Can't test async code"
**Cause**: Not awaiting promises
**Fix**: Use async/await
```typescript
// ✅ Good
test('loads data', async => {
 render(<DataComponent />);
 await waitFor( => {
 expect(screen.getByText('Data loaded')).toBeInTheDocument;
 });
});

// ❌ Bad
test('loads data', => {
 render(<DataComponent />);
 expect(screen.getByText('Data loaded')).toBeInTheDocument; // Fails
});
```

### "Mocks don't work"
**Cause**: Mock order or hoisting issues
**Fix**: Place mocks at top
```typescript
// ✅ Good - Mock before imports
jest.mock('@/lib/api');
import { api } from '@/lib/api';

// ❌ Bad - Mock after imports
import { api } from '@/lib/api';
jest.mock('@/lib/api'); // Too late
```

---

## 📚 Files in This Directory

```
docs/kb/testing/
├── README.md # This file
├── INDEX.md # Complete index
├── QUICK-REFERENCE.md # Cheat sheet
├── TESTING-HANDBOOK.md # Full reference
├── FRAMEWORK-INTEGRATION-PATTERNS.md # this project patterns
├── 01-FUNDAMENTALS.md # Testing basics
├── 02-JEST.md # Jest unit testing
├── 03-REACT-TESTING-LIBRARY.md # Component testing
├── 04-PLAYWRIGHT.md # E2E testing
├── 05-INTEGRATION-TESTING.md # Integration tests
├── 06-MOCKING.md # Mocks and stubs
├── 07-ASYNC-TESTING.md # Async patterns
├── 08-COVERAGE.md # Code coverage
├── 09-CI-CD.md # CI/CD integration
└── 10-BEST-PRACTICES.md # Best practices
```

---

## 🎓 External Resources

- **Jest Docs**: https://jestjs.io/docs/getting-started
- **React Testing Library**: https://testing-library.com/react
- **Playwright Docs**: https://playwright.dev
- **Testing Best Practices**: https://testingjavascript.com

---

**Last Updated**: November 9, 2025
**Jest Version**: 29.7.0
**Playwright Version**: 1.56.0
**Status**: Production-Ready

Happy testing! 🧪
