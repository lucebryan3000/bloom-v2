# Prisma Advanced Patterns

```yaml
id: prisma_10_advanced_patterns
topic: Prisma
file_role: Advanced patterns, techniques, and architectural approaches
profile: expert
difficulty_level: expert
kb_version: v3.1
prerequisites:
  - Fundamentals (01-FUNDAMENTALS.md)
  - Client API (03-CLIENT-API.md)
  - Transactions (06-TRANSACTIONS.md)
  - Performance (07-PERFORMANCE.md)
  - TypeScript Patterns (09-TYPESCRIPT-PATTERNS.md)
related_topics:
  - Testing (08-TESTING.md)
  - Config Operations (11-CONFIG-OPERATIONS.md)
  - PostgreSQL Advanced (../postgresql/08-ADVANCED-TOPICS.md)
embedding_keywords:
  - prisma advanced patterns
  - soft delete
  - multi-tenancy
  - row level security
  - audit logging
  - change tracking
  - full-text search
  - custom field types
  - database views
  - materialized views
last_reviewed: 2025-11-16
```

## Advanced Patterns Overview

**Advanced Patterns Covered:**
1. Soft Deletes
2. Multi-Tenancy
3. Audit Logging & Change Tracking
4. Row-Level Security (RLS)
5. Full-Text Search
6. Custom Field Types
7. Database Views
8. Materialized Views
9. Event Sourcing
10. CQRS with Prisma

## Soft Delete Pattern

### Implementation with Middleware

```prisma
// schema.prisma
model User {
  id        Int       @id @default(autoincrement())
  email     String    @unique
  name      String
  deletedAt DateTime?
  createdAt DateTime  @default(now())
  updatedAt DateTime  @updatedAt
}
```

```typescript
// lib/prisma/soft-delete-middleware.ts
import { Prisma } from '@prisma/client';

export const softDeleteMiddleware: Prisma.Middleware = async (params, next) => {
  // Intercept delete operations
  if (params.action === 'delete') {
    params.action = 'update';
    params.args.data = { deletedAt: new Date() };
  }

  // Intercept deleteMany operations
  if (params.action === 'deleteMany') {
    params.action = 'updateMany';
    if (params.args.data !== undefined) {
      params.args.data.deletedAt = new Date();
    } else {
      params.args.data = { deletedAt: new Date() };
    }
  }

  // Exclude soft-deleted records from queries
  if (params.action === 'findUnique' || params.action === 'findFirst') {
    params.action = 'findFirst';
    params.args.where = {
      ...params.args.where,
      deletedAt: null,
    };
  }

  if (params.action === 'findMany') {
    if (params.args.where) {
      if (params.args.where.deletedAt === undefined) {
        params.args.where.deletedAt = null;
      }
    } else {
      params.args.where = { deletedAt: null };
    }
  }

  return next(params);
};

// Usage
import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();
prisma.$use(softDeleteMiddleware);
```

### Soft Delete Extension

```typescript
// lib/prisma/extensions/soft-delete.ts
import { Prisma } from '@prisma/client';

export const softDelete = Prisma.defineExtension({
  name: 'softDelete',
  model: {
    $allModels: {
      async softDelete<T>(
        this: T,
        where: Prisma.Args<T, 'delete'>['where']
      ): Promise<Prisma.Result<T, {}, 'update'>> {
        const context = Prisma.getExtensionContext(this) as any;

        return context.update({
          where,
          data: { deletedAt: new Date() },
        });
      },

      async restore<T>(
        this: T,
        where: Prisma.Args<T, 'update'>['where']
      ): Promise<Prisma.Result<T, {}, 'update'>> {
        const context = Prisma.getExtensionContext(this) as any;

        return context.update({
          where,
          data: { deletedAt: null },
        });
      },

      async findManyWithDeleted<T>(
        this: T,
        args?: Prisma.Args<T, 'findMany'>
      ): Promise<Prisma.Result<T, {}, 'findMany'>> {
        const context = Prisma.getExtensionContext(this) as any;
        return context.findMany(args);
      },
    },
  },
});

// Usage
const xprisma = new PrismaClient().$extends(softDelete);

// Soft delete (sets deletedAt)
await xprisma.user.softDelete({ where: { id: 1 } });

// Restore soft-deleted record
await xprisma.user.restore({ where: { id: 1 } });

// Find including deleted records
const allUsers = await xprisma.user.findManyWithDeleted();
```

## Multi-Tenancy Patterns

