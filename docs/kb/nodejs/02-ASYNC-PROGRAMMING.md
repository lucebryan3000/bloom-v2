# Node.js Async Programming

```yaml
id: nodejs_02_async_programming
topic: Node.js
file_role: Async programming patterns, promises, async/await, callbacks
profile: full
difficulty_level: intermediate
kb_version: v3.1
prerequisites:
  - Fundamentals (01-FUNDAMENTALS.md)
  - JavaScript async concepts
related_topics:
  - Event Loop (03-EVENT-LOOP.md)
  - Error Handling (08-ERROR-HANDLING.md)
embedding_keywords:
  - nodejs async await
  - promises
  - callbacks
  - asynchronous programming
  - async patterns
  - promise chains
last_reviewed: 2025-11-17
```

## Async Programming Overview

**Core Async Patterns:**
1. **Callbacks** - Traditional Node.js pattern
2. **Promises** - Modern async handling
3. **Async/Await** - Syntactic sugar over promises
4. **Event Emitters** - Event-driven async
5. **Streams** - Async data processing

## Callbacks (Legacy Pattern)

### Basic Callback Pattern

```javascript
// Classic Node.js callback pattern (error-first)
const fs = require('fs');

fs.readFile('/path/to/file.txt', 'utf8', (err, data) => {
  if (err) {
    console.error('Error reading file:', err);
    return;
  }
  console.log('File contents:', data);
});

// ✅ GOOD - Error-first callback
function fetchUser(id, callback) {
  setTimeout(() => {
    if (id < 0) {
      callback(new Error('Invalid user ID'), null);
    } else {
      callback(null, { id, name: 'Alice' });
    }
  }, 100);
}

fetchUser(1, (err, user) => {
  if (err) {
    console.error(err);
    return;
  }
  console.log(user);
});
```

### Callback Hell (Anti-Pattern)

```javascript
// ❌ BAD - Pyramid of doom
fs.readFile('file1.txt', 'utf8', (err, data1) => {
  if (err) return console.error(err);

  fs.readFile('file2.txt', 'utf8', (err, data2) => {
    if (err) return console.error(err);

    fs.readFile('file3.txt', 'utf8', (err, data3) => {
      if (err) return console.error(err);

      console.log(data1, data2, data3);
    });
  });
});

// ✅ GOOD - Promises or async/await instead
async function readMultipleFiles() {
  try {
    const [data1, data2, data3] = await Promise.all([
      fs.promises.readFile('file1.txt', 'utf8'),
      fs.promises.readFile('file2.txt', 'utf8'),
      fs.promises.readFile('file3.txt', 'utf8'),
    ]);
    console.log(data1, data2, data3);
  } catch (err) {
    console.error(err);
  }
}
```

## Promises

### Creating Promises

```javascript
// Basic promise creation
const delay = (ms) => {
  return new Promise((resolve, reject) => {
    if (ms < 0) {
      reject(new Error('Delay cannot be negative'));
    }
    setTimeout(() => resolve(`Waited ${ms}ms`), ms);
  });
};

// Using the promise
delay(1000)
  .then(result => console.log(result))
  .catch(err => console.error(err));

// Promise wrapper for callback-based functions
function promisifyReadFile(path) {
  return new Promise((resolve, reject) => {
    fs.readFile(path, 'utf8', (err, data) => {
      if (err) reject(err);
      else resolve(data);
    });
  });
}
```

### Promise Chaining

```javascript
// ✅ GOOD - Promise chain
fetch('https://api.example.com/users/1')
  .then(response => response.json())
  .then(user => fetch(`https://api.example.com/posts/${user.id}`))
  .then(response => response.json())
  .then(posts => console.log(posts))
  .catch(err => console.error('Error:', err))
  .finally(() => console.log('Request complete'));

// ✅ GOOD - Returning values in chain
function fetchUserPosts(userId) {
  return getUserById(userId)
    .then(user => {
      console.log('Found user:', user.name);
      return getPostsByUser(user.id); // Return promise
    })
    .then(posts => {
      console.log(`Found ${posts.length} posts`);
      return posts; // Return value
    });
}
```

### Promise Combinators

```javascript
// Promise.all() - Wait for all promises
const promises = [
  fetch('/api/users'),
  fetch('/api/posts'),
  fetch('/api/comments'),
];

Promise.all(promises)
  .then(responses => Promise.all(responses.map(r => r.json())))
  .then(([users, posts, comments]) => {
    console.log({ users, posts, comments });
  })
  .catch(err => {
    console.error('One or more requests failed:', err);
  });

// Promise.allSettled() - Wait for all, don't fail on rejection
Promise.allSettled(promises)
  .then(results => {
    results.forEach((result, index) => {
      if (result.status === 'fulfilled') {
        console.log(`Promise ${index} succeeded:`, result.value);
      } else {
        console.log(`Promise ${index} failed:`, result.reason);
      }
    });
  });

