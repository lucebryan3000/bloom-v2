# Reset Deployment & Enhance OmniForge Plan

**Date**: 2025-11-24
**Status**: Ready to Execute
**Goal**: Reset deployment while preserving OmniForge improvements, then add `omni --reset` command

---

## Phase 1: Safe Reset Execution

### 1.1 Pre-Reset Backup
Create backup of all OmniForge improvements and manual fixes:

```bash
# Backup directory structure
_backup/
├── manual-fixes/           # Files we manually created to fix build
│   ├── confidence.ts
│   ├── sessionState.ts
│   └── narrative.ts
└── omniforge-enhancements/ # Enhanced OmniForge scripts
    ├── init-typescript.sh
    ├── verify-build.sh
    ├── test-deploy.sh
    ├── test-cleanup.sh
    └── bootstrap.conf
```

### 1.2 Files to Delete (28 files from commit 5a4441b)

**Root Configuration Files (7)**:
- `docker-compose.yml`
- `drizzle.config.ts`
- `next.config.ts`
- `package.json`
- `playwright.config.ts`
- `tsconfig.json`
- `vitest.config.ts`

**Source Directory (19 files)**:
- Entire `src/` directory tree

**Test Files (1)**:
- `e2e/home.spec.ts`

**Public Directory (1)**:
- `public/.gitkeep`

**Generated/Build Artifacts**:
- `.bootstrap_state` (will be regenerated)
- `node_modules/` (will be reinstalled)
- `pnpm-lock.yaml` (will be regenerated)
- `.next/` (build cache)
- `tsconfig.tsbuildinfo`
- `next-env.d.ts`
- `logs/` (build logs)

### 1.3 Files to Preserve (OmniForge Improvements)

**Enhanced Scripts**:
- ✅ `_build/omniforge/tech_stack/foundation/init-typescript.sh` (auto-exclusions)
- ✅ `_build/omniforge/tech_stack/quality/verify-build.sh` (NEW)
- ✅ `_build/omniforge/bootstrap.conf` (added verify-build.sh)
- ✅ `_build/omniforge/bin/test-deploy.sh` (NEW)
- ✅ `_build/omniforge/bin/test-cleanup.sh` (NEW)

**Documentation**:
- ✅ `_build/omniforge/DEPLOYMENT-FIXES.md` (NEW)
- ✅ `_build/omniforge/INSTALL-DIR-ISSUE.md` (NEW)
- ✅ `_build/omniforge/RESET-DEPLOYMENT.md` (NEW)

### 1.4 Reset Execution Script

```bash
#!/usr/bin/env bash
# Automated reset preserving OmniForge improvements

set -euo pipefail

PROJECT_ROOT="/home/luce/apps/bloom2"
cd "$PROJECT_ROOT"

echo "🗑️  Resetting OmniForge deployment..."

# 1. Backup manual fixes (if they exist)
if [[ -d "src/lib" ]]; then
    mkdir -p _backup/manual-fixes
    [[ -f src/lib/confidence.ts ]] && cp src/lib/confidence.ts _backup/manual-fixes/
    [[ -f src/lib/sessionState.ts ]] && cp src/lib/sessionState.ts _backup/manual-fixes/
    [[ -f src/lib/export/narrative.ts ]] && cp src/lib/export/narrative.ts _backup/manual-fixes/
    echo "✓ Manual fixes backed up to _backup/manual-fixes/"
fi

# 2. Delete root config files
rm -f docker-compose.yml drizzle.config.ts next.config.ts package.json
rm -f playwright.config.ts tsconfig.json vitest.config.ts .env.example
echo "✓ Deleted root config files"

# 3. Delete state and generated files
rm -f .bootstrap_state tsconfig.tsbuildinfo next-env.d.ts pnpm-lock.yaml
echo "✓ Deleted state files"

# 4. Delete directories
rm -rf src/ e2e/ public/ .next/ node_modules/ logs/ test-results/ playwright-report/
echo "✓ Deleted source and build directories"

# 5. Verify OmniForge improvements preserved
if [[ -f "_build/omniforge/tech_stack/quality/verify-build.sh" ]]; then
    echo "✅ OmniForge improvements preserved"
else
    echo "❌ ERROR: OmniForge improvements lost!"
    exit 1
fi

echo ""
echo "✅ Reset complete"
echo ""
echo "Manual fixes backed up to: _backup/manual-fixes/"
echo ""
echo "Next steps:"
echo "  1. Run: omni run"
echo "  2. If build fails, restore: cp _backup/manual-fixes/*.ts src/lib/"
echo "  3. Run: omni build"
```

