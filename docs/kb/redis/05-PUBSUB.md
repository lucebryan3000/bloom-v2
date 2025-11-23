---
id: redis-pubsub
topic: redis
file_role: guide
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [redis-fundamentals, redis-basic-operations]
related_topics: [messaging, real-time, event-driven, channels]
embedding_keywords: [redis, pubsub, publish, subscribe, channels, messaging, real-time]
last_reviewed: 2025-11-16
---

# Redis - Pub/Sub Messaging

Comprehensive guide to Redis Publish/Subscribe messaging for real-time communication and event-driven architectures.

## Overview

Redis Pub/Sub provides a message broker pattern for real-time communication between publishers and subscribers through named channels.

---

## Basic Pub/Sub

### PUBLISH - Send Message

```bash
# Publish message to channel
PUBLISH news "Breaking: Redis 7.2 released!"
# Output: 2 (number of subscribers that received the message)

# Publish to channel with no subscribers
PUBLISH empty-channel "Hello"
# Output: 0
```

**Node.js Publisher:**
```javascript
import Redis from 'ioredis'

const publisher = new Redis()

// Publish message
await publisher.publish('notifications', JSON.stringify({
  type: 'NEW_MESSAGE',
  userId: '1000',
  message: 'Hello!'
}))

// Returns number of subscribers
const subscriberCount = await publisher.publish('news', 'Latest update')
console.log(`Delivered to ${subscriberCount} subscribers`)
```

### SUBSCRIBE - Receive Messages

```bash
# Subscribe to one or more channels
SUBSCRIBE news weather sports

# Output when message arrives:
# 1) "message"
# 2) "news" (channel name)
# 3) "Breaking: Redis 7.2 released!" (message)
```

**Node.js Subscriber:**
```javascript
import Redis from 'ioredis'

const subscriber = new Redis()

// Subscribe to channels
await subscriber.subscribe('notifications', 'alerts')

// Handle messages
subscriber.on('message', (channel, message) => {
  console.log(`[${channel}] ${message}`)

  const data = JSON.parse(message)
  handleNotification(data)
})

// Handle subscription confirmations
subscriber.on('subscribe', (channel, count) => {
  console.log(`Subscribed to ${channel} (${count} total subscriptions)`)
})
```

### UNSUBSCRIBE - Stop Receiving

```bash
# Unsubscribe from specific channels
UNSUBSCRIBE news weather

# Unsubscribe from all channels
UNSUBSCRIBE
```

**Node.js:**
```javascript
// Unsubscribe from specific channels
await subscriber.unsubscribe('notifications')

// Unsubscribe from all
await subscriber.unsubscribe()
```

---

## Pattern Matching

### PSUBSCRIBE - Pattern Subscribe

```bash
# Subscribe to pattern (glob-style)
PSUBSCRIBE user:*

# Matches:
# - user:1000
# - user:2000
# - user:alice

# Multiple patterns
PSUBSCRIBE user:* order:* article:*
```

**Node.js Pattern Subscriber:**
```javascript
const subscriber = new Redis()

// Subscribe to pattern
await subscriber.psubscribe('user:*', 'order:*')

// Handle pattern messages
subscriber.on('pmessage', (pattern, channel, message) => {
  console.log(`Pattern: ${pattern}, Channel: ${channel}, Message: ${message}`)

  if (pattern === 'user:*') {
    const userId = channel.split(':')[1]
    handleUserEvent(userId, message)
  }
})
```

### PUNSUBSCRIBE - Pattern Unsubscribe

```bash
# Unsubscribe from patterns
PUNSUBSCRIBE user:*

# Unsubscribe from all patterns
PUNSUBSCRIBE
```

---

## Pub/Sub Commands

### PUBSUB CHANNELS - List Active Channels

```bash
# List all active channels
PUBSUB CHANNELS

# List channels matching pattern
PUBSUB CHANNELS user:*
```

### PUBSUB NUMSUB - Count Subscribers

```bash
# Count subscribers for specific channels
PUBSUB NUMSUB news weather sports
# Output: 1) "news" 2) "5" 3) "weather" 4) "3" 5) "sports" 6) "10"
```

### PUBSUB NUMPAT - Count Pattern Subscriptions

```bash
# Count pattern subscriptions
PUBSUB NUMPAT
# Output: 3 (total number of pattern subscriptions across all clients)
```

