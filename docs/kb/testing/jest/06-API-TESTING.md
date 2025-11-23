---
id: jest-06-api-testing
topic: jest
file_role: practical
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [jest-01-fundamentals, jest-03-mocking-spies, jest-04-async-testing]
related_topics: [api-testing, nextjs, http, validation, authentication]
embedding_keywords: [jest, api-testing, http-testing, next-api-routes, backend-testing, route-handlers, zod-validation, authentication, database-testing]
last_reviewed: 2025-11-14
---

# API Testing with Jest

<!-- Query: "How do I test Next.js API routes?" -->
<!-- Query: "Testing HTTP endpoints with Jest" -->
<!-- Query: "How to mock Next.js Request and Response?" -->
<!-- Query: "Testing API authentication and validation" -->

## 1. Purpose

This guide teaches you how to test API routes and backend endpoints with Jest, specifically for Next.js 16 App Router. You'll learn:

- **Testing Next.js 16 route handlers** (GET, POST, PATCH, DELETE) with async params pattern
- **Request/Response mocking** for isolated unit tests
- **Testing authentication** (cookies, tokens, middleware)
- **Testing Zod validation schemas** with valid and invalid inputs
- **Testing database integration** with Prisma and mocked data
- **Real Bloom examples**: Session API, Melissa chat endpoint
- **Testing error handling** (validation errors, 400/403/404/500 responses)
- **End-to-end API testing** vs unit testing trade-offs

**When to use this guide:**
- Building new API endpoints
- Adding validation logic
- Implementing authentication
- Testing database operations
- Debugging failing API tests

**Related guides:**
- `03-MOCKING-SPIES.md` - For mocking dependencies (Prisma, external APIs)
- `04-ASYNC-TESTING.md` - For async/await patterns in API handlers
- `07-DATABASE-TESTING.md` - For comprehensive database testing strategies

---

## 2. Mental Model / Problem Statement

<!-- Query: "What's the difference between API unit tests and integration tests?" -->
<!-- Query: "How do Next.js 16 route handlers work?" -->
<!-- Query: "API testing mental model" -->

### 2.1 The API Testing Spectrum

API tests exist on a spectrum from **pure unit tests** to **full integration tests**:

```
Unit Tests                    Integration Tests                  E2E Tests
────────────────────────────────────────────────────────────────────────
│                             │                                  │
│ Mock everything:            │ Mock external deps only:         │ Mock nothing:
│ - Database (Prisma)         │ - External APIs                  │ - Real database
│ - External APIs             │ - File system                    │ - Real HTTP server
│ - File system               │ Real database (test DB)          │ - Real auth
│                             │                                  │
│ FAST (ms)                   │ MEDIUM (100-500ms)               │ SLOW (1-5s)
│ HIGH isolation              │ MODERATE isolation               │ LOW isolation
│ Catches logic bugs          │ Catches integration bugs         │ Catches UX bugs
└─────────────────────────────┴──────────────────────────────────┴────────────────
```

**Bloom's Testing Strategy:**
- **Unit tests (Jest)**: Test individual route handlers with mocked Prisma
- **Integration tests (Jest)**: Test routes with real database, mocked external APIs
- **E2E tests (Playwright)**: Test full user workflows through the UI

### 2.2 Next.js 16 Route Handler Architecture

Next.js 16 App Router route handlers are **async functions** that:

1. Receive `NextRequest` and optional `params` (as a **Promise** in Next.js 16)
2. Parse and validate input (Zod, cookies, headers)
3. Perform business logic (database queries, calculations)
4. Return `NextResponse` with JSON or streaming response

**CRITICAL: Next.js 16 Async Params Pattern**

```typescript
// ❌ WRONG (Next.js 14/15) - Synchronous params
export async function GET(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  const { id } = params; // Type error in Next.js 16!
}

// ✅ CORRECT (Next.js 16) - Params is a Promise
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params; // Must await the Promise
}
```

**Why this matters for testing:**
- You must mock `params` as a Promise in your tests
- Forgetting to `await params` will cause runtime errors
- TypeScript won't catch this if your mocks are wrong

### 2.3 The Request → Validation → Logic → Response Flow

Every API route follows this pattern:

```typescript
export async function POST(request: NextRequest) {
  try {
    // 1. PARSE INPUT
    const body = await request.json();

    // 2. VALIDATE INPUT (Zod)
    const validatedData = schema.parse(body);

    // 3. CHECK AUTHORIZATION
    const userId = validateAuth(request);

    // 4. PERFORM BUSINESS LOGIC
    const result = await prisma.session.create({
      data: validatedData
    });

    // 5. RETURN SUCCESS RESPONSE
    return NextResponse.json(result, { status: 201 });

  } catch (error) {
    // 6. HANDLE ERRORS (validation, auth, database, unexpected)
    if (error instanceof z.ZodError) {
      return NextResponse.json({ error: "Validation error" }, { status: 400 });
    }
    return NextResponse.json({ error: "Server error" }, { status: 500 });
  }
}
```

**Testing strategy:** Test each step independently:
1. ✅ Valid input → Success path
2. ✅ Invalid input → 400 validation error
3. ✅ Unauthorized → 403 forbidden
4. ✅ Not found → 404 error
5. ✅ Database error → 500 server error

### 2.4 Mocking Philosophy for API Tests

**The Golden Rule:** Mock at the **boundaries** of your system.

```
┌─────────────────────────────────────┐
│  Your Route Handler (REAL)          │  ← Test this
│  ┌─────────────────────────────┐   │
│  │ Validation (Zod - REAL)      │   │  ← Test this
│  └─────────────────────────────┘   │
│  ┌─────────────────────────────┐   │
│  │ Business Logic (REAL)        │   │  ← Test this
│  └─────────────────────────────┘   │
└──────────────┬──────────────────────┘
               │
    ┌──────────┴──────────┐
    │                     │
┌───▼──────────┐  ┌───────▼────────┐
│ Prisma (MOCK)│  │ External API   │  ← Mock here
│              │  │ (MOCK)         │
└──────────────┘  └────────────────┘
```

**Benefits:**
- Fast tests (no database I/O)
- Predictable (no network flakiness)
- Complete coverage (can simulate errors)
- No test data pollution

---

## 3. Golden Path

<!-- Query: "Best practices for API testing with Jest" -->
<!-- Query: "How to structure API tests" -->
<!-- Query: "Recommended API testing approach" -->

### 3.1 Standard API Test Structure

**Bloom Project Convention:**

```
__tests__/
├── api/                    # API route tests
│   ├── sessions.test.ts    # /api/sessions/* routes
│   ├── melissa.test.ts     # /api/melissa/* routes
│   ├── auth.test.ts        # /api/auth/* routes
│   └── helpers/
│       ├── mock-request.ts # Request mocking utilities
│       ├── mock-prisma.ts  # Prisma mocking utilities
│       └── fixtures.ts     # Test data fixtures
└── lib/                    # Business logic tests (separate from API)
```

### 3.2 Test File Template (Complete Example)

