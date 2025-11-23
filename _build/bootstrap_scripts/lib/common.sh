#!/usr/bin/env bash
# =============================================================================
# lib/common.sh - Master loader for all library modules
# =============================================================================
# This file sources all modular library files in the correct order.
# Usage: source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
#
# After sourcing, all library functions are available:
#   - Logging:    log_info, log_warn, log_error, log_debug, log_step, etc.
#   - Config:     config_load, config_validate, config_apply_profile
#   - Phases:     phase_discover, phase_execute, phase_execute_all
#   - Packages:   pkg_expand, pkg_add_dependency, pkg_add_script
#   - State:      state_mark_success, state_has_succeeded, state_clear
#   - Git:        git_ensure_clean, git_is_repo, git_current_branch
#   - Validation: require_cmd, require_node_version, require_pnpm
#   - Utils:      run_cmd, ensure_dir, write_file, confirm
# =============================================================================

# Guard against double-sourcing
[[ -n "${_LIB_COMMON_LOADED:-}" ]] && return 0
_LIB_COMMON_LOADED=1

# Strict mode
set -euo pipefail
IFS=$'\n\t'

# =============================================================================
# PATH DETECTION
# =============================================================================

# Detect the directory containing this file
_COMMON_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Scripts directory is parent of lib
SCRIPTS_DIR="${SCRIPTS_DIR:-${_COMMON_LIB_DIR%/lib}}"

# Config file paths (can be overridden before sourcing)
: "${BOOTSTRAP_CONF:=${SCRIPTS_DIR}/bootstrap.conf}"
: "${BOOTSTRAP_CONF_EXAMPLE:=${SCRIPTS_DIR}/bootstrap.conf.example}"

# Export for use by libraries
export SCRIPTS_DIR BOOTSTRAP_CONF BOOTSTRAP_CONF_EXAMPLE

# =============================================================================
# SOURCE ALL LIBRARY MODULES (order matters!)
# =============================================================================

# 1. Logging must be first (other modules use log_* functions)
source "${_COMMON_LIB_DIR}/logging.sh"

# 2. Validation helpers (no dependencies beyond logging)
source "${_COMMON_LIB_DIR}/validation.sh"

# 3. Utils (depends on logging)
source "${_COMMON_LIB_DIR}/utils.sh"

# 4. Config loading (depends on logging)
source "${_COMMON_LIB_DIR}/config_bootstrap.sh"

# 5. State tracking (depends on logging)
source "${_COMMON_LIB_DIR}/state.sh"

# 6. Git safety (depends on logging)
source "${_COMMON_LIB_DIR}/git.sh"

# 7. Package management (depends on logging)
source "${_COMMON_LIB_DIR}/packages.sh"

# 8. Phase management (depends on logging, state, packages)
source "${_COMMON_LIB_DIR}/phases.sh"

# =============================================================================
# BACKWARD COMPATIBILITY ALIASES
# =============================================================================
# These aliases map old function names to new modular names for scripts
# that haven't been updated yet. Remove after migration is complete.

# Logging aliases (all functions have same names, no change needed)

# Config aliases
_init_config() { config_load && config_validate; }

# State aliases
init_state_file() { state_init; }
mark_script_success() { state_mark_success "$@"; }
has_script_succeeded() { state_has_succeeded "$@"; }
clear_script_state() { state_clear "$@"; }

# Git aliases
ensure_git_clean() { git_ensure_clean; }

# Package aliases
has_dependency() { pkg_has_dependency "$@"; }
add_dependency() { pkg_add_dependency "$@"; }
add_npm_script() { pkg_add_script "$@"; }
update_pkg_field() { pkg_update_field "$@"; }

# Profile aliases
apply_stack_profile() { config_apply_profile; }

# =============================================================================
# ARGUMENT PARSING (commonly used, keep in common.sh)
# =============================================================================

# Parse common arguments
parse_common_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -n|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            *)
                # Unknown option, let script handle it
                break
                ;;
        esac
    done
}

# =============================================================================
# EXPORTS
# =============================================================================

export DRY_RUN VERBOSE LOG_FILE LOG_DIR
