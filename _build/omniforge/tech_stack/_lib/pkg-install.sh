#!/usr/bin/env bash
# =============================================================================
# tech_stack/_lib/pkg-install.sh - Package Installation Utilities
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Purpose: Provide cache-aware package installation with error handling
#
# Features:
#   - Checks .download-cache/npm first for offline packages
#   - Falls back to network install if cache miss
#   - Validates package installation success
#   - Supports both dependencies and devDependencies
#
# Usage:
#   source "${SCRIPT_DIR}/../_lib/pkg-install.sh"
#   pkg_install "next" "react" "react-dom"
#   pkg_install_dev "typescript" "@types/node"
#   pkg_install_from_cache "next-16.0.3.tgz"
# =============================================================================
#
# Dependencies:
#   - pnpm
#

# Guard against double-sourcing
[[ -n "${_LIB_PKG_INSTALL_LOADED:-}" ]] && return 0
_LIB_PKG_INSTALL_LOADED=1

# =============================================================================
# CONFIGURATION
# =============================================================================

# Cache directory (relative to omniforge root)
readonly PKG_CACHE_DIR="${SCRIPTS_DIR:-.}/.download-cache/npm"

# Package manager (pnpm preferred, fallback to npm)
PKG_MANAGER=""
if command -v pnpm &>/dev/null; then
    PKG_MANAGER="pnpm"
elif command -v npm &>/dev/null; then
    PKG_MANAGER="npm"
fi

if [[ -n "${INSIDE_OMNI_DOCKER:-}" && "${PKG_MANAGER}" != "pnpm" ]]; then
    log_error "[docker] pnpm is required inside the container. Rebuild Dockerfile.dev (Phase 2)."
    PKG_MANAGER=""
fi

# Require an available package manager
pkg_require_manager() {
    if [[ -z "$PKG_MANAGER" ]]; then
        log_error "Package manager not available. Ensure pnpm (in container mode) or pnpm/npm is installed."
        return 1
    fi
}

# =============================================================================
# CACHE UTILITIES
# =============================================================================

# Check if a package tarball exists in cache
# Usage: pkg_cache_exists "next-16.0.3.tgz"
pkg_cache_exists() {
    local tarball="$1"
    [[ -f "${PKG_CACHE_DIR}/${tarball}" ]]
}

# Find cached tarball for a package (any version)
# Usage: pkg_cache_find "next" -> "next-16.0.3.tgz" or ""
pkg_cache_find() {
    local pkg_name="$1"
    local found=""

    if [[ -d "$PKG_CACHE_DIR" ]]; then
        # Look for package-version.tgz pattern
        found=$(find "$PKG_CACHE_DIR" -maxdepth 1 -name "${pkg_name}-*.tgz" -type f 2>/dev/null | head -1)
        if [[ -n "$found" ]]; then
            basename "$found"
        fi
    fi
}

# List all cached packages
# Usage: pkg_cache_list
pkg_cache_list() {
    if [[ -d "$PKG_CACHE_DIR" ]]; then
        find "$PKG_CACHE_DIR" -maxdepth 1 -name "*.tgz" -type f 2>/dev/null | while read -r f; do
            basename "$f"
        done
    fi
}

# =============================================================================
# INSTALLATION FUNCTIONS
# =============================================================================

# Install a single package from cache tarball
# Usage: pkg_install_from_cache "next-16.0.3.tgz" [--save-dev]
pkg_install_from_cache() {
    local tarball="$1"
    local save_flag="${2:---save}"
    local tarball_path="${PKG_CACHE_DIR}/${tarball}"

    pkg_require_manager || return 1

    if [[ ! -f "$tarball_path" ]]; then
        log_error "Cache tarball not found: $tarball"
        return 1
    fi

    log_info "Installing from cache: $tarball"

    if [[ "$PKG_MANAGER" == "pnpm" ]]; then
        pnpm add "$tarball_path" $save_flag 2>&1 || {
            log_error "Failed to install $tarball from cache"
            return 1
        }
    else
        npm install "$tarball_path" $save_flag 2>&1 || {
            log_error "Failed to install $tarball from cache"
            return 1
        }
    fi

    log_ok "Installed from cache: $tarball"
    return 0
}

