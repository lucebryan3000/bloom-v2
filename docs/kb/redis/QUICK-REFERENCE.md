---
id: redis-quick-reference
topic: redis
file_role: reference
profile: full
difficulty_level: all
kb_version: 3.1
prerequisites: []
related_topics: [commands, syntax, cheat-sheet]
embedding_keywords: [redis, quick-reference, cheat-sheet, commands, syntax]
last_reviewed: 2025-11-16
---

# Redis - Quick Reference

**One-page cheat sheet for Redis commands and patterns. Bookmark this for quick lookups.**

## Connection

```bash
# Local connection
redis-cli

# Remote connection
redis-cli -h hostname -p port

# With password
redis-cli -a password

# Select database (0-15)
SELECT 0
```

---

## String Commands

### Basic Operations

```bash
# Set/Get
SET key "value"                    # Set string value
GET key                            # Get string value
GETSET key "newvalue"              # Set new value, return old

# Multiple keys
MSET key1 "val1" key2 "val2"      # Set multiple
MGET key1 key2 key3                # Get multiple

# Set with options
SETNX key "value"                  # Set if not exists
SETEX key 3600 "value"             # Set with expiration (seconds)
SET key "value" EX 3600            # Same as SETEX
SET key "value" PX 3600000         # Expiration in milliseconds
SET key "value" NX                 # Only if not exists
SET key "value" XX                 # Only if exists
SET key "value" GET                # Set and return old value

# Append/Range
APPEND key "more"                  # Append to value
GETRANGE key 0 4                   # Get substring (inclusive)
SETRANGE key 6 "text"              # Overwrite from offset
STRLEN key                         # Get string length
```

### Numeric Operations

```bash
# Increment/Decrement
INCR counter                       # Increment by 1
INCRBY counter 10                  # Increment by amount
INCRBYFLOAT price 1.5              # Increment by float
DECR counter                       # Decrement by 1
DECRBY counter 5                   # Decrement by amount
```

---

## Hash Commands

```bash
# Set/Get single field
HSET user:1000 name "Alice"        # Set field
HGET user:1000 name                # Get field
HSETNX user:1000 email "a@ex.com"  # Set if field doesn't exist

# Set/Get multiple fields
HSET user:1000 name "Alice" age "30" email "alice@example.com"
HMGET user:1000 name age email     # Get multiple fields
HGETALL user:1000                  # Get all fields (O(N) - use with caution)

# Utility
HEXISTS user:1000 name             # Check if field exists (1/0)
HDEL user:1000 age                 # Delete field(s)
HLEN user:1000                     # Count fields
HKEYS user:1000                    # Get all field names
HVALS user:1000                    # Get all values

# Increment
HINCRBY user:1000 age 1            # Increment integer field
HINCRBYFLOAT stats revenue 19.99   # Increment float field

# Iteration
HSCAN user:1000 0 COUNT 100        # Cursor-based iteration
```

---

## List Commands

```bash
# Push/Pop
LPUSH tasks "task1"                # Push to left (head)
RPUSH tasks "task2"                # Push to right (tail)
LPOP tasks                         # Pop from left
RPOP tasks                         # Pop from right
LPOP tasks 2                       # Pop multiple (Redis 6.2+)

# Blocking pop (for queues)
BLPOP tasks 5                      # Block up to 5 seconds
BRPOP tasks 0                      # Block indefinitely

# Range operations
LRANGE tasks 0 -1                  # Get all elements
LRANGE tasks 0 9                   # Get first 10
LINDEX tasks 0                     # Get element by index
LSET tasks 0 "newtask"             # Set element by index

# Utility
LLEN tasks                         # Get list length
LINSERT tasks BEFORE "task2" "task1.5"  # Insert before value
LINSERT tasks AFTER "task2" "task2.5"   # Insert after value
LREM tasks 2 "task1"               # Remove first 2 occurrences
LTRIM tasks 0 99                   # Keep only first 100 elements

# Atomic move
RPOPLPUSH source destination       # Move element (atomic)
BRPOPLPUSH source dest 5           # Blocking version
```

---

## Set Commands

```bash
# Basic operations
SADD tags "redis" "cache" "db"     # Add members
SREM tags "cache"                  # Remove members
SISMEMBER tags "redis"             # Check membership (1/0)
SMEMBERS tags                      # Get all members (O(N))
SCARD tags                         # Count members

# Set operations
SINTER set1 set2                   # Intersection
SUNION set1 set2                   # Union
SDIFF set1 set2                    # Difference (in set1, not in set2)

# Store result
SINTERSTORE result set1 set2       # Store intersection
SUNIONSTORE result set1 set2       # Store union
SDIFFSTORE result set1 set2        # Store difference

# Utility
SMOVE source dest "member"         # Move member between sets
SPOP tags                          # Remove and return random
SPOP tags 3                        # Remove and return 3 random
SRANDMEMBER tags                   # Get random (without removing)
SRANDMEMBER tags 3                 # Get 3 random members

# Iteration
SSCAN tags 0 MATCH "redis*" COUNT 100
```

