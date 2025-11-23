---
id: zod-09-testing
topic: zod
file_role: practical
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [zod-fundamentals, zod-validation]
related_topics: [testing, jest, vitest]
embedding_keywords: [zod, testing, jest, vitest, test, validation-testing]
last_reviewed: 2025-11-16
---

# Zod - Testing

## Purpose

Comprehensive testing strategies for Zod schemas including unit testing, integration testing, property-based testing, and testing best practices.

## Table of Contents

1. [Testing Schemas](#testing-schemas)
2. [Testing Validations](#testing-validations)
3. [Testing Transformations](#testing-transformations)
4. [Testing Error Messages](#testing-error-messages)
5. [Integration Testing](#integration-testing)
6. [Best Practices](#best-practices)

---

## Testing Schemas

### Basic Schema Tests

```typescript
import { z } from 'zod'
import { describe, it, expect } from 'vitest'

const userSchema = z.object({
  name: z.string().min(1),
  email: z.string().email(),
  age: z.number().int().positive(),
})

describe('userSchema', () => {
  it('validates correct user data', () => {
    const validUser = {
      name: "Alice",
      email: "alice@example.com",
      age: 30,
    }

    const result = userSchema.safeParse(validUser)
    expect(result.success).toBe(true)
    if (result.success) {
      expect(result.data).toEqual(validUser)
    }
  })

  it('rejects invalid data', () => {
    const invalidUser = {
      name: "",
      email: "invalid",
      age: -5,
    }

    const result = userSchema.safeParse(invalidUser)
    expect(result.success).toBe(false)
  })
})
```

### Test Type Inference

```typescript
describe('userSchema types', () => {
  it('infers correct TypeScript type', () => {
    type User = z.infer<typeof userSchema>

    const user: User = {
      name: "Alice",
      email: "alice@example.com",
      age: 30,
    }

    // TypeScript compilation is the test
    expect(userSchema.parse(user)).toEqual(user)
  })
})
```

---

## Testing Validations

### Field Validation Tests

```typescript
describe('userSchema field validations', () => {
  describe('name field', () => {
    it('rejects empty string', () => {
      const result = userSchema.safeParse({
        name: "",
        email: "alice@example.com",
        age: 30,
      })

      expect(result.success).toBe(false)
      if (!result.success) {
        expect(result.error.issues[0].path).toEqual(['name'])
        expect(result.error.issues[0].message).toContain('1 character')
      }
    })
  })

  describe('email field', () => {
    it.each([
      'invalid',
      'test@',
      '@example.com',
      'test@example',
    ])('rejects invalid email: %s', (invalidEmail) => {
      const result = userSchema.safeParse({
        name: "Alice",
        email: invalidEmail,
        age: 30,
      })

      expect(result.success).toBe(false)
    })

    it.each([
      'test@example.com',
      'user+tag@domain.co.uk',
      'user.name@example.com',
    ])('accepts valid email: %s', (validEmail) => {
      const result = userSchema.safeParse({
        name: "Alice",
        email: validEmail,
        age: 30,
      })

      expect(result.success).toBe(true)
    })
  })

  describe('age field', () => {
    it.each([-1, 0, -100])('rejects non-positive age: %i', (age) => {
      const result = userSchema.safeParse({
        name: "Alice",
        email: "alice@example.com",
        age,
      })

      expect(result.success).toBe(false)
    })

    it('rejects decimal age', () => {
      const result = userSchema.safeParse({
        name: "Alice",
        email: "alice@example.com",
        age: 30.5,
      })

      expect(result.success).toBe(false)
    })
  })
})
```

---

## Testing Transformations

### Transform Tests

```typescript
const dateSchema = z.string().transform((str) => new Date(str))

describe('dateSchema transformation', () => {
  it('transforms valid date string to Date object', () => {
    const result = dateSchema.parse("2024-01-01")

    expect(result).toBeInstanceOf(Date)
    expect(result.getFullYear()).toBe(2024)
    expect(result.getMonth()).toBe(0)
  })

  it('handles ISO 8601 format', () => {
    const result = dateSchema.parse("2024-01-01T12:00:00Z")

    expect(result).toBeInstanceOf(Date)
    expect(result.toISOString()).toBe("2024-01-01T12:00:00.000Z")
  })
})
```

### Pipeline Tests

```typescript
const normalizedEmailSchema = z.string()
  .transform((s) => s.trim())
  .pipe(z.string().toLowerCase())
  .pipe(z.string().email())

describe('normalizedEmailSchema', () => {
  it('trims and lowercases email', () => {
    const result = normalizedEmailSchema.parse("  ALICE@EXAMPLE.COM  ")

    expect(result).toBe("alice@example.com")
  })

  it('rejects invalid email after normalization', () => {
    expect(() => {
      normalizedEmailSchema.parse("  invalid  ")
    }).toThrow()
  })
})
```

---

## Testing Error Messages

### Custom Error Message Tests

```typescript
const passwordSchema = z.string()
  .min(8, "Password must be at least 8 characters")
  .regex(/[A-Z]/, "Password must contain an uppercase letter")

describe('passwordSchema error messages', () => {
  it('shows length error for short password', () => {
    const result = passwordSchema.safeParse("short")

    expect(result.success).toBe(false)
    if (!result.success) {
      expect(result.error.issues[0].message).toBe(
        "Password must be at least 8 characters"
      )
    }
  })

  it('shows uppercase error for lowercase password', () => {
    const result = passwordSchema.safeParse("lowercase123")

    expect(result.success).toBe(false)
    if (!result.success) {
      const uppercaseError = result.error.issues.find(
        issue => issue.message === "Password must contain an uppercase letter"
      )
      expect(uppercaseError).toBeDefined()
    }
  })
})
```

### Error Format Tests

```typescript
describe('error formatting', () => {
  it('formats errors with flatten()', () => {
    const result = userSchema.safeParse({
      name: "",
      email: "invalid",
      age: -5,
    })

    expect(result.success).toBe(false)
    if (!result.success) {
      const flat = result.error.flatten()

      expect(flat.fieldErrors.name).toBeDefined()
      expect(flat.fieldErrors.email).toBeDefined()
      expect(flat.fieldErrors.age).toBeDefined()
    }
  })
})
```

---

## Integration Testing

### API Route Testing

```typescript
import { describe, it, expect, beforeEach, afterEach } from 'vitest'
import { createServer } from 'http'

const createUserSchema = z.object({
  name: z.string().min(1),
  email: z.string().email(),
})

describe('POST /api/users', () => {
  let server: any

  beforeEach(() => {
    server = createServer(async (req, res) => {
      if (req.url === '/api/users' && req.method === 'POST') {
        let body = ''
        req.on('data', chunk => body += chunk)
        req.on('end', () => {
          const data = JSON.parse(body)
          const result = createUserSchema.safeParse(data)

          if (!result.success) {
            res.writeHead(400, { 'Content-Type': 'application/json' })
            res.end(JSON.stringify({ error: result.error.flatten() }))
            return
          }

          res.writeHead(201, { 'Content-Type': 'application/json' })
          res.end(JSON.stringify({ user: result.data }))
        })
      }
    })
    server.listen(3001)
  })

  afterEach(() => {
    server.close()
  })

  it('creates user with valid data', async () => {
    const response = await fetch('http://localhost:3001/api/users', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: "Alice",
        email: "alice@example.com",
      }),
    })

    expect(response.status).toBe(201)
    const body = await response.json()
    expect(body.user).toEqual({
      name: "Alice",
      email: "alice@example.com",
    })
  })

  it('rejects invalid data with 400', async () => {
    const response = await fetch('http://localhost:3001/api/users', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: "",
        email: "invalid",
      }),
    })

    expect(response.status).toBe(400)
    const body = await response.json()
    expect(body.error).toBeDefined()
  })
})
```

---

## Best Practices

### 1. Test Valid and Invalid Cases

```typescript
describe('schema', () => {
  // ✅ Test both
  it('accepts valid data', () => { /* ... */ })
  it('rejects invalid data', () => { /* ... */ })
})
```

### 2. Test Edge Cases

```typescript
describe('age validation', () => {
  it.each([
    [0, false],      // Boundary
    [1, true],       // Just valid
    [-1, false],     // Just invalid
    [120, true],     // Upper boundary
    [121, true],     // Beyond typical
    [1000, true],    // Extreme
  ])('validates age %i as %s', (age, expected) => {
    const result = schema.safeParse({ age })
    expect(result.success).toBe(expected)
  })
})
```

### 3. Use Test Factories

```typescript
function createValidUser(overrides = {}) {
  return {
    name: "Alice",
    email: "alice@example.com",
    age: 30,
    ...overrides,
  }
}

it('validates user', () => {
  const user = createValidUser()
  expect(userSchema.safeParse(user).success).toBe(true)
})

it('rejects invalid email', () => {
  const user = createValidUser({ email: "invalid" })
  expect(userSchema.safeParse(user).success).toBe(false)
})
```

### 4. Test Type Safety

```typescript
it('maintains type safety', () => {
  const result = userSchema.parse({
    name: "Alice",
    email: "alice@example.com",
    age: 30,
  })

  // TypeScript knows result.name is string
  const uppercaseName: string = result.name.toUpperCase()

  expect(uppercaseName).toBe("ALICE")
})
```

---

## AI Pair Programming Notes

**When to load this file:**
- Writing tests for Zod schemas
- Testing validation logic
- Integration testing with Zod
- Debugging validation failures

**Typical questions:**
- "How do I test Zod schemas?"
- "How do I test custom error messages?"
- "How do I test transformations?"
- "How do I test API routes with Zod?"

**Next steps:**
- [03-VALIDATION.md](./03-VALIDATION.md) - Validation patterns
- [05-ERROR-HANDLING.md](./05-ERROR-HANDLING.md) - Error handling

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1
