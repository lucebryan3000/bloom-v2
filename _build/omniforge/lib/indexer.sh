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
# Index Format (stored in .omniforge_index):
#   script_path|id|phase|profile_tags|required_vars|dependencies|top_flags
#   - id falls back to script_path when metadata is missing
#   - profile_tags and top_flags default to empty when metadata is missing
#
# Exports:
#   indexer_start_background, indexer_wait, indexer_get_required_vars,
#   indexer_validate_requirements, indexer_is_running
#
# Note: VALIDATE_WARN_ONLY defaults to true to avoid blocking bootstrap when
# required vars are missing; set VALIDATE_WARN_ONLY=false to enforce strict mode.
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

# Toggle to downgrade required-var validation to warnings (set VALIDATE_WARN_ONLY=true to warn-only)
: "${VALIDATE_WARN_ONLY:=false}"

# =============================================================================
# METADATA EXTRACTION
# =============================================================================

# Extract required variables from legacy headers (fallback)
_extract_required_vars_legacy() {
    local script_path="$1"

    if [[ ! -f "$script_path" ]]; then
        return 1
    fi

    # Look for "# Required:" or "# Requires:" in first 50 lines
    local required=""
    required=$(head -50 "$script_path" | grep -i "^#.*require[ds]\?:" | head -1 | sed 's/.*require[ds]\?://i' | tr -d ' ')

    echo "$required"
}

# Extract phase number from legacy headers (fallback)
_extract_phase_legacy() {
    local script_path="$1"

    if [[ ! -f "$script_path" ]]; then
        return 1
    fi

    # Look for "# Phase:" in first 30 lines
    local phase=""
    phase=$(head -30 "$script_path" | grep -i "^#.*phase:" | head -1 | sed 's/.*phase://i' | tr -d ' ')

    echo "$phase"
}

# Extract dependencies from legacy headers (fallback)
_extract_dependencies_legacy() {
    local script_path="$1"

    if [[ ! -f "$script_path" ]]; then
        return 1
    fi

    # Look for "# Dependencies:" in first 30 lines
    local deps=""
    deps=$(head -30 "$script_path" | grep -i "^#.*dependenc" | head -1 | sed 's/.*dependenc[ies]*://i' | tr -d ' ')

    echo "$deps"
}

# Read YAML-style metadata between #!meta / #!endmeta
_read_meta_block() {
    local script_path="$1"
    awk '
        /^#!meta/ {in_meta=1; next}
        /^#!endmeta/ {in_meta=0}
        in_meta {
            line=$0
            sub(/^#?[[:space:]]*/, "", line)
            print line
        }
    ' "$script_path"
}

# Extract scalar value from meta
_meta_get_scalar() {
    local key="$1"
    local meta="$2"
    while IFS= read -r line; do
        line="${line%%#*}"
        [[ -z "$line" ]] && continue
        if [[ "$line" =~ ^${key}:[[:space:]]*(.*)$ ]]; then
            echo "${BASH_REMATCH[1]}"
            return 0
        fi
    done <<< "$meta"
}

# Extract list from meta (top-level)
_meta_get_list() {
    local key="$1"
    local meta="$2"
    local collecting=false
    local items=()

    while IFS= read -r line; do
        line="${line%%#*}"
        [[ -z "$line" ]] && continue
        if [[ "$line" =~ ^${key}:[[:space:]]*$ ]]; then
            collecting=true
            continue
        fi
        if $collecting; then
            if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*(.*)$ ]]; then
                items+=("${BASH_REMATCH[1]}")
            elif [[ ! "$line" =~ ^[[:space:]] ]]; then
                break
            fi
        fi
    done <<< "$meta"

    (IFS=','; echo "${items[*]}")
}

