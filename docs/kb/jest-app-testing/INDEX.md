---
id: jest-app-testing-index
topic: jest-app-testing
file_role: navigation
profile: full
difficulty_level: all-levels
kb_version: 3.1
prerequisites: []
related_topics: ['testing', 'javascript', 'unit-tests']
embedding_keywords: [jest-app-testing, index, navigation, map]
last_reviewed: 2025-11-13
---

# Jest App Testing Index

Use this index to navigate the 11-part series plus reference files. Each entry links to this project source examples so you can jump from docs to code quickly.

## 0. Orientation
- [README.md](./README.md) — value prop + learning paths
- [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) — snippets + checklists
- [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md) — real implementations
- [.metadata.json](./.metadata.json) — generation metadata (created after quality pass)

## 1. Fundamentals → [01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md)
- Testing pyramid tuned for this project (70/20/10 split)
- Naming conventions (`<feature>.<behavior>.spec` or `feature.behavior.test.tsx`)
- AAA + Given/When/Then templates
- Decision tree: Jest vs Playwright vs Vitest

## 2. Setup & Config → [02-SETUP-AND-CONFIG.md](./02-SETUP-AND-CONFIG.md)
- `next/jest` wrapper, `ts-jest` alternatives
- JSDOM vs Node environment selection
- Coverage budgets + JSTest watchers
- Locally running tests inside Dockerized dev server

## 3. Directory Architecture → [03-TEST-DIRECTORY-ARCHITECTURE.md](./03-TEST-DIRECTORY-ARCHITECTURE.md)
- When to place files under `__tests__` vs `tests/`
- Collocating fixtures under `__tests__/__fixtures__`
- How to mirror `app/` routes with spec names

## 4. Component Testing → [04-COMPONENT-TESTING.md](./04-COMPONENT-TESTING.md)
- React Testing Library helpers
- Accessibility assertions with `jest-axe`
- Interaction helpers via `@testing-library/user-event`

## 5. Hooks & State → [05-HOOKS-AND-STATE.md](./05-HOOKS-AND-STATE.md)
- Testing custom hooks with `renderHook`
- Mocking Zustand stores and context providers
- Ensuring timers/promises resolved between assertions

## 6. App Router Actions → [06-APP-ROUTER-ACTIONS.md](./06-APP-ROUTER-ACTIONS.md)
- Testing server actions with Node environment
- Mocking `cookies` + `headers`
- Validating revalidation tags and caches

## 7. API Routes & Edge Functions → [07-API-ROUTES-AND-EDGE.md](./07-API-ROUTES-AND-EDGE.md)
- Testing `app/api/*/route.ts`
- Using `NextRequest` mocks and `msw`
- Edge runtime constraints

## 8. Data + Prisma Harness → [08-DATA-AND-PRISMA.md](./08-DATA-AND-PRISMA.md)
- Mocking Prisma client modules
- Using `@jest-environment node`
- Resetting deterministic fixtures between specs

## 9. External Services & AI → [09-MOCKING-EXTERNAL-SERVICES.md](./09-MOCKING-EXTERNAL-SERVICES.md)
- Mocking Vercel AI SDK, Slack webhooks, email providers
- Snapshotting prompts and responses
- Guardrails for error-path coverage

## 10. Integration + Hybrid E2E → [10-INTEGRATION-AND-E2E-HYBRIDS.md](./10-INTEGRATION-AND-E2E-HYBRIDS.md)
- When to keep integration tests in Jest vs Playwright
- Wiring msw handlers + Prisma fakes for multi-hop flows
- Golden path specs for LLM pipelines

## 11. CI, Coverage, Observability → [11-CI-OBSERVABILITY.md](./11-CI-OBSERVABILITY.md)
- How GitHub Actions runs `npm run test:coverage`
- Coverage budget alarms + pull request checks
- Debugging flaky specs with artifacts + logs

## Quick Filters
- **By Layer**: [Unit (01,04,05)](./04-COMPONENT-TESTING.md), [Integration (06,07,08,10)](./08-DATA-AND-PRISMA.md), [System (09,10,11)](./09-MOCKING-EXTERNAL-SERVICES.md)
- **By Concern**: [Accessibility](./04-COMPONENT-TESTING.md#accessibility-regressions), [Data Integrity](./08-DATA-AND-PRISMA.md#transaction-scenarios), [AI Safety](./09-MOCKING-EXTERNAL-SERVICES.md#ai-specific-guards)

## Source Map
| this project Code | Reference |
|------------|-----------|
| `jest.config.cjs` | 02 Setup & Config |
| `jest.setup.js` | 02 Setup & Config |
| `__tests__/components/home/Hero.test.tsx` | 04 Component Testing |
| `tests/services/LLMService.test.ts` | 08 Data + 09 External |
| `tests/integration/runs-with-llm.test.ts` | 10 Integration |
| `tests/integration/recap-api.test.ts` | 07 API Routes |
| `app/api/recap/route.ts` | 07 API Routes |
| `lib/services/LLMService.ts` | 09 External Services |

## How to Contribute
1. Update relevant numbered file
2. Re-run lint/format if necessary
3. Add entry to this index (keep alphabetical order when possible)
4. Update `docs/kb/README.md` status table
