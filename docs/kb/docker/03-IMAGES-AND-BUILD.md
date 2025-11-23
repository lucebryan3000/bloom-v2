---
id: docker-03-images-and-build
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

# 03 · Images & Build

Multi-stage Dockerfiles, BuildKit optimizations, and this project conventions.

---

## 1. Project Layout

```
apps/roi-app/Dockerfile
apps/roi-api/Dockerfile
docker/.dockerignore
```

Place `.dockerignore` near Dockerfile to prevent copying `node_modules`, `.next`, `coverage`.

---

## 2. Multi-Stage Example

```dockerfile
FROM node:20-bullseye AS deps
WORKDIR /app
COPY package.json pnpm-lock.yaml./
RUN corepack enable pnpm && pnpm install --frozen-lockfile

FROM node:20-bullseye AS build
WORKDIR /app
COPY --from=deps /app/node_modules./node_modules
COPY..
RUN pnpm build

FROM gcr.io/distroless/nodejs20
WORKDIR /app
COPY --from=build /app/.next./.next
COPY package.json.
USER nonroot
CMD ["node", ".next/standalone/server.js"]
```

✅ Use distroless/minimal final stage.
❌ Keep build tools in runtime.

---

## 3. Build Arguments & Secrets

```bash
DOCKER_BUILDKIT=1 docker build \
 --secret id=npmrc,src=$HOME/.npmrc \
 --build-arg NODE_ENV=production \
 -t ghcr.io/company/web:dev.
```

Dockerfile:

```
# syntax=docker/dockerfile:1.6
RUN --mount=type=secret,id=npmrc \
 npm config set...
```

---

## 4. Caching

Use `--cache-from type=gha` with Buildx in CI:

```yaml
- uses: docker/build-push-action@v5
 with:
 cache-from: type=gha
 cache-to: type=gha,mode=max
```

Locally, rely on layer ordering (install deps before copying entire repo).

---

## 5. Platform Targets

For Apple Silicon compatibility:

```bash
docker buildx build --platform linux/amd64.
```

Add `FROM --platform=$BUILDPLATFORM node:20` pattern to multi-stage builds.

---

## 6. Testing

Use `docker build --target test` stage that runs unit tests before final image.

---

## 7. ✅ / ❌

| ✅ | ❌ |
|----|----|
| Always specify base image versions | Use floating tags |
| Keep layers deterministic | Run `npm install` after copying entire repo (cache miss) |
| Document build args in README | Hidden defaults |

---

## 8. Troubleshooting

| Problem | Solution |
|---------|----------|
| Build fails on CI only | Ensure Buildx driver set to `docker-container`; check QEMU availability |
| `no space left on device` | `docker builder prune` |
| Secret leaked | Use BuildKit `--secret`, avoid `ARG` for secrets |

---

## 9. References

- docs.docker.com/build/building/multi-stage
