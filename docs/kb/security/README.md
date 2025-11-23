---
id: security-readme
topic: security
file_role: overview
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: []
related_topics: ['security']
embedding_keywords: [security, overview, introduction, getting-started]
last_reviewed: 2025-11-13
---

# Security & Best Practices Knowledge Base

Welcome to the security knowledge base covering authentication, authorization, input validation, rate limiting, and security best practices for this application.

## 📚 Documentation Structure (9-Part Series)

### **Quick Navigation**
- **[INDEX.md](./INDEX.md)** - Complete index with learning paths
- **[QUICK-REFERENCE.md](./QUICK-REFERENCE.md)** - Security cheat sheet
- **[FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md)** - this project security patterns
- **<!-- <!-- [SECURITY-HANDBOOK.md](./SECURITY-HANDBOOK.md) (file not created) --> (File not yet created) -->** - Comprehensive reference

### **Core Topics (9 Files)**

| # | Topic | File | Focus |
|---|-------|------|-------|
| 1 | **Fundamentals** | <!-- <!-- [01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md) (file not created) --> (File not yet created) --> | Security basics, OWASP Top 10 |
| 2 | **Authentication** | <!-- <!-- [02-AUTHENTICATION.md](./02-AUTHENTICATION.md) (file not created) --> (File not yet created) --> | NextAuth.js, sessions |
| 3 | **Authorization** | <!-- <!-- [03-AUTHORIZATION.md](./03-AUTHORIZATION.md) (file not created) --> (File not yet created) --> | RBAC, permissions |
| 4 | **Input Validation** | <!-- <!-- [04-INPUT-VALIDATION.md](./04-INPUT-VALIDATION.md) (file not created) --> (File not yet created) --> | Zod, sanitization |
| 5 | **Rate Limiting** | <!-- <!-- [05-RATE-LIMITING.md](./05-RATE-LIMITING.md) (file not created) --> (File not yet created) --> | API protection |
| 6 | **Data Protection** | <!-- <!-- [06-DATA-PROTECTION.md](./06-DATA-PROTECTION.md) (file not created) --> (File not yet created) --> | Encryption, secrets |
| 7 | **XSS & CSRF** | <!-- <!-- [07-XSS-CSRF.md](./07-XSS-CSRF.md) (file not created) --> (File not yet created) --> | Attack prevention |
| 8 | **SQL Injection** | <!-- <!-- [08-SQL-INJECTION.md](./08-SQL-INJECTION.md) (file not created) --> (File not yet created) --> | Query safety |
| 9 | **Best Practices** | <!-- <!-- [09-BEST-PRACTICES.md](./09-BEST-PRACTICES.md) (file not created) --> (File not yet created) --> | Security checklist |

---

## 🛡️ Security Checklist (this project)

### Critical Security Controls
- [x] Input validation with Zod on all API routes
- [x] SQL injection prevention (Prisma ORM)
- [ ] Rate limiting on API endpoints
- [ ] CSRF protection (Next.js built-in)
- [ ] XSS protection with CSP headers
- [ ] Authentication required for protected routes
- [ ] Authorization checks on data access
- [ ] Secrets in environment variables
- [ ] HTTPS in production
- [ ] Error messages don't leak sensitive data
- [ ] Audit logging for critical actions
- [ ] Regular dependency updates

---

## 🎯 OWASP Top 10 (2021) Protection

### 1. Broken Access Control
```typescript
// ✅ Good - Check authorization
export async function GET(req: Request) {
 const session = await getSession(req);
 if (!session) {
 return new Response('Unauthorized', { status: 401 });
 }

 const data = await prisma.session.findUnique({
 where: {
 id: params.id,
 organizationId: session.user.organizationId, // Check ownership
 },
 });

 if (!data) {
 return new Response('Not found', { status: 404 });
 }

 return Response.json(data);
}
```

### 2. Cryptographic Failures
```typescript
// ✅ Good - Never commit secrets
//.env.local (in.gitignore)
DATABASE_URL="file:./this project.db"
ANTHROPIC_API_KEY="sk-ant-..."
NEXTAUTH_SECRET="random-secret"

// ❌ Bad - Hardcoded secrets
const apiKey = "sk-ant-hardcoded-key"; // Never do this!
```

### 3. Injection
```typescript
// ✅ Good - Prisma prevents SQL injection
const users = await prisma.user.findMany({
 where: { email: userInput }, // Safe, parameterized
});

// ❌ Bad - Raw SQL with user input
const users = await prisma.$queryRaw`
 SELECT * FROM users WHERE email = '${userInput}'
`; // SQL injection vulnerability!
```

### 4. Insecure Design
```typescript
// ✅ Good - Secure by default
interface SessionConfig {
 maxDuration: number; // 15 minutes
 requireAuth: boolean; // true
 allowAnonymous: boolean; // false
}

// Session automatically expires
// User must be authenticated
```

### 5. Security Misconfiguration
```typescript
// ✅ Good - Secure headers
// next.config.js
const securityHeaders = [
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
 key: 'Content-Security-Policy',
 value: "default-src 'self'",
 },
];
```

### 6. Vulnerable Components
```bash
# ✅ Good - Regular updates
npm audit
npm audit fix
npm update

# Check for vulnerabilities
npx snyk test
```

### 7. Authentication Failures
```typescript
// ✅ Good - Secure authentication
import NextAuth from 'next-auth';
import { PrismaAdapter } from '@auth/prisma-adapter';

export const authOptions = {
 adapter: PrismaAdapter(prisma),
 session: {
 strategy: 'jwt',
 maxAge: 30 * 24 * 60 * 60, // 30 days
 },
 callbacks: {
 async session({ session, token }) {
 session.user.id = token.sub;
 return session;
 },
 },
};
```

