---
id: nextauth-index
topic: nextauth
file_role: navigation
profile: full
kb_version: 3.1
prerequisites: []
related_topics: [authentication, oauth, sessions, security]
embedding_keywords: [nextauth, index, navigation, authentication, oauth]
last_reviewed: 2025-11-16
---

# NextAuth.js - Complete Index

Complete navigation and problem-based quick finder for NextAuth.js knowledge base.

## Quick Navigation

### Essential Files

- **[README.md](./README.md)** - Overview, comparison with alternatives, learning paths
- **[INDEX.md](./INDEX.md)** (this file) - Complete index and navigation
- **[QUICK-REFERENCE.md](./QUICK-REFERENCE.md)** - One-page cheat sheet
- **[FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md)** - Framework integrations

### Core Topics (Files 01-11)

| # | File | Topic | Focus |
|---|------|-------|-------|
| 01 | [01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md) | Core concepts and setup | Installation, basic configuration, session access |
| 02 | [02-PROVIDERS.md](./02-PROVIDERS.md) | Authentication providers | OAuth (Google, GitHub, etc.), Credentials, Email |
| 03 | [03-SESSIONS.md](./03-SESSIONS.md) | Session management | JWT vs Database sessions, accessing sessions |
| 04 | [04-JWT-VS-DATABASE.md](./04-JWT-VS-DATABASE.md) | Session strategies | Performance comparison, migration patterns |
| 05 | [05-CALLBACKS.md](./05-CALLBACKS.md) | Lifecycle callbacks | signIn, jwt, session, redirect customization |
| 06 | [06-MIDDLEWARE.md](./06-MIDDLEWARE.md) | Route protection | Middleware patterns, role-based access |
| 07 | [07-PROTECTED-ROUTES.md](./07-PROTECTED-ROUTES.md) | Protected routes | Server/Client Components, API routes, Server Actions |
| 08 | [08-ADVANCED-AUTH.md](./08-ADVANCED-AUTH.md) | Advanced patterns | 2FA, magic links, account linking, SAML |
| 09 | [09-SECURITY.md](./09-SECURITY.md) | Security best practices | CSRF, rate limiting, brute force protection |
| 10 | [10-INTEGRATIONS.md](./10-INTEGRATIONS.md) | Framework integration | Next.js, Prisma, Drizzle, tRPC, React Query |
| 11 | [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) | Production patterns | Environment, monitoring, troubleshooting |

---

## Learning Paths

### 🟢 Beginner Path (Start Here)

**Goal**: Set up basic authentication with OAuth providers

1. **[README.md](./README.md)** - Understand what NextAuth is and why to use it
2. **[01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md)** - Learn installation and basic setup
3. **[02-PROVIDERS.md](./02-PROVIDERS.md)** - Add Google/GitHub OAuth
4. **[03-SESSIONS.md](./03-SESSIONS.md)** - Access session data in components
5. **[06-MIDDLEWARE.md](./06-MIDDLEWARE.md)** - Protect routes with middleware
6. **[QUICK-REFERENCE.md](./QUICK-REFERENCE.md)** - Keep as handy reference

**Time**: ~2 hours | **Outcome**: Working OAuth authentication

### 🟡 Intermediate Path

**Goal**: Build production-ready authentication with database integration

**Prerequisites**: Complete Beginner Path

1. **[04-JWT-VS-DATABASE.md](./04-JWT-VS-DATABASE.md)** - Choose session strategy
2. **[05-CALLBACKS.md](./05-CALLBACKS.md)** - Customize auth flow
3. **[10-INTEGRATIONS.md](./10-INTEGRATIONS.md)** - Integrate with Prisma/Drizzle
4. **[07-PROTECTED-ROUTES.md](./07-PROTECTED-ROUTES.md)** - Multi-layer protection
5. **[FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md)** - tRPC, React Query patterns

**Time**: ~4 hours | **Outcome**: Full-stack auth with database

### 🔴 Advanced Path

**Goal**: Enterprise-grade authentication with security hardening

**Prerequisites**: Complete Intermediate Path

1. **[08-ADVANCED-AUTH.md](./08-ADVANCED-AUTH.md)** - 2FA, magic links, SAML
2. **[09-SECURITY.md](./09-SECURITY.md)** - Security hardening
3. **[11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md)** - Production operations

