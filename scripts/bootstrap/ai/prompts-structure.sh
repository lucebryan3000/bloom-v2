#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SH="${SCRIPT_DIR%/*}/lib/common.sh"
[[ -f "${COMMON_SH}" ]] || { echo "ERROR: common.sh not found" >&2; exit 1; }
. "${COMMON_SH}"

SCRIPT_KEY="ai/prompts-structure.sh"

main() {
    parse_common_args "$@"
    [[ "${SHOW_HELP}" == "true" ]] && { echo "Create AI prompts structure"; exit 0; }

    if [[ "${ENABLE_AI_SDK:-true}" != "true" ]]; then
        log_info "SKIP: AI SDK disabled via ENABLE_AI_SDK"
        mark_script_success "${SCRIPT_KEY}"
        return 0
    fi

    log_info "=== Creating AI Prompts Structure ==="
    cd "${PROJECT_ROOT:-.}"

    ensure_dir "src/lib/ai/prompts"

    local system_prompts='export const SYSTEM_PROMPTS = {
  assistant: `You are a helpful AI assistant. Be concise and accurate in your responses.`,

  analyst: `You are a data analyst. Analyze information carefully and provide insights based on the data provided.`,

  writer: `You are a professional writer. Create clear, engaging content that meets the user'"'"'s requirements.`,
} as const;

export type SystemPromptKey = keyof typeof SYSTEM_PROMPTS;

export function getSystemPrompt(key: SystemPromptKey): string {
  return SYSTEM_PROMPTS[key];
}
'
    write_file_if_missing "src/lib/ai/prompts/system.ts" "${system_prompts}"

    local prompt_builder='import { SYSTEM_PROMPTS, type SystemPromptKey } from "./system";

export interface PromptOptions {
  systemPrompt?: SystemPromptKey | string;
  context?: string;
  examples?: Array<{ input: string; output: string }>;
}

export function buildPrompt(userMessage: string, options: PromptOptions = {}): {
  system: string;
  user: string;
} {
  let system = typeof options.systemPrompt === "string"
    ? options.systemPrompt
    : SYSTEM_PROMPTS[options.systemPrompt ?? "assistant"];

  if (options.context) {
    system += `\n\nContext:\n${options.context}`;
  }

  if (options.examples?.length) {
    system += "\n\nExamples:";
    for (const ex of options.examples) {
      system += `\nInput: ${ex.input}\nOutput: ${ex.output}`;
    }
  }

  return { system, user: userMessage };
}
'
    write_file_if_missing "src/lib/ai/prompts/builder.ts" "${prompt_builder}"

    local prompts_index='export * from "./system";
export * from "./builder";
'
    write_file_if_missing "src/lib/ai/prompts/index.ts" "${prompts_index}"

    mark_script_success "${SCRIPT_KEY}"
    log_success "AI prompts structure created"
}

main "$@"
