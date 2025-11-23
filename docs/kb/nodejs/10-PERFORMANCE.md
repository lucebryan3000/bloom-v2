# Node.js Performance Optimization

```yaml
id: nodejs_10_performance
topic: Node.js
file_role: Performance optimization, profiling, clustering, caching, monitoring
profile: full
difficulty_level: advanced
kb_version: v3.1
prerequisites:
  - Fundamentals (01-FUNDAMENTALS.md)
  - Event Loop (03-EVENT-LOOP.md)
  - Async Programming (02-ASYNC-PROGRAMMING.md)
related_topics:
  - Streams (07-STREAMS-BUFFERS.md)
  - Best Practices (11-BEST-PRACTICES.md)
embedding_keywords:
  - nodejs performance
  - optimization
  - profiling
  - clustering
  - caching
  - memory management
  - cpu profiling
last_reviewed: 2025-11-17
```

## Performance Overview

**Key optimization areas:**

1. **Event loop** - Don't block it
2. **Memory** - Manage allocations
3. **CPU** - Optimize hot paths
4. **I/O** - Use async, streams, caching
5. **Clustering** - Use all CPU cores

## Event Loop Optimization

### Don't Block the Event Loop

```javascript
// ❌ BAD - Blocks event loop
function blockingSort(array) {
  return array.sort((a, b) => {
    // Expensive comparison
    for (let i = 0; i < 1000000; i++) {}
    return a - b;
  });
}

// ✅ GOOD - Break up work with setImmediate
function nonBlockingSort(array, callback) {
  const chunks = [];
  for (let i = 0; i < array.length; i += 1000) {
    chunks.push(array.slice(i, i + 1000));
  }

  let sorted = [];

  function processChunk() {
    if (chunks.length === 0) {
      return callback(sorted);
    }

    const chunk = chunks.shift();
    sorted = sorted.concat(chunk.sort((a, b) => a - b));

    setImmediate(processChunk);
  }

  processChunk();
}

// ✅ BETTER - Use worker threads for CPU-intensive work
import { Worker } from 'worker_threads';

function sortInWorker(array) {
  return new Promise((resolve, reject) => {
    const worker = new Worker('./sort-worker.js');

    worker.on('message', resolve);
    worker.on('error', reject);
    worker.postMessage(array);
  });
}
```

### Avoid Synchronous Operations

```javascript
// ❌ BAD - Synchronous I/O
const fs = require('fs');
const data = fs.readFileSync('large-file.txt'); // Blocks!

// ✅ GOOD - Async I/O
const data = await fs.promises.readFile('large-file.txt');

// ❌ BAD - Synchronous crypto
const hash = crypto.createHash('sha256').update(data).digest('hex');

// ✅ GOOD - Async crypto
const hash = await new Promise((resolve) => {
  const hasher = crypto.createHash('sha256');
  hasher.update(data);
  resolve(hasher.digest('hex'));
});
```

## Memory Management

### Memory Leaks

```javascript
// ❌ BAD - Memory leak (global array grows forever)
const globalCache = [];

function addToCache(data) {
  globalCache.push(data); // Never removed!
}

// ✅ GOOD - Bounded cache with LRU
class LRUCache {
  constructor(maxSize = 100) {
    this.maxSize = maxSize;
    this.cache = new Map();
  }

  get(key) {
    if (!this.cache.has(key)) return null;

    const value = this.cache.get(key);
    // Move to end (most recently used)
    this.cache.delete(key);
    this.cache.set(key, value);
    return value;
  }

  set(key, value) {
    if (this.cache.has(key)) {
      this.cache.delete(key);
    }

    this.cache.set(key, value);

    if (this.cache.size > this.maxSize) {
      // Remove least recently used (first item)
      const firstKey = this.cache.keys().next().value;
      this.cache.delete(firstKey);
    }
  }
}
```

### Memory Profiling

```bash
# Start with --inspect
node --inspect app.js

# Heap snapshot
node --inspect --heap-prof app.js

# Track allocations
node --trace-gc app.js
```

```javascript
// Monitor memory usage
setInterval(() => {
  const usage = process.memoryUsage();
  console.log({
    rss: `${Math.round(usage.rss / 1024 / 1024)}MB`, // Total memory
    heapTotal: `${Math.round(usage.heapTotal / 1024 / 1024)}MB`,
    heapUsed: `${Math.round(usage.heapUsed / 1024 / 1024)}MB`,
    external: `${Math.round(usage.external / 1024 / 1024)}MB`,
  });
}, 5000);
```

### Garbage Collection Tuning

```bash
# Increase max old space size (default 512MB on 32-bit, 1GB on 64-bit)
node --max-old-space-size=4096 app.js

# Expose GC to code
node --expose-gc app.js

# Manual GC (only when --expose-gc is set)
if (global.gc) {
  global.gc();
}
```

