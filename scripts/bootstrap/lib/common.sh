#!/usr/bin/env bash
# =============================================================================
# Bootstrap Common Library
# =============================================================================
# Shared functions for all bootstrap scripts.
# Source this at the top of every script.
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

# Determine paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${SCRIPT_DIR%/lib}"
BOOTSTRAP_CONF="${SCRIPTS_DIR}/bootstrap.conf"
BOOTSTRAP_CONF_EXAMPLE="${SCRIPTS_DIR}/bootstrap.conf.example"

# =============================================================================
# CONFIG LOADING & FIRST-RUN BEHAVIOR
# =============================================================================

_prompt_config_value() {
    local var_name="$1"
    local prompt_text="$2"
    local default_val="$3"
    local new_val

    if [[ "${NON_INTERACTIVE:-false}" == "true" ]]; then
        return 0
    fi

    read -rp "${prompt_text} [${default_val}]: " new_val
    if [[ -n "${new_val}" ]]; then
        sed -i.bak "s|^${var_name}=.*|${var_name}=\"${new_val}\"|" "${BOOTSTRAP_CONF}"
        rm -f "${BOOTSTRAP_CONF}.bak"
    fi
}

_init_config() {
    if [[ ! -f "${BOOTSTRAP_CONF}" ]]; then
        if [[ -f "${BOOTSTRAP_CONF_EXAMPLE}" ]]; then
            cp "${BOOTSTRAP_CONF_EXAMPLE}" "${BOOTSTRAP_CONF}"
            echo "[INFO] Created bootstrap.conf from bootstrap.conf.example"

            if [[ "${NON_INTERACTIVE:-false}" != "true" ]]; then
                echo ""
                echo "=== First-Run Configuration ==="
                echo "Customize your project settings (press Enter to keep defaults):"
                echo ""

                _prompt_config_value "APP_NAME" "Application name" "bloom2"
                _prompt_config_value "PROJECT_ROOT" "Project root directory" "."
                _prompt_config_value "DB_NAME" "Database name" "bloom2_db"
                _prompt_config_value "DB_USER" "Database user" "bloom2"
                _prompt_config_value "DB_PASSWORD" "Database password" "change_me"

                echo ""
                echo "Configuration saved to bootstrap.conf"
                echo ""
            fi
        else
            echo "[ERROR] bootstrap.conf.example not found at ${BOOTSTRAP_CONF_EXAMPLE}" >&2
            exit 1
        fi
    fi

    # shellcheck source=/dev/null
    . "${BOOTSTRAP_CONF}"

    # Validate critical values in non-interactive mode
    if [[ "${NON_INTERACTIVE:-false}" == "true" ]]; then
        if [[ "${DB_PASSWORD:-}" == "change_me" ]]; then
            echo "[ERROR] DB_PASSWORD is still 'change_me' in NON_INTERACTIVE mode. Update bootstrap.conf." >&2
            exit 1
        fi
    fi

    # Set defaults for optional vars
    : "${DRY_RUN:=false}"
    : "${LOG_FORMAT:=plain}"
    : "${MAX_CMD_SECONDS:=900}"
    : "${BOOTSTRAP_RESUME_MODE:=skip}"
    : "${GIT_SAFETY:=true}"
    : "${ALLOW_DIRTY:=false}"
    : "${STACK_PROFILE:=full}"

    # Detect OS
    OS_TYPE="$(uname -s | tr '[:upper:]' '[:lower:]')"
    export OS_TYPE
}

# =============================================================================
# STACK PROFILE APPLICATION
# =============================================================================

apply_stack_profile() {
    case "${STACK_PROFILE}" in
        minimal)
            ENABLE_AUTHJS="false"
            ENABLE_AI_SDK="false"
            ENABLE_PG_BOSS="false"
            ENABLE_SHADCN="false"
            ENABLE_ZUSTAND="false"
            ENABLE_PDF_EXPORTS="false"
            ENABLE_TEST_INFRA="false"
            ENABLE_CODE_QUALITY="true"
            ;;
        api-only)
            ENABLE_AUTHJS="true"
            ENABLE_AI_SDK="true"
            ENABLE_PG_BOSS="true"
            ENABLE_SHADCN="false"
            ENABLE_ZUSTAND="false"
            ENABLE_PDF_EXPORTS="false"
            ENABLE_TEST_INFRA="true"
            ENABLE_CODE_QUALITY="true"
            ;;
        full|*)
            # Use values from config as-is
            ;;
    esac

    export ENABLE_AUTHJS ENABLE_AI_SDK ENABLE_PG_BOSS ENABLE_SHADCN
    export ENABLE_ZUSTAND ENABLE_PDF_EXPORTS ENABLE_TEST_INFRA ENABLE_CODE_QUALITY
}

