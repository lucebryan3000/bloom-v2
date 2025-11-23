---
id: sqlite-09-testing-and-fixtures
topic: sqlite
file_role: detailed
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [sqlite-basics]
related_topics: ['sqlite']
embedding_keywords: [sqlite, testing]
last_reviewed: 2025-11-13
---

# 09 · Testing & Fixtures

SQLite excels at deterministic testing. Use template databases, Playwright fixtures, and Vitest helpers to ensure reproducible suites.

---

## 1. Template Database Flow

1. Prepare canonical DB: run migrations + seeds.
2. `sqlite3 this project-test.db ".backup tests/fixtures/appseed.db"`.
3. Each test copies template → temp file.
4. Tests operate on isolated copy; tear down after run.

```ts
import fs from "node:fs";

export function createTestDb {
 const tmp = `/tmp/sqlite-${crypto.randomUUID}.db`;
 fs.copyFileSync("tests/fixtures/appseed.db", tmp);
 return tmp;
}
```

---

## 2. Playwright Fixture

```ts
import { test as base } from "@playwright/test";
import fs from "node:fs";

export const test = base.extend({
 sqliteDb: async ({}, use) => {
 const dbPath = createTestDb;
 await use(dbPath);
 fs.rmSync(dbPath, { force: true });
 fs.rmSync(`${dbPath}-wal`, { force: true });
 },
});
```

---

## 3. Vitest Hooks

```ts
import Database from "better-sqlite3";

let db: Database;

beforeAll( => {
 db = new Database(createTestDb);
});

afterAll( => db.close);
```

---

## 4. Prisma Test Strategy

Use file-based `DATABASE_URL="file:./tests/tmp/test.db"` and run:

```bash
pnpm prisma migrate deploy --schema prisma/sqlite.schema
pnpm prisma db seed
```

Wrap in script `pnpm test:prepare-sqlite`.

---

## 5. Snapshotting Queries

Capture deterministic outputs:

```ts
const result = db.prepare("SELECT * FROM opportunities ORDER BY id").all;
expect(result).toMatchInlineSnapshot;
```

Reset DB before each test to avoid drift.

---

## 6. CI Considerations

- Ensure `.db` files stored in writable workspace.
- Delete `-shm`/`-wal` files to reduce artifact size.
- Use `tmpfs` for speed when available.

---

## 7. ✅ / ❌ Testing Patterns

| ✅ Pattern | ❌ Anti-pattern |
|-----------|-----------------|
| Copy template per test worker | Share single DB across parallel tests |
| Run migrations inside test setup | Assume dev DB already exists |
| Remove WAL files after tests | Leave stale WAL causing future lock |

---

## 8. Troubleshooting

| Issue | Fix |
|-------|-----|
| `database is locked` in CI tests | Increase busy timeout; ensure no process holds DB |
| Tests fail on Windows path | Use `path.join(os.tmpdir,...)` |
| Prisma tests slow | Use `npm_config_prisma_query_engine_type=binary` to avoid WASM |

---

## 9. References

- this project `packages/testing/sqlite-fixtures.ts`
- Playwright documentation on test fixtures
