---
id: github-05-pull-requests
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

# 05 · Pull Requests

this project PR workflow emphasizes automation, clear communication, and merge safety.

---

## 1. Templates

Default PR template sections:
- Summary
- Testing (checkbox list)
- Screenshots
- Linked Issues (`Fixes #123`)
- Rollout plan

Accept multiple templates via `.github/PULL_REQUEST_TEMPLATE/` directory.

---

## 2. Review Process

| Step | Owner | Notes |
|------|-------|-------|
| Draft PR | Author | Use `gh pr create --draft` |
| Request review | Author | Tag CODEOWNERS |
| Lint/Test | Actions workflows must pass |
| Approvals | At least 2, including affected domain |
| Merge | `gh pr merge --merge --auto` or merge queue |

---

## 3. Merge Options

- Squash merges default.
- Merge queue enabled for `main`.
- Auto-merge uses linear history requirement.

---

## 4. Checklist Example

```
- [ ] Tests covering new logic
- [ ] Telemetry added
- [ ] QA signoff
```

CI ensures checklist has no unchecked `[ ]` before merge (Action script).

---

## 5. Draft vs Ready

Set PR to draft if `WIP:` prefix or label `work-in-progress`. Action `draft-label.yml` auto toggles state when label removed.

---

## 6. ✅ / ❌ Practices

| ✅ | ❌ |
|----|----|
| Keep PRs < 400 LOC | Submit 2k+ LOC single PR |
| Use comments with suggestions | Request offline review only |
| Add screenshot/gif for UI | Describe UI change with text only |

---

## 7. Troubleshooting

| Issue | Fix |
|-------|-----|
| Auto-merge stuck | Check required checks, branch out-of-date |
| Merge conflicts | Rebase from main; use `gh pr checkout` |
| Missing reviewers | CODEOWNERS update needed |

---

## 8. References

- GitHub Docs: PRs, merge queue