---

## Sorted Set (ZSet) Commands

```bash
# Add/Remove
ZADD leaderboard 100 "Alice"       # Add with score
ZADD leaderboard 200 "Bob" 150 "Charlie"  # Add multiple
ZADD leaderboard NX 250 "David"    # Only if doesn't exist
ZADD leaderboard XX 180 "Alice"    # Only if exists
ZADD leaderboard GT 190 "Alice"    # Only if new score > current
ZADD leaderboard LT 170 "Alice"    # Only if new score < current
ZREM leaderboard "Alice"           # Remove member

# Range queries (by rank)
ZRANGE leaderboard 0 -1            # Get all (ascending by score)
ZRANGE leaderboard 0 -1 WITHSCORES # With scores
ZREVRANGE leaderboard 0 9 WITHSCORES  # Top 10 (descending)

# Range queries (by score)
ZRANGEBYSCORE leaderboard 100 200  # Members with score 100-200
ZRANGEBYSCORE leaderboard (100 200 # Exclusive lower bound
ZRANGEBYSCORE leaderboard 0 1000 LIMIT 0 10  # With pagination
ZREVRANGEBYSCORE leaderboard 200 100  # Descending

# Rank and Score
ZRANK leaderboard "Alice"          # Get rank (0-indexed, ascending)
ZREVRANK leaderboard "Alice"       # Get rank (descending)
ZSCORE leaderboard "Alice"         # Get score

# Utility
ZCARD leaderboard                  # Count members
ZCOUNT leaderboard 100 200         # Count in score range
ZINCRBY leaderboard 10 "Alice"     # Increment score

# Remove by rank/score
ZREMRANGEBYRANK leaderboard 0 9    # Remove lowest 10
ZREMRANGEBYSCORE leaderboard 0 100 # Remove with score 0-100

# Pop (Redis 5.0+)
ZPOPMIN leaderboard                # Remove and return lowest
ZPOPMAX leaderboard                # Remove and return highest
ZPOPMIN leaderboard 3              # Pop 3 lowest

# Iteration
ZSCAN leaderboard 0 COUNT 100
```

---

## Stream Commands

```bash
# Add entries
XADD events * action "login" user "alice"  # Auto-generated ID
XADD events 1700136000000-0 action "logout" user "alice"  # Custom ID
XADD events MAXLEN 1000 * action "click" page "/home"  # Cap stream length

# Read entries
XREAD STREAMS events 0             # Read all from beginning
XREAD STREAMS events $             # Read only new entries
XREAD BLOCK 5000 STREAMS events $  # Block for up to 5 seconds
XRANGE events - +                  # Read all entries
XRANGE events - + COUNT 10         # Read first 10
XREVRANGE events + - COUNT 10      # Read last 10

# Consumer groups
XGROUP CREATE events group1 0      # Create group from beginning
XGROUP CREATE events group2 $      # Create group from latest
XREADGROUP GROUP group1 consumer1 STREAMS events >  # Read new
XREADGROUP GROUP group1 consumer1 COUNT 10 STREAMS events >
XACK events group1 <entry-id>      # Acknowledge message

# Utility
XLEN events                        # Get stream length
XPENDING events group1             # Get pending messages
XINFO STREAM events                # Get stream info
```

---

## Key Management

```bash
# Existence and Type
EXISTS key                         # Check if exists (1/0)
EXISTS key1 key2 key3              # Check multiple (returns count)
TYPE key                           # Get value type

# Delete
DEL key                            # Delete key
DEL key1 key2 key3                 # Delete multiple
UNLINK key                         # Async delete (non-blocking)

# Rename
RENAME oldkey newkey               # Rename (overwrites dest)
RENAMENX oldkey newkey             # Rename if dest doesn't exist

# Expiration
EXPIRE key 3600                    # Set expiration (seconds)
PEXPIRE key 3600000                # Set expiration (milliseconds)
EXPIREAT key 1700150400            # Expire at Unix timestamp
PEXPIREAT key 1700150400000        # Expire at timestamp (ms)
TTL key                            # Get remaining time (seconds)
PTTL key                           # Get remaining time (milliseconds)
PERSIST key                        # Remove expiration

# Scanning (safe iteration)
SCAN 0                             # Cursor-based iteration
SCAN 0 MATCH user:* COUNT 100      # With pattern and count
SCAN cursor MATCH pattern COUNT count  # Continue iteration

# Database
SELECT 0                           # Switch database (0-15)
DBSIZE                             # Count keys in current DB
FLUSHDB                            # Clear current database
FLUSHALL                           # Clear all databases
```

