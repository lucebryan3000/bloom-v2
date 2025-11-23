# PostgreSQL Configuration & Operations

```yaml
id: postgresql_11_config_operations
topic: PostgreSQL
file_role: Production configuration, security, monitoring, and operational best practices
profile: advanced
difficulty_level: advanced
kb_version: v3.1
prerequisites:
  - Fundamentals (01-FUNDAMENTALS.md)
  - Performance (07-PERFORMANCE.md)
  - Replication (09-REPLICATION.md)
related_topics:
  - Backup (10-BACKUP.md)
  - Indexes (05-INDEXES.md)
embedding_keywords:
  - postgresql.conf
  - pg_hba.conf
  - security hardening
  - monitoring
  - log configuration
  - connection limits
  - memory tuning
  - production settings
last_reviewed: 2025-11-16
```

## Configuration Files

### Key Configuration Files

```
$PGDATA/
├── postgresql.conf         # Main configuration
├── postgresql.auto.conf    # Auto-generated settings (ALTER SYSTEM)
├── pg_hba.conf            # Host-Based Authentication
└── pg_ident.conf          # User name mapping
```

**Load order** (later settings override earlier):
1. `postgresql.conf`
2. `postgresql.auto.conf`
3. Command-line parameters

### Editing Configuration

```bash
# Find configuration file location
psql -c "SHOW config_file;"

# Edit postgresql.conf
sudo nano /etc/postgresql/16/main/postgresql.conf

# Or use ALTER SYSTEM (writes to postgresql.auto.conf)
psql -c "ALTER SYSTEM SET shared_buffers = '4GB';"

# Reload configuration (without restart)
sudo systemctl reload postgresql
# or
psql -c "SELECT pg_reload_conf();"

# Check pending restart required
SELECT name, setting, pending_restart
FROM pg_settings
WHERE pending_restart = true;

# Restart PostgreSQL (for settings requiring restart)
sudo systemctl restart postgresql
```

## Production Configuration Settings

### Memory Settings

```conf
# postgresql.conf

# ==========================
# MEMORY SETTINGS
# ==========================

# Shared Buffers: Cache for data pages
# Recommendation: 25% of total RAM (up to 8-16GB on large servers)
# Requires restart
shared_buffers = 4GB

# Effective Cache Size: Tells planner how much memory OS will use for caching
# Recommendation: 50-75% of total RAM
# Does NOT allocate memory, just a hint to query planner
effective_cache_size = 12GB

# Work Memory: Memory for sorts, hashes, etc. (per operation!)
# Recommendation: (Total RAM * 0.25) / max_connections
# Start conservative: 4-16MB
# Monitor and increase if you see temp file usage
work_mem = 16MB

# Maintenance Work Memory: For VACUUM, CREATE INDEX, etc.
# Recommendation: 5-10% of RAM, or 1-2GB
# Higher = faster index creation and VACUUM
maintenance_work_mem = 1GB

# Huge Pages: Use huge pages (Linux)
# Recommendation: on (if OS supports it)
huge_pages = try

# Temp Buffers: Per-session buffer for temporary tables
# Usually fine at default
temp_buffers = 8MB
```

**Calculate optimal settings for 16GB RAM server with 100 max_connections:**

```conf
shared_buffers = 4GB               # 25% of 16GB
effective_cache_size = 12GB        # 75% of 16GB
work_mem = 40MB                    # (16GB * 0.25) / 100
maintenance_work_mem = 1GB         # ~6% of 16GB
```

### Connection Settings

```conf
# ==========================
# CONNECTION SETTINGS
# ==========================

# Listen on all network interfaces (default: localhost only)
listen_addresses = '*'

# Port
port = 5432

# Maximum concurrent connections
# Recommendation: Set based on connection pooler (PgBouncer)
# Without pooler: 100-300
# With pooler: 50-100 (PgBouncer handles client connections)
max_connections = 100

# Superuser reserved connections
superuser_reserved_connections = 3

# Authentication timeout
authentication_timeout = 1min

# Idle in transaction session timeout (abort idle transactions)
# Recommendation: 5-10 minutes
idle_in_transaction_session_timeout = 10min

# TCP keep-alive settings
tcp_keepalives_idle = 60
tcp_keepalives_interval = 10
tcp_keepalives_count = 3
```

