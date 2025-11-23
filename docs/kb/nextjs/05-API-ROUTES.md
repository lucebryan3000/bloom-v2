---
id: nextjs-05-api-routes
topic: nextjs
file_role: detailed
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [react, javascript, nextjs-basics]
related_topics: ['react', 'typescript', 'web']
embedding_keywords: [nextjs, api]
last_reviewed: 2025-11-13
---

# Next.js API Routes: Building REST APIs

**Part 5 of 11 - The Next.js Knowledge Base**

## Table of Contents
1. [Route Handler Basics](#route-handler-basics)
2. [HTTP Methods](#http-methods)
3. [Request and Response Objects](#request-and-response-objects)
4. [Dynamic API Routes](#dynamic-api-routes)
5. [Middleware Patterns](#middleware-patterns)
6. [Edge vs Node Runtime](#edge-vs-node-runtime)
7. [CORS Handling](#cors-handling)
8. [Authentication](#authentication)
9. [Error Handling](#error-handling)
10. [Rate Limiting](#rate-limiting)
11. [Best Practices](#best-practices)

---

## Route Handler Basics

### What are Route Handlers?

Route handlers are server-side API endpoints in the App Router (replacing API Routes from Pages Router).

### Basic Route Handler

```typescript
// app/api/hello/route.ts
import { NextResponse } from 'next/server';

export async function GET {
 return NextResponse.json({ message: 'Hello, World!' });
}
```

### File Structure

```
app/
└── api/
 ├── hello/
 │ └── route.ts # /api/hello
 ├── users/
 │ ├── route.ts # /api/users
 │ └── [id]/
 │ └── route.ts # /api/users/[id]
 └── posts/
 ├── route.ts # /api/posts
 └── [slug]/
 ├── route.ts # /api/posts/[slug]
 └── comments/
 └── route.ts # /api/posts/[slug]/comments
```

### Supported HTTP Methods

```typescript
// app/api/resource/route.ts
import { NextResponse } from 'next/server';

export async function GET(request: Request) {
 return NextResponse.json({ method: 'GET' });
}

export async function POST(request: Request) {
 return NextResponse.json({ method: 'POST' });
}

export async function PUT(request: Request) {
 return NextResponse.json({ method: 'PUT' });
}

export async function PATCH(request: Request) {
 return NextResponse.json({ method: 'PATCH' });
}

export async function DELETE(request: Request) {
 return NextResponse.json({ method: 'DELETE' });
}

export async function HEAD(request: Request) {
 return new Response(null, { status: 200 });
}

export async function OPTIONS(request: Request) {
 return new Response(null, {
 status: 200,
 headers: {
 'Allow': 'GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS',
 },
 });
}
```

---

## HTTP Methods

### GET - Retrieve Data

```typescript
// app/api/posts/route.ts
import { NextResponse } from 'next/server';
import { prisma } from '@/lib/db';

export async function GET(request: Request) {
 try {
 const posts = await prisma.post.findMany({
 select: {
 id: true,
 title: true,
 excerpt: true,
 createdAt: true,
 },
 orderBy: {
 createdAt: 'desc',
 },
 });

 return NextResponse.json(posts);
 } catch (error) {
 return NextResponse.json(
 { error: 'Failed to fetch posts' },
 { status: 500 }
 );
 }
}
```

### POST - Create Data

```typescript
// app/api/posts/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
import { prisma } from '@/lib/db';

const createPostSchema = z.object({
 title: z.string.min(1).max(200),
 content: z.string.min(1),
 published: z.boolean.optional,
});

export async function POST(request: NextRequest) {
 try {
 // Parse request body
 const body = await request.json;

 // Validate
 const validatedData = createPostSchema.parse(body);

 // Create post
 const post = await prisma.post.create({
 data: {
 title: validatedData.title,
 content: validatedData.content,
 published: validatedData.published ?? false,
 },
 });

 return NextResponse.json(post, { status: 201 });
 } catch (error) {
 if (error instanceof z.ZodError) {
 return NextResponse.json(
 { error: 'Validation failed', details: error.errors },
 { status: 400 }
 );
 }

 return NextResponse.json(
 { error: 'Failed to create post' },
 { status: 500 }
 );
 }
}
```

### PUT - Replace Data

```typescript
// app/api/posts/[id]/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/db';

export async function PUT(
 request: NextRequest,
 { params }: { params: { id: string } }
) {
 try {
 const body = await request.json;

 // Replace entire resource
 const post = await prisma.post.update({
 where: { id: params.id },
 data: {
 title: body.title,
 content: body.content,
 published: body.published,
 },
 });

 return NextResponse.json(post);
 } catch (error) {
 return NextResponse.json(
 { error: 'Failed to update post' },
 { status: 500 }
 );
 }
}
```

### PATCH - Partial Update

```typescript
// app/api/posts/[id]/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/db';

export async function PATCH(
 request: NextRequest,
 { params }: { params: { id: string } }
) {
 try {
 const body = await request.json;

 // Update only provided fields
 const post = await prisma.post.update({
 where: { id: params.id },
 data: body, // Only updates fields present in body
 });

 return NextResponse.json(post);
 } catch (error) {
 return NextResponse.json(
 { error: 'Failed to patch post' },
 { status: 500 }
 );
 }
}
```

### DELETE - Remove Data

```typescript
// app/api/posts/[id]/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/db';

export async function DELETE(
 request: NextRequest,
 { params }: { params: { id: string } }
) {
 try {
 await prisma.post.delete({
 where: { id: params.id },
 });

 return NextResponse.json(
 { success: true, message: 'Post deleted' },
 { status: 200 }
 );
 } catch (error) {
 return NextResponse.json(
 { error: 'Failed to delete post' },
 { status: 500 }
 );
 }
}
```

---

## Request and Response Objects

### Reading Request Data

```typescript
// app/api/example/route.ts
import { NextRequest, NextResponse } from 'next/server';

export async function GET(request: NextRequest) {
 // URL and search params
 const url = new URL(request.url);
 const searchParams = url.searchParams;
 const query = searchParams.get('query');
 const page = Number(searchParams.get('page')) || 1;

 // Headers
 const authorization = request.headers.get('authorization');
 const contentType = request.headers.get('content-type');

 // Cookies
 const token = request.cookies.get('token');
 const session = request.cookies.get('session')?.value;

 // Method
 const method = request.method; // 'GET'

 return NextResponse.json({
 query,
 page,
 authorization,
 hasSession: !!session,
 });
}

export async function POST(request: NextRequest) {
 // JSON body
 const body = await request.json;

 // FormData
 const formData = await request.formData;
 const name = formData.get('name');
 const file = formData.get('file') as File;

 // Text body
 const text = await request.text;

 // ArrayBuffer
 const buffer = await request.arrayBuffer;

 return NextResponse.json({ received: true });
}
```

### Setting Response Data

```typescript
// app/api/example/route.ts
import { NextResponse } from 'next/server';

export async function GET {
 // Basic JSON response
 return NextResponse.json({ message: 'Success' });

 // With status code
 return NextResponse.json({ error: 'Not found' }, { status: 404 });

 // With headers
 return NextResponse.json(
 { data: 'example' },
 {
 status: 200,
 headers: {
 'Content-Type': 'application/json',
 'X-Custom-Header': 'value',
 'Cache-Control': 'max-age=3600',
 },
 }
 );

 // Set cookies
 const response = NextResponse.json({ success: true });
 response.cookies.set('token', 'abc123', {
 httpOnly: true,
 secure: process.env.NODE_ENV === 'production',
 sameSite: 'strict',
 maxAge: 60 * 60 * 24, // 1 day
 });
 return response;

 // Redirect
 return NextResponse.redirect(new URL('/login', request.url));

 // Rewrite
 return NextResponse.rewrite(new URL('/api/v2/endpoint', request.url));

 // Empty response
 return new Response(null, { status: 204 });
}
```

---

## Dynamic API Routes

### Single Dynamic Segment

```typescript
// app/api/users/[id]/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/db';

export async function GET(
 request: NextRequest,
 { params }: { params: { id: string } }
) {
 const user = await prisma.user.findUnique({
 where: { id: params.id },
 });

 if (!user) {
 return NextResponse.json(
 { error: 'User not found' },
 { status: 404 }
 );
 }

 return NextResponse.json(user);
}
```

### Multiple Dynamic Segments

```typescript
// app/api/posts/[postId]/comments/[commentId]/route.ts
import { NextRequest, NextResponse } from 'next/server';

export async function GET(
 request: NextRequest,
 { params }: { params: { postId: string; commentId: string } }
) {
 const comment = await fetchComment(params.postId, params.commentId);

 return NextResponse.json(comment);
}
```

### Catch-All Routes

```typescript
// app/api/files/[...path]/route.ts
import { NextRequest, NextResponse } from 'next/server';

export async function GET(
 request: NextRequest,
 { params }: { params: { path: string[] } }
) {
 // /api/files/a/b/c → params.path = ['a', 'b', 'c']
 const filePath = params.path.join('/');

 const file = await fetchFile(filePath);

 return NextResponse.json({ path: filePath, file });
}
```

---

## Middleware Patterns

### Authentication Middleware

```typescript
// lib/middleware/auth.ts
import { NextRequest, NextResponse } from 'next/server';

export async function withAuth(
 request: NextRequest,
 handler: (request: NextRequest) => Promise<NextResponse>
) {
 const token = request.headers.get('authorization')?.replace('Bearer ', '');

 if (!token) {
 return NextResponse.json(
 { error: 'Unauthorized' },
 { status: 401 }
 );
 }

 try {
 const user = await verifyToken(token);
 // Attach user to request (example)
 (request as any).user = user;
 return handler(request);
 } catch (error) {
 return NextResponse.json(
 { error: 'Invalid token' },
 { status: 401 }
 );
 }
}

// Usage in route
// app/api/protected/route.ts
import { withAuth } from '@/lib/middleware/auth';

async function handler(request: NextRequest) {
 const user = (request as any).user;
 return NextResponse.json({ user });
}

export async function GET(request: NextRequest) {
 return withAuth(request, handler);
}
```

### Validation Middleware

```typescript
// lib/middleware/validate.ts
import { NextRequest, NextResponse } from 'next/server';
import { z, ZodSchema } from 'zod';

export function withValidation<T extends ZodSchema>(schema: T) {
 return async (
 request: NextRequest,
 handler: (request: NextRequest, data: z.infer<T>) => Promise<NextResponse>
 ) => {
 try {
 const body = await request.json;
 const validatedData = schema.parse(body);
 return handler(request, validatedData);
 } catch (error) {
 if (error instanceof z.ZodError) {
 return NextResponse.json(
 { error: 'Validation failed', details: error.errors },
 { status: 400 }
 );
 }
 return NextResponse.json(
 { error: 'Invalid request' },
 { status: 400 }
 );
 }
 };
}

// Usage
import { withValidation } from '@/lib/middleware/validate';

const createUserSchema = z.object({
 name: z.string,
 email: z.string.email,
});

async function handler(request: NextRequest, data: z.infer<typeof createUserSchema>) {
 const user = await createUser(data);
 return NextResponse.json(user, { status: 201 });
}

export async function POST(request: NextRequest) {
 return withValidation(createUserSchema)(request, handler);
}
```

---

## Edge vs Node Runtime

### Node Runtime (Default)

```typescript
// app/api/node/route.ts
// Runs in Node.js runtime
export const runtime = 'nodejs'; // Default

export async function GET {
 // Full Node.js APIs available
 const fs = require('fs');
 const path = require('path');

 // Database connections
 const data = await prisma.user.findMany;

 return NextResponse.json(data);
}
```

### Edge Runtime

```typescript
// app/api/edge/route.ts
export const runtime = 'edge';

export async function GET(request: Request) {
 // Faster, deployed to edge network
 // Limited APIs (no fs, no Node.js modules)

 const data = await fetch('https://api.example.com/data');
 const json = await data.json;

 return NextResponse.json(json);
}
```

### When to Use Edge Runtime

```typescript
// ✅ Good use cases for Edge:
// - Simple API proxies
// - Fast responses
// - Geolocation-based routing
// - A/B testing
// - Authentication checks

// ❌ Don't use Edge for:
// - Database connections
// - File system operations
// - Heavy computations
// - Node.js-specific modules
```

---

## CORS Handling

### Basic CORS

```typescript
// app/api/data/route.ts
import { NextResponse } from 'next/server';

export async function GET {
 const data = { message: 'CORS enabled' };

 return NextResponse.json(data, {
 headers: {
 'Access-Control-Allow-Origin': '*',
 'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
 'Access-Control-Allow-Headers': 'Content-Type, Authorization',
 },
 });
}

export async function OPTIONS {
 return new Response(null, {
 status: 200,
 headers: {
 'Access-Control-Allow-Origin': '*',
 'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
 'Access-Control-Allow-Headers': 'Content-Type, Authorization',
 },
 });
}
```

### CORS Middleware

```typescript
// lib/cors.ts
import { NextResponse } from 'next/server';

const ALLOWED_ORIGINS = [
 'http://localhost:3000',
 'https://example.com',
];

export function corsHeaders(origin?: string) {
 const isAllowed = origin && ALLOWED_ORIGINS.includes(origin);

 return {
 'Access-Control-Allow-Origin': isAllowed ? origin: ALLOWED_ORIGINS[0],
 'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
 'Access-Control-Allow-Headers': 'Content-Type, Authorization',
 'Access-Control-Max-Age': '86400', // 24 hours
 };
}

// Usage in route
export async function GET(request: Request) {
 const origin = request.headers.get('origin');
 const data = { message: 'Success' };

 return NextResponse.json(data, {
 headers: corsHeaders(origin || undefined),
 });
}
```

---

## Authentication

### JWT Authentication

```typescript
// app/api/auth/login/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { SignJWT } from 'jose';
import { z } from 'zod';

const loginSchema = z.object({
 email: z.string.email,
 password: z.string.min(8),
});

export async function POST(request: NextRequest) {
 try {
 const body = await request.json;
 const { email, password } = loginSchema.parse(body);

 // Verify credentials
 const user = await verifyCredentials(email, password);
 if (!user) {
 return NextResponse.json(
 { error: 'Invalid credentials' },
 { status: 401 }
 );
 }

 // Generate JWT
 const secret = new TextEncoder.encode(process.env.JWT_SECRET);
 const token = await new SignJWT({ userId: user.id, email: user.email })
.setProtectedHeader({ alg: 'HS256' })
.setIssuedAt
.setExpirationTime('24h')
.sign(secret);

 const response = NextResponse.json({ success: true, user });

 // Set httpOnly cookie
 response.cookies.set('token', token, {
 httpOnly: true,
 secure: process.env.NODE_ENV === 'production',
 sameSite: 'strict',
 maxAge: 60 * 60 * 24, // 24 hours
 });

 return response;
 } catch (error) {
 return NextResponse.json(
 { error: 'Login failed' },
 { status: 500 }
 );
 }
}
```

### Protected Routes

```typescript
// app/api/protected/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { jwtVerify } from 'jose';

export async function GET(request: NextRequest) {
 try {
 const token = request.cookies.get('token')?.value;

 if (!token) {
 return NextResponse.json(
 { error: 'Unauthorized' },
 { status: 401 }
 );
 }

 const secret = new TextEncoder.encode(process.env.JWT_SECRET);
 const { payload } = await jwtVerify(token, secret);

 // Use payload.userId, payload.email, etc.
 const data = await fetchUserData(payload.userId as string);

 return NextResponse.json(data);
 } catch (error) {
 return NextResponse.json(
 { error: 'Invalid token' },
 { status: 401 }
 );
 }
}
```

---

## Error Handling

### Centralized Error Handling

```typescript
// lib/errors.ts
export class ApiError extends Error {
 constructor(
 public statusCode: number,
 message: string,
 public code?: string
 ) {
 super(message);
 this.name = 'ApiError';
 }
}

export function handleApiError(error: unknown) {
 if (error instanceof ApiError) {
 return NextResponse.json(
 { error: error.message, code: error.code },
 { status: error.statusCode }
 );
 }

 if (error instanceof z.ZodError) {
 return NextResponse.json(
 { error: 'Validation failed', details: error.errors },
 { status: 400 }
 );
 }

 console.error('Unhandled error:', error);

 return NextResponse.json(
 { error: 'Internal server error' },
 { status: 500 }
 );
}

// Usage
export async function GET {
 try {
 const data = await fetchData;
 if (!data) {
 throw new ApiError(404, 'Resource not found', 'RESOURCE_NOT_FOUND');
 }
 return NextResponse.json(data);
 } catch (error) {
 return handleApiError(error);
 }
}
```

---

## Rate Limiting

### Simple Rate Limiting

```typescript
// lib/rate-limit.ts (this project uses this pattern)
import { NextRequest, NextResponse } from 'next/server';

const rateLimit = new Map<string, { count: number; resetAt: number }>;

export function checkRateLimit(
 identifier: string,
 limit: number = 10,
 windowMs: number = 60000
): boolean {
 const now = Date.now;
 const record = rateLimit.get(identifier);

 if (!record || now > record.resetAt) {
 rateLimit.set(identifier, { count: 1, resetAt: now + windowMs });
 return true;
 }

 if (record.count >= limit) {
 return false;
 }

 record.count++;
 return true;
}

// Usage
export async function POST(request: NextRequest) {
 const ip = request.headers.get('x-forwarded-for') || 'unknown';

 if (!checkRateLimit(ip, 10, 60000)) {
 return NextResponse.json(
 { error: 'Too many requests' },
 { status: 429 }
 );
 }

 // Process request
 return NextResponse.json({ success: true });
}
```

---

## Best Practices

### ✅ DO

1. **Use TypeScript types**
```typescript
interface User {
 id: string;
 name: string;
 email: string;
}

export async function GET: Promise<NextResponse<User[]>> {
 const users = await fetchUsers;
 return NextResponse.json(users);
}
```

2. **Validate input with Zod**
```typescript
const schema = z.object({
 name: z.string,
 email: z.string.email,
});

const data = schema.parse(body);
```

3. **Use proper HTTP status codes**
```typescript
return NextResponse.json(data, { status: 201 }); // Created
return NextResponse.json({error}, { status: 400 }); // Bad Request
return NextResponse.json({error}, { status: 404 }); // Not Found
return NextResponse.json({error}, { status: 500 }); // Server Error
```

4. **Handle errors gracefully**
```typescript
try {
 const data = await operation;
 return NextResponse.json(data);
} catch (error) {
 return handleApiError(error);
}
```

### ❌ DON'T

1. **Don't expose sensitive data**
```typescript
// ❌ Bad
return NextResponse.json({
 user: {...user, password: user.password }
});

// ✅ Good
return NextResponse.json({
 user: { id: user.id, name: user.name }
});
```

2. **Don't skip validation**
```typescript
// ❌ Bad
const { email } = await request.json;
await saveEmail(email); // No validation!

// ✅ Good
const { email } = schema.parse(await request.json);
await saveEmail(email);
```

3. **Don't use sync operations**
```typescript
// ❌ Bad
const data = fs.readFileSync('file.txt');

// ✅ Good
const data = await fs.promises.readFile('file.txt');
```

---

## Summary

### Key Concepts
- Route handlers replace Pages Router API routes
- Support all HTTP methods (GET, POST, PUT, DELETE, etc.)
- Use NextRequest/NextResponse for enhanced functionality
- Support both Node.js and Edge runtimes
- Built-in support for CORS, auth, validation

### Common Patterns
| Pattern | Implementation |
|---------|----------------|
| CRUD API | GET, POST, PUT, DELETE routes |
| Auth | JWT tokens, httpOnly cookies |
| Validation | Zod schemas |
| Rate limiting | IP-based request counting |
| Error handling | Centralized error handler |

---

**Next**: [06-STYLING.md](./06-STYLING.md) - Learn about styling in Next.js

**Last Updated**: November 9, 2025
**Status**: Production-Ready ✅
