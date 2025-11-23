---
id: redis-persistence
topic: redis
file_role: guide
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [redis-fundamentals, redis-basic-operations]
related_topics: [rdb, aof, durability, backups, recovery]
embedding_keywords: [redis, persistence, rdb, aof, snapshots, durability, backups]
last_reviewed: 2025-11-16
---

# Redis - Persistence

Comprehensive guide to Redis persistence options: RDB snapshots, AOF logs, and hybrid approaches for data durability.

## Overview

Redis offers two persistence mechanisms: RDB (snapshots) and AOF (append-only file). Understanding trade-offs is critical for production deployments.

---

## RDB (Redis Database) Snapshots

### What is RDB?

**Point-in-time snapshots** of dataset saved to disk as binary dump file.

**How it works:**
1. Fork child process (copy-on-write)
2. Child writes dataset to temp file
3. Replace old RDB file atomically

### Configuration

```conf
# redis.conf

# Save if 1 key changed in 900 seconds
save 900 1

# Save if 10 keys changed in 300 seconds
save 300 10

# Save if 10000 keys changed in 60 seconds
save 60 10000

# Filename
dbfilename dump.rdb

# Directory
dir /var/lib/redis

# Compression (enabled by default)
rdbcompression yes

# Checksum (integrity check)
rdbchecksum yes

# Stop writes on save error
stop-writes-on-bgsave-error yes
```

### Manual Snapshots

```bash
# Background save (non-blocking)
BGSAVE
# Output: Background saving started

# Blocking save (stops all clients)
SAVE
# Output: OK

# Get last save timestamp
LASTSAVE
# Output: 1700136000 (Unix timestamp)
```

**Node.js:**
```javascript
// Trigger background save
await redis.bgsave()

// Check last save time
const lastSave = await redis.lastsave()
const lastSaveDate = new Date(lastSave * 1000)
console.log(`Last saved: ${lastSaveDate}`)

// Get save status
const info = await redis.info('persistence')
if (info.includes('rdb_bgsave_in_progress:1')) {
  console.log('Background save in progress')
}
```

### RDB Pros & Cons

**✅ Pros:**
- **Compact**: Single file, easy to backup
- **Fast restarts**: Faster than AOF replay
- **Performance**: Minimal impact (fork + write)
- **Disaster recovery**: Easy to copy to offsite storage

**❌ Cons:**
- **Data loss**: Lose data since last snapshot (minutes)
- **Fork overhead**: Can be slow for large datasets
- **CPU spike**: During snapshot creation

**When to use RDB:**
- Acceptable to lose recent data (5-15 minutes)
- Want fast restarts
- Backup/restore focus
- Limited disk I/O budget

---

## AOF (Append-Only File)

### What is AOF?

**Write log** of all write operations, replayed on startup.

**How it works:**
1. Client sends write command
2. Redis executes command
3. Command appended to AOF buffer
4. Buffer fsynced to disk (based on policy)

### Configuration

```conf
# redis.conf

# Enable AOF
appendonly yes

# Filename
appendfilename "appendonly.aof"

# Fsync policy
appendfsync everysec  # Recommended (1s data loss max)
# appendfsync always  # Safest (slow)
# appendfsync no      # Fastest (OS decides, risky)

# Rewrite threshold
auto-aof-rewrite-percentage 100  # Rewrite when 100% larger
auto-aof-rewrite-min-size 64mb   # Minimum size for rewrite

# No fsync during rewrite (performance)
no-appendfsync-on-rewrite no

# Load truncated AOF
aof-load-truncated yes

# Use RDB preamble (hybrid mode)
aof-use-rdb-preamble yes
```

### AOF Fsync Policies

| Policy | Description | Data Loss | Performance |
|--------|-------------|-----------|-------------|
| **always** | Fsync every write | Minimal (1 command) | Slowest |
| **everysec** | Fsync every second | ~1 second | Balanced ⭐ |
| **no** | OS decides when to fsync | Minutes | Fastest |

**Recommendation**: Use `appendfsync everysec` for balance of safety and performance.

### AOF Rewriting

**Problem**: AOF grows indefinitely as commands accumulate.

**Solution**: Rewrite AOF with minimal commands needed to recreate dataset.

```bash
# Manual rewrite (non-blocking)
BGREWRITEAOF
# Output: Background append only file rewriting started

# Check rewrite status
INFO persistence
```

**Example:**
```bash
# Original AOF (many commands):
SET key "v1"
SET key "v2"
SET key "v3"
INCR counter
INCR counter
INCR counter

# After rewrite (minimal commands):
SET key "v3"
SET counter "3"
```

