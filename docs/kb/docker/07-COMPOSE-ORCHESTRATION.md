---
id: docker-07-compose-orchestration
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

# 07 · Compose & Orchestration

Compose powers this project’s local stacks, preview environments, and test harnesses.

---

## 1. File Structure

```
docker/compose.dev.yml
docker/compose.test.yml
docker/compose.override.yml
```

Set `COMPOSE_FILE=docker/compose.dev.yml:docker/compose.override.yml`.

---

## 2. Profiles

Compose profiles allow optional services:

```yaml
services:
 web:
 profiles: ["web","default"]
 ai:
 profiles: ["ai"]
```

Run `docker compose --profile ai up`.

---

## 3. Environment Files

`COMPOSE_PROFILES=web` set in `.env`. Compose automatically loads `.env` located next to compose file. Use `.env.example` for documentation.

---

## 4. Health Checks & Dependencies

```yaml
services:
 postgres:
 healthcheck:
 test: ["CMD-SHELL", "pg_isready -U postgres"]
 api:
 depends_on:
 postgres:
 condition: service_healthy
```

---

## 5. Build vs Image

Define build contexts to reuse Dockerfiles:

```yaml
services:
 api:
 build:
 context:.
 dockerfile: apps/roi-api/Dockerfile
 image: ghcr.io/company/roi-api:dev
```

Use `--no-build` when only running prebuilt images.

---

## 6. Makefile Integration

`make compose-up`, `make compose-down` wrappers set environment variables and run `docker compose` commands consistently across engineers.

---

## 7. ✅ / ❌

| ✅ | ❌ |
|----|----|
| Commit Compose files, not ephemeral overrides | Share `.env` with secrets |
| Use profiles to keep stack light | Start all services every time |
| Document data volume names | Hardcode local absolute paths |

---

## 8. Troubleshooting

| Issue | Fix |
|-------|-----|
| Compose v1 vs v2 mismatch | Ensure `docker compose` (v2) used; alias `docker-compose` if required |
| Container rebuild not triggered | Use `--build` or `touch` relevant files |
| Orphan containers | `docker compose down --remove-orphans` |

---

## 9. References

- docs.docker.com/compose