```typescript
// __tests__/api/sessions.test.ts
import { describe, it, expect, jest, beforeEach } from '@jest/globals';
import { NextRequest } from 'next/server';
import { POST, GET } from '@/app/api/sessions/route';
import { prisma } from '@/lib/db/client';

// Mock Prisma client (see Section 5.2 for full mock setup)
jest.mock('@/lib/db/client', () => ({
  prisma: {
    session: {
      create: jest.fn(),
      findUnique: jest.fn(),
      findMany: jest.fn(),
    },
  },
}));

// Mock logger to prevent console spam
jest.mock('@/lib/logger', () => ({
  logger: {
    info: jest.fn(),
    error: jest.fn(),
    logSessionCreated: jest.fn(),
  },
}));

describe('POST /api/sessions', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('should create a new session with valid data', async () => {
    // ARRANGE: Mock Prisma response
    const mockSession = {
      id: 'WS-20251114-001',
      status: 'active',
      startedAt: new Date('2025-11-14T10:00:00Z'),
      userId: null,
      organizationId: null,
    };

    (prisma.session.create as jest.Mock).mockResolvedValue(mockSession);

    // ARRANGE: Create mock request
    const request = new NextRequest('http://localhost:3001/api/sessions', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        userId: 'user-123',
        organizationId: 'org-456',
      }),
    });

    // ACT: Call the route handler
    const response = await POST(request);
    const data = await response.json();

    // ASSERT: Verify response
    expect(response.status).toBe(200);
    expect(data.sessionId).toBe('WS-20251114-001');
    expect(data.status).toBe('active');

    // ASSERT: Verify Prisma was called correctly
    expect(prisma.session.create).toHaveBeenCalledTimes(1);
    expect(prisma.session.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        userId: 'user-123',
        organizationId: 'org-456',
        status: 'active',
      }),
    });
  });

  it('should return 400 for invalid input (Zod validation)', async () => {
    // ARRANGE: Invalid employeeCount (negative number)
    const request = new NextRequest('http://localhost:3001/api/sessions', {
      method: 'POST',
      body: JSON.stringify({
        employeeCount: -100, // Invalid: must be >= 1
      }),
    });

    // ACT
    const response = await POST(request);
    const data = await response.json();

    // ASSERT
    expect(response.status).toBe(400);
    expect(data.error).toBe('Invalid request data');
    expect(data.details).toBeDefined();
    expect(data.details[0].path).toContain('employeeCount');

    // ASSERT: Prisma should NOT be called
    expect(prisma.session.create).not.toHaveBeenCalled();
  });

  it('should return 500 for database errors', async () => {
    // ARRANGE: Simulate database error
    (prisma.session.create as jest.Mock).mockRejectedValue(
      new Error('Database connection failed')
    );

    const request = new NextRequest('http://localhost:3001/api/sessions', {
      method: 'POST',
      body: JSON.stringify({ userId: 'user-123' }),
    });

    // ACT
    const response = await POST(request);
    const data = await response.json();

    // ASSERT
    expect(response.status).toBe(500);
    expect(data.error).toBe('Internal server error');
  });
});
```

### 3.3 Testing Routes with Dynamic Params (Next.js 16)

**CRITICAL:** Params are Promises in Next.js 16!

```typescript
// __tests__/api/sessions-by-id.test.ts
import { describe, it, expect, jest, beforeEach } from '@jest/globals';
import { NextRequest } from 'next/server';
import { GET, PATCH } from '@/app/api/sessions/[id]/route';
import { prisma } from '@/lib/db/client';

jest.mock('@/lib/db/client', () => ({
  prisma: {
    session: {
      findUnique: jest.fn(),
      update: jest.fn(),
    },
  },
}));

describe('GET /api/sessions/[id]', () => {
  it('should retrieve a session by ID', async () => {
    // ARRANGE
    const mockSession = {
      id: 'WS-20251114-001',
      status: 'active',
      responses: [],
      roiReport: null,
    };

    (prisma.session.findUnique as jest.Mock).mockResolvedValue(mockSession);

    const request = new NextRequest('http://localhost:3001/api/sessions/WS-20251114-001');

    // ✅ CORRECT: Mock params as a Promise
    const params = Promise.resolve({ id: 'WS-20251114-001' });

    // ACT
    const response = await GET(request, { params });
    const data = await response.json();

    // ASSERT
    expect(response.status).toBe(200);
    expect(data.id).toBe('WS-20251114-001');
    expect(prisma.session.findUnique).toHaveBeenCalledWith({
      where: { id: 'WS-20251114-001' },
      include: { responses: true, roiReport: true },
    });
  });

  it('should return 404 for non-existent session', async () => {
    // ARRANGE: Prisma returns null
    (prisma.session.findUnique as jest.Mock).mockResolvedValue(null);

    const request = new NextRequest('http://localhost:3001/api/sessions/invalid-id');
    const params = Promise.resolve({ id: 'invalid-id' });

    // ACT
    const response = await GET(request, { params });
    const data = await response.json();

    // ASSERT
    expect(response.status).toBe(404);
    expect(data.error).toBe('Session not found');
  });
});
```

### 3.4 Testing Authentication (Cookie-Based)

```typescript
// __tests__/api/sessions-auth.test.ts
import { describe, it, expect, jest } from '@jest/globals';
import { NextRequest } from 'next/server';
import { PATCH } from '@/app/api/sessions/[id]/route';
import { prisma } from '@/lib/db/client';

jest.mock('@/lib/db/client');
jest.mock('@/lib/utils/session-auth', () => ({
  validateSignedUUID: jest.fn((uuid: string) => uuid.startsWith('valid-')),
}));

describe('PATCH /api/sessions/[id] - Authentication', () => {
  const sessionId = 'WS-20251114-001';
  const validEditKey = 'valid-edit-key-123';

  it('should allow updates with valid edit key', async () => {
    // ARRANGE: Mock session with editKey
    (prisma.session.findUnique as jest.Mock).mockResolvedValue({
      editKey: validEditKey,
    });

    (prisma.session.update as jest.Mock).mockResolvedValue({
      id: sessionId,
      customerName: 'Acme Corp',
    });

    // ARRANGE: Request with valid editKey cookie
    const request = new NextRequest(`http://localhost:3001/api/sessions/${sessionId}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'Cookie': `session.editKey.${sessionId}=${validEditKey}`,
      },
      body: JSON.stringify({ customerName: 'Acme Corp' }),
    });

    const params = Promise.resolve({ id: sessionId });

    // ACT
    const response = await PATCH(request, { params });
    const data = await response.json();

    // ASSERT
    expect(response.status).toBe(200);
    expect(data.success).toBe(true);
    expect(prisma.session.update).toHaveBeenCalled();
  });

  it('should return 403 without edit key cookie', async () => {
    // ARRANGE: Request without cookie
    const request = new NextRequest(`http://localhost:3001/api/sessions/${sessionId}`, {
      method: 'PATCH',
      body: JSON.stringify({ customerName: 'Acme Corp' }),
    });

    const params = Promise.resolve({ id: sessionId });

    // ACT
    const response = await PATCH(request, { params });
    const data = await response.json();

    // ASSERT
    expect(response.status).toBe(403);
    expect(data.error).toBe('Unauthorized');
    expect(data.message).toContain('Missing edit key');
    expect(prisma.session.update).not.toHaveBeenCalled();
  });

  it('should return 403 for mismatched edit key', async () => {
    // ARRANGE: Database has different editKey
    (prisma.session.findUnique as jest.Mock).mockResolvedValue({
      editKey: 'valid-different-key',
    });

    const request = new NextRequest(`http://localhost:3001/api/sessions/${sessionId}`, {
      method: 'PATCH',
      headers: {
        'Cookie': `session.editKey.${sessionId}=${validEditKey}`,
      },
      body: JSON.stringify({ customerName: 'Acme Corp' }),
    });

    const params = Promise.resolve({ id: sessionId });

    // ACT
    const response = await PATCH(request, { params });
    const data = await response.json();

    // ASSERT
    expect(response.status).toBe(403);
    expect(data.message).toContain('Edit key mismatch');
  });
});
```

### 3.5 Testing Zod Validation Schemas

```typescript
// __tests__/api/validation.test.ts
import { describe, it, expect, jest } from '@jest/globals';
import { NextRequest } from 'next/server';
import { POST } from '@/app/api/sessions/route';
import { prisma } from '@/lib/db/client';

jest.mock('@/lib/db/client');

