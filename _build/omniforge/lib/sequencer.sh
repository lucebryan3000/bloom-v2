#!/usr/bin/env bash
# =============================================================================
# lib/sequencer.sh - Sequential Execution with Test Criteria
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Manages sequential script execution with:
# - Per-script timeouts
# - Test criteria verification
# - Retry logic for transient failures
# - Dependency ordering
#
# Exports:
#   sequencer_run, sequencer_run_with_deps, sequencer_test,
#   sequencer_set_timeout, sequencer_get_results
#
# Dependencies:
#   lib/logging.sh
# =============================================================================

# Guard against double-sourcing
[[ -n "${_LIB_SEQUENCER_LOADED:-}" ]] && return 0
_LIB_SEQUENCER_LOADED=1

# =============================================================================
# SEQUENCER CONFIGURATION
# =============================================================================

# Default timeout (5 minutes)
: "${SEQUENCER_DEFAULT_TIMEOUT:=300}"
# Default retry count
: "${SEQUENCER_DEFAULT_RETRIES:=2}"
# Retry delay (seconds)
: "${SEQUENCER_RETRY_DELAY:=5}"

# Results tracking
declare -g -A _SEQUENCER_RESULTS=()
declare -g -A _SEQUENCER_TIMES=()
declare -g -a _SEQUENCER_ORDER=()

# =============================================================================
# SCRIPT METADATA PARSING
# =============================================================================

# Extract timeout from script header
# Usage: _sequencer_get_timeout "script.sh"
_sequencer_get_timeout() {
    local script="$1"
    local timeout

    # Look for # Timeout: N (seconds)
    timeout=$(grep -m1 '^# Timeout:' "$script" 2>/dev/null | sed 's/^# Timeout:[[:space:]]*//' | grep -o '^[0-9]*')

    if [[ -n "$timeout" ]]; then
        echo "$timeout"
    else
        echo "${SEQUENCER_DEFAULT_TIMEOUT}"
    fi
}

# Extract test criteria from script header
# Usage: _sequencer_get_test "script.sh"
_sequencer_get_test() {
    local script="$1"

    # Look for # Test: command
    grep -m1 '^# Test:' "$script" 2>/dev/null | sed 's/^# Test:[[:space:]]*//'
}

# Extract retry count from script header
# Usage: _sequencer_get_retries "script.sh"
_sequencer_get_retries() {
    local script="$1"
    local retries

    # Look for # Retries: N
    retries=$(grep -m1 '^# Retries:' "$script" 2>/dev/null | sed 's/^# Retries:[[:space:]]*//' | grep -o '^[0-9]*')

    if [[ -n "$retries" ]]; then
        echo "$retries"
    else
        echo "${SEQUENCER_DEFAULT_RETRIES}"
    fi
}

# Extract dependencies from script header
# Usage: _sequencer_get_deps "script.sh"
_sequencer_get_deps() {
    local script="$1"

    # Look for # Depends: script1.sh, script2.sh
    grep -m1 '^# Depends:' "$script" 2>/dev/null | sed 's/^# Depends:[[:space:]]*//'
}

# =============================================================================
# CORE EXECUTION
# =============================================================================

# Run a single script with timeout and retry
# Usage: sequencer_run "script.sh" [timeout] [retries]
sequencer_run() {
    local script="$1"
    local timeout="${2:-$(_sequencer_get_timeout "$script")}"
    local retries="${3:-$(_sequencer_get_retries "$script")}"

    local script_name
    script_name=$(basename "$script")

    log_debug "Sequencer: Running $script_name (timeout: ${timeout}s, retries: $retries)"

    local attempt=0
    local start_time
    local exit_code=1

    while [[ $attempt -le $retries ]]; do
        ((attempt++))

        if [[ $attempt -gt 1 ]]; then
            log_debug "Sequencer: Retry $((attempt-1))/$retries for $script_name"
            sleep "${SEQUENCER_RETRY_DELAY}"
        fi

        start_time=$(date +%s)

        # Run with timeout
        if _sequencer_execute_with_timeout "$script" "$timeout"; then
            exit_code=0
            break
        else
            exit_code=$?
            log_debug "Sequencer: $script_name failed (exit: $exit_code)"
        fi
    done

    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))

    # Record results
    _SEQUENCER_RESULTS["$script_name"]="$exit_code"
    _SEQUENCER_TIMES["$script_name"]="$duration"
    _SEQUENCER_ORDER+=("$script_name")

    # Run post-execution test if defined
    local test_cmd
    test_cmd=$(_sequencer_get_test "$script")
    if [[ -n "$test_cmd" && $exit_code -eq 0 ]]; then
        log_debug "Sequencer: Running test for $script_name: $test_cmd"
        if ! eval "$test_cmd" &>/dev/null; then
            log_warn "Test failed for $script_name"
            _SEQUENCER_RESULTS["$script_name"]="test_failed"
            return 1
        fi
    fi

    return $exit_code
}