### Pattern 1: Tenant Column

```prisma
// schema.prisma
model Tenant {
  id    Int    @id @default(autoincrement())
  name  String
  users User[]
  posts Post[]
}

model User {
  id       Int    @id @default(autoincrement())
  email    String
  tenantId Int
  tenant   Tenant @relation(fields: [tenantId], references: [id])
  posts    Post[]

  @@unique([email, tenantId])
  @@index([tenantId])
}

model Post {
  id       Int    @id @default(autoincrement())
  title    String
  tenantId Int
  authorId Int
  tenant   Tenant @relation(fields: [tenantId], references: [id])
  author   User   @relation(fields: [authorId], references: [id])

  @@index([tenantId])
}
```

```typescript
// lib/prisma/multi-tenant.ts
import { PrismaClient } from '@prisma/client';

export function createTenantClient(tenantId: number) {
  const prisma = new PrismaClient();

  // Middleware to inject tenantId
  prisma.$use(async (params, next) => {
    // Inject tenantId for creates
    if (params.action === 'create' || params.action === 'createMany') {
      if (params.args.data) {
        if (Array.isArray(params.args.data)) {
          params.args.data = params.args.data.map((item) => ({
            ...item,
            tenantId,
          }));
        } else {
          params.args.data = { ...params.args.data, tenantId };
        }
      }
    }

    // Filter by tenantId for queries
    if (
      params.action === 'findMany' ||
      params.action === 'findFirst' ||
      params.action === 'findUnique'
    ) {
      params.args.where = {
        ...params.args.where,
        tenantId,
      };
    }

    // Filter by tenantId for updates/deletes
    if (params.action === 'update' || params.action === 'delete') {
      params.args.where = {
        ...params.args.where,
        tenantId,
      };
    }

    return next(params);
  });

  return prisma;
}

// Usage
const tenant1Prisma = createTenantClient(1);
const tenant2Prisma = createTenantClient(2);

// All queries automatically scoped to tenant
const users = await tenant1Prisma.user.findMany(); // Only tenant 1 users
```

### Pattern 2: Row-Level Security (PostgreSQL)

```sql
-- Enable RLS on tables
ALTER TABLE "User" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "Post" ENABLE ROW LEVEL SECURITY;

-- Create policy to filter by tenant
CREATE POLICY tenant_isolation ON "User"
  USING ("tenantId" = current_setting('app.current_tenant_id')::int);

CREATE POLICY tenant_isolation ON "Post"
  USING ("tenantId" = current_setting('app.current_tenant_id')::int);
```

```typescript
// lib/prisma/rls-tenant.ts
import { PrismaClient } from '@prisma/client';

export async function withTenant<T>(
  tenantId: number,
  callback: (prisma: PrismaClient) => Promise<T>
): Promise<T> {
  const prisma = new PrismaClient();

  try {
    // Set tenant context for RLS
    await prisma.$executeRawUnsafe(
      `SET LOCAL app.current_tenant_id = ${tenantId}`
    );

    const result = await callback(prisma);
    return result;
  } finally {
    await prisma.$disconnect();
  }
}

// Usage
const users = await withTenant(1, async (prisma) => {
  return prisma.user.findMany(); // Automatically filtered by RLS
});
```

## Audit Logging & Change Tracking

### Audit Log Schema

```prisma
model AuditLog {
  id        Int      @id @default(autoincrement())
  table     String
  recordId  Int
  action    String   // CREATE, UPDATE, DELETE
  oldData   Json?
  newData   Json?
  userId    Int?
  user      User?    @relation(fields: [userId], references: [id])
  timestamp DateTime @default(now())

  @@index([table, recordId])
  @@index([userId])
  @@index([timestamp])
}
```

### Audit Middleware

```typescript
// lib/prisma/audit-middleware.ts
import { Prisma, PrismaClient } from '@prisma/client';

export function createAuditMiddleware(userId?: number): Prisma.Middleware {
  return async (params, next) => {
    const result = await next(params);

    // Track creates
    if (params.action === 'create') {
      await logAudit(params.model!, result.id, 'CREATE', null, result, userId);
    }

    // Track updates (need to fetch old data)
    if (params.action === 'update') {
      const oldData = await (params as any).model?.findUnique({
        where: params.args.where,
      });
      await logAudit(
        params.model!,
        params.args.where.id,
        'UPDATE',
        oldData,
        result,
        userId
      );
    }

    // Track deletes
    if (params.action === 'delete') {
      await logAudit(
        params.model!,
        params.args.where.id,
        'DELETE',
        result,
        null,
        userId
      );
    }

    return result;
  };
}

async function logAudit(
  table: string,
  recordId: number,
  action: string,
  oldData: any,
  newData: any,
  userId?: number
) {
  const auditPrisma = new PrismaClient();
  try {
    await auditPrisma.auditLog.create({
      data: {
        table,
        recordId,
        action,
        oldData: oldData || undefined,
        newData: newData || undefined,
        userId,
      },
    });
  } finally {
    await auditPrisma.$disconnect();
  }
}
```

