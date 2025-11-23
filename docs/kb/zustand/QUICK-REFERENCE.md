---
id: zustand-quick-reference
topic: zustand
file_role: quickref
profile: full
difficulty_level: all-levels
kb_version: 3.1
last_reviewed: 2025-11-16
---

# Zustand - Quick Reference

One-page cheat sheet for Zustand syntax and common patterns.

## Installation

```bash
npm install zustand
# or
yarn add zustand
# or
pnpm add zustand
```

## Basic Store

```typescript
import { create } from 'zustand'

const useStore = create((set) => ({
  // State
  count: 0,
  user: null,

  // Actions
  increment: () => set((state) => ({ count: state.count + 1 })),
  setUser: (user) => set({ user }),
  reset: () => set({ count: 0, user: null }),
}))
```

## Using in Components

```typescript
// Select single value
const count = useStore((state) => state.count)

// Select action
const increment = useStore((state) => state.increment)

// Select multiple (with useShallow to prevent re-renders)
import { useShallow } from 'zustand/react/shallow'

const { count, increment } = useStore(
  useShallow((state) => ({ count: state.count, increment: state.increment }))
)
```

## State Updates

```typescript
// Object form (static value)
set({ count: 0 })

// Function form (depends on current state)
set((state) => ({ count: state.count + 1 }))

// Replace entire state (rare)
set({ count: 0 }, true)
```

## Array Operations

```typescript
const useStore = create((set) => ({
  items: [],

  // Add item
  addItem: (item) => set((state) => ({ items: [...state.items, item] })),

  // Remove item by id
  removeItem: (id) => set((state) => ({
    items: state.items.filter(item => item.id !== id)
  })),

  // Update item
  updateItem: (id, updates) => set((state) => ({
    items: state.items.map(item =>
      item.id === id ? { ...item, ...updates } : item
    )
  })),

  // Clear all
  clearItems: () => set({ items: [] }),
}))
```

## Nested Object Updates

```typescript
const useStore = create((set) => ({
  user: { name: 'Alice', settings: { theme: 'dark' } },

  // Update nested property
  updateTheme: (theme) => set((state) => ({
    user: {
      ...state.user,
      settings: {
        ...state.user.settings,
        theme
      }
    }
  })),
}))
```

## Async Actions

```typescript
const useStore = create((set) => ({
  data: null,
  isLoading: false,
  error: null,

  fetchData: async () => {
    set({ isLoading: true, error: null })

    try {
      const response = await fetch('/api/data')
      const data = await response.json()
      set({ data, isLoading: false })
    } catch (error) {
      set({ error: error.message, isLoading: false })
    }
  },
}))
```

## Middleware

### Persist (localStorage)

```typescript
import { persist, createJSONStorage } from 'zustand/middleware'

const useStore = create(
  persist(
    (set) => ({
      bears: 0,
      addBear: () => set((state) => ({ bears: state.bears + 1 })),
    }),
    {
      name: 'bear-storage', // localStorage key
      storage: createJSONStorage(() => localStorage), // or sessionStorage
    }
  )
)
```

### Immer (mutable updates)

```typescript
import { immer } from 'zustand/middleware/immer'

const useStore = create(
  immer((set) => ({
    user: { name: 'Alice', age: 30 },

    updateAge: (age) => set((state) => {
      state.user.age = age // Mutate directly with immer
    }),
  }))
)
```

### DevTools

```typescript
import { devtools } from 'zustand/middleware'

const useStore = create(
  devtools(
    (set) => ({ /* ... */ }),
    { name: 'MyStore' }
  )
)
```

### Combining Middleware

```typescript
import { create } from 'zustand'
import { devtools, persist } from 'zustand/middleware'

const useStore = create(
  devtools(
    persist(
      (set) => ({ /* ... */ }),
      { name: 'storage' }
    ),
    { name: 'DevTools' }
  )
)
```

## TypeScript

### Basic Typing

```typescript
interface BearState {
  bears: number
  addBear: () => void
  reset: () => void
}

const useBearStore = create<BearState>((set) => ({
  bears: 0,
  addBear: () => set((state) => ({ bears: state.bears + 1 })),
  reset: () => set({ bears: 0 }),
}))
```

### With Middleware (requires extra `()`)

```typescript
const useStore = create<BearState>()(
  persist(
    (set) => ({ /* ... */ }),
    { name: 'bear-storage' }
  )
)
```

