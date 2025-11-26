#!/usr/bin/env bash
#!meta
# id: ui/shadcn-init.sh
# name: init.sh - shadcn/ui Initialization Wrapper
# phase: 3
# phase_name: User Interface
# profile_tags:
#   - tech_stack
#   - ui
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

# Delegate to core UI script which handles full shadcn/ui + Tailwind setup
exec "${SCRIPT_DIR}/../core/ui.sh"
