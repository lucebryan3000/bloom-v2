---
id: github-09-security-and-compliance
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

# 09 · Security & Compliance

Security automation is mandatory across the repos.

---

## 1. Dependabot

`.github/dependabot.yml` defines updates for npm, Docker, GitHub Actions. Key settings:
- Daily interval for high-risk repos.
- `allow` list for packages requiring fast updates.
- Reviewers: `@this project-security`.

---

## 2. Secret Scanning

Enable at org + repo level. Alerts triaged in Security Center. Workflow `secret-scan.yml` posts Slack notifications.

---

## 3. Code Scanning

Use CodeQL workflow `codeql-analysis.yml` on schedule + PR. Customize queries for Node/TypeScript.

---

## 4. Security Policies

`SECURITY.md` outlines disclosure process. `docs/security/triage.md` describes severity matrix.

---

## 5. Permissions Hygiene

- Enforce SSO for PATs.
- Use deploy keys or GitHub Apps instead of machine users.
- Audit tokens monthly via `orgs/{org}/personal-access-tokens`.

---

## 6. ✅ / ❌

| ✅ | ❌ |
|----|----|
| Require security review for Actions changes | Merge workflow updates without review |
| Pin action SHAs | Reference `@master` |
| Use Dependabot auto-merge < patch updates | Auto-merge major version bumps blindly |

---

## 7. Incident Response

Workflow:
1. Detect alert (Dependabot/Secret scan).
2. Create incident issue template.
3. Rotate credentials, patch vulnerabilities.
4. Document RCA in `security/incidents/`.

---

## 8. Troubleshooting

| Issue | Fix |
|-------|-----|
| Dependabot PR lacks reviewers | Ensure `reviewers` block specified |
| Secret scanning false positives | Add patterns to allowlist via API |
| CodeQL timeouts | Use matrix sharding or `ram` upgrade |

---

## 9. References

- docs.github.com → security features, Dependabot, CodeQL
