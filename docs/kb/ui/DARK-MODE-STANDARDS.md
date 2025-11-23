---
id: ui-dark-mode-standards
topic: ui
file_role: documentation
profile: full
difficulty_level: beginner
kb_version: 4.0
prerequisites: []
related_topics: ['ui', 'tailwind']
embedding_keywords: [ui, dark mode, styling]
last_reviewed: 2025-11-15
---

# Dark Mode Implementation Guide

**Author**: Claude (UI Standards)
**Updated**: 2025-11-15
**Status**: Active Standard
**Applies To**: All UI components, pages, and styling

---

## Quick Summary

Bloom uses **two complementary systems** for dark mode:

1. **CSS Variables** (automatic, 99% of use cases)
2. **Explicit `dark:` classes** (fine-tuned, specific cases)

Both work together seamlessly. You rarely need to think about it—just follow the patterns below.

---

## System Architecture

### How It Works

**Tailwind Configuration** (`tailwind.config.ts`):
```typescript
darkMode: ["class"]  // Enables class-based dark mode
```

**CSS Variables** (`app/globals.css`):
```css
/* Light mode (default) */
:root {
  --background: 0 0% 100%;      /* White */
  --foreground: 222.2 84% 4.9%;  /* Dark blue-gray */
  --card: 0 0% 100%;             /* White */
  --muted: 210 40% 96.1%;        /* Light gray */
}

/* Dark mode (when .dark class added to html) */
.dark {
  --background: 222.2 84% 4.9%;  /* Dark blue-gray */
  --foreground: 210 40% 98%;     /* Off-white */
  --card: 222.2 84% 4.9%;        /* Dark blue-gray */
  --muted: 217.2 32.6% 17.5%;    /* Medium gray */
}
```

**Result**: Colors automatically switch based on system preference or user setting.

---

## Pattern 1: Semantic CSS Variables (Primary Approach - 99%)

Use for core UI elements. Colors automatically adapt to light/dark mode.

### Core Semantic Colors

```tsx
// Background and foreground
<div className="bg-background text-foreground">
  <Card className="bg-card text-card-foreground">
    <p className="text-muted-foreground">Muted text</p>
  </Card>
</div>

// Borders and inputs
<input className="border-border bg-input" />
<div className="ring-ring" />

// Interactive states
<Button variant="outline" />        {/* Uses semantic colors */}
<Button variant="secondary" />      {/* Uses semantic colors */}
<Button variant="destructive" />    {/* Uses semantic colors */}
```

### When to Use

✅ **Use semantic variables for:**
- Page/section backgrounds
- Card backgrounds
- Text color for body content
- Borders and outlines
- Input fields
- Muted/secondary text
- Default button states

### Available Variables

```css
/* Structure */
--background, --foreground        /* Main page colors */
--card, --card-foreground         /* Card/container colors */
--popover, --popover-foreground   /* Popover/dropdown colors */

/* Interactive */
--primary, --primary-foreground   /* Primary actions */
--secondary, --secondary-foreground
--muted, --muted-foreground       /* Disabled/secondary text */
--accent, --accent-foreground     /* Accent colors */
--destructive, --destructive-foreground

/* Specialized */
--border, --input, --ring
--bloom-primary, --bloom-secondary, --bloom-accent
--confidence-high, --confidence-medium, --confidence-low
```

---

## Pattern 2: Explicit `dark:` Classes (Secondary - 1%)

Use when you need specific colors that don't have semantic variables.

### Color Pairing Pattern

Always pair light + dark:

```tsx
// ✅ CORRECT - Light and dark pair
<div className="bg-blue-50 dark:bg-blue-900/30">
<p className="text-blue-700 dark:text-blue-300">

// ✅ CORRECT - With hover states
<button className="bg-gray-50 dark:bg-gray-900 hover:bg-gray-100 dark:hover:bg-gray-800">

// ✅ CORRECT - Border colors
<div className="border border-gray-200 dark:border-gray-700">

// ✅ CORRECT - Icons
<Icon className="text-green-600 dark:text-green-400" />
```

### When to Use

✅ **Use explicit `dark:` classes for:**
- Brand/status colors (blue, green, amber, red)
- Hover and active states
- Borders with specific colors
- Icons that use specific colors
- Background colors for info/warning/error boxes
- Complex color combinations

### Color Mapping Guide

```typescript
// Light color → Dark equivalent mapping
text-gray-500     → dark:text-gray-400   // Slightly lighter in dark
text-gray-700     → dark:text-gray-300   // Significantly lighter
bg-gray-50        → dark:bg-gray-900/20  // Subtle dark background
bg-gray-100       → dark:bg-gray-800/30  // More prominent
bg-blue-50        → dark:bg-blue-900/30  // Brand color subtle
text-blue-600     → dark:text-blue-400   // Brand color bright

// Status colors
text-green-600    → dark:text-green-400
text-amber-600    → dark:text-amber-400
text-red-600      → dark:text-red-400
```

