# PostgreSQL Performance & Optimization

```yaml
id: postgresql_07_performance
topic: PostgreSQL
file_role: Query optimization, performance tuning, and monitoring
profile: intermediate_to_advanced
difficulty_level: advanced
kb_version: v3.1
prerequisites:
  - Indexes (05-INDEXES.md)
  - Transactions (06-TRANSACTIONS.md)
  - Queries (04-QUERIES.md)
related_topics:
  - Configuration (11-CONFIG-OPERATIONS.md)
  - Replication (10-REPLICATION.md)
embedding_keywords:
  - EXPLAIN ANALYZE
  - query optimization
  - pg_stat_statements
  - connection pooling
  - vacuum analyze
  - query plan
  - performance tuning
  - slow queries
  - buffer cache
last_reviewed: 2025-11-16
```

## Query Optimization with EXPLAIN

### EXPLAIN Basics

```sql
-- Show query plan (estimated)
EXPLAIN SELECT * FROM users WHERE email = 'john@example.com';

-- Show actual execution stats
EXPLAIN ANALYZE SELECT * FROM users WHERE email = 'john@example.com';

-- Show buffer usage (cache hits/misses)
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM users WHERE email = 'john@example.com';

-- Verbose output (more details)
EXPLAIN (ANALYZE, VERBOSE) SELECT * FROM users WHERE email = 'john@example.com';

-- JSON format (easier to parse programmatically)
EXPLAIN (ANALYZE, FORMAT JSON) SELECT * FROM users WHERE email = 'john@example.com';
```

### Reading EXPLAIN Output

```sql
EXPLAIN ANALYZE
SELECT * FROM users WHERE email = 'john@example.com';

-- Example output:
-- Index Scan using idx_users_email on users  (cost=0.29..8.30 rows=1 width=100)
--   (actual time=0.015..0.016 rows=1 loops=1)
--   Index Cond: (email = 'john@example.com')
-- Planning Time: 0.089 ms
-- Execution Time: 0.035 ms
```

**Key metrics:**
- `cost=0.29..8.30`: Startup cost..Total cost (arbitrary units)
- `rows=1`: Estimated rows returned
- `width=100`: Estimated average row size (bytes)
- `actual time=0.015..0.016`: Actual startup..total time (ms)
- `rows=1`: Actual rows returned
- `loops=1`: How many times this node executed

### Common Query Plan Nodes

```sql
-- Sequential Scan: Full table scan (slow for large tables)
Seq Scan on users  (cost=0.00..1724.00 rows=100000 width=100)
-- Solution: Add index on WHERE columns

-- Index Scan: Uses index + table lookups
Index Scan using idx_users_email on users  (cost=0.29..8.30 rows=1 width=100)
-- Good: Using index efficiently

-- Index Only Scan: Uses index only, no table access (fastest!)
Index Only Scan using idx_users_email_covering on users  (cost=0.29..4.31 rows=1 width=50)
-- Best: All data in index (covering index)

-- Bitmap Index Scan: Combines multiple indexes
Bitmap Heap Scan on users  (cost=12.75..123.45 rows=50 width=100)
  -> Bitmap Index Scan on idx_users_status  (cost=0.00..12.74 rows=50 width=0)

-- Hash Join: Fast for large tables
Hash Join  (cost=45.00..1234.56 rows=1000 width=200)
  Hash Cond: (posts.user_id = users.id)
  -> Seq Scan on posts
  -> Hash
    -> Seq Scan on users

-- Nested Loop: Good for small result sets
Nested Loop  (cost=0.29..24.56 rows=10 width=200)
  -> Index Scan on users
  -> Index Scan on posts

-- Merge Join: Good for sorted data
Merge Join  (cost=1234.56..2345.67 rows=5000 width=200)
  Merge Cond: (users.id = posts.user_id)
  -> Index Scan on users
  -> Index Scan on posts
```

### Optimization Examples