---

## Patterns & Use Cases

### Real-Time Notifications

**Publisher (API Server):**
```javascript
class NotificationService {
  constructor(redis) {
    this.redis = redis
  }

  async sendUserNotification(userId, notification) {
    const channel = `user:${userId}:notifications`
    const message = JSON.stringify(notification)

    const subscriberCount = await this.redis.publish(channel, message)

    // Log if user is online
    if (subscriberCount > 0) {
      console.log(`Notified user ${userId} (${subscriberCount} connections)`)
    }

    return subscriberCount
  }

  async broadcastNotification(notification) {
    const channel = 'notifications:global'
    const message = JSON.stringify(notification)

    return await this.redis.publish(channel, message)
  }
}

// Usage
const notificationService = new NotificationService(redis)

await notificationService.sendUserNotification('1000', {
  type: 'NEW_MESSAGE',
  from: 'Alice',
  message: 'Hello!',
  timestamp: Date.now()
})
```

**Subscriber (WebSocket Server):**
```javascript
import WebSocket from 'ws'
import Redis from 'ioredis'

const wss = new WebSocket.Server({ port: 8080 })
const subscriber = new Redis()

// Track user connections
const userConnections = new Map() // userId -> Set<WebSocket>

wss.on('connection', (ws, req) => {
  const userId = extractUserIdFromRequest(req)

  // Add to connection map
  if (!userConnections.has(userId)) {
    userConnections.set(userId, new Set())
  }
  userConnections.get(userId).add(ws)

  // Subscribe to user's channel
  const channel = `user:${userId}:notifications`
  subscriber.subscribe(channel)

  ws.on('close', () => {
    const connections = userConnections.get(userId)
    connections.delete(ws)

    // Unsubscribe if last connection
    if (connections.size === 0) {
      subscriber.unsubscribe(channel)
      userConnections.delete(userId)
    }
  })
})

// Forward Redis messages to WebSocket clients
subscriber.on('message', (channel, message) => {
  const userId = channel.split(':')[1]
  const connections = userConnections.get(userId)

  if (connections) {
    for (const ws of connections) {
      if (ws.readyState === WebSocket.OPEN) {
        ws.send(message)
      }
    }
  }
})
```

### Chat Application

```javascript
class ChatRoom {
  constructor(redis) {
    this.publisher = redis.duplicate()
    this.subscriber = redis.duplicate()
  }

  async joinRoom(roomId, userId, onMessage) {
    const channel = `chat:room:${roomId}`

    // Subscribe to room
    await this.subscriber.subscribe(channel)

    // Handle messages
    this.subscriber.on('message', (ch, msg) => {
      if (ch === channel) {
        const data = JSON.parse(msg)
        onMessage(data)
      }
    })

    // Announce join
    await this.sendMessage(roomId, {
      type: 'USER_JOINED',
      userId,
      timestamp: Date.now()
    })
  }

  async sendMessage(roomId, message) {
    const channel = `chat:room:${roomId}`
    await this.publisher.publish(channel, JSON.stringify(message))
  }

  async leaveRoom(roomId, userId) {
    const channel = `chat:room:${roomId}`

    // Announce leave
    await this.sendMessage(roomId, {
      type: 'USER_LEFT',
      userId,
      timestamp: Date.now()
    })

    // Unsubscribe
    await this.subscriber.unsubscribe(channel)
  }
}

// Usage
const chat = new ChatRoom(redis)

await chat.joinRoom('room123', 'user1000', (message) => {
  console.log(`[Room123] ${message.type}:`, message)
})

await chat.sendMessage('room123', {
  type: 'CHAT_MESSAGE',
  userId: 'user1000',
  text: 'Hello everyone!',
  timestamp: Date.now()
})
```

### Event Broadcasting

