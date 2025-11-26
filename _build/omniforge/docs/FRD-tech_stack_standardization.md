# FRD – OmniForge Tech Stack Standardization (tech_stack + indexer + flags)

## 1. Overview

OmniForge bootstrap now relies on `omni.config`, `omni.settings.sh`, `omni.profiles.sh`, and `omni.phases.sh`; `bootstrap.conf` is retired at runtime. The next major step is to bring `_build/omniforge/tech_stack` scripts up to the same level of clarity and consistency by adding structured metadata, shared flags, and an enriched indexer.

This FRD defines how every tech_stack script should expose metadata, standard flags, and explicit config dependencies, and how the indexer and `.omniforge_index` become the authoritative registry. Codex/LLMs should be able to reason over the scripts safely without changing their behavior.

## 2. Problem Statement

* Script headers are ad-hoc; some have Phase/Profile, a few list `Requires`, most omit details.
* There is no consistent flag model (no `--dry-run`, `--skip-install`, etc.).
* `lib/indexer.sh` scrapes fragile header comments and writes limited cache lines:
  `script_path|phase|required_vars|dependencies`. Phases can be non-numeric; required vars often empty; no profiles/flags/ids.
* Cache usage (`.download-cache`) is implicit via `pkg-install.sh`; scripts don’t describe cache expectations.

This makes it hard to know per-profile/phase coverage, required config, UX around flags, and to let tools propose safe changes.

## 3. Goals and Non-Goals

### Goals

1. Standardize metadata on all tech_stack scripts via embedded YAML-style headers (ids follow path names without leading ordinals/prefixes).
2. Introduce a shared base flag set: `--dry-run`, `--skip-install`, `--dev-only`, `--no-dev`, `--force`, `--no-verify`.
3. Clarify config dependencies: declare what is used from `omni.config` and `omni.settings.sh`.
4. Extend `.omniforge_index` to carry `id`, `phase`, `profile_tags`, `required_vars`, `dependencies`, `top_flags`.
5. Align profiles (from `omni.profiles.sh`) with script defaults via a simple `mode` (`dev|prod|ci|minimal`), while keeping CLI/env precedence.
6. Keep metadata machine-friendly so Codex/LLMs can backfill, audit, and evolve scripts; document variable derivation rules; ensure cache expectations are explicit.

### Non-Goals

* No change to core behavior (e.g., package manager choice) beyond wiring flags/metadata.
* No full schema-driven UI; this is groundwork only.
* No broad per-script exotic flags beyond the base set and a few domain-specific extensions.

## 4. Current State (recon snapshot)

### 4.1 Download Cache

* `_build/omniforge/.download-cache/npm` contains tarballs (`next-16.0.3.tgz`, `drizzle-orm-0.44.7.tgz`, `lucide-react-0.554.0.tgz`) and unpacked packages (`@types/node`, `react`, `react-dom`, `@typescript-eslint/eslint-plugin`, etc.).
* `pkg-install.sh` is cache-aware (`pkg_preflight_check`, `pkg_install`, `pkg_install_dev`); the goal is that every tech_stack dependency is available via `.download-cache`, and metadata should note cache expectations (e.g., `uses_cache: [npm/next]` or description/top_flags callouts).

### 4.2 Tech Stack Tree (high level)

* Core/foundation: `foundation/`, `core/`, `env/`, `quality/`, `testing/`.
* Infra/support: `db/`, `docker/` (including redis/meilisearch/minio/traefik/observability service fragments).
* Feature/optional: `ai/`, `features/`, `jobs/`, `observability/`, `monitoring/`, `state/`, `ui/`, `export/`, `intelligence/`.
* Helper: `tech_stack/_lib/pkg-install.sh`.
* Several wrappers delegate via `exec` (e.g., `db/drizzle-setup.sh`, `auth/authjs-setup.sh`, `ai/vercel-ai-setup.sh`, `testing/vitest-setup.sh`) and do not mark their own success.

### 4.3 Representative Scripts (7)

* `core/nextjs.sh`: Installs Next/React/TS + types; creates package/tsconfig/next/app scaffolding; uses `PROJECT_ROOT`, `INSTALL_DIR`, `APP_NAME`, `APP_VERSION`, `APP_DESCRIPTION`, `NODE_VERSION`; cache-aware via pkg-install; no flags; skip via `has_script_succeeded`.
* `core/database.sh`: Installs drizzle-orm + postgres client + drizzle-kit; writes drizzle config, db scaffolding, docker-compose, `.env.example`; uses DB vars, `POSTGRES_VERSION`, `APP_NAME`; pkg-install; no flags; warns if `package.json` missing.
* `core/auth.sh`: Installs `next-auth@beta`, `@auth/drizzle-adapter`; writes auth config, API route, schema, `.env.example`, middleware template; depends on `core/database`; pkg-install; no flags; wrapper never marks success.
* `features/ai-sdk.sh`: Installs Vercel AI SDK packages; writes `src/lib/ai.ts`; appends API keys to `.env.example`; uses `PROJECT_ROOT`, `INSTALL_DIR`, `SRC_LIB_DIR`; pkg-install; no flags; phase labeled “Features” (non-numeric).
* `jobs/pgboss-setup.sh`: Installs `pg-boss`; scaffolds `src/jobs`; assumes `@/lib/env` with `DATABASE_URL`; pkg-install; no flags.
* `observability/pino-logger.sh`: Installs `pino`; writes `src/lib/logger.ts`; references `pino-pretty` but does not install it; uses `PROJECT_ROOT`, `INSTALL_DIR`; pkg-install; no flags.
* `features/testing.sh`: Installs Vitest/Playwright/Testing Library; writes configs and sample tests; uses `PROJECT_ROOT`, `INSTALL_DIR`, `SRC_TEST_DIR`, `E2E_DIR`, `DEV_SERVER_URL`; pkg-install; no flags; phase “Features”.

