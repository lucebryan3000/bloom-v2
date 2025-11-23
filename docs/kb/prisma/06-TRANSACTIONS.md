# Prisma Transactions

```yaml
id: prisma_06_transactions
topic: Prisma
file_role: Transaction management, ACID compliance, and concurrency control
profile: intermediate_to_advanced
difficulty_level: advanced
kb_version: v3.1
prerequisites:
  - Fundamentals (01-FUNDAMENTALS.md)
  - Client API (03-CLIENT-API.md)
  - Relations (04-RELATIONS.md)
related_topics:
  - Performance (07-PERFORMANCE.md)
  - PostgreSQL Transactions (../postgresql/06-TRANSACTIONS.md)
embedding_keywords:
  - prisma transactions
  - $transaction
  - interactive transactions
  - sequential transactions
  - isolation levels
  - ACID
  - concurrency
  - rollback
  - atomic operations
last_reviewed: 2025-11-16
```

## Transaction Overview

Transactions ensure ACID properties (Atomicity, Consistency, Isolation, Durability) for database operations.

**Key Concepts:**
- **Atomic**: All operations succeed or all fail
- **Consistent**: Database moves from one valid state to another
- **Isolated**: Concurrent transactions don't interfere
- **Durable**: Committed changes persist

## Transaction Types

Prisma supports two transaction types:

| Type | Use Case | Performance | Flexibility |
|------|----------|-------------|-------------|
| **Sequential** | Simple operations, known steps | Fast | Limited |
| **Interactive** | Complex logic, conditional operations | Slower | Full control |

## Sequential Transactions

Execute multiple operations in a single transaction using an array.

### Basic Sequential Transaction

```typescript
const [user, post] = await prisma.$transaction([
  prisma.user.create({
    data: {
      email: 'alice@example.com',
      name: 'Alice',
    },
  }),
  prisma.post.create({
    data: {
      title: 'My first post',
      authorId: 1,
    },
  }),
]);
```

**Characteristics:**
- Operations execute in order
- Fast and efficient
- All or nothing - rolls back if any operation fails
- Cannot use results of previous operations

### Common Use Cases

```typescript
// Transfer money between accounts
await prisma.$transaction([
  prisma.account.update({
    where: { id: fromAccountId },
    data: { balance: { decrement: amount } },
  }),
  prisma.account.update({
    where: { id: toAccountId },
    data: { balance: { increment: amount } },
  }),
]);

// Batch updates
await prisma.$transaction([
  prisma.user.updateMany({
    where: { verified: false },
    data: { verified: true },
  }),
  prisma.log.create({
    data: {
      action: 'VERIFY_USERS',
      count: verifiedCount,
    },
  }),
]);

// Delete with cascade
await prisma.$transaction([
  prisma.comment.deleteMany({
    where: { postId: 1 },
  }),
  prisma.post.delete({
    where: { id: 1 },
  }),
]);
```

### Error Handling

```typescript
try {
  const result = await prisma.$transaction([
    prisma.user.create({ data: { email: 'test@example.com' } }),
    prisma.profile.create({ data: { userId: 1, bio: 'Test' } }),
  ]);
} catch (error) {
  // Transaction rolled back
  console.error('Transaction failed:', error);
}
```

## Interactive Transactions

Execute complex logic with full control over transaction flow.

### Basic Interactive Transaction

```typescript
const user = await prisma.$transaction(async (tx) => {
  // Create user
  const newUser = await tx.user.create({
    data: {
      email: 'alice@example.com',
      name: 'Alice',
    },
  });

  // Create profile using new user's ID
  await tx.profile.create({
    data: {
      userId: newUser.id,
      bio: 'Hello!',
    },
  });

  // Create posts
  await tx.post.createMany({
    data: [
      { title: 'Post 1', authorId: newUser.id },
      { title: 'Post 2', authorId: newUser.id },
    ],
  });

  return newUser;
});
```

