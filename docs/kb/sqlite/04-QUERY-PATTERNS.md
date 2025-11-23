---
id: sqlite-04-query-patterns
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

# 04 · Query Patterns

Practical querying techniques for services, covering CRUD, pagination, aggregations, and JSON operations.

---

## 1. CRUD Templates

```sql
INSERT INTO opportunities (id, customer, annual_value)
VALUES ($id, $customer, $annual_value)
ON CONFLICT(id) DO UPDATE SET
 customer=excluded.customer,
 annual_value=excluded.annual_value;
```

Use parameter binding in drivers to avoid SQL injection.

---

```sql
SELECT *
FROM opportunities
WHERE customer = $customer
ORDER BY created_at DESC
LIMIT $limit OFFSET $offset;
```

---

## 2. Keyset Pagination

```sql
SELECT *
FROM opportunities
WHERE created_at < $cursor
ORDER BY created_at DESC
LIMIT 25;
```

Store `cursor` as ISO timestamp; use `>=`/`<=` carefully to avoid duplicates.

---

## 3. Window Functions

Requires SQLite 3.25+ (present in modern builds).

```sql
SELECT
 customer,
 annual_value,
 SUM(annual_value) OVER (PARTITION BY customer ORDER BY created_at) AS running_total
FROM opportunities;
```

---

## 4. JSON Queries

```sql
SELECT
 id,
 json_extract(metadata, '$.owner') AS owner
FROM opportunities
WHERE json_extract(metadata, '$.stage') = 'qualified';
```

Add indexes via generated columns when needed.

---

## 5. Aggregations

```sql
SELECT customer, COUNT(*) AS deals, SUM(annual_value) AS arr
FROM opportunities
GROUP BY customer
HAVING SUM(annual_value) > 50000
ORDER BY arr DESC;
```

---

## 6. CTE Example

```sql
WITH recent AS (
 SELECT * FROM opportunities WHERE created_at >= datetime('now', '-30 days')
)
SELECT customer, COUNT(*) FROM recent GROUP BY customer;
```

---

## 7. Parameter Binding (better-sqlite3)

```ts
const stmt = db.prepare(`
 SELECT * FROM opportunities
 WHERE customer = @customer
 ORDER BY created_at DESC
 LIMIT @limit
`);
const rows = stmt.all({ customer: "Acme", limit: 10 });
```

✅ Use named parameters for clarity.
❌ String concatenation for queries.

---

## 8. Transactions

```ts
const transaction = db.transaction((input) => {
 for (const row of input) {
 upsert.run(row);
 }
});

transaction(rows);
```

Transactions keep WAL size manageable; commit frequently.

---

## 9. Trouble Cases

| Issue | Fix |
|-------|-----|
| `too many SQL variables` | Batch inserts or use `INSERT... SELECT` |
| `misuse: user-defined function raised exception` | Wrap functions with try/catch |
| `no such column` | Verify migrations; run `PRAGMA table_info(table);` |

---

## 10. References

- sqlite.org/lang.html
- this project `packages/db/sqlite/queries`
