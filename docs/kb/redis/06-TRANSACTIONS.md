---
id: redis-transactions
topic: redis
file_role: guide
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [redis-fundamentals, redis-basic-operations]
related_topics: [atomicity, consistency, multi-exec, pipelines, lua-scripts]
embedding_keywords: [redis, transactions, multi, exec, atomic, watch, lua, scripts]
last_reviewed: 2025-11-16
---

# Redis - Transactions & Atomicity

Comprehensive guide to Redis transactions, atomic operations, optimistic locking, and Lua scripting.

## Overview

Redis provides several mechanisms for atomic operations: MULTI/EXEC transactions, pipelining, Lua scripts, and specialized atomic commands.

---

## MULTI/EXEC Transactions

### Basic Transactions

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
```

**Node.js:**
```javascript
const multi = redis.multi()

// Queue commands
multi.set('account:1', '100')
multi.set('account:2', '200')
multi.decrby('account:1', 50)
multi.incrby('account:2', 50)

// Execute atomically
const results = await multi.exec()
// Returns: [[null, 'OK'], [null, 'OK'], [null, 50], [null, 250]]
// Format: [error, result] for each command
```

### Transaction Properties

**Atomicity**: All commands execute or none do
- No partial execution
- All-or-nothing semantics

**Isolation**: Commands queued but not executed until EXEC
- Other clients' commands don't interleave
- No dirty reads

**No Rollback**: Redis doesn't rollback on errors
- Syntax errors prevent EXEC
- Runtime errors don't stop other commands

```bash
MULTI
SET key1 "value1"
INCR key1  # Error: key1 is string, not integer
SET key2 "value2"
EXEC
# Output: 1) OK 2) Error 3) OK
# key1 and key2 are still set!
```

---

## WATCH - Optimistic Locking

### Basic WATCH

```bash
# Watch keys for changes
WATCH account:1

GET account:1
# Output: "100"

# Start transaction
MULTI
DECRBY account:1 50
EXEC

# If another client modified account:1 between WATCH and EXEC,
# EXEC returns (nil) and transaction fails
```

**Node.js Pattern:**
```javascript
async function transfer(fromId, toId, amount) {
  const fromKey = `account:${fromId}`
  const toKey = `account:${toId}`

  // Watch source account
  await redis.watch(fromKey)

  // Check balance
  const balance = parseInt(await redis.get(fromKey)) || 0
  if (balance < amount) {
    await redis.unwatch()
    throw new Error('Insufficient funds')
  }

  // Start transaction
  const multi = redis.multi()
  multi.decrby(fromKey, amount)
  multi.incrby(toKey, amount)

  // Execute
  const results = await multi.exec()

  if (results === null) {
    throw new Error('Transaction failed - account modified')
  }

  return results
}

// Usage with retry
async function transferWithRetry(fromId, toId, amount, maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await transfer(fromId, toId, amount)
    } catch (error) {
      if (error.message.includes('modified') && i < maxRetries - 1) {
        await sleep(Math.random() * 100) // Random backoff
        continue
      }
      throw error
    }
  }
  throw new Error('Transfer failed after retries')
}
```

### UNWATCH - Cancel Watching

```bash
WATCH key1 key2

# Cancel watching
UNWATCH

# Now modifications to key1 or key2 won't affect transactions
```

---

## DISCARD - Cancel Transaction

```bash
MULTI
SET key1 "value1"
SET key2 "value2"

# Cancel transaction (discard queued commands)
DISCARD
# Output: OK

# No commands were executed
```

**Node.js:**
```javascript
const multi = redis.multi()

multi.set('key1', 'value1')
multi.set('key2', 'value2')

// Cancel if condition not met
if (!condition) {
  multi.discard()
  return
}

await multi.exec()
```

---

## Lua Scripting

### Why Lua Scripts?

**Benefits:**
- **Atomic**: Script executes as single atomic operation
- **Server-side**: No network round-trips
- **Composable**: Complex logic in one operation
- **Fast**: Executed natively in Redis

### EVAL - Execute Script

```bash
# Simple script
EVAL "return redis.call('SET', KEYS[1], ARGV[1])" 1 mykey myvalue
# 1 = number of keys
# KEYS[1] = 'mykey'
# ARGV[1] = 'myvalue'

