---
id: nextauth-quick-reference
topic: nextauth
file_role: quickref
profile: full
difficulty_level: all-levels
kb_version: 3.1
prerequisites: []
related_topics: [authentication, oauth, sessions, security]
embedding_keywords: [nextauth, quick-reference, cheat-sheet, syntax]
last_reviewed: 2025-11-16
---

# NextAuth.js - Quick Reference

One-page cheat sheet for NextAuth.js authentication.

## Installation

```bash
npm install next-auth@beta
# or
yarn add next-auth@beta
# or
pnpm add next-auth@beta
```

---

## Basic Setup

### App Router Setup

```typescript
// app/api/auth/[...nextauth]/route.ts
import NextAuth from 'next-auth'
import GoogleProvider from 'next-auth/providers/google'

export const { handlers, auth, signIn, signOut } = NextAuth({
  providers: [
    GoogleProvider({
      clientId: process.env.GOOGLE_CLIENT_ID!,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
    }),
  ],
})

export { handlers as GET, handlers as POST }
```

### Environment Variables

```bash
# .env.local
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=your-secret-key-min-32-chars

GOOGLE_CLIENT_ID=your-client-id
GOOGLE_CLIENT_SECRET=your-client-secret
```

---

## Providers

### OAuth Providers

```typescript
// Google
import GoogleProvider from 'next-auth/providers/google'

GoogleProvider({
  clientId: process.env.GOOGLE_CLIENT_ID!,
  clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
})

// GitHub
import GitHubProvider from 'next-auth/providers/github'

GitHubProvider({
  clientId: process.env.GITHUB_CLIENT_ID!,
  clientSecret: process.env.GITHUB_CLIENT_SECRET!,
})

// Facebook
import FacebookProvider from 'next-auth/providers/facebook'

FacebookProvider({
  clientId: process.env.FACEBOOK_CLIENT_ID!,
  clientSecret: process.env.FACEBOOK_CLIENT_SECRET!,
})

// Azure AD
import AzureADProvider from 'next-auth/providers/azure-ad'

AzureADProvider({
  clientId: process.env.AZURE_AD_CLIENT_ID!,
  clientSecret: process.env.AZURE_AD_CLIENT_SECRET!,
  tenantId: process.env.AZURE_AD_TENANT_ID!,
})

// Discord
import DiscordProvider from 'next-auth/providers/discord'

DiscordProvider({
  clientId: process.env.DISCORD_CLIENT_ID!,
  clientSecret: process.env.DISCORD_CLIENT_SECRET!,
})
```

### Credentials Provider

```typescript
import CredentialsProvider from 'next-auth/providers/credentials'
import bcrypt from 'bcryptjs'

CredentialsProvider({
  name: 'Credentials',
  credentials: {
    email: { label: 'Email', type: 'email' },
    password: { label: 'Password', type: 'password' },
  },
  async authorize(credentials) {
    if (!credentials?.email || !credentials?.password) {
      return null
    }

    const user = await db.user.findUnique({
      where: { email: credentials.email },
    })

    if (!user || !user.password) {
      return null
    }

    const isValid = await bcrypt.compare(credentials.password, user.password)

    if (!isValid) {
      return null
    }

    return {
      id: user.id,
      email: user.email,
      name: user.name,
    }
  },
})
```

### Email Provider (Magic Links)

```typescript
import EmailProvider from 'next-auth/providers/email'

EmailProvider({
  server: {
    host: process.env.EMAIL_SERVER_HOST,
    port: process.env.EMAIL_SERVER_PORT,
    auth: {
      user: process.env.EMAIL_SERVER_USER,
      pass: process.env.EMAIL_SERVER_PASSWORD,
    },
  },
  from: process.env.EMAIL_FROM,
})
```

### Multiple Providers

```typescript
export const { handlers, auth } = NextAuth({
  providers: [
    GoogleProvider({ /* ... */ }),
    GitHubProvider({ /* ... */ }),
    CredentialsProvider({ /* ... */ }),
    EmailProvider({ /* ... */ }),
  ],
})
```

---

## Sessions

### JWT Sessions (Default)

```typescript
export const authOptions = {
  session: {
    strategy: 'jwt',
    maxAge: 30 * 24 * 60 * 60, // 30 days
    updateAge: 24 * 60 * 60, // 24 hours
  },
}
```

### Database Sessions

```typescript
import { PrismaAdapter } from '@auth/prisma-adapter'
import { prisma } from '@/lib/db'

export const authOptions = {
  adapter: PrismaAdapter(prisma),
  session: {
    strategy: 'database',
    maxAge: 30 * 24 * 60 * 60, // 30 days
    updateAge: 24 * 60 * 60, // 24 hours
  },
}
```

### Accessing Sessions

