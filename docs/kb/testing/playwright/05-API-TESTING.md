---
id: playwright-05-api-testing
topic: playwright
file_role: core
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [playwright-01-fundamentals, playwright-03-interactions-assertions]
related_topics: [api-testing, network-interception, request-fixture, mocking, next-js-routes]
embedding_keywords: [playwright, api testing, request fixture, network interception, page.route, waitForResponse, mock api, next.js route handlers]
last_reviewed: 2025-11-14
---

# Playwright API Testing

<!-- Query: "How do I test API routes in Playwright?" -->
<!-- Query: "How to intercept and mock network requests in Playwright?" -->
<!-- Query: "How to test Next.js API routes with Playwright?" -->
<!-- Query: "How to use the request fixture for API testing?" -->

## 1. Purpose

Master Playwright's API testing capabilities including direct API route testing with the `request` fixture, network interception with `page.route()`, response mocking, and testing API interactions through UI. This file is critical for comprehensive E2E testing that validates both frontend behavior and backend API responses.

**Read this file when:**
- Testing Next.js API routes directly without a browser
- Intercepting and mocking network requests during UI tests
- Validating API responses, status codes, and error handling
- Testing authenticated API endpoints with session management
- Implementing workshop session API tests or ROI calculation endpoints

**This file covers:**
- Direct API testing with `request` fixture (GET, POST, PATCH, DELETE)
- Network interception and mocking with `page.route()`
- Waiting for specific API responses with `waitForResponse()`
- Testing API routes through UI interactions
- Next.js 16 route handler testing patterns
- Bloom-specific API route examples (sessions, export, melissa chat)

---

## 2. Mental Model / Problem Statement

### The Challenge: Testing APIs in E2E Tests

Traditional E2E testing approaches struggle with API validation:

**Problem 1: UI-Only Testing Misses API Issues**
```typescript
// ❌ UI test only verifies visual feedback, not API correctness
test('create session', async ({ page }) => {
  await page.goto('/workshop');
  await page.getByRole('button', { name: 'Start Session' }).click();
  await expect(page.getByText('Session created')).toBeVisible();
  // ⚠️ What if API returned 500 but UI showed cached data?
  // ⚠️ What if response format is wrong but UI doesn't break yet?
});
```

**Problem 2: Separate API Tests Don't Catch Integration Issues**
```typescript
// ❌ API test in isolation doesn't test real user flow
test('create session API', async () => {
  const response = await fetch('/api/sessions', { method: 'POST' });
  expect(response.ok).toBeTruthy();
  // ⚠️ What if UI can't parse this response?
  // ⚠️ What if CORS headers are missing for browser?
});
```

**Problem 3: External API Dependencies Make Tests Flaky**
```typescript
// ❌ Test depends on external API (slow, unreliable, costs money)
test('AI chat integration', async ({ page }) => {
  await page.goto('/workshop/session/123');
  await page.fill('[data-testid="chat-input"]', 'Hello');
  await page.click('[data-testid="send-button"]');
  // ⚠️ Waits for real Anthropic API call ($$$, slow, rate limits)
  await expect(page.getByText(/Hi there/)).toBeVisible({ timeout: 30000 });
});
```

### Playwright's Solution: Multi-Layer API Testing

**Layer 1: Direct API Testing (request fixture)**
Test API routes directly without a browser for fast, isolated validation:
```typescript
test('session API returns correct structure', async ({ request }) => {
  const response = await request.post('/api/sessions', {
    data: { userId: 'test-user', organizationId: 'test-org' }
  });

  expect(response.ok()).toBeTruthy();
  const json = await response.json();
  expect(json).toHaveProperty('sessionId');
  expect(json.sessionId).toMatch(/^WS-\d{8}-\d{3}$/);
});
```

**Layer 2: Network Interception (page.route)**
Mock external APIs while testing real UI interactions:
```typescript
test('AI chat with mocked API', async ({ page }) => {
  // Mock Anthropic API responses
  await page.route('**/api/melissa/chat', async (route) => {
    await route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({
        message: 'Hello! How can I help?',
        phase: 'greeting'
      })
    });
  });

  await page.goto('/workshop/session/123');
  await page.fill('[data-testid="chat-input"]', 'Hello');
  await page.click('[data-testid="send-button"]');
  // ✅ Instant response, no external API call, predictable behavior
  await expect(page.getByText('Hello! How can I help?')).toBeVisible();
});
```

**Layer 3: API Response Validation Through UI**
Test real API integration with response inspection:
```typescript
test('session creation returns valid data', async ({ page }) => {
  const responsePromise = page.waitForResponse('/api/sessions');

  await page.goto('/workshop');
  await page.getByRole('button', { name: 'Start Session' }).click();

  const response = await responsePromise;
  expect(response.status()).toBe(200);

  const json = await response.json();
  expect(json.sessionId).toBeTruthy();

  // Also verify UI updated correctly
  await expect(page).toHaveURL(/\/workshop\/session\/.+/);
});
```

### Mental Model: "Test APIs at Every Layer"

**Key Insight:** Combine all three layers for comprehensive coverage:
1. **Direct API tests** → Fast feedback, validate contracts
2. **Mocked network tests** → Reliable UI testing, edge cases
3. **Integration tests** → Validate real API + UI interaction

