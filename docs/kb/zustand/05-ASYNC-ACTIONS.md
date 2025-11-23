---
id: zustand-05-async-actions
topic: zustand
file_role: practical
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [zustand-fundamentals, zustand-store-creation]
related_topics: [async-programming, react, promises]
embedding_keywords: [zustand, async, promises, fetch, loading, error-handling]
last_reviewed: 2025-11-16
---

# Zustand - Async Actions and Side Effects

## Purpose

Learn how to handle asynchronous operations in Zustand stores, including data fetching, loading states, error handling, and best practices for async workflows.

## Table of Contents

1. [Basic Async Actions](#basic-async-actions)
2. [Loading and Error States](#loading-and-error-states)
3. [Fetch Patterns](#fetch-patterns)
4. [Multiple Concurrent Requests](#multiple-concurrent-requests)
5. [Cancellation and Cleanup](#cancellation-and-cleanup)
6. [Optimistic Updates](#optimistic-updates)
7. [Best Practices](#best-practices)

---

## Basic Async Actions

### Simple Async Function

```typescript
const useStore = create((set) => ({
  data: null,

  fetchData: async () => {
    const response = await fetch('/api/data')
    const data = await response.json()
    set({ data })
  }
}))
```

**Key Points:**
- Async actions work naturally - no special syntax needed
- Call `set` when async operation completes
- Store handles async/sync actions identically

### Using in Components

```typescript
function DataComponent() {
  const { data, fetchData } = useStore(
    useShallow((state) => ({ data: state.data, fetchData: state.fetchData }))
  )

  useEffect(() => {
    fetchData()
  }, [fetchData])

  return <div>{data ? JSON.stringify(data) : 'Loading...'}</div>
}
```

---

## Loading and Error States

### Standard Loading/Error Pattern

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
    // Start loading
    set({ loading: true, error: null })

    try {
      const response = await fetch(url)

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }

      const data = await response.json()

      // Success
      set({ data, loading: false })
    } catch (error) {
      // Error
      set({
        error: error instanceof Error ? error.message : 'Unknown error',
        loading: false
      })
    }
  },
}))
```

### Using Loading States

```typescript
function DataDisplay() {
  const { data, loading, error, fetchData } = useDataStore()

  useEffect(() => {
    fetchData('/api/data')
  }, [])

  if (loading) return <div>Loading...</div>
  if (error) return <div>Error: {error}</div>
  if (!data) return <div>No data</div>

  return <div>{JSON.stringify(data)}</div>
}
```

### Reset Function

```typescript
const useDataStore = create((set) => ({
  data: null,
  loading: false,
  error: null,

  fetchData: async (url) => {
    // ... fetch logic
  },

  reset: () => set({ data: null, loading: false, error: null }),
}))
```

---

## Fetch Patterns

### Pattern 1: CRUD Operations

```typescript
interface Item {
  id: string
  name: string
}

const useItemStore = create<{
  items: Item[]
  loading: boolean
  error: string | null
  fetchItems: () => Promise<void>
  createItem: (item: Omit<Item, 'id'>) => Promise<void>
  updateItem: (id: string, updates: Partial<Item>) => Promise<void>
  deleteItem: (id: string) => Promise<void>
}>((set, get) => ({
  items: [],
  loading: false,
  error: null,

  // READ
  fetchItems: async () => {
    set({ loading: true, error: null })
    try {
      const response = await fetch('/api/items')
      const items = await response.json()
      set({ items, loading: false })
    } catch (error) {
      set({ error: 'Failed to fetch items', loading: false })
    }
  },

  // CREATE
  createItem: async (item) => {
    set({ loading: true, error: null })
    try {
      const response = await fetch('/api/items', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(item),
      })
      const newItem = await response.json()

      set((state) => ({
        items: [...state.items, newItem],
        loading: false
      }))
    } catch (error) {
      set({ error: 'Failed to create item', loading: false })
    }
  },

  // UPDATE
  updateItem: async (id, updates) => {
    set({ loading: true, error: null })
    try {
      const response = await fetch(`/api/items/${id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(updates),
      })
      const updatedItem = await response.json()

      set((state) => ({
        items: state.items.map(item =>
          item.id === id ? updatedItem : item
        ),
        loading: false
      }))
    } catch (error) {
      set({ error: 'Failed to update item', loading: false })
    }
  },

  // DELETE
  deleteItem: async (id) => {
    set({ loading: true, error: null })
    try {
      await fetch(`/api/items/${id}`, { method: 'DELETE' })

      set((state) => ({
        items: state.items.filter(item => item.id !== id),
        loading: false
      }))
    } catch (error) {
      set({ error: 'Failed to delete item', loading: false })
    }
  },
}))
```

### Pattern 2: Paginated Data

```typescript
interface PaginatedState {
  items: any[]
  page: number
  totalPages: number
  loading: boolean
  hasMore: boolean
  fetchPage: (page: number) => Promise<void>
  fetchNextPage: () => Promise<void>
}

const usePaginatedStore = create<PaginatedState>((set, get) => ({
  items: [],
  page: 1,
  totalPages: 1,
  loading: false,
  hasMore: true,

  fetchPage: async (page) => {
    set({ loading: true })
    try {
      const response = await fetch(`/api/items?page=${page}`)
      const { items, totalPages } = await response.json()

      set({
        items,
        page,
        totalPages,
        hasMore: page < totalPages,
        loading: false
      })
    } catch (error) {
      set({ loading: false })
    }
  },

  fetchNextPage: async () => {
    const { page, hasMore, loading } = get()

    if (!hasMore || loading) return

    await get().fetchPage(page + 1)
  },
}))
```

### Pattern 3: Infinite Scroll

```typescript
const useInfiniteStore = create<{
  items: any[]
  page: number
  hasMore: boolean
  loading: boolean
  loadMore: () => Promise<void>
}>((set, get) => ({
  items: [],
  page: 1,
  hasMore: true,
  loading: false,

  loadMore: async () => {
    const { loading, hasMore, page } = get()

    if (loading || !hasMore) return

    set({ loading: true })

    try {
      const response = await fetch(`/api/items?page=${page}`)
      const newItems = await response.json()

      set((state) => ({
        items: [...state.items, ...newItems],
        page: state.page + 1,
        hasMore: newItems.length > 0,
        loading: false
      }))
    } catch (error) {
      set({ loading: false })
    }
  },
}))
```

---

## Multiple Concurrent Requests

### Parallel Requests

```typescript
const useMultiStore = create((set) => ({
  users: null,
  posts: null,
  comments: null,
  loading: false,

  fetchAll: async () => {
    set({ loading: true })

    try {
      const [users, posts, comments] = await Promise.all([
        fetch('/api/users').then(r => r.json()),
        fetch('/api/posts').then(r => r.json()),
        fetch('/api/comments').then(r => r.json()),
      ])

      set({ users, posts, comments, loading: false })
    } catch (error) {
      set({ loading: false })
    }
  },
}))
```

### Sequential Requests (Dependent Data)

```typescript
const useSequentialStore = create((set, get) => ({
  user: null,
  userPosts: null,
  loading: false,

  fetchUserAndPosts: async (userId: string) => {
    set({ loading: true })

    try {
      // First request
      const userResponse = await fetch(`/api/users/${userId}`)
      const user = await userResponse.json()
      set({ user })

      // Second request depends on first
      const postsResponse = await fetch(`/api/users/${userId}/posts`)
      const userPosts = await postsResponse.json()

      set({ userPosts, loading: false })
    } catch (error) {
      set({ loading: false })
    }
  },
}))
```

### Individual Loading States

```typescript
interface MultiLoadingState {
  users: any[] | null
  posts: any[] | null
  usersLoading: boolean
  postsLoading: boolean
  fetchUsers: () => Promise<void>
  fetchPosts: () => Promise<void>
}

const useStore = create<MultiLoadingState>((set) => ({
  users: null,
  posts: null,
  usersLoading: false,
  postsLoading: false,

  fetchUsers: async () => {
    set({ usersLoading: true })
    try {
      const response = await fetch('/api/users')
      const users = await response.json()
      set({ users, usersLoading: false })
    } catch (error) {
      set({ usersLoading: false })
    }
  },

  fetchPosts: async () => {
    set({ postsLoading: true })
    try {
      const response = await fetch('/api/posts')
      const posts = await response.json()
      set({ posts, postsLoading: false })
    } catch (error) {
      set({ postsLoading: false })
    }
  },
}))
```

---

## Cancellation and Cleanup

### Using AbortController

```typescript
const useAbortableStore = create<{
  data: any | null
  loading: boolean
  abortController: AbortController | null
  fetchData: (url: string) => Promise<void>
  cancel: () => void
}>((set, get) => ({
  data: null,
  loading: false,
  abortController: null,

  fetchData: async (url) => {
    // Cancel previous request
    get().cancel()

    const abortController = new AbortController()
    set({ loading: true, abortController })

    try {
      const response = await fetch(url, {
        signal: abortController.signal
      })
      const data = await response.json()

      set({ data, loading: false, abortController: null })
    } catch (error) {
      if (error instanceof Error && error.name === 'AbortError') {
        console.log('Request cancelled')
      } else {
        set({ loading: false, abortController: null })
      }
    }
  },

  cancel: () => {
    const { abortController } = get()
    if (abortController) {
      abortController.abort()
      set({ loading: false, abortController: null })
    }
  },
}))
```

### Debounced Search

```typescript
const useSearchStore = create<{
  query: string
  results: any[]
  loading: boolean
  timeoutId: NodeJS.Timeout | null
  search: (query: string) => void
}>((set, get) => ({
  query: '',
  results: [],
  loading: false,
  timeoutId: null,

  search: (query) => {
    // Clear previous timeout
    const { timeoutId } = get()
    if (timeoutId) {
      clearTimeout(timeoutId)
    }

    set({ query, loading: true })

    // Debounce search
    const newTimeoutId = setTimeout(async () => {
      try {
        const response = await fetch(`/api/search?q=${query}`)
        const results = await response.json()
        set({ results, loading: false, timeoutId: null })
      } catch (error) {
        set({ loading: false, timeoutId: null })
      }
    }, 300)

    set({ timeoutId: newTimeoutId })
  },
}))
```

---

## Optimistic Updates

### Immediate UI Update with Rollback

```typescript
interface TodoState {
  todos: Todo[]
  toggleTodo: (id: string) => Promise<void>
}

const useTodoStore = create<TodoState>((set, get) => ({
  todos: [],

  toggleTodo: async (id) => {
    // Save current state for rollback
    const previousTodos = get().todos

    // Optimistic update
    set((state) => ({
      todos: state.todos.map(todo =>
        todo.id === id ? { ...todo, completed: !todo.completed } : todo
      )
    }))

    try {
      // Send to server
      await fetch(`/api/todos/${id}/toggle`, { method: 'POST' })
    } catch (error) {
      // Rollback on error
      set({ todos: previousTodos })
      console.error('Failed to toggle todo:', error)
    }
  },
}))
```

### Optimistic Create

```typescript
const useItemStore = create<{
  items: Item[]
  createItem: (item: Omit<Item, 'id'>) => Promise<void>
}>((set) => ({
  items: [],

  createItem: async (item) => {
    // Create temporary ID
    const tempId = `temp-${Date.now()}`
    const optimisticItem = { ...item, id: tempId }

    // Add immediately
    set((state) => ({
      items: [...state.items, optimisticItem]
    }))

    try {
      const response = await fetch('/api/items', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(item),
      })
      const serverItem = await response.json()

      // Replace temp with server item
      set((state) => ({
        items: state.items.map(i =>
          i.id === tempId ? serverItem : i
        )
      }))
    } catch (error) {
      // Remove optimistic item on error
      set((state) => ({
        items: state.items.filter(i => i.id !== tempId)
      }))
    }
  },
}))
```

---

## Best Practices

### 1. Always Handle Errors

```typescript
// ✅ Good - Error handling
const fetchData = async () => {
  set({ loading: true, error: null })
  try {
    const data = await fetch('/api/data').then(r => r.json())
    set({ data, loading: false })
  } catch (error) {
    set({
      error: error instanceof Error ? error.message : 'Unknown error',
      loading: false
    })
  }
}

// ❌ Bad - No error handling
const fetchDataBad = async () => {
  const data = await fetch('/api/data').then(r => r.json())
  set({ data })
}
```

### 2. Separate Loading States for Independent Operations

```typescript
// ✅ Good - Separate loading states
const useStore = create((set) => ({
  users: [],
  posts: [],
  usersLoading: false,
  postsLoading: false,
  fetchUsers: async () => { /* ... */ },
  fetchPosts: async () => { /* ... */ },
}))

// ❌ Bad - Single loading state for unrelated operations
const useStoreBad = create((set) => ({
  users: [],
  posts: [],
  loading: false, // Ambiguous!
  fetchUsers: async () => { /* ... */ },
  fetchPosts: async () => { /* ... */ },
}))
```

### 3. Use get() for Fresh State in Async Functions

```typescript
// ✅ Good - Fresh state
const incrementAsync = async () => {
  await delay(1000)
  const currentCount = get().count // Fresh value
  set({ count: currentCount + 1 })
}

// ❌ Bad - Stale closure
let count = get().count
const incrementAsyncBad = async () => {
  await delay(1000)
  set({ count: count + 1 }) // Stale value!
}
```

### 4. Clear Loading State on Both Success and Error

```typescript
// ✅ Good - Always clear loading
try {
  const data = await fetchData()
  set({ data, loading: false })
} catch (error) {
  set({ error: error.message, loading: false })
}

// ❌ Bad - Loading stuck on error
try {
  const data = await fetchData()
  set({ data, loading: false })
} catch (error) {
  set({ error: error.message }) // loading still true!
}
```

### 5. Avoid Race Conditions with Request IDs

```typescript
let requestId = 0

const fetchData = async (query: string) => {
  const currentRequestId = ++requestId
  set({ loading: true })

  const data = await fetch(`/api?q=${query}`).then(r => r.json())

  // Only update if this is still the latest request
  if (currentRequestId === requestId) {
    set({ data, loading: false })
  }
}
```

---

## Common Pitfalls

### Pitfall 1: Not Clearing Loading on Error

```typescript
// ❌ Wrong - Loading stuck
const bad = async () => {
  set({ loading: true })
  try {
    const data = await fetch('/api/data').then(r => r.json())
    set({ data })
  } catch (error) {
    console.error(error)
  }
  // loading never set to false!
}

// ✅ Correct
const good = async () => {
  set({ loading: true })
  try {
    const data = await fetch('/api/data').then(r => r.json())
    set({ data, loading: false })
  } catch (error) {
    set({ loading: false })
  }
}
```

### Pitfall 2: Memory Leaks with Unaborted Requests

```typescript
// ❌ Wrong - Request continues after component unmounts
useEffect(() => {
  fetchData()
}, [])

// ✅ Correct - Cancel on unmount
useEffect(() => {
  const abortController = new AbortController()
  fetchData(abortController.signal)
  return () => abortController.abort()
}, [])
```

### Pitfall 3: Race Conditions

```typescript
// ❌ Wrong - Later request might finish first
const search = async (query: string) => {
  const results = await fetch(`/api/search?q=${query}`).then(r => r.json())
  set({ results }) // Might be from old query!
}

// ✅ Correct - Use request IDs
let latestRequestId = 0
const search = async (query: string) => {
  const requestId = ++latestRequestId
  const results = await fetch(`/api/search?q=${query}`).then(r => r.json())
  if (requestId === latestRequestId) {
    set({ results })
  }
}
```

---

## AI Pair Programming Notes

**When to load this file:**
- Implementing data fetching
- Handling loading/error states
- Dealing with async operations
- Debugging race conditions

**Typical questions:**
- "How do I fetch data in Zustand?"
- "How do I handle loading states?"
- "What about error handling?"
- "How do I cancel requests?"
- "What are optimistic updates?"

**Next steps:**
- [06-MIDDLEWARE.md](./06-MIDDLEWARE.md) - Persist async data
- [08-TESTING.md](./08-TESTING.md) - Testing async actions
- [09-ADVANCED-PATTERNS.md](./09-ADVANCED-PATTERNS.md) - Complex async patterns
