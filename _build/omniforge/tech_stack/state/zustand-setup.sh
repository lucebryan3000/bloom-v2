#!/usr/bin/env bash
#!meta
# id: state/zustand-setup.sh
# name: zustand-setup
# phase: 2
# phase_name: Core Features
# profile_tags:
#   - tech_stack
#   - state
# uses_from_omni_config:
# uses_from_omni_settings:
#   - TECH_STACK_DIR
# top_flags:
#   - --dry-run
#   - --skip-install
#   - --dev-only
#   - --no-dev
#   - --force
#   - --no-verify
# dependencies:
#   packages:
#     -
#   dev_packages:
#     -
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
TECH_STACK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Delegate to consolidated implementation
exec "${TECH_STACK_DIR}/features/state.sh" "$@"
