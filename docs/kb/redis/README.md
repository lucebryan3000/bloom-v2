---
id: redis-readme
topic: redis
file_role: overview
profile: full
difficulty_level: beginner
kb_version: 3.1
prerequisites: [networking-basics, command-line]
related_topics: [caching, nosql, key-value-stores, in-memory-databases]
embedding_keywords: [redis, overview, introduction, in-memory, cache, data-structures]
last_reviewed: 2025-11-16
---

# Redis Knowledge Base

**Complete reference for Redis - the in-memory data structure store used as database, cache, message broker, and streaming engine.**

## What is Redis?

Redis (REmote DIctionary Server) is an open-source, in-memory data structure store offering:
- **Sub-millisecond latency**: RAM-based storage for ultra-fast access
- **Rich data structures**: Strings, hashes, lists, sets, sorted sets, streams, and more
- **Versatility**: Database, cache, message broker, and queue in one
- **Persistence**: Optional RDB snapshots and AOF logs for data durability
- **High availability**: Master-replica replication with automatic failover (Sentinel/Cluster)
- **Horizontal scaling**: Redis Cluster for distributed deployments

### Why Redis?

**Performance**
- 100,000+ operations/second on modest hardware
- 1M+ ops/sec on high-end systems
- Sub-millisecond response times

**Use Cases**
- Caching (reduce database load by 80-95%)
- Session storage (fast retrieval, automatic expiration)
- Real-time analytics (leaderboards, counters, metrics)
- Message queues (Pub/Sub, Streams)
- Rate limiting (atomic counters with TTL)
- Geospatial data (location-based queries)

---

## Comparison with Other Solutions

| Feature | Redis | Memcached | MongoDB | PostgreSQL |
|---------|-------|-----------|---------|------------|
| **Type** | In-memory | In-memory | Document DB | Relational DB |
| **Latency** | 🟢 <1ms | 🟢 <1ms | 🟡 10-50ms | 🔴 50-200ms |
| **Data Structures** | 🟢 Rich | 🔴 String only | 🟡 Documents | 🟡 Tables |
| **Persistence** | ✅ Optional | ❌ No | ✅ Yes | ✅ Yes |
| **Replication** | ✅ Master-replica | ❌ No | ✅ Replica sets | ✅ Streaming |
| **Clustering** | ✅ Redis Cluster | ❌ No | ✅ Sharding | 🟡 External |
| **Transactions** | ✅ MULTI/EXEC | ❌ No | ✅ ACID | ✅ ACID |
| **Pub/Sub** | ✅ Built-in | ❌ No | ❌ No | ✅ LISTEN/NOTIFY |
| **Use Case** | Cache, Queue, DB | Cache only | Primary DB | Primary DB |

**When to choose Redis:**
- Need sub-millisecond latency
- Caching layer to reduce database load
- Real-time features (leaderboards, analytics)
- Message queues and Pub/Sub
- Session storage with automatic expiration
- Complex data structures (lists, sets, sorted sets)

**When to choose alternatives:**
- Primary database with complex queries → PostgreSQL/MongoDB
- Simple key-value cache only → Memcached
- ACID transactions with relations → PostgreSQL

---

## Learning Paths

### 🟢 Beginner Path (2-4 hours)

**Goal**: Understand Redis basics and build simple cache layer

1. **[01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md)** - Core concepts and architecture (30 min)
   - What is Redis and why use it
   - Installation and setup
   - Basic commands (GET/SET, TTL, data types)
   - Client libraries

2. **[02-BASIC-OPERATIONS.md](./02-BASIC-OPERATIONS.md)** - Essential CRUD operations (45 min)
   - String operations (SET/GET/INCR)
   - Key management (EXISTS/DEL/EXPIRE)
   - Pipelining basics
   - Common patterns (cache-aside, counters)

3. **[03-DATA-STRUCTURES.md](./03-DATA-STRUCTURES.md)** - Redis data types (1 hour)
   - Hashes (objects)
   - Lists (queues, stacks)
   - Sets (unique collections)
   - Sorted Sets (leaderboards)
   - Streams (event logs)

4. **Practice Project**: Build a caching layer
   - Implement cache-aside pattern
   - Set TTL on all cache keys
   - Track hit/miss rates
   - Handle cache failures gracefully

### 🟡 Intermediate Path (4-8 hours)

**Prerequisite**: Complete beginner path

**Goal**: Build production-ready Redis implementations

