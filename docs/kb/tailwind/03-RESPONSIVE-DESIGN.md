---
id: tailwind-responsive-design
topic: tailwind
file_role: guide
profile: full
difficulty_level: beginner
kb_version: 3.1
prerequisites: [tailwind-fundamentals, tailwind-utility-classes]
related_topics: [responsive-design, mobile-first, breakpoints]
embedding_keywords: [tailwind, responsive, mobile-first, breakpoints, media-queries]
last_reviewed: 2025-11-16
---

# Tailwind CSS - Responsive Design

Mobile-first responsive design patterns with Tailwind CSS.

## Overview

Tailwind uses a mobile-first breakpoint system. All utility classes can be applied conditionally at different breakpoints using responsive prefixes.

---

## Breakpoints

### Default Breakpoints

```javascript
// tailwind.config.js - Default breakpoints
module.exports = {
  theme: {
    screens: {
      'sm': '640px',   // @media (min-width: 640px)
      'md': '768px',   // @media (min-width: 768px)
      'lg': '1024px',  // @media (min-width: 1024px)
      'xl': '1280px',  // @media (min-width: 1280px)
      '2xl': '1536px', // @media (min-width: 1536px)
    }
  }
}
```

### Usage

```html
<!-- Mobile: full width, Tablet: half width, Desktop: third width -->
<div class="w-full md:w-1/2 lg:w-1/3">
  Responsive width
</div>

<!-- Mobile: small text, Desktop: large text -->
<p class="text-sm md:text-base lg:text-lg xl:text-xl">
  Responsive text
</p>
```

---

## Mobile-First Approach

Tailwind is mobile-first, meaning unprefixed utilities target mobile devices, and you add larger breakpoints as needed.

### Example: Responsive Layout

```html
<div class="container mx-auto px-4">
  <!-- Mobile: stack vertically, Desktop: side by side -->
  <div class="flex flex-col md:flex-row gap-4">
    <div class="w-full md:w-2/3">
      <h1 class="text-2xl md:text-3xl lg:text-4xl font-bold">
        Main Content
      </h1>
      <p class="text-sm md:text-base text-gray-600">
        This content takes full width on mobile, 2/3 width on desktop.
      </p>
    </div>

    <aside class="w-full md:w-1/3">
      <h2 class="text-xl md:text-2xl font-semibold">
        Sidebar
      </h2>
      <p class="text-sm md:text-base">
        Sidebar content appears below main content on mobile.
      </p>
    </aside>
  </div>
</div>
```

---

## Responsive Utilities

### Display

```html
<!-- Hide on mobile, show on desktop -->
<div class="hidden md:block">
  Desktop only
</div>

<!-- Show on mobile, hide on desktop -->
<div class="block md:hidden">
  Mobile only
</div>

<!-- Show on specific breakpoints -->
<div class="hidden md:block lg:hidden">
  Tablet only
</div>
```

### Flexbox

```html
<!-- Stack on mobile, row on desktop -->
<div class="flex flex-col md:flex-row">
  <div>Item 1</div>
  <div>Item 2</div>
  <div>Item 3</div>
</div>

<!-- Center on mobile, left-align on desktop -->
<div class="flex flex-col items-center md:items-start">
  <h1>Title</h1>
  <p>Content</p>
</div>

<!-- Responsive gap -->
<div class="flex gap-2 md:gap-4 lg:gap-6">
  <div>Item 1</div>
  <div>Item 2</div>
</div>
```

### Grid

```html
<!-- 1 column mobile, 2 tablet, 3 desktop, 4 wide desktop -->
<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
  <div>Item 1</div>
  <div>Item 2</div>
  <div>Item 3</div>
  <div>Item 4</div>
</div>

<!-- Responsive grid with different gaps -->
<div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-2 md:gap-4 lg:gap-6">
  <!-- Grid items -->
</div>
```

### Typography

```html
<!-- Responsive text size -->
<h1 class="text-2xl sm:text-3xl md:text-4xl lg:text-5xl xl:text-6xl font-bold">
  Responsive Heading
</h1>

<!-- Responsive line height -->
<p class="leading-normal md:leading-relaxed lg:leading-loose">
  Responsive line height
</p>

<!-- Responsive text alignment -->
<p class="text-center md:text-left">
  Centered on mobile, left-aligned on desktop
</p>
```

### Spacing

```html
<!-- Responsive padding -->
<div class="p-4 md:p-6 lg:p-8 xl:p-12">
  Content with responsive padding
</div>

<!-- Responsive margin -->
<div class="my-4 md:my-6 lg:my-8">
  Content with responsive margin
</div>

<!-- Responsive space between -->
<div class="space-y-2 md:space-y-4 lg:space-y-6">
  <div>Item 1</div>
  <div>Item 2</div>
  <div>Item 3</div>
</div>
```

