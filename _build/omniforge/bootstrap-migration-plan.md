
````text
You are acting as a senior bash/DevOps engineer and systems architect working on the OmniForge bootstrap cutover.

## Objective

Retire `bootstrap.conf` as a runtime config source and make omni-based config files canonical:

- `omni.config` – Section 1 (Quick Start) + other top-level settings.
- `omni.profiles.sh` – PROFILE_* arrays + AVAILABLE_PROFILES.
- `omni.phases.sh` – PHASE metadata (PHASE_METADATA_*, PHASE_CONFIG_*, PHASE_PACKAGES_*, BOOTSTRAP_PHASE_*).
- Optionally `omni.settings.sh` – advanced/system settings (paths, flags, versions, etc).

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
Work happens on a feature branch, then we merge to `main` after all phases are done and validated.

---

## Phase 0 – Inventory & Mapping (Prep only)

**Goal:** Understand exactly how `bootstrap.conf` is used today, broken down by domain.

**Scope:** READ-ONLY inspection. No code changes.

Tasks:

- From repo root:

  ```bash
  rg "bootstrap.conf" _build/omniforge
  rg "BOOTSTRAP_CONF" _build/omniforge
````

* Classify usages into domains:

  * **Section 1 defaults:** APP_*, INSTALL_TARGET, STACK_PROFILE, DB_*, ENABLE_*.
  * **Profile data:** PROFILE_* arrays, AVAILABLE_PROFILES.
  * **Phase metadata:** PHASE_METADATA_*, PHASE_CONFIG_*, PHASE_PACKAGES_*, BOOTSTRAP_PHASE_*.
  * **Advanced/system settings:** PROJECT_ROOT, path vars, safety flags, versions, etc.

* Record which files consume these (e.g., `lib/bootstrap.sh`, `lib/config_bootstrap.sh`, `lib/phases.sh`, `lib/menu.sh`, `bin/status`, etc.).

When we ask you to run **Phase 0**, you will:

* Only inspect and summarize; NO edits.
* Report the mapping.

---

## Phase 1 – Section 1 Cutover to `omni.config` (Config-only loader)

**Goal:** Make **Section 1** (APP_*, INSTALL_TARGET, STACK_PROFILE, DB_*, ENABLE_*) live entirely in `omni.config`, not `bootstrap.conf`. After Phase 1:

* Section 1 values are sourced from: Env → `omni.config`.
* `bootstrap.conf` can still hold those values for now, but they are not used by runtime/introspection.

**Files allowed to change:**

* `_build/omniforge/omni.config`
* `_build/omniforge/lib/bootstrap.sh`
* `_build/omniforge/lib/config_bootstrap.sh` (config_load / status --config)

**Tasks:**

1. Ensure `omni.config` has a complete Section 1:

   * Copy Section 1 defaults from `bootstrap.conf` into `omni.config` (if anything is missing).
   * Keep values identical.

2. Update `lib/bootstrap.sh`:

   * Ensure Section 1 vars are set from `omni.config` (plus env), not from `bootstrap.conf`.
   * `bootstrap.conf` should no longer be a Section 1 source.

3. Update `lib/config_bootstrap.sh`:

   * `config_load` should read Section 1 from env → `omni.config`.
   * It should NOT rely on `bootstrap.conf` for Section 1 anymore.

4. Validation:

   * `bash -n` on changed files.
   * From `_build/omniforge`: `./tools/omniforge_refactor.sh phase2`.
   * Manual:

     ```bash
     ./omni.sh status
     ./bin/status --config
     APP_NAME="EnvOverride" ./bin/status --config
     # Optionally tweak APP_NAME in omni.config and re-run ./bin/status --config
     ```

**Success criteria:**

* Env override wins over omni.config.
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

**Files allowed to change:**

* `_build/omniforge/omni.profiles.sh` (new file)
* `_build/omniforge/lib/bootstrap.sh`
* `_build/omniforge/lib/menu.sh`
* `_build/omniforge/lib/config_bootstrap.sh` (if needed for profile logic)

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

4. If `config_apply_profile` (or similar) in `lib/config_bootstrap.sh` needs array-based profiles:

   * Ensure it uses data that’s already loaded from `omni.profiles.sh`.

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

* `_build/omniforge/omni.phases.sh` (new file)
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

4. Validation:

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

## Phase 4 – Sweep remaining settings & Remove `bootstrap.conf`

**Goal:** Move remaining runtime settings off `bootstrap.conf`, stop sourcing it entirely, and mark omni.* as canonical.

**Files allowed to change:**

* `_build/omniforge/omni.settings.sh` (optional; or reuse `omni.config`)
* `_build/omniforge/lib/bootstrap.sh`
* `_build/omniforge/lib/config_bootstrap.sh`
* Any file still sourcing `bootstrap.conf` / `BOOTSTRAP_CONF`.
* `_build/omniforge/bootstrap.conf`
* `_build/omniforge/OMNIFORGE.md`

**Tasks:**

1. Find remaining references:

   ```bash
   rg "bootstrap.conf" _build/omniforge
   rg "BOOTSTRAP_CONF" _build/omniforge
   ```

2. For each runtime use (not comments) that still depends on `bootstrap.conf` for real settings:

   * Create `_build/omniforge/omni.settings.sh` (or fold into `omni.config`) and move those settings there.
   * Update loaders/consumers to read from omni files instead of `bootstrap.conf`.

3. Ensure:

   * `lib/bootstrap.sh` no longer sources `bootstrap.conf` at all.
   * `lib/config_bootstrap.sh` doesn’t source it either.
   * No other file sources `bootstrap.conf` for anything.

4. Turn `_build/omniforge/bootstrap.conf` into:

   * A stub with a deprecation comment, OR
   * Delete it entirely if you’re sure nothing external depends on it.

5. Update `OMNIFORGE.md`:

   * Mark `bootstrap.conf` as legacy/removed.
   * Document `omni.config`, `omni.profiles.sh`, `omni.phases.sh`, and any `omni.settings.sh` as canonical config sources.

6. Validation:

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
* Omni config files are the only config sources.
* Docs reflect this.
* Phase 2 and manual flows are green.

---

## Alignment items (pre-execution)
- Data targets: **Decision: Option A**. Use `omni.settings.sh` for all non–Section 1 settings and derived values (PROJECT_ROOT, paths, safety flags, logging/docker/tool settings, versions, env var names, derived values like INSTALL_DIR/markers). Keep `omni.config` as Section 1 only.
- Fallback stance: **Decision: Option A**. Allow WARN fallback to `bootstrap.conf` in Phases 1/2 if omni.* is incomplete; remove fallback/hard-fail in Phase 4.
- Test scope: beyond Phase 2 smoke, add manual checks for phase discovery/listing and menu/profile selection.
- Branching: execute on a feature branch (e.g., `omniforge-bootstrap-phase1`), commit per phase, merge to main only after Phase 4 validation.
- Handling `common.sh` BOOTSTRAP_CONF/BOOTSTRAP_CONF_EXAMPLE in the omni-only state:
  - **Recommended:** Mark as legacy refs only; ensure runtime does not use them. Remove/ignore in code once omni-only; keep docs for history.