```typescript
// Server Component
import { auth } from '@/app/api/auth/[...nextauth]/route'

export default async function Page() {
  const session = await auth()
  return <div>Welcome {session?.user?.name}</div>
}

// Client Component
'use client'
import { useSession } from 'next-auth/react'

export default function Page() {
  const { data: session, status } = useSession()
  return <div>Welcome {session?.user?.name}</div>
}

// API Route
import { auth } from '@/app/api/auth/[...nextauth]/route'

export async function GET(req: Request) {
  const session = await auth()
  if (!session) {
    return Response.json({ error: 'Unauthorized' }, { status: 401 })
  }
  return Response.json({ user: session.user })
}

// Server Action
'use server'
import { auth } from '@/app/api/auth/[...nextauth]/route'

export async function updateProfile(data: FormData) {
  const session = await auth()
  if (!session) throw new Error('Unauthorized')
  // Update profile
}
```

---

## Callbacks

### signIn Callback

```typescript
callbacks: {
  async signIn({ user, account, profile }) {
    // Block sign-in based on conditions
    if (user.email?.endsWith('@blocked.com')) {
      return false
    }

    // Custom authorization logic
    if (account?.provider === 'google') {
      return profile?.email_verified || false
    }

    return true
  },
}
```

### jwt Callback

```typescript
callbacks: {
  async jwt({ token, user, account, trigger }) {
    // Initial sign in
    if (user) {
      token.id = user.id
      token.role = user.role
      token.permissions = user.permissions
    }

    // Update token
    if (trigger === 'update') {
      const updatedUser = await db.user.findUnique({
        where: { id: token.id },
      })
      token.role = updatedUser.role
    }

    return token
  },
}
```

### session Callback

```typescript
callbacks: {
  async session({ session, token, user }) {
    // JWT sessions
    if (token) {
      session.user.id = token.id
      session.user.role = token.role
      session.user.permissions = token.permissions
    }

    // Database sessions
    if (user) {
      session.user.id = user.id
      session.user.role = user.role
    }

    return session
  },
}
```

### redirect Callback

```typescript
callbacks: {
  async redirect({ url, baseUrl }) {
    // Allows relative callback URLs
    if (url.startsWith('/')) return `${baseUrl}${url}`

    // Allows callback URLs on the same origin
    if (new URL(url).origin === baseUrl) return url

    return baseUrl
  },
}
```

---

## Middleware (Route Protection)

### Basic Middleware

```typescript
// middleware.ts
export { default } from 'next-auth/middleware'

export const config = {
  matcher: ['/dashboard/:path*', '/admin/:path*'],
}
```

### Custom Middleware

```typescript
// middleware.ts
import { withAuth } from 'next-auth/middleware'

export default withAuth({
  callbacks: {
    authorized: ({ token }) => !!token,
  },
})

export const config = {
  matcher: ['/dashboard/:path*'],
}
```

### Role-Based Middleware

```typescript
// middleware.ts
import { withAuth } from 'next-auth/middleware'
import { NextResponse } from 'next/server'

export default withAuth(
  function middleware(req) {
    // Check for admin role
    if (req.nextUrl.pathname.startsWith('/admin')) {
      if (req.nextauth.token?.role !== 'admin') {
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

---

## Protected Routes

### Server Component Protection

```typescript
// app/dashboard/page.tsx
import { auth } from '@/app/api/auth/[...nextauth]/route'
import { redirect } from 'next/navigation'

export default async function DashboardPage() {
  const session = await auth()

  if (!session) {
    redirect('/login')
  }

  return <div>Protected content</div>
}
```

### Reusable Protection Function

```typescript
// lib/auth/require-auth.ts
import { auth } from '@/app/api/auth/[...nextauth]/route'
import { redirect } from 'next/navigation'

