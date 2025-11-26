# OmniForge CLI (Multi-Mode Bootstrap)

OmniForge ships a multi-mode CLI that bootstraps the entire stack, checks status, manages settings, runs build verification, and offers Docker helpers. This guide covers the available commands, flags, execution flow, and Docker behavior.

## Entry Points
- Preferred: `./_build/omniforge/omni.sh <command> [options]` (wrapper that handles Docker re-exec and delegates to `bin/` scripts).
- Optional direct calls: `_build/omniforge/bin/omni`, `bin/status`, `bin/forge`, `bin/reset`, `bin/stack` (useful when already inside the app container).

## Commands at a Glance
| Command / Mode | What it does | Typical use |
| --- | --- | --- |
| *(no args)* or `menu` | Interactive menu (`menu_main`) for guided bootstrap, status, and tools. | First-time runs or exploratory use. |
| `--init` | Guided bootstrap workflow (skips the main menu, goes straight to `menu_bootstrap`). | Quick start with prompts. |
| `--run` | Non-interactive run of all enabled phases. | CI or fully scripted bootstrap. |
| `--phase <0-5>` | Non-interactive run of a single phase. | Re-run a failed/specific phase. |
| `--settings` | Settings manager (copies IDE/tool configs). | Populate local editor/tooling configs. |
| `--list` | List phases and scripts. | Inspect what will run. |
| `--status` | Show completion state of scripts. | Check progress/resume points. |
| `--config` | Show configuration summary. | Verify resolved config and profile. |
| `--purge` | Clear the OmniForge download cache. | Recover space or force fresh downloads. |
| `build` / `forge` / `compile` | Run `pnpm install`, lint, type-check, and build (skippable steps). | Post-bootstrap verification. |
| `stack <up|down|ps>` | Host-only Docker helpers for app + Postgres. | Bring stack services up/down or inspect. |
| `clean --path <dir> [--level 1-4]` | Cleanup helper with optional non-interactive mode. | Remove generated artifacts safely. |
| `reset [--yes]` | Reset OmniForge state/system files (prompted unless `--yes`). | Advanced: nuke OmniForge artifacts. |
| `-h` / `--help` | Show usage for the current entry point. | Quick reference. |

## Common Flags
- `-n, --dry-run` (or `DRY_RUN=true`): Preview actions without changing files. The `tech_stack` profile defaults to dry-run unless overridden.
- `-v, --verbose` / `-q, --quiet`: Increase or minimize logging.
- `-f, --force`: Re-run scripts even if marked complete.
- `--fail-fast` / `--continue`: Control failure handling during runs (default is fail-fast).
- `-p, --phase <0-5>`: Restrict non-interactive runs to a single phase.
- `--path <dir>` / `--level <1-4>`: Non-interactive options for `clean`.
- `--yes`: Skip confirmation for `reset`.

## Environment Variables
- `STACK_PROFILE` (e.g., `full`, `tech_stack`): Drives default dry-run behavior and optional resource hints.
- `NON_INTERACTIVE=true`: Suppress prompts (CI-friendly).
- `DOCKER_EXEC_MODE` (`host` or `container`): `container` triggers re-exec inside the app container for bootstrap commands; `host` keeps execution on the host.
- `DRY_RUN_DIR`: Where dry-run output goes when set; used if `DRY_RUN=true` and no explicit `INSTALL_DIR` is provided.
- `ALLOW_DIRTY` / `GIT_SAFETY`: Relax or enforce git-clean checks (git safety is enforced by default on the host).

## Execution Flow (Run/Phase)
1) Load and validate config; apply profile defaults (including dry-run for `tech_stack`).
2) Initialize logging, rotate/cleanup logs, and set up project-local tools (Node.js/pnpm) if missing.
3) Ensure OmniForge templates/settings are deployed (`setup_omniforge_project`) and run one-time auto-detection on first launch.
4) Kick off background prereq install and script indexing while showing the banner and plan.
5) Run preflight checks, validate required variables (offers injection if interactive), and enforce git cleanliness (relaxed inside Docker).
6) Execute all phases or the selected phase; record stats, show recap/next steps, and print log hints (tail in dry-run mode).

## Phases
Phases are defined in `omni.phases.sh`:
- 0 Foundation (Next.js/TypeScript/project structure)
- 1 Infrastructure & Database (Docker, Postgres, Drizzle, env setup)
- 2 Core Features (Auth.js, AI SDK, state, pg-boss, logging)
- 3 User Interface (shadcn/ui, printing, component structure)
- 4 Extensions & Quality (exports, testing, lint/format)
- 5 User-Defined (custom scripts)
Use `--list` to view the scripts attached to each phase and `--phase <n>` to run a single phase.

## Docker Behavior
- The wrapper (`omni.sh`) enforces container re-exec when `DOCKER_EXEC_MODE=container` and bootstrap commands are used. It will start required services (app + Postgres by default) via `docker compose` before re-exec.
- Inside the app container, git safety is relaxed and host-specific preflight checks are skipped. Stack helpers (`omni stack ...`) must run on the host where Docker is available.

## Logging and State
- Logs live under `_build/omniforge/logs/` (rotated automatically). Use `_build/omniforge/docs/OMNIFORGE-LOGGING.md` for log management details.
- Script completion state is tracked and shown via `--status`. Use `--force` to rerun scripts or `status --clear [key]` to drop specific state entries.

