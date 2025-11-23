---
id: jest-app-testing-framework-specific-patterns
topic: jest-app-testing
file_role: patterns
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: []
related_topics: ['testing', 'javascript', 'unit-tests']
embedding_keywords: [jest-app-testing, patterns, examples, integration]
last_reviewed: 2025-11-13
---

# Framework-Specific Jest Patterns

This file captures the concrete patterns this project uses today. Each section references production files so you can mirror or extend the approach.

## 1. Component Patterns (`__tests__/components`)
### Hero CTA (file: `__tests__/components/home/Hero.test.tsx`)
- Mocks `global.fetch` at top of file to avoid leaking between specs.
- Uses `beforeEach( => jest.clearAllMocks)` to reset fetch.
- Exercises optimistic loading states before verifying the final CTA copy.
- ✅ Asserted behavior: CTA text, fetch call payload, skeleton states.
- ❌ Avoid coupling to internal hook state (e.g., `useHeroContent`).

### Patterns to reuse
1. Prefer `screen.findBy...` for asynchronous DOM.
2. Inline fixtures inside `describe` blocks; avoid `__mocks__` for one-off payloads.
3. Wrap `userEvent` interactions inside `await act(async =>...)` when timers involved.

## 2. Analytics Monitoring (`__tests__/monitoring/analytics.test.ts`)
- Uses `jest.spyOn(analytics, 'sendEvent')` to verify payload envelopes.
- Example checks around retries and failure logging.
- Shows how to coerce TypeScript with `as any` for private functions.

## 3. AI Services (`tests/services/LLMService.test.ts`)
- Declares `@jest-environment node` to avoid JSDOM overhead.
- Mocks `ai.generateText` before importing service modules (prevents module cache issues).
- Validates JSON parsing, fallback flows, telemetry instrumentation.
- Uses `mockPlaybook` + `mockContext` fixtures to keep tests deterministic.
- ✅ Pattern: convert markdown JSON blocks to plain JSON before assertions.
- ❌ Anti-pattern: expecting precise strings from the LLM; focus on semantic contract.

## 4. Integration: Runs with LLM (`tests/integration/runs-with-llm.test.ts`)
- Heavy Prisma mocking to simulate multi-table workflows.
- Stages sequential assertions: create run, add steps, persist outputs.
- Example of verifying queue side effects without touching BullMQ.

## 5. Integration: Recap API (`tests/integration/recap-api.test.ts`)
- Exercises `app/api/recap/route.ts` by mocking fetch + services.
- Shows how to assert against `Response` objects (status, JSON body).
- Uses `global.fetch` to mimic third-party API responses.

## 6. Jest Config Conventions
- `jest.config.cjs` excludes `tests/e2e`, `playwright` so layers stay separated.
- Coverage config targets app/lib/components directories.
- Add `moduleNameMapper` entries when new path aliases created (e.g., `^~shared/(.*)$`).

## 7. Setup File Rules (`jest.setup.js`)
- Router + Image mocks defined once, reused automatically.
- Shared console spies stop noisy logs from flaking tests.
- Add new globals here (TextEncoder, ResizeObserver) rather than inside single tests.

## 8. Fixture Management
- Keep fixtures next to tests when only referenced once.
- For shared fixtures, create `tests/fixtures/<domain>.ts` exporting builders.
- Clean up temp directories under `tests/.tmp` and gitignore the folder.

## 9. Mutation Harness (prompt builders)
- When snapshotting prompts, store files under `tests/prompts/__snapshots__` to keep them close to the harness.
- Use `expect(prompt).toMatchFileSnapshot(...)` to reduce inline noise.

## 10. Coverage Budgets
- Pull request pipeline fails if coverage dips below 80/70/70/80.
- Use `npx jest --coverage --findRelatedTests <file>` before pushing if touching large modules.

## 11. Flake Management
- If a spec flakes twice within 30 days, collect logs + reproduction and file under `PLAYWRIGHT-TEST-METRICS.md` style doc.
- Tag tests with `describe.skip` only when referencing a GitHub issue.

## 12. Suggested Additions
- Mirror msw handlers inside `tests/msw/handlers.ts` to centralize network mocks.
- Introduce `jest-runner-groups` to split integration suite once it exceeds 3 minutes.

## 13. Template Snippet
```ts
import { buildGoalPayload } from 'tests/fixtures/goals'

describe('GoalPipeline', => {
 const basePayload = buildGoalPayload

 it('persists run metadata', async => {
 jest.spyOn(logger, 'info').mockImplementation( => {})
 await pipeline(basePayload)
 expect(prisma.run.create).toHaveBeenCalledWith(expect.objectContaining({
 data: expect.objectContaining({ context: expect.any(Object) }),
 }))
 })
})
```

## 14. Cross-Doc References
- Pair this file with `docs/kb/openai-codex/10-TESTING-AND-OBSERVABILITY.md` for AI-specific heuristics.
- Link to `docs/kb/performance/README.md` when tests soak-run on low resources.
