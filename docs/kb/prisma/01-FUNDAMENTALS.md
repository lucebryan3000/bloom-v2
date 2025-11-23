---
id: prisma-01-fundamentals
topic: prisma
file_role: fundamentals
profile: full
difficulty_level: beginner-to-intermediate
kb_version: 3.1
prerequisites: ['databases', 'typescript']
related_topics: ['sql', 'orm', 'database-design']
embedding_keywords: [prisma, orm, database, fundamentals, basics, getting-started]
last_reviewed: 2025-11-16
---

# Prisma Fundamentals

## Purpose

This document covers the core fundamentals of Prisma - what it is, why it exists, and how to think about it. Read this first when learning Prisma or when you need to refresh foundational concepts.

## What is Prisma?

Prisma is a next-generation ORM (Object-Relational Mapping) tool that provides type-safe database access for TypeScript and Node.js applications. It eliminates the gap between your database and application code through auto-generated types and a powerful query API.

### Key Characteristics

- **Type-Safe**: Auto-generates TypeScript types from your database schema
- **Declarative Schema**: Define your data model in Prisma Schema Language
- **Migration System**: Built-in database migration workflow
- **Query Builder**: Intuitive, auto-completed query API
- **Multi-Database**: Supports PostgreSQL, MySQL, SQLite, MongoDB, SQL Server

## Mental Model

Think of Prisma as **the bridge between your database and TypeScript code**.

Instead of writing SQL manually and handling type mismatches, you:
1. Define your schema in `schema.prisma`
2. Run `prisma generate` to get TypeScript types
3. Use the type-safe Prisma Client to query your database

```
schema.prisma (source of truth)
       ↓
  prisma generate
       ↓
TypeScript Types + Query API
       ↓
  Your Application Code
       ↓
    Database
```

### Core Components

1. **Prisma Schema**: Declarative data model definition
2. **Prisma Client**: Auto-generated query builder
3. **Prisma Migrate**: Database migration tool
4. **Prisma Studio**: Visual database browser

## When to Use Prisma

✅ **Good use cases:**
- TypeScript/Node.js applications needing database access
- Projects requiring type safety and auto-completion
- Teams wanting to avoid manual SQL for most operations
- Applications with complex data relationships
- Projects needing database-agnostic code

❌ **Not ideal for:**
- Simple scripts (overkill for basic DB operations)
- Extremely high-performance requirements (raw SQL may be faster)
- Legacy databases with complex custom SQL
- Projects already using another mature ORM successfully

## Golden Path - First Steps

### Installation

```bash
# Install Prisma CLI and Client
npm install prisma @prisma/client --save-dev

# Initialize Prisma in your project
npx prisma init --datasource-provider postgresql
# Or for SQLite:
npx prisma init --datasource-provider sqlite
```

This creates:
- `prisma/schema.prisma` - Your schema file
- `.env` - Database connection URL

### Basic Schema Example

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
  id        String   @id @default(cuid())
  email     String   @unique
  name      String?
  posts     Post[]
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
}

model Post {
  id        String   @id @default(cuid())
  title     String
  content   String?
  published Boolean  @default(false)
  author    User     @relation(fields: [authorId], references: [id])
  authorId  String
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  @@index([authorId])
  @@index([published])
}
```

### Generate Client & Migrate

```bash
# Create migration from schema changes
npx prisma migrate dev --name init

# Generate Prisma Client
npx prisma generate
```

### First Queries

```typescript
import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

// Create
const user = await prisma.user.create({
  data: {
    email: 'alice@example.com',
    name: 'Alice',
    posts: {
      create: [
        { title: 'First Post', content: 'Hello World' }
      ]
    }
  },
  include: { posts: true } // Include related data
})

// Read with filters
const users = await prisma.user.findMany({
  where: {
    email: { contains: '@example.com' },
    posts: { some: { published: true } }
  },
  include: { posts: true },
  orderBy: { createdAt: 'desc' },
  take: 10
})

// Update
await prisma.user.update({
  where: { id: user.id },
  data: { name: 'Alice Smith' }
})

// Delete
await prisma.user.delete({
  where: { id: user.id }
})

// Always disconnect when done
await prisma.$disconnect()
```

## Common Pitfalls

### Pitfall 1: Forgetting to Run Migrations
**Problem**: Schema changes don't appear in database
**Solution**: Always run `prisma migrate dev` after schema changes
**Example**:
```bash
# ❌ Bad - Just editing schema
# Edit schema.prisma, save, run app
# Error: Table doesn't exist

