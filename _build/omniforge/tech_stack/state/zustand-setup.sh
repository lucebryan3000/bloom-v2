#!/usr/bin/env bash
# =============================================================================
# state/zustand-setup.sh - Zustand State Management Wrapper
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Phase: 2 (Core Features)
# Wraps: features/state.sh
#
# This script delegates to the consolidated features/state.sh implementation.
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TECH_STACK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Delegate to consolidated implementation
exec "${TECH_STACK_DIR}/features/state.sh" "$@"