```sql
-- ❌ Slow: Function prevents index usage
EXPLAIN ANALYZE
SELECT * FROM users WHERE LOWER(email) = 'john@example.com';
-- Seq Scan on users  (cost=0.00..1724.00 rows=500 width=100)
--   Filter: (lower(email) = 'john@example.com')

-- ✅ Fast: Expression index
CREATE INDEX idx_users_email_lower ON users (LOWER(email));
EXPLAIN ANALYZE
SELECT * FROM users WHERE LOWER(email) = 'john@example.com';
-- Index Scan using idx_users_email_lower  (cost=0.29..8.30 rows=1 width=100)

-- ❌ Slow: OR conditions
EXPLAIN ANALYZE
SELECT * FROM users WHERE email = 'john@example.com' OR username = 'john';
-- Seq Scan on users  (cost=0.00..1724.00 rows=2 width=100)

-- ✅ Fast: UNION with separate indexed queries
EXPLAIN ANALYZE
(SELECT * FROM users WHERE email = 'john@example.com')
UNION
(SELECT * FROM users WHERE username = 'john');
-- Two index scans + union

-- ❌ Slow: SELECT *
SELECT * FROM users JOIN posts ON posts.user_id = users.id;

-- ✅ Fast: Select only needed columns
SELECT users.id, users.username, posts.title
FROM users JOIN posts ON posts.user_id = users.id;

-- ❌ Slow: Implicit join (Cartesian product)
SELECT * FROM users, posts WHERE users.id = posts.user_id;

-- ✅ Fast: Explicit JOIN
SELECT * FROM users JOIN posts ON posts.user_id = users.id;
```

## Slow Query Monitoring

### pg_stat_statements Extension

```sql
-- Enable extension
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Add to postgresql.conf:
-- shared_preload_libraries = 'pg_stat_statements'
-- pg_stat_statements.track = all
-- Then restart PostgreSQL

-- Find slowest queries
SELECT
  query,
  calls,
  total_exec_time,
  mean_exec_time,
  max_exec_time,
  rows
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;

-- Find most frequently called queries
SELECT
  query,
  calls,
  total_exec_time,
  mean_exec_time
FROM pg_stat_statements
ORDER BY calls DESC
LIMIT 10;

-- Find queries with most total time
SELECT
  query,
  calls,
  total_exec_time,
  mean_exec_time,
  (total_exec_time / sum(total_exec_time) OVER ()) * 100 AS pct_total_time
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 10;

-- Reset statistics
SELECT pg_stat_statements_reset();
```

### Logging Slow Queries

```conf
# In postgresql.conf

# Log queries slower than 100ms
log_min_duration_statement = 100

# Log all queries (for debugging only!)
log_statement = 'all'

# Log query plans for slow queries
auto_explain.log_min_duration = 1000
auto_explain.log_analyze = true
auto_explain.log_buffers = true

# Log location
log_directory = 'log'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
logging_collector = on
```

### Monitoring Active Queries

```sql
-- Show all active queries
SELECT
  pid,
  now() - query_start AS duration,
  state,
  query
FROM pg_stat_activity
WHERE state != 'idle'
ORDER BY duration DESC;

-- Kill long-running query
SELECT pg_terminate_backend(12345);  -- Replace with PID

-- Find queries waiting for locks
SELECT
  pid,
  wait_event_type,
  wait_event,
  state,
  query
FROM pg_stat_activity
WHERE wait_event IS NOT NULL;
```

## Memory Configuration

### Key Memory Settings

```conf
# postgresql.conf

# Shared Buffers: Shared memory cache for data pages
# Recommendation: 25% of total RAM (up to 8-16GB)
shared_buffers = 4GB

# Effective Cache Size: Total memory available for caching
# Recommendation: 50-75% of total RAM
# (doesn't allocate memory, just tells planner how much OS will cache)
effective_cache_size = 12GB

# Work Memory: Memory for sorts, hashes (per operation)
# Recommendation: (Total RAM * 0.25) / max_connections
# Be careful: multiple operations can use work_mem simultaneously!
work_mem = 16MB

# Maintenance Work Memory: Memory for VACUUM, CREATE INDEX, etc.
# Recommendation: 5-10% of total RAM
maintenance_work_mem = 1GB

# WAL Buffers: Buffer for write-ahead log
# Recommendation: -1 (auto, 1/32 of shared_buffers up to 16MB)
wal_buffers = -1
```

### Calculate Optimal Settings

