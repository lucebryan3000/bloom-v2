---
id: docker-08-ci-cd
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

# 08 · CI/CD

Building, scanning, and publishing Docker images via GitHub Actions and other CI systems.

---

## 1. Workflow Outline

`.github/workflows/docker-build.yml`

```yaml
name: Docker Build
on:
 push:
 branches: [main]
jobs:
 build:
 runs-on: ubuntu-latest
 permissions:
 contents: read
 packages: write
 steps:
 - uses: actions/checkout@v4
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
 cache-from: type=gha
 cache-to: type=gha,mode=max
```

---

## 2. Buildx Drivers

For multi-arch: use `docker-container` driver. On self-hosted runners, ensure QEMU emulation installed (`tonistiigi/binfmt` action).

---

## 3. Reusable Workflows

Expose `workflow_call` so other repos reuse this project’s standard pipeline:

```yaml
jobs:
 build:
 uses: /app/.github/workflows/docker-build.yml@main
 with:
 app: roi-service
```

---

## 4. Registry Policies

Push to GHCR using `package: write` permission. Tag with release, environment, branch. Clean old tags via `packages-cleanup.yml`.

---

## 5. Scanning

Add `docker/scout-action` or `aquasecurity/trivy-action` after build:

```yaml
- uses: aquasecurity/trivy-action@v0
 with:
 image-ref: ghcr.io/company/roi-service:${{ github.sha }}
```

Fail pipeline on critical vulnerabilities (configurable).

---

## 6. Signing

Use cosign with OIDC:

```yaml
- name: cosign install
 uses: sigstore/cosign-installer@v3
- name: sign
 run: cosign sign ghcr.io/company/roi-service:${{ github.sha }}
 env:
 COSIGN_EXPERIMENTAL: "1"
```

---

## 7. ✅ / ❌

| ✅ | ❌ |
|----|----|
| Pin action versions | Use `@main` |
| Use Buildx caches to save minutes | Rebuild from scratch each pipeline |
| Scan images pre-push | Deploy unscanned images |

---

## 8. Troubleshooting

| Issue | Fix |
|-------|-----|
| `no basic auth credentials` | Ensure login action executed; PAT scope packages:write |
| QEMU errors | Update binfmt emulator; check host kernel |
| Cache miss after base update | Accept longer build; rehydrate cache |

---

## 9. References

- docker/build-push-action docs
- GHCR guide
