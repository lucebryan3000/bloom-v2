---
id: zustand-index
topic: zustand
file_role: navigation
profile: full
kb_version: 3.1
last_reviewed: 2025-11-16
---

# Zustand - Complete Index

## Quick Navigation

### 📖 Getting Started
- **[README.md](./README.md)** - Overview, quick start, why Zustand, migration guides
- **[QUICK-REFERENCE.md](./QUICK-REFERENCE.md)** - Cheat sheet for quick lookups
- **[01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md)** - Core concepts, create function, set/get

### 🔧 Core Topics (Files 02-03)
- **[02-STORE-CREATION.md](./02-STORE-CREATION.md)** - Creating stores, patterns, best practices
  - Basic store creation, structure
  - State and actions
  - The `set` function (merge vs replace)
  - Common patterns (counter, CRUD, loading/error)
  - Best practices and pitfalls

- **[03-STATE-UPDATES.md](./03-STATE-UPDATES.md)** - Immutable updates, nested objects, arrays
  - The `set` function deep dive
  - Immutable update patterns
  - Nested object updates
  - Array operations (add, remove, update, sort, filter)
  - Batching updates
  - Using the `get` function

### 🛠️ Practical Guides (Files 04-07)
- **[04-SELECTORS.md](./04-SELECTORS.md)** - Efficient state selection, preventing re-renders
  - Basic selection patterns
  - How Zustand detects changes
  - Preventing re-renders
  - `useShallow` for multiple selections
  - Custom equality functions
  - Selector best practices
  - Performance optimization strategies

- **[05-ASYNC-ACTIONS.md](./05-ASYNC-ACTIONS.md)** - API calls, loading states, error handling
  - Basic async actions
  - Loading and error states
  - CRUD operations
  - Pagination and infinite scroll
  - WebSocket integration
  - AbortController for cancellation
  - Optimistic updates with rollback
  - Request queuing and debouncing

- **[06-MIDDLEWARE.md](./06-MIDDLEWARE.md)** - persist, immer, devtools, custom middleware
  - `persist` - localStorage/sessionStorage
  - `immer` - mutable-style updates
  - `devtools` - Redux DevTools integration
  - `subscribeWithSelector` - selective subscriptions
  - Custom middleware creation
  - Combining middleware
  - Middleware order and composition

- **[07-TYPESCRIPT.md](./07-TYPESCRIPT.md)** - Type-safe stores, actions, selectors
  - Basic TypeScript patterns
  - Typing stores with interfaces
  - Typing actions and selectors
  - Middleware typing (extra `()` required)
  - Generic patterns
  - Slice typing
  - Type inference and utilities

### 🚀 Advanced Topics (Files 08-10)
- **[08-TESTING.md](./08-TESTING.md)** - Jest, React Testing Library, mocking
  - Testing stores directly
  - Testing components with stores
  - Mocking stores
  - Testing async actions
  - Testing middleware (persist, immer)
  - Testing selectors
  - Integration testing patterns

- **[09-ADVANCED-PATTERNS.md](./09-ADVANCED-PATTERNS.md)** - Slices, vanilla stores, architecture
  - Store slices for large applications
  - Vanilla stores (`createStore` from `zustand/vanilla`)
  - Cross-store communication
  - Subscriptions and transient updates
  - Code splitting stores
  - Repository pattern
  - Factory pattern
  - Context-based stores

- **[10-PERFORMANCE.md](./10-PERFORMANCE.md)** - Optimization, profiling, benchmarking
  - Understanding re-renders
  - Selector optimization
  - Memoization strategies (memo, useCallback, useMemo)
  - Component splitting patterns
  - Store optimization (shallow updates, batching, normalization)
  - Profiling with React DevTools
  - Benchmarking performance
  - Large-scale optimization (code splitting, virtual scrolling)

### ⚙️ Operations (File 11)
- **[11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md)** - Production config, SSR, deployment
  - Environment-specific configuration
  - Feature flags
  - Server-side rendering (Next.js App Router, Pages Router, Remix)
  - Hydration strategies
  - Error handling and retry logic
  - Monitoring and observability
  - Migration strategies
  - Production deployment checklist
  - Troubleshooting common issues

