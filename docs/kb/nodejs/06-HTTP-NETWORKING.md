# Node.js HTTP & Networking

```yaml
id: nodejs_06_http_networking
topic: Node.js
file_role: HTTP servers, HTTPS, requests, routing, middleware patterns
profile: full
difficulty_level: intermediate
kb_version: v3.1
prerequisites:
  - Fundamentals (01-FUNDAMENTALS.md)
  - Async Programming (02-ASYNC-PROGRAMMING.md)
  - Event Loop (03-EVENT-LOOP.md)
related_topics:
  - Streams (07-STREAMS-BUFFERS.md)
  - Best Practices (11-BEST-PRACTICES.md)
embedding_keywords:
  - nodejs http
  - http server
  - https
  - http requests
  - http headers
  - routing
  - rest api
last_reviewed: 2025-11-17
```

## HTTP Module Overview

**Core HTTP capabilities:**

1. **Create HTTP servers** - Handle incoming requests
2. **Make HTTP requests** - Call external APIs
3. **Parse URLs and headers** - Extract request data
4. **Send responses** - Return data to clients
5. **Handle routing** - Route requests to handlers

```javascript
// ESM
import http from 'node:http';
import https from 'node:https';

// CommonJS
const http = require('http');
const https = require('https');
```

## Creating HTTP Servers

### Basic HTTP Server

```javascript
import http from 'node:http';

// ✅ GOOD - Basic server
const server = http.createServer((req, res) => {
  res.statusCode = 200;
  res.setHeader('Content-Type', 'text/plain');
  res.end('Hello World\n');
});

const PORT = 3000;
server.listen(PORT, () => {
  console.log(`Server running at http://localhost:${PORT}/`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, closing server');
  server.close(() => {
    console.log('Server closed');
    process.exit(0);
  });
});
```

### Request and Response Objects

```javascript
const server = http.createServer((req, res) => {
  // Request object properties
  console.log('Method:', req.method);       // GET, POST, etc.
  console.log('URL:', req.url);             // /path?query=value
  console.log('Headers:', req.headers);     // { 'user-agent': '...', ... }
  console.log('HTTP Version:', req.httpVersion); // '1.1'

  // Response methods
  res.statusCode = 200;
  res.setHeader('Content-Type', 'application/json');
  res.write(JSON.stringify({ message: 'Hello' }));
  res.end(); // Finish response

  // Or combine write + end
  res.end(JSON.stringify({ message: 'Hello' }));
});
```

### Handling Different HTTP Methods

```javascript
import http from 'node:http';

const server = http.createServer((req, res) => {
  const { method, url } = req;

  if (method === 'GET' && url === '/') {
    res.statusCode = 200;
    res.setHeader('Content-Type', 'text/html');
    res.end('<h1>Home Page</h1>');
  } else if (method === 'GET' && url === '/api/users') {
    res.statusCode = 200;
    res.setHeader('Content-Type', 'application/json');
    res.end(JSON.stringify([{ id: 1, name: 'Alice' }]));
  } else if (method === 'POST' && url === '/api/users') {
    let body = '';

    req.on('data', chunk => {
      body += chunk.toString();
    });

    req.on('end', () => {
      try {
        const data = JSON.parse(body);
        res.statusCode = 201;
        res.setHeader('Content-Type', 'application/json');
        res.end(JSON.stringify({ id: 2, ...data }));
      } catch (err) {
        res.statusCode = 400;
        res.end(JSON.stringify({ error: 'Invalid JSON' }));
      }
    });
  } else {
    res.statusCode = 404;
    res.setHeader('Content-Type', 'application/json');
    res.end(JSON.stringify({ error: 'Not Found' }));
  }
});

server.listen(3000);
```

### Parsing Request Bodies

```javascript
// ✅ GOOD - Parse JSON body
function parseJSONBody(req) {
  return new Promise((resolve, reject) => {
    let body = '';

    req.on('data', chunk => {
      body += chunk.toString();

      // Prevent large payloads
      if (body.length > 1e6) { // 1MB limit
        req.destroy();
        reject(new Error('Request body too large'));
      }
    });

    req.on('end', () => {
      try {
        const data = JSON.parse(body);
        resolve(data);
      } catch (err) {
        reject(new Error('Invalid JSON'));
      }
    });

    req.on('error', reject);
  });
}

