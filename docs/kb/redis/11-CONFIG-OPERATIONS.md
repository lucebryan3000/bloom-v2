---
id: redis-config-operations
topic: redis
file_role: guide
profile: full
difficulty_level: advanced
kb_version: 3.1
prerequisites: [redis-fundamentals, redis-persistence, redis-performance]
related_topics: [production, configuration, security, monitoring, troubleshooting]
embedding_keywords: [redis, configuration, production, security, monitoring, operations, troubleshooting]
last_reviewed: 2025-11-16
---

# Redis - Configuration & Operations

Comprehensive guide to production configuration, security, monitoring, and operational best practices for Redis deployments.

## Overview

Running Redis in production requires careful configuration, security hardening, monitoring, and operational procedures.

---

## Production Configuration

### Essential Settings

```conf
# redis.conf - Production Configuration

# Network
bind 0.0.0.0              # Listen on all interfaces (firewall required!)
port 6379                 # Default port
protected-mode yes        # Require password
tcp-backlog 511           # Connection backlog
timeout 300               # Close idle connections (seconds)
tcp-keepalive 300         # TCP keepalive

# Security
requirepass your_very_strong_password_here
rename-command FLUSHDB ""  # Disable dangerous commands
rename-command FLUSHALL ""
rename-command CONFIG "CONFIG_a8f7d9e2"  # Rename, don't disable

# Memory
maxmemory 2gb
maxmemory-policy allkeys-lru
maxmemory-samples 5

# Persistence (Hybrid)
save 900 1                # RDB snapshots
save 300 10
save 60 10000
appendonly yes            # AOF
appendfsync everysec
aof-use-rdb-preamble yes

# Replication (if replica)
# replicaof master-ip master-port
# masterauth master-password
replica-read-only yes

# Logging
loglevel notice
logfile /var/log/redis/redis.log

# Limits
maxclients 10000
```

### Environment-Specific Configs

**Development:**
```conf
maxmemory 128mb
save 3600 1  # Infrequent saves
appendonly no  # Disable AOF
loglevel debug
```

**Production:**
```conf
maxmemory 8gb
save 900 1
save 300 10
save 60 10000
appendonly yes
appendfsync everysec
loglevel notice
```

---

## Security

### Authentication

```conf
# Strong password
requirepass $(openssl rand -base64 32)

# Separate passwords for replicas
masterauth replica_password
```

**Client auth:**
```javascript
const redis = new Redis({
  host: '127.0.0.1',
  port: 6379,
  password: 'your_password',
})
```

### Disable Dangerous Commands

```conf
# Disable completely
rename-command FLUSHDB ""
rename-command FLUSHALL ""
rename-command KEYS ""
rename-command DEBUG ""

# Rename to obscure string
rename-command CONFIG "CONFIG_x9k2p7m4"
```

### Network Security

**1. Firewall Rules:**
```bash
# Allow only from app servers
sudo ufw allow from 192.168.1.0/24 to any port 6379

# Block all other traffic
sudo ufw deny 6379
```

**2. TLS/SSL:**
```conf
# redis.conf (Redis 6+)
tls-port 6380
port 0  # Disable non-TLS port
tls-cert-file /path/to/redis.crt
tls-key-file /path/to/redis.key
tls-ca-cert-file /path/to/ca.crt
```

**Client with TLS:**
```javascript
const redis = new Redis({
  host: '127.0.0.1',
  port: 6380,
  tls: {
    ca: fs.readFileSync('/path/to/ca.crt'),
    cert: fs.readFileSync('/path/to/client.crt'),
    key: fs.readFileSync('/path/to/client.key'),
  },
})
```

### ACLs (Redis 6+)

```bash
# Create users
ACL SETUSER alice on >password ~cached:* +get +set
ACL SETUSER bob on >password ~* +@all -@dangerous

# List users
ACL LIST

# Check user permissions
ACL WHOAMI
```

