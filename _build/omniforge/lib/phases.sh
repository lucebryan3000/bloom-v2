#!/usr/bin/env bash
# =============================================================================
# lib/phases.sh - Phase Discovery & Execution
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Pure functions for discovering and executing phases from omni.phases.sh.
# Reads PHASE_METADATA_N variables dynamically. No execution on source.
#
# Exports:
#   phase_discover, phase_execute, phase_execute_all, phase_list_all,
#   phase_get_name, phase_is_enabled
#
# Dependencies:
#   lib/logging.sh, lib/state.sh, lib/validation.sh
# =============================================================================

# Guard against double-sourcing
[[ -n "${_LIB_PHASES_LOADED:-}" ]] && return 0
_LIB_PHASES_LOADED=1

# =============================================================================
# ERROR TRACKING FOR DEFERRED HANDLING
# =============================================================================

# Error collection mode: "fail-fast" (default) or "continue"
: "${EXECUTION_MODE:=continue}"

# Track execution errors for deferred handling
declare -g -a _EXECUTION_ERRORS=()
declare -g -a _EXECUTION_WARNINGS=()
declare -g -a _FAILED_SCRIPTS=()
declare -g -a _COMPLETED_SCRIPTS=()
declare -g -a _SKIPPED_SCRIPTS=()

# Reset error tracking
_execution_reset() {
    _EXECUTION_ERRORS=()
    _EXECUTION_WARNINGS=()
    _FAILED_SCRIPTS=()
    _COMPLETED_SCRIPTS=()
    _SKIPPED_SCRIPTS=()
}

# Record a script failure
_execution_record_failure() {
    local script="$1"
    local error_msg="$2"
    local exit_code="${3:-1}"

    _FAILED_SCRIPTS+=("$script")
    _EXECUTION_ERRORS+=("$script: $error_msg (exit $exit_code)")
    log_file "FAILURE: $script - $error_msg (exit $exit_code)" "ERROR"
}

# Record a script success
_execution_record_success() {
    local script="$1"
    local duration="${2:-}"
    _COMPLETED_SCRIPTS+=("$script")
    log_file "SUCCESS: $script ${duration:+(${duration})}" "OK"
}

# Record a script skip
_execution_record_skip() {
    local script="$1"
    local reason="${2:-already completed}"
    _SKIPPED_SCRIPTS+=("$script")
    log_file "SKIP: $script - $reason" "SKIP"
}

# Check if a value exists in a named array (used for recaps)
_phase_array_contains() {
    local needle="$1"
    local array_name="$2"
    local -n arr="$array_name"
    for item in "${arr[@]}"; do
        if [[ "$item" == "$needle" ]]; then
            return 0
        fi
    done
    return 1
}

# Check if we should continue after an error
_execution_should_continue() {
    [[ "${EXECUTION_MODE}" == "continue" ]]
}

# =============================================================================
# PHASE DISCOVERY
# =============================================================================

# Discover all phases from PHASE_METADATA_N variables
# Returns array of phase numbers in order (space-separated)
# Usage: read -ra phases <<< "$(phase_discover)"
phase_discover() {
    local phase_nums=()
    local i

    # Look for PHASE_METADATA_0 through PHASE_METADATA_99
    for ((i=0; i<100; i++)); do
        local var_name="PHASE_METADATA_${i}"
        if [[ -n "${!var_name:-}" ]]; then
            phase_nums+=("$i")
        fi
    done

    echo "${phase_nums[*]}"
}

# Get a single field from PHASE_METADATA_N
# Format: "number:0|name:Project Foundation|description:..."
# Usage: name=$(phase_get_metadata_field "0" "name")
phase_get_metadata_field() {
    local phase_num="$1"
    local field_name="$2"

    local var_name="PHASE_METADATA_${phase_num}"
    local metadata="${!var_name:-}"

    if [[ -z "$metadata" ]]; then
        return 1
    fi

    # Parse pipe-separated key:value pairs
    local OLD_IFS="$IFS"
    IFS='|'
    for pair in $metadata; do
        local key="${pair%%:*}"
        local value="${pair#*:}"
        if [[ "$key" == "$field_name" ]]; then
            echo "$value"
            IFS="$OLD_IFS"
            return 0
        fi
    done
    IFS="$OLD_IFS"

    return 1
}

