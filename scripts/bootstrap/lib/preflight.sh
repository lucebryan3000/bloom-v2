#!/usr/bin/env bash
# =============================================================================
# preflight.sh - Pre-flight validation checks before running bootstrap
# =============================================================================
# Validates all prerequisites before bootstrap execution begins
# =============================================================================

set -euo pipefail

# Color codes (will be disabled if not a terminal)
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' NC=''
fi

# Counters
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNED=0

# =============================================================================
# Check Functions
# =============================================================================

check_pass() {
    local msg="$1"
    echo -e "${GREEN}✓${NC} ${msg}"
    ((CHECKS_PASSED++))
}

check_fail() {
    local msg="$1"
    local hint="${2:-}"
    echo -e "${RED}✗${NC} ${msg}"
    [[ -n "${hint}" ]] && echo -e "  ${YELLOW}Hint: ${hint}${NC}"
    ((CHECKS_FAILED++))
}

check_warn() {
    local msg="$1"
    local hint="${2:-}"
    echo -e "${YELLOW}!${NC} ${msg}"
    [[ -n "${hint}" ]] && echo -e "  ${YELLOW}Hint: ${hint}${NC}"
    ((CHECKS_WARNED++))
}

check_info() {
    local msg="$1"
    echo -e "${BLUE}i${NC} ${msg}"
}

# =============================================================================
# Node.js Checks
# =============================================================================

check_node() {
    echo ""
    echo "=== Node.js Environment ==="

    # Check Node.js installed
    if ! command -v node &>/dev/null; then
        check_fail "Node.js not found" "Install Node.js 20.x LTS from https://nodejs.org"
        return 1
    fi

    local node_version
    node_version=$(node -v | sed 's/v//')
    local node_major
    node_major=$(echo "${node_version}" | cut -d. -f1)

    if [[ "${node_major}" -ge 20 ]]; then
        check_pass "Node.js ${node_version} installed (>= 20 required)"
    elif [[ "${node_major}" -ge 18 ]]; then
        check_warn "Node.js ${node_version} installed (20.x recommended)" "Consider upgrading for full Next.js 15 support"
    else
        check_fail "Node.js ${node_version} too old" "Upgrade to Node.js 20.x LTS"
    fi

    # Check npm
    if command -v npm &>/dev/null; then
        local npm_version
        npm_version=$(npm -v)
        check_pass "npm ${npm_version} available"
    fi
}

check_pnpm() {
    # Check pnpm installed
    if ! command -v pnpm &>/dev/null; then
        check_fail "pnpm not found" "Install with: npm install -g pnpm"
        return 1
    fi

    local pnpm_version
    pnpm_version=$(pnpm -v)
    local pnpm_major
    pnpm_major=$(echo "${pnpm_version}" | cut -d. -f1)

    if [[ "${pnpm_major}" -ge 9 ]]; then
        check_pass "pnpm ${pnpm_version} installed (>= 9 required)"
    elif [[ "${pnpm_major}" -ge 8 ]]; then
        check_warn "pnpm ${pnpm_version} installed (9.x recommended)" "Upgrade with: npm install -g pnpm@latest"
    else
        check_fail "pnpm ${pnpm_version} too old" "Upgrade with: npm install -g pnpm@latest"
    fi
}

# =============================================================================
# Docker Checks
# =============================================================================

