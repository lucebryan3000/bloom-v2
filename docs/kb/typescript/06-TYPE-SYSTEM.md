---
id: typescript-06-type-system
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

# TypeScript Type System: Guards & Narrowing

**Part 6 of 11 - The TypeScript Knowledge Base**

## Union & Intersection Types

```typescript
// Union type
type Status = "active" | "inactive" | "pending";
type Result = string | number | boolean;

// Intersection type
type Admin = User & { permissions: string[] };
type Entity = Id & Timestamped & Named;

// Discriminated union
type Response =
 | { ok: true; data: string }
 | { ok: false; error: Error }
 | { ok: undefined; loading: true };

function handle(response: Response) {
 if (response.ok === true) {
 console.log(response.data); // string
 } else if (response.ok === false) {
 console.log(response.error); // Error
 } else {
 console.log("Loading...");
 }
}
```

## Type Narrowing

```typescript
// typeof guard
function printLength(value: string | number) {
 if (typeof value === "string") {
 console.log(value.length); // value is string
 } else {
 console.log(value.toFixed(2)); // value is number
 }
}

// instanceof guard
class Dog {}
class Cat {}

function sound(animal: Dog | Cat) {
 if (animal instanceof Dog) {
 console.log("Woof"); // animal is Dog
 } else {
 console.log("Meow"); // animal is Cat
 }
}

// Property check
function process(value: { x: number } | { y: string }) {
 if ("x" in value) {
 console.log(value.x); // { x: number }
 } else {
 console.log(value.y); // { y: string }
 }
}

// Truthiness
function check(value: string | null | undefined) {
 if (value) {
 console.log(value); // string
 }
}
```

## Type Guards

```typescript
// Type predicate
function isString(value: unknown): value is string {
 return typeof value === "string";
}

function isUser(obj: unknown): obj is User {
 return (
 obj !== null &&
 typeof obj === "object" &&
 "name" in obj &&
 "email" in obj
 );
}

const values: unknown[] = [1, "hello", true];
const strings = values.filter(isString); // string[]

// Assertion function
function assertIsString(value: unknown): asserts value is string {
 if (typeof value !== "string") {
 throw new TypeError("Must be string");
 }
}

function process(value: unknown) {
 assertIsString(value);
 console.log(value.toUpperCase); // value is string
}

// Non-null assertion
function getValue: string | null {
 return "value";
}

const value = getValue;
console.log(value!.toUpperCase); // ! asserts non-null
```

## Exhaustiveness Checking

```typescript
type Status = "active" | "inactive" | "pending";

function handleStatus(status: Status) {
 switch (status) {
 case "active":
 return "Active";
 case "inactive":
 return "Inactive";
 case "pending":
 return "Pending";
 default:
 const exhaustive: never = status; // ERROR if new status added
 }
}

// With unions
type Action =
 | { type: "INCREMENT"; payload: number }
 | { type: "DECREMENT"; payload: number };

function reducer(state: number, action: Action): number {
 switch (action.type) {
 case "INCREMENT":
 return state + action.payload;
 case "DECREMENT":
 return state - action.payload;
 default:
 const never: never = action; // ERROR if new action added
 }
}
```

## Advanced Patterns

```typescript
// Type predicate with generics
function isArrayOf<T>(
 predicate: (value: unknown) => value is T
) {
 return (value: unknown): value is T[] => {
 return Array.isArray(value) && value.every(predicate);
 };
}

// Polymorphic type narrowing
function process<T extends { type: string }>(item: T) {
 if (item.type === "user") {
 // T is narrowed, but type checker might not understand
 // Use type guards for clarity
 }
}

// User-defined type guards
const isEmail = (value: unknown): value is string => {
 return typeof value === "string" && value.includes("@");
};
```

---

**Next**: [07-ADVANCED-TYPES.md](./07-ADVANCED-TYPES.md)

**Last Updated**: November 8, 2025
