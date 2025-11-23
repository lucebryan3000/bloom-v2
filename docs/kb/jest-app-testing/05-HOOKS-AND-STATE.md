---
id: jest-app-testing-05-hooks-and-state
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

# 05 · Hooks & State Testing

## When to Use `renderHook`
- Hook has no UI; returns data/functions consumed by many components.
- Example: `useRunProgress` could be tested via `renderHook` to confirm derived state.

```ts
import { renderHook, act } from '@testing-library/react'
import { useGoalPlanner } from '@/hooks/useGoalPlanner'

describe('useGoalPlanner', => {
 it('increments steps correctly', => {
 const { result } = renderHook( => useGoalPlanner)
 act( => result.current.nextStep)
 expect(result.current.currentStep).toBe(1)
 })
})
```

## Zustand / Store Patterns
- Re-export store creators from `stores/` and import directly.
- Reset store state in `beforeEach` by calling the initializer.

```ts
import { useTaskStore } from '@/stores/task-store'

afterEach( => {
 useTaskStore.setState(useTaskStore.getState.reset)
})
```

## Timer-Based Hooks
- `jest.useFakeTimers` before render.
- Advance timers with `jest.advanceTimersByTime(ms)`.
- Always `jest.useRealTimers` in `afterEach` to avoid leaking to other specs.

## Async Hooks
- Use `await waitFor( => expect(result.current.isLoaded).toBe(true))`.
- Combine with `renderHook` or test via component to assert DOM.

## React Server Components
- Prefer integration tests running against App Router actions when hooks rely on server modules.

## Reducer Testing
```ts
import { reducer, initialState } from '@/stores/run-reducer'

test('sets error state', => {
 const next = reducer(initialState, { type: 'error', payload: 'timeout' })
 expect(next.error).toBe('timeout')
})
```

## When Hooks Should Be Tested via Components
- Hook manipulates DOM
- Hook depends on context providers
- Hook interacts with router (useRouter) or Next.js features

## Common Pitfalls
| Pitfall | Fix |
|---------|-----|
| Accessing stale closures | Use `act` wrappers when state updates happen asynchronously. |
| Non-deterministic randomness | Inject PRNG or seed through hook parameters. |
| Failing to reset store | Provide `reset` helpers exported from store modules. |

## Debug Tips
- `console.log(result.current)` temporarily; remember to remove logs.
- Use `renderHook`'s `rerender` to simulate prop changes.