### Conditional Logic

```typescript
const result = await prisma.$transaction(async (tx) => {
  const user = await tx.user.findUnique({
    where: { id: 1 },
    include: { _count: { select: { posts: true } } },
  });

  if (!user) {
    throw new Error('User not found');
  }

  // Conditional update based on post count
  if (user._count.posts > 100) {
    await tx.user.update({
      where: { id: 1 },
      data: { role: 'POWER_USER' },
    });
  }

  return user;
});
```

### Complex Business Logic

```typescript
async function processOrder(orderId: number) {
  return await prisma.$transaction(async (tx) => {
    // Get order with items
    const order = await tx.order.findUniqueOrThrow({
      where: { id: orderId },
      include: { items: { include: { product: true } } },
    });

    // Check inventory for all items
    for (const item of order.items) {
      if (item.product.stock < item.quantity) {
        throw new Error(`Insufficient stock for ${item.product.name}`);
      }
    }

    // Reduce inventory
    for (const item of order.items) {
      await tx.product.update({
        where: { id: item.productId },
        data: { stock: { decrement: item.quantity } },
      });
    }

    // Update order status
    await tx.order.update({
      where: { id: orderId },
      data: { status: 'PROCESSING' },
    });

    // Create audit log
    await tx.orderLog.create({
      data: {
        orderId,
        action: 'PROCESSED',
        timestamp: new Date(),
      },
    });

    return order;
  });
}
```

## Transaction Options

### Timeout Configuration

```typescript
const result = await prisma.$transaction(
  async (tx) => {
    // Your operations
  },
  {
    maxWait: 5000,  // Max ms to wait to start transaction
    timeout: 10000, // Max ms for transaction to complete
  }
);
```

### Isolation Levels

```typescript
import { Prisma } from '@prisma/client';

const result = await prisma.$transaction(
  async (tx) => {
    // Your operations
  },
  {
    isolationLevel: Prisma.TransactionIsolationLevel.Serializable,
  }
);
```

**Available Isolation Levels:**

```typescript
// Read Uncommitted (lowest isolation)
isolationLevel: Prisma.TransactionIsolationLevel.ReadUncommitted

// Read Committed (default for most databases)
isolationLevel: Prisma.TransactionIsolationLevel.ReadCommitted

// Repeatable Read (PostgreSQL default)
isolationLevel: Prisma.TransactionIsolationLevel.RepeatableRead

// Serializable (highest isolation)
isolationLevel: Prisma.TransactionIsolationLevel.Serializable
```

### Isolation Level Comparison

| Level | Dirty Reads | Non-Repeatable Reads | Phantom Reads | Performance |
|-------|-------------|----------------------|---------------|-------------|
| **Read Uncommitted** | ✗ | ✗ | ✗ | Best |
| **Read Committed** | ✓ | ✗ | ✗ | Good |
| **Repeatable Read** | ✓ | ✓ | ✗ | Fair |
| **Serializable** | ✓ | ✓ | ✓ | Worst |

## Nested Transactions

Interactive transactions can call functions that use the transaction client.

```typescript
async function createUserWithProfile(
  tx: Prisma.TransactionClient,
  email: string,
  name: string
) {
  const user = await tx.user.create({
    data: { email, name },
  });

  await tx.profile.create({
    data: { userId: user.id, bio: 'New user' },
  });

  return user;
}

async function bulkCreateUsers(users: Array<{ email: string; name: string }>) {
  return await prisma.$transaction(async (tx) => {
    const created = [];

    for (const userData of users) {
      const user = await createUserWithProfile(
        tx,
        userData.email,
        userData.name
      );
      created.push(user);
    }

    return created;
  });
}
```

## Error Handling and Rollback

### Automatic Rollback

