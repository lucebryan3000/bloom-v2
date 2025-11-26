# OmniForge Six-Phase Stack Builder

OmniForge bootstraps the bloom-v2 stack through a six-phase pipeline that installs tooling, provisions Docker services, wires app features, and verifies quality. Use this guide to understand what each phase does, how to run or rerun phases, and how dry-run/state/force behaviors work.

## Quick Start
- List phases and scripts: `./_build/omniforge/omni.sh --list`
- Run all phases (non-interactive): `./_build/omniforge/omni.sh --run`
- Run a single phase: `./_build/omniforge/omni.sh --phase <0-5>`
- Dry-run preview: add `--dry-run` (default for `STACK_PROFILE=tech_stack`)
- Rerun even if marked complete: add `--force`

## Phase Summary
| # | Name | What it sets up | Docker | Notes |
| --- | --- | --- | --- | --- |
| 0 | Project Foundation | Next.js 15, React 19, TypeScript 5, package metadata, engines, base dirs | Yes | Requires git/node/pnpm; installs core packages. |
| 1 | Infrastructure & Database | Dockerfiles/compose, Postgres, Drizzle ORM, env scaffolding, rate limiter, server action template | Yes | Starts/uses Docker; longest phase; warms DB client and migrations. |
| 2 | Core Features | Auth.js, AI SDK wiring, chat scaffolds, state (Zustand), pg-boss jobs, logging (Pino) | Yes | Depends on OpenSSL (builtin); wires prompts/state/job templates. |
| 3 | User Interface | shadcn/ui init, component structure, react-to-print support | Yes | UI scaffolding and component organization. |
| 4 | Extensions & Quality | Export system (PDF/Excel/Markdown/JSON), monitoring/feature flags, testing (vitest/playwright), lint/format | Yes | Optional packages toggled via flags; quality gates. |
| 5 | User-Defined | Custom scripts/packages you add | Optional | Disabled by default; add scripts to `BOOTSTRAP_PHASE_05_USER_DEFINED`. |

Phase definitions live in `_build/omniforge/omni.phases.sh` and drive both plan listings and execution.

## Controls and Behaviors
- **Profiles & dry-run**: `STACK_PROFILE=tech_stack` defaults to dry-run unless you explicitly set `--no-dry-run`. Other profiles honor `PROFILE_DRY_RUN` defaults.
- **State & resume**: Script completions are tracked; view with `--status`. Use `--force` to re-execute or `omni status --clear [key]` to drop state entries.
- **Failure handling**: Default is fail-fast; use `--continue` (with `bin/omni`) to keep going after errors during non-interactive runs.
- **Prereqs & packages**: Host-side prereq checks run before phases; background installers warm caches. Packages for each phase are declared alongside scripts in `omni.phases.sh`.

## Docker Behavior
- Bootstrap commands require Docker; the wrapper will start needed services (app + Postgres) and re-exec inside the app container when `DOCKER_EXEC_MODE=container`.
- Inside the container, git-safety checks relax and host-specific validations are skipped. Stack helpers (`omni stack <up|down|ps>`) must be run on the host.

## Logs and State Locations
- Logs: `_build/omniforge/logs/` (rotated automatically). See `_build/omniforge/docs/OMNIFORGE-LOGGING.md` for management tips.
- State: `.omniforge_state` (script status) and `.omniforge_index` (indexed tech_stack metadata) in the project root.

## Reruns and Troubleshooting
- Re-run a single failing phase with `--phase <n> --force`.
- To preview changes without writing, combine `--dry-run` with `--phase` or `--run`.
- If required variables are missing, the indexer will prompt (when interactive) to inject placeholders into `omni.settings.sh`; update values and rerun.
