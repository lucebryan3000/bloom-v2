#!/usr/bin/env bash
# =============================================================================
# Reset Library - Track and Reset Deployments
# =============================================================================
# Functions for tracking file creation during deployment and resetting
# deployments while preserving OmniForge system improvements
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

# =============================================================================
# File Tracking Functions
# =============================================================================

# Track file creation during deployment
track_file_creation() {
    local file_path="$1"
    local script_id="${2:-unknown}"
    local timestamp=$(date -Iseconds)
    local manifest="${PROJECT_ROOT}/logs/deployment-manifest.log"

    mkdir -p "$(dirname "$manifest")"

    # Initialize manifest if needed
    if [[ ! -f "$manifest" ]]; then
        local session_id=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
        cat > "$manifest" <<EOF
# OmniForge Deployment Manifest
# Session: ${session_id}
# Started: $(date -Iseconds)

EOF
    fi

    # Append file entry: path|timestamp|script_id
    echo "${file_path}|${timestamp}|${script_id}" >> "$manifest"
}

# Get list of deployed files from manifest
get_deployed_files() {
    local manifest="${PROJECT_ROOT}/logs/deployment-manifest.log"

    if [[ ! -f "$manifest" ]]; then
        log_warn "No deployment manifest found at: $manifest"
        return 1
    fi

    # Extract file paths (first column), skip comments and section headers
    grep -v '^#' "$manifest" | grep -v '^\[' | grep -v '^$' | cut -d'|' -f1 || true
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

    # Preserve backup directory
    [[ "$file" =~ ^_backup/ ]] && return 0

    return 1
}

# =============================================================================
# Interactive Confirmation
# =============================================================================

# Interactive reset confirmation
confirm_reset() {
    local file_count="$1"

    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    log_warn "About to DELETE deployment artifacts"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    echo "Will delete:"
    echo "  • Root config files (package.json, tsconfig.json, etc.)"
    echo "  • Source directory (src/)"
    echo "  • Test directories (e2e/)"
    echo "  • Build artifacts (.next/, node_modules/)"
    echo "  • State files (.bootstrap_state)"
    echo ""
    echo "Will preserve:"
    echo "  • OmniForge system (_build/omniforge/)"
    echo "  • Claude Code config (.claude/)"
    echo "  • Documentation (docs/)"
    echo "  • Git repository (.git/)"
    echo "  • Backups (_backup/)"
    echo ""
    log_info "A backup will be created before deletion"
    echo ""
    read -rp "Continue with reset? [y/N] " response

    [[ "$response" =~ ^[Yy]$ ]]
}

# =============================================================================
# Backup Functions
# =============================================================================

# Backup important files before reset
backup_deployment_files() {
    local backup_dir="_backup/deployment-$(date +%Y%m%d-%H%M%S)"

    mkdir -p "$backup_dir"

    log_info "Creating backup at: $backup_dir"

    # Backup manually created fixes (if they exist)
    if [[ -d "src/lib" ]]; then
        mkdir -p "$backup_dir/manual-fixes"

        if [[ -f src/lib/confidence.ts ]]; then
            cp src/lib/confidence.ts "$backup_dir/manual-fixes/"
            log_ok "Backed up: src/lib/confidence.ts"
        fi

        if [[ -f src/lib/sessionState.ts ]]; then
            cp src/lib/sessionState.ts "$backup_dir/manual-fixes/"
            log_ok "Backed up: src/lib/sessionState.ts"
        fi

        if [[ -f src/lib/export/narrative.ts ]]; then
            cp src/lib/export/narrative.ts "$backup_dir/manual-fixes/"
            log_ok "Backed up: src/lib/export/narrative.ts"
        fi
    fi

    # Backup package.json if it exists
    if [[ -f package.json ]]; then
        cp package.json "$backup_dir/"
        log_ok "Backed up: package.json"
    fi

    # Backup tsconfig.json if it exists
    if [[ -f tsconfig.json ]]; then
        cp tsconfig.json "$backup_dir/"
        log_ok "Backed up: tsconfig.json"
    fi

    # Backup deployment manifest
    if [[ -f logs/deployment-manifest.log ]]; then
        cp logs/deployment-manifest.log "$backup_dir/"
        log_ok "Backed up: deployment-manifest.log"
    fi

    # Backup bootstrap state
    if [[ -f .bootstrap_state ]]; then
        cp .bootstrap_state "$backup_dir/"
        log_ok "Backed up: .bootstrap_state"
    fi

    log_ok "Deployment files backed up to: $backup_dir"
    echo "$backup_dir"
}

# =============================================================================
# Reset Execution
# =============================================================================

