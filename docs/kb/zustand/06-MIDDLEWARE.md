---
id: zustand-06-middleware
topic: zustand
file_role: practical
profile: full
difficulty_level: intermediate-to-advanced
kb_version: 3.1
prerequisites: [zustand-fundamentals, zustand-store-creation]
related_topics: [persistence, debugging, immutability]
embedding_keywords: [zustand, middleware, persist, immer, devtools, localStorage, sessionStorage]
last_reviewed: 2025-11-16
---

# Zustand - Middleware

## Purpose

Learn how to use Zustand's built-in middleware to add persistence, immutable updates, debugging tools, and selective subscriptions to your stores.

## Table of Contents

1. [Persist Middleware](#persist-middleware)
2. [Immer Middleware](#immer-middleware)
3. [DevTools Middleware](#devtools-middleware)
4. [SubscribeWithSelector](#subscribewithselector)
5. [Combining Middleware](#combining-middleware)
6. [Custom Middleware](#custom-middleware)

---

## Persist Middleware

### Basic Usage (localStorage)

```typescript
import { create } from 'zustand'
import { persist } from 'zustand/middleware'

const useStore = create(
  persist(
    (set) => ({
      count: 0,
      increment: () => set((state) => ({ count: state.count + 1 })),
    }),
    {
      name: 'counter-storage', // unique storage key
    }
  )
)
```

**Key Points:**
- Automatically saves state to localStorage
- State persists across page reloads
- Hydrates store on initialization

### SessionStorage

```typescript
import { createJSONStorage } from 'zustand/middleware'

const useSessionStore = create(
  persist(
    (set) => ({ /* ... */ }),
    {
      name: 'session-storage',
      storage: createJSONStorage(() => sessionStorage),
    }
  )
)
```

### Partial Persistence (Whitelist)

```typescript
const useStore = create(
  persist(
    (set) => ({
      user: null,
      token: null,
      theme: 'dark',
      tempData: null, // Won't be persisted
    }),
    {
      name: 'app-storage',
      partialize: (state) => ({
        user: state.user,
        token: state.token,
        theme: state.theme,
        // tempData omitted
      }),
    }
  )
)
```

### Custom Storage

```typescript
import { StateStorage } from 'zustand/middleware'

// Cookie storage example
const cookieStorage: StateStorage = {
  getItem: (name) => {
    const cookies = document.cookie.split('; ')
    const cookie = cookies.find(c => c.startsWith(`${name}=`))
    return cookie ? cookie.split('=')[1] : null
  },
  setItem: (name, value) => {
    document.cookie = `${name}=${value}; path=/; max-age=31536000`
  },
  removeItem: (name) => {
    document.cookie = `${name}=; path=/; max-age=0`
  },
}

const useCookieStore = create(
  persist(
    (set) => ({ /* ... */ }),
    {
      name: 'cookie-storage',
      storage: cookieStorage,
    }
  )
)
```

### Migration Between Versions

```typescript
const useStore = create(
  persist(
    (set) => ({
      version: 2,
      data: null,
    }),
    {
      name: 'app-storage',
      version: 2,
      migrate: (persistedState: any, version) => {
        if (version === 1) {
          // Migrate from v1 to v2
          return {
            ...persistedState,
            version: 2,
            data: transformDataFromV1(persistedState.data),
          }
        }
        return persistedState
      },
    }
  )
)
```

### Rehydration Events

```typescript
const useStore = create(
  persist(
    (set) => ({ /* ... */ }),
    {
      name: 'app-storage',
      onRehydrateStorage: () => {
        console.log('Hydration starts')

        return (state, error) => {
          if (error) {
            console.log('Hydration error:', error)
          } else {
            console.log('Hydration finished')
          }
        }
      },
    }
  )
)
```

### TypeScript with Persist

```typescript
interface BearState {
  bears: number
  addBear: () => void
}

const useBearStore = create<BearState>()(
  persist(
    (set) => ({
      bears: 0,
      addBear: () => set((state) => ({ bears: state.bears + 1 })),
    }),
    {
      name: 'bear-storage',
    }
  )
)
```

**Note:** The extra `()` is required for TypeScript type inference to work properly.

---

## Immer Middleware

### Enable Mutable Updates

```typescript
import { immer } from 'zustand/middleware/immer'

const useStore = create(
  immer((set) => ({
    nested: {
      deep: {
        count: 0
      }
    },
    increment: () => set((state) => {
      state.nested.deep.count++ // Mutation is OK with Immer!
    }),
  }))
)
```

### Before and After Immer

```typescript
// ❌ Without Immer - Verbose spreading
const withoutImmer = create((set) => ({
  user: {
    profile: {
      settings: {
        theme: 'dark'
      }
    }
  },
  updateTheme: (theme) => set((state) => ({
    user: {
      ...state.user,
      profile: {
        ...state.user.profile,
        settings: {
          ...state.user.profile.settings,
          theme
        }
      }
    }
  })),
}))

// ✅ With Immer - Direct mutation
const withImmer = create(
  immer((set) => ({
    user: {
      profile: {
        settings: {
          theme: 'dark'
        }
      }
    },
    updateTheme: (theme) => set((state) => {
      state.user.profile.settings.theme = theme
    }),
  }))
)
```

### Array Operations with Immer

```typescript
const useListStore = create(
  immer((set) => ({
    items: [],

    // Push items (mutation)
    addItem: (item) => set((state) => {
      state.items.push(item)
    }),

    // Remove item (mutation)
    removeItem: (id) => set((state) => {
      const index = state.items.findIndex(i => i.id === id)
      if (index !== -1) {
        state.items.splice(index, 1)
      }
    }),

    // Update item (mutation)
    updateItem: (id, updates) => set((state) => {
      const item = state.items.find(i => i.id === id)
      if (item) {
        Object.assign(item, updates)
      }
    }),
  }))
)
```

---

## DevTools Middleware

### Basic DevTools Integration

```typescript
import { devtools } from 'zustand/middleware'

const useStore = create(
  devtools((set) => ({
    count: 0,
    increment: () => set((state) => ({ count: state.count + 1 })),
  }))
)
```

Open Redux DevTools extension to see:
- State changes
- Time-travel debugging
- Action names

### Named Actions

```typescript
const useStore = create(
  devtools(
    (set) => ({
      count: 0,
      increment: () => set(
        (state) => ({ count: state.count + 1 }),
        false,
        'increment' // Action name in DevTools
      ),
      decrement: () => set(
        (state) => ({ count: state.count - 1 }),
        false,
        'decrement'
      ),
    }),
    { name: 'CounterStore' } // Store name in DevTools
  )
)
```

### Disable in Production

```typescript
const useStore = create(
  devtools(
    (set) => ({ /* ... */ }),
    { enabled: process.env.NODE_ENV === 'development' }
  )
)
```

---

## SubscribeWithSelector

### Enable Selective Subscriptions

```typescript
import { subscribeWithSelector } from 'zustand/middleware'

const useDogStore = create(
  subscribeWithSelector((set) => ({
    paw: true,
    snout: true,
    fur: true,
    setPaw: (paw) => set({ paw }),
  }))
)
```

### Subscribe to Specific State

```typescript
// Subscribe to paw changes only
const unsub = useDogStore.subscribe(
  (state) => state.paw,
  (paw) => console.log('Paw changed:', paw)
)

// Cleanup
unsub()
```

### Subscribe with Equality Function

```typescript
import { shallow } from 'zustand/shallow'

const unsub = useDogStore.subscribe(
  (state) => [state.paw, state.fur],
  (values) => console.log('Paw or fur changed:', values),
  { equalityFn: shallow }
)
```

### Fire Immediately

```typescript
const unsub = useDogStore.subscribe(
  (state) => state.paw,
  (paw) => console.log('Current paw:', paw),
  { fireImmediately: true } // Fires with current value
)
```

---

## Combining Middleware

### Order Matters

```typescript
// ✅ Correct order: devtools -> persist -> immer
const useStore = create(
  devtools(
    persist(
      immer((set) => ({
        count: 0,
        nested: { value: 0 },
        increment: () => set((state) => {
          state.count++
        }),
      })),
      { name: 'storage' }
    ),
    { name: 'Store' }
  )
)
```

**Recommended order:**
1. **devtools** (outermost) - Tracks all state changes
2. **persist** - Saves state to storage
3. **immer** (innermost) - Enables mutable updates

### TypeScript with Multiple Middleware

```typescript
interface State {
  count: number
  increment: () => void
}

const useStore = create<State>()(
  devtools(
    persist(
      immer((set) => ({
        count: 0,
        increment: () => set((state) => {
          state.count++
        }),
      })),
      { name: 'counter' }
    )
  )
)
```

### Selective Middleware Application

```typescript
const useStore = create<State>()(
  // DevTools only in development
  process.env.NODE_ENV === 'development'
    ? devtools(
        persist(
          immer(storeImplementation),
          { name: 'storage' }
        )
      )
    : persist(
        immer(storeImplementation),
        { name: 'storage' }
      )
)
```

---

## Custom Middleware

### Middleware Signature

```typescript
type Middleware = (config) => (set, get, api) => config
```

### Logger Middleware

```typescript
const logger = (config) => (set, get, api) =>
  config(
    (...args) => {
      console.log('Previous state:', get())
      set(...args)
      console.log('New state:', get())
    },
    get,
    api
  )

const useStore = create(
  logger((set) => ({
    count: 0,
    increment: () => set((state) => ({ count: state.count + 1 })),
  }))
)
```

### Action Logger

```typescript
const actionLogger = (config) => (set, get, api) =>
  config(
    (partial, replace, actionName) => {
      console.log('Action:', actionName || 'anonymous', { partial, replace })
      set(partial, replace, actionName)
    },
    get,
    api
  )
```

### Reset Middleware

```typescript
const resetters = new Set()

const reset = (config) => (set, get, api) => {
  resetters.add(() => set(config(set, get, api)))
  return config(
    (args) => {
      set(args)
    },
    get,
    api
  )
}

// Reset all stores
export const resetAllStores = () => {
  resetters.forEach((resetter) => resetter())
}

const useStore = create(
  reset((set) => ({
    count: 0,
    increment: () => set((state) => ({ count: state.count + 1 })),
  }))
)
```

### TypeScript Custom Middleware

```typescript
import { StateCreator, StoreMutatorIdentifier } from 'zustand'

type Logger = <
  T,
  Mps extends [StoreMutatorIdentifier, unknown][] = [],
  Mcs extends [StoreMutatorIdentifier, unknown][] = []
>(
  config: StateCreator<T, Mps, Mcs>
) => StateCreator<T, Mps, Mcs>

type LoggerImpl = <T>(config: StateCreator<T>) => StateCreator<T>

const loggerImpl: LoggerImpl = (config) => (set, get, api) =>
  config(
    (...args) => {
      console.log('Applying:', args)
      set(...args)
      console.log('New state:', get())
    },
    get,
    api
  )

export const logger = loggerImpl as Logger
```

---

## Best Practices

### 1. Use Persist for User Preferences

```typescript
const usePreferencesStore = create(
  persist(
    (set) => ({
      theme: 'dark',
      language: 'en',
      setTheme: (theme) => set({ theme }),
      setLanguage: (language) => set({ language }),
    }),
    { name: 'user-preferences' }
  )
)
```

### 2. Use Immer for Complex Nested Updates

```typescript
// ✅ Good use case for Immer
const useComplexStore = create(
  immer((set) => ({
    data: {
      level1: {
        level2: {
          level3: {
            value: 0
          }
        }
      }
    },
    updateDeep: (value) => set((state) => {
      state.data.level1.level2.level3.value = value
    }),
  }))
)
```

### 3. Use DevTools Only in Development

```typescript
const middleware = process.env.NODE_ENV === 'development'
  ? devtools
  : (f) => f

const useStore = create(
  middleware((set) => ({ /* ... */ }))
)
```

### 4. Exclude Sensitive Data from Persistence

```typescript
const useAuthStore = create(
  persist(
    (set) => ({
      user: null,
      token: null,
      tempSessionData: null,
    }),
    {
      name: 'auth',
      partialize: (state) => ({
        user: state.user,
        // Exclude token and tempSessionData
      }),
    }
  )
)
```

---

## Common Pitfalls

### Pitfall 1: Wrong Middleware Order

```typescript
// ❌ Bad - Immer outside persist
create(
  immer(
    persist(
      (set) => ({ /* ... */ }),
      { name: 'storage' }
    )
  )
)

// ✅ Good - Persist outside immer
create(
  persist(
    immer((set) => ({ /* ... */ })),
    { name: 'storage' }
  )
)
```

### Pitfall 2: Forgetting TypeScript Empty Call

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

### Pitfall 3: Persisting Functions

```typescript
// ❌ Bad - Functions can't be serialized
persist(
  (set) => ({
    data: null,
    callback: () => {}, // Won't persist!
  }),
  { name: 'storage' }
)

// ✅ Good - Only persist data
persist(
  (set) => ({
    data: null,
    callback: () => {},
  }),
  {
    name: 'storage',
    partialize: (state) => ({ data: state.data }),
  }
)
```

---

## AI Pair Programming Notes

**When to load this file:**
- Adding persistence to stores
- Simplifying nested updates
- Debugging state issues
- Creating selective subscriptions

**Typical questions:**
- "How do I persist state across reloads?"
- "How do I update nested objects without spreading?"
- "How do I debug Zustand in DevTools?"
- "Can I subscribe to specific state changes?"

**Next steps:**
- [07-TYPESCRIPT.md](./07-TYPESCRIPT.md) - TypeScript patterns with middleware
- [09-ADVANCED-PATTERNS.md](./09-ADVANCED-PATTERNS.md) - Advanced middleware combinations
- [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) - Production configuration
