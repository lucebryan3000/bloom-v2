#!/usr/bin/env bash
# =============================================================================
# lib/config_validate.sh - Enhanced Configuration Validation
# =============================================================================
# Part of OmniForge - The Factory That Builds Universes
#
# Provides comprehensive validation of bootstrap.conf settings before
# execution. Validates types, ranges, required fields, and cross-field
# dependencies.
#
# Exports:
#   config_validate_all, config_validate_field, config_suggest_fixes,
#   config_show_summary
#
# Dependencies:
#   lib/logging.sh
# =============================================================================

# Guard against double-sourcing
[[ -n "${_LIB_CONFIG_VALIDATE_LOADED:-}" ]] && return 0
_LIB_CONFIG_VALIDATE_LOADED=1

# =============================================================================
# VALIDATION RESULT TRACKING
# =============================================================================

declare -g _VALIDATION_ERRORS=()
declare -g _VALIDATION_WARNINGS=()

_validation_reset() {
    _VALIDATION_ERRORS=()
    _VALIDATION_WARNINGS=()
}

_validation_error() {
    local field="$1"
    local message="$2"
    _VALIDATION_ERRORS+=("$field: $message")
}

_validation_warn() {
    local field="$1"
    local message="$2"
    _VALIDATION_WARNINGS+=("$field: $message")
}

# =============================================================================
# FIELD VALIDATORS
# =============================================================================