export async function requireAuth() {
  const session = await auth()
  if (!session) {
    redirect('/login')
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

// Usage
export default async function AdminPage() {
  const session = await requireRole('admin')
  return <div>Admin content</div>
}
```

### API Route Protection

```typescript
// app/api/profile/route.ts
import { auth } from '@/app/api/auth/[...nextauth]/route'
import { NextResponse } from 'next/server'

export async function GET(req: Request) {
  const session = await auth()

  if (!session) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  const user = await db.user.findUnique({
    where: { id: session.user.id },
  })

  return NextResponse.json({ user })
}
```

---

## Sign In/Out

### Server-Side Sign In (Server Actions)

```typescript
// app/login/page.tsx
import { signIn } from '@/app/api/auth/[...nextauth]/route'

export default function LoginPage() {
  return (
    <form
      action={async () => {
        'use server'
        await signIn('google', { redirectTo: '/dashboard' })
      }}
    >
      <button type="submit">Sign in with Google</button>
    </form>
  )
}
```

### Client-Side Sign In

```typescript
// app/login/page.tsx
'use client'
import { signIn } from 'next-auth/react'

export default function LoginPage() {
  return (
    <>
      <button onClick={() => signIn('google', { callbackUrl: '/dashboard' })}>
        Sign in with Google
      </button>

      <button onClick={() => signIn('github', { callbackUrl: '/dashboard' })}>
        Sign in with GitHub
      </button>
    </>
  )
}
```

### Credentials Sign In

```typescript
'use client'
import { signIn } from 'next-auth/react'
import { useState } from 'react'

export default function LoginPage() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()

    const result = await signIn('credentials', {
      email,
      password,
      redirect: false,
    })

    if (result?.error) {
      console.error('Sign-in failed:', result.error)
    } else {
      window.location.href = '/dashboard'
    }
  }

  return (
    <form onSubmit={handleSubmit}>
      <input
        type="email"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
      />
      <input
        type="password"
        value={password}
        onChange={(e) => setPassword(e.target.value)}
      />
      <button type="submit">Sign In</button>
    </form>
  )
}
```

### Sign Out

```typescript
// Server-Side
import { signOut } from '@/app/api/auth/[...nextauth]/route'

<form
  action={async () => {
    'use server'
    await signOut({ redirectTo: '/' })
  }}
>
  <button type="submit">Sign out</button>
</form>

// Client-Side
'use client'
import { signOut } from 'next-auth/react'

<button onClick={() => signOut({ callbackUrl: '/' })}>
  Sign out
</button>
```

---

## Database Integration

### Prisma Adapter

```typescript
// app/api/auth/[...nextauth]/route.ts
import { PrismaAdapter } from '@auth/prisma-adapter'
import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

export const { handlers, auth } = NextAuth({
  adapter: PrismaAdapter(prisma),
  session: { strategy: 'database' },
  providers: [
    GoogleProvider({ /* ... */ }),
  ],
})
```

### Prisma Schema

```prisma
// prisma/schema.prisma
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

model User {
  id            String    @id @default(cuid())
  name          String?
  email         String?   @unique
  emailVerified DateTime?
  image         String?
  accounts      Account[]
  sessions      Session[]
}

model VerificationToken {
  identifier String
  token      String   @unique
  expires    DateTime

  @@unique([identifier, token])
}
```

### Drizzle Adapter

```typescript
import { DrizzleAdapter } from '@auth/drizzle-adapter'
import { db } from '@/db'

export const { handlers, auth } = NextAuth({
  adapter: DrizzleAdapter(db),
  session: { strategy: 'database' },
})
```

---

## Security

### Secure Cookies

```typescript
cookies: {
  sessionToken: {
    name: `__Secure-next-auth.session-token`,
    options: {
      httpOnly: true,
      sameSite: 'lax',
      path: '/',
      secure: true, // HTTPS only
    },
  },
}
```

### Rate Limiting

```typescript
// lib/security/rate-limiter.ts
import { LRUCache } from 'lru-cache'

const limiter = new LRUCache({
  max: 500,
  ttl: 60 * 1000, // 1 minute
})

export async function checkRateLimit(identifier: string, limit = 5) {
  const count = (limiter.get(identifier) as number) || 0

  if (count >= limit) {
    throw new Error('Too many requests')
  }

  limiter.set(identifier, count + 1)
}

// Usage in authorize
async authorize(credentials) {
  await checkRateLimit(`signin:${credentials.email}`, 5)
  // Verify credentials
}
```

### CSRF Protection

```typescript
// Built-in CSRF protection (enabled by default)
// For custom forms, include CSRF token:

'use client'
import { getCsrfToken } from 'next-auth/react'

const csrfToken = await getCsrfToken()

<form>
  <input type="hidden" name="csrfToken" value={csrfToken} />
</form>
```

---

## Common Patterns

### Add Custom User Fields

```typescript
// 1. Extend user in callbacks
callbacks: {
  async jwt({ token, user }) {
    if (user) {
      token.id = user.id
      token.role = user.role
    }
    return token
  },
  async session({ session, token }) {
    session.user.id = token.id
    session.user.role = token.role
    return session
  },
}

// 2. Update TypeScript types
declare module 'next-auth' {
  interface Session {
    user: {
      id: string
      role: string
      email: string
      name: string
      image: string
    }
  }

  interface User {
    role: string
  }
}

declare module 'next-auth/jwt' {
  interface JWT {
    id: string
    role: string
  }
}
```

### Custom Pages

```typescript
export const { handlers, auth } = NextAuth({
  pages: {
    signIn: '/auth/signin',
    signOut: '/auth/signout',
    error: '/auth/error',
    verifyRequest: '/auth/verify-request',
    newUser: '/auth/new-user',
  },
})
```

### Events

```typescript
events: {
  async signIn({ user }) {
    console.log('User signed in:', user.email)
    await logAuditEvent('signin', user.id)
  },
  async signOut({ token }) {
    console.log('User signed out:', token?.sub)
    await logAuditEvent('signout', token?.sub)
  },
}
```

---

## tRPC Integration

### Context with Session

```typescript
// server/trpc/context.ts
import { auth } from '@/app/api/auth/[...nextauth]/route'

