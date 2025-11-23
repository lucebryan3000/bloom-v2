---
id: tailwind-customization
topic: tailwind
file_role: guide
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [tailwind-fundamentals, tailwind-utility-classes]
related_topics: [configuration, theming, custom-utilities]
embedding_keywords: [tailwind, customization, config, theme, extend, plugins]
last_reviewed: 2025-11-16
---

# Tailwind CSS - Customization

Customizing Tailwind CSS through configuration, extending the theme, and creating custom utilities.

## Overview

Tailwind CSS is highly customizable through the `tailwind.config.js` file. You can customize colors, spacing, breakpoints, and add custom utilities without writing CSS.

---

## Configuration File

### Basic Structure

```javascript
// tailwind.config.js
module.exports = {
  content: [
    './pages/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
    './app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      // Your customizations here
    },
  },
  plugins: [],
}
```

### Content Configuration

```javascript
module.exports = {
  content: [
    // Scan all files in these directories
    './src/**/*.{js,jsx,ts,tsx}',
    './pages/**/*.{js,jsx,ts,tsx}',
    './components/**/*.{js,jsx,ts,tsx}',

    // Include specific files
    './app/layout.tsx',
    './app/page.tsx',

    // Use glob patterns
    './features/**/*.{js,tsx}',

    // Safelist classes (always include)
  ],
  safelist: [
    'bg-red-500',
    'text-3xl',
    {
      pattern: /bg-(red|green|blue)-(100|500|900)/,
    },
  ],
}
```

---

## Theme Customization

### Extending Colors

```javascript
// tailwind.config.js
module.exports = {
  theme: {
    extend: {
      colors: {
        // Add custom colors
        brand: {
          50: '#eff6ff',
          100: '#dbeafe',
          200: '#bfdbfe',
          300: '#93c5fd',
          400: '#60a5fa',
          500: '#3b82f6',
          600: '#2563eb',
          700: '#1d4ed8',
          800: '#1e40af',
          900: '#1e3a8a',
        },
        primary: '#3b82f6',
        secondary: '#10b981',
        danger: '#ef4444',

        // Using CSS variables
        background: 'var(--background)',
        foreground: 'var(--foreground)',
      },
    },
  },
}
```

### Replacing Colors

```javascript
module.exports = {
  theme: {
    // Replace default colors entirely
    colors: {
      transparent: 'transparent',
      current: 'currentColor',
      white: '#ffffff',
      black: '#000000',
      primary: {
        light: '#3fbaeb',
        DEFAULT: '#0fa9e6',
        dark: '#0c87b8',
      },
    },
  },
}
```

### Extending Spacing

```javascript
module.exports = {
  theme: {
    extend: {
      spacing: {
        '128': '32rem',
        '144': '36rem',
        '160': '40rem',
        '176': '44rem',
        '192': '48rem',
      },
    },
  },
}

// Usage: <div class="w-128 h-144">
```

### Custom Font Families

```javascript
module.exports = {
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
        serif: ['Georgia', 'serif'],
        mono: ['Fira Code', 'monospace'],
        display: ['Playfair Display', 'serif'],
      },
    },
  },
}

// Usage: <h1 class="font-display">
```

### Custom Font Sizes

```javascript
module.exports = {
  theme: {
    extend: {
      fontSize: {
        'xxs': '0.625rem',
        '3xs': '0.5rem',
        '10xl': '10rem',
      },
    },
  },
}
```

### Custom Breakpoints

```javascript
module.exports = {
  theme: {
    screens: {
      'xs': '475px',
      'sm': '640px',
      'md': '768px',
      'lg': '1024px',
      'xl': '1280px',
      '2xl': '1536px',
      '3xl': '1920px',

      // Custom breakpoints
      'tablet': '640px',
      'laptop': '1024px',
      'desktop': '1280px',

      // Max-width breakpoints
      'max-md': {'max': '767px'},

      // Range breakpoints
      'tablet-only': {'min': '640px', 'max': '1023px'},
    },
  },
}
```

### Box Shadows

```javascript
module.exports = {
  theme: {
    extend: {
      boxShadow: {
        'inner-lg': 'inset 0 2px 4px 0 rgba(0, 0, 0, 0.06)',
        'outline-blue': '0 0 0 3px rgba(66, 153, 225, 0.5)',
        'custom': '0 10px 40px rgba(0, 0, 0, 0.1)',
      },
    },
  },
}
```

### Border Radius

```javascript
module.exports = {
  theme: {
    extend: {
      borderRadius: {
        '4xl': '2rem',
        '5xl': '2.5rem',
      },
    },
  },
}
```

