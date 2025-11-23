# Node.js - Quick Reference

```yaml
id: nodejs_quick_reference
topic: Node.js
file_role: Quick syntax reference and cheat sheet
profile: full
difficulty_level: all_levels
kb_version: v3.1
prerequisites: []
related_topics:
  - 01-FUNDAMENTALS.md
  - 02-ASYNC-PROGRAMMING.md
  - INDEX.md
embedding_keywords:
  - nodejs cheat sheet
  - nodejs quick reference
  - nodejs syntax
  - nodejs commands
  - node.js examples
last_reviewed: 2025-11-17
```

## Installation & Version Management

```bash
# Install Node.js
brew install node              # macOS
sudo apt install nodejs npm    # Ubuntu/Debian
choco install nodejs           # Windows

# Check version
node --version   # v20.x.x
npm --version    # 10.x.x

# Version management with nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
nvm install 20
nvm use 20
nvm alias default 20
```

---

## Running Node.js

```bash
# Run a file
node app.js

# Run with flags
node --inspect app.js           # Debug mode
node --watch app.js             # Auto-reload (Node 18+)
node --inspect-brk app.js       # Break on start

# REPL (interactive)
node
> 2 + 2
4
> .exit

# Execute inline code
node -e "console.log('Hello')"

# Print evaluation
node -p "2 + 2"  # 4
```

---

## npm Commands

```bash
# Initialize project
npm init
npm init -y              # Skip prompts

# Install packages
npm install express      # Add to dependencies
npm install -D jest      # Add to devDependencies
npm install -g nodemon   # Global install

# Install all dependencies
npm install
npm ci                   # Clean install (uses package-lock.json)

# Update packages
npm update
npm update express

# Remove packages
npm uninstall express

# List packages
npm list
npm list --depth=0       # Top level only
npm list -g --depth=0    # Global packages

# Check for outdated
npm outdated

# View package info
npm info express
npm view express versions

# Run scripts
npm start
npm test
npm run dev
npm run build
```

---

## Modules (ESM)

```javascript
// Import
import fs from 'node:fs';                    // Default import
import { readFile } from 'node:fs/promises'; // Named import
import * as path from 'node:path';           // Namespace import

// Export
export function myFunction() { }             // Named export
export default class MyClass { }             // Default export
export { foo, bar };                         // Multiple exports

// Dynamic import
const module = await import('./module.js');

// __dirname and __filename in ESM
import { fileURLToPath } from 'url';
import { dirname } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
```

---

## Modules (CommonJS)

```javascript
// Require
const fs = require('fs');
const { readFile } = require('fs').promises;
const express = require('express');

// Export
module.exports = { myFunction };      // Object export
module.exports.foo = 'bar';           // Property export
exports.myFunction = () => { };       // Shorthand

// Don't reassign exports
exports = { foo };  // ❌ WRONG
module.exports = { foo };  // ✅ CORRECT
```

---

## Async Programming

```javascript
// Promises
const promise = new Promise((resolve, reject) => {
  if (success) resolve(data);
  else reject(error);
});

promise
  .then(data => console.log(data))
  .catch(err => console.error(err))
  .finally(() => console.log('Done'));

// Async/Await
async function fetchData() {
  try {
    const data = await readFile('file.txt', 'utf8');
    return data;
  } catch (err) {
    console.error('Error:', err);
  }
}

// Promise.all (parallel)
const [users, posts] = await Promise.all([
  fetchUsers(),
  fetchPosts()
]);

// Promise.race (first to complete)
const result = await Promise.race([
  fetchFromAPI1(),
  fetchFromAPI2()
]);

// Promise.allSettled (all results, even if some fail)
const results = await Promise.allSettled([
  promise1,
  promise2,
  promise3
]);

// Promisify callback-based functions
import { promisify } from 'node:util';
const readFilePromise = promisify(fs.readFile);
```

---

## File System

