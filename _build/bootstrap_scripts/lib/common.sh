#!/usr/bin/env bash
# =============================================================================
# File: lib/common.sh
# Purpose: Shared functions for all bootstrap scripts
# Usage: source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

# OS Detection (early, used throughout)
OS_TYPE="$(uname -s | tr '[:upper:]' '[:lower:]')"

# =============================================================================
# CONFIGURATION
# =============================================================================

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Default settings
DRY_RUN="${DRY_RUN:-false}"
VERBOSE="${VERBOSE:-false}"

# Logging
LOG_DIR="${LOG_DIR:-./logs}"
LOG_FILE="${LOG_FILE:-}"

# Path detection for config files (only if not already set by caller)
if [[ -z "${SCRIPT_DIR:-}" ]]; then
    # If SCRIPT_DIR not set, derive from this file's location
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# Ensure SCRIPTS_DIR points to parent of lib directory
SCRIPTS_DIR="${SCRIPTS_DIR:-${SCRIPT_DIR%/lib}}"

# Only set config paths if BOOTSTRAP_CONF not already defined
if [[ -z "${BOOTSTRAP_CONF:-}" ]]; then
    BOOTSTRAP_CONF="${SCRIPTS_DIR}/bootstrap.conf"
fi
if [[ -z "${BOOTSTRAP_CONF_EXAMPLE:-}" ]]; then
    BOOTSTRAP_CONF_EXAMPLE="${SCRIPTS_DIR}/bootstrap.conf.example"
fi

# =============================================================================
# CONFIG LOADING & FIRST-RUN BEHAVIOR
# =============================================================================

# Interactive prompt for config value
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

# Initialize config with first-run prompts
_init_config() {
    if [[ ! -f "${BOOTSTRAP_CONF}" ]]; then
        if [[ -f "${BOOTSTRAP_CONF_EXAMPLE}" ]]; then
            cp "${BOOTSTRAP_CONF_EXAMPLE}" "${BOOTSTRAP_CONF}"
            log_info "Created bootstrap.conf from bootstrap.conf.example"

            if [[ "${NON_INTERACTIVE:-false}" != "true" ]]; then
                echo ""
                log_info "=== First-Run Configuration ==="
                log_info "Customize your project settings (press Enter to keep defaults):"
                echo ""

                _prompt_config_value "APP_NAME" "Application name" "bloom2"
                _prompt_config_value "PROJECT_ROOT" "Project root directory" "."
                _prompt_config_value "DB_NAME" "Database name" "bloom2_db"
                _prompt_config_value "DB_USER" "Database user" "bloom2"
                _prompt_config_value "DB_PASSWORD" "Database password" "change_me"

                echo ""
                log_info "Configuration saved to bootstrap.conf"
                echo ""
            fi
        else
            log_error "bootstrap.conf.example not found at ${BOOTSTRAP_CONF_EXAMPLE}"
            exit 1
        fi
    fi

    # shellcheck source=/dev/null
    . "${BOOTSTRAP_CONF}"

    # Validate critical values in non-interactive mode
    if [[ "${NON_INTERACTIVE:-false}" == "true" ]]; then
        if [[ "${DB_PASSWORD:-}" == "change_me" ]]; then
            log_error "DB_PASSWORD is still 'change_me' in NON_INTERACTIVE mode. Update bootstrap.conf."
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

    export DRY_RUN LOG_FORMAT MAX_CMD_SECONDS BOOTSTRAP_RESUME_MODE
    export GIT_SAFETY ALLOW_DIRTY STACK_PROFILE
}

# =============================================================================
# LOGGING FUNCTIONS
# =============================================================================

# Initialize logging for a run
init_logging() {
    local script_name="${1:-bootstrap}"
    mkdir -p "$LOG_DIR"

    if [[ -z "$LOG_FILE" ]]; then
        LOG_FILE="${LOG_DIR}/bootstrap-$(date +%Y%m%d-%H%M%S).log"
    fi

    touch "$LOG_FILE"
    log_info "=== Logging initialized: $LOG_FILE ==="
    log_info "Script: $script_name"
    log_info "Date: $(date '+%Y-%m-%d %H:%M:%S')"
    log_info "User: $(whoami)"
    log_info "PWD: $(pwd)"
    log_info "DRY_RUN: $DRY_RUN"
}

