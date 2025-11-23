# Prisma Relations

```yaml
id: prisma_04_relations
topic: Prisma
file_role: Data modeling, relations, and associations between models
profile: intermediate
difficulty_level: intermediate
kb_version: v3.1
prerequisites:
  - Fundamentals (01-FUNDAMENTALS.md)
  - Schema Design (02-SCHEMA-DESIGN.md)
  - Client API (03-CLIENT-API.md)
related_topics:
  - Schema Design (02-SCHEMA-DESIGN.md)
  - Migrations (05-MIGRATIONS.md)
  - TypeScript (../typescript/)
embedding_keywords:
  - prisma relations
  - one-to-one
  - one-to-many
  - many-to-many
  - foreign keys
  - @relation
  - referential actions
  - self-relations
  - implicit relations
  - explicit relations
last_reviewed: 2025-11-16
```

## Relation Types Overview

Prisma supports three types of relations:

| Relation Type | Schema Example | Use Case |
|---------------|----------------|----------|
| **One-to-One** | User ↔ Profile | Each user has exactly one profile |
| **One-to-Many** | User → Posts | Each user has many posts |
| **Many-to-Many** | Posts ↔ Categories | Each post can have many categories, each category can have many posts |

## One-to-One Relations

### Basic One-to-One

```prisma
model User {
  id      Int      @id @default(autoincrement())
  email   String   @unique
  profile Profile?
}

model Profile {
  id     Int    @id @default(autoincrement())
  bio    String
  user   User   @relation(fields: [userId], references: [id])
  userId Int    @unique
}
```

**Key points:**
- `Profile` has foreign key field `userId` referencing `User.id`
- `userId` must be `@unique` for one-to-one relationship
- `User.profile` is optional (`Profile?`) because user might not have a profile
- `Profile.user` is required because every profile must belong to a user

### One-to-One with Deletion Cascade

```prisma
model User {
  id      Int      @id @default(autoincrement())
  email   String   @unique
  profile Profile?
}

model Profile {
  id     Int    @id @default(autoincrement())
  bio    String
  user   User   @relation(fields: [userId], references: [id], onDelete: Cascade)
  userId Int    @unique
}
```

**Referential actions:**
- `Cascade`: Delete profile when user is deleted
- `SetNull`: Set `userId` to `null` when user is deleted
- `Restrict`: Prevent user deletion if profile exists (default)
- `NoAction`: Similar to Restrict (database-level enforcement)
- `SetDefault`: Set to default value

### Creating One-to-One Relations

```typescript
// Create user with profile
const user = await prisma.user.create({
  data: {
    email: 'alice@example.com',
    profile: {
      create: {
        bio: 'Hello, I am Alice!',
      },
    },
  },
  include: {
    profile: true,
  },
});

// Create profile for existing user
const profile = await prisma.profile.create({
  data: {
    bio: 'My bio',
    userId: 1,
  },
});

// Or using nested write
const user = await prisma.user.update({
  where: { id: 1 },
  data: {
    profile: {
      create: {
        bio: 'My bio',
      },
    },
  },
});
```

## One-to-Many Relations

### Basic One-to-Many

```prisma
model User {
  id    Int    @id @default(autoincrement())
  email String @unique
  posts Post[]
}

model Post {
  id       Int    @id @default(autoincrement())
  title    String
  author   User   @relation(fields: [authorId], references: [id])
  authorId Int
}
```

**Key points:**
- `Post` has foreign key field `authorId` referencing `User.id`
- `authorId` is NOT unique (multiple posts can have same author)
- `User.posts` is an array (`Post[]`)
- Each post has exactly one author (`User`)

### One-to-Many with Referential Actions

```prisma
model User {
  id    Int    @id @default(autoincrement())
  email String @unique
  posts Post[]
}

model Post {
  id        Int     @id @default(autoincrement())
  title     String
  published Boolean @default(false)
  author    User    @relation(fields: [authorId], references: [id], onDelete: Cascade)
  authorId  Int
}
```

### Creating One-to-Many Relations

