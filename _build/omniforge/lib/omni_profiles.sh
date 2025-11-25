#!/usr/bin/env bash
#
# lib/omni_profiles.sh
#
# Staged copy of stack profile helper functions from bootstrap.conf.
# NOT wired into runtime yet; bootstrap.conf remains canonical.
# Data (PROFILE_* arrays, AVAILABLE_PROFILES) lives in bootstrap.conf and must
# be loaded before these helpers are called.
#

apply_stack_profile() {
    local profile="${1:-${STACK_PROFILE}}"
    # Convert hyphens to underscores and uppercase (api-only -> API_ONLY)
    local profile_var="PROFILE_${profile^^}"
    profile_var="${profile_var//-/_}"

    # Check if profile exists using eval (Bash 5.3 compatible)
    if ! eval "[[ \${#${profile_var}[@]} -gt 0 ]]" 2>/dev/null; then
        log_error "Unknown STACK_PROFILE: ${profile}. Available: ${AVAILABLE_PROFILES[*]}"
        return 1
    fi

    # Apply profile settings using eval (Bash 5.3 compatible)
    local keys
    keys=$(eval "echo \${!${profile_var}[@]}")
    for key in $keys; do
        # Skip metadata fields, only apply feature flags
        if [[ "$key" =~ ^ENABLE_ ]]; then
            local value
            value=$(eval "echo \${${profile_var}[$key]}")
            export "${key}=${value}"
        fi
    done

    log_debug "Applied profile: ${profile}"
    return 0
}

get_profile_by_number() {
    local num=$1
    local idx=$((num - 1))  # Convert to 0-based index

    if [[ $idx -lt 0 ]] || [[ $idx -ge ${#AVAILABLE_PROFILES[@]} ]]; then
        echo ""
        return 1
    fi

    echo "${AVAILABLE_PROFILES[$idx]}"
}

get_profile_metadata() {
    local profile="$1"
    local key="$2"
    # Convert hyphens to underscores and uppercase (api-only -> API_ONLY)
    local profile_var="PROFILE_${profile^^}"
    profile_var="${profile_var//-/_}"

    # Check if profile array exists using eval (Bash 5.3 compatible)
    if ! eval "[[ \${#${profile_var}[@]} -gt 0 ]]" 2>/dev/null; then
        return 1
    fi

    # Get value using eval (Bash 5.3 compatible)
    eval "echo \${${profile_var}[$key]:-}"
}
