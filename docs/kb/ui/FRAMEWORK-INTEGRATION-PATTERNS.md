---
id: ui-framework-integration-patterns
topic: ui
file_role: patterns
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [react, tailwind]
related_topics: [react, nextjs, typescript, design-systems]
embedding_keywords: [ui-patterns, react-ui, nextjs-ui, component-patterns, styling-patterns]
last_reviewed: 2025-11-13
---

# UI/Styling - Framework Integration Patterns

**Purpose**: Production-ready UI patterns for React and Next.js

**Scope**: Component patterns, styling integration, dark mode support, form handling

---

## Pattern 1: Dark Mode Button Component (React + Tailwind)

```tsx
// components/ui/button.tsx
import { forwardRef } from 'react';
import { cva, type VariantProps } from 'class-variance-authority';

const buttonVariants = cva(
  'inline-flex items-center justify-center rounded-md font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50',
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
    VariantProps<typeof buttonVariants> {}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant, size, ...props }, ref) => {
    return (
      <button
        className={buttonVariants({ variant, size, className })}
        ref={ref}
        {...props}
      />
    );
  }
);
Button.displayName = 'Button';
```

**Key Features**:
- ✅ Automatic dark mode via semantic variables
- ✅ Type-safe variants with CVA
- ✅ Accessible focus states
- ✅ Disabled state handling

---

## Pattern 2: Form with Dark Mode Support (React Hook Form + Zod)

```tsx
// app/components/user-form.tsx
'use client';

import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Button } from '@/components/ui/button';

const formSchema = z.object({
  email: z.string().email('Invalid email address'),
  name: z.string().min(2, 'Name must be at least 2 characters'),
});

type FormValues = z.infer<typeof formSchema>;

export function UserForm() {
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<FormValues>({
    resolver: zodResolver(formSchema),
  });

  const onSubmit = async (data: FormValues) => {
    // Handle form submission
    console.log(data);
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
      <div className="space-y-2">
        <Label htmlFor="email">Email</Label>
        <Input
          id="email"
          type="email"
          placeholder="you@example.com"
          {...register('email')}
          className={errors.email ? 'border-destructive' : ''}
        />
        {errors.email && (
          <p className="text-sm text-destructive">{errors.email.message}</p>
        )}
      </div>

      <div className="space-y-2">
        <Label htmlFor="name">Name</Label>
        <Input
          id="name"
          {...register('name')}
          className={errors.name ? 'border-destructive' : ''}
        />
        {errors.name && (
          <p className="text-sm text-destructive">{errors.name.message}</p>
        )}
      </div>

      <Button type="submit" disabled={isSubmitting}>
        {isSubmitting ? 'Submitting...' : 'Submit'}
      </Button>
    </form>
  );
}
```

**Key Features**:
- ✅ Type-safe form validation with Zod
- ✅ Dark mode error states
- ✅ Loading state handling
- ✅ Accessible labels

---

## Pattern 3: Status Badge System (Centralized Variants)

```tsx
// lib/ui/badge-variants.ts
import { cva } from 'class-variance-authority';

export const badgeVariants = {
  // Semantic status badges
  success: 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-300 border-green-200 dark:border-green-800',
  warning: 'bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-300 border-yellow-200 dark:border-yellow-800',
  error: 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-300 border-red-200 dark:border-red-800',
  info: 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300 border-blue-200 dark:border-blue-800',

  // Task status
  status: {
    idle: 'bg-gray-100 text-gray-600 dark:bg-gray-800 dark:text-gray-300',
    running: 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300',
    completed: 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-300',
    failed: 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-300',
  },
};

// Usage in components
import { Badge } from '@/components/ui/badge';
import { badgeVariants } from '@/lib/ui/badge-variants';

<Badge className={badgeVariants.success}>Active</Badge>
<Badge className={badgeVariants.status.running}>Running</Badge>
```

**Key Features**:
- ✅ Centralized variant management
- ✅ Dark mode support built-in
- ✅ Semantic naming
- ✅ Easy to extend

---

## Pattern 4: Responsive Card Grid (Next.js Server Component)

