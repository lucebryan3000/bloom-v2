#!/usr/bin/env bash
# =============================================================================
# Bootstrap Orchestrator
# =============================================================================
# Main entry point for running bootstrap scripts.
# Supports interactive mode, --all, and --steps options.
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${ROOT_DIR}/scripts/bootstrap"
COMMON_SH="${SCRIPTS_DIR}/lib/common.sh"

if [[ ! -f "${COMMON_SH}" ]]; then
    echo "[ERROR] common.sh not found at ${COMMON_SH}" >&2
    exit 1
fi

# shellcheck source=/dev/null
. "${COMMON_SH}"

# =============================================================================
# USAGE
# =============================================================================

usage() {
    cat <<EOF
Bootstrap Orchestrator for ${APP_NAME:-project}

USAGE:
    ./run-bootstrap.sh                  Interactive mode (menu-driven)
    ./run-bootstrap.sh --all            Run all scripts in default order
    ./run-bootstrap.sh --steps "..."    Run specific scripts in given order
    ./run-bootstrap.sh -n --all         Dry-run of all scripts
    ./run-bootstrap.sh --help           Show this help

OPTIONS:
    -h, --help          Show this help message
    -n, --dry-run       Preview commands without executing
    --all               Run all scripts from BOOTSTRAP_STEPS_DEFAULT
    --steps "list"      Run only specified scripts (space-separated)
    --force             Ignore state file and re-run all scripts
    --reset-state       Clear the state file and exit

CONFIGURATION:
    Edit scripts/bootstrap/bootstrap.conf to customize:
    - APP_NAME, PROJECT_ROOT, DB_* settings
    - ENABLE_* feature flags
    - STACK_PROFILE (full|minimal|api-only)
    - BOOTSTRAP_RESUME_MODE (skip|force)
    - Script order via BOOTSTRAP_STEPS_DEFAULT

STATE FILE:
    ${BOOTSTRAP_STATE_FILE:-${PROJECT_ROOT}/.bootstrap_state}

EOF
}

# =============================================================================
# HELPERS
# =============================================================================

get_steps_array() {
    local steps_var="$1"
    local -a result=()
    while IFS= read -r line; do
        line="$(echo "${line}" | xargs)"
        if [[ -n "${line}" ]]; then
            result+=("${line}")
        fi
    done <<< "${steps_var}"
    echo "${result[@]}"
}

count_completed() {
    local -a steps=("$@")
    local count=0
    for step in "${steps[@]}"; do
        if has_script_succeeded "${step}"; then
            ((count++)) || true
        fi
    done
    echo "${count}"
}

run_script() {
    local script_path="$1"
    local full_path="${SCRIPTS_DIR}/${script_path}"

    if [[ ! -f "${full_path}" ]]; then
        log_error "Script not found: ${full_path}"
        return 1
    fi

    chmod +x "${full_path}"

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "DRY RUN: Would execute ${script_path}"
        bash "${full_path}" --dry-run
    else
        log_info "Executing: ${script_path}"
        if ! bash "${full_path}"; then
            log_error "Script failed: ${script_path}"
            return 1
        fi
    fi

    return 0
}

run_sequence() {
    local -a steps=("$@")
    local total="${#steps[@]}"
    local completed
    completed="$(count_completed "${steps[@]}")"
    local current=0

    log_info "=== Bootstrap Sequence ==="
    log_info "Total scripts: ${total}"
    log_info "Already completed: ${completed}"
    log_info "Resume mode: ${BOOTSTRAP_RESUME_MODE:-skip}"
    log_info ""

    for step in "${steps[@]}"; do
        ((current++)) || true

        if [[ "${BOOTSTRAP_RESUME_MODE:-skip}" == "skip" ]] && has_script_succeeded "${step}"; then
            log_info "[${current}/${total}] SKIP (already succeeded): ${step}"
            continue
        fi

        completed="$(count_completed "${steps[@]}")"
        log_info ""
        log_info "Progress: ${completed}/${total} completed"
        log_info "[${current}/${total}] Running: ${step}"

        if ! run_script "${step}"; then
            log_error ""
            log_error "=== Bootstrap Failed ==="
            log_error "Failed at: ${step}"
            log_error "To retry: ./run-bootstrap.sh --all"
            log_error "To force: ./run-bootstrap.sh --all --force"
            exit 1
        fi

        log_info "[${current}/${total}] Completed: ${step}"
    done

    completed="$(count_completed "${steps[@]}")"
    log_info ""
    log_info "=== Bootstrap Complete ==="
    log_info "All ${total} scripts executed successfully!"
    log_info "State saved to: ${BOOTSTRAP_STATE_FILE}"
}

