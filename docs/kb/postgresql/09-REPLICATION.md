# PostgreSQL Replication & High Availability

```yaml
id: postgresql_09_replication
topic: PostgreSQL
file_role: Replication strategies, high availability, and failover
profile: advanced
difficulty_level: advanced
kb_version: v3.1
prerequisites:
  - Fundamentals (01-FUNDAMENTALS.md)
  - Transactions (06-TRANSACTIONS.md)
  - Configuration (11-CONFIG-OPERATIONS.md)
related_topics:
  - Backup (10-BACKUP.md)
  - Advanced Topics (08-ADVANCED-TOPICS.md)
embedding_keywords:
  - streaming replication
  - logical replication
  - pg_basebackup
  - replication slots
  - standby server
  - failover
  - high availability
  - read replicas
  - WAL streaming
last_reviewed: 2025-11-16
```

## Replication Overview

PostgreSQL supports two main types of replication:

| Feature | **Physical Replication** | **Logical Replication** |
|---------|--------------------------|-------------------------|
| **Mechanism** | Binary WAL file streaming | SQL statements replayed |
| **Granularity** | Entire cluster | Specific tables/databases |
| **Version compatibility** | Same major version only | Different versions OK |
| **Schema changes** | Auto-replicated | Must be applied manually |
| **Standby writes** | No (read-only) | Yes (to different tables) |
| **Use case** | HA, disaster recovery | Selective sync, upgrades |

## Streaming Replication (Physical)

Most common replication method for high availability.

### Architecture

```
┌──────────────┐
│   Primary    │
│  (Read/Write)│
└──────┬───────┘
       │ WAL Stream
       ├────────────┐
       │            │
┌──────▼───────┐   │┌──────▼───────┐
│  Standby 1   │    ││  Standby 2   │
│  (Read-only) │    ││  (Read-only) │
└──────────────┘    │└──────────────┘
```

### Setup Streaming Replication

**On Primary Server:**

```conf
# postgresql.conf

# Enable WAL archiving for replication
wal_level = replica

# Maximum number of standby servers
max_wal_senders = 3

# Replication slots (prevents WAL deletion before standby catches up)
max_replication_slots = 3

# WAL keep segments (number of WAL files to keep)
# Deprecated in favor of replication slots
# wal_keep_size = 1GB

# Enable hot standby (allows reads on standby)
hot_standby = on
```

```conf
# pg_hba.conf (allow replication connections)

# TYPE  DATABASE        USER            ADDRESS                 METHOD
host    replication     replicator      192.168.1.0/24          md5
```

```sql
-- Create replication user
CREATE USER replicator WITH REPLICATION ENCRYPTED PASSWORD 'secret';
```

**On Standby Server:**

```bash
# Stop PostgreSQL on standby
sudo systemctl stop postgresql

# Remove existing data directory
sudo rm -rf /var/lib/postgresql/16/main

# Create base backup from primary
sudo -u postgres pg_basebackup \
  -h primary-server \
  -U replicator \
  -D /var/lib/postgresql/16/main \
  -P \
  -R \
  -X stream

# -P: Show progress
# -R: Create standby.signal and configure replication in postgresql.auto.conf
# -X stream: Stream WAL files during backup

# Start standby server
sudo systemctl start postgresql
```

**standby.signal** (created by pg_basebackup -R):

```
# This file indicates that this is a standby server
```

**postgresql.auto.conf** (created by pg_basebackup -R):

```conf
primary_conninfo = 'host=primary-server port=5432 user=replicator password=secret'
```

### Verify Replication

**On Primary:**

```sql
-- Check replication status
SELECT
  client_addr,
  state,
  sent_lsn,
  write_lsn,
  flush_lsn,
  replay_lsn,
  sync_state
FROM pg_stat_replication;

-- client_addr: Standby server IP
-- state: streaming (replicating), catchup (catching up), etc.
-- sent_lsn: WAL position sent to standby
-- replay_lsn: WAL position replayed on standby
-- sync_state: async, sync, or potential
```

**On Standby:**

