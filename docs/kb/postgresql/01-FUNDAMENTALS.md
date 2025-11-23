# PostgreSQL Fundamentals

```yaml
id: postgresql_01_fundamentals
topic: PostgreSQL
file_role: Foundation concepts, architecture, and setup
profile: beginner
difficulty_level: beginner
kb_version: v3.1
prerequisites:
  - Basic SQL knowledge (helpful but not required)
  - Command line familiarity
  - Understanding of relational database concepts
related_topics:
  - SQL Basics (02-SQL-BASICS.md)
  - Data Types (03-DATA-TYPES.md)
  - Configuration & Operations (11-CONFIG-OPERATIONS.md)
embedding_keywords:
  - PostgreSQL installation
  - psql command line
  - PostgreSQL architecture
  - ACID properties
  - database server setup
  - postgres user
  - createdb dropdb
  - PostgreSQL vs MySQL
last_reviewed: 2025-11-16
```

## What is PostgreSQL?

PostgreSQL (often called "Postgres") is a powerful, open-source object-relational database management system (ORDBMS) with a strong reputation for reliability, feature robustness, and performance. First released in 1996, it's one of the most advanced open-source databases available.

### Key Characteristics

**ACID Compliant**: Full support for transactions with Atomicity, Consistency, Isolation, and Durability guarantees.

**Object-Relational**: Supports both relational (tables, SQL) and object-oriented (custom types, inheritance) features.

**Extensible**: Users can define their own data types, operators, index types, and functional languages.

**Standards-Compliant**: Closely follows SQL standards while adding powerful extensions.

**MVCC (Multi-Version Concurrency Control)**: Allows high concurrency without read locks.

### PostgreSQL vs Other Databases

| Feature | PostgreSQL | MySQL | SQLite | MongoDB |
|---------|-----------|-------|--------|---------|
| **Type** | Object-Relational | Relational | Embedded Relational | Document NoSQL |
| **ACID** | Full | Full | Full | Eventual |
| **Transactions** | Advanced (MVCC) | Standard | Standard | Limited |
| **JSON Support** | Native (JSONB) | Basic | JSON1 extension | Native |
| **Full-Text Search** | Built-in | Limited | FTS5 extension | Text indexes |
| **Replication** | Streaming, Logical | Master-Slave | None | Replica Sets |
| **Window Functions** | Yes | Yes (8.0+) | Yes (3.25+) | Limited |
| **Custom Types** | Yes | Limited | Limited | Schema-less |
| **Concurrency** | MVCC (excellent) | Lock-based | Lock-based | Document-level |
| **Best For** | Complex queries, data integrity | Web apps, read-heavy | Embedded, local | Unstructured data |

## Installation

### Docker (Recommended for Development)

```bash
# Pull official PostgreSQL image
docker pull postgres:16

# Run PostgreSQL container
docker run --name postgres-dev \
  -e POSTGRES_PASSWORD=mysecretpassword \
  -e POSTGRES_USER=appuser \
  -e POSTGRES_DB=myapp \
  -p 5432:5432 \
  -v postgres-data:/var/lib/postgresql/data \
  -d postgres:16

# Check container status
docker ps

# View logs
docker logs postgres-dev

# Access psql CLI
docker exec -it postgres-dev psql -U appuser -d myapp
```

### Linux (Ubuntu/Debian)

```bash
# Add PostgreSQL APT repository
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

# Import repository signing key
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

# Update package list
sudo apt update

# Install PostgreSQL 16
sudo apt install postgresql-16 postgresql-contrib-16

# Check status
sudo systemctl status postgresql

# Start PostgreSQL
sudo systemctl start postgresql

# Enable auto-start on boot
sudo systemctl enable postgresql
```

### macOS (Homebrew)

```bash
# Install PostgreSQL
brew install postgresql@16

# Start PostgreSQL service
brew services start postgresql@16

# Or run in foreground
postgres -D /opt/homebrew/var/postgresql@16

# Check version
postgres --version
```

### Windows

Download the installer from https://www.postgresql.org/download/windows/

1. Run the installer (EDB PostgreSQL)
2. Choose installation directory
3. Select components (PostgreSQL Server, pgAdmin, Command Line Tools)
4. Set password for postgres superuser
5. Choose port (default: 5432)
6. Select locale
7. Complete installation

## PostgreSQL Architecture

### Process Model

PostgreSQL uses a multi-process architecture (unlike multi-threaded databases):

