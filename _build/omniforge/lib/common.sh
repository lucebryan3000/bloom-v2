#!/usr/bin/env bash
# =============================================================================
# lib/common.sh - Master Loader for All Library Modules
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# This file sources all modular library files in the correct order.
# Usage: source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
#
# Exports (after sourcing):
#   - Logging:    log_info, log_warn, log_error, log_debug, log_step, etc.
#   - Config:     config_load, config_validate, config_apply_profile
#   - Phases:     phase_discover, phase_execute, phase_execute_all
#   - Packages:   pkg_expand, pkg_add_dependency, pkg_add_script
#   - State:      state_mark_success, state_has_succeeded, state_clear
#   - Git:        git_ensure_clean, git_is_repo, git_current_branch
#   - Validation: require_cmd, require_node_version, require_pnpm
#   - Utils:      run_cmd, ensure_dir, write_file, confirm
#
# Dependencies:
#   All lib/*.sh files (sourced in dependency order)
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

# 2. Log rotation utilities (depends on logging)
source "${_COMMON_LIB_DIR}/log-rotation.sh"

# 3. Validation helpers (no dependencies beyond logging)
source "${_COMMON_LIB_DIR}/validation.sh"

# 4. Utils (depends on logging)
source "${_COMMON_LIB_DIR}/utils.sh"

# 5. Config loading (depends on logging)
source "${_COMMON_LIB_DIR}/config_bootstrap.sh"

# 6. State tracking (depends on logging)
source "${_COMMON_LIB_DIR}/state.sh"

# 7. Git safety (depends on logging)
source "${_COMMON_LIB_DIR}/git.sh"

# 8. Package management (depends on logging)
source "${_COMMON_LIB_DIR}/packages.sh"

# 9. Phase management (depends on logging, state, packages)
source "${_COMMON_LIB_DIR}/phases.sh"

# 10. Prerequisites (depends on logging) - for background installation
source "${_COMMON_LIB_DIR}/prereqs.sh"

# 10b. Local Prerequisites (depends on logging) - for project-local tool installation
source "${_COMMON_LIB_DIR}/prereqs-local.sh"

# 10c. Project Scaffolding (depends on logging) - for template deployment
source "${_COMMON_LIB_DIR}/scaffold.sh"

# 10d. OmniForge Setup (depends on logging, scaffold) - for one-time project initialization
source "${_COMMON_LIB_DIR}/setup.sh"

# 11. Configuration validation (depends on logging)
source "${_COMMON_LIB_DIR}/config_validate.sh"

# 12. Setup wizard (depends on logging, config_bootstrap)
source "${_COMMON_LIB_DIR}/setup_wizard.sh"

# 13. Configuration bakes/presets (depends on logging)
source "${_COMMON_LIB_DIR}/bakes.sh"

# 14. Script indexer (depends on logging) - for background script discovery
source "${_COMMON_LIB_DIR}/indexer.sh"

# 15. ASCII art and branding (depends on logging)
source "${_COMMON_LIB_DIR}/ascii.sh"

# 16. Download cache system (depends on logging)
source "${_COMMON_LIB_DIR}/downloads.sh"

# 17. Sequencer for test criteria and timeouts (depends on logging)
source "${_COMMON_LIB_DIR}/sequencer.sh"

# 18. Settings manager for IDE configs (depends on logging)
source "${_COMMON_LIB_DIR}/settings_manager.sh"

# 19. Interactive menu framework (depends on logging, ascii, downloads)
source "${_COMMON_LIB_DIR}/menu.sh"

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