# Validate APP_NAME
_validate_app_name() {
    local value="${APP_NAME:-}"

    if [[ -z "$value" ]]; then
        _validation_error "APP_NAME" "Required field is empty"
        return 1
    fi

    if [[ ! "$value" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then
        _validation_error "APP_NAME" "Must start with letter, contain only letters, numbers, -, _"
        return 1
    fi

    if [[ ${#value} -gt 50 ]]; then
        _validation_warn "APP_NAME" "Very long name may cause issues (${#value} chars)"
    fi

    return 0
}

# Validate PROJECT_ROOT
_validate_project_root() {
    local value="${PROJECT_ROOT:-}"

    if [[ -z "$value" ]]; then
        _validation_error "PROJECT_ROOT" "Required field is empty"
        return 1
    fi

    # Resolve relative paths
    if [[ "$value" == "." ]]; then
        return 0  # Will be resolved later
    fi

    if [[ ! -d "$value" ]]; then
        _validation_error "PROJECT_ROOT" "Directory does not exist: $value"
        return 1
    fi

    if [[ ! -w "$value" ]]; then
        _validation_error "PROJECT_ROOT" "Directory is not writable: $value"
        return 1
    fi

    return 0
}

# Validate STACK_PROFILE
_validate_stack_profile() {
    local value="${STACK_PROFILE:-}"

    case "$value" in
        minimal|api-only|full)
            return 0
            ;;
        "")
            _validation_warn "STACK_PROFILE" "Not set, defaulting to 'full'"
            ;;
        *)
            _validation_error "STACK_PROFILE" "Invalid value '$value'. Must be: minimal, api-only, or full"
            return 1
            ;;
    esac
}

# Validate database configuration
_validate_database() {
    local errors=0

    # DB_NAME
    if [[ -z "${DB_NAME:-}" ]]; then
        _validation_error "DB_NAME" "Required field is empty"
        ((errors++))
    elif [[ ! "${DB_NAME}" =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]; then
        _validation_error "DB_NAME" "Invalid database name format"
        ((errors++))
    fi

    # DB_USER
    if [[ -z "${DB_USER:-}" ]]; then
        _validation_error "DB_USER" "Required field is empty"
        ((errors++))
    elif [[ ! "${DB_USER}" =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]; then
        _validation_error "DB_USER" "Invalid username format"
        ((errors++))
    fi

    # DB_PASSWORD
    if [[ -z "${DB_PASSWORD:-}" ]]; then
        _validation_error "DB_PASSWORD" "Required field is empty"
        ((errors++))
    elif [[ "${DB_PASSWORD}" == "change_me" ]]; then
        if [[ "${NON_INTERACTIVE:-false}" == "true" ]]; then
            _validation_error "DB_PASSWORD" "Still set to 'change_me' in non-interactive mode"
            ((errors++))
        else
            _validation_warn "DB_PASSWORD" "Still set to default 'change_me'"
        fi
    elif [[ ${#DB_PASSWORD} -lt 8 ]]; then
        _validation_warn "DB_PASSWORD" "Weak password (less than 8 characters)"
    fi

    # DB_PORT
    local port="${DB_PORT:-5432}"
    if [[ ! "$port" =~ ^[0-9]+$ ]]; then
        _validation_error "DB_PORT" "Must be a number"
        ((errors++))
    elif [[ "$port" -lt 1 || "$port" -gt 65535 ]]; then
        _validation_error "DB_PORT" "Must be between 1 and 65535"
        ((errors++))
    elif [[ "$port" -lt 1024 ]]; then
        _validation_warn "DB_PORT" "Port $port requires root privileges"
    fi

    return $errors
}

# Validate version numbers
_validate_versions() {
    # NODE_VERSION
    local node_ver="${NODE_VERSION:-20}"
    if [[ ! "$node_ver" =~ ^[0-9]+$ ]]; then
        _validation_error "NODE_VERSION" "Must be a major version number (e.g., 20)"
    elif [[ "$node_ver" -lt 18 ]]; then
        _validation_warn "NODE_VERSION" "Version $node_ver is below recommended minimum (18)"
    fi

    # PNPM_VERSION
    local pnpm_ver="${PNPM_VERSION:-9}"
    if [[ ! "$pnpm_ver" =~ ^[0-9]+$ ]]; then
        _validation_error "PNPM_VERSION" "Must be a major version number (e.g., 9)"
    fi

    # Check if installed versions match
    if command -v node &>/dev/null; then
        local installed_node
        installed_node=$(node --version 2>/dev/null | sed 's/v//' | cut -d. -f1)
        if [[ "$installed_node" -lt "$node_ver" ]]; then
            _validation_warn "NODE_VERSION" "Installed version ($installed_node) is older than configured ($node_ver)"
        fi
    fi
}

# Validate feature flags
_validate_feature_flags() {
    local flags=(
        "ENABLE_AUTHJS"
        "ENABLE_AI_SDK"
        "ENABLE_PG_BOSS"
        "ENABLE_SHADCN"
        "ENABLE_ZUSTAND"
        "ENABLE_PDF_EXPORTS"
        "ENABLE_TEST_INFRA"
        "ENABLE_CODE_QUALITY"
    )

    for flag in "${flags[@]}"; do
        local value="${!flag:-}"
        if [[ -n "$value" && "$value" != "true" && "$value" != "false" ]]; then
            _validation_error "$flag" "Must be 'true' or 'false', got '$value'"
        fi
    done

    # Cross-validation: ENABLE_PDF_EXPORTS needs ENABLE_SHADCN for UI
    if [[ "${ENABLE_PDF_EXPORTS:-false}" == "true" && "${ENABLE_SHADCN:-true}" == "false" ]]; then
        _validation_warn "ENABLE_PDF_EXPORTS" "PDF exports work best with ENABLE_SHADCN=true"
    fi
}

# Validate safety settings
_validate_safety() {
    # GIT_SAFETY
    local git_safety="${GIT_SAFETY:-true}"
    if [[ "$git_safety" != "true" && "$git_safety" != "false" ]]; then
        _validation_error "GIT_SAFETY" "Must be 'true' or 'false'"
    fi

    # ALLOW_DIRTY
    local allow_dirty="${ALLOW_DIRTY:-false}"
    if [[ "$allow_dirty" != "true" && "$allow_dirty" != "false" ]]; then
        _validation_error "ALLOW_DIRTY" "Must be 'true' or 'false'"
    fi

    # Warning for dangerous combinations
    if [[ "$git_safety" == "false" && "$allow_dirty" == "true" ]]; then
        _validation_warn "GIT_SAFETY" "Both GIT_SAFETY=false and ALLOW_DIRTY=true - no git protection"
    fi

    # MAX_CMD_SECONDS
    local timeout="${MAX_CMD_SECONDS:-900}"
    if [[ ! "$timeout" =~ ^[0-9]+$ ]]; then
        _validation_error "MAX_CMD_SECONDS" "Must be a number"
    elif [[ "$timeout" -gt 0 && "$timeout" -lt 60 ]]; then
        _validation_warn "MAX_CMD_SECONDS" "Very short timeout ($timeout seconds)"
    fi
}

# =============================================================================
# MAIN VALIDATION
# =============================================================================

# Run all validations
# Usage: config_validate_all
# Returns: 0 if valid (may have warnings), 1 if errors exist
config_validate_all() {
    _validation_reset

    log_debug "Running configuration validation..."

    # Core fields
    _validate_app_name
    _validate_project_root
    _validate_stack_profile

    # Database
    _validate_database

    # Versions
    _validate_versions

    # Feature flags
    _validate_feature_flags

    # Safety settings
    _validate_safety

    # Show results
    if [[ ${#_VALIDATION_ERRORS[@]} -gt 0 || ${#_VALIDATION_WARNINGS[@]} -gt 0 ]]; then
        config_show_validation_results
    fi

    # Return based on errors (warnings are OK)
    [[ ${#_VALIDATION_ERRORS[@]} -eq 0 ]]
}

# Validate a single field
# Usage: config_validate_field "APP_NAME"
config_validate_field() {
    local field="$1"
    _validation_reset

    case "$field" in
        APP_NAME) _validate_app_name ;;
        PROJECT_ROOT) _validate_project_root ;;
        STACK_PROFILE) _validate_stack_profile ;;
        DB_*) _validate_database ;;
        NODE_VERSION|PNPM_VERSION) _validate_versions ;;
        ENABLE_*) _validate_feature_flags ;;
        GIT_SAFETY|ALLOW_DIRTY|MAX_CMD_SECONDS) _validate_safety ;;
        *)
            log_debug "No specific validation for field: $field"
            return 0
            ;;
    esac

    [[ ${#_VALIDATION_ERRORS[@]} -eq 0 ]]
}

# =============================================================================
# RESULT DISPLAY
# =============================================================================

# Show validation results
config_show_validation_results() {
    if [[ ${#_VALIDATION_ERRORS[@]} -gt 0 ]]; then
        echo ""
        log_error "Configuration Errors (${#_VALIDATION_ERRORS[@]}):"
        for err in "${_VALIDATION_ERRORS[@]}"; do
            echo "  - $err"
        done
    fi

    if [[ ${#_VALIDATION_WARNINGS[@]} -gt 0 ]]; then
        echo ""
        log_warn "Configuration Warnings (${#_VALIDATION_WARNINGS[@]}):"
        for warn in "${_VALIDATION_WARNINGS[@]}"; do
            echo "  - $warn"
        done
    fi
}

# Show fix suggestions for common errors
config_suggest_fixes() {
    echo ""
    log_section "Suggested Fixes"

    for err in "${_VALIDATION_ERRORS[@]}"; do
        local field="${err%%:*}"
        case "$field" in
            APP_NAME)
                echo "  $field: Use a simple name like 'myapp' or 'bloom2'"
                ;;
            PROJECT_ROOT)
                echo "  $field: Use '.' for current directory or an absolute path"
                ;;
            DB_PASSWORD)
                echo "  $field: Set a strong password in bootstrap.conf or via DB_PASSWORD env var"
                ;;
            DB_PORT)
                echo "  $field: Use a valid port number (default: 5432 for PostgreSQL)"
                ;;
            *)
                echo "  $field: Check bootstrap.conf for valid values"
                ;;
        esac
    done
}

# Show current configuration summary
config_show_summary() {
    log_section "Configuration Summary"
    echo ""
    echo "  App Name:       ${APP_NAME:-<not set>}"
    echo "  Project Root:   ${PROJECT_ROOT:-<not set>}"
    echo "  Stack Profile:  ${STACK_PROFILE:-full}"
    echo ""
    echo "  Database:"
    echo "    Name:         ${DB_NAME:-<not set>}"
    echo "    User:         ${DB_USER:-<not set>}"
    echo "    Port:         ${DB_PORT:-5432}"
    echo ""
    echo "  Versions:"
    echo "    Node.js:      ${NODE_VERSION:-20}"
    echo "    pnpm:         ${PNPM_VERSION:-9}"
    echo ""
    echo "  Features:"

    local features=(
        "ENABLE_AUTHJS:Authentication (Auth.js)"
        "ENABLE_AI_SDK:AI Integration (Vercel AI SDK)"
        "ENABLE_PG_BOSS:Background Jobs (pg-boss)"
        "ENABLE_SHADCN:UI Components (shadcn/ui)"
        "ENABLE_ZUSTAND:State Management (Zustand)"
        "ENABLE_PDF_EXPORTS:PDF Exports"
        "ENABLE_TEST_INFRA:Testing Infrastructure"
        "ENABLE_CODE_QUALITY:Code Quality (ESLint, Prettier)"
    )

    for feature in "${features[@]}"; do
        local var="${feature%%:*}"
        local desc="${feature#*:}"
        local value="${!var:-false}"
        local marker="[ ]"
        [[ "$value" == "true" ]] && marker="[x]"
        echo "    $marker $desc"
    done
    echo ""
}

# =============================================================================
# INTERACTIVE FIX
# =============================================================================

# Prompt user to fix validation errors
config_interactive_fix() {
    if [[ ${#_VALIDATION_ERRORS[@]} -eq 0 ]]; then
        return 0
    fi

    echo ""
    log_warn "Would you like to fix these errors now? [y/N]"
    read -r fix_choice

    if [[ "${fix_choice,,}" != "y" ]]; then
        return 1
    fi

    for err in "${_VALIDATION_ERRORS[@]}"; do
        local field="${err%%:*}"
        local current="${!field:-}"

        echo ""
        echo "Error: $err"
        read -rp "New value for $field [$current]: " new_value

        if [[ -n "$new_value" ]]; then
            # Update in environment for this session
            export "$field=$new_value"

            # Update in config file
            local sed_cmd="sed -i"
            [[ "$(uname)" == "Darwin" ]] && sed_cmd="sed -i ''"
            $sed_cmd "s|^${field}=.*|${field}=\"${new_value}\"|" "${BOOTSTRAP_CONF}"

            log_success "Updated $field"
        fi
    done

    # Re-validate
    config_validate_all
}
