# PostgreSQL SQL Basics

```yaml
id: postgresql_02_sql_basics
topic: PostgreSQL
file_role: Fundamental SQL operations (DDL, DML, queries)
profile: beginner
difficulty_level: beginner
kb_version: v3.1
prerequisites:
  - PostgreSQL Fundamentals (01-FUNDAMENTALS.md)
  - Basic understanding of relational databases
  - psql CLI familiarity
related_topics:
  - Data Types (03-DATA-TYPES.md)
  - Queries (04-QUERIES.md)
  - Transactions (06-TRANSACTIONS.md)
embedding_keywords:
  - CREATE TABLE
  - INSERT UPDATE DELETE
  - DDL DML SQL
  - PRIMARY KEY FOREIGN KEY
  - constraints
  - ALTER TABLE
  - CRUD operations
  - SQL syntax
last_reviewed: 2025-11-16
```

## SQL Language Components

PostgreSQL's SQL is divided into several sublanguages:

- **DDL (Data Definition Language)**: CREATE, ALTER, DROP - Define database structure
- **DML (Data Manipulation Language)**: INSERT, UPDATE, DELETE - Manipulate data
- **DQL (Data Query Language)**: SELECT - Query data
- **DCL (Data Control Language)**: GRANT, REVOKE - Control access
- **TCL (Transaction Control Language)**: BEGIN, COMMIT, ROLLBACK - Manage transactions

## DDL - Data Definition Language

### CREATE TABLE

```sql
-- Basic table creation
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  username VARCHAR(50) NOT NULL UNIQUE,
  email VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table with constraints
CREATE TABLE posts (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  body TEXT,
  status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived')),
  published_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT title_not_empty CHECK (LENGTH(TRIM(title)) > 0)
);

-- Table with composite primary key
CREATE TABLE user_roles (
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  role_id INTEGER REFERENCES roles(id) ON DELETE CASCADE,
  assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, role_id)
);

-- Table with generated column
CREATE TABLE products (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  price NUMERIC(10, 2) NOT NULL,
  tax_rate NUMERIC(4, 2) DEFAULT 0.10,
  price_with_tax NUMERIC(10, 2) GENERATED ALWAYS AS (price * (1 + tax_rate)) STORED
);
```

### Primary Keys

```sql
-- SERIAL (auto-incrementing integer)
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100)
);

-- UUID (universally unique identifier)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(100)
);

-- Composite primary key
CREATE TABLE order_items (
  order_id INTEGER,
  product_id INTEGER,
  quantity INTEGER,
  PRIMARY KEY (order_id, product_id)
);

-- Named primary key constraint
CREATE TABLE users (
  id SERIAL,
  email VARCHAR(255),
  CONSTRAINT users_pkey PRIMARY KEY (id)
);
```

### Foreign Keys

```sql
-- Basic foreign key
CREATE TABLE orders (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id)
);

-- Foreign key with ON DELETE action
CREATE TABLE orders (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE
);

-- ON DELETE options:
-- CASCADE: Delete child rows when parent is deleted
-- SET NULL: Set foreign key to NULL when parent is deleted
-- SET DEFAULT: Set foreign key to default value when parent is deleted
-- RESTRICT: Prevent deletion of parent if children exist (default)
-- NO ACTION: Similar to RESTRICT but checked at transaction end

-- ON UPDATE action
CREATE TABLE orders (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);

-- Named foreign key constraint
CREATE TABLE orders (
  id SERIAL PRIMARY KEY,
  user_id INTEGER,
  CONSTRAINT fk_orders_user FOREIGN KEY (user_id)
    REFERENCES users(id) ON DELETE CASCADE
);

-- Composite foreign key
CREATE TABLE order_items (
  order_id INTEGER,
  product_id INTEGER,
  quantity INTEGER,
  FOREIGN KEY (order_id, product_id) REFERENCES products_orders(order_id, product_id)
);
```

### Constraints

