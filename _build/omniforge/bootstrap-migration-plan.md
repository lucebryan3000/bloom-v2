You are acting as a senior bash/DevOps engineer and systems architect working on the OmniForge bootstrap cutover.

## Objective

Retire `bootstrap.conf` as a runtime config source and make omni-based config files canonical:

- `omni.config` – Section 1 (Quick Start) + other top-level settings.
- `omni.profiles.sh` – PROFILE_* arrays + AVAILABLE_PROFILES.
- `omni.phases.sh` – PHASE metadata (PHASE_METADATA_*, PHASE_CONFIG_*, PHASE_PACKAGES_*, BOOTSTRAP_PHASE_*).
- Optionally `omni.settings.sh` – advanced/system settings (paths, flags, versions, derived values, etc).

**Final state:**

- No runtime path sources `bootstrap.conf`.
- All config reads come from env + omni.* files.
- `bootstrap.conf` is either removed or left as a stub for legacy reference only.

We will **execute this in phases**, and you will only work on **one phase per prompt**. After each phase:

- Run `./tools/omniforge_refactor.sh phase2` (Phase 2 harness).
- Perform minimal manual checks:
  - `./omni.sh status`
  - `./omni.sh list`
  - `./omni.sh menu` (profile selection)
  - `./bin/status --config` (baseline, env override, omni override).

You MUST NOT try to do all phases at once.

Repo root: `/home/luce/apps/bloom2`  
OmniForge root: `/home/luce/apps/bloom2/_build/omniforge`  
Work happens on a feature branch (e.g., `omniforge-bootstrap-phase1`), then we merge to `main` after all phases are done and validated.

---

## Phase 0 – Inventory & Mapping (Prep only)

**Goal:** Understand exactly how `bootstrap.conf` is used today, broken down by domain.

**Scope:** READ-ONLY inspection. No code changes.

**Tasks:**

From repo root:

```bash
rg "bootstrap.conf" _build/omniforge
rg "BOOTSTRAP_CONF" _build/omniforge
```

Classify usages into domains:

* **Section 1 defaults:** APP_*, INSTALL_TARGET, STACK_PROFILE, DB_*, ENABLE_*.
* **Profile data:** PROFILE_* arrays, AVAILABLE_PROFILES.
* **Phase metadata:** PHASE_METADATA_*, PHASE_CONFIG_*, PHASE_PACKAGES_*, BOOTSTRAP_PHASE_*.
* **Advanced/system settings:** PROJECT_ROOT, path vars, safety flags, versions, logging/docker/tool settings, derived values, etc.

Record which files consume these (e.g., `lib/bootstrap.sh`, `lib/config_bootstrap.sh`, `lib/phases.sh`, `lib/menu.sh`, `bin/status`, etc.).

When we ask you to run **Phase 0**, you will:

* Only inspect and summarize; NO edits.
* Report the mapping.

---

## Phase 1 – Section 1 Cutover to `omni.config` (Config-only loader)

**Goal:** Make **Section 1** live entirely in `omni.config`, not `bootstrap.conf`. After Phase 1:

* Section 1 values are sourced from: Env → `omni.config`.
* `bootstrap.conf` can still hold those values for now (for reference), but they are not used by runtime/introspection for Section 1.

**Section 1 variables that must be canonical in `omni.config`:**

* `APP_NAME`
* `APP_VERSION`
* `APP_DESCRIPTION`
* `INSTALL_TARGET`
* `STACK_PROFILE`
* `DB_NAME`
* `DB_USER`
* `DB_PASSWORD`
* `DB_HOST`
* `DB_PORT`
* `ENABLE_AUTHJS`
* `ENABLE_AI_SDK`
* `ENABLE_PG_BOSS`
* `ENABLE_SHADCN`
* `ENABLE_ZUSTAND`
* `ENABLE_PDF_EXPORTS`
* `ENABLE_TEST_INFRA`
* `ENABLE_CODE_QUALITY`

**Important derived values:**

* `INSTALL_DIR` and related paths are derived in config from:
  * `INSTALL_TARGET`
  * `INSTALL_DIR_TEST`
  * `INSTALL_DIR_PROD`
* There are also derived markers/paths like:
  * `OMNIFORGE_SETUP_MARKER`
  * `BOOTSTRAP_STATE_FILE`
  * `GIT_REMOTE_URL`
* In Phase 1:
  * Ensure all base Section 1 vars are present in `omni.config`.
  * Keep derived behavior working as-is (still computed in `bootstrap.conf`).
  * Final migration of derived logic happens in Phase 4.

**Files allowed to change:**

