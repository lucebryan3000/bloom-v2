#!/usr/bin/env bash
# =============================================================================
# File: phases/05-ai/20-chat-feature-scaffold.sh
# Purpose: Scaffold chat feature for workspace
# Assumes: AI SDK and prompts configured
# Creates: src/features/chat/* with store, components, actions
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

# =============================================================================
# METADATA
# =============================================================================
readonly SCRIPT_ID="20"
readonly SCRIPT_NAME="chat-feature-scaffold"
readonly SCRIPT_DESCRIPTION="Scaffold chat feature with components and actions"

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
    $(basename "$0")              # Create chat feature
    $(basename "$0") --dry-run    # Preview changes

WHAT THIS SCRIPT DOES:
    1. Creates chat Zustand store
    2. Creates ChatPanel component
    3. Creates chat server actions
    4. Sets up useChat hook integration

EOF
}

# =============================================================================
# MAIN LOGIC
# =============================================================================
main() {
    parse_common_args "$@"
    init_logging "$SCRIPT_NAME"

    log_step "Starting chat feature scaffold"

    # Step 1: Check prerequisites
    log_step "Checking prerequisites"
    require_file "package.json" "Initialize project first"
    ensure_dir "src/features/chat"

    # Step 2: Create chat store
    log_step "Creating src/features/chat/store.ts"

    local chat_store='import { create } from "zustand";
import type { Message } from "ai";
import type { SessionPhase, ExtractedMetric } from "@/lib/ai.types";

/**
 * Chat Store
 *
 * Manages chat state including messages, session info,
 * and extracted metrics for the active workspace.
 */

interface ChatState {
  // Session info
  sessionId: string | null;
  projectId: string | null;
  phase: SessionPhase;

  // Messages
  messages: Message[];
  isLoading: boolean;
  error: string | null;

  // Extracted data
  metrics: ExtractedMetric[];
  confidence: number;

  // UI state
  isInputFocused: boolean;

  // Actions
  setSession: (sessionId: string, projectId: string) => void;
  setPhase: (phase: SessionPhase) => void;
  setMessages: (messages: Message[]) => void;
  addMessage: (message: Message) => void;
  setLoading: (isLoading: boolean) => void;
  setError: (error: string | null) => void;
  addMetric: (metric: ExtractedMetric) => void;
  updateMetric: (index: number, metric: ExtractedMetric) => void;
  setConfidence: (confidence: number) => void;
  setInputFocused: (focused: boolean) => void;
  reset: () => void;
}

const initialState = {
  sessionId: null,
  projectId: null,
  phase: "discovery" as SessionPhase,
  messages: [],
  isLoading: false,
  error: null,
  metrics: [],
  confidence: 0,
  isInputFocused: false,
};

export const useChatStore = create<ChatState>((set) => ({
  ...initialState,

  setSession: (sessionId, projectId) =>
    set({ sessionId, projectId }),

  setPhase: (phase) =>
    set({ phase }),

  setMessages: (messages) =>
    set({ messages }),

  addMessage: (message) =>
    set((state) => ({
      messages: [...state.messages, message],
    })),

  setLoading: (isLoading) =>
    set({ isLoading }),

  setError: (error) =>
    set({ error }),

  addMetric: (metric) =>
    set((state) => ({
      metrics: [...state.metrics, metric],
    })),

  updateMetric: (index, metric) =>
    set((state) => ({
      metrics: state.metrics.map((m, i) =>
        i === index ? metric : m
      ),
    })),

  setConfidence: (confidence) =>
    set({ confidence }),

  setInputFocused: (focused) =>
    set({ isInputFocused: focused }),

  reset: () =>
    set(initialState),
}));

/**
 * Selector hooks for performance
 */
export const useMessages = () =>
  useChatStore((state) => state.messages);

export const useMetrics = () =>
  useChatStore((state) => state.metrics);

export const useChatLoading = () =>
  useChatStore((state) => state.isLoading);

export const useSessionPhase = () =>
  useChatStore((state) => state.phase);
'

    write_file "src/features/chat/store.ts" "$chat_store"

    # Step 3: Create ChatPanel component
    log_step "Creating src/features/chat/ChatPanel.tsx"

    local chat_panel='"use client";

import { useChat } from "ai/react";
import { useEffect, useRef } from "react";
import { useChatStore } from "./store";
import { ChatMessage } from "./ChatMessage";
import { ChatInput } from "./ChatInput";

/**
 * Chat Panel Component
 *
 * Main chat interface for Melissa AI conversations.
 * Uses Vercel AI SDK useChat hook for streaming.
 */

interface ChatPanelProps {
  sessionId: string;
  projectId: string;
}

export function ChatPanel({ sessionId, projectId }: ChatPanelProps) {
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const { setSession, setMessages, setLoading, setError } = useChatStore();

  // Initialize session
  useEffect(() => {
    setSession(sessionId, projectId);
  }, [sessionId, projectId, setSession]);

  // Use Vercel AI SDK chat hook
  const {
    messages,
    input,
    handleInputChange,
    handleSubmit,
    isLoading,
    error,
    reload,
    stop,
  } = useChat({
    api: "/api/chat",
    body: { sessionId },
    onFinish: (message) => {
      // TODO: Extract metrics from AI response
      // TODO: Persist message to database
      console.log("Message finished:", message);
    },
    onError: (err) => {
      setError(err.message);
    },
  });

  // Sync with store
  useEffect(() => {
    setMessages(messages);
  }, [messages, setMessages]);

  useEffect(() => {
    setLoading(isLoading);
  }, [isLoading, setLoading]);

  // Auto-scroll to bottom
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  return (
    <div className="flex flex-col h-full">
      {/* Messages area */}
      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {messages.length === 0 && (
          <div className="text-center text-gray-500 dark:text-gray-400 py-8">
            <p className="text-lg font-medium">Welcome to your ROI session</p>
            <p className="text-sm mt-2">
              Start by describing the initiative you'\''d like to analyze.
            </p>
          </div>
        )}

        {messages.map((message) => (
          <ChatMessage key={message.id} message={message} />
        ))}

        {isLoading && (
          <div className="flex items-center gap-2 text-gray-500">
            <div className="animate-pulse">Melissa is thinking...</div>
          </div>
        )}

        {error && (
          <div className="p-4 bg-red-50 dark:bg-red-900/20 text-red-600 dark:text-red-400 rounded-lg">
            <p>Error: {error.message}</p>
            <button
              onClick={() => reload()}
              className="mt-2 text-sm underline"
            >
              Try again
            </button>
          </div>
        )}

        <div ref={messagesEndRef} />
      </div>

      {/* Input area */}
      <div className="border-t border-gray-200 dark:border-gray-700 p-4">
        <ChatInput
          input={input}
          onChange={handleInputChange}
          onSubmit={handleSubmit}
          isLoading={isLoading}
          onStop={stop}
        />
      </div>
    </div>
  );
}
'

    write_file "src/features/chat/ChatPanel.tsx" "$chat_panel"

    # Step 4: Create ChatMessage component
    log_step "Creating src/features/chat/ChatMessage.tsx"

    local chat_message='"use client";

import type { Message } from "ai";
import { cn } from "@/lib/utils";

/**
 * Chat Message Component
 *
 * Renders individual chat messages with role-based styling.
 */

interface ChatMessageProps {
  message: Message;
}

export function ChatMessage({ message }: ChatMessageProps) {
  const isUser = message.role === "user";

  return (
    <div
      className={cn(
        "flex gap-3",
        isUser ? "flex-row-reverse" : "flex-row"
      )}
    >
      {/* Avatar */}
      <div
        className={cn(
          "flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium",
          isUser
            ? "bg-blue-600 text-white"
            : "bg-purple-600 text-white"
        )}
      >
        {isUser ? "You" : "M"}
      </div>

      {/* Message bubble */}
      <div
        className={cn(
          "max-w-[80%] rounded-lg px-4 py-2",
          isUser
            ? "bg-blue-600 text-white"
            : "bg-gray-100 dark:bg-gray-800 text-gray-900 dark:text-white"
        )}
      >
        <div className="whitespace-pre-wrap">{message.content}</div>

        {/* Timestamp */}
        <div
          className={cn(
            "text-xs mt-1",
            isUser
              ? "text-blue-200"
              : "text-gray-500 dark:text-gray-400"
          )}
        >
          {message.createdAt
            ? new Date(message.createdAt).toLocaleTimeString()
            : ""}
        </div>
      </div>
    </div>
  );
}
'

    write_file "src/features/chat/ChatMessage.tsx" "$chat_message"

    # Step 5: Create ChatInput component
    log_step "Creating src/features/chat/ChatInput.tsx"

    local chat_input='"use client";

import { FormEvent, KeyboardEvent } from "react";

/**
 * Chat Input Component
 *
 * Text input for sending messages with submit handling.
 */

interface ChatInputProps {
  input: string;
  onChange: (e: React.ChangeEvent<HTMLTextAreaElement>) => void;
  onSubmit: (e: FormEvent<HTMLFormElement>) => void;
  isLoading: boolean;
  onStop: () => void;
}

export function ChatInput({
  input,
  onChange,
  onSubmit,
  isLoading,
  onStop,
}: ChatInputProps) {
  // Handle keyboard shortcuts
  function handleKeyDown(e: KeyboardEvent<HTMLTextAreaElement>) {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      const form = e.currentTarget.form;
      if (form && input.trim()) {
        form.requestSubmit();
      }
    }
  }

  return (
    <form onSubmit={onSubmit} className="flex gap-2">
      <div className="flex-1 relative">
        <textarea
          value={input}
          onChange={onChange}
          onKeyDown={handleKeyDown}
          placeholder="Type your message..."
          disabled={isLoading}
          rows={1}
          className="w-full resize-none rounded-lg border border-gray-300 dark:border-gray-600 px-4 py-2 pr-12 focus:outline-none focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white disabled:opacity-50"
          style={{ minHeight: "44px", maxHeight: "200px" }}
        />
      </div>

      {isLoading ? (
        <button
          type="button"
          onClick={onStop}
          className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500"
        >
          Stop
        </button>
      ) : (
        <button
          type="submit"
          disabled={!input.trim()}
          className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          Send
        </button>
      )}
    </form>
  );
}
'

    write_file "src/features/chat/ChatInput.tsx" "$chat_input"

    # Step 6: Create actions
    log_step "Creating src/features/chat/actions.ts"

    local chat_actions='"use server";

