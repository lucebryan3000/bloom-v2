---
id: nextauth-readme
topic: nextauth
file_role: overview
profile: full
difficulty_level: beginner
kb_version: 3.1
prerequisites: [nextjs-basics, react-basics]
related_topics: [authentication, oauth, jwt, sessions]
embedding_keywords: [nextauth, authentication, oauth, jwt, sessions, next.js]
last_reviewed: 2025-11-16
---

# NextAuth.js Knowledge Base

Complete authentication solution for Next.js applications with built-in providers, sessions, and security.

## What is NextAuth.js?

NextAuth.js is a complete open-source authentication solution for Next.js applications. It provides:

- **Built-in OAuth providers** - Google, GitHub, Facebook, Twitter, and 50+ more
- **Flexible sessions** - JWT (stateless) or database-backed sessions
- **Easy integration** - Works seamlessly with Next.js App Router and Pages Router
- **Secure by default** - CSRF protection, encrypted cookies, secure headers
- **Database agnostic** - Works with Prisma, Drizzle, TypeORM, or any database
- **TypeScript support** - Fully typed with excellent IntelliSense
- **Serverless ready** - Works on Vercel, AWS Lambda, and other serverless platforms

```typescript
// Simple setup
import NextAuth from 'next-auth'
import GoogleProvider from 'next-auth/providers/google'

export const { handlers, auth } = NextAuth({
  providers: [
    GoogleProvider({
      clientId: process.env.GOOGLE_CLIENT_ID,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET,
    }),
  ],
})

// Use in Server Components
const session = await auth()
if (session?.user) {
  console.log('Signed in as', session.user.email)
}
```

## Why NextAuth.js?

### Comparison with Other Authentication Solutions

| Feature | NextAuth | Auth0 | Firebase Auth | Clerk | Supabase Auth |
|---------|----------|-------|---------------|-------|---------------|
| **Self-hosted** | ✅ Yes | ❌ No | ❌ No | ❌ No | ⚠️ Optional |
| **Cost** | 🟢 Free | 🔴 Paid ($23+/mo) | 🟡 Free tier limited | 🔴 Paid ($25+/mo) | 🟡 Free tier limited |
| **OAuth providers** | ✅ 50+ built-in | ✅ Many | ✅ Many | ✅ Many | ✅ Many |
| **Database flexibility** | ✅ Any DB | ❌ Managed only | ❌ Firebase only | ❌ Managed only | ❌ Postgres only |
| **JWT sessions** | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |
| **Database sessions** | ✅ Yes | ✅ Yes | ❌ No | ✅ Yes | ✅ Yes |
| **TypeScript** | ✅ Excellent | ✅ Good | ⚠️ Basic | ✅ Excellent | ✅ Good |
| **Next.js integration** | ✅ Native | ⚠️ Good | ⚠️ Basic | ✅ Excellent | ⚠️ Good |
| **Open source** | ✅ Yes | ❌ No | ❌ No | ❌ No | ✅ Yes |
| **Data ownership** | ✅ Full | ❌ Limited | ❌ Limited | ❌ Limited | ⚠️ Depends |
| **Customizable** | ✅ Highly | ⚠️ Limited | ⚠️ Limited | ⚠️ Limited | ✅ Highly |
| **Learning curve** | 🟡 Medium | 🟢 Low | 🟢 Low | 🟢 Low | 🟡 Medium |

**NextAuth excels at:**
- Full control over authentication logic and data
- Zero recurring costs for authentication
- Database flexibility (any ORM, any database)
- Deep Next.js integration (App Router, Server Components, Server Actions)
- Open-source transparency and community support

**Consider alternatives when:**
- **Auth0/Clerk**: Need managed UI components and minimal setup (pay for convenience)
- **Firebase Auth**: Already using Firebase ecosystem
- **Supabase Auth**: Need integrated auth + database + real-time features
- **Custom solution**: Very simple requirements or extreme customization needs

## Documentation Structure

### Core Files

- **[INDEX.md](./INDEX.md)** - Complete index with topic navigation and problem-based quick find
- **[QUICK-REFERENCE.md](./QUICK-REFERENCE.md)** - One-page cheat sheet with all patterns
- **[FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md)** - Prisma, Drizzle, tRPC, React Query integrations

### Core Topics (11 Files)

