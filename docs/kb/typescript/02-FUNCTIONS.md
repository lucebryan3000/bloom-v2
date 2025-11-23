---
id: typescript-02-functions
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

# TypeScript Functions: Typing & Patterns

**Part 2 of 11 - The TypeScript Knowledge Base**

## Table of Contents
1. [Function Type Basics](#function-type-basics)
2. [Function Parameters](#function-parameters)
3. [Return Types](#return-types)
4. [Function Overloads](#function-overloads)
5. [Advanced Patterns](#advanced-patterns)
6. [Best Practices](#best-practices)

---

## Function Type Basics

### Basic Function Declaration

```typescript
// Explicit parameter and return types
function add(a: number, b: number): number {
 return a + b;
}

// Arrow function
const subtract = (a: number, b: number): number => a - b;

// Function expression
const multiply: (a: number, b: number) => number = (a, b) => a * b;

// Function type alias
type MathOp = (a: number, b: number) => number;
const divide: MathOp = (a, b) => a / b;
```

### Function Signatures

```typescript
// Signature syntax
(param1: type1, param2: type2): returnType

// Examples
(a: number, b: number): number
(name: string): void
(data: unknown): asserts data is string
(callback: => void): Promise<void>

// Interface with function signature
interface Logger {
 (message: string): void;
}

const log: Logger = (message) => console.log(message);
```

---

## Function Parameters

### Required Parameters

```typescript
// All parameters required by default
function greet(firstName: string, lastName: string): string {
 return `Hello, ${firstName} ${lastName}!`;
}

greet("Alice", "Smith"); // ✓
// greet("Alice"); // ERROR: Missing argument
// greet("Alice", "Smith", "Jr"); // ERROR: Too many arguments
```

### Optional Parameters

```typescript
// Use ? to mark parameters as optional
function greet(
 name: string,
 greeting?: string
): string {
 const salutation = greeting || "Hello";
 return `${salutation}, ${name}!`;
}

greet("Alice"); // ✓ greeting = undefined
greet("Alice", "Hi"); // ✓ greeting = "Hi"

// Optional must come after required
function bad(optional?: string, required: string) {
 // ERROR: A required parameter cannot follow an optional parameter
}
```

### Default Parameters

```typescript
// Parameters with defaults
function multiply(a: number, b: number = 2): number {
 return a * b;
}

multiply(5); // 10 (uses default)
multiply(5, 3); // 15

// Default can reference earlier parameters
function format(value: number, decimals = 2): string {
 return value.toFixed(decimals);
}

// Type is inferred from default
function greet(greeting = "Hello"): void {
 // greeting: string (inferred)
}

// Defaults with optional
function create(name: string, type: string = "default"): void {
 //...
}
```

### Rest Parameters

```typescript
// Variadic parameters (unknown number of args)
function sum(...numbers: number[]): number {
 return numbers.reduce((a, b) => a + b, 0);
}

sum(1); // 1
sum(1, 2, 3); // 6
sum(1, 2, 3, 4, 5); // 15

// Multiple rest not allowed
function bad(...args1: string[],...args2: number[]) {
 // ERROR: A rest parameter must be last in a parameter list
}

// Rest with other parameters
function format(separator: string,...values: string[]): string {
 return values.join(separator);
}

format(", ", "a", "b", "c"); // "a, b, c"

// Rest in type
type RestFunction = (...args: string[]) => void;
```

### Destructuring Parameters

```typescript
// Object destructuring
interface User {
 id: number;
 name: string;
 email: string;
}

function displayUser({ name, email }: User): void {
 console.log(`${name} (${email})`);
}

// Array destructuring
function swap([a, b]: [number, number]): [number, number] {
 return [b, a];
}

swap([1, 2]); // [2, 1]

// With rest in destructuring
function greet({ firstName,...rest }: { firstName: string; [key: string]: any }): void {
 console.log(firstName, rest);
}

// Optional destructuring
function process({
 name,
 age = 18,
}: {
 name: string;
 age?: number;
}): void {
 //...
}
```

### This Parameter

```typescript
// Type of 'this' context
interface User {
 name: string;
 greet(this: User): void;
}

const user: User = {
 name: "Alice",
 greet {
 console.log(`Hello, I'm ${this.name}`);
 },
};

user.greet; // ✓ 'this' is User

// Arrow function doesn't have own 'this'
const user2: User = {
 name: "Bob",
 greet: => {
 console.log(`Hello, I'm ${this.name}`); // 'this' is outer scope
 },
};
```

---

## Return Types

### Basic Return Types

```typescript
// Explicit return type
function getName: string {
 return "Alice";
}

// Inferred return type
function getAge {
 return 25; // inferred: number
}

// No return value
function logMessage(message: string): void {
 console.log(message);
}

// Function that never returns
function throwError: never {
 throw new Error("Error!");
}

function infinite: never {
 while (true) {}
}
```

### Union Return Types

```typescript
// Multiple possible return types
function getValue: string | number {
 return Math.random > 0.5 ? "string": 42;
}

// Discriminated union
function process(type: "text" | "number"): string | number {
 return type === "text" ? "hello": 42;
}
```

### Async/Promise Return Types

```typescript
// Async function returns Promise
async function fetchUser(id: number): Promise<User> {
 const response = await fetch(`/api/users/${id}`);
 return response.json;
}

// Async with void (fire-and-forget)
async function logAsync: Promise<void> {
 await sleep(1000);
 console.log("Done");
}

// Async generator
async function* generateNumbers: AsyncGenerator<number> {
 yield 1;
 yield 2;
 yield 3;
}
```

### Complex Return Types

```typescript
// Object return
function getConfig: { apiUrl: string; timeout: number } {
 return {
 apiUrl: "https://api.example.com",
 timeout: 5000,
 };
}

// Array return
function getUsers: User[] {
 return [{ id: 1, name: "Alice" }];
}

// Generic return type
function identity<T>(value: T): T {
 return value;
}

// Conditional return type
function getValue(type: "string"): string;
function getValue(type: "number"): number;
function getValue(type: "string" | "number"): string | number {
 return type === "string" ? "value": 42;
}
```

---

## Function Overloads

### Basic Overloading

```typescript
// Signature 1
function process(x: string): string;
// Signature 2
function process(x: number): number;
// Implementation
function process(x: string | number): string | number {
 if (typeof x === "string") {
 return x.toUpperCase;
 } else {
 return x * 2;
 }
}

// Usage
process("hello"); // Returns string
process(21); // Returns number
```

### Overloads with Different Parameters

```typescript
// Get user by ID
function getUser(id: number): User;
// Get user by email
function getUser(email: string): User;
// Implementation
function getUser(idOrEmail: number | string): User {
 if (typeof idOrEmail === "number") {
 return db.getUserById(idOrEmail);
 } else {
 return db.getUserByEmail(idOrEmail);
 }
}

getUser(123); // ID
getUser("alice@example.com"); // Email
```

### Overloads with Different Return Types

```typescript
// Get single item
function get<T>(key: string): T;
// Get multiple items
function get<T>(key: string[]): T[];
// Implementation
function get<T>(key: string | string[]): T | T[] {
 if (Array.isArray(key)) {
 return key.map(k => cache.get(k));
 } else {
 return cache.get(key);
 }
}

const single = get<string>("key"); // string
const multiple = get<string>(["key1", "key2"]); // string[]
```

### Complex Overloads

```typescript
interface Options {
 format?: "json" | "xml";
 compress?: boolean;
}

// No options
function serialize(data: object): string;
// With options
function serialize(data: object, options: Options): string;
// With filename
function serialize(data: object, options: Options, filename: string): Promise<void>;
// Implementation
function serialize(
 data: object,
 options?: Options,
 filename?: string
): string | Promise<void> {
 const serialized = JSON.stringify(data);

 if (filename) {
 return fs.promises.writeFile(filename, serialized);
 }

 return serialized;
}

serialize({ x: 1 }); // string
serialize({ x: 1 }, { format: "json" }); // string
serialize({ x: 1 }, {}, "file.json"); // Promise<void>
```

---

## Advanced Patterns

### Generic Functions

```typescript
// Simple generic
function identity<T>(value: T): T {
 return value;
}

identity<string>("hello"); // T = string
identity<number>(42); // T = number
identity("inferred"); // T inferred as string

// Multiple type parameters
function swap<T, U>(a: T, b: U): [U, T] {
 return [b, a];
}

swap(1, "hello"); // ["hello", 1]

// Generic with constraints
function getLength<T extends { length: number }>(value: T): number {
 return value.length;
}

getLength("hello"); // ✓ strings have length
getLength([1, 2]); // ✓ arrays have length
getLength(42); // ERROR: number has no length

// Generic with default
function first<T = string>(arr: T[]): T {
 return arr[0];
}

first(["a", "b"]); // string (default)
first<number>([1, 2]); // number
```

### Function Composition

```typescript
// Compose functions
function compose<A, B, C>(
 f: (a: A) => B,
 g: (b: B) => C
): (a: A) => C {
 return (a) => g(f(a));
}

const add1 = (x: number) => x + 1;
const double = (x: number) => x * 2;

const add1Then Double = compose(add1, double);
addThenDouble(5); // double(add1(5)) = 12
```

### Type Guards in Functions

```typescript
// Type predicate
function isString(value: unknown): value is string {
 return typeof value === "string";
}

// Type assertion function
function assertIsString(value: unknown): asserts value is string {
 if (typeof value !== "string") {
 throw new TypeError(`Expected string, got ${typeof value}`);
 }
}

function process(value: unknown) {
 assertIsString(value);
 console.log(value.toUpperCase); // value is string
}
```

### Currying

```typescript
// Curried function
function curry<A, B, C>(fn: (a: A, b: B) => C) {
 return (a: A) => (b: B) => fn(a, b);
}

const add = (a: number, b: number) => a + b;
const curriedAdd = curry(add);

curriedAdd(1)(2); // 3

// Practical example
function log(level: "debug" | "info" | "warn" | "error") {
 return (message: string) => {
 console.log(`[${level}] ${message}`);
 };
}

const logInfo = log("info");
logInfo("Something happened"); // [info] Something happened
```

---

## Best Practices

✅ **DO**:
- Always annotate function parameters
- Always annotate function return types (especially public APIs)
- Use overloads for complex signatures
- Use generics for reusable functions
- Use type guards for runtime type checking

❌ **DON'T**:
- Use implicit `any` in parameters
- Omit return types for public functions
- Overload excessively (max 3-4 overloads)
- Use `arguments` (use rest parameters instead)
- Mix optional and required parameters poorly

---

**Next**: [03-OBJECTS-INTERFACES.md](./03-OBJECTS-INTERFACES.md) - Objects, interfaces & type aliases

---

**Last Updated**: November 8, 2025
**Status**: Production-Ready
