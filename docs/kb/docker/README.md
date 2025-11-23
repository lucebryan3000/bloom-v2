---
id: docker-readme
topic: docker
file_role: overview
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: ['linux-basics']
related_topics: ['containers', 'deployment', 'cicd']
embedding_keywords: [docker, overview, introduction, getting-started]
last_reviewed: 2025-11-13
---

# Docker Knowledge Base

**Status**: Draft
**Last Updated**: November 2025
**Version**: 0.8.0

This KB distills Docker usage at this project—covering local development, CI pipelines, production container builds, and security guardrails. It mirrors the TypeScript KB structure with 11 topic guides, a quick reference, and framework-specific integration patterns.

---

## Why This Exists

- **Consistency** – avoid drift between local images, CI builds, and production registries.
- **Security** – document how to scan, sign, and run containers with least privilege.
*-**Performance** – share recipes for multi-stage builds, caching, and Compose stacks.
- **AI enablement** – equip AI copilots with deterministic instructions for Docker tasks.

---

## 11-Part Series

| # | File | Focus |
|---|------|-------|
| 01 | [01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md) | Core concepts, architecture, terminology |
| 02 | [02-INSTALLATION-ENV.md](./02-INSTALLATION-ENV.md) | Tooling, runtime setup, permissions |
| 03 | [03-IMAGES-AND-BUILD.md](./03-IMAGES-AND-BUILD.md) | Dockerfiles, multi-stage builds, caching |
| 04 | [04-CONTAINERS-RUNTIME.md](./04-CONTAINERS-RUNTIME.md) | Run commands, health checks, lifecycle |
| 05 | [05-NETWORKING.md](./05-NETWORKING.md) | Bridges, ports, DNS, service mesh |
| 06 | [06-STORAGE-AND-VOLUMES.md](./06-STORAGE-AND-VOLUMES.md) | Volumes, bind mounts, backups |
| 07 | [07-COMPOSE-ORCHESTRATION.md](./07-COMPOSE-ORCHESTRATION.md) | docker-compose, profiles, envs |
| 08 | [08-CI-CD.md](./08-CI-CD.md) | Registry workflows, Buildx, caching in Actions |
| 09 | [09-SECURITY-AND-COMPLIANCE.md](./09-SECURITY-AND-COMPLIANCE.md) | Scanning, signing, runtime policies |
| 10 | [10-OBSERVABILITY-AND-DEBUGGING.md](./10-OBSERVABILITY-AND-DEBUGGING.md) | Logs, metrics, tracing, exec |
| 11 | [11-OPERATIONS-AND-GOVERNANCE.md](./11-OPERATIONS-AND-GOVERNANCE.md) | Standards, incident response, lifecycle |

Supporting files:

- [INDEX.md](./INDEX.md)
- [QUICK-REFERENCE.md](./QUICK-REFERENCE.md)
- [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md)

---

## Getting Started

1. Install Docker Desktop (macOS) or `docker-ce` packages (Linux).
2. Run `docker version` and `docker info` to confirm runtime.
3. Authenticate with GitHub Container Registry:

```bash
echo "$GHCR_TOKEN" | docker login ghcr.io -u --password-stdin
```

4. Build + run sample service:

```bash
docker build -t app/hello -f docker/Dockerfile.hello.
docker run --rm -p 4000:4000 app/hello
```

✅ Use multi-stage builds to keep images small.
❌ Run containers as root unless absolutely required.

---

## Common Tasks Snapshot

| Task | Solution | Reference |
|------|----------|-----------|
| Build multi-arch image | `docker buildx build --platform linux/amd64,linux/arm64` | Chapter 03 |
| Start local stack | `docker compose up --profile dev` | Chapter 07 |
| Debug container | `docker exec -it svc bash` + `--privileged=false` | Chapter 10 |
| Scan image | `docker scout cves ghcr.io/company/roi-service:latest` | Chapter 09 |
| Push to GHCR | `docker push ghcr.io/company/roi-service:sha-...` | Chapter 08 |

---

## Learning Paths

- **Beginner**: Chapters 01–04 + quick reference.
- **Intermediate**: Chapters 05–07 (networking, volumes, compose).
- **Advanced**: Chapters 08–10 (CI/CD, security, observability).
- **Expert**: Chapter 11 + this project patterns (org policies, incident playbooks).

---

## Configuration Essentials

| Setting | Default | this project Guidance |
|---------|---------|----------------|
| `DOCKER_BUILDKIT` | 1 | Always enabled |
| `COMPOSE_PROFILES` | `default` | Use per environment |
| `DOCKER_HOST` | local socket | Use TLS endpoints for remote builds |
| `DOCKER_SCAN_SUGGEST` | false | Explicit scanning via CLI |

---

## Issues & Fixes

- **“permission denied /var/run/docker.sock”** – add user to `docker` group or use `colima`.
- **Build cache misses in CI** – configure BuildKit cache-from.
- **Container fails on Apple Silicon** – specify `--platform linux/amd64`.

---

## Structure

```
docker/
├── README.md
├── INDEX.md
├── QUICK-REFERENCE.md
├── 01-FUNDAMENTALS.md
├── 02-INSTALLATION-ENV.md
├── 03-IMAGES-AND-BUILD.md
├── 04-CONTAINERS-RUNTIME.md
├── 05-NETWORKING.md
├── 06-STORAGE-AND-VOLUMES.md
├── 07-COMPOSE-ORCHESTRATION.md
├── 08-CI-CD.md
├── 09-SECURITY-AND-COMPLIANCE.md
├── 10-OBSERVABILITY-AND-DEBUGGING.md
├── 11-OPERATIONS-AND-GOVERNANCE.md
└── FRAMEWORK-INTEGRATION-PATTERNS.md
```

---

## External Resources

- [Docker Docs](https://docs.docker.com/)
- [Docker Compose Spec](https://docs.docker.com/compose/)
- [Container Security](https://docs.docker.com/engine/security/)
- [GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)

---

## Next Steps

1. Work through numbered chapters.
2. Apply framework-specific patterns to active services.
3. Run quality checks from `.codex/commands/kb-codex.md` before promoting beyond Draft.
