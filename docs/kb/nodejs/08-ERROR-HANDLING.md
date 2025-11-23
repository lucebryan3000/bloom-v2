# Node.js Error Handling

```yaml
id: nodejs_08_error_handling
topic: Node.js
file_role: Error handling patterns, try/catch, error events, debugging, logging
profile: full
difficulty_level: intermediate
kb_version: v3.1
prerequisites:
  - Fundamentals (01-FUNDAMENTALS.md)
  - Async Programming (02-ASYNC-PROGRAMMING.md)
related_topics:
  - Best Practices (11-BEST-PRACTICES.md)
embedding_keywords:
  - nodejs error handling
  - try catch
  - error events
  - debugging
  - error codes
  - stack traces
last_reviewed: 2025-11-17
```

## Error Handling Overview

**Node.js error handling patterns:**

1. **Try/Catch** - Synchronous code and async/await
2. **Error-first callbacks** - Traditional Node.js pattern
3. **Promise rejection** - .catch() and unhandled rejections
4. **Error events** - EventEmitter error events
5. **Process-level handlers** - uncaughtException, unhandledRejection

```javascript
// ESM
import { EventEmitter } from 'node:events';

// CommonJS
const { EventEmitter } = require('events');
```

## Synchronous Error Handling

### Try/Catch

```javascript
// ✅ GOOD - Synchronous error handling
function parseJSON(jsonString) {
  try {
    return JSON.parse(jsonString);
  } catch (err) {
    console.error('Invalid JSON:', err.message);
    return null;
  }
}

// ✅ GOOD - Specific error handling
try {
  const data = JSON.parse(invalidJSON);
} catch (err) {
  if (err instanceof SyntaxError) {
    console.error('Syntax error in JSON:', err.message);
  } else {
    console.error('Unexpected error:', err);
  }
}

// ✅ GOOD - Re-throw after logging
try {
  riskyOperation();
} catch (err) {
  console.error('Operation failed:', err);
  throw err; // Re-throw for caller to handle
}
```

## Async Error Handling

### Async/Await with Try/Catch

```javascript
// ✅ GOOD - Async/await error handling
async function fetchUser(id) {
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

// ✅ GOOD - Multiple async operations
async function processData() {
  try {
    const users = await fetchUsers();
    const posts = await fetchPosts();
    const comments = await fetchComments();

    return { users, posts, comments };
  } catch (err) {
    if (err.code === 'ECONNREFUSED') {
      console.error('Database connection refused');
    } else if (err.code === 'ETIMEDOUT') {
      console.error('Request timed out');
    } else {
      console.error('Unknown error:', err);
    }
    throw err;
  }
}
```

### Promise Error Handling

```javascript
// ✅ GOOD - Promise .catch()
fetchUser(1)
  .then(user => console.log(user))
  .catch(err => console.error('Error:', err))
  .finally(() => console.log('Request complete'));

// ✅ GOOD - Promise.all() error handling
Promise.all([fetchUsers(), fetchPosts(), fetchComments()])
  .then(([users, posts, comments]) => {
    console.log({ users, posts, comments });
  })
  .catch(err => {
    console.error('One or more requests failed:', err);
  });

// ✅ GOOD - Promise.allSettled() for partial failure
Promise.allSettled([fetchUsers(), fetchPosts(), fetchComments()])
  .then(results => {
    results.forEach((result, index) => {
      if (result.status === 'fulfilled') {
        console.log(`Request ${index} succeeded:`, result.value);
      } else {
        console.log(`Request ${index} failed:`, result.reason);
      }
    });
  });
```

### Error-First Callbacks (Legacy)

