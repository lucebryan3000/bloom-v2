#!/usr/bin/env bash
#!meta
# id: testing/vitest-setup.sh
# name: setup.sh - Vitest Setup Wrapper
# phase: 4
# phase_name: Extensions & Quality
# profile_tags:
#   - tech_stack
#   - testing
# uses_from_omni_config:
# uses_from_omni_settings:
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
# tech_stack/testing/vitest-setup.sh - Vitest Setup Wrapper
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Phase: 4 (Extensions & Quality)
# Purpose: Wrapper that delegates to features/testing.sh for Vitest setup
# =============================================================================
#
# Dependencies:
#   - delegates to features/testing (vitest, @testing-library/react, playwright, @playwright/test)
#

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Delegate to the main testing script
exec "${SCRIPT_DIR}/../features/testing.sh"
