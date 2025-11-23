# Appmelia Bloom - Comprehensive Test Plan & Implementation

**Mission**: Build a complete, production-ready test suite for Appmelia Bloom with automated E2E, integration, and unit tests. Fix trivial bugs discovered during testing and document architectural risks for team review.

---

## CURRENT STATE ASSESSMENT

### ✅ What's Already Done
- **Test Framework**: Jest 29.7.0 configured with React Testing Library
- **Coverage Target**: 70% (branches, functions, lines, statements)
- **Existing Tests** (4 files, ~800 lines):
  - `__tests__/lib/roi/calculator.test.ts` - ROI calculations ✓
  - `__tests__/lib/roi/sensitivityAnalysis.test.ts` - Sensitivity analysis ✓
  - `__tests__/lib/melissa/metricsExtractor.test.ts` - Metrics extraction ✓
  - `__tests__/monitoring/analytics.test.ts` - Analytics tracking ✓

### ❌ Critical Gaps
- **0 API route tests** - All 15+ endpoints untested
- **0 Component tests** - ChatInterface, SettingsMenu, etc. untested
- **0 E2E tests** - Playwright installed but not configured
- **0 Database tests** - Prisma operations untested
- **0 Store tests** - Zustand stores (sessionStore, brandingStore) untested
- **No integration tests** - Full user flows not verified

### 📊 Coverage Estimate
Current: ~15-20% | Target: 70% | Gap: ~50%

---

## OBJECTIVES

1. **Setup Playwright E2E** - Configure and implement critical user journeys
2. **Test All API Routes** - Integration tests for 15+ endpoints
3. **Test Core Components** - ChatInterface, SettingsMenu, branding pages
4. **Test Database Layer** - Prisma operations and data integrity
5. **Test State Management** - Zustand stores and state transitions
6. **Quick Bug Fixes** - Fix trivial issues (broken links, null checks, selectors)
7. **Risk Documentation** - Log architectural/security issues for team review
8. **CI/CD Integration** - Automated testing in GitHub Actions

---

## DELIVERABLES

All artifacts go under `_build/test/`:

```
_build/test/
├── PLAN.md                    # This plan with execution notes
├── REPORT.md                  # Final test results, coverage, findings
├── CHANGELOG.md               # All changes made during testing
├── BACKLOG.md                 # Architectural/medium-large issues for team
├── e2e/                       # Playwright E2E tests
│   ├── playwright.config.ts
│   ├── fixtures/
│   ├── helpers/
│   └── specs/
│       ├── chat-flow.spec.ts
│       ├── settings.spec.ts
│       ├── branding.spec.ts
│       └── roi-report.spec.ts
├── integration/               # API integration tests
│   ├── api/
│   │   ├── melissa.test.ts
│   │   ├── sessions.test.ts
│   │   ├── roi.test.ts
│   │   └── branding.test.ts
│   └── db/
│       └── prisma.test.ts
├── unit/                      # Additional unit tests
│   ├── components/
│   ├── stores/
│   └── lib/
├── accessibility/             # Axe-core a11y tests
│   └── a11y.spec.ts
├── performance/               # k6 performance tests
│   └── load-test.js
└── fixtures/                  # Shared test data
    ├── users.json
    ├── sessions.json
    └── roi-data.json
```

---

## CRITICAL FLOWS TO TEST (Priority Order)

### 1. **Melissa.ai Chat Flow** (HIGHEST PRIORITY)
**Files**: `app/api/melissa/chat/route.ts`, `components/bloom/ChatInterface.tsx`, `lib/melissa/agent.ts`

**Test Scenarios**:
- Start new session → greeting message appears
- Progress through phases: Greeting → Discovery → Metrics → Validation → Completion
- User input → AI response → metrics extraction → confidence scoring
- Error handling: rate limiting, API failures, invalid input
- Session state persistence across page refreshes
- Message streaming functionality

**E2E Test**: `e2e/specs/chat-flow.spec.ts`
```typescript
test('complete 15-minute workshop flow', async ({ page }) => {
  // Navigate to demo page
  // Start new session
  // Answer discovery questions
  // Verify phase transitions
  // Reach completion with ROI report
});
```

**Integration Test**: `integration/api/melissa.test.ts`
```typescript
describe('POST /api/melissa/chat', () => {
  // Test message processing
  // Test phase transitions
  // Test error responses
  // Test rate limiting
});
```

