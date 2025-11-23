---
id: sqlite-03-schema-design
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

# 03 · Schema Design

Design schemas that stay portable to Postgres while leveraging SQLite features like partial indexes and generated columns.

---

## 1. Data Types Cheat Sheet

| Declared Type | Storage Class |
|---------------|---------------|
| `INTEGER` | 64-bit signed |
| `REAL` | 64-bit float |
| `TEXT` | UTF-8/16 |
| `BLOB` | Raw bytes |
| `NUMERIC` | TEXT/REAL/INTEGER depending on affinity |

Use explicit `CHECK` constraints to emulate strict typing (e.g., booleans).

---

## 2. Table Example

```sql
CREATE TABLE opportunities (
 id TEXT PRIMARY KEY,
 customer TEXT NOT NULL,
 annual_value REAL NOT NULL CHECK (annual_value >= 0),
 metadata JSON,
 created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

- JSON stored as TEXT but validated via `json_valid`.
- Use indexes on computed expressions if stable.

---

## 3. Generated Columns

```sql
CREATE TABLE docs (
 id TEXT PRIMARY KEY,
 body TEXT NOT NULL,
 body_length INTEGER GENERATED ALWAYS AS (length(body)) VIRTUAL
);
CREATE INDEX docs_body_length_idx ON docs(body_length);
```

✅ Works in SQLite 3.31+.
❌ Expecting default values to read from other columns without `GENERATED`.

---

## 4. Foreign Keys

Enable with `PRAGMA foreign_keys = ON;`.

```sql
CREATE TABLE accounts (
 id TEXT PRIMARY KEY,
 name TEXT NOT NULL
);

CREATE TABLE opportunities (
 id TEXT PRIMARY KEY,
 account_id TEXT NOT NULL,
 FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE
);
```

---

## 5. Index Patterns

| Pattern | Example |
|---------|---------|
| Partial index | `CREATE INDEX... WHERE archived = 0;` |
| Expression index | `CREATE INDEX... ON events(json_extract(metadata,'$.type'));` |
| Covering index | `CREATE INDEX... ON events(type, created_at);` |

Indexes increase file size—monitor with `PRAGMA page_count;`.

---

## 6. FTS5 Virtual Tables

```sql
CREATE VIRTUAL TABLE opportunity_search USING fts5(
 customer,
 summary,
 content='opportunities',
 content_rowid='rowid'
);

CREATE TRIGGER opportunities_ai AFTER INSERT ON opportunities BEGIN
 INSERT INTO opportunity_search(rowid, customer, summary)
 VALUES (new.rowid, new.customer, new.summary);
END;
```

FTS tables are separate from base tables; backup both.

---

## 7. PRAGMA schema_version

Track schema version to ensure migrations applied:

```sql
PRAGMA schema_version;
```

Increment manually inside migration scripts, or rely on SQLite auto-increment when schema changes.

---

## 8. Migration Strategy

- Use Prisma migrations for TypeScript services.
- For lightweight Node-only services, store `.sql` files under `migrations/sqlite`.
- Keep naming aligned with Postgres migrations to ease uplift.

```
migrations/
 20240221_add_opportunities.sql
 20240227_add_fts.sql
```

---

## 9. ✅ / ❌ Patterns

| ✅ Good | ❌ Bad |
|--------|-------|
| Use `TEXT` for UUIDs | Use `INTEGER` just because |
| Add `CHECK (value >= 0)` | Rely only on app validation |
| Document indexes in README | Add hidden indexes with `CREATE INDEX` in scripts |

---

## 10. References

- sqlite.org/datatype3.html
- Prisma schema (chapter cross-link)
