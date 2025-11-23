---
id: sqlite-framework-specific-patterns
topic: sqlite
file_role: patterns
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: []
related_topics: ['sqlite']
embedding_keywords: [sqlite, patterns, examples, integration]
last_reviewed: 2025-11-13
---

# Framework-Specific SQLite Patterns

Grounded references to the repositories. Use these when writing assistants or updating documentation so answers cite actual files.

---

## 1. Shared Connection Factory

`packages/db/sqlite/client.ts`

```ts
import Database from "better-sqlite3";

let db: Database | null = null;

export function getSqlite {
 if (!db) {
 db = new Database(process.env.SQLITE_DB_PATH ?? "app-dev.db");
 db.pragma("journal_mode = WAL");
 db.pragma("busy_timeout = 3000");
 db.pragma("foreign_keys = ON");
 }
 return db;
}
```

---

## 2. Next.js Local API Route

`apps/roi-app/app/api/local/opportunities/route.ts`

```ts
import { NextResponse } from "next/server";
import { getSqlite } from "@/packages/db/sqlite/client";

export async function GET {
 const db = getSqlite;
 const rows = db.prepare("SELECT * FROM opportunities LIMIT 200").all;
 return NextResponse.json({ rows });
}
```

✅ Runs only in local dev or offline-first deployments.

---

## 3. Prisma Schema (SQLite flavor)

`apps/roi-api/prisma/sqlite.schema`

```prisma
model Opportunity {
 id String @id
 customer String
 annualValue Float
 metadata Json?
 createdAt DateTime @default(now)
}
```

Used for CLI analytics and test suites when Postgres unavailable.

---

## 4. Testing Fixtures

`packages/testing/sqlite-fixtures.ts`

```ts
import fs from "node:fs";
import path from "node:path";

const template = path.resolve(__dirname, "../fixtures/appseed.db");

export function createFixtureDb {
 const tmp = path.join(process.env.TMPDIR ?? "/tmp", `sqlite-${Date.now}.db`);
 fs.copyFileSync(template, tmp);
 return tmp;
}
```

Playwright + Vitest tests depend on this helper.

---

## 5. CLI Utilities

`scripts/sqlite/checkpoint.ts`

```ts
import { getSqlite } from "@/packages/db/sqlite/client";

export async function truncateWal {
 const db = getSqlite;
 db.pragma("wal_checkpoint(TRUNCATE)");
 console.log("WAL truncated");
}
```

Cron job `scripts/lifecycle/sqlite-checkpoint.sh` wraps this command nightly.

---

## 6. Backup Workflow

`scripts/sqlite-backup.sh` (see Chapter 08) runs through GitHub Actions workflow `db-cleanup.yml`, pushing encrypted backups to S3.

---

## 7. Observability Hooks

`packages/telemetry/sqliteSpan.ts`

```ts
export function instrumentSqlite<T>(operation: string, fn: => T) {
 const span = tracer.startSpan("sqlite." + operation, {
 attributes: { "db.system": "sqlite" },
 });
 try {
 return fn;
 } finally {
 span.end;
 }
}
```

Use inside better-sqlite3 wrappers.

---

## 8. Migration Playbook

`docs/kb/templates/SQLITE-MIGRATION.md` outlines steps to copy data to Postgres, update env vars, and delete `.db` once done. Link new migrations to this doc.

---

## 9. Security Notes

`.env.example` documents `SQLITE_ENCRYPTION_KEY_FILE`. Real key stored under `infrastructure/secrets/sqlite-key`. Access limited to AI Platform + Security.

---

## 10. Local-first Sync Service

`apps/offline-sync/src/storage/sqliteStore.ts`

```ts
export class SqliteStore {
 private db = getSqlite;

 listPendingSync(limit = 50) {
 return this.db.prepare(`
 SELECT * FROM sync_queue
 WHERE synced_at IS NULL
 ORDER BY created_at ASC
 LIMIT ?
 `).all(limit);
 }
}
```

Used by field agents to capture ROI data offline before syncing to cloud.

---

Use these references when grounding AI responses or onboarding engineers so instructions tie back to actual code.
