#!/usr/bin/env bash
# =============================================================================
# Bloom2 Bootstrap Orchestrator
# Master script for running all bootstrap scripts
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# CONFIGURATION
# =============================================================================

readonly VERSION="2.0.0"

# Bootstrap config file paths (export before sourcing common.sh)
export SCRIPT_DIR
export BOOTSTRAP_CONF="${SCRIPT_DIR}/bootstrap.conf"
export BOOTSTRAP_CONF_EXAMPLE="${SCRIPT_DIR}/bootstrap.conf.example"
export LOG_DIR="${SCRIPT_DIR}/logs"

# Source common library (uses paths defined above)
source "$SCRIPT_DIR/lib/common.sh"

# =============================================================================
# CONFIG LOADING
# =============================================================================

# Load configuration from bootstrap.conf
# If bootstrap.conf doesn't exist, copy from .example or fail
load_config() {
    log_debug "Loading configuration..."

    if [[ ! -f "${BOOTSTRAP_CONF}" ]]; then
        if [[ -f "${BOOTSTRAP_CONF_EXAMPLE}" ]]; then
            log_info "First run detected - copying bootstrap.conf.example to bootstrap.conf"
            cp "${BOOTSTRAP_CONF_EXAMPLE}" "${BOOTSTRAP_CONF}"
        else
            log_error "Configuration file not found: ${BOOTSTRAP_CONF}"
            log_error "Also no example file found at: ${BOOTSTRAP_CONF_EXAMPLE}"
            exit 1
        fi
    fi

    # Save environment overrides (allow env vars to override config)
    local saved_dry_run="${DRY_RUN:-}"
    local saved_allow_dirty="${ALLOW_DIRTY:-}"
    local saved_git_safety="${GIT_SAFETY:-}"
    local saved_verbose="${VERBOSE:-}"
    local saved_log_format="${LOG_FORMAT:-}"

    # Source the configuration
    # shellcheck source=/dev/null
    source "${BOOTSTRAP_CONF}"

    # Restore environment overrides (env vars take precedence over config file)
    [[ -n "${saved_dry_run}" ]] && DRY_RUN="${saved_dry_run}"
    [[ -n "${saved_allow_dirty}" ]] && ALLOW_DIRTY="${saved_allow_dirty}"
    [[ -n "${saved_git_safety}" ]] && GIT_SAFETY="${saved_git_safety}"
    [[ -n "${saved_verbose}" ]] && VERBOSE="${saved_verbose}"
    [[ -n "${saved_log_format}" ]] && LOG_FORMAT="${saved_log_format}"

    # Validate PROJECT_ROOT exists
    if [[ -z "${PROJECT_ROOT:-}" ]]; then
        log_error "PROJECT_ROOT not set in bootstrap.conf"
        exit 1
    fi

    # Resolve PROJECT_ROOT if relative
    if [[ "${PROJECT_ROOT}" == "." ]]; then
        PROJECT_ROOT="${SCRIPT_DIR}/../.."
    fi
    PROJECT_ROOT="$(cd "${PROJECT_ROOT}" && pwd)"

    if [[ ! -d "${PROJECT_ROOT}" ]]; then
        log_error "PROJECT_ROOT does not exist: ${PROJECT_ROOT}"
        exit 1
    fi

    # Set SCRIPTS_DIR from config or default
    SCRIPTS_DIR="${SCRIPTS_DIR:-${SCRIPT_DIR}/tech_stack}"

    # Set state file path
    BOOTSTRAP_STATE_FILE="${PROJECT_ROOT}/.bootstrap_state"

    # Initialize state file
    init_state_file

    log_debug "Configuration loaded from: ${BOOTSTRAP_CONF}"
    log_debug "PROJECT_ROOT: ${PROJECT_ROOT}"
    log_debug "SCRIPTS_DIR: ${SCRIPTS_DIR}"
    log_debug "BOOTSTRAP_STATE_FILE: ${BOOTSTRAP_STATE_FILE}"
}

# Technology stack mapping (phase -> tech_stack directories)
# Maps logical phases to one or more technology directories
declare -A TECH_STACK=(
    ["00-foundation"]="foundation"
    ["01-docker"]="docker"
    ["02-database"]="db"
    ["03-security"]="env"
    ["04-auth"]="auth"
    ["05-ai"]="ai"
    ["06-state"]="state"
    ["07-jobs"]="jobs"
    ["08-observability"]="observability"
    ["09-ui"]="ui"
    ["10-testing"]="testing"
    ["11-quality"]="quality"
)