### 4.4 Indexer (today)

* Scans tech_stack scripts and scrapes first 30–50 lines for `# Phase:`, `# Required/Requires:`, `# Dependencies:`.
* Emits `.omniforge_index` lines: `script_path|phase|required_vars|dependencies`.
* Does not parse `#!meta`/`#!endmeta` or any YAML, nor `uses_from_omni_*`, `top_flags`, `profile_tags`, or `id`. Phases may be strings; required vars often empty.

## 5. Functional Requirements

1. **FR1 – Script metadata (YAML in comments)**  
   Each tech_stack script MUST include a `#!meta` … `#!endmeta` block with:
   * `id`, `name`, `phase` (numeric), `phase_name`, `profile_tags`, `description`
   * `uses_from_omni_config`, `uses_from_omni_settings`
   * `top_flags` (≤5, with comments), `all_flags`
   * `env_vars` (global `OMNI_STACK_*` + script-specific `OMNI_<PREFIX>_*`)
   * `dependencies.packages`, `dependencies.dev_packages`

2. **FR2 – Standard base flags**  
   All scripts MUST recognize `--dry-run`, `--skip-install`, `--dev-only`, `--no-dev`, `--force`, `--no-verify` (and env defaults `OMNI_STACK_*`, plus `OMNI_<PREFIX>_*` overrides).

3. **FR3 – Profiles can set a simple mode**  
   `omni.profiles.sh` may set `[mode]="dev|prod|ci|minimal"` to seed defaults; CLI/env always win.

4. **FR4 – Indexer parses YAML and emits enriched index**  
   `lib/indexer.sh` MUST parse `#!meta`, extract `id`, `phase`, `profile_tags`, `uses_from_*`, `dependencies`, `top_flags`, derive `required_vars`, and emit lines:  
   `script_path|id|phase|profile_tags|required_vars|dependencies|top_flags`.

5. **FR5 – Required vars validation from metadata**  
   Indexer uses `required_vars` to validate omni/env before running; `indexer_inject_missing_vars` can backfill placeholders into `omni.settings.sh`.

6. **FR6 – No runtime dependency on bootstrap.conf**  
   Remains stub-only; no script may source it.

## 6. Non-Functional Requirements

* Backwards-compatible default behavior; flags only add control paths.
* Metadata and indexer remain extensible (e.g., future `creates:`).
* Indexer remains fast; YAML blocks are small.
* Testability: `bash -n` + `./tools/omniforge_refactor.sh phase2` + `--dry-run` flows should validate changes.

## 7. Target Design

### 7.1 Metadata Schema

`#!meta` YAML block per script with fields in FR1. Supports optional future fields (e.g., `alias_of`, `creates`, `uses_cache`). Ids follow path names without leading ordinals; wrappers can set `alias_of`. Required-var derivation: any `${VAR:?` or `${VAR:-` usage and any sourced omni settings/config variables are considered required; enforce via lint/CI.

### 7.2 Flag Parsing

* `lib/common.sh` exposes `parse_stack_flags` that:
  * Detects script prefix (`NEXT`, `DB`, `AUTH`, `AI`, `TEST`, etc.).
  * Reads `OMNI_STACK_*` and `OMNI_<PREFIX>_*` env vars.
  * Parses CLI flags to set `DRY_RUN`, `SKIP_INSTALL`, `DEV_ONLY`, `NO_DEV`, `FORCE`, `NO_VERIFY`.
* Each script sets `SCRIPT_PREFIX` and calls `parse_stack_flags "$@"`, then respects the flags in preflight, install, verify, file writes, and success marking (e.g., no success mark during dry-run).

### 7.3 Indexer and `.omniforge_index`

* Parse `#!meta` YAML; if missing, warn and fall back to legacy scraping.
* Extract `id`, `phase`, `profile_tags`, `uses_from_omni_config`, `uses_from_omni_settings`, `dependencies.packages/dev_packages`, `top_flags`.
* Compute `required_vars` from `uses_from_*` (plus any legacy `Requires:` if present).
* Emit enriched lines: `script_path|id|phase|profile_tags|required_vars|dependencies|top_flags`.
* Keep background indexing, lock files, and warning behavior when metadata is absent.

