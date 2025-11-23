---
id: redis-performance
topic: redis
file_role: guide
profile: full
difficulty_level: advanced
kb_version: 3.1
prerequisites: [redis-fundamentals, redis-basic-operations, redis-data-structures]
related_topics: [optimization, tuning, benchmarking, profiling, memory]
embedding_keywords: [redis, performance, optimization, tuning, memory, latency, throughput]
last_reviewed: 2025-11-16
---

# Redis - Performance Optimization

Comprehensive guide to Redis performance tuning, optimization techniques, and production best practices.

## Overview

Redis is designed for speed, but understanding performance characteristics and optimization techniques is critical for production deployments.

---

## Benchmarking Redis

### Built-in Benchmark Tool

```bash
# Basic benchmark
redis-benchmark

# Specific commands
redis-benchmark -t set,get -n 1000000

# With pipelining
redis-benchmark -t set,get -n 1000000 -P 16

# Specific key size
redis-benchmark -t set -n 1000000 -d 1024

# Against remote server
redis-benchmark -h 192.168.1.100 -p 6379 -a password

# Only specific test
redis-benchmark -t ping,set,get,lpush,lpop
```

**Sample Output:**
```
SET: 120,000 requests per second
GET: 130,000 requests per second
LPUSH: 110,000 requests per second
LPOP: 115,000 requests per second
```

### Custom Benchmarks

```javascript
// Measure latency
async function benchmarkLatency(iterations = 10000) {
  const start = Date.now()

  for (let i = 0; i < iterations; i++) {
    await redis.set(`bench:${i}`, i)
  }

  const duration = Date.now() - start
  const opsPerSec = (iterations / duration) * 1000
  const avgLatency = duration / iterations

  console.log(`Operations/sec: ${opsPerSec.toFixed(2)}`)
  console.log(`Avg latency: ${avgLatency.toFixed(3)}ms`)
}

// Measure pipeline performance
async function benchmarkPipeline(iterations = 10000) {
  const start = Date.now()

  const pipeline = redis.pipeline()
  for (let i = 0; i < iterations; i++) {
    pipeline.set(`bench:${i}`, i)
  }
  await pipeline.exec()

  const duration = Date.now() - start
  const opsPerSec = (iterations / duration) * 1000

  console.log(`Pipeline ops/sec: ${opsPerSec.toFixed(2)}`)
}
```

---

## Memory Optimization

### Understanding Memory Usage

```bash
# Get memory info
INFO memory

# Key metrics:
# used_memory: Total memory allocated by Redis
# used_memory_rss: Memory allocated by OS (includes fragmentation)
# used_memory_peak: Peak memory usage
# mem_fragmentation_ratio: RSS / allocated (ideal: 1.0-1.5)
```

**Node.js:**
```javascript
async function getMemoryStats() {
  const info = await redis.info('memory')

  const stats = {}
  for (const line of info.split('\r\n')) {
    if (line.includes(':')) {
      const [key, value] = line.split(':')
      stats[key] = value
    }
  }

  return {
    usedMemory: parseInt(stats.used_memory),
    usedMemoryHuman: stats.used_memory_human,
    usedMemoryRss: parseInt(stats.used_memory_rss),
    fragmentation: parseFloat(stats.mem_fragmentation_ratio),
    peakMemory: parseInt(stats.used_memory_peak),
  }
}
```

### Find Large Keys

```bash
# Scan for largest keys
redis-cli --bigkeys

# Sample output:
# Biggest string: user:1000 (1024 bytes)
# Biggest list: queue:jobs (10000 items)
# Biggest hash: stats:daily (5000 fields)
```

**Custom script:**
```javascript
async function findLargeKeys(pattern = '*', limit = 100) {
  const largeKeys = []
  let cursor = '0'

  do {
    const [newCursor, keys] = await redis.scan(cursor, 'MATCH', pattern, 'COUNT', 100)
    cursor = newCursor

    for (const key of keys) {
      const type = await redis.type(key)
      let size = 0

      switch (type) {
        case 'string':
          size = (await redis.strlen(key)) || 0
          break
        case 'list':
          size = await redis.llen(key)
          break
        case 'set':
          size = await redis.scard(key)
          break
        case 'zset':
          size = await redis.zcard(key)
          break
        case 'hash':
          size = await redis.hlen(key)
          break
      }

      largeKeys.push({ key, type, size })
    }
  } while (cursor !== '0')

  // Sort by size descending
  return largeKeys.sort((a, b) => b.size - a.size).slice(0, limit)
}
```

### Memory Optimization Techniques

**1. Use Appropriate Data Structures**
```javascript
// ❌ WRONG - String for object (serialized JSON)
await redis.set('user:1000', JSON.stringify({
  name: 'Alice',
  email: 'alice@example.com',
  age: 30
})) // ~80 bytes

// ✅ CORRECT - Hash for object
await redis.hset('user:1000', {
  name: 'Alice',
  email: 'alice@example.com',
  age: '30'
}) // ~60 bytes (25% savings)
```

