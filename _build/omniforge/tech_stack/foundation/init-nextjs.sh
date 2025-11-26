#!/usr/bin/env bash
#!meta
# id: foundation/init-nextjs.sh
# name: init-nextjs
# phase: 0
# phase_name: Project Foundation
# profile_tags:
#   - tech_stack
#   - foundation
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
# foundation/init-nextjs.sh - Initialize Next.js Project
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Phase: 0 (Foundation)
# Wraps: core/nextjs.sh
#
# This script delegates to the consolidated core/nextjs.sh implementation.
# =============================================================================
#
# Dependencies:
#   - delegates to core/nextjs (next, react, types)
#

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TECH_STACK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Delegate to consolidated implementation
exec "${TECH_STACK_DIR}/core/nextjs.sh" "$@"
