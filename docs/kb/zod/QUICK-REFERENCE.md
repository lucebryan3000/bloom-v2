---
id: zod-quick-reference
topic: zod
file_role: quickref
profile: full
difficulty_level: all-levels
kb_version: 3.1
prerequisites: []
related_topics: [validation, typescript, schema]
embedding_keywords: [zod, quick-reference, cheat-sheet, syntax]
last_reviewed: 2025-11-16
---

# Zod - Quick Reference

One-page cheat sheet for Zod validation library.

## Installation

```bash
npm install zod
# or
yarn add zod
# or
pnpm add zod
```

---

## Basic Syntax

### Import

```typescript
import { z } from 'zod'
```

### Create Schema

```typescript
const schema = z.object({ name: z.string() })
```

### Validate Data

```typescript
// Throws on error
const data = schema.parse(input)

// Returns result object
const result = schema.safeParse(input)
if (result.success) {
  console.log(result.data)
} else {
  console.error(result.error)
}
```

### Type Inference

```typescript
type MyType = z.infer<typeof schema>
```

---

## Primitive Types

```typescript
// String
z.string()                    // any string
z.string().min(3)             // min length 3
z.string().max(10)            // max length 10
z.string().length(5)          // exactly 5 chars
z.string().email()            // valid email
z.string().url()              // valid URL
z.string().uuid()             // valid UUID
z.string().regex(/^[A-Z]/)    // matches regex
z.string().startsWith('foo')  // starts with 'foo'
z.string().endsWith('bar')    // ends with 'bar'
z.string().trim()             // trim whitespace
z.string().toLowerCase()      // convert to lowercase
z.string().toUpperCase()      // convert to uppercase

// Number
z.number()                    // any number
z.number().int()              // integer only
z.number().positive()         // > 0
z.number().negative()         // < 0
z.number().nonnegative()      // >= 0
z.number().nonpositive()      // <= 0
z.number().min(5)             // >= 5
z.number().max(10)            // <= 10
z.number().multipleOf(5)      // divisible by 5
z.number().finite()           // not Infinity or -Infinity

// Boolean
z.boolean()                   // true or false

// Date
z.date()                      // Date object
z.date().min(new Date('2020-01-01'))
z.date().max(new Date('2030-12-31'))

// BigInt
z.bigint()                    // bigint type

// Literal
z.literal('foo')              // exactly 'foo'
z.literal(42)                 // exactly 42
z.literal(true)               // exactly true

// Null & Undefined
z.null()                      // null
z.undefined()                 // undefined
z.void()                      // undefined (alias)

// Any & Unknown
z.any()                       // any value (no validation)
z.unknown()                   // any value (must validate before use)

// Never
z.never()                     // no value is valid
```

---

## Object Schemas

```typescript
// Basic object
const user = z.object({
  name: z.string(),
  age: z.number(),
})

// Nested objects
const user = z.object({
  name: z.string(),
  address: z.object({
    street: z.string(),
    city: z.string(),
  }),
})

// Optional fields
const user = z.object({
  name: z.string(),
  email: z.string().optional(),  // string | undefined
})

// Nullable fields
const user = z.object({
  name: z.string(),
  deletedAt: z.date().nullable(),  // Date | null
})

// Optional + Nullable
const user = z.object({
  middleName: z.string().nullish(),  // string | null | undefined
})

// Default values
const user = z.object({
  name: z.string(),
  role: z.string().default('user'),
})

// Object operations
userSchema.pick({ name: true })       // only 'name'
userSchema.omit({ age: true })        // everything except 'age'
userSchema.partial()                  // all fields optional
userSchema.required()                 // all fields required
userSchema.extend({ email: z.string() })  // add fields
userSchema.merge(otherSchema)         // merge schemas
userSchema.passthrough()              // allow unknown keys
userSchema.strict()                   // disallow unknown keys
userSchema.strip()                    // remove unknown keys (default)
```

---

## Array Schemas

```typescript
// Array of strings
z.array(z.string())

// Min/max length
z.array(z.string()).min(1)
z.array(z.string()).max(10)
z.array(z.string()).length(5)
z.array(z.string()).nonempty()  // at least one element

// Tuple (fixed length)
z.tuple([z.string(), z.number()])  // [string, number]

// Tuple with rest
z.tuple([z.string(), z.number()]).rest(z.boolean())
// [string, number, ...boolean[]]
```

---

## Union & Intersection

```typescript
// Union (OR)
z.union([z.string(), z.number()])  // string | number
z.string().or(z.number())          // same as above

// Discriminated Union (better performance)
z.discriminatedUnion('type', [
  z.object({ type: z.literal('a'), value: z.string() }),
  z.object({ type: z.literal('b'), value: z.number() }),
])

// Intersection (AND)
z.intersection(
  z.object({ name: z.string() }),
  z.object({ age: z.number() })
)
// { name: string } & { age: number }
```

---

## Enum

