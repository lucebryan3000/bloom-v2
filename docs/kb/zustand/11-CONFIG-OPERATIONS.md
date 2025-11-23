---
id: zustand-11-config-operations
topic: zustand
file_role: practical
profile: full
difficulty_level: advanced
kb_version: 3.1
prerequisites: [zustand-fundamentals, zustand-middleware, zustand-advanced-patterns]
related_topics: [production, deployment, operations, configuration]
embedding_keywords: [zustand, production, configuration, operations, deployment, SSR, hydration]
last_reviewed: 2025-11-16
---

# Zustand - Configuration and Operations

## Purpose

Production-ready configuration, operational patterns, deployment strategies, server-side rendering (SSR), hydration, error handling, and monitoring for Zustand applications.

## Table of Contents

1. [Production Configuration](#production-configuration)
2. [Server-Side Rendering (SSR)](#server-side-rendering-ssr)
3. [Hydration Strategies](#hydration-strategies)
4. [Error Handling](#error-handling)
5. [Monitoring and Observability](#monitoring-and-observability)
6. [Migration Strategies](#migration-strategies)
7. [Deployment Best Practices](#deployment-best-practices)
8. [Troubleshooting](#troubleshooting)

---

## Production Configuration

### Environment-Specific Configuration

```typescript
interface AppConfig {
  apiUrl: string
  enableDevTools: boolean
  logLevel: 'debug' | 'info' | 'warn' | 'error'
  persistenceKey: string
}

const getConfig = (): AppConfig => {
  const isDev = process.env.NODE_ENV === 'development'
  const isTest = process.env.NODE_ENV === 'test'

  return {
    apiUrl: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000',
    enableDevTools: isDev,
    logLevel: isDev ? 'debug' : isTest ? 'warn' : 'error',
    persistenceKey: `app-store-${process.env.NEXT_PUBLIC_VERSION || 'v1'}`,
  }
}

const config = getConfig()

export const useAppStore = create<AppState>()(
  devtools(
    persist(
      (set) => ({ /* ... */ }),
      {
        name: config.persistenceKey,
      }
    ),
    { enabled: config.enableDevTools }
  )
)
```

### Feature Flags

```typescript
interface FeatureFlags {
  enableBetaFeatures: boolean
  enableAnalytics: boolean
  enableCaching: boolean
  maxCacheSize: number
}

const useFeatureFlagsStore = create<FeatureFlags>(() => ({
  enableBetaFeatures: process.env.NEXT_PUBLIC_BETA_FEATURES === 'true',
  enableAnalytics: process.env.NEXT_PUBLIC_ANALYTICS === 'true',
  enableCaching: true,
  maxCacheSize: parseInt(process.env.NEXT_PUBLIC_MAX_CACHE_SIZE || '1000'),
}))

// Usage in components
function BetaFeature() {
  const betaEnabled = useFeatureFlagsStore((state) => state.enableBetaFeatures)

  if (!betaEnabled) return null

  return <NewFeatureComponent />
}
```

### Store Initialization

```typescript
// Initialize store with server data
export const initializeStore = (initialData?: Partial<AppState>) => {
  const useStore = create<AppState>((set) => ({
    // Default state
    user: null,
    isLoading: false,

    // Override with server data
    ...initialData,

    // Actions
    setUser: (user) => set({ user }),
  }))

  return useStore
}

// In Next.js App Router
export default function Layout({ children }: { children: React.ReactNode }) {
  const store = useMemo(() => initializeStore({
    user: getServerUser(), // Server-side data
  }), [])

  return <StoreProvider store={store}>{children}</StoreProvider>
}
```

---

## Server-Side Rendering (SSR)

### Next.js App Router

```typescript
// app/providers.tsx
'use client'

import { createContext, useContext, useRef } from 'react'
import { createStore, StoreApi } from 'zustand/vanilla'

interface AppState {
  count: number
  increment: () => void
}

const createAppStore = (initialState?: Partial<AppState>) => {
  return createStore<AppState>((set) => ({
    count: initialState?.count || 0,
    increment: () => set((state) => ({ count: state.count + 1 })),
  }))
}

type AppStore = ReturnType<typeof createAppStore>

const AppStoreContext = createContext<AppStore | null>(null)

export function AppStoreProvider({
  children,
  initialState,
}: {
  children: React.ReactNode
  initialState?: Partial<AppState>
}) {
  const storeRef = useRef<AppStore>()

  if (!storeRef.current) {
    storeRef.current = createAppStore(initialState)
  }

  return (
    <AppStoreContext.Provider value={storeRef.current}>
      {children}
    </AppStoreContext.Provider>
  )
}

export function useAppStore<T>(selector: (state: AppState) => T): T {
  const store = useContext(AppStoreContext)
  if (!store) throw new Error('Missing AppStoreProvider')

  const [state, setState] = useState(() => selector(store.getState()))

  useEffect(() => {
    return store.subscribe((newState) => {
      setState(selector(newState))
    })
  }, [store, selector])

  return state
}
```

### Next.js Pages Router

```typescript
// pages/_app.tsx
import { createStore } from 'zustand/vanilla'
import { useStore } from 'zustand'

let store: ReturnType<typeof createAppStore>

function createAppStore(initialState?: Partial<AppState>) {
  return createStore<AppState>((set) => ({
    count: initialState?.count || 0,
    increment: () => set((state) => ({ count: state.count + 1 })),
  }))
}

function useAppStore<T>(selector: (state: AppState) => T): T {
  if (!store) {
    store = createAppStore()
  }
  return useStore(store, selector)
}

export default function App({ Component, pageProps }: AppProps) {
  // Reset store on client navigation
  useEffect(() => {
    if (pageProps.initialStoreState) {
      store = createAppStore(pageProps.initialStoreState)
    }
  }, [pageProps.initialStoreState])

  return <Component {...pageProps} />
}

// In page with SSR
export async function getServerSideProps() {
  const initialStoreState = {
    count: 42, // Server-fetched data
  }

  return {
    props: { initialStoreState },
  }
}
```

### Remix

```typescript
// app/root.tsx
import { createStore } from 'zustand/vanilla'
import { useLoaderData } from '@remix-run/react'

export async function loader() {
  return {
    initialState: {
      count: 100,
    },
  }
}

export default function App() {
  const { initialState } = useLoaderData<typeof loader>()

  const storeRef = useRef(createStore<AppState>((set) => ({
    ...initialState,
    increment: () => set((state) => ({ count: state.count + 1 })),
  })))

  return (
    <StoreProvider store={storeRef.current}>
      <Outlet />
    </StoreProvider>
  )
}
```

---

## Hydration Strategies

### Client-Side Hydration

```typescript
import { persist, createJSONStorage } from 'zustand/middleware'

const useStore = create(
  persist(
    (set) => ({
      user: null,
      theme: 'light',
      setUser: (user) => set({ user }),
      setTheme: (theme) => set({ theme }),
    }),
    {
      name: 'app-storage',
      storage: createJSONStorage(() => localStorage),

      // Partial hydration - only restore specific keys
      partialize: (state) => ({
        theme: state.theme,
        // Don't persist user (security)
      }),

      // Migration for schema changes
      version: 2,
      migrate: (persistedState: any, version: number) => {
        if (version === 0) {
          // Migrate from v0 to v1
          persistedState.theme = persistedState.darkMode ? 'dark' : 'light'
          delete persistedState.darkMode
        }
        if (version === 1) {
          // Migrate from v1 to v2
          persistedState.theme = persistedState.theme || 'light'
        }
        return persistedState as State
      },
    }
  )
)
```

### Prevent Hydration Mismatch

```typescript
import { useEffect, useState } from 'react'

const useHydration = () => {
  const [hydrated, setHydrated] = useState(false)

  useEffect(() => {
    setHydrated(true)
  }, [])

  return hydrated
}

function ThemeToggle() {
  const hydrated = useHydration()
  const theme = useStore((state) => state.theme)

  // Prevent hydration mismatch
  if (!hydrated) {
    return <div>Loading...</div>
  }

  return <button>{theme}</button>
}
```

### Lazy Hydration

```typescript
const useStore = create(
  persist(
    (set) => ({ /* ... */ }),
    {
      name: 'app-storage',

      // Skip hydration on initial load
      skipHydration: true,
    }
  )
)

// Manually trigger hydration when ready
function App() {
  useEffect(() => {
    useStore.persist.rehydrate()
  }, [])

  return <Dashboard />
}
```

---

## Error Handling

### Store-Level Error Boundaries

```typescript
const useStore = create<State>((set) => ({
  data: null,
  error: null,
  isLoading: false,

  fetchData: async () => {
    set({ isLoading: true, error: null })

    try {
      const data = await api.getData()
      set({ data, isLoading: false })
    } catch (error) {
      set({
        error: error instanceof Error ? error.message : 'Unknown error',
        isLoading: false,
      })

      // Log to monitoring service
      if (typeof window !== 'undefined') {
        console.error('Store error:', error)
        // Sentry.captureException(error)
      }
    }
  },

  clearError: () => set({ error: null }),
}))
```

### React Error Boundaries

```typescript
import { Component, ReactNode } from 'react'

interface ErrorBoundaryProps {
  children: ReactNode
  fallback?: ReactNode
}

interface ErrorBoundaryState {
  hasError: boolean
  error: Error | null
}

class StoreErrorBoundary extends Component<ErrorBoundaryProps, ErrorBoundaryState> {
  constructor(props: ErrorBoundaryProps) {
    super(props)
    this.state = { hasError: false, error: null }
  }

  static getDerivedStateFromError(error: Error) {
    return { hasError: true, error }
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    console.error('Store error caught:', error, errorInfo)
    // Log to monitoring service
  }

  render() {
    if (this.state.hasError) {
      return this.props.fallback || (
        <div>
          <h2>Something went wrong</h2>
          <button onClick={() => this.setState({ hasError: false, error: null })}>
            Retry
          </button>
        </div>
      )
    }

    return this.props.children
  }
}

// Usage
function App() {
  return (
    <StoreErrorBoundary>
      <Dashboard />
    </StoreErrorBoundary>
  )
}
```

### Retry Logic

```typescript
const createRetryableAction = <T,>(
  fn: () => Promise<T>,
  maxRetries = 3,
  delay = 1000
) => {
  let retries = 0

  const execute = async (): Promise<T> => {
    try {
      return await fn()
    } catch (error) {
      if (retries < maxRetries) {
        retries++
        await new Promise(resolve => setTimeout(resolve, delay * retries))
        return execute()
      }
      throw error
    }
  }

  return execute
}

const useStore = create((set) => ({
  fetchData: async () => {
    const retryableFetch = createRetryableAction(() => api.getData())

    try {
      const data = await retryableFetch()
      set({ data })
    } catch (error) {
      set({ error: 'Failed after 3 retries' })
    }
  },
}))
```

---

## Monitoring and Observability

### Action Logging

```typescript
const actionLogger = (config) => (set, get, api) =>
  config(
    (args) => {
      console.log('  applying', args)
      set(args)
      console.log('  new state', get())
    },
    get,
    api
  )

const useStore = create(
  actionLogger((set) => ({
    count: 0,
    increment: () => set((state) => ({ count: state.count + 1 })),
  }))
)
```

### Performance Monitoring

```typescript
const performanceMonitor = (config) => (set, get, api) => {
  const performanceSet = (args) => {
    const start = performance.now()
    set(args)
    const duration = performance.now() - start

    if (duration > 16) { // > 1 frame at 60fps
      console.warn(`Slow state update: ${duration.toFixed(2)}ms`)
    }
  }

  return config(performanceSet, get, api)
}

const useStore = create(
  performanceMonitor((set) => ({ /* ... */ }))
)
```

### Analytics Integration

```typescript
const analyticsMiddleware = (config) => (set, get, api) => {
  return config(
    (args) => {
      const prevState = get()
      set(args)
      const nextState = get()

      // Track state changes
      if (typeof window !== 'undefined' && window.gtag) {
        window.gtag('event', 'state_change', {
          event_category: 'store',
          event_label: JSON.stringify(args),
        })
      }
    },
    get,
    api
  )
}
```

### Health Checks

```typescript
const useHealthStore = create((set, get) => ({
  checks: {
    database: 'unknown',
    api: 'unknown',
    cache: 'unknown',
  },

  runHealthChecks: async () => {
    const results = await Promise.allSettled([
      checkDatabase(),
      checkAPI(),
      checkCache(),
    ])

    set({
      checks: {
        database: results[0].status === 'fulfilled' ? 'healthy' : 'unhealthy',
        api: results[1].status === 'fulfilled' ? 'healthy' : 'unhealthy',
        cache: results[2].status === 'fulfilled' ? 'healthy' : 'unhealthy',
      },
    })
  },
}))

// Run health checks on interval
useEffect(() => {
  useHealthStore.getState().runHealthChecks()
  const interval = setInterval(() => {
    useHealthStore.getState().runHealthChecks()
  }, 60000) // Every minute

  return () => clearInterval(interval)
}, [])
```

---

## Migration Strategies

### Version Migration

```typescript
import { persist } from 'zustand/middleware'

const useStore = create(
  persist(
    (set) => ({
      user: null,
      settings: { theme: 'light' },
    }),
    {
      name: 'app-store',
      version: 3,

      migrate: (persistedState: any, version: number) => {
        // Migrate from v0 to v1
        if (version === 0) {
          persistedState.settings = { theme: 'light' }
        }

        // Migrate from v1 to v2
        if (version <= 1) {
          persistedState.user = null // Clear user data
        }

        // Migrate from v2 to v3
        if (version <= 2) {
          // Rename field
          persistedState.userProfile = persistedState.user
          delete persistedState.user
        }

        return persistedState as State
      },
    }
  )
)
```

### Schema Validation

```typescript
import { z } from 'zod'

const stateSchema = z.object({
  user: z.object({
    id: z.string(),
    name: z.string(),
  }).nullable(),
  theme: z.enum(['light', 'dark']),
})

const useStore = create(
  persist(
    (set) => ({ /* ... */ }),
    {
      name: 'app-store',

      // Validate on hydration
      onRehydrateStorage: () => (state) => {
        try {
          stateSchema.parse(state)
        } catch (error) {
          console.error('Invalid persisted state:', error)
          // Reset to defaults
          return {
            user: null,
            theme: 'light',
          }
        }
      },
    }
  )
)
```

---

## Deployment Best Practices

### Production Checklist

```typescript
// ✅ Disable devtools in production
const useStore = create(
  devtools(
    (set) => ({ /* ... */ }),
    { enabled: process.env.NODE_ENV === 'development' }
  )
)

// ✅ Set appropriate storage keys with versioning
const useStore = create(
  persist(
    (set) => ({ /* ... */ }),
    {
      name: `app-store-${process.env.NEXT_PUBLIC_VERSION}`,
    }
  )
)

// ✅ Implement error boundaries
// ✅ Add performance monitoring
// ✅ Validate persisted state
// ✅ Handle hydration correctly for SSR
// ✅ Clear sensitive data from localStorage
// ✅ Implement proper logging
```

### Build-Time Validation

```typescript
// scripts/validate-stores.ts
import { useAuthStore } from '@/stores/auth'
import { useCartStore } from '@/stores/cart'

const validateStores = () => {
  const stores = [useAuthStore, useCartStore]

  stores.forEach((store) => {
    const state = store.getState()

    // Check for required methods
    if (!state.reset || typeof state.reset !== 'function') {
      throw new Error(`Store missing reset method`)
    }

    console.log('✅ Store validation passed')
  })
}

if (process.env.NODE_ENV === 'production') {
  validateStores()
}
```

---

## Troubleshooting

### Common Issues

#### Issue 1: Hydration Mismatch

```typescript
// ❌ Problem: SSR/CSR mismatch
function Component() {
  const theme = useStore((state) => state.theme)
  return <div>{theme}</div> // "light" on server, "dark" on client
}

// ✅ Solution: Wait for hydration
function Component() {
  const [hydrated, setHydrated] = useState(false)
  const theme = useStore((state) => state.theme)

  useEffect(() => setHydrated(true), [])

  if (!hydrated) return <div>light</div> // Default

  return <div>{theme}</div>
}
```

#### Issue 2: Memory Leaks

```typescript
// ❌ Problem: Subscription not cleaned up
useEffect(() => {
  useStore.subscribe((state) => {
    console.log(state)
  })
}, []) // Missing cleanup!

// ✅ Solution: Return unsubscribe function
useEffect(() => {
  const unsubscribe = useStore.subscribe((state) => {
    console.log(state)
  })

  return unsubscribe
}, [])
```

#### Issue 3: Stale Closures

```typescript
// ❌ Problem: Closure captures stale state
const useStore = create((set) => ({
  count: 0,
  incrementLater: () => {
    setTimeout(() => {
      const { count } = useStore.getState()
      set({ count: count + 1 }) // Gets fresh state
    }, 1000)
  },
}))
```

### Debugging Tools

```typescript
// Enable verbose logging
const logMiddleware = (config) => (set, get, api) => {
  return config(
    (args) => {
      console.group('🔧 State Update')
      console.log('Previous:', get())
      console.log('Update:', args)
      set(args)
      console.log('Next:', get())
      console.groupEnd()
    },
    get,
    api
  )
}

// Development-only store wrapper
const useDevStore = create(
  process.env.NODE_ENV === 'development'
    ? logMiddleware(devtools((set) => ({ /* ... */ })))
    : (set) => ({ /* ... */ })
)
```

---

## Best Practices Summary

### DO:
- ✅ Use environment-specific configuration
- ✅ Implement proper SSR/hydration
- ✅ Add error boundaries and retry logic
- ✅ Monitor performance and errors
- ✅ Validate persisted state
- ✅ Version your stores for migrations
- ✅ Disable devtools in production
- ✅ Clear sensitive data from storage

### DON'T:
- ❌ Persist sensitive data (passwords, tokens)
- ❌ Enable devtools in production
- ❌ Forget to handle hydration mismatches
- ❌ Skip error handling in async actions
- ❌ Ignore performance monitoring
- ❌ Hard-code configuration values
- ❌ Deploy without validation

---

## AI Pair Programming Notes

**When to load this file:**
- Setting up production deployment
- Configuring SSR/hydration
- Implementing error handling
- Adding monitoring and observability
- Troubleshooting issues

**Typical questions:**
- "How do I set up Zustand with Next.js SSR?"
- "How do I handle hydration errors?"
- "How do I monitor store performance?"
- "How do I migrate store schemas?"

**Next steps:**
- [01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md) - Review core concepts
- [06-MIDDLEWARE.md](./06-MIDDLEWARE.md) - Persist and devtools middleware
- [10-PERFORMANCE.md](./10-PERFORMANCE.md) - Performance optimization
