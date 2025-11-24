#!/usr/bin/env bash
# =============================================================================
# tech_stack/testing/vitest-setup.sh - Vitest Setup Wrapper
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Phase: 4 (Extensions & Quality)
# Purpose: Wrapper that delegates to features/testing.sh for Vitest setup
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Delegate to the main testing script
exec "${SCRIPT_DIR}/../features/testing.sh"