```javascript
// ⚠️ Legacy pattern - error-first callback
const fs = require('fs');

fs.readFile('file.txt', 'utf8', (err, data) => {
  if (err) {
    console.error('Error reading file:', err);
    return;
  }
  console.log('File contents:', data);
});

// ✅ GOOD - Promisify callback-based functions
import { promisify } from 'node:util';

const readFileAsync = promisify(fs.readFile);

try {
  const data = await readFileAsync('file.txt', 'utf8');
  console.log(data);
} catch (err) {
  console.error('Error:', err);
}
```

## Custom Error Classes

```javascript
// ✅ GOOD - Custom error classes
class ValidationError extends Error {
  constructor(message, field) {
    super(message);
    this.name = 'ValidationError';
    this.field = field;
    this.statusCode = 400;
  }
}

class DatabaseError extends Error {
  constructor(message, query) {
    super(message);
    this.name = 'DatabaseError';
    this.query = query;
    this.statusCode = 500;
  }
}

class NotFoundError extends Error {
  constructor(resource, id) {
    super(`${resource} with id ${id} not found`);
    this.name = 'NotFoundError';
    this.resource = resource;
    this.id = id;
    this.statusCode = 404;
  }
}

// Usage
function validateUser(user) {
  if (!user.email) {
    throw new ValidationError('Email is required', 'email');
  }

  if (!user.email.includes('@')) {
    throw new ValidationError('Invalid email format', 'email');
  }
}

try {
  validateUser({ name: 'Alice' });
} catch (err) {
  if (err instanceof ValidationError) {
    console.error(`Validation failed on ${err.field}: ${err.message}`);
  } else {
    console.error('Unexpected error:', err);
  }
}
```

## Error Events

### EventEmitter Errors

```javascript
import { EventEmitter } from 'node:events';

// ✅ GOOD - Handle error events
const emitter = new EventEmitter();

emitter.on('error', (err) => {
  console.error('Error event:', err);
});

emitter.emit('error', new Error('Something went wrong'));

// ❌ BAD - Unhandled error event crashes process
const badEmitter = new EventEmitter();
badEmitter.emit('error', new Error('Crash!')); // Throws!
```

### Stream Errors

```javascript
import { createReadStream } from 'node:fs';
import { pipeline } from 'node:stream/promises';

// ✅ GOOD - Handle stream errors
const stream = createReadStream('file.txt');

stream.on('error', (err) => {
  if (err.code === 'ENOENT') {
    console.error('File not found');
  } else {
    console.error('Stream error:', err);
  }
});

// ✅ BETTER - Use pipeline for error handling
try {
  await pipeline(
    createReadStream('input.txt'),
    createWriteStream('output.txt')
  );
} catch (err) {
  console.error('Pipeline failed:', err);
}
```

## Process-Level Error Handlers

### uncaughtException

```javascript
// ⚠️ LAST RESORT - Catch uncaught exceptions
process.on('uncaughtException', (err, origin) => {
  console.error('Uncaught Exception:', err);
  console.error('Exception origin:', origin);

  // Log error, cleanup, then exit
  // Don't continue running!
  process.exit(1);
});

// ❌ BAD - Continuing after uncaught exception
process.on('uncaughtException', (err) => {
  console.error('Error:', err);
  // Still running - application state may be corrupted!
});
```

### unhandledRejection

```javascript
// ✅ GOOD - Handle unhandled promise rejections
process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise);
  console.error('Reason:', reason);

  // Log error and exit
  process.exit(1);
});

// Example: Promise without catch
Promise.reject(new Error('Unhandled!')); // Triggers unhandledRejection

// ✅ GOOD - Always catch promises
Promise.reject(new Error('Handled'))
  .catch(err => console.error('Caught:', err));
```

### warning Event

```javascript
// Listen for Node.js warnings
process.on('warning', (warning) => {
  console.warn('Warning:', warning.name);
  console.warn('Message:', warning.message);
  console.warn('Stack:', warning.stack);
});

// Emit custom warning
process.emitWarning('Something is deprecated', {
  code: 'CUSTOM_WARNING',
  detail: 'Use newFunction() instead',
});
```

## Error Codes

