---
id: redis-fundamentals
topic: redis
file_role: fundamentals
profile: full
difficulty_level: beginner
kb_version: 3.1
prerequisites: [networking-basics, command-line]
related_topics: [caching, nosql, key-value-stores, data-structures]
embedding_keywords: [redis, fundamentals, basics, key-value-store, in-memory-database, cache]
last_reviewed: 2025-11-16
---

# Redis - Fundamentals

Understanding the core concepts and architecture of Redis, the in-memory data structure store.

## What is Redis?

**Redis** (REmote DIctionary Server) is an open-source, in-memory data structure store used as a database, cache, message broker, and streaming engine. It supports various data structures including strings, hashes, lists, sets, sorted sets, bitmaps, hyperloglogs, geospatial indexes, and streams.

### Key Characteristics

- **In-Memory Storage**: All data resides in RAM for ultra-fast access (sub-millisecond latency)
- **Persistence Options**: Optional disk persistence (RDB snapshots, AOF logs)
- **Atomic Operations**: All operations are atomic by design
- **Data Structures**: Rich set of native data structures beyond simple key-value
- **Single-Threaded**: Uses event loop for concurrency (6.0+ has I/O threading)
- **Replication**: Master-replica replication with automatic failover
- **Pub/Sub**: Built-in publish/subscribe messaging
- **Lua Scripting**: Server-side scripting support
- **Clustering**: Horizontal scaling with Redis Cluster

---

## Why Use Redis?

### Performance

**Ultra-Fast Operations**
```bash
# Typical Redis operations
GET key           # <1ms latency
SET key value     # <1ms latency
INCR counter      # <1ms latency

# Can handle 100k+ ops/sec on modest hardware
# 1M+ ops/sec on high-end systems
```

**In-Memory Speed**
- RAM access: ~100 nanoseconds
- SSD access: ~150 microseconds (1,500x slower)
- HDD access: ~10 milliseconds (100,000x slower)

### Use Cases

**1. Caching**
```javascript
// Cache database queries
const cachedUser = await redis.get(`user:${userId}`)
if (cachedUser) {
  return JSON.parse(cachedUser)
}

const user = await db.users.findOne({ id: userId })
await redis.setex(`user:${userId}`, 3600, JSON.stringify(user))
return user
```

**2. Session Storage**
```javascript
// Fast session retrieval
await redis.setex(`session:${sessionId}`, 1800, JSON.stringify(sessionData))
const session = await redis.get(`session:${sessionId}`)
```

**3. Rate Limiting**
```javascript
// Track API requests
const requests = await redis.incr(`rate:${userId}:${minute}`)
await redis.expire(`rate:${userId}:${minute}`, 60)

if (requests > 100) {
  throw new Error('Rate limit exceeded')
}
```

**4. Real-Time Analytics**
```javascript
// Track page views
await redis.hincrby('pageviews', '/home', 1)
await redis.zadd('trending', Date.now(), articleId)
```

**5. Message Queues**
```javascript
// Simple job queue
await redis.lpush('jobs', JSON.stringify(job))
const job = await redis.brpop('jobs', 0) // Blocking pop
```

**6. Leaderboards**
```javascript
// Gaming leaderboard
await redis.zadd('leaderboard', score, userId)
const top10 = await redis.zrevrange('leaderboard', 0, 9, 'WITHSCORES')
```

---

## Core Architecture

### Memory Management

```
┌─────────────────────────────────────┐
│       Redis Process (RAM)           │
├─────────────────────────────────────┤
│  Data Structures                    │
│  ├─ Strings                         │
│  ├─ Hashes                          │
│  ├─ Lists                           │
│  ├─ Sets                            │
│  ├─ Sorted Sets                     │
│  └─ Streams                         │
├─────────────────────────────────────┤
│  Event Loop (Single Thread)         │
│  ├─ Client Connections              │
│  ├─ Command Processing              │
│  └─ I/O Multiplexing                │
├─────────────────────────────────────┤
│  Optional Persistence               │
│  ├─ RDB (Snapshots)                 │
│  └─ AOF (Append-Only File)          │
└─────────────────────────────────────┘
```

### Single-Threaded Model

**Event Loop:**
```
Client Request → Command Queue → Execute → Response Queue → Client
                     ↓
                Event Loop
                (epoll/kqueue)
```

**Why Single-Threaded?**
- No lock contention
- Predictable performance
- Simple mental model
- CPU is rarely the bottleneck (memory access is)

