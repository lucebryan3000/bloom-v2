---
id: github-02-setup-access
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

# 02 · Setup & Access

How engineers authenticate and configure tooling.

---

## 1. Account Requirements

- Okta SSO + GitHub Enterprise Cloud seat.
- Mandatory 2FA (security key or OTP).
- SSH key fingerprint registered.

---

## 2. SSH Keys

```bash
ssh-keygen -t ed25519 -C "you@this project.app"
ssh-add ~/.ssh/id_ed25519
gh ssh-key add ~/.ssh/id_ed25519.pub --title "this project Laptop"
```

✅ Use hardware-backed keys if available.

---

## 3. Personal Access Tokens

Use fine-grained PATs scoped to repo/workflow. Re-authorize with SSO every 30 days:

```bash
open https://github.com/settings/tokens?type=beta
```

Store tokens in 1Password item `GitHub PAT (this project)`.

---

## 4. GitHub CLI

```bash
brew install gh
gh auth login
```

Configure default editor + protocol:

```bash
gh config set editor "code --wait"
gh config set git_protocol ssh
```

---

## 5. Codespaces Secrets

```bash
gh codespace secrets set NPM_TOKEN --body "$NPM_TOKEN" --org
```

Org-level secrets require admin rights.

---

## 6. ✅ / ❌ Access

| ✅ | ❌ |
|----|----|
| Rotate PATs quarterly | Store PAT in repo |
| Use `gh auth refresh` | Continue after SSO expiration |
| Use `ssh-keygen -t ed25519-sk` for security keys | Use RSA 1024 |

---

## 7. Troubleshooting

| Error | Fix |
|-------|-----|
| `fatal: Could not read from remote repository.` | Add SSH key or check agent |
| `Resource not accessible by integration` | PAT missing scope |
| CLI `HTTP 401` | Re-run `gh auth login` with SSO |

---

## 8. References

- GitHub Docs → “Authenticating with SSO”
