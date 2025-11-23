# PostgreSQL Framework Integration Patterns

```yaml
id: postgresql_framework_integration
topic: PostgreSQL
file_role: Framework-specific integration patterns and best practices
profile: intermediate_to_advanced
difficulty_level: intermediate
kb_version: v3.1
prerequisites:
  - PostgreSQL Fundamentals (01-FUNDAMENTALS.md)
  - SQL Basics (02-SQL-BASICS.md)
related_topics:
  - Performance (07-PERFORMANCE.md)
  - Transactions (06-TRANSACTIONS.md)
embedding_keywords:
  - Node.js PostgreSQL
  - Python PostgreSQL
  - Prisma PostgreSQL
  - TypeORM
  - Sequelize
  - psycopg2
  - SQLAlchemy
  - connection pooling
  - framework integration
last_reviewed: 2025-11-16
```

## Node.js Integration

### node-postgres (pg)

**Installation:**

```bash
npm install pg
npm install --save-dev @types/pg  # TypeScript types
```

**Basic Connection:**

```javascript
const { Client } = require('pg');

const client = new Client({
  host: 'localhost',
  port: 5432,
  user: 'appuser',
  password: 'secret',
  database: 'myapp',
});

await client.connect();

const result = await client.query('SELECT * FROM users WHERE id = $1', [1]);
console.log(result.rows[0]);

await client.end();
```

**Connection Pool (Recommended):**

```javascript
const { Pool } = require('pg');

const pool = new Pool({
  host: 'localhost',
  port: 5432,
  user: 'appuser',
  password: 'secret',
  database: 'myapp',

  // Pool configuration
  max: 20,                      // Maximum pool size
  min: 5,                       // Minimum pool size
  idleTimeoutMillis: 30000,     // Close idle connections after 30s
  connectionTimeoutMillis: 2000, // Fail if can't connect in 2s
});

// Use pool for queries
const result = await pool.query('SELECT * FROM users WHERE id = $1', [1]);

// Pool automatically manages connections
// No need to call pool.end() in application code
```

**Transaction Pattern:**

```javascript
async function transferMoney(fromId, toId, amount) {
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    await client.query(
      'UPDATE accounts SET balance = balance - $1 WHERE id = $2',
      [amount, fromId]
    );

    await client.query(
      'UPDATE accounts SET balance = balance + $1 WHERE id = $2',
      [amount, toId]
    );

    await client.query('COMMIT');
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}
```

**TypeScript Types:**

```typescript
import { Pool, QueryResult, PoolClient } from 'pg';

interface User {
  id: number;
  username: string;
  email: string;
  created_at: Date;
}

const pool = new Pool({ /* config */ });

async function getUser(id: number): Promise<User | null> {
  const result: QueryResult<User> = await pool.query(
    'SELECT * FROM users WHERE id = $1',
    [id]
  );
  return result.rows[0] || null;
}

async function createUser(username: string, email: string): Promise<User> {
  const result: QueryResult<User> = await pool.query(
    'INSERT INTO users (username, email) VALUES ($1, $2) RETURNING *',
    [username, email]
  );
  return result.rows[0];
}
```

**Error Handling:**

```javascript
async function safeQuery() {
  try {
    const result = await pool.query('SELECT * FROM users');
    return result.rows;
  } catch (error) {
    if (error.code === '23505') {
      // Unique violation
      throw new Error('Username already exists');
    } else if (error.code === '23503') {
      // Foreign key violation
      throw new Error('Referenced record does not exist');
    } else if (error.code === '40P01') {
      // Deadlock detected
      // Retry logic here
      throw new Error('Deadlock detected, please retry');
    } else {
      throw error;
    }
  }
}
```

### Prisma ORM

**Installation:**

```bash
npm install prisma @prisma/client
npx prisma init
```

**Schema Definition (schema.prisma):**

```prisma
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

generator client {
  provider = "prisma-client-js"
}

model User {
  id        Int      @id @default(autoincrement())
  username  String   @unique @db.VarChar(50)
  email     String   @unique @db.VarChar(255)
  posts     Post[]
  createdAt DateTime @default(now()) @map("created_at")
  updatedAt DateTime @updatedAt @map("updated_at")

  @@map("users")
}

model Post {
  id        Int      @id @default(autoincrement())
  title     String   @db.VarChar(255)
  body      String?  @db.Text
  userId    Int      @map("user_id")
  user      User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  published Boolean  @default(false)
  createdAt DateTime @default(now()) @map("created_at")

  @@map("posts")
  @@index([userId])
}
```

**Usage:**