**Redis 6.0+ I/O Threading:**
- Main thread: Command execution (still single-threaded)
- I/O threads: Network I/O (reading/writing to sockets)

---

## Installation

### Option 1: Docker (Recommended for Development)

```bash
# Pull official Redis image
docker pull redis:7-alpine

# Run Redis container
docker run -d \
  --name redis-dev \
  -p 6379:6379 \
  -v redis-data:/data \
  redis:7-alpine \
  redis-server --appendonly yes

# Connect to Redis CLI
docker exec -it redis-dev redis-cli
```

### Option 2: Linux Installation

**Ubuntu/Debian:**
```bash
# Add Redis repository
curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list

# Install Redis
sudo apt-get update
sudo apt-get install redis-server

# Start Redis
sudo systemctl start redis-server
sudo systemctl enable redis-server

# Verify installation
redis-cli ping
# Output: PONG
```

**macOS:**
```bash
# Using Homebrew
brew install redis

# Start Redis
brew services start redis

# Verify
redis-cli ping
```

### Option 3: Build from Source

```bash
# Download and extract
wget https://download.redis.io/releases/redis-7.2.3.tar.gz
tar xzf redis-7.2.3.tar.gz
cd redis-7.2.3

# Compile
make

# Optional: Run tests
make test

# Install
sudo make install

# Start Redis server
redis-server
```

---

## Basic Configuration

### redis.conf Essentials

```conf
# Network
bind 127.0.0.1          # Accept connections from localhost only
port 6379               # Default Redis port
protected-mode yes      # Prevent external connections without auth

# Memory
maxmemory 256mb         # Limit memory usage
maxmemory-policy allkeys-lru  # Eviction policy when maxmemory reached

# Persistence
save 900 1              # Save after 900s if 1 key changed
save 300 10             # Save after 300s if 10 keys changed
save 60 10000           # Save after 60s if 10000 keys changed

appendonly yes          # Enable AOF persistence
appendfsync everysec    # Fsync every second (balance of safety/performance)

# Security
requirepass your_password_here  # Require password authentication

# Logging
loglevel notice         # Log verbosity: debug, verbose, notice, warning
logfile /var/log/redis/redis.log

# Limits
maxclients 10000        # Maximum simultaneous clients
```

### Minimal Development Config

```conf
# redis-dev.conf
port 6379
bind 127.0.0.1
protected-mode no
maxmemory 128mb
maxmemory-policy allkeys-lru
appendonly yes
appendfsync everysec
```

**Start with custom config:**
```bash
redis-server /path/to/redis-dev.conf
```

---

## Redis CLI Basics

### Connecting to Redis

```bash
# Connect to local Redis
redis-cli

# Connect to remote Redis
redis-cli -h 192.168.1.100 -p 6379

# Connect with authentication
redis-cli -h localhost -p 6379 -a your_password

# Or authenticate after connecting
redis-cli
127.0.0.1:6379> AUTH your_password
```

### Essential Commands

**Server Information:**
```bash
# Check server is running
PING
# Output: PONG

# Get server info
INFO
INFO memory      # Memory stats
INFO stats       # General stats
INFO replication # Replication info

# Monitor commands in real-time
MONITOR

# Get configuration
CONFIG GET maxmemory
CONFIG GET *     # All config values
```

**Database Selection:**
```bash
# Redis has 16 databases (0-15) by default
SELECT 0  # Switch to database 0 (default)
SELECT 1  # Switch to database 1

# List all keys in current database
KEYS *

# Count keys
DBSIZE

# Clear current database
FLUSHDB

# Clear all databases (DANGEROUS!)
FLUSHALL
```

---

## Data Types Overview

### 1. Strings

**Most basic type, can hold text, numbers, or binary data (up to 512MB)**

```bash
SET name "Alice"
GET name
# Output: "Alice"

SET counter 100
INCR counter
# Output: 101

SET user:1000:email "alice@example.com"
EXPIRE user:1000:email 3600  # TTL: 1 hour
```

### 2. Hashes

**Maps of field-value pairs, ideal for objects**

```bash
HSET user:1000 name "Alice" email "alice@example.com" age 30
HGET user:1000 name
# Output: "Alice"

HGETALL user:1000
# Output: 1) "name" 2) "Alice" 3) "email" 4) "alice@example.com" 5) "age" 6) "30"

HINCRBY user:1000 age 1  # Increment age
```

### 3. Lists

**Ordered collections of strings, implemented as linked lists**

