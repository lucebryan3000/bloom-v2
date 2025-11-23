---
id: github-10-automation-and-apis
topic: github
file_role: detailed
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [github-basics]
related_topics: ['git', 'cicd', 'actions']
embedding_keywords: [github, api]
last_reviewed: 2025-11-13
---

# 10 · Automation & APIs

Use GitHub REST/GraphQL APIs, Apps, and webhooks for this project automation.

---

## 1. GitHub CLI (REST)

```bash
gh api repos//app/deployments
gh api -X POST repos//app/dispatches -f event_type=run-migrations
```

Add headers as needed: `-H "Accept: application/vnd.github+json"`.

---

## 2. GraphQL

Example query file `queries/project-items.graphql`:

```graphql
query($id:ID!){
 node(id:$id){
... on ProjectV2{
 items(first:20){
 nodes{
 id
 content{
... on Issue{ title number }
 }
 }
 }
 }
 }
}
```

Run:

```bash
gh api graphql -f query=@queries/project-items.graphql -F id=PROJECT_ID
```

---

## 3. GitHub Apps

`this project-bot` uses App authentication:
1. Generate JWT from private key.
2. Exchange for installation token.
3. Call APIs with token (scoped to installation repos).

Use `octokit/app` helper or `@octokit/rest`.

---

## 4. Webhooks

Hosted at `app/api/github/webhook`. Validates `X-Hub-Signature-256`. Events handled:
- `pull_request`
- `workflow_run`
- `project_v2_item`

Use `@octokit/webhooks` to verify signatures.

---

## 5. Scheduled Automation

Actions workflows run nightly to:
- Sync CODEOWNERS from team metadata.
- Close stale issues (with exemption labels).
- Archive merged preview environments.

---

## 6. ✅ / ❌ Automation

| ✅ | ❌ |
|----|----|
| Use GitHub App tokens instead of PAT for bots | Share PAT across scripts |
| Version queries/scripts in repo | Copy/paste from docs |
| Handle rate limiting (Retry-After) | Hammer API without backoff |

---

## 7. Troubleshooting

| Issue | Fix |
|-------|-----|
| `401 Bad credentials` | Ensure JWT < 10 minutes old |
| Webhook invalid signature | Verify secret, compare against payload |
| GraphQL `Something went wrong` | Break queries into smaller sections |

---

## 8. References

- docs.github.com → REST, GraphQL, GitHub Apps