5. **[04-CACHING-STRATEGIES.md](./04-CACHING-STRATEGIES.md)** - Advanced caching (1.5 hours)
   - Cache-aside vs write-through vs write-back
   - Cache invalidation strategies
   - Cache stampede prevention
   - Multi-tier caching

6. **[05-PUBSUB.md](./05-PUBSUB.md)** - Real-time messaging (1 hour)
   - Publish/subscribe basics
   - Channel patterns
   - Real-time notifications
   - Chat applications

7. **[06-TRANSACTIONS.md](./06-TRANSACTIONS.md)** - Atomic operations (1 hour)
   - MULTI/EXEC transactions
   - WATCH optimistic locking
   - Lua scripting
   - Distributed locks

8. **[07-PERSISTENCE.md](./07-PERSISTENCE.md)** - Data durability (1 hour)
   - RDB snapshots vs AOF logs
   - Hybrid persistence
   - Backup strategies
   - Disaster recovery

9. **Practice Project**: Build high-availability cache
   - Hybrid persistence (RDB + AOF)
   - Cache invalidation on write
   - Rate limiting with Lua scripts
   - Automated backups

### 🔴 Advanced Path (8-12 hours)

**Prerequisite**: Complete intermediate path

**Goal**: Master production operations and distributed Redis

10. **[08-PERFORMANCE.md](./08-PERFORMANCE.md)** - Optimization (1.5 hours)
    - Benchmarking and profiling
    - Memory optimization
    - Latency reduction
    - Slow query detection

11. **[09-CLUSTERING.md](./09-CLUSTERING.md)** - Horizontal scaling (1.5 hours)
    - Redis Cluster setup
    - Automatic sharding
    - Hash slots and tags
    - Cluster operations

12. **[10-REPLICATION.md](./10-REPLICATION.md)** - High availability (1 hour)
    - Master-replica replication
    - Redis Sentinel
    - Automatic failover
    - Read scaling

13. **[11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md)** - Production ops (1.5 hours)
    - Security hardening
    - Monitoring and alerting
    - Troubleshooting
    - Deployment patterns

14. **Practice Project**: Deploy production cluster
    - 3-node Redis Cluster
    - Sentinel for high availability
    - Monitoring dashboard
    - Automated backups and recovery testing

---

## File Breakdown

### Core Files (Required Reading)

| File | Purpose | Lines | Difficulty | Time |
|------|---------|-------|------------|------|
| **[README.md](./README.md)** | Overview and learning paths | ~650 | Beginner | 15 min |
| **[INDEX.md](./INDEX.md)** | Complete navigation hub | ~600 | Beginner | 10 min |
| **[QUICK-REFERENCE.md](./QUICK-REFERENCE.md)** | Command cheat sheet | ~1000 | All levels | 5 min |

### Fundamentals (01-03)

| File | Purpose | Lines | Difficulty | Time |
|------|---------|-------|------------|------|
| **[01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md)** | Core concepts, installation, data types | 782 | Beginner | 30 min |
| **[02-BASIC-OPERATIONS.md](./02-BASIC-OPERATIONS.md)** | CRUD operations, key management | 700 | Beginner | 45 min |
| **[03-DATA-STRUCTURES.md](./03-DATA-STRUCTURES.md)** | Hashes, lists, sets, sorted sets, streams | 970 | Intermediate | 1 hour |

### Workflows (04-07)

| File | Purpose | Lines | Difficulty | Time |
|------|---------|-------|------------|------|
| **[04-CACHING-STRATEGIES.md](./04-CACHING-STRATEGIES.md)** | Cache patterns and invalidation | 849 | Intermediate | 1.5 hours |
| **[05-PUBSUB.md](./05-PUBSUB.md)** | Publish/subscribe messaging | 727 | Intermediate | 1 hour |
| **[06-TRANSACTIONS.md](./06-TRANSACTIONS.md)** | MULTI/EXEC, WATCH, Lua scripts | 751 | Intermediate | 1 hour |
| **[07-PERSISTENCE.md](./07-PERSISTENCE.md)** | RDB, AOF, backups, recovery | 576 | Intermediate | 1 hour |

### Advanced Topics (08-10)

| File | Purpose | Lines | Difficulty | Time |
|------|---------|-------|------------|------|
| **[08-PERFORMANCE.md](./08-PERFORMANCE.md)** | Optimization and tuning | 645 | Advanced | 1.5 hours |
| **[09-CLUSTERING.md](./09-CLUSTERING.md)** | Horizontal scaling with Cluster | 455 | Advanced | 1.5 hours |
| **[10-REPLICATION.md](./10-REPLICATION.md)** | High availability with Sentinel | 416 | Advanced | 1 hour |

