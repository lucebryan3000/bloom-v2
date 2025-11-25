# Docker-Upgrade Progress Summary

## Work Completed
- Phases 1–6 from `_build/docker/DockerFirst-OmniForge-Plan-v2.md` implemented and committed on `docker-upgrade`.
- Phase 1: Docker defaults added; docker preflight/helpers; container re-exec shim for bootstrap runs; services started via compose with Postgres wait.
- Phase 2: Hardened `Dockerfile.dev` (pnpm/tools, /workspace) and compose templates (shared network, working_dir, bind mounts) plus host Makefile generation.
- Phase 3: Secrets centralized in app `.env` via new `lib/secrets.sh`; DB/admin secrets generated; compose/app/postgres use `env_file`; DB password removed from config; legacy `.env.local` merged for missing keys only.
- Phase 4: Container mode skips `.tools`; pkg installs require container pnpm; host tool setup gated; re-exec brings up app+postgres with readiness wait.
- Phase 5: Added per-script contracts, docker_required metadata enforcement, image pin logging, and `omni stack` helper (up/down/ps) for bootstrap verification.
- Phase 6: Docs updated for Docker-first model/migration; added deployment checklist under `docs/omniforge-deployment/`.

## Errors / Issues
- None encountered; all modified shell scripts pass `bash -n` checks.

## Work Left / Follow-Ups
- Run an end-to-end bootstrap in container mode to validate re-exec, env generation, and stack health.
- Verify CI path (`DOCKER_EXEC_MODE=host` or compose exec) per docs if needed.
- Optionally prune legacy `.tools` after confirming Docker-first flow.

## Next Steps
- From host: `omni stack up` (or `docker compose up -d app postgres`), then `omni run` to confirm container re-exec and env secrets.
- Capture `ADMIN_INITIAL_PASSWORD` from generated `.env`; validate admin login.
- Open a PR from `docker-upgrade` when validation is complete.
