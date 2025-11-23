---
id: nextjs-quick-reference
topic: nextjs
file_role: quickref
profile: full
difficulty_level: all-levels
kb_version: 3.1
prerequisites: ['react', 'javascript']
related_topics: ['react', 'typescript', 'web']
embedding_keywords: [nextjs, quick-reference, cheat-sheet, syntax]
last_reviewed: 2025-11-13
---

# Next.js Quick Reference Card

**For fast lookup while coding**

## Project Setup

```bash
# Create new Next.js app
npx create-next-app@latest my-app

# With specific options
npx create-next-app@latest my-app --typescript --tailwind --app

# Install dependencies
npm install

# Run development server
npm run dev

# Build for production
npm run build

# Start production server
npm start
```

---

## File Structure (App Router)

```
app/
├── layout.tsx # Root layout (required)
├── page.tsx # Home page (/)
├── loading.tsx # Loading UI
├── error.tsx # Error UI
├── not-found.tsx # 404 page
├── global.css # Global styles
│
├── about/
│ └── page.tsx # /about route
│
├── blog/
│ ├── page.tsx # /blog route
│ └── [slug]/
│ └── page.tsx # /blog/[slug] dynamic route
│
├── api/
│ └── users/
│ └── route.ts # API route: /api/users
│
└── (auth)/ # Route group (no URL segment)
 ├── login/
 │ └── page.tsx # /login
 └── register/
 └── page.tsx # /register
```

---

## Server vs Client Components

```tsx
// SERVER COMPONENT (default - no directive)
// ✅ Can fetch data directly
// ✅ Can use async/await
// ✅ Smaller bundle size
// ❌ Cannot use hooks (useState, useEffect)
// ❌ Cannot use browser APIs
export default async function ServerPage {
 const data = await fetch('https://api.example.com/data');
 return <div>{JSON.stringify(data)}</div>;
}

// CLIENT COMPONENT (needs 'use client')
// ✅ Can use React hooks
// ✅ Can use browser APIs
// ✅ Can handle events
// ❌ Larger bundle size
'use client';

import { useState, useEffect } from 'react';

export default function ClientPage {
 const [count, setCount] = useState(0);
 return <button onClick={ => setCount(count + 1)}>{count}</button>;
}
```

---

## Routing Patterns

### Basic Routes

```tsx
// app/page.tsx → /
export default function Home {
 return <h1>Home</h1>;
}

// app/about/page.tsx → /about
export default function About {
 return <h1>About</h1>;
}

// app/blog/posts/page.tsx → /blog/posts
export default function BlogPosts {
 return <h1>Blog Posts</h1>;
}
```

### Dynamic Routes

```tsx
// app/blog/[slug]/page.tsx → /blog/hello-world
interface PageProps {
 params: { slug: string };
 searchParams: { [key: string]: string | string[] | undefined };
}

export default function BlogPost({ params }: PageProps) {
 return <h1>Post: {params.slug}</h1>;
}

// app/shop/[category]/[product]/page.tsx → /shop/electronics/laptop
export default function Product({ params }: PageProps) {
 return <div>{params.category} - {params.product}</div>;
}
```

### Catch-All Routes

```tsx
// app/docs/[...slug]/page.tsx → /docs/a, /docs/a/b, /docs/a/b/c
interface CatchAllProps {
 params: { slug: string[] };
}

export default function Docs({ params }: CatchAllProps) {
 return <div>Path: {params.slug.join('/')}</div>;
}

// app/shop/[[...slug]]/page.tsx → /shop, /shop/a, /shop/a/b (optional)
export default function Shop({ params }: { params: { slug?: string[] } }) {
 return <div>Slug: {params.slug?.join('/') || 'home'}</div>;
}
```

### Route Groups

```tsx
// (auth) group doesn't affect URL
// app/(auth)/login/page.tsx → /login
// app/(auth)/register/page.tsx → /register
// app/(auth)/layout.tsx → Shared layout for login & register

// (marketing) group
// app/(marketing)/about/page.tsx → /about
// app/(marketing)/pricing/page.tsx → /pricing
```

