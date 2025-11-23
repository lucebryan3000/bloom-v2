---
id: nextauth-config-operations
topic: nextauth
file_role: guide
profile: full
difficulty_level: advanced
kb_version: 3.1
prerequisites: [nextauth-fundamentals, nextauth-sessions, nextauth-security]
related_topics: [production, configuration, monitoring, troubleshooting]
embedding_keywords: [nextauth, production, configuration, monitoring, troubleshooting, environment-variables]
last_reviewed: 2025-11-16
---

# NextAuth.js - Configuration & Operations

Production configuration, monitoring, and operational best practices for NextAuth.js.

## Overview

Running NextAuth in production requires careful configuration, monitoring, and operational procedures. This guide covers environment setup, configuration management, monitoring, troubleshooting, and disaster recovery.

---

## Environment Configuration

Proper environment variable management for different deployment environments.

### Environment Variables

```bash
# .env.production (NEVER commit this file)

# ============================================
# NextAuth Configuration
# ============================================

# Required: NextAuth URL (must be HTTPS in production)
NEXTAUTH_URL=https://yourdomain.com

# Required: NextAuth secret (generate with: openssl rand -base64 32)
NEXTAUTH_SECRET=your-super-secret-key-minimum-32-characters-long

# ============================================
# OAuth Providers
# ============================================

# Google OAuth
GOOGLE_CLIENT_ID=123456789.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=GOCSPX-xxxxxxxxxxxxx

# GitHub OAuth
GITHUB_CLIENT_ID=Iv1.xxxxxxxxxxxx
GITHUB_CLIENT_SECRET=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Facebook OAuth
FACEBOOK_CLIENT_ID=1234567890123456
FACEBOOK_CLIENT_SECRET=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Azure AD
AZURE_AD_CLIENT_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
AZURE_AD_CLIENT_SECRET=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
AZURE_AD_TENANT_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

# ============================================
# Database
# ============================================

# PostgreSQL
DATABASE_URL=postgresql://user:password@host:5432/dbname?sslmode=require

# MongoDB
MONGODB_URI=mongodb+srv://user:password@cluster.mongodb.net/dbname

# ============================================
# Email Provider (for magic links)
# ============================================

# SendGrid
SENDGRID_API_KEY=SG.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
EMAIL_FROM=noreply@yourdomain.com

# AWS SES
AWS_ACCESS_KEY_ID=AKIAxxxxxxxxxxxxx
AWS_SECRET_ACCESS_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
AWS_REGION=us-east-1

# ============================================
# Redis (for sessions/rate limiting)
# ============================================

REDIS_URL=redis://default:password@host:6379

# ============================================
# Monitoring & Logging
# ============================================

# Sentry
SENTRY_DSN=https://xxxxxxxxxxxxxxxxxxxxxxxxxxxxx@sentry.io/xxxxxxx

# LogDNA/Datadog
LOG_LEVEL=info
```

### Environment Validation

```typescript
// lib/config/env.ts
import { z } from 'zod'

const envSchema = z.object({
  // NextAuth
  NEXTAUTH_URL: z.string().url(),
  NEXTAUTH_SECRET: z.string().min(32),

  // OAuth Providers (optional)
  GOOGLE_CLIENT_ID: z.string().optional(),
  GOOGLE_CLIENT_SECRET: z.string().optional(),
  GITHUB_CLIENT_ID: z.string().optional(),
  GITHUB_CLIENT_SECRET: z.string().optional(),

  // Database
  DATABASE_URL: z.string().url(),

  // Email
  SENDGRID_API_KEY: z.string().optional(),
  EMAIL_FROM: z.string().email().optional(),

  // Redis
  REDIS_URL: z.string().url().optional(),

  // Environment
  NODE_ENV: z.enum(['development', 'production', 'test']),
})

export const env = envSchema.parse(process.env)

// Validate on startup
if (process.env.NODE_ENV === 'production') {
  console.log('✅ Environment validation passed')
}
```

### Multi-Environment Setup