```
┌─────────────────────────────────────────┐
│         Postmaster (Main Process)        │
│  - Listens on port 5432                 │
│  - Spawns backend processes             │
│  - Manages background workers           │
└─────────────────────────────────────────┘
                  │
     ┌────────────┼────────────┐
     │            │            │
┌────▼───┐   ┌───▼────┐  ┌───▼────┐
│Backend │   │Backend │  │Backend │  ← One per client
│Process │   │Process │  │Process │
└────────┘   └────────┘  └────────┘
     │            │            │
     └────────────┼────────────┘
                  │
     ┌────────────▼────────────┐
     │  Background Workers     │
     │  - WAL Writer           │
     │  - Checkpointer         │
     │  - Autovacuum           │
     │  - Stats Collector      │
     │  - Logical Replication  │
     └─────────────────────────┘
```

**Key Components**:

- **Postmaster**: Main server process that listens for connections
- **Backend Processes**: One per client connection, handles queries
- **Shared Buffers**: Shared memory for caching data pages
- **WAL Writer**: Writes Write-Ahead Log entries to disk
- **Checkpointer**: Periodically writes dirty buffers to disk
- **Autovacuum**: Cleans up dead tuples and updates statistics

### Data Storage

```
$PGDATA/
├── base/           # Database files (one directory per database)
├── global/         # Cluster-wide tables (pg_database, etc.)
├── pg_wal/         # Write-Ahead Log files
├── pg_xact/        # Transaction commit status
├── pg_stat/        # Statistics files
├── postgresql.conf # Configuration file
└── pg_hba.conf    # Host-Based Authentication config
```

## psql - PostgreSQL CLI

### Connecting to Database

```bash
# Connect with all parameters
psql -h localhost -p 5432 -U username -d database_name

# Connect using URI
psql postgresql://username:password@localhost:5432/database_name

# Connect as default user to default database
psql

# Connect to specific database as current user
psql myapp

# Connect as postgres superuser (Linux)
sudo -u postgres psql
```

### Essential psql Meta-Commands

```sql
-- List all databases
\l
\list

-- Connect to different database
\c database_name
\connect myapp

-- List all tables in current database
\dt

-- Describe table structure
\d table_name
\d+ table_name  -- More detailed

-- List all schemas
\dn

-- List all users/roles
\du

-- List all indexes
\di

-- List all views
\dv

-- List all functions
\df

-- Show current connection info
\conninfo

-- Execute SQL from file
\i /path/to/script.sql

-- Toggle expanded output (better for wide tables)
\x

-- Show query execution time
\timing on

-- Show command history
\s

-- Save query output to file
\o output.txt

-- Edit query in $EDITOR
\e

-- Get help on SQL commands
\h CREATE TABLE

-- Get help on psql commands
\?

-- Quit psql
\q
```

### psql Configuration (.psqlrc)

Create `~/.psqlrc` for custom settings:

```sql
-- Always show query timing
\timing on

-- Use table format by default
\pset format wrapped

-- Null values display as NULL
\pset null 'NULL'

-- Show line numbers
\set HISTSIZE 10000

-- Verbose error messages
\set VERBOSITY verbose

-- Custom prompt showing database and user
\set PROMPT1 '%n@%/%R%# '

-- Autocomplete keywords in uppercase
\set COMP_KEYWORD_CASE upper
```

## Basic Database Operations

### Creating Databases

```sql
-- As superuser (postgres)
CREATE DATABASE myapp;

-- With specific owner
CREATE DATABASE myapp OWNER appuser;

-- With template
CREATE DATABASE myapp_test TEMPLATE myapp;

-- With encoding and locale
CREATE DATABASE myapp
  ENCODING 'UTF8'
  LC_COLLATE 'en_US.UTF-8'
  LC_CTYPE 'en_US.UTF-8';
```

```bash
# Using createdb command-line utility
createdb myapp
createdb -O appuser myapp
createdb -T template0 myapp
```

### Dropping Databases

```sql
-- Drop database
DROP DATABASE myapp;

-- Drop if exists (no error if missing)
DROP DATABASE IF EXISTS myapp;

-- Force drop (disconnect all users first)
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'myapp';

DROP DATABASE myapp;
```

```bash
# Using dropdb command-line utility
dropdb myapp
dropdb --if-exists myapp
```

### User Management