# Execute script with timeout
_sequencer_execute_with_timeout() {
    local script="$1"
    local timeout="$2"

    # Use timeout command if available
    if command -v timeout &>/dev/null; then
        timeout "$timeout" bash "$script"
        return $?
    fi

    # Fallback: background process with manual timeout
    bash "$script" &
    local pid=$!

    local waited=0
    while kill -0 "$pid" 2>/dev/null; do
        sleep 1
        ((waited++))

        if [[ $waited -ge $timeout ]]; then
            log_warn "Timeout after ${timeout}s, killing script"
            kill -TERM "$pid" 2>/dev/null
            sleep 2
            kill -KILL "$pid" 2>/dev/null
            return 124  # timeout exit code
        fi
    done

    wait "$pid"
    return $?
}

# =============================================================================
# DEPENDENCY-AWARE EXECUTION
# =============================================================================

# Run script only after dependencies have succeeded
# Usage: sequencer_run_with_deps "script.sh"
sequencer_run_with_deps() {
    local script="$1"
    local script_name
    script_name=$(basename "$script")

    # Get dependencies
    local deps
    deps=$(_sequencer_get_deps "$script")

    if [[ -n "$deps" ]]; then
        log_debug "Sequencer: $script_name depends on: $deps"

        # Check each dependency
        local dep
        for dep in $(echo "$deps" | tr ',' ' '); do
            dep=$(echo "$dep" | xargs)  # trim whitespace

            local dep_result="${_SEQUENCER_RESULTS[$dep]:-}"

            if [[ -z "$dep_result" ]]; then
                log_warn "Dependency $dep not yet executed for $script_name"
                _SEQUENCER_RESULTS["$script_name"]="dep_not_run"
                return 1
            fi

            if [[ "$dep_result" != "0" ]]; then
                log_warn "Dependency $dep failed for $script_name (result: $dep_result)"
                _SEQUENCER_RESULTS["$script_name"]="dep_failed"
                return 1
            fi
        done
    fi

    # Dependencies satisfied, run the script
    sequencer_run "$script"
}

# =============================================================================
# TEST CRITERIA
# =============================================================================

# Run a test command
# Usage: sequencer_test "command" [description]
sequencer_test() {
    local cmd="$1"
    local desc="${2:-Test}"

    log_debug "Sequencer: Testing: $desc"

    if eval "$cmd" &>/dev/null; then
        log_debug "Sequencer: Test passed: $desc"
        return 0
    else
        log_debug "Sequencer: Test failed: $desc"
        return 1
    fi
}

# Common test predicates
sequencer_test_file_exists() {
    local file="$1"
    [[ -f "$file" ]]
}

sequencer_test_dir_exists() {
    local dir="$1"
    [[ -d "$dir" ]]
}

sequencer_test_command_exists() {
    local cmd="$1"
    command -v "$cmd" &>/dev/null
}

sequencer_test_port_listening() {
    local port="$1"
    if command -v nc &>/dev/null; then
        nc -z localhost "$port" 2>/dev/null
    elif command -v lsof &>/dev/null; then
        lsof -i ":$port" &>/dev/null
    else
        return 1
    fi
}

sequencer_test_url_responds() {
    local url="$1"
    local expected="${2:-200}"

    if command -v curl &>/dev/null; then
        local status
        status=$(curl -s -o /dev/null -w '%{http_code}' "$url" 2>/dev/null)
        [[ "$status" == "$expected" ]]
    else
        return 1
    fi
}

# =============================================================================
# RESULTS
# =============================================================================

# Get results summary
# Usage: sequencer_get_results
sequencer_get_results() {
    local passed=0
    local failed=0
    local total=0

    for script in "${_SEQUENCER_ORDER[@]}"; do
        ((total++))
        local result="${_SEQUENCER_RESULTS[$script]:-unknown}"

        if [[ "$result" == "0" ]]; then
            ((passed++))
        else
            ((failed++))
        fi
    done

    echo "total:$total passed:$passed failed:$failed"
}

