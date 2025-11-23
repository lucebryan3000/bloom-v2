---
id: nextjs-10-advanced
topic: nextjs
file_role: detailed
profile: full
difficulty_level: advanced
kb_version: 3.1
prerequisites: [react, javascript, nextjs-basics]
related_topics: ['react', 'typescript', 'web']
embedding_keywords: [nextjs]
last_reviewed: 2025-11-13
---

# Next.js Advanced Patterns: Deep Dive

**Part 10 of 11 - The Next.js Knowledge Base**

## Table of Contents
1. [Middleware Deep Dive](#middleware-deep-dive)
2. [Intercepting Routes for Modals](#intercepting-routes-for-modals)
3. [Parallel Routes Advanced](#parallel-routes-advanced)
4. [Route Handlers Advanced](#route-handlers-advanced)
5. [Internationalization (i18n)](#internationalization-i18n)
6. [Authentication Patterns](#authentication-patterns)
7. [Database Integration](#database-integration)
8. [Caching Strategies](#caching-strategies)
9. [Server Actions Advanced](#server-actions-advanced)
10. [Best Practices](#best-practices)

---

## Middleware Deep Dive

### Advanced Middleware Patterns

```typescript
// middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
 const { pathname, searchParams } = request.nextUrl;

 // 1. Logging
 console.log(`${request.method} ${pathname}`);

 // 2. Authentication
 const token = request.cookies.get('token');
 if (pathname.startsWith('/dashboard') && !token) {
 return NextResponse.redirect(new URL('/login', request.url));
 }

 // 3. A/B Testing
 const bucket = request.cookies.get('bucket')?.value || Math.random > 0.5 ? 'A': 'B';
 const response = NextResponse.next;
 response.cookies.set('bucket', bucket);

 // 4. Geolocation
 const country = request.geo?.country || 'US';
 response.headers.set('x-country', country);

 // 5. Custom headers
 response.headers.set('x-middleware', 'true');

 // 6. Rate limiting
 const ip = request.headers.get('x-forwarded-for') || 'unknown';
 if (shouldRateLimit(ip)) {
 return NextResponse.json(
 { error: 'Too many requests' },
 { status: 429 }
 );
 }

 return response;
}

export const config = {
 matcher: [
 '/((?!api|_next/static|_next/image|favicon.ico).*)',
 ],
};

// Rate limiting helper
const rateLimitMap = new Map<string, { count: number; resetAt: number }>;

function shouldRateLimit(ip: string): boolean {
 const now = Date.now;
 const record = rateLimitMap.get(ip);

 if (!record || now > record.resetAt) {
 rateLimitMap.set(ip, { count: 1, resetAt: now + 60000 });
 return false;
 }

 if (record.count >= 100) {
 return true;
 }

 record.count++;
 return false;
}
```

### Chaining Middleware

```typescript
// lib/middleware/chain.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

type MiddlewareFactory = (
 middleware: (request: NextRequest) => NextResponse
) => (request: NextRequest) => NextResponse;

export function chain(
 functions: MiddlewareFactory[],
 index = 0
): (request: NextRequest) => NextResponse {
 const current = functions[index];

 if (current) {
 const next = chain(functions, index + 1);
 return current(next);
 }

 return (request: NextRequest) => NextResponse.next;
}

// Usage
import { withAuth } from './withAuth';
import { withLogging } from './withLogging';
import { withRateLimit } from './withRateLimit';

export default chain([withAuth, withLogging, withRateLimit]);
```

---

## Intercepting Routes for Modals

### Photo Gallery Modal Pattern

```typescript
// Directory structure:
// app/
// ├── photos/
// │ └── [id]/
// │ └── page.tsx # Full page
// ├── @modal/
// │ └── (.)photos/
// │ └── [id]/
// │ └── page.tsx # Modal
// └── layout.tsx

// app/layout.tsx
export default function RootLayout({
 children,
 modal,
}: {
 children: React.ReactNode;
 modal: React.ReactNode;
}) {
 return (
 <html>
 <body>
 {children}
 {modal}
 </body>
 </html>
 );
}

// app/photos/[id]/page.tsx (Full page)
export default function PhotoPage({
 params,
}: {
 params: { id: string };
}) {
 return (
 <div className="container">
 <Image src={`/photos/${params.id}.jpg`} alt="" fill />
 <div className="details">
 <h1>Photo {params.id}</h1>
 <p>Full page view</p>
 </div>
 </div>
 );
}

// app/@modal/(.)photos/[id]/page.tsx (Modal)
'use client';

import { useRouter } from 'next/navigation';
import Image from 'next/image';

export default function PhotoModal({
 params,
}: {
 params: { id: string };
}) {
 const router = useRouter;

 return (
 <div
 className="fixed inset-0 bg-black/80 flex items-center justify-center"
 onClick={ => router.back}
 >
 <div
 className="relative w-full max-w-4xl h-[80vh]"
 onClick={(e) => e.stopPropagation}
 >
 <Image src={`/photos/${params.id}.jpg`} alt="" fill />
 <button
 onClick={ => router.back}
 className="absolute top-4 right-4"
 >
 Close
 </button>
 </div>
 </div>
 );
}

// app/@modal/default.tsx (Important!)
export default function Default {
 return null;
}
```

### Login Modal Pattern

```typescript
// app/@auth/(.)login/page.tsx
'use client';

import { useRouter } from 'next/navigation';
import LoginForm from '@/components/auth/LoginForm';

export default function LoginModal {
 const router = useRouter;

 return (
 <div className="fixed inset-0 bg-black/50 flex items-center justify-center">
 <div
 className="bg-white rounded-lg p-8 max-w-md w-full"
 onClick={(e) => e.stopPropagation}
 >
 <h2 className="text-2xl font-bold mb-4">Login</h2>
 <LoginForm onSuccess={ => router.back} />
 <button onClick={ => router.back}>Cancel</button>
 </div>
 </div>
 );
}
```

---

## Parallel Routes Advanced

### Dashboard with Multiple Slots

```typescript
// app/dashboard/layout.tsx
export default function DashboardLayout({
 children,
 analytics,
 notifications,
 activity,
}: {
 children: React.ReactNode;
 analytics: React.ReactNode;
 notifications: React.ReactNode;
 activity: React.ReactNode;
}) {
 return (
 <div className="grid grid-cols-12 gap-4">
 <div className="col-span-8">{children}</div>
 <div className="col-span-4 space-y-4">
 {analytics}
 {notifications}
 {activity}
 </div>
 </div>
 );
}

// app/dashboard/@analytics/page.tsx
export default async function Analytics {
 const data = await fetchAnalytics;
 return <AnalyticsChart data={data} />;
}

// app/dashboard/@notifications/page.tsx
export default async function Notifications {
 const notifications = await fetchNotifications;
 return <NotificationList items={notifications} />;
}

// app/dashboard/@activity/page.tsx
export default async function Activity {
 const activity = await fetchRecentActivity;
 return <ActivityFeed items={activity} />;
}
```

### Conditional Slot Rendering

```typescript
// app/dashboard/layout.tsx
import { cookies } from 'next/headers';

export default function DashboardLayout({
 children,
 admin,
 user,
}: {
 children: React.ReactNode;
 admin: React.ReactNode;
 user: React.ReactNode;
}) {
 const cookieStore = cookies;
 const role = cookieStore.get('role')?.value;

 return (
 <div>
 {children}
 {role === 'admin' ? admin: user}
 </div>
 );
}
```

---

## Route Handlers Advanced

### Streaming Responses

```typescript
// app/api/stream/route.ts
export async function GET {
 const encoder = new TextEncoder;

 const stream = new ReadableStream({
 async start(controller) {
 for (let i = 0; i < 10; i++) {
 await new Promise((resolve) => setTimeout(resolve, 1000));
 controller.enqueue(encoder.encode(`data: ${i}\n\n`));
 }
 controller.close;
 },
 });

 return new Response(stream, {
 headers: {
 'Content-Type': 'text/event-stream',
 'Cache-Control': 'no-cache',
 Connection: 'keep-alive',
 },
 });
}
```

### WebSocket-like SSE

```typescript
// app/api/events/route.ts
export async function GET(request: Request) {
 const encoder = new TextEncoder;

 const stream = new ReadableStream({
 start(controller) {
 const interval = setInterval( => {
 const data = {
 timestamp: new Date.toISOString,
 message: 'Server event',
 };
 controller.enqueue(
 encoder.encode(`data: ${JSON.stringify(data)}\n\n`)
 );
 }, 1000);

 // Cleanup on close
 request.signal.addEventListener('abort', => {
 clearInterval(interval);
 controller.close;
 });
 },
 });

 return new Response(stream, {
 headers: {
 'Content-Type': 'text/event-stream',
 'Cache-Control': 'no-cache',
 Connection: 'keep-alive',
 },
 });
}

// Client usage
'use client';

useEffect( => {
 const eventSource = new EventSource('/api/events');

 eventSource.onmessage = (event) => {
 const data = JSON.parse(event.data);
 console.log('Received:', data);
 };

 return => eventSource.close;
}, []);
```

### File Upload Handler

```typescript
// app/api/upload/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { writeFile } from 'fs/promises';
import { join } from 'path';

export async function POST(request: NextRequest) {
 try {
 const formData = await request.formData;
 const file = formData.get('file') as File;

 if (!file) {
 return NextResponse.json(
 { error: 'No file provided' },
 { status: 400 }
 );
 }

 // Validate file type
 const allowedTypes = ['image/jpeg', 'image/png', 'image/webp'];
 if (!allowedTypes.includes(file.type)) {
 return NextResponse.json(
 { error: 'Invalid file type' },
 { status: 400 }
 );
 }

 // Validate file size (5MB)
 if (file.size > 5 * 1024 * 1024) {
 return NextResponse.json(
 { error: 'File too large' },
 { status: 400 }
 );
 }

 const bytes = await file.arrayBuffer;
 const buffer = Buffer.from(bytes);

 // Save file
 const filename = `${Date.now}-${file.name}`;
 const path = join(process.cwd, 'public/uploads', filename);
 await writeFile(path, buffer);

 return NextResponse.json({
 success: true,
 filename,
 url: `/uploads/${filename}`,
 });
 } catch (error) {
 return NextResponse.json(
 { error: 'Upload failed' },
 { status: 500 }
 );
 }
}
```

---

## Internationalization (i18n)

### App Router i18n Setup

```typescript
// i18n/config.ts
export const i18n = {
 defaultLocale: 'en',
 locales: ['en', 'es', 'fr', 'de'],
} as const;

export type Locale = (typeof i18n)['locales'][number];

// i18n/dictionaries.ts
const dictionaries = {
 en: => import('./dictionaries/en.json').then((module) => module.default),
 es: => import('./dictionaries/es.json').then((module) => module.default),
 fr: => import('./dictionaries/fr.json').then((module) => module.default),
};

export const getDictionary = async (locale: Locale) =>
 dictionaries[locale];

// app/[lang]/layout.tsx
import { i18n } from '@/i18n/config';

export async function generateStaticParams {
 return i18n.locales.map((locale) => ({ lang: locale }));
}

export default function Layout({
 children,
 params,
}: {
 children: React.ReactNode;
 params: { lang: Locale };
}) {
 return (
 <html lang={params.lang}>
 <body>{children}</body>
 </html>
 );
}

// app/[lang]/page.tsx
import { getDictionary } from '@/i18n/dictionaries';
import type { Locale } from '@/i18n/config';

export default async function Page({
 params,
}: {
 params: { lang: Locale };
}) {
 const dict = await getDictionary(params.lang);

 return (
 <div>
 <h1>{dict.welcome}</h1>
 <p>{dict.description}</p>
 </div>
 );
}

// i18n/dictionaries/en.json
{
 "welcome": "Welcome",
 "description": "This is the English version"
}

// i18n/dictionaries/es.json
{
 "welcome": "Bienvenido",
 "description": "Esta es la versión en español"
}
```

### Language Switcher

```typescript
'use client';

import { useRouter, usePathname } from 'next/navigation';
import { i18n, type Locale } from '@/i18n/config';

export default function LanguageSwitcher({ lang }: { lang: Locale }) {
 const router = useRouter;
 const pathname = usePathname;

 const switchLanguage = (newLocale: Locale) => {
 const segments = pathname.split('/');
 segments[1] = newLocale;
 router.push(segments.join('/'));
 };

 return (
 <select
 value={lang}
 onChange={(e) => switchLanguage(e.target.value as Locale)}
 >
 {i18n.locales.map((locale) => (
 <option key={locale} value={locale}>
 {locale.toUpperCase}
 </option>
 ))}
 </select>
 );
}
```

---

## Authentication Patterns

### NextAuth.js Integration

```typescript
// app/api/auth/[...nextauth]/route.ts
import NextAuth from 'next-auth';
import CredentialsProvider from 'next-auth/providers/credentials';
import { compare } from 'bcrypt';
import { prisma } from '@/lib/db';

const handler = NextAuth({
 providers: [
 CredentialsProvider({
 name: 'Credentials',
 credentials: {
 email: { label: 'Email', type: 'email' },
 password: { label: 'Password', type: 'password' },
 },
 async authorize(credentials) {
 if (!credentials?.email || !credentials?.password) {
 return null;
 }

 const user = await prisma.user.findUnique({
 where: { email: credentials.email },
 });

 if (!user) {
 return null;
 }

 const isValid = await compare(credentials.password, user.password);

 if (!isValid) {
 return null;
 }

 return {
 id: user.id,
 email: user.email,
 name: user.name,
 };
 },
 }),
 ],
 session: {
 strategy: 'jwt',
 },
 pages: {
 signIn: '/login',
 signOut: '/logout',
 error: '/error',
 },
 callbacks: {
 async jwt({ token, user }) {
 if (user) {
 token.id = user.id;
 }
 return token;
 },
 async session({ session, token }) {
 if (session.user) {
 session.user.id = token.id as string;
 }
 return session;
 },
 },
});

export { handler as GET, handler as POST };

// Middleware for protected routes
// middleware.ts
import { withAuth } from 'next-auth/middleware';

export default withAuth({
 callbacks: {
 authorized: ({ token }) => !!token,
 },
});

export const config = {
 matcher: ['/dashboard/:path*', '/profile/:path*'],
};
```

### Custom JWT Auth

```typescript
// lib/auth.ts
import { SignJWT, jwtVerify } from 'jose';
import { cookies } from 'next/headers';

const secret = new TextEncoder.encode(process.env.JWT_SECRET!);

export async function createToken(payload: { userId: string; email: string }) {
 return await new SignJWT(payload)
.setProtectedHeader({ alg: 'HS256' })
.setIssuedAt
.setExpirationTime('24h')
.sign(secret);
}

export async function verifyToken(token: string) {
 try {
 const { payload } = await jwtVerify(token, secret);
 return payload;
 } catch (error) {
 return null;
 }
}

export async function getSession {
 const cookieStore = cookies;
 const token = cookieStore.get('token')?.value;

 if (!token) {
 return null;
 }

 return await verifyToken(token);
}

// Usage in Server Component
export default async function ProfilePage {
 const session = await getSession;

 if (!session) {
 redirect('/login');
 }

 return <div>Welcome, {session.email}</div>;
}
```

---

## Database Integration

### Prisma Best Practices (this project uses this)

```typescript
// lib/db/client.ts (this project pattern)
import { PrismaClient } from '@prisma/client';

const globalForPrisma = global as unknown as { prisma: PrismaClient };

export const prisma =
 globalForPrisma.prisma ||
 new PrismaClient({
 log: process.env.NODE_ENV === 'development' ? ['query', 'error', 'warn']: ['error'],
 });

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma;

// Connection pooling
// lib/db/pool.ts
import { Pool } from 'pg';

export const pool = new Pool({
 connectionString: process.env.DATABASE_URL,
 max: 20,
 idleTimeoutMillis: 30000,
 connectionTimeoutMillis: 2000,
});

// Transactions
export async function transferFunds(fromId: string, toId: string, amount: number) {
 await prisma.$transaction(async (tx) => {
 // Deduct from sender
 await tx.account.update({
 where: { id: fromId },
 data: { balance: { decrement: amount } },
 });

 // Add to receiver
 await tx.account.update({
 where: { id: toId },
 data: { balance: { increment: amount } },
 });

 // Log transaction
 await tx.transaction.create({
 data: {
 fromId,
 toId,
 amount,
 },
 });
 });
}
```

---

## Caching Strategies

### Multi-tier Caching

```typescript
// lib/cache.ts
import { Redis } from 'ioredis';

const redis = new Redis(process.env.REDIS_URL);

// 1. In-memory cache (fastest)
const memoryCache = new Map<string, { data: any; expires: number }>;

// 2. Redis cache (fast, shared)
// 3. Database (slowest, source of truth)

export async function getCached<T>(
 key: string,
 fetcher: => Promise<T>,
 ttl: number = 60
): Promise<T> {
 // Check memory cache
 const memCached = memoryCache.get(key);
 if (memCached && memCached.expires > Date.now) {
 return memCached.data;
 }

 // Check Redis cache
 const redisCached = await redis.get(key);
 if (redisCached) {
 const data = JSON.parse(redisCached);
 memoryCache.set(key, { data, expires: Date.now + ttl * 1000 });
 return data;
 }

 // Fetch from source
 const data = await fetcher;

 // Store in both caches
 memoryCache.set(key, { data, expires: Date.now + ttl * 1000 });
 await redis.setex(key, ttl, JSON.stringify(data));

 return data;
}

// Usage
const posts = await getCached('posts:all', async => {
 return await prisma.post.findMany;
}, 300); // 5 minutes
```

---

## Server Actions Advanced

### Form with Validation

```typescript
// app/actions.ts
'use server';

import { z } from 'zod';
import { revalidatePath } from 'next/cache';

const createPostSchema = z.object({
 title: z.string.min(1).max(200),
 content: z.string.min(1),
 published: z.boolean,
});

export async function createPost(prevState: any, formData: FormData) {
 try {
 const data = {
 title: formData.get('title'),
 content: formData.get('content'),
 published: formData.get('published') === 'on',
 };

 const validated = createPostSchema.parse(data);

 await prisma.post.create({ data: validated });

 revalidatePath('/posts');

 return { success: true, message: 'Post created!' };
 } catch (error) {
 if (error instanceof z.ZodError) {
 return {
 success: false,
 errors: error.errors,
 };
 }
 return { success: false, message: 'Failed to create post' };
 }
}
```

---

## Best Practices

### ✅ DO

1. **Use middleware for global logic**
2. **Implement proper caching strategies**
3. **Validate all inputs with Zod**
4. **Use Server Actions for mutations**
5. **Implement proper error handling**

### ❌ DON'T

1. **Don't skip authentication checks**
2. **Don't ignore rate limiting**
3. **Don't expose sensitive data**
4. **Don't skip input validation**

---

**Next**: [11-CONFIG-BEST-PRACTICES.md](./11-CONFIG-BEST-PRACTICES.md) - Final configuration guide

**Last Updated**: November 9, 2025
**Status**: Production-Ready ✅
