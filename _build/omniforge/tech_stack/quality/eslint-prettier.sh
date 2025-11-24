#!/usr/bin/env bash
# =============================================================================
# tech_stack/quality/eslint-prettier.sh - ESLint + Prettier Wrapper
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Phase: 4 (Extensions & Quality)
# Purpose: Wrapper that delegates to features/code-quality.sh for ESLint + Prettier setup
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Delegate to the main code-quality script
exec "${SCRIPT_DIR}/../features/code-quality.sh"
