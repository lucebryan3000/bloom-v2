# OmniForge Branded Landing (Manifest + Page) – Execution Plan (FRD)

## Objective
Deliver a reproducible, branded “Deployed by OmniForge” landing page for every deployment:
- Source of truth: OmniForge profiles/settings (not runtime introspection).
- Profiles remain metadata only (no JSX/templates in profiles).
- Landing page reads a generated manifest; safe fallback if manifest is missing/invalid.

## Guardrails
- Manifest is written once after a successful `omni run` (skip on failure, dry-run, single-phase unless explicitly allowed).
- Page must handle missing/malformed manifest with a minimal fallback and warn on parse errors.
- Use a real template file (no JSX in profiles; avoid heredocs).
- Keep changes minimal and idempotent; landing-page script overwrites page.tsx even if it exists.
- Canonical manifest path: `PROJECT_ROOT/omni.manifest.json`; template reads from `process.cwd()` + that filename. Ensure Docker image copies it there.

## Alignment with `_build/web-docker-done.md`
- Step 1 (HTML → TSX) completed: design from `_build/omni-landing-design-v3.html` converted to TSX template.
- Step 2 (inject manifest-shaped data) completed: template now reads `omni.manifest.json`, warns on read/parse errors, and falls back with defaults.
- Step 3 (real IO + minimal fallback card) partially pending: template currently renders with defaults when manifest is absent; we still need the manifest writer, log source, and to decide if we harden the minimal fallback card behavior once manifest IO is in place.

## Execution Plan (ordered)

1) Documentation & Metadata
- Add `docs/OMNIFORGE-MANIFEST.md` (schema, sources, fallbacks, breaking vs non-breaking fields; path = `PROJECT_ROOT/omni.manifest.json`; skip rules: failure, dry-run, single-phase unless explicitly enabled).
- Update `OMNIFORGE-PROFILES.md` to:
  - Label manifest-consumer fields as required (name, tagline, description, mode, PROFILE_DRY_RUN, PROFILE_RESOURCES), optional, or not-used-by-manifest.
  - Note these affect metadata only, not behavior.

2) Profile Accessors
- In `lib/omni_profiles.sh`, add helpers to fetch profile fields (name, tagline, description, mode, dryRunDefault, resources) with sane defaults; keep flag application logic unchanged.
- Optionally provide a “manifest view” helper to fill an associative array in one call.
- Ensure `omni.profiles.sh` includes required fields for every profile; keep PROFILE_DRY_RUN/PROFILE_RESOURCES authoritative.

3) Manifest Writer
- Add `lib/manifest.sh` with `omni_write_manifest`:
  - Inputs: STACK_PROFILE, profile metadata (via accessors), PROFILE_DRY_RUN/PROFILE_RESOURCES, ENABLE_* flags (post profile apply), settings (PROJECT_ROOT/INSTALL_DIR, URLs), package versions (node/pnpm/next), omniVersion (single source, e.g., OMNI_VERSION), timestamp.
  - Output: `PROJECT_ROOT/omni.manifest.json` (canonical path); overwrite only on success; skip on failure, dry-run, and single-phase (unless explicitly enabled).
  - Logging: log success with path; log error with reason.
- Call `omni_write_manifest` once after all phases succeed in `omni.sh` (main run flow), before recap/exit.

4) Landing Page Template + Installer (staged)
- Template now staged: `_build/omniforge/templates/next/page.tsx` (TSX converted from `_build/omni-landing-design-v3.html`), already reads `omni.manifest.json` with try/catch, warns and falls back if missing/invalid. Renders OmniForge badge, profile info, stack facets, features, dev quick-start, optional container info; uses package.json as a minor fallback for name/version.
- Next: Add `tech_stack/ui/landing-page.sh`:
  - Ensures `src/app` exists.
  - Copies the template into `src/app/page.tsx`, overwriting unconditionally to stay in sync.
- Hook `landing-page.sh` into the UI phase (same phase as UI scaffolding) so it regenerates consistently.

5) Validation
- Run `PROFILE=<profile> DOCKER=container make omni`.
- Confirm `omni.manifest.json` exists at PROJECT_ROOT in both host and container (same path the template reads).
- Confirm `src/app/page.tsx` is the manifest-based template (copied by landing-page.sh).
- Start dev (`pnpm dev` or `scripts/start-dev.sh`) and open http://localhost:3000 (or host IP); verify branded page; rename/remove manifest to confirm fallback.
- Optional: `pnpm build` to ensure SSR works with fs read/fallback.

6) Polish (optional)
- Enrich manifest stack fields (from package.json/indexer/script results); document data sources (ENABLE_* from env after profile apply; versions from package.json/runtime; resources/dryRun from PROFILE_*; settings from omni.settings/config).
- Decide on `APP_AUTO_START` policy; keep `scripts/start-dev.sh` if auto-start remains off.
- Keep manifest generation tolerant: missing fields → defaults; malformed manifest → fallback UI and log warning.

## Deliverables
- `omni.manifest.json` generated post-successful run (PROJECT_ROOT).
- Manifest schema doc + profile metadata doc updates.
- Template-driven `src/app/page.tsx` derived from `_build/omni-landing-design-v3.html` (via `landing-page.sh`).
- Manifest helper integrated into `omni.sh`.
