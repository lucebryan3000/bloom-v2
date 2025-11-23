# PostgreSQL Indexes

```yaml
id: postgresql_05_indexes
topic: PostgreSQL
file_role: Index types, creation strategies, and performance optimization
profile: intermediate
difficulty_level: intermediate
kb_version: v3.1
prerequisites:
  - SQL Basics (02-SQL-BASICS.md)
  - Data Types (03-DATA-TYPES.md)
  - Queries (04-QUERIES.md)
related_topics:
  - Performance (08-PERFORMANCE.md)
  - Transactions (06-TRANSACTIONS.md)
embedding_keywords:
  - B-tree index
  - GIN GiST BRIN
  - CREATE INDEX
  - partial index
  - covering index
  - multicolumn index
  - index-only scan
  - EXPLAIN ANALYZE
  - query optimization
last_reviewed: 2025-11-16
```

## What Are Indexes?

Indexes are data structures that improve the speed of data retrieval operations on database tables. They work similarly to book indexes - instead of scanning every page, you look up the topic in the index and jump directly to the relevant pages.

**Tradeoffs:**
- ✅ **Faster reads**: Queries with WHERE, JOIN, ORDER BY can be 10-1000x faster
- ❌ **Slower writes**: INSERT, UPDATE, DELETE must also update indexes
- ❌ **Storage overhead**: Indexes consume disk space (typically 10-50% of table size)
- ❌ **Maintenance overhead**: Indexes must be periodically rebuilt or analyzed

## Index Types in PostgreSQL

### B-tree Index (Default)

B-tree (Balanced Tree) is the default index type, suitable for most use cases.

**Best for:**
- Equality comparisons (`=`, `IN`)
- Range queries (`<`, `>`, `BETWEEN`)
- Pattern matching (`LIKE 'prefix%'`)
- Sorting (`ORDER BY`)
- MIN/MAX lookups

**Not good for:**
- Full-text search (use GIN instead)
- Pattern matching with leading wildcard (`LIKE '%suffix'`)
- Multi-dimensional data (use GiST instead)

```sql
-- Create B-tree index (explicit type, but B-tree is default)
CREATE INDEX idx_users_email ON users USING BTREE (email);

-- Default (B-tree is implicit)
CREATE INDEX idx_users_email ON users (email);

-- B-tree supports multiple columns (left-to-right)
CREATE INDEX idx_users_name ON users (last_name, first_name);

-- Works for: WHERE last_name = 'Smith'
-- Works for: WHERE last_name = 'Smith' AND first_name = 'John'
-- Does NOT work for: WHERE first_name = 'John' (missing leading column)
```

### Hash Index

Hash indexes are optimized for simple equality comparisons only.

**Best for:**
- Equality comparisons (`=`) only
- Exact match lookups

**Not good for:**
- Range queries
- Sorting
- Pattern matching

```sql
-- Create hash index
CREATE INDEX idx_users_id_hash ON users USING HASH (id);

-- Only works for:
SELECT * FROM users WHERE id = 123;

-- Does NOT work for:
SELECT * FROM users WHERE id > 100;  -- Range query
SELECT * FROM users WHERE id IN (1, 2, 3);  -- Multiple values
```

**Note:** Hash indexes were not WAL-logged until PostgreSQL 10, making them unsafe for replication. As of PostgreSQL 10+, they're safe but rarely needed - B-tree is usually faster or equivalent.

### GIN Index (Generalized Inverted Index)

GIN indexes are optimized for indexing composite values (arrays, JSONB, full-text search).

**Best for:**
- JSONB queries
- Array containment (`@>`, `&&`)
- Full-text search (tsvector)
- Multi-value columns

**Tradeoffs:**
- Slower to build than B-tree
- Slower for writes
- Larger storage
- Much faster for containment queries

