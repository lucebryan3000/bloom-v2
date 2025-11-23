# Node.js - Complete Index

```yaml
id: nodejs_index
topic: Node.js
file_role: Problem-based navigation and learning path guide
profile: full
difficulty_level: all_levels
kb_version: v3.1
prerequisites: []
related_topics:
  - TypeScript (../typescript/)
  - Next.js (../nextjs/)
  - Testing (../testing/)
embedding_keywords:
  - nodejs index
  - nodejs navigation
  - node.js guide
  - learning path
  - problem solving
last_reviewed: 2025-11-17
```

## 📍 Quick Navigation

### **New to Node.js?**
1. [README.md](./README.md) - Start here for overview and installation
2. [01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md) - Learn Node.js basics
3. [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) - Quick syntax reference

### **Building Something?**
- **HTTP Server**: [06-HTTP-NETWORKING.md](./06-HTTP-NETWORKING.md)
- **File Processing**: [05-FILE-SYSTEM.md](./05-FILE-SYSTEM.md) + [07-STREAMS-BUFFERS.md](./07-STREAMS-BUFFERS.md)
- **API Backend**: [06-HTTP-NETWORKING.md](./06-HTTP-NETWORKING.md) + [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md)

### **Debugging Issues?**
- **Errors**: [08-ERROR-HANDLING.md](./08-ERROR-HANDLING.md)
- **Performance**: [10-PERFORMANCE.md](./10-PERFORMANCE.md)
- **Testing**: [09-TESTING.md](./09-TESTING.md)

---

## 🗂️ Complete File Structure

### Core Files (11 Topics)

| # | File | Topic | Level | Lines | When to Use |
|---|------|-------|-------|-------|-------------|
| 01 | [FUNDAMENTALS.md](./01-FUNDAMENTALS.md) | Installation, REPL, npm, globals | Beginner | 690 | Setting up Node.js, learning basics |
| 02 | [ASYNC-PROGRAMMING.md](./02-ASYNC-PROGRAMMING.md) | Promises, async/await, callbacks | Intermediate | 720 | Handling async operations |
| 03 | [EVENT-LOOP.md](./03-EVENT-LOOP.md) | Event loop, timers, process.nextTick | Advanced | 870 | Understanding Node.js concurrency |
| 04 | [MODULES.md](./04-MODULES.md) | CommonJS, ES modules, imports/exports | Intermediate | 850 | Organizing code, using packages |
| 05 | [FILE-SYSTEM.md](./05-FILE-SYSTEM.md) | fs/promises, streams, file operations | Intermediate | 930 | Working with files and directories |
| 06 | [HTTP-NETWORKING.md](./06-HTTP-NETWORKING.md) | HTTP/HTTPS servers, routing, requests | Intermediate | 880 | Building web servers and APIs |
| 07 | [STREAMS-BUFFERS.md](./07-STREAMS-BUFFERS.md) | Readable, Writable, Transform, Buffers | Advanced | 900 | Processing large files/data |
| 08 | [ERROR-HANDLING.md](./08-ERROR-HANDLING.md) | Error patterns, debugging, logging | Intermediate | 810 | Debugging and error handling |
| 09 | [TESTING.md](./09-TESTING.md) | Jest, unit tests, mocking, TDD | Intermediate | 680 | Writing tests for Node.js code |
| 10 | [PERFORMANCE.md](./10-PERFORMANCE.md) | Profiling, clustering, caching | Advanced | 730 | Optimizing application performance |
| 11 | [BEST-PRACTICES.md](./11-BEST-PRACTICES.md) | Production patterns, security | Intermediate | 740 | Production deployment and security |

### Navigation Files

- **[INDEX.md](./INDEX.md)** (this file) - Problem-based navigation
- **[QUICK-REFERENCE.md](./QUICK-REFERENCE.md)** - Quick syntax cheat sheet
- **[FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md)** - Framework integration

**Total**: ~11,000+ lines of production-ready Node.js patterns

---

## 📚 Learning Paths

### Path 1: Beginner (New to Node.js)

**Goal**: Build basic Node.js applications

**Files**:
1. [01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md) - Installation, REPL, npm, package.json
2. [04-MODULES.md](./04-MODULES.md) - CommonJS and ES modules
3. [02-ASYNC-PROGRAMMING.md](./02-ASYNC-PROGRAMMING.md) - Promises and async/await
4. [05-FILE-SYSTEM.md](./05-FILE-SYSTEM.md) - Working with files
5. [06-HTTP-NETWORKING.md](./06-HTTP-NETWORKING.md) - Building HTTP servers

**Time**: 6-8 hours | **Outcome**: Create simple Node.js servers and scripts

---

### Path 2: Intermediate (Know basics, need depth)

**Goal**: Production-ready Node.js skills

