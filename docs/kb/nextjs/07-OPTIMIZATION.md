---
id: nextjs-07-optimization
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

# Next.js Optimization: Performance & Best Practices

**Part 7 of 11 - The Next.js Knowledge Base**

## Table of Contents
1. [Image Optimization](#image-optimization)
2. [Font Optimization](#font-optimization)
3. [Script Optimization](#script-optimization)
4. [Metadata API](#metadata-api)
5. [Bundle Analysis](#bundle-analysis)
6. [Code Splitting](#code-splitting)
7. [Lazy Loading](#lazy-loading)
8. [Performance Monitoring](#performance-monitoring)
9. [Caching Strategies](#caching-strategies)
10. [Core Web Vitals](#core-web-vitals)
11. [Best Practices](#best-practices)

---

## Image Optimization

### next/image Component

Next.js Image component automatically optimizes images:
- Lazy loading by default
- Automatic format conversion (WebP, AVIF)
- Responsive images
- Prevents Cumulative Layout Shift (CLS)

### Basic Image Usage

```typescript
import Image from 'next/image';

export default function Page {
 return (
 <div>
 {/* Local image (import) */}
 <Image
 src="/logo.png"
 alt="Company Logo"
 width={200}
 height={100}
 priority // Load immediately (above fold)
 />

 {/* Remote image */}
 <Image
 src="https://example.com/image.jpg"
 alt="Description"
 width={800}
 height={600}
 quality={85} // 1-100, default 75
 />
 </div>
 );
}
```

### Fill Container

```typescript
export default function HeroImage {
 return (
 <div className="relative w-full h-96">
 <Image
 src="/hero.jpg"
 alt="Hero"
 fill
 style={{ objectFit: 'cover' }}
 priority
 />
 </div>
 );
}
```

### Responsive Images

```typescript
export default function ResponsiveImage {
 return (
 <Image
 src="/product.jpg"
 alt="Product"
 width={800}
 height={600}
 sizes="(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 33vw"
 // Generates srcset for different screen sizes
 />
 );
}
```

### Image Configuration

```javascript
// next.config.js
module.exports = {
 images: {
 domains: ['example.com', 'cdn.example.com'], // Allowed image domains
 remotePatterns: [
 {
 protocol: 'https',
 hostname: '**.example.com',
 pathname: '/images/**',
 },
 ],
 formats: ['image/avif', 'image/webp'], // Preferred formats
 deviceSizes: [640, 750, 828, 1080, 1200, 1920, 2048, 3840],
 imageSizes: [16, 32, 48, 64, 96, 128, 256, 384],
 minimumCacheTTL: 60, // Seconds
 },
};
```

### Blur Placeholder

```typescript
import Image from 'next/image';
import productImage from '@/public/product.jpg';

export default function ProductImage {
 return (
 <Image
 src={productImage}
 alt="Product"
 placeholder="blur" // Automatic blur placeholder
 // Or custom blur data URL
 // blurDataURL="data:image/jpeg;base64,..."
 />
 );
}
```

### Image Loader

```typescript
// Custom image loader for CDN
const myLoader = ({ src, width, quality }: {
 src: string;
 width: number;
 quality?: number;
}) => {
 return `https://cdn.example.com/${src}?w=${width}&q=${quality || 75}`;
};

export default function CustomLoaderImage {
 return (
 <Image
 loader={myLoader}
 src="image.jpg"
 alt="Image"
 width={500}
 height={300}
 />
 );
}
```

---

## Font Optimization

### next/font (Automatic Optimization)

```typescript
// app/layout.tsx
import { Inter, JetBrains_Mono } from 'next/font/google';

// Google Fonts
const inter = Inter({
 subsets: ['latin'],
 display: 'swap',
 variable: '--font-inter',
});

const jetbrainsMono = JetBrains_Mono({
 subsets: ['latin'],
 display: 'swap',
 variable: '--font-jetbrains-mono',
});

export default function RootLayout({
 children,
}: {
 children: React.ReactNode;
}) {
 return (
 <html lang="en" className={`${inter.variable} ${jetbrainsMono.variable}`}>
 <body className="font-sans">{children}</body>
 </html>
 );
}
```

### Local Fonts

```typescript
import localFont from 'next/font/local';

const customFont = localFont({
 src: [
 {
 path: './fonts/CustomFont-Regular.woff2',
 weight: '400',
 style: 'normal',
 },
 {
 path: './fonts/CustomFont-Bold.woff2',
 weight: '700',
 style: 'normal',
 },
 ],
 variable: '--font-custom',
});

export default function RootLayout({ children }: { children: React.ReactNode }) {
 return (
 <html lang="en" className={customFont.variable}>
 <body>{children}</body>
 </html>
 );
}
```

### Font Configuration

```typescript
import { Inter } from 'next/font/google';

const inter = Inter({
 subsets: ['latin', 'latin-ext'],
 weight: ['400', '500', '600', '700'],
 style: ['normal', 'italic'],
 display: 'swap', // 'auto' | 'block' | 'swap' | 'fallback' | 'optional'
 preload: true,
 fallback: ['system-ui', 'arial'],
 adjustFontFallback: true, // Reduce CLS
 variable: '--font-inter',
});
```

---

## Script Optimization

### next/script Component

```typescript
import Script from 'next/script';

export default function Page {
 return (
 <>
 {/* Load after page interactive (default) */}
 <Script src="https://example.com/script.js" />

 {/* Load before page interactive (blocking) */}
 <Script
 src="https://example.com/critical.js"
 strategy="beforeInteractive"
 />

 {/* Load after page interactive (recommended) */}
 <Script
 src="https://example.com/analytics.js"
 strategy="afterInteractive"
 />

 {/* Lazy load when idle */}
 <Script
 src="https://example.com/widget.js"
 strategy="lazyOnload"
 />

 {/* Inline script */}
 <Script id="inline-script">
 {`console.log('Inline script');`}
 </Script>

 {/* With callback */}
 <Script
 src="https://example.com/lib.js"
 onLoad={ => {
 console.log('Script loaded');
 }}
 onError={(e) => {
 console.error('Script failed to load', e);
 }}
 />
 </>
 );
}
```

### Google Analytics Example

```typescript
// app/layout.tsx
import Script from 'next/script';

export default function RootLayout({ children }: { children: React.ReactNode }) {
 return (
 <html>
 <body>
 {children}
 <Script
 src={`https://www.googletagmanager.com/gtag/js?id=GA_MEASUREMENT_ID`}
 strategy="afterInteractive"
 />
 <Script id="google-analytics" strategy="afterInteractive">
 {`
 window.dataLayer = window.dataLayer || [];
 function gtag{dataLayer.push(arguments);}
 gtag('js', new Date);
 gtag('config', 'GA_MEASUREMENT_ID');
 `}
 </Script>
 </body>
 </html>
 );
}
```

---

## Metadata API

### Static Metadata

```typescript
// app/page.tsx
import type { Metadata } from 'next';

export const metadata: Metadata = {
 title: 'this application - ROI Discovery Workshop',
 description: '15-minute AI-guided ROI discovery workshop',
 keywords: ['ROI', 'business intelligence', 'AI'],
 authors: [{ name: '' }],
 openGraph: {
 title: 'this application',
 description: '15-minute ROI discovery workshop',
 images: ['/og-image.jpg'],
 type: 'website',
 },
 twitter: {
 card: 'summary_large_image',
 title: 'this application',
 description: '15-minute ROI discovery workshop',
 images: ['/twitter-image.jpg'],
 },
 robots: {
 index: true,
 follow: true,
 },
};

export default function Page {
 return <div>Content</div>;
}
```

### Dynamic Metadata

```typescript
// app/blog/[slug]/page.tsx
import type { Metadata } from 'next';

interface PageProps {
 params: { slug: string };
}

export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
 const post = await fetchPost(params.slug);

 return {
 title: post.title,
 description: post.excerpt,
 openGraph: {
 title: post.title,
 description: post.excerpt,
 images: [post.image],
 publishedTime: post.publishedAt,
 authors: [post.author],
 },
 };
}

export default async function BlogPost({ params }: PageProps) {
 const post = await fetchPost(params.slug);
 return <article>{/*... */}</article>;
}
```

### Metadata Templates

```typescript
// app/layout.tsx
export const metadata: Metadata = {
 metadataBase: new URL('https://this project..com'),
 title: {
 default: 'this application',
 template: '%s | this application', // "Page Title | this application"
 },
 description: 'Default description',
};

// app/blog/page.tsx
export const metadata: Metadata = {
 title: 'Blog', // Becomes "Blog | this application"
};
```

---

## Bundle Analysis

### Analyze Bundle Size

```bash
# Install
npm install @next/bundle-analyzer

# Analyze
ANALYZE=true npm run build
```

```javascript
// next.config.js
const withBundleAnalyzer = require('@next/bundle-analyzer')({
 enabled: process.env.ANALYZE === 'true',
});

module.exports = withBundleAnalyzer({
 // Your Next.js config
});
```

### Viewing Bundle Analysis

After running `ANALYZE=true npm run build`, two HTML files open:
- Client bundle analysis
- Server bundle analysis

Look for:
- Large dependencies (>100KB)
- Duplicate dependencies
- Unused code

---

## Code Splitting

### Automatic Code Splitting

Next.js automatically splits code by route:

```typescript
// Each page is a separate bundle
// app/page.tsx → page-[hash].js
// app/about/page.tsx → about-page-[hash].js
// app/blog/[slug]/page.tsx → blog-[slug]-page-[hash].js
```

### Dynamic Imports

```typescript
import dynamic from 'next/dynamic';

// Lazy load component
const DynamicComponent = dynamic( => import('@/components/HeavyComponent'));

export default function Page {
 return (
 <div>
 <DynamicComponent />
 </div>
 );
}

// With loading state
const DynamicComponentWithLoading = dynamic(
 => import('@/components/HeavyComponent'),
 {
 loading: => <p>Loading...</p>,
 ssr: false, // Disable SSR for this component
 }
);

// With named export
const DynamicComponentNamed = dynamic(
 => import('@/components/Components').then(mod => mod.SpecificComponent)
);
```

### Conditional Loading

```typescript
'use client';

import { useState } from 'react';
import dynamic from 'next/dynamic';

const AdminPanel = dynamic( => import('@/components/AdminPanel'));

export default function Page {
 const [showAdmin, setShowAdmin] = useState(false);

 return (
 <div>
 <button onClick={ => setShowAdmin(true)}>
 Load Admin Panel
 </button>
 {showAdmin && <AdminPanel />}
 </div>
 );
}
```

---

## Lazy Loading

### React Lazy + Suspense

```typescript
import { lazy, Suspense } from 'react';

const LazyComponent = lazy( => import('@/components/Component'));

export default function Page {
 return (
 <Suspense fallback={<div>Loading...</div>}>
 <LazyComponent />
 </Suspense>
 );
}
```

### Lazy Load on Interaction

```typescript
'use client';

import { useState } from 'react';
import dynamic from 'next/dynamic';

const Modal = dynamic( => import('@/components/Modal'), {
 ssr: false,
});

export default function Page {
 const [showModal, setShowModal] = useState(false);

 return (
 <>
 <button onClick={ => setShowModal(true)}>Open Modal</button>
 {showModal && <Modal onClose={ => setShowModal(false)} />}
 </>
 );
}
```

### Lazy Load on Scroll (Intersection Observer)

```typescript
'use client';

import { useEffect, useRef, useState } from 'react';
import dynamic from 'next/dynamic';

const ExpensiveComponent = dynamic( => import('@/components/Expensive'));

export default function Page {
 const [shouldRender, setShouldRender] = useState(false);
 const ref = useRef<HTMLDivElement>(null);

 useEffect( => {
 const observer = new IntersectionObserver(
 ([entry]) => {
 if (entry.isIntersecting) {
 setShouldRender(true);
 }
 },
 { threshold: 0.1 }
 );

 if (ref.current) {
 observer.observe(ref.current);
 }

 return => observer.disconnect;
 }, []);

 return (
 <div>
 <div ref={ref}>
 {shouldRender && <ExpensiveComponent />}
 </div>
 </div>
 );
}
```

---

## Performance Monitoring

### Web Vitals

```typescript
// app/layout.tsx
import { SpeedInsights } from '@vercel/speed-insights/next';
import { Analytics } from '@vercel/analytics/react';

export default function RootLayout({ children }: { children: React.ReactNode }) {
 return (
 <html>
 <body>
 {children}
 <SpeedInsights />
 <Analytics />
 </body>
 </html>
 );
}
```

### Custom Web Vitals Reporting

```typescript
// app/layout.tsx
'use client';

import { useReportWebVitals } from 'next/web-vitals';

export function WebVitals {
 useReportWebVitals((metric) => {
 console.log(metric);

 // Send to analytics
 switch (metric.name) {
 case 'FCP':
 // First Contentful Paint
 break;
 case 'LCP':
 // Largest Contentful Paint
 break;
 case 'CLS':
 // Cumulative Layout Shift
 break;
 case 'FID':
 // First Input Delay
 break;
 case 'TTFB':
 // Time to First Byte
 break;
 case 'INP':
 // Interaction to Next Paint
 break;
 }
 });

 return null;
}
```

---

## Caching Strategies

### Static Generation (Build Time)

```typescript
// Cached forever until rebuild
export default async function Page {
 const data = await fetch('https://api.example.com/data', {
 cache: 'force-cache', // Default
 });

 return <div>{data.title}</div>;
}
```

### Revalidation (ISR)

```typescript
// Revalidate every 60 seconds
export const revalidate = 60;

export default async function Page {
 const data = await fetch('https://api.example.com/data');
 return <div>{data.title}</div>;
}
```

### No Caching (SSR)

```typescript
// Fresh data on every request
export const dynamic = 'force-dynamic';

export default async function Page {
 const data = await fetch('https://api.example.com/data', {
 cache: 'no-store',
 });

 return <div>{data.title}</div>;
}
```

### Partial Caching

```typescript
export default async function Page {
 // Cached
 const staticData = await fetch('https://api.example.com/config', {
 cache: 'force-cache',
 });

 // Revalidated every 60s
 const semiStaticData = await fetch('https://api.example.com/news', {
 next: { revalidate: 60 },
 });

 // Never cached
 const dynamicData = await fetch('https://api.example.com/user', {
 cache: 'no-store',
 });

 return <div>{/*... */}</div>;
}
```

---

## Core Web Vitals

### What are Core Web Vitals?

- **LCP (Largest Contentful Paint)**: < 2.5s (good)
- **FID (First Input Delay)**: < 100ms (good)
- **CLS (Cumulative Layout Shift)**: < 0.1 (good)
- **INP (Interaction to Next Paint)**: < 200ms (good)
- **TTFB (Time to First Byte)**: < 600ms (good)

### Improving LCP

```typescript
// 1. Use next/image with priority
<Image src="/hero.jpg" alt="Hero" priority />

// 2. Preload critical resources
import { Metadata } from 'next';

export const metadata: Metadata = {
 other: {
 'preload': '/critical-font.woff2',
 },
};

// 3. Optimize server response time
export const dynamic = 'force-static'; // Pre-render when possible
```

### Improving FID/INP

```typescript
// 1. Reduce JavaScript bundle size
const Component = dynamic( => import('./Component'));

// 2. Use Server Components
// (no JS sent to client by default)

// 3. Defer non-critical JavaScript
<Script src="/analytics.js" strategy="lazyOnload" />
```

### Improving CLS

```typescript
// 1. Specify image dimensions
<Image src="/image.jpg" width={800} height={600} alt="Image" />

// 2. Reserve space for dynamic content
<div className="h-64">{/* Content loads here */}</div>

// 3. Use font-display: swap
const inter = Inter({ display: 'swap' });
```

---

## Best Practices

### ✅ DO

1. **Use next/image for all images**
```typescript
<Image src="/logo.png" width={200} height={100} alt="Logo" />
```

2. **Optimize fonts with next/font**
```typescript
import { Inter } from 'next/font/google';
const inter = Inter({ subsets: ['latin'] });
```

3. **Lazy load non-critical components**
```typescript
const Modal = dynamic( => import('./Modal'), { ssr: false });
```

4. **Use appropriate caching strategies**
```typescript
// Static
{ cache: 'force-cache' }

// Dynamic
{ cache: 'no-store' }

// ISR
{ next: { revalidate: 60 } }
```

5. **Monitor Core Web Vitals**
```typescript
import { SpeedInsights } from '@vercel/speed-insights/next';
```

### ❌ DON'T

1. **Don't use <img> tags**
```typescript
// ❌ Bad
<img src="/image.jpg" />

// ✅ Good
<Image src="/image.jpg" width={800} height={600} alt="Image" />
```

2. **Don't load all components upfront**
```typescript
// ❌ Bad
import HeavyComponent from './HeavyComponent';

// ✅ Good
const HeavyComponent = dynamic( => import('./HeavyComponent'));
```

3. **Don't ignore bundle size**
```bash
# ✅ Analyze regularly
ANALYZE=true npm run build
```

4. **Don't skip image dimensions**
```typescript
// ❌ Causes CLS
<Image src="/image.jpg" alt="Image" />

// ✅ Prevents CLS
<Image src="/image.jpg" width={800} height={600} alt="Image" />
```

---

## Summary

### Optimization Checklist
- ✅ Use next/image for all images
- ✅ Optimize fonts with next/font
- ✅ Lazy load heavy components
- ✅ Use appropriate caching strategies
- ✅ Monitor Core Web Vitals
- ✅ Analyze bundle size regularly
- ✅ Use Metadata API for SEO

### Performance Targets (this project)
- Page load: < 2s (p90)
- API response: < 200ms (p95)
- Lighthouse score: > 90
- Core Web Vitals: All "Good"

---

**Next**: [08-DEPLOYMENT.md](./08-DEPLOYMENT.md) - Learn about deployment strategies

**Last Updated**: November 9, 2025
**Status**: Production-Ready ✅
