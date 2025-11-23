---
id: ui-developer-reference-badge-variants
topic: ui
file_role: documentation
profile: full
difficulty_level: all-levels
kb_version: 3.1
prerequisites: []
related_topics: ['ui']
embedding_keywords: [ui]
last_reviewed: 2025-11-13
---

# Developer Reference: Badge Variants and Dark Mode Styling

**Last Updated**: 2025-11-10
**Status**: Production Standard
**Enforcement**: REQUIRED for all UI components

## Table of Contents

1. [Quick Reference](#quick-reference)
2. [Core Concepts](#core-concepts)
3. [Badge Variants Library](#badge-variants-library)
4. [Usage Patterns](#usage-patterns)
5. [Common Mistakes](#common-mistakes)
6. [Migration Guide](#migration-guide)
7. [Testing Dark Mode](#testing-dark-mode)

---

## Quick Reference

### Import Statement

```typescript
import { badgeVariants } from '@/lib/ui/badge-variants';
```

### Most Common Usage

```tsx
// Status badges
<Badge className={badgeVariants.success}>Active</Badge>
<Badge className={badgeVariants.error}>Failed</Badge>
<Badge className={badgeVariants.warning}>Warning</Badge>
<Badge className={badgeVariants.info}>Info</Badge>
<Badge className={badgeVariants.neutral}>Neutral</Badge>

// Frequency/schedule badges
<Badge className={badgeVariants.status.hourly}>Hourly</Badge>
<Badge className={badgeVariants.status.daily}>Daily</Badge>
<Badge className={badgeVariants.status.weekly}>Weekly</Badge>

// Confidence score badges (ROI system)
<Badge className={badgeVariants.confidence.high}>High Confidence</Badge>
<Badge className={badgeVariants.confidence.medium}>Medium</Badge>
<Badge className={badgeVariants.confidence.low}>Low</Badge>

// Execution status badges
<Badge className={badgeVariants.execution.completed}>Done</Badge>
<Badge className={badgeVariants.execution.running}>Running</Badge>
<Badge className={badgeVariants.execution.failed}>Failed</Badge>
```

### Semantic Color Variables (Text & Backgrounds)

```tsx
// ALWAYS prefer these over hardcoded colors
<div className="bg-background text-foreground">
 Main content
</div>

<div className="bg-card text-card-foreground border border-border">
 Card content
</div>

<p className="text-muted-foreground">
 Helper text or descriptions
</p>

<button className="bg-primary text-primary-foreground hover:bg-primary/90">
 Primary Action
</button>

<button className="bg-secondary text-secondary-foreground hover:bg-secondary/80">
 Secondary Action
</button>
```

---

## Core Concepts

### Three-Tier Dark Mode Approach

this project uses a **three-tier system** for dark mode support:

1. **Tier 1: Semantic CSS Variables (PREFERRED)**
 - Use Tailwind's theme-aware utilities
 - Automatically adapts to light/dark mode
 - Examples: `bg-background`, `text-foreground`, `text-muted-foreground`

2. **Tier 2: Centralized Badge Variants**
 - Use `badgeVariants` from `@/lib/ui/badge-variants`
 - Pre-configured for all status/badge use cases
 - Single source of truth

3. **Tier 3: Manual Dark Classes (LAST RESORT)**
 - Only when Tiers 1 & 2 don't apply
 - Must include `dark:` variants
 - Example: `bg-blue-50 dark:bg-blue-900/30`

### Why This Matters

**Hardcoded light-only colors cause:**
- Invisible text/elements in dark mode
- Poor accessibility and contrast
- Frequent dark mode bugs
- Bad user experience
- PR rejections

---

## Badge Variants Library

**Location**: [`lib/ui/badge-variants.ts`](../../../lib/ui/badge-variants.ts)

### Available Variants

#### 1. Status Variants

```typescript
badgeVariants.success // Green (for active, completed, success states)
badgeVariants.error // Red (for errors, failed states)
badgeVariants.warning // Orange (for warnings, attention needed)
badgeVariants.info // Blue (for informational messages)
badgeVariants.neutral // Gray (for neutral/inactive states)
```

**Generated Classes** (example for `success`):
```
bg-green-50 text-green-700 border-green-200
dark:bg-green-900/30 dark:text-green-300 dark:border-green-800
```

#### 2. Frequency/Schedule Variants

```typescript
badgeVariants.status.hourly // Blue
badgeVariants.status.daily // Green
badgeVariants.status.weekly // Purple
badgeVariants.status.monthly // Orange
badgeVariants.status.custom // Gray
```

**Use Case**: Task scheduler, cron jobs, scheduled reports

#### 3. Confidence Score Variants (ROI System)

```typescript
badgeVariants.confidence.high // Green (80%+ confidence)
badgeVariants.confidence.medium // Amber (50-79% confidence)
badgeVariants.confidence.low // Red (<50% confidence)
```

**Use Case**: ROI calculations, data quality indicators

#### 4. Execution Status Variants

```typescript
badgeVariants.execution.completed // Green
badgeVariants.execution.failed // Red
badgeVariants.execution.running // Blue
badgeVariants.execution.pending // Gray
```

**Use Case**: Background jobs, API requests, async operations

---

## Usage Patterns

### Pattern 1: Basic Badge

```tsx
import { Badge } from '@/components/ui/badge';
import { badgeVariants } from '@/lib/ui/badge-variants';

export function StatusIndicator({ status }: { status: 'active' | 'inactive' }) {
 return (
 <Badge className={status === 'active' ? badgeVariants.success: badgeVariants.neutral}>
 {status === 'active' ? 'Active': 'Inactive'}
 </Badge>
 );
}
```

### Pattern 2: Dynamic Variant Selection

```tsx
import { badgeVariants } from '@/lib/ui/badge-variants';

export function ConfidenceScore({ score }: { score: number }) {
 const getVariant = => {
 if (score >= 80) return badgeVariants.confidence.high;
 if (score >= 50) return badgeVariants.confidence.medium;
 return badgeVariants.confidence.low;
 };

 return (
 <Badge className={getVariant}>
 {score}% Confidence
 </Badge>
 );
}
```

### Pattern 3: Type-Safe Variant Getter

```tsx
import { getBadgeVariant } from '@/lib/ui/badge-variants';

export function StatusBadge({ type }: { type: 'success' | 'error' | 'warning' }) {
 return (
 <Badge className={getBadgeVariant(type)}>
 {type.toUpperCase}
 </Badge>
 );
}
```

### Pattern 4: Custom Badge Variant

```tsx
import { createBadgeVariant } from '@/lib/ui/badge-variants';

// Create a custom pink variant
const pinkVariant = createBadgeVariant(
 'bg-pink-50 text-pink-700 border-pink-200',
 'bg-pink-900/30 text-pink-300 border-pink-800'
);

export function CustomBadge {
 return <Badge className={pinkVariant}>Custom</Badge>;
}
```

### Pattern 5: Semantic Color Variables for Text

```tsx
export function ArticleCard {
 return (
 <div className="bg-card text-card-foreground border border-border rounded-lg p-4">
 <h3 className="text-lg font-semibold text-foreground mb-2">
 Article Title
 </h3>
 <p className="text-muted-foreground text-sm mb-4">
 This is a description with automatically adapting colors
 </p>
 <button className="bg-primary text-primary-foreground px-4 py-2 rounded hover:bg-primary/90">
 Read More
 </button>
 </div>
 );
}
```

---

## Common Mistakes

### ❌ WRONG: Hardcoded Light-Only Colors

```tsx
// NEVER do this - invisible in dark mode
<Badge className="bg-green-50 text-green-700">Active</Badge>
<p className="text-gray-500">Helper text</p>
<div className="bg-white text-black">Content</div>
<button className="bg-blue-500 hover:bg-blue-600">Click</button>
```

### ✅ CORRECT: Use Centralized Variants or Semantic Variables

```tsx
// Use badge variants
<Badge className={badgeVariants.success}>Active</Badge>

// Use semantic variables
<p className="text-muted-foreground">Helper text</p>
<div className="bg-background text-foreground">Content</div>
<button className="bg-primary hover:bg-primary/90 text-primary-foreground">Click</button>
```

### ❌ WRONG: Partial Dark Mode Support

```tsx
// Missing border dark variant
<div className="bg-white dark:bg-gray-900 border border-gray-200">
 Content
</div>

// Missing text dark variant
<p className="text-gray-600 dark:bg-gray-800">
 Text color doesn't adapt!
</p>
```

### ✅ CORRECT: Complete Dark Mode Support

```tsx
// All properties have dark variants
<div className="bg-card border border-border text-card-foreground">
 Content
</div>

// Or use manual dark classes for everything
<div className="bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-700 text-gray-900 dark:text-gray-100">
 Content
</div>
```

### ❌ WRONG: Inconsistent Variant Usage

```tsx
// Don't mix approaches for the same type of badge
<Badge className="bg-green-50 text-green-700">Success</Badge>
<Badge className={badgeVariants.success}>Also Success</Badge>
```

### ✅ CORRECT: Consistent Library Usage

```tsx
// Always use the library for badges
<Badge className={badgeVariants.success}>Success</Badge>
<Badge className={badgeVariants.success}>Also Success</Badge>
```

---

## Migration Guide

### Finding Hardcoded Colors

```bash
# Search for common hardcoded patterns
grep -r "text-slate-[0-9]" app/ components/ --include="*.tsx"
grep -r "bg-green-[0-9]" app/ components/ --include="*.tsx"
grep -r "text-gray-[0-9]" app/ components/ --include="*.tsx"
```

### Step-by-Step Migration

1. **Identify the component type**
 - Badge/pill → Use `badgeVariants`
 - Text/background → Use semantic variables
 - Custom styling → Manual dark classes

2. **For Badges: Replace with library**

```tsx
// Before
<Badge className="bg-green-50 text-green-700 border-green-200">
 Active
</Badge>

// After
import { badgeVariants } from '@/lib/ui/badge-variants';

<Badge className={badgeVariants.success}>
 Active
</Badge>
```

3. **For Text/Backgrounds: Use semantic variables**

```tsx
// Before
<p className="text-gray-600">Helper text</p>
<div className="bg-white text-black">Content</div>

// After
<p className="text-muted-foreground">Helper text</p>
<div className="bg-background text-foreground">Content</div>
```

4. **For Custom Styling: Add dark variants**

```tsx
// Before
<div className="bg-blue-50 text-blue-700">
 Custom element
</div>

// After
<div className="bg-blue-50 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300">
 Custom element
</div>
```

### Bulk Migration Script (Python)

```python
#!/usr/bin/env python3
import re
import sys

# Common replacements
REPLACEMENTS = {
 r'className="([^"]*)\bbg-green-50 text-green-700 border-green-200\b([^"]*)?"':
 r'className={\1badgeVariants.success\2}',

 r'className="([^"]*)\btext-slate-700\b([^"]*)?"':
 r'className="\1text-foreground\2"',

 r'className="([^"]*)\btext-gray-600\b([^"]*)?"':
 r'className="\1text-muted-foreground\2"',
}

def migrate_file(filepath):
 with open(filepath, 'r') as f:
 content = f.read

 for pattern, replacement in REPLACEMENTS.items:
 content = re.sub(pattern, replacement, content)

 with open(filepath, 'w') as f:
 f.write(content)

if __name__ == '__main__':
 for filepath in sys.argv[1:]:
 migrate_file(filepath)
 print(f"Migrated: {filepath}")
```

---

## Testing Dark Mode

### Pre-Commit Checklist

**CRITICAL**: Test ALL UI changes in both light AND dark mode before committing.

### Manual Testing

1. **Toggle dark mode** using the theme toggle button
2. **Check all states**:
 - Default state
 - Hover state
 - Active/selected state
 - Disabled state
3. **Verify contrast** (text should be easily readable)
4. **Check borders** (should be visible but not harsh)

### Automated Testing (Playwright)

```typescript
// tests/e2e/dark-mode.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Dark Mode Support', => {
 test('workshop page should support dark mode', async ({ page }) => {
 await page.goto('/workshop');

 // Check light mode
 await expect(page.locator('body')).not.toHaveClass(/dark/);
 const lightBg = await page.locator('.min-h-screen').evaluate(el =>
 getComputedStyle(el).backgroundColor
 );

 // Toggle dark mode
 await page.click('[aria-label="Toggle theme"]');
 await expect(page.locator('body')).toHaveClass(/dark/);

 // Check dark mode
 const darkBg = await page.locator('.min-h-screen').evaluate(el =>
 getComputedStyle(el).backgroundColor
 );

 // Background should be different
 expect(lightBg).not.toBe(darkBg);
 });

 test('badges should adapt to dark mode', async ({ page }) => {
 await page.goto('/settings?tab=monitoring');

 // Get badge in light mode
 const badge = page.locator('.badge').first;
 const lightColor = await badge.evaluate(el =>
 getComputedStyle(el).color
 );

 // Toggle dark mode
 await page.click('[aria-label="Toggle theme"]');

 // Get badge in dark mode
 const darkColor = await badge.evaluate(el =>
 getComputedStyle(el).color
 );

 // Colors should be different
 expect(lightColor).not.toBe(darkColor);
 });
});
```

### Visual Regression Testing

```bash
# Take screenshots in both modes
npm run test:e2e -- --project=chromium --update-snapshots

# Compare screenshots
npm run test:e2e -- --project=chromium
```

---

## Semantic Color Variables Reference

### Background Colors

| Variable | Usage | Example |
|----------|-------|---------|
| `bg-background` | Main page background | `<body className="bg-background">` |
| `bg-card` | Card/panel backgrounds | `<div className="bg-card">` |
| `bg-popover` | Dropdown/popover backgrounds | `<div className="bg-popover">` |
| `bg-primary` | Primary action buttons | `<button className="bg-primary">` |
| `bg-secondary` | Secondary action buttons | `<button className="bg-secondary">` |
| `bg-muted` | Muted/inactive sections | `<div className="bg-muted">` |
| `bg-accent` | Highlight/accent elements | `<div className="bg-accent">` |

### Text Colors

| Variable | Usage | Example |
|----------|-------|---------|
| `text-foreground` | Primary text | `<p className="text-foreground">` |
| `text-muted-foreground` | Secondary/helper text | `<span className="text-muted-foreground">` |
| `text-card-foreground` | Text on cards | `<div className="bg-card text-card-foreground">` |
| `text-primary-foreground` | Text on primary buttons | `<button className="bg-primary text-primary-foreground">` |
| `text-destructive` | Error/destructive text | `<p className="text-destructive">` |

### Border Colors

| Variable | Usage | Example |
|----------|-------|---------|
| `border-border` | Default borders | `<div className="border border-border">` |
| `border-input` | Form input borders | `<input className="border-input">` |
| `border-ring` | Focus rings | `<input className="focus:ring-ring">` |

---

## Enforcement

### Pre-Commit Hook

Add to `.husky/pre-commit`:

```bash
#!/bin/sh
# Check for hardcoded light-only colors

HARDCODED_COLORS=$(git diff --cached --name-only | grep -E '\.(tsx|jsx)$' | xargs grep -l "text-slate-[0-9]\|bg-green-[0-9]\|text-gray-[0-9]" || true)

if [ -n "$HARDCODED_COLORS" ]; then
 echo "❌ ERROR: Hardcoded light-only colors found:"
 echo "$HARDCODED_COLORS"
 echo ""
 echo "Please use:"
 echo " - badgeVariants from @/lib/ui/badge-variants for badges"
 echo " - Semantic variables (bg-background, text-foreground, etc.) for text/backgrounds"
 echo " - Manual dark: classes for custom styling"
 echo ""
 echo "See: docs/kb/ui/DEVELOPER-REFERENCE-BADGE-VARIANTS.md"
 exit 1
fi
```

### ESLint Plugin (Future)

```javascript
//.eslintrc.js
module.exports = {
 rules: {
 'no-hardcoded-colors': 'error',
 'require-dark-variants': 'warn',
 }
};
```

---

## Additional Resources

- **Main Documentation**: [`docs/kb/ui/DARK-MODE-STANDARDS.md`](DARK-MODE-STANDARDS.md)
- **Badge Variants Source**: [`lib/ui/badge-variants.ts`](../../../lib/ui/badge-variants.ts)
- **Tailwind Config**: [`tailwind.config.ts`](../../../tailwind.config.ts)
- **Architecture Decision**: [`docs/ARCHITECTURE.md`](../../ARCHITECTURE.md) (search for "Dark Mode")

---

## Summary

**Golden Rules:**

1. **ALWAYS use `badgeVariants`** for badges/pills
2. **PREFER semantic variables** (`bg-background`, `text-foreground`, etc.)
3. **NEVER hardcode light-only colors** without `dark:` variants
4. **TEST in both modes** before committing
5. **Be consistent** - same pattern for same use case

**If in doubt**: Use semantic variables first, badge variants second, manual dark classes last.

---

**Questions or need help?** Check `docs/kb/ui/DARK-MODE-STANDARDS.md` or ask in #frontend channel.