```javascript
class EventBus {
  constructor(redis) {
    this.publisher = redis.duplicate()
    this.subscriber = redis.duplicate()
    this.handlers = new Map()
  }

  async emit(event, data) {
    const channel = `events:${event}`
    const message = JSON.stringify({
      event,
      data,
      timestamp: Date.now()
    })

    return await this.publisher.publish(channel, message)
  }

  async on(event, handler) {
    const channel = `events:${event}`

    // Subscribe if first handler for this event
    if (!this.handlers.has(event)) {
      await this.subscriber.subscribe(channel)
      this.handlers.set(event, [])
    }

    this.handlers.get(event).push(handler)
  }

  async off(event, handler) {
    const handlers = this.handlers.get(event) || []
    const index = handlers.indexOf(handler)

    if (index > -1) {
      handlers.splice(index, 1)
    }

    // Unsubscribe if no more handlers
    if (handlers.length === 0) {
      await this.subscriber.unsubscribe(`events:${event}`)
      this.handlers.delete(event)
    }
  }

  // Handle incoming messages
  start() {
    this.subscriber.on('message', (channel, message) => {
      const event = channel.replace('events:', '')
      const handlers = this.handlers.get(event) || []

      const data = JSON.parse(message)

      for (const handler of handlers) {
        try {
          handler(data.data, data.timestamp)
        } catch (error) {
          console.error(`Event handler error:`, error)
        }
      }
    })
  }
}

// Usage
const eventBus = new EventBus(redis)
eventBus.start()

// Subscribe to events
await eventBus.on('user.created', (userData, timestamp) => {
  console.log('New user created:', userData)
  sendWelcomeEmail(userData.email)
})

await eventBus.on('order.placed', (orderData, timestamp) => {
  console.log('New order:', orderData)
  processOrder(orderData)
})

// Emit events
await eventBus.emit('user.created', {
  userId: '1000',
  email: 'alice@example.com'
})

await eventBus.emit('order.placed', {
  orderId: '5432',
  userId: '1000',
  total: 99.99
})
```

### Cache Invalidation

```javascript
class CacheInvalidator {
  constructor(redis) {
    this.cache = redis.duplicate()
    this.subscriber = redis.duplicate()
  }

  async start() {
    // Subscribe to invalidation events
    await this.subscriber.subscribe('cache:invalidate')

    this.subscriber.on('message', async (channel, message) => {
      if (channel === 'cache:invalidate') {
        const { pattern, keys } = JSON.parse(message)

        if (pattern) {
          await this.invalidatePattern(pattern)
        }

        if (keys && keys.length > 0) {
          await this.invalidateKeys(keys)
        }
      }
    })
  }

  async invalidateKeys(keys) {
    if (keys.length > 0) {
      await this.cache.del(...keys)
      console.log(`Invalidated ${keys.length} cache keys`)
    }
  }

  async invalidatePattern(pattern) {
    let cursor = '0'
    let total = 0

    do {
      const [newCursor, keys] = await this.cache.scan(cursor, 'MATCH', pattern)
      cursor = newCursor

      if (keys.length > 0) {
        await this.cache.del(...keys)
        total += keys.length
      }
    } while (cursor !== '0')

    console.log(`Invalidated ${total} keys matching ${pattern}`)
  }
}

// On cache-invalidator instances
const invalidator = new CacheInvalidator(redis)
await invalidator.start()

// On API servers (publishers)
class CacheManager {
  constructor(redis) {
    this.redis = redis
  }

  async invalidate(options) {
    await this.redis.publish('cache:invalidate', JSON.stringify(options))
  }
}

const cacheManager = new CacheManager(redis)

// Invalidate specific keys
await cacheManager.invalidate({
  keys: ['user:1000', 'user:1000:profile']
})

// Invalidate pattern
await cacheManager.invalidate({
  pattern: 'user:1000:*'
})
```

---

## Pub/Sub vs Streams

### When to Use Pub/Sub

**✅ Use Pub/Sub when:**
- Messages can be lost (fire-and-forget)
- Real-time delivery is critical
- No message history needed
- Subscribers are always online
- Simple broadcast pattern
- Low latency required

**Examples:**
- Live notifications
- Real-time dashboards
- Chat applications
- System monitoring alerts

### When to Use Streams

**✅ Use Streams when:**
- Message history required
- Guaranteed delivery needed
- Consumer groups needed
- Offline consumers
- Message replay required
- Message persistence important

**Examples:**
- Event sourcing
- Job queues
- Audit logs
- Data pipelines

---

## Reliability Considerations

### Message Delivery

**⚠️ Important**: Redis Pub/Sub is **fire-and-forget**:
- Messages not delivered if no subscribers
- Messages lost if subscriber disconnects
- No message persistence
- No acknowledgments

