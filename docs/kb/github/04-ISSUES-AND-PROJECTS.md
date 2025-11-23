---
id: github-04-issues-and-projects
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

# 04 · Issues & Projects

Manage work using GitHub Issues and Projects v2 automations.

---

## 1. Issue Templates

- `bug-report.yml`: required reproduction, severity.
- `feature-request.yml`: goals, acceptance criteria.
- `runbook-update.yml`: used by platform teams to track doc updates.

Store under `.github/ISSUE_TEMPLATE`. Each YAML form enforces labels.

---

## 2. Issue Automation

Actions workflow `issue-triage.yml`:

```yaml
on:
 issues:
 types: [opened]
jobs:
 triage:
 runs-on: ubuntu-latest
 steps:
 - uses: actions-ecosystem/action-add-labels@v1
 with:
 labels: "needs-triage"
```

---

## 3. Projects v2

Project `ROI` uses fields: Status, Priority, Squad, Target Release. Automations:
- New issue added automatically via action.
- PR merge updates linked item status.
- Weekly insights exported via GraphQL script `scripts/projects/snapshot.ts`.

---

## 4. CLI Tips

```bash
gh project view 42 --owner
gh project item-edit 42 --id ITEM_ID --field "Status" --value "In Review"
```

---

## 5. ✅ / ❌ Usage

| ✅ | ❌ |
|----|----|
| Link PRs to issues using keywords (`closes #123`) | Track progress outside GitHub |
| Use templates to capture context | Freeform issues without acceptance criteria |
| Keep Projects fields minimal | Add dozens of custom fields |

---

## 6. Troubleshooting

| Problem | Solution |
|---------|----------|
| Project automation not firing | Ensure workflow PAT has `project` scope |
| Issues missing from board | Confirm filter query includes label/milestone |
| GraphQL limit reached | Use pagination + `after` cursors |

---

## 7. References

- docs.github.com → Projects v2, Issue forms
