---
id: tailwind-config-operations
topic: tailwind
file_role: guide
profile: full
difficulty_level: advanced
kb_version: 3.1
prerequisites: [tailwind-fundamentals, tailwind-customization, tailwind-integrations]
related_topics: [configuration, optimization, debugging, cli, devtools]
embedding_keywords: [tailwind, config, production, optimization, debugging, cli, vscode, devtools]
last_reviewed: 2025-11-16
---

# Tailwind CSS - Configuration & Operations

Production configuration, optimization, debugging, and operational best practices for Tailwind CSS.

## Overview

This guide covers advanced configuration, build optimization, debugging tools, and operational practices for production Tailwind CSS projects.

---

## Production Configuration

### Environment-Specific Config

```javascript
// tailwind.config.js
const isProduction = process.env.NODE_ENV === 'production'

module.exports = {
  content: [
    './src/**/*.{js,jsx,ts,tsx}',
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        primary: '#3b82f6',
        secondary: '#10b981',
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
  ],
  // Production-only optimizations
  ...(isProduction && {
    safelist: [],
    blocklist: [],
  }),
}
```

### Multiple Config Files

```javascript
// tailwind.config.base.js (shared config)
module.exports = {
  theme: {
    extend: {
      colors: {
        brand: {
          50: '#eff6ff',
          500: '#3b82f6',
          900: '#1e3a8a',
        },
      },
    },
  },
}

// tailwind.config.js (main config)
const baseConfig = require('./tailwind.config.base')

module.exports = {
  ...baseConfig,
  content: ['./src/**/*.{js,jsx,ts,tsx}'],
  plugins: [
    require('@tailwindcss/forms'),
  ],
}
```

---

## Performance Optimization

### Content Configuration

```javascript
// tailwind.config.js
module.exports = {
  content: [
    // Be specific to reduce scanning time
    './src/components/**/*.{js,jsx,ts,tsx}',
    './src/pages/**/*.{js,jsx,ts,tsx}',
    './src/app/**/*.{js,jsx,ts,tsx}',

    // Avoid scanning unnecessary files
    // ❌ Don't do this: './src/**/*'
    // ✅ Do this: './src/**/*.{js,jsx,ts,tsx}'

    // Exclude files that don't contain classes
    '!./src/**/*.test.{js,jsx,ts,tsx}',
    '!./src/**/*.spec.{js,jsx,ts,tsx}',

    // Include external libraries if needed
    './node_modules/@mycompany/ui-lib/**/*.js',
  ],
}
```

### Safelist Configuration

```javascript
// tailwind.config.js
module.exports = {
  safelist: [
    // Always include these classes
    'bg-red-500',
    'bg-green-500',
    'bg-blue-500',

    // Pattern-based safelist
    {
      pattern: /bg-(red|green|blue)-(100|500|900)/,
    },

    // With variants
    {
      pattern: /bg-(red|green|blue)-(100|500|900)/,
      variants: ['lg', 'hover', 'focus'],
    },

    // Safelist entire groups
    {
      pattern: /^bg-/,
      variants: ['hover'],
    },
  ],
}
```

### Disabling Unused Core Plugins

```javascript
// tailwind.config.js
module.exports = {
  corePlugins: {
    // Disable plugins you don't use
    float: false,
    objectFit: false,
    objectPosition: false,
    textDecoration: false,
    textTransform: false,
    verticalAlign: false,
    writingMode: false,
  },
}
```

### CSS Minification

```javascript
// postcss.config.js
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
    ...(process.env.NODE_ENV === 'production' && {
      cssnano: {
        preset: ['default', {
          discardComments: {
            removeAll: true,
          },
        }],
      },
    }),
  },
}
```

---

## CLI Commands

### Initialize Tailwind

```bash
# Create tailwind.config.js
npx tailwindcss init

# Create tailwind.config.js and postcss.config.js
npx tailwindcss init -p

# Create full config with all defaults
npx tailwindcss init --full

# Create TypeScript config
npx tailwindcss init --ts
```

### Build Commands

```bash
# Watch for changes (development)
npx tailwindcss -i ./src/input.css -o ./dist/output.css --watch

# Build for production (minified)
NODE_ENV=production npx tailwindcss -i ./src/input.css -o ./dist/output.css --minify

# Build with custom config
npx tailwindcss -i ./src/input.css -o ./dist/output.css -c ./tailwind.custom.config.js
```

### NPM Scripts

```json
{
  "scripts": {
    "dev": "tailwindcss -i ./src/input.css -o ./dist/output.css --watch",
    "build": "NODE_ENV=production tailwindcss -i ./src/input.css -o ./dist/output.css --minify",
    "build:css": "tailwindcss -i ./src/input.css -o ./dist/output.css"
  }
}
```

