---
id: typescript-08-utility-types
topic: typescript
file_role: detailed
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [javascript, typescript-basics]
related_topics: ['javascript', 'nextjs', 'react']
embedding_keywords: [typescript]
last_reviewed: 2025-11-13
---

# TypeScript Utility Types

**Part 8 of 11 - The TypeScript Knowledge Base**

## Property Manipulation

```typescript
// Partial - all properties optional
type PartialUser = Partial<User>;
// { name?: string; age?: number; email?: string }

// Required - all properties required
type RequiredUser = Required<User>;
// { name: string; age: number; email: string }

// Readonly - all properties readonly
type ReadonlyUser = Readonly<User>;

// Record - map keys to type
type Permissions = Record<"read" | "write" | "delete", boolean>;
// { read: boolean; write: boolean; delete: boolean }
```

## Property Selection

```typescript
// Pick - select specific properties
type UserPreview = Pick<User, "id" | "name">;
// { id: number; name: string }

// Omit - exclude properties
type UserWithoutPassword = Omit<User, "password">;

// Record with properties
type Config = Record<"dev" | "prod", { timeout: number }>;
// { dev: { timeout: number }; prod: { timeout: number } }
```

## Union Manipulation

```typescript
// Exclude - remove types from union
type NonString = Exclude<string | number | boolean, string>;
// number | boolean

// Extract - keep matching types
type StringOrNum = Extract<string | number | boolean, string | number>;
// string | number

// Union to intersection
type UnionToIntersection<U> = (
 U extends any ? (k: U) => void: never
) extends (k: infer I) => void
 ? I
: never;
```

## Function Types

```typescript
// ReturnType - get function return type
type AddResult = ReturnType<typeof add>;
type PromiseString = ReturnType< => Promise<string>>;

// Parameters - get function parameters
type AddParams = Parameters<typeof add>;
// [number, number]

// ConstructorParameters - constructor params
type DateConstructor = ConstructorParameters<typeof Date>;

// InstanceType - get instance type
type DateInstance = InstanceType<typeof Date>;
```

## Object & Key Types

```typescript
// Keyof - get object keys as union
type UserKeys = keyof User; // "id" | "name" | "email"

// Typeof - get type of value
const config = { timeout: 5000 };
type Config = typeof config; // { timeout: number }

// ThisType - specify 'this' type
type SetupContext = ThisType<{ value: number }>;
```

## String Transformation

```typescript
// Capitalize
type Capitalized = Capitalize<"hello">; // "Hello"

// Uppercase
type Screaming = Uppercase<"hello">; // "HELLO"

// Lowercase
type LowerCase = Lowercase<"HELLO">; // "hello"

// Uncapitalize
type UnCapitalized = Uncapitalize<"Hello">; // "hello"
```

## Custom Utilities

```typescript
// Deep partial
type DeepPartial<T> = {
 [P in keyof T]?: T[P] extends object ? DeepPartial<T[P]>: T[P];
};

// Readonly deep
type DeepReadonly<T> = {
 readonly [P in keyof T]: T[P] extends object
 ? DeepReadonly<T[P]>
: T[P];
};

// Getters
type Getters<T> = {
 [P in keyof T as `get${Capitalize<P & string>}`]: => T[P];
};

// Pick by type
type PickByType<T, U> = {
 [K in keyof T as T[K] extends U ? K: never]: T[K];
};
```

---

**Next**: [09-DECORATORS-METADATA.md](./09-DECORATORS-METADATA.md)

**Last Updated**: November 8, 2025
