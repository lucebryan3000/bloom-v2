# PostgreSQL Advanced Topics

```yaml
id: postgresql_08_advanced_topics
topic: PostgreSQL
file_role: Advanced features (partitioning, parallel queries, FDW, full-text search)
profile: advanced
difficulty_level: advanced
kb_version: v3.1
prerequisites:
  - Indexes (05-INDEXES.md)
  - Performance (07-PERFORMANCE.md)
  - Queries (04-QUERIES.md)
related_topics:
  - Replication (09-REPLICATION.md)
  - Configuration (11-CONFIG-OPERATIONS.md)
embedding_keywords:
  - table partitioning
  - parallel query
  - foreign data wrapper
  - full-text search
  - materialized views
  - inheritance
  - listen notify
  - pg_cron
last_reviewed: 2025-11-16
```

## Table Partitioning

Partitioning splits large tables into smaller, more manageable pieces while maintaining a single logical table.

### Benefits of Partitioning

- **Query performance**: Partition pruning eliminates scanning irrelevant partitions
- **Bulk operations**: Drop entire partitions instead of DELETE
- **Maintenance**: VACUUM/ANALYZE smaller partitions faster
- **Archival**: Move old partitions to slower storage

### Range Partitioning

Most common for time-series data.

```sql
-- Create partitioned table
CREATE TABLE logs (
  id BIGSERIAL,
  user_id INTEGER,
  action VARCHAR(50),
  created_at TIMESTAMP NOT NULL,
  metadata JSONB
) PARTITION BY RANGE (created_at);

-- Create partitions
CREATE TABLE logs_2025_01 PARTITION OF logs
  FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');

CREATE TABLE logs_2025_02 PARTITION OF logs
  FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');

CREATE TABLE logs_2025_03 PARTITION OF logs
  FOR VALUES FROM ('2025-03-01') TO ('2025-04-01');

-- Create default partition (for data outside ranges)
CREATE TABLE logs_default PARTITION OF logs DEFAULT;

-- Create indexes on partitions
CREATE INDEX ON logs_2025_01 (user_id);
CREATE INDEX ON logs_2025_02 (user_id);
CREATE INDEX ON logs_2025_03 (user_id);

-- Query automatically uses partition pruning
EXPLAIN SELECT * FROM logs WHERE created_at >= '2025-02-01' AND created_at < '2025-03-01';
-- Only scans logs_2025_02 partition!
```

### List Partitioning

Partition by discrete values.

```sql
-- Create partitioned table
CREATE TABLE sales (
  id SERIAL,
  product_id INTEGER,
  region VARCHAR(10) NOT NULL,
  amount NUMERIC(10, 2),
  sale_date DATE
) PARTITION BY LIST (region);

-- Create partitions by region
CREATE TABLE sales_us PARTITION OF sales
  FOR VALUES IN ('US');

CREATE TABLE sales_eu PARTITION OF sales
  FOR VALUES IN ('UK', 'FR', 'DE');

CREATE TABLE sales_asia PARTITION OF sales
  FOR VALUES IN ('JP', 'CN', 'IN');
```

### Hash Partitioning

Distribute data evenly across partitions.

```sql
-- Create partitioned table
CREATE TABLE users (
  id SERIAL,
  username VARCHAR(50),
  email VARCHAR(255)
) PARTITION BY HASH (id);

-- Create hash partitions
CREATE TABLE users_p0 PARTITION OF users
  FOR VALUES WITH (MODULUS 4, REMAINDER 0);

CREATE TABLE users_p1 PARTITION OF users
  FOR VALUES WITH (MODULUS 4, REMAINDER 1);

CREATE TABLE users_p2 PARTITION OF users
  FOR VALUES WITH (MODULUS 4, REMAINDER 2);

CREATE TABLE users_p3 PARTITION OF users
  FOR VALUES WITH (MODULUS 4, REMAINDER 3);
```

### Automatic Partition Creation