```sql
-- NOT NULL constraint
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255) NOT NULL,
  username VARCHAR(50) NOT NULL
);

-- UNIQUE constraint
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255) UNIQUE,
  username VARCHAR(50) UNIQUE
);

-- Composite UNIQUE constraint
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  first_name VARCHAR(50),
  last_name VARCHAR(50),
  email VARCHAR(255),
  UNIQUE (email),
  UNIQUE (first_name, last_name)
);

-- CHECK constraint
CREATE TABLE products (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255),
  price NUMERIC(10, 2) CHECK (price > 0),
  discount_percent NUMERIC(5, 2) CHECK (discount_percent >= 0 AND discount_percent <= 100),
  stock INTEGER CHECK (stock >= 0)
);

-- Named CHECK constraint
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  age INTEGER,
  CONSTRAINT valid_age CHECK (age >= 0 AND age <= 150)
);

-- Table-level CHECK constraint (multiple columns)
CREATE TABLE date_ranges (
  id SERIAL PRIMARY KEY,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  CONSTRAINT valid_date_range CHECK (end_date >= start_date)
);

-- DEFAULT constraint
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  username VARCHAR(50),
  role VARCHAR(20) DEFAULT 'user',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- EXCLUSION constraint (requires btree_gist extension)
CREATE EXTENSION IF NOT EXISTS btree_gist;

CREATE TABLE room_bookings (
  id SERIAL PRIMARY KEY,
  room_id INTEGER,
  booked_during TSRANGE,
  EXCLUDE USING GIST (room_id WITH =, booked_during WITH &&)
);
```

### ALTER TABLE

```sql
-- Add column
ALTER TABLE users ADD COLUMN phone VARCHAR(20);

-- Add column with default
ALTER TABLE users ADD COLUMN status VARCHAR(20) DEFAULT 'active';

-- Drop column
ALTER TABLE users DROP COLUMN phone;

-- Rename column
ALTER TABLE users RENAME COLUMN username TO user_name;

-- Change column type
ALTER TABLE users ALTER COLUMN age TYPE BIGINT;

-- Set NOT NULL
ALTER TABLE users ALTER COLUMN email SET NOT NULL;

-- Drop NOT NULL
ALTER TABLE users ALTER COLUMN phone DROP NOT NULL;

-- Set default value
ALTER TABLE users ALTER COLUMN role SET DEFAULT 'user';

-- Drop default value
ALTER TABLE users ALTER COLUMN role DROP DEFAULT;

-- Add constraint
ALTER TABLE users ADD CONSTRAINT unique_email UNIQUE (email);

-- Drop constraint
ALTER TABLE users DROP CONSTRAINT unique_email;

-- Add foreign key
ALTER TABLE orders ADD CONSTRAINT fk_user
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- Rename table
ALTER TABLE users RENAME TO app_users;
```

### DROP TABLE

```sql
-- Drop table
DROP TABLE users;

-- Drop if exists (no error if missing)
DROP TABLE IF EXISTS users;

-- Drop with CASCADE (also drop dependent objects)
DROP TABLE users CASCADE;

-- Drop multiple tables
DROP TABLE users, posts, comments;
```

### Temporary Tables

```sql
-- Create temporary table (exists only in current session)
CREATE TEMP TABLE temp_results (
  id INTEGER,
  value TEXT
);

-- Temporary table inheriting structure from existing table
CREATE TEMP TABLE temp_users AS
SELECT * FROM users WHERE created_at > NOW() - INTERVAL '7 days';

-- Temporary table for CTEs
WITH recent_users AS (
  SELECT * FROM users WHERE created_at > NOW() - INTERVAL '30 days'
)
SELECT * INTO TEMP TABLE temp_recent_users FROM recent_users;
```

## DML - Data Manipulation Language

### INSERT

```sql
-- Insert single row
INSERT INTO users (username, email, password_hash)
VALUES ('john_doe', 'john@example.com', 'hashed_password_123');

-- Insert multiple rows
INSERT INTO users (username, email, password_hash) VALUES
  ('jane_smith', 'jane@example.com', 'hashed_password_456'),
  ('bob_jones', 'bob@example.com', 'hashed_password_789'),
  ('alice_wong', 'alice@example.com', 'hashed_password_012');

-- Insert with RETURNING (get inserted row data back)
INSERT INTO users (username, email, password_hash)
VALUES ('sam_taylor', 'sam@example.com', 'hashed_password_345')
RETURNING id, username, created_at;

-- Insert from SELECT
INSERT INTO archived_users (id, username, email)
SELECT id, username, email FROM users WHERE last_login < '2023-01-01';

-- Insert with DEFAULT values
INSERT INTO users (username, email, role)
VALUES ('test_user', 'test@example.com', DEFAULT);

-- Insert all default values
INSERT INTO users DEFAULT VALUES;

-- Insert with ON CONFLICT (upsert)
INSERT INTO users (id, username, email, password_hash)
VALUES (1, 'john_doe', 'john@example.com', 'new_hash')
ON CONFLICT (id) DO UPDATE
  SET password_hash = EXCLUDED.password_hash,
      updated_at = CURRENT_TIMESTAMP;

-- Insert or ignore conflicts
INSERT INTO users (username, email, password_hash)
VALUES ('existing_user', 'existing@example.com', 'hash')
ON CONFLICT (email) DO NOTHING;

-- Upsert with WHERE clause
INSERT INTO product_inventory (product_id, quantity)
VALUES (101, 50)
ON CONFLICT (product_id) DO UPDATE
  SET quantity = product_inventory.quantity + EXCLUDED.quantity
  WHERE product_inventory.quantity < 100;
```

