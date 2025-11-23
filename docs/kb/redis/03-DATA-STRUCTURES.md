---
id: redis-data-structures
topic: redis
file_role: guide
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [redis-fundamentals, redis-basic-operations]
related_topics: [hashes, lists, sets, sorted-sets, streams]
embedding_keywords: [redis, data-structures, hash, list, set, sorted-set, stream, zset]
last_reviewed: 2025-11-16
---

# Redis - Data Structures

Comprehensive guide to Redis advanced data structures: Hashes, Lists, Sets, Sorted Sets, and Streams.

## Overview

Redis provides rich data structures beyond simple strings. This guide covers all major data types with production-ready patterns and performance characteristics.

---

## Hashes

**Maps of field-value pairs - ideal for representing objects**

### Basic Hash Operations

**HSET / HGET - Set/Get Single Field:**
```bash
# Set single field
HSET user:1000 name "Alice"
# Output: 1 (number of fields added)

# Set multiple fields
HSET user:1000 email "alice@example.com" age "30"
# Output: 2

# Get single field
HGET user:1000 name
# Output: "Alice"

# Get non-existent field
HGET user:1000 nonexistent
# Output: (nil)
```

**HMSET / HMGET - Multiple Fields:**
```bash
# Set multiple fields (deprecated, use HSET)
HMSET user:1000 name "Alice" email "alice@example.com" age "30"
# Modern approach: HSET user:1000 name "Alice" email "alice@example.com" age "30"

# Get multiple fields
HMGET user:1000 name email age
# Output: 1) "Alice" 2) "alice@example.com" 3) "30"
```

**HGETALL - Get All Fields:**
```bash
HGETALL user:1000
# Output: 1) "name" 2) "Alice" 3) "email" 4) "alice@example.com" 5) "age" 6) "30"
```

⚠️ **Warning**: `HGETALL` is O(N). Use `HSCAN` for large hashes.

### Hash Utility Commands

**HEXISTS - Check Field Exists:**
```bash
HEXISTS user:1000 name
# Output: 1 (exists) or 0 (doesn't exist)
```

**HDEL - Delete Fields:**
```bash
HDEL user:1000 age
# Output: 1 (number of fields deleted)

# Delete multiple fields
HDEL user:1000 field1 field2 field3
# Output: 3
```

**HLEN - Count Fields:**
```bash
HLEN user:1000
# Output: 2
```

**HKEYS / HVALS - Get Keys/Values:**
```bash
# Get all field names
HKEYS user:1000
# Output: 1) "name" 2) "email"

# Get all values
HVALS user:1000
# Output: 1) "Alice" 2) "alice@example.com"
```

### Hash Numeric Operations

**HINCRBY / HINCRBYFLOAT - Increment Field:**
```bash
# Set numeric field
HSET stats:daily views "1000"

# Increment by integer
HINCRBY stats:daily views 10
# Output: 1010

# Increment by float
HINCRBYFLOAT stats:daily revenue 19.99
# Output: "19.99"
```

**Use Case - Page Views by Article:**
```javascript
// Track page views
await redis.hincrby('pageviews:2025-11-16', articleId, 1)

// Get specific article views
const views = await redis.hget('pageviews:2025-11-16', articleId)

// Get all views for the day
const allViews = await redis.hgetall('pageviews:2025-11-16')
// { "article:1": "150", "article:2": "320", ... }
```

### Hash Iteration

**HSCAN - Safe Iteration:**
```bash
# Scan hash fields (cursor-based)
HSCAN user:1000 0 COUNT 10
# Output: 1) "0" 2) 1) "name" 2) "Alice" 3) "email" 4) "alice@example.com"

# Pattern matching
HSCAN user:1000 0 MATCH email* COUNT 10
```

**Node.js HSCAN Pattern:**
```javascript
async function getAllHashFields(key) {
  const fields = {}
  let cursor = '0'

  do {
    const result = await redis.hscan(key, cursor, 'COUNT', 100)
    cursor = result[0]
    const items = result[1]

    for (let i = 0; i < items.length; i += 2) {
      fields[items[i]] = items[i + 1]
    }
  } while (cursor !== '0')

  return fields
}
```

