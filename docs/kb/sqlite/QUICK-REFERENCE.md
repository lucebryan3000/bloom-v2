---
id: sqlite-quick-reference
topic: sqlite
file_role: quickref
profile: full
difficulty_level: all-levels
kb_version: 3.1
prerequisites: []
related_topics: ['sqlite']
embedding_keywords: [sqlite, quick-reference, cheat-sheet, syntax]
last_reviewed: 2025-11-13
---

# SQLite Quick Reference

Snippets and commands aligned with this project’s tooling. Copy/paste directly into terminals, scripts, or AI prompts.

---

## CLI Basics

```bash
sqlite3 app-dev.db <<'SQL'
.timeout 3000
.mode table
.headers on
SELECT name FROM sqlite_master WHERE type='table';
SQL
```

✅ Set `.timeout` before running heavy statements.
❌ Forgetting to enable headers when exporting CSVs.

---

## Enable WAL + Busy Timeout

```sql
PRAGMA journal_mode=WAL;
PRAGMA synchronous=NORMAL;
PRAGMA busy_timeout=3000;
PRAGMA wal_autocheckpoint=1000;
```

Run once per connection (app startup) or include in connection factory.

---

## better-sqlite3 Connection Helper

```ts
import Database from "better-sqlite3";

export const db = new Database("file:./app-dev.db", {
 verbose: (msg) => logger.debug({ msg }),
});

db.pragma("journal_mode = WAL");
db.pragma("busy_timeout = 3000");

export const queries = {
 selectOpportunity: db.prepare(
 `SELECT * FROM opportunities WHERE id = ?`
 ),
 upsertOpportunity: db.prepare(
 `INSERT INTO opportunities (id, customer, annual_value)
 VALUES (@id, @customer, @annual_value)
 ON CONFLICT(id) DO UPDATE SET
 customer=excluded.customer,
 annual_value=excluded.annual_value`
 ),
};
```

---

## Prisma Connection (SQLite)

`DATABASE_URL="file:./app-dev.db"`

```ts
import { PrismaClient } from "@prisma/client";

export const prisma = new PrismaClient({
 datasourceUrl: process.env.DATABASE_URL,
});
```

Run `PRAGMA` statements using `$executeRawUnsafe('PRAGMA...')` after connecting (Chapter 07).

---

## Seed Script

```ts
import { db } from "./db";

const insert = db.prepare(`
 INSERT INTO opportunities (id, customer, annual_value)
 VALUES (@id, @customer, @annual_value)
`);

db.transaction((rows) => {
 for (const row of rows) insert.run(row);
})([
 { id: "opp_1", customer: "Acme", annual_value: 100000 },
 { id: "opp_2", customer: "Globex", annual_value: 64000 },
]);
```

---

## Dump & Restore

```bash
sqlite3 app-dev.db ".backup 'backups/$(date +%F)-app-dev.db'"
sqlite3 app-dev.db ".dump" > dumps/app-dev.sql
sqlite3 new.db < dumps/app-dev.sql
```

---

## sqldiff

```bash
sqldiff staging.db prod.db > delta.sql
sqlite3 staging.db < delta.sql
```

✅ Inspect diff before applying to prod.
❌ Running sqldiff directly on mounted volumes without snapshot.

---

## Playwright Fixture Template

```ts
import { test as base } from "@playwright/test";
import fs from "node:fs";

export const test = base.extend({
 sqliteDb: async ({}, use) => {
 const tmp = `/tmp/sqlite-${Date.now}.db`;
 fs.copyFileSync("tests/fixtures/appseed.db", tmp);
 await use(tmp);
 fs.rmSync(tmp, { force: true });
 },
});
```

Use in tests:

```ts
test("reads opportunities", async ({ page, sqliteDb }) => {
 await page.route("/api/local/opportunities", (route) =>
 route.fulfill({ path: sqliteDb })
 );
});
```

---

## Health Check Query

```ts
const stmt = db.prepare("SELECT 1 as ok, sqlite_version as version");
const result = stmt.get;
if (!result?.ok) throw new Error("sqlite offline");
```

Log `version` for diagnostics.

---

## WAL Checkpoint Script

```bash
sqlite3 app-dev.db "PRAGMA wal_checkpoint(TRUNCATE);"
rm -f app-dev.db-shm
```

Schedule via cron for long-running dev servers.

---

## Busy Handler Example

```ts
db.pragma("busy_timeout = 5000");
db.function("sleep", (ms: number) => Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, ms));
```

Use to wait for lock release when running migrations.

---

## JSON Query

```sql
SELECT
 json_extract(metadata, '$.owner') as owner,
 json_extract(metadata, '$.score') as score
FROM reports
WHERE json_type(metadata, '$.score') = 'number';
```

Add `CREATE INDEX reports_owner_idx ON reports(json_extract(metadata,'$.owner'));`

---

## Full-Text Search (FTS5)

```sql
CREATE VIRTUAL TABLE search_content USING fts5(
 title,
 body,
 content='documents',
 content_rowid='id'
);
```

Populate via triggers (Chapter 03).

---

Use this cheat sheet with the deeper chapters for rationale and framework-specific references.
