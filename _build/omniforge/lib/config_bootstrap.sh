#!/usr/bin/env bash
# =============================================================================
# lib/config_bootstrap.sh - Configuration Loading & Validation
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Pure functions for loading OmniForge configuration. No execution on source.
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
: "${SCRIPTS_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
: "${OMNI_CONFIG_PATH:=${SCRIPTS_DIR}/omni.config}"
: "${OMNI_SETTINGS_PATH:=${SCRIPTS_DIR}/omni.settings.sh}"
: "${OMNI_PROFILES_PATH:=${SCRIPTS_DIR}/omni.profiles.sh}"
: "${OMNI_PHASES_PATH:=${SCRIPTS_DIR}/omni.phases.sh}"
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
    log_info "Configuration saved to omni.config"
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

    # Determine canonical config paths
    local omni_config_path="${OMNI_CONFIG_PATH:-${SCRIPTS_DIR}/omni.config}"
    local omni_settings_path="${OMNI_SETTINGS_PATH:-${SCRIPTS_DIR}/omni.settings.sh}"
    local omni_profiles_path="${OMNI_PROFILES_PATH:-${SCRIPTS_DIR}/omni.profiles.sh}"
    local omni_phases_path="${OMNI_PHASES_PATH:-${SCRIPTS_DIR}/omni.phases.sh}"

    # Require omni.config (Section 1)
    if [[ ! -f "$omni_config_path" ]]; then
        log_error "omni.config not found at $omni_config_path (Section 1 must live in omni.config)"
        return 1
    fi
    # Require omni.settings (advanced/system)
    if [[ ! -f "$omni_settings_path" ]]; then
        log_error "omni.settings.sh not found at $omni_settings_path (advanced settings are required)"
        return 1
    fi
    # Require profile and phase data
    if [[ ! -f "$omni_profiles_path" ]]; then
        log_error "omni.profiles.sh not found at $omni_profiles_path (profile data is required)"
        return 1
    fi
    if [[ ! -f "$omni_phases_path" ]]; then
        log_error "omni.phases.sh not found at $omni_phases_path (phase metadata is required)"
        return 1
    fi

    # Save environment overrides (allow env vars to override config)
    local section1_vars=(
        APP_NAME APP_VERSION APP_DESCRIPTION
        INSTALL_TARGET STACK_PROFILE
        DB_NAME DB_USER DB_PASSWORD DB_HOST DB_PORT
        ENABLE_AUTHJS ENABLE_AI_SDK ENABLE_PG_BOSS ENABLE_SHADCN
        ENABLE_ZUSTAND ENABLE_PDF_EXPORTS ENABLE_TEST_INFRA ENABLE_CODE_QUALITY
    )
    declare -A saved_section1_env=()
    for v in "${section1_vars[@]}"; do
        if [[ -n "${v}" && -n "${!v+x}" ]]; then
            saved_section1_env["$v"]="${!v}"
        fi
    done
    local saved_dry_run="${DRY_RUN:-}"
    local saved_allow_dirty="${ALLOW_DIRTY:-}"
    local saved_git_safety="${GIT_SAFETY:-}"
    local saved_verbose="${VERBOSE:-}"
    local saved_log_format="${LOG_FORMAT:-}"

    # Source the configuration (omni.*)
    # shellcheck source=/dev/null
    source "$omni_config_path"
    # shellcheck source=/dev/null
    source "$omni_settings_path"
    # shellcheck source=/dev/null
    source "$omni_profiles_path"
    # shellcheck source=/dev/null
    source "$omni_phases_path"

    # Restore environment overrides (env vars take precedence over config file)
    for v in "${section1_vars[@]}"; do
        if [[ -n "${saved_section1_env[$v]+x}" ]]; then
            export "${v}=${saved_section1_env[$v]}"
        fi
    done
    [[ -n "${saved_dry_run}" ]] && DRY_RUN="${saved_dry_run}"
    [[ -n "${saved_allow_dirty}" ]] && ALLOW_DIRTY="${saved_allow_dirty}"
    [[ -n "${saved_git_safety}" ]] && GIT_SAFETY="${saved_git_safety}"
    [[ -n "${saved_verbose}" ]] && VERBOSE="${saved_verbose}"
    [[ -n "${saved_log_format}" ]] && LOG_FORMAT="${saved_log_format}"
    unset section1_vars saved_section1_env v omni_config_path

    # Set defaults for optional vars
    : "${DRY_RUN:=false}"
    : "${LOG_FORMAT:=plain}"
    : "${MAX_CMD_SECONDS:=900}"
    : "${BOOTSTRAP_RESUME_MODE:=skip}"
    : "${GIT_SAFETY:=true}"
    : "${ALLOW_DIRTY:=false}"
    : "${STACK_PROFILE:=full}"

    # Derived values
    if [[ "${PROJECT_ROOT:-.}" == "." ]]; then
        PROJECT_ROOT="$(cd "${SCRIPTS_DIR}/../.." && pwd)"
    fi
    if [[ -z "${INSTALL_DIR+x}" ]]; then
        if [[ "${INSTALL_TARGET:-test}" == "prod" ]]; then
            INSTALL_DIR="${INSTALL_DIR_PROD}"
        else
            INSTALL_DIR="${INSTALL_DIR_TEST}"
        fi
    fi
    : "${OMNIFORGE_SETUP_MARKER:=${PROJECT_ROOT}/.omniforge_setup_complete}"
    : "${BOOTSTRAP_STATE_FILE:=${PROJECT_ROOT}/.bootstrap_state}"
    : "${GIT_REMOTE_URL:=${GIT_REMOTE_URL:-}}"

    log_debug "Configuration loaded from omni.* files"
    return 0
}

