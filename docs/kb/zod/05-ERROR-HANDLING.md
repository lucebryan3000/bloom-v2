---
id: zod-05-error-handling
topic: zod
file_role: practical
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [zod-fundamentals, zod-validation]
related_topics: [error-handling, validation, forms]
embedding_keywords: [zod, errors, ZodError, format, flatten, custom-errors]
last_reviewed: 2025-11-16
---

# Zod - Error Handling

## Purpose

Advanced error handling patterns in Zod, including custom error messages, error formatting, internationalization, and production-ready error handling strategies.

## Table of Contents

1. [ZodError Structure](#zoderror-structure)
2. [Error Formatting](#error-formatting)
3. [Custom Error Messages](#custom-error-messages)
4. [Error Maps](#error-maps)
5. [Form Error Handling](#form-error-handling)
6. [Production Patterns](#production-patterns)

---

## ZodError Structure

### Understanding ZodError

```typescript
import { z } from 'zod'

const userSchema = z.object({
  name: z.string().min(3),
  age: z.number().positive(),
  email: z.string().email(),
})

try {
  userSchema.parse({
    name: "AB",
    age: -5,
    email: "invalid",
  })
} catch (error) {
  if (error instanceof z.ZodError) {
    console.log(error.issues)
    /*
    [
      {
        code: "too_small",
        minimum: 3,
        type: "string",
        inclusive: true,
        message: "String must contain at least 3 character(s)",
        path: ["name"]
      },
      {
        code: "too_small",
        minimum: 0,
        type: "number",
        inclusive: false,
        message: "Number must be greater than 0",
        path: ["age"]
      },
      {
        code: "invalid_string",
        validation: "email",
        message: "Invalid email",
        path: ["email"]
      }
    ]
    */
  }
}
```

### Issue Codes

```typescript
// Common ZodIssueCode values
const issueCodes = {
  invalid_type: "Expected type doesn't match received",
  invalid_literal: "Literal value doesn't match",
  custom: "Custom validation failed",
  invalid_union: "None of union options matched",
  invalid_union_discriminator: "Discriminator value invalid",
  invalid_enum_value: "Value not in enum",
  unrecognized_keys: "Extra keys in object",
  invalid_arguments: "Invalid function arguments",
  invalid_return_type: "Invalid function return type",
  invalid_date: "Invalid date",
  invalid_string: "String validation failed (email, url, etc.)",
  too_small: "Value too small/short",
  too_big: "Value too big/long",
  invalid_intersection_types: "Intersection types don't match",
  not_multiple_of: "Number not multiple of specified value",
  not_finite: "Number is not finite",
}
```

---

## Error Formatting

### format() - Nested Object

```typescript
const result = userSchema.safeParse({
  name: "AB",
  age: -5,
  email: "invalid",
})

if (!result.success) {
  const formatted = result.error.format()
  console.log(formatted)
  /*
  {
    _errors: [],
    name: { _errors: ["String must contain at least 3 character(s)"] },
    age: { _errors: ["Number must be greater than 0"] },
    email: { _errors: ["Invalid email"] }
  }
  */

  // Access specific field errors
  console.log(formatted.name._errors[0])
  // "String must contain at least 3 character(s)"
}
```

### flatten() - Flat Structure

```typescript
if (!result.success) {
  const flat = result.error.flatten()
  console.log(flat)
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

  // Easier to iterate
  Object.entries(flat.fieldErrors).forEach(([field, errors]) => {
    console.log(`${field}: ${errors.join(", ")}`)
  })
}
```

### Custom Formatting

```typescript
function formatErrors(error: z.ZodError) {
  return error.issues.reduce((acc, issue) => {
    const path = issue.path.join(".")
    if (!acc[path]) {
      acc[path] = []
    }
    acc[path].push(issue.message)
    return acc
  }, {} as Record<string, string[]>)
}

const errors = formatErrors(result.error)
// { "name": ["..."], "age": ["..."], "email": ["..."] }
```

---

## Custom Error Messages

### Per-Field Messages

```typescript
const schema = z.object({
  username: z.string()
    .min(3, "Username must be at least 3 characters")
    .max(20, "Username must be at most 20 characters"),

  password: z.string()
    .min(8, "Password must be at least 8 characters")
    .regex(/[A-Z]/, "Password must contain an uppercase letter")
    .regex(/[0-9]/, "Password must contain a number"),

  email: z.string().email("Please enter a valid email address"),

  age: z.number({
    required_error: "Age is required",
    invalid_type_error: "Age must be a number",
  }).min(18, "You must be at least 18 years old"),
})
```

### Refinement Messages

```typescript
const passwordSchema = z.object({
  password: z.string(),
  confirm: z.string(),
}).refine((data) => data.password === data.confirm, {
  message: "Passwords don't match",
  path: ["confirm"], // Error attached to confirm field
})

const dateRangeSchema = z.object({
  startDate: z.date(),
  endDate: z.date(),
}).refine((data) => data.endDate > data.startDate, {
  message: "End date must be after start date",
  path: ["endDate"],
})
```

---

## Error Maps

### Custom Error Map

```typescript
const customErrorMap: z.ZodErrorMap = (issue, ctx) => {
  // Handle specific error types
  if (issue.code === z.ZodIssueCode.invalid_type) {
    if (issue.expected === "string") {
      return { message: "This field must be text" }
    }
    if (issue.expected === "number") {
      return { message: "This field must be a number" }
    }
  }

  if (issue.code === z.ZodIssueCode.too_small) {
    if (issue.type === "string") {
      return { message: `Must be at least ${issue.minimum} characters` }
    }
  }

  if (issue.code === z.ZodIssueCode.invalid_string) {
    if (issue.validation === "email") {
      return { message: "Please enter a valid email address" }
    }
    if (issue.validation === "url") {
      return { message: "Please enter a valid URL" }
    }
  }

  // Fall back to default message
  return { message: ctx.defaultError }
}

// Use per-parse
const result = schema.safeParse(data, { errorMap: customErrorMap })

// Set globally
z.setErrorMap(customErrorMap)
```

### Internationalization (i18n)

```typescript
// translations.ts
const translations = {
  en: {
    too_small_string: "Must be at least {minimum} characters",
    invalid_email: "Invalid email address",
    required: "This field is required",
  },
  es: {
    too_small_string: "Debe tener al menos {minimum} caracteres",
    invalid_email: "Dirección de correo electrónico no válida",
    required: "Este campo es obligatorio",
  },
}

function createErrorMap(locale: 'en' | 'es'): z.ZodErrorMap {
  return (issue, ctx) => {
    const t = translations[locale]

    if (issue.code === z.ZodIssueCode.too_small && issue.type === "string") {
      return {
        message: t.too_small_string.replace("{minimum}", String(issue.minimum))
      }
    }

    if (issue.code === z.ZodIssueCode.invalid_string && issue.validation === "email") {
      return { message: t.invalid_email }
    }

    return { message: ctx.defaultError }
  }
}

// Usage
const errorMap = createErrorMap('es')
const result = schema.safeParse(data, { errorMap })
```

---

## Form Error Handling

### React Form Integration

```typescript
import { useState } from 'react'
import { z } from 'zod'

const formSchema = z.object({
  name: z.string().min(1, "Name is required"),
  email: z.string().email("Invalid email"),
  age: z.coerce.number().min(18, "Must be 18+"),
})

type FormData = z.infer<typeof formSchema>
type FormErrors = Partial<Record<keyof FormData, string>>

function MyForm() {
  const [errors, setErrors] = useState<FormErrors>({})

  const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    const formData = new FormData(e.currentTarget)
    const data = Object.fromEntries(formData)

    const result = formSchema.safeParse(data)

    if (!result.success) {
      const fieldErrors = result.error.flatten().fieldErrors
      const formattedErrors: FormErrors = {}

      Object.entries(fieldErrors).forEach(([key, messages]) => {
        formattedErrors[key as keyof FormData] = messages[0]
      })

      setErrors(formattedErrors)
      return
    }

    setErrors({})
    console.log("Valid data:", result.data)
  }

  return (
    <form onSubmit={handleSubmit}>
      <input name="name" />
      {errors.name && <span className="error">{errors.name}</span>}

      <input name="email" />
      {errors.email && <span className="error">{errors.email}</span>}

      <input name="age" type="number" />
      {errors.age && <span className="error">{errors.age}</span>}

      <button type="submit">Submit</button>
    </form>
  )
}
```

### Field-Level Validation

```typescript
function validateField<T>(schema: z.ZodType<T>, value: unknown): string | null {
  const result = schema.safeParse(value)
  if (!result.success) {
    return result.error.issues[0]?.message || "Invalid value"
  }
  return null
}

// Usage
const emailError = validateField(z.string().email(), "invalid@")
// "Invalid email"
```

---

## Production Patterns

### API Error Response

```typescript
function handleValidationError(error: z.ZodError) {
  return {
    status: 400,
    body: {
      error: "Validation failed",
      details: error.flatten().fieldErrors,
    }
  }
}

// Next.js API route
export async function POST(request: Request) {
  const body = await request.json()
  const result = schema.safeParse(body)

  if (!result.success) {
    return Response.json(
      handleValidationError(result.error),
      { status: 400 }
    )
  }

  // Process valid data
  return Response.json({ success: true })
}
```

### Logging Validation Errors

```typescript
function logValidationError(error: z.ZodError, context: any) {
  console.error("Validation error:", {
    context,
    errors: error.flatten(),
    timestamp: new Date().toISOString(),
  })
}

const result = schema.safeParse(data)
if (!result.success) {
  logValidationError(result.error, { endpoint: "/api/users", userId: "123" })
}
```

---

## Best Practices

### 1. Always Use safeParse for User Input

```typescript
// ✅ Good
const result = schema.safeParse(userInput)
if (!result.success) {
  return { error: result.error.format() }
}

// ❌ Bad - May crash
const data = schema.parse(userInput)
```

### 2. Provide User-Friendly Messages

```typescript
// ✅ Good
z.string().min(8, "Password must be at least 8 characters")

// ❌ Bad
z.string().min(8)
```

### 3. Use Flatten for Forms

```typescript
// ✅ Good - Easy to display
const errors = result.error.flatten().fieldErrors

// ⚠️ Less ideal for forms
const errors = result.error.format()
```

---

## AI Pair Programming Notes

**When to load this file:**
- Handling validation errors
- Building forms with error display
- API error responses
- Internationalization

**Typical questions:**
- "How do I display Zod errors in forms?"
- "How do I customize error messages?"
- "How do I format errors for API responses?"
- "How do I internationalize error messages?"

**Next steps:**
- [03-VALIDATION.md](./03-VALIDATION.md) - Review validation patterns
- [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md) - Framework integration

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1