* `_build/omniforge/omni.config`
* `_build/omniforge/lib/bootstrap.sh`
* `_build/omniforge/lib/config_bootstrap.sh` (config_load / status --config)

**Tasks:**

1. Ensure `omni.config` has a complete Section 1:
   * Copy Section 1 defaults from `bootstrap.conf` into `omni.config` (if anything is missing).
   * Keep values identical.
2. Update `lib/bootstrap.sh`:
   * Ensure Section 1 vars are set from `omni.config` (plus env), **not** from `bootstrap.conf`.
   * For Section 1, `bootstrap.conf` should no longer be a runtime source after this phase.
   * Preserve env override reapplication logic (env still wins over omni.config).
3. Update `lib/config_bootstrap.sh`:
   * `config_load` should read Section 1 from env → `omni.config`.
   * It should NOT rely on `bootstrap.conf` for Section 1 anymore.
   * Keep env override reapplication behavior intact.
4. Validation:
   * `bash -n` on changed files.
   * From `_build/omniforge`:
     ```bash
     ./tools/omniforge_refactor.sh phase2
     ```
   * Manual:
     ```bash
     ./omni.sh status
     ./bin/status --config
     APP_NAME="EnvOverride" ./bin/status --config
     # Optionally tweak APP_NAME in omni.config and re-run ./bin/status --config
     ```

**Success criteria:**

* Env override wins over `omni.config`.
* With env unset, Section 1 comes from `omni.config`.
* CLI behavior (status, list, menu) stays the same.

When we ask you to run **Phase 1**, you MUST:

* Touch only the allowed files.
* Implement the above steps.
* Run Phase 2 + manual tests.
* Summarize changes and results.

---

## Phase 2 – Profile Data Cutover to `omni.profiles.sh`

**Goal:** Move PROFILE_* arrays + AVAILABLE_PROFILES from `bootstrap.conf` into `omni.profiles.sh`, and use that everywhere. After Phase 2:

* Profile data is sourced from `omni.profiles.sh`.
* Profile helpers remain in `lib/omni_profiles.sh`.
* No code path re-sources `bootstrap.conf` for profile data.

**Reality check:**

* `config_apply_profile` in `lib/config_bootstrap.sh` is **case-based** (`minimal`, `full`, etc.) and does NOT rely on PROFILE_* arrays.
* PROFILE_* arrays and AVAILABLE_PROFILES are used by menu/profile flows.

**Files allowed to change:**

* `_build/omniforge/omni.profiles.sh` (new file, created in this phase)
* `_build/omniforge/lib/bootstrap.sh`
* `_build/omniforge/lib/menu.sh`
* `_build/omniforge/lib/config_bootstrap.sh` (only if truly needed for profile logic)

**Tasks:**

1. Create `_build/omniforge/omni.profiles.sh`:
   * Move PROFILE_* arrays and AVAILABLE_PROFILES from `bootstrap.conf` to this file.
   * Values unchanged.
2. Update `lib/bootstrap.sh`:
   * Source `omni.profiles.sh` before `lib/omni_profiles.sh`.
3. Update `lib/menu.sh`:
   * Stop re-sourcing `bootstrap.conf` to get profiles.
   * Assume profile data is already loaded from `omni.profiles.sh`.
   * Continue using helpers in `lib/omni_profiles.sh`.
4. If (and only if) `config_apply_profile` or related code in `lib/config_bootstrap.sh` truly needs array-based profile data:
   * Wire it to use data from `omni.profiles.sh`, which is already loaded by bootstrap.
   * Otherwise, leave `config_apply_profile` as-is (case-based fallback).
5. Validation:
   * `bash -n` on changed files.
   * `./tools/omniforge_refactor.sh phase2`.
   * Manual:
     ```bash
     ./omni.sh menu   # verify profiles listed and selectable
     ```

**Success criteria:**

* Profile data now lives in and is loaded from `omni.profiles.sh`.
* No re-sourcing of `bootstrap.conf` for profiles.
* Profile behavior unchanged.

When we ask you to run **Phase 2**, do ONLY this scope.

---

## Phase 3 – Phase Metadata Cutover to `omni.phases.sh`

**Goal:** Move phase metadata (PHASE_METADATA_*, PHASE_CONFIG_*, PHASE_PACKAGES_*, BOOTSTRAP_PHASE_*) from `bootstrap.conf` to `omni.phases.sh`. After Phase 3:

* Phase metadata is sourced from `omni.phases.sh`.
* Phase discovery/listing uses omni data, not bootstrap.

**Files allowed to change:**