### Hash Patterns

**Storing Objects:**
```javascript
// ✅ CORRECT - Hash for object
await redis.hset('user:1000', {
  name: 'Alice',
  email: 'alice@example.com',
  age: '30',
  createdAt: Date.now().toString(),
})

// Retrieve object
const user = await redis.hgetall('user:1000')
// { name: 'Alice', email: 'alice@example.com', age: '30', ... }

// Update specific field
await redis.hset('user:1000', 'email', 'alice.new@example.com')
```

**Storing Counters:**
```javascript
// Multiple counters in one hash
await redis.hincrby('stats:api', 'requests', 1)
await redis.hincrby('stats:api', 'errors', 0)
await redis.hincrbyfloat('stats:api', 'latency', responseTime)

// Get all stats
const stats = await redis.hgetall('stats:api')
// { requests: '1523', errors: '12', latency: '45.67' }
```

---

## Lists

**Ordered collections of strings - implemented as linked lists**

### Basic List Operations

**LPUSH / RPUSH - Add Elements:**
```bash
# Push to left (head)
LPUSH tasks "task3" "task2" "task1"
# Output: 3 (list length)

# Push to right (tail)
RPUSH tasks "task4"
# Output: 4

# Result: ["task1", "task2", "task3", "task4"]
```

**LPOP / RPOP - Remove Elements:**
```bash
# Pop from left
LPOP tasks
# Output: "task1"

# Pop from right
RPOP tasks
# Output: "task4"

# Pop multiple (Redis 6.2+)
LPOP tasks 2
# Output: 1) "task2" 2) "task3"
```

**LRANGE - Get Range:**
```bash
# Get all elements
LRANGE tasks 0 -1
# Output: 1) "task1" 2) "task2" 3) "task3" 4) "task4"

# Get first 3 elements
LRANGE tasks 0 2
# Output: 1) "task1" 2) "task2" 3) "task3"

# Get last 2 elements
LRANGE tasks -2 -1
# Output: 1) "task3" 2) "task4"
```

### List Utility Commands

**LLEN - List Length:**
```bash
LLEN tasks
# Output: 4
```

**LINDEX - Get Element by Index:**
```bash
LINDEX tasks 0
# Output: "task1"

LINDEX tasks -1
# Output: "task4" (last element)
```

**LSET - Set Element by Index:**
```bash
LSET tasks 0 "updated_task1"
# Output: OK
```

**LINSERT - Insert Before/After:**
```bash
# Insert before value
LINSERT tasks BEFORE "task2" "task1.5"
# Output: 5 (new length)

# Insert after value
LINSERT tasks AFTER "task3" "task3.5"
# Output: 6
```

**LREM - Remove Elements:**
```bash
LPUSH numbers 1 2 3 2 4 2 5

# Remove first 2 occurrences of "2"
LREM numbers 2 "2"
# Output: 2

# Remove last 1 occurrence
LREM numbers -1 "2"
# Output: 1

# Remove all occurrences
LREM numbers 0 "2"
# Output: 0 (all removed)
```

**LTRIM - Trim List:**
```bash
# Keep only first 100 elements
LTRIM tasks 0 99
# Output: OK
```

### Blocking Operations

**BLPOP / BRPOP - Blocking Pop:**
```bash
# Block until element available (timeout in seconds)
BLPOP queue:jobs 5
# Waits up to 5 seconds, returns: 1) "queue:jobs" 2) "job_data"

# Block indefinitely (0 = no timeout)
BRPOP queue:jobs 0
```

**BRPOPLPUSH - Atomic Move:**
```bash
# Move element from source to destination (blocking)
BRPOPLPUSH queue:pending queue:processing 30
# Returns: "job_data"
```

### List Patterns