---

## 3. Golden Path

### Recommended API Testing Strategy

**1. Direct API Testing with Request Fixture**

Use `request` fixture for fast, focused API validation:

```typescript
import { test, expect } from '@playwright/test';

test.describe('Sessions API', () => {
  test('POST /api/sessions creates new session', async ({ request }) => {
    const response = await request.post('/api/sessions', {
      data: {
        userId: 'test-user-123',
        organizationId: 'test-org-456'
      }
    });

    // Validate response
    expect(response.ok()).toBeTruthy();
    expect(response.status()).toBe(200);

    // Validate response structure
    const json = await response.json();
    expect(json).toMatchObject({
      sessionId: expect.stringMatching(/^WS-\d{8}-\d{3}$/),
      status: 'active',
      startedAt: expect.any(String)
    });
  });

  test('GET /api/sessions/:id returns session details', async ({ request }) => {
    // Create session first
    const createResponse = await request.post('/api/sessions', {
      data: { userId: 'test-user' }
    });
    const { sessionId } = await createResponse.json();

    // Fetch session
    const getResponse = await request.get(`/api/sessions/${sessionId}`);
    expect(getResponse.ok()).toBeTruthy();

    const session = await getResponse.json();
    expect(session).toMatchObject({
      id: sessionId,
      userId: 'test-user',
      status: 'active'
    });
  });

  test('PATCH /api/sessions/:id updates session context', async ({ request }) => {
    // Create session
    const { sessionId } = await (await request.post('/api/sessions')).json();

    // Update session
    const patchResponse = await request.patch(`/api/sessions/${sessionId}`, {
      data: {
        customerName: 'Acme Corp',
        customerIndustry: 'Technology',
        employeeCount: 500
      }
    });

    expect(patchResponse.ok()).toBeTruthy();
    const result = await patchResponse.json();
    expect(result.success).toBe(true);

    // Verify update
    const getResponse = await request.get(`/api/sessions/${sessionId}`);
    const session = await getResponse.json();
    expect(session.customerName).toBe('Acme Corp');
    expect(session.employeeCount).toBe(500);
  });
});
```

**2. Network Interception for External APIs**

Mock external services to make tests fast and reliable:

```typescript
test.describe('Melissa Chat (Mocked)', () => {
  test.beforeEach(async ({ page }) => {
    // Mock Anthropic API for all tests
    await page.route('**/api/melissa/chat', async (route) => {
      const request = route.request();
      const postData = JSON.parse(request.postData() || '{}');

      // Simulate Melissa's greeting
      if (postData.message === '__INIT__') {
        await route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify({
            message: "Hello! I'm Melissa, your AI workshop facilitator.",
            phase: 'greeting',
            progress: 0,
            needsUserInput: true
          })
        });
      } else {
        // Generic response for other messages
        await route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify({
            message: `You said: "${postData.message}". Let's explore that further.`,
            phase: 'discovery',
            progress: 25,
            needsUserInput: true
          })
        });
      }
    });
  });

  test('chat initialization displays greeting', async ({ page }) => {
    await page.goto('/workshop/session/test-session-123');

    // Melissa greeting should appear (mocked response)
    await expect(page.getByText("I'm Melissa")).toBeVisible();
    await expect(page.getByText('workshop facilitator')).toBeVisible();
  });

  test('user can send messages and receive responses', async ({ page }) => {
    await page.goto('/workshop/session/test-session-123');

    // Wait for initial greeting
    await expect(page.getByText("I'm Melissa")).toBeVisible();

    // Send user message
    await page.getByLabel('Chat message').fill('I want to optimize invoicing');
    await page.getByRole('button', { name: 'Send' }).click();

    // Verify mocked response appears
    await expect(page.getByText(/You said.*optimize invoicing/)).toBeVisible();
  });
});
```

**3. Validate API Through UI with Response Inspection**

Test real API integration and verify response data:

```typescript
test('session export generates valid PDF', async ({ page }) => {
  // Wait for specific API response
  const exportPromise = page.waitForResponse(
    response => response.url().includes('/api/sessions/') &&
               response.url().includes('/export') &&
               response.status() === 200
  );

  await page.goto('/workshop/session/test-session-123');
  await page.getByRole('button', { name: 'Export PDF' }).click();

  // Validate response
  const response = await exportPromise;
  expect(response.headers()['content-type']).toBe('application/pdf');

  const buffer = await response.body();
  expect(buffer.length).toBeGreaterThan(1000); // PDF has content

  // Verify UI feedback
  await expect(page.getByText('PDF exported successfully')).toBeVisible();
});
```

**4. Test Error Handling**

```typescript
test.describe('API Error Handling', () => {
  test('404 error shows appropriate message', async ({ request }) => {
    const response = await request.get('/api/sessions/nonexistent-session-id');

    expect(response.status()).toBe(404);
    const json = await response.json();
    expect(json.error).toBe('Session not found');
  });

  test('validation errors return 400 with details', async ({ request }) => {
    const response = await request.post('/api/sessions', {
      data: {
        employeeCount: -100 // Invalid: must be positive
      }
    });

    expect(response.status()).toBe(400);
    const json = await response.json();
    expect(json.error).toBe('Invalid request data');
    expect(json.details).toBeDefined();
  });

  test('UI displays API error messages', async ({ page }) => {
    // Mock API to return error
    await page.route('**/api/sessions', async (route) => {
      await route.fulfill({
        status: 500,
        contentType: 'application/json',
        body: JSON.stringify({ error: 'Database connection failed' })
      });
    });

    await page.goto('/workshop');
    await page.getByRole('button', { name: 'Start Session' }).click();

    // Verify error displayed to user
    await expect(page.getByText(/Database connection failed/)).toBeVisible();
  });
});
```

---

## 4. Common Patterns

### Pattern 1: Testing All HTTP Methods

```typescript
test.describe('CRUD Operations', () => {
  let sessionId: string;

  test('CREATE (POST)', async ({ request }) => {
    const response = await request.post('/api/sessions', {
      data: { userId: 'test-user' }
    });

    expect(response.status()).toBe(200);
    const json = await response.json();
    sessionId = json.sessionId;
    expect(sessionId).toBeTruthy();
  });

  test('READ (GET)', async ({ request }) => {
    const response = await request.get(`/api/sessions/${sessionId}`);
    expect(response.status()).toBe(200);

    const json = await response.json();
    expect(json.id).toBe(sessionId);
  });

  test('UPDATE (PATCH)', async ({ request }) => {
    const response = await request.patch(`/api/sessions/${sessionId}`, {
      data: { customerName: 'Updated Corp' }
    });

    expect(response.status()).toBe(200);
    const json = await response.json();
    expect(json.success).toBe(true);
  });

  test('DELETE', async ({ request }) => {
    const response = await request.delete(`/api/sessions/${sessionId}`);
    expect(response.status()).toBe(200);

    // Verify deletion
    const getResponse = await request.get(`/api/sessions/${sessionId}`);
    expect(getResponse.status()).toBe(404);
  });
});
```

### Pattern 2: Testing with Headers and Cookies

```typescript
test('authenticated API request', async ({ request }) => {
  // Create session with auth headers
  const response = await request.post('/api/sessions', {
    headers: {
      'Authorization': 'Bearer test-token-123',
      'X-Idempotency-Key': 'unique-request-id-456'
    },
    data: { userId: 'auth-user' }
  });

  expect(response.ok()).toBeTruthy();

  // Verify response includes cookies
  const cookies = response.headers()['set-cookie'];
  expect(cookies).toBeDefined();
});

