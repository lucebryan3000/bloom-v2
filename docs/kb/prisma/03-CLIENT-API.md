# Prisma Client API

```yaml
id: prisma_03_client_api
topic: Prisma
file_role: Prisma Client usage, CRUD operations, and query patterns
profile: intermediate
difficulty_level: intermediate
kb_version: v3.1
prerequisites:
  - Fundamentals (01-FUNDAMENTALS.md)
  - Schema Design (02-SCHEMA-DESIGN.md)
related_topics:
  - Relations (04-RELATIONS.md)
  - Transactions (06-TRANSACTIONS.md)
  - TypeScript (../typescript/)
embedding_keywords:
  - prisma client
  - crud operations
  - findMany findUnique
  - create update delete
  - where select include
  - pagination
  - filtering
  - aggregations
  - raw sql
last_reviewed: 2025-11-16
```

## Prisma Client Initialization

### Basic Setup

```typescript
import { PrismaClient } from '@prisma/client';

// Initialize Prisma Client
const prisma = new PrismaClient();

// Use in application
async function main() {
  const users = await prisma.user.findMany();
  console.log(users);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
```

### Client Options

```typescript
const prisma = new PrismaClient({
  // Logging
  log: ['query', 'info', 'warn', 'error'],

  // Error formatting
  errorFormat: 'pretty',

  // Data source overrides
  datasources: {
    db: {
      url: process.env.DATABASE_URL,
    },
  },
});

// Detailed logging
const prisma = new PrismaClient({
  log: [
    {
      emit: 'event',
      level: 'query',
    },
    {
      emit: 'stdout',
      level: 'error',
    },
    {
      emit: 'stdout',
      level: 'info',
    },
    {
      emit: 'stdout',
      level: 'warn',
    },
  ],
});

// Listen to query events
prisma.$on('query', (e) => {
  console.log('Query: ' + e.query);
  console.log('Duration: ' + e.duration + 'ms');
});
```

### Singleton Pattern (Next.js)

```typescript
// lib/prisma.ts
import { PrismaClient } from '@prisma/client';

declare global {
  // eslint-disable-next-line no-var
  var prisma: PrismaClient | undefined;
}

export const prisma = global.prisma || new PrismaClient();

if (process.env.NODE_ENV !== 'production') {
  global.prisma = prisma;
}
```

## CRUD Operations

### Create

```typescript
// Create single record
const user = await prisma.user.create({
  data: {
    email: 'alice@example.com',
    name: 'Alice',
  },
});

// Create with relations
const user = await prisma.user.create({
  data: {
    email: 'bob@example.com',
    name: 'Bob',
    posts: {
      create: [
        { title: 'My first post', published: true },
        { title: 'Draft post', published: false },
      ],
    },
  },
  include: {
    posts: true,
  },
});

// Create many
const users = await prisma.user.createMany({
  data: [
    { email: 'user1@example.com', name: 'User 1' },
    { email: 'user2@example.com', name: 'User 2' },
    { email: 'user3@example.com', name: 'User 3' },
  ],
  skipDuplicates: true, // Skip records if they already exist
});

console.log(`Created ${users.count} users`);
```

### Read (Find)

```typescript
// Find all
const users = await prisma.user.findMany();

// Find first match
const user = await prisma.user.findFirst({
  where: {
    email: 'alice@example.com',
  },
});

// Find unique (by unique field or ID)
const user = await prisma.user.findUnique({
  where: {
    id: 1,
  },
});

const user = await prisma.user.findUnique({
  where: {
    email: 'alice@example.com',
  },
});

// Find or throw error
const user = await prisma.user.findUniqueOrThrow({
  where: {
    id: 1,
  },
});

const user = await prisma.user.findFirstOrThrow({
  where: {
    email: 'alice@example.com',
  },
});
```

### Update

```typescript
// Update single record
const user = await prisma.user.update({
  where: {
    id: 1,
  },
  data: {
    name: 'Alice Updated',
  },
});

// Update many
const result = await prisma.user.updateMany({
  where: {
    email: {
      contains: '@example.com',
    },
  },
  data: {
    verified: true,
  },
});

console.log(`Updated ${result.count} users`);

// Update with relations
const user = await prisma.user.update({
  where: {
    id: 1,
  },
  data: {
    posts: {
      create: { title: 'New post' },
      update: {
        where: { id: 5 },
        data: { published: true },
      },
      delete: { id: 3 },
    },
  },
  include: {
    posts: true,
  },
});
```

