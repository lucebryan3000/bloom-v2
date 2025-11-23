---
id: tailwind-utility-classes
topic: tailwind
file_role: guide
profile: full
difficulty_level: beginner
kb_version: 3.1
prerequisites: [tailwind-fundamentals]
related_topics: [css, responsive-design, styling]
embedding_keywords: [tailwind, utility-classes, css, styling, utilities]
last_reviewed: 2025-11-16
---

# Tailwind CSS - Utility Classes

Core utility classes and their usage patterns.

## Overview

Tailwind CSS is a utility-first CSS framework that provides low-level utility classes to build custom designs without writing CSS. This guide covers the most commonly used utility classes.

---

## Spacing

### Padding

```html
<!-- All sides -->
<div class="p-4">Padding 1rem (16px)</div>
<div class="p-8">Padding 2rem (32px)</div>

<!-- Individual sides -->
<div class="pt-4">Padding top 1rem</div>
<div class="pr-4">Padding right 1rem</div>
<div class="pb-4">Padding bottom 1rem</div>
<div class="pl-4">Padding left 1rem</div>

<!-- Horizontal & Vertical -->
<div class="px-4">Padding left & right 1rem</div>
<div class="py-4">Padding top & bottom 1rem</div>

<!-- Zero padding -->
<div class="p-0">No padding</div>
```

### Margin

```html
<!-- All sides -->
<div class="m-4">Margin 1rem</div>
<div class="m-auto">Center horizontally</div>

<!-- Individual sides -->
<div class="mt-4">Margin top 1rem</div>
<div class="mr-4">Margin right 1rem</div>
<div class="mb-4">Margin bottom 1rem</div>
<div class="ml-4">Margin left 1rem</div>

<!-- Horizontal & Vertical -->
<div class="mx-4">Margin left & right 1rem</div>
<div class="my-4">Margin top & bottom 1rem</div>

<!-- Negative margins -->
<div class="-mt-4">Negative margin top</div>
<div class="-ml-8">Negative margin left</div>
```

### Space Between

```html
<!-- Space between children -->
<div class="space-y-4">
  <div>Item 1</div>
  <div>Item 2</div>
  <div>Item 3</div>
</div>

<div class="space-x-4">
  <span>Item 1</span>
  <span>Item 2</span>
  <span>Item 3</span>
</div>
```

---

## Typography

### Font Size

```html
<p class="text-xs">Extra small (0.75rem)</p>
<p class="text-sm">Small (0.875rem)</p>
<p class="text-base">Base (1rem)</p>
<p class="text-lg">Large (1.125rem)</p>
<p class="text-xl">Extra large (1.25rem)</p>
<p class="text-2xl">2X large (1.5rem)</p>
<p class="text-3xl">3X large (1.875rem)</p>
<p class="text-4xl">4X large (2.25rem)</p>
```

### Font Weight

```html
<p class="font-thin">Thin (100)</p>
<p class="font-light">Light (300)</p>
<p class="font-normal">Normal (400)</p>
<p class="font-medium">Medium (500)</p>
<p class="font-semibold">Semibold (600)</p>
<p class="font-bold">Bold (700)</p>
<p class="font-black">Black (900)</p>
```

### Text Alignment

```html
<p class="text-left">Left aligned</p>
<p class="text-center">Center aligned</p>
<p class="text-right">Right aligned</p>
<p class="text-justify">Justified</p>
```

### Text Color

```html
<p class="text-gray-500">Gray text</p>
<p class="text-blue-600">Blue text</p>
<p class="text-red-500">Red text</p>
<p class="text-green-600">Green text</p>

<!-- With opacity -->
<p class="text-blue-600/50">Blue with 50% opacity</p>
<p class="text-red-500/75">Red with 75% opacity</p>
```

### Line Height & Letter Spacing

