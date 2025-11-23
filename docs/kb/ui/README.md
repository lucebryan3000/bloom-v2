---
id: ui-readme
topic: ui
file_role: overview
profile: full
difficulty_level: all-levels
kb_version: 3.1
prerequisites: []
related_topics: [react, tailwind, design-systems, accessibility]
embedding_keywords: [ui, styling, dark-mode, components, design-system, tailwind, css]
last_reviewed: 2025-11-13
---

# UI/Styling Knowledge Base

**Purpose**: Comprehensive guide to UI development, styling patterns, dark mode support, and design system usage

**Scope**: Tailwind CSS, shadcn/ui, dark mode standards, badge variants, component styling, accessibility

**Target Audience**: Frontend developers, UI engineers, designers implementing designs in code

---

## 📚 Documentation Structure

This knowledge base contains the following files:

| File | Purpose | Lines | When to Use |
|------|---------|-------|-------------|
| **[README.md](./README.md)** | This file - overview and navigation | ~250 | Start here for orientation |
| **[INDEX.md](./INDEX.md)** | Complete navigation and search | ~200 | Finding specific topics quickly |
| **[QUICK-REFERENCE.md](./QUICK-REFERENCE.md)** | Copy-paste snippets and commands | ~300 | Quick lookups during development |
| **[FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md)** | Framework integration examples | ~400 | Integrating UI with React/Next.js |
| **[DARK-MODE-STANDARDS.md](./DARK-MODE-STANDARDS.md)** | Dark mode implementation guide | ~350 | Implementing dark mode support |
| **[DEVELOPER-REFERENCE-BADGE-VARIANTS.md](./DEVELOPER-REFERENCE-BADGE-VARIANTS.md)** | Badge variant reference | ~300 | Using status badges and indicators |
| **[DARK-MODE-AUDIT-2025-11-09.md](./DARK-MODE-AUDIT-2025-11-09.md)** | Dark mode audit report | ~250 | Understanding dark mode issues |

**Total Lines**: ~2,050 lines

---

## 🎯 What This KB Covers

### Core Topics

1. **Dark Mode Standards**
   - Three-tier color system (CSS variables, badge variants, manual classes)
   - Semantic color tokens (`bg-background`, `text-foreground`)
   - Common dark mode pitfalls and solutions

2. **Design System Components**
   - shadcn/ui component usage
   - Badge variants for status indicators
   - Consistent styling patterns

3. **Tailwind CSS Patterns**
   - Utility-first styling
   - Responsive design
   - Dark mode with `dark:` modifier

4. **Accessibility**
   - Color contrast requirements (WCAG 2.1 AA)
   - Screen reader support
   - Keyboard navigation

5. **Component Styling**
   - Reusable component patterns
   - Styling props and variants
   - Theme integration

---

## 🚀 Quick Start

### For New Developers

1. **Understand dark mode requirements**
   - Read: [DARK-MODE-STANDARDS.md](./DARK-MODE-STANDARDS.md)
   - Key rule: **ALWAYS use dark mode-aware colors**

2. **Learn the three-tier system**
   ```tsx
   // Tier 1: Semantic CSS variables (PREFERRED)
   <div className="bg-background text-foreground">

   // Tier 2: Centralized badge variants
   <Badge className={badgeVariants.success}>Active</Badge>

   // Tier 3: Manual dark classes (last resort)
   <div className="bg-blue-50 dark:bg-blue-900/30">
   ```

3. **Use the quick reference**
   - Check: [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) for copy-paste snippets

### For Experienced Developers

1. **Reference patterns**
   - [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md) for framework-specific examples

2. **Check badge variants**
   - [DEVELOPER-REFERENCE-BADGE-VARIANTS.md](./DEVELOPER-REFERENCE-BADGE-VARIANTS.md) for status indicators

3. **Review standards**
   - [DARK-MODE-STANDARDS.md](./DARK-MODE-STANDARDS.md) before implementing new components

---

## 🎨 Design System Overview

### Color System

**Semantic Variables** (from `app/globals.css`):
```css
/* Layout */
--background: /* Page background */
--foreground: /* Default text color */

/* Components */
--card: /* Card background */
--card-foreground: /* Card text */
--popover: /* Popover background */
--popover-foreground: /* Popover text */

/* UI Elements */
--primary: /* Primary buttons, links */
--primary-foreground: /* Text on primary elements */
--secondary: /* Secondary elements */
--secondary-foreground: /* Text on secondary */
--muted: /* Muted backgrounds */
--muted-foreground: /* Helper text */
--accent: /* Accent highlights */
--accent-foreground: /* Text on accents */

/* Feedback */
--destructive: /* Error states */
--destructive-foreground: /* Error text */
```

### Typography

**Font Stack**:
- Headings: Inter, sans-serif
- Body: Inter, sans-serif
- Monospace: JetBrains Mono, monospace

**Size Scale**:
- `text-xs` - 0.75rem (12px)
- `text-sm` - 0.875rem (14px)
- `text-base` - 1rem (16px)
- `text-lg` - 1.125rem (18px)
- `text-xl` - 1.25rem (20px)
- `text-2xl` - 1.5rem (24px)

### Spacing

**Base Unit**: 4px (0.25rem)

**Common Spacing**:
- `space-y-2` - 8px vertical spacing
- `space-y-4` - 16px vertical spacing
- `space-y-6` - 24px vertical spacing
- `gap-4` - 16px gap in flex/grid
- `p-4` - 16px padding
- `m-4` - 16px margin

---

## 📋 Common Tasks

### 1. Implementing Dark Mode Support

**Problem**: Component has invisible text in dark mode

