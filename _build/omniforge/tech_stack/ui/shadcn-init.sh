#!/usr/bin/env bash
# =============================================================================
# tech_stack/ui/shadcn-init.sh - shadcn/ui Initialization Wrapper
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Phase: 3 (User Interface)
# Purpose: Delegates shadcn/ui setup to core/ui.sh for centralized management
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Delegate to core UI script which handles full shadcn/ui + Tailwind setup
exec "${SCRIPT_DIR}/../core/ui.sh"