### Parallel Routes

```tsx
// app/dashboard/@analytics/page.tsx
// app/dashboard/@team/page.tsx
// app/dashboard/layout.tsx

export default function DashboardLayout({
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
 {children}
 <div className="grid grid-cols-2">
 {analytics}
 {team}
 </div>
 </div>
 );
}
```

### Intercepting Routes

```tsx
// app/feed/(..)photo/[id]/page.tsx
// Intercepts /photo/[id] when navigating from /feed
export default function PhotoModal({ params }: { params: { id: string } }) {
 return <div>Modal for photo {params.id}</div>;
}
```

---

## Layouts

```tsx
// app/layout.tsx (Root Layout - Required)
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

// app/dashboard/layout.tsx (Nested Layout)
export default function DashboardLayout({
 children,
}: {
 children: React.ReactNode;
}) {
 return (
 <div>
 <nav>Dashboard Nav</nav>
 <main>{children}</main>
 </div>
 );
}

// Layout with metadata
export const metadata = {
 title: 'Dashboard',
 description: 'User dashboard',
};
```

---

## Data Fetching

### Server Components (Recommended)

```tsx
// Direct fetch in Server Component
async function getData {
 const res = await fetch('https://api.example.com/data', {
 cache: 'force-cache', // Default (SSG)
 // cache: 'no-store', // SSR (always fresh)
 // next: { revalidate: 60 }, // ISR (revalidate every 60s)
 });

 if (!res.ok) throw new Error('Failed to fetch');
 return res.json;
}

export default async function Page {
 const data = await getData;
 return <div>{JSON.stringify(data)}</div>;
}
```

### Parallel Data Fetching

```tsx
async function getUser {
 const res = await fetch('https://api.example.com/user');
 return res.json;
}

async function getPosts {
 const res = await fetch('https://api.example.com/posts');
 return res.json;
}

export default async function Page {
 // Fetch in parallel
 const [user, posts] = await Promise.all([getUser, getPosts]);

 return (
 <div>
 <h1>{user.name}</h1>
 <ul>
 {posts.map((post) => (
 <li key={post.id}>{post.title}</li>
 ))}
 </ul>
 </div>
 );
}
```

### Sequential Data Fetching

```tsx
export default async function Page {
 // Fetch user first
 const user = await getUser;

 // Then fetch user's posts (depends on user.id)
 const posts = await getUserPosts(user.id);

 return <div>...</div>;
}
```

### Revalidation Strategies

```tsx
// Static (cached forever)
fetch('https://api.example.com/data', { cache: 'force-cache' });

// Dynamic (no cache - SSR)
fetch('https://api.example.com/data', { cache: 'no-store' });

// Revalidate (ISR - regenerate after time)
fetch('https://api.example.com/data', { next: { revalidate: 3600 } });

// Revalidate with tag
fetch('https://api.example.com/posts', { next: { tags: ['posts'] } });

// Manually revalidate by tag
import { revalidateTag } from 'next/cache';
revalidateTag('posts');

// Manually revalidate by path
import { revalidatePath } from 'next/cache';
revalidatePath('/blog');
```

---

## API Routes

### Basic Route Handler

```typescript
// app/api/hello/route.ts
import { NextRequest, NextResponse } from 'next/server';

export async function GET(request: NextRequest) {
 return NextResponse.json({ message: 'Hello World' });
}

export async function POST(request: NextRequest) {
 const body = await request.json;
 return NextResponse.json({ received: body }, { status: 201 });
}

export async function PUT(request: NextRequest) {
 const body = await request.json;
 return NextResponse.json({ updated: body });
}

export async function DELETE(request: NextRequest) {
 return NextResponse.json({ deleted: true });
}

export async function PATCH(request: NextRequest) {
 const body = await request.json;
 return NextResponse.json({ patched: body });
}
```

### Dynamic Route Handler