# Install packages with cache-first strategy
# Usage: pkg_install "next" "react" "react-dom"
pkg_install() {
    local packages=("$@")
    local cache_installs=()
    local network_installs=()
    local failed=()
    local pnpm_flags="${PNPM_FLAGS_OVERRIDE:-${PNPM_FLAGS:-}}"
    local node_opts="${NODE_OPTIONS:-}"

    pkg_require_manager || return 1

    # Sort packages into cache vs network
    for pkg in "${packages[@]}"; do
        local cached=$(pkg_cache_find "$pkg")
        if [[ -n "$cached" ]]; then
            cache_installs+=("$cached")
        else
            network_installs+=("$pkg")
        fi
    done

    # Install from cache first
    for tarball in "${cache_installs[@]}"; do
        if ! pkg_install_from_cache "$tarball" "--save"; then
            failed+=("$tarball")
        fi
    done

    # Install remaining from network
    if [[ ${#network_installs[@]} -gt 0 ]]; then
        log_info "Installing from network: ${network_installs[*]}"

        if [[ "$PKG_MANAGER" == "pnpm" ]]; then
            NODE_OPTIONS="$node_opts" pnpm add ${pnpm_flags:+$pnpm_flags} "${network_installs[@]}" 2>&1 || {
                log_error "Failed network install: ${network_installs[*]}"
                failed+=("${network_installs[@]}")
            }
        else
            npm install "${network_installs[@]}" 2>&1 || {
                log_error "Failed network install: ${network_installs[*]}"
                failed+=("${network_installs[@]}")
            }
        fi
    fi

    # Report results
    if [[ ${#failed[@]} -gt 0 ]]; then
        log_error "Failed to install: ${failed[*]}"
        return 1
    fi

    log_ok "All packages installed successfully"
    return 0
}

# Install dev dependencies with cache-first strategy
# Usage: pkg_install_dev "typescript" "@types/node"
pkg_install_dev() {
    local packages=("$@")
    local cache_installs=()
    local network_installs=()
    local failed=()
    local pnpm_flags="${PNPM_FLAGS_OVERRIDE:-${PNPM_FLAGS:-}}"
    local node_opts="${NODE_OPTIONS:-}"

    pkg_require_manager || return 1

    # Sort packages into cache vs network
    for pkg in "${packages[@]}"; do
        local cached=$(pkg_cache_find "$pkg")
        if [[ -n "$cached" ]]; then
            cache_installs+=("$cached")
        else
            network_installs+=("$pkg")
        fi
    done

    # Install from cache first
    for tarball in "${cache_installs[@]}"; do
        if ! pkg_install_from_cache "$tarball" "--save-dev"; then
            failed+=("$tarball")
        fi
    done

    # Install remaining from network
    if [[ ${#network_installs[@]} -gt 0 ]]; then
        log_info "Installing dev deps from network: ${network_installs[*]}"

        if [[ "$PKG_MANAGER" == "pnpm" ]]; then
            NODE_OPTIONS="$node_opts" pnpm add -D ${pnpm_flags:+$pnpm_flags} "${network_installs[@]}" 2>&1 || {
                log_error "Failed network install: ${network_installs[*]}"
                failed+=("${network_installs[@]}")
            }
        else
            npm install --save-dev "${network_installs[@]}" 2>&1 || {
                log_error "Failed network install: ${network_installs[*]}"
                failed+=("${network_installs[@]}")
            }
        fi
    fi

    # Report results
    if [[ ${#failed[@]} -gt 0 ]]; then
        log_error "Failed to install dev deps: ${failed[*]}"
        return 1
    fi

    log_ok "All dev dependencies installed successfully"
    return 0
}

# Retry wrappers (lightweight) ------------------------------------------------
pkg_install_retry() {
    local attempts="${PKG_INSTALL_RETRIES:-3}"
    local delay="${PKG_INSTALL_RETRY_DELAY:-2}"
    local gap="${PKG_INSTALL_GAP:-2}"
    local i
    for ((i=1; i<=attempts; i++)); do
        if pkg_install "$@"; then
            sleep "$gap" || true
            return 0
        fi
        log_warn "pkg_install retry $i/$attempts failed for: $*"
        sleep "$delay" || true
    done
    return 1
}

pkg_install_dev_retry() {
    local attempts="${PKG_INSTALL_RETRIES:-3}"
    local delay="${PKG_INSTALL_RETRY_DELAY:-2}"
    local gap="${PKG_INSTALL_GAP:-2}"
    local i
    for ((i=1; i<=attempts; i++)); do
        if pkg_install_dev "$@"; then
            sleep "$gap" || true
            return 0
        fi
        log_warn "pkg_install_dev retry $i/$attempts failed for: $*"
        sleep "$delay" || true
    done
    return 1
}

# =============================================================================
# VERIFICATION FUNCTIONS
# =============================================================================

# Verify a package is installed in node_modules
# Usage: pkg_verify "next"
pkg_verify() {
    local pkg="$1"
    local node_modules="${PROJECT_ROOT:-./}/node_modules"

    if [[ -d "${node_modules}/${pkg}" ]]; then
        return 0
    fi

    # Handle scoped packages (@org/pkg)
    if [[ "$pkg" == @*/* ]]; then
        local scope="${pkg%/*}"
        local name="${pkg#*/}"
        if [[ -d "${node_modules}/${scope}/${name}" ]]; then
            return 0
        fi
    fi

    return 1
}

# Verify multiple packages are installed
# Usage: pkg_verify_all "next" "react" "react-dom"
pkg_verify_all() {
    local packages=("$@")
    local missing=()

    for pkg in "${packages[@]}"; do
        if ! pkg_verify "$pkg"; then
            missing+=("$pkg")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing packages: ${missing[*]}"
        return 1
    fi

    return 0
}

# =============================================================================
# PREFLIGHT CHECK
# =============================================================================

# Check cache status for a list of packages (informational only)
# Usage: pkg_preflight_check "next" "react" "typescript"
# Returns: Always 0 (this is purely informational, never fails the build)
pkg_preflight_check() {
    local packages=("$@")
    local cached=0
    local network=0

    echo ""
    echo "  Package Cache Status:"
    echo "  ─────────────────────"

    for pkg in "${packages[@]}"; do
        local found=$(pkg_cache_find "$pkg")
        if [[ -n "$found" ]]; then
            echo "  [CACHED]  $pkg → $found"
            cached=$((cached + 1))
        else
            echo "  [NETWORK] $pkg"
            network=$((network + 1))
        fi
    done

    echo ""
    echo "  Summary: $cached cached, $network require network"
    echo ""

    return 0  # Informational only - always succeed
}

# =============================================================================
# EXPORTS
# =============================================================================

export PKG_CACHE_DIR PKG_MANAGER