---

### 2. **Session Management** (HIGH PRIORITY)
**Files**: `app/api/sessions/route.ts`, `stores/sessionStore.ts`

**Test Scenarios**:
- Create new session → session ID returned
- Retrieve session by ID → correct data
- List user sessions → all sessions returned
- Session state transitions: created → active → completed → archived
- Concurrent session handling
- Session timeout/abandonment

**Integration Test**: `integration/api/sessions.test.ts`
```typescript
describe('Session API', () => {
  test('POST /api/sessions - creates session');
  test('GET /api/sessions - lists sessions');
  test('GET /api/sessions/[id] - retrieves session');
  test('PATCH /api/sessions/[id] - updates status');
});
```

**Unit Test**: `unit/stores/sessionStore.test.ts`
```typescript
describe('sessionStore', () => {
  test('creates new session');
  test('updates session state');
  test('clears session on logout');
});
```

---

### 3. **ROI Calculation & Reports** (HIGH PRIORITY)
**Files**: `app/api/roi/calculate/route.ts`, `app/api/reports/[sessionId]/route.ts`

**Test Scenarios**:
- API endpoint accepts valid inputs → returns calculation
- Report generation: JSON, CSV, Markdown formats
- Report retrieval by session ID
- Database persistence of ROI reports
- Edge cases: zero automation, extreme values
- **Note**: Core calculation logic already tested ✓

**Integration Test**: `integration/api/roi.test.ts`
```typescript
describe('ROI API', () => {
  test('POST /api/roi/calculate - calculates ROI');
  test('GET /api/roi/[reportId] - retrieves report');
  test('POST /api/reports/[sessionId] - generates report');
  test('GET /api/reports/[sessionId]/markdown - exports markdown');
});
```

---

### 4. **Branding & Settings** (MEDIUM PRIORITY)
**Files**: `app/settings/branding/page.tsx`, `app/api/branding/[orgId]/route.ts`, `stores/brandingStore.ts`

**Test Scenarios**:
- Settings menu navigation (floating menu)
- Branding page: color scheme updates, logo upload, preset themes
- Advanced branding: custom CSS, fonts, email templates
- Accessibility validation (WCAG compliance checks)
- Asset upload and management
- Theme application and preview

**E2E Test**: `e2e/specs/settings.spec.ts`
```typescript
test('navigate settings menu', async ({ page }) => {
  // Open floating settings menu
  // Navigate to Branding
  // Change color scheme
  // Upload logo
  // Apply theme
  // Verify changes persist
});
```

**Component Test**: `unit/components/SettingsMenu.test.tsx`
```typescript
describe('SettingsMenu', () => {
  test('renders menu items');
  test('navigates to branding settings');
  test('closes on outside click');
});
```

---

### 5. **Core UI Components** (MEDIUM PRIORITY)
**Files**: `components/bloom/ChatInterface.tsx`, `components/bloom/MessageBubble.tsx`

**Test Scenarios**:
- ChatInterface renders with initial state
- MessageBubble displays user/AI messages correctly
- InputField handles user input and submission
- ProgressIndicator shows current phase
- Error boundaries handle component crashes
- Loading states and skeletons

**Component Test**: `unit/components/ChatInterface.test.tsx`
```typescript
describe('ChatInterface', () => {
  test('renders initial greeting');
  test('sends message on submit');
  test('displays loading state');
  test('handles API errors gracefully');
});
```

---

### 6. **Error Handling & Edge Cases** (MEDIUM PRIORITY)

**Test Scenarios**:
- 404 page rendering
- 500 error page rendering
- API rate limiting responses
- Network timeout handling
- Invalid session ID handling
- Database connection failures
- Malformed user input sanitization

**E2E Test**: `e2e/specs/error-handling.spec.ts`
```typescript
test('handles 404 gracefully', async ({ page }) => {
  await page.goto('/nonexistent-route');
  await expect(page.locator('h1')).toContainText('404');
});
```

---

### 7. **Accessibility** (MEDIUM PRIORITY)

**Test Scenarios**:
- Axe-core violations on key pages: Home, Chat, Settings, Branding
- Keyboard navigation (tab order, focus management)
- ARIA attributes and roles
- Color contrast ratios (WCAG AA)
- Screen reader compatibility