### Write-Ahead Log (WAL) Settings

```conf
# ==========================
# WAL SETTINGS
# ==========================

# WAL level: minimal, replica, logical
# - minimal: No replication support
# - replica: Support physical replication (default)
# - logical: Support logical replication
wal_level = replica

# Fsync: Force write to disk (NEVER disable in production!)
fsync = on

# Synchronous commit: Wait for WAL write before COMMIT returns
# - on: Wait for WAL write and flush (safest, slowest)
# - remote_apply: Wait for standby to apply WAL (sync replication)
# - remote_write: Wait for standby to write WAL
# - local: Wait for local WAL write only
# - off: Don't wait (fastest, risk of data loss)
synchronous_commit = on

# WAL buffers: Buffer for WAL (auto = 1/32 of shared_buffers)
wal_buffers = -1

# WAL writer delay (how often to flush WAL buffer)
wal_writer_delay = 200ms

# Checkpoint settings
max_wal_size = 1GB                # Trigger checkpoint when WAL exceeds this
min_wal_size = 80MB               # Min WAL to keep

# Checkpoint timeout
checkpoint_timeout = 5min

# Checkpoint completion target (spread I/O over this fraction of checkpoint_timeout)
# Recommendation: 0.9 (spread checkpoint I/O over 90% of timeout)
checkpoint_completion_target = 0.9

# WAL segment size (compile-time, usually 16MB)
# Can check with: SHOW wal_segment_size;

# Archive mode (for PITR and replication)
archive_mode = on
archive_command = 'test ! -f /archives/%f && cp %p /archives/%f'
archive_timeout = 0               # Force switch after timeout (0 = disabled)
```

### Query Planner Settings

```conf
# ==========================
# QUERY PLANNER
# ==========================

# Random page cost (SSD: 1.1, HDD: 4.0)
random_page_cost = 1.1

# Sequential page cost
seq_page_cost = 1.0

# CPU tuple cost
cpu_tuple_cost = 0.01

# CPU index tuple cost
cpu_index_tuple_cost = 0.005

# CPU operator cost
cpu_operator_cost = 0.0025

# Parallel query settings
max_parallel_workers_per_gather = 4
max_parallel_workers = 8
max_worker_processes = 8

# Enable/disable query planner features (usually leave default)
enable_seqscan = on
enable_indexscan = on
enable_bitmapscan = on
enable_hashjoin = on
enable_mergejoin = on
enable_nestloop = on
```

### Autovacuum Settings

```conf
# ==========================
# AUTOVACUUM
# ==========================

# Enable autovacuum (should ALWAYS be on!)
autovacuum = on

# Maximum autovacuum workers
autovacuum_max_workers = 3

# Naptime between autovacuum runs
autovacuum_naptime = 1min

# Vacuum when 20% of rows are dead or 50 rows
autovacuum_vacuum_scale_factor = 0.2
autovacuum_vacuum_threshold = 50

# Analyze when 10% of rows change or 50 rows
autovacuum_analyze_scale_factor = 0.1
autovacuum_analyze_threshold = 50

# Autovacuum memory (uses maintenance_work_mem if -1)
autovacuum_work_mem = -1

# Cost-based autovacuum delay (throttling)
autovacuum_vacuum_cost_delay = 2ms
autovacuum_vacuum_cost_limit = 200

# Per-table overrides
-- For high-churn tables:
ALTER TABLE high_activity_table SET (
  autovacuum_vacuum_scale_factor = 0.05,
  autovacuum_vacuum_threshold = 100
);
```

### Logging Settings

