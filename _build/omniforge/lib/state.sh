#!/usr/bin/env bash
# =============================================================================
# lib/state.sh - State Tracking
# =============================================================================
# Part of OmniForge - The Factory That Builds Universes
#
# Pure functions for tracking script completion state. No execution on source.
#
# Exports:
#   state_init, state_mark_success, state_has_succeeded, state_clear,
#   state_clear_all, state_show_status
#
# Dependencies:
#   lib/logging.sh
# =============================================================================

# Guard against double-sourcing
[[ -n "${_LIB_STATE_LOADED:-}" ]] && return 0
_LIB_STATE_LOADED=1

# =============================================================================
# STATE FILE MANAGEMENT
# =============================================================================

# State file path (set by caller or default)
: "${BOOTSTRAP_STATE_FILE:=}"

# Initialize state file for tracking script success
# Usage: state_init
state_init() {
    if [[ -z "${BOOTSTRAP_STATE_FILE}" ]]; then
        BOOTSTRAP_STATE_FILE="${PROJECT_ROOT:-.}/.bootstrap_state"
    fi

    if [[ ! -f "${BOOTSTRAP_STATE_FILE}" ]]; then
        if [[ "${DRY_RUN:-false}" == "true" ]]; then
            log_dry "touch ${BOOTSTRAP_STATE_FILE}"
        else
            touch "${BOOTSTRAP_STATE_FILE}"
            log_debug "Created state file: ${BOOTSTRAP_STATE_FILE}"
        fi
    fi
}

# =============================================================================
# STATE OPERATIONS
# =============================================================================

# Mark a script as successfully completed
# Usage: state_mark_success "foundation/init-nextjs.sh"
state_mark_success() {
    local key="$1"
    state_init

    # Check if already marked
    if grep -q "^${key}=" "${BOOTSTRAP_STATE_FILE}" 2>/dev/null; then
        log_debug "Already marked: ${key}"
        return 0
    fi

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_dry "echo '${key}=success:$(date -Is)' >> ${BOOTSTRAP_STATE_FILE}"
    else
        echo "${key}=success:$(date -Is 2>/dev/null || date '+%Y-%m-%dT%H:%M:%S')" >> "${BOOTSTRAP_STATE_FILE}"
        log_debug "Marked success: ${key}"
    fi
}

# Check if a script has already succeeded
# Usage: state_has_succeeded "foundation/init-nextjs.sh" && echo "already done"
state_has_succeeded() {
    local key="$1"
    state_init

    if grep -q "^${key}=success" "${BOOTSTRAP_STATE_FILE}" 2>/dev/null; then
        return 0
    fi
    return 1
}

# Clear/reset a specific script's state
# Usage: state_clear "foundation/init-nextjs.sh"
state_clear() {
    local key="$1"
    state_init

    if [[ -f "${BOOTSTRAP_STATE_FILE}" ]]; then
        if [[ "${DRY_RUN:-false}" == "true" ]]; then
            log_dry "Remove ${key} from state file"
        else
            sed -i.bak "/^${key}=/d" "${BOOTSTRAP_STATE_FILE}"
            rm -f "${BOOTSTRAP_STATE_FILE}.bak"
            log_info "Cleared state for: ${key}"
        fi
    fi
}

# Clear all state (reset bootstrap)
# Usage: state_clear_all
state_clear_all() {
    state_init

    if [[ -f "${BOOTSTRAP_STATE_FILE}" ]]; then
        if [[ "${DRY_RUN:-false}" == "true" ]]; then
            log_dry "rm ${BOOTSTRAP_STATE_FILE}"
        else
            rm -f "${BOOTSTRAP_STATE_FILE}"
            log_info "Cleared all bootstrap state"
        fi
    fi
}

# =============================================================================
# STATE REPORTING
# =============================================================================

# Count completed scripts
# Usage: completed=$(state_count_completed)
state_count_completed() {
    state_init
    grep -c "=success:" "${BOOTSTRAP_STATE_FILE}" 2>/dev/null || echo "0"
}

# List completed scripts
# Usage: state_list_completed
state_list_completed() {
    state_init

    if [[ ! -f "${BOOTSTRAP_STATE_FILE}" ]]; then
        return 0
    fi

    grep "=success:" "${BOOTSTRAP_STATE_FILE}" 2>/dev/null | while read -r line; do
        local script_name="${line%%=*}"
        local timestamp="${line##*:}"
        echo "  ✓ ${script_name} (${timestamp})"
    done
}

# Show bootstrap status summary
# Usage: state_show_status
state_show_status() {
    state_init

    log_info "=== Bootstrap Status ==="
    echo ""

    if [[ ! -f "${BOOTSTRAP_STATE_FILE}" ]]; then
        log_warn "No state file found. Bootstrap has not been run yet."
        return 0
    fi

    local completed
    completed=$(state_count_completed)

    echo "State file: ${BOOTSTRAP_STATE_FILE}"
    echo "Completed scripts: ${completed}"
    echo ""

    if [[ "${completed}" -gt 0 ]]; then
        echo "Completed:"
        state_list_completed
    fi
}

# Export state file path
export BOOTSTRAP_STATE_FILE
