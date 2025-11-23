# React 19 Features

```yaml
id: react_09_react_19
topic: React
file_role: React 19 new features, server components, actions, use hook
profile: advanced
difficulty_level: advanced
kb_version: v3.1
prerequisites:
  - Fundamentals (01-FUNDAMENTALS.md)
  - State (02-STATE.md)
  - Hooks (03-HOOKS.md)
related_topics:
  - Performance (08-PERFORMANCE.md)
  - Next.js (../nextjs/)
embedding_keywords:
  - react 19
  - server components
  - react server components
  - use hook
  - useActionState
  - useOptimistic
  - actions
  - transitions
  - suspense
last_reviewed: 2025-11-16
```

## React 19 Overview

**Major Features:**
1. **Actions** - Handle async state transitions
2. **use Hook** - Read promises and context
3. **useActionState** - Manage action state
4. **useOptimistic** - Optimistic UI updates
5. **Server Components** - Render on server
6. **Document Metadata** - Built-in title/meta
7. **Ref as Prop** - Pass ref like normal prop
8. **Enhanced Suspense** - Better loading states

## Actions

### Basic Form Action

```typescript
'use client';

import { useActionState } from 'react';

async function submitForm(prevState: any, formData: FormData) {
  const name = formData.get('name') as string;
  const email = formData.get('email') as string;

  // Simulate API call
  await new Promise(resolve => setTimeout(resolve, 1000));

  if (!email.includes('@')) {
    return { error: 'Invalid email' };
  }

  return { success: true, message: 'Form submitted!' };
}

function ContactForm() {
  const [state, formAction] = useActionState(submitForm, { message: '' });

  return (
    <form action={formAction}>
      <input name="name" required />
      <input name="email" type="email" required />
      <button type="submit">Submit</button>

      {state.error && <p style={{ color: 'red' }}>{state.error}</p>}
      {state.success && <p style={{ color: 'green' }}>{state.message}</p>}
    </form>
  );
}
```

### Action with useTransition

```typescript
import { useTransition } from 'react';

function UpdateProfile() {
  const [isPending, startTransition] = useTransition();
  const [name, setName] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    startTransition(async () => {
      await updateProfile(name);
    });
  };

  return (
    <form onSubmit={handleSubmit}>
      <input value={name} onChange={(e) => setName(e.target.value)} />
      <button disabled={isPending}>
        {isPending ? 'Updating...' : 'Update'}
      </button>
    </form>
  );
}
```

## useActionState

### Managing Form State

```typescript
import { useActionState } from 'react';

interface FormState {
  error?: string;
  success?: boolean;
  message?: string;
}

async function createTodo(prevState: FormState, formData: FormData): Promise<FormState> {
  const text = formData.get('text') as string;

  if (!text || text.length < 3) {
    return { error: 'Todo must be at least 3 characters' };
  }

  try {
    await fetch('/api/todos', {
      method: 'POST',
      body: JSON.stringify({ text }),
      headers: { 'Content-Type': 'application/json' },
    });

    return { success: true, message: 'Todo created!' };
  } catch (error) {
    return { error: 'Failed to create todo' };
  }
}

function TodoForm() {
  const [state, formAction, isPending] = useActionState(createTodo, {});

  return (
    <form action={formAction}>
      <input name="text" placeholder="New todo" />
      <button type="submit" disabled={isPending}>
        {isPending ? 'Adding...' : 'Add Todo'}
      </button>

      {state.error && <p className="error">{state.error}</p>}
      {state.success && <p className="success">{state.message}</p>}
    </form>
  );
}
```

## useOptimistic

### Optimistic UI Updates

```typescript
import { useOptimistic } from 'react';

interface Todo {
  id: string;
  text: string;
  completed: boolean;
  sending?: boolean;
}

function TodoList({ todos }: { todos: Todo[] }) {
  const [optimisticTodos, addOptimisticTodo] = useOptimistic(
    todos,
    (state, newTodo: Todo) => [...state, { ...newTodo, sending: true }]
  );

  const handleSubmit = async (formData: FormData) => {
    const text = formData.get('text') as string;
    const newTodo: Todo = {
      id: crypto.randomUUID(),
      text,
      completed: false,
    };

    // Add optimistically (shows immediately)
    addOptimisticTodo(newTodo);

    // Actual API call
    await fetch('/api/todos', {
      method: 'POST',
      body: JSON.stringify(newTodo),
    });
  };

  return (
    <div>
      <form action={handleSubmit}>
        <input name="text" />
        <button type="submit">Add</button>
      </form>

      <ul>
        {optimisticTodos.map(todo => (
          <li key={todo.id} style={{ opacity: todo.sending ? 0.5 : 1 }}>
            {todo.text}
            {todo.sending && <span> (Sending...)</span>}
          </li>
        ))}
      </ul>
    </div>
  );
}
```

