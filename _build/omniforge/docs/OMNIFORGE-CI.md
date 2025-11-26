# OmniForge CI/CD Runbook

How to run OmniForge non-interactively in pipelines, including docker mode, caching, logs, and testing.

## Core Steps (Typical Pipeline)
1) Check out repo and install system deps (Docker + compose available, or run inside the app container).
2) Bootstrap (non-interactive):
   ```bash
   DOCKER_EXEC_MODE=container ./_build/omniforge/omni.sh --run --phase 0
   DOCKER_EXEC_MODE=container ./_build/omniforge/omni.sh --run --phase 1
   DOCKER_EXEC_MODE=container ./_build/omniforge/omni.sh --run --phase 2
   DOCKER_EXEC_MODE=container ./_build/omniforge/omni.sh --run --phase 3
   DOCKER_EXEC_MODE=container ./_build/omniforge/omni.sh --run --phase 4
   ```
   - Or single call: `DOCKER_EXEC_MODE=container ./_build/omniforge/omni.sh --run`
   - Add `--continue` if you want to keep going after errors.
3) Build/verify: `DOCKER_EXEC_MODE=container ./_build/omniforge/omni.sh build --skip-lint --skip-types` (or keep defaults).
4) Tests: run Vitest/Playwright as needed (ensure app/Postgres are up for E2E).

## Environment
- `NON_INTERACTIVE=true` recommended to avoid prompts.
- `LOG_FORMAT=json` if you want machine-readable status output (`omni --status`).
- `STACK_PROFILE` to select profile (e.g., `full`, `tech_stack`).
- `DOCKER_EXEC_MODE=container` to re-exec inside app container (preferred for parity).

## Caching
- Download cache: `_build/omniforge/.download-cache/` (can be persisted between CI runs to speed installs).
- Node_modules: typically built fresh inside container; rely on pnpm cache if your CI supports it.
- Logs: `_build/omniforge/logs/` (capture as artifact for debugging).

## Services
- If running on host with Docker: ensure `docker compose up -d app postgres` is available; `omni stack up` is host-only.
- In container mode: the wrapper starts app + Postgres before re-exec. Make sure compose files are staged.

## Non-interactive Flags
- `--dry-run` for preview-only (common in tech_stack profile by default).
- `--force` to rerun scripts if state exists.
- `--phase <n>` to scope runs; `--continue` to avoid fail-fast behavior.

## Artifacts to Collect
- Logs: `_build/omniforge/logs/omniforge_*.log` (and Playwright reports if E2E run).
- Build outputs (if needed by downstream steps).

## Failures & Recovery
- Rerun failed phases with `--phase <n> --force`.
- Purge cache if suspect: `./_build/omniforge/omni.sh --purge` (or remove `.download-cache/`).
- Clear state selectively: `./_build/omniforge/omni.sh status --clear "<script>"`.

## Minimal CI Example (container mode)
```bash
export NON_INTERACTIVE=true
export STACK_PROFILE=full
export DOCKER_EXEC_MODE=container

./_build/omniforge/omni.sh --run --continue
./_build/omniforge/omni.sh build --skip-lint --skip-types
pnpm test               # vitest
pnpm playwright test    # e2e (ensure services running)
```

## References
- Docker behavior: `_build/omniforge/docs/OMNIFORGE-DOCKER.md`
- Testing: `_build/omniforge/docs/OMNIFORGE-TESTING.md`
- Flags: `_build/omniforge/docs/OMNIFORGE-FLAGS.md`
- Profiles: `_build/omniforge/docs/OMNIFORGE-PROFILES.md`
- Workflow: `_build/omniforge/docs/OMNIFORGE-WORKFLOW.md`