import { z } from "zod";
import { createAction } from "@/lib/action";
import { db } from "@/db";
// import { messages } from "@/db/schema";
import { getCurrentUser } from "@/lib/auth";
import { rateLimiters } from "@/lib/rateLimiter";

/**
 * Chat Server Actions
 *
 * Server-side actions for chat operations.
 */

/**
 * Save message to database
 */
const SaveMessageSchema = z.object({
  sessionId: z.string().uuid(),
  role: z.enum(["user", "assistant"]),
  content: z.string().min(1),
  metadata: z.record(z.unknown()).optional(),
});

export const saveMessage = createAction({
  schema: SaveMessageSchema,
  rateLimit: {
    limit: 60,
    interval: 60 * 1000,
    namespace: "save_message",
  },
  async getIdentifier() {
    const user = await getCurrentUser();
    return user?.id || "anonymous";
  },
  async handler(input) {
    // TODO: Implement when messages table is created
    // const [message] = await db.insert(messages).values({
    //   sessionId: input.sessionId,
    //   role: input.role,
    //   content: input.content,
    //   metadata: input.metadata,
    // }).returning();

    console.log("Would save message:", input);
    return { id: "placeholder", ...input };
  },
});

/**
 * Get session messages
 */
const GetMessagesSchema = z.object({
  sessionId: z.string().uuid(),
  limit: z.number().min(1).max(100).default(50),
  offset: z.number().min(0).default(0),
});

