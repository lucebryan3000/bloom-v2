---
id: docker-11-operations-and-governance
topic: docker
file_role: detailed
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [linux-basics, docker-basics]
related_topics: ['containers', 'deployment', 'cicd']
embedding_keywords: [docker]
last_reviewed: 2025-11-13
---

# 11 · Operations & Governance

Standards for Docker usage across this project, including approvals, incident response, and lifecycle management.

---

## 1. Standards

| Area | Requirement |
|------|-------------|
| Dockerfile reviews | At least one platform/CODEOWNER review |
| Registry | Use GHCR unless exception approved |
| Tags | Semantic version + SHA required |
| Documentation | Each service README documents build/run instructions |

---

## 2. Approvals

- New base images require security sign-off.
- Privileged containers flagged via PR template checklist.
- Compose file changes touching data services require DBA review.

---

## 3. Incident Response

1. Detect issue (failed scan, compromised image, runtime outage).
2. Pull affected tags from GHCR (use `gh api` to delete).
3. Roll back to known-good tag.
4. Rotate credentials if secrets exposed.
5. Document postmortem in `security/incidents`.

---

## 4. Lifecycle

- Weekly cleanup job removes images older than 90 days.
- Compose stacks documented in `docs/runbooks/*`.
- Base image upgrades tracked via Linear board `Docker Upgrades`.

---

## 5. Compliance Mapping

| Control | Implementation |
|---------|----------------|
| Immutable infrastructure | Images built via CI and signed |
| Vulnerability management | Chapter 09 scanning |
| Change management | PR approvals, release notes |
| Disaster recovery | Volume backup scripts (Chapter 06) |

---

## 6. ✅ / ❌

| ✅ | ❌ |
|----|----|
| Keep audit trail of deployments (tag + commit) | Deploy ad-hoc builds |
| Remove unused registries | Leave abandoned repos with outdated images |
| Document exception requests | Approve verbally |

---

## 7. Troubleshooting

| Issue | Fix |
|-------|-----|
| Missing provenance for release | Regenerate tags from commit, sign image |
| Compose file drift across teams | Centralize updates via `docker/compose.dev.yml` |
| Security review backlog | Batch base-image upgrades monthly |

---

## 8. References

- Internal governance doc `docs/governance/docker.md`
