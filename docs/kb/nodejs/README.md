# Node.js Knowledge Base

```yaml
id: nodejs_readme
topic: Node.js
file_role: Overview and entry point for Node.js KB
profile: full
difficulty_level: all_levels
kb_version: v3.1
prerequisites: []
related_topics:
  - TypeScript (../typescript/)
  - Next.js (../nextjs/)
  - Testing (../testing/)
embedding_keywords:
  - nodejs
  - node.js
  - javascript runtime
  - npm
  - server-side javascript
  - backend
last_reviewed: 2025-11-17
```

## Welcome to Node.js KB

Comprehensive knowledge base for **Node.js** covering fundamentals, async programming, event loop, modules, file system, HTTP, streams, testing, performance, and production best practices.

**Total Content**: 11 core files, ~11,000+ lines of production-ready patterns

---

## 📚 Documentation Structure

### **Quick Navigation**
- **[INDEX.md](./INDEX.md)** - Problem-based navigation and learning paths
- **[QUICK-REFERENCE.md](./QUICK-REFERENCE.md)** - Quick syntax reference
- **[FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md)** - Framework integration patterns

### **Core Files (11 Topics)**

| # | File | Topic | Level | Lines |
|---|------|-------|-------|-------|
| 01 | [FUNDAMENTALS.md](./01-FUNDAMENTALS.md) | Installation, REPL, npm, globals | Beginner | 690 |
| 02 | [ASYNC-PROGRAMMING.md](./02-ASYNC-PROGRAMMING.md) | Promises, async/await, callbacks | Intermediate | 720 |
| 03 | [EVENT-LOOP.md](./03-EVENT-LOOP.md) | Event loop, timers, process.nextTick | Advanced | 870 |
| 04 | [MODULES.md](./04-MODULES.md) | CommonJS, ES modules, imports/exports | Intermediate | 850 |
| 05 | [FILE-SYSTEM.md](./05-FILE-SYSTEM.md) | fs/promises, streams, file operations | Intermediate | 930 |
| 06 | [HTTP-NETWORKING.md](./06-HTTP-NETWORKING.md) | HTTP/HTTPS servers, routing, requests | Intermediate | 880 |
| 07 | [STREAMS-BUFFERS.md](./07-STREAMS-BUFFERS.md) | Readable, Writable, Transform, Buffers | Advanced | 900 |
| 08 | [ERROR-HANDLING.md](./08-ERROR-HANDLING.md) | Error patterns, debugging, logging | Intermediate | 810 |
| 09 | [TESTING.md](./09-TESTING.md) | Jest, unit tests, mocking, TDD | Intermediate | 680 |
| 10 | [PERFORMANCE.md](./10-PERFORMANCE.md) | Profiling, clustering, caching | Advanced | 730 |
| 11 | [BEST-PRACTICES.md](./11-BEST-PRACTICES.md) | Production patterns, security | Intermediate | 740 |

**Total**: ~11,000+ lines of Node.js patterns and examples

---

## 🚀 Quick Start

### Installation

```bash
# Install Node.js (choose one)
# macOS with Homebrew
brew install node

# Ubuntu/Debian
sudo apt update && sudo apt install nodejs npm

# Windows with Chocolatey
choco install nodejs

# Or download from https://nodejs.org/
```

### Verify Installation

```bash
node --version  # v20.x.x or higher
npm --version   # 10.x.x or higher
```

### First Program

```javascript
// hello.js
console.log('Hello, Node.js!');
```

```bash
node hello.js
```

### Simple HTTP Server

```javascript
// server.js
import http from 'node:http';

const server = http.createServer((req, res) => {
  res.statusCode = 200;
  res.setHeader('Content-Type', 'text/plain');
  res.end('Hello World\n');
});

server.listen(3000, () => {
  console.log('Server running at http://localhost:3000/');
});
```

---

## 📖 Learning Paths

### **Path 1: Beginner (New to Node.js)**

1. [FUNDAMENTALS.md](./01-FUNDAMENTALS.md) - Installation, REPL, npm, package.json
2. [MODULES.md](./04-MODULES.md) - CommonJS and ES modules
3. [ASYNC-PROGRAMMING.md](./02-ASYNC-PROGRAMMING.md) - Promises and async/await
4. [FILE-SYSTEM.md](./05-FILE-SYSTEM.md) - Working with files
5. [HTTP-NETWORKING.md](./06-HTTP-NETWORKING.md) - Building HTTP servers