```sql
-- Function to create monthly partitions
CREATE OR REPLACE FUNCTION create_monthly_partition(
  table_name TEXT,
  partition_date DATE
) RETURNS VOID AS $$
DECLARE
  partition_name TEXT;
  start_date DATE;
  end_date DATE;
BEGIN
  partition_name := table_name || '_' || to_char(partition_date, 'YYYY_MM');
  start_date := date_trunc('month', partition_date);
  end_date := start_date + INTERVAL '1 month';

  EXECUTE format(
    'CREATE TABLE IF NOT EXISTS %I PARTITION OF %I FOR VALUES FROM (%L) TO (%L)',
    partition_name, table_name, start_date, end_date
  );

  EXECUTE format(
    'CREATE INDEX IF NOT EXISTS %I ON %I (user_id)',
    partition_name || '_user_id_idx', partition_name
  );
END;
$$ LANGUAGE plpgsql;

-- Create partitions for next 12 months
SELECT create_monthly_partition('logs', generate_series(
  date_trunc('month', CURRENT_DATE),
  date_trunc('month', CURRENT_DATE) + INTERVAL '11 months',
  INTERVAL '1 month'
));
```

### Detaching and Dropping Partitions

```sql
-- Detach partition (makes it a standalone table)
ALTER TABLE logs DETACH PARTITION logs_2024_01;

-- Can now archive or drop the detached table
DROP TABLE logs_2024_01;

-- Or attach it back
ALTER TABLE logs ATTACH PARTITION logs_2024_01
  FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
```

## Parallel Query Execution

PostgreSQL can use multiple CPUs to execute queries faster.

### Enabling Parallel Queries

```conf
# postgresql.conf

# Maximum parallel workers per query
max_parallel_workers_per_gather = 4

# Maximum parallel workers system-wide
max_parallel_workers = 8

# Minimum table size to consider parallelism (default 8MB)
min_parallel_table_scan_size = 8MB

# Minimum index size to consider parallelism (default 512kB)
min_parallel_index_scan_size = 512kB

# Cost threshold for parallel query (lower = more parallel)
parallel_setup_cost = 1000
parallel_tuple_cost = 0.1
```

### Parallel Query Examples

```sql
-- Sequential scan (single worker)
EXPLAIN SELECT COUNT(*) FROM large_table;
-- Aggregate
--   -> Seq Scan on large_table

-- Parallel sequential scan (multiple workers)
SET max_parallel_workers_per_gather = 4;
EXPLAIN SELECT COUNT(*) FROM large_table;
-- Finalize Aggregate
--   -> Gather
--     Workers Planned: 4
--     -> Partial Aggregate
--       -> Parallel Seq Scan on large_table

-- Parallel index scan
EXPLAIN SELECT * FROM large_table WHERE indexed_column > 1000000;
-- Gather
--   Workers Planned: 4
--   -> Parallel Index Scan on idx_large_table

-- Parallel join
EXPLAIN SELECT * FROM large_table1 JOIN large_table2 USING (id);
-- Gather
--   Workers Planned: 4
--   -> Parallel Hash Join
--     -> Parallel Seq Scan on large_table1
--     -> Parallel Hash
--       -> Parallel Seq Scan on large_table2
```

### Force or Disable Parallelism

```sql
-- Disable parallelism for specific query
SET max_parallel_workers_per_gather = 0;
SELECT * FROM large_table;
SET max_parallel_workers_per_gather TO DEFAULT;

-- Force parallelism (use with caution)
SET parallel_setup_cost = 0;
SET parallel_tuple_cost = 0;
SELECT * FROM large_table;
```

## Full-Text Search

PostgreSQL has built-in full-text search capabilities.

### Basic Full-Text Search

```sql
-- Create sample data
CREATE TABLE documents (
  id SERIAL PRIMARY KEY,
  title TEXT,
  body TEXT
);

INSERT INTO documents (title, body) VALUES
  ('PostgreSQL Tutorial', 'Learn PostgreSQL database fundamentals and advanced topics'),
  ('SQL Basics', 'Introduction to SQL queries and database design'),
  ('Advanced PostgreSQL', 'Deep dive into PostgreSQL internals and optimization');

-- Basic full-text search with to_tsvector and to_tsquery
SELECT title
FROM documents
WHERE to_tsvector('english', body) @@ to_tsquery('english', 'postgresql & database');
-- Returns: 'PostgreSQL Tutorial'

-- Ranking results by relevance
SELECT
  title,
  ts_rank(to_tsvector('english', body), to_tsquery('english', 'postgresql | sql')) AS rank
FROM documents
WHERE to_tsvector('english', body) @@ to_tsquery('english', 'postgresql | sql')
ORDER BY rank DESC;
```