```sql
-- Create user
CREATE USER appuser WITH PASSWORD 'secretpass';

-- Create role (user without login)
CREATE ROLE readonly;

-- Grant login privilege
ALTER ROLE readonly WITH LOGIN;

-- Create superuser
CREATE USER admin WITH SUPERUSER PASSWORD 'adminpass';

-- Grant database privileges
GRANT ALL PRIVILEGES ON DATABASE myapp TO appuser;

-- Grant schema privileges
GRANT ALL ON SCHEMA public TO appuser;

-- Grant table privileges
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO readonly;

-- Grant future table privileges
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT ON TABLES TO readonly;

-- Drop user
DROP USER appuser;

-- Change password
ALTER USER appuser WITH PASSWORD 'newpass';

-- List all users and their roles
\du
```

## ACID Properties in PostgreSQL

### Atomicity

Transactions are all-or-nothing. Either all operations succeed or none do.

```sql
BEGIN;
  UPDATE accounts SET balance = balance - 100 WHERE id = 1;
  UPDATE accounts SET balance = balance + 100 WHERE id = 2;
COMMIT;  -- Both updates succeed

-- Or if error occurs:
ROLLBACK;  -- Both updates are undone
```

### Consistency

Database remains in a valid state before and after transactions.

```sql
-- Constraints enforce consistency
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  age INTEGER CHECK (age >= 0 AND age <= 150)
);

-- This violates constraint, transaction fails
INSERT INTO users (email, age) VALUES ('test@example.com', 200);
-- ERROR: new row violates check constraint "users_age_check"
```

### Isolation

Concurrent transactions don't interfere with each other.

```sql
-- Default isolation level: READ COMMITTED
-- Each query sees only committed data

-- Set stricter isolation
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

BEGIN;
  SELECT * FROM accounts WHERE id = 1;  -- Sees consistent snapshot
  -- Even if another transaction commits changes, this transaction
  -- sees the snapshot from when it started
COMMIT;
```

### Durability

Committed transactions persist even after system crashes.

PostgreSQL uses Write-Ahead Logging (WAL):
1. Changes written to WAL log first
2. WAL flushed to disk before commit returns
3. Data pages written to disk asynchronously
4. Crash recovery replays WAL to restore state

## Data Directory Structure

```bash
# Find data directory location
psql -c "SHOW data_directory;"

# Typical locations:
# Linux: /var/lib/postgresql/16/main
# macOS: /opt/homebrew/var/postgresql@16
# Docker: /var/lib/postgresql/data
```

### Key Files

**postgresql.conf** - Main configuration file:
```conf
# Connection settings
listen_addresses = 'localhost'
port = 5432
max_connections = 100

# Memory settings
shared_buffers = 256MB
effective_cache_size = 1GB
work_mem = 4MB

# WAL settings
wal_level = replica
max_wal_size = 1GB

# Logging
logging_collector = on
log_directory = 'log'
log_filename = 'postgresql-%Y-%m-%d.log'
```

**pg_hba.conf** - Host-Based Authentication:
```conf
# TYPE  DATABASE        USER            ADDRESS                 METHOD

# Local connections
local   all             postgres                                peer
local   all             all                                     md5

# IPv4 connections
host    all             all             127.0.0.1/32            md5
host    all             all             0.0.0.0/0               reject

# IPv6 connections
host    all             all             ::1/128                 md5

# Replication connections
host    replication     replicator      192.168.1.0/24          md5
```

## Connection Pooling

PostgreSQL creates a new backend process for each connection. For high-concurrency applications, use connection pooling.

### PgBouncer (Recommended)

```bash
# Install PgBouncer
sudo apt install pgbouncer

# Configure /etc/pgbouncer/pgbouncer.ini
[databases]
myapp = host=localhost port=5432 dbname=myapp

[pgbouncer]
listen_addr = 127.0.0.1
listen_port = 6432
auth_type = md5
auth_file = /etc/pgbouncer/userlist.txt
pool_mode = transaction
max_client_conn = 1000
default_pool_size = 25

# Start PgBouncer
sudo systemctl start pgbouncer

# Connect through PgBouncer
psql -h localhost -p 6432 -U appuser myapp
```

### Application-Level Pooling

Most PostgreSQL client libraries include connection pooling:

```javascript
// Node.js with pg (node-postgres)
const { Pool } = require('pg');

const pool = new Pool({
  host: 'localhost',
  port: 5432,
  user: 'appuser',
  password: 'secretpass',
  database: 'myapp',
  max: 20,                // Maximum pool size
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

const result = await pool.query('SELECT * FROM users WHERE id = $1', [1]);
```

## PostgreSQL System Catalogs

PostgreSQL stores metadata about databases, tables, and other objects in system catalogs (tables prefixed with `pg_`):