```typescript
// app/api/users/[id]/route.ts
interface RouteParams {
 params: { id: string };
}

export async function GET(
 request: NextRequest,
 { params }: RouteParams
) {
 const user = await getUserById(params.id);
 return NextResponse.json(user);
}

export async function DELETE(
 request: NextRequest,
 { params }: RouteParams
) {
 await deleteUser(params.id);
 return NextResponse.json({ success: true });
}
```

### Query Parameters

```typescript
// app/api/search/route.ts
export async function GET(request: NextRequest) {
 const searchParams = request.nextUrl.searchParams;
 const query = searchParams.get('q');
 const limit = searchParams.get('limit') || '10';

 return NextResponse.json({ query, limit });
}

// Usage: /api/search?q=hello&limit=20
```

### Headers & Cookies

```typescript
import { cookies, headers } from 'next/headers';

export async function GET(request: NextRequest) {
 // Read headers
 const headersList = headers;
 const authorization = headersList.get('authorization');

 // Read cookies
 const cookieStore = cookies;
 const token = cookieStore.get('token');

 // Set cookie in response
 const response = NextResponse.json({ data: 'value' });
 response.cookies.set('name', 'value', {
 httpOnly: true,
 secure: process.env.NODE_ENV === 'production',
 maxAge: 60 * 60 * 24 * 7, // 1 week
 path: '/',
 });

 return response;
}
```

### Error Handling

```typescript
// app/api/users/route.ts
export async function POST(request: NextRequest) {
 try {
 const body = await request.json;

 // Validate
 if (!body.email) {
 return NextResponse.json(
 { error: 'Email is required' },
 { status: 400 }
 );
 }

 const user = await createUser(body);
 return NextResponse.json(user, { status: 201 });

 } catch (error) {
 console.error('Error creating user:', error);
 return NextResponse.json(
 { error: 'Internal server error' },
 { status: 500 }
 );
 }
}
```

### CORS Configuration

```typescript
export async function GET(request: NextRequest) {
 const response = NextResponse.json({ data: 'value' });

 response.headers.set('Access-Control-Allow-Origin', '*');
 response.headers.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE');
 response.headers.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

 return response;
}

export async function OPTIONS(request: NextRequest) {
 return new NextResponse(null, {
 status: 204,
 headers: {
 'Access-Control-Allow-Origin': '*',
 'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE',
 'Access-Control-Allow-Headers': 'Content-Type, Authorization',
 },
 });
}
```

---

## Navigation

### Link Component

```tsx
import Link from 'next/link';

// Basic link
<Link href="/about">About</Link>

// Dynamic link
<Link href={`/blog/${post.slug}`}>Read More</Link>

// With query params
<Link href={{ pathname: '/blog', query: { id: '123' } }}>Blog</Link>

// External link (opens in new tab)
<Link href="https://example.com" target="_blank" rel="noopener noreferrer">
 External
</Link>

// With custom className
<Link href="/about" className="text-blue-500 hover:underline">
 About
</Link>

// Replace instead of push
<Link href="/login" replace>Login</Link>

// Scroll to top (default true)
<Link href="/contact" scroll={false}>Contact</Link>

// Prefetch (default true for visible links)
<Link href="/products" prefetch={false}>Products</Link>
```

### useRouter Hook (Client Component)

```tsx
'use client';

import { useRouter, usePathname, useSearchParams } from 'next/navigation';

export default function ClientNav {
 const router = useRouter;
 const pathname = usePathname; // Current path
 const searchParams = useSearchParams; // Query params

 // Navigate programmatically
 const handleClick = => {
 router.push('/dashboard'); // Navigate
 // router.replace('/dashboard'); // Replace (no history)
 // router.back; // Go back
 // router.forward; // Go forward
 // router.refresh; // Refresh current route
 };

 return (
 <div>
 <p>Current path: {pathname}</p>
 <p>Query: {searchParams.get('id')}</p>
 <button onClick={handleClick}>Go to Dashboard</button>
 </div>
 );
}
```

