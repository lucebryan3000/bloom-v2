# Node.js Fundamentals

```yaml
id: nodejs_01_fundamentals
topic: Node.js
file_role: Node.js fundamentals, runtime, V8 engine, REPL, package management
profile: full
difficulty_level: beginner
kb_version: v3.1
prerequisites: []
related_topics:
  - Event Loop (03-EVENT-LOOP.md)
  - Async Programming (02-ASYNC-PROGRAMMING.md)
  - Modules (04-MODULES.md)
embedding_keywords:
  - nodejs
  - node.js fundamentals
  - v8 engine
  - npm
  - package.json
  - runtime
  - javascript server
last_reviewed: 2025-11-17
```

## What is Node.js?

**Node.js** is a **JavaScript runtime** built on Chrome's V8 JavaScript engine. It allows you to run JavaScript on the server side, outside of a web browser.

**Key characteristics:**
- **JavaScript everywhere** - Same language for frontend and backend
- **Event-driven** - Non-blocking I/O model
- **Single-threaded** - With event loop for concurrency
- **Fast** - V8 engine compiles JS to machine code
- **Large ecosystem** - npm with 2+ million packages

## Installation

### Install Node.js

```bash
# Using package manager (recommended)
# macOS with Homebrew
brew install node

# Ubuntu/Debian
sudo apt update
sudo apt install nodejs npm

# Windows with Chocolatey
choco install nodejs

# Or download installer from https://nodejs.org/
```

### Verify Installation

```bash
# Check Node.js version
node --version  # v20.x.x or higher

# Check npm version
npm --version   # 10.x.x or higher

# Check installation
node -e "console.log('Node.js is working!')"
```

### Version Management

```bash
# Using nvm (Node Version Manager)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# Install specific version
nvm install 20
nvm install 18

# Use specific version
nvm use 20

# List installed versions
nvm list

# Set default version
nvm alias default 20
```

## First Program

### Hello World

```javascript
// hello.js
console.log('Hello, Node.js!');
```

```bash
# Run the program
node hello.js
```

### HTTP Server

```javascript
// server.js
import http from 'node:http';

const server = http.createServer((req, res) => {
  res.statusCode = 200;
  res.setHeader('Content-Type', 'text/plain');
  res.end('Hello World\n');
});

const port = 3000;
server.listen(port, () => {
  console.log(`Server running at http://localhost:${port}/`);
});
```

```bash
# Run the server
node server.js
```

## REPL (Read-Eval-Print Loop)

### Interactive Shell

```bash
# Start REPL
node

# Try commands
> 2 + 2
4
> console.log('Hello')
Hello
undefined
> const arr = [1, 2, 3]
undefined
> arr.map(x => x * 2)
[ 2, 4, 6 ]

# Exit REPL
> .exit
# Or press Ctrl+C twice
```

### REPL Commands

```bash
.help      # Show help
.break     # Break out of multi-line expression
.clear     # Clear the REPL context
.exit      # Exit REPL
.save file # Save session to file
.load file # Load file into session
```

## Package Management

### package.json

```bash
# Initialize new project
npm init

# Quick initialization
npm init -y
```

```json
{
  "name": "my-project",
  "version": "1.0.0",
  "description": "My Node.js project",
  "main": "index.js",
  "type": "module",
  "scripts": {
    "start": "node index.js",
    "dev": "node --watch index.js",
    "test": "jest"
  },
  "keywords": ["node", "javascript"],
  "author": "Your Name",
  "license": "MIT",
  "dependencies": {
    "express": "^4.18.0"
  },
  "devDependencies": {
    "jest": "^29.0.0"
  }
}
```

### npm Commands

```bash
# Install package
npm install express
npm install lodash --save        # Add to dependencies
npm install jest --save-dev      # Add to devDependencies

# Install all dependencies
npm install

# Update packages
npm update
npm update express

# Remove package
npm uninstall express

# Global installation
npm install -g nodemon

# List installed packages
npm list
npm list --depth=0  # Top level only

# Check for outdated packages
npm outdated

# View package info
npm info express

# Search packages
npm search http server
```

## Node.js Architecture

### V8 Engine

```
┌─────────────────────────────────┐
│         Your JavaScript         │
│            Code                 │
└──────────────┬──────────────────┘
               │
               ▼
┌─────────────────────────────────┐
│         V8 Engine               │
│  - Parses JavaScript            │
│  - Compiles to machine code     │
│  - Executes code                │
│  - Manages memory (GC)          │
└──────────────┬──────────────────┘
               │
               ▼
