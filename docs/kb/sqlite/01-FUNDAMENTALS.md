---
id: sqlite-01-fundamentals
topic: sqlite
file_role: detailed
profile: full
difficulty_level: beginner
kb_version: 3.1
prerequisites: [sqlite-basics]
related_topics: ['sqlite']
embedding_keywords: [sqlite]
last_reviewed: 2025-11-13
---

# 01 · SQLite Fundamentals

Understand what makes SQLite suited for this project’s local-first workflows, how files are structured, and the default journaling/locking model.

---

## 1. Core Architecture

- Single-file DB containing pages (default 4 KB).
- Page cache sits inside process; locking occurs via file locks.
- Journaling options: `DELETE`, `TRUNCATE`, `PERSIST`, `WAL`.

```
Application → VFS → OS file handles → sqlite.db / sqlite.db-wal / sqlite.db-shm
```

Use WAL for most services; fallback to default journal when running on read-only media.

---

## 2. Lifecycle

| Stage | Action | this project Usage |
|-------|--------|-------------|
| Initialize | `sqlite3 app-dev.db` | Generated in dev containers |
| Migrate | Prisma/SQL files | `pnpm prisma migrate deploy` |
| Operate | Read/write via better-sqlite3 | Local ROI agents |
| Archive | `.backup` or zipped file | Playwright fixtures |

---

## 3. File Anatomy

| File | Purpose |
|------|---------|
| `app-dev.db` | main database |
| `app-dev.db-wal` | write-ahead log |
| `app-dev.db-shm` | shared memory for WAL metadata |

✅ Commit schema, not `.db`.
❌ Delete `-wal` while process active; use checkpoint first.

---

## 4. Locking Model (simplified)

| Lock | Description |
|------|-------------|
| `SHARED` | Readers |
| `RESERVED` | Writer intent |
| `PENDING` | Preparing to write |
| `EXCLUSIVE` | Write access |

WAL separates readers/writers, enabling concurrent reads.

---

## 5. ✅ / ❌ Patterns

| ✅ Recommended | ❌ Avoid |
|---------------|---------|
| Keep DB per environment (`app-dev.db`, `this project-test.db`) | Using same file for all workflows |
| Run `PRAGMA integrity_check;` weekly | Ignoring verification |
| Document page size & pragmas | Hard-coding defaults |

---

## 6. Integrity Checks

```bash
sqlite3 app-dev.db "PRAGMA integrity_check;"
sqlite3 app-dev.db "PRAGMA quick_check;"
```

Schedule via cron or CI after migrations.

---

## 7. WAL vs Rollback Journal

| Aspect | WAL | Rollback |
|--------|-----|----------|
| Read concurrency | ✅ Many readers | ⚠️ Blocked by writers |
| Durability | ✅ (SYNC=NORMAL/ FULL) | ✅ |
| File count | `.db`, `.db-wal`, `.db-shm` | `.db`, journal file |

Switch with `PRAGMA journal_mode=WAL;`.

---

## 8. Storage Limits

- Default max DB size: 281 TB (64-bit).
- Max columns: 2000 (practical limit smaller).
- Use `PRAGMA page_size = 8192;` before creating tables when expecting large DBs.

---

## 9. Troubleshooting

| Symptom | Root Cause | Fix |
|---------|------------|-----|
| `database is locked` | No busy timeout | `PRAGMA busy_timeout=3000;` |
| `disk I/O error` | File path invalid / read-only | Validate path, mount RW volume |
| `malformed database schema` | Partial migration | Restore from backup or re-run migrations |

---

## 10. References

- sqlite.org/lockingv3.html
- this project Notion “Local-first stack”