describe('Session Validation (Zod)', () => {
  describe('employeeCount validation', () => {
    it('should accept valid employee count', async () => {
      (prisma.session.create as jest.Mock).mockResolvedValue({
        id: 'WS-20251114-001',
        employeeCount: 500,
      });

      const request = new NextRequest('http://localhost:3001/api/sessions', {
        method: 'POST',
        body: JSON.stringify({ employeeCount: 500 }),
      });

      const response = await POST(request);
      expect(response.status).toBe(200);
    });

    it('should reject negative employee count', async () => {
      const request = new NextRequest('http://localhost:3001/api/sessions', {
        method: 'POST',
        body: JSON.stringify({ employeeCount: -10 }),
      });

      const response = await POST(request);
      const data = await response.json();

      expect(response.status).toBe(400);
      expect(data.details[0].message).toContain('greater than or equal to 1');
    });

    it('should reject employee count > 100,000', async () => {
      const request = new NextRequest('http://localhost:3001/api/sessions', {
        method: 'POST',
        body: JSON.stringify({ employeeCount: 200000 }),
      });

      const response = await POST(request);
      expect(response.status).toBe(400);
    });

    it('should reject non-integer employee count', async () => {
      const request = new NextRequest('http://localhost:3001/api/sessions', {
        method: 'POST',
        body: JSON.stringify({ employeeCount: 50.5 }),
      });

      const response = await POST(request);
      expect(response.status).toBe(400);
    });
  });

  describe('email validation', () => {
    it('should accept valid email', async () => {
      (prisma.session.create as jest.Mock).mockResolvedValue({
        id: 'WS-20251114-001',
        customerContact: 'john@example.com',
      });

      const request = new NextRequest('http://localhost:3001/api/sessions', {
        method: 'POST',
        body: JSON.stringify({ customerContact: 'john@example.com' }),
      });

      const response = await POST(request);
      expect(response.status).toBe(200);
    });

    it('should reject invalid email', async () => {
      const request = new NextRequest('http://localhost:3001/api/sessions', {
        method: 'POST',
        body: JSON.stringify({ customerContact: 'not-an-email' }),
      });

      const response = await POST(request);
      const data = await response.json();

      expect(response.status).toBe(400);
      expect(data.details[0].message).toContain('email');
    });
  });

  describe('array validation (attendees)', () => {
    it('should accept valid attendees array', async () => {
      (prisma.session.create as jest.Mock).mockResolvedValue({
        id: 'WS-20251114-001',
      });

      const request = new NextRequest('http://localhost:3001/api/sessions', {
        method: 'POST',
        body: JSON.stringify({
          attendees: [
            { name: 'John Doe', role: 'CTO' },
            { name: 'Jane Smith' },
          ],
        }),
      });

      const response = await POST(request);
      expect(response.status).toBe(200);
    });

    it('should reject attendees with missing name', async () => {
      const request = new NextRequest('http://localhost:3001/api/sessions', {
        method: 'POST',
        body: JSON.stringify({
          attendees: [{ role: 'CTO' }], // Missing required 'name'
        }),
      });

      const response = await POST(request);
      expect(response.status).toBe(400);
    });
  });
});
```

---

## 4. Variations & Trade-Offs

<!-- Query: "When to use unit tests vs integration tests for APIs?" -->
<!-- Query: "Should I mock the database in API tests?" -->
<!-- Query: "API testing strategies comparison" -->

### 4.1 Unit Tests vs Integration Tests

| Aspect | Unit Tests (Mocked) | Integration Tests (Real DB) |
|--------|--------------------|-----------------------------|
| **Speed** | Fast (1-10ms) | Slow (100-500ms) |
| **Isolation** | Complete | Partial |
| **Setup** | Mock configuration | Database setup + migrations |
| **Teardown** | Clear mocks | Rollback transactions or cleanup |
| **Flakiness** | None | Possible (DB state, locks) |
| **Coverage** | Logic + validation | Logic + validation + DB constraints |
| **CI/CD** | Always run | May skip on fast builds |
| **Best For** | Validation, error handling, auth logic | Complex queries, transactions, cascades |

**Bloom's Recommendation:**
- **Write unit tests (mocked)** for:
  - Validation logic (Zod schemas)
  - Authentication/authorization logic
  - Error handling paths
  - Edge cases
- **Write integration tests (real DB)** for:
  - Complex Prisma queries with joins
  - Database constraints and cascades
  - Transaction rollback scenarios
  - Data normalization logic

**Example of both:**

```typescript
// Unit test: Fast, isolated, tests validation
describe('POST /api/sessions - Unit', () => {
  it('validates employeeCount range', async () => {
    const request = new NextRequest('http://localhost:3001/api/sessions', {
      method: 'POST',
      body: JSON.stringify({ employeeCount: -1 }),
    });

    const response = await POST(request);
    expect(response.status).toBe(400);
  });
});

// Integration test: Slow, real DB, tests persistence
describe('POST /api/sessions - Integration', () => {
  it('persists session to database', async () => {
    const request = new NextRequest('http://localhost:3001/api/sessions', {
      method: 'POST',
      body: JSON.stringify({ employeeCount: 100 }),
    });

    const response = await POST(request);
    const data = await response.json();

    // Verify in real database
    const savedSession = await prisma.session.findUnique({
      where: { id: data.sessionId },
    });

    expect(savedSession).not.toBeNull();
    expect(savedSession?.employeeCount).toBe(100);

    // Cleanup
    await prisma.session.delete({ where: { id: data.sessionId } });
  });
});
```

### 4.2 Mocking Strategies for Prisma

**Strategy 1: Mock the entire Prisma client (Unit tests)**

```typescript
// __tests__/api/sessions.test.ts
jest.mock('@/lib/db/client', () => ({
  prisma: {
    session: {
      create: jest.fn(),
      findUnique: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
    },
  },
}));

// PROs:
// - Fast (no database)
// - Complete control over responses
// - Can simulate errors easily

// CONs:
// - Doesn't catch Prisma query mistakes
// - Doesn't test database constraints
// - Must mock every method used
```

**Strategy 2: Use a test database (Integration tests)**

```typescript
// __tests__/integration/sessions.test.ts
import { prisma } from '@/lib/db/client'; // Real Prisma client

beforeEach(async () => {
  // Clear test data
  await prisma.session.deleteMany({
    where: { id: { startsWith: 'TEST-' } },
  });
});

afterAll(async () => {
  await prisma.$disconnect();
});

// PROs:
// - Tests real Prisma queries
// - Catches database constraint violations
// - Tests complex joins and transactions

// CONs:
// - Slower (50-500ms per test)
// - Requires test database setup
// - Can have state pollution if not careful
```

**Strategy 3: Prisma Mock Library (Alternative)**

```typescript
import { createMockPrismaClient } from 'jest-mock-extended';

const prismaMock = createMockPrismaClient();

jest.mock('@/lib/db/client', () => ({
  prisma: prismaMock,
}));

// PROs:
// - Type-safe mocking with TypeScript
// - Auto-completion for Prisma methods
// - Less verbose than manual mocks

// CONs:
// - Extra dependency
// - Learning curve
```

**Bloom's Choice:** Strategy 1 (manual mocks) for unit tests, Strategy 2 (real DB) for critical paths.

### 4.3 Testing POST vs GET vs PATCH vs DELETE

Different HTTP methods have different testing priorities:

| Method | Primary Test Focus | Secondary Test Focus |
|--------|-------------------|---------------------|
| **GET** | 404 handling, query params, filtering | Authorization, pagination |
| **POST** | Validation (400), creation success (201), idempotency | Authorization, duplicate detection |
| **PATCH** | Partial update validation, 404 handling, authorization | Optimistic locking, audit logs |
| **DELETE** | 404 handling, authorization, cascade deletes | Soft delete vs hard delete |

**Example: Comprehensive GET test suite**

```typescript
describe('GET /api/sessions', () => {
  describe('Query parameter filtering', () => {
    it('filters by sessionId');
    it('filters by userId');
    it('filters by status');
    it('filters by multiple params');
  });

  describe('Response structure', () => {
    it('returns single session when sessionId provided');
    it('returns array when listing sessions');
    it('includes pagination metadata');
    it('includes response counts');
  });

  describe('Error handling', () => {
    it('returns 404 for non-existent sessionId');
    it('returns 500 for database errors');
    it('returns 400 for invalid query params');
  });

  describe('Authorization', () => {
    it('allows public access to own sessions');
    it('requires auth for other users\' sessions');
  });
});
```

### 4.4 Testing Streaming Responses (Server-Sent Events)

Some endpoints (like Melissa chat) may stream responses. Testing strategies:

```typescript
// __tests__/api/melissa-stream.test.ts
import { describe, it, expect, jest } from '@jest/globals';
import { POST } from '@/app/api/melissa/chat/route';

