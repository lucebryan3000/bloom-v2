#!/usr/bin/env bash
# =============================================================================
# lib/prereqs.sh - Prerequisite Package Installer
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Checks and installs required package managers/tools in the background.
# Can run while config validation proceeds in parallel.
#
# Exports:
#   prereqs_check, prereqs_install_background, prereqs_wait,
#   prereqs_status, prereqs_is_running
#
# Dependencies:
#   lib/logging.sh
# =============================================================================

# Guard against double-sourcing
[[ -n "${_LIB_PREREQS_LOADED:-}" ]] && return 0
_LIB_PREREQS_LOADED=1

# =============================================================================
# CONFIGURATION
# =============================================================================

# Required tools and their install methods
# Format: "command:check_cmd:install_method:install_hint"
declare -a PREREQ_TOOLS=(
    "node:node --version:nvm:https://nodejs.org"
    "pnpm:pnpm --version:npm:https://pnpm.io"
    "git:git --version:system:https://git-scm.com"
    "docker:docker --version:system:https://docker.com"
)

# Background process tracking
declare -g _PREREQS_PID=""
declare -g _PREREQS_LOG_FILE=""
declare -g _PREREQS_STATUS="not_started"  # not_started, running, completed, failed

# =============================================================================
# CHECKING FUNCTIONS
# =============================================================================

# Check if a single tool is installed
# Usage: prereq_tool_exists "node"
prereq_tool_exists() {
    local tool="$1"
    command -v "$tool" &>/dev/null
}

# Check if Node.js meets minimum version
# Usage: prereq_node_version_ok "20"
prereq_node_version_ok() {
    local required="${1:-20}"

    if ! prereq_tool_exists "node"; then
        return 1
    fi

    local current
    current=$(node --version 2>/dev/null | sed 's/v//' | cut -d. -f1)
    [[ "$current" -ge "$required" ]]
}

# Check if pnpm meets minimum version
# Usage: prereq_pnpm_version_ok "9"
prereq_pnpm_version_ok() {
    local required="${1:-9}"

    if ! prereq_tool_exists "pnpm"; then
        return 1
    fi

    local current
    current=$(pnpm --version 2>/dev/null | cut -d. -f1)
    [[ "$current" -ge "$required" ]]
}

# Check all prerequisites and return missing ones
# Usage: missing=$(prereqs_check)
prereqs_check() {
    local missing=()

    # Check Node.js
    if ! prereq_node_version_ok "${NODE_VERSION:-20}"; then
        missing+=("node")
    fi

    # Check pnpm
    if ! prereq_pnpm_version_ok "${PNPM_VERSION:-9}"; then
        missing+=("pnpm")
    fi

    # Check git
    if ! prereq_tool_exists "git"; then
        missing+=("git")
    fi

    # Check docker (optional, warn only)
    if ! prereq_tool_exists "docker"; then
        # Docker is optional for some profiles
        if [[ "${STACK_PROFILE:-full}" == "full" ]]; then
            missing+=("docker")
        fi
    fi

    echo "${missing[*]}"
}

# Quick check - returns 0 if all prereqs met
# Usage: prereqs_all_met && echo "Ready"
prereqs_all_met() {
    local missing
    missing=$(prereqs_check)
    [[ -z "$missing" ]]
}

# =============================================================================
# INSTALLATION FUNCTIONS
# =============================================================================

