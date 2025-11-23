# Prisma Migrations

```yaml
id: prisma_05_migrations
topic: Prisma
file_role: Schema migrations, version control, and database evolution
profile: intermediate
difficulty_level: intermediate
kb_version: v3.1
prerequisites:
  - Fundamentals (01-FUNDAMENTALS.md)
  - Schema Design (02-SCHEMA-DESIGN.md)
related_topics:
  - Schema Design (02-SCHEMA-DESIGN.md)
  - Config Operations (11-CONFIG-OPERATIONS.md)
  - Database (../postgresql/)
embedding_keywords:
  - prisma migrate
  - migrations
  - schema evolution
  - migrate dev
  - migrate deploy
  - migration files
  - database versioning
  - prisma db seed
  - migration history
last_reviewed: 2025-11-16
```

## Prisma Migrate Overview

Prisma Migrate is a declarative migration system that uses your Prisma schema as the source of truth.

**Key Concepts:**
- **Schema-first**: Define your data model in `schema.prisma`, Prisma generates SQL migrations
- **Migration files**: SQL files stored in `prisma/migrations/` directory
- **Migration history**: `_prisma_migrations` table tracks applied migrations
- **Idempotent**: Migrations can be safely rerun

**Workflow:**
```
1. Update schema.prisma
2. Run prisma migrate dev (development)
3. Review generated SQL
4. Commit migration files to git
5. Run prisma migrate deploy (production)
```

## Development Workflow

### Initial Migration

```bash
# Initialize database and create first migration
npx prisma migrate dev --name init

# What happens:
# 1. Creates `prisma/migrations/` directory
# 2. Generates migration SQL files
# 3. Applies migration to database
# 4. Generates Prisma Client
```

### Creating Migrations

```bash
# Create migration after schema changes
npx prisma migrate dev --name add_user_role

# Steps:
# 1. Detects schema changes
# 2. Generates migration SQL
# 3. Prompts for migration name
# 4. Applies to database
# 5. Regenerates Prisma Client
```

### Schema Evolution Example

```prisma
// Initial schema
model User {
  id    Int    @id @default(autoincrement())
  email String @unique
  name  String
}
```

```bash
# Create initial migration
npx prisma migrate dev --name init
```

```prisma
// Add new field
model User {
  id        Int      @id @default(autoincrement())
  email     String   @unique
  name      String
  role      String   @default("USER")  // New field
  createdAt DateTime @default(now())   // New field
}
```

```bash
# Create migration for changes
npx prisma migrate dev --name add_user_fields
```

## Migration Files

### File Structure

```
prisma/
├── schema.prisma
└── migrations/
    ├── 20231116120000_init/
    │   └── migration.sql
    ├── 20231117100000_add_user_role/
    │   └── migration.sql
    └── migration_lock.toml
```

### Migration SQL File

```sql
-- CreateTable
CREATE TABLE "User" (
    "id" SERIAL NOT NULL,
    "email" TEXT NOT NULL,
    "name" TEXT NOT NULL,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");
```

### Migration Metadata

Each migration directory contains:
- `migration.sql`: SQL statements to apply
- Timestamp prefix: `YYYYMMDDHHMMSS_migration_name`
- Auto-generated based on schema diff

## Production Workflow

### Deploying Migrations

```bash
# Apply pending migrations in production
npx prisma migrate deploy

# What happens:
# 1. Reads migration history from database
# 2. Applies unapplied migrations in order
# 3. Updates _prisma_migrations table
# 4. Does NOT generate Prisma Client (do this in build step)
```

### Deployment Pipeline

```bash
# Typical CI/CD pipeline

# 1. Install dependencies
npm install

# 2. Generate Prisma Client (build time)
npx prisma generate

# 3. Build application
npm run build

# 4. Deploy migrations (runtime, before starting app)
npx prisma migrate deploy

# 5. Start application
npm start
```

### Docker Example

```dockerfile
# Dockerfile
FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./
COPY prisma ./prisma/

# Install dependencies
RUN npm install

# Generate Prisma Client
RUN npx prisma generate

# Copy application code
COPY . .

# Build application
RUN npm run build

# Expose port
EXPOSE 3000

# Start script with migrations
CMD npx prisma migrate deploy && npm start
```

## Customizing Migrations

### Manual Migration Editing

