# OmniForge Profiles & Feature Flags

Profiles tune default behaviors (e.g., dry-run, resource hints) and feature flags enable or skip optional services and scripts. This guide explains how profiles are defined and how flags influence the bootstrap pipeline.

## Profile Basics
- Defined in `_build/omniforge/omni.profiles.sh`.
- Selected via `STACK_PROFILE` (e.g., `full`, `tech_stack`, `minimal`, `api-only` if present).
- Profiles can set:
  - `PROFILE_DRY_RUN[profile]=true|false` (default dry-run behavior)
  - `PROFILE_RESOURCES[profile]="memory=... cpu=..."` (resource hints used in container mode)
  - Feature toggles (e.g., `ENABLE_*`) scoped per profile.

## Common Flags (examples)
- `ENABLE_AUTHJS`, `ENABLE_AI_SDK`, `ENABLE_PG_BOSS`, `ENABLE_SHADCN`, `ENABLE_PDF_EXPORTS`, `ENABLE_TEST_INFRA`, `ENABLE_CODE_QUALITY`, and service flags like `ENABLE_REDIS`, `ENABLE_MEILI`, `ENABLE_MINIO`, `ENABLE_OBSERVABILITY` if defined.
- Flags control whether related tech_stack scripts are included or skipped within phases (or gated in compose configs).

## How Profiles Affect Runs
- Dry-run default: `tech_stack` profile defaults to dry-run unless you override with `--dry-run=false`.
- Docker resource hints: when `DOCKER_EXEC_MODE=container`, profile hints may set `APP_MEM_LIMIT` / `APP_CPU_LIMIT` if unset.
- Optional services: scripts and compose fragments tied to disabled flags are skipped.

## Changing Profiles
- Set per-run: `STACK_PROFILE=tech_stack ./_build/omniforge/omni.sh --run`
- Set persistently: export in your shell profile or edit `omni.config` if it carries a default.

## Updating Flags
- Edit `_build/omniforge/omni.profiles.sh` for profile defaults.
- Edit `_build/omniforge/omni.config` for project-level defaults (feature flags).
- Re-run `omni --run` (or specific phases) to apply changes; rerun with `--force` if scripts were previously completed.

## Troubleshooting
- Unexpected dry-run: check `STACK_PROFILE` and `PROFILE_DRY_RUN` map; pass `--dry-run=false` to override.
- Missing services/scripts: verify relevant `ENABLE_*` flags in `omni.profiles.sh` and `omni.config`.
- Resource limits ignored: ensure you’re in container mode and hints exist for the active profile.

## References
- Profiles: `_build/omniforge/omni.profiles.sh`
- Feature flags & config: `_build/omniforge/omni.config`
- Workflow: `_build/omniforge/docs/OMNIFORGE-WORKFLOW.md`
- Docker behavior: `_build/omniforge/docs/OMNIFORGE-DOCKER.md`
- Phases: `_build/omniforge/docs/OMNIFORGE-PHASES.md`
