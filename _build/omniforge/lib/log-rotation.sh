#!/usr/bin/env bash
# =============================================================================
# lib/log-rotation.sh - Log Rotation & Cleanup Utilities
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Handles automatic log rotation and cleanup:
# - Rotate logs older than LOG_ROTATE_DAYS to archive/
# - Clean up archived logs older than LOG_CLEANUP_DAYS
# - Maintain organized log directory structure
#
# Usage:
#   source lib/log-rotation.sh
#   log_rotate_if_needed
#   log_cleanup_if_needed
#
# Dependencies:
#   lib/logging.sh (for log output)
# =============================================================================

# Guard against double-sourcing
[[ -n "${_LIB_LOG_ROTATION_LOADED:-}" ]] && return 0
_LIB_LOG_ROTATION_LOADED=1

# =============================================================================
# LOG ROTATION
# =============================================================================

# Rotate logs older than LOG_ROTATE_DAYS to archive/
# Usage: log_rotate_if_needed
log_rotate_if_needed() {
    local log_dir="${1:-.}"
    local rotate_days="${LOG_ROTATE_DAYS:-30}"

    # Skip if log directory doesn't exist
    if [[ ! -d "$log_dir" ]]; then
        return 0
    fi

    # Create archive directory if it doesn't exist
    if [[ ! -d "${log_dir}/archive" ]]; then
        mkdir -p "${log_dir}/archive"
    fi

    # Count files to rotate
    local count=0

    # Find and move logs older than rotate_days to archive/
    while IFS= read -r file; do
        local basename="$(basename "$file")"

        # Skip current log file
        if [[ "${basename}" == "${LOG_FILE##*/}" ]]; then
            continue
        fi

        # Skip archive directory
        if [[ "${file}" =~ /archive/ ]]; then
            continue
        fi

        # Move to archive
        mv "$file" "${log_dir}/archive/" 2>/dev/null
        ((count++)) || true

        log_file "Rotated: ${basename}" "ROTATION"
    done < <(find "$log_dir" -maxdepth 1 -name "*.log" -type f -mtime +${rotate_days} 2>/dev/null)

    if [[ $count -gt 0 ]]; then
        log_file "Rotated ${count} logs to archive/" "ROTATION"
    fi
}

# =============================================================================
# LOG CLEANUP
# =============================================================================

# Clean up archived logs older than LOG_CLEANUP_DAYS
# Usage: log_cleanup_if_needed
log_cleanup_if_needed() {
    local log_dir="${1:-.}"
    local cleanup_days="${LOG_CLEANUP_DAYS:-90}"

    # Skip if archive directory doesn't exist
    if [[ ! -d "${log_dir}/archive" ]]; then
        return 0
    fi

    # Count files to delete
    local count=0

    # Find and delete archived logs older than cleanup_days
    while IFS= read -r file; do
        local basename="$(basename "$file")"

        rm -f "$file"
        ((count++)) || true

        log_file "Deleted archived log: ${basename}" "CLEANUP"
    done < <(find "${log_dir}/archive" -maxdepth 1 -name "*.log" -type f -mtime +${cleanup_days} 2>/dev/null)

    if [[ $count -gt 0 ]]; then
        log_file "Deleted ${count} archived logs older than ${cleanup_days} days" "CLEANUP"
    fi
}

# =============================================================================
# LOG DIRECTORY MANAGEMENT
# =============================================================================

# Ensure log directory exists and is writable
# Usage: ensure_log_dir "/path/to/logs"
ensure_log_dir() {
    local log_dir="${1:-.}"

    # Create log directory if it doesn't exist
    if [[ ! -d "$log_dir" ]]; then
        mkdir -p "$log_dir" || return 1
    fi

    # Check write permissions
    if [[ ! -w "$log_dir" ]]; then
        log_error "Log directory not writable: $log_dir"
        return 1
    fi

    # Create archive subdirectory
    if [[ ! -d "${log_dir}/archive" ]]; then
        mkdir -p "${log_dir}/archive"
    fi

    return 0
}

# Get log directory size (for reporting)
# Usage: log_dir_size=$(get_log_dir_size "/path/to/logs")
get_log_dir_size() {
    local log_dir="${1:-.}"

    if [[ ! -d "$log_dir" ]]; then
        echo "0"
        return 0
    fi

    # Get size in bytes, convert to MB
    local size_bytes
    size_bytes=$(du -sb "$log_dir" 2>/dev/null | awk '{print $1}')
    echo "$((size_bytes / 1024 / 1024))"
}

# List recent logs (for user reference)
# Usage: list_recent_logs "/path/to/logs" 5
list_recent_logs() {
    local log_dir="${1:-.}"
    local count="${2:-5}"

    if [[ ! -d "$log_dir" ]]; then
        return 0
    fi

    # Find most recent logs
    find "$log_dir" -maxdepth 1 -name "*.log" -type f -printf '%T@ %p\n' | \
        sort -rn | head -n "$count" | awk '{print $2}'
}

# Export functions for subshells
export -f log_rotate_if_needed
export -f log_cleanup_if_needed
export -f ensure_log_dir
export -f get_log_dir_size
export -f list_recent_logs