**Time**: ~3 hours | **Outcome**: Enterprise-ready authentication

---

## Problem-Based Quick Find

### "I want to..."

#### Setup & Installation
- **Install NextAuth** → [01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md) → Installation
- **Configure environment variables** → [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) → Environment Configuration
- **Choose between JWT and database sessions** → [04-JWT-VS-DATABASE.md](./04-JWT-VS-DATABASE.md)

#### Authentication Providers
- **Add Google OAuth** → [02-PROVIDERS.md](./02-PROVIDERS.md) → OAuth Providers → Google
- **Add GitHub OAuth** → [02-PROVIDERS.md](./02-PROVIDERS.md) → OAuth Providers → GitHub
- **Add username/password auth** → [02-PROVIDERS.md](./02-PROVIDERS.md) → Credentials Provider
- **Add email magic links** → [02-PROVIDERS.md](./02-PROVIDERS.md) → Email Provider
- **Add Azure AD/Okta SSO** → [02-PROVIDERS.md](./02-PROVIDERS.md) → Enterprise Providers
- **Support multiple providers** → [02-PROVIDERS.md](./02-PROVIDERS.md) → Multiple Providers

#### Sessions
- **Access session in Server Component** → [03-SESSIONS.md](./03-SESSIONS.md) → Server Components
- **Access session in Client Component** → [03-SESSIONS.md](./03-SESSIONS.md) → Client Components
- **Access session in API route** → [03-SESSIONS.md](./03-SESSIONS.md) → API Routes
- **Choose JWT vs database sessions** → [04-JWT-VS-DATABASE.md](./04-JWT-VS-DATABASE.md) → Comparison
- **Migrate from JWT to database** → [04-JWT-VS-DATABASE.md](./04-JWT-VS-DATABASE.md) → Migration

#### Customization
- **Add custom user fields** → [05-CALLBACKS.md](./05-CALLBACKS.md) → jwt/session callbacks
- **Add roles to session** → [05-CALLBACKS.md](./05-CALLBACKS.md) → jwt callback
- **Customize redirect after sign-in** → [05-CALLBACKS.md](./05-CALLBACKS.md) → redirect callback
- **Block sign-ins based on conditions** → [05-CALLBACKS.md](./05-CALLBACKS.md) → signIn callback

#### Route Protection
- **Protect routes with middleware** → [06-MIDDLEWARE.md](./06-MIDDLEWARE.md) → Basic Middleware
- **Protect specific routes** → [06-MIDDLEWARE.md](./06-MIDDLEWARE.md) → Route Matching
- **Add role-based access** → [06-MIDDLEWARE.md](./06-MIDDLEWARE.md) → Role-Based Access
- **Protect Server Components** → [07-PROTECTED-ROUTES.md](./07-PROTECTED-ROUTES.md) → Server Component Protection
- **Protect API routes** → [07-PROTECTED-ROUTES.md](./07-PROTECTED-ROUTES.md) → API Route Protection
- **Protect Server Actions** → [07-PROTECTED-ROUTES.md](./07-PROTECTED-ROUTES.md) → Server Actions

#### Advanced Features
- **Implement 2FA** → [08-ADVANCED-AUTH.md](./08-ADVANCED-AUTH.md) → Two-Factor Authentication
- **Add magic link login** → [08-ADVANCED-AUTH.md](./08-ADVANCED-AUTH.md) → Magic Links
- **Link multiple OAuth accounts** → [08-ADVANCED-AUTH.md](./08-ADVANCED-AUTH.md) → Account Linking
- **Add SAML SSO** → [08-ADVANCED-AUTH.md](./08-ADVANCED-AUTH.md) → Enterprise Authentication
- **Custom OAuth flow** → [08-ADVANCED-AUTH.md](./08-ADVANCED-AUTH.md) → Custom OAuth Flows

