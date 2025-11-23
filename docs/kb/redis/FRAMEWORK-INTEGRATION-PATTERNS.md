---
id: redis-framework-patterns
topic: redis
file_role: framework
profile: full
difficulty_level: advanced
kb_version: 3.1
prerequisites: [redis-fundamentals, redis-basic-operations, redis-caching-strategies]
related_topics: [nodejs, python, typescript, orm, caching]
embedding_keywords: [redis, framework, integration, nodejs, python, patterns, ioredis]
last_reviewed: 2025-11-16
---

# Redis - Framework Integration Patterns

**Advanced production-ready patterns for integrating Redis with Node.js, Python, and modern frameworks.**

## Overview

This guide covers framework-specific integration patterns, connection management, error handling, and production best practices.

---

## Node.js Integration

### ioredis Setup

**Installation:**
```bash
npm install ioredis
```

**Basic Configuration:**
```typescript
import Redis from 'ioredis'

const redis = new Redis({
  host: process.env.REDIS_HOST || 'localhost',
  port: parseInt(process.env.REDIS_PORT || '6379'),
  password: process.env.REDIS_PASSWORD,
  db: 0,
  maxRetriesPerRequest: 3,
  enableReadyCheck: true,
  enableOfflineQueue: false,
  retryStrategy: (times) => {
    const delay = Math.min(times * 50, 2000)
    return delay
  },
  reconnectOnError: (err) => {
    const targetError = 'READONLY'
    if (err.message.includes(targetError)) {
      // Reconnect on READONLY error (sentinel failover)
      return true
    }
    return false
  },
})

// Event handlers
redis.on('error', (err) => {
  console.error('Redis error:', err)
})

redis.on('connect', () => {
  console.log('Redis connected')
})

redis.on('ready', () => {
  console.log('Redis ready')
})

redis.on('close', () => {
  console.log('Redis connection closed')
})
```

### Connection Patterns

**Singleton Pattern:**
```typescript
// redis.ts
import Redis from 'ioredis'

let redisInstance: Redis | null = null

export function getRedis(): Redis {
  if (!redisInstance) {
    redisInstance = new Redis({
      host: process.env.REDIS_HOST,
      port: parseInt(process.env.REDIS_PORT || '6379'),
      password: process.env.REDIS_PASSWORD,
    })
  }
  return redisInstance
}

export async function closeRedis(): Promise<void> {
  if (redisInstance) {
    await redisInstance.quit()
    redisInstance = null
  }
}

// Usage
import { getRedis } from './redis'

const redis = getRedis()
await redis.set('key', 'value')
```

**Factory Pattern:**
```typescript
class RedisClient {
  private client: Redis
  private publisher: Redis
  private subscriber: Redis

  constructor() {
    const config = {
      host: process.env.REDIS_HOST,
      port: parseInt(process.env.REDIS_PORT || '6379'),
      password: process.env.REDIS_PASSWORD,
    }

    this.client = new Redis(config)
    this.publisher = new Redis(config)
    this.subscriber = new Redis(config)
  }

  getClient(): Redis {
    return this.client
  }

  getPublisher(): Redis {
    return this.publisher
  }

  getSubscriber(): Redis {
    return this.subscriber
  }

  async close(): Promise<void> {
    await Promise.all([
      this.client.quit(),
      this.publisher.quit(),
      this.subscriber.quit(),
    ])
  }
}

export const redisClient = new RedisClient()
```

### Type-Safe Wrapper

