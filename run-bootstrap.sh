#!/usr/bin/env bash
# =============================================================================
# Bootstrap Orchestrator v2.0
# =============================================================================
# Main entry point for running bootstrap scripts.
# Supports interactive mode, phase/script selection, breakpoints, and resume.
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

# =============================================================================
# PATHS & SETUP
# =============================================================================

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${ROOT_DIR}/scripts/bootstrap"
CONFIG_DIR="${SCRIPTS_DIR}/config"
STATE_DIR="${SCRIPTS_DIR}/state"
LIB_DIR="${SCRIPTS_DIR}/lib"
LOG_DIR="${SCRIPTS_DIR}/logs"

# Ensure directories exist
mkdir -p "${STATE_DIR}" "${LOG_DIR}"

# Source libraries
for lib in common.sh preflight.sh; do
    if [[ -f "${LIB_DIR}/${lib}" ]]; then
        # shellcheck source=/dev/null
        . "${LIB_DIR}/${lib}"
    fi
done

# Source config files
for conf in defaults.conf phases.conf breakpoints.conf; do
    if [[ -f "${CONFIG_DIR}/${conf}" ]]; then
        # shellcheck source=/dev/null
        . "${CONFIG_DIR}/${conf}"
    fi
done

# Source checkpoint functions
if [[ -f "${STATE_DIR}/checkpoint.sh" ]]; then
    # shellcheck source=/dev/null
    . "${STATE_DIR}/checkpoint.sh"
fi

# Initialize logging
LOG_FILE="${LOG_DIR}/bootstrap-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "${LOG_FILE}") 2>&1

# =============================================================================
# COLOR OUTPUT
# =============================================================================

if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' CYAN='' BOLD='' NC=''
fi

# =============================================================================
# GLOBAL STATE
# =============================================================================

DRY_RUN="${DRY_RUN:-false}"
SKIP_BREAKPOINTS="${SKIP_BREAKPOINTS:-false}"
SKIP_PREFLIGHT="${SKIP_PREFLIGHT:-false}"
FORCE_MODE="${FORCE_MODE:-false}"
AUTO_CONFIRM="${AUTO_CONFIRM:-false}"
VERBOSE="${VERBOSE:-false}"

STATE_FILE="${STATE_DIR}/.bootstrap-state"
CHECKPOINT_FILE="${STATE_DIR}/.checkpoint"
HANDOFF_DIR="${STATE_DIR}/handoffs"

mkdir -p "${HANDOFF_DIR}"

# =============================================================================
# USAGE
# =============================================================================

usage() {
    cat <<EOF
${BOLD}Bootstrap Orchestrator v2.0${NC}

${CYAN}USAGE:${NC}
    ./run-bootstrap.sh                      Interactive mode (menu-driven)
    ./run-bootstrap.sh --all                Run all phases sequentially
    ./run-bootstrap.sh --phase <name>       Run a specific phase
    ./run-bootstrap.sh --script <path>      Run a specific script
    ./run-bootstrap.sh --resume             Resume from last checkpoint
    ./run-bootstrap.sh --status             Show current progress

${CYAN}OPTIONS:${NC}
    -h, --help              Show this help message
    -n, --dry-run           Preview commands without executing
    -v, --verbose           Show detailed output
    --all                   Run all phases from start to finish
    --phase <name>          Run a specific phase (e.g., foundation, db, auth)
    --script <path>         Run a specific script (e.g., db/drizzle-setup.sh)
    --from <phase>          Start from a specific phase (skip earlier phases)
    --resume                Resume from last checkpoint
    --force                 Ignore state and re-run all scripts
    --skip-breakpoints      Don't pause at LLM/human breakpoints
    --skip-preflight        Skip pre-flight validation checks
    --yes, -y               Auto-confirm all prompts
    --status                Show bootstrap progress and exit
    --reset                 Clear all state and exit
    --list-phases           List all available phases
    --list-scripts          List all available scripts

${CYAN}EXAMPLES:${NC}
    ./run-bootstrap.sh                      # Interactive menu
    ./run-bootstrap.sh --all                # Full bootstrap
    ./run-bootstrap.sh --all --dry-run      # Preview what would run
    ./run-bootstrap.sh --phase db           # Run only database phase
    ./run-bootstrap.sh --from auth          # Start from auth phase
    ./run-bootstrap.sh --resume             # Continue after interruption

${CYAN}CONFIG FILES:${NC}
    scripts/bootstrap/bootstrap.conf        User configuration
    scripts/bootstrap/config/defaults.conf  Default values
    scripts/bootstrap/config/phases.conf    Phase definitions
    scripts/bootstrap/config/breakpoints.conf  LLM handoff points

${CYAN}LOG FILE:${NC}
    ${LOG_FILE}

EOF
}