* `_build/omniforge/omni.phases.sh` (new file, created in this phase)
* `_build/omniforge/lib/bootstrap.sh`
* `_build/omniforge/lib/phases.sh`

**Tasks:**

1. Create `_build/omniforge/omni.phases.sh`:
   * Move PHASE_METADATA_*, PHASE_CONFIG_*, PHASE_PACKAGES_*, BOOTSTRAP_PHASE_* from `bootstrap.conf` into it.
   * Values unchanged.
2. Update `lib/bootstrap.sh`:
   * Source `omni.phases.sh`.
3. Update `lib/phases.sh`:
   * Ensure phase logic (`phase_discover`, `phase_get_metadata_field`, etc.) reads PHASE_* from `omni.phases.sh`.
   * Remove any direct dependency on `bootstrap.conf`.
4. **Load-order requirement:**
   * `lib/bootstrap.sh` MUST source `omni.phases.sh` before any code in `lib/phases.sh` expects PHASE_* variables to be defined.
   * Phase 3 must enforce this ordering and must not rely on `phases.sh` re-sourcing config.
5. Validation:
   * `bash -n` on changed files.
   * `./tools/omniforge_refactor.sh phase2`.
   * Manual:
     ```bash
     ./omni.sh list   # phase listing looks the same as before
     ```

**Success criteria:**

* Phase metadata now lives in `omni.phases.sh`.
* No use of `bootstrap.conf` for phases.
* List/phase behavior unchanged.

When we ask you to run **Phase 3**, stay within this scope.

---

## Phase 4 – Sweep Remaining Settings & Remove `bootstrap.conf`

**Goal:** Move remaining runtime settings off `bootstrap.conf`, stop sourcing it entirely, and mark omni.* as canonical.

**Advanced/system settings to migrate (non-exhaustive):**

* Paths and structure:
  * `PROJECT_ROOT`, `OMNIFORGE_DIR`, `TOOLS_DIR`
  * `LOG_DIR`, `INSTALL_DIR_TEST`, `INSTALL_DIR_PROD`
  * `SRC_DIR`, `SRC_APP_DIR`, `SRC_COMPONENTS_DIR`, `SRC_LIB_DIR`, `SRC_DB_DIR`, `SRC_STYLES_DIR`, `SRC_HOOKS_DIR`, `SRC_TYPES_DIR`, `SRC_STORES_DIR`, `SRC_TEST_DIR`, `PUBLIC_DIR`, `TEST_DIR`, `E2E_DIR`
* Safety/behavior flags:
  * `GIT_SAFETY`, `ALLOW_DIRTY`, `NON_INTERACTIVE`, `MAX_CMD_SECONDS`, `BOOTSTRAP_RESUME_MODE`
* Logging/retention:
  * `LOG_LEVEL`, `LOG_FORMAT`, `LOG_ROTATE_DAYS`, `LOG_CLEANUP_DAYS`
* Docker/runtime toggles:
  * `ENABLE_DOCKER`, `DOCKER_EXEC_MODE`, `ENABLE_REDIS`, `DOCKER_REGISTRY`, `DOCKER_BUILDKIT`
* Version pins:
  * `NODE_VERSION`, `PNPM_VERSION`, `REQUIRED_NODE_VERSION`, `NEXT_VERSION`, `POSTGRES_VERSION`, `PGVECTOR_IMAGE`
* Env var names:
  * `ENV_ANTHROPIC_API_KEY`, `ENV_AUTH_SECRET`, `ENV_DATABASE_URL`
* Derived values:
  * `INSTALL_DIR` (based on `INSTALL_TARGET` + `INSTALL_DIR_TEST`/`PROD`)
  * `OMNIFORGE_SETUP_MARKER`, `BOOTSTRAP_STATE_FILE`, `GIT_REMOTE_URL`
  * Any derived paths/markers tied to PROJECT_ROOT/SCRIPTS_DIR must be recomputed from omni values (do not assume `bootstrap.conf` defaults).

**Files allowed to change:**

* `_build/omniforge/omni.settings.sh` (optional; or reuse `omni.config`)
* `_build/omniforge/lib/bootstrap.sh`
* `_build/omniforge/lib/config_bootstrap.sh`
* Any file still sourcing `bootstrap.conf` / `BOOTSTRAP_CONF`.
* `_build/omniforge/bootstrap.conf`
* `_build/omniforge/OMNIFORGE.md`
* (Optionally) `lib/common.sh` for BOOTSTRAP_CONF/BOOTSTRAP_CONF_EXAMPLE handling.
* (Optionally) add omni.* example files for first-run flows (replace bootstrap.conf.example usage).

**Tasks:**