```sql
-- Check if server is in recovery (standby mode)
SELECT pg_is_in_recovery();
-- Returns true if standby

-- Check replication lag
SELECT
  now() - pg_last_xact_replay_timestamp() AS replication_lag;
-- Returns time lag behind primary

-- Check WAL receiver status
SELECT
  status,
  receive_start_lsn,
  received_lsn,
  last_msg_send_time,
  last_msg_receipt_time
FROM pg_stat_wal_receiver;
```

### Synchronous vs Asynchronous Replication

**Asynchronous (default):**
- Primary commits without waiting for standby
- Faster performance
- Risk of data loss if primary fails before WAL reaches standby

**Synchronous:**
- Primary waits for standby to acknowledge WAL
- Slower performance (network latency)
- No data loss

```conf
# postgresql.conf (primary)

# Enable synchronous replication
synchronous_commit = on

# Standby server names that must acknowledge
synchronous_standby_names = 'standby1, standby2'

# FIRST 1: Wait for any 1 standby
synchronous_standby_names = 'FIRST 1 (standby1, standby2)'

# ANY 2: Wait for any 2 standbys
synchronous_standby_names = 'ANY 2 (standby1, standby2, standby3)'
```

**On Standby:**

```conf
# postgresql.conf (standby)

# Set application name to match synchronous_standby_names
primary_conninfo = '...application_name=standby1'
```

## Replication Slots

Replication slots prevent WAL files from being deleted before standby servers have received them.

```sql
-- On primary: Create replication slot
SELECT pg_create_physical_replication_slot('standby1_slot');

-- View replication slots
SELECT * FROM pg_replication_slots;

-- On standby: Use replication slot
# postgresql.auto.conf
primary_slot_name = 'standby1_slot'

-- Drop replication slot
SELECT pg_drop_replication_slot('standby1_slot');

-- Monitor slot lag
SELECT
  slot_name,
  pg_size_pretty(
    pg_current_wal_lsn() - confirmed_flush_lsn
  ) AS lag_size
FROM pg_replication_slots;
```

## Logical Replication

Replicates specific tables or databases using SQL statements.

### Setup Logical Replication

**On Publisher (source):**

```conf
# postgresql.conf
wal_level = logical
max_replication_slots = 4
max_wal_senders = 4
```

```sql
-- Create publication for specific tables
CREATE PUBLICATION my_publication FOR TABLE users, posts;

-- Or for all tables
CREATE PUBLICATION all_tables FOR ALL TABLES;

-- Or for specific schema
CREATE PUBLICATION schema_pub FOR TABLES IN SCHEMA public;

-- Add/remove tables from publication
ALTER PUBLICATION my_publication ADD TABLE comments;
ALTER PUBLICATION my_publication DROP TABLE posts;
```

**On Subscriber (destination):**

```sql
-- Create identical table structure (logical replication doesn't create tables)
CREATE TABLE users (id SERIAL PRIMARY KEY, username VARCHAR(50));
CREATE TABLE posts (id SERIAL PRIMARY KEY, user_id INTEGER, title TEXT);

-- Create subscription
CREATE SUBSCRIPTION my_subscription
  CONNECTION 'host=publisher-host port=5432 dbname=mydb user=replicator password=secret'
  PUBLICATION my_publication;

-- View subscriptions
SELECT * FROM pg_subscription;

-- View subscription status
SELECT * FROM pg_stat_subscription;

-- Refresh subscription (re-sync table list)
ALTER SUBSCRIPTION my_subscription REFRESH PUBLICATION;

-- Drop subscription
DROP SUBSCRIPTION my_subscription;
```

### Logical Replication Use Cases

```sql
-- Use case 1: Database upgrade
-- Publisher: PostgreSQL 14
-- Subscriber: PostgreSQL 16
-- Allows zero-downtime major version upgrade

-- Use case 2: Selective replication
-- Replicate only "users" table from DB1 to DB2
CREATE PUBLICATION users_only FOR TABLE users;

-- Use case 3: Multi-master (with care!)
-- DB1 publishes users to DB2
-- DB2 publishes orders to DB1
-- Careful: conflicts possible!

-- Use case 4: Data aggregation
-- Multiple regional databases publish to central analytics database
```

