# Dark Mode Centralization Guide

> **Last Updated:** November 14, 2025
> **Status:** Fully Centralized ✅

## Overview

Bloom now has a **centralized, cohesive dark mode system** that eliminates scattered logic and provides a single source of truth for theme management across all pages.

### Problem Solved

**Before:** Dark mode logic was split across multiple sources:
- `next-themes` ThemeProvider in `layout.tsx`
- Manual dark class application in `LayoutClient.tsx`
- Branding store darkMode setting
- CSS variables in `globals.css`

This caused potential conflicts and made it hard to control dark mode consistently.

**After:** Single centralized system:
- All dark mode logic flows through `useTheme()` hook
- CSS variables applied consistently via `globals.css`
- Branding config has priority
- Helper utilities for common operations

## Architecture

### System Components

```
┌─────────────────────────────────────────────────────┐
│ useTheme() Hook (Central Authority)                 │
│ ├─ Combines next-themes + branding config           │
│ ├─ Prevents conflicts                               │
│ └─ Single source of truth                           │
└─────────────────────────────────────────────────────┘
         ↓                                      ↓
┌──────────────────────┐        ┌──────────────────────┐
│ next-themes Provider  │        │ Branding Store Config │
│ (System preference)   │        │ (User preference)    │
└──────────────────────┘        └──────────────────────┘
         ↓                                      ↓
┌─────────────────────────────────────────────────────┐
│ Dark Class on <html>                                │
├─ Applied by useTheme hook                          │
├─ CSS variables activated in globals.css            │
└─────────────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────────────┐
│ Application Components                              │
├─ Use Tailwind dark: prefix                         │
├─ Use CSS variables from globals.css               │
├─ Use dark-mode-utils helpers                      │
└─────────────────────────────────────────────────────┘
```

### Priority Order

1. **Branding Config (Highest Priority)** - User's saved preference
2. **System Preference (Fallback)** - OS/browser dark mode setting
3. **Default (Dark Mode)** - If neither is set, defaults to dark

## Usage Guide

### Basic Usage: Toggling Dark Mode

```typescript
// In any client component
import { useTheme } from '@/lib/hooks/useTheme';

export function ThemeToggle() {
  const { isDarkMode, toggleDarkMode } = useTheme();

  return (
    <button onClick={() => toggleDarkMode()}>
      {isDarkMode ? '☀️ Light' : '🌙 Dark'}
    </button>
  );
}
```

### Advanced Usage: Syncing Configuration

```typescript
import { useTheme } from '@/lib/hooks/useTheme';

export function SettingsPanel() {
  const { isDarkMode, toggleDarkMode, syncWithBranding } = useTheme();

  // After fetching updated branding config
  const handleConfigLoad = () => {
    syncWithBranding(); // Re-sync theme with latest config
  };

  return (
    <div>
      <Toggle
        checked={isDarkMode}
        onChange={toggleDarkMode}
        label="Dark Mode"
      />
    </div>
  );
}
```

### Hydration Safety

The hook includes `isMounted` state to prevent hydration mismatches:

```typescript
const { isDarkMode, isMounted } = useTheme();

// Only render theme-dependent content after mount
return isMounted ? <ThemeContent /> : <Skeleton />;
```

## Helper Utilities

Location: `lib/theme/dark-mode-utils.ts`

### Common Functions

#### Check Dark Mode Status
```typescript
import { isDark, systemPrefersDark } from '@/lib/theme/dark-mode-utils';

const currentlyDark = isDark(); // Checks document.documentElement.classList
const systemDark = systemPrefersDark(); // Checks media query
```

#### Set Dark Mode
```typescript
import { setDarkMode, toggleDarkMode } from '@/lib/theme/dark-mode-utils';

// Set to specific state
setDarkMode(true);  // Enable dark mode
setDarkMode(false); // Disable dark mode

// Toggle current state
toggleDarkMode(); // Returns new state
```

#### Watch for Changes
```typescript
import { observeDarkMode, observeSystemThemePreference } from '@/lib/theme/dark-mode-utils';

// Watch app dark mode changes
useEffect(() => {
  const unwatch = observeDarkMode((isDark) => {
    console.log('Dark mode changed:', isDark);
  });
  return unwatch;
}, []);

// Watch system theme preference changes
useEffect(() => {
  const unwatch = observeSystemThemePreference((prefersDark) => {
    console.log('System theme changed:', prefersDark);
  });
  return unwatch;
}, []);
```