```sql
-- Index JSONB column for fast queries
CREATE INDEX idx_users_metadata ON users USING GIN (metadata);

-- Supports queries like:
SELECT * FROM users WHERE metadata @> '{"role": "admin"}';
SELECT * FROM users WHERE metadata ? 'role';  -- Key exists
SELECT * FROM users WHERE metadata ?| ARRAY['role', 'status'];  -- Any key exists

-- Index array column
CREATE INDEX idx_posts_tags ON posts USING GIN (tags);

-- Supports:
SELECT * FROM posts WHERE tags @> ARRAY['postgresql'];  -- Contains
SELECT * FROM posts WHERE tags && ARRAY['sql', 'databases'];  -- Overlaps

-- Full-text search
CREATE INDEX idx_posts_search ON posts USING GIN (to_tsvector('english', body));

-- Supports:
SELECT * FROM posts
WHERE to_tsvector('english', body) @@ to_tsquery('english', 'postgresql & database');
```

### GiST Index (Generalized Search Tree)

GiST indexes are versatile and support many data types, including geometric types, range types, and full-text search.

**Best for:**
- Geometric data (points, circles, polygons)
- Range types (overlaps, contains)
- Full-text search (alternative to GIN)
- Nearest-neighbor searches

```sql
-- Index geometric data
CREATE INDEX idx_locations_point ON locations USING GIST (coordinates);

-- Supports:
SELECT * FROM locations WHERE coordinates <-> point '(40.7128, -74.0060)' < 10;

-- Index range types
CREATE INDEX idx_bookings_range ON room_bookings USING GIST (booked_during);

-- Supports:
SELECT * FROM room_bookings
WHERE booked_during && '[2025-11-16 10:00, 2025-11-16 12:00)'::tstzrange;

-- Exclusion constraint (prevent overlapping bookings)
CREATE TABLE room_bookings (
  id SERIAL PRIMARY KEY,
  room_id INTEGER,
  booked_during TSTZRANGE,
  EXCLUDE USING GIST (room_id WITH =, booked_during WITH &&)
);
```

### BRIN Index (Block Range Index)

BRIN indexes are extremely compact and efficient for very large tables with natural clustering.

**Best for:**
- Very large tables (billions of rows)
- Naturally ordered data (timestamps, sequential IDs)
- When data is physically clustered on disk

**Benefits:**
- Tiny storage (often < 1% of table size)
- Very fast to build
- Minimal write overhead

**Not good for:**
- Random data distribution
- Small tables
- Frequent updates that destroy clustering

```sql
-- Index timestamp column on large log table
CREATE INDEX idx_logs_created ON logs USING BRIN (created_at);

-- Supports range queries efficiently:
SELECT * FROM logs WHERE created_at > '2025-11-01';

-- Check pages per range (default 128)
CREATE INDEX idx_logs_created ON logs USING BRIN (created_at) WITH (pages_per_range = 256);
```

### SP-GiST Index (Space-Partitioned GiST)

SP-GiST indexes support partitioned search trees for non-balanced data structures.

**Best for:**
- Phone numbers
- IP addresses
- Geographic data with quadtrees
- Text with prefix trees

```sql
-- Index IP addresses
CREATE INDEX idx_requests_ip ON requests USING SPGIST (ip_address);

-- Index text with prefix search
CREATE INDEX idx_urls_path ON urls USING SPGIST (path);
```

## Creating Indexes

### Basic Index Creation

```sql
-- Single column index
CREATE INDEX idx_users_email ON users (email);

-- Multi-column index (column order matters!)
CREATE INDEX idx_users_name ON users (last_name, first_name);

-- Unique index (enforces uniqueness)
CREATE UNIQUE INDEX idx_users_username ON users (username);

-- Concurrent index creation (doesn't block writes)
CREATE INDEX CONCURRENTLY idx_users_email ON users (email);

-- Note: CONCURRENTLY takes longer but allows table writes during creation
```

### Index Naming Conventions

