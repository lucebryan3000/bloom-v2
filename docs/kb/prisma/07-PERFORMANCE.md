# Prisma Performance Optimization

```yaml
id: prisma_07_performance
topic: Prisma
file_role: Query optimization, caching, and performance tuning
profile: intermediate_to_advanced
difficulty_level: advanced
kb_version: v3.1
prerequisites:
  - Fundamentals (01-FUNDAMENTALS.md)
  - Client API (03-CLIENT-API.md)
  - Relations (04-RELATIONS.md)
related_topics:
  - Indexes (../postgresql/05-INDEXES.md)
  - Performance (../postgresql/07-PERFORMANCE.md)
  - Transactions (06-TRANSACTIONS.md)
embedding_keywords:
  - prisma performance
  - query optimization
  - N+1 problem
  - connection pooling
  - batching
  - caching
  - monitoring
  - findMany performance
  - select vs include
  - indexes
last_reviewed: 2025-11-16
```

## Performance Optimization Overview

**Key Principles:**
1. **Select only needed fields**: Reduce data transfer
2. **Use relations efficiently**: Avoid N+1 queries
3. **Batch operations**: Reduce round trips
4. **Index strategically**: Speed up queries
5. **Connection pooling**: Reuse connections
6. **Monitor queries**: Identify bottlenecks

## Query Optimization

### Select Only Required Fields

```typescript
// ❌ SLOW - Fetches all fields
const users = await prisma.user.findMany();

// ✅ FAST - Selects specific fields
const users = await prisma.user.findMany({
  select: {
    id: true,
    email: true,
    name: true,
    // Don't fetch large fields like 'bio' if not needed
  },
});

// Example: 90% reduction in data transfer
// Before: 10KB per user × 1000 users = 10MB
// After: 1KB per user × 1000 users = 1MB
```

### Avoid N+1 Query Problems

**N+1 Problem**: Fetching relations in a loop causes N+1 database queries.

```typescript
// ❌ BAD - N+1 queries (1 + N queries for N users)
const users = await prisma.user.findMany();

for (const user of users) {
  const posts = await prisma.post.findMany({
    where: { authorId: user.id },
  });
  console.log(`${user.name} has ${posts.length} posts`);
}
// Result: 1 query for users + 1000 queries for posts = 1001 queries!

// ✅ GOOD - Single query with include
const users = await prisma.user.findMany({
  include: {
    posts: true,
  },
});

for (const user of users) {
  console.log(`${user.name} has ${user.posts.length} posts`);
}
// Result: 1 query for users + 1 query for all posts = 2 queries

// ✅ EVEN BETTER - Use _count for just the count
const users = await prisma.user.findMany({
  include: {
    _count: {
      select: { posts: true },
    },
  },
});

for (const user of users) {
  console.log(`${user.name} has ${user._count.posts} posts`);
}
// Result: 1-2 queries total (depending on database)
```

### Pagination Best Practices

```typescript
// ❌ SLOW - Offset pagination for large datasets
const users = await prisma.user.findMany({
  skip: 100000,  // Database must scan 100k rows
  take: 100,
});

// ✅ FAST - Cursor-based pagination
const users = await prisma.user.findMany({
  take: 100,
  cursor: { id: lastSeenId },
  orderBy: { id: 'asc' },
});

// Performance comparison:
// Offset (skip: 100000): ~500ms
// Cursor (cursor-based): ~5ms (100x faster!)
```

### Filter Early

```typescript
// ❌ SLOW - Fetch everything then filter
const allUsers = await prisma.user.findMany();
const activeUsers = allUsers.filter(u => u.status === 'ACTIVE');

// ✅ FAST - Filter in database
const activeUsers = await prisma.user.findMany({
  where: { status: 'ACTIVE' },
});

// ✅ EVEN BETTER - With index
// CREATE INDEX idx_user_status ON users(status);
```

## Batch Operations

### Batch Reads

