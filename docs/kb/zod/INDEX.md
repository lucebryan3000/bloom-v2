---
id: zod-index
topic: zod
file_role: navigation
profile: full
kb_version: 3.1
prerequisites: []
related_topics: [validation, typescript, type-safety]
embedding_keywords: [zod, index, navigation, reference]
last_reviewed: 2025-11-16
---

# Zod - Complete Index

## Quick Navigation by Category

### 📚 Getting Started
- **[README.md](./README.md)** - Complete overview, comparison table, learning paths
- **[01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md)** - Installation, basic schemas, parse vs safeParse
- **[QUICK-REFERENCE.md](./QUICK-REFERENCE.md)** - One-page cheat sheet

### 🎯 Core Concepts (02-03)
- **[02-SCHEMA-DEFINITION.md](./02-SCHEMA-DEFINITION.md)** - Primitives, objects, arrays, unions
- **[03-VALIDATION.md](./03-VALIDATION.md)** - Validation methods, error handling, refinements

### 🛠️ Practical Workflows (04-07)
- **[04-TYPE-INFERENCE.md](./04-TYPE-INFERENCE.md)** - z.infer, input/output types, branded types
- **[05-ERROR-HANDLING.md](./05-ERROR-HANDLING.md)** - ZodError, formatting, internationalization
- **[06-TRANSFORMATIONS.md](./06-TRANSFORMATIONS.md)** - transform(), preprocess(), pipe(), coercion
- **[07-ADVANCED-SCHEMAS.md](./07-ADVANCED-SCHEMAS.md)** - Recursive types, discriminated unions, generics

### 🚀 Advanced Topics (08-10)
- **[08-PERFORMANCE.md](./08-PERFORMANCE.md)** - Optimization, caching, benchmarking
- **[09-TESTING.md](./09-TESTING.md)** - Unit testing, integration testing, test factories
- **[10-INTEGRATIONS.md](./10-INTEGRATIONS.md)** - React Hook Form, tRPC, Next.js, Prisma

### ⚙️ Operations
- **[11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md)** - Environment config, monitoring, production
- **[FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md)** - Framework patterns

---

## File Breakdown by Topic

### Basic Validation
| File | Topics Covered |
|------|----------------|
| [01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md) | Installation, basic types, parse() vs safeParse(), type inference basics |
| [02-SCHEMA-DEFINITION.md](./02-SCHEMA-DEFINITION.md) | Primitives (string, number, boolean, date), objects, arrays, tuples, unions, intersections |
| [03-VALIDATION.md](./03-VALIDATION.md) | Built-in validators, custom error messages, refinements, async validation |

### Type System
| File | Topics Covered |
|------|----------------|
| [04-TYPE-INFERENCE.md](./04-TYPE-INFERENCE.md) | z.infer, input vs output types, branded types, generic factories |
| [05-ERROR-HANDLING.md](./05-ERROR-HANDLING.md) | ZodError structure, format() and flatten(), custom error maps, i18n |

### Data Processing
| File | Topics Covered |
|------|----------------|
| [06-TRANSFORMATIONS.md](./06-TRANSFORMATIONS.md) | transform(), preprocess(), pipe(), coercion (z.coerce), chaining |

### Advanced Patterns
| File | Topics Covered |
|------|----------------|
| [07-ADVANCED-SCHEMAS.md](./07-ADVANCED-SCHEMAS.md) | Recursive schemas (z.lazy), discriminated unions, generic schemas, builder pattern, conditional validation |
| [08-PERFORMANCE.md](./08-PERFORMANCE.md) | Performance profiling, caching strategies, schema optimization, lazy loading |

### Testing & Integration
| File | Topics Covered |
|------|----------------|
| [09-TESTING.md](./09-TESTING.md) | Unit testing, integration testing, testing transformations, test factories |
| [10-INTEGRATIONS.md](./10-INTEGRATIONS.md) | React Hook Form, tRPC, Next.js, Prisma, Express, Fastify |

### Production
| File | Topics Covered |
|------|----------------|
| [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) | Environment validation, runtime validation, error monitoring, health checks, troubleshooting |

---

## Topic-Based Quick Find

### Validation
- **Basic validation**: [01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md), [03-VALIDATION.md](./03-VALIDATION.md)
- **String validation**: [02-SCHEMA-DEFINITION.md](./02-SCHEMA-DEFINITION.md) → String methods
- **Email/URL/UUID**: [03-VALIDATION.md](./03-VALIDATION.md) → Built-in validators
- **Custom validation**: [03-VALIDATION.md](./03-VALIDATION.md) → Refinements
- **Async validation**: [03-VALIDATION.md](./03-VALIDATION.md) → Async refinements
- **Conditional validation**: [07-ADVANCED-SCHEMAS.md](./07-ADVANCED-SCHEMAS.md) → Conditional schemas