```sql
-- Good naming pattern: idx_{table}_{columns}
CREATE INDEX idx_users_email ON users (email);
CREATE INDEX idx_users_created_at ON users (created_at);
CREATE INDEX idx_posts_user_id ON posts (user_id);

-- For multi-column: idx_{table}_{col1}_{col2}
CREATE INDEX idx_users_last_first ON users (last_name, first_name);

-- For unique: uniq_{table}_{column}
CREATE UNIQUE INDEX uniq_users_email ON users (email);

-- For partial: idx_{table}_{column}_partial
CREATE INDEX idx_users_email_active ON users (email) WHERE status = 'active';
```

### Partial Indexes

Index only a subset of rows, reducing index size and improving performance.

```sql
-- Index only active users
CREATE INDEX idx_users_email_active ON users (email)
WHERE status = 'active';

-- Index only recent orders
CREATE INDEX idx_orders_recent ON orders (created_at)
WHERE created_at > '2025-01-01';

-- Index only NULL values (find rows missing data)
CREATE INDEX idx_users_missing_phone ON users (id)
WHERE phone IS NULL;

-- Index only expensive products
CREATE INDEX idx_products_expensive ON products (price)
WHERE price > 1000;

-- Partial unique index (unique only for subset)
CREATE UNIQUE INDEX uniq_users_email_active ON users (email)
WHERE status != 'deleted';
-- Allows duplicate emails for deleted users
```

### Expression Indexes

Index the result of an expression or function.

```sql
-- Case-insensitive search
CREATE INDEX idx_users_email_lower ON users (LOWER(email));

-- Supports:
SELECT * FROM users WHERE LOWER(email) = 'john@example.com';

-- Index date part
CREATE INDEX idx_orders_year ON orders (EXTRACT(YEAR FROM created_at));

-- Supports:
SELECT * FROM orders WHERE EXTRACT(YEAR FROM created_at) = 2025;

-- Index JSON field
CREATE INDEX idx_users_role ON users ((metadata->>'role'));

-- Supports:
SELECT * FROM users WHERE metadata->>'role' = 'admin';

-- Index calculated value
CREATE INDEX idx_products_price_with_tax ON products ((price * 1.1));
```

### Covering Indexes (INCLUDE)

Include additional columns in the index for index-only scans.

```sql
-- Regular index: only indexes user_id
CREATE INDEX idx_posts_user_id ON posts (user_id);

-- Query still needs to access table to get title:
SELECT title FROM posts WHERE user_id = 123;

-- Covering index: includes title in index (not searchable, but retrievable)
CREATE INDEX idx_posts_user_id_covering ON posts (user_id) INCLUDE (title, created_at);

-- Now index-only scan (faster, no table access):
SELECT title, created_at FROM posts WHERE user_id = 123;
```

## Multi-Column Indexes

### Column Order Matters

```sql
-- Index columns in order of selectivity (most selective first)
CREATE INDEX idx_users_country_city_name ON users (country, city, last_name);

-- Works efficiently for:
WHERE country = 'US'
WHERE country = 'US' AND city = 'NYC'
WHERE country = 'US' AND city = 'NYC' AND last_name = 'Smith'

-- Does NOT work for (missing leading column):
WHERE city = 'NYC'
WHERE last_name = 'Smith'
WHERE city = 'NYC' AND last_name = 'Smith'

-- Partially works (uses country part only):
WHERE country = 'US' AND last_name = 'Smith'
```

### When to Use Multi-Column vs Separate Indexes

```sql
-- Multi-column index (best for combined queries)
CREATE INDEX idx_orders_user_status ON orders (user_id, status);

-- Best for:
WHERE user_id = 123 AND status = 'completed'

-- Two separate indexes (PostgreSQL can combine them)
CREATE INDEX idx_orders_user_id ON orders (user_id);
CREATE INDEX idx_orders_status ON orders (status);

-- Best for:
WHERE user_id = 123  -- Uses first index
WHERE status = 'completed'  -- Uses second index
WHERE user_id = 123 OR status = 'completed'  -- Can use both (bitmap scan)

-- General rule:
-- - Multi-column: When columns are ALWAYS queried together
-- - Separate: When columns are queried independently
```