#### Security
- **Prevent CSRF attacks** → [09-SECURITY.md](./09-SECURITY.md) → CSRF Protection
- **Configure secure cookies** → [09-SECURITY.md](./09-SECURITY.md) → Secure Cookies
- **Add rate limiting** → [09-SECURITY.md](./09-SECURITY.md) → Rate Limiting
- **Prevent brute force attacks** → [09-SECURITY.md](./09-SECURITY.md) → Brute Force Protection
- **Implement account lockout** → [09-SECURITY.md](./09-SECURITY.md) → Account Lockout
- **Add CAPTCHA** → [09-SECURITY.md](./09-SECURITY.md) → CAPTCHA Integration
- **Secure sessions** → [09-SECURITY.md](./09-SECURITY.md) → Session Security

#### Database Integration
- **Integrate with Prisma** → [10-INTEGRATIONS.md](./10-INTEGRATIONS.md) → Prisma Integration
- **Integrate with Drizzle ORM** → [10-INTEGRATIONS.md](./10-INTEGRATIONS.md) → Drizzle Integration
- **Add custom user fields to database** → [10-INTEGRATIONS.md](./10-INTEGRATIONS.md) → Extended User Model
- **Integrate with tRPC** → [10-INTEGRATIONS.md](./10-INTEGRATIONS.md) → tRPC Integration
- **Use with React Query** → [10-INTEGRATIONS.md](./10-INTEGRATIONS.md) → React Query Integration

#### Production & Operations
- **Configure for production** → [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) → Environment Configuration
- **Monitor authentication** → [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) → Monitoring
- **Set up logging** → [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) → Logging
- **Troubleshoot CSRF errors** → [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) → Troubleshooting
- **Handle database migrations** → [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) → Database Migrations
- **Set up health checks** → [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) → Health Checks

---

## Topic-Based Navigation

### Authentication Basics
- **What is NextAuth?** → [README.md](./README.md) → What is NextAuth.js?
- **Why use NextAuth?** → [README.md](./README.md) → Why NextAuth.js?
- **Installation** → [01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md) → Installation
- **Basic setup** → [01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md) → Basic Configuration
- **Quick start** → [README.md](./README.md) → Quick Start

### Providers
- **OAuth providers** → [02-PROVIDERS.md](./02-PROVIDERS.md) → OAuth Providers
- **Credentials provider** → [02-PROVIDERS.md](./02-PROVIDERS.md) → Credentials Provider
- **Email provider** → [02-PROVIDERS.md](./02-PROVIDERS.md) → Email Provider
- **Multiple providers** → [02-PROVIDERS.md](./02-PROVIDERS.md) → Combining Providers
- **Custom providers** → [08-ADVANCED-AUTH.md](./08-ADVANCED-AUTH.md) → Custom OAuth Flows

### Sessions
- **Session types** → [03-SESSIONS.md](./03-SESSIONS.md) → Session Types
- **JWT sessions** → [04-JWT-VS-DATABASE.md](./04-JWT-VS-DATABASE.md) → JWT Sessions
- **Database sessions** → [04-JWT-VS-DATABASE.md](./04-JWT-VS-DATABASE.md) → Database Sessions
- **Session access** → [03-SESSIONS.md](./03-SESSIONS.md) → Accessing Sessions
- **Session timeout** → [09-SECURITY.md](./09-SECURITY.md) → Session Timeout

### Customization
- **Callbacks** → [05-CALLBACKS.md](./05-CALLBACKS.md)
- **Events** → [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) → Logging
- **Pages** → [01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md) → Custom Pages
- **Error handling** → [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) → Troubleshooting

### Security
- **CSRF protection** → [09-SECURITY.md](./09-SECURITY.md) → CSRF Protection
- **Rate limiting** → [09-SECURITY.md](./09-SECURITY.md) → Rate Limiting
- **Brute force protection** → [09-SECURITY.md](./09-SECURITY.md) → Brute Force Protection
- **Secure cookies** → [09-SECURITY.md](./09-SECURITY.md) → Secure Cookies
- **Security headers** → [09-SECURITY.md](./09-SECURITY.md) → Security Headers
- **Input validation** → [09-SECURITY.md](./09-SECURITY.md) → Input Validation
- **Password security** → [09-SECURITY.md](./09-SECURITY.md) → Password Security

