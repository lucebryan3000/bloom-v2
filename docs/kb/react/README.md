# React Knowledge Base

```yaml
id: react_readme
topic: React
file_role: Overview and entry point for React KB
profile: full
difficulty_level: all_levels
kb_version: v3.1
prerequisites: []
related_topics:
  - Next.js (../nextjs/)
  - TypeScript (../typescript/)
  - Testing (../testing/)
embedding_keywords:
  - react
  - react 19
  - hooks
  - components
  - jsx
  - state management
last_reviewed: 2025-11-16
```

## Welcome to React KB

Comprehensive knowledge base for **React 19.x** covering components, hooks, state, forms, performance, testing, and best practices.

**Total Content**: 15 files, ~7,500+ lines of production-ready patterns

---

## 📚 Documentation Structure

### **Quick Navigation**
- **[INDEX.md](./INDEX.md)** - Problem-based navigation
- **[QUICK-REFERENCE.md](./QUICK-REFERENCE.md)** - Quick syntax reference
- **[FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md)** - Framework integration

### **Core Files (11 Topics)**

| # | File | Topic | Level | Lines |
|---|------|-------|-------|-------|
| 01 | [FUNDAMENTALS.md](./01-FUNDAMENTALS.md) | Components, JSX, props | Beginner | 521 |
| 02 | [STATE.md](./02-STATE.md) | useState, state management | Beginner | 700 |
| 03 | [HOOKS.md](./03-HOOKS.md) | useEffect, useRef, useMemo, custom hooks | Intermediate | 800 |
| 04 | [EVENTS.md](./04-EVENTS.md) | Event handling, forms | Beginner | 700 |
| 05 | [CONTEXT.md](./05-CONTEXT.md) | Context API, providers | Intermediate | 600 |
| 06 | [PATTERNS.md](./06-PATTERNS.md) | Component patterns, composition | Advanced | 900 |
| 07 | [FORMS.md](./07-FORMS.md) | Form handling, validation | Intermediate | 900 |
| 08 | [PERFORMANCE.md](./08-PERFORMANCE.md) | Optimization, memoization | Advanced | 800 |
| 09 | [REACT-19.md](./09-REACT-19.md) | React 19 features, server components | Advanced | 700 |
| 10 | [TESTING.md](./10-TESTING.md) | Testing with React Testing Library | Intermediate | 650 |
| 11 | [BEST-PRACTICES.md](./11-BEST-PRACTICES.md) | Best practices, anti-patterns | Intermediate | 750 |

**Total**: ~7,500+ lines of React patterns and examples

---

## 🚀 Quick Start

### Installation

```bash
# React 19 with Next.js 16
npx create-next-app@latest my-app

# Or with Vite
npm create vite@latest my-app -- --template react-ts
```

### First Component

```typescript
interface GreetingProps {
  name: string;
  message?: string;
}

export function Greeting({ name, message = 'Hello' }: GreetingProps) {
  return (
    <div>
      <h1>{message}, {name}!</h1>
    </div>
  );
}

// Usage
<Greeting name="Alice" />
```

### State and Events

```typescript
import { useState } from 'react';

function Counter() {
  const [count, setCount] = useState(0);

  return (
    <div>
      <p>Count: {count}</p>
      <button onClick={() => setCount(c => c + 1)}>
        Increment
      </button>
    </div>
  );
}
```

---

## 📖 Learning Paths

### **Path 1: Beginner (New to React)**

1. [FUNDAMENTALS.md](./01-FUNDAMENTALS.md) - Components, JSX, props
2. [STATE.md](./02-STATE.md) - useState and state management
3. [EVENTS.md](./04-EVENTS.md) - Event handling
4. [FORMS.md](./07-FORMS.md) - Form handling basics
5. [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) - Syntax reference

**Time**: 4-6 hours | **Outcome**: Build basic interactive UIs

### **Path 2: Intermediate (Know basics, need depth)**

1. [HOOKS.md](./03-HOOKS.md) - useEffect, useRef, custom hooks
2. [CONTEXT.md](./05-CONTEXT.md) - Context API for global state
3. [PATTERNS.md](./06-PATTERNS.md) - Component patterns
4. [PERFORMANCE.md](./08-PERFORMANCE.md) - Optimization techniques
5. [TESTING.md](./10-TESTING.md) - Component testing

**Time**: 6-8 hours | **Outcome**: Production-ready React skills

### **Path 3: Advanced (Modern React)**

1. [REACT-19.md](./09-REACT-19.md) - React 19 features
2. [PERFORMANCE.md](./08-PERFORMANCE.md) - Advanced optimization
3. [PATTERNS.md](./06-PATTERNS.md) - Advanced patterns
4. [BEST-PRACTICES.md](./11-BEST-PRACTICES.md) - Code quality
5. [Next.js KB](../nextjs/) - Server components, routing

**Time**: 8-12 hours | **Outcome**: Expert-level React architecture

---

## 🎯 Common Tasks

### "I need to manage state"
→ [STATE.md](./02-STATE.md) - useState patterns
→ [CONTEXT.md](./05-CONTEXT.md) - Global state