```typescript
// Create user with posts
const user = await prisma.user.create({
  data: {
    email: 'alice@example.com',
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

// Add post to existing user
const post = await prisma.post.create({
  data: {
    title: 'My post',
    authorId: 1,
  },
});

// Or using connect
const user = await prisma.user.update({
  where: { id: 1 },
  data: {
    posts: {
      create: { title: 'New post' },
    },
  },
});

// Querying with relations
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
    },
  },
});
```

## Many-to-Many Relations

### Implicit Many-to-Many

Prisma creates join table automatically.

```prisma
model Post {
  id         Int        @id @default(autoincrement())
  title      String
  categories Category[]
}

model Category {
  id    Int    @id @default(autoincrement())
  name  String @unique
  posts Post[]
}
```

**Generated join table:**
- Prisma creates `_CategoryToPost` table automatically
- No explicit join model needed
- Simpler schema

### Explicit Many-to-Many

Full control over join table with additional fields.

```prisma
model Post {
  id               Int               @id @default(autoincrement())
  title            String
  postCategories   PostCategory[]
}

model Category {
  id               Int               @id @default(autoincrement())
  name             String            @unique
  postCategories   PostCategory[]
}

model PostCategory {
  post       Post     @relation(fields: [postId], references: [id], onDelete: Cascade)
  postId     Int
  category   Category @relation(fields: [categoryId], references: [id], onDelete: Cascade)
  categoryId Int
  assignedAt DateTime @default(now())

  @@id([postId, categoryId])
}
```

**Advantages of explicit:**
- Add extra fields (timestamps, metadata)
- Custom referential actions
- Better performance control
- Query join table directly

### Creating Many-to-Many Relations (Implicit)

```typescript
// Create post with categories
const post = await prisma.post.create({
  data: {
    title: 'My post',
    categories: {
      create: [
        { name: 'Technology' },
        { name: 'Programming' },
      ],
    },
  },
  include: {
    categories: true,
  },
});

// Connect existing categories
const post = await prisma.post.create({
  data: {
    title: 'My post',
    categories: {
      connect: [
        { id: 1 },
        { id: 2 },
      ],
    },
  },
});

// Create or connect
const post = await prisma.post.create({
  data: {
    title: 'My post',
    categories: {
      connectOrCreate: [
        {
          where: { name: 'Technology' },
          create: { name: 'Technology' },
        },
      ],
    },
  },
});
```

### Creating Many-to-Many Relations (Explicit)

```typescript
// Create post with categories (explicit join)
const post = await prisma.post.create({
  data: {
    title: 'My post',
    postCategories: {
      create: [
        {
          category: {
            connect: { id: 1 },
          },
        },
        {
          category: {
            connect: { id: 2 },
          },
        },
      ],
    },
  },
  include: {
    postCategories: {
      include: {
        category: true,
      },
    },
  },
});

// Query with join table data
const posts = await prisma.post.findMany({
  include: {
    postCategories: {
      include: {
        category: true,
      },
      orderBy: {
        assignedAt: 'desc',
      },
    },
  },
});
```

## Self-Relations

### One-to-Many Self-Relation

```prisma
model User {
  id         Int    @id @default(autoincrement())
  email      String @unique
  referrer   User?  @relation("UserReferrals", fields: [referrerId], references: [id])
  referrerId Int?
  referrals  User[] @relation("UserReferrals")
}
```

**Use cases:**
- Referral systems
- Organizational hierarchies
- Comment threads

```typescript
// Create user with referrer
const user = await prisma.user.create({
  data: {
    email: 'bob@example.com',
    referrerId: 1, // Referred by user 1
  },
});

// Get user with referrals
const user = await prisma.user.findUnique({
  where: { id: 1 },
  include: {
    referrals: true, // Users referred by this user
  },
});
```

### Many-to-Many Self-Relation

```prisma
model User {
  id         Int    @id @default(autoincrement())
  email      String @unique
  following  User[] @relation("UserFollows")
  followers  User[] @relation("UserFollows")
}
```

**Use cases:**
- Social networks (followers/following)
- Collaboration networks

```typescript
// Follow a user
const user = await prisma.user.update({
  where: { id: 1 },
  data: {
    following: {
      connect: { id: 2 },
    },
  },
});

// Get followers and following
const user = await prisma.user.findUnique({
  where: { id: 1 },
  include: {
    followers: true,
    following: true,
  },
});
```

## Named Relations

When multiple relations exist between two models, use named relations.

