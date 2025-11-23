---
id: github-07-codespaces-devcontainers
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

# 07 · Codespaces & Devcontainers

this project uses Codespaces to onboard contractors and run ephemeral dev environments.

---

## 1. Devcontainer Basics

`/.devcontainer/devcontainer.json`

```json
{
 "name": "this project Workspace",
 "image": "mcr.microsoft.com/devcontainers/universal:2",
 "features": {
 "ghcr.io/devcontainers/features/node:1": { "version": "20" },
 "ghcr.io/devcontainers/features/docker-in-docker:2": {}
 },
 "postCreateCommand": "pnpm install"
}
```

---

## 2. Prebuilds

Enable repo-level prebuilds for `main` + `release/*`. Keeps `node_modules` cached. Admins configure via Settings → Codespaces → Prebuilds.

---

## 3. Secrets

| Secret | Scope | Usage |
|--------|-------|-------|
| `NEXTAUTH_SECRET` | repo | Web app |
| `OPENAI_API_KEY` | org | AI tooling |
| `DATABASE_URL` | repo | local services |

Manage with `gh codespace secrets`.

---

## 4. Dotfiles & Extensions

Set `GITHUB_USER` dotfiles repo to install shell aliases + git config. Use `devcontainer.json` `customizations.vscode.extensions` to auto-install the project's VS Code pack.

---

## 5. Resource Profiles

Default: 4-core/8GB. For Playwright tests, choose 8-core/16GB. Document cost awareness.

---

## 6. Offline Workflows

When Codespaces unavailable, use the same devcontainer locally via VS Code `Dev Containers: Open Folder in Container`.

---

## 7. ✅ / ❌ Codespaces

| ✅ | ❌ |
|----|----|
| Use prebuild-enabled branches | Rebuild from scratch each time |
| Trim Docker images to reduce startup | Ship bloated base images |
| Destroy stale spaces (`gh codespace delete -a`) | Leave dozens idle |

---

## 8. Troubleshooting

| Issue | Fix |
|-------|-----|
| Codespace fails to build | Check `postCreateCommand` logs |
| Port forwarding blocked | Ensure `devcontainer.json` `portsAttributes` configured |
| Secrets not accessible | Ensure added at repo vs org level |

---

## 9. References

- docs.github.com → Codespaces, devcontainers