**A11y Test**: `accessibility/a11y.spec.ts`
```typescript
import { test, expect } from '@playwright/test';
import { injectAxe, checkA11y } from 'axe-playwright';

test('homepage has no a11y violations', async ({ page }) => {
  await page.goto('/');
  await injectAxe(page);
  await checkA11y(page, null, {
    detailedReport: true,
    detailedReportOptions: { html: true }
  });
});
```

---

### 8. **Performance** (LOW PRIORITY)

**Test Scenarios**:
- API response times < 200ms (p95)
- Page load times < 2s (p90)
- ROI calculation < 500ms
- Report generation < 3s
- Concurrent session handling (100 sessions)

**Performance Test**: `performance/load-test.js` (k6)
```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '30s', target: 10 },  // Ramp up
    { duration: '1m', target: 50 },   // Steady state
    { duration: '30s', target: 0 },   // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<200'],
  },
};

export default function () {
  const res = http.post('http://localhost:3000/api/melissa/chat', {
    message: 'Tell me about automation ROI',
    sessionId: 'test-session',
  });
  check(res, { 'status is 200': (r) => r.status === 200 });
  sleep(1);
}
```

---

## SIMPLE FIX POLICY

You may fix **ONLY** these types of issues without approval:

✅ **Safe to Fix Immediately**:
- Broken selectors or missing `data-testid` attributes
- Null/undefined checks (optional chaining, nullish coalescing)
- Missing `await` on async functions
- Trivial ARIA attributes (`aria-label`, `role`)
- Dead links (404 routes)
- Incorrect tab order
- Minor CSS regressions (spacing, alignment)
- Console errors/warnings
- Missing loading states
- Typos in user-facing text

❌ **Document Only - Do NOT Fix**:
- Data model changes
- Authentication/authorization logic
- Cross-cutting architecture changes
- API contract changes
- Database schema modifications
- State management refactoring
- Security vulnerabilities (XSS, SQL injection, CSRF)
- Performance optimizations requiring code restructuring

**Process**:
1. Fix the issue in a minimal, isolated way
2. Log in `_build/test/CHANGELOG.md` with risk level
3. Commit with clear message: `test: fix [issue] in [file]`
4. Continue testing

---

## TEST DATA & FIXTURES

### Seed Data Requirements
Create stable, idempotent test fixtures under `_build/test/fixtures/`:

**users.json**:
```json
[
  {
    "id": "test-user-1",
    "email": "test@example.com",
    "name": "Test User",
    "organizationId": "test-org-1"
  }
]
```

**sessions.json**:
```json
[
  {
    "id": "test-session-1",
    "userId": "test-user-1",
    "status": "active",
    "currentPhase": "discovery",
    "responses": []
  }
]
```

**roi-data.json**:
```json
{
  "hoursSavedPerWeek": 10,
  "currentCostPerHour": 50,
  "automationCostPerMonth": 500,
  "teamSize": 5,
  "industry": "technology"
}
```

### Seeding Strategy
- Use Prisma seed scripts: `prisma/seed.ts`
- Create test database: `bloom-test.db` (SQLite) or `bloom_test` (PostgreSQL)
- Reset database before each test suite
- Use transactions for test isolation

---

## COLLABORATION WITH SPECIALISTS

When you hit boundaries, delegate to these agents:

### 1. **backend-typescript-architect**
**When**: Complex API issues, auth tokens, database strategy
**Tasks**:
- Design idempotent seed strategy for tests
- Create test API token generation utilities
- Review database transaction patterns
- Advise on rate limiting test harness

### 2. **senior-code-reviewer**
**When**: Need fast PR review or security analysis
**Tasks**:
- Review quick-fix PRs for severity and risk
- Identify security vulnerabilities in tests
- Suggest code improvements
- Validate test coverage strategy

### 3. **ui-engineer**
**When**: Component testing or accessibility issues
**Tasks**:
- Create component test harnesses
- Fix flaky selectors (add `data-testid`)
- Implement accessibility fixes
- Validate responsive breakpoints

**You are the lead** - assign clear, atomic tasks and integrate results.

---

## METHODOLOGY & STANDARDS

### Testing Pyramid
```
      /\
     /E2E\      <- Few, critical paths (10-15 tests)
    /------\
   /  INT   \   <- API routes, DB operations (30-40 tests)
  /----------\
 /    UNIT    \ <- Components, utils, stores (100+ tests)
/--------------\
```