```prisma
model User {
  id            Int    @id @default(autoincrement())
  email         String @unique
  writtenPosts  Post[] @relation("WrittenPosts")
  favoritePosts Post[] @relation("FavoritePosts")
}

model Post {
  id               Int    @id @default(autoincrement())
  title            String
  author           User   @relation("WrittenPosts", fields: [authorId], references: [id])
  authorId         Int
  favoritedBy      User[] @relation("FavoritePosts")
}
```

```typescript
// Query with named relations
const user = await prisma.user.findUnique({
  where: { id: 1 },
  include: {
    writtenPosts: true,
    favoritePosts: true,
  },
});
```

## Referential Actions

Control what happens when referenced record is deleted or updated.

```prisma
model User {
  id    Int    @id @default(autoincrement())
  email String @unique
  posts Post[]
}

model Post {
  id       Int    @id @default(autoincrement())
  title    String
  author   User   @relation(fields: [authorId], references: [id], onDelete: Cascade, onUpdate: Cascade)
  authorId Int
}
```

### OnDelete Actions

```prisma
// Cascade: Delete all posts when user is deleted
onDelete: Cascade

// SetNull: Set authorId to null when user is deleted
// (requires authorId to be optional: authorId Int?)
onDelete: SetNull

// SetDefault: Set authorId to default value when user is deleted
// (requires default value: authorId Int @default(1))
onDelete: SetDefault

// Restrict: Prevent user deletion if posts exist (default)
onDelete: Restrict

// NoAction: Database handles action (similar to Restrict)
onDelete: NoAction
```

### OnUpdate Actions

```prisma
// Cascade: Update authorId when user id changes
onUpdate: Cascade

// SetNull: Set authorId to null when user id changes
onUpdate: SetNull

// SetDefault: Set authorId to default when user id changes
onUpdate: SetDefault

// Restrict: Prevent user id change if posts exist
onUpdate: Restrict

// NoAction: Database handles action
onUpdate: NoAction
```

## Relation Queries

### Include Relations