# =============================================================================
# LOGGING
# =============================================================================

_ensure_log_dir() {
    if [[ -z "${LOG_FILE:-}" ]]; then
        mkdir -p "${LOGS_DIR:-./logs}"
        LOG_FILE="${LOGS_DIR:-./logs}/bootstrap-$(date +%Y%m%d-%H%M%S).log"
        export LOG_FILE
    fi
}

_log_plain() {
    local level="$1"
    shift
    local formatted_level
    formatted_level="$(printf '%-5s' "${level^^}")"
    echo "[${formatted_level}] $*" | tee -a "${LOG_FILE}"
}

_log_json() {
    local level="$1"
    shift
    local script_name="${0##*/}"
    printf '{"ts":"%s","level":"%s","script":"%s","msg":"%s"}\n' \
        "$(date -Iseconds)" "${level}" "${script_name}" "$*" | tee -a "${LOG_FILE}"
}

log_info() {
    _ensure_log_dir
    if [[ "${LOG_FORMAT:-plain}" == "json" ]]; then
        _log_json "info" "$@"
    else
        _log_plain "info" "$@"
    fi
}

log_warn() {
    _ensure_log_dir
    if [[ "${LOG_FORMAT:-plain}" == "json" ]]; then
        _log_json "warn" "$@"
    else
        _log_plain "warn" "$@"
    fi
}

log_error() {
    _ensure_log_dir
    if [[ "${LOG_FORMAT:-plain}" == "json" ]]; then
        _log_json "error" "$@"
    else
        _log_plain "error" "$@"
    fi
}

log_success() {
    log_info "SUCCESS: $*"
}

# =============================================================================
# COMMAND EXECUTION WITH TIMEOUT
# =============================================================================

run_cmd() {
    local cmd="$*"

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "DRY RUN: ${cmd}"
        return 0
    fi

    if command -v timeout >/dev/null 2>&1 && [[ -n "${MAX_CMD_SECONDS:-}" && "${MAX_CMD_SECONDS}" != "0" ]]; then
        log_info "RUN (timeout ${MAX_CMD_SECONDS}s): ${cmd}"
        if ! timeout "${MAX_CMD_SECONDS}" bash -lc "${cmd}"; then
            log_error "Command timed out or failed: ${cmd}"
            return 1
        fi
    else
        log_info "RUN: ${cmd}"
        if ! eval "${cmd}"; then
            log_error "Command failed: ${cmd}"
            return 1
        fi
    fi
}

# =============================================================================
# PREFLIGHT CHECKS
# =============================================================================

require_cmd() {
    local cmd="$1"
    if ! command -v "${cmd}" >/dev/null 2>&1; then
        log_error "Required command '${cmd}' not found. Please install it and retry."
        exit 1
    fi
}

check_tool_versions() {
    if command -v node >/dev/null 2>&1; then
        local node_major
        node_major="$(node -v | sed 's/v//' | cut -d. -f1)"
        if [[ "${node_major}" -lt "${NODE_VERSION:-20}" ]]; then
            log_warn "Node.js version ${node_major} is below recommended ${NODE_VERSION}"
        fi
    fi

    if command -v pnpm >/dev/null 2>&1; then
        local pnpm_major
        pnpm_major="$(pnpm -v | cut -d. -f1)"
        if [[ "${pnpm_major}" -lt "${PNPM_VERSION:-9}" ]]; then
            log_warn "pnpm version ${pnpm_major} is below recommended ${PNPM_VERSION}"
        fi
    fi
}

# =============================================================================
# GIT SAFETY
# =============================================================================

ensure_git_clean() {
    if [[ "${GIT_SAFETY:-true}" == "true" && "${ALLOW_DIRTY:-false}" != "true" ]]; then
        local proj_root="${PROJECT_ROOT:-.}"
        if [[ -d "${proj_root}/.git" ]]; then
            if [[ -n "$(git -C "${proj_root}" status --porcelain 2>/dev/null)" ]]; then
                log_error "Git working tree is dirty and GIT_SAFETY=true."
                log_error "Commit or stash changes, or set ALLOW_DIRTY=true in bootstrap.conf."
                exit 1
            fi
        fi
    fi
}

# =============================================================================
# STATE TRACKING & RESUME
# =============================================================================

