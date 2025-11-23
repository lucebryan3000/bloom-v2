---
id: docker-04-containers-runtime
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

# 04 · Containers & Runtime

Running containers with correct flags, health checks, restart policies, and resource limits.

---

## 1. Run Command Template

```bash
docker run \
 --name roi-api \
 --rm \
 --env-file.env.docker \
 --publish 4000:4000 \
 --memory 512m --cpus 1.5 \
 --health-cmd="curl -sS http://localhost:4000/health || exit 1" \
 --health-interval=30s \
 ghcr.io/company/roi-api:dev
```

✅ Limit resources; containers should not default to entire host.

---

## 2. Restart Policies

`--restart unless-stopped` for long-running background containers (e.g., local databases). Compose: `restart: unless-stopped`.

---

## 3. Environment Variables

Use `--env KEY=VALUE` or `.env` files (Compose automatically loads `.env`). Guard secrets using Docker secrets when running swarm/k8s; for local dev, rely on `.env.docker` not committed to git.

---

## 4. Health Checks

Dockerfile snippet:

```
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
 CMD node healthcheck.js
```

Status revealed via `docker inspect container --format '{{.State.Health.Status}}'`.

---

## 5. Logs

`docker logs -f container`. For JSON-file driver, set log rotation in daemon config. Compose services specify `logging` block with `max-size` etc.

---

## 6. Exec & Debug

`docker exec -it container /bin/sh`. For distroless images, use `busybox` sidecar or `--target debug` stage.

---

## 7. ✅ / ❌

| ✅ | ❌ |
|----|----|
| Use non-root user (`USER 1000`) | Run as root in production |
| Set `--read-only` when possible | Provide unnecessary write access |
| Clean up containers (`--rm`) | Leave dozens of exited containers |

---

## 8. Troubleshooting

| Issue | Fix |
|-------|-----|
| Container exits immediately | Check entrypoint cmd; ensure `CMD` not overwritten |
| Port collision | `lsof -i:4000` to inspect; change host port |
| Unable to attach TTY | Use `-it`; ensure shell exists |

---

## 9. References

- docs.docker.com/engine/reference/run/
