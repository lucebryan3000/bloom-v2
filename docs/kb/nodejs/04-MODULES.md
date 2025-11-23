# Node.js Modules

```yaml
id: nodejs_04_modules
topic: Node.js
file_role: Module systems (CommonJS, ES modules), imports, exports, packages
profile: full
difficulty_level: intermediate
kb_version: v3.1
prerequisites:
  - Fundamentals (01-FUNDAMENTALS.md)
related_topics:
  - Best Practices (11-BEST-PRACTICES.md)
embedding_keywords:
  - nodejs modules
  - commonjs
  - es modules
  - import export
  - require
  - module.exports
  - esm
last_reviewed: 2025-11-17
```

## Module Systems Overview

Node.js has **two module systems**:

1. **CommonJS (CJS)** - Traditional Node.js module system
2. **ECMAScript Modules (ESM)** - Modern JavaScript standard

**Key Differences:**

| Feature | CommonJS | ES Modules |
|---------|----------|------------|
| Syntax | `require()` / `module.exports` | `import` / `export` |
| Loading | Synchronous | Asynchronous |
| File Extension | `.js` (default), `.cjs` | `.mjs`, `.js` (with "type": "module") |
| Top-level await | ❌ Not supported | ✅ Supported |
| Dynamic imports | ❌ require() is sync | ✅ `import()` is async |
| `__dirname`, `__filename` | ✅ Available | ❌ Not available (use `import.meta.url`) |
| Tree-shaking | ❌ Limited | ✅ Better optimization |

## CommonJS Modules

### Basic Exports

```javascript
// math.js - Exporting functions
function add(a, b) {
  return a + b;
}

function subtract(a, b) {
  return a - b;
}

// Method 1: Named exports
module.exports.add = add;
module.exports.subtract = subtract;

// Method 2: Object assignment
module.exports = {
  add,
  subtract,
};

// Method 3: Shorthand (exports is reference to module.exports)
exports.add = add;
exports.subtract = subtract;

// ❌ WRONG - This doesn't work (breaks reference)
exports = { add, subtract };
```

### Basic Imports

```javascript
// app.js - Importing module
const math = require('./math');

console.log(math.add(2, 3)); // 5
console.log(math.subtract(5, 2)); // 3

// Destructuring
const { add, subtract } = require('./math');

console.log(add(2, 3)); // 5
```

### Default Export Pattern

```javascript
// user.js - Single export (class)
class User {
  constructor(name) {
    this.name = name;
  }

  greet() {
    return `Hello, ${this.name}`;
  }
}

module.exports = User;

// app.js - Import default
const User = require('./user');

const alice = new User('Alice');
console.log(alice.greet()); // Hello, Alice
```

### Mixed Exports

```javascript
// database.js - Mix of default and named exports
class Database {
  connect() { /* ... */ }
}

function query(sql) { /* ... */ }

function close() { /* ... */ }

// Default export
module.exports = Database;

// Named exports on default
module.exports.query = query;
module.exports.close = close;

// app.js - Using mixed exports
const Database = require('./database');
const { query, close } = require('./database');

const db = new Database();
db.connect();

query('SELECT * FROM users');
close();
```

### Module Caching

```javascript
// counter.js
let count = 0;

module.exports = {
  increment() {
    count++;
  },
  get() {
    return count;
  },
};

// app.js
const counter1 = require('./counter');
const counter2 = require('./counter');

counter1.increment();
console.log(counter1.get()); // 1
console.log(counter2.get()); // 1 (same instance, cached!)

// counter1 and counter2 are the same object
console.log(counter1 === counter2); // true

// ⚠️ Clear cache if needed (rare, testing only)
delete require.cache[require.resolve('./counter')];
const counter3 = require('./counter');
console.log(counter3.get()); // 0 (fresh instance)
```

### Circular Dependencies

```javascript
// a.js
exports.loaded = false;

const b = require('./b');

console.log('In a.js, b.loaded =', b.loaded);

exports.loaded = true;
console.log('a.js loaded');

// b.js
exports.loaded = false;

const a = require('./a'); // Circular dependency!

console.log('In b.js, a.loaded =', a.loaded); // false (partial)

exports.loaded = true;
console.log('b.js loaded');

// main.js
const a = require('./a');
const b = require('./b');

console.log('In main, a.loaded =', a.loaded); // true
console.log('In main, b.loaded =', b.loaded); // true

// Output:
// In b.js, a.loaded = false  <-- a is not fully loaded yet
// b.js loaded
// In a.js, b.loaded = true
// a.js loaded
// In main, a.loaded = true
// In main, b.loaded = true
```

### CommonJS Patterns