# Plain text logging
_log_plain() {
    local level="$1"
    local color="$2"
    local message="$3"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

    # Console output with color
    echo -e "${color}[${level}]${NC} ${message}"

    # File output without color codes
    if [[ -n "$LOG_FILE" && -f "$LOG_FILE" ]]; then
        echo "[${timestamp}] [${level}] ${message}" >> "$LOG_FILE"
    fi
}

# JSON logging for CI/machine parsing
_log_json() {
    local level="$1"
    local message="$2"
    local script_name="${0##*/}"

    printf '{"ts":"%s","level":"%s","script":"%s","msg":"%s"}\n' \
        "$(date -Iseconds)" "${level}" "${script_name}" "${message}" | tee -a "${LOG_FILE}"
}

# Unified logging that respects LOG_FORMAT
_log() {
    local level="$1"
    local color="$2"
    local message="$3"

    if [[ "${LOG_FORMAT:-plain}" == "json" ]]; then
        _log_json "${level}" "${message}"
    else
        _log_plain "${level}" "${color}" "${message}"
    fi
}

log_info() {
    _log "INFO" "$GREEN" "$1"
}

log_warn() {
    _log "WARN" "$YELLOW" "$1"
}

log_error() {
    _log "ERROR" "$RED" "$1"
}

log_debug() {
    if [[ "$VERBOSE" == "true" ]]; then
        _log "DEBUG" "$CYAN" "$1"
    fi
}

log_step() {
    _log "STEP" "$BLUE" ">>> $1"
}

log_skip() {
    _log "SKIP" "$YELLOW" "$1 (already exists)"
}

log_success() {
    _log "OK" "$GREEN" "✓ $1"
}

log_dry() {
    _log "DRY RUN" "$CYAN" "Would execute: $1"
}

# =============================================================================
# DRY RUN HELPERS
# =============================================================================

# Execute command or log in dry-run mode (with optional timeout)
run_cmd() {
    local cmd="$*"
    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry "$cmd"
        return 0
    fi

    # Check if timeout should be used
    local max_seconds="${MAX_CMD_SECONDS:-0}"
    if [[ "$max_seconds" != "0" ]] && command -v timeout &> /dev/null; then
        log_debug "RUN (timeout ${max_seconds}s): $cmd"
        timeout "${max_seconds}" bash -lc "$cmd"
    else
        log_debug "RUN: $cmd"
        eval "$cmd"
    fi
}

# Create directory with dry-run support
ensure_dir() {
    local dir="$1"
    if [[ -d "$dir" ]]; then
        log_skip "Directory $dir"
        return 0
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry "mkdir -p $dir"
    else
        mkdir -p "$dir"
        log_success "Created directory: $dir"
    fi
}

