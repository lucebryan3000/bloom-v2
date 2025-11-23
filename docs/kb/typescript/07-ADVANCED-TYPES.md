---
id: typescript-07-advanced-types
topic: typescript
file_role: detailed
profile: full
difficulty_level: advanced
kb_version: 3.1
prerequisites: [javascript, typescript-basics]
related_topics: ['javascript', 'nextjs', 'react']
embedding_keywords: [typescript]
last_reviewed: 2025-11-13
---

# Advanced TypeScript Types

**Part 7 of 11 - The TypeScript Knowledge Base**

## Conditional Types

```typescript
// Basic conditional
type IsString<T> = T extends string ? true: false;

type A = IsString<"hello">; // true
type B = IsString<42>; // false

// Practical conditional
type Flatten<T> = T extends Array<infer U> ? U: T;

type FlatStr = Flatten<string[]>; // string
type FlatNum = Flatten<number>; // number

// Conditional with unions
type Flatten2<T> = T extends Array<infer U> ? Flatten2<U>: T;

type Deep = Flatten2<[[[string]]]>; // string

// Using conditionals for overloading
type ReturnTypeOf<T extends (...args: any[]) => any> =
 T extends (...args: any[]) => infer R ? R: never;

type Fn = (x: number) => string;
type Result = ReturnTypeOf<Fn>; // string
```

## Mapped Types

```typescript
// Make all properties readonly
type Readonly<T> = {
 readonly [K in keyof T]: T[K];
};

// Make all properties optional
type Partial<T> = {
 [K in keyof T]?: T[K];
};

// Create getters
type Getters<T> = {
 [K in keyof T as `get${Capitalize<K & string>}`]: => T[K];
};

interface User {
 name: string;
 age: number;
}

type UserGetters = Getters<User>;
// { getName: => string; getAge: => number }

// Property name transformation
type Record<K extends string, T> = {
 [P in K]: T;
};

// Filter properties
type PickByType<T, U> = {
 [K in keyof T as T[K] extends U ? K: never]: T[K];
};
```

## Template Literal Types

```typescript
// String pattern matching
type Greeting = `Hello, ${"Alice" | "Bob"}!`;
const msg: Greeting = "Hello, Alice!"; // ✓

// URL pattern
type Endpoint = `GET /api/${string}`;
const api: Endpoint = "GET /api/users"; // ✓

// Union expansion
type HTTP = "GET" | "POST" | "PUT";
type Resource = "users" | "posts";
type Route = `${HTTP} /api/${Resource}`;
// "GET /api/users" | "GET /api/posts" |...

// With transformations
type Split<S extends string> =
 S extends `${infer L} ${infer R}` ? [L,...Split<R>]: [S];

type Parts = Split<"hello world typescript">;
// ["hello", "world", "typescript"]
```

## Recursive Types

```typescript
// Deep readonly
type DeepReadonly<T> = {
 readonly [K in keyof T]: T[K] extends object
 ? DeepReadonly<T[K]>
: T[K];
};

interface Config {
 name: string;
 options: {
 timeout: number;
 retries: {
 count: number;
 };
 };
}

type ImmutableConfig = DeepReadonly<Config>;
// All nested properties readonly

// Deep partial
type DeepPartial<T> = {
 [K in keyof T]?: T[K] extends object
 ? DeepPartial<T[K]>
: T[K];
};
```

## Infer Patterns

```typescript
// Extract function return type
type ReturnType<T extends (...args: any) => any> =
 T extends (...args: any) => infer R ? R: never;

// Extract function parameters
type Parameters<T extends (...args: any) => any> =
 T extends (...args: infer P) => any ? P: never;

// Extract array element type
type ArrayElement<T extends any[]> =
 T extends (infer E)[] ? E: never;

type Arr = [1, 2, 3];
type Element = ArrayElement<Arr>; // 1 | 2 | 3
```

---

**Next**: [08-UTILITY-TYPES.md](./08-UTILITY-TYPES.md)

**Last Updated**: November 8, 2025
