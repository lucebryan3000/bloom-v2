---
id: nextauth-05-callbacks
topic: nextauth
file_role: practical
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [nextauth-fundamentals, nextauth-sessions]
related_topics: [callbacks, authentication-flow, authorization]
embedding_keywords: [nextauth, callbacks, signIn, jwt, session, redirect]
last_reviewed: 2025-11-16
---

# NextAuth.js - Callbacks

## Purpose

Master NextAuth.js callbacks to customize authentication flows, enhance sessions, control access, and implement advanced patterns.

## Table of Contents

1. [Callback Overview](#callback-overview)
2. [Core Callbacks](#core-callbacks)
3. [Session Callbacks](#session-callbacks)
4. [Redirect Callbacks](#redirect-callbacks)
5. [Advanced Patterns](#advanced-patterns)
6. [Error Handling](#error-handling)

---

## Callback Overview

### What are Callbacks?

Callbacks are asynchronous functions you can use to control what happens during the authentication flow.

```typescript
export const authOptions = {
  providers: [/* ... */],
  callbacks: {
    async signIn({ user, account, profile, email, credentials }) {
      // Control whether user can sign in
      return true
    },
    async jwt({ token, user, account, profile, trigger, session }) {
      // Modify JWT token
      return token
    },
    async session({ session, token, user }) {
      // Modify session object
      return session
    },
    async redirect({ url, baseUrl }) {
      // Control where user is redirected
      return baseUrl
    },
  },
}
```

### Callback Execution Order

```
1. signIn() - Authorize sign in attempt
   â†"
2. jwt() - Create/update JWT token
   â†"
3. session() - Create session object sent to client
   â†"
4. redirect() - Determine where to redirect user
```

---

## Core Callbacks

### signIn Callback

Controls whether a user is allowed to sign in.

```typescript
callbacks: {
  async signIn({ user, account, profile, email, credentials }) {
    // Allow all sign ins
    return true

    // Block sign in
    return false

    // Redirect to custom page
    return '/unauthorized'
  }
}
```

**Use Cases:**

**1. Email Domain Allowlist**
```typescript
async signIn({ user, account, profile }) {
  const allowedDomains = ['company.com', 'partner.com']

  if (user.email) {
    const domain = user.email.split('@')[1]
    return allowedDomains.includes(domain)
  }

  return false
}
```

**2. Account Verification**
```typescript
async signIn({ user, account }) {
  if (account?.provider === 'google') {
    // Check if user exists in database
    const dbUser = await db.user.findUnique({
      where: { email: user.email },
    })

    // Only allow if user exists and is active
    return dbUser?.isActive ?? false
  }

  return true
}
```

**3. OAuth Provider Restrictions**
```typescript
async signIn({ user, account }) {
  // Only allow GitHub OAuth in production
  if (account?.provider === 'github') {
    if (process.env.NODE_ENV !== 'production') {
      return '/auth/error?error=ProviderNotAllowed'
    }
  }

  return true
}
```

**4. Rate Limiting**
```typescript
import { Ratelimit } from '@upstash/ratelimit'
import { Redis } from '@upstash/redis'

const ratelimit = new Ratelimit({
  redis: Redis.fromEnv(),
  limiter: Ratelimit.slidingWindow(5, '15 m'), // 5 attempts per 15 minutes
})

async signIn({ user }) {
  const { success } = await ratelimit.limit(user.email)

  if (!success) {
    return '/auth/error?error=RateLimited'
  }

  return true
}
```

---

## Session Callbacks

### jwt Callback

Modifies the JWT token (runs before session callback).

```typescript
callbacks: {
  async jwt({ token, user, account, profile, trigger, session }) {
    // Initial sign in
    if (user) {
      token.id = user.id
      token.role = user.role
    }

    // Update session data
    if (trigger === 'update' && session) {
      token.name = session.name
    }

    return token
  }
}
```

**Parameters:**
- `token` - JWT token object (persisted between requests)
- `user` - User object (only available on initial sign in)
- `account` - OAuth account (only on initial sign in)
- `profile` - OAuth profile (only on initial sign in)
- `trigger` - 'signIn' | 'signUp' | 'update'
- `session` - Session data from update() call

**Use Cases:**

**1. Add Custom Fields**
```typescript
declare module 'next-auth/jwt' {
  interface JWT {
    id: string
    role: string
    department: string
    permissions: string[]
  }
}

async jwt({ token, user }) {
  if (user) {
    token.id = user.id
    token.role = user.role
    token.department = user.department
    token.permissions = user.permissions
  }

  return token
}
```

**2. Fetch Additional Data**
```typescript
async jwt({ token, user }) {
  if (user) {
    // Fetch additional user data
    const userData = await db.user.findUnique({
      where: { id: user.id },
      include: {
        organization: true,
        permissions: true,
      },
    })

    token.id = user.id
    token.organizationId = userData?.organization?.id
    token.permissions = userData?.permissions.map(p => p.name)
  }

  return token
}
```

**3. Handle Token Refresh**
```typescript
async jwt({ token, account }) {
  // Initial sign in
  if (account) {
    return {
      ...token,
      accessToken: account.access_token,
      accessTokenExpires: account.expires_at! * 1000,
      refreshToken: account.refresh_token,
    }
  }

  // Token not expired yet
  if (Date.now() < (token.accessTokenExpires as number)) {
    return token
  }

  // Token expired, refresh it
  return refreshAccessToken(token)
}

async function refreshAccessToken(token: JWT) {
  try {
    const response = await fetch('https://oauth.provider.com/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        client_id: process.env.CLIENT_ID!,
        client_secret: process.env.CLIENT_SECRET!,
        grant_type: 'refresh_token',
        refresh_token: token.refreshToken as string,
      }),
    })

    const tokens = await response.json()

    if (!response.ok) throw tokens

    return {
      ...token,
      accessToken: tokens.access_token,
      accessTokenExpires: Date.now() + tokens.expires_in * 1000,
      refreshToken: tokens.refresh_token ?? token.refreshToken,
    }
  } catch (error) {
    return {
      ...token,
      error: 'RefreshAccessTokenError' as const,
    }
  }
}
```

### session Callback

Modifies the session object sent to the client.

```typescript
callbacks: {
  async session({ session, token, user }) {
    // Add custom fields to session
    if (session.user) {
      session.user.id = token.id as string
      session.user.role = token.role as string
    }

    return session
  }
}
```

**Use Cases:**

**1. Add Custom Fields to Session**
```typescript
declare module 'next-auth' {
  interface Session {
    user: {
      id: string
      email: string
      name: string
      role: string
      organizationId: string
    }
  }
}

async session({ session, token }) {
  if (session.user) {
    session.user.id = token.id as string
    session.user.role = token.role as string
    session.user.organizationId = token.organizationId as string
  }

  return session
}
```

**2. Filter Sensitive Data**
```typescript
async session({ session, token }) {
  // Don't expose sensitive fields to client
  const { password, ...safeUser } = token

  session.user = {
    ...session.user,
    ...safeUser,
  }

  return session
}
```

**3. Real-Time User Data**
```typescript
async session({ session, token }) {
  // Fetch fresh user data on every request (database sessions only)
  const user = await db.user.findUnique({
    where: { id: token.id as string },
    select: {
      id: true,
      email: true,
      name: true,
      role: true,
      isActive: true,
    },
  })

  if (!user || !user.isActive) {
    // User deactivated, invalidate session
    throw new Error('User inactive')
  }

  session.user = user

  return session
}
```

---

## Redirect Callbacks

### redirect Callback

Controls where users are redirected after sign in/sign out.

```typescript
callbacks: {
  async redirect({ url, baseUrl }) {
    // Allows relative callback URLs
    if (url.startsWith('/')) return `${baseUrl}${url}`

    // Allows callback URLs on the same origin
    if (new URL(url).origin === baseUrl) return url

    return baseUrl
  }
}
```

**Use Cases:**

**1. Role-Based Redirects**
```typescript
async redirect({ url, baseUrl }) {
  // Get session to check role
  const session = await getServerSession(authOptions)

  if (session?.user?.role === 'admin') {
    return `${baseUrl}/admin/dashboard`
  }

  if (session?.user?.role === 'user') {
    return `${baseUrl}/dashboard`
  }

  return baseUrl
}
```

**2. Preserve Query Parameters**
```typescript
async redirect({ url, baseUrl }) {
  const urlObj = new URL(url, baseUrl)

  // Preserve 'callbackUrl' query parameter
  const callbackUrl = urlObj.searchParams.get('callbackUrl')

  if (callbackUrl && callbackUrl.startsWith('/')) {
    return `${baseUrl}${callbackUrl}`
  }

  return baseUrl
}
```

**3. External URL Allowlist**
```typescript
const allowedOrigins = [
  'https://app.example.com',
  'https://admin.example.com',
]

async redirect({ url, baseUrl }) {
  const urlObj = new URL(url, baseUrl)

  if (allowedOrigins.includes(urlObj.origin)) {
    return url
  }

  return baseUrl
}
```

---

## Advanced Patterns

### Conditional Callbacks

```typescript
callbacks: {
  async signIn({ user, account }) {
    // Different logic per provider
    switch (account?.provider) {
      case 'google':
        return user.email?.endsWith('@company.com') ?? false

      case 'github':
        // Allow all GitHub users
        return true

      case 'credentials':
        // Check 2FA
        const user2FA = await db.user.findUnique({
          where: { id: user.id },
          select: { twoFactorEnabled: true, twoFactorVerified: true },
        })

        if (user2FA?.twoFactorEnabled && !user2FA?.twoFactorVerified) {
          return '/auth/verify-2fa'
        }

        return true

      default:
        return false
    }
  }
}
```

### Audit Logging

```typescript
callbacks: {
  async signIn({ user, account }) {
    // Log all sign-in attempts
    await db.auditLog.create({
      data: {
        event: 'SIGN_IN_ATTEMPT',
        userId: user.id,
        provider: account?.provider,
        timestamp: new Date(),
        metadata: {
          email: user.email,
          ip: request.headers.get('x-forwarded-for'),
        },
      },
    })

    return true
  },

  async jwt({ token, trigger }) {
    if (trigger === 'update') {
      // Log session updates
      await db.auditLog.create({
        data: {
          event: 'SESSION_UPDATE',
          userId: token.id as string,
          timestamp: new Date(),
        },
      })
    }

    return token
  }
}
```

### Feature Flags

```typescript
callbacks: {
  async session({ session, token }) {
    // Load user-specific feature flags
    const featureFlags = await db.featureFlag.findMany({
      where: {
        OR: [
          { userId: token.id as string },
          { global: true },
        ],
      },
    })

    session.features = featureFlags.reduce((acc, flag) => {
      acc[flag.name] = flag.enabled
      return acc
    }, {} as Record<string, boolean>)

    return session
  }
}
```

### Analytics Integration

```typescript
import { Analytics } from '@segment/analytics-node'

const analytics = new Analytics({ writeKey: process.env.SEGMENT_WRITE_KEY! })

callbacks: {
  async signIn({ user, account }) {
    // Track sign-in event
    analytics.track({
      userId: user.id,
      event: 'User Signed In',
      properties: {
        provider: account?.provider,
        email: user.email,
      },
    })

    return true
  },

  async jwt({ token, user, trigger }) {
    if (trigger === 'signIn') {
      // Identify user
      analytics.identify({
        userId: token.id as string,
        traits: {
          email: user.email,
          name: user.name,
          role: user.role,
        },
      })
    }

    return token
  }
}
```

---

## Error Handling

### Callback Errors

```typescript
callbacks: {
  async signIn({ user }) {
    try {
      // Validate user
      const dbUser = await db.user.findUnique({
        where: { email: user.email },
      })

      if (!dbUser) {
        throw new Error('User not found')
      }

      if (!dbUser.isActive) {
        throw new Error('User is inactive')
      }

      return true
    } catch (error) {
      console.error('Sign in error:', error)

      // Redirect to error page with message
      return `/auth/error?error=${encodeURIComponent(error.message)}`
    }
  },

  async jwt({ token }) {
    try {
      // Refresh token logic
      return token
    } catch (error) {
      console.error('JWT error:', error)

      // Return error in token
      return {
        ...token,
        error: 'TokenError',
      }
    }
  },

  async session({ session, token }) {
    // Check for token errors
    if (token.error) {
      throw new Error('Failed to create session')
    }

    return session
  }
}
```

### Error Pages

```typescript
pages: {
  signIn: '/auth/signin',
  signOut: '/auth/signout',
  error: '/auth/error', // Error code passed in query string as ?error=
  verifyRequest: '/auth/verify-request',
}

// app/auth/error/page.tsx
export default function AuthErrorPage({
  searchParams,
}: {
  searchParams: { error?: string }
}) {
  const errorMessages = {
    Configuration: 'There is a problem with the server configuration.',
    AccessDenied: 'You do not have permission to sign in.',
    Verification: 'The verification token has expired or has already been used.',
    RateLimited: 'Too many sign-in attempts. Please try again later.',
  }

  const error = searchParams.error as keyof typeof errorMessages
  const message = errorMessages[error] || 'An error occurred during authentication.'

  return (
    <div>
      <h1>Authentication Error</h1>
      <p>{message}</p>
      <Link href="/auth/signin">Try again</Link>
    </div>
  )
}
```

---

## Best Practices

### 1. Keep Callbacks Simple

```typescript
// ✅ Good - Simple and focused
async signIn({ user }) {
  return user.email?.endsWith('@company.com') ?? false
}

// ❌ Bad - Too much logic
async signIn({ user }) {
  const userData = await db.user.findUnique({ where: { email: user.email } })
  const permissions = await db.permission.findMany({ where: { userId: userData.id } })
  const featureFlags = await db.featureFlag.findMany({ where: { userId: userData.id } })
  // ... too much!
}
```

### 2. Handle Errors Gracefully

```typescript
// ✅ Good - Error handling
async jwt({ token, user }) {
  try {
    if (user) {
      const userData = await db.user.findUnique({ where: { id: user.id } })
      token.role = userData?.role
    }
    return token
  } catch (error) {
    console.error('JWT callback error:', error)
    return token // Return token even if enrichment fails
  }
}
```

### 3. Type Your Callbacks

```typescript
// ✅ Good - Proper typing
import { JWT } from 'next-auth/jwt'
import { Session, User, Account, Profile } from 'next-auth'

async jwt({
  token,
  user,
  account,
}: {
  token: JWT
  user?: User
  account?: Account | null
}): Promise<JWT> {
  if (user) {
    token.id = user.id
  }
  return token
}
```

---

## AI Pair Programming Notes

**When to load this file:**
- Customizing authentication flow
- Adding custom fields to sessions
- Implementing access control
- Integrating analytics or logging

**Typical questions:**
- "How do I add custom data to session?" → See Session Callbacks → jwt & session
- "How do I restrict sign-ins?" → See Core Callbacks → signIn Callback
- "How do I redirect based on role?" → See Redirect Callbacks
- "How do I handle errors in callbacks?" → See Error Handling

**Next steps:**
- [06-MIDDLEWARE.md](./06-MIDDLEWARE.md) - Route protection
- [07-PROTECTED-ROUTES.md](./07-PROTECTED-ROUTES.md) - Access control
- [09-SECURITY.md](./09-SECURITY.md) - Security patterns

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1
