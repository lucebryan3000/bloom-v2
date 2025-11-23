---
id: tailwind-typography
topic: tailwind
file_role: guide
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [tailwind-fundamentals, tailwind-utility-classes, tailwind-customization]
related_topics: [typography, fonts, text, prose, tailwindcss-typography]
embedding_keywords: [tailwind, typography, fonts, text, prose, font-family, font-size, line-height]
last_reviewed: 2025-11-16
---

# Tailwind CSS - Typography

Typography utilities and the @tailwindcss/typography plugin for beautiful text styling.

## Overview

Tailwind CSS provides comprehensive typography utilities for font families, sizes, weights, colors, and spacing. The `@tailwindcss/typography` plugin adds beautiful default styles for prose content.

---

## Font Families

### Default Font Families

```html
<!-- font-sans: system sans-serif stack -->
<p class="font-sans">
  The quick brown fox jumps over the lazy dog.
</p>

<!-- font-serif: system serif stack -->
<p class="font-serif">
  The quick brown fox jumps over the lazy dog.
</p>

<!-- font-mono: monospace stack -->
<code class="font-mono">
  const greeting = 'Hello, World!'
</code>
```

### Custom Font Families

```javascript
// tailwind.config.js
module.exports = {
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
        serif: ['Georgia', 'serif'],
        mono: ['Fira Code', 'monospace'],
        display: ['Playfair Display', 'serif'],
        body: ['Open Sans', 'sans-serif'],
      },
    },
  },
}
```

```html
<!-- Using custom fonts -->
<h1 class="font-display text-4xl">Display Heading</h1>
<p class="font-body">Body text with custom font.</p>
```

### Google Fonts Integration

```html
<!-- Add to <head> -->
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
```

```javascript
// tailwind.config.js
module.exports = {
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter', 'sans-serif'],
      },
    },
  },
}
```

---

## Font Sizes

### Size Scale

```html
<!-- text-xs: 0.75rem (12px) -->
<p class="text-xs">Extra small text</p>

<!-- text-sm: 0.875rem (14px) -->
<p class="text-sm">Small text</p>

<!-- text-base: 1rem (16px) - default -->
<p class="text-base">Base text</p>

<!-- text-lg: 1.125rem (18px) -->
<p class="text-lg">Large text</p>

<!-- text-xl: 1.25rem (20px) -->
<p class="text-xl">Extra large text</p>

<!-- text-2xl: 1.5rem (24px) -->
<h3 class="text-2xl">2XL Heading</h3>

<!-- text-3xl: 1.875rem (30px) -->
<h2 class="text-3xl">3XL Heading</h2>

<!-- text-4xl: 2.25rem (36px) -->
<h1 class="text-4xl">4XL Heading</h1>

<!-- text-5xl: 3rem (48px) -->
<h1 class="text-5xl">5XL Heading</h1>

<!-- text-6xl: 3.75rem (60px) -->
<h1 class="text-6xl">6XL Heading</h1>

<!-- text-7xl: 4.5rem (72px) -->
<h1 class="text-7xl">7XL Heading</h1>

<!-- text-8xl: 6rem (96px) -->
<h1 class="text-8xl">8XL Heading</h1>

<!-- text-9xl: 8rem (128px) -->
<h1 class="text-9xl">9XL Heading</h1>
```

### Responsive Font Sizes

```html
<!-- Mobile: base, Tablet: lg, Desktop: xl -->
<h1 class="text-base md:text-lg lg:text-xl">
  Responsive Heading
</h1>

<!-- Mobile: 2xl, Tablet: 4xl, Desktop: 6xl -->
<h1 class="text-2xl md:text-4xl lg:text-6xl font-bold">
  Large Responsive Heading
</h1>
```

---

## Font Weights

### Weight Scale

```html
<!-- font-thin: 100 -->
<p class="font-thin">Thin text (100)</p>

<!-- font-extralight: 200 -->
<p class="font-extralight">Extra light text (200)</p>

<!-- font-light: 300 -->
<p class="font-light">Light text (300)</p>

<!-- font-normal: 400 - default -->
<p class="font-normal">Normal text (400)</p>

<!-- font-medium: 500 -->
<p class="font-medium">Medium text (500)</p>

<!-- font-semibold: 600 -->
<p class="font-semibold">Semibold text (600)</p>

<!-- font-bold: 700 -->
<p class="font-bold">Bold text (700)</p>

<!-- font-extrabold: 800 -->
<p class="font-extrabold">Extra bold text (800)</p>

<!-- font-black: 900 -->
<p class="font-black">Black text (900)</p>
```

### Common Combinations

