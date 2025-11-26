# OmniForge Quick Reference

Fast lookup for commands, states, paths, and Docker behavior when bootstrapping bloom-v2 with OmniForge. Use this as a cheat sheet; see linked docs for depth.

## Essential Commands
- Help & menu: `./_build/omniforge/omni.sh --help` (no args opens menu)
- List phases/scripts: `./_build/omniforge/omni.sh --list`
- Run all phases: `./_build/omniforge/omni.sh --run`
- Single phase: `./_build/omniforge/omni.sh --phase <0-5>`
- Status/state: `./_build/omniforge/omni.sh --status`
- Clear state: `./_build/omniforge/omni.sh status --clear [script]`
- Build verify: `./_build/omniforge/omni.sh build [--skip-lint|--skip-types|--skip-build]`
- Purge download cache: `./_build/omniforge/omni.sh --purge`
- Container mode: `DOCKER_EXEC_MODE=container ./_build/omniforge/omni.sh --run`

## Key Paths & Files
- Config: `_build/omniforge/omni.config`, `_build/omniforge/omni.settings.sh`, `_build/omniforge/omni.profiles.sh`, `_build/omniforge/omni.phases.sh`
- State: `.omniforge_state` (project root)
- Index: `.omniforge_index` (project root)
- Logs: `_build/omniforge/logs/` (rotated)
- Cache: `_build/omniforge/.download-cache/`

## Modes & Flags
- Dry-run: `--dry-run` (default for `STACK_PROFILE=tech_stack` unless overridden)
- Force rerun scripts: `--force`
- Verbose/quiet: `-v` / `-q`
- Docker re-exec: `DOCKER_EXEC_MODE=container` (starts app + Postgres, then re-execs inside app container)

## Prerequisites
- Host: `git`, `node` (>=20), `pnpm`, `docker` (+ compose), `psql` when DB tasks run
- Local toolchain: when outside Docker, OmniForge installs/activates project-local Node.js + pnpm under `.tools/`

## Reruns & Recovery
- Targeted rerun: `--phase <n> --force`
- Clear specific state: `omni.sh status --clear "<script-path>"`
- Logs for debugging: `tail -f _build/omniforge/logs/omniforge_*.log`

## References
- CLI: `_build/omniforge/docs/OMNIFORGE-CLI.md`
- Workflow: `_build/omniforge/docs/OMNIFORGE-WORKFLOW.md`
- Architecture: `_build/omniforge/docs/OMNIFORGE-ARCHITECTURE.md`
- Phases: `_build/omniforge/docs/OMNIFORGE-PHASES.md`
- Build pipeline: `_build/omniforge/docs/OMNIFORGE-BUILD.md`
- Status & state: `_build/omniforge/docs/OMNIFORGE-STATUS.md`
- Docker behavior: `_build/omniforge/docs/OMNIFORGE-DOCKER.md`
