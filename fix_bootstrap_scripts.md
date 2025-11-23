# Fix Bootstrap Scripts - Investigation & Implementation Plan

**Status**: Analysis Complete
**Date**: 2025-11-22
**Current Location**: `/home/luce/apps/bloom2/_build/bootstrap_scripts`

---

## Executive Summary

The Bloom2 bootstrap system in `_build/bootstrap_scripts/` is **95% complete** as a v1.0 reference implementation with:

- ✅ **35 category-organized scripts** (foundation, docker, db, env, auth, ai, state, jobs, observability, ui, testing, quality)
- ✅ **bootstrap.conf.example** with comprehensive configuration template
- ✅ **lib/common.sh** with 31 utility functions covering logging, file ops, validation, git safety
- ✅ **run-bootstrap.sh** orchestrator with TECH_STACK mapping and phase-based execution
- ✅ **Documentation** (BOOTSTRAP_SETUP.md, run-bootstrap-README.md)

### Key Gaps vs. New Specification

The new specification requires migration from **v1.0 (phase-based orchestrator in _build)** to **v2.0 (config-driven system at project root)**. The required changes are:

| Feature | Current Status | Gap | Impact |
|---------|---|---|---|
| Config-driven script ordering | 🔴 Phase-based hardcoding | BOOTSTRAP_STEPS_DEFAULT exists but run-bootstrap.sh doesn't use it | Scripts run in phase order, not config order |
| State tracking & resume | 🔴 Missing entirely | No `.bootstrap_state` file, no `mark_script_success()` / `has_script_succeeded()` | Can't resume interrupted runs |
| Stack profiles | 🟡 Partial (config exists) | Not applied by common.sh | STACK_PROFILE="minimal" doesn't actually disable features |
| Interactive mode | 🔴 Missing entirely | No menu system, no script selection UI | Only CLI mode available |
| Timeouts on commands | 🔴 Missing entirely | No timeout wrapper | Long commands (pnpm install) can hang forever |
| JSON logging | 🔴 Missing entirely | Only plain text logging | CI/machine parsing impossible |
| OS detection | 🔴 Missing entirely | Common.sh has no OS_TYPE detection | Scripts can't adapt for macOS vs Linux |
| Config loading on first run | 🟡 Partial | bootstrap.conf sourcing works, but first-run prompting not implemented | User must manually create bootstrap.conf |

---

## Current Directory Structure

```
_build/bootstrap_scripts/
├── bootstrap.conf.example          ✅ Config template (196 lines)
├── BOOTSTRAP_SETUP.md              ✅ Dual-version guide (277 lines)
├── run-bootstrap.sh                ⚠️  Orchestrator (v1.0 style - 313 lines)
├── run-bootstrap-README.md         ✅ Complete v1.0 spec (579 lines)
├── lib/
│   ├── common.sh                   ⚠️  Utility library (457 lines, 31 functions)
│   └── preflight.sh                ❌ UNUSED (v2.0 file, should be removed)
├── logs/                           ✅ Execution log directory
└── tech_stack/                     ✅ 12 category directories, 35 scripts total
    ├── foundation/    (4 scripts)  ✅ Next.js init, TypeScript, package engines, dir structure
    ├── docker/        (3 scripts)  ✅ Dockerfile, docker-compose, pnpm cache
    ├── db/            (4 scripts)  ✅ Drizzle ORM, schema, migrations, client
    ├── env/           (4 scripts)  ✅ Env validation, Zod, rate limiter, server actions
    ├── auth/          (2 scripts)  ✅ Auth.js setup, auth routes
    ├── ai/            (3 scripts)  ✅ Vercel AI SDK, prompts, chat scaffold
    ├── state/         (2 scripts)  ✅ Zustand setup, session state lib (NO v2.0 files)
    ├── jobs/          (2 scripts)  ✅ PG Boss setup, worker template
    ├── observability/ (2 scripts)  ✅ Pino logger, pretty printer
    ├── ui/            (3 scripts)  ✅ shadcn/ui, react-to-print, components
    ├── testing/       (3 scripts)  ✅ Vitest, Playwright, test directory
    └── quality/       (3 scripts)  ✅ ESLint/Prettier, Husky/lint-staged, TS strict
```

---

## Configuration Analysis

### bootstrap.conf.example (196 lines)

**Coverage**: Excellent. Contains all required sections:

- ✅ Core identity & paths (APP_NAME, PROJECT_ROOT, SCRIPTS_DIR, etc.)
- ✅ Runtime versions (NODE, PNPM, NEXT, POSTGRES)
- ✅ Database config (DB_NAME, DB_USER, DB_PASSWORD, DB_PORT)
- ✅ Environment variable names (ANTHROPIC_API_KEY, AUTH_SECRET, DATABASE_URL)
- ✅ Feature flags (ENABLE_AUTHJS, ENABLE_AI_SDK, etc. - 8 flags)
- ✅ Safety & profiles (GIT_SAFETY, ALLOW_DIRTY, STACK_PROFILE, NON_INTERACTIVE, LOG_FORMAT, MAX_CMD_SECONDS, BOOTSTRAP_RESUME_MODE)
- ✅ 40+ PKG_* package version variables (organized by category)
- ✅ 5 package profile variables (AUTH_PACKAGE_PROFILE, AI_PACKAGE_PROFILE, UI_PACKAGE_PROFILE, TEST_PACKAGE_PROFILE, CODE_QUALITY_PACKAGE_PROFILE)
- ✅ BOOTSTRAP_STEPS_DEFAULT with all 35 scripts in correct order (259-295 lines)

**Missing**: Nothing critical. Config file is complete per specification.

---

## lib/common.sh Analysis (457 lines, 31 functions)

### ✅ Already Implemented

1. **Logging** (7 functions):
   - `_log()` with color support and file output
   - `log_info()`, `log_warn()`, `log_error()`, `log_debug()`, `log_step()`, `log_skip()`, `log_success()`, `log_dry()`
   - **NOTE**: Only plain text logging; NO JSON format

2. **File Operations** (5 functions):
   - `ensure_dir()` with skip detection
   - `write_file()` with force flag, dry-run support
   - `append_file()` with dry-run support
   - `add_gitkeep()` for empty directories

3. **Validation/Preflight** (6 functions):
   - `require_cmd()` - check if command exists
   - `require_node_version()` - version check with min version
   - `require_pnpm()` - pnpm check
   - `require_docker()` - Docker running check
   - `require_file()` - file existence check
   - `require_project_root()` - package.json check

4. **Config & Logging Init** (2 functions):
   - `init_logging()` - set up log file with timestamp
   - Log file auto-created in LOGS_DIR (default ./logs)