### redirect Function (Server Component)

```tsx
import { redirect } from 'next/navigation';

export default async function Page {
 const session = await getSession;

 if (!session) {
 redirect('/login'); // Server-side redirect
 }

 return <div>Protected content</div>;
}
```

### permanentRedirect Function

```tsx
import { permanentRedirect } from 'next/navigation';

export default function OldPage {
 permanentRedirect('/new-page'); // 308 redirect
}
```

---

## Metadata

### Static Metadata

```tsx
// app/page.tsx
import type { Metadata } from 'next';

export const metadata: Metadata = {
 title: 'Home',
 description: 'Welcome to our site',
 keywords: ['nextjs', 'react', 'typescript'],
 authors: [{ name: 'John Doe' }],
 openGraph: {
 title: 'Home',
 description: 'Welcome to our site',
 images: ['/og-image.png'],
 },
 twitter: {
 card: 'summary_large_image',
 title: 'Home',
 description: 'Welcome to our site',
 images: ['/twitter-image.png'],
 },
};
```

### Dynamic Metadata

```tsx
// app/blog/[slug]/page.tsx
import type { Metadata } from 'next';

interface PageProps {
 params: { slug: string };
}

export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
 const post = await getPost(params.slug);

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

export default async function BlogPost({ params }: PageProps) {
 const post = await getPost(params.slug);
 return <article>{post.content}</article>;
}
```

### Metadata Template

```tsx
// app/layout.tsx
export const metadata: Metadata = {
 title: {
 template: '%s | My Site',
 default: 'My Site',
 },
};

// app/about/page.tsx
export const metadata: Metadata = {
 title: 'About', // Becomes "About | My Site"
};
```

---

## Loading & Error States

### Loading UI

```tsx
// app/dashboard/loading.tsx
export default function Loading {
 return (
 <div className="flex items-center justify-center h-screen">
 <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600" />
 </div>
 );
}
```

### Error UI

```tsx
// app/dashboard/error.tsx
'use client';

export default function Error({
 error,
 reset,
}: {
 error: Error & { digest?: string };
 reset: => void;
}) {
 return (
 <div className="flex flex-col items-center justify-center h-screen">
 <h2 className="text-2xl font-bold mb-4">Something went wrong!</h2>
 <p className="text-gray-600 mb-4">{error.message}</p>
 <button
 onClick={reset}
 className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
 >
 Try again
 </button>
 </div>
 );
}
```

### Not Found UI

```tsx
// app/not-found.tsx
import Link from 'next/link';

export default function NotFound {
 return (
 <div className="flex flex-col items-center justify-center h-screen">
 <h1 className="text-6xl font-bold mb-4">404</h1>
 <p className="text-xl mb-4">Page not found</p>
 <Link href="/" className="text-blue-600 hover:underline">
 Go home
 </Link>
 </div>
 );
}
```

### Trigger Not Found

```tsx
import { notFound } from 'next/navigation';

export default async function Page({ params }: { params: { id: string } }) {
 const user = await getUser(params.id);

 if (!user) {
 notFound; // Renders not-found.tsx
 }

 return <div>{user.name}</div>;
}
```

---

## Image Optimization

```tsx
import Image from 'next/image';

// Local image (from /public)
<Image
 src="/hero.png"
 alt="Hero image"
 width={800}
 height={600}
 priority // Load immediately (above fold)
/>

// Remote image
<Image
 src="https://example.com/photo.jpg"
 alt="Photo"
 width={800}
 height={600}
 loader={({ src }) => src} // Custom loader
/>

// Fill container
<div className="relative w-full h-96">
 <Image
 src="/banner.jpg"
 alt="Banner"
 fill
 className="object-cover"
 />
</div>

// Responsive sizes
<Image
 src="/responsive.jpg"
 alt="Responsive"
 width={800}
 height={600}
 sizes="(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 33vw"
/>

// Blur placeholder
<Image
 src="/photo.jpg"
 alt="Photo"
 width={800}
 height={600}
 placeholder="blur"
 blurDataURL="data:image/..." // Base64 blur data
/>

// Quality control
<Image
 src="/high-quality.jpg"
 alt="High quality"
 width={800}
 height={600}
 quality={100} // Default 75
/>
```