### Delete

```typescript
// Delete single record
const user = await prisma.user.delete({
  where: {
    id: 1,
  },
});

// Delete many
const result = await prisma.user.deleteMany({
  where: {
    email: {
      contains: 'test',
    },
  },
});

console.log(`Deleted ${result.count} users`);

// Delete all records
const result = await prisma.user.deleteMany({});
```

### Upsert (Create or Update)

```typescript
// Create if not exists, update if exists
const user = await prisma.user.upsert({
  where: {
    email: 'alice@example.com',
  },
  update: {
    name: 'Alice Updated',
  },
  create: {
    email: 'alice@example.com',
    name: 'Alice',
  },
});
```

## Query Options

### Select Fields

```typescript
// Select specific fields
const user = await prisma.user.findUnique({
  where: {
    id: 1,
  },
  select: {
    id: true,
    email: true,
    name: true,
    // posts excluded
  },
});

// Nested select
const user = await prisma.user.findUnique({
  where: {
    id: 1,
  },
  select: {
    email: true,
    posts: {
      select: {
        title: true,
        published: true,
      },
    },
  },
});
```

### Include Relations

```typescript
// Include related data
const user = await prisma.user.findUnique({
  where: {
    id: 1,
  },
  include: {
    posts: true,
  },
});

// Nested include
const user = await prisma.user.findUnique({
  where: {
    id: 1,
  },
  include: {
    posts: {
      include: {
        comments: true,
      },
    },
  },
});

// Combine include with where
const user = await prisma.user.findUnique({
  where: {
    id: 1,
  },
  include: {
    posts: {
      where: {
        published: true,
      },
    },
  },
});
```

### Where Filters

```typescript
// Equals
const users = await prisma.user.findMany({
  where: {
    email: 'alice@example.com',
  },
});

// Not equals
const users = await prisma.user.findMany({
  where: {
    email: {
      not: 'alice@example.com',
    },
  },
});

// In array
const users = await prisma.user.findMany({
  where: {
    id: {
      in: [1, 2, 3],
    },
  },
});

// Not in array
const users = await prisma.user.findMany({
  where: {
    id: {
      notIn: [1, 2, 3],
    },
  },
});

// Less than / Greater than
const users = await prisma.user.findMany({
  where: {
    age: {
      lt: 30,      // less than
      lte: 30,     // less than or equal
      gt: 18,      // greater than
      gte: 18,     // greater than or equal
    },
  },
});

// String filters
const users = await prisma.user.findMany({
  where: {
    email: {
      contains: '@example.com',
      startsWith: 'alice',
      endsWith: '.com',
    },
    name: {
      mode: 'insensitive', // Case-insensitive search
    },
  },
});

// Null checks
const users = await prisma.user.findMany({
  where: {
    name: null,        // IS NULL
    bio: { not: null }, // IS NOT NULL
  },
});

// Logical operators
const users = await prisma.user.findMany({
  where: {
    AND: [
      { email: { contains: '@example.com' } },
      { verified: true },
    ],
  },
});

const users = await prisma.user.findMany({
  where: {
    OR: [
      { role: 'ADMIN' },
      { role: 'MODERATOR' },
    ],
  },
});

const users = await prisma.user.findMany({
  where: {
    NOT: {
      email: { contains: 'spam' },
    },
  },
});
```

### Order By

```typescript
// Order by single field
const users = await prisma.user.findMany({
  orderBy: {
    createdAt: 'desc',
  },
});

// Order by multiple fields
const users = await prisma.user.findMany({
  orderBy: [
    {
      role: 'asc',
    },
    {
      name: 'asc',
    },
  ],
});

// Order by related field
const users = await prisma.user.findMany({
  orderBy: {
    posts: {
      _count: 'desc', // Order by post count
    },
  },
});
```

## Pagination

### Offset-Based Pagination