# Get a single field from PHASE_CONFIG_0N_*
# Format: "enabled:true|timeout:300|exec:sequential|prereq:strict|deps:git:url,node:url"
# Usage: enabled=$(phase_get_config_field "0" "enabled")
phase_get_config_field() {
    local phase_num="$1"
    local field_name="$2"

    # Find the PHASE_CONFIG variable for this phase
    local config_var=""
    local var
    for var in $(compgen -v 2>/dev/null | grep "^PHASE_CONFIG_0${phase_num}_"); do
        config_var="$var"
        break
    done

    if [[ -z "$config_var" ]]; then
        return 1
    fi

    local config="${!config_var:-}"

    # Parse pipe-separated key:value pairs
    local OLD_IFS="$IFS"
    IFS='|'
    for pair in $config; do
        local key="${pair%%:*}"
        local value="${pair#*:}"
        if [[ "$key" == "$field_name" ]]; then
            echo "$value"
            IFS="$OLD_IFS"
            return 0
        fi
    done
    IFS="$OLD_IFS"

    return 1
}

# Get scripts list for a phase
# Usage: scripts=$(phase_get_scripts "0")
phase_get_scripts() {
    local phase_num="$1"

    # Find the BOOTSTRAP_PHASE variable for this phase
    local scripts_var=""
    for var in $(compgen -v | grep "^BOOTSTRAP_PHASE_0${phase_num}_"); do
        scripts_var="$var"
        break
    done

    if [[ -z "$scripts_var" ]]; then
        return 1
    fi

    # Return the scripts, filtering empty lines
    echo "${!scripts_var}" | grep -v '^[[:space:]]*$'
}

# =============================================================================
# PHASE INFORMATION
# =============================================================================

# Get phase name
# Usage: name=$(phase_get_name "0")
phase_get_name() {
    local phase_num="$1"
    local name
    name=$(phase_get_metadata_field "$phase_num" "name") || true
    echo "${name:-Phase $phase_num}"
}

# Get phase description
# Usage: desc=$(phase_get_description "0")
phase_get_description() {
    local phase_num="$1"
    phase_get_metadata_field "$phase_num" "description" 2>/dev/null || true
}

# Check if phase is enabled
# Usage: phase_is_enabled "0" && echo "yes"
phase_is_enabled() {
    local phase_num="$1"
    local enabled
    enabled=$(phase_get_config_field "$phase_num" "enabled") || true
    [[ "${enabled:-true}" == "true" ]]
}

# Get phase timeout
# Usage: timeout=$(phase_get_timeout "0")
phase_get_timeout() {
    local phase_num="$1"
    local timeout
    timeout=$(phase_get_config_field "$phase_num" "timeout") || true
    echo "${timeout:-600}"
}

# =============================================================================
# PHASE EXECUTION
# =============================================================================

# Run a single script with timing and status tracking
# Usage: phase_run_script "tech_stack/foundation/init-nextjs.sh"
phase_run_script() {
    local script_path="$1"
    local script_name
    script_name=$(basename "$script_path")
    local script_rel="${script_path##*/tech_stack/}"

    # Show running status
    log_status "RUN" "$script_name"

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_status "DRY" "$script_name" "would run"
        _execution_record_skip "$script_rel" "dry-run"
        # Simulate success to exercise success-path side effects without executing
        state_mark_success "$script_rel"
        return 0
    fi

    # Track execution time
    local start_time
    start_time=$(date +%s)

    # Run script, capturing output to log file
    local exit_code=0
    if [[ -n "${LOG_FILE:-}" && -f "${LOG_FILE}" ]]; then
        bash "$script_path" >> "$LOG_FILE" 2>&1
        exit_code=$?
    else
        bash "$script_path"
        exit_code=$?
    fi

    local end_time
    end_time=$(date +%s)
    local duration="$((end_time - start_time))s"

    if [[ $exit_code -eq 0 ]]; then
        log_status "OK" "$script_name" "$duration"
        _execution_record_success "$script_rel" "$duration"
        return 0
    else
        log_status "FAIL" "$script_name" "$duration"
        _execution_record_failure "$script_rel" "script failed" "$exit_code"
        return $exit_code
    fi
}