---

## Environment Variables

```bash
#.env.local (local development - not committed)
DATABASE_URL="postgresql://..."
NEXTAUTH_SECRET="..."

#.env.production (production)
DATABASE_URL="postgresql://..."

#.env (all environments)
NEXT_PUBLIC_API_URL="https://api.example.com"
```

```typescript
// Server-side only
const dbUrl = process.env.DATABASE_URL;

// Client-side (must prefix with NEXT_PUBLIC_)
const apiUrl = process.env.NEXT_PUBLIC_API_URL;
```

---

## Middleware

```typescript
// middleware.ts (root level)
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
 // Check authentication
 const token = request.cookies.get('token');

 if (!token && request.nextUrl.pathname.startsWith('/dashboard')) {
 return NextResponse.redirect(new URL('/login', request.url));
 }

 // Add custom header
 const response = NextResponse.next;
 response.headers.set('x-custom-header', 'value');
 return response;
}

// Configure matcher
export const config = {
 matcher: [
 '/dashboard/:path*',
 '/api/:path*',
 '/((?!_next/static|_next/image|favicon.ico).*)',
 ],
};
```

---

## Server Actions

```tsx
// app/actions.ts
'use server';

import { revalidatePath } from 'next/cache';

export async function createPost(formData: FormData) {
 const title = formData.get('title') as string;
 const content = formData.get('content') as string;

 await db.post.create({
 data: { title, content },
 });

 revalidatePath('/blog');
}

export async function updatePost(id: string, formData: FormData) {
 const title = formData.get('title') as string;

 await db.post.update({
 where: { id },
 data: { title },
 });

 revalidatePath(`/blog/${id}`);
}
```

```tsx
// app/blog/new/page.tsx
import { createPost } from '@/app/actions';

export default function NewPost {
 return (
 <form action={createPost}>
 <input name="title" required />
 <textarea name="content" required />
 <button type="submit">Create Post</button>
 </form>
 );
}
```

```tsx
// Client component with server action
'use client';

import { updatePost } from '@/app/actions';
import { useFormStatus } from 'react-dom';

function SubmitButton {
 const { pending } = useFormStatus;
 return (
 <button type="submit" disabled={pending}>
 {pending ? 'Saving...': 'Save'}
 </button>
 );
}

export default function EditPost({ id }: { id: string }) {
 return (
 <form action={updatePost.bind(null, id)}>
 <input name="title" required />
 <SubmitButton />
 </form>
 );
}
```

---

## Streaming & Suspense

```tsx
import { Suspense } from 'react';

async function SlowComponent {
 await new Promise(resolve => setTimeout(resolve, 3000));
 const data = await fetchData;
 return <div>{data}</div>;
}

function LoadingFallback {
 return <div>Loading...</div>;
}

export default function Page {
 return (
 <div>
 <h1>Page Title</h1>

 {/* Fast content renders immediately */}
 <p>This renders right away</p>

 {/* Slow content streams in when ready */}
 <Suspense fallback={<LoadingFallback />}>
 <SlowComponent />
 </Suspense>
 </div>
 );
}
```

---

## Static Site Generation (SSG)

```tsx
// Generate static params at build time
export async function generateStaticParams {
 const posts = await getPosts;

 return posts.map((post) => ({
 slug: post.slug,
 }));
}

// Static page with params
export default async function Post({ params }: { params: { slug: string } }) {
 const post = await getPost(params.slug);
 return <article>{post.content}</article>;
}
```

---

## Configuration (next.config.js)

