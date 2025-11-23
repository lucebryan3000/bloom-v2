# PostgreSQL Quick Reference

```yaml
id: postgresql_quick_reference
topic: PostgreSQL
file_role: Command cheat sheet and syntax reference
profile: all_levels
difficulty_level: all
kb_version: v3.1
prerequisites: []
related_topics:
  - All PostgreSQL topics
embedding_keywords:
  - PostgreSQL cheat sheet
  - SQL syntax
  - command reference
  - quick lookup
last_reviewed: 2025-11-16
```

## psql Meta-Commands

```sql
-- Connection
\c dbname                  -- Connect to database
\conninfo                  -- Show connection info
\q                         -- Quit psql

-- Information
\l                         -- List databases
\dt                        -- List tables
\d table_name              -- Describe table
\d+ table_name             -- Detailed table description
\di                        -- List indexes
\dv                        -- List views
\df                        -- List functions
\du                        -- List users/roles
\dn                        -- List schemas

-- Display
\x                         -- Toggle expanded display
\timing on                 -- Show query execution time
\pset format wrapped       -- Set output format

-- Execution
\i file.sql                -- Execute SQL from file
\e                         -- Edit query in $EDITOR
\! command                 -- Execute shell command

-- Help
\?                         -- psql command help
\h CREATE TABLE            -- SQL command help
```

## Database Operations

```sql
-- Create database
CREATE DATABASE myapp;
CREATE DATABASE myapp OWNER appuser;
CREATE DATABASE myapp TEMPLATE template0 ENCODING 'UTF8';

-- Drop database
DROP DATABASE myapp;
DROP DATABASE IF EXISTS myapp;

-- Alter database
ALTER DATABASE myapp RENAME TO newapp;
ALTER DATABASE myapp OWNER TO newuser;
ALTER DATABASE myapp CONNECTION LIMIT 100;

-- List databases
SELECT datname FROM pg_database;
```

## Table Operations

```sql
-- Create table
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  username VARCHAR(50) UNIQUE NOT NULL,
  email VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Drop table
DROP TABLE users;
DROP TABLE IF EXISTS users CASCADE;

-- Alter table
ALTER TABLE users ADD COLUMN age INTEGER;
ALTER TABLE users DROP COLUMN age;
ALTER TABLE users RENAME COLUMN username TO user_name;
ALTER TABLE users ALTER COLUMN email SET NOT NULL;
ALTER TABLE users ADD CONSTRAINT unique_email UNIQUE (email);

-- Rename table
ALTER TABLE users RENAME TO app_users;

-- Truncate table (delete all rows)
TRUNCATE TABLE users;
TRUNCATE TABLE users RESTART IDENTITY CASCADE;
```

## Data Manipulation

```sql
-- INSERT
INSERT INTO users (username, email) VALUES ('john', 'john@example.com');
INSERT INTO users (username, email) VALUES
  ('alice', 'alice@example.com'),
  ('bob', 'bob@example.com');
INSERT INTO users (username, email) VALUES ('jane', 'jane@example.com')
  RETURNING id, username;

-- UPDATE
UPDATE users SET email = 'new@example.com' WHERE id = 1;
UPDATE users SET email = 'new@example.com', updated_at = NOW() WHERE id = 1
  RETURNING *;

-- DELETE
DELETE FROM users WHERE id = 1;
DELETE FROM users WHERE created_at < '2023-01-01'
  RETURNING username;

-- UPSERT (INSERT ON CONFLICT)
INSERT INTO users (id, username, email) VALUES (1, 'john', 'john@example.com')
ON CONFLICT (id) DO UPDATE SET email = EXCLUDED.email;
```

## Queries

