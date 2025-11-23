#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SH="${SCRIPT_DIR%/*}/lib/common.sh"
[[ -f "${COMMON_SH}" ]] || { echo "ERROR: common.sh not found" >&2; exit 1; }
. "${COMMON_SH}"

SCRIPT_KEY="env/rate-limiter.sh"

main() {
    parse_common_args "$@"
    [[ "${SHOW_HELP}" == "true" ]] && { echo "Create rate limiter utility"; exit 0; }

    log_info "=== Creating Rate Limiter ==="
    cd "${PROJECT_ROOT:-.}"
    ensure_dir "src/lib"

    local limiter='interface RateLimitConfig { interval?: number; limit?: number; namespace?: string; }
interface RateLimitResult { success: boolean; remaining: number; resetIn: number; limit: number; }
const store = new Map<string, { tokens: number; lastRefill: number }>();

export function rateLimit(config: RateLimitConfig = {}) {
  const { interval = 60000, limit = 10, namespace = "default" } = config;
  return {
    async check(identifier: string): Promise<RateLimitResult> {
      const key = `${namespace}:${identifier}`;
      const now = Date.now();
      const entry = store.get(key);
      if (!entry) { store.set(key, { tokens: limit - 1, lastRefill: now }); return { success: true, remaining: limit - 1, resetIn: interval, limit }; }
      const refill = ((now - entry.lastRefill) / interval) * limit;
      entry.tokens = Math.min(limit, entry.tokens + refill);
      entry.lastRefill = now;
      if (entry.tokens < 1) return { success: false, remaining: 0, resetIn: Math.ceil((1 - entry.tokens) / (limit / interval)), limit };
      entry.tokens -= 1;
      return { success: true, remaining: Math.floor(entry.tokens), resetIn: interval, limit };
    },
  };
}

export const rateLimiters = {
  chat: rateLimit({ namespace: "chat", limit: 30 }),
  api: rateLimit({ namespace: "api", limit: 100 }),
  auth: rateLimit({ namespace: "auth", limit: 5, interval: 900000 }),
};
'
    write_file_if_missing "src/lib/rateLimiter.ts" "${limiter}"
    mark_script_success "${SCRIPT_KEY}"
    log_success "Rate limiter created"
}

main "$@"
