---
id: ui-quick-reference
topic: ui
file_role: quickref
profile: full
difficulty_level: all-levels
kb_version: 3.1
prerequisites: []
related_topics: [react, tailwind, design-systems]
embedding_keywords: [ui-quickref, styling-snippets, tailwind-examples, dark-mode-quick]
last_reviewed: 2025-11-13
---

# UI/Styling - Quick Reference

**Purpose**: Copy-paste snippets for common UI tasks

**Usage**: Ctrl+F/Cmd+F to search, copy code directly

---

## 🎨 Dark Mode Patterns

### Tier 1: Semantic CSS Variables (PREFERRED)

```tsx
// Background and text
<div className="bg-background text-foreground">

// Cards
<div className="bg-card text-card-foreground border border-border">

// Muted text (helper/secondary text)
<p className="text-muted-foreground">Helper text</p>

// Primary actions
<button className="bg-primary text-primary-foreground">

// Secondary elements
<div className="bg-secondary text-secondary-foreground">

// Accent highlights
<div className="bg-accent text-accent-foreground">

// Destructive/errors
<button className="bg-destructive text-destructive-foreground">
```

### Tier 2: Badge Variants

```tsx
import { badgeVariants } from '@/lib/ui/badge-variants';
import { Badge } from '@/components/ui/badge';

// Status badges
<Badge className={badgeVariants.success}>Active</Badge>
<Badge className={badgeVariants.warning}>Pending</Badge>
<Badge className={badgeVariants.error}>Failed</Badge>
<Badge className={badgeVariants.info}>Info</Badge>

// Task status
<Badge className={badgeVariants.status.idle}>Idle</Badge>
<Badge className={badgeVariants.status.running}>Running</Badge>
<Badge className={badgeVariants.status.completed}>Completed</Badge>
<Badge className={badgeVariants.status.failed}>Failed</Badge>

// Schedule types
<Badge className={badgeVariants.status.hourly}>Hourly</Badge>
<Badge className={badgeVariants.status.daily}>Daily</Badge>
<Badge className={badgeVariants.status.weekly}>Weekly</Badge>
```

### Tier 3: Manual Dark Classes

```tsx
// Only use when Tiers 1 & 2 don't apply
<div className="bg-blue-50 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300">

// Pattern: light colors + dark: dark colors
<span className="text-gray-600 dark:text-gray-300">
<div className="bg-green-100 dark:bg-green-900/20">
<button className="hover:bg-gray-100 dark:hover:bg-gray-800">
```

---

## 📐 Layout Patterns

### Responsive Grid

```tsx
// 1 column mobile, 2 tablet, 3 desktop
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">

// Auto-fit with min/max
<div className="grid grid-cols-[repeat(auto-fit,minmax(250px,1fr))] gap-4">

// Specific column sizes
<div className="grid grid-cols-[200px_1fr_200px] gap-4">
```

### Responsive Flex

```tsx
// Column on mobile, row on desktop
<div className="flex flex-col md:flex-row gap-4">

// Centered content
<div className="flex items-center justify-center min-h-screen">

// Space between items
<div className="flex justify-between items-center">

// Wrap items
<div className="flex flex-wrap gap-2">
```

### Container

```tsx
// Centered container with max width
<div className="container mx-auto max-w-7xl px-4">

// Full width
<div className="w-full">

// Constrained width
<div className="max-w-2xl mx-auto">
```

---

## 🔘 Interactive Components

### Buttons

```tsx
// Primary button
<Button variant="default" size="default">
  Click me
</Button>

// Secondary button
<Button variant="secondary">
  Secondary Action
</Button>

// Destructive button
<Button variant="destructive">
  Delete
</Button>

// Ghost button
<Button variant="ghost">
  Cancel
</Button>

// With icon
<Button>
  <Plus className="mr-2 h-4 w-4" />
  Add Item
</Button>

// Loading state
<Button disabled={isLoading}>
  {isLoading ? "Loading..." : "Submit"}
</Button>
```

### Cards

```tsx
import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter } from '@/components/ui/card';

<Card>
  <CardHeader>
    <CardTitle>Card Title</CardTitle>
    <CardDescription>Card description text</CardDescription>
  </CardHeader>
  <CardContent>
    <p>Main content goes here</p>
  </CardContent>
  <CardFooter>
    <Button>Action</Button>
  </CardFooter>
</Card>
```

### Forms

```tsx
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';

<div className="space-y-2">
  <Label htmlFor="email">Email</Label>
  <Input
    id="email"
    type="email"
    placeholder="you@example.com"
  />
</div>

// With validation error
<div className="space-y-2">
  <Label htmlFor="password" className={error ? "text-destructive" : ""}>
    Password
  </Label>
  <Input
    id="password"
    type="password"
    className={error ? "border-destructive" : ""}
  />
  {error && <p className="text-sm text-destructive">{error}</p>}
</div>
```

