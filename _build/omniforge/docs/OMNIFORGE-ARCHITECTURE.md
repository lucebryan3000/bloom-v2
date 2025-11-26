# OmniForge Architecture & Dependency Flow

This document explains how OmniForge bootstraps bloom-v2 end to end: which components run, where dependencies live, how Docker is used, and where state/logs are stored. Use it as the authoritative map for the bootstrap pipeline.

## Core Layout
```
_build/omniforge/
├── omni.sh                 # Docker-aware wrapper, dispatches to bin/
├── bin/                    # Entry commands (omni, forge, status, stack, reset)
├── lib/                    # Shared libraries (logging, validation, prereqs, phases, downloads, state)
├── omni.config             # Project config (app/db values, feature flags)
├── omni.settings.sh        # Paths and environment defaults
├── omni.profiles.sh        # Profile defaults (e.g., dry-run behavior)
├── omni.phases.sh          # Phase metadata (0–5) and script lists
├── tech_stack/             # Bootstrap scripts grouped by phase/feature
├── logs/                   # Runtime logs (rotated by logging library)
└── docs/                   # Reference docs (this file, CLI, phases, workflow, etc.)
```

## Execution Flow (Host → Container)
1) **Entry**: Run `./_build/omniforge/omni.sh [command]`. The wrapper loads `lib/bootstrap.sh` and common libs.
2) **Config load/validation**: `config_load` + `config_validate_all` apply profile defaults, required vars, and file checks.
3) **Local tools (host)**: If not inside Docker, OmniForge installs/activates project-local Node.js and pnpm under `.tools/` so the stack is self-contained.
4) **Project setup**: `setup_omniforge_project` deploys template files/settings and runs one-time auto-detect on first launch.
5) **Background prep**: Prereq remediation/warmup and the tech_stack indexer start in the background; a banner shows the plan.
6) **Preflight**: `phase_preflight_check` validates required vars and indexed script requirements.
7) **Phase execution**: Runs all enabled phases or a single phase, marking success in state; optional dry-run and force behaviors apply.
8) **Recap**: Shows stats and log hints; dry-run tails recent log output.

## Dependency Model
- **Host prerequisites**: `git`, `node` (>=20), `pnpm`, `docker` (+ compose), and `psql` when DB tasks are enabled. Docker must be running for bootstrap; commands surface install hints but do not auto-install on the host.
- **Local toolchain**: When outside Docker, OmniForge installs project-local Node.js/pnpm under `.tools/` and activates them for runs.
- **Container prerequisites**: In container mode (`DOCKER_EXEC_MODE=container`), OmniForge starts the app + Postgres services on the host, then re-execs in the app container. Inside the container, git safety is relaxed and Alpine-only package installs (e.g., `psql`) may occur if `apk` is available.
- **Package installs**: Tech_stack scripts install npm deps via pnpm and cache artifacts under `_build/omniforge/.download-cache/` when applicable.
- **Config inputs**: `omni.config`, `omni.settings.sh`, `omni.profiles.sh`, and `omni.phases.sh` provide stack, paths, profile defaults, and phase metadata.

## State, Logs, and Indexes
- **State**: `.omniforge_state` (project root) tracks per-script completion; rerun with `--force` or clear via `omni status --clear`.
- **Indexer**: `.omniforge_index` lists tech_stack scripts with metadata/requirements for validation and menus.
- **Logs**: `_build/omniforge/logs/` (rotated). See `_build/omniforge/docs/OMNIFORGE-LOGGING.md` for rotation and inspection commands.
- **Caches**: `_build/omniforge/.download-cache/` holds download artifacts; `omni --purge` clears downloads.

## Host vs Container Responsibilities
- **Host**: Validates Docker/compose, installs/activates local Node.js + pnpm, enforces git clean by default, starts services for container mode, and handles downloads/cache.
- **Container**: Executes bootstrap when re-execed; skips host-only validations and relaxes git safety (`GIT_SAFETY=false`, `ALLOW_DIRTY=true`). Stack helpers (`omni stack ...`) must run on the host.

## Key Commands & Checks
- Preview plan: `./_build/omniforge/omni.sh --list`
- Run all phases: `./_build/omniforge/omni.sh --run`
- Single phase: `./_build/omniforge/omni.sh --phase <0-5>`
- Status/state: `./_build/omniforge/omni.sh --status`
- Build verify: `./_build/omniforge/omni.sh build`
- Docker mode: `DOCKER_EXEC_MODE=container ./_build/omniforge/omni.sh --run`

## Related Docs
- CLI reference: `_build/omniforge/docs/OMNIFORGE-CLI.md`
- Workflow (start to finish): `_build/omniforge/docs/OMNIFORGE-WORKFLOW.md`
- Phase guide: `_build/omniforge/docs/OMNIFORGE-PHASES.md`
- Build pipeline: `_build/omniforge/docs/OMNIFORGE-BUILD.md`
- Status & state: `_build/omniforge/docs/OMNIFORGE-STATUS.md`
- Docker-aware execution: `_build/omniforge/docs/OMNIFORGE-DOCKER.md`
