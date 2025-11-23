# Node.js Best Practices

```yaml
id: nodejs_11_best_practices
topic: Node.js
file_role: Best practices, production patterns, security, code quality
profile: full
difficulty_level: intermediate
kb_version: v3.1
prerequisites:
  - All previous files (01-10)
related_topics:
  - Security
  - Error Handling (08-ERROR-HANDLING.md)
  - Performance (10-PERFORMANCE.md)
embedding_keywords:
  - nodejs best practices
  - production ready
  - code quality
  - security
  - patterns
  - conventions
last_reviewed: 2025-11-17
```

## Best Practices Overview

**Core principles:**

1. **Security first** - Validate input, sanitize output
2. **Error handling** - Handle all errors explicitly
3. **Async patterns** - Use async/await, promises
4. **Code quality** - ESLint, TypeScript, testing
5. **Performance** - Profile, optimize, monitor

## Project Structure

### Recommended Structure

```
project/
├── src/
│   ├── controllers/
│   ├── models/
│   ├── services/
│   ├── routes/
│   ├── middleware/
│   ├── utils/
│   └── index.js
├── tests/
│   ├── unit/
│   ├── integration/
│   └── e2e/
├── config/
├── docs/
├── scripts/
├── .env.example
├── .gitignore
├── .eslintrc.js
├── package.json
├── README.md
└── tsconfig.json
```

### Separation of Concerns

```javascript
// ✅ GOOD - Layered architecture

// controllers/user-controller.js
export class UserController {
  constructor(userService) {
    this.userService = userService;
  }

  async getUser(req, res) {
    try {
      const user = await this.userService.findById(req.params.id);
      res.json(user);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  }
}

// services/user-service.js
export class UserService {
  constructor(userRepository) {
    this.userRepository = userRepository;
  }

  async findById(id) {
    const user = await this.userRepository.findById(id);
    if (!user) {
      throw new Error('User not found');
    }
    return user;
  }
}

// repositories/user-repository.js
export class UserRepository {
  constructor(db) {
    this.db = db;
  }

  async findById(id) {
    return this.db.query('SELECT * FROM users WHERE id = $1', [id]);
  }
}
```

## Configuration Management

### Environment Variables

```javascript
// ✅ GOOD - Use dotenv for development
import 'dotenv/config';

const config = {
  port: process.env.PORT || 3000,
  nodeEnv: process.env.NODE_ENV || 'development',
  database: {
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '5432'),
    name: process.env.DB_NAME,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
  },
  jwt: {
    secret: process.env.JWT_SECRET,
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  },
};

// Validate required config
const required = ['DB_NAME', 'DB_USER', 'DB_PASSWORD', 'JWT_SECRET'];
for (const key of required) {
  if (!process.env[key]) {
    throw new Error(`Missing required environment variable: ${key}`);
  }
}

export default config;
```

### Config Files

```javascript
// config/index.js
const development = {
  port: 3000,
  database: {
    host: 'localhost',
    port: 5432,
  },
  logging: {
    level: 'debug',
  },
};

const production = {
  port: process.env.PORT,
  database: {
    host: process.env.DB_HOST,
    port: parseInt(process.env.DB_PORT),
  },
  logging: {
    level: 'error',
  },
};

const config = process.env.NODE_ENV === 'production' ? production : development;

export default config;
```

## Security

### Input Validation

```javascript
import { z } from 'zod';

// ✅ GOOD - Validate with Zod
const userSchema = z.object({
  name: z.string().min(1).max(100),
  email: z.string().email(),
  age: z.number().int().positive().max(150),
});

function createUser(req, res) {
  try {
    const validated = userSchema.parse(req.body);
    // Use validated data
  } catch (err) {
    res.status(400).json({ error: err.errors });
  }
}

// ❌ BAD - No validation
function badCreateUser(req, res) {
  const { name, email, age } = req.body; // Dangerous!
  // What if name is undefined? What if age is a string?
}
```

### SQL Injection Prevention

```javascript
// ✅ GOOD - Parameterized queries
const user = await db.query(
  'SELECT * FROM users WHERE email = $1',
  [email]
);

// ❌ BAD - String concatenation (SQL injection!)
const user = await db.query(
  `SELECT * FROM users WHERE email = '${email}'`
);
```

### XSS Prevention