```bash
# Create migration without applying
npx prisma migrate dev --create-only --name custom_migration

# Edit migration SQL before applying
# File: prisma/migrations/[timestamp]_custom_migration/migration.sql
```

```sql
-- Generated migration
ALTER TABLE "User" ADD COLUMN "role" TEXT NOT NULL DEFAULT 'USER';

-- Add custom SQL
CREATE INDEX CONCURRENTLY "idx_user_role" ON "User"("role");

-- Add data migration
UPDATE "User" SET "role" = 'ADMIN' WHERE "email" LIKE '%@admin.example.com';
```

```bash
# Apply edited migration
npx prisma migrate dev
```

### Data Migrations

```sql
-- Migration: backfill_user_slugs

-- Add slug column
ALTER TABLE "User" ADD COLUMN "slug" TEXT;

-- Backfill slugs from names
UPDATE "User"
SET "slug" = LOWER(REPLACE("name", ' ', '-'))
WHERE "slug" IS NULL;

-- Make slug required and unique
ALTER TABLE "User" ALTER COLUMN "slug" SET NOT NULL;
CREATE UNIQUE INDEX "User_slug_key" ON "User"("slug");
```

### Complex Schema Changes

```sql
-- Migration: split_name_into_first_last

-- Add new columns
ALTER TABLE "User" ADD COLUMN "firstName" TEXT;
ALTER TABLE "User" ADD COLUMN "lastName" TEXT;

-- Migrate data
UPDATE "User"
SET
  "firstName" = SPLIT_PART("name", ' ', 1),
  "lastName" = SPLIT_PART("name", ' ', 2)
WHERE "name" IS NOT NULL;

-- Make required
ALTER TABLE "User" ALTER COLUMN "firstName" SET NOT NULL;
ALTER TABLE "User" ALTER COLUMN "lastName" SET NOT NULL;

-- Drop old column
ALTER TABLE "User" DROP COLUMN "name";
```

## Migration Commands

### Development Commands

```bash
# Create and apply migration
npx prisma migrate dev --name migration_name

# Create migration without applying
npx prisma migrate dev --create-only --name migration_name

# Skip generate (useful in CI)
npx prisma migrate dev --skip-generate

# Skip seeding
npx prisma migrate dev --skip-seed
```

### Production Commands

```bash
# Apply pending migrations
npx prisma migrate deploy

# Validate migration history without applying
npx prisma migrate status

# Resolve migration issues (advanced)
npx prisma migrate resolve --applied migration_name
npx prisma migrate resolve --rolled-back migration_name
```

### Database Commands

```bash
# Reset database (WARNING: deletes all data)
npx prisma migrate reset

# What happens:
# 1. Drops database
# 2. Creates database
# 3. Applies all migrations
# 4. Runs seed script

# Push schema without migrations (prototyping)
npx prisma db push

# WARNING: Use only in development
# Bypasses migration system
```

## Migration Status

### Check Migration Status

```bash
npx prisma migrate status

# Output examples:

# ✅ All migrations applied
# Database schema is up to date!

# ⚠️ Pending migrations
# Following migrations have not yet been applied:
# 20231117100000_add_user_role

# ❌ Migration conflicts
# Your local migrations differ from production
```

### Migration History Table

```sql
-- _prisma_migrations table structure
CREATE TABLE "_prisma_migrations" (
  id                  VARCHAR(36) PRIMARY KEY,
  checksum            VARCHAR(64) NOT NULL,
  finished_at         TIMESTAMPTZ,
  migration_name      VARCHAR(255) NOT NULL,
  logs                TEXT,
  rolled_back_at      TIMESTAMPTZ,
  started_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  applied_steps_count INTEGER NOT NULL DEFAULT 0
);

-- Query migration history
SELECT
  migration_name,
  started_at,
  finished_at
FROM _prisma_migrations
ORDER BY started_at DESC;
```

## Database Seeding

### Seed Script

```typescript
// prisma/seed.ts
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  // Clear existing data
  await prisma.post.deleteMany();
  await prisma.user.deleteMany();

  // Create users
  const alice = await prisma.user.create({
    data: {
      email: 'alice@example.com',
      name: 'Alice',
      posts: {
        create: [
          {
            title: 'First post',
            content: 'This is my first post',
            published: true,
          },
          {
            title: 'Second post',
            content: 'This is my second post',
            published: false,
          },
        ],
      },
    },
  });

  const bob = await prisma.user.create({
    data: {
      email: 'bob@example.com',
      name: 'Bob',
    },
  });

  console.log({ alice, bob });
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

### Configure Seeding

```json
// package.json
{
  "name": "my-app",
  "prisma": {
    "seed": "ts-node prisma/seed.ts"
  },
  "scripts": {
    "seed": "prisma db seed"
  }
}
```

```bash
# Run seed manually
npm run seed