---

## Phase 2: Enhance OmniForge with --reset Command

### 2.1 Design Requirements

**Command**: `omni --reset` or `omni reset`

**Features**:
1. Read `.bootstrap_state` to identify all created files
2. Parse deployment logs to track file creation
3. Interactive mode: show what will be deleted, confirm
4. Non-interactive mode: `omni reset --yes`
5. Safety: backup important files before deletion
6. Preserve OmniForge system improvements
7. Smart detection: distinguish deployment artifacts from user modifications

### 2.2 Implementation Architecture

**New Files to Create**:
1. `_build/omniforge/bin/reset` - Main reset script
2. `_build/omniforge/lib/reset.sh` - Reset library functions
3. `_build/omniforge/logs/deployment-manifest.log` - Track created files

**Enhanced Files**:
1. `_build/omniforge/omni.sh` - Add reset command
2. `_build/omniforge/lib/common.sh` - Add file tracking functions

### 2.3 Deployment Manifest System

**Purpose**: Track every file created during deployment

**Format** (`logs/deployment-manifest.log`):
```
# OmniForge Deployment Manifest
# Generated: 2025-11-24T01:28:57-06:00
# Session: 5a4441b

[ROOT_CONFIGS]
docker-compose.yml|2025-11-24T01:28:58-06:00|core/00-nextjs
drizzle.config.ts|2025-11-24T01:29:02-06:00|db/drizzle-setup
next.config.ts|2025-11-24T01:28:58-06:00|core/00-nextjs
package.json|2025-11-24T01:28:57-06:00|core/00-nextjs
playwright.config.ts|2025-11-24T01:53:31-06:00|testing/playwright-setup
tsconfig.json|2025-11-24T01:28:58-06:00|foundation/init-typescript
vitest.config.ts|2025-11-24T01:53:31-06:00|testing/vitest-setup

[SOURCE_FILES]
src/app/globals.css|2025-11-24T01:28:58-06:00|core/00-nextjs
src/app/layout.tsx|2025-11-24T01:28:58-06:00|core/00-nextjs
src/app/page.tsx|2025-11-24T01:28:58-06:00|core/00-nextjs
src/db/index.ts|2025-11-24T01:29:02-06:00|db/db-client-index
src/db/schema/index.ts|2025-11-24T01:29:02-06:00|db/drizzle-schema-base
src/prompts/system.ts|2025-11-24T01:29:17-06:00|intelligence/melissa-prompts
src/prompts/discovery.ts|2025-11-24T01:29:17-06:00|intelligence/melissa-prompts
src/prompts/quantification.ts|2025-11-24T01:29:17-06:00|intelligence/melissa-prompts
src/prompts/validation.ts|2025-11-24T01:29:17-06:00|intelligence/melissa-prompts
src/prompts/synthesis.ts|2025-11-24T01:29:17-06:00|intelligence/melissa-prompts
src/prompts/phaseRouter.ts|2025-11-24T01:29:17-06:00|intelligence/melissa-prompts
src/stores/index.ts|2025-11-24T01:29:08-06:00|state/zustand-setup
src/schemas/roi.ts|2025-11-24T01:29:18-06:00|intelligence/roi-engine
src/test/setup.ts|2025-11-24T01:53:31-06:00|testing/vitest-setup
...

[DIRECTORIES]
src/app/
src/db/
src/db/schema/
src/prompts/
src/stores/
src/schemas/
src/components/
src/hooks/
src/styles/
src/types/
src/test/
e2e/
public/

[GITKEEP_FILES]
src/components/.gitkeep
src/db/.gitkeep
src/hooks/.gitkeep
src/styles/.gitkeep
src/types/.gitkeep
public/.gitkeep
```