# ✅ Good - Migrate after changes
# 1. Edit schema.prisma
# 2. Run: npx prisma migrate dev --name add_user_role
# 3. Prisma generates migration + updates client
```

### Pitfall 2: Not Using Transactions for Related Operations
**Problem**: Partial data creation when one operation fails
**Solution**: Use `$transaction` for atomic operations
**Example**:
```typescript
// ❌ Bad - Can result in orphaned data
const user = await prisma.user.create({ data: userData })
const session = await prisma.session.create({
  data: { userId: user.id, ...sessionData }
}) // If this fails, user exists but session doesn't

// ✅ Good - Atomic operation
await prisma.$transaction(async (tx) => {
  const user = await tx.user.create({ data: userData })
  await tx.session.create({ data: { userId: user.id, ...sessionData } })
})
```

### Pitfall 3: Missing Indexes on Foreign Keys
**Problem**: Slow queries on related data
**Solution**: Always index foreign keys and frequently queried fields
**Example**:
```prisma
// ❌ Bad - Missing index
model Post {
  author   User   @relation(fields: [authorId], references: [id])
  authorId String
  // Queries like "find posts by author" will be slow
}

// ✅ Good - Indexed foreign key
model Post {
  author   User   @relation(fields: [authorId], references: [id])
  authorId String
  @@index([authorId])
}
```

### Pitfall 4: Using `any` Instead of Generated Types
**Problem**: Loses type safety benefits
**Solution**: Always use Prisma-generated types
**Example**:
```typescript
// ❌ Bad - No type safety
const createUser = async (data: any) => {
  return await prisma.user.create({ data })
}

// ✅ Good - Type-safe
import { Prisma } from '@prisma/client'

const createUser = async (data: Prisma.UserCreateInput) => {
  return await prisma.user.create({ data })
}
```

### Pitfall 5: Not Handling Connection Pooling
**Problem**: "Too many connections" errors in serverless
**Solution**: Reuse Prisma Client instance
**Example**:
```typescript
// ❌ Bad - Creates new instance every request
export async function handler() {
  const prisma = new PrismaClient() // New connection each time!
  const users = await prisma.user.findMany()
  return users
}

// ✅ Good - Singleton pattern
// lib/prisma.ts
import { PrismaClient } from '@prisma/client'

const globalForPrisma = global as unknown as { prisma: PrismaClient }

export const prisma = globalForPrisma.prisma || new PrismaClient()

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma
```

## Schema Syntax Basics

### Field Types

```prisma
model Example {
  // Scalars
  id        String   @id @default(cuid())
  count     Int
  price     Float
  active    Boolean
  data      Json     // Arbitrary JSON

  // Dates
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  // Optional fields
  nickname  String?

  // Arrays
  tags      String[]
}
```

### Relations

```prisma
// One-to-Many
model User {
  id    String @id
  posts Post[]  // User has many Posts
}

model Post {
  id       String @id
  author   User   @relation(fields: [authorId], references: [id])
  authorId String // Foreign key
}

// Many-to-Many
model Post {
  id         String     @id
  categories Category[]
}

model Category {
  id    String @id
  posts Post[]
}
```

### Attributes & Constraints

```prisma
model User {
  id    String @id @default(cuid())     // Primary key with default
  email String @unique                  // Unique constraint
  role  String @default("user")         // Default value

  @@index([email])                      // Database index
  @@unique([email, organizationId])     // Composite unique
}
```

## AI Pair Programming Notes

**When to load this file:**
- Learning Prisma for the first time
- Setting up a new project with Prisma
- Need mental model refresher
- Explaining Prisma to others

**Recommended context bundle:**
- This file (01-FUNDAMENTALS.md)
- QUICK-REFERENCE.md (for quick syntax lookups)
- FRAMEWORK-INTEGRATION-PATTERNS.md (for framework-specific usage)

**What to avoid:**
- Using Prisma without migrations (`prisma db push` is for prototyping only)
- Manually editing migration files (use `prisma migrate` commands)
- Storing Prisma Client in global scope without singleton pattern

**Typical questions this file answers:**
- "What is Prisma and when should I use it?"
- "How do I get started with Prisma?"
- "What are the core components of Prisma?"
- "What are common mistakes when using Prisma?"

**Next steps after reading this:**
- 02-SCHEMA-DESIGN.md (for detailed schema patterns)
- 03-CLIENT-API.md (for query patterns)
- FRAMEWORK-INTEGRATION-PATTERNS.md (for Next.js/Express integration)