```typescript
interface CacheOptions {
  ttl?: number
  namespace?: string
}

class TypeSafeCache {
  constructor(private redis: Redis) {}

  async get<T>(key: string, namespace?: string): Promise<T | null> {
    const fullKey = namespace ? `${namespace}:${key}` : key
    const value = await this.redis.get(fullKey)
    
    if (!value) return null
    
    try {
      return JSON.parse(value) as T
    } catch {
      return value as T
    }
  }

  async set<T>(
    key: string,
    value: T,
    options: CacheOptions = {}
  ): Promise<void> {
    const fullKey = options.namespace ? `${options.namespace}:${key}` : key
    const serialized = typeof value === 'string' ? value : JSON.stringify(value)

    if (options.ttl) {
      await this.redis.setex(fullKey, options.ttl, serialized)
    } else {
      await this.redis.set(fullKey, serialized)
    }
  }

  async del(key: string, namespace?: string): Promise<void> {
    const fullKey = namespace ? `${namespace}:${key}` : key
    await this.redis.del(fullKey)
  }

  async exists(key: string, namespace?: string): Promise<boolean> {
    const fullKey = namespace ? `${namespace}:${key}` : key
    const result = await this.redis.exists(fullKey)
    return result === 1
  }
}

// Usage
interface User {
  id: string
  name: string
  email: string
}

const cache = new TypeSafeCache(redis)

// Type-safe operations
await cache.set<User>('1000', user, { namespace: 'user', ttl: 3600 })
const user = await cache.get<User>('1000', 'user')
```

### Caching Decorator

```typescript
function Cached(ttl: number, namespace: string = 'cache') {
  return function (
    target: any,
    propertyKey: string,
    descriptor: PropertyDescriptor
  ) {
    const originalMethod = descriptor.value

    descriptor.value = async function (...args: any[]) {
      const cacheKey = `${namespace}:${propertyKey}:${JSON.stringify(args)}`
      
      // Try cache
      const cached = await redis.get(cacheKey)
      if (cached) {
        return JSON.parse(cached)
      }

      // Execute method
      const result = await originalMethod.apply(this, args)

      // Store in cache
      await redis.setex(cacheKey, ttl, JSON.stringify(result))

      return result
    }

    return descriptor
  }
}

// Usage
class UserService {
  @Cached(3600, 'user')
  async getUser(userId: string): Promise<User> {
    return await db.users.findOne({ id: userId })
  }

  @Cached(600, 'user:list')
  async listUsers(limit: number): Promise<User[]> {
    return await db.users.find().limit(limit)
  }
}
```

### Repository Pattern

```typescript
interface Repository<T> {
  get(id: string): Promise<T | null>
  set(id: string, value: T, ttl?: number): Promise<void>
  delete(id: string): Promise<void>
  exists(id: string): Promise<boolean>
}

class RedisRepository<T> implements Repository<T> {
  constructor(
    private redis: Redis,
    private namespace: string
  ) {}

  private getKey(id: string): string {
    return `${this.namespace}:${id}`
  }

  async get(id: string): Promise<T | null> {
    const value = await this.redis.get(this.getKey(id))
    if (!value) return null
    return JSON.parse(value) as T
  }

  async set(id: string, value: T, ttl?: number): Promise<void> {
    const key = this.getKey(id)
    const serialized = JSON.stringify(value)

    if (ttl) {
      await this.redis.setex(key, ttl, serialized)
    } else {
      await this.redis.set(key, serialized)
    }
  }

  async delete(id: string): Promise<void> {
    await this.redis.del(this.getKey(id))
  }

  async exists(id: string): Promise<boolean> {
    const result = await this.redis.exists(this.getKey(id))
    return result === 1
  }
}

// Usage
const userRepo = new RedisRepository<User>(redis, 'user')
const productRepo = new RedisRepository<Product>(redis, 'product')

await userRepo.set('1000', user, 3600)
const user = await userRepo.get('1000')
```

---

## Express.js Integration

### Middleware for Caching