---

## Real-World Examples

### Example 1: Simple Card

```tsx
// ✅ CORRECT - Uses semantic variables
<div className="bg-card p-4 rounded-lg border border-border">
  <h3 className="text-foreground font-semibold">Title</h3>
  <p className="text-muted-foreground">Description</p>
</div>
```

### Example 2: Status Badge with Explicit Colors

```tsx
// ✅ CORRECT - Semantic base + explicit colors for status
<div className="flex items-center gap-2 px-3 py-1 rounded-full bg-green-50 dark:bg-green-900/20">
  <CheckCircle className="w-4 h-4 text-green-600 dark:text-green-400" />
  <span className="text-green-700 dark:text-green-300 text-sm font-medium">
    Active
  </span>
</div>
```

### Example 3: Interactive Form

```tsx
// ✅ CORRECT - Mix of semantic and explicit
<div className="space-y-4">
  <div>
    <label className="text-foreground font-medium">Name</label>
    <input
      className="w-full px-3 py-2 border border-border bg-input rounded-md text-foreground"
    />
  </div>

  <button className="px-4 py-2 bg-blue-600 dark:bg-blue-700 text-white rounded-md hover:bg-blue-700 dark:hover:bg-blue-800">
    Submit
  </button>
</div>
```

---

## Anti-Patterns (Don't Do This)

```tsx
// ❌ WRONG - No dark mode support
<div className="bg-gray-50">Text will be invisible in dark mode</div>
<p className="text-gray-500">Gray text, hard to read in dark</p>
<button className="bg-blue-50 text-blue-700">Light text on light background</button>

// ❌ WRONG - Incomplete dark: pair
<div className="bg-gray-50 dark:bg-gray-900">Missing text color dark pair</div>
<p className="text-gray-700">Missing dark: text color</p>

// ❌ WRONG - Hardcoded colors
<div style={{ backgroundColor: '#f3f4f6' }}>Can't toggle dark mode with inline styles</div>
```

---

## Testing Your Dark Mode

### Quick Visual Test

1. Open your component in the browser
2. Open DevTools → Toggle device theme
3. Or toggle dark mode in browser Settings

### In Code

```typescript
// Browser DevTools Console
document.documentElement.classList.toggle('dark')

// Or in app, use your theme toggle
```

### Accessibility Check

- Text should have sufficient contrast in both modes
- Use tools like WebAIM contrast checker
- Axe DevTools browser extension

---

## Migration Path (Old → New Code)

If you find old hardcoded colors:

```tsx
// OLD CODE (❌ Wrong)
<div className="bg-gray-100 text-gray-700 border border-gray-200">

// NEW CODE (✅ Correct)
<div className="bg-muted text-foreground border border-border">
```

---

## Troubleshooting

### "Text is invisible in dark mode"

1. Check if you used a light-only color (e.g., `text-gray-600`)
2. Add the `dark:` equivalent (e.g., `dark:text-gray-400`)
3. Or use semantic variable (e.g., `text-foreground` or `text-muted-foreground`)

### "Colors look wrong in dark mode"

1. Check CSS variables are defined in `app/globals.css`
2. Verify `.dark` class is being applied to `html` element
3. Use DevTools to inspect computed colors

### "I'm not sure what color to use"

1. **For backgrounds/text**: Use semantic variable (priority!)
2. **For status/brand colors**: Check `app/globals.css` for `--confidence-*` or `--bloom-*`
3. **For specific colors**: Use `dark:` pair with light color

---

## Summary

| Situation | Use This | Example |
|-----------|----------|---------|
| Background/foreground | Semantic variable | `bg-background text-foreground` |
| Card content | Semantic variable | `bg-card text-card-foreground` |
| Muted/secondary | Semantic variable | `text-muted-foreground` |
| Status badge | Explicit `dark:` pair | `bg-green-50 dark:bg-green-900/20` |
| Icon color | Explicit `dark:` pair | `text-blue-600 dark:text-blue-400` |
| Brand colors | Explicit `dark:` pair | `text-bloom-primary dark:text-bloom-accent` |
| Hover states | Explicit `dark:` pair | `hover:bg-gray-100 dark:hover:bg-gray-800` |

---

## Further Reading

- [Tailwind Dark Mode Docs](https://tailwindcss.com/docs/dark-mode)
- `tailwind.config.ts` - Dark mode configuration
- `app/globals.css` - CSS variable definitions
- CLAUDE.md → Dark Mode & Styling Standards section

