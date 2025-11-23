---
id: jest-app-testing-04-component-testing
topic: jest-app-testing
file_role: detailed
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [jest-app-testing-basics]
related_topics: ['testing', 'javascript', 'unit-tests']
embedding_keywords: [jest-app-testing, testing]
last_reviewed: 2025-11-13
---

# 04 · Component Testing

## Core Stack
- React Testing Library (`render`, `screen`, `within`)
- `@testing-library/user-event` 14.x
- `jest-axe` for accessibility
- `@testing-library/jest-dom` matchers in setup file

## Example: Hero Component (`__tests__/components/home/Hero.test.tsx`)
```tsx
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { Hero } from '@/components/home/Hero'

describe('Hero', => {
 beforeEach( => {
 global.fetch = jest.fn
 })

 it('shows loading skeleton before CTA', async => {
 render(<Hero />)
 expect(screen.getByTestId('hero-skeleton')).toBeInTheDocument
 })

 it('invokes recap fetch on CTA click', async => {
 render(<Hero />)
 await userEvent.click(screen.getByRole('button', { name: /start/i }))
 expect(global.fetch).toHaveBeenCalledWith(expect.stringContaining('/api/recap'), expect.any(Object))
 })
})
```

## Accessibility Regression Example
```tsx
import { axe } from 'jest-axe'

test('GoalDrawer has no violations', async => {
 const { container } = render(<GoalDrawer open={true} />)
 const results = await axe(container)
 expect(results).toHaveNoViolations
})
```

## ✅ Do
- Assert on user-facing text, aria labels, and DOM roles.
- Use `findBy*` for asynchronous operations.
- Provide custom render wrappers when contexts/providers required.

## ❌ Don't
- Access component internals (`component.instance` or state).
- Mock React or Next.js internals beyond router + navigation.
- Snapshot entire components unless necessary for Markdown or prompts.

## Testing Data Fetchers
- Mock `global.fetch` or use `msw` to simulate responses.
- Assert on loading/error states separately.

## Context Providers
```tsx
const renderWithProviders = (ui: React.ReactNode) =>
 render(<SessionProvider value={mockSession}>{ui}</SessionProvider>)
```
Use wrappers to avoid repeating provider setup.

## Suspense + Streaming
- Use `await screen.findByText` to wait for async boundaries.
- Wrap assertions inside `await waitFor( =>...)` when streaming updates expected.

## Error Boundaries
- Use `@testing-library/react`'s `render` to catch thrown errors; assert on fallback UI.

## Portal Testing
- Leverage `document.body` to check `modal-root` contents.
- Clean up DOM between specs via RTL's `cleanup` (auto-run by jest-dom v14).

## Hooks vs Components
- Hooks with UI side effects belong in component tests to ensure markup remains accessible.
