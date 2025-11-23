---
id: sqlite-07-orm-integrations
topic: sqlite
file_role: detailed
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [sqlite-basics]
related_topics: ['sqlite']
embedding_keywords: [sqlite]
last_reviewed: 2025-11-13
---

# 07 · ORM Integrations

SQLite appears across this project using multiple libraries: Prisma for schema-first APIs, Drizzle for type-safe queries, Kysely for builder patterns, and better-sqlite3 for lightweight scripts.

---

## 1. Prisma Setup

`schema.prisma`

```prisma
datasource db {
 provider = "sqlite"
 url = env("DATABASE_URL")
}

generator client {
 provider = "prisma-client-js"
 binaryTargets = ["native"]
}
```

Generate client:

```bash
pnpm prisma generate --schema prisma/sqlite.schema
```

---

### Prisma Client Usage

```ts
import { PrismaClient } from "@prisma/client";

export const prisma = new PrismaClient;

await prisma.opportunity.create({
 data: {
 id: "opp_123",
 customer: "Acme",
 annualValue: 120000,
 },
});
```

✅ Keep `DATABASE_URL` relative to repo root.
❌ Using absolute path that breaks in CI.

---

## 2. Prisma Accelerate Limitations

Accelerate/Driverless features target Postgres/MySQL only; disable for SQLite projects.

---

## 3. Drizzle ORM

```ts
import { drizzle } from "drizzle-orm/better-sqlite3";
import Database from "better-sqlite3";
import { opportunities } from "./schema";

const sqlite = new Database("app-dev.db");
const db = drizzle(sqlite);

const rows = await db.select.from(opportunities).all;
```

`schema.ts`:

```ts
import { sqliteTable, text, real } from "drizzle-orm/sqlite-core";

export const opportunities = sqliteTable("opportunities", {
 id: text("id").primaryKey,
 customer: text("customer").notNull,
 annualValue: real("annual_value").notNull,
});
```

---

## 4. Kysely Example

```ts
import { Kysely, SqliteDialect } from "kysely";
import Database from "better-sqlite3";

interface DatabaseSchema { /*... */ }

const db = new Kysely<DatabaseSchema>({
 dialect: new SqliteDialect({
 database: new Database("app-dev.db"),
 }),
});
```

---

## 5. better-sqlite3 Direct Access

Use when low-level pragmas or user-defined functions needed.

```ts
db.function("slugify", (value: string) =>
 value.toLowerCase.replace(/\s+/g, "-")
);
```

---

## 6. Migrations

| Tool | Approach |
|------|----------|
| Prisma | `prisma migrate dev --name init` |
| Drizzle Kit | `drizzle-kit generate:sqlite` |
| Knex | `knex migrate:latest` |

Pick one per service to avoid drift. Export SQL to review.

---

## 7. Testing

Prisma: `prisma db push --force-reset --skip-generate` for test DBs.
Drizzle: `drizzle-kit push:sqlite`.
For better-sqlite3, copy template `.db`.

---

## 8. ✅ / ❌ Integration Choices

| Scenario | Use | Avoid |
|----------|-----|-------|
| Schema-first API | Prisma | Raw SQL without migrations |
| Edge worker | Drizzle + better-sqlite3 | Prisma (due to binary target) |
| CLI utility | better-sqlite3 | Heavy ORM |

---

## 9. Troubleshooting

| Issue | Fix |
|-------|-----|
| Prisma “binary target not available” | Run `pnpm prisma generate` on deploy target |
| better-sqlite3 build fails | Install build tools (`xcode-select --install` or `build-essential`) |
| Drizzle schema mismatch | Regenerate types after schema change |

---

## 10. References

- prisma.io/docs/databases/sqlite
- drizzle.team/docs/sqlite-core
