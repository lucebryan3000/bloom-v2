# Prisma TypeScript Patterns

```yaml
id: prisma_09_typescript_patterns
topic: Prisma
file_role: TypeScript type safety, type inference, and advanced patterns
profile: advanced
difficulty_level: advanced
kb_version: v3.1
prerequisites:
  - Fundamentals (01-FUNDAMENTALS.md)
  - Client API (03-CLIENT-API.md)
  - Relations (04-RELATIONS.md)
related_topics:
  - TypeScript (../typescript/)
  - Testing (08-TESTING.md)
  - Advanced Patterns (10-ADVANCED-PATTERNS.md)
embedding_keywords:
  - prisma typescript
  - type inference
  - prisma types
  - type-safe queries
  - prisma generics
  - Prisma.UserGetPayload
  - Prisma namespace
  - type guards
  - prisma validation
  - utility types
last_reviewed: 2025-11-16
```

## TypeScript Integration Overview

Prisma provides excellent TypeScript support with automatic type generation and inference.

**Key Features:**
1. **Auto-generated types**: Types generated from Prisma schema
2. **Type inference**: Return types inferred from queries
3. **Type safety**: Compile-time checks for queries
4. **Utility types**: Helper types for complex scenarios
5. **Generic patterns**: Reusable type-safe patterns

## Generated Types

### Model Types

```typescript
// Generated from Prisma schema
import { User, Post, Profile } from '@prisma/client';

// Basic usage
const user: User = {
  id: 1,
  email: 'alice@example.com',
  name: 'Alice',
  role: 'USER',
  createdAt: new Date(),
  updatedAt: new Date(),
};

// Type checking
function processUser(user: User) {
  console.log(user.email); // ✓ Type-safe
  // console.log(user.foo); // ✗ Error: Property 'foo' does not exist
}
```

### Query Return Types

```typescript
// findUnique returns User | null
const user = await prisma.user.findUnique({
  where: { id: 1 },
});
// Type: User | null

// findUniqueOrThrow returns User (no null)
const user2 = await prisma.user.findUniqueOrThrow({
  where: { id: 1 },
});
// Type: User

// findMany returns User[]
const users = await prisma.user.findMany();
// Type: User[]

// create returns User
const newUser = await prisma.user.create({
  data: { email: 'test@example.com', name: 'Test' },
});
// Type: User
```

## Prisma Namespace Types

### Prisma.UserGetPayload

Extract types including relations from queries.

```typescript
import { Prisma } from '@prisma/client';

// User with posts included
type UserWithPosts = Prisma.UserGetPayload<{
  include: { posts: true };
}>;

// Usage
const user: UserWithPosts = await prisma.user.findUnique({
  where: { id: 1 },
  include: { posts: true },
});

// Type: { id: number, email: string, ..., posts: Post[] }
console.log(user.posts); // ✓ Type-safe access to posts

// User with specific fields selected
type UserPublicInfo = Prisma.UserGetPayload<{
  select: {
    id: true;
    name: true;
    email: true;
  };
}>;

// Type: { id: number, name: string, email: string }
const publicUser: UserPublicInfo = await prisma.user.findUnique({
  where: { id: 1 },
  select: { id: true, name: true, email: true },
});
```

### Complex Payload Types

```typescript
// Nested relations
type UserWithPostsAndComments = Prisma.UserGetPayload<{
  include: {
    posts: {
      include: {
        comments: true;
      };
    };
    profile: true;
  };
}>;

// Partial selection with relations
type UserWithPostCount = Prisma.UserGetPayload<{
  select: {
    id: true;
    name: true;
    _count: {
      select: { posts: true };
    };
  };
}>;

// Type: { id: number, name: string, _count: { posts: number } }
```

## Prisma Input Types

### Create Input Types

```typescript
// Type for creating a user
type UserCreateInput = Prisma.UserCreateInput;

const createUserData: UserCreateInput = {
  email: 'alice@example.com',
  name: 'Alice',
  posts: {
    create: [
      { title: 'Post 1', content: 'Content 1' },
      { title: 'Post 2', content: 'Content 2' },
    ],
  },
};

await prisma.user.create({ data: createUserData });
```

