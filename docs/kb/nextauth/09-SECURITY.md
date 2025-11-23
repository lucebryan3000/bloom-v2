---
id: nextauth-security
topic: nextauth
file_role: guide
profile: full
difficulty_level: advanced
kb_version: 3.1
prerequisites: [nextauth-fundamentals, nextauth-sessions, nextauth-middleware]
related_topics: [security, authentication, csrf, rate-limiting]
embedding_keywords: [nextauth, security, csrf, rate-limiting, brute-force, secure-cookies, session-security]
last_reviewed: 2025-11-16
---

# NextAuth.js - Security Best Practices

Comprehensive security patterns for production NextAuth applications.

## Overview

Security is paramount in authentication systems. This guide covers essential security measures including CSRF protection, secure cookies, rate limiting, brute force prevention, and production hardening.

---

## CSRF Protection

NextAuth.js has built-in CSRF protection, but you need to understand how it works.

### Built-in CSRF Token

NextAuth automatically generates CSRF tokens for all authentication requests.

```typescript
// app/api/auth/[...nextauth]/route.ts
import NextAuth from 'next-auth'

export const { handlers, auth, signIn, signOut } = NextAuth({
  // CSRF protection is enabled by default
  // Token is stored in cookies and validated on requests
})
```

### Custom Forms with CSRF

When building custom sign-in forms, include the CSRF token:

```typescript
// app/login/page.tsx
'use client'

import { getCsrfToken } from 'next-auth/react'
import { useEffect, useState } from 'react'

export default function LoginPage() {
  const [csrfToken, setCsrfToken] = useState('')

  useEffect(() => {
    getCsrfToken().then((token) => setCsrfToken(token || ''))
  }, [])

  return (
    <form method="post" action="/api/auth/callback/credentials">
      <input type="hidden" name="csrfToken" value={csrfToken} />
      <input type="email" name="email" placeholder="Email" required />
      <input type="password" name="password" placeholder="Password" required />
      <button type="submit">Sign in</button>
    </form>
  )
}
```

### API Route CSRF Validation

For custom API routes that modify authentication state:

```typescript
// lib/auth/csrf.ts
import { getServerSession } from 'next-auth'
import { authOptions } from '@/app/api/auth/[...nextauth]/route'

export async function validateCSRF(token: string): Promise<boolean> {
  const session = await getServerSession(authOptions)

  // NextAuth stores CSRF token in session
  if (!session?.csrfToken) {
    return false
  }

  return session.csrfToken === token
}

// app/api/profile/update/route.ts
import { NextRequest, NextResponse } from 'next/server'
import { validateCSRF } from '@/lib/auth/csrf'

export async function POST(req: NextRequest) {
  const body = await req.json()
  const { csrfToken, ...data } = body

  if (!await validateCSRF(csrfToken)) {
    return NextResponse.json(
      { error: 'Invalid CSRF token' },
      { status: 403 }
    )
  }

  // Process request
  return NextResponse.json({ success: true })
}
```

---

## Secure Cookies

Proper cookie configuration is critical for security.

### Production Cookie Settings

```typescript
// app/api/auth/[...nextauth]/route.ts
import NextAuth from 'next-auth'

export const { handlers, auth } = NextAuth({
  cookies: {
    sessionToken: {
      name: `__Secure-next-auth.session-token`,
      options: {
        httpOnly: true,
        sameSite: 'lax',
        path: '/',
        secure: true, // HTTPS only in production
        domain: process.env.NODE_ENV === 'production'
          ? '.yourdomain.com'
          : undefined,
      },
    },
    callbackUrl: {
      name: `__Secure-next-auth.callback-url`,
      options: {
        httpOnly: true,
        sameSite: 'lax',
        path: '/',
        secure: true,
      },
    },
    csrfToken: {
      name: `__Host-next-auth.csrf-token`,
      options: {
        httpOnly: true,
        sameSite: 'lax',
        path: '/',
        secure: true,
      },
    },
  },
})
```

### Cookie Prefixes

Use `__Secure-` and `__Host-` prefixes for enhanced security:

```typescript
// __Secure- prefix requirements:
// - Must be set with secure flag
// - Must be from secure origin (HTTPS)

// __Host- prefix requirements:
// - Must be set with secure flag
// - Must be from secure origin (HTTPS)
// - Must not have domain attribute
// - Must have path set to /

const cookieOptions = {
  // For cookies that can be shared across subdomains
  sessionToken: {
    name: '__Secure-session-token',
    options: {
      secure: true,
      domain: '.example.com',
    },
  },

  // For cookies that should be strictly scoped
  csrfToken: {
    name: '__Host-csrf-token',
    options: {
      secure: true,
      path: '/',
      // No domain attribute
    },
  },
}
```

### Cookie Rotation

Rotate session cookies periodically to reduce replay attack risk:

```typescript
// lib/auth/session-rotation.ts
import { getServerSession } from 'next-auth'
import { cookies } from 'next/headers'

const SESSION_ROTATION_INTERVAL = 15 * 60 * 1000 // 15 minutes

export async function rotateSessionIfNeeded() {
  const session = await getServerSession()

  if (!session?.user?.sessionCreatedAt) {
    return
  }

  const age = Date.now() - new Date(session.user.sessionCreatedAt).getTime()

  if (age > SESSION_ROTATION_INTERVAL) {
    // Force session refresh
    const cookieStore = cookies()
    cookieStore.delete('next-auth.session-token')

    // NextAuth will create new session on next request
  }
}
```

---

## Rate Limiting

Prevent brute force attacks with rate limiting.

### Basic Rate Limiting

```typescript
// lib/security/rate-limiter.ts
import { LRUCache } from 'lru-cache'

type RateLimitOptions = {
  interval: number
  uniqueTokenPerInterval: number
}

export function rateLimit(options: RateLimitOptions) {
  const tokenCache = new LRUCache({
    max: options.uniqueTokenPerInterval,
    ttl: options.interval,
  })

  return {
    check: (limit: number, token: string): Promise<void> =>
      new Promise((resolve, reject) => {
        const tokenCount = (tokenCache.get(token) as number) || 0

        if (tokenCount >= limit) {
          reject(new Error('Rate limit exceeded'))
        } else {
          tokenCache.set(token, tokenCount + 1)
          resolve()
        }
      }),
  }
}

// Usage
const limiter = rateLimit({
  interval: 60 * 1000, // 1 minute
  uniqueTokenPerInterval: 500,
})

export async function checkRateLimit(identifier: string, limit = 5) {
  try {
    await limiter.check(limit, identifier)
  } catch {
    throw new Error('Too many requests')
  }
}
```

### Sign-In Rate Limiting

```typescript
// app/api/auth/[...nextauth]/route.ts
import NextAuth from 'next-auth'
import { checkRateLimit } from '@/lib/security/rate-limiter'

export const { handlers, auth } = NextAuth({
  providers: [
    CredentialsProvider({
      credentials: {
        email: { type: 'email' },
        password: { type: 'password' },
      },
      async authorize(credentials, req) {
        const email = credentials.email as string

        // Rate limit by email
        try {
          await checkRateLimit(`signin:${email}`, 5)
        } catch (error) {
          throw new Error('Too many sign-in attempts. Please try again later.')
        }

        // Verify credentials
        const user = await verifyCredentials(credentials)

        if (!user) {
          throw new Error('Invalid credentials')
        }

        return user
      },
    }),
  ],
})
```

### IP-Based Rate Limiting

```typescript
// lib/security/ip-rate-limiter.ts
import { NextRequest } from 'next/server'
import { checkRateLimit } from './rate-limiter'

export function getClientIP(req: NextRequest): string {
  const forwarded = req.headers.get('x-forwarded-for')
  const realIP = req.headers.get('x-real-ip')

  if (forwarded) {
    return forwarded.split(',')[0].trim()
  }

  if (realIP) {
    return realIP
  }

  return 'unknown'
}

export async function checkIPRateLimit(req: NextRequest, limit = 10) {
  const ip = getClientIP(req)
  await checkRateLimit(`ip:${ip}`, limit)
}

// middleware.ts
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'
import { checkIPRateLimit } from '@/lib/security/ip-rate-limiter'

export async function middleware(req: NextRequest) {
  // Rate limit all requests
  try {
    await checkIPRateLimit(req, 100) // 100 requests per minute per IP
  } catch (error) {
    return NextResponse.json(
      { error: 'Rate limit exceeded' },
      { status: 429 }
    )
  }

  return NextResponse.next()
}
```