# Script with logic
EVAL "
  local current = redis.call('GET', KEYS[1])
  if current then
    return redis.call('INCR', KEYS[1])
  else
    return redis.call('SET', KEYS[1], ARGV[1])
  end
" 1 counter 1
```

**Node.js:**
```javascript
// Simple script
const result = await redis.eval(
  `return redis.call('SET', KEYS[1], ARGV[1])`,
  1,  // Number of keys
  'mykey',  // KEYS[1]
  'myvalue' // ARGV[1]
)

// Multi-line script
const script = `
  local current = redis.call('GET', KEYS[1])
  if current then
    return redis.call('INCR', KEYS[1])
  else
    return redis.call('SET', KEYS[1], ARGV[1])
  end
`

const result = await redis.eval(script, 1, 'counter', '1')
```

### EVALSHA - Cached Scripts

```bash
# Load script (returns SHA1 hash)
SCRIPT LOAD "return redis.call('GET', KEYS[1])"
# Output: "a42059b356c875f0717db19a51f6aaca9ae659ea"

# Execute by SHA
EVALSHA a42059b356c875f0717db19a51f6aaca9ae659ea 1 mykey
```

**Node.js - Script Caching:**
```javascript
class ScriptManager {
  constructor(redis) {
    this.redis = redis
    this.scripts = new Map()
  }

  async register(name, script) {
    const sha = await this.redis.script('LOAD', script)
    this.scripts.set(name, { script, sha })
    return sha
  }

  async run(name, keys, args) {
    const { script, sha } = this.scripts.get(name)

    try {
      // Try cached SHA
      return await this.redis.evalsha(sha, keys.length, ...keys, ...args)
    } catch (error) {
      if (error.message.includes('NOSCRIPT')) {
        // Script not cached - reload and retry
        const newSha = await this.redis.script('LOAD', script)
        this.scripts.get(name).sha = newSha
        return await this.redis.evalsha(newSha, keys.length, ...keys, ...args)
      }
      throw error
    }
  }
}

// Usage
const scripts = new ScriptManager(redis)

// Register scripts
await scripts.register('getAndIncr', `
  local current = redis.call('GET', KEYS[1])
  redis.call('INCR', KEYS[1])
  return current
`)

// Run scripts
const previous = await scripts.run('getAndIncr', ['counter'], [])
```

### Common Lua Patterns

**Rate Limiting:**
```javascript
const rateLimitScript = `
  local key = KEYS[1]
  local limit = tonumber(ARGV[1])
  local window = tonumber(ARGV[2])
  local current = tonumber(redis.call('GET', key) or '0')

  if current >= limit then
    return 0  -- Rate limit exceeded
  end

  redis.call('INCR', key)
  if current == 0 then
    redis.call('EXPIRE', key, window)
  end

  return limit - current - 1  -- Remaining requests
`

async function checkRateLimit(userId, limit, window) {
  const remaining = await redis.eval(
    rateLimitScript,
    1,
    `rate:${userId}`,
    limit,
    window
  )

  return {
    allowed: remaining >= 0,
    remaining: Math.max(0, remaining)
  }
}
```

**Atomic Increment with Max:**
```javascript
const incrementWithMaxScript = `
  local current = tonumber(redis.call('GET', KEYS[1]) or '0')
  local max = tonumber(ARGV[1])

  if current >= max then
    return current  -- Already at max
  end

  redis.call('INCR', KEYS[1])
  return current + 1
`

const newValue = await redis.eval(
  incrementWithMaxScript,
  1,
  'counter',
  100  // max value
)
```

**Conditional Set:**
```javascript
const conditionalSetScript = `
  local current = redis.call('GET', KEYS[1])
  local expected = ARGV[1]
  local newValue = ARGV[2]

  if current == expected then
    redis.call('SET', KEYS[1], newValue)
    return 1  -- Success
  end

  return 0  -- Failed (value changed)
`