```javascript
// ✅ GOOD - Factory function pattern
// logger.js
module.exports = function createLogger(name) {
  return {
    log(message) {
      console.log(`[${name}] ${message}`);
    },
  };
};

// Usage
const createLogger = require('./logger');
const logger = createLogger('MyApp');
logger.log('Hello'); // [MyApp] Hello

// ✅ GOOD - Singleton pattern
// database.js
let instance = null;

class Database {
  constructor() {
    if (instance) {
      return instance;
    }
    this.connected = false;
    instance = this;
  }

  connect() {
    this.connected = true;
  }
}

module.exports = new Database(); // Export instance, not class

// ✅ GOOD - Module with initialization
// config.js
const fs = require('fs');

let config = null;

function loadConfig() {
  if (!config) {
    const data = fs.readFileSync('config.json', 'utf8');
    config = JSON.parse(data);
  }
  return config;
}

module.exports = {
  get: loadConfig,
};
```

## ES Modules (ESM)

### Enabling ES Modules

**Method 1: package.json**
```json
{
  "type": "module"
}
```

**Method 2: .mjs extension**
```javascript
// math.mjs - Always treated as ES module
export function add(a, b) {
  return a + b;
}
```

**Method 3: .cjs extension**
```javascript
// utils.cjs - Always treated as CommonJS
module.exports = { /* ... */ };
```

### Named Exports

```javascript
// math.mjs
export function add(a, b) {
  return a + b;
}

export function subtract(a, b) {
  return a - b;
}

export const PI = 3.14159;

// Alternative: Export list
function multiply(a, b) {
  return a * b;
}

function divide(a, b) {
  return a / b;
}

export { multiply, divide };

// Rename exports
const secret = 42;
export { secret as answer };
```

### Named Imports

```javascript
// app.mjs
import { add, subtract } from './math.mjs';

console.log(add(2, 3)); // 5
console.log(subtract(5, 2)); // 3

// Import with rename
import { answer as secretNumber } from './math.mjs';
console.log(secretNumber); // 42

// Import all
import * as math from './math.mjs';
console.log(math.add(2, 3)); // 5
console.log(math.PI); // 3.14159
```

### Default Exports

```javascript
// user.mjs
export default class User {
  constructor(name) {
    this.name = name;
  }

  greet() {
    return `Hello, ${this.name}`;
  }
}

// Alternative syntax
class User {
  /* ... */
}
export default User;

// app.mjs
import User from './user.mjs';

const alice = new User('Alice');
console.log(alice.greet());
```

### Mixed Exports

```javascript
// database.mjs - Default + named exports
export default class Database {
  connect() { /* ... */ }
}

export function query(sql) { /* ... */ }
export function close() { /* ... */ }

// app.mjs
import Database, { query, close } from './database.mjs';

const db = new Database();
db.connect();
query('SELECT * FROM users');
close();
```

### Dynamic Imports

```javascript
// ✅ GOOD - Conditional loading
async function loadModule(moduleName) {
  if (moduleName === 'math') {
    const math = await import('./math.mjs');
    return math;
  } else {
    const utils = await import('./utils.mjs');
    return utils;
  }
}

// Usage
const math = await loadModule('math');
console.log(math.add(2, 3));

// ✅ GOOD - Lazy loading
button.addEventListener('click', async () => {
  const { processData } = await import('./heavy-module.mjs');
  await processData();
});

// ✅ GOOD - Code splitting
async function loadFeature(featureName) {
  try {
    const module = await import(`./features/${featureName}.mjs`);
    module.initialize();
  } catch (err) {
    console.error(`Failed to load feature ${featureName}:`, err);
  }
}
```

### Top-Level Await

```javascript
// ✅ GOOD - Top-level await (ESM only!)
// config.mjs
import fs from 'fs/promises';

const config = JSON.parse(
  await fs.readFile('config.json', 'utf8')
);

export default config;

// database.mjs
import Database from './db.mjs';

const db = new Database();
await db.connect(); // Wait for connection

export default db;

// ❌ NOT AVAILABLE in CommonJS
// config.js (CommonJS)
const config = await loadConfig(); // SyntaxError!
```

### ESM Built-in Replacements

```javascript
// __dirname and __filename in ESM
import { fileURLToPath } from 'url';
import { dirname } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

console.log(__filename); // /path/to/current/file.mjs
console.log(__dirname);  // /path/to/current

// import.meta
console.log(import.meta.url); // file:///path/to/file.mjs

// Check if module is main
if (import.meta.url === `file://${process.argv[1]}`) {
  console.log('This is the main module');
}

// Resolve relative paths
import { resolve } from 'path';
const configPath = resolve(dirname(__filename), 'config.json');
```

## Interoperability (CommonJS ↔ ESM)

### Importing CommonJS from ESM

```javascript
// cjs-module.cjs (CommonJS)
module.exports = {
  add(a, b) {
    return a + b;
  },
};

module.exports.subtract = function(a, b) {
  return a - b;
};

// esm-module.mjs (ES Module)
import cjsModule from './cjs-module.cjs';

console.log(cjsModule.add(2, 3)); // 5
console.log(cjsModule.subtract(5, 2)); // 3

// Named imports DON'T work for most CommonJS modules
// import { add } from './cjs-module.cjs'; // May not work