### Coverage Targets
- **Overall**: 70% (branches, functions, lines, statements)
- **Critical Paths**: 90% (Melissa agent, ROI calc, session mgmt)
- **Components**: 80%
- **API Routes**: 100%
- **Utilities**: 85%

### Security Testing Checklist
- [ ] Auth leakage in error messages
- [ ] Rate limiting on auth endpoints
- [ ] XSS sanitization in chat input
- [ ] SQL injection protection (Prisma parameterization)
- [ ] CSRF token validation
- [ ] Input validation on all API routes
- [ ] File upload restrictions (size, type)
- [ ] Secrets not in logs/commits

### Test Naming Convention
```typescript
// Pattern: describe('Component/Function', () => { test('should [expected behavior] when [condition]') })

describe('ChatInterface', () => {
  test('should display greeting message when session starts');
  test('should send user message when form submitted');
  test('should show loading state when awaiting AI response');
  test('should handle API error gracefully when network fails');
});
```

### Mocking Strategy
- **External APIs**: Mock Anthropic API responses
- **Database**: Use in-memory SQLite or test database
- **Time**: Mock `Date.now()` for deterministic tests
- **File uploads**: Mock file system operations
- **Network**: Use MSW (Mock Service Worker) for API mocking

---

## CI/CD INTEGRATION

### GitHub Actions Workflow
Create `.github/workflows/test.yml`:

```yaml
name: Test Suite

on: [push, pull_request]

jobs:
  unit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'
      - run: npm ci
      - run: npm run test:unit
      - uses: codecov/codecov-action@v3

  integration:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_DB: bloom_test
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - run: npx prisma migrate deploy
      - run: npm run test:integration

  e2e:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - run: npx playwright install --with-deps
      - run: npm run build
      - run: npm run test:e2e
      - uses: actions/upload-artifact@v3
        if: always()
        with:
          name: playwright-report
          path: playwright-report/
```

### Package.json Scripts
Add these test scripts:

```json
{
  "scripts": {
    "test": "jest",
    "test:unit": "jest --testPathPattern=__tests__",
    "test:integration": "jest --testPathPattern=integration",
    "test:e2e": "playwright test",
    "test:coverage": "jest --coverage",
    "test:watch": "jest --watch",
    "test:a11y": "playwright test --project=accessibility"
  }
}
```

---

## EXECUTION PLAN (10-DAY SPRINT)

### Day 1: Setup & Configuration
- [ ] Install missing dependencies (Playwright config, axe-core)
- [ ] Create `_build/test/` directory structure
- [ ] Setup Playwright config with projects (chromium, firefox, webkit)
- [ ] Create test fixtures and seed data
- [ ] Setup database for testing (`bloom_test`)
- [ ] Create helper utilities (auth, API client, test factories)
- [ ] Write this plan to `_build/test/PLAN.md`

### Day 2-3: API Integration Tests
- [ ] `integration/api/melissa.test.ts` - Chat endpoint
- [ ] `integration/api/sessions.test.ts` - Session management
- [ ] `integration/api/roi.test.ts` - ROI calculation
- [ ] `integration/api/branding.test.ts` - Branding endpoints
- [ ] `integration/db/prisma.test.ts` - Database operations
- [ ] Fix simple bugs discovered (log in CHANGELOG.md)

### Day 4-5: Component Tests
- [ ] `unit/components/ChatInterface.test.tsx`
- [ ] `unit/components/SettingsMenu.test.tsx`
- [ ] `unit/components/MessageBubble.test.tsx`
- [ ] `unit/components/BrandingPage.test.tsx`
- [ ] `unit/stores/sessionStore.test.ts`
- [ ] `unit/stores/brandingStore.test.ts`

### Day 6-7: E2E Tests (Playwright)
- [ ] `e2e/specs/chat-flow.spec.ts` - Complete workshop flow
- [ ] `e2e/specs/settings.spec.ts` - Settings navigation
- [ ] `e2e/specs/branding.spec.ts` - Branding customization
- [ ] `e2e/specs/roi-report.spec.ts` - Report generation
- [ ] `e2e/specs/error-handling.spec.ts` - Error scenarios

