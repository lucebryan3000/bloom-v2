---
id: nextjs-11-config-best-practices
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

# Next.js Configuration & Best Practices

**Part 11 of 11 - The Next.js Knowledge Base**

## Table of Contents
1. [next.config.js Complete Reference](#nextconfigjs-complete-reference)
2. [TypeScript Configuration](#typescript-configuration)
3. [ESLint Setup](#eslint-setup)
4. [Performance Optimization](#performance-optimization)
5. [Security Best Practices](#security-best-practices)
6. [Common Pitfalls](#common-pitfalls)
7. [Production Checklist](#production-checklist)
8. [Debugging Tips](#debugging-tips)
9. [this project Configuration](#this project-configuration)
10. [Summary](#summary)

---

## next.config.js Complete Reference

### Essential Configuration (this project-based)

```javascript
// next.config.js
/** @type {import('next').NextConfig} */
const nextConfig = {
 // TypeScript
 typescript: {
 // Ignore build errors in production (NOT recommended)
 ignoreBuildErrors: false,
 },

 // ESLint
 eslint: {
 // Directories to lint during build
 dirs: ['app', 'components', 'lib', 'stores'],
 // Ignore lint errors during build (NOT recommended)
 ignoreDuringBuilds: false,
 },

 // React
 reactStrictMode: true,

 // Compiler
 swcMinify: true,

 // Output
 output: 'standalone', // For Docker (this project uses this)

 // Compression
 compress: true,

 // Headers
 poweredByHeader: false,

 // Source maps
 productionBrowserSourceMaps: false,

 // Trailing slash
 trailingSlash: false,

 // Images
 images: {
 domains: [],
 remotePatterns: [
 {
 protocol: 'https',
 hostname: '**.example.com',
 },
 ],
 formats: ['image/avif', 'image/webp'],
 deviceSizes: [640, 750, 828, 1080, 1200, 1920, 2048, 3840],
 imageSizes: [16, 32, 48, 64, 96, 128, 256, 384],
 },

 // Redirects
 async redirects {
 return [
 {
 source: '/old-path',
 destination: '/new-path',
 permanent: true,
 },
 ];
 },

 // Rewrites
 async rewrites {
 return [
 {
 source: '/api/:path*',
 destination: 'https://api.example.com/:path*',
 },
 ];
 },

 // Headers
 async headers {
 return [
 {
 source: '/:path*',
 headers: [
 {
 key: 'X-DNS-Prefetch-Control',
 value: 'on',
 },
 {
 key: 'Strict-Transport-Security',
 value: 'max-age=63072000; includeSubDomains; preload',
 },
 {
 key: 'X-Frame-Options',
 value: 'DENY',
 },
 {
 key: 'X-Content-Type-Options',
 value: 'nosniff',
 },
 {
 key: 'X-XSS-Protection',
 value: '1; mode=block',
 },
 {
 key: 'Referrer-Policy',
 value: 'origin-when-cross-origin',
 },
 {
 key: 'Permissions-Policy',
 value: 'camera=, microphone=, geolocation=',
 },
 ],
 },
 ];
 },

 // Environment variables
 env: {
 CUSTOM_KEY: process.env.CUSTOM_KEY,
 },

 // Experimental features
 experimental: {
 serverActions: {
 allowedOrigins: ['localhost:3001'],
 },
 },

 // Webpack customization (advanced)
 webpack: (config, { isServer }) => {
 // Custom webpack config
 return config;
 },
};

module.exports = nextConfig;
```

### Advanced Features

```javascript
// next.config.js (advanced)
module.exports = {
 // Static export
 output: 'export',

 // Base path
 basePath: '/docs',

 // Asset prefix (CDN)
 assetPrefix: 'https://cdn.example.com',

 // Generate build ID
 generateBuildId: async => {
 return process.env.GIT_HASH || 'build-id';
 },

 // Page extensions
 pageExtensions: ['tsx', 'ts', 'jsx', 'js', 'mdx'],

 // Disable x-powered-by
 poweredByHeader: false,

 // Generate etags
 generateEtags: true,

 // Compression
 compress: true,

 // Dev indicators
 devIndicators: {
 buildActivity: true,
 buildActivityPosition: 'bottom-right',
 },

 // On-demand entries
 onDemandEntries: {
 maxInactiveAge: 25 * 1000,
 pagesBufferLength: 2,
 },

 // HTTP Agent options
 httpAgentOptions: {
 keepAlive: true,
 },
};
```

### Bundle Analyzer

```javascript
// next.config.js
const withBundleAnalyzer = require('@next/bundle-analyzer')({
 enabled: process.env.ANALYZE === 'true',
});

module.exports = withBundleAnalyzer({
 // Your config
});
```

---

## TypeScript Configuration

### tsconfig.json (this project Configuration)

```json
{
 "compilerOptions": {
 "target": "ES2020",
 "lib": ["dom", "dom.iterable", "esnext"],
 "allowJs": true,
 "skipLibCheck": true,
 "strict": true,
 "noEmit": true,
 "esModuleInterop": true,
 "module": "esnext",
 "moduleResolution": "bundler",
 "resolveJsonModule": true,
 "isolatedModules": true,
 "jsx": "preserve",
 "incremental": true,
 "plugins": [
 {
 "name": "next"
 }
 ],
 "paths": {
 "@/*": ["./*"]
 },
 "forceConsistentCasingInFileNames": true,

 // Strict checks
 "noImplicitAny": true,
 "strictNullChecks": true,
 "strictFunctionTypes": true,
 "strictBindCallApply": true,
 "strictPropertyInitialization": true,
 "noImplicitThis": true,
 "alwaysStrict": true,

 // Linter checks
 "noUnusedLocals": true,
 "noUnusedParameters": true,
 "noImplicitReturns": true,
 "noFallthroughCasesInSwitch": true,
 "noUncheckedIndexedAccess": true
 },
 "include": [
 "next-env.d.ts",
 "**/*.ts",
 "**/*.tsx",
 ".next/types/**/*.ts"
 ],
 "exclude": ["node_modules"]
}
```

### Type Definitions

```typescript
// types/index.d.ts
declare global {
 namespace NodeJS {
 interface ProcessEnv {
 DATABASE_URL: string;
 ANTHROPIC_API_KEY: string;
 NEXTAUTH_SECRET: string;
 NEXTAUTH_URL: string;
 REDIS_URL?: string;
 }
 }
}

export {};

// types/prisma.d.ts
import { PrismaClient } from '@prisma/client';

declare global {
 var prisma: PrismaClient | undefined;
}

export {};
```

---

## ESLint Setup

###.eslintrc.json (this project Configuration)

```json
{
 "extends": [
 "next/core-web-vitals",
 "plugin:@typescript-eslint/recommended"
 ],
 "parser": "@typescript-eslint/parser",
 "parserOptions": {
 "ecmaVersion": "latest",
 "sourceType": "module"
 },
 "plugins": ["@typescript-eslint"],
 "rules": {
 "@typescript-eslint/no-unused-vars": "error",
 "@typescript-eslint/no-explicit-any": "warn",
 "@typescript-eslint/explicit-function-return-type": "off",
 "@typescript-eslint/explicit-module-boundary-types": "off",
 "react/react-in-jsx-scope": "off",
 "react/prop-types": "off",
 "no-console": ["warn", { "allow": ["warn", "error"] }],
 "prefer-const": "error",
 "no-var": "error"
 },
 "ignorePatterns": [
 "node_modules/",
 ".next/",
 "out/",
 "public/",
 "*.config.js"
 ]
}
```

### Prettier Configuration

```json
{
 "semi": true,
 "trailingComma": "es5",
 "singleQuote": true,
 "printWidth": 100,
 "tabWidth": 2,
 "useTabs": false,
 "arrowParens": "always",
 "endOfLine": "lf"
}
```

---

## Performance Optimization

### Build Optimization

```javascript
// next.config.js
module.exports = {
 // Enable SWC minification
 swcMinify: true,

 // Compiler optimizations
 compiler: {
 // Remove console.log in production
 removeConsole: process.env.NODE_ENV === 'production',
 },

 // Optimize packages
 experimental: {
 optimizePackageImports: [
 'lodash',
 'date-fns',
 '@mui/material',
 ],
 },

 // Webpack optimizations
 webpack: (config, { isServer }) => {
 if (!isServer) {
 config.optimization = {
...config.optimization,
 splitChunks: {
 chunks: 'all',
 cacheGroups: {
 default: false,
 vendors: false,
 commons: {
 name: 'commons',
 chunks: 'all',
 minChunks: 2,
 },
 },
 },
 };
 }
 return config;
 },
};
```

### Runtime Optimization

```typescript
// Optimize imports
import dynamic from 'next/dynamic';

// Lazy load heavy components
const HeavyComponent = dynamic( => import('./HeavyComponent'), {
 loading: => <Skeleton />,
 ssr: false,
});

// Optimize images
import Image from 'next/image';

<Image
 src="/hero.jpg"
 width={800}
 height={600}
 priority // Above the fold
 placeholder="blur"
 alt="Hero"
/>

// Optimize fonts
import { Inter } from 'next/font/google';

const inter = Inter({
 subsets: ['latin'],
 display: 'swap',
 preload: true,
});
```

---

## Security Best Practices

### Security Headers

```javascript
// next.config.js
module.exports = {
 async headers {
 return [
 {
 source: '/:path*',
 headers: [
 // HSTS
 {
 key: 'Strict-Transport-Security',
 value: 'max-age=63072000; includeSubDomains; preload',
 },
 // Prevent clickjacking
 {
 key: 'X-Frame-Options',
 value: 'DENY',
 },
 // Prevent MIME sniffing
 {
 key: 'X-Content-Type-Options',
 value: 'nosniff',
 },
 // XSS protection
 {
 key: 'X-XSS-Protection',
 value: '1; mode=block',
 },
 // Referrer policy
 {
 key: 'Referrer-Policy',
 value: 'origin-when-cross-origin',
 },
 // Permissions policy
 {
 key: 'Permissions-Policy',
 value: 'camera=, microphone=, geolocation=',
 },
 // CSP (Content Security Policy)
 {
 key: 'Content-Security-Policy',
 value: [
 "default-src 'self'",
 "script-src 'self' 'unsafe-eval' 'unsafe-inline'",
 "style-src 'self' 'unsafe-inline'",
 "img-src 'self' data: https:",
 "font-src 'self' data:",
 "connect-src 'self'",
 ].join('; '),
 },
 ],
 },
 ];
 },
};
```

### Input Validation

```typescript
import { z } from 'zod';

// Always validate input
const userSchema = z.object({
 email: z.string.email,
 password: z.string.min(8),
});

// Use in API routes
export async function POST(request: Request) {
 const body = await request.json;

 try {
 const validated = userSchema.parse(body);
 // Process validated data
 } catch (error) {
 return NextResponse.json({ error: 'Invalid input' }, { status: 400 });
 }
}
```

### Environment Variables Security

```bash
#.env.local (NEVER commit)
DATABASE_URL="postgresql://..."
API_KEY="secret-key"

#.env.example (commit this)
DATABASE_URL="postgresql://localhost:5432/mydb"
API_KEY="your-api-key-here"

#.gitignore
.env*.local
.env.production
```

---

## Common Pitfalls

### ❌ Pitfall 1: Not Using Server Components

```typescript
// ❌ Bad: Unnecessary Client Component
'use client';

export default function Page {
 return <div>Static content</div>;
}

// ✅ Good: Server Component by default
export default function Page {
 return <div>Static content</div>;
}
```

### ❌ Pitfall 2: Fetching in Client Components

```typescript
// ❌ Bad: Client-side fetching
'use client';

export default function Page {
 const [data, setData] = useState(null);

 useEffect( => {
 fetch('/api/data').then(r => r.json).then(setData);
 }, []);
}

// ✅ Good: Server-side fetching
export default async function Page {
 const data = await fetch('/api/data');
 return <Component data={data} />;
}
```

### ❌ Pitfall 3: Ignoring Cache Configuration

```typescript
// ❌ Bad: No cache control
fetch('https://api.example.com/data');

// ✅ Good: Explicit cache control
fetch('https://api.example.com/data', {
 cache: 'force-cache', // or 'no-store'
 next: { revalidate: 60 },
});
```

### ❌ Pitfall 4: Missing Image Optimization

```typescript
// ❌ Bad: Using <img>
<img src="/hero.jpg" alt="Hero" />

// ✅ Good: Using next/image
<Image src="/hero.jpg" width={800} height={600} alt="Hero" />
```

### ❌ Pitfall 5: Not Handling Loading States

```typescript
// ❌ Bad: No loading state
export default async function Page {
 const data = await fetchData;
 return <Component data={data} />;
}

// ✅ Good: With loading.tsx
// app/page.tsx
export default async function Page {
 const data = await fetchData;
 return <Component data={data} />;
}

// app/loading.tsx
export default function Loading {
 return <Skeleton />;
}
```

---

## Production Checklist

### Before Deployment

- [ ] All tests passing (`npm test`)
- [ ] TypeScript errors resolved (`npm run type-check`)
- [ ] ESLint warnings fixed (`npm run lint`)
- [ ] Build succeeds (`npm run build`)
- [ ] Bundle size analyzed (`ANALYZE=true npm run build`)
- [ ] Environment variables configured
- [ ] Security headers configured
- [ ] Database migrations ready
- [ ] Error tracking setup (Sentry)
- [ ] Analytics configured
- [ ] Performance monitoring setup
- [ ] HTTPS/SSL configured
- [ ] Rate limiting implemented
- [ ] CORS configured correctly
- [ ] API keys secured
- [ ] Secrets not committed

### Configuration Checklist

```javascript
// next.config.js
module.exports = {
 reactStrictMode: true, // ✅
 swcMinify: true, // ✅
 poweredByHeader: false, // ✅
 compress: true, // ✅
 productionBrowserSourceMaps: false, // ✅

 async headers {
 // Security headers configured ✅
 },
};
```

---

## Debugging Tips

### Enable Verbose Logging

```bash
# Debug build
DEBUG=* npm run build

# Debug runtime
NODE_OPTIONS='--inspect' npm run dev
```

### Analyze Bundle

```bash
# Install analyzer
npm install @next/bundle-analyzer

# Analyze
ANALYZE=true npm run build
```

### Check Build Output

```bash
# Build with profiling
npm run build -- --profile

# Check build size
ls -lh.next/static/chunks/
```

### Common Errors

```typescript
// Error: Hydration mismatch
// Fix: Ensure server and client render the same content

// Error: Module not found
// Fix: Check import paths and tsconfig paths

// Error: Cannot read property of undefined
// Fix: Add null checks and optional chaining

// Error: Maximum call stack exceeded
// Fix: Check for circular dependencies
```

---

## this project Configuration

### Production Setup (this project)

```javascript
// next.config.js (this project)
module.exports = {
 reactStrictMode: true,
 swcMinify: true,
 output: 'standalone',
 compress: true,
 poweredByHeader: false,
 productionBrowserSourceMaps: false,

 images: {
 domains: [],
 formats: ['image/avif', 'image/webp'],
 },

 async headers {
 return [
 {
 source: '/:path*',
 headers: [
 { key: 'X-Frame-Options', value: 'DENY' },
 { key: 'X-Content-Type-Options', value: 'nosniff' },
 { key: 'X-XSS-Protection', value: '1; mode=block' },
 ],
 },
 ];
 },
};
```

### Environment Variables (this project)

```bash
#.env.local
DATABASE_URL="file:./this project.db"
ANTHROPIC_API_KEY="sk-ant-..."
NEXTAUTH_SECRET="..."
NEXTAUTH_URL="http://localhost:3001"
LOG_LEVEL="info"
DEBUG="this project:*"
NODE_OPTIONS="--max-old-space-size=4096"
```

---

## Summary

### Essential Configuration
- ✅ TypeScript strict mode enabled
- ✅ React strict mode enabled
- ✅ SWC minification enabled
- ✅ Security headers configured
- ✅ Image optimization configured
- ✅ Font optimization configured
- ✅ Bundle analysis available
- ✅ Error tracking setup
- ✅ Performance monitoring setup

### Production Targets (this project)
- Page load: < 2s (p90)
- API response: < 200ms (p95)
- Lighthouse score: > 90
- Test coverage: > 80%
- Bundle size: < 500KB (gzipped)

### Key Takeaways
1. Always use TypeScript strict mode
2. Configure security headers
3. Optimize images and fonts
4. Monitor performance
5. Analyze bundle size regularly
6. Test before deploying
7. Use environment variables for secrets
8. Enable compression
9. Implement rate limiting
10. Follow the App Router patterns

---

**Congratulations!** 🎉

**You've completed all 11 parts of the Next.js Knowledge Base!**

**Total Coverage**: 5,000+ lines of Next.js documentation

---

**Last Updated**: November 9, 2025
**Status**: Production-Ready ✅