```sql
-- Check current settings
SHOW shared_buffers;
SHOW effective_cache_size;
SHOW work_mem;
SHOW maintenance_work_mem;

-- For a server with 16GB RAM and 100 max_connections:
shared_buffers = 4GB              -- 25% of RAM
effective_cache_size = 12GB       -- 75% of RAM
work_mem = 40MB                   -- (16GB * 0.25) / 100
maintenance_work_mem = 1GB        -- ~6% of RAM
```

## Connection Management

### Connection Pooling

PostgreSQL creates a new process for each connection - expensive!

**PgBouncer Configuration:**

```ini
# /etc/pgbouncer/pgbouncer.ini

[databases]
myapp = host=localhost port=5432 dbname=myapp

[pgbouncer]
listen_addr = 127.0.0.1
listen_port = 6432

# Pool modes:
# - session: Connection held for entire session (default)
# - transaction: Connection held for transaction only (recommended)
# - statement: Connection held for single statement (aggressive)
pool_mode = transaction

# Limits
max_client_conn = 1000          # Max client connections
default_pool_size = 25          # Connections per database
reserve_pool_size = 5           # Emergency reserve
max_db_connections = 50         # Actual PostgreSQL connections
```

**Application-Level Pooling (Node.js):**

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

// Use pool
const result = await pool.query('SELECT * FROM users WHERE id = $1', [1]);
```

### Connection Limits

```sql
-- Check current connections
SELECT count(*) FROM pg_stat_activity;

-- Check connection limit
SHOW max_connections;

-- Set connection limit per database
ALTER DATABASE myapp CONNECTION LIMIT 50;

-- Set connection limit per user
ALTER USER appuser CONNECTION LIMIT 10;

-- Monitor connection usage
SELECT
  datname,
  count(*) AS connections,
  max_conn,
  round((count(*)::float / max_conn) * 100, 2) AS pct_used
FROM pg_stat_activity
JOIN (
  SELECT datname, setting::int AS max_conn
  FROM pg_database
  CROSS JOIN (SELECT setting FROM pg_settings WHERE name = 'max_connections') s
) db_info USING (datname)
WHERE datname IS NOT NULL
GROUP BY datname, max_conn
ORDER BY pct_used DESC;
```

## VACUUM and ANALYZE

### Understanding VACUUM

VACUUM reclaims storage from dead tuples created by UPDATE/DELETE operations (due to MVCC).

```sql
-- VACUUM single table
VACUUM users;

-- VACUUM with ANALYZE (update statistics too)
VACUUM ANALYZE users;

-- VACUUM FULL: Rebuilds table, reclaims maximum space (locks table!)
VACUUM FULL users;

-- VERBOSE output
VACUUM VERBOSE users;

-- Check table bloat
SELECT
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size,
  n_dead_tup,
  n_live_tup,
  round(n_dead_tup * 100.0 / NULLIF(n_live_tup + n_dead_tup, 0), 2) AS dead_pct
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC;
```

### Understanding ANALYZE

ANALYZE updates statistics used by the query planner.

```sql
-- ANALYZE single table
ANALYZE users;

-- ANALYZE all tables
ANALYZE;

-- Check when tables were last analyzed
SELECT
  schemaname,
  tablename,
  last_analyze,
  last_autoanalyze,
  n_tup_ins + n_tup_upd + n_tup_del AS total_changes
FROM pg_stat_user_tables
ORDER BY last_analyze ASC NULLS FIRST;
```

### Autovacuum Configuration

```conf
# postgresql.conf

# Enable autovacuum (should always be on!)
autovacuum = on

# How often to check for autovacuum (default: 1min)
autovacuum_naptime = 1min

# Vacuum when 20% of rows are dead or 50 dead rows (whichever first)
autovacuum_vacuum_scale_factor = 0.2
autovacuum_vacuum_threshold = 50

# Analyze when 10% of rows change or 50 rows change
autovacuum_analyze_scale_factor = 0.1
autovacuum_analyze_threshold = 50

# Max autovacuum workers (parallel vacuum operations)
autovacuum_max_workers = 3

# Memory for autovacuum
autovacuum_work_mem = -1  # Uses maintenance_work_mem

