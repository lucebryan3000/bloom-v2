---
id: tailwind-integrations
topic: tailwind
file_role: guide
profile: full
difficulty_level: advanced
kb_version: 3.1
prerequisites: [tailwind-fundamentals, tailwind-customization]
related_topics: [nextjs, react, vue, svelte, vite, postcss, build-tools]
embedding_keywords: [tailwind, integration, nextjs, react, vue, svelte, vite, webpack, postcss]
last_reviewed: 2025-11-16
---

# Tailwind CSS - Framework Integrations

Integrating Tailwind CSS with popular frontend frameworks and build tools.

## Overview

Tailwind CSS works seamlessly with modern frontend frameworks. This guide covers installation, configuration, and framework-specific patterns.

---

## Next.js Integration

### Installation (Next.js 13+)

```bash
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p
```

### Configuration

```javascript
// tailwind.config.js
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './app/**/*.{js,ts,jsx,tsx,mdx}',
    './pages/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
```

```css
/* app/globals.css or styles/globals.css */
@tailwind base;
@tailwind components;
@tailwind utilities;
```

```typescript
// app/layout.tsx (App Router)
import './globals.css'

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  )
}
```

### Next.js App Router Patterns

```tsx
// app/page.tsx
export default function Home() {
  return (
    <main className="min-h-screen bg-gradient-to-b from-blue-50 to-white">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-16">
        <h1 className="text-4xl font-bold text-gray-900 mb-4">
          Welcome to Next.js + Tailwind
        </h1>
        <p className="text-lg text-gray-600">
          Building modern web applications with ease.
        </p>
      </div>
    </main>
  )
}
```

### Server Components with Tailwind

```tsx
// app/components/Card.tsx (Server Component)
export function Card({ title, description }: { title: string; description: string }) {
  return (
    <div className="bg-white rounded-lg shadow-md p-6 hover:shadow-xl transition-shadow">
      <h3 className="text-xl font-semibold text-gray-900 mb-2">
        {title}
      </h3>
      <p className="text-gray-600">
        {description}
      </p>
    </div>
  )
}
```

### Client Components with Tailwind

```tsx
// app/components/Button.tsx (Client Component)
'use client'

import { useState } from 'react'

export function Button() {
  const [count, setCount] = useState(0)

  return (
    <button
      onClick={() => setCount(count + 1)}
      className="bg-blue-600 hover:bg-blue-700 text-white font-semibold px-6 py-3 rounded-lg transition-colors"
    >
      Clicked {count} times
    </button>
  )
}
```

---

## React Integration

### Create React App

```bash
# Create new app
npx create-react-app my-app
cd my-app

# Install Tailwind
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p
```

```javascript
// tailwind.config.js
module.exports = {
  content: [
    "./src/**/*.{js,jsx,ts,tsx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
```

```css
/* src/index.css */
@tailwind base;
@tailwind components;
@tailwind utilities;
```

```javascript
// src/index.js
import './index.css'
import App from './App'
// ... rest of imports
```

### React Component Patterns

```tsx
// src/components/Card.tsx
interface CardProps {
  title: string
  description: string
  imageUrl: string
}

export function Card({ title, description, imageUrl }: CardProps) {
  return (
    <div className="bg-white rounded-lg overflow-hidden shadow-lg hover:shadow-2xl transition-shadow">
      <img
        src={imageUrl}
        alt={title}
        className="w-full h-48 object-cover"
      />
      <div className="p-6">
        <h3 className="text-xl font-bold text-gray-900 mb-2">
          {title}
        </h3>
        <p className="text-gray-600">
          {description}
        </p>
      </div>
    </div>
  )
}
```

### Conditional Classes

```tsx
// Using template literals
function Button({ variant, children }: { variant: 'primary' | 'secondary'; children: React.ReactNode }) {
  const baseClasses = "px-6 py-3 rounded-lg font-semibold transition-colors"
  const variantClasses = {
    primary: "bg-blue-600 text-white hover:bg-blue-700",
    secondary: "bg-gray-200 text-gray-900 hover:bg-gray-300"
  }

  return (
    <button className={`${baseClasses} ${variantClasses[variant]}`}>
      {children}
    </button>
  )
}

// Using clsx/classnames library
import clsx from 'clsx'

function Button({ variant, disabled, children }) {
  return (
    <button
      className={clsx(
        "px-6 py-3 rounded-lg font-semibold transition-colors",
        {
          "bg-blue-600 text-white hover:bg-blue-700": variant === 'primary',
          "bg-gray-200 text-gray-900 hover:bg-gray-300": variant === 'secondary',
          "opacity-50 cursor-not-allowed": disabled,
        }
      )}
      disabled={disabled}
    >
      {children}
    </button>
  )
}
```

---

## Vite Integration

### Installation

