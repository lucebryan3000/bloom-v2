#!/usr/bin/env bash
#!meta
# id: quality/eslint-prettier.sh
# name: prettier.sh - ESLint + Prettier Wrapper
# phase: 4
# phase_name: Extensions & Quality
# profile_tags:
#   - tech_stack
#   - quality
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

# Delegate to the main code-quality script
exec "${SCRIPT_DIR}/../features/code-quality.sh"
