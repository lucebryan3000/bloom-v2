---
id: sqlite-05-concurrency-and-wal
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

# 05 · Concurrency & WAL

Keep SQLite responsive under concurrent workloads by combining WAL mode, busy handlers, and operational hygiene.

---

## 1. Enable WAL

```sql
PRAGMA journal_mode=WAL;
PRAGMA synchronous=NORMAL;
PRAGMA wal_autocheckpoint=1000;
```

Run each time a connection opens. `NORMAL` sync trades some durability for speed; use `FULL` in regulated contexts.

---

## 2. Busy Timeout

```sql
PRAGMA busy_timeout=5000;
```

or via driver:

```ts
db.pragma("busy_timeout = 5000");
```

Prevents `SQLITE_BUSY` when multiple writes occur.

---

## 3. WAL Checkpoints

| Mode | Description |
|------|-------------|
| `PASSIVE` | checkpoint when safe |
| `FULL` | wait for readers |
| `RESTART` | start new WAL |
| `TRUNCATE` | shrink WAL file |

```sql
PRAGMA wal_checkpoint(FULL);
```

Schedule `TRUNCATE` nightly for long-lived services.

---

## 4. Connections

SQLite works best with a small number of long-lived connections. In Next.js or serverless contexts:

```ts
let db: Database | undefined;

export function getDb {
 if (!db) db = createSqliteConnection;
 return db;
}
```

✅ Reuse connection.
❌ Create new `Database` per request.

---

## 5. Reader/Writer Separation

- Use WAL to allow concurrent readers.
- For heavy ETL, run writes in worker queue to avoid collisions.
- Optionally keep separate DB for analytics vs transactions.

---

## 6. WAL on Network Drives

WAL requires shared memory file; network storage must support byte-range locking. For unsupported systems (e.g., Dropbox), revert to rollback journal.

---

## 7. Monitoring Locks

```sql
PRAGMA busy_timeout;
PRAGMA wal_checkpoint_stats;
.locks
```

`.locks` is CLI-only; use `pragma_locked_list` (3.39+) to inspect.

---

## 8. ✅ / ❌ Patterns

| ✅ Good | ❌ Bad |
|--------|-------|
| Use WAL in dev/test/prod | Mixed modes causing surprises |
| Document busy timeout | Hard-coded default 0 |
| Checkpoint before packaging fixture | Copy `.db` while WAL contains uncheckpointed pages |

---

## 9. Troubleshooting

| Symptom | Fix |
|---------|-----|
| `database is locked` after tests | Ensure tests close connections or delete `.db-shm` |
| WAL grows indefinitely | `PRAGMA wal_checkpoint(TRUNCATE)`; reduce long-running readers |
| `attempt to write a readonly database` | Verify file perms + mount options |

---

## 10. References

- sqlite.org/wal.html
- this project `scripts/sqlite/checkpoint.ts`