| # | File | Topic | What You'll Learn |
|---|------|-------|-------------------|
| 01 | [01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md) | Core concepts and setup | Installation, basic auth, session access |
| 02 | [02-PROVIDERS.md](./02-PROVIDERS.md) | Authentication providers | OAuth, Credentials, Email providers |
| 03 | [03-SESSIONS.md](./03-SESSIONS.md) | Session management | JWT vs Database sessions, session access |
| 04 | [04-JWT-VS-DATABASE.md](./04-JWT-VS-DATABASE.md) | Session strategies | Performance comparison, when to use each |
| 05 | [05-CALLBACKS.md](./05-CALLBACKS.md) | Lifecycle callbacks | signIn, jwt, session, redirect callbacks |
| 06 | [06-MIDDLEWARE.md](./06-MIDDLEWARE.md) | Route protection | Middleware patterns, role-based access |
| 07 | [07-PROTECTED-ROUTES.md](./07-PROTECTED-ROUTES.md) | Protected routes | Server Components, API routes, Server Actions |
| 08 | [08-ADVANCED-AUTH.md](./08-ADVANCED-AUTH.md) | Advanced patterns | 2FA, magic links, account linking, SAML |
| 09 | [09-SECURITY.md](./09-SECURITY.md) | Security best practices | CSRF, rate limiting, brute force protection |
| 10 | [10-INTEGRATIONS.md](./10-INTEGRATIONS.md) | Framework integration | Next.js, Prisma, Drizzle, tRPC, React Query |
| 11 | [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) | Production patterns | Environment config, monitoring, troubleshooting |

## Learning Paths

### 🟢 Beginner Path (Start Here)

**Goal**: Set up basic authentication with OAuth providers

1. **[01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md)** - Core concepts (30 min)
   - Installation and setup
   - Basic configuration
   - Session access patterns

2. **[02-PROVIDERS.md](./02-PROVIDERS.md)** - Authentication providers (30 min)
   - Google OAuth setup
   - GitHub OAuth setup
   - Email magic links

3. **[03-SESSIONS.md](./03-SESSIONS.md)** - Session basics (20 min)
   - JWT vs Database sessions
   - Accessing sessions in Server Components
   - Client-side session access

4. **[06-MIDDLEWARE.md](./06-MIDDLEWARE.md)** - Basic protection (20 min)
   - Protecting routes with middleware
   - Public vs protected routes
   - Redirect patterns

**Beginner Projects**:
- OAuth sign-in (Google + GitHub)
- Protected dashboard with session display
- Sign-out functionality

### 🟡 Intermediate Path

**Goal**: Build production-ready authentication with database integration

**Prerequisites**: Complete Beginner Path

1. **[04-JWT-VS-DATABASE.md](./04-JWT-VS-DATABASE.md)** - Session strategies (30 min)
   - Performance comparison
   - When to use JWT vs Database
   - Migration strategies

2. **[05-CALLBACKS.md](./05-CALLBACKS.md)** - Customization (45 min)
   - signIn callback for authorization
   - jwt callback for custom claims
   - session callback for client data
   - redirect callback for post-login flow

3. **[10-INTEGRATIONS.md](./10-INTEGRATIONS.md)** - Database integration (60 min)
   - Prisma adapter setup
   - Schema configuration
   - Extended user models
   - tRPC integration

4. **[07-PROTECTED-ROUTES.md](./07-PROTECTED-ROUTES.md)** - Multi-layer protection (30 min)
   - Server Component protection
   - API route protection
   - Server Actions protection
   - Role-based access control

**Intermediate Projects**:
- Full-stack auth with Prisma
- Role-based admin dashboard
- User profile management
- tRPC with authenticated procedures

### 🔴 Advanced Path

**Goal**: Enterprise-grade authentication with security hardening

**Prerequisites**: Complete Intermediate Path

1. **[08-ADVANCED-AUTH.md](./08-ADVANCED-AUTH.md)** - Advanced patterns (60 min)
   - Two-factor authentication (TOTP, SMS)
   - Magic links implementation
   - Account linking (multiple providers)
   - Custom OAuth flows
   - SAML/SSO integration

2. **[09-SECURITY.md](./09-SECURITY.md)** - Security hardening (45 min)
   - CSRF protection
   - Rate limiting
   - Brute force prevention
   - Session security
   - Security monitoring

3. **[11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md)** - Production operations (45 min)
   - Environment configuration
   - Monitoring and logging
   - Troubleshooting
   - Database migrations
   - Disaster recovery

**Advanced Projects**:
- Multi-tenant authentication
- 2FA with backup codes
- Security monitoring dashboard
- Custom OAuth provider
- Zero-downtime auth migrations