### Optimistic Updates with State

```typescript
function LikeButton({ postId, initialLikes }: Props) {
  const [likes, setLikes] = useState(initialLikes);
  const [optimisticLikes, addOptimisticLike] = useOptimistic(
    likes,
    (state, amount: number) => state + amount
  );

  const handleLike = async () => {
    // Show optimistic update immediately
    addOptimisticLike(1);

    try {
      const response = await fetch(`/api/posts/${postId}/like`, {
        method: 'POST',
      });
      const data = await response.json();

      // Update with real count
      setLikes(data.likes);
    } catch (error) {
      // Revert on error (happens automatically)
      console.error('Failed to like');
    }
  };

  return (
    <button onClick={handleLike}>
      ❤️ {optimisticLikes}
    </button>
  );
}
```

## use Hook

### Reading Promises

```typescript
import { use, Suspense } from 'react';

interface User {
  id: number;
  name: string;
}

async function fetchUser(id: number): Promise<User> {
  const response = await fetch(`/api/users/${id}`);
  return response.json();
}

function UserProfile({ userPromise }: { userPromise: Promise<User> }) {
  // use() reads the promise
  const user = use(userPromise);

  return <div>{user.name}</div>;
}

function App() {
  const userPromise = fetchUser(1);

  return (
    <Suspense fallback={<div>Loading user...</div>}>
      <UserProfile userPromise={userPromise} />
    </Suspense>
  );
}
```

### Reading Context

```typescript
import { use } from 'react';

const ThemeContext = createContext('light');

function ThemedButton() {
  // use() can read context
  const theme = use(ThemeContext);

  return <button className={theme}>Click me</button>;
}
```

### Conditional use

```typescript
function UserData({ userId }: { userId: number | null }) {
  // use() can be called conditionally (unlike other hooks!)
  if (userId === null) {
    return <div>No user selected</div>;
  }

  const user = use(fetchUser(userId));
  return <div>{user.name}</div>;
}
```

## Server Components

### Server Component (Default in Next.js 16)

```typescript
// app/posts/page.tsx - Runs on server
export default async function PostsPage() {
  // Fetch data on server
  const posts = await db.post.findMany({
    orderBy: { createdAt: 'desc' },
  });

  return (
    <div>
      <h1>Posts</h1>
      {posts.map(post => (
        <article key={post.id}>
          <h2>{post.title}</h2>
          <p>{post.content}</p>
        </article>
      ))}
    </div>
  );
}
```

### Client Component

```typescript
'use client'; // Mark as client component

import { useState } from 'react';

export function LikeButton({ postId }: { postId: number }) {
  const [likes, setLikes] = useState(0);

  return (
    <button onClick={() => setLikes(l => l + 1)}>
      ❤️ {likes}
    </button>
  );
}
```

### Mixing Server and Client

```typescript
// Server Component
export default async function PostPage({ params }: Props) {
  const post = await db.post.findUnique({
    where: { id: params.id },
  });

  return (
    <article>
      <h1>{post.title}</h1>
      <p>{post.content}</p>

      {/* Client component for interactivity */}
      <LikeButton postId={post.id} />
      <CommentForm postId={post.id} />
    </article>
  );
}
```

## Document Metadata

### Title and Meta Tags

```typescript
// app/page.tsx
export const metadata = {
  title: 'Home Page',
  description: 'Welcome to our site',
};

export default function HomePage() {
  return <div>Home</div>;
}

// Or dynamic metadata
export async function generateMetadata({ params }: Props) {
  const post = await db.post.findUnique({
    where: { id: params.id },
  });

  return {
    title: post.title,
    description: post.excerpt,
    openGraph: {
      title: post.title,
      description: post.excerpt,
      images: [post.coverImage],
    },
  };
}
```