```html
<!-- Heading with semibold -->
<h1 class="text-4xl font-semibold text-gray-900">
  Main Heading
</h1>

<!-- Subheading with medium -->
<h2 class="text-2xl font-medium text-gray-700">
  Subheading
</h2>

<!-- Body text with normal weight -->
<p class="text-base font-normal text-gray-600">
  Regular body text content.
</p>

<!-- Emphasized text with bold -->
<p class="text-base font-bold text-gray-900">
  Important information
</p>
```

---

## Font Styles

### Italic

```html
<!-- italic -->
<p class="italic">This text is italic</p>

<!-- not-italic -->
<p class="not-italic">This text is not italic</p>

<!-- Use with other styles -->
<p class="text-lg font-semibold italic text-gray-700">
  Italic semibold heading
</p>
```

---

## Line Height

### Line Height Values

```html
<!-- leading-none: 1 -->
<p class="leading-none">
  Tight line height. The quick brown fox jumps over the lazy dog.
</p>

<!-- leading-tight: 1.25 -->
<p class="leading-tight">
  Tight line height. The quick brown fox jumps over the lazy dog.
</p>

<!-- leading-snug: 1.375 -->
<p class="leading-snug">
  Snug line height. The quick brown fox jumps over the lazy dog.
</p>

<!-- leading-normal: 1.5 - default -->
<p class="leading-normal">
  Normal line height. The quick brown fox jumps over the lazy dog.
</p>

<!-- leading-relaxed: 1.625 -->
<p class="leading-relaxed">
  Relaxed line height. The quick brown fox jumps over the lazy dog.
</p>

<!-- leading-loose: 2 -->
<p class="leading-loose">
  Loose line height. The quick brown fox jumps over the lazy dog.
</p>
```

### Fixed Line Heights

```html
<!-- leading-3: 0.75rem -->
<p class="leading-3">Fixed line height</p>

<!-- leading-4: 1rem -->
<p class="leading-4">Fixed line height</p>

<!-- leading-6: 1.5rem -->
<p class="leading-6">Fixed line height</p>

<!-- leading-10: 2.5rem -->
<p class="leading-10">Fixed line height</p>
```

---

## Letter Spacing

### Tracking Values

```html
<!-- tracking-tighter: -0.05em -->
<p class="tracking-tighter">Tighter letter spacing</p>

<!-- tracking-tight: -0.025em -->
<p class="tracking-tight">Tight letter spacing</p>

<!-- tracking-normal: 0 - default -->
<p class="tracking-normal">Normal letter spacing</p>

<!-- tracking-wide: 0.025em -->
<p class="tracking-wide">Wide letter spacing</p>

<!-- tracking-wider: 0.05em -->
<p class="tracking-wider">Wider letter spacing</p>

<!-- tracking-widest: 0.1em -->
<p class="tracking-widest">Widest letter spacing</p>
```

### Common Use Cases

```html
<!-- Headings with wider tracking -->
<h1 class="text-6xl font-bold tracking-tight">
  HEADLINE
</h1>

<!-- Uppercase text with wide tracking -->
<p class="text-sm uppercase tracking-widest text-gray-600">
  Label Text
</p>

<!-- Button text -->
<button class="px-6 py-3 bg-blue-500 text-white font-semibold tracking-wide rounded-lg">
  Button Text
</button>
```

---

## Text Alignment

### Horizontal Alignment

```html
<!-- text-left -->
<p class="text-left">Left aligned text</p>

<!-- text-center -->
<p class="text-center">Center aligned text</p>

<!-- text-right -->
<p class="text-right">Right aligned text</p>

<!-- text-justify -->
<p class="text-justify">
  Justified text. The quick brown fox jumps over the lazy dog.
  Lorem ipsum dolor sit amet, consectetur adipiscing elit.
</p>

<!-- Responsive alignment -->
<p class="text-left md:text-center lg:text-right">
  Responsive alignment
</p>
```

### Vertical Alignment

```html
<!-- align-baseline -->
<span class="align-baseline">Baseline</span>

<!-- align-top -->
<span class="align-top">Top</span>

<!-- align-middle -->
<span class="align-middle">Middle</span>

<!-- align-bottom -->
<span class="align-bottom">Bottom</span>

<!-- align-text-top -->
<span class="align-text-top">Text top</span>

<!-- align-text-bottom -->
<span class="align-text-bottom">Text bottom</span>
```

---

## Text Decoration

### Underline

