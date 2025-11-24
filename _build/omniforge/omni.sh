#!/usr/bin/env bash
# =============================================================================
# OmniForge - Infinite Architectures. Instant Foundation.
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

readonly VERSION="1.1.0"
readonly CODENAME="OmniForge"

# =============================================================================
# LOGO
# =============================================================================

show_logo() {
    clear
    cat << 'EOF'
    ███████                                ███
  ███░░░░░███                             ░░░
 ███     ░░███ █████████████   ████████   ████
░███      ░███░░███░░███░░███ ░░███░░███ ░░███
░███      ░███ ░███ ░███ ░███  ░███ ░███  ░███
░░███     ███  ░███ ░███ ░███  ░███ ░███  ░███
 ░░░███████░   █████░███ █████ ████ █████ █████
   ░░░░░░░    ░░░░░ ░░░ ░░░░░ ░░░░ ░░░░░ ░░░░░
                     ___  __   __   __   ___
                    |__  /  \ |__) / _` |__
                    |    \__/ |  \ \__> |___

EOF
    echo "  Infinite Architectures. Instant Foundation. v${VERSION}"
}

# =============================================================================
# USAGE
# =============================================================================

usage() {
    show_logo
    cat <<EOF
${CODENAME} v${VERSION} - Infinite Architectures. Instant Foundation.

Usage: omni [OPTIONS] [COMMAND]

COMMANDS:
    run             Execute phase scripts from omniforge.conf
                    - Runs tech_stack/*.sh scripts in phase order (0-5)
                    - Tracks state to avoid re-running completed phases
                    - Use --force to re-run previously completed phases

    list            List all phases and their scripts without executing
                    - Shows phase metadata from omniforge.conf
                    - Displays execution order and dependencies

    status          Show completion status and state file contents
                    - Displays which phases/scripts have run
                    - Shows success/failure status

    build           Build and verify the project (post-initialization)
                    - Runs: pnpm install, lint, typecheck, build
                    - Use after 'run' completes to compile the project
                    - Validates the initialized project works correctly

OPTIONS:
    -h, --help      Show this help
    -n, --dry-run   Preview without executing (show what would run)
    -v, --verbose   Verbose output with detailed logging
    -p, --phase N   Run only specific phase number (0-5)
    -f, --force     Force re-run (ignore previous success state)

WORKFLOW:
    1. omni menu     Interactive setup (recommended for first time)
    2. omni run      Execute all phase scripts to initialize project
    3. omni build    Build and verify the initialized project

EXAMPLES:
    omni                           # Interactive menu (default)
    omni run                       # Run all phases
    omni run --dry-run             # Preview what would execute
    omni run --phase 0             # Run only phase 0
    omni run --force               # Re-run all, ignore state
    omni list                      # List phases without running
    omni status                    # Show completion progress
    omni build                     # Build after initialization

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
        menu|run|list|status|build|forge|compile)
            # Map 'forge' and 'compile' to 'build' for backward compat
            if [[ "$1" == "forge" || "$1" == "compile" ]]; then
                COMMAND="build"
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
    menu|"")
        # Launch interactive menu (default when no command given)
        source "${SCRIPT_DIR}/lib/common.sh"
        source "${SCRIPT_DIR}/lib/ascii.sh"
        source "${SCRIPT_DIR}/lib/menu.sh"
        menu_main
        ;;
    run)
        show_logo
        exec "${SCRIPT_DIR}/bin/omni" $ARGS
        ;;
    list)
        exec "${SCRIPT_DIR}/bin/status" --list
        ;;
    status)
        exec "${SCRIPT_DIR}/bin/status" --state
        ;;
    build)
        show_logo
        exec "${SCRIPT_DIR}/bin/forge" $ARGS
        ;;
    *)
        echo "Unknown command: $COMMAND"
        usage
        exit 1
        ;;
esac