### 2.4 Reset Library Functions

**File**: `_build/omniforge/lib/reset.sh`

```bash
#!/usr/bin/env bash
# Reset Library - Track and reset deployments

# Track file creation during deployment
track_file_creation() {
    local file_path="$1"
    local script_id="${2:-unknown}"
    local timestamp=$(date -Iseconds)
    local manifest="${PROJECT_ROOT}/logs/deployment-manifest.log"

    mkdir -p "$(dirname "$manifest")"

    # Initialize manifest if needed
    if [[ ! -f "$manifest" ]]; then
        cat > "$manifest" <<EOF
# OmniForge Deployment Manifest
# Session: $(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
# Started: $(date -Iseconds)

EOF
    fi

    echo "${file_path}|${timestamp}|${script_id}" >> "$manifest"
}

# Get list of deployed files from manifest
get_deployed_files() {
    local manifest="${PROJECT_ROOT}/logs/deployment-manifest.log"

    if [[ ! -f "$manifest" ]]; then
        log_warn "No deployment manifest found"
        return 1
    fi

    # Extract file paths (first column)
    grep -v '^#' "$manifest" | grep -v '^\[' | cut -d'|' -f1
}

# Check if file is OmniForge system file (should be preserved)
is_omniforge_system_file() {
    local file="$1"

    # Preserve OmniForge system directory
    [[ "$file" =~ ^_build/omniforge/ ]] && return 0

    # Preserve Claude configuration
    [[ "$file" =~ ^\.claude/ ]] && return 0

    # Preserve documentation
    [[ "$file" =~ ^docs/ ]] && return 0

    # Preserve git
    [[ "$file" =~ ^\.git/ ]] && return 0

    return 1
}

# Interactive reset confirmation
confirm_reset() {
    local file_list="$1"
    local file_count=$(echo "$file_list" | wc -l)

    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    log_warn "About to DELETE ${file_count} files from last deployment"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    echo "Files to delete:"
    echo "$file_list" | head -20
    if [[ $file_count -gt 20 ]]; then
        echo "... and $((file_count - 20)) more files"
    fi
    echo ""
    echo "OmniForge system files will be PRESERVED"
    echo ""
    read -rp "Continue with reset? [y/N] " response

    [[ "$response" =~ ^[Yy]$ ]]
}

# Backup important files before reset
backup_deployment_files() {
    local backup_dir="_backup/deployment-$(date +%Y%m%d-%H%M%S)"

    mkdir -p "$backup_dir"

    # Backup manually created fixes
    if [[ -d "src/lib" ]]; then
        mkdir -p "$backup_dir/manual-fixes"
        [[ -f src/lib/confidence.ts ]] && cp src/lib/confidence.ts "$backup_dir/manual-fixes/"
        [[ -f src/lib/sessionState.ts ]] && cp src/lib/sessionState.ts "$backup_dir/manual-fixes/"
        [[ -f src/lib/export/narrative.ts ]] && cp src/lib/export/narrative.ts "$backup_dir/manual-fixes/"
        log_ok "Manual fixes backed up"
    fi

    # Backup package.json if it exists
    [[ -f package.json ]] && cp package.json "$backup_dir/"

    # Backup tsconfig.json if it exists
    [[ -f tsconfig.json ]] && cp tsconfig.json "$backup_dir/"

    log_ok "Deployment files backed up to: $backup_dir"
    echo "$backup_dir"
}

# Execute reset
execute_reset() {
    local manifest="${PROJECT_ROOT}/logs/deployment-manifest.log"
    local force="${1:-false}"

    cd "$PROJECT_ROOT"

    # Get list of deployed files
    local deployed_files
    if ! deployed_files=$(get_deployed_files); then
        log_error "Cannot reset: no deployment manifest found"
        return 1
    fi

    # Interactive confirmation unless --yes flag
    if [[ "$force" != "true" ]]; then
        if ! confirm_reset "$deployed_files"; then
            log_info "Reset cancelled by user"
            return 0
        fi
    fi

    # Backup before deletion
    local backup_dir
    backup_dir=$(backup_deployment_files)

    log_info "Executing reset..."

    # Delete root config files
    rm -f docker-compose.yml drizzle.config.ts next.config.ts package.json
    rm -f playwright.config.ts tsconfig.json vitest.config.ts .env.example
    log_ok "Deleted root config files"

    # Delete state files
    rm -f .bootstrap_state tsconfig.tsbuildinfo next-env.d.ts pnpm-lock.yaml
    log_ok "Deleted state files"

    # Delete directories
    rm -rf src/ e2e/ public/ .next/ node_modules/ logs/ test-results/ playwright-report/
    log_ok "Deleted source and build directories"

    # Verify OmniForge improvements preserved
    if [[ -f "_build/omniforge/tech_stack/quality/verify-build.sh" ]]; then
        log_ok "OmniForge improvements preserved"
    else
        log_error "OmniForge improvements may have been deleted!"
        log_info "Restore from backup: $backup_dir"
        return 1
    fi

    echo ""
    echo "✅ Reset complete"
    echo ""
    echo "Backup location: $backup_dir"
    echo ""
    echo "Next steps:"
    echo "  1. Run: omni run"
    echo "  2. If build fails, restore manual fixes:"
    echo "     cp $backup_dir/manual-fixes/*.ts src/lib/"
    echo "  3. Run: omni build"
    echo ""
}
```