### Common Error Codes

```javascript
// File system errors
// ENOENT - No such file or directory
// EACCES - Permission denied
// EEXIST - File already exists
// EISDIR - Is a directory
// ENOTDIR - Not a directory

// Network errors
// ECONNREFUSED - Connection refused
// ETIMEDOUT - Connection timed out
// ENOTFOUND - DNS lookup failed
// ECONNRESET - Connection reset by peer

// ✅ GOOD - Handle specific error codes
try {
  await fs.promises.readFile('file.txt');
} catch (err) {
  switch (err.code) {
    case 'ENOENT':
      console.error('File not found');
      break;
    case 'EACCES':
      console.error('Permission denied');
      break;
    case 'EISDIR':
      console.error('Path is a directory, not a file');
      break;
    default:
      console.error('Unknown error:', err);
  }
}
```

## Error Propagation

```javascript
// ✅ GOOD - Let errors bubble up
async function fetchData() {
  const response = await fetch('/api/data');

  if (!response.ok) {
    throw new Error(`HTTP ${response.status}`);
  }

  return response.json();
}

async function processData() {
  const data = await fetchData(); // Let error propagate
  return data.map(item => item.value);
}

async function main() {
  try {
    const result = await processData();
    console.log(result);
  } catch (err) {
    // Handle error at top level
    console.error('Failed to process data:', err);
  }
}

// ❌ BAD - Swallow errors
async function badFunction() {
  try {
    await riskyOperation();
  } catch (err) {
    // Silent failure - error is lost!
  }
}
```

## Debugging

### Console Debugging

```javascript
// Basic logging
console.log('Info:', data);
console.error('Error:', err);
console.warn('Warning:', msg);

// Timing
console.time('operation');
// ... code ...
console.timeEnd('operation'); // operation: 123.456ms

// Table
console.table([
  { name: 'Alice', age: 25 },
  { name: 'Bob', age: 30 },
]);

// Trace
console.trace('Trace from here');

// Assert
console.assert(value > 0, 'Value must be positive');
```

### Debug Module

```javascript
import debug from 'debug';

// Create debug namespaces
const debugApp = debug('app:main');
const debugDB = debug('app:db');
const debugHTTP = debug('app:http');

debugApp('Application starting');
debugDB('Connecting to database');
debugHTTP('Starting HTTP server');

// Run with: DEBUG=app:* node app.js
// Or: DEBUG=app:db node app.js
```

### Node.js Debugger

```bash
# Built-in debugger
node inspect app.js

# Chrome DevTools
node --inspect app.js
# Open chrome://inspect in Chrome

# VS Code debugging
# Add breakpoints in editor, press F5
```

### Stack Traces

```javascript
// ✅ GOOD - Capture stack trace
function captureStack() {
  const err = new Error();
  Error.captureStackTrace(err, captureStack);
  return err.stack;
}

console.log(captureStack());

// Limit stack trace depth
Error.stackTraceLimit = 10; // Default is 10

// ✅ GOOD - Clean stack traces
function cleanStack(err) {
  const lines = err.stack.split('\n');
  const filtered = lines.filter(line =>
    !line.includes('node_modules')
  );
  return filtered.join('\n');
}

try {
  throw new Error('Test');
} catch (err) {
  console.log(cleanStack(err));
}
```

## Error Handling Patterns

### Centralized Error Handler

```javascript
// ✅ GOOD - Centralized error handler
class ErrorHandler {
  static handle(err, req, res) {
    console.error('Error:', err);

    const statusCode = err.statusCode || 500;
    const message = err.message || 'Internal Server Error';

    res.statusCode = statusCode;
    res.setHeader('Content-Type', 'application/json');
    res.end(JSON.stringify({
      error: {
        message,
        ...(process.env.NODE_ENV === 'development' && {
          stack: err.stack,
        }),
      },
    }));
  }

  static async handleAsync(fn) {
    return async (req, res) => {
      try {
        await fn(req, res);
      } catch (err) {
        ErrorHandler.handle(err, req, res);
      }
    };
  }
}

// Usage
const server = http.createServer(ErrorHandler.handleAsync(async (req, res) => {
  if (req.url === '/users') {
    const users = await fetchUsers();
    res.end(JSON.stringify(users));
  } else {
    throw new NotFoundError('Route', req.url);
  }
}));
```

