#!/usr/bin/env bash
# =============================================================================
# lib/config_bootstrap.sh - Configuration Loading & Validation
# =============================================================================
# Part of OmniForge - The Factory That Builds Universes
#
# Pure functions for loading bootstrap.conf. No execution on source.
#
# Exports:
#   config_load, config_validate, config_apply_profile
#
# Dependencies:
#   lib/logging.sh
# =============================================================================

# Guard against double-sourcing
[[ -n "${_LIB_CONFIG_LOADED:-}" ]] && return 0
_LIB_CONFIG_LOADED=1

# =============================================================================
# CONFIGURATION PATHS (set by caller or defaults)
# =============================================================================

# These should be set by the entry script before sourcing
: "${BOOTSTRAP_CONF:=}"
: "${BOOTSTRAP_CONF_EXAMPLE:=}"
: "${NON_INTERACTIVE:=false}"

# =============================================================================
# FIRST-RUN CONFIGURATION
# =============================================================================

# Run first-time setup using the setup wizard
# This is called when no bootstrap.conf exists
_config_first_run() {
    # Check if setup wizard is available
    if type setup_run_first_time &>/dev/null; then
        setup_run_first_time "${BOOTSTRAP_CONF}" "${BOOTSTRAP_CONF_EXAMPLE}"
        return $?
    fi

    # Fallback: basic prompts if wizard not loaded
    _config_first_run_basic
}

# Basic first-run prompts (fallback if wizard unavailable)
_config_first_run_basic() {
    if [[ "${NON_INTERACTIVE:-false}" == "true" ]]; then
        return 0
    fi

    echo ""
    log_info "=== First-Run Configuration ==="
    log_info "Customize your project settings (press Enter to keep defaults):"
    echo ""

    _config_prompt_basic "APP_NAME" "Application name" "bloom2"
    _config_prompt_basic "PROJECT_ROOT" "Project root directory" "."
    _config_prompt_basic "DB_NAME" "Database name" "bloom2_db"
    _config_prompt_basic "DB_USER" "Database user" "bloom2"
    _config_prompt_basic "DB_PASSWORD" "Database password" "change_me"

    echo ""
    log_info "Configuration saved to bootstrap.conf"
    echo ""
}

# Basic prompt helper (used by fallback)
_config_prompt_basic() {
    local var_name="$1"
    local prompt_text="$2"
    local default_val="$3"

    if [[ "${NON_INTERACTIVE:-false}" == "true" ]]; then
        return 0
    fi

    local new_val
    read -rp "${prompt_text} [${default_val}]: " new_val

    if [[ -n "${new_val}" ]]; then
        local sed_cmd="sed -i"
        [[ "$(uname)" == "Darwin" ]] && sed_cmd="sed -i ''"
        $sed_cmd "s|^${var_name}=.*|${var_name}=\"${new_val}\"|" "${BOOTSTRAP_CONF}"
    fi
}

# =============================================================================
# CONFIG LOADING
# =============================================================================

# Load configuration from bootstrap.conf
# Usage: config_load
config_load() {
    log_debug "Loading configuration..."

    # Check if config file exists
    if [[ ! -f "${BOOTSTRAP_CONF}" ]]; then
        if [[ -f "${BOOTSTRAP_CONF_EXAMPLE}" ]]; then
            log_info "First run detected - copying bootstrap.conf.example to bootstrap.conf"
            cp "${BOOTSTRAP_CONF_EXAMPLE}" "${BOOTSTRAP_CONF}"
            _config_first_run
        else
            log_error "Configuration file not found: ${BOOTSTRAP_CONF}"
            log_error "Also no example file found at: ${BOOTSTRAP_CONF_EXAMPLE}"
            return 1
        fi
    fi

    # Save environment overrides (allow env vars to override config)
    local saved_dry_run="${DRY_RUN:-}"
    local saved_allow_dirty="${ALLOW_DIRTY:-}"
    local saved_git_safety="${GIT_SAFETY:-}"
    local saved_verbose="${VERBOSE:-}"
    local saved_log_format="${LOG_FORMAT:-}"

    # Source the configuration
    # shellcheck source=/dev/null
    source "${BOOTSTRAP_CONF}"

    # Restore environment overrides (env vars take precedence over config file)
    [[ -n "${saved_dry_run}" ]] && DRY_RUN="${saved_dry_run}"
    [[ -n "${saved_allow_dirty}" ]] && ALLOW_DIRTY="${saved_allow_dirty}"
    [[ -n "${saved_git_safety}" ]] && GIT_SAFETY="${saved_git_safety}"
    [[ -n "${saved_verbose}" ]] && VERBOSE="${saved_verbose}"
    [[ -n "${saved_log_format}" ]] && LOG_FORMAT="${saved_log_format}"

    # Set defaults for optional vars
    : "${DRY_RUN:=false}"
    : "${LOG_FORMAT:=plain}"
    : "${MAX_CMD_SECONDS:=900}"
    : "${BOOTSTRAP_RESUME_MODE:=skip}"
    : "${GIT_SAFETY:=true}"
    : "${ALLOW_DIRTY:=false}"
    : "${STACK_PROFILE:=full}"

    log_debug "Configuration loaded from: ${BOOTSTRAP_CONF}"
    return 0
}