```typescript
// lib/config/auth.config.ts
import { NextAuthOptions } from 'next-auth'

const isDevelopment = process.env.NODE_ENV === 'development'
const isProduction = process.env.NODE_ENV === 'production'

export const authConfig: NextAuthOptions = {
  // Development-specific settings
  debug: isDevelopment,

  // Cookie settings based on environment
  cookies: {
    sessionToken: {
      name: isProduction
        ? '__Secure-next-auth.session-token'
        : 'next-auth.session-token',
      options: {
        httpOnly: true,
        sameSite: 'lax',
        path: '/',
        secure: isProduction, // Only secure in production
        domain: isProduction ? '.yourdomain.com' : undefined,
      },
    },
  },

  // Session settings
  session: {
    strategy: 'jwt',
    maxAge: isProduction ? 7 * 24 * 60 * 60 : 30 * 24 * 60 * 60, // 7 days prod, 30 days dev
    updateAge: isProduction ? 24 * 60 * 60 : 0, // Update daily in prod, always in dev
  },

  // Providers
  providers: [
    // Only enable certain providers in production
    ...(isProduction ? [
      GoogleProvider({
        clientId: process.env.GOOGLE_CLIENT_ID!,
        clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
      }),
    ] : []),

    // Development-only providers
    ...(isDevelopment ? [
      CredentialsProvider({
        credentials: {
          email: { type: 'email' },
          password: { type: 'password' },
        },
        async authorize(credentials) {
          // Simplified auth for development
          return { id: '1', email: credentials?.email }
        },
      }),
    ] : []),
  ],
}
```

---

## Configuration Management

Centralized configuration for different deployment scenarios.

### Configuration Factory

```typescript
// lib/config/factory.ts
import { NextAuthOptions } from 'next-auth'
import { productionConfig } from './production'
import { developmentConfig } from './development'
import { testConfig } from './test'

export function createAuthConfig(): NextAuthOptions {
  const env = process.env.NODE_ENV

  switch (env) {
    case 'production':
      return productionConfig
    case 'test':
      return testConfig
    default:
      return developmentConfig
  }
}

// lib/config/production.ts
export const productionConfig: NextAuthOptions = {
  debug: false,
  session: {
    strategy: 'jwt',
    maxAge: 7 * 24 * 60 * 60, // 7 days
  },
  pages: {
    signIn: '/auth/signin',
    signOut: '/auth/signout',
    error: '/auth/error',
    verifyRequest: '/auth/verify-request',
  },
  callbacks: {
    async jwt({ token, user, account }) {
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
  },
  events: {
    async signIn(message) {
      // Log to monitoring service
      await logEvent('user_signin', { userId: message.user.id })
    },
    async signOut(message) {
      await logEvent('user_signout', { userId: message.token?.sub })
    },
  },
}
```

### Feature Flags

```typescript
// lib/config/features.ts
interface FeatureFlags {
  enableOAuth: boolean
  enableMagicLinks: boolean
  enable2FA: boolean
  enableRateLimiting: boolean
  enableAuditLogging: boolean
}

export const features: FeatureFlags = {
  enableOAuth: process.env.ENABLE_OAUTH === 'true',
  enableMagicLinks: process.env.ENABLE_MAGIC_LINKS === 'true',
  enable2FA: process.env.ENABLE_2FA === 'true',
  enableRateLimiting: process.env.ENABLE_RATE_LIMITING === 'true',
  enableAuditLogging: process.env.NODE_ENV === 'production',
}

// Usage
if (features.enable2FA) {
  // Enable 2FA middleware
}
```

---

## Monitoring & Observability

Track authentication metrics and system health.

### Metrics Collection

```typescript
// lib/monitoring/metrics.ts
interface AuthMetrics {
  totalSignIns: number
  failedSignIns: number
  activeUsers: number
  sessionDuration: number[]
}

class MetricsCollector {
  private metrics: AuthMetrics = {
    totalSignIns: 0,
    failedSignIns: 0,
    activeUsers: 0,
    sessionDuration: [],
  }

  recordSignIn(success: boolean) {
    if (success) {
      this.metrics.totalSignIns++
    } else {
      this.metrics.failedSignIns++
    }
  }

  recordSessionDuration(durationMs: number) {
    this.metrics.sessionDuration.push(durationMs)
  }

  getMetrics() {
    return {
      ...this.metrics,
      avgSessionDuration:
        this.metrics.sessionDuration.reduce((a, b) => a + b, 0) /
        this.metrics.sessionDuration.length,
      failureRate:
        this.metrics.failedSignIns /
        (this.metrics.totalSignIns + this.metrics.failedSignIns),
    }
  }

  reset() {
    this.metrics = {
      totalSignIns: 0,
      failedSignIns: 0,
      activeUsers: 0,
      sessionDuration: [],
    }
  }
}

export const metrics = new MetricsCollector()

// app/api/auth/[...nextauth]/route.ts
import { metrics } from '@/lib/monitoring/metrics'

export const authOptions = {
  events: {
    async signIn({ user, account, isNewUser }) {
      metrics.recordSignIn(true)

      // Send to monitoring service
      await sendMetric('auth.signin', {
        userId: user.id,
        provider: account?.provider,
        isNewUser,
      })
    },
  },
}
```

### Error Tracking

