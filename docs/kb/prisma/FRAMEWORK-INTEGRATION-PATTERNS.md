---
id: prisma-patterns
topic: prisma
file_role: patterns
profile: full
difficulty_level: intermediate-advanced
kb_version: 3.1
prerequisites: [prisma-basics, typescript, databases]
related_topics: [nextjs, postgresql, sqlite]
embedding_keywords: [patterns, examples, integration, best-practices, prisma-patterns, orm]
last_reviewed: 2025-11-13
---

# Prisma Framework Integration Patterns

**Purpose**: Production-ready Prisma ORM patterns and integration examples.

---

## 📋 Table of Contents

1. [Next.js Integration](#nextjs-integration)
2. [CRUD Operations](#crud-operations)
3. [Relations](#relations)
4. [Transactions](#transactions)
5. [Performance](#performance)

---

## Next.js Integration

### Pattern 1: Prisma Client Singleton

```typescript
// lib/prisma.ts
import { PrismaClient } from '@prisma/client';

const globalForPrisma = global as unknown as { prisma: PrismaClient };

export const prisma =
 globalForPrisma.prisma ||
 new PrismaClient({
 log: ['query'],
 });

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma;
```

### Pattern 2: API Route with Prisma

```typescript
// app/api/users/route.ts
import { prisma } from '@/lib/prisma';
import { NextResponse } from 'next/server';

export async function GET {
 const users = await prisma.user.findMany({
 include: { posts: true }
 });
 return NextResponse.json(users);
}
```

---

## CRUD Operations

### Pattern 3: Create with Relations

```typescript
const user = await prisma.user.create({
 data: {
 email: 'user@example.com',
 name: 'John Doe',
 posts: {
 create: [
 { title: 'First Post', content: 'Hello World' }
 ]
 }
 },
 include: { posts: true }
});
```

### Pattern 4: Complex Filtering

```typescript
const users = await prisma.user.findMany({
 where: {
 AND: [
 { email: { contains: '@example.com' } },
 { posts: { some: { published: true } } }
 ]
 },
 orderBy: { createdAt: 'desc' },
 take: 10,
 skip: 0
});
```

---

## Relations

### Pattern 5: One-to-Many Queries

```typescript
const userWithPosts = await prisma.user.findUnique({
 where: { id: userId },
 include: {
 posts: {
 where: { published: true },
 orderBy: { createdAt: 'desc' }
 }
 }
});
```

### Pattern 6: Many-to-Many Relations

```typescript
const post = await prisma.post.create({
 data: {
 title: 'Post Title',
 content: 'Post content',
 categories: {
 connect: [
 { id: categoryId1 },
 { id: categoryId2 }
 ]
 }
 },
 include: { categories: true }
});
```

---

## Transactions

### Pattern 7: Interactive Transactions

```typescript
const result = await prisma.$transaction(async (tx) => {
 const user = await tx.user.create({
 data: { email: 'user@example.com', name: 'John' }
 });

 const post = await tx.post.create({
 data: {
 title: 'First Post',
 authorId: user.id
 }
 });

 return { user, post };
});
```

### Pattern 8: Batch Operations

```typescript
const updateMany = await prisma.user.updateMany({
 where: {
 email: { contains: '@old-domain.com' }
 },
 data: {
 email: { replace: { from: '@old-domain.com', to: '@new-domain.com' } }
 }
});
```

---

## Performance

### Pattern 9: Select Specific Fields

```typescript
const users = await prisma.user.findMany({
 select: {
 id: true,
 email: true,
 posts: {
 select: {
 id: true,
 title: true
 }
 }
 }
});
```

### Pattern 10: Connection Pooling

```typescript
// prisma/schema.prisma
datasource db {
 provider = "postgresql"
 url = env("DATABASE_URL")
 directUrl = env("DIRECT_URL")
}
```

---

## Best Practices

1. **Use Singleton Pattern**: One Prisma Client instance per app
2. **Type Safety**: Leverage Prisma's generated types
3. **Transactions**: Use for multi-step operations
4. **Select Fields**: Only query fields you need
5. **Connection Pooling**: Configure for production

---

## Related Files

- **Overview**: [README.md](./README.md)
- **Navigation**: [INDEX.md](./INDEX.md)

---

**All examples are production-ready patterns. Adapt them to your database schema!**