```javascript
// ✅ GOOD - Escape output
import escape from 'escape-html';

const html = `<div>${escape(userInput)}</div>`;

// ✅ GOOD - Use Content Security Policy
res.setHeader('Content-Security-Policy', "default-src 'self'");
res.setHeader('X-Content-Type-Options', 'nosniff');
res.setHeader('X-Frame-Options', 'DENY');
```

### Authentication & Authorization

```javascript
import jwt from 'jsonwebtoken';
import bcrypt from 'bcrypt';

// ✅ GOOD - Hash passwords
async function createUser(email, password) {
  const hashedPassword = await bcrypt.hash(password, 10);

  await db.query(
    'INSERT INTO users (email, password) VALUES ($1, $2)',
    [email, hashedPassword]
  );
}

// ✅ GOOD - Verify password
async function login(email, password) {
  const user = await db.query(
    'SELECT * FROM users WHERE email = $1',
    [email]
  );

  if (!user) {
    throw new Error('Invalid credentials');
  }

  const valid = await bcrypt.compare(password, user.password);
  if (!valid) {
    throw new Error('Invalid credentials');
  }

  const token = jwt.sign(
    { id: user.id, email: user.email },
    process.env.JWT_SECRET,
    { expiresIn: '7d' }
  );

  return token;
}

// ✅ GOOD - Verify JWT middleware
function authMiddleware(req, res, next) {
  const token = req.headers.authorization?.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'No token provided' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    next();
  } catch (err) {
    res.status(401).json({ error: 'Invalid token' });
  }
}
```

### Rate Limiting

```javascript
import rateLimit from 'express-rate-limit';

// ✅ GOOD - Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per windowMs
  message: 'Too many requests, please try again later',
});

app.use('/api/', limiter);
```

## Logging

### Structured Logging

```javascript
import winston from 'winston';

// ✅ GOOD - Structured logging
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: { service: 'api' },
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' }),
  ],
});

if (process.env.NODE_ENV !== 'production') {
  logger.add(new winston.transports.Console({
    format: winston.format.simple(),
  }));
}

// Usage
logger.info('User logged in', { userId: 123, email: 'user@example.com' });
logger.error('Database error', { error: err.message, stack: err.stack });
```

### Request Logging

```javascript
// ✅ GOOD - Log all requests
function requestLogger(req, res, next) {
  const start = Date.now();

  res.on('finish', () => {
    const duration = Date.now() - start;

    logger.info('HTTP Request', {
      method: req.method,
      url: req.url,
      statusCode: res.statusCode,
      duration,
      userAgent: req.headers['user-agent'],
      ip: req.ip,
    });
  });

  next();
}

app.use(requestLogger);
```

## Error Handling

### Global Error Handler

```javascript
// ✅ GOOD - Global error handler
function errorHandler(err, req, res, next) {
  logger.error('Error:', {
    error: err.message,
    stack: err.stack,
    url: req.url,
    method: req.method,
  });

  const statusCode = err.statusCode || 500;
  const message = process.env.NODE_ENV === 'production'
    ? 'Internal Server Error'
    : err.message;

  res.status(statusCode).json({
    error: {
      message,
      ...(process.env.NODE_ENV === 'development' && {
        stack: err.stack,
      }),
    },
  });
}

app.use(errorHandler);
```

### Graceful Shutdown

```javascript
// ✅ GOOD - Graceful shutdown
const server = app.listen(3000);

process.on('SIGTERM', gracefulShutdown);
process.on('SIGINT', gracefulShutdown);

async function gracefulShutdown(signal) {
  console.log(`Received ${signal}, closing server...`);

  // Stop accepting new connections
  server.close(async () => {
    console.log('HTTP server closed');

    try {
      // Close database connection
      await db.close();
      console.log('Database connection closed');

      // Close Redis connection
      await redis.quit();
      console.log('Redis connection closed');

      process.exit(0);
    } catch (err) {
      console.error('Error during shutdown:', err);
      process.exit(1);
    }
  });

  // Force shutdown after 30 seconds
  setTimeout(() => {
    console.error('Forced shutdown after timeout');
    process.exit(1);
  }, 30000);
}
```

## Code Quality

### ESLint Configuration