```typescript
// Skip and take
const users = await prisma.user.findMany({
  skip: 10,  // Skip first 10
  take: 10,  // Take next 10
  orderBy: {
    createdAt: 'desc',
  },
});

// Page-based helper
function paginate(page: number, pageSize: number) {
  return {
    skip: (page - 1) * pageSize,
    take: pageSize,
  };
}

const page = 3;
const pageSize = 20;
const users = await prisma.user.findMany({
  ...paginate(page, pageSize),
  orderBy: {
    createdAt: 'desc',
  },
});

// Get total count for pagination
const total = await prisma.user.count();
const totalPages = Math.ceil(total / pageSize);
```

### Cursor-Based Pagination

```typescript
// First page
const firstPage = await prisma.user.findMany({
  take: 10,
  orderBy: {
    id: 'asc',
  },
});

// Next page (using last item as cursor)
const lastUser = firstPage[firstPage.length - 1];
const nextPage = await prisma.user.findMany({
  take: 10,
  skip: 1,            // Skip cursor itself
  cursor: {
    id: lastUser.id,
  },
  orderBy: {
    id: 'asc',
  },
});

// Backward pagination
const prevPage = await prisma.user.findMany({
  take: -10,          // Negative value for backward
  skip: 1,
  cursor: {
    id: firstUser.id,
  },
  orderBy: {
    id: 'asc',
  },
});
```

## Aggregations

### Count

```typescript
// Count all
const count = await prisma.user.count();

// Count with filter
const count = await prisma.user.count({
  where: {
    verified: true,
  },
});
```

### Aggregate Functions

```typescript
// Multiple aggregations
const result = await prisma.user.aggregate({
  _count: true,
  _avg: {
    age: true,
  },
  _sum: {
    points: true,
  },
  _min: {
    age: true,
  },
  _max: {
    age: true,
  },
  where: {
    verified: true,
  },
});

console.log(result);
// {
//   _count: 100,
//   _avg: { age: 28.5 },
//   _sum: { points: 50000 },
//   _min: { age: 18 },
//   _max: { age: 65 }
// }
```

### Group By

```typescript
// Group by field
const result = await prisma.user.groupBy({
  by: ['role'],
  _count: {
    role: true,
  },
});

console.log(result);
// [
//   { role: 'USER', _count: { role: 50 } },
//   { role: 'ADMIN', _count: { role: 5 } },
// ]

// Group with aggregations
const result = await prisma.post.groupBy({
  by: ['authorId'],
  _count: {
    id: true,
  },
  _avg: {
    views: true,
  },
  having: {
    views: {
      _avg: {
        gt: 100,
      },
    },
  },
  orderBy: {
    _count: {
      id: 'desc',
    },
  },
});
```

## Relation Queries

### Nested Reads

```typescript
// Include relations
const user = await prisma.user.findUnique({
  where: { id: 1 },
  include: {
    posts: true,
  },
});

// Filter nested relations
const user = await prisma.user.findUnique({
  where: { id: 1 },
  include: {
    posts: {
      where: {
        published: true,
      },
      orderBy: {
        createdAt: 'desc',
      },
      take: 10,
    },
  },
});
```

### Nested Writes

```typescript
// Create with nested relations
const user = await prisma.user.create({
  data: {
    email: 'alice@example.com',
    name: 'Alice',
    posts: {
      create: [
        { title: 'First post', published: true },
        { title: 'Second post', published: false },
      ],
    },
  },
  include: {
    posts: true,
  },
});

// Update with nested relations
const user = await prisma.user.update({
  where: { id: 1 },
  data: {
    posts: {
      // Create new posts
      create: { title: 'New post' },
      // Update existing posts
      update: {
        where: { id: 5 },
        data: { published: true },
      },
      // Delete posts
      delete: { id: 3 },
      // Connect existing posts
      connect: { id: 10 },
      // Disconnect posts
      disconnect: { id: 7 },
    },
  },
});
```

## Raw SQL Queries

### Raw Queries

```typescript
import { Prisma } from '@prisma/client';

// Execute raw query
const users = await prisma.$queryRaw<User[]>`
  SELECT * FROM users WHERE email LIKE ${'%@example.com'}
`;

// Parameterized queries (safe from SQL injection)
const email = 'alice@example.com';
const user = await prisma.$queryRaw<User[]>`
  SELECT * FROM users WHERE email = ${email}
`;

// Unsafe raw query (use with caution!)
const users = await prisma.$queryRawUnsafe(
  'SELECT * FROM users WHERE role = $1',
  'ADMIN'
);
```

