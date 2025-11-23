---
id: zod-04-type-inference
topic: zod
file_role: practical
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [zod-fundamentals, zod-schema-definition, typescript-basics]
related_topics: [typescript, type-safety, inference]
embedding_keywords: [zod, typescript, type-inference, infer, types]
last_reviewed: 2025-11-16
---

# Zod - TypeScript Type Inference

## Purpose

Master TypeScript type inference with Zod, extracting types from schemas, working with branded types, and ensuring end-to-end type safety.

## Table of Contents

1. [Basic Type Inference](#basic-type-inference)
2. [Input vs Output Types](#input-vs-output-types)
3. [Branded Types](#branded-types)
4. [Utility Types](#utility-types)
5. [Advanced Inference](#advanced-inference)
6. [Integration Patterns](#integration-patterns)

---

## Basic Type Inference

### z.infer - Extract TypeScript Type

```typescript
import { z } from 'zod'

const userSchema = z.object({
  id: z.string().uuid(),
  name: z.string(),
  email: z.string().email(),
  age: z.number().int().positive(),
  roles: z.array(z.string()),
  settings: z.object({
    theme: z.enum(["light", "dark"]),
    notifications: z.boolean(),
  }),
})

// Infer TypeScript type from schema
type User = z.infer<typeof userSchema>

/*
type User = {
  id: string
  name: string
  email: string
  age: number
  roles: string[]
  settings: {
    theme: "light" | "dark"
    notifications: boolean
  }
}
*/

// Use inferred type
const user: User = {
  id: "123e4567-e89b-12d3-a456-426614174000",
  name: "Alice",
  email: "alice@example.com",
  age: 30,
  roles: ["admin", "user"],
  settings: {
    theme: "dark",
    notifications: true,
  },
}
```

### Primitive Type Inference

```typescript
const stringSchema = z.string()
type StringType = z.infer<typeof stringSchema> // string

const numberSchema = z.number()
type NumberType = z.infer<typeof numberSchema> // number

const booleanSchema = z.boolean()
type BooleanType = z.infer<typeof booleanSchema> // boolean

const dateSchema = z.date()
type DateType = z.infer<typeof dateSchema> // Date

const enumSchema = z.enum(["a", "b", "c"])
type EnumType = z.infer<typeof enumSchema> // "a" | "b" | "c"

const literalSchema = z.literal("hello")
type LiteralType = z.infer<typeof literalSchema> // "hello"
```

### Complex Type Inference

```typescript
// Union types
const idSchema = z.union([z.string(), z.number()])
type Id = z.infer<typeof idSchema> // string | number

// Discriminated union
const shapeSchema = z.discriminatedUnion("kind", [
  z.object({ kind: z.literal("circle"), radius: z.number() }),
  z.object({ kind: z.literal("square"), size: z.number() }),
])
type Shape = z.infer<typeof shapeSchema>
// { kind: "circle"; radius: number } | { kind: "square"; size: number }

// Tuple
const pointSchema = z.tuple([z.number(), z.number(), z.number()])
type Point = z.infer<typeof pointSchema> // [number, number, number]

// Record
const scoresSchema = z.record(z.string(), z.number())
type Scores = z.infer<typeof scoresSchema> // { [x: string]: number }

// Map and Set
const mapSchema = z.map(z.string(), z.number())
type MapType = z.infer<typeof mapSchema> // Map<string, number>

const setSchema = z.set(z.string())
type SetType = z.infer<typeof setSchema> // Set<string>
```

---

## Input vs Output Types

### Understanding Input and Output

```typescript
// Schema with transformations
const userSchema = z.object({
  name: z.string().trim().toLowerCase(),
  age: z.string().transform((val) => parseInt(val, 10)),
  createdAt: z.coerce.date(),
})

// Input type (before transformation)
type UserInput = z.input<typeof userSchema>
/*
{
  name: string
  age: string
  createdAt: string | number | Date
}
*/

// Output type (after transformation)
type UserOutput = z.output<typeof userSchema>
/*
{
  name: string
  age: number
  createdAt: Date
}
*/

// z.infer is alias for z.output
type User = z.infer<typeof userSchema>
// Same as UserOutput
```

### When to Use Input vs Output

```typescript
const apiSchema = z.object({
  userId: z.string().uuid(),
  timestamp: z.string().transform((s) => new Date(s)),
  data: z.string().transform((s) => JSON.parse(s)),
})

// Use input type for API request validation
function validateRequest(body: unknown): z.input<typeof apiSchema> {
  return apiSchema.parse(body)
}

// Use output type for application logic
function processData(data: z.output<typeof apiSchema>) {
  const { userId, timestamp, data: parsedData } = data
  // timestamp is Date (not string)
  // data is any (parsed JSON)
}
```

---

## Branded Types

### Creating Branded Types

```typescript
// Nominal type to prevent accidental mixing
const userIdSchema = z.string().uuid().brand<"UserId">()
const postIdSchema = z.string().uuid().brand<"PostId">()

type UserId = z.infer<typeof userIdSchema>
type PostId = z.infer<typeof postIdSchema>

// TypeScript prevents mixing
const userId: UserId = userIdSchema.parse("123e4567-e89b-12d3-a456-426614174000")
const postId: PostId = postIdSchema.parse("987e6543-e21b-12d3-a456-426614174000")

// ❌ Type error: Type 'UserId' is not assignable to type 'PostId'
// const wrongId: PostId = userId
```

### Branded Type Use Cases

```typescript
// Email brand
const emailSchema = z.string().email().brand<"Email">()
type Email = z.infer<typeof emailSchema>

// Currency brand
const usdSchema = z.number().positive().brand<"USD">()
const eurSchema = z.number().positive().brand<"EUR">()

type USD = z.infer<typeof usdSchema>
type EUR = z.infer<typeof eurSchema>

function processPayment(amount: USD) {
  // amount is guaranteed to be USD
}

const usd = usdSchema.parse(100)
const eur = eurSchema.parse(100)

processPayment(usd) // ✅ OK
// processPayment(eur) // ❌ Type error

// Positive integer brand
const positiveIntSchema = z.number().int().positive().brand<"PositiveInt">()
type PositiveInt = z.infer<typeof positiveIntSchema>

function processQuantity(qty: PositiveInt) {
  // qty is guaranteed to be a positive integer
}
```

---

## Utility Types

### Partial and Required

```typescript
const userSchema = z.object({
  id: z.string(),
  name: z.string(),
  email: z.string().email(),
})

// Make all fields optional
const partialUserSchema = userSchema.partial()
type PartialUser = z.infer<typeof partialUserSchema>
// { id?: string; name?: string; email?: string }

// Make all fields required (reverse of partial)
const requiredUserSchema = partialUserSchema.required()
type RequiredUser = z.infer<typeof requiredUserSchema>
// { id: string; name: string; email: string }

// Partial specific fields
const partialNameSchema = userSchema.partial({ name: true })
type PartialName = z.infer<typeof partialNameSchema>
// { id: string; name?: string; email: string }
```

### Pick and Omit

```typescript
const userSchema = z.object({
  id: z.string(),
  name: z.string(),
  email: z.string().email(),
  password: z.string(),
  createdAt: z.date(),
})

// Pick specific fields
const userPublicSchema = userSchema.pick({ id: true, name: true, email: true })
type UserPublic = z.infer<typeof userPublicSchema>
// { id: string; name: string; email: string }

// Omit specific fields
const userWithoutPasswordSchema = userSchema.omit({ password: true })
type UserWithoutPassword = z.infer<typeof userWithoutPasswordSchema>
// { id: string; name: string; email: string; createdAt: Date }
```

### Extend and Merge

```typescript
const baseSchema = z.object({
  id: z.string(),
  createdAt: z.date(),
})

// Extend with new fields
const userSchema = baseSchema.extend({
  name: z.string(),
  email: z.string().email(),
})

type User = z.infer<typeof userSchema>
// { id: string; createdAt: Date; name: string; email: string }

// Merge two schemas
const schema1 = z.object({ a: z.string() })
const schema2 = z.object({ b: z.number() })
const mergedSchema = schema1.merge(schema2)

type Merged = z.infer<typeof mergedSchema>
// { a: string; b: number }
```

---

## Advanced Inference

### Recursive Types

```typescript
interface Category {
  name: string
  subcategories: Category[]
}

const categorySchema: z.ZodType<Category> = z.lazy(() =>
  z.object({
    name: z.string(),
    subcategories: z.array(categorySchema),
  })
)

type Category = z.infer<typeof categorySchema>
/*
{
  name: string
  subcategories: Category[]
}
*/
```

### Generic Schema Functions

```typescript
function createPaginatedSchema<T extends z.ZodTypeAny>(itemSchema: T) {
  return z.object({
    data: z.array(itemSchema),
    total: z.number(),
    page: z.number(),
    pageSize: z.number(),
  })
}

const userSchema = z.object({ id: z.string(), name: z.string() })
const paginatedUsersSchema = createPaginatedSchema(userSchema)

type PaginatedUsers = z.infer<typeof paginatedUsersSchema>
/*
{
  data: { id: string; name: string }[]
  total: number
  page: number
  pageSize: number
}
*/

// Generic API response wrapper
function createApiResponseSchema<T extends z.ZodTypeAny>(dataSchema: T) {
  return z.object({
    success: z.boolean(),
    data: dataSchema,
    error: z.string().optional(),
  })
}

const userResponseSchema = createApiResponseSchema(userSchema)
type UserResponse = z.infer<typeof userResponseSchema>
/*
{
  success: boolean
  data: { id: string; name: string }
  error?: string
}
*/
```

### Conditional Types

```typescript
const baseSchema = z.object({
  type: z.enum(["user", "admin"]),
})

// Discriminated union with conditional fields
const schema = z.discriminatedUnion("type", [
  baseSchema.extend({
    type: z.literal("user"),
    username: z.string(),
  }),
  baseSchema.extend({
    type: z.literal("admin"),
    username: z.string(),
    permissions: z.array(z.string()),
  }),
])

type Entity = z.infer<typeof schema>
/*
| { type: "user"; username: string }
| { type: "admin"; username: string; permissions: string[] }
*/

// Type narrowing
function handleEntity(entity: Entity) {
  if (entity.type === "admin") {
    // TypeScript knows entity has permissions
    console.log(entity.permissions)
  } else {
    // entity.permissions is not accessible here
  }
}
```

---

## Integration Patterns

### API Route Handlers

```typescript
// Next.js API route
import { z } from 'zod'
import { NextRequest, NextResponse } from 'next/server'

const createUserSchema = z.object({
  name: z.string().min(1),
  email: z.string().email(),
  age: z.number().int().positive(),
})

type CreateUserInput = z.infer<typeof createUserSchema>

export async function POST(request: NextRequest) {
  const body = await request.json()
  const result = createUserSchema.safeParse(body)

  if (!result.success) {
    return NextResponse.json(
      { error: result.error.format() },
      { status: 400 }
    )
  }

  // result.data is type-safe
  const user: CreateUserInput = result.data

  // Create user in database
  const created = await db.user.create({ data: user })

  return NextResponse.json(created)
}
```

### React Hook Form Integration

```typescript
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'

const formSchema = z.object({
  name: z.string().min(1, "Name is required"),
  email: z.string().email("Invalid email"),
  age: z.number().min(18, "Must be 18+"),
})

type FormData = z.infer<typeof formSchema>

function MyForm() {
  const { register, handleSubmit, formState: { errors } } = useForm<FormData>({
    resolver: zodResolver(formSchema),
  })

  const onSubmit = (data: FormData) => {
    // data is type-safe and validated
    console.log(data)
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <input {...register("name")} />
      {errors.name && <span>{errors.name.message}</span>}

      <input {...register("email")} />
      {errors.email && <span>{errors.email.message}</span>}

      <input type="number" {...register("age", { valueAsNumber: true })} />
      {errors.age && <span>{errors.age.message}</span>}

      <button type="submit">Submit</button>
    </form>
  )
}
```

### Type-Safe API Client

```typescript
// API schema definitions
const schemas = {
  getUser: z.object({
    id: z.string().uuid(),
    name: z.string(),
    email: z.string().email(),
  }),

  createUser: z.object({
    name: z.string(),
    email: z.string().email(),
  }),

  updateUser: z.object({
    name: z.string().optional(),
    email: z.string().email().optional(),
  }),
}

type User = z.infer<typeof schemas.getUser>
type CreateUser = z.infer<typeof schemas.createUser>
type UpdateUser = z.infer<typeof schemas.updateUser>

// Type-safe API client
class UserAPI {
  async getUser(id: string): Promise<User> {
    const response = await fetch(`/api/users/${id}`)
    const data = await response.json()
    return schemas.getUser.parse(data)
  }

  async createUser(input: CreateUser): Promise<User> {
    // Validate input before sending
    schemas.createUser.parse(input)

    const response = await fetch('/api/users', {
      method: 'POST',
      body: JSON.stringify(input),
    })
    const data = await response.json()
    return schemas.getUser.parse(data)
  }

  async updateUser(id: string, input: UpdateUser): Promise<User> {
    schemas.updateUser.parse(input)

    const response = await fetch(`/api/users/${id}`, {
      method: 'PATCH',
      body: JSON.stringify(input),
    })
    const data = await response.json()
    return schemas.getUser.parse(data)
  }
}
```

---

## Best Practices

### 1. Export Both Schema and Type

```typescript
// ✅ Good - Export both for reuse
export const userSchema = z.object({
  id: z.string(),
  name: z.string(),
})

export type User = z.infer<typeof userSchema>

// Usage
import { userSchema, type User } from './schemas'
```

### 2. Use Branded Types for Critical IDs

```typescript
// ✅ Good - Prevent mixing different ID types
const userIdSchema = z.string().uuid().brand<"UserId">()
const postIdSchema = z.string().uuid().brand<"PostId">()

// ❌ Bad - Easy to mix up IDs
const userIdSchema = z.string().uuid()
const postIdSchema = z.string().uuid()
```

### 3. Leverage Type Inference for DRY Code

```typescript
// ✅ Good - Single source of truth
const userSchema = z.object({ /* ... */ })
type User = z.infer<typeof userSchema>

// ❌ Bad - Duplicate definitions
interface User {
  // Manually typed interface
}
const userSchema = z.object({ /* Same fields again */ })
```

---

## AI Pair Programming Notes

**When to load this file:**
- Working with TypeScript and Zod
- Need type inference from schemas
- Building type-safe APIs
- Integrating with React Hook Form

**Typical questions:**
- "How do I get TypeScript types from Zod schemas?"
- "What's the difference between input and output types?"
- "How do I create branded types?"
- "How do I integrate Zod with React Hook Form?"

**Next steps:**
- [07-ADVANCED-SCHEMAS.md](./07-ADVANCED-SCHEMAS.md) - Complex schema patterns
- [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md) - Framework integration
- [02-SCHEMA-DEFINITION.md](./02-SCHEMA-DEFINITION.md) - Review schema basics

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1
