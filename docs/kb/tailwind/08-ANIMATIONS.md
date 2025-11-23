---
id: tailwind-animations
topic: tailwind
file_role: guide
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [tailwind-fundamentals, tailwind-utility-classes, tailwind-customization]
related_topics: [animations, transitions, transforms, keyframes, hover-effects]
embedding_keywords: [tailwind, animations, transitions, transforms, keyframes, hover, motion, loading]
last_reviewed: 2025-11-16
---

# Tailwind CSS - Animations and Transitions

Creating smooth animations and transitions with Tailwind CSS utility classes.

## Overview

Tailwind CSS provides utility classes for transitions, transforms, and animations. You can create smooth hover effects, loading states, and complex animations without writing custom CSS.

---

## Transitions

### Basic Transition

```html
<!-- Transition all properties -->
<button class="bg-blue-500 text-white px-6 py-3 rounded-lg transition hover:bg-blue-600">
  Hover Me
</button>

<!-- Transition specific properties -->
<button class="bg-blue-500 text-white px-6 py-3 rounded-lg transition-colors hover:bg-blue-600">
  Colors Only
</button>

<button class="bg-blue-500 text-white px-6 py-3 rounded-lg transition-transform hover:scale-110">
  Transform Only
</button>
```

### Transition Properties

```html
<!-- transition-all: all properties -->
<div class="transition-all hover:bg-blue-500 hover:scale-110"></div>

<!-- transition-colors: background, border, text colors -->
<div class="transition-colors hover:bg-blue-500"></div>

<!-- transition-opacity: opacity only -->
<div class="transition-opacity hover:opacity-50"></div>

<!-- transition-shadow: box-shadow only -->
<div class="transition-shadow hover:shadow-lg"></div>

<!-- transition-transform: transform only -->
<div class="transition-transform hover:scale-110"></div>
```

### Transition Duration

```html
<!-- Default: 150ms -->
<button class="transition hover:bg-blue-600">Default (150ms)</button>

<!-- duration-75: 75ms -->
<button class="transition duration-75 hover:bg-blue-600">Fast (75ms)</button>

<!-- duration-300: 300ms -->
<button class="transition duration-300 hover:bg-blue-600">Medium (300ms)</button>

<!-- duration-500: 500ms -->
<button class="transition duration-500 hover:bg-blue-600">Slow (500ms)</button>

<!-- duration-1000: 1000ms -->
<button class="transition duration-1000 hover:bg-blue-600">Very Slow (1s)</button>
```

### Transition Timing Functions

```html
<!-- ease-linear: linear -->
<div class="transition duration-300 ease-linear"></div>

<!-- ease-in: starts slow, ends fast -->
<div class="transition duration-300 ease-in"></div>

<!-- ease-out: starts fast, ends slow -->
<div class="transition duration-300 ease-out"></div>

<!-- ease-in-out: slow start and end -->
<div class="transition duration-300 ease-in-out"></div>
```

### Transition Delay

```html
<!-- delay-75: 75ms delay -->
<div class="transition delay-75 hover:bg-blue-500"></div>

<!-- delay-150: 150ms delay -->
<div class="transition delay-150 hover:bg-blue-500"></div>

<!-- delay-300: 300ms delay -->
<div class="transition delay-300 hover:bg-blue-500"></div>

<!-- delay-500: 500ms delay -->
<div class="transition delay-500 hover:bg-blue-500"></div>
```

---

## Transforms

### Scale

```html
<!-- Scale up on hover -->
<div class="transition-transform hover:scale-110">
  <img src="/image.jpg" alt="Image" class="rounded-lg" />
</div>

<!-- Scale down on hover -->
<button class="transition-transform active:scale-95 bg-blue-500 text-white px-6 py-3 rounded-lg">
  Click Me
</button>

<!-- Different scale values -->
<div class="hover:scale-50">50%</div>
<div class="hover:scale-75">75%</div>
<div class="hover:scale-90">90%</div>
<div class="hover:scale-95">95%</div>
<div class="hover:scale-100">100% (default)</div>
<div class="hover:scale-105">105%</div>
<div class="hover:scale-110">110%</div>
<div class="hover:scale-125">125%</div>
<div class="hover:scale-150">150%</div>
```

### Rotate

```html
<!-- Rotate on hover -->
<div class="transition-transform hover:rotate-45">
  <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"></path>
  </svg>
</div>

<!-- Rotation values -->
<div class="hover:rotate-0">0°</div>
<div class="hover:rotate-45">45°</div>
<div class="hover:rotate-90">90°</div>
<div class="hover:rotate-180">180°</div>
<div class="hover:-rotate-45">-45°</div>
<div class="hover:-rotate-90">-90°</div>
<div class="hover:-rotate-180">-180°</div>
```

### Translate