### Creating a Search Column

```sql
-- Add tsvector column
ALTER TABLE documents ADD COLUMN search_vector tsvector;

-- Populate search vector
UPDATE documents SET search_vector =
  to_tsvector('english', coalesce(title,'') || ' ' || coalesce(body,''));

-- Create GIN index for fast search
CREATE INDEX idx_documents_search ON documents USING GIN (search_vector);

-- Auto-update search vector on insert/update
CREATE OR REPLACE FUNCTION documents_search_trigger()
RETURNS TRIGGER AS $$
BEGIN
  NEW.search_vector := to_tsvector('english', coalesce(NEW.title,'') || ' ' || coalesce(NEW.body,''));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trig_documents_search
BEFORE INSERT OR UPDATE ON documents
FOR EACH ROW EXECUTE FUNCTION documents_search_trigger();

-- Fast full-text search
SELECT title, body
FROM documents
WHERE search_vector @@ to_tsquery('english', 'postgresql & (tutorial | advanced)');
```

### Search Query Syntax

```sql
-- AND operator (&)
to_tsquery('postgresql & database');
-- Matches documents containing both "postgresql" and "database"

-- OR operator (|)
to_tsquery('postgresql | mysql');
-- Matches documents containing either "postgresql" or "mysql"

-- NOT operator (!)
to_tsquery('postgresql & !mysql');
-- Matches documents containing "postgresql" but not "mysql"

-- Phrase search (<->)
to_tsquery('postgresql <-> database');
-- Matches "postgresql" followed by "database"

-- Proximity search (<N>)
to_tsquery('postgresql <2> database');
-- Matches "postgresql" within 2 words of "database"

-- Prefix search (:*)
to_tsquery('post:*');
-- Matches "post", "posts", "postgresql", "postfix", etc.

-- Weighted search (A:1, B:2, C:3, D:4)
to_tsvector('postgresql:A database:B tutorial:C');
-- Higher weight (A) = more important
```

## Foreign Data Wrappers (FDW)

Query external data sources as if they were PostgreSQL tables.

### PostgreSQL Foreign Data Wrapper

```sql
-- Install postgres_fdw extension
CREATE EXTENSION IF NOT EXISTS postgres_fdw;

-- Create foreign server
CREATE SERVER remote_db
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (host 'remote-host.example.com', port '5432', dbname 'remotedb');

-- Create user mapping
CREATE USER MAPPING FOR current_user
SERVER remote_db
OPTIONS (user 'remote_user', password 'remote_pass');

-- Import foreign schema
IMPORT FOREIGN SCHEMA public
FROM SERVER remote_db
INTO public;

-- Or create specific foreign table
CREATE FOREIGN TABLE remote_users (
  id INTEGER,
  username VARCHAR(50),
  email VARCHAR(255)
)
SERVER remote_db
OPTIONS (schema_name 'public', table_name 'users');

-- Query foreign table
SELECT * FROM remote_users WHERE username = 'john';

-- Join local and remote tables
SELECT
  local_orders.id,
  remote_users.username
FROM local_orders
JOIN remote_users ON remote_users.id = local_orders.user_id;
```

### File FDW (CSV files)

```sql
-- Install file_fdw extension
CREATE EXTENSION IF NOT EXISTS file_fdw;

-- Create foreign server
CREATE SERVER csv_server FOREIGN DATA WRAPPER file_fdw;

-- Create foreign table for CSV
CREATE FOREIGN TABLE import_users (
  username VARCHAR(50),
  email VARCHAR(255),
  created_at DATE
)
SERVER csv_server
OPTIONS (filename '/path/to/users.csv', format 'csv', header 'true');

-- Query CSV as table
SELECT * FROM import_users WHERE created_at > '2025-01-01';

-- Import data from CSV
INSERT INTO users (username, email, created_at)
SELECT username, email, created_at FROM import_users;
```

