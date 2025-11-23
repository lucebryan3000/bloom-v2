---
id: tailwind-index
topic: tailwind
file_role: navigation
profile: full
difficulty_level: beginner
kb_version: 3.1
prerequisites: []
related_topics: []
embedding_keywords: [tailwind, index, navigation, contents, table-of-contents]
last_reviewed: 2025-11-16
---

# Tailwind CSS - Complete Index

**Complete navigation hub for the Tailwind CSS knowledge base with problem-based quick find and learning paths.**

## Quick Navigation

| Section | Description | Jump To |
|---------|-------------|---------|
| 📚 **Learning Paths** | Structured learning by experience level | [→](#learning-paths) |
| 🎯 **Problem-Based Quick Find** | "I want to..." navigation | [→](#problem-based-quick-find-i-want-to) |
| 📖 **Complete File Breakdown** | All files with descriptions | [→](#complete-file-breakdown) |
| 🔍 **Syntax Quick Lookup** | Find utilities by category | [→](#syntax-quick-lookup) |
| ❓ **Common Questions** | FAQ and troubleshooting | [→](#common-questions) |

---

## Learning Paths

### 🟢 Beginner (2-4 hours)

**If you've never used Tailwind CSS, start here.**

1. [**01-FUNDAMENTALS.md**](./01-FUNDAMENTALS.md) - Core concepts (30 min)
   - What is utility-first CSS
   - Installation (Next.js, Vite, React)
   - Basic syntax: `bg-blue-500`, `p-4`, `text-lg`
   - Your first component (card example)

2. [**02-UTILITY-CLASSES.md**](./02-UTILITY-CLASSES.md) - Essential utilities (45 min)
   - Spacing: `p-4`, `m-2`, `space-x-4`
   - Typography: `text-xl`, `font-bold`, `tracking-wide`
   - Colors: `bg-blue-500`, `text-gray-900`
   - Layout: Flexbox and Grid basics

3. [**03-RESPONSIVE-DESIGN.md**](./03-RESPONSIVE-DESIGN.md) - Mobile-first (30 min)
   - Breakpoints: `sm:`, `md:`, `lg:`, `xl:`, `2xl:`
   - Responsive utilities: `md:flex`, `lg:grid-cols-3`
   - Mobile-first workflow

**Practice**: Build a landing page (hero, features, footer)

### 🟡 Intermediate (4-8 hours)

**Prerequisites: Complete beginner path**

4. [**04-CUSTOMIZATION.md**](./04-CUSTOMIZATION.md) - Customize Tailwind (1 hour)
   - `tailwind.config.js` structure
   - Extend colors, spacing, fonts
   - Create custom utilities

5. [**05-LAYOUT-PATTERNS.md**](./05-LAYOUT-PATTERNS.md) - UI patterns (1 hour)
   - Hero sections, cards, navigation bars
   - Sidebars, footers, dashboards
   - Common layouts

6. [**06-DARK-MODE.md**](./06-DARK-MODE.md) - Dark mode (45 min)
   - Class vs media query strategy
   - `dark:` variant usage
   - Manual toggle implementation

7. [**07-FORMS.md**](./07-FORMS.md) - Form styling (1 hour)
   - Input fields, selects, checkboxes
   - Validation states (error, success)
   - `@tailwindcss/forms` plugin

**Practice**: Build a dashboard with auth forms and dark mode

### 🔴 Advanced (8-12 hours)

**Prerequisites: Complete intermediate path**

8. [**08-ANIMATIONS.md**](./08-ANIMATIONS.md) - Animations (1 hour)
   - Transitions: `transition`, `duration-300`
   - Transforms: `scale-110`, `rotate-45`
   - Custom keyframe animations
   - Loading states

9. [**09-TYPOGRAPHY.md**](./09-TYPOGRAPHY.md) - Typography (1 hour)
   - Font families, sizes, weights
   - `@tailwindcss/typography` plugin
   - Prose classes: `prose`, `prose-lg`

10. [**10-INTEGRATIONS.md**](./10-INTEGRATIONS.md) - Frameworks (1.5 hours)
    - Next.js 13+ App Router
    - React, Vue, Svelte
    - Vite and webpack config

11. [**11-CONFIG-OPERATIONS.md**](./11-CONFIG-OPERATIONS.md) - Production (1.5 hours)
    - Production optimization
    - VS Code setup and IntelliSense
    - Debugging and troubleshooting

**Practice**: Build a full-stack app with optimal production build

---

## Problem-Based Quick Find ("I want to...")

### Getting Started

**"How do I install Tailwind?"**
→ [01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md) → Installation → Option 1: Framework Integration

**"What is utility-first CSS?"**
→ [01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md) → Core Philosophy: Utility-First

**"How do I create my first component?"**
→ [01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md) → Your First Example

**"How do I set up VS Code?"**
→ [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) → VS Code Setup

---

### Layout & Spacing

**"How do I center elements?"**
→ [02-UTILITY-CLASSES.md](./02-UTILITY-CLASSES.md) → Layout → Flexbox (`flex justify-center items-center`)

**"How do I create a grid layout?"**
→ [02-UTILITY-CLASSES.md](./02-UTILITY-CLASSES.md) → Layout → Grid (`grid grid-cols-3 gap-4`)

**"How do I add padding/margin?"**
→ [02-UTILITY-CLASSES.md](./02-UTILITY-CLASSES.md) → Spacing (`p-4`, `m-2`, `mx-auto`)

**"How do I build a hero section?"**
→ [05-LAYOUT-PATTERNS.md](./05-LAYOUT-PATTERNS.md) → Hero Sections

**"How do I create a card grid?"**
→ [05-LAYOUT-PATTERNS.md](./05-LAYOUT-PATTERNS.md) → Card Patterns → Simple Card Grid

**"How do I build a navigation bar?"**
→ [05-LAYOUT-PATTERNS.md](./05-LAYOUT-PATTERNS.md) → Navigation Patterns → Desktop Navigation Bar

**"How do I create a sidebar?"**
→ [05-LAYOUT-PATTERNS.md](./05-LAYOUT-PATTERNS.md) → Sidebar Layouts

**"How do I build a footer?"**
→ [05-LAYOUT-PATTERNS.md](./05-LAYOUT-PATTERNS.md) → Footer Patterns

---

### Responsive Design

**"How do I make my design responsive?"**
→ [03-RESPONSIVE-DESIGN.md](./03-RESPONSIVE-DESIGN.md) → Basic Responsive Design

**"What are the breakpoints?"**
→ [03-RESPONSIVE-DESIGN.md](./03-RESPONSIVE-DESIGN.md) → Breakpoint System

**"How do I hide/show elements on mobile?"**
→ [03-RESPONSIVE-DESIGN.md](./03-RESPONSIVE-DESIGN.md) → Display Utilities

**"How do I change layout on different screens?"**
→ [03-RESPONSIVE-DESIGN.md](./03-RESPONSIVE-DESIGN.md) → Responsive Flexbox/Grid

---

### Colors & Styling

**"How do I change background color?"**
→ [02-UTILITY-CLASSES.md](./02-UTILITY-CLASSES.md) → Colors → Background (`bg-blue-500`)

**"How do I change text color?"**
→ [02-UTILITY-CLASSES.md](./02-UTILITY-CLASSES.md) → Colors → Text (`text-gray-900`)

**"How do I add custom colors?"**
→ [04-CUSTOMIZATION.md](./04-CUSTOMIZATION.md) → Theme Customization → Extending Colors

**"How do I add borders?"**
→ [02-UTILITY-CLASSES.md](./02-UTILITY-CLASSES.md) → Borders and Shadows

**"How do I add rounded corners?"**
→ [02-UTILITY-CLASSES.md](./02-UTILITY-CLASSES.md) → Borders and Shadows (`rounded-lg`)

**"How do I add shadows?"**
→ [02-UTILITY-CLASSES.md](./02-UTILITY-CLASSES.md) → Borders and Shadows (`shadow-md`)

---

### Dark Mode

**"How do I implement dark mode?"**
→ [06-DARK-MODE.md](./06-DARK-MODE.md) → Configuration → Class Strategy

**"How do I create a dark mode toggle?"**
→ [06-DARK-MODE.md](./06-DARK-MODE.md) → Manual Dark Mode Toggle

**"How do I style elements for dark mode?"**
→ [06-DARK-MODE.md](./06-DARK-MODE.md) → Basic Dark Mode Styling

---

### Typography

**"How do I change font size?"**
→ [02-UTILITY-CLASSES.md](./02-UTILITY-CLASSES.md) → Typography → Font Sizes (`text-xl`, `text-2xl`)

**"How do I make text bold?"**
→ [02-UTILITY-CLASSES.md](./02-UTILITY-CLASSES.md) → Typography → Font Weight (`font-bold`)

**"How do I change font family?"**
→ [09-TYPOGRAPHY.md](./09-TYPOGRAPHY.md) → Font Families

**"How do I add custom fonts?"**
→ [09-TYPOGRAPHY.md](./09-TYPOGRAPHY.md) → Font Families → Custom Font Families

**"How do I style markdown content?"**
→ [09-TYPOGRAPHY.md](./09-TYPOGRAPHY.md) → @tailwindcss/typography Plugin → Basic Prose

---

### Forms

**"How do I style form inputs?"**
→ [07-FORMS.md](./07-FORMS.md) → Text Inputs → Basic Text Input

**"How do I show validation errors?"**
→ [07-FORMS.md](./07-FORMS.md) → Validation States → Error State

**"How do I style checkboxes?"**
→ [07-FORMS.md](./07-FORMS.md) → Checkboxes

**"How do I create a login form?"**
→ [07-FORMS.md](./07-FORMS.md) → Complete Form Examples → Login Form

---

### Animations

**"How do I add transitions?"**
→ [08-ANIMATIONS.md](./08-ANIMATIONS.md) → Transitions → Basic Transition

**"How do I add hover effects?"**
→ [08-ANIMATIONS.md](./08-ANIMATIONS.md) → Hover Effects

**"How do I create loading spinners?"**
→ [08-ANIMATIONS.md](./08-ANIMATIONS.md) → Loading States → Spinner Variations

**"How do I create skeleton loaders?"**
→ [08-ANIMATIONS.md](./08-ANIMATIONS.md) → Loading States → Skeleton Loaders

**"How do I create custom animations?"**
→ [08-ANIMATIONS.md](./08-ANIMATIONS.md) → Custom Animations → Keyframe Animations

---

### Customization

**"How do I customize the config file?"**
→ [04-CUSTOMIZATION.md](./04-CUSTOMIZATION.md) → Configuration File

**"How do I extend the theme?"**
→ [04-CUSTOMIZATION.md](./04-CUSTOMIZATION.md) → Theme Customization

**"How do I create custom utilities?"**
→ [04-CUSTOMIZATION.md](./04-CUSTOMIZATION.md) → Custom Utilities

**"How do I use plugins?"**
→ [04-CUSTOMIZATION.md](./04-CUSTOMIZATION.md) → Plugins

---

### Framework Integration

**"How do I use Tailwind with Next.js?"**
→ [10-INTEGRATIONS.md](./10-INTEGRATIONS.md) → Next.js Integration

**"How do I use Tailwind with React?"**
→ [10-INTEGRATIONS.md](./10-INTEGRATIONS.md) → React Integration

**"How do I use Tailwind with Vite?"**
→ [10-INTEGRATIONS.md](./10-INTEGRATIONS.md) → Vite Integration

**"How do I use Tailwind with Vue?"**
→ [10-INTEGRATIONS.md](./10-INTEGRATIONS.md) → Vue Integration

---

### Production & Optimization

**"How do I optimize for production?"**
→ [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) → Production Configuration

**"Why aren't my classes generating?"**
→ [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) → Troubleshooting → Classes Not Generating

**"How do I reduce bundle size?"**
→ [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) → Performance Optimization

**"How do I debug Tailwind?"**
→ [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) → Debugging Tools

---

## Complete File Breakdown

### Core Navigation Files

**[README.md](./README.md)** (595 lines)
- Overview of Tailwind CSS
- Comparison with other frameworks
- Learning paths (beginner/intermediate/advanced)
- File breakdown with time estimates
- Quick start guide
- Common use cases and FAQ

**[INDEX.md](./INDEX.md)** (this file) (540 lines)
- Complete navigation hub
- Problem-based quick find
- Learning paths
- Syntax quick lookup

**[QUICK-REFERENCE.md](./QUICK-REFERENCE.md)** (900 lines)
- Cheat sheet for all utilities
- Quick syntax lookups
- Common patterns
- Copy-paste examples

**[FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md)** (950 lines)
- Advanced framework patterns
- Component composition
- State management integration
- Performance optimization

---

### Content Files (01-11)

**[01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md)** (645 lines) - Beginner
- What is Tailwind CSS and why use it
- Core philosophy: utility-first
- Installation (Next.js, Vite, React, CLI, CDN)
- How Tailwind works (build process)
- Basic syntax and naming conventions
- Your first example (card component)
- Development workflow
- Common misconceptions
- Best practices for beginners

**[02-UTILITY-CLASSES.md](./02-UTILITY-CLASSES.md)** (680 lines) - Beginner
- Spacing: padding, margin, space-between
- Typography: font size, weight, color
- Colors: background, text, borders
- Layout: flexbox, grid, display, position
- Borders and shadows
- Width and height
- Common utility patterns

**[03-RESPONSIVE-DESIGN.md](./03-RESPONSIVE-DESIGN.md)** (600 lines) - Beginner
- Breakpoint system: sm, md, lg, xl, 2xl
- Mobile-first approach
- Responsive utilities: display, flexbox, grid
- Responsive typography and spacing
- Common responsive patterns
- Testing responsive designs

**[04-CUSTOMIZATION.md](./04-CUSTOMIZATION.md)** (735 lines) - Intermediate
- Configuration file structure
- Content configuration
- Theme customization: colors, spacing, fonts, breakpoints
- Custom utilities with `@layer`
- Custom components
- Plugins: official and custom
- CSS variables integration
- Production optimization

**[05-LAYOUT-PATTERNS.md](./05-LAYOUT-PATTERNS.md)** (810 lines) - Intermediate
- Hero sections: centered, split, full-screen
- Card patterns: simple grid, feature cards, pricing cards
- Navigation patterns: navbar, sidebar
- Footer patterns: simple, multi-column
- Dashboard layouts: stats, charts
- Complete component examples

**[06-DARK-MODE.md](./06-DARK-MODE.md)** (690 lines) - Intermediate
- Configuration: class vs media strategy
- Basic dark mode styling
- Complete component examples: cards, navigation, buttons, forms
- Manual dark mode toggle: React, Vanilla JS, Next.js
- CSS variables approach
- Image handling in dark mode
- Best practices and testing

**[07-FORMS.md](./07-FORMS.md)** (725 lines) - Intermediate
- `@tailwindcss/forms` plugin
- Text inputs: basic, with labels, with icons
- Validation states: error, success, warning
- Textareas, select dropdowns
- Checkboxes and radio buttons
- File uploads
- Complete form examples: login, contact

**[08-ANIMATIONS.md](./08-ANIMATIONS.md)** (600 lines) - Advanced
- Transitions: properties, duration, timing, delay
- Transforms: scale, rotate, translate, skew
- Built-in animations: spin, ping, pulse, bounce
- Custom keyframe animations
- Loading states: spinners, skeleton loaders, progress bars
- Hover effects: cards, buttons, images
- Performance considerations

**[09-TYPOGRAPHY.md](./09-TYPOGRAPHY.md)** (775 lines) - Advanced
- Font families: default and custom
- Google Fonts integration
- Font sizes: xs to 9xl
- Font weights: thin to black
- Font styles: italic, not-italic
- Line height and letter spacing
- Text alignment, decoration, transform
- `@tailwindcss/typography` plugin: prose classes, sizes, colors, dark mode

**[10-INTEGRATIONS.md](./10-INTEGRATIONS.md)** (795 lines) - Advanced
- Next.js 13+ App Router: installation, config, patterns
- React: Create React App, component patterns, conditional classes
- Vite: installation, config, optimizations
- Vue 3: installation, component patterns, dynamic classes
- Svelte: installation, component patterns
- Angular: installation, component patterns
- PostCSS configuration
- Build optimization
- Server-Side Rendering (SSR)
- JIT mode and arbitrary values

**[11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md)** (710 lines) - Advanced
- Production configuration
- Environment-specific config
- Performance optimization: content paths, safelist, disabling plugins
- CLI commands: init, build, watch
- VS Code setup: extensions, settings, IntelliSense
- Debugging tools: browser DevTools, debug screens
- Troubleshooting: classes not generating, styles not applying, performance issues
- Migration guides: v2 to v3
- Best practices
- Monitoring and CI/CD integration

---

## Syntax Quick Lookup

### Spacing Scale

```
0, 0.5, 1, 1.5, 2, 2.5, 3, 3.5, 4, 5, 6, 7, 8, 9, 10, 11, 12, 14, 16, 20, 24, 28, 32, 36, 40, 44, 48, 52, 56, 60, 64, 72, 80, 96
```

Example: `p-4` = 1rem padding, `m-2` = 0.5rem margin

### Color Shades

```
50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950
```

Example: `bg-blue-500`, `text-gray-900`

### Breakpoints

```
sm: 640px
md: 768px
lg: 1024px
xl: 1280px
2xl: 1536px
```

Example: `md:flex`, `lg:grid-cols-3`

### Font Sizes

```
xs, sm, base, lg, xl, 2xl, 3xl, 4xl, 5xl, 6xl, 7xl, 8xl, 9xl
```

Example: `text-xl`, `text-2xl`

---

## Common Questions

**Q: Where do I start if I'm new to Tailwind?**
A: [01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md) → Follow the beginner learning path

**Q: How do I find a specific utility class?**
A: [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) → Search by category or use Ctrl+F

**Q: My classes aren't working, what's wrong?**
A: [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) → Troubleshooting → Classes Not Generating

**Q: How do I build a specific component?**
A: Use this INDEX.md → Problem-Based Quick Find → Search for your component

**Q: Is there a cheat sheet?**
A: Yes! [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) - one-page syntax reference

---

## File Reading Order by Use Case

**Learning Tailwind from scratch:**
1. README.md → Overview
2. 01-FUNDAMENTALS.md → Core concepts
3. 02-UTILITY-CLASSES.md → Essential utilities
4. 03-RESPONSIVE-DESIGN.md → Mobile-first
5. Practice building components
6. 04-CUSTOMIZATION.md → Customize theme
7. Continue through 05-11 as needed

**Building a specific component:**
1. INDEX.md → Problem-Based Quick Find
2. Jump to relevant file (05-LAYOUT-PATTERNS.md for layouts, 07-FORMS.md for forms, etc.)
3. Copy and adapt examples
4. Reference QUICK-REFERENCE.md for syntax

**Optimizing existing Tailwind project:**
1. 11-CONFIG-OPERATIONS.md → Performance Optimization
2. 04-CUSTOMIZATION.md → Production Optimization
3. 10-INTEGRATIONS.md → Build Optimization

**Implementing advanced features:**
1. 06-DARK-MODE.md → Dark mode
2. 08-ANIMATIONS.md → Animations
3. 09-TYPOGRAPHY.md → Typography
4. FRAMEWORK-INTEGRATION-PATTERNS.md → Advanced patterns

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1 | **Total Coverage**: 15 files, ~9,500 lines
