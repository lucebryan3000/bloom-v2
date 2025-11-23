---
id: zustand-09-advanced-patterns
topic: zustand
file_role: advanced
profile: full
difficulty_level: advanced
kb_version: 3.1
prerequisites: [zustand-fundamentals, zustand-store-creation, zustand-middleware]
related_topics: [advanced-patterns, architecture, scalability]
embedding_keywords: [zustand, advanced, patterns, slices, subscriptions, vanilla]
last_reviewed: 2025-11-16
---

# Zustand - Advanced Patterns

## Purpose

Explore advanced Zustand patterns for large-scale applications, including store slices, vanilla stores, cross-store communication, and architectural patterns.

## Table of Contents

1. [Store Slices](#store-slices)
2. [Vanilla Stores](#vanilla-stores)
3. [Cross-Store Communication](#cross-store-communication)
4. [Subscriptions](#subscriptions)
5. [Code Splitting](#code-splitting)
6. [Advanced Architectural Patterns](#advanced-architectural-patterns)

---

## Store Slices

### Slicing Large Stores

```typescript
import { StateCreator } from 'zustand'

// Define slice interfaces
interface UserSlice {
  user: User | null
  setUser: (user: User) => void
  clearUser: () => void
}

interface PostsSlice {
  posts: Post[]
  addPost: (post: Post) => void
  removePost: (id: string) => void
}

interface CommentsSlice {
  comments: Comment[]
  addComment: (comment: Comment) => void
}

// Create slice creators
const createUserSlice: StateCreator<
  UserSlice & PostsSlice & CommentsSlice,
  [],
  [],
  UserSlice
> = (set) => ({
  user: null,
  setUser: (user) => set({ user }),
  clearUser: () => set({ user: null }),
})

const createPostsSlice: StateCreator<
  UserSlice & PostsSlice & CommentsSlice,
  [],
  [],
  PostsSlice
> = (set) => ({
  posts: [],
  addPost: (post) => set((state) => ({ posts: [...state.posts, post] })),
  removePost: (id) => set((state) => ({
    posts: state.posts.filter(p => p.id !== id)
  })),
})

const createCommentsSlice: StateCreator<
  UserSlice & PostsSlice & CommentsSlice,
  [],
  [],
  CommentsSlice
> = (set) => ({
  comments: [],
  addComment: (comment) => set((state) => ({
    comments: [...state.comments, comment]
  })),
})

// Combine slices
const useStore = create<UserSlice & PostsSlice & CommentsSlice>()(
  (...a) => ({
    ...createUserSlice(...a),
    ...createPostsSlice(...a),
    ...createCommentsSlice(...a),
  })
)
```

### Slice with Dependencies

```typescript
interface CartSlice {
  items: CartItem[]
  addItem: (item: CartItem) => void
  removeItem: (id: string) => void
}

interface CheckoutSlice {
  isCheckingOut: boolean
  checkout: () => Promise<void>
}

// CheckoutSlice depends on CartSlice
const createCheckoutSlice: StateCreator<
  CartSlice & CheckoutSlice,
  [],
  [],
  CheckoutSlice
> = (set, get) => ({
  isCheckingOut: false,
  checkout: async () => {
    const { items } = get() // Access CartSlice state

    if (items.length === 0) {
      throw new Error('Cart is empty')
    }

    set({ isCheckingOut: true })

    try {
      await processPayment(items)
      set({ items: [], isCheckingOut: false })
    } catch (error) {
      set({ isCheckingOut: false })
      throw error
    }
  },
})
```

---

## Vanilla Stores

### Creating Vanilla (Non-React) Store

```typescript
import { createStore } from 'zustand/vanilla'

interface CounterState {
  count: number
  increment: () => void
  decrement: () => void
}

const counterStore = createStore<CounterState>((set) => ({
  count: 0,
  increment: () => set((state) => ({ count: state.count + 1 })),
  decrement: () => set((state) => ({ count: state.count - 1 })),
}))

// Use outside React
counterStore.getState().increment()
console.log(counterStore.getState().count) // 1

// Subscribe to changes
const unsubscribe = counterStore.subscribe((state) => {
  console.log('Count changed:', state.count)
})

// Cleanup
unsubscribe()
```

### React Hook from Vanilla Store

```typescript
import { useStore } from 'zustand'

const counterStore = createStore<CounterState>(/* ... */)

// Create React hook from vanilla store
function useCounterStore(): CounterState
function useCounterStore<T>(selector: (state: CounterState) => T): T
function useCounterStore<T>(selector?: (state: CounterState) => T) {
  return useStore(counterStore, selector!)
}

// Usage in components
function Counter() {
  const count = useCounterStore((state) => state.count)
  const increment = useCounterStore((state) => state.increment)

  return <button onClick={increment}>{count}</button>
}
```

### Vanilla Store in Node.js

```typescript
// server.ts
import { createStore } from 'zustand/vanilla'

interface AppState {
  users: User[]
  sessions: Session[]
  addUser: (user: User) => void
  addSession: (session: Session) => void
}

export const appStore = createStore<AppState>((set) => ({
  users: [],
  sessions: [],
  addUser: (user) => set((state) => ({ users: [...state.users, user] })),
  addSession: (session) => set((state) => ({
    sessions: [...state.sessions, session]
  })),
}))

// Use in Express middleware
app.post('/users', (req, res) => {
  const user = req.body
  appStore.getState().addUser(user)
  res.json(appStore.getState().users)
})
```

---

## Cross-Store Communication

### Store References

```typescript
const useAuthStore = create<AuthState>((set) => ({
  user: null,
  token: null,
  login: async (credentials) => {
    const { user, token } = await api.login(credentials)
    set({ user, token })
  },
  logout: () => set({ user: null, token: null }),
}))

const useCartStore = create<CartState>((set, get) => ({
  items: [],

  checkout: async () => {
    // Access auth store
    const { user, token } = useAuthStore.getState()

    if (!user || !token) {
      throw new Error('Not authenticated')
    }

    const { items } = get()
    await api.checkout(items, token)

    set({ items: [] })
  },
}))
```

### Event Bus Pattern

```typescript
import mitt, { Emitter } from 'mitt'

type Events = {
  'user:login': User
  'user:logout': void
  'cart:checkout': { total: number }
}

const emitter: Emitter<Events> = mitt()

// Auth store emits events
const useAuthStore = create<AuthState>((set) => ({
  user: null,
  login: async (credentials) => {
    const user = await api.login(credentials)
    set({ user })
    emitter.emit('user:login', user)
  },
  logout: () => {
    set({ user: null })
    emitter.emit('user:logout')
  },
}))

// Cart store listens to events
const useCartStore = create<CartState>((set) => {
  // Subscribe to auth events
  emitter.on('user:logout', () => {
    set({ items: [] }) // Clear cart on logout
  })

  return {
    items: [],
    checkout: async () => {
      const total = /* calculate total */
      await api.checkout()
      emitter.emit('cart:checkout', { total })
      set({ items: [] })
    },
  }
})
```

### Shared Subscriptions

```typescript
const useAuthStore = create<AuthState>(/* ... */)
const useCartStore = create<CartState>(/* ... */)
const useOrderStore = create<OrderState>(/* ... */)

// Subscribe all stores to logout
function subscribeToLogout() {
  useAuthStore.subscribe(
    (state) => state.user,
    (user) => {
      if (!user) {
        // Clear other stores on logout
        useCartStore.setState({ items: [] })
        useOrderStore.setState({ orders: [] })
      }
    }
  )
}

// Call on app initialization
subscribeToLogout()
```

---

## Subscriptions

### Custom Subscription

```typescript
const useStore = create<State>((set) => ({ /* ... */ }))

// Subscribe to specific state changes
const unsubscribe = useStore.subscribe(
  (state) => console.log('State changed:', state)
)

// Cleanup
unsubscribe()
```

### Selective Subscription with Equality

```typescript
import { shallow } from 'zustand/shallow'

const unsubscribe = useStore.subscribe(
  (state) => [state.count, state.user],
  (newValues, oldValues) => {
    console.log('Changed from', oldValues, 'to', newValues)
  },
  { equalityFn: shallow }
)
```

### Subscription Middleware

```typescript
import { subscribeWithSelector } from 'zustand/middleware'

const useStore = create(
  subscribeWithSelector((set) => ({
    count: 0,
    user: null,
    increment: () => set((state) => ({ count: state.count + 1 })),
  }))
)

// Subscribe to count changes only
const unsubscribe = useStore.subscribe(
  (state) => state.count,
  (count) => console.log('Count:', count)
)
```

### Transient Updates

```typescript
const useStore = create((set) => ({
  x: 0,
  y: 0,
  setPosition: (x: number, y: number) => set({ x, y }),
}))

// High-frequency updates without re-renders
const unsubscribe = useStore.subscribe((state) => {
  // Update canvas, log metrics, etc.
  console.log('Position:', state.x, state.y)
})

// Component doesn't re-render on every position change
function Component() {
  const setPosition = useStore((state) => state.setPosition)

  useEffect(() => {
    const handleMouseMove = (e: MouseEvent) => {
      setPosition(e.clientX, e.clientY)
    }

    window.addEventListener('mousemove', handleMouseMove)
    return () => window.removeEventListener('mousemove', handleMouseMove)
  }, [setPosition])

  return <div>Tracking mouse...</div>
}
```

---

## Code Splitting

### Lazy Store Loading

```typescript
// stores/userStore.ts
export const createUserStore = () => create<UserState>((set) => ({
  user: null,
  setUser: (user) => set({ user }),
}))

// Component.tsx
const UserProfile = lazy(() => import('./UserProfile'))

function App() {
  const [userStore, setUserStore] = useState<ReturnType<typeof createUserStore> | null>(null)

  useEffect(() => {
    import('./stores/userStore').then(({ createUserStore }) => {
      setUserStore(createUserStore())
    })
  }, [])

  if (!userStore) return <div>Loading...</div>

  return <UserProfile useUserStore={userStore} />
}
```

### Dynamic Store Creation

```typescript
const storeCache = new Map()

function getOrCreateStore<T>(
  key: string,
  creator: () => StoreApi<T>
): StoreApi<T> {
  if (!storeCache.has(key)) {
    storeCache.set(key, creator())
  }
  return storeCache.get(key)
}

// Usage
const usePostsStore = getOrCreateStore('posts', () =>
  create<PostsState>((set) => ({ /* ... */ }))
)
```

---

## Advanced Architectural Patterns

### Repository Pattern

```typescript
// repositories/userRepository.ts
export class UserRepository {
  private store = createStore<UserState>((set) => ({
    users: [],
    addUser: (user) => set((state) => ({ users: [...state.users, user] })),
  }))

  async fetchUsers() {
    const users = await api.getUsers()
    this.store.setState({ users })
  }

  getUser(id: string) {
    return this.store.getState().users.find(u => u.id === id)
  }

  subscribe(listener: (state: UserState) => void) {
    return this.store.subscribe(listener)
  }
}

export const userRepository = new UserRepository()
```

### Store Factory Pattern

```typescript
function createEntityStore<T extends { id: string }>() {
  return create<{
    items: T[]
    add: (item: T) => void
    remove: (id: string) => void
    update: (id: string, updates: Partial<T>) => void
    getById: (id: string) => T | undefined
  }>((set, get) => ({
    items: [],

    add: (item) => set((state) => ({ items: [...state.items, item] })),

    remove: (id) => set((state) => ({
      items: state.items.filter(i => i.id !== id)
    })),

    update: (id, updates) => set((state) => ({
      items: state.items.map(i => i.id === id ? { ...i, ...updates } : i)
    })),

    getById: (id) => get().items.find(i => i.id === id),
  }))
}

// Usage
const useUsersStore = createEntityStore<User>()
const usePostsStore = createEntityStore<Post>()
```

### Context-Based Stores

```typescript
import { createContext, useContext } from 'react'

interface Store {
  count: number
  increment: () => void
}

const StoreContext = createContext<ReturnType<typeof createStore<Store>> | null>(null)

export function StoreProvider({ children }: { children: React.ReactNode }) {
  const [store] = useState(() =>
    createStore<Store>((set) => ({
      count: 0,
      increment: () => set((state) => ({ count: state.count + 1 })),
    }))
  )

  return <StoreContext.Provider value={store}>{children}</StoreContext.Provider>
}

export function useAppStore(): Store
export function useAppStore<T>(selector: (state: Store) => T): T
export function useAppStore<T>(selector?: (state: Store) => T) {
  const store = useContext(StoreContext)
  if (!store) throw new Error('Missing StoreProvider')
  return useStore(store, selector!)
}
```

---

## Best Practices

### 1. Use Slices for Large Stores

```typescript
// ✅ Good - Organized slices
const useStore = create((set) => ({
  ...createUserSlice(set),
  ...createPostsSlice(set),
  ...createSettingsSlice(set),
}))

// ❌ Bad - Monolithic store
const useStore = create((set) => ({
  user: null,
  posts: [],
  settings: {},
  // ... 100 more properties
}))
```

### 2. Keep Stores Focused

```typescript
// ✅ Good - Single responsibility
const useAuthStore = create(/* auth logic */)
const useCartStore = create(/* cart logic */)
const useUIStore = create(/* UI state */)

// ❌ Bad - God store
const useAppStore = create(/* everything */)
```

### 3. Use Vanilla Stores for Non-React Code

```typescript
// ✅ Good - Vanilla store for server/workers
const appStore = createStore<AppState>(/* ... */)

// ❌ Bad - React hook in Node.js
const useAppStore = create(/* ... */) // Can't use in Node!
```

---

## AI Pair Programming Notes

**When to load this file:**
- Building large-scale applications
- Need advanced patterns
- Cross-store communication
- Performance optimization

**Typical questions:**
- "How do I split a large store?"
- "Can stores communicate?"
- "How do I use Zustand outside React?"
- "What's the best architecture for large apps?"

**Next steps:**
- [10-PERFORMANCE.md](./10-PERFORMANCE.md) - Performance optimization
- [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) - Production configuration
- [06-MIDDLEWARE.md](./06-MIDDLEWARE.md) - Review middleware patterns