```typescript
// lib/monitoring/errors.ts
import * as Sentry from '@sentry/nextjs'

export function trackAuthError(error: Error, context?: Record<string, any>) {
  console.error('Auth error:', error, context)

  if (process.env.NODE_ENV === 'production') {
    Sentry.captureException(error, {
      tags: { category: 'authentication' },
      extra: context,
    })
  }
}

// Usage in callbacks
export const authOptions = {
  callbacks: {
    async signIn({ user, account, profile }) {
      try {
        // Sign-in logic
        return true
      } catch (error) {
        trackAuthError(error as Error, {
          userId: user.id,
          provider: account?.provider,
        })
        return false
      }
    },
  },
}
```

### Health Checks

```typescript
// app/api/health/auth/route.ts
import { NextResponse } from 'next/server'
import { getServerSession } from 'next-auth'
import { authOptions } from '@/app/api/auth/[...nextauth]/route'

export async function GET() {
  const checks = {
    sessionProvider: false,
    database: false,
    redis: false,
  }

  try {
    // Check if session provider works
    const session = await getServerSession(authOptions)
    checks.sessionProvider = true

    // Check database connection
    await db.$queryRaw`SELECT 1`
    checks.database = true

    // Check Redis (if using)
    if (process.env.REDIS_URL) {
      await redis.ping()
      checks.redis = true
    }

    const allHealthy = Object.values(checks).every((v) => v)

    return NextResponse.json(
      { status: allHealthy ? 'healthy' : 'degraded', checks },
      { status: allHealthy ? 200 : 503 }
    )
  } catch (error) {
    return NextResponse.json(
      { status: 'unhealthy', checks, error: String(error) },
      { status: 503 }
    )
  }
}
```

---

## Logging

Structured logging for authentication events.

### Audit Logger

```typescript
// lib/logging/audit.ts
import { prisma } from '@/lib/db'

export enum AuditAction {
  SIGNIN = 'SIGNIN',
  SIGNOUT = 'SIGNOUT',
  SIGNUP = 'SIGNUP',
  PASSWORD_RESET = 'PASSWORD_RESET',
  EMAIL_CHANGE = 'EMAIL_CHANGE',
  PROFILE_UPDATE = 'PROFILE_UPDATE',
}

export async function auditLog(
  action: AuditAction,
  userId: string | null,
  metadata?: Record<string, any>
) {
  await prisma.auditLog.create({
    data: {
      action,
      userId,
      metadata,
      ipAddress: metadata?.ipAddress,
      userAgent: metadata?.userAgent,
      timestamp: new Date(),
    },
  })

  // Also log to external service
  if (process.env.NODE_ENV === 'production') {
    await sendToLogService({
      level: 'info',
      action,
      userId,
      ...metadata,
    })
  }
}

// Usage
export const authOptions = {
  events: {
    async signIn({ user }) {
      await auditLog(AuditAction.SIGNIN, user.id, {
        ipAddress: getClientIP(),
        userAgent: getUserAgent(),
      })
    },
    async signOut({ token }) {
      await auditLog(AuditAction.SIGNOUT, token?.sub || null)
    },
  },
}
```

### Structured Logging

```typescript
// lib/logging/logger.ts
import winston from 'winston'

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: { service: 'nextauth' },
  transports: [
    new winston.transports.File({ filename: 'logs/error.log', level: 'error' }),
    new winston.transports.File({ filename: 'logs/combined.log' }),
  ],
})

if (process.env.NODE_ENV !== 'production') {
  logger.add(
    new winston.transports.Console({
      format: winston.format.simple(),
    })
  )
}

export { logger }

// Usage
logger.info('User signed in', { userId: user.id, provider: 'google' })
logger.error('Sign-in failed', { email, error: error.message })
```

---

## Troubleshooting

Common issues and solutions.

### Debug Mode

```typescript
// Enable debug mode in development
export const authOptions: NextAuthOptions = {
  debug: process.env.NODE_ENV === 'development',
  logger: {
    error(code, metadata) {
      console.error('NextAuth Error:', code, metadata)
    },
    warn(code) {
      console.warn('NextAuth Warning:', code)
    },
    debug(code, metadata) {
      console.log('NextAuth Debug:', code, metadata)
    },
  },
}
```

### Common Issues

**Issue: "Invalid CSRF token"**

```typescript
// Solution 1: Check cookie settings
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

// Solution 2: Ensure NEXTAUTH_URL is set correctly
NEXTAUTH_URL=https://yourdomain.com  // Must match actual domain
```

**Issue: "Session undefined in Server Components"**

```typescript
// Solution: Import from correct location
import { getServerSession } from 'next-auth'
import { authOptions } from '@/app/api/auth/[...nextauth]/route'

export default async function Page() {
  const session = await getServerSession(authOptions)
  // NOT: const session = await getSession()
}
```

**Issue: "Callback URL mismatch"**