```bash
LPUSH tasks "task1" "task2" "task3"  # Push to left
RPUSH tasks "task4"                  # Push to right

LRANGE tasks 0 -1  # Get all elements
# Output: 1) "task3" 2) "task2" 3) "task1" 4) "task4"

LPOP tasks  # Pop from left
# Output: "task3"
```

### 4. Sets

**Unordered collections of unique strings**

```bash
SADD tags "redis" "database" "cache"
SADD tags "redis"  # Ignored (duplicate)

SMEMBERS tags
# Output: 1) "redis" 2) "database" 3) "cache"

SISMEMBER tags "redis"
# Output: 1 (true)
```

### 5. Sorted Sets

**Sets with a score for each member, sorted by score**

```bash
ZADD leaderboard 100 "Alice" 200 "Bob" 150 "Charlie"

ZRANGE leaderboard 0 -1 WITHSCORES
# Output: 1) "Alice" 2) "100" 3) "Charlie" 4) "150" 5) "Bob" 6) "200"

ZREVRANGE leaderboard 0 2 WITHSCORES  # Top 3
# Output: 1) "Bob" 2) "200" 3) "Charlie" 4) "150" 5) "Alice" 6) "100"
```

### 6. Streams

**Append-only log data structure (Redis 5.0+)**

```bash
XADD events * action "login" user "alice" timestamp "2025-11-16T10:00:00Z"
# Output: "1700136000000-0" (auto-generated ID)

XRANGE events - +  # Read all entries
```

---

## Key Naming Conventions

### Best Practices

**Use Hierarchical Structure with Colons:**
```bash
# Good
user:1000:profile
user:1000:sessions:active
product:5432:inventory
cache:api:users:1000

# Bad (flat, unclear)
user1000profile
product5432
cacheapiusers1000
```

**Common Patterns:**
```bash
# Objects
user:{userId}
product:{productId}
order:{orderId}

# Collections
users:active        # Set of active user IDs
products:featured   # Set of featured product IDs

# Counters
stats:pageviews:{date}
metrics:api:requests:{endpoint}

# Caching
cache:{resource}:{id}
cache:user:1000
cache:product:5432

# Sessions
session:{sessionId}
user:{userId}:session

# Temporary data
temp:{process}:{id}
lock:{resource}:{id}
```

---

## Time To Live (TTL)

### Expiration Management

```bash
# Set key with expiration (seconds)
SETEX cache:user:1000 3600 "{\"name\":\"Alice\"}"

# Set expiration on existing key
SET user:1000 "Alice"
EXPIRE user:1000 3600

# Set expiration (milliseconds)
PEXPIRE user:1000 3600000

# Check remaining TTL
TTL user:1000
# Output: 3599 (seconds remaining)

PTTL user:1000
# Output: 3599000 (milliseconds)

# Remove expiration (make key persistent)
PERSIST user:1000

# Set expiration at specific Unix timestamp
EXPIREAT user:1000 1700150400
```

### TTL Return Values

```bash
TTL key
# Returns:
#  -2: Key does not exist
#  -1: Key exists but has no expiration
#  >0: Seconds until expiration
```

---

## Atomic Operations

### Why Atomicity Matters

```javascript
// ❌ WRONG - Race condition in traditional DB
const value = await db.get('counter')
await db.set('counter', value + 1)
// Another client could update between GET and SET

// ✅ CORRECT - Atomic operation in Redis
await redis.incr('counter')
// Guaranteed to be atomic
```

### Common Atomic Commands

```bash
# Increment/Decrement
INCR counter        # Increment by 1
INCRBY counter 5    # Increment by 5
DECR counter        # Decrement by 1
DECRBY counter 3    # Decrement by 3

# Atomic get and set
GETSET key newvalue  # Set new value, return old value

# Set if not exists
SETNX lock:resource "locked"  # Returns 1 if set, 0 if key exists

# Multiple operations
MULTI               # Start transaction
SET key1 "value1"
SET key2 "value2"
EXEC                # Execute all commands atomically
```

---

## Client Libraries

### Node.js (ioredis)

```javascript
import Redis from 'ioredis'

// Connect
const redis = new Redis({
  host: 'localhost',
  port: 6379,
  password: 'your_password',
  db: 0,
  retryStrategy: (times) => {
    const delay = Math.min(times * 50, 2000)
    return delay
  },
})

// Basic operations
await redis.set('key', 'value')
const value = await redis.get('key')

// With expiration
await redis.setex('key', 3600, 'value')

// Pipeline (batch commands)
const pipeline = redis.pipeline()
pipeline.set('key1', 'value1')
pipeline.set('key2', 'value2')
pipeline.incr('counter')
await pipeline.exec()

// Disconnect
await redis.quit()
```