### Update Input Types

```typescript
// Type for updating a user
type UserUpdateInput = Prisma.UserUpdateInput;

const updateUserData: UserUpdateInput = {
  name: { set: 'Alice Updated' },
  posts: {
    create: { title: 'New Post', content: 'Content' },
    updateMany: {
      where: { published: false },
      data: { published: true },
    },
  },
};

await prisma.user.update({
  where: { id: 1 },
  data: updateUserData,
});
```

### Where Input Types

```typescript
// Type for where clauses
type UserWhereInput = Prisma.UserWhereInput;

const searchFilter: UserWhereInput = {
  OR: [
    { email: { contains: 'example.com' } },
    { name: { startsWith: 'Alice' } },
  ],
  role: { in: ['ADMIN', 'USER'] },
  posts: {
    some: {
      published: true,
      createdAt: { gte: new Date('2024-01-01') },
    },
  },
};

const users = await prisma.user.findMany({
  where: searchFilter,
});
```

## Generic Repository Pattern

### Base Repository

```typescript
import { PrismaClient, Prisma } from '@prisma/client';

// Generic repository interface
interface Repository<T, CreateInput, UpdateInput, WhereInput, WhereUniqueInput> {
  findMany(args?: { where?: WhereInput }): Promise<T[]>;
  findUnique(where: WhereUniqueInput): Promise<T | null>;
  create(data: CreateInput): Promise<T>;
  update(where: WhereUniqueInput, data: UpdateInput): Promise<T>;
  delete(where: WhereUniqueInput): Promise<T>;
}

// Base repository implementation
class BaseRepository<
  T,
  CreateInput,
  UpdateInput,
  WhereInput,
  WhereUniqueInput
> implements Repository<T, CreateInput, UpdateInput, WhereInput, WhereUniqueInput> {
  constructor(
    private model: any // Prisma model delegate
  ) {}

  async findMany(args?: { where?: WhereInput }): Promise<T[]> {
    return this.model.findMany(args);
  }

  async findUnique(where: WhereUniqueInput): Promise<T | null> {
    return this.model.findUnique({ where });
  }

  async create(data: CreateInput): Promise<T> {
    return this.model.create({ data });
  }

  async update(where: WhereUniqueInput, data: UpdateInput): Promise<T> {
    return this.model.update({ where, data });
  }

  async delete(where: WhereUniqueInput): Promise<T> {
    return this.model.delete({ where });
  }
}
```

### Typed Repository

```typescript
import { User, Prisma } from '@prisma/client';

// User repository with full type safety
class UserRepository extends BaseRepository<
  User,
  Prisma.UserCreateInput,
  Prisma.UserUpdateInput,
  Prisma.UserWhereInput,
  Prisma.UserWhereUniqueInput
> {
  constructor(private prisma: PrismaClient) {
    super(prisma.user);
  }

  // Custom methods with type safety
  async findByEmail(email: string): Promise<User | null> {
    return this.prisma.user.findUnique({
      where: { email },
    });
  }

  async findActiveUsers(): Promise<User[]> {
    return this.prisma.user.findMany({
      where: { status: 'ACTIVE' },
    });
  }

  async createWithProfile(
    userData: Prisma.UserCreateInput,
    profileData: Omit<Prisma.ProfileCreateInput, 'user'>
  ): Promise<User> {
    return this.prisma.user.create({
      data: {
        ...userData,
        profile: {
          create: profileData,
        },
      },
      include: { profile: true },
    });
  }
}

// Usage
const userRepo = new UserRepository(prisma);

const user = await userRepo.findByEmail('alice@example.com');
// Type: User | null

const activeUsers = await userRepo.findActiveUsers();
// Type: User[]
```

## Type-Safe Query Building

### Query Builder Pattern

