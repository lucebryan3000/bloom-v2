---
id: typescript-09-decorators-metadata
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

# TypeScript Decorators & Metadata

**Part 9 of 11 - The TypeScript Knowledge Base**

## Class Decorators

```typescript
// Basic decorator
function sealed<T extends { new(...args: any[]): {} }>(constructor: T) {
 Object.seal(constructor);
 Object.seal(constructor.prototype);
 return constructor;
}

@sealed
class User {
 constructor(public name: string) {}
}

// Decorator factory
function logClass<T extends { new(...args: any[]): {} }>(constructor: T) {
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

## Property Decorators

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
 apiUrl = "https://api.example.com";
}
```

## Method Decorators

```typescript
function timer(
 target: any,
 propertyKey: string,
 descriptor: PropertyDescriptor
) {
 const original = descriptor.value;

 descriptor.value = async function (...args: any[]) {
 const start = performance.now;
 const result = await original.apply(this, args);
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

## Reflect Metadata API

```typescript
import "reflect-metadata";

function serialize(
 target: any,
 propertyKey: string,
 parameterIndex: number
) {
 Reflect.defineMetadata("serialize", true, target, propertyKey, parameterIndex);
}

class User {
 constructor(@serialize firstName: string, @serialize lastName: string) {}
}

// Read metadata
const metadata = Reflect.getMetadata("serialize", User);
```

## Real-World Patterns

```typescript
// Validation decorator
function validate(rules: Record<string, Function>) {
 return function (target: any, propertyKey: string) {
 Reflect.defineMetadata("validate", rules, target, propertyKey);
 };
}

// Memoization
function memoize(target: any, propertyKey: string, descriptor: PropertyDescriptor) {
 const original = descriptor.value;
 const cache = new Map;

 descriptor.value = function (...args: any[]) {
 const key = JSON.stringify(args);
 if (cache.has(key)) {
 return cache.get(key);
 }
 const result = original.apply(this, args);
 cache.set(key, result);
 return result;
 };

 return descriptor;
}

// Logging
function log(target: any, propertyKey: string, descriptor: PropertyDescriptor) {
 const original = descriptor.value;

 descriptor.value = function (...args: any[]) {
 console.log(`Calling ${propertyKey} with:`, args);
 return original.apply(this, args);
 };

 return descriptor;
}
```

---

**Next**: [10-MODULES-NAMESPACES.md](./10-MODULES-NAMESPACES.md)

**Last Updated**: November 8, 2025