### UPDATE

```sql
-- Update single row
UPDATE users
SET email = 'newemail@example.com'
WHERE id = 1;

-- Update multiple columns
UPDATE users
SET
  email = 'newemail@example.com',
  updated_at = CURRENT_TIMESTAMP
WHERE id = 1;

-- Update multiple rows
UPDATE users
SET role = 'premium'
WHERE created_at < '2023-01-01';

-- Update with RETURNING
UPDATE users
SET status = 'inactive'
WHERE last_login < NOW() - INTERVAL '1 year'
RETURNING id, username, status;

-- Update from another table
UPDATE posts
SET user_name = users.username
FROM users
WHERE posts.user_id = users.id;

-- Update with subquery
UPDATE products
SET category_name = (
  SELECT name FROM categories WHERE categories.id = products.category_id
);

-- Conditional update with CASE
UPDATE products
SET price = CASE
  WHEN category = 'electronics' THEN price * 1.10
  WHEN category = 'clothing' THEN price * 1.05
  ELSE price
END;

-- Update all rows (careful!)
UPDATE users SET status = 'active';
```

### DELETE

```sql
-- Delete single row
DELETE FROM users WHERE id = 1;

-- Delete multiple rows
DELETE FROM users WHERE last_login < '2023-01-01';

-- Delete with RETURNING
DELETE FROM users
WHERE status = 'inactive'
RETURNING id, username;

-- Delete with subquery
DELETE FROM posts
WHERE user_id IN (
  SELECT id FROM users WHERE status = 'banned'
);

-- Delete from join
DELETE FROM posts
USING users
WHERE posts.user_id = users.id
  AND users.status = 'deleted';

-- Delete all rows (careful!)
DELETE FROM users;

-- TRUNCATE (faster than DELETE for removing all rows)
TRUNCATE TABLE users;

-- TRUNCATE with CASCADE (also truncate dependent tables)
TRUNCATE TABLE users CASCADE;

-- TRUNCATE multiple tables
TRUNCATE TABLE users, posts, comments;
```

## DQL - Data Query Language

### SELECT Basics

```sql
-- Select all columns
SELECT * FROM users;

-- Select specific columns
SELECT id, username, email FROM users;

-- Select with alias
SELECT
  id AS user_id,
  username AS name,
  email AS email_address
FROM users;

-- Select with WHERE clause
SELECT * FROM users WHERE role = 'admin';

-- Select with multiple conditions
SELECT * FROM users
WHERE role = 'admin' AND status = 'active';

-- Select with OR condition
SELECT * FROM users
WHERE role = 'admin' OR role = 'moderator';

-- Select with IN
SELECT * FROM users
WHERE role IN ('admin', 'moderator', 'editor');

-- Select with NOT IN
SELECT * FROM users
WHERE role NOT IN ('banned', 'suspended');

-- Select with BETWEEN
SELECT * FROM products
WHERE price BETWEEN 10.00 AND 50.00;

-- Select with LIKE (pattern matching)
SELECT * FROM users WHERE email LIKE '%@gmail.com';

-- Select with ILIKE (case-insensitive LIKE)
SELECT * FROM users WHERE username ILIKE 'john%';

-- Select with IS NULL
SELECT * FROM users WHERE phone IS NULL;

-- Select with IS NOT NULL
SELECT * FROM users WHERE phone IS NOT NULL;

-- Select DISTINCT
SELECT DISTINCT role FROM users;

-- Select with ORDER BY
SELECT * FROM users ORDER BY created_at DESC;

-- Select with multiple ORDER BY
SELECT * FROM users
ORDER BY role ASC, created_at DESC;

-- Select with LIMIT
SELECT * FROM users LIMIT 10;

-- Select with OFFSET (pagination)
SELECT * FROM users ORDER BY id LIMIT 10 OFFSET 20;
```

### Aggregate Functions