┌─────────────────────────────────┐
│         libuv                   │
│  - Event loop                   │
│  - Async I/O                    │
│  - Thread pool                  │
└──────────────┬──────────────────┘
               │
               ▼
┌─────────────────────────────────┐
│      Operating System           │
└─────────────────────────────────┘
```

### Core Components

1. **V8 Engine** - JavaScript execution
2. **libuv** - Event loop and async I/O
3. **C++ bindings** - Bridge between JS and C++
4. **Core modules** - Built-in functionality (fs, http, crypto, etc.)

## Global Objects

```javascript
// Console
console.log('Message');
console.error('Error');
console.warn('Warning');
console.dir(object, { depth: null });

// Process
console.log(process.version);        // Node.js version
console.log(process.platform);       // OS platform
console.log(process.cwd());          // Current directory
console.log(process.env.NODE_ENV);   // Environment variable
console.log(process.argv);           // Command line arguments

// Timers
setTimeout(() => console.log('Delayed'), 1000);
setInterval(() => console.log('Repeated'), 1000);
setImmediate(() => console.log('Immediate'));

// __dirname and __filename (CommonJS only)
console.log(__dirname);   // Current directory path
console.log(__filename);  // Current file path

// For ES modules:
import { fileURLToPath } from 'url';
import { dirname } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
```

## Command Line Arguments

```javascript
// process.argv array contains:
// [0] - Path to Node.js executable
// [1] - Path to JavaScript file
// [2...] - Additional arguments

// args.js
console.log('Arguments:', process.argv.slice(2));

// Run: node args.js foo bar --name=Alice
// Output: Arguments: [ 'foo', 'bar', '--name=Alice' ]

// Parse arguments manually
const args = process.argv.slice(2);
const options = {};

args.forEach(arg => {
  if (arg.startsWith('--')) {
    const [key, value] = arg.slice(2).split('=');
    options[key] = value || true;
  }
});

console.log(options); // { name: 'Alice' }
```

## Environment Variables

```javascript
// Access environment variables
console.log(process.env.NODE_ENV);
console.log(process.env.PORT);
console.log(process.env.DATABASE_URL);

// Set environment variables
process.env.MY_VAR = 'value';

// Using dotenv package for development
import 'dotenv/config';

// Now variables from .env file are loaded
console.log(process.env.API_KEY);
```

```.env
# .env file
NODE_ENV=development
PORT=3000
DATABASE_URL=postgresql://localhost/mydb
API_KEY=secret123
```

## Built-in Modules

```javascript
// File System
import fs from 'node:fs';
import { readFile, writeFile } from 'node:fs/promises';

// Path
import path from 'node:path';
const fullPath = path.join(__dirname, 'file.txt');

// HTTP
import http from 'node:http';

// HTTPS
import https from 'node:https';

// Events
import { EventEmitter } from 'node:events';

// Stream
import { Readable, Writable } from 'node:stream';

// Buffer
import { Buffer } from 'node:buffer';

// Crypto
import crypto from 'node:crypto';

// OS
import os from 'node:os';

// Utilities
import util from 'node:util';

// URL
import { URL } from 'node:url';

// Querystring
import querystring from 'node:querystring';
```

## Process Management

### Exit Codes

```javascript
// Exit process
process.exit(0); // Success
process.exit(1); // Failure

// Exit handlers
process.on('exit', (code) => {
  console.log(`Process exiting with code: ${code}`);
});

// SIGTERM/SIGINT handlers
process.on('SIGTERM', () => {
  console.log('SIGTERM received');
  // Cleanup and exit
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('SIGINT received (Ctrl+C)');
  process.exit(0);
});
```

### Standard Streams

```javascript
// stdin (input)
process.stdin.on('data', (data) => {
  console.log(`You typed: ${data.toString()}`);
});

// stdout (output)
process.stdout.write('Hello\n');

// stderr (errors)
process.stderr.write('Error message\n');

// Example: Read from stdin
import readline from 'node:readline';

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
});

rl.question('What is your name? ', (name) => {
  console.log(`Hello, ${name}!`);
  rl.close();
});
```

## Working with Files

### Basic File Operations

```javascript
import { readFile, writeFile, appendFile } from 'node:fs/promises';

// Read file
const data = await readFile('file.txt', 'utf8');
console.log(data);

// Write file
await writeFile('output.txt', 'Hello World', 'utf8');

// Append to file
await appendFile('log.txt', 'New log entry\n', 'utf8');

// Check if file exists
import { access } from 'node:fs/promises';
import { constants } from 'node:fs';