```html
<!-- underline -->
<a href="#" class="underline text-blue-600">Underlined link</a>

<!-- no-underline -->
<a href="#" class="no-underline text-blue-600">Link without underline</a>

<!-- Underline on hover -->
<a href="#" class="no-underline hover:underline text-blue-600">
  Underline on hover
</a>

<!-- Underline thickness -->
<p class="underline decoration-1">Thin underline</p>
<p class="underline decoration-2">Medium underline</p>
<p class="underline decoration-4">Thick underline</p>

<!-- Underline style -->
<p class="underline decoration-solid">Solid underline</p>
<p class="underline decoration-double">Double underline</p>
<p class="underline decoration-dotted">Dotted underline</p>
<p class="underline decoration-dashed">Dashed underline</p>
<p class="underline decoration-wavy">Wavy underline</p>

<!-- Underline color -->
<p class="underline decoration-blue-500">Blue underline</p>
<p class="underline decoration-red-500">Red underline</p>

<!-- Underline offset -->
<p class="underline underline-offset-1">Small offset</p>
<p class="underline underline-offset-4">Medium offset</p>
<p class="underline underline-offset-8">Large offset</p>
```

### Line Through

```html
<!-- line-through -->
<p class="line-through">Strikethrough text</p>

<!-- Price with strikethrough -->
<div class="flex items-center space-x-2">
  <span class="text-gray-500 line-through">$99.99</span>
  <span class="text-2xl font-bold text-red-600">$49.99</span>
</div>
```

---

## Text Transform

### Case Transformation

```html
<!-- uppercase -->
<p class="uppercase">uppercase text</p>

<!-- lowercase -->
<p class="lowercase">LOWERCASE TEXT</p>

<!-- capitalize -->
<p class="capitalize">capitalize each word</p>

<!-- normal-case -->
<p class="normal-case">Normal case text</p>
```

### Common Patterns

```html
<!-- Uppercase labels -->
<label class="block text-sm font-medium uppercase tracking-widest text-gray-600 mb-2">
  Email Address
</label>

<!-- Capitalized headings -->
<h2 class="text-2xl font-bold capitalize">
  welcome to our platform
</h2>
```

---

## Text Color

### Basic Colors

```html
<!-- Grayscale -->
<p class="text-gray-900">Dark gray text</p>
<p class="text-gray-600">Medium gray text</p>
<p class="text-gray-400">Light gray text</p>

<!-- Colors -->
<p class="text-blue-600">Blue text</p>
<p class="text-green-600">Green text</p>
<p class="text-red-600">Red text</p>
<p class="text-yellow-600">Yellow text</p>
<p class="text-purple-600">Purple text</p>
```

### Dark Mode Text Colors

```html
<!-- Adapts to dark mode -->
<p class="text-gray-900 dark:text-gray-100">
  Dark mode aware text
</p>

<!-- Muted text -->
<p class="text-gray-600 dark:text-gray-400">
  Muted text in both modes
</p>

<!-- Links -->
<a href="#" class="text-blue-600 dark:text-blue-400 hover:underline">
  Link text
</a>
```

---

## @tailwindcss/typography Plugin

### Installation

```bash
npm install @tailwindcss/typography
```

```javascript
// tailwind.config.js
module.exports = {
  plugins: [
    require('@tailwindcss/typography'),
  ],
}
```

### Basic Prose

```html
<!-- Default prose styling -->
<article class="prose">
  <h1>Heading 1</h1>
  <h2>Heading 2</h2>
  <p>
    This is a paragraph with <strong>bold</strong> and <em>italic</em> text.
    It automatically gets beautiful typography styles.
  </p>
  <ul>
    <li>List item one</li>
    <li>List item two</li>
    <li>List item three</li>
  </ul>
  <blockquote>
    <p>This is a beautiful blockquote with automatic styling.</p>
  </blockquote>
  <pre><code>const code = 'Code blocks are styled too!'</code></pre>
</article>
```

### Prose Sizes

```html
<!-- prose-sm: Small prose -->
<article class="prose prose-sm">
  <h1>Small Prose</h1>
  <p>Smaller text and spacing.</p>
</article>

<!-- prose: Default (base) -->
<article class="prose">
  <h1>Default Prose</h1>
  <p>Normal size text and spacing.</p>
</article>

<!-- prose-lg: Large prose -->
<article class="prose prose-lg">
  <h1>Large Prose</h1>
  <p>Larger text and spacing.</p>
</article>

<!-- prose-xl: Extra large prose -->
<article class="prose prose-xl">
  <h1>Extra Large Prose</h1>
  <p>Extra large text and spacing.</p>
</article>

<!-- prose-2xl: 2XL prose -->
<article class="prose prose-2xl">
  <h1>2XL Prose</h1>
  <p>Very large text and spacing.</p>
</article>

<!-- Responsive prose sizes -->
<article class="prose prose-sm md:prose-base lg:prose-lg xl:prose-xl">
  <h1>Responsive Prose</h1>
  <p>Changes size based on screen width.</p>
</article>
```

