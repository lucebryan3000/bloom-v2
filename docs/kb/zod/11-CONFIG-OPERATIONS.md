---
id: zod-11-config-operations
topic: zod
file_role: practical
profile: full
difficulty_level: advanced
kb_version: 3.1
prerequisites: [zod-fundamentals, zod-validation]
related_topics: [production, operations, configuration, monitoring]
embedding_keywords: [zod, production, operations, configuration, environment, validation]
last_reviewed: 2025-11-16
---

# Zod - Configuration and Operations

## Purpose

Production-ready patterns for Zod including environment configuration, runtime validation, monitoring, error tracking, and operational best practices.

## Table of Contents

1. [Environment Configuration](#environment-configuration)
2. [Runtime Validation](#runtime-validation)
3. [Error Monitoring](#error-monitoring)
4. [Performance Monitoring](#performance-monitoring)
5. [Production Patterns](#production-patterns)
6. [Troubleshooting](#troubleshooting)

---

## Environment Configuration

### Validate Environment Variables

```typescript
import { z } from 'zod'

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']),
  PORT: z.coerce.number().default(3000),
  DATABASE_URL: z.string().url(),
  REDIS_URL: z.string().url().optional(),
  API_KEY: z.string().min(1),
  LOG_LEVEL: z.enum(['debug', 'info', 'warn', 'error']).default('info'),
  MAX_REQUEST_SIZE: z.coerce.number().default(1048576), // 1MB
})

type Env = z.infer<typeof envSchema>

// Validate on startup
export const env: Env = envSchema.parse(process.env)

// Usage
console.log(`Server running on port ${env.PORT}`)
```

### Typed Config Object

```typescript
const configSchema = z.object({
  server: z.object({
    port: z.number().default(3000),
    host: z.string().default('localhost'),
    cors: z.object({
      origin: z.string().or(z.array(z.string())),
      credentials: z.boolean().default(true),
    }),
  }),
  database: z.object({
    url: z.string().url(),
    pool: z.object({
      min: z.number().default(2),
      max: z.number().default(10),
    }),
  }),
  features: z.object({
    enableCache: z.boolean().default(true),
    enableMetrics: z.boolean().default(true),
  }),
})

export const config = configSchema.parse({
  server: {
    port: parseInt(process.env.PORT || '3000'),
    host: process.env.HOST || 'localhost',
    cors: {
      origin: process.env.CORS_ORIGIN || '*',
    },
  },
  database: {
    url: process.env.DATABASE_URL!,
    pool: {
      min: 2,
      max: 10,
    },
  },
  features: {
    enableCache: process.env.ENABLE_CACHE === 'true',
    enableMetrics: process.env.ENABLE_METRICS !== 'false',
  },
})
```

---

## Runtime Validation

### API Request Validation

```typescript
// Create validation middleware
function validateRequest<T extends z.ZodType>(schema: T) {
  return (req: Request, res: Response, next: NextFunction) => {
    const result = schema.safeParse(req.body)

    if (!result.success) {
      logger.warn('Request validation failed', {
        endpoint: req.path,
        errors: result.error.flatten(),
      })

      return res.status(400).json({
        error: 'Validation failed',
        details: result.error.flatten().fieldErrors,
      })
    }

    req.body = result.data
    next()
  }
}

// Usage
app.post('/users', validateRequest(createUserSchema), createUserHandler)
```

### Database Model Validation

```typescript
// Validate data before database operations
async function createUser(data: unknown) {
  const validated = createUserSchema.parse(data)

  const user = await db.user.create({
    data: validated,
  })

  // Validate database response
  return userSchema.parse(user)
}

// Validate query results
async function getUsers() {
  const users = await db.user.findMany()

  // Ensure all results match schema
  return z.array(userSchema).parse(users)
}
```

---

## Error Monitoring

### Centralized Error Logging

```typescript
import * as Sentry from '@sentry/node'

function logValidationError(error: z.ZodError, context: any) {
  const formattedError = {
    type: 'validation_error',
    issues: error.issues.map(issue => ({
      path: issue.path.join('.'),
      message: issue.message,
      code: issue.code,
    })),
    context,
  }

  // Log to monitoring service
  Sentry.captureException(error, {
    extra: formattedError,
  })

  // Log locally
  console.error('Validation error:', formattedError)

  return formattedError
}

// Usage
const result = schema.safeParse(data)
if (!result.success) {
  logValidationError(result.error, {
    endpoint: '/api/users',
    userId: currentUser.id,
    timestamp: new Date().toISOString(),
  })
}
```

### Error Categorization

```typescript
class ValidationErrorTracker {
  private errors: Map<string, number> = new Map()

  track(error: z.ZodError, endpoint: string) {
    error.issues.forEach(issue => {
      const key = `${endpoint}:${issue.path.join('.')}:${issue.code}`
      this.errors.set(key, (this.errors.get(key) || 0) + 1)
    })
  }

  getReport() {
    return Array.from(this.errors.entries())
      .map(([key, count]) => ({ key, count }))
      .sort((a, b) => b.count - a.count)
  }

  reset() {
    this.errors.clear()
  }
}

const errorTracker = new ValidationErrorTracker()

// Track errors
const result = schema.safeParse(data)
if (!result.success) {
  errorTracker.track(result.error, req.path)
}

// Get report periodically
setInterval(() => {
  const report = errorTracker.getReport()
  console.log('Validation error report:', report)
  errorTracker.reset()
}, 60000) // Every minute
```

---

## Performance Monitoring

### Validation Metrics

```typescript
class ValidationMetrics {
  private metrics = {
    total: 0,
    success: 0,
    failure: 0,
    totalTime: 0,
  }

  async measure<T>(schema: z.ZodType<T>, data: unknown) {
    const start = performance.now()
    const result = schema.safeParse(data)
    const duration = performance.now() - start

    this.metrics.total++
    this.metrics.totalTime += duration

    if (result.success) {
      this.metrics.success++
    } else {
      this.metrics.failure++
    }

    if (duration > 10) {
      console.warn(`Slow validation: ${duration.toFixed(2)}ms`)
    }

    return result
  }

  getMetrics() {
    return {
      ...this.metrics,
      avgTime: this.metrics.totalTime / this.metrics.total,
      successRate: this.metrics.success / this.metrics.total,
    }
  }
}

const metrics = new ValidationMetrics()

// Usage
const result = await metrics.measure(userSchema, userData)
```

### Health Checks

```typescript
// Validate critical services
async function healthCheck() {
  const checks = {
    database: await checkDatabase(),
    cache: await checkCache(),
    api: await checkAPI(),
  }

  const healthSchema = z.object({
    database: z.literal('healthy'),
    cache: z.literal('healthy'),
    api: z.literal('healthy'),
  })

  try {
    healthSchema.parse(checks)
    return { status: 'healthy', checks }
  } catch (error) {
    return { status: 'unhealthy', checks }
  }
}

// Endpoint
app.get('/health', async (req, res) => {
  const health = await healthCheck()
  const statusCode = health.status === 'healthy' ? 200 : 503
  res.status(statusCode).json(health)
})
```

---

## Production Patterns

### Schema Versioning

```typescript
const userSchemaV1 = z.object({
  name: z.string(),
  email: z.string().email(),
})

const userSchemaV2 = z.object({
  firstName: z.string(),
  lastName: z.string(),
  email: z.string().email(),
})

function getSchema(version: string) {
  switch (version) {
    case 'v1':
      return userSchemaV1
    case 'v2':
      return userSchemaV2
    default:
      throw new Error(`Unknown schema version: ${version}`)
  }
}

// API endpoint
app.post('/users', (req, res) => {
  const version = req.headers['api-version'] || 'v2'
  const schema = getSchema(version)

  const result = schema.safeParse(req.body)
  // ...
})
```

### Graceful Degradation

```typescript
function parseWithFallback<T>(
  schema: z.ZodType<T>,
  data: unknown,
  fallback: T
): T {
  const result = schema.safeParse(data)

  if (result.success) {
    return result.data
  }

  logger.error('Validation failed, using fallback', {
    error: result.error.format(),
  })

  return fallback
}

// Usage
const config = parseWithFallback(
  configSchema,
  loadedConfig,
  defaultConfig
)
```

### Safe Partial Updates

```typescript
const updateUserSchema = z.object({
  name: z.string().optional(),
  email: z.string().email().optional(),
}).refine(
  (data) => Object.keys(data).length > 0,
  "At least one field must be provided"
)

async function updateUser(id: string, updates: unknown) {
  const validated = updateUserSchema.parse(updates)

  return db.user.update({
    where: { id },
    data: validated,
  })
}
```

---

## Troubleshooting

### Common Issues

#### Issue 1: Unexpected undefined

```typescript
// ❌ Problem: Missing data treated as undefined
const schema = z.object({
  name: z.string(),
  age: z.number(),
})

schema.parse({ name: "Alice" })
// Error: age is required

// ✅ Solution: Make optional or provide default
const schema = z.object({
  name: z.string(),
  age: z.number().optional(),
})
```

#### Issue 2: Coercion Issues

```typescript
// ❌ Problem: String numbers not converted
const schema = z.object({ age: z.number() })
schema.parse({ age: "30" })
// Error: Expected number, received string

// ✅ Solution: Use coercion
const schema = z.object({ age: z.coerce.number() })
schema.parse({ age: "30" }) // Works!
```

#### Issue 3: Date Validation

```typescript
// ❌ Problem: Date strings not recognized
const schema = z.object({ date: z.date() })
schema.parse({ date: "2024-01-01" })
// Error: Expected Date, received string

// ✅ Solution: Coerce or transform
const schema = z.object({
  date: z.coerce.date()
})
```

### Debug Mode

```typescript
function createDebugSchema<T extends z.ZodTypeAny>(schema: T, label: string) {
  return schema.transform((data) => {
    console.log(`[${label}] Validated:`, data)
    return data
  })
}

const debugUserSchema = createDebugSchema(userSchema, 'User')
```

---

## Best Practices

### 1. Validate Early

```typescript
// ✅ Validate at API boundary
export async function POST(request: Request) {
  const result = schema.safeParse(await request.json())
  if (!result.success) return errorResponse(result.error)
  // ...
}
```

### 2. Monitor Validation Failures

```typescript
// ✅ Track and alert on validation failures
if (!result.success) {
  metrics.increment('validation.failure')
  logger.error('Validation failed', result.error)
}
```

### 3. Version Your Schemas

```typescript
// ✅ Support multiple API versions
const schemas = {
  v1: userSchemaV1,
  v2: userSchemaV2,
}
```

---

## AI Pair Programming Notes

**When to load this file:**
- Setting up production validation
- Configuring environment variables
- Implementing error monitoring
- Troubleshooting validation issues

**Typical questions:**
- "How do I validate environment variables?"
- "How do I monitor validation errors?"
- "How do I handle validation in production?"
- "How do I version my schemas?"

**Next steps:**
- [03-VALIDATION.md](./03-VALIDATION.md) - Validation basics
- [05-ERROR-HANDLING.md](./05-ERROR-HANDLING.md) - Error handling
- [08-PERFORMANCE.md](./08-PERFORMANCE.md) - Performance optimization

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1
