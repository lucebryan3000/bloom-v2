---
id: tailwind-framework-patterns
topic: tailwind
file_role: framework
profile: full
difficulty_level: advanced
kb_version: 3.1
prerequisites: [tailwind-fundamentals, tailwind-integrations]
related_topics: [nextjs, react, component-patterns, state-management, typescript]
embedding_keywords: [tailwind, framework, patterns, nextjs, react, components, advanced]
last_reviewed: 2025-11-16
---

# Tailwind CSS - Framework Integration Patterns

**Advanced production-ready patterns for integrating Tailwind CSS with modern frameworks, component libraries, and state management.**

## Overview

This guide covers advanced framework integration patterns beyond basic setup. Focus on component composition, type safety, performance optimization, and production patterns.

---

## Next.js App Router Patterns

### Server vs Client Component Styling

```tsx
// app/components/ServerCard.tsx (Server Component)
export function ServerCard({ title, description }: { title: string; description: string }) {
  return (
    <div className="bg-white dark:bg-gray-800 rounded-lg shadow-md p-6">
      <h3 className="text-xl font-bold text-gray-900 dark:text-white mb-2">
        {title}
      </h3>
      <p className="text-gray-600 dark:text-gray-300">
        {description}
      </p>
    </div>
  )
}

// app/components/ClientCard.tsx (Client Component)
'use client'

import { useState } from 'react'

export function ClientCard({ title, description }: { title: string; description: string }) {
  const [isExpanded, setIsExpanded] = useState(false)

  return (
    <div className="bg-white dark:bg-gray-800 rounded-lg shadow-md p-6">
      <h3 className="text-xl font-bold text-gray-900 dark:text-white mb-2">
        {title}
      </h3>
      <p className={`text-gray-600 dark:text-gray-300 ${isExpanded ? '' : 'line-clamp-2'}`}>
        {description}
      </p>
      <button
        onClick={() => setIsExpanded(!isExpanded)}
        className="mt-2 text-blue-600 dark:text-blue-400 hover:underline"
      >
        {isExpanded ? 'Show less' : 'Show more'}
      </button>
    </div>
  )
}
```

### Composition Pattern

```tsx
// app/components/Layout.tsx (Server Component)
import { Nav } from './Nav'
import { Sidebar } from './Sidebar'
import { Footer } from './Footer'

export function Layout({ children }: { children: React.ReactNode }) {
  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
      <Nav />
      <div className="flex">
        <Sidebar className="hidden lg:block w-64 shrink-0" />
        <main className="flex-1 p-6">
          {children}
        </main>
      </div>
      <Footer />
    </div>
  )
}

// app/page.tsx
import { Layout } from './components/Layout'
import { ServerCard } from './components/ServerCard'
import { ClientCard } from './components/ClientCard'

export default function Page() {
  return (
    <Layout>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <ServerCard title="Server Card" description="Rendered on server" />
        <ClientCard title="Client Card" description="Interactive on client" />
      </div>
    </Layout>
  )
}
```

---

## React Component Patterns

### Compound Components

```tsx
// components/Card/index.tsx
import { createContext, useContext, ReactNode } from 'react'

const CardContext = createContext<{ variant?: 'default' | 'bordered' | 'elevated' }>({})

export function Card({ children, variant = 'default' }: { children: ReactNode; variant?: 'default' | 'bordered' | 'elevated' }) {
  const baseClasses = 'bg-white dark:bg-gray-800 rounded-lg p-6'
  const variantClasses = {
    default: '',
    bordered: 'border-2 border-gray-200 dark:border-gray-700',
    elevated: 'shadow-xl',
  }

  return (
    <CardContext.Provider value={{ variant }}>
      <div className={`${baseClasses} ${variantClasses[variant]}`}>
        {children}
      </div>
    </CardContext.Provider>
  )
}

Card.Header = function CardHeader({ children }: { children: ReactNode }) {
  return (
    <div className="border-b border-gray-200 dark:border-gray-700 pb-4 mb-4">
      {children}
    </div>
  )
}

Card.Title = function CardTitle({ children }: { children: ReactNode }) {
  return (
    <h3 className="text-2xl font-bold text-gray-900 dark:text-white">
      {children}
    </h3>
  )
}

Card.Body = function CardBody({ children }: { children: ReactNode }) {
  return (
    <div className="text-gray-600 dark:text-gray-300">
      {children}
    </div>
  )
}

Card.Footer = function CardFooter({ children }: { children: ReactNode }) {
  return (
    <div className="border-t border-gray-200 dark:border-gray-700 pt-4 mt-4">
      {children}
    </div>
  )
}

// Usage
<Card variant="elevated">
  <Card.Header>
    <Card.Title>Card Title</Card.Title>
  </Card.Header>
  <Card.Body>
    <p>Card content goes here</p>
  </Card.Body>
  <Card.Footer>
    <button className="bg-blue-600 text-white px-4 py-2 rounded">Action</button>
  </Card.Footer>
</Card>
```

