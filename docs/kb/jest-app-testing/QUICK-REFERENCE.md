---
id: jest-app-testing-quick-reference
topic: jest-app-testing
file_role: quickref
profile: full
difficulty_level: all-levels
kb_version: 3.1
prerequisites: []
related_topics: ['testing', 'javascript', 'unit-tests']
embedding_keywords: [jest-app-testing, quick-reference, cheat-sheet, syntax]
last_reviewed: 2025-11-13
---

# Jest App Testing Quick Reference

Fast snippets and checklists for the project's Jest harness.

## Commands
- `npm test` → run everything once with caching disabled
- `npm run test:watch` → watch mode with failed test focus
- `npm run test:coverage` → produce `coverage/lcov-report/index.html`
- `npm run test:unit` → only files in `__tests__`
- `npm run test:integration` → everything under `tests/`

## File Naming
| Layer | Directory | Pattern |
|-------|-----------|---------|
| Unit component | `__tests__/components` | `ComponentName.test.tsx` |
| Integration | `tests/integration` | `<domain>.<behavior>.test.ts` |
| Services | `tests/services` | `<ServiceName>.test.ts` |

## Test Template (AAA)
```ts
import { thing } from '@/lib/thing'

describe('thing', => {
 it('does X', async => {
 // Arrange
 const deps = buildDeps

 // Act
 const result = await thing(deps)

 // Assert
 expect(result).toMatchObject({ ok: true })
 })
})
```

## Component Helpers
```ts
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'

const setup = (props = {}) => render(<Button {...props}>Save</Button>)

test('fires onClick once', async => {
 const onClick = jest.fn
 setup({ onClick })
 await userEvent.click(screen.getByRole('button', { name: /save/i }))
 expect(onClick).toHaveBeenCalledTimes(1)
})
```

## MSW Handler Stub (integration tests)
```ts
import { setupServer } from 'msw/node'
import { http, HttpResponse } from 'msw'

const server = setupServer(
 http.post('https://slack.com/api/chat.postMessage', => HttpResponse.json({ ok: true }))
)

beforeAll( => server.listen)
afterEach( => server.resetHandlers)
afterAll( => server.close)
```

## Prisma Mock
```ts
jest.mock('@/lib/prisma', => ({
 __esModule: true,
 default: {
 run: {
 findUnique: jest.fn,
 create: jest.fn,
 },
 },
}))
```

## Server Action Harness
```ts
import { cookies } from 'next/headers'

describe('submitGoalAction', => {
 it('stores persona in cookie', async => {
 const store = new Map
;(cookies as jest.Mock).mockReturnValue({ get: store.get.bind(store), set: store.set.bind(store) })
 const response = await submitGoalAction(formData)
 expect(response.success).toBe(true)
 expect(store.get('persona')).toBeDefined
 })
})
```

## NextRequest Mock
```ts
import { NextRequest } from 'next/server'

const buildRequest = (payload: unknown) =>
 new NextRequest('http://localhost/api/recap', {
 method: 'POST',
 body: JSON.stringify(payload),
 headers: new Headers({ 'Content-Type': 'application/json' }),
 })
```

## Snapshot Testing Prompt Builders
```ts
import { buildPrompt } from '@/lib/codex/prompts/generate-tests'

test('prompt matches contract', => {
 const prompt = buildPrompt(fixture)
 expect(prompt).toMatchSnapshot
})
```

## Accessibility Assertions
```ts
import { axe } from 'jest-axe'

test('drawer meets a11y bar', async => {
 const { container } = render(<GoalDrawer open />)
 const results = await axe(container)
 expect(results).toHaveNoViolations
})
```

## Common Assertions
- `expect(screen.getByRole('button', { name: /submit/i })).toBeDisabled`
- `expect(fetch).toHaveBeenCalledWith(expect.stringContaining('/api/recap'), expect.any(Object))`
- `await expect(service.run).rejects.toThrow('Missing playbook')`
- `expect(logger.warn).toHaveBeenCalledWith(expect.objectContaining({ runId }))`

## Mock Reset Checklist
- `jest.clearAllMocks` inside `beforeEach`
- Reset msw handlers
- Recreate Prisma mock return values
- Delete temporary directories if test writes files

## Async Utilities
```ts
jest.useFakeTimers
await waitFor( => expect(queue.flush).toHaveBeenCalled)
await act(async => {
 jest.advanceTimersByTime(1000)
})
```

## Test Smells (❌)
- Asserting on implementation details (state hooks)
- Multiple `await userEvent.click` calls without `await waitFor`
- Tests that depend on order (shared mutable state)
- Real network calls or hitting actual Prisma DB

## Review Checklist
1. Fails when bug reintroduced?
2. No redundant snapshots?
3. Coverage impact positive?
4. Follows AAA / Given-When-Then naming?
5. Mocks reset between tests?

## this project Coverage Targets
- Lines ≥ 80%
- Functions ≥ 70%
- Branches ≥ 70%
- Statements ≥ 80%

## Failure Debug Tips
- Run `npx jest <pattern> --runInBand --detectOpenHandles`
- Add `--logHeapUsage` when diagnosing leaks
- Use `DEBUG=jest:* npm test` for verbose logs

## Useful Links
- `docs/kb/nextjs/09-TESTING.md` for App Router nuance
- `docs/kb/openai-codex/10-TESTING-AND-OBSERVABILITY.md` for AI harness ideas