# Install Node.js via nvm or direct download
_install_node() {
    local version="${NODE_VERSION:-20}"

    echo "[prereqs] Installing Node.js v${version}..."

    # Check if nvm is available
    if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
        # shellcheck source=/dev/null
        source "$HOME/.nvm/nvm.sh"
        nvm install "$version"
        nvm use "$version"
        return $?
    fi

    # Try to install nvm first
    if command -v curl &>/dev/null; then
        echo "[prereqs] Installing nvm..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

        # Source nvm
        export NVM_DIR="$HOME/.nvm"
        # shellcheck source=/dev/null
        [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"

        nvm install "$version"
        nvm use "$version"
        return $?
    fi

    echo "[prereqs] ERROR: Cannot install Node.js automatically."
    echo "[prereqs] Please install Node.js ${version}+ from https://nodejs.org"
    return 1
}

# Install pnpm via npm or corepack
_install_pnpm() {
    local version="${PNPM_VERSION:-9}"

    echo "[prereqs] Installing pnpm v${version}..."

    # Try corepack first (comes with Node.js 16.13+)
    if command -v corepack &>/dev/null; then
        corepack enable
        corepack prepare "pnpm@${version}" --activate
        return $?
    fi

    # Fall back to npm
    if command -v npm &>/dev/null; then
        npm install -g "pnpm@${version}"
        return $?
    fi

    echo "[prereqs] ERROR: Cannot install pnpm automatically."
    echo "[prereqs] Please install pnpm from https://pnpm.io"
    return 1
}

# Main installation function (runs all missing prereqs)
_install_all_missing() {
    local missing="$1"
    local failed=0

    echo "[prereqs] =========================================="
    echo "[prereqs] Installing missing prerequisites: $missing"
    echo "[prereqs] =========================================="
    echo ""

    for tool in $missing; do
        case "$tool" in
            node)
                if ! _install_node; then
                    failed=$((failed + 1))
                fi
                ;;
            pnpm)
                if ! _install_pnpm; then
                    failed=$((failed + 1))
                fi
                ;;
            git)
                echo "[prereqs] MANUAL: Please install git from https://git-scm.com"
                failed=$((failed + 1))
                ;;
            docker)
                echo "[prereqs] MANUAL: Please install Docker from https://docker.com"
                # Docker is often optional, don't count as failure
                ;;
        esac
    done

    echo ""
    if [[ $failed -eq 0 ]]; then
        echo "[prereqs] =========================================="
        echo "[prereqs] All prerequisites installed successfully!"
        echo "[prereqs] =========================================="
        return 0
    else
        echo "[prereqs] =========================================="
        echo "[prereqs] WARNING: $failed prerequisite(s) need manual installation"
        echo "[prereqs] =========================================="
        return 1
    fi
}

# =============================================================================
# BACKGROUND EXECUTION
# =============================================================================

# Start prerequisite installation in background
# Usage: prereqs_install_background
prereqs_install_background() {
    local missing
    missing=$(prereqs_check)

    if [[ -z "$missing" ]]; then
        _PREREQS_STATUS="completed"
        return 0
    fi

    # Create log file for background process
    _PREREQS_LOG_FILE="${TMPDIR:-/tmp}/omniforge_prereqs_$$.log"

    # Show user message
    echo ""
    log_warn "Missing prerequisites: $missing"
    log_info "Installing in background while you review configuration..."
    log_info "Progress logged to: $_PREREQS_LOG_FILE"
    echo ""

    # Start background installation
    (
        _install_all_missing "$missing" > "$_PREREQS_LOG_FILE" 2>&1
        echo $? > "${_PREREQS_LOG_FILE}.exit"
    ) &

    _PREREQS_PID=$!
    _PREREQS_STATUS="running"

    return 0
}

# Check if background installation is still running
# Usage: prereqs_is_running && echo "Still installing..."
prereqs_is_running() {
    [[ -n "$_PREREQS_PID" ]] && kill -0 "$_PREREQS_PID" 2>/dev/null
}

# Wait for background installation to complete
# Usage: prereqs_wait
prereqs_wait() {
    if [[ -z "$_PREREQS_PID" ]]; then
        return 0
    fi

    if prereqs_is_running; then
        log_info "Waiting for prerequisite installation to complete..."
        wait "$_PREREQS_PID" 2>/dev/null
    fi

    # Check exit status
    if [[ -f "${_PREREQS_LOG_FILE}.exit" ]]; then
        local exit_code
        exit_code=$(cat "${_PREREQS_LOG_FILE}.exit")
        rm -f "${_PREREQS_LOG_FILE}.exit"

        if [[ "$exit_code" -eq 0 ]]; then
            _PREREQS_STATUS="completed"
            log_success "Prerequisite installation completed"
        else
            _PREREQS_STATUS="failed"
            log_error "Prerequisite installation failed. Check: $_PREREQS_LOG_FILE"
            return 1
        fi
    fi

    return 0
}

# Get current status of prereq installation
# Usage: status=$(prereqs_status)
prereqs_status() {
    if prereqs_is_running; then
        echo "running"
    else
        echo "$_PREREQS_STATUS"
    fi
}

# Show installation progress (tail log file)
# Usage: prereqs_show_progress
prereqs_show_progress() {
    if [[ -f "$_PREREQS_LOG_FILE" ]]; then
        echo ""
        echo "=== Prerequisite Installation Progress ==="
        tail -20 "$_PREREQS_LOG_FILE"
        echo "==========================================="
    fi
}

# =============================================================================
# VALIDATION AFTER INSTALL
# =============================================================================

# Verify prerequisites after installation attempt
# Usage: prereqs_verify
prereqs_verify() {
    local missing
    missing=$(prereqs_check)

    if [[ -z "$missing" ]]; then
        log_success "All prerequisites verified"
        return 0
    else
        log_error "Still missing prerequisites: $missing"
        log_error "Please install manually before continuing."
        return 1
    fi
}