### 2.5 Enhance omni.sh

**Changes to `/home/luce/apps/bloom2/_build/omniforge/omni.sh`**:

1. Add `reset` to command list (line 226):
```bash
menu|run|list|status|build|forge|compile|clean|reset)
```

2. Add reset case handler (after clean, line 315):
```bash
    reset)
        # Load libraries for reset function
        source "${SCRIPT_DIR}/lib/common.sh"
        source "${SCRIPT_DIR}/lib/reset.sh"

        # Parse --yes flag for non-interactive mode
        local force=false
        if [[ "${ARGS[@]:-}" =~ --yes ]]; then
            force=true
        fi

        execute_reset "$force"
        ;;
```

3. Update usage documentation (line 133):
```bash
    reset           Reset last deployment
                    - Deletes deployment artifacts while preserving OmniForge system
                    - Creates backup before deletion
                    - Use --yes for non-interactive mode
```

### 2.6 Enhance File Creation Tracking

**Modify**: `_build/omniforge/lib/common.sh`

Add to `write_file` function:
```bash
write_file() {
    local target_file="$1"
    local content="$2"

    # ... existing validation code ...

    # Write content
    echo "$content" > "$target_file"

    # Track file creation for reset functionality
    if [[ -n "${SCRIPT_ID:-}" ]]; then
        track_file_creation "$target_file" "$SCRIPT_ID"
    fi

    log_ok "Created: $target_file"
}
```

---

## Phase 3: Testing Plan

### 3.1 Test Reset Manually

1. Execute reset script
2. Verify OmniForge files preserved
3. Verify deployment files deleted
4. Check backup created

### 3.2 Test Enhanced omni.sh

1. Test `omni reset` interactive mode
2. Test `omni reset --yes` non-interactive mode
3. Test manifest tracking during deployment
4. Verify reset removes only deployment artifacts

### 3.3 Test Full Cycle

1. Reset deployment: `omni reset --yes`
2. Redeploy: `omni run`
3. Verify manifest created
4. Reset again: `omni reset`
5. Verify clean reset

---