# Validate critical configuration values
# Usage: config_validate
config_validate() {
    # Validate PROJECT_ROOT exists
    if [[ -z "${PROJECT_ROOT:-}" ]]; then
        log_error "PROJECT_ROOT not set in bootstrap.conf"
        return 1
    fi

    # Resolve PROJECT_ROOT if relative (. means relative to omniforge parent)
    if [[ "${PROJECT_ROOT}" == "." ]]; then
        # Assumes we're in _build/omniforge, so ../.. is project root
        local script_parent
        script_parent="$(dirname "${BOOTSTRAP_CONF}")"
        PROJECT_ROOT="$(cd "${script_parent}/../.." 2>/dev/null && pwd)"
    fi

    if [[ ! -d "${PROJECT_ROOT}" ]]; then
        log_error "PROJECT_ROOT does not exist: ${PROJECT_ROOT}"
        return 1
    fi

    # Validate password in non-interactive mode
    if [[ "${NON_INTERACTIVE:-false}" == "true" ]]; then
        if [[ "${DB_PASSWORD:-}" == "change_me" ]]; then
            log_error "DB_PASSWORD is still 'change_me' in NON_INTERACTIVE mode"
            return 1
        fi
    fi

    log_debug "PROJECT_ROOT: ${PROJECT_ROOT}"
    return 0
}

# =============================================================================
# STACK PROFILES
# =============================================================================

# Apply stack profile settings (minimal, api-only, full)
# Usage: config_apply_profile
config_apply_profile() {
    local profile="${STACK_PROFILE:-full}"

    case "$profile" in
        minimal)
            log_info "Applying minimal stack profile"
            export ENABLE_AUTHJS="${ENABLE_AUTHJS:-false}"
            export ENABLE_AI_SDK="${ENABLE_AI_SDK:-false}"
            export ENABLE_PG_BOSS="${ENABLE_PG_BOSS:-false}"
            export ENABLE_PDF_EXPORTS="${ENABLE_PDF_EXPORTS:-false}"
            export ENABLE_SHADCN="${ENABLE_SHADCN:-false}"
            ;;
        api-only)
            log_info "Applying api-only stack profile"
            export ENABLE_AUTHJS="${ENABLE_AUTHJS:-false}"
            export ENABLE_AI_SDK="${ENABLE_AI_SDK:-false}"
            export ENABLE_PG_BOSS="${ENABLE_PG_BOSS:-false}"
            export ENABLE_PDF_EXPORTS="${ENABLE_PDF_EXPORTS:-false}"
            export ENABLE_SHADCN="${ENABLE_SHADCN:-false}"
            export ENABLE_UI="${ENABLE_UI:-false}"
            ;;
        full)
            log_debug "Using full stack profile (all features enabled)"
            ;;
        *)
            log_warn "Unknown stack profile: $profile, using full"
            ;;
    esac
}

# Export key variables
export DRY_RUN LOG_FORMAT MAX_CMD_SECONDS BOOTSTRAP_RESUME_MODE
export GIT_SAFETY ALLOW_DIRTY STACK_PROFILE PROJECT_ROOT