### Types & TypeScript
- **Type inference**: [04-TYPE-INFERENCE.md](./04-TYPE-INFERENCE.md) → z.infer
- **Input vs output types**: [04-TYPE-INFERENCE.md](./04-TYPE-INFERENCE.md) → Input/Output types
- **Branded types**: [04-TYPE-INFERENCE.md](./04-TYPE-INFERENCE.md) → Branded types
- **Generic types**: [07-ADVANCED-SCHEMAS.md](./07-ADVANCED-SCHEMAS.md) → Generic schemas
- **Recursive types**: [07-ADVANCED-SCHEMAS.md](./07-ADVANCED-SCHEMAS.md) → Recursive schemas

### Schema Building
- **Primitives**: [02-SCHEMA-DEFINITION.md](./02-SCHEMA-DEFINITION.md) → Primitive types
- **Objects**: [02-SCHEMA-DEFINITION.md](./02-SCHEMA-DEFINITION.md) → Object schemas
- **Arrays**: [02-SCHEMA-DEFINITION.md](./02-SCHEMA-DEFINITION.md) → Array operations
- **Unions**: [02-SCHEMA-DEFINITION.md](./02-SCHEMA-DEFINITION.md) → Unions
- **Discriminated unions**: [07-ADVANCED-SCHEMAS.md](./07-ADVANCED-SCHEMAS.md) → Discriminated unions
- **Schema composition**: [07-ADVANCED-SCHEMAS.md](./07-ADVANCED-SCHEMAS.md) → Schema composition

### Error Handling
- **Error structure**: [05-ERROR-HANDLING.md](./05-ERROR-HANDLING.md) → ZodError structure
- **Error formatting**: [05-ERROR-HANDLING.md](./05-ERROR-HANDLING.md) → format() and flatten()
- **Custom messages**: [05-ERROR-HANDLING.md](./05-ERROR-HANDLING.md) → Custom error messages
- **Error maps**: [05-ERROR-HANDLING.md](./05-ERROR-HANDLING.md) → Error maps
- **i18n**: [05-ERROR-HANDLING.md](./05-ERROR-HANDLING.md) → Internationalization

### Transformations
- **Data transformation**: [06-TRANSFORMATIONS.md](./06-TRANSFORMATIONS.md) → transform()
- **Preprocessing**: [06-TRANSFORMATIONS.md](./06-TRANSFORMATIONS.md) → preprocess()
- **Chaining**: [06-TRANSFORMATIONS.md](./06-TRANSFORMATIONS.md) → pipe()
- **Coercion**: [06-TRANSFORMATIONS.md](./06-TRANSFORMATIONS.md) → z.coerce

### Framework Integration
- **React Hook Form**: [10-INTEGRATIONS.md](./10-INTEGRATIONS.md) → React Hook Form
- **tRPC**: [10-INTEGRATIONS.md](./10-INTEGRATIONS.md) → tRPC
- **Next.js**: [10-INTEGRATIONS.md](./10-INTEGRATIONS.md) → Next.js
- **Prisma**: [10-INTEGRATIONS.md](./10-INTEGRATIONS.md) → Prisma
- **Express**: [10-INTEGRATIONS.md](./10-INTEGRATIONS.md) → Express.js

### Performance
- **Optimization**: [08-PERFORMANCE.md](./08-PERFORMANCE.md) → Schema optimization
- **Caching**: [08-PERFORMANCE.md](./08-PERFORMANCE.md) → Caching strategies
- **Benchmarking**: [08-PERFORMANCE.md](./08-PERFORMANCE.md) → Benchmarking
- **Lazy loading**: [08-PERFORMANCE.md](./08-PERFORMANCE.md) → Lazy loading

### Testing
- **Unit testing**: [09-TESTING.md](./09-TESTING.md) → Testing schemas
- **Integration testing**: [09-TESTING.md](./09-TESTING.md) → Integration testing
- **Test factories**: [09-TESTING.md](./09-TESTING.md) → Best practices

### Production
- **Environment config**: [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) → Environment configuration
- **Error monitoring**: [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) → Error monitoring
- **Health checks**: [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) → Performance monitoring
- **Troubleshooting**: [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) → Troubleshooting

---

## Problem-Based Quick Find

### "I want to..."

#### Validate Data
- **"Validate form input"** → [10-INTEGRATIONS.md](./10-INTEGRATIONS.md) → React Hook Form
- **"Validate API requests"** → [03-VALIDATION.md](./03-VALIDATION.md) + [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) → API validation
- **"Validate email addresses"** → [03-VALIDATION.md](./03-VALIDATION.md) → Built-in validators
- **"Validate environment variables"** → [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) → Environment configuration
- **"Check if value is valid without throwing"** → [01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md) → safeParse()