**Node.js:**
```javascript
// Trigger AOF rewrite
await redis.bgrewriteaof()

// Check if rewrite in progress
const info = await redis.info('persistence')
if (info.includes('aof_rewrite_in_progress:1')) {
  console.log('AOF rewrite in progress')
}
```

### AOF Pros & Cons

**✅ Pros:**
- **Durability**: Minimal data loss (1 second max)
- **Append-only**: More resilient than RDB
- **Human-readable**: Can inspect/edit AOF file
- **Auto-rewrite**: Automatic optimization

**❌ Cons:**
- **Larger files**: Bigger than RDB
- **Slower restarts**: Must replay all commands
- **Slower writes**: Fsync overhead

**When to use AOF:**
- Cannot afford data loss
- Durability critical
- Willing to trade performance for safety

---

## Hybrid Persistence (RDB + AOF)

### Best of Both Worlds

**Enable both RDB and AOF** for maximum durability:

```conf
# redis.conf

# RDB configuration
save 900 1
save 300 10
save 60 10000

# AOF configuration
appendonly yes
appendfsync everysec
aof-use-rdb-preamble yes  # Hybrid mode!
```

**How hybrid mode works:**
1. AOF starts with RDB snapshot
2. New commands appended
3. On rewrite: New RDB snapshot + recent commands
4. Faster restarts (RDB) + durability (AOF)

**Restart behavior:**
- If both exist: Load AOF (more complete)
- If only RDB: Load RDB
- If only AOF: Load AOF

### Recommendation

**Production setup:**
```conf
# Hybrid persistence
appendonly yes
appendfsync everysec
aof-use-rdb-preamble yes

# RDB backups (hourly)
save 3600 1

# Auto-rewrite AOF
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
```

---

## Backups & Disaster Recovery

### RDB Backups

**Automated backup script:**
```bash
#!/bin/bash
# backup-redis.sh

BACKUP_DIR="/backups/redis"
DATE=$(date +%Y%m%d_%H%M%S)

# Trigger snapshot
redis-cli BGSAVE

# Wait for snapshot to complete
while redis-cli INFO persistence | grep -q "rdb_bgsave_in_progress:1"; do
  sleep 1
done

# Copy RDB file
cp /var/lib/redis/dump.rdb "$BACKUP_DIR/dump_$DATE.rdb"

# Compress
gzip "$BACKUP_DIR/dump_$DATE.rdb"

# Keep only last 7 days
find "$BACKUP_DIR" -name "dump_*.rdb.gz" -mtime +7 -delete

echo "Backup completed: dump_$DATE.rdb.gz"
```

**Cron schedule (hourly backups):**
```cron
0 * * * * /usr/local/bin/backup-redis.sh
```

### AOF Backups

```bash
#!/bin/bash
# backup-aof.sh

BACKUP_DIR="/backups/redis"
DATE=$(date +%Y%m%d_%H%M%S)

# Trigger AOF rewrite
redis-cli BGREWRITEAOF

# Wait for rewrite
while redis-cli INFO persistence | grep -q "aof_rewrite_in_progress:1"; do
  sleep 1
done

# Copy AOF file
cp /var/lib/redis/appendonly.aof "$BACKUP_DIR/appendonly_$DATE.aof"
gzip "$BACKUP_DIR/appendonly_$DATE.aof"

# Keep last 7 days
find "$BACKUP_DIR" -name "appendonly_*.aof.gz" -mtime +7 -delete

echo "AOF backup completed: appendonly_$DATE.aof.gz"
```

### Offsite Backups

```bash
#!/bin/bash
# offsite-backup.sh

# Trigger snapshot
redis-cli BGSAVE

# Wait for completion
while redis-cli INFO persistence | grep -q "rdb_bgsave_in_progress:1"; do
  sleep 1
done

# Upload to S3
aws s3 cp /var/lib/redis/dump.rdb \
  s3://my-backups/redis/dump_$(date +%Y%m%d_%H%M%S).rdb

# Or use rsync
rsync -avz /var/lib/redis/dump.rdb \
  user@backup-server:/backups/redis/
```

---

## Restore & Recovery

### Restore from RDB

```bash
# 1. Stop Redis
systemctl stop redis-server

# 2. Replace RDB file
cp /backups/redis/dump_20251116.rdb /var/lib/redis/dump.rdb

# 3. Set permissions
chown redis:redis /var/lib/redis/dump.rdb

# 4. Start Redis
systemctl start redis-server

# 5. Verify
redis-cli PING
```