---

## Transactions

```bash
# Basic transaction
MULTI                              # Start transaction
SET key1 "value1"
SET key2 "value2"
EXEC                               # Execute all commands

# Cancel transaction
MULTI
SET key "value"
DISCARD                            # Cancel (no commands execute)

# Optimistic locking
WATCH key                          # Watch for changes
MULTI
INCR key
EXEC                               # Returns nil if key changed

# Cancel watching
UNWATCH
```

---

## Pub/Sub

```bash
# Publish
PUBLISH channel "message"          # Send message (returns subscriber count)

# Subscribe
SUBSCRIBE channel1 channel2        # Subscribe to channels
PSUBSCRIBE user:*                  # Subscribe to pattern
UNSUBSCRIBE channel1               # Unsubscribe from channels
PUNSUBSCRIBE user:*                # Unsubscribe from patterns

# Info
PUBSUB CHANNELS                    # List active channels
PUBSUB CHANNELS user:*             # List matching pattern
PUBSUB NUMSUB channel1 channel2    # Count subscribers per channel
PUBSUB NUMPAT                      # Count pattern subscriptions
```

---

## Lua Scripting

```bash
# Execute script
EVAL "return redis.call('SET', KEYS[1], ARGV[1])" 1 mykey myvalue
# 1 = number of keys
# KEYS[1] = 'mykey'
# ARGV[1] = 'myvalue'

# Load script
SCRIPT LOAD "return redis.call('GET', KEYS[1])"
# Returns: SHA1 hash

# Execute by SHA
EVALSHA <sha1> 1 mykey

# Script management
SCRIPT EXISTS <sha1>               # Check if script cached
SCRIPT FLUSH                       # Remove all scripts
SCRIPT KILL                        # Kill running script
```

---

## Server Commands

```bash
# Info and stats
PING                               # Test connection
INFO                               # Get all server info
INFO memory                        # Memory stats
INFO stats                         # General stats
INFO replication                   # Replication info
INFO persistence                   # Persistence info

# Configuration
CONFIG GET maxmemory               # Get config value
CONFIG GET *                       # Get all config
CONFIG SET maxmemory 256mb         # Set config value
CONFIG REWRITE                     # Persist config to file

# Monitoring
MONITOR                            # Watch commands in real-time
SLOWLOG GET 10                     # Get slow queries
SLOWLOG LEN                        # Count slow queries
SLOWLOG RESET                      # Clear slow log

# Persistence
SAVE                               # Blocking snapshot
BGSAVE                             # Background snapshot
LASTSAVE                           # Last save timestamp
BGREWRITEAOF                       # Rewrite AOF file

# Client management
CLIENT LIST                        # List connected clients
CLIENT SETNAME connection-name     # Name current connection
CLIENT GETNAME                     # Get connection name
CLIENT KILL ip:port                # Kill client connection

# Database management
SELECT 0                           # Switch database
DBSIZE                             # Count keys
FLUSHDB                            # Clear current DB
FLUSHALL                           # Clear all DBs

# Shutdown
SHUTDOWN                           # Stop server (saves data)
SHUTDOWN NOSAVE                    # Stop without saving
```

---

## Replication

```bash
# Make node a replica
REPLICAOF hostname port            # Set master
REPLICAOF NO ONE                   # Stop replication (promote to master)

# Info
INFO replication                   # Get replication status
ROLE                               # Get role (master/replica)
```

---

## Cluster

```bash
# Cluster info
CLUSTER INFO                       # Get cluster state
CLUSTER NODES                      # List all nodes
CLUSTER SLOTS                      # Get slot distribution

# Node management
CLUSTER MEET ip port               # Add node to cluster
CLUSTER FORGET node-id             # Remove node
CLUSTER REPLICATE master-id        # Make current node a replica

# Slot management
CLUSTER ADDSLOTS slot...           # Assign slots to node
CLUSTER DELSLOTS slot...           # Remove slots from node
CLUSTER KEYSLOT key                # Get slot for key

# Failover
CLUSTER FAILOVER                   # Trigger manual failover
```

---

## Common Patterns

### Cache-Aside Pattern

```javascript
async function getUser(userId) {
  const key = `user:${userId}`
  
  // Try cache
  let user = await redis.get(key)
  if (user) return JSON.parse(user)
  
  // Cache miss - fetch from DB
  user = await db.users.findOne({ id: userId })
  
  // Store in cache
  await redis.setex(key, 3600, JSON.stringify(user))
  
  return user
}
```

### Rate Limiting