```typescript
// Native enum
enum Role { Admin, User }
z.nativeEnum(Role)

// Zod enum
z.enum(['admin', 'user', 'guest'])

// Get values
const roles = z.enum(['admin', 'user'])
roles.enum.admin  // 'admin'
roles.options     // ['admin', 'user']
```

---

## Transformations

```typescript
// Transform
z.string().transform((val) => val.length)
// Input: string, Output: number

// Preprocess (before validation)
z.preprocess((val) => String(val), z.string())

// Pipe (chain schemas)
z.string()
  .transform((s) => s.trim())
  .pipe(z.string().email())

// Coercion
z.coerce.string()   // convert to string
z.coerce.number()   // convert to number
z.coerce.boolean()  // convert to boolean
z.coerce.date()     // convert to date
```

---

## Refinements (Custom Validation)

```typescript
// Basic refinement
z.string().refine(
  (val) => val.length > 3,
  'Must be longer than 3 characters'
)

// Multiple refinements
z.string()
  .refine((val) => val.length > 3, 'Too short')
  .refine((val) => /[A-Z]/.test(val), 'Must have uppercase')

// Async refinement
z.string().email().refine(
  async (email) => {
    const exists = await checkEmail(email)
    return !exists
  },
  'Email already taken'
)

// superRefine (advanced)
z.object({
  password: z.string(),
  confirm: z.string(),
}).superRefine((data, ctx) => {
  if (data.password !== data.confirm) {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      message: 'Passwords do not match',
      path: ['confirm'],
    })
  }
})
```

---

## Error Handling

```typescript
// Parse (throws ZodError)
try {
  const data = schema.parse(input)
} catch (error) {
  if (error instanceof z.ZodError) {
    console.log(error.issues)
  }
}

// SafeParse (returns result)
const result = schema.safeParse(input)
if (!result.success) {
  console.log(result.error.issues)
  console.log(result.error.format())
  console.log(result.error.flatten())
}

// Error formatting
error.format()
// { name: { _errors: ['Required'] }, age: { _errors: ['Expected number'] } }

error.flatten()
// { fieldErrors: { name: ['Required'], age: ['Expected number'] }, formErrors: [] }

// Custom error messages
z.string({ required_error: 'Name is required' })
z.string().min(3, { message: 'Must be at least 3 chars' })

// Error map
const customErrorMap: z.ZodErrorMap = (issue, ctx) => {
  if (issue.code === z.ZodIssueCode.invalid_type) {
    return { message: 'Custom type error message' }
  }
  return { message: ctx.defaultError }
}

z.setErrorMap(customErrorMap)
```

---

## Type Inference

```typescript
// Basic inference
const schema = z.object({ name: z.string() })
type Schema = z.infer<typeof schema>  // { name: string }

// Input type (before transform)
const schema = z.string().transform((s) => s.length)
type Input = z.input<typeof schema>   // string
type Output = z.output<typeof schema> // number

// Branded types
const UserId = z.string().uuid().brand<'UserId'>()
type UserId = z.infer<typeof UserId>  // string & { __brand: 'UserId' }
```

---

## Advanced Patterns

### Recursive Schemas

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
```

### Generic Factory

```typescript
function createPaginatedSchema<T extends z.ZodTypeAny>(itemSchema: T) {
  return z.object({
    data: z.array(itemSchema),
    total: z.number(),
    page: z.number(),
  })
}

const users = createPaginatedSchema(userSchema)
```

### Conditional Validation

```typescript
const schema = z.object({
  type: z.enum(['email', 'phone']),
  email: z.string().email().optional(),
  phone: z.string().optional(),
}).superRefine((data, ctx) => {
  if (data.type === 'email' && !data.email) {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      message: 'Email is required',
      path: ['email'],
    })
  }
})
```

---

## Common Patterns

### Form Validation (React Hook Form)

```typescript
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'

const schema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
})

const { register, handleSubmit, formState: { errors } } = useForm({
  resolver: zodResolver(schema),
})
```

### API Validation (Next.js)

```typescript
const schema = z.object({
  name: z.string(),
  email: z.string().email(),
})

export async function POST(request: Request) {
  const body = await request.json()
  const result = schema.safeParse(body)

  if (!result.success) {
    return Response.json({ error: result.error.flatten() }, { status: 400 })
  }

  // result.data is type-safe
  const user = await createUser(result.data)
  return Response.json({ user })
}
```

### Environment Variables

```typescript
const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']),
  DATABASE_URL: z.string().url(),
  PORT: z.coerce.number().default(3000),
})

export const env = envSchema.parse(process.env)
```

### tRPC

```typescript
import { z } from 'zod'
import { initTRPC } from '@trpc/server'

const t = initTRPC.create()

export const appRouter = t.router({
  getUser: t.procedure
    .input(z.object({ id: z.string().uuid() }))
    .query(({ input }) => {
      return db.user.findUnique({ where: { id: input.id } })
    }),
})
```

---

## Performance Tips

```typescript
// ✅ Use discriminated unions (faster)
z.discriminatedUnion('type', [
  z.object({ type: z.literal('a'), data: z.string() }),
  z.object({ type: z.literal('b'), data: z.number() }),
])

