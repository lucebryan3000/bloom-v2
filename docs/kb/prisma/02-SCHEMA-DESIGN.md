# Prisma Schema Design

```yaml
id: prisma_02_schema_design
topic: Prisma
file_role: Schema definition, model design, and database structure
profile: intermediate
difficulty_level: intermediate
kb_version: v3.1
prerequisites:
  - Fundamentals (01-FUNDAMENTALS.md)
related_topics:
  - Relations (04-RELATIONS.md)
  - Migrations (05-MIGRATIONS.md)
  - TypeScript (../typescript/)
embedding_keywords:
  - prisma schema
  - model definition
  - field types
  - schema.prisma
  - datasource
  - generator
  - enums
  - indexes
  - constraints
  - composite types
last_reviewed: 2025-11-16
```

## Schema File Structure

The `schema.prisma` file is the single source of truth for your database schema.

```prisma
// schema.prisma - Basic structure

// Data source configuration
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

// Client generator configuration
generator client {
  provider = "prisma-client-js"
}

// Model definitions
model User {
  id    Int     @id @default(autoincrement())
  email String  @unique
  name  String?
  posts Post[]
}

model Post {
  id        Int      @id @default(autoincrement())
  title     String
  content   String?
  published Boolean  @default(false)
  author    User     @relation(fields: [authorId], references: [id])
  authorId  Int
}
```

## Data Source Configuration

### Supported Database Providers

```prisma
// PostgreSQL
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

// MySQL
datasource db {
  provider = "mysql"
  url      = env("DATABASE_URL")
}

// SQLite
datasource db {
  provider = "sqlite"
  url      = "file:./dev.db"
}

// SQL Server
datasource db {
  provider = "sqlserver"
  url      = env("DATABASE_URL")
}

// MongoDB
datasource db {
  provider = "mongodb"
  url      = env("DATABASE_URL")
}

// CockroachDB
datasource db {
  provider = "cockroachdb"
  url      = env("DATABASE_URL")
}
```

### Connection URL Formats

```bash
# PostgreSQL
DATABASE_URL="postgresql://USER:PASSWORD@HOST:PORT/DATABASE?schema=public"

# MySQL
DATABASE_URL="mysql://USER:PASSWORD@HOST:PORT/DATABASE"

# SQLite
DATABASE_URL="file:./dev.db"

# SQL Server
DATABASE_URL="sqlserver://HOST:PORT;database=DATABASE;user=USER;password=PASSWORD"

# MongoDB
DATABASE_URL="mongodb+srv://USER:PASSWORD@HOST/DATABASE"
```

### Advanced Data Source Options

```prisma
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")

  // Use shadow database for migrations
  shadowDatabaseUrl = env("SHADOW_DATABASE_URL")

  // Direct URL for migrations (bypasses connection pooling)
  directUrl = env("DIRECT_DATABASE_URL")
}
```

## Generator Configuration

### Prisma Client Generator

```prisma
generator client {
  provider = "prisma-client-js"

  // Output directory (default: node_modules/.prisma/client)
  output   = "../src/generated/prisma-client"

  // Preview features
  previewFeatures = ["fullTextSearch", "fullTextIndex"]

  // Binary targets for deployment
  binaryTargets = ["native", "linux-musl"]

  // Engine type
  engineType = "binary"
}
```

### Multiple Generators

```prisma
generator client {
  provider = "prisma-client-js"
}

generator dbml {
  provider = "prisma-dbml-generator"
}

generator docs {
  provider = "node node_modules/prisma-docs-generator"
}

generator erd {
  provider = "prisma-erd-generator"
  output   = "../ERD.svg"
}
```

## Field Types

### Scalar Types

```prisma
model Example {
  // String types
  id          String   @id @default(uuid())
  email       String
  name        String?   // Optional field
  bio         String   @db.Text  // Large text

  // Numeric types
  age         Int
  price       Float
  stock       BigInt
  rating      Decimal

  // Boolean
  isActive    Boolean  @default(true)

  // Date and time
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt
  birthDate   DateTime @db.Date

  // Binary data
  avatar      Bytes

  // JSON (PostgreSQL, MySQL, CockroachDB)
  metadata    Json
}
```

### Database-Specific Type Mapping

```prisma
model DatabaseTypes {
  // PostgreSQL specific
  id          String   @id @default(uuid()) @db.Uuid
  name        String   @db.VarChar(255)
  bio         String   @db.Text
  price       Decimal  @db.Decimal(10, 2)
  tags        String[] @db.VarChar(50)
  metadata    Json     @db.JsonB

  // MySQL specific
  status      String   @db.VarChar(20)
  description String   @db.MediumText

  // SQL Server specific
  code        String   @db.NVarChar(100)

  createdAt   DateTime @default(now())
}
```