**Node.js:**
```javascript
const redis = new Redis({
  username: 'alice',
  password: 'password',
})
```

---

## Monitoring

### Key Metrics

```javascript
async function getMetrics() {
  const [server, stats, memory, replication, persistence] = await Promise.all([
    redis.info('server'),
    redis.info('stats'),
    redis.info('memory'),
    redis.info('replication'),
    redis.info('persistence'),
  ])

  return {
    // Performance
    uptimeSeconds: parseInt(server.match(/uptime_in_seconds:(\d+)/)[1]),
    opsPerSec: parseInt(stats.match(/instantaneous_ops_per_sec:(\d+)/)[1]),
    
    // Memory
    usedMemory: parseInt(memory.match(/used_memory:(\d+)/)[1]),
    usedMemoryPeak: parseInt(memory.match(/used_memory_peak:(\d+)/)[1]),
    memFragmentation: parseFloat(memory.match(/mem_fragmentation_ratio:([\d.]+)/)[1]),

    // Connections
    connectedClients: parseInt(stats.match(/connected_clients:(\d+)/)[1]),
    blockedClients: parseInt(stats.match(/blocked_clients:(\d+)/)[1]),
    rejectedConnections: parseInt(stats.match(/rejected_connections:(\d+)/)[1]),

    // Hit rate
    keyspaceHits: parseInt(stats.match(/keyspace_hits:(\d+)/)[1]),
    keyspaceMisses: parseInt(stats.match(/keyspace_misses:(\d+)/)[1]),

    // Persistence
    rdbLastSaveTime: parseInt(persistence.match(/rdb_last_save_time:(\d+)/)[1]),
    rdbChangesSinceLastSave: parseInt(persistence.match(/rdb_changes_since_last_save:(\d+)/)[1]),
  }
}

// Calculate hit rate
function calculateHitRate(metrics) {
  const total = metrics.keyspaceHits + metrics.keyspaceMisses
  return total > 0 ? (metrics.keyspaceHits / total * 100).toFixed(2) : 0
}
```

### Health Checks

```javascript
async function healthCheck() {
  try {
    // Ping test
    const pong = await redis.ping()
    if (pong !== 'PONG') {
      return { healthy: false, reason: 'Ping failed' }
    }

    // Get metrics
    const metrics = await getMetrics()

    // Check memory
    if (metrics.memFragmentation > 1.5) {
      console.warn(`High memory fragmentation: ${metrics.memFragmentation}`)
    }

    // Check hit rate
    const hitRate = calculateHitRate(metrics)
    if (hitRate < 80) {
      console.warn(`Low cache hit rate: ${hitRate}%`)
    }

    // Check connections
    if (metrics.connectedClients > 5000) {
      console.warn(`High connection count: ${metrics.connectedClients}`)
    }

    return { healthy: true, metrics }
  } catch (error) {
    return { healthy: false, reason: error.message }
  }
}

// Run health check every minute
setInterval(async () => {
  const health = await healthCheck()
  if (!health.healthy) {
    console.error('Health check failed:', health.reason)
  }
}, 60000)
```

### Slow Log

```javascript
async function checkSlowQueries() {
  const slowlog = await redis.slowlog('GET', 10)

  for (const entry of slowlog) {
    const [id, timestamp, duration, command] = entry

    if (duration > 100000) { // > 100ms
      console.warn({
        id,
        timestamp: new Date(timestamp * 1000),
        durationMs: (duration / 1000).toFixed(2),
        command: command.join(' '),
      })
    }
  }
}
```

---

## Backup & Recovery

### Automated Backups

