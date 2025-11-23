---
id: typescript-11-config-best-practices
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

# TypeScript Configuration & Best Practices

**Part 11 of 11 - The TypeScript Knowledge Base**

## Essential tsconfig.json

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

 // Strict mode (ALWAYS enable)
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
 "forceConsistentCasingInFileNames": true
 },
 "include": ["src/**/*"],
 "exclude": ["node_modules", "dist"]
}
```

## Best Practices (18 Key Principles)

1. **Always enable strict mode** - Catches more errors at compile time
2. **Use explicit types for APIs** - Function parameters and return types
3. **Avoid `any` at all costs** - Use `unknown` instead
4. **Use `const` by default** - More predictable code
5. **Prefer `readonly` properties** - Prevents accidental mutations
6. **Use discriminated unions** - Safer than simple unions
7. **Make invalid states unrepresentable** - Design types to prevent bugs
8. **Use branded types** - Semantic safety (UserId vs ProductId)
9. **Leverage type inference** - Don't over-annotate
10. **Document complex types** - JSDoc comments help maintainers
11. **Use type guards** - Check unknown types safely
12. **Prefer interfaces for objects** - Type for complex shapes
13. **Keep generics simple** - Max 3 type parameters usually
14. **Use const assertions** - For literal types
15. **Enable noUnusedLocals** - Catch dead code
16. **Use noImplicitReturns** - Ensure all paths return
17. **Module organization** - Group related types
18. **Test with TypeScript** - Catch errors before runtime

## Common Pitfalls

### 1. Over-using `any`

**Bad**:
```typescript
function process(data: any) {
 return data.toUpperCase;
}
```

**Good**:
```typescript
function process(data: unknown): string {
 if (typeof data === "string") {
 return data.toUpperCase;
 }
 throw new Error("Expected string");
}
```

### 2. Circular Dependencies

**Bad**:
```typescript
// user.ts
import { Service } from "./service";
export interface User {}

// service.ts
import { User } from "./user";
export class Service {}
```

**Good**:
```typescript
// user.ts
export interface User {}

// service.ts
import type { User } from "./user"; // Type-only import
export class Service {}
```

### 3. Implicit `any`

**Bad**:
```typescript
const getValue = (obj, key) => obj[key];
```

**Good**:
```typescript
const getValue = <T, K extends keyof T>(obj: T, key: K): T[K] => obj[key];
```

### 4. Not Using Strict Null Checks

**Bad**:
```typescript
function getName(user: User): string {
 return user.name; // May be null without strictNullChecks
}
```

**Good**:
```typescript
function getName(user: User): string {
 return user.name ?? "Unknown";
}
```

### 5. Type Assertions Everywhere

**Bad**:
```typescript
const user = response as User; // Dangerous!
```

**Good**:
```typescript
function isUser(obj: unknown): obj is User {
 return obj !== null && typeof obj === "object" && "name" in obj;
}

if (isUser(response)) {
 // Safe: response is definitely User
}
```

### 6. Not Documenting Types

**Bad**:
```typescript
type Action = A | B | C;
```

**Good**:
```typescript
/**
 * Represents possible user actions
 * - A: Create action
 * - B: Update action
 * - C: Delete action
 */
type Action = "create" | "update" | "delete";
```

### 7. Overly Complex Generics

**Bad**:
```typescript
type Complex<T extends Record<K, any>, K extends keyof T> = T[K] extends Array<infer U>
 ? U extends { [P in keyof U]: U[P] extends Function ? never: U[P] }
 ? T[K]
: never
: never;
```

**Good**:
```typescript
type ArrayElement<T extends any[]> = T extends (infer E)[] ? E: never;
```

### 8. Not Using Type Guards

**Bad**:
```typescript
const values: (string | number)[] = [1, "two", 3];
values.map(v => v.toUpperCase); // ERROR
```

**Good**:
```typescript
const isString = (v: unknown): v is string => typeof v === "string";

values.filter(isString).map(v => v.toUpperCase); // ✓
```

## Performance Tips

1. **Skip library checking** - `skipLibCheck: true`
2. **Use project references** - For monorepos
3. **Enable incremental compilation** - `incremental: true`
4. **Cache type checking** - Use appropriate tools
5. **Profile compilation** - Use `--diagnostics`

## Testing TypeScript

```typescript
// test.ts
import { describe, it, expect } from "vitest";

describe("User", => {
 it("should create user", => {
 const user: User = { id: 1, name: "Alice" };
 expect(user.name).toBe("Alice");
 });
});
```

---

## Summary

✅ **DO**:
- Enable strict mode
- Type function parameters and returns
- Use type guards for unknown types
- Keep types simple and focused
- Document complex types
- Test your types

❌ **DON'T**:
- Use `any` carelessly
- Over-complicate generic types
- Skip `noUnusedLocals` and related
- Use type assertions excessively
- Ignore circular dependencies
- Ship without testing types

---

**You've completed all 11 parts!** 🎉

**Total Coverage**: 4,500+ lines of TypeScript documentation

---

**Last Updated**: November 8, 2025
**Status**: Production-Ready ✅