**Solution**:
1. Use semantic CSS variables:
   ```tsx
   <div className="bg-card text-card-foreground">
     <p className="text-muted-foreground">Helper text</p>
   </div>
   ```

2. For badges, use centralized variants:
   ```tsx
   import { badgeVariants } from '@/lib/ui/badge-variants';
   <Badge className={badgeVariants.success}>Active</Badge>
   ```

3. For custom colors, add dark mode variants:
   ```tsx
   <div className="bg-blue-50 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300">
   ```

**See**: [DARK-MODE-STANDARDS.md](./DARK-MODE-STANDARDS.md) for complete guide

### 2. Using Status Badges

**Problem**: Need to show status with proper colors

**Solution**:
```tsx
import { badgeVariants } from '@/lib/ui/badge-variants';

<Badge className={badgeVariants.success}>Active</Badge>
<Badge className={badgeVariants.warning}>Pending</Badge>
<Badge className={badgeVariants.error}>Failed</Badge>
<Badge className={badgeVariants.info}>Info</Badge>
```

**See**: [DEVELOPER-REFERENCE-BADGE-VARIANTS.md](./DEVELOPER-REFERENCE-BADGE-VARIANTS.md)

### 3. Creating Responsive Layouts

**Solution**:
```tsx
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
  {/* Responsive grid: 1 col mobile, 2 cols tablet, 3 cols desktop */}
</div>

<div className="flex flex-col md:flex-row gap-4">
  {/* Responsive flex: column on mobile, row on desktop */}
</div>
```

### 4. Accessibility Considerations

**Key Requirements**:
- ✅ Color contrast >= 4.5:1 for normal text
- ✅ Color contrast >= 3:1 for large text
- ✅ Keyboard navigation support
- ✅ Screen reader labels
- ✅ Focus indicators

**Example**:
```tsx
<button
  className="focus:ring-2 focus:ring-primary focus:outline-none"
  aria-label="Close dialog"
>
  <X className="h-4 w-4" />
</button>
```

---

## 🔍 Finding Information

### By Task

| What You Need | Where to Look | File |
|---------------|---------------|------|
| Dark mode colors | Tier 1-3 system | DARK-MODE-STANDARDS.md |
| Status badges | Badge variants library | DEVELOPER-REFERENCE-BADGE-VARIANTS.md |
| Quick snippets | Copy-paste examples | QUICK-REFERENCE.md |
| React patterns | Component integration | FRAMEWORK-INTEGRATION-PATTERNS.md |
| Navigation | File map and search | INDEX.md |

### By Difficulty

- **Beginners**: Start with DARK-MODE-STANDARDS.md and QUICK-REFERENCE.md
- **Intermediate**: Review FRAMEWORK-INTEGRATION-PATTERNS.md
- **Advanced**: Study DEVELOPER-REFERENCE-BADGE-VARIANTS.md and custom implementations

---

## ⚠️ Critical Rules

### ALWAYS

✅ **Use dark mode-aware colors** in all components
✅ **Test in both light AND dark mode** before committing
✅ **Use semantic CSS variables** as first choice
✅ **Check accessibility contrast** (4.5:1 minimum)
✅ **Use centralized badge variants** for status indicators

### NEVER

❌ **Hardcode light-only colors** (`bg-gray-50` without `dark:` variant)
❌ **Skip dark mode testing**
❌ **Use inline styles** for colors (use Tailwind classes)
❌ **Create custom badge styles** (use `badgeVariants`)
❌ **Ignore accessibility requirements**

---

## 🎓 Learning Paths

### Path 1: UI Fundamentals (Beginners)
1. Read DARK-MODE-STANDARDS.md (understand the three-tier system)
2. Practice with QUICK-REFERENCE.md examples
3. Review DEVELOPER-REFERENCE-BADGE-VARIANTS.md

### Path 2: Component Development (Intermediate)
1. Study FRAMEWORK-INTEGRATION-PATTERNS.md
2. Implement components with dark mode support
3. Use INDEX.md for quick navigation

### Path 3: Design System Mastery (Advanced)
1. Review all standards documents
2. Understand semantic color system deeply
3. Create new reusable patterns

---

## 🛠️ Tools & Resources

### Internal Tools
- **`lib/ui/badge-variants.ts`** - Centralized badge variants
- **`app/globals.css`** - Semantic CSS variables
- **`tailwind.config.ts`** - Tailwind configuration

### External Resources
- [Tailwind CSS Documentation](https://tailwindcss.com/docs)
- [shadcn/ui Components](https://ui.shadcn.com/)
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)

---

## 📊 KB Statistics

- **Total Files**: 7
- **Total Lines**: ~2,050
- **Core Files**: 4 (README, INDEX, QUICK-REFERENCE, FRAMEWORK-INTEGRATION-PATTERNS)
- **Specialized Files**: 3 (Dark mode standards, badge reference, audit report)
- **Last Updated**: 2025-11-13

---

## 🤝 Contributing

When adding UI documentation:
1. Follow KB v3.1 standards (front-matter required)
2. Make content technology-agnostic (reusable patterns)
3. Include code examples with ✅/❌ indicators
4. Test all examples in both light and dark mode
5. Update this README when adding new files

---

## 📖 Related Knowledge Bases

- **[React KB](../react/)** - React component patterns
- **[TypeScript KB](../typescript/)** - Type safety for components
- **[Next.js KB](../nextjs/)** - Next.js-specific UI patterns
- **[Testing KB](../testing/)** - UI component testing
- **Accessibility KB (not yet created)** - Accessibility guidelines (if exists)

---

**Next Steps**: Start with [INDEX.md](./INDEX.md) for complete navigation, or [DARK-MODE-STANDARDS.md](./DARK-MODE-STANDARDS.md) to understand the color system.
