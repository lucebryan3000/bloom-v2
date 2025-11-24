#!/usr/bin/env bash
# =============================================================================
# lib/git.sh - Git Safety Checks
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Pure functions for git operations. No execution on source.
#
# Exports:
#   git_ensure_clean, git_is_repo, git_current_branch
#
# Dependencies:
#   lib/logging.sh
# =============================================================================

# Guard against double-sourcing
[[ -n "${_LIB_GIT_LOADED:-}" ]] && return 0
_LIB_GIT_LOADED=1

# =============================================================================
# GIT SAFETY
# =============================================================================

# Ensure git working directory is clean (if GIT_SAFETY is enabled)
# Usage: git_ensure_clean
git_ensure_clean() {
    local git_safety="${GIT_SAFETY:-false}"
    local allow_dirty="${ALLOW_DIRTY:-false}"

    if [[ "$git_safety" != "true" ]]; then
        log_debug "Git safety check disabled"
        return 0
    fi

    if [[ "$allow_dirty" == "true" ]]; then
        log_debug "Git safety check skipped (ALLOW_DIRTY=true)"
        return 0
    fi

    local project_dir="${PROJECT_ROOT:-.}"
    if [[ ! -d "${project_dir}/.git" ]]; then
        log_debug "Not a git repository, skipping git safety check"
        return 0
    fi

    local status
    status="$(cd "${project_dir}" && git status --porcelain 2>/dev/null)"

    if [[ -n "$status" ]]; then
        log_error "Git working directory is not clean"
        log_error "Uncommitted changes found. Commit or stash before running bootstrap."
        log_error "Use ALLOW_DIRTY=true to override this check."
        return 1
    fi

    log_debug "Git working directory is clean"
    return 0
}

# Check if we're in a git repository
# Usage: git_is_repo
git_is_repo() {
    local project_dir="${PROJECT_ROOT:-.}"
    [[ -d "${project_dir}/.git" ]]
}

# Get current git branch
# Usage: branch=$(git_current_branch)
git_current_branch() {
    local project_dir="${PROJECT_ROOT:-.}"
    cd "${project_dir}" && git branch --show-current 2>/dev/null
}

# Get short commit hash
# Usage: hash=$(git_short_hash)
git_short_hash() {
    local project_dir="${PROJECT_ROOT:-.}"
    cd "${project_dir}" && git rev-parse --short HEAD 2>/dev/null
}
