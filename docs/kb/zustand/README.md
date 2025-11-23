---
id: zustand-readme
topic: zustand
file_role: overview
profile: full
difficulty_level: beginner
kb_version: 3.1
prerequisites: [react-hooks]
related_topics: [react, state-management, hooks]
embedding_keywords: [zustand, state-management, react, hooks, minimal]
last_reviewed: 2025-11-16
---

# Zustand Knowledge Base

A small, fast, and scalable bearbones state-management solution using simplified flux principles. Has a comfy API based on hooks, isn't boilerplatey or opinionated.

## Why Zustand?

### Key Benefits

- **Tiny**: < 1kb (minified + gzipped)
- **Simple**: No providers, no boilerplate, no external dependencies
- **Fast**: Optimized re-renders through transient updates
- **TypeScript**: First-class TypeScript support
- **DevTools**: Redux DevTools integration
- **Middleware**: Built-in and custom middleware support
- **No Context**: Works without React Context
- **SSR-Ready**: Full support for Next.js and other SSR frameworks

### Comparison with Other Libraries

| Feature | Zustand | Redux | Context API | Jotai | Valtio |
|---------|---------|-------|-------------|-------|--------|
| Bundle Size | 1kb | 45kb | 0 (built-in) | 3kb | 5kb |
| Boilerplate | Minimal | High | Low | Minimal | Minimal |
| Learning Curve | Easy | Steep | Easy | Easy | Easy |
| DevTools | ✅ | ✅ | ❌ | ✅ | ✅ |
| TypeScript | ✅ | ✅ | ✅ | ✅ | ✅ |
| Middleware | ✅ | ✅ | ❌ | Limited | Limited |
| SSR | ✅ | ✅ | ✅ | ✅ | ✅ |

## Installation

```bash
npm install zustand
# or
yarn add zustand
# or
pnpm add zustand
```

## Quick Start

### Create a Store (30 seconds)

```typescript
import { create } from 'zustand'

interface BearState {
  bears: number
  increasePopulation: () => void
  removeAllBears: () => void
}

const useBearStore = create<BearState>((set) => ({
  bears: 0,
  increasePopulation: () => set((state) => ({ bears: state.bears + 1 })),
  removeAllBears: () => set({ bears: 0 }),
}))
```

### Use in Components

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

**That's it!** No providers, no wrappers, just a hook.

## Core Concepts

### 1. Store Creation

```typescript
const useStore = create((set) => ({
  // State
  count: 0,

  // Actions
  increment: () => set((state) => ({ count: state.count + 1 })),
  decrement: () => set((state) => ({ count: state.count - 1 })),
  reset: () => set({ count: 0 }),
}))
```

### 2. State Selection

```typescript
// Select specific state (prevents unnecessary re-renders)
const count = useStore((state) => state.count)

// Select multiple values
import { useShallow } from 'zustand/react/shallow'

const { count, increment } = useStore(
  useShallow((state) => ({ count: state.count, increment: state.increment }))
)
```

### 3. Middleware

```typescript
import { create } from 'zustand'
import { persist, devtools } from 'zustand/middleware'

const useStore = create(
  devtools(
    persist(
      (set) => ({
        bears: 0,
        increasePopulation: () => set((state) => ({ bears: state.bears + 1 })),
      }),
      { name: 'bear-storage' }
    )
  )
)
```

## Documentation Structure

This knowledge base contains **15 comprehensive files**:

### Getting Started
- **[README.md](./README.md)** (You are here) - Overview and quick start
- **[INDEX.md](./INDEX.md)** - Complete file index with learning paths
- **[QUICK-REFERENCE.md](./QUICK-REFERENCE.md)** - Cheat sheet for quick lookups
- **[FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md)** - Next.js, Remix, SSR patterns

### Core Concepts (Files 01-03)
1. **[01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md)** - Core concepts, create function, set/get
2. **[02-STORE-CREATION.md](./02-STORE-CREATION.md)** - Creating stores, patterns, best practices
3. **[03-STATE-UPDATES.md](./03-STATE-UPDATES.md)** - Immutable updates, nested objects, arrays

### Practical Guides (Files 04-07)
4. **[04-SELECTORS.md](./04-SELECTORS.md)** - Efficient state selection, preventing re-renders
5. **[05-ASYNC-ACTIONS.md](./05-ASYNC-ACTIONS.md)** - API calls, loading states, error handling
6. **[06-MIDDLEWARE.md](./06-MIDDLEWARE.md)** - persist, immer, devtools, custom middleware
7. **[07-TYPESCRIPT.md](./07-TYPESCRIPT.md)** - Type-safe stores, actions, selectors

### Advanced Topics (Files 08-10)
8. **[08-TESTING.md](./08-TESTING.md)** - Jest, React Testing Library, mocking
9. **[09-ADVANCED-PATTERNS.md](./09-ADVANCED-PATTERNS.md)** - Slices, vanilla stores, cross-store communication
10. **[10-PERFORMANCE.md](./10-PERFORMANCE.md)** - Optimization, profiling, benchmarking

### Operations (File 11)
11. **[11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md)** - Production config, SSR, deployment

## Learning Paths

### 🐻 Beginner Path (1-2 hours)
Perfect for developers new to Zustand

1. **Start**: [01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md) - Learn core concepts
2. **Practice**: [02-STORE-CREATION.md](./02-STORE-CREATION.md) - Create your first store
3. **Use**: [04-SELECTORS.md](./04-SELECTORS.md) - Efficient state selection
4. **Reference**: [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) - Cheat sheet