```javascript
// ❌ WRONG - Assuming reliable delivery
await redis.publish('critical:events', JSON.stringify(criticalData))
// If no subscribers, message is lost!

// ✅ CORRECT - Ensure subscribers or use Streams for critical data
const subscriberCount = await redis.publish('critical:events', JSON.stringify(criticalData))

if (subscriberCount === 0) {
  console.warn('No subscribers - message not delivered')
  // Fallback: Store in database or Stream
  await redis.xadd('critical:events:stream', '*', 'data', JSON.stringify(criticalData))
}
```

### Connection Handling

```javascript
const subscriber = new Redis({
  retryStrategy: (times) => {
    const delay = Math.min(times * 50, 2000)
    console.log(`Reconnecting in ${delay}ms...`)
    return delay
  }
})

// Resubscribe on reconnect
subscriber.on('ready', async () => {
  console.log('Redis ready - resubscribing to channels')
  await subscriber.subscribe('notifications', 'alerts')
})

// Handle connection errors
subscriber.on('error', (error) => {
  console.error('Redis subscriber error:', error)
})

// Handle unexpected close
subscriber.on('close', () => {
  console.log('Redis subscriber connection closed')
})
```

### Message Ordering

**Within a channel**: Messages are delivered in order published
**Across channels**: No ordering guarantees

```javascript
// ✅ Ordered within channel
await redis.publish('events', 'event1')
await redis.publish('events', 'event2')
await redis.publish('events', 'event3')
// Subscribers receive: event1 → event2 → event3

// ❌ No order guarantee across channels
await redis.publish('channel1', 'msg1')
await redis.publish('channel2', 'msg2')
await redis.publish('channel1', 'msg3')
// No guarantee which channel's message arrives first
```

---

## Performance Characteristics

### Pub/Sub Performance

- **Throughput**: 100k+ messages/sec on modern hardware
- **Latency**: Sub-millisecond within same datacenter
- **Overhead**: Minimal CPU/memory per channel
- **Scalability**: Horizontal scaling via multiple Redis instances

**Benchmark:**
```bash
# Publish 100k messages
redis-benchmark -t publish -n 100000

# Sample output:
# PUBLISH: 120,000 requests per second
```

### Best Practices

**1. Limit Subscriber Count per Channel**
```javascript
// ❌ Don't subscribe 10,000 clients to same channel
// ✅ Use multiple channels or pattern matching
const userId = '1000'
await subscriber.subscribe(`user:${userId}:notifications`)
```

**2. Keep Messages Small**
```javascript
// ❌ Large message
await redis.publish('channel', JSON.stringify(largeObject)) // 100KB+

// ✅ Reference to data
await redis.publish('channel', JSON.stringify({ 
  type: 'NEW_DATA', 
  id: '12345' 
}))
// Subscriber fetches details via GET
```

**3. Use Dedicated Redis Instance for Pub/Sub**
```javascript
// Separate Pub/Sub from cache/data
const cacheRedis = new Redis({ db: 0 })
const pubsubRedis = new Redis({ db: 1 })
```

---

## Next Steps

After mastering Pub/Sub, explore:

1. **Transactions** → See `06-TRANSACTIONS.md` for atomic operations
2. **Streams** → See `03-DATA-STRUCTURES.md` for persistent messaging
3. **Clustering** → See `09-CLUSTERING.md` for distributed Pub/Sub
4. **Performance** → See `08-PERFORMANCE.md` for optimization
5. **Production** → See `11-CONFIG-OPERATIONS.md` for deployment

---

## AI Pair Programming Notes

**When to load this KB:**
- Building real-time features
- Implementing event-driven architecture
- Creating notification systems
- Building chat applications

**Common starting points:**
- Basic Pub/Sub: See Basic Pub/Sub section
- Real-time notifications: See Real-Time Notifications pattern
- Chat: See Chat Application pattern
- Events: See Event Broadcasting pattern

**Typical questions:**
- "How do I send real-time notifications?" → Real-Time Notifications
- "How do I build a chat system?" → Chat Application
- "Is Pub/Sub reliable?" → Reliability Considerations
- "When should I use Streams instead?" → Pub/Sub vs Streams

**Related topics:**
- Streams: See `03-DATA-STRUCTURES.md`
- Patterns: See `04-CACHING-STRATEGIES.md`
- Performance: See `08-PERFORMANCE.md`

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1
