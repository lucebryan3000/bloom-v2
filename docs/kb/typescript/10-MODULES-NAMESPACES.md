---
id: typescript-10-modules-namespaces
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

# TypeScript Modules & Namespaces

**Part 10 of 11 - The TypeScript Knowledge Base**

## ES6 Modules

```typescript
// Named exports
export const config = { timeout: 5000 };
export type User = { id: number; name: string };
export function greet(name: string): string {
 return `Hello, ${name}`;
}
export class Logger {
 log(message: string) { console.log(message); }
}

// Default export
export default class Application {
 run {}
}

// Export renaming
export { User as UserType, config as Config };

// Import named
import { config, greet, Logger } from "./util";
import type { User } from "./types";

// Import default
import Application from "./app";

// Import namespace
import * as utils from "./util";
utils.config;

// Dynamic import
const module = await import("./utils");
```

## Export Strategies

```typescript
// Barrel export (re-export)
// src/index.ts
export { User, Admin } from "./types";
export { createUser, deleteUser } from "./services";
export * from "./constants";

// Selective re-export
export type { User, Product };
export { createUser };

// Mixed exports
export { default as Logger } from "./logger";
export * from "./types";
```

## Type-Only Imports

```typescript
// Import only for types (not runtime)
import type { User, Config } from "./types";

// Prevents circular dependencies
import type { Service } from "./service";

// Type-only namespace
import type * as Types from "./types";
```

## Namespaces

```typescript
// Define namespace
namespace Math {
 export const PI = 3.14159;
 export function add(a: number, b: number): number {
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
 area { return Math.PI * this.radius ** 2; }
 }
 }
}

const circle = new Geometry["2D"].Circle(5);
```

## Module Augmentation

```typescript
// Extend existing module
declare global {
 interface Window {
 myCustomProperty: string;
 }
}

Window.myCustomProperty = "value";

// Augment imported module
declare module "express" {
 interface Request {
 user?: User;
 }
}

app.use((req, res) => {
 const user = req.user; // Now typed
});
```

## Best Practices

✅ **DO**:
- Use named exports for flexibility
- Use default export for main functionality
- Group related exports in files
- Use type-only imports to prevent circular deps
- Use barrel exports to organize modules

❌ **DON'T**:
- Mix default and named heavily
- Create circular dependencies
- Export everything (`*`)
- Use namespaces in modern code
- Over-organize modules

---

**Next**: [11-CONFIG-BEST-PRACTICES.md](./11-CONFIG-BEST-PRACTICES.md)

**Last Updated**: November 8, 2025
