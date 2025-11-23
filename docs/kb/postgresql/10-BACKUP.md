# PostgreSQL Backup & Recovery

```yaml
id: postgresql_10_backup
topic: PostgreSQL
file_role: Backup strategies, recovery procedures, and disaster recovery planning
profile: intermediate_to_advanced
difficulty_level: advanced
kb_version: v3.1
prerequisites:
  - Fundamentals (01-FUNDAMENTALS.md)
  - Replication (09-REPLICATION.md)
  - Transactions (06-TRANSACTIONS.md)
related_topics:
  - Configuration (11-CONFIG-OPERATIONS.md)
  - Advanced Topics (08-ADVANCED-TOPICS.md)
embedding_keywords:
  - pg_dump pg_dumpall
  - pg_restore
  - pg_basebackup
  - PITR point-in-time recovery
  - WAL archiving
  - backup strategies
  - disaster recovery
  - continuous archiving
last_reviewed: 2025-11-16
```

## Backup Strategies Overview

| Strategy | Backup Time | Restore Time | Storage | Best For |
|----------|-------------|--------------|---------|----------|
| **Logical (pg_dump)** | Slow (hours) | Slow (hours) | Small (compressed) | Small DBs, specific tables |
| **Physical (pg_basebackup)** | Medium (minutes) | Fast (seconds) | Large (full cluster) | Large DBs, disaster recovery |
| **Continuous Archiving (WAL)** | Instant (continuous) | Medium (replay WAL) | Large (cumulative) | PITR, minimal data loss |
| **Snapshots** | Instant (copy-on-write) | Instant | Medium | Cloud/VM environments |

**Key Decisions:**
- Logical backups: Portable, selective, human-readable SQL
- Physical backups: Fast, entire cluster, binary format
- PITR: Recover to any point in time, minimal data loss

## Logical Backups (pg_dump)

### pg_dump - Single Database

```bash
# Basic dump (SQL format)
pg_dump dbname > backup.sql

# Custom format (compressed, parallel restore)
pg_dump -F c -f backup.dump dbname

# Directory format (parallel dump and restore)
pg_dump -F d -f backup_dir -j 4 dbname

# Compressed SQL dump
pg_dump dbname | gzip > backup.sql.gz

# Dump specific tables
pg_dump -t users -t posts dbname > tables_backup.sql

# Dump specific schema
pg_dump -n public dbname > public_schema.sql

# Exclude specific tables
pg_dump --exclude-table=logs dbname > backup.sql

# Include data only (no schema)
pg_dump --data-only dbname > data.sql

# Include schema only (no data)
pg_dump --schema-only dbname > schema.sql

# With connection parameters
pg_dump -h localhost -p 5432 -U postgres -d dbname -f backup.dump
```

### pg_dumpall - All Databases

```bash
# Dump all databases (includes roles and tablespaces)
pg_dumpall > all_databases.sql

# Dump only global objects (roles, tablespaces)
pg_dumpall --globals-only > globals.sql

# Dump only roles
pg_dumpall --roles-only > roles.sql

# Compressed backup
pg_dumpall | gzip > all_databases.sql.gz
```

### Restore from pg_dump

```bash
# Restore SQL dump
psql dbname < backup.sql

# Restore compressed SQL dump
gunzip -c backup.sql.gz | psql dbname

# Restore custom format (can restore selectively)
pg_restore -d dbname backup.dump

# Restore with parallel jobs
pg_restore -d dbname -j 4 backup_dir

# Restore specific table
pg_restore -d dbname -t users backup.dump

# Restore schema only
pg_restore -d dbname --schema-only backup.dump

# Restore data only
pg_restore -d dbname --data-only backup.dump

# Clean database before restore
pg_restore -d dbname --clean backup.dump

# Create database if not exists
pg_restore -C -d postgres backup.dump

# Verbose output
pg_restore -d dbname -v backup.dump
```

### Automated Logical Backups