### Configuration (11)

| File | Purpose | Lines | Difficulty | Time |
|------|---------|-------|------------|------|
| **[11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md)** | Production config and operations | 557 | Advanced | 1.5 hours |

### Reference Files

| File | Purpose | Lines | Difficulty | Time |
|------|---------|-------|------------|------|
| **[FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md)** | Advanced framework patterns | ~900 | Advanced | 1.5 hours |

---

## Quick Start

### Installation (Docker)

```bash
# Pull Redis image
docker pull redis:7-alpine

# Run Redis
docker run -d \
  --name redis-dev \
  -p 6379:6379 \
  redis:7-alpine

# Connect to CLI
docker exec -it redis-dev redis-cli
```

### Installation (Native)

**macOS:**
```bash
brew install redis
brew services start redis
redis-cli ping  # Output: PONG
```

**Ubuntu/Debian:**
```bash
curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list
sudo apt-get update
sudo apt-get install redis-server
redis-cli ping
```

### Your First Commands

```bash
# Set key-value
SET name "Alice"

# Get value
GET name  # Output: "Alice"

# Set with expiration (3600 seconds = 1 hour)
SETEX session:abc123 3600 "user_data"

# Increment counter
SET counter 100
INCR counter  # Output: 101

# Hash (object)
HSET user:1000 name "Alice" email "alice@example.com" age "30"
HGETALL user:1000

# List (queue)
LPUSH tasks "task1" "task2" "task3"
LRANGE tasks 0 -1

# Set (unique collection)
SADD tags "redis" "database" "cache"
SMEMBERS tags

# Sorted set (leaderboard)
ZADD leaderboard 100 "Alice" 200 "Bob" 150 "Charlie"
ZREVRANGE leaderboard 0 9 WITHSCORES  # Top 10
```

### Node.js Client

```bash
npm install ioredis
```

```javascript
import Redis from 'ioredis'

const redis = new Redis({
  host: 'localhost',
  port: 6379,
  password: 'your_password', // if set
})

// Basic operations
await redis.set('user:1000', 'Alice')
const user = await redis.get('user:1000')

// With expiration
await redis.setex('session:abc123', 3600, JSON.stringify(sessionData))

// Atomic increment
await redis.incr('pageviews')

// Hash
await redis.hset('user:1000', {
  name: 'Alice',
  email: 'alice@example.com',
  age: '30',
})
const userData = await redis.hgetall('user:1000')

// Pipeline (batch)
const pipeline = redis.pipeline()
pipeline.set('key1', 'value1')
pipeline.set('key2', 'value2')
pipeline.incr('counter')
await pipeline.exec()
```

---

## Common Use Cases

### "I want to..."

**Build a cache layer**
→ Start with [04-CACHING-STRATEGIES.md](./04-CACHING-STRATEGIES.md) → Cache-Aside Pattern
→ Then [02-BASIC-OPERATIONS.md](./02-BASIC-OPERATIONS.md) → TTL Management

**Implement rate limiting**
→ [06-TRANSACTIONS.md](./06-TRANSACTIONS.md) → Lua Scripts → Rate Limiting Pattern

**Build a real-time chat**
→ [05-PUBSUB.md](./05-PUBSUB.md) → Chat Application Pattern

**Create a leaderboard**
→ [03-DATA-STRUCTURES.md](./03-DATA-STRUCTURES.md) → Sorted Sets → Leaderboard Pattern

**Store sessions**
→ [02-BASIC-OPERATIONS.md](./02-BASIC-OPERATIONS.md) → Session Storage Pattern

**Ensure data durability**
→ [07-PERSISTENCE.md](./07-PERSISTENCE.md) → Hybrid Persistence

**Scale horizontally**
→ [09-CLUSTERING.md](./09-CLUSTERING.md) → Redis Cluster Setup

**High availability**
→ [10-REPLICATION.md](./10-REPLICATION.md) → Redis Sentinel

**Optimize performance**
→ [08-PERFORMANCE.md](./08-PERFORMANCE.md) → Performance Optimization

**Deploy to production**
→ [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) → Production Configuration

---

## Key Concepts Summary

### In-Memory Storage

Redis stores all data in RAM for ultra-fast access:
- GET/SET: <1ms latency
- 100k+ operations/second on modest hardware
- Trade-off: Data size limited by RAM

### Data Structures