// Promise.race() - First to resolve/reject wins
const timeout = new Promise((_, reject) =>
  setTimeout(() => reject(new Error('Timeout')), 5000)
);

Promise.race([fetch('/api/data'), timeout])
  .then(response => response.json())
  .then(data => console.log(data))
  .catch(err => console.error('Request failed or timed out:', err));

// Promise.any() - First to fulfill wins (ignores rejections)
Promise.any([
  fetch('https://api1.example.com/data'),
  fetch('https://api2.example.com/data'),
  fetch('https://api3.example.com/data'),
])
  .then(response => response.json())
  .then(data => console.log('First successful response:', data))
  .catch(err => console.error('All requests failed:', err));
```

## Async/Await

### Basic Async Functions

```javascript
// ✅ GOOD - Async function always returns a promise
async function fetchUser(id) {
  const response = await fetch(`/api/users/${id}`);
  const user = await response.json();
  return user; // Automatically wrapped in Promise.resolve()
}

// Calling async functions
fetchUser(1)
  .then(user => console.log(user))
  .catch(err => console.error(err));

// Or with async/await
async function main() {
  try {
    const user = await fetchUser(1);
    console.log(user);
  } catch (err) {
    console.error(err);
  }
}
```

### Error Handling

```javascript
// ✅ GOOD - Try/catch for error handling
async function fetchUserSafely(id) {
  try {
    const response = await fetch(`/api/users/${id}`);

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const user = await response.json();
    return user;
  } catch (err) {
    console.error('Failed to fetch user:', err);
    throw err; // Re-throw or return default
  }
}

// ✅ GOOD - Handle specific errors
async function fetchWithRetry(url, retries = 3) {
  for (let i = 0; i < retries; i++) {
    try {
      const response = await fetch(url);
      return await response.json();
    } catch (err) {
      if (i === retries - 1) throw err; // Last attempt

      const delay = Math.pow(2, i) * 1000; // Exponential backoff
      console.log(`Retry ${i + 1} after ${delay}ms`);
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }
}
```

### Parallel vs Sequential Execution

```javascript
// ❌ BAD - Sequential (slow, 3 seconds total)
async function fetchSequential() {
  const user = await fetchUser(1);      // 1 second
  const posts = await fetchPosts(1);    // 1 second
  const comments = await fetchComments(1); // 1 second
  return { user, posts, comments };
}

// ✅ GOOD - Parallel (fast, ~1 second total)
async function fetchParallel() {
  const [user, posts, comments] = await Promise.all([
    fetchUser(1),
    fetchPosts(1),
    fetchComments(1),
  ]);
  return { user, posts, comments };
}

// ✅ GOOD - Parallel with individual error handling
async function fetchParallelSafe() {
  const results = await Promise.allSettled([
    fetchUser(1),
    fetchPosts(1),
    fetchComments(1),
  ]);

  return {
    user: results[0].status === 'fulfilled' ? results[0].value : null,
    posts: results[1].status === 'fulfilled' ? results[1].value : [],
    comments: results[2].status === 'fulfilled' ? results[2].value : [],
  };
}
```

### Async Iteration

```javascript
// ✅ GOOD - for await...of for async iterables
async function processFiles(filePaths) {
  for await (const filePath of filePaths) {
    const content = await fs.promises.readFile(filePath, 'utf8');
    console.log(`File: ${filePath}, Size: ${content.length}`);
  }
}

// Async generator
async function* fetchPages(url, maxPages = 10) {
  for (let page = 1; page <= maxPages; page++) {
    const response = await fetch(`${url}?page=${page}`);
    const data = await response.json();

    if (data.length === 0) break;

    yield data;
  }
}

// Usage
async function processPaginatedData() {
  for await (const pageData of fetchPages('/api/items')) {
    console.log(`Processing page with ${pageData.length} items`);
    // Process items...
  }
}
```

## Advanced Patterns

### Promise Promisification

```javascript
// Util.promisify from Node.js
const util = require('util');
const fs = require('fs');

// Convert callback-based function to promise
const readFilePromise = util.promisify(fs.readFile);

async function readConfig() {
  try {
    const data = await readFilePromise('config.json', 'utf8');
    return JSON.parse(data);
  } catch (err) {
    console.error('Failed to read config:', err);
    return {};
  }
}

// Manual promisification
function promisify(fn) {
  return function(...args) {
    return new Promise((resolve, reject) => {
      fn(...args, (err, result) => {
        if (err) reject(err);
        else resolve(result);
      });
    });
  };
}

const readFileAsync = promisify(fs.readFile);
```

### Async Queue/Batch Processing

```javascript
// ✅ GOOD - Process items in batches
async function processBatch(items, batchSize = 5) {
  const results = [];

  for (let i = 0; i < items.length; i += batchSize) {
    const batch = items.slice(i, i + batchSize);
    const batchResults = await Promise.all(
      batch.map(item => processItem(item))
    );
    results.push(...batchResults);

    console.log(`Processed ${i + batch.length}/${items.length} items`);
  }

  return results;
}

// Limit concurrency with a pool
class AsyncPool {
  constructor(limit) {
    this.limit = limit;
    this.running = 0;
    this.queue = [];
  }

  async run(fn) {
    while (this.running >= this.limit) {
      await Promise.race(this.queue);
    }

    this.running++;
    const promise = fn().finally(() => {
      this.running--;
      const index = this.queue.indexOf(promise);
      if (index !== -1) this.queue.splice(index, 1);
    });

    this.queue.push(promise);
    return promise;
  }
}

// Usage
const pool = new AsyncPool(3); // Max 3 concurrent operations

async function processFiles(files) {
  const promises = files.map(file =>
    pool.run(() => processFile(file))
  );
  return Promise.all(promises);
}
```

### Timeouts and Cancellation

```javascript
// Add timeout to async operation
function withTimeout(promise, ms) {
  const timeout = new Promise((_, reject) =>
    setTimeout(() => reject(new Error('Operation timed out')), ms)
  );
  return Promise.race([promise, timeout]);
}

// Usage
async function fetchWithTimeout(url, ms = 5000) {
  try {
    const response = await withTimeout(fetch(url), ms);
    return await response.json();
  } catch (err) {
    if (err.message === 'Operation timed out') {
      console.error('Request timed out');
    }
    throw err;
  }
}

// AbortController for cancellation
async function fetchCancellable(url) {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 5000);

  try {
    const response = await fetch(url, { signal: controller.signal });
    clearTimeout(timeoutId);
    return await response.json();
  } catch (err) {
    if (err.name === 'AbortError') {
      console.error('Request was cancelled');
    }
    throw err;
  }
}
```

## Common Async Patterns

### Retry Logic

```javascript
async function retry(fn, options = {}) {
  const {
    retries = 3,
    delay = 1000,
    backoff = 2,
    onRetry = () => {},
  } = options;

  let lastError;

  for (let i = 0; i < retries; i++) {
    try {
      return await fn();
    } catch (err) {
      lastError = err;

      if (i < retries - 1) {
        const waitTime = delay * Math.pow(backoff, i);
        onRetry(err, i + 1, waitTime);
        await new Promise(resolve => setTimeout(resolve, waitTime));
      }
    }
  }

  throw lastError;
}

