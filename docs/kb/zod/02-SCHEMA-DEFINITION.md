---
id: zod-02-schema-definition
topic: zod
file_role: core
profile: full
difficulty_level: beginner-to-intermediate
kb_version: 3.1
prerequisites: [zod-fundamentals, typescript-basics]
related_topics: [typescript, validation, type-safety]
embedding_keywords: [zod, schema, definition, primitives, objects, validation]
last_reviewed: 2025-11-16
---

# Zod - Schema Definition

## Purpose

Learn how to define comprehensive validation schemas using Zod's type-safe schema builders, from primitives to complex nested structures.

## Table of Contents

1. [Primitive Types](#primitive-types)
2. [Object Schemas](#object-schemas)
3. [Array Schemas](#array-schemas)
4. [Union and Intersection](#union-and-intersection)
5. [Optional and Nullable](#optional-and-nullable)
6. [Enum and Literal](#enum-and-literal)
7. [Common Patterns](#common-patterns)

---

## Primitive Types

### String Schemas

```typescript
import { z } from 'zod'

// Basic string
const nameSchema = z.string()

// With validation
const emailSchema = z.string().email()
const urlSchema = z.string().url()
const uuidSchema = z.string().uuid()

// Length constraints
const usernameSchema = z.string().min(3).max(20)
const exactLengthSchema = z.string().length(10)

// Pattern matching (regex)
const phoneSchema = z.string().regex(/^\+?[1-9]\d{1,14}$/)

// Built-in string validations
const schemas = {
  email: z.string().email(),
  url: z.string().url(),
  uuid: z.string().uuid(),
  cuid: z.string().cuid(),
  cuid2: z.string().cuid2(),
  ulid: z.string().ulid(),
  datetime: z.string().datetime(), // ISO 8601
  ip: z.string().ip(), // IPv4 or IPv6
  emoji: z.string().emoji(),
}

// Custom error messages
const customSchema = z.string().min(3, { message: "Must be at least 3 characters" })

// Transformations
const trimmedSchema = z.string().trim()
const lowercaseSchema = z.string().toLowerCase()
const uppercaseSchema = z.string().toUpperCase()
```

### Number Schemas

```typescript
// Basic number
const ageSchema = z.number()

// Integer validation
const integerSchema = z.number().int()

// Range constraints
const ratingSchema = z.number().min(1).max(5)
const positiveSchema = z.number().positive()
const negativeSchema = z.number().negative()
const nonNegativeSchema = z.number().nonnegative()
const nonPositiveSchema = z.number().nonpositive()

// Precision
const priceSchema = z.number().multipleOf(0.01) // 2 decimal places

// Finite (not Infinity or NaN)
const finiteSchema = z.number().finite()

// Safe integer (within Number.MIN_SAFE_INTEGER and MAX_SAFE_INTEGER)
const safeIntSchema = z.number().int().safe()
```

### Boolean Schemas

```typescript
// Basic boolean
const isActiveSchema = z.boolean()

// Coercion (convert truthy/falsy to boolean)
const coercedBooleanSchema = z.coerce.boolean()
// "true", "1", 1 → true
// "false", "0", 0, "" → false
```

### Date Schemas

```typescript
// Basic date
const birthdateSchema = z.date()

// Date constraints
const futureSchema = z.date().min(new Date())
const pastSchema = z.date().max(new Date())

const dateRangeSchema = z.date()
  .min(new Date("2020-01-01"))
  .max(new Date("2025-12-31"))

// Coerce string to date
const dateStringSchema = z.coerce.date()
// "2024-01-01" → Date object
```

### BigInt Schemas

```typescript
const bigIntSchema = z.bigint()

const positiveBigIntSchema = z.bigint().positive()
const bigIntRangeSchema = z.bigint().min(BigInt(0)).max(BigInt(100))
```

### Symbol and Other Primitives

```typescript
const symbolSchema = z.symbol()
const undefinedSchema = z.undefined()
const nullSchema = z.null()
const voidSchema = z.void() // Accepts undefined
const anySchema = z.any() // Accepts any value (avoid in production)
const unknownSchema = z.unknown() // Safer alternative to any
const neverSchema = z.never() // Never passes validation
```

---

## Object Schemas

### Basic Object Schema

```typescript
import { z } from 'zod'

const userSchema = z.object({
  id: z.string().uuid(),
  name: z.string().min(1),
  email: z.string().email(),
  age: z.number().int().positive(),
  isActive: z.boolean(),
})

// Infer TypeScript type
type User = z.infer<typeof userSchema>
/*
{
  id: string
  name: string
  email: string
  age: number
  isActive: boolean
}
*/

// Validate data
const result = userSchema.parse({
  id: "123e4567-e89b-12d3-a456-426614174000",
  name: "Alice",
  email: "alice@example.com",
  age: 30,
  isActive: true,
})
```

### Nested Objects

```typescript
const addressSchema = z.object({
  street: z.string(),
  city: z.string(),
  state: z.string(),
  zip: z.string().regex(/^\d{5}$/),
})

const userWithAddressSchema = z.object({
  name: z.string(),
  email: z.string().email(),
  address: addressSchema,
  shippingAddress: addressSchema.optional(),
})

type UserWithAddress = z.infer<typeof userWithAddressSchema>
/*
{
  name: string
  email: string
  address: {
    street: string
    city: string
    state: string
    zip: string
  }
  shippingAddress?: {
    street: string
    city: string
    state: string
    zip: string
  }
}
*/
```

### Object Methods

```typescript
const baseSchema = z.object({
  name: z.string(),
  email: z.string().email(),
})

// Extend schema (add fields)
const extendedSchema = baseSchema.extend({
  age: z.number(),
  role: z.string(),
})

// Merge schemas (combine two objects)
const schemaA = z.object({ a: z.string() })
const schemaB = z.object({ b: z.number() })
const mergedSchema = schemaA.merge(schemaB)

// Pick specific fields
const nameOnlySchema = userSchema.pick({ name: true })

// Omit specific fields
const userWithoutEmailSchema = userSchema.omit({ email: true })

// Partial (all fields optional)
const partialUserSchema = userSchema.partial()

// Required (all fields required)
const requiredSchema = partialUserSchema.required()

// Deep partial (recursive partial)
const deepPartialSchema = userSchema.deepPartial()

// Passthrough (allow extra keys)
const passthroughSchema = userSchema.passthrough()

// Strict (disallow extra keys)
const strictSchema = userSchema.strict()

// Strip (remove extra keys)
const stripSchema = userSchema.strip()

// Catchall (validate extra keys)
const catchallSchema = userSchema.catchall(z.string())
```

---

## Array Schemas

### Basic Arrays

```typescript
// Array of strings
const tagsSchema = z.array(z.string())

// Array of objects
const usersSchema = z.array(userSchema)

// Non-empty array
const nonEmptySchema = z.array(z.string()).nonempty()

// Length constraints
const fixedLengthSchema = z.array(z.number()).length(5)
const minLengthSchema = z.array(z.string()).min(1)
const maxLengthSchema = z.array(z.string()).max(10)
const rangeSchema = z.array(z.string()).min(1).max(100)
```

### Array Validations

```typescript
// Array with custom validation
const uniqueTagsSchema = z.array(z.string()).refine(
  (tags) => new Set(tags).size === tags.length,
  { message: "Tags must be unique" }
)

// Sorted array
const sortedNumbersSchema = z.array(z.number()).refine(
  (arr) => arr.every((val, i, array) => i === 0 || array[i - 1] <= val),
  { message: "Array must be sorted" }
)
```

### Tuple Schemas

```typescript
// Fixed-length array with specific types
const coordinatesSchema = z.tuple([z.number(), z.number()])
type Coordinates = z.infer<typeof coordinatesSchema> // [number, number]

// Tuple with rest elements
const csvRowSchema = z.tuple([z.string(), z.number()]).rest(z.string())
// First: string, Second: number, Rest: any number of strings

// Named tuple (for clarity)
const personTupleSchema = z.tuple([
  z.string(), // name
  z.number(), // age
  z.string().email(), // email
])
```

---

## Union and Intersection

### Union Types

```typescript
// Union of primitives
const idSchema = z.union([z.string(), z.number()])

// Discriminated union (recommended)
const shapeSchema = z.discriminatedUnion("kind", [
  z.object({ kind: z.literal("circle"), radius: z.number() }),
  z.object({ kind: z.literal("square"), sideLength: z.number() }),
  z.object({ kind: z.literal("rectangle"), width: z.number(), height: z.number() }),
])

type Shape = z.infer<typeof shapeSchema>
/*
| { kind: "circle"; radius: number }
| { kind: "square"; sideLength: number }
| { kind: "rectangle"; width: number; height: number }
*/

// Multiple possible types
const resultSchema = z.union([
  z.object({ success: z.literal(true), data: z.any() }),
  z.object({ success: z.literal(false), error: z.string() }),
])
```

### Intersection Types

```typescript
const nameSchema = z.object({ name: z.string() })
const ageSchema = z.object({ age: z.number() })

// Intersection (both schemas must pass)
const personSchema = z.intersection(nameSchema, ageSchema)

// Alternative: merge
const personMergedSchema = nameSchema.merge(ageSchema)

type Person = z.infer<typeof personSchema>
// { name: string; age: number }
```

---

## Optional and Nullable

### Optional Fields

```typescript
// Optional field (value | undefined)
const userSchema = z.object({
  name: z.string(),
  nickname: z.string().optional(),
})

type User = z.infer<typeof userSchema>
// { name: string; nickname?: string | undefined }

// With default value
const configSchema = z.object({
  port: z.number().default(3000),
  host: z.string().default("localhost"),
})

const config = configSchema.parse({})
// { port: 3000, host: "localhost" }
```

### Nullable Fields

```typescript
// Nullable field (value | null)
const userSchema = z.object({
  name: z.string(),
  middleName: z.string().nullable(),
})

type User = z.infer<typeof userSchema>
// { name: string; middleName: string | null }

// Nullish (value | null | undefined)
const schema = z.string().nullish()

// Optional with default
const schema = z.string().optional().default("default")
```

---

## Enum and Literal

### Enum Schemas

```typescript
// String enum
const roleSchema = z.enum(["admin", "user", "guest"])
type Role = z.infer<typeof roleSchema> // "admin" | "user" | "guest"

// Native enum
enum Color {
  Red = "RED",
  Green = "GREEN",
  Blue = "BLUE",
}

const colorSchema = z.nativeEnum(Color)
type ColorType = z.infer<typeof colorSchema> // Color
```

### Literal Schemas

```typescript
// Single literal value
const trueSchema = z.literal(true)
const adminSchema = z.literal("admin")
const piSchema = z.literal(3.14)

// Union of literals (alternative to enum)
const statusSchema = z.union([
  z.literal("pending"),
  z.literal("approved"),
  z.literal("rejected"),
])
```

---

## Common Patterns

### Recursive Schemas

```typescript
// Self-referencing schema
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

// Tree structure
interface TreeNode {
  value: number
  children: TreeNode[]
}

const treeSchema: z.ZodType<TreeNode> = z.lazy(() =>
  z.object({
    value: z.number(),
    children: z.array(treeSchema),
  })
)
```

### Record Schemas

```typescript
// Key-value pairs (like { [key: string]: value })
const stringRecordSchema = z.record(z.string())
const numberRecordSchema = z.record(z.number())

// Record with specific value type
const userMapSchema = z.record(z.string(), userSchema)
type UserMap = z.infer<typeof userMapSchema>
// { [key: string]: User }

// Record with key validation
const envSchema = z.record(
  z.string().regex(/^[A-Z_]+$/), // Keys must be uppercase
  z.string()
)
```

### Map and Set Schemas

```typescript
// Map schema
const userMapSchema = z.map(z.string(), userSchema)
type UserMap = z.infer<typeof userMapSchema> // Map<string, User>

// Set schema
const tagsSetSchema = z.set(z.string())
type TagsSet = z.infer<typeof tagsSetSchema> // Set<string>

// Set with size constraints
const limitedSetSchema = z.set(z.number()).min(1).max(10)
```

### Promise Schemas

```typescript
// Promise that resolves to a string
const promiseSchema = z.promise(z.string())

// Async function return type
async function fetchUser(): Promise<User> {
  return await fetch("/api/user").then(r => r.json())
}

const userPromiseSchema = z.promise(userSchema)
```

---

## Best Practices

### 1. Use Descriptive Names

```typescript
// ✅ Good
const emailSchema = z.string().email()
const positiveIntegerSchema = z.number().int().positive()

// ❌ Bad
const schema1 = z.string()
const schema2 = z.number()
```

### 2. Extract Reusable Schemas

```typescript
// ✅ Good - Reusable components
const emailSchema = z.string().email()
const uuidSchema = z.string().uuid()

const userSchema = z.object({
  id: uuidSchema,
  email: emailSchema,
})

const postSchema = z.object({
  id: uuidSchema,
  authorEmail: emailSchema,
})

// ❌ Bad - Duplicated definitions
const userSchema = z.object({
  id: z.string().uuid(),
  email: z.string().email(),
})

const postSchema = z.object({
  id: z.string().uuid(),
  authorEmail: z.string().email(),
})
```

### 3. Provide Custom Error Messages

```typescript
// ✅ Good
const passwordSchema = z.string()
  .min(8, "Password must be at least 8 characters")
  .regex(/[A-Z]/, "Password must contain an uppercase letter")
  .regex(/[0-9]/, "Password must contain a number")

// ❌ Bad
const passwordSchema = z.string().min(8).regex(/[A-Z]/).regex(/[0-9]/)
```

---

## AI Pair Programming Notes

**When to load this file:**
- Defining validation schemas
- Learning Zod schema syntax
- Creating type-safe data models
- Validating API inputs/outputs

**Typical questions:**
- "How do I define a schema for X?"
- "How do I validate nested objects?"
- "How do I make fields optional?"
- "What's the difference between optional() and nullable()?"

**Next steps:**
- [03-VALIDATION.md](./03-VALIDATION.md) - Parsing and validation
- [04-TYPE-INFERENCE.md](./04-TYPE-INFERENCE.md) - TypeScript type inference
- [07-ADVANCED-SCHEMAS.md](./07-ADVANCED-SCHEMAS.md) - Complex schema patterns

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1