Beyond key-value:
```bash
# Strings
SET counter 100
INCR counter

# Hashes (objects)
HSET user:1000 name "Alice" email "alice@example.com"

# Lists (queues)
LPUSH jobs "job1"
BRPOP jobs 0  # Blocking pop

# Sets (unique items)
SADD tags "redis" "cache"

# Sorted Sets (rankings)
ZADD leaderboard 100 "player1"
ZREVRANGE leaderboard 0 9  # Top 10
```

### TTL (Time To Live)

Automatic expiration:
```bash
# Set key with 1 hour TTL
SETEX cache:user:1000 3600 "{\"name\":\"Alice\"}"

# Check remaining time
TTL cache:user:1000  # Output: 3599 (seconds)

# Key automatically deleted after expiration
```

### Atomic Operations

All operations are atomic:
```javascript
// Race-condition free
await redis.incr('counter')  // Atomic increment

// vs traditional approach (NOT atomic)
const value = await db.get('counter')
await db.set('counter', value + 1)  // ❌ Another client could modify between GET and SET
```

---

## Production Checklist

- [ ] Set `maxmemory` limit
- [ ] Configure eviction policy (`allkeys-lru`)
- [ ] Enable persistence (RDB + AOF hybrid)
- [ ] Set strong password (`requirepass`)
- [ ] Disable dangerous commands (`FLUSHALL`, `KEYS`)
- [ ] Configure firewall rules
- [ ] Set up monitoring (memory, hit rate, latency)
- [ ] Implement automated backups
- [ ] Test disaster recovery
- [ ] Use connection pooling
- [ ] Set TTL on all cache keys
- [ ] Monitor slow queries
- [ ] Configure replication (master-replica)
- [ ] Set up Redis Sentinel (high availability)
- [ ] Document runbooks (failover, restore)

---

## Troubleshooting

### Common Issues

**Problem**: Classes not generating
**Solution**: Check `maxmemory` and eviction policy → See [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) → Configuration

**Problem**: High memory usage
**Solution**: Find large keys → See [08-PERFORMANCE.md](./08-PERFORMANCE.md) → Memory Optimization

**Problem**: Slow queries
**Solution**: Check slow log → See [08-PERFORMANCE.md](./08-PERFORMANCE.md) → Slow Query Detection

**Problem**: Connection timeouts
**Solution**: Check network and firewall → See [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) → Troubleshooting

---

## Additional Resources

### Official Documentation
- **Redis Docs**: https://redis.io/docs
- **Redis Commands**: https://redis.io/commands
- **Redis University**: https://university.redis.com (free courses)

### Tools
- **Redis Insight**: https://redis.com/redis-enterprise/redis-insight/ (GUI)
- **redis-cli**: Built-in command-line interface
- **redis-benchmark**: Built-in benchmarking tool

### Community
- **Redis GitHub**: https://github.com/redis/redis
- **Redis Forum**: https://forum.redis.com
- **Stack Overflow**: Tag `redis`

---

## FAQ

**Q: Is Redis a database or cache?**
A: Both. Redis can be used as a primary database (with persistence) or cache layer (with TTL and eviction).

**Q: Will I lose data if Redis crashes?**
A: Depends on persistence. With AOF (`appendfsync everysec`), you lose at most 1 second of data. With RDB only, you lose data since last snapshot.

**Q: How much data can Redis store?**
A: Limited by RAM. Typical production: 2-64GB. For larger datasets, use Redis Cluster.

**Q: Is Redis fast enough for real-time applications?**
A: Yes. Sub-millisecond latency makes it ideal for real-time use cases (chat, analytics, gaming).

**Q: Can I use Redis as my only database?**
A: For some applications, yes (with persistence enabled). For complex queries and analytics, combine with PostgreSQL/MongoDB.

**Q: How do I scale Redis?**
A: Vertically (more RAM) or horizontally (Redis Cluster with sharding).

---

## AI Pair Programming Notes

**When to load this KB:**
- Learning Redis from scratch
- Building cache layers
- Implementing real-time features
- Setting up production Redis

**Entry points by experience:**
- **Never used Redis**: Start with [01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md)
- **Used Redis before**: Jump to [QUICK-REFERENCE.md](./QUICK-REFERENCE.md)
- **Need specific pattern**: Use [INDEX.md](./INDEX.md) → "I want to..." section
- **Troubleshooting**: See [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) → Troubleshooting

**Recommended workflow:**
1. Read README.md (this file) to understand Redis philosophy
2. Follow a learning path based on your experience level
3. Use QUICK-REFERENCE.md for quick command lookups
4. Reference INDEX.md for problem-based navigation

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1 | **Total Lines**: ~10,000 across 15 files