**Simple Queue (FIFO):**
```javascript
// Producer: Add jobs to queue
await redis.rpush('queue:jobs', JSON.stringify(job))

// Consumer: Process jobs
while (true) {
  const [_key, jobData] = await redis.blpop('queue:jobs', 0)
  const job = JSON.parse(jobData)
  await processJob(job)
}
```

**Stack (LIFO):**
```javascript
// Push
await redis.lpush('stack:undo', action)

// Pop
const action = await redis.lpop('stack:undo')
```

**Capped List (Recent Items):**
```javascript
// Add item and keep only last 100
await redis.lpush('recent:views', itemId)
await redis.ltrim('recent:views', 0, 99)

// Get recent 10
const recent = await redis.lrange('recent:views', 0, 9)
```

**Reliable Queue Pattern:**
```javascript
// Move from pending to processing atomically
const job = await redis.brpoplpush(
  'queue:pending',
  'queue:processing',
  30 // timeout
)

try {
  await processJob(JSON.parse(job))
  // Remove from processing on success
  await redis.lrem('queue:processing', 1, job)
} catch (error) {
  // Move back to pending on failure
  await redis.lrem('queue:processing', 1, job)
  await redis.lpush('queue:pending', job)
}
```

---

## Sets

**Unordered collections of unique strings**

### Basic Set Operations

**SADD / SREM - Add/Remove Members:**
```bash
# Add members
SADD tags "redis" "database" "cache"
# Output: 3

# Add duplicate (ignored)
SADD tags "redis"
# Output: 0

# Remove members
SREM tags "cache"
# Output: 1
```

**SMEMBERS - Get All Members:**
```bash
SMEMBERS tags
# Output: 1) "redis" 2) "database" (unordered)
```

⚠️ **Warning**: O(N) operation. Use `SSCAN` for large sets.

**SISMEMBER - Check Membership:**
```bash
SISMEMBER tags "redis"
# Output: 1 (member exists)

SISMEMBER tags "sql"
# Output: 0 (not a member)
```

**SCARD - Count Members:**
```bash
SCARD tags
# Output: 2
```

### Set Operations

**SINTER - Intersection:**
```bash
SADD set1 "a" "b" "c"
SADD set2 "b" "c" "d"

SINTER set1 set2
# Output: 1) "b" 2) "c"
```

**SUNION - Union:**
```bash
SUNION set1 set2
# Output: 1) "a" 2) "b" 3) "c" 4) "d"
```

**SDIFF - Difference:**
```bash
# Elements in set1 but not in set2
SDIFF set1 set2
# Output: 1) "a"
```

**Store Result:**
```bash
# Store intersection result
SINTERSTORE result set1 set2
# Output: 2 (number of elements in result)

# Store union result
SUNIONSTORE result set1 set2

# Store difference result
SDIFFSTORE result set1 set2
```

### Advanced Set Operations

**SMOVE - Move Member:**
```bash
SMOVE source destination "member"
# Output: 1 (success) or 0 (member doesn't exist)
```

**SPOP - Random Remove:**
```bash
# Remove and return random member
SPOP tags
# Output: "database"

# Remove multiple random members (Redis 3.2+)
SPOP tags 2
# Output: 1) "redis" 2) "cache"
```

**SRANDMEMBER - Random Sample:**
```bash
# Get random member (without removing)
SRANDMEMBER tags
# Output: "redis"

# Get multiple random members
SRANDMEMBER tags 3
# Output: 1) "redis" 2) "database" 3) "cache"

# Get random with possible duplicates (negative count)
SRANDMEMBER tags -5
# May return duplicates
```

### Set Patterns

**Tagging System:**
```javascript
// Add tags to article
await redis.sadd(`article:${articleId}:tags`, 'redis', 'database', 'cache')

// Find articles with specific tag
await redis.sadd(`tag:redis:articles`, articleId)

// Get all tags for article
const tags = await redis.smembers(`article:${articleId}:tags`)

// Get all articles with tag
const articles = await redis.smembers('tag:redis:articles')

// Find articles with multiple tags (intersection)
const articles = await redis.sinter(
  'tag:redis:articles',
  'tag:database:articles'
)
```

