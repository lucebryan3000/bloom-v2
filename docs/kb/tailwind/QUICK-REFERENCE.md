---
id: tailwind-quick-reference
topic: tailwind
file_role: quickref
profile: full
difficulty_level: all-levels
kb_version: 3.1
prerequisites: []
related_topics: [utility-classes, responsive-design, customization]
embedding_keywords: [tailwind, cheat-sheet, quick-reference, syntax, utilities]
last_reviewed: 2025-11-16
---

# Tailwind CSS - Quick Reference

**One-page cheat sheet for Tailwind CSS utilities and syntax. Bookmark this for quick lookups!**

---

## Installation

```bash
# Next.js
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p

# Vite/React
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p

# CLI only
npm install -D tailwindcss
npx tailwindcss init
```

**Config:**
```javascript
// tailwind.config.js
module.exports = {
  content: ["./src/**/*.{js,jsx,ts,tsx}"],
  theme: { extend: {} },
  plugins: [],
}
```

**CSS:**
```css
/* styles.css */
@tailwind base;
@tailwind components;
@tailwind utilities;
```

---

## Spacing Scale

```
0, 0.5, 1, 1.5, 2, 2.5, 3, 3.5, 4, 5, 6, 7, 8, 9, 10, 11, 12, 14, 16, 20, 24, 28, 32, 36, 40, 44, 48, 52, 56, 60, 64, 72, 80, 96
```

**Examples:**
- `p-4` = 1rem (16px) padding
- `m-2` = 0.5rem (8px) margin
- `w-12` = 3rem (48px) width

---

## Layout

### Display

```html
block           <!-- display: block -->
inline-block    <!-- display: inline-block -->
inline          <!-- display: inline -->
flex            <!-- display: flex -->
inline-flex     <!-- display: inline-flex -->
grid            <!-- display: grid -->
inline-grid     <!-- display: inline-grid -->
hidden          <!-- display: none -->
```

### Flexbox

```html
<!-- Direction -->
flex-row        <!-- flex-direction: row -->
flex-col        <!-- flex-direction: column -->
flex-row-reverse
flex-col-reverse

<!-- Wrap -->
flex-wrap
flex-nowrap
flex-wrap-reverse

<!-- Justify Content -->
justify-start
justify-center
justify-end
justify-between
justify-around
justify-evenly

<!-- Align Items -->
items-start
items-center
items-end
items-baseline
items-stretch

<!-- Align Self -->
self-start
self-center
self-end
self-stretch

<!-- Flex Grow/Shrink -->
flex-1          <!-- flex: 1 1 0% -->
flex-auto       <!-- flex: 1 1 auto -->
flex-none       <!-- flex: none -->
grow            <!-- flex-grow: 1 -->
grow-0          <!-- flex-grow: 0 -->
shrink          <!-- flex-shrink: 1 -->
shrink-0        <!-- flex-shrink: 0 -->

<!-- Gap -->
gap-0, gap-1, gap-2, gap-4, gap-6, gap-8
gap-x-4         <!-- column-gap -->
gap-y-4         <!-- row-gap -->
```

### Grid

```html
<!-- Columns -->
grid-cols-1     <!-- grid-template-columns: repeat(1, minmax(0, 1fr)) -->
grid-cols-2
grid-cols-3
grid-cols-4
grid-cols-6
grid-cols-12

<!-- Rows -->
grid-rows-1
grid-rows-2
grid-rows-3

<!-- Column Span -->
col-span-1
col-span-2
col-span-6
col-span-full   <!-- grid-column: 1 / -1 -->

<!-- Row Span -->
row-span-1
row-span-2
row-span-full

<!-- Gap -->
gap-4           <!-- gap: 1rem -->
gap-x-4         <!-- column-gap: 1rem -->
gap-y-2         <!-- row-gap: 0.5rem -->
```

### Position

```html
static          <!-- position: static -->
fixed           <!-- position: fixed -->
absolute        <!-- position: absolute -->
relative        <!-- position: relative -->
sticky          <!-- position: sticky -->

<!-- Positioning -->
top-0, right-0, bottom-0, left-0
top-4, right-4, bottom-4, left-4
inset-0         <!-- top, right, bottom, left: 0 -->
inset-x-0       <!-- left, right: 0 -->
inset-y-0       <!-- top, bottom: 0 -->
```

---

## Spacing

### Padding

```html
p-0, p-1, p-2, p-4, p-6, p-8, p-12, p-16
px-4            <!-- padding-left, padding-right -->
py-4            <!-- padding-top, padding-bottom -->
pt-4            <!-- padding-top -->
pr-4            <!-- padding-right -->
pb-4            <!-- padding-bottom -->
pl-4            <!-- padding-left -->
```