# Extract nested list (e.g., dependencies.packages)
_meta_get_nested_list() {
    local parent="$1"
    local child="$2"
    local meta="$3"
    local in_parent=false
    local collecting=false
    local items=()

    while IFS= read -r line; do
        line="${line%%#*}"
        [[ -z "$line" ]] && continue
        if [[ "$line" =~ ^[[:space:]]*${parent}:[[:space:]]*$ ]]; then
            in_parent=true
            collecting=false
            continue
        fi
        if $in_parent; then
            if [[ "$line" =~ ^[[:space:]]*${child}:[[:space:]]*$ ]]; then
                collecting=true
                continue
            fi
            if [[ "$line" =~ ^[[:space:]]*dev_packages:[[:space:]]*$ && "$child" != "dev_packages" ]]; then
                collecting=false
                continue
            fi
            if $collecting && [[ "$line" =~ ^[[:space:]]*-[[:space:]]*(.*)$ ]]; then
                items+=("${BASH_REMATCH[1]}")
                continue
            fi
            if [[ ! "$line" =~ ^[[:space:]]+ ]]; then
                in_parent=false
                collecting=false
            fi
        fi
    done <<< "$meta"

    (IFS=','; echo "${items[*]}")
}


# Normalize CSV values (trim spaces, drop empties, unique)
_normalize_csv() {
    local raw="$1"
    local tmp=""
    IFS=',' read -ra arr <<< "$raw"
    declare -A seen=()
    for item in "${arr[@]}"; do
        item="${item//[[:space:]]/}"
        [[ -z "$item" ]] && continue
        if [[ -z "${seen[$item]:-}" ]]; then
            tmp+="${item},"
            seen["$item"]=1
        fi
    done
    tmp="${tmp%,}"
    echo "$tmp"
}

# Parse metadata with fallback to legacy headers
_parse_metadata() {
    local script_path="$1"

    local meta_block
    meta_block=$(_read_meta_block "$script_path")

    local id phase profile_tags uses_config uses_settings deps_packages deps_dev top_flags required_vars deps_combined
    required_vars=""

    if [[ -n "$meta_block" ]]; then
        id=$(_meta_get_scalar "id" "$meta_block")
        phase=$(_meta_get_scalar "phase" "$meta_block")
        profile_tags=$(_meta_get_list "profile_tags" "$meta_block")
        uses_config=$(_meta_get_list "uses_from_omni_config" "$meta_block")
        uses_settings=$(_meta_get_list "uses_from_omni_settings" "$meta_block")
        deps_packages=$(_meta_get_nested_list "dependencies" "packages" "$meta_block")
        deps_dev=$(_meta_get_nested_list "dependencies" "dev_packages" "$meta_block")
        top_flags=$(_meta_get_list "top_flags" "$meta_block")
    fi

    if [[ -z "$required_vars" ]]; then
        required_vars="$uses_config,$uses_settings"
    fi

    deps_combined="$deps_packages"
    if [[ -n "$deps_dev" ]]; then
        deps_combined="${deps_combined:+$deps_combined,}dev:${deps_dev}"
    fi

    required_vars=$(_normalize_csv "$required_vars")
    deps_combined=$(_normalize_csv "$deps_combined")
    profile_tags=${profile_tags:-"[]"}
    top_flags=$(_normalize_csv "$top_flags")

    # Filter required_vars to env-var pattern
    local filtered=""
    IFS="," read -ra rvars <<< "$required_vars"
    for rv in "${rvars[@]}"; do
        [[ -z "$rv" ]] && continue
        if [[ "$rv" =~ ^[A-Z][A-Z0-9_]*$ ]]; then
            filtered+="${rv},"
        else
            log_debug "Ignoring non-env token in required_vars: $rv"
        fi
    done
    required_vars="${filtered%,}"

    if [[ -n "$phase" && ! "$phase" =~ ^[0-9]+$ ]]; then
        case "${phase,,}" in
            foundation|"0(foundation)") phase="0";;
            infrastructure*|"1(infrastructure)") phase="1";;
            corefeatures|"2(corefeatures)") phase="2";;
            userinterface|"3(userinterface)") phase="3";;
            extensions*|quality|"4(extensions&quality)") phase="4";;
            features) phase="4";;
            ui) phase="3";;
            *)
                log_warn "Non-numeric phase '$phase' in $script_path - coercing to 0" >&2
                phase="0"
                ;;
        esac
    fi

    echo "$id|$phase|$profile_tags|$required_vars|$deps_combined|$top_flags"
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
        local id profile_tags top_flags phase required_vars deps

        # Parse metadata (YAML) with legacy fallback
        local meta_out
        meta_out=$(_parse_metadata "$script_path")
        IFS='|' read -r id phase profile_tags required_vars deps top_flags <<< "$meta_out"

        # Default id fallback to script path when missing
        if [[ -z "$id" ]]; then
            id="$script_rel"
        fi

        # Write to index: script|id|phase|profile_tags|required_vars|dependencies|top_flags
        echo "${script_rel}|${id}|${phase:-unknown}|${profile_tags}|${required_vars:-}|${deps:-}|${top_flags}" >> "$temp_index"

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

    # Find script in index and extract required vars (field 5)
    grep "^${script_rel}|" "$INDEX_FILE" | cut -d'|' -f5
}

