#!/usr/bin/env bash
#!meta
# id: ai/vercel-ai-setup.sh
# name: vercel ai setup
# phase: 3
# phase_name: User Interface
# profile_tags:
#   - tech_stack
#   - ai
# uses_from_omni_config:
#   - ENABLE_AI_SDK
# uses_from_omni_settings:
#   - PROJECT_ROOT
#   - INSTALL_DIR
# top_flags:
# dependencies:
#   packages: []
#   dev_packages: []
#!endmeta

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
#
# Dependencies:
#   - delegates to features/ai-sdk (ai, @ai-sdk/openai, @ai-sdk/anthropic)
#

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"
if command -v parse_stack_flags >/dev/null 2>&1; then
    parse_stack_flags "$@"
fi

readonly SCRIPT_ID="ai/vercel-ai-setup"
readonly SCRIPT_NAME="Vercel AI SDK Setup"

if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_skip "DRY_RUN: skipping ${SCRIPT_NAME}"
    exit 0
fi

# Check if already completed
if has_script_succeeded "${SCRIPT_ID}"; then
    log_skip "${SCRIPT_NAME} (already completed)"
    exit 0
fi

log_step "${SCRIPT_NAME}"

# Delegate to features implementation
exec "${SCRIPT_DIR}/../features/ai-sdk.sh"