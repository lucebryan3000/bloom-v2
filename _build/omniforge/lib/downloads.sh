#!/usr/bin/env bash
# =============================================================================
# lib/downloads.sh - Package Download Cache System
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Manages background package downloads and caching for faster reinstalls.
# Downloads packages to a local cache during preflight, uses cache during install.
#
# Exports:
#   downloads_init, downloads_start_for_config, downloads_wait,
#   downloads_get_cache_size, downloads_purge, downloads_get_path
#
# Dependencies:
#   lib/logging.sh
# =============================================================================

# Guard against double-sourcing
[[ -n "${_LIB_DOWNLOADS_LOADED:-}" ]] && return 0
_LIB_DOWNLOADS_LOADED=1

# =============================================================================
# CACHE CONFIGURATION
# =============================================================================

# Cache location (default: ~/.omniforge/cache)
: "${OMNIFORGE_CACHE_DIR:=${HOME}/.omniforge/cache}"
: "${OMNIFORGE_CACHE_MAX_AGE:=604800}"  # 7 days in seconds

# Package managers
declare -g _DOWNLOADS_PID=""
declare -g _DOWNLOADS_LOG=""
declare -g _DOWNLOADS_PACKAGES=()

# =============================================================================
# CACHE INITIALIZATION
# =============================================================================

# Initialize the download cache directory
# Usage: downloads_init
downloads_init() {
    log_debug "Initializing download cache at: ${OMNIFORGE_CACHE_DIR}"

    mkdir -p "${OMNIFORGE_CACHE_DIR}/npm"
    mkdir -p "${OMNIFORGE_CACHE_DIR}/pnpm"
    mkdir -p "${OMNIFORGE_CACHE_DIR}/logs"

    # Set up logging
    _DOWNLOADS_LOG="${OMNIFORGE_CACHE_DIR}/logs/download_$(date +%Y%m%d_%H%M%S).log"
    touch "$_DOWNLOADS_LOG"

    # Clean old cached packages
    _downloads_cleanup_old

    log_debug "Download cache initialized"
    return 0
}

# Clean up packages older than MAX_AGE
_downloads_cleanup_old() {
    local max_age="${OMNIFORGE_CACHE_MAX_AGE:-604800}"

    log_debug "Cleaning packages older than ${max_age} seconds"

    find "${OMNIFORGE_CACHE_DIR}" -type f -mtime +7 -delete 2>/dev/null || true
    find "${OMNIFORGE_CACHE_DIR}" -type d -empty -delete 2>/dev/null || true
}

# =============================================================================
# PACKAGE DETECTION
# =============================================================================

# Detect packages needed based on current configuration
# Returns array of package specs
_downloads_detect_packages() {
    _DOWNLOADS_PACKAGES=()

    # Core packages (always needed)
    _DOWNLOADS_PACKAGES+=(
        "npm:typescript"
        "npm:@types/node"
    )

    # Next.js
    if [[ "${ENABLE_NEXTJS:-true}" == "true" ]]; then
        _DOWNLOADS_PACKAGES+=(
            "npm:next"
            "npm:react"
            "npm:react-dom"
            "npm:@types/react"
            "npm:@types/react-dom"
        )
    fi

    # Database/Drizzle
    if [[ "${ENABLE_DATABASE:-true}" == "true" ]]; then
        _DOWNLOADS_PACKAGES+=(
            "npm:drizzle-orm"
            "npm:drizzle-kit"
            "npm:postgres"
            "npm:@vercel/postgres"
        )
    fi

    # Auth.js
    if [[ "${ENABLE_AUTHJS:-false}" == "true" ]]; then
        _DOWNLOADS_PACKAGES+=(
            "npm:next-auth"
            "npm:@auth/drizzle-adapter"
        )
    fi

    # AI SDK
    if [[ "${ENABLE_AI_SDK:-false}" == "true" ]]; then
        _DOWNLOADS_PACKAGES+=(
            "npm:ai"
            "npm:@ai-sdk/openai"
            "npm:@ai-sdk/anthropic"
        )
    fi

    # pg-boss
    if [[ "${ENABLE_PG_BOSS:-false}" == "true" ]]; then
        _DOWNLOADS_PACKAGES+=(
            "npm:pg-boss"
        )
    fi

    # shadcn/ui (these are the key dependencies)
    if [[ "${ENABLE_SHADCN:-false}" == "true" ]]; then
        _DOWNLOADS_PACKAGES+=(
            "npm:tailwindcss"
            "npm:autoprefixer"
            "npm:postcss"
            "npm:class-variance-authority"
            "npm:clsx"
            "npm:tailwind-merge"
            "npm:lucide-react"
            "npm:@radix-ui/react-slot"
        )
    fi

    # PDF Exports
    if [[ "${ENABLE_PDF_EXPORTS:-false}" == "true" ]]; then
        _DOWNLOADS_PACKAGES+=(
            "npm:jspdf"
            "npm:xlsx"
        )
    fi

    # Testing
    if [[ "${ENABLE_TEST_INFRA:-false}" == "true" ]]; then
        _DOWNLOADS_PACKAGES+=(
            "npm:vitest"
            "npm:@playwright/test"
            "npm:@testing-library/react"
        )
    fi

    # Code Quality
    if [[ "${ENABLE_CODE_QUALITY:-false}" == "true" ]]; then
        _DOWNLOADS_PACKAGES+=(
            "npm:eslint"
            "npm:prettier"
            "npm:@typescript-eslint/parser"
            "npm:@typescript-eslint/eslint-plugin"
        )
    fi

    log_debug "Detected ${#_DOWNLOADS_PACKAGES[@]} packages for download"
}