```javascript
import {
  readFile,
  writeFile,
  appendFile,
  access,
  mkdir,
  readdir,
  stat,
  unlink,
  rm
} from 'node:fs/promises';
import { constants } from 'node:fs';

// Read file
const data = await readFile('file.txt', 'utf8');

// Write file
await writeFile('file.txt', 'content', 'utf8');

// Append to file
await appendFile('log.txt', 'New line\n', 'utf8');

// Check if file exists
try {
  await access('file.txt', constants.F_OK);
  console.log('File exists');
} catch {
  console.log('File does not exist');
}

// Create directory
await mkdir('dir', { recursive: true });

// Read directory
const files = await readdir('dir');

// File stats
const stats = await stat('file.txt');
console.log(stats.size);           // File size
console.log(stats.isFile());       // true
console.log(stats.isDirectory());  // false

// Delete file
await unlink('file.txt');

// Delete directory (recursive)
await rm('dir', { recursive: true, force: true });
```

---

## Streams

```javascript
import {
  createReadStream,
  createWriteStream
} from 'node:fs';
import { pipeline } from 'node:stream/promises';
import { Transform } from 'node:stream';

// Read stream
const readStream = createReadStream('input.txt', 'utf8');
readStream.on('data', chunk => console.log(chunk));
readStream.on('end', () => console.log('Done'));
readStream.on('error', err => console.error(err));

// Write stream
const writeStream = createWriteStream('output.txt');
writeStream.write('Hello\n');
writeStream.end('Goodbye\n');

// Pipe streams
createReadStream('input.txt')
  .pipe(createWriteStream('output.txt'));

// Pipeline (recommended - handles errors)
await pipeline(
  createReadStream('input.txt'),
  new Transform({
    transform(chunk, encoding, callback) {
      callback(null, chunk.toString().toUpperCase());
    }
  }),
  createWriteStream('output.txt')
);

// Compress file
import { createGzip } from 'node:zlib';

await pipeline(
  createReadStream('file.txt'),
  createGzip(),
  createWriteStream('file.txt.gz')
);
```

---

## HTTP Server

```javascript
import http from 'node:http';

// Basic server
const server = http.createServer((req, res) => {
  res.statusCode = 200;
  res.setHeader('Content-Type', 'application/json');
  res.end(JSON.stringify({ message: 'Hello' }));
});

server.listen(3000, () => {
  console.log('Server running at http://localhost:3000/');
});

// Parse URL
import { URL } from 'node:url';

const url = new URL(req.url, `http://${req.headers.host}`);
console.log(url.pathname);      // /api/users
console.log(url.searchParams.get('id'));  // Query param

// Parse request body
let body = '';
req.on('data', chunk => body += chunk);
req.on('end', () => {
  const data = JSON.parse(body);
  console.log(data);
});

// Make HTTP request
import https from 'node:https';

https.get('https://api.example.com/data', res => {
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => console.log(JSON.parse(data)));
});
```

---

## Process & Environment

```javascript
// Environment variables
console.log(process.env.NODE_ENV);
console.log(process.env.PORT);

// Command line arguments
console.log(process.argv);  // ['node', 'script.js', 'arg1', 'arg2']

// Current directory
console.log(process.cwd());

// Platform
console.log(process.platform);  // 'linux', 'darwin', 'win32'

// Node version
console.log(process.version);

// Exit process
process.exit(0);  // Success
process.exit(1);  // Failure

// Exit handlers
process.on('exit', code => {
  console.log(`Exiting with code ${code}`);
});

process.on('SIGTERM', () => {
  console.log('SIGTERM received');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('SIGINT received (Ctrl+C)');
  process.exit(0);
});

// Uncaught errors
process.on('uncaughtException', err => {
  console.error('Uncaught Exception:', err);
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection:', reason);
  process.exit(1);
});
```

---

## Path

```javascript
import path from 'node:path';

// Join paths
const fullPath = path.join(__dirname, 'dir', 'file.txt');
// /home/user/dir/file.txt