---

## VS Code Setup

### Extensions

```json
// .vscode/extensions.json
{
  "recommendations": [
    "bradlc.vscode-tailwindcss",
    "esbenp.prettier-vscode"
  ]
}
```

### VS Code Settings

```json
// .vscode/settings.json
{
  // Enable IntelliSense for Tailwind classes
  "tailwindCSS.experimental.classRegex": [
    ["cva\\(([^)]*)\\)", "[\"'`]([^\"'`]*).*?[\"'`]"],
    ["clsx\\(([^)]*)\\)", "(?:'|\"|`)([^']*)(?:'|\"|`)"]
  ],

  // Enable suggestions in strings
  "editor.quickSuggestions": {
    "strings": true
  },

  // Emmet support
  "emmet.includeLanguages": {
    "javascript": "javascriptreact",
    "typescript": "typescriptreact"
  },

  // Format on save
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",

  // Tailwind CSS IntelliSense
  "tailwindCSS.includeLanguages": {
    "typescript": "javascript",
    "typescriptreact": "javascript"
  },

  // Validate CSS
  "css.validate": false,
  "less.validate": false,
  "scss.validate": false
}
```

### IntelliSense Configuration

```javascript
// tailwind.config.js
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./src/**/*.{js,jsx,ts,tsx}'],
  theme: {
    extend: {},
  },
  plugins: [],
}
```

---

## Debugging Tools

### Browser DevTools

```html
<!-- Add Tailwind Play CDN for quick debugging -->
<script src="https://cdn.tailwindcss.com"></script>

<!-- Configure via script tag -->
<script>
  tailwind.config = {
    theme: {
      extend: {
        colors: {
          primary: '#3b82f6',
        }
      }
    }
  }
</script>
```

### Debug Screens

```javascript
// tailwind.config.js
module.exports = {
  plugins: [
    function({ addComponents }) {
      addComponents({
        '.debug-screens::before': {
          position: 'fixed',
          zIndex: '2147483647',
          bottom: '0',
          left: '0',
          padding: '.3333333em .5em',
          fontSize: '12px',
          lineHeight: '1',
          fontFamily: 'sans-serif',
          backgroundColor: '#000',
          color: '#fff',
          boxShadow: '0 0 0 1px #fff',
          content: '"screen: _"',
          '@screen sm': {
            content: '"screen: sm"',
          },
          '@screen md': {
            content: '"screen: md"',
          },
          '@screen lg': {
            content: '"screen: lg"',
          },
          '@screen xl': {
            content: '"screen: xl"',
          },
          '@screen 2xl': {
            content: '"screen: 2xl"',
          },
        },
      })
    },
  ],
}
```

```html
<!-- Add to your layout in development -->
<body class="debug-screens">
  <!-- Your app -->
</body>
```

### CSS Analysis

```bash
# Analyze generated CSS size
npx tailwindcss -i ./src/input.css -o ./dist/output.css
du -h ./dist/output.css

# View detailed stats
npx tailwindcss -i ./src/input.css -o ./dist/output.css --verbose
```

---

## Troubleshooting

### Classes Not Generating

```javascript
// 1. Check content paths
module.exports = {
  content: [
    './src/**/*.{js,jsx,ts,tsx}', // ✅ Correct
    // './src/**/*', // ❌ Too broad
  ],
}