**Files**:
1. [03-EVENT-LOOP.md](./03-EVENT-LOOP.md) - Understanding event loop
2. [07-STREAMS-BUFFERS.md](./07-STREAMS-BUFFERS.md) - Efficient data processing
3. [08-ERROR-HANDLING.md](./08-ERROR-HANDLING.md) - Error patterns and debugging
4. [09-TESTING.md](./09-TESTING.md) - Testing with Jest
5. [10-PERFORMANCE.md](./10-PERFORMANCE.md) - Optimization techniques

**Time**: 8-10 hours | **Outcome**: Build robust, tested Node.js applications

---

### Path 3: Advanced (Modern Node.js)

**Goal**: Expert-level Node.js architecture

**Files**:
1. [10-PERFORMANCE.md](./10-PERFORMANCE.md) - Profiling, clustering, caching
2. [11-BEST-PRACTICES.md](./11-BEST-PRACTICES.md) - Security, architecture, code quality
3. [03-EVENT-LOOP.md](./03-EVENT-LOOP.md) - Deep dive into event loop
4. [07-STREAMS-BUFFERS.md](./07-STREAMS-BUFFERS.md) - Advanced stream patterns
5. [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md) - Framework integration

**Time**: 10-12 hours | **Outcome**: Expert-level Node.js architecture and optimization

---

## 🎯 Problem-Based Navigation

### "I need to handle async operations"

**Primary**:
- [02-ASYNC-PROGRAMMING.md](./02-ASYNC-PROGRAMMING.md) - Promises, async/await, callbacks

**Related**:
- [03-EVENT-LOOP.md](./03-EVENT-LOOP.md) - How Node.js handles async
- [08-ERROR-HANDLING.md](./08-ERROR-HANDLING.md) - Error handling in async code

**Quick answer**: Use `async/await` with try/catch for modern async code.

```javascript
async function fetchData() {
  try {
    const data = await readFile('file.txt', 'utf8');
    return data;
  } catch (err) {
    console.error('Error:', err);
  }
}
```

---

### "I need to work with files"

**Primary**:
- [05-FILE-SYSTEM.md](./05-FILE-SYSTEM.md) - fs/promises API, file operations

**Related**:
- [07-STREAMS-BUFFERS.md](./07-STREAMS-BUFFERS.md) - Large file processing
- [02-ASYNC-PROGRAMMING.md](./02-ASYNC-PROGRAMMING.md) - Async file operations

**Quick answer**: Use `fs/promises` for async file operations.

```javascript
import { readFile, writeFile } from 'node:fs/promises';

const data = await readFile('file.txt', 'utf8');
await writeFile('output.txt', data, 'utf8');
```

---

### "I need to build an HTTP server"

**Primary**:
- [06-HTTP-NETWORKING.md](./06-HTTP-NETWORKING.md) - HTTP servers, routing, middleware

**Related**:
- [11-BEST-PRACTICES.md](./11-BEST-PRACTICES.md) - Security and production patterns
- [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md) - Express, Next.js integration

**Quick answer**: Use built-in `http` module or Express framework.

```javascript
import http from 'node:http';

const server = http.createServer((req, res) => {
  res.statusCode = 200;
  res.setHeader('Content-Type', 'application/json');
  res.end(JSON.stringify({ message: 'Hello World' }));
});

server.listen(3000);
```

---

### "My app is slow"

**Primary**:
- [10-PERFORMANCE.md](./10-PERFORMANCE.md) - Profiling, optimization, clustering

**Related**:
- [03-EVENT-LOOP.md](./03-EVENT-LOOP.md) - Event loop optimization
- [07-STREAMS-BUFFERS.md](./07-STREAMS-BUFFERS.md) - Efficient data processing

**Quick answer**: Profile with `--inspect`, use clustering, avoid blocking operations.

```javascript
// Profile your app
node --inspect app.js

// Use clustering for multi-core
import cluster from 'node:cluster';
import os from 'node:os';

if (cluster.isPrimary) {
  for (let i = 0; i < os.cpus().length; i++) {
    cluster.fork();
  }
} else {
  // Worker processes
  startServer();
}
```

---

### "I'm getting errors"

**Primary**:
- [08-ERROR-HANDLING.md](./08-ERROR-HANDLING.md) - Error patterns, debugging, logging

**Related**:
- [02-ASYNC-PROGRAMMING.md](./02-ASYNC-PROGRAMMING.md) - Async error handling
- [09-TESTING.md](./09-TESTING.md) - Testing error conditions

**Quick answer**: Always use try/catch for async code, handle process errors.

```javascript
// Handle async errors
try {
  await operation();
} catch (err) {
  console.error('Error:', err);
}

// Handle process-level errors
process.on('unhandledRejection', (err) => {
  console.error('Unhandled rejection:', err);
  process.exit(1);
});
```