**Time**: 6-8 hours | **Outcome**: Build basic Node.js applications

### **Path 2: Intermediate (Know basics, need depth)**

1. [EVENT-LOOP.md](./03-EVENT-LOOP.md) - Understanding event loop
2. [STREAMS-BUFFERS.md](./07-STREAMS-BUFFERS.md) - Efficient data processing
3. [ERROR-HANDLING.md](./08-ERROR-HANDLING.md) - Error patterns and debugging
4. [TESTING.md](./09-TESTING.md) - Testing with Jest
5. [PERFORMANCE.md](./10-PERFORMANCE.md) - Optimization techniques

**Time**: 8-10 hours | **Outcome**: Production-ready Node.js skills

### **Path 3: Advanced (Modern Node.js)**

1. [PERFORMANCE.md](./10-PERFORMANCE.md) - Profiling, clustering, caching
2. [BEST-PRACTICES.md](./11-BEST-PRACTICES.md) - Security, architecture, code quality
3. [EVENT-LOOP.md](./03-EVENT-LOOP.md) - Deep dive into event loop
4. [STREAMS-BUFFERS.md](./07-STREAMS-BUFFERS.md) - Advanced stream patterns
5. [TypeScript KB](../typescript/) - Type-safe Node.js development

**Time**: 10-12 hours | **Outcome**: Expert-level Node.js architecture

---

## 🎯 Common Tasks

### "I need to handle async operations"
→ [ASYNC-PROGRAMMING.md](./02-ASYNC-PROGRAMMING.md) - Promises, async/await, patterns
→ [EVENT-LOOP.md](./03-EVENT-LOOP.md) - How Node.js handles async

### "I need to work with files"
→ [FILE-SYSTEM.md](./05-FILE-SYSTEM.md) - fs/promises, streams
→ [STREAMS-BUFFERS.md](./07-STREAMS-BUFFERS.md) - Large file processing

