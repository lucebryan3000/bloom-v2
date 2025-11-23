---
id: typescript-quick-reference
topic: typescript
file_role: quickref
profile: full
difficulty_level: all-levels
kb_version: 3.1
prerequisites: ['javascript']
related_topics: ['javascript', 'nextjs', 'react']
embedding_keywords: [typescript, quick-reference, cheat-sheet, syntax]
last_reviewed: 2025-11-13
---

# TypeScript Quick Reference Card

**For fast lookup while coding**

## Basic Type Syntax

```typescript
// Primitives
let name: string = 'Alice';
let age: number = 25;
let active: boolean = true;
let nothing: null = null;
let undefined_value: undefined = undefined;

// Arrays
let numbers: number[] = [1, 2, 3];
let strings: Array<string> = ['a', 'b'];
let mixed: (string | number)[] = [1, 'a', 2];

// Tuples (fixed-length arrays)
let pair: [string, number] = ['hello', 42];
let tuple: [string, number,...boolean[]] = ['x', 1, true, false];

// Any (avoid!)
let anything: any = 'could be anything';

// Unknown (safe alternative to any)
let value: unknown = 'something';
if (typeof value === 'string') {
 console.log(value.toUpperCase); // Safe
}

// Never (impossible type)
function throwError(message: string): never {
 throw new Error(message);
}
```

---

## Function Typing

```typescript
// Basic function
function add(a: number, b: number): number {
 return a + b;
}

// Optional parameters
function greet(name: string, greeting?: string): string {
 return `${greeting || 'Hello'}, ${name}!`;
}

// Default parameters
function multiply(a: number, b: number = 2): number {
 return a * b;
}

// Rest parameters
function sum(...numbers: number[]): number {
 return numbers.reduce((a, b) => a + b, 0);
}

// Function type
type Callback = (data: string) => void;
const callback: Callback = (data) => console.log(data);

// Arrow function
const double = (x: number): number => x * 2;

// Overloading
function process(x: string): string;
function process(x: number): number;
function process(x: string | number): string | number {
 return typeof x === 'string' ? x.toUpperCase: x * 2;
}
```

---

## Objects and Interfaces

```typescript
// Interface
interface User {
 id: number;
 name: string;
 email: string;
 age?: number; // Optional
 readonly createdAt: Date; // Read-only
}

// Type alias
type Product = {
 id: number;
 title: string;
 price: number;
};

// Intersection type (combines types)
type Employee = User & {
 employeeId: string;
 department: string;
};

// Union type (either or)
type Status = 'pending' | 'completed' | 'failed';

// Index signatures (dynamic keys)
interface Dictionary {
 [key: string]: string;
}

// Mapped types (transform types)
type ReadonlyUser = {
 readonly [K in keyof User]: User[K];
};
```

---

## Types vs Interfaces

| Feature | Type | Interface |
|---------|------|-----------|
| Can extend | ✓ (with `&`) | ✓ (`extends`) |
| Declaration merging | ✗ | ✓ |
| Can be union | ✓ | ✗ |
| Computed properties | ✓ | ✗ |
| Tuples | ✓ | ✗ |
| **When to use** | Complex shapes, unions | Object contracts |

**Rule**: Use `interface` for object shapes, `type` for everything else.

---

## Union and Intersection Types

```typescript
// Union (A | B)
type Result = string | number;
type Status = 'success' | 'error' | 'pending';

function handle(result: Result) {
 if (typeof result === 'string') {
 console.log(result.toUpperCase);
 } else {
 console.log(result.toFixed(2));
 }
}

// Intersection (A & B)
type Admin = User & {
 permissions: string[];
};

// Discriminated unions (safer)
type Response =
 | { status: 'success'; data: string }
 | { status: 'error'; error: Error }
 | { status: 'loading' };

function handle(response: Response) {
 if (response.status === 'success') {
 console.log(response.data); // Type-safe
 }
}
```

---

## Generics

```typescript
// Basic generic
function identity<T>(value: T): T {
 return value;
}

const str = identity<string>('hello');
const num = identity<number>(42);
const auto = identity('inferred'); // Type inference

// Generic constraints
function getLength<T extends { length: number }>(value: T): number {
 return value.length;
}

getLength([1, 2, 3]); // ✓
getLength('hello'); // ✓
getLength(42); // ✗ (no length property)

// Generic interfaces
interface Box<T> {
 value: T;
 getValue: T;
}

const stringBox: Box<string> = {
 value: 'hello',
 getValue { return this.value; }
};

// Multiple type parameters
function merge<T, U>(a: T, b: U): T & U {
 return {...a,...b } as T & U;
}

// Default type parameters
type Container<T = string> = {
 value: T;
};

// Generic defaults
interface Api<Response = unknown> {
 get: Promise<Response>;
}
```