```typescript
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

// Create
const user = await prisma.user.create({
  data: {
    username: 'john',
    email: 'john@example.com',
  },
});

// Read
const users = await prisma.user.findMany({
  where: { email: { endsWith: '@gmail.com' } },
  include: { posts: true },
  orderBy: { createdAt: 'desc' },
  take: 10,
});

// Update
const updatedUser = await prisma.user.update({
  where: { id: 1 },
  data: { email: 'newemail@example.com' },
});

// Delete
await prisma.user.delete({
  where: { id: 1 },
});

// Transactions
await prisma.$transaction([
  prisma.user.create({ data: { username: 'alice', email: 'alice@example.com' } }),
  prisma.user.create({ data: { username: 'bob', email: 'bob@example.com' } }),
]);

// Interactive transactions
await prisma.$transaction(async (tx) => {
  await tx.accounts.update({
    where: { id: 1 },
    data: { balance: { decrement: 100 } },
  });

  await tx.accounts.update({
    where: { id: 2 },
    data: { balance: { increment: 100 } },
  });
});

// Raw SQL
const result = await prisma.$queryRaw`
  SELECT * FROM users WHERE email LIKE ${`%@gmail.com`}
`;

// Connection pooling
const prisma = new PrismaClient({
  datasources: {
    db: {
      url: 'postgresql://user:pass@localhost:5432/myapp?connection_limit=10',
    },
  },
});
```

### TypeORM

**Installation:**

```bash
npm install typeorm reflect-metadata pg
npm install --save-dev @types/node
```

**Entity Definition:**

```typescript
import { Entity, PrimaryGeneratedColumn, Column, OneToMany, CreateDateColumn } from 'typeorm';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: 'varchar', length: 50, unique: true })
  username: string;

  @Column({ type: 'varchar', length: 255, unique: true })
  email: string;

  @OneToMany(() => Post, post => post.user)
  posts: Post[];

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}

@Entity('posts')
export class Post {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: 'varchar', length: 255 })
  title: string;

  @Column({ type: 'text', nullable: true })
  body: string;

  @Column({ name: 'user_id' })
  userId: number;

  @ManyToOne(() => User, user => user.posts, { onDelete: 'CASCADE' })
  user: User;
}
```

**Data Source Configuration:**

```typescript
import { DataSource } from 'typeorm';

export const AppDataSource = new DataSource({
  type: 'postgres',
  host: 'localhost',
  port: 5432,
  username: 'appuser',
  password: 'secret',
  database: 'myapp',
  entities: [User, Post],
  synchronize: false, // NEVER true in production!
  logging: ['error'],

  // Connection pooling
  extra: {
    max: 20,
    min: 5,
    idleTimeoutMillis: 30000,
  },
});

// Initialize
await AppDataSource.initialize();
```

**Repository Pattern:**

```typescript
const userRepository = AppDataSource.getRepository(User);

// Create
const user = userRepository.create({
  username: 'john',
  email: 'john@example.com',
});
await userRepository.save(user);

// Read
const users = await userRepository.find({
  where: { email: Like('%@gmail.com') },
  relations: ['posts'],
  order: { createdAt: 'DESC' },
  take: 10,
});

// Update
await userRepository.update({ id: 1 }, { email: 'new@example.com' });

// Delete
await userRepository.delete({ id: 1 });

// Transaction
await AppDataSource.transaction(async (transactionalEntityManager) => {
  await transactionalEntityManager.save(user1);
  await transactionalEntityManager.save(user2);
});
```

## Python Integration

### psycopg2

**Installation:**

```bash
pip install psycopg2-binary
```

**Basic Connection:**

```python
import psycopg2

# Connect
conn = psycopg2.connect(
    host="localhost",
    port=5432,
    user="appuser",
    password="secret",
    database="myapp"
)

# Query
cur = conn.cursor()
cur.execute("SELECT * FROM users WHERE id = %s", (1,))
row = cur.fetchone()
print(row)

# Close
cur.close()
conn.close()
```

**Connection Pool:**

```python
from psycopg2 import pool

# Create connection pool
connection_pool = psycopg2.pool.SimpleConnectionPool(
    minconn=5,
    maxconn=20,
    host="localhost",
    port=5432,
    user="appuser",
    password="secret",
    database="myapp"
)

# Get connection from pool
conn = connection_pool.getconn()

# Use connection
cur = conn.cursor()
cur.execute("SELECT * FROM users")
rows = cur.fetchall()

# Return connection to pool
connection_pool.putconn(conn)

# Close all connections
connection_pool.closeall()
```

**Context Manager (Best Practice):**