## Index Maintenance

### Checking Index Usage

```sql
-- Enable pg_stat_statements extension
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Find unused indexes (never used since last stats reset)
SELECT
  schemaname,
  tablename,
  indexname,
  idx_scan AS index_scans,
  pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
WHERE idx_scan = 0
  AND indexrelname NOT LIKE 'pg_toast%'
ORDER BY pg_relation_size(indexrelid) DESC;

-- Find indexes with low usage
SELECT
  schemaname,
  tablename,
  indexname,
  idx_scan AS scans,
  idx_tup_read AS tuples_read,
  idx_tup_fetch AS tuples_fetched,
  pg_size_pretty(pg_relation_size(indexrelid)) AS size
FROM pg_stat_user_indexes
WHERE idx_scan < 100  -- Adjust threshold
ORDER BY idx_scan ASC;

-- Check index bloat
SELECT
  schemaname,
  tablename,
  indexname,
  pg_size_pretty(pg_relation_size(indexrelid)) AS index_size,
  idx_scan,
  idx_tup_read,
  idx_tup_fetch
FROM pg_stat_user_indexes
ORDER BY pg_relation_size(indexrelid) DESC;
```

### Rebuilding Indexes

```sql
-- REINDEX rebuilds a single index
REINDEX INDEX idx_users_email;

-- REINDEX rebuilds all indexes on a table
REINDEX TABLE users;

-- REINDEX rebuilds all indexes in a database
REINDEX DATABASE myapp;

-- Concurrent rebuild (doesn't block writes)
REINDEX INDEX CONCURRENTLY idx_users_email;

-- Drop and recreate (alternative approach)
DROP INDEX CONCURRENTLY idx_users_email;
CREATE INDEX CONCURRENTLY idx_users_email ON users (email);
```

### VACUUM and ANALYZE

```sql
-- VACUUM reclaims dead tuple storage
VACUUM users;

-- VACUUM FULL rebuilds table completely (locks table)
VACUUM FULL users;

-- ANALYZE updates statistics for query planner
ANALYZE users;

-- VACUUM ANALYZE (both operations)
VACUUM ANALYZE users;

-- Autovacuum (enabled by default)
-- Automatically runs VACUUM and ANALYZE when needed
-- Check autovacuum settings:
SHOW autovacuum;
SHOW autovacuum_naptime;
```

## Query Optimization with EXPLAIN

### EXPLAIN Basics

```sql
-- Show query plan
EXPLAIN SELECT * FROM users WHERE email = 'john@example.com';

-- Show query plan with execution stats
EXPLAIN ANALYZE SELECT * FROM users WHERE email = 'john@example.com';

-- Show buffers (cache hits/misses)
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM users WHERE email = 'john@example.com';

-- Show query plan in JSON format
EXPLAIN (FORMAT JSON) SELECT * FROM users WHERE email = 'john@example.com';
```

### Reading EXPLAIN Output

```sql
EXPLAIN SELECT * FROM users WHERE email = 'john@example.com';

-- Example output:
-- Seq Scan on users  (cost=0.00..35.50 rows=1 width=100)
--   Filter: (email = 'john@example.com')

-- Seq Scan = Sequential scan (reads entire table, NO INDEX)
-- cost=0.00..35.50 = Startup cost..Total cost
-- rows=1 = Estimated rows returned
-- width=100 = Estimated average row size in bytes

-- After creating index:
CREATE INDEX idx_users_email ON users (email);

EXPLAIN SELECT * FROM users WHERE email = 'john@example.com';

-- Index Scan using idx_users_email on users  (cost=0.29..8.30 rows=1 width=100)
--   Index Cond: (email = 'john@example.com')

-- Index Scan = Uses index (much faster than Seq Scan)
```

### Common EXPLAIN Node Types