#### Validate Dark Mode Setup
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

#### Generate Dynamic Classes
```typescript
import { darkModeClass } from '@/lib/theme/dark-mode-utils';

// Generate class string based on current theme
const className = darkModeClass({
  light: 'bg-white text-black',
  dark: 'bg-slate-950 text-white',
  always: 'rounded-lg p-4'
});
// Result: "rounded-lg p-4 bg-slate-950 text-white" (if dark mode)
```

## CSS Variables System

### Location: `app/globals.css`

Light and dark mode CSS variables are defined for all standard colors and Bloom-specific colors:

```css
:root {
  /* Light mode variables (lines 6-52) */
  --background: 0 0% 100%;
  --foreground: 0 0% 3.6%;
  --bloom-primary: #7C3AED;
  --bloom-secondary: #10B981;
  --bloom-accent: #F59E0B;
  /* ... more variables ... */
}

.dark {
  /* Dark mode variables (lines 54-85) */
  --background: 0 0% 3.6%;
  --foreground: 0 0% 98%;
  --bloom-primary: #A78BFA;
  --bloom-secondary: #6EE7B7;
  --bloom-accent: #FBBF24;
  /* ... more variables ... */
}
```

### Using CSS Variables

#### In CSS
```css
.component {
  background-color: hsl(var(--background));
  color: hsl(var(--foreground));
}
```

#### In Tailwind
```tsx
<div className="bg-background text-foreground">
  Content that adapts to dark mode
</div>
```

#### In JavaScript
```typescript
import { getCSSVariable } from '@/lib/theme/dark-mode-utils';

const bgColor = getCSSVariable('background');
const primaryColor = getCSSVariable('bloom-primary');
```

## Component Implementation Patterns

### Pattern 1: Using Tailwind dark: Prefix (PREFERRED)

```tsx
// ✅ CORRECT - Automatic dark mode support
export function Card() {
  return (
    <div className="bg-card dark:bg-slate-800 text-card-foreground dark:text-slate-100">
      <p className="text-muted-foreground dark:text-slate-400">Helper text</p>
    </div>
  );
}
```

### Pattern 2: Using CSS Variables

```tsx
// ✅ CORRECT - Dynamic colors based on CSS variables
import { getCSSVariable } from '@/lib/theme/dark-mode-utils';

export function DynamicComponent() {
  const bgColor = getCSSVariable('background');
  const fgColor = getCSSVariable('foreground');

  return (
    <div style={{ backgroundColor: bgColor, color: fgColor }}>
      Content
    </div>
  );
}
```

### Pattern 3: Using useTheme Hook

```tsx
// ✅ CORRECT - Respond to theme changes
import { useTheme } from '@/lib/hooks/useTheme';

export function ThemeResponsiveComponent() {
  const { isDarkMode } = useTheme();

  return (
    <div className={isDarkMode ? 'dark-styles' : 'light-styles'}>
      {isDarkMode ? '🌙 Dark Mode' : '☀️ Light Mode'}
    </div>
  );
}
```

### Pattern 4: Dark Mode Helper Utility

```tsx
// ✅ CORRECT - Dynamic class generation
import { darkModeClass } from '@/lib/theme/dark-mode-utils';

export function ConditionalComponent() {
  const className = darkModeClass({
    light: 'bg-blue-50 text-blue-900',
    dark: 'bg-blue-950 text-blue-50',
    always: 'rounded-lg border',
  });

  return <div className={className}>Themed content</div>;
}
```

## Anti-Patterns (What NOT to Do)

### ❌ WRONG: Hardcoded Light Colors

```tsx
// WRONG - No dark mode support, invisible in dark mode
<div className="bg-white text-gray-600">
  This is invisible in dark mode!
</div>
```

### ❌ WRONG: Manual Dark Class Logic

```tsx
// WRONG - Duplicates centralized logic
useEffect(() => {
  if (isDarkMode) {
    document.documentElement.classList.add('dark');
  }
}, [isDarkMode]);
```

### ❌ WRONG: Conditional Rendering Based on Color Scheme

```tsx
// WRONG - Can cause hydration mismatch
const isDark = typeof window !== 'undefined' && isDark();
return isDark ? <DarkComponent /> : <LightComponent />;
```

### ❌ WRONG: Scattered Theme Logic

```tsx
// WRONG - Theme logic everywhere, hard to maintain
const theme = localStorage.getItem('theme');
const config = useConfig();
const system = prefersColorScheme();
// ... multiple sources of truth ...
```

