#!/usr/bin/env bash
# =============================================================================
# tools/test-local-tools.sh - Test Local Prerequisites Installation
# =============================================================================
# Quick test script to verify project-local Node.js/pnpm setup

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source common library
source "${SCRIPTS_DIR}/lib/common.sh"

# Load configuration
config_load

echo "========================================"
echo "  OmniForge - Local Tools Test"
echo "========================================"
echo ""

# Show current status
prereqs_local_status

echo ""
echo "========================================"
echo "  Testing Installation"
echo "========================================"
echo ""

# Test Node.js installation
if prereqs_local_node_exists; then
    echo "✓ Local Node.js found"
    echo "  Version: $(prereqs_local_node_version)"
    echo "  Path: ${NODE_LOCAL_BIN}"
else
    echo "✗ Local Node.js not found"
    echo "  Installing..."
    if prereqs_local_install_node; then
        echo "  ✓ Installation successful"
    else
        echo "  ✗ Installation failed"
        exit 1
    fi
fi

echo ""

# Test pnpm installation
if prereqs_local_pnpm_exists; then
    echo "✓ Local pnpm found"
    echo "  Version: $(prereqs_local_pnpm_version)"
    echo "  Path: ${PNPM_LOCAL_BIN}"
else
    echo "✗ Local pnpm not found"
    echo "  Installing..."
    if prereqs_local_install_pnpm; then
        echo "  ✓ Installation successful"
    else
        echo "  ✗ Installation failed"
        exit 1
    fi
fi

echo ""
echo "========================================"
echo "  Activation Script"
echo "========================================"
echo ""

if [[ -f "${TOOLS_ACTIVATE_SCRIPT}" ]]; then
    echo "✓ Activation script exists: ${TOOLS_ACTIVATE_SCRIPT}"
    echo ""
    echo "To use local tools in your shell:"
    echo "  source .toolsrc"
else
    echo "✗ Activation script not found"
    echo "  Creating..."
    prereqs_local_create_activate_script
fi

echo ""
echo "========================================"
echo "  Test Complete"
echo "========================================"
