---
id: github-01-fundamentals
topic: github
file_role: detailed
profile: full
difficulty_level: beginner
kb_version: 3.1
prerequisites: [github-basics]
related_topics: ['git', 'cicd', 'actions']
embedding_keywords: [github]
last_reviewed: 2025-11-13
---

# 01 · GitHub Fundamentals

Overview of this project’s GitHub Enterprise Cloud organization.

---

## 1. Org Layout

| Org | Purpose | Notes |
|-----|---------|-------|
| `` | Primary product + platform repos | Requires Okta SSO |
| `-infra` | Terraform, shared infra code | Access limited |
| `-sandbox` | Prototypes, experiments | Relaxed protections |

Teams mirror squads (ROI, Platform, Security). Use teams for CODEOWNERS and project access.

---

## 2. Repository Types

- **Monorepos**: `this project`, `infrastructure`.
- **Service repos**: `roi-service`, `ops-dashboard`.
- **Tools**: `this project-bot`, `codex-cli`.

`this project` uses workspaces and requires Actions minutes; see Chapter 06.

---

## 3. Permissions

| Role | Capabilities |
|------|--------------|
| Admin | Manage settings, secrets |
| Maintain | Merge PRs, manage issues |
| Write | Push branches, open PRs |
| Triage | Label, close issues |
| Read | View repo |

Always assign least privilege. Use teams (e.g., `this project-frontend`) to grant access.

---

## 4. Branch Strategy

`main` is protected. Feature branches `feature/<slug>`. Release branches `release/<date>`. Hotfixes `hotfix/<slug>`.

---

## 5. ✅ / ❌ Practices

| ✅ Do | ❌ Don't |
|------|----------|
| Use fork or branch for long-running work | Force-push `main` |
| Link PRs to issues | Merge without CI |
| Enable discussions for major proposals | Use issues as chat |

---

## 6. Repo Templates

Located at `/template-service`. Use `gh repo create --template`. Template includes:
- CODEOWNERS placeholder
- `.github/workflows/base.yml`
- Security policy stub

---

## 7. Audit Logs

Admins access enterprise audit log via settings. CLI:

```bash
gh api orgs//audit-log?per_page=50
```

Export monthly for compliance.

---

## 8. Notifications

Recommend GitHub notifications → Slack personal channel using filters (e.g., `reason:review_requested`).

---

## 9. Troubleshooting

| Issue | Resolution |
|-------|------------|
| Org not visible | Accept Okta invitation |
| Cannot push | Ensure branch protection satisfied |
| Missing repo | Request via `#github-admin` Slack |

---

## 10. References

- docs.github.com → Enterprise Cloud overview
