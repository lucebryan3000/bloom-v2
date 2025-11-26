#!/usr/bin/env bash
#!meta
# id: features/ai-sdk.sh
# name: sdk.sh - Vercel AI SDK Integration
# phase: 4
# phase_name: Extensions & Quality
# profile_tags:
#   - tech_stack
#   - features
# uses_from_omni_config:
# uses_from_omni_settings:
#   - PROJECT_ROOT
#   - SRC_LIB_DIR
# top_flags:
#   - --dry-run
#   - --skip-install
#   - --dev-only
#   - --no-dev
#   - --force
#   - --no-verify
# dependencies:
#   packages:
#     - ai-sdk-anthropic
#     - ai-sdk-openai
#     - vercel-ai
#   dev_packages:
#     -
#!endmeta


# =============================================================================
# tech_stack/features/ai-sdk.sh - Vercel AI SDK Integration
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Phase: Features
# Profile: advanced+
#
# Installs:
#   - ai (Vercel AI SDK)
#   - @ai-sdk/openai (OpenAI provider)
#   - @ai-sdk/anthropic (Anthropic provider)
#
# Dependencies:
#   - ai
#   - @ai-sdk/openai
#   - @ai-sdk/anthropic
#
# Creates:
#   - src/lib/ai.ts (provider configuration)
#   - Adds API keys to .env.example
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"
source "${SCRIPT_DIR}/../_lib/pkg-install.sh"

readonly SCRIPT_ID="features/ai-sdk"
readonly SCRIPT_NAME="Vercel AI SDK"

# =============================================================================
# PREFLIGHT
# =============================================================================

log_step "${SCRIPT_NAME} - Preflight"

# Check if already completed
if has_script_succeeded "${SCRIPT_ID}"; then
    log_skip "${SCRIPT_NAME} (already completed)"
    exit 0
fi

# Verify PROJECT_ROOT is set
if [[ -z "${PROJECT_ROOT:-}" ]]; then
    log_error "PROJECT_ROOT not set"
    exit 1
fi

# Verify project directory exists
if [[ ! -d "$INSTALL_DIR" ]]; then
    log_error "Project directory does not exist: $INSTALL_DIR"
    exit 1
fi

cd "$INSTALL_DIR"

# =============================================================================
# DEPENDENCY INSTALLATION
# =============================================================================

log_step "Installing Vercel AI SDK"

DEPS=("${PKG_VERCEL_AI}" "${PKG_AI_SDK_OPENAI}" "${PKG_AI_SDK_ANTHROPIC}")

# Show cache status
pkg_preflight_check "${DEPS[@]}"

# Install dependencies (with retry)
log_info "Installing AI SDK packages..."
if ! pkg_install_retry "${DEPS[@]}"; then
    log_error "Failed to install AI SDK packages"
    exit 1
fi

# Verify installation
log_info "Verifying installation..."
pkg_verify_all "${PKG_VERCEL_AI}" "${PKG_AI_SDK_OPENAI}" "${PKG_AI_SDK_ANTHROPIC}" || {
    log_error "Package verification failed"
    exit 1
}

log_ok "AI SDK installed"

# =============================================================================
# AI LIBRARY SETUP
# =============================================================================

log_step "Creating AI library"

mkdir -p "${SRC_LIB_DIR}"

if [[ ! -f "${SRC_LIB_DIR}/ai.ts" ]]; then
    cat > "${SRC_LIB_DIR}/ai.ts" <<'EOF'
import { createOpenAI } from '@ai-sdk/openai';
import { createAnthropic } from '@ai-sdk/anthropic';

// =============================================================================
// AI Provider Configuration
// =============================================================================

/**
 * OpenAI Provider
 * Models: gpt-4o, gpt-4o-mini, gpt-4-turbo, gpt-3.5-turbo
 */
export const openai = createOpenAI({
  apiKey: process.env.OPENAI_API_KEY,
  // Optional: Custom base URL for Azure OpenAI or proxies
  // baseURL: process.env.OPENAI_BASE_URL,
});

/**
 * Anthropic Provider
 * Models: claude-sonnet-4-20250514, claude-3-5-haiku-20241022
 */
export const anthropic = createAnthropic({
  apiKey: process.env.ANTHROPIC_API_KEY,
});

// =============================================================================
// Model Aliases
// =============================================================================

// Default models for different use cases
export const models = {
  // Fast, cost-effective
  fast: openai('gpt-4o-mini'),

  // Balanced performance
  balanced: openai('gpt-4o'),

  // Best quality (Claude)
  quality: anthropic('claude-sonnet-4-20250514'),

  // Fast Claude
  claudeFast: anthropic('claude-3-5-haiku-20241022'),
} as const;

// =============================================================================
// Type Exports
// =============================================================================

export type ModelKey = keyof typeof models;
EOF
    log_ok "Created ${SRC_LIB_DIR}/ai.ts"
else
    log_skip "${SRC_LIB_DIR}/ai.ts already exists"
fi

# =============================================================================
# ENVIRONMENT VARIABLES
# =============================================================================

log_step "Adding API keys to .env.example"

ENV_EXAMPLE=".env.example"

# Create or append to .env.example
if [[ ! -f "$ENV_EXAMPLE" ]]; then
    cat > "$ENV_EXAMPLE" <<'EOF'
# =============================================================================
# Environment Variables
# =============================================================================
# Copy this file to .env.local and fill in your values

# AI Provider API Keys
OPENAI_API_KEY=sk-your-openai-api-key
ANTHROPIC_API_KEY=sk-ant-your-anthropic-api-key
EOF
    log_ok "Created $ENV_EXAMPLE with AI keys"
else
    # Check if keys already exist
    if ! grep -q "OPENAI_API_KEY" "$ENV_EXAMPLE" 2>/dev/null; then
        cat >> "$ENV_EXAMPLE" <<'EOF'

# AI Provider API Keys
OPENAI_API_KEY=sk-your-openai-api-key
ANTHROPIC_API_KEY=sk-ant-your-anthropic-api-key
EOF
        log_ok "Added AI keys to $ENV_EXAMPLE"
    else
        log_skip "AI keys already in $ENV_EXAMPLE"
    fi
fi

# =============================================================================
# MARK SUCCESS
# =============================================================================

mark_script_success "${SCRIPT_ID}"
log_ok "${SCRIPT_NAME} complete"