```conf
# ==========================
# LOGGING
# ==========================

# Where to log
logging_collector = on
log_directory = 'log'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
log_file_mode = 0600

# Log rotation
log_rotation_age = 1d
log_rotation_size = 100MB
log_truncate_on_rotation = off

# When to log
log_min_messages = warning         # Server log: debug5-panic
log_min_error_statement = error    # Log queries causing errors
log_min_duration_statement = 1000  # Log queries slower than 1 second (ms)

# What to log
log_connections = on
log_disconnections = on
log_duration = off                 # Log statement duration
log_statement = 'none'             # none, ddl, mod, all
log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '
log_timezone = 'UTC'

# Lock waits
log_lock_waits = on
deadlock_timeout = 1s

# Temp file usage (indicates work_mem too small)
log_temp_files = 0                 # Log temp files larger than 0KB

# Checkpoints
log_checkpoints = on

# Autovacuum
log_autovacuum_min_duration = 0    # Log all autovacuum activity
```

## Security Configuration

### pg_hba.conf (Host-Based Authentication)

```conf
# /etc/postgresql/16/main/pg_hba.conf

# TYPE  DATABASE        USER            ADDRESS                 METHOD

# Local connections
local   all             postgres                                peer
local   all             all                                     md5

# IPv4 local connections
host    all             all             127.0.0.1/32            md5

# IPv4 remote connections (application servers)
host    all             appuser         192.168.1.0/24          md5

# SSL-required connections
hostssl all             all             0.0.0.0/0               md5

# Replication connections
host    replication     replicator      192.168.1.0/24          md5

# Reject all other connections
host    all             all             0.0.0.0/0               reject

# Methods:
# - trust: Allow without password (DANGEROUS in production!)
# - reject: Reject connection
# - md5: MD5 password authentication
# - scram-sha-256: More secure password authentication (preferred)
# - peer: OS user name must match PostgreSQL user (local only)
# - ident: Ident server authentication
# - cert: SSL certificate authentication
```

### SSL/TLS Configuration

```conf
# postgresql.conf

# Enable SSL
ssl = on
ssl_cert_file = '/etc/postgresql/16/main/server.crt'
ssl_key_file = '/etc/postgresql/16/main/server.key'
ssl_ca_file = '/etc/postgresql/16/main/root.crt'

# SSL ciphers
ssl_ciphers = 'HIGH:MEDIUM:+3DES:!aNULL'
ssl_prefer_server_ciphers = on

# SSL versions
ssl_min_protocol_version = 'TLSv1.2'
ssl_max_protocol_version = ''

# Require SSL for connections
# In pg_hba.conf: hostssl instead of host
```

```bash
# Generate self-signed certificate (dev only!)
openssl req -new -x509 -days 365 -nodes \
  -out /etc/postgresql/16/main/server.crt \
  -keyout /etc/postgresql/16/main/server.key \
  -subj "/CN=localhost"

sudo chown postgres:postgres /etc/postgresql/16/main/server.*
sudo chmod 600 /etc/postgresql/16/main/server.key
```

### Row-Level Security (RLS)

```sql
-- Enable RLS on table
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

-- Create policy: Users can only see their own documents
CREATE POLICY user_documents ON documents
  FOR SELECT
  USING (user_id = current_user::INTEGER);

-- Create policy: Users can only update their own documents
CREATE POLICY user_documents_update ON documents
  FOR UPDATE
  USING (user_id = current_user::INTEGER)
  WITH CHECK (user_id = current_user::INTEGER);

-- Create policy: Admins can see all
CREATE POLICY admin_documents ON documents
  FOR SELECT
  TO admin_role
  USING (true);

-- Disable RLS for specific role
ALTER TABLE documents FORCE ROW LEVEL SECURITY;
```

### Password Policies

