#!/usr/bin/env bash
#!meta
# id: testing/vitest-setup.sh
# name: vitest setup
# phase: 4
# phase_name: Extensions & Quality
# profile_tags:
#   - tech_stack
#   - testing
# uses_from_omni_config:
#   - ENABLE_TEST_INFRA
# uses_from_omni_settings:
#   - PROJECT_ROOT
#   - INSTALL_DIR
#   - SRC_TEST_DIR
#   - E2E_DIR
# top_flags:
# dependencies:
#   packages:
#     - vitest
#     - @testing-library/react
#     - @testing-library/jest-dom
#     - @testing-library/user-event
#     - jsdom
#   dev_packages: []
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
if command -v parse_stack_flags >/dev/null 2>&1; then
    parse_stack_flags "$@"
fi

if [[ "${DRY_RUN:-false}" == "true" ]]; then
    echo "DRY_RUN: skipping Vitest setup (delegates to features/testing.sh)"
    exit 0
fi

# Delegate to the main testing script
exec "${SCRIPT_DIR}/../features/testing.sh"
