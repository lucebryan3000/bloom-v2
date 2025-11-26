#!/usr/bin/env bash
# =============================================================================
# Refactor Script - Replace PROJECT_ROOT with INSTALL_DIR Throughout Codebase
# =============================================================================
# This script implements Option B: Full INSTALL_DIR support by refactoring
# all 49 tech_stack scripts to use INSTALL_DIR instead of PROJECT_ROOT.
#
# Usage:
#   bash refactor-install-dir.sh [--dry-run] [--verbose]
#
# Options:
#   --dry-run    Show what would be changed without modifying files
#   --verbose    Show detailed output for each file processed
#
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

# Parse arguments
DRY_RUN=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            ;;
        --verbose)
            VERBOSE=true
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
    shift
done

# =============================================================================
# Configuration
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OMNIFORGE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TECH_STACK_DIR="$OMNIFORGE_ROOT/tech_stack"

# Track statistics
TOTAL_FILES=0
TOTAL_REPLACEMENTS=0
FILES_MODIFIED=0

# =============================================================================
# Helper Functions
# =============================================================================

log_info() {
    echo "[INFO] $*"
}

log_ok() {
    echo "[✓] $*"
}

log_warn() {
    echo "[WARN] $*"
}

log_error() {
    echo "[ERROR] $*"
}

log_verbose() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo "[VERBOSE] $*"
    fi
}

# =============================================================================
# Main Refactoring Logic
# =============================================================================

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "OmniForge - INSTALL_DIR Refactoring Script"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "This script replaces PROJECT_ROOT with INSTALL_DIR in all"
echo "tech_stack scripts to implement full INSTALL_DIR support."
echo ""

if [[ "$DRY_RUN" == "true" ]]; then
    log_warn "DRY RUN MODE - No files will be modified"
    echo ""
fi

log_info "Scanning $TECH_STACK_DIR for scripts..."
echo ""

# Find all .sh files in tech_stack
while IFS= read -r file; do
    TOTAL_FILES=$((TOTAL_FILES + 1))

    # Count matches in this file
    match_count=$(grep -c "PROJECT_ROOT" "$file" 2>/dev/null || true)
    match_count=${match_count:-0}
    match_count=$((match_count))

    if (( match_count > 0 )); then
        log_verbose "Found $match_count references in: $file"

        if [[ "$DRY_RUN" == "true" ]]; then
            # Show what would be changed
            log_verbose "Preview of changes:"
            grep -n "PROJECT_ROOT" "$file" | head -3 | sed 's/^/  /'
            if (( match_count > 3 )); then
                log_verbose "  ... and $((match_count - 3)) more references"
            fi
            TOTAL_REPLACEMENTS=$((TOTAL_REPLACEMENTS + match_count))
        else
            # Perform the actual replacement
            sed -i 's/\${PROJECT_ROOT}/\${INSTALL_DIR}/g' "$file"
            sed -i 's/"\$PROJECT_ROOT"/"\$INSTALL_DIR"/g' "$file"
            sed -i "s/'\$PROJECT_ROOT'/'\$INSTALL_DIR'/g" "$file"

            # Handle bare variable references (PROJECT_ROOT without braces)
            # Be careful to match word boundaries
            sed -i 's/\$PROJECT_ROOT\([^a-zA-Z0-9_]\)/\$INSTALL_DIR\1/g' "$file"

            FILES_MODIFIED=$((FILES_MODIFIED + 1))
            TOTAL_REPLACEMENTS=$((TOTAL_REPLACEMENTS + match_count))

            log_ok "Modified: $(basename $file) ($match_count replacements)"
        fi
    fi
done < <(find "$TECH_STACK_DIR" -name "*.sh" -type f)

# =============================================================================
# Summary
# =============================================================================

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "Refactoring Summary"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Total scripts scanned:     $TOTAL_FILES"
echo "Scripts with PROJECT_ROOT: $((TOTAL_FILES - (TOTAL_FILES - FILES_MODIFIED)))"
echo "Total replacements:        $TOTAL_REPLACEMENTS"
echo ""

if [[ "$DRY_RUN" == "true" ]]; then
    echo "⚠️  DRY RUN MODE - No files were modified"
    echo ""
    echo "To apply changes, run without --dry-run flag:"
    echo "  bash $0"
else
    log_ok "Successfully modified $FILES_MODIFIED script(s)"
    echo ""
    echo "Next steps:"
    echo "  1. Run tests to verify refactoring: omni run"
    echo "  2. Review changes in git: git diff _build/omniforge/tech_stack/"
    echo "  3. Commit changes: git add -A && git commit -m 'refactor: use INSTALL_DIR throughout tech_stack'"
fi

echo ""
