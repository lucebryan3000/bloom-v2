---
id: nextjs-08-deployment
topic: nextjs
file_role: detailed
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [react, javascript, nextjs-basics]
related_topics: ['react', 'typescript', 'web']
embedding_keywords: [nextjs]
last_reviewed: 2025-11-13
---

# Next.js Deployment: Production & Hosting

**Part 8 of 11 - The Next.js Knowledge Base**

## Table of Contents
1. [Build Process](#build-process)
2. [Environment Variables](#environment-variables)
3. [Vercel Deployment](#vercel-deployment)
4. [Docker Deployment](#docker-deployment)
5. [Self-Hosting](#self-hosting)
6. [CI/CD Pipelines](#cicd-pipelines)
7. [Database Migrations](#database-migrations)
8. [Production Checklist](#production-checklist)
9. [Monitoring & Analytics](#monitoring--analytics)
10. [Best Practices](#best-practices)

---

## Build Process

### Production Build

```bash
# Build for production
npm run build

# Output:
#.next/ - Build output directory
# - static/ - Static assets
# - server/ - Server-side code
# - cache/ - Build cache
```

### Build Output

```
.next/
├── cache/ # Build cache
├── server/
│ ├── app/ # App Router pages
│ ├── chunks/ # Code chunks
│ └── pages/ # Pages Router (if used)
├── static/
│ ├── chunks/ # Client-side chunks
│ ├── css/ # CSS files
│ └── media/ # Images, fonts
└── BUILD_ID # Build identifier
```

### Build Configuration

```javascript
// next.config.js
module.exports = {
 // Output mode
 output: 'standalone', // For Docker (this project uses this)
 // output: 'export', // For static export

 // Compression
 compress: true,

 // Generate source maps (production)
 productionBrowserSourceMaps: false,

 // Disable x-powered-by header
 poweredByHeader: false,

 // Generate build ID
 generateBuildId: async => {
 return process.env.GIT_HASH || 'my-build-id';
 },

 // React strict mode
 reactStrictMode: true,

 // SWC minification
 swcMinify: true,
};
```

### Analyzing Build

```bash
# Analyze bundle size
ANALYZE=true npm run build

# Check build output
npm run build -- --profile
```

---

## Environment Variables

### Environment Files

```bash
#.env.local (development, never commit)
DATABASE_URL=postgresql://localhost:5432/dev
NEXT_PUBLIC_API_URL=http://localhost:3001/api

#.env.production (production values)
DATABASE_URL=${DATABASE_URL}
NEXT_PUBLIC_API_URL=https://api.example.com

#.env (committed defaults)
NEXT_PUBLIC_APP_NAME=this application
```

### Using Environment Variables

```typescript
// Server-side (Server Components, API Routes)
const dbUrl = process.env.DATABASE_URL;
const apiKey = process.env.API_KEY;

// Client-side (must be prefixed with NEXT_PUBLIC_)
const apiUrl = process.env.NEXT_PUBLIC_API_URL;
const appName = process.env.NEXT_PUBLIC_APP_NAME;
```

### Runtime Environment Variables

```typescript
// next.config.js
module.exports = {
 env: {
 CUSTOM_KEY: process.env.CUSTOM_KEY,
 },
 // Or use publicRuntimeConfig for client-side
 publicRuntimeConfig: {
 apiUrl: process.env.API_URL,
 },
 // Or serverRuntimeConfig for server-side only
 serverRuntimeConfig: {
 dbPassword: process.env.DB_PASSWORD,
 },
};
```

### this project Environment Variables

```bash
#.env.example (this project)
# Database
DATABASE_URL="file:./this project.db"

# AI/ML
ANTHROPIC_API_KEY="sk-ant-..."

# Application
NEXTAUTH_SECRET="..."
NEXTAUTH_URL="http://localhost:3001"

# Logging
LOG_LEVEL="info"
DEBUG="this project:*"
NODE_OPTIONS="--max-old-space-size=4096"

# Redis (optional)
REDIS_URL="redis://localhost:6379"
```

---

## Vercel Deployment

### Deploy from CLI

```bash
# Install Vercel CLI
npm install -g vercel

# Deploy
vercel

# Deploy to production
vercel --prod

# Set environment variables
vercel env add ANTHROPIC_API_KEY
```

### vercel.json Configuration

```json
{
 "buildCommand": "npm run build",
 "devCommand": "npm run dev",
 "installCommand": "npm install",
 "framework": "nextjs",
 "regions": ["iad1"],
 "env": {
 "CUSTOM_VAR": "@custom-var-secret"
 },
 "build": {
 "env": {
 "BUILD_VAR": "value"
 }
 },
 "headers": [
 {
 "source": "/(.*)",
 "headers": [
 {
 "key": "X-Content-Type-Options",
 "value": "nosniff"
 },
 {
 "key": "X-Frame-Options",
 "value": "DENY"
 },
 {
 "key": "X-XSS-Protection",
 "value": "1; mode=block"
 }
 ]
 }
 ],
 "redirects": [
 {
 "source": "/old-path",
 "destination": "/new-path",
 "permanent": true
 }
 ],
 "rewrites": [
 {
 "source": "/api/:path*",
 "destination": "https://api.example.com/:path*"
 }
 ]
}
```

### GitHub Integration

```yaml
#.github/workflows/vercel.yml
name: Vercel Deploy

on:
 push:
 branches: [main]
 pull_request:
 branches: [main]

jobs:
 deploy:
 runs-on: ubuntu-latest
 steps:
 - uses: actions/checkout@v3

 - name: Install Vercel CLI
 run: npm install -g vercel

 - name: Pull Vercel Environment
 run: vercel pull --yes --environment=production --token=${{ secrets.VERCEL_TOKEN }}

 - name: Build Project
 run: vercel build --prod --token=${{ secrets.VERCEL_TOKEN }}

 - name: Deploy to Vercel
 run: vercel deploy --prebuilt --prod --token=${{ secrets.VERCEL_TOKEN }}
```

---

## Docker Deployment

### Dockerfile (this project Configuration)

```dockerfile
# Dockerfile.production (this project uses this)
FROM node:20-alpine AS base

# Dependencies
FROM base AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app

COPY package.json package-lock.json./
RUN npm ci

# Builder
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules./node_modules
COPY..

# Build
ENV NEXT_TELEMETRY_DISABLED 1
RUN npm run build

# Runner
FROM base AS runner
WORKDIR /app

ENV NODE_ENV production
ENV NEXT_TELEMETRY_DISABLED 1

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Copy build
COPY --from=builder /app/public./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static./.next/static

USER nextjs

EXPOSE 3000

ENV PORT 3000
ENV HOSTNAME "0.0.0.0"

CMD ["node", "server.js"]
```

### docker-compose.yml

```yaml
# docker-compose.yml
version: '3.8'

services:
 app:
 build:
 context:.
 dockerfile: Dockerfile.production
 ports:
 - "3000:3000"
 environment:
 - DATABASE_URL=${DATABASE_URL}
 - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
 - NEXTAUTH_SECRET=${NEXTAUTH_SECRET}
 volumes:
 -./prisma:/app/prisma
 - this project-data:/app/data
 restart: unless-stopped

 redis:
 image: redis:7-alpine
 ports:
 - "6379:6379"
 volumes:
 - redis-data:/data
 restart: unless-stopped

volumes:
 this project-data:
 redis-data:
```

### Build & Run Docker

```bash
# Build
docker build -t app-image -f Dockerfile.production.

# Run
docker run -p 3000:3000 \
 -e DATABASE_URL="..." \
 -e ANTHROPIC_API_KEY="..." \
 app-image

# Or with docker-compose
docker-compose up -d

# View logs
docker-compose logs -f app

# Stop
docker-compose down
```

### next.config.js for Docker

```javascript
// next.config.js (required for standalone)
module.exports = {
 output: 'standalone',

 // Optional: Customize standalone output
 experimental: {
 outputFileTracingRoot: __dirname,
 },
};
```

---

## Self-Hosting

### Node.js Server

```bash
# Build
npm run build

# Start production server
npm start

# Or with custom port
PORT=3000 npm start

# Or with PM2 (not used in this project anymore)
pm2 start npm --name "this project" -- start
pm2 save
pm2 startup
```

### Custom Server (Advanced)

```typescript
// server.ts
import { createServer } from 'http';
import { parse } from 'url';
import next from 'next';

const dev = process.env.NODE_ENV !== 'production';
const hostname = 'localhost';
const port = 3000;

const app = next({ dev, hostname, port });
const handle = app.getRequestHandler;

app.prepare.then( => {
 createServer(async (req, res) => {
 try {
 const parsedUrl = parse(req.url!, true);
 await handle(req, res, parsedUrl);
 } catch (err) {
 console.error('Error occurred handling', req.url, err);
 res.statusCode = 500;
 res.end('Internal server error');
 }
 }).listen(port, => {
 console.log(`> Ready on http://${hostname}:${port}`);
 });
});
```

### Nginx Reverse Proxy

```nginx
# /etc/nginx/sites-available/this project
upstream this project {
 server localhost:3000;
}

server {
 listen 80;
 server_name this project.example.com;

 # Redirect to HTTPS
 return 301 https://$server_name$request_uri;
}

server {
 listen 443 ssl http2;
 server_name this project.example.com;

 ssl_certificate /etc/letsencrypt/live/this project.example.com/fullchain.pem;
 ssl_certificate_key /etc/letsencrypt/live/this project.example.com/privkey.pem;

 location / {
 proxy_pass http://this project;
 proxy_http_version 1.1;
 proxy_set_header Upgrade $http_upgrade;
 proxy_set_header Connection 'upgrade';
 proxy_set_header Host $host;
 proxy_cache_bypass $http_upgrade;
 proxy_set_header X-Real-IP $remote_addr;
 proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
 proxy_set_header X-Forwarded-Proto $scheme;
 }

 # Static files
 location /_next/static {
 proxy_pass http://this project;
 expires 1y;
 add_header Cache-Control "public, immutable";
 }

 # Images
 location /images {
 proxy_pass http://this project;
 expires 1y;
 add_header Cache-Control "public, immutable";
 }
}
```

---

## CI/CD Pipelines

### GitHub Actions (this project uses this)

```yaml
#.github/workflows/test-and-deploy.yml
name: Test and Deploy

on:
 push:
 branches: [main]
 pull_request:
 branches: [main]

jobs:
 test:
 runs-on: ubuntu-latest

 steps:
 - uses: actions/checkout@v3

 - name: Setup Node.js
 uses: actions/setup-node@v3
 with:
 node-version: '20'
 cache: 'npm'

 - name: Install dependencies
 run: npm ci

 - name: Run linter
 run: npm run lint

 - name: Run type check
 run: npm run type-check

 - name: Run tests
 run: npm test

 - name: Build
 run: npm run build

 deploy:
 needs: test
 runs-on: ubuntu-latest
 if: github.ref == 'refs/heads/main'

 steps:
 - uses: actions/checkout@v3

 - name: Deploy to production
 run: |
 # Your deployment script
./scripts/deploy.sh
 env:
 DATABASE_URL: ${{ secrets.DATABASE_URL }}
 ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
```

### Deployment Script

```bash
#!/bin/bash
# scripts/deploy.sh

set -e

echo "🚀 Starting deployment..."

# Pull latest code
git pull origin main

# Install dependencies
npm ci

# Run database migrations
npm run migrate:deploy

# Build application
npm run build

# Restart application
pm2 restart this project

echo "✅ Deployment complete!"
```

---

## Database Migrations

### Prisma Migrations (this project uses this)

```bash
# Development
npx prisma migrate dev --name add_user_fields

# Production
npx prisma migrate deploy

# Reset database (DANGEROUS)
npx prisma migrate reset
```

### Migration Script

```bash
#!/bin/bash
# scripts/migrate-production.sh (this project)

set -e

echo "🔄 Running database migrations..."

# Backup database
cp prisma/this project.db prisma/this project.db.backup.$(date +%Y%m%d_%H%M%S)

# Run migrations
npx prisma migrate deploy

# Generate Prisma Client
npx prisma generate

echo "✅ Migrations complete!"
```

---

## Production Checklist

### Before Deployment

- [ ] All tests passing
- [ ] TypeScript type check passes
- [ ] ESLint no errors
- [ ] Environment variables configured
- [ ] Database migrations ready
- [ ] Build succeeds locally
- [ ] Bundle size analyzed
- [ ] Security headers configured
- [ ] HTTPS/SSL configured
- [ ] Error tracking setup
- [ ] Analytics configured
- [ ] Monitoring setup

### Configuration Checklist

```typescript
// next.config.js
module.exports = {
 reactStrictMode: true, // ✅
 swcMinify: true, // ✅
 poweredByHeader: false, // ✅
 compress: true, // ✅
 productionBrowserSourceMaps: false, // ✅

 // Security headers
 async headers {
 return [
 {
 source: '/:path*',
 headers: [
 { key: 'X-DNS-Prefetch-Control', value: 'on' },
 { key: 'X-Frame-Options', value: 'DENY' },
 { key: 'X-Content-Type-Options', value: 'nosniff' },
 { key: 'X-XSS-Protection', value: '1; mode=block' },
 { key: 'Referrer-Policy', value: 'origin-when-cross-origin' },
 ],
 },
 ];
 },
};
```

---

## Monitoring & Analytics

### Vercel Analytics

```typescript
// app/layout.tsx
import { Analytics } from '@vercel/analytics/react';
import { SpeedInsights } from '@vercel/speed-insights/next';

export default function RootLayout({ children }: { children: React.ReactNode }) {
 return (
 <html>
 <body>
 {children}
 <Analytics />
 <SpeedInsights />
 </body>
 </html>
 );
}
```

### Sentry Error Tracking

```typescript
// sentry.client.config.ts
import * as Sentry from '@sentry/nextjs';

Sentry.init({
 dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
 tracesSampleRate: 1.0,
 environment: process.env.NODE_ENV,
});

// sentry.server.config.ts
import * as Sentry from '@sentry/nextjs';

Sentry.init({
 dsn: process.env.SENTRY_DSN,
 tracesSampleRate: 1.0,
});
```

### Custom Health Check

```typescript
// app/api/health/route.ts (this project has this)
import { NextResponse } from 'next/server';
import { prisma } from '@/lib/db';

export async function GET {
 try {
 // Check database
 await prisma.$queryRaw`SELECT 1`;

 return NextResponse.json({
 status: 'healthy',
 timestamp: new Date.toISOString,
 uptime: process.uptime,
 });
 } catch (error) {
 return NextResponse.json(
 { status: 'unhealthy', error: 'Database unavailable' },
 { status: 503 }
 );
 }
}
```

---

## Best Practices

### ✅ DO

1. **Use environment variables for secrets**
```bash
# Never commit
DATABASE_URL=...
API_KEY=...
```

2. **Enable security headers**
```javascript
async headers {
 return [{ source: '/:path*', headers: [...] }];
}
```

3. **Use standalone output for Docker**
```javascript
module.exports = {
 output: 'standalone',
};
```

4. **Run database migrations before deploy**
```bash
npm run migrate:deploy && npm run build
```

5. **Monitor production errors**
```typescript
import * as Sentry from '@sentry/nextjs';
```

### ❌ DON'T

1. **Don't commit secrets**
```bash
# ❌ Never commit.env.local
# ✅ Add to.gitignore
echo ".env*.local" >>.gitignore
```

2. **Don't skip tests in CI**
```yaml
# ❌ Bad
- run: npm run build

# ✅ Good
- run: npm test
- run: npm run build
```

3. **Don't deploy without migrations**
```bash
# ❌ Bad
npm run build && deploy

# ✅ Good
npm run migrate:deploy && npm run build && deploy
```

---

## Summary

### Deployment Options
- **Vercel**: Zero-config, automatic (easiest)
- **Docker**: Portable, self-hosted (this project uses this)
- **Node.js**: Traditional VPS hosting
- **Static Export**: CDN deployment

### this project Production Stack
- Docker container
- SQLite database (DELETE mode)
- Port 3000 (Docker), 3001 (dev)
- GitHub Actions CI/CD
- Health check endpoint
- Logging system

---

**Next**: [09-TESTING.md](./09-TESTING.md) - Learn about testing strategies

**Last Updated**: November 9, 2025
**Status**: Production-Ready ✅
