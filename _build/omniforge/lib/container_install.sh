#!/usr/bin/env bash
# =============================================================================
# lib/container_install.sh - container-only dependency installer
# =============================================================================

if [[ -n "${_OMNI_CONTAINER_INSTALL_LIB_LOADED:-}" ]]; then
    return 0 2>/dev/null || exit 0
fi
_OMNI_CONTAINER_INSTALL_LIB_LOADED=1

omni_container_install_if_needed() {
    # Only run inside Docker container
    if [[ -z "${INSIDE_OMNI_DOCKER:-}" ]]; then
        return 0
    fi

    local auto_install="${APP_AUTO_INSTALL:-true}"
    if [[ "${auto_install}" != "true" ]]; then
        log_debug "[docker] APP_AUTO_INSTALL=false; skipping container install"
        return 0
    fi

    local install_marker="${PROJECT_ROOT}/.omniforge_node_modules_ready"

    if [[ -d "${PROJECT_ROOT}/node_modules" && -f "${install_marker}" ]]; then
        log_debug "[docker] node_modules present; skipping container install"
        return 0
    fi

    log_info "[docker] Installing dependencies inside container (one-time)..."
    if pnpm install; then
        touch "${install_marker}" 2>/dev/null || true
        return 0
    fi

    log_warn "[docker] pnpm install failed as current user, retrying as root then node"
    if ! command -v su >/dev/null 2>&1; then
        log_error "[docker] su not available; pnpm install failed"
        return 1
    fi

    if su root -c "cd '${PROJECT_ROOT}' && pnpm install"; then
        touch "${install_marker}" 2>/dev/null || true
        return 0
    fi

    if su root -c "cd '${PROJECT_ROOT}' && chown -R node:node /workspace || true; su node -c \"cd '${PROJECT_ROOT}' && pnpm install\""; then
        touch "${install_marker}" 2>/dev/null || true
        return 0
    fi

    log_error "[docker] pnpm install failed in container"
    return 1
}
