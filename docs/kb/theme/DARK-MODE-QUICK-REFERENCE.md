# Dark Mode Quick Reference

**TL;DR** - Centralized dark mode using `useTheme()` hook + Tailwind `dark:` prefix.

## Quick Start

### Check if Dark Mode is Enabled

```typescript
import { isDark } from '@/lib/theme/dark-mode-utils';

console.log(isDark()); // true or false
```

### Toggle Dark Mode

```typescript
import { useTheme } from '@/lib/hooks/useTheme';

export function Toggle() {
  const { isDarkMode, toggleDarkMode } = useTheme();

  return (
    <button onClick={toggleDarkMode}>
      {isDarkMode ? '☀️' : '🌙'}
    </button>
  );
}
```

### Style Components for Dark Mode

**PREFERRED - Use Tailwind dark: prefix:**

```tsx
<div className="bg-white dark:bg-slate-950 text-black dark:text-white">
  Content that adapts to dark mode
</div>
```

**ALTERNATIVE - Use CSS variables:**

```tsx
<div className="bg-background text-foreground">
  Automatically adapts via globals.css variables
</div>
```

**LAST RESORT - Use helper utility:**

```typescript
import { darkModeClass } from '@/lib/theme/dark-mode-utils';

const className = darkModeClass({
  light: 'bg-white text-black',
  dark: 'bg-slate-950 text-white',
  always: 'rounded-lg p-4'
});
```

## Common Tasks

### I want to access dark mode state in a component

```typescript
import { useTheme } from '@/lib/hooks/useTheme';

export function MyComponent() {
  const { isDarkMode, isMounted } = useTheme();

  // Don't render until mounted (prevents hydration mismatch)
  if (!isMounted) return null;

  return <div>{isDarkMode ? 'Dark' : 'Light'}</div>;
}
```

### I want to watch for dark mode changes

```typescript
import { observeDarkMode } from '@/lib/theme/dark-mode-utils';

useEffect(() => {
  const unwatch = observeDarkMode((isDark) => {
    console.log('Theme changed:', isDark ? 'Dark' : 'Light');
  });
  return unwatch;
}, []);
```

### I want to get a CSS variable value

```typescript
import { getCSSVariable } from '@/lib/theme/dark-mode-utils';

const primaryColor = getCSSVariable('bloom-primary');
console.log(primaryColor); // e.g., "#7C3AED"
```

### I want to validate dark mode setup

```typescript
import { validateDarkModeSetup } from '@/lib/theme/dark-mode-utils';

const validation = validateDarkModeSetup();
console.log(validation);
// {
//   isDarkModeApplied: true,
//   cssVariablesLoaded: true,
//   isConsistent: true,
//   warnings: []
// }
```

## CSS Variables Available

All variables defined in `app/globals.css`:

**Semantic:**
- `--background` / `--foreground`
- `--card` / `--card-foreground`
- `--primary` / `--secondary` / `--accent`
- `--muted` / `--muted-foreground`
- `--destructive` / `--border` / `--input` / `--ring`

**Bloom-Specific:**
- `--bloom-primary` (Purple)
- `--bloom-secondary` (Green)
- `--bloom-accent` (Amber)

**Usage:**
```css
.component {
  background-color: hsl(var(--background));
  color: hsl(var(--foreground));
  border-color: hsl(var(--border));
}
```

## Tailwind Classes for Dark Mode

```tsx
// Every Tailwind class has a dark: variant
<div className="bg-white dark:bg-slate-950">
<button className="bg-blue-500 dark:bg-blue-700">
<p className="text-gray-900 dark:text-gray-100">

// Use with hover, focus, etc.
<a className="text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300">

// Always available classes (no dark: needed)
<div className="bg-background text-foreground">
```

## Anti-Patterns (Don't Do This!)

❌ **Hardcoded light colors:**
```tsx
<div className="bg-white text-gray-600">
```

