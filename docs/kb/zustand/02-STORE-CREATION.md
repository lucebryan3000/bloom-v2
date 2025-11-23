---
id: zustand-02-store-creation
topic: zustand
file_role: core
profile: full
difficulty_level: beginner-to-intermediate
kb_version: 3.1
prerequisites: [zustand-fundamentals, react-hooks]
related_topics: [react, state-management, hooks]
embedding_keywords: [zustand, store, create, state, hooks]
last_reviewed: 2025-11-16
---

# Zustand - Store Creation

## Purpose

Learn how to create Zustand stores using the `create` function, understand the store structure, and implement basic state and actions.

## Table of Contents

1. [Basic Store Creation](#basic-store-creation)
2. [Store Structure](#store-structure)
3. [State and Actions](#state-and-actions)
4. [The set Function](#the-set-function)
5. [Common Patterns](#common-patterns)
6. [Best Practices](#best-practices)

---

## Basic Store Creation

### Installation

```bash
npm install zustand
```

### Creating Your First Store

```typescript
import { create } from 'zustand'

const useBearStore = create((set) => ({
  bears: 0,
  increasePopulation: () => set((state) => ({ bears: state.bears + 1 })),
  removeAllBears: () => set({ bears: 0 }),
}))
```

**Key Points:**
- `create` returns a React hook
- The callback receives `set` function for updates
- Return an object with state and actions
- No providers or wrappers needed

### Using the Store

```typescript
function BearCounter() {
  const bears = useBearStore((state) => state.bears)
  return <h1>{bears} around here...</h1>
}

function Controls() {
  const increasePopulation = useBearStore((state) => state.increasePopulation)
  return <button onClick={increasePopulation}>one up</button>
}
```

---

## Store Structure

### Anatomy of a Store

```typescript
const useStore = create((set, get) => ({
  // State properties
  count: 0,
  user: null,
  items: [],

  // Actions
  increment: () => set((state) => ({ count: state.count + 1 })),
  setUser: (user) => set({ user }),
  addItem: (item) => set((state) => ({ items: [...state.items, item] })),

  // Computed values (using get)
  getTotal: () => {
    const state = get()
    return state.items.reduce((sum, item) => sum + item.price, 0)
  },
}))
```

**Parameters:**
- `set(partial)` - Merge state updates
- `get()` - Read current state
- `api` - Store API (rarely used)

---

## State and Actions

### State Properties

```typescript
const useGameStore = create((set) => ({
  // Primitives
  score: 0,
  level: 1,

  // Objects
  player: {
    name: 'Player 1',
    health: 100,
  },

  // Arrays
  inventory: [],

  // Booleans
  isPaused: false,
}))
```

### Action Patterns

```typescript
const useTaskStore = create((set, get) => ({
  tasks: [],

  // Add task
  addTask: (task) => set((state) => ({
    tasks: [...state.tasks, { id: Date.now(), ...task }]
  })),

  // Remove task
  removeTask: (id) => set((state) => ({
    tasks: state.tasks.filter(t => t.id !== id)
  })),

  // Toggle task
  toggleTask: (id) => set((state) => ({
    tasks: state.tasks.map(t =>
      t.id === id ? { ...t, completed: !t.completed } : t
    )
  })),

  // Clear completed
  clearCompleted: () => set((state) => ({
    tasks: state.tasks.filter(t => !t.completed)
  })),

  // Get specific task (using get)
  getTask: (id) => {
    return get().tasks.find(t => t.id === id)
  },
}))
```

---

## The set Function

### Merge Mode (Default)

```typescript
const useStore = create((set) => ({
  user: { name: 'Alice', age: 30 },
  count: 0,

  updateUser: (updates) => set((state) => ({
    user: { ...state.user, ...updates } // Must spread manually
  })),

  increment: () => set({ count: 5 }), // Merges: { ...state, count: 5 }
}))
```

**Important:** `set` merges at the top level only. Nested objects must be spread manually.

### Replace Mode

```typescript
const useStore = create((set) => ({
  user: { name: 'Bob', age: 25 },

  // ❌ Bad - Loses 'user' property
  resetCount: () => set({ count: 0 }, true), // replace=true

  // ✅ Good - Explicit replace
  reset: () => set({ user: null, count: 0 }, true),
}))
```

Second parameter `true` = replace entire state (rarely needed).

### Function vs Object Updates

```typescript
const useCountStore = create((set) => ({
  count: 0,

  // Function form - access current state
  increment: () => set((state) => ({ count: state.count + 1 })),

  // Object form - no access to current state
  reset: () => set({ count: 0 }),
}))
```

**Rule:** Use function form when update depends on current state.

---

## Common Patterns

### Counter Pattern

```typescript
const useCounterStore = create((set) => ({
  count: 0,
  increment: () => set((state) => ({ count: state.count + 1 })),
  decrement: () => set((state) => ({ count: state.count - 1 })),
  reset: () => set({ count: 0 }),
}))
```

### CRUD Pattern

```typescript
const useItemStore = create((set) => ({
  items: [],

  create: (item) => set((state) => ({
    items: [...state.items, { id: crypto.randomUUID(), ...item }]
  })),

  read: (id) => useItemStore.getState().items.find(i => i.id === id),

  update: (id, updates) => set((state) => ({
    items: state.items.map(i => i.id === id ? { ...i, ...updates } : i)
  })),

  delete: (id) => set((state) => ({
    items: state.items.filter(i => i.id !== id)
  })),
}))
```

### Loading/Error Pattern

```typescript
const useDataStore = create((set) => ({
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
      set({ error: error.message, loading: false })
    }
  },

  reset: () => set({ data: null, loading: false, error: null }),
}))
```

---

## Best Practices

### 1. Co-locate State and Actions

```typescript
// ✅ Good - Actions are part of the store
const useStore = create((set) => ({
  count: 0,
  increment: () => set((state) => ({ count: state.count + 1 })),
}))

// ❌ Bad - Actions defined outside
const useStore = create(() => ({ count: 0 }))
const increment = () => useStore.setState((s) => ({ count: s.count + 1 }))
```

### 2. Use Descriptive Names

```typescript
// ✅ Good - Clear intent
const useAuthStore = create((set) => ({
  user: null,
  isAuthenticated: false,
  login: (credentials) => { /* ... */ },
  logout: () => { /* ... */ },
}))

// ❌ Bad - Vague names
const useStore = create((set) => ({
  data: null,
  flag: false,
  fn1: () => { /* ... */ },
}))
```

### 3. One Store Per Domain

```typescript
// ✅ Good - Separate concerns
const useAuthStore = create(/* auth state */)
const useCartStore = create(/* cart state */)
const useUIStore = create(/* UI state */)

// ❌ Bad - Global god store
const useAppStore = create(/* everything */)
```

### 4. Immutable Updates

```typescript
const useStore = create((set) => ({
  items: [],

  // ✅ Good - Immutable
  addItem: (item) => set((state) => ({
    items: [...state.items, item]
  })),

  // ❌ Bad - Mutates state
  addItemBad: (item) => set((state) => {
    state.items.push(item) // NEVER mutate
    return { items: state.items }
  }),
}))
```

### 5. Avoid Inline Functions

```typescript
// ❌ Bad - Creates new function on every render
function Component() {
  const increment = useBearStore((state) => () => state.bears++)
  return <button onClick={increment}>Add</button>
}

// ✅ Good - Action defined in store
const useBearStore = create((set) => ({
  bears: 0,
  increment: () => set((state) => ({ bears: state.bears + 1 })),
}))

function Component() {
  const increment = useBearStore((state) => state.increment)
  return <button onClick={increment}>Add</button>
}
```

---

## Common Pitfalls

### Pitfall 1: Forgetting to Spread Nested Objects

```typescript
const useStore = create((set) => ({
  user: { name: 'Alice', email: 'alice@example.com' },

  // ❌ Bad - Loses email
  updateName: (name) => set({ user: { name } }),

  // ✅ Good - Preserves email
  updateName: (name) => set((state) => ({
    user: { ...state.user, name }
  })),
}))
```

### Pitfall 2: Relying on Stale State

```typescript
const useStore = create((set) => ({
  count: 0,
  items: [],

  // ❌ Bad - Closure captures stale count
  badAdd: (item) => {
    const { count } = useStore.getState()
    setTimeout(() => set({ items: [...items, item] }), 1000)
  },

  // ✅ Good - Get fresh state when needed
  goodAdd: (item) => {
    setTimeout(() => {
      const { items } = useStore.getState()
      set({ items: [...items, item] })
    }, 1000)
  },
}))
```

### Pitfall 3: Using `set` Outside Actions

```typescript
// ❌ Bad - set called outside store
const useStore = create((set) => ({ count: 0 }))
const increment = () => useStore.setState((s) => ({ count: s.count + 1 }))

// ✅ Good - Action defined in store
const useStore = create((set) => ({
  count: 0,
  increment: () => set((state) => ({ count: state.count + 1 })),
}))
```

---

## AI Pair Programming Notes

**When to load this file:**
- Creating a new Zustand store
- Understanding store structure
- Implementing actions
- Debugging state update issues

**Typical questions this answers:**
- "How do I create a Zustand store?"
- "What's the difference between set with function vs object?"
- "How do I update nested objects?"
- "Should actions be inside or outside the store?"

**Next steps:**
- Read [03-STATE-UPDATES.md](./03-STATE-UPDATES.md) for advanced update patterns
- Read [04-SELECTORS.md](./04-SELECTORS.md) for consuming state in components
- Read [07-TYPESCRIPT.md](./07-TYPESCRIPT.md) for TypeScript patterns