```html
<!-- Line height -->
<p class="leading-none">Line height 1</p>
<p class="leading-tight">Line height 1.25</p>
<p class="leading-normal">Line height 1.5</p>
<p class="leading-relaxed">Line height 1.625</p>
<p class="leading-loose">Line height 2</p>

<!-- Letter spacing -->
<p class="tracking-tighter">Tighter spacing</p>
<p class="tracking-tight">Tight spacing</p>
<p class="tracking-normal">Normal spacing</p>
<p class="tracking-wide">Wide spacing</p>
<p class="tracking-wider">Wider spacing</p>
```

---

## Colors

### Background Colors

```html
<div class="bg-white">White background</div>
<div class="bg-gray-100">Light gray</div>
<div class="bg-gray-900">Dark gray</div>
<div class="bg-blue-500">Blue background</div>

<!-- With opacity -->
<div class="bg-blue-500/50">Blue with 50% opacity</div>
<div class="bg-red-600/25">Red with 25% opacity</div>

<!-- Gradients -->
<div class="bg-gradient-to-r from-blue-500 to-purple-600">
  Gradient background
</div>
```

### Border Colors

```html
<div class="border border-gray-300">Gray border</div>
<div class="border-2 border-blue-500">Blue border</div>
<div class="border-t-4 border-red-500">Top red border</div>
```

---

## Layout

### Display

```html
<div class="block">Block element</div>
<div class="inline-block">Inline block</div>
<div class="inline">Inline element</div>
<div class="flex">Flex container</div>
<div class="grid">Grid container</div>
<div class="hidden">Hidden element</div>
```

### Flexbox

```html
<!-- Container -->
<div class="flex">
  <div>Item 1</div>
  <div>Item 2</div>
</div>

<!-- Direction -->
<div class="flex flex-row">Horizontal</div>
<div class="flex flex-col">Vertical</div>
<div class="flex flex-row-reverse">Reverse horizontal</div>

<!-- Justify content -->
<div class="flex justify-start">Start</div>
<div class="flex justify-center">Center</div>
<div class="flex justify-end">End</div>
<div class="flex justify-between">Space between</div>
<div class="flex justify-around">Space around</div>

<!-- Align items -->
<div class="flex items-start">Align start</div>
<div class="flex items-center">Align center</div>
<div class="flex items-end">Align end</div>
<div class="flex items-stretch">Stretch</div>

<!-- Gap -->
<div class="flex gap-4">Gap 1rem</div>
<div class="flex gap-x-4 gap-y-2">Different x/y gaps</div>

<!-- Wrap -->
<div class="flex flex-wrap">Wrap items</div>
<div class="flex flex-nowrap">No wrap</div>
```

### Grid

```html
<!-- Grid columns -->
<div class="grid grid-cols-2">Two columns</div>
<div class="grid grid-cols-3">Three columns</div>
<div class="grid grid-cols-4">Four columns</div>
<div class="grid grid-cols-12">12 columns</div>

<!-- Grid rows -->
<div class="grid grid-rows-2">Two rows</div>
<div class="grid grid-rows-3">Three rows</div>

<!-- Gap -->
<div class="grid grid-cols-3 gap-4">Grid with gap</div>
<div class="grid grid-cols-3 gap-x-4 gap-y-2">Different x/y gaps</div>

<!-- Column span -->
<div class="grid grid-cols-3">
  <div class="col-span-2">Spans 2 columns</div>
  <div>1 column</div>
</div>

<!-- Auto columns -->
<div class="grid grid-cols-[auto_1fr_auto]">
  <div>Auto</div>
  <div>Flex</div>
  <div>Auto</div>
</div>
```

---

## Sizing

### Width

```html
<!-- Fixed widths -->
<div class="w-32">Width 8rem (128px)</div>
<div class="w-64">Width 16rem (256px)</div>

<!-- Percentage widths -->
<div class="w-1/2">50% width</div>
<div class="w-1/3">33.333% width</div>
<div class="w-2/3">66.666% width</div>
<div class="w-full">100% width</div>

<!-- Viewport widths -->
<div class="w-screen">100vw width</div>

<!-- Min/Max widths -->
<div class="min-w-0">Min width 0</div>
<div class="max-w-sm">Max width 24rem</div>
<div class="max-w-md">Max width 28rem</div>
<div class="max-w-lg">Max width 32rem</div>
<div class="max-w-xl">Max width 36rem</div>
<div class="max-w-7xl">Max width 80rem</div>
```

