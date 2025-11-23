#!/usr/bin/env bash
# =============================================================================
# Bloom2 Bootstrap Orchestrator
# Master script for running all bootstrap scripts
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# =============================================================================
# CONFIGURATION
# =============================================================================

readonly VERSION="1.0.0"
readonly PHASES=(
    "00-foundation:Project Foundation:4"
    "01-docker:Docker Infrastructure:3"
    "02-database:Database Layer:4"
    "03-security:Environment & Security:4"
    "04-auth:Authentication:2"
    "05-ai:AI Integration:3"
    "06-state:State Management:2"
    "07-jobs:Background Jobs:2"
    "08-observability:Observability:2"
    "09-ui:UI Components:3"
    "10-testing:Testing Infrastructure:3"
    "11-quality:Code Quality:3"
)

# LLM breakpoints
readonly BREAKPOINTS=("05-ai" "09-ui")

# =============================================================================
# USAGE
# =============================================================================

usage() {
    cat <<EOF
Bloom2 Bootstrap Orchestrator v${VERSION}

Usage: $(basename "$0") [OPTIONS] [COMMAND]

COMMANDS:
    run             Run all phases (default)
    phase <name>    Run specific phase
    script <num>    Run specific script number
    list            List all phases and scripts
    status          Show completion status

OPTIONS:
    -h, --help      Show this help
    -n, --dry-run   Preview without executing
    -v, --verbose   Verbose output
    --skip-breaks   Skip LLM breakpoints
    --from <num>    Start from script number

EXAMPLES:
    $(basename "$0")                    # Run all phases
    $(basename "$0") --dry-run          # Preview all
    $(basename "$0") phase 02-database  # Run database phase
    $(basename "$0") script 08          # Run script 08
    $(basename "$0") list               # List all scripts
EOF
}

# =============================================================================
# HELPERS
# =============================================================================

list_phases() {
    echo ""
    echo "PHASES AND SCRIPTS"
    echo "=================="
    echo ""

    for phase_info in "${PHASES[@]}"; do
        IFS=':' read -r phase_id phase_name script_count <<< "$phase_info"
        echo "Phase: $phase_id - $phase_name ($script_count scripts)"

        local phase_dir="$SCRIPT_DIR/phases/$phase_id"
        if [[ -d "$phase_dir" ]]; then
            for script in "$phase_dir"/*.sh; do
                if [[ -f "$script" ]]; then
                    local script_name=$(basename "$script")
                    echo "  - $script_name"
                fi
            done
        fi
        echo ""
    done
}

run_script() {
    local script_path="$1"
    local script_name=$(basename "$script_path")

    log_step "Running: $script_name"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry "bash $script_path"
        return 0
    fi

    if bash "$script_path"; then
        log_success "$script_name completed"
        return 0
    else
        log_error "$script_name failed"
        return 1
    fi
}

run_phase() {
    local phase_id="$1"
    local phase_dir="$SCRIPT_DIR/phases/$phase_id"

    if [[ ! -d "$phase_dir" ]]; then
        log_error "Phase not found: $phase_id"
        return 1
    fi

    log_info "=== Running Phase: $phase_id ==="

    for script in "$phase_dir"/*.sh; do
        if [[ -f "$script" ]]; then
            run_script "$script" || return 1
        fi
    done

    # Check for breakpoint
    for bp in "${BREAKPOINTS[@]}"; do
        if [[ "$phase_id" == "$bp" && "$SKIP_BREAKPOINTS" != "true" ]]; then
            log_warn ""
            log_warn "=== LLM BREAKPOINT ==="
            log_warn "Phase $phase_id complete. This is a good point for LLM customization."
            log_warn "Review generated files before continuing."
            log_warn ""

            if [[ "$DRY_RUN" != "true" ]]; then
                read -r -p "Continue to next phase? [Y/n] " response
                if [[ "$response" =~ ^[Nn] ]]; then
                    log_info "Stopping at breakpoint. Resume with: $0 --from <next-script>"
                    exit 0
                fi
            fi
        fi
    done

    return 0
}

run_all() {
    log_info "=== Bloom2 Bootstrap Orchestrator ==="
    log_info "Running all phases..."
    echo ""

    for phase_info in "${PHASES[@]}"; do
        IFS=':' read -r phase_id phase_name script_count <<< "$phase_info"
        run_phase "$phase_id" || {
            log_error "Failed at phase: $phase_id"
            exit 1
        }
    done

    log_success ""
    log_success "=== Bootstrap Complete ==="
    log_success "All 35 scripts executed successfully!"
    log_success ""
    log_info "Next steps:"
    log_info "  1. Review generated files"
    log_info "  2. Run: pnpm install"
    log_info "  3. Run: docker compose up -d"
    log_info "  4. Run: pnpm dev"
}

# =============================================================================
# MAIN
# =============================================================================

SKIP_BREAKPOINTS=false
COMMAND="run"
TARGET=""

# Parse arguments
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
        --skip-breaks)
            SKIP_BREAKPOINTS=true
            shift
            ;;
        run|list|status)
            COMMAND="$1"
            shift
            ;;
        phase)
            COMMAND="phase"
            TARGET="${2:-}"
            shift 2
            ;;
        script)
            COMMAND="script"
            TARGET="${2:-}"
            shift 2
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Initialize logging
init_logging "orchestrate"

# Execute command
case $COMMAND in
    run)
        run_all
        ;;
    list)
        list_phases
        ;;
    phase)
        if [[ -z "$TARGET" ]]; then
            log_error "Phase name required"
            exit 1
        fi
        run_phase "$TARGET"
        ;;
    script)
        if [[ -z "$TARGET" ]]; then
            log_error "Script number required"
            exit 1
        fi
        # Find script by number
        script_file=$(find "$SCRIPT_DIR/phases" -name "${TARGET}-*.sh" 2>/dev/null | head -1)
        if [[ -z "$script_file" ]]; then
            log_error "Script not found: $TARGET"
            exit 1
        fi
        run_script "$script_file"
        ;;
    *)
        log_error "Unknown command: $COMMAND"
        usage
        exit 1
        ;;
esac
