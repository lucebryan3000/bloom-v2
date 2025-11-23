---
id: docker-patterns
topic: docker
file_role: patterns
profile: full
difficulty_level: intermediate-advanced
kb_version: 3.1
prerequisites: [docker-basics, linux]
related_topics: [cicd, deployment, containers]
embedding_keywords: [patterns, examples, integration, best-practices, docker-patterns]
last_reviewed: 2025-11-13
---

# Docker Framework Integration Patterns

**Purpose**: Production-ready Docker patterns and integration examples.

---

## 📋 Table of Contents

1. [Multi-Stage Builds](#multi-stage-builds)
2. [Docker Compose](#docker-compose)
3. [Development Environments](#development-environments)
4. [Production Optimization](#production-optimization)
5. [CI/CD Integration](#cicd-integration)

---

## Multi-Stage Builds

### Pattern 1: Next.js Multi-Stage Build

```dockerfile
# Stage 1: Dependencies
FROM node:20-alpine AS deps
WORKDIR /app
COPY package*.json./
RUN npm ci

# Stage 2: Builder
FROM node:20-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules./node_modules
COPY..
RUN npm run build

# Stage 3: Runner
FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production

COPY --from=builder /app/public./public
COPY --from=builder /app/.next/standalone./
COPY --from=builder /app/.next/static./.next/static

EXPOSE 3000
CMD ["node", "server.js"]
```

### Pattern 2: Python Multi-Stage Build

```dockerfile
# Build stage
FROM python:3.11-slim AS builder
WORKDIR /app
COPY requirements.txt.
RUN pip install --user --no-cache-dir -r requirements.txt

# Runtime stage
FROM python:3.11-slim
WORKDIR /app
COPY --from=builder /root/.local /root/.local
COPY..

ENV PATH=/root/.local/bin:$PATH
CMD ["python", "app.py"]
```

---

## Docker Compose

### Pattern 3: Full Stack Application

```yaml
version: '3.8'

services:
 app:
 build:.
 ports:
 - "3000:3000"
 environment:
 - DATABASE_URL=postgresql://user:pass@db:5432/mydb
 depends_on:
 db:
 condition: service_healthy

 db:
 image: postgres:16
 environment:
 POSTGRES_USER: user
 POSTGRES_PASSWORD: pass
 POSTGRES_DB: mydb
 volumes:
 - postgres_data:/var/lib/postgresql/data
 healthcheck:
 test: ["CMD-SHELL", "pg_isready -U user"]
 interval: 5s
 timeout: 5s
 retries: 5

 redis:
 image: redis:7-alpine
 ports:
 - "6379:6379"

volumes:
 postgres_data:
```

### Pattern 4: Development with Hot Reload

```yaml
version: '3.8'

services:
 app:
 build:
 context:.
 target: development
 volumes:
 -.:/app
 - /app/node_modules
 environment:
 - NODE_ENV=development
 command: npm run dev
```

---

## Development Environments

### Pattern 5: Dev Container

```dockerfile
FROM mcr.microsoft.com/devcontainers/typescript-node:20

# Install additional tools
RUN apt-get update && apt-get install -y \
 git \
 curl \
 vim \
 && rm -rf /var/lib/apt/lists/*

# Install global npm packages
RUN npm install -g typescript tsx

USER node
WORKDIR /workspace
```

### Pattern 6: Docker Compose Override for Development

```yaml
# docker-compose.override.yml
version: '3.8'

services:
 app:
 build:
 target: development
 volumes:
 -.:/app
 - /app/node_modules
 environment:
 - DEBUG=*
 - LOG_LEVEL=debug
```

---

## Production Optimization

### Pattern 7:.dockerignore

```
node_modules
npm-debug.log
.next
.git
.env.local
.DS_Store
*.md
tests/
docs/
.github/
```

### Pattern 8: Health Checks

```dockerfile
FROM node:20-alpine
WORKDIR /app

COPY package*.json./
RUN npm ci --only=production

COPY..

HEALTHCHECK --interval=30s --timeout=3s --start-period=40s \
 CMD node healthcheck.js || exit 1

EXPOSE 3000
CMD ["node", "server.js"]
```

---

## CI/CD Integration

### Pattern 9: GitHub Actions Build

```yaml
name: Docker Build

on:
 push:
 branches: [main]

jobs:
 build:
 runs-on: ubuntu-latest
 steps:
 - uses: actions/checkout@v3

 - name: Set up Docker Buildx
 uses: docker/setup-buildx-action@v2

 - name: Login to Docker Hub
 uses: docker/login-action@v2
 with:
 username: ${{ secrets.DOCKER_USERNAME }}
 password: ${{ secrets.DOCKER_TOKEN }}

 - name: Build and push
 uses: docker/build-push-action@v4
 with:
 context:.
 push: true
 tags: user/app:latest
 cache-from: type=gha
 cache-to: type=gha,mode=max
```

### Pattern 10: Docker Layer Caching

```dockerfile
# Optimize layer caching by copying dependencies first
FROM node:20-alpine
WORKDIR /app

# Copy package files first (changes less frequently)
COPY package*.json./
RUN npm ci --only=production

# Copy application code (changes more frequently)
COPY..

CMD ["node", "index.js"]
```

---

## Best Practices

1. **Multi-Stage Builds**: Keep final images small
2. **.dockerignore**: Exclude unnecessary files
3. **Layer Caching**: Order Dockerfile commands by change frequency
4. **Health Checks**: Implement proper health check endpoints
5. **Security**: Run as non-root user when possible

---

## Related Files

- **Quick Syntax**: [QUICK-REFERENCE.md](./QUICK-REFERENCE.md)
- **Overview**: [README.md](./README.md)
- **Navigation**: [INDEX.md](./INDEX.md)

---

**All examples are production-ready Docker patterns. Optimize for your use case!**
