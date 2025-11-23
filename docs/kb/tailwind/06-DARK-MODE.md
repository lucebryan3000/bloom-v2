---
id: tailwind-dark-mode
topic: tailwind
file_role: guide
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [tailwind-fundamentals, tailwind-utility-classes, tailwind-customization]
related_topics: [dark-mode, theming, css-variables, accessibility]
embedding_keywords: [tailwind, dark mode, theme, dark variant, class strategy, media query, toggle]
last_reviewed: 2025-11-16
---

# Tailwind CSS - Dark Mode

Implementing dark mode in Tailwind CSS using the `dark:` variant and various strategies.

## Overview

Tailwind CSS provides first-class support for dark mode through the `dark:` variant. You can implement dark mode using class-based strategy (manual toggle) or media query strategy (system preference).

---

## Configuration

### Class Strategy (Recommended)

```javascript
// tailwind.config.js
module.exports = {
  darkMode: 'class', // Enable class-based dark mode
  // ... rest of config
}
```

**How it works:**
- Add `dark` class to `<html>` or `<body>` element
- All `dark:` variants activate when ancestor has `dark` class
- Enables manual toggling with JavaScript

### Media Query Strategy

```javascript
// tailwind.config.js
module.exports = {
  darkMode: 'media', // Use system preference
  // ... rest of config
}
```

**How it works:**
- Responds to `prefers-color-scheme: dark` media query
- No JavaScript required
- Follows system/browser preference automatically

---

## Basic Dark Mode Styling

### Text Colors

```html
<!-- Light: gray-900, Dark: gray-100 -->
<p class="text-gray-900 dark:text-gray-100">
  This text adapts to dark mode
</p>

<!-- Light: blue-600, Dark: blue-400 -->
<a href="#" class="text-blue-600 dark:text-blue-400">
  Link text
</a>
```

### Background Colors

```html
<!-- Light: white, Dark: gray-900 -->
<div class="bg-white dark:bg-gray-900">
  <p class="text-gray-900 dark:text-white">Content</p>
</div>

<!-- Light: gray-100, Dark: gray-800 -->
<div class="bg-gray-100 dark:bg-gray-800">
  <p class="text-gray-900 dark:text-gray-100">Content</p>
</div>
```

### Borders

```html
<!-- Light: gray-200, Dark: gray-700 -->
<div class="border border-gray-200 dark:border-gray-700">
  Bordered content
</div>

<!-- Light: gray-300, Dark: gray-600 -->
<input class="border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100">
```

---

## Complete Component Examples

### Card Component

```html
<!-- Card with dark mode support -->
<div class="bg-white dark:bg-gray-800 rounded-lg shadow-lg dark:shadow-gray-900/50 border border-gray-200 dark:border-gray-700 p-6">
  <!-- Header -->
  <h3 class="text-2xl font-bold text-gray-900 dark:text-white mb-4">
    Card Title
  </h3>

  <!-- Content -->
  <p class="text-gray-600 dark:text-gray-300 mb-4">
    This is a card component that works in both light and dark modes.
  </p>

  <!-- Link -->
  <a href="#" class="text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300 font-semibold">
    Learn More →
  </a>
</div>
```

### Navigation Bar

```html
<!-- Responsive navbar with dark mode -->
<nav class="bg-white dark:bg-gray-900 border-b border-gray-200 dark:border-gray-800 shadow-sm">
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
    <div class="flex justify-between items-center h-16">
      <!-- Logo -->
      <div class="flex items-center">
        <span class="text-2xl font-bold text-gray-900 dark:text-white">
          Brand
        </span>
      </div>

      <!-- Navigation Links -->
      <div class="hidden md:flex space-x-8">
        <a href="#" class="text-gray-700 dark:text-gray-300 hover:text-blue-600 dark:hover:text-blue-400 font-medium transition">
          Home
        </a>
        <a href="#" class="text-gray-700 dark:text-gray-300 hover:text-blue-600 dark:hover:text-blue-400 font-medium transition">
          Products
        </a>
        <a href="#" class="text-gray-700 dark:text-gray-300 hover:text-blue-600 dark:hover:text-blue-400 font-medium transition">
          About
        </a>
      </div>

      <!-- Dark Mode Toggle Button -->
      <button id="theme-toggle" class="p-2 rounded-lg bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-700 transition">
        <!-- Sun Icon (visible in dark mode) -->
        <svg class="hidden dark:block w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z"></path>
        </svg>
        <!-- Moon Icon (visible in light mode) -->
        <svg class="block dark:hidden w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z"></path>
        </svg>
      </button>
    </div>
  </div>
</nav>
```

### Button Variants

