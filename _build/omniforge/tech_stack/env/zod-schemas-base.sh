#!/usr/bin/env bash
#!meta
# id: env/zod-schemas-base.sh
# name: zod-schemas-base
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
# env/zod-schemas-base.sh - Base Zod Validation Schemas
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Phase: 1 (Infrastructure)
# Purpose: Create reusable Zod validation schemas
#
# Creates:
#   - src/lib/validations/index.ts (common schemas)
# =============================================================================
#
# Dependencies:
#   - zod
#

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"
if command -v parse_stack_flags >/dev/null 2>&1; then
    parse_stack_flags "$@"
fi

readonly SCRIPT_ID="env/zod-schemas-base"
readonly SCRIPT_NAME="Zod Base Schemas"

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

# Create validations directory
mkdir -p "${SRC_LIB_DIR:-src/lib}/validations"

# Create base schemas
if [[ ! -f "${SRC_LIB_DIR:-src/lib}/validations/index.ts" ]]; then
    cat > "${SRC_LIB_DIR:-src/lib}/validations/index.ts" << 'EOF'
/**
 * Reusable Zod Validation Schemas
 * Common patterns for form validation, API requests, etc.
 */

import { z } from 'zod';

// =============================================================================
// Primitives
// =============================================================================

/** Non-empty string */
export const nonEmptyString = z.string().min(1, 'Required');

/** Email address */
export const email = z.string().email('Invalid email address');

/** UUID */
export const uuid = z.string().uuid('Invalid UUID');

/** Positive integer */
export const positiveInt = z.coerce.number().int().positive();

/** Pagination */
export const paginationSchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

// =============================================================================
// Common Patterns
// =============================================================================

/** ID parameter (from URL params) */
export const idParam = z.object({
  id: uuid,
});

/** Search query */
export const searchSchema = z.object({
  q: z.string().optional(),
  ...paginationSchema.shape,
});

/** Date range */
export const dateRangeSchema = z.object({
  startDate: z.coerce.date().optional(),
  endDate: z.coerce.date().optional(),
}).refine(
  (data) => {
    if (data.startDate && data.endDate) {
      return data.startDate <= data.endDate;
    }
    return true;
  },
  { message: 'Start date must be before end date' }
);

// =============================================================================
// Type Exports
// =============================================================================

export type Pagination = z.infer<typeof paginationSchema>;
export type IdParam = z.infer<typeof idParam>;
export type SearchParams = z.infer<typeof searchSchema>;
export type DateRange = z.infer<typeof dateRangeSchema>;
EOF
    log_ok "Created ${SRC_LIB_DIR:-src/lib}/validations/index.ts"
else
    log_skip "validations/index.ts already exists"
fi

mark_script_success "${SCRIPT_ID}"
log_ok "${SCRIPT_NAME} complete"