5. **Argument Parsing** (1 function):
   - `parse_common_args()` - basic arg handling (limited; doesn't set SHOW_HELP)

6. **Package.json Utilities** (3 functions):
   - `has_dependency()` - check if package in package.json
   - `add_dependency()` - install via pnpm add/add -D
   - `add_npm_script()` - modify package.json scripts
   - `update_pkg_field()` - update arbitrary package.json field

7. **Utility Functions** (5 functions):
   - `get_script_dir()` - get script directory
   - `get_project_root()` - resolve PROJECT_ROOT
   - `confirm()` - Y/N prompt
   - `run_cmd()` - execute with eval, respects DRY_RUN
   - `setup_error_trap()` / `cleanup_on_error()` - error handling

### 🔴 **Missing (Critical for v2.0)**

1. **Config Loading with First-Run Behavior**:
   - No `load_config()` or bootstrap.conf sourcing logic
   - No auto-copy of .example → .conf on first run
   - No interactive prompts for APP_NAME, PROJECT_ROOT, DB credentials (in NON_INTERACTIVE="false" mode)
   - **Impact**: Users must manually create bootstrap.conf before running any script

2. **Stack Profile Application**:
   - `apply_stack_profile()` function missing
   - Config has STACK_PROFILE="full|minimal|api-only" but it's never applied
   - Feature flags (ENABLE_*) not conditionally checked
   - **Impact**: STACK_PROFILE and ENABLE_* settings are ignored by orchestrator

3. **State Tracking & Resume**:
   - No `init_state_file()`, `mark_script_success()`, `has_script_succeeded()`
   - No .bootstrap_state file support
   - Each run starts from scratch; can't resume after interruption
   - **Impact**: If bootstrap fails at script 20/35, must manually skip first 19 or re-run from start

4. **OS Detection**:
   - No `OS_TYPE` variable set
   - Scripts can't adapt for Linux vs macOS
   - **Impact**: Cross-platform scripts may fail (sed differences, brew vs apt, etc.)

5. **Timeout-Wrapped Command Execution**:
   - `run_cmd()` exists but doesn't use MAX_CMD_SECONDS
   - No timeout wrapper; long pnpm installs can hang indefinitely
   - **Impact**: Bootstrap can hang on slow networks

6. **JSON Logging Support**:
   - Only plain text logging implemented
   - LOG_FORMAT="json" config exists but ignored
   - **Impact**: CI/monitoring systems can't parse logs

7. **Git Safety Checks**:
   - No `ensure_git_clean()` function
   - GIT_SAFETY and ALLOW_DIRTY config exists but not checked
   - **Impact**: Bootstrap could run on dirty working tree, creating conflicts

---

## run-bootstrap.sh Analysis (313 lines)

### ✅ Currently Does

- Hardcoded TECH_STACK array mapping phase ID → technology directory
- Hardcoded PHASES array with display names
- Hardcoded BREAKPOINTS=("05-ai" "09-ui")
- `list_phases()` - scans tech_stack dirs and lists all scripts
- `run_phase()` - runs all scripts in a phase/technology group
- `run_script()` - executes individual script with logging
- `run_all()` - runs all phases in sequence
- CLI parsing: `run`, `list`, `status`, `phase <name>`, `script <num>`

### 🔴 **Doesn't Do (Per New Spec)**

1. **Config-Driven Script Ordering**:
   - Hardcodes phase-based execution via PHASES and TECH_STACK arrays
   - **Should**: Read BOOTSTRAP_STEPS_DEFAULT from bootstrap.conf and execute in that order
   - **Current**: Iterates PHASES[@] which enforces phase order

2. **Interactive Menu Mode**:
   - No interactive mode when run with no arguments
   - Only CLI: `./run-bootstrap.sh [command]`
   - **Should**: Present menu for "Run all", "Run single script", "Exit"

3. **State Tracking & Resume**:
   - Doesn't check or update `.bootstrap_state`
   - No progress reporting (X/Y scripts completed)
   - No resume behavior (skip vs force)
   - **Should**: Call `has_script_succeeded()` and `mark_script_success()` per script

4. **Preflight Checks**:
   - Only calls `init_logging` and `log_info` at start
   - No `require_cmd node`, `require_cmd pnpm`, etc.
   - No Git safety check
   - **Should**: Call preflight helpers from common.sh before running scripts

5. **Help & Usage**:
   - Has `usage()` but doesn't properly parse `-h`, `--help`
   - `parse_common_args` not called

6. **Error Handling**:
   - If a script fails, does `exit 1` but doesn't distinguish which script failed
   - No rollback or cleanup

---

## Scripts Assessment (35 files, 12 categories)

### ✅ **All Scripts Exist and Are Properly Organized**

- Foundation: init-nextjs.sh, init-typescript.sh, init-package-engines.sh, init-directory-structure.sh
- Docker: dockerfile-multistage.sh, docker-compose-pg.sh, docker-pnpm-cache.sh
- DB: drizzle-setup.sh, drizzle-schema-base.sh, drizzle-migrations.sh, db-client-index.sh
- Env: env-validation.sh, zod-schemas-base.sh, rate-limiter.sh, server-action-template.sh
- Auth: authjs-setup.sh, auth-routes.sh
- AI: vercel-ai-setup.sh, prompts-structure.sh, chat-feature-scaffold.sh
- State: zustand-setup.sh, session-state-lib.sh (✅ NO v2.0 files like checkpoint.sh)
- Jobs: pgboss-setup.sh, job-worker-template.sh
- Observability: pino-logger.sh, pino-pretty-dev.sh
- UI: shadcn-init.sh, react-to-print.sh, components-structure.sh
- Testing: vitest-setup.sh, playwright-setup.sh, test-directory.sh
- Quality: eslint-prettier.sh, husky-lintstaged.sh, ts-strict-mode.sh

### Script Pattern Analysis

**Sample: foundation/init-nextjs.sh** (70 lines)
- ✅ Sets SCRIPT_KEY="foundation/init-nextjs.sh"
- ✅ Sources common.sh with error check
- ✅ Defines usage()
- ✅ Calls parse_common_args and honors SHOW_HELP, DRY_RUN
- ✅ Uses run_cmd() for pnpm operations
- ✅ Uses PKG_* variables from config
- ✅ Is idempotent (checks if already initialized)
- ✅ Calls mark_script_success at end
- ⚠️ **BUT**: mark_script_success() doesn't exist in common.sh yet

### 🔴 **Critical Issue**: Scripts Call `mark_script_success()` But Function Doesn't Exist

```bash
# In scripts/bootstrap/foundation/init-nextjs.sh (line 70):
mark_script_success "foundation/init-nextjs.sh"

# In lib/common.sh:
# ❌ Function not defined!
```

This means:
- All 35 scripts will FAIL at the end because they call a non-existent function
- Bootstrap will exit with error from every single script
- Resume/state tracking completely broken

---

## Environment & Ignore File Management

### ✅ **Currently Implemented**

1. **foundation/init-nextjs.sh**:
   - Creates .gitignore with node_modules, .next, .env, .env.local, .env.*.local
   - Creates .env.example with placeholder APP_NAME
   - Creates .env.local as empty/placeholder

2. **docker/dockerfile-multistage.sh**:
   - Creates .dockerignore with Node/Next patterns, .env files

### ⚠️ **Gaps**

1. **env-validation.sh** should:
   - Ensure .env.example includes ENV_ANTHROPIC_API_KEY, ENV_AUTH_SECRET, ENV_DATABASE_URL (from bootstrap.conf)
   - Sync env variable NAMES from bootstrap.conf into .env.example (not values)

2. **.claudeignore** not created anywhere:
   - Should be created by observability/pino-logger.sh or quality/ script
   - Should include: node_modules/, .next/, .turbo/, dist/, logs/, .git/, .env, .env.*, coverage/

3. **.env.local** management:
   - Should be kept out of git (✅ in .gitignore)
   - Should be auto-created if missing (✅ foundation/init-nextjs.sh does this)

---

## Package Version Coverage

### ✅ **40+ PKG_* Variables Defined**

All major packages covered with version specs:
- Core: next@15, react@19, typescript@5
- DB: drizzle-orm, postgres, tsx, drizzle-kit
- Auth: next-auth@beta, bcryptjs
- AI: ai, @ai-sdk/anthropic
- State: zustand, immer
- UI: tailwindcss, react-to-print, clsx, tailwind-merge
- Jobs: pg-boss
- Observability: pino, pino-pretty
- Validation: zod, @t3-oss/env-nextjs
- Testing: vitest, @vitejs/plugin-react, @playwright/test, jsdom, @testing-library/react
- Quality: eslint, prettier, husky, lint-staged, eslint-config-prettier, eslint-plugin-jsx-a11y

### 🔴 **Missing shadcn/ui Package**

shadcn/ui is installed via CLI (npx shadcn-ui@latest init), not via pnpm add.
- ✅ ui/shadcn-init.sh handles this
- But no PKG_SHADCN_CLI variable (though that's correct since it's installed globally/one-shot)

---

## Implementation Priority

### **CRITICAL (Bootstrap will fail without these)**

1. **Add `mark_script_success()` and `has_script_succeeded()` to common.sh**
   - All 35 scripts call `mark_script_success()` at the end
   - Currently crashes with "command not found"
   - **Effort**: ~15 minutes

2. **Add `apply_stack_profile()` to common.sh**
   - Converts STACK_PROFILE (minimal/api-only/full) into ENABLE_* overrides
   - Called once after sourcing bootstrap.conf
   - **Effort**: ~10 minutes

3. **Update `run_cmd()` to respect MAX_CMD_SECONDS timeout**
   - Wrap commands with `timeout` utility if available
   - Log timeout events
   - **Effort**: ~15 minutes

### **HIGH (Bootstrap works but is fragile)**

4. **Add config loading logic to common.sh**
   - Auto-copy bootstrap.conf.example → bootstrap.conf on first run
   - Optional interactive prompt for APP_NAME, PROJECT_ROOT, DB_* vars in NON_INTERACTIVE="false" mode
   - Validate critical values (fail if still "change_me")
   - **Effort**: ~30 minutes

5. **Add `ensure_git_clean()` to common.sh**
   - Check GIT_SAFETY and ALLOW_DIRTY flags
   - Exit with error if working tree dirty and GIT_SAFETY=true
   - **Effort**: ~10 minutes

6. **Update run-bootstrap.sh to use BOOTSTRAP_STEPS_DEFAULT**
   - Read script list from config instead of hardcoded PHASES
   - Execute scripts in config-defined order
   - **Effort**: ~20 minutes

7. **Add state tracking & resume to run-bootstrap.sh**
   - Check BOOTSTRAP_RESUME_MODE before running each script
   - Report progress (X/Y completed)
   - Skip already-completed scripts if resume=skip
   - **Effort**: ~25 minutes

### **MEDIUM (Better experience)**

8. **Add interactive menu mode to run-bootstrap.sh**
   - Present menu when no arguments given
   - "Run all", "Run specific scripts", "View progress", "Exit"
   - **Effort**: ~30 minutes

9. **Add JSON logging support to common.sh**
   - Detect LOG_FORMAT="json" and output structured logs
   - Include timestamp, level, script name, message
   - **Effort**: ~20 minutes

10. **Add OS detection to common.sh**
    - Set OS_TYPE="linux"|"darwin"|"windows"
    - Scripts can query this for platform-specific behavior
    - **Effort**: ~10 minutes

11. **Remove lib/preflight.sh** (unused v2.0 file)
    - **Effort**: ~5 minutes (1 rm command)

### **LOW (Nice to have)**

12. **Add `check_tool_versions()`** - best-effort version checks
13. **Improve parse_common_args()** - currently doesn't set SHOW_HELP properly
14. **Add rollback support** - optional recovery from partial runs

---

## Summary of What Needs to Happen Locally

### Phase 1: Fix Common.sh (Critical Functions)

```bash
# Add these functions to lib/common.sh:
- mark_script_success() - append "{script}=success:$(date)" to .bootstrap_state
- has_script_succeeded() - grep for "{script}=success" in .bootstrap_state
- init_state_file() - create .bootstrap_state if missing
- apply_stack_profile() - override ENABLE_* based on STACK_PROFILE
- ensure_git_clean() - check GIT_SAFETY, ALLOW_DIRTY, git status
- Update run_cmd() to use MAX_CMD_SECONDS with timeout wrapper
- Add OS detection (OS_TYPE variable)
- Add load_config() - bootstrap.conf loading with first-run behavior
- Add JSON logging variants (_log_json)
```

### Phase 2: Update run-bootstrap.sh

```bash
# Modify run-bootstrap.sh to:
- Call load_config() and apply_stack_profile() at start
- Call ensure_git_clean() before any scripts run
- Replace hardcoded PHASES iteration with BOOTSTRAP_STEPS_DEFAULT array
- Add state tracking (has_script_succeeded before run, mark_script_success after)
- Add progress reporting (X/Y completed)
- Add interactive menu mode
- Honor BOOTSTRAP_RESUME_MODE (skip vs force)
```

### Phase 3: Cleanup

```bash
# Remove unused/v2.0-only files:
- lib/preflight.sh (v2.0 only, run-bootstrap.sh doesn't source it)
```

### Phase 4: Validation

```bash
# Test locally:
- ./run-bootstrap.sh --help
- ./run-bootstrap.sh -n --all (dry-run)
- Check that .bootstrap_state is created/updated
- Check progress reporting
- Verify timeouts work on slow commands
```

---

## Notes for Implementation

1. **All 35 scripts already exist and are well-structured** - no need to regenerate them
2. **bootstrap.conf.example is complete** - no changes needed
3. **Main work is in lib/common.sh** (add ~200-300 lines of new functions)
4. **run-bootstrap.sh needs refactoring** (~30-50 lines changed, same size overall)
5. **Scripts will immediately work once mark_script_success() is added**
6. **Testing can be done with `./run-bootstrap.sh -n --all` (dry-run mode)**

---

## File Sizes (Current)

| File | Lines | Status |
|------|-------|--------|
| bootstrap.conf.example | 196 | ✅ Complete |
| lib/common.sh | 457 | ⚠️ Needs +200 lines |
| run-bootstrap.sh | 313 | ⚠️ Needs ~30 line refactor |
| All 35 scripts | ~2,500 total | ✅ Complete |
| run-bootstrap-README.md | 579 | ✅ Reference documentation |
| BOOTSTRAP_SETUP.md | 277 | ✅ Setup guide |
| **Total** | **~4,300 lines** | **~95% done** |

---

## Success Criteria

After implementing fixes locally, verify:

- [ ] `./run-bootstrap.sh --help` shows correct usage
- [ ] `./run-bootstrap.sh -n --all` completes without errors (dry-run)
- [ ] `.bootstrap_state` is created and updated with each script completion
- [ ] Progress shown as "Running X/Y: foundation/init-nextjs.sh"
- [ ] Timeout kicks in if pnpm install takes > MAX_CMD_SECONDS
- [ ] `STACK_PROFILE="minimal"` actually disables non-essential scripts
- [ ] `GIT_SAFETY="true"` prevents running on dirty working tree
- [ ] Interactive menu appears when run with no arguments
- [ ] Resume works: if script 15 fails, can run again and skip 1-14
- [ ] All 35 scripts call mark_script_success and complete successfully
