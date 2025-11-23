---
id: redis-caching-strategies
topic: redis
file_role: guide
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [redis-fundamentals, redis-basic-operations, redis-data-structures]
related_topics: [caching, cache-invalidation, ttl, eviction-policies]
embedding_keywords: [redis, caching, cache-aside, write-through, write-back, cache-invalidation, eviction]
last_reviewed: 2025-11-16
---

# Redis - Caching Strategies

Comprehensive guide to caching patterns, invalidation strategies, and production-ready cache implementations.

## Overview

Redis is most commonly used as a cache layer to reduce database load and improve application performance. This guide covers cache patterns, invalidation strategies, and best practices.

---

## Caching Patterns

### Cache-Aside (Lazy Loading)

**Most common pattern - application manages cache**

```javascript
async function getUser(userId) {
  const cacheKey = `user:${userId}`

  // 1. Try cache first
  const cached = await redis.get(cacheKey)
  if (cached) {
    return JSON.parse(cached)
  }

  // 2. Cache miss - fetch from database
  const user = await db.users.findOne({ id: userId })

  if (!user) {
    throw new Error('User not found')
  }

  // 3. Store in cache
  await redis.setex(cacheKey, 3600, JSON.stringify(user))

  return user
}
```

**Pros:**
- Simple to implement
- Cache only contains requested data
- Resilient to cache failures

**Cons:**
- Cache miss penalty (3 operations: cache check, DB query, cache write)
- Possible cache stampede

### Write-Through Cache

**Write to cache and database simultaneously**

```javascript
async function updateUser(userId, updates) {
  const cacheKey = `user:${userId}`

  // 1. Update database
  const user = await db.users.findOneAndUpdate(
    { id: userId },
    updates,
    { new: true }
  )

  // 2. Update cache immediately
  await redis.setex(cacheKey, 3600, JSON.stringify(user))

  return user
}
```

**Pros:**
- Cache always in sync with database
- Read operations faster (always cached)

**Cons:**
- Write penalty (2 operations)
- May cache data that's never read

### Write-Back (Write-Behind) Cache

**Write to cache first, async write to database**

```javascript
async function updateUser(userId, updates) {
  const cacheKey = `user:${userId}`
  const dirtyKey = `dirty:user:${userId}`

  // 1. Update cache immediately
  const cached = await redis.get(cacheKey)
  const user = { ...JSON.parse(cached), ...updates }
  await redis.setex(cacheKey, 3600, JSON.stringify(user))

  // 2. Mark as dirty for background sync
  await redis.sadd('dirty:users', userId)

  return user
}

// Background worker syncs to database
async function syncDirtyUsers() {
  while (true) {
    const userId = await redis.spop('dirty:users')
    if (!userId) {
      await sleep(1000)
      continue
    }

    const cacheKey = `user:${userId}`
    const cached = await redis.get(cacheKey)
    if (cached) {
      await db.users.updateOne({ id: userId }, JSON.parse(cached))
    }
  }
}
```

**Pros:**
- Fastest writes
- Batching possible
- Reduced database load

**Cons:**
- Complex implementation
- Risk of data loss if cache fails
- Eventual consistency

### Refresh-Ahead Cache

**Refresh cache before expiration**

```javascript
async function getUser(userId) {
  const cacheKey = `user:${userId}`
  const ttlKey = `${cacheKey}:ttl`

  const cached = await redis.get(cacheKey)
  if (cached) {
    // Check if refresh needed (< 20% TTL remaining)
    const ttl = await redis.ttl(cacheKey)
    if (ttl > 0 && ttl < 720) { // < 12 minutes out of 1 hour
      // Async refresh (don't wait)
      refreshUserCache(userId).catch(err => console.error(err))
    }
    return JSON.parse(cached)
  }

  // Cache miss - synchronous fetch
  return await refreshUserCache(userId)
}

async function refreshUserCache(userId) {
  const user = await db.users.findOne({ id: userId })
  await redis.setex(`user:${userId}`, 3600, JSON.stringify(user))
  return user
}
```

**Pros:**
- Prevents cache misses for hot data
- Lower latency for reads

