---
id: redis-index
topic: redis
file_role: navigation
profile: full
difficulty_level: beginner
kb_version: 3.1
prerequisites: []
related_topics: [caching, nosql, key-value-stores, in-memory-databases]
embedding_keywords: [redis, index, navigation, table-of-contents]
last_reviewed: 2025-11-16
---

# Redis - Complete Index

**Navigation hub for the Redis Knowledge Base - find what you need quickly.**

## Quick Navigation

- **[README.md](./README.md)** - Overview, learning paths, quick start
- **[QUICK-REFERENCE.md](./QUICK-REFERENCE.md)** - Command cheat sheet
- **[FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md)** - Advanced patterns

---

## Learning Paths

### 🟢 Beginner (2-4 hours)

**Start here if you're new to Redis**

1. [01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md) - Core concepts (30 min)
2. [02-BASIC-OPERATIONS.md](./02-BASIC-OPERATIONS.md) - CRUD operations (45 min)
3. [03-DATA-STRUCTURES.md](./03-DATA-STRUCTURES.md) - Data types (1 hour)

**Practice**: Build a simple cache layer

### 🟡 Intermediate (4-8 hours)

**Prerequisites**: Complete beginner path

4. [04-CACHING-STRATEGIES.md](./04-CACHING-STRATEGIES.md) - Advanced caching (1.5 hours)
5. [05-PUBSUB.md](./05-PUBSUB.md) - Real-time messaging (1 hour)
6. [06-TRANSACTIONS.md](./06-TRANSACTIONS.md) - Atomic operations (1 hour)
7. [07-PERSISTENCE.md](./07-PERSISTENCE.md) - Data durability (1 hour)

**Practice**: Build high-availability cache with persistence

### 🔴 Advanced (8-12 hours)

**Prerequisites**: Complete intermediate path

8. [08-PERFORMANCE.md](./08-PERFORMANCE.md) - Optimization (1.5 hours)
9. [09-CLUSTERING.md](./09-CLUSTERING.md) - Horizontal scaling (1.5 hours)
10. [10-REPLICATION.md](./10-REPLICATION.md) - High availability (1 hour)
11. [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) - Production ops (1.5 hours)

**Practice**: Deploy production cluster with monitoring

---

## Problem-Based Quick Find

### "I want to..."

**Cache database queries**
→ [04-CACHING-STRATEGIES.md](./04-CACHING-STRATEGIES.md) → Cache-Aside Pattern
→ [02-BASIC-OPERATIONS.md](./02-BASIC-OPERATIONS.md) → TTL Management

**Build a real-time feature**
→ [05-PUBSUB.md](./05-PUBSUB.md) → Publish/Subscribe
→ [03-DATA-STRUCTURES.md](./03-DATA-STRUCTURES.md) → Streams

**Implement rate limiting**
→ [06-TRANSACTIONS.md](./06-TRANSACTIONS.md) → Lua Scripts → Rate Limiting Pattern
→ [02-BASIC-OPERATIONS.md](./02-BASIC-OPERATIONS.md) → INCR with EXPIRE

**Create a leaderboard**
→ [03-DATA-STRUCTURES.md](./03-DATA-STRUCTURES.md) → Sorted Sets → Leaderboard Pattern

**Store user sessions**
→ [02-BASIC-OPERATIONS.md](./02-BASIC-OPERATIONS.md) → Session Storage Pattern
→ [04-CACHING-STRATEGIES.md](./04-CACHING-STRATEGIES.md) → TTL-Based Invalidation

**Build a job queue**
→ [03-DATA-STRUCTURES.md](./03-DATA-STRUCTURES.md) → Lists → Queue Pattern
→ [05-PUBSUB.md](./05-PUBSUB.md) → Pub/Sub vs Streams

**Implement distributed locks**
→ [06-TRANSACTIONS.md](./06-TRANSACTIONS.md) → Distributed Lock Pattern
→ [02-BASIC-OPERATIONS.md](./02-BASIC-OPERATIONS.md) → SETNX

**Track unique visitors**
→ [03-DATA-STRUCTURES.md](./03-DATA-STRUCTURES.md) → Sets → Unique Visitors Pattern

**Build a chat application**
→ [05-PUBSUB.md](./05-PUBSUB.md) → Chat Application Pattern

**Prevent cache stampede**
→ [04-CACHING-STRATEGIES.md](./04-CACHING-STRATEGIES.md) → Cache Stampede Prevention

**Ensure data durability**
→ [07-PERSISTENCE.md](./07-PERSISTENCE.md) → Hybrid Persistence (RDB + AOF)