# Validate critical configuration values
# Usage: config_validate
config_validate() {
    # Validate PROJECT_ROOT exists
    if [[ -z "${PROJECT_ROOT:-}" ]]; then
        log_error "PROJECT_ROOT not set in config"
        return 1
    fi

    # Resolve PROJECT_ROOT if relative (. means relative to omniforge parent)
    if [[ "${PROJECT_ROOT}" == "." ]]; then
        # Assumes we're in _build/omniforge, so ../.. is project root
        local script_parent
        script_parent="${SCRIPTS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
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

# Apply stack profile settings
# Handles BOS profiles: ai_automation, fpa_dashboard, collab_editor,
# erp_gateway, asset_manager, custom_bos
# Note: The data-driven apply_stack_profile() from bootstrap.conf uses
# associative arrays which don't survive being sourced inside a function.
# This fallback provides the same functionality with explicit case handling.
# Usage: config_apply_profile
config_apply_profile() {
    local profile="${STACK_PROFILE:-asset_manager}"

    # Apply profile settings directly (associative arrays from bootstrap.conf
    # are not available here due to function scoping of 'declare -A')
    case "$profile" in
        minimal|custom_bos)
            log_info "Applying minimal stack profile"
            export ENABLE_AUTHJS="${ENABLE_AUTHJS:-false}"
            export ENABLE_AI_SDK="${ENABLE_AI_SDK:-false}"
            export ENABLE_PG_BOSS="${ENABLE_PG_BOSS:-false}"
            export ENABLE_PDF_EXPORTS="${ENABLE_PDF_EXPORTS:-false}"
            export ENABLE_SHADCN="${ENABLE_SHADCN:-false}"
            ;;
        api-only|erp_gateway)
            log_info "Applying api-only stack profile"
            export ENABLE_AUTHJS="${ENABLE_AUTHJS:-true}"
            export ENABLE_AI_SDK="${ENABLE_AI_SDK:-false}"
            export ENABLE_PG_BOSS="${ENABLE_PG_BOSS:-true}"
            export ENABLE_PDF_EXPORTS="${ENABLE_PDF_EXPORTS:-false}"
            export ENABLE_SHADCN="${ENABLE_SHADCN:-false}"
            ;;
        full|enterprise|asset_manager|fpa_dashboard)
            log_debug "Using full stack profile (all features enabled)"
            export ENABLE_AUTHJS="${ENABLE_AUTHJS:-true}"
            export ENABLE_AI_SDK="${ENABLE_AI_SDK:-false}"
            export ENABLE_PG_BOSS="${ENABLE_PG_BOSS:-true}"
            export ENABLE_PDF_EXPORTS="${ENABLE_PDF_EXPORTS:-true}"
            export ENABLE_SHADCN="${ENABLE_SHADCN:-true}"
            export ENABLE_ZUSTAND="${ENABLE_ZUSTAND:-true}"
            ;;
        ai_automation)
            log_info "Applying AI Automation profile"
            export ENABLE_AUTHJS="${ENABLE_AUTHJS:-true}"
            export ENABLE_AI_SDK="${ENABLE_AI_SDK:-true}"
            export ENABLE_PG_BOSS="${ENABLE_PG_BOSS:-true}"
            export ENABLE_PDF_EXPORTS="${ENABLE_PDF_EXPORTS:-false}"
            export ENABLE_SHADCN="${ENABLE_SHADCN:-true}"
            export ENABLE_ZUSTAND="${ENABLE_ZUSTAND:-false}"
            ;;
        collab_editor)
            log_info "Applying Collab Editor profile"
            export ENABLE_AUTHJS="${ENABLE_AUTHJS:-true}"
            export ENABLE_AI_SDK="${ENABLE_AI_SDK:-false}"
            export ENABLE_PG_BOSS="${ENABLE_PG_BOSS:-true}"
            export ENABLE_PDF_EXPORTS="${ENABLE_PDF_EXPORTS:-false}"
            export ENABLE_SHADCN="${ENABLE_SHADCN:-true}"
            export ENABLE_ZUSTAND="${ENABLE_ZUSTAND:-true}"
            ;;
        *)
            log_warn "Unknown stack profile: $profile, using asset_manager defaults"
            ;;
    esac
}