```bash
# Create Vite project
npm create vite@latest my-app -- --template react-ts
cd my-app

# Install Tailwind
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p
```

### Configuration

```javascript
// tailwind.config.js
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
```

```css
/* src/index.css */
@tailwind base;
@tailwind components;
@tailwind utilities;
```

```typescript
// src/main.tsx
import './index.css'
import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App'

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)
```

### Vite-Specific Optimizations

```javascript
// vite.config.ts
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  css: {
    postcss: './postcss.config.js',
  },
  build: {
    cssCodeSplit: true,
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom'],
        },
      },
    },
  },
})
```

---

## Vue Integration

### Vue 3 + Vite

```bash
# Create Vue project
npm create vite@latest my-app -- --template vue-ts
cd my-app

# Install Tailwind
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p
```

```javascript
// tailwind.config.js
export default {
  content: [
    "./index.html",
    "./src/**/*.{vue,js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
```

```css
/* src/style.css */
@tailwind base;
@tailwind components;
@tailwind utilities;
```

```typescript
// src/main.ts
import './style.css'
import { createApp } from 'vue'
import App from './App.vue'

createApp(App).mount('#app')
```

### Vue Component Patterns

```vue
<!-- src/components/Card.vue -->
<script setup lang="ts">
interface Props {
  title: string
  description: string
  imageUrl: string
}

defineProps<Props>()
</script>

<template>
  <div class="bg-white rounded-lg overflow-hidden shadow-lg hover:shadow-2xl transition-shadow">
    <img
      :src="imageUrl"
      :alt="title"
      class="w-full h-48 object-cover"
    />
    <div class="p-6">
      <h3 class="text-xl font-bold text-gray-900 mb-2">
        {{ title }}
      </h3>
      <p class="text-gray-600">
        {{ description }}
      </p>
    </div>
  </div>
</template>
```

### Dynamic Classes in Vue

```vue
<script setup lang="ts">
import { computed } from 'vue'

interface Props {
  variant?: 'primary' | 'secondary'
  disabled?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  variant: 'primary',
  disabled: false,
})

const buttonClasses = computed(() => ({
  'px-6 py-3 rounded-lg font-semibold transition-colors': true,
  'bg-blue-600 text-white hover:bg-blue-700': props.variant === 'primary',
  'bg-gray-200 text-gray-900 hover:bg-gray-300': props.variant === 'secondary',
  'opacity-50 cursor-not-allowed': props.disabled,
}))
</script>

<template>
  <button :class="buttonClasses" :disabled="disabled">
    <slot />
  </button>
</template>
```

---

## Svelte Integration

### Installation

```bash
# Create Svelte project
npm create vite@latest my-app -- --template svelte-ts
cd my-app

# Install Tailwind
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p
```

```javascript
// tailwind.config.js
export default {
  content: [
    "./index.html",
    "./src/**/*.{svelte,js,ts}",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
```

```css
/* src/app.css */
@tailwind base;
@tailwind components;
@tailwind utilities;
```

```typescript
// src/main.ts
import './app.css'
import App from './App.svelte'

const app = new App({
  target: document.getElementById('app')!,
})

export default app
```

### Svelte Component Patterns

```svelte
<!-- src/lib/Card.svelte -->
<script lang="ts">
  export let title: string
  export let description: string
  export let imageUrl: string
</script>

<div class="bg-white rounded-lg overflow-hidden shadow-lg hover:shadow-2xl transition-shadow">
  <img
    src={imageUrl}
    alt={title}
    class="w-full h-48 object-cover"
  />
  <div class="p-6">
    <h3 class="text-xl font-bold text-gray-900 mb-2">
      {title}
    </h3>
    <p class="text-gray-600">
      {description}
    </p>
  </div>
</div>
```

### Dynamic Classes in Svelte

```svelte
<script lang="ts">
  export let variant: 'primary' | 'secondary' = 'primary'
  export let disabled = false

  $: classes = [
    'px-6 py-3 rounded-lg font-semibold transition-colors',
    variant === 'primary' ? 'bg-blue-600 text-white hover:bg-blue-700' : '',
    variant === 'secondary' ? 'bg-gray-200 text-gray-900 hover:bg-gray-300' : '',
    disabled ? 'opacity-50 cursor-not-allowed' : '',
  ].filter(Boolean).join(' ')
</script>

<button class={classes} {disabled}>
  <slot />
</button>
```

---

## Angular Integration

### Installation

```bash
# Create Angular project
ng new my-app
cd my-app

# Install Tailwind
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init
```

```javascript
// tailwind.config.js
module.exports = {
  content: [
    "./src/**/*.{html,ts}",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
```

```css
/* src/styles.css */
@tailwind base;
@tailwind components;
@tailwind utilities;
```

### Angular Component

