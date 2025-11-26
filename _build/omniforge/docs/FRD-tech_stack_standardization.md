# FRD – OmniForge Tech Stack Standardization (lean update)

## Purpose
Finish standardizing tech_stack scripts so metadata, flags, and the indexer provide reliable, machine-readable insight without changing runtime behavior.

## What’s Already Done
- Runtime now uses `omni.config`, `omni.settings.sh`, `omni.profiles.sh`, `omni.phases.sh` (no `bootstrap.conf` dependency).
- `parse_stack_flags` is implemented in `lib/common.sh` (supports dry-run/skip-install/dev-only/no-dev/force/no-verify) and `omni.profiles.sh` exposes `mode` defaults.
- Indexer writes 7-field `.omniforge_index` (`script|id|phase|profile_tags|required_vars|dependencies|top_flags`) and parses `#!meta` blocks with phase normalization; consumers read the 7-field format.
- Indexer warns when required vars are missing and falls back to legacy scraping when metadata is absent.

## Decisions (locked)
- Required_vars: Meta-only with lint enforcement; required_vars must be accurate and non-empty per script.
- Schema: Keep the 7-field index (`script|id|phase|profile_tags|required_vars|dependencies|top_flags`); `uses_cache`/`alias_of` dropped from scope.
- Metadata completeness rules: uses_from_* must list actual vars; dependencies must list actual packages; profile_tags must be meaningful; top_flags only when supported; id/phase present and numeric; required_vars non-empty/accurate.
- Lint/CI: Implement checks for meta completeness, required_vars (meta-only), numeric phases, `parse_stack_flags` usage, and `bash -n`; run in CI (fail or warn-to-fail per policy).
- Cache hygiene: Choose canonical tarball versions, prune duplicates in `.download-cache/`, document chosen versions; no index schema field for cache.

## Remaining Gaps
- Incomplete metadata coverage: many scripts still lack `#!meta` blocks with real ids, profile_tags, uses_from_omni_*, dependencies, and top_flags.
- Required vars need to be accurate and derived from actual usage; some scripts still emit empty required_vars.
- No lint/check enforcing metadata presence/quality across all scripts.
- Cache hygiene not guaranteed (tarball versions and declarations may be inconsistent).

## Target State
- Every tech_stack script has a `#!meta … #!endmeta` block with: `id`, `phase` (numeric), `profile_tags`, `description`, `uses_from_omni_config`, `uses_from_omni_settings`, `dependencies.packages/dev_packages`, and `top_flags` where relevant.
- Scripts honor `parse_stack_flags` outputs (no success marking on dry-run; install/verify respect skip/dev flags) while preserving existing behavior otherwise.
- `.omniforge_index` remains the single 7-field format populated from metadata (legacy scrape only as a warning fallback).
- Lint/check exists to validate metadata presence, required-var derivation, phase numeric, and `bash -n` hygiene.
- Cache hygiene is addressed (prune duplicate tarballs to a single chosen version per package and document choices).

## Issues & Recommendations (current gaps)
- Meta quality not enforced  
  - Issue: Meta exists but fields are often empty/placeholders; required_vars stay empty.  
  - Recommendation: Validate meta at index time; warn/fail on empty key fields (required_vars, uses_from_*, dependencies, profile_tags). Treat empty meta as non-compliant.
- Required-vars validation disabled  
  - Issue: `indexer_validate_requirements` is hardcoded to return early; missing required vars never surface.  
  - Recommendation: Re-enable validation to at least warn; tie behavior to the chosen required_vars strategy (meta-only).
- Undefined completeness rules  
  - Issue: No definition of what complete uses_from_*, dependencies, profile_tags, top_flags look like.  
  - Recommendation: Define minimum content per field and enforce via validation/lint.
- Consumers assume happy path  
  - Issue: Empty/unknown fields don’t surface strongly; “fresh” index may skip rebuild even if low-quality.  
  - Recommendation: Surface warnings for empty/unknown fields and rebuild index when validation fails, regardless of age.
- Injection/requirements hooks neutered  
  - Issue: Missing-var injection relies on required_vars but validation is disabled and vars are empty.  
  - Recommendation: After re-enabling validation, make injection useful by ensuring required_vars are populated per chosen strategy.
- Flags unused in scripts  
  - Issue: Scripts don’t call `parse_stack_flags`; flags ignored; success marked on dry-run.  
  - Recommendation: Make `parse_stack_flags` mandatory; honor flags; no success mark on dry-run.
- Metadata is boilerplate/empty  
  - Issue: uses_from_*, dependencies, profile_tags, top_flags are empty/generic; occasional junk values.  
  - Recommendation: Require real values per script (uses_from_*, dependencies, profile_tags, meaningful top_flags); empty meta is non-compliant.
- Required vars misaligned  
  - Issue: Scripts use vars but required_vars remain empty (meta-only derivation).  
  - Recommendation: Enforce accurate required_vars via meta + lint (meta-only strategy); pick and document the approach.
- Cache hygiene not enforced  
  - Issue: Duplicate tarball versions may exist; cache expectations are not documented.  
  - Recommendation: Choose canonical tarball versions, prune duplicates, and document choices.
- No lint/enforcement  
  - Issue: No guardrail for meta completeness, required_vars, numeric phases, flag usage, `bash -n`.  
  - Recommendation: Add lint/CI checks; update `_build/omniforge/tech_stack/_templates/script.sh` as canonical and lint against it.

## Action Plan
1) Add/verify `#!meta` blocks across all tech_stack scripts (ids, phases, profile_tags, uses_from_*, dependencies, top_flags). Fix empty required_vars by reflecting actual usage (meta-only strategy).
2) Ensure scripts use `parse_stack_flags` patterns from the template (skip success on dry-run; respect skip/no-dev/no-verify paths).
3) Prune duplicate tarballs in `.download-cache/` and document chosen versions.
4) Add a lint/check script to enforce metadata completeness (per rules above), required-vars, numeric phases, and `bash -n`; run it in CI.
5) Maintain `_build/omniforge/tech_stack/_templates/script.sh` as the canonical example reflecting the standardized pattern.