**Cons:**
- Complexity in refresh logic
- May refresh rarely-used data

---

## Cache Invalidation Strategies

### TTL-Based Invalidation

**Set expiration on all cache keys**

```javascript
// Short TTL for volatile data
await redis.setex('price:BTC', 60, currentPrice) // 1 minute

// Medium TTL for semi-static data
await redis.setex(`user:${userId}`, 3600, JSON.stringify(user)) // 1 hour

// Long TTL for static data
await redis.setex('config:app', 86400, JSON.stringify(config)) // 24 hours
```

**Stale-While-Revalidate Pattern:**
```javascript
async function getWithRefresh(key, ttl, fetchFn) {
  const cached = await redis.get(key)
  const ttlRemaining = await redis.ttl(key)

  if (cached) {
    // Async refresh if TTL < 20%
    if (ttlRemaining > 0 && ttlRemaining < ttl * 0.2) {
      fetchFn().then(data => 
        redis.setex(key, ttl, JSON.stringify(data))
      ).catch(console.error)
    }
    return JSON.parse(cached)
  }

  // Cache miss - synchronous fetch
  const data = await fetchFn()
  await redis.setex(key, ttl, JSON.stringify(data))
  return data
}
```

### Event-Based Invalidation

**Invalidate on data changes**

```javascript
async function updateUser(userId, updates) {
  // 1. Update database
  const user = await db.users.findOneAndUpdate(
    { id: userId },
    updates,
    { new: true }
  )

  // 2. Invalidate related cache keys
  await redis.del(`user:${userId}`)
  await redis.del(`user:${userId}:profile`)
  await redis.del(`user:${userId}:settings`)

  return user
}
```

**Pattern Matching Invalidation:**
```javascript
async function invalidatePattern(pattern) {
  let cursor = '0'
  const keys = []

  // Find all matching keys
  do {
    const [newCursor, foundKeys] = await redis.scan(cursor, 'MATCH', pattern)
    cursor = newCursor
    keys.push(...foundKeys)
  } while (cursor !== '0')

  // Delete in batches
  if (keys.length > 0) {
    const pipeline = redis.pipeline()
    for (const key of keys) {
      pipeline.del(key)
    }
    await pipeline.exec()
  }

  return keys.length
}

// Usage
await invalidatePattern('user:1000:*') // All cache for user 1000
```

### Cache Tags

**Tag-based invalidation for complex dependencies**

```javascript
async function cacheWithTags(key, value, ttl, tags) {
  // Store value
  await redis.setex(key, ttl, JSON.stringify(value))

  // Associate with tags
  const pipeline = redis.pipeline()
  for (const tag of tags) {
    pipeline.sadd(`tag:${tag}`, key)
    pipeline.expire(`tag:${tag}`, ttl + 60) // Slightly longer TTL
  }
  await pipeline.exec()
}

async function invalidateByTag(tag) {
  const keys = await redis.smembers(`tag:${tag}`)

  if (keys.length > 0) {
    const pipeline = redis.pipeline()
    for (const key of keys) {
      pipeline.del(key)
    }
    pipeline.del(`tag:${tag}`) // Remove tag set
    await pipeline.exec()
  }

  return keys.length
}

// Usage
await cacheWithTags(
  'article:123',
  article,
  3600,
  ['user:1000', 'category:tech', 'featured']
)

// Invalidate all articles by user 1000
await invalidateByTag('user:1000')
```

### Version-Based Invalidation

**Include version in cache key**

```javascript
// Generate version on entity update
async function updateUser(userId, updates) {
  const user = await db.users.findOneAndUpdate(
    { id: userId },
    { ...updates, version: Date.now() },
    { new: true }
  )

  return user
}

// Use version in cache key
async function getUser(userId) {
  const user = await db.users.findOne({ id: userId }, { version: 1 })
  const cacheKey = `user:${userId}:v${user.version}`

  const cached = await redis.get(cacheKey)
  if (cached) {
    return JSON.parse(cached)
  }

  const fullUser = await db.users.findOne({ id: userId })
  await redis.setex(cacheKey, 3600, JSON.stringify(fullUser))

  return fullUser
}
```

---

## Cache Warming