### Execute Raw SQL

```typescript
// Execute without returning data
const result = await prisma.$executeRaw`
  UPDATE users SET verified = true WHERE email LIKE ${'%@example.com'}
`;

console.log(`Updated ${result} rows`);

// Unsafe execute
const result = await prisma.$executeRawUnsafe(
  'DELETE FROM posts WHERE created_at < $1',
  new Date('2020-01-01')
);
```

### Type-Safe Raw Queries

```typescript
import { Prisma } from '@prisma/client';

// Define result type
type UserWithPostCount = {
  id: number;
  email: string;
  name: string;
  postCount: bigint;
};

// Execute with type safety
const users = await prisma.$queryRaw<UserWithPostCount[]>`
  SELECT u.id, u.email, u.name, COUNT(p.id) as "postCount"
  FROM users u
  LEFT JOIN posts p ON u.id = p.author_id
  GROUP BY u.id
`;
```

## Batch Operations

### Batch Transactions

```typescript
// Multiple operations in array (executed in sequence)
const [updatedUsers, newPost] = await prisma.$transaction([
  prisma.user.updateMany({
    where: { verified: false },
    data: { verified: true },
  }),
  prisma.post.create({
    data: {
      title: 'New post',
      authorId: 1,
    },
  }),
]);
```

### Interactive Transactions

```typescript
// Interactive transaction with full control
const result = await prisma.$transaction(async (tx) => {
  // Create user
  const user = await tx.user.create({
    data: {
      email: 'alice@example.com',
      name: 'Alice',
    },
  });

  // Create posts for user
  await tx.post.createMany({
    data: [
      { title: 'Post 1', authorId: user.id },
      { title: 'Post 2', authorId: user.id },
    ],
  });

  // Update user stats
  await tx.user.update({
    where: { id: user.id },
    data: { postCount: 2 },
  });

  return user;
});

// Transaction options
const result = await prisma.$transaction(
  async (tx) => {
    // Your operations
  },
  {
    maxWait: 5000,      // Max wait time to acquire transaction (ms)
    timeout: 10000,     // Max transaction execution time (ms)
    isolationLevel: Prisma.TransactionIsolationLevel.Serializable,
  }
);
```

## TypeScript Types

### Inferred Types

```typescript
import { Prisma } from '@prisma/client';

// Get type from model
type User = Prisma.UserGetPayload<{}>;

// Get type with relations
type UserWithPosts = Prisma.UserGetPayload<{
  include: { posts: true };
}>;

// Get type with select
type UserEmail = Prisma.UserGetPayload<{
  select: { email: true };
}>;

// Create input type
type CreateUserInput = Prisma.UserCreateInput;

// Update input type
type UpdateUserInput = Prisma.UserUpdateInput;

// Where input type
type UserWhereInput = Prisma.UserWhereInput;
```

### Validation Types

```typescript
import { Prisma } from '@prisma/client';

// Validator for create input
const createUserInput = Prisma.validator<Prisma.UserCreateInput>()({
  email: 'alice@example.com',
  name: 'Alice',
  posts: {
    create: [
      { title: 'First post' },
    ],
  },
});

// Extract type from validator
type CreateUserInput = typeof createUserInput;
```

## Error Handling

### Prisma Errors

```typescript
import { Prisma } from '@prisma/client';

try {
  const user = await prisma.user.create({
    data: {
      email: 'duplicate@example.com',
    },
  });
} catch (error) {
  if (error instanceof Prisma.PrismaClientKnownRequestError) {
    // Unique constraint violation
    if (error.code === 'P2002') {
      console.log('Email already exists');
    }

    // Record not found
    if (error.code === 'P2025') {
      console.log('Record not found');
    }

    // Foreign key constraint failed
    if (error.code === 'P2003') {
      console.log('Foreign key constraint failed');
    }
  }

  if (error instanceof Prisma.PrismaClientValidationError) {
    console.log('Validation error');
  }

  throw error;
}
```

### Common Error Codes

```typescript
// P2002: Unique constraint violation
// P2003: Foreign key constraint failed
// P2025: Record not found
// P2014: Invalid ID
// P2015: Related record not found
// P2016: Query interpretation error
// P2017: Records for relation not connected
```

## Best Practices

### 1. Connection Management

