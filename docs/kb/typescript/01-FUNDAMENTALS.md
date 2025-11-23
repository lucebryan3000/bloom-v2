# TypeScript Fundamentals

```yaml
id: typescript_01_fundamentals
topic: TypeScript
file_role: TypeScript fundamentals, types, primitives, type system basics
profile: full
difficulty_level: beginner
kb_version: v3.1
prerequisites:
  - JavaScript basics
related_topics:
  - 02-FUNCTIONS.md
  - 03-OBJECTS-INTERFACES.md
  - 06-TYPE-SYSTEM.md
embedding_keywords:
  - typescript fundamentals
  - typescript types
  - primitives
  - type annotations
  - literal types
  - typescript basics
last_reviewed: 2025-11-17
```

## What is TypeScript?

**TypeScript** is a **typed superset of JavaScript** that compiles to plain JavaScript. It adds optional static typing to JavaScript, enabling better tooling, error detection, and code intelligence.

**Key benefits:**
- **Compile-time error detection** - Catch errors before runtime
- **Better IDE support** - Autocomplete, refactoring, navigation
- **Code documentation** - Types serve as inline documentation
- **Safer refactoring** - Compiler catches breaking changes
- **Large-scale development** - Scales better for big codebases

## Installation

```bash
# Install TypeScript
npm install -D typescript @types/node

# Initialize tsconfig.json
npx tsc --init

# Compile TypeScript
npx tsc

# Watch mode
npx tsc --watch
```

## Basic Usage

```typescript
// hello.ts
function greet(name: string): string {
  return `Hello, ${name}!`;
}

console.log(greet('Alice'));  // ✓
// console.log(greet(42));    // ❌ Error: Argument of type 'number' is not assignable to parameter of type 'string'
```

```bash
# Compile and run
npx tsc hello.ts
node hello.js
```

---

## Primitive Types

### The Eight Primitive Types

TypeScript supports all JavaScript primitives plus some additional types:

#### 1. String

```typescript
const greeting: string = "Hello, World!";
const name: string = 'Alice';
const template: string = `Hello, ${name}!`;

// Multi-line strings
const multiline: string = `Line 1
Line 2
Line 3`;

// Template tag functions (advanced)
function tag(strings: TemplateStringsArray, ...values: any[]): string {
  return strings.raw[0];
}

const result = tag`Hello ${name}!`;

// String methods are type-safe
const upper: string = greeting.toUpperCase();
const substr: string = greeting.substring(0, 5);
```

#### 2. Number

```typescript
// All numbers are floating-point (IEEE 754)
const decimal: number = 42;
const hex: number = 0xFF;        // 255
const binary: number = 0b1010;   // 10
const octal: number = 0o755;     // 493
const exponential: number = 1e3; // 1000

// Special number values
const negative: number = -42;
const float: number = 3.14159;
const infinity: number = Infinity;
const negInfinity: number = -Infinity;
const notANumber: number = NaN;

// Type-safe math operations
const sum: number = 5 + 10;
const product: number = 5 * 10;

// Be aware of floating-point precision
console.log(0.1 + 0.2);  // 0.30000000000000004
console.log(0.1 + 0.2 === 0.3);  // false
```

#### 3. Boolean

```typescript
const active: boolean = true;
const inactive: boolean = false;

// Boolean expressions
const isValid: boolean = age >= 18;
const hasAccess: boolean = user.role === 'admin' || user.isOwner;

// Type narrowing with boolean checks
function process(value: number | string) {
  if (typeof value === "string") {
    // value is string here
    console.log(value.toUpperCase());
  } else {
    // value is number here
    console.log(value.toFixed(2));
  }
}

// Truthy/falsy values
const truthyCheck = !!value;  // Converts to boolean
```

#### 4. BigInt

```typescript
// For integers larger than Number.MAX_SAFE_INTEGER (2^53 - 1)
const big1: bigint = 9007199254740991n;
const big2: bigint = BigInt("9007199254740991");
const big3: bigint = BigInt(9007199254740991);

// Math operations
const sum: bigint = big1 + 100n;
const product: bigint = big1 * 2n;

// ⚠️ Can't mix with number
// const mixed = big1 + 5;  // ❌ Error: cannot mix bigint and other types

// Must convert explicitly
const mixedCorrect = big1 + BigInt(5);  // ✓

// Use cases: cryptography, timestamps, large integers
const timestamp: bigint = BigInt(Date.now());
```

