# Prisma ORM Knowledge Base

```yaml
id: prisma_readme
topic: Prisma
file_role: Overview and entry point for Prisma KB
profile: full
difficulty_level: all_levels
kb_version: v3.1
prerequisites: []
related_topics:
  - PostgreSQL (../postgresql/)
  - TypeScript (../typescript/)
  - Testing (../testing/)
embedding_keywords:
  - prisma
  - orm
  - database
  - prisma client
  - prisma migrate
  - prisma schema
last_reviewed: 2025-11-16
```

## Welcome to Prisma KB

Comprehensive knowledge base for **Prisma ORM 6.x+** covering schema design, migrations, queries, performance, TypeScript patterns, and advanced techniques.

**Total Content**: 15 files, ~15,000 lines of production-ready patterns and examples

---

## 📚 Documentation Structure

### **Quick Navigation**
- **[INDEX.md](./INDEX.md)** - Problem-based navigation and learning paths
- **[QUICK-REFERENCE.md](./QUICK-REFERENCE.md)** - Command cheat sheet and quick lookups
- **[FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md)** - Integration with Next.js, Express, NestJS

### **Core Files (15 Topics)**

| # | File | Topic | Level | Lines |
|---|------|-------|-------|-------|
| 01 | [FUNDAMENTALS.md](./01-FUNDAMENTALS.md) | Setup, installation, schema basics | Beginner | 9,583 |
| 02 | [SCHEMA-DESIGN.md](./02-SCHEMA-DESIGN.md) | Models, fields, relations, enums | Beginner | 901 |
| 03 | [CLIENT-API.md](./03-CLIENT-API.md) | CRUD operations, queries, filters | Intermediate | 1,115 |
| 04 | [RELATIONS.md](./04-RELATIONS.md) | One-to-one, one-to-many, many-to-many | Intermediate | 1,103 |
| 05 | [MIGRATIONS.md](./05-MIGRATIONS.md) | Schema evolution, migrate dev/deploy | Intermediate | 799 |
| 06 | [TRANSACTIONS.md](./06-TRANSACTIONS.md) | Sequential, interactive, isolation levels | Advanced | 660 |
| 07 | [PERFORMANCE.md](./07-PERFORMANCE.md) | Optimization, N+1 problems, caching | Advanced | 652 |
| 08 | [TESTING.md](./08-TESTING.md) | Unit testing, integration testing, factories | Intermediate | 490 |
| 09 | [TYPESCRIPT-PATTERNS.md](./09-TYPESCRIPT-PATTERNS.md) | Type inference, generics, type safety | Advanced | 864 |
| 10 | [ADVANCED-PATTERNS.md](./10-ADVANCED-PATTERNS.md) | Soft deletes, multi-tenancy, event sourcing | Expert | 905 |
| 11 | [CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) | Production config, deployment, monitoring | Advanced | 4,624 |
| -- | [README.md](./README.md) | Overview (this file) | All | 492 |
| -- | [INDEX.md](./INDEX.md) | Problem-based navigation | All | 180 |
| -- | [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) | Cheat sheet | All | 575 |
| -- | [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md) | Integration patterns | Advanced | 920 |

**Total**: ~23,000+ lines of production-ready Prisma patterns

---

## 🚀 Quick Start

### Installation

```bash
# Install Prisma
npm install prisma @prisma/client --save-dev

# Initialize Prisma with PostgreSQL
npx prisma init --datasource-provider postgresql

# Or with SQLite
npx prisma init --datasource-provider sqlite
```

### First Schema

```prisma
// prisma/schema.prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id        Int      @id @default(autoincrement())
  email     String   @unique
  name      String
  posts     Post[]
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
}

model Post {
  id        Int      @id @default(autoincrement())
  title     String
  content   String
  published Boolean  @default(false)
  authorId  Int
  author    User     @relation(fields: [authorId], references: [id])
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  @@index([authorId])
  @@index([published, createdAt])
}
```

### Generate Client & Migrate

```bash
# Generate Prisma Client
npx prisma generate

# Create migration
npx prisma migrate dev --name init

# Apply migrations (production)
npx prisma migrate deploy
```

### First Query