test('request with custom headers', async ({ request }) => {
  const response = await request.get('/api/health', {
    headers: {
      'Accept': 'application/json',
      'User-Agent': 'Playwright-Test-Agent'
    }
  });

  expect(response.ok()).toBeTruthy();
});
```

### Pattern 3: waitForResponse() Patterns

```typescript
test('wait for specific API call', async ({ page }) => {
  // Method 1: URL pattern matching
  const responsePromise = page.waitForResponse('/api/sessions');

  await page.goto('/workshop');
  await page.click('[data-testid="start-session"]');

  const response = await responsePromise;
  expect(response.status()).toBe(200);
});

test('wait for response with custom predicate', async ({ page }) => {
  // Method 2: Custom condition
  const responsePromise = page.waitForResponse(
    response => {
      return response.url().includes('/api/roi/calculate') &&
             response.status() === 200 &&
             response.request().method() === 'POST';
    }
  );

  await page.goto('/workshop/session/123');
  await page.click('[data-testid="calculate-roi"]');

  const response = await responsePromise;
  const json = await response.json();
  expect(json).toHaveProperty('npv');
  expect(json).toHaveProperty('irr');
});

test('wait for multiple responses', async ({ page }) => {
  // Method 3: Multiple parallel API calls
  const [sessionsResponse, healthResponse] = await Promise.all([
    page.waitForResponse('/api/sessions'),
    page.waitForResponse('/api/health'),
    page.goto('/dashboard') // Triggers both API calls
  ]);

  expect(sessionsResponse.ok()).toBeTruthy();
  expect(healthResponse.ok()).toBeTruthy();
});

test('wait with timeout', async ({ page }) => {
  // Method 4: Custom timeout
  const responsePromise = page.waitForResponse('/api/sessions', {
    timeout: 10000 // 10 seconds
  });

  await page.click('[data-testid="slow-operation"]');

  const response = await responsePromise;
  expect(response.ok()).toBeTruthy();
});
```

### Pattern 4: Network Interception and Modification

```typescript
test('intercept and modify request', async ({ page }) => {
  await page.route('**/api/sessions', async (route) => {
    // Modify request before sending
    const request = route.request();
    const postData = JSON.parse(request.postData() || '{}');

    // Add custom field
    postData.testMode = true;

    // Continue with modified data
    await route.continue({
      postData: JSON.stringify(postData)
    });
  });

  await page.goto('/workshop');
  await page.click('[data-testid="start-session"]');
});

test('intercept and modify response', async ({ page }) => {
  await page.route('**/api/sessions', async (route) => {
    // Fetch real response
    const response = await route.fetch();
    const json = await response.json();

    // Modify response data
    json.testFlag = true;
    json.status = 'test-mode-active';

    // Return modified response
    await route.fulfill({
      response,
      json
    });
  });

  await page.goto('/workshop');
  // UI will receive modified response
});