### "I need to build an HTTP server"
→ [HTTP-NETWORKING.md](./06-HTTP-NETWORKING.md) - HTTP/HTTPS servers, routing
→ [QUICK-REFERENCE.md](./QUICK-REFERENCE.md#http) - Quick HTTP examples

### "My app is slow"
→ [PERFORMANCE.md](./10-PERFORMANCE.md) - Profiling, optimization
→ [EVENT-LOOP.md](./03-EVENT-LOOP.md) - Event loop optimization

### "How do I test my code?"
→ [TESTING.md](./09-TESTING.md) - Jest, unit tests, integration tests
→ [ERROR-HANDLING.md](./08-ERROR-HANDLING.md) - Testing error conditions

### "I need production best practices"
→ [BEST-PRACTICES.md](./11-BEST-PRACTICES.md) - Security, architecture, deployment
→ [ERROR-HANDLING.md](./08-ERROR-HANDLING.md) - Production error handling

---

## 🔑 Key Concepts

### 1. Asynchronous by Default

```javascript
// ✅ GOOD - Async I/O (non-blocking)
const data = await fs.promises.readFile('file.txt', 'utf8');

// ❌ BAD - Synchronous I/O (blocks event loop)
const data = fs.readFileSync('file.txt', 'utf8');
```

### 2. Event-Driven Architecture

```javascript
// Event emitter pattern
const EventEmitter = require('events');

class Server extends EventEmitter {
  start() {
    this.emit('started');
  }
}

const server = new Server();
server.on('started', () => console.log('Server started'));
server.start();
```

### 3. Modules (CommonJS & ESM)

```javascript
// ESM (recommended for new projects)
import { readFile } from 'node:fs/promises';
export function processFile() { /* ... */ }

// CommonJS (legacy, still widely used)
const fs = require('fs');
module.exports = { processFile };
```

### 4. Streams for Large Data

```javascript
// ✅ GOOD - Stream large files
import { createReadStream } from 'node:fs';

createReadStream('large-file.txt')
  .pipe(processStream)
  .pipe(createWriteStream('output.txt'));

// ❌ BAD - Load entire file into memory
const data = await readFile('large-file.txt');
```

### 5. Error Handling

```javascript
// ✅ GOOD - Always handle errors
try {
  const data = await fetchData();
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

## ⚡ Node.js Features

### NPM Package Management

```bash
# Initialize project
npm init -y

# Install dependencies
npm install express
npm install --save-dev jest

# Run scripts
npm start
npm test
```

### Built-in Modules

```javascript
// Core modules (no installation required)
import fs from 'node:fs';
import http from 'node:http';
import path from 'node:path';
import crypto from 'node:crypto';
import os from 'node:os';
import { EventEmitter } from 'node:events';
```

### REPL (Interactive Shell)

```bash
# Start REPL
node

> 2 + 2
4
> console.log('Hello')
Hello
> .exit
```

---

## ⚠️ Common Pitfalls

### ❌ Blocking the Event Loop

```javascript
// BAD - Blocks event loop
while (Date.now() - start < 5000) {
  // CPU-intensive loop blocks all I/O
}

// GOOD - Use async operations
await new Promise(resolve => setTimeout(resolve, 5000));
```

### ❌ Not Handling Errors

```javascript
// BAD - Unhandled promise rejection
fetchData(); // No .catch() or try/catch

// GOOD - Always handle errors
try {
  await fetchData();
} catch (err) {
  console.error('Error:', err);
}
```

### ❌ Synchronous I/O in Production

```javascript
// BAD - Blocks all requests
const data = fs.readFileSync('file.txt');

// GOOD - Non-blocking
const data = await fs.promises.readFile('file.txt');
```

---

## 🔧 Configuration

### package.json

```json
{
  "name": "my-app",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "start": "node index.js",
    "dev": "node --watch index.js",
    "test": "jest"
  },
  "dependencies": {
    "express": "^4.18.0"
  },
  "devDependencies": {
    "jest": "^29.0.0"
  }
}
```

### .env File

```env
NODE_ENV=development
PORT=3000
DATABASE_URL=postgresql://localhost/mydb
```

---

## 📊 Files in This Directory

```
docs/kb/nodejs/
├── README.md                           # Overview (this file)
├── INDEX.md                            # Problem-based navigation
├── QUICK-REFERENCE.md                  # Syntax cheat sheet
├── FRAMEWORK-INTEGRATION-PATTERNS.md   # Framework integration
├── 01-FUNDAMENTALS.md                  # Installation, REPL, npm
├── 02-ASYNC-PROGRAMMING.md             # Promises, async/await
├── 03-EVENT-LOOP.md                    # Event loop, timers
├── 04-MODULES.md                       # CommonJS, ES modules
├── 05-FILE-SYSTEM.md                   # fs/promises, streams
├── 06-HTTP-NETWORKING.md               # HTTP servers, requests
├── 07-STREAMS-BUFFERS.md               # Streams, Buffers, piping
├── 08-ERROR-HANDLING.md                # Error patterns, debugging
├── 09-TESTING.md                       # Jest, unit tests, mocking
├── 10-PERFORMANCE.md                   # Profiling, optimization
└── 11-BEST-PRACTICES.md                # Production patterns, security
```

---

## 🌐 External Resources

- **Official Docs**: https://nodejs.org/docs/
- **npm Docs**: https://docs.npmjs.com/
- **Node.js Guides**: https://nodejs.org/en/docs/guides/
- **Best Practices**: https://github.com/goldbergyoni/nodebestpractices
- **Learn Node.js**: https://nodejs.dev/en/learn/

---

**Last Updated**: November 17, 2025
**Node.js Version**: 20.x+
**Total Lines**: 11,000+
**Status**: Production-Ready ✅

---

## Next Steps

1. **New to Node.js?** → Start with [FUNDAMENTALS.md](./01-FUNDAMENTALS.md)
2. **Need quick syntax?** → Check [QUICK-REFERENCE.md](./QUICK-REFERENCE.md)
3. **Building production apps?** → Review [BEST-PRACTICES.md](./11-BEST-PRACTICES.md)
4. **Need performance help?** → Read [PERFORMANCE.md](./10-PERFORMANCE.md)

Happy coding! 🚀
