#!/usr/bin/env bash
# =============================================================================
# File: lib/common.sh
# Purpose: Shared functions for all bootstrap scripts
# Usage: source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

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

# Log to both stdout and log file
_log() {
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

# Execute command or log in dry-run mode
run_cmd() {
    local cmd="$*"
    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry "$cmd"
        return 0
    else
        log_debug "Executing: $cmd"
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

export DRY_RUN
export VERBOSE
export LOG_FILE
export LOG_DIR