export const getMessages = createAction({
  schema: GetMessagesSchema,
  async handler(input) {
    // TODO: Implement when messages table is created
    // const sessionMessages = await db.query.messages.findMany({
    //   where: eq(messages.sessionId, input.sessionId),
    //   limit: input.limit,
    //   offset: input.offset,
    //   orderBy: (messages, { asc }) => [asc(messages.createdAt)],
    // });

    console.log("Would fetch messages for session:", input.sessionId);
    return [];
  },
});
'

    write_file "src/features/chat/actions.ts" "$chat_actions"

    # Step 7: Create utils file
    log_step "Creating src/lib/utils.ts"

    local utils='import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

/**
 * Utility for merging Tailwind CSS classes
 *
 * Combines clsx and tailwind-merge for optimal class handling.
 */
export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
'

    write_file "src/lib/utils.ts" "$utils"

    # Install clsx and tailwind-merge
    add_dependency "clsx"
    add_dependency "tailwind-merge"

    # Step 8: Create index export
    log_step "Creating src/features/chat/index.ts"

    local chat_index='export { ChatPanel } from "./ChatPanel";
export { ChatMessage } from "./ChatMessage";
export { ChatInput } from "./ChatInput";
export { useChatStore, useMessages, useMetrics } from "./store";
export * from "./actions";
'

    write_file "src/features/chat/index.ts" "$chat_index"

    log_success "Script $SCRIPT_ID completed"
}

main "$@"
