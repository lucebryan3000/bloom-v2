---
id: nextauth-03-sessions
topic: nextauth
file_role: practical
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [nextauth-fundamentals, nextauth-providers]
related_topics: [session-management, jwt, database-sessions]
embedding_keywords: [nextauth, session, jwt, database, session-management]
last_reviewed: 2025-11-16
---

# NextAuth.js - Session Management

## Purpose

Comprehensive guide to session management in NextAuth.js including JWT sessions, database sessions, session configuration, access patterns, and security best practices.

## Table of Contents

1. [Session Basics](#session-basics)
2. [JWT Sessions](#jwt-sessions)
3. [Database Sessions](#database-sessions)
4. [Accessing Sessions](#accessing-sessions)
5. [Session Configuration](#session-configuration)
6. [Session Security](#session-security)

---

## Session Basics

### What is a Session?

A session represents an authenticated user's active connection to your application.

```typescript
// Session object structure
{
  user: {
    id: string
    name: string
    email: string
    image: string
  },
  expires: string // ISO 8601 date
}
```

### Session Strategies

NextAuth.js supports two session strategies:

```typescript
// JWT Strategy (default)
session: {
  strategy: 'jwt', // Session data stored in encrypted JWT
}

// Database Strategy
session: {
  strategy: 'database', // Session data stored in database
}
```

**Comparison:**

| Feature | JWT | Database |
|---------|-----|----------|
| **Storage** | Client (encrypted cookie) | Server (database) |
| **Performance** | ✅ Fast (no DB calls) | ⚠️ Requires DB query |
| **Scalability** | ✅ Stateless, infinite scale | ⚠️ Limited by database |
| **Invalidation** | ⚠️ Only on expiry | ✅ Immediate |
| **Data size** | ⚠️ Limited (~4KB cookie) | ✅ Unlimited |
| **Security** | ✅ Encrypted, signed | ✅ Server-side only |
| **Required for** | Credentials provider | Email provider |

---

## JWT Sessions

### Basic JWT Configuration

```typescript
// app/api/auth/[...nextauth]/route.ts
import NextAuth from 'next-auth'
import { JWT } from 'next-auth/jwt'

export const authOptions = {
  providers: [
    // Your providers
  ],
  session: {
    strategy: 'jwt',
    maxAge: 30 * 24 * 60 * 60, // 30 days
    updateAge: 24 * 60 * 60, // 24 hours
  },
  jwt: {
    secret: process.env.NEXTAUTH_SECRET,
    maxAge: 30 * 24 * 60 * 60, // 30 days
  },
}

const handler = NextAuth(authOptions)
export { handler as GET, handler as POST }
```

### JWT Callbacks

```typescript
callbacks: {
  async jwt({ token, user, account, profile, trigger, session }) {
    // Initial sign in
    if (user) {
      token.id = user.id
      token.role = user.role
    }

    // Subsequent requests
    return token
  },

  async session({ session, token }) {
    // Add custom fields to session
    if (session.user) {
      session.user.id = token.id as string
      session.user.role = token.role as string
    }

    return session
  }
}
```

### Custom JWT Data

```typescript
// Extend types
declare module 'next-auth' {
  interface Session {
    user: {
      id: string
      email: string
      name: string
      role: string
      department: string
    }
  }

  interface User {
    role: string
    department: string
  }
}

declare module 'next-auth/jwt' {
  interface JWT {
    id: string
    role: string
    department: string
  }
}

// Callbacks
callbacks: {
  async jwt({ token, user }) {
    if (user) {
      token.id = user.id
      token.role = user.role
      token.department = user.department
    }
    return token
  },

  async session({ session, token }) {
    session.user.id = token.id
    session.user.role = token.role
    session.user.department = token.department
    return session
  }
}
```

### JWT Encryption

```typescript
// Custom JWT encryption
import { encode, decode } from 'next-auth/jwt'

// Encode (sign and encrypt)
const token = await encode({
  token: { userId: '123', role: 'admin' },
  secret: process.env.NEXTAUTH_SECRET!,
  maxAge: 30 * 24 * 60 * 60,
})

// Decode (verify and decrypt)
const decoded = await decode({
  token,
  secret: process.env.NEXTAUTH_SECRET!,
})
```

---

## Database Sessions

### Basic Database Configuration

```typescript
import NextAuth from 'next-auth'
import { PrismaAdapter } from '@next-auth/prisma-adapter'
import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

export const authOptions = {
  adapter: PrismaAdapter(prisma),
  providers: [
    // Your providers (NOT Credentials)
  ],
  session: {
    strategy: 'database',
    maxAge: 30 * 24 * 60 * 60, // 30 days
    updateAge: 24 * 60 * 60, // Update session in DB every 24 hours
  },
}
```

### Prisma Schema

```prisma
// prisma/schema.prisma
model User {
  id            String    @id @default(cuid())
  name          String?
  email         String?   @unique
  emailVerified DateTime?
  image         String?
  accounts      Account[]
  sessions      Session[]
}

model Account {
  id                String  @id @default(cuid())
  userId            String
  type              String
  provider          String
  providerAccountId String
  refresh_token     String? @db.Text
  access_token      String? @db.Text
  expires_at        Int?
  token_type        String?
  scope             String?
  id_token          String? @db.Text
  session_state     String?

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@unique([provider, providerAccountId])
}

model Session {
  id           String   @id @default(cuid())
  sessionToken String   @unique
  userId       String
  expires      DateTime
  user         User     @relation(fields: [userId], references: [id], onDelete: Cascade)
}

model VerificationToken {
  identifier String
  token      String   @unique
  expires    DateTime

  @@unique([identifier, token])
}
```

### Database Session Callbacks

```typescript
callbacks: {
  async session({ session, user }) {
    // Add user data from database
    if (session.user) {
      session.user.id = user.id
      session.user.role = user.role
    }

    return session
  }
}
```

---

## Accessing Sessions

### Server Components (App Router)

```typescript
// app/dashboard/page.tsx
import { getServerSession } from 'next-auth'
import { authOptions } from '@/app/api/auth/[...nextauth]/route'

export default async function DashboardPage() {
  const session = await getServerSession(authOptions)

  if (!session) {
    return <div>Not authenticated</div>
  }

  return (
    <div>
      <h1>Welcome, {session.user.name}</h1>
      <p>Email: {session.user.email}</p>
    </div>
  )
}
```

### Client Components

```typescript
'use client'

import { useSession } from 'next-auth/react'

export function UserProfile() {
  const { data: session, status } = useSession()

  if (status === 'loading') {
    return <div>Loading...</div>
  }

  if (status === 'unauthenticated') {
    return <div>Not signed in</div>
  }

  return (
    <div>
      <p>Signed in as {session?.user?.email}</p>
    </div>
  )
}
```

### API Routes

```typescript
// app/api/user/route.ts
import { getServerSession } from 'next-auth'
import { authOptions } from '../auth/[...nextauth]/route'

export async function GET(request: Request) {
  const session = await getServerSession(authOptions)

  if (!session) {
    return Response.json({ error: 'Unauthorized' }, { status: 401 })
  }

  return Response.json({
    user: session.user,
  })
}
```

### Route Handlers with Session

```typescript
import { getServerSession } from 'next-auth'
import { authOptions } from '@/app/api/auth/[...nextauth]/route'

export async function POST(request: Request) {
  const session = await getServerSession(authOptions)

  if (!session?.user) {
    return Response.json({ error: 'Unauthorized' }, { status: 401 })
  }

  // Check role
  if (session.user.role !== 'admin') {
    return Response.json({ error: 'Forbidden' }, { status: 403 })
  }

  // Proceed with admin-only logic
  const body = await request.json()
  // ...

  return Response.json({ success: true })
}
```

### Middleware

```typescript
// middleware.ts
import { withAuth } from 'next-auth/middleware'

export default withAuth(
  function middleware(req) {
    console.log('Authenticated user:', req.nextauth.token)
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

---

## Session Configuration

### Max Age and Update

```typescript
session: {
  strategy: 'jwt',

  // Sessions last 30 days
  maxAge: 30 * 24 * 60 * 60, // 30 days

  // Update session in database every 24 hours
  updateAge: 24 * 60 * 60, // 24 hours
}
```

### Cookie Configuration

```typescript
cookies: {
  sessionToken: {
    name: `__Secure-next-auth.session-token`,
    options: {
      httpOnly: true,
      sameSite: 'lax',
      path: '/',
      secure: process.env.NODE_ENV === 'production',
    },
  },
}
```

### Session Callback

```typescript
callbacks: {
  async session({ session, token, user }) {
    // JWT strategy: user data in token
    // Database strategy: user data from database

    // Add custom fields
    session.customField = 'custom value'

    return session
  }
}
```

---

## Session Security

### CSRF Protection

```typescript
// Automatic CSRF protection enabled by default
pages: {
  signIn: '/auth/signin',
  signOut: '/auth/signout',
  error: '/auth/error',
}

// CSRF token automatically included in forms
```

### Secure Cookies

```typescript
cookies: {
  sessionToken: {
    name: `__Secure-next-auth.session-token`,
    options: {
      httpOnly: true, // Not accessible via JavaScript
      sameSite: 'lax', // CSRF protection
      path: '/',
      secure: process.env.NODE_ENV === 'production', // HTTPS only in production
      domain: '.example.com', // Subdomain support
    },
  },
}
```

### Session Validation

```typescript
callbacks: {
  async session({ session, token }) {
    // Validate session on every request
    if (token.exp && Date.now() > token.exp * 1000) {
      // Session expired
      return null
    }

    // Fetch fresh user data from database
    const user = await db.user.findUnique({
      where: { id: token.id as string },
    })

    if (!user || !user.isActive) {
      // User deleted or deactivated
      return null
    }

    return session
  }
}
```

### Session Invalidation

```typescript
// Force logout all sessions (JWT)
// 1. Change NEXTAUTH_SECRET environment variable
// All existing JWTs become invalid

// Force logout single session (Database)
async function revokeSession(sessionToken: string) {
  await db.session.delete({
    where: { sessionToken },
  })
}

// Force logout all user sessions (Database)
async function revokeAllUserSessions(userId: string) {
  await db.session.deleteMany({
    where: { userId },
  })
}
```

---

## Advanced Patterns

### Sliding Sessions

```typescript
// Automatically extend session on activity
session: {
  strategy: 'jwt',
  maxAge: 30 * 24 * 60 * 60, // 30 days
  updateAge: 24 * 60 * 60, // Extend every 24 hours
}

callbacks: {
  async jwt({ token, user, account, trigger }) {
    // Update timestamp on every request
    if (trigger === 'update') {
      token.iat = Math.floor(Date.now() / 1000)
    }
    return token
  }
}
```

### Multi-Factor Authentication

```typescript
callbacks: {
  async signIn({ user, account }) {
    // Check if MFA is enabled
    const userWithMFA = await db.user.findUnique({
      where: { id: user.id },
      select: { mfaEnabled: true, mfaVerified: true },
    })

    if (userWithMFA?.mfaEnabled && !userWithMFA?.mfaVerified) {
      // Redirect to MFA verification page
      return '/auth/verify-mfa'
    }

    return true
  }
}
```

### Session Refresh

```typescript
'use client'

import { useSession } from 'next-auth/react'
import { useEffect } from 'react'

export function SessionRefresh() {
  const { data: session, update } = useSession()

  useEffect(() => {
    // Refresh session every 5 minutes
    const interval = setInterval(() => {
      update()
    }, 5 * 60 * 1000)

    return () => clearInterval(interval)
  }, [update])

  return null
}
```

---

## Best Practices

### 1. Use JWT for Scalability

```typescript
// ✅ Good - JWT for stateless apps
session: {
  strategy: 'jwt',
}

// ⚠️ Database only when needed
session: {
  strategy: 'database', // When you need immediate invalidation
}
```

### 2. Keep Sessions Short

```typescript
// ✅ Good - Short-lived sessions
session: {
  maxAge: 7 * 24 * 60 * 60, // 7 days
}

// ❌ Bad - Long-lived sessions
session: {
  maxAge: 365 * 24 * 60 * 60, // 1 year (too long)
}
```

### 3. Validate Sessions

```typescript
// ✅ Good - Validate on critical operations
export async function deleteAccount() {
  const session = await getServerSession(authOptions)

  if (!session?.user) {
    throw new Error('Unauthorized')
  }

  // Verify session is still valid
  const user = await db.user.findUnique({
    where: { id: session.user.id },
  })

  if (!user) {
    throw new Error('User not found')
  }

  // Proceed with deletion
}
```

---

## AI Pair Programming Notes

**When to load this file:**
- Configuring session management
- Choosing between JWT and database sessions
- Accessing session data
- Implementing session security
- Session invalidation

**Typical questions:**
- "Should I use JWT or database sessions?" → See Session Basics → Session Strategies
- "How do I access session in Server Components?" → See Accessing Sessions → Server Components
- "How do I add custom data to sessions?" → See JWT Sessions → Custom JWT Data
- "How do I invalidate sessions?" → See Session Security → Session Invalidation

**Next steps:**
- [04-JWT-VS-DATABASE.md](./04-JWT-VS-DATABASE.md) - Deep dive into session strategies
- [05-CALLBACKS.md](./05-CALLBACKS.md) - Callback patterns
- [09-SECURITY.md](./09-SECURITY.md) - Security best practices

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1