### Prose Colors

```html
<!-- prose-gray: Gray links and code (default) -->
<article class="prose prose-gray">
  <p>Content with gray accents</p>
</article>

<!-- prose-slate -->
<article class="prose prose-slate">
  <p>Content with slate accents</p>
</article>

<!-- prose-zinc -->
<article class="prose prose-zinc">
  <p>Content with zinc accents</p>
</article>

<!-- prose-blue -->
<article class="prose prose-blue">
  <p>Content with blue links and accents</p>
</article>

<!-- prose-green -->
<article class="prose prose-green">
  <p>Content with green links and accents</p>
</article>

<!-- prose-red -->
<article class="prose prose-red">
  <p>Content with red links and accents</p>
</article>
```

### Dark Mode Prose

```html
<!-- Automatic dark mode -->
<article class="prose dark:prose-invert">
  <h1>Dark Mode Prose</h1>
  <p>This content adapts to dark mode automatically.</p>
</article>

<!-- Custom dark mode colors -->
<article class="prose prose-blue dark:prose-invert">
  <h1>Blue Prose with Dark Mode</h1>
  <p>Blue links in light mode, inverted in dark mode.</p>
</article>
```

### Maximum Width

```html
<!-- Default: max-w-none -->
<article class="prose max-w-none">
  <p>Full width prose content</p>
</article>

<!-- Custom max width -->
<article class="prose max-w-2xl mx-auto">
  <p>Centered prose with max width</p>
</article>

<!-- Responsive max width -->
<article class="prose max-w-full md:max-w-3xl lg:max-w-4xl xl:max-w-5xl mx-auto">
  <p>Responsive max width prose</p>
</article>
```

### Customizing Prose

```javascript
// tailwind.config.js
module.exports = {
  theme: {
    extend: {
      typography: {
        DEFAULT: {
          css: {
            color: '#333',
            a: {
              color: '#3b82f6',
              '&:hover': {
                color: '#2563eb',
              },
            },
            h1: {
              fontWeight: '800',
            },
            code: {
              backgroundColor: '#f3f4f6',
              padding: '0.25rem 0.5rem',
              borderRadius: '0.25rem',
              fontWeight: '600',
            },
          },
        },
      },
    },
  },
}
```

---

## Typography Best Practices

### Hierarchy

```html
<!-- Clear visual hierarchy -->
<div class="space-y-4">
  <h1 class="text-4xl font-bold text-gray-900">
    Main Heading
  </h1>
  <h2 class="text-2xl font-semibold text-gray-800">
    Subheading
  </h2>
  <p class="text-base text-gray-600 leading-relaxed">
    Body text with comfortable line height and readable color contrast.
  </p>
</div>
```

### Readability

```html
<!-- Optimal line length: 45-75 characters -->
<article class="max-w-2xl mx-auto">
  <p class="text-base leading-relaxed text-gray-700">
    This paragraph has an optimal line length for readability.
    The max-width ensures lines don't become too long.
  </p>
</article>

<!-- Good contrast -->
<div class="bg-white">
  <p class="text-gray-900">High contrast dark text on light background</p>
</div>

<div class="bg-gray-900">
  <p class="text-gray-100">High contrast light text on dark background</p>
</div>
```

### Responsive Typography

```html
<!-- Scale typography responsively -->
<div class="space-y-6">
  <h1 class="text-3xl md:text-4xl lg:text-5xl xl:text-6xl font-bold leading-tight">
    Responsive Heading
  </h1>
  <p class="text-base md:text-lg leading-relaxed">
    Responsive body text that scales appropriately.
  </p>
</div>
```

---

## AI Pair Programming Notes

**When to load this KB:**
- Styling text and typography
- Using @tailwindcss/typography plugin
- Creating readable content layouts
- Implementing responsive text sizing

**Common starting points:**
- Font sizes: See Font Sizes
- Typography plugin: See @tailwindcss/typography Plugin
- Text styling: See Font Weights, Font Styles
- Prose content: See Basic Prose

**Typical questions:**
- "How do I change font size?" → Font Sizes
- "How do I use the typography plugin?" → @tailwindcss/typography Plugin
- "How do I style markdown content?" → Basic Prose
- "How do I make responsive text?" → Responsive Font Sizes

**Related topics:**
- Colors: See `02-UTILITY-CLASSES.md`
- Customization: See `04-CUSTOMIZATION.md`
- Dark mode: See `06-DARK-MODE.md`

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1