// Usage
const server = http.createServer(async (req, res) => {
  if (req.method === 'POST') {
    try {
      const data = await parseJSONBody(req);
      console.log('Received:', data);

      res.statusCode = 200;
      res.setHeader('Content-Type', 'application/json');
      res.end(JSON.stringify({ success: true, data }));
    } catch (err) {
      res.statusCode = 400;
      res.end(JSON.stringify({ error: err.message }));
    }
  }
});
```

## URL Routing

### Basic Router Pattern

```javascript
import http from 'node:http';
import { URL } from 'node:url';

class Router {
  constructor() {
    this.routes = {
      GET: new Map(),
      POST: new Map(),
      PUT: new Map(),
      DELETE: new Map(),
    };
  }

  get(path, handler) {
    this.routes.GET.set(path, handler);
  }

  post(path, handler) {
    this.routes.POST.set(path, handler);
  }

  put(path, handler) {
    this.routes.PUT.set(path, handler);
  }

  delete(path, handler) {
    this.routes.DELETE.set(path, handler);
  }

  handle(req, res) {
    const url = new URL(req.url, `http://${req.headers.host}`);
    const handler = this.routes[req.method]?.get(url.pathname);

    if (handler) {
      handler(req, res);
    } else {
      res.statusCode = 404;
      res.end('Not Found');
    }
  }
}

// Usage
const router = new Router();

router.get('/', (req, res) => {
  res.end('Home Page');
});

router.get('/api/users', (req, res) => {
  res.setHeader('Content-Type', 'application/json');
  res.end(JSON.stringify([{ id: 1, name: 'Alice' }]));
});

router.post('/api/users', async (req, res) => {
  const data = await parseJSONBody(req);
  res.statusCode = 201;
  res.setHeader('Content-Type', 'application/json');
  res.end(JSON.stringify({ id: 2, ...data }));
});

const server = http.createServer((req, res) => {
  router.handle(req, res);
});

server.listen(3000);
```

### Route Parameters

```javascript
class Router {
  // ... previous code ...

  matchRoute(method, pathname) {
    const routes = this.routes[method];

    for (const [pattern, handler] of routes) {
      const regex = new RegExp('^' + pattern.replace(/:\w+/g, '([^/]+)') + '$');
      const match = pathname.match(regex);

      if (match) {
        const keys = [...pattern.matchAll(/:(\w+)/g)].map(m => m[1]);
        const params = {};

        keys.forEach((key, index) => {
          params[key] = match[index + 1];
        });

        return { handler, params };
      }
    }

    return null;
  }

  handle(req, res) {
    const url = new URL(req.url, `http://${req.headers.host}`);
    const match = this.matchRoute(req.method, url.pathname);

    if (match) {
      req.params = match.params;
      match.handler(req, res);
    } else {
      res.statusCode = 404;
      res.end('Not Found');
    }
  }
}

// Usage
router.get('/api/users/:id', (req, res) => {
  const { id } = req.params;
  res.setHeader('Content-Type', 'application/json');
  res.end(JSON.stringify({ id, name: 'Alice' }));
});

// GET /api/users/123 → params = { id: '123' }
```

### Query Parameters

```javascript
import { URL } from 'node:url';

const server = http.createServer((req, res) => {
  const url = new URL(req.url, `http://${req.headers.host}`);

  // Extract query parameters
  const searchParams = url.searchParams;
  const page = searchParams.get('page') || '1';
  const limit = searchParams.get('limit') || '10';

  console.log(`Page: ${page}, Limit: ${limit}`);

  // GET /api/users?page=2&limit=20
  // → page = '2', limit = '20'

  res.setHeader('Content-Type', 'application/json');
  res.end(JSON.stringify({
    page: parseInt(page),
    limit: parseInt(limit),
    users: [],
  }));
});
```

## HTTPS Servers

### Creating HTTPS Server

```javascript
import https from 'node:https';
import fs from 'node:fs';

