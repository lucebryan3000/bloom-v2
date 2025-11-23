---
id: redis-basic-operations
topic: redis
file_role: guide
profile: full
difficulty_level: beginner
kb_version: 3.1
prerequisites: [redis-fundamentals]
related_topics: [crud-operations, data-manipulation, key-value-operations]
embedding_keywords: [redis, operations, crud, get, set, delete, update, commands]
last_reviewed: 2025-11-16
---

# Redis - Basic Operations

Comprehensive guide to basic CRUD operations and common command patterns in Redis.

## Overview

This guide covers fundamental Redis operations organized by operation type: Create, Read, Update, Delete (CRUD), plus essential utility commands for everyday Redis usage.

---

## String Operations

### SET - Create/Update String Values

**Basic SET:**
```bash
# Simple key-value
SET name "Alice"
# Output: OK

# Numeric values (stored as strings)
SET age "30"
SET price "99.99"
```

**SET with Options:**
```bash
# Set with expiration (seconds)
SET session:abc123 "user_data" EX 3600
# Expires in 1 hour

# Set with expiration (milliseconds)
SET temp:data "value" PX 5000
# Expires in 5 seconds

# Set only if key doesn't exist (NX)
SET lock:resource "locked" NX
# Returns OK if set, nil if key exists

# Set only if key exists (XX)
SET existing:key "new_value" XX
# Returns OK if key exists, nil otherwise

# Get old value while setting new (GETSET replacement in Redis 6.2+)
SET counter "100" GET
# Returns old value or nil
```

**SETEX - Set with Expiration (Atomic):**
```bash
# Set key with TTL in one operation
SETEX cache:user:1000 3600 '{"name":"Alice","email":"alice@example.com"}'
# Equivalent to: SET + EXPIRE but atomic
```

**SETNX - Set if Not Exists:**
```bash
# Distributed lock pattern
SETNX lock:order:5432 "processing"
# Returns 1 (success) or 0 (key exists)

# Use SET NX instead (modern approach)
SET lock:order:5432 "processing" NX EX 30
```

### GET - Read String Values

```bash
# Simple GET
GET name
# Output: "Alice"

# Get non-existent key
GET nonexistent
# Output: (nil)

# Get multiple keys at once (MGET)
MGET name age email
# Output: 1) "Alice" 2) "30" 3) "alice@example.com"
```

**Type-Safe Retrieval:**
```javascript
// Node.js - Always check for null
const value = await redis.get('key')
if (value === null) {
  // Key doesn't exist
  throw new Error('Key not found')
}
```

### MSET / MGET - Multiple Keys

**MSET - Set Multiple Keys (Atomic):**
```bash
# Set multiple keys in one operation
MSET user:1000:name "Alice" user:1000:email "alice@example.com" user:1000:age "30"
# Output: OK

# Returns: All keys set atomically (all or nothing)
```

**MGET - Get Multiple Keys:**
```bash
MGET user:1000:name user:1000:email user:1000:age
# Output: 1) "Alice" 2) "alice@example.com" 3) "30"

# Non-existent keys return nil
MGET key1 nonexistent key2
# Output: 1) "value1" 2) (nil) 3) "value2"
```

### APPEND - Concatenate Strings

```bash
SET message "Hello"
APPEND message " World"
# Returns: 11 (new length)

GET message
# Output: "Hello World"
```

### GETRANGE / SETRANGE - Substring Operations

```bash
SET email "alice@example.com"

# Get substring (0-indexed, inclusive)
GETRANGE email 0 4
# Output: "alice"

GETRANGE email 6 -1
# Output: "example.com" (negative index from end)

# Overwrite part of string
SETRANGE email 6 "company"
# Returns: 17

GET email
# Output: "alice@company.com"
```

### STRLEN - String Length

```bash
SET name "Alice"
STRLEN name
# Output: 5
```

---

## Numeric Operations

### INCR / DECR - Atomic Counters

```bash
# Initialize counter
SET counter "100"

# Increment by 1 (atomic)
INCR counter
# Output: 101

# Decrement by 1 (atomic)
DECR counter
# Output: 100

# Increment by specific amount
INCRBY counter 10
# Output: 110

# Decrement by specific amount
DECRBY counter 5
# Output: 105
```

**Float Increment:**
```bash
SET price "19.99"

# Increment by float
INCRBYFLOAT price 0.01
# Output: "20"

INCRBYFLOAT price -1.50
# Output: "18.5"
```