```typescript
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

// Create with relations
const user = await prisma.user.create({
  data: {
    email: 'alice@example.com',
    name: 'Alice',
    posts: {
      create: [
        { title: 'First Post', content: 'Hello World', published: true },
        { title: 'Second Post', content: 'Draft', published: false },
      ],
    },
  },
  include: { posts: true },
});

// Query with relations
const users = await prisma.user.findMany({
  where: {
    posts: {
      some: {
        published: true,
      },
    },
  },
  include: {
    posts: {
      where: { published: true },
      orderBy: { createdAt: 'desc' },
    },
  },
});

// Update
await prisma.post.update({
  where: { id: 1 },
  data: { published: true },
});

// Delete
await prisma.user.delete({
  where: { id: 1 },
});
```

---

## 📖 Learning Paths

### **Path 1: Beginner (New to Prisma)**

1. [FUNDAMENTALS.md](./01-FUNDAMENTALS.md) - Installation, basic concepts
2. [SCHEMA-DESIGN.md](./02-SCHEMA-DESIGN.md) - Define your data model
3. [CLIENT-API.md](./03-CLIENT-API.md) - CRUD operations
4. [MIGRATIONS.md](./05-MIGRATIONS.md) - Schema evolution
5. [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) - Command reference

**Time**: 4-6 hours | **Outcome**: Build simple CRUD app with Prisma

### **Path 2: Intermediate (Know basics, need best practices)**

1. [RELATIONS.md](./04-RELATIONS.md) - Master relation patterns
2. [PERFORMANCE.md](./07-PERFORMANCE.md) - Optimize queries
3. [TESTING.md](./08-TESTING.md) - Test Prisma applications
4. [TYPESCRIPT-PATTERNS.md](./09-TYPESCRIPT-PATTERNS.md) - Type-safe patterns
5. [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md) - Real-world integration

**Time**: 6-8 hours | **Outcome**: Production-ready Prisma patterns

### **Path 3: Advanced (Production systems)**

1. [TRANSACTIONS.md](./06-TRANSACTIONS.md) - Complex atomic operations
2. [PERFORMANCE.md](./07-PERFORMANCE.md) - Advanced optimization
3. [ADVANCED-PATTERNS.md](./10-ADVANCED-PATTERNS.md) - Soft deletes, multi-tenancy, CQRS
4. [CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) - Production deployment
5. [PostgreSQL KB](../postgresql/) - Database-level optimization

**Time**: 8-12 hours | **Outcome**: Enterprise-scale Prisma architecture

---

## 🎯 Common Tasks

### "I need to design a schema"
→ [SCHEMA-DESIGN.md](./02-SCHEMA-DESIGN.md)
→ [RELATIONS.md](./04-RELATIONS.md)

### "I need to query related data"
→ [CLIENT-API.md](./03-CLIENT-API.md) - Include and select
→ [RELATIONS.md](./04-RELATIONS.md) - Relation queries