// ❌ Avoid regular unions (slower)
z.union([
  z.object({ type: z.literal('a'), data: z.string() }),
  z.object({ type: z.literal('b'), data: z.number() }),
])

// ✅ Reuse compiled schemas
const schema = z.object({ name: z.string() })
function validate(data: unknown) {
  return schema.safeParse(data)  // ✅ Fast
}

// ❌ Don't recreate schemas
function validate(data: unknown) {
  const schema = z.object({ name: z.string() })  // ❌ Slow
  return schema.safeParse(data)
}

// ✅ Use safeParse in production
const result = schema.safeParse(data)

// ❌ Don't use parse (throws errors)
const data = schema.parse(input)  // May crash app
```

---

## Testing

```typescript
import { describe, it, expect } from 'vitest'

describe('userSchema', () => {
  it('validates correct data', () => {
    const result = userSchema.safeParse({
      name: 'Alice',
      email: 'alice@example.com',
    })

    expect(result.success).toBe(true)
    if (result.success) {
      expect(result.data.name).toBe('Alice')
    }
  })

  it('rejects invalid data', () => {
    const result = userSchema.safeParse({
      name: '',
      email: 'invalid',
    })

    expect(result.success).toBe(false)
    if (!result.success) {
      expect(result.error.issues.length).toBeGreaterThan(0)
    }
  })
})
```

---

## Cheat Sheet Summary

| Category | Pattern | Example |
|----------|---------|---------|
| **Validation** | Parse | `schema.parse(data)` |
| | Safe parse | `schema.safeParse(data)` |
| **Types** | Inference | `type T = z.infer<typeof schema>` |
| | Input type | `type I = z.input<typeof schema>` |
| | Output type | `type O = z.output<typeof schema>` |
| **Primitives** | String | `z.string()` |
| | Number | `z.number()` |
| | Boolean | `z.boolean()` |
| | Date | `z.date()` |
| **Objects** | Basic | `z.object({ name: z.string() })` |
| | Optional | `z.string().optional()` |
| | Nullable | `z.string().nullable()` |
| | Default | `z.string().default('foo')` |
| **Arrays** | Array | `z.array(z.string())` |
| | Tuple | `z.tuple([z.string(), z.number()])` |
| **Unions** | Basic union | `z.union([z.string(), z.number()])` |
| | Discriminated | `z.discriminatedUnion('type', [...])` |
| | Enum | `z.enum(['a', 'b', 'c'])` |
| **Transform** | Transform | `z.string().transform(fn)` |
| | Preprocess | `z.preprocess(fn, schema)` |
| | Pipe | `schema.pipe(otherSchema)` |
| | Coerce | `z.coerce.number()` |
| **Validation** | Built-in | `.email()`, `.url()`, `.uuid()` |
| | Custom | `.refine(fn, msg)` |
| | Async | `.refine(async fn, msg)` |
| **Errors** | Format | `error.format()` |
| | Flatten | `error.flatten()` |
| | Custom | `z.setErrorMap(customMap)` |
| **Advanced** | Recursive | `z.lazy(() => schema)` |
| | Branded | `z.string().brand<'Brand'>()` |

---

## Quick Links

### Core Documentation
- **[README.md](./README.md)** - Complete overview
- **[INDEX.md](./INDEX.md)** - Navigation and problem-based quick find
- **[01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md)** - Getting started

### Common Tasks
- **Form validation** → [10-INTEGRATIONS.md](./10-INTEGRATIONS.md) → React Hook Form
- **API validation** → [03-VALIDATION.md](./03-VALIDATION.md) + [10-INTEGRATIONS.md](./10-INTEGRATIONS.md)
- **Type inference** → [04-TYPE-INFERENCE.md](./04-TYPE-INFERENCE.md)
- **Error handling** → [05-ERROR-HANDLING.md](./05-ERROR-HANDLING.md)
- **Transformations** → [06-TRANSFORMATIONS.md](./06-TRANSFORMATIONS.md)
- **Advanced schemas** → [07-ADVANCED-SCHEMAS.md](./07-ADVANCED-SCHEMAS.md)
- **Performance** → [08-PERFORMANCE.md](./08-PERFORMANCE.md)
- **Testing** → [09-TESTING.md](./09-TESTING.md)
- **Production** → [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md)

### Framework Integration
- **React Hook Form** → [10-INTEGRATIONS.md](./10-INTEGRATIONS.md) → React Hook Form
- **tRPC** → [10-INTEGRATIONS.md](./10-INTEGRATIONS.md) → tRPC
- **Next.js** → [10-INTEGRATIONS.md](./10-INTEGRATIONS.md) → Next.js
- **Prisma** → [10-INTEGRATIONS.md](./10-INTEGRATIONS.md) → Prisma

### External Resources
- [Official Docs](https://zod.dev)
- [GitHub](https://github.com/colinhacks/zod)
- [API Reference](https://zod.dev/api)

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1