## Quick Start

### Installation

```bash
npm install next-auth@beta
# or
yarn add next-auth@beta
# or
pnpm add next-auth@beta
```

### Basic Setup (App Router)

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
  pages: {
    signIn: '/login',
  },
})

export { handlers as GET, handlers as POST }
```

### Environment Variables

```bash
# .env.local
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=your-secret-key-generate-with-openssl-rand-base64-32

# OAuth Providers
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret
```

### Sign-In Page

```typescript
// app/login/page.tsx
import { signIn } from '@/app/api/auth/[...nextauth]/route'

export default function LoginPage() {
  return (
    <div>
      <h1>Sign In</h1>
      <form
        action={async () => {
          'use server'
          await signIn('google', { redirectTo: '/dashboard' })
        }}
      >
        <button type="submit">Sign in with Google</button>
      </form>
    </div>
  )
}
```

### Protected Page

```typescript
// app/dashboard/page.tsx
import { auth } from '@/app/api/auth/[...nextauth]/route'
import { redirect } from 'next/navigation'

export default async function DashboardPage() {
  const session = await auth()

  if (!session?.user) {
    redirect('/login')
  }

  return (
    <div>
      <h1>Welcome, {session.user.name}</h1>
      <p>Email: {session.user.email}</p>
    </div>
  )
}
```

## Key Features

### 1. Multiple Authentication Providers

```typescript
import GoogleProvider from 'next-auth/providers/google'
import GitHubProvider from 'next-auth/providers/github'
import CredentialsProvider from 'next-auth/providers/credentials'

export const { handlers, auth } = NextAuth({
  providers: [
    GoogleProvider({ /* ... */ }),
    GitHubProvider({ /* ... */ }),
    CredentialsProvider({
      credentials: {
        email: { type: 'email' },
        password: { type: 'password' },
      },
      async authorize(credentials) {
        const user = await verifyCredentials(credentials)
        return user || null
      },
    }),
  ],
})
```

### 2. Flexible Session Management

```typescript
// JWT Sessions (stateless, fast)
export const authOptions = {
  session: { strategy: 'jwt' },
}

// Database Sessions (immediate invalidation)
import { PrismaAdapter } from '@auth/prisma-adapter'

export const authOptions = {
  adapter: PrismaAdapter(prisma),
  session: { strategy: 'database' },
}
```

### 3. Role-Based Access Control

```typescript
// Add roles to session
callbacks: {
  async jwt({ token, user }) {
    if (user) token.role = user.role
    return token
  },
  async session({ session, token }) {
    session.user.role = token.role
    return session
  },
}

// Protect routes by role
export default withAuth(
  function middleware(req) {
    if (req.nextauth.token?.role !== 'admin') {
      return NextResponse.redirect('/unauthorized')
    }
  },
  { callbacks: { authorized: ({ token }) => !!token } }
)
```

### 4. Database Integration

```typescript
// Works with any database via adapters
import { PrismaAdapter } from '@auth/prisma-adapter'
import { DrizzleAdapter } from '@auth/drizzle-adapter'
import { TypeORMAdapter } from '@auth/typeorm-adapter'

export const authOptions = {
  adapter: PrismaAdapter(prisma),
  // or
  adapter: DrizzleAdapter(db),
  // or
  adapter: TypeORMAdapter(connection),
}
```

## Use Cases

### ✅ Ideal For

- **Next.js applications**: Native integration with App Router and Server Components
- **Self-hosted applications**: Full control over auth logic and user data
- **Multi-provider auth**: Support Google, GitHub, Facebook, and 50+ providers
- **Cost-sensitive projects**: No recurring auth service fees
- **Database flexibility**: Works with any database via adapters
- **Custom auth flows**: Highly customizable callbacks and events
- **Open-source projects**: Transparent, auditable authentication

### ⚠️ Consider Alternatives When

- **Need managed UI**: Auth0/Clerk provide ready-made UI components
- **Minimal setup time**: Managed services are faster to set up initially
- **Non-Next.js projects**: NextAuth is optimized for Next.js
- **Compliance requirements**: Managed services handle compliance certifications
- **Very simple needs**: Plain JWT library might suffice

## Common Patterns

### OAuth Sign-In

```typescript
// app/api/auth/[...nextauth]/route.ts
import GoogleProvider from 'next-auth/providers/google'
import GitHubProvider from 'next-auth/providers/github'

