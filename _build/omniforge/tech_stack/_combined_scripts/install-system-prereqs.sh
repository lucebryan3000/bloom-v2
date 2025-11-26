#!/usr/bin/env bash
# =============================================================================
# tech_stack/_combined_scripts/install-system-prereqs.sh
# Ensures docker CLI and psql client are available with basic retries.
# Skips docker install inside container; attempts apk add psql in container.
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"
source "${SCRIPT_DIR}/../../lib/pkgman.sh"

readonly SCRIPT_ID="_combined/install-system-prereqs"
readonly SCRIPT_NAME="Install system prerequisites (docker, psql)"

log_step "${SCRIPT_NAME}"

retry_cmd() {
    local attempts="${1:-3}"
    local delay="${2:-2}"
    shift 2
    local cmd=("$@")
    local i
    for ((i=1; i<=attempts; i++)); do
        if "${cmd[@]}"; then
            return 0
        fi
        log_warn "Retry $i/$attempts failed: ${cmd[*]}"
        sleep "$delay" || true
    done
    return 1
}

# Inside container: skip docker, try to install psql via apk
if [[ -n "${INSIDE_OMNI_DOCKER:-}" ]]; then
    log_debug "[docker] Inside container; skipping docker CLI check"
    if ! command -v psql >/dev/null 2>&1; then
        if command -v apk >/dev/null 2>&1; then
            log_info "[docker] Installing psql client via apk..."
            retry_cmd 3 2 apk add --no-cache postgresql-client || log_warn "[docker] Failed to install psql client"
        else
            log_warn "[docker] apk not available; cannot install psql client"
        fi
    fi
    mark_script_success "${SCRIPT_ID}"
    log_ok "${SCRIPT_NAME} complete (container mode)"
    exit 0
fi

# Host: ensure docker and psql
pkgman_info

if ! command -v docker >/dev/null 2>&1; then
    log_info "docker not found; attempting install via package manager..."
    if ! pkgman_install docker docker.io docker-ce 2>/dev/null; then
        log_warn "Could not install docker automatically. Install manually from https://docker.com"
    fi
else
    log_debug "docker CLI present"
fi

if ! command -v psql >/dev/null 2>&1; then
    log_info "psql not found; attempting install via package manager..."
    if ! pkgman_install postgresql-client postgresql 2>/dev/null; then
        log_warn "Could not install psql automatically. Install manually from https://postgresql.org"
    fi
else
    log_debug "psql client present"
fi

mark_script_success "${SCRIPT_ID}"
log_ok "${SCRIPT_NAME} complete"