## Field Attributes

### ID Fields

```prisma
model User {
  // Auto-increment integer ID
  id Int @id @default(autoincrement())
}

model Post {
  // UUID
  id String @id @default(uuid())
}

model Product {
  // CUID (Collision-resistant unique ID)
  id String @id @default(cuid())
}

model Article {
  // Composite ID
  authorId Int
  slug     String

  @@id([authorId, slug])
}

model Session {
  // Custom generated ID
  id String @id @default(dbgenerated("gen_random_uuid()"))
}
```

### Unique Constraints

```prisma
model User {
  id       Int    @id @default(autoincrement())
  email    String @unique
  username String @unique

  // Composite unique constraint
  firstName String
  lastName  String

  @@unique([firstName, lastName])
}

model Product {
  id  Int    @id @default(autoincrement())
  sku String @unique(map: "product_sku_unique")
}
```

### Default Values

```prisma
model Post {
  id          Int      @id @default(autoincrement())
  title       String
  published   Boolean  @default(false)
  viewCount   Int      @default(0)
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt

  // Database-level default
  status      String   @default(dbgenerated("'draft'::text"))

  // UUID default
  uuid        String   @default(uuid())

  // CUID default
  cuid        String   @default(cuid())
}
```

### Updated At Timestamp

```prisma
model User {
  id        Int      @id @default(autoincrement())
  email     String
  updatedAt DateTime @updatedAt  // Auto-updated on every change
}
```

## Enums

```prisma
enum Role {
  USER
  ADMIN
  MODERATOR
}

enum Status {
  DRAFT
  PUBLISHED
  ARCHIVED
}

model User {
  id    Int    @id @default(autoincrement())
  email String @unique
  role  Role   @default(USER)
}

model Post {
  id     Int    @id @default(autoincrement())
  title  String
  status Status @default(DRAFT)
}

// Database enum with custom values (PostgreSQL)
enum Priority {
  LOW    @map("low")
  MEDIUM @map("medium")
  HIGH   @map("high")
}
```

## Indexes

### Single Field Indexes

```prisma
model User {
  id       Int    @id @default(autoincrement())
  email    String @unique
  username String

  // Regular index
  @@index([username])
}
```

### Composite Indexes

```prisma
model Post {
  id        Int      @id @default(autoincrement())
  authorId  Int
  published Boolean
  createdAt DateTime @default(now())

  // Composite index
  @@index([authorId, published])

  // Index with sort order
  @@index([createdAt(sort: Desc)])
}
```

### Named Indexes

```prisma
model Product {
  id       Int    @id @default(autoincrement())
  sku      String
  category String

  @@index([sku, category], name: "product_sku_category_idx")
}
```

### Full-Text Search Indexes (PostgreSQL)

```prisma
generator client {
  provider        = "prisma-client-js"
  previewFeatures = ["fullTextSearch", "fullTextIndex"]
}

model Post {
  id      Int    @id @default(autoincrement())
  title   String
  content String

  @@fulltext([title, content])
}
```

### Unique Indexes

```prisma
model User {
  id        Int    @id @default(autoincrement())
  email     String
  username  String

  @@unique([email, username], name: "unique_email_username")
}
```

## Model Attributes

### Table Naming

```prisma
model User {
  id Int @id @default(autoincrement())

  @@map("users")  // Map to "users" table
}

model BlogPost {
  id Int @id @default(autoincrement())

  @@map("blog_posts")
}
```

### Schema Mapping (PostgreSQL)

```prisma
model User {
  id Int @id @default(autoincrement())

  @@schema("auth")  // Use "auth" schema
}

model Post {
  id Int @id @default(autoincrement())

  @@schema("content")  // Use "content" schema
}
```

### Ignore Models

```prisma
model LegacyTable {
  id Int @id

  @@ignore  // Skip in Prisma Client generation
}
```

## Composite Types (MongoDB)

```prisma
type Address {
  street  String
  city    String
  state   String
  zipCode String
}

model User {
  id      String  @id @default(auto()) @map("_id") @db.ObjectId
  email   String  @unique
  address Address
}
```

## Multi-Schema Support

```prisma
// schema.prisma
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
  schemas  = ["auth", "public"]
}

generator client {
  provider        = "prisma-client-js"
  previewFeatures = ["multiSchema"]
}

model User {
  id       Int    @id @default(autoincrement())
  email    String @unique

  @@schema("auth")
}

model Post {
  id       Int    @id @default(autoincrement())
  title    String
  authorId Int

  @@schema("public")
}
```