# Or
npx prisma db seed

# Seed runs automatically after:
# - prisma migrate reset
# - prisma migrate dev (unless --skip-seed)
```

### Environment-Specific Seeding

```typescript
// prisma/seed.ts
const isDevelopment = process.env.NODE_ENV === 'development';
const isProduction = process.env.NODE_ENV === 'production';

async function main() {
  if (isDevelopment) {
    // Seed lots of test data
    await seedDevelopmentData();
  }

  if (isProduction) {
    // Seed only essential data
    await seedProductionData();
  }
}

async function seedDevelopmentData() {
  // Create 1000 test users
  const users = Array.from({ length: 1000 }).map((_, i) => ({
    email: `user${i}@example.com`,
    name: `User ${i}`,
  }));

  await prisma.user.createMany({
    data: users,
  });
}

async function seedProductionData() {
  // Create only admin user
  await prisma.user.create({
    data: {
      email: 'admin@example.com',
      name: 'Admin',
      role: 'ADMIN',
    },
  });
}
```

## Team Collaboration

### Migration Conflicts

**Scenario**: Two developers create migrations simultaneously

```
Developer A:
20231116100000_add_user_role/migration.sql

Developer B (same time):
20231116100000_add_user_status/migration.sql
```

**Resolution:**

```bash
# Developer B pulls A's changes
git pull

# Recreate B's migration with new timestamp
npx prisma migrate dev --create-only --name add_user_status

# New migration:
# 20231116103000_add_user_status/migration.sql

# Apply and commit
npx prisma migrate dev
git add .
git commit -m "Add user status migration"
git push
```

### Migration Guidelines

1. **Pull before migrate**: Always pull latest changes first
2. **One migration per feature**: Keep migrations focused
3. **Commit migrations**: Always commit migration files
4. **Test migrations**: Verify on staging before production
5. **Never edit applied migrations**: Create new migration instead

### Handling Schema Drift

**Schema drift**: Database schema differs from migration history

```bash
# Detect drift
npx prisma migrate status

# Resolve drift
# Option 1: Reset database (development only!)
npx prisma migrate reset

# Option 2: Create baseline migration
npx prisma migrate dev --create-only --name baseline
# Edit migration to match current database state
npx prisma migrate dev

# Option 3: Manually sync database
# Use prisma db push (prototyping only, not recommended)
npx prisma db push
```

## Migration Best Practices

### 1. Descriptive Migration Names

```bash
# ✅ GOOD - Clear and descriptive
npx prisma migrate dev --name add_user_email_verification
npx prisma migrate dev --name create_order_items_table
npx prisma migrate dev --name add_index_posts_published_date

# ❌ AVOID - Vague names
npx prisma migrate dev --name update
npx prisma migrate dev --name fix
npx prisma migrate dev --name changes
```

### 2. Small, Focused Migrations

```bash
# ✅ GOOD - One change per migration
npx prisma migrate dev --name add_user_avatar
npx prisma migrate dev --name add_user_bio

# ❌ AVOID - Too many changes
npx prisma migrate dev --name update_user_model_and_add_posts_and_comments
```

### 3. Test Before Deploying

```bash
# Test migration on staging
# 1. Create database backup
pg_dump production_db > backup.sql

# 2. Restore to staging
psql staging_db < backup.sql

# 3. Run migrations on staging
npx prisma migrate deploy

# 4. Verify application works

# 5. Deploy to production
```

### 4. Rollback Strategy

```sql
-- migration.sql (with rollback instructions)

-- UP Migration
ALTER TABLE "User" ADD COLUMN "verified" BOOLEAN DEFAULT false;

-- To rollback manually:
-- ALTER TABLE "User" DROP COLUMN "verified";
```

### 5. Performance Considerations

```sql
-- ✅ GOOD - Non-blocking index creation (PostgreSQL)
CREATE INDEX CONCURRENTLY "idx_user_email" ON "User"("email");