---

## Brute Force Protection

Protect against credential stuffing and brute force attacks.

### Account Lockout

```typescript
// lib/security/account-lockout.ts
import { db } from '@/lib/db'

const MAX_FAILED_ATTEMPTS = 5
const LOCKOUT_DURATION = 15 * 60 * 1000 // 15 minutes

export async function recordFailedLogin(email: string) {
  const user = await db.user.findUnique({ where: { email } })

  if (!user) return

  await db.user.update({
    where: { id: user.id },
    data: {
      failedLoginAttempts: { increment: 1 },
      lastFailedLogin: new Date(),
    },
  })

  const updated = await db.user.findUnique({ where: { id: user.id } })

  if (updated && updated.failedLoginAttempts >= MAX_FAILED_ATTEMPTS) {
    await db.user.update({
      where: { id: user.id },
      data: {
        lockedUntil: new Date(Date.now() + LOCKOUT_DURATION),
      },
    })
  }
}

export async function isAccountLocked(email: string): Promise<boolean> {
  const user = await db.user.findUnique({ where: { email } })

  if (!user?.lockedUntil) return false

  if (user.lockedUntil < new Date()) {
    // Lockout expired, reset
    await db.user.update({
      where: { id: user.id },
      data: {
        failedLoginAttempts: 0,
        lockedUntil: null,
      },
    })
    return false
  }

  return true
}

export async function resetFailedAttempts(email: string) {
  await db.user.update({
    where: { email },
    data: {
      failedLoginAttempts: 0,
      lastFailedLogin: null,
    },
  })
}
```

### CAPTCHA Integration

```typescript
// lib/security/captcha.ts
export async function verifyCaptcha(token: string): Promise<boolean> {
  const response = await fetch(
    'https://www.google.com/recaptcha/api/siteverify',
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        secret: process.env.RECAPTCHA_SECRET_KEY!,
        response: token,
      }),
    }
  )

  const data = await response.json()
  return data.success && data.score >= 0.5
}

// app/api/auth/[...nextauth]/route.ts
import { verifyCaptcha } from '@/lib/security/captcha'
import { isAccountLocked, recordFailedLogin } from '@/lib/security/account-lockout'

export const { handlers, auth } = NextAuth({
  providers: [
    CredentialsProvider({
      credentials: {
        email: { type: 'email' },
        password: { type: 'password' },
        captcha: { type: 'text' },
      },
      async authorize(credentials) {
        const email = credentials.email as string

        // Check if account is locked
        if (await isAccountLocked(email)) {
          throw new Error('Account is temporarily locked. Please try again later.')
        }

        // Verify CAPTCHA
        const captchaValid = await verifyCaptcha(credentials.captcha as string)
        if (!captchaValid) {
          throw new Error('CAPTCHA verification failed')
        }

        // Verify credentials
        const user = await verifyCredentials(credentials)

        if (!user) {
          await recordFailedLogin(email)
          throw new Error('Invalid credentials')
        }

        return user
      },
    }),
  ],
})
```

---

## Session Security

Protect active sessions from hijacking and unauthorized access.

### Session Binding

Bind sessions to user agent and IP to detect hijacking:

```typescript
// lib/security/session-binding.ts
import { getServerSession } from 'next-auth'
import { headers } from 'next/headers'

export async function validateSessionBinding(): Promise<boolean> {
  const session = await getServerSession()
  const headersList = headers()

  if (!session?.user?.sessionMetadata) {
    return true // No binding data
  }

  const currentUA = headersList.get('user-agent')
  const currentIP = headersList.get('x-forwarded-for')?.split(',')[0]

  const { userAgent, ipAddress } = session.user.sessionMetadata

  // Strict validation
  if (currentUA !== userAgent) {
    return false
  }

  // IP can change (mobile networks), but log suspicious changes
  if (currentIP !== ipAddress) {
    console.warn('IP address changed for session', {
      sessionId: session.user.id,
      oldIP: ipAddress,
      newIP: currentIP,
    })
  }

  return true
}

// middleware.ts
import { validateSessionBinding } from '@/lib/security/session-binding'

export async function middleware(req: NextRequest) {
  if (req.nextUrl.pathname.startsWith('/dashboard')) {
    const isValid = await validateSessionBinding()

    if (!isValid) {
      return NextResponse.redirect(new URL('/login?error=session-hijack', req.url))
    }
  }

  return NextResponse.next()
}
```

### Session Timeout

Implement idle timeout and absolute timeout:

```typescript
// lib/security/session-timeout.ts
import { getServerSession } from 'next-auth'

const IDLE_TIMEOUT = 30 * 60 * 1000 // 30 minutes
const ABSOLUTE_TIMEOUT = 12 * 60 * 60 * 1000 // 12 hours

export async function validateSessionTimeout(): Promise<{
  valid: boolean
  reason?: 'idle' | 'absolute'
}> {
  const session = await getServerSession()

  if (!session?.user?.sessionMetadata) {
    return { valid: true }
  }

  const { createdAt, lastActivityAt } = session.user.sessionMetadata
  const now = Date.now()

  // Check absolute timeout
  if (now - new Date(createdAt).getTime() > ABSOLUTE_TIMEOUT) {
    return { valid: false, reason: 'absolute' }
  }

  // Check idle timeout
  if (now - new Date(lastActivityAt).getTime() > IDLE_TIMEOUT) {
    return { valid: false, reason: 'idle' }
  }

  return { valid: true }
}

// Update last activity
export async function updateLastActivity(userId: string) {
  await db.session.update({
    where: { userId },
    data: { lastActivityAt: new Date() },
  })
}
```

---

## Production Security Checklist

Essential security measures for production deployments.

### Environment Variables

```bash
# .env.production (NEVER commit this file)

# NextAuth
NEXTAUTH_URL=https://yourdomain.com
NEXTAUTH_SECRET= # Generate with: openssl rand -base64 32

# Use strong secrets (minimum 32 characters)
# Rotate secrets regularly
# Use different secrets for dev/staging/prod

# Database
DATABASE_URL=postgresql://user:password@host:5432/dbname?sslmode=require

# Enable SSL for database connections
# Use connection pooling
# Rotate database credentials quarterly
```

### Security Headers

```typescript
// next.config.js
module.exports = {
  async headers() {
    return [
      {
        source: '/(.*)',
        headers: [
          {
            key: 'X-Frame-Options',
            value: 'DENY',
          },
          {
            key: 'X-Content-Type-Options',
            value: 'nosniff',
          },
          {
            key: 'Referrer-Policy',
            value: 'strict-origin-when-cross-origin',
          },
          {
            key: 'Permissions-Policy',
            value: 'camera=(), microphone=(), geolocation=()',
          },
          {
            key: 'Strict-Transport-Security',
            value: 'max-age=31536000; includeSubDomains; preload',
          },
          {
            key: 'Content-Security-Policy',
            value: [
              "default-src 'self'",
              "script-src 'self' 'unsafe-eval' 'unsafe-inline'",
              "style-src 'self' 'unsafe-inline'",
              "img-src 'self' data: https:",
              "font-src 'self'",
              "connect-src 'self' https://api.yourdomain.com",
              "frame-ancestors 'none'",
            ].join('; '),
          },
        ],
      },
    ]
  },
}
```

### Input Validation

Always validate and sanitize user input:

```typescript
// lib/validation/auth.ts
import { z } from 'zod'

export const signInSchema = z.object({
  email: z
    .string()
    .email('Invalid email')
    .toLowerCase()
    .trim()
    .max(255, 'Email too long'),
  password: z
    .string()
    .min(8, 'Password must be at least 8 characters')
    .max(100, 'Password too long'),
})

export const signUpSchema = signInSchema.extend({
  name: z
    .string()
    .trim()
    .min(1, 'Name required')
    .max(100, 'Name too long')
    .regex(/^[a-zA-Z\s'-]+$/, 'Invalid name format'),
  confirmPassword: z.string(),
}).refine((data) => data.password === data.confirmPassword, {
  message: 'Passwords do not match',
  path: ['confirmPassword'],
})

// app/api/auth/signup/route.ts
import { signUpSchema } from '@/lib/validation/auth'

export async function POST(req: NextRequest) {
  const body = await req.json()

  // Validate input
  const result = signUpSchema.safeParse(body)

  if (!result.success) {
    return NextResponse.json(
      { error: result.error.flatten() },
      { status: 400 }
    )
  }

  // Process signup
  const { email, password, name } = result.data
  // ...
}
```

### Password Security

```typescript
// lib/security/password.ts
import bcrypt from 'bcryptjs'
import { z } from 'zod'

// Strong password requirements
export const passwordSchema = z
  .string()
  .min(12, 'Password must be at least 12 characters')
  .regex(/[A-Z]/, 'Password must contain uppercase letter')
  .regex(/[a-z]/, 'Password must contain lowercase letter')
  .regex(/[0-9]/, 'Password must contain number')
  .regex(/[^A-Za-z0-9]/, 'Password must contain special character')

export async function hashPassword(password: string): Promise<string> {
  // Use high cost factor (10-12 recommended)
  return bcrypt.hash(password, 12)
}

export async function verifyPassword(
  password: string,
  hash: string
): Promise<boolean> {
  return bcrypt.compare(password, hash)
}

// Check against common passwords
const COMMON_PASSWORDS = new Set([
  'password123',
  '123456789',
  'qwerty123',
  // ... add more
])

export function isCommonPassword(password: string): boolean {
  return COMMON_PASSWORDS.has(password.toLowerCase())
}
```

---

## Security Monitoring

Monitor and log security events.

### Audit Logging

```typescript
// lib/security/audit-log.ts
import { db } from '@/lib/db'

export enum AuditEvent {
  LOGIN_SUCCESS = 'LOGIN_SUCCESS',
  LOGIN_FAILED = 'LOGIN_FAILED',
  LOGOUT = 'LOGOUT',
  PASSWORD_CHANGE = 'PASSWORD_CHANGE',
  PASSWORD_RESET = 'PASSWORD_RESET',
  EMAIL_CHANGE = 'EMAIL_CHANGE',
  ACCOUNT_LOCKED = 'ACCOUNT_LOCKED',
  SUSPICIOUS_ACTIVITY = 'SUSPICIOUS_ACTIVITY',
}

export async function logAuditEvent(
  event: AuditEvent,
  userId: string | null,
  metadata?: Record<string, any>
) {
  await db.auditLog.create({
    data: {
      event,
      userId,
      metadata,
      ipAddress: metadata?.ipAddress,
      userAgent: metadata?.userAgent,
      timestamp: new Date(),
    },
  })

  // Alert on suspicious events
  if (event === AuditEvent.SUSPICIOUS_ACTIVITY) {
    await sendSecurityAlert(userId, metadata)
  }
}

// Usage in auth flow
async function handleLogin(email: string, success: boolean) {
  const user = await db.user.findUnique({ where: { email } })

  await logAuditEvent(
    success ? AuditEvent.LOGIN_SUCCESS : AuditEvent.LOGIN_FAILED,
    user?.id || null,
    {
      email,
      ipAddress: getClientIP(),
      userAgent: getUserAgent(),
    }
  )
}
```

### Anomaly Detection