test('conditionally intercept requests', async ({ page }) => {
  await page.route('**/api/**', async (route) => {
    const url = route.request().url();

    if (url.includes('/api/external/')) {
      // Mock external API
      await route.fulfill({
        status: 200,
        body: JSON.stringify({ data: 'mocked' })
      });
    } else {
      // Let internal APIs pass through
      await route.continue();
    }
  });

  await page.goto('/dashboard');
});
```

### Pattern 5: Testing File Uploads/Downloads

```typescript
test('upload file via API', async ({ request }) => {
  const response = await request.post('/api/branding/upload', {
    multipart: {
      file: {
        name: 'logo.png',
        mimeType: 'image/png',
        buffer: Buffer.from('fake-png-data')
      },
      organizationId: 'test-org-123'
    }
  });

  expect(response.ok()).toBeTruthy();
  const json = await response.json();
  expect(json.url).toMatch(/^https?:\/\/.+\/logo\.png$/);
});

test('download PDF export', async ({ request }) => {
  const response = await request.get('/api/sessions/test-123/export?format=pdf');

  expect(response.ok()).toBeTruthy();
  expect(response.headers()['content-type']).toBe('application/pdf');

  const buffer = await response.body();
  expect(buffer.length).toBeGreaterThan(0);

  // Optionally save for inspection
  // await fs.writeFile('test-export.pdf', buffer);
});
```

### Pattern 6: Testing Rate Limiting

```typescript
test('rate limiting blocks excessive requests', async ({ request }) => {
  const sessionId = 'test-session-123';

  // Make requests until rate limit hit
  const responses = await Promise.all(
    Array.from({ length: 100 }, () =>
      request.get(`/api/sessions/${sessionId}`)
    )
  );

  // Some should succeed
  const successful = responses.filter(r => r.status() === 200);
  expect(successful.length).toBeGreaterThan(0);

  // Some should be rate limited (429 Too Many Requests)
  const rateLimited = responses.filter(r => r.status() === 429);
  expect(rateLimited.length).toBeGreaterThan(0);
});

test('rate limit headers present', async ({ request }) => {
  const response = await request.get('/api/sessions');

  const headers = response.headers();
  expect(headers).toHaveProperty('x-ratelimit-limit');
  expect(headers).toHaveProperty('x-ratelimit-remaining');
});
```

---

## 5. Advanced Techniques

### Technique 1: Dynamic Response Based on Request

```typescript
test('mock responses based on request parameters', async ({ page }) => {
  await page.route('**/api/sessions', async (route) => {
    const request = route.request();
    const url = new URL(request.url());
    const status = url.searchParams.get('status');

    // Different responses based on query params
    const mockSessions = {
      'active': [
        { id: 'WS-1', status: 'active', title: 'Active Session 1' },
        { id: 'WS-2', status: 'active', title: 'Active Session 2' }
      ],
      'completed': [
        { id: 'WS-3', status: 'completed', title: 'Completed Session' }
      ],
      'default': [
        { id: 'WS-4', status: 'idle', title: 'All Sessions' }
      ]
    };

    const sessions = mockSessions[status || 'default'] || mockSessions.default;

    await route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ sessions })
    });
  });

  await page.goto('/sessions?status=active');
  await expect(page.getByText('Active Session 1')).toBeVisible();

  await page.goto('/sessions?status=completed');
  await expect(page.getByText('Completed Session')).toBeVisible();
});
```

### Technique 2: Testing WebSocket-Like Streaming

```typescript
test('SSE log streaming', async ({ page }) => {
  // Mock Server-Sent Events endpoint
  await page.route('**/api/system/logs-stream', async (route) => {
    const stream = [
      'data: {"level":"info","message":"Server started"}\n\n',
      'data: {"level":"debug","message":"Database connected"}\n\n',
      'data: {"level":"error","message":"Cache unavailable"}\n\n'
    ].join('');

    await route.fulfill({
      status: 200,
      headers: {
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive'
      },
      body: stream
    });
  });

  await page.goto('/settings?tab=monitoring');

  // Verify SSE messages appear in UI
  await expect(page.getByText('Server started')).toBeVisible();
  await expect(page.getByText('Database connected')).toBeVisible();
  await expect(page.getByText('Cache unavailable')).toBeVisible();
});
```

### Technique 3: Testing Retry Logic

```typescript
test('API retries on failure', async ({ page }) => {
  let attemptCount = 0;

  await page.route('**/api/sessions', async (route) => {
    attemptCount++;

    if (attemptCount < 3) {
      // Fail first 2 attempts
      await route.fulfill({
        status: 500,
        body: JSON.stringify({ error: 'Temporary failure' })
      });
    } else {
      // Succeed on 3rd attempt
      await route.fulfill({
        status: 200,
        body: JSON.stringify({ sessionId: 'WS-123', status: 'active' })
      });
    }
  });

  await page.goto('/workshop');
  await page.click('[data-testid="start-session"]');

  // Should eventually succeed after retries
  await expect(page.getByText('Session created')).toBeVisible();
  expect(attemptCount).toBe(3);
});
```

### Technique 4: Testing Response Timing

```typescript
test('API response time within acceptable range', async ({ request }) => {
  const start = Date.now();
  const response = await request.get('/api/health');
  const duration = Date.now() - start;

  expect(response.ok()).toBeTruthy();
  expect(duration).toBeLessThan(500); // Health check < 500ms
});