**Backup Redis data**
→ [07-PERSISTENCE.md](./07-PERSISTENCE.md) → Backups & Disaster Recovery

**Optimize memory usage**
→ [08-PERFORMANCE.md](./08-PERFORMANCE.md) → Memory Optimization

**Reduce latency**
→ [08-PERFORMANCE.md](./08-PERFORMANCE.md) → Latency Optimization
→ [02-BASIC-OPERATIONS.md](./02-BASIC-OPERATIONS.md) → Pipelining

**Scale horizontally**
→ [09-CLUSTERING.md](./09-CLUSTERING.md) → Redis Cluster Setup

**Set up high availability**
→ [10-REPLICATION.md](./10-REPLICATION.md) → Redis Sentinel

**Secure Redis**
→ [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) → Security

**Monitor Redis**
→ [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) → Monitoring

**Troubleshoot issues**
→ [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) → Troubleshooting
→ [08-PERFORMANCE.md](./08-PERFORMANCE.md) → Slow Query Detection

**Deploy to production**
→ [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) → Production Configuration
→ [07-PERSISTENCE.md](./07-PERSISTENCE.md) → Backups

---

## Complete File Breakdown

### Core Navigation Files

| File | Purpose | Lines | Time |
|------|---------|-------|------|
| [README.md](./README.md) | Overview, learning paths, quick start | 655 | 15 min |
| [INDEX.md](./INDEX.md) | Navigation hub (this file) | 600 | 10 min |
| [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) | Command cheat sheet | 1000 | 5 min |
| [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md) | Advanced patterns | 900 | 1.5 hours |

### Fundamentals

| File | Topics | Lines | Difficulty | Time |
|------|--------|-------|------------|------|
| [01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md) | Core concepts, installation, architecture, data types overview, CLI basics, client libraries | 782 | Beginner | 30 min |
| [02-BASIC-OPERATIONS.md](./02-BASIC-OPERATIONS.md) | String operations, numeric operations, key management, TTL, batch operations, common patterns | 700 | Beginner | 45 min |
| [03-DATA-STRUCTURES.md](./03-DATA-STRUCTURES.md) | Hashes, Lists, Sets, Sorted Sets, Streams with production patterns | 970 | Intermediate | 1 hour |

### Workflows & Patterns

| File | Topics | Lines | Difficulty | Time |
|------|--------|-------|------------|------|
| [04-CACHING-STRATEGIES.md](./04-CACHING-STRATEGIES.md) | Cache-aside, write-through, write-back, invalidation, cache stampede, eviction policies | 849 | Intermediate | 1.5 hours |
| [05-PUBSUB.md](./05-PUBSUB.md) | Publish/subscribe, channels, patterns, real-time notifications, chat, event broadcasting | 727 | Intermediate | 1 hour |
| [06-TRANSACTIONS.md](./06-TRANSACTIONS.md) | MULTI/EXEC, WATCH, Lua scripting, atomic operations, distributed locks | 751 | Intermediate | 1 hour |
| [07-PERSISTENCE.md](./07-PERSISTENCE.md) | RDB snapshots, AOF logs, hybrid persistence, backups, disaster recovery | 576 | Intermediate | 1 hour |

### Advanced Topics

| File | Topics | Lines | Difficulty | Time |
|------|--------|-------|------------|------|
| [08-PERFORMANCE.md](./08-PERFORMANCE.md) | Benchmarking, memory optimization, latency reduction, slow queries, monitoring | 645 | Advanced | 1.5 hours |
| [09-CLUSTERING.md](./09-CLUSTERING.md) | Redis Cluster, horizontal scaling, sharding, hash slots, cluster operations | 455 | Advanced | 1.5 hours |
| [10-REPLICATION.md](./10-REPLICATION.md) | Master-replica replication, Redis Sentinel, automatic failover, read scaling | 416 | Advanced | 1 hour |

### Configuration & Operations

| File | Topics | Lines | Difficulty | Time |
|------|--------|-------|------------|------|
| [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) | Production config, security, monitoring, troubleshooting, deployment patterns | 557 | Advanced | 1.5 hours |

---

## By Topic

### Installation & Setup

- **Docker setup** → [01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md) → Installation → Docker
- **Linux installation** → [01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md) → Installation → Linux
- **macOS installation** → [01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md) → Installation → macOS
- **Client libraries** → [01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md) → Client Libraries
- **Configuration** → [01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md) → Basic Configuration

### Data Structures