---

## Custom Breakpoints

### Adding Custom Breakpoints

```javascript
// tailwind.config.js
module.exports = {
  theme: {
    screens: {
      'xs': '475px',   // Extra small
      'sm': '640px',
      'md': '768px',
      'lg': '1024px',
      'xl': '1280px',
      '2xl': '1536px',
      '3xl': '1920px', // Ultra wide
    }
  }
}
```

### Max-Width Breakpoints

```javascript
// tailwind.config.js
module.exports = {
  theme: {
    screens: {
      'sm': '640px',
      'md': {'max': '767px'}, // Target mobile and tablet only
      'lg': '1024px',
    }
  }
}
```

### Range Breakpoints

```javascript
// tailwind.config.js
module.exports = {
  theme: {
    screens: {
      'sm': '640px',
      'md': {'min': '768px', 'max': '1023px'}, // Tablet only
      'lg': '1024px',
    }
  }
}
```

---

## Common Responsive Patterns

### Responsive Navigation

```html
<!-- Mobile: hamburger menu, Desktop: horizontal nav -->
<nav class="bg-white shadow">
  <div class="container mx-auto px-4">
    <div class="flex justify-between items-center py-4">
      <!-- Logo -->
      <div class="text-xl font-bold">
        Logo
      </div>

      <!-- Desktop nav (hidden on mobile) -->
      <div class="hidden md:flex space-x-6">
        <a href="#" class="hover:text-blue-500">Home</a>
        <a href="#" class="hover:text-blue-500">About</a>
        <a href="#" class="hover:text-blue-500">Services</a>
        <a href="#" class="hover:text-blue-500">Contact</a>
      </div>

      <!-- Mobile menu button (hidden on desktop) -->
      <button class="md:hidden">
        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"/>
        </svg>
      </button>
    </div>
  </div>
</nav>
```

### Responsive Card Grid

```html
<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4 md:gap-6">
  <!-- Card -->
  <div class="bg-white rounded-lg shadow-md overflow-hidden">
    <img src="image.jpg" alt="Card image" class="w-full h-48 object-cover">
    <div class="p-4 md:p-6">
      <h3 class="text-lg md:text-xl font-bold mb-2">Card Title</h3>
      <p class="text-sm md:text-base text-gray-600 mb-4">
        Card description goes here.
      </p>
      <button class="bg-blue-500 text-white px-4 py-2 rounded text-sm md:text-base hover:bg-blue-600">
        Learn More
      </button>
    </div>
  </div>
  <!-- Repeat cards -->
</div>
```

### Responsive Hero Section

```html
<div class="bg-gradient-to-r from-blue-500 to-purple-600 text-white">
  <div class="container mx-auto px-4 py-12 md:py-20 lg:py-32">
    <div class="flex flex-col md:flex-row items-center gap-8 md:gap-12">
      <!-- Content -->
      <div class="w-full md:w-1/2 text-center md:text-left">
        <h1 class="text-3xl sm:text-4xl md:text-5xl lg:text-6xl font-bold mb-4 md:mb-6">
          Welcome to Our Site
        </h1>
        <p class="text-base sm:text-lg md:text-xl mb-6 md:mb-8">
          Build amazing things with Tailwind CSS
        </p>
        <button class="bg-white text-blue-500 px-6 py-3 md:px-8 md:py-4 rounded-lg font-semibold text-sm md:text-base hover:bg-gray-100 transition">
          Get Started
        </button>
      </div>

      <!-- Image -->
      <div class="w-full md:w-1/2">
        <img src="hero.jpg" alt="Hero" class="rounded-lg shadow-2xl">
      </div>
    </div>
  </div>
</div>
```

### Responsive Form

```html
<form class="max-w-4xl mx-auto p-4 md:p-8">
  <div class="grid grid-cols-1 md:grid-cols-2 gap-4 md:gap-6">
    <!-- First Name -->
    <div>
      <label class="block text-sm font-medium mb-2">First Name</label>
      <input
        type="text"
        class="w-full px-3 py-2 md:px-4 md:py-3 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
      >
    </div>

    <!-- Last Name -->
    <div>
      <label class="block text-sm font-medium mb-2">Last Name</label>
      <input
        type="text"
        class="w-full px-3 py-2 md:px-4 md:py-3 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
      >
    </div>

    <!-- Email (full width) -->
    <div class="md:col-span-2">
      <label class="block text-sm font-medium mb-2">Email</label>
      <input
        type="email"
        class="w-full px-3 py-2 md:px-4 md:py-3 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
      >
    </div>

    <!-- Message (full width) -->
    <div class="md:col-span-2">
      <label class="block text-sm font-medium mb-2">Message</label>
      <textarea
        rows="4"
        class="w-full px-3 py-2 md:px-4 md:py-3 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
      ></textarea>
    </div>

    <!-- Submit button -->
    <div class="md:col-span-2">
      <button class="w-full md:w-auto bg-blue-500 text-white px-6 py-3 rounded-lg font-semibold hover:bg-blue-600 transition">
        Submit
      </button>
    </div>
  </div>
</form>
```