#### Work with Types
- **"Get TypeScript type from schema"** → [04-TYPE-INFERENCE.md](./04-TYPE-INFERENCE.md) → z.infer
- **"Create branded types"** → [04-TYPE-INFERENCE.md](./04-TYPE-INFERENCE.md) → Branded types
- **"Handle input vs output types"** → [04-TYPE-INFERENCE.md](./04-TYPE-INFERENCE.md) → Input/Output types
- **"Create generic schemas"** → [07-ADVANCED-SCHEMAS.md](./07-ADVANCED-SCHEMAS.md) → Generic schemas

#### Build Schemas
- **"Create object schema"** → [02-SCHEMA-DEFINITION.md](./02-SCHEMA-DEFINITION.md) → Object schemas
- **"Validate arrays"** → [02-SCHEMA-DEFINITION.md](./02-SCHEMA-DEFINITION.md) → Array operations
- **"Create union types"** → [02-SCHEMA-DEFINITION.md](./02-SCHEMA-DEFINITION.md) → Unions
- **"Handle polymorphic data"** → [07-ADVANCED-SCHEMAS.md](./07-ADVANCED-SCHEMAS.md) → Discriminated unions
- **"Create recursive schemas"** → [07-ADVANCED-SCHEMAS.md](./07-ADVANCED-SCHEMAS.md) → Recursive schemas
- **"Make field optional"** → [02-SCHEMA-DEFINITION.md](./02-SCHEMA-DEFINITION.md) → Optional and nullable
- **"Compose schemas"** → [07-ADVANCED-SCHEMAS.md](./07-ADVANCED-SCHEMAS.md) → Schema composition

#### Transform Data
- **"Transform data after validation"** → [06-TRANSFORMATIONS.md](./06-TRANSFORMATIONS.md) → transform()
- **"Modify data before validation"** → [06-TRANSFORMATIONS.md](./06-TRANSFORMATIONS.md) → preprocess()
- **"Chain validations"** → [06-TRANSFORMATIONS.md](./06-TRANSFORMATIONS.md) → pipe()
- **"Convert string to number"** → [06-TRANSFORMATIONS.md](./06-TRANSFORMATIONS.md) → z.coerce
- **"Parse dates"** → [06-TRANSFORMATIONS.md](./06-TRANSFORMATIONS.md) → Date transformations

#### Handle Errors
- **"Customize error messages"** → [05-ERROR-HANDLING.md](./05-ERROR-HANDLING.md) → Custom error messages
- **"Format validation errors"** → [05-ERROR-HANDLING.md](./05-ERROR-HANDLING.md) → format() and flatten()
- **"Translate error messages"** → [05-ERROR-HANDLING.md](./05-ERROR-HANDLING.md) → Internationalization
- **"Get error details"** → [05-ERROR-HANDLING.md](./05-ERROR-HANDLING.md) → ZodError structure
- **"Monitor validation errors"** → [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) → Error monitoring

#### Integrate with Frameworks
- **"Use with React Hook Form"** → [10-INTEGRATIONS.md](./10-INTEGRATIONS.md) → React Hook Form
- **"Build type-safe API with tRPC"** → [10-INTEGRATIONS.md](./10-INTEGRATIONS.md) → tRPC
- **"Validate Next.js API routes"** → [10-INTEGRATIONS.md](./10-INTEGRATIONS.md) → Next.js
- **"Validate Prisma models"** → [10-INTEGRATIONS.md](./10-INTEGRATIONS.md) → Prisma
- **"Add middleware to Express"** → [10-INTEGRATIONS.md](./10-INTEGRATIONS.md) → Express.js

#### Optimize Performance
- **"Speed up validation"** → [08-PERFORMANCE.md](./08-PERFORMANCE.md) → Schema optimization
- **"Cache validation results"** → [08-PERFORMANCE.md](./08-PERFORMANCE.md) → Caching strategies
- **"Benchmark schemas"** → [08-PERFORMANCE.md](./08-PERFORMANCE.md) → Benchmarking
- **"Reduce bundle size"** → [08-PERFORMANCE.md](./08-PERFORMANCE.md) → Lazy loading

#### Test Schemas
- **"Write unit tests"** → [09-TESTING.md](./09-TESTING.md) → Testing schemas
- **"Test API endpoints"** → [09-TESTING.md](./09-TESTING.md) → Integration testing
- **"Test transformations"** → [09-TESTING.md](./09-TESTING.md) → Testing transformations
- **"Test error messages"** → [09-TESTING.md](./09-TESTING.md) → Testing error messages

