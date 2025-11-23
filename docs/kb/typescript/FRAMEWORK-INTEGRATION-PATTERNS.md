---
id: typescript-patterns
topic: typescript
file_role: patterns
profile: full
difficulty_level: intermediate-advanced
kb_version: 3.1
prerequisites: [typescript-basics, javascript]
related_topics: [nextjs, react, nodejs]
embedding_keywords: [patterns, examples, integration, best-practices, typescript-patterns]
last_reviewed: 2025-11-13
---

# TypeScript Framework Integration Patterns

**Purpose**: Production-ready TypeScript patterns and integration examples.

---

## 📋 Table of Contents

1. [Type Definitions](#type-definitions)
2. [Generics](#generics)
3. [Utility Types](#utility-types)
4. [API Response Typing](#api-response-typing)
5. [Strict Type Safety](#strict-type-safety)

---

## Type Definitions

### Pattern 1: Interface vs Type

```typescript
// Interface (extendable)
interface User {
 id: string;
 name: string;
 email: string;
}

// Type alias (unions, intersections)
type Status = 'active' | 'inactive' | 'pending';

// Intersection
type UserWithStatus = User & { status: Status };
```

### Pattern 2: Function Types

```typescript
type Handler = (event: Event) => void;
type AsyncHandler<T> = (data: T) => Promise<void>;

const handleClick: Handler = (event) => {
 console.log(event.target);
};
```

---

## Generics

### Pattern 3: Generic Functions

```typescript
function identity<T>(value: T): T {
 return value;
}

function map<T, U>(array: T[], fn: (item: T) => U): U[] {
 return array.map(fn);
}
```

### Pattern 4: Generic Constraints

```typescript
interface HasId {
 id: string;
}

function findById<T extends HasId>(items: T[], id: string): T | undefined {
 return items.find(item => item.id === id);
}
```

---

## Utility Types

### Pattern 5: Partial and Required

```typescript
interface User {
 id: string;
 name: string;
 email: string;
 age?: number;
}

// All properties optional
type PartialUser = Partial<User>;

// All properties required
type CompleteUser = Required<User>;
```

### Pattern 6: Pick and Omit

```typescript
// Select specific properties
type UserPreview = Pick<User, 'id' | 'name'>;

// Exclude specific properties
type UserWithoutId = Omit<User, 'id'>;
```

---

## API Response Typing

### Pattern 7: API Response Wrapper

```typescript
type ApiResponse<T> = {
 data: T;
 error: null;
 status: 'success';
} | {
 data: null;
 error: string;
 status: 'error';
};

async function fetchUser(id: string): Promise<ApiResponse<User>> {
 try {
 const response = await fetch(`/api/users/${id}`);
 const data = await response.json;
 return { data, error: null, status: 'success' };
 } catch (error) {
 return { data: null, error: error.message, status: 'error' };
 }
}
```

### Pattern 8: Zod Schema Validation

```typescript
import { z } from 'zod';

const UserSchema = z.object({
 id: z.string,
 name: z.string,
 email: z.string.email,
 age: z.number.optional
});

type User = z.infer<typeof UserSchema>;

function validateUser(data: unknown): User {
 return UserSchema.parse(data);
}
```

---

## Strict Type Safety

### Pattern 9: Discriminated Unions

```typescript
type Shape =
 | { kind: 'circle'; radius: number }
 | { kind: 'square'; size: number }
 | { kind: 'rectangle'; width: number; height: number };

function area(shape: Shape): number {
 switch (shape.kind) {
 case 'circle':
 return Math.PI * shape.radius ** 2;
 case 'square':
 return shape.size ** 2;
 case 'rectangle':
 return shape.width * shape.height;
 }
}
```

### Pattern 10: Branded Types

```typescript
type UserId = string & { readonly __brand: 'UserId' };
type Email = string & { readonly __brand: 'Email' };

function createUserId(id: string): UserId {
 return id as UserId;
}

function sendEmail(to: Email, subject: string) {
 // Type-safe email handling
}
```

---

## Best Practices

1. **Strict Mode**: Always enable strict TypeScript compiler options
2. **Type Over Any**: Avoid `any`, use `unknown` when type is uncertain
3. **Utility Types**: Leverage built-in utility types (Partial, Pick, etc.)
4. **Validation**: Use runtime validation libraries like Zod
5. **Generics**: Write reusable, type-safe generic functions

---

## Related Files

- **Quick Syntax**: [QUICK-REFERENCE.md](./QUICK-REFERENCE.md)
- **Handbook**: [TYPESCRIPT-HANDBOOK.md](./TYPESCRIPT-HANDBOOK.md)
- **Overview**: [README.md](./README.md)
- **Navigation**: [INDEX.md](./INDEX.md)

---

**All examples are production-ready patterns. Use strict TypeScript for maximum safety!**
