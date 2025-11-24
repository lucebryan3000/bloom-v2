# Path Resolution Analysis - INSTALL_DIR vs PROJECT_ROOT

**Date**: 2025-11-24
**Status**: Investigation & Remediation Plan
**Codex Analysis**: Dry-run validation pending

---

## Problem Statement

The bootstrap.conf declares INSTALL_DIR configuration (test/prod paths), but **no tech_stack scripts actually use INSTALL_DIR**. All scripts implicitly use PROJECT_ROOT, creating a mismatch between declared and actual behavior.

### Current Configuration
```bash
# bootstrap.conf
INSTALL_DIR_TEST="./test/install-1"
INSTALL_DIR_PROD="./app"
INSTALL_TARGET="prod"  # determines which INSTALL_DIR is used

# Runtime result:
INSTALL_DIR="./app"  # or "./test/install-1" based on target
```

### Actual Execution
```bash
# All tech_stack scripts use:
cd "$PROJECT_ROOT"
mkdir package.json    # Creates in PROJECT_ROOT, NOT INSTALL_DIR
npm install          # Installs to PROJECT_ROOT
```

---

## Analysis: Where INSTALL_DIR is (NOT) Used

### In bootstrap.conf
✅ **Declared**: Lines define INSTALL_DIR_TEST, INSTALL_DIR_PROD, INSTALL_TARGET
❌ **Never Referenced**: No scripts source or use INSTALL_DIR after it's set

### In tech_stack scripts (94 scripts)
❌ **Zero References**: grep -r "INSTALL_DIR" returns 0 matches
✅ **All use PROJECT_ROOT**: Scripts derive PROJECT_ROOT from SCRIPT_DIR paths

### In lib/ (validation, phases, downloads, etc.)
❌ **No References**: INSTALL_DIR not used in preflight checks or package management
✅ **Uses PROJECT_ROOT**: All file operations target PROJECT_ROOT

### In bin/ entry points
❌ **No References**: omni.sh, reset, forge, status don't use INSTALL_DIR

---

## Current Preflight Check Behavior

**Phase preflight_check() in lib/phases.sh (line 540)**
- ✅ Checks dependencies (node, pnpm, docker, etc.)
- ❌ **Only logs status** - does NOT attempt installation
- ❌ **Doesn't remediate**: Missing pnpm, node, etc. are reported as warnings/errors
- ❌ **No fallback**: If pnpm missing, preflight continues anyway

**Impact**:
- Users running dry-run see what WOULD fail, but can't run actual deployment
- Missing dependencies block real execution but aren't auto-installed
- No guidance on how to fix missing dependencies

---

## Solution: Three-Part Patch

### Part 1: Fix INSTALL_DIR Usage
**Goal**: Make tech_stack scripts respect INSTALL_DIR configuration

**Option A (Recommended)**: Accept PROJECT_ROOT as authoritative
- Remove INSTALL_DIR from bootstrap.conf
- All deployments go to PROJECT_ROOT (simpler)
- Update documentation

**Option B (Complex)**: Implement full INSTALL_DIR support
- Export INSTALL_DIR to all scripts
- Modify 94 tech_stack scripts to use `$INSTALL_DIR` instead of `$PROJECT_ROOT`
- Add validation that INSTALL_DIR != PROJECT_ROOT for safety
- Breaking change - all paths change

### Part 2: Enhanced Preflight Check
**Goal**: Auto-remediate missing dependencies during preflight

```bash
preflight_remediate_dependencies() {
    # If pnpm missing: install pnpm
    # If node wrong version: offer nvm install
    # If docker missing: guide to docker desktop
    # Download missing packages to cache
}
```

**Changes needed**:
- lib/phases.sh: Add remediation logic
- lib/validation.sh: Add install functions
- bootstrap.conf: Set remediation flags

### Part 3: bootstrap.conf as Source of Truth
**Goal**: All configuration centralized in bootstrap.conf

**Current gaps**:
- INSTALL_DIR configured but unused
- Preflight flags not configurable
- No remediation settings
- Missing dependency handling hardcoded

**Additions needed**:
```bash
# Preflight behavior
PREFLIGHT_REMEDIATE="true"     # Auto-fix missing dependencies
PREFLIGHT_SKIP_MISSING="false" # Fail if critical missing
PREFLIGHT_DOWNLOAD_PACKAGES="true" # Pre-download to cache

# Dependency installation
AUTO_INSTALL_PNPM="true"
AUTO_INSTALL_NODE_VERSION="20"
ALLOW_NODE_VERSION_MANAGER="nvm"  # nvm|asdf|fnm
```

---

## Recommended Path Forward

### Immediate (Easy Patch)
1. **Option A: Use PROJECT_ROOT Only**
   - Remove INSTALL_DIR from bootstrap.conf
   - Simplify documentation
   - No script changes needed
   - ~30 minutes work

2. **OR add preflight remediation**
   - Auto-detect missing pnpm
   - Call install function if missing
   - Download packages to cache before phase execution
   - ~1 hour work

### Short-term (bootstrap.conf Authority)
1. Add remediation flags to bootstrap.conf
2. Update phase_preflight_check() to read remediation flags
3. Add functions for auto-installing pnpm, node, docker
4. Log remediation actions clearly

### Long-term (Full INSTALL_DIR Support)
- Only if use case demands separate install directories
- Currently no evidence of need (test/prod are same structure)
- Would require 94 script modifications

---

## Testing Plan

### Dry-Run Validation (Using Codex)
```bash
# In container with missing pnpm
cd /app && omni run --dry-run

# Expected output:
# [WARN] pnpm not found - required for Phase 1
# [INFO] Would install pnpm with: npm install -g pnpm
# [INFO] Would continue with Phase 0...
```

### Integration Testing
```bash
# Test 1: Missing pnpm (remediate)
docker run --rm node:20-alpine sh -c "omni run --dry-run"
# Should: Detect missing pnpm, log remediation, continue

# Test 2: Missing node version
docker run --rm node:18-alpine sh -c "omni run --dry-run"
# Should: Warn node version mismatch

# Test 3: With remediation enabled
PREFLIGHT_REMEDIATE=true omni run --dry-run
# Should: Auto-install missing, download packages
```

---

## Decision Required

**What should we do?**

1. **Option A**: Remove INSTALL_DIR, use PROJECT_ROOT only (recommended)
2. **Option B**: Add preflight remediation to install missing dependencies
3. **Option C**: Full INSTALL_DIR implementation
4. **Option D**: All three (full solution)

**Quick wins available**:
- Preflight remediation: 1 hour, immediate value
- bootstrap.conf cleanup: 30 minutes, improve clarity
- Dry-run validation with Codex: 30 minutes, verify behavior

---

## Files to Modify

| File | Change | Impact |
|------|--------|--------|
| lib/phases.sh | Add remediation logic | ~50 lines |
| lib/validation.sh | Add install functions | ~80 lines |
| bootstrap.conf | Add config flags | ~10 lines |
| OMNIFORGE.md | Document preflight behavior | ~20 lines |
| (94 scripts) | Only if full INSTALL_DIR | Major refactor |

---

**Next Step**: Run dry-run test with Codex to confirm path resolution behavior, then implement remediation patch.