**2. Use Integer Encoding**
```conf
# redis.conf
hash-max-ziplist-entries 512
hash-max-ziplist-value 64
```

**3. Set maxmemory and Eviction Policy**
```conf
# Limit memory usage
maxmemory 2gb

# Evict least recently used keys
maxmemory-policy allkeys-lru
```

**4. Use Compression**
```javascript
// Compress large values
import zlib from 'zlib'
import { promisify } from 'util'

const gzip = promisify(zlib.gzip)
const gunzip = promisify(zlib.gunzip)

async function setCompressed(key, value) {
  const compressed = await gzip(JSON.stringify(value))
  await redis.set(key, compressed)
}

async function getCompressed(key) {
  const compressed = await redis.getBuffer(key)
  if (!compressed) return null

  const decompressed = await gunzip(compressed)
  return JSON.parse(decompressed.toString())
}
```

**5. Delete Unused Keys**
```javascript
// Regular cleanup
async function cleanupOldKeys(pattern, maxAge) {
  let cursor = '0'
  let deleted = 0

  do {
    const [newCursor, keys] = await redis.scan(cursor, 'MATCH', pattern)
    cursor = newCursor

    for (const key of keys) {
      const ttl = await redis.ttl(key)
      if (ttl === -1) {
        // No TTL set - delete if old
        await redis.del(key)
        deleted++
      }
    }
  } while (cursor !== '0')

  return deleted
}
```

---

## Latency Optimization

### Measure Latency

```bash
# Latency monitoring
redis-cli --latency

# Latency history
redis-cli --latency-history

# Intrinsic latency (baseline)
redis-cli --intrinsic-latency 100
```

**Node.js:**
```javascript
async function measureLatency(iterations = 1000) {
  const latencies = []

  for (let i = 0; i < iterations; i++) {
    const start = process.hrtime.bigint()
    await redis.ping()
    const end = process.hrtime.bigint()

    latencies.push(Number(end - start) / 1000000) // Convert to ms
  }

  latencies.sort((a, b) => a - b)

  return {
    min: latencies[0],
    max: latencies[latencies.length - 1],
    avg: latencies.reduce((a, b) => a + b) / latencies.length,
    p50: latencies[Math.floor(latencies.length * 0.5)],
    p95: latencies[Math.floor(latencies.length * 0.95)],
    p99: latencies[Math.floor(latencies.length * 0.99)],
  }
}
```

### Reduce Latency

**1. Use Pipelining**
```javascript
// ❌ SLOW - Sequential (1000ms total)
for (let i = 0; i < 100; i++) {
  await redis.get(`key:${i}`) // 10ms each
}

// ✅ FAST - Pipelined (50ms total)
const pipeline = redis.pipeline()
for (let i = 0; i < 100; i++) {
  pipeline.get(`key:${i}`)
}
const results = await pipeline.exec()
```

**2. Connection Pooling**
```javascript
import Redis from 'ioredis'

// ✅ Reuse connection
const redis = new Redis({
  maxRetriesPerRequest: 3,
  enableReadyCheck: true,
  enableOfflineQueue: false
})

// ❌ Don't create new connection per request
```

**3. Disable Slow Commands**
```conf
# redis.conf
rename-command KEYS ""
rename-command FLUSHDB ""
rename-command FLUSHALL ""
```

**4. Use Faster Data Structures**
```javascript
// For membership check:
// ❌ SLOW - O(N)
await redis.lrange('list', 0, -1) // then search in app

// ✅ FAST - O(1)
await redis.sismember('set', 'member')
```

---

## Throughput Optimization

### Maximize Throughput

**1. Connection Multiplexing**
```javascript
// Single connection can handle 100k+ ops/sec
// Use pipelining instead of multiple connections
const pipeline = redis.pipeline()

for (let i = 0; i < 10000; i++) {
  pipeline.set(`key:${i}`, i)
}

await pipeline.exec()
```

**2. Batch Operations**
```javascript
// ✅ Use MGET/MSET
await redis.mset('key1', 'val1', 'key2', 'val2', 'key3', 'val3')
const values = await redis.mget('key1', 'key2', 'key3')

// ❌ Avoid individual SET/GET
await redis.set('key1', 'val1')
await redis.set('key2', 'val2')
await redis.set('key3', 'val3')
```

**3. Use Lua Scripts**
```javascript
// ✅ Server-side execution (1 round-trip)
const script = `
  for i = 1, 1000 do
    redis.call('SET', 'key:' .. i, i)
  end
  return 1000
`
await redis.eval(script, 0)

// ❌ Client-side loop (1000 round-trips)
for (let i = 0; i < 1000; i++) {
  await redis.set(`key:${i}`, i)
}
```

---

## Slow Query Detection

### Slow Log

```conf
# redis.conf
slowlog-log-slower-than 10000  # 10ms
slowlog-max-len 128
```

```bash
# View slow queries
SLOWLOG GET 10

# Sample output:
# 1) 1) (integer) 15 (ID)
#    2) (integer) 1700136000 (timestamp)
#    3) (integer) 12000 (duration in microseconds)
#    4) 1) "KEYS" 2) "*" (command)
```