**Use Cases:**
```javascript
// Page view counter
await redis.incr(`pageviews:${articleId}`)

// Rate limiting
const requests = await redis.incr(`rate:${userId}:${minute}`)
if (requests > 100) {
  throw new Error('Rate limit exceeded')
}

// Inventory management
const remaining = await redis.decr(`inventory:${productId}`)
if (remaining < 0) {
  await redis.incr(`inventory:${productId}`) // Rollback
  throw new Error('Out of stock')
}
```

---

## Key Management

### EXISTS - Check Key Existence

```bash
# Check if key exists
EXISTS name
# Output: 1 (exists) or 0 (doesn't exist)

# Check multiple keys
EXISTS key1 key2 key3
# Output: 2 (number of existing keys)
```

### DEL - Delete Keys

```bash
# Delete single key
DEL name
# Output: 1 (number of keys deleted)

# Delete multiple keys
DEL key1 key2 key3
# Output: 3 (number of keys deleted)

# Delete non-existent key
DEL nonexistent
# Output: 0
```

**Unlink (Async Delete):**
```bash
# Non-blocking delete (Redis 4.0+)
UNLINK large:key
# Deletes key asynchronously, returns immediately
```

### KEYS - Pattern Matching

```bash
# List all keys (DANGEROUS in production!)
KEYS *
# Output: 1) "user:1000" 2) "user:1001" 3) "session:abc123"

# Pattern matching
KEYS user:*
# Output: 1) "user:1000" 2) "user:1001"

KEYS *:name
# Output: 1) "user:1000:name" 2) "user:1001:name"

KEYS user:100?
# Output: 1) "user:1000" 2) "user:1001" (? matches single char)
```

**⚠️ Warning:** `KEYS *` blocks Redis for large datasets. Use `SCAN` instead.

### SCAN - Safe Key Iteration

```bash
# Cursor-based iteration (production-safe)
SCAN 0 MATCH user:* COUNT 100
# Output: 1) "17" (next cursor) 2) 1) "user:1000" 2) "user:1001"

# Continue with returned cursor
SCAN 17 MATCH user:* COUNT 100

# When cursor returns 0, iteration is complete
```

**Node.js SCAN Pattern:**
```javascript
async function getAllKeys(pattern) {
  const keys = []
  let cursor = '0'

  do {
    const result = await redis.scan(cursor, 'MATCH', pattern, 'COUNT', 100)
    cursor = result[0]
    keys.push(...result[1])
  } while (cursor !== '0')

  return keys
}

// Usage
const userKeys = await getAllKeys('user:*')
```

### RENAME - Rename Keys

```bash
# Rename key (overwrites destination)
SET oldkey "value"
RENAME oldkey newkey
# Output: OK

# Rename only if destination doesn't exist
RENAMENX oldkey newkey
# Output: 1 (success) or 0 (destination exists)
```

### TYPE - Get Value Type

```bash
SET name "Alice"
TYPE name
# Output: string

LPUSH tasks "task1"
TYPE tasks
# Output: list

HSET user:1000 name "Alice"
TYPE user:1000
# Output: hash
```

---

## Expiration (TTL)

### EXPIRE - Set Expiration Time

```bash
SET cache:data "value"

# Expire in seconds
EXPIRE cache:data 3600
# Output: 1 (success) or 0 (key doesn't exist)

# Expire in milliseconds
PEXPIRE cache:data 3600000

# Expire at specific Unix timestamp
EXPIREAT cache:data 1700150400

# Expire at specific Unix timestamp (milliseconds)
PEXPIREAT cache:data 1700150400000
```

### TTL - Check Time To Live

```bash
SET temp "value"
EXPIRE temp 300

# Check TTL in seconds
TTL temp
# Output: 299 (seconds remaining)

# Check TTL in milliseconds
PTTL temp
# Output: 299000

# Key with no expiration
SET persistent "value"
TTL persistent
# Output: -1

# Non-existent key
TTL nonexistent
# Output: -2
```

### PERSIST - Remove Expiration

```bash
SET temp "value"
EXPIRE temp 3600

# Remove expiration (make key persistent)
PERSIST temp
# Output: 1 (success) or 0 (no expiration set)

TTL temp
# Output: -1 (no expiration)
```

---

## Batch Operations

### Pipelining

**Execute Multiple Commands Without Waiting:**
```javascript
// Node.js (ioredis)
const pipeline = redis.pipeline()

// Queue commands
pipeline.set('key1', 'value1')
pipeline.set('key2', 'value2')
pipeline.incr('counter')
pipeline.get('key1')

// Execute all at once
const results = await pipeline.exec()

// Results: [[null, 'OK'], [null, 'OK'], [null, 101], [null, 'value1']]
// Format: [error, result] for each command
```