## Page Implementation Checklist

When implementing dark mode on a page, verify:

- [ ] Page uses `useTheme()` hook (if needs theme state)
- [ ] All text colors have dark mode versions
- [ ] All backgrounds use CSS variables or `dark:` prefix
- [ ] All borders/shadows have dark mode variants
- [ ] No hardcoded light colors (#fff, #000, etc.)
- [ ] Test in both light and dark modes
- [ ] No console warnings about class application
- [ ] Dark mode toggle (in settings) works correctly

## Testing Dark Mode

### Manual Testing

1. **Homepage**: http://codeswarm:3001/
   - Verify all sections visible in both modes
   - Check text contrast meets WCAG standards

2. **Workshop**: http://codeswarm:3001/workshop
   - Chat interface readable in both modes
   - Buttons clearly visible

3. **Settings**: http://codeswarm:3001/settings
   - Toggle dark mode
   - Verify persists on reload
   - All tabs display correctly

4. **Other Pages**:
   - Share page (public)
   - Auth pages (if any)
   - Error pages

### Programmatic Validation

```typescript
import { validateDarkModeSetup } from '@/lib/theme/dark-mode-utils';

// Run this in browser console
const result = validateDarkModeSetup();
console.log(result);
// Should show: isDarkModeApplied: true, cssVariablesLoaded: true
```

### Dark Mode Monitoring

Check the Settings > Monitoring tab for:
- Dark mode status indicator
- CSS variable validation
- No errors in console related to theme

## Troubleshooting

### Dark Mode Not Applying

**Check these in order:**

1. **Verify dark class is applied**:
   ```typescript
   document.documentElement.classList.contains('dark') // Should be true
   ```

2. **Verify CSS variables are loaded**:
   ```typescript
   getComputedStyle(document.documentElement).getPropertyValue('--background')
   // Should return a valid value
   ```

3. **Run validation**:
   ```typescript
   import { validateDarkModeSetup } from '@/lib/theme/dark-mode-utils';
   validateDarkModeSetup();
   ```

4. **Check branding config**:
   - Navigate to Settings > General
   - Verify Dark Mode toggle is enabled
   - Check browser console for errors

### Theme Not Persisting

**Root causes:**

1. **Branding config not saved**:
   - Go to Settings > General
   - Ensure you click "Save Changes"
   - Check network tab for API call

2. **localStorage issue**:
   - Check if localStorage is enabled
   - Check browser console for errors
   - Verify no Private/Incognito mode

3. **Hydration mismatch**:
   - Page will flicker on reload
   - Check for mismatched components
   - Use `isMounted` from useTheme hook

### Inconsistent Styling in Dark Mode

1. **Check for hardcoded colors**:
   ```bash
   grep -r "bg-white\|text-black\|#ffffff\|#000000" components/
   ```

2. **Verify CSS variables**:
   - Open DevTools
   - Check Computed Styles
   - Verify variables are being used

3. **Check component Tailwind classes**:
   - All `bg-`, `text-`, `border-` classes should have `dark:` variant
   - Use `darkModeClass()` utility for complex cases

## Performance Considerations

### CSS Variables (Efficient)
- Minimal JavaScript
- CSS handles all rendering
- Fast theme transitions
- No component re-renders needed

### useTheme Hook (When Needed)
- Only update when branding config changes
- Prevents excessive re-renders
- Use `isMounted` to prevent hydration issues

### Helper Utilities (Lightweight)
- Minimal bundle size
- No external dependencies
- Safe to call frequently

## Related Documentation

- **DARK-MODE-STANDARDS.md** - UI implementation guidelines
- **globals.css** - CSS variable definitions
- **lib/hooks/useTheme.ts** - Central hook implementation
- **lib/theme/dark-mode-utils.ts** - Helper utilities
- **CLAUDE.md** - Project-wide dark mode rules

## Summary

Dark mode is now **fully centralized** through:

1. **`useTheme()` hook** - Central authority for theme state
2. **CSS variables in `globals.css`** - Automatic light/dark switching
3. **Helper utilities** - Common operations without code duplication
4. **Branding config** - User preferences persist across sessions

This eliminates conflicts, provides a single source of truth, and makes it easy to maintain consistent dark mode across all 134+ components.

**Key Principle**: When in doubt, use the `useTheme()` hook or a helper utility instead of writing custom dark mode logic.
