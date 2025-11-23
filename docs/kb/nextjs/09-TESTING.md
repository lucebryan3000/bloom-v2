---
id: nextjs-09-testing
topic: nextjs
file_role: detailed
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [react, javascript, nextjs-basics]
related_topics: ['react', 'typescript', 'web']
embedding_keywords: [nextjs, testing]
last_reviewed: 2025-11-13
---

# Next.js Testing: Jest, RTL, and Playwright

**Part 9 of 11 - The Next.js Knowledge Base**

## Table of Contents
1. [Testing Overview](#testing-overview)
2. [Jest Configuration](#jest-configuration)
3. [React Testing Library](#react-testing-library)
4. [Component Testing](#component-testing)
5. [API Testing](#api-testing)
6. [Playwright E2E Tests](#playwright-e2e-tests)
7. [Snapshot Testing](#snapshot-testing)
8. [Coverage Reports](#coverage-reports)
9. [Testing Best Practices](#testing-best-practices)
10. [this project Testing Patterns](#this project-testing-patterns)

---

## Testing Overview

### Testing Pyramid

```
 /\
 /E2E\ ← Few, slow, high confidence
 /------\
 / API \ ← More, medium speed
 /----------\
 / Component \ ← Many, fast, focused
 /--------------\
```

### Test Types in Next.js

| Type | Tool | Purpose | Speed |
|------|------|---------|-------|
| Unit | Jest | Individual functions | ⚡⚡⚡ |
| Component | Jest + RTL | React components | ⚡⚡ |
| Integration | Jest | API routes | ⚡⚡ |
| E2E | Playwright | Full user flows | ⚡ |

---

## Jest Configuration

### Installation

```bash
npm install --save-dev jest jest-environment-jsdom @testing-library/react @testing-library/jest-dom
```

### jest.config.js (this project Configuration)

```javascript
// jest.config.js
const nextJest = require('next/jest');

const createJestConfig = nextJest({
 // Provide the path to your Next.js app
 dir: './',
});

const customJestConfig = {
 setupFilesAfterEnv: ['<rootDir>/jest.setup.js'],
 testEnvironment: 'jest-environment-jsdom',
 moduleNameMapper: {
 '^@/(.*)$': '<rootDir>/$1',
 },
 collectCoverageFrom: [
 'app/**/*.{js,jsx,ts,tsx}',
 'components/**/*.{js,jsx,ts,tsx}',
 'lib/**/*.{js,jsx,ts,tsx}',
 '!**/*.d.ts',
 '!**/node_modules/**',
 '!**/.next/**',
 ],
 testMatch: [
 '**/__tests__/**/*.{js,jsx,ts,tsx}',
 '**/*.{spec,test}.{js,jsx,ts,tsx}',
 ],
 testPathIgnorePatterns: [
 '<rootDir>/node_modules/',
 '<rootDir>/.next/',
 '<rootDir>/e2e/',
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

module.exports = createJestConfig(customJestConfig);
```

### jest.setup.js

```javascript
// jest.setup.js
import '@testing-library/jest-dom';

// Mock Next.js router
jest.mock('next/navigation', => ({
 useRouter {
 return {
 push: jest.fn,
 replace: jest.fn,
 prefetch: jest.fn,
 back: jest.fn,
 pathname: '/',
 query: {},
 asPath: '/',
 };
 },
 usePathname {
 return '/';
 },
 useSearchParams {
 return new URLSearchParams;
 },
}));

// Mock environment variables
process.env = {
...process.env,
 NEXT_PUBLIC_API_URL: 'http://localhost:3001/api',
};
```

### package.json Scripts

```json
{
 "scripts": {
 "test": "jest",
 "test:watch": "jest --watch",
 "test:coverage": "jest --coverage",
 "test:e2e": "playwright test",
 "test:unit": "jest --testPathPattern=__tests__",
 "test:integration": "jest --testPathPattern=tests/integration"
 }
}
```

---

## React Testing Library

### Basic Component Test

```typescript
// components/Button.test.tsx
import { render, screen, fireEvent } from '@testing-library/react';
import Button from './Button';

describe('Button', => {
 it('renders with text', => {
 render(<Button>Click me</Button>);
 expect(screen.getByText('Click me')).toBeInTheDocument;
 });

 it('calls onClick when clicked', => {
 const handleClick = jest.fn;
 render(<Button onClick={handleClick}>Click me</Button>);

 fireEvent.click(screen.getByText('Click me'));
 expect(handleClick).toHaveBeenCalledTimes(1);
 });

 it('applies variant classes', => {
 render(<Button variant="primary">Primary</Button>);
 const button = screen.getByText('Primary');
 expect(button).toHaveClass('bg-this project-primary');
 });

 it('disables when disabled prop is true', => {
 render(<Button disabled>Disabled</Button>);
 expect(screen.getByText('Disabled')).toBeDisabled;
 });
});
```

### Testing Async Components

```typescript
// components/UserProfile.test.tsx
import { render, screen, waitFor } from '@testing-library/react';
import UserProfile from './UserProfile';

// Mock fetch
global.fetch = jest.fn( =>
 Promise.resolve({
 json: => Promise.resolve({ name: 'John Doe', email: 'john@example.com' }),
 })
) as jest.Mock;

describe('UserProfile', => {
 it('loads and displays user data', async => {
 render(<UserProfile userId="123" />);

 // Initially shows loading
 expect(screen.getByText('Loading...')).toBeInTheDocument;

 // Wait for data to load
 await waitFor( => {
 expect(screen.getByText('John Doe')).toBeInTheDocument;
 });

 expect(screen.getByText('john@example.com')).toBeInTheDocument;
 });

 it('handles errors', async => {
 global.fetch = jest.fn( => Promise.reject(new Error('Failed to fetch')));

 render(<UserProfile userId="123" />);

 await waitFor( => {
 expect(screen.getByText('Error loading user')).toBeInTheDocument;
 });
 });
});
```

### Testing with User Events

```typescript
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import Form from './Form';

describe('Form', => {
 it('submits form with values', async => {
 const user = userEvent.setup;
 const handleSubmit = jest.fn;

 render(<Form onSubmit={handleSubmit} />);

 // Type into inputs
 await user.type(screen.getByLabelText('Name'), 'John Doe');
 await user.type(screen.getByLabelText('Email'), 'john@example.com');

 // Click submit
 await user.click(screen.getByRole('button', { name: /submit/i }));

 expect(handleSubmit).toHaveBeenCalledWith({
 name: 'John Doe',
 email: 'john@example.com',
 });
 });
});
```

---

## Component Testing

### Testing Server Components

```typescript
// app/posts/page.test.tsx
import { render, screen } from '@testing-library/react';
import PostsPage from './page';

// Mock data fetching
jest.mock('@/lib/db', => ({
 prisma: {
 post: {
 findMany: jest.fn.mockResolvedValue([
 { id: '1', title: 'Post 1', content: 'Content 1' },
 { id: '2', title: 'Post 2', content: 'Content 2' },
 ]),
 },
 },
}));

describe('PostsPage', => {
 it('renders list of posts', async => {
 const posts = await PostsPage;
 render(posts);

 expect(screen.getByText('Post 1')).toBeInTheDocument;
 expect(screen.getByText('Post 2')).toBeInTheDocument;
 });
});
```

### Testing Client Components

```typescript
// components/Counter.test.tsx
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import Counter from './Counter';

describe('Counter', => {
 it('increments count when button clicked', async => {
 const user = userEvent.setup;
 render(<Counter />);

 const button = screen.getByRole('button', { name: /increment/i });
 expect(screen.getByText('Count: 0')).toBeInTheDocument;

 await user.click(button);
 expect(screen.getByText('Count: 1')).toBeInTheDocument;

 await user.click(button);
 expect(screen.getByText('Count: 2')).toBeInTheDocument;
 });
});
```

### Testing Forms

```typescript
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import LoginForm from './LoginForm';

describe('LoginForm', => {
 it('validates email field', async => {
 const user = userEvent.setup;
 render(<LoginForm />);

 const emailInput = screen.getByLabelText(/email/i);
 const submitButton = screen.getByRole('button', { name: /login/i });

 await user.type(emailInput, 'invalid-email');
 await user.click(submitButton);

 expect(screen.getByText('Invalid email address')).toBeInTheDocument;
 });

 it('submits valid form', async => {
 const user = userEvent.setup;
 const handleSubmit = jest.fn;

 render(<LoginForm onSubmit={handleSubmit} />);

 await user.type(screen.getByLabelText(/email/i), 'user@example.com');
 await user.type(screen.getByLabelText(/password/i), 'password123');
 await user.click(screen.getByRole('button', { name: /login/i }));

 expect(handleSubmit).toHaveBeenCalledWith({
 email: 'user@example.com',
 password: 'password123',
 });
 });
});
```

---

## API Testing

### Testing Route Handlers

```typescript
// app/api/posts/route.test.ts
import { GET, POST } from './route';
import { prisma } from '@/lib/db';

jest.mock('@/lib/db', => ({
 prisma: {
 post: {
 findMany: jest.fn,
 create: jest.fn,
 },
 },
}));

describe('/api/posts', => {
 describe('GET', => {
 it('returns list of posts', async => {
 const mockPosts = [
 { id: '1', title: 'Post 1' },
 { id: '2', title: 'Post 2' },
 ];

 (prisma.post.findMany as jest.Mock).mockResolvedValue(mockPosts);

 const response = await GET(new Request('http://localhost:3000/api/posts'));
 const data = await response.json;

 expect(response.status).toBe(200);
 expect(data).toEqual(mockPosts);
 });
 });

 describe('POST', => {
 it('creates a new post', async => {
 const newPost = { title: 'New Post', content: 'Content' };
 const createdPost = { id: '1',...newPost };

 (prisma.post.create as jest.Mock).mockResolvedValue(createdPost);

 const request = new Request('http://localhost:3000/api/posts', {
 method: 'POST',
 body: JSON.stringify(newPost),
 });

 const response = await POST(request);
 const data = await response.json;

 expect(response.status).toBe(201);
 expect(data).toEqual(createdPost);
 });

 it('validates input', async => {
 const request = new Request('http://localhost:3000/api/posts', {
 method: 'POST',
 body: JSON.stringify({ title: '' }), // Invalid
 });

 const response = await POST(request);
 const data = await response.json;

 expect(response.status).toBe(400);
 expect(data.error).toBeDefined;
 });
 });
});
```

---

## Playwright E2E Tests

### Playwright Configuration (this project uses this)

```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
 testDir: './e2e',
 fullyParallel: true,
 forbidOnly: !!process.env.CI,
 retries: process.env.CI ? 2: 0,
 workers: process.env.CI ? 1: undefined,
 reporter: [
 ['html', { outputFolder: '_build/test/reports/playwright-html' }],
 ['json', { outputFile: '_build/test/reports/playwright-results.json' }],
 ],
 use: {
 baseURL: 'http://localhost:3001',
 trace: 'on-first-retry',
 screenshot: 'only-on-failure',
 },
 projects: [
 {
 name: 'chromium',
 use: {...devices['Desktop Chrome'] },
 },
 {
 name: 'firefox',
 use: {...devices['Desktop Firefox'] },
 },
 {
 name: 'webkit',
 use: {...devices['Desktop Safari'] },
 },
 ],
 webServer: {
 command: 'npm run dev',
 url: 'http://localhost:3001',
 reuseExistingServer: !process.env.CI,
 },
});
```

### Basic E2E Test

```typescript
// e2e/home.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Home Page', => {
 test('loads and displays content', async ({ page }) => {
 await page.goto('/');

 await expect(page).toHaveTitle(/this application/);
 await expect(page.getByRole('heading', { name: /welcome/i })).toBeVisible;
 });

 test('navigates to about page', async ({ page }) => {
 await page.goto('/');

 await page.getByRole('link', { name: /about/i }).click;

 await expect(page).toHaveURL('/about');
 await expect(page.getByRole('heading', { name: /about/i })).toBeVisible;
 });
});
```

### Testing Forms (E2E)

```typescript
// e2e/contact-form.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Contact Form', => {
 test('submits form successfully', async ({ page }) => {
 await page.goto('/contact');

 // Fill form
 await page.getByLabel('Name').fill('John Doe');
 await page.getByLabel('Email').fill('john@example.com');
 await page.getByLabel('Message').fill('Hello, this is a test message');

 // Submit
 await page.getByRole('button', { name: /submit/i }).click;

 // Verify success
 await expect(page.getByText('Thank you for your message')).toBeVisible;
 });

 test('shows validation errors', async ({ page }) => {
 await page.goto('/contact');

 // Submit without filling
 await page.getByRole('button', { name: /submit/i }).click;

 // Verify errors
 await expect(page.getByText('Name is required')).toBeVisible;
 await expect(page.getByText('Email is required')).toBeVisible;
 });
});
```

### Testing Authentication

```typescript
// e2e/auth.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Authentication', => {
 test('logs in successfully', async ({ page }) => {
 await page.goto('/login');

 await page.getByLabel('Email').fill('user@example.com');
 await page.getByLabel('Password').fill('password123');
 await page.getByRole('button', { name: /login/i }).click;

 await expect(page).toHaveURL('/dashboard');
 await expect(page.getByText('Welcome back')).toBeVisible;
 });

 test('protects dashboard route', async ({ page }) => {
 await page.goto('/dashboard');

 // Should redirect to login
 await expect(page).toHaveURL('/login');
 });
});
```

---

## Snapshot Testing

### Component Snapshot

```typescript
import { render } from '@testing-library/react';
import Button from './Button';

describe('Button Snapshots', => {
 it('matches snapshot for default variant', => {
 const { container } = render(<Button>Click me</Button>);
 expect(container.firstChild).toMatchSnapshot;
 });

 it('matches snapshot for primary variant', => {
 const { container } = render(<Button variant="primary">Primary</Button>);
 expect(container.firstChild).toMatchSnapshot;
 });
});
```

### Updating Snapshots

```bash
# Update all snapshots
npm test -- -u

# Update specific snapshot
npm test -- -u Button.test.tsx
```

---

## Coverage Reports

### Generate Coverage

```bash
# Run tests with coverage
npm run test:coverage

# Open HTML report
open coverage/lcov-report/index.html
```

### Coverage Configuration

```javascript
// jest.config.js
module.exports = {
 collectCoverageFrom: [
 'app/**/*.{js,jsx,ts,tsx}',
 'components/**/*.{js,jsx,ts,tsx}',
 'lib/**/*.{js,jsx,ts,tsx}',
 '!**/*.d.ts',
 '!**/node_modules/**',
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

---

## Testing Best Practices

### ✅ DO

1. **Test user behavior, not implementation**
```typescript
// ✅ Good
expect(screen.getByRole('button', { name: /submit/i })).toBeEnabled;

// ❌ Bad
expect(component.state.isValid).toBe(true);
```

2. **Use semantic queries**
```typescript
// ✅ Good
screen.getByRole('button', { name: /submit/i })
screen.getByLabelText('Email')
screen.getByText('Welcome')

// ❌ Bad
screen.getByTestId('submit-button')
```

3. **Test accessibility**
```typescript
expect(screen.getByRole('button')).toBeInTheDocument;
expect(screen.getByLabelText('Email')).toHaveAccessibleName;
```

4. **Mock external dependencies**
```typescript
jest.mock('@/lib/db');
jest.mock('next/navigation');
```

5. **Use async utilities**
```typescript
await waitFor( => {
 expect(screen.getByText('Loaded')).toBeInTheDocument;
});
```

### ❌ DON'T

1. **Don't test implementation details**
```typescript
// ❌ Bad
expect(wrapper.find('.class-name')).toHaveLength(1);

// ✅ Good
expect(screen.getByRole('heading')).toHaveTextContent('Title');
```

2. **Don't use unnecessary test IDs**
```typescript
// ❌ Bad
<button data-testid="submit">Submit</button>

// ✅ Good
<button type="submit">Submit</button>
// Then: screen.getByRole('button', { name: /submit/i })
```

3. **Don't ignore async warnings**
```typescript
// ❌ Bad
fireEvent.click(button);
expect(screen.getByText('Success')).toBeInTheDocument; // May fail

// ✅ Good
await user.click(button);
await waitFor( => {
 expect(screen.getByText('Success')).toBeInTheDocument;
});
```

---

## this project Testing Patterns

### ROI Calculator Tests (this project Example)

```typescript
// __tests__/lib/roi/calculator.test.ts
import { calculateROI } from '@/lib/roi/calculator';

describe('ROI Calculator', => {
 it('calculates NPV correctly', => {
 const result = calculateROI({
 investment: 100000,
 benefits: [30000, 40000, 50000],
 discountRate: 0.1,
 });

 expect(result.npv).toBeCloseTo(5394.67, 2);
 });

 it('calculates IRR correctly', => {
 const result = calculateROI({
 investment: 100000,
 benefits: [30000, 40000, 50000],
 });

 expect(result.irr).toBeCloseTo(0.12, 2);
 });
});
```

---

## Summary

### Test Coverage by Layer
- **Unit Tests**: 80%+ coverage
- **Component Tests**: Critical UI
- **Integration Tests**: API routes
- **E2E Tests**: Critical paths

### this project Testing Stack
- Jest + React Testing Library (unit/component)
- Playwright 1.56 (E2E)
- 80% coverage threshold
- CI/CD integration

---

**Next**: [10-ADVANCED.md](./10-ADVANCED.md) - Learn advanced Next.js patterns

**Last Updated**: November 9, 2025
**Status**: Production-Ready ✅