### Change Tracking with Temporal Tables

```sql
-- Create history table
CREATE TABLE "User_history" (
  id         INT,
  email      TEXT,
  name       TEXT,
  createdAt  TIMESTAMPTZ,
  updatedAt  TIMESTAMPTZ,
  validFrom  TIMESTAMPTZ NOT NULL,
  validTo    TIMESTAMPTZ,
  PRIMARY KEY (id, validFrom)
);

-- Trigger to track changes
CREATE OR REPLACE FUNCTION user_history_trigger()
RETURNS TRIGGER AS $$
BEGIN
  -- Close current history record
  UPDATE "User_history"
  SET "validTo" = NOW()
  WHERE id = OLD.id AND "validTo" IS NULL;

  -- Insert new history record
  INSERT INTO "User_history" (id, email, name, "createdAt", "updatedAt", "validFrom", "validTo")
  VALUES (NEW.id, NEW.email, NEW.name, NEW."createdAt", NEW."updatedAt", NOW(), NULL);

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER user_history
AFTER UPDATE ON "User"
FOR EACH ROW EXECUTE FUNCTION user_history_trigger();
```

## Full-Text Search

### PostgreSQL Full-Text Search

```prisma
model Post {
  id          Int      @id @default(autoincrement())
  title       String
  content     String
  searchVector Unsupported("tsvector")?

  @@index([searchVector], type: Gin)
}
```

```typescript
// Full-text search with Prisma
async function searchPosts(query: string) {
  return prisma.$queryRaw`
    SELECT *
    FROM "Post"
    WHERE "searchVector" @@ plainto_tsquery('english', ${query})
    ORDER BY ts_rank("searchVector", plainto_tsquery('english', ${query})) DESC
    LIMIT 100
  `;
}

// Trigger to auto-update search vector
await prisma.$executeRaw`
  CREATE OR REPLACE FUNCTION posts_search_trigger()
  RETURNS TRIGGER AS $$
  BEGIN
    NEW."searchVector" :=
      setweight(to_tsvector('english', COALESCE(NEW.title, '')), 'A') ||
      setweight(to_tsvector('english', COALESCE(NEW.content, '')), 'B');
    RETURN NEW;
  END;
  $$ LANGUAGE plpgsql;

  CREATE TRIGGER posts_search_update
  BEFORE INSERT OR UPDATE ON "Post"
  FOR EACH ROW EXECUTE FUNCTION posts_search_trigger();
`;
```

### Search with Ranking

```typescript
interface SearchResult {
  id: number;
  title: string;
  content: string;
  rank: number;
}

async function searchPostsWithRank(query: string): Promise<SearchResult[]> {
  return prisma.$queryRaw<SearchResult[]>`
    SELECT
      id,
      title,
      content,
      ts_rank("searchVector", plainto_tsquery('english', ${query})) as rank
    FROM "Post"
    WHERE "searchVector" @@ plainto_tsquery('english', ${query})
    ORDER BY rank DESC
    LIMIT 100
  `;
}
```

## Custom Field Types

### JSON Field Patterns

```prisma
model Settings {
  id       Int  @id @default(autoincrement())
  userId   Int  @unique
  metadata Json
}
```

```typescript
// Type-safe JSON handling
interface UserMetadata {
  theme: 'light' | 'dark';
  notifications: {
    email: boolean;
    push: boolean;
  };
  preferences: Record<string, any>;
}

async function updateUserMetadata(
  userId: number,
  metadata: UserMetadata
): Promise<void> {
  await prisma.settings.upsert({
    where: { userId },
    create: {
      userId,
      metadata: metadata as any,
    },
    update: {
      metadata: metadata as any,
    },
  });
}

async function getUserMetadata(userId: number): Promise<UserMetadata | null> {
  const settings = await prisma.settings.findUnique({
    where: { userId },
  });

  return settings?.metadata as UserMetadata | null;
}
```

