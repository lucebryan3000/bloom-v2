---
id: docker-01-fundamentals
topic: docker
file_role: detailed
profile: full
difficulty_level: beginner
kb_version: 3.1
prerequisites: [linux-basics, docker-basics]
related_topics: ['containers', 'deployment', 'cicd']
embedding_keywords: [docker]
last_reviewed: 2025-11-13
---

# 01 · Docker Fundamentals

High-level concepts, terminology, and architecture for engineers and AI assistants.

---

## 1. Components

| Component | Description |
|-----------|-------------|
| Docker Engine | Daemon (`dockerd`) managing images/containers |
| CLI | `docker` command-line client |
| API Socket | `/var/run/docker.sock` (or TCP/TLS) |
| Registry | GHCR, Docker Hub, ECR |
| Compose | Higher-level orchestration for local stacks |

---

## 2. Lifecycle

```
Dockerfile → docker build → image → docker run → container → logs/metrics → cleanup
```

Images are immutable layers; containers are ephemeral runtime instances.

---

## 3. Image Tags

Use semantic tags + Git SHA:

```
ghcr.io/company/roi-service:2025.11.10
ghcr.io/company/roi-service:sha-1a2b3c
```

Avoid `latest` in production deployments.

---

## 4. CLI Basics

```bash
docker ps -a
docker images
docker system df
```

Use context-specific `docker context use app-prod` for remote daemons.

---

## 5. ✅ / ❌ Practices

| ✅ Do | ❌ Don’t |
|------|----------|
| Keep Dockerfiles in `apps/<service>/Dockerfile` | Scatter Dockerfiles randomly |
| Use `.dockerignore` to exclude build artifacts | Copy entire repo by default |
| Document port mappings in README | Assume default ports |
| Clean up images/containers | Let disk fill with old volumes |

---

## 6. BuildKit Overview

Set `DOCKER_BUILDKIT=1` to enable parallel builds, inline cache, secret mounts. Compose v2 uses BuildKit by default.

---

## 7. Daemon Configuration

`/etc/docker/daemon.json` example:

```json
{
 "features": { "buildkit": true },
 "log-driver": "json-file",
 "log-opts": { "max-size": "10m", "max-file": "3" }
}
```

Document custom settings for self-hosted runners.

---

## 8. Troubleshooting

| Symptom | Fix |
|---------|-----|
| `Cannot connect to the Docker daemon` | Start service, check socket perms |
| `no space left on device` | `docker system prune` (with caution) |
| Build fails on Apple Silicon | `--platform linux/amd64` |

---

## 9. References

- docs.docker.com/get-started/overview