## CPU Profiling

### Built-in Profiler

```bash
# CPU profiling
node --prof app.js

# Process profile output
node --prof-process isolate-*.log > profile.txt
```

### Chrome DevTools Profiling

```bash
# Start with inspect
node --inspect app.js

# Open Chrome DevTools
# chrome://inspect
# Click "Open dedicated DevTools for Node"
# Go to Profiler tab
```

### Identifying Hot Paths

```javascript
// Use console.time for quick profiling
console.time('operation');
expensiveOperation();
console.timeEnd('operation'); // operation: 123.456ms

// Performance hooks for detailed timing
import { performance, PerformanceObserver } from 'node:perf_hooks';

const obs = new PerformanceObserver((items) => {
  console.log(items.getEntries()[0].duration);
  performance.clearMarks();
});
obs.observe({ entryTypes: ['measure'] });

performance.mark('start');
// ... code ...
performance.mark('end');
performance.measure('operation', 'start', 'end');
```

## Clustering

### Cluster Module

```javascript
import cluster from 'node:cluster';
import http from 'node:http';
import os from 'node:os';

const numCPUs = os.cpus().length;

if (cluster.isPrimary) {
  console.log(`Primary ${process.pid} is running`);

  // Fork workers
  for (let i = 0; i < numCPUs; i++) {
    cluster.fork();
  }

  cluster.on('exit', (worker, code, signal) => {
    console.log(`Worker ${worker.process.pid} died`);
    // Replace dead worker
    cluster.fork();
  });
} else {
  // Workers share TCP connection
  http.createServer((req, res) => {
    res.writeHead(200);
    res.end('Hello World\n');
  }).listen(8000);

  console.log(`Worker ${process.pid} started`);
}
```

### Worker Threads

```javascript
// main.js
import { Worker } from 'worker_threads';

function runWorker(data) {
  return new Promise((resolve, reject) => {
    const worker = new Worker('./worker.js', {
      workerData: data,
    });

    worker.on('message', resolve);
    worker.on('error', reject);
    worker.on('exit', (code) => {
      if (code !== 0) {
        reject(new Error(`Worker stopped with code ${code}`));
      }
    });
  });
}

// Process data in parallel
const results = await Promise.all([
  runWorker({ id: 1, data: 'chunk1' }),
  runWorker({ id: 2, data: 'chunk2' }),
  runWorker({ id: 3, data: 'chunk3' }),
]);

// worker.js
import { parentPort, workerData } from 'worker_threads';

// CPU-intensive work
const result = processData(workerData);

parentPort.postMessage(result);
```

## Caching Strategies

### In-Memory Cache

```javascript
// Simple cache
const cache = new Map();

function getUser(id) {
  if (cache.has(id)) {
    return cache.get(id);
  }

  const user = fetchUserFromDB(id);
  cache.set(id, user);
  return user;
}

// Cache with TTL
class TTLCache {
  constructor(ttl = 60000) {
    this.ttl = ttl;
    this.cache = new Map();
  }

  get(key) {
    const item = this.cache.get(key);
    if (!item) return null;

    if (Date.now() > item.expiry) {
      this.cache.delete(key);
      return null;
    }

    return item.value;
  }

  set(key, value) {
    this.cache.set(key, {
      value,
      expiry: Date.now() + this.ttl,
    });
  }

  clear() {
    this.cache.clear();
  }
}
```

### Redis Caching

```javascript
import { createClient } from 'redis';

const redis = createClient();
await redis.connect();

// Cache with Redis
async function getUser(id) {
  const cached = await redis.get(`user:${id}`);
  if (cached) {
    return JSON.parse(cached);
  }

  const user = await fetchUserFromDB(id);

  // Cache for 1 hour
  await redis.setEx(`user:${id}`, 3600, JSON.stringify(user));

  return user;
}

// Invalidate cache
async function updateUser(id, data) {
  await updateUserInDB(id, data);
  await redis.del(`user:${id}`); // Invalidate cache
}
```

## Database Optimization

### Connection Pooling

```javascript
import { Pool } from 'pg';

// ✅ GOOD - Connection pool
const pool = new Pool({
  host: 'localhost',
  database: 'mydb',
  max: 20, // Max connections
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

async function query(sql, params) {
  const client = await pool.connect();
  try {
    return await client.query(sql, params);
  } finally {
    client.release(); // Return to pool
  }
}

// ❌ BAD - New connection every time
async function badQuery(sql) {
  const client = new Client();
  await client.connect();
  const result = await client.query(sql);
  await client.end(); // Expensive!
  return result;
}
```

### Query Optimization

