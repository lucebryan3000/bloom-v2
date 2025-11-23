---
id: zustand-04-selectors
topic: zustand
file_role: practical
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [zustand-fundamentals, zustand-store-creation]
related_topics: [react, performance, re-renders]
embedding_keywords: [zustand, selectors, performance, re-renders, useShallow]
last_reviewed: 2025-11-16
---

# Zustand - Selectors and Preventing Re-renders

## Purpose

Learn how to efficiently select state in components using selectors, prevent unnecessary re-renders, and optimize component performance with Zustand.

## Table of Contents

1. [Basic Selection](#basic-selection)
2. [Preventing Re-renders](#preventing-re-renders)
3. [useShallow for Multiple Selections](#useshallow-for-multiple-selections)
4. [Custom Equality Functions](#custom-equality-functions)
5. [Selector Best Practices](#selector-best-practices)
6. [Common Patterns](#common-patterns)

---

## Basic Selection

### Simple Property Selection

```typescript
const useBearStore = create((set) => ({
  bears: 0,
  fish: 10,
  increaseBears: () => set((state) => ({ bears: state.bears + 1 })),
}))

function BearCounter() {
  // ✅ Subscribes only to bears
  const bears = useBearStore((state) => state.bears)
  return <h1>{bears} bears</h1>
}

function FishCounter() {
  // ✅ Subscribes only to fish
  const fish = useBearStore((state) => state.fish)
  return <h1>{fish} fish</h1>
}
```

**Key Point:** Components re-render **only** when their selected state changes.

### How Zustand Detects Changes

Zustand uses **strict equality** (`===`) by default:

```typescript
const bears = useBearStore((state) => state.bears)
// Re-renders only if: newState.bears !== oldState.bears
```

---

## Preventing Re-renders

### Anti-Pattern: Selecting Entire State

```typescript
// ❌ BAD - Re-renders on ANY state change
function Component() {
  const state = useBearStore((state) => state)
  return <div>{state.bears}</div>
}
```

Selecting the entire state object causes re-renders whenever **any** property changes, even if the component doesn't use it.

### Best Practice: Select Only What You Need

```typescript
// ✅ GOOD - Re-renders only when bears changes
function Component() {
  const bears = useBearStore((state) => state.bears)
  return <div>{bears}</div>
}
```

### Multiple Independent Selections

```typescript
function Dashboard() {
  // Each selector is independent
  const user = useStore((state) => state.user)
  const posts = useStore((state) => state.posts)
  const settings = useStore((state) => state.settings)

  // Component re-renders if ANY of these change
  return (
    <div>
      <UserProfile user={user} />
      <PostList posts={posts} />
      <Settings settings={settings} />
    </div>
  )
}
```

---

## useShallow for Multiple Selections

### Problem: Object Selectors Always Re-render

```typescript
// ❌ BAD - Creates new object on every render
const { nuts, honey } = useBearStore((state) => ({
  nuts: state.nuts,
  honey: state.honey,
}))
// Re-renders even if nuts and honey haven't changed!
```

**Why?** `{ nuts, honey }` creates a **new object** every time, failing `===` check.

### Solution: useShallow

```typescript
import { useShallow } from 'zustand/react/shallow'

function Component() {
  // ✅ GOOD - Shallow comparison
  const { nuts, honey } = useBearStore(
    useShallow((state) => ({ nuts: state.nuts, honey: state.honey }))
  )

  // Only re-renders if nuts or honey actually changed
  return <div>{nuts} nuts, {honey} honey</div>
}
```

### useShallow with Arrays

```typescript
// ✅ Selecting multiple actions
const [increaseBears, increaseBearsBy] = useBearStore(
  useShallow((state) => [state.increaseBears, state.increaseBearsBy])
)

// ✅ Selecting multiple primitives
const [bears, fish, dolphins] = useStore(
  useShallow((state) => [state.bears, state.fish, state.dolphins])
)
```

---

## Custom Equality Functions

### The Equality Parameter

```typescript
const selector = (state) => state.treats
const equalityFn = (oldTreats, newTreats) => {
  // Custom comparison logic
  return oldTreats.length === newTreats.length
}

const treats = useBearStore(selector, equalityFn)
```

### Deep Equality Example

```typescript
import { isEqual } from 'lodash'

function Component() {
  const user = useStore(
    (state) => state.user,
    isEqual // Deep equality check
  )

  // Re-renders only if user object deeply changed
  return <UserProfile user={user} />
}
```

### Array Length Equality

```typescript
const items = useStore(
  (state) => state.items,
  (oldItems, newItems) => oldItems.length === newItems.length
)

// Component re-renders only when array length changes
```

---

## Selector Best Practices

### 1. Extract Selectors to Constants

```typescript
// ❌ BAD - Inline selector (less readable)
function Component() {
  const count = useStore((state) => state.count)
}

// ✅ GOOD - Named selector (reusable, testable)
const selectCount = (state) => state.count

function Component() {
  const count = useStore(selectCount)
}
```

### 2. Create Reusable Selectors

```typescript
// selectors.ts
export const selectUser = (state) => state.user
export const selectPosts = (state) => state.posts
export const selectUserPosts = (state) =>
  state.posts.filter(p => p.authorId === state.user.id)

// Component.tsx
import { selectUser, selectUserPosts } from './selectors'

function UserDashboard() {
  const user = useStore(selectUser)
  const userPosts = useStore(selectUserPosts)

  return <div>...</div>
}
```

### 3. Derived State in Selectors

```typescript
const useCartStore = create((set) => ({
  items: [],
  addItem: (item) => set((state) => ({ items: [...state.items, item] })),
}))

// Derived selectors
const selectTotal = (state) =>
  state.items.reduce((sum, item) => sum + item.price, 0)

const selectItemCount = (state) => state.items.length

const selectCartSummary = (state) => ({
  items: state.items,
  total: selectTotal(state),
  itemCount: selectItemCount(state),
})

function CartSummary() {
  const summary = useCartStore(selectCartSummary)
  return <div>{summary.itemCount} items: ${summary.total}</div>
}
```

### 4. Parameterized Selectors

```typescript
// ❌ WRONG - Can't pass parameters directly
const selectPostById = (state, id) => state.posts.find(p => p.id === id)

// ✅ CORRECT - Selector factory
const createSelectPostById = (id) => (state) =>
  state.posts.find(p => p.id === id)

function Post({ postId }) {
  const post = useStore(createSelectPostById(postId))
  return <article>{post.title}</article>
}
```

---

## Common Patterns

### Pattern 1: Selecting Actions Only

```typescript
// Actions don't change, so component never re-renders from store
const increaseBears = useBearStore((state) => state.increaseBears)

function Button() {
  const increaseBears = useBearStore((state) => state.increaseBears)

  return <button onClick={increaseBears}>Add Bear</button>
  // Never re-renders when state changes!
}
```

### Pattern 2: Combining State and Actions

```typescript
function Counter() {
  // Get both state and actions
  const { count, increment, decrement } = useStore(
    useShallow((state) => ({
      count: state.count,
      increment: state.increment,
      decrement: state.decrement,
    }))
  )

  return (
    <div>
      <button onClick={decrement}>-</button>
      <span>{count}</span>
      <button onClick={increment}>+</button>
    </div>
  )
}
```

### Pattern 3: Conditional Selection

```typescript
function ConditionalComponent({ showDetails }) {
  const user = useStore((state) => state.user)

  const details = useStore(
    (state) => showDetails ? state.userDetails : null,
    (a, b) => a?.id === b?.id
  )

  return (
    <div>
      <UserBasic user={user} />
      {showDetails && <UserDetails details={details} />}
    </div>
  )
}
```

### Pattern 4: Memoized Selectors

```typescript
import { useMemo } from 'react'

function UserPosts({ userId }) {
  const selectUserPosts = useMemo(
    () => (state) => state.posts.filter(p => p.authorId === userId),
    [userId]
  )

  const posts = useStore(selectUserPosts)

  return <PostList posts={posts} />
}
```

### Pattern 5: Selector with Fallback

```typescript
const selectUserOrGuest = (state) =>
  state.user || { name: 'Guest', role: 'visitor' }

function Header() {
  const user = useStore(selectUserOrGuest)
  return <div>Welcome, {user.name}</div>
}
```

---

## Performance Optimization Strategies

### Strategy 1: Split Large Components

```typescript
// ❌ BAD - Single component with multiple selections
function Dashboard() {
  const user = useStore((state) => state.user)
  const posts = useStore((state) => state.posts)
  const comments = useStore((state) => state.comments)
  const likes = useStore((state) => state.likes)

  // Re-renders if ANY of these change
  return (
    <div>
      <User data={user} />
      <Posts data={posts} />
      <Comments data={comments} />
      <Likes data={likes} />
    </div>
  )
}

// ✅ GOOD - Separate components
function Dashboard() {
  return (
    <div>
      <UserSection />
      <PostsSection />
      <CommentsSection />
      <LikesSection />
    </div>
  )
}

function UserSection() {
  const user = useStore((state) => state.user)
  return <User data={user} />
}
// Each section re-renders independently
```

### Strategy 2: Select Primitives, Not Objects

```typescript
// ❌ LESS OPTIMAL - Selects object
const user = useStore((state) => state.user)

// ✅ MORE OPTIMAL - Selects only needed primitive
const userName = useStore((state) => state.user.name)
```

### Strategy 3: Use Selectors for Computed Values

```typescript
const useTaskStore = create((set) => ({
  tasks: [],
  // Don't store derived values
  // ❌ BAD: completedCount: 0
}))

// ✅ GOOD - Compute in selector
const selectCompletedCount = (state) =>
  state.tasks.filter(t => t.completed).length

function Stats() {
  const completedCount = useTaskStore(selectCompletedCount)
  return <div>{completedCount} completed</div>
}
```

---

## Common Pitfalls

### Pitfall 1: Inline Object Selectors

```typescript
// ❌ BAD - New object every render
const data = useStore((state) => ({ count: state.count }))

// ✅ GOOD - Use useShallow
const data = useStore(
  useShallow((state) => ({ count: state.count }))
)
```

### Pitfall 2: Unnecessary Deep Selectors

```typescript
// ❌ BAD - Re-renders even if only user.name is used
const user = useStore((state) => state.user)

// ✅ GOOD - Select only what's needed
const userName = useStore((state) => state.user.name)
```

### Pitfall 3: Forgetting Equality Functions for Arrays

```typescript
// ❌ BAD - New array reference every time
const items = useStore((state) => state.items.map(i => i.id))

// ✅ GOOD - Memoize or use equality function
const items = useStore(
  (state) => state.items.map(i => i.id),
  (a, b) => a.length === b.length && a.every((v, i) => v === b[i])
)
```

---

## AI Pair Programming Notes

**When to load this file:**
- Component re-rendering too often
- Performance optimization needed
- Understanding how Zustand subscriptions work
- Selecting multiple pieces of state

**Typical questions:**
- "Why is my component re-rendering?"
- "How do I select multiple properties without re-renders?"
- "What's the difference between useShallow and custom equality?"
- "Should I use selectors for derived state?"

**Next steps:**
- [10-PERFORMANCE.md](./10-PERFORMANCE.md) - Advanced performance optimization
- [09-ADVANCED-PATTERNS.md](./09-ADVANCED-PATTERNS.md) - Complex selector patterns
- [08-TESTING.md](./08-TESTING.md) - Testing components with selectors