**Node.js:**
```javascript
async function getSlowQueries(count = 10) {
  const slowlog = await redis.slowlog('GET', count)

  return slowlog.map(entry => ({
    id: entry[0],
    timestamp: new Date(entry[1] * 1000),
    durationUs: entry[2],
    command: entry[3],
  }))
}

// Monitor for slow queries
setInterval(async () => {
  const slow = await getSlowQueries(10)

  for (const query of slow) {
    if (query.durationUs > 100000) { // > 100ms
      console.warn(`Slow query detected: ${query.command.join(' ')}`)
    }
  }
}, 60000) // Check every minute
```

---

## Network Optimization

### TCP Tuning (Linux)

```bash
# /etc/sysctl.conf

# Increase TCP buffer sizes
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216

# Enable TCP fast open
net.ipv4.tcp_fastopen = 3

# Reduce TIME_WAIT sockets
net.ipv4.tcp_tw_reuse = 1

# Apply changes
sysctl -p
```

### Redis TCP Settings

```conf
# redis.conf
tcp-backlog 511
tcp-keepalive 300
timeout 0
```

---

## Monitoring & Alerting

### Key Metrics to Monitor

```javascript
async function getKeyMetrics() {
  const [info, stats, memory] = await Promise.all([
    redis.info('server'),
    redis.info('stats'),
    redis.info('memory'),
  ])

  return {
    // Performance
    opsPerSec: parseInt(stats.match(/instantaneous_ops_per_sec:(\d+)/)[1]),
    hitRate: calculateHitRate(stats),

    // Memory
    usedMemory: parseInt(memory.match(/used_memory:(\d+)/)[1]),
    fragmentation: parseFloat(memory.match(/mem_fragmentation_ratio:([\d.]+)/)[1]),

    // Connections
    connectedClients: parseInt(stats.match(/connected_clients:(\d+)/)[1]),
    blockedClients: parseInt(stats.match(/blocked_clients:(\d+)/)[1]),

    // Persistence
    rdbLastSaveTime: parseInt(stats.match(/rdb_last_save_time:(\d+)/)[1]),
    aofCurrentSize: parseInt(stats.match(/aof_current_size:(\d+)/)?.[1] || 0),
  }
}

function calculateHitRate(stats) {
  const hits = parseInt(stats.match(/keyspace_hits:(\d+)/)[1])
  const misses = parseInt(stats.match(/keyspace_misses:(\d+)/)[1])
  const total = hits + misses
  return total > 0 ? (hits / total * 100).toFixed(2) : 0
}
```

### Alerts

```javascript
async function checkHealth() {
  const metrics = await getKeyMetrics()
  const alerts = []

  // High memory usage
  if (metrics.usedMemory > 0.9 * MAX_MEMORY) {
    alerts.push('Memory usage > 90%')
  }

  // High fragmentation
  if (metrics.fragmentation > 1.5) {
    alerts.push(`Memory fragmentation: ${metrics.fragmentation}`)
  }

  // Low hit rate
  if (metrics.hitRate < 80) {
    alerts.push(`Cache hit rate: ${metrics.hitRate}%`)
  }

  // Too many connections
  if (metrics.connectedClients > 1000) {
    alerts.push(`High connection count: ${metrics.connectedClients}`)
  }

  return alerts
}
```

---

## Production Best Practices

### 1. Set Memory Limits

```conf
maxmemory 2gb
maxmemory-policy allkeys-lru
```

### 2. Use Connection Pooling

```javascript
// Pool configuration
const redis = new Redis({
  maxRetriesPerRequest: 3,
  enableReadyCheck: true,
  retryStrategy: (times) => {
    return Math.min(times * 50, 2000)
  }
})
```

### 3. Monitor Key Metrics

- Operations/second
- Memory usage
- Hit rate
- Latency (p99)
- Connection count

### 4. Use Pipelining & Lua Scripts

- Batch operations
- Reduce round-trips
- Server-side processing

### 5. Avoid Expensive Commands

```javascript
// ❌ Avoid in production
KEYS *
FLUSHALL
FLUSHDB

// ✅ Use instead
SCAN 0 MATCH pattern COUNT 100
DEL key1 key2 key3
```

---

## Next Steps

1. **Clustering** → See `09-CLUSTERING.md`
2. **Replication** → See `10-REPLICATION.md`
3. **Production** → See `11-CONFIG-OPERATIONS.md`

---

## AI Pair Programming Notes

**When to load this KB:**
- Optimizing Redis performance
- Troubleshooting slow queries
- Reducing memory usage
- Improving throughput

**Common starting points:**
- Benchmarking: See Benchmarking section
- Memory: See Memory Optimization
- Latency: See Latency Optimization
- Monitoring: See Monitoring section

**Typical questions:**
- "How do I improve performance?" → Throughput Optimization
- "Why is Redis slow?" → Slow Query Detection
- "How do I reduce memory?" → Memory Optimization
- "What metrics should I monitor?" → Monitoring section

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1
