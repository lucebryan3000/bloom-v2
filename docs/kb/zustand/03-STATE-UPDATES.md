---
id: zustand-03-state-updates
topic: zustand
file_role: core
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [zustand-fundamentals, zustand-store-creation]
related_topics: [react, immutability, state-management]
embedding_keywords: [zustand, state, updates, set, immutable, mutations]
last_reviewed: 2025-11-16
---

# Zustand - State Updates and Immutability

## Purpose

Master state update patterns in Zustand, understand immutability requirements, and learn advanced update techniques using the `set` function.

## Table of Contents

1. [The set Function Deep Dive](#the-set-function-deep-dive)
2. [Immutable Update Patterns](#immutable-update-patterns)
3. [Nested Object Updates](#nested-object-updates)
4. [Array Operations](#array-operations)
5. [Batching Updates](#batching-updates)
6. [Using the get Function](#using-the-get-function)
7. [Best Practices](#best-practices)

---

## The set Function Deep Dive

### Basic Signature

```typescript
set(
  partial: (state: T) => Partial<T> | Partial<T>,
  replace?: boolean
)
```

**Parameters:**
- `partial`: Function or object with updates
- `replace`: If true, replaces entire state (default: false)

### Two Update Modes

```typescript
const useStore = create((set) => ({
  count: 0,
  user: { name: 'Alice', age: 30 },

  // 1. Function form - access current state
  increment: () => set((state) => ({ count: state.count + 1 })),

  // 2. Object form - no state access
  reset: () => set({ count: 0 }),
}))
```

**When to use:**
- **Function form**: When update depends on current state
- **Object form**: When setting static values

---

## Immutable Update Patterns

### Why Immutability Matters

Zustand uses reference equality to detect changes. Mutating state directly breaks reactivity.

```typescript
const useStore = create((set) => ({
  items: [1, 2, 3],
  user: { name: 'Bob' },

  // ❌ WRONG - Mutates state
  addItemBad: (item) => set((state) => {
    state.items.push(item) // MUTATION!
    return { items: state.items }
  }),

  // ✅ CORRECT - Immutable update
  addItemGood: (item) => set((state) => ({
    items: [...state.items, item]
  })),

  // ❌ WRONG - Mutates nested object
  updateNameBad: (name) => set((state) => {
    state.user.name = name // MUTATION!
    return { user: state.user }
  }),

  // ✅ CORRECT - Spread nested object
  updateNameGood: (name) => set((state) => ({
    user: { ...state.user, name }
  })),
}))
```

### Shallow Merge Behavior

```typescript
const useStore = create((set) => ({
  user: { name: 'Alice', email: 'alice@example.com', age: 30 },
  count: 0,

  // set() merges at TOP LEVEL only
  updateUser: (updates) => set((state) => ({
    // ❌ WRONG - Loses other user properties
    user: { name: updates.name }
  })),

  // ✅ CORRECT - Spreads existing user properties
  updateUser: (updates) => set((state) => ({
    user: { ...state.user, ...updates }
  })),
}))
```

**Key Point:** `set` performs **shallow merge** at the root level. Nested objects must be spread manually.

---

## Nested Object Updates

### Single-Level Nesting

```typescript
const useProfileStore = create((set) => ({
  profile: {
    name: 'Alice',
    email: 'alice@example.com',
    settings: {
      theme: 'dark',
      notifications: true,
    },
  },

  // Update top-level property
  updateName: (name) => set((state) => ({
    profile: {
      ...state.profile,
      name,
    },
  })),

  // Update nested property
  updateTheme: (theme) => set((state) => ({
    profile: {
      ...state.profile,
      settings: {
        ...state.profile.settings,
        theme,
      },
    },
  })),
}))
```

### Deep Nesting Pattern

```typescript
const useDeepStore = create((set) => ({
  data: {
    user: {
      profile: {
        address: {
          street: '123 Main St',
          city: 'Boston',
        },
      },
    },
  },

  updateCity: (city) => set((state) => ({
    data: {
      ...state.data,
      user: {
        ...state.data.user,
        profile: {
          ...state.data.user.profile,
          address: {
            ...state.data.user.profile.address,
            city,
          },
        },
      },
    },
  })),
}))
```

**Problem:** Deep nesting requires verbose spreading.

**Solution:** Use Immer middleware (see [06-MIDDLEWARE.md](./06-MIDDLEWARE.md))

---

## Array Operations

### Adding Items

```typescript
const useListStore = create((set) => ({
  items: [],

  // Add to end
  addItem: (item) => set((state) => ({
    items: [...state.items, item]
  })),

  // Add to beginning
  prepend: (item) => set((state) => ({
    items: [item, ...state.items]
  })),

  // Add at specific index
  insertAt: (index, item) => set((state) => ({
    items: [
      ...state.items.slice(0, index),
      item,
      ...state.items.slice(index)
    ]
  })),

  // Add multiple items
  addMany: (newItems) => set((state) => ({
    items: [...state.items, ...newItems]
  })),
}))
```

### Removing Items

```typescript
const useListStore = create((set) => ({
  items: [],

  // Remove by index
  removeAt: (index) => set((state) => ({
    items: state.items.filter((_, i) => i !== index)
  })),

  // Remove by value
  removeItem: (item) => set((state) => ({
    items: state.items.filter(i => i !== item)
  })),

  // Remove by ID
  removeById: (id) => set((state) => ({
    items: state.items.filter(i => i.id !== id)
  })),

  // Remove first item
  removeFirst: () => set((state) => ({
    items: state.items.slice(1)
  })),

  // Remove last item
  removeLast: () => set((state) => ({
    items: state.items.slice(0, -1)
  })),

  // Clear all
  clear: () => set({ items: [] }),
}))
```

### Updating Items

```typescript
const useTaskStore = create((set) => ({
  tasks: [],

  // Update specific item
  updateTask: (id, updates) => set((state) => ({
    tasks: state.tasks.map(task =>
      task.id === id ? { ...task, ...updates } : task
    )
  })),

  // Toggle boolean property
  toggleComplete: (id) => set((state) => ({
    tasks: state.tasks.map(task =>
      task.id === id ? { ...task, completed: !task.completed } : task
    )
  })),

  // Replace entire item
  replaceTask: (id, newTask) => set((state) => ({
    tasks: state.tasks.map(task =>
      task.id === id ? newTask : task
    )
  })),
}))
```

### Sorting and Filtering

```typescript
const useDataStore = create((set) => ({
  items: [],

  // Sort items
  sortByName: () => set((state) => ({
    items: [...state.items].sort((a, b) => a.name.localeCompare(b.name))
  })),

  // Filter items (non-destructive)
  // Note: Filtering should usually happen in selectors, not state
  filterCompleted: () => set((state) => ({
    items: state.items.filter(item => item.completed)
  })),

  // Reverse array
  reverse: () => set((state) => ({
    items: [...state.items].reverse()
  })),
}))
```

---

## Batching Updates

### Multiple set Calls

```typescript
const useStore = create((set) => ({
  count: 0,
  loading: false,

  // Multiple set calls happen synchronously
  increment: () => {
    set({ loading: true })
    set((state) => ({ count: state.count + 1 }))
    set({ loading: false })
  },

  // Better: Single set call
  incrementBetter: () => set((state) => ({
    loading: false,
    count: state.count + 1,
  })),
}))
```

**Best Practice:** Combine related updates into a single `set` call.

### Complex Multi-Step Updates

```typescript
const useFormStore = create((set, get) => ({
  formData: {},
  errors: {},
  isValid: false,
  isSubmitting: false,

  updateField: (field, value) => set((state) => {
    const newFormData = { ...state.formData, [field]: value }
    const newErrors = validateForm(newFormData)
    const isValid = Object.keys(newErrors).length === 0

    return {
      formData: newFormData,
      errors: newErrors,
      isValid,
    }
  }),
}))
```

---

## Using the get Function

### Accessing Current State in Actions

```typescript
const useStore = create((set, get) => ({
  count: 0,
  multiplier: 2,

  // Use get() to read current state
  incrementByMultiplier: () => {
    const { count, multiplier } = get()
    set({ count: count + multiplier })
  },

  // Can also use set with function form
  incrementByMultiplierAlt: () => set((state) => ({
    count: state.count + state.multiplier
  })),
}))
```

### When to Use get vs set Function Form

```typescript
const useCartStore = create((set, get) => ({
  items: [],
  total: 0,

  // ✅ Good - Use set function form for simple updates
  addItem: (item) => set((state) => ({
    items: [...state.items, item]
  })),

  // ✅ Good - Use get() for complex logic
  checkout: async () => {
    const { items, total } = get()

    if (items.length === 0) {
      throw new Error('Cart is empty')
    }

    set({ isCheckingOut: true })

    try {
      await processPayment(total)
      set({ items: [], total: 0, isCheckingOut: false })
    } catch (error) {
      set({ isCheckingOut: false, error: error.message })
    }
  },
}))
```

**Rule of Thumb:**
- **set function form**: For updates that depend on previous state
- **get()**: For complex logic, conditionals, or accessing state outside `set`

---

## Best Practices

### 1. Always Return New References

```typescript
// ❌ Bad - Reuses same array reference
const badUpdate = () => set((state) => {
  const items = state.items
  items.push(newItem) // Mutation!
  return { items }
})

// ✅ Good - Creates new array reference
const goodUpdate = () => set((state) => ({
  items: [...state.items, newItem]
}))
```

### 2. Avoid Nested Mutations

```typescript
// ❌ Bad - Nested mutation
const bad = () => set((state) => {
  state.user.name = 'New Name' // Mutation!
  return { user: state.user }
})

// ✅ Good - Spread all levels
const good = () => set((state) => ({
  user: { ...state.user, name: 'New Name' }
}))
```

### 3. Keep Actions Focused

```typescript
// ❌ Bad - Does too much
const updateEverything = (data) => set({
  user: data.user,
  posts: data.posts,
  comments: data.comments,
  likes: data.likes,
})

// ✅ Good - Separate concerns
const updateUser = (user) => set({ user })
const updatePosts = (posts) => set({ posts })
const updateComments = (comments) => set({ comments })
```

### 4. Use Descriptive Action Names

```typescript
// ❌ Bad - Vague names
const update = (data) => set(data)
const change = (key, value) => set({ [key]: value })

// ✅ Good - Clear intent
const updateUserProfile = (profile) => set({ userProfile: profile })
const setAuthToken = (token) => set({ authToken: token })
```

### 5. Validate Before Updating

```typescript
const useValidatedStore = create((set) => ({
  email: '',

  setEmail: (email) => {
    if (!email.includes('@')) {
      console.error('Invalid email')
      return
    }
    set({ email })
  },
}))
```

---

## Common Pitfalls

### Pitfall 1: Forgetting to Spread Arrays

```typescript
// ❌ Wrong - Mutates array
const bad = () => set((state) => {
  state.items.push(newItem)
  return { items: state.items }
})

// ✅ Correct - Creates new array
const good = () => set((state) => ({
  items: [...state.items, newItem]
}))
```

### Pitfall 2: Shallow Merge Surprise

```typescript
const useStore = create((set) => ({
  user: { name: 'Alice', email: 'alice@example.com' },

  // ❌ Loses email!
  updateName: (name) => set({ user: { name } }),

  // ✅ Preserves email
  updateName: (name) => set((state) => ({
    user: { ...state.user, name }
  })),
}))
```

### Pitfall 3: Asynchronous Updates

```typescript
const useStore = create((set) => ({
  data: null,

  // ❌ Closure captures stale state
  fetchDataBad: async () => {
    const { userId } = useStore.getState()
    const data = await api.fetch(userId)
    // userId might be stale!
    set({ data })
  },

  // ✅ Get fresh state when needed
  fetchDataGood: async () => {
    const data = await api.fetch()
    const { userId } = useStore.getState() // Fresh state
    set({ data: { ...data, userId } })
  },
}))
```

---

## AI Pair Programming Notes

**When to load this file:**
- Debugging state update issues
- Learning immutable update patterns
- Updating nested objects or arrays
- Understanding set vs get usage

**Typical questions:**
- "Why isn't my state updating?"
- "How do I update a nested object?"
- "What's the difference between set and get?"
- "How do I update an array immutably?"

**Next steps:**
- [04-SELECTORS.md](./04-SELECTORS.md) - Consuming state efficiently
- [06-MIDDLEWARE.md](./06-MIDDLEWARE.md) - Immer for easier nested updates
- [09-ADVANCED-PATTERNS.md](./09-ADVANCED-PATTERNS.md) - Complex update patterns