### Height

```html
<!-- Fixed heights -->
<div class="h-32">Height 8rem</div>
<div class="h-64">Height 16rem</div>

<!-- Percentage heights -->
<div class="h-1/2">50% height</div>
<div class="h-full">100% height</div>

<!-- Viewport heights -->
<div class="h-screen">100vh height</div>

<!-- Min/Max heights -->
<div class="min-h-0">Min height 0</div>
<div class="min-h-screen">Min height 100vh</div>
<div class="max-h-64">Max height 16rem</div>
```

---

## Borders

### Border Width

```html
<div class="border">1px border</div>
<div class="border-2">2px border</div>
<div class="border-4">4px border</div>
<div class="border-8">8px border</div>

<!-- Individual sides -->
<div class="border-t">Top border</div>
<div class="border-r">Right border</div>
<div class="border-b">Bottom border</div>
<div class="border-l">Left border</div>
```

### Border Radius

```html
<div class="rounded">0.25rem radius</div>
<div class="rounded-md">0.375rem radius</div>
<div class="rounded-lg">0.5rem radius</div>
<div class="rounded-xl">0.75rem radius</div>
<div class="rounded-2xl">1rem radius</div>
<div class="rounded-full">9999px radius (circle)</div>

<!-- Individual corners -->
<div class="rounded-t-lg">Top corners</div>
<div class="rounded-r-lg">Right corners</div>
<div class="rounded-b-lg">Bottom corners</div>
<div class="rounded-l-lg">Left corners</div>
<div class="rounded-tl-lg">Top left corner</div>
```

---

## Shadows

```html
<div class="shadow-sm">Small shadow</div>
<div class="shadow">Default shadow</div>
<div class="shadow-md">Medium shadow</div>
<div class="shadow-lg">Large shadow</div>
<div class="shadow-xl">Extra large shadow</div>
<div class="shadow-2xl">2X large shadow</div>
<div class="shadow-none">No shadow</div>

<!-- Colored shadows -->
<div class="shadow-lg shadow-blue-500/50">Blue shadow</div>
<div class="shadow-xl shadow-red-500/50">Red shadow</div>
```

---

## Position

```html
<!-- Position type -->
<div class="static">Static position</div>
<div class="relative">Relative position</div>
<div class="absolute">Absolute position</div>
<div class="fixed">Fixed position</div>
<div class="sticky">Sticky position</div>

<!-- Position values -->
<div class="absolute top-0 left-0">Top left</div>
<div class="absolute top-0 right-0">Top right</div>
<div class="absolute bottom-0 left-0">Bottom left</div>
<div class="absolute bottom-0 right-0">Bottom right</div>

<!-- Inset -->
<div class="absolute inset-0">All sides 0</div>
<div class="absolute inset-x-0">Horizontal 0</div>
<div class="absolute inset-y-0">Vertical 0</div>

<!-- Z-index -->
<div class="z-0">Z-index 0</div>
<div class="z-10">Z-index 10</div>
<div class="z-20">Z-index 20</div>
<div class="z-50">Z-index 50</div>
```

---

## Opacity & Visibility

```html
<!-- Opacity -->
<div class="opacity-0">Invisible (0%)</div>
<div class="opacity-25">25% opacity</div>
<div class="opacity-50">50% opacity</div>
<div class="opacity-75">75% opacity</div>
<div class="opacity-100">Fully opaque</div>

<!-- Visibility -->
<div class="visible">Visible</div>
<div class="invisible">Invisible but takes space</div>
```

---

## Transitions & Animations