test('slow API shows loading state', async ({ page }) => {
  await page.route('**/api/roi/calculate', async (route) => {
    // Simulate slow API (2 seconds)
    await new Promise(resolve => setTimeout(resolve, 2000));

    await route.fulfill({
      status: 200,
      body: JSON.stringify({ npv: 150000, irr: 0.25 })
    });
  });

  await page.goto('/workshop/session/123');
  await page.click('[data-testid="calculate-roi"]');

  // Loading indicator should appear
  await expect(page.getByText('Calculating...')).toBeVisible();

  // Then results appear
  await expect(page.getByText('NPV: $150,000')).toBeVisible({ timeout: 5000 });
});
```

### Technique 5: Testing Parallel API Calls

```typescript
test('concurrent API requests', async ({ request }) => {
  // Create 10 sessions in parallel
  const createPromises = Array.from({ length: 10 }, (_, i) =>
    request.post('/api/sessions', {
      data: { userId: `user-${i}` }
    })
  );

  const responses = await Promise.all(createPromises);

  // All should succeed
  responses.forEach(response => {
    expect(response.ok()).toBeTruthy();
  });

  // All should have unique session IDs
  const sessionIds = await Promise.all(
    responses.map(r => r.json().then(j => j.sessionId))
  );
  const uniqueIds = new Set(sessionIds);
  expect(uniqueIds.size).toBe(10); // No duplicates
});
```

### Technique 6: Mocking with Fixture Data

```typescript
import sessionsFixture from '../fixtures/sessions.json';

test('sessions list with fixture data', async ({ page }) => {
  await page.route('**/api/sessions', async (route) => {
    await route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ sessions: sessionsFixture })
    });
  });

  await page.goto('/sessions');

  // Verify all fixture sessions appear
  for (const session of sessionsFixture) {
    await expect(page.getByText(session.title)).toBeVisible();
  }
});
```

---

## 6. Anti-Patterns

### ❌ Anti-Pattern 1: Not Using Request Fixture for API-Only Tests

```typescript
// ❌ BAD: Launching browser just to test API
test('health check', async ({ page }) => {
  const response = await page.goto('/api/health');
  expect(response?.status()).toBe(200);
});

// ✅ GOOD: Use request fixture (faster, no browser overhead)
test('health check', async ({ request }) => {
  const response = await request.get('/api/health');
  expect(response.status()).toBe(200);
});
```

**Why it matters:**
- Browser overhead adds 1-2 seconds per test
- Request fixture is 10-50x faster for pure API tests
- No need for browser automation when testing APIs directly

### ❌ Anti-Pattern 2: Not Mocking External APIs

```typescript
// ❌ BAD: Tests depend on real Anthropic API
test('melissa chat', async ({ page }) => {
  await page.goto('/workshop/session/123');
  await page.fill('[data-testid="chat-input"]', 'Hello');
  await page.click('[data-testid="send"]');

  // ⚠️ Real API call: slow, costs money, rate limits, flaky
  await expect(page.getByText(/Hi.*help/)).toBeVisible({ timeout: 30000 });
});

// ✅ GOOD: Mock external API
test('melissa chat', async ({ page }) => {
  await page.route('**/api/melissa/chat', async (route) => {
    await route.fulfill({
      status: 200,
      body: JSON.stringify({
        message: 'Hi! How can I help?',
        phase: 'greeting'
      })
    });
  });

  await page.goto('/workshop/session/123');
  await page.fill('[data-testid="chat-input"]', 'Hello');
  await page.click('[data-testid="send"]');

  // ✅ Instant, free, reliable
  await expect(page.getByText('Hi! How can I help?')).toBeVisible();
});
```

**Why it matters:**
- External API calls add latency (5-30 seconds vs milliseconds)
- Costs money per test run (Anthropic charges per token)
- Rate limits can fail tests during CI/CD
- Unpredictable responses make tests flaky

### ❌ Anti-Pattern 3: Not Validating Response Structure

```typescript
// ❌ BAD: Only checks status code
test('create session', async ({ request }) => {
  const response = await request.post('/api/sessions');
  expect(response.ok()).toBeTruthy();
  // ⚠️ What if response is empty? What if format changed?
});

// ✅ GOOD: Validate full response structure
test('create session', async ({ request }) => {
  const response = await request.post('/api/sessions', {
    data: { userId: 'test-user' }
  });

  expect(response.status()).toBe(200);

  const json = await response.json();
  expect(json).toMatchObject({
    sessionId: expect.stringMatching(/^WS-\d{8}-\d{3}$/),
    status: expect.stringMatching(/^(active|idle|completed|abandoned)$/),
    startedAt: expect.stringMatching(/^\d{4}-\d{2}-\d{2}T/)
  });
});
```

**Why it matters:**
- Breaking API changes often go undetected
- Invalid response structures break frontend
- Schema drift causes runtime errors

### ❌ Anti-Pattern 4: Hardcoding API Responses

```typescript
// ❌ BAD: Hardcoded mock responses
test('sessions list', async ({ page }) => {
  await page.route('**/api/sessions', async (route) => {
    await route.fulfill({
      body: '{"sessions":[{"id":"WS-1"}]}' // Hardcoded, brittle
    });
  });

  await page.goto('/sessions');
});