### Pre-populate on Startup

```javascript
async function warmCache() {
  console.log('Warming cache...')

  // Fetch frequently accessed data
  const popularArticles = await db.articles.find({ views: { $gt: 10000 } })

  const pipeline = redis.pipeline()
  for (const article of popularArticles) {
    pipeline.setex(
      `article:${article.id}`,
      3600,
      JSON.stringify(article)
    )
  }

  await pipeline.exec()

  console.log(`Cached ${popularArticles.length} popular articles`)
}

// Run on application startup
await warmCache()
```

### Scheduled Refresh

```javascript
// Refresh top users every hour
setInterval(async () => {
  const topUsers = await db.users.find({ rank: { $lte: 1000 } })

  const pipeline = redis.pipeline()
  for (const user of topUsers) {
    pipeline.setex(`user:${user.id}`, 3600, JSON.stringify(user))
  }

  await pipeline.exec()
}, 3600000) // Every hour
```

### On-Demand Warming

```javascript
async function warmUserCache(userId) {
  const user = await db.users.findOne({ id: userId })

  // Warm multiple related caches
  await Promise.all([
    redis.setex(`user:${userId}`, 3600, JSON.stringify(user)),
    redis.setex(`user:${userId}:profile`, 3600, JSON.stringify(user.profile)),
    redis.setex(`user:${userId}:stats`, 3600, JSON.stringify(user.stats)),
  ])
}
```

---

## Cache Stampede Prevention

### Problem

```javascript
// ❌ Cache stampede - multiple requests fetch same data
async function getPopularArticle(id) {
  const cached = await redis.get(`article:${id}`)
  if (cached) return JSON.parse(cached)

  // 100 concurrent requests all hit this path
  const article = await db.articles.findOne({ id }) // Database overload!

  await redis.setex(`article:${id}`, 3600, JSON.stringify(article))
  return article
}
```

### Solution 1: Distributed Lock

```javascript
async function getArticleWithLock(id) {
  const cacheKey = `article:${id}`
  const lockKey = `lock:${cacheKey}`

  // Check cache
  let cached = await redis.get(cacheKey)
  if (cached) return JSON.parse(cached)

  // Try to acquire lock
  const lockAcquired = await redis.set(lockKey, '1', 'NX', 'EX', 10)

  if (lockAcquired) {
    // We have the lock - fetch data
    try {
      const article = await db.articles.findOne({ id })
      await redis.setex(cacheKey, 3600, JSON.stringify(article))
      return article
    } finally {
      await redis.del(lockKey)
    }
  } else {
    // Another request is fetching - wait and retry
    await sleep(100)
    cached = await redis.get(cacheKey)
    if (cached) return JSON.parse(cached)

    // If still not cached, fetch ourselves
    const article = await db.articles.findOne({ id })
    return article
  }
}
```

### Solution 2: Probabilistic Early Expiration

```javascript
async function getWithProbabilisticRefresh(key, ttl, fetchFn) {
  const cached = await redis.get(key)
  if (!cached) {
    const data = await fetchFn()
    await redis.setex(key, ttl, JSON.stringify(data))
    return data
  }

  const ttlRemaining = await redis.ttl(key)

  // Probabilistic early refresh
  const beta = 1.0
  const delta = ttlRemaining
  const random = Math.random() * delta * beta

  if (random < 1) {
    // Refresh cache
    const data = await fetchFn()
    await redis.setex(key, ttl, JSON.stringify(data))
    return data
  }

  return JSON.parse(cached)
}
```

### Solution 3: Stale Serve + Background Refresh

```javascript
async function getWithStaleServe(key, ttl, fetchFn) {
  const staleKey = `${key}:stale`

  const cached = await redis.get(key)
  if (cached) return JSON.parse(cached)

  // Check stale cache
  const stale = await redis.get(staleKey)
  if (stale) {
    // Serve stale data immediately
    const data = JSON.parse(stale)

    // Refresh in background
    fetchFn().then(fresh => {
      redis.setex(key, ttl, JSON.stringify(fresh))
      redis.setex(staleKey, ttl * 2, JSON.stringify(fresh))
    }).catch(console.error)

    return data
  }

  // No cache at all - synchronous fetch
  const data = await fetchFn()
  await redis.setex(key, ttl, JSON.stringify(data))
  await redis.setex(staleKey, ttl * 2, JSON.stringify(data))
  return data
}
```

