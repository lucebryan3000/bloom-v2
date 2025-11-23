---
id: jest-app-testing-01-fundamentals
topic: jest-app-testing
file_role: detailed
profile: full
difficulty_level: beginner
kb_version: 3.1
prerequisites: [jest-app-testing-basics]
related_topics: ['testing', 'javascript', 'unit-tests']
embedding_keywords: [jest-app-testing]
last_reviewed: 2025-11-13
---

# 01 · Fundamentals

## Why Jest for this project
- Mature ecosystem with TypeScript typings and App Router compatibility.
- Fast feedback with intelligent caching + watch mode.
- Integrates with Testing Library, msw, Prisma mocks.

## Testing Layers
```
 E2E (Playwright) ↗ Contract coverage
Integration (Jest Node env) ↔ Server actions, APIs, pipelines
 Unit (Jest JSDOM) ↘ Components, hooks, utils
```
- Target ratio = 70% unit, 20% integration, 10% system.
- Document exceptions when integration specs must cover unique behavior.

## Naming Patterns
- `describe('<Module>')` + `it('does something meaningful')`
- Append regression context: `it('rejects invalid persona (GH-1842)')`
- File names mirror features: `runs-with-llm.test.ts` not `run.test.ts`.

## Arrange-Act-Assert Template
```ts
it('stores telemetry metadata', async => {
 // Arrange
 const payload = buildPayload

 // Act
 const result = await handler(payload)

 // Assert
 expect(result.context.telemetry).toMatchObject({ status: 'ok' })
})
```

## Given-When-Then Variation
```ts
it('returns HTTP 400 when schema fails', async => {
 // Given
 const request = buildRequest({ companyName: '' })

 // When
 const response = await POST(request)

 // Then
 expect(response.status).toBe(400)
})
```

## ✅ vs ❌ Examples
- ✅ `expect(screen.getByRole('button')).toHaveTextContent('Start')`
- ❌ `expect(wrapper.state('label')).toBe('Start')` // No enzyme-style state peeking.

## Mocking Philosophy
- Prefer module-level mocks via `jest.mock` to keep imports deterministic.
- Reset with `jest.resetModules` when testing module side effects.
- Use `ts-jest` style transforms only when Babel plugins needed (rare).

## Data Builders
- Add `tests/fixtures/<domain>.ts` for builder functions.
- Example builder signature: `buildRun(overrides?: Partial<Run>)`.
- Keep defaults realistic; referencing seeds from Prisma helps catch issues.

## Determinism Checklist
1. Disable timers or use fake timers explicitly.
2. Provide timezone-stable strings (ISO with `Z`).
3. Avoid randomness; if needed, seed and assert on output shape, not exact value.
4. Clean global state (fetch, console, localStorage) after each spec.

## Documentation Expectations
- Link to files inside `app/`, `lib/`, `tests/` when referencing behavior.
- Include docstrings or comments for non-obvious mocks.

## When Not to Use Jest
- Browser-only flows requiring real layout -> Playwright.
- Performance budgets -> custom bench harness.
- Visual regressions -> Chromatic or Storybook test runners.
