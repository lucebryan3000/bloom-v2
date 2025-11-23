---
id: nextjs-01-fundamentals
topic: nextjs
file_role: detailed
profile: full
difficulty_level: beginner
kb_version: 3.1
prerequisites: [react, javascript, nextjs-basics]
related_topics: ['react', 'typescript', 'web']
embedding_keywords: [nextjs]
last_reviewed: 2025-11-13
---

# Next.js Fundamentals

**Getting Started, Project Structure, and Core Concepts**

---

## Table of Contents
1. [Introduction](#introduction)
2. [Installation & Setup](#installation--setup)
3. [Project Structure](#project-structure)
4. [App Router vs Pages Router](#app-router-vs-pages-router)
5. [Server Components (Default)](#server-components-default)
6. [Client Components](#client-components)
7. [Layouts](#layouts)
8. [Pages](#pages)
9. [Navigation](#navigation)
10. [Core Directives](#core-directives)

---

## Introduction

### What is Next.js?

Next.js is a **React framework for building full-stack web applications**. It provides:

- **Automatic routing** based on file system
- **Server-side rendering (SSR)** out of the box
- **Static site generation (SSG)** support
- **API routes** for backend logic
- **Built-in optimization** (images, fonts, scripts)
- **TypeScript support** with zero config

### Key Benefits

✅ **Performance**: Automatic code splitting, image optimization, font optimization
✅ **SEO**: Server-side rendering for better search engine visibility
✅ **Developer Experience**: Hot reload, TypeScript, fast refresh
✅ **Full-Stack**: API routes, middleware, server actions
✅ **Production-Ready**: Built-in optimization and best practices

---

## Installation & Setup

### Create New Project

```bash
# Using npx (recommended)
npx create-next-app@latest my-app

# Using yarn
yarn create next-app my-app

# Using pnpm
pnpm create next-app my-app

# Using bun
bunx create-next-app my-app
```

### Interactive Setup

```bash
✔ Would you like to use TypeScript? … Yes
✔ Would you like to use ESLint? … Yes
✔ Would you like to use Tailwind CSS? … Yes
✔ Would you like to use `src/` directory? … No
✔ Would you like to use App Router? (recommended) … Yes
✔ Would you like to customize the default import alias? … No
```

### Manual Setup

```bash
npm install next@latest react@latest react-dom@latest
```

**package.json scripts:**
```json
{
 "scripts": {
 "dev": "next dev",
 "build": "next build",
 "start": "next start",
 "lint": "next lint"
 }
}
```

### Start Development Server

```bash
npm run dev
# Server running on http://localhost:3000
```

---

## Project Structure

### Default App Router Structure

```
my-next-app/
├── app/ # App Router directory (Next.js 13+)
│ ├── layout.tsx # Root layout (required)
│ ├── page.tsx # Home page (/)
│ ├── loading.tsx # Loading UI
│ ├── error.tsx # Error UI
│ ├── not-found.tsx # 404 page
│ ├── global.css # Global styles
│ │
│ ├── dashboard/ # Route: /dashboard
│ │ ├── layout.tsx # Dashboard layout
│ │ ├── page.tsx # Dashboard page
│ │ └── settings/ # Route: /dashboard/settings
│ │ └── page.tsx
│ │
│ └── api/ # API routes
│ └── users/
│ └── route.ts # API: /api/users
│
├── public/ # Static files
│ ├── images/
│ ├── fonts/
│ └── favicon.ico
│
├── components/ # Reusable components
│ ├── ui/
│ └── shared/
│
├── lib/ # Utility functions
│ ├── db.ts
│ └── utils.ts
│
├── types/ # TypeScript types
│ └── index.ts
│
├── middleware.ts # Middleware (optional)
├── next.config.js # Next.js configuration
├── tsconfig.json # TypeScript config
├── tailwind.config.ts # Tailwind config
└── package.json
```

### Key Directories

| Directory | Purpose | Required |
|-----------|---------|----------|
| `app/` | App Router pages and layouts | ✅ Yes |
| `public/` | Static assets served from `/` | ❌ Optional |
| `components/` | Reusable React components | ❌ Optional |
| `lib/` | Utility functions | ❌ Optional |
| `middleware.ts` | Request middleware | ❌ Optional |

### File Conventions

| File | Purpose |
|------|---------|
| `layout.tsx` | Shared UI for a segment |
| `page.tsx` | Unique page UI |
| `loading.tsx` | Loading UI |
| `error.tsx` | Error UI |
| `not-found.tsx` | 404 UI |
| `route.ts` | API endpoint |
| `template.tsx` | Re-rendered layout |
| `default.tsx` | Parallel route fallback |

---

## App Router vs Pages Router

### App Router (Recommended - Next.js 13+)

**Location**: `app/` directory

**Features**:
- ✅ Server Components by default
- ✅ Layouts and nested routing
- ✅ Streaming and Suspense
- ✅ Server Actions
- ✅ Better data fetching
- ✅ React 19 features

**Example**:
```typescript
// app/page.tsx
export default function HomePage {
 return <h1>Home Page</h1>;
}

// app/about/page.tsx
export default function AboutPage {
 return <h1>About Page</h1>;
}
```

### Pages Router (Legacy - Next.js 12 and earlier)

**Location**: `pages/` directory

**Features**:
- ✅ File-based routing
- ✅ API routes in `pages/api/`
- ✅ `getServerSideProps`, `getStaticProps`
- ⚠️ No Server Components
- ⚠️ No Streaming

**Example**:
```typescript
// pages/index.tsx
export default function HomePage {
 return <h1>Home Page</h1>;
}

// pages/about.tsx
export default function AboutPage {
 return <h1>About Page</h1>;
}
```

### When to Use Each

| Use Case | Router |
|----------|--------|
| New projects | **App Router** |
| Modern features (Server Components) | **App Router** |
| Legacy projects | **Pages Router** |
| Gradual migration | **Both** (incremental adoption) |

---

## Server Components (Default)

### What are Server Components?

Server Components render **on the server only**. They:

- ✅ Reduce JavaScript bundle size
- ✅ Access backend resources directly
- ✅ Better SEO and initial load
- ❌ Cannot use React hooks (`useState`, `useEffect`)
- ❌ Cannot use browser APIs
- ❌ Cannot use event handlers

### Default Behavior

**All components in `app/` are Server Components by default:**

```typescript
// app/components/UserList.tsx
// This is a Server Component (default)

async function getUsers {
 const res = await fetch('https://api.example.com/users');
 return res.json;
}

export default async function UserList {
 const users = await getUsers;

 return (
 <ul>
 {users.map(user => (
 <li key={user.id}>{user.name}</li>
 ))}
 </ul>
 );
}
```

### Benefits of Server Components

```typescript
// ✅ Direct database access
import { db } from '@/lib/db';

export default async function PostsPage {
 const posts = await db.post.findMany;

 return (
 <div>
 {posts.map(post => (
 <article key={post.id}>{post.title}</article>
 ))}
 </div>
 );
}

// ✅ No API route needed
// ✅ No client-side fetch
// ✅ Faster initial render
// ✅ Better SEO
```

---

## Client Components

### What are Client Components?

Client Components render **on both server and client**. Use them for:

- ✅ Interactivity (click handlers, forms)
- ✅ React hooks (`useState`, `useEffect`, `useContext`)
- ✅ Browser APIs (`localStorage`, `window`)
- ✅ Event listeners

### The `"use client"` Directive

**Add `"use client"` at the top of the file:**

```typescript
// components/Counter.tsx
'use client'; // This directive makes it a Client Component

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
// ❌ Don't use for static content
'use client';
export default function Header {
 return <header>My Site</header>;
}

// ✅ Use for interactivity
'use client';
import { useState } from 'react';

export default function SearchBar {
 const [query, setQuery] = useState('');

 return (
 <input
 value={query}
 onChange={(e) => setQuery(e.target.value)}
 placeholder="Search..."
 />
 );
}

// ✅ Use for React hooks
'use client';
import { useEffect } from 'react';

export default function Analytics {
 useEffect( => {
 // Track page view
 window.gtag('event', 'page_view');
 }, []);

 return null;
}
```

### Composition Pattern

**Keep Server Components as parents:**

```typescript
// app/page.tsx (Server Component)
import ClientButton from '@/components/ClientButton'; // Client Component

export default function HomePage {
 // Server-side data fetching
 const data = await fetchData;

 return (
 <div>
 <h1>Server Rendered Content</h1>
 <ClientButton /> {/* Client Component for interactivity */}
 </div>
 );
}
```

---

## Layouts

### Root Layout (Required)

**Every app needs a root layout:**

```typescript
// app/layout.tsx
export default function RootLayout({
 children,
}: {
 children: React.ReactNode;
}) {
 return (
 <html lang="en">
 <body>
 <header>My Site</header>
 <main>{children}</main>
 <footer>© 2025</footer>
 </body>
 </html>
 );
}
```

### Nested Layouts

```typescript
// app/dashboard/layout.tsx
export default function DashboardLayout({
 children,
}: {
 children: React.ReactNode;
}) {
 return (
 <div className="dashboard">
 <aside>Sidebar</aside>
 <main>{children}</main>
 </div>
 );
}
```

**URL**: `/dashboard/settings`

**Rendered**:
```
Root Layout
 └── Dashboard Layout
 └── Settings Page
```

### Layouts Preserve State

Layouts **do not re-render** on navigation within the same segment.

```typescript
// app/dashboard/layout.tsx
'use client';
import { useState } from 'react';

export default function DashboardLayout({ children }) {
 const [sidebarOpen, setSidebarOpen] = useState(true);

 // State persists when navigating between /dashboard pages
 return (
 <div>
 <Sidebar open={sidebarOpen} />
 {children}
 </div>
 );
}
```

---

## Pages

### Defining a Page

**A page is a UI unique to a route:**

```typescript
// app/page.tsx → Route: /
export default function HomePage {
 return <h1>Home</h1>;
}

// app/about/page.tsx → Route: /about
export default function AboutPage {
 return <h1>About</h1>;
}

// app/blog/[slug]/page.tsx → Route: /blog/hello-world
export default function BlogPost({ params }: { params: { slug: string } }) {
 return <h1>Blog Post: {params.slug}</h1>;
}
```

### Pages are Server Components by Default

```typescript
// app/posts/page.tsx
async function getPosts {
 const res = await fetch('https://api.example.com/posts');
 return res.json;
}

export default async function PostsPage {
 const posts = await getPosts;

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

## Navigation

### Link Component

**Use `next/link` for client-side navigation:**

```typescript
import Link from 'next/link';

export default function Navigation {
 return (
 <nav>
 <Link href="/">Home</Link>
 <Link href="/about">About</Link>
 <Link href="/blog">Blog</Link>
 </nav>
 );
}
```

### Dynamic Links

```typescript
const posts = [
 { id: 1, title: 'First Post' },
 { id: 2, title: 'Second Post' },
];

export default function PostList {
 return (
 <ul>
 {posts.map(post => (
 <li key={post.id}>
 <Link href={`/posts/${post.id}`}>
 {post.title}
 </Link>
 </li>
 ))}
 </ul>
 );
}
```

### Programmatic Navigation

```typescript
'use client';
import { useRouter } from 'next/navigation';

export default function LoginButton {
 const router = useRouter;

 const handleLogin = async => {
 // Perform login
 await login;

 // Navigate programmatically
 router.push('/dashboard');
 };

 return <button onClick={handleLogin}>Login</button>;
}
```

### Prefetching

Links are **automatically prefetched** in production:

```typescript
// Prefetch on hover (default)
<Link href="/about">About</Link>

// Disable prefetching
<Link href="/about" prefetch={false}>About</Link>
```

---

## Core Directives

### `"use client"`

Makes a component a Client Component:

```typescript
'use client';

import { useState } from 'react';

export default function Counter {
 const [count, setCount] = useState(0);
 return <button onClick={ => setCount(count + 1)}>{count}</button>;
}
```

### `"use server"`

Marks Server Actions (for mutations):

```typescript
// app/actions.ts
'use server';

export async function createPost(formData: FormData) {
 const title = formData.get('title');
 // Save to database
 await db.post.create({ data: { title } });
}
```

### `"use cache"` (Experimental)

Caches function results:

```typescript
'use cache';

export async function getUser(id: string) {
 return await db.user.findUnique({ where: { id } });
}
```

---

## Quick Reference

### File Structure

```typescript
app/
├── layout.tsx // Root layout (required)
├── page.tsx // Home page (/)
├── about/
│ └── page.tsx // /about
├── blog/
│ ├── layout.tsx // Blog layout
│ ├── page.tsx // /blog
│ └── [slug]/
│ └── page.tsx // /blog/:slug
└── api/
 └── users/
 └── route.ts // API: /api/users
```

### Component Types

```typescript
// Server Component (default)
export default async function ServerComponent {
 const data = await fetchData;
 return <div>{data}</div>;
}

// Client Component
'use client';
import { useState } from 'react';

export default function ClientComponent {
 const [state, setState] = useState(0);
 return <button onClick={ => setState(state + 1)}>{state}</button>;
}
```

### Navigation

```typescript
// Link component
import Link from 'next/link';
<Link href="/about">About</Link>

// Programmatic navigation
import { useRouter } from 'next/navigation';
const router = useRouter;
router.push('/dashboard');
```

---

## Common Patterns

### Mixing Server and Client Components

```typescript
// app/page.tsx (Server Component)
import ClientButton from '@/components/ClientButton';

export default async function HomePage {
 const data = await fetchData; // Server-side

 return (
 <div>
 <h1>Server Data: {data}</h1>
 <ClientButton /> {/* Client interactivity */}
 </div>
 );
}
```

### Passing Server Data to Client Components

```typescript
// Server Component
export default async function ProductPage({ params }) {
 const product = await getProduct(params.id);

 return <AddToCartButton product={product} />;
}

// Client Component
'use client';
export default function AddToCartButton({ product }) {
 const handleClick = => {
 // Use product data from server
 addToCart(product);
 };

 return <button onClick={handleClick}>Add to Cart</button>;
}
```

---

## Best Practices

### ✅ Do's

1. **Use Server Components by default** - Only add `"use client"` when needed
2. **Fetch data in Server Components** - Direct database access
3. **Keep Client Components small** - Minimize JavaScript bundle
4. **Compose Server and Client Components** - Pass data from server to client
5. **Use layouts for shared UI** - Avoid duplication

### ❌ Don'ts

1. **Don't use `"use client"` everywhere** - Increases bundle size
2. **Don't fetch data in Client Components** - Use Server Components
3. **Don't import Server Components into Client Components** - Won't work
4. **Don't use React hooks in Server Components** - Use Client Components

---

## Next Steps

Continue learning:

- **[02-ROUTING.md](./02-ROUTING.md)** - Dynamic routes, route groups, parallel routes
- **[03-DATA-FETCHING.md](./03-DATA-FETCHING.md)** - Server-side data fetching patterns
- **[04-RENDERING.md](./04-RENDERING.md)** - SSR, SSG, ISR strategies

---

**Last Updated**: November 9, 2025
**Next.js Version**: 16.0.1
**Status**: ✅ Production-Ready