---

### "How do I test my code?"

**Primary**:
- [09-TESTING.md](./09-TESTING.md) - Jest, unit tests, integration tests, mocking

**Related**:
- [08-ERROR-HANDLING.md](./08-ERROR-HANDLING.md) - Testing error conditions
- [11-BEST-PRACTICES.md](./11-BEST-PRACTICES.md) - Testing best practices

**Quick answer**: Use Jest for testing Node.js applications.

```javascript
import { fetchUser } from './user-service.js';

describe('fetchUser', () => {
  it('should fetch user by id', async () => {
    const user = await fetchUser(1);
    expect(user).toHaveProperty('id', 1);
  });
});
```

---

### "I need production best practices"

**Primary**:
- [11-BEST-PRACTICES.md](./11-BEST-PRACTICES.md) - Security, architecture, deployment

**Related**:
- [08-ERROR-HANDLING.md](./08-ERROR-HANDLING.md) - Production error handling
- [10-PERFORMANCE.md](./10-PERFORMANCE.md) - Performance optimization

**Quick answer**: Environment variables, error handling, security headers, graceful shutdown.

```javascript
// Validate required environment variables
const required = ['DB_HOST', 'DB_PASSWORD', 'JWT_SECRET'];
for (const key of required) {
  if (!process.env[key]) {
    throw new Error(`Missing required environment variable: ${key}`);
  }
}

// Graceful shutdown
process.on('SIGTERM', async () => {
  await db.close();
  process.exit(0);
});
```

---

### "I need to process large files"

**Primary**:
- [07-STREAMS-BUFFERS.md](./07-STREAMS-BUFFERS.md) - Streams, piping, Transform

**Related**:
- [05-FILE-SYSTEM.md](./05-FILE-SYSTEM.md) - File system operations
- [10-PERFORMANCE.md](./10-PERFORMANCE.md) - Memory optimization

**Quick answer**: Use streams instead of loading entire file into memory.

```javascript
import { createReadStream, createWriteStream } from 'node:fs';
import { pipeline } from 'node:stream/promises';
import { createGzip } from 'node:zlib';

await pipeline(
  createReadStream('large-file.txt'),
  createGzip(),
  createWriteStream('large-file.txt.gz')
);
```

---

### "I need to understand the event loop"

**Primary**:
- [03-EVENT-LOOP.md](./03-EVENT-LOOP.md) - Event loop phases, timers, process.nextTick

**Related**:
- [02-ASYNC-PROGRAMMING.md](./02-ASYNC-PROGRAMMING.md) - Async programming patterns
- [10-PERFORMANCE.md](./10-PERFORMANCE.md) - Event loop optimization

**Quick answer**: Event loop processes async operations in phases: timers → I/O → check → close.

```javascript
// Execution order
console.log('1: Sync');
setTimeout(() => console.log('2: Timer'), 0);
Promise.resolve().then(() => console.log('3: Promise'));
process.nextTick(() => console.log('4: nextTick'));

// Output:
// 1: Sync
// 4: nextTick  <-- Highest priority
// 3: Promise   <-- Microtask queue
// 2: Timer     <-- Timers phase
```

---

### "I need to organize my code"

**Primary**:
- [04-MODULES.md](./04-MODULES.md) - CommonJS, ES modules, imports/exports

**Related**:
- [11-BEST-PRACTICES.md](./11-BEST-PRACTICES.md) - Project structure and architecture
- [01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md) - Node.js module basics

**Quick answer**: Use ES modules (ESM) for new projects.

```javascript
// ESM (recommended)
import { readFile } from 'node:fs/promises';
export function processFile() { /* ... */ }

// CommonJS (legacy)
const fs = require('fs');
module.exports = { processFile };
```

---

## 🔍 Topic Index

### A
- **Async/Await**: 02-ASYNC-PROGRAMMING.md
- **Authentication**: 11-BEST-PRACTICES.md (JWT, bcrypt)

### B
- **Buffers**: 07-STREAMS-BUFFERS.md
- **Best Practices**: 11-BEST-PRACTICES.md

### C
- **Callbacks**: 02-ASYNC-PROGRAMMING.md
- **Clustering**: 10-PERFORMANCE.md
- **CommonJS**: 04-MODULES.md

### D
- **Debugging**: 08-ERROR-HANDLING.md
- **Deployment**: 11-BEST-PRACTICES.md

### E
- **Error Handling**: 08-ERROR-HANDLING.md
- **Event Loop**: 03-EVENT-LOOP.md
- **ES Modules**: 04-MODULES.md
- **Express Integration**: FRAMEWORK-INTEGRATION-PATTERNS.md

### F
- **File System**: 05-FILE-SYSTEM.md
- **File Uploads**: 06-HTTP-NETWORKING.md

