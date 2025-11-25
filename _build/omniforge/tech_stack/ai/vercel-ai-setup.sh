#!/usr/bin/env bash
# =============================================================================
# tech_stack/ai/vercel-ai-setup.sh - Vercel AI SDK Setup Wrapper
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Phase: 3
# Purpose: Wrapper script that delegates Vercel AI SDK setup to features/ai-sdk.sh
# =============================================================================
# Contract:
#   Inputs: PROJECT_ROOT, ENABLE_AI_SDK, API key env placeholders
#   Outputs: Delegates to features/ai-sdk.sh (env example updates, AI scaffolding)
#   Runtime: Runs during bootstrap when AI stack enabled
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"

readonly SCRIPT_ID="ai/vercel-ai-setup"
readonly SCRIPT_NAME="Vercel AI SDK Setup"

# Check if already completed
if has_script_succeeded "${SCRIPT_ID}"; then
    log_skip "${SCRIPT_NAME} (already completed)"
    exit 0
fi

log_step "${SCRIPT_NAME}"

# Delegate to features implementation
exec "${SCRIPT_DIR}/../features/ai-sdk.sh"