## 8. Execution Plan (ordered)

### Phase 0 – Inventory and Mapping (done)
* Recon tech_stack scripts and indexer; list installed tools, required vars, header formats, inconsistencies.

### Phase 1 – Seed Metadata + Cache Declarations (7 scripts)
* Order: (1) draft metadata fields; (2) add `uses_cache`; (3) capture required vars; (4) run `bash -n`.
* Scripts: `core/nextjs.sh`, `core/database.sh`, `core/auth.sh`, `features/ai-sdk.sh`, `jobs/pgboss-setup.sh`, `observability/pino-logger.sh`, `features/testing.sh`.
* Add `#!meta` with FR1 fields, ids without ordinals, `uses_cache` entries (all deps expected in `.download-cache`), `alias_of` for wrappers as needed.
* Document required vars per `${VAR:?`/`${VAR:-` and sourced omni settings/config.
* Run `bash -n` and summarize metadata per script.

### Phase 2 – Base Flags + parse_stack_flags (same 7 scripts)
* Order: (1) implement `parse_stack_flags` in `lib/common.sh` (CLI > env > profile mode precedence) exporting `DRY_RUN`, `SKIP_INSTALL`, `DEV_ONLY`, `NO_DEV`, `FORCE`, `NO_VERIFY`; (2) add `mode` defaults in `omni.profiles.sh`; (3) wire scripts with `SCRIPT_PREFIX` and flag behaviors; (4) verify via `bash -n`/`refactor.sh`/`--dry-run`.
* In scripts, honor flags in preflight/install/file writes/verify, skip success mark on dry-run, support `OMNI_<PREFIX>_SKIP` as needed.

### Phase 3 – Indexer Upgrade (overwrite existing index)
* Order: (1) update `lib/indexer.sh` to parse `#!meta` (fallback legacy) and overwrite `.omniforge_index` with `script_path|id|phase|profile_tags|required_vars|dependencies|top_flags`; (2) audit/update consumers expecting old fields; (3) regenerate index and validate outputs.
* Derive required vars from `uses_from_*` plus legacy Requires; coerce non-numeric phases with warnings.

### Phase 4 – Full Rollout + Lint/CI
* Order: (1) apply metadata/flags/cache declarations to all `_build/omniforge/tech_stack/**/*.sh`; (2) ensure numeric phases, accurate `profile_tags`, `uses_from_*`, `uses_cache`; (3) enforce required-var derivation via lint/CI; (4) run `bash -n` across scripts, `./tools/omniforge_refactor.sh phase2`, regenerate index, resolve warnings.
* Wrappers use `alias_of` and avoid redundant success marking; standardize flag behavior.

### Phase 5 – Validation and Templates
* Order: (1) maintain `_build/omniforge/tech_stack/_templates/script.sh` to reflect the canonical pattern; (2) add a check script (lint) to enforce presence/quality of `#!meta`, required-var rules, cache declarations; (3) optionally hook lint into CI.

### Cross-Cutting Rules (approved)

* Ids follow path names with no leading ordinals/prefixes; wrappers should use `alias_of`.
* All tech_stack dependencies should be cached in `.download-cache` and declared via `uses_cache` metadata; track any missing cache artifacts for backfill.
* Required-var derivation must follow `${VAR:?`/`${VAR:-` usage and sourced omni settings/config; enforce via lint/CI.
* Phase 2/3/4 changes are approved; base flags, in-place indexer update (overwrite existing index), and full rollout proceed.
* Respect base flag behaviors across install/file/verify paths; do not mark success on dry-run.
* Keep metadata machine-friendly; prefer simple ids, consistent phases/profiles.
* Coordinate shared-file edits (omni.sh/bin/settings) carefully to avoid clobbering existing user changes.
* Wrapper handling: use `alias_of`, avoid redundant success markers, and have indexer collapse alias entries.
* Indexer overwrite: audit/update any consumers expecting old index fields before rollout.
* Phase normalization: enforce numeric phases; warn/coerce non-numeric values.
* pkg-install integration: scripts must short-circuit on dry-run/skip/no-dev; consider no-op dry-run logging in helpers.
* Env defaults: backfill required vars (INSTALL_DIR, SRC_LIB_DIR, DEV_SERVER_URL, etc.) via settings or injection when metadata rollout tightens validation.

### Optional – Script Template

* Maintain `_build/omniforge/tech_stack/_templates/script.sh` showing the canonical structure (metadata, flag parsing, preflight/install/verify, success marking, cache-aware pkg-install).

## 9. Clarification: Current vs Target Indexer Behavior

* **Today:** indexer scrapes simple header comments, emits `script_path|phase|required_vars|dependencies`, no YAML parsing, no profiles/flags/id.
* **Target (per FRD):** indexer parses `#!meta` to pull `id`, `phase`, `profile_tags`, `uses_from_omni_*`, `dependencies`, `top_flags`, derives `required_vars`, and emits enriched lines. Legacy parsing remains as fallback with warnings.