**Performance Benefit:**
```javascript
// ❌ SLOW - 1000 round trips
for (let i = 0; i < 1000; i++) {
  await redis.set(`key:${i}`, i)
}
// Time: ~2-3 seconds

// ✅ FAST - 1 round trip
const pipeline = redis.pipeline()
for (let i = 0; i < 1000; i++) {
  pipeline.set(`key:${i}`, i)
}
await pipeline.exec()
// Time: ~50-100ms
```

### Transactions

**MULTI / EXEC - Atomic Execution:**
```bash
# Start transaction
MULTI
# Output: OK

# Queue commands
SET account:1 "100"
SET account:2 "200"
DECRBY account:1 50
INCRBY account:2 50

# Execute all commands atomically
EXEC
# Output: 1) OK 2) OK 3) 50 4) 250

# All commands execute together or not at all
```

**DISCARD - Cancel Transaction:**
```bash
MULTI
SET key1 "value1"
SET key2 "value2"

# Cancel transaction
DISCARD
# Output: OK

# No commands were executed
```

**WATCH - Optimistic Locking:**
```bash
# Watch keys for changes
WATCH account:1

GET account:1
# Output: "100"

# Start transaction
MULTI
DECRBY account:1 50

# If another client modifies account:1 before EXEC,
# transaction fails
EXEC
# Output: (nil) if watched key changed, results otherwise
```

**Node.js Transaction Pattern:**
```javascript
async function transfer(from, to, amount) {
  const multi = redis.multi()

  // Queue operations
  multi.decrby(`account:${from}`, amount)
  multi.incrby(`account:${to}`, amount)

  // Execute atomically
  const results = await multi.exec()

  if (results === null) {
    throw new Error('Transaction failed (key modified)')
  }

  return results
}
```

---

## Utility Commands

### DBSIZE - Count Keys

```bash
# Total keys in current database
DBSIZE
# Output: 12543
```

### FLUSHDB / FLUSHALL - Clear Data

```bash
# Clear current database (DANGEROUS!)
FLUSHDB
# Output: OK

# Clear all databases (EXTREMELY DANGEROUS!)
FLUSHALL
# Output: OK

# Async variants (non-blocking)
FLUSHDB ASYNC
FLUSHALL ASYNC
```

### SELECT - Switch Database

```bash
# Select database 0 (default)
SELECT 0
# Output: OK

# Select database 1
SELECT 1

# Redis has 16 databases by default (0-15)
```

### RANDOMKEY - Random Key Selection

```bash
# Get random key from database
RANDOMKEY
# Output: "user:1000"
```

### DUMP / RESTORE - Serialize/Deserialize

```bash
# Serialize key value
DUMP user:1000
# Output: binary data

# Restore to different key
RESTORE user:1001 0 "\x00\x05Alice\x09\x00..."
# 0 = TTL (0 means no expiration)

# Restore with TTL
RESTORE user:1002 3600000 "\x00\x05Alice\x09\x00..."
# Expires in 1 hour
```

---

## Common Patterns

### Caching Pattern

```javascript
async function getUser(userId) {
  const cacheKey = `cache:user:${userId}`

  // Try cache first
  const cached = await redis.get(cacheKey)
  if (cached) {
    return JSON.parse(cached)
  }

  // Cache miss - fetch from database
  const user = await db.users.findOne({ id: userId })

  // Store in cache with 1 hour TTL
  await redis.setex(cacheKey, 3600, JSON.stringify(user))

  return user
}
```

### Distributed Lock Pattern

```javascript
async function acquireLock(resource, ttl = 30) {
  const lockKey = `lock:${resource}`
  const lockValue = crypto.randomUUID()

  // Acquire lock (NX = only if not exists, EX = expiration)
  const acquired = await redis.set(lockKey, lockValue, 'NX', 'EX', ttl)

  if (!acquired) {
    return null // Lock already held
  }

  // Return release function
  return async () => {
    // Only release if we still own the lock
    const script = `
      if redis.call("get", KEYS[1]) == ARGV[1] then
        return redis.call("del", KEYS[1])
      else
        return 0
      end
    `
    await redis.eval(script, 1, lockKey, lockValue)
  }
}

// Usage
const release = await acquireLock('order:5432')
if (!release) {
  throw new Error('Resource locked')
}

try {
  // Process order
} finally {
  await release()
}
```

### Rate Limiting Pattern