```typescript
import express, { Request, Response, NextFunction } from 'express'
import Redis from 'ioredis'

const redis = new Redis()

interface CacheMiddlewareOptions {
  ttl: number
  keyGenerator?: (req: Request) => string
}

function cacheMiddleware(options: CacheMiddlewareOptions) {
  return async (req: Request, res: Response, next: NextFunction) => {
    // Only cache GET requests
    if (req.method !== 'GET') {
      return next()
    }

    const cacheKey = options.keyGenerator
      ? options.keyGenerator(req)
      : `cache:${req.originalUrl}`

    try {
      const cached = await redis.get(cacheKey)

      if (cached) {
        return res.json(JSON.parse(cached))
      }

      // Capture response
      const originalJson = res.json.bind(res)
      res.json = (body: any) => {
        // Store in cache
        redis.setex(cacheKey, options.ttl, JSON.stringify(body))
          .catch(err => console.error('Cache error:', err))

        return originalJson(body)
      }

      next()
    } catch (error) {
      // Don't fail request on cache error
      console.error('Cache middleware error:', error)
      next()
    }
  }
}

// Usage
app.get('/api/users/:id',
  cacheMiddleware({
    ttl: 3600,
    keyGenerator: (req) => `user:${req.params.id}`
  }),
  async (req, res) => {
    const user = await db.users.findOne({ id: req.params.id })
    res.json(user)
  }
)
```

### Session Store

```typescript
import session from 'express-session'
import RedisStore from 'connect-redis'
import Redis from 'ioredis'

const redis = new Redis()

app.use(
  session({
    store: new RedisStore({ client: redis as any }),
    secret: process.env.SESSION_SECRET!,
    resave: false,
    saveUninitialized: false,
    cookie: {
      secure: process.env.NODE_ENV === 'production',
      httpOnly: true,
      maxAge: 1000 * 60 * 60 * 24, // 24 hours
    },
  })
)
```

### Rate Limiting

```typescript
import rateLimit from 'express-rate-limit'
import RedisStore from 'rate-limit-redis'
import Redis from 'ioredis'

const redis = new Redis()

const limiter = rateLimit({
  store: new RedisStore({
    client: redis as any,
    prefix: 'rate:',
  }),
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP',
})

app.use('/api/', limiter)
```

---

## Next.js Integration

### API Route Caching

```typescript
// pages/api/users/[id].ts
import type { NextApiRequest, NextApiResponse } from 'next'
import { getRedis } from '@/lib/redis'

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  const { id } = req.query
  const redis = getRedis()

  const cacheKey = `user:${id}`

  // Try cache
  const cached = await redis.get(cacheKey)
  if (cached) {
    return res.json(JSON.parse(cached))
  }

  // Fetch from database
  const user = await db.users.findOne({ id })

  if (!user) {
    return res.status(404).json({ error: 'User not found' })
  }

  // Cache for 1 hour
  await redis.setex(cacheKey, 3600, JSON.stringify(user))

  res.json(user)
}
```

### Revalidation with Cache Tags

```typescript
class CacheManager {
  constructor(private redis: Redis) {}

  async cacheWithTags(
    key: string,
    value: any,
    ttl: number,
    tags: string[]
  ): Promise<void> {
    await this.redis.setex(key, ttl, JSON.stringify(value))

    const pipeline = this.redis.pipeline()
    for (const tag of tags) {
      pipeline.sadd(`tag:${tag}`, key)
      pipeline.expire(`tag:${tag}`, ttl + 60)
    }
    await pipeline.exec()
  }

  async invalidateByTag(tag: string): Promise<number> {
    const keys = await this.redis.smembers(`tag:${tag}`)

    if (keys.length > 0) {
      const pipeline = this.redis.pipeline()
      for (const key of keys) {
        pipeline.del(key)
      }
      pipeline.del(`tag:${tag}`)
      await pipeline.exec()
    }

    return keys.length
  }
}

// Usage
const cacheManager = new CacheManager(redis)

// Cache with tags
await cacheManager.cacheWithTags(
  'article:123',
  article,
  3600,
  ['user:1000', 'category:tech']
)

// Invalidate all articles by user
await cacheManager.invalidateByTag('user:1000')
```

---

## Python Integration

### redis-py Setup

```python
import redis
import json
from typing import Optional, Any
from functools import wraps
import time

# Connection pool
pool = redis.ConnectionPool(
    host='localhost',
    port=6379,
    password='your_password',
    db=0,
    decode_responses=True,
    max_connections=10
)

# Get connection from pool
r = redis.Redis(connection_pool=pool)
```

### Caching Decorator

