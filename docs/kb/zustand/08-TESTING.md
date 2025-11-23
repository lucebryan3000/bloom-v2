---
id: zustand-08-testing
topic: zustand
file_role: practical
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [zustand-fundamentals, testing-basics]
related_topics: [jest, react-testing-library, testing]
embedding_keywords: [zustand, testing, jest, react-testing-library, unit-tests, integration-tests]
last_reviewed: 2025-11-16
---

# Zustand - Testing

## Purpose

Learn how to test Zustand stores, actions, and components that use Zustand with Jest and React Testing Library.

## Table of Contents

1. [Testing Store Actions](#testing-store-actions)
2. [Testing Components](#testing-components)
3. [Mocking Stores](#mocking-stores)
4. [Testing Async Actions](#testing-async-actions)
5. [Testing with Middleware](#testing-with-middleware)
6. [Best Practices](#best-practices)

---

## Testing Store Actions

### Basic Store Testing

```typescript
import { create } from 'zustand'

interface CounterState {
  count: number
  increment: () => void
  decrement: () => void
  reset: () => void
}

const useCounterStore = create<CounterState>((set) => ({
  count: 0,
  increment: () => set((state) => ({ count: state.count + 1 })),
  decrement: () => set((state) => ({ count: state.count - 1 })),
  reset: () => set({ count: 0 }),
}))

// Test
describe('CounterStore', () => {
  beforeEach(() => {
    useCounterStore.setState({ count: 0 })
  })

  it('increments count', () => {
    expect(useCounterStore.getState().count).toBe(0)

    useCounterStore.getState().increment()
    expect(useCounterStore.getState().count).toBe(1)

    useCounterStore.getState().increment()
    expect(useCounterStore.getState().count).toBe(2)
  })

  it('decrements count', () => {
    useCounterStore.setState({ count: 5 })

    useCounterStore.getState().decrement()
    expect(useCounterStore.getState().count).toBe(4)
  })

  it('resets count', () => {
    useCounterStore.setState({ count: 10 })

    useCounterStore.getState().reset()
    expect(useCounterStore.getState().count).toBe(0)
  })
})
```

### Testing with Initial State

```typescript
it('initializes with correct state', () => {
  const initialState = useCounterStore.getState()

  expect(initialState).toEqual({
    count: 0,
    increment: expect.any(Function),
    decrement: expect.any(Function),
    reset: expect.any(Function),
  })
})
```

### Resetting Store Between Tests

```typescript
beforeEach(() => {
  // Reset to initial state
  useCounterStore.setState({ count: 0 })

  // Or completely reset
  useCounterStore.setState(
    {
      count: 0,
      increment: useCounterStore.getState().increment,
      decrement: useCounterStore.getState().decrement,
      reset: useCounterStore.getState().reset,
    },
    true // replace
  )
})
```

---

## Testing Components

### Basic Component Test

```typescript
import { render, screen, fireEvent } from '@testing-library/react'

function Counter() {
  const { count, increment } = useCounterStore()

  return (
    <div>
      <span>Count: {count}</span>
      <button onClick={increment}>Increment</button>
    </div>
  )
}

describe('Counter Component', () => {
  beforeEach(() => {
    useCounterStore.setState({ count: 0 })
  })

  it('renders current count', () => {
    render(<Counter />)
    expect(screen.getByText('Count: 0')).toBeInTheDocument()
  })

  it('increments on button click', () => {
    render(<Counter />)

    const button = screen.getByText('Increment')
    fireEvent.click(button)

    expect(screen.getByText('Count: 1')).toBeInTheDocument()
  })
})
```

### Testing with renderHook

```typescript
import { renderHook, act } from '@testing-library/react'

describe('useCounterStore hook', () => {
  beforeEach(() => {
    useCounterStore.setState({ count: 0 })
  })

  it('increments count', () => {
    const { result } = renderHook(() => useCounterStore())

    act(() => {
      result.current.increment()
    })

    expect(result.current.count).toBe(1)
  })

  it('handles multiple increments', () => {
    const { result } = renderHook(() => useCounterStore())

    act(() => {
      result.current.increment()
      result.current.increment()
      result.current.increment()
    })

    expect(result.current.count).toBe(3)
  })
})
```

### Testing Selectors

```typescript
const selectCount = (state: CounterState) => state.count
const selectActions = (state: CounterState) => ({
  increment: state.increment,
  decrement: state.decrement,
})

it('selects count correctly', () => {
  useCounterStore.setState({ count: 5 })

  const { result } = renderHook(() => useCounterStore(selectCount))
  expect(result.current).toBe(5)
})

it('selects actions correctly', () => {
  const { result } = renderHook(() => useCounterStore(selectActions))

  expect(result.current).toEqual({
    increment: expect.any(Function),
    decrement: expect.any(Function),
  })
})
```

---

## Mocking Stores

### Mock Store for Testing

```typescript
import { create as actualCreate } from 'zustand'

const storeResetFns = new Set<() => void>()

const create = (<T>(stateCreator: StateCreator<T>) => {
  const store = actualCreate(stateCreator)
  const initialState = store.getState()
  storeResetFns.add(() => {
    store.setState(initialState, true)
  })
  return store
}) as typeof actualCreate

// Reset all stores after each test
afterEach(() => {
  storeResetFns.forEach((resetFn) => {
    resetFn()
  })
})

export { create }
```

### Partial Mock

```typescript
const mockIncrement = jest.fn()

jest.mock('./useCounterStore', () => ({
  useCounterStore: jest.fn(() => ({
    count: 0,
    increment: mockIncrement,
    decrement: jest.fn(),
    reset: jest.fn(),
  })),
}))

it('calls increment when button clicked', () => {
  render(<Counter />)

  fireEvent.click(screen.getByText('Increment'))

  expect(mockIncrement).toHaveBeenCalledTimes(1)
})
```

### Test-Specific Store

```typescript
function createTestStore() {
  return create<CounterState>((set) => ({
    count: 0,
    increment: () => set((state) => ({ count: state.count + 1 })),
    decrement: () => set((state) => ({ count: state.count - 1 })),
    reset: () => set({ count: 0 }),
  }))
}

it('works with isolated store', () => {
  const useTestStore = createTestStore()

  useTestStore.getState().increment()
  expect(useTestStore.getState().count).toBe(1)
})
```

---

## Testing Async Actions

### Testing Fetch Actions

```typescript
interface DataState {
  data: any | null
  loading: boolean
  error: string | null
  fetchData: (url: string) => Promise<void>
}

const useDataStore = create<DataState>((set) => ({
  data: null,
  loading: false,
  error: null,

  fetchData: async (url) => {
    set({ loading: true, error: null })
    try {
      const response = await fetch(url)
      const data = await response.json()
      set({ data, loading: false })
    } catch (error) {
      set({
        error: error instanceof Error ? error.message : 'Unknown error',
        loading: false
      })
    }
  },
}))

// Test
describe('DataStore', () => {
  beforeEach(() => {
    useDataStore.setState({ data: null, loading: false, error: null })
    global.fetch = jest.fn()
  })

  afterEach(() => {
    jest.restoreAllMocks()
  })

  it('fetches data successfully', async () => {
    const mockData = { id: 1, name: 'Test' }

    ;(global.fetch as jest.Mock).mockResolvedValueOnce({
      ok: true,
      json: async () => mockData,
    })

    await useDataStore.getState().fetchData('/api/data')

    expect(useDataStore.getState()).toEqual({
      data: mockData,
      loading: false,
      error: null,
      fetchData: expect.any(Function),
    })
  })

  it('handles fetch error', async () => {
    ;(global.fetch as jest.Mock).mockRejectedValueOnce(
      new Error('Network error')
    )

    await useDataStore.getState().fetchData('/api/data')

    expect(useDataStore.getState()).toEqual({
      data: null,
      loading: false,
      error: 'Network error',
      fetchData: expect.any(Function),
    })
  })

  it('sets loading state', async () => {
    ;(global.fetch as jest.Mock).mockImplementationOnce(
      () => new Promise((resolve) => setTimeout(resolve, 100))
    )

    const fetchPromise = useDataStore.getState().fetchData('/api/data')

    expect(useDataStore.getState().loading).toBe(true)

    await fetchPromise

    expect(useDataStore.getState().loading).toBe(false)
  })
})
```

### Testing with MSW (Mock Service Worker)

```typescript
import { rest } from 'msw'
import { setupServer } from 'msw/node'

const server = setupServer(
  rest.get('/api/data', (req, res, ctx) => {
    return res(ctx.json({ id: 1, name: 'Test' }))
  })
)

beforeAll(() => server.listen())
afterEach(() => server.resetHandlers())
afterAll(() => server.close())

it('fetches real data with MSW', async () => {
  await useDataStore.getState().fetchData('/api/data')

  expect(useDataStore.getState().data).toEqual({
    id: 1,
    name: 'Test',
  })
})

it('handles server error', async () => {
  server.use(
    rest.get('/api/data', (req, res, ctx) => {
      return res(ctx.status(500))
    })
  )

  await useDataStore.getState().fetchData('/api/data')

  expect(useDataStore.getState().error).toBeTruthy()
})
```

---

## Testing with Middleware

### Testing Persist Middleware

```typescript
import { persist } from 'zustand/middleware'

const usePersistedStore = create(
  persist(
    (set) => ({
      count: 0,
      increment: () => set((state) => ({ count: state.count + 1 })),
    }),
    {
      name: 'test-storage',
    }
  )
)

describe('PersistedStore', () => {
  beforeEach(() => {
    localStorage.clear()
  })

  it('persists to localStorage', () => {
    usePersistedStore.getState().increment()

    const stored = localStorage.getItem('test-storage')
    expect(stored).toBeTruthy()

    const parsed = JSON.parse(stored!)
    expect(parsed.state.count).toBe(1)
  })

  it('rehydrates from localStorage', () => {
    localStorage.setItem(
      'test-storage',
      JSON.stringify({ state: { count: 5 }, version: 0 })
    )

    // Create new store instance
    const useNewStore = create(
      persist(
        (set) => ({
          count: 0,
          increment: () => set((state) => ({ count: state.count + 1 })),
        }),
        {
          name: 'test-storage',
        }
      )
    )

    expect(useNewStore.getState().count).toBe(5)
  })
})
```

### Testing Immer Middleware

```typescript
import { immer } from 'zustand/middleware/immer'

const useImmerStore = create(
  immer((set) => ({
    nested: { count: 0 },
    increment: () => set((state) => {
      state.nested.count++
    }),
  }))
)

it('updates nested state immutably', () => {
  const before = useImmerStore.getState().nested

  useImmerStore.getState().increment()

  const after = useImmerStore.getState().nested

  expect(before).not.toBe(after) // Different reference
  expect(after.count).toBe(1)
})
```

---

## Best Practices

### 1. Reset State Between Tests

```typescript
let initialState: CounterState

beforeEach(() => {
  initialState = useCounterStore.getState()
  useCounterStore.setState(initialState, true)
})
```

### 2. Test Actions in Isolation

```typescript
it('increment increases count by 1', () => {
  useCounterStore.setState({ count: 5 })

  useCounterStore.getState().increment()

  expect(useCounterStore.getState().count).toBe(6)
})
```

### 3. Use getState() for Direct Testing

```typescript
// ✅ Good - Direct state access
it('updates state correctly', () => {
  const { increment } = useCounterStore.getState()
  increment()
  expect(useCounterStore.getState().count).toBe(1)
})

// ❌ Less ideal - Testing through component
it('updates state', () => {
  const { result } = renderHook(() => useCounterStore())
  act(() => result.current.increment())
  expect(result.current.count).toBe(1)
})
```

### 4. Mock External Dependencies

```typescript
jest.mock('./api', () => ({
  fetchUser: jest.fn(() => Promise.resolve({ id: 1, name: 'Test' }))
}))

it('fetches user data', async () => {
  await useUserStore.getState().fetchUser()
  expect(useUserStore.getState().user).toEqual({ id: 1, name: 'Test' })
})
```

### 5. Test Error Cases

```typescript
it('handles errors gracefully', async () => {
  global.fetch = jest.fn(() => Promise.reject(new Error('Failed')))

  await useDataStore.getState().fetchData('/api/data')

  expect(useDataStore.getState().error).toBe('Failed')
  expect(useDataStore.getState().loading).toBe(false)
})
```

---

## Common Pitfalls

### Pitfall 1: Not Resetting State

```typescript
// ❌ Bad - State leaks between tests
it('test 1', () => {
  useStore.getState().increment()
  expect(useStore.getState().count).toBe(1)
})

it('test 2', () => {
  // count is still 1 from previous test!
  expect(useStore.getState().count).toBe(0) // FAILS
})

// ✅ Good - Reset between tests
beforeEach(() => {
  useStore.setState({ count: 0 })
})
```

### Pitfall 2: Not Using act() for State Updates

```typescript
// ❌ Bad - Missing act()
const { result } = renderHook(() => useStore())
result.current.increment() // Warning: state update not wrapped in act()

// ✅ Good - Wrapped in act()
const { result } = renderHook(() => useStore())
act(() => {
  result.current.increment()
})
```

### Pitfall 3: Testing Implementation Details

```typescript
// ❌ Bad - Testing internal state structure
it('has correct internal structure', () => {
  expect(useStore.getState()).toHaveProperty('_count')
})

// ✅ Good - Testing behavior
it('increments count', () => {
  useStore.getState().increment()
  expect(useStore.getState().count).toBe(1)
})
```

---

## Test Patterns

### Pattern 1: Factory Function for Test Stores

```typescript
function createTestCounterStore(initialCount = 0) {
  return create<CounterState>((set) => ({
    count: initialCount,
    increment: () => set((state) => ({ count: state.count + 1 })),
    decrement: () => set((state) => ({ count: state.count - 1 })),
    reset: () => set({ count: 0 }),
  }))
}

it('works with custom initial state', () => {
  const useStore = createTestCounterStore(10)

  useStore.getState().increment()
  expect(useStore.getState().count).toBe(11)
})
```

### Pattern 2: Snapshot Testing

```typescript
it('matches state snapshot', () => {
  useCounterStore.getState().increment()
  useCounterStore.getState().increment()

  expect(useCounterStore.getState()).toMatchSnapshot()
})
```

### Pattern 3: Testing State Transitions

```typescript
it('transitions through states correctly', async () => {
  const states: string[] = []

  useDataStore.subscribe((state) => {
    states.push(state.loading ? 'loading' : 'idle')
  })

  await useDataStore.getState().fetchData('/api/data')

  expect(states).toEqual(['loading', 'idle'])
})
```

---

## AI Pair Programming Notes

**When to load this file:**
- Writing tests for Zustand stores
- Testing components that use Zustand
- Debugging test failures
- Setting up test infrastructure

**Typical questions:**
- "How do I test Zustand stores?"
- "How do I reset state between tests?"
- "How do I test async actions?"
- "How do I mock a Zustand store?"

**Next steps:**
- [09-ADVANCED-PATTERNS.md](./09-ADVANCED-PATTERNS.md) - Complex patterns to test
- [05-ASYNC-ACTIONS.md](./05-ASYNC-ACTIONS.md) - Review async actions
- [06-MIDDLEWARE.md](./06-MIDDLEWARE.md) - Testing with middleware
