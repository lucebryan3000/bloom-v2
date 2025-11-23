---
id: zod-03-validation
topic: zod
file_role: core
profile: full
difficulty_level: beginner-to-intermediate
kb_version: 3.1
prerequisites: [zod-fundamentals, zod-schema-definition]
related_topics: [validation, parsing, error-handling]
embedding_keywords: [zod, validation, parse, safeParse, error-handling]
last_reviewed: 2025-11-16
---

# Zod - Validation and Parsing

## Purpose

Master validation and parsing techniques in Zod, including error handling, transformation, and async validation patterns.

## Table of Contents

1. [Parse Methods](#parse-methods)
2. [Error Handling](#error-handling)
3. [Transformations](#transformations)
4. [Refinements](#refinements)
5. [Async Validation](#async-validation)
6. [Preprocessing](#preprocessing)
7. [Common Patterns](#common-patterns)

---

## Parse Methods

### parse() - Throw on Error

```typescript
import { z } from 'zod'

const userSchema = z.object({
  name: z.string(),
  age: z.number(),
})

// ✅ Valid data - returns parsed object
const user = userSchema.parse({ name: "Alice", age: 30 })
// user: { name: string, age: number }

// ❌ Invalid data - throws ZodError
try {
  userSchema.parse({ name: "Bob", age: "thirty" })
} catch (error) {
  if (error instanceof z.ZodError) {
    console.error(error.errors)
  }
}
```

### safeParse() - Return Result Object

```typescript
// Recommended for most use cases
const result = userSchema.safeParse({ name: "Alice", age: 30 })

if (result.success) {
  console.log(result.data) // { name: "Alice", age: 30 }
} else {
  console.error(result.error.errors)
}

// Type narrowing
if (!result.success) {
  // result.error is ZodError
  console.log(result.error.format())
  return
}

// result.data is guaranteed valid
const user = result.data
```

### parseAsync() and safeParseAsync()

```typescript
const asyncSchema = z.object({
  email: z.string().email(),
  username: z.string().refine(async (username) => {
    const exists = await checkUsernameExists(username)
    return !exists
  }, "Username already taken"),
})

// Async parse (throws)
const user = await asyncSchema.parseAsync(data)

// Async safe parse (returns result)
const result = await asyncSchema.safeParseAsync(data)

if (result.success) {
  console.log(result.data)
} else {
  console.error(result.error.errors)
}
```

---

## Error Handling

### ZodError Structure

```typescript
const userSchema = z.object({
  name: z.string().min(3),
  age: z.number().positive(),
  email: z.string().email(),
})

const result = userSchema.safeParse({
  name: "AB",
  age: -5,
  email: "invalid",
})

if (!result.success) {
  const error = result.error

  // Array of issues
  error.issues.forEach((issue) => {
    console.log({
      path: issue.path, // ["name"], ["age"], ["email"]
      message: issue.message,
      code: issue.code,
    })
  })

  // Formatted errors
  const formatted = error.format()
  /*
  {
    name: { _errors: ["String must contain at least 3 character(s)"] },
    age: { _errors: ["Number must be greater than 0"] },
    email: { _errors: ["Invalid email"] },
    _errors: []
  }
  */

  // Flat errors
  const flat = error.flatten()
  /*
  {
    formErrors: [],
    fieldErrors: {
      name: ["String must contain at least 3 character(s)"],
      age: ["Number must be greater than 0"],
      email: ["Invalid email"]
    }
  }
  */
}
```

### Custom Error Messages

```typescript
// Per-validation custom message
const schema = z.string().min(5, { message: "Too short!" })

// Custom error map
const customErrorMap: z.ZodErrorMap = (issue, ctx) => {
  if (issue.code === z.ZodIssueCode.too_small) {
    return { message: `Must be at least ${issue.minimum} characters` }
  }
  if (issue.code === z.ZodIssueCode.invalid_string) {
    if (issue.validation === "email") {
      return { message: "Please enter a valid email address" }
    }
  }
  return { message: ctx.defaultError }
}

// Use custom error map
const result = schema.safeParse("abc", { errorMap: customErrorMap })

// Set global error map
z.setErrorMap(customErrorMap)
```

### Validation Result Patterns

```typescript
// Pattern 1: Early return
function validateUser(data: unknown) {
  const result = userSchema.safeParse(data)

  if (!result.success) {
    return { error: result.error.format() }
  }

  return { data: result.data }
}

// Pattern 2: Throw for invalid
function parseUserOrThrow(data: unknown): User {
  return userSchema.parse(data)
}

// Pattern 3: With error transformation
function validateWithCustomErrors(data: unknown) {
  const result = userSchema.safeParse(data)

  if (!result.success) {
    const errors = result.error.flatten().fieldErrors
    return { success: false, errors }
  }

  return { success: true, data: result.data }
}
```

---

## Transformations

### transform() - Transform Parsed Data

```typescript
// Transform string to number
const stringToNumberSchema = z.string().transform((val) => parseInt(val, 10))

const result = stringToNumberSchema.parse("123")
// result: 123 (number)

// Transform and validate
const dateSchema = z.string().transform((str) => new Date(str)).pipe(
  z.date().min(new Date("2020-01-01"))
)

// Chained transformations
const schema = z.string()
  .transform((s) => s.trim())
  .transform((s) => s.toLowerCase())
  .transform((s) => s.split(","))

const result = schema.parse("  APPLE, BANANA, CHERRY  ")
// result: ["apple", "banana", "cherry"]
```

### preprocess() - Preprocess Before Validation

```typescript
// Trim strings before validation
const trimmedStringSchema = z.preprocess(
  (val) => (typeof val === "string" ? val.trim() : val),
  z.string().min(1)
)

trimmedStringSchema.parse("  hello  ") // "hello" ✅
trimmedStringSchema.parse("     ") // ❌ Error: too short

// Parse JSON string
const jsonSchema = z.preprocess(
  (val) => (typeof val === "string" ? JSON.parse(val) : val),
  z.object({ name: z.string() })
)

jsonSchema.parse('{"name":"Alice"}') // { name: "Alice" } ✅

// Coerce to date
const dateSchema = z.preprocess((arg) => {
  if (typeof arg === "string" || arg instanceof Date) return new Date(arg)
  return arg
}, z.date())
```

### pipe() - Chain Schemas

```typescript
// Validate then transform
const schema = z.string().pipe(z.coerce.number()).pipe(z.number().positive())

schema.parse("123") // 123 ✅
schema.parse("-5") // ❌ Error: must be positive

// Multi-step transformation
const emailSchema = z.string()
  .transform((s) => s.trim())
  .pipe(z.string().toLowerCase())
  .pipe(z.string().email())

emailSchema.parse("  ALICE@EXAMPLE.COM  ") // "alice@example.com" ✅
```

---

## Refinements

### refine() - Custom Validation

```typescript
// Single refinement
const passwordSchema = z.string().refine(
  (password) => password.length >= 8,
  { message: "Password must be at least 8 characters" }
)

// Multiple refinements
const strongPasswordSchema = z.string()
  .refine((val) => val.length >= 8, "Must be at least 8 characters")
  .refine((val) => /[A-Z]/.test(val), "Must contain uppercase letter")
  .refine((val) => /[a-z]/.test(val), "Must contain lowercase letter")
  .refine((val) => /[0-9]/.test(val), "Must contain number")
  .refine((val) => /[^A-Za-z0-9]/.test(val), "Must contain special character")

// Object-level refinement
const passwordConfirmSchema = z.object({
  password: z.string().min(8),
  confirm: z.string().min(8),
}).refine((data) => data.password === data.confirm, {
  message: "Passwords must match",
  path: ["confirm"], // Error path
})

// Multiple refinements on object
const userSchema = z.object({
  startDate: z.date(),
  endDate: z.date(),
}).refine((data) => data.endDate > data.startDate, {
  message: "End date must be after start date",
  path: ["endDate"],
})
```

### superRefine() - Advanced Validation

```typescript
// Add multiple issues
const schema = z.object({
  password: z.string(),
  confirm: z.string(),
}).superRefine((data, ctx) => {
  if (data.password !== data.confirm) {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      message: "Passwords do not match",
      path: ["confirm"],
    })
  }

  if (data.password.length < 8) {
    ctx.addIssue({
      code: z.ZodIssueCode.too_small,
      minimum: 8,
      type: "string",
      inclusive: true,
      message: "Password too short",
      path: ["password"],
    })
  }
})

// Conditional validation
const schema = z.object({
  type: z.enum(["email", "phone"]),
  contact: z.string(),
}).superRefine((data, ctx) => {
  if (data.type === "email" && !z.string().email().safeParse(data.contact).success) {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      message: "Invalid email address",
      path: ["contact"],
    })
  }

  if (data.type === "phone" && !z.string().regex(/^\d{10}$/).safeParse(data.contact).success) {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      message: "Invalid phone number (must be 10 digits)",
      path: ["contact"],
    })
  }
})
```

---

## Async Validation

### Async Refinements

```typescript
// Check if email is unique
const emailSchema = z.string().email().refine(async (email) => {
  const exists = await checkEmailExists(email)
  return !exists
}, "Email already in use")

// Check username availability
const usernameSchema = z.string().min(3).refine(async (username) => {
  const response = await fetch(`/api/check-username?username=${username}`)
  const { available } = await response.json()
  return available
}, "Username is taken")

// Async object validation
const registrationSchema = z.object({
  email: z.string().email().refine(async (email) => {
    return await isEmailAvailable(email)
  }, "Email already registered"),
  username: z.string().refine(async (username) => {
    return await isUsernameAvailable(username)
  }, "Username already taken"),
})

// Use with parseAsync
const result = await registrationSchema.safeParseAsync({
  email: "alice@example.com",
  username: "alice123",
})
```

### Async Transforms

```typescript
// Fetch related data during validation
const userIdSchema = z.string().uuid().transform(async (id) => {
  const user = await fetchUser(id)
  return user
})

const result = await userIdSchema.parseAsync("123e4567-e89b-12d3-a456-426614174000")
// result: User object

// Enrich data
const productSchema = z.object({
  productId: z.string(),
  quantity: z.number(),
}).transform(async (data) => {
  const product = await fetchProduct(data.productId)
  return {
    ...data,
    productName: product.name,
    unitPrice: product.price,
    totalPrice: product.price * data.quantity,
  }
})
```

---

## Preprocessing

### Common Preprocessing Patterns

```typescript
// Trim all strings
const trimStrings = (val: unknown) => {
  if (typeof val === "string") return val.trim()
  if (Array.isArray(val)) return val.map(trimStrings)
  if (typeof val === "object" && val !== null) {
    return Object.fromEntries(
      Object.entries(val).map(([k, v]) => [k, trimStrings(v)])
    )
  }
  return val
}

const schema = z.preprocess(trimStrings, z.object({
  name: z.string().min(1),
  tags: z.array(z.string()),
}))

// Normalize dates
const normalizeDateSchema = z.preprocess((arg) => {
  if (typeof arg === "string" || typeof arg === "number") {
    return new Date(arg)
  }
  return arg
}, z.date())

// Handle empty strings as undefined
const optionalStringSchema = z.preprocess((val) => {
  if (val === "") return undefined
  return val
}, z.string().optional())
```

---

## Common Patterns

### Form Validation

```typescript
const formSchema = z.object({
  name: z.string().min(1, "Name is required"),
  email: z.string().email("Invalid email"),
  age: z.coerce.number().min(18, "Must be 18 or older"),
  terms: z.boolean().refine((val) => val === true, "Must accept terms"),
})

function handleSubmit(formData: FormData) {
  const data = Object.fromEntries(formData)
  const result = formSchema.safeParse(data)

  if (!result.success) {
    const errors = result.error.flatten().fieldErrors
    return { errors }
  }

  return { success: true, data: result.data }
}
```

### API Response Validation

```typescript
const apiResponseSchema = z.object({
  success: z.boolean(),
  data: z.array(z.object({
    id: z.number(),
    name: z.string(),
    createdAt: z.coerce.date(),
  })),
  meta: z.object({
    total: z.number(),
    page: z.number(),
  }),
})

async function fetchData() {
  const response = await fetch("/api/data")
  const json = await response.json()

  const result = apiResponseSchema.safeParse(json)

  if (!result.success) {
    throw new Error("Invalid API response")
  }

  return result.data
}
```

### Environment Variables

```typescript
const envSchema = z.object({
  NODE_ENV: z.enum(["development", "production", "test"]),
  PORT: z.coerce.number().default(3000),
  DATABASE_URL: z.string().url(),
  API_KEY: z.string().min(1),
  LOG_LEVEL: z.enum(["debug", "info", "warn", "error"]).default("info"),
})

const env = envSchema.parse(process.env)
// Type-safe environment variables
```

---

## Best Practices

### 1. Use safeParse for User Input

```typescript
// ✅ Good - Handle errors gracefully
const result = userSchema.safeParse(userInput)
if (!result.success) {
  return { error: result.error.format() }
}

// ❌ Bad - May crash application
const user = userSchema.parse(userInput)
```

### 2. Provide Meaningful Error Messages

```typescript
// ✅ Good
const schema = z.string().min(8, "Password must be at least 8 characters")

// ❌ Bad
const schema = z.string().min(8)
```

### 3. Use Transformations Sparingly

```typescript
// ✅ Good - Transform when necessary
const dateSchema = z.string().transform((s) => new Date(s))

// ⚠️ Consider - Complex transformations may belong in application logic
const schema = z.object({
  items: z.array(z.object({ price: z.number() }))
}).transform((data) => ({
  ...data,
  total: data.items.reduce((sum, item) => sum + item.price, 0),
  tax: data.items.reduce((sum, item) => sum + item.price, 0) * 0.1,
  // ... complex business logic
}))
```

---

## AI Pair Programming Notes

**When to load this file:**
- Validating user input
- Handling form submissions
- API response validation
- Error handling strategies

**Typical questions:**
- "How do I validate form data?"
- "What's the difference between parse and safeParse?"
- "How do I customize error messages?"
- "How do I do async validation?"

**Next steps:**
- [05-ERROR-HANDLING.md](./05-ERROR-HANDLING.md) - Advanced error handling
- [06-TRANSFORMATIONS.md](./06-TRANSFORMATIONS.md) - Data transformation patterns
- [08-PERFORMANCE.md](./08-PERFORMANCE.md) - Validation performance

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1