```sql
-- SELECT
SELECT * FROM users;
SELECT id, username FROM users WHERE email LIKE '%@gmail.com';
SELECT * FROM users ORDER BY created_at DESC LIMIT 10 OFFSET 20;
SELECT DISTINCT role FROM users;

-- Aggregates
SELECT COUNT(*) FROM users;
SELECT AVG(age), MIN(age), MAX(age) FROM users;
SELECT role, COUNT(*) FROM users GROUP BY role;
SELECT role, COUNT(*) FROM users GROUP BY role HAVING COUNT(*) > 10;

-- JOINs
SELECT u.username, p.title
FROM users u
INNER JOIN posts p ON p.user_id = u.id;

SELECT u.username, COUNT(p.id) AS post_count
FROM users u
LEFT JOIN posts p ON p.user_id = u.id
GROUP BY u.id, u.username;

-- Subqueries
SELECT * FROM users WHERE id IN (SELECT user_id FROM posts);
SELECT * FROM users WHERE EXISTS (SELECT 1 FROM posts WHERE posts.user_id = users.id);

-- CTEs
WITH active_users AS (
  SELECT * FROM users WHERE status = 'active'
)
SELECT * FROM active_users JOIN posts ON posts.user_id = active_users.id;

-- Window Functions
SELECT username, salary, RANK() OVER (ORDER BY salary DESC) AS rank
FROM employees;

SELECT username, created_at,
  LAG(created_at) OVER (ORDER BY created_at) AS prev_created
FROM users;
```

## Indexes

```sql
-- Create index
CREATE INDEX idx_users_email ON users (email);
CREATE UNIQUE INDEX idx_users_username ON users (username);
CREATE INDEX CONCURRENTLY idx_users_email ON users (email);

-- Multi-column index
CREATE INDEX idx_users_name ON users (last_name, first_name);

-- Partial index
CREATE INDEX idx_active_users ON users (email) WHERE status = 'active';

-- Expression index
CREATE INDEX idx_users_lower_email ON users (LOWER(email));

-- GIN index (for JSONB, arrays)
CREATE INDEX idx_users_metadata ON users USING GIN (metadata);

-- Drop index
DROP INDEX idx_users_email;
DROP INDEX CONCURRENTLY idx_users_email;

-- Reindex
REINDEX INDEX idx_users_email;
REINDEX TABLE users;
```

## Constraints

```sql
-- PRIMARY KEY
CREATE TABLE users (id SERIAL PRIMARY KEY);
ALTER TABLE users ADD PRIMARY KEY (id);

-- FOREIGN KEY
CREATE TABLE posts (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE
);
ALTER TABLE posts ADD FOREIGN KEY (user_id) REFERENCES users(id);

-- UNIQUE
ALTER TABLE users ADD CONSTRAINT unique_email UNIQUE (email);

-- CHECK
ALTER TABLE users ADD CONSTRAINT valid_age CHECK (age >= 0 AND age <= 150);

-- NOT NULL
ALTER TABLE users ALTER COLUMN email SET NOT NULL;

-- DEFAULT
ALTER TABLE users ALTER COLUMN role SET DEFAULT 'user';

-- Drop constraint
ALTER TABLE users DROP CONSTRAINT unique_email;
```

## Transactions

```sql
-- Basic transaction
BEGIN;
  UPDATE accounts SET balance = balance - 100 WHERE id = 1;
  UPDATE accounts SET balance = balance + 100 WHERE id = 2;
COMMIT;

-- Rollback
BEGIN;
  DELETE FROM users WHERE id = 999;
ROLLBACK;

-- Savepoints
BEGIN;
  INSERT INTO users (username) VALUES ('alice');
  SAVEPOINT sp1;
  INSERT INTO users (username) VALUES ('bob');
  ROLLBACK TO sp1;  -- Only alice is kept
COMMIT;

-- Set isolation level
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
  SELECT * FROM accounts WHERE id = 1 FOR UPDATE;
COMMIT;
```

## Data Types

```sql
-- Numeric
SMALLINT, INTEGER, BIGINT
SERIAL, BIGSERIAL
NUMERIC(10,2), DECIMAL(10,2)
REAL, DOUBLE PRECISION

-- Text
CHAR(10), VARCHAR(50), TEXT

-- Date/Time
DATE, TIME, TIMESTAMP, TIMESTAMPTZ, INTERVAL

-- Boolean
BOOLEAN

-- Binary
BYTEA

-- UUID
UUID

-- JSON
JSON, JSONB

-- Arrays
INTEGER[], TEXT[]

-- Ranges
INT4RANGE, INT8RANGE, DATERANGE, TSRANGE, TSTZRANGE

-- Custom
CREATE TYPE mood AS ENUM ('sad', 'ok', 'happy');
```