## Schema Design Best Practices

### 1. Naming Conventions

```prisma
// ✅ GOOD - Consistent naming
model User {
  id        Int      @id @default(autoincrement())
  firstName String   @map("first_name")  // snake_case in DB
  lastName  String   @map("last_name")
  createdAt DateTime @default(now()) @map("created_at")

  @@map("users")
}

// ❌ AVOID - Inconsistent naming
model user {
  ID        Int      @id @default(autoincrement())
  FirstName String
  last_name String
  CreatedAt DateTime @default(now())
}
```

### 2. Required vs Optional Fields

```prisma
model User {
  id          Int      @id @default(autoincrement())
  email       String   @unique         // Required
  name        String?                  // Optional
  phoneNumber String?                  // Optional
  bio         String?  @db.Text        // Optional, large text
  createdAt   DateTime @default(now()) // Required with default
}
```

### 3. Timestamp Fields

```prisma
model Post {
  id        Int      @id @default(autoincrement())
  title     String
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  // Optional: soft delete
  deletedAt DateTime?
}
```

### 4. Enums for Status Fields

```prisma
enum OrderStatus {
  PENDING
  PROCESSING
  SHIPPED
  DELIVERED
  CANCELLED
}

model Order {
  id     Int         @id @default(autoincrement())
  status OrderStatus @default(PENDING)
}
```

### 5. JSON for Flexible Data

```prisma
model Product {
  id       Int    @id @default(autoincrement())
  name     String

  // Flexible metadata as JSON
  metadata Json?  @db.JsonB  // PostgreSQL: use JSONB for better performance

  // Structured data with specific fields
  options  Json?  // e.g., { "color": "red", "size": "large" }
}
```

### 6. Indexes for Performance

```prisma
model User {
  id        Int      @id @default(autoincrement())
  email     String   @unique
  username  String
  status    String
  createdAt DateTime @default(now())

  // Index frequently queried fields
  @@index([username])
  @@index([status])
  @@index([createdAt(sort: Desc)])
}
```

### 7. Composite Indexes for Multi-Column Queries

```prisma
model Post {
  id        Int      @id @default(autoincrement())
  authorId  Int
  published Boolean  @default(false)
  createdAt DateTime @default(now())

  // Optimize for: "Get all published posts by author"
  @@index([authorId, published])

  // Optimize for: "Get recent posts"
  @@index([createdAt(sort: Desc)])
}
```

## Real-World Schema Examples

### E-Commerce Schema

```prisma
enum OrderStatus {
  PENDING
  PAID
  SHIPPED
  DELIVERED
  CANCELLED
  REFUNDED
}

model User {
  id        String   @id @default(cuid())
  email     String   @unique
  name      String
  password  String
  orders    Order[]
  cart      Cart?
  addresses Address[]
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  @@map("users")
}

model Product {
  id          String      @id @default(cuid())
  sku         String      @unique
  name        String
  description String?     @db.Text
  price       Decimal     @db.Decimal(10, 2)
  stock       Int         @default(0)
  images      String[]
  category    Category    @relation(fields: [categoryId], references: [id])
  categoryId  String
  cartItems   CartItem[]
  orderItems  OrderItem[]
  createdAt   DateTime    @default(now())
  updatedAt   DateTime    @updatedAt

  @@index([categoryId])
  @@index([sku])
  @@map("products")
}

model Category {
  id       String    @id @default(cuid())
  name     String    @unique
  slug     String    @unique
  products Product[]

  @@map("categories")
}

model Cart {
  id        String     @id @default(cuid())
  user      User       @relation(fields: [userId], references: [id])
  userId    String     @unique
  items     CartItem[]
  createdAt DateTime   @default(now())
  updatedAt DateTime   @updatedAt

  @@map("carts")
}

model CartItem {
  id        String   @id @default(cuid())
  cart      Cart     @relation(fields: [cartId], references: [id], onDelete: Cascade)
  cartId    String
  product   Product  @relation(fields: [productId], references: [id])
  productId String
  quantity  Int      @default(1)

  @@unique([cartId, productId])
  @@map("cart_items")
}

model Order {
  id         String      @id @default(cuid())
  orderNumber String     @unique @default(cuid())
  user       User        @relation(fields: [userId], references: [id])
  userId     String
  status     OrderStatus @default(PENDING)
  total      Decimal     @db.Decimal(10, 2)
  items      OrderItem[]
  shippingAddress Address @relation(fields: [addressId], references: [id])
  addressId  String
  createdAt  DateTime    @default(now())
  updatedAt  DateTime    @updatedAt

  @@index([userId])
  @@index([status])
  @@index([createdAt(sort: Desc)])
  @@map("orders")
}

model OrderItem {
  id        String  @id @default(cuid())
  order     Order   @relation(fields: [orderId], references: [id], onDelete: Cascade)
  orderId   String
  product   Product @relation(fields: [productId], references: [id])
  productId String
  quantity  Int
  price     Decimal @db.Decimal(10, 2)

  @@map("order_items")
}

model Address {
  id         String   @id @default(cuid())
  user       User     @relation(fields: [userId], references: [id])
  userId     String
  street     String
  city       String
  state      String
  zipCode    String
  country    String   @default("US")
  isDefault  Boolean  @default(false)
  orders     Order[]

  @@map("addresses")
}
```

