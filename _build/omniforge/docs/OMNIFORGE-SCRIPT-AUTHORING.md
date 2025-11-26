# OmniForge Tech_Stack Script Authoring Guide

How to write or modify tech_stack scripts so they integrate cleanly with OmniForge phases, indexer, and metadata expectations.

## Template & Location
- Start from `_build/omniforge/tech_stack_script_template.sh` or copy an existing script in the relevant category.
- Place scripts under `_build/omniforge/tech_stack/<area>/script-name.sh` and register them in `omni.phases.sh` under the appropriate `BOOTSTRAP_PHASE_0X_*` list.

## Required Structure
- Shebang + `set -euo pipefail`
- `SCRIPT_DIR` resolution and `source` of `lib/common.sh` (and `tech_stack/_lib/pkg-install.sh` when installing npm packages).
- Script identity: `SCRIPT_ID` and optional `SCRIPT_NAME` for logging.
- Idempotency guard: skip if `has_script_succeeded "$SCRIPT_ID"`.
- Required vars: validate with `: "${VAR:?message}"`.
- Optional vars with defaults: `: "${VAR:=default}"`.
- Log steps with `log_step` / `log_info`; mark completion with `mark_script_success "$SCRIPT_ID"`.

## Metadata & Indexer
- Include `#!meta` lines if applicable (see standardization FRD for details). At minimum, ensure phase/profile tags and required vars are correct when indexer expects them.
- Keep `SCRIPT_ID` consistent and unique; update references in `.omniforge_index` consumers if names change (indexer regeneration will handle mappings).

## Package Installation Pattern
```bash
source "${SCRIPT_DIR}/../_lib/pkg-install.sh"
DEPS=("pkg1" "pkg2")
pkg_preflight_check "${DEPS[@]}"
pkg_install "${DEPS[@]}"
pkg_verify "pkg1"
```

## File Writes
- Use `write_file` (from `lib/utils`) for creating files with heredocs; ensures directories exist and writes atomically.
- Avoid direct `cat > file` when possible to keep consistency.

## Docker & External Binaries
- Assume Docker is available when `docker_required=true` for the phase; use `require_docker` / `require_docker_env` when needed.
- For DB/client tools, rely on preflight checks and `ensure_db_client` (container-safe) if needed inside scripts.

## Idempotency
- Scripts must be safe to rerun: check for existing files/entries, skip if already applied, and rely on `mark_script_success` state to avoid repeating work.

## Registering the Script
- Add the script path to the correct phase block in `omni.phases.sh`.
- If the script introduces packages, add them to the corresponding `PHASE_PACKAGES_*` list.
- Regenerate the index: run `./_build/omniforge/omni.sh --list` or `--run` to rebuild `.omniforge_index`.

## Testing & Validation
- Run `./_build/omniforge/omni.sh --phase <n> --dry-run` to preview actions.
- Run `bash -n` on the script to ensure syntax correctness.
- Use `./tools/omniforge_refactor.sh` (if present) for batch validations per FRD.

## References
- Template: `_build/omniforge/tech_stack_script_template.sh`
- Phases: `_build/omniforge/omni.phases.sh`
- Standardization FRD: `_build/omniforge/docs/FRD-tech_stack_standardization.md`
- Indexer: `_build/omniforge/docs/OMNIFORGE-INDEXER.md`
- Architecture: `_build/omniforge/docs/OMNIFORGE-ARCHITECTURE.md`
