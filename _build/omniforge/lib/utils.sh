#!/usr/bin/env bash
# =============================================================================
# lib/utils.sh - General Utility Functions
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Pure functions for file operations, command execution. No execution on source.
#
# Exports:
#   run_cmd, ensure_dir, write_file, add_gitkeep, confirm,
#   get_script_dir, get_project_root
#
# Dependencies:
#   lib/logging.sh
# =============================================================================

# Guard against double-sourcing
[[ -n "${_LIB_UTILS_LOADED:-}" ]] && return 0
_LIB_UTILS_LOADED=1

# =============================================================================
# CONFIGURATION DEFAULTS
# =============================================================================

: "${DRY_RUN:=false}"
: "${MAX_CMD_SECONDS:=900}"

# =============================================================================
# COMMAND EXECUTION
# =============================================================================

# Execute command or log in dry-run mode (with optional timeout)
# Usage: run_cmd "pnpm install"
run_cmd() {
    local cmd="$*"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry "$cmd"
        return 0
    fi

    local max_seconds="${MAX_CMD_SECONDS:-0}"
    if [[ "$max_seconds" != "0" ]] && command -v timeout &> /dev/null; then
        log_debug "RUN (timeout ${max_seconds}s): $cmd"
        timeout "${max_seconds}" bash -lc "$cmd"
    else
        log_debug "RUN: $cmd"
        eval "$cmd"
    fi
}

# =============================================================================
# DIRECTORY OPERATIONS
# =============================================================================

# Create directory with dry-run support
# Usage: ensure_dir "/path/to/dir"
ensure_dir() {
    local dir="$1"

    if [[ -d "$dir" ]]; then
        log_debug "Directory exists: $dir"
        return 0
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry "mkdir -p $dir"
    else
        mkdir -p "$dir"
        log_success "Created directory: $dir"
    fi
}

# Create .gitkeep in empty directory
# Usage: add_gitkeep "/path/to/dir"
add_gitkeep() {
    local dir="$1"
    ensure_dir "$dir"

    local gitkeep="$dir/.gitkeep"
    if [[ ! -f "$gitkeep" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            log_dry "touch $gitkeep"
        else
            touch "$gitkeep"
            log_debug "Created .gitkeep in $dir"
        fi
    fi
}

# =============================================================================
# FILE OPERATIONS
# =============================================================================

# Create file with content (dry-run aware)
# Usage: write_file "/path/to/file" "content" [force]
write_file() {
    local file_path="$1"
    local content="$2"
    local force="${3:-false}"

    if [[ -f "$file_path" && "$force" != "true" ]]; then
        log_skip "File exists: $file_path"
        return 0
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry "Create file: $file_path"
        return 0
    fi

    # Ensure parent directory exists
    mkdir -p "$(dirname "$file_path")"

    echo "$content" > "$file_path"
    log_success "Created file: $file_path"
}

# Write file only if it doesn't exist
# Usage: write_file_if_missing "/path/to/file" "content"
write_file_if_missing() {
    local file_path="$1"
    local content="$2"
    write_file "$file_path" "$content" "false"
}

# Append to file (dry-run aware)
# Usage: append_file "/path/to/file" "content"
append_file() {
    local file_path="$1"
    local content="$2"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry "Append to file: $file_path"
        return 0
    fi

    echo "$content" >> "$file_path"
    log_success "Appended to: $file_path"
}

# =============================================================================
# PATH RESOLUTION
# =============================================================================

# Get directory of the calling script
# Usage: SCRIPT_DIR="$(get_script_dir)"
get_script_dir() {
    cd "$(dirname "${BASH_SOURCE[1]}")" && pwd
}

# Get project root (assumes scripts are in _build/omniforge/)
# Usage: PROJECT_ROOT="$(get_project_root)"
get_project_root() {
    local script_dir
    script_dir="$(get_script_dir)"
    echo "$(cd "$script_dir/../.." && pwd)"
}

# =============================================================================
# USER INTERACTION
# =============================================================================

# Confirm action with user (skipped in dry-run)
# Usage: confirm "Continue?" && do_something
confirm() {
    local message="${1:-Continue?}"

    if [[ "$DRY_RUN" == "true" ]]; then
        return 0
    fi

    read -r -p "$message [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# =============================================================================
# ERROR HANDLING
# =============================================================================

# Trap for cleanup on error
cleanup_on_error() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        log_error "Script failed with exit code: $exit_code"
    fi
}

# Set up error trap
# Usage: setup_error_trap
setup_error_trap() {
    trap cleanup_on_error EXIT
}

# =============================================================================
# OS DETECTION
# =============================================================================

# Detect OS type (darwin, linux, etc.)
get_os_type() {
    uname -s | tr '[:upper:]' '[:lower:]'
}

# Export for subshells
export DRY_RUN MAX_CMD_SECONDS
