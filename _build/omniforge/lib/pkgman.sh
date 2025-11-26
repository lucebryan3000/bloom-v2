#!/usr/bin/env bash
# =============================================================================
# lib/pkgman.sh - Lightweight package manager detection/helpers
# =============================================================================
# Purpose:
#   - Detect the active system package manager (apt, apk, yum, dnf)
#   - Provide thin install wrappers so scripts can call pkgman_install "pkg1" "pkg2"
#   - Avoid heavy auto-installs of optional managers (brew/conda/nix) — just detect/log
#
# Exports:
#   pkgman_detect           # echo manager name: apt|apk|yum|dnf|unknown
#   pkgman_install ...      # install packages via detected manager
#   pkgman_ensure ...       # install if missing (best-effort), else warn
#   pkgman_info             # log which manager is active
#
# Notes:
#   - Intended for minimal use inside scripts that need a system pkg (e.g., psql in container)
#   - Does not implement caching for OS package managers
# =============================================================================

[[ -n "${_LIB_PKGMAN_LOADED:-}" ]] && return 0
_LIB_PKGMAN_LOADED=1

pkgman_detect() {
    if command -v apt-get >/dev/null 2>&1; then
        echo "apt"
    elif command -v apk >/dev/null 2>&1; then
        echo "apk"
    elif command -v dnf >/dev/null 2>&1; then
        echo "dnf"
    elif command -v yum >/dev/null 2>&1; then
        echo "yum"
    else
        echo "unknown"
    fi
}

pkgman_info() {
    local mgr
    mgr="$(pkgman_detect)"
    case "$mgr" in
        apt) log_debug "[pkgman] Using apt-get (Debian/Ubuntu)" ;;
        apk) log_debug "[pkgman] Using apk (Alpine)" ;;
        dnf) log_debug "[pkgman] Using dnf (Fedora/RHEL)" ;;
        yum) log_debug "[pkgman] Using yum (CentOS/RHEL)" ;;
        *)   log_warn "[pkgman] No supported package manager detected" ;;
    esac
}

pkgman_install() {
    local mgr
    mgr="$(pkgman_detect)"
    local pkgs=("$@")

    if [[ ${#pkgs[@]} -eq 0 ]]; then
        return 0
    fi

    case "$mgr" in
        apt)
            sudo apt-get update -y >/dev/null 2>&1 || true
            sudo apt-get install -y "${pkgs[@]}"
            ;;
        apk)
            apk add --no-cache "${pkgs[@]}"
            ;;
        dnf)
            sudo dnf install -y "${pkgs[@]}"
            ;;
        yum)
            sudo yum install -y "${pkgs[@]}"
            ;;
        *)
            log_warn "[pkgman] Cannot install ${pkgs[*]}: no supported package manager detected"
            return 1
            ;;
    esac
}

pkgman_ensure() {
    local pkgs=("$@")
    local to_install=()
    for p in "${pkgs[@]}"; do
        if ! command -v "$p" >/dev/null 2>&1; then
            to_install+=("$p")
        fi
    done

    if [[ ${#to_install[@]} -eq 0 ]]; then
        return 0
    fi

    pkgman_install "${to_install[@]}" || {
        log_warn "[pkgman] Failed to ensure: ${to_install[*]}"
        return 1
    }
}
