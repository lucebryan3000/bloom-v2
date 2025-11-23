---
id: nextjs-readme
topic: nextjs
file_role: overview
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: ['react', 'javascript']
related_topics: ['react', 'typescript', 'web']
embedding_keywords: [nextjs, overview, introduction, getting-started]
last_reviewed: 2025-11-13
---

# Next.js Comprehensive Knowledge Base

Welcome to the organized Next.js knowledge base for developing production-grade applications. This KB is split into **14 focused topic categories** for easy navigation, plus quick references and project-specific patterns.

---

## 📚 Documentation Structure (14-Part Series)

### **Quick Navigation**
- **[INDEX.md](./INDEX.md)** - Complete index with learning paths (start here!)
- **[QUICK-REFERENCE.md](./QUICK-REFERENCE.md)** - Cheat sheet for quick lookups (900+ lines)
- **[FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md)** - Real production patterns (900+ lines)

### **Core Topics (14 Files)**

| # | Topic | File | Focus |
|---|-------|------|-------|
| 1 | **Fundamentals** | [01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md) | Setup, structure, basics |
| 2 | **Routing** | [02-ROUTING.md](./02-ROUTING.md) | File-based routing, dynamic routes |
| 3 | **Data Fetching** | [03-DATA-FETCHING.md](./03-DATA-FETCHING.md) | SSG, SSR, ISR, caching |
| 4 | **Rendering** | [04-RENDERING.md](./04-RENDERING.md) | Server/Client components, streaming |
| 5 | **API Routes** | [05-API-ROUTES.md](./05-API-ROUTES.md) | Backend endpoints, route handlers |
| 6 | **Styling** | [06-STYLING.md](./06-STYLING.md) | Tailwind, CSS Modules, theming |
| 7 | **Optimization** | [07-OPTIMIZATION.md](./07-OPTIMIZATION.md) | Images, fonts, performance |
| 8 | **Deployment** | [08-DEPLOYMENT.md](./08-DEPLOYMENT.md) | Vercel, Docker, production |
| 9 | **Testing** | [09-TESTING.md](./09-TESTING.md) | Jest, Playwright, testing strategies |
| 10 | **Advanced** | [10-ADVANCED.md](./10-ADVANCED.md) | Middleware, Server Actions, i18n |
| 11 | **Best Practices** | [11-CONFIG-BEST-PRACTICES.md](./11-CONFIG-BEST-PRACTICES.md) | Config, security, performance |

---

## 🚀 Getting Started

### Installation

```bash
# Create new Next.js app with TypeScript and Tailwind
npx create-next-app@latest my-app --typescript --tailwind --app

# Navigate to project
cd my-app

# Install dependencies
npm install

# Run development server
npm run dev
```

Visit http://localhost:3000 to see your app.

---

### First Next.js Page

**Create a simple page:**

```typescript
// app/page.tsx
export default function Home {
 return (
 <main className="flex min-h-screen flex-col items-center justify-center p-24">
 <h1 className="text-4xl font-bold">Welcome to Next.js!</h1>
 <p className="mt-4 text-lg">
 Start editing app/page.tsx to see changes.
 </p>
 </main>
 );
}
```

**Add metadata:**

```typescript
// app/layout.tsx
import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
 title: 'My Next.js App',
 description: 'Built with Next.js 16',
};

export default function RootLayout({
 children,
}: {
 children: React.ReactNode;
}) {
 return (
 <html lang="en">
 <body>{children}</body>
 </html>
 );
}
```

**Create an about page:**

```typescript
// app/about/page.tsx
export default function About {
 return (
 <div className="p-24">
 <h1 className="text-4xl font-bold">About Us</h1>
 <p className="mt-4">This is the about page.</p>
 </div>
 );
}
```

Now visit:
- http://localhost:3000 → Home page
- http://localhost:3000/about → About page

---

## 📋 Common Tasks