```html
<!-- Transitions -->
<button class="transition hover:bg-blue-500">
  Transition all properties
</button>

<button class="transition-colors hover:bg-blue-500">
  Transition colors only
</button>

<button class="transition-transform hover:scale-110">
  Transition transform
</button>

<!-- Duration -->
<button class="transition duration-150">150ms</button>
<button class="transition duration-300">300ms</button>
<button class="transition duration-500">500ms</button>

<!-- Timing function -->
<button class="transition ease-in">Ease in</button>
<button class="transition ease-out">Ease out</button>
<button class="transition ease-in-out">Ease in-out</button>

<!-- Transform -->
<div class="hover:scale-110">Scale on hover</div>
<div class="hover:rotate-45">Rotate on hover</div>
<div class="hover:translate-x-2">Translate on hover</div>
```

---

## Responsive Design

```html
<!-- Mobile-first approach -->
<div class="w-full md:w-1/2 lg:w-1/3">
  Full width on mobile, half on tablet, third on desktop
</div>

<!-- Breakpoint-specific classes -->
<div class="text-sm sm:text-base md:text-lg lg:text-xl">
  Responsive text size
</div>

<!-- Hide/show at breakpoints -->
<div class="block md:hidden">Mobile only</div>
<div class="hidden md:block">Desktop only</div>

<!-- Responsive flexbox -->
<div class="flex flex-col md:flex-row">
  Column on mobile, row on desktop
</div>
```

---

## Hover, Focus, and Other States

```html
<!-- Hover -->
<button class="bg-blue-500 hover:bg-blue-600">
  Hover me
</button>

<!-- Focus -->
<input class="border focus:border-blue-500 focus:ring focus:ring-blue-200">

<!-- Active -->
<button class="bg-blue-500 active:bg-blue-700">
  Click me
</button>

<!-- Disabled -->
<button class="bg-blue-500 disabled:opacity-50" disabled>
  Disabled
</button>

<!-- Group hover -->
<div class="group">
  <button class="bg-blue-500 group-hover:bg-blue-600">
    Button
  </button>
  <p class="text-gray-500 group-hover:text-gray-700">
    Text changes on group hover
  </p>
</div>

<!-- Dark mode -->
<div class="bg-white dark:bg-gray-900 text-black dark:text-white">
  Auto dark mode
</div>
```

---

## Common Patterns

### Card Component

```html
<div class="bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition">
  <h2 class="text-xl font-bold mb-2">Card Title</h2>
  <p class="text-gray-600 mb-4">Card description goes here.</p>
  <button class="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600">
    Action
  </button>
</div>
```

### Button Variants

```html
<!-- Primary -->
<button class="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600 transition">
  Primary
</button>

<!-- Secondary -->
<button class="bg-gray-200 text-gray-800 px-4 py-2 rounded hover:bg-gray-300 transition">
  Secondary
</button>

<!-- Outline -->
<button class="border-2 border-blue-500 text-blue-500 px-4 py-2 rounded hover:bg-blue-500 hover:text-white transition">
  Outline
</button>
```

### Input Field

```html
<div class="mb-4">
  <label class="block text-gray-700 text-sm font-bold mb-2">
    Email
  </label>
  <input
    type="email"
    class="border rounded w-full py-2 px-3 text-gray-700 focus:outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-200"
    placeholder="you@example.com"
  >
</div>
```

---

## AI Pair Programming Notes

**When to load this KB:**
- Learning Tailwind utility classes
- Building UI components with Tailwind
- Need quick reference for class names
- Styling React/Next.js components

**Common starting points:**
- Spacing: See Spacing section
- Typography: See Typography section
- Layout: See Layout section (Flexbox, Grid)
- Colors: See Colors section

**Typical questions:**
- "How do I center a div?" → Layout → Flexbox
- "How do I make text bigger?" → Typography → Font Size
- "How do I add spacing?" → Spacing → Padding/Margin
- "How do I make it responsive?" → Responsive Design section

**Related topics:**
- Responsive design: See `03-RESPONSIVE-DESIGN.md`
- Customization: See `04-CUSTOMIZATION.md`
- Dark mode: See `06-DARK-MODE.md`

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1
