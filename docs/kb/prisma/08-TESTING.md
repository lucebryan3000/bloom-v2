# Prisma Testing Patterns

```yaml
id: prisma_08_testing
topic: Prisma
file_role: Testing strategies, test databases, mocking, and best practices
profile: intermediate
difficulty_level: intermediate
kb_version: v3.1
prerequisites:
  - Fundamentals (01-FUNDAMENTALS.md)
  - Client API (03-CLIENT-API.md)
  - Transactions (06-TRANSACTIONS.md)
related_topics:
  - Testing (../testing/)
  - TypeScript (../typescript/)
embedding_keywords:
  - prisma testing
  - test database
  - jest prisma
  - vitest prisma
  - mocking prisma
  - test factories
  - integration testing
  - unit testing
  - test isolation
last_reviewed: 2025-11-16
```

## Testing Strategy Overview

**Test Types:**
1. **Unit Tests**: Test business logic without database
2. **Integration Tests**: Test with real database
3. **E2E Tests**: Test entire application flow

## Test Database Setup

### Separate Test Database

```typescript
// tests/setup.ts
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient({
  datasources: {
    db: {
      url: process.env.DATABASE_URL_TEST,
    },
  },
});

// Clean database before each test
export async function resetDatabase() {
  await prisma.$transaction([
    prisma.post.deleteMany(),
    prisma.user.deleteMany(),
  ]);
}

// Close connection after tests
export async function disconnect() {
  await prisma.$disconnect();
}

export { prisma };
```

### Jest Configuration

```javascript
// jest.config.js
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  setupFilesAfterEnv: ['<rootDir>/tests/setup.ts'],
  testMatch: ['**/*.test.ts'],
  collectCoverageFrom: ['src/**/*.ts'],
};
```

```typescript
// tests/setup.ts (Jest)
import { prisma } from './test-db';

beforeEach(async () => {
  await prisma.$transaction([
    prisma.comment.deleteMany(),
    prisma.post.deleteMany(),
    prisma.user.deleteMany(),
  ]);
});

afterAll(async () => {
  await prisma.$disconnect();
});
```

## Unit Testing (Mocked Prisma)

### Mocking Prisma Client

```typescript
// tests/mocks/prisma.ts
import { PrismaClient } from '@prisma/client';
import { mockDeep, mockReset, DeepMockProxy } from 'jest-mock-extended';

export const prismaMock = mockDeep<PrismaClient>();

beforeEach(() => {
  mockReset(prismaMock);
});
```

### Unit Test Example

```typescript
// src/services/user.service.ts
import { PrismaClient } from '@prisma/client';

export class UserService {
  constructor(private prisma: PrismaClient) {}

  async getUserWithPosts(userId: number) {
    return this.prisma.user.findUnique({
      where: { id: userId },
      include: { posts: true },
    });
  }

  async createUser(email: string, name: string) {
    return this.prisma.user.create({
      data: { email, name },
    });
  }
}

// tests/services/user.service.test.ts
import { UserService } from '../../src/services/user.service';
import { prismaMock } from '../mocks/prisma';

describe('UserService', () => {
  let userService: UserService;

  beforeEach(() => {
    userService = new UserService(prismaMock as any);
  });

  describe('getUserWithPosts', () => {
    it('should return user with posts', async () => {
      const mockUser = {
        id: 1,
        email: 'test@example.com',
        name: 'Test User',
        posts: [
          { id: 1, title: 'Post 1', authorId: 1 },
          { id: 2, title: 'Post 2', authorId: 1 },
        ],
      };

      prismaMock.user.findUnique.mockResolvedValue(mockUser as any);

      const result = await userService.getUserWithPosts(1);

      expect(result).toEqual(mockUser);
      expect(prismaMock.user.findUnique).toHaveBeenCalledWith({
        where: { id: 1 },
        include: { posts: true },
      });
    });
  });

  describe('createUser', () => {
    it('should create and return new user', async () => {
      const mockUser = {
        id: 1,
        email: 'new@example.com',
        name: 'New User',
      };

      prismaMock.user.create.mockResolvedValue(mockUser as any);

      const result = await userService.createUser('new@example.com', 'New User');

      expect(result).toEqual(mockUser);
      expect(prismaMock.user.create).toHaveBeenCalledWith({
        data: { email: 'new@example.com', name: 'New User' },
      });
    });
  });
});
```

## Integration Testing (Real Database)

### Test Factory Pattern

```typescript
// tests/factories/user.factory.ts
import { PrismaClient } from '@prisma/client';

let userCount = 0;

export async function createUser(
  prisma: PrismaClient,
  data?: Partial<{ email: string; name: string }>
) {
  userCount++;

  return prisma.user.create({
    data: {
      email: data?.email ?? `user${userCount}@example.com`,
      name: data?.name ?? `User ${userCount}`,
    },
  });
}

export async function createUserWithPosts(
  prisma: PrismaClient,
  postCount: number = 3
) {
  const user = await createUser(prisma);

  const posts = await prisma.post.createMany({
    data: Array.from({ length: postCount }).map((_, i) => ({
      title: `Post ${i + 1}`,
      authorId: user.id,
    })),
  });

  return { user, posts };
}
```

### Integration Test Example