```html
<!-- Translate on hover -->
<button class="transition-transform hover:translate-x-2 bg-blue-500 text-white px-6 py-3 rounded-lg">
  Slide Right →
</button>

<button class="transition-transform hover:-translate-y-2 bg-blue-500 text-white px-6 py-3 rounded-lg">
  Slide Up ↑
</button>

<!-- Translation values -->
<div class="hover:translate-x-0">0</div>
<div class="hover:translate-x-1">4px</div>
<div class="hover:translate-x-2">8px</div>
<div class="hover:translate-x-4">16px</div>
<div class="hover:translate-y-0">0</div>
<div class="hover:translate-y-1">4px</div>
<div class="hover:-translate-x-1">-4px</div>
<div class="hover:-translate-y-2">-8px</div>
```

### Skew

```html
<!-- Skew on hover -->
<div class="transition-transform hover:skew-x-12">
  Skewed Element
</div>

<!-- Skew values -->
<div class="hover:skew-x-0">0°</div>
<div class="hover:skew-x-3">3°</div>
<div class="hover:skew-x-6">6°</div>
<div class="hover:skew-x-12">12°</div>
<div class="hover:skew-y-3">3° Y</div>
<div class="hover:-skew-x-12">-12°</div>
```

### Combined Transforms

```html
<!-- Multiple transforms on hover -->
<div class="transition-transform hover:scale-110 hover:rotate-6 hover:translate-x-2">
  <img src="/card.jpg" alt="Card" class="rounded-lg shadow-lg" />
</div>

<!-- Card with lift effect -->
<div class="transition-all duration-300 hover:scale-105 hover:-translate-y-2 hover:shadow-2xl bg-white rounded-lg p-6">
  <h3 class="text-xl font-bold mb-2">Card Title</h3>
  <p class="text-gray-600">Hover for lift effect</p>
</div>
```

---

## Built-in Animations

### Spin

```html
<!-- Infinite spin -->
<svg class="animate-spin h-8 w-8 text-blue-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
  <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
  <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
</svg>

<!-- Loading button -->
<button class="bg-blue-500 text-white px-6 py-3 rounded-lg flex items-center" disabled>
  <svg class="animate-spin -ml-1 mr-3 h-5 w-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
    <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
    <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
  </svg>
  Processing...
</button>
```

### Ping

```html
<!-- Notification dot with ping -->
<div class="relative inline-flex">
  <button class="bg-blue-500 text-white px-6 py-3 rounded-lg">
    Notifications
  </button>
  <span class="absolute top-0 right-0 flex h-3 w-3">
    <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-red-400 opacity-75"></span>
    <span class="relative inline-flex rounded-full h-3 w-3 bg-red-500"></span>
  </span>
</div>
```

### Pulse

```html
<!-- Pulsing indicator -->
<div class="flex items-center space-x-3">
  <span class="relative flex h-3 w-3">
    <span class="animate-pulse absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75"></span>
    <span class="relative inline-flex rounded-full h-3 w-3 bg-green-500"></span>
  </span>
  <span class="text-sm text-gray-600">Live</span>
</div>

<!-- Pulsing button -->
<button class="animate-pulse bg-red-500 text-white px-6 py-3 rounded-lg">
  Live Stream
</button>
```

### Bounce

```html
<!-- Bouncing arrow -->
<div class="flex flex-col items-center">
  <p class="mb-4">Scroll Down</p>
  <svg class="animate-bounce w-6 h-6 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 14l-7 7m0 0l-7-7m7 7V3"></path>
  </svg>
</div>
```

---

## Custom Animations

### Keyframe Animations

```javascript
// tailwind.config.js
module.exports = {
  theme: {
    extend: {
      keyframes: {
        wiggle: {
          '0%, 100%': { transform: 'rotate(-3deg)' },
          '50%': { transform: 'rotate(3deg)' },
        },
        slideIn: {
          '0%': { transform: 'translateX(-100%)', opacity: '0' },
          '100%': { transform: 'translateX(0)', opacity: '1' },
        },
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        scaleIn: {
          '0%': { transform: 'scale(0.9)', opacity: '0' },
          '100%': { transform: 'scale(1)', opacity: '1' },
        },
      },
      animation: {
        wiggle: 'wiggle 1s ease-in-out infinite',
        slideIn: 'slideIn 0.3s ease-out',
        fadeIn: 'fadeIn 0.5s ease-in',
        scaleIn: 'scaleIn 0.2s ease-out',
      },
    },
  },
}
```

### Using Custom Animations