# Phase definitions with display names
readonly PHASES=(
    "00-foundation:Project Foundation"
    "01-docker:Docker Infrastructure"
    "02-database:Database Layer"
    "03-security:Environment & Security"
    "04-auth:Authentication"
    "05-ai:AI Integration"
    "06-state:State Management"
    "07-jobs:Background Jobs"
    "08-observability:Observability"
    "09-ui:UI Components"
    "10-testing:Testing Infrastructure"
    "11-quality:Code Quality"
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
    run             Run all phases (legacy phase-based execution)
    --all           Run config-driven script sequence (recommended)
    phase <name>    Run specific phase
    script <num>    Run specific script number
    list            List all phases and scripts
    status          Show completion status from .bootstrap_state

OPTIONS:
    -h, --help      Show this help
    -n, --dry-run   Preview without executing
    -v, --verbose   Verbose output
    --skip-breaks   Skip LLM breakpoints
    --from <num>    Start from script number
    --force         Force re-run (ignore previous success state)

EXAMPLES:
    $(basename "$0") --all              # Run config-driven bootstrap (recommended)
    $(basename "$0") --all --dry-run    # Preview config-driven run
    $(basename "$0") --all --force      # Force re-run all scripts
    $(basename "$0") run                # Run legacy phase-based execution
    $(basename "$0") --dry-run          # Preview legacy execution
    $(basename "$0") phase 02-database  # Run database phase
    $(basename "$0") script 08          # Run script 08
    $(basename "$0") list               # List all scripts
    $(basename "$0") status             # Show bootstrap progress
EOF
}

# =============================================================================
# HELPERS
# =============================================================================