```typescript
// ✅ GOOD - Singleton pattern
// lib/prisma.ts
import { PrismaClient } from '@prisma/client';

const prisma = global.prisma || new PrismaClient();

if (process.env.NODE_ENV !== 'production') {
  global.prisma = prisma;
}

export default prisma;

// ❌ AVOID - Creating new instances
import { PrismaClient } from '@prisma/client';

function getUser() {
  const prisma = new PrismaClient(); // DON'T DO THIS
  return prisma.user.findMany();
}
```

### 2. Select Only What You Need

```typescript
// ✅ GOOD - Select specific fields
const users = await prisma.user.findMany({
  select: {
    id: true,
    email: true,
    name: true,
  },
});

// ❌ AVOID - Fetching all fields when not needed
const users = await prisma.user.findMany(); // Fetches everything
```

### 3. Use Transactions for Data Integrity

```typescript
// ✅ GOOD - Atomic operations
await prisma.$transaction(async (tx) => {
  const user = await tx.user.create({
    data: { email: 'alice@example.com', name: 'Alice' },
  });

  await tx.profile.create({
    data: { userId: user.id, bio: 'Hello' },
  });
});

// ❌ AVOID - Non-atomic operations
const user = await prisma.user.create({
  data: { email: 'alice@example.com', name: 'Alice' },
});
// If this fails, user is created but profile is not
await prisma.profile.create({
  data: { userId: user.id, bio: 'Hello' },
});
```

### 4. Handle Errors Properly

```typescript
// ✅ GOOD - Specific error handling
import { Prisma } from '@prisma/client';

try {
  const user = await prisma.user.create({ data: { email } });
} catch (error) {
  if (
    error instanceof Prisma.PrismaClientKnownRequestError &&
    error.code === 'P2002'
  ) {
    return { error: 'Email already exists' };
  }
  throw error;
}

// ❌ AVOID - Generic error handling
try {
  const user = await prisma.user.create({ data: { email } });
} catch (error) {
  console.log('Something went wrong'); // Not helpful
}
```

### 5. Use Cursor Pagination for Large Datasets

```typescript
// ✅ GOOD - Cursor pagination for performance
const users = await prisma.user.findMany({
  take: 100,
  cursor: { id: lastSeenId },
  orderBy: { id: 'asc' },
});

// ❌ AVOID - Offset pagination for large datasets
const users = await prisma.user.findMany({
  skip: 100000,  // Slow for large offsets
  take: 100,
});
```

## AI Pair Programming Notes

**When working with Prisma Client:**

1. **Always use singleton pattern**: Prevent connection pool exhaustion
2. **Select only needed fields**: Optimize query performance
3. **Use TypeScript types**: Leverage Prisma's type safety
4. **Handle errors specifically**: Check Prisma error codes
5. **Use transactions for related operations**: Ensure data consistency
6. **Prefer cursor pagination**: Better performance for large datasets
7. **Use `include` for relations**: Avoid N+1 query problems
8. **Disconnect client on app shutdown**: Prevent hanging connections
9. **Use `findUniqueOrThrow`**: When record must exist
10. **Leverage aggregations**: Compute on database level for performance

**Common Prisma Client mistakes to catch:**
- Creating new PrismaClient instances in functions
- Not disconnecting client on shutdown
- Using offset pagination for large datasets
- Not using transactions for multi-step operations
- Fetching all fields when only a few are needed
- Ignoring Prisma error codes
- Not using `select` or `include` appropriately
- Missing null checks on optional relations
- Using raw SQL when Prisma Client methods would work

## Next Steps

1. **04-RELATIONS.md** - Deep dive into Prisma relations
2. **06-TRANSACTIONS.md** - Advanced transaction patterns
3. **07-PERFORMANCE.md** - Query optimization and performance

## Additional Resources

- Prisma Client API Reference: https://www.prisma.io/docs/reference/api-reference/prisma-client-reference
- CRUD Operations: https://www.prisma.io/docs/concepts/components/prisma-client/crud
- Filtering and Sorting: https://www.prisma.io/docs/concepts/components/prisma-client/filtering-and-sorting
- Pagination: https://www.prisma.io/docs/concepts/components/prisma-client/pagination
- Aggregation: https://www.prisma.io/docs/concepts/components/prisma-client/aggregation-grouping-summarizing
