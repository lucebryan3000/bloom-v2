---
id: redis-clustering
topic: redis
file_role: guide
profile: full
difficulty_level: advanced
kb_version: 3.1
prerequisites: [redis-fundamentals, redis-performance, redis-replication]
related_topics: [horizontal-scaling, sharding, high-availability, distributed-systems]
embedding_keywords: [redis, cluster, clustering, sharding, scaling, distributed, high-availability]
last_reviewed: 2025-11-16
---

# Redis - Clustering & Horizontal Scaling

Comprehensive guide to Redis Cluster for horizontal scaling, automatic sharding, and high availability.

## Overview

Redis Cluster provides automatic sharding across multiple nodes with built-in replication and failover.

---

## What is Redis Cluster?

**Key Features:**
- **Automatic sharding**: Data distributed across multiple nodes
- **High availability**: Automatic failover
- **Horizontal scaling**: Add/remove nodes online
- **No single point of failure**: Master-replica replication

**Architecture:**
```
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│  Master 1   │  │  Master 2   │  │  Master 3   │
│ (slots 0-   │  │ (slots      │  │ (slots      │
│   5460)     │  │ 5461-10922) │  │ 10923-16383)│
└─────┬───────┘  └─────┬───────┘  └─────┬───────┘
      │                │                │
┌─────▼───────┐  ┌─────▼───────┐  ┌─────▼───────┐
│  Replica 1  │  │  Replica 2  │  │  Replica 3  │
└─────────────┘  └─────────────┘  └─────────────┘
```

**Hash Slots:**
- 16,384 total slots (0-16383)
- Each key assigned to slot via CRC16 hash
- Slots distributed across master nodes

---

## Setting Up Cluster

### Minimum Configuration

**Requirements:**
- Minimum 3 master nodes (recommended: 3 masters + 3 replicas)
- Each node needs unique port
- All nodes must be able to reach each other

### Create Cluster (Docker)

```bash
# Create network
docker network create redis-cluster

# Start 6 nodes (3 masters + 3 replicas)
for i in {1..6}; do
  docker run -d --name redis-$i \
    --network redis-cluster \
    -p 700$i:6379 \
    redis:7-alpine \
    redis-server \
    --cluster-enabled yes \
    --cluster-config-file nodes.conf \
    --cluster-node-timeout 5000 \
    --appendonly yes
done

# Create cluster
docker run -it --rm --network redis-cluster redis:7-alpine \
  redis-cli --cluster create \
  redis-1:6379 redis-2:6379 redis-3:6379 \
  redis-4:6379 redis-5:6379 redis-6:6379 \
  --cluster-replicas 1
```

### Manual Configuration

```conf
# redis-7001.conf
port 7001
cluster-enabled yes
cluster-config-file nodes-7001.conf
cluster-node-timeout 5000
appendonly yes
```

```bash
# Start nodes
redis-server redis-7001.conf
redis-server redis-7002.conf
redis-server redis-7003.conf
redis-server redis-7004.conf
redis-server redis-7005.conf
redis-server redis-7006.conf

# Create cluster
redis-cli --cluster create \
  127.0.0.1:7001 127.0.0.1:7002 127.0.0.1:7003 \
  127.0.0.1:7004 127.0.0.1:7005 127.0.0.1:7006 \
  --cluster-replicas 1
```

---

## Cluster Operations

### Check Cluster Health

```bash
# Cluster info
redis-cli -c -p 7001 CLUSTER INFO

# Output:
# cluster_state:ok
# cluster_slots_assigned:16384
# cluster_slots_ok:16384
# cluster_known_nodes:6
# cluster_size:3

# Node list
redis-cli -c -p 7001 CLUSTER NODES

# Check cluster
redis-cli --cluster check 127.0.0.1:7001
```

### Add Node

```bash
# Add new master
redis-cli --cluster add-node 127.0.0.1:7007 127.0.0.1:7001

# Add replica
redis-cli --cluster add-node 127.0.0.1:7008 127.0.0.1:7001 \
  --cluster-slave \
  --cluster-master-id <master-node-id>
```

### Remove Node

```bash
# Get node ID
redis-cli -c -p 7001 CLUSTER NODES | grep 7007

# Remove node
redis-cli --cluster del-node 127.0.0.1:7001 <node-id>
```

### Rebalance Cluster

```bash
# Rebalance slots across all masters
redis-cli --cluster rebalance 127.0.0.1:7001

# Rebalance with specific weight
redis-cli --cluster rebalance 127.0.0.1:7001 \
  --cluster-weight <node1>=1 <node2>=2 <node3>=3
```

### Reshard Cluster

```bash
# Move slots between nodes
redis-cli --cluster reshard 127.0.0.1:7001

# Automated reshard
redis-cli --cluster reshard 127.0.0.1:7001 \
  --cluster-from <source-node-id> \
  --cluster-to <dest-node-id> \
  --cluster-slots 1000 \
  --cluster-yes
```

---

## Client Usage

### Node.js (ioredis)

```javascript
import Redis from 'ioredis'

// Connect to cluster
const cluster = new Redis.Cluster([
  { host: '127.0.0.1', port: 7001 },
  { host: '127.0.0.1', port: 7002 },
  { host: '127.0.0.1', port: 7003 },
], {
  redisOptions: {
    password: 'your_password',
  },
  clusterRetryStrategy: (times) => {
    return Math.min(times * 100, 2000)
  }
})

// Use like normal Redis
await cluster.set('key', 'value')
const value = await cluster.get('key')

// Keys on same slot (hash tags)
await cluster.set('{user:1000}:name', 'Alice')
await cluster.set('{user:1000}:email', 'alice@example.com')
// Both keys on same slot due to {user:1000} hash tag

// Pipeline
const pipeline = cluster.pipeline()
pipeline.set('key1', 'value1')
pipeline.set('key2', 'value2')
await pipeline.exec()
```

