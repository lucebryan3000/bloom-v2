#!/bin/bash

# Create all remaining numbered files for Prisma KB

for i in {02..10}; do
  file=$(printf "%02d" $i)
  
  case $i in
    2) name="SCHEMA-DESIGN" ;;
    3) name="CLIENT-API" ;;
    4) name="RELATIONS" ;;
    5) name="MIGRATIONS" ;;
    6) name="TRANSACTIONS" ;;
    7) name="PERFORMANCE" ;;
    8) name="TESTING" ;;
    9) name="TYPESCRIPT-PATTERNS" ;;
    10) name="ADVANCED-PATTERNS" ;;
  esac
  
  cat > "${file}-${name}.md" << FILEEOF
---
id: prisma-${file}-$(echo $name | tr '[:upper:]' '[:lower:]')
topic: prisma
file_role: $([ $i -le 3 ] && echo "core" || ([ $i -le 7 ] && echo "practical" || echo "advanced"))
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [prisma-fundamentals]
related_topics: [typescript, databases]
embedding_keywords: [prisma, $(echo $name | tr '[:upper:]' '[:lower:]' | tr '-' ' ')]
last_reviewed: 2025-11-16
---

# Prisma - ${name//-/ }

## Purpose

This document covers ${name//-/ } in Prisma ORM.

[Content to be expanded based on specific topic needs]

## Key Concepts

[Topic-specific concepts]

## Patterns

### Pattern 1: [Name]

\`\`\`typescript
// Example
\`\`\`

## Common Pitfalls

### Pitfall 1: [Name]
**Problem**: [description]
**Solution**: [fix]

## AI Pair Programming Notes

**When to load this file:**
- Working with ${name//-/ }

**Typical questions:**
- "How do I [common task]?"
FILEEOF

done

# Create 11-CONFIG-OPERATIONS.md
cat > "11-CONFIG-OPERATIONS.md" << 'CONFIGEOF'
---
id: prisma-11-config-operations
topic: prisma
file_role: config
profile: full
difficulty_level: intermediate-to-advanced
kb_version: 3.1
prerequisites: [prisma-fundamentals]
related_topics: [deployment, operations]
embedding_keywords: [prisma, configuration, deployment, production, operations]
last_reviewed: 2025-11-16
---

# Prisma - Configuration & Operations

## Purpose

Covers configuration, deployment, monitoring, and operational concerns for Prisma in production environments.

## Configuration

### Development Configuration

\`\`\`prisma
// schema.prisma
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

generator client {
  provider = "prisma-client-js"
}
\`\`\`

\`\`\`env
# .env
DATABASE_URL="postgresql://user:password@localhost:5432/mydb?schema=public"
\`\`\`

### Production Configuration

\`\`\`env
# Production with connection pooling
DATABASE_URL="postgresql://user:password@prod-host:5432/mydb?connection_limit=10&pool_timeout=20"
\`\`\`

### Environment Variables

| Variable | Purpose | Required | Default |
|----------|---------|----------|---------|
| DATABASE_URL | Database connection string | Yes | - |
| PRISMA_QUERY_ENGINE_LIBRARY | Custom query engine path | No | Auto |
| PRISMA_CLI_BINARY_TARGETS | Deployment targets | No | native |

## Deployment Patterns

### Pattern 1: Docker Deployment

\`\`\`dockerfile
FROM node:20-alpine

WORKDIR /app
COPY package*.json ./
COPY prisma ./prisma/

RUN npm ci
RUN npx prisma generate

COPY . .
RUN npm run build

CMD ["sh", "-c", "npx prisma migrate deploy && npm start"]
\`\`\`

### Pattern 2: Serverless (AWS Lambda, Vercel)

\`\`\`typescript
// Use singleton pattern
import { PrismaClient } from '@prisma/client'

const globalForPrisma = global as unknown as { prisma: PrismaClient }

export const prisma = globalForPrisma.prisma || new PrismaClient()

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma
\`\`\`

## Monitoring & Observability

### Query Logging

\`\`\`typescript
const prisma = new PrismaClient({
  log: [
    { level: 'query', emit: 'event' },
    { level: 'error', emit: 'stdout' },
    { level: 'warn', emit: 'stdout' },
  ],
})

prisma.$on('query', (e) => {
  console.log('Query: ' + e.query)
  console.log('Duration: ' + e.duration + 'ms')
})
\`\`\`

### Key Metrics to Track

1. **Query Performance**: Track slow queries (>100ms)
2. **Connection Pool**: Monitor active/idle connections
3. **Error Rates**: Database errors, constraint violations
4. **Migration Status**: Track migration success/failures

## Performance Tuning

### Connection Pooling

\`\`\`env
# PostgreSQL connection limits
DATABASE_URL="postgresql://user:pass@host:5432/db?connection_limit=10&pool_timeout=20"
\`\`\`

### Query Optimization

\`\`\`typescript
// ❌ Bad - N+1 query problem
const posts = await prisma.post.findMany()
for (const post of posts) {
  const author = await prisma.user.findUnique({ where: { id: post.authorId } })
}

// ✅ Good - Use include
const posts = await prisma.post.findMany({
  include: { author: true }
})
\`\`\`

## Security Considerations

### SQL Injection Protection
Prisma automatically prevents SQL injection through parameterized queries.

### Sensitive Data
\`\`\`prisma
model User {
  id       String @id
  email    String @unique
  password String // Should be hashed before storing
}
\`\`\`

### Access Control
Use RLS (Row-Level Security) at database level or implement in application:

\`\`\`typescript
// Filter based on user context
const userPosts = await prisma.post.findMany({
  where: {
    OR: [
      { authorId: userId }, // User's own posts
      { published: true }   // Or published posts
    ]
  }
})
\`\`\`

## Troubleshooting

### Issue 1: "Too Many Connections"
**Symptoms**: `Error: Can't reach database server`
**Diagnosis**: Check connection pool settings
**Fix**: 
\`\`\`env
DATABASE_URL="postgresql://...?connection_limit=5"
\`\`\`

### Issue 2: Slow Migrations
**Symptoms**: Migration takes minutes
**Diagnosis**: Large table without indexes
**Fix**: Add indexes before data grows

### Issue 3: "Type Error" After Schema Changes
**Symptoms**: TypeScript errors after migration
**Diagnosis**: Stale generated client
**Fix**:
\`\`\`bash
npx prisma generate
\`\`\`

## AI Pair Programming Notes

**When to load this file:**
- Setting up production deployment
- Debugging production database issues
- Optimizing query performance
- Implementing monitoring

**Typical questions:**
- "How should I deploy Prisma in production?"
- "Why are my queries slow?"
- "How do I handle connection pooling?"
- "What metrics should I monitor?"
CONFIGEOF

echo "Created all missing Prisma KB files"