interactive_menu() {
    local -a steps
    read -ra steps <<< "$(get_steps_array "${BOOTSTRAP_STEPS_DEFAULT}")"
    local total="${#steps[@]}"
    local completed
    completed="$(count_completed "${steps[@]}")"

    while true; do
        echo ""
        echo "=============================================="
        echo "  ${APP_NAME:-Project} Bootstrap"
        echo "=============================================="
        echo "  Progress: ${completed}/${total} scripts completed"
        echo "  State: ${BOOTSTRAP_STATE_FILE}"
        echo ""
        echo "  [1] Run all remaining scripts"
        echo "  [2] Run a single script"
        echo "  [3] Run all (force re-run)"
        echo "  [4] Dry-run all scripts"
        echo "  [5] View script list"
        echo "  [6] Reset state file"
        echo "  [q] Quit"
        echo ""
        read -rp "  Select option: " choice

        case "${choice}" in
            1)
                run_sequence "${steps[@]}"
                completed="$(count_completed "${steps[@]}")"
                ;;
            2)
                echo ""
                echo "Available scripts:"
                local idx=0
                for step in "${steps[@]}"; do
                    ((idx++)) || true
                    local status="[ ]"
                    if has_script_succeeded "${step}"; then
                        status="[x]"
                    fi
                    echo "  ${idx}. ${status} ${step}"
                done
                echo ""
                read -rp "  Enter script number (or 0 to cancel): " script_num

                if [[ "${script_num}" =~ ^[0-9]+$ ]] && [[ "${script_num}" -gt 0 ]] && [[ "${script_num}" -le "${#steps[@]}" ]]; then
                    local selected="${steps[$((script_num-1))]}"
                    run_script "${selected}"
                    completed="$(count_completed "${steps[@]}")"
                fi
                ;;
            3)
                BOOTSTRAP_RESUME_MODE="force"
                run_sequence "${steps[@]}"
                BOOTSTRAP_RESUME_MODE="skip"
                completed="$(count_completed "${steps[@]}")"
                ;;
            4)
                DRY_RUN="true"
                run_sequence "${steps[@]}"
                DRY_RUN="false"
                ;;
            5)
                echo ""
                echo "Script execution order:"
                local idx=0
                for step in "${steps[@]}"; do
                    ((idx++)) || true
                    local status="pending"
                    if has_script_succeeded "${step}"; then
                        status="completed"
                    fi
                    echo "  ${idx}. [${status}] ${step}"
                done
                echo ""
                read -rp "Press Enter to continue..." _
                ;;
            6)
                if [[ -f "${BOOTSTRAP_STATE_FILE}" ]]; then
                    rm "${BOOTSTRAP_STATE_FILE}"
                    log_info "State file cleared"
                    completed=0
                else
                    log_info "No state file to clear"
                fi
                ;;
            q|Q)
                echo "Goodbye!"
                exit 0
                ;;
            *)
                echo "Invalid option"
                ;;
        esac
    done
}

# =============================================================================
# MAIN
# =============================================================================

main() {
    local mode="interactive"
    local custom_steps=""
    local force_mode="false"
    local reset_state="false"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            -n|--dry-run)
                DRY_RUN="true"
                shift
                ;;
            --all)
                mode="all"
                shift
                ;;
            --steps)
                mode="custom"
                custom_steps="$2"
                shift 2
                ;;
            --force)
                force_mode="true"
                shift
                ;;
            --reset-state)
                reset_state="true"
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done

    # Preflight checks
    require_cmd node
    require_cmd pnpm
    require_cmd git
    check_tool_versions

    # Handle reset state
    if [[ "${reset_state}" == "true" ]]; then
        if [[ -f "${BOOTSTRAP_STATE_FILE}" ]]; then
            rm "${BOOTSTRAP_STATE_FILE}"
            log_info "State file cleared: ${BOOTSTRAP_STATE_FILE}"
        fi
        exit 0
    fi

    # Git safety (skip in dry-run)
    if [[ "${DRY_RUN:-false}" != "true" ]]; then
        ensure_git_clean
    fi

    # Handle force mode
    if [[ "${force_mode}" == "true" ]]; then
        BOOTSTRAP_RESUME_MODE="force"
    fi

    # Execute based on mode
    case "${mode}" in
        interactive)
            interactive_menu
            ;;
        all)
            local -a steps
            read -ra steps <<< "$(get_steps_array "${BOOTSTRAP_STEPS_DEFAULT}")"
            run_sequence "${steps[@]}"
            ;;
        custom)
            local -a steps
            read -ra steps <<< "${custom_steps}"
            run_sequence "${steps[@]}"
            ;;
    esac
}

main "$@"