# =============================================================================
# LOGGING HELPERS
# =============================================================================

log() {
    local level="$1"
    shift
    local timestamp
    timestamp=$(date +"%H:%M:%S")
    case "${level}" in
        INFO)  echo -e "${BLUE}[${timestamp}]${NC} $*" ;;
        OK)    echo -e "${GREEN}[${timestamp}] ✓${NC} $*" ;;
        WARN)  echo -e "${YELLOW}[${timestamp}] ⚠${NC} $*" ;;
        ERROR) echo -e "${RED}[${timestamp}] ✗${NC} $*" ;;
        STEP)  echo -e "${CYAN}[${timestamp}] ►${NC} $*" ;;
        *)     echo -e "[${timestamp}] $*" ;;
    esac
}

# =============================================================================
# STATE MANAGEMENT
# =============================================================================

init_state() {
    if [[ ! -f "${STATE_FILE}" ]]; then
        cat > "${STATE_FILE}" << EOF
# Bootstrap State - Generated $(date +"%Y-%m-%d %H:%M:%S")
# Format: TYPE:KEY:STATUS:TIMESTAMP
EOF
    fi
}

mark_script_complete() {
    local script_key="$1"
    local status="${2:-completed}"
    init_state
    local ts
    ts=$(date +%s)
    # Remove existing entry
    grep -v "^SCRIPT:${script_key}:" "${STATE_FILE}" > "${STATE_FILE}.tmp" 2>/dev/null || true
    mv "${STATE_FILE}.tmp" "${STATE_FILE}"
    echo "SCRIPT:${script_key}:${status}:${ts}" >> "${STATE_FILE}"
}

mark_phase_complete() {
    local phase_id="$1"
    local status="${2:-completed}"
    init_state
    local ts
    ts=$(date +%s)
    grep -v "^PHASE:${phase_id}:" "${STATE_FILE}" > "${STATE_FILE}.tmp" 2>/dev/null || true
    mv "${STATE_FILE}.tmp" "${STATE_FILE}"
    echo "PHASE:${phase_id}:${status}:${ts}" >> "${STATE_FILE}"
}

is_script_done() {
    local script_key="$1"
    [[ -f "${STATE_FILE}" ]] && grep -q "^SCRIPT:${script_key}:completed:" "${STATE_FILE}" 2>/dev/null
}

is_phase_done() {
    local phase_id="$1"
    [[ -f "${STATE_FILE}" ]] && grep -q "^PHASE:${phase_id}:completed:" "${STATE_FILE}" 2>/dev/null
}

save_checkpoint() {
    local phase="$1"
    local script="${2:-}"
    echo "PHASE=${phase}" > "${CHECKPOINT_FILE}"
    echo "SCRIPT=${script}" >> "${CHECKPOINT_FILE}"
    echo "TIMESTAMP=$(date +%s)" >> "${CHECKPOINT_FILE}"
}

load_checkpoint() {
    if [[ -f "${CHECKPOINT_FILE}" ]]; then
        # shellcheck source=/dev/null
        source "${CHECKPOINT_FILE}"
        echo "${PHASE:-}"
    fi
}

clear_checkpoint() {
    rm -f "${CHECKPOINT_FILE}"
}

