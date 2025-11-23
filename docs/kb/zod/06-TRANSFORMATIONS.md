---
id: zod-06-transformations
topic: zod
file_role: practical
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [zod-fundamentals, zod-validation]
related_topics: [data-transformation, preprocessing, pipelines]
embedding_keywords: [zod, transform, preprocess, pipe, coerce]
last_reviewed: 2025-11-16
---

# Zod - Transformations and Preprocessing

## Purpose

Master data transformation techniques in Zod, including transform(), preprocess(), pipe(), coercion, and building transformation pipelines.

## Table of Contents

1. [Basic Transformations](#basic-transformations)
2. [Preprocessing](#preprocessing)
3. [Piping Schemas](#piping-schemas)
4. [Coercion](#coercion)
5. [Transformation Pipelines](#transformation-pipelines)
6. [Common Patterns](#common-patterns)

---

## Basic Transformations

### transform() Method

```typescript
import { z } from 'zod'

// String to number
const stringToNumber = z.string().transform((val) => parseInt(val, 10))
stringToNumber.parse("42") // 42 (number)

// Trim and lowercase
const normalizedString = z.string()
  .transform((s) => s.trim())
  .transform((s) => s.toLowerCase())

normalizedString.parse("  HELLO  ") // "hello"

// Parse JSON
const jsonSchema = z.string().transform((str) => JSON.parse(str))
jsonSchema.parse('{"name":"Alice"}') // { name: "Alice" }

// Date string to Date object
const dateSchema = z.string().transform((str) => new Date(str))
dateSchema.parse("2024-01-01") // Date object
```

### Transform with Validation

```typescript
// Transform then validate result
const positiveNumberSchema = z.string()
  .transform((val) => parseInt(val, 10))
  .pipe(z.number().positive())

positiveNumberSchema.parse("42") // 42 ✅
positiveNumberSchema.parse("-5") // ❌ Error: must be positive

// Multi-step with validation at each step
const schema = z.string()
  .min(1, "Cannot be empty")
  .transform((s) => s.trim())
  .transform((s) => parseInt(s, 10))
  .pipe(z.number().positive())
```

---

## Preprocessing

### preprocess() - Modify Before Validation

```typescript
// Trim strings before validation
const trimmedString = z.preprocess(
  (val) => (typeof val === "string" ? val.trim() : val),
  z.string().min(1)
)

trimmedString.parse("  hello  ") // "hello" ✅
trimmedString.parse("     ") // ❌ Error: too short

// Convert empty string to undefined
const optionalString = z.preprocess(
  (val) => (val === "" ? undefined : val),
  z.string().optional()
)

optionalString.parse("") // undefined
optionalString.parse("hello") // "hello"

// Parse JSON before validation
const jsonObject = z.preprocess(
  (val) => (typeof val === "string" ? JSON.parse(val) : val),
  z.object({ name: z.string() })
)

jsonObject.parse('{"name":"Alice"}') // { name: "Alice" }
```

### Preprocessing Objects

```typescript
// Recursive trim all strings in object
function deepTrim(val: unknown): unknown {
  if (typeof val === "string") return val.trim()
  if (Array.isArray(val)) return val.map(deepTrim)
  if (typeof val === "object" && val !== null) {
    return Object.fromEntries(
      Object.entries(val).map(([k, v]) => [k, deepTrim(v)])
    )
  }
  return val
}

const schema = z.preprocess(
  deepTrim,
  z.object({
    name: z.string(),
    tags: z.array(z.string()),
  })
)
```

---

## Piping Schemas

### pipe() - Chain Validations

```typescript
// Validate string, then convert to number, then validate number
const schema = z.string()
  .regex(/^\d+$/)
  .pipe(z.coerce.number())
  .pipe(z.number().positive())

schema.parse("42") // 42 ✅
schema.parse("0") // ❌ Error: must be positive
schema.parse("abc") // ❌ Error: regex

// Multi-stage transformation
const emailSchema = z.string()
  .transform((s) => s.trim())
  .pipe(z.string().toLowerCase())
  .pipe(z.string().email())

emailSchema.parse("  ALICE@EXAMPLE.COM  ") // "alice@example.com"
```

### Complex Pipes

```typescript
// Date validation pipeline
const dateSchema = z.string()
  .datetime() // Validate ISO 8601 format
  .pipe(z.coerce.date()) // Convert to Date
  .pipe(z.date().min(new Date("2020-01-01"))) // Validate date range

// URL validation and parsing
const urlSchema = z.string()
  .url()
  .transform((url) => new URL(url))
  .transform((url) => ({
    protocol: url.protocol,
    hostname: url.hostname,
    pathname: url.pathname,
  }))
```

---

## Coercion

### z.coerce - Automatic Type Conversion

```typescript
// Coerce to string
z.coerce.string().parse(42) // "42"
z.coerce.string().parse(true) // "true"
z.coerce.string().parse(null) // "null"

// Coerce to number
z.coerce.number().parse("42") // 42
z.coerce.number().parse("3.14") // 3.14
z.coerce.number().parse(true) // 1
z.coerce.number().parse(false) // 0

// Coerce to boolean
z.coerce.boolean().parse("true") // true
z.coerce.boolean().parse("false") // false
z.coerce.boolean().parse(1) // true
z.coerce.boolean().parse(0) // false
z.coerce.boolean().parse("") // false

// Coerce to date
z.coerce.date().parse("2024-01-01") // Date object
z.coerce.date().parse(1704067200000) // Date from timestamp
z.coerce.date().parse(new Date()) // Passthrough
```

### Coercion in Schemas

```typescript
const formSchema = z.object({
  name: z.string(),
  age: z.coerce.number().int().positive(),
  isActive: z.coerce.boolean(),
  birthdate: z.coerce.date(),
})

// Form data (all strings) automatically converted
formSchema.parse({
  name: "Alice",
  age: "30", // Converted to 30
  isActive: "true", // Converted to true
  birthdate: "1994-01-01", // Converted to Date
})
```

---

## Transformation Pipelines

### Building Complex Pipelines

```typescript
// CSV parsing pipeline
const csvRowSchema = z.string()
  .transform((row) => row.split(","))
  .pipe(z.array(z.string()))
  .transform((arr) => arr.map((s) => s.trim()))
  .pipe(z.tuple([z.string(), z.coerce.number(), z.string().email()]))

csvRowSchema.parse("Alice,30,alice@example.com")
// ["Alice", 30, "alice@example.com"]

// API response pipeline
const apiSchema = z.string()
  .transform((json) => JSON.parse(json))
  .pipe(z.object({
    data: z.array(z.object({
      id: z.number(),
      created_at: z.string(),
    })),
  }))
  .transform((obj) => obj.data)
  .transform((arr) => arr.map(item => ({
    ...item,
    createdAt: new Date(item.created_at),
  })))
```

### Conditional Transformations

```typescript
// Transform based on input
const schema = z.object({
  type: z.enum(["celsius", "fahrenheit"]),
  value: z.number(),
}).transform((data) => {
  if (data.type === "fahrenheit") {
    return {
      celsius: ((data.value - 32) * 5) / 9,
      fahrenheit: data.value,
    }
  }
  return {
    celsius: data.value,
    fahrenheit: (data.value * 9) / 5 + 32,
  }
})

schema.parse({ type: "celsius", value: 0 })
// { celsius: 0, fahrenheit: 32 }
```

---

## Common Patterns

### Form Data Normalization

```typescript
const formSchema = z.object({
  email: z.preprocess(
    (val) => typeof val === "string" ? val.trim().toLowerCase() : val,
    z.string().email()
  ),
  phone: z.preprocess(
    (val) => typeof val === "string" ? val.replace(/\D/g, "") : val,
    z.string().regex(/^\d{10}$/)
  ),
  zipCode: z.preprocess(
    (val) => typeof val === "string" ? val.replace(/\s/g, "") : val,
    z.string().regex(/^\d{5}$/)
  ),
})
```

### API Response Enrichment

```typescript
const userSchema = z.object({
  id: z.string(),
  name: z.string(),
  created_at: z.string(),
}).transform((user) => ({
  ...user,
  createdAt: new Date(user.created_at),
  displayName: user.name.toUpperCase(),
  slug: user.name.toLowerCase().replace(/\s+/g, "-"),
}))
```

### Sanitization

```typescript
const sanitizedHtml = z.string()
  .transform((html) => html.replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, ""))
  .transform((html) => html.trim())

const sanitizedInput = z.string()
  .transform((s) => s.replace(/[<>]/g, ""))
  .transform((s) => s.trim())
  .pipe(z.string().min(1).max(1000))
```

---

## Best Practices

### 1. Keep Transformations Simple

```typescript
// ✅ Good - Clear single-purpose transforms
const schema = z.string()
  .transform((s) => s.trim())
  .transform((s) => s.toLowerCase())

// ❌ Bad - Complex business logic in transform
const schema = z.string().transform((s) => {
  // 50 lines of complex logic...
})
```

### 2. Validate Before Transform

```typescript
// ✅ Good - Validate then transform
const schema = z.string()
  .min(1)
  .email()
  .transform((s) => s.toLowerCase())

// ⚠️ Less safe - Transform then validate
const schema = z.string()
  .transform((s) => s.toLowerCase())
  .pipe(z.string().email())
```

### 3. Use Coercion for Simple Type Conversion

```typescript
// ✅ Good - Use coercion
z.coerce.number()

// ❌ Unnecessary - Manual transform
z.string().transform((s) => Number(s))
```

---

## AI Pair Programming Notes

**When to load this file:**
- Need to transform validated data
- Processing form inputs
- Normalizing API responses
- Data sanitization

**Typical questions:**
- "How do I transform data after validation?"
- "What's the difference between transform and preprocess?"
- "How do I use pipe?"
- "How do I coerce types?"

**Next steps:**
- [03-VALIDATION.md](./03-VALIDATION.md) - Validation patterns
- [07-ADVANCED-SCHEMAS.md](./07-ADVANCED-SCHEMAS.md) - Advanced techniques

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1