#### 5. Symbol

```typescript
// Create unique symbols
const sym1: symbol = Symbol("description");
const sym2: symbol = Symbol("description");

// Each symbol is unique
console.log(sym1 === sym2);  // false

// Global symbol registry
const globalSym1: symbol = Symbol.for("app.id");
const globalSym2: symbol = Symbol.for("app.id");
console.log(globalSym1 === globalSym2);  // true

// Use case: object property keys
const obj = {
  [sym1]: "value 1",
  [sym2]: "value 2",
  name: "regular property"
};

console.log(obj[sym1]);  // "value 1"

// Symbols don't appear in Object.keys()
console.log(Object.keys(obj));  // ['name']

// Use case: private object properties
const privateField = Symbol("private");

class MyClass {
  [privateField]: string = "secret";

  getPrivate() {
    return this[privateField];
  }
}
```

#### 6. Null

```typescript
const nothing: null = null;

// Represents intentional absence of value
let user: User | null = null;

// null is a distinct value from undefined
console.log(null === undefined);  // false
console.log(null == undefined);   // true (loose equality)

// Type guard for null
function processUser(user: User | null) {
  if (user !== null) {
    // user is User here
    console.log(user.name);
  }
}

// Nullish coalescing operator (??)
const value = possiblyNull ?? "default";  // Uses "default" only if null/undefined
```

#### 7. Undefined

```typescript
const undef: undefined = undefined;

// Represents variables without assigned values
let unassigned: string;  // implicitly undefined
// console.log(unassigned);  // ❌ Error with strict mode

// Function with no return
function noReturn(): undefined {
  console.log("no return");
  // Implicitly returns undefined
}

// Optional parameters
function greet(name?: string): void {
  // name is string | undefined
  console.log(name ?? "Guest");
}

// Difference from null
// undefined: variable exists but has no value
// null: intentional absence of value
```

#### 8. Void

```typescript
// void is not a primitive, but a special type
// Represents absence of return value

function logMessage(message: string): void {
  console.log(message);
  // No return statement
}

// void vs undefined
function returnsUndefined(): undefined {
  return undefined;  // Must explicitly return undefined
}

function returnsVoid(): void {
  // Can return nothing, or return undefined
  return;
}

// In callbacks
type Callback = (data: string) => void;
const callback: Callback = (data) => {
  console.log(data);
  // Return value is ignored
};

// Can return a value, but it's ignored
const callback2: Callback = (data) => "ignored";  // ✓ Valid
```

---

## Type Annotations

### Explicit Type Annotations

```typescript
// Variable annotations
const name: string = "Alice";
const age: number = 25;
const active: boolean = true;

// Function parameter annotations (always required in strict mode)
function greet(name: string, age: number): string {
  return `Hello, ${name}! You are ${age} years old.`;
}

// Arrow functions
const add = (a: number, b: number): number => a + b;

// Function type annotation
const multiply: (a: number, b: number) => number = (a, b) => a * b;

// Const with type annotation
const config: Record<string, number> = {
  timeout: 5000,
  retries: 3,
};
```

### Type Inference

TypeScript infers types when you don't explicitly annotate:

```typescript
// ✅ Inferred: string
const greeting = "Hello";

// ✅ Inferred: number
const count = 42;

// ✅ Inferred: boolean
const isActive = true;

// ✅ Inferred: string[]
const colors = ["red", "green", "blue"];

// ✅ Inferred: number[]
const numbers = [1, 2, 3];

// ✅ Inferred: (string | number)[]
const mixed = [1, "two", 3];

// ⚠️ Inferred: any (avoid this!)
const mystery = JSON.parse('{"foo":"bar"}');

// ✅ Explicit type fixes it
const mystery: { foo: string } = JSON.parse('{"foo":"bar"}');

// Function return type inference
function getName() {
  return "Alice";  // inferred return type: string
}

// Parameter default value inference
function greet(greeting = "Hello") {
  // greeting: string (inferred from default value)
  return greeting.toUpperCase();
}
```

### When to Use Explicit Annotations

