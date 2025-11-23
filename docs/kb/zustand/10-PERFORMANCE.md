---
id: zustand-10-performance
topic: zustand
file_role: advanced
profile: full
difficulty_level: advanced
kb_version: 3.1
prerequisites: [zustand-fundamentals, zustand-selectors, zustand-advanced-patterns]
related_topics: [react-performance, optimization, profiling]
embedding_keywords: [zustand, performance, optimization, re-renders, memoization, profiling]
last_reviewed: 2025-11-16
---

# Zustand - Performance Optimization

## Purpose

Master performance optimization techniques for Zustand stores, including preventing re-renders, memoization strategies, profiling, benchmarking, and scaling to large applications.

## Table of Contents

1. [Understanding Re-renders](#understanding-re-renders)
2. [Selector Optimization](#selector-optimization)
3. [Memoization Strategies](#memoization-strategies)
4. [Component Splitting](#component-splitting)
5. [Store Optimization](#store-optimization)
6. [Profiling and Debugging](#profiling-and-debugging)
7. [Benchmarking](#benchmarking)
8. [Large-Scale Optimization](#large-scale-optimization)

---

## Understanding Re-renders

### How Zustand Triggers Re-renders

```typescript
const useStore = create((set) => ({
  count: 0,
  user: { name: 'Alice' },
  increment: () => set((state) => ({ count: state.count + 1 })),
}))

function Component1() {
  // Re-renders ONLY when count changes
  const count = useStore((state) => state.count)
  return <div>{count}</div>
}

function Component2() {
  // Re-renders when ANYTHING changes
  const state = useStore()
  return <div>{state.count}</div>
}

function Component3() {
  // NEVER re-renders (action reference is stable)
  const increment = useStore((state) => state.increment)
  return <button onClick={increment}>+</button>
}
```

### Re-render Tracking

```typescript
import { useEffect, useRef } from 'react'

function useRenderCount(componentName: string) {
  const renders = useRef(0)

  useEffect(() => {
    renders.current++
    console.log(`${componentName} rendered ${renders.current} times`)
  })
}

function TrackedComponent() {
  useRenderCount('TrackedComponent')
  const count = useStore((state) => state.count)
  return <div>{count}</div>
}
```

### Visualizing Re-renders

```typescript
// React DevTools Profiler
import { Profiler } from 'react'

function onRenderCallback(
  id: string,
  phase: 'mount' | 'update',
  actualDuration: number,
  baseDuration: number,
  startTime: number,
  commitTime: number
) {
  console.log({
    id,
    phase,
    actualDuration, // Time spent rendering
    baseDuration,   // Estimated time without memoization
  })
}

function App() {
  return (
    <Profiler id="Dashboard" onRender={onRenderCallback}>
      <Dashboard />
    </Profiler>
  )
}
```

---

## Selector Optimization

### Atomic Selectors

```typescript
const useCounterStore = create((set) => ({
  count: 0,
  user: { name: 'Alice', email: 'alice@example.com' },
  items: [],
}))

// ❌ BAD - Re-renders on ANY state change
function BadComponent() {
  const state = useCounterStore()
  return <div>{state.count}</div>
}

// ✅ GOOD - Re-renders only on count change
function GoodComponent() {
  const count = useCounterStore((state) => state.count)
  return <div>{count}</div>
}
```

### Derived Selectors with Memoization

```typescript
import { useMemo } from 'react'

const useTaskStore = create((set) => ({
  tasks: [],
  addTask: (task) => set((state) => ({ tasks: [...state.tasks, task] })),
}))

// ❌ BAD - Computes on every render
function BadTaskList() {
  const tasks = useTaskStore((state) => state.tasks)
  const completed = tasks.filter(t => t.completed) // Recomputes every render
  return <div>{completed.length} completed</div>
}

// ✅ GOOD - Memoized computation
function GoodTaskList() {
  const tasks = useTaskStore((state) => state.tasks)
  const completed = useMemo(
    () => tasks.filter(t => t.completed),
    [tasks]
  )
  return <div>{completed.length} completed</div>
}

// ✅ BETTER - Computed in selector
function BestTaskList() {
  const completedCount = useTaskStore((state) =>
    state.tasks.filter(t => t.completed).length
  )
  return <div>{completedCount} completed</div>
}
```

### Selector Factories

```typescript
// Reusable selector factory
const createSelectById = <T extends { id: string }>(items: T[], id: string) =>
  items.find(item => item.id === id)

function Post({ postId }: { postId: string }) {
  const post = useStore((state) =>
    createSelectById(state.posts, postId)
  )

  return <article>{post?.title}</article>
}

// With useMemo for stable selector reference
function PostMemo({ postId }: { postId: string }) {
  const selectPost = useMemo(
    () => (state: State) => createSelectById(state.posts, postId),
    [postId]
  )

  const post = useStore(selectPost)
  return <article>{post?.title}</article>
}
```

---

## Memoization Strategies

### React.memo for Component Memoization

```typescript
import { memo } from 'react'

interface TaskItemProps {
  task: Task
  onToggle: (id: string) => void
}

// ❌ Without memo - Re-renders even if props unchanged
function TaskItem({ task, onToggle }: TaskItemProps) {
  console.log('TaskItem rendered:', task.id)
  return (
    <div onClick={() => onToggle(task.id)}>
      {task.title}
    </div>
  )
}

// ✅ With memo - Re-renders only when props change
const TaskItemMemo = memo(TaskItem)

// ✅ Custom comparison function
const TaskItemCustom = memo(
  TaskItem,
  (prevProps, nextProps) => {
    // Only re-render if task.completed changed
    return prevProps.task.completed === nextProps.task.completed
  }
)
```

### useCallback for Stable Functions

```typescript
import { useCallback } from 'react'

const useTaskStore = create((set) => ({
  tasks: [],
  toggleTask: (id: string) => set((state) => ({
    tasks: state.tasks.map(t =>
      t.id === id ? { ...t, completed: !t.completed } : t
    )
  })),
}))

// ❌ BAD - Creates new function every render
function BadTaskList() {
  const tasks = useTaskStore((state) => state.tasks)

  return tasks.map(task => (
    <TaskItem
      key={task.id}
      task={task}
      onToggle={(id) => useTaskStore.getState().toggleTask(id)}
    />
  ))
}

// ✅ GOOD - Stable action reference
function GoodTaskList() {
  const tasks = useTaskStore((state) => state.tasks)
  const toggleTask = useTaskStore((state) => state.toggleTask)

  return tasks.map(task => (
    <TaskItemMemo
      key={task.id}
      task={task}
      onToggle={toggleTask}
    />
  ))
}

// ✅ BEST - useCallback for derived handlers
function BestTaskList() {
  const tasks = useTaskStore((state) => state.tasks)
  const toggleTask = useTaskStore((state) => state.toggleTask)

  const handleToggle = useCallback((id: string) => {
    console.log('Toggling task:', id)
    toggleTask(id)
  }, [toggleTask])

  return tasks.map(task => (
    <TaskItemMemo
      key={task.id}
      task={task}
      onToggle={handleToggle}
    />
  ))
}
```

### useMemo for Expensive Computations

```typescript
function Analytics() {
  const tasks = useTaskStore((state) => state.tasks)

  // ❌ BAD - Recomputes on every render
  const stats = {
    total: tasks.length,
    completed: tasks.filter(t => t.completed).length,
    highPriority: tasks.filter(t => t.priority === 'high').length,
    avgCompletionTime: calculateAvgTime(tasks),
  }

  // ✅ GOOD - Memoized computation
  const statsMemo = useMemo(() => ({
    total: tasks.length,
    completed: tasks.filter(t => t.completed).length,
    highPriority: tasks.filter(t => t.priority === 'high').length,
    avgCompletionTime: calculateAvgTime(tasks),
  }), [tasks])

  return <StatsDisplay stats={statsMemo} />
}
```

---

## Component Splitting

### Granular Components

```typescript
// ❌ BAD - Monolithic component
function Dashboard() {
  const user = useStore((state) => state.user)
  const tasks = useStore((state) => state.tasks)
  const notifications = useStore((state) => state.notifications)
  const settings = useStore((state) => state.settings)

  // Re-renders when ANY of these change
  return (
    <div>
      <UserProfile user={user} />
      <TaskList tasks={tasks} />
      <Notifications items={notifications} />
      <Settings config={settings} />
    </div>
  )
}

// ✅ GOOD - Granular components
function UserSection() {
  const user = useStore((state) => state.user)
  return <UserProfile user={user} />
}

function TaskSection() {
  const tasks = useStore((state) => state.tasks)
  return <TaskList tasks={tasks} />
}

function NotificationSection() {
  const notifications = useStore((state) => state.notifications)
  return <Notifications items={notifications} />
}

function SettingsSection() {
  const settings = useStore((state) => state.settings)
  return <Settings config={settings} />
}

function DashboardOptimized() {
  return (
    <div>
      <UserSection />
      <TaskSection />
      <NotificationSection />
      <SettingsSection />
    </div>
  )
}
```

### Action-Only Components

```typescript
// Component that NEVER re-renders from store
function ActionButtons() {
  const increment = useCounterStore((state) => state.increment)
  const decrement = useCounterStore((state) => state.decrement)
  const reset = useCounterStore((state) => state.reset)

  return (
    <div>
      <button onClick={increment}>+</button>
      <button onClick={decrement}>-</button>
      <button onClick={reset}>Reset</button>
    </div>
  )
}
```

---

## Store Optimization

### Shallow State Updates

```typescript
const useStore = create((set) => ({
  settings: {
    theme: 'dark',
    fontSize: 14,
    notifications: true,
  },

  // ❌ BAD - Creates new settings object even if value unchanged
  updateTheme: (theme: string) => set((state) => ({
    settings: { ...state.settings, theme }
  })),

  // ✅ GOOD - Avoid update if value unchanged
  updateThemeOptimized: (theme: string) => set((state) => {
    if (state.settings.theme === theme) return state
    return { settings: { ...state.settings, theme } }
  }),
}))
```

### Batching Multiple Updates

```typescript
const useFormStore = create((set) => ({
  formData: {},
  errors: {},
  isValid: false,

  // ❌ BAD - Three separate set calls
  updateFieldBad: (field: string, value: string) => {
    set((state) => ({ formData: { ...state.formData, [field]: value } }))
    set({ errors: validateField(field, value) })
    set({ isValid: checkFormValidity() })
  },

  // ✅ GOOD - Single batched update
  updateFieldGood: (field: string, value: string) => set((state) => {
    const newFormData = { ...state.formData, [field]: value }
    const newErrors = validateForm(newFormData)
    return {
      formData: newFormData,
      errors: newErrors,
      isValid: Object.keys(newErrors).length === 0,
    }
  }),
}))
```

### Normalized State

```typescript
// ❌ BAD - Nested arrays, hard to update
interface BadState {
  posts: {
    id: string
    title: string
    comments: { id: string; text: string }[]
  }[]
}

// ✅ GOOD - Normalized structure
interface GoodState {
  posts: Record<string, Post>
  comments: Record<string, Comment>
  postComments: Record<string, string[]> // postId -> commentIds
}

const useStore = create<GoodState>((set) => ({
  posts: {},
  comments: {},
  postComments: {},

  // Easy to update single comment
  updateComment: (commentId: string, text: string) => set((state) => ({
    comments: {
      ...state.comments,
      [commentId]: { ...state.comments[commentId], text }
    }
  })),
}))
```

---

## Profiling and Debugging

### React DevTools Profiler

```typescript
// Enable profiling in production
import { Profiler, ProfilerOnRenderCallback } from 'react'

const onRender: ProfilerOnRenderCallback = (
  id,
  phase,
  actualDuration,
  baseDuration,
  startTime,
  commitTime,
  interactions
) => {
  // Log slow renders
  if (actualDuration > 16) { // > 1 frame at 60fps
    console.warn(`Slow render in ${id}:`, {
      phase,
      actualDuration,
      baseDuration,
    })
  }
}

function App() {
  return (
    <Profiler id="App" onRender={onRender}>
      <Dashboard />
    </Profiler>
  )
}
```

### Custom Performance Monitor

```typescript
const usePerformanceMonitor = create((set, get) => ({
  renders: {} as Record<string, number>,
  updates: {} as Record<string, number>,

  trackRender: (componentName: string) => {
    const { renders } = get()
    set({
      renders: {
        ...renders,
        [componentName]: (renders[componentName] || 0) + 1
      }
    })
  },

  trackUpdate: (storeName: string) => {
    const { updates } = get()
    set({
      updates: {
        ...updates,
        [storeName]: (updates[storeName] || 0) + 1
      }
    })
  },

  getReport: () => {
    const { renders, updates } = get()
    return { renders, updates }
  },
}))

// Use in components
function MonitoredComponent() {
  useEffect(() => {
    usePerformanceMonitor.getState().trackRender('MonitoredComponent')
  })

  const count = useStore((state) => state.count)
  return <div>{count}</div>
}
```

### Why-Did-You-Render Integration

```typescript
// Install: npm install @welldone-software/why-did-you-render
import whyDidYouRender from '@welldone-software/why-did-you-render'

if (process.env.NODE_ENV === 'development') {
  whyDidYouRender(React, {
    trackAllPureComponents: true,
    trackHooks: true,
    logOnDifferentValues: true,
  })
}

// Track specific components
function TaskList() {
  // ...
}
TaskList.whyDidYouRender = true
```

---

## Benchmarking

### Performance Benchmarks

```typescript
import { performance } from 'perf_hooks'

function benchmarkSelector() {
  const useStore = create((set) => ({
    items: Array.from({ length: 10000 }, (_, i) => ({ id: i, value: i }))
  }))

  // Benchmark 1: Array filter in selector
  const start1 = performance.now()
  const selector1 = (state: State) => state.items.filter(i => i.value > 5000)
  for (let i = 0; i < 1000; i++) {
    selector1(useStore.getState())
  }
  const end1 = performance.now()
  console.log(`Array filter: ${end1 - start1}ms`)

  // Benchmark 2: Memoized selector
  let cached: any
  let lastItems: any
  const selector2 = (state: State) => {
    if (state.items === lastItems) return cached
    lastItems = state.items
    cached = state.items.filter(i => i.value > 5000)
    return cached
  }

  const start2 = performance.now()
  for (let i = 0; i < 1000; i++) {
    selector2(useStore.getState())
  }
  const end2 = performance.now()
  console.log(`Memoized selector: ${end2 - start2}ms`)
}
```

### Load Testing

```typescript
// Simulate concurrent updates
async function loadTest() {
  const useStore = create((set) => ({
    counter: 0,
    increment: () => set((state) => ({ counter: state.counter + 1 })),
  }))

  const iterations = 10000
  const concurrency = 100

  const start = performance.now()

  await Promise.all(
    Array.from({ length: concurrency }, async () => {
      for (let i = 0; i < iterations / concurrency; i++) {
        useStore.getState().increment()
      }
    })
  )

  const end = performance.now()
  const finalCount = useStore.getState().counter

  console.log({
    duration: end - start,
    operations: iterations,
    opsPerSecond: iterations / ((end - start) / 1000),
    finalCount,
  })
}
```

---

## Large-Scale Optimization

### Code Splitting Stores

```typescript
// Lazy-load store modules
const useAuthStore = create(() => ({ user: null }))

const useDashboardStore = lazy(async () => {
  const module = await import('./stores/dashboardStore')
  return module.useDashboardStore
})

function Dashboard() {
  const [store, setStore] = useState<any>(null)

  useEffect(() => {
    useDashboardStore.then(setStore)
  }, [])

  if (!store) return <Spinner />
  return <DashboardContent store={store} />
}
```

### Virtual Scrolling

```typescript
import { useVirtualizer } from '@tanstack/react-virtual'

function VirtualList() {
  const items = useStore((state) => state.items) // 10,000 items
  const parentRef = useRef<HTMLDivElement>(null)

  const virtualizer = useVirtualizer({
    count: items.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 50,
  })

  return (
    <div ref={parentRef} style={{ height: '600px', overflow: 'auto' }}>
      <div style={{ height: virtualizer.getTotalSize() }}>
        {virtualizer.getVirtualItems().map((virtualRow) => (
          <div
            key={virtualRow.index}
            style={{
              position: 'absolute',
              top: 0,
              left: 0,
              width: '100%',
              height: virtualRow.size,
              transform: `translateY(${virtualRow.start}px)`,
            }}
          >
            {items[virtualRow.index].title}
          </div>
        ))}
      </div>
    </div>
  )
}
```

### Subscription Optimization

```typescript
// Subscribe to specific slices
const useTaskStore = create((set) => ({
  tasks: [],
  filters: { status: 'all', priority: 'all' },
  ui: { sidebarOpen: true },
}))

// Only re-render when tasks change, not filters or UI
function TaskList() {
  const tasks = useTaskStore((state) => state.tasks)
  return tasks.map(task => <TaskItem key={task.id} task={task} />)
}

// Only re-render when filters change
function Filters() {
  const filters = useTaskStore((state) => state.filters)
  return <FilterControls filters={filters} />
}
```

---

## Best Practices

### 1. Measure Before Optimizing

```typescript
// ❌ BAD - Premature optimization
const MemoizedEverything = memo(
  memo(memo(Component))
)

// ✅ GOOD - Profile first, optimize bottlenecks
// Use React DevTools Profiler to identify slow components
// Then apply targeted optimizations
```

### 2. Optimize Selectors First

```typescript
// Selector optimization has the biggest impact
// ✅ Atomic selectors (select minimum data)
// ✅ Stable selectors (don't create new objects)
// ✅ Shallow equality for objects (useShallow)
```

### 3. Avoid Over-Memoization

```typescript
// ❌ BAD - Unnecessary memo for cheap component
const SimpleBadge = memo(({ text }: { text: string }) => <span>{text}</span>)

// ✅ GOOD - No memo for trivial renders
const SimpleBadge = ({ text }: { text: string }) => <span>{text}</span>
```

---

## AI Pair Programming Notes

**When to load this file:**
- Performance issues or slow renders
- Optimizing large applications
- Reducing re-renders
- Profiling and benchmarking

**Typical questions:**
- "Why is my app slow?"
- "How do I reduce re-renders?"
- "What's the best way to optimize selectors?"
- "How do I profile Zustand performance?"

**Next steps:**
- [04-SELECTORS.md](./04-SELECTORS.md) - Efficient state selection
- [09-ADVANCED-PATTERNS.md](./09-ADVANCED-PATTERNS.md) - Large-scale patterns
- [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) - Production configuration