---

## Custom Utilities

### Using @layer

```css
/* styles/globals.css */
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer utilities {
  .scrollbar-hide {
    -ms-overflow-style: none;
    scrollbar-width: none;
  }

  .scrollbar-hide::-webkit-scrollbar {
    display: none;
  }

  .text-shadow {
    text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.1);
  }

  .rotate-y-180 {
    transform: rotateY(180deg);
  }
}
```

### Plugin-Based Utilities

```javascript
// tailwind.config.js
const plugin = require('tailwindcss/plugin')

module.exports = {
  plugins: [
    plugin(function({ addUtilities }) {
      const newUtilities = {
        '.text-stroke': {
          '-webkit-text-stroke': '1px black',
        },
        '.text-stroke-2': {
          '-webkit-text-stroke': '2px black',
        },
        '.clip-circle': {
          'clip-path': 'circle(50%)',
        },
      }

      addUtilities(newUtilities)
    }),
  ],
}
```

### Responsive & Variant Utilities

```javascript
const plugin = require('tailwindcss/plugin')

module.exports = {
  plugins: [
    plugin(function({ addUtilities, theme, variants }) {
      const newUtilities = {
        '.skew-10deg': {
          transform: 'skewY(-10deg)',
        },
        '.skew-15deg': {
          transform: 'skewY(-15deg)',
        },
      }

      addUtilities(newUtilities, ['responsive', 'hover'])
    }),
  ],
}

// Usage: <div class="skew-10deg md:skew-15deg hover:skew-0">
```

---

## Custom Components

### Component Classes

```css
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer components {
  .btn {
    @apply px-4 py-2 rounded font-semibold transition;
  }

  .btn-primary {
    @apply bg-blue-500 text-white hover:bg-blue-600;
  }

  .btn-secondary {
    @apply bg-gray-200 text-gray-800 hover:bg-gray-300;
  }

  .card {
    @apply bg-white rounded-lg shadow-md p-6;
  }

  .input-field {
    @apply w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500;
  }
}
```

### Component Plugin

```javascript
const plugin = require('tailwindcss/plugin')

module.exports = {
  plugins: [
    plugin(function({ addComponents, theme }) {
      const buttons = {
        '.btn': {
          padding: `${theme('spacing.2')} ${theme('spacing.4')}`,
          borderRadius: theme('borderRadius.md'),
          fontWeight: theme('fontWeight.semibold'),
          transition: 'all 0.2s',
        },
        '.btn-primary': {
          backgroundColor: theme('colors.blue.500'),
          color: theme('colors.white'),
          '&:hover': {
            backgroundColor: theme('colors.blue.600'),
          },
        },
      }

      addComponents(buttons)
    }),
  ],
}
```

---

## Plugins

### Official Plugins

```javascript
module.exports = {
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
    require('@tailwindcss/aspect-ratio'),
    require('@tailwindcss/container-queries'),
  ],
}
```

### @tailwindcss/forms

```html
<!-- Beautiful form elements with zero configuration -->
<form>
  <input type="text" class="form-input">
  <input type="checkbox" class="form-checkbox">
  <select class="form-select">
    <option>Option 1</option>
  </select>
</form>
```

### @tailwindcss/typography

```html
<!-- Beautiful typography for CMS content -->
<article class="prose lg:prose-xl">
  <h1>Heading</h1>
  <p>This will be beautifully styled automatically.</p>
</article>

<!-- Dark mode prose -->
<article class="prose dark:prose-invert">
  Content
</article>

<!-- Custom prose colors -->
<article class="prose prose-blue">
  Content with blue links
</article>
```

### Custom Plugin Example

```javascript
// tailwind.config.js
const plugin = require('tailwindcss/plugin')

module.exports = {
  plugins: [
    plugin(function({ addBase, addComponents, addUtilities, theme }) {
      // Add base styles
      addBase({
        'h1': { fontSize: theme('fontSize.2xl') },
        'h2': { fontSize: theme('fontSize.xl') },
      })

      // Add components
      addComponents({
        '.card': {
          backgroundColor: theme('colors.white'),
          borderRadius: theme('borderRadius.lg'),
          padding: theme('spacing.6'),
          boxShadow: theme('boxShadow.md'),
        },
      })

      // Add utilities
      addUtilities({
        '.content-auto': {
          contentVisibility: 'auto',
        },
      })
    }),
  ],
}
```

---

## CSS Variables Integration

### Setup

