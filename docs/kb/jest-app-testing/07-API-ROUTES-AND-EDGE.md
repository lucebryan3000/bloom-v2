---
id: jest-app-testing-07-api-routes-and-edge
topic: jest-app-testing
file_role: detailed
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [jest-app-testing-basics]
related_topics: ['testing', 'javascript', 'unit-tests']
embedding_keywords: [jest-app-testing, api]
last_reviewed: 2025-11-13
---

# 07 · API Routes & Edge Functions

## Route Handler Anatomy
```ts
import { NextResponse } from 'next/server'
import { recapService } from '@/lib/services/RecapService'

export async function POST(request: NextRequest) {
 const payload = await request.json
 const recap = await recapService.generate(payload)
 return NextResponse.json(recap)
}
```

## Testing Strategy
1. Build `NextRequest` objects manually.
2. Mock downstream services (LLM, Prisma, Slack).
3. Assert on status code, JSON body, and headers.
4. Use Node environment.

```ts
/** @jest-environment node */
import { POST } from '@/app/api/recap/route'

describe('POST /api/recap', => {
 it('returns recap payload', async => {
 const request = buildRequest({ summary: 'Hi' })
 const response = await POST(request)
 expect(response.status).toBe(200)
 expect(await response.json).toMatchObject({ summary: expect.any(String) })
 })
})
```

## Edge Runtime Considerations
- Avoid Node APIs (fs, net) inside Edge handlers.
- During tests, mimic Edge by setting `process.env.NEXT_RUNTIME = 'edge'`.
- Provide fetch mocks for external APIs since Edge typically relies on fetch.

## Streaming Responses
- For streamed responses, test via `response.body?.getReader`.
- Collect chunks and assert on aggregated string.

## Input Validation
- Use Zod schemas inside route handlers.
- Tests should assert 400 status codes with error details when validation fails.

## Auth & Headers
- Mock `headers` to provide `Authorization` tokens.
- For cookies, use `cookies` mock similar to server actions.

## Idempotency
- When endpoints support idempotency keys, ensure tests cover duplicate submissions.

## Telemetry
- Spy on telemetry modules to confirm metrics fired for success/error cases.

## Common Failure Modes
| Symptom | Debug |
|---------|-------|
| 500 errors due to JSON parse | Validate `request.headers.get('content-type')` before parsing. |
| Timeout | Use fake timers or `jest.retryTimes` for flaky network mocks. |
| Response body locked | Clone request before reading when passing downstream. |