```javascript
async function checkRateLimit(userId, limit = 100, window = 60) {
  const key = `rate:${userId}:${Math.floor(Date.now() / 1000 / window)}`

  const requests = await redis.incr(key)

  if (requests === 1) {
    // First request in window - set expiration
    await redis.expire(key, window)
  }

  return {
    allowed: requests <= limit,
    remaining: Math.max(0, limit - requests),
    reset: await redis.ttl(key),
  }
}

// Usage
const { allowed, remaining, reset } = await checkRateLimit('user:1000', 100, 60)

if (!allowed) {
  throw new Error(`Rate limit exceeded. Try again in ${reset} seconds.`)
}
```

### Session Storage Pattern

```javascript
async function createSession(userId, data) {
  const sessionId = crypto.randomUUID()
  const sessionKey = `session:${sessionId}`

  await redis.setex(
    sessionKey,
    1800, // 30 minutes
    JSON.stringify({
      userId,
      ...data,
      createdAt: Date.now(),
    })
  )

  return sessionId
}

async function getSession(sessionId) {
  const sessionKey = `session:${sessionId}`
  const data = await redis.get(sessionKey)

  if (!data) {
    return null
  }

  // Refresh TTL on access
  await redis.expire(sessionKey, 1800)

  return JSON.parse(data)
}

async function destroySession(sessionId) {
  await redis.del(`session:${sessionId}`)
}
```

---

## Error Handling

### Command Errors

```javascript
// Wrong type operation
await redis.set('mystring', 'value')

try {
  await redis.lpush('mystring', 'item')
} catch (error) {
  // Error: WRONGTYPE Operation against a key holding the wrong kind of value
}
```

### Key Not Found

```javascript
// GET returns null for missing keys
const value = await redis.get('nonexistent')
console.log(value) // null

// INCR on non-existent key initializes to 0
const count = await redis.incr('new:counter')
console.log(count) // 1
```

### Atomic Operations Safety

```javascript
// ❌ WRONG - Race condition
const current = parseInt(await redis.get('counter')) || 0
await redis.set('counter', current + 1)
// Another client could modify counter between GET and SET

// ✅ CORRECT - Atomic operation
await redis.incr('counter')
```

---

## Performance Best Practices

### 1. Use Pipelining for Multiple Operations

```javascript
// 10x-100x faster than individual commands
const pipeline = redis.pipeline()
for (const key of keys) {
  pipeline.get(key)
}
const results = await pipeline.exec()
```

### 2. Use MGET/MSET for Multiple Keys

```javascript
// ❌ SLOW
const name = await redis.get('user:1000:name')
const email = await redis.get('user:1000:email')
const age = await redis.get('user:1000:age')

// ✅ FAST
const [name, email, age] = await redis.mget(
  'user:1000:name',
  'user:1000:email',
  'user:1000:age'
)
```

### 3. Set Expiration on Temporary Data

```javascript
// Prevent memory leaks
await redis.setex('temp:data', 3600, value)
```

### 4. Use Appropriate Data Structures

```javascript
// ❌ WRONG - String for object
await redis.set('user:1000', JSON.stringify({ name: 'Alice', email: 'alice@example.com' }))

// ✅ BETTER - Hash for object
await redis.hset('user:1000', 'name', 'Alice', 'email', 'alice@example.com')
```

---

## Next Steps

After mastering basic operations, explore:

1. **Data Structures** → See `03-DATA-STRUCTURES.md` for advanced data types
2. **Caching Strategies** → See `04-CACHING-STRATEGIES.md` for cache patterns
3. **Pub/Sub** → See `05-PUBSUB.md` for real-time messaging
4. **Transactions** → See `06-TRANSACTIONS.md` for complex atomic operations
5. **Performance** → See `08-PERFORMANCE.md` for optimization

---

## AI Pair Programming Notes

**When to load this KB:**
- Learning basic Redis commands
- Implementing CRUD operations
- Building caching layers
- Understanding Redis patterns

**Common starting points:**
- String operations: See String Operations
- Counters: See Numeric Operations
- Cache patterns: See Common Patterns
- Batch operations: See Batch Operations

**Typical questions:**
- "How do I set a key with expiration?" → SET with Options
- "How do I increment a counter?" → INCR/DECR
- "How do I get multiple keys?" → MGET
- "How do I implement rate limiting?" → Rate Limiting Pattern

**Related topics:**
- Fundamentals: See `01-FUNDAMENTALS.md`
- Data structures: See `03-DATA-STRUCTURES.md`
- Performance: See `08-PERFORMANCE.md`

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1