### "I need to migrate my database"
→ [MIGRATIONS.md](./05-MIGRATIONS.md)
→ [QUICK-REFERENCE.md](./QUICK-REFERENCE.md#migrations)

### "My queries are slow"
→ [PERFORMANCE.md](./07-PERFORMANCE.md)
→ [PostgreSQL Performance](../postgresql/07-PERFORMANCE.md)

### "I need atomic operations"
→ [TRANSACTIONS.md](./06-TRANSACTIONS.md)

### "I need to test my code"
→ [TESTING.md](./08-TESTING.md)

### "I need type safety"
→ [TYPESCRIPT-PATTERNS.md](./09-TYPESCRIPT-PATTERNS.md)

### "I need soft deletes / multi-tenancy / audit logs"
→ [ADVANCED-PATTERNS.md](./10-ADVANCED-PATTERNS.md)

### "I'm deploying to production"
→ [CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md)

---

## 🔑 Key Concepts

### 1. Schema is Source of Truth

Prisma schema defines your database structure. TypeScript types are auto-generated.

```prisma
model User {
  id    Int    @id @default(autoincrement())
  email String @unique
  name  String
}
```

```typescript
// Auto-generated types
import { User } from '@prisma/client';

const user: User = await prisma.user.findUnique({ where: { id: 1 } });
// Type: { id: number, email: string, name: string }
```

### 2. Migrations for Schema Evolution

Never manually edit your database. Use migrations.

```bash
# Development
npx prisma migrate dev --name add_user_role

# Production
npx prisma migrate deploy
```

### 3. Relations for Data Modeling

Define relations in schema, query with `include`.

```prisma
model User {
  posts Post[]
}

model Post {
  authorId Int
  author   User @relation(fields: [authorId], references: [id])
}
```

```typescript
const user = await prisma.user.findUnique({
  where: { id: 1 },
  include: { posts: true },
});
// Type: User & { posts: Post[] }
```

### 4. Transactions for Atomicity

Use transactions for multi-step operations.

```typescript
await prisma.$transaction([
  prisma.user.create({ data: { email: 'alice@example.com' } }),
  prisma.post.create({ data: { title: 'Post', authorId: 1 } }),
]);
```

### 5. Performance through Indexes

Index foreign keys and frequently queried fields.

```prisma
model Post {
  authorId Int
  author   User @relation(fields: [authorId], references: [id])

  @@index([authorId])
  @@index([published, createdAt])
}
```

---

## ⚠️ Common Pitfalls

### ❌ N+1 Query Problem

```typescript
// BAD - 1 query for users + N queries for posts
const users = await prisma.user.findMany();
for (const user of users) {
  const posts = await prisma.post.findMany({ where: { authorId: user.id } });
}
```

```typescript
// GOOD - 2 queries total
const users = await prisma.user.findMany({
  include: { posts: true },
});
```

### ❌ Missing Indexes

```prisma
// BAD - No index on foreign key
model Post {
  authorId Int
  author   User @relation(fields: [authorId], references: [id])
}
```

```prisma
// GOOD - Indexed foreign key
model Post {
  authorId Int
  author   User @relation(fields: [authorId], references: [id])

  @@index([authorId])
}
```

### ❌ Not Using Transactions

```typescript
// BAD - Can result in partial updates
await prisma.user.create({ data: userData });
await prisma.session.create({ data: sessionData }); // May fail
```

```typescript
// GOOD - Atomic operation
await prisma.$transaction([
  prisma.user.create({ data: userData }),
  prisma.session.create({ data: sessionData }),
]);
```

---

## 🔧 Configuration

### Environment Variables

```bash
# PostgreSQL
DATABASE_URL="postgresql://user:pass@localhost:5432/mydb"

# SQLite
DATABASE_URL="file:./dev.db"

# Connection pooling
DATABASE_URL="postgresql://user:pass@localhost:5432/mydb?connection_limit=10"
```

### Prisma Schema Configuration

```prisma
generator client {
  provider        = "prisma-client-js"
  previewFeatures = ["fullTextSearch", "metrics"]
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}
```

---

## 📊 Files in This Directory

```
docs/kb/prisma/
├── README.md                           # Overview (this file)
├── INDEX.md                            # Problem-based index
├── QUICK-REFERENCE.md                  # Command cheat sheet
├── FRAMEWORK-INTEGRATION-PATTERNS.md   # Next.js, Express, NestJS patterns
├── 01-FUNDAMENTALS.md                  # Setup, installation, basics
├── 02-SCHEMA-DESIGN.md                 # Models, fields, relations
├── 03-CLIENT-API.md                    # CRUD operations, queries
├── 04-RELATIONS.md                     # One-to-one, one-to-many, many-to-many
├── 05-MIGRATIONS.md                    # Schema evolution
├── 06-TRANSACTIONS.md                  # Sequential, interactive transactions
├── 07-PERFORMANCE.md                   # Optimization, N+1, caching
├── 08-TESTING.md                       # Unit, integration testing
├── 09-TYPESCRIPT-PATTERNS.md           # Type safety, generics
├── 10-ADVANCED-PATTERNS.md             # Soft deletes, multi-tenancy, CQRS
└── 11-CONFIG-OPERATIONS.md             # Production config, deployment
```

---

## 🌐 External Resources

- **Official Docs**: https://www.prisma.io/docs
- **Schema Reference**: https://www.prisma.io/docs/reference/api-reference/prisma-schema-reference
- **Client API**: https://www.prisma.io/docs/reference/api-reference/prisma-client-reference
- **Migrate**: https://www.prisma.io/docs/concepts/components/prisma-migrate
- **Best Practices**: https://www.prisma.io/docs/guides/performance-and-optimization

---

**Last Updated**: November 16, 2025
**Prisma Version**: 6.x+
**Total Lines**: 23,000+
**Status**: Production-Ready ✅

---

## Next Steps

1. **New to Prisma?** → Start with [FUNDAMENTALS.md](./01-FUNDAMENTALS.md)
2. **Need quick reference?** → Check [QUICK-REFERENCE.md](./QUICK-REFERENCE.md)
3. **Building production app?** → Review [ADVANCED-PATTERNS.md](./10-ADVANCED-PATTERNS.md) and [CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md)
4. **Optimizing performance?** → Read [PERFORMANCE.md](./07-PERFORMANCE.md) and [PostgreSQL Performance](../postgresql/07-PERFORMANCE.md)

Happy querying! 🔷