## Functions

### String Functions

```sql
-- Concatenation
SELECT first_name || ' ' || last_name AS full_name FROM users;
SELECT CONCAT(first_name, ' ', last_name) FROM users;

-- Case conversion
SELECT UPPER(email), LOWER(username) FROM users;

-- Substring
SELECT SUBSTRING(email FROM 1 FOR 10) FROM users;
SELECT LEFT(username, 5), RIGHT(username, 3) FROM users;

-- Length
SELECT LENGTH(username), CHAR_LENGTH(email) FROM users;

-- Trim
SELECT TRIM('  hello  '), LTRIM('  hello  '), RTRIM('  hello  ');

-- Replace
SELECT REPLACE(email, '@gmail.com', '@company.com') FROM users;

-- Split
SELECT SPLIT_PART(email, '@', 1) AS username FROM users;
```

### Date/Time Functions

```sql
-- Current date/time
SELECT NOW(), CURRENT_TIMESTAMP, CURRENT_DATE, CURRENT_TIME;

-- Date arithmetic
SELECT NOW() + INTERVAL '7 days';
SELECT NOW() - INTERVAL '1 month';
SELECT AGE(NOW(), created_at) FROM users;

-- Extract parts
SELECT EXTRACT(YEAR FROM created_at) FROM users;
SELECT DATE_PART('month', created_at) FROM users;

-- Truncate
SELECT DATE_TRUNC('day', created_at) FROM users;
SELECT DATE_TRUNC('month', created_at) FROM users;

-- Format
SELECT TO_CHAR(created_at, 'YYYY-MM-DD HH24:MI:SS') FROM users;
SELECT TO_DATE('2025-11-16', 'YYYY-MM-DD');
```

### Aggregate Functions

```sql
SELECT COUNT(*), COUNT(DISTINCT role) FROM users;
SELECT SUM(amount), AVG(amount) FROM orders;
SELECT MIN(price), MAX(price) FROM products;
SELECT ARRAY_AGG(username) FROM users;
SELECT STRING_AGG(username, ', ') FROM users;
SELECT JSONB_AGG(username) FROM users;
```

## JSON/JSONB Operations

```sql
-- Operators
metadata->'key'              -- Get JSON value (returns JSON)
metadata->>'key'             -- Get JSON value (returns text)
metadata#>'{a,b}'            -- Get nested value (JSON)
metadata#>>'{a,b}'           -- Get nested value (text)

-- Containment
metadata @> '{"role":"admin"}'   -- Contains
metadata ? 'key'                  -- Key exists
metadata ?| ARRAY['k1','k2']      -- Any key exists
metadata ?& ARRAY['k1','k2']      -- All keys exist

-- Functions
SELECT jsonb_array_length(metadata->'tags') FROM users;
SELECT jsonb_object_keys(metadata) FROM users;
SELECT jsonb_set(metadata, '{role}', '"admin"') FROM users;
```

## User Management

```sql
-- Create user
CREATE USER appuser WITH PASSWORD 'secret';
CREATE USER admin WITH SUPERUSER PASSWORD 'secret';

-- Alter user
ALTER USER appuser WITH PASSWORD 'newsecret';
ALTER USER appuser VALID UNTIL '2026-01-01';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE myapp TO appuser;
GRANT SELECT, INSERT, UPDATE ON users TO appuser;
GRANT ALL ON ALL TABLES IN SCHEMA public TO appuser;

-- Revoke privileges
REVOKE INSERT ON users FROM appuser;

-- Drop user
DROP USER appuser;

-- List users
\du
SELECT usename FROM pg_user;
```

## Replication

```sql
-- Check if standby
SELECT pg_is_in_recovery();

-- Replication status (on primary)
SELECT * FROM pg_stat_replication;

-- Replication lag (on standby)
SELECT now() - pg_last_xact_replay_timestamp() AS lag;

-- Create replication slot
SELECT pg_create_physical_replication_slot('standby1');

-- Promote standby
SELECT pg_promote();
```

