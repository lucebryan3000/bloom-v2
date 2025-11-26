# OmniForge Docker-Aware Execution

`omni.sh` can re-execute inside the app container, start required services, and adjust safety checks depending on host vs container. Use this guide to understand modes, required services, and how commands behave in Docker-aware workflows.

## Quick Reference
- Run normally on host: `./_build/omniforge/omni.sh --run`
- Force container re-exec: `DOCKER_EXEC_MODE=container ./_build/omniforge/omni.sh --run`
- Start stack services (host-only helper): `./_build/omniforge/omni.sh stack up`
- Show status without re-exec: `./_build/omniforge/omni.sh --status`

## Execution Modes
- `DOCKER_EXEC_MODE=host` (default): Runs on host; uses host Docker CLI as needed.
- `DOCKER_EXEC_MODE=container`: For bootstrap commands (run/init/phase), `omni.sh` ensures Docker services are up, then re-execs inside the app container (`omni_docker_exec_app env INSIDE_OMNI_DOCKER=1 ./_build/omniforge/omni.sh ...`).

## Services Started for Bootstrap
- App service (`${APP_SERVICE_NAME:-app}`) and Postgres are started via `docker compose up -d` before re-exec when container mode is active.
- Postgres readiness is checked (`pg_isready`) with retries; warnings are non-fatal if it takes too long.

## Host vs Container Behavior
- **Host**: Performs prereq validation, installs project-local tools if missing, enforces git-clean safety, and can start Docker services.
- **Container (INSIDE_OMNI_DOCKER=1)**: Skips host-specific validations, relaxes git safety (`GIT_SAFETY=false`, `ALLOW_DIRTY=true`), assumes Node/pnpm are present in the image, and continues bootstrap using mounted project files.
- Stack helpers (`omni stack <up|down|ps>`) must run on the host (Docker CLI required).

## Commands Affected by Docker Mode
- `--run` / `--phase` / `--init`: Respect `DOCKER_EXEC_MODE`; may re-exec in container for bootstrap work.
- `build` / `forge`: When invoked via `omni.sh`, will follow the same re-exec rules if container mode is enabled; otherwise run on host.
- `status` / `list` / `config`: Read-only; typically run where invoked (no re-exec required).

## Environment Variables
- `DOCKER_EXEC_MODE` (`host`|`container`): Select execution location.
- `INSIDE_OMNI_DOCKER`: Set internally on container re-exec; signals to skip host checks and relax git safety.
- `APP_SERVICE_NAME`: Overrides the app service name used for `docker compose` commands.
- `DOCKER_REQUIRED`: Internal; set to `false` inside container to relax Docker dependency.

## Troubleshooting
- Docker daemon unavailable: Ensure Docker is running on the host; container mode cannot start without host Docker.
- pnpm/node missing in container: Rebuild the app image (Phase 2) so tools are available inside the container.
- Git reported dirty in container: Expected; git safety is relaxed inside container to handle bind mounts.
- Compose file missing: Ensure tech_stack Docker templates have been staged before running bootstrap.
