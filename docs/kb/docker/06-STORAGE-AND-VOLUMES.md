---
id: docker-06-storage-and-volumes
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

# 06 · Storage & Volumes

Handle persistent data, backups, and bind mounts safely.

---

## 1. Volume Types

| Type | Description | Use |
|------|-------------|-----|
| Named volume | Managed by Docker (`docker volume create`) | Databases, caches |
| Bind mount | Host path mapped into container | Source code, config |
| tmpfs | In-memory | Sensitive data needing speed |

---

## 2. Named Volume Usage

```bash
docker volume create this project-db
docker run -v this project-db:/var/lib/postgresql/data postgres:16
```

Compose:

```yaml
volumes:
 this project-db:
services:
 postgres:
 volumes:
 - this project-db:/var/lib/postgresql/data
```

---

## 3. Bind Mounts

```bash
docker run -v $PWD/config:/app/config:ro ghcr.io/company/roi-service
```

Include `:ro` for read-only where possible. Watch for file permission differences across OS.

---

## 4. Backup & Restore

Backup:

```bash
docker run --rm \
 -v this project-db:/data \
 -v $PWD/backups:/backups \
 alpine tar czf /backups/this project-db-$(date +%s).tgz -C /data.
```

Restore:

```bash
docker run --rm \
 -v this project-db:/data \
 -v $PWD/backups:/backups \
 alpine sh -c "rm -rf /data/* && tar xzf /backups/this project-db.tgz -C /data"
```

---

## 5. Cleanup

`docker volume ls`, `docker volume rm unused`. To prune all unused volumes: `docker volume prune` (confirm!). Document safe cleanup steps for CI.

---

## 6. ✅ / ❌

| ✅ | ❌ |
|----|----|
| Use named volumes for DB data | Bind mount entire host directories with secrets |
| Use `.dockerignore` to prevent `.env` leakage | Copy entire repo to image |
| Backup before upgrades | Delete volumes without notice |

---

## 7. Troubleshooting

| Issue | Fix |
|-------|-----|
| Permissions mismatch | Use `chown` or run container as matching UID |
| Windows line endings | Use `.gitattributes`; avoid bind mounting text for production |
| Volume not removed | Ensure container stopped; use `docker rm -f` |

---

## 8. References

- docs.docker.com/storage