# Per-table autovacuum settings
ALTER TABLE users SET (
  autovacuum_vacuum_scale_factor = 0.1,
  autovacuum_vacuum_threshold = 100
);
```

## Write-Ahead Log (WAL) Configuration

```conf
# postgresql.conf

# WAL level:
# - minimal: Minimal logging (no replication)
# - replica: Supports replication (default)
# - logical: Supports logical replication
wal_level = replica

# Size of WAL files before checkpoint
max_wal_size = 1GB
min_wal_size = 80MB

# Checkpoint timeout (force checkpoint after this time)
checkpoint_timeout = 5min

# Checkpoint completion target (spread checkpoint I/O)
checkpoint_completion_target = 0.9

# WAL segment size (compile-time option, usually 16MB)
# wal_segment_size = 16MB

# WAL buffers (-1 = auto, 1/32 of shared_buffers)
wal_buffers = -1

# Sync WAL to disk:
# - fsync: Sync every commit (safest, slowest)
# - fdatasync: Sync data only, not metadata (faster)
# - open_sync: Open files with O_SYNC (platform-dependent)
wal_sync_method = fsync

# Commit delay (group commits together)
commit_delay = 0               # Microseconds (0 = disabled)
commit_siblings = 5            # Min concurrent transactions for delay
```

## Query Optimization Techniques

### 1. Use Prepared Statements

```javascript
// ❌ Vulnerable to SQL injection, re-parses query every time
const email = req.body.email;
const result = await pool.query(`SELECT * FROM users WHERE email = '${email}'`);

// ✅ Safe from SQL injection, query plan cached
const result = await pool.query(
  'SELECT * FROM users WHERE email = $1',
  [email]
);
```

### 2. Batch Operations

```sql
-- ❌ Slow: Individual inserts
INSERT INTO users (username) VALUES ('alice');
INSERT INTO users (username) VALUES ('bob');
INSERT INTO users (username) VALUES ('charlie');
-- 3 round trips + 3 transaction commits

-- ✅ Fast: Single batch insert
INSERT INTO users (username) VALUES
  ('alice'),
  ('bob'),
  ('charlie');
-- 1 round trip + 1 transaction commit

-- ✅ Fast: COPY for bulk imports
COPY users (username, email) FROM STDIN WITH CSV;
alice,alice@example.com
bob,bob@example.com
charlie,charlie@example.com
\.
```

### 3. Limit Result Sets

```sql
-- ❌ Slow: Returns all rows
SELECT * FROM posts ORDER BY created_at DESC;

-- ✅ Fast: Returns only what's needed
SELECT * FROM posts ORDER BY created_at DESC LIMIT 20;

-- ✅ Better: Cursor pagination (faster for deep pages)
SELECT * FROM posts
WHERE (created_at, id) < ('2025-11-16 10:00:00', 12345)
ORDER BY created_at DESC, id DESC
LIMIT 20;
```

### 4. Avoid N+1 Queries

```javascript
// ❌ N+1 queries: 1 for users + N for posts
const users = await pool.query('SELECT * FROM users');
for (const user of users.rows) {
  const posts = await pool.query(
    'SELECT * FROM posts WHERE user_id = $1',
    [user.id]
  );
  user.posts = posts.rows;
}

// ✅ Single query with JOIN
const result = await pool.query(`
  SELECT
    users.*,
    json_agg(posts.*) AS posts
  FROM users
  LEFT JOIN posts ON posts.user_id = users.id
  GROUP BY users.id
`);
```

### 5. Use Appropriate Data Types

```sql
-- ❌ Inefficient: TEXT for IDs
CREATE TABLE users (
  id TEXT PRIMARY KEY,  -- Larger storage, slower comparisons
  age TEXT              -- Can't use numeric operators
);

-- ✅ Efficient: Appropriate types
CREATE TABLE users (
  id INTEGER PRIMARY KEY,  -- Compact, fast comparisons
  age INTEGER              -- Enables numeric operations
);

-- ✅ UUID for distributed systems
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid()
);
```

### 6. Denormalize When Appropriate

```sql
-- Normalized (requires JOIN)
SELECT users.username, COUNT(posts.id)
FROM users
LEFT JOIN posts ON posts.user_id = users.id
GROUP BY users.id;

-- Denormalized (fast lookup, needs maintenance)
ALTER TABLE users ADD COLUMN post_count INTEGER DEFAULT 0;

