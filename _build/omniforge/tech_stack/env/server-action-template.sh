#!/usr/bin/env bash
#!meta
# id: env/server-action-template.sh
# name: server-action-template
# phase: 1
# phase_name: Infrastructure & Database
# profile_tags:
#   - tech_stack
#   - env
# uses_from_omni_config:
# uses_from_omni_settings:
#   - PROJECT_ROOT
#   - INSTALL_DIR
#   - SRC_LIB_DIR
# required_vars:
#   - PROJECT_ROOT
#   - INSTALL_DIR
#   - SRC_LIB_DIR
# top_flags:
# dependencies:
#   packages:
#     - zod
#   dev_packages: []
#!endmeta

# =============================================================================
# env/server-action-template.sh - Server Action Utilities
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Phase: 1 (Infrastructure)
# Purpose: Create server action patterns and utilities
#
# Creates:
#   - src/lib/actions.ts (server action utilities)
# =============================================================================
#
# Dependencies:
#   - none
#

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"
if command -v parse_stack_flags >/dev/null 2>&1; then
    parse_stack_flags "$@"
fi

readonly SCRIPT_ID="env/server-action-template"
readonly SCRIPT_NAME="Server Action Template"

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

: "${PROJECT_ROOT:?PROJECT_ROOT not set}"
cd "$INSTALL_DIR"

mkdir -p "${SRC_LIB_DIR:-src/lib}"

# Create server action utilities
if [[ ! -f "${SRC_LIB_DIR:-src/lib}/actions.ts" ]]; then
    cat > "${SRC_LIB_DIR:-src/lib}/actions.ts" << 'EOF'
/**
 * Server Action Utilities
 * Type-safe patterns for Next.js Server Actions
 */

import { z } from 'zod';

// =============================================================================
// Types
// =============================================================================

/** Standard action result shape */
export type ActionResult<T = void> =
  | { success: true; data: T }
  | { success: false; error: string; fieldErrors?: Record<string, string[]> };

/** Action handler function type */
export type ActionHandler<TInput, TOutput> = (
  input: TInput
) => Promise<ActionResult<TOutput>>;

// =============================================================================
// Utilities
// =============================================================================

/**
 * Create a validated server action
 * Wraps action with Zod validation and error handling
 */
export function createAction<TInput, TOutput>(
  schema: z.ZodSchema<TInput>,
  handler: (validatedInput: TInput) => Promise<TOutput>
): ActionHandler<TInput, TOutput> {
  return async (input: TInput): Promise<ActionResult<TOutput>> => {
    try {
      // Validate input
      const result = schema.safeParse(input);

      if (!result.success) {
        return {
          success: false,
          error: 'Validation failed',
          fieldErrors: result.error.flatten().fieldErrors as Record<string, string[]>,
        };
      }

      // Execute handler
      const data = await handler(result.data);

      return { success: true, data };
    } catch (error) {
      console.error('Action error:', error);

      return {
        success: false,
        error: error instanceof Error ? error.message : 'An unexpected error occurred',
      };
    }
  };
}

/**
 * Success result helper
 */
export function success<T>(data: T): ActionResult<T> {
  return { success: true, data };
}

/**
 * Error result helper
 */
export function error(message: string, fieldErrors?: Record<string, string[]>): ActionResult<never> {
  return { success: false, error: message, fieldErrors };
}
EOF
    log_ok "Created ${SRC_LIB_DIR:-src/lib}/actions.ts"
else
    log_skip "actions.ts already exists"
fi

mark_script_success "${SCRIPT_ID}"
log_ok "${SCRIPT_NAME} complete"