### "I need side effects"
→ [HOOKS.md](./03-HOOKS.md) - useEffect guide
→ [QUICK-REFERENCE.md](./QUICK-REFERENCE.md#hooks)

### "I need to handle forms"
→ [FORMS.md](./07-FORMS.md) - Form patterns
→ [EVENTS.md](./04-EVENTS.md) - Event handling

### "My app is slow"
→ [PERFORMANCE.md](./08-PERFORMANCE.md) - Optimization
→ [REACT-19.md](./09-REACT-19.md) - Server components

### "I need to test components"
→ [TESTING.md](./10-TESTING.md) - React Testing Library

### "What's new in React 19?"
→ [REACT-19.md](./09-REACT-19.md) - Latest features

---

## 🔑 Key Concepts

### 1. Components are Functions

```typescript
// ✅ Modern React - functional components
function UserCard({ user }: Props) {
  return <div>{user.name}</div>;
}

// ❌ Avoid - class components (legacy)
class UserCard extends React.Component {
  render() {
    return <div>{this.props.user.name}</div>;
  }
}
```

### 2. State Updates are Async

```typescript
// ✅ GOOD - Functional update
setCount(prev => prev + 1);

// ❌ BAD - Direct reference (may be stale)
setCount(count + 1);
```

### 3. Effects Run After Render

```typescript
useEffect(() => {
  // Runs after render
  document.title = `Count: ${count}`;
}, [count]);
```

### 4. Props are Immutable

```typescript
// ✅ GOOD - Don't mutate props
function Component({ data }: Props) {
  const modified = { ...data, active: true };
  return <div>{modified.name}</div>;
}

// ❌ BAD - Never mutate props
function Component({ data }: Props) {
  data.active = true; // ERROR!
  return <div>{data.name}</div>;
}
```

### 5. Keys Must be Stable

```typescript
// ✅ GOOD - Use stable IDs
{items.map(item => (
  <Item key={item.id} data={item} />
))}

// ❌ BAD - Index as key
{items.map((item, index) => (
  <Item key={index} data={item} />
))}
```

---

## ⚡ React 19 Features

### Actions

```typescript
'use client';

import { useActionState } from 'react';

function Form() {
  const [state, formAction] = useActionState(submitForm, { message: '' });

  return (
    <form action={formAction}>
      <input name="email" />
      <button type="submit">Submit</button>
      {state.error && <p>{state.error}</p>}
    </form>
  );
}
```

### useOptimistic

```typescript
function TodoList({ todos }: Props) {
  const [optimisticTodos, addOptimisticTodo] = useOptimistic(
    todos,
    (state, newTodo) => [...state, { ...newTodo, sending: true }]
  );

  return (
    <ul>
      {optimisticTodos.map(todo => (
        <li key={todo.id}>{todo.text}</li>
      ))}
    </ul>
  );
}
```

### Server Components

```typescript
// app/posts/page.tsx - Server Component
export default async function PostsPage() {
  const posts = await db.post.findMany(); // Runs on server

  return (
    <div>
      {posts.map(post => (
        <article key={post.id}>{post.title}</article>
      ))}
    </div>
  );
}
```

---

## ⚠️ Common Pitfalls

### ❌ N+1 Re-renders

```typescript
// BAD - New function every render
<button onClick={() => handleClick(id)}>Click</button>

// GOOD - Memoized callback
const handleClick = useCallback((id) => { /*...*/ }, []);
<button onClick={() => handleClick(id)}>Click</button>
```

### ❌ Missing Dependencies

```typescript
// BAD - Missing userId
useEffect(() => {
  fetchUser(userId);
}, []);

// GOOD - All dependencies
useEffect(() => {
  fetchUser(userId);
}, [userId]);
```

### ❌ Mutating State

```typescript
// BAD - Direct mutation
users.push(newUser);
setUsers(users);

// GOOD - New array
setUsers([...users, newUser]);
```

---

## 🔧 Configuration

### tsconfig.json

```json
{
  "compilerOptions": {
    "jsx": "preserve",
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "strict": true,
    "esModuleInterop": true
  }
}
```

---

## 📊 Files in This Directory

```
docs/kb/react/
├── README.md                           # Overview (this file)
├── INDEX.md                            # Problem-based navigation
├── QUICK-REFERENCE.md                  # Syntax cheat sheet
├── FRAMEWORK-INTEGRATION-PATTERNS.md   # Framework integration
├── 01-FUNDAMENTALS.md                  # Components, JSX, props
├── 02-STATE.md                         # useState, state management
├── 03-HOOKS.md                         # useEffect, useRef, custom hooks
├── 04-EVENTS.md                        # Event handling
├── 05-CONTEXT.md                       # Context API
├── 06-PATTERNS.md                      # Component patterns
├── 07-FORMS.md                         # Form handling
├── 08-PERFORMANCE.md                   # Optimization
├── 09-REACT-19.md                      # React 19 features
├── 10-TESTING.md                       # Testing
└── 11-BEST-PRACTICES.md                # Best practices
```

---

## 🌐 External Resources

- **Official Docs**: https://react.dev
- **React 19 Blog**: https://react.dev/blog/2024/12/05/react-19
- **Next.js**: https://nextjs.org/docs
- **TypeScript Cheatsheet**: https://react-typescript-cheatsheet.netlify.app/

---

**Last Updated**: November 16, 2025
**React Version**: 19.x
**Total Lines**: 7,500+
**Status**: Production-Ready ✅

---

## Next Steps

1. **New to React?** → Start with [FUNDAMENTALS.md](./01-FUNDAMENTALS.md)
2. **Need quick syntax?** → Check [QUICK-REFERENCE.md](./QUICK-REFERENCE.md)
3. **Building modern apps?** → Review [REACT-19.md](./09-REACT-19.md)
4. **Want best practices?** → Read [BEST-PRACTICES.md](./11-BEST-PRACTICES.md)

Happy coding! ⚛️
