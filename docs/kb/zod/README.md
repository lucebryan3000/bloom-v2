---
id: zod-readme
topic: zod
file_role: overview
profile: full
difficulty_level: beginner
kb_version: 3.1
prerequisites: [typescript-basics]
related_topics: [typescript, validation, type-safety]
embedding_keywords: [zod, validation, typescript, schema, type-safety, runtime-validation]
last_reviewed: 2025-11-16
---

# Zod Knowledge Base

TypeScript-first schema validation with static type inference.

## What is Zod?

Zod is a TypeScript-first schema declaration and validation library. It provides:
- **Zero dependencies** - Lightweight and fast
- **Type inference** - TypeScript types derived from schemas
- **Runtime validation** - Catch errors before they reach production
- **Developer experience** - Intuitive API with excellent TypeScript support
- **Immutable** - Schemas are immutable, transformations create new schemas
- **Composable** - Build complex schemas from simple primitives

```typescript
import { z } from 'zod'

// Define schema
const userSchema = z.object({
  name: z.string().min(1),
  email: z.string().email(),
  age: z.number().int().positive(),
})

// Infer TypeScript type
type User = z.infer<typeof userSchema>
// { name: string; email: string; age: number }

// Validate data
const result = userSchema.safeParse(data)
if (result.success) {
  console.log(result.data) // Type-safe!
}
```

## Why Zod?

### Comparison with Other Validation Libraries

| Feature | Zod | Yup | Joi | io-ts | class-validator |
|---------|-----|-----|-----|-------|-----------------|
| **Type inference** | ✅ Excellent | ⚠️ Limited | ❌ No | ✅ Good | ⚠️ Decorator-based |
| **Bundle size** | 🟢 8kb | 🟡 20kb | 🔴 145kb | 🟢 9kb | 🟡 18kb |
| **TypeScript-first** | ✅ Yes | ❌ No | ❌ No | ✅ Yes | ⚠️ Partial |
| **Zero dependencies** | ✅ Yes | ❌ No | ❌ No | ✅ Yes | ❌ No |
| **Runtime validation** | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |
| **Transform data** | ✅ Built-in | ✅ Built-in | ✅ Built-in | ⚠️ Manual | ❌ No |
| **Async validation** | ✅ Yes | ✅ Yes | ✅ Yes | ❌ No | ✅ Yes |
| **Error messages** | ✅ Customizable | ✅ Good | ✅ Good | ⚠️ Basic | ✅ Good |
| **Framework agnostic** | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes | ❌ NestJS-focused |
| **Learning curve** | 🟢 Low | 🟢 Low | 🟡 Medium | 🔴 High | 🟡 Medium |

**Zod excels at:**
- TypeScript integration and type inference
- Small bundle size with zero dependencies
- Developer experience and intuitive API
- Framework-agnostic design
- Transformation and preprocessing

**Consider alternatives when:**
- **Yup**: Existing codebase uses it (migration effort)
- **Joi**: Node.js-only environment (Joi has more Node features)
- **io-ts**: Functional programming paradigm (fp-ts ecosystem)
- **class-validator**: NestJS or class-based architecture

## Documentation Structure

### Core Files

- **[INDEX.md](./INDEX.md)** - Complete index with topic navigation and problem-based quick find
- **[QUICK-REFERENCE.md](./QUICK-REFERENCE.md)** - One-page cheat sheet with all syntax patterns
- **[FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md)** - React Hook Form, tRPC, Next.js, Prisma integrations

### Core Topics (11 Files)

| # | File | Topic | What You'll Learn |
|---|------|-------|-------------------|
| 01 | [01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md) | Core concepts and setup | Installation, basic schemas, parse vs safeParse |
| 02 | [02-SCHEMA-DEFINITION.md](./02-SCHEMA-DEFINITION.md) | Schema building blocks | Primitives, objects, arrays, unions, intersections |
| 03 | [03-VALIDATION.md](./03-VALIDATION.md) | Validation patterns | Validation methods, error handling, custom messages |
| 04 | [04-TYPE-INFERENCE.md](./04-TYPE-INFERENCE.md) | TypeScript integration | z.infer, input/output types, branded types |
| 05 | [05-ERROR-HANDLING.md](./05-ERROR-HANDLING.md) | Error management | ZodError structure, formatting, internationalization |
| 06 | [06-TRANSFORMATIONS.md](./06-TRANSFORMATIONS.md) | Data transformation | transform(), preprocess(), pipe(), coercion |
| 07 | [07-ADVANCED-SCHEMAS.md](./07-ADVANCED-SCHEMAS.md) | Complex patterns | Recursive types, discriminated unions, generics |
| 08 | [08-PERFORMANCE.md](./08-PERFORMANCE.md) | Optimization | Performance tuning, caching, benchmarking |
| 09 | [09-TESTING.md](./09-TESTING.md) | Testing strategies | Unit tests, integration tests, property-based testing |
| 10 | [10-INTEGRATIONS.md](./10-INTEGRATIONS.md) | Framework integration | React Hook Form, tRPC, Next.js, Prisma, Express |
| 11 | [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) | Production patterns | Environment config, monitoring, troubleshooting |

