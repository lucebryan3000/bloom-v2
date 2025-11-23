#!/usr/bin/env bash
# =============================================================================
# checkpoint.sh - State management for bootstrap resumption
# =============================================================================
# Provides checkpoint/restore functionality for interrupted bootstrap runs
# =============================================================================

set -euo pipefail

# Default paths (can be overridden)
STATE_DIR="${STATE_DIR:-scripts/bootstrap/state}"
STATE_FILE="${STATE_FILE:-${STATE_DIR}/.bootstrap-state}"
CHECKPOINT_FILE="${CHECKPOINT_FILE:-${STATE_DIR}/.checkpoint}"
HANDOFF_DIR="${HANDOFF_DIR:-${STATE_DIR}/handoffs}"

# =============================================================================
# State File Management
# =============================================================================

# Initialize state file if it doesn't exist
init_state() {
    mkdir -p "${STATE_DIR}"
    mkdir -p "${HANDOFF_DIR}"

    if [[ ! -f "${STATE_FILE}" ]]; then
        cat > "${STATE_FILE}" << EOF
# Bootstrap State File
# Generated: $(date +"%Y-%m-%d %H:%M:%S")
# Format: TYPE:KEY:STATUS[:TIMESTAMP]
#   TYPE: SCRIPT, PHASE, or CHECKPOINT
#   KEY: Script path or phase ID
#   STATUS: pending, in_progress, completed, failed, skipped
EOF
        echo "STATE:initialized:$(date +%s)" >> "${STATE_FILE}"
    fi
}

# Mark a script as completed
mark_script_done() {
    local script_key="$1"
    local status="${2:-completed}"
    local timestamp
    timestamp=$(date +%s)

    init_state

    # Remove any existing entry for this script
    if [[ -f "${STATE_FILE}" ]]; then
        grep -v "^SCRIPT:${script_key}:" "${STATE_FILE}" > "${STATE_FILE}.tmp" || true
        mv "${STATE_FILE}.tmp" "${STATE_FILE}"
    fi

    echo "SCRIPT:${script_key}:${status}:${timestamp}" >> "${STATE_FILE}"
}

# Mark a phase as completed
mark_phase_done() {
    local phase_id="$1"
    local status="${2:-completed}"
    local timestamp
    timestamp=$(date +%s)

    init_state

    # Remove any existing entry for this phase
    if [[ -f "${STATE_FILE}" ]]; then
        grep -v "^PHASE:${phase_id}:" "${STATE_FILE}" > "${STATE_FILE}.tmp" || true
        mv "${STATE_FILE}.tmp" "${STATE_FILE}"
    fi

    echo "PHASE:${phase_id}:${status}:${timestamp}" >> "${STATE_FILE}"
}

# Check if a script has completed successfully
has_script_completed() {
    local script_key="$1"
    [[ -f "${STATE_FILE}" ]] && grep -q "^SCRIPT:${script_key}:completed:" "${STATE_FILE}"
}

# Check if a phase has completed successfully
has_phase_completed() {
    local phase_id="$1"
    [[ -f "${STATE_FILE}" ]] && grep -q "^PHASE:${phase_id}:completed:" "${STATE_FILE}"
}

# Get script status
get_script_status() {
    local script_key="$1"
    if [[ -f "${STATE_FILE}" ]]; then
        grep "^SCRIPT:${script_key}:" "${STATE_FILE}" | tail -1 | cut -d: -f3
    else
        echo "pending"
    fi
}

# Get phase status
get_phase_status() {
    local phase_id="$1"
    if [[ -f "${STATE_FILE}" ]]; then
        grep "^PHASE:${phase_id}:" "${STATE_FILE}" | tail -1 | cut -d: -f3
    else
        echo "pending"
    fi
}

# =============================================================================
# Checkpoint Management
# =============================================================================

# Save a checkpoint (for resume after interruption)
save_checkpoint() {
    local phase_id="$1"
    local script_key="${2:-}"
    local timestamp
    timestamp=$(date +%s)

    init_state

    cat > "${CHECKPOINT_FILE}" << EOF
# Bootstrap Checkpoint
# Saved: $(date +"%Y-%m-%d %H:%M:%S")
CHECKPOINT_PHASE="${phase_id}"
CHECKPOINT_SCRIPT="${script_key}"
CHECKPOINT_TIMESTAMP="${timestamp}"
EOF
}

