---
id: github-index
topic: github
file_role: navigation
profile: full
difficulty_level: all-levels
kb_version: 3.1
prerequisites: []
related_topics: ['git', 'cicd', 'actions']
embedding_keywords: [github, index, navigation, map]
last_reviewed: 2025-11-13
---

# GitHub KB Index

Navigate GitHub topics quickly. Each entry maps tasks to the numbered chapters and supporting references.

---

## Category Map

| Area | Chapter | Highlights |
|------|---------|------------|
| Org Fundamentals | 01 | Org layout, permissions, repos |
| Access & Auth | 02 | SSO, PATs, SSH, audit logging |
| Repo Governance | 03 | Branch strategy, CODEOWNERS, templates |
| Issues & Projects | 04 | Workflows, automation, Projects v2 |
| Pull Requests | 05 | Templates, review gates, merge queues |
| CI/CD | 06 | Actions, runners, caching, environments |
| Codespaces | 07 | Devcontainers, prebuilds, secrets |
| Packages | 08 | npm/Docker registries, provenance |
| Security | 09 | Dependabot, secret scanning, policies |
| Automation | 10 | REST/GraphQL, GitHub Apps, bots |
| Governance | 11 | Audits, migrations, incident response |
| Patterns | this project | Real repo references |

---

## Task Lookup

| Task | File | Notes |
|------|------|-------|
| Add CODEOWNERS rule | 03-REPO-GOVERNANCE | Includes ✅/❌ examples |
| Configure branch protection | 03-REPO-GOVERNANCE | Step-by-step plus CLI |
| Create Project view automation | 04-ISSUES-AND-PROJECTS | Templates + GraphQL |
| Enforce PR template | 05-PULL-REQUESTS | Multi-template strategy |
| Author workflow dispatch | 06-ACTIONS-CI-CD | CLI + YAML sample |
| Spin up Codespaces prebuild | 07-CODESPACES-DEVCONTAINERS | `devcontainer.json` snippets |
| Serve npm package via GitHub Packages | 08-PACKAGES-AND-REGISTRIES | `.npmrc` config |
| Configure Dependabot ignore | 09-SECURITY-AND-COMPLIANCE | Example config |
| Query audit log via API | 10-AUTOMATION-AND-APIS | CLI + GraphQL |
| Handle org incident | 11-OPERATIONS-AND-GOVERNANCE | Runbook |

---

## this project References

| Asset | Location | Notes |
|-------|----------|-------|
| Main monorepo | `github.com//this project` | Branch protections + Actions |
| Infra repo | `github.com//infrastructure` | Terraform + self-hosted runners |
| GitHub App | `github.com//this project-bot` | Automation scripts |
| Workflow catalog | `.github/workflows/` | Shared CI templates |
| Docs | `docs/kb/github/` | This KB |

---

## Keywords

- `merge queue`, `rulesets`, `workflow_call`, `environments`, `codespaces prebuilds`, `dependabot`, `gh api`, `oidc`, `deployments`.

Add new keywords when chapters gain new sections.

---

## Quick Reference Cross-links

| Topic | QUICK Section | Deep Dive |
|-------|---------------|-----------|
| `gh` CLI auth | Authentication | Chapter 02 |
| Workflow dispatch | Actions | Chapter 06 |
| Codespaces secrets | Codespaces | Chapter 07 |
| Package publishing | Packages | Chapter 08 |
| GraphQL snippets | Automation | Chapter 10 |

---

## Contribution Guidelines

- Keep tables sorted alphabetically when practical.
- Reference both CLI and UI where relevant.
- Update main KB README after adding major sections.

---

Use this index to jump straight to the chapter that answers your GitHub question.***