---

## Eviction Policies

### Understanding Eviction

**When `maxmemory` is reached, Redis evicts keys based on policy**

```conf
# redis.conf
maxmemory 256mb
maxmemory-policy allkeys-lru
```

### Eviction Policies

| Policy | Description | Use Case |
|--------|-------------|----------|
| **noeviction** | Return error when memory full | Not recommended for cache |
| **allkeys-lru** | Evict least recently used (any key) | General-purpose cache |
| **allkeys-lfu** | Evict least frequently used (any key) | Frequency-based cache |
| **allkeys-random** | Evict random key | Testing only |
| **volatile-lru** | Evict LRU (only keys with TTL) | Mixed workload |
| **volatile-lfu** | Evict LFU (only keys with TTL) | Mixed workload |
| **volatile-random** | Evict random (only keys with TTL) | Testing only |
| **volatile-ttl** | Evict soonest to expire | Time-sensitive data |

### Choosing an Eviction Policy

```javascript
// General-purpose cache (recommended)
CONFIG SET maxmemory-policy allkeys-lru

// Frequency-based (better for Zipf distribution)
CONFIG SET maxmemory-policy allkeys-lfu

// Mixed persistent + cache data
CONFIG SET maxmemory-policy volatile-lru

// Time-sensitive data
CONFIG SET maxmemory-policy volatile-ttl
```

---

## Multi-Tier Caching

### Application + Redis + Database

```javascript
class CacheService {
  constructor() {
    this.memoryCache = new Map() // L1: In-memory
    this.redis = new Redis()      // L2: Redis
  }

  async get(key, fetchFn, { memTTL = 60, redisTTL = 3600 } = {}) {
    // L1: Check memory cache
    const memCached = this.memoryCache.get(key)
    if (memCached && Date.now() < memCached.expires) {
      return memCached.value
    }

    // L2: Check Redis
    const redisCached = await this.redis.get(key)
    if (redisCached) {
      const value = JSON.parse(redisCached)

      // Store in L1
      this.memoryCache.set(key, {
        value,
        expires: Date.now() + memTTL * 1000
      })

      return value
    }

    // L3: Fetch from database
    const value = await fetchFn()

    // Store in both caches
    await this.redis.setex(key, redisTTL, JSON.stringify(value))
    this.memoryCache.set(key, {
      value,
      expires: Date.now() + memTTL * 1000
    })

    return value
  }

  async invalidate(key) {
    this.memoryCache.delete(key)
    await this.redis.del(key)
  }
}

// Usage
const cache = new CacheService()

const user = await cache.get(
  `user:${userId}`,
  () => db.users.findOne({ id: userId }),
  { memTTL: 30, redisTTL: 3600 }
)
```

---

## Cache Metrics & Monitoring

### Track Cache Performance

```javascript
class CacheWithMetrics {
  constructor(redis) {
    this.redis = redis
    this.metrics = {
      hits: 0,
      misses: 0,
      sets: 0,
      errors: 0,
    }
  }

  async get(key) {
    try {
      const value = await this.redis.get(key)
      if (value) {
        this.metrics.hits++
        return JSON.parse(value)
      } else {
        this.metrics.misses++
        return null
      }
    } catch (error) {
      this.metrics.errors++
      throw error
    }
  }

  async set(key, value, ttl) {
    try {
      await this.redis.setex(key, ttl, JSON.stringify(value))
      this.metrics.sets++
    } catch (error) {
      this.metrics.errors++
      throw error
    }
  }

  getStats() {
    const total = this.metrics.hits + this.metrics.misses
    return {
      ...this.metrics,
      hitRate: total > 0 ? (this.metrics.hits / total * 100).toFixed(2) : 0
    }
  }
}

// Usage
const cache = new CacheWithMetrics(redis)

// Log metrics periodically
setInterval(() => {
  console.log('Cache stats:', cache.getStats())
}, 60000)
```