```sql
-- Set password encryption method
SET password_encryption = 'scram-sha-256';

-- Create user with strong password
CREATE USER appuser WITH PASSWORD 'longSecureP@ssw0rd!2025';

-- Password expiration
ALTER USER appuser VALID UNTIL '2026-01-01';

-- Require password on next login
ALTER USER appuser PASSWORD 'temp' VALID UNTIL 'now';
```

## Monitoring and Maintenance

### Essential Monitoring Queries

```sql
-- Active connections
SELECT
  count(*),
  state
FROM pg_stat_activity
GROUP BY state;

-- Long-running queries (> 5 minutes)
SELECT
  pid,
  now() - query_start AS duration,
  usename,
  query
FROM pg_stat_activity
WHERE state != 'idle'
  AND now() - query_start > interval '5 minutes'
ORDER BY duration DESC;

-- Database sizes
SELECT
  datname,
  pg_size_pretty(pg_database_size(datname)) AS size
FROM pg_database
ORDER BY pg_database_size(datname) DESC;

-- Table sizes with bloat
SELECT
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS total_size,
  n_dead_tup,
  n_live_tup,
  round(n_dead_tup * 100.0 / NULLIF(n_live_tup + n_dead_tup, 0), 2) AS dead_pct
FROM pg_stat_user_tables
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
LIMIT 20;

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
  pg_size_pretty(pg_relation_size(schemaname||'.'||indexname)) AS index_size
FROM pg_stat_user_indexes
WHERE idx_scan = 0
  AND schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY pg_relation_size(schemaname||'.'||indexname) DESC;

-- Replication lag
SELECT
  client_addr,
  state,
  pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn) AS lag_bytes,
  now() - pg_last_xact_replay_timestamp() AS lag_time
FROM pg_stat_replication;
```

### Prometheus Monitoring (postgres_exporter)

```bash
# Install postgres_exporter
sudo apt install prometheus-postgres-exporter

# Configure connection
export DATA_SOURCE_NAME="postgresql://exporter:password@localhost:5432/postgres?sslmode=disable"

# Start exporter
postgres_exporter

# Metrics available at http://localhost:9187/metrics
```

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'postgresql'
    static_configs:
      - targets: ['localhost:9187']
