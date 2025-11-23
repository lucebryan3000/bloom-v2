---
id: nextauth-07-protected-routes
topic: nextauth
file_role: practical
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [nextauth-fundamentals, nextauth-sessions, nextauth-middleware]
related_topics: [route-protection, access-control, authorization]
embedding_keywords: [nextauth, protected-routes, authorization, access-control, server-components]
last_reviewed: 2025-11-16
---

# NextAuth.js - Protected Routes

## Purpose

Implement route protection at multiple levels: middleware, Server Components, Client Components, API Routes, and Server Actions with comprehensive access control patterns.

## Table of Contents

1. [Protection Strategies](#protection-strategies)
2. [Server Component Protection](#server-component-protection)
3. [Client Component Protection](#client-component-protection)
4. [API Route Protection](#api-route-protection)
5. [Server Actions Protection](#server-actions-protection)
6. [Advanced Patterns](#advanced-patterns)

---

## Protection Strategies

### Multi-Layer Protection

```typescript
// Layer 1: Middleware (fastest, edge)
// middleware.ts
export { default } from 'next-auth/middleware'
export const config = { matcher: ['/dashboard/:path*'] }

// Layer 2: Server Component (server-side)
// app/dashboard/page.tsx
import { redirect } from 'next/navigation'
import { getServerSession } from 'next-auth'

export default async function DashboardPage() {
  const session = await getServerSession()
  if (!session) redirect('/auth/signin')
  // ...
}

// Layer 3: Client Component (client-side)
// components/UserProfile.tsx
'use client'
import { useSession } from 'next-auth/react'

export function UserProfile() {
  const { data: session, status } = useSession({
    required: true,
    onUnauthenticated() {
      redirect('/auth/signin')
    },
  })
  // ...
}
```

### When to Use Each Layer

```typescript
// Middleware
✅ Fast edge protection
✅ Protect entire route trees
✅ Simple token-based checks
❌ Cannot access request body
❌ Limited to token data

// Server Components
✅ Full session access
✅ Can query database
✅ SEO-friendly (rendered on server)
✅ No client-side flash
❌ Slower than middleware

// Client Components
✅ Interactive UI
✅ Real-time session updates
✅ Loading states
❌ Client-side flash possible
❌ Not SEO-friendly
```

---

## Server Component Protection

### Basic Protection

```typescript
// app/dashboard/page.tsx
import { getServerSession } from 'next-auth'
import { redirect } from 'next/navigation'
import { authOptions } from '@/app/api/auth/[...nextauth]/route'

export default async function DashboardPage() {
  const session = await getServerSession(authOptions)

  if (!session) {
    redirect('/auth/signin')
  }

  return (
    <div>
      <h1>Welcome, {session.user.name}</h1>
    </div>
  )
}
```

### Role-Based Protection

```typescript
// app/admin/page.tsx
import { getServerSession } from 'next-auth'
import { redirect } from 'next/navigation'
import { authOptions } from '@/app/api/auth/[...nextauth]/route'

export default async function AdminPage() {
  const session = await getServerSession(authOptions)

  if (!session) {
    redirect('/auth/signin')
  }

  if (session.user.role !== 'admin') {
    redirect('/unauthorized')
  }

  return (
    <div>
      <h1>Admin Dashboard</h1>
    </div>
  )
}
```

### Permission-Based Protection

```typescript
// app/users/delete/page.tsx
import { getServerSession } from 'next-auth'
import { redirect } from 'next/navigation'

export default async function DeleteUserPage() {
  const session = await getServerSession(authOptions)

  if (!session) {
    redirect('/auth/signin')
  }

  const permissions = session.user.permissions as string[]

  if (!permissions.includes('users.delete')) {
    redirect('/forbidden')
  }

  return (
    <div>
      <h1>Delete User</h1>
    </div>
  )
}
```

### Reusable Protection Functions

```typescript
// lib/auth/protect.ts
import { getServerSession } from 'next-auth'
import { redirect } from 'next/navigation'
import { authOptions } from '@/app/api/auth/[...nextauth]/route'

export async function requireAuth() {
  const session = await getServerSession(authOptions)

  if (!session) {
    redirect('/auth/signin')
  }

  return session
}

export async function requireRole(role: string) {
  const session = await requireAuth()

  if (session.user.role !== role) {
    redirect('/unauthorized')
  }

  return session
}

export async function requirePermission(permission: string) {
  const session = await requireAuth()
  const permissions = session.user.permissions as string[]

  if (!permissions.includes(permission)) {
    redirect('/forbidden')
  }

  return session
}

// Usage
// app/admin/page.tsx
import { requireRole } from '@/lib/auth/protect'

export default async function AdminPage() {
  const session = await requireRole('admin')

  return <div>Admin content</div>
}
```

---

## Client Component Protection

### Basic Client Protection

```typescript
'use client'

import { useSession } from 'next-auth/react'
import { redirect } from 'next/navigation'

export function ProtectedContent() {
  const { data: session, status } = useSession({
    required: true,
    onUnauthenticated() {
      redirect('/auth/signin')
    },
  })

  if (status === 'loading') {
    return <div>Loading...</div>
  }

  return (
    <div>
      <h1>Protected Content</h1>
      <p>Welcome, {session?.user?.name}</p>
    </div>
  )
}
```

### Custom Protection Hook

```typescript
'use client'

import { useSession } from 'next-auth/react'
import { useRouter } from 'next/navigation'
import { useEffect } from 'react'

export function useRequireAuth(redirectTo: string = '/auth/signin') {
  const { data: session, status } = useSession()
  const router = useRouter()

  useEffect(() => {
    if (status === 'loading') return

    if (!session) {
      router.push(redirectTo)
    }
  }, [session, status, router, redirectTo])

  return { session, status }
}

// Usage
export function ProfilePage() {
  const { session, status } = useRequireAuth()

  if (status === 'loading') {
    return <div>Loading...</div>
  }

  return (
    <div>
      <h1>Profile: {session?.user?.name}</h1>
    </div>
  )
}
```

### Role-Based Client Protection

```typescript
'use client'

export function useRequireRole(role: string) {
  const { data: session, status } = useSession()
  const router = useRouter()

  useEffect(() => {
    if (status === 'loading') return

    if (!session) {
      router.push('/auth/signin')
      return
    }

    if (session.user.role !== role) {
      router.push('/unauthorized')
    }
  }, [session, status, role, router])

  return { session, status }
}

// Usage
export function AdminPanel() {
  const { session, status } = useRequireRole('admin')

  if (status === 'loading') {
    return <div>Loading...</div>
  }

  return <div>Admin Panel</div>
}
```

---

## API Route Protection

### Basic API Protection

```typescript
// app/api/protected/route.ts
import { getServerSession } from 'next-auth'
import { authOptions } from '../auth/[...nextauth]/route'
import { NextResponse } from 'next/server'

export async function GET(request: Request) {
  const session = await getServerSession(authOptions)

  if (!session) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  return NextResponse.json({ data: 'Protected data' })
}
```

### Role-Based API Protection

```typescript
// app/api/admin/users/route.ts
export async function DELETE(request: Request) {
  const session = await getServerSession(authOptions)

  if (!session) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  if (session.user.role !== 'admin') {
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
  }

  // Delete user logic
  const { userId } = await request.json()
  await db.user.delete({ where: { id: userId } })

  return NextResponse.json({ success: true })
}
```

### Reusable API Protection

```typescript
// lib/auth/api-protect.ts
import { getServerSession } from 'next-auth'
import { NextResponse } from 'next/server'
import { authOptions } from '@/app/api/auth/[...nextauth]/route'

export async function withAuth(
  handler: (request: Request, session: Session) => Promise<Response>
) {
  return async (request: Request) => {
    const session = await getServerSession(authOptions)

    if (!session) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    return handler(request, session)
  }
}

export async function withRole(
  role: string,
  handler: (request: Request, session: Session) => Promise<Response>
) {
  return async (request: Request) => {
    const session = await getServerSession(authOptions)

    if (!session) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    if (session.user.role !== role) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }

    return handler(request, session)
  }
}

// Usage
// app/api/admin/route.ts
export const GET = withRole('admin', async (request, session) => {
  return NextResponse.json({ data: 'Admin data' })
})
```

---

## Server Actions Protection

### Basic Server Action Protection

```typescript
// app/actions/user.ts
'use server'

import { getServerSession } from 'next-auth'
import { authOptions } from '@/app/api/auth/[...nextauth]/route'

export async function updateProfile(formData: FormData) {
  const session = await getServerSession(authOptions)

  if (!session) {
    throw new Error('Unauthorized')
  }

  const name = formData.get('name') as string

  await db.user.update({
    where: { id: session.user.id },
    data: { name },
  })

  return { success: true }
}
```

### Role-Based Server Action

```typescript
'use server'

export async function deleteUser(userId: string) {
  const session = await getServerSession(authOptions)

  if (!session) {
    throw new Error('Unauthorized')
  }

  if (session.user.role !== 'admin') {
    throw new Error('Forbidden: Admin access required')
  }

  await db.user.delete({
    where: { id: userId },
  })

  return { success: true }
}
```

### Reusable Server Action Protection

```typescript
// lib/auth/action-protect.ts
'use server'

import { getServerSession } from 'next-auth'

export async function requireAuthAction() {
  const session = await getServerSession(authOptions)

  if (!session) {
    throw new Error('Unauthorized')
  }

  return session
}

export async function requireRoleAction(role: string) {
  const session = await requireAuthAction()

  if (session.user.role !== role) {
    throw new Error(`Forbidden: ${role} access required`)
  }

  return session
}

// Usage
'use server'

import { requireRoleAction } from '@/lib/auth/action-protect'

export async function deleteUser(userId: string) {
  await requireRoleAction('admin')

  await db.user.delete({ where: { id: userId } })

  return { success: true }
}
```

---

## Advanced Patterns

### Dynamic Permission Checks

```typescript
// lib/auth/permissions.ts
export async function checkPermission(
  userId: string,
  resource: string,
  action: string
): Promise<boolean> {
  const permission = await db.permission.findFirst({
    where: {
      userId,
      resource,
      action,
    },
  })

  return !!permission
}

// Usage in Server Component
export default async function EditPostPage({ params }: { params: Promise<{ id: string }> }) {
  const session = await requireAuth()
  const { id: postId } = await params

  const canEdit = await checkPermission(session.user.id, 'post', 'edit')

  if (!canEdit) {
    redirect('/forbidden')
  }

  return <div>Edit Post</div>
}
```

### Resource Ownership

```typescript
// lib/auth/ownership.ts
export async function requireOwnership(
  userId: string,
  resourceType: 'post' | 'comment' | 'profile',
  resourceId: string
): Promise<boolean> {
  const resource = await db[resourceType].findUnique({
    where: { id: resourceId },
    select: { authorId: true },
  })

  return resource?.authorId === userId
}

// Usage
export default async function EditPostPage({ params }: { params: Promise<{ id: string }> }) {
  const session = await requireAuth()
  const { id: postId } = await params

  const isOwner = await requireOwnership(session.user.id, 'post', postId)

  if (!isOwner) {
    redirect('/forbidden')
  }

  return <div>Edit Your Post</div>
}
```

### Time-Based Access

```typescript
// lib/auth/time-based.ts
export function checkBusinessHours(): boolean {
  const now = new Date()
  const hour = now.getHours()
  const day = now.getDay()

  // Monday-Friday, 9 AM - 5 PM
  const isWeekday = day >= 1 && day <= 5
  const isBusinessHour = hour >= 9 && hour < 17

  return isWeekday && isBusinessHour
}

// Usage
export default async function AdminPage() {
  await requireRole('admin')

  if (!checkBusinessHours()) {
    return (
      <div>
        <h1>Access Restricted</h1>
        <p>Admin access is only available during business hours (Mon-Fri, 9 AM - 5 PM)</p>
      </div>
    )
  }

  return <div>Admin Dashboard</div>
}
```

---

## Best Practices

### 1. Layer Protection

```typescript
// ✅ Good - Multiple layers
// middleware.ts
export { default } from 'next-auth/middleware'
export const config = { matcher: ['/dashboard/:path*'] }

// app/dashboard/page.tsx (additional server-side check)
export default async function DashboardPage() {
  const session = await requireAuth()
  // ...
}
```

### 2. Clear Error Messages

```typescript
// ✅ Good - Descriptive errors
if (!session) {
  throw new Error('Authentication required')
}

if (session.user.role !== 'admin') {
  throw new Error('Admin access required')
}

// ❌ Bad - Generic errors
if (!authorized) {
  throw new Error('Error')
}
```

### 3. Consistent Protection Patterns

```typescript
// ✅ Good - Reusable functions
export default async function Page() {
  await requireRole('admin')
  // ...
}

// ❌ Bad - Duplicated logic
export default async function Page() {
  const session = await getServerSession()
  if (!session) redirect('/auth/signin')
  if (session.user.role !== 'admin') redirect('/unauthorized')
  // ... repeated in every file
}
```

---

## AI Pair Programming Notes

**When to load this file:**
- Protecting pages and routes
- Implementing access control
- Role-based authorization
- Resource ownership checks

**Typical questions:**
- "How do I protect a Server Component?" → See Server Component Protection
- "How do I protect API routes?" → See API Route Protection
- "How do I check user roles?" → See Role-Based Protection
- "How do I protect Server Actions?" → See Server Actions Protection

**Next steps:**
- [06-MIDDLEWARE.md](./06-MIDDLEWARE.md) - Middleware patterns
- [05-CALLBACKS.md](./05-CALLBACKS.md) - Callback customization
- [09-SECURITY.md](./09-SECURITY.md) - Security best practices

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1