## Phase 4: Documentation Updates

### 4.1 Update OMNIFORGE.md

Add section on reset functionality:
```markdown
## Resetting Deployments

OmniForge tracks all files created during deployment in `logs/deployment-manifest.log`.

### Reset Last Deployment

```bash
omni reset              # Interactive mode (confirm before delete)
omni reset --yes        # Non-interactive mode (auto-confirm)
```

### What Gets Deleted

- Root config files (package.json, tsconfig.json, etc.)
- Source directory (src/)
- Test directories (e2e/, test/)
- Build artifacts (.next/, node_modules/)
- Generated files (.bootstrap_state, lock files)

### What Gets Preserved

- OmniForge system (_build/omniforge/)
- OmniForge improvements and enhancements
- Claude Code configuration (.claude/)
- Git repository (.git/)
- Documentation (docs/)

### Backup Strategy

Before deletion, `omni reset` automatically creates a backup:
```
_backup/deployment-YYYYMMDD-HHMMSS/
├── manual-fixes/           # Manually created files
├── package.json            # Package manifest
└── tsconfig.json           # TypeScript config
```

Restore from backup if needed:
```bash
cp _backup/deployment-*/manual-fixes/*.ts src/lib/
```
```

### 4.2 Create Quick Reference

**File**: `_build/omniforge/RESET-QUICKREF.md`

```markdown
# Reset Quick Reference

## Reset Commands

| Command | Description |
|---------|-------------|
| `omni reset` | Interactive reset (confirm before delete) |
| `omni reset --yes` | Non-interactive reset (auto-confirm) |

## Files Deleted

- `docker-compose.yml`, `drizzle.config.ts`, `next.config.ts`
- `package.json`, `playwright.config.ts`, `tsconfig.json`, `vitest.config.ts`
- `src/` directory tree (all source files)
- `e2e/` directory (E2E tests)
- `public/` directory
- `.bootstrap_state`, `node_modules/`, `.next/`, `logs/`

## Files Preserved

- `_build/omniforge/` (entire OmniForge system)
- `.claude/` (Claude Code config)
- `docs/` (documentation)
- `.git/` (git repository)

## Backup Location

Backups stored in: `_backup/deployment-YYYYMMDD-HHMMSS/`

## Full Cycle

1. Reset: `omni reset --yes`
2. Deploy: `omni run`
3. Build: `omni build`
4. Test: `pnpm dev`
```

---

## Execution Checklist

### Phase 1: Reset Current Deployment ✓
- [ ] Create backup of manual fixes
- [ ] Execute reset script
- [ ] Verify OmniForge improvements preserved
- [ ] Verify deployment files deleted
- [ ] Document backup location

### Phase 2: Implement Reset System ✓
- [ ] Create `lib/reset.sh` with tracking functions
- [ ] Create `bin/reset` executable script
- [ ] Enhance `omni.sh` with reset command
- [ ] Update `lib/common.sh` to track file creation
- [ ] Test reset functionality

### Phase 3: Documentation ✓
- [ ] Update OMNIFORGE.md with reset section
- [ ] Create RESET-QUICKREF.md
- [ ] Update omni.sh usage text
- [ ] Document manifest format

### Phase 4: Testing ✓
- [ ] Test manual reset
- [ ] Test `omni reset` interactive
- [ ] Test `omni reset --yes` non-interactive
- [ ] Test full deployment → reset → redeploy cycle

---

## Success Criteria

- ✅ Current deployment reset successfully
- ✅ All OmniForge improvements preserved
- ✅ Backup created and documented
- ✅ `omni reset` command functional
- ✅ Deployment manifest tracks all created files
- ✅ Full cycle tested (deploy → reset → redeploy)
- ✅ Documentation complete and accurate

---

**Status**: Ready to Execute
**Risk**: Low (backup strategy in place)
**Estimated Time**: 45 minutes
**Recommendation**: Execute Phase 1 first, verify, then proceed to Phase 2