CREATE OR REPLACE FUNCTION update_post_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE users SET post_count = post_count + 1 WHERE id = NEW.user_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE users SET post_count = post_count - 1 WHERE id = OLD.user_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_post_count
AFTER INSERT OR DELETE ON posts
FOR EACH ROW EXECUTE FUNCTION update_post_count();

-- Fast query
SELECT username, post_count FROM users;
```

### 7. Use Materialized Views

```sql
-- Expensive query (runs every time)
SELECT
  category,
  COUNT(*) AS product_count,
  AVG(price) AS avg_price,
  SUM(stock) AS total_stock
FROM products
GROUP BY category;

-- Materialized view (pre-computed, fast)
CREATE MATERIALIZED VIEW product_stats AS
SELECT
  category,
  COUNT(*) AS product_count,
  AVG(price) AS avg_price,
  SUM(stock) AS total_stock
FROM products
GROUP BY category;

-- Fast query
SELECT * FROM product_stats;

-- Refresh when data changes
REFRESH MATERIALIZED VIEW product_stats;

-- Concurrent refresh (doesn't block reads)
REFRESH MATERIALIZED VIEW CONCURRENTLY product_stats;
```

## Monitoring and Diagnostics

### Key Metrics to Monitor

```sql
-- Database size
SELECT
  datname,
  pg_size_pretty(pg_database_size(datname)) AS size
FROM pg_database
ORDER BY pg_database_size(datname) DESC;

-- Table sizes
SELECT
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS total_size,
  pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) AS table_size,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) -
    pg_relation_size(schemaname||'.'||tablename)) AS index_size
FROM pg_tables
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Cache hit ratio (should be > 99%)
SELECT
  sum(heap_blks_read) AS heap_read,
  sum(heap_blks_hit) AS heap_hit,
  round(sum(heap_blks_hit) * 100.0 / NULLIF(sum(heap_blks_hit) + sum(heap_blks_read), 0), 2) AS cache_hit_ratio
FROM pg_statio_user_tables;

-- Index usage
SELECT
  schemaname,
  tablename,
  indexname,
  idx_scan,
  idx_tup_read,
  idx_tup_fetch
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;

-- Transaction rate
SELECT
  datname,
  xact_commit,
  xact_rollback,
  round(xact_commit * 100.0 / NULLIF(xact_commit + xact_rollback, 0), 2) AS commit_ratio
FROM pg_stat_database;
```

## AI Pair Programming Notes

**When optimizing PostgreSQL performance:**

1. **Always start with EXPLAIN ANALYZE**: Show actual query performance before optimization
2. **Measure before and after**: Quantify improvements with concrete metrics
3. **Focus on slow queries first**: Use pg_stat_statements to find bottlenecks
4. **Show index usage**: Query pg_stat_user_indexes to verify indexes are used
5. **Demonstrate pooling**: Connection pooling is critical for scalability
6. **Explain VACUUM/ANALYZE**: MVCC requires regular maintenance
7. **Discuss memory settings**: shared_buffers and work_mem significantly impact performance
8. **Show batching**: Single batch INSERT vs multiple individual INSERTs
9. **Mention prepared statements**: Both for security and performance
10. **Monitor cache hit ratio**: Should be > 99% for good performance

**Common performance mistakes to catch:**
- SELECT * instead of listing needed columns
- Missing indexes on foreign keys
- N+1 query patterns
- No connection pooling
- Functions in WHERE without expression indexes
- Large transactions holding locks
- Not using LIMIT on unbounded queries
- Ignoring autovacuum warnings

## Next Steps

1. **08-PERFORMANCE.md** - Advanced performance topics (partitioning, parallel queries)
2. **10-REPLICATION.md** - Scaling with replication
3. **11-CONFIG-OPERATIONS.md** - Production PostgreSQL configuration

## Additional Resources

- PostgreSQL Performance Tuning: https://wiki.postgresql.org/wiki/Performance_Optimization
- EXPLAIN Tutorial: https://www.postgresql.org/docs/current/using-explain.html
- pg_stat_statements: https://www.postgresql.org/docs/current/pgstatstatements.html
- PgBouncer: https://www.pgbouncer.org/