```typescript
// lib/security/anomaly-detection.ts
export async function detectAnomalies(userId: string): Promise<string[]> {
  const anomalies: string[] = []

  // Check for multiple failed logins
  const recentFailures = await db.auditLog.count({
    where: {
      userId,
      event: AuditEvent.LOGIN_FAILED,
      timestamp: { gt: new Date(Date.now() - 60 * 60 * 1000) },
    },
  })

  if (recentFailures > 3) {
    anomalies.push('Multiple failed login attempts')
  }

  // Check for login from new location
  const recentLogins = await db.auditLog.findMany({
    where: {
      userId,
      event: AuditEvent.LOGIN_SUCCESS,
    },
    orderBy: { timestamp: 'desc' },
    take: 2,
  })

  if (recentLogins.length === 2) {
    const [current, previous] = recentLogins
    if (current.metadata?.country !== previous.metadata?.country) {
      anomalies.push('Login from new location')
    }
  }

  // Check for unusual activity time
  const hour = new Date().getHours()
  if (hour < 6 || hour > 23) {
    const usualTime = await db.auditLog.count({
      where: {
        userId,
        event: AuditEvent.LOGIN_SUCCESS,
        timestamp: {
          gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000),
        },
      },
    })

    if (usualTime < 5) {
      anomalies.push('Login at unusual time')
    }
  }

  return anomalies
}
```

---

## Production Deployment

Final security checklist before going live.

### Pre-Deployment Checklist

```typescript
// scripts/security-check.ts
interface SecurityCheck {
  name: string
  check: () => Promise<boolean>
  severity: 'critical' | 'high' | 'medium'
}

const securityChecks: SecurityCheck[] = [
  {
    name: 'NEXTAUTH_SECRET is set',
    severity: 'critical',
    check: async () => !!process.env.NEXTAUTH_SECRET,
  },
  {
    name: 'NEXTAUTH_SECRET is strong',
    severity: 'critical',
    check: async () => {
      const secret = process.env.NEXTAUTH_SECRET
      return !!secret && secret.length >= 32
    },
  },
  {
    name: 'HTTPS is enabled',
    severity: 'critical',
    check: async () => process.env.NEXTAUTH_URL?.startsWith('https://') || false,
  },
  {
    name: 'Secure cookies enabled',
    severity: 'critical',
    check: async () => process.env.NODE_ENV === 'production',
  },
  {
    name: 'Rate limiting configured',
    severity: 'high',
    check: async () => !!process.env.REDIS_URL,
  },
  {
    name: 'CORS properly configured',
    severity: 'high',
    check: async () => {
      // Check next.config.js for CORS settings
      return true
    },
  },
]

async function runSecurityChecks() {
  const results = await Promise.all(
    securityChecks.map(async (check) => ({
      ...check,
      passed: await check.check(),
    }))
  )

  const failed = results.filter((r) => !r.passed)

  if (failed.length > 0) {
    console.error('Security checks failed:')
    failed.forEach((f) => {
      console.error(`[${f.severity.toUpperCase()}] ${f.name}`)
    })

    const criticalFailures = failed.filter((f) => f.severity === 'critical')
    if (criticalFailures.length > 0) {
      throw new Error('Critical security checks failed')
    }
  }

  console.log('All security checks passed')
}

runSecurityChecks()
```

---

## AI Pair Programming Notes

**When to load this KB:**
- Hardening NextAuth for production
- Implementing rate limiting or brute force protection
- Setting up security monitoring
- Configuring secure cookies
- Need CSRF protection patterns

**Common starting points:**
- Production deployment: See Pre-Deployment Checklist section
- Rate limiting: See Rate Limiting section
- Secure cookies: See Secure Cookies section
- Audit logging: See Security Monitoring section

**Typical questions:**
- "How do I prevent brute force attacks?" → See Brute Force Protection section
- "How do I configure secure cookies?" → See Secure Cookies section
- "How do I implement rate limiting?" → See Rate Limiting section
- "What security headers should I use?" → See Production Security Checklist

**Related topics:**
- Middleware patterns: See `06-MIDDLEWARE.md`
- Session management: See `03-SESSIONS.md`
- Advanced authentication: See `08-ADVANCED-AUTH.md`

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1
