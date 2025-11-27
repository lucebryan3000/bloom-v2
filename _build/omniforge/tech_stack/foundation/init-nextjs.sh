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
#   - APP_NAME
#   - APP_DESCRIPTION
#   - APP_VERSION
# uses_from_omni_settings:
#   - PROJECT_ROOT
#   - INSTALL_DIR
#   - NODE_VERSION
# top_flags:
# dependencies:
#   packages:
#     - next
#     - react
#     - react-dom
#     - typescript
#     - @types/node
#     - @types/react
#     - @types/react-dom
#   dev_packages:
#     - @types/node
#     - @types/react
#     - @types/react-dom
#     - typescript
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
if command -v parse_stack_flags >/dev/null 2>&1; then
    parse_stack_flags "$@"
fi

if [[ "${DRY_RUN:-false}" == "true" ]]; then
    echo "DRY_RUN: skipping init-nextjs (delegates to core/nextjs.sh)"
    exit 0
fi

exec "${TECH_STACK_DIR}/core/nextjs.sh" "$@"