## Learning Paths

### 🟢 Beginner Path (Start Here)

**Goal**: Learn core Zod concepts and basic validation

1. **[01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md)** - Core concepts (30 min)
   - Installation and setup
   - Basic schema types
   - parse() vs safeParse()

2. **[02-SCHEMA-DEFINITION.md](./02-SCHEMA-DEFINITION.md)** - Building schemas (45 min)
   - Primitive types (string, number, boolean, date)
   - Object and array schemas
   - Optional and nullable fields

3. **[03-VALIDATION.md](./03-VALIDATION.md)** - Validation basics (30 min)
   - Built-in validators (email, url, uuid, regex)
   - Custom error messages
   - Basic refinements

4. **[04-TYPE-INFERENCE.md](./04-TYPE-INFERENCE.md)** - TypeScript types (20 min)
   - z.infer for type extraction
   - Single source of truth pattern
   - Type-safe data handling

**Beginner Projects**:
- Form validation in React
- API request validation
- Environment variable validation

### 🟡 Intermediate Path

**Goal**: Master transformations, integrations, and production patterns

**Prerequisites**: Complete Beginner Path

1. **[05-ERROR-HANDLING.md](./05-ERROR-HANDLING.md)** - Error management (30 min)
   - ZodError structure and issue codes
   - format() and flatten() methods
   - Custom error maps

2. **[06-TRANSFORMATIONS.md](./06-TRANSFORMATIONS.md)** - Data transformation (45 min)
   - transform() for data manipulation
   - preprocess() for pre-validation
   - pipe() for chaining schemas

3. **[10-INTEGRATIONS.md](./10-INTEGRATIONS.md)** - Framework integration (60 min)
   - React Hook Form with zodResolver
   - tRPC input/output validation
   - Next.js API routes

4. **[09-TESTING.md](./09-TESTING.md)** - Testing schemas (30 min)
   - Unit testing schemas
   - Integration testing
   - Test factories

**Intermediate Projects**:
- Full-stack type-safe API with tRPC
- Form library integration
- Database model validation

### 🔴 Advanced Path

**Goal**: Complex schemas, performance optimization, production operations

**Prerequisites**: Complete Intermediate Path

1. **[07-ADVANCED-SCHEMAS.md](./07-ADVANCED-SCHEMAS.md)** - Complex patterns (60 min)
   - Recursive schemas with z.lazy()
   - Discriminated unions
   - Generic schema factories
   - Builder pattern

2. **[08-PERFORMANCE.md](./08-PERFORMANCE.md)** - Optimization (45 min)
   - Performance profiling
   - Caching strategies
   - Schema optimization
   - Lazy loading

3. **[11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md)** - Production (45 min)
   - Environment configuration
   - Error monitoring
   - Schema versioning
   - Graceful degradation

4. **[FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md)** - Advanced integrations (30 min)
   - Complex integration patterns
   - Performance optimization
   - Production best practices

**Advanced Projects**:
- Enterprise-scale API validation
- Multi-version schema system
- Custom validation library
- Performance-critical validation

## Quick Start

### Installation

```bash
npm install zod
# or
yarn add zod
# or
pnpm add zod
```

### Basic Usage

```typescript
import { z } from 'zod'

// 1. Create schema
const userSchema = z.object({
  username: z.string().min(3).max(20),
  email: z.string().email(),
  age: z.number().int().positive().optional(),
  role: z.enum(['admin', 'user', 'guest']),
})

// 2. Infer TypeScript type
type User = z.infer<typeof userSchema>

// 3. Validate data
const result = userSchema.safeParse({
  username: 'alice',
  email: 'alice@example.com',
  role: 'user',
})

if (result.success) {
  console.log(result.data) // Typed as User
} else {
  console.error(result.error.format())
}
```

### Form Validation Example

```typescript
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'

const formSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(8, 'Password must be at least 8 characters'),
})

function LoginForm() {
  const { register, handleSubmit, formState: { errors } } = useForm({
    resolver: zodResolver(formSchema),
  })

  return (
    <form onSubmit={handleSubmit(console.log)}>
      <input {...register('email')} />
      {errors.email && <span>{errors.email.message}</span>}

      <input type="password" {...register('password')} />
      {errors.password && <span>{errors.password.message}</span>}

      <button type="submit">Login</button>
    </form>
  )
}
```

## Key Features

### 1. Type Inference

```typescript
const schema = z.object({ name: z.string(), age: z.number() })
type Data = z.infer<typeof schema>
// { name: string; age: number }
```

### 2. Composable Schemas

```typescript
const address = z.object({ street: z.string(), city: z.string() })
const user = z.object({ name: z.string(), address })
```

### 3. Transformations

```typescript
const dateSchema = z.string().transform((str) => new Date(str))
const trimmed = z.string().transform((s) => s.trim())
```

### 4. Custom Validation