### Advanced Features
- **Two-factor authentication** → [08-ADVANCED-AUTH.md](./08-ADVANCED-AUTH.md) → 2FA
- **Magic links** → [08-ADVANCED-AUTH.md](./08-ADVANCED-AUTH.md) → Magic Links
- **Account linking** → [08-ADVANCED-AUTH.md](./08-ADVANCED-AUTH.md) → Account Linking
- **SAML/SSO** → [08-ADVANCED-AUTH.md](./08-ADVANCED-AUTH.md) → Enterprise Authentication
- **Adaptive authentication** → [08-ADVANCED-AUTH.md](./08-ADVANCED-AUTH.md) → Adaptive Authentication

### Database Integration
- **Prisma** → [10-INTEGRATIONS.md](./10-INTEGRATIONS.md) → Prisma Integration
- **Drizzle** → [10-INTEGRATIONS.md](./10-INTEGRATIONS.md) → Drizzle Integration
- **Database adapters** → [10-INTEGRATIONS.md](./10-INTEGRATIONS.md)
- **Schema design** → [10-INTEGRATIONS.md](./10-INTEGRATIONS.md) → Schema Setup

### Framework Integration
- **Next.js App Router** → [10-INTEGRATIONS.md](./10-INTEGRATIONS.md) → Next.js Integration
- **tRPC** → [10-INTEGRATIONS.md](./10-INTEGRATIONS.md) → tRPC Integration
- **React Query** → [10-INTEGRATIONS.md](./10-INTEGRATIONS.md) → React Query Integration
- **Express.js** → [10-INTEGRATIONS.md](./10-INTEGRATIONS.md) → Express Integration

### Production & Operations
- **Environment variables** → [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) → Environment Configuration
- **Configuration management** → [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) → Configuration Management
- **Monitoring** → [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) → Monitoring
- **Logging** → [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) → Logging
- **Troubleshooting** → [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) → Troubleshooting
- **Database migrations** → [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) → Database Migrations
- **Disaster recovery** → [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) → Disaster Recovery

---

## File Breakdown

### README.md (595 lines)

**Purpose**: Comprehensive overview and comparison

**Contains**:
- What is NextAuth.js
- Comparison with Auth0, Firebase Auth, Clerk, Supabase
- Documentation structure
- Learning paths (3 levels)
- Quick start guide
- Key features
- Use cases
- Common patterns
- Migration guides

**Use when**: First-time learning, comparing solutions, planning implementation

---

### 01-FUNDAMENTALS.md

**Purpose**: Core concepts and basic setup

**Contains**:
- Installation
- Basic configuration
- Session access patterns
- Custom pages

**Use when**: Setting up NextAuth for the first time

---

### 02-PROVIDERS.md (660 lines)

**Purpose**: Authentication provider setup

**Contains**:
- OAuth providers (Google, GitHub, Facebook, Discord, Azure AD, Okta)
- Credentials provider with bcrypt
- Email provider (magic links)
- Multiple provider setup
- Provider configuration best practices

**Use when**: Adding authentication providers

---

### 03-SESSIONS.md (605 lines)

**Purpose**: Session management fundamentals

**Contains**:
- JWT vs Database sessions overview
- Accessing sessions in Server Components
- Accessing sessions in Client Components
- Accessing sessions in API Routes
- Session configuration

**Use when**: Understanding session management, choosing session strategy

---

### 04-JWT-VS-DATABASE.md (608 lines)

**Purpose**: Deep comparison of session strategies

**Contains**:
- Performance benchmarks (JWT: 0.2ms vs Database: 12.5ms)
- When to use JWT vs Database
- Migration strategies (JWT ↔ Database)
- Hybrid approaches
- Trade-offs analysis

**Use when**: Choosing session strategy, optimizing performance, planning migration

---

### 05-CALLBACKS.md (728 lines)

**Purpose**: Lifecycle callback customization

**Contains**:
- signIn callback (authorization logic)
- jwt callback (custom claims)
- session callback (client-side data)
- redirect callback (post-login flow)
- Real-world examples

**Use when**: Customizing auth flow, adding roles, controlling redirects

---

### 06-MIDDLEWARE.md (633 lines)

**Purpose**: Route protection with middleware

**Contains**:
- Basic middleware setup
- Route matching patterns
- Role-based access control
- Permission-based access
- Rate limiting middleware

**Use when**: Protecting routes, implementing role-based access

---

### 07-PROTECTED-ROUTES.md (650+ lines)

**Purpose**: Multi-layer route protection