init_state_file() {
    : "${BOOTSTRAP_STATE_FILE:="${PROJECT_ROOT:-.}/.bootstrap_state"}"
    if [[ ! -f "${BOOTSTRAP_STATE_FILE}" ]]; then
        touch "${BOOTSTRAP_STATE_FILE}"
    fi
}

mark_script_success() {
    local key="$1"
    init_state_file
    if ! grep -q "^${key}=success" "${BOOTSTRAP_STATE_FILE}" 2>/dev/null; then
        echo "${key}=success:$(date -Iseconds)" >> "${BOOTSTRAP_STATE_FILE}"
    fi
}

has_script_succeeded() {
    local key="$1"
    init_state_file
    grep -q "^${key}=success" "${BOOTSTRAP_STATE_FILE}" 2>/dev/null
}

clear_script_state() {
    local key="$1"
    init_state_file
    if [[ -f "${BOOTSTRAP_STATE_FILE}" ]]; then
        sed -i.bak "/^${key}=/d" "${BOOTSTRAP_STATE_FILE}"
        rm -f "${BOOTSTRAP_STATE_FILE}.bak"
    fi
}

# =============================================================================
# ARGUMENT PARSING
# =============================================================================

parse_common_args() {
    SCRIPT_ARGS=()
    SHOW_HELP="false"
    DRY_RUN="${DRY_RUN:-false}"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                SHOW_HELP="true"
                shift
                ;;
            -n|--dry-run)
                DRY_RUN="true"
                shift
                ;;
            *)
                SCRIPT_ARGS+=("$1")
                shift
                ;;
        esac
    done

    export SHOW_HELP DRY_RUN
}

# =============================================================================
# FILE HELPERS
# =============================================================================

ensure_dir() {
    local dir="$1"
    if [[ ! -d "${dir}" ]]; then
        if [[ "${DRY_RUN:-false}" == "true" ]]; then
            log_info "DRY RUN: mkdir -p ${dir}"
        else
            mkdir -p "${dir}"
            log_info "Created directory: ${dir}"
        fi
    fi
}

ensure_file_contains() {
    local file="$1"
    local pattern="$2"
    local content="$3"

    if [[ ! -f "${file}" ]]; then
        if [[ "${DRY_RUN:-false}" == "true" ]]; then
            log_info "DRY RUN: Create ${file} with content"
        else
            echo "${content}" > "${file}"
            log_info "Created: ${file}"
        fi
    elif ! grep -qF "${pattern}" "${file}" 2>/dev/null; then
        if [[ "${DRY_RUN:-false}" == "true" ]]; then
            log_info "DRY RUN: Append to ${file}"
        else
            echo "${content}" >> "${file}"
            log_info "Updated: ${file}"
        fi
    else
        log_info "SKIP: ${file} already contains required content"
    fi
}

write_file_if_missing() {
    local file="$1"
    local content="$2"

    if [[ -f "${file}" ]]; then
        log_info "SKIP: ${file} already exists"
        return 0
    fi

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "DRY RUN: Create ${file}"
        return 0
    fi

    ensure_dir "$(dirname "${file}")"
    echo "${content}" > "${file}"
    log_info "Created: ${file}"
}

# =============================================================================
# PACKAGE MANAGEMENT HELPERS
# =============================================================================

add_dependency() {
    local pkg="$1"
    local dev="${2:-false}"

    if [[ -z "${pkg}" ]]; then
        return 0
    fi

    local pkg_name="${pkg%%@*}"

    if grep -q "\"${pkg_name}\"" package.json 2>/dev/null; then
        log_info "SKIP: ${pkg_name} already in package.json"
        return 0
    fi

    if [[ "${dev}" == "true" ]]; then
        run_cmd "pnpm add -D ${pkg}"
    else
        run_cmd "pnpm add ${pkg}"
    fi
}

add_npm_script() {
    local name="$1"
    local command="$2"

    if [[ ! -f "package.json" ]]; then
        log_warn "package.json not found, cannot add script ${name}"
        return 1
    fi

    if grep -q "\"${name}\":" package.json 2>/dev/null; then
        log_info "SKIP: Script '${name}' already exists"
        return 0
    fi

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "DRY RUN: Add npm script '${name}'"
        return 0
    fi

    node -e "
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
pkg.scripts = pkg.scripts || {};
pkg.scripts['${name}'] = '${command}';
fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
"
    log_info "Added npm script: ${name}"
}

# =============================================================================
# INITIALIZATION
# =============================================================================

_init_config
apply_stack_profile
