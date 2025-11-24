# OmniForge INSTALL_DIR Issue - Critical Bug Report

**Date**: 2025-11-24
**Severity**: **CRITICAL** - Configuration completely ignored
**Impact**: All files installed in wrong locations

---

## Problem Summary

OmniForge has an `INSTALL_DIR` configuration designed to support test vs production deployments. However, **all tech_stack scripts completely ignore this configuration** and install directly to the project root.

---

## Configuration Intent

### From [bootstrap.conf](bootstrap.conf):

```bash
# Line 220-234
INSTALL_TARGET="test"                     # ← Set to "test" mode
INSTALL_DIR_TEST="./test/install-1"      # ← Should install here
INSTALL_DIR_PROD="./app"                 # ← Production location

# Dynamically set INSTALL_DIR based on INSTALL_TARGET
if [[ "${INSTALL_TARGET}" == "prod" ]]; then
    INSTALL_DIR="${INSTALL_DIR_PROD}"
else
    INSTALL_DIR="${INSTALL_DIR_TEST}"    # ← Should be active
fi
```

**Expected Behavior:**
- With `INSTALL_TARGET="test"`, all files should go into `./test/install-1/`
- Directory structure: `./test/install-1/src/`, `./test/install-1/package.json`, etc.
- Safe, isolated testing environment that can be deleted

**Actual Behavior:**
- **`INSTALL_DIR` variable is defined but NEVER USED**
- All files installed directly to project root (`./src/`, `./package.json`, etc.)
- No `./test/` directory created
- No isolation between test and production deployments

---

## Evidence

### What Was Created (Actual)

```bash
# From git commit 5a4441b
./src/app/layout.tsx                 ❌ Wrong location
./src/prompts/system.ts              ❌ Wrong location
./src/lib/confidence.ts              ❌ Wrong location
./tsconfig.json                      ❌ Wrong location
./package.json                       ❌ Wrong location
./next.config.ts                     ❌ Wrong location
./docker-compose.yml                 ❌ Wrong location
... (50+ files in wrong locations)
```

### What Should Have Been Created

```bash
./test/install-1/src/app/layout.tsx     ✅ Correct location
./test/install-1/src/prompts/system.ts  ✅ Correct location
./test/install-1/src/lib/confidence.ts  ✅ Correct location
./test/install-1/tsconfig.json          ✅ Correct location
./test/install-1/package.json           ✅ Correct location
./test/install-1/next.config.ts         ✅ Correct location
./test/install-1/docker-compose.yml     ✅ Correct location
```

---

## Root Cause Analysis

### Problem 1: Scripts Use Hardcoded Relative Paths

**Example from [core/00-nextjs.sh](tech_stack/core/00-nextjs.sh:172):**

```bash
# Line 172 - Creates next.config.ts in current directory
if [[ ! -f "next.config.ts" ]]; then
    cat > next.config.ts <<'EOF'     # ❌ Hardcoded relative path
    # ... content ...
    EOF
fi

# Should be:
if [[ ! -f "${INSTALL_DIR}/next.config.ts" ]]; then
    cat > "${INSTALL_DIR}/next.config.ts" <<'EOF'
    # ... content ...
    EOF
fi
```

**Example from [core/00-nextjs.sh](tech_stack/core/00-nextjs.sh:216):**

```bash
# Line 216 - Creates src/app/layout.tsx
mkdir -p src/app                      # ❌ Hardcoded
cat > src/app/layout.tsx <<EOF        # ❌ Hardcoded

# Should be:
mkdir -p "${INSTALL_DIR}/src/app"
cat > "${INSTALL_DIR}/src/app/layout.tsx" <<EOF
```

### Problem 2: INSTALL_DIR Variable Never Exported

**From [bootstrap.conf](bootstrap.conf:229):**

```bash
# Variable is set but never exported
INSTALL_DIR="${INSTALL_DIR_TEST}"     # ← Set locally
# No: export INSTALL_DIR               # ← Never exported
```

Even if scripts tried to use `$INSTALL_DIR`, it wouldn't be available in subshells.

### Problem 3: PROJECT_ROOT Used Instead

**From [core/00-nextjs.sh](tech_stack/core/00-nextjs.sh:51-60):**

```bash
# Verify PROJECT_ROOT is set
if [[ -z "${PROJECT_ROOT:-}" ]]; then
    log_error "PROJECT_ROOT not set"
    exit 1
fi

# Verify project directory exists
if [[ ! -d "$PROJECT_ROOT" ]]; then
    mkdir -p "$PROJECT_ROOT"          # ← Always creates PROJECT_ROOT
fi
```