## Asynchronous Notifications (LISTEN/NOTIFY)

Real-time event notification between database sessions.

```sql
-- Session 1: Listen for notifications
LISTEN order_created;

-- Session 2: Send notification
NOTIFY order_created, 'order_id:12345';

-- Session 1 receives notification

-- Or use with triggers
CREATE OR REPLACE FUNCTION notify_order_created()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM pg_notify('order_created', json_build_object(
    'id', NEW.id,
    'user_id', NEW.user_id,
    'total', NEW.total
  )::text);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_notify_order
AFTER INSERT ON orders
FOR EACH ROW EXECUTE FUNCTION notify_order_created();

-- Application code (Node.js example)
const client = new pg.Client();
await client.connect();

client.on('notification', (msg) => {
  const payload = JSON.parse(msg.payload);
  console.log('New order:', payload);
  // Trigger real-time update to frontend
});

await client.query('LISTEN order_created');
```

## Scheduled Jobs (pg_cron)

Schedule database jobs directly in PostgreSQL.

```sql
-- Install pg_cron extension
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Add to postgresql.conf:
-- shared_preload_libraries = 'pg_cron'
-- cron.database_name = 'myapp'

-- Schedule daily cleanup job (every day at 3 AM)
SELECT cron.schedule(
  'daily-cleanup',
  '0 3 * * *',
  'DELETE FROM logs WHERE created_at < NOW() - INTERVAL ''90 days'''
);

-- Schedule hourly aggregation (every hour)
SELECT cron.schedule(
  'hourly-stats',
  '0 * * * *',
  'REFRESH MATERIALIZED VIEW CONCURRENTLY hourly_stats'
);

-- View scheduled jobs
SELECT * FROM cron.job;

-- View job run history
SELECT * FROM cron.job_run_details ORDER BY start_time DESC LIMIT 10;

-- Unschedule job
SELECT cron.unschedule('daily-cleanup');
```

## Materialized Views

Pre-computed views stored on disk.

```sql
-- Create materialized view
CREATE MATERIALIZED VIEW product_stats AS
SELECT
  category,
  COUNT(*) AS product_count,
  AVG(price) AS avg_price,
  MIN(price) AS min_price,
  MAX(price) AS max_price
FROM products
GROUP BY category;

-- Create index on materialized view
CREATE INDEX ON product_stats (category);

-- Query materialized view (fast!)
SELECT * FROM product_stats WHERE category = 'Electronics';

-- Refresh materialized view
REFRESH MATERIALIZED VIEW product_stats;

-- Concurrent refresh (doesn't block reads)
CREATE UNIQUE INDEX ON product_stats (category);
REFRESH MATERIALIZED VIEW CONCURRENTLY product_stats;

-- Auto-refresh with trigger
CREATE OR REPLACE FUNCTION refresh_product_stats()
RETURNS TRIGGER AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY product_stats;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_refresh_stats
AFTER INSERT OR UPDATE OR DELETE ON products
FOR EACH STATEMENT EXECUTE FUNCTION refresh_product_stats();
```

## Table Inheritance (Legacy Feature)

Note: Declarative partitioning (covered earlier) is preferred over inheritance for new applications.

```sql
-- Parent table
CREATE TABLE vehicles (
  id SERIAL PRIMARY KEY,
  make VARCHAR(50),
  model VARCHAR(50),
  year INTEGER
);

-- Child tables inherit from parent
CREATE TABLE cars (
  num_doors INTEGER
) INHERITS (vehicles);

CREATE TABLE trucks (
  bed_length NUMERIC(5, 2)
) INHERITS (vehicles);

-- Insert into child tables
INSERT INTO cars (make, model, year, num_doors)
VALUES ('Toyota', 'Camry', 2025, 4);

INSERT INTO trucks (make, model, year, bed_length)
VALUES ('Ford', 'F-150', 2025, 6.5);

-- Query parent table (includes all child tables)
SELECT * FROM vehicles;
-- Returns both cars and trucks

-- Query only parent table (exclude children)
SELECT * FROM ONLY vehicles;
-- Returns nothing (no rows in parent table directly)

-- Query specific child table
SELECT * FROM cars;
-- Returns only cars
```

