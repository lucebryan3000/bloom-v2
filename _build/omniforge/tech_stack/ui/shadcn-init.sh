#!/usr/bin/env bash
#!meta
# id: ui/shadcn-init.sh
# name: shadcn init
# phase: 3
# phase_name: User Interface
# profile_tags:
#   - tech_stack
#   - ui
# uses_from_omni_config:
#   - ENABLE_SHADCN
# uses_from_omni_settings:
#   - PROJECT_ROOT
#   - INSTALL_DIR
# required_vars:
#   - PROJECT_ROOT
#   - INSTALL_DIR
# top_flags:
# dependencies:
#   packages:
#     - lucide-react
#     - clsx
#     - tailwind-merge
#     - class-variance-authority
#     - react-to-print
#   dev_packages:
#     - tailwindcss
#     - postcss
#     - autoprefixer
#!endmeta

# =============================================================================
# tech_stack/ui/shadcn-init.sh - shadcn/ui Initialization Wrapper
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Phase: 3 (User Interface)
# Purpose: Delegates shadcn/ui setup to core/ui.sh for centralized management
# =============================================================================
#
# Dependencies:
#   - delegates to core/ui (tailwindcss + shadcn stack)
#

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if command -v parse_stack_flags >/dev/null 2>&1; then
    parse_stack_flags "$@"
fi

if [[ "${DRY_RUN:-false}" == "true" ]]; then
    echo "DRY_RUN: skipping shadcn/ui init (delegates to core/ui.sh)"
    exit 0
fi

# Delegate to core UI script which handles full shadcn/ui + Tailwind setup
exec "${SCRIPT_DIR}/../core/ui.sh"