```typescript
// ❌ SLOW - Multiple queries
const user1 = await prisma.user.findUnique({ where: { id: 1 } });
const user2 = await prisma.user.findUnique({ where: { id: 2 } });
const user3 = await prisma.user.findUnique({ where: { id: 3 } });

// ✅ FAST - Single query
const users = await prisma.user.findMany({
  where: {
    id: { in: [1, 2, 3] },
  },
});
```

### Batch Writes

```typescript
// ❌ SLOW - Individual inserts
for (const userData of users) {
  await prisma.user.create({
    data: userData,
  });
}
// Result: N database round trips

// ✅ FAST - Batch insert
await prisma.user.createMany({
  data: users,
  skipDuplicates: true,
});
// Result: 1 database round trip

// Performance comparison for 1000 records:
// Individual: ~10 seconds
// Batch: ~100ms (100x faster!)
```

## Connection Pooling

### PgBouncer Configuration

```typescript
// Prisma connection pooling
const prisma = new PrismaClient({
  datasources: {
    db: {
      url: process.env.DATABASE_URL,
    },
  },
});

// Configure connection pool size
// DATABASE_URL="postgresql://user:pass@host:5432/db?connection_limit=10"
```

### Connection Pool Best Practices

```bash
# Connection pool sizing formula
connection_limit = (num_cpu_cores * 2) + effective_spindle_count

# For serverless (AWS Lambda, Vercel, etc.)
# Use connection pooler like PgBouncer or Prisma Accelerate
DATABASE_URL="postgresql://user:pass@pgbouncer:6432/db"
```

### Serverless Considerations

```typescript
// For serverless environments, use connection pooling
import { PrismaClient } from '@prisma/client';

let prisma: PrismaClient;

if (process.env.NODE_ENV === 'production') {
  prisma = new PrismaClient({
    datasources: {
      db: {
        url: process.env.DATABASE_URL_POOLED, // PgBouncer URL
      },
    },
  });
} else {
  prisma = new PrismaClient();
}

export default prisma;
```

## Caching Strategies

### Application-Level Caching

```typescript
import NodeCache from 'node-cache';

const cache = new NodeCache({ stdTTL: 600 }); // 10 minute TTL

async function getCachedUsers() {
  const cacheKey = 'all-users';

  // Try cache first
  const cached = cache.get<User[]>(cacheKey);
  if (cached) {
    return cached;
  }

  // Fetch from database
  const users = await prisma.user.findMany();

  // Store in cache
  cache.set(cacheKey, users);

  return users;
}
```

### Redis Caching

```typescript
import Redis from 'ioredis';

const redis = new Redis(process.env.REDIS_URL);

async function getCachedUser(userId: number) {
  const cacheKey = `user:${userId}`;

  // Try Redis cache
  const cached = await redis.get(cacheKey);
  if (cached) {
    return JSON.parse(cached);
  }

  // Fetch from database
  const user = await prisma.user.findUnique({
    where: { id: userId },
  });

  if (user) {
    // Cache for 1 hour
    await redis.setex(cacheKey, 3600, JSON.stringify(user));
  }

  return user;
}
```

### Cache Invalidation

```typescript
async function updateUserWithCacheInvalidation(userId: number, data: any) {
  // Update database
  const user = await prisma.user.update({
    where: { id: userId },
    data,
  });

  // Invalidate cache
  await redis.del(`user:${userId}`);
  await redis.del('all-users');

  return user;
}
```

## Index Optimization

### Identifying Missing Indexes

```typescript
// Enable query logging to identify slow queries
const prisma = new PrismaClient({
  log: [
    {
      emit: 'event',
      level: 'query',
    },
  ],
});

prisma.$on('query', (e) => {
  console.log('Query: ' + e.query);
  console.log('Duration: ' + e.duration + 'ms');

  if (e.duration > 1000) {
    console.warn('SLOW QUERY DETECTED!');
  }
});
```

### Common Index Patterns

