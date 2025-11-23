---
id: zod-10-integrations
topic: zod
file_role: practical
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [zod-fundamentals, zod-validation]
related_topics: [react-hook-form, trpc, nextjs, prisma]
embedding_keywords: [zod, integration, react-hook-form, trpc, nextjs, prisma, zodios]
last_reviewed: 2025-11-16
---

# Zod - Framework and Library Integrations

## Purpose

Comprehensive integration patterns for Zod with popular frameworks and libraries including React Hook Form, tRPC, Next.js, Prisma, and more.

## Table of Contents

1. [React Hook Form](#react-hook-form)
2. [tRPC](#trpc)
3. [Next.js](#nextjs)
4. [Prisma](#prisma)
5. [Express.js](#expressjs)
6. [Other Integrations](#other-integrations)

---

## React Hook Form

### Basic Integration

```typescript
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'

const formSchema = z.object({
  name: z.string().min(1, "Name is required"),
  email: z.string().email("Invalid email"),
  age: z.coerce.number().min(18, "Must be 18+"),
})

type FormData = z.infer<typeof formSchema>

function MyForm() {
  const { register, handleSubmit, formState: { errors } } = useForm<FormData>({
    resolver: zodResolver(formSchema),
  })

  const onSubmit = (data: FormData) => {
    console.log(data) // Validated and type-safe
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <input {...register("name")} />
      {errors.name && <span>{errors.name.message}</span>}

      <input {...register("email")} />
      {errors.email && <span>{errors.email.message}</span>}

      <input type="number" {...register("age")} />
      {errors.age && <span>{errors.age.message}</span>}

      <button type="submit">Submit</button>
    </form>
  )
}
```

### Advanced Form Patterns

```typescript
// Nested objects
const addressSchema = z.object({
  street: z.string(),
  city: z.string(),
  zip: z.string().regex(/^\d{5}$/),
})

const userFormSchema = z.object({
  name: z.string(),
  email: z.string().email(),
  address: addressSchema,
})

function NestedForm() {
  const { register, handleSubmit, formState: { errors } } = useForm({
    resolver: zodResolver(userFormSchema),
  })

  return (
    <form onSubmit={handleSubmit(console.log)}>
      <input {...register("name")} />
      <input {...register("email")} />

      <input {...register("address.street")} />
      {errors.address?.street && <span>{errors.address.street.message}</span>}

      <input {...register("address.city")} />
      <input {...register("address.zip")} />
    </form>
  )
}
```

---

## tRPC

### Basic Setup

```typescript
import { initTRPC } from '@trpc/server'
import { z } from 'zod'

const t = initTRPC.create()

const appRouter = t.router({
  getUser: t.procedure
    .input(z.object({ id: z.string().uuid() }))
    .query(async ({ input }) => {
      // input is type-safe and validated
      const user = await db.user.findUnique({ where: { id: input.id } })
      return user
    }),

  createUser: t.procedure
    .input(z.object({
      name: z.string().min(1),
      email: z.string().email(),
    }))
    .mutation(async ({ input }) => {
      const user = await db.user.create({ data: input })
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

const appRouter = t.router({
  getUser: t.procedure
    .input(z.object({ id: z.string().uuid() }))
    .output(userSchema)
    .query(async ({ input }) => {
      const user = await db.user.findUnique({ where: { id: input.id } })
      return userSchema.parse(user) // Validates output
    }),
})
```

---

## Next.js

### API Routes (App Router)

```typescript
// app/api/users/route.ts
import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'

const createUserSchema = z.object({
  name: z.string().min(1),
  email: z.string().email(),
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
        { error: error.flatten() },
        { status: 400 }
      )
    }
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    )
  }
}
```

### Server Actions

```typescript
// app/actions/user.ts
'use server'

import { z } from 'zod'

const updateUserSchema = z.object({
  id: z.string().uuid(),
  name: z.string().min(1).optional(),
  email: z.string().email().optional(),
})

export async function updateUser(formData: FormData) {
  const data = Object.fromEntries(formData)
  const validated = updateUserSchema.safeParse(data)

  if (!validated.success) {
    return { error: validated.error.flatten() }
  }

  const user = await db.user.update({
    where: { id: validated.data.id },
    data: validated.data,
  })

  return { user }
}
```

---

## Prisma

### Generate Zod Schemas from Prisma

```bash
npm install zod-prisma-types
```

```prisma
// schema.prisma
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
}
```

```typescript
// Generated schemas
import { UserSchema } from './generated/zod'

// Validate Prisma model data
const userData = UserSchema.parse(data)
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
```

---

## Express.js

### Middleware Validation

```typescript
import express from 'express'
import { z } from 'zod'

function validate<T extends z.ZodTypeAny>(schema: T) {
  return (req: express.Request, res: express.Response, next: express.NextFunction) => {
    const result = schema.safeParse(req.body)

    if (!result.success) {
      return res.status(400).json({ error: result.error.flatten() })
    }

    req.body = result.data
    next()
  }
}

const createUserSchema = z.object({
  name: z.string(),
  email: z.string().email(),
})

app.post('/users',
  validate(createUserSchema),
  async (req, res) => {
    // req.body is validated and type-safe
    const user = await db.user.create({ data: req.body })
    res.json({ user })
  }
)
```

### Query Parameter Validation

```typescript
const getUserQuerySchema = z.object({
  id: z.string().uuid(),
  include: z.enum(['posts', 'comments']).optional(),
})

app.get('/users', async (req, res) => {
  const result = getUserQuerySchema.safeParse(req.query)

  if (!result.success) {
    return res.status(400).json({ error: result.error.flatten() })
  }

  const { id, include } = result.data
  // ...
})
```

---

## Other Integrations

### Fastify

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
    return reply.code(400).send({ error: result.error })
  }

  // Use validated data
  const user = await db.user.create({ data: result.data })
  return { user }
})
```

### Zodios (Type-safe API Client)

```typescript
import { Zodios } from '@zodios/core'
import { z } from 'zod'

const userSchema = z.object({
  id: z.string(),
  name: z.string(),
  email: z.string().email(),
})

const api = new Zodios('https://api.example.com', [
  {
    method: 'get',
    path: '/users/:id',
    response: userSchema,
  },
  {
    method: 'post',
    path: '/users',
    parameters: [
      {
        name: 'body',
        type: 'Body',
        schema: z.object({
          name: z.string(),
          email: z.string().email(),
        }),
      },
    ],
    response: userSchema,
  },
])

// Type-safe API calls
const user = await api.get('/users/:id', { params: { id: '123' } })
// user is typed as { id: string; name: string; email: string }
```

### GraphQL (with Pothos)

```typescript
import { createYoga } from 'graphql-yoga'
import { z } from 'zod'

const createUserInput = z.object({
  name: z.string(),
  email: z.string().email(),
})

const yoga = createYoga({
  schema: {
    typeDefs: `
      type Mutation {
        createUser(input: CreateUserInput!): User!
      }
    `,
    resolvers: {
      Mutation: {
        createUser: async (_, { input }) => {
          const validated = createUserInput.parse(input)
          return db.user.create({ data: validated })
        },
      },
    },
  },
})
```

---

## Best Practices

### 1. Reuse Schemas Across Integrations

```typescript
// schemas/user.ts
export const userSchema = z.object({
  id: z.string().uuid(),
  name: z.string(),
  email: z.string().email(),
})

export const createUserSchema = userSchema.omit({ id: true })

// Use in tRPC
import { createUserSchema } from './schemas/user'

const appRouter = t.router({
  createUser: t.procedure
    .input(createUserSchema)
    .mutation(async ({ input }) => {
      // ...
    }),
})

// Use in React Hook Form
import { createUserSchema } from './schemas/user'

const { register, handleSubmit } = useForm({
  resolver: zodResolver(createUserSchema),
})
```

### 2. Generate Types from Schemas

```typescript
// Single source of truth
const apiSchema = z.object({
  user: userSchema,
  posts: z.array(postSchema),
})

type ApiResponse = z.infer<typeof apiSchema>
```

### 3. Validate at Boundaries

```typescript
// Validate at API boundary
export async function POST(request: Request) {
  const result = schema.safeParse(await request.json())
  // ...
}

// Don't re-validate internally
function processData(data: ValidatedData) {
  // data is already validated
}
```

---

## AI Pair Programming Notes

**When to load this file:**
- Integrating Zod with frameworks
- Setting up form validation
- Building type-safe APIs
- Working with tRPC or React Hook Form

**Typical questions:**
- "How do I use Zod with React Hook Form?"
- "How do I integrate Zod with tRPC?"
- "How do I validate Next.js API routes?"
- "How do I use Zod with Prisma?"

**Next steps:**
- [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md) - Framework patterns
- [03-VALIDATION.md](./03-VALIDATION.md) - Validation basics

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1
