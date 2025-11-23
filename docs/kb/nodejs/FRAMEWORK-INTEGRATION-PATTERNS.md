# Node.js - Framework Integration Patterns

```yaml
id: nodejs_framework_integration
topic: Node.js
file_role: Framework integration patterns and best practices
profile: full
difficulty_level: intermediate
kb_version: v3.1
prerequisites:
  - 01-FUNDAMENTALS.md
  - 02-ASYNC-PROGRAMMING.md
  - 06-HTTP-NETWORKING.md
related_topics:
  - TypeScript (../typescript/)
  - Next.js (../nextjs/)
  - Testing (../testing/)
embedding_keywords:
  - nodejs framework integration
  - express nodejs
  - nextjs nodejs
  - typescript nodejs
  - node.js patterns
  - framework best practices
last_reviewed: 2025-11-17
```

## Overview

Node.js integrates with modern frameworks to build scalable applications. This guide covers integration patterns for:

- **Express.js** - Minimalist web framework
- **Next.js** - React framework with SSR/SSG
- **TypeScript** - Type-safe Node.js development
- **Prisma** - Type-safe database ORM
- **Jest** - Testing framework

---

## Express.js Integration

### Basic Setup

```javascript
// app.js
import express from 'express';

const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.get('/', (req, res) => {
  res.json({ message: 'Hello Express' });
});

// Start server
app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});

export default app;
```

### Router Pattern

```javascript
// routes/users.js
import express from 'express';

const router = express.Router();

// GET /api/users
router.get('/', async (req, res) => {
  try {
    const users = await User.findAll();
    res.json(users);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/users/:id
router.get('/:id', async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    res.json(user);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/users
router.post('/', async (req, res) => {
  try {
    const user = await User.create(req.body);
    res.status(201).json(user);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// PUT /api/users/:id
router.put('/:id', async (req, res) => {
  try {
    const user = await User.update(req.params.id, req.body);
    res.json(user);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// DELETE /api/users/:id
router.delete('/:id', async (req, res) => {
  try {
    await User.delete(req.params.id);
    res.status(204).send();
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

export default router;

// app.js
import userRoutes from './routes/users.js';
app.use('/api/users', userRoutes);
```

### Middleware Pattern

```javascript
// middleware/auth.js
export function authMiddleware(req, res, next) {
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

// middleware/error-handler.js
export function errorHandler(err, req, res, next) {
  console.error(err.stack);

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

// middleware/request-logger.js
export function requestLogger(req, res, next) {
  const start = Date.now();

  res.on('finish', () => {
    const duration = Date.now() - start;
    console.log(`${req.method} ${req.url} ${res.statusCode} ${duration}ms`);
  });

  next();
}

// app.js
import { authMiddleware } from './middleware/auth.js';
import { errorHandler } from './middleware/error-handler.js';
import { requestLogger } from './middleware/request-logger.js';

app.use(requestLogger);

// Protected routes
app.use('/api/protected', authMiddleware);

// Error handling (must be last)
app.use(errorHandler);
```

### Validation with Zod

```javascript
// validators/user.js
import { z } from 'zod';

export const createUserSchema = z.object({
  name: z.string().min(1).max(100),
  email: z.string().email(),
  age: z.number().int().positive().max(150),
});

export const updateUserSchema = createUserSchema.partial();

// routes/users.js
import { createUserSchema, updateUserSchema } from '../validators/user.js';

router.post('/', async (req, res) => {
  try {
    const validated = createUserSchema.parse(req.body);
    const user = await User.create(validated);
    res.status(201).json(user);
  } catch (err) {
    if (err instanceof z.ZodError) {
      return res.status(400).json({ errors: err.errors });
    }
    res.status(500).json({ error: err.message });
  }
});
```

### CORS Configuration

```javascript
import cors from 'cors';

// Allow all origins (development only)
app.use(cors());

// Production configuration
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || 'http://localhost:3000',
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));
```

---

## Next.js Integration

### API Routes

```javascript
// app/api/users/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/db';

export async function GET(request: NextRequest) {
  try {
    const users = await prisma.user.findMany();
    return NextResponse.json(users);
  } catch (err) {
    return NextResponse.json(
      { error: 'Internal Server Error' },
      { status: 500 }
    );
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const user = await prisma.user.create({ data: body });
    return NextResponse.json(user, { status: 201 });
  } catch (err) {
    return NextResponse.json(
      { error: 'Bad Request' },
      { status: 400 }
    );
  }
}
```