### 🔌 Framework Integration
- **[FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md)** - Next.js, Remix, SSR patterns
  - Next.js App Router integration
  - Next.js Pages Router integration
  - Remix integration
  - Vanilla React (Vite, CRA)
  - React Native
  - SSR best practices
  - Hydration patterns

---

## File Breakdown by Topic

### State Management Basics
| File | Topics Covered | Lines |
|------|----------------|-------|
| 01-FUNDAMENTALS | Core concepts, create, set, get | ~600 |
| 02-STORE-CREATION | Store structure, actions, patterns | ~318 |
| 03-STATE-UPDATES | Immutability, nested updates, arrays | ~425 |

### State Usage
| File | Topics Covered | Lines |
|------|----------------|-------|
| 04-SELECTORS | Selection, re-renders, useShallow | ~350 |
| 05-ASYNC-ACTIONS | API calls, loading, errors, optimistic updates | ~445 |

### Enhancement
| File | Topics Covered | Lines |
|------|----------------|-------|
| 06-MIDDLEWARE | persist, immer, devtools, custom | ~430 |
| 07-TYPESCRIPT | Types, interfaces, generics | ~410 |
| 08-TESTING | Jest, RTL, mocking, async | ~405 |

### Advanced
| File | Topics Covered | Lines |
|------|----------------|-------|
| 09-ADVANCED-PATTERNS | Slices, vanilla, cross-store, architecture | ~385 |
| 10-PERFORMANCE | Optimization, profiling, benchmarking | ~630 |
| 11-CONFIG-OPERATIONS | SSR, hydration, production, deployment | ~640 |

**Total Documentation**: ~5,038 lines of comprehensive content

---

## Learning Paths

### 🐻 Beginner Path (1-2 hours)
**Goal**: Create and use basic Zustand stores

1. **[README.md](./README.md)** - Understand what Zustand is and why to use it
2. **[01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md)** - Learn core concepts
3. **[02-STORE-CREATION.md](./02-STORE-CREATION.md)** - Create your first store
4. **[04-SELECTORS.md](./04-SELECTORS.md)** - Use state efficiently in components
5. **[QUICK-REFERENCE.md](./QUICK-REFERENCE.md)** - Bookmark for quick lookups

**After this path, you can:**
- ✅ Create basic Zustand stores
- ✅ Add state and actions
- ✅ Use stores in React components
- ✅ Prevent unnecessary re-renders
- ✅ Understand the API basics

### 🦊 Intermediate Path (3-4 hours)
**Goal**: Build production-ready applications with Zustand

**Prerequisites**: Complete Beginner Path first

1. **[03-STATE-UPDATES.md](./03-STATE-UPDATES.md)** - Master state updates
2. **[05-ASYNC-ACTIONS.md](./05-ASYNC-ACTIONS.md)** - Handle API calls and async logic
3. **[06-MIDDLEWARE.md](./06-MIDDLEWARE.md)** - Add persistence and devtools
4. **[07-TYPESCRIPT.md](./07-TYPESCRIPT.md)** - Type-safe stores
5. **[FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md)** - Next.js/Remix integration

**After this path, you can:**
- ✅ Handle complex state updates immutably
- ✅ Implement loading states and error handling
- ✅ Persist state to localStorage
- ✅ Use Redux DevTools for debugging
- ✅ Write type-safe stores with TypeScript
- ✅ Integrate with Next.js SSR

### 🦁 Advanced Path (5+ hours)
**Goal**: Master advanced patterns and production deployment

**Prerequisites**: Complete Intermediate Path first

1. **[08-TESTING.md](./08-TESTING.md)** - Test stores and components
2. **[09-ADVANCED-PATTERNS.md](./09-ADVANCED-PATTERNS.md)** - Architectural patterns
3. **[10-PERFORMANCE.md](./10-PERFORMANCE.md)** - Optimize for production
4. **[11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md)** - Deploy to production

**After this path, you can:**
- ✅ Write comprehensive tests for stores
- ✅ Use advanced patterns (slices, vanilla stores)
- ✅ Implement cross-store communication
- ✅ Profile and optimize performance
- ✅ Handle SSR/hydration correctly
- ✅ Deploy to production confidently

---

## Topic-Based Quick Find