```html
<!-- Primary Button -->
<button class="bg-blue-600 dark:bg-blue-500 text-white px-6 py-3 rounded-lg font-semibold hover:bg-blue-700 dark:hover:bg-blue-600 transition">
  Primary Action
</button>

<!-- Secondary Button -->
<button class="bg-gray-200 dark:bg-gray-700 text-gray-900 dark:text-gray-100 px-6 py-3 rounded-lg font-semibold hover:bg-gray-300 dark:hover:bg-gray-600 transition">
  Secondary Action
</button>

<!-- Outline Button -->
<button class="border-2 border-gray-300 dark:border-gray-600 text-gray-700 dark:text-gray-300 px-6 py-3 rounded-lg font-semibold hover:bg-gray-100 dark:hover:bg-gray-800 transition">
  Outline Button
</button>

<!-- Ghost Button -->
<button class="text-gray-700 dark:text-gray-300 px-6 py-3 rounded-lg font-semibold hover:bg-gray-100 dark:hover:bg-gray-800 transition">
  Ghost Button
</button>
```

### Form Input

```html
<!-- Text Input with Dark Mode -->
<div class="mb-4">
  <label class="block text-gray-700 dark:text-gray-300 font-semibold mb-2">
    Email Address
  </label>
  <input
    type="email"
    placeholder="you@example.com"
    class="w-full px-4 py-3 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 placeholder-gray-400 dark:placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500 dark:focus:ring-blue-400 focus:border-transparent transition"
  />
</div>

<!-- Select Dropdown -->
<div class="mb-4">
  <label class="block text-gray-700 dark:text-gray-300 font-semibold mb-2">
    Country
  </label>
  <select class="w-full px-4 py-3 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 focus:outline-none focus:ring-2 focus:ring-blue-500 dark:focus:ring-blue-400 transition">
    <option>United States</option>
    <option>Canada</option>
    <option>United Kingdom</option>
  </select>
</div>

<!-- Checkbox -->
<label class="flex items-center">
  <input type="checkbox" class="w-5 h-5 text-blue-600 dark:text-blue-400 border-gray-300 dark:border-gray-600 rounded focus:ring-2 focus:ring-blue-500 dark:focus:ring-blue-400">
  <span class="ml-2 text-gray-700 dark:text-gray-300">
    I agree to the terms and conditions
  </span>
</label>
```

---

## Manual Dark Mode Toggle

### React Implementation

```jsx
// components/ThemeToggle.jsx
'use client'
import { useEffect, useState } from 'react'

export function ThemeToggle() {
  const [theme, setTheme] = useState('light')

  useEffect(() => {
    // Check localStorage or system preference on mount
    const savedTheme = localStorage.getItem('theme')
    const systemTheme = window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light'
    const initialTheme = savedTheme || systemTheme

    setTheme(initialTheme)
    document.documentElement.classList.toggle('dark', initialTheme === 'dark')
  }, [])

  const toggleTheme = () => {
    const newTheme = theme === 'light' ? 'dark' : 'light'
    setTheme(newTheme)
    localStorage.setItem('theme', newTheme)
    document.documentElement.classList.toggle('dark', newTheme === 'dark')
  }

  return (
    <button
      onClick={toggleTheme}
      className="p-2 rounded-lg bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-700 transition"
      aria-label="Toggle theme"
    >
      {theme === 'light' ? (
        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z" />
        </svg>
      ) : (
        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z" />
        </svg>
      )}
    </button>
  )
}
```

### Vanilla JavaScript Implementation

```html
<!-- HTML -->
<button id="theme-toggle" class="p-2 rounded-lg bg-gray-100 dark:bg-gray-800">
  <svg id="sun-icon" class="hidden dark:block w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z"></path>
  </svg>
  <svg id="moon-icon" class="block dark:hidden w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z"></path>
  </svg>
</button>

<script>
  // Check for saved theme or system preference
  const getTheme = () => {
    const savedTheme = localStorage.getItem('theme')
    if (savedTheme) return savedTheme

    return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light'
  }

  // Apply theme on page load
  const theme = getTheme()
  if (theme === 'dark') {
    document.documentElement.classList.add('dark')
  }

  // Toggle theme
  document.getElementById('theme-toggle').addEventListener('click', () => {
    const isDark = document.documentElement.classList.toggle('dark')
    localStorage.setItem('theme', isDark ? 'dark' : 'light')
  })

  // Listen for system theme changes
  window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (e) => {
    if (!localStorage.getItem('theme')) {
      document.documentElement.classList.toggle('dark', e.matches)
    }
  })
</script>
```

### Next.js App Router Implementation

