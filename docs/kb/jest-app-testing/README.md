---
id: jest-app-testing-readme
topic: jest-app-testing
file_role: overview
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: []
related_topics: ['testing', 'javascript', 'unit-tests']
embedding_keywords: [jest-app-testing, overview, introduction, getting-started]
last_reviewed: 2025-11-13
---

# Jest App Testing Knowledge Base

**Status**: Draft (awaiting quality pass)
**Last Updated**: November 10, 2025
**Version**: 0.9.0

This knowledge base focuses on how this application uses Jest 29.7.0 to test the Next.js 16 App Router application. It distills this project conventions, working code samples, and CI expectations so contributors can ship deterministic, high-signal tests without slowing the pipeline.

---

## 11-Part Series Overview

| # | File | Theme | Why it matters |
|---|------|-------|----------------|
| 1 | [01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md) | Testing value stream | Shared vocabulary + goals |
| 2 | [02-SETUP-AND-CONFIG.md](./02-SETUP-AND-CONFIG.md) | Tooling + jest.config | Prevent brittle harnesses |
| 3 | [03-TEST-DIRECTORY-ARCHITECTURE.md](./03-TEST-DIRECTORY-ARCHITECTURE.md) | File layout + naming | Keep intent obvious |
| 4 | [04-COMPONENT-TESTING.md](./04-COMPONENT-TESTING.md) | RTL patterns | Ship reliable UI specs |
| 5 | [05-HOOKS-AND-STATE.md](./05-HOOKS-AND-STATE.md) | Store + hook tests | Contain state regressions |
| 6 | [06-APP-ROUTER-ACTIONS.md](./06-APP-ROUTER-ACTIONS.md) | Server actions + caching | Confident data workflows |
| 7 | [07-API-ROUTES-AND-EDGE.md](./07-API-ROUTES-AND-EDGE.md) | Route handlers | Validate platform contracts |
| 8 | [08-DATA-AND-PRISMA.md](./08-DATA-AND-PRISMA.md) | Prisma + SQLite harness | Deterministic data fakes |
| 9 | [09-MOCKING-EXTERNAL-SERVICES.md](./09-MOCKING-EXTERNAL-SERVICES.md) | AI + third-party mocks | Control flaky dependencies |
|10 | [10-INTEGRATION-AND-E2E-HYBRIDS.md](./10-INTEGRATION-AND-E2E-HYBRIDS.md) | Contract + hybrid tests | Cover cross-cutting flows |
|11 | [11-CI-OBSERVABILITY.md](./11-CI-OBSERVABILITY.md) | Coverage, reporters, alerts | Keep velocity + signal |

Supporting references:
- [INDEX.md](./INDEX.md) → navigation map
- [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) → copy/paste snippets
- [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md) → real implementations

---

## Getting Started

### Install dependencies (already in `package.json`)
```bash
npm install -D jest jest-environment-jsdom @testing-library/react @testing-library/jest-dom @testing-library/user-event msw jest-axe
```

### Core npm scripts (package.json)
```jsonc
{
  "scripts": {
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
    "test:unit": "jest --testPathPattern=tests/unit",
    "test:domain": "jest --testPathPattern=tests/domain",
    "test:integration": "jest --testPathPattern=tests/integration",
    "test:e2e": "npm run dev:clean && playwright test"
  }
}
```

### First component test
```tsx
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { Hero } from '@/components/home/Hero'

describe('Hero CTA', => {
 it('shows personalized CTA', async => {
 render(<Hero />)
 await userEvent.click(screen.getByRole('button', { name: /start/i }))
 expect(screen.getByText(/tell us about your goals/i)).toBeInTheDocument
 })
})
```

---

## Common Tasks Map

| Task | Read This | Example |
|------|-----------|---------|
| Add a new unit test | 01 Fundamentals → naming + AAA | `tests/unit/components/home/Hero.test.tsx` |
| Mock Prisma | 08 Data + this project patterns | `tests/services/LLMService.test.ts` |
| Test App Router action | 06 App Router Actions | `tests/integration/runs-with-llm.test.ts` |
| Test Route Handler (API) | 07 API Routes + 10 Hybrid | `tests/integration/recap-api.test.ts` |
| Mock AI SDK | 09 External Services | `tests/services/LLMService.test.ts` |
| Track coverage budget | 11 CI Observability | coverage thresholds in `jest.config.cjs` |

---

## Key Principles

1. **Behavior over implementation** – assert observable outcomes, not private state.
2. **Deterministic data** – build hermetic fixtures and reset after every spec.
3. **Single reason to fail** – keep each `it` scoped to one assertion cluster.
4. **framework-specific smoke** – every feature ships one integration spec hitting `tests/integration`.
5. **Document edge cases** – reference issue IDs in test titles when fixing regressions.

Each chapter includes ✅ good vs ❌ bad examples so reviewers can reason about quality quickly.

---

## Learning Paths

- **Beginner (4 hrs)**: Read 01 Fundamentals, run `npm test`, add a `describe` block to an existing file.
- **Intermediate (8 hrs)**: Add RTL coverage for a new component (04) and mock Prisma writes (08).
- **Advanced (12 hrs)**: Extend integration spec for `runs-with-llm` (10), wire coverage alerts (11).
- **Expert (ongoing)**: Own a domain; ship golden-path integration tests plus mutation harness metrics.

---

## Configuration Essentials

- `jest.config.cjs` wraps `next/jest`, maps `@/` imports, and enforces coverage ≥80% lines.
- `jest.setup.js` polyfills `next/router`, `next/image`, and ensures `global.fetch` is a stable mock.
- `.env.test` should stay minimal—prefer explicit environment overrides via `process.env.X = 'value'` inside tests.
- Use the `@jest-environment node` pragma for server-only specs living under `tests/`.

---

## Troubleshooting Cheatsheet

| Symptom | Fix |
|---------|-----|
| `TextEncoder is not defined` | Add `import { TextEncoder } from 'util'; global.TextEncoder = TextEncoder;` in `jest.setup.js` if polyfill missing. |
| Tests stuck on Prisma connection | Mock `@/lib/prisma` and avoid hitting SQLite file. |
| `next/navigation` not mocked | Ensure `jest.setup.js` exports `mockedUseRouter` before components import it. |
| Random `fetch` failures | Replace global fetch stub with `msw` per 09 mocking guidance. |
| Coverage drops below gate | Run `npm run test:coverage` locally and focus on low-branch files via `coverage/lcov-report`. |

---

## External References

- Jest 29.7 Docs (offline snapshot) – `https://jestjs.io/docs/getting-started`
- Testing Library – `https://testing-library.com/docs/react-testing-library/intro`
- Next.js App Router Testing Guide – `https://nextjs.org/docs/pages/building-your-application/testing`

(Unable to fetch live pages in this environment; content is based on November 2025 knowledge.)

---

## Next Steps

1. Continue with [INDEX.md](./INDEX.md) to find deep dives.
2. Use `QUICK-REFERENCE.md` during code reviews.
3. Sync with `FRAMEWORK-INTEGRATION-PATTERNS.md` before merging new suites.
