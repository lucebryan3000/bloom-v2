---
id: github-framework-specific-patterns
topic: github
file_role: patterns
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: []
related_topics: ['git', 'cicd', 'actions']
embedding_keywords: [github, patterns, examples, integration]
last_reviewed: 2025-11-13
---

# Framework-Specific GitHub Patterns

Concrete references to the repositories and workflow files.

---

## 1. Monorepo Workflows

`/app/.github/workflows/web-ci.yml`

```yaml
name: Web CI
on:
 pull_request:
 paths:
 - "apps/roi-app/**"
jobs:
 lint-test:
 uses:./.github/workflows/pnpm-ci.yml
 with:
 app: "apps/roi-app"
```

Reusable workflow `pnpm-ci.yml` handles setup and caching.

---

## 2. Self-Hosted Runner Registration

`infrastructure/scripts/register-runner.sh` wraps `actions-runner` binary and tags runner as `this project-linux`. Terraform module manages auto-scaling.

---

## 3. CODEOWNERS

`/app/.github/CODEOWNERS` snippet:

```
apps/roi-app/ @this project-frontend @this project-platform
packages/db/ @this project-platform
```

Used across PRs for auto-review assignment.

---

## 4. Branch Protection IaC

`infrastructure/modules/github-repo/main.tf` uses `integrations/github` Terraform provider:

```hcl
resource "github_branch_protection_v3" "app_main" {
 repository_id = github_repository.this project.node_id
 pattern = "main"
 require_signed_commits = true
 required_pull_request_reviews {
 dismiss_stale_reviews = true
 required_approving_review_count = 2
 }
}
```

---

## 5. Projects Automation Script

`tools/github/projects-sync.ts` uses Octokit to sync Linear tickets to GitHub Projects. Runs nightly via Actions `projects-sync.yml`.

---

## 6. Dependabot Config

`/app/.github/dependabot.yml` includes multi-directory updates (root, apps/roi-app, packages/*). Security team auto-approves patch updates under 50 LOC.

---

## 7. Codespaces Config

`/app/.devcontainer/devcontainer.json` adds `ghcr.io/devcontainers/features/prisma:1` and sets `setupCommands` to run `pnpm prisma generate`.

---

## 8. Package Publishing Workflow

`/app/.github/workflows/publish-packages.yml`:

```yaml
jobs:
 publish:
 runs-on: ubuntu-latest
 permissions:
 contents: read
 packages: write
 steps:
 - uses: actions/checkout@v4
 - uses: pnpm/action-setup@v3
 - run: pnpm publish -r --filter @/*
```

---

## 9. GitHub App

Repo `/this project-bot` exposes Cloudflare Worker receiving GitHub webhooks (PR labeled, deployment status). App enforces PR checklist completion and updates Slack threads.

---

## 10. Incident Templates

`/app/.github/ISSUE_TEMPLATE/security-incident.yml` collects severity, timeline, remediation plan. Linked to Chapter 11 governance.

---

Use these references when grounding AI responses or implementing changes so documentation points to real this project assets.