```tsx
// app/components/card-grid.tsx
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from '@/components/ui/card';

interface Item {
  id: string;
  title: string;
  description: string;
}

interface CardGridProps {
  items: Item[];
}

export function CardGrid({ items }: CardGridProps) {
  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      {items.map((item) => (
        <Card key={item.id} className="hover:shadow-lg transition-shadow">
          <CardHeader>
            <CardTitle>{item.title}</CardTitle>
            <CardDescription>{item.description}</CardDescription>
          </CardHeader>
          <CardContent>
            {/* Card content */}
          </CardContent>
        </Card>
      ))}
    </div>
  );
}
```

**Key Features**:
- ✅ Responsive breakpoints
- ✅ Server component (zero JS by default)
- ✅ Hover effects
- ✅ Dark mode compatible

---

## Pattern 5: Dialog/Modal with Form (shadcn/ui)

```tsx
// app/components/create-item-dialog.tsx
'use client';

import { useState } from 'react';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';

export function CreateItemDialog() {
  const [open, setOpen] = useState(false);
  const [name, setName] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    // Handle submission
    await createItem({ name });
    setOpen(false);
    setName('');
  };

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button>Create Item</Button>
      </DialogTrigger>
      <DialogContent className="sm:max-w-[425px]">
        <form onSubmit={handleSubmit}>
          <DialogHeader>
            <DialogTitle>Create new item</DialogTitle>
            <DialogDescription>
              Add a new item to your collection
            </DialogDescription>
          </DialogHeader>
          <div className="grid gap-4 py-4">
            <div className="grid gap-2">
              <Label htmlFor="name">Name</Label>
              <Input
                id="name"
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="Enter name"
              />
            </div>
          </div>
          <DialogFooter>
            <Button type="button" variant="ghost" onClick={() => setOpen(false)}>
              Cancel
            </Button>
            <Button type="submit">Create</Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
```

**Key Features**:
- ✅ Controlled dialog state
- ✅ Form integration
- ✅ Responsive max-width
- ✅ Accessible keyboard navigation

---

## Pattern 6: Loading Skeleton (React)

```tsx
// components/ui/skeleton.tsx
export function Skeleton({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      className={`animate-pulse rounded-md bg-muted ${className}`}
      {...props}
    />
  );
}

// Usage in loading states
export function CardSkeleton() {
  return (
    <Card>
      <CardHeader>
        <Skeleton className="h-4 w-2/3" />
        <Skeleton className="h-3 w-1/2 mt-2" />
      </CardHeader>
      <CardContent>
        <Skeleton className="h-20 w-full" />
      </CardContent>
    </Card>
  );
}

// In Next.js page with Suspense
import { Suspense } from 'react';

export default function Page() {
  return (
    <Suspense fallback={<CardSkeleton />}>
      <CardGrid />
    </Suspense>
  );
}
```

**Key Features**:
- ✅ Dark mode compatible
- ✅ Flexible sizing
- ✅ Works with Suspense

---

## Pattern 7: Toast Notifications (React + Context)

```tsx
// components/ui/toast-provider.tsx
'use client';

import { Toaster } from 'sonner';

export function ToastProvider() {
  return (
    <Toaster
      position="top-right"
      toastOptions={{
        classNames: {
          toast: 'bg-card text-card-foreground border border-border',
          success: 'bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-300',
          error: 'bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-300',
        },
      }}
    />
  );
}

// Usage in components
import { toast } from 'sonner';

function MyComponent() {
  const handleSuccess = () => {
    toast.success('Item created successfully');
  };

  const handleError = () => {
    toast.error('Failed to create item');
  };

  return <Button onClick={handleSuccess}>Create</Button>;
}
```

**Key Features**:
- ✅ Dark mode theming
- ✅ Position customization
- ✅ Success/error variants

---

## Pattern 8: Data Table with Sorting (React + TanStack Table)