```prisma
model User {
  id        Int      @id @default(autoincrement())
  email     String   @unique          // Automatically indexed
  username  String
  status    String
  createdAt DateTime @default(now())

  // Add indexes for frequently queried fields
  @@index([username])           // Single field
  @@index([status])             // Filter queries
  @@index([createdAt(sort: Desc)])  // Sorting
}

model Post {
  id        Int      @id @default(autoincrement())
  authorId  Int
  published Boolean
  createdAt DateTime @default(now())

  // Composite index for combined queries
  @@index([authorId, published])  // "Get published posts by author"
  @@index([createdAt(sort: Desc)])  // "Get recent posts"
}
```

## Monitoring and Profiling

### Query Analysis

```typescript
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient({
  log: ['query', 'info', 'warn', 'error'],
});

// Monitor query performance
prisma.$use(async (params, next) => {
  const before = Date.now();
  const result = await next(params);
  const after = Date.now();

  console.log(`Query ${params.model}.${params.action} took ${after - before}ms`);

  return result;
});
```

### Prisma Metrics (PostgreSQL)

```sql
-- Check slow queries
SELECT
  query,
  calls,
  total_exec_time,
  mean_exec_time,
  max_exec_time
FROM pg_stat_statements
WHERE query LIKE '%User%'
ORDER BY mean_exec_time DESC
LIMIT 10;

-- Check table sizes
SELECT
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Check index usage
SELECT
  schemaname,
  tablename,
  indexname,
  idx_scan,
  idx_tup_read,
  idx_tup_fetch
FROM pg_stat_user_indexes
ORDER BY idx_scan ASC;
```

## Real-World Optimization Examples

### Example 1: Dashboard Query Optimization

```typescript
// ❌ SLOW - Multiple separate queries
async function getDashboard(userId: number) {
  const user = await prisma.user.findUnique({ where: { id: userId } });
  const posts = await prisma.post.findMany({ where: { authorId: userId } });
  const comments = await prisma.comment.findMany({ where: { authorId: userId } });
  const followers = await prisma.follow.findMany({ where: { followingId: userId } });

  return { user, posts, comments, followers };
}
// Result: 4 separate queries, ~400ms

// ✅ FAST - Single query with relations
async function getDashboard(userId: number) {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    include: {
      posts: {
        take: 10,
        orderBy: { createdAt: 'desc' },
      },
      comments: {
        take: 10,
        orderBy: { createdAt: 'desc' },
      },
      followers: {
        take: 10,
        select: {
          follower: {
            select: {
              id: true,
              name: true,
              avatar: true,
            },
          },
        },
      },
    },
  });

  return user;
}
// Result: 1-2 queries, ~50ms (8x faster!)
```

### Example 2: Search Optimization

```typescript
// ❌ SLOW - Case-insensitive search without index
const users = await prisma.user.findMany({
  where: {
    email: {
      contains: searchTerm,
      mode: 'insensitive',
    },
  },
});
// Result: Full table scan, ~2000ms for 100k users

// ✅ FAST - Use database-specific features
// Add GIN index: CREATE INDEX idx_user_email_gin ON users USING GIN (email gin_trgm_ops);
const users = await prisma.$queryRaw`
  SELECT * FROM users
  WHERE email ILIKE ${'%' + searchTerm + '%'}
  LIMIT 100
`;
// Result: Index scan, ~20ms (100x faster!)

// ✅ EVEN BETTER - Full-text search with index
// PostgreSQL with ts_vector index
const users = await prisma.$queryRaw`
  SELECT * FROM users
  WHERE search_vector @@ to_tsquery($1)
  LIMIT 100
`;
// Result: ~5ms (400x faster!)
```

### Example 3: Reporting Query Optimization