### Render Props with Tailwind

```tsx
// components/Dropdown.tsx
import { useState, ReactNode } from 'react'

interface DropdownProps {
  trigger: (props: { isOpen: boolean; toggle: () => void }) => ReactNode
  children: (props: { close: () => void }) => ReactNode
}

export function Dropdown({ trigger, children }: DropdownProps) {
  const [isOpen, setIsOpen] = useState(false)

  return (
    <div className="relative">
      {trigger({ isOpen, toggle: () => setIsOpen(!isOpen) })}

      {isOpen && (
        <>
          <div className="fixed inset-0 z-10" onClick={() => setIsOpen(false)} />
          <div className="absolute right-0 mt-2 w-56 bg-white dark:bg-gray-800 rounded-lg shadow-lg ring-1 ring-black ring-opacity-5 z-20">
            <div className="py-1">
              {children({ close: () => setIsOpen(false) })}
            </div>
          </div>
        </>
      )}
    </div>
  )
}

// Usage
<Dropdown
  trigger={({ isOpen, toggle }) => (
    <button
      onClick={toggle}
      className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
    >
      Options {isOpen ? '▲' : '▼'}
    </button>
  )}
>
  {({ close }) => (
    <>
      <button
        onClick={close}
        className="block w-full text-left px-4 py-2 text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700"
      >
        Edit
      </button>
      <button
        onClick={close}
        className="block w-full text-left px-4 py-2 text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700"
      >
        Delete
      </button>
    </>
  )}
</Dropdown>
```

---

## TypeScript Patterns

### Type-Safe Class Composition

```tsx
// lib/cn.ts (Class Name utility)
import { clsx, type ClassValue } from 'clsx'
import { twMerge } from 'tailwind-merge'

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

// Usage
import { cn } from '@/lib/cn'

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'ghost'
  size?: 'sm' | 'md' | 'lg'
}

export function Button({ variant = 'primary', size = 'md', className, children, ...props }: ButtonProps) {
  return (
    <button
      className={cn(
        'font-semibold rounded-lg transition-colors',
        {
          'bg-blue-600 text-white hover:bg-blue-700': variant === 'primary',
          'bg-gray-200 text-gray-900 hover:bg-gray-300': variant === 'secondary',
          'hover:bg-gray-100': variant === 'ghost',
        },
        {
          'px-3 py-1.5 text-sm': size === 'sm',
          'px-4 py-2 text-base': size === 'md',
          'px-6 py-3 text-lg': size === 'lg',
        },
        className
      )}
      {...props}
    >
      {children}
    </button>
  )
}
```

### Variant API with CVA

```tsx
// components/Button.tsx
import { cva, type VariantProps } from 'class-variance-authority'
import { cn } from '@/lib/cn'

const buttonVariants = cva(
  'inline-flex items-center justify-center rounded-lg font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 disabled:opacity-50 disabled:pointer-events-none',
  {
    variants: {
      variant: {
        primary: 'bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500',
        secondary: 'bg-gray-200 text-gray-900 hover:bg-gray-300 focus:ring-gray-500',
        destructive: 'bg-red-600 text-white hover:bg-red-700 focus:ring-red-500',
        outline: 'border-2 border-gray-300 hover:bg-gray-100 focus:ring-gray-500',
        ghost: 'hover:bg-gray-100 focus:ring-gray-500',
      },
      size: {
        sm: 'px-3 py-1.5 text-sm',
        md: 'px-4 py-2 text-base',
        lg: 'px-6 py-3 text-lg',
      },
    },
    defaultVariants: {
      variant: 'primary',
      size: 'md',
    },
  }
)

interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {}

export function Button({ variant, size, className, ...props }: ButtonProps) {
  return <button className={cn(buttonVariants({ variant, size }), className)} {...props} />
}

// Usage with full TypeScript safety
<Button variant="primary" size="lg">Click me</Button>
<Button variant="destructive">Delete</Button>
```