## JSON Operators and Functions

```sql
-- Create table with JSONB
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100),
  metadata JSONB
);

INSERT INTO users (name, metadata) VALUES
  ('Alice', '{"age": 30, "city": "NYC", "hobbies": ["reading", "coding"]}'),
  ('Bob', '{"age": 25, "city": "LA", "hobbies": ["gaming"]}');

-- JSON operators
SELECT metadata->'age' FROM users;              -- Returns JSON
SELECT metadata->>'age' FROM users;             -- Returns text
SELECT metadata->'hobbies'->0 FROM users;       -- First hobby (JSON)
SELECT metadata->'hobbies'->>0 FROM users;      -- First hobby (text)
SELECT metadata#>'{hobbies,0}' FROM users;      -- Path notation (JSON)
SELECT metadata#>>'{hobbies,0}' FROM users;     -- Path notation (text)

-- JSON functions
SELECT jsonb_array_length(metadata->'hobbies') FROM users;
SELECT jsonb_object_keys(metadata) FROM users;
SELECT jsonb_each(metadata) FROM users;

-- JSON containment
SELECT * FROM users WHERE metadata @> '{"city": "NYC"}';
SELECT * FROM users WHERE metadata->'hobbies' @> '["coding"]';

-- JSON key existence
SELECT * FROM users WHERE metadata ? 'age';
SELECT * FROM users WHERE metadata ?| ARRAY['age', 'city'];  -- Any key
SELECT * FROM users WHERE metadata ?& ARRAY['age', 'city'];  -- All keys

-- JSON aggregation
SELECT jsonb_agg(name) FROM users;
SELECT jsonb_object_agg(name, metadata) FROM users;

-- JSON build functions
SELECT jsonb_build_object('name', name, 'age', metadata->>'age') FROM users;
SELECT jsonb_build_array(name, metadata->>'age') FROM users;
```

## AI Pair Programming Notes

**When working with advanced PostgreSQL features:**

1. **Explain partitioning strategy**: Range vs List vs Hash, when to use each
2. **Show partition pruning**: Demonstrate EXPLAIN output with partition pruning
3. **Discuss parallel query limits**: Not all queries benefit from parallelism
4. **Demonstrate FTS ranking**: Show ts_rank for relevance scoring
5. **Explain FDW use cases**: When to query remote data vs replication
6. **Show LISTEN/NOTIFY examples**: Real-time notifications without polling
7. **Discuss materialized view refresh**: Trade-offs between REFRESH and CONCURRENTLY
8. **Mention pg_cron limitations**: Alternative job schedulers for complex workflows
9. **Recommend declarative partitioning**: Over inheritance for new projects
10. **Show JSONB indexing**: GIN indexes for fast JSONB queries

**Common mistakes to avoid:**
- Partitioning small tables (overhead exceeds benefits)
- Not creating indexes on partition key
- Forgetting to refresh materialized views
- Using inheritance instead of declarative partitioning
- Enabling parallelism for small queries (overhead)
- Not setting up GIN indexes for full-text search
- Forgetting CONCURRENTLY when refreshing mat views in production

## Next Steps

1. **09-REPLICATION.md** - Replication and high availability
2. **10-BACKUP.md** - Backup and recovery strategies
3. **11-CONFIG-OPERATIONS.md** - Production configuration and operations

## Additional Resources

- Partitioning: https://www.postgresql.org/docs/current/ddl-partitioning.html
- Parallel Query: https://www.postgresql.org/docs/current/parallel-query.html
- Full-Text Search: https://www.postgresql.org/docs/current/textsearch.html
- Foreign Data Wrappers: https://wiki.postgresql.org/wiki/Foreign_data_wrappers
- LISTEN/NOTIFY: https://www.postgresql.org/docs/current/sql-notify.html