❌ **Manual dark class application:**
```typescript
useEffect(() => {
  document.documentElement.classList.toggle('dark', isDark);
}, [isDark]);
```

❌ **No dark mode support:**
```tsx
<div className="border-blue-300">
```

❌ **Mixed dark mode sources:**
```typescript
const isDark1 = useTheme().isDarkMode;
const isDark2 = useBrandingStore().config.darkMode;
const isDark3 = systemPrefersDark();
// Which one is correct?
```

## File Locations

| Purpose | File |
|---------|------|
| Hook | `lib/hooks/useTheme.ts` |
| Utilities | `lib/theme/dark-mode-utils.ts` |
| CSS Variables | `app/globals.css` (lines 6-85) |
| Full Guide | `docs/kb/theme/DARK-MODE-CENTRALIZATION.md` |
| Implementation | `docs/DARK-MODE-IMPLEMENTATION-SUMMARY.md` |

## Testing in Browser

Open DevTools console:

```javascript
// Check if dark mode is enabled
document.documentElement.classList.contains('dark')

// Toggle dark mode
document.documentElement.classList.toggle('dark')

// Get CSS variable
getComputedStyle(document.documentElement).getPropertyValue('--bloom-primary')
```

## Debugging

If dark mode isn't working:

1. **Check dark class is applied:**
   ```javascript
   document.documentElement.classList.contains('dark') // Should be true
   ```

2. **Check CSS variables loaded:**
   ```javascript
   getComputedStyle(document.documentElement).getPropertyValue('--background').trim().length > 0
   ```

3. **Check branding config:**
   - Go to Settings > General
   - Verify Dark Mode toggle is enabled

4. **Run validation:**
   ```javascript
   import { validateDarkModeSetup } from '@/lib/theme/dark-mode-utils';
   console.log(validateDarkModeSetup());
   ```

## One-Liners

```typescript
// Check dark mode
import { isDark } from '@/lib/theme/dark-mode-utils';
isDark(); // true or false

// Toggle dark mode
import { toggleDarkMode } from '@/lib/theme/dark-mode-utils';
toggleDarkMode(); // Returns new state

// System preference
import { systemPrefersDark } from '@/lib/theme/dark-mode-utils';
systemPrefersDark(); // true or false

// In component
import { useTheme } from '@/lib/hooks/useTheme';
const { isDarkMode, toggleDarkMode } = useTheme();
```

## Complete Example Component

```typescript
'use client';

import { useTheme } from '@/lib/hooks/useTheme';

export function ThemedCard() {
  const { isDarkMode, isMounted, toggleDarkMode } = useTheme();

  if (!isMounted) return <div>Loading...</div>;

  return (
    <div className="bg-white dark:bg-slate-950 rounded-lg p-6 shadow-lg">
      <h2 className="text-slate-900 dark:text-white font-bold mb-4">
        {isDarkMode ? 'Dark Mode' : 'Light Mode'}
      </h2>

      <p className="text-slate-600 dark:text-slate-400 mb-4">
        This card adapts to the current theme
      </p>

      <button
        onClick={toggleDarkMode}
        className="
          px-4 py-2 rounded-lg font-semibold transition-colors
          bg-blue-600 hover:bg-blue-700
          dark:bg-blue-500 dark:hover:bg-blue-600
          text-white
        "
      >
        {isDarkMode ? '☀️ Light Mode' : '🌙 Dark Mode'}
      </button>
    </div>
  );
}
```

## Summary

- **Hook:** `useTheme()` - Get/set dark mode state
- **Utilities:** `dark-mode-utils.ts` - Helper functions
- **Styling:** Tailwind `dark:` prefix - Responsive classes
- **Variables:** `globals.css` - CSS custom properties
- **Truth:** Branding store → useTheme → DOM

**Key Principle:** Use `useTheme()` hook or helper utilities instead of writing custom dark mode logic.
