#!/usr/bin/env bash
# =============================================================================
# OmniForge - The Factory That Builds Universes
# Thin wrapper that delegates to modular bin/ entry points
# =============================================================================
#
# ARCHITECTURE:
# This script is a compatibility wrapper. All functionality has been
# moved to modular entry points in bin/:
#   - bin/omni     (main execution)
#   - bin/forge    (build/verify)
#   - bin/status   (show status)
#
# The modular libraries in lib/ provide:
#   - lib/logging.sh    (log_info, log_error, etc.)
#   - lib/config_bootstrap.sh     (config_load, config_validate)
#   - lib/phases.sh     (phase_discover, phase_execute)
#   - lib/packages.sh   (pkg_expand, pkg_add_dependency)
#   - lib/state.sh      (state_mark_success, state_has_succeeded)
#   - lib/git.sh        (git_ensure_clean)
#   - lib/validation.sh (require_cmd, require_node_version)
#   - lib/utils.sh      (run_cmd, ensure_dir, write_file)
#   - lib/common.sh     (loads all of the above)
#
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

readonly VERSION="3.0.0"
readonly CODENAME="OmniForge"

# =============================================================================
# USAGE
# =============================================================================

usage() {
    cat <<EOF
${CODENAME} v${VERSION} - The Factory That Builds Universes

Usage: omni [OPTIONS] [COMMAND]

COMMANDS:
    init            Initialize project with all phases
    run             Run all phases using PHASE_METADATA from omniforge.conf
    list            List all phases and scripts
    status          Show completion status
    forge           Build and verify project

OPTIONS:
    -h, --help      Show this help
    -n, --dry-run   Preview without executing
    -v, --verbose   Verbose output
    -p, --phase N   Run specific phase number
    -f, --force     Force re-run (ignore previous success state)

EXAMPLES:
    omni --init                    # Initialize project (alias for run)
    omni --help                    # Show this help
    omni run                       # Run all phases
    omni run --dry-run             # Preview execution
    omni run --phase 0             # Run only phase 0
    omni list                      # List all phases
    omni status                    # Show progress
    omni forge                     # Build and verify

ENTRY POINTS:
    ./bin/omni [options]     # Main execution
    ./bin/forge [options]    # Build and verify
    ./bin/status [options]   # Status and configuration

EOF
}

# =============================================================================
# MAIN - DELEGATE TO BIN SCRIPTS
# =============================================================================

# Default values
COMMAND=""
DRY_RUN="${DRY_RUN:-false}"
VERBOSE="${VERBOSE:-false}"
FORCE=false
PHASE=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        --init)
            COMMAND="run"
            shift
            ;;
        -n|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -p|--phase)
            PHASE="$2"
            shift 2
            ;;
        init|run|list|status|forge|compile)
            # Map 'compile' to 'forge' for backward compat
            if [[ "$1" == "compile" ]]; then
                COMMAND="forge"
            else
                COMMAND="$1"
            fi
            shift
            ;;
        # Legacy compatibility
        --all)
            COMMAND="run"
            shift
            ;;
        --skip-breaks)
            # Ignored - breakpoints removed in v3
            shift
            ;;
        --from)
            # Ignored - use --phase instead
            shift 2
            ;;
        phase)
            COMMAND="run"
            PHASE="${2:-}"
            shift 2
            ;;
        script)
            echo "Error: 'script' command removed in v3. Use --phase instead."
            exit 1
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Build arguments for bin scripts
ARGS=""
[[ "$DRY_RUN" == "true" ]] && ARGS="$ARGS --dry-run"
[[ "$VERBOSE" == "true" ]] && ARGS="$ARGS --verbose"
[[ "$FORCE" == "true" ]] && ARGS="$ARGS --force"
[[ -n "$PHASE" ]] && ARGS="$ARGS --phase $PHASE"

# Execute command by delegating to bin scripts
case "${COMMAND:-}" in
    init|run)
        exec "${SCRIPT_DIR}/bin/omni" $ARGS
        ;;
    list)
        exec "${SCRIPT_DIR}/bin/status" --list
        ;;
    status)
        exec "${SCRIPT_DIR}/bin/status" --state
        ;;
    forge)
        exec "${SCRIPT_DIR}/bin/forge" $ARGS
        ;;
    "")
        usage
        exit 0
        ;;
    *)
        echo "Unknown command: $COMMAND"
        usage
        exit 1
        ;;
esac