// ✅ GOOD: Use factory functions or fixtures
import { createMockSession } from '../factories/session-factory';

test('sessions list', async ({ page }) => {
  const mockSessions = [
    createMockSession({ status: 'active' }),
    createMockSession({ status: 'completed' })
  ];

  await page.route('**/api/sessions', async (route) => {
    await route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ sessions: mockSessions })
    });
  });

  await page.goto('/sessions');
});
```

**Why it matters:**
- Factory functions ensure realistic data
- Easier to maintain when schema changes
- Reusable across multiple tests

### ❌ Anti-Pattern 5: Not Testing Error Cases

```typescript
// ❌ BAD: Only tests happy path
test('create session', async ({ request }) => {
  const response = await request.post('/api/sessions', {
    data: { userId: 'valid-user' }
  });
  expect(response.ok()).toBeTruthy();
});

// ✅ GOOD: Test error scenarios
test.describe('Session Creation', () => {
  test('succeeds with valid data', async ({ request }) => {
    const response = await request.post('/api/sessions', {
      data: { userId: 'valid-user' }
    });
    expect(response.status()).toBe(200);
  });

  test('fails with invalid employee count', async ({ request }) => {
    const response = await request.post('/api/sessions', {
      data: { employeeCount: -100 }
    });
    expect(response.status()).toBe(400);
    const json = await response.json();
    expect(json.error).toBe('Invalid request data');
  });

  test('fails with missing required fields', async ({ request }) => {
    const response = await request.post('/api/sessions', {
      data: {} // Empty data
    });
    expect(response.status()).toBe(400);
  });

  test('returns 500 on database error', async ({ page }) => {
    // Mock database failure
    await page.route('**/api/sessions', async (route) => {
      await route.fulfill({
        status: 500,
        body: JSON.stringify({ error: 'Database connection failed' })
      });
    });

    await page.goto('/workshop');
    await page.click('[data-testid="start-session"]');

    // Verify error displayed to user
    await expect(page.getByText(/connection failed/i)).toBeVisible();
  });
});
```

**Why it matters:**
- Error handling bugs often go unnoticed
- Production failures surprise users
- 80% of real-world scenarios involve errors

### ❌ Anti-Pattern 6: Ignoring Response Headers

```typescript
// ❌ BAD: Doesn't check headers
test('export PDF', async ({ request }) => {
  const response = await request.get('/api/sessions/123/export?format=pdf');
  expect(response.ok()).toBeTruthy();
});

// ✅ GOOD: Validate critical headers
test('export PDF', async ({ request }) => {
  const response = await request.get('/api/sessions/123/export?format=pdf');

  expect(response.status()).toBe(200);

  const headers = response.headers();
  expect(headers['content-type']).toBe('application/pdf');
  expect(headers['content-disposition']).toMatch(/attachment; filename=.+\.pdf/);
  expect(headers['cache-control']).toBeDefined();

  const buffer = await response.body();
  expect(buffer.length).toBeGreaterThan(1000);
});
```

**Why it matters:**
- Wrong Content-Type breaks downloads
- Missing CORS headers fail browser requests
- Cache headers affect performance

---

## 7. Bloom-Specific Examples

### Example 1: Session Management API

```typescript
import { test, expect } from '@playwright/test';