**Following/Followers:**
```javascript
// User A follows User B
await redis.sadd(`user:${userA}:following`, userB)
await redis.sadd(`user:${userB}:followers`, userA)

// Get mutual follows (friends)
const mutualFriends = await redis.sinter(
  `user:${userA}:following`,
  `user:${userA}:followers`
)

// Suggested friends (friends of friends not already following)
const friendsOfFriends = await redis.sunion(
  ...followingIds.map(id => `user:${id}:following`)
)
const suggested = friendsOfFriends.filter(id => 
  !await redis.sismember(`user:${userA}:following`, id)
)
```

**Unique Visitors:**
```javascript
// Track unique visitors per day
await redis.sadd(`visitors:2025-11-16`, userId)

// Count unique visitors
const uniqueCount = await redis.scard('visitors:2025-11-16')

// Check if user visited
const visited = await redis.sismember('visitors:2025-11-16', userId)
```

---

## Sorted Sets (ZSets)

**Sets with a score for each member - sorted by score**

### Basic Sorted Set Operations

**ZADD - Add Members with Scores:**
```bash
# Add members with scores
ZADD leaderboard 100 "Alice" 200 "Bob" 150 "Charlie"
# Output: 3

# Update score (if member exists)
ZADD leaderboard 180 "Alice"
# Output: 0 (updated, not added)

# Add only if doesn't exist (NX)
ZADD leaderboard NX 250 "David"

# Add only if exists (XX)
ZADD leaderboard XX 220 "Bob"

# Only if new score is greater (GT)
ZADD leaderboard GT 190 "Alice"

# Only if new score is less (LT)
ZADD leaderboard LT 170 "Alice"
```

**ZRANGE / ZREVRANGE - Get Range:**
```bash
# Get members by rank (ascending)
ZRANGE leaderboard 0 -1
# Output: 1) "Charlie" 2) "Alice" 3) "Bob"

# With scores
ZRANGE leaderboard 0 -1 WITHSCORES
# Output: 1) "Charlie" 2) "150" 3) "Alice" 4) "180" 5) "Bob" 6) "200"

# Descending order
ZREVRANGE leaderboard 0 -1 WITHSCORES
# Output: 1) "Bob" 2) "200" 3) "Alice" 4) "180" 5) "Charlie" 6) "150"

# Top 3
ZREVRANGE leaderboard 0 2 WITHSCORES
```

**ZRANK / ZREVRANK - Get Rank:**
```bash
# Get rank (0-indexed, ascending)
ZRANK leaderboard "Alice"
# Output: 1

# Get rank (descending)
ZREVRANK leaderboard "Alice"
# Output: 1 (second from top)
```

**ZSCORE - Get Score:**
```bash
ZSCORE leaderboard "Alice"
# Output: "180"
```

**ZCARD - Count Members:**
```bash
ZCARD leaderboard
# Output: 3
```

### Range Queries

**ZRANGEBYSCORE - Range by Score:**
```bash
# Get members with score between 150 and 200
ZRANGEBYSCORE leaderboard 150 200
# Output: 1) "Charlie" 2) "Alice" 3) "Bob"

# Exclusive range
ZRANGEBYSCORE leaderboard (150 (200
# Excludes 150 and 200

# With limit
ZRANGEBYSCORE leaderboard 0 1000 LIMIT 0 10
# First 10 members with score 0-1000

# Descending
ZREVRANGEBYSCORE leaderboard 200 150
```

**ZCOUNT - Count in Range:**
```bash
ZCOUNT leaderboard 150 200
# Output: 3
```

### Sorted Set Modifications

**ZINCRBY - Increment Score:**
```bash
ZINCRBY leaderboard 10 "Alice"
# Output: "190" (new score)
```

