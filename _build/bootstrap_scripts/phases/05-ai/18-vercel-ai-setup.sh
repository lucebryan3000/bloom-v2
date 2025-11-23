#!/usr/bin/env bash
# =============================================================================
# File: phases/05-ai/18-vercel-ai-setup.sh
# Purpose: Install and configure @vercel/ai (AI SDK)
# Assumes: Next.js project exists
# Creates: AI client configuration and hooks
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

# =============================================================================
# METADATA
# =============================================================================
readonly SCRIPT_ID="18"
readonly SCRIPT_NAME="vercel-ai-setup"
readonly SCRIPT_DESCRIPTION="Install and configure Vercel AI SDK"

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
    $(basename "$0")              # Set up AI SDK
    $(basename "$0") --dry-run    # Preview changes

WHAT THIS SCRIPT DOES:
    1. Installs ai and @ai-sdk/anthropic packages
    2. Creates AI client configuration
    3. Sets up streaming chat API route
    4. Creates useChat hook wrapper

EOF
}

# =============================================================================
# MAIN LOGIC
# =============================================================================
main() {
    parse_common_args "$@"
    init_logging "$SCRIPT_NAME"

    log_step "Starting Vercel AI SDK setup"

    # Step 1: Check prerequisites
    log_step "Checking prerequisites"
    require_pnpm
    require_file "package.json" "Initialize project first"

    # Step 2: Install dependencies
    log_step "Installing AI SDK dependencies"

    add_dependency "ai"
    add_dependency "@ai-sdk/anthropic"

    # Step 3: Create AI client configuration
    log_step "Creating src/lib/ai.ts"

    ensure_dir "src/lib"

    local ai_config='import { createAnthropic } from "@ai-sdk/anthropic";

/**
 * Anthropic AI Client Configuration
 *
 * Configures the Anthropic provider for use with the Vercel AI SDK.
 *
 * @see https://sdk.vercel.ai/providers/ai-sdk-providers/anthropic
 */

// Validate API key
if (!process.env.ANTHROPIC_API_KEY) {
  console.warn(
    "ANTHROPIC_API_KEY not set. AI features will not work."
  );
}

/**
 * Anthropic client instance
 *
 * Use this to create model instances for chat completions.
 */
export const anthropic = createAnthropic({
  apiKey: process.env.ANTHROPIC_API_KEY,
});

/**
 * Default model for Bloom2
 *
 * Claude 3.5 Sonnet is recommended for the balance of
 * capability and cost.
 */
export const DEFAULT_MODEL = "claude-sonnet-4-20250514";

/**
 * Model options
 */
export const AI_MODELS = {
  /** Best for complex reasoning and analysis */
  sonnet: "claude-sonnet-4-20250514",
  /** Fastest, best for simple tasks */
  haiku: "claude-3-5-haiku-20241022",
} as const;

export type AIModel = keyof typeof AI_MODELS;

/**
 * Get model instance by name
 */
export function getModel(modelName: AIModel = "sonnet") {
  return anthropic(AI_MODELS[modelName]);
}

/**
 * Default generation settings
 */
export const DEFAULT_SETTINGS = {
  maxTokens: 4096,
  temperature: 0.7,
} as const;
'

    write_file "src/lib/ai.ts" "$ai_config"

    # Step 4: Create chat API route
    log_step "Creating chat API route"

    ensure_dir "src/app/api/chat"

    local chat_route='import { streamText } from "ai";
import { getModel, DEFAULT_SETTINGS } from "@/lib/ai";
import { getSystemPrompt } from "@/prompts/system";

/**
 * Chat API Route
 *
 * Handles streaming chat completions with Melissa AI.
 *
 * POST /api/chat
 */
export async function POST(req: Request) {
  try {
    const { messages, sessionId } = await req.json();

    // Validate input
    if (!messages || !Array.isArray(messages)) {
      return new Response("Invalid messages", { status: 400 });
    }

    // Get system prompt with session context
    const systemPrompt = await getSystemPrompt(sessionId);

    // Stream the response
    const result = streamText({
      model: getModel("sonnet"),
      system: systemPrompt,
      messages,
      ...DEFAULT_SETTINGS,
    });

    // Return streaming response
    return result.toDataStreamResponse();
  } catch (error) {
    console.error("Chat API error:", error);
    return new Response(
      error instanceof Error ? error.message : "Internal server error",
      { status: 500 }
    );
  }
}
'

    write_file "src/app/api/chat/route.ts" "$chat_route"

    # Step 5: Create AI types
    log_step "Creating AI types"

    local ai_types='import type { Message } from "ai";

/**
 * AI-related type definitions
 */

/**
 * Extended message type with Bloom2-specific metadata
 */
export interface BloomMessage extends Message {
  /** Session this message belongs to */
  sessionId?: string;
  /** Extracted metrics from this message */
  metrics?: ExtractedMetric[];
  /** Emotion detected in message */
  emotion?: MessageEmotion;
  /** Phase during which message was sent */
  phase?: SessionPhase;
}

/**
 * Metric extracted from conversation
 */
export interface ExtractedMetric {
  name: string;
  value: number;
  unit?: string;
  confidence: number;
  sourceText: string;
}

/**
 * Emotion classification
 */
export type MessageEmotion =
  | "neutral"
  | "positive"
  | "negative"
  | "uncertain"
  | "excited";

/**
 * Conversation phases
 */
export type SessionPhase =
  | "discovery"
  | "quantification"
  | "validation"
  | "synthesis";

/**
 * Session state injected into system prompt
 */
export interface SessionState {
  sessionId: string;
  projectId: string;
  phase: SessionPhase;
  metrics: ExtractedMetric[];
  openQuestions: string[];
  confidence: number;
}
'

    write_file "src/lib/ai.types.ts" "$ai_types"

    log_success "Script $SCRIPT_ID completed"
}

main "$@"