// ✅ GOOD - HTTPS server with SSL/TLS
const options = {
  key: fs.readFileSync('private-key.pem'),
  cert: fs.readFileSync('certificate.pem'),
};

const server = https.createServer(options, (req, res) => {
  res.statusCode = 200;
  res.setHeader('Content-Type', 'text/plain');
  res.end('Secure Hello World\n');
});

server.listen(443, () => {
  console.log('HTTPS server running on port 443');
});
```

### Self-Signed Certificate (Development)

```bash
# Generate self-signed certificate
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes
```

```javascript
// Use in development
const options = {
  key: fs.readFileSync('key.pem'),
  cert: fs.readFileSync('cert.pem'),
};

const server = https.createServer(options, handler);
```

## Making HTTP Requests

### GET Request

```javascript
import https from 'node:https';

// ✅ GOOD - Basic GET request
function httpsGet(url) {
  return new Promise((resolve, reject) => {
    https.get(url, (res) => {
      let data = '';

      res.on('data', chunk => {
        data += chunk;
      });

      res.on('end', () => {
        resolve({
          statusCode: res.statusCode,
          headers: res.headers,
          body: data,
        });
      });
    }).on('error', reject);
  });
}

// Usage
const result = await httpsGet('https://api.example.com/users');
console.log(JSON.parse(result.body));
```

### POST Request

```javascript
import https from 'node:https';

// ✅ GOOD - POST request with JSON body
function httpsPost(url, data) {
  return new Promise((resolve, reject) => {
    const urlObj = new URL(url);
    const postData = JSON.stringify(data);

    const options = {
      hostname: urlObj.hostname,
      port: 443,
      path: urlObj.pathname + urlObj.search,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData),
      },
    };

    const req = https.request(options, (res) => {
      let body = '';

      res.on('data', chunk => {
        body += chunk;
      });

      res.on('end', () => {
        resolve({
          statusCode: res.statusCode,
          headers: res.headers,
          body,
        });
      });
    });

    req.on('error', reject);
    req.write(postData);
    req.end();
  });
}

// Usage
const result = await httpsPost('https://api.example.com/users', {
  name: 'Alice',
  email: 'alice@example.com',
});
```

### Modern Fetch API (Node.js 18+)

```javascript
// ✅ RECOMMENDED - Use native fetch (Node.js 18+)
// GET request
const response = await fetch('https://api.example.com/users');
const users = await response.json();

// POST request
const response = await fetch('https://api.example.com/users', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    name: 'Alice',
    email: 'alice@example.com',
  }),
});

const user = await response.json();

// With error handling
try {
  const response = await fetch('https://api.example.com/users');

  if (!response.ok) {
    throw new Error(`HTTP error! status: ${response.status}`);
  }

  const data = await response.json();
  console.log(data);
} catch (err) {
  console.error('Fetch error:', err);
}
```

## Response Headers

### Common Headers

```javascript
const server = http.createServer((req, res) => {
  // Content type
  res.setHeader('Content-Type', 'application/json');

  // CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  // Caching
  res.setHeader('Cache-Control', 'public, max-age=3600');
  res.setHeader('ETag', '"abc123"');

  // Security
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'DENY');
  res.setHeader('Strict-Transport-Security', 'max-age=31536000');

  // Custom headers
  res.setHeader('X-API-Version', '1.0.0');

  res.end('Response');
});
```

### Setting Multiple Headers

```javascript
// Method 1: Individual setHeader calls
res.setHeader('Content-Type', 'application/json');
res.setHeader('Cache-Control', 'no-cache');

// Method 2: writeHead
res.writeHead(200, {
  'Content-Type': 'application/json',
  'Cache-Control': 'no-cache',
});
res.end(JSON.stringify({ message: 'Hello' }));
```

## Middleware Pattern

```javascript
// ✅ GOOD - Middleware pattern
class App {
  constructor() {
    this.middleware = [];
  }