Scripts check for `PROJECT_ROOT` (which is `.`) but never check for or use `INSTALL_DIR`.

---

## Impact Assessment

### Files Installed in Wrong Locations

| Category | Count | Should Be In | Actually In |
|----------|-------|--------------|-------------|
| Source files | 19 | `./test/install-1/src/` | `./src/` |
| Config files | 8 | `./test/install-1/` | `./` (root) |
| Docker files | 2 | `./test/install-1/` | `./` (root) |
| Test files | 3 | `./test/install-1/e2e/` | `./e2e/` |
| **Total** | **50+** | **Isolated test dir** | **Production root** |

### Consequences

1. **❌ No Test Isolation**
   - Cannot safely test OmniForge without polluting production
   - Cannot compare multiple test configurations
   - Cannot easily delete test installations

2. **❌ Broken Configuration Contract**
   - `INSTALL_TARGET="test"` has no effect
   - Users expect configuration to be respected
   - Documentation/comments are misleading

3. **❌ Risk of Overwriting Production Files**
   - Test deployments overwrite production src/
   - No separation between environments
   - Lost work if testing over existing project

4. **❌ Impossible to Run Multiple Tests**
   - Can't test `./test/install-1/` vs `./test/install-2/`
   - Each test overwrites previous
   - No A/B comparison capability

---

## Affected Scripts

**All 94 tech_stack scripts are affected.** Sample:

```bash
_build/omniforge/tech_stack/
├── core/00-nextjs.sh              ❌ Uses hardcoded paths
├── db/drizzle-setup.sh            ❌ Uses hardcoded paths
├── ai/vercel-ai-setup.sh          ❌ Uses hardcoded paths
├── quality/eslint-prettier.sh     ❌ Uses hardcoded paths
├── export/pdf-export.sh           ❌ Uses hardcoded paths
└── ... (89 more scripts)          ❌ All use hardcoded paths
```

**Pattern in every script:**

```bash
# Hardcoded patterns found:
cat > src/...               # Should be: ${INSTALL_DIR}/src/...
cat > package.json          # Should be: ${INSTALL_DIR}/package.json
mkdir -p src/app            # Should be: ${INSTALL_DIR}/src/app
cd src/                     # Should be: cd ${INSTALL_DIR}/src/
if [[ -f "next.config.ts"   # Should be: ${INSTALL_DIR}/next.config.ts
```

---

## Fix Strategy

### Option 1: Fix All Scripts (Comprehensive)

**Approach**: Update all 94 scripts to respect `INSTALL_DIR`

**Required Changes:**

1. **Export INSTALL_DIR in bootstrap.conf:**
```bash
export INSTALL_DIR="${INSTALL_DIR_TEST}"
export INSTALL_TARGET
```

2. **Update lib/common.sh to provide helper:**
```bash
# Get target directory for file installation
function get_install_path() {
    local relative_path="$1"
    echo "${INSTALL_DIR}/${relative_path}"
}
```

3. **Update all 94 scripts to use install path:**
```bash
# Old:
cat > src/app/layout.tsx <<EOF

# New:
cat > "$(get_install_path "src/app/layout.tsx")" <<EOF
```

**Pros:**
- ✅ Fixes root cause
- ✅ Configuration works as designed
- ✅ Enables test isolation

**Cons:**
- ❌ Requires updating 94 scripts
- ❌ High risk of breaking existing deployments
- ❌ Extensive testing required

---

### Option 2: Deprecate INSTALL_DIR (Pragmatic)

**Approach**: Remove unused configuration, document current behavior

**Required Changes:**

1. **Remove INSTALL_DIR from bootstrap.conf:**
```bash
# Remove lines 220-234
# Document that OmniForge always installs to PROJECT_ROOT
```

2. **Update documentation:**
```markdown
## Installation Location

OmniForge always installs to the current project root (`PROJECT_ROOT`).

For test deployments:
1. Create a temporary directory: `mkdir -p /tmp/omniforge-test`
2. Copy OmniForge: `cp -r _build/omniforge /tmp/omniforge-test/`
3. Run from there: `cd /tmp/omniforge-test && omni --init`
```

**Pros:**
- ✅ Minimal code changes
- ✅ Honest about current behavior
- ✅ Low risk

**Cons:**
- ❌ Loses test isolation feature
- ❌ Users must manually create temp dirs
- ❌ Abandons original design intent

---

### Option 3: Hybrid - Add Test Mode Script (Recommended)

**Approach**: Keep current behavior, add wrapper for test mode

**Required Changes:**

