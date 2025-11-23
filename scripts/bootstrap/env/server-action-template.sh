#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SH="${SCRIPT_DIR%/*}/lib/common.sh"
[[ -f "${COMMON_SH}" ]] || { echo "ERROR: common.sh not found" >&2; exit 1; }
. "${COMMON_SH}"

SCRIPT_KEY="env/server-action-template.sh"

main() {
    parse_common_args "$@"
    [[ "${SHOW_HELP}" == "true" ]] && { echo "Create Server Action template"; exit 0; }

    log_info "=== Creating Server Action Template ==="
    cd "${PROJECT_ROOT:-.}"
    ensure_dir "src/lib"

    local action='"use server";
import { z, ZodSchema } from "zod";
import { rateLimit } from "./rateLimiter";

export type ActionResult<T> = { success: true; data: T } | { success: false; error: { code: string; message: string; fieldErrors?: Record<string, string[]> } };

interface ActionConfig<TInput, TOutput> {
  schema: ZodSchema<TInput>;
  rateLimit?: { limit: number; interval: number; namespace: string };
  getIdentifier?: () => Promise<string>;
  handler: (input: TInput) => Promise<TOutput>;
}

export function createAction<TInput, TOutput>(config: ActionConfig<TInput, TOutput>) {
  return async (rawInput: unknown): Promise<ActionResult<TOutput>> => {
    try {
      const parsed = config.schema.safeParse(rawInput);
      if (!parsed.success) return { success: false, error: { code: "VALIDATION_ERROR", message: "Invalid input", fieldErrors: parsed.error.flatten().fieldErrors as Record<string, string[]> } };
      if (config.rateLimit) {
        const limiter = rateLimit(config.rateLimit);
        const id = config.getIdentifier ? await config.getIdentifier() : "anon";
        const result = await limiter.check(id);
        if (!result.success) return { success: false, error: { code: "RATE_LIMITED", message: `Too many requests. Try again in ${Math.ceil(result.resetIn / 1000)}s.` } };
      }
      return { success: true, data: await config.handler(parsed.data) };
    } catch (e) { return { success: false, error: { code: "INTERNAL_ERROR", message: e instanceof Error ? e.message : "Unknown error" } }; }
  };
}
'
    write_file_if_missing "src/lib/action.ts" "${action}"
    mark_script_success "${SCRIPT_KEY}"
    log_success "Server Action template created"
}

main "$@"
