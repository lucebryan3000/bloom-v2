---
id: sqlite-10-observability
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

# 10 · Observability

Monitor SQLite health even though it runs in-process. Capture metrics, logs, and traces for every this project service that touches `.db` files.

---

## 1. Health Checks

```ts
export async function sqliteHealth {
 const stmt = db.prepare("SELECT 1 as ok, sqlite_version as version");
 const row = stmt.get;
 return { ok: !!row?.ok, version: row?.version };
}
```

Expose via `/api/health/sqlite`. Include file path and journal mode.

---

## 2. Telemetry Fields

| Attribute | Example |
|-----------|---------|
| `db.system` | `sqlite` |
| `db.name` | `app-dev` |
| `db.path` | `file:./app-dev.db` |
| `db.operation` | `SELECT` |
| `ai.busy_timeout_ms` | 3000 |

Add to OTEL spans:

```ts
span.setAttributes({
 "db.system": "sqlite",
 "db.name": "this project",
 "db.operation": operation,
 "db.statement": scrub(sql),
});
```

Redact statements if containing PII.

---

## 3. Logging

Structured log example:

```json
{
 "event": "sqlite.query",
 "path": "app-dev.db",
 "duration_ms": 4.2,
 "rows": 12,
 "journal_mode": "wal"
}
```

Avoid logging full result sets. Summaries only.

---

## 4. Metrics

| Metric | Description |
|--------|-------------|
| `sqlite.query.count` | Counter per operation |
| `sqlite.query.duration` | Histogram |
| `sqlite.wal.size` | Gauge; track `-wal` file size |
| `sqlite.busy.errors` | Counter for `SQLITE_BUSY` |

Collect via StatsD (`dogstatsd`) or OTEL metrics.

---

## 5. Profiling

Use `EXPLAIN QUERY PLAN` for hotspots:

```sql
EXPLAIN QUERY PLAN
SELECT * FROM opportunities WHERE customer = 'Acme';
```

Integrate into CI to catch missing indexes.

---

## 6. Alerting

| Alert | Threshold | Action |
|-------|-----------|--------|
| Busy errors | >5/min | Investigate WAL/busy timeout |
| WAL size | >200 MB | Run checkpoint; inspect long-running readers |
| Backup failures | consecutive 2 failures | Restore from previous backup |

---

## 7. ✅ / ❌ Observability

| ✅ Do | ❌ Don’t |
|------|---------|
| Include DB path + env in logs | Log absolute local paths for prod |
| Redact statements before logging | Dump entire SQL if sensitive |
| Alert on `SQLITE_BUSY` | Ignore until user reports |

---

## 8. Troubleshooting

| Issue | Fix |
|-------|-----|
| Metrics missing after deploy | Ensure OTEL exporter runs in worker threads too |
| `db.statement` causes PII leak | Hash statements or remove parameter values |
| WAL size not reporting | Use `fs.statSync(`${dbPath}-wal`).size` |

---

## 9. References

- OTEL spec for `db.*` attributes
- this project telemetry package
