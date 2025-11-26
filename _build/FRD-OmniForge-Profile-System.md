# FRD – OmniForge Profile System Refactor & Profile Editor

## 1) Objective & Scope
- Objective: Consolidate OmniForge’s profile system into a single, data-driven source of truth, refactor runtime application to use it, and add a safe CLI/UX for viewing and editing profiles with validation guardrails.
- In scope:
  - Data-driven profile application and validation (map-based).
  - A `profiles` command with diagnostics and basic edit/append/clone capabilities.
  - Documentation/help updates for discoverability.
  - Preserving existing DRY_RUN/resource/profile behaviors (tech_stack special handling).
- Out of scope: phase engine (`lib/phases.sh`/`omni.phases.sh`), tech_stack ordering, indexer changes, state handling changes, and any script-selection logic.

## 2) Current Execution Path (pre-refactor)
- `omni.sh` dispatches to bin scripts; applies DRY_RUN defaults (PROFILE_DRY_RUN, tech_stack forced dry-run).
- `bin/omni`: `config_load` → `config_validate` → `config_apply_profile` (case switch) → phases; reapplies DRY_RUN defaults; uses PROFILE_RESOURCES in container mode.
- Menus (`lib/menu.sh`): use AVAILABLE_PROFILES + `apply_stack_profile`; `menu_bootstrap` bypasses `config_apply_profile`; no profile editor.
- Validation: `config_validate_all` checks STACK_PROFILE aliases, not map consistency.
- Phases: run all listed scripts; scripts may self-check flags; indexer builds `.omniforge_index` (unchanged).

## 3) Target Execution Flow (post-refactor)
1) `config_load` (via bootstrap) sources config/settings/profiles, resolves aliases/defaults, then runs profile validation.
2) Validation fails fast if profiles/maps are inconsistent.
3) `config_apply_profile` calls data-driven apply; limited special-cases afterward (tech_stack).
4) DRY_RUN defaults from wrapper/bin remain; phases execute unchanged.
5) `omni profiles` command provides listing/details/edit/append/clone and a `--validate` diagnostic.

## 4) Key Requirements (concise)
- **Command/UX**: Add `profiles` command; menu supports list/details/edit-in-editor/append/clone; include `omni profiles --validate` diagnostic. Phase 1 editor is append-only; remind users to manually update AVAILABLE_PROFILES/PROFILE_DRY_RUN/PROFILE_RESOURCES.
- **Model/Apply**: Provide `omni_profile_apply_from_map` that normalizes keys (uppercase, hyphens→underscores), resolves aliases (e.g., `full`→`asset_manager`, `api-only`→`erp_gateway`, `custom_bos`→`tech_stack`; map `minimal` explicitly or drop), validates existence, exports only ENABLE_*; optional metadata export is read-only. `apply_stack_profile` delegates to the shared apply helper so menu/runtime align.
- **Validation**: `omni_profiles_validate_all` runs inside `config_load` after sourcing `omni.profiles.sh`; uses resolved key; required metadata: name, description, recommended; optional: tagline, time_estimate (warn/default). Warn on non-ENABLE_* keys; error on missing required/map/list mismatches. Return non-zero on errors only.
- **Precedence**: Profile map sets defaults; explicit env/CLI/omni.config ENABLE_* overrides win; apply must not clobber user-set values. DRY_RUN defaults from wrapper/bin are authoritative; map apply never overrides user DRY_RUN. PROFILE_RESOURCES apply only in container mode after apply.
- **Defaults/Aliases**: Default STACK_PROFILE = `asset_manager` (match shipped config); apply the concrete alias map before validation/apply/DRY_RUN/logging (e.g., `full`→`asset_manager`, `api-only`→`erp_gateway`, `custom_bos`→`tech_stack`; map `minimal` explicitly or drop).
- **Docs/Help**: Update CLI/help (OMNIFORGE-CLI.md, usage text) to advertise `profiles`/`--validate`; adjust examples where `full` is used as an alias.
- **Scope**: Indexer and state handling are unchanged.

## 5) Phased Plan (simplified)
1) **Phase 1 – Model & validation**: Add apply/validate helpers; hook validation into `config_load`; add `omni profiles --validate`; keep existing `config_apply_profile` temporarily; ensure helpers are sourced via bootstrap (guard/error if missing).
2) **Phase 2 – Runtime switch**: Refactor `config_apply_profile` to use map-based apply + tech_stack special-case; remove legacy case once parity confirmed; keep DRY_RUN/resource behavior unchanged.
3) **Phase 3 – `omni profiles` editor**: Add command routing; implement list/details/edit/append/clone (append-only) using shared helpers; remind users to update AVAILABLE_PROFILES/PROFILE_DRY_RUN/PROFILE_RESOURCES.
4) **Phase 4 – Optional UX polish**: Menu hook for profiles; optional array edits/reordering/metadata persistence.

## 6) Guardrails
- Run validation after logging is available (bootstrap/common), or provide a minimal fallback logger if invoked early.
- Use resolved profile key consistently for validation/apply/logging.
- Preserve tech_stack behaviors: force dry-run by default and enable-all features.
- Formatting: keep `declare -A PROFILE_<KEY>=( ... )` with quoted values; avoid reflowing existing arrays.
- Docs alignment: sync CLI/help with new commands and alias handling; note state doc mismatch separately (profile refactor does not change state files).

## Additional Clarifications
- **Validation ownership:** STACK_PROFILE validation lives in `omni_profiles_validate_all`; `config_validate_all` should defer to it (keep only legacy alias warnings if needed) to avoid duplicate checks.
- **Menu/bootstrap validation:** Choose and document: either `menu_bootstrap` runs `omni_profiles_validate_all` before phases (preferred) or explicitly note menus skip it but rely on `apply_stack_profile` delegating to the shared apply helper.
- **Diagnostic hook behavior:** `omni profiles --validate` runs validation, lists profiles with status/warnings, exits 0 on success and non-zero on errors (CI-friendly).
- **Helper sourcing guard:** `config_load` must error if profile helpers aren’t sourced (e.g., bypassing bootstrap) to prevent silent failures.
- **Docs sync detail:** Update docs/examples that use `full` to reflect the chosen alias/real profile and new `profiles`/`--validate` command exposure.