### 8. Software and Data Integrity
```typescript
// ✅ Good - Validate all inputs
import { z } from 'zod';

const CreateSessionSchema = z.object({
 organizationId: z.string.cuid,
 metadata: z.record(z.unknown).optional,
});

export async function POST(req: Request) {
 const body = await req.json;

 // Validate before using
 const validated = CreateSessionSchema.parse(body);

 const session = await prisma.session.create({
 data: validated,
 });

 return Response.json(session);
}
```

### 9. Logging Failures
```typescript
// ✅ Good - Comprehensive logging
import { logger } from '@/lib/logging';

export async function POST(req: Request) {
 try {
 //... operation
 logger.info('Session created', { sessionId, userId });
 } catch (error) {
 logger.error('Session creation failed', {
 error: error.message,
 userId,
 timestamp: new Date.toISOString,
 });
 throw error;
 }
}
```

### 10. Server-Side Request Forgery (SSRF)
```typescript
// ✅ Good - Validate URLs
import { z } from 'zod';

const UrlSchema = z.string.url.refine(
 (url) => {
 const parsed = new URL(url);
 // Only allow specific domains
 return ['api.anthropic.com', 'vercel.ai'].includes(parsed.hostname);
 },
 { message: 'URL not allowed' }
);

// ❌ Bad - Arbitrary URLs
async function fetchData(url: string) {
 return await fetch(url); // Can fetch internal resources!
}
```

---

## 📋 Common Security Patterns

### Input Validation with Zod
```typescript
import { z } from 'zod';

// Define schema
const UserInputSchema = z.object({
 email: z.string.email.max(255),
 name: z.string.min(1).max(100),
 age: z.number.int.min(0).max(150),
});

// Validate
export async function POST(req: Request) {
 const body = await req.json;

 try {
 const validated = UserInputSchema.parse(body);
 // Use validated data
 } catch (error) {
 return new Response('Invalid input', { status: 400 });
 }
}
```

### Rate Limiting
```typescript
import { Ratelimit } from '@upstash/ratelimit';
import { Redis } from '@upstash/redis';

const ratelimit = new Ratelimit({
 redis: Redis.fromEnv,
 limiter: Ratelimit.slidingWindow(10, '1 m'), // 10 requests per minute
});

export async function POST(req: Request) {
 const ip = req.headers.get('x-forwarded-for') ?? 'unknown';
 const { success, limit, remaining } = await ratelimit.limit(ip);

 if (!success) {
 return new Response('Rate limit exceeded', {
 status: 429,
 headers: {
 'X-RateLimit-Limit': limit.toString,
 'X-RateLimit-Remaining': remaining.toString,
 },
 });
 }

 // Process request
}
```

### Secure Error Handling
```typescript
// ✅ Good - Safe error messages
export async function POST(req: Request) {
 try {
 //... operation
 } catch (error) {
 logger.error('Operation failed', { error, userId });

 // Don't leak internal details
 return new Response('An error occurred', { status: 500 });
 }
}

// ❌ Bad - Leaks details
export async function POST(req: Request) {
 try {
 //... operation
 } catch (error) {
 // Exposes internal paths, database structure, etc.
 return new Response(error.message, { status: 500 });
 }
}
```

---

## ⚠️ Common Vulnerabilities

### XSS (Cross-Site Scripting)
```tsx
// ✅ Good - React escapes by default
function UserProfile({ name }: Props) {
 return <h1>{name}</h1>; // Safe, automatically escaped
}

// ❌ Bad - dangerouslySetInnerHTML
function UserProfile({ bio }: Props) {
 return <div dangerouslySetInnerHTML={{ __html: bio }} />;
 // Can execute JavaScript if bio contains <script>
}
```

### CSRF (Cross-Site Request Forgery)
```typescript
// ✅ Good - Next.js has built-in CSRF protection
// For API routes, use proper authentication

// ❌ Bad - No auth on state-changing operations
export async function POST(req: Request) {
 // Anyone can call this!
 await prisma.user.delete({ where: { id } });
}
```

### Path Traversal
```typescript
// ✅ Good - Validate paths
import path from 'path';

function getFile(filename: string) {
 const safePath = path.basename(filename); // Remove../
 return path.join(UPLOAD_DIR, safePath);
}

// ❌ Bad - No validation
function getFile(filename: string) {
 return path.join(UPLOAD_DIR, filename);
 // Can access../../../etc/passwd
}
```

---

## 📚 Files in This Directory

```
docs/kb/security/
├── README.md # This file
├── INDEX.md # Complete index
├── QUICK-REFERENCE.md # Security cheat sheet
├── SECURITY-HANDBOOK.md # Full reference
├── FRAMEWORK-INTEGRATION-PATTERNS.md # this project security
├── 01-FUNDAMENTALS.md # Security basics
├── 02-AUTHENTICATION.md # Auth patterns
├── 03-AUTHORIZATION.md # Access control
├── 04-INPUT-VALIDATION.md # Validation
├── 05-RATE-LIMITING.md # Rate limiting
├── 06-DATA-PROTECTION.md # Encryption
├── 07-XSS-CSRF.md # Attack prevention
├── 08-SQL-INJECTION.md # Query safety
└── 09-BEST-PRACTICES.md # Best practices
```

---

## 🎓 External Resources

- **OWASP Top 10**: https://owasp.org/Top10/
- **NextAuth.js**: https://next-auth.js.org/
- **Zod Validation**: https://zod.dev/
- **Security Headers**: https://securityheaders.com/

---

**Last Updated**: November 9, 2025
**Status**: Production-Ready

Stay secure! 🔒
