#!/usr/bin/env bash
# =============================================================================
# tech_stack/ai/prompts-structure.sh - Prompts Structure Setup
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Phase: 3
# Purpose: Creates src/lib/prompts/ directory with prompt templates
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"

readonly SCRIPT_ID="ai/prompts-structure"
readonly SCRIPT_NAME="Prompts Structure Setup"

# Check if already completed
if has_script_succeeded "${SCRIPT_ID}"; then
    log_skip "${SCRIPT_NAME} (already completed)"
    exit 0
fi

log_step "${SCRIPT_NAME}"

: "${PROJECT_ROOT:?PROJECT_ROOT not set}"
cd "$PROJECT_ROOT"

# Create prompts directory
PROMPTS_DIR="src/lib/prompts"
mkdir -p "${PROMPTS_DIR}"

# Create index.ts barrel export
cat > "${PROMPTS_DIR}/index.ts" << 'EOF'
/**
 * Prompt Templates
 *
 * Centralized prompt management for AI features.
 * Import prompts from this module to ensure consistency.
 */

export * from "./system";
export * from "./chat";
export * from "./utils";
EOF

log_ok "Created prompts index"

# Create system prompts
cat > "${PROMPTS_DIR}/system.ts" << 'EOF'
/**
 * System Prompts
 *
 * Base system prompts that define AI assistant behavior and constraints.
 */

export const SYSTEM_PROMPTS = {
  default: `You are a helpful AI assistant. Be concise, accurate, and helpful.`,

  coding: `You are an expert software engineer. Help users with coding questions,
debugging, and best practices. Provide clear explanations and working code examples.`,

  creative: `You are a creative writing assistant. Help users brainstorm ideas,
improve their writing, and explore creative possibilities.`,
} as const;

export type SystemPromptKey = keyof typeof SYSTEM_PROMPTS;

export function getSystemPrompt(key: SystemPromptKey = "default"): string {
  return SYSTEM_PROMPTS[key];
}
EOF

log_ok "Created system prompts"

# Create chat prompts
cat > "${PROMPTS_DIR}/chat.ts" << 'EOF'
/**
 * Chat Prompts
 *
 * Prompt templates for chat-based interactions.
 */

export interface ChatPromptOptions {
  context?: string;
  instructions?: string;
  format?: "markdown" | "plain" | "json";
}

export function buildChatPrompt(
  userMessage: string,
  options: ChatPromptOptions = {}
): string {
  const { context, instructions, format = "markdown" } = options;

  const parts: string[] = [];

  if (context) {
    parts.push(`Context:\n${context}\n`);
  }

  if (instructions) {
    parts.push(`Instructions:\n${instructions}\n`);
  }

  parts.push(`User Message:\n${userMessage}`);

  if (format === "json") {
    parts.push("\nRespond with valid JSON only.");
  }

  return parts.join("\n");
}

export const CHAT_TEMPLATES = {
  summarize: (text: string) =>
    `Summarize the following text concisely:\n\n${text}`,

  explain: (concept: string) =>
    `Explain ${concept} in simple terms that a beginner would understand.`,

  improve: (text: string) =>
    `Improve the following text for clarity and readability:\n\n${text}`,
} as const;
EOF

log_ok "Created chat prompts"

# Create prompt utilities
cat > "${PROMPTS_DIR}/utils.ts" << 'EOF'
/**
 * Prompt Utilities
 *
 * Helper functions for prompt construction and manipulation.
 */

/**
 * Truncate text to a maximum token estimate (rough character-based)
 */
export function truncateForContext(
  text: string,
  maxChars: number = 4000
): string {
  if (text.length <= maxChars) return text;
  return text.slice(0, maxChars) + "... [truncated]";
}

/**
 * Escape special characters in user input for safe prompt injection
 */
export function sanitizeInput(input: string): string {
  return input
    .replace(/\\/g, "\\\\")
    .replace(/"/g, '\\"')
    .trim();
}

/**
 * Join multiple prompt segments with proper spacing
 */
export function joinPromptParts(...parts: (string | undefined)[]): string {
  return parts
    .filter((part): part is string => Boolean(part))
    .join("\n\n");
}

/**
 * Create a structured prompt with labeled sections
 */
export function createStructuredPrompt(
  sections: Record<string, string>
): string {
  return Object.entries(sections)
    .map(([label, content]) => `## ${label}\n${content}`)
    .join("\n\n");
}
EOF

log_ok "Created prompt utilities"

mark_script_success "${SCRIPT_ID}"
log_ok "${SCRIPT_NAME} complete"