## Failover and High Availability

### Manual Failover (Promote Standby)

```bash
# On standby server: Promote to primary
sudo -u postgres pg_ctl promote -D /var/lib/postgresql/16/main

# Or using SQL
SELECT pg_promote();

# Verify standby is now primary
SELECT pg_is_in_recovery();
-- Returns false (no longer in recovery)
```

**After Promotion:**

1. Update application to point to new primary
2. Configure old primary as new standby (if recovered)
3. Update replication connections

### Automatic Failover Tools

**pg_auto_failover:**

```bash
# Install pg_auto_failover
sudo apt install pg-auto-failover-cli

# Initialize monitor node
pg_autoctl create monitor \
  --hostname monitor.example.com \
  --pgdata /var/lib/postgresql/monitor

# Initialize primary node
pg_autoctl create postgres \
  --hostname primary.example.com \
  --pgdata /var/lib/postgresql/16/main \
  --monitor postgres://monitor.example.com:5432/pg_auto_failover

# Initialize standby node
pg_autoctl create postgres \
  --hostname standby.example.com \
  --pgdata /var/lib/postgresql/16/main \
  --monitor postgres://monitor.example.com:5432/pg_auto_failover

# Monitor performs health checks and automatic failover
```

**Patroni (with etcd/Consul/Zookeeper):**

```yaml
# patroni.yml
scope: postgres-cluster
name: postgres1

restapi:
  listen: 0.0.0.0:8008
  connect_address: postgres1.example.com:8008

etcd:
  host: etcd.example.com:2379

bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 1048576

postgresql:
  listen: 0.0.0.0:5432
  connect_address: postgres1.example.com:5432
  data_dir: /var/lib/postgresql/16/main
  authentication:
    replication:
      username: replicator
      password: secret
```

```bash
# Start Patroni
patroni /etc/patroni/patroni.yml

# Check cluster status
patronictl -c /etc/patroni/patroni.yml list

# Manual failover
patronictl -c /etc/patroni/patroni.yml failover
```

## Load Balancing with HAProxy

```conf
# /etc/haproxy/haproxy.cfg

global
  maxconn 1000

defaults
  mode tcp
  timeout connect 5s
  timeout client 30s
  timeout server 30s

# Primary (writes)
listen postgres_primary
  bind *:5000
  option httpchk
  http-check expect status 200
  default-server inter 3s fall 3 rise 2 on-marked-down shutdown-sessions
  server postgres1 postgres1.example.com:5432 maxconn 100 check port 8008
  server postgres2 postgres2.example.com:5432 maxconn 100 check port 8008 backup

# Standby (reads)
listen postgres_standby
  bind *:5001
  option httpchk
  http-check expect status 200
  default-server inter 3s fall 3 rise 2
  server postgres2 postgres2.example.com:5432 maxconn 100 check port 8008
  server postgres3 postgres3.example.com:5432 maxconn 100 check port 8008

# Application connects to:
# - localhost:5000 for writes (primary)
# - localhost:5001 for reads (standbys)
```

## Read Scaling with Standbys

```javascript
// Node.js example: Route reads to standbys
const { Pool } = require('pg');

const primaryPool = new Pool({
  host: 'primary.example.com',
  port: 5432,
  database: 'myapp',
  max: 20,
});

const standbyPools = [
  new Pool({ host: 'standby1.example.com', port: 5432, database: 'myapp', max: 20 }),
  new Pool({ host: 'standby2.example.com', port: 5432, database: 'myapp', max: 20 }),
];

let standbyIndex = 0;

function getPrimaryPool() {
  return primaryPool;
}

function getStandbyPool() {
  // Round-robin load balancing
  const pool = standbyPools[standbyIndex];
  standbyIndex = (standbyIndex + 1) % standbyPools.length;
  return pool;
}

// Usage
async function createUser(username) {
  // Write to primary
  return getPrimaryPool().query(
    'INSERT INTO users (username) VALUES ($1) RETURNING *',
    [username]
  );
}

async function getUsers() {
  // Read from standby
  return getStandbyPool().query('SELECT * FROM users');
}

async function getUser(id) {
  // Critical read from primary (for consistency)
  return getPrimaryPool().query('SELECT * FROM users WHERE id = $1', [id]);
}
```

