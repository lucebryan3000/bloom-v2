#!/usr/bin/env bash
#
# lib/omni_profiles.sh
#
# Staged copy of stack profile helper functions from bootstrap.conf.
# NOT wired into runtime yet; bootstrap.conf remains canonical.
# Data (PROFILE_* arrays, AVAILABLE_PROFILES) lives in bootstrap.conf and must
# be loaded before these helpers are called.
#

# Guard against double-sourcing
if [[ -n "${_OMNI_PROFILES_HELPERS_LOADED:-}" ]]; then
    return 0 2>/dev/null || exit 0
fi
_OMNI_PROFILES_HELPERS_LOADED=1

_omni_profile_var_name() {
    local profile="$1"
    local profile_var="PROFILE_${profile^^}"
    profile_var="${profile_var//-/_}"
    echo "${profile_var}"
}

omni_profile_exists() {
    local profile="$1"
    local profile_var
    profile_var="$(_omni_profile_var_name "$profile")"
    eval "[[ \${#${profile_var}[@]} -gt 0 ]]" 2>/dev/null
}

omni_profile_get_field() {
    local profile="$1"
    local key="$2"
    local default_value="${3:-}"

    local profile_var
    profile_var="$(_omni_profile_var_name "$profile")"

    if ! omni_profile_exists "$profile"; then
        echo "${default_value}"
        return 0
    fi

    local value
    value=$(eval "echo \${${profile_var}[$key]:-}")
    if [[ -n "${value}" ]]; then
        echo "${value}"
    else
        echo "${default_value}"
    fi
    return 0
}

omni_profile_manifest_view() {
    local profile="$1"
    local out_name="$2"
    if [[ -z "${out_name:-}" ]]; then
        return 1
    fi

    local -n out_ref="$out_name"
    out_ref=()

    out_ref[key]="${profile}"
    out_ref[name]="$(omni_profile_get_field "$profile" "name" "$profile")"
    out_ref[tagline]="$(omni_profile_get_field "$profile" "tagline" "")"
    out_ref[description]="$(omni_profile_get_field "$profile" "description" "")"
    out_ref[mode]="$(omni_profile_get_field "$profile" "mode" "")"
    out_ref[dryRunDefault]="$(omni_profile_get_field "$profile" "dry_run_default" "")"
    if declare -p PROFILE_DRY_RUN >/dev/null 2>&1; then
        out_ref[dryRunDefault]="${PROFILE_DRY_RUN[${profile}]:-$(omni_profile_get_field "$profile" "dry_run_default" "")}"
    fi
    if declare -p PROFILE_RESOURCES >/dev/null 2>&1; then
        out_ref[resources]="${PROFILE_RESOURCES[${profile}]:-}"
    else
        out_ref[resources]=""
    fi
    out_ref[app_auto_install]="$(omni_profile_get_field "$profile" "APP_AUTO_INSTALL" "")"
    out_ref[git_safety]="$(omni_profile_get_field "$profile" "GIT_SAFETY" "")"
    out_ref[allow_dirty]="$(omni_profile_get_field "$profile" "ALLOW_DIRTY" "")"
    out_ref[strict_tests]="$(omni_profile_get_field "$profile" "STRICT_TESTS" "")"
    out_ref[warn_policy]="$(omni_profile_get_field "$profile" "WARN_POLICY" "")"
}

omni_profile_apply_defaults() {
    local profile="$1"
    # Apply optional metadata-driven defaults if not already set
    local val

    val="$(omni_profile_get_field "$profile" "APP_AUTO_INSTALL" "")"
    if [[ -n "$val" && -z "${APP_AUTO_INSTALL+x}" ]]; then
        export APP_AUTO_INSTALL="$val"
    fi

    val="$(omni_profile_get_field "$profile" "GIT_SAFETY" "")"
    if [[ -n "$val" && -z "${GIT_SAFETY_SET_BY_PROFILE:-}" ]]; then
        export GIT_SAFETY="$val"
        export GIT_SAFETY_SET_BY_PROFILE=1
    fi

    val="$(omni_profile_get_field "$profile" "ALLOW_DIRTY" "")"
    if [[ -n "$val" && -z "${ALLOW_DIRTY_SET_BY_PROFILE:-}" ]]; then
        export ALLOW_DIRTY="$val"
        export ALLOW_DIRTY_SET_BY_PROFILE=1
    fi

    val="$(omni_profile_get_field "$profile" "STRICT_TESTS" "")"
    if [[ -n "$val" && -z "${STRICT_TESTS_SET_BY_PROFILE:-}" ]]; then
        export STRICT_TESTS="$val"
        export STRICT_TESTS_SET_BY_PROFILE=1
    fi

    val="$(omni_profile_get_field "$profile" "WARN_POLICY" "")"
    if [[ -n "$val" && -z "${WARN_POLICY_SET_BY_PROFILE:-}" ]]; then
        export WARN_POLICY="$val"
        export WARN_POLICY_SET_BY_PROFILE=1
    fi
}

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
