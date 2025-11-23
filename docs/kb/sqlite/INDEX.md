---
id: sqlite-index
topic: sqlite
file_role: navigation
profile: full
difficulty_level: all-levels
kb_version: 3.1
prerequisites: []
related_topics: ['sqlite']
embedding_keywords: [sqlite, index, navigation, map]
last_reviewed: 2025-11-13
---

# SQLite KB Index

Use this index to find the fastest path to any SQLite topic in this project’s stack. Tables list the canonical file for each scenario plus key search keywords.

---

## Navigation Map

| Section | Jump To | Highlights |
|---------|---------|------------|
| Fundamentals | [01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md) | Lifecycle, file types, journaling |
| Tooling & Setup | [02-SETUP-AUTH.md](./02-SETUP-AUTH.md) | CLI, drivers, encryption |
| Data Modeling | [03-SCHEMA-DESIGN.md](./03-SCHEMA-DESIGN.md) | Data types, constraints |
| Querying | [04-QUERY-PATTERNS.md](./04-QUERY-PATTERNS.md) | CRUD, pagination, window fn |
| Concurrency | [05-CONCURRENCY-AND-WAL.md](./05-CONCURRENCY-AND-WAL.md) | WAL, busy handlers |
| Tuning | [06-PRAGMA-TUNING.md](./06-PRAGMA-TUNING.md) | pragmas, cache, fts5 |
| Integrations | [07-ORM-INTEGRATIONS.md](./07-ORM-INTEGRATIONS.md) | Prisma, Drizzle, better-sqlite3 |
| Migrations | [08-BACKUP-AND-MIGRATION.md](./08-BACKUP-AND-MIGRATION.md) | Dump/restore, sqldiff |
| Testing | [09-TESTING-AND-FIXTURES.md](./09-TESTING-AND-FIXTURES.md) | Playwright fixtures |
| Observability | [10-OBSERVABILITY.md](./10-OBSERVABILITY.md) | Logging, tracing, health |
| Security | [11-GOVERNANCE-AND-SECURITY.md](./11-GOVERNANCE-AND-SECURITY.md) | Encryption, secrets |
| Patterns | [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md) | Real code references |

---

## Tasks → Files

| Task | File | Notes |
|------|------|-------|
| Convert dev DB to WAL | 05-CONCURRENCY-AND-WAL | Step-by-step CLI + Node examples |
| Add JSON column | 03-SCHEMA-DESIGN | Uses `json_extract` + indexes |
| Build pagination API | 04-QUERY-PATTERNS | Offset/limit vs keyset patterns |
| Capture Playwright fixture | 09-TESTING-AND-FIXTURES | Template for zipped DBs |
| Export to Postgres | 08-BACKUP-AND-MIGRATION | `pgloader` + `sqlite3.dump` combo |
| Instrument queries | 10-OBSERVABILITY | OTEL spans with query text redaction |

---

## this project Integration References

| Integration | Path | File |
|-------------|------|------|
| `apps/roi-app/app/api/local/rois/route.ts` | Local-first API using better-sqlite3 | Framework-Specific-PATTERNS |
| `packages/db/sqlite/client.ts` | Shared connection factory | 07-ORM-INTEGRATIONS & this project patterns |
| `packages/testing/sqlite-fixtures.ts` | Snapshot + reset helper | 09-TESTING-AND-FIXTURES |
| `scripts/sqlite-backup.sh` | Cron-compatible backup | 08-BACKUP-AND-MIGRATION |

---

## Keyword Hints

| Keyword | Where |
|---------|-------|
| `busy_timeout` | Chapter 05 |
| `wal_checkpoint` | Chapter 05 & 06 |
| `sqldiff` | Chapter 08 |
| `better-sqlite3` | Chapter 07 & QUICK-REFERENCE |
| `fts5` | Chapter 03 & 06 |
| `SQLCipher` | Chapter 02 & 11 |

---

## Quick Reference Crosslinks

| Need | Quick Entry | Deep Dive |
|------|-------------|-----------|
| `sqlite3` CLI cheat sheet | QUICK-REFERENCE → CLI | Chapter 02 |
| Node connection snippet | QUICK-REFERENCE → better-sqlite3 | Chapter 07 |
| WAL tuning script | QUICK-REFERENCE → PRAGMAS | Chapter 05/06 |
| Backup command | QUICK-REFERENCE → Backup | Chapter 08 |

---

## Contribution Notes

- Add new keywords to the table so search stays accurate.
- Cross-link the file paths whenever referencing in numbered chapters.
- Keep table rows alphabetized when practical.

---

Use this index before diving into the numbered chapters; it shortens lookup time and keeps KB navigation predictable.