```bash
#!/bin/bash
# /usr/local/bin/backup-postgres.sh

# Configuration
BACKUP_DIR="/backups/postgresql"
RETENTION_DAYS=7
DATE=$(date +%Y%m%d_%H%M%S)

# Create backup directory
mkdir -p $BACKUP_DIR

# Backup all databases
pg_dumpall -U postgres | gzip > $BACKUP_DIR/all_databases_$DATE.sql.gz

# Or backup specific database
pg_dump -U postgres -F c -f $BACKUP_DIR/myapp_$DATE.dump myapp

# Delete old backups
find $BACKUP_DIR -name "*.dump" -mtime +$RETENTION_DAYS -delete
find $BACKUP_DIR -name "*.sql.gz" -mtime +$RETENTION_DAYS -delete

# Optional: Upload to S3
# aws s3 cp $BACKUP_DIR/myapp_$DATE.dump s3://my-backups/postgresql/

echo "Backup completed: $DATE"
```

```bash
# Schedule with cron (daily at 2 AM)
# crontab -e
0 2 * * * /usr/local/bin/backup-postgres.sh >> /var/log/postgres-backup.log 2>&1
```

## Physical Backups (pg_basebackup)

### Basic Physical Backup

```bash
# Create base backup
pg_basebackup -h localhost -U replicator -D /backups/base -P -R

# -D: Target directory
# -P: Show progress
# -R: Create standby.signal and recovery configuration

# Compressed backup (tar format)
pg_basebackup -h localhost -U replicator -F tar -z -D /backups/base.tar.gz

# With specific WAL method
pg_basebackup -h localhost -U replicator -D /backups/base -X stream -P

# -X fetch: Fetch WAL files at end
# -X stream: Stream WAL during backup (recommended)
# -X none: No WAL files (use with WAL archiving)
```

### Restore from Physical Backup

```bash
# Stop PostgreSQL
sudo systemctl stop postgresql

# Replace data directory with backup
sudo rm -rf /var/lib/postgresql/16/main
sudo cp -r /backups/base /var/lib/postgresql/16/main

# Set correct permissions
sudo chown -R postgres:postgres /var/lib/postgresql/16/main

# Start PostgreSQL
sudo systemctl start postgresql
```

## Continuous Archiving and PITR

Point-in-Time Recovery (PITR) allows restoring database to any point in time.

### Setup WAL Archiving

```conf
# postgresql.conf

# Enable WAL archiving
wal_level = replica
archive_mode = on

# Archive command (copy WAL files to archive directory)
archive_command = 'test ! -f /archives/%f && cp %p /archives/%f'

# Or archive to S3
# archive_command = 'aws s3 cp %p s3://my-backups/wal/%f'

# Or using pg_receivewal (more reliable)
# No archive_command needed, run pg_receivewal separately

# WAL segment size (default 16MB)
# Larger segments = less frequent archiving, more data loss risk
# Smaller segments = more frequent archiving, more I/O
```

```bash
# Create archive directory
sudo mkdir -p /archives
sudo chown postgres:postgres /archives

# Or use pg_receivewal for continuous WAL streaming
pg_receivewal -h localhost -U replicator -D /archives
```

### Create Base Backup for PITR

```bash
# Start backup
psql -c "SELECT pg_start_backup('daily_backup', false, false);"

# Create backup (using rsync, tar, or filesystem snapshot)
sudo rsync -av /var/lib/postgresql/16/main/ /backups/base/

# Stop backup
psql -c "SELECT pg_stop_backup(false);"

# Or use pg_basebackup (easier, recommended)
pg_basebackup -h localhost -U replicator -D /backups/base -X none -P
```

### Restore with PITR

```bash
# Stop PostgreSQL
sudo systemctl stop postgresql

# Restore base backup
sudo rm -rf /var/lib/postgresql/16/main
sudo cp -r /backups/base /var/lib/postgresql/16/main

# Create recovery configuration
sudo tee /var/lib/postgresql/16/main/recovery.signal << EOF
# This file indicates recovery mode
EOF

# Configure recovery
sudo tee -a /var/lib/postgresql/16/main/postgresql.auto.conf << EOF
restore_command = 'cp /archives/%f %p'
recovery_target_time = '2025-11-16 10:30:00'
EOF

# Set permissions
sudo chown -R postgres:postgres /var/lib/postgresql/16/main

# Start PostgreSQL (enters recovery mode)
sudo systemctl start postgresql

# Monitor recovery
sudo -u postgres psql -c "SELECT pg_is_in_recovery();"

# Check recovery target
tail -f /var/lib/postgresql/16/main/log/postgresql-*.log
```

### Recovery Targets

