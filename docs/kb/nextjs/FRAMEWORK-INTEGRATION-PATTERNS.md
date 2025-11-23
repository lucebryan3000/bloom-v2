---
id: nextjs-patterns
topic: nextjs
file_role: patterns
profile: full
difficulty_level: intermediate-advanced
kb_version: 3.1
prerequisites: [nextjs-basics, react, typescript]
related_topics: [react, typescript, prisma]
embedding_keywords: [patterns, examples, integration, best-practices, nextjs-patterns]
last_reviewed: 2025-11-13
---

# Next.js Framework Integration Patterns

**Purpose**: Production-ready Next.js patterns and integration examples.

---

## 📋 Table of Contents

1. [App Router Patterns](#app-router-patterns)
2. [Server Components](#server-components)
3. [Client Components](#client-components)
4. [API Routes](#api-routes)
5. [Data Fetching](#data-fetching)

---

## App Router Patterns

### Pattern 1: File-Based Routing

```
app/
 layout.tsx # Root layout
 page.tsx # Homepage (/)
 about/
 page.tsx # About page (/about)
 blog/
 [slug]/
 page.tsx # Dynamic blog post (/blog/my-post)
```

### Pattern 2: Dynamic Routes with Params

```typescript
// app/blog/[slug]/page.tsx
export default async function BlogPost({
 params
}: {
 params: Promise<{ slug: string }>
}) {
 const { slug } = await params; // Next.js 16: params is a Promise
 const post = await getPost(slug);
 return <article>{post.content}</article>;
}
```

---

## Server Components

### Pattern 3: Server Component with Data Fetching

```typescript
// app/users/page.tsx (Server Component by default)
async function getUsers {
 const res = await fetch('https://api.example.com/users', {
 next: { revalidate: 3600 } // Cache for 1 hour
 });
 return res.json;
}

export default async function UsersPage {
 const users = await getUsers;
 return (
 <div>
 {users.map(user => (
 <div key={user.id}>{user.name}</div>
 ))}
 </div>
 );
}
```

### Pattern 4: Streaming with Suspense

```typescript
import { Suspense } from 'react';

export default function Page {
 return (
 <div>
 <h1>My Page</h1>
 <Suspense fallback={<div>Loading...</div>}>
 <SlowComponent />
 </Suspense>
 </div>
 );
}
```

---

## Client Components

### Pattern 5: Client Component with Interactivity

```typescript
'use client';

import { useState } from 'react';

export function Counter {
 const [count, setCount] = useState(0);
 return (
 <button onClick={ => setCount(count + 1)}>
 Count: {count}
 </button>
 );
}
```

### Pattern 6: Client Component with useEffect

```typescript
'use client';

import { useEffect, useState } from 'react';

export function ClientData {
 const [data, setData] = useState(null);

 useEffect( => {
 fetch('/api/data')
.then(res => res.json)
.then(setData);
 }, []);

 return <div>{data ? JSON.stringify(data): 'Loading...'}</div>;
}
```

---

## API Routes

### Pattern 7: GET Route Handler

```typescript
// app/api/users/route.ts
import { NextResponse } from 'next/server';

export async function GET {
 const users = await prisma.user.findMany;
 return NextResponse.json(users);
}
```

### Pattern 8: POST Route with Validation

```typescript
// app/api/users/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';

const CreateUserSchema = z.object({
 name: z.string,
 email: z.string.email
});

export async function POST(request: NextRequest) {
 try {
 const body = await request.json;
 const data = CreateUserSchema.parse(body);

 const user = await prisma.user.create({ data });
 return NextResponse.json(user, { status: 201 });
 } catch (error) {
 return NextResponse.json(
 { error: 'Invalid input' },
 { status: 400 }
 );
 }
}
```

---

## Data Fetching

### Pattern 9: Parallel Data Fetching

```typescript
export default async function Page {
 const [users, posts] = await Promise.all([
 fetch('/api/users').then(r => r.json),
 fetch('/api/posts').then(r => r.json)
 ]);

 return (
 <div>
 <UserList users={users} />
 <PostList posts={posts} />
 </div>
 );
}
```

### Pattern 10: Incremental Static Regeneration (ISR)

```typescript
export default async function Page {
 const data = await fetch('https://api.example.com/data', {
 next: { revalidate: 60 } // Revalidate every 60 seconds
 });

 return <div>{/* Render data */}</div>;
}
```

---

## Best Practices

1. **Server Components by Default**: Use client components only when needed
2. **Type Safety**: Use TypeScript for all components and routes
3. **Error Handling**: Implement error.tsx for graceful error handling
4. **Loading States**: Use loading.tsx for better UX
5. **Metadata**: Export metadata for SEO

---

## Related Files

- **Quick Syntax**: [QUICK-REFERENCE.md](./QUICK-REFERENCE.md)
- **Overview**: [README.md](./README.md)
- **Navigation**: [INDEX.md](./INDEX.md)

---

**All examples are production-ready patterns for Next.js 16+ App Router!**