---

## Container Queries (Modern)

Tailwind v3.2+ supports container queries for component-based responsive design.

### Setup

```javascript
// tailwind.config.js
module.exports = {
  plugins: [
    require('@tailwindcss/container-queries'),
  ],
}
```

### Usage

```html
<!-- Container -->
<div class="@container">
  <!-- Child responds to container size, not viewport -->
  <div class="@sm:text-lg @md:text-xl @lg:text-2xl">
    Responsive to container width
  </div>
</div>

<!-- Named containers -->
<div class="@container/main">
  <div class="@lg/main:flex">
    Responds to .@container/main
  </div>
</div>
```

---

## Print Styles

```html
<!-- Hide on print -->
<div class="print:hidden">
  This won't appear when printing
</div>

<!-- Show only on print -->
<div class="hidden print:block">
  This only appears when printing
</div>

<!-- Print-specific styles -->
<div class="text-sm print:text-base">
  Larger text when printing
</div>
```

---

## Best Practices

### 1. Mobile-First Mindset

```html
<!-- ✅ Good: Mobile-first -->
<div class="text-sm md:text-base lg:text-lg">
  Start small, scale up
</div>

<!-- ❌ Avoid: Desktop-first -->
<div class="text-lg md:text-base sm:text-sm">
  Requires overrides at each breakpoint
</div>
```

### 2. Use Container for Max Width

```html
<!-- ✅ Good: Use container -->
<div class="container mx-auto px-4">
  Content automatically constrained and centered
</div>

<!-- ❌ Avoid: Manual max-width on every section -->
<div class="max-w-7xl mx-auto px-4">
  Repetitive
</div>
```

### 3. Consistent Breakpoints

```html
<!-- ✅ Good: Consistent breakpoint usage -->
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3">
  <div class="p-4 md:p-6 lg:p-8">Item</div>
</div>

<!-- ❌ Avoid: Mixing breakpoints inconsistently -->
<div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3">
  <div class="p-4 lg:p-6 2xl:p-8">Item</div>
</div>
```

### 4. Responsive Images

```html
<!-- ✅ Good: Responsive image -->
<img
  src="image.jpg"
  alt="Description"
  class="w-full h-auto object-cover md:w-1/2 lg:w-1/3"
>

<!-- ✅ Good: Art direction with picture -->
<picture>
  <source media="(min-width: 1024px)" srcset="desktop.jpg">
  <source media="(min-width: 768px)" srcset="tablet.jpg">
  <img src="mobile.jpg" alt="Description" class="w-full h-auto">
</picture>
```

---

## Testing Responsive Design

### Browser DevTools

```
Chrome/Edge DevTools:
1. Open DevTools (F12)
2. Click device toolbar icon (Ctrl+Shift+M)
3. Select device or enter custom dimensions
4. Test at each breakpoint: 640px, 768px, 1024px, 1280px, 1536px
```

### Common Test Devices

- **Mobile**: 375px (iPhone SE), 390px (iPhone 12), 414px (iPhone Pro Max)
- **Tablet**: 768px (iPad), 820px (iPad Air), 1024px (iPad Pro)
- **Desktop**: 1280px, 1440px, 1920px

---

## AI Pair Programming Notes

**When to load this KB:**
- Building responsive layouts
- Need mobile-first design patterns
- Implementing breakpoint-specific styles
- Testing responsive components

**Common starting points:**
- Breakpoints: See Breakpoints section
- Mobile-first: See Mobile-First Approach section
- Patterns: See Common Responsive Patterns section

**Typical questions:**
- "How do I make this responsive?" → Mobile-First Approach
- "How do I hide on mobile?" → Responsive Utilities → Display
- "How do I change layout at breakpoints?" → Responsive Utilities → Flexbox/Grid
- "What are the breakpoint sizes?" → Breakpoints section

**Related topics:**
- Utility classes: See `02-UTILITY-CLASSES.md`
- Customization: See `04-CUSTOMIZATION.md`
- Layout patterns: See `05-LAYOUT-PATTERNS.md`

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1