### "I need to create a new page"
1. Create a new folder in `app/` with your route name
2. Add a `page.tsx` file inside that folder
3. Export a default React component
4. **See**: [01-FUNDAMENTALS.md - Pages](./01-FUNDAMENTALS.md#pages)

### "I need to fetch data from an API"
1. Use `async/await` in Server Components (default)
2. Use `fetch` with caching options
3. Handle errors with try/catch
4. **See**: [03-DATA-FETCHING.md - Server Components](./03-DATA-FETCHING.md)

### "I need to use React hooks (useState, useEffect)"
1. Add `'use client'` directive at the top of your file
2. Import and use hooks normally
3. **See**: [04-RENDERING.md - Client Components](./04-RENDERING.md#client-components)

### "I need to create an API endpoint"
1. Create a folder in `app/api/`
2. Add a `route.ts` file
3. Export async functions: GET, POST, PUT, DELETE
4. **See**: [05-API-ROUTES.md](./05-API-ROUTES.md)

### "I need to optimize images"
1. Use the `next/image` component instead of `<img>`
2. Provide width and height or use `fill`
3. **See**: [07-OPTIMIZATION.md - Images](./07-OPTIMIZATION.md)

### "I need to add authentication"
1. Use middleware for route protection
2. Check auth state in Server Components
3. **See**: [FRAMEWORK-INTEGRATION-PATTERNS.md - Authentication](./FRAMEWORK-INTEGRATION-PATTERNS.md#authentication-patterns)

### "I need to handle forms"
1. Use Server Actions for form submissions
2. Or use API routes with client-side fetch
3. **See**: [10-ADVANCED.md - Server Actions](./10-ADVANCED.md)

### "I need to add a database"
1. Install Prisma: `npm install prisma @prisma/client`
2. Set up database URL in `.env`
3. Create Prisma schema
4. **See**: [FRAMEWORK-INTEGRATION-PATTERNS.md - Prisma](./FRAMEWORK-INTEGRATION-PATTERNS.md#database-integration-prisma--sqlite)

---

## 🎯 Key Principles

### 1. **Server Components by Default**

Next.js uses Server Components by default. They:
- Run on the server only
- Can fetch data directly (async/await)
- Have zero JavaScript bundle sent to client
- Can access backend resources (databases, files)

```typescript
// Server Component (default - no directive needed)
async function getData {
 const res = await fetch('https://api.example.com/data');
 return res.json;
}

export default async function Page {
 const data = await getData;
 return <div>{JSON.stringify(data)}</div>;
}
```

### 2. **Client Components for Interactivity**

Use Client Components when you need:
- React hooks (useState, useEffect, etc.)
- Browser APIs (localStorage, navigator, etc.)
- Event handlers (onClick, onChange, etc.)
- Third-party libraries that use browser features

```typescript
'use client';

import { useState } from 'react';

export default function Counter {
 const [count, setCount] = useState(0);
 return (
 <button onClick={ => setCount(count + 1)}>
 Count: {count}
 </button>
 );
}
```

### 3. **File-Based Routing**

The folder structure in `app/` determines your routes:

```
app/
├── page.tsx → /
├── about/
│ └── page.tsx → /about
├── blog/
│ ├── page.tsx → /blog
│ └── [slug]/
│ └── page.tsx → /blog/hello-world
└── api/
 └── users/
 └── route.ts → /api/users
```

### 4. **Layouts for Shared UI**

Layouts wrap pages and persist across navigation:

```typescript
// app/layout.tsx (Root Layout - Required)
export default function RootLayout({ children }: { children: React.ReactNode }) {
 return (
 <html lang="en">
 <body>
 <nav>Global Navigation</nav>
 {children}
 <footer>Global Footer</footer>
 </body>
 </html>
 );
}
```

### 5. **Automatic Code Splitting**

Next.js automatically splits code by route:
- Each page only loads the code it needs
- Shared code is bundled efficiently
- Dynamic imports for on-demand loading

### 6. **Built-in Optimization**

Next.js optimizes automatically:
- **Images**: Resize, optimize, lazy load (next/image)
- **Fonts**: Self-host Google Fonts (next/font)
- **Scripts**: Control loading strategy (next/script)
- **CSS**: Extract and minimize automatically

---

## 🔧 Configuration Essentials

### Essential next.config.js

```javascript
/** @type {import('next').NextConfig} */
const nextConfig = {
 // Enable React strict mode
 reactStrictMode: true,

 // Configure external images
 images: {
 domains: ['example.com'],
 remotePatterns: [
 {
 protocol: 'https',
 hostname: '**.example.com',
 },
 ],
 },

 // Environment variables
 env: {
 CUSTOM_KEY: process.env.CUSTOM_KEY,
 },
};

module.exports = nextConfig;
```

### Environment Variables

```bash
#.env.local (local development - not committed)
DATABASE_URL="postgresql://..."
NEXT_PUBLIC_API_URL="https://api.example.com"

#.env.production (production)
DATABASE_URL="postgresql://..."
```

**Rules:**
- Server-side: `DATABASE_URL` (not exposed to browser)
- Client-side: `NEXT_PUBLIC_API_URL` (must have `NEXT_PUBLIC_` prefix)

### TypeScript Configuration

```json
{
 "compilerOptions": {
 "target": "ES2020",
 "lib": ["dom", "dom.iterable", "esnext"],
 "allowJs": true,
 "skipLibCheck": true,
 "strict": true,
 "forceConsistentCasingInFileNames": true,
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
 }
 },
 "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
 "exclude": ["node_modules"]
}
```

---

## ⚠️ Common Issues & Solutions

### Issue: "Cannot use hooks in Server Component"

**Error:**
```
Error: useState is not a function
```

**Cause:** Using React hooks in a Server Component

**Solution:** Add `'use client'` directive at the top of the file

```typescript
'use client';

import { useState } from 'react';

export default function MyComponent {
 const [state, setState] = useState(0);
 //...
}
```

---

### Issue: "Module not found: Can't resolve 'fs'"

**Error:**
```
Module not found: Can't resolve 'fs'
```

**Cause:** Importing Node.js modules (fs, path, etc.) in Client Component

**Solution:** Only use Node.js modules in Server Components or API routes

---

### Issue: "Hydration failed"

**Error:**
```
Hydration failed because the initial UI does not match what was rendered on the server
```

**Cause:** Different HTML on server vs client (often from browser extensions or conditional rendering)

**Solution:**
1. Ensure consistent rendering between server and client
2. Use `suppressHydrationWarning` for intentional differences
3. Check for browser extensions affecting the DOM

---

### Issue: "NEXT_PUBLIC_ variable not defined"

**Error:**
```
process.env.NEXT_PUBLIC_API_URL is undefined
```

**Cause:** Client-side environment variable missing `NEXT_PUBLIC_` prefix

**Solution:** Add `NEXT_PUBLIC_` prefix to variable name

```bash
# Wrong
API_URL="https://api.example.com"

# Correct
NEXT_PUBLIC_API_URL="https://api.example.com"
```

---

### Issue: "Image is missing required width and height"

**Error:**
```
Image with src "..." is missing required "width" or "height" properties
```

**Solution:** Provide width/height or use `fill` prop

```typescript
// Option 1: Provide dimensions
<Image src="/photo.jpg" alt="Photo" width={800} height={600} />

// Option 2: Use fill (with parent container)
<div className="relative w-full h-96">
 <Image src="/photo.jpg" alt="Photo" fill className="object-cover" />
</div>
```

---

### Issue: "Cannot access headers in Client Component"

**Error:**
```
Error: headers is not available in Client Components
```

**Cause:** Using server-only functions in Client Component

**Solution:** Move to Server Component or API route

```typescript
// Server Component or API route only
import { headers } from 'next/headers';

export default async function Page {
 const headersList = headers;
 const userAgent = headersList.get('user-agent');
 return <div>{userAgent}</div>;
}
```

---

## 📊 Learning Path

### **Beginner** (2-4 hours)
1. Read: [01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md)
2. Read: [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) sections 1-5
3. Build: Simple multi-page website
4. Practice: File-based routing and navigation

**You'll learn:**
- Project structure
- Server vs Client Components
- Basic routing
- Layout and page files
- Navigation with Link

---

### **Intermediate** (6-10 hours)
1. All Beginner materials
2. Read: [02-ROUTING.md](./02-ROUTING.md) - Dynamic routes
3. Read: [03-DATA-FETCHING.md](./03-DATA-FETCHING.md) - Data patterns
4. Read: [05-API-ROUTES.md](./05-API-ROUTES.md) - Building APIs
5. Read: [06-STYLING.md](./06-STYLING.md) - Tailwind CSS
6. Build: Blog with dynamic routes and API

**You'll learn:**
- Dynamic routing
- Data fetching (SSG, SSR, ISR)
- API routes
- Error handling
- Loading states
- Styling with Tailwind

---

### **Advanced** (12-20 hours)
1. All Intermediate materials
2. Read: [04-RENDERING.md](./04-RENDERING.md) - Rendering strategies
3. Read: [07-OPTIMIZATION.md](./07-OPTIMIZATION.md) - Performance
4. Read: [09-TESTING.md](./09-TESTING.md) - Testing
5. Read: [10-ADVANCED.md](./10-ADVANCED.md) - Advanced patterns
6. Read: [11-CONFIG-BEST-PRACTICES.md](./11-CONFIG-BEST-PRACTICES.md)
7. Build: Full-stack application with database

**You'll learn:**
- Streaming with Suspense
- Server Actions
- Middleware
- Performance optimization
- Testing strategies
- Best practices
- Security patterns

---

### **Expert** (20+ hours)
1. All Advanced materials
2. Read: [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md)
3. Read: [08-DEPLOYMENT.md](./08-DEPLOYMENT.md)
4. Study: Real production codebases
5. Build: Production-ready SaaS application

**You'll learn:**
- Real-world production patterns
- Database integration (Prisma)
- State management (Zustand)
- SSE streaming
- Health checks
- Deployment strategies
- Production optimization

---

## 🎓 External Resources

### Official Documentation
- **Next.js Docs**: https://nextjs.org/docs
- **Next.js Learn**: https://nextjs.org/learn
- **Next.js Examples**: https://github.com/vercel/next.js/tree/canary/examples
- **Next.js Blog**: https://nextjs.org/blog

### Video Tutorials
- **Vercel YouTube**: https://www.youtube.com/@VercelHQ
- **Lee Robinson (Vercel VP)**: https://www.youtube.com/@leerob

### Community
- **Next.js Discord**: https://nextjs.org/discord
- **Next.js Reddit**: https://www.reddit.com/r/nextjs/
- **Next.js GitHub Discussions**: https://github.com/vercel/next.js/discussions

### Tools & Libraries
- **shadcn/ui Components**: https://ui.shadcn.com/
- **Tailwind CSS**: https://tailwindcss.com/
- **Prisma ORM**: https://www.prisma.io/
- **Zod Validation**: https://zod.dev/
- **Playwright Testing**: https://playwright.dev/

---

## 📚 Files in This Directory

```
docs/kb/nextjs/
├── README.md # This file
├── INDEX.md # Complete navigation index
├── QUICK-REFERENCE.md # Cheat sheet (900+ lines)
├── FRAMEWORK-INTEGRATION-PATTERNS.md # Real production patterns (900+ lines)
├── 01-FUNDAMENTALS.md # Getting started
├── 02-ROUTING.md # File-based routing
├── 03-DATA-FETCHING.md # Data patterns
├── 04-RENDERING.md # Server/Client components
├── 05-API-ROUTES.md # Backend routes
├── 06-STYLING.md # CSS & Tailwind
├── 07-OPTIMIZATION.md # Performance
├── 08-DEPLOYMENT.md # Production deployment
├── 09-TESTING.md # Testing strategies
├── 10-ADVANCED.md # Advanced patterns
└── 11-CONFIG-BEST-PRACTICES.md # Config & best practices
```

**Total**: 6,500+ lines of comprehensive Next.js documentation

---

## 🚀 Next Steps

### **New to Next.js?**
→ Start with [01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md)
→ Then review [QUICK-REFERENCE.md](./QUICK-REFERENCE.md)

### **Building a specific feature?**
→ Check [INDEX.md](./INDEX.md) for quick navigation
→ Reference [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) while coding

### **Working on this project?**
→ Study [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md)
→ Use real production code examples

### **Ready to deploy?**
→ Review [08-DEPLOYMENT.md](./08-DEPLOYMENT.md)
→ Check [11-CONFIG-BEST-PRACTICES.md](./11-CONFIG-BEST-PRACTICES.md)

### **Need quick answers?**
→ Use [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) as your cheat sheet
→ Covers 90% of daily development tasks

---

## 💡 Pro Tips

1. **Start with Server Components** - Use Client Components only when needed
2. **Use the App Router** - It's the future of Next.js (not Pages Router)
3. **Leverage caching** - Understand fetch cache options
4. **Optimize images** - Always use next/image
5. **Type everything** - Use TypeScript for better DX
6. **Read error messages** - Next.js provides helpful error messages
7. **Use the Quick Reference** - Bookmark [QUICK-REFERENCE.md](./QUICK-REFERENCE.md)
8. **Study real code** - Review [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md)

---

**Last Updated**: November 9, 2025
**Status**: Production-Ready
**Version**: 2.0.0

Happy building! 🎉
