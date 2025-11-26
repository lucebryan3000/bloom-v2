#!/usr/bin/env bash
# =============================================================================
# lib/validation.sh - Validation Helper Functions
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Pure functions for validating commands, files, versions. No execution on source.
#
# Exports:
#   require_cmd, require_node_version, require_pnpm, require_docker,
#   require_file, require_project_root
#
# Dependencies:
#   lib/logging.sh
# =============================================================================

# Guard against double-sourcing
[[ -n "${_LIB_VALIDATION_LOADED:-}" ]] && return 0
_LIB_VALIDATION_LOADED=1

# =============================================================================
# COMMAND VALIDATION
# =============================================================================

# Check if command exists
# Usage: require_cmd "docker" "Install from https://docker.com"
require_cmd() {
    local cmd="$1"
    local install_hint="${2:-}"

    if ! command -v "$cmd" &> /dev/null; then
        log_error "Required command not found: $cmd"
        if [[ -n "$install_hint" ]]; then
            log_error "Install with: $install_hint"
        fi
        return 1
    fi
    log_debug "Found command: $cmd"
    return 0
}

# Ensure required database clients exist (container-safe)
# Usage: ensure_db_client "postgres" | "sqlite"
ensure_db_client() {
    local db_type="${1:-postgres}"

    # If running inside OmniForge container and apk exists, install as needed
    if [[ -n "${INSIDE_OMNI_DOCKER:-}" && -x "/sbin/apk" ]]; then
        case "$db_type" in
            postgres)
                if ! command -v psql &>/dev/null; then
                    log_info "Installing PostgreSQL client (psql) inside container..."
                    apk add --no-cache postgresql-client >/dev/null 2>&1 || {
                        log_warn "Failed to install postgresql-client; psql may be unavailable"
                    }
                fi
                ;;
            sqlite|litesql)
                if ! command -v sqlite3 &>/dev/null; then
                    log_info "Installing SQLite client inside container..."
                    apk add --no-cache sqlite >/dev/null 2>&1 || {
                        log_warn "Failed to install sqlite client"
                    }
                fi
                ;;
        esac
    fi
}

# Check Node.js version meets minimum
# Usage: require_node_version 20
require_node_version() {
    local min_version="${1:-20}"

    if ! command -v node &> /dev/null; then
        log_error "Node.js not found. Install from https://nodejs.org"
        return 1
    fi

    local current_version
    current_version=$(node -v | sed 's/v//' | cut -d'.' -f1)

    if [[ "$current_version" -lt "$min_version" ]]; then
        log_error "Node.js version $min_version+ required, found: $(node -v)"
        return 1
    fi
    log_debug "Node.js version OK: $(node -v)"
    return 0
}

# Check pnpm is installed
require_pnpm() {
    require_cmd "pnpm" "npm install -g pnpm"
}

# Check Docker is installed and running
require_docker() {
    local install_hint="Install Docker from https://docker.com"

    if ! require_cmd "docker" "$install_hint"; then
        log_error "Docker is required to bootstrap. Install Docker and ensure the daemon is running, then rerun omni (Option 1)."
        return 1
    fi

    if ! docker info &> /dev/null; then
        log_error "Docker is required to bootstrap. Install Docker and ensure the daemon is running, then rerun omni (Option 1)."
        return 1
    fi

    if ! require_docker_compose; then
        log_error "Docker is required to bootstrap. Install Docker and ensure the daemon is running, then rerun omni (Option 1)."
        return 1
    fi

    log_debug "Docker CLI, daemon, and compose are available"
    return 0
}

# Check Docker Compose is available (v2 plugin or standalone)
require_docker_compose() {
    if command -v docker >/dev/null 2>&1 && docker compose version &> /dev/null; then
        log_debug "Docker Compose v2 (plugin) available"
        return 0
    fi

    if command -v docker-compose &> /dev/null; then
        log_warn "Using standalone docker-compose. Consider upgrading to Docker Compose v2"
        return 0
    fi

    log_error "Docker Compose not found. Install Docker Compose v2 or the docker-compose plugin."
    return 1
}