### Retry Logic with Exponential Backoff

```javascript
// ✅ GOOD - Retry with backoff
async function retryWithBackoff(fn, maxRetries = 3, baseDelay = 1000) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await fn();
    } catch (err) {
      if (i === maxRetries - 1) {
        throw err; // Last attempt failed
      }

      const delay = baseDelay * Math.pow(2, i);
      console.log(`Retry ${i + 1}/${maxRetries} after ${delay}ms`);
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }
}

// Usage
const data = await retryWithBackoff(
  () => fetch('/api/data').then(r => r.json())
);
```

### Circuit Breaker Pattern

```javascript
// ✅ GOOD - Circuit breaker
class CircuitBreaker {
  constructor(fn, options = {}) {
    this.fn = fn;
    this.failureThreshold = options.failureThreshold || 5;
    this.timeout = options.timeout || 60000;
    this.state = 'CLOSED'; // CLOSED, OPEN, HALF_OPEN
    this.failureCount = 0;
    this.nextAttempt = Date.now();
  }

  async call(...args) {
    if (this.state === 'OPEN') {
      if (Date.now() < this.nextAttempt) {
        throw new Error('Circuit breaker is OPEN');
      }
      this.state = 'HALF_OPEN';
    }

    try {
      const result = await this.fn(...args);

      // Success - reset
      if (this.state === 'HALF_OPEN') {
        this.state = 'CLOSED';
      }
      this.failureCount = 0;

      return result;
    } catch (err) {
      this.failureCount++;

      if (this.failureCount >= this.failureThreshold) {
        this.state = 'OPEN';
        this.nextAttempt = Date.now() + this.timeout;
      }

      throw err;
    }
  }
}

// Usage
const breaker = new CircuitBreaker(
  () => fetch('/api/data').then(r => r.json()),
  { failureThreshold: 5, timeout: 60000 }
);

try {
  const data = await breaker.call();
} catch (err) {
  console.error('Circuit breaker error:', err);
}
```

## AI Pair Programming Notes

**When handling errors:**

1. **Always handle errors** - Never ignore errors silently
2. **Use try/catch** for async/await
3. **Create custom error classes** - Add context and metadata
4. **Check error codes** - Handle specific errors differently
5. **Log errors** - Include context and stack traces
6. **Propagate errors** - Let callers decide how to handle
7. **Handle promise rejections** - Always .catch() or use try/catch
8. **Listen for error events** - EventEmitter, streams, etc.
9. **Use centralized error handling** - Consistent error responses
10. **Debug effectively** - Use debug module, stack traces, DevTools

**Common error handling mistakes:**
- Swallowing errors (empty catch blocks)
- Not handling unhandled rejections
- Continuing after uncaughtException
- Ignoring error event on EventEmitters
- Not checking error codes
- Losing error context when re-throwing
- Using console.log instead of proper logging
- Not cleaning up resources in error cases
- Exposing internal errors to users
- Not testing error paths

## Next Steps

1. **09-TESTING.md** - Testing error conditions
2. **11-BEST-PRACTICES.md** - Production error handling
3. **10-PERFORMANCE.md** - Error handling performance

## Additional Resources

- Error Handling: https://nodejs.org/api/errors.html
- Process Events: https://nodejs.org/api/process.html#process_event_uncaughtexception
- Debug Module: https://www.npmjs.com/package/debug
- Node.js Debugging Guide: https://nodejs.org/en/docs/guides/debugging-getting-started/
