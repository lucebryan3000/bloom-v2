---
id: zustand-07-typescript
topic: zustand
file_role: practical
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [zustand-fundamentals, typescript-basics]
related_topics: [typescript, type-safety, generics]
embedding_keywords: [zustand, typescript, types, type-safety, generics, interfaces]
last_reviewed: 2025-11-16
---

# Zustand - TypeScript Patterns

## Purpose

Master TypeScript usage with Zustand for type-safe state management, including proper typing for stores, actions, selectors, and middleware.

## Table of Contents

1. [Basic Store Typing](#basic-store-typing)
2. [Typing Actions](#typing-actions)
3. [Typing with Middleware](#typing-with-middleware)
4. [Selector Types](#selector-types)
5. [Advanced Patterns](#advanced-patterns)
6. [Common Patterns](#common-patterns)

---

## Basic Store Typing

### Interface-Based Typing

```typescript
import { create } from 'zustand'

interface BearState {
  bears: number
  increaseBears: () => void
  removeAllBears: () => void
}

const useBearStore = create<BearState>((set) => ({
  bears: 0,
  increaseBears: () => set((state) => ({ bears: state.bears + 1 })),
  removeAllBears: () => set({ bears: 0 }),
}))
```

### Type vs Interface

```typescript
// ✅ Using Interface (recommended for state)
interface UserState {
  user: User | null
  setUser: (user: User) => void
  clearUser: () => void
}

// ✅ Using Type (works too)
type UserState = {
  user: User | null
  setUser: (user: User) => void
  clearUser: () => void
}

const useUserStore = create<UserState>((set) => ({
  user: null,
  setUser: (user) => set({ user }),
  clearUser: () => set({ user: null }),
}))
```

### Inferred Types

```typescript
// TypeScript infers the type
const useCountStore = create((set) => ({
  count: 0,
  increment: () => set((state) => ({ count: state.count + 1 })),
}))

// Get inferred type
type CountStore = ReturnType<typeof useCountStore.getState>
// { count: number, increment: () => void }
```

---

## Typing Actions

### Action with Parameters

```typescript
interface TodoState {
  todos: Todo[]
  addTodo: (text: string) => void
  removeTodo: (id: string) => void
  updateTodo: (id: string, updates: Partial<Todo>) => void
}

const useTodoStore = create<TodoState>((set) => ({
  todos: [],

  addTodo: (text) => set((state) => ({
    todos: [...state.todos, { id: crypto.randomUUID(), text, completed: false }]
  })),

  removeTodo: (id) => set((state) => ({
    todos: state.todos.filter(t => t.id !== id)
  })),

  updateTodo: (id, updates) => set((state) => ({
    todos: state.todos.map(t => t.id === id ? { ...t, ...updates } : t)
  })),
}))
```

### Async Actions

```typescript
interface DataState {
  data: Data | null
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
```

### Generic Actions

```typescript
interface ApiState<T> {
  data: T | null
  loading: boolean
  error: string | null
  fetch: (url: string) => Promise<void>
}

function createApiStore<T>() {
  return create<ApiState<T>>((set) => ({
    data: null,
    loading: false,
    error: null,

    fetch: async (url) => {
      set({ loading: true, error: null })
      try {
        const response = await fetch(url)
        const data: T = await response.json()
        set({ data, loading: false })
      } catch (error) {
        set({
          error: error instanceof Error ? error.message : 'Unknown error',
          loading: false
        })
      }
    },
  }))
}

// Usage
interface User {
  id: string
  name: string
}

const useUserStore = createApiStore<User>()
```

---

## Typing with Middleware

### Persist Middleware

```typescript
import { persist } from 'zustand/middleware'

interface AuthState {
  token: string | null
  user: User | null
  login: (token: string, user: User) => void
  logout: () => void
}

const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      token: null,
      user: null,
      login: (token, user) => set({ token, user }),
      logout: () => set({ token: null, user: null }),
    }),
    {
      name: 'auth-storage',
    }
  )
)
```

**Note:** The extra `()` is required for TypeScript type inference with middleware.

### Immer Middleware

```typescript
import { immer } from 'zustand/middleware/immer'

interface NestedState {
  nested: {
    deep: {
      count: number
    }
  }
  increment: () => void
}

const useNestedStore = create<NestedState>()(
  immer((set) => ({
    nested: {
      deep: {
        count: 0
      }
    },
    increment: () => set((state) => {
      state.nested.deep.count++ // Mutable update with Immer
    }),
  }))
)
```

### DevTools Middleware

```typescript
import { devtools } from 'zustand/middleware'

interface CounterState {
  count: number
  increment: () => void
  decrement: () => void
}

const useCounterStore = create<CounterState>()(
  devtools(
    (set) => ({
      count: 0,
      increment: () => set((state) => ({ count: state.count + 1 })),
      decrement: () => set((state) => ({ count: state.count - 1 })),
    }),
    { name: 'CounterStore' }
  )
)
```

### Multiple Middleware

```typescript
interface UserState {
  user: User | null
  settings: Settings
  updateUser: (user: User) => void
  updateSettings: (settings: Partial<Settings>) => void
}

const useUserStore = create<UserState>()(
  devtools(
    persist(
      immer((set) => ({
        user: null,
        settings: defaultSettings,
        updateUser: (user) => set({ user }),
        updateSettings: (updates) => set((state) => {
          Object.assign(state.settings, updates)
        }),
      })),
      { name: 'user-storage' }
    ),
    { name: 'UserStore' }
  )
)
```

---

## Selector Types

### Basic Selectors

```typescript
// Selector functions with proper types
const selectBears = (state: BearState) => state.bears
const selectIncrease = (state: BearState) => state.increaseBears

function Component() {
  const bears = useBearStore(selectBears)
  const increase = useBearStore(selectIncrease)

  return <button onClick={increase}>{bears} bears</button>
}
```

### Generic Selector Type

```typescript
type Selector<T, U> = (state: T) => U

// Usage
const selectUser: Selector<UserState, User | null> = (state) => state.user
const selectToken: Selector<UserState, string | null> = (state) => state.token
```

### Selector Factory

```typescript
function createSelector<State, Selected>(
  selector: (state: State) => Selected
): (state: State) => Selected {
  return selector
}

// Usage
const selectBears = createSelector((state: BearState) => state.bears)
const selectActions = createSelector((state: BearState) => ({
  increase: state.increaseBears,
  removeAll: state.removeAllBears,
}))
```

### Typed useShallow

```typescript
import { useShallow } from 'zustand/react/shallow'

interface State {
  nuts: number
  honey: number
  treats: string[]
}

function Component() {
  const { nuts, honey } = useBearStore(
    useShallow((state: State) => ({ nuts: state.nuts, honey: state.honey }))
  )

  return <div>{nuts} nuts, {honey} honey</div>
}
```

---

## Advanced Patterns

### Slices Pattern

```typescript
interface UserSlice {
  user: User | null
  setUser: (user: User) => void
}

interface PostsSlice {
  posts: Post[]
  addPost: (post: Post) => void
}

type StoreState = UserSlice & PostsSlice

const createUserSlice = (set: SetState<StoreState>): UserSlice => ({
  user: null,
  setUser: (user) => set({ user }),
})

const createPostsSlice = (set: SetState<StoreState>): PostsSlice => ({
  posts: [],
  addPost: (post) => set((state) => ({ posts: [...state.posts, post] })),
})

const useStore = create<StoreState>((set) => ({
  ...createUserSlice(set),
  ...createPostsSlice(set),
}))
```

### Computed Values

```typescript
interface CartState {
  items: CartItem[]
  addItem: (item: CartItem) => void
  removeItem: (id: string) => void
  // Computed properties
  get total(): number
  get itemCount(): number
}

const useCartStore = create<CartState>((set, get) => ({
  items: [],

  addItem: (item) => set((state) => ({ items: [...state.items, item] })),

  removeItem: (id) => set((state) => ({
    items: state.items.filter(i => i.id !== id)
  })),

  get total() {
    return get().items.reduce((sum, item) => sum + item.price, 0)
  },

  get itemCount() {
    return get().items.length
  },
}))
```

### State with Discriminated Unions

```typescript
type AsyncState<T> =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'success'; data: T }
  | { status: 'error'; error: string }

interface DataState {
  asyncState: AsyncState<User>
  fetchUser: (id: string) => Promise<void>
}

const useDataStore = create<DataState>((set) => ({
  asyncState: { status: 'idle' },

  fetchUser: async (id) => {
    set({ asyncState: { status: 'loading' } })

    try {
      const response = await fetch(`/api/users/${id}`)
      const data = await response.json()
      set({ asyncState: { status: 'success', data } })
    } catch (error) {
      set({
        asyncState: {
          status: 'error',
          error: error instanceof Error ? error.message : 'Unknown error'
        }
      })
    }
  },
}))
```

### Extract Store Type

```typescript
const useStore = create((set) => ({
  count: 0,
  text: '',
  increment: () => set((state) => ({ count: state.count + 1 })),
}))

// Extract the store state type
type StoreState = ReturnType<typeof useStore.getState>
// { count: number, text: string, increment: () => void }

// Extract just the state properties (no actions)
type State = Omit<StoreState, 'increment'>
// { count: number, text: string }
```

---

## Common Patterns

### Pattern 1: Separate State and Actions

```typescript
interface State {
  count: number
  user: User | null
}

interface Actions {
  increment: () => void
  setUser: (user: User) => void
  reset: () => void
}

type StoreState = State & Actions

const initialState: State = {
  count: 0,
  user: null,
}

const useStore = create<StoreState>((set) => ({
  ...initialState,

  increment: () => set((state) => ({ count: state.count + 1 })),
  setUser: (user) => set({ user }),
  reset: () => set(initialState),
}))
```

### Pattern 2: Readonly State

```typescript
interface ReadonlyState {
  readonly count: number
  readonly user: Readonly<User> | null
}

interface Actions {
  increment: () => void
  setUser: (user: User) => void
}

const useStore = create<ReadonlyState & Actions>((set) => ({
  count: 0,
  user: null,
  increment: () => set((state) => ({ count: state.count + 1 })),
  setUser: (user) => set({ user }),
}))
```

### Pattern 3: Typed get Parameter

```typescript
interface State {
  count: number
  multiplier: number
  multiplyAndAdd: () => void
}

const useStore = create<State>((set, get) => ({
  count: 0,
  multiplier: 2,

  multiplyAndAdd: () => {
    const state = get() // Typed as State
    set({ count: state.count * state.multiplier + 1 })
  },
}))
```

---

## Best Practices

### 1. Always Type Your Stores

```typescript
// ✅ Good - Explicit typing
interface State {
  count: number
  increment: () => void
}

const useStore = create<State>((set) => ({
  count: 0,
  increment: () => set((state) => ({ count: state.count + 1 })),
}))

// ❌ Bad - No typing (lose type safety)
const useStore = create((set) => ({
  count: 0,
  increment: () => set((state) => ({ count: state.count + 1 })),
}))
```

### 2. Use Interfaces for State, Types for Unions

```typescript
// ✅ Interface for object state
interface UserState {
  user: User | null
  setUser: (user: User) => void
}

// ✅ Type for unions/complex types
type AsyncStatus = 'idle' | 'loading' | 'success' | 'error'
```

### 3. Type Action Parameters

```typescript
// ✅ Good - Typed parameters
interface State {
  items: Item[]
  addItem: (item: Omit<Item, 'id'>) => void
  updateItem: (id: string, updates: Partial<Item>) => void
}

// ❌ Bad - Untyped parameters
interface State {
  items: Item[]
  addItem: (item: any) => void
  updateItem: (id: any, updates: any) => void
}
```

### 4. Extract Common Types

```typescript
// Reusable async state type
type AsyncState<T, E = string> =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'success'; data: T }
  | { status: 'error'; error: E }

// Use across multiple stores
interface UserStore {
  userState: AsyncState<User>
}

interface PostsStore {
  postsState: AsyncState<Post[]>
}
```

---

## Common Pitfalls

### Pitfall 1: Forgetting () with Middleware

```typescript
// ❌ Wrong - Type inference fails
const useStore = create<State>(
  persist(/* ... */)
)

// ✅ Correct - Extra () for type inference
const useStore = create<State>()(
  persist(/* ... */)
)
```

### Pitfall 2: Any Types in Actions

```typescript
// ❌ Bad - any parameter
const updateUser = (user: any) => set({ user })

// ✅ Good - Typed parameter
const updateUser = (user: User) => set({ user })
```

### Pitfall 3: Not Typing get Parameter

```typescript
// ❌ Bad - Untyped get
const useStore = create((set, get) => ({
  count: 0,
  double: () => {
    const state = get() // Type is unknown
    set({ count: state.count * 2 })
  },
}))

// ✅ Good - Typed store
interface State {
  count: number
  double: () => void
}

const useStore = create<State>((set, get) => ({
  count: 0,
  double: () => {
    const state = get() // Type is State
    set({ count: state.count * 2 })
  },
}))
```

---

## AI Pair Programming Notes

**When to load this file:**
- Setting up TypeScript with Zustand
- Type errors in store
- Typing middleware
- Creating reusable typed patterns

**Typical questions:**
- "How do I type my Zustand store?"
- "Why do I need () with middleware?"
- "How do I type selectors?"
- "What's the best way to structure types?"

**Next steps:**
- [08-TESTING.md](./08-TESTING.md) - Testing TypeScript Zustand stores
- [09-ADVANCED-PATTERNS.md](./09-ADVANCED-PATTERNS.md) - Advanced TypeScript patterns
- [02-STORE-CREATION.md](./02-STORE-CREATION.md) - Review store creation basics
