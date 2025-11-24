#!/usr/bin/env bash
# =============================================================================
# foundation/init-nextjs.sh - Initialize Next.js Project
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Phase: 0 (Foundation)
# Wraps: core/00-nextjs.sh
#
# This script delegates to the consolidated core/00-nextjs.sh implementation.
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TECH_STACK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Delegate to consolidated implementation
exec "${TECH_STACK_DIR}/core/00-nextjs.sh" "$@"
