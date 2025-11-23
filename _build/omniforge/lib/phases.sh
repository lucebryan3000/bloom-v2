#!/usr/bin/env bash
# =============================================================================
# lib/phases.sh - Phase Discovery & Execution
# =============================================================================
# Part of OmniForge - The Factory That Builds Universes
#
# Pure functions for discovering and executing phases from bootstrap.conf.
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

# Run a single script
# Usage: phase_run_script "tech_stack/foundation/init-nextjs.sh"
phase_run_script() {
    local script_path="$1"
    local script_name
    script_name=$(basename "$script_path")

    log_step "Running: $script_name"

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
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

    # Check dependencies
    local deps prereq
    deps=$(phase_get_config_field "$phase_num" "deps") || true
    prereq=$(phase_get_config_field "$phase_num" "prereq") || true
    prereq="${prereq:-warn}"
    if [[ -n "$deps" ]]; then
        if ! check_phase_deps "$deps" "$prereq"; then
            if [[ "$prereq" == "strict" ]]; then
                log_error "Phase $phase_num ($phase_name) dependency check failed"
                return 1
            fi
        fi
    fi

    local timeout
    timeout=$(phase_get_timeout "$phase_num")

    log_info "=== Phase $phase_num: $phase_name (timeout: ${timeout}s) ==="

    # Get and run scripts
    local scripts
    scripts=$(phase_get_scripts "$phase_num")

    if [[ -z "$scripts" ]]; then
        log_warn "No scripts defined for phase $phase_num"
        return 0
    fi

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
                log_skip "$script_rel (already completed)"
                continue
            fi
        fi

        # Check script exists
        if [[ ! -f "$full_path" ]]; then
            log_error "Script not found: $full_path"
            return 1
        fi

        # Run script
        if phase_run_script "$full_path"; then
            state_mark_success "$script_rel"
        else
            log_error "Phase $phase_num failed at: $script_rel"
            return 1
        fi
    done <<< "$scripts"

    log_success "Phase $phase_num ($phase_name) completed"
    return 0
}

# Execute all phases in order
# Usage: phase_execute_all "/path/to/tech_stack" [force]
phase_execute_all() {
    local tech_stack_dir="$1"
    local force="${2:-false}"

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

    log_info "Discovered ${#phases[@]} phases: ${phases[*]}"
    echo ""

    for phase_num in "${phases[@]}"; do
        if ! phase_execute "$phase_num" "$tech_stack_dir" "$force"; then
            return 1
        fi
        echo ""
    done

    return 0
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

        local scripts
        scripts=$(phase_get_scripts "$phase_num")
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