### Day 8: Accessibility & Performance
- [ ] `accessibility/a11y.spec.ts` - Axe-core tests on key pages
- [ ] `performance/load-test.js` - k6 load testing
- [ ] Fix trivial a11y violations (aria-labels, contrast)
- [ ] Document performance bottlenecks

### Day 9: CI/CD & Coverage
- [ ] Create `.github/workflows/test.yml`
- [ ] Run full test suite and measure coverage
- [ ] Add coverage badges to README
- [ ] Fix gaps to reach 70% overall coverage
- [ ] Ensure all tests pass in CI

### Day 10: Documentation & Handoff
- [ ] Write `_build/test/REPORT.md` with results
- [ ] Write `_build/test/BACKLOG.md` with architectural issues
- [ ] Update `_build/test/CHANGELOG.md` with all changes
- [ ] Create summary PR with test suite
- [ ] Present findings to team

---

## REPORTING FORMAT

### REPORT.md Structure

```markdown
# Appmelia Bloom - Test Suite Report
*Generated: [Date]*

## Executive Summary
- **Overall Status**: ✅ PASS / ❌ FAIL
- **Test Coverage**: X% (target 70%)
- **Tests Written**: X tests across Y files
- **Bugs Fixed**: X trivial bugs (see CHANGELOG.md)
- **Critical Risks**: X architectural issues (see BACKLOG.md)

## Test Results by Category

### Unit Tests
- **Total**: X tests
- **Passed**: X
- **Failed**: X
- **Coverage**: X%
- **Files Tested**: [List]

### Integration Tests
- **Total**: X tests
- **Passed**: X
- **Failed**: X
- **Files Tested**: [List]

### E2E Tests
- **Total**: X tests
- **Passed**: X
- **Failed**: X
- **Flaky Tests**: [List]

### Accessibility Tests
- **Pages Tested**: X
- **Violations**: X
- **WCAG Level**: AA
- **Top Issues**: [List]

### Performance Tests
- **API Response (p95)**: Xms (target <200ms)
- **Page Load (p90)**: Xs (target <2s)
- **Concurrent Sessions**: X (target 1000)

## Coverage by Module

| Module | Lines | Functions | Branches | Status |
|--------|-------|-----------|----------|--------|
| lib/melissa | X% | X% | X% | ✅/❌ |
| lib/roi | X% | X% | X% | ✅ |
| components/bloom | X% | X% | X% | ✅/❌ |
| app/api | X% | X% | X% | ✅/❌ |

## Quick Fixes Implemented

1. **[File]**: [Issue] → [Fix] (Risk: Low)
2. **[File]**: [Issue] → [Fix] (Risk: Low)
[See CHANGELOG.md for full list]

## Critical Findings

### Architectural Issues
[See BACKLOG.md for detailed breakdown]

1. **[Issue]**: [Impact] → [Options] → Est. [X days]
2. **[Issue]**: [Impact] → [Options] → Est. [X days]

### Security Concerns
[List any security vulnerabilities found]

### Performance Bottlenecks
[List any performance issues]

## Recommendations

1. **Immediate Actions**: [List]
2. **Next Sprint**: [List]
3. **Technical Debt**: [List]

## Next Steps

- [ ] Review BACKLOG.md with team
- [ ] Prioritize architectural fixes
- [ ] Integrate tests into CI/CD
- [ ] Monitor coverage over time
```

### BACKLOG.md Structure

```markdown
# Appmelia Bloom - Testing Backlog
*Architectural & Medium/Large Issues for Team Review*

## Issue #1: [Title]
- **Category**: Architecture / Security / Performance / Feature
- **Severity**: Critical / High / Medium / Low
- **Impact**: [Description of business/technical impact]
- **Current State**: [What's implemented]
- **Problem**: [Detailed problem description]
- **Options**:
  - **Option A**: [Description] → Est. X days → Dependencies: [List]
  - **Option B**: [Description] → Est. X days → Dependencies: [List]
  - **Option C**: [Description] → Est. X days → Dependencies: [List]
- **Recommendation**: [Preferred option with rationale]
- **References**: [Files, docs, related issues]

---

## Issue #2: [Title]
...
```

---

## CONSTRAINTS & GUARDRAILS

