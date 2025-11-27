#!/usr/bin/env bash
#!meta
# id: env/rate-limiter.sh
# name: rate-limiter
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
#   packages: []
#   dev_packages: []
#!endmeta

# =============================================================================
# env/rate-limiter.sh - Rate Limiting Utilities
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Phase: 1 (Infrastructure)
# Purpose: Create rate limiting utilities for API routes
#
# Creates:
#   - src/lib/rate-limit.ts (rate limiter implementation)
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

readonly SCRIPT_ID="env/rate-limiter"
readonly SCRIPT_NAME="Rate Limiter"

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

# Create rate limiter
if [[ ! -f "${SRC_LIB_DIR:-src/lib}/rate-limit.ts" ]]; then
    cat > "${SRC_LIB_DIR:-src/lib}/rate-limit.ts" << 'EOF'
/**
 * In-Memory Rate Limiter
 * Simple rate limiting for API routes (use Redis in production for multi-instance)
 */

interface RateLimitEntry {
  count: number;
  resetAt: number;
}

const rateLimitStore = new Map<string, RateLimitEntry>();

interface RateLimitConfig {
  /** Maximum requests allowed in window */
  limit: number;
  /** Window duration in milliseconds */
  windowMs: number;
}

const DEFAULT_CONFIG: RateLimitConfig = {
  limit: 100,
  windowMs: 60 * 1000, // 1 minute
};

/**
 * Check if request should be rate limited
 * @param key Unique identifier (e.g., IP address, user ID)
 * @param config Rate limit configuration
 * @returns Object with allowed status and remaining requests
 */
export function rateLimit(
  key: string,
  config: Partial<RateLimitConfig> = {}
): { allowed: boolean; remaining: number; resetAt: Date } {
  const { limit, windowMs } = { ...DEFAULT_CONFIG, ...config };
  const now = Date.now();

  const entry = rateLimitStore.get(key);

  // Clean up expired entry
  if (entry && entry.resetAt < now) {
    rateLimitStore.delete(key);
  }

  const current = rateLimitStore.get(key);

  if (!current) {
    // First request in window
    rateLimitStore.set(key, {
      count: 1,
      resetAt: now + windowMs,
    });
    return {
      allowed: true,
      remaining: limit - 1,
      resetAt: new Date(now + windowMs),
    };
  }

  if (current.count >= limit) {
    // Rate limited
    return {
      allowed: false,
      remaining: 0,
      resetAt: new Date(current.resetAt),
    };
  }

  // Increment count
  current.count++;
  return {
    allowed: true,
    remaining: limit - current.count,
    resetAt: new Date(current.resetAt),
  };
}

/**
 * Create rate limit headers for response
 */
export function rateLimitHeaders(result: ReturnType<typeof rateLimit>): HeadersInit {
  return {
    'X-RateLimit-Remaining': result.remaining.toString(),
    'X-RateLimit-Reset': result.resetAt.toISOString(),
  };
}

// Cleanup old entries periodically (every 5 minutes)
if (typeof setInterval !== 'undefined') {
  setInterval(() => {
    const now = Date.now();
    for (const [key, entry] of rateLimitStore.entries()) {
      if (entry.resetAt < now) {
        rateLimitStore.delete(key);
      }
    }
  }, 5 * 60 * 1000);
}
EOF
    log_ok "Created ${SRC_LIB_DIR:-src/lib}/rate-limit.ts"
else
    log_skip "rate-limit.ts already exists"
fi

mark_script_success "${SCRIPT_ID}"
log_ok "${SCRIPT_NAME} complete"
