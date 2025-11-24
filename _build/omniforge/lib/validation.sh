#!/usr/bin/env bash
# =============================================================================
# lib/validation.sh - Validation Helper Functions
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Pure functions for validating commands, files, versions. No execution on source.
#
# Exports:
#   require_cmd, require_node_version, require_pnpm, require_docker,
#   require_file, require_project_root
#
# Dependencies:
#   lib/logging.sh
# =============================================================================

# Guard against double-sourcing
[[ -n "${_LIB_VALIDATION_LOADED:-}" ]] && return 0
_LIB_VALIDATION_LOADED=1

# =============================================================================
# COMMAND VALIDATION
# =============================================================================

# Check if command exists
# Usage: require_cmd "docker" "Install from https://docker.com"
require_cmd() {
    local cmd="$1"
    local install_hint="${2:-}"

    if ! command -v "$cmd" &> /dev/null; then
        log_error "Required command not found: $cmd"
        if [[ -n "$install_hint" ]]; then
            log_error "Install with: $install_hint"
        fi
        return 1
    fi
    log_debug "Found command: $cmd"
    return 0
}

# Check Node.js version meets minimum
# Usage: require_node_version 20
require_node_version() {
    local min_version="${1:-20}"

    if ! command -v node &> /dev/null; then
        log_error "Node.js not found. Install from https://nodejs.org"
        return 1
    fi

    local current_version
    current_version=$(node -v | sed 's/v//' | cut -d'.' -f1)

    if [[ "$current_version" -lt "$min_version" ]]; then
        log_error "Node.js version $min_version+ required, found: $(node -v)"
        return 1
    fi
    log_debug "Node.js version OK: $(node -v)"
    return 0
}

# Check pnpm is installed
require_pnpm() {
    require_cmd "pnpm" "npm install -g pnpm"
}

# Check Docker is installed and running
require_docker() {
    if ! require_cmd "docker" "Install from https://docker.com"; then
        return 1
    fi

    if ! docker info &> /dev/null; then
        log_error "Docker is not running. Please start Docker."
        return 1
    fi
    log_debug "Docker is running"
    return 0
}

# =============================================================================
# FILE VALIDATION
# =============================================================================

# Check if file exists
# Usage: require_file "/path/to/file" "Run setup first"
require_file() {
    local file="$1"
    local hint="${2:-}"

    if [[ ! -f "$file" ]]; then
        log_error "Required file not found: $file"
        if [[ -n "$hint" ]]; then
            log_error "Hint: $hint"
        fi
        return 1
    fi
    log_debug "Found file: $file"
    return 0
}

# Check if directory exists
# Usage: require_dir "/path/to/dir"
require_dir() {
    local dir="$1"
    local hint="${2:-}"

    if [[ ! -d "$dir" ]]; then
        log_error "Required directory not found: $dir"
        if [[ -n "$hint" ]]; then
            log_error "Hint: $hint"
        fi
        return 1
    fi
    log_debug "Found directory: $dir"
    return 0
}

# Check if we're in a project directory (has package.json)
require_project_root() {
    if [[ ! -f "package.json" ]]; then
        log_error "Not in a project root (no package.json found)"
        log_error "Please run this script from the project root directory"
        return 1
    fi
    return 0
}

# =============================================================================
# DEPENDENCY CHECKING FROM PHASE CONFIG
# =============================================================================

# Check dependencies from PHASE_CONFIG deps string
# Usage: check_phase_deps "git:https://git-scm.com,node:https://nodejs.org"
check_phase_deps() {
    local deps_string="$1"
    local prereq_mode="${2:-warn}"  # strict|warn

    [[ -z "$deps_string" ]] && return 0

    local IFS=','
    local failed=0

    for dep in $deps_string; do
        local cmd="${dep%%:*}"
        local url="${dep#*:}"

        # Skip "builtin" dependencies
        [[ "$url" == "builtin" ]] && continue

        if ! command -v "$cmd" &> /dev/null; then
            if [[ "$prereq_mode" == "strict" ]]; then
                log_error "Required: $cmd - Install from $url"
                failed=1
            else
                log_warn "Missing (optional): $cmd - Install from $url"
            fi
        else
            log_debug "Dependency OK: $cmd"
        fi
    done

    return $failed
}
