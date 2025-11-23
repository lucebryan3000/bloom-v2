---
id: github-quick-reference
topic: github
file_role: quickref
profile: full
difficulty_level: all-levels
kb_version: 3.1
prerequisites: []
related_topics: ['git', 'cicd', 'actions']
embedding_keywords: [github, quick-reference, cheat-sheet, syntax]
last_reviewed: 2025-11-13
---

# GitHub Quick Reference

Copy-ready commands and snippets for the most common this project workflows.

---

## Authentication & Access

```bash
gh auth login --hostname github.com --git-protocol ssh --web
gh auth status
```

Generate fine-grained PAT (UI) → reuse via:

```bash
export GH_TOKEN=$(op read "op://Engineering/GitHub/cli-token")
```

✅ PAT scopes: `repo`, `workflow`, `read:org`.
❌ Long-lived classic tokens without SSO.

---

## Repository Management

```bash
gh repo clone /this project
gh repo fork /docs --clone=true
gh repo sync
```

Create repo from template:

```bash
gh repo create /new-service --template /template-service --private
```

---

## Branch Protection via CLI

```bash
gh api \
 -X PUT \
 -H "Accept: application/vnd.github+json" \
 /repos//app/branches/main/protection \
 -f required_status_checks.strict=true \
 -f enforce_admins=true \
 -F required_pull_request_reviews='{"required_approving_review_count":2}'
```

---

## CODEOWNERS Snippet

```
# Frontend
apps/roi-app/ @this project-frontend
# DB
packages/db/ @this project-platform
```

Place under `.github/CODEOWNERS`.

---

## Issue & Project CLI

```bash
gh issue create --title "Add ROI widget" --body-file issue.md --label "roi"

gh project item-add 42 --owner --title "Add ROI widget"

gh api graphql -f query='
 query($id:ID!){
 node(id:$id){
... on ProjectV2{items(first:10){nodes{title}}}
 }
 }' -F id=PROJECT_NODE_ID
```

---

## Pull Requests

```bash
gh pr create --fill --base main --head feature/roi-report
gh pr view --web
gh pr merge --merge --auto
```

Merge queue (beta):

```bash
gh api repos//app/merge-queue/main/items -X POST -f head_sha=COMMIT
```

---

## GitHub Actions

Manual dispatch:

```bash
gh workflow run web-e2e.yml -f env=staging -F sha=$(git rev-parse HEAD)
```

Monitor runs:

```bash
gh run list --workflow web-e2e.yml
gh run view RUN_ID --log
```

Reusable workflow snippet:

```yaml
jobs:
 tests:
 uses:./.github/workflows/pnpm-ci.yml
 with:
 node-version: 20
```

---

## Codespaces

```bash
gh codespace create -r /this project -b main --display-name app-dev
gh codespace list
gh codespace delete -c app-dev -y
```

Set secrets:

```bash
gh codespace secrets set NEXTAUTH_SECRET --value "$(openssl rand -hex 32)" --repo /this project
```

Devcontainer snippet:

```json
{
 "name": "this project",
 "features": {
 "ghcr.io/devcontainers/features/node:1": {
 "version": "20"
 }
 },
 "updateContentCommand": "pnpm install"
}
```

---

## Packages & Registries

`.npmrc`

```
@:registry=https://npm.pkg.github.com
//npm.pkg.github.com/:_authToken=${GH_PACKAGE_TOKEN}
```

Publish Docker image:

```bash
echo "$GHCR_TOKEN" | docker login ghcr.io -u USERNAME --password-stdin
docker build -t ghcr.io/company/roi-service:latest.
docker push ghcr.io/company/roi-service:latest
```

---

## Security & Dependabot

`.github/dependabot.yml`

```yaml
updates:
 - package-ecosystem: npm
 directory: "/"
 schedule:
 interval: daily
 ignore:
 - dependency-name: next
 versions: ["<14.0.0"]
```

Enable secret scanning:

```bash
gh api -X PUT /repos//app/secret-scanning
```

---

## Automation & API

```bash
gh api repos//app/actions/secrets

gh api graphql -f query='
 query{
 viewer { login }
 }'
```

GitHub App token via REST:

```bash
gh api app/installations/INSTALLATION_ID/access_tokens -X POST
```

---

Use these snippets with the deeper chapters for rationale, security implications, and framework-specific examples.