### Encrypted Fields

```typescript
// lib/crypto.ts
import crypto from 'crypto';

const ENCRYPTION_KEY = process.env.ENCRYPTION_KEY!; // 32 bytes
const IV_LENGTH = 16;

export function encrypt(text: string): string {
  const iv = crypto.randomBytes(IV_LENGTH);
  const cipher = crypto.createCipheriv(
    'aes-256-cbc',
    Buffer.from(ENCRYPTION_KEY, 'hex'),
    iv
  );
  let encrypted = cipher.update(text, 'utf8', 'hex');
  encrypted += cipher.final('hex');
  return iv.toString('hex') + ':' + encrypted;
}

export function decrypt(text: string): string {
  const parts = text.split(':');
  const iv = Buffer.from(parts[0], 'hex');
  const encryptedText = parts[1];
  const decipher = crypto.createDecipheriv(
    'aes-256-cbc',
    Buffer.from(ENCRYPTION_KEY, 'hex'),
    iv
  );
  let decrypted = decipher.update(encryptedText, 'hex', 'utf8');
  decrypted += decipher.final('utf8');
  return decrypted;
}

// Usage with Prisma
async function createUserWithSSN(email: string, ssn: string) {
  return prisma.user.create({
    data: {
      email,
      ssn: encrypt(ssn),
    },
  });
}

async function getUserSSN(userId: number): Promise<string | null> {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { ssn: true },
  });

  return user?.ssn ? decrypt(user.ssn) : null;
}
```

## Database Views

### Creating Views with Prisma

```sql
-- Create view
CREATE VIEW "UserStats" AS
SELECT
  u.id,
  u.name,
  u.email,
  COUNT(DISTINCT p.id) as "postCount",
  COUNT(DISTINCT c.id) as "commentCount"
FROM "User" u
LEFT JOIN "Post" p ON p."authorId" = u.id
LEFT JOIN "Comment" c ON c."authorId" = u.id
GROUP BY u.id, u.name, u.email;
```

```prisma
// schema.prisma - Define view as model
model UserStats {
  id           Int    @id
  name         String
  email        String
  postCount    Int
  commentCount Int

  @@map("UserStats")
}
```

```typescript
// Query view like a table
const stats = await prisma.userStats.findMany({
  where: {
    postCount: { gte: 10 },
  },
  orderBy: { postCount: 'desc' },
});
```

## Materialized Views

### Refresh Strategy

```sql
-- Create materialized view
CREATE MATERIALIZED VIEW "DailyStats" AS
SELECT
  DATE("createdAt") as date,
  COUNT(*) as "postCount",
  COUNT(DISTINCT "authorId") as "authorCount"
FROM "Post"
GROUP BY DATE("createdAt");

-- Create index for fast queries
CREATE INDEX idx_daily_stats_date ON "DailyStats" (date);
```

```typescript
// Refresh materialized view
async function refreshDailyStats() {
  await prisma.$executeRaw`REFRESH MATERIALIZED VIEW "DailyStats"`;
}

// Concurrent refresh (doesn't block reads)
async function refreshDailyStatsConcurrent() {
  await prisma.$executeRaw`REFRESH MATERIALIZED VIEW CONCURRENTLY "DailyStats"`;
}

// Schedule refresh with cron
import cron from 'node-cron';

cron.schedule('0 0 * * *', async () => {
  // Refresh daily at midnight
  await refreshDailyStatsConcurrent();
});
```

## Event Sourcing Pattern

### Event Store Schema

```prisma
model Event {
  id          Int      @id @default(autoincrement())
  aggregateId String
  type        String
  data        Json
  metadata    Json?
  version     Int
  timestamp   DateTime @default(now())

  @@unique([aggregateId, version])
  @@index([aggregateId])
  @@index([type])
  @@index([timestamp])
}

model Snapshot {
  id          Int      @id @default(autoincrement())
  aggregateId String   @unique
  version     Int
  state       Json
  timestamp   DateTime @default(now())
}
```

### Event Sourcing Implementation