const success = await redis.eval(
  conditionalSetScript,
  1,
  'config:setting',
  'old_value',
  'new_value'
)
```

**List Push with Cap:**
```javascript
const listPushWithCapScript = `
  redis.call('LPUSH', KEYS[1], ARGV[1])
  redis.call('LTRIM', KEYS[1], 0, tonumber(ARGV[2]) - 1)
  return redis.call('LLEN', KEYS[1])
`

// Add item and keep only last 100
const listLength = await redis.eval(
  listPushWithCapScript,
  1,
  'recent:items',
  JSON.stringify(item),
  100  // max length
)
```

---

## Pipelining

### What is Pipelining?

**Pipelining**: Send multiple commands without waiting for responses
- Reduces network round-trips
- NOT atomic (unlike MULTI/EXEC)
- Faster for batch operations

```javascript
// ❌ SLOW - Individual requests
for (let i = 0; i < 1000; i++) {
  await redis.set(`key:${i}`, i)
}
// Time: ~2-3 seconds

// ✅ FAST - Pipelined
const pipeline = redis.pipeline()
for (let i = 0; i < 1000; i++) {
  pipeline.set(`key:${i}`, i)
}
await pipeline.exec()
// Time: ~50-100ms
```

### Pipeline vs Transaction

```javascript
// Pipeline (NOT atomic)
const pipeline = redis.pipeline()
pipeline.set('key1', 'value1')
pipeline.set('key2', 'value2')
await pipeline.exec()
// Other clients can see key1 before key2 is set

// Transaction (atomic)
const multi = redis.multi()
multi.set('key1', 'value1')
multi.set('key2', 'value2')
await multi.exec()
// Both keys set atomically
```

### Combining Pipeline + Transaction

```javascript
// Atomic transaction with pipelining benefit
const multi = redis.multi()

for (let i = 0; i < 1000; i++) {
  multi.set(`key:${i}`, i)
}

// All commands execute atomically, pipelined
await multi.exec()
```

---

## Atomic Commands

### Built-in Atomic Operations

**No transaction needed - already atomic:**

```javascript
// Increment
await redis.incr('counter')
await redis.incrby('counter', 10)
await redis.incrbyfloat('price', 1.5)

// Decrement
await redis.decr('counter')
await redis.decrby('counter', 5)

// Set if not exists
await redis.setnx('lock:resource', 'locked')

// Get and set
await redis.getset('key', 'newvalue')

// Append
await redis.append('message', ' world')

// Hash increment
await redis.hincrby('stats:api', 'requests', 1)

// Set add
await redis.sadd('tags', 'redis', 'database')

// Sorted set add/increment
await redis.zadd('leaderboard', 100, 'player1')
await redis.zincrby('leaderboard', 10, 'player1')

// List push/pop
await redis.lpush('queue', 'job1')
await redis.rpop('queue')

// Atomic list move
await redis.rpoplpush('source', 'destination')
```

---

## Patterns & Best Practices

### Bank Transfer

```javascript
async function transfer(fromId, toId, amount) {
  const fromKey = `account:${fromId}`
  const toKey = `account:${toId}`

  // Watch source account
  await redis.watch(fromKey)

  // Check balance
  const balance = parseInt(await redis.get(fromKey)) || 0
  if (balance < amount) {
    await redis.unwatch()
    throw new Error('Insufficient funds')
  }

  // Execute transfer atomically
  const multi = redis.multi()
  multi.decrby(fromKey, amount)
  multi.incrby(toKey, amount)

  const results = await multi.exec()

  if (results === null) {
    throw new Error('Account modified during transaction')
  }

  return {
    from: results[0][1],
    to: results[1][1]
  }
}
```

### Inventory Decrement

```javascript
const decrementInventoryScript = `
  local current = tonumber(redis.call('GET', KEYS[1]) or '0')
  local amount = tonumber(ARGV[1])

  if current < amount then
    return -1  -- Insufficient inventory
  end

  redis.call('DECRBY', KEYS[1], amount)
  return current - amount  -- New inventory
`