**ZREM - Remove Members:**
```bash
ZREM leaderboard "Charlie"
# Output: 1 (number removed)

# Remove multiple
ZREM leaderboard "Alice" "Bob"
# Output: 2
```

**ZREMRANGEBYRANK - Remove by Rank:**
```bash
# Remove lowest 10
ZREMRANGEBYRANK leaderboard 0 9
```

**ZREMRANGEBYSCORE - Remove by Score:**
```bash
# Remove all with score < 100
ZREMRANGEBYSCORE leaderboard -inf 100
```

**ZPOPMIN / ZPOPMAX - Remove and Return:**
```bash
# Remove and return lowest score
ZPOPMIN leaderboard
# Output: 1) "Charlie" 2) "150"

# Remove and return highest score
ZPOPMAX leaderboard
# Output: 1) "Bob" 2) "200"

# Pop multiple
ZPOPMIN leaderboard 2
```

### Sorted Set Patterns

**Leaderboard:**
```javascript
// Update player score
await redis.zincrby('leaderboard:global', score, playerId)

// Get top 10
const top10 = await redis.zrevrange('leaderboard:global', 0, 9, 'WITHSCORES')

// Get player rank (1-indexed)
const rank = (await redis.zrevrank('leaderboard:global', playerId)) + 1

// Get players around specific player
const playerRank = await redis.zrevrank('leaderboard:global', playerId)
const surrounding = await redis.zrevrange(
  'leaderboard:global',
  playerRank - 5,
  playerRank + 5,
  'WITHSCORES'
)
```

**Priority Queue:**
```javascript
// Add task with priority (lower score = higher priority)
await redis.zadd('tasks:priority', priority, taskId)

// Get highest priority task
const [taskId, _score] = await redis.zpopmin('tasks:priority')

// Process in priority order
while (true) {
  const result = await redis.bzpopmin('tasks:priority', 0)
  if (result) {
    const [_key, taskId, _score] = result
    await processTask(taskId)
  }
}
```

**Time-Series / Recent Items:**
```javascript
// Add with timestamp as score
await redis.zadd('recent:logins', Date.now(), userId)

// Get logins in last hour
const hourAgo = Date.now() - 3600000
const recentLogins = await redis.zrangebyscore(
  'recent:logins',
  hourAgo,
  '+inf'
)

// Remove old entries (> 24 hours)
const dayAgo = Date.now() - 86400000
await redis.zremrangebyscore('recent:logins', '-inf', dayAgo)
```

**Rate Limiting (Sliding Window):**
```javascript
async function checkRateLimit(userId, limit, windowMs) {
  const key = `rate:${userId}`
  const now = Date.now()
  const windowStart = now - windowMs

  // Remove old entries
  await redis.zremrangebyscore(key, '-inf', windowStart)

  // Count requests in window
  const count = await redis.zcard(key)

  if (count >= limit) {
    return false // Rate limit exceeded
  }

  // Add current request
  await redis.zadd(key, now, `${now}-${Math.random()}`)
  await redis.pexpire(key, windowMs)

  return true // Request allowed
}
```

---

## Streams

**Append-only log data structure for event sourcing (Redis 5.0+)**

### Basic Stream Operations

**XADD - Add Entry:**
```bash
# Auto-generated ID
XADD events * action "login" user "alice" timestamp "2025-11-16T10:00:00Z"
# Output: "1700136000000-0"

# Custom ID
XADD events 1700136000000-1 action "logout" user "alice"

# With MAXLEN (cap stream length)
XADD events MAXLEN 1000 * action "pageview" page "/home"
```

**XREAD - Read Entries:**
```bash
# Read all entries
XREAD STREAMS events 0
# Output: 1) 1) "events" 2) 1) 1) "1700136000000-0" 2) 1) "action" 2) "login" ...

# Read from specific ID
XREAD STREAMS events 1700136000000-0

# Block until new entry (like BLPOP)
XREAD BLOCK 5000 STREAMS events $
# $ = latest ID
```