## Backup & Recovery

```bash
# Logical backup
pg_dump myapp > backup.sql
pg_dump -F c -f backup.dump myapp
pg_dumpall > all_databases.sql

# Restore
psql myapp < backup.sql
pg_restore -d myapp backup.dump

# Physical backup
pg_basebackup -h localhost -U replicator -D /backup -P -R

# WAL archiving
archive_command = 'cp %p /archives/%f'
```

## Monitoring

```sql
-- Active connections
SELECT count(*) FROM pg_stat_activity;
SELECT * FROM pg_stat_activity WHERE state = 'active';

-- Database size
SELECT pg_size_pretty(pg_database_size('myapp'));

-- Table size
SELECT pg_size_pretty(pg_total_relation_size('users'));

-- Index usage
SELECT * FROM pg_stat_user_indexes WHERE idx_scan = 0;

-- Cache hit ratio
SELECT
  sum(heap_blks_hit) * 100.0 / NULLIF(sum(heap_blks_hit) + sum(heap_blks_read), 0)
FROM pg_statio_user_tables;

-- Slow queries
SELECT query, mean_exec_time FROM pg_stat_statements
ORDER BY mean_exec_time DESC LIMIT 10;

-- Kill query
SELECT pg_terminate_backend(12345);
```

## Performance

```sql
-- EXPLAIN
EXPLAIN SELECT * FROM users WHERE email = 'john@example.com';
EXPLAIN ANALYZE SELECT * FROM users WHERE email = 'john@example.com';
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM users;

-- VACUUM
VACUUM users;
VACUUM ANALYZE users;
VACUUM FULL users;

-- ANALYZE
ANALYZE users;
ANALYZE;

-- Set parameters
SET work_mem = '64MB';
SET enable_seqscan = off;
SHOW all;
```

## Configuration

```sql
-- Show config file location
SHOW config_file;

-- Show settings
SHOW shared_buffers;
SHOW all;

-- Alter system settings
ALTER SYSTEM SET shared_buffers = '4GB';
SELECT pg_reload_conf();

-- Per-database settings
ALTER DATABASE myapp SET work_mem = '64MB';

-- Per-user settings
ALTER USER appuser SET work_mem = '32MB';
```

## Time Complexity Reference

| Operation | Without Index | With Index |
|-----------|--------------|------------|
| **SELECT WHERE =** | O(n) | O(log n) |
| **SELECT WHERE LIKE 'prefix%'** | O(n) | O(log n) |
| **SELECT WHERE LIKE '%suffix'** | O(n) | O(n) |
| **INSERT** | O(1) | O(log n) per index |
| **UPDATE** | O(n) + O(log n) per index | O(log n) + O(log n) per index |
| **DELETE** | O(n) + O(log n) per index | O(log n) + O(log n) per index |
| **ORDER BY** | O(n log n) | O(n) if index matches |
| **JOIN** | O(n * m) | O(n log m) or O(n + m) |

## Common Patterns

```sql
-- Pagination (offset-based)
SELECT * FROM users ORDER BY id LIMIT 20 OFFSET 40;

-- Pagination (cursor-based)
SELECT * FROM users WHERE id > 1000 ORDER BY id LIMIT 20;

-- Top N per group
SELECT DISTINCT ON (category) category, product_name, price
FROM products
ORDER BY category, price DESC;

-- Running total
SELECT date, amount,
  SUM(amount) OVER (ORDER BY date) AS running_total
FROM sales;

-- Row number
SELECT username, ROW_NUMBER() OVER (ORDER BY created_at) AS row_num
FROM users;

-- Upsert
INSERT INTO users (id, username, email) VALUES (1, 'john', 'john@example.com')
ON CONFLICT (id) DO UPDATE SET email = EXCLUDED.email;

-- Bulk insert
INSERT INTO users (username) SELECT unnest(ARRAY['alice', 'bob', 'charlie']);
```

---

**See Also:**
- Full documentation → [README.md](./README.md)
- Topic index → [INDEX.md](./INDEX.md)
- Framework integration → [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md)

**Last Updated**: 2025-11-16