```javascript
// .eslintrc.js
module.exports = {
  env: {
    node: true,
    es2021: true,
  },
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended',
  ],
  parser: '@typescript-eslint/parser',
  parserOptions: {
    ecmaVersion: 'latest',
    sourceType: 'module',
  },
  rules: {
    'no-console': process.env.NODE_ENV === 'production' ? 'warn' : 'off',
    'no-unused-vars': 'error',
    'prefer-const': 'error',
    'no-var': 'error',
  },
};
```

### TypeScript

```typescript
// ✅ GOOD - Use TypeScript
interface User {
  id: number;
  email: string;
  name: string;
}

interface UserService {
  findById(id: number): Promise<User | null>;
  create(user: Omit<User, 'id'>): Promise<User>;
  update(id: number, user: Partial<User>): Promise<User>;
  delete(id: number): Promise<void>;
}

class UserServiceImpl implements UserService {
  constructor(private db: Database) {}

  async findById(id: number): Promise<User | null> {
    const result = await this.db.query<User>(
      'SELECT * FROM users WHERE id = $1',
      [id]
    );
    return result.rows[0] || null;
  }

  // ... other methods
}
```

## Testing

### Test Coverage

```javascript
// ✅ GOOD - High test coverage
describe('UserService', () => {
  let service;
  let mockDb;

  beforeEach(() => {
    mockDb = {
      query: jest.fn(),
    };
    service = new UserService(mockDb);
  });

  describe('findById', () => {
    it('should return user when found', async () => {
      const mockUser = { id: 1, name: 'Alice', email: 'alice@example.com' };
      mockDb.query.mockResolvedValue({ rows: [mockUser] });

      const user = await service.findById(1);

      expect(user).toEqual(mockUser);
      expect(mockDb.query).toHaveBeenCalledWith(
        'SELECT * FROM users WHERE id = $1',
        [1]
      );
    });

    it('should return null when user not found', async () => {
      mockDb.query.mockResolvedValue({ rows: [] });

      const user = await service.findById(999);

      expect(user).toBeNull();
    });
  });
});
```

## Documentation

### Code Comments

```javascript
// ✅ GOOD - JSDoc comments
/**
 * Fetches user by ID from database
 * @param {number} id - User ID
 * @returns {Promise<User|null>} User object or null if not found
 * @throws {DatabaseError} If database query fails
 */
async function getUserById(id) {
  const user = await db.query('SELECT * FROM users WHERE id = $1', [id]);
  return user.rows[0] || null;
}

// ❌ BAD - No documentation
async function get(i) {
  const u = await db.query('SELECT * FROM users WHERE id = $1', [i]);
  return u.rows[0] || null;
}
```

### README

```markdown
# Project Name

## Description
Brief description of what the project does.

## Installation
\`\`\`bash
npm install
\`\`\`

## Configuration
Copy `.env.example` to `.env` and configure:
- `DATABASE_URL` - PostgreSQL connection string
- `JWT_SECRET` - Secret for JWT tokens

## Usage
\`\`\`bash
npm run dev
\`\`\`

## Testing
\`\`\`bash
npm test
npm run test:coverage
\`\`\`

## API Documentation
See [API.md](./docs/API.md)

## License
MIT
```

## AI Pair Programming Notes

**Production checklist:**

1. **Environment variables** - Never commit secrets
2. **Input validation** - Validate all user input
3. **Error handling** - Handle all errors gracefully
4. **Logging** - Structured logging for debugging
5. **Security headers** - CSP, HSTS, X-Frame-Options
6. **Rate limiting** - Prevent abuse
7. **HTTPS only** - Use TLS in production
8. **Database connection pooling** - Reuse connections
9. **Graceful shutdown** - Handle SIGTERM/SIGINT
10. **Monitoring** - Track errors, performance, uptime

**Common mistakes:**
- Committing `.env` files with secrets
- Not validating user input
- Using `console.log` instead of proper logging
- No error handling in async code
- Blocking event loop with CPU work
- Not using connection pooling
- Exposing stack traces in production
- No rate limiting
- Not handling process signals
- Missing health check endpoints

## Next Steps

1. Review all previous files (01-10)
2. Implement patterns in production code
3. Add monitoring and observability
4. Continuous improvement

## Additional Resources

- Node.js Best Practices: https://github.com/goldbergyoni/nodebestpractices
- Security Checklist: https://cheatsheetseries.owasp.org/cheatsheets/Nodejs_Security_Cheat_Sheet.html
- Twelve-Factor App: https://12factor.net/
- Production Ready Node.js: https://nodejs.org/en/docs/guides/
