# OmniForge Indexer

## Purpose
Scans `_build/omniforge/tech_stack/**/*.sh` and builds `.omniforge_index` for script discovery, required-var validation, and phase/profile insights.

## Metadata Source
- Scripts must declare a `#!meta … #!endmeta` block (commented). Fields read:
  - `id`, `phase`, `phase_name`, `profile_tags`
  - `uses_from_omni_config`, `uses_from_omni_settings`
  - `dependencies.packages`, `dependencies.dev_packages`
  - `top_flags`
- Dependencies should be concrete package names. `uses_from_*` must list only real env/config vars.

## Validation
- Required vars derived from `uses_from_*` (filtered to `[A-Z][A-Z0-9_]*`).
- `VALIDATE_WARN_ONLY=true` downgrades missing vars to warnings; default is strict.
- Phase normalization maps legacy strings to numeric phases; legacy header scraping is removed.

## Index Format
`.omniforge_index` lines: `script_path|id|phase|profile_tags|required_vars|dependencies|top_flags`.

## Workflow
1) Add/maintain `#!meta` in each tech_stack script.
2) Regenerate index: source indexer and run `_build_index "_build/omniforge/tech_stack"` (omni does this automatically).
3) Ensure defaults for required vars live in `omni.settings.sh`/`omni.config`.

## Notes
- Optional `# Docs:` comment blocks can list authoritative package URLs (human aid only).
- Legacy header fallback has been removed; metadata is the single source of truth.

## Metadata Fields (#!meta)
Each tech_stack script must include a commented `#!meta … #!endmeta` block. Fields:
- `id`: unique script identifier (path-like), e.g., `core/nextjs`.
- `name`: human-readable name.
- `phase`: numeric phase (0=Foundation, 1=Infrastructure, 2=Core Features, 3=User Interface, 4=Extensions & Quality).
- `phase_name`: descriptive phase label.
- `profile_tags`: list of tags (e.g., `tech_stack`, `core`, `db`).
- `uses_from_omni_config`: env/config vars sourced from `omni.config` (only real env var names).
- `uses_from_omni_settings`: env/config vars sourced from `omni.settings.sh` (only real env var names).
- `top_flags`: surfaced flags (≤5), typically base flags (`--dry-run`, `--skip-install`, `--dev-only`, `--no-dev`, `--force`, `--no-verify`).
- `dependencies.packages`: concrete package names (no PKG_* placeholders).
- `dependencies.dev_packages`: concrete dev package names.

Rules:
- Comments stay commented; indexer parses the content inside `#!meta`.
- No script-local/internal vars in `uses_from_*` (drop SCRIPT_DIR, BASH_SOURCE, PKG_*, DEPS, etc.).
- Dependencies must be actual package names; indexer emits them into the index.
- Legacy header scraping is removed; metadata is the sole source of truth.