---

## Component Library Integration

### shadcn/ui Patterns

```tsx
// components/ui/dialog.tsx
'use client'

import * as DialogPrimitive from '@radix-ui/react-dialog'
import { X } from 'lucide-react'
import { cn } from '@/lib/cn'

const Dialog = DialogPrimitive.Root
const DialogTrigger = DialogPrimitive.Trigger

const DialogContent = React.forwardRef<
  React.ElementRef<typeof DialogPrimitive.Content>,
  React.ComponentPropsWithoutRef<typeof DialogPrimitive.Content>
>(({ className, children, ...props }, ref) => (
  <DialogPrimitive.Portal>
    <DialogPrimitive.Overlay className="fixed inset-0 z-50 bg-black/50 data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0" />
    <DialogPrimitive.Content
      ref={ref}
      className={cn(
        'fixed left-[50%] top-[50%] z-50 w-full max-w-lg translate-x-[-50%] translate-y-[-50%] gap-4 border bg-white dark:bg-gray-900 p-6 shadow-lg duration-200 data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0 data-[state=closed]:zoom-out-95 data-[state=open]:zoom-in-95 data-[state=closed]:slide-out-to-left-1/2 data-[state=closed]:slide-out-to-top-[48%] data-[state=open]:slide-in-from-left-1/2 data-[state=open]:slide-in-from-top-[48%] rounded-lg',
        className
      )}
      {...props}
    >
      {children}
      <DialogPrimitive.Close className="absolute right-4 top-4 rounded-sm opacity-70 ring-offset-white transition-opacity hover:opacity-100 focus:outline-none focus:ring-2 focus:ring-gray-400 focus:ring-offset-2 disabled:pointer-events-none data-[state=open]:bg-gray-100 dark:ring-offset-gray-950 dark:focus:ring-gray-800 dark:data-[state=open]:bg-gray-800">
        <X className="h-4 w-4" />
        <span className="sr-only">Close</span>
      </DialogPrimitive.Close>
    </DialogPrimitive.Content>
  </DialogPrimitive.Portal>
))
DialogContent.displayName = DialogPrimitive.Content.displayName

// Usage
<Dialog>
  <DialogTrigger asChild>
    <Button>Open Dialog</Button>
  </DialogTrigger>
  <DialogContent>
    <h2 className="text-lg font-semibold">Dialog Title</h2>
    <p className="text-gray-600 dark:text-gray-400">Dialog content</p>
  </DialogContent>
</Dialog>
```

---

## State Management Integration

### Zustand with Tailwind

```tsx
// stores/themeStore.ts
import { create } from 'zustand'
import { persist } from 'zustand/middleware'

interface ThemeStore {
  theme: 'light' | 'dark'
  setTheme: (theme: 'light' | 'dark') => void
  toggleTheme: () => void
}

export const useThemeStore = create<ThemeStore>()(
  persist(
    (set) => ({
      theme: 'light',
      setTheme: (theme) => {
        set({ theme })
        document.documentElement.classList.toggle('dark', theme === 'dark')
      },
      toggleTheme: () =>
        set((state) => {
          const newTheme = state.theme === 'light' ? 'dark' : 'light'
          document.documentElement.classList.toggle('dark', newTheme === 'dark')
          return { theme: newTheme }
        }),
    }),
    { name: 'theme-storage' }
  )
)

// components/ThemeToggle.tsx
'use client'

import { useThemeStore } from '@/stores/themeStore'
import { Moon, Sun } from 'lucide-react'

export function ThemeToggle() {
  const { theme, toggleTheme } = useThemeStore()

  return (
    <button
      onClick={toggleTheme}
      className="p-2 rounded-lg bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors"
      aria-label="Toggle theme"
    >
      {theme === 'light' ? <Moon className="w-5 h-5" /> : <Sun className="w-5 h-5" />}
    </button>
  )
}
```

### React Query with Tailwind