```sql
-- Sequential Scan (no index, scans entire table)
Seq Scan on users

-- Index Scan (uses index + table access)
Index Scan using idx_users_email on users

-- Index Only Scan (uses index only, no table access - fastest!)
Index Only Scan using idx_users_email_covering on users

-- Bitmap Index Scan (combines multiple indexes)
Bitmap Heap Scan on users
  -> Bitmap Index Scan on idx_users_email

-- Hash Join (join using hash table)
Hash Join
  -> Seq Scan on orders
  -> Hash
    -> Seq Scan on users

-- Nested Loop (join using nested loops)
Nested Loop
  -> Index Scan on users
  -> Index Scan on posts

-- Sort (explicit sorting)
Sort
  -> Seq Scan on users
```

### Index Selection Examples

```sql
-- Example 1: No index (Sequential Scan)
EXPLAIN SELECT * FROM users WHERE email = 'john@example.com';
-- Seq Scan on users  (cost=0.00..35.50 rows=1)
--   Filter: (email = 'john@example.com')

-- Solution: Create index
CREATE INDEX idx_users_email ON users (email);

-- Example 2: Index not used (function prevents index usage)
EXPLAIN SELECT * FROM users WHERE LOWER(email) = 'john@example.com';
-- Seq Scan on users  (cost=0.00..42.50 rows=1)
--   Filter: (lower(email) = 'john@example.com')

-- Solution: Create expression index
CREATE INDEX idx_users_email_lower ON users (LOWER(email));

-- Example 3: Leading wildcard prevents index usage
EXPLAIN SELECT * FROM users WHERE email LIKE '%@gmail.com';
-- Seq Scan on users  (cost=0.00..35.50 rows=10)
--   Filter: (email ~~ '%@gmail.com')

-- Solution: Use trigram index (pg_trgm extension)
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX idx_users_email_trgm ON users USING GIN (email gin_trgm_ops);

-- Example 4: Poor selectivity (index not worth it)
-- If 90% of rows match, PostgreSQL may choose Seq Scan over Index Scan
-- because reading entire table is faster than index + table lookups

EXPLAIN SELECT * FROM users WHERE status = 'active';
-- Seq Scan (if most users are active)

-- Solution: Partial index for minority case
CREATE INDEX idx_users_inactive ON users (status) WHERE status = 'inactive';
```

## Index Strategies by Use Case

### Primary Keys and Foreign Keys

```sql
-- Primary keys automatically create unique B-tree index
CREATE TABLE users (
  id SERIAL PRIMARY KEY  -- Automatically indexed
);

-- Foreign keys should ALWAYS be indexed
CREATE TABLE posts (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id)  -- NOT automatically indexed!
);

-- Create index on foreign key
CREATE INDEX idx_posts_user_id ON posts (user_id);
```

### Timestamps and Date Ranges

```sql
-- Index timestamp for recent data queries
CREATE INDEX idx_logs_created_at ON logs (created_at DESC);

-- BRIN index for very large time-series tables
CREATE INDEX idx_logs_created_brin ON logs USING BRIN (created_at);

-- Partial index for recent data only
CREATE INDEX idx_logs_recent ON logs (created_at)
WHERE created_at > '2025-01-01';
```

### Text Search

```sql
-- Prefix search (B-tree works)
CREATE INDEX idx_users_username ON users (username);
-- Supports: WHERE username LIKE 'john%'

-- Full-text search (GIN index)
CREATE INDEX idx_posts_search ON posts USING GIN (to_tsvector('english', body));
-- Supports: WHERE to_tsvector('english', body) @@ to_tsquery('postgresql & database')

-- Trigram search (substring matching)
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX idx_posts_title_trgm ON posts USING GIN (title gin_trgm_ops);
-- Supports: WHERE title ILIKE '%postgres%'
```

### JSON/JSONB Queries

