---
id: docker-index
topic: docker
file_role: navigation
profile: full
difficulty_level: all-levels
kb_version: 3.1
prerequisites: ['linux-basics']
related_topics: ['containers', 'deployment', 'cicd']
embedding_keywords: [docker, index, navigation, map]
last_reviewed: 2025-11-13
---

# Docker KB Index

Use this navigation map to jump to the right Docker topic fast.

---

## Category Map

| Area | File | Highlights |
|------|------|------------|
| Fundamentals | 01-FUNDAMENTALS | Architecture, CLI basics |
| Installation | 02-INSTALLATION-ENV | Desktop, Colima, remote daemons |
| Images & Build | 03-IMAGES-AND-BUILD | BuildKit, multi-stage, cache |
| Runtime | 04-CONTAINERS-RUNTIME | `run`, health checks, restart policies |
| Networking | 05-NETWORKING | Bridge, host, overlay, DNS |
| Storage | 06-STORAGE-AND-VOLUMES | Volumes, backups, temp dirs |
| Compose | 07-COMPOSE-ORCHESTRATION | Profiles, overrides, env files |
| CI/CD | 08-CI-CD | Buildx, GH Actions, registry pushes |
| Security | 09-SECURITY-AND-COMPLIANCE | Scanning, signing, policies |
| Observability | 10-OBSERVABILITY-AND-DEBUGGING | Logs, stats, exec |
| Governance | 11-OPERATIONS-AND-GOVERNANCE | Standards, incident playbooks |
| this project References | Framework-Specific-PATTERNS | Real repo paths |

---

## Task Lookup

| Task | File | Notes |
|------|------|-------|
| Create multi-stage Dockerfile | 03-IMAGES-AND-BUILD | Includes ✅/❌ examples |
| Publish multi-arch image | 08-CI-CD | Buildx and GHCR workflow |
| Configure Compose profiles | 07-COMPOSE-ORCHESTRATION | Dev/staging/prod toggles |
| Set up Colima for Apple Silicon | 02-INSTALLATION-ENV | Command snippets |
| Add healthcheck to service | 04-CONTAINERS-RUNTIME | CLI and Compose examples |
| Backup named volume | 06-STORAGE-AND-VOLUMES | tar + restore steps |
| Configure docker networks for integration tests | 05-NETWORKING | Bridge + custom subnets |
| Run container logs to OTEL | 10-OBSERVABILITY-AND-DEBUGGING | Logging driver config |
| Sign images with cosign | 09-SECURITY-AND-COMPLIANCE | Sigstore workflow |
| Document governance checklist | 11-OPERATIONS-AND-GOVERNANCE | Approval steps |

---

## this project References

| Asset | Location | Description |
|-------|----------|-------------|
| Web Dockerfile | `apps/roi-app/Dockerfile` | Multi-stage Node + Next |
| API Dockerfile | `apps/roi-api/Dockerfile` | Bun/Node hybrid |
| Compose file | `docker/compose.dev.yml` | Local stack |
| Build scripts | `scripts/docker/build.sh` | Wraps Buildx |
| GH Actions workflow | `.github/workflows/docker-build.yml` | CI pipeline |

---

## Keywords

`buildx`, `multi-arch`, `compose profiles`, `volume backup`, `cosign`, `docker scout`, `colima`, `rootless`, `healthcheck`, `OTEL logging`.

Update this list when adding new sections to keep search accurate.

---

## Quick Reference Ties

| Quick Section | Deep Dive |
|---------------|-----------|
| CLI basics | Chapters 01–02 |
| Build & push | Chapters 03 & 08 |
| Compose commands | Chapter 07 |
| Volume management | Chapter 06 |
| Security checks | Chapter 09 |

---

## Contribution Tips

- Keep tables alphabetical where applicable.
- When referencing the repos, include relative path.
- Update root KB README when adding significant sections.

---

Use this index before scanning entire files to reduce lookup time.***
