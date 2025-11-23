---
id: docker-05-networking
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

# 05 · Networking

Configure container networks, port mappings, DNS, and Compose connectivity.

---

## 1. Drivers

| Driver | Use |
|--------|-----|
| bridge | default isolated network |
| host | share host network (Linux only) |
| none | disable networking |
| overlay | swarm/k8s (not primary in this project) |

For most local stacks, create custom bridge networks to avoid collisions.

---

## 2. Custom Network

```bash
docker network create this project-bridge --subnet 172.30.0.0/16
docker run --network this project-bridge --name postgres postgres:16
```

Compose:

```yaml
networks:
 this project:
 driver: bridge
 ipam:
 config:
 - subnet: 172.30.0.0/16
services:
 api:
 networks: [this project]
```

---

## 3. Ports

`-p host:container`. Document expected ports in README. Use `--publish 127.0.0.1:4000:4000` to avoid exposing broadly.

---

## 4. DNS & Service Discovery

Within same network, containers resolve by service name (e.g., `postgres` from `api`). For external DNS, ensure container has `DNS` entries via `/etc/docker/daemon.json`.

---

## 5. Proxy / Corporate Networks

Set `HTTP_PROXY`, `HTTPS_PROXY`, `NO_PROXY` environment variables, or configure daemon proxies. Use `build --build-arg HTTP_PROXY` for builds behind firewall.

---

## 6. Troubleshooting

| Symptom | Fix |
|---------|-----|
| Container cannot reach host service | Use `host.docker.internal` (macOS/Windows) or `172.17.0.1` (Linux) |
| Port already allocated | `docker ps` to find conflicting container |
| DNS issues | Restart Docker Desktop; check `resolve.conf` inside container |

---

## 7. ✅ / ❌

| ✅ | ❌ |
|----|----|
| Use isolated networks per stack | Put all containers on default bridge |
| Restrict published ports to localhost | Expose 0.0.0.0 unnecessarily |
| Document network names in Compose | Hardcode host IPs |

---

## 8. References

- docs.docker.com/network
