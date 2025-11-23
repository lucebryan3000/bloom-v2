---
id: jest-app-testing-08-data-and-prisma
topic: jest-app-testing
file_role: detailed
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [jest-app-testing-basics]
related_topics: ['testing', 'javascript', 'unit-tests']
embedding_keywords: [jest-app-testing]
last_reviewed: 2025-11-13
---

# 08 · Data & Prisma Harness

## Mocking Prisma Client
```ts
jest.mock('@/lib/prisma', => ({
 __esModule: true,
 default: {
 run: {
 findUnique: jest.fn,
 create: jest.fn,
 update: jest.fn,
 },
 runStep: {
 create: jest.fn,
 },
 playbook: {
 findUnique: jest.fn,
 },
 },
}))
```
- Export named mocks for reuse inside tests if needed.

## Deterministic Fixtures
- Build TypeScript fixtures replicating Prisma schema (see `tests/services/LLMService.test.ts`).
- Use `as Run` or `as Playbook` to satisfy typing.

## Transactions & Batching
- Simulate `prisma.$transaction` by mocking function returning array results.

```ts
;(prisma.$transaction as jest.Mock).mockImplementation(async (ops) => Promise.all(ops))
```

## Error Paths
- Force `prisma.run.create` to throw to validate retries/fallbacks.
- Assert telemetry hooks capture error metadata.

## SQLite vs In-Memory
- Jest tests should not hit actual SQLite file to avoid locking.
- For rare cases requiring DB, spin up temporary database under `tests/.tmp/test.sqlite` and clean up after.

## Seed Data Strategy
- Keep `tests/fixtures/playbooks.ts` listing minimal canonical playbooks.
- Document each fixture field to prevent drift when schema changes.

## Snapshotting Data
- Avoid snapshotting entire Prisma responses; prefer shape assertions.

## Resetting Between Tests
- In `beforeEach`, reset mocks: `(prisma.run.create as jest.Mock).mockReset`.
- Provide helper `resetPrismaMocks` in fixture file.

## Type Safety
- Import Prisma types from `@prisma/client` when describing expected payloads.
- When mocking nested selects, ensure object shape matches actual query to catch renames.

## Performance Tips
- Node environment prevents unnecessary DOM rendering for data-heavy suites.
- Use `--runInBand` for specs that mutate large global mocks to avoid cross-test interference.
