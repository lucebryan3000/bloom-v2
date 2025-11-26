# OmniForge Optional Services & Feature Flags

Matrix of `ENABLE_*` flags and the scripts/services they control. Adjust these in `omni.config` or per-profile in `omni.profiles.sh`.

## Flag Matrix (examples)
- `ENABLE_REDIS` → `tech_stack/docker/redis-setup.sh`; include Redis service in compose.
- `ENABLE_MEILI` → `tech_stack/docker/meilisearch-setup.sh`; include Meilisearch service in compose.
- `ENABLE_MINIO` → `tech_stack/docker/minio-setup.sh`; include Minio service in compose.
- `ENABLE_OBSERVABILITY` → `tech_stack/docker/observability-setup.sh`; includes traces/logging stack in compose.
- `ENABLE_AUTHJS` → `tech_stack/auth/*` scripts (Auth.js setup/routes).
- `ENABLE_AI_SDK` → `tech_stack/features/ai-sdk.sh` and related AI wiring.
- `ENABLE_PG_BOSS` → `tech_stack/jobs/pgboss-setup.sh` and job templates.
- `ENABLE_SHADCN` → `tech_stack/ui/shadcn-init.sh` and UI components.
- `ENABLE_PDF_EXPORTS` → export scripts in `tech_stack/export/` (PDF, Excel, Markdown, JSON).
- `ENABLE_TEST_INFRA` → `tech_stack/testing/*` (vitest/playwright setup) when enabled.
- `ENABLE_CODE_QUALITY` → `tech_stack/quality/*` (eslint/prettier/husky) when enabled.

## Profiles
- Profiles in `omni.profiles.sh` can set defaults for these flags; `STACK_PROFILE` selects which profile applies.
- For container setups, ensure compose templates exist for enabled services before turning flags on.

## Changing Flags
- Edit `_build/omniforge/omni.config` for project defaults.
- Override per run: `ENABLE_REDIS=false ENABLE_MINIO=true ./_build/omniforge/omni.sh --run`.
- Profiles: adjust defaults in `omni.profiles.sh` (e.g., enable services for specific profiles).

## Regenerating Outputs
- After changing flags, rerun relevant phases or `--run`; use `--force` to rerun scripts if already marked complete.
- For compose changes, re-run docker setup scripts or regenerate compose files by rerunning the associated phase.

## Troubleshooting
- Service missing in compose: ensure flag is true and rerun phase 1 Docker scripts.
- Scripts skipped unexpectedly: verify flags in both `omni.config` and `omni.profiles.sh`; check `.omniforge_index` after rerun.
- CI differences: confirm `STACK_PROFILE` and exported flags in CI match local expectations.

## References
- Profiles & defaults: `_build/omniforge/docs/OMNIFORGE-PROFILES.md`
- Docker behavior: `_build/omniforge/docs/OMNIFORGE-DOCKER.md`
- Phases: `_build/omniforge/docs/OMNIFORGE-PHASES.md`
- Architecture: `_build/omniforge/docs/OMNIFORGE-ARCHITECTURE.md`