---

## 🎯 Common Patterns

### Loading States

```tsx
// Spinner
<div className="flex items-center justify-center p-4">
  <Loader2 className="h-6 w-6 animate-spin text-primary" />
</div>

// Skeleton
<div className="space-y-2">
  <Skeleton className="h-4 w-full" />
  <Skeleton className="h-4 w-3/4" />
  <Skeleton className="h-4 w-1/2" />
</div>

// Button loading
<Button disabled={isLoading}>
  {isLoading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
  {isLoading ? "Processing..." : "Submit"}
</Button>
```

### Empty States

```tsx
<div className="flex flex-col items-center justify-center p-8 text-center">
  <FileQuestion className="h-12 w-12 text-muted-foreground mb-4" />
  <h3 className="text-lg font-semibold">No items found</h3>
  <p className="text-sm text-muted-foreground mb-4">
    Get started by creating your first item
  </p>
  <Button>
    <Plus className="mr-2 h-4 w-4" />
    Create Item
  </Button>
</div>
```

### Error States

```tsx
<div className="rounded-lg border border-destructive bg-destructive/10 p-4">
  <div className="flex items-start gap-3">
    <AlertCircle className="h-5 w-5 text-destructive" />
    <div className="flex-1">
      <h4 className="text-sm font-semibold text-destructive">Error</h4>
      <p className="text-sm text-destructive/90">
        {errorMessage}
      </p>
    </div>
  </div>
</div>
```

---

## 📊 Data Display

### Tables

```tsx
<div className="rounded-md border">
  <table className="w-full">
    <thead>
      <tr className="border-b bg-muted/50">
        <th className="px-4 py-2 text-left font-medium">Name</th>
        <th className="px-4 py-2 text-left font-medium">Status</th>
        <th className="px-4 py-2 text-right font-medium">Actions</th>
      </tr>
    </thead>
    <tbody>
      <tr className="border-b">
        <td className="px-4 py-2">John Doe</td>
        <td className="px-4 py-2">
          <Badge className={badgeVariants.success}>Active</Badge>
        </td>
        <td className="px-4 py-2 text-right">
          <Button variant="ghost" size="sm">Edit</Button>
        </td>
      </tr>
    </tbody>
  </table>
</div>
```

### Lists

```tsx
// Simple list
<ul className="space-y-2">
  {items.map(item => (
    <li key={item.id} className="flex items-center justify-between p-2 rounded hover:bg-accent">
      <span>{item.name}</span>
      <Button variant="ghost" size="sm">View</Button>
    </li>
  ))}
</ul>

// Card list
<div className="space-y-4">
  {items.map(item => (
    <Card key={item.id}>
      <CardHeader>
        <CardTitle>{item.title}</CardTitle>
        <CardDescription>{item.description}</CardDescription>
      </CardHeader>
    </Card>
  ))}
</div>
```

---

## ♿ Accessibility

### Focus Indicators

```tsx
// Button focus
<button className="focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2">

// Input focus
<input className="focus:ring-2 focus:ring-primary focus:border-primary">

// Custom focus
<div tabIndex={0} className="focus:outline-none focus:ring-2 focus:ring-primary rounded">
```

### Screen Reader

```tsx
// Accessible button
<button aria-label="Close dialog">
  <X className="h-4 w-4" />
</button>

// Accessible image
<img src="/logo.png" alt="Company logo" />

// Hidden from screen readers
<span aria-hidden="true">•</span>

// Screen reader only
<span className="sr-only">Loading...</span>
```

---

## 📱 Responsive Breakpoints

```tsx
// Tailwind breakpoints
sm: 640px   // Small devices
md: 768px   // Medium devices
lg: 1024px  // Large devices
xl: 1280px  // Extra large
2xl: 1536px // 2X extra large

// Usage
<div className="text-sm md:text-base lg:text-lg">
<div className="hidden md:block">  // Hide on mobile
<div className="block md:hidden">  // Show only on mobile
```

---

## 🔗 Related Files

- **[DARK-MODE-STANDARDS.md](./DARK-MODE-STANDARDS.md)** - Complete dark mode guide
- **[DEVELOPER-REFERENCE-BADGE-VARIANTS.md](./DEVELOPER-REFERENCE-BADGE-VARIANTS.md)** - All badge variants
- **[FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md)** - Framework patterns
- **[INDEX.md](./INDEX.md)** - Complete navigation

---

**Last Updated**: 2025-11-13
**KB Version**: 3.1