```typescript
// ❌ SLOW - Fetch all data then aggregate in application
const allOrders = await prisma.order.findMany({
  where: { createdAt: { gte: startDate } },
});

const totalRevenue = allOrders.reduce((sum, order) => sum + order.total, 0);
const avgOrderValue = totalRevenue / allOrders.length;
// Result: Fetches 100MB of data, ~5000ms

// ✅ FAST - Aggregate in database
const stats = await prisma.order.aggregate({
  where: { createdAt: { gte: startDate } },
  _sum: { total: true },
  _avg: { total: true },
  _count: true,
});

const totalRevenue = stats._sum.total;
const avgOrderValue = stats._avg.total;
// Result: Single query, ~50ms (100x faster!)
```

## Best Practices Checklist

### Query Optimization

```typescript
// ✅ Select specific fields
await prisma.user.findMany({
  select: { id: true, email: true, name: true },
});

// ✅ Use include for relations (avoid N+1)
await prisma.user.findMany({
  include: { posts: true },
});

// ✅ Use _count for counts
await prisma.user.findMany({
  include: {
    _count: { select: { posts: true } },
  },
});

// ✅ Use cursor pagination for large datasets
await prisma.user.findMany({
  take: 100,
  cursor: { id: lastId },
  orderBy: { id: 'asc' },
});

// ✅ Batch operations
await prisma.user.createMany({ data: users });

// ✅ Use transactions for atomic operations
await prisma.$transaction([
  prisma.user.create({ data: userData }),
  prisma.profile.create({ data: profileData }),
]);
```

### Index Strategy

```prisma
model Post {
  id          Int      @id @default(autoincrement())
  authorId    Int
  categoryId  Int
  published   Boolean  @default(false)
  createdAt   DateTime @default(now())

  // Index frequently filtered fields
  @@index([published])
  @@index([categoryId])

  // Composite index for common query pattern
  @@index([authorId, published, createdAt(sort: Desc)])
}
```

### Connection Management

```typescript
// ✅ Use singleton pattern
// lib/prisma.ts
import { PrismaClient } from '@prisma/client';

const prisma = global.prisma || new PrismaClient();

if (process.env.NODE_ENV !== 'production') {
  global.prisma = prisma;
}

export default prisma;

// ✅ Configure connection pool
// DATABASE_URL="postgresql://user:pass@host:5432/db?connection_limit=10"

// ✅ Use PgBouncer for serverless
// DATABASE_URL="postgresql://user:pass@pgbouncer:6432/db"
```

## AI Pair Programming Notes

**When optimizing Prisma performance:**

1. **Profile before optimizing**: Use query logging to identify slow queries
2. **Select only needed fields**: Reduce data transfer significantly
3. **Avoid N+1 queries**: Use include/select with relations
4. **Use cursor pagination**: For large datasets (>1000 records)
5. **Batch operations**: createMany, updateMany, deleteMany
6. **Add strategic indexes**: Based on where clauses and orderBy
7. **Cache appropriately**: Application-level or Redis for hot data
8. **Monitor query times**: Log queries >1000ms
9. **Use connection pooling**: Especially for serverless
10. **Aggregate in database**: Don't fetch all data to aggregate in app

**Common performance mistakes to catch:**
- Fetching all fields when only a few are needed
- N+1 query problems with relations
- Using offset pagination for large datasets
- Missing indexes on frequently queried fields
- Creating new PrismaClient instances
- Not using createMany for batch inserts
- Aggregating large datasets in application code
- No connection pooling in serverless environments
- Not monitoring query performance
- Fetching entire collections without limits

## Next Steps

1. **08-TESTING.md** - Testing Prisma applications
2. **09-TYPESCRIPT-PATTERNS.md** - TypeScript best practices
3. **PostgreSQL Performance** - ../postgresql/07-PERFORMANCE.md

## Additional Resources

- Prisma Performance Best Practices: https://www.prisma.io/docs/guides/performance-and-optimization
- Query Optimization: https://www.prisma.io/docs/guides/performance-and-optimization/query-optimization-performance
- Connection Management: https://www.prisma.io/docs/guides/performance-and-optimization/connection-management
- Prisma Accelerate: https://www.prisma.io/docs/accelerate