```conf
# Recover to specific timestamp
recovery_target_time = '2025-11-16 10:30:00'

# Recover to specific transaction ID
recovery_target_xid = '12345678'

# Recover to specific WAL location
recovery_target_lsn = '0/3000000'

# Recover to earliest consistent state
recovery_target = 'immediate'

# Recovery target action
recovery_target_action = 'promote'  # Promote to primary after recovery
# recovery_target_action = 'pause'  # Pause at recovery target
# recovery_target_action = 'shutdown'  # Shutdown at recovery target

# Include/exclude recovery target
recovery_target_inclusive = true  # Include target transaction
# recovery_target_inclusive = false  # Exclude target transaction
```

## Backup Verification

### Test Logical Backup

```bash
# Create test database
createdb test_restore

# Restore backup
pg_restore -d test_restore backup.dump

# Run consistency checks
psql test_restore -c "SELECT count(*) FROM users;"
psql test_restore -c "\dt"  # List tables

# Drop test database
dropdb test_restore
```

### Test Physical Backup

```bash
# Restore to temporary location
pg_basebackup -h localhost -U replicator -D /tmp/test_restore -P

# Start temporary instance
pg_ctl -D /tmp/test_restore -o "-p 5433" start

# Verify data
psql -p 5433 -d myapp -c "SELECT count(*) FROM users;"

# Stop temporary instance
pg_ctl -D /tmp/test_restore stop

# Cleanup
rm -rf /tmp/test_restore
```

## Cloud Backup Solutions

### AWS S3 Integration

```bash
# Install AWS CLI
sudo apt install awscli

# Configure AWS credentials
aws configure

# Backup script with S3 upload
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BUCKET="s3://my-postgres-backups"

# Create backup
pg_dump -F c -f /tmp/backup_$DATE.dump myapp

# Upload to S3
aws s3 cp /tmp/backup_$DATE.dump $BUCKET/daily/

# Cleanup local backup
rm /tmp/backup_$DATE.dump

# Lifecycle policy deletes backups older than 30 days
```

### Automated Cloud Backups (pgBackRest)

```bash
# Install pgBackRest
sudo apt install pgbackrest

# Configure /etc/pgbackrest.conf
[global]
repo1-path=/var/lib/pgbackrest
repo1-retention-full=7
repo1-retention-diff=7

[myapp]
pg1-path=/var/lib/postgresql/16/main
pg1-port=5432

# Create stanza
sudo pgbackrest --stanza=myapp stanza-create

# Full backup
sudo pgbackrest --stanza=myapp backup --type=full

# Incremental backup
sudo pgbackrest --stanza=myapp backup --type=incr

# Differential backup
sudo pgbackrest --stanza=myapp backup --type=diff

# List backups
sudo pgbackrest --stanza=myapp info

# Restore
sudo systemctl stop postgresql
sudo pgbackrest --stanza=myapp restore
sudo systemctl start postgresql
```

## Backup Best Practices

### 1. 3-2-1 Rule

- **3** copies of data (production + 2 backups)
- **2** different media types (disk + cloud)
- **1** offsite copy (different location)

### 2. Regular Testing

```bash
#!/bin/bash
# Weekly backup verification script

# Restore latest backup to test server
LATEST_BACKUP=$(ls -t /backups/*.dump | head -1)

# Restore to test database
dropdb --if-exists test_restore
createdb test_restore
pg_restore -d test_restore $LATEST_BACKUP

# Run sanity checks
psql test_restore -c "SELECT COUNT(*) FROM users;" > /tmp/user_count.txt
psql test_restore -c "SELECT version();" > /tmp/version.txt

# Send report
mail -s "Backup Verification Report" admin@example.com < /tmp/user_count.txt

# Cleanup
dropdb test_restore
```

### 3. Monitoring

```sql
-- Check WAL archiving status
SELECT
  archived_count,
  last_archived_wal,
  last_archived_time,
  failed_count,
  last_failed_wal,
  last_failed_time
FROM pg_stat_archiver;

-- Alert if archiving is failing
SELECT
  failed_count,
  last_failed_wal,
  last_failed_time
FROM pg_stat_archiver
WHERE failed_count > 0;

-- Check age of last backup
-- (Requires tracking in separate table or monitoring system)
```

### 4. Encryption

```bash
# Encrypt backup with GPG
pg_dump dbname | gzip | gpg -e -r admin@example.com > backup.sql.gz.gpg

# Decrypt and restore
gpg -d backup.sql.gz.gpg | gunzip | psql dbname

# Or use pg_dump with SSL
pg_dump "sslmode=require host=localhost dbname=myapp" > backup.sql
```

