---
id: nextauth-06-middleware
topic: nextauth
file_role: practical
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [nextauth-fundamentals, nextauth-sessions]
related_topics: [middleware, route-protection, authorization]
embedding_keywords: [nextauth, middleware, protected-routes, authorization, access-control]
last_reviewed: 2025-11-16
---

# NextAuth.js - Middleware and Route Protection

## Purpose

Implement authentication middleware, protect routes, control access based on roles/permissions, and handle unauthorized access gracefully.

## Table of Contents

1. [Middleware Basics](#middleware-basics)
2. [Route Protection](#route-protection)
3. [Role-Based Access](#role-based-access)
4. [Advanced Patterns](#advanced-patterns)
5. [Error Handling](#error-handling)
6. [Performance Optimization](#performance-optimization)

---

## Middleware Basics

### Basic Middleware Setup

```typescript
// middleware.ts
import { withAuth } from 'next-auth/middleware'

export default withAuth({
  callbacks: {
    authorized: ({ token }) => !!token,
  },
})

export const config = {
  matcher: ['/dashboard/:path*', '/admin/:path*'],
}
```

**What this does:**
- Protects `/dashboard/*` and `/admin/*` routes
- Requires authentication (checks for valid token)
- Redirects to sign-in page if not authenticated

### Middleware Execution Flow

```
1. User requests protected route
   â†"
2. Middleware intercepts request
   â†"
3. Check authentication (token exists?)
   â†"
4. authorized() callback returns true/false
   â†"
5. If true: Allow access
   If false: Redirect to sign-in
```

---

## Route Protection

### Protect Specific Routes

```typescript
// middleware.ts
import { withAuth } from 'next-auth/middleware'

export default withAuth({
  callbacks: {
    authorized: ({ token }) => !!token,
  },
})

export const config = {
  matcher: [
    '/dashboard/:path*',
    '/profile/:path*',
    '/settings/:path*',
  ],
}
```

### Protect All Routes Except Public

```typescript
export const config = {
  matcher: [
    /*
     * Match all request paths except:
     * - api/auth/* (NextAuth routes)
     * - _next/static (static files)
     * - _next/image (image optimization)
     * - favicon.ico (favicon)
     * - public folder
     */
    '/((?!api/auth|_next/static|_next/image|favicon.ico|public).*)',
  ],
}
```

### Multiple Middleware Functions

```typescript
import { withAuth } from 'next-auth/middleware'
import { NextResponse } from 'next/server'
import type { NextRequestWithAuth } from 'next-auth/middleware'

export default withAuth(
  function middleware(request: NextRequestWithAuth) {
    // Custom logic after authentication
    console.log('Authenticated user:', request.nextauth.token?.email)

    // Add custom headers
    const response = NextResponse.next()
    response.headers.set('x-user-id', request.nextauth.token?.id as string)

    return response
  },
  {
    callbacks: {
      authorized: ({ token }) => !!token,
    },
  }
)
```

---

## Role-Based Access

### Basic Role Check

```typescript
import { withAuth } from 'next-auth/middleware'
import { NextResponse } from 'next/server'

export default withAuth(
  function middleware(req) {
    const token = req.nextauth.token

    // Admin-only routes
    if (req.nextUrl.pathname.startsWith('/admin')) {
      if (token?.role !== 'admin') {
        return NextResponse.redirect(new URL('/unauthorized', req.url))
      }
    }

    return NextResponse.next()
  },
  {
    callbacks: {
      authorized: ({ token }) => !!token,
    },
  }
)

export const config = {
  matcher: ['/dashboard/:path*', '/admin/:path*'],
}
```

### Multiple Roles

```typescript
export default withAuth(
  function middleware(req) {
    const token = req.nextauth.token
    const path = req.nextUrl.pathname

    // Define role requirements per route
    const roleRequirements: Record<string, string[]> = {
      '/admin': ['admin'],
      '/moderator': ['admin', 'moderator'],
      '/dashboard': ['admin', 'moderator', 'user'],
    }

    // Check if route requires specific roles
    for (const [routePath, allowedRoles] of Object.entries(roleRequirements)) {
      if (path.startsWith(routePath)) {
        if (!allowedRoles.includes(token?.role as string)) {
          return NextResponse.redirect(new URL('/unauthorized', req.url))
        }
      }
    }

    return NextResponse.next()
  },
  {
    callbacks: {
      authorized: ({ token }) => !!token,
    },
  }
)
```

### Permission-Based Access

```typescript
export default withAuth(
  function middleware(req) {
    const token = req.nextauth.token
    const path = req.nextUrl.pathname

    // Define permission requirements
    const permissionRequirements: Record<string, string[]> = {
      '/users/delete': ['users.delete'],
      '/posts/publish': ['posts.publish'],
      '/settings/billing': ['billing.manage'],
    }

    for (const [routePath, requiredPermissions] of Object.entries(permissionRequirements)) {
      if (path.startsWith(routePath)) {
        const userPermissions = token?.permissions as string[] || []

        const hasPermission = requiredPermissions.every(
          permission => userPermissions.includes(permission)
        )

        if (!hasPermission) {
          return NextResponse.redirect(new URL('/forbidden', req.url))
        }
      }
    }

    return NextResponse.next()
  },
  {
    callbacks: {
      authorized: ({ token }) => !!token,
    },
  }
)
```

---

## Advanced Patterns

### Conditional Middleware

```typescript
import { withAuth } from 'next-auth/middleware'
import { NextResponse } from 'next/server'

export default withAuth(
  function middleware(req) {
    const token = req.nextauth.token

    // Different logic for different route patterns
    if (req.nextUrl.pathname.startsWith('/api/admin')) {
      // API admin routes - require admin role
      if (token?.role !== 'admin') {
        return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
      }
    }

    if (req.nextUrl.pathname.startsWith('/admin')) {
      // Admin pages - require admin role
      if (token?.role !== 'admin') {
        return NextResponse.redirect(new URL('/unauthorized', req.url))
      }
    }

    return NextResponse.next()
  },
  {
    callbacks: {
      authorized: ({ token }) => !!token,
    },
  }
)

export const config = {
  matcher: ['/admin/:path*', '/api/admin/:path*'],
}
```

### Team/Organization Access

```typescript
export default withAuth(
  async function middleware(req) {
    const token = req.nextauth.token

    // Extract organization ID from URL
    const orgMatch = req.nextUrl.pathname.match(/^\/org\/([^\/]+)/)

    if (orgMatch) {
      const orgId = orgMatch[1]

      // Check if user has access to this organization
      const hasAccess = await checkOrganizationAccess(
        token?.id as string,
        orgId
      )

      if (!hasAccess) {
        return NextResponse.redirect(new URL('/unauthorized', req.url))
      }
    }

    return NextResponse.next()
  },
  {
    callbacks: {
      authorized: ({ token }) => !!token,
    },
  }
)

async function checkOrganizationAccess(userId: string, orgId: string) {
  // Check if user is member of organization
  const membership = await db.organizationMember.findFirst({
    where: {
      userId,
      organizationId: orgId,
    },
  })

  return !!membership
}
```

### Feature Flags

```typescript
export default withAuth(
  async function middleware(req) {
    const token = req.nextauth.token

    // Check if user has access to new feature
    if (req.nextUrl.pathname.startsWith('/beta')) {
      const hasBetaAccess = await checkFeatureFlag(
        token?.id as string,
        'beta_access'
      )

      if (!hasBetaAccess) {
        return NextResponse.redirect(new URL('/coming-soon', req.url))
      }
    }

    return NextResponse.next()
  },
  {
    callbacks: {
      authorized: ({ token }) => !!token,
    },
  }
)

async function checkFeatureFlag(userId: string, flag: string) {
  const userFlag = await db.featureFlag.findFirst({
    where: {
      userId,
      flag,
      enabled: true,
    },
  })

  return !!userFlag
}
```

### Rate Limiting

```typescript
import { Ratelimit } from '@upstash/ratelimit'
import { Redis } from '@upstash/redis'

const ratelimit = new Ratelimit({
  redis: Redis.fromEnv(),
  limiter: Ratelimit.slidingWindow(10, '10 s'),
})

export default withAuth(
  async function middleware(req) {
    const token = req.nextauth.token

    // Rate limit API routes per user
    if (req.nextUrl.pathname.startsWith('/api/')) {
      const { success, limit, remaining } = await ratelimit.limit(
        token?.id as string
      )

      if (!success) {
        return NextResponse.json(
          {
            error: 'Too many requests',
            limit,
            remaining,
          },
          { status: 429 }
        )
      }
    }

    return NextResponse.next()
  },
  {
    callbacks: {
      authorized: ({ token }) => !!token,
    },
  }
)
```

---

## Error Handling

### Custom Error Pages

```typescript
export default withAuth(
  function middleware(req) {
    const token = req.nextauth.token

    if (req.nextUrl.pathname.startsWith('/admin')) {
      if (token?.role !== 'admin') {
        // Redirect to custom error page with details
        const errorUrl = new URL('/error', req.url)
        errorUrl.searchParams.set('code', '403')
        errorUrl.searchParams.set('message', 'Admin access required')
        errorUrl.searchParams.set('returnUrl', req.nextUrl.pathname)

        return NextResponse.redirect(errorUrl)
      }
    }

    return NextResponse.next()
  },
  {
    callbacks: {
      authorized: ({ token }) => !!token,
    },
  }
)

// app/error/page.tsx
export default function ErrorPage({
  searchParams,
}: {
  searchParams: { code?: string; message?: string; returnUrl?: string }
}) {
  return (
    <div>
      <h1>Error {searchParams.code}</h1>
      <p>{searchParams.message}</p>
      {searchParams.returnUrl && (
        <p>You tried to access: {searchParams.returnUrl}</p>
      )}
    </div>
  )
}
```

### Graceful Degradation

```typescript
export default withAuth(
  async function middleware(req) {
    try {
      const token = req.nextauth.token

      // Attempt authorization check
      const authorized = await checkAuthorization(token)

      if (!authorized) {
        return NextResponse.redirect(new URL('/unauthorized', req.url))
      }

      return NextResponse.next()
    } catch (error) {
      console.error('Middleware error:', error)

      // Allow access but log error
      // (could also deny access depending on requirements)
      return NextResponse.next()
    }
  },
  {
    callbacks: {
      authorized: ({ token }) => !!token,
    },
  }
)
```

---

## Performance Optimization

### Minimize Database Calls

```typescript
// ❌ Bad - DB call on every request
export default withAuth(
  async function middleware(req) {
    const token = req.nextauth.token

    // Database call on EVERY request
    const user = await db.user.findUnique({
      where: { id: token?.id as string },
    })

    if (!user.isActive) {
      return NextResponse.redirect(new URL('/unauthorized', req.url))
    }

    return NextResponse.next()
  }
)

// ✅ Good - Use token data
export default withAuth(
  function middleware(req) {
    const token = req.nextauth.token

    // Check token data (no DB call)
    if (!token?.isActive) {
      return NextResponse.redirect(new URL('/unauthorized', req.url))
    }

    return NextResponse.next()
  },
  {
    callbacks: {
      // Store isActive in token during JWT callback
      authorized: ({ token }) => !!token && token.isActive,
    },
  }
)
```

### Cache Authorization Results

```typescript
import { Redis } from '@upstash/redis'

const redis = new Redis({
  url: process.env.REDIS_URL!,
  token: process.env.REDIS_TOKEN!,
})

export default withAuth(
  async function middleware(req) {
    const token = req.nextauth.token
    const cacheKey = `auth:${token?.id}:${req.nextUrl.pathname}`

    // Check cache first
    const cached = await redis.get(cacheKey)

    if (cached !== null) {
      if (!cached) {
        return NextResponse.redirect(new URL('/unauthorized', req.url))
      }
      return NextResponse.next()
    }

    // Not in cache, check authorization
    const authorized = await checkAuthorization(token, req.nextUrl.pathname)

    // Cache result for 5 minutes
    await redis.setex(cacheKey, 300, authorized ? 1 : 0)

    if (!authorized) {
      return NextResponse.redirect(new URL('/unauthorized', req.url))
    }

    return NextResponse.next()
  },
  {
    callbacks: {
      authorized: ({ token }) => !!token,
    },
  }
)
```

### Smart Matcher Patterns

```typescript
// ✅ Good - Specific matchers
export const config = {
  matcher: [
    '/dashboard/:path*',
    '/admin/:path*',
    '/api/protected/:path*',
  ],
}

// ❌ Bad - Too broad
export const config = {
  matcher: '/:path*', // Runs on EVERY route including static files
}
```

---

## Best Practices

### 1. Keep Middleware Fast

```typescript
// ✅ Good - Fast checks
export default withAuth(
  function middleware(req) {
    const token = req.nextauth.token

    // Quick role check (from token)
    if (req.nextUrl.pathname.startsWith('/admin')) {
      if (token?.role !== 'admin') {
        return NextResponse.redirect(new URL('/unauthorized', req.url))
      }
    }

    return NextResponse.next()
  }
)

// ❌ Bad - Slow database calls
export default withAuth(
  async function middleware(req) {
    const token = req.nextauth.token

    // Slow database call on every request
    const user = await db.user.findUnique({
      where: { id: token?.id as string },
      include: { permissions: true, organization: true },
    })

    // ...
  }
)
```

### 2. Use Specific Matchers

```typescript
// ✅ Good - Specific paths
export const config = {
  matcher: ['/dashboard/:path*', '/admin/:path*'],
}

// ❌ Bad - Too generic
export const config = {
  matcher: '/:path*',
}
```

### 3. Handle Errors Gracefully

```typescript
// ✅ Good - Error handling
export default withAuth(
  async function middleware(req) {
    try {
      // Authorization logic
    } catch (error) {
      console.error('Middleware error:', error)
      // Decide: allow or deny on error
      return NextResponse.redirect(new URL('/error', req.url))
    }
  }
)
```

---

## AI Pair Programming Notes

**When to load this file:**
- Protecting routes with middleware
- Implementing role-based access control
- Adding permission checks
- Optimizing middleware performance

**Typical questions:**
- "How do I protect routes?" → See Route Protection
- "How do I check user roles?" → See Role-Based Access
- "How do I handle unauthorized access?" → See Error Handling
- "How do I optimize middleware?" → See Performance Optimization

**Next steps:**
- [07-PROTECTED-ROUTES.md](./07-PROTECTED-ROUTES.md) - Route protection patterns
- [05-CALLBACKS.md](./05-CALLBACKS.md) - Callback patterns
- [09-SECURITY.md](./09-SECURITY.md) - Security best practices

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1
