---
id: sqlite-readme
topic: sqlite
file_role: overview
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: []
related_topics: ['sqlite']
embedding_keywords: [sqlite, overview, introduction, getting-started]
last_reviewed: 2025-11-13
---

# SQLite Knowledge Base

**Status**: Draft
**Last Updated**: November 2025
**Version**: 0.8.0

this project relies on SQLite for embedded analytics, offline-first ROI capture, prototype services, and deterministic test harnesses. This KB mirrors the TypeScript KB standards while focusing on high-leverage SQLite topics: file lifecycle, WAL tuning, Prisma + Drizzle workflows, and framework-specific patterns such as local-first sync and Playwright fixtures.

---

## Why SQLite?

- **Deterministic dev experience** – portable single-file DBs for preview deployments and Playwright tests.
- **Edge-friendly** – used in Cloudflare Workers/Durable Objects and local ROI agents.
- **Observability** – WAL + tracing ensures reproducible bug reports.
- **Migration bridge** – prototypes begin with SQLite, later uplift to Postgres via compatible schema design.

---

## 11-Part Guide Overview

| # | File | Focus |
|---|------|-------|
| 01 | [01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md) | File formats, journaling, lifecycle |
| 02 | [02-SETUP-AUTH.md](./02-SETUP-AUTH.md) | Tooling, drivers, encryption options |
| 03 | [03-SCHEMA-DESIGN.md](./03-SCHEMA-DESIGN.md) | Data types, pragmas, normalization |
| 04 | [04-QUERY-PATTERNS.md](./04-QUERY-PATTERNS.md) | CRUD, pagination, window functions |
| 05 | [05-CONCURRENCY-AND-WAL.md](./05-CONCURRENCY-AND-WAL.md) | WAL tuning, connection pooling, busy handlers |
| 06 | [06-PRAGMA-TUNING.md](./06-PRAGMA-TUNING.md) | Performance switches, cache size, journal modes |
| 07 | [07-ORM-INTEGRATIONS.md](./07-ORM-INTEGRATIONS.md) | Prisma, Drizzle, Kysely, better-sqlite3 |
| 08 | [08-BACKUP-AND-MIGRATION.md](./08-BACKUP-AND-MIGRATION.md) | Dump/restore, sqldiff, Postgres uplift |
| 09 | [09-TESTING-AND-Fixtures.md](./09-TESTING-AND-FIXTURES.md) | Playwright, Vitest, snapshot DBs |
| 10 | [10-OBSERVABILITY.md](./10-OBSERVABILITY.md) | Tracing, profiling, health checks |
| 11 | [11-GOVERNANCE-AND-SECURITY.md](./11-GOVERNANCE-AND-SECURITY.md) | Encryption, secret rotation, compliance |

Supporting docs:

- [INDEX.md](./INDEX.md) – search map.
- [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) – CLI/snippet cheatsheet.
- [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md) – actual the file paths (Next.js API routes, migration scripts, tests).

---

## Getting Started

1. **Install tooling** – `brew install sqlite`, `pnpm add better-sqlite3`, `cargo install sqlx-cli`.
2. **Create DB file** – `sqlite3 app-dev.db ".databases"`.
3. **Enable WAL** – `PRAGMA journal_mode=WAL;`.
4. **Run schema migration** – `prisma migrate deploy --schema prisma/sqlite.schema`.
5. **Seed data** – `pnpm db:seed --target=sqlite`.

```bash
sqlite3 app-dev.db <<'SQL'
.mode box
.headers on
PRAGMA journal_mode=WAL;
CREATE TABLE IF NOT EXISTS opportunities (
 id TEXT PRIMARY KEY,
 customer TEXT NOT NULL,
 annual_value REAL NOT NULL
);
INSERT INTO opportunities VALUES ('opp_1','Acme',120000.0);
SQL
```

✅ Commit schema + seed fixtures.
❌ Commit `.db` binaries unless explicitly needed for fixtures (use `.gitignore`).

---

## Common Tasks Cheat Sheet