```html
<!-- Wiggle animation -->
<button class="hover:animate-wiggle bg-yellow-500 text-white px-6 py-3 rounded-lg">
  Hover to Wiggle
</button>

<!-- Slide in animation -->
<div class="animate-slideIn bg-white rounded-lg shadow-lg p-6">
  <h3 class="text-xl font-bold">Welcome!</h3>
  <p class="text-gray-600">This element slides in from the left.</p>
</div>

<!-- Fade in animation -->
<div class="animate-fadeIn bg-white rounded-lg shadow-lg p-6">
  <h3 class="text-xl font-bold">Hello!</h3>
  <p class="text-gray-600">This element fades in smoothly.</p>
</div>

<!-- Scale in animation -->
<div class="animate-scaleIn bg-white rounded-lg shadow-lg p-6">
  <h3 class="text-xl font-bold">Pop!</h3>
  <p class="text-gray-600">This element scales in from small.</p>
</div>
```

---

## Loading States

### Spinner Variations

```html
<!-- Circle Spinner -->
<div class="flex justify-center items-center">
  <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500"></div>
</div>

<!-- Dots Spinner -->
<div class="flex space-x-2">
  <div class="w-3 h-3 bg-blue-500 rounded-full animate-bounce" style="animation-delay: 0s"></div>
  <div class="w-3 h-3 bg-blue-500 rounded-full animate-bounce" style="animation-delay: 0.1s"></div>
  <div class="w-3 h-3 bg-blue-500 rounded-full animate-bounce" style="animation-delay: 0.2s"></div>
</div>

<!-- Pulse Circles -->
<div class="flex justify-center items-center space-x-2">
  <div class="w-4 h-4 bg-blue-500 rounded-full animate-pulse"></div>
  <div class="w-4 h-4 bg-blue-500 rounded-full animate-pulse" style="animation-delay: 0.2s"></div>
  <div class="w-4 h-4 bg-blue-500 rounded-full animate-pulse" style="animation-delay: 0.4s"></div>
</div>
```

### Skeleton Loaders

```html
<!-- Basic skeleton -->
<div class="bg-white rounded-lg shadow p-6">
  <div class="animate-pulse space-y-4">
    <!-- Header -->
    <div class="h-4 bg-gray-200 rounded w-3/4"></div>

    <!-- Lines -->
    <div class="space-y-2">
      <div class="h-3 bg-gray-200 rounded"></div>
      <div class="h-3 bg-gray-200 rounded w-5/6"></div>
      <div class="h-3 bg-gray-200 rounded w-4/6"></div>
    </div>
  </div>
</div>

<!-- Card skeleton -->
<div class="bg-white rounded-lg shadow overflow-hidden">
  <div class="animate-pulse">
    <!-- Image placeholder -->
    <div class="h-48 bg-gray-200"></div>

    <!-- Content -->
    <div class="p-6 space-y-4">
      <div class="h-4 bg-gray-200 rounded w-3/4"></div>
      <div class="space-y-2">
        <div class="h-3 bg-gray-200 rounded"></div>
        <div class="h-3 bg-gray-200 rounded w-5/6"></div>
      </div>
      <div class="h-8 bg-gray-200 rounded w-1/3"></div>
    </div>
  </div>
</div>

<!-- Profile skeleton -->
<div class="flex items-center space-x-4">
  <div class="animate-pulse flex items-center space-x-4 w-full">
    <div class="rounded-full bg-gray-200 h-12 w-12"></div>
    <div class="flex-1 space-y-2">
      <div class="h-4 bg-gray-200 rounded w-3/4"></div>
      <div class="h-3 bg-gray-200 rounded w-1/2"></div>
    </div>
  </div>
</div>
```

### Progress Bars

```html
<!-- Indeterminate progress -->
<div class="w-full bg-gray-200 rounded-full h-2.5 dark:bg-gray-700 overflow-hidden">
  <div class="bg-blue-600 h-2.5 rounded-full animate-pulse" style="width: 45%"></div>
</div>

<!-- Animated progress bar -->
<div class="relative w-full bg-gray-200 rounded-full h-2.5 overflow-hidden">
  <div class="absolute h-full bg-gradient-to-r from-blue-400 to-blue-600 animate-pulse" style="width: 60%"></div>
</div>

<!-- Sliding progress bar -->
<style>
@keyframes slideProgress {
  0% { transform: translateX(-100%); }
  100% { transform: translateX(400%); }
}
</style>

<div class="w-full bg-gray-200 rounded-full h-2.5 overflow-hidden">
  <div class="h-full w-1/4 bg-gradient-to-r from-transparent via-blue-500 to-transparent" style="animation: slideProgress 1.5s infinite"></div>
</div>
```

---

## Hover Effects

### Card Hover Effects