```typescript
// src/app/components/card/card.component.ts
import { Component, Input } from '@angular/core'

@Component({
  selector: 'app-card',
  template: `
    <div class="bg-white rounded-lg overflow-hidden shadow-lg hover:shadow-2xl transition-shadow">
      <img
        [src]="imageUrl"
        [alt]="title"
        class="w-full h-48 object-cover"
      />
      <div class="p-6">
        <h3 class="text-xl font-bold text-gray-900 mb-2">
          {{ title }}
        </h3>
        <p class="text-gray-600">
          {{ description }}
        </p>
      </div>
    </div>
  `,
})
export class CardComponent {
  @Input() title!: string
  @Input() description!: string
  @Input() imageUrl!: string
}
```

---

## PostCSS Configuration

### Basic Setup

```javascript
// postcss.config.js
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
```

### Advanced PostCSS

```javascript
// postcss.config.js
module.exports = {
  plugins: {
    'postcss-import': {},
    'tailwindcss/nesting': 'postcss-nesting',
    tailwindcss: {},
    autoprefixer: {},
    ...(process.env.NODE_ENV === 'production' ? { cssnano: {} } : {}),
  },
}
```

---

## Build Optimization

### Production Configuration

```javascript
// tailwind.config.js
module.exports = {
  content: [
    './src/**/*.{js,jsx,ts,tsx}',
  ],
  theme: {
    extend: {},
  },
  plugins: [],
  // Disable unused features for smaller builds
  corePlugins: {
    // Disable unused utilities
    float: false,
    objectFit: false,
    objectPosition: false,
  },
}
```

### PurgeCSS Configuration

```javascript
// tailwind.config.js
module.exports = {
  content: [
    './src/**/*.{js,jsx,ts,tsx}',
  ],
  safelist: [
    // Always include these classes
    'bg-red-500',
    'bg-green-500',
    {
      pattern: /bg-(red|green|blue)-(100|500|900)/,
    },
  ],
}
```

### Content Configuration

```javascript
// tailwind.config.js
module.exports = {
  content: [
    // Scan all component files
    './src/components/**/*.{js,jsx,ts,tsx}',
    './src/pages/**/*.{js,jsx,ts,tsx}',

    // Include specific files
    './src/App.tsx',

    // Scan files from node_modules (if using UI library)
    './node_modules/@mycompany/ui-lib/**/*.js',

    // Use functions for dynamic content
    {
      raw: '<div class="text-center"></div>',
      extension: 'html',
    },
  ],
}
```

---

## Server-Side Rendering (SSR)

### Next.js SSR

```tsx
// app/page.tsx (Next.js 13+ App Router)
export default function Page() {
  return (
    <div className="min-h-screen bg-gray-100">
      {/* Tailwind classes work in SSR */}
      <h1 className="text-4xl font-bold">Server-Rendered Page</h1>
    </div>
  )
}
```

### Preventing Flash of Unstyled Content (FOUC)

```tsx
// app/layout.tsx
import './globals.css'

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en" suppressHydrationWarning>
      <head>
        {/* Critical CSS is inlined by Next.js */}
      </head>
      <body>{children}</body>
    </html>
  )
}
```

---

## JIT Mode (Just-In-Time)

JIT mode is enabled by default in Tailwind CSS v3+. It generates styles on-demand as you author your templates.

### Benefits

- ⚡ Lightning fast build times
- 🎨 Every variant is enabled by default
- 🔧 Generate arbitrary values on the fly
- 📦 Smaller CSS bundles in development
- 🚀 Same fast experience in dev and prod

### Arbitrary Values

```html
<!-- Generate custom values on the fly -->
<div class="w-[137px]">Custom width</div>
<div class="bg-[#bada55]">Custom color</div>
<div class="grid-cols-[1fr_500px_2fr]">Custom grid</div>
<div class="text-[22px]">Custom font size</div>
<div class="top-[117px]">Custom positioning</div>
```

---

## AI Pair Programming Notes

**When to load this KB:**
- Setting up Tailwind in a new project
- Integrating Tailwind with specific frameworks
- Configuring build tools and PostCSS
- Optimizing production builds

**Common starting points:**
- Next.js setup: See Next.js Integration
- React setup: See React Integration
- Vue setup: See Vue Integration
- Build config: See Build Optimization

**Typical questions:**
- "How do I install Tailwind in Next.js?" → Next.js Integration
- "How do I use Tailwind with Vite?" → Vite Integration
- "How do I optimize for production?" → Build Optimization
- "How do I configure PostCSS?" → PostCSS Configuration

**Related topics:**
- Configuration: See `04-CUSTOMIZATION.md`
- Production: See `11-CONFIG-OPERATIONS.md`
- Utilities: See `02-UTILITY-CLASSES.md`

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1