# Load checkpoint (returns phase to resume from)
load_checkpoint() {
    if [[ -f "${CHECKPOINT_FILE}" ]]; then
        source "${CHECKPOINT_FILE}"
        echo "${CHECKPOINT_PHASE:-}"
    fi
}

# Get checkpoint script (returns script to resume from within phase)
get_checkpoint_script() {
    if [[ -f "${CHECKPOINT_FILE}" ]]; then
        source "${CHECKPOINT_FILE}"
        echo "${CHECKPOINT_SCRIPT:-}"
    fi
}

# Clear checkpoint after successful completion
clear_checkpoint() {
    rm -f "${CHECKPOINT_FILE}"
}

# =============================================================================
# Progress Reporting
# =============================================================================

# Get overall progress
get_progress() {
    local total_scripts=35
    local completed=0

    if [[ -f "${STATE_FILE}" ]]; then
        completed=$(grep -c "^SCRIPT:.*:completed:" "${STATE_FILE}" 2>/dev/null || echo 0)
    fi

    echo "${completed}/${total_scripts}"
}

# Get phase progress
get_phase_progress() {
    local phase_id="$1"
    local total=0
    local completed=0

    # Count scripts in this phase
    case "${phase_id}" in
        foundation) total=4 ;;
        docker) total=3 ;;
        db) total=4 ;;
        env) total=4 ;;
        auth) total=2 ;;
        ai) total=3 ;;
        state) total=2 ;;
        jobs) total=2 ;;
        observability) total=2 ;;
        ui) total=3 ;;
        testing) total=3 ;;
        quality) total=3 ;;
        *) total=0 ;;
    esac

    if [[ -f "${STATE_FILE}" ]]; then
        completed=$(grep -c "^SCRIPT:${phase_id}/.*:completed:" "${STATE_FILE}" 2>/dev/null || echo 0)
    fi

    echo "${completed}/${total}"
}

# Print status summary
print_status_summary() {
    echo "=== Bootstrap Status ==="
    echo "Progress: $(get_progress)"
    echo ""
    echo "Phase Status:"

    local phases=("foundation" "docker" "db" "env" "auth" "ai" "state" "jobs" "observability" "ui" "testing" "quality")

    for phase in "${phases[@]}"; do
        local status
        status=$(get_phase_status "${phase}")
        local progress
        progress=$(get_phase_progress "${phase}")

        local icon="○"
        case "${status}" in
            completed) icon="✓" ;;
            in_progress) icon="●" ;;
            failed) icon="✗" ;;
            skipped) icon="−" ;;
        esac

        printf "  %s %-15s [%s] %s\n" "${icon}" "${phase}" "${progress}" "${status}"
    done

    if [[ -f "${CHECKPOINT_FILE}" ]]; then
        echo ""
        echo "Checkpoint: $(load_checkpoint)"
        echo "Resume with: ./run-bootstrap.sh --resume"
    fi
}

# =============================================================================
# Reset Functions
# =============================================================================

# Reset all state (full restart)
reset_state() {
    rm -f "${STATE_FILE}"
    rm -f "${CHECKPOINT_FILE}"
    rm -rf "${HANDOFF_DIR:?}"/*
    init_state
    echo "State reset complete"
}

# Reset a specific phase
reset_phase() {
    local phase_id="$1"

    if [[ -f "${STATE_FILE}" ]]; then
        grep -v "^SCRIPT:${phase_id}/" "${STATE_FILE}" > "${STATE_FILE}.tmp" || true
        grep -v "^PHASE:${phase_id}:" "${STATE_FILE}.tmp" > "${STATE_FILE}" || true
        rm -f "${STATE_FILE}.tmp"
    fi

    echo "Phase ${phase_id} reset"
}

# =============================================================================
# Main (for standalone testing)
# =============================================================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        init) init_state ;;
        status) print_status_summary ;;
        reset) reset_state ;;
        reset-phase) reset_phase "${2:-}" ;;
        mark-script) mark_script_done "${2:-}" "${3:-completed}" ;;
        mark-phase) mark_phase_done "${2:-}" "${3:-completed}" ;;
        progress) get_progress ;;
        *)
            echo "Usage: $0 {init|status|reset|reset-phase|mark-script|mark-phase|progress}"
            exit 1
            ;;
    esac
fi
