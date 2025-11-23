---
id: redis-replication
topic: redis
file_role: guide
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [redis-fundamentals, redis-persistence]
related_topics: [high-availability, master-replica, sentinel, failover]
embedding_keywords: [redis, replication, master-slave, sentinel, high-availability, failover]
last_reviewed: 2025-11-16
---

# Redis - Replication & High Availability

Comprehensive guide to Redis replication, Redis Sentinel, and high availability patterns.

## Overview

Redis replication provides data redundancy, read scaling, and high availability through master-replica architecture.

---

## Master-Replica Replication

### Basic Setup

**Master node** (primary):
```conf
# master.conf
port 6379
bind 0.0.0.0
requirepass masterpassword
```

**Replica node** (secondary):
```conf
# replica.conf
port 6380
bind 0.0.0.0
replicaof 127.0.0.1 6379  # Master host and port
masterauth masterpassword  # Master password
replica-read-only yes      # Read-only (default)
```

**Start nodes:**
```bash
redis-server master.conf
redis-server replica.conf
```

**Verify replication:**
```bash
# On master
redis-cli -p 6379 INFO replication

# On replica
redis-cli -p 6380 INFO replication
```

### Runtime Replication

```bash
# Make node a replica (at runtime)
redis-cli -p 6380 REPLICAOF 127.0.0.1 6379

# Stop replication (promote to master)
redis-cli -p 6380 REPLICAOF NO ONE
```

**Node.js:**
```javascript
// Make replica
await redis.replicaof('127.0.0.1', 6379)

// Promote to master
await redis.replicaof('NO', 'ONE')
```

---

## Replication Process

### Initial Sync

1. Replica connects to master
2. Replica sends PSYNC command
3. Master starts BGSAVE (background snapshot)
4. Master buffers new writes
5. Master sends RDB file to replica
6. Replica loads RDB
7. Master sends buffered writes
8. Replica applies buffered writes

### Partial Resync

**After network interruption:**
- Master maintains replication buffer
- Replica reconnects and requests missing data
- Master sends only missing commands (if in buffer)
- Avoids full resync

---

## Read Scaling

### Multiple Replicas

```
┌──────────┐
│  Master  │ (writes)
└────┬─────┘
     │
  ┌──┴──┬──────┐
  │     │      │
┌─▼─┐ ┌─▼─┐ ┌─▼─┐
│R1 │ │R2 │ │R3 │ (reads)
└───┘ └───┘ └───┘
```

**Node.js - Read from Replicas:**
```javascript
import Redis from 'ioredis'

// Master connection (writes)
const master = new Redis({ port: 6379, password: 'password' })

// Replica connections (reads)
const replicas = [
  new Redis({ port: 6380, password: 'password' }),
  new Redis({ port: 6381, password: 'password' }),
  new Redis({ port: 6382, password: 'password' }),
]

// Round-robin read distribution
let replicaIndex = 0

async function read(key) {
  const replica = replicas[replicaIndex]
  replicaIndex = (replicaIndex + 1) % replicas.length
  return await replica.get(key)
}

async function write(key, value) {
  return await master.set(key, value)
}

// Usage
await write('user:1000', 'Alice')  // Master
const user = await read('user:1000')  // Replica (round-robin)
```

---

## Redis Sentinel

### What is Sentinel?

**Redis Sentinel provides:**
- Automatic failover
- Monitoring
- Notification
- Configuration provider

**Architecture:**
```
┌────────────┐   ┌────────────┐   ┌────────────┐
│ Sentinel 1 │   │ Sentinel 2 │   │ Sentinel 3 │
└─────┬──────┘   └─────┬──────┘   └─────┬──────┘
      │                │                │
  ┌───▼────────────────▼────────────────▼───┐
  │          Monitor & Vote                  │
  └────────┬──────────────────┬──────────────┘
           │                  │
     ┌─────▼──────┐     ┌─────▼──────┐
     │   Master   │────▶│  Replica   │
     └────────────┘     └────────────┘
```

### Sentinel Configuration

```conf
# sentinel.conf
port 26379
sentinel monitor mymaster 127.0.0.1 6379 2  # 2 = quorum
sentinel auth-pass mymaster masterpassword
sentinel down-after-milliseconds mymaster 5000
sentinel parallel-syncs mymaster 1
sentinel failover-timeout mymaster 10000
```

**Start Sentinel:**
```bash
redis-sentinel sentinel.conf
```

### Sentinel Commands

