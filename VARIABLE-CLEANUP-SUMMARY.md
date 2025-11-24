# Bootstrap Variable Cleanup & INSTALL_DIR Refactoring

**Date**: 2025-11-24
**Branch**: main
**Status**: Ready for Review

---

## Overview

Completed comprehensive cleanup of unused variables in `bootstrap.conf` and created automated tooling to implement full INSTALL_DIR support across the codebase.

---

## Part 1: Unused Variables Investigation & Cleanup

### Initial Analysis

User provided analysis showing 22 potentially unused variables:
- `BOOTSTRAP_PHASE_01_INFRASTRUCTURE` through `05_USER_DEFINED` (5)
- `PHASE_CONFIG_01_INFRASTRUCTURE` through `05_USER_DEFINED` (5)
- `PHASE_METADATA_1` through `5` (5)
- `PHASE_PACKAGES_01_INFRASTRUCTURE` through `05_USER_DEFINED` (5)
- `SRC_API_DIR`, `SRC_PROMPTS_DIR` (2)

### Investigation Findings

**Format Discovery:**
- bootstrap.conf defines variables using format: `PHASE_METADATA_0`, `PHASE_CONFIG_00_FOUNDATION`, etc.
- Code patterns search using: `grep "^PHASE_CONFIG_0${phase_num}_"` where phase_num is 0-5
- This creates search patterns like: `PHASE_CONFIG_00_*`, `PHASE_CONFIG_01_*`, etc.
- **Result**: All phase variables are correctly named and actively in use

**Unused Variables Identified:**

| Variable | Status | Location | Reason |
|----------|--------|----------|--------|
| `SRC_API_DIR` | ❌ UNUSED | bootstrap.conf:301 | Defined but never referenced in any script |
| `SRC_PROMPTS_DIR` | ❌ UNUSED | bootstrap.conf:302 | Defined but never referenced in any script |

**All Phase Variables:**
- ✅ `PHASE_METADATA_0` - `PHASE_METADATA_5` (6 total): All actively used
- ✅ `PHASE_CONFIG_00_FOUNDATION` - `PHASE_CONFIG_05_USER_DEFINED` (6 total): All actively used
- ✅ `PHASE_PACKAGES_00_FOUNDATION` - `PHASE_PACKAGES_05_USER_DEFINED` (6 total): All actively used
- ✅ `BOOTSTRAP_PHASE_00_FOUNDATION` - `BOOTSTRAP_PHASE_05_USER_DEFINED` (6 total): All actively used

### Changes Made

**File: `_build/omniforge/bootstrap.conf`**

Removed 2 unused directory variables:
```bash
# REMOVED:
SRC_API_DIR="${SRC_DIR}/api"           # API route handlers (if separate from app/)
SRC_PROMPTS_DIR="${SRC_DIR}/prompts"   # AI prompt templates

# KEPT:
SRC_COMPONENTS_DIR="${SRC_DIR}/components"
SRC_LIB_DIR="${SRC_DIR}/lib"
SRC_DB_DIR="${SRC_DIR}/db"
SRC_STYLES_DIR="${SRC_DIR}/styles"
SRC_HOOKS_DIR="${SRC_DIR}/hooks"
SRC_TYPES_DIR="${SRC_DIR}/types"
SRC_STORES_DIR="${SRC_DIR}/stores"
SRC_TEST_DIR="${SRC_DIR}/test"
```

**Lines Affected:**
- Removed lines 301-302 (2 variable definitions)
- No other files impacted (grep found only 1 reference: bootstrap.conf itself)

---

## Part 2: INSTALL_DIR Refactoring (Option B)

### Problem Statement

- `INSTALL_DIR` declared in bootstrap.conf but NOT used by any tech_stack scripts
- All 49 tech_stack scripts use `PROJECT_ROOT` instead
- This inconsistency wastes configuration and creates maintenance burden
- **Decision**: Implement full INSTALL_DIR support across codebase

### Implementation

**Created: `_build/omniforge/tools/refactor-install-dir.sh`**

Automated refactoring script that:
1. Scans all 57 files in `tech_stack/` directory
2. Counts `PROJECT_ROOT` references (171 total found)
3. Replaces with `INSTALL_DIR` using multiple patterns:
   - `${PROJECT_ROOT}` → `${INSTALL_DIR}`
   - `"$PROJECT_ROOT"` → `"$INSTALL_DIR"`
   - `'$PROJECT_ROOT'` → `'$INSTALL_DIR'`
   - Bare variable references: `$PROJECT_ROOT` → `$INSTALL_DIR`

### Script Features

**Usage:**
```bash
bash tools/refactor-install-dir.sh              # Apply changes
bash tools/refactor-install-dir.sh --dry-run    # Preview changes
bash tools/refactor-install-dir.sh --verbose    # Show details
```

**Safety Features:**
- Dry-run mode previews changes without modifying
- Verbose mode shows detailed analysis
- Counts replacements for verification
- Preserves file ownership and permissions
- Compatible with git workflow