async function reserveInventory(productId, quantity) {
  const remaining = await redis.eval(
    decrementInventoryScript,
    1,
    `inventory:${productId}`,
    quantity
  )

  if (remaining < 0) {
    throw new Error('Out of stock')
  }

  return remaining
}
```

### Distributed Lock

```javascript
const acquireLockScript = `
  local lockKey = KEYS[1]
  local lockValue = ARGV[1]
  local ttl = tonumber(ARGV[2])

  if redis.call('EXISTS', lockKey) == 0 then
    redis.call('SET', lockKey, lockValue, 'EX', ttl)
    return 1  -- Lock acquired
  end

  return 0  -- Lock held by another client
`

const releaseLockScript = `
  local lockKey = KEYS[1]
  local lockValue = ARGV[1]

  if redis.call('GET', lockKey) == lockValue then
    return redis.call('DEL', lockKey)
  end

  return 0  -- Lock not owned
`

class DistributedLock {
  constructor(redis) {
    this.redis = redis
  }

  async acquire(resource, ttl = 30) {
    const lockKey = `lock:${resource}`
    const lockValue = crypto.randomUUID()

    const acquired = await this.redis.eval(
      acquireLockScript,
      1,
      lockKey,
      lockValue,
      ttl
    )

    if (!acquired) {
      return null
    }

    return async () => {
      await this.redis.eval(releaseLockScript, 1, lockKey, lockValue)
    }
  }
}

// Usage
const lock = new DistributedLock(redis)

const release = await lock.acquire('order:5432', 30)
if (!release) {
  throw new Error('Resource locked')
}

try {
  // Process order
  await processOrder('5432')
} finally {
  await release()
}
```

---

## Error Handling

### Transaction Errors

```javascript
try {
  const multi = redis.multi()
  multi.set('key1', 'value1')
  multi.incr('key1')  // Will error
  multi.set('key2', 'value2')

  const results = await multi.exec()

  // Check each result
  for (const [error, result] of results) {
    if (error) {
      console.error('Command failed:', error)
      // Handle error
    }
  }
} catch (error) {
  console.error('Transaction failed:', error)
}
```

### Lua Script Errors

```javascript
try {
  const result = await redis.eval(script, keys.length, ...keys, ...args)
} catch (error) {
  if (error.message.includes('ERR Error running script')) {
    console.error('Lua script error:', error)
    // Check script logic
  } else if (error.message.includes('NOSCRIPT')) {
    console.error('Script not cached - reloading')
    // Reload script
  } else {
    throw error
  }
}
```

---

## Performance Tips

1. **Use Lua scripts for complex operations** - Avoid multiple round-trips
2. **Pipeline when possible** - Batch non-atomic operations
3. **Keep transactions short** - Don't hold locks long
4. **Watch only necessary keys** - Reduce contention
5. **Cache Lua scripts** - Use EVALSHA, not EVAL

---

## Next Steps

After mastering transactions, explore:

1. **Persistence** → See `07-PERSISTENCE.md` for data durability
2. **Performance** → See `08-PERFORMANCE.md` for optimization
3. **Clustering** → See `09-CLUSTERING.md` for distributed Redis
4. **Replication** → See `10-REPLICATION.md` for high availability
5. **Production** → See `11-CONFIG-OPERATIONS.md` for deployment

---

## AI Pair Programming Notes

**When to load this KB:**
- Implementing atomic operations
- Building transactional logic
- Writing Lua scripts
- Ensuring data consistency

**Common starting points:**
- Basic transactions: See MULTI/EXEC section
- Optimistic locking: See WATCH section
- Server-side logic: See Lua Scripting section
- Batch operations: See Pipelining section

**Typical questions:**
- "How do I make operations atomic?" → MULTI/EXEC
- "How do I handle concurrent updates?" → WATCH
- "How do I run server-side logic?" → Lua Scripting
- "What's the difference between pipeline and transaction?" → Pipeline vs Transaction

**Related topics:**
- Basics: See `02-BASIC-OPERATIONS.md`
- Patterns: See `04-CACHING-STRATEGIES.md`
- Performance: See `08-PERFORMANCE.md`

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1