```sql
-- COUNT
SELECT COUNT(*) FROM users;
SELECT COUNT(DISTINCT role) FROM users;

-- SUM
SELECT SUM(price) FROM products;

-- AVG
SELECT AVG(price) FROM products;

-- MIN and MAX
SELECT MIN(price), MAX(price) FROM products;

-- GROUP BY
SELECT role, COUNT(*) as user_count
FROM users
GROUP BY role;

-- GROUP BY with multiple columns
SELECT role, status, COUNT(*) as count
FROM users
GROUP BY role, status;

-- HAVING (filter after aggregation)
SELECT role, COUNT(*) as count
FROM users
GROUP BY role
HAVING COUNT(*) > 10;

-- Aggregate with WHERE and HAVING
SELECT category, AVG(price) as avg_price
FROM products
WHERE stock > 0
GROUP BY category
HAVING AVG(price) > 50
ORDER BY avg_price DESC;
```

### String Functions

```sql
-- Concatenation
SELECT first_name || ' ' || last_name AS full_name FROM users;
SELECT CONCAT(first_name, ' ', last_name) AS full_name FROM users;

-- Length
SELECT username, LENGTH(username) FROM users;

-- Uppercase/Lowercase
SELECT UPPER(email), LOWER(username) FROM users;

-- Substring
SELECT SUBSTRING(email FROM 1 FOR 10) FROM users;

-- Replace
SELECT REPLACE(email, '@gmail.com', '@company.com') FROM users;

-- Trim
SELECT TRIM('  hello  ');           -- 'hello'
SELECT LTRIM('  hello  ');          -- 'hello  '
SELECT RTRIM('  hello  ');          -- '  hello'

-- Position (find substring)
SELECT POSITION('@' IN email) FROM users;

-- Left/Right
SELECT LEFT(username, 5), RIGHT(username, 3) FROM users;

-- Split part
SELECT SPLIT_PART(email, '@', 1) AS username,
       SPLIT_PART(email, '@', 2) AS domain
FROM users;
```

### Date/Time Functions

```sql
-- Current timestamp
SELECT NOW();                        -- 2025-11-16 14:30:00.123456-05
SELECT CURRENT_TIMESTAMP;            -- Same as NOW()
SELECT CURRENT_DATE;                 -- 2025-11-16
SELECT CURRENT_TIME;                 -- 14:30:00.123456-05

-- Date arithmetic
SELECT NOW() - INTERVAL '7 days';
SELECT NOW() + INTERVAL '1 month';
SELECT NOW() - INTERVAL '2 hours 30 minutes';

-- Extract parts
SELECT EXTRACT(YEAR FROM created_at) FROM users;
SELECT EXTRACT(MONTH FROM created_at) FROM users;
SELECT EXTRACT(DAY FROM created_at) FROM users;
SELECT EXTRACT(HOUR FROM created_at) FROM users;

-- Date_part (similar to EXTRACT)
SELECT DATE_PART('year', created_at) FROM users;

-- Age calculation
SELECT AGE(NOW(), created_at) FROM users;

-- Date truncation
SELECT DATE_TRUNC('day', created_at) FROM users;
SELECT DATE_TRUNC('month', created_at) FROM users;
SELECT DATE_TRUNC('year', created_at) FROM users;

-- Format dates
SELECT TO_CHAR(created_at, 'YYYY-MM-DD') FROM users;
SELECT TO_CHAR(created_at, 'Month DD, YYYY') FROM users;
SELECT TO_CHAR(created_at, 'HH24:MI:SS') FROM users;

-- Parse dates
SELECT TO_DATE('2025-11-16', 'YYYY-MM-DD');
SELECT TO_TIMESTAMP('2025-11-16 14:30:00', 'YYYY-MM-DD HH24:MI:SS');
```

### Mathematical Functions

```sql
-- Basic math
SELECT price * 1.1 AS price_with_tax FROM products;
SELECT price / 2 AS half_price FROM products;
SELECT price % 10 AS remainder FROM products;

-- Rounding
SELECT ROUND(price, 2) FROM products;           -- Round to 2 decimals
SELECT CEIL(price) FROM products;               -- Round up
SELECT FLOOR(price) FROM products;              -- Round down
SELECT TRUNC(price, 1) FROM products;           -- Truncate to 1 decimal

-- Power and square root
SELECT POWER(2, 10);                            -- 1024
SELECT SQRT(16);                                -- 4

-- Absolute value
SELECT ABS(-42);                                -- 42

-- Random
SELECT RANDOM();                                -- 0.0 to 1.0
SELECT FLOOR(RANDOM() * 100 + 1)::INTEGER;      -- 1 to 100
```

### CASE Expressions