// Resolve absolute path
const absPath = path.resolve('file.txt');
// /current/working/dir/file.txt

// Get directory name
path.dirname('/home/user/file.txt');  // /home/user

// Get file name
path.basename('/home/user/file.txt');  // file.txt

// Get extension
path.extname('/home/user/file.txt');  // .txt

// Parse path
path.parse('/home/user/file.txt');
// {
//   root: '/',
//   dir: '/home/user',
//   base: 'file.txt',
//   ext: '.txt',
//   name: 'file'
// }

// Normalize path
path.normalize('/home/user/../user/file.txt');  // /home/user/file.txt
```

---

## Events

```javascript
import { EventEmitter } from 'node:events';

const emitter = new EventEmitter();

// Listen to event
emitter.on('event', (arg1, arg2) => {
  console.log('Event fired', arg1, arg2);
});

// Listen once
emitter.once('event', () => {
  console.log('Fires only once');
});

// Emit event
emitter.emit('event', 'arg1', 'arg2');

// Remove listener
const listener = () => console.log('Event');
emitter.on('event', listener);
emitter.off('event', listener);

// Remove all listeners
emitter.removeAllListeners('event');

// Get listener count
emitter.listenerCount('event');

// Custom EventEmitter class
class MyEmitter extends EventEmitter {
  doSomething() {
    this.emit('done', { status: 'success' });
  }
}

const myEmitter = new MyEmitter();
myEmitter.on('done', data => console.log(data));
myEmitter.doSomething();
```

---

## Timers

```javascript
// setTimeout (run once after delay)
const timeout = setTimeout(() => {
  console.log('Delayed');
}, 1000);

clearTimeout(timeout);  // Cancel

// setInterval (run repeatedly)
const interval = setInterval(() => {
  console.log('Repeated');
}, 1000);

clearInterval(interval);  // Cancel

// setImmediate (run on next event loop iteration)
setImmediate(() => {
  console.log('Immediate');
});

// process.nextTick (run before next event loop phase)
process.nextTick(() => {
  console.log('Next tick');
});

// Execution order
console.log('1: Sync');
setTimeout(() => console.log('2: Timer'), 0);
Promise.resolve().then(() => console.log('3: Promise'));
process.nextTick(() => console.log('4: nextTick'));
setImmediate(() => console.log('5: Immediate'));

// Output:
// 1: Sync
// 4: nextTick
// 3: Promise
// 2: Timer
// 5: Immediate
```

---

## Buffer

```javascript
// Create buffer
const buf1 = Buffer.from('Hello');
const buf2 = Buffer.from([0x48, 0x65, 0x6c, 0x6c, 0x6f]);
const buf3 = Buffer.alloc(10);  // 10 bytes filled with 0
const buf4 = Buffer.allocUnsafe(10);  // 10 bytes uninitialized (faster)

// Convert to string
buf1.toString();  // 'Hello'
buf1.toString('hex');  // '48656c6c6f'
buf1.toString('base64');  // 'SGVsbG8='

// Write to buffer
buf3.write('Hello');

// Buffer length
buf1.length;  // 5

// Compare buffers
Buffer.compare(buf1, buf2);  // 0 (equal)

// Concatenate buffers
const buf5 = Buffer.concat([buf1, buf2]);

// Slice buffer
const slice = buf1.slice(0, 2);  // <Buffer 48 65>
```

---

## Error Handling

```javascript
// Try/catch
try {
  const data = JSON.parse(invalidJSON);
} catch (err) {
  console.error('Parse error:', err.message);
}

// Async try/catch
try {
  const data = await readFile('file.txt', 'utf8');
} catch (err) {
  if (err.code === 'ENOENT') {
    console.error('File not found');
  } else {
    console.error('Error:', err);
  }
}

// Custom error class
class ValidationError extends Error {
  constructor(message, field) {
    super(message);
    this.name = 'ValidationError';
    this.field = field;
    this.statusCode = 400;
  }
}

throw new ValidationError('Invalid email', 'email');