  use(fn) {
    this.middleware.push(fn);
  }

  async handle(req, res) {
    let index = 0;

    const next = async () => {
      if (index < this.middleware.length) {
        const fn = this.middleware[index++];
        await fn(req, res, next);
      }
    };

    await next();
  }

  listen(port) {
    const server = http.createServer((req, res) => {
      this.handle(req, res);
    });

    server.listen(port);
    return server;
  }
}

// Usage
const app = new App();

// Logger middleware
app.use(async (req, res, next) => {
  console.log(`${req.method} ${req.url}`);
  await next();
});

// JSON body parser middleware
app.use(async (req, res, next) => {
  if (req.method === 'POST' || req.method === 'PUT') {
    try {
      req.body = await parseJSONBody(req);
    } catch (err) {
      res.statusCode = 400;
      res.end(JSON.stringify({ error: 'Invalid JSON' }));
      return;
    }
  }
  await next();
});

// Route handler
app.use(async (req, res) => {
  if (req.url === '/api/users' && req.method === 'POST') {
    console.log('Creating user:', req.body);
    res.statusCode = 201;
    res.setHeader('Content-Type', 'application/json');
    res.end(JSON.stringify({ id: 1, ...req.body }));
  } else {
    res.statusCode = 404;
    res.end('Not Found');
  }
});

app.listen(3000);
```

## Error Handling

```javascript
// ✅ GOOD - Centralized error handling
function errorHandler(err, req, res) {
  console.error('Error:', err);

  const statusCode = err.statusCode || 500;
  const message = err.message || 'Internal Server Error';

  res.statusCode = statusCode;
  res.setHeader('Content-Type', 'application/json');
  res.end(JSON.stringify({
    error: {
      message,
      ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
    },
  }));
}

const server = http.createServer(async (req, res) => {
  try {
    // Handle request
    if (req.url === '/api/users') {
      const data = await fetchUsers();
      res.setHeader('Content-Type', 'application/json');
      res.end(JSON.stringify(data));
    } else {
      const err = new Error('Not Found');
      err.statusCode = 404;
      throw err;
    }
  } catch (err) {
    errorHandler(err, req, res);
  }
});
```

## AI Pair Programming Notes

**When building HTTP servers:**

1. **Use frameworks** - Express, Fastify, Koa for production (don't reinvent)
2. **Handle request body** carefully - Set size limits, validate input
3. **Always set Content-Type** - Browsers/clients need to know response format
4. **Implement error handling** - Centralized error handler for all routes
5. **Use HTTPS in production** - Never send sensitive data over HTTP
6. **Set security headers** - X-Content-Type-Options, X-Frame-Options, etc.
7. **Implement CORS** if needed - For cross-origin requests
8. **Use fetch()** for requests (Node.js 18+) - Native, modern, Promise-based
9. **Graceful shutdown** - Handle SIGTERM, close server properly
10. **Rate limiting** - Prevent abuse in production

**Common HTTP mistakes:**
- Not handling request body streaming properly
- Forgetting to call res.end()
- Setting headers after response started
- Not validating/sanitizing input
- Missing error handlers (crashes server)
- Not setting Content-Type header
- Synchronous operations in handlers (blocks event loop)
- Not implementing request timeouts
- Exposing stack traces in production
- Not using HTTPS in production

## Next Steps

1. **07-STREAMS-BUFFERS.md** - Working with streams for large payloads
2. **08-ERROR-HANDLING.md** - Comprehensive error handling
3. **11-BEST-PRACTICES.md** - Production best practices

## Additional Resources

- HTTP Module: https://nodejs.org/api/http.html
- HTTPS Module: https://nodejs.org/api/https.html
- URL Module: https://nodejs.org/api/url.html
- Fetch API: https://nodejs.org/api/globals.html#fetch
- Express.js: https://expressjs.com/
- Fastify: https://www.fastify.io/
