#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SH="${SCRIPT_DIR%/*}/lib/common.sh"
[[ -f "${COMMON_SH}" ]] || { echo "ERROR: common.sh not found" >&2; exit 1; }
. "${COMMON_SH}"

SCRIPT_KEY="ai/chat-feature-scaffold.sh"

main() {
    parse_common_args "$@"
    [[ "${SHOW_HELP}" == "true" ]] && { echo "Scaffold AI chat feature"; exit 0; }

    if [[ "${ENABLE_AI_SDK:-true}" != "true" ]]; then
        log_info "SKIP: AI SDK disabled via ENABLE_AI_SDK"
        mark_script_success "${SCRIPT_KEY}"
        return 0
    fi

    log_info "=== Scaffolding AI Chat Feature ==="
    cd "${PROJECT_ROOT:-.}"

    ensure_dir "src/app/api/chat"

    local chat_route='import { streamText } from "ai";
import { defaultModel } from "@/lib/ai/client";
import { AI_CONFIG } from "@/lib/ai/config";
import { getSystemPrompt } from "@/lib/ai/prompts";

export const maxDuration = 30;

export async function POST(req: Request) {
  const { messages } = await req.json();

  const result = streamText({
    model: defaultModel,
    system: getSystemPrompt("assistant"),
    messages,
    maxTokens: AI_CONFIG.maxTokens,
    temperature: AI_CONFIG.temperature,
  });

  return result.toDataStreamResponse();
}
'
    write_file_if_missing "src/app/api/chat/route.ts" "${chat_route}"

    ensure_dir "src/components/chat"

    local chat_component='"use client";

import { useChat } from "ai/react";
import { useState } from "react";

export function Chat() {
  const { messages, input, handleInputChange, handleSubmit, isLoading } = useChat();
  const [error, setError] = useState<string | null>(null);

  return (
    <div className="flex flex-col h-full max-w-2xl mx-auto p-4">
      <div className="flex-1 overflow-y-auto space-y-4 mb-4">
        {messages.map((m) => (
          <div
            key={m.id}
            className={`p-3 rounded-lg ${
              m.role === "user"
                ? "bg-primary text-primary-foreground ml-auto max-w-[80%]"
                : "bg-muted max-w-[80%]"
            }`}
          >
            <p className="text-sm font-medium mb-1">
              {m.role === "user" ? "You" : "Assistant"}
            </p>
            <p className="whitespace-pre-wrap">{m.content}</p>
          </div>
        ))}
        {isLoading && (
          <div className="bg-muted p-3 rounded-lg max-w-[80%]">
            <p className="text-sm text-muted-foreground">Thinking...</p>
          </div>
        )}
      </div>

      {error && (
        <div className="bg-destructive/10 text-destructive p-2 rounded mb-2">
          {error}
        </div>
      )}

      <form onSubmit={handleSubmit} className="flex gap-2">
        <input
          value={input}
          onChange={handleInputChange}
          placeholder="Type your message..."
          className="flex-1 px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-primary"
          disabled={isLoading}
        />
        <button
          type="submit"
          disabled={isLoading || !input.trim()}
          className="px-4 py-2 bg-primary text-primary-foreground rounded-lg hover:bg-primary/90 disabled:opacity-50"
        >
          Send
        </button>
      </form>
    </div>
  );
}
'
    write_file_if_missing "src/components/chat/Chat.tsx" "${chat_component}"

    local chat_index='export { Chat } from "./Chat";
'
    write_file_if_missing "src/components/chat/index.ts" "${chat_index}"

    mark_script_success "${SCRIPT_KEY}"
    log_success "AI chat feature scaffolded"
}

main "$@"