### G
- **Graceful Shutdown**: 11-BEST-PRACTICES.md

### H
- **HTTP Server**: 06-HTTP-NETWORKING.md
- **HTTPS**: 06-HTTP-NETWORKING.md

### I
- **Input Validation**: 11-BEST-PRACTICES.md

### J
- **Jest**: 09-TESTING.md
- **JWT**: 11-BEST-PRACTICES.md

### L
- **Logging**: 11-BEST-PRACTICES.md

### M
- **Middleware**: 06-HTTP-NETWORKING.md
- **Mocking**: 09-TESTING.md
- **Modules**: 04-MODULES.md

### N
- **npm**: 01-FUNDAMENTALS.md
- **Next.js Integration**: FRAMEWORK-INTEGRATION-PATTERNS.md

### P
- **Promises**: 02-ASYNC-PROGRAMMING.md
- **Performance**: 10-PERFORMANCE.md
- **process.nextTick**: 03-EVENT-LOOP.md
- **Profiling**: 10-PERFORMANCE.md

### R
- **REPL**: 01-FUNDAMENTALS.md
- **Rate Limiting**: 11-BEST-PRACTICES.md
- **Routing**: 06-HTTP-NETWORKING.md

### S
- **Streams**: 07-STREAMS-BUFFERS.md
- **Security**: 11-BEST-PRACTICES.md
- **SQL Injection**: 11-BEST-PRACTICES.md

### T
- **Testing**: 09-TESTING.md
- **Timers**: 03-EVENT-LOOP.md
- **TypeScript**: FRAMEWORK-INTEGRATION-PATTERNS.md

### V
- **V8 Engine**: 01-FUNDAMENTALS.md

### W
- **WebSockets**: 06-HTTP-NETWORKING.md
- **Worker Threads**: 10-PERFORMANCE.md

### X
- **XSS Prevention**: 11-BEST-PRACTICES.md

---

## 📖 Reading Recommendations

### First Time with Node.js?
Start with the **Beginner Path**:
1. README.md (overview)
2. 01-FUNDAMENTALS.md (basics)
3. 02-ASYNC-PROGRAMMING.md (async patterns)
4. 06-HTTP-NETWORKING.md (build a server)

### Coming from another language?
Focus on Node.js-specific concepts:
1. 03-EVENT-LOOP.md (Node.js concurrency model)
2. 04-MODULES.md (module system)
3. 02-ASYNC-PROGRAMMING.md (async patterns)
4. 07-STREAMS-BUFFERS.md (efficient data processing)

### Preparing for production?
Read these in order:
1. 08-ERROR-HANDLING.md (error patterns)
2. 09-TESTING.md (testing strategies)
3. 10-PERFORMANCE.md (optimization)
4. 11-BEST-PRACTICES.md (security and deployment)

### Debugging performance issues?
1. 10-PERFORMANCE.md (profiling and optimization)
2. 03-EVENT-LOOP.md (event loop blocking)
3. 07-STREAMS-BUFFERS.md (memory optimization)

---

## 🌐 External Resources

- **Official Docs**: https://nodejs.org/docs/
- **npm Docs**: https://docs.npmjs.com/
- **Node.js Guides**: https://nodejs.org/en/docs/guides/
- **Best Practices**: https://github.com/goldbergyoni/nodebestpractices
- **Learn Node.js**: https://nodejs.dev/en/learn/

---

## AI Pair Programming Notes

**When Claude references this INDEX:**

**Common user intents**:
- "I need to learn Node.js" → Beginner Path
- "How do I do X in Node.js?" → Problem-Based Navigation
- "My Node.js app has issues" → Debugging Issues section
- "Best way to structure Node.js code?" → 11-BEST-PRACTICES.md + 04-MODULES.md

**Quick resolution patterns**:
1. **Async operations** → 02-ASYNC-PROGRAMMING.md
2. **File handling** → 05-FILE-SYSTEM.md
3. **HTTP server** → 06-HTTP-NETWORKING.md
4. **Performance** → 10-PERFORMANCE.md
5. **Errors** → 08-ERROR-HANDLING.md

**Integration questions**:
- "Use with Express?" → FRAMEWORK-INTEGRATION-PATTERNS.md
- "Use with TypeScript?" → FRAMEWORK-INTEGRATION-PATTERNS.md + ../typescript/
- "Use with Next.js?" → FRAMEWORK-INTEGRATION-PATTERNS.md + ../nextjs/

**Testing questions**:
- "How to test?" → 09-TESTING.md
- "How to mock?" → 09-TESTING.md (mocking section)

---

**Last Updated**: November 17, 2025
**Node.js Version**: 20.x+
**Total Lines**: 11,000+
**Status**: Production-Ready ✅