describe('POST /api/melissa/chat - Streaming', () => {
  it('should stream response chunks', async () => {
    const request = new NextRequest('http://localhost:3001/api/melissa/chat', {
      method: 'POST',
      body: JSON.stringify({
        sessionId: 'WS-20251114-001',
        message: 'Hello',
      }),
    });

    const response = await POST(request);

    // Check for streaming headers
    expect(response.headers.get('Content-Type')).toBe('text/event-stream');
    expect(response.headers.get('Cache-Control')).toBe('no-cache');

    // Read stream chunks
    const reader = response.body?.getReader();
    const decoder = new TextDecoder();
    const chunks: string[] = [];

    if (reader) {
      let done = false;
      while (!done) {
        const { value, done: streamDone } = await reader.read();
        done = streamDone;
        if (value) {
          chunks.push(decoder.decode(value));
        }
      }
    }

    expect(chunks.length).toBeGreaterThan(0);
    expect(chunks.join('')).toContain('data:');
  });
});
```

---

## 5. Examples

<!-- Query: "Real Bloom API test examples" -->
<!-- Query: "Complete API test suite example" -->

### 5.1 Complete Session API Test Suite

```typescript
// __tests__/api/sessions-complete.test.ts
import { describe, it, expect, jest, beforeEach, afterAll } from '@jest/globals';
import { NextRequest } from 'next/server';
import { GET, POST } from '@/app/api/sessions/route';
import { GET as GET_BY_ID, PATCH } from '@/app/api/sessions/[id]/route';
import { prisma } from '@/lib/db/client';

// Mock Prisma
jest.mock('@/lib/db/client', () => ({
  prisma: {
    session: {
      create: jest.fn(),
      findUnique: jest.fn(),
      findMany: jest.fn(),
      update: jest.fn(),
    },
  },
}));

// Mock logger
jest.mock('@/lib/logger', () => ({
  logger: {
    info: jest.fn(),
    error: jest.fn(),
    logSessionCreated: jest.fn(),
  },
}));

// Mock session ID generator
jest.mock('@/lib/sessions/id-generator', () => ({
  SessionIdGenerator: {
    generate: jest.fn(async () => 'WS-20251114-001'),
  },
}));

// Mock auth utilities
jest.mock('@/lib/utils/session-auth', () => ({
  generateSignedUUID: jest.fn(() => 'valid-edit-key-123'),
  validateSignedUUID: jest.fn(() => true),
}));