### Python (redis-py)

```python
import redis

# Connect
r = redis.Redis(
    host='localhost',
    port=6379,
    password='your_password',
    db=0,
    decode_responses=True  # Decode bytes to strings
)

# Basic operations
r.set('key', 'value')
value = r.get('key')

# With expiration
r.setex('key', 3600, 'value')

# Pipeline
pipe = r.pipeline()
pipe.set('key1', 'value1')
pipe.set('key2', 'value2')
pipe.incr('counter')
pipe.execute()
```

---

## Performance Characteristics

### Time Complexity

| Command | Complexity | Notes |
|---------|-----------|-------|
| GET | O(1) | Constant time |
| SET | O(1) | Constant time |
| INCR | O(1) | Atomic increment |
| HGET | O(1) | Hash field access |
| HGETALL | O(N) | N = number of fields |
| LPUSH | O(1) | List prepend |
| LRANGE | O(S+N) | S = offset, N = elements |
| SADD | O(1) | Set add |
| SMEMBERS | O(N) | N = set size |
| ZADD | O(log(N)) | Sorted set add |
| ZRANGE | O(log(N)+M) | M = elements returned |

### Benchmarking

```bash
# Built-in benchmark tool
redis-benchmark -h localhost -p 6379 -n 100000

# Specific commands
redis-benchmark -t set,get -n 100000 -q

# Pipeline benchmark
redis-benchmark -t set,get -n 100000 -P 16

# Sample output:
# SET: 85470.09 requests per second
# GET: 89285.71 requests per second
```

---

## Best Practices for Beginners

### 1. Use Appropriate Data Structures

```bash
# ❌ WRONG - Using strings for objects
SET user:1000 "{\"name\":\"Alice\",\"email\":\"alice@example.com\"}"

# ✅ CORRECT - Using hashes
HSET user:1000 name "Alice" email "alice@example.com"
```

### 2. Set Expiration on Cache Keys

```javascript
// Always set TTL for cache data
await redis.setex(`cache:user:${userId}`, 3600, JSON.stringify(user))
```

### 3. Use Pipelining for Multiple Commands

```javascript
// ❌ SLOW - Individual requests
for (let i = 0; i < 100; i++) {
  await redis.set(`key:${i}`, i)
}

// ✅ FAST - Pipelined
const pipeline = redis.pipeline()
for (let i = 0; i < 100; i++) {
  pipeline.set(`key:${i}`, i)
}
await pipeline.exec()
```

### 4. Monitor Memory Usage

```bash
# Check memory info
INFO memory

# Find largest keys
redis-cli --bigkeys

# Set maxmemory limit
CONFIG SET maxmemory 256mb
CONFIG SET maxmemory-policy allkeys-lru
```

### 5. Use Connection Pooling

```javascript
// ✅ Reuse connection
const redis = new Redis() // Created once

// ❌ Don't create new connection per request
async function handler() {
  const redis = new Redis() // BAD: New connection every time
  // ...
}
```

---

## Next Steps

After mastering the fundamentals, explore:

1. **Basic Operations** → See `02-BASIC-OPERATIONS.md` for CRUD patterns
2. **Data Structures** → See `03-DATA-STRUCTURES.md` for advanced usage
3. **Caching Patterns** → See `04-CACHING-STRATEGIES.md` for cache implementations
4. **Performance** → See `08-PERFORMANCE.md` for optimization techniques
5. **Production** → See `11-CONFIG-OPERATIONS.md` for production deployment

---

## AI Pair Programming Notes

**When to load this KB:**
- New to Redis
- Understanding in-memory databases
- Implementing caching solutions
- Learning NoSQL data structures

**Common starting points:**
- Installation: See Installation section
- First commands: See Redis CLI Basics
- Data types: See Data Types Overview
- Client setup: See Client Libraries

**Typical questions:**
- "What is Redis?" → What is Redis?
- "How do I install Redis?" → Installation
- "What data types does Redis support?" → Data Types Overview
- "How do I connect to Redis?" → Client Libraries

**Related topics:**
- Caching: See `04-CACHING-STRATEGIES.md`
- Data structures: See `03-DATA-STRUCTURES.md`
- Performance: See `08-PERFORMANCE.md`

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1
