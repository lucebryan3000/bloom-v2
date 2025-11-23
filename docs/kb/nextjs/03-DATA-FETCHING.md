---
id: nextjs-03-data-fetching
topic: nextjs
file_role: detailed
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [react, javascript, nextjs-basics]
related_topics: ['react', 'typescript', 'web']
embedding_keywords: [nextjs]
last_reviewed: 2025-11-13
---

# Next.js Data Fetching: Server & Client Patterns

**Part 3 of 11 - The Next.js Knowledge Base**

## Table of Contents
1. [Server Components Data Fetching](#server-components-data-fetching)
2. [Client Components Data Fetching](#client-components-data-fetching)
3. [fetch API & Caching](#fetch-api--caching)
4. [Revalidation Strategies](#revalidation-strategies)
5. [Server Actions](#server-actions)
6. [Streaming with Suspense](#streaming-with-suspense)
7. [Error Handling](#error-handling)
8. [Loading States](#loading-states)
9. [Real-World Patterns](#real-world-patterns)
10. [Best Practices](#best-practices)

---

## Server Components Data Fetching

### Why Server Components?

Server Components fetch data on the server, offering:
- **Direct database access** without API routes
- **Secure API keys** never exposed to client
- **Reduced bundle size** by keeping code on server
- **Better performance** with server-side data fetching

### Basic Server Component Data Fetching

```typescript
// app/posts/page.tsx (Server Component by default)
interface Post {
 id: number;
 title: string;
 body: string;
}

export default async function PostsPage {
 // Fetch data directly in component
 const res = await fetch('https://api.example.com/posts');
 const posts: Post[] = await res.json;

 return (
 <div>
 <h1>Posts</h1>
 <ul>
 {posts.map(post => (
 <li key={post.id}>{post.title}</li>
 ))}
 </ul>
 </div>
 );
}
```

### Direct Database Access

```typescript
// app/users/page.tsx
import { prisma } from '@/lib/db';

export default async function UsersPage {
 // Direct Prisma query (this project uses this pattern)
 const users = await prisma.user.findMany({
 select: {
 id: true,
 name: true,
 email: true,
 },
 orderBy: {
 createdAt: 'desc',
 },
 });

 return (
 <div>
 <h1>Users</h1>
 <UserList users={users} />
 </div>
 );
}
```

### Parallel Data Fetching

```typescript
// app/dashboard/page.tsx
async function getRevenue {
 const res = await fetch('https://api.example.com/revenue');
 return res.json;
}

async function getUsers {
 const res = await fetch('https://api.example.com/users');
 return res.json;
}

async function getMetrics {
 const res = await fetch('https://api.example.com/metrics');
 return res.json;
}

export default async function DashboardPage {
 // Fetch all data in parallel
 const [revenue, users, metrics] = await Promise.all([
 getRevenue,
 getUsers,
 getMetrics,
 ]);

 return (
 <div>
 <RevenueChart data={revenue} />
 <UserStats data={users} />
 <MetricsGrid data={metrics} />
 </div>
 );
}
```

### Sequential Data Fetching

```typescript
// app/user/[id]/page.tsx
export default async function UserPage({
 params,
}: {
 params: { id: string };
}) {
 // Fetch user first
 const user = await fetch(`https://api.example.com/users/${params.id}`)
.then(res => res.json);

 // Then fetch user's posts (depends on user data)
 const posts = await fetch(`https://api.example.com/users/${user.id}/posts`)
.then(res => res.json);

 return (
 <div>
 <h1>{user.name}</h1>
 <PostList posts={posts} />
 </div>
 );
}
```

### Deduplication

Next.js automatically deduplicates identical requests:

```typescript
// These three identical requests will only execute once
async function getPost(id: string) {
 return fetch(`https://api.example.com/posts/${id}`);
}

export default async function Page {
 const post1 = await getPost('1'); // Executes
 const post2 = await getPost('1'); // Deduplicated
 const post3 = await getPost('1'); // Deduplicated

 // Only one network request is made
}
```

---

## Client Components Data Fetching

### When to Use Client Components

Use Client Components for data fetching when you need:
- User interactions (forms, buttons)
- Browser APIs (localStorage, window)
- React hooks (useState, useEffect)
- Event listeners

### SWR Pattern (Recommended)

```typescript
'use client';

import useSWR from 'swr';

const fetcher = (url: string) => fetch(url).then(res => res.json);

export default function Profile {
 const { data, error, isLoading } = useSWR('/api/user', fetcher);

 if (error) return <div>Failed to load</div>;
 if (isLoading) return <div>Loading...</div>;

 return <div>Hello, {data.name}!</div>;
}
```

### SWR with TypeScript

```typescript
'use client';

import useSWR from 'swr';

interface User {
 id: number;
 name: string;
 email: string;
}

const fetcher = (url: string) => fetch(url).then(res => res.json);

export default function UserProfile {
 const { data, error, isLoading } = useSWR<User>('/api/user', fetcher);

 if (error) return <div>Error: {error.message}</div>;
 if (isLoading) return <div>Loading...</div>;
 if (!data) return null;

 return (
 <div>
 <h1>{data.name}</h1>
 <p>{data.email}</p>
 </div>
 );
}
```

### SWR Advanced Features

```typescript
'use client';

import useSWR from 'swr';

export default function UserList {
 const { data, error, isLoading, mutate } = useSWR('/api/users', fetcher, {
 // Revalidate on focus
 revalidateOnFocus: true,

 // Revalidate on reconnect
 revalidateOnReconnect: true,

 // Refresh interval (ms)
 refreshInterval: 5000,

 // Retry on error
 errorRetryCount: 3,

 // Dedupe requests within 2 seconds
 dedupingInterval: 2000,
 });

 const handleRefresh = => {
 // Manually revalidate
 mutate;
 };

 return (
 <div>
 <button onClick={handleRefresh}>Refresh</button>
 {data && <UserList users={data} />}
 </div>
 );
}
```

### React Query Pattern

```typescript
'use client';

import { useQuery } from '@tanstack/react-query';

interface Post {
 id: number;
 title: string;
}

export default function Posts {
 const { data, error, isLoading } = useQuery({
 queryKey: ['posts'],
 queryFn: async => {
 const res = await fetch('/api/posts');
 if (!res.ok) throw new Error('Network response was not ok');
 return res.json as Promise<Post[]>;
 },
 });

 if (isLoading) return <div>Loading...</div>;
 if (error) return <div>Error: {error.message}</div>;

 return (
 <ul>
 {data?.map(post => (
 <li key={post.id}>{post.title}</li>
 ))}
 </ul>
 );
}
```

### useEffect Pattern (Basic)

```typescript
'use client';

import { useState, useEffect } from 'react';

interface User {
 id: number;
 name: string;
}

export default function UserComponent {
 const [user, setUser] = useState<User | null>(null);
 const [loading, setLoading] = useState(true);
 const [error, setError] = useState<string | null>(null);

 useEffect( => {
 fetch('/api/user')
.then(res => res.json)
.then(data => {
 setUser(data);
 setLoading(false);
 })
.catch(err => {
 setError(err.message);
 setLoading(false);
 });
 }, []);

 if (loading) return <div>Loading...</div>;
 if (error) return <div>Error: {error}</div>;
 if (!user) return null;

 return <div>Welcome, {user.name}</div>;
}
```

---

## fetch API & Caching

### Extended fetch API

Next.js extends the native fetch API with caching and revalidation:

```typescript
// Default: cache and revalidate
fetch('https://api.example.com/data');

// Force cache (default)
fetch('https://api.example.com/data', { cache: 'force-cache' });

// Never cache
fetch('https://api.example.com/data', { cache: 'no-store' });

// Revalidate every 60 seconds
fetch('https://api.example.com/data', { next: { revalidate: 60 } });

// Tag-based revalidation
fetch('https://api.example.com/data', { next: { tags: ['posts'] } });
```

### Cache Options

```typescript
// ✅ Static Data (default)
// Cached indefinitely
fetch('https://api.example.com/config', {
 cache: 'force-cache'
});

// ✅ Dynamic Data
// Never cached
fetch('https://api.example.com/live-prices', {
 cache: 'no-store'
});

// ✅ Time-based Revalidation
// Cache for 60 seconds, then revalidate
fetch('https://api.example.com/news', {
 next: { revalidate: 60 }
});

// ✅ On-demand Revalidation
// Cache with tag for manual revalidation
fetch('https://api.example.com/posts', {
 next: { tags: ['posts'] }
});
```

### Request Memoization

```typescript
// These requests are memoized during the render
async function getUser(id: string) {
 return fetch(`/api/users/${id}`);
}

export default async function Page {
 // Only one request is made
 const user1 = await getUser('1');
 const user2 = await getUser('1');
 const user3 = await getUser('1');
}
```

---

## Revalidation Strategies

### Time-based Revalidation

```typescript
// Revalidate every hour (3600 seconds)
export default async function NewsPage {
 const res = await fetch('https://api.example.com/news', {
 next: { revalidate: 3600 }
 });
 const news = await res.json;

 return <NewsList news={news} />;
}

// Or at route segment level
export const revalidate = 3600; // 1 hour

export default async function Page {
 const data = await fetch('https://api.example.com/data');
 return <div>{/*... */}</div>;
}
```

### On-demand Revalidation

```typescript
// app/api/revalidate/route.ts
import { revalidateTag, revalidatePath } from 'next/cache';
import { NextRequest, NextResponse } from 'next/server';

export async function POST(request: NextRequest) {
 const { tag, path } = await request.json;

 if (tag) {
 // Revalidate specific tag
 revalidateTag(tag);
 return NextResponse.json({ revalidated: true, tag });
 }

 if (path) {
 // Revalidate specific path
 revalidatePath(path);
 return NextResponse.json({ revalidated: true, path });
 }

 return NextResponse.json({ revalidated: false });
}

// Usage in Server Component
fetch('https://api.example.com/posts', {
 next: { tags: ['posts'] }
});

// Trigger revalidation
await fetch('/api/revalidate', {
 method: 'POST',
 body: JSON.stringify({ tag: 'posts' }),
});
```

### Route Segment Config

```typescript
// app/blog/page.tsx
// This applies to all data fetching in this route
export const revalidate = 60; // Revalidate every 60 seconds
export const dynamic = 'force-dynamic'; // Always dynamic
export const fetchCache = 'force-no-store'; // Never cache

export default async function BlogPage {
 const posts = await fetch('https://api.example.com/posts');
 return <PostList posts={posts} />;
}
```

### Segment Config Options

```typescript
// Dynamic behavior
export const dynamic = 'auto'; // Default
export const dynamic = 'force-dynamic'; // Always SSR
export const dynamic = 'force-static'; // Always SSG
export const dynamic = 'error'; // Error if dynamic

// Fetch caching
export const fetchCache = 'auto'; // Default
export const fetchCache = 'force-cache'; // Always cache
export const fetchCache = 'force-no-store'; // Never cache
export const fetchCache = 'only-cache'; // Only cached data
export const fetchCache = 'only-no-store'; // Only fresh data

// Revalidation
export const revalidate = false; // Infinite
export const revalidate = 0; // Never cache
export const revalidate = 60; // Every 60 seconds

// Runtime
export const runtime = 'nodejs'; // Default
export const runtime = 'edge'; // Edge runtime
```

---

## Server Actions

### What are Server Actions?

Server Actions are async functions that run on the server, callable from Client or Server Components.

### Basic Server Action

```typescript
// app/actions.ts
'use server';

export async function createPost(formData: FormData) {
 const title = formData.get('title') as string;
 const content = formData.get('content') as string;

 // Validate
 if (!title || !content) {
 throw new Error('Title and content are required');
 }

 // Save to database
 await db.post.create({
 data: { title, content },
 });

 // Revalidate
 revalidatePath('/posts');
}
```

### Using Server Actions in Forms

```typescript
// app/posts/new/page.tsx
import { createPost } from '@/app/actions';

export default function NewPostPage {
 return (
 <form action={createPost}>
 <input type="text" name="title" placeholder="Title" required />
 <textarea name="content" placeholder="Content" required />
 <button type="submit">Create Post</button>
 </form>
 );
}
```

### Server Actions with useFormState

```typescript
// app/actions.ts
'use server';

export async function createUser(prevState: any, formData: FormData) {
 const name = formData.get('name') as string;
 const email = formData.get('email') as string;

 try {
 await db.user.create({
 data: { name, email },
 });
 return { success: true, message: 'User created!' };
 } catch (error) {
 return { success: false, message: 'Failed to create user' };
 }
}

// app/users/new/page.tsx
'use client';

import { useFormState } from 'react-dom';
import { createUser } from '@/app/actions';

export default function NewUserPage {
 const [state, formAction] = useFormState(createUser, null);

 return (
 <form action={formAction}>
 <input type="text" name="name" required />
 <input type="email" name="email" required />
 <button type="submit">Create User</button>
 {state?.message && <p>{state.message}</p>}
 </form>
 );
}
```

### Server Actions with useFormStatus

```typescript
// app/components/SubmitButton.tsx
'use client';

import { useFormStatus } from 'react-dom';

export function SubmitButton {
 const { pending } = useFormStatus;

 return (
 <button type="submit" disabled={pending}>
 {pending ? 'Submitting...': 'Submit'}
 </button>
 );
}

// app/posts/new/page.tsx
import { createPost } from '@/app/actions';
import { SubmitButton } from '@/app/components/SubmitButton';

export default function NewPostPage {
 return (
 <form action={createPost}>
 <input type="text" name="title" />
 <textarea name="content" />
 <SubmitButton />
 </form>
 );
}
```

### Programmatic Server Actions

```typescript
'use client';

import { useTransition } from 'react';
import { deletePost } from '@/app/actions';

export function DeleteButton({ postId }: { postId: string }) {
 const [isPending, startTransition] = useTransition;

 const handleDelete = => {
 startTransition(async => {
 await deletePost(postId);
 });
 };

 return (
 <button onClick={handleDelete} disabled={isPending}>
 {isPending ? 'Deleting...': 'Delete'}
 </button>
 );
}
```

---

## Streaming with Suspense

### Basic Streaming

```typescript
// app/dashboard/page.tsx
import { Suspense } from 'react';

async function Revenue {
 const data = await fetchRevenue; // Slow
 return <RevenueChart data={data} />;
}

async function Users {
 const data = await fetchUsers; // Fast
 return <UserList data={data} />;
}

export default function DashboardPage {
 return (
 <div>
 {/* Users load immediately */}
 <Suspense fallback={<UsersSkeleton />}>
 <Users />
 </Suspense>

 {/* Revenue streams in when ready */}
 <Suspense fallback={<RevenueSkeleton />}>
 <Revenue />
 </Suspense>
 </div>
 );
}
```

### Nested Suspense

```typescript
export default function Page {
 return (
 <Suspense fallback={<PageSkeleton />}>
 <Header />

 <Suspense fallback={<MainSkeleton />}>
 <MainContent />
 </Suspense>

 <Suspense fallback={<SidebarSkeleton />}>
 <Sidebar />
 </Suspense>
 </Suspense>
 );
}
```

### Suspense Best Practices

```typescript
// ✅ Good: Granular suspense boundaries
export default function Dashboard {
 return (
 <div>
 <Suspense fallback={<HeaderSkeleton />}>
 <Header />
 </Suspense>

 <Suspense fallback={<ChartSkeleton />}>
 <RevenueChart />
 </Suspense>

 <Suspense fallback={<TableSkeleton />}>
 <DataTable />
 </Suspense>
 </div>
 );
}

// ❌ Bad: Single suspense boundary
export default function Dashboard {
 return (
 <Suspense fallback={<FullPageSkeleton />}>
 <Header />
 <RevenueChart />
 <DataTable />
 </Suspense>
 );
}
```

---

## Error Handling

### Error Boundaries

```typescript
// app/dashboard/error.tsx
'use client';

export default function DashboardError({
 error,
 reset,
}: {
 error: Error & { digest?: string };
 reset: => void;
}) {
 return (
 <div>
 <h2>Something went wrong!</h2>
 <p>{error.message}</p>
 <button onClick={ => reset}>Try again</button>
 </div>
 );
}
```

### Try-Catch in Server Components

```typescript
export default async function PostsPage {
 try {
 const res = await fetch('https://api.example.com/posts');

 if (!res.ok) {
 throw new Error('Failed to fetch posts');
 }

 const posts = await res.json;
 return <PostList posts={posts} />;
 } catch (error) {
 return <div>Error: {error.message}</div>;
 }
}
```

### notFound Function

```typescript
import { notFound } from 'next/navigation';

export default async function PostPage({
 params,
}: {
 params: { id: string };
}) {
 const post = await fetchPost(params.id);

 if (!post) {
 notFound; // Renders nearest not-found.tsx
 }

 return <Post data={post} />;
}

// app/posts/[id]/not-found.tsx
export default function PostNotFound {
 return <div>Post not found</div>;
}
```

---

## Loading States

### loading.tsx Files

```typescript
// app/dashboard/loading.tsx
export default function DashboardLoading {
 return (
 <div className="space-y-4">
 <div className="h-8 bg-gray-200 rounded animate-pulse" />
 <div className="h-64 bg-gray-200 rounded animate-pulse" />
 </div>
 );
}
```

### Skeleton Components

```typescript
// components/Skeleton.tsx
export function PostSkeleton {
 return (
 <div className="animate-pulse space-y-4">
 <div className="h-4 bg-gray-200 rounded w-3/4" />
 <div className="h-4 bg-gray-200 rounded w-1/2" />
 <div className="h-20 bg-gray-200 rounded" />
 </div>
 );
}

// Usage
<Suspense fallback={<PostSkeleton />}>
 <Post id={id} />
</Suspense>
```

---

## Real-World Patterns

### the ROI Dashboard Pattern

```typescript
// app/roi/[reportId]/page.tsx
import { prisma } from '@/lib/db';
import { ROIDashboard } from '@/components/app/ROIDashboard';

export default async function ROIReportPage({
 params,
}: {
 params: { reportId: string };
}) {
 // Direct database access (this project pattern)
 const report = await prisma.rOIReport.findUnique({
 where: { id: params.reportId },
 include: {
 session: {
 include: {
 organization: true,
 },
 },
 },
 });

 if (!report) {
 notFound;
 }

 return <ROIDashboard report={report} />;
}
```

### Pagination Pattern

```typescript
export default async function PostsPage({
 searchParams,
}: {
 searchParams: { page?: string };
}) {
 const page = Number(searchParams.page) || 1;
 const perPage = 10;

 const [posts, total] = await Promise.all([
 prisma.post.findMany({
 skip: (page - 1) * perPage,
 take: perPage,
 }),
 prisma.post.count,
 ]);

 return (
 <div>
 <PostList posts={posts} />
 <Pagination page={page} total={total} perPage={perPage} />
 </div>
 );
}
```

### Search Pattern

```typescript
export default async function SearchPage({
 searchParams,
}: {
 searchParams: { q?: string };
}) {
 const query = searchParams.q || '';

 const results = await prisma.post.findMany({
 where: {
 OR: [
 { title: { contains: query, mode: 'insensitive' } },
 { content: { contains: query, mode: 'insensitive' } },
 ],
 },
 });

 return (
 <div>
 <SearchForm defaultValue={query} />
 <SearchResults results={results} />
 </div>
 );
}
```

---

## Best Practices

### ✅ DO

1. **Use Server Components for data fetching**
```typescript
// ✅ Fetch on server
export default async function Page {
 const data = await fetch('/api/data');
 return <Component data={data} />;
}
```

2. **Fetch in parallel when possible**
```typescript
const [users, posts] = await Promise.all([
 fetchUsers,
 fetchPosts,
]);
```

3. **Use appropriate cache strategies**
```typescript
// Static data
fetch(url, { cache: 'force-cache' });

// Dynamic data
fetch(url, { cache: 'no-store' });

// Time-based
fetch(url, { next: { revalidate: 60 } });
```

4. **Handle errors gracefully**
```typescript
// error.tsx for route-level errors
// try-catch for component-level errors
// notFound for missing resources
```

5. **Use Suspense for progressive loading**
```typescript
<Suspense fallback={<Skeleton />}>
 <AsyncComponent />
</Suspense>
```

### ❌ DON'T

1. **Don't fetch in Client Components unnecessarily**
```typescript
// ❌ Bad
'use client';
export default function Page {
 const [data, setData] = useState(null);
 useEffect( => {
 fetch('/api').then(r => r.json).then(setData);
 }, []);
}

// ✅ Good
export default async function Page {
 const data = await fetch('/api');
 return <Component data={data} />;
}
```

2. **Don't waterfall requests**
```typescript
// ❌ Sequential
const user = await fetchUser;
const posts = await fetchPosts; // Waits for user

// ✅ Parallel
const [user, posts] = await Promise.all([
 fetchUser,
 fetchPosts,
]);
```

3. **Don't ignore cache configuration**
```typescript
// ❌ Always dynamic when could be static
fetch(url, { cache: 'no-store' });

// ✅ Cache static data
fetch(url, { cache: 'force-cache' });
```

4. **Don't skip error handling**
```typescript
// ❌ No error handling
const data = await fetch(url);

// ✅ With error handling
try {
 const data = await fetch(url);
 if (!data.ok) throw new Error('Failed');
} catch (error) {
 // Handle error
}
```

---

## Summary

### Key Concepts
- **Server Components** fetch data on the server by default
- **fetch API** extended with caching and revalidation
- **Server Actions** enable server-side mutations
- **Suspense** enables progressive loading
- **Revalidation** supports time-based and on-demand strategies

### Caching Strategies
| Strategy | Usage | Example |
|----------|-------|---------|
| `force-cache` | Static data | Config, constants |
| `no-store` | Dynamic data | Live prices, user data |
| `revalidate: N` | Time-based | News (every 60s) |
| `tags` | On-demand | Posts (revalidate on edit) |

---

**Next**: [04-RENDERING.md](./04-RENDERING.md) - Learn about rendering strategies

**Last Updated**: November 9, 2025
**Status**: Production-Ready ✅