```typescript
// ✅ DO annotate:

// 1. Function parameters (always)
function process(data: unknown): void {
  // ...
}

// 2. Function return types (for public APIs)
export function calculateROI(metrics: Metrics): ROIReport {
  // ...
}

// 3. Complex types that are hard to infer
const config: Record<string, number | string | boolean> = {
  timeout: 5000,
  retries: 3,
  debug: false,
};

// 4. When initializing with null/undefined
let user: User | null = null;

// 5. When type is broader than inferred
let value: string | number = "hello";
value = 42;  // ✓ Okay

// ✅ DON'T over-annotate:

// 1. Simple variable assignments
const name = "Alice";  // Clearly a string, no annotation needed
const age = 25;        // Clearly a number

// 2. Array literals with obvious types
const numbers = [1, 2, 3];  // Clearly number[]
const strings = ["a", "b"]; // Clearly string[]

// 3. Object literals with obvious structure
const user = {
  name: "Alice",
  age: 25,
};  // Type is inferred correctly
```

---

## Literal Types

Literal types allow you to specify exact values a variable can have.

### String Literals

```typescript
// Single literal
type Greeting = "hello";
const greeting: Greeting = "hello";  // ✓
// const wrong: Greeting = "hi";     // ❌ Error

// Union of literals (more useful)
type Direction = "up" | "down" | "left" | "right";
const move: Direction = "up";  // ✓
// const wrong: Direction = "forward";  // ❌ Error

// Use case: status values
type Status = "pending" | "completed" | "failed" | "cancelled";

function updateStatus(status: Status): void {
  // Can only pass valid statuses
}

updateStatus("pending");    // ✓
// updateStatus("unknown");  // ❌ Error

// Use case: HTTP methods
type HttpMethod = "GET" | "POST" | "PUT" | "DELETE" | "PATCH";

function request(url: string, method: HttpMethod): Promise<Response> {
  return fetch(url, { method });
}

request("/api/users", "GET");   // ✓
// request("/api/users", "get");  // ❌ Error (case-sensitive)
```

### Number Literals

```typescript
// Small set of numbers
type SmallPrime = 2 | 3 | 5 | 7;
const prime: SmallPrime = 3;  // ✓

// HTTP status codes
type HttpStatus = 200 | 201 | 204 | 400 | 401 | 403 | 404 | 500 | 502 | 503;
const statusCode: HttpStatus = 404;  // ✓

// Dice values
type DiceValue = 1 | 2 | 3 | 4 | 5 | 6;
const roll: DiceValue = 4;  // ✓

// Port numbers
type CommonPort = 80 | 443 | 3000 | 3001 | 8080;
const port: CommonPort = 3000;  // ✓
```

### Boolean Literals

```typescript
// Rare but valid
type AlwaysTrue = true;
type AlwaysFalse = false;

const flag: AlwaysTrue = true;  // ✓
// const flag: AlwaysTrue = false;  // ❌ Error

// Use case: feature flags with literal types
type Feature = {
  name: string;
  enabled: true | false;  // More explicit than boolean
};
```

### Template Literal Types

```typescript
// Create string patterns (TypeScript 4.1+)
type Greeting = `Hello, ${"Alice" | "Bob"}!`;
const msg: Greeting = "Hello, Alice!";  // ✓
// const wrong: Greeting = "Hello, Charlie!";  // ❌ Error

// URL pattern
type URLString = `https://${string}`;
const url: URLString = "https://example.com";  // ✓
// const bad: URLString = "http://example.com";   // ❌ Error

// API endpoint pattern
type GetEndpoint = `GET /api/${string}`;
const endpoint: GetEndpoint = "GET /api/users";  // ✓

// Color hex codes
type HexColor = `#${string}`;
const color: HexColor = "#FF5733";  // ✓

// CSS units
type CSSValue = `${number}px` | `${number}%` | `${number}rem`;
const width: CSSValue = "100px";  // ✓
const height: CSSValue = "50%";   // ✓

// Combining with unions
type HTTPMethod = "GET" | "POST" | "PUT" | "DELETE";
type APIRoute = `/${string}`;
type APICall = `${HTTPMethod} ${APIRoute}`;

const call: APICall = "GET /api/users";  // ✓
```

### Const Assertions

Const assertions (`as const`) create the narrowest possible literal types:

```typescript
// Without 'as const' - infers loose types
const config = {
  apiUrl: "https://api.example.com",
  timeout: 5000,
};
// typeof config: { apiUrl: string; timeout: number }

