#!/usr/bin/env bash
#!meta
# id: quality/eslint-prettier.sh
# name: eslint prettier
# phase: 4
# phase_name: Extensions & Quality
# profile_tags:
#   - tech_stack
#   - quality
# uses_from_omni_config:
#   - ENABLE_CODE_QUALITY
# uses_from_omni_settings:
#   - PROJECT_ROOT
#   - INSTALL_DIR
# required_vars:
#   - PROJECT_ROOT
#   - INSTALL_DIR
# top_flags:
# dependencies:
#   packages:
#     - eslint
#     - prettier
#     - @typescript-eslint/eslint-plugin
#     - @typescript-eslint/parser
#     - eslint-config-prettier
#     - eslint-plugin-jsx-a11y
#   dev_packages: []
#!endmeta

# =============================================================================
# tech_stack/quality/eslint-prettier.sh - ESLint + Prettier Wrapper
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Phase: 4 (Extensions & Quality)
# Purpose: Wrapper that delegates to features/code-quality.sh for ESLint + Prettier setup
# =============================================================================
#
# Dependencies:
#   - delegates to features/code-quality (eslint, prettier, lint-staged, husky, typescript-eslint)
#

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if command -v parse_stack_flags >/dev/null 2>&1; then
    parse_stack_flags "$@"
fi

if [[ "${DRY_RUN:-false}" == "true" ]]; then
    echo "DRY_RUN: skipping ESLint+Prettier (delegates to features/code-quality.sh)"
    exit 0
fi

# Delegate to the main code-quality script
exec "${SCRIPT_DIR}/../features/code-quality.sh"