### SaaS Application Schema

```prisma
enum SubscriptionStatus {
  ACTIVE
  PAST_DUE
  CANCELLED
  TRIALING
}

model Organization {
  id           String        @id @default(cuid())
  name         String
  slug         String        @unique
  members      Member[]
  projects     Project[]
  subscription Subscription?
  createdAt    DateTime      @default(now())

  @@map("organizations")
}

model User {
  id        String   @id @default(cuid())
  email     String   @unique
  name      String
  avatar    String?
  members   Member[]
  createdAt DateTime @default(now())

  @@map("users")
}

model Member {
  id             String       @id @default(cuid())
  user           User         @relation(fields: [userId], references: [id])
  userId         String
  organization   Organization @relation(fields: [organizationId], references: [id], onDelete: Cascade)
  organizationId String
  role           String       @default("member")
  invitedAt      DateTime     @default(now())

  @@unique([userId, organizationId])
  @@map("members")
}

model Project {
  id             String       @id @default(cuid())
  name           String
  description    String?      @db.Text
  organization   Organization @relation(fields: [organizationId], references: [id], onDelete: Cascade)
  organizationId String
  tasks          Task[]
  createdAt      DateTime     @default(now())

  @@index([organizationId])
  @@map("projects")
}

model Task {
  id          String   @id @default(cuid())
  title       String
  description String?  @db.Text
  status      String   @default("todo")
  priority    String   @default("medium")
  project     Project  @relation(fields: [projectId], references: [id], onDelete: Cascade)
  projectId   String
  dueDate     DateTime?
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt

  @@index([projectId])
  @@index([status])
  @@map("tasks")
}

model Subscription {
  id             String             @id @default(cuid())
  organization   Organization       @relation(fields: [organizationId], references: [id], onDelete: Cascade)
  organizationId String             @unique
  status         SubscriptionStatus @default(TRIALING)
  planId         String
  currentPeriodStart DateTime
  currentPeriodEnd   DateTime
  cancelAt       DateTime?
  createdAt      DateTime           @default(now())

  @@map("subscriptions")
}
```

## AI Pair Programming Notes

**When designing Prisma schemas:**

1. **Start with data source configuration**: Choose provider and connection URL
2. **Define core models first**: User, Product, Order, etc.
3. **Add relationships**: Use `@relation` to connect models
4. **Use enums for status fields**: Better type safety than strings
5. **Add indexes strategically**: Based on query patterns
6. **Use `@map` for naming**: Keep Prisma models PascalCase, database snake_case
7. **Add timestamps**: `createdAt` and `updatedAt` for all models
8. **Use appropriate field types**: Match database capabilities (e.g., `@db.JsonB` for PostgreSQL)
9. **Add constraints**: `@unique`, `@@unique`, `@@id` for data integrity
10. **Plan for soft deletes**: Use `deletedAt DateTime?` if needed

**Common schema design mistakes to catch:**
- Missing indexes on foreign keys
- Not using `@updatedAt` for automatic updates
- Inconsistent naming conventions
- Using strings for status instead of enums
- Missing `onDelete` cascade behavior
- Not mapping Prisma names to database names with `@map`
- Forgetting to add `previewFeatures` when using new features
- Not using database-specific types (e.g., `@db.JsonB`, `@db.Text`)

## Next Steps

1. **04-RELATIONS.md** - Understanding Prisma relations and associations
2. **05-MIGRATIONS.md** - Schema migrations and version control
3. **03-CLIENT-API.md** - Working with generated Prisma Client

## Additional Resources

- Prisma Schema Reference: https://www.prisma.io/docs/reference/api-reference/prisma-schema-reference
- Data Model Documentation: https://www.prisma.io/docs/concepts/components/prisma-schema/data-model
- Database Connectors: https://www.prisma.io/docs/concepts/database-connectors
- Schema Best Practices: https://www.prisma.io/dataguide/types/relational/what-is-a-database-schema