// With 'as const' - infers literal types
const config = {
  apiUrl: "https://api.example.com",
  timeout: 5000,
} as const;
// typeof config: { readonly apiUrl: "https://api.example.com"; readonly timeout: 5000 }

// Array with const assertion
const directions = ["up", "down", "left", "right"] as const;
// type: readonly ["up", "down", "left", "right"]

// Extract literal type from const array
type Direction = typeof directions[number];  // "up" | "down" | "left" | "right"

// Practical example: configuration
const HTTP_STATUS = {
  OK: 200,
  CREATED: 201,
  BAD_REQUEST: 400,
  NOT_FOUND: 404,
  SERVER_ERROR: 500,
} as const;

type HttpStatusCode = typeof HTTP_STATUS[keyof typeof HTTP_STATUS];
// 200 | 201 | 400 | 404 | 500

function handleResponse(status: HttpStatusCode): void {
  if (status === HTTP_STATUS.OK) {
    // ...
  }
}
```

---

## Special Types

### Any Type (Avoid!)

```typescript
// ❌ DO NOT USE 'any' - it disables type checking
let anything: any = "value";
anything.toUpperCase();      // No type checking
anything.foo.bar.baz();      // No errors, will fail at runtime
anything = 42;               // Can reassign to anything
anything = { x: 1 };

// Any is a "type escape hatch" - use only when absolutely necessary
const data: any = JSON.parse('{"x": 1}');
data.y.z;  // No error, but will be undefined at runtime

// ⚠️ any spreads through your code
function process(value: any): any {  // ❌ any in, any out
  return value.toUpperCase();  // No type safety
}

const result = process(42);  // Returns any
result.foo.bar();  // No error, runtime failure
```

### Unknown Type (Safe Alternative to Any)

```typescript
// ✅ USE 'unknown' INSTEAD OF 'any'
let value: unknown = "something";

// Can't use value without narrowing
// value.toUpperCase();  // ❌ Error: Object is of type 'unknown'

// Must check type first
if (typeof value === "string") {
  value.toUpperCase();  // ✓ Now it's safe
}

// Practical example: API response parsing
function parseJSON(json: string): unknown {
  return JSON.parse(json);
}

const response: unknown = parseJSON('{"name": "Alice"}');

// Type guard
function isUser(obj: unknown): obj is User {
  return (
    typeof obj === "object" &&
    obj !== null &&
    "name" in obj &&
    typeof (obj as any).name === "string"
  );
}

if (isUser(response)) {
  console.log(response.name);  // Type-safe
}

// Another example: processing different types
function process(data: unknown): void {
  if (typeof data === "string") {
    console.log(data.toUpperCase());
  } else if (typeof data === "number") {
    console.log(data.toFixed(2));
  } else if (Array.isArray(data)) {
    console.log(`Array of ${data.length} items`);
  } else if (data !== null && typeof data === "object") {
    console.log(Object.keys(data));
  }
}
```

### Never Type

```typescript
// 'never' represents values that never occur

// Function that never returns (throws)
function throwError(message: string): never {
  throw new Error(message);
}

// Function with infinite loop
function infiniteLoop(): never {
  while (true) {
    // Never exits
  }
}

// Exhaustive checking
type Status = "success" | "error" | "loading";

function handleStatus(status: Status): string {
  if (status === "success") {
    return "Success!";
  } else if (status === "error") {
    return "Error!";
  } else if (status === "loading") {
    return "Loading...";
  } else {
    // If you add a new status and forget to handle it, TypeScript will error here
    const _exhaustiveCheck: never = status;
    return _exhaustiveCheck;
  }
}

// Use case: impossible union members
type Result =
  | { ok: true; value: string }
  | { ok: false; error: Error };

function getResultValue(result: Result): string {
  if (result.ok) {
    return result.value;
  } else {
    throw result.error;
  }
  // Both branches return, so code here is unreachable: never
}

// Type-level programming
type Exclude<T, U> = T extends U ? never : T;
type A = Exclude<"a" | "b" | "c", "a">;  // "b" | "c"
```

### Void Type

```typescript
// 'void' represents absence of return value

function logMessage(message: string): void {
  console.log(message);
  // No return statement
}