reset_all_state() {
    rm -f "${STATE_FILE}" "${CHECKPOINT_FILE}"
    rm -rf "${HANDOFF_DIR:?}"/*
    log INFO "All state cleared"
}

# =============================================================================
# PROGRESS DISPLAY
# =============================================================================

show_status() {
    echo ""
    echo -e "${BOLD}=== Bootstrap Status ===${NC}"
    echo ""

    local total_scripts=35
    local completed_scripts=0
    if [[ -f "${STATE_FILE}" ]]; then
        completed_scripts=$(grep -c "^SCRIPT:.*:completed:" "${STATE_FILE}" 2>/dev/null || echo 0)
    fi

    echo -e "Progress: ${GREEN}${completed_scripts}${NC}/${total_scripts} scripts"
    echo ""

    # Phase status
    echo -e "${BOLD}Phases:${NC}"
    local phase_order=("foundation" "docker" "db" "env" "auth" "ai" "state" "jobs" "observability" "ui" "testing" "quality")

    for phase in "${phase_order[@]}"; do
        local icon="○"
        local color="${NC}"

        if is_phase_done "${phase}"; then
            icon="●"
            color="${GREEN}"
        elif [[ -f "${STATE_FILE}" ]] && grep -q "^PHASE:${phase}:in_progress:" "${STATE_FILE}" 2>/dev/null; then
            icon="◐"
            color="${YELLOW}"
        fi

        printf "  ${color}%s${NC} %-15s\n" "${icon}" "${phase}"
    done

    echo ""

    # Checkpoint info
    if [[ -f "${CHECKPOINT_FILE}" ]]; then
        local checkpoint_phase
        checkpoint_phase=$(load_checkpoint)
        echo -e "Checkpoint: ${YELLOW}${checkpoint_phase}${NC}"
        echo "Resume with: ./run-bootstrap.sh --resume"
    fi

    echo ""
    echo "Log file: ${LOG_FILE}"
    echo ""
}

# =============================================================================
# PHASE LISTING
# =============================================================================

list_phases() {
    echo ""
    echo -e "${BOLD}=== Available Phases ===${NC}"
    echo ""

    local phase_order=("foundation" "docker" "db" "env" "auth" "ai" "state" "jobs" "observability" "ui" "testing" "quality")
    local phase_names=(
        "Project Foundation (4 scripts)"
        "Docker Infrastructure (3 scripts)"
        "Database Layer (4 scripts)"
        "Environment & Security (4 scripts)"
        "Authentication (2 scripts)"
        "AI Integration (3 scripts)"
        "State Management (2 scripts)"
        "Background Jobs (2 scripts)"
        "Observability (2 scripts)"
        "UI Components (3 scripts)"
        "Testing Infrastructure (3 scripts)"
        "Code Quality (3 scripts)"
    )

    local idx=0
    for phase in "${phase_order[@]}"; do
        ((idx++)) || true
        local status="pending"
        if is_phase_done "${phase}"; then
            status="${GREEN}completed${NC}"
        fi
        printf "  %2d. %-15s %s [%b]\n" "${idx}" "${phase}" "${phase_names[$((idx-1))]}" "${status}"
    done
    echo ""
}

list_scripts() {
    echo ""
    echo -e "${BOLD}=== Available Scripts ===${NC}"
    echo ""

    local idx=0
    while IFS= read -r script; do
        [[ -z "${script}" ]] && continue
        ((idx++)) || true
        local status="[ ]"
        if is_script_done "${script}"; then
            status="${GREEN}[✓]${NC}"
        fi
        printf "  %2d. %b %s\n" "${idx}" "${status}" "${script}"
    done <<< "${BOOTSTRAP_STEPS_DEFAULT:-}"
    echo ""
}

# =============================================================================
# SCRIPT EXECUTION
# =============================================================================

run_script() {
    local script_path="$1"
    local full_path="${SCRIPTS_DIR}/${script_path}"

    if [[ ! -f "${full_path}" ]]; then
        log ERROR "Script not found: ${full_path}"
        return 1
    fi

    chmod +x "${full_path}" 2>/dev/null || true

    log STEP "Running: ${script_path}"

    if [[ "${DRY_RUN}" == "true" ]]; then
        log INFO "DRY RUN: Would execute ${script_path}"
        echo "  Command: bash ${full_path}"

        # Still run with --dry-run flag to show what would happen
        if bash "${full_path}" --dry-run 2>/dev/null; then
            log OK "DRY RUN: ${script_path} (would succeed)"
        fi
        return 0
    fi

    local start_time
    start_time=$(date +%s)

    if bash "${full_path}"; then
        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))
        mark_script_complete "${script_path}" "completed"
        log OK "Completed: ${script_path} (${duration}s)"
        return 0
    else
        mark_script_complete "${script_path}" "failed"
        log ERROR "Failed: ${script_path}"
        return 1
    fi
}

# =============================================================================
# PHASE EXECUTION
# =============================================================================

get_phase_scripts() {
    local phase_id="$1"
    grep "^[[:space:]]*${phase_id}/" <<< "${BOOTSTRAP_STEPS_DEFAULT:-}" | tr -s '[:space:]' '\n' | grep -v '^$'
}

run_phase() {
    local phase_id="$1"
    local force="${2:-false}"

    log INFO ""
    log INFO "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log INFO "  Phase: ${BOLD}${phase_id}${NC}"
    log INFO "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Check if phase already done
    if [[ "${force}" != "true" ]] && is_phase_done "${phase_id}"; then
        log INFO "Phase already completed, skipping"
        return 0
    fi

    mark_phase_complete "${phase_id}" "in_progress"
    save_checkpoint "${phase_id}" ""

    # Get scripts for this phase
    local scripts
    scripts=$(get_phase_scripts "${phase_id}")

    if [[ -z "${scripts}" ]]; then
        log WARN "No scripts found for phase: ${phase_id}"
        return 0
    fi

    local script_count
    script_count=$(echo "${scripts}" | wc -l)
    local current=0

    while IFS= read -r script; do
        [[ -z "${script}" ]] && continue
        ((current++)) || true

        # Skip completed scripts unless forced
        if [[ "${force}" != "true" ]] && [[ "${FORCE_MODE}" != "true" ]] && is_script_done "${script}"; then
            log INFO "[${current}/${script_count}] SKIP: ${script} (already completed)"
            continue
        fi

        save_checkpoint "${phase_id}" "${script}"

        if ! run_script "${script}"; then
            log ERROR ""
            log ERROR "Phase ${phase_id} failed at: ${script}"
            log ERROR "To retry: ./run-bootstrap.sh --phase ${phase_id}"
            log ERROR "To resume: ./run-bootstrap.sh --resume"
            return 1
        fi
    done <<< "${scripts}"

    mark_phase_complete "${phase_id}" "completed"
    log OK "Phase ${phase_id} completed"

    # Check for breakpoint
    handle_breakpoint "${phase_id}"

    return 0
}

# =============================================================================
# BREAKPOINT HANDLING
# =============================================================================

handle_breakpoint() {
    local phase_id="$1"

    [[ "${SKIP_BREAKPOINTS}" == "true" ]] && return 0
    [[ "${DRY_RUN}" == "true" ]] && return 0

    # Check if this phase has a breakpoint
    local has_breakpoint="false"
    case "${phase_id}" in
        db|auth|ai|ui|quality)
            has_breakpoint="true"
            ;;
    esac

    [[ "${has_breakpoint}" != "true" ]] && return 0

    # Export handoff documentation
    export_handoff_doc "${phase_id}"

    log WARN ""
    log WARN "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log WARN "  🛑 BREAKPOINT: ${phase_id}"
    log WARN "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Show phase-specific instructions
    case "${phase_id}" in
        db)
            echo ""
            echo "DATABASE SETUP REQUIRED:"
            echo "  1. Start PostgreSQL: docker compose up -d"
            echo "  2. Update .env with DATABASE_URL"
            echo "  3. Run: pnpm db:push"
            echo ""
            echo "LLM HANDOFF: Review src/db/schema.ts and add domain tables"
            ;;
        auth)
            echo ""
            echo "AUTHENTICATION SETUP REQUIRED:"
            echo "  1. Generate NEXTAUTH_SECRET: openssl rand -base64 32"
            echo "  2. Add OAuth provider credentials to .env"
            echo ""
            echo "LLM HANDOFF: Configure providers in src/lib/auth/config.ts"
            ;;
        ai)
            echo ""
            echo "AI CONFIGURATION REQUIRED:"
            echo "  1. Add ANTHROPIC_API_KEY to .env"
            echo ""
            echo "LLM HANDOFF: Customize prompts in src/lib/ai/prompts/"
            ;;
        ui)
            echo ""
            echo "LLM HANDOFF: Customize components and theme"
            ;;
        quality)
            echo ""
            echo "FINAL VERIFICATION:"
            echo "  □ pnpm install"
            echo "  □ pnpm lint"
            echo "  □ pnpm build"
            echo "  □ pnpm dev"
            ;;
    esac

    local handoff_file="${HANDOFF_DIR}/${phase_id}-handoff.md"
    if [[ -f "${handoff_file}" ]]; then
        echo ""
        echo "Detailed instructions: ${handoff_file}"
    fi

    echo ""

    if [[ "${AUTO_CONFIRM}" == "true" ]]; then
        log INFO "Auto-continuing (--yes flag set)"
        return 0
    fi

    read -rp "Continue to next phase? [Y/n/q] " response
    case "${response}" in
        n|N)
            log INFO "Paused. Resume with: ./run-bootstrap.sh --resume"
            exit 0
            ;;
        q|Q)
            log INFO "Exiting. Resume with: ./run-bootstrap.sh --resume"
            exit 0
            ;;
    esac
}

export_handoff_doc() {
    local phase_id="$1"
    local output_file="${HANDOFF_DIR}/${phase_id}-handoff.md"

    cat > "${output_file}" << EOF
# LLM Handoff: ${phase_id}

**Generated:** $(date +"%Y-%m-%d %H:%M:%S")
**Phase:** ${phase_id}

---

## Files Created

$(list_phase_files "${phase_id}")

---

## Next Steps

$(get_phase_instructions "${phase_id}")

---

## Resume Command

\`\`\`bash
./run-bootstrap.sh --resume
\`\`\`
EOF

    log INFO "Handoff doc exported: ${output_file}"
}

list_phase_files() {
    local phase_id="$1"
    case "${phase_id}" in
        db)
            echo "- src/db/schema.ts"
            echo "- src/db/index.ts"
            echo "- drizzle.config.ts"
            ;;
        auth)
            echo "- src/lib/auth/config.ts"
            echo "- src/middleware.ts"
            echo "- src/app/api/auth/[...nextauth]/route.ts"
            ;;
        ai)
            echo "- src/lib/ai/client.ts"
            echo "- src/lib/ai/prompts/system.ts"
            echo "- src/app/api/chat/route.ts"
            ;;
        *)
            echo "(See phase scripts for created files)"
            ;;
    esac
}

get_phase_instructions() {
    local phase_id="$1"
    case "${phase_id}" in
        db)
            echo "1. Run: docker compose up -d"
            echo "2. Run: pnpm db:push"
            echo "3. Add domain-specific tables to schema.ts"
            ;;
        auth)
            echo "1. Generate NEXTAUTH_SECRET"
            echo "2. Configure OAuth providers"
            echo "3. Test: pnpm dev, then visit /login"
            ;;
        ai)
            echo "1. Add ANTHROPIC_API_KEY to .env"
            echo "2. Customize system prompts"
            echo "3. Test chat API endpoint"
            ;;
        *)
            echo "Continue to next phase"
            ;;
    esac
}

# =============================================================================
# RUN ALL PHASES
# =============================================================================

run_all_phases() {
    local start_from="${1:-}"
    local found_start="false"

    if [[ -z "${start_from}" ]]; then
        found_start="true"
    fi

    local phase_order=("foundation" "docker" "db" "env" "auth" "ai" "state" "jobs" "observability" "ui" "testing" "quality")

    log INFO ""
    log INFO "=============================================="
    log INFO "  ${BOLD}Bootstrap Starting${NC}"
    log INFO "=============================================="
    log INFO "  Phases: ${#phase_order[@]}"
    log INFO "  Mode: ${DRY_RUN:+DRY RUN}${DRY_RUN:-LIVE}"
    log INFO "  Force: ${FORCE_MODE}"
    log INFO "  Log: ${LOG_FILE}"
    log INFO "=============================================="

    for phase in "${phase_order[@]}"; do
        # Handle --from flag
        if [[ "${found_start}" != "true" ]]; then
            if [[ "${phase}" == "${start_from}" ]]; then
                found_start="true"
            else
                log INFO "Skipping phase: ${phase} (before start point)"
                continue
            fi
        fi

        if ! run_phase "${phase}"; then
            log ERROR ""
            log ERROR "Bootstrap failed at phase: ${phase}"
            exit 1
        fi
    done

    clear_checkpoint

    log OK ""
    log OK "=============================================="
    log OK "  ${BOLD}Bootstrap Complete!${NC}"
    log OK "=============================================="
    log OK "  All phases executed successfully"
    log OK ""
    log OK "  Next steps:"
    log OK "  1. Review generated files"
    log OK "  2. Run: pnpm install"
    log OK "  3. Run: pnpm dev"
    log OK "=============================================="
}

# =============================================================================
# INTERACTIVE MENU
# =============================================================================

interactive_menu() {
    while true; do
        echo ""
        echo -e "${BOLD}=============================================="
        echo -e "  Bootstrap Orchestrator${NC}"
        echo -e "${BOLD}==============================================${NC}"
        echo ""

        # Show progress
        local total=35
        local done=0
        if [[ -f "${STATE_FILE}" ]]; then
            done=$(grep -c "^SCRIPT:.*:completed:" "${STATE_FILE}" 2>/dev/null || echo 0)
        fi
        echo -e "  Progress: ${GREEN}${done}${NC}/${total} scripts completed"
        echo ""

        echo "  ${CYAN}[1]${NC} Run all phases"
        echo "  ${CYAN}[2]${NC} Run specific phase"
        echo "  ${CYAN}[3]${NC} Run specific script"
        echo "  ${CYAN}[4]${NC} Resume from checkpoint"
        echo "  ${CYAN}[5]${NC} Dry-run all phases"
        echo "  ${CYAN}[6]${NC} View status"
        echo "  ${CYAN}[7]${NC} List phases"
        echo "  ${CYAN}[8]${NC} List scripts"
        echo "  ${CYAN}[9]${NC} Reset state"
        echo "  ${CYAN}[p]${NC} Run pre-flight checks"
        echo "  ${CYAN}[q]${NC} Quit"
        echo ""
        read -rp "  Select option: " choice

        case "${choice}" in
            1)
                run_all_phases
                ;;
            2)
                echo ""
                list_phases
                read -rp "  Enter phase name: " phase_name
                if [[ -n "${phase_name}" ]]; then
                    run_phase "${phase_name}"
                fi
                ;;
            3)
                echo ""
                list_scripts
                read -rp "  Enter script path (e.g., db/drizzle-setup.sh): " script_path
                if [[ -n "${script_path}" ]]; then
                    run_script "${script_path}"
                fi
                ;;
            4)
                local checkpoint
                checkpoint=$(load_checkpoint)
                if [[ -n "${checkpoint}" ]]; then
                    log INFO "Resuming from: ${checkpoint}"
                    run_all_phases "${checkpoint}"
                else
                    log WARN "No checkpoint found"
                fi
                ;;
            5)
                DRY_RUN="true"
                run_all_phases
                DRY_RUN="false"
                ;;
            6)
                show_status
                ;;
            7)
                list_phases
                ;;
            8)
                list_scripts
                ;;
            9)
                read -rp "  Reset all state? [y/N] " confirm
                if [[ "${confirm}" =~ ^[Yy]$ ]]; then
                    reset_all_state
                fi
                ;;
            p|P)
                run_preflight
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
    local phase_name=""
    local script_path=""
    local start_from=""

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
            -v|--verbose)
                VERBOSE="true"
                shift
                ;;
            -y|--yes)
                AUTO_CONFIRM="true"
                shift
                ;;
            --all)
                mode="all"
                shift
                ;;
            --phase)
                mode="phase"
                phase_name="$2"
                shift 2
                ;;
            --script)
                mode="script"
                script_path="$2"
                shift 2
                ;;
            --from)
                start_from="$2"
                shift 2
                ;;
            --resume)
                mode="resume"
                shift
                ;;
            --force)
                FORCE_MODE="true"
                shift
                ;;
            --skip-breakpoints)
                SKIP_BREAKPOINTS="true"
                shift
                ;;
            --skip-preflight)
                SKIP_PREFLIGHT="true"
                shift
                ;;
            --status)
                show_status
                exit 0
                ;;
            --reset)
                reset_all_state
                exit 0
                ;;
            --list-phases)
                list_phases
                exit 0
                ;;
            --list-scripts)
                list_scripts
                exit 0
                ;;
            *)
                log ERROR "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done

    # Initialize state
    init_state

    # Run pre-flight checks (unless skipped)
    if [[ "${SKIP_PREFLIGHT}" != "true" ]] && [[ "${mode}" != "interactive" ]]; then
        if type run_preflight &>/dev/null; then
            if ! run_preflight; then
                log ERROR "Pre-flight checks failed"
                exit 1
            fi
        fi
    fi

    # Execute based on mode
    case "${mode}" in
        interactive)
            interactive_menu
            ;;
        all)
            run_all_phases "${start_from}"
            ;;
        phase)
            run_phase "${phase_name}"
            ;;
        script)
            run_script "${script_path}"
            ;;
        resume)
            local checkpoint
            checkpoint=$(load_checkpoint)
            if [[ -n "${checkpoint}" ]]; then
                log INFO "Resuming from: ${checkpoint}"
                run_all_phases "${checkpoint}"
            else
                log WARN "No checkpoint found, starting from beginning"
                run_all_phases
            fi
            ;;
    esac
}

main "$@"