try {
  await access('file.txt', constants.F_OK);
  console.log('File exists');
} catch {
  console.log('File does not exist');
}
```

## Error Handling

### Try/Catch

```javascript
// Synchronous error handling
try {
  const data = JSON.parse(invalidJSON);
} catch (err) {
  console.error('Parse error:', err.message);
}

// Async error handling
try {
  const data = await readFile('file.txt', 'utf8');
} catch (err) {
  if (err.code === 'ENOENT') {
    console.error('File not found');
  } else {
    console.error('Error:', err);
  }
}
```

### Uncaught Exceptions

```javascript
// Handle uncaught exceptions
process.on('uncaughtException', (err) => {
  console.error('Uncaught Exception:', err);
  // Log error and exit
  process.exit(1);
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
  process.exit(1);
});
```

## Debugging

### Built-in Debugger

```bash
# Start with debugger
node inspect app.js

# Commands:
# cont, c    - Continue execution
# next, n    - Step to next line
# step, s    - Step into function
# out, o     - Step out of function
# pause      - Pause execution
```

### Chrome DevTools

```bash
# Start with --inspect
node --inspect app.js

# Or with break on start
node --inspect-brk app.js

# Open chrome://inspect in Chrome
# Click "Open dedicated DevTools for Node"
```

### Debug with VS Code

```json
// .vscode/launch.json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "node",
      "request": "launch",
      "name": "Launch Program",
      "skipFiles": ["<node_internals>/**"],
      "program": "${workspaceFolder}/index.js"
    }
  ]
}
```

## npm Scripts

```json
{
  "scripts": {
    "start": "node index.js",
    "dev": "node --watch index.js",
    "test": "jest",
    "lint": "eslint .",
    "format": "prettier --write .",
    "build": "tsc",
    "clean": "rm -rf dist"
  }
}
```

```bash
# Run scripts
npm start
npm run dev
npm test

# Pass arguments
npm run dev -- --port=4000
```

## Best Practices

### ✅ DO

```javascript
// Use ES modules (type: "module" in package.json)
import fs from 'node:fs';

// Use async/await
const data = await readFile('file.txt');

// Handle errors
try {
  await operation();
} catch (err) {
  console.error('Error:', err);
}

// Use environment variables
const port = process.env.PORT || 3000;

// Use path.join for cross-platform paths
const filePath = path.join(__dirname, 'data', 'file.txt');
```

### ❌ DON'T

```javascript
// Don't use synchronous methods in production
const data = fs.readFileSync('file.txt'); // Blocks!

// Don't ignore errors
await readFile('file.txt'); // What if error?

// Don't use callbacks when promises are available
fs.readFile('file.txt', (err, data) => { }); // Use promises!

// Don't hardcode paths
const file = '/home/user/data/file.txt'; // Use path.join!
```

## Common Pitfalls

1. **Blocking event loop** - Use async operations
2. **Memory leaks** - Clean up listeners, timers, connections
3. **Unhandled errors** - Always handle errors
4. **Callback hell** - Use async/await
5. **Global state** - Avoid global variables
6. **Synchronous I/O** - Use async methods

## AI Pair Programming Notes

**When writing Node.js code:**

1. **Use async/await** - Modern, readable async code
2. **Handle all errors** - try/catch or .catch()
3. **Use ES modules** - import/export over require
4. **Validate environment** - Check required env vars
5. **Use built-in modules** - Prefer 'node:fs' over 'fs'
6. **Don't block event loop** - Use async operations
7. **Clean up resources** - Close connections, clear timers
8. **Use path.join** - Cross-platform file paths
9. **Set up linting** - ESLint for code quality
10. **Write tests** - Jest or similar framework

**Common mistakes:**
- Using synchronous methods (readFileSync, etc.)
- Not handling promise rejections
- Blocking event loop with CPU work
- Ignoring error codes (ENOENT, EACCES, etc.)
- Not validating environment variables
- Hardcoding file paths instead of using path module
- Global variables and state
- Not closing database connections
- Memory leaks from unclosed resources
- Missing package.json scripts

## Next Steps

1. **02-ASYNC-PROGRAMMING.md** - Promises, async/await, callbacks
2. **03-EVENT-LOOP.md** - Understanding the event loop
3. **04-MODULES.md** - Module systems (CommonJS, ES modules)
4. **05-FILE-SYSTEM.md** - Working with files
5. **06-HTTP-NETWORKING.md** - Building HTTP servers

## Additional Resources

- Node.js Documentation: https://nodejs.org/docs/
- npm Documentation: https://docs.npmjs.com/
- Node.js Guides: https://nodejs.org/en/docs/guides/
- Node.js Best Practices: https://github.com/goldbergyoni/nodebestpractices
- Learn Node.js: https://nodejs.dev/en/learn/