## Selectors

### Atomic Selector

```typescript
// ✅ Good - Re-renders only when count changes
const count = useStore((state) => state.count)
```

### Multiple Selection with useShallow

```typescript
import { useShallow } from 'zustand/react/shallow'

// ✅ Good - Shallow comparison
const { nuts, honey } = useBearStore(
  useShallow((state) => ({ nuts: state.nuts, honey: state.honey }))
)
```

### Custom Equality

```typescript
import { isEqual } from 'lodash'

const user = useStore(
  (state) => state.user,
  isEqual // Deep equality
)
```

### Selector Factory

```typescript
const createSelectById = (id) => (state) =>
  state.items.find(item => item.id === id)

function Post({ postId }) {
  const post = useStore(createSelectById(postId))
  return <div>{post.title}</div>
}
```

## Accessing Store Outside React

```typescript
// Get current state
const state = useStore.getState()

// Update state
useStore.setState({ count: 5 })

// Subscribe to changes
const unsubscribe = useStore.subscribe((state) => {
  console.log('State changed:', state)
})

// Cleanup
unsubscribe()
```

## Vanilla Store (Non-React)

```typescript
import { createStore } from 'zustand/vanilla'

const store = createStore((set) => ({
  count: 0,
  increment: () => set((state) => ({ count: state.count + 1 })),
}))

// Use outside React
store.getState().increment()
console.log(store.getState().count) // 1

// Create React hook from vanilla store
import { useStore } from 'zustand'

function useCountStore() {
  return useStore(store)
}
```

## Store Slices

```typescript
import { StateCreator } from 'zustand'

interface UserSlice {
  user: User | null
  setUser: (user: User) => void
}

interface PostsSlice {
  posts: Post[]
  addPost: (post: Post) => void
}

const createUserSlice: StateCreator<
  UserSlice & PostsSlice,
  [],
  [],
  UserSlice
> = (set) => ({
  user: null,
  setUser: (user) => set({ user }),
})

const createPostsSlice: StateCreator<
  UserSlice & PostsSlice,
  [],
  [],
  PostsSlice
> = (set) => ({
  posts: [],
  addPost: (post) => set((state) => ({ posts: [...state.posts, post] })),
})

const useStore = create<UserSlice & PostsSlice>()((...a) => ({
  ...createUserSlice(...a),
  ...createPostsSlice(...a),
}))
```

## Testing

### Test Store Directly

```typescript
import { useStore } from './store'

describe('useStore', () => {
  beforeEach(() => {
    useStore.setState({ count: 0 }) // Reset state
  })

  it('increments count', () => {
    useStore.getState().increment()
    expect(useStore.getState().count).toBe(1)
  })
})
```

### Test Component

```typescript
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'

beforeEach(() => {
  useStore.setState({ count: 0 })
})

it('displays and increments count', async () => {
  render(<Counter />)

  expect(screen.getByText('Count: 0')).toBeInTheDocument()

  await userEvent.click(screen.getByRole('button', { name: /increment/i }))

  expect(screen.getByText('Count: 1')).toBeInTheDocument()
})
```

### Mock Store

```typescript
import { create } from 'zustand'

const createMockStore = (initialState = {}) => {
  return create(() => ({
    count: 0,
    increment: jest.fn(),
    ...initialState,
  }))
}

it('calls increment', async () => {
  const mockStore = createMockStore()

  render(<Counter useStore={mockStore} />)

  await userEvent.click(screen.getByRole('button'))

  expect(mockStore.getState().increment).toHaveBeenCalled()
})
```

## SSR / Next.js

### App Router

```typescript
'use client'

import { createContext, useContext, useRef } from 'react'
import { createStore } from 'zustand/vanilla'

const StoreContext = createContext(null)

export function StoreProvider({ children, initialState }) {
  const storeRef = useRef()

  if (!storeRef.current) {
    storeRef.current = createStore((set) => ({
      ...initialState,
      increment: () => set((state) => ({ count: state.count + 1 })),
    }))
  }

  return (
    <StoreContext.Provider value={storeRef.current}>
      {children}
    </StoreContext.Provider>
  )
}

export function useAppStore(selector) {
  const store = useContext(StoreContext)
  if (!store) throw new Error('Missing StoreProvider')
  return useStore(store, selector)
}
```