### Margin

```html
m-0, m-1, m-2, m-4, m-6, m-8, m-12, m-16
mx-4            <!-- margin-left, margin-right -->
my-4            <!-- margin-top, margin-bottom -->
mt-4            <!-- margin-top -->
mr-4            <!-- margin-right -->
mb-4            <!-- margin-bottom -->
ml-4            <!-- margin-left -->
mx-auto         <!-- margin-left: auto, margin-right: auto -->
-m-4            <!-- negative margin -->
```

### Space Between

```html
space-x-4       <!-- gap between children (horizontal) -->
space-y-4       <!-- gap between children (vertical) -->
space-x-reverse
space-y-reverse
```

---

## Sizing

### Width

```html
w-0, w-1, w-2, w-4, w-8, w-12, w-16, w-24, w-32, w-48, w-64
w-auto
w-full          <!-- width: 100% -->
w-screen        <!-- width: 100vw -->
w-min           <!-- width: min-content -->
w-max           <!-- width: max-content -->
w-fit           <!-- width: fit-content -->
w-1/2           <!-- width: 50% -->
w-1/3           <!-- width: 33.333% -->
w-2/3           <!-- width: 66.666% -->
w-1/4           <!-- width: 25% -->
w-3/4           <!-- width: 75% -->
```

### Height

```html
h-0, h-1, h-2, h-4, h-8, h-12, h-16, h-24, h-32, h-48, h-64
h-auto
h-full          <!-- height: 100% -->
h-screen        <!-- height: 100vh -->
h-min, h-max, h-fit
```

### Min/Max Width

```html
min-w-0, min-w-full
max-w-xs, max-w-sm, max-w-md, max-w-lg, max-w-xl, max-w-2xl, max-w-7xl
max-w-full, max-w-screen-sm, max-w-screen-lg
```

### Min/Max Height

```html
min-h-0, min-h-full, min-h-screen
max-h-0, max-h-full, max-h-screen
```

---

## Typography

### Font Size

```html
text-xs         <!-- font-size: 0.75rem (12px) -->
text-sm         <!-- 0.875rem (14px) -->
text-base       <!-- 1rem (16px) -->
text-lg         <!-- 1.125rem (18px) -->
text-xl         <!-- 1.25rem (20px) -->
text-2xl        <!-- 1.5rem (24px) -->
text-3xl        <!-- 1.875rem (30px) -->
text-4xl        <!-- 2.25rem (36px) -->
text-5xl        <!-- 3rem (48px) -->
text-6xl        <!-- 3.75rem (60px) -->
text-7xl        <!-- 4.5rem (72px) -->
text-8xl        <!-- 6rem (96px) -->
text-9xl        <!-- 8rem (128px) -->
```

### Font Weight

```html
font-thin       <!-- font-weight: 100 -->
font-extralight <!-- 200 -->
font-light      <!-- 300 -->
font-normal     <!-- 400 -->
font-medium     <!-- 500 -->
font-semibold   <!-- 600 -->
font-bold       <!-- 700 -->
font-extrabold  <!-- 800 -->
font-black      <!-- 900 -->
```

### Font Family

```html
font-sans       <!-- system sans-serif stack -->
font-serif      <!-- system serif stack -->
font-mono       <!-- system monospace stack -->
```

### Font Style

```html
italic
not-italic
```

### Text Alignment

```html
text-left
text-center
text-right
text-justify
```

### Text Color

```html
text-black
text-white
text-gray-50, text-gray-100, ..., text-gray-900
text-red-500
text-blue-600
text-green-700
```

### Text Decoration

```html
underline
line-through
no-underline
decoration-solid
decoration-double
decoration-dotted
decoration-dashed
decoration-wavy
```

### Text Transform

```html
uppercase
lowercase
capitalize
normal-case
```

### Line Height

```html
leading-none    <!-- line-height: 1 -->
leading-tight   <!-- 1.25 -->
leading-snug    <!-- 1.375 -->
leading-normal  <!-- 1.5 -->
leading-relaxed <!-- 1.625 -->
leading-loose   <!-- 2 -->
```

### Letter Spacing

```html
tracking-tighter <!-- letter-spacing: -0.05em -->
tracking-tight   <!-- -0.025em -->
tracking-normal  <!-- 0 -->
tracking-wide    <!-- 0.025em -->
tracking-wider   <!-- 0.05em -->
tracking-widest  <!-- 0.1em -->
```

---

## Colors

### Color Palette

```
Shades: 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950
```