## Cascading Replication

Standby replicates from another standby, reducing load on primary.

```
┌──────────────┐
│   Primary    │
└──────┬───────┘
       │
       │
┌──────▼───────┐
│  Standby 1   │
└──────┬───────┘
       │
       ├────────────┐
       │            │
┌──────▼───────┐   │┌──────▼───────┐
│  Standby 2   │    ││  Standby 3   │
└──────────────┘    │└──────────────┘
```

**Setup:**

```bash
# Standby 1 replicates from Primary (normal setup)
pg_basebackup -h primary -U replicator -D /data -R

# Standby 2 replicates from Standby 1
# In postgresql.auto.conf on Standby 2:
primary_conninfo = 'host=standby1 port=5432 user=replicator password=secret'
```

## Monitoring Replication

### Key Metrics

```sql
-- Replication lag (time-based)
SELECT
  client_addr,
  state,
  now() - pg_last_xact_replay_timestamp() AS lag
FROM pg_stat_replication;

-- Replication lag (bytes)
SELECT
  client_addr,
  pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn) AS lag_bytes
FROM pg_stat_replication;

-- Replication slot lag
SELECT
  slot_name,
  active,
  pg_size_pretty(
    pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)
  ) AS lag_size
FROM pg_replication_slots;

-- WAL generation rate
SELECT
  pg_size_pretty(
    pg_wal_lsn_diff(pg_current_wal_lsn(), '0/0')
  ) AS total_wal_generated;
```

### Alerts to Set Up

```sql
-- Alert if replication lag > 60 seconds
SELECT
  client_addr,
  EXTRACT(EPOCH FROM (now() - pg_last_xact_replay_timestamp())) AS lag_seconds
FROM pg_stat_replication
WHERE EXTRACT(EPOCH FROM (now() - pg_last_xact_replay_timestamp())) > 60;

-- Alert if standby is not connected
SELECT count(*) FROM pg_stat_replication WHERE state != 'streaming';

-- Alert if replication slot lag > 1GB
SELECT
  slot_name,
  pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn) AS lag_bytes
FROM pg_replication_slots
WHERE pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn) > 1073741824;
```

## AI Pair Programming Notes

**When setting up PostgreSQL replication:**

1. **Explain replication types**: Physical vs logical, when to use each
2. **Show pg_basebackup command**: Step-by-step standby setup
3. **Demonstrate replication monitoring**: Essential queries for lag monitoring
4. **Discuss synchronous tradeoffs**: Performance vs data safety
5. **Show failover process**: Manual and automatic failover procedures
6. **Explain replication slots**: Prevent WAL deletion, monitor lag
7. **Recommend load balancing**: HAProxy or connection pooling for read scaling
8. **Show cascading setup**: Reduce primary load with cascading standbys
9. **Discuss logical replication use cases**: Upgrades, selective sync
10. **Mention HA tools**: pg_auto_failover, Patroni, repmgr

**Common replication mistakes to catch:**
- Not creating replication slots (WAL files deleted before standby catches up)
- Forgetting to configure pg_hba.conf for replication user
- Not monitoring replication lag
- Using synchronous replication without understanding performance impact
- Not testing failover procedure before production
- Forgetting to promote standby during failover
- Not updating application connection strings after failover

## Next Steps

1. **10-BACKUP.md** - Backup and recovery strategies
2. **11-CONFIG-OPERATIONS.md** - Production configuration and operations
3. **08-ADVANCED-TOPICS.md** - Advanced features like partitioning

## Additional Resources

- Streaming Replication: https://www.postgresql.org/docs/current/warm-standby.html
- Logical Replication: https://www.postgresql.org/docs/current/logical-replication.html
- pg_basebackup: https://www.postgresql.org/docs/current/app-pgbasebackup.html
- Patroni: https://patroni.readthedocs.io/
- pg_auto_failover: https://pg-auto-failover.readthedocs.io/
