---
id: github-11-operations-and-governance
topic: github
file_role: detailed
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [github-basics]
related_topics: ['git', 'cicd', 'actions']
embedding_keywords: [github]
last_reviewed: 2025-11-13
---

# 11 · Operations & Governance

Processes covering audits, incidents, and large-scale migrations.

---

## 1. Org Governance

- Quarterly access reviews: export team membership via API, compare to HR roster.
- Repo lifecycle: archive stale repos after 90 days inactivity (Action script `repo-archiver.yml`).
- Naming conventions documented in `docs/governance/github.md`.

---

## 2. Audit Logs

Export monthly:

```bash
gh api orgs//audit-log --paginate > audit-log.json
```

Ingest into Snowflake for compliance reporting.

---

## 3. Incident Response

1. Detect (alerts, security center).
2. Create incident issue using template.
3. Assign commander + scribe.
4. Mitigate (revoke access, revert commits).
5. Postmortem within 5 business days; store in `security/incidents/`.

---

## 4. Migrations

Use GitHub Enterprise Importer for large repo moves. Steps:
- Export repo via `gh repo sync`.
- Update references (`git remote set-url`).
- Communicate freeze window.

---

## 5. Compliance Controls

| Control | Implementation |
|---------|----------------|
| 2FA enforced | Org setting |
| Secret scanning mandatory | Enabled for all repos |
| Branch protections | Rulesets |
| Release approvals | PR template + environment protection rules |

---

## 6. ✅ / ❌ Governance

| ✅ | ❌ |
|----|----|
| Document every exception to policy | Approve ad-hoc |
| Use automation for reviews | Manual spreadsheets |
| Tag incidents with severity labels | Freeform text |

---

## 7. Troubleshooting

| Problem | Solution |
|---------|----------|
| Missing audit log events | Use enterprise audit log (higher scope) |
| Unapproved repo created | Enforce repo creation policy via App |
| Environment bypass misuse | Remove bypass list, use approvals |

---

## 8. References

- GitHub Enterprise governance docs
