---
id: nextjs-02-routing
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

# Next.js Routing: App Router & File-Based Routing

**Part 2 of 11 - The Next.js Knowledge Base**

## Table of Contents
1. [App Router Fundamentals](#app-router-fundamentals)
2. [File-Based Routing](#file-based-routing)
3. [Dynamic Routes](#dynamic-routes)
4. [Route Groups](#route-groups)
5. [Parallel Routes](#parallel-routes)
6. [Intercepting Routes](#intercepting-routes)
7. [Route Handlers](#route-handlers)
8. [Middleware](#middleware)
9. [Navigation](#navigation)
10. [Best Practices](#best-practices)

---

## App Router Fundamentals

### What is the App Router?

The App Router is Next.js's modern routing system (introduced in Next.js 13+) that enables:
- **Server Components** by default
- **Nested layouts** and templates
- **Loading states** with Suspense
- **Error boundaries** built-in
- **Parallel and intercepting routes**

```typescript
// app/layout.tsx - Root layout (required)
export default function RootLayout({
 children,
}: {
 children: React.ReactNode;
}) {
 return (
 <html lang="en">
 <body>{children}</body>
 </html>
 );
}

// app/page.tsx - Home page (/)
export default function HomePage {
 return <h1>Welcome to Next.js App Router</h1>;
}
```

### Directory Structure

```
app/
├── layout.tsx # Root layout (required)
├── page.tsx # Home page (/)
├── loading.tsx # Loading UI
├── error.tsx # Error boundary
├── not-found.tsx # 404 page
├── global.css # Global styles
│
├── about/
│ └── page.tsx # /about
│
├── blog/
│ ├── layout.tsx # Blog layout
│ ├── page.tsx # /blog
│ └── [slug]/
│ └── page.tsx # /blog/[slug]
│
├── dashboard/
│ ├── layout.tsx # Dashboard layout
│ ├── page.tsx # /dashboard
│ ├── settings/
│ │ └── page.tsx # /dashboard/settings
│ └── analytics/
│ └── page.tsx # /dashboard/analytics
│
└── api/
 └── users/
 └── route.ts # API route: /api/users
```

---

## File-Based Routing

### Special Files

Next.js uses special file names to create UI:

| File | Purpose | Example |
|------|---------|---------|
| `layout.tsx` | Shared UI for segments | Navigation, sidebar |
| `page.tsx` | Unique page UI | Blog post, dashboard |
| `loading.tsx` | Loading fallback | Skeleton, spinner |
| `error.tsx` | Error boundary | Error message UI |
| `not-found.tsx` | 404 page | Custom 404 UI |
| `template.tsx` | Re-rendered layout | Per-route instance |
| `route.ts` | API endpoint | REST API handler |

### Page Files

```typescript
// app/page.tsx - Home page
export default function HomePage {
 return <h1>Home</h1>;
}

// app/about/page.tsx - About page
export default function AboutPage {
 return <h1>About Us</h1>;
}

// app/blog/page.tsx - Blog listing
export default function BlogPage {
 return <h1>Blog Posts</h1>;
}
```

### Layout Files

Layouts wrap multiple pages and persist across navigation:

```typescript
// app/layout.tsx - Root layout (required)
import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
 title: 'My App',
 description: 'Built with Next.js',
};

export default function RootLayout({
 children,
}: {
 children: React.ReactNode;
}) {
 return (
 <html lang="en">
 <body>
 <header>
 <nav>Navigation</nav>
 </header>
 <main>{children}</main>
 <footer>Footer</footer>
 </body>
 </html>
 );
}

// app/dashboard/layout.tsx - Nested layout
export default function DashboardLayout({
 children,
}: {
 children: React.ReactNode;
}) {
 return (
 <div className="dashboard">
 <aside>Sidebar</aside>
 <section>{children}</section>
 </div>
 );
}
```

### Loading Files

Automatic loading states with Suspense:

```typescript
// app/dashboard/loading.tsx
export default function DashboardLoading {
 return (
 <div className="animate-pulse">
 <div className="h-8 bg-gray-200 rounded w-1/4 mb-4"></div>
 <div className="h-64 bg-gray-200 rounded"></div>
 </div>
 );
}

// This automatically wraps page.tsx in Suspense:
// <Suspense fallback={<DashboardLoading />}>
// <DashboardPage />
// </Suspense>
```

### Error Files

Built-in error boundaries:

```typescript
// app/dashboard/error.tsx
'use client'; // Error components must be Client Components

import { useEffect } from 'react';

export default function DashboardError({
 error,
 reset,
}: {
 error: Error & { digest?: string };
 reset: => void;
}) {
 useEffect( => {
 // Log error to error reporting service
 console.error(error);
 }, [error]);

 return (
 <div>
 <h2>Something went wrong!</h2>
 <p>{error.message}</p>
 <button onClick={ => reset}>Try again</button>
 </div>
 );
}
```

### Not Found Files

Custom 404 pages:

```typescript
// app/not-found.tsx - Global 404
import Link from 'next/link';

export default function NotFound {
 return (
 <div>
 <h2>Not Found</h2>
 <p>Could not find requested resource</p>
 <Link href="/">Return Home</Link>
 </div>
 );
}

// app/blog/[slug]/not-found.tsx - Scoped 404
export default function BlogPostNotFound {
 return (
 <div>
 <h2>Blog Post Not Found</h2>
 <p>This blog post does not exist</p>
 </div>
 );
}
```

---

## Dynamic Routes

### Single Dynamic Segment

```typescript
// app/blog/[slug]/page.tsx
interface BlogPostPageProps {
 params: {
 slug: string;
 };
}

export default function BlogPostPage({ params }: BlogPostPageProps) {
 return <h1>Post: {params.slug}</h1>;
}

// Routes:
// /blog/hello-world → params.slug = "hello-world"
// /blog/nextjs-tips → params.slug = "nextjs-tips"
```

### Multiple Dynamic Segments

```typescript
// app/shop/[category]/[product]/page.tsx
interface ProductPageProps {
 params: {
 category: string;
 product: string;
 };
}

export default function ProductPage({ params }: ProductPageProps) {
 return (
 <div>
 <h1>Category: {params.category}</h1>
 <h2>Product: {params.product}</h2>
 </div>
 );
}

// Routes:
// /shop/electronics/laptop → { category: "electronics", product: "laptop" }
// /shop/clothing/shirt → { category: "clothing", product: "shirt" }
```

### Catch-All Segments

Catch all subsequent segments:

```typescript
// app/docs/[...slug]/page.tsx
interface DocsPageProps {
 params: {
 slug: string[];
 };
}

export default function DocsPage({ params }: DocsPageProps) {
 return <h1>Docs: {params.slug.join(' / ')}</h1>;
}

// Routes:
// /docs/getting-started → params.slug = ["getting-started"]
// /docs/api/reference → params.slug = ["api", "reference"]
// /docs/guides/deployment/vercel → params.slug = ["guides", "deployment", "vercel"]

// ❌ Does NOT match:
// /docs → 404 (catch-all requires at least one segment)
```

### Optional Catch-All Segments

Make catch-all optional:

```typescript
// app/docs/[[...slug]]/page.tsx (double brackets)
interface DocsPageProps {
 params: {
 slug?: string[];
 };
}

export default function DocsPage({ params }: DocsPageProps) {
 if (!params.slug) {
 return <h1>Documentation Home</h1>;
 }
 return <h1>Docs: {params.slug.join(' / ')}</h1>;
}

// Routes:
// /docs → params.slug = undefined (✅ matches!)
// /docs/getting-started → params.slug = ["getting-started"]
// /docs/api/reference → params.slug = ["api", "reference"]
```

### Generating Static Params

Generate routes at build time:

```typescript
// app/blog/[slug]/page.tsx
interface Post {
 slug: string;
 title: string;
 content: string;
}

// Generate static params at build time
export async function generateStaticParams {
 const posts = await fetch('https://api.example.com/posts').then(res => res.json);

 return posts.map((post: Post) => ({
 slug: post.slug,
 }));
}

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
 <p>{post.content}</p>
 </article>
 );
}
```

---

## Route Groups

Route groups organize routes without affecting the URL:

### Basic Route Groups

```typescript
// app/(marketing)/about/page.tsx
// URL: /about

// app/(marketing)/contact/page.tsx
// URL: /contact

// app/(shop)/products/page.tsx
// URL: /products

// app/(shop)/cart/page.tsx
// URL: /cart
```

### Different Layouts

```typescript
// app/(marketing)/layout.tsx
export default function MarketingLayout({
 children,
}: {
 children: React.ReactNode;
}) {
 return (
 <div>
 <nav>Marketing Nav</nav>
 {children}
 </div>
 );
}

// app/(shop)/layout.tsx
export default function ShopLayout({
 children,
}: {
 children: React.ReactNode;
}) {
 return (
 <div>
 <nav>Shop Nav</nav>
 {children}
 </div>
 );
}
```

### Multiple Root Layouts

```typescript
// app/(public)/layout.tsx
export default function PublicLayout({
 children,
}: {
 children: React.ReactNode;
}) {
 return (
 <html lang="en">
 <body className="public">
 {children}
 </body>
 </html>
 );
}

// app/(dashboard)/layout.tsx
export default function DashboardLayout({
 children,
}: {
 children: React.ReactNode;
}) {
 return (
 <html lang="en">
 <body className="dashboard">
 {children}
 </body>
 </html>
 );
}

// ⚠️ Warning: Multiple root layouts opt out of automatic <html> and <body> management
```

---

## Parallel Routes

Render multiple pages in the same layout simultaneously:

### Slot Convention

```typescript
// Directory structure:
// app/
// ├── layout.tsx
// ├── page.tsx
// ├── @analytics/
// │ └── page.tsx
// └── @team/
// └── page.tsx

// app/layout.tsx
export default function Layout({
 children,
 analytics,
 team,
}: {
 children: React.ReactNode;
 analytics: React.ReactNode;
 team: React.ReactNode;
}) {
 return (
 <div>
 <main>{children}</main>
 <aside>
 <section>{analytics}</section>
 <section>{team}</section>
 </aside>
 </div>
 );
}
```

### Conditional Rendering

```typescript
// app/layout.tsx
export default function Layout({
 children,
 analytics,
 team,
}: {
 children: React.ReactNode;
 analytics: React.ReactNode;
 team: React.ReactNode;
}) {
 const isAdmin = checkUserRole;

 return (
 <div>
 <main>{children}</main>
 {isAdmin && (
 <aside>
 {analytics}
 {team}
 </aside>
 )}
 </div>
 );
}
```

### Default Files

Provide fallback when slot isn't matched:

```typescript
// app/@analytics/default.tsx
export default function AnalyticsDefault {
 return <div>Analytics not available</div>;
}
```

---

## Intercepting Routes

Intercept routes to show content in a different context (e.g., modals):

### Convention

- `(.)` - match same level
- `(..)` - match one level up
- `(..)(..)` - match two levels up
- `(...)` - match from root

### Photo Modal Example

```typescript
// Directory structure:
// app/
// ├── photos/
// │ └── [id]/
// │ └── page.tsx
// └── @modal/
// └── (.)photos/
// └── [id]/
// └── page.tsx

// app/photos/[id]/page.tsx - Full page
export default function PhotoPage({
 params,
}: {
 params: { id: string };
}) {
 return (
 <div>
 <h1>Photo {params.id}</h1>
 <img src={`/photos/${params.id}.jpg`} alt="" />
 </div>
 );
}

// app/@modal/(.)photos/[id]/page.tsx - Modal
export default function PhotoModal({
 params,
}: {
 params: { id: string };
}) {
 return (
 <dialog open>
 <img src={`/photos/${params.id}.jpg`} alt="" />
 </dialog>
 );
}

// app/layout.tsx
export default function Layout({
 children,
 modal,
}: {
 children: React.ReactNode;
 modal: React.ReactNode;
}) {
 return (
 <>
 {children}
 {modal}
 </>
 );
}
```

---

## Route Handlers

Create API endpoints with route handlers:

### Basic Route Handler

```typescript
// app/api/hello/route.ts
import { NextResponse } from 'next/server';

export async function GET {
 return NextResponse.json({ message: 'Hello, World!' });
}

export async function POST(request: Request) {
 const body = await request.json;
 return NextResponse.json({ received: body });
}
```

### HTTP Methods

```typescript
// app/api/posts/route.ts
import { NextResponse } from 'next/server';

// GET /api/posts
export async function GET(request: Request) {
 const posts = await fetchPosts;
 return NextResponse.json(posts);
}

// POST /api/posts
export async function POST(request: Request) {
 const body = await request.json;
 const post = await createPost(body);
 return NextResponse.json(post, { status: 201 });
}

// PUT /api/posts
export async function PUT(request: Request) {
 const body = await request.json;
 const post = await updatePost(body);
 return NextResponse.json(post);
}

// DELETE /api/posts
export async function DELETE(request: Request) {
 const { searchParams } = new URL(request.url);
 const id = searchParams.get('id');
 await deletePost(id!);
 return NextResponse.json({ success: true });
}

// PATCH /api/posts
export async function PATCH(request: Request) {
 const body = await request.json;
 const post = await patchPost(body);
 return NextResponse.json(post);
}
```

### Dynamic Route Handlers

```typescript
// app/api/posts/[id]/route.ts
import { NextResponse } from 'next/server';

export async function GET(
 request: Request,
 { params }: { params: { id: string } }
) {
 const post = await fetchPost(params.id);

 if (!post) {
 return NextResponse.json(
 { error: 'Post not found' },
 { status: 404 }
 );
 }

 return NextResponse.json(post);
}

export async function DELETE(
 request: Request,
 { params }: { params: { id: string } }
) {
 await deletePost(params.id);
 return NextResponse.json({ success: true });
}
```

### Request & Response Helpers

```typescript
// app/api/data/route.ts
import { NextRequest, NextResponse } from 'next/server';

export async function GET(request: NextRequest) {
 // Query parameters
 const searchParams = request.nextUrl.searchParams;
 const query = searchParams.get('query');

 // Headers
 const token = request.headers.get('authorization');

 // Cookies
 const session = request.cookies.get('session');

 // Response with headers and cookies
 return NextResponse.json(
 { data: 'example' },
 {
 status: 200,
 headers: {
 'Content-Type': 'application/json',
 'X-Custom-Header': 'value',
 },
 }
 );
}
```

---

## Middleware

Run code before requests are completed:

### Basic Middleware

```typescript
// middleware.ts (root of project)
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
 // Clone request headers
 const requestHeaders = new Headers(request.headers);
 requestHeaders.set('x-custom-header', 'value');

 // Response with modified headers
 return NextResponse.next({
 request: {
 headers: requestHeaders,
 },
 });
}

// Configure which routes to run middleware on
export const config = {
 matcher: '/dashboard/:path*',
};
```

### Authentication Middleware

```typescript
// middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
 const token = request.cookies.get('token');

 // Redirect to login if no token
 if (!token) {
 return NextResponse.redirect(new URL('/login', request.url));
 }

 return NextResponse.next;
}

export const config = {
 matcher: ['/dashboard/:path*', '/profile/:path*'],
};
```

### Conditional Redirects

```typescript
// middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
 // Check if user is authenticated
 const isAuthenticated = request.cookies.get('session');

 // Redirect authenticated users away from login
 if (isAuthenticated && request.nextUrl.pathname === '/login') {
 return NextResponse.redirect(new URL('/dashboard', request.url));
 }

 // Redirect unauthenticated users to login
 if (!isAuthenticated && request.nextUrl.pathname.startsWith('/dashboard')) {
 return NextResponse.redirect(new URL('/login', request.url));
 }

 return NextResponse.next;
}

export const config = {
 matcher: ['/((?!api|_next/static|_next/image|favicon.ico).*)'],
};
```

### Matcher Configuration

```typescript
export const config = {
 matcher: [
 // Match all routes except static files and API
 '/((?!api|_next/static|_next/image|favicon.ico).*)',

 // OR specific patterns
 '/dashboard/:path*',
 '/profile/:path*',

 // OR array of paths
 ['/dashboard/:path*', '/profile/:path*'],
 ],
};
```

---

## Navigation

### Link Component

```typescript
import Link from 'next/link';

export default function Navigation {
 return (
 <nav>
 {/* Basic link */}
 <Link href="/about">About</Link>

 {/* Dynamic route */}
 <Link href={`/blog/${post.slug}`}>
 {post.title}
 </Link>

 {/* With className */}
 <Link href="/contact" className="text-blue-500">
 Contact
 </Link>

 {/* Prefetch disabled */}
 <Link href="/heavy-page" prefetch={false}>
 Heavy Page
 </Link>

 {/* Replace history */}
 <Link href="/login" replace>
 Login
 </Link>

 {/* Scroll to top */}
 <Link href="/about" scroll={true}>
 About (scroll to top)
 </Link>
 </nav>
 );
}
```

### useRouter Hook

```typescript
'use client';

import { useRouter, usePathname, useSearchParams } from 'next/navigation';

export default function ClientComponent {
 const router = useRouter;
 const pathname = usePathname;
 const searchParams = useSearchParams;

 // Programmatic navigation
 const navigate = => {
 router.push('/dashboard');
 // router.replace('/dashboard'); // Replace history
 // router.back; // Go back
 // router.forward; // Go forward
 // router.refresh; // Refresh current route
 };

 // Get current path
 console.log(pathname); // e.g., "/blog/post-1"

 // Get search params
 const query = searchParams.get('query');

 return <button onClick={navigate}>Go to Dashboard</button>;
}
```

### redirect Function

```typescript
// Server Component or Server Action
import { redirect } from 'next/navigation';

export default async function ProfilePage {
 const user = await getUser;

 if (!user) {
 redirect('/login');
 }

 return <div>Welcome, {user.name}</div>;
}
```

---

## Best Practices

### ✅ DO

1. **Use Server Components by default**
```typescript
// app/posts/page.tsx (Server Component)
export default async function PostsPage {
 const posts = await fetchPosts; // Direct database access
 return <PostList posts={posts} />;
}
```

2. **Colocate related files**
```
app/blog/
├── page.tsx
├── loading.tsx
├── error.tsx
├── components/
│ ├── PostCard.tsx
│ └── PostList.tsx
└── utils/
 └── formatDate.ts
```

3. **Use loading.tsx for instant feedback**
```typescript
// app/dashboard/loading.tsx
export default function Loading {
 return <Skeleton />;
}
```

4. **Implement error boundaries**
```typescript
// app/error.tsx
'use client';

export default function Error({ error, reset }: {
 error: Error;
 reset: => void;
}) {
 return (
 <div>
 <h2>Something went wrong!</h2>
 <button onClick={reset}>Try again</button>
 </div>
 );
}
```

5. **Use route groups for organization**
```
app/
├── (marketing)/
│ ├── about/
│ └── contact/
└── (shop)/
 ├── products/
 └── cart/
```

### ❌ DON'T

1. **Don't use pages and app router together**
```typescript
// ❌ Bad: Mixing routers
/pages/index.tsx
/app/page.tsx
```

2. **Don't fetch data in Client Components**
```typescript
// ❌ Bad
'use client';

export default function Page {
 const [data, setData] = useState(null);
 useEffect( => {
 fetch('/api/data').then(r => r.json).then(setData);
 }, []);
}

// ✅ Good
export default async function Page {
 const data = await fetch('/api/data');
 return <Component data={data} />;
}
```

3. **Don't ignore TypeScript types**
```typescript
// ❌ Bad
export default function Page({ params }: any) {

}

// ✅ Good
export default function Page({ params }: { params: { id: string } }) {

}
```

4. **Don't create unnecessary route groups**
```typescript
// ❌ Unnecessary nesting
app/(group1)/(group2)/(group3)/page.tsx

// ✅ Keep it simple
app/page.tsx
```

5. **Don't skip error handling**
```typescript
// ❌ No error handling
export default async function Page {
 const data = await fetchData; // May fail
 return <div>{data.title}</div>;
}

// ✅ With error boundary
// app/error.tsx handles errors automatically
```

---

## Summary

### Key Concepts
- **App Router** uses file-based routing with special files
- **Dynamic routes** support `[param]`, `[...slug]`, and `[[...slug]]`
- **Route groups** organize without affecting URLs
- **Parallel routes** render multiple pages simultaneously
- **Intercepting routes** show content in different contexts
- **Route handlers** create API endpoints
- **Middleware** runs before request completion

### File Conventions
| File | Purpose |
|------|---------|
| `page.tsx` | Route UI |
| `layout.tsx` | Shared UI wrapper |
| `loading.tsx` | Loading fallback |
| `error.tsx` | Error boundary |
| `not-found.tsx` | 404 page |
| `route.ts` | API endpoint |

---

**Next**: [03-DATA-FETCHING.md](./03-DATA-FETCHING.md) - Learn how to fetch and manage data

**Last Updated**: November 9, 2025
**Status**: Production-Ready ✅
