---
id: github-08-packages-and-registries
topic: github
file_role: detailed
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [github-basics]
related_topics: ['git', 'cicd', 'actions']
embedding_keywords: [github]
last_reviewed: 2025-11-13
---

# 08 · Packages & Registries

this project publishes npm packages, Docker images, and OCI artifacts via GitHub Packages.

---

## 1. npm Registry

`.npmrc` config:

```
@:registry=https://npm.pkg.github.com
//npm.pkg.github.com/:_authToken=${GH_PACKAGE_TOKEN}
```

`GH_PACKAGE_TOKEN` scope: `read:packages`, `write:packages`.

Publish:

```bash
npm publish
```

---

## 2. Docker / OCI (GHCR)

```bash
echo "$GHCR_TOKEN" | docker login ghcr.io -u USER --password-stdin
docker build -t ghcr.io/company/roi-service:${TAG}.
docker push ghcr.io/company/roi-service:${TAG}
```

Add metadata labels for provenance.

---

## 3. Retention Policies

Use `packages-cleanup.yml` workflow to delete images older than 30 days except tags matching `release-*`.

---

## 4. SBOM & Provenance

Actions workflow generates SBOM via `anchore/sbom-action` and attaches to release. Sigstore signing optional; documented in Security chapter.

---

## 5. ✅ / ❌

| ✅ | ❌ |
|----|----|
| Use PAT with least privileges | Use personal PAT for org-wide publish |
| Tag releases semantically | `latest` only |
| Document package README | Leave blank descriptions |

---

## 6. Troubleshooting

| Issue | Fix |
|-------|-----|
| 403 when publishing npm | Ensure package scope matches repo owner |
| Docker push fails | Check GHCR token permission |
| Package not visible | Set visibility to `public` or `internal` as needed |

---

## 7. References

- docs.github.com → GitHub Packages