export async function createContext() {
  const session = await auth()
  return { session }
}
```

### Protected Procedure

```typescript
// server/trpc/trpc.ts
import { initTRPC, TRPCError } from '@trpc/server'

const t = initTRPC.context<Context>().create()

const isAuthed = t.middleware(({ ctx, next }) => {
  if (!ctx.session?.user) {
    throw new TRPCError({ code: 'UNAUTHORIZED' })
  }
  return next({ ctx: { session: ctx.session } })
})

export const protectedProcedure = t.procedure.use(isAuthed)
```

### Usage

```typescript
// server/trpc/routers/user.ts
export const userRouter = router({
  getCurrent: protectedProcedure.query(async ({ ctx }) => {
    return await db.user.findUnique({
      where: { id: ctx.session.user.id },
    })
  }),
})
```

---

## Troubleshooting

### Common Issues

```typescript
// ❌ Issue: "Invalid CSRF token"
// ✅ Solution: Check cookie settings
cookies: {
  csrfToken: {
    name: '__Host-next-auth.csrf-token',
    options: {
      httpOnly: true,
      sameSite: 'lax',
      path: '/',
      secure: process.env.NODE_ENV === 'production',
    },
  },
}

// ❌ Issue: "Session undefined in Server Components"
// ✅ Solution: Use correct import
import { auth } from '@/app/api/auth/[...nextauth]/route'
// NOT: import { getSession } from 'next-auth/react'

// ❌ Issue: "Callback URL mismatch"
// ✅ Solution: Add all callback URLs in provider console
// Google Console: https://console.cloud.google.com
// Authorized redirect URIs:
// - http://localhost:3000/api/auth/callback/google
// - https://yourdomain.com/api/auth/callback/google

// ❌ Issue: "Database sessions not working"
// ✅ Solution: Ensure session strategy is 'database'
export const authOptions = {
  adapter: PrismaAdapter(prisma),
  session: { strategy: 'database' }, // Must be 'database'
}
```

---

## Cheat Sheet Summary

| Category | Pattern | Example |
|----------|---------|---------|
| **Setup** | Basic config | `NextAuth({ providers: [...] })` |
| | Environment | `NEXTAUTH_SECRET`, `NEXTAUTH_URL` |
| **Providers** | OAuth | `GoogleProvider({ clientId, clientSecret })` |
| | Credentials | `CredentialsProvider({ authorize })` |
| | Email | `EmailProvider({ server, from })` |
| **Sessions** | JWT | `session: { strategy: 'jwt' }` |
| | Database | `session: { strategy: 'database' }` |
| | Access (Server) | `const session = await auth()` |
| | Access (Client) | `const { data: session } = useSession()` |
| **Callbacks** | signIn | `async signIn({ user, account })` |
| | jwt | `async jwt({ token, user })` |
| | session | `async session({ session, token })` |
| **Protection** | Middleware | `export { default } from 'next-auth/middleware'` |
| | Server Component | `const session = await auth(); if (!session) redirect()` |
| | API Route | `const session = await auth(); if (!session) return 401` |
| **Auth Actions** | Sign in | `await signIn('google', { redirectTo: '/dashboard' })` |
| | Sign out | `await signOut({ redirectTo: '/' })` |
| **Database** | Prisma | `adapter: PrismaAdapter(prisma)` |
| | Drizzle | `adapter: DrizzleAdapter(db)` |

---

## Quick Links

### Core Documentation
- **[README.md](./README.md)** - Complete overview
- **[INDEX.md](./INDEX.md)** - Navigation and problem-based quick find
- **[01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md)** - Getting started

### Common Tasks
- **Add OAuth provider** → [02-PROVIDERS.md](./02-PROVIDERS.md)
- **Protect routes** → [06-MIDDLEWARE.md](./06-MIDDLEWARE.md)
- **Choose session strategy** → [04-JWT-VS-DATABASE.md](./04-JWT-VS-DATABASE.md)
- **Add custom fields** → [05-CALLBACKS.md](./05-CALLBACKS.md)
- **Database integration** → [10-INTEGRATIONS.md](./10-INTEGRATIONS.md)
- **Security hardening** → [09-SECURITY.md](./09-SECURITY.md)
- **Production config** → [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md)

### External Resources
- [Official Docs](https://next-auth.js.org/)
- [GitHub](https://github.com/nextauthjs/next-auth)
- [Providers](https://next-auth.js.org/providers/)
- [Adapters](https://authjs.dev/reference/adapters)

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1
