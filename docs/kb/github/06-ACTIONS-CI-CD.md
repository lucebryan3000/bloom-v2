---
id: github-06-actions-ci-cd
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

# 06 · GitHub Actions (CI/CD)

this project runs CI/CD exclusively through GitHub Actions with a mix of hosted and self-hosted runners.

---

## 1. Workflow Structure

- `.github/workflows/web-ci.yml` – lint/test/build for web apps.
- `.github/workflows/api-ci.yml` – backend tests + Prisma migrations.
- `.github/workflows/deploy.yml` – environment deployments using OIDC to AWS/Vercel.

Reusable workflows stored under `.github/workflows/common/`.

---

## 2. Runners

| Runner | Use | Notes |
|--------|-----|-------|
| `ubuntu-latest` | Default CI | caches PNPM |
| Self-hosted `this project-linux` | Heavy tests, GPU | defined via Actions runner controller |
| `macos-13` | iOS builds | limited concurrency |

Register self-hosted runner using `scripts/actions/register-runner.sh`.

---

## 3. Caching

```yaml
- uses: actions/cache@v4
 with:
 path: ~/.pnpm-store
 key: pnpm-${{ runner.os }}-${{ hashFiles('pnpm-lock.yaml') }}
```

Also cache Playwright browsers.

---

## 4. Environment Secrets & OIDC

Deploy workflow uses:

```yaml
permissions:
 id-token: write
 contents: read
```

Then assume AWS role via `aws-actions/configure-aws-credentials`.

---

## 5. Manual Triggers

Add `workflow_dispatch` inputs for env, commit SHA, feature flags.

```yaml
on:
 workflow_dispatch:
 inputs:
 env:
 type: choice
 options: [staging, prod]
```

---

## 6. Matrix Builds

```yaml
strategy:
 matrix:
 node: [18, 20]
steps:
 - uses: actions/setup-node@v4
 with:
 node-version: ${{ matrix.node }}
```

---

## 7. ✅ / ❌ CI Patterns

| ✅ | ❌ |
|----|----|
| Keep workflows modular with `workflow_call` | Duplicate steps across dozens of files |
| Use concurrency groups to cancel superseded runs | Let obsolete runs consume minutes |
| Pin action versions | Use `@main` references |

---

## 8. Troubleshooting

| Problem | Fix |
|---------|-----|
| `Resource not accessible by integration` | Ensure workflow has required permissions |
| Runner offline | Check ARC state or scale set |
| Secret missing | Add to repo/environment; verify case sensitivity |

---

## 9. References

- docs.github.com → Actions, OIDC federation
