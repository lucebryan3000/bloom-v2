#!/usr/bin/env bash
# =============================================================================
# lib/logging.sh - Logging Functions
# =============================================================================
# Part of OmniForge - The Factory That Builds Universes
#
# Pure functions for logging. No execution on source.
#
# Exports:
#   log_info, log_warn, log_error, log_debug, log_step, log_success,
#   log_skip, log_dry, log_detail, log_init
#
# Dependencies:
#   None (base module)
# =============================================================================

# Guard against double-sourcing
[[ -n "${_LIB_LOGGING_LOADED:-}" ]] && return 0
_LIB_LOGGING_LOADED=1

# =============================================================================
# COLORS
# =============================================================================

readonly LOG_RED='\033[0;31m'
readonly LOG_GREEN='\033[0;32m'
readonly LOG_YELLOW='\033[0;33m'
readonly LOG_BLUE='\033[0;34m'
readonly LOG_CYAN='\033[0;36m'
readonly LOG_NC='\033[0m' # No Color

# =============================================================================
# LOGGING CONFIGURATION
# =============================================================================

# These can be set before sourcing or will use defaults
: "${LOG_FORMAT:=plain}"
: "${LOG_FILE:=}"
: "${VERBOSE:=false}"

# =============================================================================
# INTERNAL LOGGING FUNCTIONS
# =============================================================================

# Plain text logging (default)
_log_plain() {
    local level="$1"
    local color="$2"
    local message="$3"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

    # Console output with color
    echo -e "${color}[${level}]${LOG_NC} ${message}"

    # File output without color codes
    if [[ -n "${LOG_FILE:-}" && -f "${LOG_FILE}" ]]; then
        echo "[${timestamp}] [${level}] ${message}" >> "$LOG_FILE"
    fi
}

# JSON logging for CI/machine parsing
_log_json() {
    local level="$1"
    local message="$2"
    local script_name="${0##*/}"

    local json_line
    json_line=$(printf '{"ts":"%s","level":"%s","script":"%s","msg":"%s"}' \
        "$(date -Iseconds 2>/dev/null || date '+%Y-%m-%dT%H:%M:%S')" \
        "${level}" "${script_name}" "${message}")

    echo "$json_line"
    if [[ -n "${LOG_FILE:-}" && -f "${LOG_FILE}" ]]; then
        echo "$json_line" >> "$LOG_FILE"
    fi
}

# Unified logging dispatcher
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

# =============================================================================
# PUBLIC LOGGING FUNCTIONS
# =============================================================================

log_info() {
    _log "INFO" "$LOG_GREEN" "$1"
}

log_warn() {
    _log "WARN" "$LOG_YELLOW" "$1"
}

log_error() {
    _log "ERROR" "$LOG_RED" "$1"
}

log_debug() {
    if [[ "${VERBOSE:-false}" == "true" ]]; then
        _log "DEBUG" "$LOG_CYAN" "$1"
    fi
}

log_step() {
    _log "STEP" "$LOG_BLUE" ">>> $1"
}

log_skip() {
    _log "SKIP" "$LOG_YELLOW" "$1"
}

log_success() {
    _log "OK" "$LOG_GREEN" "✓ $1"
}

log_dry() {
    _log "DRY" "$LOG_CYAN" "Would execute: $1"
}

# =============================================================================
# LOG FILE INITIALIZATION
# =============================================================================

# Initialize logging for a run (creates log file if LOG_DIR is set)
log_init() {
    local script_name="${1:-bootstrap}"

    if [[ -n "${LOG_DIR:-}" ]]; then
        mkdir -p "$LOG_DIR"
        if [[ -z "${LOG_FILE:-}" ]]; then
            LOG_FILE="${LOG_DIR}/bootstrap-$(date +%Y%m%d-%H%M%S).log"
        fi
        touch "$LOG_FILE"

        log_info "=== Logging initialized: $LOG_FILE ==="
        log_info "Script: $script_name"
        log_info "Date: $(date '+%Y-%m-%d %H:%M:%S')"
        log_info "User: $(whoami)"
        log_info "PWD: $(pwd)"
        log_debug "DRY_RUN: ${DRY_RUN:-false}"
    fi
}

# Export for subshells
export LOG_FORMAT VERBOSE LOG_FILE
