---
id: typescript-typescript-handbook
topic: typescript
file_role: guide
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: ['javascript']
related_topics: ['javascript', 'nextjs', 'react']
embedding_keywords: [typescript, guide, tutorial, comprehensive]
last_reviewed: 2025-11-13
---

# TypeScript Comprehensive Handbook

**Last Updated**: November 8, 2025
**Status**: Production-Ready

## Table of Contents

1. [Introduction](#introduction)
2. [Types: The Foundation](#types--the-foundation)
3. [Functions & Parameters](#functions--parameters)
4. [Objects & Interfaces](#objects--interfaces)
5. [Classes & Inheritance](#classes--inheritance)
6. [Generics](#generics)
7. [Union & Intersection Types](#union--intersection-types)
8. [Type Guards & Narrowing](#type-guards--narrowing)
9. [Advanced Type Patterns](#advanced-type-patterns)
10. [Utility Types](#utility-types)
11. [Decorators](#decorators)
12. [Modules & Namespaces](#modules--namespaces)
13. [Configuration](#configuration)
14. [Best Practices](#best-practices)
15. [Common Pitfalls](#common-pitfalls)

---

## Introduction

TypeScript extends JavaScript with **static typing** and advanced type system features, enabling developers to catch errors at compile-time rather than runtime.

### Why TypeScript?

1. **Catch Errors Early**: Type mismatches are caught during development
2. **Better IDE Support**: Autocomplete, refactoring, navigation
3. **Self-Documenting**: Types serve as documentation
4. **Scalability**: Large codebases become manageable
5. **Maintainability**: Type information helps future developers

### Core Principle

> "Make invalid states unrepresentable"

A well-typed system prevents impossible states from being created.

---

## Types: The Foundation

### Primitive Types

```typescript
// String
const name: string = 'Alice';
const greeting: string = `Hello, ${name}`;

// Number (both integer and float)
const age: number = 25;
const pi: number = 3.14159;
const hex: number = 0xFF;
const binary: number = 0b1010;

// Boolean
const isActive: boolean = true;
const isDone: boolean = false;

// Null and Undefined
const nothing: null = null;
const undef: undefined = undefined;

// Symbol (unique identifiers)
const sym: symbol = Symbol('unique');

// BigInt (large integers)
const big: bigint = 9007199254740991n;
```

### Literal Types

```typescript
// String literal
type Direction = 'up' | 'down' | 'left' | 'right';
const move: Direction = 'up';

// Number literal
type HttpStatus = 200 | 404 | 500;
const status: HttpStatus = 200;

// Boolean literal (rarely used)
type AlwaysTrue = true;
```

### Array Types

```typescript
// Basic array syntax
const numbers: number[] = [1, 2, 3];
const strings: Array<string> = ['a', 'b', 'c'];

// Array of objects
interface User {
 id: number;
 name: string;
}

const users: User[] = [
 { id: 1, name: 'Alice' },
 { id: 2, name: 'Bob' },
];

// Readonly arrays
const readonlyNumbers: readonly number[] = [1, 2, 3];
const readonlyStrings: ReadonlyArray<string> = ['a', 'b'];

// Tuple types (fixed-length arrays)
type Pair = [string, number];
const pair: Pair = ['hello', 42];

// Variable-length tuples
type StringNumberBooleans = [string, number,...boolean[]];
const tuple: StringNumberBooleans = ['a', 1, true, false];

// Optional elements
type OptionalTuple = [string, number?];
const opt1: OptionalTuple = ['hello'];
const opt2: OptionalTuple = ['hello', 42];
```

### Special Types

```typescript
// Any (avoid this!)
let anything: any = 'could be anything';
anything.toUpperCase; // No type checking

// Unknown (safe alternative)
let value: unknown = 'something';

if (typeof value === 'string') {
 console.log(value.toUpperCase); // Safe
}

// Never (unreachable code / impossible type)
function throwError(message: string): never {
 throw new Error(message);
}

function infiniteLoop: never {
 while (true) {}
}

// Void (no return value)
function logMessage(message: string): void {
 console.log(message);
}
```

---

## Functions & Parameters

### Function Types

```typescript
// Basic function
function add(a: number, b: number): number {
 return a + b;
}

// Arrow function
const subtract = (a: number, b: number): number => a - b;

// Function expression
const multiply: (a: number, b: number) => number = (a, b) => a * b;

// Function type alias
type MathOperation = (a: number, b: number) => number;

const divide: MathOperation = (a, b) => a / b;
```

### Parameter Types

```typescript
// Required parameters
function createUser(name: string, age: number): void {
 console.log(name, age);
}

// Optional parameters (with ?)
function greet(name: string, greeting?: string): string {
 return `${greeting || 'Hello'}, ${name}!`;
}

// Default parameters
function multiply(a: number, b: number = 2): number {
 return a * b;
}

// Rest parameters (variadic)
function sum(...numbers: number[]): number {
 return numbers.reduce((a, b) => a + b, 0);
}

// Parameter destructuring
function createUser({ name, age }: { name: string; age: number }): void {
 console.log(name, age);
}

// Rest in destructuring
function process({ first,...rest }: { first: string; [key: string]: any }): void {
 console.log(first, rest);
}
```

### Overloading

```typescript
// Function overloads define multiple signatures
function process(x: string): string;
function process(x: number): number;
function process(x: string | number): string | number {
 if (typeof x === 'string') {
 return x.toUpperCase;
 }
 return x * 2;
}

process('hello'); // Returns string
process(21); // Returns number

// Generic overloads
function identity<T extends string>(x: T): T;
function identity<T extends number>(x: T): T;
function identity<T>(x: T): T {
 return x;
}
```

---

## Objects & Interfaces

### Interface Definition

```typescript
// Basic interface
interface User {
 id: number;
 name: string;
 email: string;
}

// Optional properties
interface Product {
 id: number;
 title: string;
 description?: string;
 price?: number;
}

// Readonly properties
interface Config {
 readonly apiUrl: string;
 readonly timeout: number;
}

// Methods
interface Logger {
 log(message: string): void;
 error(message: string, error: Error): void;
}

// Function types in interface
interface Callback {
 (data: string): void;
}

const myCallback: Callback = (data) => console.log(data);
```

### Type Aliases

```typescript
// Type alias for union
type Status = 'pending' | 'completed' | 'failed';

// Type alias for object
type Person = {
 name: string;
 age: number;
};

// Type alias for function
type Converter<T, U> = (value: T) => U;

// Type alias for intersection
type Admin = User & {
 permissions: string[];
};
```

### Extending Interfaces

```typescript
// Interface extension
interface Animal {
 name: string;
 age: number;
}

interface Dog extends Animal {
 breed: string;
 bark: void;
}

// Multiple extension
interface Employee extends Person, Timestamped {
 employeeId: string;
 department: string;
}

// Interface merging
interface Window {
 myCustomProperty: string;
}

// Now Window has both original properties and myCustomProperty
```

---

## Classes & Inheritance

### Basic Classes

```typescript
// Class definition
class Animal {
 name: string;
 age: number;

 constructor(name: string, age: number) {
 this.name = name;
 this.age = age;
 }

 describe: string {
 return `${this.name} is ${this.age} years old`;
 }
}

// Class inheritance
class Dog extends Animal {
 breed: string;

 constructor(name: string, age: number, breed: string) {
 super(name, age);
 this.breed = breed;
 }

 bark: void {
 console.log('Woof!');
 }

 // Method override
 override describe: string {
 return `${super.describe} and is a ${this.breed}`;
 }
}
```

### Access Modifiers

```typescript
class User {
 // Public (default) - accessible everywhere
 public id: number;

 // Protected - accessible in class and subclasses
 protected role: string;

 // Private - only accessible in this class
 private password: string;

 constructor(id: number, role: string, password: string) {
 this.id = id;
 this.role = role;
 this.password = password;
 }

 // Public method
 getId: number {
 return this.id;
 }

 // Protected method
 protected getRole: string {
 return this.role;
 }

 // Private method
 private validatePassword(pw: string): boolean {
 return pw === this.password;
 }
}

// Subclass
class Admin extends User {
 override getName: string {
 // Can access protected method
 const role = this.getRole;
 return `Admin: ${role}`;
 }
}
```

### Property Shortcuts

```typescript
// Shorthand constructor parameters
class Point {
 constructor(
 public x: number,
 public y: number
 ) {}
}

// Equivalent to:
class PointLong {
 public x: number;
 public y: number;

 constructor(x: number, y: number) {
 this.x = x;
 this.y = y;
 }
}
```

### Static Members

```typescript
class MathUtil {
 static readonly PI = 3.14159;

 static add(a: number, b: number): number {
 return a + b;
 }

 static readonly version = '1.0.0';
}

// Usage
console.log(MathUtil.PI);
const result = MathUtil.add(1, 2);
```

---

## Generics

### Basic Generics

```typescript
// Generic function
function identity<T>(value: T): T {
 return value;
}

const str = identity<string>('hello');
const num = identity<number>(42);
const auto = identity('inferred'); // Type inference

// Generic interface
interface Box<T> {
 value: T;
 getValue: T;
 setValue(newValue: T): void;
}

const stringBox: Box<string> = {
 value: 'hello',
 getValue {
 return this.value;
 },
 setValue(newValue) {
 this.value = newValue;
 },
};

// Generic class
class Stack<T> {
 private items: T[] = [];

 push(item: T): void {
 this.items.push(item);
 }

 pop: T | undefined {
 return this.items.pop;
 }
}

const stack = new Stack<number>;
stack.push(1);
stack.push(2);
```

### Generic Constraints

```typescript
// Extend specific type
function getLength<T extends { length: number }>(value: T): number {
 return value.length;
}

getLength([1, 2, 3]); // ✓
getLength('hello'); // ✓
getLength(42); // ✗

// Keyof constraint
function getProperty<T, K extends keyof T>(obj: T, key: K): T[K] {
 return obj[key];
}

const user = { name: 'Alice', age: 25 };
const name = getProperty(user, 'name'); // ✓
// getProperty(user, 'email'); // ✗

// Multiple constraints
function merge<T extends object, U extends object>(a: T, b: U): T & U {
 return {...a,...b } as T & U;
}
```

### Advanced Generic Patterns

```typescript
// Generic with default
type Container<T = string> = {
 value: T;
};

// Generic with conditional
type Flatten<T> = T extends Array<infer U> ? U: T;

type Str = Flatten<string[]>; // string
type Num = Flatten<number>; // number

// Generic with mapped types
type Getters<T> = {
 [K in keyof T as `get${Capitalize<K & string>}`]: => T[K];
};

type Person = { name: string; age: number };
type PersonGetters = Getters<Person>;
// Result: { getName: => string; getAge: => number }
```

---

## Union & Intersection Types

### Union Types

```typescript
// Basic union
type Status = 'active' | 'inactive' | 'pending';
type Priority = 1 | 2 | 3;

const status: Status = 'active';

// Union of types
type Result = string | number | boolean;

function process(value: Result): void {
 if (typeof value === 'string') {
 console.log(value.toUpperCase);
 } else if (typeof value === 'number') {
 console.log(value.toFixed(2));
 } else {
 console.log(value ? 'true': 'false');
 }
}

// Union of object types
type Dog = { bark: void };
type Cat = { meow: void };
type Pet = Dog | Cat;
```

### Discriminated Unions

```typescript
// Safer than simple unions
type Response =
 | { status: 'success'; data: string }
 | { status: 'error'; error: Error }
 | { status: 'loading' };

function handle(response: Response) {
 switch (response.status) {
 case 'success':
 console.log(response.data); // data available
 break;
 case 'error':
 console.log(response.error); // error available
 break;
 case 'loading':
 console.log('Loading...');
 break;
 }
}
```

### Intersection Types

```typescript
// Combine types
type Animal = { name: string };
type Mammal = { warmBlooded: boolean };
type Dog = Animal & Mammal;

const dog: Dog = {
 name: 'Rex',
 warmBlooded: true,
};

// Practical intersection
type Base = { id: number };
type Timestamped = { createdAt: Date; updatedAt: Date };
type User = Base & Timestamped & { name: string };
```

---

## Type Guards & Narrowing

### Type Narrowing

```typescript
// typeof guard
function printLength(value: string | number) {
 if (typeof value === 'string') {
 console.log(value.length); // value is string
 } else {
 console.log(value.toFixed(2)); // value is number
 }
}

// instanceof guard
class Error1 extends Error {}
class Error2 extends Error {}

function handleError(error: Error1 | Error2) {
 if (error instanceof Error1) {
 // error is Error1
 } else {
 // error is Error2
 }
}

// Truthiness guard
function check(value: string | null) {
 if (value) {
 console.log(value.toUpperCase); // value is string
 } else {
 console.log('null'); // value is null
 }
}

// Equality guard
function compare(a: string | number, b: string | boolean) {
 if (a === b) {
 // a and b are both string
 }
}

// Control flow analysis
function process(value: string | undefined) {
 if (!value) {
 return;
 }
 // value is definitely string here
 console.log(value.toUpperCase);
}
```

### Type Predicates

```typescript
// Type predicate function
function isString(value: unknown): value is string {
 return typeof value === 'string';
}

function isNumber(value: unknown): value is number {
 return typeof value === 'number';
}

const values: unknown[] = [1, 'hello', true, 42];
const strings = values.filter(isString);
const numbers = values.filter(isNumber);

// Object predicate
interface User {
 name: string;
 email: string;
}

function isUser(obj: unknown): obj is User {
 return (
 typeof obj === 'object' &&
 obj !== null &&
 'name' in obj &&
 'email' in obj &&
 typeof obj.name === 'string' &&
 typeof obj.email === 'string'
 );
}
```

### Assertion Functions

```typescript
// Assertion function
function assertIsString(value: unknown): asserts value is string {
 if (typeof value !== 'string') {
 throw new TypeError(`Expected string, got ${typeof value}`);
 }
}

function process(value: unknown) {
 assertIsString(value);
 console.log(value.toUpperCase); // value is string
}

// Assertion with condition
function assert(condition: boolean, message: string): asserts condition {
 if (!condition) {
 throw new Error(message);
 }
}

const value: string | null = getValue;
assert(value !== null, 'value must not be null');
console.log(value); // value is string
```

---

## Advanced Type Patterns

### Conditional Types

```typescript
// Basic conditional type
type IsString<T> = T extends string ? true: false;

type A = IsString<'hello'>; // true
type B = IsString<42>; // false

// Practical conditional type
type FlattenArray<T> = T extends Array<infer U>
 ? U
: T;

type Flat1 = FlattenArray<string[]>; // string
type Flat2 = FlattenArray<string>; // string

// Conditional with union
type Flatten<T> = T extends Array<infer U> ? Flatten<U>: T;

type Deep = Flatten<[[[string]]]>; // string
```

### Mapped Types

```typescript
// Transform object types
type ReadonlyUser = {
 readonly [K in keyof User]: User[K];
};

type Getters<T> = {
 [K in keyof T as `get${Capitalize<K & string>}`]: => T[K];
};

type Setters<T> = {
 [K in keyof T as `set${Capitalize<K & string>}`]: (
 value: T[K]
 ) => void;
};

interface Person {
 name: string;
 age: number;
}

type PersonGetters = Getters<Person>;
// { getName: => string; getAge: => number }

// Template literal type
type EventEmitterMethods<T> = {
 [K in keyof T as `on${Capitalize<K & string>}`]: (
 listener: (value: T[K]) => void
 ) => void;
};
```

### Template Literal Types

```typescript
// String manipulation types
type Greeting = `Hello, ${string}!`;

const greeting: Greeting = 'Hello, World!'; // ✓
// const bad: Greeting = 'Hi, World!'; // ✗

// Extracting from template
type URLString = `https://${string}`;

// Union in template
type Status = 'pending' | 'complete';
type Event = `${Status}Event`;
// type Event = 'pendingEvent' | 'completeEvent'
```

### Recursive Types

```typescript
// Recursive type
type DeepReadonly<T> = {
 readonly [K in keyof T]: T[K] extends object
 ? DeepReadonly<T[K]>
: T[K];
};

interface User {
 name: string;
 address: {
 city: string;
 zipcode: {
 code: string;
 };
 };
}

type ReadonlyUser = DeepReadonly<User>;
// All nested properties are readonly
```

---

## Utility Types

### Common Utility Types

```typescript
// Partial - all properties optional
type PartialUser = Partial<User>;

// Required - all properties required
type RequiredUser = Required<User>;

// Readonly - all properties readonly
type ReadonlyUser = Readonly<User>;

// Record - object with specific keys
type Permissions = Record<'read' | 'write' | 'delete', boolean>;

// Pick - select specific properties
type UserPreview = Pick<User, 'id' | 'name'>;

// Omit - exclude specific properties
type UserWithoutPassword = Omit<User, 'password'>;

// Exclude - exclude types from union
type NonString = Exclude<string | number | boolean, string>;

// Extract - extract matching types
type StringOrNum = Extract<string | number | boolean, string | number>;

// ReturnType - get function return type
type AddResult = ReturnType<typeof add>;

// Parameters - get function parameter types
type AddParams = Parameters<typeof add>;

// InstanceType - get instance type of constructor
class MyClass {}
type MyInstance = InstanceType<typeof MyClass>;

// Keyof - get object keys as union
type UserKeys = keyof User;

// Typeof - get type of a value
const config = { timeout: 5000 };
type Config = typeof config;
```

---

## Decorators

### Class Decorators

```typescript
// Basic decorator
function sealed(constructor: Function) {
 Object.seal(constructor);
 Object.seal(constructor.prototype);
}

@sealed
class User {
 name: string = 'Anonymous';
}

// Decorator factory
function logClass<T extends { new(...args: any[]): {} }>(
 constructor: T
) {
 return class extends constructor {
 constructor(...args: any[]) {
 super(...args);
 console.log(`Instance of ${constructor.name} created`);
 }
 };
}

@logClass
class Database {}
```

### Property Decorators

```typescript
function readonly(target: any, propertyKey: string) {
 let value = target[propertyKey];

 Object.defineProperty(target, propertyKey, {
 get: => value,
 set: => {
 throw new Error(`Cannot assign to ${propertyKey}`);
 },
 });
}

class Config {
 @readonly
 apiUrl = 'https://api.example.com';
}
```

### Method Decorators

```typescript
function timer(
 target: any,
 propertyKey: string,
 descriptor: PropertyDescriptor
) {
 const originalMethod = descriptor.value;

 descriptor.value = async function (...args: any[]) {
 const start = performance.now;
 const result = await originalMethod.apply(this, args);
 const end = performance.now;
 console.log(`${propertyKey} took ${end - start}ms`);
 return result;
 };

 return descriptor;
}

class API {
 @timer
 async fetchData {
 // implementation
 }
}
```

---

## Modules & Namespaces

### ES6 Modules

```typescript
// Export named
export const config = { timeout: 5000 };
export type User = { id: number; name: string };
export function greet(name: string) { return `Hello, ${name}`; }

// Export default
export default class Logger {
 log(message: string) { console.log(message); }
}

// Import named
import { config, greet } from './util';
import type { User } from './types';

// Import default
import Logger from './logger';

// Import namespace
import * as utils from './util';
utils.config;

// Namespace import
import type * as Types from './types';
```

### Namespaces

```typescript
// Define namespace
namespace Math {
 export const PI = 3.14159;
 export function add(a: number, b: number) {
 return a + b;
 }
}

// Use namespace
Math.add(1, 2);
console.log(Math.PI);

// Nested namespaces
namespace Geometry {
 export namespace 2D {
 export class Circle {
 constructor(public radius: number) {}
 }
 }
}

const circle = new Geometry['2D'].Circle(5);
```

---

## Configuration

### Essential tsconfig.json

```json
{
 "compilerOptions": {
 // Output
 "target": "ES2020",
 "module": "esnext",
 "lib": ["ES2020", "DOM"],
 "declaration": true,
 "declarationMap": true,
 "sourceMap": true,
 "outDir": "./dist",
 "rootDir": "./src",

 // Strict checks (ALWAYS enable)
 "strict": true,
 "noImplicitAny": true,
 "strictNullChecks": true,
 "strictFunctionTypes": true,
 "strictBindCallApply": true,
 "strictPropertyInitialization": true,
 "noImplicitThis": true,

 // Modules
 "esModuleInterop": true,
 "allowSyntheticDefaultImports": true,
 "resolveJsonModule": true,

 // Checking
 "noUnusedLocals": true,
 "noUnusedParameters": true,
 "noImplicitReturns": true,
 "noFallthroughCasesInSwitch": true,
 "noUncheckedIndexedAccess": true,

 // Other
 "skipLibCheck": true,
 "forceConsistentCasingInFileNames": true,
 "resolveJsonModule": true,
 },
 "include": ["src/**/*"],
 "exclude": ["node_modules", "dist", "**/*.test.ts"],
 "ts-node": {
 "esm": true
 }
}
```

---

## Best Practices

### 1. Avoid `any` at All Costs

**Bad**:
```typescript
function process(data: any) {
 return data.toUpperCase; // No error, but will fail at runtime
}
```

**Good**:
```typescript
function process(data: unknown) {
 if (typeof data === 'string') {
 return data.toUpperCase;
 }
 throw new Error('Expected string');
}
```

### 2. Use Branded Types for Semantic Safety

**Bad**:
```typescript
type UserId = number;
type ProductId = number;

function getUser(id: UserId) { /*... */ }

getUser(productId as UserId); // Compiles but wrong!
```

**Good**:
```typescript
type UserId = number & { readonly __brand: 'UserId' };
type ProductId = number & { readonly __brand: 'ProductId' };

// Can't accidentally pass ProductId to UserId
```

### 3. Make Invalid States Unrepresentable

**Bad**:
```typescript
type User = {
 loading: boolean;
 data: UserData | null;
 error: Error | null;
};

// Can represent invalid state: loading=true, data=null, error=null
```

**Good**:
```typescript
type UserState =
 | { status: 'loading' }
 | { status: 'loaded'; data: UserData }
 | { status: 'error'; error: Error };

// Impossible to represent invalid state
```

### 4. Use Const Assertions for Literals

**Bad**:
```typescript
const directions = {
 up: 'up',
 down: 'down',
}; // Types: { up: string; down: string }
```

**Good**:
```typescript
const directions = {
 up: 'up',
 down: 'down',
} as const; // Types: { up: 'up'; down: 'down' }
```

### 5. Leverage Type Inference

```typescript
// Let TypeScript infer types
const user = { name: 'Alice', age: 25 }; // Inferred type
// Instead of: const user: { name: string; age: number } = {... }

// Use ReturnType for function returns
function createUser(name: string) {
 return { name, createdAt: new Date };
}

type User = ReturnType<typeof createUser>;
```

### 6. Use Discriminated Unions

```typescript
// For pattern matching on complex types
type Result<T, E> =
 | { ok: true; value: T }
 | { ok: false; error: E };

function process<T>(result: Result<T, Error>) {
 if (result.ok) {
 console.log(result.value);
 } else {
 console.log(result.error);
 }
}
```

### 7. Enable Strict Mode

Always enable `"strict": true` in tsconfig.json. This enables:
- `noImplicitAny`
- `strictNullChecks`
- `strictFunctionTypes`
- `strictPropertyInitialization`
- And more

### 8. Document Complex Types

```typescript
/**
 * Represents the result of a calculation.
 * Can be in one of three states:
 * - calculating: Request is in progress
 * - success: Calculation completed with value
 * - error: Calculation failed with error
 */
type CalculationState =
 | { status: 'calculating' }
 | { status: 'success'; value: number }
 | { status: 'error'; error: Error };
```

### 9. Use Type Guards Consistently

```typescript
// Define once
function isUser(obj: unknown): obj is User {
 return (
 typeof obj === 'object' &&
 obj !== null &&
 'id' in obj &&
 'name' in obj
 );
}

// Reuse everywhere
if (isUser(data)) {
 console.log(data.name); // Type-safe
}
```

### 10. Module Organization

```
src/
├── types/ # Type definitions
│ ├── user.ts
│ ├── product.ts
│ └── index.ts
├── services/ # Business logic
│ ├── userService.ts
│ └── index.ts
├── components/ # React components
│ └── User.tsx
└── utils/ # Utilities
 ├── helpers.ts
 └── validators.ts
```

---

## Common Pitfalls

### 1. "Implicit any"

**Problem**: Parameter or variable has implicit `any` type

**Fix**: Add explicit type annotation
```typescript
function greet(name: string) { // ✓ explicit
 return `Hello, ${name}`;
}
```

### 2. Circular Type Dependencies

**Problem**:
```typescript
type A = {
 b: B;
};

type B = {
 a: A;
};
```

**Fix**: Use interfaces or extract common type
```typescript
interface A {
 b?: B;
}

interface B {
 a?: A;
}
```

### 3. Type Inference Failures

**Problem**:
```typescript
function createObject<T>(value: T): T {
 return { value } as T; // T doesn't include 'value' property
}
```

**Fix**: Explicitly pass type parameter
```typescript
function createObject<T extends object>(value: T): T {
 return Object.assign({}, value);
}
```

### 4. Void vs Void Return

**Problem**:
```typescript
type Handler = => void;
const handler: Handler = => {
 return 42; // ✓ Allowed (void ignores return)
};
```

**Solution**: Understand void semantics
```typescript
// void return type ignores the return value
const callback: => void = => 'hello'; // ✓
```

### 5. Overspecification

**Problem**:
```typescript
function process(data: { name: string; age: number; email: string }) {
 return data.name; // Only uses name
}
```

**Fix**: Accept looser constraints
```typescript
function process(data: { name: string }) {
 return data.name; // More flexible
}
```

---

## Conclusion

TypeScript provides powerful tools to write type-safe, maintainable code. Key principles:

1. **Type everything** - Functions, parameters, returns
2. **Use strict mode** - Enable all compiler checks
3. **Make invalid states unrepresentable** - Design types to prevent bugs
4. **Document complex types** - Help future maintainers understand intent
5. **Leverage inference** - Don't over-annotate
6. **Use type guards** - Safely narrow types
7. **Prefer interfaces for contracts** - Clear contracts for objects
8. **Master generics** - Write reusable, type-safe code

---

**Last Updated**: November 8, 2025
**Status**: Production-Ready
**Version**: 1.0.0

---

**See Also**:
- [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) - Quick syntax lookups
- [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md) - Project patterns
- [Official TypeScript Handbook](https://www.typescriptlang.org/docs/handbook/)
