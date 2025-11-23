---
id: playwright-01-fundamentals
topic: playwright
file_role: fundamentals
profile: full
difficulty_level: beginner
kb_version: 3.1
prerequisites: []
related_topics: [testing, e2e]
embedding_keywords: [playwright, testing, e2e, fundamentals]
last_reviewed: 2025-11-16
---

# Playwright - Fundamentals

## What is Playwright?

Playwright is a modern end-to-end testing framework for web applications. It enables reliable, cross-browser testing with powerful automation capabilities.

## Core Concepts

### Browser Automation
- Cross-browser support (Chromium, Firefox, WebKit)
- Headless and headed modes
- Mobile emulation

### Test Structure
```typescript
import { test, expect } from '@playwright/test'

test('basic test', async ({ page }) => {
  await page.goto('https://example.com')
  await expect(page).toHaveTitle(/Example/)
})
```

## Getting Started

```bash
# Install Playwright
npm install @playwright/test

# Install browsers
npx playwright install
```

## Common Pitfalls

### Pitfall 1: Not Waiting for Elements
**Problem**: Tests fail due to timing issues
**Solution**: Use built-in waiting mechanisms

```typescript
// ✅ Good - Waits automatically
await page.click('button')

// ❌ Bad - Race condition
const button = page.locator('button')
button.click() // Might fail if not ready
```

## AI Pair Programming Notes

**When to load:** Learning Playwright E2E testing basics