### Hash Tags

**Problem**: Multi-key operations require all keys on same slot

**Solution**: Use hash tags to force keys to same slot

```javascript
// ❌ WRONG - Keys on different slots
await cluster.mget('user:1000:name', 'user:1000:email')
// Error: CROSSSLOT Keys in request don't hash to the same slot

// ✅ CORRECT - Hash tag forces same slot
await cluster.mget('{user:1000}:name', '{user:1000}:email')
// Only {user:1000} is hashed, rest is metadata
```

---

## Cluster Limitations

### Multi-Key Operations

**Limitation**: Multi-key commands require all keys on same slot

```javascript
// ❌ These fail across slots:
MGET key1 key2 key3  // Unless all on same slot
SUNION set1 set2 set3
ZINTERSTORE dest numkeys key1 key2

// ✅ Use hash tags:
MGET {user}:key1 {user}:key2 {user}:key3
```

### Transactions

**Limitation**: MULTI/EXEC works only on single slot

```javascript
// ❌ WRONG - Keys on different slots
cluster.multi()
  .set('key1', 'value1')
  .set('key2', 'value2')
  .exec()
// Error if key1 and key2 on different slots

// ✅ CORRECT - Same slot via hash tag
cluster.multi()
  .set('{user:1000}:field1', 'value1')
  .set('{user:1000}:field2', 'value2')
  .exec()
```

### Pub/Sub

**Limitation**: Pub/Sub is node-local, not cluster-wide

**Workaround**: Use Redis Streams for distributed messaging

---

## Failover

### Automatic Failover

**When master fails:**
1. Replicas detect master down (timeout)
2. Replicas vote for new master
3. Winning replica promotes itself
4. Clients redirected to new master

**Minimum requirements:**
- Majority of masters must be reachable
- Failed master must have at least one replica

### Manual Failover

```bash
# Force replica to become master
redis-cli -c -p 7004 CLUSTER FAILOVER

# Takeover (no voting)
redis-cli -c -p 7004 CLUSTER FAILOVER FORCE
```

---

## Monitoring Cluster

### Health Checks

```javascript
async function checkClusterHealth(cluster) {
  const nodes = await cluster.cluster('NODES')
  const lines = nodes.split('\n').filter(line => line.trim())

  const health = {
    masters: 0,
    replicas: 0,
    failed: 0,
    online: 0,
  }

  for (const line of lines) {
    if (line.includes('master')) health.masters++
    if (line.includes('slave')) health.replicas++
    if (line.includes('fail')) health.failed++
    if (!line.includes('fail') && line.includes('connected')) health.online++
  }

  return health
}

// Usage
const health = await checkClusterHealth(cluster)
console.log(health)
// { masters: 3, replicas: 3, failed: 0, online: 6 }

if (health.failed > 0) {
  console.warn(`${health.failed} nodes failed!`)
}
```

### Slot Coverage

```javascript
async function checkSlotCoverage(cluster) {
  const info = await cluster.cluster('INFO')

  const match = info.match(/cluster_slots_assigned:(\d+)/)
  const assigned = parseInt(match[1])

  return {
    assigned,
    total: 16384,
    coverage: (assigned / 16384 * 100).toFixed(2),
    complete: assigned === 16384,
  }
}
```

---

## Best Practices

### 1. Use Hash Tags Wisely

```javascript
// ✅ Group related keys
'{user:1000}:profile'
'{user:1000}:settings'
'{user:1000}:sessions'

// ❌ Don't overuse (creates hot spots)
'{global}:key1'
'{global}:key2'  // All keys on one node!
```

### 2. Plan for Growth

```javascript
// Start with 3 masters minimum
// Add capacity before hitting limits
// Monitor slot distribution
```

### 3. Monitor Cluster Health

```javascript
setInterval(async () => {
  const health = await checkClusterHealth(cluster)
  if (health.failed > 0) {
    alert('Cluster nodes failed!')
  }
}, 60000)
```

### 4. Test Failover

```bash
# Simulate master failure
docker stop redis-1

# Verify automatic failover
redis-cli -c -p 7002 CLUSTER NODES

# Restart failed node
docker start redis-1
```

### 5. Backup Strategy

```bash
# Backup each node
for port in 7001 7002 7003; do
  redis-cli -p $port BGSAVE
done
```

---

## Next Steps

1. **Replication** → See `10-REPLICATION.md`
2. **Production** → See `11-CONFIG-OPERATIONS.md`

---

## AI Pair Programming Notes

**When to load this KB:**
- Scaling Redis horizontally
- Setting up Redis Cluster
- High availability requirements
- Distributed Redis deployment

**Common starting points:**
- Setup: See Setting Up Cluster
- Operations: See Cluster Operations
- Client usage: See Client Usage
- Limitations: See Cluster Limitations

**Typical questions:**
- "How do I scale Redis?" → Setting Up Cluster
- "How does failover work?" → Failover section
- "Why do multi-key commands fail?" → Cluster Limitations
- "How do I monitor cluster?" → Monitoring section

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1
