#!/usr/bin/env bash
# =============================================================================
# lib/logging.sh - Logging Functions
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Pure functions for logging. No execution on source.
#
# LOG_LEVEL controls console verbosity:
#   quiet  - Errors only
#   status - Status updates per script/package (default)
#   verbose - Full debug output
#
# Exports:
#   log_info, log_warn, log_error, log_debug, log_step, log_success,
#   log_skip, log_dry, log_status, log_file, log_progress, log_init
#
# Dependencies:
#   None (base module)
# =============================================================================

# Guard against double-sourcing
[[ -n "${_LIB_LOGGING_LOADED:-}" ]] && return 0
_LIB_LOGGING_LOADED=1

# =============================================================================
# COLORS (using $'...' syntax for interpreted escape sequences)
# =============================================================================

readonly LOG_RED=$'\033[0;31m'
readonly LOG_GREEN=$'\033[0;32m'
readonly LOG_YELLOW=$'\033[0;33m'
readonly LOG_BLUE=$'\033[0;34m'
readonly LOG_CYAN=$'\033[0;36m'
readonly LOG_GRAY=$'\033[0;90m'
readonly LOG_BOLD=$'\033[1m'
readonly LOG_NC=$'\033[0m' # No Color

# =============================================================================
# LOGGING CONFIGURATION
# =============================================================================

# LOG_LEVEL: quiet, status (default), verbose
: "${LOG_LEVEL:=status}"
: "${LOG_FORMAT:=plain}"
: "${LOG_FILE:=}"
: "${VERBOSE:=false}"

# Map VERBOSE=true to LOG_LEVEL=verbose for backward compatibility
if [[ "${VERBOSE:-false}" == "true" && "${LOG_LEVEL}" == "status" ]]; then
    LOG_LEVEL="verbose"
fi

# Progress tracking
declare -g _LOG_PROGRESS_CURRENT=0
declare -g _LOG_PROGRESS_TOTAL=0
declare -g _LOG_CURRENT_PHASE=""

# =============================================================================
# INTERNAL LOGGING FUNCTIONS
# =============================================================================

# Check if a log level should be shown on console
_log_should_show() {
    local level="$1"
    case "${LOG_LEVEL}" in
        quiet)
            # Only show errors
            [[ "$level" == "ERROR" ]]
            ;;
        status)
            # Show errors, warnings, status, step, ok, skip
            [[ "$level" =~ ^(ERROR|WARN|STATUS|STEP|OK|SKIP|INFO)$ ]]
            ;;
        verbose)
            # Show everything
            return 0
            ;;
        *)
            # Default to status behavior
            [[ "$level" =~ ^(ERROR|WARN|STATUS|STEP|OK|SKIP|INFO)$ ]]
            ;;
    esac
}

# Plain text logging (default)
_log_plain() {
    local level="$1"
    local color="$2"
    local message="$3"
    local to_console="${4:-true}"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

    # Console output with color (if level is visible)
    if [[ "$to_console" == "true" ]] && _log_should_show "$level"; then
        echo -e "${color}[${level}]${LOG_NC} ${message}"
    fi

    # File output always (without color codes)
    if [[ -n "${LOG_FILE:-}" && -f "${LOG_FILE}" ]]; then
        echo "[${timestamp}] [${level}] ${message}" >> "$LOG_FILE"
    fi
}

# JSON logging for CI/machine parsing
_log_json() {
    local level="$1"
    local message="$2"
    local to_console="${3:-true}"
    local script_name="${0##*/}"

    local json_line
    json_line=$(printf '{"ts":"%s","level":"%s","script":"%s","msg":"%s"}' \
        "$(date -Iseconds 2>/dev/null || date '+%Y-%m-%dT%H:%M:%S')" \
        "${level}" "${script_name}" "${message}")

    if [[ "$to_console" == "true" ]] && _log_should_show "$level"; then
        echo "$json_line"
    fi
    if [[ -n "${LOG_FILE:-}" && -f "${LOG_FILE}" ]]; then
        echo "$json_line" >> "$LOG_FILE"
    fi
}

# Unified logging dispatcher
# Usage: _log LEVEL COLOR MESSAGE [TO_CONSOLE]
_log() {
    local level="$1"
    local color="$2"
    local message="$3"
    local to_console="${4:-true}"

    if [[ "${LOG_FORMAT:-plain}" == "json" ]]; then
        _log_json "${level}" "${message}" "$to_console"
    else
        _log_plain "${level}" "${color}" "${message}" "$to_console"
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
    # Debug only shows in verbose mode
    if [[ "${LOG_LEVEL}" == "verbose" ]]; then
        _log "DEBUG" "$LOG_CYAN" "$1"
    elif [[ -n "${LOG_FILE:-}" && -f "${LOG_FILE}" ]]; then
        # Always write to log file even if not shown
        _log "DEBUG" "$LOG_CYAN" "$1" "false"
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

# Alias for log_success (used by some tech_stack scripts)
log_ok() {
    log_success "$1"
}

log_dry() {
    _log "DRY" "$LOG_CYAN" "Would execute: $1"
}

# =============================================================================
# NEW STATUS & PROGRESS FUNCTIONS
# =============================================================================

# Status line - clean single-line output for script completion
# Usage: log_status "OK" "init-nextjs.sh" "16s"
log_status() {
    local status="$1"
    local script="$2"
    local duration="${3:-}"

    local color
    local symbol
    case "$status" in
        OK|ok|success)
            color="$LOG_GREEN"
            symbol="✓"
            status="OK"
            ;;
        FAIL|fail|error)
            color="$LOG_RED"
            symbol="✗"
            status="FAIL"
            ;;
        SKIP|skip)
            color="$LOG_YELLOW"
            symbol="○"
            status="SKIP"
            ;;
        RUN|run|running)
            color="$LOG_BLUE"
            symbol="▶"
            status=".."
            ;;
        *)
            color="$LOG_NC"
            symbol="·"
            ;;
    esac

    local duration_str=""
    if [[ -n "$duration" ]]; then
        duration_str=" ${LOG_GRAY}(${duration})${LOG_NC}"
    fi

    # Console: [OK] script-name.sh (16s)
    if _log_should_show "STATUS"; then
        echo -e "  ${color}[${status}]${LOG_NC} ${script}${duration_str}"
    fi

    # File: timestamp [STATUS] OK script-name.sh (16s)
    if [[ -n "${LOG_FILE:-}" && -f "${LOG_FILE}" ]]; then
        local timestamp
        timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
        echo "[${timestamp}] [STATUS] ${status} ${script} ${duration}" >> "$LOG_FILE"
    fi
}