**You'll know:**
- How to create stores
- How to use state in components
- How to prevent unnecessary re-renders
- Basic patterns and best practices

### 🦊 Intermediate Path (3-4 hours)
For developers building production applications

1. **Updates**: [03-STATE-UPDATES.md](./03-STATE-UPDATES.md) - Master immutable updates
2. **Async**: [05-ASYNC-ACTIONS.md](./05-ASYNC-ACTIONS.md) - API calls and loading states
3. **Middleware**: [06-MIDDLEWARE.md](./06-MIDDLEWARE.md) - Persistence and devtools
4. **TypeScript**: [07-TYPESCRIPT.md](./07-TYPESCRIPT.md) - Type-safe stores
5. **Integration**: [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md) - Next.js setup

**You'll know:**
- Complex state updates
- Async operations
- Local storage persistence
- TypeScript integration
- Framework-specific patterns

### 🦁 Advanced Path (5+ hours)
For senior developers and large-scale applications

1. **Testing**: [08-TESTING.md](./08-TESTING.md) - Comprehensive testing strategies
2. **Patterns**: [09-ADVANCED-PATTERNS.md](./09-ADVANCED-PATTERNS.md) - Slices, vanilla stores, architecture
3. **Performance**: [10-PERFORMANCE.md](./10-PERFORMANCE.md) - Optimization and profiling
4. **Operations**: [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) - Production deployment

**You'll know:**
- Testing strategies for stores
- Advanced architectural patterns
- Performance optimization
- SSR/hydration handling
- Production deployment

## Common Use Cases

### ✅ Zustand is Great For:

1. **Global UI State**
   - Theme settings, sidebar state, modal visibility
   - User preferences and settings
   - Navigation and routing state

2. **Shared Application State**
   - User authentication and session data
   - Shopping cart and checkout flow
   - Form state across multiple steps

3. **Real-time Data**
   - WebSocket connections
   - Live notifications
   - Collaborative editing

4. **Small to Medium Apps**
   - Most React applications
   - MVP projects
   - Side projects and prototypes

### ⚠️ Consider Alternatives For:

1. **Server State** → Use React Query, SWR, or Apollo
   - API caching and synchronization
   - Server-side pagination
   - Background refetching

2. **Complex Redux Ecosystems** → Migrate gradually
   - Existing Redux apps with middleware
   - Teams already proficient in Redux
   - Redux-specific tooling requirements

3. **Atomic State** → Use Jotai or Recoil
   - Highly granular state atoms
   - Dependency graphs between state
   - Derived state with complex computations

## Migration from Other Libraries

### From Context API

```typescript
// Before (Context API)
const CountContext = createContext()

function CountProvider({ children }) {
  const [count, setCount] = useState(0)
  return (
    <CountContext.Provider value={{ count, setCount }}>
      {children}
    </CountContext.Provider>
  )
}

// After (Zustand)
const useCountStore = create((set) => ({
  count: 0,
  setCount: (count) => set({ count }),
}))

// No provider needed!
```

### From Redux

```typescript
// Before (Redux)
const INCREMENT = 'INCREMENT'
const increment = () => ({ type: INCREMENT })

const reducer = (state = { count: 0 }, action) => {
  switch (action.type) {
    case INCREMENT:
      return { count: state.count + 1 }
    default:
      return state
  }
}

// After (Zustand)
const useStore = create((set) => ({
  count: 0,
  increment: () => set((state) => ({ count: state.count + 1 })),
}))
```

## Resources

### Official Documentation
- **Website**: [https://zustand-demo.pmnd.rs/](https://zustand-demo.pmnd.rs/)
- **GitHub**: [https://github.com/pmndrs/zustand](https://github.com/pmndrs/zustand)
- **npm**: [https://www.npmjs.com/package/zustand](https://www.npmjs.com/package/zustand)

### Community
- **Discord**: [Poimandres Discord](https://discord.gg/poimandres)
- **Stack Overflow**: Tag `zustand`
- **Reddit**: r/reactjs discussions

### Related Libraries (by pmndrs)
- **React Three Fiber**: 3D graphics with React
- **Jotai**: Primitive and flexible state management
- **Valtio**: Proxy-based state management

## Version Compatibility

| Zustand | React | TypeScript | Node.js |
|---------|-------|------------|---------|
| 4.x | 18+ | 4.5+ | 14+ |
| 3.x | 16.8+ | 3.8+ | 12+ |

## AI Pair Programming Notes

**When to recommend this KB:**
- Developer asks about React state management
- Project needs global state without Redux complexity
- Looking for lightweight alternative to Context API
- Building TypeScript React application
- Need local storage persistence
- SSR/Next.js state management

**Common entry points:**
- **Complete beginner**: Start at [01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md)
- **Quick syntax lookup**: Use [QUICK-REFERENCE.md](./QUICK-REFERENCE.md)
- **Specific problem**: Check [INDEX.md](./INDEX.md) for topic
- **Next.js integration**: [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md)
- **Production deployment**: [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md)

**This KB is NOT for:**
- Server state management (use React Query/SWR)
- Form state (use React Hook Form/Formik)
- URL state (use Next.js router/React Router)
- Database state (use Prisma/TypeORM)

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1 | **Zustand Version**: 4.x