// 2. Verify template literals are detected
module.exports = {
  content: {
    files: ['./src/**/*.{js,jsx,ts,tsx}'],
    extract: {
      // Custom extractor for dynamic classes
      js: (content) => {
        return content.match(/[^<>"'`\s]*[^<>"'`\s:]/g) || []
      },
    },
  },
}

// 3. Use safelist for dynamic classes
module.exports = {
  safelist: [
    'bg-red-500',
    {
      pattern: /bg-(red|green|blue)-500/,
    },
  ],
}
```

### Styles Not Applying

```css
/* 1. Check CSS import order */
@tailwind base;
@tailwind components;
@tailwind utilities;

/* Custom styles should come after utilities */
.my-custom-class {
  /* Custom CSS */
}
```

```javascript
// 2. Check for CSS conflicts
module.exports = {
  important: true, // Use !important for all utilities
  // Or scope to a selector
  important: '#app',
}
```

### Build Performance Issues

```javascript
// 1. Optimize content paths
module.exports = {
  content: [
    './src/components/**/*.{js,jsx,ts,tsx}',
    './src/pages/**/*.{js,jsx,ts,tsx}',
    // Don't scan node_modules unless necessary
  ],
}

// 2. Use JIT mode (default in v3)
// JIT is enabled by default, no configuration needed

// 3. Disable source maps in production
```

```javascript
// postcss.config.js
module.exports = {
  map: process.env.NODE_ENV !== 'production',
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
```

---

## Migration Guides

### Migrating from v2 to v3

```javascript
// Before (v2)
module.exports = {
  purge: ['./src/**/*.{js,jsx,ts,tsx}'],
  darkMode: false,
  theme: {
    extend: {},
  },
  variants: {
    extend: {},
  },
  plugins: [],
}

// After (v3)
module.exports = {
  content: ['./src/**/*.{js,jsx,ts,tsx}'], // Changed from 'purge'
  darkMode: 'media', // Changed from boolean
  theme: {
    extend: {},
  },
  // variants are no longer needed (all variants enabled in JIT)
  plugins: [],
}
```

### Key Changes in v3

1. **JIT mode is default** - No configuration needed
2. **All variants enabled** - No need to configure variants
3. **New color palette** - Updated default colors
4. **Performance improvements** - Faster builds
5. **New arbitrary values** - `w-[137px]`, `bg-[#bada55]`

---

## Best Practices

### Config Organization

```javascript
// tailwind.config.js
const colors = require('tailwindcss/colors')

module.exports = {
  content: ['./src/**/*.{js,jsx,ts,tsx}'],

  darkMode: 'class',

  theme: {
    // Override defaults
    colors: {
      transparent: 'transparent',
      current: 'currentColor',
      black: colors.black,
      white: colors.white,
      gray: colors.gray,
      blue: colors.blue,
    },

    // Extend defaults
    extend: {
      colors: {
        primary: '#3b82f6',
        secondary: '#10b981',
      },
      spacing: {
        '128': '32rem',
        '144': '36rem',
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

### Version Control

```gitignore
# .gitignore
# Don't commit generated CSS
/dist/output.css
/dist/output.css.map

# Don't commit full config (if using init --full)
# tailwind.config.full.js

# Node modules
node_modules/
```

### Documentation

```javascript
// tailwind.config.js
/**
 * Tailwind CSS Configuration
 *
 * @see https://tailwindcss.com/docs/configuration
 */

module.exports = {
  content: [
    // Scan all component files for class names
    './src/components/**/*.{js,jsx,ts,tsx}',
    './src/pages/**/*.{js,jsx,ts,tsx}',
  ],

  theme: {
    extend: {
      // Brand colors from design system
      colors: {
        primary: '#3b82f6', // Blue
        secondary: '#10b981', // Green
        accent: '#f59e0b', // Amber
      },
    },
  },

  plugins: [],
}
```

---

## Monitoring & Analytics

### Bundle Size Monitoring

```json
{
  "scripts": {
    "build": "tailwindcss build src/styles.css -o dist/styles.css",
    "analyze": "tailwindcss build src/styles.css -o dist/styles.css && du -h dist/styles.css"
  }
}
```

### CI/CD Integration

```yaml
# .github/workflows/ci.yml
name: CI

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Node
        uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Install dependencies
        run: npm ci

      - name: Build CSS
        run: npm run build:css

      - name: Check CSS size
        run: |
          SIZE=$(du -k dist/output.css | cut -f1)
          echo "CSS size: ${SIZE}KB"
          if [ $SIZE -gt 50 ]; then
            echo "Warning: CSS bundle is larger than 50KB"
          fi
```

---

## Testing Configuration

### Jest Setup

```javascript
// jest.config.js
module.exports = {
  moduleNameMapper: {
    // Mock CSS imports
    '\\.(css|less|scss|sass)$': 'identity-obj-proxy',
  },
  setupFilesAfterEnv: ['<rootDir>/jest.setup.js'],
}
```

```javascript
// jest.setup.js
// Add global styles for testing
import '@testing-library/jest-dom'
import './src/styles/globals.css'
```

---

## AI Pair Programming Notes

**When to load this KB:**
- Setting up production configuration
- Optimizing Tailwind builds
- Debugging Tailwind issues
- Configuring development tools

**Common starting points:**
- Production config: See Production Configuration
- Performance: See Performance Optimization
- Debugging: See Debugging Tools
- VS Code: See VS Code Setup

**Typical questions:**
- "How do I optimize for production?" → Production Configuration
- "Why aren't my classes generating?" → Troubleshooting → Classes Not Generating
- "How do I set up VS Code?" → VS Code Setup
- "How do I migrate from v2 to v3?" → Migration Guides

**Related topics:**
- Customization: See `04-CUSTOMIZATION.md`
- Integration: See `10-INTEGRATIONS.md`
- Build tools: See PostCSS configuration

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1
