# OmniForge

OmniForge bootstraps and verifies the bloom-v2 stack with an opinionated, Docker-aware workflow. Use this file as your entry point to the feature docs below.

## Feature Docs (One Stop)
- CLI entry points and flags: `_build/omniforge/docs/OMNIFORGE-CLI.md`
- Workflow (start to finish): `_build/omniforge/docs/OMNIFORGE-WORKFLOW.md`
- Architecture & dependency flow: `_build/omniforge/docs/OMNIFORGE-ARCHITECTURE.md`
- Quick reference: `_build/omniforge/docs/OMNIFORGE-QUICK-REFERENCE.md`
- Six-phase stack builder: `_build/omniforge/docs/OMNIFORGE-PHASES.md`
- Build & verification pipeline: `_build/omniforge/docs/OMNIFORGE-BUILD.md`
- Status & state management: `_build/omniforge/docs/OMNIFORGE-STATUS.md`
- Docker-aware execution: `_build/omniforge/docs/OMNIFORGE-DOCKER.md`
- Indexer internals: `_build/omniforge/docs/OMNIFORGE-INDEXER.md`
- Tech stack standardization FRD: `_build/omniforge/docs/FRD-tech_stack_standardization.md`
- Logging: `_build/omniforge/docs/OMNIFORGE-LOGGING.md`
- Download cache: `_build/omniforge/docs/OMNIFORGE-CACHE.md`
- Secrets & env handling: `_build/omniforge/docs/OMNIFORGE-SECRETS.md`
- Profiles & feature flags: `_build/omniforge/docs/OMNIFORGE-PROFILES.md`
- Local toolchain (Node.js/pnpm): `_build/omniforge/docs/OMNIFORGE-TOOLS.md`
- Stack helpers (docker compose): `_build/omniforge/docs/OMNIFORGE-STACK.md`
- Settings manager: `_build/omniforge/docs/OMNIFORGE-SETTINGS.md`
- Reset & cleanup tools: `_build/omniforge/docs/OMNIFORGE-RESET-CLEANUP.md`
- Tech_stack script authoring: `_build/omniforge/docs/OMNIFORGE-SCRIPT-AUTHORING.md`
- Optional services & flags: `_build/omniforge/docs/OMNIFORGE-FLAGS.md`
- Testing & E2E harness: `_build/omniforge/docs/OMNIFORGE-TESTING.md`
- CI/CD runbook: `_build/omniforge/docs/OMNIFORGE-CI.md`
- Execution flow (one run): `_build/omniforge/docs/OMNIFORGE-EXECUTION-FLOW.md`

## Overview
- **Bootstrap phases:** Run all phases non-interactively with `omni --run` or target one with `omni --phase <0-5>`; preview with `--dry-run`. See the phases guide for details.
- **Status & reruns:** Check progress with `omni --status`, clear state with `omni status --clear`, and rerun scripts with `--force` when needed.
- **Build verification:** Validate the generated stack with `omni build` / `omni forge`, optionally skipping lint/types/build steps via flags.
- **Docker-aware flow:** Set `DOCKER_EXEC_MODE=container` to re-exec inside the app container after starting required services; run stack helpers on the host.
- **Execution flow snapshot:** See the execution flow doc for a one-page view of how OmniForge runs from entry through recap.
- **End-to-end runbook:** Follow the workflow doc for a practical sequence from prep to cleanup.

## Quick Reference
Fast command and path cheat sheet for OmniForge (CLI, phases, state, logs, Docker flags). See `_build/omniforge/docs/OMNIFORGE-QUICK-REFERENCE.md`.

## Logging
Logs live under `_build/omniforge/logs/`, rotate automatically, and always capture full detail regardless of console verbosity. See `_build/omniforge/docs/OMNIFORGE-LOGGING.md` for tailing tips and cleanup.

## Download Cache
OmniForge caches npm tarballs and related artifacts under `_build/omniforge/.download-cache/` to speed bootstrap. Purge with `omni.sh --purge` or delete the directory; it will be rebuilt on next run. See `_build/omniforge/docs/OMNIFORGE-CACHE.md` for details.

## Secrets & Environment
OmniForge writes and uses `.env` and `.omni.secrets.env` for compose/app configuration; secrets are generated when missing and must stay out of git. See `_build/omniforge/docs/OMNIFORGE-SECRETS.md` for handling, regeneration, and Docker usage.

## Profiles & Feature Flags
Profiles set defaults (e.g., dry-run) and enable/disable optional services via `STACK_PROFILE` and `ENABLE_*` flags. Update `omni.profiles.sh` and `omni.config` to change behavior. See `_build/omniforge/docs/OMNIFORGE-PROFILES.md` for details.

## Local Toolchain
OmniForge installs/activates project-local Node.js and pnpm under `_build/omniforge/.tools/` when missing on the host; container runs assume the image provides them. See `_build/omniforge/docs/OMNIFORGE-TOOLS.md` for behavior and recovery.

## Stack Helpers
Use `omni.sh stack up|down|ps` (host-only) to manage app + Postgres services during bootstrap. See `_build/omniforge/docs/OMNIFORGE-STACK.md` for requirements and usage.

## Settings Manager
Run `omni.sh --settings` (or use the menu) to copy recommended IDE/tool configs from `example-files/` into the project. See `_build/omniforge/docs/OMNIFORGE-SETTINGS.md` for behavior and safety notes.

## Reset & Cleanup
Use `omni.sh reset` to remove OmniForge system files/state, `omni.sh clean --path <dir> [--level]` for artifact cleanup, and `omni.sh --purge` to drop the download cache. See `_build/omniforge/docs/OMNIFORGE-RESET-CLEANUP.md` for commands and safety notes.

## Tech_Stack Script Authoring
Follow the script authoring guide to add/modify tech_stack scripts using the standard template, metadata, package install patterns, and idempotency rules. See `_build/omniforge/docs/OMNIFORGE-SCRIPT-AUTHORING.md`.

## Optional Services & Flags
Map `ENABLE_*` flags to the scripts and compose services they control. See `_build/omniforge/docs/OMNIFORGE-FLAGS.md` for the matrix and guidance.

## Testing & E2E Harness
Vitest and Playwright scaffolds are included for unit/integration and E2E tests. See `_build/omniforge/docs/OMNIFORGE-TESTING.md` for commands, CI notes, and troubleshooting.

## CI/CD Runbook
Guidance for running OmniForge non-interactively in pipelines (docker mode, caching, logs, tests). See `_build/omniforge/docs/OMNIFORGE-CI.md`.
