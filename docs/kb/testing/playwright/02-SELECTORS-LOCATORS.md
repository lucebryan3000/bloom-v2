---
id: playwright-02-selectors-locators
topic: playwright
file_role: core
profile: full
difficulty_level: beginner-to-intermediate
kb_version: 3.1
prerequisites: [playwright-01-fundamentals]
related_topics: [selectors, locators, dom, accessibility]
embedding_keywords: [playwright, selectors, locators, getByRole, getByText, element-finding, accessibility]
last_reviewed: 2025-11-14
---

# Playwright Selectors & Locators

**Part 2 of 11 - The Playwright Knowledge Base**

## Table of Contents
1. [Purpose](#1-purpose)
2. [Mental Model / Problem Statement](#2-mental-model--problem-statement)
3. [Golden Path](#3-golden-path)
4. [Variations & Trade-Offs](#4-variations--trade-offs)
5. [Examples](#5-examples)
6. [Common Pitfalls](#6-common-pitfalls)
7. [AI Pair Programming Notes](#7-ai-pair-programming-notes)

---

## 1. Purpose

Master Playwright's selector and locator strategies for reliable, maintainable, and accessibility-first element finding.

**What You'll Learn:**
- Accessibility-first locator philosophy (getByRole recommended)
- Complete locator method reference (getByRole, getByText, getByLabel, getByPlaceholder, getByTestId)
- Locator chaining, filtering, and position methods (nth, first, last)
- Advanced filtering (has, hasText, filter)
- When to use CSS and XPath selectors (and when NOT to)
- Bloom-specific patterns and best practices

**Why This Matters:**
- **Resilience**: Tests that survive UI refactoring
- **Accessibility**: Tests that validate accessible markup
- **Maintainability**: Readable, self-documenting test code
- **Speed**: Fast, reliable element finding

---

## 2. Mental Model / Problem Statement

### The Locator Philosophy

**Core Principle: Test Like Users Interact**

Users don't think about CSS classes or DOM structure. They:
- Click buttons by their label ("Send", "Export")
- Fill inputs by their label ("Email", "Password")
- Read headings to understand page structure
- Navigate by landmarks (navigation, main content, footer)

**Playwright's locator hierarchy mirrors this:**

```typescript
// ✅ BEST: How users perceive the page
await page.getByRole('button', { name: 'Send' }).click();
await page.getByLabel('Email').fill('user@example.com');
await page.getByRole('heading', { name: 'Settings' });

// ⚠️ OK: When semantic methods don't work
await page.getByTestId('submit-button').click();

// ❌ AVOID: Brittle, implementation-dependent
await page.locator('.btn-primary.submit-btn').click();
await page.locator('div > form > button:nth-child(3)').click();
```

### Why Accessibility-First?

**Three Benefits in One:**

1. **Better Tests**: Semantic locators are more stable than CSS classes
2. **Better Accessibility**: Forces you to write proper ARIA markup
3. **Better UX**: Screen reader users can navigate your app

**Example: The Button Problem**

```typescript
// ❌ BAD: Doesn't test if button is accessible
await page.locator('.btn-submit').click();

// ✅ GOOD: Verifies button has accessible role and name
await page.getByRole('button', { name: 'Submit' }).click();
// This FAILS if button lacks proper label → forces you to fix accessibility
```

### The Locator vs. Selector Distinction

**Locator (Playwright Object):**
```typescript
const submitButton = page.getByRole('button', { name: 'Submit' });
// Returns a Locator object (lazy, chainable, auto-waits)
```

**Selector (String):**
```typescript
const submitButton = page.locator('button.submit');
// Uses CSS selector string (old-school, brittle)
```

**Always prefer Locators.** They're:
- Auto-waiting (no need for manual `waitFor`)
- Strict by default (error if multiple matches)
- Chainable (can narrow down from parent to child)

---

## 3. Golden Path

### The Locator Hierarchy (Use in This Order)

```typescript
// 🥇 TIER 1: Accessibility-Based (ALWAYS TRY FIRST)
page.getByRole()         // Buttons, headings, links, inputs, etc.
page.getByLabel()        // Form fields with <label> tags
page.getByPlaceholder()  // Inputs with placeholder text
page.getByText()         // Visible text content

// 🥈 TIER 2: Semantic Attributes
page.getByAltText()      // Images with alt text
page.getByTitle()        // Elements with title attribute

// 🥉 TIER 3: Test IDs (When semantic methods fail)
page.getByTestId()       // data-testid attributes

// ⛔ TIER 4: CSS/XPath (LAST RESORT)
page.locator('css')      // Only when nothing else works
page.locator('xpath=')   // Rarely needed
```

### Core Locator Methods

#### 1. `getByRole()` - The Golden Standard

**Use for: Buttons, links, headings, navigation, inputs, dialogs, etc.**

```typescript
// Basic usage
await page.getByRole('button').click();

// With name (recommended)
await page.getByRole('button', { name: 'Send' }).click();
await page.getByRole('button', { name: /send|submit/i }).click(); // Regex

// With exact match
await page.getByRole('button', { name: 'Send', exact: true }).click();

// Common roles
await page.getByRole('heading', { name: 'Settings' });
await page.getByRole('link', { name: 'Home' });
await page.getByRole('textbox', { name: 'Email' });
await page.getByRole('checkbox', { name: 'Remember me' });
await page.getByRole('navigation');
await page.getByRole('main');
await page.getByRole('dialog');
await page.getByRole('alert');
```

**ARIA Roles Reference:**
- `button` → `<button>`, `role="button"`
- `link` → `<a href="...">`, `role="link"`
- `textbox` → `<input type="text">`, `<textarea>`
- `checkbox` → `<input type="checkbox">`
- `radio` → `<input type="radio">`
- `heading` → `<h1>`, `<h2>`, etc.
- `navigation` → `<nav>`, `role="navigation"`
- `main` → `<main>`, `role="main"`
- `dialog` → `role="dialog"`, `<dialog>`

#### 2. `getByLabel()` - Form Fields

**Use for: Inputs, textareas, selects with associated `<label>` tags**

```typescript
// Matches <label>Email</label><input type="text" />
await page.getByLabel('Email').fill('user@example.com');

// Partial match
await page.getByLabel(/email/i).fill('user@example.com');

// Exact match
await page.getByLabel('Email Address', { exact: true }).fill('...');
```

#### 3. `getByPlaceholder()` - Input Hints

**Use for: Inputs with placeholder text (when no label exists)**

```typescript
await page.getByPlaceholder('Enter your email').fill('user@example.com');
await page.getByPlaceholder(/search/i).fill('query');
```

#### 4. `getByText()` - Visible Text

**Use for: Paragraphs, spans, divs with visible text**

```typescript
// Exact text
await page.getByText('Welcome back!');

// Partial text
await page.getByText('Welcome');

// Regex
await page.getByText(/welcome|hello/i);

// Exact match
await page.getByText('Submit', { exact: true }); // Won't match "Submit Form"
```

#### 5. `getByTestId()` - Test Attributes

**Use for: Complex components where semantic locators fail**

```typescript
// Matches data-testid="submit-button"
await page.getByTestId('submit-button').click();
await page.getByTestId('user-profile-card');
```

**When to Use:**
- Complex components without clear ARIA roles
- Dynamic content that changes frequently
- Legacy code you can't refactor immediately

**Best Practices:**
```typescript
// ✅ GOOD: Descriptive, hierarchical
data-testid="session-card"
data-testid="session-card-title"
data-testid="session-card-export-button"

// ❌ BAD: Generic, unclear
data-testid="card-1"
data-testid="btn"
data-testid="test123"
```

---

## 4. Variations & Trade-Offs

### Locator Chaining

**Narrow down from parent to child:**

```typescript
// Find button inside a specific card
const sessionCard = page.getByTestId('session-card-123');
await sessionCard.getByRole('button', { name: 'Export' }).click();

// Chaining multiple levels
const dialog = page.getByRole('dialog');
const form = dialog.locator('form');
await form.getByLabel('Email').fill('user@example.com');
```

**Why Chain?**
- Disambiguate when multiple elements match
- Scope searches to specific page regions
- More readable than complex CSS selectors

### Filtering Locators

#### `filter()` - Filter by Text or Locator

```typescript
// Filter buttons by text
await page
  .getByRole('button')
  .filter({ hasText: 'Export' })
  .click();

// Filter by nested element
await page
  .getByTestId('session-card')
  .filter({ has: page.getByText('Active') })
  .getByRole('button', { name: 'Pause' })
  .click();
```

#### `has()` - Must Contain Element

```typescript
// Find card that contains specific text
const activeCard = page
  .getByTestId('session-card')
  .filter({ has: page.getByText('Active') });

await activeCard.click();
```

#### `hasText()` - Must Contain Text

```typescript
// Find card with "Active" status
const activeCard = page
  .getByTestId('session-card')
  .filter({ hasText: 'Active' });
```

### Position Methods

#### `nth()` - Get by Index (0-based)

```typescript
// Get second button
await page.getByRole('button').nth(1).click();

// Get third session card
const thirdCard = page.getByTestId('session-card').nth(2);
```

#### `first()` - Get First Match

```typescript
await page.getByRole('button').first().click();
await page.getByTestId('session-card').first();
```

#### `last()` - Get Last Match

```typescript
await page.getByRole('button').last().click();
await page.getByTestId('session-card').last();
```

**⚠️ Warning: Position methods are fragile**

```typescript
// ❌ BRITTLE: Breaks if button order changes
await page.getByRole('button').nth(2).click();

// ✅ BETTER: Use specific name
await page.getByRole('button', { name: 'Export' }).click();

// ✅ ACCEPTABLE: When order is semantically meaningful
const firstSessionCard = page.getByTestId('session-card').first();
// OK if cards are sorted by date and you want most recent
```

### CSS and XPath Selectors

**When to Use CSS:**

```typescript
// ✅ ACCEPTABLE: Testing CSS classes are applied correctly
await expect(page.locator('.error-message')).toBeVisible();
await expect(page.locator('.btn-primary')).toHaveClass(/disabled/);

// ✅ ACCEPTABLE: Complex pseudo-selectors
await page.locator('input:focus').blur();
await page.locator('button:has(svg)'); // Button with icon

// ⚠️ OK: When semantic locators genuinely don't work
await page.locator('[data-status="active"]').click();
```

**When to Use XPath (Rarely):**

```typescript
// ✅ ACCEPTABLE: Complex DOM traversal
await page.locator('xpath=//button[contains(text(), "Export")]/following-sibling::div');

// ✅ ACCEPTABLE: Text content with specific formatting
await page.locator('xpath=//p[normalize-space()="Exact text with   spaces"]');
```

**❌ AVOID CSS/XPath for:**
- Clicking buttons (use `getByRole`)
- Filling forms (use `getByLabel`)
- Finding text (use `getByText`)
- Any interactive element

### Trade-Offs Summary

| Method | Pros | Cons | Use When |
|--------|------|------|----------|
| `getByRole()` | Accessible, semantic, stable | Requires proper ARIA | Always try first |
| `getByLabel()` | Semantic, stable | Requires `<label>` tags | Form fields |
| `getByText()` | Simple, readable | Breaks if text changes | Static text, headings |
| `getByTestId()` | Stable, flexible | Adds test-only markup | Complex components |
| CSS/XPath | Powerful, flexible | Brittle, implementation-dependent | Last resort |

---

## 5. Examples

### Bloom Component Examples

#### Example 1: ChatInterface Component

**Component:** `/components/bloom/ChatInterface.tsx`

```tsx
// Component code (simplified)
<Card className="flex flex-col h-full">
  <SessionTitleEditor sessionId={sessionId} />
  <ProgressIndicator phase={currentPhase} progress={progress} />

  <ScrollArea className="flex-1 p-6">
    {messages.map((message) => (
      <MessageBubble key={message.id} message={message} />
    ))}

    {isLoading && (
      <div className="flex gap-3">
        <div className="animate-pulse">...</div>
      </div>
    )}

    {errorDetails && (
      <div className="bg-red-50 border border-red-200">
        <AlertCircle />
        <p>{errorDetails.message}</p>
        <button onClick={handleRetry}>Retry</button>
      </div>
    )}
  </ScrollArea>

  <InputField onSend={handleSendMessage} disabled={isLoading} />
</Card>
```

**Test Code:**

```typescript
import { test, expect } from '@playwright/test';

test.describe('ChatInterface', () => {
  test('should send a message', async ({ page }) => {
    await page.goto('/workshop');

    // ✅ GOOD: Use placeholder to find input
    const input = page.getByPlaceholder('Type your response...');
    await input.fill('Hello, Melissa!');

    // ✅ GOOD: Find button by ARIA role
    await page.getByRole('button', { name: /send/i }).click();

    // ✅ GOOD: Verify message appears in chat
    await expect(page.getByText('Hello, Melissa!')).toBeVisible();
  });

  test('should show loading indicator', async ({ page }) => {
    await page.goto('/workshop');

    // Send message
    await page.getByPlaceholder('Type your response...').fill('Test');
    await page.getByRole('button', { name: /send/i }).click();

    // ✅ GOOD: Check for loading state
    await expect(page.locator('.animate-pulse')).toBeVisible();
  });

  test('should retry on error', async ({ page }) => {
    // ... simulate error ...

    // ✅ GOOD: Find error by role (implicit role="alert")
    const errorAlert = page.locator('.bg-red-50'); // Contains error
    await expect(errorAlert).toBeVisible();

    // ✅ GOOD: Find retry button by text
    await errorAlert.getByRole('button', { name: 'Retry' }).click();
  });
});
```

#### Example 2: SessionCard Component

**Component:** `/components/bloom/SessionCard.tsx`

```tsx
<div className="p-6 border rounded-lg">
  <h3 className="font-semibold">
    {SessionIdGenerator.toDisplayFormat(session.id)}
  </h3>
  <p className="text-xs text-muted-foreground">{session.id}</p>

  <span className={`px-2 py-1 rounded ${getStatusColor(status)}`}>
    {status}
  </span>

  <div className="flex items-center gap-2">
    <Clock className="w-4 h-4" />
    <span>Started {formatTime(session.startedAt)}</span>
  </div>

  {status === 'active' && (
    <Button onClick={handlePause}>
      <Pause className="w-4 h-4" />
      Pause
    </Button>
  )}

  {status === 'idle' && (
    <Button onClick={handleResume}>
      <Play className="w-4 h-4" />
      Resume
    </Button>
  )}

  <DropdownMenu>
    <DropdownMenuTrigger>
      <Download className="w-4 h-4" />
      Export
    </DropdownMenuTrigger>
    <DropdownMenuContent>
      <DropdownMenuItem onClick={() => handleExport('pdf')}>
        PDF Report
      </DropdownMenuItem>
      <DropdownMenuItem onClick={() => handleExport('excel')}>
        Excel Workbook
      </DropdownMenuItem>
    </DropdownMenuContent>
  </DropdownMenu>
</div>
```

**Test Code:**

```typescript
test.describe('SessionCard', () => {
  test('should pause active session', async ({ page }) => {
    await page.goto('/settings');

    // ✅ GOOD: Find card by test ID (complex component)
    const sessionCard = page.getByTestId('session-card-abc123');

    // ✅ GOOD: Verify status badge
    await expect(sessionCard.getByText('Active')).toBeVisible();

    // ✅ GOOD: Click pause button within card (scoped)
    await sessionCard.getByRole('button', { name: /pause/i }).click();

    // ✅ GOOD: Verify status changed
    await expect(sessionCard.getByText('Idle')).toBeVisible();
  });

  test('should export session as PDF', async ({ page }) => {
    await page.goto('/settings');

    const sessionCard = page.getByTestId('session-card-abc123');

    // ✅ GOOD: Open dropdown menu
    await sessionCard.getByRole('button', { name: /export/i }).click();

    // ✅ GOOD: Click menu item
    await page.getByRole('menuitem', { name: 'PDF Report' }).click();

    // Verify download started
    const download = await page.waitForEvent('download');
    expect(download.suggestedFilename()).toMatch(/\.pdf$/);
  });

  test('should show session timestamp', async ({ page }) => {
    await page.goto('/settings');

    const sessionCard = page.getByTestId('session-card-abc123');

    // ✅ GOOD: Find by text pattern
    await expect(
      sessionCard.getByText(/started.*ago/i)
    ).toBeVisible();
  });
});
```

#### Example 3: Button Variants

**Component:** `/components/ui/button.tsx`

```tsx
const buttonVariants = cva(
  "inline-flex items-center justify-center rounded-md",
  {
    variants: {
      variant: {
        default: "bg-primary text-primary-foreground",
        destructive: "bg-destructive text-destructive-foreground",
        outline: "border border-input",
        ghost: "hover:bg-accent",
        link: "underline-offset-4 hover:underline",
      },
      size: {
        default: "h-10 px-4 py-2",
        sm: "h-9 px-3",
        lg: "h-11 px-8",
        icon: "h-10 w-10",
      },
    },
  }
);

<Button variant="destructive" size="sm">
  Delete
</Button>
```

**Test Code:**

```typescript
test.describe('Button', () => {
  test('should render different variants', async ({ page }) => {
    await page.goto('/components/buttons');

    // ✅ GOOD: Find by role and name
    const deleteButton = page.getByRole('button', { name: 'Delete' });

    // ✅ ACCEPTABLE: Verify CSS class for variant
    await expect(deleteButton).toHaveClass(/destructive/);

    // ✅ GOOD: Verify button is clickable
    await expect(deleteButton).toBeEnabled();
    await deleteButton.click();
  });

  test('should disable button when loading', async ({ page }) => {
    await page.goto('/components/buttons');

    const submitButton = page.getByRole('button', { name: 'Submit' });

    // Trigger loading state
    await submitButton.click();

    // ✅ GOOD: Verify disabled state
    await expect(submitButton).toBeDisabled();
  });
});
```

#### Example 4: InputField with File Upload

**Component:** `/components/bloom/InputField.tsx`

```tsx
<form onSubmit={handleSubmit}>
  {/* File attachments preview */}
  {attachedFiles.map((file, index) => (
    <div key={index}>
      <span>{file.name}</span>
      <button onClick={() => removeFile(index)} title="Remove file">
        <X className="w-3.5 h-3.5" />
      </button>
    </div>
  ))}

  <div className="flex items-center gap-2">
    <DropdownMenu>
      <DropdownMenuTrigger>
        <Plus className="h-5 w-5" />
      </DropdownMenuTrigger>
      <DropdownMenuContent>
        <DropdownMenuItem onClick={() => fileInputRef.current?.click()}>
          <Upload className="mr-2 h-4 w-4" />
          Upload File
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>

    <textarea
      placeholder="Type your response..."
      value={input}
      onChange={(e) => setInput(e.target.value)}
    />

    <Button type="submit">Send</Button>
  </div>
</form>
```

**Test Code:**

```typescript
test.describe('InputField', () => {
  test('should attach and remove files', async ({ page }) => {
    await page.goto('/workshop');

    // ✅ GOOD: Open file upload menu
    await page.getByRole('button', { name: /attach|plus/i }).click();

    // ✅ GOOD: Click upload option
    await page.getByRole('menuitem', { name: /upload file/i }).click();

    // Upload file
    const fileInput = page.locator('input[type="file"]');
    await fileInput.setInputFiles({
      name: 'test.pdf',
      mimeType: 'application/pdf',
      buffer: Buffer.from('test content'),
    });

    // ✅ GOOD: Verify file appears
    await expect(page.getByText('test.pdf')).toBeVisible();

    // ✅ GOOD: Remove file by button title
    await page.getByRole('button', { name: 'Remove file' }).first().click();

    // Verify file removed
    await expect(page.getByText('test.pdf')).not.toBeVisible();
  });

  test('should send message with Enter key', async ({ page }) => {
    await page.goto('/workshop');

    // ✅ GOOD: Find textarea by placeholder
    const textarea = page.getByPlaceholder('Type your response...');

    await textarea.fill('Test message');
    await textarea.press('Enter');

    // ✅ GOOD: Verify message sent
    await expect(page.getByText('Test message')).toBeVisible();
  });
});
```

#### Example 5: ProgressIndicator

**Component:** `/components/bloom/ProgressIndicator.tsx`

```tsx
<div className="bg-white border-b p-4">
  <div className="flex items-center justify-between">
    <span className="text-sm font-medium">Progress:</span>
    <span className="text-bloom-primary">{getPhaseLabel(phase)}</span>
    <span className="text-sm font-semibold">{progress}%</span>
  </div>

  <Progress value={progress} className="h-2" />

  {/* Phase steps */}
  <div className="flex items-center justify-between gap-1">
    {phases.map((p, index) => (
      <div
        key={p}
        className={index <= currentPhaseIndex ? "bg-bloom-primary" : "bg-slate-200"}
      />
    ))}
  </div>

  {/* Confidence score */}
  <div className="flex items-center gap-1">
    <span>Confidence:</span>
    <span className={getConfidenceColor(confidenceScore)}>
      {getConfidenceLabel(confidenceScore)} ({Math.round(confidenceScore * 100)}%)
    </span>
  </div>
</div>
```

**Test Code:**

```typescript
test.describe('ProgressIndicator', () => {
  test('should show current phase and progress', async ({ page }) => {
    await page.goto('/workshop');

    // ✅ GOOD: Find progress section by text
    const progressSection = page.locator('text=Progress:').locator('..');

    // ✅ GOOD: Verify phase label
    await expect(progressSection.getByText('Discovery')).toBeVisible();

    // ✅ GOOD: Verify percentage (regex for flexibility)
    await expect(progressSection.getByText(/\d+%/)).toBeVisible();
  });

  test('should show confidence score', async ({ page }) => {
    await page.goto('/workshop');

    // ✅ GOOD: Find confidence section
    const confidenceSection = page.locator('text=Confidence:').locator('..');

    // ✅ GOOD: Verify confidence label (High/Medium/Low)
    await expect(
      confidenceSection.getByText(/high|medium|low/i)
    ).toBeVisible();

    // ✅ GOOD: Verify percentage
    await expect(
      confidenceSection.getByText(/\(\d+%\)/)
    ).toBeVisible();
  });

  test('should update progress bar visually', async ({ page }) => {
    await page.goto('/workshop');

    // ✅ ACCEPTABLE: Check progress bar has value
    const progressBar = page.locator('[role="progressbar"]');

    const ariaValue = await progressBar.getAttribute('aria-valuenow');
    expect(Number(ariaValue)).toBeGreaterThan(0);
  });
});
```

#### Example 6: QuickPromptButtons

**Component:** `/components/bloom/QuickPromptButtons.tsx`

```tsx
<div className="flex items-center justify-center gap-2 py-4">
  {enabledPrompts.map((prompt) => {
    const IconComponent = iconMap[prompt.icon];

    return (
      <Button
        key={prompt.id}
        variant="outline"
        size="sm"
        onClick={() => onPromptClick(prompt.prompt)}
      >
        {IconComponent && <IconComponent className="w-4 h-4 mr-2" />}
        <span>{prompt.label}</span>
      </Button>
    );
  })}
</div>
```

**Test Code:**

```typescript
test.describe('QuickPromptButtons', () => {
  test('should click quick prompt', async ({ page }) => {
    await page.goto('/workshop');

    // ✅ GOOD: Find button by exact label
    await page.getByRole('button', { name: 'Explain Benefits' }).click();

    // Verify prompt was inserted
    const textarea = page.getByPlaceholder('Type your response...');
    await expect(textarea).toHaveValue(/benefits/i);
  });

  test('should show all enabled prompts', async ({ page }) => {
    await page.goto('/workshop');

    // ✅ GOOD: Count buttons with specific pattern
    const promptButtons = page.getByRole('button').filter({
      hasText: /explain|summarize|analyze/i,
    });

    const count = await promptButtons.count();
    expect(count).toBeGreaterThan(0);
  });

  test('should disable buttons when loading', async ({ page }) => {
    await page.goto('/workshop');

    // Trigger loading state
    await page.getByPlaceholder('Type your response...').fill('Test');
    await page.getByRole('button', { name: /send/i }).click();

    // ✅ GOOD: Verify all quick prompts are disabled
    const promptButtons = page.getByRole('button').filter({
      hasText: /explain|summarize|analyze/i,
    });

    const firstButton = promptButtons.first();
    await expect(firstButton).toBeDisabled();
  });
});
```

### Advanced Chaining Example

```typescript
test('complex session card interaction', async ({ page }) => {
  await page.goto('/settings');

  // Find the specific session card
  const sessions = page.getByTestId('session-card');

  // Filter to active sessions only
  const activeSessions = sessions.filter({ hasText: 'Active' });

  // Find the first active session with a specific timestamp
  const recentSession = activeSessions
    .filter({ hasText: /\d+m ago/ })
    .first();

  // Verify session details
  await expect(recentSession.getByRole('heading')).toBeVisible();

  // Click pause button within this specific card
  await recentSession.getByRole('button', { name: /pause/i }).click();

  // Verify status changed
  await expect(recentSession.getByText('Idle')).toBeVisible();
});
```

---

## 6. Common Pitfalls

### ❌ Pitfall 1: Using CSS Classes for Interactive Elements

```typescript
// ❌ BAD: Brittle, breaks when CSS changes
await page.locator('.btn-primary.submit').click();

// ✅ GOOD: Semantic, stable
await page.getByRole('button', { name: 'Submit' }).click();
```

**Why it's bad:** CSS classes are implementation details that change frequently during refactoring.

### ❌ Pitfall 2: Relying on DOM Structure

```typescript
// ❌ BAD: Breaks if DOM structure changes
await page.locator('div > form > button:nth-child(3)').click();

// ✅ GOOD: Independent of structure
await page.getByRole('button', { name: 'Submit' }).click();
```

### ❌ Pitfall 3: Not Using `name` Option with `getByRole`

```typescript
// ❌ BAD: Ambiguous, may match multiple buttons
await page.getByRole('button').click(); // Which button?

// ✅ GOOD: Specific, self-documenting
await page.getByRole('button', { name: 'Submit' }).click();
```

### ❌ Pitfall 4: Overusing `nth()` and Position Methods

```typescript
// ❌ BAD: Fragile, breaks when order changes
await page.getByRole('button').nth(2).click();

// ✅ GOOD: Semantic, resilient
await page.getByRole('button', { name: 'Export' }).click();

// ✅ ACCEPTABLE: When order is semantically meaningful
const mostRecentSession = page.getByTestId('session-card').first();
// OK if cards are sorted by date
```

### ❌ Pitfall 5: Ignoring Accessibility

```typescript
// ❌ BAD: Button without accessible name
<button className="icon-btn" onClick={handleClick}>
  <TrashIcon />
</button>

// Test will fail:
await page.getByRole('button', { name: 'Delete' }).click();
// Error: No button with name "Delete"

// ✅ GOOD: Add accessible label
<button className="icon-btn" onClick={handleClick} aria-label="Delete">
  <TrashIcon />
</button>
```

**Lesson:** Failing tests can reveal accessibility bugs!

### ❌ Pitfall 6: Not Using Strict Mode

```typescript
// ❌ BAD: Silently clicks first match if multiple buttons exist
await page.locator('button').click();

// ✅ GOOD: Fails if multiple matches (forces you to be specific)
await page.getByRole('button', { name: 'Submit' }).click();
// Error if multiple "Submit" buttons exist
```

**Solution for multiple matches:**
```typescript
// Option 1: Be more specific
await page.getByRole('button', { name: 'Submit Form' }).click();

// Option 2: Scope to parent
const loginForm = page.locator('form[name="login"]');
await loginForm.getByRole('button', { name: 'Submit' }).click();

// Option 3: Use first() explicitly (if intentional)
await page.getByRole('button', { name: 'Submit' }).first().click();
```

### ❌ Pitfall 7: Mixing Locator Strategies Inconsistently

```typescript
// ❌ BAD: Inconsistent, hard to maintain
await page.locator('.email-input').fill('user@example.com');
await page.getByRole('button', { name: 'Submit' }).click();
await page.locator('#password').fill('secret');

// ✅ GOOD: Consistent strategy
await page.getByLabel('Email').fill('user@example.com');
await page.getByLabel('Password').fill('secret');
await page.getByRole('button', { name: 'Submit' }).click();
```

### ❌ Pitfall 8: Not Testing Accessibility Attributes

```typescript
// ❌ BAD: Only tests visual presence
await expect(page.locator('.error-msg')).toBeVisible();

// ✅ BETTER: Also test accessibility
const errorAlert = page.locator('.error-msg');
await expect(errorAlert).toBeVisible();
await expect(errorAlert).toHaveAttribute('role', 'alert');
await expect(errorAlert).toHaveAttribute('aria-live', 'polite');
```

### ❌ Pitfall 9: Hardcoding Text That Changes

```typescript
// ❌ BAD: Breaks if timestamp format changes
await expect(page.getByText('Started 5m ago')).toBeVisible();

// ✅ GOOD: Use regex for flexibility
await expect(page.getByText(/started.*ago/i)).toBeVisible();
```

### ❌ Pitfall 10: Not Using Locator Variables

```typescript
// ❌ BAD: Repetitive, hard to update
await page.getByRole('button', { name: 'Submit' }).click();
await expect(page.getByRole('button', { name: 'Submit' })).toBeDisabled();

// ✅ GOOD: Reusable, DRY
const submitButton = page.getByRole('button', { name: 'Submit' });
await submitButton.click();
await expect(submitButton).toBeDisabled();
```

---

## 7. AI Pair Programming Notes

### When to Load This File

**Load with:**
- `QUICK-REFERENCE.md` - For quick syntax lookup
- `01-FUNDAMENTALS.md` - For Playwright basics
- `03-INTERACTIONS-ASSERTIONS.md` - For actions and checks

**Use for:**
- "How do I find X element?"
- "What's the best way to select Y?"
- "My selector is flaky, how can I make it more reliable?"
- "Is this selector following best practices?"

### AI Code Review Checklist

When reviewing Playwright test code, check:

1. **✅ Accessibility-First:**
   - Using `getByRole`, `getByLabel`, `getByText` where possible?
   - Only using `getByTestId` when semantic methods fail?
   - Avoiding CSS classes for interactive elements?

2. **✅ Specificity:**
   - Using `name` option with `getByRole`?
   - Avoiding generic selectors like `.locator('button')`?
   - Using strict mode (default in Playwright)?

3. **✅ Resilience:**
   - Avoiding position methods (`nth`, `first`) unless semantically meaningful?
   - Not relying on DOM structure (`:nth-child`, `> div > button`)?
   - Using regex for flexible text matching?

4. **✅ Maintainability:**
   - Storing locators in variables for reuse?
   - Consistent locator strategy throughout tests?
   - Self-documenting selector names?

5. **✅ Accessibility Testing:**
   - Verifying ARIA attributes when relevant?
   - Testing keyboard navigation?
   - Checking focus management?

### Common AI Prompts

**Finding elements:**
```
"How do I select a button with text 'Export' inside a specific card component?"
→ Use chaining: sessionCard.getByRole('button', { name: 'Export' })

"I have multiple buttons with the same name, how do I distinguish them?"
→ Scope to parent container or use filter()

"How do I find an input field?"
→ Use getByLabel() if there's a <label>, otherwise getByPlaceholder()
```

**Refactoring:**
```
"Can you make this selector more resilient?"
→ AI will suggest moving from CSS to getByRole/getByLabel

"Is this following Bloom conventions?"
→ AI will check against this guide's best practices
```

### Quick Reference: Locator Decision Tree

```
Need to find an element?
│
├─ Is it a button, link, heading, input?
│  └─ ✅ Use getByRole('role', { name: '...' })
│
├─ Is it a form field with a <label>?
│  └─ ✅ Use getByLabel('Label Text')
│
├─ Is it an input with placeholder text?
│  └─ ✅ Use getByPlaceholder('Placeholder')
│
├─ Is it visible text (paragraph, heading, etc.)?
│  └─ ✅ Use getByText('Text Content')
│
├─ Is it a complex component without semantic markup?
│  └─ ✅ Use getByTestId('component-id')
│
└─ None of the above work?
   └─ ⚠️ Use locator('css') or locator('xpath=') as last resort
```

---

## Last Updated

2025-11-14

---

## Related Documentation

- **[01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md)** - Playwright setup and core concepts
- **[03-INTERACTIONS-ASSERTIONS.md](./03-INTERACTIONS-ASSERTIONS.md)** - Actions and expectations
- **[QUICK-REFERENCE.md](./QUICK-REFERENCE.md)** - Syntax cheat sheet
- **[FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md)** - Bloom-specific patterns

---

**📚 Part 2 of 11 Complete** | Next: [03-INTERACTIONS-ASSERTIONS.md](./03-INTERACTIONS-ASSERTIONS.md)