### Prevent Hydration Mismatch

```typescript
function Component() {
  const [hydrated, setHydrated] = useState(false)
  const theme = useStore((state) => state.theme)

  useEffect(() => setHydrated(true), [])

  if (!hydrated) return <div>Loading...</div>

  return <div>{theme}</div>
}
```

## Common Patterns

### Loading/Error State

```typescript
const useStore = create((set) => ({
  data: null,
  isLoading: false,
  error: null,

  fetchData: async () => {
    set({ isLoading: true, error: null })
    try {
      const data = await api.getData()
      set({ data, isLoading: false })
    } catch (error) {
      set({ error: error.message, isLoading: false })
    }
  },
}))
```

### Optimistic Updates

```typescript
const useStore = create((set, get) => ({
  posts: [],

  createPost: async (newPost) => {
    const tempId = Date.now()
    const optimisticPost = { id: tempId, ...newPost }

    // Add optimistically
    set((state) => ({ posts: [...state.posts, optimisticPost] }))

    try {
      const savedPost = await api.createPost(newPost)

      // Replace with real post
      set((state) => ({
        posts: state.posts.map(p =>
          p.id === tempId ? savedPost : p
        )
      }))
    } catch (error) {
      // Rollback on error
      set((state) => ({
        posts: state.posts.filter(p => p.id !== tempId)
      }))
    }
  },
}))
```

### Cross-Store Communication

```typescript
const useAuthStore = create((set) => ({ /* ... */ }))

const useCartStore = create((set, get) => ({
  items: [],

  checkout: async () => {
    const { token } = useAuthStore.getState() // Access other store

    if (!token) throw new Error('Not authenticated')

    await api.checkout(get().items, token)
    set({ items: [] })
  },
}))
```

## Performance Tips

```typescript
// ✅ DO: Select only what you need
const count = useStore((state) => state.count)

// ❌ DON'T: Select entire state
const state = useStore((state) => state)

// ✅ DO: Use useShallow for objects
const { x, y } = useStore(useShallow((state) => ({ x: state.x, y: state.y })))

// ❌ DON'T: Create new objects without useShallow
const { x, y } = useStore((state) => ({ x: state.x, y: state.y }))

// ✅ DO: Memoize expensive computations
const total = useMemo(
  () => items.reduce((sum, item) => sum + item.price, 0),
  [items]
)

// ✅ DO: Split large components
function UserSection() {
  const user = useStore((state) => state.user)
  return <User data={user} />
}
```

## Debugging

### Enable DevTools

```typescript
const useStore = create(
  devtools((set) => ({ /* ... */ }), { name: 'MyStore' })
)
```

### Log State Changes

```typescript
const logMiddleware = (config) => (set, get, api) =>
  config(
    (args) => {
      console.log('Before:', get())
      set(args)
      console.log('After:', get())
    },
    get,
    api
  )

const useStore = create(logMiddleware((set) => ({ /* ... */ })))
```

### Subscribe to Changes

```typescript
useEffect(() => {
  const unsubscribe = useStore.subscribe((state, prevState) => {
    console.log('State changed from', prevState, 'to', state)
  })

  return unsubscribe
}, [])
```

## Cheat Sheet Summary

| Task | Pattern |
|------|---------|
| **Create store** | `create((set) => ({ /* ... */ }))` |
| **Select state** | `useStore((state) => state.value)` |
| **Update state** | `set((state) => ({ count: state.count + 1 }))` |
| **Reset state** | `set({ count: 0 })` |
| **Async action** | `async () => { /* await api */ set({ data }) }` |
| **Persist** | `persist((set) => ({ /* ... */ }), { name: 'key' })` |
| **DevTools** | `devtools((set) => ({ /* ... */ }))` |
| **TypeScript** | `create<State>()((set) => ({ /* ... */ }))` |
| **Access outside React** | `useStore.getState()` / `useStore.setState()` |
| **Subscribe** | `useStore.subscribe((state) => { /* ... */ })` |

## Quick Links

- **[README.md](./README.md)** - Full overview and learning paths
- **[INDEX.md](./INDEX.md)** - Complete file index
- **[01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md)** - Core concepts
- **[Official Docs](https://zustand-demo.pmnd.rs/)** - Zustand documentation
- **[GitHub](https://github.com/pmndrs/zustand)** - Source code and examples

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1 | **Print this page for quick reference!**