```typescript
try {
  await prisma.$transaction(async (tx) => {
    await tx.user.create({
      data: { email: 'test@example.com', name: 'Test' },
    });

    // This throws an error
    await tx.user.create({
      data: { email: 'duplicate@example.com', name: 'Duplicate' },
    });

    // Transaction automatically rolls back
  });
} catch (error) {
  console.error('Transaction failed and rolled back:', error);
}
```

### Manual Rollback

```typescript
await prisma.$transaction(async (tx) => {
  const user = await tx.user.create({
    data: { email: 'test@example.com', name: 'Test' },
  });

  const balance = await checkBalance(user.id);

  if (balance < 100) {
    // Throw error to rollback
    throw new Error('Insufficient balance');
  }

  await tx.purchase.create({
    data: { userId: user.id, amount: 100 },
  });
});
```

### Partial Rollback Workaround

```typescript
// Prisma doesn't support savepoints, use try/catch for partial handling
await prisma.$transaction(async (tx) => {
  // Critical operation (will rollback if fails)
  const user = await tx.user.create({
    data: { email: 'test@example.com', name: 'Test' },
  });

  // Optional operation (continue if fails)
  try {
    await tx.notification.create({
      data: { userId: user.id, message: 'Welcome!' },
    });
  } catch (error) {
    console.log('Notification failed, continuing...');
    // Transaction continues
  }

  return user;
});
```

## Read-Write Splitting

Use read replicas for read-only operations outside transactions.

```typescript
// Read from replica (if configured)
const users = await prisma.user.findMany();

// Write to primary (always in transaction)
await prisma.$transaction([
  prisma.user.create({
    data: { email: 'test@example.com', name: 'Test' },
  }),
]);
```

## Optimistic Concurrency Control

Use version fields to handle concurrent updates.

```prisma
model Post {
  id      Int    @id @default(autoincrement())
  title   String
  content String
  version Int    @default(0)
}
```

```typescript
async function updatePostOptimistic(postId: number, newTitle: string) {
  const currentPost = await prisma.post.findUnique({
    where: { id: postId },
  });

  if (!currentPost) {
    throw new Error('Post not found');
  }

  try {
    const updated = await prisma.post.update({
      where: {
        id: postId,
        version: currentPost.version, // Ensure version hasn't changed
      },
      data: {
        title: newTitle,
        version: { increment: 1 },
      },
    });

    return updated;
  } catch (error) {
    throw new Error('Concurrent modification detected');
  }
}
```

## Idempotency Patterns

Ensure operations can be safely retried.

```typescript
async function createPayment(orderId: string, amount: number) {
  return await prisma.$transaction(async (tx) => {
    // Check if payment already exists (idempotency)
    const existing = await tx.payment.findUnique({
      where: { orderId },
    });

    if (existing) {
      return existing; // Already processed
    }

    // Create payment
    const payment = await tx.payment.create({
      data: {
        orderId,
        amount,
        status: 'PENDING',
      },
    });

    // Process payment...

    return payment;
  });
}
```

## Long-Running Transactions

Avoid long-running transactions to prevent lock contention.

```typescript
// ❌ AVOID - Long-running transaction
await prisma.$transaction(async (tx) => {
  const users = await tx.user.findMany();

  for (const user of users) {
    // External API call (slow!)
    await sendEmail(user.email);

    await tx.user.update({
      where: { id: user.id },
      data: { emailSent: true },
    });
  }
});

// ✅ GOOD - Keep transaction short
const users = await prisma.user.findMany();

const emailResults = [];
for (const user of users) {
  try {
    await sendEmail(user.email);
    emailResults.push({ userId: user.id, success: true });
  } catch (error) {
    emailResults.push({ userId: user.id, success: false });
  }
}

// Update in batches with short transactions
await prisma.user.updateMany({
  where: {
    id: { in: emailResults.filter(r => r.success).map(r => r.userId) },
  },
  data: { emailSent: true },
});
```

## Best Practices

### 1. Choose the Right Transaction Type

