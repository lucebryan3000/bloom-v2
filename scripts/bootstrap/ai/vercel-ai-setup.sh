#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SH="${SCRIPT_DIR%/*}/lib/common.sh"
[[ -f "${COMMON_SH}" ]] || { echo "ERROR: common.sh not found" >&2; exit 1; }
. "${COMMON_SH}"

SCRIPT_KEY="ai/vercel-ai-setup.sh"

main() {
    parse_common_args "$@"
    [[ "${SHOW_HELP}" == "true" ]] && { echo "Setup Vercel AI SDK"; exit 0; }

    if [[ "${ENABLE_AI_SDK:-true}" != "true" ]]; then
        log_info "SKIP: AI SDK disabled via ENABLE_AI_SDK"
        mark_script_success "${SCRIPT_KEY}"
        return 0
    fi

    log_info "=== Setting up Vercel AI SDK ==="
    cd "${PROJECT_ROOT:-.}"

    add_dependency "ai"
    add_dependency "@ai-sdk/anthropic"
    add_dependency "zod"

    ensure_dir "src/lib/ai"

    local ai_client='import { createAnthropic } from "@ai-sdk/anthropic";

if (!process.env.ANTHROPIC_API_KEY) {
  throw new Error("ANTHROPIC_API_KEY environment variable is not set");
}

export const anthropic = createAnthropic({
  apiKey: process.env.ANTHROPIC_API_KEY,
});

export const defaultModel = anthropic("claude-sonnet-4-20250514");

export type ModelId = "claude-sonnet-4-20250514" | "claude-3-5-haiku-20241022";

export function getModel(modelId: ModelId = "claude-sonnet-4-20250514") {
  return anthropic(modelId);
}
'
    write_file_if_missing "src/lib/ai/client.ts" "${ai_client}"

    local ai_config='export const AI_CONFIG = {
  maxTokens: 4096,
  temperature: 0.7,
  defaultModel: "claude-sonnet-4-20250514" as const,
  streamingEnabled: true,
} as const;

export type AIConfig = typeof AI_CONFIG;
'
    write_file_if_missing "src/lib/ai/config.ts" "${ai_config}"

    mark_script_success "${SCRIPT_KEY}"
    log_success "Vercel AI SDK setup complete"
}

main "$@"
