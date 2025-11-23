---
id: docker-quick-reference
topic: docker
file_role: quickref
profile: full
difficulty_level: all-levels
kb_version: 3.1
prerequisites: ['linux-basics']
related_topics: ['containers', 'deployment', 'cicd']
embedding_keywords: [docker, quick-reference, cheat-sheet, syntax]
last_reviewed: 2025-11-13
---

# Docker Quick Reference

Copy/paste snippets for this project’s container workflows.

---

## CLI Basics

```bash
docker version
docker info --format '{{json.}}'
docker context ls
```

---

## Build & Run

```bash
DOCKER_BUILDKIT=1 docker build -t ghcr.io/company/roi-service:dev -f apps/roi-service/Dockerfile.
docker run --rm -p 3000:3000 --env-file.env.docker ghcr.io/company/roi-service:dev
```

Multi-arch Buildx:

```bash
docker buildx build \
 --platform linux/amd64,linux/arm64 \
 --push -t ghcr.io/company/roi-service:$(git rev-parse --short HEAD) \
 -f apps/roi-service/Dockerfile.
```

---

## Compose

```bash
docker compose --project-name app-dev \
 -f docker/compose.dev.yml \
 --profile web \
 up --build
```

Stop and remove:

```bash
docker compose down --volumes --remove-orphans
```

---

## Networking

```bash
docker network create this project-bridge --subnet 172.50.0.0/16
docker run --network this project-bridge --name redis redis:7
```

Expose ports:

```bash
docker run -p 8080:80 nginx
```

---

## Volumes & Backups

```bash
docker volume create this project-data
docker run -v this project-data:/var/lib/service...
```

Backup:

```bash
docker run --rm -v this project-data:/data -v $PWD/backups:/backups alpine \
 tar czf /backups/this project-data-$(date +%F).tgz -C /data.
```

---

## Logs & Debug

```bash
docker logs -f svc --tail 100
docker exec -it svc bash
docker inspect svc --format '{{.State.Health.Status}}'
```

---

## Registry Auth

```bash
echo "$GHCR_TOKEN" | docker login ghcr.io -u --password-stdin
docker push ghcr.io/company/roi-service:latest
```

---

## Security

```bash
docker scout cves ghcr.io/company/roi-service:latest
cosign sign ghcr.io/company/roi-service:latest
```

---

## CI Snippets

```yaml
- uses: docker/setup-buildx-action@v3
- uses: docker/login-action@v3
 with:
 registry: ghcr.io
 username: ${{ github.repository_owner }}
 password: ${{ secrets.GHCR_TOKEN }}
- uses: docker/build-push-action@v5
 with:
 context:.
 push: true
 tags: ghcr.io/company/roi-service:${{ github.sha }}
```

---

Use with the numbered guides for rationale, security posture, and troubleshooting.***
