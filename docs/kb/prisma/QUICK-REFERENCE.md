---
id: prisma-quick-reference
topic: prisma
file_role: quickref
profile: full
difficulty_level: all-levels
kb_version: 3.1
prerequisites: []
related_topics: [database, orm, typescript, nextjs]
embedding_keywords: [prisma-quickref, prisma-snippets, orm-examples, database-queries]
last_reviewed: 2025-11-13
---

# Prisma - Quick Reference

**Purpose**: Copy-paste snippets for common Prisma operations

**Usage**: Ctrl+F/Cmd+F to search, copy code directly

---

## 🔧 Setup & Configuration

### Prisma Client Singleton (Next.js)

```typescript
// lib/prisma.ts
import { PrismaClient } from '@prisma/client';

const globalForPrisma = global as unknown as { prisma: PrismaClient };

export const prisma =
  globalForPrisma.prisma ||
  new PrismaClient({
    log: ['query', 'error', 'warn'],
  });

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma;
```

### Environment Variables

```bash
# .env
DATABASE_URL="file:./dev.db"  # SQLite
# DATABASE_URL="postgresql://user:password@localhost:5432/mydb"  # PostgreSQL
```

---

## 📊 CRUD Operations

### Create

```typescript
// Create single record
const user = await prisma.user.create({
  data: {
    email: 'user@example.com',
    name: 'John Doe',
  },
});

// Create with relations
const post = await prisma.post.create({
  data: {
    title: 'My Post',
    content: 'Post content',
    author: {
      connect: { id: userId },
    },
  },
});

// Create many
const users = await prisma.user.createMany({
  data: [
    { email: 'user1@example.com', name: 'User 1' },
    { email: 'user2@example.com', name: 'User 2' },
  ],
});
```

### Read

```typescript
// Find unique
const user = await prisma.user.findUnique({
  where: { id: userId },
});

// Find first
const user = await prisma.user.findFirst({
  where: { email: 'user@example.com' },
});

// Find many
const users = await prisma.user.findMany({
  where: {
    email: { contains: '@example.com' },
  },
  orderBy: { createdAt: 'desc' },
  take: 10,
  skip: 0,
});

// Find with relations
const user = await prisma.user.findUnique({
  where: { id: userId },
  include: {
    posts: true,
    profile: true,
  },
});

// Count
const count = await prisma.user.count({
  where: { active: true },
});
```

### Update

```typescript
// Update one
const user = await prisma.user.update({
  where: { id: userId },
  data: {
    name: 'New Name',
    updatedAt: new Date(),
  },
});

// Update many
const result = await prisma.user.updateMany({
  where: { active: false },
  data: { status: 'inactive' },
});

// Upsert (update or create)
const user = await prisma.user.upsert({
  where: { email: 'user@example.com' },
  update: { name: 'Updated Name' },
  create: {
    email: 'user@example.com',
    name: 'New User',
  },
});
```

### Delete

```typescript
// Delete one
const user = await prisma.user.delete({
  where: { id: userId },
});

// Delete many
const result = await prisma.user.deleteMany({
  where: { active: false },
});
```

---

## 🔗 Relations

### One-to-Many

```typescript
// Get user with posts
const user = await prisma.user.findUnique({
  where: { id: userId },
  include: {
    posts: {
      orderBy: { createdAt: 'desc' },
      take: 10,
    },
  },
});

// Get post with author
const post = await prisma.post.findUnique({
  where: { id: postId },
  include: {
    author: true,
  },
});
```

### Many-to-Many

```typescript
// Create with many-to-many relation
const post = await prisma.post.create({
  data: {
    title: 'My Post',
    categories: {
      connect: [{ id: categoryId1 }, { id: categoryId2 }],
    },
  },
});

// Query with many-to-many
const post = await prisma.post.findUnique({
  where: { id: postId },
  include: {
    categories: true,
  },
});
```

---

## 🔍 Filtering & Sorting

### Where Clauses

```typescript
// Equals
where: { status: 'active' }

// Not equals
where: { status: { not: 'deleted' } }

// In array
where: { status: { in: ['active', 'pending'] } }

// Contains (string)
where: { email: { contains: '@example.com' } }

// Starts with
where: { name: { startsWith: 'John' } }

// Greater than / Less than
where: {
  createdAt: { gte: new Date('2024-01-01') },
  price: { lte: 100 },
}

// AND / OR
where: {
  AND: [
    { status: 'active' },
    { email: { contains: '@example.com' } },
  ],
}

where: {
  OR: [
    { status: 'active' },
    { status: 'pending' },
  ],
}
```

### Sorting

```typescript
// Single field
orderBy: { createdAt: 'desc' }

// Multiple fields
orderBy: [
  { status: 'asc' },
  { createdAt: 'desc' },
]

// Relation field
orderBy: {
  author: {
    name: 'asc',
  },
}
```

### Pagination

```typescript
// Offset pagination
const users = await prisma.user.findMany({
  skip: (page - 1) * pageSize,
  take: pageSize,
  orderBy: { createdAt: 'desc' },
});

// Cursor pagination
const users = await prisma.user.findMany({
  take: 10,
  skip: 1,  // Skip the cursor
  cursor: {
    id: lastUserId,
  },
  orderBy: { id: 'asc' },
});
```

---

## 💾 Transactions

### Sequential Transactions

```typescript
const result = await prisma.$transaction(async (tx) => {
  // Create user
  const user = await tx.user.create({
    data: { email: 'user@example.com', name: 'John' },
  });

  // Create post
  const post = await tx.post.create({
    data: {
      title: 'First Post',
      authorId: user.id,
    },
  });

  return { user, post };
});
```

### Batch Transactions

```typescript
const [deleteResult, createResult] = await prisma.$transaction([
  prisma.post.deleteMany({ where: { published: false } }),
  prisma.post.create({ data: { title: 'New Post' } }),
]);
```

---

## 📈 Aggregations

### Count, Sum, Avg

```typescript
// Count
const count = await prisma.user.count();

// Aggregate
const result = await prisma.order.aggregate({
  _sum: { total: true },
  _avg: { total: true },
  _min: { total: true },
  _max: { total: true },
  _count: true,
});

// Group by
const result = await prisma.order.groupBy({
  by: ['status'],
  _count: { id: true },
  _sum: { total: true },
});
```

---

## 🛠️ Common Commands

```bash
# Generate Prisma Client
npx prisma generate

# Create migration (dev)
npx prisma migrate dev --name init

# Deploy migration (prod)
npx prisma migrate deploy

# Reset database
npx prisma migrate reset

# Prisma Studio (GUI)
npx prisma studio

# Format schema
npx prisma format

# Validate schema
npx prisma validate

# Pull schema from database
npx prisma db pull

# Push schema to database (prototyping)
npx prisma db push
```

---

## 🔗 Related Files

- **[README.md](./README.md)** - Complete overview
- **[FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md)** - Integration patterns
- **[INDEX.md](./INDEX.md)** - Complete navigation

---

**Last Updated**: 2025-11-13
**KB Version**: 3.1
