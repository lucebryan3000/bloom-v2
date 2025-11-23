---
id: typescript-03-objects-interfaces
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

# TypeScript Objects & Interfaces

**Part 3 of 11 - The TypeScript Knowledge Base**

## Table of Contents
1. [Interface Basics](#interface-basics)
2. [Type Aliases](#type-aliases)
3. [Object Types](#object-types)
4. [Interface vs Type](#interface-vs-type)
5. [Advanced Patterns](#advanced-patterns)
6. [Best Practices](#best-practices)

---

## Interface Basics

### Simple Interface

```typescript
// Basic interface
interface User {
 id: number;
 name: string;
 email: string;
}

// Implementing interface
const user: User = {
 id: 1,
 name: "Alice",
 email: "alice@example.com",
};

// Must have all required properties
const incomplete: User = {
 id: 1,
 name: "Bob",
 // ERROR: Missing 'email'
};
```

### Optional Properties

```typescript
interface Product {
 id: number;
 title: string;
 description?: string; // Optional
 price: number;
 onSale?: boolean; // Optional
}

const product: Product = {
 id: 1,
 title: "Laptop",
 price: 999,
 // description and onSale can be omitted
};
```

### Readonly Properties

```typescript
interface Config {
 readonly apiUrl: string;
 readonly timeout: number;
 debug?: boolean; // Can be modified
}

const config: Config = {
 apiUrl: "https://api.example.com",
 timeout: 5000,
};

// config.apiUrl = "new-url"; // ERROR: readonly
config.debug = true; // ✓ okay
```

### Methods in Interfaces

```typescript
interface Logger {
 log(message: string): void;
 error(message: string, error: Error): void;
 warn(message: string): void;
}

const logger: Logger = {
 log: (msg) => console.log(msg),
 error: (msg, err) => console.error(msg, err),
 warn: (msg) => console.warn(msg),
};

// Alternative method syntax
interface Store {
 get(key: string): unknown;
 set(key: string, value: unknown): void;
 delete(key: string): boolean;
}

const store: Store = {
 get(key) {
 return null;
 },
 set(key, value) {
 //...
 },
 delete(key) {
 return true;
 },
};
```

### Index Signatures

```typescript
// Any string key
interface Dictionary {
 [key: string]: string;
}

const dict: Dictionary = {
 hello: "world",
 foo: "bar",
};

// Any number key
interface NumberMap {
 [index: number]: string;
}

const map: NumberMap = {
 0: "first",
 1: "second",
};

// Multiple signatures
interface FlexibleMap {
 [key: string]: string | number;
 [index: number]: string; // numbers must be strings
}

// With readonly
interface ReadonlyMap {
 readonly [key: string]: number;
}
```

### Extending Interfaces

```typescript
// Simple extension
interface Animal {
 name: string;
 age: number;
}

interface Dog extends Animal {
 breed: string;
 bark: void;
}

const dog: Dog = {
 name: "Rex",
 age: 3,
 breed: "Labrador",
 bark {
 console.log("Woof!");
 },
};

// Multiple extension
interface Timestamped {
 createdAt: Date;
 updatedAt: Date;
}

interface Entity {
 id: string;
}

interface User extends Entity, Timestamped {
 name: string;
 email: string;
}
```

### Callable Interfaces

```typescript
// Function type as interface
interface Callback {
 (data: string): void;
}

const callback: Callback = (data) => console.log(data);

// Combined with properties
interface ClickHandler {
 (event: MouseEvent): void;
 enabled: boolean;
}

const handler: ClickHandler = (event) => {
 if (handler.enabled) {
 console.log(event);
 }
};

handler.enabled = true;
```

---

## Type Aliases

### Simple Type Aliases

```typescript
// Basic alias
type StringOrNumber = string | number;

const value: StringOrNumber = "hello"; // ✓
const number: StringOrNumber = 42; // ✓

// Object type alias
type Person = {
 name: string;
 age: number;
 email: string;
};

const person: Person = {
 name: "Alice",
 age: 25,
 email: "alice@example.com",
};
```

### Union Types

```typescript
type Status = "pending" | "active" | "inactive";
type Priority = 1 | 2 | 3;

// Type discrimination
type Response =
 | { ok: true; data: string }
 | { ok: false; error: string };

function handle(response: Response) {
 if (response.ok) {
 console.log(response.data); // string
 } else {
 console.log(response.error); // string
 }
}
```

### Function Type Aliases

```typescript
type Predicate<T> = (value: T) => boolean;
type Transformer<T, U> = (value: T) => U;
type EventListener = (event: Event) => void;

const isEven: Predicate<number> = (n) => n % 2 === 0;
const double: Transformer<number, number> = (n) => n * 2;
```

### Template Literal Types

```typescript
// Pattern matching
type EventType = `on${Capitalize<"click" | "hover" | "focus">}`;
// "onClick" | "onHover" | "onFocus"

// API endpoints
type GetEndpoint = `/api/users/${string}`;
type PostEndpoint = `POST /api/${string}`;

// Extracting types
type Message = `User ${string} logged in`;
const msg: Message = "User alice logged in"; // ✓
```

---

## Object Types

### Inline Object Types

```typescript
// In variable
const user: { name: string; age: number } = {
 name: "Alice",
 age: 25,
};

// In function parameter
function displayUser(user: { name: string; email: string }): void {
 console.log(user.name, user.email);
}

// In return type
function getConfig: { apiUrl: string; timeout: number } {
 return {
 apiUrl: "https://api.example.com",
 timeout: 5000,
 };
}
```

### Nested Objects

```typescript
interface Address {
 street: string;
 city: string;
 country: string;
}

interface User {
 name: string;
 address: Address;
}

const user: User = {
 name: "Alice",
 address: {
 street: "123 Main St",
 city: "Springfield",
 country: "USA",
 },
};
```

### Object Spread

```typescript
interface Base {
 id: number;
 createdAt: Date;
}

interface User extends Base {
 name: string;
}

const base: Base = {
 id: 1,
 createdAt: new Date,
};

const user: User = {
...base,
 name: "Alice",
};

// Type-safe spread
const merged = {...base,...user };
// Type: Base & User
```

---

## Interface vs Type

### Comparison Table

| Feature | Interface | Type |
|---------|-----------|------|
| Extends | `extends` | `&` |
| Declaration merging | ✓ | ✗ |
| Union types | ✗ | ✓ |
| Tuples | ✗ | ✓ |
| Mapped types | ✗ | ✓ |
| Conditional types | ✗ | ✓ |
| Primitive aliases | ✗ | ✓ |

### When to Use Each

```typescript
// Use Interface for:
// 1. Object contracts
interface Animal {
 name: string;
 age: number;
}

// 2. Declaration merging (augmentation)
interface Window {
 myCustomProperty: string;
}

// Use Type for:
// 1. Union types
type Status = "active" | "inactive" | "pending";

// 2. Tuple types
type Coordinates = [number, number];

// 3. Complex types
type Result<T, E> =
 | { ok: true; value: T }
 | { ok: false; error: E };

// 4. Primitives
type UserId = number & { readonly __brand: "UserId" };
```

---

## Advanced Patterns

### Intersection Types

```typescript
interface Named {
 name: string;
}

interface Timestamped {
 createdAt: Date;
 updatedAt: Date;
}

// Combine interfaces
type Entity = Named & Timestamped;

const entity: Entity = {
 name: "Item",
 createdAt: new Date,
 updatedAt: new Date,
};
```

### Mapped Types

```typescript
// Make all properties readonly
type ReadonlyUser = {
 readonly [K in keyof User]: User[K];
};

// Get optional version
type Partial<T> = {
 [K in keyof T]?: T[K];
};

// Make all getters
type Getters<T> = {
 [K in keyof T as `get${Capitalize<K & string>}`]: => T[K];
};

type PersonGetters = Getters<User>;
// { getName: => string; getAge: => number; }
```

### Conditional Types

```typescript
// Type that depends on another
type Flatten<T> = T extends Array<infer U> ? U: T;

type Str = Flatten<string[]>; // string
type Num = Flatten<number>; // number
```

---

## Best Practices

✅ **DO**:
- Use `interface` for object contracts
- Use `type` for unions and complex types
- Keep objects flat when possible
- Use `readonly` for immutable data
- Document complex properties with JSDoc

❌ **DON'T**:
- Mix interface and type unnecessarily
- Use overly broad index signatures
- Create deeply nested objects
- Overuse intersection types
- Use `any` for object properties

---

**Next**: [04-CLASSES-OOP.md](./04-CLASSES-OOP.md) - Classes & OOP patterns

---

**Last Updated**: November 8, 2025
**Status**: Production-Ready