// void vs undefined
function returnsUndefined(): undefined {
  return undefined;  // Must explicitly return undefined
}

function returnsVoid(): void {
  // Can return nothing
  return;
}

function alsoVoid(): void {
  // Can return undefined
  return undefined;
}

// In callbacks, void means "return value is ignored"
type Callback = (data: string) => void;

const callback: Callback = (data) => {
  console.log(data);
  // Return value is ignored
};

// Can return a value, but it's ignored
const callback2: Callback = (data) => "ignored";  // ✓ Valid

// Array forEach callback
[1, 2, 3].forEach((num: number): void => {
  console.log(num);
});

// Practical: event handlers
type EventHandler = (event: Event) => void;

const handleClick: EventHandler = (event) => {
  event.preventDefault();
  // No return needed
};
```

---

## Array & Collection Types

### Array Types

```typescript
// Array of numbers
const numbers: number[] = [1, 2, 3];
const moreNumbers: Array<number> = [4, 5, 6];  // Generic syntax

// Array of strings
const strings: string[] = ["a", "b", "c"];

// Array of objects
interface User {
  id: number;
  name: string;
}

const users: User[] = [
  { id: 1, name: "Alice" },
  { id: 2, name: "Bob" },
];

// Array of unions (elements can be different types)
const mixed: (string | number)[] = [1, "two", 3, "four"];

// Multi-dimensional arrays
const matrix: number[][] = [
  [1, 2, 3],
  [4, 5, 6],
];

// Readonly array (prevents modifications)
const readonly: readonly number[] = [1, 2, 3];
// readonly.push(4);  // ❌ Error: Property 'push' does not exist on type 'readonly number[]'

// ReadonlyArray<T> generic
const alsoReadonly: ReadonlyArray<string> = ["a", "b"];

// Array methods are type-safe
const doubled: number[] = numbers.map(n => n * 2);
const filtered: number[] = numbers.filter(n => n > 1);
const sum: number = numbers.reduce((acc, n) => acc + n, 0);
```

### Tuple Types

```typescript
// Fixed-length array with specific types at each position
type Pair = [string, number];
const pair: Pair = ["hello", 42];  // ✓
// const wrong: Pair = [42, "hello"];  // ❌ Error: wrong order

// Can't change types
pair[0] = "world";  // ✓
// pair[0] = 123;    // ❌ Error

// Optional elements
type OptionalTuple = [string, number?];
const with2: OptionalTuple = ["hello", 42];
const with1: OptionalTuple = ["hello"];

// Rest elements (variable-length)
type StringNumberBooleans = [string, number, ...boolean[]];
const tuple1: StringNumberBooleans = ["a", 1, true, false];
const tuple2: StringNumberBooleans = ["a", 1];  // ✓ No booleans

// Labeled tuples (self-documenting, TypeScript 4.0+)
type Response = [success: boolean, code: number, message: string];
const response: Response = [true, 200, "OK"];

// Use case: React useState
function useState<T>(initial: T): [T, (value: T) => void] {
  let state = initial;
  const setState = (value: T) => { state = value; };
  return [state, setState];
}

const [count, setCount] = useState(0);

// Use case: function returning multiple values
function getUserData(id: number): [User, Post[]] {
  const user = fetchUser(id);
  const posts = fetchUserPosts(id);
  return [user, posts];
}

const [user, posts] = getUserData(1);

// Readonly tuples
type ReadonlyPair = readonly [string, number];
const readonlyPair: ReadonlyPair = ["hello", 42];
// readonlyPair[0] = "world";  // ❌ Error
```

---

## Type Inference in Action

### How Inference Works

```typescript
// 1. From assignment
const greeting = "Hello";  // inferred: string
const count = 42;          // inferred: number

// 2. From return value
function getName() {
  return "Alice";  // inferred return type: string
}

// 3. From parameter defaults
function greet(greeting = "Hello") {
  // greeting: string (inferred from default)
  return greeting.toUpperCase();
}

// 4. From context (contextual typing)
const numbers: number[] = [1, 2, 3];
numbers.forEach(n => {
  // n: number (inferred from array element type)
  console.log(n.toFixed(2));
});

// 5. Best common type
const mixed = [1, "two", 3];  // inferred: (string | number)[]