```html
<!-- Lift and shadow on hover -->
<div class="bg-white rounded-lg shadow-md p-6 transition-all duration-300 hover:shadow-2xl hover:-translate-y-2">
  <h3 class="text-xl font-bold mb-2">Hover Me</h3>
  <p class="text-gray-600">I lift up on hover!</p>
</div>

<!-- Glow effect on hover -->
<div class="bg-white rounded-lg p-6 transition-all duration-300 hover:shadow-[0_0_30px_rgba(59,130,246,0.5)] border-2 border-transparent hover:border-blue-500">
  <h3 class="text-xl font-bold mb-2">Glow Effect</h3>
  <p class="text-gray-600">I glow on hover!</p>
</div>

<!-- Tilt effect (requires custom CSS) -->
<div class="bg-white rounded-lg shadow-lg p-6 transition-transform duration-300 hover:rotate-2 hover:scale-105">
  <h3 class="text-xl font-bold mb-2">Tilt Effect</h3>
  <p class="text-gray-600">I tilt on hover!</p>
</div>
```

### Button Hover Effects

```html
<!-- Slide background -->
<button class="relative px-6 py-3 rounded-lg overflow-hidden bg-blue-500 text-white font-semibold transition-all hover:bg-blue-600 group">
  <span class="relative z-10">Hover Me</span>
  <span class="absolute inset-0 bg-blue-700 transform -translate-x-full group-hover:translate-x-0 transition-transform duration-300"></span>
</button>

<!-- Border grow -->
<button class="relative px-6 py-3 rounded-lg bg-transparent border-2 border-blue-500 text-blue-500 font-semibold overflow-hidden group hover:text-white transition-colors duration-300">
  <span class="relative z-10">Hover Me</span>
  <span class="absolute inset-0 bg-blue-500 transform scale-0 group-hover:scale-100 transition-transform duration-300"></span>
</button>

<!-- Shine effect -->
<button class="relative px-6 py-3 rounded-lg bg-gradient-to-r from-blue-500 to-purple-600 text-white font-semibold overflow-hidden group">
  <span class="relative z-10">Hover Me</span>
  <span class="absolute inset-0 bg-white opacity-0 group-hover:opacity-20 transform -skew-x-12 -translate-x-full group-hover:translate-x-full transition-all duration-700"></span>
</button>
```

### Image Hover Effects

```html
<!-- Zoom on hover -->
<div class="overflow-hidden rounded-lg">
  <img src="/image.jpg" alt="Image" class="w-full h-full object-cover transition-transform duration-500 hover:scale-110" />
</div>

<!-- Grayscale to color -->
<div class="overflow-hidden rounded-lg">
  <img src="/image.jpg" alt="Image" class="w-full h-full object-cover grayscale hover:grayscale-0 transition-all duration-300" />
</div>

<!-- Overlay on hover -->
<div class="relative group overflow-hidden rounded-lg">
  <img src="/image.jpg" alt="Image" class="w-full h-full object-cover" />
  <div class="absolute inset-0 bg-black bg-opacity-0 group-hover:bg-opacity-50 transition-all duration-300 flex items-center justify-center">
    <button class="opacity-0 group-hover:opacity-100 bg-white text-gray-900 px-6 py-3 rounded-lg font-semibold transform translate-y-4 group-hover:translate-y-0 transition-all duration-300">
      View Details
    </button>
  </div>
</div>
```

---

## Performance Considerations

### GPU Acceleration

```html
<!-- Use transform instead of top/left for better performance -->
<!-- ❌ Avoid -->
<div class="hover:top-2"></div>

<!-- ✅ Prefer -->
<div class="hover:translate-y-2"></div>

<!-- Use transform: scale instead of width/height -->
<!-- ❌ Avoid -->
<div class="hover:w-64 hover:h-64"></div>

<!-- ✅ Prefer -->
<div class="hover:scale-110"></div>
```

### Reduced Motion

```html
<!-- Respect user's motion preferences -->
<div class="transition-transform hover:scale-110 motion-reduce:transition-none motion-reduce:hover:scale-100">
  Respects motion preferences
</div>

<!-- Custom config -->
```javascript
// tailwind.config.js
module.exports = {
  theme: {
    extend: {
      // Add custom animations that respect reduced motion
    },
  },
  variants: {
    extend: {
      animation: ['motion-reduce'],
      transition: ['motion-reduce'],
    },
  },
}
```

---

## AI Pair Programming Notes

**When to load this KB:**
- Creating animations and transitions
- Implementing loading states
- Adding hover effects
- Building interactive components

**Common starting points:**
- Basic transitions: See Transitions
- Hover effects: See Hover Effects
- Loading states: See Loading States
- Custom animations: See Custom Animations

**Typical questions:**
- "How do I add transitions?" → Transitions → Basic Transition
- "How do I create a spinner?" → Loading States → Spinner Variations
- "How do I make hover effects?" → Hover Effects
- "How do I create custom animations?" → Custom Animations → Keyframe Animations

**Related topics:**
- Transforms: See Transforms section
- Customization: See `04-CUSTOMIZATION.md`
- Components: See `05-LAYOUT-PATTERNS.md`

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1
