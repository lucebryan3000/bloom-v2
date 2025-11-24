#!/usr/bin/env bash
# =============================================================================
# test-cleanup.sh - Clean Up Test Deployments
# =============================================================================
# Removes test deployment directories created by test-deploy.sh
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_ok() { echo -e "${GREEN}[OK]${NC} ✓ $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
TEST_BASE_DIR="${PROJECT_ROOT}/test"

# =============================================================================
# Find Test Deployments
# =============================================================================

log_info "Searching for test deployments in: ${TEST_BASE_DIR}"
echo ""

if [[ ! -d "${TEST_BASE_DIR}" ]]; then
    log_warn "No test directory found"
    exit 0
fi

# Find all install-* directories
TEST_DIRS=()
while IFS= read -r -d '' dir; do
    TEST_DIRS+=("$dir")
done < <(find "${TEST_BASE_DIR}" -maxdepth 1 -type d -name "install-*" -print0 2>/dev/null)

if [[ ${#TEST_DIRS[@]} -eq 0 ]]; then
    log_warn "No test deployments found"
    exit 0
fi

# =============================================================================
# List and Confirm
# =============================================================================

log_info "Found ${#TEST_DIRS[@]} test deployment(s):"
echo ""

for dir in "${TEST_DIRS[@]}"; do
    size=$(du -sh "$dir" 2>/dev/null | cut -f1)
    age=$(stat -c %y "$dir" 2>/dev/null | cut -d' ' -f1,2 | cut -d'.' -f1)
    echo "  • $(basename "$dir")"
    echo "    Size: ${size}"
    echo "    Created: ${age}"
    echo "    Path: ${dir}"
    echo ""
done

# Confirm deletion
read -rp "Delete all test deployments? [y/N] " response
if [[ ! "${response}" =~ ^[Yy]$ ]]; then
    log_info "Cancelled by user"
    exit 0
fi

# =============================================================================
# Delete Test Deployments
# =============================================================================

log_info "Removing test deployments..."

for dir in "${TEST_DIRS[@]}"; do
    log_info "Removing: $(basename "$dir")"
    rm -rf "$dir"
done

log_ok "Removed ${#TEST_DIRS[@]} test deployment(s)"

# Check if test directory is now empty
if [[ -d "${TEST_BASE_DIR}" ]] && [[ -z "$(ls -A "${TEST_BASE_DIR}")" ]]; then
    log_info "Removing empty test directory"
    rmdir "${TEST_BASE_DIR}"
fi

log_ok "Cleanup complete"
