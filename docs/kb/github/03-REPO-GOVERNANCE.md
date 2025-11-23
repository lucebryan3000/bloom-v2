---
id: github-03-repo-governance
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

# 03 · Repository Governance

this project enforces consistent repo policies for stability and compliance.

---

## 1. Branch Protections

Settings for `main`:
- Require status checks `web-tests`, `api-tests`, `lint`.
- Require 2 approvals (one CODEOWNER).
- Require branches up to date with base.
- Enforce signed commits.

CLI snippet (see quick reference) to apply programmatically.

---

## 2. Branch Strategy

| Branch | Purpose | Notes |
|--------|---------|-------|
| `main` | Deployable trunk | Protected |
| `release/<yyyy-mm-dd>` | Staging release | auto-created weekly |
| `hotfix/<slug>` | Urgent fix | uses cherry-pick |
| Feature | `feature/<issue>` | merged via PR |

---

## 3. CODEOWNERS

```
# Default
* @this project-core
apps/roi-app/ @this project-frontend
packages/db/ @this project-platform
```

✅ Place at `.github/CODEOWNERS`.
❌ Storing inside `/docs` only (ignored).

---

## 4. PR & Issue Templates

`/.github/pull_request_template.md` with sections: Summary, Testing, Linked Issues, Screenshots. For multi-template: `.github/PULL_REQUEST_TEMPLATE/feature.md`.

Issues use YAML form definitions stored in `.github/ISSUE_TEMPLATE`. Example `bug-report.yml` requiring reproduction steps.

---

## 5. Labels

Label schema:
- `type:` (bug, feature, docs)
- `area:` (frontend, backend, infra)
- `priority:` (p0-p3)

Manage via `settings.yml` using `github-labeler`.

---

## 6. Rulesets

Enterprise feature enabling global rules (e.g., block force-push). Document rule IDs for auditing:
- `ruleset-main-protection`
- `ruleset-release-tagging`

---

## 7. ✅ / ❌ Practices

| ✅ | ❌ |
|----|----|
| Use branch naming conventions | Random names w/out issue IDs |
| Keep CODEOWNERS updated with team mapping | Leave stale owners after reorg |
| Document default labels | Create duplicates (Bug vs bug) |

---

## 8. Troubleshooting

| Symptom | Fix |
|---------|-----|
| Unable to merge due to `branch out-of-date` | Rebase or enable merge queue |
| CODEOWNER not triggered | Ensure path order; trailing slashes |
| Branch protection blocked automation | Add GitHub App to bypass list |

---

## 9. References

- GitHub Docs: Branch protection, CODEOWNERS, rulesets