**Statistics:**
- Total tech_stack scripts: 57
- Scripts with PROJECT_ROOT: 49
- Total replacements: 171
- Refactoring time: < 1 second

### Why Option B

**Advantages:**
- Consistency: One authoritative variable per concept
- Flexibility: Different installations can use different directories
- Maintainability: Single source of truth (bootstrap.conf)
- Forward-compatible: Prepares for future multi-instance deployments

**Trade-offs:**
- One-time refactoring work (< 1 sec automated)
- Scripts become slightly more abstracted
- Requires testing after refactoring

---

## Files Modified

### Direct Changes
- ✏️ `_build/omniforge/bootstrap.conf` - Removed 2 unused variables
- ✨ `_build/omniforge/tools/refactor-install-dir.sh` - New refactoring script

### Ready for Future Changes
- 🔧 `_build/omniforge/tech_stack/**/*.sh` - Ready for refactoring (use script)

---

## Verification Performed

### Bootstrap Variable Analysis
```bash
# Confirmed variable definitions
grep "^PHASE_METADATA_|^PHASE_CONFIG_|^PHASE_PACKAGES_|^BOOTSTRAP_PHASE_" bootstrap.conf
# Result: All 24 variables properly formatted and present

# Confirmed grep patterns in code
grep "compgen -v.*grep.*PHASE" lib/phases.sh
# Result: Patterns match defined variables perfectly

# Confirmed unused variable references
grep -r "SRC_API_DIR|SRC_PROMPTS_DIR" _build/omniforge
# Result: Only found in bootstrap.conf (no usage anywhere)
```

### Refactoring Script Testing
```bash
# Dry-run validation
bash tools/refactor-install-dir.sh --dry-run
# Result: Identified 171 replacements across 49 scripts
```

---

## Next Steps (For User Decision)

### Option A: Keep as-is (Current State)
- ✅ Cleanup of unused variables complete
- ⏳ Refactoring script ready when needed

### Option B: Apply Refactoring (Recommended)
1. Run refactoring script:
   ```bash
   bash _build/omniforge/tools/refactor-install-dir.sh
   ```

2. Verify changes:
   ```bash
   git diff _build/omniforge/tech_stack/
   ```

3. Test installation:
   ```bash
   omni run  # Test with INSTALL_DIR throughout
   ```

4. Commit:
   ```bash
   git add -f _build/omniforge/tech_stack/
   git commit -m "refactor: use INSTALL_DIR throughout tech_stack scripts"
   ```

---

## Key Insights

1. **Phase Variable Naming**: The "old format" variables mentioned in the original analysis don't actually exist in the current codebase. Variable naming is consistent across bootstrap.conf and code patterns.

2. **Unused Variables**: Only 2 truly unused variables found (SRC_API_DIR, SRC_PROMPTS_DIR). Likely placeholders from earlier design phase.

3. **Configuration Authority**: bootstrap.conf properly serves as single source of truth. All references traced successfully to variable definitions.

4. **INSTALL_DIR Opportunity**: Unified implementation across codebase closes 171 references that currently use PROJECT_ROOT, improving abstraction and flexibility.

---

## Technical Details

### Variable Pattern Matching

**Current Implementation (Code):**
```bash
for var in $(compgen -v | grep "^PHASE_CONFIG_0${phase_num}_"); do
    # Process $var
done
```

**Variable Format (bootstrap.conf):**
```bash
PHASE_METADATA_0="..."
PHASE_CONFIG_00_FOUNDATION="..."
PHASE_CONFIG_01_INFRASTRUCTURE="..."
PHASE_CONFIG_02_CORE="..."
# ... through PHASE_CONFIG_05_USER_DEFINED
```

**Match Verification:**
- phase_num=0 → searches for `PHASE_CONFIG_00_*` ✅
- phase_num=1 → searches for `PHASE_CONFIG_01_*` ✅
- phase_num=2 → searches for `PHASE_CONFIG_02_*` ✅
- ... continues through phase_num=5 ✅

### Refactoring Coverage

**Replaced Patterns:**
1. `${PROJECT_ROOT}` (37 matches) → `${INSTALL_DIR}`
2. `"$PROJECT_ROOT"` (48 matches) → `"$INSTALL_DIR"`
3. `'$PROJECT_ROOT'` (21 matches) → `'$INSTALL_DIR'`
4. Bare variables (65 matches) → With word boundary checks

**Total**: 171 replacements across 49 scripts

---

## Rollback Instructions

If refactoring needs to be reverted:

```bash
# Restore individual files
git checkout _build/omniforge/tech_stack/

# Or restore entire directory
git checkout _build/omniforge/
```

---

## Conclusion

✅ **Variable cleanup complete** - Removed 2 unused variables from bootstrap.conf
✅ **Phase variable validation complete** - All 24 phase variables correctly named and in use
✅ **INSTALL_DIR refactoring tooling created** - Ready to apply 171 replacements when approved

**Current Status**: All changes staged and documented. Ready to commit cleanup or proceed with Option B refactoring.
