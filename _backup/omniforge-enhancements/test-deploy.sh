#!/usr/bin/env bash
# =============================================================================
# test-deploy.sh - Isolated Test Deployment Wrapper
# =============================================================================
# Workaround for INSTALL_DIR bug (see INSTALL-DIR-ISSUE.md)
# Creates isolated test environment instead of installing to project root
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_ok() { echo -e "${GREEN}[OK]${NC} ✓ $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

# =============================================================================
# Configuration
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OMNIFORGE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROJECT_ROOT="$(cd "${OMNIFORGE_ROOT}/../.." && pwd)"

# Test directory can be specified or auto-generated
TEST_DIR="${1:-${PROJECT_ROOT}/test/install-$(date +%s)}"

# =============================================================================
# Validation
# =============================================================================

log_info "OmniForge Test Deployment"
echo ""
log_info "Source: ${OMNIFORGE_ROOT}"
log_info "Target: ${TEST_DIR}"
echo ""

# Check if OmniForge exists
if [[ ! -f "${OMNIFORGE_ROOT}/omni.sh" ]]; then
    log_error "OmniForge not found at: ${OMNIFORGE_ROOT}"
    log_error "Run this script from within an OmniForge project"
    exit 1
fi

# Warn if test directory exists
if [[ -d "${TEST_DIR}" ]]; then
    log_warn "Test directory already exists: ${TEST_DIR}"
    read -rp "Delete and recreate? [y/N] " response
    if [[ "${response}" =~ ^[Yy]$ ]]; then
        log_info "Removing existing test directory..."
        rm -rf "${TEST_DIR}"
    else
        log_error "Aborted by user"
        exit 1
    fi
fi

# =============================================================================
# Create Isolated Test Environment
# =============================================================================

log_info "Creating test environment..."

# Create test directory structure
mkdir -p "${TEST_DIR}/_build"

# Copy OmniForge system
log_info "Copying OmniForge system..."
cp -r "${OMNIFORGE_ROOT}" "${TEST_DIR}/_build/omniforge"

# Copy .claude if it exists (for Claude Code integration)
if [[ -d "${PROJECT_ROOT}/.claude" ]]; then
    log_info "Copying .claude configuration..."
    cp -r "${PROJECT_ROOT}/.claude" "${TEST_DIR}/.claude"
fi

# Initialize git if not already a repo
if [[ ! -d "${TEST_DIR}/.git" ]]; then
    log_info "Initializing git repository..."
    cd "${TEST_DIR}"
    git init -q
    git config user.name "OmniForge Test"
    git config user.email "test@omniforge.local"
fi

log_ok "Test environment created"

# =============================================================================
# Run OmniForge Initialization
# =============================================================================

log_info "Running OmniForge initialization..."
echo ""

cd "${TEST_DIR}"

# Run omni.sh with all output visible
if ./_build/omniforge/omni.sh --init; then
    log_ok "OmniForge initialization complete"
else
    log_error "OmniForge initialization failed"
    log_error "Test directory preserved for debugging: ${TEST_DIR}"
    exit 1
fi

# =============================================================================
# Post-Deployment Summary
# =============================================================================

echo ""
echo "═══════════════════════════════════════════════════════════════"
log_ok "Test Deployment Complete"
echo "═══════════════════════════════════════════════════════════════"
echo ""
log_info "Test Directory: ${TEST_DIR}"
log_info "Files Created:"
find "${TEST_DIR}" -type f -not -path "*/node_modules/*" -not -path "*/.git/*" -not -path "*/.next/*" | wc -l | xargs echo "  "
echo ""
log_info "Next Steps:"
echo "  1. Test the deployment:"
echo "     cd ${TEST_DIR}"
echo "     pnpm dev"
echo ""
echo "  2. Review build verification:"
echo "     cat ${TEST_DIR}/logs/verification-report.md"
echo ""
echo "  3. Run tests:"
echo "     cd ${TEST_DIR}"
echo "     pnpm test"
echo "     pnpm test:e2e"
echo ""
echo "  4. Clean up when done:"
echo "     rm -rf ${TEST_DIR}"
echo ""
log_info "To create another test deployment:"
echo "  ${SCRIPT_DIR}/test-deploy.sh"
echo ""
echo "═══════════════════════════════════════════════════════════════"