```typescript
// ✅ Use sequential for simple, independent operations
await prisma.$transaction([
  prisma.user.create({ data: { email: 'a@example.com' } }),
  prisma.user.create({ data: { email: 'b@example.com' } }),
]);

// ✅ Use interactive for dependent operations
await prisma.$transaction(async (tx) => {
  const user = await tx.user.create({ data: { email: 'a@example.com' } });
  await tx.profile.create({ data: { userId: user.id, bio: 'Hi' } });
});
```

### 2. Keep Transactions Short

```typescript
// ✅ GOOD - Short transaction
await prisma.$transaction(async (tx) => {
  await tx.user.update({ where: { id: 1 }, data: { name: 'Alice' } });
  await tx.log.create({ data: { action: 'UPDATE_USER' } });
});

// ❌ AVOID - Long transaction with external calls
await prisma.$transaction(async (tx) => {
  await tx.user.update({ where: { id: 1 }, data: { name: 'Alice' } });
  await fetch('https://api.example.com/notify'); // External call!
  await tx.log.create({ data: { action: 'UPDATE_USER' } });
});
```

### 3. Handle Errors Properly

```typescript
// ✅ GOOD - Explicit error handling
try {
  const result = await prisma.$transaction(async (tx) => {
    // Operations
  });
} catch (error) {
  if (error instanceof Prisma.PrismaClientKnownRequestError) {
    if (error.code === 'P2002') {
      // Handle unique constraint violation
    }
  }
  throw error;
}
```

### 4. Set Appropriate Timeouts

```typescript
// ✅ GOOD - Configure timeouts based on operation
await prisma.$transaction(
  async (tx) => {
    // Complex operations
  },
  {
    maxWait: 5000,  // 5 seconds to acquire lock
    timeout: 10000, // 10 seconds to complete
  }
);
```

### 5. Use Isolation Levels Wisely

```typescript
// ✅ Use Serializable for critical financial transactions
await prisma.$transaction(
  async (tx) => {
    // Transfer money
  },
  {
    isolationLevel: Prisma.TransactionIsolationLevel.Serializable,
  }
);

// ✅ Use Read Committed for typical operations (default)
await prisma.$transaction(async (tx) => {
  // Normal operations
});
```

## AI Pair Programming Notes

**When working with Prisma transactions:**

1. **Choose transaction type carefully**: Sequential for simple operations, interactive for complex logic
2. **Keep transactions short**: Minimize lock duration
3. **Handle errors explicitly**: Transaction rolls back on any error
4. **Set appropriate timeouts**: Prevent hanging transactions
5. **Use correct isolation level**: Balance consistency vs performance
6. **Avoid external calls**: Don't make API requests inside transactions
7. **Use optimistic locking**: For concurrent updates
8. **Implement idempotency**: Operations should be safely retryable
9. **Batch when possible**: Group related operations
10. **Monitor transaction duration**: Long transactions indicate issues

**Common transaction mistakes to catch:**
- Making external API calls inside transactions
- Using sequential transactions when operations depend on each other
- Not handling transaction timeouts
- Missing error handling for transaction failures
- Using wrong isolation level for use case
- Creating unnecessarily long transactions
- Not using optimistic locking for concurrent updates
- Forgetting to set timeouts for long operations
- Not implementing idempotency for critical operations
- Mixing read-only and write operations inefficiently

## Next Steps

1. **07-PERFORMANCE.md** - Optimizing Prisma query performance
2. **08-TESTING.md** - Testing patterns for Prisma applications
3. **PostgreSQL Transactions** - ../postgresql/06-TRANSACTIONS.md

## Additional Resources

- Prisma Transactions: https://www.prisma.io/docs/concepts/components/prisma-client/transactions
- Transaction Isolation Levels: https://www.postgresql.org/docs/current/transaction-iso.html
- ACID Properties: https://en.wikipedia.org/wiki/ACID
- Optimistic Concurrency Control: https://en.wikipedia.org/wiki/Optimistic_concurrency_control