**Colors:**
- `slate` `gray` `zinc` `neutral` `stone`
- `red` `orange` `amber` `yellow` `lime` `green` `emerald` `teal` `cyan` `sky` `blue` `indigo` `violet` `purple` `fuchsia` `pink` `rose`

**Usage:**
```html
bg-blue-500     <!-- background -->
text-red-600    <!-- text -->
border-green-700 <!-- border -->
```

### Background

```html
bg-transparent
bg-black
bg-white
bg-gray-100
bg-blue-500
bg-gradient-to-r <!-- gradient direction: to right -->
bg-gradient-to-br <!-- to bottom-right -->
from-blue-500   <!-- gradient start -->
via-purple-500  <!-- gradient middle -->
to-pink-500     <!-- gradient end -->
```

### Text Color

```html
text-black
text-white
text-gray-900
text-blue-600
text-current    <!-- currentColor -->
```

### Border Color

```html
border-black
border-white
border-gray-300
border-blue-500
```

---

## Borders

### Border Width

```html
border          <!-- border-width: 1px -->
border-0
border-2
border-4
border-8
border-x-2      <!-- left and right -->
border-y-2      <!-- top and bottom -->
border-t-2      <!-- top -->
border-r-2      <!-- right -->
border-b-2      <!-- bottom -->
border-l-2      <!-- left -->
```

### Border Style

```html
border-solid
border-dashed
border-dotted
border-double
border-none
```

### Border Radius

```html
rounded-none    <!-- border-radius: 0 -->
rounded-sm      <!-- 0.125rem -->
rounded         <!-- 0.25rem -->
rounded-md      <!-- 0.375rem -->
rounded-lg      <!-- 0.5rem -->
rounded-xl      <!-- 0.75rem -->
rounded-2xl     <!-- 1rem -->
rounded-3xl     <!-- 1.5rem -->
rounded-full    <!-- 9999px (circle) -->
rounded-t-lg    <!-- top corners -->
rounded-r-lg    <!-- right corners -->
rounded-b-lg    <!-- bottom corners -->
rounded-l-lg    <!-- left corners -->
```

---

## Effects

### Shadow

```html
shadow-sm       <!-- small shadow -->
shadow          <!-- medium shadow -->
shadow-md
shadow-lg
shadow-xl
shadow-2xl
shadow-inner
shadow-none
```

### Opacity

```html
opacity-0       <!-- opacity: 0 -->
opacity-25      <!-- 0.25 -->
opacity-50      <!-- 0.5 -->
opacity-75      <!-- 0.75 -->
opacity-100     <!-- 1 -->
```

---

## Responsive Design

### Breakpoints

```html
sm:             <!-- @media (min-width: 640px) -->
md:             <!-- @media (min-width: 768px) -->
lg:             <!-- @media (min-width: 1024px) -->
xl:             <!-- @media (min-width: 1280px) -->
2xl:            <!-- @media (min-width: 1536px) -->
```

**Usage:**
```html
<div class="text-sm md:text-base lg:text-lg">
  <!-- Mobile: small, Tablet: base, Desktop: large -->
</div>
```

---

## State Variants

```html
hover:          <!-- &:hover -->
focus:          <!-- &:focus -->
active:         <!-- &:active -->
visited:        <!-- &:visited (links only) -->
disabled:       <!-- &:disabled -->
first:          <!-- &:first-child -->
last:           <!-- &:last-child -->
odd:            <!-- &:nth-child(odd) -->
even:           <!-- &:nth-child(even) -->
group-hover:    <!-- parent has .group class and is hovered -->
peer-focus:     <!-- sibling with .peer class is focused -->
```

**Examples:**
```html
<button class="bg-blue-500 hover:bg-blue-600 active:bg-blue-700">
  Button
</button>

<div class="group">
  <img class="group-hover:scale-110" />
</div>

<input class="peer" />
<p class="hidden peer-focus:block">Shown when input focused</p>
```

---

## Dark Mode

```html
dark:           <!-- applies when dark mode is active -->
```

**Configuration:**
```javascript
// tailwind.config.js
module.exports = {
  darkMode: 'class', // or 'media'
}
```

**Usage:**
```html
<div class="bg-white dark:bg-gray-900 text-gray-900 dark:text-white">
  Content
</div>
```

---

## Transitions

```html
transition              <!-- transition all properties -->
transition-colors       <!-- transition color properties -->
transition-opacity
transition-shadow
transition-transform
transition-all

<!-- Duration -->
duration-75
duration-100
duration-150
duration-200
duration-300
duration-500
duration-700
duration-1000

<!-- Timing -->
ease-linear
ease-in
ease-out
ease-in-out

<!-- Delay -->
delay-75
delay-100
delay-150
delay-200
delay-300
```