# =============================================================================
# BACKGROUND DOWNLOAD
# =============================================================================

# Start background download for current configuration
# Usage: downloads_start_for_config
downloads_start_for_config() {
    downloads_init
    _downloads_detect_packages

    if [[ ${#_DOWNLOADS_PACKAGES[@]} -eq 0 ]]; then
        log_debug "No packages to download"
        return 0
    fi

    log_debug "Starting background download of ${#_DOWNLOADS_PACKAGES[@]} packages"
    log_file "Starting download: ${_DOWNLOADS_PACKAGES[*]}"

    # Run download in background
    _downloads_background &
    _DOWNLOADS_PID=$!

    log_debug "Background download started (PID: $_DOWNLOADS_PID)"
    return 0
}

# Background download worker
_downloads_background() {
    local total=${#_DOWNLOADS_PACKAGES[@]}
    local current=0
    local failed=0

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting download of $total packages" >> "$_DOWNLOADS_LOG"

    for pkg_spec in "${_DOWNLOADS_PACKAGES[@]}"; do
        ((current++))

        local manager="${pkg_spec%%:*}"
        local package="${pkg_spec#*:}"

        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$current/$total] Downloading: $package" >> "$_DOWNLOADS_LOG"

        case "$manager" in
            npm|pnpm)
                _download_npm_package "$package"
                ;;
            *)
                echo "  Unknown manager: $manager" >> "$_DOWNLOADS_LOG"
                ((failed++))
                ;;
        esac
    done

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Download complete: $((total - failed))/$total succeeded" >> "$_DOWNLOADS_LOG"
}

# Download a single npm package to cache
_download_npm_package() {
    local package="$1"
    local cache_dir="${OMNIFORGE_CACHE_DIR}/npm"

    # Use npm pack to download without installing
    # This downloads to a tarball we can install from later
    local tarball

    if command -v pnpm &>/dev/null; then
        # pnpm stores in its own cache, just trigger fetch
        pnpm store add "$package" >> "$_DOWNLOADS_LOG" 2>&1 || {
            echo "  [WARN] Failed to cache: $package" >> "$_DOWNLOADS_LOG"
            return 1
        }
    elif command -v npm &>/dev/null; then
        # npm cache add
        npm cache add "$package" >> "$_DOWNLOADS_LOG" 2>&1 || {
            echo "  [WARN] Failed to cache: $package" >> "$_DOWNLOADS_LOG"
            return 1
        }
    fi

    echo "  [OK] Cached: $package" >> "$_DOWNLOADS_LOG"
    return 0
}

# =============================================================================
# DOWNLOAD CONTROL
# =============================================================================

# Wait for background download to complete
# Usage: downloads_wait [timeout_seconds]
downloads_wait() {
    local timeout="${1:-300}"

    if [[ -z "$_DOWNLOADS_PID" ]]; then
        log_debug "No background download running"
        return 0
    fi

    if ! kill -0 "$_DOWNLOADS_PID" 2>/dev/null; then
        log_debug "Background download already completed"
        return 0
    fi

    log_debug "Waiting for background download (PID: $_DOWNLOADS_PID)..."

    local waited=0
    while kill -0 "$_DOWNLOADS_PID" 2>/dev/null; do
        sleep 1
        ((waited++))

        if [[ $waited -ge $timeout ]]; then
            log_warn "Download timeout after ${timeout}s, killing..."
            kill "$_DOWNLOADS_PID" 2>/dev/null
            return 1
        fi
    done

    wait "$_DOWNLOADS_PID" 2>/dev/null
    local exit_code=$?

    log_debug "Background download finished (exit: $exit_code)"
    return $exit_code
}

# Check if download is still running
# Usage: downloads_is_running
downloads_is_running() {
    [[ -n "$_DOWNLOADS_PID" ]] && kill -0 "$_DOWNLOADS_PID" 2>/dev/null
}

# Get download progress (if available)
# Usage: downloads_get_progress
downloads_get_progress() {
    if [[ -z "$_DOWNLOADS_LOG" || ! -f "$_DOWNLOADS_LOG" ]]; then
        echo "0/0"
        return
    fi

    local completed
    completed=$(grep -c '\[OK\] Cached:' "$_DOWNLOADS_LOG" 2>/dev/null || echo 0)
    local total=${#_DOWNLOADS_PACKAGES[@]}

    echo "${completed}/${total}"
}

# =============================================================================
# CACHE MANAGEMENT
# =============================================================================

# Get cache size in MB
# Usage: downloads_get_cache_size
downloads_get_cache_size() {
    if [[ ! -d "${OMNIFORGE_CACHE_DIR}" ]]; then
        echo "0"
        return
    fi

    local size_kb
    size_kb=$(du -sk "${OMNIFORGE_CACHE_DIR}" 2>/dev/null | cut -f1 || echo 0)
    local size_mb=$((size_kb / 1024))

    echo "$size_mb"
}

# Get detailed cache info
# Usage: downloads_get_cache_info
downloads_get_cache_info() {
    if [[ ! -d "${OMNIFORGE_CACHE_DIR}" ]]; then
        echo "Cache not initialized"
        return
    fi

    local size_mb
    size_mb=$(downloads_get_cache_size)

    local file_count
    file_count=$(find "${OMNIFORGE_CACHE_DIR}" -type f 2>/dev/null | wc -l)

    echo "Location: ${OMNIFORGE_CACHE_DIR}"
    echo "Size: ${size_mb} MB"
    echo "Files: ${file_count}"
    echo "Max Age: $((OMNIFORGE_CACHE_MAX_AGE / 86400)) days"
}

# Purge entire cache
# Usage: downloads_purge
downloads_purge() {
    log_info "Purging download cache..."

    if [[ ! -d "${OMNIFORGE_CACHE_DIR}" ]]; then
        log_debug "Cache directory doesn't exist"
        return 0
    fi

    local size_before
    size_before=$(downloads_get_cache_size)

    rm -rf "${OMNIFORGE_CACHE_DIR:?}"/*

    log_info "Purged ${size_before} MB from cache"
    return 0
}

# Get path for cached package (for install commands)
# Usage: downloads_get_path "package-name"
downloads_get_path() {
    local package="$1"
    local cache_dir="${OMNIFORGE_CACHE_DIR}/npm"

    # Look for tarball in cache
    local tarball
    tarball=$(find "$cache_dir" -name "${package}-*.tgz" -type f 2>/dev/null | head -1)

    if [[ -n "$tarball" ]]; then
        echo "$tarball"
        return 0
    fi

    # Not in cache, return package name for normal install
    echo "$package"
    return 1
}

# =============================================================================
# EXPORT CACHE CONFIG TO PACKAGE MANAGERS
# =============================================================================

# Configure npm to use our cache
downloads_setup_npm_cache() {
    if [[ -n "${OMNIFORGE_CACHE_DIR}" ]]; then
        export npm_config_cache="${OMNIFORGE_CACHE_DIR}/npm"
    fi
}

# Configure pnpm to use our cache
downloads_setup_pnpm_cache() {
    if [[ -n "${OMNIFORGE_CACHE_DIR}" ]]; then
        export PNPM_HOME="${OMNIFORGE_CACHE_DIR}/pnpm"
    fi
}

# =============================================================================
# STANDALONE EXECUTION
# =============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Allow standalone execution for testing
    case "${1:-}" in
        --init)
            downloads_init
            echo "Cache initialized at: ${OMNIFORGE_CACHE_DIR}"
            ;;
        --size)
            echo "$(downloads_get_cache_size) MB"
            ;;
        --info)
            downloads_get_cache_info
            ;;
        --purge)
            downloads_purge
            ;;
        --start)
            # Source minimal logging if not available
            if ! type log_debug &>/dev/null; then
                log_debug() { echo "[DEBUG] $1"; }
                log_info() { echo "[INFO] $1"; }
                log_warn() { echo "[WARN] $1"; }
                log_file() { :; }
            fi
            downloads_start_for_config
            echo "Download started (PID: $_DOWNLOADS_PID)"
            ;;
        *)
            echo "Usage: $0 {--init|--size|--info|--purge|--start}"
            exit 1
            ;;
    esac
fi