```typescript
// Solution: Configure allowed callback URLs
export const authOptions = {
  providers: [
    GoogleProvider({
      clientId: process.env.GOOGLE_CLIENT_ID!,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
      authorization: {
        params: {
          // Add all allowed redirect URIs in Google Console:
          // https://yourdomain.com/api/auth/callback/google
          // http://localhost:3000/api/auth/callback/google
        },
      },
    }),
  ],
}
```

**Issue: "Database sessions not working"**

```typescript
// Solution: Check adapter configuration
import { PrismaAdapter } from '@auth/prisma-adapter'

export const authOptions = {
  adapter: PrismaAdapter(prisma),
  session: {
    strategy: 'database', // MUST be 'database', not 'jwt'
  },
}

// Verify schema includes all required models
// Account, Session, User, VerificationToken
```

### Diagnostic Endpoint

```typescript
// app/api/auth/diagnostics/route.ts (dev only)
import { NextResponse } from 'next/server'

export async function GET() {
  if (process.env.NODE_ENV !== 'development') {
    return NextResponse.json({ error: 'Not available in production' }, { status: 403 })
  }

  return NextResponse.json({
    env: {
      NEXTAUTH_URL: process.env.NEXTAUTH_URL,
      NEXTAUTH_SECRET: process.env.NEXTAUTH_SECRET ? '✓ Set' : '✗ Missing',
      DATABASE_URL: process.env.DATABASE_URL ? '✓ Set' : '✗ Missing',
    },
    providers: authOptions.providers.map((p) => p.id),
    session: {
      strategy: authOptions.session?.strategy,
      maxAge: authOptions.session?.maxAge,
    },
  })
}
```

---

## Database Migrations

Managing schema changes in production.

### Safe Migration Strategy

```bash
# 1. Create migration in development
npx prisma migrate dev --name add_user_role

# 2. Review generated SQL
cat prisma/migrations/XXXXXX_add_user_role/migration.sql

# 3. Test migration in staging
DATABASE_URL=$STAGING_DATABASE_URL npx prisma migrate deploy

# 4. Backup production database
pg_dump $PROD_DB_URL > backup_$(date +%Y%m%d).sql

# 5. Deploy to production (zero downtime)
DATABASE_URL=$PROD_DB_URL npx prisma migrate deploy
```

### Schema Versioning

```prisma
// prisma/schema.prisma
model User {
  id            String   @id @default(cuid())
  email         String   @unique

  // Add version field for schema evolution
  schemaVersion Int      @default(1)

  // New fields (backward compatible)
  role          Role?    @default(USER)

  @@index([email])
  @@index([schemaVersion])
}
```

---

## Disaster Recovery

Procedures for handling authentication system failures.

### Backup & Restore

```typescript
// scripts/backup-auth-data.ts
import { PrismaClient } from '@prisma/client'
import fs from 'fs'

const prisma = new PrismaClient()

async function backupAuthData() {
  const users = await prisma.user.findMany()
  const accounts = await prisma.account.findMany()
  const sessions = await prisma.session.findMany()

  const backup = {
    timestamp: new Date().toISOString(),
    users,
    accounts,
    sessions,
  }

  fs.writeFileSync(
    `backups/auth_${Date.now()}.json`,
    JSON.stringify(backup, null, 2)
  )

  console.log('Backup created successfully')
}

backupAuthData()
```

### Failover Plan

```typescript
// lib/auth/failover.ts
export const authOptions: NextAuthOptions = {
  // Primary database
  adapter: PrismaAdapter(primaryDb),

  callbacks: {
    async signIn({ user }) {
      try {
        // Try primary database
        await primaryDb.user.findUnique({ where: { id: user.id } })
        return true
      } catch (error) {
        console.error('Primary DB error, failing over to replica')

        try {
          // Fallback to read replica
          await replicaDb.user.findUnique({ where: { id: user.id } })
          return true
        } catch (replicaError) {
          // Both failed, log and deny
          trackAuthError(replicaError as Error)
          return false
        }
      }
    },
  },
}
```

---

## AI Pair Programming Notes

**When to load this KB:**
- Setting up NextAuth for production
- Configuring environment variables
- Need monitoring and logging patterns
- Troubleshooting authentication issues
- Planning disaster recovery

**Common starting points:**
- Production setup: See Environment Configuration section
- Monitoring: See Monitoring & Observability section
- Troubleshooting: See Troubleshooting section
- Database migrations: See Database Migrations section

**Typical questions:**
- "How do I configure NextAuth for production?" → See Environment Configuration
- "How do I monitor authentication?" → See Monitoring & Observability
- "How do I troubleshoot CSRF errors?" → See Troubleshooting section
- "How do I handle database migrations?" → See Database Migrations

**Related topics:**
- Security: See `09-SECURITY.md`
- Sessions: See `03-SESSIONS.md`
- Integrations: See `10-INTEGRATIONS.md`

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1