// Error codes
// ENOENT - File not found
// EACCES - Permission denied
// EADDRINUSE - Port in use
// ECONNREFUSED - Connection refused
// ETIMEDOUT - Operation timed out
```

---

## Child Processes

```javascript
import { exec, spawn, execFile, fork } from 'node:child_process';
import { promisify } from 'node:util';

const execPromise = promisify(exec);

// exec (buffer output)
const { stdout, stderr } = await execPromise('ls -la');
console.log(stdout);

// spawn (stream output)
const child = spawn('ls', ['-la']);

child.stdout.on('data', data => {
  console.log(`stdout: ${data}`);
});

child.stderr.on('data', data => {
  console.error(`stderr: ${data}`);
});

child.on('close', code => {
  console.log(`Exit code: ${code}`);
});

// execFile (execute file)
execFile('node', ['--version'], (err, stdout) => {
  console.log(stdout);
});

// fork (run Node.js file in separate process)
const worker = fork('worker.js');

worker.on('message', msg => {
  console.log('Message from worker:', msg);
});

worker.send({ cmd: 'start' });
```

---

## OS

```javascript
import os from 'node:os';

// Platform
os.platform();  // 'linux', 'darwin', 'win32'
os.arch();      // 'x64', 'arm64'

// CPU info
os.cpus();      // Array of CPU info
os.cpus().length;  // Number of CPU cores

// Memory
os.totalmem();  // Total memory in bytes
os.freemem();   // Free memory in bytes

// Uptime
os.uptime();    // System uptime in seconds

// Hostname
os.hostname();  // 'my-computer'

// Home directory
os.homedir();   // '/home/user'

// Temp directory
os.tmpdir();    // '/tmp'

// Network interfaces
os.networkInterfaces();
```

---

## Crypto

```javascript
import crypto from 'node:crypto';

// Random bytes
const bytes = crypto.randomBytes(16);
console.log(bytes.toString('hex'));

// Random UUID
const uuid = crypto.randomUUID();  // '123e4567-e89b-12d3-a456-426614174000'

// Hash (SHA-256)
const hash = crypto.createHash('sha256')
  .update('password')
  .digest('hex');

// HMAC
const hmac = crypto.createHmac('sha256', 'secret')
  .update('message')
  .digest('hex');

// Encrypt/Decrypt (AES-256-GCM)
const algorithm = 'aes-256-gcm';
const key = crypto.randomBytes(32);
const iv = crypto.randomBytes(16);

// Encrypt
const cipher = crypto.createCipheriv(algorithm, key, iv);
let encrypted = cipher.update('text', 'utf8', 'hex');
encrypted += cipher.final('hex');
const authTag = cipher.getAuthTag();

// Decrypt
const decipher = crypto.createDecipheriv(algorithm, key, iv);
decipher.setAuthTag(authTag);
let decrypted = decipher.update(encrypted, 'hex', 'utf8');
decrypted += decipher.final('utf8');

// Password hashing (use bcrypt package instead)
const salt = crypto.randomBytes(16).toString('hex');
const hashedPassword = crypto.pbkdf2Sync('password', salt, 100000, 64, 'sha512').toString('hex');
```

---

## Debugging

```bash
# Chrome DevTools
node --inspect app.js
node --inspect-brk app.js  # Break on start

# Open chrome://inspect in Chrome

# VS Code debugging
# Add to .vscode/launch.json:
{
  "type": "node",
  "request": "launch",
  "name": "Launch Program",
  "program": "${workspaceFolder}/app.js"
}

# Debug with breakpoints
debugger;  // Add to code

# Performance profiling
node --prof app.js
node --prof-process isolate-*.log
```

---

## Testing (Jest)

```javascript
// test/user.test.js
import { fetchUser } from '../src/user.js';

describe('User Service', () => {
  it('should fetch user by id', async () => {
    const user = await fetchUser(1);
    expect(user).toHaveProperty('id', 1);
    expect(user.name).toBe('Alice');
  });

  it('should throw error for invalid id', async () => {
    await expect(fetchUser(999)).rejects.toThrow('User not found');
  });
});