list_phases() {
    echo ""
    echo "TECHNOLOGY STACK SCRIPTS"
    echo "========================"
    echo ""

    for phase_info in "${PHASES[@]}"; do
        IFS=':' read -r phase_id phase_name <<< "$phase_info" || true
        local tech_dirs="${TECH_STACK[$phase_id]:-}"

        echo "Phase: $phase_id - $phase_name"

        # Count total scripts in this phase
        local script_count=0
        # Use default IFS temporarily to split on spaces
        local IFS_OLD="$IFS"
        IFS=' '
        for tech_dir in $tech_dirs; do
            IFS="$IFS_OLD"
            local tech_path="$SCRIPT_DIR/tech_stack/$tech_dir"
            if [[ -d "$tech_path" ]]; then
                for script_file in "$tech_path"/*.sh; do
                    if [[ -f "$script_file" ]]; then
                        local script_name=$(basename "$script_file")
                        echo "  - tech_stack/$tech_dir/$script_name"
                        script_count=$((script_count + 1))
                    fi
                done
            fi
            IFS=' '
        done
        IFS="$IFS_OLD"

        echo "  Total: $script_count scripts"
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
    local tech_dirs="${TECH_STACK[$phase_id]}"

    if [[ -z "$tech_dirs" ]]; then
        log_error "Phase not found: $phase_id"
        return 1
    fi

    log_info "=== Running Phase: $phase_id ==="

    # Run scripts from all technology directories in this phase
    # Use default IFS temporarily to split on spaces
    local IFS_OLD="$IFS"
    IFS=' '
    for tech_dir in $tech_dirs; do
        IFS="$IFS_OLD"
        local tech_path="$SCRIPT_DIR/tech_stack/$tech_dir"
        if [[ -d "$tech_path" ]]; then
            for script in "$tech_path"/*.sh; do
                if [[ -f "$script" ]]; then
                    run_script "$script" || return 1
                fi
            done
        else
            log_warn "Technology directory not found: $tech_dir"
        fi
        IFS=' '
    done
    IFS="$IFS_OLD"

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
    log_info "Running all phases (legacy mode)..."
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
# CONFIG-DRIVEN EXECUTION (v2.0)
# =============================================================================

# Run all scripts using BOOTSTRAP_STEPS_DEFAULT from bootstrap.conf
# Supports resume mode and progress tracking
run_all_config() {
    log_info "=== Bloom2 Bootstrap Orchestrator (Config-Driven) ==="
    log_info "Reading script order from bootstrap.conf..."
    echo ""

    # Parse BOOTSTRAP_STEPS_DEFAULT into array (multiline string)
    local -a STEPS
    if [[ -z "${BOOTSTRAP_STEPS_DEFAULT:-}" ]]; then
        log_error "BOOTSTRAP_STEPS_DEFAULT not set in bootstrap.conf"
        exit 1
    fi

    # Convert multiline string to array, filtering empty lines
    mapfile -t STEPS < <(echo "${BOOTSTRAP_STEPS_DEFAULT}" | grep -v '^[[:space:]]*$')

    local TOTAL=${#STEPS[@]}
    local COMPLETED=0
    local SKIPPED=0

    log_info "Found ${TOTAL} scripts to execute"
    log_info "Resume mode: ${BOOTSTRAP_RESUME_MODE:-skip}"
    echo ""

    for script_path in "${STEPS[@]}"; do
        # Trim whitespace
        script_path="${script_path#"${script_path%%[![:space:]]*}"}"
        script_path="${script_path%"${script_path##*[![:space:]]}"}"

        # Skip empty lines
        [[ -z "${script_path}" ]] && continue

        local full_script_path="${SCRIPT_DIR}/tech_stack/${script_path}"
        local script_name=$(basename "${script_path}")

        # Check resume mode
        if [[ "${BOOTSTRAP_RESUME_MODE:-skip}" == "skip" ]] && [[ "${FORCE_RUN:-false}" != "true" ]]; then
            if has_script_succeeded "${script_path}"; then
                SKIPPED=$((SKIPPED + 1))
                log_skip "${script_path} (already completed)"
                continue
            fi
        fi

        COMPLETED=$((COMPLETED + 1))
        log_info "Progress: ${COMPLETED}/${TOTAL} - Running: ${script_path}"

        if [[ ! -f "${full_script_path}" ]]; then
            log_error "Script not found: ${full_script_path}"
            exit 1
        fi

        if run_script "${full_script_path}"; then
            mark_script_success "${script_path}"
        else
            log_error ""
            log_error "=== BOOTSTRAP FAILED ==="
            log_error "Script failed: ${script_path}"
            log_error "Progress: ${COMPLETED}/${TOTAL} scripts attempted"
            log_error "Resume with: $0 --all (will skip completed scripts)"
            exit 1
        fi
    done

    log_success ""
    log_success "=== Bootstrap Complete ==="
    log_success "Executed: ${COMPLETED} scripts"
    if [[ ${SKIPPED} -gt 0 ]]; then
        log_info "Skipped (already completed): ${SKIPPED} scripts"
    fi
    log_success ""
    log_info "Next steps:"
    log_info "  1. Review generated files"
    log_info "  2. Run: pnpm install"
    log_info "  3. Run: docker compose up -d"
    log_info "  4. Run: pnpm dev"
}

# Show bootstrap status from .bootstrap_state
show_status() {
    log_info "=== Bootstrap Status ==="
    echo ""

    if [[ ! -f "${BOOTSTRAP_STATE_FILE:-}" ]]; then
        log_warn "No state file found. Bootstrap has not been run yet."
        return 0
    fi

    local total_scripts=0
    local completed_scripts=0

    # Count total scripts from config
    if [[ -n "${BOOTSTRAP_STEPS_DEFAULT:-}" ]]; then
        total_scripts=$(echo "${BOOTSTRAP_STEPS_DEFAULT}" | grep -c '[^[:space:]]' 2>/dev/null) || total_scripts=0
    fi

    # Count completed scripts (grep -c returns 0 even on no match, but exits non-zero)
    completed_scripts=$(grep -c "=success:" "${BOOTSTRAP_STATE_FILE}" 2>/dev/null) || completed_scripts=0

    echo "State file: ${BOOTSTRAP_STATE_FILE}"
    echo "Total scripts in config: ${total_scripts}"
    echo "Completed scripts: ${completed_scripts}"
    echo ""

    if [[ "${completed_scripts}" -gt 0 ]]; then
        echo "Completed:"
        grep "=success:" "${BOOTSTRAP_STATE_FILE}" | while read -r line; do
            local script_name="${line%%=*}"
            local timestamp="${line##*:}"
            echo "  ✓ ${script_name} (${timestamp})"
        done
    fi
}

# =============================================================================
# MAIN
# =============================================================================

SKIP_BREAKPOINTS=false
COMMAND=""
TARGET=""
RUN_ALL=false
FORCE_RUN=false
SHOW_HELP=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            SHOW_HELP=true
            shift
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
        --all)
            RUN_ALL=true
            shift
            ;;
        --force)
            FORCE_RUN=true
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

# Show help if requested
if [[ "${SHOW_HELP}" == "true" ]]; then
    usage
    exit 0
fi

# Initialize logging
init_logging "orchestrator"

# Load configuration
load_config

# Apply stack profile overrides
apply_stack_profile

# Check git safety before running scripts
if [[ "${RUN_ALL}" == "true" || "${COMMAND}" == "run" ]]; then
    ensure_git_clean
fi

# Execute command
if [[ "${RUN_ALL}" == "true" ]]; then
    # Config-driven execution (v2.0)
    run_all_config
elif [[ -n "${COMMAND}" ]]; then
    case $COMMAND in
        run)
            # Legacy phase-based execution
            run_all
            ;;
        list)
            list_phases
            ;;
        status)
            show_status
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
            # Find script by number in tech_stack directories
            script_file=$(find "$SCRIPT_DIR/tech_stack" -name "${TARGET}*.sh" 2>/dev/null | head -1)
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
else
    # No command specified - show usage
    usage
    exit 0
fi