```tsx
// app/providers.tsx
'use client'
import { ThemeProvider } from 'next-themes'

export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <ThemeProvider attribute="class" defaultTheme="system" enableSystem>
      {children}
    </ThemeProvider>
  )
}

// app/layout.tsx
import { Providers } from './providers'

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body>
        <Providers>
          {children}
        </Providers>
      </body>
    </html>
  )
}

// components/ThemeToggle.tsx
'use client'
import { useTheme } from 'next-themes'
import { useEffect, useState } from 'react'

export function ThemeToggle() {
  const [mounted, setMounted] = useState(false)
  const { theme, setTheme } = useTheme()

  useEffect(() => setMounted(true), [])

  if (!mounted) return null

  return (
    <button
      onClick={() => setTheme(theme === 'light' ? 'dark' : 'light')}
      className="p-2 rounded-lg bg-gray-100 dark:bg-gray-800"
    >
      {theme === 'light' ? '🌙' : '☀️'}
    </button>
  )
}
```

---

## CSS Variables Approach

### Setup with CSS Variables

```css
/* globals.css */
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  :root {
    /* Light mode colors */
    --color-background: 0 0% 100%;
    --color-foreground: 222.2 84% 4.9%;
    --color-card: 0 0% 100%;
    --color-card-foreground: 222.2 84% 4.9%;
    --color-primary: 221.2 83.2% 53.3%;
    --color-primary-foreground: 210 40% 98%;
    --color-secondary: 210 40% 96.1%;
    --color-secondary-foreground: 222.2 47.4% 11.2%;
    --color-muted: 210 40% 96.1%;
    --color-muted-foreground: 215.4 16.3% 46.9%;
    --color-border: 214.3 31.8% 91.4%;
  }

  .dark {
    /* Dark mode colors */
    --color-background: 222.2 84% 4.9%;
    --color-foreground: 210 40% 98%;
    --color-card: 222.2 84% 4.9%;
    --color-card-foreground: 210 40% 98%;
    --color-primary: 217.2 91.2% 59.8%;
    --color-primary-foreground: 222.2 47.4% 11.2%;
    --color-secondary: 217.2 32.6% 17.5%;
    --color-secondary-foreground: 210 40% 98%;
    --color-muted: 217.2 32.6% 17.5%;
    --color-muted-foreground: 215 20.2% 65.1%;
    --color-border: 217.2 32.6% 17.5%;
  }
}
```

### Tailwind Config

```javascript
// tailwind.config.js
module.exports = {
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        background: 'hsl(var(--color-background))',
        foreground: 'hsl(var(--color-foreground))',
        card: {
          DEFAULT: 'hsl(var(--color-card))',
          foreground: 'hsl(var(--color-card-foreground))',
        },
        primary: {
          DEFAULT: 'hsl(var(--color-primary))',
          foreground: 'hsl(var(--color-primary-foreground))',
        },
        secondary: {
          DEFAULT: 'hsl(var(--color-secondary))',
          foreground: 'hsl(var(--color-secondary-foreground))',
        },
        muted: {
          DEFAULT: 'hsl(var(--color-muted))',
          foreground: 'hsl(var(--color-muted-foreground))',
        },
        border: 'hsl(var(--color-border))',
      },
    },
  },
}
```

### Usage with CSS Variables

```html
<!-- Automatic dark mode with semantic colors -->
<div class="bg-background text-foreground">
  <div class="bg-card text-card-foreground border border-border rounded-lg p-6">
    <h2 class="text-primary">Title</h2>
    <p class="text-muted-foreground">Description</p>
    <button class="bg-primary text-primary-foreground px-4 py-2 rounded">
      Action
    </button>
  </div>
</div>
```

---

## Image Handling

### Dark Mode Images

```html
<!-- Show different images for light/dark mode -->
<img
  src="/logo-light.png"
  alt="Logo"
  class="block dark:hidden"
/>
<img
  src="/logo-dark.png"
  alt="Logo"
  class="hidden dark:block"
/>
```

### Image Filters

```html
<!-- Adjust image brightness in dark mode -->
<img
  src="/photo.jpg"
  alt="Photo"
  class="dark:brightness-75 dark:contrast-125"
/>

<!-- Invert images in dark mode -->
<img
  src="/icon.png"
  alt="Icon"
  class="dark:invert"
/>
```

---

## Best Practices

### Color Contrast

```html
<!-- ✅ Good: Sufficient contrast in both modes -->
<div class="bg-white dark:bg-gray-900">
  <p class="text-gray-900 dark:text-gray-100">
    High contrast text
  </p>
</div>

<!-- ❌ Bad: Insufficient contrast in dark mode -->
<div class="bg-white dark:bg-gray-900">
  <p class="text-gray-500">
    Low contrast in dark mode
  </p>
</div>
```