describe('Sessions API - Complete Suite', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  afterAll(() => {
    jest.restoreAllMocks();
  });

  describe('POST /api/sessions - Create Session', () => {
    const validSession = {
      id: 'WS-20251114-001',
      status: 'active',
      startedAt: new Date('2025-11-14T10:00:00Z'),
      userId: null,
      organizationId: null,
      editKey: 'valid-edit-key-123',
      customerName: null,
      customerIndustry: null,
      employeeCount: null,
    };

    it('creates session with minimal data', async () => {
      (prisma.session.create as jest.Mock).mockResolvedValue(validSession);

      const request = new NextRequest('http://localhost:3001/api/sessions', {
        method: 'POST',
        body: JSON.stringify({}),
      });

      const response = await POST(request);
      const data = await response.json();

      expect(response.status).toBe(200);
      expect(data.sessionId).toBe('WS-20251114-001');
      expect(response.cookies.get(`session.editKey.${data.sessionId}`)).toBeDefined();
    });

    it('creates session with full context data', async () => {
      (prisma.session.create as jest.Mock).mockResolvedValue({
        ...validSession,
        customerName: 'Acme Corp',
        customerIndustry: 'Manufacturing',
        employeeCount: 500,
      });

      const request = new NextRequest('http://localhost:3001/api/sessions', {
        method: 'POST',
        body: JSON.stringify({
          customerName: 'Acme Corp',
          customerIndustry: 'Manufacturing',
          employeeCount: 500,
          customerLocation: 'San Francisco, CA',
          problemStatement: 'Optimize invoice processing',
          department: 'Finance',
          customerContact: 'john@acme.com',
          attendees: [
            { name: 'John Doe', role: 'CFO' },
            { name: 'Jane Smith', role: 'Finance Manager' },
          ],
        }),
      });

      const response = await POST(request);
      const data = await response.json();

      expect(response.status).toBe(200);
      expect(prisma.session.create).toHaveBeenCalledWith({
        data: expect.objectContaining({
          customerName: 'Acme Corp',
          employeeCount: 500,
          attendees: expect.any(String), // Stringified JSON
        }),
      });
    });

    it('respects idempotency key', async () => {
      (prisma.session.create as jest.Mock).mockResolvedValue(validSession);

      const idempotencyKey = 'test-idempotency-key-123';

      // First request
      const request1 = new NextRequest('http://localhost:3001/api/sessions', {
        method: 'POST',
        headers: { 'X-Idempotency-Key': idempotencyKey },
        body: JSON.stringify({}),
      });

      const response1 = await POST(request1);
      const data1 = await response1.json();

      expect(response1.status).toBe(200);
      expect(prisma.session.create).toHaveBeenCalledTimes(1);

      // Second request with same key (should return cached)
      const request2 = new NextRequest('http://localhost:3001/api/sessions', {
        method: 'POST',
        headers: { 'X-Idempotency-Key': idempotencyKey },
        body: JSON.stringify({}),
      });

      const response2 = await POST(request2);
      const data2 = await response2.json();

      expect(response2.status).toBe(200);
      expect(data2.sessionId).toBe(data1.sessionId);
      expect(prisma.session.create).toHaveBeenCalledTimes(1); // Still only 1 call
    });

    describe('Validation errors', () => {
      it('rejects negative employeeCount', async () => {
        const request = new NextRequest('http://localhost:3001/api/sessions', {
          method: 'POST',
          body: JSON.stringify({ employeeCount: -100 }),
        });

        const response = await POST(request);
        const data = await response.json();

        expect(response.status).toBe(400);
        expect(data.error).toBe('Invalid request data');
        expect(data.details).toHaveLength(1);
        expect(data.details[0].path).toContain('employeeCount');
      });

      it('rejects employeeCount > 100,000', async () => {
        const request = new NextRequest('http://localhost:3001/api/sessions', {
          method: 'POST',
          body: JSON.stringify({ employeeCount: 200000 }),
        });

        const response = await POST(request);
        expect(response.status).toBe(400);
      });

      it('rejects invalid email', async () => {
        const request = new NextRequest('http://localhost:3001/api/sessions', {
          method: 'POST',
          body: JSON.stringify({ customerContact: 'not-an-email' }),
        });

        const response = await POST(request);
        expect(response.status).toBe(400);
      });

      it('rejects malformed attendees array', async () => {
        const request = new NextRequest('http://localhost:3001/api/sessions', {
          method: 'POST',
          body: JSON.stringify({
            attendees: [{ role: 'CFO' }], // Missing required 'name'
          }),
        });

        const response = await POST(request);
        expect(response.status).toBe(400);
      });
    });

    it('handles database errors gracefully', async () => {
      (prisma.session.create as jest.Mock).mockRejectedValue(
        new Error('Database connection lost')
      );

      const request = new NextRequest('http://localhost:3001/api/sessions', {
        method: 'POST',
        body: JSON.stringify({}),
      });

      const response = await POST(request);
      const data = await response.json();

      expect(response.status).toBe(500);
      expect(data.error).toBe('Internal server error');
    });
  });

  describe('GET /api/sessions - List Sessions', () => {
    const mockSessions = [
      {
        id: 'WS-20251114-001',
        title: 'Acme Corp Workshop',
        status: 'active',
        startedAt: new Date('2025-11-14T10:00:00Z'),
        completedAt: null,
        metadata: '{}',
        responses: [{ id: 'resp-1' }, { id: 'resp-2' }],
      },
      {
        id: 'WS-20251114-002',
        title: 'TechCo Workshop',
        status: 'completed',
        startedAt: new Date('2025-11-14T11:00:00Z'),
        completedAt: new Date('2025-11-14T11:15:00Z'),
        metadata: '{}',
        responses: [{ id: 'resp-3' }],
      },
    ];

    it('returns all sessions without filters', async () => {
      (prisma.session.findMany as jest.Mock).mockResolvedValue(mockSessions);

      const request = new NextRequest('http://localhost:3001/api/sessions');

      const response = await GET(request);
      const data = await response.json();

      expect(response.status).toBe(200);
      expect(data.sessions).toHaveLength(2);
      expect(data.sessions[0].id).toBe('WS-20251114-001');
      expect(data.sessions[0].responseCount).toBe(2);
    });

    it('filters by status', async () => {
      (prisma.session.findMany as jest.Mock).mockResolvedValue([mockSessions[1]]);

      const request = new NextRequest('http://localhost:3001/api/sessions?status=completed');

      const response = await GET(request);
      const data = await response.json();

      expect(response.status).toBe(200);
      expect(data.sessions).toHaveLength(1);
      expect(data.sessions[0].status).toBe('completed');
      expect(prisma.session.findMany).toHaveBeenCalledWith({
        where: { status: 'completed' },
        select: expect.any(Object),
        orderBy: { startedAt: 'desc' },
        take: 50,
      });
    });

    it('filters by userId', async () => {
      (prisma.session.findMany as jest.Mock).mockResolvedValue([mockSessions[0]]);

      const request = new NextRequest('http://localhost:3001/api/sessions?userId=user-123');

      const response = await GET(request);
      const data = await response.json();

      expect(response.status).toBe(200);
      expect(prisma.session.findMany).toHaveBeenCalledWith({
        where: { userId: 'user-123' },
        orderBy: { startedAt: 'desc' },
        take: 10,
      });
    });
  });

  describe('GET /api/sessions/[id] - Get Single Session', () => {
    const mockSession = {
      id: 'WS-20251114-001',
      title: 'Acme Corp Workshop',
      status: 'active',
      responses: [],
      roiReport: null,
    };

    it('returns session by ID', async () => {
      (prisma.session.findUnique as jest.Mock).mockResolvedValue(mockSession);

      const request = new NextRequest('http://localhost:3001/api/sessions/WS-20251114-001');
      const params = Promise.resolve({ id: 'WS-20251114-001' });

      const response = await GET_BY_ID(request, { params });
      const data = await response.json();

      expect(response.status).toBe(200);
      expect(data.id).toBe('WS-20251114-001');
      expect(prisma.session.findUnique).toHaveBeenCalledWith({
        where: { id: 'WS-20251114-001' },
        include: { responses: true, roiReport: true },
      });
    });

    it('returns 404 for non-existent session', async () => {
      (prisma.session.findUnique as jest.Mock).mockResolvedValue(null);

      const request = new NextRequest('http://localhost:3001/api/sessions/invalid-id');
      const params = Promise.resolve({ id: 'invalid-id' });

      const response = await GET_BY_ID(request, { params });
      const data = await response.json();

      expect(response.status).toBe(404);
      expect(data.error).toBe('Session not found');
    });

    it('handles database errors', async () => {
      (prisma.session.findUnique as jest.Mock).mockRejectedValue(
        new Error('Database query failed')
      );

      const request = new NextRequest('http://localhost:3001/api/sessions/WS-20251114-001');
      const params = Promise.resolve({ id: 'WS-20251114-001' });

      const response = await GET_BY_ID(request, { params });
      const data = await response.json();

      expect(response.status).toBe(500);
      expect(data.error).toBe('Internal server error');
    });
  });

  describe('PATCH /api/sessions/[id] - Update Session', () => {
    const sessionId = 'WS-20251114-001';
    const validEditKey = 'valid-edit-key-123';

    beforeEach(() => {
      // Default: session exists with matching editKey
      (prisma.session.findUnique as jest.Mock).mockResolvedValue({
        editKey: validEditKey,
      });

      (prisma.session.update as jest.Mock).mockResolvedValue({
        id: sessionId,
        customerName: 'Updated Corp',
      });
    });

    it('updates session with valid edit key', async () => {
      const request = new NextRequest(`http://localhost:3001/api/sessions/${sessionId}`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'Cookie': `session.editKey.${sessionId}=${validEditKey}`,
        },
        body: JSON.stringify({
          customerName: 'Updated Corp',
          employeeCount: 750,
        }),
      });

      const params = Promise.resolve({ id: sessionId });

      const response = await PATCH(request, { params });
      const data = await response.json();

      expect(response.status).toBe(200);
      expect(data.success).toBe(true);
      expect(data.updated).toContain('customerName');
      expect(prisma.session.update).toHaveBeenCalledWith({
        where: { id: sessionId },
        data: expect.objectContaining({
          customerName: 'Updated Corp',
          employeeCount: 750,
          lastEditedAt: expect.any(String),
        }),
      });
    });

    it('rejects update without edit key cookie', async () => {
      const request = new NextRequest(`http://localhost:3001/api/sessions/${sessionId}`, {
        method: 'PATCH',
        body: JSON.stringify({ customerName: 'Hacked Corp' }),
      });

      const params = Promise.resolve({ id: sessionId });

      const response = await PATCH(request, { params });
      const data = await response.json();

      expect(response.status).toBe(403);
      expect(data.error).toBe('Unauthorized');
      expect(data.message).toContain('Missing edit key');
      expect(prisma.session.update).not.toHaveBeenCalled();
    });

    it('rejects update with mismatched edit key', async () => {
      // Mock session has different editKey
      (prisma.session.findUnique as jest.Mock).mockResolvedValue({
        editKey: 'valid-different-key-456',
      });

      const request = new NextRequest(`http://localhost:3001/api/sessions/${sessionId}`, {
        method: 'PATCH',
        headers: {
          'Cookie': `session.editKey.${sessionId}=${validEditKey}`,
        },
        body: JSON.stringify({ customerName: 'Hacked Corp' }),
      });

      const params = Promise.resolve({ id: sessionId });

      const response = await PATCH(request, { params });
      const data = await response.json();

      expect(response.status).toBe(403);
      expect(data.message).toContain('Edit key mismatch');
      expect(prisma.session.update).not.toHaveBeenCalled();
    });

    it('returns 404 for non-existent session', async () => {
      (prisma.session.findUnique as jest.Mock).mockResolvedValue(null);

      const request = new NextRequest(`http://localhost:3001/api/sessions/${sessionId}`, {
        method: 'PATCH',
        headers: {
          'Cookie': `session.editKey.${sessionId}=${validEditKey}`,
        },
        body: JSON.stringify({ customerName: 'Updated Corp' }),
      });

      const params = Promise.resolve({ id: sessionId });

      const response = await PATCH(request, { params });
      const data = await response.json();

      expect(response.status).toBe(404);
      expect(data.error).toBe('Not Found');
    });

    it('validates partial updates correctly', async () => {
      const request = new NextRequest(`http://localhost:3001/api/sessions/${sessionId}`, {
        method: 'PATCH',
        headers: {
          'Cookie': `session.editKey.${sessionId}=${validEditKey}`,
        },
        body: JSON.stringify({
          employeeCount: -50, // Invalid
        }),
      });

      const params = Promise.resolve({ id: sessionId });

      const response = await PATCH(request, { params });
      const data = await response.json();

      expect(response.status).toBe(400);
      expect(data.error).toBe('Invalid request data');
    });
  });
});
```

### 5.2 Melissa Chat API Test (Complex Example)

```typescript
// __tests__/api/melissa-chat.test.ts
import { describe, it, expect, jest, beforeEach } from '@jest/globals';
import { NextRequest } from 'next/server';
import { POST } from '@/app/api/melissa/chat/route';
import { prisma } from '@/lib/db/client';
import { MelissaAgent } from '@/lib/melissa/agent';