### Redis INFO Stats

```javascript
async function getCacheStats() {
  const info = await redis.info('stats')

  // Parse relevant metrics
  const stats = {}
  for (const line of info.split('\r\n')) {
    if (line.includes(':')) {
      const [key, value] = line.split(':')
      stats[key] = value
    }
  }

  return {
    keyspaceHits: parseInt(stats.keyspace_hits || 0),
    keyspaceMisses: parseInt(stats.keyspace_misses || 0),
    hitRate: (
      (parseInt(stats.keyspace_hits || 0) /
        (parseInt(stats.keyspace_hits || 0) + parseInt(stats.keyspace_misses || 1))) *
      100
    ).toFixed(2),
    evictedKeys: parseInt(stats.evicted_keys || 0),
  }
}
```

---

## Production Best Practices

### 1. Always Set TTL

```javascript
// ❌ WRONG - No expiration
await redis.set('cache:data', JSON.stringify(data))

// ✅ CORRECT - With TTL
await redis.setex('cache:data', 3600, JSON.stringify(data))
```

### 2. Use Consistent Key Naming

```javascript
// ✅ Good key structure
const cacheKey = `cache:${resource}:${id}:v${version}`

// Examples
'cache:user:1000:v123456789'
'cache:article:5432:v987654321'
'cache:product:9999:v555555555'
```

### 3. Handle Cache Failures Gracefully

```javascript
async function getUserWithFallback(userId) {
  try {
    const cached = await redis.get(`user:${userId}`)
    if (cached) return JSON.parse(cached)
  } catch (error) {
    console.error('Cache error:', error)
    // Continue to database fallback
  }

  // Fallback to database
  const user = await db.users.findOne({ id: userId })

  try {
    await redis.setex(`user:${userId}`, 3600, JSON.stringify(user))
  } catch (error) {
    console.error('Cache set error:', error)
    // Don't fail the request
  }

  return user
}
```

### 4. Monitor Cache Hit Rate

```javascript
// Target: >80% hit rate for cache effectiveness
const stats = await getCacheStats()

if (stats.hitRate < 80) {
  console.warn(`Low cache hit rate: ${stats.hitRate}%`)
  // Consider: Increasing TTLs, warming cache, reviewing access patterns
}
```

### 5. Size Your Cache Appropriately

```javascript
// Rule of thumb: 80/20 rule
// Cache 20% of data that gets 80% of requests

// Monitor memory usage
const memoryInfo = await redis.info('memory')
const usedMemory = parseInt(memoryInfo.match(/used_memory:(\d+)/)[1])
const maxMemory = parseInt(memoryInfo.match(/maxmemory:(\d+)/)[1])

const usage = (usedMemory / maxMemory * 100).toFixed(2)

if (usage > 90) {
  console.warn(`High memory usage: ${usage}%`)
}
```

---

## Next Steps

After mastering caching strategies, explore:

1. **Pub/Sub** → See `05-PUBSUB.md` for real-time messaging
2. **Transactions** → See `06-TRANSACTIONS.md` for atomic operations
3. **Persistence** → See `07-PERSISTENCE.md` for data durability
4. **Performance** → See `08-PERFORMANCE.md` for optimization
5. **Production** → See `11-CONFIG-OPERATIONS.md` for deployment

---

## AI Pair Programming Notes

**When to load this KB:**
- Implementing cache layer
- Optimizing application performance
- Reducing database load
- Cache invalidation strategies

**Common starting points:**
- Basic caching: See Cache-Aside pattern
- Invalidation: See Cache Invalidation Strategies
- Stampede prevention: See Cache Stampede Prevention
- Monitoring: See Cache Metrics & Monitoring

**Typical questions:**
- "How do I implement caching?" → Cache-Aside
- "When should I invalidate cache?" → Cache Invalidation Strategies
- "How do I prevent cache stampede?" → Cache Stampede Prevention
- "What eviction policy should I use?" → Eviction Policies

**Related topics:**
- Basics: See `02-BASIC-OPERATIONS.md`
- Data structures: See `03-DATA-STRUCTURES.md`
- Performance: See `08-PERFORMANCE.md`

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1
