# OmniForge Deployment Checklist

- [ ] Docker installed and daemon running (`docker info` succeeds).
- [ ] Run Docker-first bootstrap (`omni run` or menu Option 1) to stage Dockerfile.dev, docker-compose.yml, and generate the app `.env`.
- [ ] Capture admin credentials (user `admin`, password in `.env` via `ADMIN_INITIAL_PASSWORD`).
- [ ] Bring up core services: `docker compose up -d app postgres` (or `omni stack up`), then verify logs/status.
- [ ] Smoke test the app inside the `app` container (e.g., `docker compose exec app pnpm test` or app-specific checks).
- [ ] CI ready: either set `DOCKER_EXEC_MODE=host` or run `docker compose up -d app postgres && docker compose exec app ./_build/omniforge/omni.sh --run`.
- [ ] Treat `.tools` as legacy/host-only; container mode must include pnpm/node in Dockerfile.dev.
- [ ] Post-bootstrap cleanup: commit generated Docker artifacts, keep `.env` secure, and optionally remove `_build/omniforge`.
- [ ] Re-run guidance: bootstrap is detect-and-exit; delete/rebuild to apply new configuration.