// Mocking
jest.mock('../src/database.js');

// Setup/teardown
beforeAll(() => { /* Run once before all tests */ });
afterAll(() => { /* Run once after all tests */ });
beforeEach(() => { /* Run before each test */ });
afterEach(() => { /* Run after each test */ });
```

---

## Common Patterns

```javascript
// Read JSON file
import { readFile } from 'node:fs/promises';
const config = JSON.parse(await readFile('config.json', 'utf8'));

// Write JSON file
import { writeFile } from 'node:fs/promises';
await writeFile('data.json', JSON.stringify(data, null, 2), 'utf8');

// Check if path is directory
import { stat } from 'node:fs/promises';
const stats = await stat('path');
if (stats.isDirectory()) { /* ... */ }

// Retry with exponential backoff
async function retry(fn, maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await fn();
    } catch (err) {
      if (i === maxRetries - 1) throw err;
      await new Promise(resolve => setTimeout(resolve, 1000 * 2 ** i));
    }
  }
}

// Timeout wrapper
async function withTimeout(promise, ms) {
  const timeout = new Promise((_, reject) =>
    setTimeout(() => reject(new Error('Timeout')), ms)
  );
  return Promise.race([promise, timeout]);
}

// Debounce
function debounce(fn, delay) {
  let timeoutId;
  return (...args) => {
    clearTimeout(timeoutId);
    timeoutId = setTimeout(() => fn(...args), delay);
  };
}

// Throttle
function throttle(fn, delay) {
  let lastCall = 0;
  return (...args) => {
    const now = Date.now();
    if (now - lastCall >= delay) {
      lastCall = now;
      fn(...args);
    }
  };
}
```

---

## package.json Scripts

```json
{
  "scripts": {
    "start": "node index.js",
    "dev": "node --watch index.js",
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
    "lint": "eslint .",
    "format": "prettier --write .",
    "build": "tsc",
    "clean": "rm -rf dist"
  }
}
```

---

## .env File

```env
NODE_ENV=development
PORT=3000
DATABASE_URL=postgresql://user:pass@localhost/db
API_KEY=secret123
```

```javascript
// Load with dotenv package
import 'dotenv/config';

console.log(process.env.PORT);  // 3000
```

---

## Common Error Codes

| Code | Meaning |
|------|---------|
| `ENOENT` | File or directory not found |
| `EACCES` | Permission denied |
| `EADDRINUSE` | Port already in use |
| `ECONNREFUSED` | Connection refused |
| `ECONNRESET` | Connection reset by peer |
| `ETIMEDOUT` | Operation timed out |
| `EEXIST` | File already exists |
| `EISDIR` | Path is a directory |
| `ENOTDIR` | Path is not a directory |

---

## HTTP Status Codes

| Code | Meaning |
|------|---------|
| 200 | OK |
| 201 | Created |
| 204 | No Content |
| 400 | Bad Request |
| 401 | Unauthorized |
| 403 | Forbidden |
| 404 | Not Found |
| 500 | Internal Server Error |
| 502 | Bad Gateway |
| 503 | Service Unavailable |

---

## AI Pair Programming Notes

**When to load this file**: Quick syntax lookup for Node.js commands, modules, and patterns.

**Common use cases**:
- "How do I read a file in Node.js?" → File System section
- "How to make HTTP request?" → HTTP Server section
- "How to handle errors?" → Error Handling section
- "Node.js async patterns?" → Async Programming section

**Quick answers**:
- **Read file**: `await readFile('file.txt', 'utf8')`
- **HTTP server**: `http.createServer((req, res) => { })`
- **Async/await**: `async function() { await ... }`
- **Error handling**: `try { await ... } catch (err) { }`

---

**Last Updated**: November 17, 2025
**Node.js Version**: 20.x+
**Status**: Production-Ready ✅