### Dynamic API Routes (Next.js 16)

```typescript
// app/api/users/[id]/route.ts
import { NextRequest, NextResponse } from 'next/server';

// ⚠️ IMPORTANT: Next.js 16 requires async params
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;  // Must await params Promise

  try {
    const user = await prisma.user.findUnique({
      where: { id: parseInt(id) }
    });

    if (!user) {
      return NextResponse.json(
        { error: 'User not found' },
        { status: 404 }
      );
    }

    return NextResponse.json(user);
  } catch (err) {
    return NextResponse.json(
      { error: 'Internal Server Error' },
      { status: 500 }
    );
  }
}

export async function PUT(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;
  const body = await request.json();

  try {
    const user = await prisma.user.update({
      where: { id: parseInt(id) },
      data: body,
    });
    return NextResponse.json(user);
  } catch (err) {
    return NextResponse.json(
      { error: 'Bad Request' },
      { status: 400 }
    );
  }
}

export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;

  try {
    await prisma.user.delete({
      where: { id: parseInt(id) }
    });
    return new NextResponse(null, { status: 204 });
  } catch (err) {
    return NextResponse.json(
      { error: 'Internal Server Error' },
      { status: 500 }
    );
  }
}
```

### Server Actions (Next.js 14+)

```typescript
// app/actions/users.ts
'use server';

import { revalidatePath } from 'next/cache';
import { prisma } from '@/lib/db';

export async function createUser(formData: FormData) {
  const name = formData.get('name') as string;
  const email = formData.get('email') as string;

  try {
    const user = await prisma.user.create({
      data: { name, email },
    });

    revalidatePath('/users');
    return { success: true, user };
  } catch (err) {
    return { success: false, error: err.message };
  }
}

export async function deleteUser(id: number) {
  try {
    await prisma.user.delete({
      where: { id },
    });

    revalidatePath('/users');
    return { success: true };
  } catch (err) {
    return { success: false, error: err.message };
  }
}

// app/users/page.tsx
import { createUser } from '../actions/users';

export default function UsersPage() {
  return (
    <form action={createUser}>
      <input name="name" required />
      <input name="email" type="email" required />
      <button type="submit">Create User</button>
    </form>
  );
}
```

### Middleware

```typescript
// middleware.ts
import { NextRequest, NextResponse } from 'next/server';

export function middleware(request: NextRequest) {
  const token = request.cookies.get('token');

  if (!token && request.nextUrl.pathname.startsWith('/dashboard')) {
    return NextResponse.redirect(new URL('/login', request.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: '/dashboard/:path*',
};
```

---

## TypeScript Integration

### Basic Setup

```bash
npm install -D typescript @types/node
npx tsc --init
```

```json
// tsconfig.json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "node",
    "lib": ["ES2022"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "declaration": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

### Type-Safe Express

```typescript
// types/express.d.ts
import { User } from './user';

declare global {
  namespace Express {
    interface Request {
      user?: User;
    }
  }
}

// routes/users.ts
import { Request, Response, NextFunction } from 'express';

interface CreateUserBody {
  name: string;
  email: string;
  age: number;
}

export async function createUser(
  req: Request<{}, {}, CreateUserBody>,
  res: Response,
  next: NextFunction
) {
  try {
    const { name, email, age } = req.body;
    const user = await User.create({ name, email, age });
    res.status(201).json(user);
  } catch (err) {
    next(err);
  }
}

// With route params
interface UserParams {
  id: string;
}

export async function getUser(
  req: Request<UserParams>,
  res: Response,
  next: NextFunction
) {
  try {
    const user = await User.findById(parseInt(req.params.id));
    res.json(user);
  } catch (err) {
    next(err);
  }
}
```

### Type-Safe Async Handlers

```typescript
import { Request, Response, NextFunction } from 'express';

type AsyncHandler = (
  req: Request,
  res: Response,
  next: NextFunction
) => Promise<void>;

export function asyncHandler(fn: AsyncHandler) {
  return (req: Request, res: Response, next: NextFunction) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
}

// Usage
router.get('/:id', asyncHandler(async (req, res) => {
  const user = await User.findById(req.params.id);
  res.json(user);
}));
```

---

## Prisma Integration

### Setup

```bash
npm install prisma @prisma/client
npx prisma init
```

```prisma
// prisma/schema.prisma
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

generator client {
  provider = "prisma-client-js"
}

model User {
  id        Int      @id @default(autoincrement())
  email     String   @unique
  name      String
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
  posts     Post[]
}