```css
/* globals.css */
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  :root {
    --background: 0 0% 100%;
    --foreground: 222.2 84% 4.9%;
    --primary: 221.2 83.2% 53.3%;
    --secondary: 210 40% 96.1%;
    --accent: 210 40% 96.1%;
    --destructive: 0 84.2% 60.2%;
  }

  .dark {
    --background: 222.2 84% 4.9%;
    --foreground: 210 40% 98%;
    --primary: 217.2 91.2% 59.8%;
    --secondary: 217.2 32.6% 17.5%;
    --accent: 217.2 32.6% 17.5%;
    --destructive: 0 62.8% 30.6%;
  }
}
```

### Config

```javascript
// tailwind.config.js
module.exports = {
  theme: {
    extend: {
      colors: {
        background: 'hsl(var(--background))',
        foreground: 'hsl(var(--foreground))',
        primary: {
          DEFAULT: 'hsl(var(--primary))',
          foreground: 'hsl(var(--primary-foreground))',
        },
        secondary: {
          DEFAULT: 'hsl(var(--secondary))',
          foreground: 'hsl(var(--secondary-foreground))',
        },
      },
    },
  },
}

// Usage: <div class="bg-background text-foreground">
```

---

## Theme Function

### Using in Config

```javascript
module.exports = {
  theme: {
    extend: {
      spacing: {
        '128': '32rem',
      },
      borderRadius: {
        '4xl': '2rem',
      },
    },
  },
  plugins: [
    plugin(function({ addComponents, theme }) {
      addComponents({
        '.card': {
          padding: theme('spacing.6'),
          borderRadius: theme('borderRadius.lg'),
          backgroundColor: theme('colors.white'),
        },
      })
    }),
  ],
}
```

---

## Presets

### Creating a Preset

```javascript
// my-preset.js
module.exports = {
  theme: {
    extend: {
      colors: {
        primary: '#3b82f6',
        secondary: '#10b981',
      },
      fontFamily: {
        sans: ['Inter', 'sans-serif'],
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
  ],
}
```

### Using a Preset

```javascript
// tailwind.config.js
module.exports = {
  presets: [
    require('./my-preset.js')
  ],
  theme: {
    extend: {
      // Additional customizations
    },
  },
}
```

---

## Production Optimization

### PurgeCSS Configuration

```javascript
module.exports = {
  content: [
    './pages/**/*.{js,ts,jsx,tsx}',
    './components/**/*.{js,ts,jsx,tsx}',
  ],
  // Safelist dynamic classes
  safelist: [
    'bg-red-500',
    'bg-green-500',
    {
      pattern: /bg-(red|green|blue)-(400|500|600)/,
      variants: ['hover', 'focus'],
    },
  ],
}
```

### Important Selector

```javascript
module.exports = {
  important: true, // Makes all utilities !important
  // Or use a selector
  important: '#app', // Scope to element
}
```

---

## Best Practices

### 1. Use Extend, Don't Replace

```javascript
// ✅ Good: Extend the default theme
module.exports = {
  theme: {
    extend: {
      colors: {
        brand: '#3b82f6',
      },
    },
  },
}

// ❌ Avoid: Replacing removes default colors
module.exports = {
  theme: {
    colors: {
      brand: '#3b82f6',
      // Lost all default colors!
    },
  },
}
```

### 2. Organize Custom Styles

```
styles/
  ├── globals.css        # Base, components, utilities
  ├── components.css     # Component classes
  └── utilities.css      # Custom utilities
```

### 3. Use Semantic Naming

```javascript
// ✅ Good: Semantic names
colors: {
  primary: '#3b82f6',
  secondary: '#10b981',
  danger: '#ef4444',
}

// ❌ Avoid: Generic names
colors: {
  blue: '#3b82f6',
  green: '#10b981',
  red: '#ef4444',
}
```

---

## AI Pair Programming Notes

**When to load this KB:**
- Customizing Tailwind configuration
- Adding custom colors or utilities
- Creating reusable component classes
- Integrating with design system

**Common starting points:**
- Colors: See Theme Customization → Extending Colors
- Custom utilities: See Custom Utilities section
- Plugins: See Plugins section
- CSS variables: See CSS Variables Integration

**Typical questions:**
- "How do I add custom colors?" → Theme Customization → Extending Colors
- "How do I create reusable components?" → Custom Components section
- "How do I add custom utilities?" → Custom Utilities section
- "How do I use CSS variables?" → CSS Variables Integration

**Related topics:**
- Dark mode: See `06-DARK-MODE.md`
- Configuration: See `11-CONFIG-OPERATIONS.md`
- Plugins: See official Tailwind docs

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1