```sql
-- GIN index on entire JSONB column
CREATE INDEX idx_users_metadata ON users USING GIN (metadata);

-- Supports:
WHERE metadata @> '{"role": "admin"}'
WHERE metadata ? 'role'
WHERE metadata ?| ARRAY['role', 'status']

-- Expression index on specific JSON field
CREATE INDEX idx_users_role ON users ((metadata->>'role'));

-- Supports:
WHERE metadata->>'role' = 'admin'

-- jsonb_path_ops (smaller, faster, but only supports @>)
CREATE INDEX idx_users_metadata_ops ON users USING GIN (metadata jsonb_path_ops);
```

### Arrays

```sql
-- GIN index for array containment
CREATE INDEX idx_posts_tags ON posts USING GIN (tags);

-- Supports:
WHERE tags @> ARRAY['postgresql']
WHERE tags && ARRAY['sql', 'databases']

-- B-tree index for array length
CREATE INDEX idx_posts_tag_count ON posts (array_length(tags, 1));
```

### Sorting and Pagination

```sql
-- Index for ORDER BY
CREATE INDEX idx_posts_created_desc ON posts (created_at DESC);

-- Supports efficient:
SELECT * FROM posts ORDER BY created_at DESC LIMIT 10;

-- Multi-column for complex sorting
CREATE INDEX idx_posts_status_created ON posts (status, created_at DESC);

-- Supports:
SELECT * FROM posts
WHERE status = 'published'
ORDER BY created_at DESC
LIMIT 10;
```

## Performance Best Practices

1. **Index foreign keys**: Always index foreign key columns
2. **Index WHERE clause columns**: Columns frequently in WHERE should be indexed
3. **Index JOIN columns**: Both sides of JOIN should have indexes
4. **Index ORDER BY columns**: Columns in ORDER BY benefit from indexes
5. **Use INCLUDE for covering indexes**: Include columns needed in SELECT
6. **Create partial indexes**: Index only rows you query
7. **Monitor index usage**: Drop unused indexes
8. **Use CONCURRENTLY for production**: Avoid table locks during index creation
9. **Rebuild bloated indexes**: REINDEX CONCURRENTLY periodically
10. **Don't over-index**: Each index slows writes, consumes storage

## AI Pair Programming Notes

**When discussing indexes in pair programming:**

1. **Always run EXPLAIN first**: Show the query plan before and after indexing
2. **Explain column order**: Multi-column index order is crucial
3. **Show index usage stats**: Query `pg_stat_user_indexes` to justify indexes
4. **Demonstrate partial indexes**: Much more efficient than full indexes
5. **Explain covering indexes**: Index-only scans are fastest
6. **Show expression indexes**: Functions in WHERE prevent index usage
7. **Discuss GIN vs GiST**: Different use cases for JSONB, arrays, full-text
8. **Use CONCURRENTLY in examples**: Production indexes shouldn't lock tables
9. **Mention index bloat**: Indexes need periodic maintenance
10. **Show the tradeoffs**: Faster reads vs slower writes

**Common index mistakes to catch:**
- Missing indexes on foreign keys
- Function in WHERE without expression index (`WHERE LOWER(email)` without `LOWER(email)` index)
- Leading wildcard without trigram index (`LIKE '%suffix'`)
- Too many indexes (every column indexed)
- Multi-column index with wrong column order
- Not using CONCURRENTLY in production
- Indexing low-cardinality columns (e.g., boolean with 90%/10% split)

## Next Steps

1. **06-TRANSACTIONS.md** - Transaction isolation and concurrency control
2. **08-PERFORMANCE.md** - Query optimization beyond indexes
3. **11-CONFIG-OPERATIONS.md** - PostgreSQL configuration for performance

## Additional Resources

- PostgreSQL Index Documentation: https://www.postgresql.org/docs/current/indexes.html
- Index Types: https://www.postgresql.org/docs/current/indexes-types.html
- EXPLAIN Guide: https://www.postgresql.org/docs/current/using-explain.html
- Index Maintenance: https://wiki.postgresql.org/wiki/Index_Maintenance