## Disaster Recovery Plan

### 1. Define RPO and RTO

- **RPO (Recovery Point Objective)**: Maximum acceptable data loss
  - Example: 1 hour (hourly backups + WAL archiving)
- **RTO (Recovery Time Objective)**: Maximum acceptable downtime
  - Example: 15 minutes (standby server ready)

### 2. Recovery Procedures

```markdown
# Disaster Recovery Runbook

## Scenario 1: Primary Server Failure

1. Verify primary is unreachable
2. Promote standby to primary:
   ```bash
   sudo -u postgres pg_ctl promote -D /var/lib/postgresql/16/main
   ```
3. Update application connection strings to standby
4. Monitor new primary for 30 minutes
5. Setup new standby from old primary (if recoverable)

## Scenario 2: Data Corruption

1. Identify corruption time from logs
2. Stop PostgreSQL
3. Restore base backup
4. Configure PITR to time before corruption
5. Start recovery
6. Verify data integrity
7. Promote recovered server

## Scenario 3: Accidental DROP TABLE

1. Estimate when table was dropped
2. Setup PITR recovery to time before drop
3. Create temporary recovery server
4. Export table from recovery server
5. Import table to production

## Scenario 4: Complete Site Loss

1. Provision new servers in alternate region
2. Retrieve latest backup from offsite storage (S3)
3. Restore backup on new server
4. Apply WAL archives from offsite
5. Update DNS to point to new servers
6. Verify application functionality
```

### 3. Testing Schedule

```markdown
# Disaster Recovery Testing Schedule

## Monthly Tests
- Restore latest logical backup to test server
- Verify data integrity and counts
- Test application against restored database

## Quarterly Tests
- Full PITR test (restore to specific timestamp)
- Test failover to standby server
- Verify backup encryption/decryption

## Annual Tests
- Complete disaster recovery simulation
- Restore from offsite backups only
- Full application stack recovery in alternate region
```

## Backup Comparison

| Feature | pg_dump | pg_basebackup | WAL Archiving + PITR | Snapshots |
|---------|---------|---------------|----------------------|-----------|
| **Backup Size** | Small (compressed) | Large (full cluster) | Cumulative (grows) | Medium (depends on change rate) |
| **Backup Speed** | Slow | Medium | Instant (continuous) | Instant |
| **Restore Speed** | Slow | Fast | Medium | Instant |
| **Granularity** | Per-table | Full cluster | Full cluster | Full cluster |
| **PITR Support** | No | No | Yes | Depends on filesystem |
| **Cross-Version** | Yes | No | No (same major) | No |
| **Consistency** | Snapshot | Snapshot | Continuous | Depends on filesystem |

## AI Pair Programming Notes

**When discussing PostgreSQL backups:**

1. **Explain backup types**: Logical vs physical vs PITR, when to use each
2. **Show pg_dump formats**: SQL vs custom vs directory, pros/cons
3. **Demonstrate PITR setup**: WAL archiving configuration and recovery
4. **Discuss RPO/RTO tradeoffs**: Business requirements vs technical implementation
5. **Show verification scripts**: Always test backups regularly
6. **Mention cloud integration**: S3 for offsite backups
7. **Explain 3-2-1 rule**: Essential backup redundancy
8. **Show encryption**: Protect sensitive backup data
9. **Demonstrate restore process**: Step-by-step recovery procedures
10. **Discuss monitoring**: Alert on backup failures

**Common backup mistakes to catch:**
- Not testing restores regularly
- No offsite/cloud backup copy
- Insufficient backup retention
- Missing WAL files for PITR
- No backup verification
- Storing backups on same disk as database
- Not encrypting sensitive backups
- No documented disaster recovery procedures

## Next Steps

1. **11-CONFIG-OPERATIONS.md** - Production configuration and operations
2. **09-REPLICATION.md** - High availability with replication
3. **08-ADVANCED-TOPICS.md** - Advanced PostgreSQL features

## Additional Resources

- pg_dump Documentation: https://www.postgresql.org/docs/current/app-pgdump.html
- pg_basebackup: https://www.postgresql.org/docs/current/app-pgbasebackup.html
- Continuous Archiving: https://www.postgresql.org/docs/current/continuous-archiving.html
- pgBackRest: https://pgbackrest.org/
- Barman: https://www.pgbarman.org/
