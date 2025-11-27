#!/usr/bin/env bash
#!meta
# id: ai/chat-feature-scaffold.sh
# name: chat feature scaffold
# phase: 3
# phase_name: User Interface
# profile_tags:
#   - tech_stack
#   - ai
# uses_from_omni_config:
# uses_from_omni_settings:
#   - PROJECT_ROOT
#   - INSTALL_DIR
#   - CHAT_API_DIR
#   - CHAT_COMPONENTS_DIR
#   - CHAT_PAGE_DIR
# top_flags:
# dependencies:
#   packages: []
#   dev_packages: []
#!endmeta

# =============================================================================
# tech_stack/ai/chat-feature-scaffold.sh - Chat Feature Scaffold
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Phase: 3
# Purpose: Creates basic chat UI scaffold with components and API route
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

readonly SCRIPT_ID="ai/chat-feature-scaffold"
readonly SCRIPT_NAME="Chat Feature Scaffold"

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

# Create chat components directory
CHAT_COMPONENTS_DIR="src/components/chat"
mkdir -p "${CHAT_COMPONENTS_DIR}"

# Create ChatMessage component
cat > "${CHAT_COMPONENTS_DIR}/chat-message.tsx" << 'EOF'
"use client";

import { cn } from "@/lib/utils";

export interface Message {
  id: string;
  role: "user" | "assistant";
  content: string;
}

interface ChatMessageProps {
  message: Message;
}

export function ChatMessage({ message }: ChatMessageProps) {
  const isUser = message.role === "user";

  return (
    <div
      className={cn(
        "flex w-full",
        isUser ? "justify-end" : "justify-start"
      )}
    >
      <div
        className={cn(
          "max-w-[80%] rounded-lg px-4 py-2",
          isUser
            ? "bg-primary text-primary-foreground"
            : "bg-muted text-muted-foreground"
        )}
      >
        <p className="whitespace-pre-wrap">{message.content}</p>
      </div>
    </div>
  );
}
EOF

log_ok "Created ChatMessage component"

# Create ChatInput component
cat > "${CHAT_COMPONENTS_DIR}/chat-input.tsx" << 'EOF'
"use client";

import { useState, useRef, KeyboardEvent } from "react";

interface ChatInputProps {
  onSend: (message: string) => void;
  disabled?: boolean;
  placeholder?: string;
}

export function ChatInput({
  onSend,
  disabled = false,
  placeholder = "Type a message...",
}: ChatInputProps) {
  const [input, setInput] = useState("");
  const textareaRef = useRef<HTMLTextAreaElement>(null);

  const handleSubmit = () => {
    const trimmed = input.trim();
    if (!trimmed || disabled) return;

    onSend(trimmed);
    setInput("");

    if (textareaRef.current) {
      textareaRef.current.style.height = "auto";
    }
  };

  const handleKeyDown = (e: KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      handleSubmit();
    }
  };

  return (
    <div className="flex gap-2 border-t p-4">
      <textarea
        ref={textareaRef}
        value={input}
        onChange={(e) => setInput(e.target.value)}
        onKeyDown={handleKeyDown}
        placeholder={placeholder}
        disabled={disabled}
        rows={1}
        className="flex-1 resize-none rounded-md border bg-background px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-ring disabled:opacity-50"
      />
      <button
        onClick={handleSubmit}
        disabled={disabled || !input.trim()}
        className="rounded-md bg-primary px-4 py-2 text-sm text-primary-foreground hover:bg-primary/90 disabled:opacity-50"
      >
        Send
      </button>
    </div>
  );
}
EOF

log_ok "Created ChatInput component"

# Create ChatContainer component
cat > "${CHAT_COMPONENTS_DIR}/chat-container.tsx" << 'EOF'
"use client";

import { useRef, useEffect } from "react";
import { ChatMessage, Message } from "./chat-message";
import { ChatInput } from "./chat-input";

interface ChatContainerProps {
  messages: Message[];
  onSend: (message: string) => void;
  isLoading?: boolean;
}

export function ChatContainer({
  messages,
  onSend,
  isLoading = false,
}: ChatContainerProps) {
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  return (
    <div className="flex h-full flex-col">
      <div className="flex-1 overflow-y-auto p-4">
        <div className="space-y-4">
          {messages.length === 0 ? (
            <div className="flex h-full items-center justify-center text-muted-foreground">
              <p>Start a conversation...</p>
            </div>
          ) : (
            messages.map((message) => (
              <ChatMessage key={message.id} message={message} />
            ))
          )}
          {isLoading && (
            <div className="flex justify-start">
              <div className="rounded-lg bg-muted px-4 py-2 text-muted-foreground">
                <span className="animate-pulse">Thinking...</span>
              </div>
            </div>
          )}
          <div ref={messagesEndRef} />
        </div>
      </div>
      <ChatInput onSend={onSend} disabled={isLoading} />
    </div>
  );
}
EOF

log_ok "Created ChatContainer component"

# Create barrel export for chat components
cat > "${CHAT_COMPONENTS_DIR}/index.ts" << 'EOF'
export { ChatMessage, type Message } from "./chat-message";
export { ChatInput } from "./chat-input";
export { ChatContainer } from "./chat-container";
EOF

log_ok "Created chat components index"

# Create chat API route directory
CHAT_API_DIR="src/app/api/chat"
mkdir -p "${CHAT_API_DIR}"

# Create chat API route
cat > "${CHAT_API_DIR}/route.ts" << 'EOF'
import { streamText } from "ai";
import { openai } from "@ai-sdk/openai";
import { getSystemPrompt } from "@/lib/prompts";

export const runtime = "edge";

export async function POST(req: Request) {
  try {
    const { messages } = await req.json();

    const result = streamText({
      model: openai("gpt-4o-mini"),
      system: getSystemPrompt("default"),
      messages,
    });

    return result.toTextStreamResponse();
  } catch (error) {
    console.error("Chat API error:", error);
    return new Response(
      JSON.stringify({ error: "Failed to process chat request" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
}
EOF

log_ok "Created chat API route"

# Create chat page
CHAT_PAGE_DIR="src/app/chat"
mkdir -p "${CHAT_PAGE_DIR}"

cat > "${CHAT_PAGE_DIR}/page.tsx" << 'EOF'
"use client";

import { useChat } from "@ai-sdk/react";
import { ChatContainer } from "@/components/chat";

export default function ChatPage() {
  const { messages, sendMessage, status } = useChat();
  const isLoading = status === "streaming";

  const handleSend = (message: string) => {
    void sendMessage({ text: message });
  };

  const formattedMessages = messages.map((m) => {
    const parts: any[] | undefined = (m as any).parts;
    const textFromParts =
      Array.isArray(parts) && parts.length
        ? parts
            .map((p: any) => ("text" in p ? p.text : ""))
            .filter(Boolean)
            .join(" ")
        : undefined;
    const content = (m as any).content ?? (m as any).text ?? textFromParts ?? "";

    return {
      id: m.id,
      role: m.role as "user" | "assistant",
      content,
    };
  });

  return (
    <div className="container mx-auto h-[calc(100vh-4rem)] max-w-4xl py-4">
      <div className="flex h-full flex-col rounded-lg border shadow-sm">
        <div className="border-b px-4 py-3">
          <h1 className="text-lg font-semibold">Chat</h1>
        </div>
        <ChatContainer
          messages={formattedMessages}
          onSend={handleSend}
          isLoading={isLoading}
        />
      </div>
    </div>
  );
}
EOF

log_ok "Created chat page"

mark_script_success "${SCRIPT_ID}"
log_ok "${SCRIPT_NAME} complete"