#!/usr/bin/env bash
# =============================================================================
# lib/auto_detect.sh - Auto-Detection of Project Settings
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Detects project settings on first run:
#   - Project name from git repo or directory name
#   - Git remote URL
#   - Configuration initialization status
#
# Exports:
#   autodetect_project_name, autodetect_git_remote, autodetect_is_needed,
#   autodetect_run_all, autodetect_write_to_config
#
# Dependencies:
#   lib/logging.sh
# =============================================================================

# Guard against double-sourcing
[[ -n "${_LIB_AUTO_DETECT_LOADED:-}" ]] && return 0
_LIB_AUTO_DETECT_LOADED=1

# =============================================================================
# PROJECT NAME DETECTION
# =============================================================================

# Detect project name from folder or git repo
autodetect_project_name() {
    # Try git repo name first
    if git rev-parse --git-dir >/dev/null 2>&1; then
        local repo_name
        repo_name=$(basename "$(git rev-parse --show-toplevel)" 2>/dev/null)
        if [[ -n "$repo_name" ]]; then
            echo "$repo_name"
            return 0
        fi
    fi

    # Fallback to current directory name
    basename "$(pwd)"
}

# =============================================================================
# GIT REMOTE DETECTION
# =============================================================================

# Detect git remote URL
autodetect_git_remote() {
    if git rev-parse --git-dir >/dev/null 2>&1; then
        git remote get-url origin 2>/dev/null || echo ""
    else
        echo ""
    fi
}

# =============================================================================
# INITIALIZATION STATUS CHECK
# =============================================================================

# Check if auto-detection is needed (first run)
autodetect_is_needed() {
    # Check if OMNIFORGE_CONFIG_INITIALIZED is false or unset
    [[ "${OMNIFORGE_CONFIG_INITIALIZED:-false}" != "true" ]]
}

# =============================================================================
# RUN ALL AUTO-DETECTION
# =============================================================================

# Run all auto-detection and export results
autodetect_run_all() {
    log_debug "Running auto-detection..."

    export AUTO_DETECTED_PROJECT_NAME=$(autodetect_project_name)
    export AUTO_DETECTED_GIT_REMOTE=$(autodetect_git_remote)

    log_debug "Detected project name: ${AUTO_DETECTED_PROJECT_NAME}"
    log_debug "Detected git remote: ${AUTO_DETECTED_GIT_REMOTE:-none}"
}

# =============================================================================
# WRITE DETECTED VALUES TO CONFIG
# =============================================================================

# Write detected values to omni.config (Section 1) and related settings
autodetect_write_to_config() {
    local config_file="${OMNI_CONFIG_PATH:-${SCRIPTS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/omni.config}"

    log_info "Writing auto-detected values to omni.config"

    # Use sed to update values (avoid IFS issues by using arrays)
    local sed_cmd=(sed -i)
    if [[ "$(uname)" == "Darwin" ]]; then
        sed_cmd=(sed -i '')
    fi

    # Update APP_NAME if still default
    if grep -q '^APP_NAME="Bloom"' "$config_file"; then
        "${sed_cmd[@]}" "s/^APP_NAME=.*/APP_NAME=\"${AUTO_DETECTED_PROJECT_NAME}\"/" "$config_file"
    fi

    # Update GIT_REMOTE_URL
    if [[ -n "${AUTO_DETECTED_GIT_REMOTE}" ]]; then
        if grep -q '^GIT_REMOTE_URL=' "$config_file"; then
            "${sed_cmd[@]}" "s|^GIT_REMOTE_URL=.*|GIT_REMOTE_URL=\"${AUTO_DETECTED_GIT_REMOTE}\"|" "$config_file"
        else
            echo "GIT_REMOTE_URL=\"${AUTO_DETECTED_GIT_REMOTE}\"" >> "$config_file"
        fi
    fi

    # Mark as initialized
    if grep -q '^OMNIFORGE_CONFIG_INITIALIZED=' "$config_file"; then
        "${sed_cmd[@]}" 's/^OMNIFORGE_CONFIG_INITIALIZED=.*/OMNIFORGE_CONFIG_INITIALIZED="true"/' "$config_file"
    else
        echo 'OMNIFORGE_CONFIG_INITIALIZED="true"' >> "$config_file"
    fi

    log_success "Auto-detection complete"
}