```sql
-- Simple CASE
SELECT
  username,
  CASE role
    WHEN 'admin' THEN 'Administrator'
    WHEN 'moderator' THEN 'Moderator'
    WHEN 'user' THEN 'Regular User'
    ELSE 'Unknown'
  END AS role_description
FROM users;

-- Searched CASE
SELECT
  product_name,
  price,
  CASE
    WHEN price < 10 THEN 'Budget'
    WHEN price >= 10 AND price < 50 THEN 'Mid-range'
    WHEN price >= 50 AND price < 100 THEN 'Premium'
    ELSE 'Luxury'
  END AS price_tier
FROM products;

-- CASE in WHERE clause
SELECT * FROM users
WHERE
  CASE
    WHEN role = 'admin' THEN age >= 18
    WHEN role = 'moderator' THEN age >= 21
    ELSE age >= 13
  END;

-- CASE with aggregation
SELECT
  role,
  COUNT(CASE WHEN status = 'active' THEN 1 END) AS active_count,
  COUNT(CASE WHEN status = 'inactive' THEN 1 END) AS inactive_count
FROM users
GROUP BY role;
```

## CRUD Operations in Practice

### Complete User Management Example

```sql
-- CREATE: Insert new user
INSERT INTO users (username, email, password_hash, role)
VALUES ('new_user', 'user@example.com', 'hashed_pass', 'user')
RETURNING id, username, created_at;

-- READ: Get user by ID
SELECT id, username, email, role, created_at
FROM users
WHERE id = 1;

-- READ: Get all active users
SELECT id, username, email, role
FROM users
WHERE status = 'active'
ORDER BY created_at DESC;

-- UPDATE: Change user email
UPDATE users
SET email = 'new_email@example.com',
    updated_at = CURRENT_TIMESTAMP
WHERE id = 1
RETURNING id, username, email, updated_at;

-- DELETE: Remove user
DELETE FROM users
WHERE id = 1
RETURNING id, username;

-- Soft delete (mark as deleted instead of removing)
UPDATE users
SET status = 'deleted',
    deleted_at = CURRENT_TIMESTAMP
WHERE id = 1;
```

## Transactions in SQL

```sql
-- Begin transaction
BEGIN;

-- Multiple operations
INSERT INTO users (username, email) VALUES ('test', 'test@example.com');
UPDATE accounts SET balance = balance - 100 WHERE user_id = 1;
UPDATE accounts SET balance = balance + 100 WHERE user_id = 2;

-- Commit transaction (make changes permanent)
COMMIT;

-- Or rollback if error
ROLLBACK;

-- Savepoints (partial rollback)
BEGIN;
  INSERT INTO users (username, email) VALUES ('user1', 'user1@example.com');
  SAVEPOINT sp1;

  INSERT INTO users (username, email) VALUES ('user2', 'user2@example.com');
  SAVEPOINT sp2;

  -- Rollback to sp1 (undo user2 insert, keep user1)
  ROLLBACK TO sp1;

COMMIT;
```

## AI Pair Programming Notes

**When working with SQL in pair programming:**

1. **Always use parameterized queries**: Never concatenate user input into SQL strings (SQL injection risk)
2. **Show both raw SQL and ORM**: Provide SQL examples alongside Prisma/TypeORM/Sequelize equivalents
3. **Explain RETURNING clause**: PostgreSQL-specific, very useful for getting inserted/updated data
4. **Demonstrate transactions**: Show how to wrap related operations in transactions
5. **Use meaningful table/column names**: `user_id` not `uid`, `created_at` not `ts`
6. **Show constraint violations**: Demonstrate what happens when constraints fail
7. **Explain ON CONFLICT**: Upsert patterns are common in production
8. **Use examples with realistic data**: Not just `id=1`, show patterns with multiple rows
9. **Show query result shapes**: Clarify what the query returns (single row vs array)
10. **Discuss performance**: Mention when to use indexes (covered in 05-INDEXES.md)

**Common mistakes to catch:**
- Missing WHERE clause in UPDATE/DELETE (updates all rows!)
- Forgetting RETURNING clause when you need the result
- Not using transactions for multi-statement operations
- Using SELECT * in production (explicitly list columns)
- Forgetting to handle NULL values
- Using LIKE with leading wildcard (`LIKE '%abc'` can't use index)

## Next Steps

1. **03-DATA-TYPES.md** - Explore PostgreSQL's rich type system
2. **04-QUERIES.md** - Master JOINs, subqueries, CTEs, window functions
3. **05-INDEXES.md** - Optimize queries with proper indexing
4. **06-TRANSACTIONS.md** - Deep dive into isolation levels and concurrency

## Additional Resources

- PostgreSQL SQL Tutorial: https://www.postgresqltutorial.com/
- PostgreSQL SQL Reference: https://www.postgresql.org/docs/current/sql.html
- SQL Style Guide: https://www.sqlstyle.guide/