#### Production
- **"Validate config on startup"** → [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) → Environment configuration
- **"Monitor validation failures"** → [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) → Error monitoring
- **"Version schemas"** → [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) → Schema versioning
- **"Handle validation in production"** → [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) → Production patterns
- **"Debug validation issues"** → [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) → Troubleshooting

---

## Code Examples by Use Case

### Form Validation
```typescript
// React Hook Form integration
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'

const schema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
})

const { register, handleSubmit } = useForm({
  resolver: zodResolver(schema),
})
```
📖 See: [10-INTEGRATIONS.md](./10-INTEGRATIONS.md) → React Hook Form

### API Validation
```typescript
// Next.js API route
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

  const user = await db.user.create({ data: result.data })
  return Response.json({ user })
}
```
📖 See: [10-INTEGRATIONS.md](./10-INTEGRATIONS.md) → Next.js

### Environment Configuration
```typescript
// Validate environment variables
const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']),
  DATABASE_URL: z.string().url(),
  PORT: z.coerce.number().default(3000),
})

export const env = envSchema.parse(process.env)
```
📖 See: [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) → Environment configuration

### Type-Safe API (tRPC)
```typescript
// tRPC procedure
import { z } from 'zod'

const appRouter = t.router({
  createUser: t.procedure
    .input(z.object({ name: z.string(), email: z.string().email() }))
    .mutation(async ({ input }) => {
      return await db.user.create({ data: input })
    }),
})
```
📖 See: [10-INTEGRATIONS.md](./10-INTEGRATIONS.md) → tRPC

### Complex Validation
```typescript
// Discriminated union for polymorphic data
const shapeSchema = z.discriminatedUnion("kind", [
  z.object({ kind: z.literal("circle"), radius: z.number() }),
  z.object({ kind: z.literal("square"), sideLength: z.number() }),
])

// Recursive schema
const treeSchema: z.ZodType<TreeNode> = z.lazy(() =>
  z.object({
    value: z.number(),
    left: treeSchema.optional(),
    right: treeSchema.optional(),
  })
)
```
📖 See: [07-ADVANCED-SCHEMAS.md](./07-ADVANCED-SCHEMAS.md)

### Data Transformation
```typescript
// Transform and validate
const normalizedEmail = z.string()
  .transform((s) => s.trim())
  .pipe(z.string().toLowerCase())
  .pipe(z.string().email())

const dateSchema = z.string().transform((str) => new Date(str))
```
📖 See: [06-TRANSFORMATIONS.md](./06-TRANSFORMATIONS.md)

---

## Learning Paths

### 🟢 Beginner → Intermediate

**Phase 1: Basics** (2-3 hours)
1. [README.md](./README.md) - Overview and why Zod
2. [01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md) - Core concepts
3. [02-SCHEMA-DEFINITION.md](./02-SCHEMA-DEFINITION.md) - Building schemas
4. [03-VALIDATION.md](./03-VALIDATION.md) - Validation patterns

**Phase 2: TypeScript Integration** (1-2 hours)
1. [04-TYPE-INFERENCE.md](./04-TYPE-INFERENCE.md) - Type inference
2. [05-ERROR-HANDLING.md](./05-ERROR-HANDLING.md) - Error management
3. [06-TRANSFORMATIONS.md](./06-TRANSFORMATIONS.md) - Data transformation

**Phase 3: Practical Use** (2-3 hours)
1. [10-INTEGRATIONS.md](./10-INTEGRATIONS.md) - Framework integration
2. [09-TESTING.md](./09-TESTING.md) - Testing strategies
3. Practice: Build a form validation system

### 🟡 Intermediate → Advanced

**Phase 1: Advanced Patterns** (2-3 hours)
1. [07-ADVANCED-SCHEMAS.md](./07-ADVANCED-SCHEMAS.md) - Complex schemas
2. [08-PERFORMANCE.md](./08-PERFORMANCE.md) - Performance optimization

**Phase 2: Production** (2-3 hours)
1. [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) - Production patterns
2. [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md) - Advanced integrations
3. Practice: Build enterprise API validation system

---

## AI Pair Programming Notes

**When starting a new Zod project:**
1. Check [README.md](./README.md) for overview and comparison
2. Follow appropriate learning path based on experience
3. Reference [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) for syntax

**When troubleshooting:**
1. Check [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) → Troubleshooting
2. Review [05-ERROR-HANDLING.md](./05-ERROR-HANDLING.md) for error details
3. Use "Problem-Based Quick Find" above

**When optimizing:**
1. Start with [08-PERFORMANCE.md](./08-PERFORMANCE.md)
2. Profile before optimizing
3. Focus on hot paths only

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1
