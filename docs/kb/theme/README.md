---
id: theme-readme
topic: theme
file_role: overview
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: []
related_topics: [css, ui, design-systems]
embedding_keywords: [theme, dark-mode, styling]
last_reviewed: 2025-11-16
---

# Theme & Dark Mode Knowledge Base

Comprehensive guide to implementing theming and dark mode in modern web applications.

## Documentation Structure

- **[INDEX.md](./INDEX.md)** - Complete index with learning paths
- **[DARK-MODE-QUICK-REFERENCE.md](./DARK-MODE-QUICK-REFERENCE.md)** - Quick reference
- **[DARK-MODE-CENTRALIZATION.md](./DARK-MODE-CENTRALIZATION.md)** - Centralization patterns
- **[FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md)** - Framework integration

## Quick Start

### CSS Variables Approach

```css
:root {
  --bg-primary: #ffffff;
  --text-primary: #000000;
}

[data-theme="dark"] {
  --bg-primary: #000000;
  --text-primary: #ffffff;
}
```

### Tailwind Dark Mode

```tsx
<div className="bg-white dark:bg-gray-900">
  <h1 className="text-black dark:text-white">
    Content
  </h1>
</div>
```

## Key Concepts

- CSS variables for dynamic theming
- System preference detection
- Theme persistence
- Tailwind dark mode utilities

---

**Last Updated**: 2025-11-16