### Focus States

```html
<!-- Always provide visible focus states in both modes -->
<button class="bg-blue-600 dark:bg-blue-500 text-white px-4 py-2 rounded focus:outline-none focus:ring-2 focus:ring-blue-500 dark:focus:ring-blue-400 focus:ring-offset-2 focus:ring-offset-white dark:focus:ring-offset-gray-900">
  Button
</button>
```

### Hover States

```html
<!-- Ensure hover states work in both modes -->
<a href="#" class="text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300 hover:underline">
  Link
</a>
```

### Gradients

```html
<!-- Light and dark mode gradients -->
<div class="bg-gradient-to-r from-blue-500 to-purple-600 dark:from-blue-600 dark:to-purple-700 text-white p-8 rounded-lg">
  Gradient background
</div>
```

---

## Common Patterns

### Alert Components

```html
<!-- Success Alert -->
<div class="bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 text-green-800 dark:text-green-200 rounded-lg p-4">
  <div class="flex items-start">
    <svg class="w-5 h-5 text-green-600 dark:text-green-400 mr-3 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
      <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"></path>
    </svg>
    <div>
      <h4 class="font-semibold mb-1">Success!</h4>
      <p class="text-sm">Your changes have been saved.</p>
    </div>
  </div>
</div>

<!-- Error Alert -->
<div class="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 text-red-800 dark:text-red-200 rounded-lg p-4">
  <div class="flex items-start">
    <svg class="w-5 h-5 text-red-600 dark:text-red-400 mr-3 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
      <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"></path>
    </svg>
    <div>
      <h4 class="font-semibold mb-1">Error</h4>
      <p class="text-sm">Something went wrong. Please try again.</p>
    </div>
  </div>
</div>
```

### Badge Components

```html
<!-- Status Badges -->
<span class="inline-flex items-center px-3 py-1 rounded-full text-sm font-semibold bg-green-100 dark:bg-green-900/30 text-green-800 dark:text-green-300">
  Active
</span>

<span class="inline-flex items-center px-3 py-1 rounded-full text-sm font-semibold bg-yellow-100 dark:bg-yellow-900/30 text-yellow-800 dark:text-yellow-300">
  Pending
</span>

<span class="inline-flex items-center px-3 py-1 rounded-full text-sm font-semibold bg-red-100 dark:bg-red-900/30 text-red-800 dark:text-red-300">
  Inactive
</span>
```

### Code Blocks

```html
<!-- Code block with dark mode -->
<pre class="bg-gray-900 dark:bg-gray-950 text-gray-100 rounded-lg p-4 overflow-x-auto">
  <code class="text-sm font-mono">
const greeting = 'Hello, World!'
console.log(greeting)
  </code>
</pre>
```

---

## Testing Dark Mode

### Manual Testing

1. **Toggle test**: Verify theme toggle button works
2. **Persistence test**: Check localStorage saves preference
3. **System preference test**: Test `prefers-color-scheme` detection
4. **Visual test**: Verify all components in both modes
5. **Contrast test**: Check WCAG contrast ratios

### Browser DevTools

```javascript
// Test dark mode in console
document.documentElement.classList.add('dark')
document.documentElement.classList.remove('dark')

// Test system preference
window.matchMedia('(prefers-color-scheme: dark)').matches
```

### Automated Testing

```javascript
// Playwright/Cypress example
test('dark mode toggle', async ({ page }) => {
  await page.goto('/')

  // Click theme toggle
  await page.click('[aria-label="Toggle theme"]')

  // Verify dark class added
  const htmlClass = await page.getAttribute('html', 'class')
  expect(htmlClass).toContain('dark')

  // Verify localStorage
  const theme = await page.evaluate(() => localStorage.getItem('theme'))
  expect(theme).toBe('dark')
})
```

---

## AI Pair Programming Notes

**When to load this KB:**
- Implementing dark mode in Tailwind projects
- Creating theme toggle functionality
- Designing components that support both light and dark themes
- Setting up CSS variables for theming

**Common starting points:**
- Basic setup: See Configuration
- Manual toggle: See Manual Dark Mode Toggle
- Component styling: See Complete Component Examples
- CSS variables: See CSS Variables Approach

**Typical questions:**
- "How do I enable dark mode in Tailwind?" → Configuration
- "How do I create a theme toggle?" → Manual Dark Mode Toggle
- "How do I style components for dark mode?" → Complete Component Examples
- "Should I use class or media strategy?" → Configuration (class is recommended)

**Related topics:**
- Customization: See `04-CUSTOMIZATION.md`
- Components: See `05-LAYOUT-PATTERNS.md`
- Responsive design: See `03-RESPONSIVE-DESIGN.md`

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1