```

### Health Check Endpoint

```sql
-- Create health check function
CREATE OR REPLACE FUNCTION health_check()
RETURNS TABLE (
  status TEXT,
  db_size BIGINT,
  active_connections INTEGER,
  cache_hit_ratio NUMERIC,
  replication_lag INTERVAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    'ok'::TEXT AS status,
    pg_database_size(current_database()) AS db_size,
    (SELECT count(*)::INTEGER FROM pg_stat_activity WHERE state = 'active') AS active_connections,
    round(sum(heap_blks_hit) * 100.0 / NULLIF(sum(heap_blks_hit) + sum(heap_blks_read), 0), 2)
      FROM pg_statio_user_tables AS cache_hit_ratio,
    (SELECT now() - pg_last_xact_replay_timestamp()) AS replication_lag;
END;
$$ LANGUAGE plpgsql;

-- Check health
SELECT * FROM health_check();
```

## Operational Best Practices

### 1. Regular Maintenance Schedule

```markdown
# Daily
- Monitor active connections and slow queries
- Check replication lag
- Review error logs

# Weekly
- VACUUM ANALYZE on high-churn tables
- Review backup success/failures
- Check disk space usage
- Review index usage stats

# Monthly
- Full database VACUUM (during maintenance window)
- Rebuild bloated indexes
- Review and update statistics
- Test disaster recovery procedure

# Quarterly
- Review and update security policies
- Review connection pool settings
- Performance audit with EXPLAIN ANALYZE
- Update PostgreSQL to latest patch version

# Annually
- Major version upgrade planning
- Review and update capacity planning
- Disaster recovery drill
- Security audit
```

### 2. Upgrade Procedure

```bash
# Minor version upgrade (e.g., 16.0 -> 16.1)
# Safe, in-place upgrade

# Backup database
pg_dumpall > backup_before_upgrade.sql

# Upgrade packages
sudo apt update
sudo apt upgrade postgresql-16

# Restart PostgreSQL
sudo systemctl restart postgresql

# Verify version
psql -c "SELECT version();"

# Major version upgrade (e.g., 15 -> 16)
# Use pg_upgrade for minimal downtime

# Install new version
sudo apt install postgresql-16

# Stop both versions
sudo systemctl stop postgresql@15-main
sudo systemctl stop postgresql@16-main

# Run pg_upgrade
sudo -u postgres /usr/lib/postgresql/16/bin/pg_upgrade \
  --old-datadir=/var/lib/postgresql/15/main \
  --new-datadir=/var/lib/postgresql/16/main \
  --old-bindir=/usr/lib/postgresql/15/bin \
  --new-bindir=/usr/lib/postgresql/16/bin \
  --check  # Check first, then remove --check to upgrade

# Start new version
sudo systemctl start postgresql@16-main

# Update optimizer statistics
/usr/lib/postgresql/16/bin/vacuumdb --all --analyze-in-stages

# Delete old cluster (after verification!)
sudo /usr/lib/postgresql/16/bin/pg_dropcluster 15 main
```

### 3. Performance Tuning Checklist

- [ ] Indexes created on foreign keys
- [ ] Indexes on WHERE clause columns
- [ ] No unused indexes
- [ ] shared_buffers = 25% RAM
- [ ] effective_cache_size = 75% RAM
- [ ] work_mem tuned for complex queries
- [ ] autovacuum enabled and tuned
- [ ] Connection pooling configured
- [ ] pg_stat_statements enabled
- [ ] Slow query logging enabled
- [ ] Cache hit ratio > 99%
- [ ] No table/index bloat

### 4. Security Hardening Checklist

- [ ] SSL/TLS enabled and enforced
- [ ] pg_hba.conf restrictive (no trust method)
- [ ] Strong passwords (scram-sha-256)
- [ ] Least privilege user permissions
- [ ] Database firewall rules
- [ ] Regular security updates
- [ ] Audit logging enabled
- [ ] Row-level security where applicable
- [ ] Encrypted backups
- [ ] Regular security audits

## AI Pair Programming Notes

**When configuring production PostgreSQL:**

1. **Calculate memory settings**: Based on available RAM and max_connections
2. **Explain restart requirements**: Not all settings can be reloaded
3. **Show pg_hba.conf order**: First match wins, order matters
4. **Demonstrate monitoring**: Essential queries for production health
5. **Discuss autovacuum tuning**: High-churn tables need aggressive settings
6. **Show SSL setup**: Production databases must use SSL
7. **Explain checkpoint tuning**: Spread I/O to avoid performance spikes
8. **Recommend connection pooling**: PgBouncer for high-connection applications
9. **Show upgrade procedure**: Both minor and major version upgrades
10. **Provide maintenance schedule**: Regular operations for production databases

**Common configuration mistakes to catch:**
- shared_buffers too high (> 40% RAM)
- work_mem too high (causes OOM when many operations run)
- Disabling fsync (NEVER in production!)
- No connection pooling with high max_connections
- Autovacuum disabled
- No monitoring or alerting
- Using 'trust' method in pg_hba.conf
- No SSL/TLS in production
- Not testing backups

## Next Steps

1. **09-REPLICATION.md** - High availability with replication
2. **10-BACKUP.md** - Backup and recovery strategies
3. **07-PERFORMANCE.md** - Performance optimization techniques

## Additional Resources

- Configuration Documentation: https://www.postgresql.org/docs/current/runtime-config.html
- pg_hba.conf: https://www.postgresql.org/docs/current/auth-pg-hba-conf.html
- Security Best Practices: https://www.postgresql.org/docs/current/security.html
- PGTune: https://pgtune.leopard.in.ua/ (configuration calculator)
- Postgres Monitoring: https://github.com/prometheus/postgres_exporter