- **Strings** → [01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md) → Data Types → Strings
- **Hashes** → [03-DATA-STRUCTURES.md](./03-DATA-STRUCTURES.md) → Hashes
- **Lists** → [03-DATA-STRUCTURES.md](./03-DATA-STRUCTURES.md) → Lists
- **Sets** → [03-DATA-STRUCTURES.md](./03-DATA-STRUCTURES.md) → Sets
- **Sorted Sets** → [03-DATA-STRUCTURES.md](./03-DATA-STRUCTURES.md) → Sorted Sets
- **Streams** → [03-DATA-STRUCTURES.md](./03-DATA-STRUCTURES.md) → Streams

### Commands

- **String commands** → [02-BASIC-OPERATIONS.md](./02-BASIC-OPERATIONS.md) → String Operations
- **Numeric commands** → [02-BASIC-OPERATIONS.md](./02-BASIC-OPERATIONS.md) → Numeric Operations
- **Key management** → [02-BASIC-OPERATIONS.md](./02-BASIC-OPERATIONS.md) → Key Management
- **Expiration (TTL)** → [02-BASIC-OPERATIONS.md](./02-BASIC-OPERATIONS.md) → Expiration
- **Batch operations** → [02-BASIC-OPERATIONS.md](./02-BASIC-OPERATIONS.md) → Batch Operations
- **Transactions** → [06-TRANSACTIONS.md](./06-TRANSACTIONS.md) → MULTI/EXEC

### Caching

- **Cache-aside pattern** → [04-CACHING-STRATEGIES.md](./04-CACHING-STRATEGIES.md) → Cache-Aside
- **Write-through** → [04-CACHING-STRATEGIES.md](./04-CACHING-STRATEGIES.md) → Write-Through
- **Cache invalidation** → [04-CACHING-STRATEGIES.md](./04-CACHING-STRATEGIES.md) → Cache Invalidation
- **Eviction policies** → [04-CACHING-STRATEGIES.md](./04-CACHING-STRATEGIES.md) → Eviction Policies
- **Multi-tier caching** → [04-CACHING-STRATEGIES.md](./04-CACHING-STRATEGIES.md) → Multi-Tier Caching

### Real-Time Features

- **Pub/Sub messaging** → [05-PUBSUB.md](./05-PUBSUB.md) → Basic Pub/Sub
- **Channels** → [05-PUBSUB.md](./05-PUBSUB.md) → PUBLISH/SUBSCRIBE
- **Pattern matching** → [05-PUBSUB.md](./05-PUBSUB.md) → Pattern Matching
- **Chat applications** → [05-PUBSUB.md](./05-PUBSUB.md) → Chat Application
- **Notifications** → [05-PUBSUB.md](./05-PUBSUB.md) → Real-Time Notifications

### Atomicity & Transactions

- **MULTI/EXEC** → [06-TRANSACTIONS.md](./06-TRANSACTIONS.md) → MULTI/EXEC
- **WATCH (optimistic locking)** → [06-TRANSACTIONS.md](./06-TRANSACTIONS.md) → WATCH
- **Lua scripts** → [06-TRANSACTIONS.md](./06-TRANSACTIONS.md) → Lua Scripting
- **Pipelining** → [06-TRANSACTIONS.md](./06-TRANSACTIONS.md) → Pipelining
- **Distributed locks** → [06-TRANSACTIONS.md](./06-TRANSACTIONS.md) → Distributed Lock

### Persistence & Durability

- **RDB snapshots** → [07-PERSISTENCE.md](./07-PERSISTENCE.md) → RDB
- **AOF (Append-Only File)** → [07-PERSISTENCE.md](./07-PERSISTENCE.md) → AOF
- **Hybrid persistence** → [07-PERSISTENCE.md](./07-PERSISTENCE.md) → Hybrid Persistence
- **Backups** → [07-PERSISTENCE.md](./07-PERSISTENCE.md) → Backups & Disaster Recovery
- **Restore** → [07-PERSISTENCE.md](./07-PERSISTENCE.md) → Restore & Recovery

### Performance

- **Benchmarking** → [08-PERFORMANCE.md](./08-PERFORMANCE.md) → Benchmarking Redis
- **Memory optimization** → [08-PERFORMANCE.md](./08-PERFORMANCE.md) → Memory Optimization
- **Latency optimization** → [08-PERFORMANCE.md](./08-PERFORMANCE.md) → Latency Optimization
- **Slow queries** → [08-PERFORMANCE.md](./08-PERFORMANCE.md) → Slow Query Detection
- **Monitoring** → [08-PERFORMANCE.md](./08-PERFORMANCE.md) → Monitoring & Alerting

### Scaling