```bash
# Get master info
redis-cli -p 26379 SENTINEL master mymaster

# Get replicas
redis-cli -p 26379 SENTINEL replicas mymaster

# Get other sentinels
redis-cli -p 26379 SENTINEL sentinels mymaster

# Manual failover
redis-cli -p 26379 SENTINEL failover mymaster
```

### Sentinel Client (Node.js)

```javascript
import Redis from 'ioredis'

const redis = new Redis({
  sentinels: [
    { host: '127.0.0.1', port: 26379 },
    { host: '127.0.0.1', port: 26380 },
    { host: '127.0.0.1', port: 26381 },
  ],
  name: 'mymaster',
  sentinelPassword: 'sentinel_password',
  password: 'master_password',
})

// Automatic failover handling
redis.on('error', (err) => {
  console.error('Redis error:', err)
})

redis.on('+switch-master', (master) => {
  console.log('New master:', master)
})

// Use normally
await redis.set('key', 'value')
```

---

## Failover Process

### Automatic Failover

**When master fails:**
1. Sentinels detect master down (after timeout)
2. Sentinels vote on new master
3. Quorum must be reached
4. Best replica is promoted
5. Other replicas reconfigured
6. Clients notified

**Replica Selection:**
- Replica with highest priority
- Most up-to-date replication offset
- Smallest runid (tiebreaker)

### Manual Failover

```bash
# Graceful failover (waits for replication)
redis-cli -p 6379 CLUSTER FAILOVER

# Force failover
redis-cli -p 26379 SENTINEL failover mymaster
```

---

## Monitoring Replication

### Replication Lag

```javascript
async function checkReplicationLag(master, replica) {
  const masterInfo = await master.info('replication')
  const replicaInfo = await replica.info('replication')

  const masterOffset = parseInt(
    masterInfo.match(/master_repl_offset:(\d+)/)[1]
  )

  const replicaOffset = parseInt(
    replicaInfo.match(/slave_repl_offset:(\d+)/)[1]
  )

  const lag = masterOffset - replicaOffset

  return {
    masterOffset,
    replicaOffset,
    lag,
    lagSeconds: lag / 1000, // Approximate
  }
}

// Alert if lag too high
const { lag } = await checkReplicationLag(master, replica)
if (lag > 1000000) {
  console.warn(`High replication lag: ${lag} bytes`)
}
```

### Replica Status

```javascript
async function getReplicaStatus(master) {
  const info = await master.info('replication')
  const replicas = []

  const lines = info.split('\r\n')
  for (const line of lines) {
    if (line.startsWith('slave')) {
      const match = line.match(/ip=([^,]+),port=(\d+),state=(\w+),offset=(\d+),lag=(\d+)/)
      if (match) {
        replicas.push({
          ip: match[1],
          port: parseInt(match[2]),
          state: match[3],
          offset: parseInt(match[4]),
          lag: parseInt(match[5]),
        })
      }
    }
  }

  return replicas
}
```

---

## Best Practices

### 1. Use Sentinel for HA

```conf
# Minimum 3 Sentinels (odd number)
# Quorum = (N / 2) + 1
sentinel monitor mymaster 127.0.0.1 6379 2
```

### 2. Monitor Replication Lag

```javascript
setInterval(async () => {
  const lag = await checkReplicationLag(master, replica)
  if (lag.lag > 1000000) {
    alert('High replication lag!')
  }
}, 60000)
```

### 3. Use Read-Only Replicas

```conf
replica-read-only yes  # Prevent writes to replicas
```

### 4. Configure Proper Timeouts

```conf
# Sentinel timeout
sentinel down-after-milliseconds mymaster 5000

# Client timeout
timeout 300
```

### 5. Test Failover

```bash
# Stop master
docker stop redis-master

# Verify failover
redis-cli -p 26379 SENTINEL master mymaster

# Restart old master (becomes replica)
docker start redis-master
```

---

## Next Steps

1. **Production** → See `11-CONFIG-OPERATIONS.md`

---

## AI Pair Programming Notes

**When to load this KB:**
- Setting up high availability
- Configuring replication
- Implementing failover
- Scaling reads

**Common starting points:**
- Basic replication: See Master-Replica section
- High availability: See Redis Sentinel
- Monitoring: See Monitoring Replication
- Failover: See Failover Process

**Typical questions:**
- "How do I set up replication?" → Master-Replica Replication
- "How do I ensure high availability?" → Redis Sentinel
- "How does failover work?" → Failover Process
- "How do I scale reads?" → Read Scaling

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1
