---
id: docker-02-installation-env
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

# 02 · Installation & Environment

How engineers install and configure Docker runtimes across macOS, Linux, and CI.

---

## 1. macOS

- Preferred: Docker Desktop 4.x (Apple Silicon aware).
- Alternative: Colima (`brew install colima`).
- For virtualization restrictions, use `finch` or `lima`.

Start Colima:

```bash
colima start --arch x86_64 --memory 8 --cpu 4 --vm-type vz
export DOCKER_HOST=unix://${HOME}/.colima/default/docker.sock
```

---

## 2. Linux (Ubuntu)

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker.gpg
echo \
 "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
 $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

Add user to group:

```bash
sudo usermod -aG docker $USER
```

Log out/in.

---

## 3. Windows

Use WSL2 + Docker Desktop. Ensure WSL distro has >8GB memory for Compose stacks. Document path translation differences (`/c/Users/...` vs `/mnt/c/...`).

---

## 4. Remote Contexts

`docker context create app-prod --docker "host=tcp://prod-docker:2376,ca=ca.pem,cert=cert.pem,key=key.pem"`

Switch via `docker context use app-prod`.

---

## 5. Environment Variables

| Var | Purpose |
|-----|---------|
| `DOCKER_HOST` | point CLI to remote daemon |
| `DOCKER_TLS_VERIFY` | enforce TLS |
| `DOCKER_CERT_PATH` | certificate location |
| `COMPOSE_FILE` | default compose files |

Set in `.envrc` or shell profile.

---

## 6. ✅ / ❌

| ✅ | ❌ |
|----|----|
| Keep Docker Desktop updated monthly | Stay on old builds lacking security patches |
| Pin Buildx plugin versions in CI | Use `latest` |
| Document CPU/RAM requirements | Assume defaults suit everyone |

---

## 7. Troubleshooting

| Issue | Fix |
|-------|-----|
| Docker Desktop stuck starting | Reset to factory defaults; check virtualization settings |
| Colima network issues | `colima stop; colima start --network-address` |
| `permission denied` on socket | Ensure group membership, run `newgrp docker` |

---

## 8. References

- docs.docker.com/desktop
- Colima documentation
