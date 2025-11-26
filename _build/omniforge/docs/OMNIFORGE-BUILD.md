# OmniForge Build & Verification Pipeline

OmniForge ships a build/verify helper (`bin/forge`, surfaced as `omni build`/`omni forge`) that installs dependencies, runs lint + type checks, and builds the app. Use this guide for flags, execution order, and Docker considerations.

## Quick Commands
- Full pipeline: `./_build/omniforge/omni.sh build`
- Skip lint: `./_build/omniforge/omni.sh build --skip-lint`
- Skip type check: `./_build/omniforge/omni.sh build --skip-types`
- Skip build: `./_build/omniforge/omni.sh build --skip-build`
- Verbose logs: add `-v`
- Dry-run preview: add `--dry-run` (honors `DRY_RUN=true`)

## What Runs (Order)
1) `pnpm install`
2) `pnpm lint` (skipped with `--skip-lint`; non-fatal if it fails, logs a warning)
3) `pnpm typecheck` (or `pnpm tsc --noEmit` fallback; skipped with `--skip-types`; non-fatal if it fails, logs a warning)
4) `pnpm build` (skipped with `--skip-build`; failures are fatal)

## Flags and Environment
- `-n, --dry-run` / `DRY_RUN=true`: preview commands via `run_cmd` without applying changes.
- `-v, --verbose` / `VERBOSE=true`: more logging.
- `--skip-lint`, `--skip-types`, `--skip-build`: toggle individual steps.

## Behavior Notes
- Configuration is loaded and validated before running; logging is initialized and output goes to `_build/omniforge/logs/`.
- The command runs from `PROJECT_ROOT`, so artifacts land in the normal project directories.
- Lint/typecheck failures do not stop the pipeline; build failures do.
- When run through `omni.sh`, Docker re-exec is handled automatically if `DOCKER_EXEC_MODE=container`.

## Recommended Usage
- After bootstrap: `omni forge` (or `omni build`) to validate the generated stack.
- In CI: `omni forge --skip-lint --skip-types` if lint/types already run elsewhere, or keep defaults for full verification.

## Troubleshooting
- Missing pnpm/node: rerun `omni --run` or ensure local tools are set up; `omni.sh` will install project-local tools on the host.
- Docker unavailable: ensure bootstrap was run or use host mode if appropriate; build itself runs in the project root but `omni.sh` may re-exec inside the app container when configured.
- Lint/types warnings: fix issues, or rerun with `--skip-*` if intentionally deferred (not recommended for CI).