```bash
# Lua script for atomic rate limiting
EVAL "
  local current = tonumber(redis.call('GET', KEYS[1]) or '0')
  if current >= tonumber(ARGV[1]) then
    return 0
  end
  redis.call('INCR', KEYS[1])
  if current == 0 then
    redis.call('EXPIRE', KEYS[1], ARGV[2])
  end
  return tonumber(ARGV[1]) - current - 1
" 1 rate:user:1000 100 60
# Returns remaining requests or 0 if exceeded
```

### Distributed Lock

```bash
# Acquire lock
SET lock:resource "unique-id" NX EX 30

# Release lock (Lua script to ensure we own it)
EVAL "
  if redis.call('GET', KEYS[1]) == ARGV[1] then
    return redis.call('DEL', KEYS[1])
  end
  return 0
" 1 lock:resource "unique-id"
```

### Leaderboard

```bash
# Add score
ZADD leaderboard 1000 "player:1"

# Get top 10
ZREVRANGE leaderboard 0 9 WITHSCORES

# Get player rank (1-indexed)
# rank = ZREVRANK + 1
ZREVRANK leaderboard "player:1"

# Get players around specific rank
ZREVRANGE leaderboard rank-5 rank+5 WITHSCORES
```

### Session Storage

```bash
# Store session (30 min TTL)
SETEX session:abc123 1800 "{\"userId\":\"1000\",\"name\":\"Alice\"}"

# Get session
GET session:abc123

# Refresh TTL on access
EXPIRE session:abc123 1800
```

### Job Queue

```bash
# Producer: Add job
LPUSH queue:jobs "{\"type\":\"email\",\"to\":\"user@example.com\"}"

# Consumer: Process job (blocking)
BRPOP queue:jobs 0

# Reliable queue (move to processing list)
BRPOPLPUSH queue:pending queue:processing 30
# Process job...
# On success: LREM queue:processing 1 job
# On failure: LPUSH queue:pending job
```

---

## Time Complexity Reference

| Command | Complexity | Notes |
|---------|-----------|-------|
| **Strings** |
| GET, SET | O(1) | Constant time |
| MGET | O(N) | N = number of keys |
| INCR | O(1) | Atomic |
| **Hashes** |
| HGET, HSET | O(1) | Single field |
| HGETALL | O(N) | N = number of fields |
| HMGET | O(N) | N = number of fields requested |
| **Lists** |
| LPUSH, RPUSH | O(1) | Insert at end |
| LPOP, RPOP | O(1) | Remove from end |
| LRANGE | O(S+N) | S = start offset, N = number of elements |
| LINDEX | O(N) | N = list length |
| **Sets** |
| SADD, SREM | O(1) | Single member |
| SISMEMBER | O(1) | Membership check |
| SMEMBERS | O(N) | N = set size |
| SINTER | O(N*M) | N = smallest set, M = number of sets |
| **Sorted Sets** |
| ZADD, ZREM | O(log(N)) | N = number of elements |
| ZSCORE | O(1) | Get score |
| ZRANGE | O(log(N)+M) | M = number of elements returned |
| ZRANK | O(log(N)) | Get rank |
| **Keys** |
| DEL | O(N) | N = number of keys |
| EXISTS | O(1) | Single key |
| KEYS | O(N) | N = number of keys (NEVER use in production!) |
| SCAN | O(1) per call | Cursor-based iteration |

---

## Best Practices

✅ **Do:**
- Use SCAN instead of KEYS in production
- Set TTL on all cache keys
- Use pipelining for multiple commands
- Use appropriate data structures
- Monitor memory usage
- Set maxmemory and eviction policy
- Use Lua scripts for complex atomic operations
- Enable persistence (RDB + AOF)

❌ **Don't:**
- Use KEYS * in production (blocks server)
- Use HGETALL on large hashes
- Create keys without TTL
- Store large values (>100KB) without compression
- Use SELECT in shared environments
- Forget to handle connection failures

---

## Quick Troubleshooting

**High memory usage:**
```bash
redis-cli --bigkeys                # Find largest keys
INFO memory                        # Check memory stats
```

**Slow queries:**
```bash
SLOWLOG GET 10                     # View slow queries
```

**Connection issues:**
```bash
PING                               # Test connection
CONFIG GET timeout                 # Check timeout setting
```

**Replication lag:**
```bash
INFO replication                   # Check offset difference
```

---

## Related Files

- **[01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md)** - Core concepts
- **[02-BASIC-OPERATIONS.md](./02-BASIC-OPERATIONS.md)** - Detailed command guide
- **[INDEX.md](./INDEX.md)** - Complete navigation
- **[README.md](./README.md)** - Overview and learning paths

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1 | **Commands**: 150+