# Check Docker BuildKit is enabled
require_buildkit() {
    if [[ "${DOCKER_BUILDKIT:-0}" != "1" ]]; then
        log_warn "DOCKER_BUILDKIT not enabled. Set DOCKER_BUILDKIT=1 for optimized builds"
        return 1
    fi
    log_debug "Docker BuildKit enabled"
    return 0
}

# Full Docker environment check (Docker + Compose + running)
require_docker_env() {
    if ! require_docker; then
        return 1
    fi

    return 0
}

# =============================================================================
# FILE VALIDATION
# =============================================================================

# Check if file exists
# Usage: require_file "/path/to/file" "Run setup first"
require_file() {
    local file="$1"
    local hint="${2:-}"

    if [[ ! -f "$file" ]]; then
        log_error "Required file not found: $file"
        if [[ -n "$hint" ]]; then
            log_error "Hint: $hint"
        fi
        return 1
    fi
    log_debug "Found file: $file"
    return 0
}

# Check if directory exists
# Usage: require_dir "/path/to/dir"
require_dir() {
    local dir="$1"
    local hint="${2:-}"

    if [[ ! -d "$dir" ]]; then
        log_error "Required directory not found: $dir"
        if [[ -n "$hint" ]]; then
            log_error "Hint: $hint"
        fi
        return 1
    fi
    log_debug "Found directory: $dir"
    return 0
}

# Check if we're in a project directory (has package.json)
require_project_root() {
    if [[ ! -f "package.json" ]]; then
        log_error "Not in a project root (no package.json found)"
        log_error "Please run this script from the project root directory"
        return 1
    fi
    return 0
}

# =============================================================================
# DEPENDENCY CHECKING FROM PHASE CONFIG
# =============================================================================

# Check dependencies from PHASE_CONFIG deps string
# Usage: check_phase_deps "git:https://git-scm.com,node:https://nodejs.org"
check_phase_deps() {
    local deps_string="$1"
    local prereq_mode="${2:-warn}"  # strict|warn

    [[ -z "$deps_string" ]] && return 0

    local IFS=','
    local failed=0

    for dep in $deps_string; do
        local cmd="${dep%%:*}"
        local url="${dep#*:}"

        # Skip "builtin" dependencies
        [[ "$url" == "builtin" ]] && continue

        if ! command -v "$cmd" &> /dev/null; then
            if [[ "$prereq_mode" == "strict" ]]; then
                log_error "Required: $cmd - Install from $url"
                failed=1
            else
                log_warn "Missing (optional): $cmd - Install from $url"
            fi
        else
            log_debug "Dependency OK: $cmd"
        fi
    done

    return $failed
}

# =============================================================================
# DEPENDENCY REMEDIATION (Auto-install missing dependencies)
# =============================================================================

# Install pnpm globally using npm
# Usage: install_pnpm
install_pnpm() {
    if command -v pnpm &>/dev/null; then
        log_ok "pnpm already installed"
        return 0
    fi

    log_step "Installing pnpm..."
    if npm install -g pnpm 2>/dev/null; then
        log_ok "pnpm installed successfully"
        return 0
    else
        log_error "Failed to install pnpm"
        return 1
    fi
}

# Attempt to install Docker
# Usage: install_docker
# Respects: AUTO_INSTALL_DOCKER flag
install_docker() {
    if command -v docker &>/dev/null; then
        log_ok "Docker already installed"
        return 0
    fi

    # Check if auto-install is disabled
    if [[ "${AUTO_INSTALL_DOCKER:-true}" != "true" ]]; then
        log_debug "Docker auto-install disabled (AUTO_INSTALL_DOCKER=false)"
        return 1
    fi

    log_step "Installing Docker..."

    # Detect OS and install accordingly
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux: Use package manager
        if command -v apt-get &>/dev/null; then
            log_info "Installing Docker via apt-get..."
            sudo apt-get update && sudo apt-get install -y docker.io 2>/dev/null && return 0
        elif command -v yum &>/dev/null; then
            log_info "Installing Docker via yum..."
            sudo yum install -y docker 2>/dev/null && return 0
        elif command -v brew &>/dev/null; then
            log_info "Installing Docker via brew..."
            brew install docker 2>/dev/null && return 0
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS: Use Homebrew
        if command -v brew &>/dev/null; then
            log_info "Installing Docker via Homebrew (macOS)..."
            brew install docker docker-machine 2>/dev/null && return 0
        fi
    fi

    log_error "Could not auto-install Docker - please install manually from https://docker.com"
    return 1
}

