---
id: nextjs-04-rendering
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

# Next.js Rendering: SSR, SSG, ISR, and CSR

**Part 4 of 11 - The Next.js Knowledge Base**

## Table of Contents
1. [Rendering Fundamentals](#rendering-fundamentals)
2. [Server-Side Rendering (SSR)](#server-side-rendering-ssr)
3. [Static Site Generation (SSG)](#static-site-generation-ssg)
4. [Incremental Static Regeneration (ISR)](#incremental-static-regeneration-isr)
5. [Client-Side Rendering (CSR)](#client-side-rendering-csr)
6. [Streaming and Suspense](#streaming-and-suspense)
7. [React Server Components](#react-server-components)
8. [Partial Prerendering](#partial-prerendering)
9. [When to Use Each Strategy](#when-to-use-each-strategy)
10. [Best Practices](#best-practices)

---

## Rendering Fundamentals

### What is Rendering?

Rendering converts React components into HTML that browsers can display. Next.js supports multiple rendering strategies:

- **SSR (Server-Side Rendering)**: Generate HTML on each request
- **SSG (Static Site Generation)**: Generate HTML at build time
- **ISR (Incremental Static Regeneration)**: Update static pages after build
- **CSR (Client-Side Rendering)**: Render in browser with JavaScript

### App Router vs Pages Router

```typescript
// App Router (default in Next.js 13+)
// Server Components by default
export default async function Page {
 const data = await fetch('...');
 return <div>{data.title}</div>;
}

// Pages Router (legacy)
// Client Components by default
export default function Page({ data }) {
 return <div>{data.title}</div>;
}

export async function getServerSideProps {
 const data = await fetch('...');
 return { props: { data } };
}
```

---

## Server-Side Rendering (SSR)

### What is SSR?

SSR generates HTML on the server for **each request**. Best for:
- Personalized content
- Real-time data
- SEO-critical pages with dynamic content

### SSR with App Router

```typescript
// app/dashboard/page.tsx
// Force dynamic rendering
export const dynamic = 'force-dynamic';

export default async function DashboardPage {
 // Fetched on every request
 const data = await fetch('https://api.example.com/user', {
 cache: 'no-store', // Don't cache
 });

 const user = await data.json;

 return (
 <div>
 <h1>Welcome, {user.name}</h1>
 <p>Last login: {new Date.toISOString}</p>
 </div>
 );
}
```

### SSR with Dynamic Data

```typescript
// app/user/[id]/page.tsx
export default async function UserPage({
 params,
}: {
 params: { id: string };
}) {
 // Fresh data on every request
 const user = await fetch(`https://api.example.com/users/${params.id}`, {
 cache: 'no-store',
 }).then(res => res.json);

 return (
 <div>
 <h1>{user.name}</h1>
 <p>{user.email}</p>
 </div>
 );
}
```

### SSR with Cookies/Headers

```typescript
// app/profile/page.tsx
import { cookies, headers } from 'next/headers';

export default async function ProfilePage {
 // Reading cookies/headers forces SSR
 const cookieStore = cookies;
 const token = cookieStore.get('token');

 const headersList = headers;
 const userAgent = headersList.get('user-agent');

 const user = await fetchUserWithToken(token?.value);

 return (
 <div>
 <h1>{user.name}</h1>
 <p>Browser: {userAgent}</p>
 </div>
 );
}
```

### SSR Performance Considerations

```typescript
// ✅ Good: Fetch only what you need
export default async function Page {
 const data = await fetch('/api/data', {
 cache: 'no-store',
 });
 return <Component data={data} />;
}

// ❌ Bad: Heavy computation on every request
export default async function Page {
 // Don't do this on SSR
 const result = await heavyComputation; // Slow!
 const data = await multipleSlowQueries; // Slow!
 return <Component data={data} />;
}

// ✅ Better: Cache heavy computations
export default async function Page {
 const result = await getCachedResult;
 return <Component data={result} />;
}
```

---

## Static Site Generation (SSG)

### What is SSG?

SSG generates HTML at **build time**. Best for:
- Content that doesn't change often
- Marketing pages
- Blog posts
- Documentation

### SSG with App Router

```typescript
// app/blog/page.tsx
// Static by default (no dynamic functions, cached fetch)
export default async function BlogPage {
 const posts = await fetch('https://api.example.com/posts', {
 cache: 'force-cache', // Default
 }).then(res => res.json);

 return (
 <div>
 <h1>Blog Posts</h1>
 <PostList posts={posts} />
 </div>
 );
}
```

### SSG with Dynamic Routes

```typescript
// app/blog/[slug]/page.tsx
interface Post {
 slug: string;
 title: string;
 content: string;
}

// Generate static paths at build time
export async function generateStaticParams {
 const posts: Post[] = await fetch('https://api.example.com/posts')
.then(res => res.json);

 return posts.map(post => ({
 slug: post.slug,
 }));
}

// Generate page for each slug
export default async function BlogPostPage({
 params,
}: {
 params: { slug: string };
}) {
 const post = await fetch(`https://api.example.com/posts/${params.slug}`)
.then(res => res.json);

 return (
 <article>
 <h1>{post.title}</h1>
 <div>{post.content}</div>
 </article>
 );
}
```

### Metadata Generation

```typescript
// app/blog/[slug]/page.tsx
import type { Metadata } from 'next';

// Generate metadata at build time
export async function generateMetadata({
 params,
}: {
 params: { slug: string };
}): Promise<Metadata> {
 const post = await fetch(`https://api.example.com/posts/${params.slug}`)
.then(res => res.json);

 return {
 title: post.title,
 description: post.excerpt,
 openGraph: {
 title: post.title,
 description: post.excerpt,
 images: [post.image],
 },
 };
}

export default async function BlogPostPage({
 params,
}: {
 params: { slug: string };
}) {
 const post = await fetch(`https://api.example.com/posts/${params.slug}`)
.then(res => res.json);

 return <article>{/*... */}</article>;
}
```

### Partial Static Generation

```typescript
// app/blog/page.tsx
export const dynamicParams = false; // Only generate specified paths

export async function generateStaticParams {
 // Generate only top 100 posts at build time
 const posts = await fetch('https://api.example.com/posts?limit=100')
.then(res => res.json);

 return posts.map(post => ({ slug: post.slug }));
}

// Other paths will 404
```

---

## Incremental Static Regeneration (ISR)

### What is ISR?

ISR updates static pages **after build** without rebuilding the entire site. Best for:
- Content that changes periodically
- E-commerce product pages
- News sites
- User-generated content

### Time-based Revalidation

```typescript
// app/products/page.tsx
export const revalidate = 60; // Revalidate every 60 seconds

export default async function ProductsPage {
 const products = await fetch('https://api.example.com/products')
.then(res => res.json);

 return <ProductList products={products} />;
}
```

### Per-fetch Revalidation

```typescript
// app/news/page.tsx
export default async function NewsPage {
 // Revalidate this fetch every 30 seconds
 const news = await fetch('https://api.example.com/news', {
 next: { revalidate: 30 },
 }).then(res => res.json);

 // This fetch cached indefinitely
 const categories = await fetch('https://api.example.com/categories', {
 cache: 'force-cache',
 }).then(res => res.json);

 return (
 <div>
 <NewsList news={news} />
 <CategoryFilter categories={categories} />
 </div>
 );
}
```

### On-demand Revalidation

```typescript
// app/api/revalidate/route.ts
import { revalidatePath, revalidateTag } from 'next/cache';
import { NextRequest, NextResponse } from 'next/server';

export async function POST(request: NextRequest) {
 const { path, tag } = await request.json;

 if (path) {
 // Revalidate specific path
 revalidatePath(path);
 return NextResponse.json({ revalidated: true, path });
 }

 if (tag) {
 // Revalidate all pages with tag
 revalidateTag(tag);
 return NextResponse.json({ revalidated: true, tag });
 }

 return NextResponse.json({ revalidated: false }, { status: 400 });
}

// Usage in another file
fetch('https://api.example.com/posts', {
 next: { tags: ['posts'] },
});

// Trigger revalidation
await fetch('http://localhost:3000/api/revalidate', {
 method: 'POST',
 body: JSON.stringify({ tag: 'posts' }),
});
```

### Tag-based Revalidation

```typescript
// app/posts/page.tsx
export default async function PostsPage {
 const posts = await fetch('https://api.example.com/posts', {
 next: { tags: ['posts'] },
 }).then(res => res.json);

 return <PostList posts={posts} />;
}

// app/posts/[id]/page.tsx
export default async function PostPage({ params }: { params: { id: string } }) {
 const post = await fetch(`https://api.example.com/posts/${params.id}`, {
 next: { tags: ['posts', `post-${params.id}`] },
 }).then(res => res.json);

 return <Post data={post} />;
}

// Revalidate all posts
revalidateTag('posts');

// Revalidate specific post
revalidateTag('post-123');
```

---

## Client-Side Rendering (CSR)

### What is CSR?

CSR renders content in the browser with JavaScript. Best for:
- Interactive dashboards
- Client-only features
- Real-time updates

### Client Components

```typescript
// app/components/Counter.tsx
'use client'; // Mark as Client Component

import { useState } from 'react';

export default function Counter {
 const [count, setCount] = useState(0);

 return (
 <div>
 <p>Count: {count}</p>
 <button onClick={ => setCount(count + 1)}>
 Increment
 </button>
 </div>
 );
}
```

### When to Use Client Components

```typescript
'use client';

import { useState, useEffect } from 'react';

export default function ClientFeatures {
 // ✅ Good use cases for Client Components:

 // 1. User interactions
 const [count, setCount] = useState(0);

 // 2. Browser APIs
 useEffect( => {
 const width = window.innerWidth;
 localStorage.setItem('key', 'value');
 }, []);

 // 3. Event listeners
 const handleClick = => {
 console.log('Clicked!');
 };

 // 4. React hooks
 const [isOpen, setIsOpen] = useState(false);

 return <div onClick={handleClick}>Interactive UI</div>;
}
```

### Mixing Server and Client Components

```typescript
// app/page.tsx (Server Component)
import ClientCounter from './ClientCounter';

export default async function Page {
 // Fetch on server
 const data = await fetch('https://api.example.com/data')
.then(res => res.json);

 return (
 <div>
 <h1>Server-rendered data: {data.title}</h1>

 {/* Client Component for interactivity */}
 <ClientCounter initialCount={data.count} />
 </div>
 );
}

// app/ClientCounter.tsx
'use client';

import { useState } from 'react';

export default function ClientCounter({ initialCount }: { initialCount: number }) {
 const [count, setCount] = useState(initialCount);

 return (
 <button onClick={ => setCount(count + 1)}>
 Count: {count}
 </button>
 );
}
```

---

## Streaming and Suspense

### Progressive Rendering

```typescript
// app/dashboard/page.tsx
import { Suspense } from 'react';

async function SlowComponent {
 await new Promise(resolve => setTimeout(resolve, 3000));
 return <div>Slow content loaded!</div>;
}

async function FastComponent {
 return <div>Fast content loaded!</div>;
}

export default function DashboardPage {
 return (
 <div>
 {/* Fast content shows immediately */}
 <Suspense fallback={<div>Loading fast...</div>}>
 <FastComponent />
 </Suspense>

 {/* Slow content streams in when ready */}
 <Suspense fallback={<div>Loading slow...</div>}>
 <SlowComponent />
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

 <Suspense fallback={<SidebarSkeleton />}>
 <Sidebar />
 </Suspense>

 <main>
 <Suspense fallback={<ContentSkeleton />}>
 <Content />
 </Suspense>
 </main>
 </Suspense>
 );
}
```

---

## React Server Components

### What are Server Components?

Server Components run **only on the server** and never send JavaScript to the client.

### Benefits

```typescript
// ✅ Server Component benefits:

// 1. Direct database access
import { prisma } from '@/lib/db';

export default async function Users {
 const users = await prisma.user.findMany;
 return <UserList users={users} />;
}

// 2. Keep sensitive data on server
const API_KEY = process.env.SECRET_KEY; // Never sent to client

// 3. Reduce bundle size
import heavyLibrary from 'heavy-library'; // Only runs on server

// 4. Better performance
const data = await fetchLargeDataset; // Processed on server
```

### Server vs Client Components

```typescript
// Server Component (default)
export default async function ServerComponent {
 const data = await fetch('...');
 return <div>{data.title}</div>;
}

// Client Component (opt-in)
'use client';

import { useState } from 'react';

export default function ClientComponent {
 const [count, setCount] = useState(0);
 return <button onClick={ => setCount(count + 1)}>{count}</button>;
}
```

---

## Partial Prerendering

### What is Partial Prerendering?

Partial Prerendering combines static and dynamic rendering in a single page (experimental feature).

```typescript
// next.config.js
module.exports = {
 experimental: {
 ppr: true,
 },
};

// app/product/[id]/page.tsx
import { Suspense } from 'react';

export default function ProductPage({ params }: { params: { id: string } }) {
 return (
 <div>
 {/* Static shell */}
 <header>Product Page</header>

 {/* Dynamic content */}
 <Suspense fallback={<ProductSkeleton />}>
 <ProductDetails id={params.id} />
 </Suspense>

 {/* Static footer */}
 <footer>Footer</footer>
 </div>
 );
}
```

---

## When to Use Each Strategy

### Decision Matrix

| Strategy | Use When | Examples |
|----------|----------|----------|
| **SSR** | Data changes per request | User dashboards, personalized content |
| **SSG** | Content rarely changes | Marketing pages, documentation |
| **ISR** | Periodic updates OK | Product pages, news articles |
| **CSR** | Client-only features | Interactive widgets, real-time updates |

### Strategy Examples

```typescript
// SSR: User Dashboard
export const dynamic = 'force-dynamic';

export default async function Dashboard {
 const user = await getCurrentUser;
 return <DashboardUI user={user} />;
}

// SSG: Blog Post
export async function generateStaticParams {
 const posts = await getPosts;
 return posts.map(p => ({ slug: p.slug }));
}

export default async function BlogPost({ params }) {
 const post = await getPost(params.slug);
 return <Article post={post} />;
}

// ISR: Product Page
export const revalidate = 60;

export default async function Product({ params }) {
 const product = await getProduct(params.id);
 return <ProductDetails product={product} />;
}

// CSR: Interactive Chart
'use client';

export default function Chart {
 const [data, setData] = useState([]);
 useEffect( => {
 // Fetch and update in browser
 }, []);
 return <ChartComponent data={data} />;
}
```

---

## Best Practices

### ✅ DO

1. **Use Server Components by default**
```typescript
// Default: Server Component
export default async function Page {
 const data = await fetchData;
 return <Component data={data} />;
}
```

2. **Use ISR for content that updates periodically**
```typescript
export const revalidate = 3600; // 1 hour

export default async function Page {
 const news = await fetchNews;
 return <NewsList news={news} />;
}
```

3. **Stream slow content with Suspense**
```typescript
<Suspense fallback={<Skeleton />}>
 <SlowContent />
</Suspense>
```

4. **Use Client Components only when needed**
```typescript
// Only for interactivity
'use client';

export default function Interactive {
 const [state, setState] = useState(0);
 return <button onClick={ => setState(s => s + 1)}>{state}</button>;
}
```

### ❌ DON'T

1. **Don't use SSR when SSG works**
```typescript
// ❌ Unnecessary SSR
export const dynamic = 'force-dynamic';

export default async function AboutPage {
 return <div>Static content</div>;
}

// ✅ Use SSG
export default function AboutPage {
 return <div>Static content</div>;
}
```

2. **Don't make everything a Client Component**
```typescript
// ❌ Bad
'use client';

export default function Page {
 // No interactivity, shouldn't be client
 return <div>Static content</div>;
}

// ✅ Good
export default function Page {
 return <div>Static content</div>;
}
```

3. **Don't fetch data in Client Components**
```typescript
// ❌ Bad
'use client';

export default function Page {
 const [data, setData] = useState(null);
 useEffect( => {
 fetch('/api/data').then(r => r.json).then(setData);
 }, []);
 return <div>{data?.title}</div>;
}

// ✅ Good
export default async function Page {
 const data = await fetch('/api/data');
 return <Component data={data} />;
}
```

---

## Summary

### Rendering Strategies
- **SSR**: Fresh data on every request (dynamic)
- **SSG**: Built once at build time (static)
- **ISR**: Static with periodic updates (best of both)
- **CSR**: Browser-side rendering (interactive)

### Key Decisions
1. Does content change per user? → **SSR**
2. Does content rarely change? → **SSG**
3. Can updates be delayed? → **ISR**
4. Need client interactions? → **CSR**

### Performance Tips
- Start with SSG/ISR when possible
- Use SSR only when necessary
- Stream slow content with Suspense
- Keep Client Components minimal

---

**Next**: [05-API-ROUTES.md](./05-API-ROUTES.md) - Learn about API route handlers

**Last Updated**: November 9, 2025
**Status**: Production-Ready ✅