// Usage
const data = await retry(
  () => fetch('/api/data').then(r => r.json()),
  {
    retries: 3,
    delay: 1000,
    backoff: 2,
    onRetry: (err, attempt, delay) => {
      console.log(`Retry ${attempt} after ${delay}ms. Error: ${err.message}`);
    },
  }
);
```

### Debounce and Throttle

```javascript
// Debounce async function
function debounce(fn, delay) {
  let timeoutId;

  return function(...args) {
    clearTimeout(timeoutId);

    return new Promise((resolve, reject) => {
      timeoutId = setTimeout(async () => {
        try {
          const result = await fn.apply(this, args);
          resolve(result);
        } catch (err) {
          reject(err);
        }
      }, delay);
    });
  };
}

// Usage
const debouncedSearch = debounce(async (query) => {
  const response = await fetch(`/api/search?q=${query}`);
  return response.json();
}, 300);

// Throttle async function
function throttle(fn, limit) {
  let inThrottle;

  return async function(...args) {
    if (!inThrottle) {
      inThrottle = true;

      try {
        return await fn.apply(this, args);
      } finally {
        setTimeout(() => inThrottle = false, limit);
      }
    }
  };
}
```

## AI Pair Programming Notes

**When writing async code:**

1. **Prefer async/await** over raw promises for readability
2. **Always handle errors** with try/catch or .catch()
3. **Use Promise.all()** for parallel execution when possible
4. **Avoid blocking** the event loop with synchronous operations
5. **Add timeouts** to prevent hanging operations
6. **Implement retries** for network requests
7. **Use AbortController** for cancellable operations
8. **Process large datasets** in batches
9. **Promisify** callback-based APIs with util.promisify
10. **Use Promise.allSettled()** when you need all results regardless of failures

**Common async mistakes:**
- Not handling promise rejections (unhandled rejection warnings)
- Sequential execution when parallel would work (slow code)
- Missing await keyword (promise returned instead of value)
- Not returning promises from .then() handlers
- Callback hell (use async/await instead)
- Mixing callbacks and promises
- Not cleaning up resources (timeouts, listeners)
- Forgetting to await in loops
- Creating promises inside loops unnecessarily
- Not using error boundaries for top-level async errors

## Next Steps

1. **03-EVENT-LOOP.md** - Understanding Node.js event loop
2. **04-MODULES.md** - Module systems and imports
3. **08-ERROR-HANDLING.md** - Comprehensive error handling

## Additional Resources

- Node.js Async Documentation: https://nodejs.org/en/docs/guides/
- MDN Async/Await: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/async_function
- Promise Documentation: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise
- Event Loop Guide: https://nodejs.org/en/docs/guides/event-loop-timers-and-nexttick