model Post {
  id        Int      @id @default(autoincrement())
  title     String
  content   String?
  published Boolean  @default(false)
  authorId  Int
  author    User     @relation(fields: [authorId], references: [id])
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
}
```

### Database Client

```typescript
// lib/db.ts
import { PrismaClient } from '@prisma/client';

const globalForPrisma = global as unknown as { prisma: PrismaClient };

export const prisma = globalForPrisma.prisma || new PrismaClient({
  log: process.env.NODE_ENV === 'development'
    ? ['query', 'error', 'warn']
    : ['error'],
});

if (process.env.NODE_ENV !== 'production') {
  globalForPrisma.prisma = prisma;
}

// Graceful shutdown
process.on('beforeExit', async () => {
  await prisma.$disconnect();
});
```

### Repository Pattern

```typescript
// repositories/user-repository.ts
import { prisma } from '@/lib/db';
import { Prisma } from '@prisma/client';

export class UserRepository {
  async findAll() {
    return prisma.user.findMany({
      include: { posts: true },
    });
  }

  async findById(id: number) {
    return prisma.user.findUnique({
      where: { id },
      include: { posts: true },
    });
  }

  async create(data: Prisma.UserCreateInput) {
    return prisma.user.create({ data });
  }

  async update(id: number, data: Prisma.UserUpdateInput) {
    return prisma.user.update({
      where: { id },
      data,
    });
  }

  async delete(id: number) {
    return prisma.user.delete({
      where: { id },
    });
  }
}

export const userRepository = new UserRepository();
```

### Service Layer

```typescript
// services/user-service.ts
import { userRepository } from '@/repositories/user-repository';

export class UserService {
  async getUsers() {
    return userRepository.findAll();
  }

  async getUser(id: number) {
    const user = await userRepository.findById(id);
    if (!user) {
      throw new Error('User not found');
    }
    return user;
  }

  async createUser(data: { name: string; email: string }) {
    // Validate email uniqueness
    const existing = await prisma.user.findUnique({
      where: { email: data.email },
    });

    if (existing) {
      throw new Error('Email already exists');
    }

    return userRepository.create(data);
  }

  async updateUser(id: number, data: { name?: string; email?: string }) {
    await this.getUser(id);  // Ensure exists
    return userRepository.update(id, data);
  }

  async deleteUser(id: number) {
    await this.getUser(id);  // Ensure exists
    return userRepository.delete(id);
  }
}

export const userService = new UserService();
```

---

## Testing Integration (Jest)

### Setup

```bash
npm install -D jest @types/jest ts-jest
npx ts-jest config:init
```

```javascript
// jest.config.js
export default {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/src', '<rootDir>/tests'],
  testMatch: ['**/__tests__/**/*.ts', '**/?(*.)+(spec|test).ts'],
  transform: {
    '^.+\\.ts$': 'ts-jest',
  },
  collectCoverageFrom: [
    'src/**/*.ts',
    '!src/**/*.d.ts',
    '!src/**/*.test.ts',
  ],
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80,
    },
  },
};
```

### Testing Express Routes

```typescript
// tests/routes/users.test.ts
import request from 'supertest';
import app from '@/app';
import { prisma } from '@/lib/db';

describe('User API', () => {
  beforeAll(async () => {
    await prisma.$connect();
  });

  afterAll(async () => {
    await prisma.user.deleteMany();
    await prisma.$disconnect();
  });

  beforeEach(async () => {
    await prisma.user.deleteMany();
  });

  describe('GET /api/users', () => {
    it('should return all users', async () => {
      await prisma.user.createMany({
        data: [
          { name: 'Alice', email: 'alice@example.com' },
          { name: 'Bob', email: 'bob@example.com' },
        ],
      });

      const res = await request(app).get('/api/users');

      expect(res.status).toBe(200);
      expect(res.body).toHaveLength(2);
    });
  });

  describe('POST /api/users', () => {
    it('should create a user', async () => {
      const userData = {
        name: 'Alice',
        email: 'alice@example.com',
      };

      const res = await request(app)
        .post('/api/users')
        .send(userData);

      expect(res.status).toBe(201);
      expect(res.body).toMatchObject(userData);
    });

    it('should reject invalid data', async () => {
      const res = await request(app)
        .post('/api/users')
        .send({ name: 'Alice' });  // Missing email

      expect(res.status).toBe(400);
    });
  });
});
```

### Mocking Prisma

```typescript
// tests/services/user-service.test.ts
import { userService } from '@/services/user-service';
import { prisma } from '@/lib/db';