```sql
-- List all tables in current database
SELECT tablename FROM pg_tables WHERE schemaname = 'public';

-- Get table size
SELECT pg_size_pretty(pg_total_relation_size('users'));

-- Get database size
SELECT pg_size_pretty(pg_database_size('myapp'));

-- List all indexes on a table
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'users';

-- Show all active queries
SELECT pid, usename, state, query, query_start
FROM pg_stat_activity
WHERE state = 'active';

-- Kill a specific query
SELECT pg_terminate_backend(12345);  -- Replace with actual pid

-- Get table statistics
SELECT schemaname, tablename, n_tup_ins, n_tup_upd, n_tup_del
FROM pg_stat_user_tables
WHERE tablename = 'users';
```

## Common Errors and Solutions

### "connection refused" Error

```bash
# Check if PostgreSQL is running
sudo systemctl status postgresql

# Check if listening on correct port
sudo netstat -plnt | grep 5432

# Check pg_hba.conf allows your connection
# Make sure listen_addresses in postgresql.conf is set correctly
```

### "role does not exist" Error

```sql
-- Create the role
CREATE USER myuser WITH PASSWORD 'mypass';

-- Grant necessary privileges
GRANT ALL PRIVILEGES ON DATABASE myapp TO myuser;
```

### "permission denied for table" Error

```sql
-- Grant table access
GRANT SELECT, INSERT, UPDATE, DELETE ON table_name TO myuser;

-- Grant access to all tables in schema
GRANT ALL ON ALL TABLES IN SCHEMA public TO myuser;

-- Grant access to future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT ALL ON TABLES TO myuser;
```

### "too many connections" Error

```sql
-- Check current connections
SELECT count(*) FROM pg_stat_activity;

-- Increase max_connections in postgresql.conf
max_connections = 200

-- Then restart PostgreSQL
sudo systemctl restart postgresql

-- Or use connection pooling (PgBouncer)
```

## Performance Tips

1. **Use Connection Pooling**: PgBouncer or application-level pooling
2. **Tune Memory Settings**: Adjust `shared_buffers`, `work_mem`, `effective_cache_size`
3. **Enable Query Logging**: Monitor slow queries with `log_min_duration_statement`
4. **Regular VACUUM**: Autovacuum should be enabled (it is by default)
5. **Use EXPLAIN**: Analyze query performance with `EXPLAIN ANALYZE`
6. **Create Indexes**: Index frequently queried columns
7. **Use Connection Limits**: Set `max_connections` appropriately
8. **Monitor with pg_stat**: Use `pg_stat_statements` extension

## AI Pair Programming Notes

**When working with PostgreSQL in pair programming sessions:**

1. **Always specify connection details**: Share the exact host, port, database name, and credentials needed
2. **Check PostgreSQL version**: Different versions have different features (`SELECT version();`)
3. **Use migrations**: Never manually alter production databases - use migration tools
4. **Test locally first**: Use Docker for local PostgreSQL instances matching production
5. **Explain isolation levels**: When discussing concurrency, clarify which isolation level you're using
6. **Show EXPLAIN plans**: When optimizing queries, always share the `EXPLAIN ANALYZE` output
7. **Document schema changes**: Include DDL statements in code reviews
8. **Use transactions in examples**: Show proper transaction usage in code samples
9. **Mention connection pooling**: Always discuss connection management strategy
10. **Reference system catalogs**: Show how to query `pg_*` tables for metadata

**Common pitfalls to avoid:**
- Opening too many connections without pooling
- Not using prepared statements (SQL injection risk)
- Forgetting to create indexes on foreign keys
- Not setting appropriate `work_mem` for complex queries
- Ignoring autovacuum warnings
- Using text instead of appropriate data types (use INTEGER not TEXT for IDs)
- Not using schemas for multi-tenant applications

## Next Steps

After understanding PostgreSQL fundamentals:

1. **02-SQL-BASICS.md** - Learn DDL, DML, and basic SQL queries
2. **03-DATA-TYPES.md** - Explore PostgreSQL's rich type system
3. **04-QUERIES.md** - Master SELECT, JOINs, and advanced querying
4. **05-INDEXES.md** - Optimize query performance with indexes
5. **06-TRANSACTIONS.md** - Deep dive into transaction management and isolation

## Additional Resources

- Official Documentation: https://www.postgresql.org/docs/
- PostgreSQL Tutorial: https://www.postgresqltutorial.com/
- PostgreSQL Wiki: https://wiki.postgresql.org/
- Awesome Postgres: https://github.com/dhamaniasad/awesome-postgres
- pgAdmin (GUI Tool): https://www.pgadmin.org/
- DBeaver (Universal DB Tool): https://dbeaver.io/
