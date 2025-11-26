# OmniForge Stack Helpers

Host-only Docker helpers for bringing up/down core services (app + Postgres) during bootstrap. Exposed via `omni stack`.

## Commands
- `./_build/omniforge/omni.sh stack up` — start app + Postgres via docker compose
- `./_build/omniforge/omni.sh stack down` — stop all stack services
- `./_build/omniforge/omni.sh stack ps` — show stack status

## Requirements
- Run on the host (not inside the app container). If `INSIDE_OMNI_DOCKER` is set, commands exit with an error.
- Docker daemon and compose must be available (`require_docker_env`).
- Env files: `secrets_ensure_core_env` populates required env before bringing services up (expects `.env` / `.omni.secrets.env`).

## Typical Uses
- Bring services up before running bootstrap in container mode.
- Quickly stop services after bootstrap to free resources.
- Check service health/status outside the main bootstrap flow.

## Troubleshooting
- “must run on host”: ensure you’re not inside the app container; run from the host shell.
- Compose not found: install Docker Compose v2 (or plugin) and ensure `docker compose` works.
- Env missing: rerun `omni --run` to regenerate `.env`/`.omni.secrets.env` or ensure they exist before `stack up`.

## References
- Docker behavior: `_build/omniforge/docs/OMNIFORGE-DOCKER.md`
- Secrets/env: `_build/omniforge/docs/OMNIFORGE-SECRETS.md`
- Workflow: `_build/omniforge/docs/OMNIFORGE-WORKFLOW.md`