```javascript
// ✅ GOOD - Use indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_posts_user_id ON posts(user_id);

// ✅ GOOD - Batch queries
const userIds = [1, 2, 3, 4, 5];
const users = await db.query(
  'SELECT * FROM users WHERE id = ANY($1)',
  [userIds]
);

// ❌ BAD - N+1 queries
for (const id of userIds) {
  const user = await db.query('SELECT * FROM users WHERE id = $1', [id]);
}

// ✅ GOOD - Use prepared statements
const stmt = await client.prepare('SELECT * FROM users WHERE id = $1');
const user = await stmt.execute([userId]);
```

## HTTP Performance

### HTTP Keep-Alive

```javascript
import http from 'node:http';

const agent = new http.Agent({
  keepAlive: true,
  maxSockets: 50,
});

// Reuse connections
fetch('http://example.com/api', { agent });
```

### Compression

```javascript
import { createGzip } from 'node:zlib';
import { pipeline } from 'node:stream/promises';

// Compress responses
const server = http.createServer(async (req, res) => {
  const acceptEncoding = req.headers['accept-encoding'] || '';

  if (acceptEncoding.includes('gzip')) {
    res.writeHead(200, {
      'Content-Type': 'text/plain',
      'Content-Encoding': 'gzip',
    });

    const gzip = createGzip();
    await pipeline(
      Readable.from(['Hello World']),
      gzip,
      res
    );
  } else {
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    res.end('Hello World');
  }
});
```

### Response Caching

```javascript
// ETag caching
const etag = crypto.createHash('md5').update(data).digest('hex');

if (req.headers['if-none-match'] === etag) {
  res.writeHead(304); // Not Modified
  res.end();
  return;
}

res.writeHead(200, {
  'Content-Type': 'application/json',
  'ETag': etag,
  'Cache-Control': 'public, max-age=3600',
});
res.end(data);
```

## Monitoring

### Performance Metrics

```javascript
import { performance } from 'node:perf_hooks';

class PerformanceMonitor {
  constructor() {
    this.metrics = new Map();
  }

  start(name) {
    performance.mark(`${name}-start`);
  }

  end(name) {
    performance.mark(`${name}-end`);
    performance.measure(name, `${name}-start`, `${name}-end`);

    const measure = performance.getEntriesByName(name)[0];
    this.recordMetric(name, measure.duration);

    performance.clearMarks(`${name}-start`);
    performance.clearMarks(`${name}-end`);
    performance.clearMeasures(name);
  }

  recordMetric(name, duration) {
    if (!this.metrics.has(name)) {
      this.metrics.set(name, []);
    }
    this.metrics.get(name).push(duration);
  }

  getStats(name) {
    const values = this.metrics.get(name) || [];
    if (values.length === 0) return null;

    const sorted = values.sort((a, b) => a - b);
    return {
      count: values.length,
      min: sorted[0],
      max: sorted[sorted.length - 1],
      avg: values.reduce((a, b) => a + b, 0) / values.length,
      p50: sorted[Math.floor(sorted.length * 0.5)],
      p95: sorted[Math.floor(sorted.length * 0.95)],
      p99: sorted[Math.floor(sorted.length * 0.99)],
    };
  }
}

// Usage
const monitor = new PerformanceMonitor();

monitor.start('db-query');
await db.query('SELECT * FROM users');
monitor.end('db-query');

console.log(monitor.getStats('db-query'));
```

## AI Pair Programming Notes

**When optimizing performance:**

1. **Measure first** - Profile before optimizing
2. **Don't block event loop** - Use async operations
3. **Use clustering** - Utilize all CPU cores
4. **Cache aggressively** - Reduce DB queries
5. **Use connection pools** - Don't create connections repeatedly
6. **Stream large data** - Don't load into memory
7. **Compress responses** - Reduce network transfer
8. **Use worker threads** for CPU work
9. **Monitor in production** - Track metrics
10. **Optimize hot paths** - Focus on frequently executed code

**Common performance mistakes:**
- Optimizing before measuring (premature optimization)
- Blocking event loop with CPU-intensive work
- Not using connection pooling
- Loading large files into memory
- N+1 database queries
- Not caching repeated computations
- Creating too many objects/closures
- Not using indexes on database queries
- Synchronous I/O in production
- Not compressing HTTP responses

## Next Steps

1. **11-BEST-PRACTICES.md** - Production best practices
2. **03-EVENT-LOOP.md** - Event loop deep dive
3. **07-STREAMS-BUFFERS.md** - Stream performance

## Additional Resources

- Node.js Performance: https://nodejs.org/en/docs/guides/simple-profiling/
- Clinic.js: https://clinicjs.org/
- Chrome DevTools: https://developers.google.com/web/tools/chrome-devtools
- Performance Timing API: https://nodejs.org/api/perf_hooks.html
- Worker Threads: https://nodejs.org/api/worker_threads.html