jest.mock('@/lib/db', () => ({
  prisma: {
    user: {
      findMany: jest.fn(),
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
    },
  },
}));

describe('UserService', () => {
  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('getUsers', () => {
    it('should return all users', async () => {
      const mockUsers = [
        { id: 1, name: 'Alice', email: 'alice@example.com' },
        { id: 2, name: 'Bob', email: 'bob@example.com' },
      ];

      (prisma.user.findMany as jest.Mock).mockResolvedValue(mockUsers);

      const users = await userService.getUsers();

      expect(users).toEqual(mockUsers);
      expect(prisma.user.findMany).toHaveBeenCalledTimes(1);
    });
  });

  describe('getUser', () => {
    it('should return user by id', async () => {
      const mockUser = { id: 1, name: 'Alice', email: 'alice@example.com' };

      (prisma.user.findUnique as jest.Mock).mockResolvedValue(mockUser);

      const user = await userService.getUser(1);

      expect(user).toEqual(mockUser);
      expect(prisma.user.findUnique).toHaveBeenCalledWith({
        where: { id: 1 },
      });
    });

    it('should throw error if user not found', async () => {
      (prisma.user.findUnique as jest.Mock).mockResolvedValue(null);

      await expect(userService.getUser(999)).rejects.toThrow('User not found');
    });
  });
});
```

---

## Environment Configuration

### Setup

```bash
npm install dotenv
```

```env
# .env
NODE_ENV=development
PORT=3000

# Database
DATABASE_URL=postgresql://user:password@localhost:5432/mydb

# Authentication
JWT_SECRET=your-secret-key
JWT_EXPIRES_IN=7d

# External APIs
API_KEY=your-api-key
```

### Type-Safe Config

```typescript
// config/index.ts
import { z } from 'zod';
import 'dotenv/config';

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  PORT: z.string().transform(Number).default('3000'),
  DATABASE_URL: z.string().url(),
  JWT_SECRET: z.string().min(32),
  JWT_EXPIRES_IN: z.string().default('7d'),
  API_KEY: z.string().optional(),
});

// Validate and export
const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  console.error('❌ Invalid environment variables:', parsed.error.format());
  throw new Error('Invalid environment variables');
}

export const config = parsed.data;

// Usage
import { config } from '@/config';

console.log(config.PORT);  // Type-safe: number
console.log(config.NODE_ENV);  // Type-safe: 'development' | 'production' | 'test'
```

---

## Project Structure

```
project/
├── src/
│   ├── routes/
│   │   ├── users.ts
│   │   └── posts.ts
│   ├── services/
│   │   ├── user-service.ts
│   │   └── post-service.ts
│   ├── repositories/
│   │   ├── user-repository.ts
│   │   └── post-repository.ts
│   ├── middleware/
│   │   ├── auth.ts
│   │   ├── error-handler.ts
│   │   └── request-logger.ts
│   ├── validators/
│   │   ├── user.ts
│   │   └── post.ts
│   ├── lib/
│   │   └── db.ts
│   ├── config/
│   │   └── index.ts
│   └── app.ts
├── tests/
│   ├── routes/
│   ├── services/
│   └── repositories/
├── prisma/
│   └── schema.prisma
├── .env.example
├── .env
├── package.json
├── tsconfig.json
└── jest.config.js
```

---

## AI Pair Programming Notes

**When to load this file**: Integrating Node.js with Express, Next.js, TypeScript, Prisma, or Jest.

**Common integration questions**:
- "How to use Express with Node.js?" → Express.js Integration section
- "Next.js API routes?" → Next.js Integration section
- "TypeScript with Node.js?" → TypeScript Integration section
- "Prisma setup?" → Prisma Integration section
- "Testing Node.js apps?" → Testing Integration section

**Quick patterns**:
- **Express API**: Router pattern with middleware
- **Next.js API**: Route handlers with NextRequest/NextResponse
- **TypeScript**: Type-safe Express handlers and Prisma repositories
- **Prisma**: Repository pattern with service layer
- **Testing**: Jest with supertest for API testing

**Common mistakes**:
- Forgetting to await params in Next.js 16 dynamic routes
- Not validating environment variables
- Missing error handling middleware
- Not using async handlers correctly
- Forgetting to disconnect Prisma client

---

**Last Updated**: November 17, 2025
**Node.js Version**: 20.x+
**Status**: Production-Ready ✅