```python
import psycopg2
from contextlib import contextmanager

@contextmanager
def get_db_connection():
    conn = psycopg2.connect(
        host="localhost",
        user="appuser",
        password="secret",
        database="myapp"
    )
    try:
        yield conn
    finally:
        conn.close()

# Usage
with get_db_connection() as conn:
    with conn.cursor() as cur:
        cur.execute("SELECT * FROM users WHERE id = %s", (1,))
        user = cur.fetchone()
        print(user)
```

**Transaction:**

```python
def transfer_money(from_id, to_id, amount):
    with get_db_connection() as conn:
        with conn.cursor() as cur:
            try:
                cur.execute("BEGIN")

                cur.execute(
                    "UPDATE accounts SET balance = balance - %s WHERE id = %s",
                    (amount, from_id)
                )

                cur.execute(
                    "UPDATE accounts SET balance = balance + %s WHERE id = %s",
                    (amount, to_id)
                )

                conn.commit()
            except Exception as e:
                conn.rollback()
                raise e
```

**Type Safety:**

```python
from typing import Optional, List, Dict, Any

def get_user(user_id: int) -> Optional[Dict[str, Any]]:
    with get_db_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT id, username, email FROM users WHERE id = %s",
                (user_id,)
            )
            row = cur.fetchone()
            if row:
                return {
                    'id': row[0],
                    'username': row[1],
                    'email': row[2],
                }
            return None

def get_all_users() -> List[Dict[str, Any]]:
    with get_db_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT id, username, email FROM users")
            rows = cur.fetchall()
            return [
                {'id': row[0], 'username': row[1], 'email': row[2]}
                for row in rows
            ]
```

### SQLAlchemy

**Installation:**

```bash
pip install sqlalchemy psycopg2-binary
```

**Model Definition:**

```python
from sqlalchemy import create_engine, Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship, sessionmaker
from datetime import datetime

Base = declarative_base()

class User(Base):
    __tablename__ = 'users'

    id = Column(Integer, primary_key=True)
    username = Column(String(50), unique=True, nullable=False)
    email = Column(String(255), unique=True, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    posts = relationship('Post', back_populates='user', cascade='all, delete-orphan')

class Post(Base):
    __tablename__ = 'posts'

    id = Column(Integer, primary_key=True)
    title = Column(String(255), nullable=False)
    body = Column(String)
    user_id = Column(Integer, ForeignKey('users.id', ondelete='CASCADE'))

    user = relationship('User', back_populates='posts')
```

**Engine and Session:**

```python
# Create engine with connection pooling
engine = create_engine(
    'postgresql://appuser:secret@localhost:5432/myapp',
    pool_size=10,
    max_overflow=20,
    pool_pre_ping=True,  # Verify connections before use
)

# Create session factory
SessionLocal = sessionmaker(bind=engine)

# Create all tables
Base.metadata.create_all(engine)

# Use session
session = SessionLocal()

# Create
user = User(username='john', email='john@example.com')
session.add(user)
session.commit()

# Read
users = session.query(User).filter(User.email.like('%@gmail.com')).all()
user = session.query(User).filter_by(id=1).first()

# Update
user.email = 'new@example.com'
session.commit()

# Delete
session.delete(user)
session.commit()

# Close session
session.close()
```

**Context Manager:**

```python
from contextlib import contextmanager

@contextmanager
def get_db_session():
    session = SessionLocal()
    try:
        yield session
        session.commit()
    except Exception:
        session.rollback()
        raise
    finally:
        session.close()

# Usage
with get_db_session() as session:
    user = User(username='alice', email='alice@example.com')
    session.add(user)
```

## Next.js Integration

**API Route with pg:**

```typescript
// app/api/users/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { Pool } from 'pg';

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 20,
});

export async function GET(request: NextRequest) {
  try {
    const result = await pool.query('SELECT id, username, email FROM users');
    return NextResponse.json(result.rows);
  } catch (error) {
    console.error('Database error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { username, email } = body;

    const result = await pool.query(
      'INSERT INTO users (username, email) VALUES ($1, $2) RETURNING *',
      [username, email]
    );

    return NextResponse.json(result.rows[0], { status: 201 });
  } catch (error: any) {
    if (error.code === '23505') {
      return NextResponse.json({ error: 'Username or email already exists' }, { status: 409 });
    }
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
```

**API Route with Prisma:**

```typescript
// app/api/users/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export async function GET() {
  try {
    const users = await prisma.user.findMany({
      select: { id: true, username: true, email: true },
    });
    return NextResponse.json(users);
  } catch (error) {
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}

export async function POST(request: NextRequest) {
  try {
    const { username, email } = await request.json();

    const user = await prisma.user.create({
      data: { username, email },
    });

    return NextResponse.json(user, { status: 201 });
  } catch (error: any) {
    if (error.code === 'P2002') {
      return NextResponse.json({ error: 'Username or email already exists' }, { status: 409 });
    }
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
```