### Document Title in Component

```typescript
import { useEffect } from 'react';

function DocumentTitleComponent() {
  useEffect(() => {
    document.title = 'New Page Title';
  }, []);

  return <div>Content</div>;
}
```

## Ref as Prop

### Pass Ref Like Normal Prop

```typescript
// React 19 - ref is a normal prop, no forwardRef needed
function Input({ ref, ...props }: { ref: React.Ref<HTMLInputElement> }) {
  return <input ref={ref} {...props} />;
}

// Usage
function Form() {
  const inputRef = useRef<HTMLInputElement>(null);

  const focusInput = () => {
    inputRef.current?.focus();
  };

  return (
    <div>
      <Input ref={inputRef} />
      <button onClick={focusInput}>Focus</button>
    </div>
  );
}

// React 18 (old way) - needed forwardRef
const Input = forwardRef<HTMLInputElement, Props>((props, ref) => {
  return <input ref={ref} {...props} />;
});
```

## Enhanced Suspense

### Nested Suspense Boundaries

```typescript
import { Suspense } from 'react';

function App() {
  return (
    <div>
      <Suspense fallback={<HeaderSkeleton />}>
        <Header />
      </Suspense>

      <Suspense fallback={<SidebarSkeleton />}>
        <Sidebar />
      </Suspense>

      <Suspense fallback={<ContentSkeleton />}>
        <MainContent />
      </Suspense>
    </div>
  );
}
```

### Error Boundaries with Suspense

```typescript
import { Suspense } from 'react';
import { ErrorBoundary } from 'react-error-boundary';

function App() {
  return (
    <ErrorBoundary fallback={<div>Error loading data</div>}>
      <Suspense fallback={<div>Loading...</div>}>
        <AsyncComponent />
      </Suspense>
    </ErrorBoundary>
  );
}
```

## Streaming

### Streaming Server Components

```typescript
// app/dashboard/page.tsx
export default async function Dashboard() {
  return (
    <div>
      <h1>Dashboard</h1>

      {/* Loads immediately */}
      <QuickStats />

      {/* Streams in when ready */}
      <Suspense fallback={<ChartSkeleton />}>
        <RevenueChart />
      </Suspense>

      <Suspense fallback={<TableSkeleton />}>
        <RecentOrders />
      </Suspense>
    </div>
  );
}

async function RevenueChart() {
  // Slow data fetch
  const data = await fetchRevenueData();
  return <Chart data={data} />;
}

async function RecentOrders() {
  // Another slow fetch
  const orders = await fetchOrders();
  return <OrderTable orders={orders} />;
}
```

## AI Pair Programming Notes

**When using React 19:**

1. **Actions**: Use for form submissions and async state
2. **useActionState**: Simplify form state management
3. **useOptimistic**: Show immediate feedback for better UX
4. **use hook**: Read promises and context, can be conditional
5. **Server Components**: Fetch data on server, reduce bundle size
6. **Client Components**: Use 'use client' for interactivity
7. **Metadata**: Use export metadata for SEO
8. **Ref as prop**: No more forwardRef in React 19
9. **Suspense**: Stream components for better perceived performance
10. **Transitions**: Use for non-urgent updates

**Common React 19 mistakes:**
- Not marking interactive components with 'use client'
- Using client components when server components would work
- Not wrapping async components in Suspense
- Missing error boundaries with Suspense
- Not using optimistic updates for better UX
- Forgetting to handle action errors
- Not streaming expensive components
- Using old forwardRef pattern (not needed in 19)
- Not leveraging server components for data fetching
- Missing metadata exports for SEO

## Next Steps

1. **10-TESTING.md** - Testing React 19 features
2. **11-BEST-PRACTICES.md** - Best practices and patterns
3. **Next.js KB** - Server components in Next.js

## Additional Resources

- React 19 Release: https://react.dev/blog/2024/12/05/react-19
- Server Components: https://react.dev/reference/react/use-server
- Actions: https://react.dev/reference/react-dom/components/form#handle-form-submission-with-a-server-action
- use Hook: https://react.dev/reference/react/use
- Next.js with React 19: https://nextjs.org/docs