```typescript
import { Prisma, PrismaClient } from '@prisma/client';

class UserQueryBuilder {
  private whereConditions: Prisma.UserWhereInput[] = [];
  private includeOptions: Prisma.UserInclude = {};
  private selectOptions?: Prisma.UserSelect;

  constructor(private prisma: PrismaClient) {}

  where(condition: Prisma.UserWhereInput): this {
    this.whereConditions.push(condition);
    return this;
  }

  include(relations: Prisma.UserInclude): this {
    this.includeOptions = { ...this.includeOptions, ...relations };
    return this;
  }

  select(fields: Prisma.UserSelect): this {
    this.selectOptions = fields;
    return this;
  }

  async execute() {
    return this.prisma.user.findMany({
      where: this.whereConditions.length > 0
        ? { AND: this.whereConditions }
        : undefined,
      include: Object.keys(this.includeOptions).length > 0
        ? this.includeOptions
        : undefined,
      select: this.selectOptions,
    });
  }
}

// Usage
const users = await new UserQueryBuilder(prisma)
  .where({ role: 'ADMIN' })
  .where({ status: 'ACTIVE' })
  .include({ posts: true, profile: true })
  .execute();
// Type: (User & { posts: Post[], profile: Profile | null })[]
```

### Fluent Query API

```typescript
class FluentUserQuery {
  private query: any = {};

  constructor(private prisma: PrismaClient) {}

  byEmail(email: string): this {
    this.query.where = { ...this.query.where, email };
    return this;
  }

  byRole(role: string): this {
    this.query.where = { ...this.query.where, role };
    return this;
  }

  withPosts(): this {
    this.query.include = { ...this.query.include, posts: true };
    return this;
  }

  withProfile(): this {
    this.query.include = { ...this.query.include, profile: true };
    return this;
  }

  async first(): Promise<User | null> {
    return this.prisma.user.findFirst(this.query);
  }

  async all(): Promise<User[]> {
    return this.prisma.user.findMany(this.query);
  }
}

// Usage
const user = await new FluentUserQuery(prisma)
  .byEmail('alice@example.com')
  .withPosts()
  .withProfile()
  .first();
```

## Type Guards and Validation

### Type Guards

```typescript
import { User, Post } from '@prisma/client';

// Type guard for User
function isUser(obj: any): obj is User {
  return (
    typeof obj === 'object' &&
    obj !== null &&
    typeof obj.id === 'number' &&
    typeof obj.email === 'string' &&
    typeof obj.name === 'string'
  );
}

// Type guard for User with posts
type UserWithPosts = User & { posts: Post[] };

function isUserWithPosts(obj: any): obj is UserWithPosts {
  return (
    isUser(obj) &&
    Array.isArray(obj.posts) &&
    obj.posts.every((post: any) => isPost(post))
  );
}

function isPost(obj: any): obj is Post {
  return (
    typeof obj === 'object' &&
    obj !== null &&
    typeof obj.id === 'number' &&
    typeof obj.title === 'string'
  );
}

// Usage
const data: unknown = await prisma.user.findUnique({
  where: { id: 1 },
  include: { posts: true },
});

if (isUserWithPosts(data)) {
  // Type: UserWithPosts
  console.log(data.posts.length);
}
```

### Runtime Validation with Zod

```typescript
import { z } from 'zod';
import { Prisma } from '@prisma/client';

// Zod schema matching Prisma model
const UserSchema = z.object({
  id: z.number(),
  email: z.string().email(),
  name: z.string().min(1),
  role: z.enum(['USER', 'ADMIN']),
  createdAt: z.date(),
  updatedAt: z.date(),
});

// Validate Prisma query result
async function getValidatedUser(id: number) {
  const user = await prisma.user.findUnique({
    where: { id },
  });

  if (!user) {
    return null;
  }

  // Validate and return
  return UserSchema.parse(user);
}

// Create input validation
const CreateUserSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1).max(100),
  role: z.enum(['USER', 'ADMIN']).optional(),
});

async function createValidatedUser(data: unknown) {
  const validated = CreateUserSchema.parse(data);

  return prisma.user.create({
    data: validated,
  });
}
```

## Utility Types and Helpers

### Partial Types