// 6. Union narrowing
function process(value: string | number) {
  if (typeof value === "string") {
    // value: string (narrowed)
    return value.toUpperCase();
  } else {
    // value: number (narrowed)
    return value.toFixed(2);
  }
}
```

### Contextual Typing

```typescript
// TypeScript infers types from usage context

// Array method callbacks
const users = [
  { name: "Alice", age: 25 },
  { name: "Bob", age: 30 },
];

// forEach: user type inferred from array
users.forEach(user => {
  // user: { name: string; age: number }
  console.log(user.name);
});

// map: return type inferred
const names = users.map(user => user.name);  // string[]
const ages = users.map(user => user.age);    // number[]

// filter: return type is subset of input
const adults = users.filter(user => user.age >= 18);
// adults: { name: string; age: number }[]

// Object literals
const handler = {
  onClick(event: MouseEvent) {
    console.log(event.clientX);
  }
};

// Promise chains
fetch("/api/users")
  .then(response => response.json())  // response: Response
  .then(data => {  // data: any (need explicit type)
    // ...
  });

// Better with explicit typing
fetch("/api/users")
  .then(response => response.json())
  .then((data: User[]) => {  // Explicit type
    data.forEach(user => console.log(user.name));  // Type-safe
  });
```

### When Inference Fails

```typescript
// Problem 1: Inference too broad
let value = null;  // inferred: any
value = "string";  // ✓ Okay
value = 42;        // ✓ Okay

// Solution: Explicit type
let value: string | null = null;
// value = 42;  // ❌ Error

// Problem 2: JSON.parse always returns any
const data = JSON.parse('{"x": 1}');  // any
data.y.z;  // No error, but undefined at runtime

// Solution: Explicit type or assertion
const data: { x: number } = JSON.parse('{"x": 1}');
// Or with type guard
const parsed: unknown = JSON.parse('{"x": 1}');
if (isValidData(parsed)) {
  // Use parsed safely
}

// Problem 3: Empty arrays
const emptyArray = [];  // any[]
emptyArray.push("string");  // ✓
emptyArray.push(123);       // ✓

// Solution: Explicit type
const typedArray: string[] = [];
// typedArray.push(123);  // ❌ Error
```

---

## Common Patterns

### Pattern 1: Branded Types (Nominal Typing)

```typescript
// Make domain concepts explicit and type-safe
type UserId = number & { readonly __brand: "UserId" };
type ProductId = number & { readonly __brand: "ProductId" };
type Email = string & { readonly __brand: "Email" };

// Constructor functions
function createUserId(id: number): UserId {
  return id as UserId;
}

function createEmail(email: string): Email {
  if (!email.includes("@")) {
    throw new Error("Invalid email");
  }
  return email as Email;
}

// Type-safe functions
function getUser(id: UserId): User {
  // ...
}

function getProduct(id: ProductId): Product {
  // ...
}

// Can't accidentally mix them
const userId = createUserId(1);
const productId = createProductId(2);

getUser(userId);     // ✓
// getUser(productId);  // ❌ Error: Type 'ProductId' is not assignable to type 'UserId'

// Real-world example
type Percent = number & { readonly __brand: "Percent" };

function createPercent(value: number): Percent {
  if (value < 0 || value > 100) {
    throw new Error("Percent must be between 0 and 100");
  }
  return value as Percent;
}

function applyDiscount(price: number, discount: Percent): number {
  return price * (1 - discount / 100);
}

const discount = createPercent(20);
applyDiscount(100, discount);  // ✓
// applyDiscount(100, 20);      // ❌ Error
```

### Pattern 2: Discriminated Unions (Tagged Unions)

```typescript
// Use literal types to discriminate between union members
type Status = "pending" | "completed" | "failed";

type LoadingState =
  | { status: "loading" }
  | { status: "loaded"; data: string }
  | { status: "error"; error: Error };

function handleState(state: LoadingState): void {
  if (state.status === "loading") {
    console.log("Loading...");
  } else if (state.status === "loaded") {
    console.log(state.data);  // ✓ data is available
  } else {
    console.error(state.error);  // ✓ error is available
  }
}

// More complex example: API responses
type APIResponse<T> =
  | { success: true; data: T }
  | { success: false; error: string; code: number };

