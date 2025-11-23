---
id: zod-07-advanced-schemas
topic: zod
file_role: advanced
profile: full
difficulty_level: advanced
kb_version: 3.1
prerequisites: [zod-fundamentals, zod-schema-definition, zod-validation]
related_topics: [advanced-patterns, generics, recursive-types]
embedding_keywords: [zod, advanced, recursive, discriminated-union, generic, lazy]
last_reviewed: 2025-11-16
---

# Zod - Advanced Schema Patterns

## Purpose

Advanced schema patterns including recursive types, discriminated unions, generic schemas, conditional schemas, and complex validation patterns.

## Table of Contents

1. [Recursive Schemas](#recursive-schemas)
2. [Discriminated Unions](#discriminated-unions)
3. [Generic Schemas](#generic-schemas)
4. [Conditional Schemas](#conditional-schemas)
5. [Schema Composition](#schema-composition)
6. [Advanced Patterns](#advanced-patterns)

---

## Recursive Schemas

### Self-Referencing Types

```typescript
import { z } from 'zod'

// Tree structure
interface TreeNode {
  value: number
  left?: TreeNode
  right?: TreeNode
}

const treeSchema: z.ZodType<TreeNode> = z.lazy(() =>
  z.object({
    value: z.number(),
    left: treeSchema.optional(),
    right: treeSchema.optional(),
  })
)

// Category with subcategories
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

// File system
interface FileSystemNode {
  name: string
  type: "file" | "directory"
  children?: FileSystemNode[]
}

const fsSchema: z.ZodType<FileSystemNode> = z.lazy(() =>
  z.object({
    name: z.string(),
    type: z.enum(["file", "directory"]),
    children: z.array(fsSchema).optional(),
  })
)
```

### Mutually Recursive Types

```typescript
interface Person {
  name: string
  friends: Person[]
  bestFriend?: Person
}

const personSchema: z.ZodType<Person> = z.lazy(() =>
  z.object({
    name: z.string(),
    friends: z.array(personSchema),
    bestFriend: personSchema.optional(),
  })
)
```

---

## Discriminated Unions

### Basic Discriminated Union

```typescript
const shapeSchema = z.discriminatedUnion("kind", [
  z.object({
    kind: z.literal("circle"),
    radius: z.number(),
  }),
  z.object({
    kind: z.literal("square"),
    sideLength: z.number(),
  }),
  z.object({
    kind: z.literal("rectangle"),
    width: z.number(),
    height: z.number(),
  }),
])

type Shape = z.infer<typeof shapeSchema>

// Type narrowing
function getArea(shape: Shape): number {
  switch (shape.kind) {
    case "circle":
      return Math.PI * shape.radius ** 2
    case "square":
      return shape.sideLength ** 2
    case "rectangle":
      return shape.width * shape.height
  }
}
```

### Complex Discriminated Union

```typescript
const apiResponseSchema = z.discriminatedUnion("status", [
  z.object({
    status: z.literal("success"),
    data: z.any(),
    timestamp: z.date(),
  }),
  z.object({
    status: z.literal("error"),
    error: z.object({
      code: z.string(),
      message: z.string(),
    }),
    timestamp: z.date(),
  }),
  z.object({
    status: z.literal("pending"),
    progress: z.number().min(0).max(100),
    timestamp: z.date(),
  }),
])
```

---

## Generic Schemas

### Reusable Generic Schemas

```typescript
// Generic paginated response
function createPaginatedSchema<T extends z.ZodTypeAny>(itemSchema: T) {
  return z.object({
    data: z.array(itemSchema),
    total: z.number(),
    page: z.number(),
    pageSize: z.number(),
    hasNext: z.boolean(),
    hasPrev: z.boolean(),
  })
}

const userSchema = z.object({
  id: z.string(),
  name: z.string(),
})

const paginatedUsers = createPaginatedSchema(userSchema)
type PaginatedUsers = z.infer<typeof paginatedUsers>

// Generic API response wrapper
function createApiResponse<T extends z.ZodTypeAny>(dataSchema: T) {
  return z.object({
    success: z.boolean(),
    data: dataSchema.optional(),
    error: z.string().optional(),
    metadata: z.object({
      timestamp: z.date(),
      version: z.string(),
    }),
  })
}

const userResponse = createApiResponse(userSchema)
```

### Generic Factory Pattern

```typescript
function createCRUDSchemas<T extends z.ZodObject<any>>(baseSchema: T) {
  return {
    create: baseSchema.omit({ id: true, createdAt: true, updatedAt: true }),
    update: baseSchema.omit({ id: true, createdAt: true }).partial(),
    read: baseSchema,
    list: z.object({
      items: z.array(baseSchema),
      total: z.number(),
    }),
  }
}

const userSchemas = createCRUDSchemas(
  z.object({
    id: z.string().uuid(),
    name: z.string(),
    email: z.string().email(),
    createdAt: z.date(),
    updatedAt: z.date(),
  })
)

type CreateUser = z.infer<typeof userSchemas.create>
type UpdateUser = z.infer<typeof userSchemas.update>
```

---

## Conditional Schemas

### Dependent Validation

```typescript
const contactSchema = z.object({
  contactMethod: z.enum(["email", "phone", "mail"]),
  email: z.string().email().optional(),
  phone: z.string().optional(),
  address: z.object({
    street: z.string(),
    city: z.string(),
    zip: z.string(),
  }).optional(),
}).superRefine((data, ctx) => {
  if (data.contactMethod === "email" && !data.email) {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      message: "Email is required when contact method is email",
      path: ["email"],
    })
  }

  if (data.contactMethod === "phone" && !data.phone) {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      message: "Phone is required when contact method is phone",
      path: ["phone"],
    })
  }

  if (data.contactMethod === "mail" && !data.address) {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      message: "Address is required when contact method is mail",
      path: ["address"],
    })
  }
})
```

### Dynamic Schema Based on Input

```typescript
function createUserSchema(role: "admin" | "user") {
  const baseSchema = z.object({
    name: z.string(),
    email: z.string().email(),
  })

  if (role === "admin") {
    return baseSchema.extend({
      permissions: z.array(z.string()),
      departmentId: z.string().uuid(),
    })
  }

  return baseSchema
}

const adminSchema = createUserSchema("admin")
const userSchema = createUserSchema("user")
```

---

## Schema Composition

### Mixins Pattern

```typescript
// Base schemas (mixins)
const timestamps = z.object({
  createdAt: z.date(),
  updatedAt: z.date(),
})

const softDelete = z.object({
  deletedAt: z.date().nullable(),
  isDeleted: z.boolean().default(false),
})

const auditable = z.object({
  createdBy: z.string().uuid(),
  updatedBy: z.string().uuid(),
})

// Compose schemas
const userSchema = z.object({
  id: z.string().uuid(),
  name: z.string(),
  email: z.string().email(),
})
  .merge(timestamps)
  .merge(softDelete)
  .merge(auditable)
```

### Inheritance Pattern

```typescript
const baseEntitySchema = z.object({
  id: z.string().uuid(),
  createdAt: z.date(),
  updatedAt: z.date(),
})

const userSchema = baseEntitySchema.extend({
  name: z.string(),
  email: z.string().email(),
  role: z.enum(["admin", "user"]),
})

const postSchema = baseEntitySchema.extend({
  title: z.string(),
  content: z.string(),
  authorId: z.string().uuid(),
})
```

---

## Advanced Patterns

### Builder Pattern

```typescript
class SchemaBuilder<T extends z.ZodTypeAny> {
  constructor(private schema: T) {}

  addTimestamps() {
    this.schema = this.schema.extend({
      createdAt: z.date(),
      updatedAt: z.date(),
    }) as T
    return this
  }

  addSoftDelete() {
    this.schema = this.schema.extend({
      deletedAt: z.date().nullable(),
    }) as T
    return this
  }

  build() {
    return this.schema
  }
}

const userSchema = new SchemaBuilder(
  z.object({
    id: z.string(),
    name: z.string(),
  })
)
  .addTimestamps()
  .addSoftDelete()
  .build()
```

### Branded Types for Domain Logic

```typescript
const UserId = z.string().uuid().brand<"UserId">()
const PostId = z.string().uuid().brand<"PostId">()
const Email = z.string().email().brand<"Email">()

type UserId = z.infer<typeof UserId>
type PostId = z.infer<typeof PostId>
type Email = z.infer<typeof Email>

// Prevents accidental mixing
function getUser(id: UserId) { /* ... */ }
function getPost(id: PostId) { /* ... */ }

const userId = UserId.parse("...")
const postId = PostId.parse("...")

getUser(userId) // ✅
// getUser(postId) // ❌ Type error
```

---

## Best Practices

### 1. Use Discriminated Unions for Variants

```typescript
// ✅ Good - Type-safe and performant
z.discriminatedUnion("type", [
  z.object({ type: z.literal("a"), /* ... */ }),
  z.object({ type: z.literal("b"), /* ... */ }),
])

// ❌ Less ideal - Slower validation
z.union([
  z.object({ type: z.literal("a"), /* ... */ }),
  z.object({ type: z.literal("b"), /* ... */ }),
])
```

### 2. Extract Reusable Schemas

```typescript
// ✅ Good
const userIdSchema = z.string().uuid()
const emailSchema = z.string().email()

const userSchema = z.object({
  id: userIdSchema,
  email: emailSchema,
})

// ❌ Bad - Duplicated
const userSchema = z.object({
  id: z.string().uuid(),
  email: z.string().email(),
})
```

---

## AI Pair Programming Notes

**When to load this file:**
- Building complex data models
- Need recursive types
- Working with discriminated unions
- Creating reusable schema factories

**Typical questions:**
- "How do I create recursive schemas?"
- "How do I handle polymorphic data?"
- "How do I create generic schema factories?"
- "How do I compose schemas?"

**Next steps:**
- [02-SCHEMA-DEFINITION.md](./02-SCHEMA-DEFINITION.md) - Schema basics
- [08-PERFORMANCE.md](./08-PERFORMANCE.md) - Performance optimization

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1