# Export key variables for child processes (tech_stack scripts run in subshells)
export DRY_RUN LOG_FORMAT MAX_CMD_SECONDS BOOTSTRAP_RESUME_MODE
export GIT_SAFETY ALLOW_DIRTY STACK_PROFILE PROJECT_ROOT

# Export app configuration
export APP_NAME APP_VERSION APP_DESCRIPTION INSTALL_DIR INSTALL_TARGET

# Export database configuration
export DB_NAME DB_USER DB_PASSWORD DB_HOST DB_PORT

# Export version requirements
export NODE_VERSION PNPM_VERSION NEXT_VERSION POSTGRES_VERSION

# Export feature flags
export ENABLE_NEXTJS ENABLE_DATABASE ENABLE_AUTHJS ENABLE_AI_SDK
export ENABLE_PG_BOSS ENABLE_SHADCN ENABLE_ZUSTAND ENABLE_PDF_EXPORTS
export ENABLE_TEST_INFRA ENABLE_CODE_QUALITY ENABLE_DOCKER ENABLE_REDIS

# Export directory structure
export SRC_DIR SRC_APP_DIR SRC_COMPONENTS_DIR SRC_LIB_DIR SRC_DB_DIR
export SRC_STYLES_DIR SRC_HOOKS_DIR SRC_TYPES_DIR SRC_STORES_DIR SRC_TEST_DIR
export PUBLIC_DIR TEST_DIR E2E_DIR

# Export package versions (PKG_* variables used by tech_stack scripts)
export PKG_NEXT PKG_REACT PKG_REACT_DOM PKG_TYPESCRIPT PKG_TYPES_NODE PKG_TYPES_REACT PKG_TYPES_REACT_DOM
export PKG_DRIZZLE_ORM PKG_DRIZZLE_KIT PKG_POSTGRES_JS PKG_TSX PKG_ZOD PKG_T3_ENV
export PKG_NEXT_AUTH PKG_AUTH_DRIZZLE_ADAPTER PKG_BCRYPTJS PKG_TYPES_BCRYPTJS
export PKG_VERCEL_AI PKG_AI_SDK_OPENAI PKG_AI_SDK_ANTHROPIC
export PKG_ZUSTAND PKG_IMMER PKG_CLSX PKG_TAILWIND_MERGE PKG_CLASS_VARIANCE_AUTHORITY
export PKG_LUCIDE_REACT PKG_REACT_TO_PRINT PKG_TAILWINDCSS PKG_POSTCSS PKG_AUTOPREFIXER
export PKG_PG_BOSS PKG_PINO PKG_PINO_PRETTY
export PKG_JSPDF PKG_HTML2CANVAS PKG_EXCELJS PKG_TYPES_EXCELJS
export PKG_MARKDOWN_IT PKG_REMARK PKG_REMARK_HTML
export PKG_VITEST PKG_VITEJS_PLUGIN_REACT PKG_TESTING_LIBRARY_REACT PKG_TESTING_LIBRARY_JEST_DOM
export PKG_JSDOM PKG_PLAYWRIGHT
export PKG_ESLINT PKG_ESLINT_CONFIG_PRETTIER PKG_ESLINT_PLUGIN_JSX_A11Y
export PKG_TYPESCRIPT_ESLINT_PLUGIN PKG_TYPESCRIPT_ESLINT_PARSER
export PKG_PRETTIER PKG_PRETTIER_PLUGIN_TAILWIND PKG_HUSKY PKG_LINT_STAGED

# Export OmniForge paths
export SCRIPTS_DIR BOOTSTRAP_CONF LOG_FILE LOG_DIR