export const { handlers, auth } = NextAuth({
  providers: [
    GoogleProvider({
      clientId: process.env.GOOGLE_CLIENT_ID!,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
    }),
    GitHubProvider({
      clientId: process.env.GITHUB_CLIENT_ID!,
      clientSecret: process.env.GITHUB_CLIENT_SECRET!,
    }),
  ],
})
```

### Protected API Route

```typescript
// app/api/profile/route.ts
import { auth } from '@/app/api/auth/[...nextauth]/route'
import { NextResponse } from 'next/server'

export async function GET() {
  const session = await auth()

  if (!session?.user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  const user = await db.user.findUnique({
    where: { id: session.user.id },
  })

  return NextResponse.json({ user })
}
```

### Custom Sign-In Page

```typescript
// app/login/page.tsx
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
        placeholder="Email"
      />
      <input
        type="password"
        value={password}
        onChange={(e) => setPassword(e.target.value)}
        placeholder="Password"
      />
      <button type="submit">Sign In</button>

      <hr />

      <button type="button" onClick={() => signIn('google')}>
        Sign in with Google
      </button>
      <button type="button" onClick={() => signIn('github')}>
        Sign in with GitHub
      </button>
    </form>
  )
}
```

## Resources

### Official Documentation
- [NextAuth.js Official Docs](https://next-auth.js.org/)
- [GitHub Repository](https://github.com/nextauthjs/next-auth)
- [Migration Guide (v4 to v5)](https://authjs.dev/getting-started/migrating-to-v5)

### Provider Setup Guides
- [Google OAuth Setup](https://next-auth.js.org/providers/google)
- [GitHub OAuth Setup](https://next-auth.js.org/providers/github)
- [All Providers](https://next-auth.js.org/providers/)

### Database Adapters
- [Prisma Adapter](https://authjs.dev/reference/adapter/prisma)
- [Drizzle Adapter](https://authjs.dev/reference/adapter/drizzle)
- [All Adapters](https://authjs.dev/reference/adapters)

### Community
- [GitHub Discussions](https://github.com/nextauthjs/next-auth/discussions)
- [Discord Server](https://discord.gg/nextauth)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/next-auth)

### Related Libraries
- [@auth/prisma-adapter](https://www.npmjs.com/package/@auth/prisma-adapter) - Prisma database adapter
- [@auth/drizzle-adapter](https://www.npmjs.com/package/@auth/drizzle-adapter) - Drizzle ORM adapter
- [next-auth-sanity](https://github.com/jamesryan094/next-auth-sanity) - Sanity.io adapter

## Migration Guides

### From Auth0

```typescript
// Auth0
import { Auth0Provider } from '@auth0/nextjs-auth0'

// NextAuth
import GoogleProvider from 'next-auth/providers/google'

export const { handlers, auth } = NextAuth({
  providers: [
    GoogleProvider({
      clientId: process.env.GOOGLE_CLIENT_ID!,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
    }),
  ],
})
```

### From Firebase Auth

```typescript
// Firebase Auth
import { getAuth, signInWithPopup, GoogleAuthProvider } from 'firebase/auth'

// NextAuth
import { signIn } from 'next-auth/react'

// Sign in
await signIn('google', { callbackUrl: '/dashboard' })
```

---

## AI Pair Programming Notes

**When to load this KB:**
- Implementing authentication in Next.js applications
- Need OAuth provider integration
- Building protected routes and API endpoints
- Migrating from other auth solutions
- Need session management patterns

**Common starting points:**
- Beginners: Start with [01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md)
- OAuth setup: See [02-PROVIDERS.md](./02-PROVIDERS.md)
- Database integration: See [10-INTEGRATIONS.md](./10-INTEGRATIONS.md)
- Security hardening: See [09-SECURITY.md](./09-SECURITY.md)

**Typical questions:**
- "How do I add Google sign-in?" → [02-PROVIDERS.md](./02-PROVIDERS.md)
- "How do I protect routes?" → [06-MIDDLEWARE.md](./06-MIDDLEWARE.md) + [07-PROTECTED-ROUTES.md](./07-PROTECTED-ROUTES.md)
- "Should I use JWT or database sessions?" → [04-JWT-VS-DATABASE.md](./04-JWT-VS-DATABASE.md)
- "How do I add custom user fields?" → [05-CALLBACKS.md](./05-CALLBACKS.md) + [10-INTEGRATIONS.md](./10-INTEGRATIONS.md)

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1
