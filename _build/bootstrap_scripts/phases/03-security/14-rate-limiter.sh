#!/usr/bin/env bash
# =============================================================================
# File: phases/03-security/14-rate-limiter.sh
# Purpose: Generate a basic rate limiter utility
# Assumes: Project exists with src/lib directory
# Creates: src/lib/rateLimiter.ts
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

# =============================================================================
# METADATA
# =============================================================================
readonly SCRIPT_ID="14"
readonly SCRIPT_NAME="rate-limiter"
readonly SCRIPT_DESCRIPTION="Generate rate limiter utility"

# =============================================================================
# USAGE
# =============================================================================
usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

$SCRIPT_DESCRIPTION

OPTIONS:
    -h, --help      Show this help message and exit
    -n, --dry-run   Show what would be done without making changes
    -v, --verbose   Enable verbose output

EXAMPLES:
    $(basename "$0")              # Create rate limiter
    $(basename "$0") --dry-run    # Preview content

WHAT THIS SCRIPT DOES:
    1. Creates src/lib/rateLimiter.ts with in-memory rate limiting
    2. Provides token bucket algorithm implementation
    3. Supports both simple and sliding window limiting
    4. Designed for Server Actions and API routes

EOF
}

# =============================================================================
# MAIN LOGIC
# =============================================================================
main() {
    parse_common_args "$@"
    init_logging "$SCRIPT_NAME"

    log_step "Starting rate limiter creation"

    # Step 1: Check prerequisites
    log_step "Checking prerequisites"
    require_file "package.json" "Initialize project first"
    ensure_dir "src/lib"

    # Step 2: Create rate limiter
    log_step "Creating src/lib/rateLimiter.ts"

    local rate_limiter='/**
 * Rate Limiter Utility
 *
 * In-memory rate limiting for Server Actions and API routes.
 * Uses a sliding window algorithm for fair limiting.
 *
 * @example
 * ```ts
 * import { rateLimit } from "@/lib/rateLimiter";
 *
 * // In a Server Action
 * const limiter = rateLimit({
 *   interval: 60 * 1000, // 1 minute
 *   limit: 10,           // 10 requests per minute
 * });
 *
 * const { success, remaining } = await limiter.check(userId);
 * if (!success) {
 *   throw new Error("Rate limit exceeded");
 * }
 * ```
 */

interface RateLimitConfig {
  /**
   * Time window in milliseconds
   * @default 60000 (1 minute)
   */
  interval?: number;

  /**
   * Maximum requests per interval
   * @default 10
   */
  limit?: number;

  /**
   * Unique identifier for this limiter
   * @default "default"
   */
  namespace?: string;
}

interface RateLimitResult {
  /** Whether the request is allowed */
  success: boolean;
  /** Remaining requests in current window */
  remaining: number;
  /** Time until reset in milliseconds */
  resetIn: number;
  /** Total limit for this window */
  limit: number;
}

interface RateLimitEntry {
  tokens: number;
  lastRefill: number;
}

/**
 * In-memory store for rate limit data
 * Note: This resets on server restart. For production,
 * consider using Redis or the database.
 */
const store = new Map<string, RateLimitEntry>();

/**
 * Cleanup old entries periodically
 */
const CLEANUP_INTERVAL = 60 * 1000; // 1 minute
let lastCleanup = Date.now();

function cleanup(interval: number): void {
  const now = Date.now();
  if (now - lastCleanup < CLEANUP_INTERVAL) return;

  lastCleanup = now;
  const expiry = now - interval * 2;

  for (const [key, entry] of store.entries()) {
    if (entry.lastRefill < expiry) {
      store.delete(key);
    }
  }
}

/**
 * Create a rate limiter instance
 */
export function rateLimit(config: RateLimitConfig = {}) {
  const {
    interval = 60 * 1000,
    limit = 10,
    namespace = "default",
  } = config;

  return {
    /**
     * Check if a request should be allowed
     * @param identifier - Unique identifier (user ID, IP, etc.)
     */
    async check(identifier: string): Promise<RateLimitResult> {
      cleanup(interval);

      const key = `${namespace}:${identifier}`;
      const now = Date.now();
      const entry = store.get(key);

      if (!entry) {
        // First request - initialize with limit - 1 tokens
        store.set(key, {
          tokens: limit - 1,
          lastRefill: now,
        });

        return {
          success: true,
          remaining: limit - 1,
          resetIn: interval,
          limit,
        };
      }

      // Calculate token refill
      const timePassed = now - entry.lastRefill;
      const refillRate = limit / interval;
      const refillAmount = timePassed * refillRate;

      // Update tokens (cap at limit)
      entry.tokens = Math.min(limit, entry.tokens + refillAmount);
      entry.lastRefill = now;

      if (entry.tokens < 1) {
        // Rate limited
        const resetIn = Math.ceil((1 - entry.tokens) / refillRate);

        return {
          success: false,
          remaining: 0,
          resetIn,
          limit,
        };
      }

      // Allow request, consume token
      entry.tokens -= 1;
      store.set(key, entry);

      return {
        success: true,
        remaining: Math.floor(entry.tokens),
        resetIn: Math.ceil((limit - entry.tokens) / refillRate),
        limit,
      };
    },

    /**
     * Reset the rate limit for an identifier
     * @param identifier - Unique identifier to reset
     */
    async reset(identifier: string): Promise<void> {
      const key = `${namespace}:${identifier}`;
      store.delete(key);
    },

    /**
     * Get current status without consuming a token
     * @param identifier - Unique identifier to check
     */
    async status(identifier: string): Promise<RateLimitResult> {
      const key = `${namespace}:${identifier}`;
      const entry = store.get(key);

      if (!entry) {
        return {
          success: true,
          remaining: limit,
          resetIn: 0,
          limit,
        };
      }

      const now = Date.now();
      const timePassed = now - entry.lastRefill;
      const refillRate = limit / interval;
      const tokens = Math.min(limit, entry.tokens + timePassed * refillRate);

      return {
        success: tokens >= 1,
        remaining: Math.floor(tokens),
        resetIn: tokens < 1 ? Math.ceil((1 - tokens) / refillRate) : 0,
        limit,
      };
    },
  };
}

/**
 * Pre-configured rate limiters for common use cases
 */
export const rateLimiters = {
  /** Chat messages: 30 per minute */
  chat: rateLimit({ namespace: "chat", limit: 30, interval: 60 * 1000 }),

  /** Project creation: 5 per hour */
  projectCreate: rateLimit({ namespace: "project_create", limit: 5, interval: 60 * 60 * 1000 }),

  /** Export generation: 10 per hour */
  export: rateLimit({ namespace: "export", limit: 10, interval: 60 * 60 * 1000 }),

  /** General API: 100 per minute */
  api: rateLimit({ namespace: "api", limit: 100, interval: 60 * 1000 }),

  /** Auth attempts: 5 per 15 minutes */
  auth: rateLimit({ namespace: "auth", limit: 5, interval: 15 * 60 * 1000 }),
};

/**
 * Type exports
 */
export type { RateLimitConfig, RateLimitResult };
'

    write_file "src/lib/rateLimiter.ts" "$rate_limiter"

    log_success "Script $SCRIPT_ID completed"
}

main "$@"