**Example:**
```html
<button class="transition duration-300 ease-in-out hover:bg-blue-600">
  Button
</button>
```

---

## Transforms

```html
<!-- Scale -->
scale-0, scale-50, scale-75, scale-90, scale-95
scale-100       <!-- default -->
scale-105, scale-110, scale-125, scale-150

<!-- Rotate -->
rotate-0, rotate-45, rotate-90, rotate-180
-rotate-45      <!-- negative rotation -->

<!-- Translate -->
translate-x-0, translate-x-1, translate-x-4
translate-y-0, translate-y-1, translate-y-4
-translate-x-1  <!-- negative translation -->

<!-- Skew -->
skew-x-0, skew-x-3, skew-x-6, skew-x-12
skew-y-0, skew-y-3, skew-y-6, skew-y-12
```

**Example:**
```html
<div class="transform hover:scale-110 hover:rotate-6 transition">
  Hover me
</div>
```

---

## Animations

```html
animate-none
animate-spin        <!-- continuous spin -->
animate-ping        <!-- ping effect -->
animate-pulse       <!-- pulse effect -->
animate-bounce      <!-- bounce effect -->
```

---

## Filters

```html
<!-- Blur -->
blur-none, blur-sm, blur, blur-md, blur-lg, blur-xl, blur-2xl, blur-3xl

<!-- Brightness -->
brightness-0, brightness-50, brightness-75, brightness-100, brightness-125

<!-- Contrast -->
contrast-0, contrast-50, contrast-100, contrast-125

<!-- Grayscale -->
grayscale-0, grayscale

<!-- Invert -->
invert-0, invert

<!-- Saturate -->
saturate-0, saturate-50, saturate-100, saturate-150
```

---

## Common Patterns

### Centered Container

```html
<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
  Content
</div>
```

### Card

```html
<div class="bg-white rounded-lg shadow-md p-6">
  <h3 class="text-xl font-bold mb-2">Title</h3>
  <p class="text-gray-600">Description</p>
</div>
```

### Button

```html
<button class="bg-blue-600 hover:bg-blue-700 text-white font-semibold px-6 py-3 rounded-lg transition">
  Button
</button>
```

### Flexbox Center

```html
<div class="flex items-center justify-center h-screen">
  Centered content
</div>
```

### Grid Layout

```html
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
  <div>Item 1</div>
  <div>Item 2</div>
  <div>Item 3</div>
</div>
```

### Responsive Text

```html
<h1 class="text-2xl md:text-3xl lg:text-4xl font-bold">
  Responsive Heading
</h1>
```

### Form Input

```html
<input
  type="text"
  class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
/>
```

### Badge

```html
<span class="inline-flex items-center px-3 py-1 rounded-full text-sm font-semibold bg-blue-100 text-blue-800">
  Badge
</span>
```

### Avatar

```html
<img
  src="/avatar.jpg"
  alt="Avatar"
  class="w-12 h-12 rounded-full"
/>
```

---

## Configuration Tips

### Extend Theme

```javascript
// tailwind.config.js
module.exports = {
  theme: {
    extend: {
      colors: {
        brand: '#3b82f6',
      },
      spacing: {
        '128': '32rem',
      },
    },
  },
}
```

### Custom Utilities

```javascript
// tailwind.config.js
module.exports = {
  plugins: [
    function({ addUtilities }) {
      addUtilities({
        '.text-shadow': {
          'text-shadow': '2px 2px 4px rgba(0,0,0,0.1)',
        },
      })
    },
  ],
}
```

---

## CLI Commands

```bash
# Initialize
npx tailwindcss init
npx tailwindcss init -p          # with PostCSS config

# Build
npx tailwindcss -i input.css -o output.css

# Watch
npx tailwindcss -i input.css -o output.css --watch

# Minify
npx tailwindcss -i input.css -o output.css --minify
```

---

## Arbitrary Values

```html
<!-- JIT mode allows arbitrary values -->
<div class="w-[137px]">Custom width</div>
<div class="bg-[#bada55]">Custom color</div>
<div class="top-[117px]">Custom position</div>
<div class="text-[22px]">Custom font size</div>
```

---

## Important Modifier

```html
<!-- Add ! to make utility !important -->
<div class="!text-red-500">
  Always red, even if overridden
</div>
```

---

## Print Styles

```html
<div class="hidden print:block">
  Only visible when printing
</div>
```

---

## Screen Reader Only

```html
<span class="sr-only">
  Hidden visually, but read by screen readers
</span>
```

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1 | **For full examples see:** [01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md)
