---
id: docker-10-observability-and-debugging
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

# 10 · Observability & Debugging

Capture logs, metrics, and run-time diagnostics for Dockerized services.

---

## 1. Logging Drivers

Defaults to `json-file`. this project uses:
- `json-file` locally (with rotation).
- `awslogs` or `gcp` drivers in managed environments.
- `fluentd` for centralized logging when using Compose in staging.

Set per service:

```yaml
logging:
 driver: json-file
 options:
 max-size: "10m"
 max-file: "3"
```

---

## 2. Metrics

`docker stats` for live usage:

```bash
docker stats roi-api --no-stream
```

For long-term metrics, integrate with Prometheus cAdvisor or use OTEL instrumentation inside apps.

---

## 3. Exec Debugging

`docker exec -it svc sh`. For distroless images, include debug shell stage or run `kubectl debug` equivalent in orchestrators.

---

## 4. Inspect

`docker inspect svc` reveals environment variables, mounts, network info. Format with Go templates:

```bash
docker inspect svc --format '{{.NetworkSettings.IPAddress}}'
```

---

## 5. Dumping Container Files

`docker cp svc:/app/logs./logs`. Use for quick snapshot; avoid copying secrets unnecessarily.

---

## 6. Compose Observability

`docker compose logs -f api`. Use `--tail` to limit output. Combine with `--timestamps` for timeline analysis.

---

## 7. Troubleshooting

| Problem | Fix |
|---------|-----|
| Container repeatedly restarting | Inspect `docker logs` + healthcheck status |
| High CPU | `docker stats`, `docker top <id>` |
| Disk usage growth | `docker system df`; prune unused images |

---

## 8. ✅ / ❌

| ✅ | ❌ |
|----|----|
| Rotate logs | Let JSON-file grow unbounded |
| Use structured logging (JSON) | Plain text inconsistent logs |
| Capture exit codes in CI | Ignore status when container fails |

---

## 9. References

- docs.docker.com/config/containers/logging