function handleResponse<T>(response: APIResponse<T>): T {
  if (response.success) {
    return response.data;  // ✓ Type-safe
  } else {
    throw new Error(`API Error ${response.code}: ${response.error}`);
  }
}
```

### Pattern 3: Type Guards

```typescript
// User-defined type guards
function isString(value: unknown): value is string {
  return typeof value === "string";
}

function isNumber(value: unknown): value is number {
  return typeof value === "number";
}

function isUser(obj: unknown): obj is User {
  return (
    typeof obj === "object" &&
    obj !== null &&
    "id" in obj &&
    "name" in obj &&
    typeof (obj as any).id === "number" &&
    typeof (obj as any).name === "string"
  );
}

// Usage
function process(value: unknown): void {
  if (isString(value)) {
    console.log(value.toUpperCase());  // value: string
  } else if (isNumber(value)) {
    console.log(value.toFixed(2));     // value: number
  }
}

// Real-world: validating API responses
interface User {
  id: number;
  name: string;
  email: string;
}

function isValidUser(data: unknown): data is User {
  return (
    typeof data === "object" &&
    data !== null &&
    "id" in data &&
    typeof (data as any).id === "number" &&
    "name" in data &&
    typeof (data as any).name === "string" &&
    "email" in data &&
    typeof (data as any).email === "string"
  );
}

const response: unknown = await fetch("/api/user").then(r => r.json());
if (isValidUser(response)) {
  console.log(response.name);  // Type-safe!
}
```

---

## Best Practices

### ✅ DO

```typescript
// 1. Use explicit types for function parameters
function greet(name: string, age: number): string {
  return `Hello, ${name}! You are ${age} years old.`;
}

// 2. Leverage type inference for variable assignments
const greeting = "Hello";  // string (inferred)
const count = 42;          // number (inferred)

// 3. Use 'unknown' instead of 'any'
function process(data: unknown): void {
  if (typeof data === "string") {
    console.log(data.toUpperCase());
  }
}

// 4. Use literal types for fixed values
type Status = "pending" | "completed" | "failed";

// 5. Use 'readonly' for immutable values
const config: readonly string[] = ["production", "staging"];

// 6. Use branded types for domain concepts
type UserId = number & { readonly __brand: "UserId" };

// 7. Use const assertions for literal types
const HTTP_STATUS = {
  OK: 200,
  NOT_FOUND: 404,
} as const;
```

### ❌ DON'T

```typescript
// 1. Don't use 'any' to avoid typing
function process(data: any) {  // ❌ Bad
  data.foo.bar.baz();  // No type safety
}

// 2. Don't over-annotate obvious types
const name: string = "Alice";  // ❌ Unnecessary annotation
const age: number = 25;        // ❌ Unnecessary annotation

// Better:
const name = "Alice";  // ✓ Type is obvious
const age = 25;        // ✓ Type is obvious

// 3. Don't mix null and undefined without intention
let value: string | null | undefined;  // ❌ Confusing

// Better:
let value: string | null;  // ✓ Clear intent

// 4. Don't use implicit 'any'
const data = JSON.parse('{}');  // ❌ Returns any

// Better:
const data: User = JSON.parse('{}');  // ✓ Explicit type
```

---

## AI Pair Programming Notes

**When writing TypeScript code:**

1. **Always type function parameters** - TypeScript can't infer these
2. **Use type inference for variables** - Let TypeScript infer when obvious
3. **Prefer `unknown` over `any`** - Forces type checking before use
4. **Use literal types for constants** - Better autocomplete and type safety
5. **Use branded types for domain concepts** - Prevent mixing IDs, emails, etc.
6. **Use const assertions** - Get the narrowest literal types
7. **Write type guards** - Safely narrow `unknown` types
8. **Avoid `any`** - It defeats the purpose of TypeScript

**Common mistakes:**
- Using `any` to bypass type errors (fix the types instead)
- Not handling `null`/`undefined` (use strict mode)
- Over-annotating obvious types (trust inference)
- Missing function return type annotations (always annotate public APIs)
- Using `string` when literal union would be better (`"status" | "pending"`)

---

**Next**: [02-FUNCTIONS.md](./02-FUNCTIONS.md) - Function typing, parameters, overloads

---

**Last Updated**: November 17, 2025
**TypeScript Version**: 5.x+
**Total Lines**: ~1000
**Status**: Production-Ready ✅