**XRANGE - Range Query:**
```bash
# Get all entries
XRANGE events - +

# Get specific range
XRANGE events 1700136000000 1700140000000

# With limit
XRANGE events - + COUNT 10
```

**XLEN - Stream Length:**
```bash
XLEN events
# Output: 1523
```

### Consumer Groups

**XGROUP CREATE - Create Consumer Group:**
```bash
# Create group starting from beginning
XGROUP CREATE events group1 0

# Create group starting from latest
XGROUP CREATE events group2 $

# Create group and stream if doesn't exist
XGROUP CREATE events group3 $ MKSTREAM
```

**XREADGROUP - Read as Consumer:**
```bash
# Read new messages for consumer
XREADGROUP GROUP group1 consumer1 STREAMS events >

# Read with block
XREADGROUP GROUP group1 consumer1 BLOCK 5000 COUNT 10 STREAMS events >
```

**XACK - Acknowledge Message:**
```bash
XACK events group1 1700136000000-0
# Output: 1 (number acknowledged)
```

**XPENDING - Check Pending Messages:**
```bash
# Summary
XPENDING events group1

# Detailed pending for consumer
XPENDING events group1 - + 10 consumer1
```

### Stream Patterns

**Event Log:**
```javascript
// Append event
await redis.xadd('events:user:1000', '*', 
  'type', 'profile_updated',
  'timestamp', Date.now(),
  'data', JSON.stringify({ email: 'new@example.com' })
)

// Read all events
const events = await redis.xrange('events:user:1000', '-', '+')
```

**Distributed Processing:**
```javascript
// Create consumer group
await redis.xgroup('CREATE', 'jobs', 'workers', '$', 'MKSTREAM')

// Worker: Read and process jobs
while (true) {
  const results = await redis.xreadgroup(
    'GROUP', 'workers', workerId,
    'BLOCK', 5000,
    'COUNT', 10,
    'STREAMS', 'jobs', '>'
  )

  if (results) {
    for (const [stream, messages] of results) {
      for (const [id, fields] of messages) {
        await processJob(fields)
        await redis.xack('jobs', 'workers', id)
      }
    }
  }
}
```

---

## Performance Characteristics

### Time Complexity

| Data Structure | Operation | Complexity |
|---------------|-----------|-----------|
| Hash | HGET, HSET, HDEL | O(1) |
| Hash | HGETALL | O(N) |
| List | LPUSH, RPUSH, LPOP, RPOP | O(1) |
| List | LRANGE | O(S+N) |
| Set | SADD, SREM, SISMEMBER | O(1) |
| Set | SMEMBERS | O(N) |
| Sorted Set | ZADD, ZREM, ZSCORE | O(log(N)) |
| Sorted Set | ZRANGE | O(log(N)+M) |
| Stream | XADD | O(1) |
| Stream | XRANGE | O(N) |

---

## Next Steps

After mastering data structures, explore:

1. **Caching Strategies** → See `04-CACHING-STRATEGIES.md`
2. **Pub/Sub** → See `05-PUBSUB.md`
3. **Transactions** → See `06-TRANSACTIONS.md`
4. **Persistence** → See `07-PERSISTENCE.md`
5. **Performance** → See `08-PERFORMANCE.md`

---

## AI Pair Programming Notes

**When to load this KB:**
- Learning Redis data structures
- Choosing appropriate data type
- Building complex Redis patterns
- Optimizing data storage

**Common starting points:**
- Objects: See Hashes
- Queues: See Lists
- Relationships: See Sets
- Rankings: See Sorted Sets
- Events: See Streams

**Typical questions:**
- "How do I store an object?" → Hashes
- "How do I build a queue?" → Lists
- "How do I track unique items?" → Sets
- "How do I build a leaderboard?" → Sorted Sets
- "How do I implement event sourcing?" → Streams

**Related topics:**
- Basics: See `02-BASIC-OPERATIONS.md`
- Patterns: See `04-CACHING-STRATEGIES.md`
- Performance: See `08-PERFORMANCE.md`

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1
