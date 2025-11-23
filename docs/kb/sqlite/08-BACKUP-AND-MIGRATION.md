---
id: sqlite-08-backup-and-migration
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

# 08 · Backup & Migration

SQLite backups are lightweight but must be consistent. This chapter covers `sqlite3.backup`, `.dump`, `sqldiff`, and Postgres uplift steps.

---

## 1. Backup Strategies

| Strategy | Command | Use Case |
|----------|---------|----------|
| Hot backup | `.backup` | Live service snapshot |
| Logical dump | `.dump` | Schema + data for transports |
| File copy | `cp this project.db backup.db` | When DB idle / WAL checkpointed |

```bash
sqlite3 app-dev.db ".backup './backups/app-dev-$(date +%s).db'"
```

---

## 2. WAL Checkpoint Before Backup

```bash
sqlite3 app-dev.db "PRAGMA wal_checkpoint(FULL);"
sqlite3 app-dev.db ".backup 'backups/app-dev.db'"
```

Ensures `.db` contains latest pages.

---

## 3. Automated Script

`scripts/sqlite-backup.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail
DB_PATH="${SQLITE_DB_PATH:-app-dev.db}"
OUT="backups/$(basename "$DB_PATH").$(date +%F-%H%M%S).db"
sqlite3 "$DB_PATH" "PRAGMA wal_checkpoint(FULL);"
sqlite3 "$DB_PATH" ".backup '$OUT'"
echo "backup saved to $OUT"
```

Cron entry:

```
0 * * * * /app/scripts/sqlite-backup.sh
```

---

## 4. sqldiff

Generate migration script between environments:

```bash
sqldiff staging.db prod.db > migrate-staging-to-prod.sql
sqlite3 staging.db < migrate-staging-to-prod.sql
```

✅ Inspect diff before applying.
❌ Running diff between mismatched schema versions (compare versions first).

---

## 5. Export to Postgres

Steps:
1. `sqlite3 app-dev.db.schema > schema.sql`
2. Hand-convert types (e.g., `TEXT` → `UUID`, `REAL` → `NUMERIC`).
3. Use `pgloader`:

```lisp
LOAD DATABASE
 FROM sqlite://app-dev.db
 INTO postgres://postgres@localhost/this project
WITH include drop, create tables;
```

Document type mappings to avoid silent coercions.

---

## 6. Restore From Dump

```bash
sqlite3 this project-restore.db < dumps/app-dev.sql
```

For WAL-enabled DB, run `PRAGMA journal_mode=WAL;` after restore.

---

## 7. Deterministic Fixtures

1. Prepare DB to desired state.
2. Run `.backup tests/fixtures/appseed.db`.
3. Tests copy this file into temp directories (Chapter 09).

---

## 8. ✅ / ❌ Backup Ops

| ✅ Do | ❌ Don’t |
|------|----------|
| Keep three most recent backups | Hoard unlimited `.db` without rotation |
| Store backups encrypted | Leave `.db` readable in artifact storage |
| Document migration steps | Run ad-hoc commands without runbook |

---

## 9. Troubleshooting

| Issue | Fix |
|-------|-----|
| `sqlite3: command not found` in CI | Install `apt-get install sqlite3` in pipeline |
| WAL present after restore | Run `PRAGMA wal_checkpoint(TRUNCATE);` |
| `sqldiff` missing | Ensure `sqlite-diff` package installed (macOS includes) |

---

## 10. References

- sqlite.org/backup.html
- pgloader documentation
