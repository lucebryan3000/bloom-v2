#!/usr/bin/env bash
# =============================================================================
# lib/indexer.sh - Background Script Indexer
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Scans tech_stack scripts and builds an index for:
#   - Script discovery and validation
#   - Required variables extraction from metadata
#   - Phase membership
#   - Caching for fast preflight checks
#
# Index Format (JSON-like, stored in .omniforge_index):
#   script_path|phase|required_vars|dependencies
#
# Exports:
#   indexer_start_background, indexer_wait, indexer_get_required_vars,
#   indexer_validate_requirements, indexer_is_running
#
# Dependencies:
#   lib/logging.sh
# =============================================================================

# Guard against double-sourcing
[[ -n "${_LIB_INDEXER_LOADED:-}" ]] && return 0
_LIB_INDEXER_LOADED=1

# =============================================================================
# CONFIGURATION
# =============================================================================

# Index file location (in project root, git-ignored)
: "${INDEX_FILE:=${PROJECT_ROOT:-.}/.omniforge_index}"
: "${INDEX_LOCK_FILE:=${INDEX_FILE}.lock}"

# Background process tracking
declare -g _INDEXER_PID=""
declare -g _INDEXER_STATUS="not_started"  # not_started, running, completed, failed

# =============================================================================
# METADATA EXTRACTION
# =============================================================================

# Extract required variables from script metadata header
# Scripts should have: # Required: VAR1, VAR2, VAR3
# Usage: _extract_required_vars "/path/to/script.sh"
_extract_required_vars() {
    local script_path="$1"

    if [[ ! -f "$script_path" ]]; then
        return 1
    fi

    # Look for "# Required:" or "# Requires:" in first 50 lines
    local required=""
    required=$(head -50 "$script_path" | grep -i "^#.*require[ds]\?:" | head -1 | sed 's/.*require[ds]\?://i' | tr -d ' ')

    echo "$required"
}

# Extract phase number from script metadata
# Scripts should have: # Phase: 0
# Usage: _extract_phase "/path/to/script.sh"
_extract_phase() {
    local script_path="$1"

    if [[ ! -f "$script_path" ]]; then
        return 1
    fi

    # Look for "# Phase:" in first 30 lines
    local phase=""
    phase=$(head -30 "$script_path" | grep -i "^#.*phase:" | head -1 | sed 's/.*phase://i' | tr -d ' ')

    echo "$phase"
}

# Extract dependencies from script metadata
# Scripts should have: # Dependencies: lib/common.sh
# Usage: _extract_dependencies "/path/to/script.sh"
_extract_dependencies() {
    local script_path="$1"

    if [[ ! -f "$script_path" ]]; then
        return 1
    fi

    # Look for "# Dependencies:" in first 30 lines
    local deps=""
    deps=$(head -30 "$script_path" | grep -i "^#.*dependenc" | head -1 | sed 's/.*dependenc[ies]*://i' | tr -d ' ')

    echo "$deps"
}

# =============================================================================
# INDEX BUILDING
# =============================================================================

# Build the index from all tech_stack scripts
# Usage: _build_index "/path/to/tech_stack"
_build_index() {
    local tech_stack_dir="$1"
    local temp_index="${INDEX_FILE}.tmp"

    log_file "Building script index from $tech_stack_dir" "INDEX"

    # Clear temp file
    : > "$temp_index"

    # Find all .sh files in tech_stack
    local script_count=0
    local missing_vars_count=0

    while IFS= read -r -d '' script_path; do
        local script_rel="${script_path#$tech_stack_dir/}"
        local required_vars phase deps

        required_vars=$(_extract_required_vars "$script_path")
        phase=$(_extract_phase "$script_path")
        deps=$(_extract_dependencies "$script_path")

        # Write to index: script|phase|required_vars|dependencies
        echo "${script_rel}|${phase:-unknown}|${required_vars:-}|${deps:-}" >> "$temp_index"

        ((script_count++))

        # Track scripts missing required vars metadata
        if [[ -z "$required_vars" ]]; then
            ((missing_vars_count++))
            log_file "WARNING: No required vars in $script_rel" "INDEX"
        fi
    done < <(find "$tech_stack_dir" -name "*.sh" -type f -print0 2>/dev/null)

    # Atomically move temp to final
    mv "$temp_index" "$INDEX_FILE"

    log_file "Index complete: $script_count scripts, $missing_vars_count missing required vars" "INDEX"

    # Return warning if many scripts lack metadata
    if [[ $missing_vars_count -gt $((script_count / 2)) ]]; then
        return 2  # Warning: many scripts lack metadata
    fi

    return 0
}

# =============================================================================
# BACKGROUND EXECUTION
# =============================================================================

# Start indexing in background
# Usage: indexer_start_background "/path/to/tech_stack"
indexer_start_background() {
    local tech_stack_dir="${1:-${SCRIPTS_DIR:-}/tech_stack}"

    # Check if index exists and is recent (less than 1 hour old)
    if [[ -f "$INDEX_FILE" ]]; then
        local index_age
        local current_time
        current_time=$(date +%s)
        local index_mtime
        index_mtime=$(stat -c %Y "$INDEX_FILE" 2>/dev/null || stat -f %m "$INDEX_FILE" 2>/dev/null)

        if [[ -n "$index_mtime" ]]; then
            index_age=$((current_time - index_mtime))
            if [[ $index_age -lt 3600 ]]; then
                log_debug "Index is fresh ($index_age seconds old), skipping rebuild"
                _INDEXER_STATUS="completed"
                return 0
            fi
        fi
    fi

    log_debug "Starting background indexer..."

    # Start background process
    (
        _build_index "$tech_stack_dir"
        echo $? > "${INDEX_FILE}.exit"
    ) &

    _INDEXER_PID=$!
    _INDEXER_STATUS="running"

    return 0
}

