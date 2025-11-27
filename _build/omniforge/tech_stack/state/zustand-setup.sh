#!/usr/bin/env bash
#!meta
# id: state/zustand-setup.sh
# name: zustand setup
# phase: 2
# phase_name: Core Features
# profile_tags:
#   - tech_stack
#   - state
# uses_from_omni_config:
#   - ENABLE_ZUSTAND
# uses_from_omni_settings:
#   - PROJECT_ROOT
#   - INSTALL_DIR
#   - TECH_STACK_DIR
# required_vars:
#   - PROJECT_ROOT
#   - INSTALL_DIR
#   - TECH_STACK_DIR
# top_flags:
# dependencies:
#   packages: []
#   dev_packages: []
#!endmeta

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
#
# Dependencies:
#   - delegates to features/state (zustand)
#

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if command -v parse_stack_flags >/dev/null 2>&1; then
    parse_stack_flags "$@"
fi

if [[ "${DRY_RUN:-false}" == "true" ]]; then
    echo "DRY_RUN: skipping zustand setup (delegates to features/state.sh)"
    exit 0
fi

TECH_STACK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Delegate to consolidated implementation
exec "${TECH_STACK_DIR}/features/state.sh" "$@"