# Run a script with deferred error handling (continues on failure)
# Usage: phase_run_script_safe "tech_stack/foundation/init-nextjs.sh"
phase_run_script_safe() {
    local script_path="$1"

    if phase_run_script "$script_path"; then
        return 0
    else
        # Error already recorded, check if we should continue
        if _execution_should_continue; then
            log_warn "Continuing despite failure (deferred error mode)"
            return 0  # Return success to continue execution
        else
            return 1  # Fail fast
        fi
    fi
}

# Execute a single phase
# Usage: phase_execute "0" "/path/to/tech_stack"
phase_execute() {
    local phase_num="$1"
    local tech_stack_dir="$2"
    local force="${3:-false}"

    local phase_name
    phase_name=$(phase_get_name "$phase_num")

    # Check if enabled
    if ! phase_is_enabled "$phase_num"; then
        log_info "Phase $phase_num ($phase_name) is disabled, skipping"
        return 0
    fi

    # Check dependencies (skip in dry-run mode)
    local deps prereq
    local dry_run_mode="${DRY_RUN:-false}"
    deps=$(phase_get_config_field "$phase_num" "deps") || true
    prereq=$(phase_get_config_field "$phase_num" "prereq") || true
    prereq="${prereq:-warn}"
    if [[ -n "${INSIDE_OMNI_DOCKER:-}" ]]; then
        prereq="warn"  # relax inside container (daemon unavailable)
        deps=""        # host preflight should cover deps; skip in-container
    fi
    if [[ -n "$deps" ]]; then
        if ! check_phase_deps "$deps" "$prereq"; then
            # In dry-run mode, treat dependency failures as warnings and continue
            if [[ "$dry_run_mode" == "true" ]]; then
                log_warn "Phase $phase_num ($phase_name) dependency check failed (continuing in dry-run mode)"
            elif [[ "$prereq" == "strict" ]]; then
                log_error "Phase $phase_num ($phase_name) dependency check failed"
                return 1
            fi
        fi
    fi

    local docker_required
    docker_required=$(phase_get_config_field "$phase_num" "docker_required") || true
    if [[ "${docker_required:-false}" == "true" && "${DOCKER_REQUIRED:-true}" == "true" ]]; then
        if [[ "${DOCKER_EXEC_MODE:-container}" == "container" && -z "${INSIDE_OMNI_DOCKER:-}" ]]; then
            log_error "Phase $phase_num ($phase_name) requires Docker container mode."
            return 1
        fi
        if [[ "${DOCKER_EXEC_MODE:-container}" == "host" ]]; then
            if ! require_docker_env; then
                log_error "Phase $phase_num ($phase_name) requires Docker; ensure Docker is available."
                return 1
            fi
        fi
    fi

    # Use new phase start logging
    log_phase_start "$phase_num" "$phase_name"

    # Get and run scripts
    local scripts
    scripts=$(phase_get_scripts "$phase_num")

    if [[ -z "$scripts" ]]; then
        log_warn "No scripts defined for phase $phase_num"
        return 0
    fi

    local phase_failed=false

    while IFS= read -r script_rel; do
        # Skip empty lines
        [[ -z "$script_rel" ]] && continue
        script_rel="${script_rel#"${script_rel%%[![:space:]]*}"}"  # trim leading
        script_rel="${script_rel%"${script_rel##*[![:space:]]}"}"  # trim trailing
        [[ -z "$script_rel" ]] && continue

        local full_path="${tech_stack_dir}/${script_rel}"

        # Check resume mode
        if [[ "$force" != "true" && "${BOOTSTRAP_RESUME_MODE:-skip}" == "skip" ]]; then
            if state_has_succeeded "$script_rel"; then
                log_status "SKIP" "$(basename "$script_rel")" "already done"
                _execution_record_skip "$script_rel" "already completed"
                continue
            fi
        fi

        # Check script exists
        if [[ ! -f "$full_path" ]]; then
            log_status "FAIL" "$(basename "$script_rel")" "not found"
            _execution_record_failure "$script_rel" "script not found"
            if ! _execution_should_continue; then
                return 1
            fi
            phase_failed=true
            continue
        fi

        # Run script with deferred error handling
        if phase_run_script_safe "$full_path"; then
            state_mark_success "$script_rel"
        else
            phase_failed=true
            if ! _execution_should_continue; then
                log_error "Phase $phase_num failed at: $script_rel"
                return 1
            fi
        fi
    done <<< "$scripts"

    if [[ "$phase_failed" == "true" ]]; then
        log_warn "Phase $phase_num completed with errors"
        return 1
    fi

    log_debug "Phase $phase_num ($phase_name) completed"
    return 0
}

# Execute all phases in order
# Usage: phase_execute_all "/path/to/tech_stack" [force]
phase_execute_all() {
    local tech_stack_dir="$1"
    local force="${2:-false}"

    # Initialize error tracking
    _execution_reset

    # Ensure app env and secrets exist before running phases
    if ! secrets_ensure_core_env; then
        log_error "Failed to prepare app env/secrets"
        return 1
    fi

    local phases
    # Save IFS and restore to default for word splitting
    local OLD_IFS="$IFS"
    IFS=' '
    read -ra phases <<< "$(phase_discover)"
    IFS="$OLD_IFS"

    if [[ ${#phases[@]} -eq 0 ]]; then
        log_error "No phases discovered from PHASE_METADATA_* variables"
        return 1
    fi

    log_debug "Discovered ${#phases[@]} phases: ${phases[*]}"

    local any_failed=false

    for phase_num in "${phases[@]}"; do
        if ! phase_execute "$phase_num" "$tech_stack_dir" "$force"; then
            any_failed=true
            if ! _execution_should_continue; then
                return 1
            fi
        fi
    done

    # Return based on whether any phases failed
    [[ "$any_failed" == "false" ]]
}

# Get execution summary for recap
execution_get_summary() {
    echo "completed:${#_COMPLETED_SCRIPTS[@]}"
    echo "failed:${#_FAILED_SCRIPTS[@]}"
    echo "skipped:${#_SKIPPED_SCRIPTS[@]}"
}

# Get list of failed scripts
execution_get_failed() {
    printf '%s\n' "${_FAILED_SCRIPTS[@]}"
}

# Get list of errors
execution_get_errors() {
    printf '%s\n' "${_EXECUTION_ERRORS[@]}"
}

# =============================================================================
# PHASE LISTING
# =============================================================================

# List all phases and their scripts
# Usage: phase_list_all
phase_list_all() {
    local phases
    # Save IFS and restore to default for word splitting
    local OLD_IFS="$IFS"
    IFS=' '
    read -ra phases <<< "$(phase_discover)"
    IFS="$OLD_IFS"

    echo ""
    echo "BOOTSTRAP PHASES"
    echo "================"
    echo ""

    for phase_num in "${phases[@]}"; do
        local name
        name=$(phase_get_name "$phase_num")
        local desc
        desc=$(phase_get_description "$phase_num")
        local enabled="enabled"
        phase_is_enabled "$phase_num" || enabled="DISABLED"

        echo "Phase $phase_num: $name [$enabled]"
        [[ -n "$desc" ]] && echo "  Description: $desc"

        local scripts=""
        if [[ "$enabled" == "enabled" ]]; then
            scripts=$(phase_get_scripts "$phase_num") || scripts=""
        fi
        local count=0

        while IFS= read -r script; do
            [[ -z "$script" ]] && continue
            script="${script#"${script%%[![:space:]]*}"}"
            [[ -z "$script" ]] && continue
            echo "    - $script"
            count=$((count + 1))
        done <<< "$scripts"

        echo "  Scripts: $count"
        echo ""
    done
}

# =============================================================================
# DEPENDENCY CHECKING
# =============================================================================

# Check phase dependencies
# Format: "git:https://git-scm.com,node:https://nodejs.org,pnpm:https://pnpm.io"
# Usage: check_phase_deps "git:url,node:url" "strict"
check_phase_deps() {
    local deps_string="$1"
    local prereq_mode="${2:-warn}"
    local all_ok=true

    [[ -z "$deps_string" ]] && return 0

    local OLD_IFS="$IFS"
    IFS=','
    for dep in $deps_string; do
        local cmd="${dep%%:*}"
        local hint="${dep#*:}"

        # Skip empty or builtin
        [[ -z "$cmd" || "$hint" == "builtin" ]] && continue

        if ! command -v "$cmd" &>/dev/null; then
            if [[ "$prereq_mode" == "strict" ]]; then
                log_error "Required: $cmd - Install from $hint"
                all_ok=false
            else
                log_warn "Optional: $cmd not found - Install from $hint"
            fi
        else
            log_debug "Found dependency: $cmd"
        fi
    done
    IFS="$OLD_IFS"

    $all_ok
}

# =============================================================================
# PREFLIGHT CHECKS
# =============================================================================

# Run all preflight checks before any phase execution
# Usage: phase_preflight_check "/path/to/tech_stack"
# In DRY_RUN mode, dependency errors are reported as warnings instead of errors
phase_preflight_check() {
    local tech_stack_dir="$1"
    local errors=0
    local warnings=0
    local dry_run_mode="${DRY_RUN:-false}"

    log_info "=========================================="
    log_info "  PREFLIGHT CHECK"
    [[ "$dry_run_mode" == "true" ]] && log_info "  (dry-run: dependency errors reported as warnings)"
    log_info "=========================================="
    echo ""

    # 1. Check all phase dependencies upfront
    log_step "Checking dependencies for all phases..."
    local phases
    local OLD_IFS="$IFS"
    IFS=' '
    read -ra phases <<< "$(phase_discover)"
    IFS="$OLD_IFS"

    for phase_num in "${phases[@]}"; do
        if ! phase_is_enabled "$phase_num"; then
            continue
        fi

        local deps prereq
        deps=$(phase_get_config_field "$phase_num" "deps") || true
        prereq=$(phase_get_config_field "$phase_num" "prereq") || true
        prereq="${prereq:-warn}"

        if [[ -n "$deps" ]]; then
            local phase_name
            phase_name=$(phase_get_name "$phase_num")
            log_debug "Checking Phase $phase_num ($phase_name) dependencies..."

            if ! check_phase_deps "$deps" "$prereq"; then
                # In dry-run mode, treat all dependency issues as warnings
                if [[ "$dry_run_mode" == "true" ]]; then
                    warnings=$((warnings + 1))
                elif [[ "$prereq" == "strict" ]]; then
                    errors=$((errors + 1))
                else
                    warnings=$((warnings + 1))
                fi
            fi
        fi
    done

    # 2. Check all scripts exist
    log_step "Verifying all scripts exist..."
    local missing_scripts=0

    for phase_num in "${phases[@]}"; do
        if ! phase_is_enabled "$phase_num"; then
            continue
        fi

        local scripts
        scripts=$(phase_get_scripts "$phase_num") || true

        while IFS= read -r script_rel; do
            [[ -z "$script_rel" ]] && continue
            script_rel="${script_rel#"${script_rel%%[![:space:]]*}"}"
            script_rel="${script_rel%"${script_rel##*[![:space:]]}"}"
            [[ -z "$script_rel" ]] && continue

            local full_path="${tech_stack_dir}/${script_rel}"
            if [[ ! -f "$full_path" ]]; then
                log_warn "Missing script: $script_rel"
                missing_scripts=$((missing_scripts + 1))
            fi
        done <<< "$scripts"
    done

    if [[ $missing_scripts -gt 0 ]]; then
        log_warn "$missing_scripts script(s) not found - will be skipped"
        warnings=$((warnings + missing_scripts))
    fi

    # 3. Check disk space (basic check)
    log_step "Checking system resources..."
    local available_space
    available_space=$(df -P "${PROJECT_ROOT:-.}" 2>/dev/null | awk 'NR==2 {print $4}')
    if [[ -n "$available_space" && "$available_space" -lt 1048576 ]]; then
        log_warn "Low disk space: less than 1GB available"
        warnings=$((warnings + 1))
    fi

    # 4. Check PROJECT_ROOT is writable
    if [[ ! -w "${PROJECT_ROOT:-.}" ]]; then
        log_error "PROJECT_ROOT is not writable: ${PROJECT_ROOT:-.}"
        errors=$((errors + 1))
    fi

    # Summary
    echo ""
    log_info "=========================================="
    if [[ $errors -gt 0 ]]; then
        log_error "Preflight check FAILED: $errors error(s), $warnings warning(s)"
        log_error "Fix the errors above before proceeding."
        return 1
    elif [[ $warnings -gt 0 ]]; then
        log_warn "Preflight check passed with $warnings warning(s)"
        log_info "Proceeding despite warnings..."
        return 0
    else
        log_success "Preflight check PASSED"
        return 0
    fi
}

# =============================================================================
# EXECUTION RECAP
# =============================================================================

# Track execution statistics
declare -g _PHASE_STATS_STARTED=0
declare -g _PHASE_STATS_COMPLETED=0
declare -g _PHASE_STATS_SKIPPED=0
declare -g _PHASE_STATS_FAILED=0
declare -g _PHASE_STATS_START_TIME=""
declare -g _PHASE_STATS_PHASES_RUN=""

# Initialize execution stats
phase_stats_init() {
    _PHASE_STATS_STARTED=0
    _PHASE_STATS_COMPLETED=0
    _PHASE_STATS_SKIPPED=0
    _PHASE_STATS_FAILED=0
    _PHASE_STATS_START_TIME=$(date +%s)
    _PHASE_STATS_PHASES_RUN=""
}

# Record phase completion
phase_stats_record() {
    local phase_num="$1"
    local status="$2"  # completed, skipped, failed

    case "$status" in
        completed)
            _PHASE_STATS_COMPLETED=$((_PHASE_STATS_COMPLETED + 1))
            ;;
        skipped)
            _PHASE_STATS_SKIPPED=$((_PHASE_STATS_SKIPPED + 1))
            ;;
        failed)
            _PHASE_STATS_FAILED=$((_PHASE_STATS_FAILED + 1))
            ;;
    esac
    _PHASE_STATS_PHASES_RUN="${_PHASE_STATS_PHASES_RUN} $phase_num:$status"
}

# Show execution recap and next steps
phase_show_recap() {
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - _PHASE_STATS_START_TIME))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))

    echo ""
    echo ""
    log_info "=========================================="
    log_info "  OMNIFORGE EXECUTION RECAP"
    log_info "=========================================="
    echo ""

    # Statistics
    log_info "Summary:"
    local mode_str="live"
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        mode_str="dry-run (no commands executed)"
    fi
    echo "  Mode: ${mode_str}"
    echo "  Duration: ${minutes}m ${seconds}s"
    echo "  Phases: completed=$_PHASE_STATS_COMPLETED skipped=$_PHASE_STATS_SKIPPED failed=$_PHASE_STATS_FAILED"
    echo "  Scripts: completed=${#_COMPLETED_SCRIPTS[@]} skipped=${#_SKIPPED_SCRIPTS[@]} failed=${#_FAILED_SCRIPTS[@]}"
    echo ""

    # Per-phase summary (concise)
    local phases
    local OLD_IFS="$IFS"
    IFS=' '
    read -ra phases <<< "$(phase_discover)"
    IFS="$OLD_IFS"

    if [[ ${#phases[@]} -gt 0 ]]; then
        log_info "Per-phase summary (ok/fail/skip):"
        for p in "${phases[@]}"; do
            phase_is_enabled "$p" || continue
            local scripts
            scripts=$(phase_get_scripts "$p" | sed '/^$/d') || true
            [[ -z "$scripts" ]] && continue

            local ok=0 fail=0 skip=0
            while IFS= read -r script_rel; do
                [[ -z "$script_rel" ]] && continue
                if _phase_array_contains "$script_rel" "_FAILED_SCRIPTS"; then
                    ((fail++))
                elif _phase_array_contains "$script_rel" "_COMPLETED_SCRIPTS"; then
                    ((ok++))
                elif _phase_array_contains "$script_rel" "_SKIPPED_SCRIPTS"; then
                    ((skip++))
                fi
            done <<< "$scripts"

            local phase_name
            phase_name=$(phase_get_name "$p")
            log_info "  Phase ${p} (${phase_name}): ok=${ok} fail=${fail} skip=${skip}"
        done
        echo ""
    fi

    # Check for failures (either phase-level or script-level)
    local has_failures=false
    [[ $_PHASE_STATS_FAILED -gt 0 || ${#_FAILED_SCRIPTS[@]} -gt 0 ]] && has_failures=true

    if [[ "$has_failures" == "false" ]]; then
        log_success "No failures detected"
        echo ""
        log_info "=========================================="
        log_info "  NEXT STEPS"
        log_info "=========================================="
        echo ""
        echo "1. Review generated files and customize as needed"
        echo ""
        echo "2. Set up environment variables:"
        echo "   cp .env.example .env.local"
        echo "   # Edit .env.local with your secrets"
        echo ""
        echo "3. Start the database:"
        echo "   docker compose up -d"
        echo ""
        echo "4. Run database migrations:"
        echo "   pnpm db:migrate"
        echo ""
        echo "5. Start development server:"
        echo "   pnpm dev"
        echo ""
        echo "6. Verify the build:"
        echo "   omni forge"
        echo ""

        log_info "=========================================="
        log_info "  CONFIGURATION CHECKLIST"
        log_info "=========================================="
        echo ""
        echo "[ ] Update .env.local with your API keys"
        echo "[ ] Update database credentials in docker-compose.yml"
        echo "[ ] Configure authentication providers in auth.config.ts"
        echo "[ ] Review and customize the schema in src/db/schema/"
        echo "[ ] Set up your preferred IDE extensions"
        echo ""
    else
        log_info "=========================================="
        log_warn "  FAILURES DETECTED"
        log_info "=========================================="
        echo ""

        # Show failed scripts
        if [[ ${#_FAILED_SCRIPTS[@]} -gt 0 ]]; then
            echo "Failed scripts:"
            for script in "${_FAILED_SCRIPTS[@]}"; do
                echo "  - $script"
            done
            echo ""
        fi

        # Show error details
        if [[ ${#_EXECUTION_ERRORS[@]} -gt 0 ]]; then
            echo "Error details:"
            for err in "${_EXECUTION_ERRORS[@]}"; do
                echo "  $err"
            done
            echo ""
        fi

        log_info "=========================================="
        log_info "  RECOVERY OPTIONS"
        log_info "=========================================="
        echo ""
        echo "To retry (skips completed scripts):"
        echo "   omni"
        echo ""
        echo "To force re-run all scripts:"
        echo "   omni --force"
        echo ""
        echo "To clear state and start fresh:"
        echo "   omni --status --clear"
        echo "   omni"
        echo ""

        log_show_file_hint
    fi

    log_success "=========================================="
    log_success "  OmniForge complete. Happy building!"
    log_success "=========================================="
}

# =============================================================================
# PARALLEL EXECUTION (for independent scripts)
# =============================================================================

# Check if two scripts can run in parallel (no dependencies)
# For now, scripts within same subdirectory are considered dependent
phase_can_parallelize() {
    local script1="$1"
    local script2="$2"

    local dir1="${script1%/*}"
    local dir2="${script2%/*}"

    # Different directories = can parallelize
    [[ "$dir1" != "$dir2" ]]
}

# Execute scripts in parallel where possible
# Usage: phase_execute_parallel "script1 script2 script3" "/path/to/tech_stack"
phase_execute_parallel() {
    local scripts_string="$1"
    local tech_stack_dir="$2"
    local force="$3"

    # For now, just run sequentially
    # Parallel execution requires more sophisticated dependency analysis
    local script
    for script in $scripts_string; do
        [[ -z "$script" ]] && continue

        local full_path="${tech_stack_dir}/${script}"

        if [[ "$force" != "true" && "${BOOTSTRAP_RESUME_MODE:-skip}" == "skip" ]]; then
            if state_has_succeeded "$script"; then
                log_skip "$script (already completed)"
                continue
            fi
        fi

        if [[ ! -f "$full_path" ]]; then
            log_warn "Script not found, skipping: $script"
            continue
        fi

        if phase_run_script "$full_path"; then
            state_mark_success "$script"
        else
            return 1
        fi
    done

    return 0
}