```typescript
// Include single relation
const user = await prisma.user.findUnique({
  where: { id: 1 },
  include: {
    profile: true,
  },
});

// Include multiple relations
const user = await prisma.user.findUnique({
  where: { id: 1 },
  include: {
    profile: true,
    posts: true,
  },
});

// Nested include
const user = await prisma.user.findUnique({
  where: { id: 1 },
  include: {
    posts: {
      include: {
        comments: true,
      },
    },
  },
});

// Include with filters
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

### Select with Relations

```typescript
// Select specific fields from relations
const user = await prisma.user.findUnique({
  where: { id: 1 },
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

### Count Relations

```typescript
// Count related records
const user = await prisma.user.findUnique({
  where: { id: 1 },
  include: {
    _count: {
      select: {
        posts: true,
      },
    },
  },
});

// Result: { id: 1, email: '...', _count: { posts: 5 } }

// Count with filter
const users = await prisma.user.findMany({
  include: {
    _count: {
      select: {
        posts: {
          where: {
            published: true,
          },
        },
      },
    },
  },
});
```

## Nested Writes

### Create with Nested Relations

```typescript
// Create user with profile and posts
const user = await prisma.user.create({
  data: {
    email: 'alice@example.com',
    profile: {
      create: {
        bio: 'Hello!',
      },
    },
    posts: {
      create: [
        { title: 'First post' },
        { title: 'Second post' },
      ],
    },
  },
});
```

### Update with Nested Relations

```typescript
// Update user and related data
const user = await prisma.user.update({
  where: { id: 1 },
  data: {
    posts: {
      // Create new posts
      create: [
        { title: 'New post 1' },
        { title: 'New post 2' },
      ],
      // Update existing posts
      update: [
        {
          where: { id: 5 },
          data: { title: 'Updated title' },
        },
      ],
      // Update many
      updateMany: {
        where: { published: false },
        data: { published: true },
      },
      // Delete specific posts
      delete: [
        { id: 3 },
        { id: 4 },
      ],
      // Delete many
      deleteMany: {
        where: {
          createdAt: {
            lt: new Date('2020-01-01'),
          },
        },
      },
    },
  },
});
```

### Connect and Disconnect

```typescript
// Connect existing records
const post = await prisma.post.update({
  where: { id: 1 },
  data: {
    categories: {
      connect: [
        { id: 1 },
        { id: 2 },
      ],
    },
  },
});

// Disconnect records
const post = await prisma.post.update({
  where: { id: 1 },
  data: {
    categories: {
      disconnect: [
        { id: 1 },
      ],
    },
  },
});

// Set (replace all existing connections)
const post = await prisma.post.update({
  where: { id: 1 },
  data: {
    categories: {
      set: [
        { id: 1 },
        { id: 2 },
        { id: 3 },
      ],
    },
  },
});
```

## Complex Relation Examples

### E-Commerce Order System

```prisma
model Customer {
  id      Int     @id @default(autoincrement())
  email   String  @unique
  name    String
  orders  Order[]
}

model Order {
  id         Int         @id @default(autoincrement())
  orderNumber String     @unique @default(cuid())
  customer   Customer   @relation(fields: [customerId], references: [id])
  customerId Int
  items      OrderItem[]
  total      Decimal     @db.Decimal(10, 2)
  createdAt  DateTime    @default(now())
}

model Product {
  id         Int         @id @default(autoincrement())
  sku        String      @unique
  name       String
  price      Decimal     @db.Decimal(10, 2)
  orderItems OrderItem[]
}

model OrderItem {
  id        Int     @id @default(autoincrement())
  order     Order   @relation(fields: [orderId], references: [id], onDelete: Cascade)
  orderId   Int
  product   Product @relation(fields: [productId], references: [id])
  productId Int
  quantity  Int
  price     Decimal @db.Decimal(10, 2)

  @@unique([orderId, productId])
}
```

```typescript
// Create order with items
const order = await prisma.order.create({
  data: {
    orderNumber: 'ORD-001',
    customerId: 1,
    total: 150.00,
    items: {
      create: [
        {
          productId: 1,
          quantity: 2,
          price: 50.00,
        },
        {
          productId: 2,
          quantity: 1,
          price: 50.00,
        },
      ],
    },
  },
  include: {
    items: {
      include: {
        product: true,
      },
    },
  },
});

// Get customer orders with items and products
const customer = await prisma.customer.findUnique({
  where: { id: 1 },
  include: {
    orders: {
      include: {
        items: {
          include: {
            product: true,
          },
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
    },
  },
});
```

### Blog with Comments and Tags

```prisma
model User {
  id       Int       @id @default(autoincrement())
  email    String    @unique
  name     String
  posts    Post[]
  comments Comment[]
}

model Post {
  id        Int       @id @default(autoincrement())
  title     String
  content   String    @db.Text
  published Boolean   @default(false)
  author    User      @relation(fields: [authorId], references: [id])
  authorId  Int
  comments  Comment[]
  tags      Tag[]
  createdAt DateTime  @default(now())
}

model Comment {
  id        Int      @id @default(autoincrement())
  content   String
  post      Post     @relation(fields: [postId], references: [id], onDelete: Cascade)
  postId    Int
  author    User     @relation(fields: [authorId], references: [id])
  authorId  Int
  createdAt DateTime @default(now())
}

model Tag {
  id    Int    @id @default(autoincrement())
  name  String @unique
  posts Post[]
}
```

```typescript
// Create post with comments and tags
const post = await prisma.post.create({
  data: {
    title: 'My blog post',
    content: 'Post content here...',
    authorId: 1,
    comments: {
      create: [
        {
          content: 'Great post!',
          authorId: 2,
        },
      ],
    },
    tags: {
      connectOrCreate: [
        {
          where: { name: 'technology' },
          create: { name: 'technology' },
        },
        {
          where: { name: 'programming' },
          create: { name: 'programming' },
        },
      ],
    },
  },
  include: {
    comments: {
      include: {
        author: true,
      },
    },
    tags: true,
  },
});

// Get posts with full relations
const posts = await prisma.post.findMany({
  where: {
    published: true,
  },
  include: {
    author: {
      select: {
        name: true,
        email: true,
      },
    },
    comments: {
      include: {
        author: {
          select: {
            name: true,
          },
        },
      },
      orderBy: {
        createdAt: 'asc',
      },
    },
    tags: true,
    _count: {
      select: {
        comments: true,
      },
    },
  },
  orderBy: {
    createdAt: 'desc',
  },
});
```

## Best Practices

### 1. Use Cascade for Dependent Data

```prisma
// ✅ GOOD - Comments should be deleted when post is deleted
model Comment {
  post   Post @relation(fields: [postId], references: [id], onDelete: Cascade)
  postId Int
}

// ❌ AVOID - Orphaned comments when post is deleted
model Comment {
  post   Post @relation(fields: [postId], references: [id])
  postId Int
}
```

### 2. Use SetNull for Optional Relations

```prisma
// ✅ GOOD - Articles can exist without categories
model Article {
  category   Category? @relation(fields: [categoryId], references: [id], onDelete: SetNull)
  categoryId Int?
}

// ❌ AVOID - Articles deleted when category is deleted
model Article {
  category   Category @relation(fields: [categoryId], references: [id], onDelete: Cascade)
  categoryId Int
}
```

### 3. Choose Implicit vs Explicit Many-to-Many Carefully

```prisma
// ✅ Use implicit for simple relations
model Post {
  tags Tag[]
}

model Tag {
  posts Post[]
}

// ✅ Use explicit when you need metadata
model PostTag {
  post       Post     @relation(fields: [postId], references: [id])
  postId     Int
  tag        Tag      @relation(fields: [tagId], references: [id])
  tagId      Int
  addedAt    DateTime @default(now())
  addedBy    Int

  @@id([postId, tagId])
}
```

### 4. Use Include for Related Data

```typescript
// ✅ GOOD - Fetch related data in single query
const user = await prisma.user.findUnique({
  where: { id: 1 },
  include: {
    posts: true,
  },
});

// ❌ AVOID - N+1 query problem
const user = await prisma.user.findUnique({ where: { id: 1 } });
const posts = await prisma.post.findMany({ where: { authorId: user.id } });
```

### 5. Use Select to Optimize Queries

```typescript
// ✅ GOOD - Fetch only needed fields
const user = await prisma.user.findUnique({
  where: { id: 1 },
  select: {
    email: true,
    posts: {
      select: {
        title: true,
      },
      take: 5,
    },
  },
});

// ❌ AVOID - Fetching all fields
const user = await prisma.user.findUnique({
  where: { id: 1 },
  include: {
    posts: true, // Fetches all post fields
  },
});
```

## AI Pair Programming Notes

**When working with Prisma relations:**

1. **Choose correct relation type**: One-to-one, one-to-many, or many-to-many
2. **Use referential actions**: Set `onDelete` and `onUpdate` appropriately
3. **Name relations for clarity**: Use `@relation("Name")` when multiple relations exist
4. **Use include for fetching**: Avoid N+1 queries by including relations
5. **Prefer explicit many-to-many**: When you need metadata on the relation
6. **Use cascade for dependent data**: Comments, order items should cascade delete
7. **Use SetNull for optional**: When related record can exist independently
8. **Count relations efficiently**: Use `_count` instead of fetching all records
9. **Filter nested relations**: Use where/orderBy in include
10. **Leverage nested writes**: Create/update related records atomically

**Common relation mistakes to catch:**
- Missing `@unique` on one-to-one foreign keys
- Not setting appropriate `onDelete` actions
- Using Restrict when Cascade is needed
- Creating N+1 queries instead of using include
- Not naming multiple relations between same models
- Fetching all fields when select would be more efficient
- Using implicit many-to-many when metadata is needed
- Missing indexes on foreign key fields
- Not using transactions for complex nested writes

## Next Steps

1. **05-MIGRATIONS.md** - Managing schema changes with Prisma Migrate
2. **06-TRANSACTIONS.md** - Advanced transaction patterns with relations
3. **07-PERFORMANCE.md** - Optimizing relation queries

## Additional Resources

- Prisma Relations: https://www.prisma.io/docs/concepts/components/prisma-schema/relations
- Referential Actions: https://www.prisma.io/docs/concepts/components/prisma-schema/relations/referential-actions
- Relation Queries: https://www.prisma.io/docs/concepts/components/prisma-client/relation-queries
- Many-to-Many: https://www.prisma.io/docs/concepts/components/prisma-schema/relations/many-to-many-relations