- **Horizontal scaling** → [09-CLUSTERING.md](./09-CLUSTERING.md) → Redis Cluster
- **Vertical scaling** → [08-PERFORMANCE.md](./08-PERFORMANCE.md) → Memory Optimization
- **Sharding** → [09-CLUSTERING.md](./09-CLUSTERING.md) → Automatic Sharding
- **Hash slots** → [09-CLUSTERING.md](./09-CLUSTERING.md) → Hash Slots

### High Availability

- **Replication** → [10-REPLICATION.md](./10-REPLICATION.md) → Master-Replica
- **Redis Sentinel** → [10-REPLICATION.md](./10-REPLICATION.md) → Redis Sentinel
- **Automatic failover** → [10-REPLICATION.md](./10-REPLICATION.md) → Failover Process
- **Read scaling** → [10-REPLICATION.md](./10-REPLICATION.md) → Read Scaling

### Production Operations

- **Security** → [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) → Security
- **Configuration** → [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) → Production Configuration
- **Monitoring** → [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) → Monitoring
- **Troubleshooting** → [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) → Troubleshooting
- **Deployment** → [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) → Deployment Patterns

---

## Common Patterns

### Caching Patterns

- **Cache-aside** → [04-CACHING-STRATEGIES.md](./04-CACHING-STRATEGIES.md) → Cache-Aside
- **Session storage** → [02-BASIC-OPERATIONS.md](./02-BASIC-OPERATIONS.md) → Session Storage Pattern
- **Multi-tier cache** → [04-CACHING-STRATEGIES.md](./04-CACHING-STRATEGIES.md) → Multi-Tier Caching

### Data Patterns

- **Leaderboards** → [03-DATA-STRUCTURES.md](./03-DATA-STRUCTURES.md) → Sorted Sets → Leaderboard
- **Job queues** → [03-DATA-STRUCTURES.md](./03-DATA-STRUCTURES.md) → Lists → Queue Pattern
- **Counters** → [02-BASIC-OPERATIONS.md](./02-BASIC-OPERATIONS.md) → Numeric Operations
- **Tagging** → [03-DATA-STRUCTURES.md](./03-DATA-STRUCTURES.md) → Sets → Tagging System
- **Following/Followers** → [03-DATA-STRUCTURES.md](./03-DATA-STRUCTURES.md) → Sets → Following Pattern

### Application Patterns

- **Rate limiting** → [06-TRANSACTIONS.md](./06-TRANSACTIONS.md) → Rate Limiting Pattern
- **Distributed locks** → [06-TRANSACTIONS.md](./06-TRANSACTIONS.md) → Distributed Lock
- **Real-time chat** → [05-PUBSUB.md](./05-PUBSUB.md) → Chat Application
- **Event broadcasting** → [05-PUBSUB.md](./05-PUBSUB.md) → Event Broadcasting
- **Cache invalidation** → [04-CACHING-STRATEGIES.md](./04-CACHING-STRATEGIES.md) → Event-Based Invalidation

---

## Syntax Quick Lookup

### Basic Commands

```bash
# Strings
SET key value
GET key
SETEX key seconds value
INCR key
DECR key

# Hashes
HSET key field value
HGET key field
HGETALL key
HINCRBY key field increment

# Lists
LPUSH key value
RPUSH key value
LRANGE key start stop
LPOP key
RPOP key

# Sets
SADD key member
SMEMBERS key
SISMEMBER key member
SINTER key1 key2

# Sorted Sets
ZADD key score member
ZRANGE key start stop WITHSCORES
ZREVRANGE key start stop
ZRANK key member

# Key Management
EXISTS key
DEL key
EXPIRE key seconds
TTL key
KEYS pattern
SCAN cursor MATCH pattern

# Transactions
MULTI
commands...
EXEC

# Pub/Sub
PUBLISH channel message
SUBSCRIBE channel
PSUBSCRIBE pattern
```

---

## Related Resources

### Official Documentation
- **Redis Docs**: https://redis.io/docs
- **Redis Commands**: https://redis.io/commands
- **Redis University**: https://university.redis.com

### Tools
- **Redis Insight**: GUI for Redis
- **redis-cli**: Command-line interface
- **redis-benchmark**: Performance testing

### Community
- **GitHub**: https://github.com/redis/redis
- **Forum**: https://forum.redis.com
- **Stack Overflow**: Tag `redis`

---

## AI Pair Programming Notes

**When to use this index:**
- Finding specific topics quickly
- Problem-based navigation ("I want to...")
- Understanding file organization
- Planning learning path

**Navigation strategies:**
1. **Problem-first**: Use "I want to..." section
2. **Topic-first**: Use "By Topic" section
3. **Sequential learning**: Follow learning paths
4. **Quick reference**: Jump to QUICK-REFERENCE.md

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1