# Log to file only (verbose details that shouldn't clutter console)
# Usage: log_file "Command output: ..."
log_file() {
    local message="$1"
    local level="${2:-DETAIL}"

    if [[ -n "${LOG_FILE:-}" && -f "${LOG_FILE}" ]]; then
        local timestamp
        timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
        echo "[${timestamp}] [${level}] ${message}" >> "$LOG_FILE"
    fi
}

# Progress indicator for multi-step operations
# Usage: log_progress_init 12; log_progress "Installing packages"
log_progress_init() {
    _LOG_PROGRESS_TOTAL="${1:-0}"
    _LOG_PROGRESS_CURRENT=0
}

log_progress() {
    local message="$1"
    _LOG_PROGRESS_CURRENT=$((_LOG_PROGRESS_CURRENT + 1))

    local progress_str=""
    if [[ $_LOG_PROGRESS_TOTAL -gt 0 ]]; then
        progress_str=" [${_LOG_PROGRESS_CURRENT}/${_LOG_PROGRESS_TOTAL}]"
    fi

    if _log_should_show "STATUS"; then
        echo -e "  ${LOG_BLUE}..${LOG_NC} ${message}${LOG_GRAY}${progress_str}${LOG_NC}"
    fi

    log_file "Progress: ${message}${progress_str}"
}

# Set current phase for context in logs
# Usage: log_phase_start "0" "Project Foundation"
log_phase_start() {
    local phase_num="$1"
    local phase_name="$2"
    _LOG_CURRENT_PHASE="$phase_num"

    echo ""
    echo -e "${LOG_BOLD}Phase ${phase_num}: ${phase_name}${LOG_NC}"
    log_file "=== Phase ${phase_num}: ${phase_name} ===" "PHASE"
}

# Show a section header
# Usage: log_section "Configuration Summary"
log_section() {
    local title="$1"
    echo ""
    echo -e "${LOG_BOLD}${title}${LOG_NC}"
    echo "──────────────────────────────────────────────"
}

# =============================================================================
# LOG FILE INITIALIZATION
# =============================================================================

# Initialize logging for a run (creates log file if LOG_DIR is set)
# Usage: log_init "omniforge"
log_init() {
    local script_name="${1:-omniforge}"

    # Set default LOG_DIR if not set
    if [[ -z "${LOG_DIR:-}" ]]; then
        if [[ -n "${OMNIFORGE_DIR:-}" ]]; then
            LOG_DIR="${OMNIFORGE_DIR%/}/logs"
        elif [[ -n "${SCRIPTS_DIR:-}" ]]; then
            LOG_DIR="${SCRIPTS_DIR%/}/logs"
        else
            LOG_DIR="${TMPDIR:-/tmp}"
        fi
    fi

    mkdir -p "$LOG_DIR"

    if [[ -z "${LOG_FILE:-}" ]]; then
        LOG_FILE="${LOG_DIR}/omniforge_$(date +%Y%m%d_%H%M%S).log"
    fi
    touch "$LOG_FILE"

    # Write init info to file only (don't clutter console)
    log_file "=== OmniForge Logging Initialized ===" "INIT"
    log_file "Script: $script_name" "INIT"
    log_file "Date: $(date '+%Y-%m-%d %H:%M:%S')" "INIT"
    log_file "User: $(whoami)" "INIT"
    log_file "PWD: $(pwd)" "INIT"
    log_file "LOG_LEVEL: ${LOG_LEVEL}" "INIT"
    log_file "DRY_RUN: ${DRY_RUN:-false}" "INIT"

    # Show log file location on console (always helpful)
    if [[ "${LOG_LEVEL}" != "quiet" ]]; then
        echo -e "${LOG_GRAY}Log: ${LOG_FILE}${LOG_NC}"
    fi
}

# Show where to find detailed logs (call after errors)
log_show_file_hint() {
    if [[ -n "${LOG_FILE:-}" && -f "${LOG_FILE}" ]]; then
        echo ""
        echo -e "${LOG_GRAY}For details, see: ${LOG_FILE}${LOG_NC}"
    fi
}

# Export for subshells
export LOG_FORMAT LOG_LEVEL VERBOSE LOG_FILE LOG_DIR
