---
id: jest-app-testing-10-integration-and-e2e-hybrids
topic: jest-app-testing
file_role: detailed
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [jest-app-testing-basics]
related_topics: ['testing', 'javascript', 'unit-tests']
embedding_keywords: [jest-app-testing]
last_reviewed: 2025-11-13
---

# 10 · Integration & Hybrid Tests

## Purpose
- Cover multi-hop flows without spinning up browsers.
- Validate contracts between server actions, Prisma, AI services, and queues.

## Example: `tests/integration/runs-with-llm.test.ts`
- Mocks Prisma, AI SDK, and queueing layer.
- Walks through run creation, step persistence, and telemetry.

```ts
/** @jest-environment node */
import { orchestrateRun } from '@/lib/workflows/run-orchestrator'

describe('orchestrateRun', => {
 beforeEach( => jest.clearAllMocks)

 it('persists run, steps, and summary', async => {
 const payload = buildRunPayload
 const result = await orchestrateRun(payload)

 expect(prisma.run.create).toHaveBeenCalled
 expect(prisma.runStep.create).toHaveBeenCalledTimes(payload.steps.length)
 expect(result.status).toBe('success')
 })
})
```

## Example: `tests/integration/recap-api.test.ts`
- Hits API route handler directly.
- Exercises happy path + error handling.
- Ensures we do not call real network endpoints by mocking fetch.

## Building Hybrid Tests
1. Mock external services (msw, jest mocks).
2. Keep Prisma in-memory via mocks.
3. Execute workflow entry point.
4. Assert on persisted data + responses.
5. Verify telemetry/logging.

## Test Data Builders
- Provide `buildRunPayload`, `buildRecapPayload` in `tests/fixtures`.
- Keep builder defaults aligned with real schema (enum values, required fields).

## Handling Async Chains
- Use `await waitFor` when actions dispatch asynchronous events.
- Spy on queue modules to confirm job scheduling.

## Coverage Expectations
- Every new workflow requires at least one integration spec.
- Document coverage holes in PR description if temporarily missing.

## Failing Fast
- Use `expect.assertions(n)` when testing error branches to ensure assertions run.
- Wrap asynchronous failures in `await expect(promise).rejects.toThrow`.

## Snapshot vs Semantic Assertions
- Snapshot only multi-part JSON templates or prompts.
- Prefer semantic assertions for responses and DB writes.