# Attempt to install PostgreSQL client (psql)
# Usage: install_psql
# Respects: AUTO_INSTALL_PSQL flag
install_psql() {
    if command -v psql &>/dev/null; then
        log_ok "psql (PostgreSQL client) already installed"
        return 0
    fi

    # Check if auto-install is disabled
    if [[ "${AUTO_INSTALL_PSQL:-true}" != "true" ]]; then
        log_debug "psql auto-install disabled (AUTO_INSTALL_PSQL=false)"
        return 1
    fi

    log_step "Installing psql (PostgreSQL client)..."

    # Detect OS and install accordingly
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux: Use package manager
        if command -v apt-get &>/dev/null; then
            log_info "Installing PostgreSQL client via apt-get..."
            sudo apt-get update && sudo apt-get install -y postgresql-client 2>/dev/null && return 0
        elif command -v yum &>/dev/null; then
            log_info "Installing PostgreSQL client via yum..."
            sudo yum install -y postgresql 2>/dev/null && return 0
        elif command -v brew &>/dev/null; then
            log_info "Installing PostgreSQL client via brew..."
            brew install postgresql 2>/dev/null && return 0
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS: Use Homebrew
        if command -v brew &>/dev/null; then
            log_info "Installing PostgreSQL client via Homebrew (macOS)..."
            brew install postgresql 2>/dev/null && return 0
        fi
    fi

    log_error "Could not auto-install psql - please install manually from https://postgresql.org"
    return 1
}

# Attempt to download packages to cache before phase execution
# Usage: preflight_download_packages
preflight_download_packages() {
    local omniforge_root="${1:-}"

    if [[ -z "$omniforge_root" ]]; then
        return 0
    fi

    local cache_dir="${omniforge_root}/.download-cache"
    if [[ ! -d "$cache_dir" ]]; then
        return 0
    fi

    log_step "Pre-downloading packages to cache..."
    if command -v downloads_init &>/dev/null; then
        downloads_init
        log_ok "Package cache initialized"
        return 0
    else
        log_debug "downloads.sh not loaded, skipping package cache"
        return 0
    fi
}

# Check and remediate all critical missing dependencies
# Usage: preflight_remediate_missing
# Returns: 0 if all critical deps available, 1 if critical missing
preflight_remediate_missing() {
    local remediate="${PREFLIGHT_REMEDIATE:-false}"
    local skip_missing="${PREFLIGHT_SKIP_MISSING:-false}"
    local critical_missing=0

    if [[ "$remediate" != "true" ]]; then
        return 0
    fi

    log_info "Attempting to remediate missing dependencies..."
    echo ""

    # Critical dependency: pnpm
    if ! command -v pnpm &>/dev/null; then
        log_warn "pnpm not found - attempting installation..."
        if install_pnpm; then
            log_ok "pnpm remediation successful"
        else
            log_error "pnpm remediation failed"
            critical_missing=1
        fi
    fi

    # Critical dependency: Docker
    if ! command -v docker &>/dev/null; then
        log_warn "Docker not found - attempting installation..."
        if install_docker; then
            log_ok "Docker remediation successful"
        else
            log_warn "Docker remediation failed - will need manual installation"
            critical_missing=1
        fi
    fi

    # Critical dependency: psql (PostgreSQL client)
    if ! command -v psql &>/dev/null; then
        log_warn "psql (PostgreSQL client) not found - attempting installation..."
        if install_psql; then
            log_ok "psql remediation successful"
        else
            log_warn "psql remediation failed - will need manual installation"
            critical_missing=1
        fi
    fi

    # Pre-download packages if possible
    preflight_download_packages "${OMNIFORGE_ROOT:-}"

    if [[ "$skip_missing" == "true" ]] && [[ $critical_missing -eq 1 ]]; then
        log_warn "Critical dependencies still missing but continuing (PREFLIGHT_SKIP_MISSING=true)"
        return 0
    fi

    return $critical_missing
}