```typescript
import { Prisma } from '@prisma/client';

// Partial update helper
type PartialUser = Partial<Prisma.UserUpdateInput>;

async function partialUpdate(id: number, data: PartialUser) {
  return prisma.user.update({
    where: { id },
    data,
  });
}

// Usage
await partialUpdate(1, { name: { set: 'Alice' } });
await partialUpdate(1, { role: { set: 'ADMIN' } });
```

### Pick and Omit

```typescript
import { User } from '@prisma/client';

// Pick specific fields
type UserPublic = Pick<User, 'id' | 'name' | 'email'>;

function toPublicUser(user: User): UserPublic {
  return {
    id: user.id,
    name: user.name,
    email: user.email,
  };
}

// Omit sensitive fields
type UserWithoutPassword = Omit<User, 'password' | 'resetToken'>;

async function getUserSafe(id: number): Promise<UserWithoutPassword | null> {
  const user = await prisma.user.findUnique({
    where: { id },
  });

  if (!user) return null;

  const { password, resetToken, ...safeUser } = user as any;
  return safeUser;
}
```

### Custom Utility Types

```typescript
// Extract relation type
type ExtractRelation<T, K extends keyof T> = T[K];

// Example: Extract Post type from User
type UserPosts = ExtractRelation<
  Prisma.UserGetPayload<{ include: { posts: true } }>,
  'posts'
>;
// Type: Post[]

// Make all fields optional except specified
type PartialExcept<T, K extends keyof T> = Partial<T> & Pick<T, K>;

type UserUpdateExceptId = PartialExcept<User, 'id'>;
// Type: { id: number } & Partial<Omit<User, 'id'>>

// Deep partial for nested updates
type DeepPartial<T> = {
  [P in keyof T]?: T[P] extends object ? DeepPartial<T[P]> : T[P];
};
```

## Advanced Patterns

### Conditional Types

```typescript
import { Prisma } from '@prisma/client';

// Conditional return type based on include/select
type UserQueryResult<T extends { include?: any; select?: any }> =
  T extends { select: infer S }
    ? Prisma.UserGetPayload<{ select: S }>
    : T extends { include: infer I }
    ? Prisma.UserGetPayload<{ include: I }>
    : User;

async function getUser<T extends { include?: any; select?: any }>(
  id: number,
  options?: T
): Promise<UserQueryResult<T> | null> {
  return prisma.user.findUnique({
    where: { id },
    ...options,
  }) as any;
}

// Usage with type inference
const user1 = await getUser(1);
// Type: User | null

const user2 = await getUser(1, { include: { posts: true } });
// Type: (User & { posts: Post[] }) | null

const user3 = await getUser(1, { select: { id: true, name: true } });
// Type: { id: number, name: string } | null
```

### Generic CRUD Service

```typescript
import { PrismaClient, Prisma } from '@prisma/client';

type ModelName = Prisma.ModelName;

type ModelDelegate<M extends ModelName> = M extends 'User'
  ? PrismaClient['user']
  : M extends 'Post'
  ? PrismaClient['post']
  : never;

class CRUDService<M extends ModelName> {
  private delegate: ModelDelegate<M>;

  constructor(
    private prisma: PrismaClient,
    private modelName: M
  ) {
    this.delegate = prisma[modelName.toLowerCase()] as any;
  }

  async findMany(args?: any) {
    return this.delegate.findMany(args);
  }

  async findUnique(where: any) {
    return this.delegate.findUnique({ where });
  }

  async create(data: any) {
    return this.delegate.create({ data });
  }

  async update(where: any, data: any) {
    return this.delegate.update({ where, data });
  }

  async delete(where: any) {
    return this.delegate.delete({ where });
  }
}

// Usage
const userService = new CRUDService(prisma, 'User');
const users = await userService.findMany();

const postService = new CRUDService(prisma, 'Post');
const posts = await postService.findMany();
```

### Typed Middleware