1. Find remaining references:
   ```bash
   rg "bootstrap.conf" _build/omniforge
   rg "BOOTSTRAP_CONF" _build/omniforge
   ```
2. For each **runtime** use (not comments) that still depends on `bootstrap.conf` for real settings:
   * Move those settings into either:
     * `_build/omniforge/omni.settings.sh`, or
     * `_build/omniforge/omni.config` (if they conceptually belong there).
   * Update loaders/consumers to read from omni files instead of `bootstrap.conf`.
3. Ensure:
   * `lib/bootstrap.sh` no longer sources `bootstrap.conf` at all.
   * `lib/config_bootstrap.sh` doesn’t source it either.
   * No other runtime file sources `bootstrap.conf`.
   * Derived values (e.g., INSTALL_DIR, OMNIFORGE_SETUP_MARKER, BOOTSTRAP_STATE_FILE, GIT_REMOTE_URL) are recomputed from omni.* values inside the omni-based loader path.
4. Handle `common.sh` BOOTSTRAP_CONF / BOOTSTRAP_CONF_EXAMPLE:
   * Mark these as legacy references only; runtime must not depend on them.
   * Phase 4 may either:
     * Leave them as doc-only/legacy, OR
     * Remove them entirely if no code uses them after cutover.
   * Update first-run/example behavior to use omni.* equivalents (e.g., omni.config.example, omni.profiles.example, omni.phases.example, omni.settings.example) instead of bootstrap.conf.example; update `config_bootstrap.sh`/status `--config` flows accordingly.
5. Turn `_build/omniforge/bootstrap.conf` into:
   * A stub with a deprecation comment stating it is no longer used at runtime, OR
   * Delete it entirely if you’re sure nothing external depends on it.
6. Update `OMNIFORGE.md`:
   * Mark `bootstrap.conf` as legacy/removed.
   * Document:
     * `omni.config` as Section 1 & top-level settings.
     * `omni.profiles.sh` as profile data.
     * `omni.phases.sh` as phase metadata.
     * `omni.settings.sh` (if created) as advanced/system settings.
7. Validation:
   * `bash -n` on changed files.
   * From `_build/omniforge`:
     ```bash
     ./tools/omniforge_refactor.sh phase2
     ```
   * Manual:
     ```bash
     ./omni.sh status
     ./omni.sh list
     ./omni.sh menu
     ./bin/status --config     # baseline, env override, omni override
     ```

**Success criteria:**

* No runtime code path sources `bootstrap.conf`.
* Omni config files (omni.config, omni.profiles.sh, omni.phases.sh, omni.settings.sh if used) are the only config sources.
* Docs reflect this.
* Phase 2 and manual flows are green.

---

## Alignment items (pre-execution)

- **Omni file creation timing:**
  - `omni.config` exists and is expanded in Phase 1.
  - `omni.profiles.sh` is created in Phase 2.
  - `omni.phases.sh` is created in Phase 3.
  - `omni.settings.sh` is created in Phase 4 if needed.
  - Each file is created and populated with data copied from `bootstrap.conf` **before** consumers are rewired in that domain.
- **Data targets / layout:**
  - Use `omni.settings.sh` for all non–Section 1 settings and derived values (PROJECT_ROOT, paths, safety flags, logging/docker/tool settings, versions, env var names, derived values like INSTALL_DIR/markers).
  - Keep `omni.config` as Section 1 + top-level app-facing settings.
- **Fallback stance (clean cut per domain):**
  - For each domain (Section 1, profiles, phases), once its phase is complete, runtime must use only omni-based files for that domain (no runtime fallback to bootstrap.conf for that domain).
  - If a temporary bootstrap fallback is absolutely needed during a phase, log a WARN and remove it before closing the phase.
  - `bootstrap.conf` may retain a copy of data for reference, but it is not a runtime fallback once the domain has been migrated.
  - Phase 4 removes any remaining dependency and stubs or deletes `bootstrap.conf`.
- **Test scope:**
  - Beyond Phase 2 smoke tests, always manually verify:
    - Phase discovery/listing (after Phase 3).
    - Menu/profile selection (after Phase 2).
    - Status/config introspection (after each phase that touches config).
- **Branching:**
  - Execute on feature branches (e.g., `omniforge-bootstrap-phase1`, `omniforge-bootstrap-phase2`).
  - Commit per phase.
  - Merge to `main` only after the corresponding phase’s validation is green.
- **Env precedence:**
  - In all phases, maintain Env → omni.* precedence:
    - Env must always win over omni.* values.
    - After full cutover, `config_load` and bootstrap must reapply env overrides last.

```