```typescript
// tests/integration/user.test.ts
import { prisma } from '../test-db';
import { createUser, createUserWithPosts } from '../factories/user.factory';

describe('User Integration Tests', () => {
  beforeEach(async () => {
    await prisma.post.deleteMany();
    await prisma.user.deleteMany();
  });

  afterAll(async () => {
    await prisma.$disconnect();
  });

  it('should create user', async () => {
    const user = await createUser(prisma, {
      email: 'test@example.com',
      name: 'Test User',
    });

    expect(user).toMatchObject({
      email: 'test@example.com',
      name: 'Test User',
    });

    const dbUser = await prisma.user.findUnique({
      where: { id: user.id },
    });

    expect(dbUser).toEqual(user);
  });

  it('should find user with posts', async () => {
    const { user } = await createUserWithPosts(prisma, 3);

    const result = await prisma.user.findUnique({
      where: { id: user.id },
      include: { posts: true },
    });

    expect(result?.posts).toHaveLength(3);
  });

  it('should handle transactions correctly', async () => {
    const user1 = await createUser(prisma);
    const user2 = await createUser(prisma);

    await expect(
      prisma.$transaction([
        prisma.user.update({
          where: { id: user1.id },
          data: { name: 'Updated' },
        }),
        prisma.user.update({
          where: { id: 999 }, // Non-existent user
          data: { name: 'Updated' },
        }),
      ])
    ).rejects.toThrow();

    // Verify transaction rolled back
    const dbUser1 = await prisma.user.findUnique({
      where: { id: user1.id },
    });

    expect(dbUser1?.name).not.toBe('Updated');
  });
});
```

## Vitest Configuration

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    setupFiles: ['./tests/setup.ts'],
    include: ['**/*.test.ts'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
    },
  },
});
```

```typescript
// tests/setup.ts (Vitest)
import { beforeEach, afterAll } from 'vitest';
import { prisma } from './test-db';

beforeEach(async () => {
  await prisma.$transaction([
    prisma.post.deleteMany(),
    prisma.user.deleteMany(),
  ]);
});

afterAll(async () => {
  await prisma.$disconnect();
});
```

## Test Isolation Strategies

### Strategy 1: Cleanup Between Tests

```typescript
beforeEach(async () => {
  await prisma.$transaction([
    prisma.comment.deleteMany(),
    prisma.post.deleteMany(),
    prisma.user.deleteMany(),
  ]);
});
```

### Strategy 2: Transactions with Rollback

```typescript
// Note: Not officially supported by Prisma, use cleanup instead
```

### Strategy 3: Separate Databases per Test Suite

```typescript
// DATABASE_URL_TEST=postgresql://user:pass@localhost:5432/test_db_1
// DATABASE_URL_TEST_2=postgresql://user:pass@localhost:5432/test_db_2
```

## Testing Best Practices

### 1. Use Factories for Test Data

```typescript
// ✅ GOOD - Factory pattern
const user = await createUser(prisma, { email: 'test@example.com' });
const { user, posts } = await createUserWithPosts(prisma, 5);

// ❌ AVOID - Inline creation
const user = await prisma.user.create({
  data: {
    email: 'test@example.com',
    name: 'Test',
    // ... lots of fields
  },
});
```

### 2. Test Edge Cases

```typescript
it('should handle duplicate email', async () => {
  await createUser(prisma, { email: 'test@example.com' });

  await expect(
    createUser(prisma, { email: 'test@example.com' })
  ).rejects.toThrow();
});

it('should handle not found', async () => {
  const user = await prisma.user.findUnique({
    where: { id: 999 },
  });

  expect(user).toBeNull();
});
```

### 3. Test Transactions

```typescript
it('should rollback on error', async () => {
  const user = await createUser(prisma);

  await expect(
    prisma.$transaction(async (tx) => {
      await tx.user.update({
        where: { id: user.id },
        data: { name: 'Updated' },
      });

      throw new Error('Intentional error');
    })
  ).rejects.toThrow();

  const dbUser = await prisma.user.findUnique({
    where: { id: user.id },
  });

  expect(dbUser?.name).not.toBe('Updated');
});
```

### 4. Clean Up Resources

```typescript
afterAll(async () => {
  await prisma.$disconnect();
});

afterEach(async () => {
  await prisma.$transaction([
    prisma.post.deleteMany(),
    prisma.user.deleteMany(),
  ]);
});
```

## AI Pair Programming Notes

**When testing Prisma applications:**

1. **Use separate test database**: Never test against production
2. **Reset between tests**: Ensure test isolation
3. **Use factories**: Create consistent test data
4. **Test transactions**: Verify rollback behavior
5. **Mock for unit tests**: Use jest-mock-extended
6. **Integration tests for critical paths**: Use real database
7. **Clean up resources**: Disconnect Prisma Client
8. **Test edge cases**: Duplicates, not found, constraints
9. **Use TypeScript**: Leverage type safety in tests
10. **Organize by test type**: Unit, integration, E2E

**Common testing mistakes to catch:**
- Testing against production database
- Not cleaning up between tests
- Inline test data creation (use factories)
- Not testing error cases
- Not testing transactions
- Not disconnecting Prisma Client
- Mocking when integration test needed
- Integration test when unit test sufficient
- Not testing concurrent operations
- Missing edge case tests

## Next Steps

1. **09-TYPESCRIPT-PATTERNS.md** - TypeScript patterns with Prisma
2. **10-ADVANCED-PATTERNS.md** - Advanced Prisma patterns
3. **Testing Documentation** - ../testing/

## Additional Resources

- Prisma Testing Guide: https://www.prisma.io/docs/guides/testing
- Jest Mock Extended: https://github.com/marchaos/jest-mock-extended
- Vitest: https://vitest.dev/
- Testing Best Practices: https://testingjavascript.com/