1. **Create `_build/omniforge/bin/test-deploy.sh`:**
```bash
#!/usr/bin/env bash
# Test deployment wrapper - creates isolated test environment

set -euo pipefail

TEST_DIR="${1:-./test/install-$(date +%s)}"

log_info "Creating test environment: ${TEST_DIR}"
mkdir -p "${TEST_DIR}"

# Copy OmniForge system
cp -r _build/omniforge "${TEST_DIR}/_build/omniforge"

# Copy bootstrap configuration
cp _build/omniforge/bootstrap.conf "${TEST_DIR}/_build/omniforge/"

# Run initialization in test directory
cd "${TEST_DIR}"
./_build/omniforge/omni.sh --init

log_ok "Test deployment complete: ${TEST_DIR}"
log_info "To test: cd ${TEST_DIR} && pnpm dev"
log_info "To clean: rm -rf ${TEST_DIR}"
```

2. **Update bootstrap.conf comments:**
```bash
# NOTE: INSTALL_DIR not currently implemented in tech_stack scripts
# For test deployments, use: _build/omniforge/bin/test-deploy.sh
INSTALL_TARGET="prod"  # Currently ignored
```

**Pros:**
- ✅ Provides test isolation without breaking existing scripts
- ✅ Clear user workflow
- ✅ Low risk
- ✅ Can be enhanced later

**Cons:**
- ❌ Workaround instead of true fix
- ❌ Test deployments copy files (slower)
- ❌ Original configuration still broken

---

## Recommendation

**Implement Option 3 (Hybrid)** immediately:
1. Create `test-deploy.sh` wrapper script
2. Update bootstrap.conf comments to clarify current behavior
3. Document test workflow in OMNIFORGE.md

**Plan Option 1 (Comprehensive Fix)** for v4.0:
1. Design INSTALL_DIR architecture
2. Update scripts in phases
3. Add integration tests
4. Release as breaking change with migration guide

---

## Current State After Our Fixes

### What We Fixed Today
- ✅ TypeScript compilation errors
- ✅ Missing modules created
- ✅ Build verification added
- ✅ Auto-exclusion of backup directories

### What Still Broken
- ❌ **INSTALL_DIR completely ignored**
- ❌ **All files in wrong locations**
- ❌ **No test isolation**
- ❌ **Configuration misleading**

---

## Action Items

### Immediate (Today)
1. [ ] Create `_build/omniforge/bin/test-deploy.sh` wrapper
2. [ ] Update bootstrap.conf comments to reflect reality
3. [ ] Document actual behavior in OMNIFORGE.md
4. [ ] Add warning when INSTALL_TARGET="test"

### Short-term (This Week)
1. [ ] Test the wrapper script with multiple test deployments
2. [ ] Create cleanup script: `_build/omniforge/bin/test-cleanup.sh`
3. [ ] Add examples to documentation

### Long-term (v4.0)
1. [ ] Design proper INSTALL_DIR architecture
2. [ ] Refactor tech_stack scripts to use install paths
3. [ ] Add integration tests for both test and prod modes
4. [ ] Release with migration guide

---

## Testing the Issue

### Reproduce the Bug

```bash
cd /home/luce/apps/bloom2

# Check current configuration
grep "INSTALL_TARGET" _build/omniforge/bootstrap.conf
# Output: INSTALL_TARGET="test"

# Check if test directory exists
ls -la ./test/
# Error: No such file or directory

# Check where files actually went
ls -la ./src/
# Output: All files installed here (wrong location)
```

### Verify Our Analysis

```bash
# Count scripts using hardcoded paths
grep -r "cat > src/" _build/omniforge/tech_stack/ | wc -l
# Output: 50+ occurrences

# Check if INSTALL_DIR is ever exported
grep "export INSTALL_DIR" _build/omniforge/bootstrap.conf
# Output: (nothing - not exported)

# Check if any script uses INSTALL_DIR
grep -r "\${INSTALL_DIR}" _build/omniforge/tech_stack/
# Output: (nothing - never used)
```

---

## Conclusion

The `INSTALL_DIR` configuration in bootstrap.conf is **vestigial code** - defined but never used. All 94 tech_stack scripts install directly to `PROJECT_ROOT` using hardcoded relative paths. This is a critical design flaw that prevents test isolation and violates the configuration contract.

**Recommendation**: Implement the hybrid solution (Option 3) immediately to provide working test isolation, then plan a comprehensive fix for v4.0.

---

**Status**: 🔴 **CRITICAL BUG** - Configuration ignored, files in wrong locations
**Priority**: **HIGH** - Affects all OmniForge deployments
**Fix Complexity**: **MEDIUM** (wrapper) to **HIGH** (comprehensive)
