---
id: zustand-framework-integration
topic: zustand
file_role: framework
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [zustand-fundamentals, zustand-store-creation]
related_topics: [nextjs, remix, ssr, react]
embedding_keywords: [zustand, nextjs, remix, ssr, framework, integration]
last_reviewed: 2025-11-16
---

# Zustand - Framework Integration Patterns

## Purpose

Comprehensive integration patterns for Zustand with popular React frameworks including Next.js (App Router & Pages Router), Remix, Vite, Create React App, and React Native.

## Table of Contents

1. [Next.js App Router](#nextjs-app-router)
2. [Next.js Pages Router](#nextjs-pages-router)
3. [Remix](#remix)
4. [Vite / Create React App](#vite--create-react-app)
5. [React Native](#react-native)
6. [SSR Best Practices](#ssr-best-practices)
7. [Common Patterns](#common-patterns)

---

## Next.js App Router

### Basic Setup with Context

```typescript
// stores/counterStore.ts
import { createStore } from 'zustand/vanilla'

export interface CounterState {
  count: number
  increment: () => void
  decrement: () => void
}

export const createCounterStore = (initialCount = 0) => {
  return createStore<CounterState>((set) => ({
    count: initialCount,
    increment: () => set((state) => ({ count: state.count + 1 })),
    decrement: () => set((state) => ({ count: state.count - 1 })),
  }))
}

export type CounterStore = ReturnType<typeof createCounterStore>
```

```typescript
// providers/counter-store-provider.tsx
'use client'

import { createContext, useContext, useRef, ReactNode } from 'react'
import { useStore } from 'zustand'
import { createCounterStore, CounterStore, CounterState } from '@/stores/counterStore'

const CounterStoreContext = createContext<CounterStore | null>(null)

export interface CounterStoreProviderProps {
  children: ReactNode
  initialCount?: number
}

export function CounterStoreProvider({ children, initialCount }: CounterStoreProviderProps) {
  const storeRef = useRef<CounterStore>()

  if (!storeRef.current) {
    storeRef.current = createCounterStore(initialCount)
  }

  return (
    <CounterStoreContext.Provider value={storeRef.current}>
      {children}
    </CounterStoreContext.Provider>
  )
}

export function useCounterStore(): CounterState
export function useCounterStore<T>(selector: (state: CounterState) => T): T
export function useCounterStore<T>(selector?: (state: CounterState) => T) {
  const store = useContext(CounterStoreContext)

  if (!store) {
    throw new Error('useCounterStore must be used within CounterStoreProvider')
  }

  return useStore(store, selector!)
}
```

```typescript
// app/layout.tsx
import { CounterStoreProvider } from '@/providers/counter-store-provider'

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <CounterStoreProvider initialCount={0}>
          {children}
        </CounterStoreProvider>
      </body>
    </html>
  )
}
```

```typescript
// app/counter-client.tsx
'use client'

import { useCounterStore } from '@/providers/counter-store-provider'

export function CounterClient() {
  const count = useCounterStore((state) => state.count)
  const increment = useCounterStore((state) => state.increment)
  const decrement = useCounterStore((state) => state.decrement)

  return (
    <div>
      <p>Count: {count}</p>
      <button onClick={increment}>+</button>
      <button onClick={decrement}>-</button>
    </div>
  )
}
```

### Server-Side Data Hydration

```typescript
// app/page.tsx
import { CounterClient } from './counter-client'
import { CounterStoreProvider } from '@/providers/counter-store-provider'

async function getInitialCount() {
  // Fetch from database or API
  const res = await fetch('https://api.example.com/count')
  const data = await res.json()
  return data.count
}

export default async function Page() {
  const initialCount = await getInitialCount()

  return (
    <CounterStoreProvider initialCount={initialCount}>
      <CounterClient />
    </CounterStoreProvider>
  )
}
```

### Multi-Store Setup

```typescript
// providers/app-store-provider.tsx
'use client'

import { createContext, useContext, useRef } from 'react'
import { useStore } from 'zustand'
import { createAuthStore, AuthStore, AuthState } from '@/stores/authStore'
import { createCartStore, CartStore, CartState } from '@/stores/cartStore'

interface AppStoreContextValue {
  authStore: AuthStore
  cartStore: CartStore
}

const AppStoreContext = createContext<AppStoreContextValue | null>(null)

export function AppStoreProvider({
  children,
  initialAuth,
  initialCart,
}: {
  children: React.ReactNode
  initialAuth?: Partial<AuthState>
  initialCart?: Partial<CartState>
}) {
  const storesRef = useRef<AppStoreContextValue>()

  if (!storesRef.current) {
    storesRef.current = {
      authStore: createAuthStore(initialAuth),
      cartStore: createCartStore(initialCart),
    }
  }

  return (
    <AppStoreContext.Provider value={storesRef.current}>
      {children}
    </AppStoreContext.Provider>
  )
}

// Hook for auth store
export function useAuthStore(): AuthState
export function useAuthStore<T>(selector: (state: AuthState) => T): T
export function useAuthStore<T>(selector?: (state: AuthState) => T) {
  const stores = useContext(AppStoreContext)
  if (!stores) throw new Error('useAuthStore must be used within AppStoreProvider')
  return useStore(stores.authStore, selector!)
}

// Hook for cart store
export function useCartStore(): CartState
export function useCartStore<T>(selector: (state: CartState) => T): T
export function useCartStore<T>(selector?: (state: CartState) => T) {
  const stores = useContext(AppStoreContext)
  if (!stores) throw new Error('useCartStore must be used within AppStoreProvider')
  return useStore(stores.cartStore, selector!)
}
```

---

## Next.js Pages Router

### Global Store Pattern

```typescript
// stores/appStore.ts
import { create } from 'zustand'

interface AppState {
  user: User | null
  setUser: (user: User | null) => void
  theme: 'light' | 'dark'
  setTheme: (theme: 'light' | 'dark') => void
}

export const useAppStore = create<AppState>((set) => ({
  user: null,
  setUser: (user) => set({ user }),
  theme: 'light',
  setTheme: (theme) => set({ theme }),
}))
```

```typescript
// pages/_app.tsx
import type { AppProps } from 'next/app'
import { useEffect } from 'react'
import { useAppStore } from '@/stores/appStore'

export default function App({ Component, pageProps }: AppProps) {
  // Hydrate from pageProps if available
  useEffect(() => {
    if (pageProps.initialUser) {
      useAppStore.getState().setUser(pageProps.initialUser)
    }
  }, [pageProps.initialUser])

  return <Component {...pageProps} />
}
```

### SSR with getServerSideProps

```typescript
// pages/dashboard.tsx
import { GetServerSideProps } from 'next'
import { useAppStore } from '@/stores/appStore'
import { useEffect } from 'react'

interface DashboardProps {
  initialUser: User | null
  initialData: Data[]
}

export default function Dashboard({ initialUser, initialData }: DashboardProps) {
  const setUser = useAppStore((state) => state.setUser)

  useEffect(() => {
    if (initialUser) {
      setUser(initialUser)
    }
  }, [initialUser, setUser])

  return <div>Dashboard</div>
}

export const getServerSideProps: GetServerSideProps<DashboardProps> = async (context) => {
  const user = await getUser(context.req)
  const data = await getData(user.id)

  return {
    props: {
      initialUser: user,
      initialData: data,
    },
  }
}
```

### Per-Page Store Initialization

```typescript
// stores/createPageStore.ts
import { create, StoreApi } from 'zustand'

const stores = new Map<string, StoreApi<any>>()

export function createPageStore<T>(key: string, initialState: T) {
  if (!stores.has(key)) {
    stores.set(key, create<T>(() => initialState))
  }

  return stores.get(key) as StoreApi<T>
}

export function resetPageStore(key: string) {
  stores.delete(key)
}
```

```typescript
// pages/products/[id].tsx
import { useEffect } from 'react'
import { useStore } from 'zustand'
import { createPageStore, resetPageStore } from '@/stores/createPageStore'

export default function ProductPage({ product }: { product: Product }) {
  const store = createPageStore('product-page', { product, quantity: 1 })
  const quantity = useStore(store, (state) => state.quantity)

  useEffect(() => {
    return () => resetPageStore('product-page')
  }, [])

  return <div>{product.name} - Quantity: {quantity}</div>
}
```

---

## Remix

### Route-Level Stores

```typescript
// app/stores/todo.store.ts
import { createStore } from 'zustand/vanilla'

export interface TodoState {
  todos: Todo[]
  addTodo: (todo: Todo) => void
  toggleTodo: (id: string) => void
}

export const createTodoStore = (initialTodos: Todo[] = []) => {
  return createStore<TodoState>((set) => ({
    todos: initialTodos,
    addTodo: (todo) => set((state) => ({ todos: [...state.todos, todo] })),
    toggleTodo: (id) => set((state) => ({
      todos: state.todos.map(t =>
        t.id === id ? { ...t, completed: !t.completed } : t
      )
    })),
  }))
}
```

```typescript
// app/routes/todos.tsx
import { json, LoaderFunction } from '@remix-run/node'
import { useLoaderData } from '@remix-run/react'
import { useRef } from 'react'
import { useStore } from 'zustand'
import { createTodoStore } from '@/stores/todo.store'

export const loader: LoaderFunction = async () => {
  const todos = await db.todo.findMany()
  return json({ todos })
}

export default function TodosRoute() {
  const { todos } = useLoaderData<typeof loader>()

  const storeRef = useRef(createTodoStore(todos))
  const todosState = useStore(storeRef.current, (state) => state.todos)
  const addTodo = useStore(storeRef.current, (state) => state.addTodo)

  return (
    <div>
      {todosState.map(todo => (
        <TodoItem key={todo.id} todo={todo} />
      ))}
    </div>
  )
}
```

### Remix Context Provider

```typescript
// app/root.tsx
import { Outlet, useLoaderData } from '@remix-run/react'
import { createContext, useContext, useRef } from 'react'
import { useStore } from 'zustand'
import { createAppStore, AppStore, AppState } from '@/stores/appStore'

const AppStoreContext = createContext<AppStore | null>(null)

export async function loader() {
  return json({
    initialState: {
      user: await getUser(),
      settings: await getSettings(),
    },
  })
}

export default function App() {
  const { initialState } = useLoaderData<typeof loader>()
  const storeRef = useRef<AppStore>()

  if (!storeRef.current) {
    storeRef.current = createAppStore(initialState)
  }

  return (
    <html>
      <body>
        <AppStoreContext.Provider value={storeRef.current}>
          <Outlet />
        </AppStoreContext.Provider>
      </body>
    </html>
  )
}

export function useAppStore(): AppState
export function useAppStore<T>(selector: (state: AppState) => T): T
export function useAppStore<T>(selector?: (state: AppState) => T) {
  const store = useContext(AppStoreContext)
  if (!store) throw new Error('useAppStore must be used within provider')
  return useStore(store, selector!)
}
```

---

## Vite / Create React App

### Simple Global Store

```typescript
// src/stores/appStore.ts
import { create } from 'zustand'
import { devtools, persist } from 'zustand/middleware'

interface AppState {
  user: User | null
  login: (user: User) => void
  logout: () => void
}

export const useAppStore = create<AppState>()(
  devtools(
    persist(
      (set) => ({
        user: null,
        login: (user) => set({ user }),
        logout: () => set({ user: null }),
      }),
      { name: 'app-storage' }
    ),
    { name: 'AppStore' }
  )
)
```

```typescript
// src/App.tsx
import { useAppStore } from './stores/appStore'

function App() {
  const user = useAppStore((state) => state.user)
  const login = useAppStore((state) => state.login)
  const logout = useAppStore((state) => state.logout)

  return (
    <div>
      {user ? (
        <div>
          <p>Welcome, {user.name}</p>
          <button onClick={logout}>Logout</button>
        </div>
      ) : (
        <button onClick={() => login({ id: '1', name: 'Alice' })}>
          Login
        </button>
      )}
    </div>
  )
}
```

### Store with React Router

```typescript
// src/main.tsx
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter } from 'react-router-dom'
import App from './App'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <BrowserRouter>
      <App />
    </BrowserRouter>
  </StrictMode>
)
```

```typescript
// src/stores/routerStore.ts
import { create } from 'zustand'
import { useNavigate, useLocation } from 'react-router-dom'

interface RouterState {
  from: string | null
  setFrom: (path: string | null) => void
}

export const useRouterStore = create<RouterState>((set) => ({
  from: null,
  setFrom: (from) => set({ from }),
}))

// Custom hook combining router and store
export function useAuthenticatedRoute() {
  const navigate = useNavigate()
  const location = useLocation()
  const user = useAppStore((state) => state.user)
  const setFrom = useRouterStore((state) => state.setFrom)

  if (!user) {
    setFrom(location.pathname)
    navigate('/login')
  }
}
```

---

## React Native

### Basic Setup

```typescript
// stores/appStore.ts
import { create } from 'zustand'
import { persist, createJSONStorage } from 'zustand/middleware'
import AsyncStorage from '@react-native-async-storage/async-storage'

interface AppState {
  theme: 'light' | 'dark'
  setTheme: (theme: 'light' | 'dark') => void
  user: User | null
  setUser: (user: User | null) => void
}

export const useAppStore = create<AppState>()(
  persist(
    (set) => ({
      theme: 'light',
      setTheme: (theme) => set({ theme }),
      user: null,
      setUser: (user) => set({ user }),
    }),
    {
      name: 'app-storage',
      storage: createJSONStorage(() => AsyncStorage),
    }
  )
)
```

```typescript
// App.tsx
import { useAppStore } from './stores/appStore'
import { View, Text, Button } from 'react-native'

export default function App() {
  const theme = useAppStore((state) => state.theme)
  const setTheme = useAppStore((state) => state.setTheme)

  return (
    <View style={{ backgroundColor: theme === 'dark' ? '#000' : '#fff' }}>
      <Text>Current theme: {theme}</Text>
      <Button
        title="Toggle Theme"
        onPress={() => setTheme(theme === 'dark' ? 'light' : 'dark')}
      />
    </View>
  )
}
```

### Navigation with React Navigation

```typescript
// stores/navigationStore.ts
import { create } from 'zustand'

interface NavigationState {
  currentRoute: string | null
  setCurrentRoute: (route: string) => void
}

export const useNavigationStore = create<NavigationState>((set) => ({
  currentRoute: null,
  setCurrentRoute: (route) => set({ currentRoute: route }),
}))
```

```typescript
// navigation/RootNavigator.tsx
import { NavigationContainer } from '@react-navigation/native'
import { createNativeStackNavigator } from '@react-navigation/native-stack'
import { useNavigationStore } from '@/stores/navigationStore'

const Stack = createNativeStackNavigator()

export function RootNavigator() {
  const setCurrentRoute = useNavigationStore((state) => state.setCurrentRoute)

  return (
    <NavigationContainer
      onStateChange={(state) => {
        const route = state?.routes[state.index]
        setCurrentRoute(route?.name || null)
      }}
    >
      <Stack.Navigator>
        <Stack.Screen name="Home" component={HomeScreen} />
        <Stack.Screen name="Profile" component={ProfileScreen} />
      </Stack.Navigator>
    </NavigationContainer>
  )
}
```

---

## SSR Best Practices

### Hydration Pattern

```typescript
// hooks/useHydration.ts
import { useEffect, useState } from 'react'

export function useHydration() {
  const [hydrated, setHydrated] = useState(false)

  useEffect(() => {
    setHydrated(true)
  }, [])

  return hydrated
}
```

```typescript
// components/ClientOnly.tsx
import { useHydration } from '@/hooks/useHydration'

export function ClientOnly({
  children,
  fallback = null,
}: {
  children: React.ReactNode
  fallback?: React.ReactNode
}) {
  const hydrated = useHydration()

  return hydrated ? <>{children}</> : <>{fallback}</>
}
```

```typescript
// Usage
import { ClientOnly } from '@/components/ClientOnly'
import { useAppStore } from '@/stores/appStore'

function ThemeToggle() {
  const theme = useAppStore((state) => state.theme)
  const setTheme = useAppStore((state) => state.setTheme)

  return (
    <ClientOnly fallback={<div>Loading theme...</div>}>
      <button onClick={() => setTheme(theme === 'dark' ? 'light' : 'dark')}>
        Current: {theme}
      </button>
    </ClientOnly>
  )
}
```

### Lazy Hydration with Persist

```typescript
import { create } from 'zustand'
import { persist } from 'zustand/middleware'

const useStore = create(
  persist(
    (set) => ({ /* ... */ }),
    {
      name: 'app-storage',
      skipHydration: true, // Skip automatic hydration
    }
  )
)

// Manually trigger hydration when ready
function App() {
  useEffect(() => {
    useStore.persist.rehydrate()
  }, [])

  return <div>App</div>
}
```

---

## Common Patterns

### Store Factory for Testing

```typescript
// test-utils/createMockStore.ts
import { create } from 'zustand'

export function createMockStore<T>(initialState: Partial<T>) {
  return create<T>(() => initialState as T)
}

// Usage in tests
const mockStore = createMockStore({ count: 5, user: null })
```

### Environment-Specific Configuration

```typescript
const useStore = create(
  devtools(
    persist(/* ... */),
    {
      enabled: process.env.NODE_ENV === 'development',
      name: 'AppStore',
    }
  )
)
```

### Cross-Tab Synchronization

```typescript
import { persist, createJSONStorage } from 'zustand/middleware'

const useStore = create(
  persist(
    (set) => ({ /* ... */ }),
    {
      name: 'app-storage',
      storage: createJSONStorage(() => localStorage),

      // Sync across tabs
      partialize: (state) => ({ user: state.user }), // Only sync user

      onRehydrateStorage: () => (state) => {
        console.log('Hydrated from storage:', state)
      },
    }
  )
)

// Listen to storage events
if (typeof window !== 'undefined') {
  window.addEventListener('storage', (e) => {
    if (e.key === 'app-storage') {
      useStore.persist.rehydrate()
    }
  })
}
```

---

## AI Pair Programming Notes

**When to load this file:**
- Integrating Zustand with Next.js, Remix, or other frameworks
- Setting up SSR with Zustand
- Need framework-specific patterns
- Hydration or cross-tab sync issues

**Typical questions:**
- "How do I use Zustand with Next.js App Router?"
- "How do I prevent hydration mismatches?"
- "How do I pass server data to Zustand?"
- "Can I use Zustand with React Native?"

**Framework recommendations:**
- **Next.js App Router**: Use context provider pattern with vanilla stores
- **Next.js Pages Router**: Use global stores with manual hydration
- **Remix**: Use loader data with route-level stores
- **Vite/CRA**: Use simple global stores with persist middleware
- **React Native**: Use AsyncStorage for persistence

**Next steps:**
- [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) - Production SSR configuration
- [02-STORE-CREATION.md](./02-STORE-CREATION.md) - Store creation patterns
- [06-MIDDLEWARE.md](./06-MIDDLEWARE.md) - Persist and devtools middleware

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1