| Task | Summary | Reference |
|------|---------|-----------|
| Enable WAL in CI | Use `PRAGMA journal_mode=WAL; PRAGMA synchronous=NORMAL;` | Chapter 05 |
| Generate Prisma client | `PRISMA_CLIENT_ENGINE_TYPE=binary pnpm prisma generate --schema prisma/sqlite.schema` | Chapter 07 |
| Dump DB | `sqlite3 app-dev.db.dump > dump.sql` | Chapter 08 |
| Apply sqldiff | `sqldiff prod.db staging.db | sqlite3 staging.db` | Chapter 08 |
| Reset test DB | Copy from template file in `/tmp/this project-sqlite-template.db` | Chapter 09 |

---

## Key Principles

1. **Single writer rule** – keep concurrent writes minimal; use WAL + busy timeouts.
2. **Schema compatibility** – avoid SQLite-only types if Postgres migration is planned.
3. **Deterministic snapshots** – prefer `.db` templates over seeding at runtime for tests.
4. **Pragma hygiene** – set pragmas per connection, not globally.
5. **Telemetry** – log file path + journal mode per service for audits.

Each chapter includes ✅ recommended usage and ❌ anti-patterns demonstrating these principles.

---

## Learning Paths

### Beginner
- Read Chapters 01–04 (fundamentals, setup, schema, query patterns)
- Practice with `sqlite3` CLI and `better-sqlite3` sample scripts
- Use QUICK-REFERENCE snippets during development

### Intermediate
- Chapters 05–07 (WAL, pragmas, ORM integration)
- Implement Prisma + Drizzle side-by-side example
- Configure `better-sqlite3` in Next.js API route with pooling

### Advanced
- Chapters 08–10 (migrations, testing fixtures, observability)
- Build `sqldiff`-driven promotion pipeline
- Add OTEL tracing for SQLite queries

### Expert
- Chapter 11 + this project patterns (security & governance)
- Create SQLite-based offline-first sync service
- Lead migration readiness review to Postgres

---

## Configuration Essentials

| Setting | Default | Notes |
|---------|---------|-------|
| `DATABASE_URL` | `file:./app-dev.db` | Use workspace-relative paths |
| `SQLITE_BUSY_TIMEOUT_MS` | 3000 | Avoid immediate `SQLITE_BUSY` errors |
| `SQLITE_WAL_AUTOCHECKPOINT` | 1000 pages | tune for file size |
| `SQLITE_USE_ENCRYPTION` | false | Use SEE/SQLCipher only when licensed |

---

## Common Issues

- **`SQLITE_BUSY`** – set `PRAGMA busy_timeout=3000;` and ensure WAL mode.
- **File locking in CI** – remove `.db-shm`/`.db-wal` after tests.
- **Schema drift** – track migrations using Prisma `migrations/` per environment.
- **Large WAL files** – configure auto-checkpoint or manual `PRAGMA wal_checkpoint(TRUNCATE);`.

Troubleshooting flows are summarized in Chapter 05 and this project patterns.

---

## File Listing

```
sqlite/
├── README.md
├── INDEX.md
├── QUICK-REFERENCE.md
├── 01-FUNDAMENTALS.md
├── 02-SETUP-AUTH.md
├── 03-SCHEMA-DESIGN.md
├── 04-QUERY-PATTERNS.md
├── 05-CONCURRENCY-AND-WAL.md
├── 06-PRAGMA-TUNING.md
├── 07-ORM-INTEGRATIONS.md
├── 08-BACKUP-AND-MIGRATION.md
├── 09-TESTING-AND-FIXTURES.md
├── 10-OBSERVABILITY.md
├── 11-GOVERNANCE-AND-SECURITY.md
└── FRAMEWORK-INTEGRATION-PATTERNS.md
```

---

## External Resources

- [SQLite Documentation](https://www.sqlite.org/docs.html)
- [SQLite Pragmas](https://www.sqlite.org/pragma.html)
- [Prisma SQLite Guide](https://www.prisma.io/docs/orm/overview/databases/sqlite)
- [Drizzle ORM SQLite](https://orm.drizzle.team/docs/sqlite-core)

---

## Next Steps

1. Follow numbered guides sequentially.
2. Validate services still running SQLite by cross-referencing this project patterns.
3. Expand tests + migration scripts per Chapter 08.
4. Update status to Production-Ready once quality checks in `.codex/commands/kb-codex.md` pass.
