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

set -Eeuo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OMNI_ROOT="${OMNI_ROOT:-"${SCRIPT_DIR}"}"

# Central bootstrap loader (delegates to common.sh)
# shellcheck source=/dev/null
. "${OMNI_ROOT}/lib/bootstrap.sh"

readonly VERSION="1.1.0"
readonly CODENAME="OmniForge"

# =============================================================================
# ERROR HANDLING
# =============================================================================

# Error handler for cleaner exit messages
_error_exit() {
    local msg="$1"
    local code="${2:-1}"
    echo "[ERROR] $msg" >&2
    exit "$code"
}

# Validate required files exist before execution
_validate_files() {
    local required_files=(
        "${SCRIPT_DIR}/lib/bootstrap.sh"
        "${SCRIPT_DIR}/lib/menu.sh"
        "${SCRIPT_DIR}/lib/ascii.sh"
        "${SCRIPT_DIR}/omni.config"
        "${SCRIPT_DIR}/omni.settings.sh"
        "${SCRIPT_DIR}/omni.profiles.sh"
        "${SCRIPT_DIR}/omni.phases.sh"
    )

    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            _error_exit "Required file not found: $file" 1
        fi
    done
}

# Validate bin scripts exist
_validate_bin() {
    local script="$1"
    if [[ ! -x "${SCRIPT_DIR}/bin/${script}" ]]; then
        _error_exit "Executable not found: ${SCRIPT_DIR}/bin/${script}" 1
    fi
}

# Set TERM if not set (prevents tput errors)
: "${TERM:=xterm-256color}"
export TERM

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

    clean           Clean/reset a previous installation
                    - Deletes app folder, state files, and optionally Docker
                    - Use --level 1-4 for quick/full/deep/nuclear clean
                    - Use --path <dir> to specify installation path

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

    reset           Reset last deployment
                    - Deletes deployment artifacts while preserving OmniForge system
                    - Creates backup before deletion
                    - Use --yes for non-interactive mode

OPTIONS:
    -h, --help      Show this help
    -n, --dry-run   Preview without executing (show what would run)
    -v, --verbose   Verbose output with detailed logging
    -p, --phase N   Run only specific phase number (0-5)
    -f, --force     Force re-run (ignore previous success state)
    --path <dir>    Target installation path (for clean command)
    --level <1-4>   Clean level: 1=quick, 2=full, 3=deep, 4=nuclear

WORKFLOW:
    1. omni menu     Interactive setup (recommended for first time)
    2. omni run      Execute all phase scripts to initialize project
    3. omni build    Build and verify the initialized project
    4. omni reset    Reset deployment for fresh start
    5. omni clean    Reset installation to test different configurations

EXAMPLES:
    omni                           # Interactive menu (default)
    omni run                       # Run all phases
    omni run --dry-run             # Preview what would execute
    omni run --phase 0             # Run only phase 0
    omni run --force               # Re-run all, ignore state
    omni list                      # List phases without running
    omni status                    # Show completion progress
    omni build                     # Build after initialization
    omni reset                     # Reset last deployment (interactive)
    omni reset --yes               # Reset without confirmation
    omni clean                     # Interactive clean menu
    omni clean --path ./test/install-1 --level 2  # Full clean specific path

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
CLEAN_PATH=""
CLEAN_LEVEL=""
RESET_YES=false

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
            if [[ -z "${2:-}" ]]; then
                _error_exit "--phase requires a phase number (0-5)" 1
            fi
            if ! [[ "$2" =~ ^[0-5]$ ]]; then
                _error_exit "Invalid phase number: $2. Must be 0-5" 1
            fi
            PHASE="$2"
            shift 2
            ;;
        --path)
            if [[ -z "${2:-}" ]]; then
                _error_exit "--path requires a directory path" 1
            fi
            CLEAN_PATH="$2"
            shift 2
            ;;
        --level)
            if [[ -z "${2:-}" ]]; then
                _error_exit "--level requires a level number (1-4)" 1
            fi
            if ! [[ "$2" =~ ^[1-4]$ ]]; then
                _error_exit "Invalid clean level: $2. Must be 1-4" 1
            fi
            CLEAN_LEVEL="$2"
            shift 2
            ;;
        --yes)
            RESET_YES=true
            shift
            ;;
        menu|run|list|status|build|forge|compile|clean|reset)
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

# Build arguments for bin scripts (array to avoid quoting issues)
ARGS=()
[[ "$DRY_RUN" == "true" ]] && ARGS+=("--dry-run")
[[ "$VERBOSE" == "true" ]] && ARGS+=("--verbose")
[[ "$FORCE" == "true" ]] && ARGS+=("--force")
[[ -n "$PHASE" ]] && ARGS+=("--phase" "$PHASE")

# Validate required files before execution
_validate_files

# Execute command by delegating to bin scripts
case "${COMMAND:-}" in
    menu|"")
        # Launch interactive menu (default when no command given)
        source "${SCRIPT_DIR}/lib/ascii.sh"
        source "${SCRIPT_DIR}/lib/menu.sh"
        menu_main
        ;;
    run)
        _validate_bin "omni"
        show_logo
        exec "${SCRIPT_DIR}/bin/omni" "${ARGS[@]}"
        ;;
    list)
        _validate_bin "status"
        exec "${SCRIPT_DIR}/bin/status" --list
        ;;
    status)
        _validate_bin "status"
        exec "${SCRIPT_DIR}/bin/status" --state
        ;;
    build)
        _validate_bin "forge"
        show_logo
        exec "${SCRIPT_DIR}/bin/forge" "${ARGS[@]}"
        ;;
    clean)
        # Load libraries for clean function
        source "${SCRIPT_DIR}/lib/ascii.sh"
        source "${SCRIPT_DIR}/lib/menu.sh"

        # If no path specified, launch interactive menu
        if [[ -z "$CLEAN_PATH" ]]; then
            menu_clean
        else
            # Non-interactive clean with --path and optional --level
            _run_clean_noninteractive "$CLEAN_PATH" "${CLEAN_LEVEL:-1}"
        fi
        ;;
    reset)
        _validate_bin "reset"
        show_logo

        # Build args for reset command
        RESET_ARGS=()
        [[ "$RESET_YES" == "true" ]] && RESET_ARGS+=("--yes")

        exec "${SCRIPT_DIR}/bin/reset" "${RESET_ARGS[@]}"
        ;;
    *)
        echo "Unknown command: $COMMAND"
        usage
        exit 1
        ;;
esac
