---
id: nextjs-06-styling
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

# Next.js Styling: CSS, Tailwind, and CSS-in-JS

**Part 6 of 11 - The Next.js Knowledge Base**

## Table of Contents
1. [Styling Options Overview](#styling-options-overview)
2. [CSS Modules](#css-modules)
3. [Tailwind CSS](#tailwind-css)
4. [Global Styles](#global-styles)
5. [CSS-in-JS](#css-in-js)
6. [Sass/SCSS](#sassscss)
7. [PostCSS](#postcss)
8. [Class Variance Authority (cva)](#class-variance-authority-cva)
9. [shadcn/ui Patterns](#shadcnui-patterns)
10. [Best Practices](#best-practices)

---

## Styling Options Overview

Next.js supports multiple styling approaches:

| Method | Scope | Performance | DX | Use Case |
|--------|-------|-------------|-----|----------|
| CSS Modules | Component | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | Scoped styles |
| Tailwind CSS | Utility | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | **this project uses this** |
| Global CSS | Global | ⭐⭐⭐⭐ | ⭐⭐⭐ | Base styles |
| CSS-in-JS | Component | ⭐⭐⭐ | ⭐⭐⭐⭐ | Dynamic styles |
| Sass/SCSS | Component/Global | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | Advanced CSS |

---

## CSS Modules

### What are CSS Modules?

CSS Modules automatically scope CSS to components, preventing style conflicts.

### Basic CSS Module

```typescript
// components/Button/Button.module.css
.button {
 padding: 12px 24px;
 background-color: #7c3aed;
 color: white;
 border: none;
 border-radius: 6px;
 font-weight: 600;
 cursor: pointer;
}

.button:hover {
 background-color: #6d28d9;
}

.primary {
 background-color: #7c3aed;
}

.secondary {
 background-color: #10b981;
}

.large {
 padding: 16px 32px;
 font-size: 18px;
}

// components/Button/Button.tsx
import styles from './Button.module.css';

interface ButtonProps {
 variant?: 'primary' | 'secondary';
 size?: 'large';
 children: React.ReactNode;
}

export default function Button({ variant, size, children }: ButtonProps) {
 const className = [
 styles.button,
 variant && styles[variant],
 size && styles[size],
 ]
.filter(Boolean)
.join(' ');

 return <button className={className}>{children}</button>;
}
```

### Composing Classes

```css
/* components/Card.module.css */
.base {
 padding: 20px;
 border-radius: 8px;
}

.card {
 composes: base;
 background-color: white;
 box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}

.highlighted {
 composes: card;
 border: 2px solid #7c3aed;
}
```

### Global Class Names

```css
/* Access global classes from CSS Module */
:global(.dark-mode).button {
 background-color: #1f2937;
}

/* Or use:global selector */
.container:global(.external-class) {
 color: red;
}
```

---

## Tailwind CSS

### Setup (this project Configuration)

```typescript
// tailwind.config.ts
import type { Config } from 'tailwindcss';

const config: Config = {
 content: [
 './pages/**/*.{js,ts,jsx,tsx,mdx}',
 './components/**/*.{js,ts,jsx,tsx,mdx}',
 './app/**/*.{js,ts,jsx,tsx,mdx}',
 ],
 theme: {
 extend: {
 colors: {
 // this project color palette
 'this project-primary': '#7C3AED',
 'this project-secondary': '#10B981',
 'this project-accent': '#F59E0B',
 'confidence-high': '#10B981',
 'confidence-medium': '#F59E0B',
 'confidence-low': '#EF4444',
 },
 fontFamily: {
 sans: ['Inter', 'sans-serif'],
 mono: ['JetBrains Mono', 'monospace'],
 },
 },
 },
 plugins: [require('@tailwindcss/forms')],
};

export default config;
```

### Basic Tailwind Usage

```typescript
// components/Card.tsx
export default function Card({ title, content }: {
 title: string;
 content: string;
}) {
 return (
 <div className="bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition-shadow">
 <h2 className="text-2xl font-bold text-gray-900 mb-4">
 {title}
 </h2>
 <p className="text-gray-600 leading-relaxed">
 {content}
 </p>
 </div>
 );
}
```

### Responsive Design

```typescript
export default function ResponsiveLayout {
 return (
 <div className="
 grid
 grid-cols-1
 sm:grid-cols-2
 md:grid-cols-3
 lg:grid-cols-4
 gap-4
 p-4
 sm:p-6
 md:p-8
 ">
 {/* Content */}
 </div>
 );
}
```

### Conditional Classes

```typescript
import { clsx } from 'clsx';

interface ButtonProps {
 variant: 'primary' | 'secondary';
 size: 'sm' | 'md' | 'lg';
 disabled?: boolean;
 children: React.ReactNode;
}

export default function Button({
 variant,
 size,
 disabled,
 children,
}: ButtonProps) {
 return (
 <button
 className={clsx(
 // Base styles
 'font-semibold rounded transition-colors',

 // Variant styles
 variant === 'primary' && 'bg-this project-primary text-white hover:bg-purple-700',
 variant === 'secondary' && 'bg-this project-secondary text-white hover:bg-green-700',

 // Size styles
 size === 'sm' && 'px-3 py-1.5 text-sm',
 size === 'md' && 'px-4 py-2 text-base',
 size === 'lg' && 'px-6 py-3 text-lg',

 // State styles
 disabled && 'opacity-50 cursor-not-allowed',
 )}
 disabled={disabled}
 >
 {children}
 </button>
 );
}
```

### Dark Mode

```typescript
// tailwind.config.ts
module.exports = {
 darkMode: 'class', // or 'media'
 //...
};

// Component with dark mode
export default function Card {
 return (
 <div className="
 bg-white dark:bg-gray-800
 text-gray-900 dark:text-white
 border border-gray-200 dark:border-gray-700
 rounded-lg p-6
 ">
 <h2 className="text-xl font-bold">Card Title</h2>
 <p className="text-gray-600 dark:text-gray-300">
 Content
 </p>
 </div>
 );
}

// Toggle dark mode
'use client';

import { useEffect, useState } from 'react';

export default function DarkModeToggle {
 const [darkMode, setDarkMode] = useState(false);

 useEffect( => {
 if (darkMode) {
 document.documentElement.classList.add('dark');
 } else {
 document.documentElement.classList.remove('dark');
 }
 }, [darkMode]);

 return (
 <button onClick={ => setDarkMode(!darkMode)}>
 {darkMode ? '🌞': '🌙'}
 </button>
 );
}
```

### Custom Utilities

```css
/* app/globals.css */
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer utilities {
.text-balance {
 text-wrap: balance;
 }

.scrollbar-hide {
 -ms-overflow-style: none;
 scrollbar-width: none;
 }

.scrollbar-hide::-webkit-scrollbar {
 display: none;
 }
}

@layer components {
.btn-primary {
 @apply px-4 py-2 bg-this project-primary text-white rounded-lg font-semibold;
 @apply hover:bg-purple-700 transition-colors;
 }

.card {
 @apply bg-white rounded-lg shadow-md p-6;
 }
}
```

---

## Global Styles

### Global CSS File

```css
/* app/globals.css */
@tailwind base;
@tailwind components;
@tailwind utilities;

/* Custom global styles */
* {
 box-sizing: border-box;
 padding: 0;
 margin: 0;
}

html,
body {
 max-width: 100vw;
 overflow-x: hidden;
}

body {
 font-family: 'Inter', sans-serif;
 -webkit-font-smoothing: antialiased;
 -moz-osx-font-smoothing: grayscale;
}

a {
 color: inherit;
 text-decoration: none;
}

/* Custom scrollbar */
::-webkit-scrollbar {
 width: 8px;
}

::-webkit-scrollbar-track {
 background: #f1f1f1;
}

::-webkit-scrollbar-thumb {
 background: #888;
 border-radius: 4px;
}

::-webkit-scrollbar-thumb:hover {
 background: #555;
}
```

### Importing Global Styles

```typescript
// app/layout.tsx
import './globals.css';

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

---

## CSS-in-JS

### Styled Components

```typescript
// Install: npm install styled-components

// components/Button.tsx
'use client';

import styled from 'styled-components';

const StyledButton = styled.button<{ $primary?: boolean }>`
 padding: 12px 24px;
 background-color: ${props => props.$primary ? '#7c3aed': '#10b981'};
 color: white;
 border: none;
 border-radius: 6px;
 font-weight: 600;
 cursor: pointer;
 transition: background-color 0.2s;

 &:hover {
 background-color: ${props => props.$primary ? '#6d28d9': '#059669'};
 }

 &:disabled {
 opacity: 0.5;
 cursor: not-allowed;
 }
`;

export default function Button({ primary, children }: {
 primary?: boolean;
 children: React.ReactNode;
}) {
 return <StyledButton $primary={primary}>{children}</StyledButton>;
}

// app/registry.tsx (Required for styled-components in App Router)
'use client';

import React, { useState } from 'react';
import { useServerInsertedHTML } from 'next/navigation';
import { ServerStyleSheet, StyleSheetManager } from 'styled-components';

export default function StyledComponentsRegistry({
 children,
}: {
 children: React.ReactNode;
}) {
 const [styledComponentsStyleSheet] = useState( => new ServerStyleSheet);

 useServerInsertedHTML( => {
 const styles = styledComponentsStyleSheet.getStyleElement;
 styledComponentsStyleSheet.instance.clearTag;
 return <>{styles}</>;
 });

 if (typeof window !== 'undefined') return <>{children}</>;

 return (
 <StyleSheetManager sheet={styledComponentsStyleSheet.instance}>
 {children}
 </StyleSheetManager>
 );
}
```

### Emotion

```typescript
// Install: npm install @emotion/react @emotion/styled

/** @jsxImportSource @emotion/react */
'use client';

import { css } from '@emotion/react';

const buttonStyles = css`
 padding: 12px 24px;
 background-color: #7c3aed;
 color: white;
 border: none;
 border-radius: 6px;
 font-weight: 600;
 cursor: pointer;

 &:hover {
 background-color: #6d28d9;
 }
`;

export default function Button({ children }: { children: React.ReactNode }) {
 return <button css={buttonStyles}>{children}</button>;
}
```

---

## Sass/SCSS

### Setup

```bash
npm install sass
```

### SCSS Module

```scss
// components/Card/Card.module.scss
$primary-color: #7c3aed;
$secondary-color: #10b981;
$border-radius: 8px;
$spacing-md: 16px;

.card {
 padding: $spacing-md;
 border-radius: $border-radius;
 background-color: white;
 box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);

 &:hover {
 box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
 }

.title {
 font-size: 1.5rem;
 font-weight: 700;
 color: $primary-color;
 margin-bottom: $spacing-md;
 }

.content {
 color: #4b5563;
 line-height: 1.6;
 }

 &.highlighted {
 border: 2px solid $primary-color;
 }
}
```

```typescript
// components/Card/Card.tsx
import styles from './Card.module.scss';

export default function Card({
 title,
 content,
 highlighted,
}: {
 title: string;
 content: string;
 highlighted?: boolean;
}) {
 return (
 <div className={`${styles.card} ${highlighted ? styles.highlighted: ''}`}>
 <h2 className={styles.title}>{title}</h2>
 <p className={styles.content}>{content}</p>
 </div>
 );
}
```

### Global SCSS

```scss
// app/globals.scss
@import './variables';
@import './mixins';

* {
 box-sizing: border-box;
}

body {
 font-family: $font-family-base;
 color: $text-color;
 background-color: $bg-color;
}

// _variables.scss
$primary-color: #7c3aed;
$secondary-color: #10b981;
$font-family-base: 'Inter', sans-serif;
$text-color: #1f2937;
$bg-color: #ffffff;

// _mixins.scss
@mixin flex-center {
 display: flex;
 align-items: center;
 justify-content: center;
}

@mixin responsive($breakpoint) {
 @if $breakpoint == mobile {
 @media (max-width: 640px) { @content; }
 }
 @if $breakpoint == tablet {
 @media (max-width: 1024px) { @content; }
 }
}
```

---

## PostCSS

### Configuration

```javascript
// postcss.config.js
module.exports = {
 plugins: {
 'postcss-import': {},
 'tailwindcss/nesting': {},
 tailwindcss: {},
 autoprefixer: {},
 },
};
```

### Custom PostCSS Plugins

```javascript
// postcss.config.js
module.exports = {
 plugins: {
 'postcss-import': {},
 'postcss-custom-properties': {},
 'postcss-nested': {},
 autoprefixer: {},
 cssnano: process.env.NODE_ENV === 'production' ? {}: false,
 },
};
```

---

## Class Variance Authority (cva)

### What is cva?

cva provides type-safe variant styling (used by shadcn/ui).

```typescript
// components/Button.tsx
import { cva, type VariantProps } from 'class-variance-authority';

const buttonVariants = cva(
 // Base styles
 'inline-flex items-center justify-center rounded-md font-medium transition-colors focus-visible:outline-none disabled:opacity-50 disabled:pointer-events-none',
 {
 variants: {
 variant: {
 default: 'bg-this project-primary text-white hover:bg-purple-700',
 secondary: 'bg-this project-secondary text-white hover:bg-green-700',
 outline: 'border border-gray-300 bg-white hover:bg-gray-50',
 ghost: 'hover:bg-gray-100',
 },
 size: {
 sm: 'h-8 px-3 text-sm',
 md: 'h-10 px-4 text-base',
 lg: 'h-12 px-6 text-lg',
 },
 },
 defaultVariants: {
 variant: 'default',
 size: 'md',
 },
 }
);

interface ButtonProps
 extends React.ButtonHTMLAttributes<HTMLButtonElement>,
 VariantProps<typeof buttonVariants> {
 children: React.ReactNode;
}

export default function Button({
 variant,
 size,
 className,
 children,
...props
}: ButtonProps) {
 return (
 <button
 className={buttonVariants({ variant, size, className })}
 {...props}
 >
 {children}
 </button>
 );
}

// Usage
<Button variant="default" size="md">Click me</Button>
<Button variant="outline" size="lg">Outlined</Button>
```

---

## shadcn/ui Patterns

### shadcn/ui Component Structure (this project uses this)

```typescript
// components/ui/button.tsx
import * as React from 'react';
import { Slot } from '@radix-ui/react-slot';
import { cva, type VariantProps } from 'class-variance-authority';
import { cn } from '@/lib/utils';

const buttonVariants = cva(
 'inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50',
 {
 variants: {
 variant: {
 default: 'bg-primary text-primary-foreground hover:bg-primary/90',
 destructive: 'bg-destructive text-destructive-foreground hover:bg-destructive/90',
 outline: 'border border-input bg-background hover:bg-accent hover:text-accent-foreground',
 secondary: 'bg-secondary text-secondary-foreground hover:bg-secondary/80',
 ghost: 'hover:bg-accent hover:text-accent-foreground',
 link: 'text-primary underline-offset-4 hover:underline',
 },
 size: {
 default: 'h-10 px-4 py-2',
 sm: 'h-9 rounded-md px-3',
 lg: 'h-11 rounded-md px-8',
 icon: 'h-10 w-10',
 },
 },
 defaultVariants: {
 variant: 'default',
 size: 'default',
 },
 }
);

export interface ButtonProps
 extends React.ButtonHTMLAttributes<HTMLButtonElement>,
 VariantProps<typeof buttonVariants> {
 asChild?: boolean;
}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
 ({ className, variant, size, asChild = false,...props }, ref) => {
 const Comp = asChild ? Slot: 'button';
 return (
 <Comp
 className={cn(buttonVariants({ variant, size, className }))}
 ref={ref}
 {...props}
 />
 );
 }
);
Button.displayName = 'Button';

export { Button, buttonVariants };
```

### Utility Function (cn)

```typescript
// lib/utils.ts
import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]) {
 return twMerge(clsx(inputs));
}

// Usage
<div className={cn(
 'base-class',
 isActive && 'active-class',
 className // User-provided className
)} />
```

---

## Best Practices

### ✅ DO

1. **Use Tailwind for this project (consistent with project)**
```typescript
<div className="bg-white rounded-lg shadow-md p-6">
 <h1 className="text-2xl font-bold text-gray-900">Title</h1>
</div>
```

2. **Use cn utility for conditional classes**
```typescript
import { cn } from '@/lib/utils';

<div className={cn(
 'base-class',
 isActive && 'active-class',
 className
)} />
```

3. **Extract repeated patterns with cva**
```typescript
const cardVariants = cva('rounded-lg p-4', {
 variants: {
 variant: {
 default: 'bg-white',
 highlighted: 'bg-purple-50 border-2 border-purple-500',
 },
 },
});
```

4. **Use CSS variables for theming**
```css
:root {
 --color-primary: #7c3aed;
 --color-secondary: #10b981;
 --spacing-md: 1rem;
}

.button {
 background-color: var(--color-primary);
 padding: var(--spacing-md);
}
```

### ❌ DON'T

1. **Don't mix styling approaches**
```typescript
// ❌ Bad: Mixing Tailwind and CSS Modules
<div className="flex" style={{ display: 'grid' }}>
```

2. **Don't use inline styles for static values**
```typescript
// ❌ Bad
<div style={{ padding: '16px', backgroundColor: 'white' }}>

// ✅ Good
<div className="p-4 bg-white">
```

3. **Don't create overly specific Tailwind classes**
```typescript
// ❌ Bad: Too specific, hard to maintain
<div className="mt-[13px] ml-[27px] text-[#7c3aed]">

// ✅ Good: Use design system values
<div className="mt-4 ml-6 text-this project-primary">
```

---

## Summary

### Styling Methods
- **Tailwind CSS**: Utility-first (the project's choice)
- **CSS Modules**: Scoped component styles
- **Global CSS**: App-wide base styles
- **cva**: Type-safe variants
- **shadcn/ui**: Component library pattern

### this project Stack
- Tailwind CSS 3.4
- shadcn/ui components
- Class Variance Authority (cva)
- Custom design tokens
- Responsive utilities

---

**Next**: [07-OPTIMIZATION.md](./07-OPTIMIZATION.md) - Learn about performance optimization

**Last Updated**: November 9, 2025
**Status**: Production-Ready ✅
