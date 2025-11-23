---
id: typescript-05-generics
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

# TypeScript Generics

**Part 5 of 11 - The TypeScript Knowledge Base**

## Quick Start

```typescript
// Generic function
function identity<T>(value: T): T {
 return value;
}

const str = identity<string>("hello");
const num = identity<number>(42);
const auto = identity("inferred"); // Type inference

// Generic interface
interface Box<T> {
 value: T;
 getValue: T;
}

// Generic class
class Stack<T> {
 private items: T[] = [];
 push(item: T) { this.items.push(item); }
 pop: T | undefined { return this.items.pop; }
}

const stack = new Stack<number>;
stack.push(1);
stack.push(2);
```

## Generic Constraints

```typescript
// Extend type
function getLength<T extends { length: number }>(value: T): number {
 return value.length;
}

getLength("hello"); // ✓
getLength([1, 2]); // ✓
getLength(42); // ERROR

// Keyof constraint
function getProperty<T, K extends keyof T>(obj: T, key: K): T[K] {
 return obj[key];
}

const user = { name: "Alice", age: 25 };
const name = getProperty(user, "name"); // ✓
// getProperty(user, "email"); // ERROR

// Multiple constraints
function merge<T extends object, U extends object>(a: T, b: U): T & U {
 return {...a,...b } as T & U;
}
```

## Advanced Patterns

```typescript
// Generic with default
type Container<T = string> = { value: T };

// Generic with conditional
type IsString<T> = T extends string ? true: false;

// Generic with mapped types
type Getters<T> = {
 [K in keyof T as `get${Capitalize<K & string>}`]: => T[K];
};

// Generic in utility function
function createFactory<T>(constructor: new => T) {
 return => new constructor;
}

// Generic with rest
function concat<T>(...arrays: T[][]): T[] {
 return arrays.flat;
}
```

## Real-World Patterns

```typescript
// Redux-style reducer
type Reducer<S, A> = (state: S, action: A) => S;

function createReducer<S, A>(
 initialState: S,
 handlers: Record<A["type"], Reducer<S, A>>
): Reducer<S, A> {
 return (state, action) => {
 const handler = handlers[action.type];
 return handler ? handler(state, action): state;
 };
}

// API client
class ApiClient<TResponse> {
 async get(url: string): Promise<TResponse> {
 const res = await fetch(url);
 return res.json;
 }
}

// Event emitter
class EventEmitter<Events extends Record<string, any>> {
 private listeners: Record<string, Function[]> = {};

 on<K extends keyof Events>(
 event: K,
 listener: (payload: Events[K]) => void
 ) {
 if (!this.listeners[String(event)]) {
 this.listeners[String(event)] = [];
 }
 this.listeners[String(event)].push(listener);
 }

 emit<K extends keyof Events>(event: K, payload: Events[K]) {
 this.listeners[String(event)]?.forEach(listener => listener(payload));
 }
}
```

## Best Practices

✅ **DO**:
- Use meaningful type parameter names (T, U, K for specific concepts)
- Constraint types when possible
- Use defaults for common cases
- Document generic parameters

❌ **DON'T**:
- Over-parameterize types
- Use `any` within generics
- Create deeply nested generics
- Forget type inference

---

**Next**: [06-TYPE-SYSTEM.md](./06-TYPE-SYSTEM.md)

**Last Updated**: November 8, 2025