```python
def cached(ttl: int, namespace: str = 'cache'):
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            # Generate cache key
            cache_key = f"{namespace}:{func.__name__}:{args}:{kwargs}"
            
            # Try cache
            cached_value = r.get(cache_key)
            if cached_value:
                return json.loads(cached_value)
            
            # Execute function
            result = func(*args, **kwargs)
            
            # Store in cache
            r.setex(cache_key, ttl, json.dumps(result))
            
            return result
        return wrapper
    return decorator

# Usage
@cached(ttl=3600, namespace='user')
def get_user(user_id: int) -> dict:
    # Fetch from database
    user = db.users.find_one({'id': user_id})
    return user
```

### Repository Pattern

```python
from typing import TypeVar, Generic, Optional
from dataclasses import dataclass, asdict
import json

T = TypeVar('T')

class RedisRepository(Generic[T]):
    def __init__(self, redis_client: redis.Redis, namespace: str):
        self.redis = redis_client
        self.namespace = namespace
    
    def _get_key(self, id: str) -> str:
        return f"{self.namespace}:{id}"
    
    def get(self, id: str) -> Optional[T]:
        value = self.redis.get(self._get_key(id))
        if not value:
            return None
        return json.loads(value)
    
    def set(self, id: str, value: T, ttl: Optional[int] = None) -> None:
        key = self._get_key(id)
        serialized = json.dumps(value if isinstance(value, dict) else asdict(value))
        
        if ttl:
            self.redis.setex(key, ttl, serialized)
        else:
            self.redis.set(key, serialized)
    
    def delete(self, id: str) -> None:
        self.redis.delete(self._get_key(id))
    
    def exists(self, id: str) -> bool:
        return self.redis.exists(self._get_key(id)) == 1

# Usage
@dataclass
class User:
    id: str
    name: str
    email: str

user_repo = RedisRepository[User](r, 'user')
user_repo.set('1000', User('1000', 'Alice', 'alice@example.com'), ttl=3600)
user = user_repo.get('1000')
```

---

## Django Integration

### Cache Backend

```python
# settings.py
CACHES = {
    'default': {
        'BACKEND': 'django_redis.cache.RedisCache',
        'LOCATION': 'redis://127.0.0.1:6379/1',
        'OPTIONS': {
            'CLIENT_CLASS': 'django_redis.client.DefaultClient',
            'PASSWORD': 'your_password',
        }
    }
}

# Session backend
SESSION_ENGINE = 'django.contrib.sessions.backends.cache'
SESSION_CACHE_ALIAS = 'default'
```

### View Caching

```python
from django.core.cache import cache
from django.views.decorators.cache import cache_page

# Cache view for 15 minutes
@cache_page(60 * 15)
def user_list(request):
    users = User.objects.all()
    return render(request, 'users.html', {'users': users})

# Manual caching
def user_detail(request, user_id):
    cache_key = f'user:{user_id}'
    
    user = cache.get(cache_key)
    if not user:
        user = User.objects.get(id=user_id)
        cache.set(cache_key, user, timeout=3600)
    
    return render(request, 'user.html', {'user': user})
```

---

## FastAPI Integration

### Dependency Injection

```python
from fastapi import FastAPI, Depends
from redis import Redis

app = FastAPI()

# Dependency
async def get_redis() -> Redis:
    redis = Redis(
        host='localhost',
        port=6379,
        decode_responses=True
    )
    try:
        yield redis
    finally:
        redis.close()

# Usage
@app.get("/users/{user_id}")
async def get_user(user_id: str, redis: Redis = Depends(get_redis)):
    cache_key = f"user:{user_id}"
    
    cached = redis.get(cache_key)
    if cached:
        return json.loads(cached)
    
    user = await db.users.find_one({'id': user_id})
    redis.setex(cache_key, 3600, json.dumps(user))
    
    return user
```

---

## Error Handling

### Resilient Cache Pattern