# Show detailed results
sequencer_show_results() {
    echo ""
    log_section "Execution Results"
    echo ""

    for script in "${_SEQUENCER_ORDER[@]}"; do
        local result="${_SEQUENCER_RESULTS[$script]:-unknown}"
        local duration="${_SEQUENCER_TIMES[$script]:-0}"

        local status_icon
        local status_color

        case "$result" in
            0)
                status_icon="[OK]"
                status_color="${LOG_GREEN:-}"
                ;;
            test_failed)
                status_icon="[TEST]"
                status_color="${LOG_YELLOW:-}"
                ;;
            dep_failed|dep_not_run)
                status_icon="[SKIP]"
                status_color="${LOG_YELLOW:-}"
                ;;
            124)
                status_icon="[TIME]"
                status_color="${LOG_RED:-}"
                ;;
            *)
                status_icon="[FAIL]"
                status_color="${LOG_RED:-}"
                ;;
        esac

        printf "  %s%-6s%s %-40s %s(%ds)%s\n" \
            "$status_color" "$status_icon" "${LOG_NC:-}" \
            "$script" \
            "${LOG_GRAY:-}" "$duration" "${LOG_NC:-}"
    done

    echo ""
    local results
    results=$(sequencer_get_results)
    echo "  Summary: $results"
}

# Get list of failed scripts
sequencer_get_failed() {
    local failed=()

    for script in "${_SEQUENCER_ORDER[@]}"; do
        local result="${_SEQUENCER_RESULTS[$script]:-unknown}"
        if [[ "$result" != "0" ]]; then
            failed+=("$script")
        fi
    done

    printf '%s\n' "${failed[@]}"
}

# Reset sequencer state
sequencer_reset() {
    _SEQUENCER_RESULTS=()
    _SEQUENCER_TIMES=()
    _SEQUENCER_ORDER=()
}

# =============================================================================
# BATCH EXECUTION
# =============================================================================

# Run multiple scripts in order
# Usage: sequencer_run_batch script1.sh script2.sh ...
sequencer_run_batch() {
    local scripts=("$@")
    local failed=0

    sequencer_reset

    for script in "${scripts[@]}"; do
        if [[ -f "$script" ]]; then
            if ! sequencer_run_with_deps "$script"; then
                ((failed++))
            fi
        else
            log_warn "Script not found: $script"
            ((failed++))
        fi
    done

    return $failed
}

# Run all scripts in a directory (sorted by Phase metadata)
# Usage: sequencer_run_directory "/path/to/scripts"
sequencer_run_directory() {
    local dir="$1"
    local failed=0

    if [[ ! -d "$dir" ]]; then
        log_error "Directory not found: $dir"
        return 1
    fi

    sequencer_reset

    # Get scripts sorted by Phase number
    local scripts=()
    while IFS= read -r script; do
        scripts+=("$script")
    done < <(_sequencer_sort_by_phase "$dir")

    for script in "${scripts[@]}"; do
        if ! sequencer_run_with_deps "$script"; then
            ((failed++))
        fi
    done

    return $failed
}

# Sort scripts by Phase metadata
_sequencer_sort_by_phase() {
    local dir="$1"

    for script in "$dir"/*.sh; do
        [[ -f "$script" ]] || continue

        local phase
        phase=$(grep -m1 '^# Phase:' "$script" 2>/dev/null | grep -o '[0-9]*' || echo "99")
        echo "$phase:$script"
    done | sort -t: -k1 -n | cut -d: -f2
}

# =============================================================================
# STANDALONE EXECUTION
# =============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Minimal logging if not available
    if ! type log_debug &>/dev/null; then
        log_debug() { [[ "${VERBOSE:-}" == "true" ]] && echo "[DEBUG] $1"; }
        log_warn() { echo "[WARN] $1"; }
        log_error() { echo "[ERROR] $1"; }
        log_section() { echo ""; echo "=== $1 ==="; }
        LOG_GREEN='\033[0;32m'
        LOG_YELLOW='\033[0;33m'
        LOG_RED='\033[0;31m'
        LOG_GRAY='\033[0;90m'
        LOG_NC='\033[0m'
    fi

    case "${1:-}" in
        --run)
            shift
            sequencer_run "$@"
            sequencer_show_results
            ;;
        --batch)
            shift
            sequencer_run_batch "$@"
            sequencer_show_results
            ;;
        --dir)
            shift
            sequencer_run_directory "$@"
            sequencer_show_results
            ;;
        *)
            echo "Usage: $0 {--run script.sh|--batch s1.sh s2.sh|--dir /path}"
            exit 1
            ;;
    esac
fi
