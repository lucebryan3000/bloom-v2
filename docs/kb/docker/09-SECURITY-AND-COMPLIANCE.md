---
id: docker-09-security-and-compliance
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

# 09 · Security & Compliance

Policies for scanning, signing, least privilege, and runtime hardening.

---

## 1. Base Images

- Prefer distroless or Alpine for Node services.
- Pin digest (`node:20-bullseye@sha256:...`) for reproducibility.
- Document upgrade cadence (monthly).

---

## 2. Vulnerability Scanning

Tools:
- Docker Scout (`docker scout cves image`)
- Trivy (CI action)
- GHCR built-in alerts

Fail builds on critical CVEs unless accepted with documented ticket.

---

## 3. Signing

Use cosign with keyless signing. Store signatures in OCI registry:

```bash
COSIGN_EXPERIMENTAL=1 cosign sign ghcr.io/company/roi-service:sha-123
```

Verify before deploy:

```bash
cosign verify ghcr.io/company/roi-service:sha-123
```

---

## 4. Runtime Policies

- Run containers as non-root; set `USER 65532`.
- Use `READONLY_ROOT_FILESYSTEM` in orchestrators.
- Limit capabilities: `--cap-drop ALL --cap-add NET_BIND_SERVICE`.
- Use `seccomp` default profile (or custom).

---

## 5. Secrets

- Inject via environment secrets (Compose) or secret files mounted at runtime.
- Avoid baking secrets into images.
- Use `docker build --secret` for build-time tokens.

---

## 6. Compliance Checklist

- [ ] Vulnerability scan results captured in CI logs.
- [ ] cosign signature stored per artifact.
- [ ] Dockerfiles stored in repo with approvals.
- [ ] Base image license review completed.
- [ ] Logging/monitoring configured (Chapter 10).

---

## 7. ✅ / ❌

| ✅ | ❌ |
|----|----|
| Keep image SBOM (CycloneDX) | Ship opaque images |
| Document CVE exceptions | Ignore vulnerability reports |
| Use rootless Docker where possible | Give containers privileged mode |

---

## 8. Troubleshooting

| Issue | Solution |
|-------|----------|
| False positive CVE | Pin digest, file suppression with justification |
| cosign fails with `permission denied` | Ensure `COSIGN_EXPERIMENTAL=1`, OIDC identity allowed |
| Image flagged for secret exposure | Revoke keys, rebuild image after removing file |

---

## 9. References

- docs.docker.com/engine/security
- sigstore.dev docs
