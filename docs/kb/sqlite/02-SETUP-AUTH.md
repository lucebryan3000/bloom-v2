---
id: sqlite-02-setup-auth
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

# 02 · Setup & Tooling

SQLite does not require authentication like client/server databases, but this project standardizes tooling, environment variables, and optional encryption to keep deployments reproducible.

---

## 1. Toolchain

| Tool | Usage |
|------|-------|
| `sqlite3` CLI | quick inspection, exports |
| `better-sqlite3` | Node production driver |
| Prisma / Drizzle | schema + migrations |
| `sqldiff`, `sqlite3.backup` | promotion pipelines |
| SQLCipher / LiteStream | encryption / streaming backups |

Install:

```bash
brew install sqlite sqldiff
pnpm add better-sqlite3
pnpm add -D @types/better-sqlite3
```

---

## 2. Environment Configuration

```
DATABASE_URL="file:./app-dev.db"
SQLITE_DB_PATH="./app-dev.db"
SQLITE_BUSY_TIMEOUT_MS=3000
SQLITE_WAL=1
SQLITE_ENCRYPTION_KEY_FILE="/run/secrets/sqlite-key" # optional
```

Set through `.env`, Doppler, or Vercel envs; avoid hardcoding absolute paths in repo.

---

## 3. Connection Factory

```ts
import Database from "better-sqlite3";
import fs from "node:fs";

export function createSqliteConnection(path = process.env.SQLITE_DB_PATH ?? "app-dev.db") {
 const db = new Database(path);
 db.pragma("journal_mode = WAL");
 db.pragma(`busy_timeout = ${process.env.SQLITE_BUSY_TIMEOUT_MS ?? 3000}`);
 if (process.env.SQLITE_ENCRYPTION_KEY_FILE) {
 const key = fs.readFileSync(process.env.SQLITE_ENCRYPTION_KEY_FILE, "utf8").trim;
 db.pragma(`key = '${key}'`);
 }
 return db;
}
```

✅ Configure pragmas immediately after opening connection.
❌ Changing journal mode mid-request.

---

## 4. Optional Encryption

- Commercial SQLite SEE or SQLCipher required when encrypting DBs at rest.
- Keep keys in 1Password / AWS Secrets Manager.
- For local dev, use macOS FileVault or encrypted volume instead of custom encryption if licenses unavailable.

```sql
PRAGMA key = 'x''0123456789ABCDEF''';
```

(SQLCipher syntax)

---

## 5. Access Control

Even without built-in auth, implement OS-level and application-level guards:

- Set directory permissions to `chmod 700`.
- Run services under non-root user.
- In Next.js routes, ensure user session validated before reading DB.
- Log DB path for audit trails.

---

## 6. ✅ / ❌ Flow

| ✅ Good | ❌ Bad |
|--------|-------|
| Keep DB under `/var/lib/app/sqlite/<env>/` with proper perms | Store under `/tmp` accessible to all |
| Use env var for DB path | Hardcode `~/Downloads/foo.db` in code |
| Document version (`sqlite3 --version`) | Assume OS default |

---

## 7. Troubleshooting

| Issue | Fix |
|-------|-----|
| `Error: Cannot find module 'better-sqlite3'` | Install optional dependencies or use `npm rebuild --sqlite` |
| Prebuild mismatch in CI | Use `pnpm install --ignore-scripts=false` so native addon compiles |
| `file is encrypted or is not a database` | Ensure correct key or disable SQLCipher pragmas |

---

## 8. References

- sqlite.org/cli.html
- SQLCipher docs
