---
id: sqlite-06-pragma-tuning
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

# 06 · PRAGMA Tuning

SQLite exposes tuning knobs via `PRAGMA` statements. Apply them deliberately—document defaults and environment-specific overrides.

---

## 1. Common Pragmas

| PRAGMA | Default | this project Recommendation |
|--------|---------|----------------------|
| `journal_mode` | DELETE | WAL |
| `synchronous` | FULL | NORMAL (dev), FULL (prod) |
| `temp_store` | FILE | MEMORY for tests |
| `cache_size` | -2000 (~2 MB) | adjust per workload |
| `foreign_keys` | OFF | ON |
| `busy_timeout` | 0 | 3000–5000 |

---

## 2. Applying Pragmas in Code

```ts
const pragmas = [
 "PRAGMA foreign_keys = ON",
 "PRAGMA journal_mode = WAL",
 "PRAGMA synchronous = NORMAL",
 "PRAGMA cache_size = -8000", // 8k pages = ~32MB
];
pragmas.forEach((sql) => db.pragma(sql));
```

Apply once per connection creation.

---

## 3. Memory Cache

`PRAGMA cache_size = -N` sets size in KiB. Example:

```sql
PRAGMA cache_size = -16384; -- 64MB
```

Monitor `PRAGMA page_count;` to ensure DB fits.

---

## 4. Temp Store

For test suites with heavy sorting:

```sql
PRAGMA temp_store = MEMORY;
```

Use judiciously to avoid high RAM usage.

---

## 5. Automatic Indexing

```sql
PRAGMA automatic_index = TRUE;
```

Useful for ad-hoc queries but not a substitute for explicit indexes. Log queries to detect automatically created indexes.

---

## 6. Recursive Triggers & Foreign Keys

```sql
PRAGMA recursive_triggers = ON;
PRAGMA foreign_keys = ON;
```

Ensure Prisma migrations set these after each connection.

---

## 7. WAL Auto-Checkpoint

Tune based on write throughput:

```sql
PRAGMA wal_autocheckpoint = 500;
```

Lower threshold for CI (small tests). Higher for production to reduce checkpoints.

---

## 8. User Version

```sql
PRAGMA user_version = 3;
```

Applications can check this value to know which migrations ran.

---

## 9. ✅ / ❌ Configs

| ✅ Do | ❌ Don’t |
|------|----------|
| Store pragmas centrally in `createSqliteConnection` | Scatter `db.pragma` calls across code |
| Document per-environment settings | Guess after incidents |
| Use FULL synchronous for encrypted/significant data | Keep NORMAL despite auditor requests |

---

## 10. References

- sqlite.org/pragma.html
- this project `packages/db/sqlite/pragmas.ts`