```typescript
class ResilientCache {
  constructor(private redis: Redis) {}

  async get<T>(key: string): Promise<T | null> {
    try {
      const value = await this.redis.get(key)
      if (!value) return null
      return JSON.parse(value) as T
    } catch (error) {
      console.error('Cache GET error:', error)
      return null // Fail gracefully
    }
  }

  async set<T>(key: string, value: T, ttl?: number): Promise<boolean> {
    try {
      const serialized = JSON.stringify(value)
      if (ttl) {
        await this.redis.setex(key, ttl, serialized)
      } else {
        await this.redis.set(key, serialized)
      }
      return true
    } catch (error) {
      console.error('Cache SET error:', error)
      return false // Don't fail request
    }
  }
}
```

### Circuit Breaker

```typescript
class CircuitBreaker {
  private failures = 0
  private lastFailure = 0
  private state: 'closed' | 'open' | 'half-open' = 'closed'

  constructor(
    private threshold: number = 5,
    private timeout: number = 60000
  ) {}

  async execute<T>(operation: () => Promise<T>): Promise<T | null> {
    if (this.state === 'open') {
      if (Date.now() - this.lastFailure > this.timeout) {
        this.state = 'half-open'
      } else {
        console.warn('Circuit breaker is open')
        return null
      }
    }

    try {
      const result = await operation()
      this.onSuccess()
      return result
    } catch (error) {
      this.onFailure()
      throw error
    }
  }

  private onSuccess() {
    this.failures = 0
    this.state = 'closed'
  }

  private onFailure() {
    this.failures++
    this.lastFailure = Date.now()

    if (this.failures >= this.threshold) {
      this.state = 'open'
      console.error('Circuit breaker opened')
    }
  }
}

// Usage
const circuitBreaker = new CircuitBreaker(5, 60000)

async function getCachedData(key: string) {
  return await circuitBreaker.execute(async () => {
    return await redis.get(key)
  })
}
```

---

## Testing

### Mock Redis for Tests

```typescript
import Redis from 'ioredis-mock'

describe('UserService', () => {
  let redis: Redis

  beforeEach(() => {
    redis = new Redis()
  })

  afterEach(async () => {
    await redis.flushall()
    await redis.quit()
  })

  it('should cache user data', async () => {
    const service = new UserService(redis)
    
    await service.getUser('1000')
    
    const cached = await redis.get('user:1000')
    expect(cached).toBeDefined()
  })
})
```

---

## Production Best Practices

### 1. Connection Pooling

```typescript
const redis = new Redis({
  host: 'localhost',
  maxRetriesPerRequest: 3,
  enableOfflineQueue: false,
  lazyConnect: true,
})
```

### 2. Health Checks

```typescript
async function checkRedisHealth(): Promise<boolean> {
  try {
    const pong = await redis.ping()
    return pong === 'PONG'
  } catch {
    return false
  }
}
```

### 3. Graceful Shutdown

```typescript
process.on('SIGTERM', async () => {
  console.log('SIGTERM received, closing Redis connection')
  await redis.quit()
  process.exit(0)
})
```

### 4. Monitoring

```typescript
redis.on('error', (err) => {
  logger.error('Redis error', { error: err })
  metrics.increment('redis.errors')
})

redis.on('reconnecting', () => {
  logger.warn('Redis reconnecting')
  metrics.increment('redis.reconnects')
})
```

---

## Next Steps

1. **Performance** → See [08-PERFORMANCE.md](./08-PERFORMANCE.md)
2. **Production** → See [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md)
3. **Clustering** → See [09-CLUSTERING.md](./09-CLUSTERING.md)

---

## AI Pair Programming Notes

**When to load this KB:**
- Integrating Redis with Node.js/Python
- Building production cache layers
- Framework-specific patterns
- Error handling and resilience

**Common starting points:**
- Node.js: See Node.js Integration
- Python: See Python Integration
- Express: See Express.js Integration
- Patterns: See Repository Pattern

**Typical questions:**
- "How do I integrate Redis with Node.js?" → Node.js Integration
- "How do I handle Redis errors?" → Error Handling
- "What's the best connection pattern?" → Connection Patterns
- "How do I test Redis code?" → Testing

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1