```typescript
import { Prisma } from '@prisma/client';

// Middleware with type safety
const loggingMiddleware: Prisma.Middleware = async (params, next) => {
  const before = Date.now();
  const result = await next(params);
  const after = Date.now();

  console.log(`Query ${params.model}.${params.action} took ${after - before}ms`);

  return result;
};

prisma.$use(loggingMiddleware);

// Conditional middleware
const softDeleteMiddleware: Prisma.Middleware = async (params, next) => {
  if (params.model === 'User') {
    if (params.action === 'delete') {
      // Change delete to update
      params.action = 'update';
      params.args.data = { deletedAt: new Date() };
    }

    if (params.action === 'findMany' || params.action === 'findFirst') {
      // Add filter for non-deleted
      params.args.where = {
        ...params.args.where,
        deletedAt: null,
      };
    }
  }

  return next(params);
};

prisma.$use(softDeleteMiddleware);
```

## Type-Safe API Responses

### API Response Types

```typescript
import { User, Post } from '@prisma/client';

// Generic API response
type ApiResponse<T> = {
  success: boolean;
  data?: T;
  error?: string;
};

// User response types
type UserResponse = ApiResponse<User>;
type UsersResponse = ApiResponse<User[]>;
type UserWithPostsResponse = ApiResponse<
  Prisma.UserGetPayload<{ include: { posts: true } }>
>;

// API handler with type safety
async function getUserHandler(id: number): Promise<UserResponse> {
  try {
    const user = await prisma.user.findUnique({
      where: { id },
    });

    if (!user) {
      return {
        success: false,
        error: 'User not found',
      };
    }

    return {
      success: true,
      data: user,
    };
  } catch (error) {
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error',
    };
  }
}
```

### Paginated Responses

```typescript
type PaginatedResponse<T> = {
  data: T[];
  pagination: {
    page: number;
    pageSize: number;
    total: number;
    totalPages: number;
  };
};

async function getPaginatedUsers(
  page: number,
  pageSize: number
): Promise<PaginatedResponse<User>> {
  const skip = (page - 1) * pageSize;

  const [data, total] = await Promise.all([
    prisma.user.findMany({
      skip,
      take: pageSize,
    }),
    prisma.user.count(),
  ]);

  return {
    data,
    pagination: {
      page,
      pageSize,
      total,
      totalPages: Math.ceil(total / pageSize),
    },
  };
}
```

## AI Pair Programming Notes

**When using TypeScript with Prisma:**

1. **Leverage generated types**: Use Prisma's generated types instead of manually defining them
2. **Use Prisma.UserGetPayload**: For extracting types with relations/selections
3. **Type query results**: Let TypeScript infer types from Prisma queries
4. **Validate at runtime**: Use Zod for runtime validation of Prisma inputs/outputs
5. **Generic patterns**: Create reusable generic repositories and services
6. **Type guards**: Implement type guards for unknown data
7. **Utility types**: Use Pick, Omit, Partial for API responses
8. **Avoid `any`**: Use proper Prisma types instead of `any`
9. **Middleware typing**: Use Prisma.Middleware for type-safe middleware
10. **Conditional types**: Use conditional types for flexible APIs

**Common TypeScript mistakes with Prisma:**
- Not using Prisma.UserGetPayload for relation types
- Manually typing what Prisma can infer
- Using `any` for Prisma query results
- Not validating runtime input data
- Ignoring null possibility in findUnique results
- Not typing API responses properly
- Missing type guards for unknown data
- Over-complicating with unnecessary generics
- Not leveraging Prisma's input types (CreateInput, UpdateInput)
- Forgetting to handle Prisma errors with proper types

## Next Steps

1. **10-ADVANCED-PATTERNS.md** - Advanced Prisma patterns and techniques
2. **11-CONFIG-OPERATIONS.md** - Production configuration and operations
3. **TypeScript KB** - ../typescript/ for general TypeScript patterns

## Additional Resources

- Prisma TypeScript: https://www.prisma.io/docs/concepts/components/prisma-client/working-with-prismaclient/use-custom-model-and-field-names
- Advanced Type Safety: https://www.prisma.io/docs/concepts/components/prisma-client/advanced-type-safety
- Prisma Client API Reference: https://www.prisma.io/docs/reference/api-reference/prisma-client-reference
- TypeScript Handbook: https://www.typescriptlang.org/docs/handbook/intro.html