# Execute reset
execute_reset() {
    local force="${1:-false}"

    cd "$PROJECT_ROOT"

    log_info "Reset Deployment - OmniForge v${VERSION:-1.0.0}"
    echo ""

    # Interactive confirmation unless --yes flag
    if [[ "$force" != "true" ]]; then
        if ! confirm_reset "deployment"; then
            log_info "Reset cancelled by user"
            return 0
        fi
    fi

    # Backup before deletion
    log_step "Backing up deployment files..."
    local backup_dir
    backup_dir=$(backup_deployment_files)
    echo ""

    # Execute deletion
    log_step "Deleting deployment artifacts..."

    # Delete root config files
    rm -f docker-compose.yml drizzle.config.ts next.config.ts package.json \
          playwright.config.ts tsconfig.json vitest.config.ts .env.example 2>/dev/null || true
    log_ok "Deleted root config files"

    # Delete state files
    rm -f .bootstrap_state tsconfig.tsbuildinfo next-env.d.ts pnpm-lock.yaml 2>/dev/null || true
    log_ok "Deleted state files"

    # Delete directories
    rm -rf src/ e2e/ public/ .next/ node_modules/ logs/ test-results/ playwright-report/ 2>/dev/null || true
    log_ok "Deleted source and build directories"

    # Verify OmniForge improvements preserved
    echo ""
    log_step "Verifying OmniForge system preserved..."

    local critical_files=(
        "_build/omniforge/omni.sh"
        "_build/omniforge/lib/common.sh"
        "_build/omniforge/bootstrap.conf"
    )

    local all_preserved=true
    for file in "${critical_files[@]}"; do
        if [[ -f "$file" ]]; then
            log_ok "Preserved: $file"
        else
            log_error "Missing: $file"
            all_preserved=false
        fi
    done

    echo ""
    if [[ "$all_preserved" == "true" ]]; then
        log_ok "✅ OmniForge system preserved successfully"
    else
        log_error "❌ Some OmniForge files may be missing!"
        log_info "Restore from backup: $backup_dir"
        return 1
    fi

    # Summary
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    log_ok "✅ Reset Complete"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    log_info "Backup location: $backup_dir"
    echo ""
    log_info "Next steps:"
    echo "  1. Run: omni run               # Initialize new deployment"
    echo "  2. If build fails:"
    echo "     cp $backup_dir/manual-fixes/*.ts src/lib/"
    echo "  3. Run: omni build             # Verify build"
    echo ""
}

# =============================================================================
# Manifest-based Reset (Future Enhancement)
# =============================================================================

# Execute manifest-based reset (reads deployment-manifest.log)
execute_manifest_reset() {
    local force="${1:-false}"

    cd "$PROJECT_ROOT"

    log_info "Manifest-based Reset - OmniForge v${VERSION:-1.0.0}"
    echo ""

    # Get list of deployed files
    local deployed_files
    if ! deployed_files=$(get_deployed_files); then
        log_warn "No deployment manifest found"
        log_info "Using standard reset instead..."
        execute_reset "$force"
        return $?
    fi

    local file_count=$(echo "$deployed_files" | wc -l)
    log_info "Found $file_count files in deployment manifest"

    # Interactive confirmation unless --yes flag
    if [[ "$force" != "true" ]]; then
        if ! confirm_reset "$file_count"; then
            log_info "Reset cancelled by user"
            return 0
        fi
    fi

    # Backup before deletion
    log_step "Backing up deployment files..."
    local backup_dir
    backup_dir=$(backup_deployment_files)
    echo ""

    # Execute deletion based on manifest
    log_step "Deleting files from manifest..."
    local deleted_count=0
    local skipped_count=0

    while IFS= read -r file_path; do
        if is_omniforge_system_file "$file_path"; then
            log_skip "Preserving: $file_path"
            ((skipped_count++))
            continue
        fi

        if [[ -f "$file_path" ]]; then
            rm -f "$file_path"
            log_ok "Deleted: $file_path"
            ((deleted_count++))
        elif [[ -d "$file_path" ]]; then
            rm -rf "$file_path"
            log_ok "Deleted directory: $file_path"
            ((deleted_count++))
        fi
    done <<< "$deployed_files"

    echo ""
    log_ok "Deleted $deleted_count files/directories"
    log_info "Preserved $skipped_count system files"

    # Verify OmniForge improvements preserved
    echo ""
    log_step "Verifying OmniForge system preserved..."

    if [[ -f "_build/omniforge/omni.sh" ]]; then
        log_ok "✅ OmniForge system preserved successfully"
    else
        log_error "❌ OmniForge system may have been deleted!"
        log_info "Restore from backup: $backup_dir"
        return 1
    fi

    # Summary
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    log_ok "✅ Manifest-based Reset Complete"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    log_info "Backup location: $backup_dir"
    echo ""
    log_info "Next steps:"
    echo "  1. Run: omni run               # Initialize new deployment"
    echo "  2. Run: omni build             # Verify build"
    echo ""
}