---

## Type Guards and Narrowing

```typescript
// typeof guard
function printLength(value: string | number) {
 if (typeof value === 'string') {
 console.log(value.length); // string
 } else {
 console.log(value.toFixed(2)); // number
 }
}

// instanceof guard
class Dog {
 bark { console.log('Woof!'); }
}

function makeSound(animal: Dog | string) {
 if (animal instanceof Dog) {
 animal.bark; // Dog
 }
}

// Type predicate
function isString(value: unknown): value is string {
 return typeof value === 'string';
}

const values: unknown[] = [1, 'hello', true];
const strings = values.filter(isString); // string[]

// Discriminated union
type Animal =
 | { kind: 'dog'; bark: void }
 | { kind: 'cat'; meow: void };

function animalSound(animal: Animal) {
 if (animal.kind === 'dog') {
 animal.bark; // Dog
 } else {
 animal.meow; // Cat
 }
}

// Assertion functions
function assertIsString(value: unknown): asserts value is string {
 if (typeof value !== 'string') {
 throw new TypeError('Must be a string');
 }
}

function process(value: unknown) {
 assertIsString(value);
 console.log(value.toUpperCase); // value is string
}
```

---

## Classes

```typescript
// Basic class
class Animal {
 name: string;

 constructor(name: string) {
 this.name = name;
 }

 speak: void {
 console.log(`${this.name} makes a sound`);
 }
}

// Inheritance
class Dog extends Animal {
 override speak: void {
 console.log(`${this.name} barks`);
 }
}

// Access modifiers
class User {
 public id: number; // Accessible everywhere
 protected role: string; // Accessible in class and subclasses
 private password: string; // Only accessible in class

 constructor(id: number, role: string, password: string) {
 this.id = id;
 this.role = role;
 this.password = password;
 }
}

// Shorthand
class Point {
 constructor(
 public x: number,
 public y: number
 ) {}
}

// Readonly properties
class Config {
 readonly apiUrl: string;
 readonly timeout: number = 5000;

 constructor(apiUrl: string) {
 this.apiUrl = apiUrl;
 }
}

// Static members
class MathUtil {
 static readonly PI = 3.14159;
 static add(a: number, b: number): number {
 return a + b;
 }
}
```

---

## Utility Types

```typescript
// Partial<T> - all properties optional
type UserPreview = Partial<User>;

// Required<T> - all properties required
type FullUser = Required<User>;

// Readonly<T> - all properties readonly
type ReadonlyUser = Readonly<User>;

// Record<K, T> - object with specific keys
type Permissions = Record<'read' | 'write' | 'delete', boolean>;

// Pick<T, K> - select properties
type UserPreview = Pick<User, 'id' | 'name'>;

// Omit<T, K> - exclude properties
type UserWithoutPassword = Omit<User, 'password'>;

// Exclude<T, U> - exclude types from union
type NotString = Exclude<string | number | boolean, string>; // number | boolean

// Extract<T, U> - extract matching types
type StringOrNumber = Extract<string | number | boolean, string | number>; // string | number

// ReturnType<T> - get function return type
type AddResult = ReturnType<typeof add>; // number

// Parameters<T> - get function parameters
type AddParams = Parameters<typeof add>; // [number, number]

// Keyof - get object keys as union
type UserKeys = keyof User; // 'id' | 'name' | 'email'

// Typeof - get type of value
const config = { timeout: 5000 };
type Config = typeof config; // { timeout: number }
```

---

## Enums

```typescript
// Numeric enum
enum Direction {
 Up = 1,
 Down = 2,
 Left = 3,
 Right = 4,
}

// String enum (better for debugging)
enum Status {
 Active = 'active',
 Inactive = 'inactive',
 Pending = 'pending',
}

// Heterogeneous enum (mixed)
enum Response {
 No = 0,
 Yes = 'yes',
}

// Using enums
let direction: Direction = Direction.Up;
let status: Status = Status.Active;

// Const enum (erased at compile time)
const enum Role {
 User = 'user',
 Admin = 'admin',
}
```

**Prefer**: Union types over enums
```typescript
type Status = 'active' | 'inactive' | 'pending';
type Role = 'user' | 'admin';
```