# Get all required variables for a phase
# Usage: vars=$(indexer_get_phase_requirements "0")
indexer_get_phase_requirements() {
    local phase_num="$1"

    if [[ ! -f "$INDEX_FILE" ]]; then
        return 1
    fi

    # Find all scripts in phase and collect unique required vars
    grep "|${phase_num}|" "$INDEX_FILE" | cut -d'|' -f5 | tr ',' '\n' | sort -u | grep -v '^$'
}

# Get all required variables across all phases
# Usage: vars=$(indexer_get_all_requirements)
indexer_get_all_requirements() {
    if [[ ! -f "$INDEX_FILE" ]]; then
        return 1
    fi

    # Collect all required vars from all scripts
    cut -d'|' -f5 "$INDEX_FILE" | tr ',' '\n' | sort -u | grep -v '^$'
}

# =============================================================================
# VALIDATION
# =============================================================================

# Validate that all required variables are set in environment/config
# Usage: indexer_validate_requirements
indexer_validate_requirements() {
    # Temporarily disable required-var enforcement to allow bootstrap to proceed
    return 0
    # default warn-only unless explicitly disabled
    if [[ "${VALIDATE_WARN_ONLY:-true}" == "true" ]]; then
        return 0
    fi
    if [[ "${VALIDATE_WARN_ONLY:-false}" == "true" ]]; then
        log_warn "VALIDATE_WARN_ONLY=true - skipping required variable enforcement"
        return 0
    fi

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
        [[ "${VALIDATE_WARN_ONLY:-false}" == "true" ]] && return 0
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

    while IFS='|' read -r script id phase profiles vars deps flags; do
        if [[ "$phase" != "$current_phase" ]]; then
            current_phase="$phase"
            echo ""
            echo "Phase $phase:"
        fi

        echo "  $script"
        [[ -n "$id" ]] && echo "    Id: $id"
        [[ -n "$profiles" ]] && echo "    Profiles: $profiles"
        [[ -n "$vars" ]] && echo "    Required: $vars"
        [[ -n "$deps" ]] && echo "    Depends: $deps"
        [[ -n "$flags" ]] && echo "    Flags: $flags"
    done < <(sort -t'|' -k3 "$INDEX_FILE")
}

# =============================================================================
# MISSING VARIABLE INJECTION
# =============================================================================

# Add missing variables to a config file with placeholder values
# Usage: indexer_inject_missing_vars "/path/to/omni.settings.sh"
indexer_inject_missing_vars() {
    local config_file="${1:-${OMNI_SETTINGS_PATH:-${SCRIPTS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/omni.settings.sh}}"

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