-- ✅ GOOD - Add nullable column, backfill, then set NOT NULL
ALTER TABLE "User" ADD COLUMN "role" TEXT;
UPDATE "User" SET "role" = 'USER' WHERE "role" IS NULL;
ALTER TABLE "User" ALTER COLUMN "role" SET NOT NULL;

-- ❌ AVOID - Blocking operations on large tables
ALTER TABLE "User" ADD COLUMN "role" TEXT NOT NULL DEFAULT 'USER';
-- This locks the entire table during migration
```

## Common Migration Scenarios

### Renaming a Column

```prisma
// schema.prisma
model User {
  id       Int    @id @default(autoincrement())
  // username String  // Old
  userName String  @map("user_name")  // New
}
```

```sql
-- migration.sql
ALTER TABLE "User" RENAME COLUMN "username" TO "user_name";
```

### Renaming a Table

```prisma
// schema.prisma
model User {
  id Int @id @default(autoincrement())

  @@map("users")  // Map to "users" table
}
```

```bash
npx prisma migrate dev --create-only --name rename_user_table
```

```sql
-- migration.sql
ALTER TABLE "User" RENAME TO "users";
```

### Adding Required Field to Existing Table

```prisma
model User {
  id       Int    @id @default(autoincrement())
  email    String @unique
  name     String
  role     String @default("USER")  // New required field
}
```

```sql
-- migration.sql
-- Add column as nullable first
ALTER TABLE "User" ADD COLUMN "role" TEXT;

-- Backfill with default value
UPDATE "User" SET "role" = 'USER' WHERE "role" IS NULL;

-- Make column required
ALTER TABLE "User" ALTER COLUMN "role" SET NOT NULL;

-- Set default for new rows
ALTER TABLE "User" ALTER COLUMN "role" SET DEFAULT 'USER';
```

### Changing Column Type

```prisma
model Post {
  id    Int    @id @default(autoincrement())
  // views Int  // Old: integer
  views BigInt  // New: bigint
}
```

```sql
-- migration.sql
ALTER TABLE "Post" ALTER COLUMN "views" TYPE BIGINT;
```

## Troubleshooting

### Migration Fails

```bash
# Error: migration already applied
npx prisma migrate resolve --applied 20231116100000_migration_name

# Error: migration failed midway
npx prisma migrate resolve --rolled-back 20231116100000_migration_name

# Then fix and rerun
npx prisma migrate dev
```

### Database Out of Sync

```bash
# Check status
npx prisma migrate status

# Reset database (development only!)
npx prisma migrate reset

# Or create baseline
npx prisma migrate dev --create-only --name baseline
```

### Prisma Client Out of Sync

```bash
# Regenerate Prisma Client
npx prisma generate

# Or with migration
npx prisma migrate dev
```

## AI Pair Programming Notes

**When working with Prisma migrations:**

1. **Always use descriptive names**: Migration names should explain what changed
2. **Test locally first**: Run migrations in development before production
3. **Commit migration files**: Migrations are part of your codebase
4. **Use migrate deploy in production**: Never use migrate dev in production
5. **Create baseline for existing databases**: Use --create-only and edit migration
6. **Handle data migrations carefully**: Test backfill scripts thoroughly
7. **Use CONCURRENTLY for indexes**: Avoid locking large tables (PostgreSQL)
8. **Never edit applied migrations**: Create new migration for changes
9. **Seed intelligently**: Different data for development vs production
10. **Monitor migration status**: Use prisma migrate status in CI/CD

**Common migration mistakes to catch:**
- Editing applied migrations instead of creating new ones
- Using migrate dev in production
- Not testing migrations before deploying
- Forgetting to commit migration files
- Not handling data migrations for required fields
- Creating blocking migrations on large tables
- Not resolving migration conflicts
- Skipping migration status checks
- Missing rollback documentation
- Not using transactions for multi-step data migrations

## Next Steps

1. **06-TRANSACTIONS.md** - Managing complex operations with transactions
2. **07-PERFORMANCE.md** - Optimizing database performance
3. **11-CONFIG-OPERATIONS.md** - Production configuration and operations

## Additional Resources

- Prisma Migrate: https://www.prisma.io/docs/concepts/components/prisma-migrate
- Migration Flows: https://www.prisma.io/docs/concepts/components/prisma-migrate/migration-flows
- Seeding: https://www.prisma.io/docs/guides/database/seed-database
- Deployment: https://www.prisma.io/docs/guides/deployment/deploy-database-changes-with-prisma-migrate