```tsx
// hooks/useProjects.ts
import { useQuery } from '@tanstack/react-query'

interface Project {
  id: string
  name: string
  status: 'active' | 'archived'
}

async function fetchProjects(): Promise<Project[]> {
  const res = await fetch('/api/projects')
  return res.json()
}

export function useProjects() {
  return useQuery({
    queryKey: ['projects'],
    queryFn: fetchProjects,
  })
}

// components/ProjectList.tsx
'use client'

import { useProjects } from '@/hooks/useProjects'

export function ProjectList() {
  const { data: projects, isLoading, error } = useProjects()

  if (isLoading) {
    return (
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {[...Array(6)].map((_, i) => (
          <div key={i} className="animate-pulse">
            <div className="h-32 bg-gray-200 dark:bg-gray-800 rounded-lg"></div>
          </div>
        ))}
      </div>
    )
  }

  if (error) {
    return (
      <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 text-red-800 dark:text-red-200 rounded-lg p-4">
        <p className="font-semibold">Error loading projects</p>
        <p className="text-sm mt-1">{error.message}</p>
      </div>
    )
  }

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      {projects?.map((project) => (
        <div
          key={project.id}
          className="bg-white dark:bg-gray-800 rounded-lg shadow-md p-6 hover:shadow-lg transition-shadow"
        >
          <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-2">
            {project.name}
          </h3>
          <span
            className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
              project.status === 'active'
                ? 'bg-green-100 dark:bg-green-900/30 text-green-800 dark:text-green-300'
                : 'bg-gray-100 dark:bg-gray-700 text-gray-800 dark:text-gray-300'
            }`}
          >
            {project.status}
          </span>
        </div>
      ))}
    </div>
  )
}
```

---

## Performance Optimization

### Code Splitting CSS

```tsx
// components/HeavyComponent.tsx
import dynamic from 'next/dynamic'

// Dynamically import heavy component with custom loading
const HeavyChart = dynamic(() => import('./HeavyChart'), {
  loading: () => (
    <div className="animate-pulse bg-gray-200 dark:bg-gray-800 h-96 rounded-lg" />
  ),
  ssr: false, // Disable SSR for client-only components
})

export function Dashboard() {
  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <div className="bg-white dark:bg-gray-800 rounded-lg p-6">
        <h3 className="text-lg font-semibold mb-4">Chart</h3>
        <HeavyChart />
      </div>
    </div>
  )
}
```

### Memoized Class Computation

```tsx
// hooks/useButtonClasses.ts
import { useMemo } from 'react'
import { cn } from '@/lib/cn'

export function useButtonClasses(variant: string, size: string, className?: string) {
  return useMemo(() => {
    const baseClasses = 'font-semibold rounded-lg transition-colors'
    const variantClasses = {
      primary: 'bg-blue-600 text-white hover:bg-blue-700',
      secondary: 'bg-gray-200 text-gray-900 hover:bg-gray-300',
    }[variant]
    const sizeClasses = {
      sm: 'px-3 py-1.5 text-sm',
      md: 'px-4 py-2 text-base',
      lg: 'px-6 py-3 text-lg',
    }[size]

    return cn(baseClasses, variantClasses, sizeClasses, className)
  }, [variant, size, className])
}

// Usage
export function Button({ variant = 'primary', size = 'md', className, ...props }) {
  const classes = useButtonClasses(variant, size, className)
  return <button className={classes} {...props} />
}
```

---

## Testing Patterns

### Jest + React Testing Library

```tsx
// components/__tests__/Button.test.tsx
import { render, screen } from '@testing-library/react'
import { Button } from '../Button'

describe('Button', () => {
  it('renders with primary variant classes', () => {
    render(<Button variant="primary">Click me</Button>)
    const button = screen.getByRole('button')
    expect(button).toHaveClass('bg-blue-600')
    expect(button).toHaveClass('text-white')
  })

  it('renders with secondary variant classes', () => {
    render(<Button variant="secondary">Click me</Button>)
    const button = screen.getByRole('button')
    expect(button).toHaveClass('bg-gray-200')
  })

  it('applies custom className', () => {
    render(<Button className="custom-class">Click me</Button>)
    const button = screen.getByRole('button')
    expect(button).toHaveClass('custom-class')
  })
})
```

---

## AI Pair Programming Notes

**When to load this KB:**
- Building complex component systems with Tailwind
- Integrating Tailwind with state management
- Creating type-safe Tailwind components
- Optimizing Tailwind performance in production

**Common patterns:**
- Component composition: See Compound Components
- Type safety: See TypeScript Patterns → Variant API with CVA
- State management: See Zustand with Tailwind
- Performance: See Performance Optimization

**Related topics:**
- Basic integration: See `10-INTEGRATIONS.md`
- Component patterns: See `05-LAYOUT-PATTERNS.md`
- Customization: See `04-CUSTOMIZATION.md`

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1
