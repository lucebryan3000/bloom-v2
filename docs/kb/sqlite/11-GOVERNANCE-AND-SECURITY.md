---
id: sqlite-11-governance-and-security
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

# 11 · Governance & Security

SQLite’s embedded nature does not remove governance obligations. Treat `.db` files like source of truth: encrypt when needed, control access, document lifecycle.

---

## 1. Ownership

| Asset | Owner |
|-------|-------|
| `app-dev.db` | DX Platform |
| `roi-local.db` | ROI squad |
| Test fixtures | QA Engineering |

Each asset tracked in inventory doc with path, backup cadence, retention.

---

## 2. Encryption Options

| Option | Notes |
|--------|-------|
| OS-level (FileVault, LUKS) | Easiest for dev laptops |
| SQLCipher | Requires license; adds `PRAGMA key` |
| Application-layer encryption | Encrypt sensitive columns before storing |

Pick approach per data classification (see this project security matrix).

---

## 3. Secrets Handling

- Store encryption keys in 1Password or AWS Secrets Manager.
- Reference via `SQLITE_ENCRYPTION_KEY_FILE`.
- Rotate bi-annually; update runbooks when key rotated.

---

## 4. Backup & Retention

- Keep at least 7 daily backups, 4 weekly, 3 monthly for prod-level data.
- Delete old backups using automated script.
- Document where backups live (S3 bucket `this project-sqlite-backups`).

---

## 5. Compliance Checklist

- [ ] DPIA completed for datasets with PII.
- [ ] Access controls enforced (`chmod 700` directories, restricted container users).
- [ ] Audit log for DB file access (macOS `fs_usage`, Linux `auditd` if required).
- [ ] Backup encryption validated.
- [ ] Incident runbook linked (see Notion “SQLite Incident”).

---

## 6. ✅ / ❌ Governance

| ✅ Do | ❌ Don’t |
|------|---------|
| Document DB location + owner | “It’s somewhere in /tmp” |
| Rotate encryption keys | Leave default key for years |
| Run `PRAGMA integrity_check;` monthly | Assume DB is fine |

---

## 7. Migration to Server DB

When migrating to Postgres:
- Create GDAP record referencing SQLite dataset.
- Copy data via pgloader.
- Decommission SQLite file (secure delete or archive).

---

## 8. Incident Response

If DB corrupted or leaked:
1. Isolate service.
2. Restore from last good backup.
3. Rotate keys.
4. File incident in PagerDuty + Security Slack.
5. Post-mortem within 5 days.

---

## 9. Documentation

- Keep `.metadata.json` updated (command, status, contacts).
- Note encryption + backup status inside README.
- Add cross-links to this project security handbook.

---

## 10. References

- SQLite Encryption Extension docs
- this project Security Program handbook