// Mock Prisma
jest.mock('@/lib/db/client', () => ({
  prisma: {
    session: {
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
    response: {
      create: jest.fn(),
    },
    sessionMemory: {
      findUnique: jest.fn(),
    },
    sessionInstructions: {
      findUnique: jest.fn(),
    },
    sessionFile: {
      findMany: jest.fn(),
    },
  },
}));

// Mock Melissa agent
jest.mock('@/lib/melissa/agent', () => ({
  MelissaAgent: {
    create: jest.fn(),
  },
}));

// Mock logger
jest.mock('@/lib/logger', () => ({
  logger: {
    info: jest.fn(),
    warn: jest.fn(),
    error: jest.fn(),
  },
}));

// Mock context loader
jest.mock('@/lib/melissa/context-loader', () => ({
  loadBloomContext: jest.fn(async () => null),
}));

describe('POST /api/melissa/chat', () => {
  const sessionId = 'WS-20251114-001';

  beforeEach(() => {
    jest.clearAllMocks();

    // Set required env var
    process.env.ANTHROPIC_API_KEY = 'test-key';
  });

  it('processes a chat message successfully', async () => {
    // ARRANGE: Mock existing session
    (prisma.session.findUnique as jest.Mock).mockResolvedValue({
      id: sessionId,
      userId: '',
      organizationId: '',
      startedAt: new Date('2025-11-14T10:00:00Z'),
      transcript: JSON.stringify([]),
      metadata: JSON.stringify({}),
      responses: [],
    });

    // Mock Bloom Intelligence context (empty)
    (prisma.sessionMemory.findUnique as jest.Mock).mockResolvedValue(null);
    (prisma.sessionInstructions.findUnique as jest.Mock).mockResolvedValue(null);
    (prisma.sessionFile.findMany as jest.Mock).mockResolvedValue([]);

    // Mock Melissa agent
    const mockAgent = {
      processMessage: jest.fn(async () => ({
        message: 'Great! Tell me more about your process.',
        phase: 'discovery',
        progress: 25,
        needsUserInput: true,
        confidence: 60,
      })),
    };

    (MelissaAgent.create as jest.Mock).mockResolvedValue(mockAgent);

    // Mock response creation
    (prisma.response.create as jest.Mock).mockResolvedValue({
      id: 'resp-1',
    });

    // ARRANGE: Request
    const request = new NextRequest('http://localhost:3001/api/melissa/chat', {
      method: 'POST',
      body: JSON.stringify({
        sessionId,
        message: 'I want to optimize invoice processing',
      }),
    });

    // ACT
    const response = await POST(request);
    const data = await response.json();

    // ASSERT
    expect(response.status).toBe(200);
    expect(data.message).toBe('Great! Tell me more about your process.');
    expect(data.phase).toBe('discovery');
    expect(data.progress).toBe(25);
    expect(mockAgent.processMessage).toHaveBeenCalledWith(
      'I want to optimize invoice processing',
      []
    );
    expect(prisma.response.create).toHaveBeenCalled();
  });

  it('creates session if it doesn\'t exist', async () => {
    // ARRANGE: No existing session
    (prisma.session.findUnique as jest.Mock).mockResolvedValue(null);

    // Mock session creation
    (prisma.session.create as jest.Mock).mockResolvedValue({
      id: sessionId,
      userId: '',
      organizationId: '',
      startedAt: new Date(),
      transcript: JSON.stringify([]),
      metadata: JSON.stringify({}),
      responses: [],
    });

    // Mock context and agent
    (prisma.sessionMemory.findUnique as jest.Mock).mockResolvedValue(null);
    (prisma.sessionInstructions.findUnique as jest.Mock).mockResolvedValue(null);
    (prisma.sessionFile.findMany as jest.Mock).mockResolvedValue([]);

    const mockAgent = {
      processMessage: jest.fn(async () => ({
        message: 'Hello!',
        phase: 'greeting',
        progress: 0,
        needsUserInput: true,
      })),
    };

    (MelissaAgent.create as jest.Mock).mockResolvedValue(mockAgent);
    (prisma.response.create as jest.Mock).mockResolvedValue({ id: 'resp-1' });

    const request = new NextRequest('http://localhost:3001/api/melissa/chat', {
      method: 'POST',
      body: JSON.stringify({
        sessionId: 'NEW-SESSION-123',
        message: 'Hello',
      }),
    });

    // ACT
    const response = await POST(request);
    const data = await response.json();

    // ASSERT
    expect(response.status).toBe(200);
    expect(prisma.session.create).toHaveBeenCalledWith({
      data: {
        id: 'NEW-SESSION-123',
        userId: '',
        organizationId: '',
        status: 'active',
        startedAt: expect.any(Date),
        transcript: JSON.stringify([]),
        metadata: JSON.stringify({}),
      },
      include: { responses: true },
    });
  });

  it('returns 400 for invalid request (Zod validation)', async () => {
    const request = new NextRequest('http://localhost:3001/api/melissa/chat', {
      method: 'POST',
      body: JSON.stringify({
        sessionId: '', // Empty string (invalid)
        message: 'Hello',
      }),
    });

    const response = await POST(request);
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toBe('Invalid request data');
    expect(data.retryable).toBe(false);
  });

  it('returns 503 when ANTHROPIC_API_KEY is missing', async () => {
    delete process.env.ANTHROPIC_API_KEY;

    const request = new NextRequest('http://localhost:3001/api/melissa/chat', {
      method: 'POST',
      body: JSON.stringify({
        sessionId,
        message: 'Hello',
      }),
    });

    const response = await POST(request);
    const data = await response.json();

    expect(response.status).toBe(503);
    expect(data.error).toBe('Configuration Error');
    expect(data.retryable).toBe(false);

    // Restore env var
    process.env.ANTHROPIC_API_KEY = 'test-key';
  });

  it('returns 503 for database errors', async () => {
    (prisma.session.findUnique as jest.Mock).mockRejectedValue(
      new Error('Database connection lost')
    );

    const request = new NextRequest('http://localhost:3001/api/melissa/chat', {
      method: 'POST',
      body: JSON.stringify({
        sessionId,
        message: 'Hello',
      }),
    });

    const response = await POST(request);
    const data = await response.json();

    expect(response.status).toBe(503);
    expect(data.error).toBe('Database Error');
    expect(data.retryable).toBe(true);
  });

  it('returns 503 for AI service errors', async () => {
    (prisma.session.findUnique as jest.Mock).mockResolvedValue({
      id: sessionId,
      transcript: JSON.stringify([]),
      metadata: JSON.stringify({}),
      responses: [],
    });

    // Mock context
    (prisma.sessionMemory.findUnique as jest.Mock).mockResolvedValue(null);
    (prisma.sessionInstructions.findUnique as jest.Mock).mockResolvedValue(null);
    (prisma.sessionFile.findMany as jest.Mock).mockResolvedValue([]);

    // Mock agent failure
    const mockAgent = {
      processMessage: jest.fn(async () => {
        throw new Error('Anthropic API rate limit exceeded');
      }),
    };

    (MelissaAgent.create as jest.Mock).mockResolvedValue(mockAgent);

    const request = new NextRequest('http://localhost:3001/api/melissa/chat', {
      method: 'POST',
      body: JSON.stringify({
        sessionId,
        message: 'Hello',
      }),
    });

    const response = await POST(request);
    const data = await response.json();

    expect(response.status).toBe(503);
    expect(data.error).toBe('AI Service Error');
    expect(data.retryable).toBe(true);
  });

  it('loads Bloom Intelligence context (Memory, Instructions, Files)', async () => {
    (prisma.session.findUnique as jest.Mock).mockResolvedValue({
      id: sessionId,
      organizationId: 'org-123',
      transcript: JSON.stringify([]),
      metadata: JSON.stringify({}),
      responses: [],
    });

    // Mock context data
    (prisma.sessionMemory.findUnique as jest.Mock).mockResolvedValue({
      content: 'Previous conversation summary...',
    });

    (prisma.sessionInstructions.findUnique as jest.Mock).mockResolvedValue({
      content: 'Custom instructions for this session...',
    });

    (prisma.sessionFile.findMany as jest.Mock).mockResolvedValue([
      { id: 'file-1', filename: 'data.csv', fileType: 'text/csv', fileSize: 1024 },
    ]);

    // Mock agent
    const mockAgent = {
      processMessage: jest.fn(async () => ({
        message: 'Response',
        phase: 'discovery',
        progress: 50,
        needsUserInput: true,
      })),
    };

    (MelissaAgent.create as jest.Mock).mockResolvedValue(mockAgent);
    (prisma.response.create as jest.Mock).mockResolvedValue({ id: 'resp-1' });

    const request = new NextRequest('http://localhost:3001/api/melissa/chat', {
      method: 'POST',
      body: JSON.stringify({
        sessionId,
        message: 'Hello',
      }),
    });

    const response = await POST(request);
    expect(response.status).toBe(200);

    // Verify agent was created with context
    expect(MelissaAgent.create).toHaveBeenCalledWith({
      sessionId,
      userId: undefined,
      organizationId: 'org-123',
      existingState: expect.objectContaining({
        context: {
          memory: 'Previous conversation summary...',
          instructions: 'Custom instructions for this session...',
          files: [
            { id: 'file-1', filename: 'data.csv', fileType: 'text/csv', fileSize: 1024 },
          ],
        },
      }),
    });
  });
});
```

### 5.3 Test Utilities and Helpers

Create reusable test utilities for common patterns:

```typescript
// __tests__/api/helpers/mock-request.ts
import { NextRequest } from 'next/server';

/**
 * Create a mock NextRequest for testing
 */
export function createMockRequest(
  url: string,
  options?: {
    method?: string;
    body?: any;
    headers?: Record<string, string>;
    cookies?: Record<string, string>;
    searchParams?: Record<string, string>;
  }
): NextRequest {
  const { method = 'GET', body, headers = {}, cookies = {}, searchParams = {} } = options || {};

  // Build URL with search params
  const urlObj = new URL(url);
  Object.entries(searchParams).forEach(([key, value]) => {
    urlObj.searchParams.set(key, value);
  });

  // Build cookie header
  const cookieHeader = Object.entries(cookies)
    .map(([key, value]) => `${key}=${value}`)
    .join('; ');

  if (cookieHeader) {
    headers['Cookie'] = cookieHeader;
  }

  // Create request
  const requestInit: RequestInit = {
    method,
    headers,
  };

  if (body !== undefined) {
    requestInit.body = typeof body === 'string' ? body : JSON.stringify(body);
    headers['Content-Type'] = headers['Content-Type'] || 'application/json';
  }

  return new NextRequest(urlObj.toString(), requestInit);
}

/**
 * Create a mock params object (Next.js 16 async pattern)
 */
export function createMockParams<T extends Record<string, string>>(
  params: T
): Promise<T> {
  return Promise.resolve(params);
}

/**
 * Extract JSON from NextResponse
 */
export async function extractResponseJson(response: Response): Promise<any> {
  return response.json();
}

/**
 * Extract cookies from NextResponse
 */
export function extractResponseCookies(response: Response): Record<string, string> {
  const cookies: Record<string, string> = {};
  const setCookieHeaders = response.headers.getSetCookie();

  setCookieHeaders.forEach((cookie) => {
    const [nameValue] = cookie.split(';');
    const [name, value] = nameValue.split('=');
    cookies[name.trim()] = value.trim();
  });

  return cookies;
}
```

```typescript
// __tests__/api/helpers/mock-prisma.ts
import { jest } from '@jest/globals';

/**
 * Create a mock Prisma client with common methods
 */
export function createMockPrismaClient() {
  return {
    session: {
      create: jest.fn(),
      findUnique: jest.fn(),
      findMany: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
      deleteMany: jest.fn(),
    },
    response: {
      create: jest.fn(),
      findMany: jest.fn(),
    },
    roiReport: {
      create: jest.fn(),
      findUnique: jest.fn(),
      update: jest.fn(),
    },
    user: {
      create: jest.fn(),
      findUnique: jest.fn(),
    },
    organization: {
      create: jest.fn(),
      findUnique: jest.fn(),
    },
    $disconnect: jest.fn(),
  };
}

/**
 * Reset all Prisma mocks
 */
export function resetPrismaMocks(prismaMock: ReturnType<typeof createMockPrismaClient>) {
  Object.values(prismaMock).forEach((model) => {
    if (typeof model === 'object') {
      Object.values(model).forEach((method) => {
        if (typeof method === 'function' && 'mockClear' in method) {
          (method as jest.Mock).mockClear();
        }
      });
    }
  });
}
```

```typescript
// __tests__/api/helpers/fixtures.ts
/**
 * Test data fixtures for consistent test data
 */
export const fixtures = {
  session: {
    valid: () => ({
      id: 'WS-20251114-001',
      status: 'active',
      startedAt: new Date('2025-11-14T10:00:00Z'),
      completedAt: null,
      userId: null,
      organizationId: null,
      editKey: 'valid-edit-key-123',
      transcript: JSON.stringify([]),
      metadata: JSON.stringify({}),
      customerName: 'Acme Corp',
      customerIndustry: 'Manufacturing',
      employeeCount: 500,
    }),
    withContext: () => ({
      ...fixtures.session.valid(),
      customerName: 'Acme Corp',
      customerIndustry: 'Manufacturing',
      employeeCount: 500,
      customerLocation: 'San Francisco, CA',
      problemStatement: 'Optimize invoice processing',
      department: 'Finance',
      customerContact: 'john@acme.com',
      attendees: JSON.stringify([
        { name: 'John Doe', role: 'CFO' },
        { name: 'Jane Smith', role: 'Finance Manager' },
      ]),
    }),
  },

  response: {
    valid: () => ({
      id: 'resp-1',
      sessionId: 'WS-20251114-001',
      questionId: 'q-1',
      question: 'What process are you optimizing?',
      answer: 'Invoice processing',
      confidence: 0.8,
      createdAt: new Date('2025-11-14T10:05:00Z'),
    }),
  },

  roiReport: {
    valid: () => ({
      id: 'roi-1',
      sessionId: 'WS-20251114-001',
      reportData: JSON.stringify({
        npv: 150000,
        irr: 0.35,
        paybackPeriod: 1.5,
      }),
      confidenceScore: 0.85,
      generatedAt: new Date('2025-11-14T10:15:00Z'),
    }),
  },
};
```

---

## 6. Common Pitfalls

<!-- Query: "Common mistakes when testing APIs with Jest" -->
<!-- Query: "API testing gotchas" -->

### 6.1 Forgetting to Await Params (Next.js 16)

**Problem:** Params are Promises in Next.js 16, but easy to forget in tests.

```typescript
// ❌ WRONG - params is not awaited
const params = { id: 'WS-20251114-001' }; // Should be Promise!
const response = await GET(request, { params });
// Runtime error: Cannot read properties of undefined

// ✅ CORRECT
const params = Promise.resolve({ id: 'WS-20251114-001' });
const response = await GET(request, { params });
```

**Solution:** Always use `Promise.resolve()` for params in tests. Create a helper:

```typescript
function mockParams<T>(params: T): Promise<T> {
  return Promise.resolve(params);
}

const response = await GET(request, { params: mockParams({ id: 'test' }) });
```

### 6.2 Not Clearing Mocks Between Tests

**Problem:** Mock state leaks between tests, causing flaky results.

```typescript
// ❌ WRONG - Mocks retain state
describe('API tests', () => {
  it('test 1', async () => {
    (prisma.session.create as jest.Mock).mockResolvedValue({ id: 'session-1' });
    // Test runs...
  });

  it('test 2', async () => {
    // Mock from test 1 still active!
    const response = await POST(request);
    // May get unexpected 'session-1' instead of error
  });
});

// ✅ CORRECT - Clear mocks before each test
describe('API tests', () => {
  beforeEach(() => {
    jest.clearAllMocks(); // Clear call history and mock implementations
  });

  it('test 1', async () => {
    (prisma.session.create as jest.Mock).mockResolvedValue({ id: 'session-1' });
  });

  it('test 2', async () => {
    // Clean slate
  });
});
```

### 6.3 Testing Implementation Instead of Behavior

**Problem:** Tests are too coupled to implementation details.

```typescript
// ❌ WRONG - Testing implementation
it('calls prisma.session.create with exact arguments', async () => {
  const response = await POST(request);

  expect(prisma.session.create).toHaveBeenCalledWith({
    data: {
      id: 'WS-20251114-001',
      userId: null,
      organizationId: null,
      status: 'active',
      startedAt: new Date('2025-11-14T10:00:00.000Z'), // Fragile!
      transcript: '[]',
      metadata: '{}',
      // ... 20 more fields
    },
  });
  // Breaks whenever implementation changes slightly
});

// ✅ CORRECT - Testing behavior
it('creates a session with active status', async () => {
  const response = await POST(request);
  const data = await response.json();

  // Test observable behavior
  expect(response.status).toBe(200);
  expect(data.sessionId).toBeDefined();
  expect(data.status).toBe('active');

  // Test important implementation details
  expect(prisma.session.create).toHaveBeenCalledWith({
    data: expect.objectContaining({
      status: 'active',
      userId: null,
    }),
  });
  // More resilient to refactoring
});
```

### 6.4 Not Testing Error Paths

**Problem:** Only testing happy path, missing error handling bugs.

```typescript
// ❌ WRONG - Only tests success
describe('POST /api/sessions', () => {
  it('creates a session', async () => {
    // ... test happy path only
  });
});

// ✅ CORRECT - Tests all paths
describe('POST /api/sessions', () => {
  it('creates a session with valid data', async () => {
    // Happy path
  });

  describe('Error handling', () => {
    it('returns 400 for validation errors', async () => {
      // Invalid input
    });

    it('returns 500 for database errors', async () => {
      // Simulate DB failure
    });

    it('returns 503 for missing configuration', async () => {
      // Missing env vars
    });
  });
});
```

### 6.5 Hardcoding URLs Instead of Using Environment Variables

**Problem:** Tests break in different environments (CI, staging, prod).

```typescript
// ❌ WRONG - Hardcoded URL
const request = new NextRequest('http://localhost:3001/api/sessions', {
  method: 'POST',
});

// ✅ CORRECT - Environment-aware
const BASE_URL = process.env.TEST_BASE_URL || 'http://localhost:3001';
const request = new NextRequest(`${BASE_URL}/api/sessions`, {
  method: 'POST',
});
```

### 6.6 Not Mocking External Dependencies

**Problem:** Tests make real API calls, causing slow/flaky tests.

```typescript
// ❌ WRONG - Calls real Anthropic API
describe('Melissa chat', () => {
  it('processes message', async () => {
    // This makes a real API call!
    const response = await POST(request);
    // Slow, costs money, rate-limited
  });
});

// ✅ CORRECT - Mock external services
jest.mock('@/lib/melissa/agent', () => ({
  MelissaAgent: {
    create: jest.fn(async () => ({
      processMessage: jest.fn(async () => ({
        message: 'Mocked response',
      })),
    })),
  },
}));
```

### 6.7 Ignoring Database Transaction Isolation

**Problem:** Integration tests pollute each other's data.

```typescript
// ❌ WRONG - No cleanup
describe('Integration tests', () => {
  it('creates session 1', async () => {
    await prisma.session.create({ data: { id: 'test-1' } });
    // Never cleaned up!
  });

  it('creates session 2', async () => {
    const sessions = await prisma.session.findMany();
    expect(sessions).toHaveLength(1); // FAILS - has 2 sessions!
  });
});

// ✅ CORRECT - Clean up after tests
describe('Integration tests', () => {
  afterEach(async () => {
    await prisma.session.deleteMany({
      where: { id: { startsWith: 'test-' } },
    });
  });

  it('creates session 1', async () => {
    await prisma.session.create({ data: { id: 'test-1' } });
  });

  it('creates session 2', async () => {
    const sessions = await prisma.session.findMany({
      where: { id: { startsWith: 'test-' } },
    });
    expect(sessions).toHaveLength(1); // PASSES
  });
});
```

### 6.8 Not Testing Idempotency

**Problem:** API endpoints that should be idempotent aren't tested for it.

```typescript
// ❌ WRONG - Doesn't test idempotency
it('creates session', async () => {
  const response = await POST(request);
  expect(response.status).toBe(200);
  // What if client retries due to network error?
});

// ✅ CORRECT - Tests idempotency
it('respects idempotency key', async () => {
  const idempotencyKey = 'test-key-123';

  // First request
  const request1 = createMockRequest('http://localhost:3001/api/sessions', {
    method: 'POST',
    headers: { 'X-Idempotency-Key': idempotencyKey },
    body: {},
  });

  const response1 = await POST(request1);
  const data1 = await response1.json();

  expect(response1.status).toBe(200);
  expect(prisma.session.create).toHaveBeenCalledTimes(1);

  // Second request with same key
  const request2 = createMockRequest('http://localhost:3001/api/sessions', {
    method: 'POST',
    headers: { 'X-Idempotency-Key': idempotencyKey },
    body: {},
  });

  const response2 = await POST(request2);
  const data2 = await response2.json();

  // Should return cached result, not create new session
  expect(response2.status).toBe(200);
  expect(data2.sessionId).toBe(data1.sessionId);
  expect(prisma.session.create).toHaveBeenCalledTimes(1); // Still only 1 call
});
```

---

## 7. AI Pair Programming Notes

<!-- Query: "How to explain API tests to AI" -->
<!-- Query: "Context for Claude when writing API tests" -->

### When to Share This Guide

Share this guide when:
- ✅ Writing new API endpoint tests
- ✅ Debugging failing API tests
- ✅ Reviewing API test coverage
- ✅ Implementing authentication or validation
- ✅ Refactoring route handlers

### Key Context to Provide

When asking AI to write/fix API tests, provide:

1. **Route handler file path**: `app/api/sessions/route.ts`
2. **HTTP method**: POST, GET, PATCH, DELETE
3. **Authentication requirements**: Cookie-based, JWT, none
4. **Validation schema**: Zod schema if applicable
5. **Database operations**: Which Prisma models are involved
6. **Expected response format**: Status codes, JSON structure

**Example AI prompt:**

```
Write Jest tests for the PATCH /api/sessions/[id] route handler.

Context:
- File: app/api/sessions/[id]/route.ts
- Method: PATCH
- Auth: Cookie-based editKey (session.editKey.{id})
- Validation: Zod schema with employeeCount, customerName, etc.
- Database: Prisma session.update()
- Success: 200 with { success: true, updated: [...fields] }
- Errors: 400 (validation), 403 (unauthorized), 404 (not found), 500 (server error)

Use Next.js 16 async params pattern.
Mock Prisma, logger, and session-auth utilities.
Follow structure from docs/kb/testing/jest/06-API-TESTING.md
```

### Related Guides to Combine

Combine this guide with:
- **03-MOCKING-SPIES.md**: For detailed mocking strategies
- **04-ASYNC-TESTING.md**: For async/await patterns
- **07-DATABASE-TESTING.md**: For integration test strategies
- **FRAMEWORK-INTEGRATION-PATTERNS.md**: For Next.js-specific patterns

### Testing Checklist for New API Endpoints

When adding a new API endpoint, ensure tests cover:

- [ ] **Happy path**: Valid input → Success response
- [ ] **Validation errors**: Invalid input → 400 with error details
- [ ] **Authentication**: Missing/invalid auth → 403
- [ ] **Not found**: Non-existent resource → 404
- [ ] **Database errors**: Simulated DB failure → 500
- [ ] **Edge cases**: Empty arrays, null values, boundary conditions
- [ ] **Idempotency**: Duplicate requests handled correctly
- [ ] **Rate limiting**: Too many requests → 429 (if applicable)
- [ ] **Cookie/header handling**: Cookies set/read correctly
- [ ] **Query parameter parsing**: Search params handled correctly

### Code Review Focus Points

When reviewing API test PRs:

1. **Test coverage**: All error paths covered?
2. **Mock isolation**: Mocks cleared between tests?
3. **Next.js 16 compliance**: Params awaited correctly?
4. **Behavioral testing**: Tests behavior, not implementation?
5. **Fixture usage**: Test data uses fixtures for consistency?
6. **Cleanup**: Integration tests clean up after themselves?
7. **Assertions**: Both response AND side effects verified?

---

## Last Updated

2025-11-14

---

## Changelog

- **2025-11-14**: Initial comprehensive version with Next.js 16 async params pattern, Bloom examples, and complete test suites