test.describe('Bloom Session API', () => {
  test('complete session lifecycle', async ({ request }) => {
    // 1. Create session
    const createResponse = await request.post('/api/sessions', {
      data: {
        userId: 'test-user-123',
        organizationId: 'test-org-456'
      },
      headers: {
        'X-Idempotency-Key': 'unique-request-' + Date.now()
      }
    });

    expect(createResponse.status()).toBe(200);
    const { sessionId } = await createResponse.json();
    expect(sessionId).toMatch(/^WS-\d{8}-\d{3}$/);

    // 2. Update session context
    const updateResponse = await request.patch(`/api/sessions/${sessionId}`, {
      data: {
        customerName: 'Acme Corporation',
        customerIndustry: 'Technology',
        employeeCount: 500,
        problemStatement: 'Manual invoice processing takes 40 hours/week'
      }
    });

    expect(updateResponse.status()).toBe(200);
    const updateResult = await updateResponse.json();
    expect(updateResult.success).toBe(true);

    // 3. Verify update
    const getResponse = await request.get(`/api/sessions/${sessionId}`);
    const session = await getResponse.json();
    expect(session).toMatchObject({
      id: sessionId,
      customerName: 'Acme Corporation',
      employeeCount: 500,
      status: 'active'
    });

    // 4. Export session
    const exportResponse = await request.get(
      `/api/sessions/${sessionId}/export?format=json`
    );
    expect(exportResponse.status()).toBe(200);
    const exportData = await exportResponse.json();
    expect(exportData.session.id).toBe(sessionId);
  });

  test('session context validation', async ({ request }) => {
    const response = await request.post('/api/sessions', {
      data: {
        customerIndustry: 'Technology',
        employeeCount: 999999, // Exceeds max (100000)
        customerContact: 'invalid-email' // Invalid email
      }
    });

    expect(response.status()).toBe(400);
    const json = await response.json();
    expect(json.error).toBe('Invalid request data');
    expect(json.details).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          path: expect.arrayContaining(['employeeCount'])
        }),
        expect.objectContaining({
          path: expect.arrayContaining(['customerContact'])
        })
      ])
    );
  });
});
```

### Example 2: Melissa Chat API (Mocked)

```typescript
test.describe('Melissa Chat Integration', () => {
  test('initialization flow', async ({ page }) => {
    let requestCount = 0;

    await page.route('**/api/melissa/chat', async (route) => {
      const postData = JSON.parse(route.request().postData() || '{}');
      requestCount++;

      // First request: __INIT__
      if (postData.message === '__INIT__') {
        await route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify({
            message: "Hello! I'm Melissa, your AI workshop facilitator. Let's discover your ROI opportunities together. What process would you like to optimize?",
            phase: 'greeting',
            progress: 0,
            needsUserInput: true
          })
        });
      }
      // Subsequent requests
      else {
        await route.fulfill({
          status: 200,
          body: JSON.stringify({
            message: `Great! "${postData.message}" is a common optimization area. How many hours per week does your team spend on this?`,
            phase: 'discovery',
            progress: 15,
            needsUserInput: true
          })
        });
      }
    });

    // Navigate to workshop
    await page.goto('/workshop/session/test-session-123');

    // Verify greeting appears
    await expect(page.getByText("I'm Melissa")).toBeVisible();
    await expect(page.getByText('workshop facilitator')).toBeVisible();

    // Send user message
    const chatInput = page.getByLabel('Chat message');
    await chatInput.fill('Invoice processing');
    await page.getByRole('button', { name: 'Send' }).click();

    // Verify response
    await expect(page.getByText(/hours per week/)).toBeVisible();

    // Verify request count
    expect(requestCount).toBe(2); // __INIT__ + user message
  });

  test('error handling in chat', async ({ page }) => {
    await page.route('**/api/melissa/chat', async (route) => {
      await route.fulfill({
        status: 500,
        body: JSON.stringify({
          error: 'AI service unavailable',
          message: 'Anthropic API rate limit exceeded'
        })
      });
    });

    await page.goto('/workshop/session/test-123');
    await page.getByLabel('Chat message').fill('Hello');
    await page.getByRole('button', { name: 'Send' }).click();

    // Verify error message displayed
    await expect(page.getByText(/service unavailable/i)).toBeVisible();
  });
});
```

### Example 3: ROI Calculation API

```typescript
test.describe('ROI Calculation', () => {
  test('calculate NPV and IRR', async ({ request }) => {
    const response = await request.post('/api/roi/calculate', {
      data: {
        sessionId: 'test-session-123',
        initialInvestment: 50000,
        annualSavings: 75000,
        timeHorizonYears: 5,
        discountRate: 0.10
      }
    });

    expect(response.status()).toBe(200);
    const result = await response.json();

    expect(result).toMatchObject({
      npv: expect.any(Number),
      irr: expect.any(Number),
      paybackPeriod: expect.any(Number),
      confidenceScore: expect.any(Number)
    });

    // Validate calculations
    expect(result.npv).toBeGreaterThan(0); // Profitable
    expect(result.irr).toBeGreaterThan(0.10); // Exceeds discount rate
    expect(result.confidenceScore).toBeGreaterThanOrEqual(0);
    expect(result.confidenceScore).toBeLessThanOrEqual(100);
  });

  test('ROI calculation through UI', async ({ page }) => {
    // Mock ROI API
    await page.route('**/api/roi/calculate', async (route) => {
      await route.fulfill({
        status: 200,
        body: JSON.stringify({
          npv: 234000,
          irr: 0.45,
          paybackPeriod: 0.67,
          confidenceScore: 85
        })
      });
    });

    await page.goto('/workshop/session/test-123');

    // Fill in ROI inputs
    await page.getByLabel('Initial Investment').fill('50000');
    await page.getByLabel('Annual Savings').fill('75000');
    await page.getByLabel('Time Horizon (years)').fill('5');

    // Trigger calculation
    const responsePromise = page.waitForResponse('/api/roi/calculate');
    await page.getByRole('button', { name: 'Calculate ROI' }).click();

    // Verify API called
    const response = await responsePromise;
    expect(response.status()).toBe(200);

    // Verify results displayed
    await expect(page.getByText('NPV: $234,000')).toBeVisible();
    await expect(page.getByText('IRR: 45%')).toBeVisible();
    await expect(page.getByText('Payback: 8 months')).toBeVisible();
    await expect(page.getByText('Confidence: 85%')).toBeVisible();
  });
});
```

### Example 4: Export API (Multiple Formats)

```typescript
test.describe('Session Export', () => {
  test('export as JSON', async ({ request }) => {
    const response = await request.get('/api/sessions/test-123/export?format=json');

    expect(response.status()).toBe(200);
    expect(response.headers()['content-type']).toBe('application/json');

    const json = await response.json();
    expect(json).toHaveProperty('session');
    expect(json).toHaveProperty('responses');
    expect(json).toHaveProperty('roiReport');
  });

  test('export as PDF', async ({ request }) => {
    const response = await request.get('/api/sessions/test-123/export?format=pdf');

    expect(response.status()).toBe(200);
    expect(response.headers()['content-type']).toBe('application/pdf');
    expect(response.headers()['content-disposition']).toMatch(/attachment/);

    const buffer = await response.body();
    expect(buffer.length).toBeGreaterThan(1000); // Has content
    expect(buffer.toString('utf8', 0, 4)).toBe('%PDF'); // PDF magic number
  });

  test('export as Excel', async ({ request }) => {
    const response = await request.get('/api/sessions/test-123/export?format=excel');

    expect(response.status()).toBe(200);
    expect(response.headers()['content-type']).toMatch(/spreadsheet|excel/);

    const buffer = await response.body();
    expect(buffer.length).toBeGreaterThan(0);
  });

  test('export through UI triggers download', async ({ page }) => {
    const downloadPromise = page.waitForEvent('download');

    await page.goto('/workshop/session/test-123');
    await page.getByRole('button', { name: 'Export' }).click();
    await page.getByRole('menuitem', { name: 'PDF' }).click();

    const download = await downloadPromise;
    expect(download.suggestedFilename()).toMatch(/\.pdf$/);
  });
});
```

### Example 5: Health Check API

```typescript
test.describe('Health & Monitoring', () => {
  test('health endpoint returns system status', async ({ request }) => {
    const response = await request.get('/api/health');

    expect(response.status()).toBe(200);
    const json = await response.json();

    expect(json).toMatchObject({
      status: 'healthy',
      timestamp: expect.stringMatching(/^\d{4}-\d{2}-\d{2}T/),
      version: expect.any(String),
      checks: {
        database: expect.stringMatching(/^(healthy|unhealthy)$/),
        redis: expect.stringMatching(/^(connected|not_connected)$/),
        anthropic: expect.stringMatching(/^(configured|not configured)$/)
      },
      database: {
        healthy: expect.any(Boolean),
        latency: expect.any(Number)
      },
      process: {
        uptime: expect.any(Number),
        memory: {
          rss: expect.any(Number),
          heapUsed: expect.any(Number),
          heapTotal: expect.any(Number)
        }
      }
    });

    // Performance check
    expect(json.database.latency).toBeLessThan(100); // < 100ms
  });

  test('HEAD request for lightweight health check', async ({ request }) => {
    const response = await request.head('/api/health');
    expect(response.status()).toBe(200);

    // No body for HEAD requests
    const body = await response.body();
    expect(body.length).toBe(0);
  });
});
```

### Example 6: Next.js 16 Route Handler Pattern

```typescript
// Testing Next.js 16 async params pattern
test.describe('Next.js 16 Route Handlers', () => {
  test('dynamic route with async params', async ({ request }) => {
    // Create session first
    const createResponse = await request.post('/api/sessions', {
      data: { userId: 'test-user' }
    });
    const { sessionId } = await createResponse.json();

    // Test GET handler with dynamic [id] param
    const getResponse = await request.get(`/api/sessions/${sessionId}`);
    expect(getResponse.ok()).toBeTruthy();

    const session = await getResponse.json();
    expect(session.id).toBe(sessionId);

    // Test PATCH handler (also uses async params)
    const patchResponse = await request.patch(`/api/sessions/${sessionId}`, {
      data: { customerName: 'Updated Corp' }
    });
    expect(patchResponse.ok()).toBeTruthy();
  });

  test('nested dynamic routes', async ({ request }) => {
    // Test nested route: /api/sessions/[id]/files/[fileId]
    const response = await request.get(
      '/api/sessions/test-session-123/files/test-file-456'
    );

    // Should handle async params correctly
    expect([200, 404]).toContain(response.status());
  });
});
```

---

## References

### Official Documentation
- [Playwright API Testing](https://playwright.dev/docs/api-testing)
- [Playwright Request Fixture](https://playwright.dev/docs/api/class-request)
- [Network Interception](https://playwright.dev/docs/network)
- [APIResponse Class](https://playwright.dev/docs/api/class-apiresponse)

### Related Bloom Documentation
- `01-FUNDAMENTALS.md` - Test structure and fixtures
- `03-INTERACTIONS-ASSERTIONS.md` - Web-first assertions
- `06-AUTHENTICATION-STATE.md` - Testing authenticated endpoints
- `07-DATABASE-FIXTURES.md` - Test data setup
- `09-DEBUGGING-TROUBLESHOOTING.md` - Debugging API test failures

### Bloom API Documentation
- `/docs/_BloomAppDocs/api/README.md` - Complete API reference
- `CLAUDE.md` - API conventions and patterns
- `docs/ARCHITECTURE.md` - ADR-004 (Next.js 16 async params)

---

**Last Updated:** 2025-11-14
**Version:** 3.1
**Author:** Claude Code (Anthropic)
