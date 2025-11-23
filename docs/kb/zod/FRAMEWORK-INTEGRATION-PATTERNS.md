---
id: zod-framework-integration
topic: zod
file_role: framework
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [zod-fundamentals, zod-validation]
related_topics: [nextjs, react, trpc, prisma, react-hook-form]
embedding_keywords: [zod, framework-integration, nextjs, react, trpc, prisma, express]
last_reviewed: 2025-11-16
---

# Zod - Framework Integration Patterns

Comprehensive patterns for integrating Zod with popular frameworks and libraries.

## Table of Contents

1. [Next.js Integration](#nextjs-integration)
2. [React Patterns](#react-patterns)
3. [tRPC Integration](#trpc-integration)
4. [Prisma Integration](#prisma-integration)
5. [Node.js Frameworks](#nodejs-frameworks)
6. [Advanced Patterns](#advanced-patterns)
7. [Best Practices](#best-practices)

---

## Next.js Integration

### App Router API Routes

```typescript
// app/api/users/route.ts
import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'

const createUserSchema = z.object({
  name: z.string().min(1, 'Name is required'),
  email: z.string().email('Invalid email'),
  age: z.number().int().positive().optional(),
})

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const data = createUserSchema.parse(body)

    const user = await db.user.create({ data })

    return NextResponse.json({ user }, { status: 201 })
  } catch (error) {
    if (error instanceof z.ZodError) {
      return NextResponse.json(
        { error: 'Validation failed', details: error.flatten() },
        { status: 400 }
      )
    }

    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}
```

### Dynamic Route Parameters

```typescript
// app/api/users/[id]/route.ts
import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'

const paramsSchema = z.object({
  id: z.string().uuid(),
})

const updateUserSchema = z.object({
  name: z.string().min(1).optional(),
  email: z.string().email().optional(),
})

export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    // Validate params
    const { id } = paramsSchema.parse(await params)

    // Validate body
    const body = await request.json()
    const data = updateUserSchema.parse(body)

    const user = await db.user.update({
      where: { id },
      data,
    })

    return NextResponse.json({ user })
  } catch (error) {
    if (error instanceof z.ZodError) {
      return NextResponse.json({ error: error.flatten() }, { status: 400 })
    }

    return NextResponse.json({ error: 'Server error' }, { status: 500 })
  }
}
```

### Server Actions

```typescript
// app/actions/user.ts
'use server'

import { z } from 'zod'
import { revalidatePath } from 'next/cache'

const createUserSchema = z.object({
  name: z.string().min(1),
  email: z.string().email(),
})

export async function createUser(formData: FormData) {
  // Convert FormData to object
  const data = Object.fromEntries(formData)

  // Validate
  const result = createUserSchema.safeParse(data)

  if (!result.success) {
    return {
      error: result.error.flatten().fieldErrors,
    }
  }

  // Create user
  const user = await db.user.create({
    data: result.data,
  })

  // Revalidate
  revalidatePath('/users')

  return { success: true, user }
}
```

### Query String Validation

```typescript
// app/api/users/search/route.ts
import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'

const searchParamsSchema = z.object({
  q: z.string().min(1),
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(100).default(10),
  sortBy: z.enum(['name', 'email', 'createdAt']).optional(),
  order: z.enum(['asc', 'desc']).default('asc'),
})

export async function GET(request: NextRequest) {
  const searchParams = Object.fromEntries(request.nextUrl.searchParams)
  const result = searchParamsSchema.safeParse(searchParams)

  if (!result.success) {
    return NextResponse.json({ error: result.error.flatten() }, { status: 400 })
  }

  const { q, page, limit, sortBy, order } = result.data

  const users = await db.user.findMany({
    where: {
      OR: [
        { name: { contains: q } },
        { email: { contains: q } },
      ],
    },
    orderBy: sortBy ? { [sortBy]: order } : undefined,
    skip: (page - 1) * limit,
    take: limit,
  })

  return NextResponse.json({ users, page, limit })
}
```

### Middleware Validation

```typescript
// middleware.ts
import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'

const apiKeySchema = z.string().min(32)

export function middleware(request: NextRequest) {
  if (request.nextUrl.pathname.startsWith('/api/protected')) {
    const apiKey = request.headers.get('x-api-key')

    const result = apiKeySchema.safeParse(apiKey)

    if (!result.success) {
      return NextResponse.json(
        { error: 'Invalid API key' },
        { status: 401 }
      )
    }
  }

  return NextResponse.next()
}
```

---

## React Patterns

### React Hook Form Integration

```typescript
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'

const formSchema = z.object({
  name: z.string().min(1, 'Name is required'),
  email: z.string().email('Invalid email'),
  age: z.coerce.number().int().positive().optional(),
})

type FormData = z.infer<typeof formSchema>

function UserForm() {
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<FormData>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      name: '',
      email: '',
    },
  })

  const onSubmit = async (data: FormData) => {
    const response = await fetch('/api/users', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    })

    if (!response.ok) {
      throw new Error('Failed to create user')
    }
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <div>
        <input {...register('name')} placeholder="Name" />
        {errors.name && <span>{errors.name.message}</span>}
      </div>

      <div>
        <input {...register('email')} placeholder="Email" />
        {errors.email && <span>{errors.email.message}</span>}
      </div>

      <div>
        <input type="number" {...register('age')} placeholder="Age" />
        {errors.age && <span>{errors.age.message}</span>}
      </div>

      <button type="submit" disabled={isSubmitting}>
        {isSubmitting ? 'Creating...' : 'Create User'}
      </button>
    </form>
  )
}
```

### Custom Validation Hook

```typescript
import { useState } from 'react'
import { z } from 'zod'

function useValidation<T extends z.ZodTypeAny>(schema: T) {
  const [errors, setErrors] = useState<z.ZodError | null>(null)

  const validate = (data: unknown): data is z.infer<T> => {
    const result = schema.safeParse(data)

    if (result.success) {
      setErrors(null)
      return true
    }

    setErrors(result.error)
    return false
  }

  const clearErrors = () => setErrors(null)

  return { errors, validate, clearErrors }
}

// Usage
const userSchema = z.object({
  name: z.string().min(1),
  email: z.string().email(),
})

function MyComponent() {
  const { errors, validate } = useValidation(userSchema)

  const handleSubmit = (data: unknown) => {
    if (validate(data)) {
      // data is now typed and validated
      console.log(data)
    }
  }

  return (
    <div>
      {errors && <pre>{JSON.stringify(errors.flatten(), null, 2)}</pre>}
      {/* Form fields */}
    </div>
  )
}
```

### Context-Based Schema Sharing

```typescript
import { createContext, useContext } from 'react'
import { z } from 'zod'

// Define schemas
const userSchema = z.object({
  id: z.string().uuid(),
  name: z.string(),
  email: z.string().email(),
})

const postSchema = z.object({
  id: z.string().uuid(),
  title: z.string(),
  content: z.string(),
  authorId: z.string().uuid(),
})

// Schema registry
const schemas = {
  user: userSchema,
  post: postSchema,
}

type Schemas = typeof schemas

// Context
const SchemaContext = createContext<Schemas>(schemas)

export function SchemaProvider({ children }: { children: React.ReactNode }) {
  return (
    <SchemaContext.Provider value={schemas}>
      {children}
    </SchemaContext.Provider>
  )
}

export function useSchema<K extends keyof Schemas>(key: K): Schemas[K] {
  const schemas = useContext(SchemaContext)
  return schemas[key]
}

// Usage
function UserComponent() {
  const userSchema = useSchema('user')

  const validateUser = (data: unknown) => {
    return userSchema.safeParse(data)
  }

  // ...
}
```

---

## tRPC Integration

### Basic tRPC Setup

```typescript
// server/trpc.ts
import { initTRPC } from '@trpc/server'
import { z } from 'zod'

const t = initTRPC.create()

export const appRouter = t.router({
  // Query with input validation
  getUser: t.procedure
    .input(z.object({ id: z.string().uuid() }))
    .query(async ({ input }) => {
      const user = await db.user.findUnique({ where: { id: input.id } })
      return user
    }),

  // Mutation with input validation
  createUser: t.procedure
    .input(z.object({
      name: z.string().min(1),
      email: z.string().email(),
    }))
    .mutation(async ({ input }) => {
      const user = await db.user.create({ data: input })
      return user
    }),

  // Update with partial input
  updateUser: t.procedure
    .input(z.object({
      id: z.string().uuid(),
      data: z.object({
        name: z.string().min(1).optional(),
        email: z.string().email().optional(),
      }),
    }))
    .mutation(async ({ input }) => {
      const user = await db.user.update({
        where: { id: input.id },
        data: input.data,
      })
      return user
    }),
})

export type AppRouter = typeof appRouter
```

### Output Validation

```typescript
const userSchema = z.object({
  id: z.string().uuid(),
  name: z.string(),
  email: z.string().email(),
  createdAt: z.date(),
})

export const appRouter = t.router({
  getUser: t.procedure
    .input(z.object({ id: z.string().uuid() }))
    .output(userSchema)
    .query(async ({ input }) => {
      const user = await db.user.findUnique({ where: { id: input.id } })
      // Output is validated against userSchema
      return userSchema.parse(user)
    }),
})
```

### Protected Procedures

```typescript
// Context with user
interface Context {
  user?: {
    id: string
    role: string
  }
}

const t = initTRPC.context<Context>().create()

// Middleware for authentication
const isAuthenticated = t.middleware(({ ctx, next }) => {
  if (!ctx.user) {
    throw new Error('Not authenticated')
  }
  return next({ ctx: { user: ctx.user } })
})

const authenticatedProcedure = t.procedure.use(isAuthenticated)

export const appRouter = t.router({
  createPost: authenticatedProcedure
    .input(z.object({
      title: z.string().min(1),
      content: z.string(),
    }))
    .mutation(async ({ input, ctx }) => {
      const post = await db.post.create({
        data: {
          ...input,
          authorId: ctx.user.id,
        },
      })
      return post
    }),
})
```

---

## Prisma Integration

### Generate Zod Schemas from Prisma

```bash
npm install zod-prisma-types
```

```prisma
// prisma/schema.prisma
generator client {
  provider = "prisma-client-js"
}

generator zod {
  provider = "zod-prisma-types"
}

model User {
  id        String   @id @default(uuid())
  name      String
  email     String   @unique
  createdAt DateTime @default(now())
  posts     Post[]
}

model Post {
  id       String @id @default(uuid())
  title    String
  content  String
  authorId String
  author   User   @relation(fields: [authorId], references: [id])
}
```

```typescript
// After running `npx prisma generate`
import { UserSchema, PostSchema } from './generated/zod'

// Validate Prisma data
const userData = UserSchema.parse(data)

// Use in API
export async function POST(request: Request) {
  const body = await request.json()
  const data = UserSchema.omit({ id: true, createdAt: true }).parse(body)

  const user = await db.user.create({ data })
  return Response.json({ user })
}
```

### Manual Prisma Integration

```typescript
import { z } from 'zod'
import { Prisma } from '@prisma/client'

// Match Prisma types
const userCreateSchema = z.object({
  name: z.string(),
  email: z.string().email(),
}) satisfies z.ZodType<Prisma.UserCreateInput>

const userUpdateSchema = z.object({
  name: z.string().optional(),
  email: z.string().email().optional(),
}) satisfies z.ZodType<Prisma.UserUpdateInput>

// Use with Prisma
export async function createUser(data: unknown) {
  const validated = userCreateSchema.parse(data)
  return await db.user.create({ data: validated })
}
```

---

## Node.js Frameworks

### Express.js Middleware

```typescript
import express from 'express'
import { z } from 'zod'

function validateBody<T extends z.ZodTypeAny>(schema: T) {
  return (req: express.Request, res: express.Response, next: express.NextFunction) => {
    const result = schema.safeParse(req.body)

    if (!result.success) {
      return res.status(400).json({
        error: 'Validation failed',
        details: result.error.flatten(),
      })
    }

    // Replace body with validated data
    req.body = result.data
    next()
  }
}

const createUserSchema = z.object({
  name: z.string(),
  email: z.string().email(),
})

const app = express()

app.post('/users',
  validateBody(createUserSchema),
  async (req, res) => {
    // req.body is validated and type-safe
    const user = await db.user.create({ data: req.body })
    res.json({ user })
  }
)
```

### Fastify Integration

```typescript
import Fastify from 'fastify'
import { z } from 'zod'

const fastify = Fastify()

const createUserSchema = z.object({
  name: z.string(),
  email: z.string().email(),
})

fastify.post('/users', async (request, reply) => {
  const result = createUserSchema.safeParse(request.body)

  if (!result.success) {
    return reply.code(400).send({
      error: result.error.flatten(),
    })
  }

  const user = await db.user.create({ data: result.data })
  return { user }
})
```

### Hono Integration

```typescript
import { Hono } from 'hono'
import { z } from 'zod'
import { zValidator } from '@hono/zod-validator'

const app = new Hono()

const createUserSchema = z.object({
  name: z.string(),
  email: z.string().email(),
})

app.post('/users',
  zValidator('json', createUserSchema),
  async (c) => {
    const data = c.req.valid('json')
    const user = await db.user.create({ data })
    return c.json({ user })
  }
)
```

---

## Advanced Patterns

### Schema Registry Pattern

```typescript
// schemas/registry.ts
import { z } from 'zod'

export const schemas = {
  user: {
    create: z.object({
      name: z.string().min(1),
      email: z.string().email(),
    }),
    update: z.object({
      name: z.string().min(1).optional(),
      email: z.string().email().optional(),
    }),
    read: z.object({
      id: z.string().uuid(),
      name: z.string(),
      email: z.string().email(),
      createdAt: z.date(),
    }),
  },
  post: {
    create: z.object({
      title: z.string().min(1),
      content: z.string(),
    }),
    update: z.object({
      title: z.string().min(1).optional(),
      content: z.string().optional(),
    }),
    read: z.object({
      id: z.string().uuid(),
      title: z.string(),
      content: z.string(),
      authorId: z.string().uuid(),
      createdAt: z.date(),
    }),
  },
}

export type Schemas = typeof schemas

// Helper to get schema
export function getSchema<
  Entity extends keyof Schemas,
  Operation extends keyof Schemas[Entity]
>(entity: Entity, operation: Operation): Schemas[Entity][Operation] {
  return schemas[entity][operation]
}
```

### Reusable Validation Decorator

```typescript
import { z } from 'zod'

function Validate<T extends z.ZodTypeAny>(schema: T) {
  return function (
    target: any,
    propertyKey: string,
    descriptor: PropertyDescriptor
  ) {
    const originalMethod = descriptor.value

    descriptor.value = async function (...args: any[]) {
      const [data] = args
      const result = schema.safeParse(data)

      if (!result.success) {
        throw new Error(`Validation failed: ${result.error.message}`)
      }

      return originalMethod.apply(this, [result.data, ...args.slice(1)])
    }

    return descriptor
  }
}

// Usage
class UserService {
  @Validate(createUserSchema)
  async createUser(data: unknown) {
    // data is validated
    return await db.user.create({ data })
  }
}
```

### Type-Safe API Client

```typescript
// api-client.ts
import { z } from 'zod'

type Endpoint<I extends z.ZodTypeAny, O extends z.ZodTypeAny> = {
  input: I
  output: O
}

function createEndpoint<I extends z.ZodTypeAny, O extends z.ZodTypeAny>(
  input: I,
  output: O
): Endpoint<I, O> {
  return { input, output }
}

const endpoints = {
  getUser: createEndpoint(
    z.object({ id: z.string().uuid() }),
    z.object({ id: z.string().uuid(), name: z.string(), email: z.string().email() })
  ),
  createUser: createEndpoint(
    z.object({ name: z.string(), email: z.string().email() }),
    z.object({ id: z.string().uuid(), name: z.string(), email: z.string().email() })
  ),
}

async function call<K extends keyof typeof endpoints>(
  endpoint: K,
  input: z.infer<typeof endpoints[K]['input']>
): Promise<z.infer<typeof endpoints[K]['output']>> {
  const { input: inputSchema, output: outputSchema } = endpoints[endpoint]

  // Validate input
  const validatedInput = inputSchema.parse(input)

  // Make request
  const response = await fetch(`/api/${endpoint}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(validatedInput),
  })

  const data = await response.json()

  // Validate output
  return outputSchema.parse(data)
}

// Usage
const user = await call('createUser', {
  name: 'Alice',
  email: 'alice@example.com',
})
// user is typed as { id: string; name: string; email: string }
```

---

## Best Practices

### 1. Centralize Schemas

```typescript
// ✅ Good - Centralized schemas
// schemas/user.ts
export const userSchema = z.object({
  id: z.string().uuid(),
  name: z.string(),
  email: z.string().email(),
})

export const createUserSchema = userSchema.omit({ id: true })
export const updateUserSchema = createUserSchema.partial()

// Use across application
import { createUserSchema } from '@/schemas/user'

// ❌ Bad - Duplicated schemas
const schema1 = z.object({ name: z.string(), email: z.string().email() })
const schema2 = z.object({ name: z.string(), email: z.string().email() })
```

### 2. Validate at Boundaries

```typescript
// ✅ Good - Validate at API boundary
export async function POST(request: Request) {
  const body = await request.json()
  const data = schema.safeParse(body)

  if (!data.success) {
    return Response.json({ error: data.error }, { status: 400 })
  }

  // Pass validated data to business logic
  return processData(data.data)
}

// ❌ Bad - Re-validate internally
function processData(data: unknown) {
  const validated = schema.parse(data) // Already validated!
  // ...
}
```

### 3. Use safeParse in Production

```typescript
// ✅ Good - Never crashes
const result = schema.safeParse(data)
if (!result.success) {
  logger.error('Validation failed', result.error)
  return { error: 'Invalid input' }
}

// ❌ Bad - May crash app
const data = schema.parse(input) // Throws error
```

### 4. Type Inference

```typescript
// ✅ Good - Single source of truth
const userSchema = z.object({ name: z.string(), email: z.string().email() })
type User = z.infer<typeof userSchema>

// ❌ Bad - Duplicate types
type User = { name: string; email: string }
const userSchema = z.object({ name: z.string(), email: z.string().email() })
```

---

## Performance Optimization

### Schema Reuse

```typescript
// ✅ Good - Compile once, reuse
const schema = z.object({ name: z.string() })

function validate1(data: unknown) {
  return schema.safeParse(data)
}

function validate2(data: unknown) {
  return schema.safeParse(data)
}

// ❌ Bad - Recreate schema
function validate(data: unknown) {
  const schema = z.object({ name: z.string() })
  return schema.safeParse(data)
}
```

### Lazy Loading

```typescript
// Lazy load heavy schemas
const heavySchemas = {
  get complex() {
    return import('./schemas/complex').then(m => m.complexSchema)
  },
}

// Use when needed
const schema = await heavySchemas.complex
```

---

## AI Pair Programming Notes

**When to load this file:**
- Integrating Zod with frameworks
- Setting up validation in API routes
- Building type-safe APIs
- Form validation setup

**Typical questions:**
- "How do I use Zod with Next.js?" → See Next.js Integration
- "How do I integrate with React Hook Form?" → See React Patterns
- "How do I build type-safe API with tRPC?" → See tRPC Integration
- "How do I validate Express routes?" → See Node.js Frameworks

**Next steps:**
- [10-INTEGRATIONS.md](./10-INTEGRATIONS.md) - Framework integration basics
- [03-VALIDATION.md](./03-VALIDATION.md) - Validation patterns
- [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) - Production patterns

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1