# Check if indexer is still running
indexer_is_running() {
    [[ -n "$_INDEXER_PID" ]] && kill -0 "$_INDEXER_PID" 2>/dev/null
}

# Wait for indexer to complete
indexer_wait() {
    if [[ -z "$_INDEXER_PID" ]]; then
        return 0
    fi

    if indexer_is_running; then
        wait "$_INDEXER_PID" 2>/dev/null
    fi

    # Check exit status
    if [[ -f "${INDEX_FILE}.exit" ]]; then
        local exit_code
        exit_code=$(cat "${INDEX_FILE}.exit")
        rm -f "${INDEX_FILE}.exit"

        if [[ "$exit_code" -eq 0 ]]; then
            _INDEXER_STATUS="completed"
        elif [[ "$exit_code" -eq 2 ]]; then
            _INDEXER_STATUS="completed"  # Warning only
            log_warn "Index built with warnings - some scripts lack required vars metadata"
        else
            _INDEXER_STATUS="failed"
            return 1
        fi
    fi

    return 0
}

# =============================================================================
# INDEX QUERIES
# =============================================================================

# Get required variables for a script
# Usage: vars=$(indexer_get_required_vars "foundation/init-nextjs.sh")
indexer_get_required_vars() {
    local script_rel="$1"

    if [[ ! -f "$INDEX_FILE" ]]; then
        return 1
    fi

    # Find script in index and extract required vars (field 3)
    grep "^${script_rel}|" "$INDEX_FILE" | cut -d'|' -f3
}

# Get all required variables for a phase
# Usage: vars=$(indexer_get_phase_requirements "0")
indexer_get_phase_requirements() {
    local phase_num="$1"

    if [[ ! -f "$INDEX_FILE" ]]; then
        return 1
    fi

    # Find all scripts in phase and collect unique required vars
    grep "|${phase_num}|" "$INDEX_FILE" | cut -d'|' -f3 | tr ',' '\n' | sort -u | grep -v '^$'
}

# Get all required variables across all phases
# Usage: vars=$(indexer_get_all_requirements)
indexer_get_all_requirements() {
    if [[ ! -f "$INDEX_FILE" ]]; then
        return 1
    fi

    # Collect all required vars from all scripts
    cut -d'|' -f3 "$INDEX_FILE" | tr ',' '\n' | sort -u | grep -v '^$'
}

# =============================================================================
# VALIDATION
# =============================================================================

# Validate that all required variables are set in environment/config
# Usage: indexer_validate_requirements
indexer_validate_requirements() {
    if [[ ! -f "$INDEX_FILE" ]]; then
        log_warn "Index file not found, skipping requirements validation"
        return 0
    fi

    local missing=()
    local all_vars
    all_vars=$(indexer_get_all_requirements)

    while IFS= read -r var; do
        [[ -z "$var" ]] && continue

        # Check if variable is set (in environment or was loaded from config)
        if [[ -z "${!var:-}" ]]; then
            missing+=("$var")
        fi
    done <<< "$all_vars"

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_warn "Missing required variables (${#missing[@]}):"
        for var in "${missing[@]}"; do
            echo "  - $var"
        done
        return 1
    fi

    log_debug "All required variables are set"
    return 0
}

# Generate a report of scripts and their requirements
# Usage: indexer_show_requirements
indexer_show_requirements() {
    if [[ ! -f "$INDEX_FILE" ]]; then
        log_error "Index file not found. Run: omni (to build index)"
        return 1
    fi

    echo ""
    log_section "Script Requirements Index"
    echo ""

    # Group by phase
    local current_phase=""

    while IFS='|' read -r script phase vars deps; do
        if [[ "$phase" != "$current_phase" ]]; then
            current_phase="$phase"
            echo ""
            echo "Phase $phase:"
        fi

        echo "  $script"
        [[ -n "$vars" ]] && echo "    Required: $vars"
        [[ -n "$deps" ]] && echo "    Depends: $deps"
    done < <(sort -t'|' -k2 "$INDEX_FILE")
}

# =============================================================================
# MISSING VARIABLE INJECTION
# =============================================================================

# Add missing variables to bootstrap.conf with placeholder values
# Usage: indexer_inject_missing_vars "/path/to/bootstrap.conf"
indexer_inject_missing_vars() {
    local config_file="$1"

    if [[ ! -f "$INDEX_FILE" ]]; then
        return 1
    fi

    local all_vars
    all_vars=$(indexer_get_all_requirements)
    local injected=0

    while IFS= read -r var; do
        [[ -z "$var" ]] && continue

        # Check if variable exists in config
        if ! grep -q "^${var}=" "$config_file" 2>/dev/null; then
            # Add with placeholder
            echo "" >> "$config_file"
            echo "# AUTO-ADDED: Required by tech_stack scripts" >> "$config_file"
            echo "${var}=\"CHANGE_ME\"" >> "$config_file"
            ((injected++))
            log_warn "Added missing variable: $var"
        fi
    done <<< "$all_vars"

    if [[ $injected -gt 0 ]]; then
        log_warn "Injected $injected missing variables into $config_file"
        log_warn "Please update these values before running omni"
        return 2  # Warning: needs user attention
    fi

    return 0
}