```tsx
// components/data-table.tsx
'use client';

import {
  flexRender,
  getCoreRowModel,
  getSortedRowModel,
  useReactTable,
  type ColumnDef,
  type SortingState,
} from '@tanstack/react-table';
import { useState } from 'react';
import { ArrowUpDown } from 'lucide-react';

interface DataTableProps<TData, TValue> {
  columns: ColumnDef<TData, TValue>[];
  data: TData[];
}

export function DataTable<TData, TValue>({
  columns,
  data,
}: DataTableProps<TData, TValue>) {
  const [sorting, setSorting] = useState<SortingState>([]);

  const table = useReactTable({
    data,
    columns,
    getCoreRowModel: getCoreRowModel(),
    onSortingChange: setSorting,
    getSortedRowModel: getSortedRowModel(),
    state: {
      sorting,
    },
  });

  return (
    <div className="rounded-md border">
      <table className="w-full">
        <thead>
          {table.getHeaderGroups().map((headerGroup) => (
            <tr key={headerGroup.id} className="border-b bg-muted/50">
              {headerGroup.headers.map((header) => (
                <th key={header.id} className="px-4 py-2 text-left font-medium">
                  {header.isPlaceholder
                    ? null
                    : flexRender(
                        header.column.columnDef.header,
                        header.getContext()
                      )}
                </th>
              ))}
            </tr>
          ))}
        </thead>
        <tbody>
          {table.getRowModel().rows.map((row) => (
            <tr key={row.id} className="border-b hover:bg-muted/50">
              {row.getVisibleCells().map((cell) => (
                <td key={cell.id} className="px-4 py-2">
                  {flexRender(cell.column.columnDef.cell, cell.getContext())}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

// Define sortable column header
export const sortableHeader = (title: string) => {
  return ({ column }) => (
    <button
      className="flex items-center gap-2 hover:text-foreground"
      onClick={() => column.toggleSorting(column.getIsSorted() === 'asc')}
    >
      {title}
      <ArrowUpDown className="h-4 w-4" />
    </button>
  );
};
```

**Key Features**:
- ✅ Type-safe columns
- ✅ Sorting built-in
- ✅ Dark mode compatible
- ✅ Hover effects

---

## Pattern 9: Theme Switcher (Next.js + next-themes)

```tsx
// components/theme-switcher.tsx
'use client';

import { useTheme } from 'next-themes';
import { Moon, Sun } from 'lucide-react';
import { Button } from '@/components/ui/button';

export function ThemeSwitcher() {
  const { theme, setTheme } = useTheme();

  return (
    <Button
      variant="ghost"
      size="icon"
      onClick={() => setTheme(theme === 'dark' ? 'light' : 'dark')}
    >
      <Sun className="h-5 w-5 rotate-0 scale-100 transition-all dark:-rotate-90 dark:scale-0" />
      <Moon className="absolute h-5 w-5 rotate-90 scale-0 transition-all dark:rotate-0 dark:scale-100" />
      <span className="sr-only">Toggle theme</span>
    </Button>
  );
}

// In app/layout.tsx
import { ThemeProvider } from 'next-themes';

export default function RootLayout({ children }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body>
        <ThemeProvider attribute="class" defaultTheme="system" enableSystem>
          {children}
        </ThemeProvider>
      </body>
    </html>
  );
}
```

**Key Features**:
- ✅ Smooth transitions
- ✅ System preference support
- ✅ No flash on load

---

## Pattern 10: Error Boundary (React 19 + Next.js)

```tsx
// app/error.tsx (Next.js error boundary)
'use client';

import { useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { AlertCircle } from 'lucide-react';

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    console.error(error);
  }, [error]);

  return (
    <div className="flex min-h-screen items-center justify-center p-4">
      <div className="w-full max-w-md space-y-4 text-center">
        <AlertCircle className="mx-auto h-12 w-12 text-destructive" />
        <h2 className="text-2xl font-semibold">Something went wrong!</h2>
        <p className="text-muted-foreground">{error.message}</p>
        <Button onClick={reset}>Try again</Button>
      </div>
    </div>
  );
}
```

**Key Features**:
- ✅ Next.js convention
- ✅ Error logging
- ✅ Recovery action
- ✅ User-friendly message

---

## 🔗 Related Files

- **[DARK-MODE-STANDARDS.md](./DARK-MODE-STANDARDS.md)** - Dark mode guidelines
- **[DEVELOPER-REFERENCE-BADGE-VARIANTS.md](./DEVELOPER-REFERENCE-BADGE-VARIANTS.md)** - Badge variants
- **[QUICK-REFERENCE.md](./QUICK-REFERENCE.md)** - Quick snippets
- **[README.md](./README.md)** - Complete overview

---

**Last Updated**: 2025-11-13
**KB Version**: 3.1
**Pattern Count**: 10