```typescript
const passwordSchema = z.string()
  .min(8)
  .refine((pwd) => /[A-Z]/.test(pwd), 'Must contain uppercase')
  .refine((pwd) => /[0-9]/.test(pwd), 'Must contain number')
```

### 5. Async Validation

```typescript
const emailSchema = z.string().email().refine(async (email) => {
  const exists = await checkEmailExists(email)
  return !exists
}, 'Email already taken')
```

## Use Cases

### ✅ Ideal For

- **API validation**: Validate request/response data
- **Form validation**: Type-safe form handling
- **Configuration**: Environment variables, app config
- **Database models**: Validate data before persistence
- **Type-safe APIs**: tRPC, GraphQL resolvers
- **Data transformation**: Parse and transform external data
- **Runtime type checking**: Validate third-party data

### ⚠️ Consider Alternatives When

- **Simple projects**: Plain TypeScript might suffice
- **Schema evolution**: Frequent breaking changes (consider versioning)
- **Legacy codebase**: Migration effort may be high
- **Extreme performance**: Ultra-high-frequency validation (consider simpler validators)
- **Node-only features**: Joi might be better for Node-specific features

## Common Patterns

### API Validation

```typescript
// app/api/users/route.ts
import { z } from 'zod'

const createUserSchema = z.object({
  name: z.string().min(1),
  email: z.string().email(),
})

export async function POST(request: Request) {
  const body = await request.json()
  const result = createUserSchema.safeParse(body)

  if (!result.success) {
    return Response.json({ error: result.error.flatten() }, { status: 400 })
  }

  // result.data is type-safe
  const user = await db.user.create({ data: result.data })
  return Response.json({ user })
}
```

### Environment Variables

```typescript
import { z } from 'zod'

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']),
  DATABASE_URL: z.string().url(),
  API_KEY: z.string().min(1),
  PORT: z.coerce.number().default(3000),
})

export const env = envSchema.parse(process.env)
```

### tRPC Integration

```typescript
import { z } from 'zod'
import { initTRPC } from '@trpc/server'

const t = initTRPC.create()

export const appRouter = t.router({
  createUser: t.procedure
    .input(z.object({ name: z.string(), email: z.string().email() }))
    .mutation(async ({ input }) => {
      // input is fully typed and validated
      return await db.user.create({ data: input })
    }),
})
```

## Resources

### Official Documentation
- [Zod GitHub](https://github.com/colinhacks/zod)
- [Official Documentation](https://zod.dev)
- [API Reference](https://zod.dev/api)

### Integration Guides
- [React Hook Form](https://react-hook-form.com/get-started#SchemaValidation)
- [tRPC](https://trpc.io/docs/server/validators)
- [Prisma + Zod](https://github.com/CarterGrimmeisen/zod-prisma)

### Community
- [GitHub Discussions](https://github.com/colinhacks/zod/discussions)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/zod)

### Related Libraries
- [@hookform/resolvers](https://www.npmjs.com/package/@hookform/resolvers) - Form validation
- [zod-prisma-types](https://www.npmjs.com/package/zod-prisma-types) - Generate Zod schemas from Prisma
- [@zodios/core](https://www.npmjs.com/package/@zodios/core) - Type-safe API client
- [zod-to-json-schema](https://www.npmjs.com/package/zod-to-json-schema) - Convert to JSON Schema
- [zod-to-openapi](https://www.npmjs.com/package/@asteasolutions/zod-to-openapi) - Generate OpenAPI specs

## Migration Guides

### From Yup

```typescript
// Yup
import * as yup from 'yup'
const yupSchema = yup.object({
  name: yup.string().required(),
  age: yup.number().required().positive(),
})

// Zod
import { z } from 'zod'
const zodSchema = z.object({
  name: z.string(),
  age: z.number().positive(),
})
```

### From Joi

```typescript
// Joi
import Joi from 'joi'
const joiSchema = Joi.object({
  email: Joi.string().email().required(),
  password: Joi.string().min(8).required(),
})

// Zod
import { z } from 'zod'
const zodSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
})
```

---

## AI Pair Programming Notes

**When to load this KB:**
- Validating user input or API data
- Building type-safe forms
- Creating type-safe APIs
- Validating environment configuration
- Need runtime type checking

**Common starting points:**
- Beginners: Start with [01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md)
- Form validation: See [10-INTEGRATIONS.md](./10-INTEGRATIONS.md) → React Hook Form
- API validation: See [03-VALIDATION.md](./03-VALIDATION.md) + [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md)
- Complex schemas: See [07-ADVANCED-SCHEMAS.md](./07-ADVANCED-SCHEMAS.md)

**Typical questions:**
- "How do I validate forms with Zod?" → [10-INTEGRATIONS.md](./10-INTEGRATIONS.md)
- "How do I get TypeScript types from schemas?" → [04-TYPE-INFERENCE.md](./04-TYPE-INFERENCE.md)
- "How do I handle validation errors?" → [05-ERROR-HANDLING.md](./05-ERROR-HANDLING.md)
- "How do I transform data?" → [06-TRANSFORMATIONS.md](./06-TRANSFORMATIONS.md)

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1