## Best Practices

### 1. Always Use Parameterized Queries

```javascript
// ❌ WRONG - SQL injection vulnerability
const email = req.body.email;
const result = await pool.query(`SELECT * FROM users WHERE email = '${email}'`);

// ✅ CORRECT - Parameterized query
const email = req.body.email;
const result = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
```

### 2. Use Connection Pooling

```javascript
// ❌ WRONG - New connection per query
const { Client } = require('pg');
app.get('/users', async (req, res) => {
  const client = new Client({ /* config */ });
  await client.connect();
  const result = await client.query('SELECT * FROM users');
  await client.end();
  res.json(result.rows);
});

// ✅ CORRECT - Connection pool
const { Pool } = require('pg');
const pool = new Pool({ /* config */ });

app.get('/users', async (req, res) => {
  const result = await pool.query('SELECT * FROM users');
  res.json(result.rows);
});
```

### 3. Handle Errors Properly

```javascript
async function safeQuery() {
  try {
    return await pool.query('SELECT * FROM users');
  } catch (error) {
    // Log error with context
    console.error('Database query failed:', {
      error: error.message,
      code: error.code,
      query: 'SELECT * FROM users',
    });

    // Rethrow or handle gracefully
    throw new Error('Failed to fetch users');
  }
}
```

### 4. Use Transactions for Multi-Statement Operations

```javascript
async function transferFunds(fromId, toId, amount) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const { rows } = await client.query(
      'UPDATE accounts SET balance = balance - $1 WHERE id = $2 RETURNING balance',
      [amount, fromId]
    );

    if (rows[0].balance < 0) {
      throw new Error('Insufficient funds');
    }

    await client.query(
      'UPDATE accounts SET balance = balance + $1 WHERE id = $2',
      [amount, toId]
    );

    await client.query('COMMIT');
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}
```

### 5. Close Connections Gracefully

```javascript
// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('SIGTERM received, closing database pool');
  await pool.end();
  process.exit(0);
});

process.on('SIGINT', async () => {
  console.log('SIGINT received, closing database pool');
  await pool.end();
  process.exit(0);
});
```

### 6. Use Environment Variables for Configuration

```javascript
// .env
DATABASE_URL=postgresql://appuser:secret@localhost:5432/myapp
DATABASE_POOL_MAX=20
DATABASE_POOL_MIN=5

// app.js
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: parseInt(process.env.DATABASE_POOL_MAX || '20'),
  min: parseInt(process.env.DATABASE_POOL_MIN || '5'),
});
```

### 7. Monitor Query Performance

```javascript
import { Pool } from 'pg';

const pool = new Pool({ /* config */ });

// Log slow queries
const originalQuery = pool.query.bind(pool);
pool.query = async (...args) => {
  const start = Date.now();
  try {
    const result = await originalQuery(...args);
    const duration = Date.now() - start;

    if (duration > 1000) {
      console.warn('Slow query detected:', {
        query: args[0],
        duration: `${duration}ms`,
      });
    }

    return result;
  } catch (error) {
    const duration = Date.now() - start;
    console.error('Query failed:', {
      query: args[0],
      duration: `${duration}ms`,
      error: error.message,
    });
    throw error;
  }
};
```

## AI Pair Programming Notes

**When integrating PostgreSQL with frameworks:**

1. **Always use connection pooling**: Essential for performance in production
2. **Show parameterized queries**: Prevent SQL injection vulnerabilities
3. **Demonstrate transaction patterns**: Multi-statement operations require transactions
4. **Explain error handling**: Different error codes for different scenarios
5. **Use TypeScript types**: Type safety for database operations
6. **Show graceful shutdown**: Close connections properly on application exit
7. **Mention ORMs**: Prisma/TypeORM for type safety, pg for raw control
8. **Discuss connection limits**: Match pool size to database max_connections
9. **Show monitoring**: Log slow queries, connection pool stats
10. **Environment configuration**: Use env vars, never hardcode credentials

**Common integration mistakes to catch:**
- Not using connection pooling (performance issue)
- String concatenation in queries (SQL injection)
- Missing error handling (silent failures)
- Not using transactions for multi-statement operations
- Hardcoded credentials (security issue)
- Not closing connections on shutdown (connection leaks)
- Setting pool size too high (overwhelming database)

---

**See Also:**
- PostgreSQL Fundamentals → [01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md)
- Performance Tuning → [07-PERFORMANCE.md](./07-PERFORMANCE.md)
- Connection Management → [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md)

**Last Updated**: 2025-11-16