check_docker() {
    echo ""
    echo "=== Docker Environment ==="

    # Check Docker installed
    if ! command -v docker &>/dev/null; then
        check_warn "Docker not found" "Install Docker for PostgreSQL container support"
        return 0
    fi

    local docker_version
    docker_version=$(docker --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    check_pass "Docker ${docker_version} installed"

    # Check Docker daemon running
    if docker info &>/dev/null; then
        check_pass "Docker daemon is running"
    else
        check_fail "Docker daemon not running" "Start Docker Desktop or run: sudo systemctl start docker"
    fi

    # Check Docker Compose
    if docker compose version &>/dev/null; then
        local compose_version
        compose_version=$(docker compose version --short 2>/dev/null || echo "unknown")
        check_pass "Docker Compose ${compose_version} available"
    elif command -v docker-compose &>/dev/null; then
        check_warn "Legacy docker-compose found" "Consider upgrading to Docker Compose V2"
    else
        check_warn "Docker Compose not found" "PostgreSQL container setup may require manual configuration"
    fi
}

# =============================================================================
# Git Checks
# =============================================================================

check_git() {
    echo ""
    echo "=== Git Environment ==="

    if ! command -v git &>/dev/null; then
        check_fail "Git not found" "Install git for version control"
        return 1
    fi

    local git_version
    git_version=$(git --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
    check_pass "Git ${git_version} installed"

    # Check if in a git repo
    if git rev-parse --git-dir &>/dev/null; then
        check_pass "Inside a git repository"

        # Check for uncommitted changes
        if git diff-index --quiet HEAD -- 2>/dev/null; then
            check_pass "Working directory clean"
        else
            check_warn "Uncommitted changes detected" "Consider committing or stashing before bootstrap"
        fi
    else
        check_warn "Not in a git repository" "Run: git init"
    fi
}

# =============================================================================
# Directory Checks
# =============================================================================

check_directory() {
    echo ""
    echo "=== Project Directory ==="

    local cwd
    cwd=$(pwd)
    check_info "Working directory: ${cwd}"

    # Check for existing src directory
    if [[ -d "src" ]]; then
        check_warn "src/ directory already exists" "Bootstrap may overwrite existing files"
    else
        check_pass "No existing src/ directory (clean slate)"
    fi

    # Check for existing package.json
    if [[ -f "package.json" ]]; then
        check_warn "package.json already exists" "Bootstrap may modify or conflict with existing config"
    else
        check_pass "No existing package.json (fresh project)"
    fi

    # Check for existing .env
    if [[ -f ".env" ]]; then
        check_pass ".env file exists"
    else
        check_info "No .env file (will be created from template)"
    fi

    # Check disk space
    local free_space
    free_space=$(df -BG . | awk 'NR==2 {print $4}' | tr -d 'G')
    if [[ "${free_space}" -ge 5 ]]; then
        check_pass "Sufficient disk space (${free_space}GB free)"
    elif [[ "${free_space}" -ge 2 ]]; then
        check_warn "Low disk space (${free_space}GB free)" "Bootstrap requires ~2GB for node_modules"
    else
        check_fail "Insufficient disk space (${free_space}GB free)" "Free up at least 2GB"
    fi
}

# =============================================================================
# Network Checks
# =============================================================================

check_network() {
    echo ""
    echo "=== Network Connectivity ==="

    # Check npm registry
    if curl -s --max-time 5 https://registry.npmjs.org/ &>/dev/null; then
        check_pass "npm registry accessible"
    else
        check_warn "Cannot reach npm registry" "Check your internet connection"
    fi

    # Check GitHub (for some dependencies)
    if curl -s --max-time 5 https://github.com &>/dev/null; then
        check_pass "GitHub accessible"
    else
        check_warn "Cannot reach GitHub" "Some git-based dependencies may fail"
    fi
}

# =============================================================================
# Optional Tool Checks
# =============================================================================

check_optional_tools() {
    echo ""
    echo "=== Optional Tools ==="

    # PostgreSQL client
    if command -v psql &>/dev/null; then
        local psql_version
        psql_version=$(psql --version | grep -oE '[0-9]+\.[0-9]+')
        check_pass "psql ${psql_version} available (database debugging)"
    else
        check_info "psql not found (optional, for database debugging)"
    fi

    # curl
    if command -v curl &>/dev/null; then
        check_pass "curl available"
    else
        check_info "curl not found (optional)"
    fi

    # jq
    if command -v jq &>/dev/null; then
        check_pass "jq available (JSON processing)"
    else
        check_info "jq not found (optional, for JSON processing)"
    fi
}

# =============================================================================
# Bootstrap Scripts Check
# =============================================================================

check_bootstrap_scripts() {
    echo ""
    echo "=== Bootstrap Scripts ==="

    local script_dir
    script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

    # Check common.sh
    if [[ -f "${script_dir}/lib/common.sh" ]]; then
        check_pass "lib/common.sh found"
    else
        check_fail "lib/common.sh missing" "Bootstrap scripts incomplete"
    fi

    # Check config files
    for conf in defaults.conf phases.conf breakpoints.conf; do
        if [[ -f "${script_dir}/config/${conf}" ]]; then
            check_pass "config/${conf} found"
        else
            check_warn "config/${conf} missing" "Using default configuration"
        fi
    done

    # Count available scripts
    local script_count
    script_count=$(find "${script_dir}" -name "*.sh" -type f | wc -l)
    check_info "${script_count} bootstrap scripts found"
}

# =============================================================================
# Main Preflight Function
# =============================================================================

run_preflight() {
    local strict="${1:-false}"

    echo "=============================================="
    echo "  Bootstrap Pre-flight Checks"
    echo "=============================================="

    check_node
    check_pnpm
    check_docker
    check_git
    check_directory
    check_network
    check_optional_tools
    check_bootstrap_scripts

    echo ""
    echo "=============================================="
    echo "  Summary"
    echo "=============================================="
    echo -e "${GREEN}Passed:${NC}  ${CHECKS_PASSED}"
    echo -e "${YELLOW}Warnings:${NC} ${CHECKS_WARNED}"
    echo -e "${RED}Failed:${NC}  ${CHECKS_FAILED}"
    echo ""

    if [[ "${CHECKS_FAILED}" -gt 0 ]]; then
        echo -e "${RED}Pre-flight check failed!${NC}"
        echo "Please resolve the failed checks before continuing."

        if [[ "${strict}" == "true" ]]; then
            return 1
        else
            echo ""
            echo "Continue anyway? (not recommended) [y/N]"
            read -r response
            if [[ ! "${response}" =~ ^[Yy]$ ]]; then
                return 1
            fi
        fi
    elif [[ "${CHECKS_WARNED}" -gt 0 ]]; then
        echo -e "${YELLOW}Pre-flight check passed with warnings.${NC}"
        echo "Review warnings above before continuing."
    else
        echo -e "${GREEN}All pre-flight checks passed!${NC}"
    fi

    return 0
}

# =============================================================================
# Main (for standalone execution)
# =============================================================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_preflight "${1:-false}"
fi
