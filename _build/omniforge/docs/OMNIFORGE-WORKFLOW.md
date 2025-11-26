# OmniForge Workflow (Start to Finish)

A practical, end-to-end runbook for bootstrapping bloom-v2 with OmniForge: prepare, dry-run, execute phases, verify, and clean up.

## 1) Prep & Prereqs
- Ensure Docker is running on the host.
- From project root, use the wrapper: `./_build/omniforge/omni.sh ...` (handles Docker re-exec and setup).
- Optional: set `DOCKER_EXEC_MODE=container` to run bootstrap inside the app container; otherwise defaults to host.

## 2) Configure
- Edit `_build/omniforge/omni.settings.sh` for environment values (DB creds, app name, etc.).
- Edit `_build/omniforge/omni.config` for stack profile and feature toggles.
- First run will auto-detect and inject missing values; update them before re-running if prompted.

## 3) Preview (Dry Run)
- List phases/scripts: `./_build/omniforge/omni.sh --list`
- Full dry-run: `./_build/omniforge/omni.sh --run --dry-run`
- Single phase dry-run: `./_build/omniforge/omni.sh --phase <0-5> --dry-run`
- Tech stack profile defaults to dry-run unless you override with `--no-dry-run` (set `DRY_RUN=false`).

## 4) Execute Bootstrap
- All phases (non-interactive): `./_build/omniforge/omni.sh --run`
- Single phase: `./_build/omniforge/omni.sh --phase <0-5>`
- Interactive menu: `./_build/omniforge/omni.sh` (no args) or `./_build/omniforge/omni.sh --init` for guided bootstrap.
- Re-run completed scripts: add `--force`.

## 5) Monitor & Rerun
- Check progress: `./_build/omniforge/omni.sh --status`
- Clear specific script state: `./_build/omniforge/omni.sh status --clear "foundation/init-nextjs.sh"`
- Clear all state: `./_build/omniforge/omni.sh status --clear`
- JSON output for CI: `LOG_FORMAT=json ./_build/omniforge/omni.sh --status`

## 6) Build & Verify
- Run the verification pipeline: `./_build/omniforge/omni.sh build`
- Skip steps if needed: `--skip-lint`, `--skip-types`, `--skip-build`
- Typical CI flow: run bootstrap (`--run`), then `omni build` (optionally with skips if lint/types ran earlier).

## 7) Docker Notes
- Container mode: `DOCKER_EXEC_MODE=container` makes omni start app + Postgres then re-exec inside the app container; git safety is relaxed inside.
- Host mode: performs prereq checks, installs project-local tools if missing, and enforces git-clean safety.
- Stack helpers (host only): `./_build/omniforge/omni.sh stack up|down|ps`.

## 8) Clean Up (Optional)
- Remove download cache: `./_build/omniforge/omni.sh --purge`
- Cleanup artifacts: `./_build/omniforge/omni.sh clean --path <dir> [--level 1-4]`

## Reference Docs
- CLI: `_build/omniforge/docs/OMNIFORGE-CLI.md`
- Phases: `_build/omniforge/docs/OMNIFORGE-PHASES.md`
- Build pipeline: `_build/omniforge/docs/OMNIFORGE-BUILD.md`
- Status/state: `_build/omniforge/docs/OMNIFORGE-STATUS.md`
- Docker behavior: `_build/omniforge/docs/OMNIFORGE-DOCKER.md`