### Security
- ❌ NO secrets in logs or commits
- ❌ NO production API keys in tests
- ❌ NO test data with real user information
- ✅ Use .env.test for test environment variables
- ✅ Mock external services (Anthropic API)
- ✅ Sanitize all test output

### Git Workflow
- ❌ NO pushes to `main` branch
- ❌ NO large, multi-purpose commits
- ✅ Create feature branch: `test/comprehensive-suite`
- ✅ Small, focused commits per test file
- ✅ Conventional commit messages: `test: add [test name]`

### Code Quality
- ✅ All tests must pass before commit
- ✅ Follow existing code style (Prettier, ESLint)
- ✅ Use TypeScript strict mode
- ✅ Document complex test setups
- ✅ Keep tests DRY (shared utilities)

### Risk Management
- ⚠️ Dry-run destructive actions by default
- ⚠️ Feature flags for experimental tests
- ⚠️ Rollback plan for each change
- ⚠️ Test in isolation (no side effects)

---

## DEFINITION OF DONE

- [ ] `_build/test/PLAN.md` written and approved
- [ ] All test directories scaffolded
- [ ] Playwright configured and running
- [ ] 70%+ overall test coverage achieved
- [ ] 100% of API routes tested
- [ ] Critical E2E flows passing (chat, ROI, settings)
- [ ] Accessibility tests passing (WCAG AA)
- [ ] Performance baseline established
- [ ] CI/CD pipeline integrated
- [ ] All trivial bugs fixed and logged
- [ ] `_build/test/REPORT.md` completed
- [ ] `_build/test/BACKLOG.md` reviewed by team
- [ ] Test suite merged to `main` branch

---

## START NOW

### Immediate Actions

1. **Inventory** - Confirm current test setup (DONE via exploration)
2. **Setup** - Create directory structure and configs
3. **Quick Win** - Write first Playwright smoke test (chat flow)
4. **Iterate** - Implement tests by priority, fix bugs, log findings
5. **Report** - Generate comprehensive report and backlog

### First Test to Write

**File**: `_build/test/e2e/specs/chat-smoke.spec.ts`

```typescript
import { test, expect } from '@playwright/test';

test('smoke test: complete chat flow', async ({ page }) => {
  // Navigate to demo page
  await page.goto('/demo');

  // Verify chat interface loads
  await expect(page.locator('[data-testid="chat-interface"]')).toBeVisible();

  // Verify greeting message
  await expect(page.locator('[data-testid="message-0"]')).toContainText('Hello');

  // Send first message
  await page.fill('[data-testid="chat-input"]', 'I want to explore automation ROI');
  await page.click('[data-testid="send-button"]');

  // Verify response received
  await expect(page.locator('[data-testid="message-1"]')).toBeVisible({ timeout: 10000 });

  // Verify session created
  const sessionId = await page.locator('[data-testid="session-id"]').textContent();
  expect(sessionId).toBeTruthy();
});
```

---

## REFERENCES

### Documentation
- **PRD**: `/home/user/bloom/[Bloom-PRD-v10-MVP-v1.0.md](_build/PRD-Bloom/Bloom-PRD-v10-MVP-v1.0.md)`
- **CLAUDE.md**: `/home/user/bloom/CLAUDE.md`
- **Existing Tests**: `/home/user/bloom/__tests__/`

### Tech Stack
- **Framework**: Next.js 14 (App Router)
- **Testing**: Jest 29.7.0 + React Testing Library + Playwright 1.48.1
- **Database**: PostgreSQL + Prisma (use `bloom_test` DB)
- **State**: Zustand stores
- **AI**: Vercel AI SDK + Anthropic Claude

### Key Files to Test
- `lib/melissa/agent.ts` - AI agent logic
- `app/api/melissa/chat/route.ts` - Chat endpoint
- `app/api/sessions/route.ts` - Session management
- `components/bloom/ChatInterface.tsx` - Chat UI
- `components/layout/SettingsMenu.tsx` - Settings navigation
- `stores/sessionStore.ts` - Session state

### Agent Responsibilities
- **spec-tester** (YOU): Lead testing, coordinate specialists, deliver report
- **backend-typescript-architect**: API design, auth tokens, DB strategy
- **senior-code-reviewer**: PR reviews, security analysis
- **ui-engineer**: Component tests, accessibility, selectors

---

**Let's build a world-class test suite! 🚀**

*Start by creating the directory structure and writing your first smoke test.*