```bash
#!/bin/bash
# /usr/local/bin/redis-backup.sh

BACKUP_DIR="/backups/redis"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=7

# Trigger save
redis-cli BGSAVE

# Wait for save
while redis-cli INFO persistence | grep -q "rdb_bgsave_in_progress:1"; do
  sleep 1
done

# Copy RDB
cp /var/lib/redis/dump.rdb "$BACKUP_DIR/dump_$DATE.rdb"
gzip "$BACKUP_DIR/dump_$DATE.rdb"

# Cleanup old backups
find "$BACKUP_DIR" -name "dump_*.rdb.gz" -mtime +$RETENTION_DAYS -delete

echo "Backup completed: dump_$DATE.rdb.gz"
```

**Cron schedule:**
```cron
0 */6 * * * /usr/local/bin/redis-backup.sh
```

---

## Troubleshooting

### High Memory Usage

```bash
# Find largest keys
redis-cli --bigkeys

# Memory analysis
redis-cli --memkeys

# Check for memory leaks
INFO memory
```

**Solutions:**
1. Set maxmemory limit
2. Configure eviction policy
3. Delete unused keys
4. Use appropriate data structures

### High Latency

```bash
# Measure latency
redis-cli --latency

# Check slow log
redis-cli SLOWLOG GET 10
```

**Solutions:**
1. Use pipelining
2. Avoid KEYS command
3. Optimize queries
4. Check network
5. Monitor CPU usage

### Connection Issues

```bash
# Check connections
redis-cli INFO clients

# Check network
netstat -an | grep 6379

# Check firewall
sudo ufw status
```

### Replication Lag

```bash
# Check replication offset
redis-cli -p 6379 INFO replication | grep offset
redis-cli -p 6380 INFO replication | grep offset
```

---

## Deployment Patterns

### Docker Compose

```yaml
version: '3.8'

services:
  redis:
    image: redis:7-alpine
    command: redis-server --requirepass ${REDIS_PASSWORD}
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data
    environment:
      - REDIS_PASSWORD=${REDIS_PASSWORD}
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 3s
      retries: 3

volumes:
  redis-data:
```

### Kubernetes

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: redis-config
data:
  redis.conf: |
    maxmemory 2gb
    maxmemory-policy allkeys-lru
    save 900 1
    appendonly yes

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
      - name: redis
        image: redis:7-alpine
        command: ["redis-server", "/etc/redis/redis.conf"]
        ports:
        - containerPort: 6379
        volumeMounts:
        - name: config
          mountPath: /etc/redis
        - name: data
          mountPath: /data
      volumes:
      - name: config
        configMap:
          name: redis-config
      - name: data
        persistentVolumeClaim:
          claimName: redis-pvc
```

---

## Best Practices

### 1. Security First

```conf
requirepass strong_password
rename-command FLUSHDB ""
bind 127.0.0.1  # Or use firewall
```

### 2. Set Memory Limits

```conf
maxmemory 2gb
maxmemory-policy allkeys-lru
```

### 3. Enable Persistence

```conf
save 900 1
appendonly yes
appendfsync everysec
aof-use-rdb-preamble yes
```

### 4. Monitor Metrics

- Memory usage
- Operations/second
- Hit rate
- Connection count
- Replication lag

### 5. Regular Backups

```bash
# Hourly RDB backups
0 * * * * /usr/local/bin/redis-backup.sh
```

### 6. Test Disaster Recovery

```bash
# Test restore procedure quarterly
# Document recovery time objective (RTO)
# Verify backup integrity
```

---

## Next Steps

1. **Review all guides** → Complete KB mastery
2. **Build production setup** → Apply best practices
3. **Monitor and optimize** → Continuous improvement

---

## AI Pair Programming Notes

**When to load this KB:**
- Setting up production Redis
- Security hardening
- Monitoring configuration
- Troubleshooting issues

**Common starting points:**
- Production config: See Production Configuration
- Security: See Security section
- Monitoring: See Monitoring section
- Troubleshooting: See Troubleshooting section

**Typical questions:**
- "How do I configure Redis for production?" → Production Configuration
- "How do I secure Redis?" → Security section
- "What should I monitor?" → Monitoring section
- "How do I troubleshoot issues?" → Troubleshooting section

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1