// Use this pattern instead
import cjsModule from './cjs-module.cjs';
const { add, subtract } = cjsModule;
```

### Importing ESM from CommonJS

```javascript
// esm-module.mjs (ES Module)
export function add(a, b) {
  return a + b;
}

// cjs-module.cjs (CommonJS)
// ❌ Can't use require() for ESM
// const math = require('./esm-module.mjs'); // Error!

// ✅ GOOD - Use dynamic import()
async function loadMath() {
  const math = await import('./esm-module.mjs');
  console.log(math.add(2, 3)); // 5
}

loadMath();

// Or with IIFE
(async () => {
  const { add } = await import('./esm-module.mjs');
  console.log(add(2, 3));
})();
```

## Package.json Module Configuration

### Dual Package (Support Both)

```json
{
  "name": "my-package",
  "version": "1.0.0",
  "type": "module",
  "main": "./dist/index.cjs",
  "module": "./dist/index.mjs",
  "exports": {
    ".": {
      "import": "./dist/index.mjs",
      "require": "./dist/index.cjs"
    }
  }
}
```

### Conditional Exports

```json
{
  "exports": {
    ".": {
      "import": "./esm/index.mjs",
      "require": "./cjs/index.cjs",
      "default": "./esm/index.mjs"
    },
    "./utils": {
      "import": "./esm/utils.mjs",
      "require": "./cjs/utils.cjs"
    },
    "./package.json": "./package.json"
  }
}
```

## Built-in Modules

### Core Modules

```javascript
// CommonJS
const fs = require('fs');
const path = require('path');
const http = require('http');

// ES Modules (use 'node:' prefix for clarity)
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';

// Named imports from core modules
import { readFile, writeFile } from 'node:fs/promises';
import { join, resolve } from 'node:path';
```

### Core Module List

```javascript
// File System
import fs from 'node:fs';
import fspromises from 'node:fs/promises';

// Path
import path from 'node:path';

// HTTP/HTTPS
import http from 'node:http';
import https from 'node:https';

// Events
import { EventEmitter } from 'node:events';

// Streams
import { Readable, Writable, Transform } from 'node:stream';

// Buffer
import { Buffer } from 'node:buffer';

// Crypto
import crypto from 'node:crypto';

// OS
import os from 'node:os';

// Process
import process from 'node:process';

// URL
import { URL, URLSearchParams } from 'node:url';

// Utilities
import util from 'node:util';
```

## Module Resolution

### Resolution Algorithm

```javascript
// require('./module') or import './module.mjs'
// 1. Exact file: ./module.js, ./module.mjs
// 2. Add .js: ./module.js
// 3. Add .mjs: ./module.mjs
// 4. Add .json: ./module.json
// 5. Add .node: ./module.node
// 6. Directory with package.json: ./module/package.json → main field
// 7. Directory with index: ./module/index.js

// require('express') or import 'express'
// Looks in node_modules/:
// 1. ./node_modules/express
// 2. ../node_modules/express
// 3. ../../node_modules/express
// ... up to root
```

### Subpath Exports

```json
{
  "name": "my-library",
  "exports": {
    ".": "./index.js",
    "./feature-a": "./features/a.js",
    "./feature-b": "./features/b.js",
    "./package.json": "./package.json"
  }
}
```

```javascript
// Users can import
import lib from 'my-library';
import featureA from 'my-library/feature-a';
import featureB from 'my-library/feature-b';

// But NOT
import internal from 'my-library/internal/secret.js'; // Error!
```

## AI Pair Programming Notes

**When working with modules:**

1. **Use ESM for new projects** - Modern, better tooling support
2. **Use 'node:' prefix** for core modules in ESM
3. **Never mix module.exports and exports** - Pick one
4. **Don't reassign exports** - Use `module.exports = {}`
5. **Use package.json "type": "module"** for ESM
6. **Provide both CJS and ESM** for libraries (dual package)
7. **Use dynamic import()** to load ESM from CommonJS
8. **Avoid circular dependencies** - Refactor if needed
9. **Top-level await** only works in ESM
10. **Use import.meta.url** for __dirname in ESM

**Common module mistakes:**
- Reassigning exports object (breaks reference)
- Circular dependencies causing undefined exports
- Forgetting .mjs extension or package.json type
- Using require() with ESM modules
- Not handling dynamic import() promises
- Mixing CommonJS and ESM syntax
- Not using 'node:' prefix for core modules
- Forgetting to export functions/variables
- Importing from wrong path (missing ./ or ../)
- Not understanding module caching

## Next Steps

1. **05-FILE-SYSTEM.md** - Working with files and directories
2. **11-BEST-PRACTICES.md** - Module organization patterns
3. **06-HTTP-NETWORKING.md** - Building HTTP servers

## Additional Resources

- CommonJS Modules: https://nodejs.org/api/modules.html
- ECMAScript Modules: https://nodejs.org/api/esm.html
- Packages: https://nodejs.org/api/packages.html
- Module Resolution: https://nodejs.org/api/modules.html#modules_all_together
- Dual Package Guide: https://nodejs.org/api/packages.html#dual-commonjses-module-packages