```javascript
/** @type {import('next').NextConfig} */
const nextConfig = {
 // Enable React strict mode
 reactStrictMode: true,

 // Image domains
 images: {
 domains: ['example.com', 'images.unsplash.com'],
 remotePatterns: [
 {
 protocol: 'https',
 hostname: '**.example.com',
 },
 ],
 },

 // Redirects
 async redirects {
 return [
 {
 source: '/old-path',
 destination: '/new-path',
 permanent: true,
 },
 ];
 },

 // Rewrites
 async rewrites {
 return [
 {
 source: '/api/:path*',
 destination: 'https://api.example.com/:path*',
 },
 ];
 },

 // Headers
 async headers {
 return [
 {
 source: '/api/:path*',
 headers: [
 {
 key: 'Access-Control-Allow-Origin',
 value: '*',
 },
 ],
 },
 ];
 },

 // Environment variables
 env: {
 CUSTOM_KEY: 'value',
 },

 // TypeScript
 typescript: {
 ignoreBuildErrors: false,
 },

 // ESLint
 eslint: {
 ignoreDuringBuilds: false,
 },
};

module.exports = nextConfig;
```

---

## Common Patterns

### Protected Route

```tsx
// app/dashboard/page.tsx
import { redirect } from 'next/navigation';
import { getSession } from '@/lib/auth';

export default async function Dashboard {
 const session = await getSession;

 if (!session) {
 redirect('/login');
 }

 return <div>Welcome, {session.user.name}</div>;
}
```

### Form Handling

```tsx
'use client';

import { useState } from 'react';

export default function ContactForm {
 const [status, setStatus] = useState<'idle' | 'loading' | 'success' | 'error'>('idle');

 async function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
 e.preventDefault;
 setStatus('loading');

 const formData = new FormData(e.currentTarget);

 try {
 const response = await fetch('/api/contact', {
 method: 'POST',
 body: formData,
 });

 if (!response.ok) throw new Error('Failed');

 setStatus('success');
 } catch (error) {
 setStatus('error');
 }
 }

 return (
 <form onSubmit={handleSubmit}>
 <input name="email" type="email" required />
 <textarea name="message" required />
 <button type="submit" disabled={status === 'loading'}>
 {status === 'loading' ? 'Sending...': 'Send'}
 </button>
 {status === 'success' && <p>Message sent!</p>}
 {status === 'error' && <p>Failed to send</p>}
 </form>
 );
}
```

### Infinite Scroll

```tsx
'use client';

import { useState, useEffect } from 'react';

export default function InfiniteList {
 const [items, setItems] = useState([]);
 const [page, setPage] = useState(1);
 const [hasMore, setHasMore] = useState(true);

 useEffect( => {
 async function loadMore {
 const res = await fetch(`/api/items?page=${page}`);
 const data = await res.json;

 setItems((prev) => [...prev,...data.items]);
 setHasMore(data.hasMore);
 }

 loadMore;
 }, [page]);

 return (
 <div>
 {items.map((item) => (
 <div key={item.id}>{item.title}</div>
 ))}
 {hasMore && (
 <button onClick={ => setPage(page + 1)}>
 Load More
 </button>
 )}
 </div>
 );
}
```

---

## Performance Tips

✅ **Use Server Components by default** - Smaller bundle size
✅ **Code split with dynamic imports** - Load code on demand
✅ **Optimize images** - Use next/image
✅ **Static generation** - Pre-render when possible
✅ **Streaming** - Use Suspense for slow components
✅ **Route prefetching** - Link components prefetch automatically
✅ **Font optimization** - Use next/font
✅ **Parallel data fetching** - Use Promise.all

---

## Common Gotchas

❌ **Using hooks in Server Components** - Add 'use client'
❌ **Importing server-only code in client** - Separate files
❌ **Not handling loading/error states** - Add loading.tsx & error.tsx
❌ **Forgetting NEXT_PUBLIC_ prefix** - Client env vars need it
❌ **Not optimizing images** - Always use next/image
❌ **Blocking data fetches** - Use parallel fetching
❌ **Not revalidating cached data** - Set appropriate cache strategies

---

**This quick reference covers 90% of daily Next.js development tasks.**
**For deep dives, see the full handbook files.**