### Looking for specific topics? Jump directly to the relevant section:

#### State Management
- **Creating stores** → [02-STORE-CREATION.md](./02-STORE-CREATION.md)
- **Updating state** → [03-STATE-UPDATES.md](./03-STATE-UPDATES.md)
- **Selecting state** → [04-SELECTORS.md](./04-SELECTORS.md)
- **Async operations** → [05-ASYNC-ACTIONS.md](./05-ASYNC-ACTIONS.md)

#### Features & Enhancement
- **Persistence (localStorage)** → [06-MIDDLEWARE.md#persist](./06-MIDDLEWARE.md)
- **DevTools** → [06-MIDDLEWARE.md#devtools](./06-MIDDLEWARE.md)
- **Immer (mutable updates)** → [06-MIDDLEWARE.md#immer](./06-MIDDLEWARE.md)
- **TypeScript** → [07-TYPESCRIPT.md](./07-TYPESCRIPT.md)

#### Testing & Quality
- **Testing stores** → [08-TESTING.md](./08-TESTING.md)
- **Testing components** → [08-TESTING.md#testing-components](./08-TESTING.md)
- **Mocking** → [08-TESTING.md#mocking-stores](./08-TESTING.md)

#### Performance
- **Preventing re-renders** → [04-SELECTORS.md](./04-SELECTORS.md) + [10-PERFORMANCE.md](./10-PERFORMANCE.md)
- **Optimization** → [10-PERFORMANCE.md](./10-PERFORMANCE.md)
- **Profiling** → [10-PERFORMANCE.md#profiling-and-debugging](./10-PERFORMANCE.md)
- **Benchmarking** → [10-PERFORMANCE.md#benchmarking](./10-PERFORMANCE.md)

#### Architecture & Patterns
- **Store slices** → [09-ADVANCED-PATTERNS.md#store-slices](./09-ADVANCED-PATTERNS.md)
- **Vanilla stores** → [09-ADVANCED-PATTERNS.md#vanilla-stores](./09-ADVANCED-PATTERNS.md)
- **Cross-store communication** → [09-ADVANCED-PATTERNS.md#cross-store-communication](./09-ADVANCED-PATTERNS.md)
- **Subscriptions** → [09-ADVANCED-PATTERNS.md#subscriptions](./09-ADVANCED-PATTERNS.md)

#### Framework Integration
- **Next.js** → [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md) + [11-CONFIG-OPERATIONS.md#server-side-rendering](./11-CONFIG-OPERATIONS.md)
- **Remix** → [11-CONFIG-OPERATIONS.md#remix](./11-CONFIG-OPERATIONS.md)
- **SSR/Hydration** → [11-CONFIG-OPERATIONS.md#hydration-strategies](./11-CONFIG-OPERATIONS.md)

#### Production
- **Configuration** → [11-CONFIG-OPERATIONS.md#production-configuration](./11-CONFIG-OPERATIONS.md)
- **Error handling** → [11-CONFIG-OPERATIONS.md#error-handling](./11-CONFIG-OPERATIONS.md)
- **Monitoring** → [11-CONFIG-OPERATIONS.md#monitoring-and-observability](./11-CONFIG-OPERATIONS.md)
- **Deployment** → [11-CONFIG-OPERATIONS.md#deployment-best-practices](./11-CONFIG-OPERATIONS.md)
- **Troubleshooting** → [11-CONFIG-OPERATIONS.md#troubleshooting](./11-CONFIG-OPERATIONS.md)

---

## Problem-Based Quick Find

### "I want to..."

#### Basic Tasks
- **Create a store** → [02-STORE-CREATION.md](./02-STORE-CREATION.md)
- **Add an action** → [02-STORE-CREATION.md#action-patterns](./02-STORE-CREATION.md)
- **Update state** → [03-STATE-UPDATES.md](./03-STATE-UPDATES.md)
- **Use state in a component** → [04-SELECTORS.md](./04-SELECTORS.md)

#### Data Operations
- **Update an array** → [03-STATE-UPDATES.md#array-operations](./03-STATE-UPDATES.md)
- **Update nested objects** → [03-STATE-UPDATES.md#nested-object-updates](./03-STATE-UPDATES.md)
- **Handle async/API calls** → [05-ASYNC-ACTIONS.md](./05-ASYNC-ACTIONS.md)
- **Show loading states** → [05-ASYNC-ACTIONS.md#loading-and-error-states](./05-ASYNC-ACTIONS.md)

#### Enhancement
- **Save to localStorage** → [06-MIDDLEWARE.md#persist](./06-MIDDLEWARE.md)
- **Debug with Redux DevTools** → [06-MIDDLEWARE.md#devtools](./06-MIDDLEWARE.md)
- **Use TypeScript** → [07-TYPESCRIPT.md](./07-TYPESCRIPT.md)
- **Write tests** → [08-TESTING.md](./08-TESTING.md)

#### Performance
- **Reduce re-renders** → [04-SELECTORS.md](./04-SELECTORS.md) + [10-PERFORMANCE.md](./10-PERFORMANCE.md)
- **Optimize performance** → [10-PERFORMANCE.md](./10-PERFORMANCE.md)
- **Profile my app** → [10-PERFORMANCE.md#profiling-and-debugging](./10-PERFORMANCE.md)

#### Advanced
- **Split large stores** → [09-ADVANCED-PATTERNS.md#store-slices](./09-ADVANCED-PATTERNS.md)
- **Use outside React** → [09-ADVANCED-PATTERNS.md#vanilla-stores](./09-ADVANCED-PATTERNS.md)
- **Communicate between stores** → [09-ADVANCED-PATTERNS.md#cross-store-communication](./09-ADVANCED-PATTERNS.md)

#### Production
- **Deploy to production** → [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md)
- **Handle SSR** → [11-CONFIG-OPERATIONS.md#server-side-rendering-ssr](./11-CONFIG-OPERATIONS.md)
- **Fix hydration errors** → [11-CONFIG-OPERATIONS.md#hydration-strategies](./11-CONFIG-OPERATIONS.md)

---

## Code Examples by Use Case

### E-Commerce Store
Files: [02-STORE-CREATION.md](./02-STORE-CREATION.md), [05-ASYNC-ACTIONS.md](./05-ASYNC-ACTIONS.md), [06-MIDDLEWARE.md](./06-MIDDLEWARE.md)
- Shopping cart state
- Product catalog
- Checkout flow
- Persist cart to localStorage

### Todo/Task Manager
Files: [02-STORE-CREATION.md](./02-STORE-CREATION.md), [03-STATE-UPDATES.md](./03-STATE-UPDATES.md), [08-TESTING.md](./08-TESTING.md)
- CRUD operations
- Filtering and sorting
- Local state persistence
- Testing task operations

### Authentication
Files: [05-ASYNC-ACTIONS.md](./05-ASYNC-ACTIONS.md), [06-MIDDLEWARE.md](./06-MIDDLEWARE.md), [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md)
- Login/logout flow
- Token management
- Protected routes
- Session persistence

### Real-time Dashboard
Files: [05-ASYNC-ACTIONS.md](./05-ASYNC-ACTIONS.md), [09-ADVANCED-PATTERNS.md](./09-ADVANCED-PATTERNS.md), [10-PERFORMANCE.md](./10-PERFORMANCE.md)
- WebSocket integration
- Live data updates
- Performance optimization
- Transient updates

---

## AI Pair Programming Notes

**When to load this file:**
- User asks "Where do I find X?"
- Need to recommend relevant documentation
- Planning learning path for developer
- Looking for specific topic or pattern

**How to use this index:**
1. **Identify user's skill level** → Recommend appropriate learning path
2. **Identify specific problem** → Use Problem-Based Quick Find
3. **Identify topic** → Use Topic-Based Quick Find
4. **Need overview** → Point to README.md
5. **Need quick syntax** → Point to QUICK-REFERENCE.md

**Common navigation patterns:**
- New to Zustand → Beginner Path
- Know basics, building app → Intermediate Path
- Performance issues → [10-PERFORMANCE.md](./10-PERFORMANCE.md)
- SSR/Hydration issues → [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md)
- Testing questions → [08-TESTING.md](./08-TESTING.md)
- TypeScript types → [07-TYPESCRIPT.md](./07-TYPESCRIPT.md)

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1 | **Files**: 15 | **Total Lines**: ~5,600+