### Restore from AOF

```bash
# 1. Stop Redis
systemctl stop redis-server

# 2. Replace AOF file
cp /backups/redis/appendonly_20251116.aof /var/lib/redis/appendonly.aof

# 3. Set permissions
chown redis:redis /var/lib/redis/appendonly.aof

# 4. Start Redis (will replay AOF)
systemctl start redis-server

# 5. Verify
redis-cli INFO persistence
```

### Repair Corrupted AOF

```bash
# Check for corruption
redis-check-aof appendonly.aof

# Fix corruption (removes corrupted part)
redis-check-aof --fix appendonly.aof

# Restart Redis
systemctl restart redis-server
```

---

## Monitoring Persistence

### Key Metrics

```javascript
async function checkPersistence() {
  const info = await redis.info('persistence')

  // Parse metrics
  const metrics = {}
  for (const line of info.split('\r\n')) {
    if (line.includes(':')) {
      const [key, value] = line.split(':')
      metrics[key] = value
    }
  }

  return {
    // RDB
    rdbLastSaveTime: new Date(parseInt(metrics.rdb_last_save_time) * 1000),
    rdbChangesSinceLastSave: parseInt(metrics.rdb_changes_since_last_save),
    rdbInProgress: metrics.rdb_bgsave_in_progress === '1',

    // AOF
    aofEnabled: metrics.aof_enabled === '1',
    aofRewriteInProgress: metrics.aof_rewrite_in_progress === '1',
    aofCurrentSize: parseInt(metrics.aof_current_size),
    aofBaseSize: parseInt(metrics.aof_base_size),
  }
}

// Alert if no save in last hour
const metrics = await checkPersistence()
const hourAgo = Date.now() - 3600000

if (metrics.rdbLastSaveTime < hourAgo) {
  console.warn('No RDB save in last hour!')
}
```

---

## Production Best Practices

### 1. Use Hybrid Persistence

```conf
appendonly yes
appendfsync everysec
aof-use-rdb-preamble yes
save 3600 1  # Hourly snapshots
```

### 2. Monitor Disk Space

```javascript
async function checkDiskSpace() {
  const info = await redis.info('persistence')
  
  // Check AOF size
  const aofSize = parseInt(info.match(/aof_current_size:(\d+)/)[1])
  const baseSize = parseInt(info.match(/aof_base_size:(\d+)/)[1])
  
  const growthRatio = aofSize / baseSize
  
  if (growthRatio > 5) {
    console.warn(`AOF grown ${growthRatio}x - consider rewrite`)
    await redis.bgrewriteaof()
  }
}
```

### 3. Test Restores Regularly

```bash
#!/bin/bash
# test-restore.sh

# Create test instance
docker run -d --name redis-restore-test \
  -v /backups/redis/dump.rdb:/data/dump.rdb \
  redis:7-alpine

# Wait for startup
sleep 5

# Verify data
docker exec redis-restore-test redis-cli DBSIZE

# Cleanup
docker rm -f redis-restore-test
```

### 4. Separate Persistence Disk

```conf
# Use separate disk for persistence (avoid I/O contention)
dir /mnt/redis-data
```

### 5. Handle Save Errors

```conf
# Continue serving reads even if save fails
stop-writes-on-bgsave-error no

# But monitor errors!
```

---

## Next Steps

After mastering persistence, explore:

1. **Performance** → See `08-PERFORMANCE.md` for optimization
2. **Clustering** → See `09-CLUSTERING.md` for distributed Redis
3. **Replication** → See `10-REPLICATION.md` for high availability
4. **Production** → See `11-CONFIG-OPERATIONS.md` for deployment

---

## AI Pair Programming Notes

**When to load this KB:**
- Setting up production Redis
- Configuring data durability
- Planning backup strategy
- Disaster recovery planning

**Common starting points:**
- RDB vs AOF: See RDB and AOF sections
- Production setup: See Hybrid Persistence
- Backups: See Backups & Disaster Recovery
- Recovery: See Restore & Recovery

**Typical questions:**
- "Should I use RDB or AOF?" → Hybrid Persistence
- "How do I backup Redis?" → Backups section
- "How do I restore from backup?" → Restore & Recovery
- "How much data loss is acceptable?" → AOF Fsync Policies

**Related topics:**
- Configuration: See `11-CONFIG-OPERATIONS.md`
- Performance: See `08-PERFORMANCE.md`
- High availability: See `10-REPLICATION.md`

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1
