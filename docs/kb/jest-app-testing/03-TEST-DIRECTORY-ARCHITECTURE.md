---
id: jest-app-testing-03-test-directory-architecture
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

# 03 · Test Directory Architecture

## High-Level Layout
```
app/
├── __tests__/ # fast unit + component specs
│ └── components/
├── tests/
│ ├── services/ # Node env unit/integration
│ ├── integration/ # API + workflow specs
│ └── prompts/ # Snapshot harnesses
└── tests/.tmp/ # Runtime artifacts (gitignored)
```

## Placement Rules
| Scenario | Directory |
|----------|-----------|
| React component, hook, util | `__tests__/` |
| Server action, Prisma-heavy logic | `tests/services/` |
| Multi-hop workflow (API + DB + AI) | `tests/integration/` |
| Prompt mutations & snapshots | `tests/prompts/` |

## Naming
- `__tests__/components/home/Hero.test.tsx`
- `tests/integration/runs-with-llm.test.ts`
- `tests/services/LLMService.test.ts`

## Fixture Placement
- Single-use JSON? Keep inline using helper `buildFixture`.
- Shared fixtures → `tests/fixtures/<domain>.ts`.
- Binary/test files (CSV, Markdown) → `tests/fixtures/files/`.

## File Header Template
```ts
/**
 * @jest-environment node
 */
```
Use when DOM not required or to speed up Node-based suites.

## Avoiding Circular Imports
- Do not import test files from other tests.
- Export builder utilities from `tests/fixtures` or `lib/test-utils` if they must be shared.

## Test Data Storage
- Keep `tests/.tmp` for runtime output; clean with `rimraf tests/.tmp/*` in `afterEach` if necessary.
- Add `.gitkeep` if directory needs to exist empty.

## Snapshot Organization
- Collocate `__snapshots__` with spec file.
- Name snapshot files after test file: `Hero.test.tsx.snap`.
- Keep snapshot count low; prefer semantic assertions.

## Accessibility Utilities
- Place custom matchers in `tests/utils/a11y.ts` and import where needed.

## Config Awareness
- `testPathIgnorePatterns` currently excludes `tests/e2e` and `playwright/`. Keep e2e in Playwright tree to avoid double execution.
