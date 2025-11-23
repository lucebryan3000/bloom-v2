---
id: theme-framework-integration
topic: theme
file_role: framework
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [theme-fundamentals]
last_reviewed: 2025-11-16
---

# Theme - Framework Integration Patterns

## Next.js + Tailwind Dark Mode

```tsx
// app/layout.tsx
import { ThemeProvider } from 'next-themes'

export default function RootLayout({ children }) {
  return (
    <html suppressHydrationWarning>
      <body>
        <ThemeProvider attribute="class" defaultTheme="dark">
          {children}
        </ThemeProvider>
      </body>
    </html>
  )
}
```

## Theme Toggle Component

```tsx
'use client'
import { useTheme } from 'next-themes'

export function ThemeToggle() {
  const { theme, setTheme } = useTheme()
  
  return (
    <button onClick={() => setTheme(theme === 'dark' ? 'light' : 'dark')}>
      Toggle Theme
    </button>
  )
}
```

## Tailwind Configuration

```js
// tailwind.config.js
module.exports = {
  darkMode: 'class', // Use class-based dark mode
  theme: {
    extend: {
      colors: {
        background: 'var(--background)',
        foreground: 'var(--foreground)',
      }
    }
  }
}
```

## Best Practices

- Use semantic CSS variables
- Support system preference
- Persist user choice
- Avoid flash of unstyled content

## AI Pair Programming Notes

**When to load:** Implementing dark mode with Next.js and Tailwind