```typescript
// lib/event-sourcing/event-store.ts
import { PrismaClient } from '@prisma/client';

export class EventStore {
  constructor(private prisma: PrismaClient) {}

  async appendEvent(
    aggregateId: string,
    type: string,
    data: any,
    expectedVersion?: number
  ): Promise<void> {
    await this.prisma.$transaction(async (tx) => {
      // Get current version
      const lastEvent = await tx.event.findFirst({
        where: { aggregateId },
        orderBy: { version: 'desc' },
      });

      const currentVersion = lastEvent?.version ?? 0;

      // Optimistic concurrency check
      if (expectedVersion !== undefined && currentVersion !== expectedVersion) {
        throw new Error('Concurrency conflict');
      }

      // Append event
      await tx.event.create({
        data: {
          aggregateId,
          type,
          data,
          version: currentVersion + 1,
        },
      });
    });
  }

  async getEvents(aggregateId: string, fromVersion = 0) {
    return this.prisma.event.findMany({
      where: {
        aggregateId,
        version: { gt: fromVersion },
      },
      orderBy: { version: 'asc' },
    });
  }

  async saveSnapshot(aggregateId: string, version: number, state: any) {
    await this.prisma.snapshot.upsert({
      where: { aggregateId },
      create: {
        aggregateId,
        version,
        state,
      },
      update: {
        version,
        state,
      },
    });
  }

  async getSnapshot(aggregateId: string) {
    return this.prisma.snapshot.findUnique({
      where: { aggregateId },
    });
  }
}
```

## CQRS Pattern

### Command and Query Separation

```typescript
// commands/create-user.command.ts
export class CreateUserCommand {
  constructor(
    public readonly email: string,
    public readonly name: string
  ) {}
}

export class CreateUserCommandHandler {
  constructor(private prisma: PrismaClient) {}

  async execute(command: CreateUserCommand) {
    // Write model - normalized for writes
    const user = await this.prisma.user.create({
      data: {
        email: command.email,
        name: command.name,
      },
    });

    // Publish event or update read model
    await this.updateReadModel(user);

    return user;
  }

  private async updateReadModel(user: any) {
    // Update denormalized read model
    await this.prisma.userReadModel.create({
      data: {
        id: user.id,
        email: user.email,
        name: user.name,
        postCount: 0,
        lastActivity: new Date(),
      },
    });
  }
}
```

```typescript
// queries/get-user-profile.query.ts
export class GetUserProfileQuery {
  constructor(public readonly userId: number) {}
}

export class GetUserProfileQueryHandler {
  constructor(private prisma: PrismaClient) {}

  async execute(query: GetUserProfileQuery) {
    // Query optimized read model
    return this.prisma.userReadModel.findUnique({
      where: { id: query.userId },
      include: {
        recentPosts: {
          take: 10,
          orderBy: { createdAt: 'desc' },
        },
      },
    });
  }
}
```

## AI Pair Programming Notes

**When using advanced Prisma patterns:**

1. **Soft deletes**: Use middleware or extensions for automatic filtering
2. **Multi-tenancy**: Choose pattern based on isolation requirements (column vs RLS)
3. **Audit logging**: Track all data changes with middleware
4. **Full-text search**: Use database-native search with generated columns
5. **Custom types**: Handle encryption, JSON validation at application layer
6. **Views**: Use for complex read queries and reporting
7. **Materialized views**: Refresh strategy for expensive aggregations
8. **Event sourcing**: Append-only events with snapshots for performance
9. **CQRS**: Separate read/write models for complex domains
10. **Performance**: Index appropriately, use transactions for consistency

**Common advanced pattern mistakes:**
- Not testing soft delete middleware thoroughly
- Missing tenant isolation in multi-tenant systems
- Over-auditing (logging too much, killing performance)
- Not indexing full-text search vectors
- Storing sensitive data unencrypted in JSON fields
- Forgetting to refresh materialized views
- Event sourcing without snapshots (slow rehydration)
- CQRS without eventual consistency handling
- Not handling concurrency conflicts in event sourcing
- Missing indexes on audit/event tables

## Next Steps

1. **11-CONFIG-OPERATIONS.md** - Production configuration and operations
2. **PostgreSQL Advanced Topics** - ../postgresql/08-ADVANCED-TOPICS.md
3. **Testing Advanced Patterns** - 08-TESTING.md

## Additional Resources

- Prisma Client Extensions: https://www.prisma.io/docs/concepts/components/prisma-client/client-extensions
- PostgreSQL Row-Level Security: https://www.postgresql.org/docs/current/ddl-rowsecurity.html
- Full-Text Search: https://www.postgresql.org/docs/current/textsearch.html
- Event Sourcing: https://martinfowler.com/eaaDev/EventSourcing.html
- CQRS Pattern: https://martinfowler.com/bliki/CQRS.html