**Contains**:
- Server Component protection
- Client Component protection
- API Route protection
- Server Actions protection
- Reusable protection utilities

**Use when**: Implementing comprehensive route protection

---

### 08-ADVANCED-AUTH.md (783+ lines)

**Purpose**: Enterprise-grade authentication patterns

**Contains**:
- Two-factor authentication (TOTP, SMS)
- Magic links implementation
- Account linking (multiple OAuth providers)
- Custom OAuth flows with PKCE
- SAML/SSO integration
- Adaptive authentication

**Use when**: Implementing enterprise features, 2FA, SSO

---

### 09-SECURITY.md (850+ lines)

**Purpose**: Security best practices and hardening

**Contains**:
- CSRF protection patterns
- Secure cookie configuration
- Rate limiting (basic, sign-in, IP-based)
- Brute force protection (lockout, CAPTCHA)
- Session security (binding, timeout)
- Production security checklist
- Audit logging
- Anomaly detection

**Use when**: Hardening for production, implementing security measures

---

### 10-INTEGRATIONS.md (780+ lines)

**Purpose**: Framework and database integrations

**Contains**:
- Next.js App Router (Server Components, API Routes, Server Actions)
- Prisma integration (schema, adapter, extended models)
- Drizzle ORM integration
- tRPC integration (protected procedures, role-based access)
- React Query integration (optimistic updates)
- Express.js integration

**Use when**: Integrating with databases, building type-safe APIs

---

### 11-CONFIG-OPERATIONS.md (870+ lines)

**Purpose**: Production configuration and operations

**Contains**:
- Environment configuration
- Multi-environment setup
- Configuration management
- Monitoring & observability
- Error tracking
- Health checks
- Logging (audit logs, structured logging)
- Troubleshooting guide
- Database migrations
- Disaster recovery

**Use when**: Deploying to production, monitoring, troubleshooting

---

### QUICK-REFERENCE.md

**Purpose**: One-page cheat sheet

**Contains**:
- Quick syntax reference
- Common patterns
- Code snippets
- Quick lookup table

**Use when**: Quick syntax lookup during development

---

### FRAMEWORK-INTEGRATION-PATTERNS.md

**Purpose**: Framework-specific integration patterns

**Contains**:
- Detailed integration examples
- Best practices per framework
- Performance optimization

**Use when**: Integrating with specific frameworks

---

## Code Examples by Topic

### Basic Setup
```typescript
// See: 01-FUNDAMENTALS.md → Basic Configuration
import NextAuth from 'next-auth'
import GoogleProvider from 'next-auth/providers/google'

export const { handlers, auth } = NextAuth({
  providers: [GoogleProvider({ /* ... */ })],
})
```

### Session Access
```typescript
// See: 03-SESSIONS.md → Server Components
import { auth } from '@/app/api/auth/[...nextauth]/route'

const session = await auth()
```

### Route Protection
```typescript
// See: 06-MIDDLEWARE.md → Basic Middleware
export { default } from 'next-auth/middleware'

export const config = { matcher: ['/dashboard/:path*'] }
```

### Custom Callbacks
```typescript
// See: 05-CALLBACKS.md → jwt callback
callbacks: {
  async jwt({ token, user }) {
    if (user) token.role = user.role
    return token
  },
}
```

### Prisma Integration
```typescript
// See: 10-INTEGRATIONS.md → Prisma Integration
import { PrismaAdapter } from '@auth/prisma-adapter'

export const authOptions = {
  adapter: PrismaAdapter(prisma),
}
```

---

## Quick Links

### External Resources
- [NextAuth.js Official Docs](https://next-auth.js.org/)
- [GitHub Repository](https://github.com/nextauthjs/next-auth)
- [Provider Directory](https://next-auth.js.org/providers/)
- [Adapter Directory](https://authjs.dev/reference/adapters)

### Common Workflows
1. **OAuth setup** → 02-PROVIDERS.md → 06-MIDDLEWARE.md
2. **Database auth** → 10-INTEGRATIONS.md → 04-JWT-VS-DATABASE.md
3. **Production deployment** → 09-SECURITY.md → 11-CONFIG-OPERATIONS.md
4. **tRPC integration** → 10-INTEGRATIONS.md → 05-CALLBACKS.md

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1
