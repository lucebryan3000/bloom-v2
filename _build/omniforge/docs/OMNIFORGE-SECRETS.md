# OmniForge Secrets & Environment Handling

How OmniForge manages env files, secrets, and configuration during bootstrap (host and container modes).

## File Roles
- `.env` (project root): Primary environment for the app and Docker compose; populated by bootstrap scripts. Keep out of version control.
- `.env.local`: Local overrides; merged by the app at runtime. Not written by OmniForge.
- `.omni.secrets.env`: Secret values used by Docker and app; generated or updated during bootstrap. Must not be committed.
- `omni.config`: Project-level config (app name, DB name/user, feature flags). Safe for version control.
- `omni.settings.sh`: Paths and execution settings (project root, OMNIFORGE_DIR, LOG_DIR). Safe for version control.
- `omni.profiles.sh`: Profile defaults (dry-run behavior, resource hints). Safe for version control.

## Generation & Updates
- On first run, OmniForge detects missing values and writes `.env` and `.omni.secrets.env` as needed.
- If prompted (interactive), missing variables can be injected; edit values and rerun.
- Sensitive fields (e.g., DB passwords) are generated when absent and stored only in `.omni.secrets.env`.

## Usage in Host vs Container
- Host mode: `.env` and `.omni.secrets.env` are read by Docker compose and bootstrap scripts.
- Container mode (`DOCKER_EXEC_MODE=container`): Host starts services with these files mounted; inside the app container, the same files are available via the bind mount.

## Keep These Out of Git
Add to `.gitignore` (already typically present):
- `.env`
- `.omni.secrets.env`
- `.env.local` (if present)

## Common Commands
- Regenerate missing vars (interactive prompt): rerun `./_build/omniforge/omni.sh --run` and accept injection of missing variables.
- Inspect env files: `cat .env` (non-secret values) and `cat .omni.secrets.env` (sensitive—handle carefully).
- Refresh secrets: delete `.omni.secrets.env` and rerun bootstrap to regenerate (will prompt/auto-create).

## Troubleshooting
- Missing keys at runtime: rerun `omni --run` to inject defaults and rebuild `.env`/`.omni.secrets.env`.
- Docker compose cannot find env: ensure `.env` and `.omni.secrets.env` exist before `stack up` or `omni --run` in container mode.
- Leaked secrets: rotate affected values (e.g., DB password) in `.omni.secrets.env`, restart services, and remove exposed copies.

## References
- Workflow: `_build/omniforge/docs/OMNIFORGE-WORKFLOW.md`
- Docker behavior: `_build/omniforge/docs/OMNIFORGE-DOCKER.md`
- Architecture: `_build/omniforge/docs/OMNIFORGE-ARCHITECTURE.md`
- Phases: `_build/omniforge/docs/OMNIFORGE-PHASES.md`