---

## Decorators

```typescript
// Class decorator
function sealed(constructor: Function) {
 Object.seal(constructor);
 Object.seal(constructor.prototype);
}

@sealed
class User {
 constructor(public name: string) {}
}

// Property decorator
function readonly(target: any, propertyKey: string) {
 Object.defineProperty(target, propertyKey, {
 writable: false,
 });
}

class Config {
 @readonly
 apiUrl = 'https://api.example.com';
}

// Method decorator
function timer(target: any, propertyKey: string, descriptor: PropertyDescriptor) {
 const originalMethod = descriptor.value;

 descriptor.value = function(...args: any[]) {
 console.time(propertyKey);
 const result = originalMethod.apply(this, args);
 console.timeEnd(propertyKey);
 return result;
 };

 return descriptor;
}

class Calculator {
 @timer
 add(a: number, b: number) {
 return a + b;
 }
}
```

---

## Async/Await Typing

```typescript
// Promise return type
async function fetchUser(id: number): Promise<User> {
 const response = await fetch(`/api/users/${id}`);
 return response.json;
}

// Error handling
async function safeApproach(
 id: number
): Promise<User | null> {
 try {
 const response = await fetch(`/api/users/${id}`);
 if (!response.ok) return null;
 return response.json;
 } catch (error) {
 console.error(error);
 return null;
 }
}

// Multiple awaits with types
async function getMultiple(ids: number[]): Promise<User[]> {
 const promises = ids.map(id => fetchUser(id));
 return Promise.all(promises);
}
```

---

## Module System

```typescript
// Export
export const config = { timeout: 5000 };
export type User = { id: number; name: string };
export function greet(name: string): string {
 return `Hello, ${name}`;
}

// Default export
export default class Logger {
 log(message: string) { console.log(message); }
}

// Import
import { config, greet } from './util';
import type { User } from './types'; // Type-only import
import Logger from './logger';

// Namespace export
export namespace Math {
 export const PI = 3.14159;
 export function add(a: number, b: number) { return a + b; }
}

// Import namespace
import * as math from './math';
math.Math.add(1, 2);
```

---

## Configuration Essentials

### Key `tsconfig.json` options

| Option | Purpose |
|--------|---------|
| `target` | ES version to compile to (ES2020) |
| `module` | Module system (esnext, commonjs) |
| `lib` | Built-in type definitions to include |
| `strict` | Enable all strict type checks |
| `esModuleInterop` | Import CommonJS as ES6 |
| `resolveJsonModule` | Allow importing JSON files |
| `declaration` | Generate `.d.ts` files |
| `sourceMap` | Generate source maps |
| `noUnusedLocals` | Error on unused variables |
| `noImplicitAny` | Error on implicit any |
| `strictNullChecks` | Treat null/undefined as types |
| `skipLibCheck` | Skip type checking of declaration files |

---

## Best Practices Checklist

- [ ] Use `strict` mode in tsconfig.json
- [ ] Avoid `any` - use `unknown` instead
- [ ] Use type predicates for narrowing
- [ ] Prefer interfaces for object contracts
- [ ] Use discriminated unions for state
- [ ] Make invalid states unrepresentable
- [ ] Use branded types for semantic safety
- [ ] Enable `noUnusedLocals` and `noUnusedParameters`
- [ ] Use const assertions for literals
- [ ] Document complex types with comments

---

## Common Type Patterns

```typescript
// State machine
type State =
 | { type: 'idle' }
 | { type: 'loading' }
 | { type: 'success'; data: any }
 | { type: 'error'; error: Error };

// Builder pattern
class QueryBuilder {
 private query: Query = {};

 where(condition: string): this {
 this.query.where = condition;
 return this;
 }

 limit(n: number): this {
 this.query.limit = n;
 return this;
 }

 build: Query {
 return this.query;
 }
}

// Result type (like Rust)
type Result<T, E> =
 | { ok: true; value: T }
 | { ok: false; error: E };

// Optional type
type Optional<T> = T | null;
```

---

## Troubleshooting Quick Answers

| Problem | Solution |
|---------|----------|
| "Implicit any" error | Add explicit type annotation |
| Can't extend interface | Use `type` with `&` instead |
| Circular types | Extract common type or use interface |
| Type is "never" | Check type narrowing logic |
| Can't access property | Add to interface/type definition |
| Generic type inference fails | Explicitly pass type parameter |

---

**Print this card or bookmark it for quick reference!**

Last Updated: November 8, 2025