# Create file with content (dry-run aware)
write_file() {
    local file_path="$1"
    local content="$2"
    local force="${3:-false}"

    if [[ -f "$file_path" && "$force" != "true" ]]; then
        log_skip "File $file_path"
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

# Append to file (dry-run aware)
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

# Write file only if it doesn't exist (wrapper for write_file)
# This is the function that bootstrap scripts call
write_file_if_missing() {
    local file_path="$1"
    local content="$2"

    # Call write_file with force=false (default skip behavior)
    write_file "$file_path" "$content" "false"
}

# =============================================================================
# VALIDATION HELPERS
# =============================================================================

# Check if command exists
require_cmd() {
    local cmd="$1"
    local install_hint="${2:-}"

    if ! command -v "$cmd" &> /dev/null; then
        log_error "Required command not found: $cmd"
        if [[ -n "$install_hint" ]]; then
            log_error "Install with: $install_hint"
        fi
        exit 1
    fi
    log_debug "Found command: $cmd"
}

# Check Node.js version
require_node_version() {
    local min_version="${1:-20}"
    require_cmd "node" "Install Node.js from https://nodejs.org"

    local current_version
    current_version=$(node -v | sed 's/v//' | cut -d'.' -f1)

    if [[ "$current_version" -lt "$min_version" ]]; then
        log_error "Node.js version $min_version+ required, found: $(node -v)"
        exit 1
    fi
    log_debug "Node.js version OK: $(node -v)"
}

# Check pnpm is installed
require_pnpm() {
    require_cmd "pnpm" "npm install -g pnpm"
}

# Check Docker is installed and running
require_docker() {
    require_cmd "docker" "Install Docker from https://docker.com"

    if ! docker info &> /dev/null; then
        log_error "Docker is not running. Please start Docker."
        exit 1
    fi
    log_debug "Docker is running"
}

# Check if file exists
require_file() {
    local file="$1"
    local hint="${2:-}"

    if [[ ! -f "$file" ]]; then
        log_error "Required file not found: $file"
        if [[ -n "$hint" ]]; then
            log_error "Hint: $hint"
        fi
        exit 1
    fi
    log_debug "Found file: $file"
}

# Check if we're in a project directory
require_project_root() {
    if [[ ! -f "package.json" ]]; then
        log_error "Not in a project root (no package.json found)"
        log_error "Please run this script from the project root directory"
        exit 1
    fi
}

# =============================================================================
# PACKAGE.JSON HELPERS
# =============================================================================

# Check if dependency exists in package.json
has_dependency() {
    local dep="$1"
    local pkg_file="${2:-package.json}"

    if [[ ! -f "$pkg_file" ]]; then
        return 1
    fi

    if grep -q "\"$dep\"" "$pkg_file"; then
        return 0
    fi
    return 1
}

# Add dependency if not present
add_dependency() {
    local dep="$1"
    local dev="${2:-false}"

    if has_dependency "$dep"; then
        log_skip "Dependency $dep"
        return 0
    fi

    local flag=""
    if [[ "$dev" == "true" ]]; then
        flag="-D"
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry "pnpm add $flag $dep"
    else
        log_info "Installing $dep..."
        pnpm add $flag "$dep"
        log_success "Installed: $dep"
    fi
}

# Add script to package.json
add_npm_script() {
    local name="$1"
    local command="$2"
    local pkg_file="package.json"

    if [[ ! -f "$pkg_file" ]]; then
        log_error "package.json not found"
        return 1
    fi

    # Check if script already exists
    if grep -q "\"$name\":" "$pkg_file"; then
        log_skip "Script $name"
        return 0
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry "Add script '$name': '$command'"
        return 0
    fi

    # Use node to safely add script
    node -e "
        const fs = require('fs');
        const pkg = JSON.parse(fs.readFileSync('$pkg_file', 'utf8'));
        pkg.scripts = pkg.scripts || {};
        pkg.scripts['$name'] = '$command';
        fs.writeFileSync('$pkg_file', JSON.stringify(pkg, null, 2) + '\n');
    "
    log_success "Added script: $name"
}

# Update package.json field
update_pkg_field() {
    local field="$1"
    local value="$2"
    local pkg_file="package.json"

    if [[ ! -f "$pkg_file" ]]; then
        log_error "package.json not found"
        return 1
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry "Set package.json $field = $value"
        return 0
    fi

    # Use node to safely update field
    node -e "
        const fs = require('fs');
        const pkg = JSON.parse(fs.readFileSync('$pkg_file', 'utf8'));
        const path = '$field'.split('.');
        let obj = pkg;
        for (let i = 0; i < path.length - 1; i++) {
            obj[path[i]] = obj[path[i]] || {};
            obj = obj[path[i]];
        }
        obj[path[path.length - 1]] = $value;
        fs.writeFileSync('$pkg_file', JSON.stringify(pkg, null, 2) + '\n');
    "
    log_success "Updated package.json: $field"
}

# =============================================================================
# ARGUMENT PARSING
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
# UTILITY FUNCTIONS
# =============================================================================

# Get script directory
get_script_dir() {
    cd "$(dirname "${BASH_SOURCE[1]}")" && pwd
}

# Get project root (assumes scripts are in _build/bootstrap_scripts/)
get_project_root() {
    local script_dir
    script_dir="$(get_script_dir)"
    echo "$(cd "$script_dir/../.." && pwd)"
}

# Create .gitkeep in empty directory
add_gitkeep() {
    local dir="$1"
    ensure_dir "$dir"

    local gitkeep="$dir/.gitkeep"
    if [[ ! -f "$gitkeep" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            log_dry "touch $gitkeep"
        else
            touch "$gitkeep"
        fi
    fi
}

# Confirm action with user
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
# STATE TRACKING
# =============================================================================

# Initialize state file for tracking script success
init_state_file() {
    BOOTSTRAP_STATE_FILE="${BOOTSTRAP_STATE_FILE:-${PROJECT_ROOT:-.}/.bootstrap_state}"
    if [[ ! -f "${BOOTSTRAP_STATE_FILE}" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            log_dry "touch ${BOOTSTRAP_STATE_FILE}"
        else
            touch "${BOOTSTRAP_STATE_FILE}"
        fi
    fi
}

# Mark a script as successfully completed
mark_script_success() {
    local key="$1"
    init_state_file
    if ! grep -q "^${key}=" "${BOOTSTRAP_STATE_FILE}" 2>/dev/null; then
        if [[ "$DRY_RUN" == "true" ]]; then
            log_dry "echo '${key}=success:$(date -Is)' >> ${BOOTSTRAP_STATE_FILE}"
        else
            echo "${key}=success:$(date -Is)" >> "${BOOTSTRAP_STATE_FILE}"
            log_debug "Marked success: ${key}"
        fi
    fi
}

# Check if a script has already succeeded
has_script_succeeded() {
    local key="$1"
    init_state_file
    if grep -q "^${key}=success" "${BOOTSTRAP_STATE_FILE}" 2>/dev/null; then
        return 0
    fi
    return 1
}

# Clear/reset a specific script's state
clear_script_state() {
    local key="$1"
    init_state_file
    if [[ -f "${BOOTSTRAP_STATE_FILE}" ]]; then
        sed -i.bak "/^${key}=/d" "${BOOTSTRAP_STATE_FILE}"
        rm -f "${BOOTSTRAP_STATE_FILE}.bak"
        log_info "Cleared state for script: ${key}"
    fi
}

# =============================================================================
# STACK PROFILES
# =============================================================================

# Apply stack profile settings (minimal, api-only, full)
apply_stack_profile() {
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

# =============================================================================
# GIT SAFETY
# =============================================================================

# Ensure git working directory is clean (if GIT_SAFETY is enabled)
ensure_git_clean() {
    local git_safety="${GIT_SAFETY:-false}"
    local allow_dirty="${ALLOW_DIRTY:-false}"

    if [[ "$git_safety" != "true" ]]; then
        return 0
    fi

    if [[ "$allow_dirty" == "true" ]]; then
        log_debug "Git safety check skipped (ALLOW_DIRTY=true)"
        return 0
    fi

    local project_dir="${PROJECT_ROOT:-.}"
    if [[ ! -d "${project_dir}/.git" ]]; then
        log_debug "Not a git repository, skipping git safety check"
        return 0
    fi

    local status
    status="$(cd "${project_dir}" && git status --porcelain 2>/dev/null)"
    if [[ -n "$status" ]]; then
        log_error "Git working directory is not clean"
        log_error "Uncommitted changes found. Commit or stash before running bootstrap."
        log_error "Use ALLOW_DIRTY=true to override this check."
        exit 1
    fi

    log_debug "Git working directory is clean"
    return 0
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
setup_error_trap() {
    trap cleanup_on_error EXIT
}

# =============================================================================
# EXPORTS
# =============================================================================

export OS_TYPE
export DRY_RUN
export VERBOSE
export LOG_FILE
export LOG_DIR
