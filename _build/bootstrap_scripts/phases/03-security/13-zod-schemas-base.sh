#!/usr/bin/env bash
# =============================================================================
# File: phases/03-security/13-zod-schemas-base.sh
# Purpose: Create base Zod schema files for common payloads
# Assumes: Zod installed, src/schemas directory exists
# Creates: src/schemas/*.ts with base validation schemas
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

# =============================================================================
# METADATA
# =============================================================================
readonly SCRIPT_ID="13"
readonly SCRIPT_NAME="zod-schemas-base"
readonly SCRIPT_DESCRIPTION="Create base Zod validation schemas"

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
    $(basename "$0")              # Create schema files
    $(basename "$0") --dry-run    # Preview changes

WHAT THIS SCRIPT DOES:
    1. Creates src/schemas/chat.ts for chat payloads
    2. Creates src/schemas/metrics.ts for metrics/ROI
    3. Creates src/schemas/projects.ts for project CRUD
    4. Creates src/schemas/settings.ts for feature flags

EOF
}

# =============================================================================
# MAIN LOGIC
# =============================================================================
main() {
    parse_common_args "$@"
    init_logging "$SCRIPT_NAME"

    log_step "Starting Zod schemas creation"

    # Step 1: Check prerequisites
    log_step "Checking prerequisites"
    require_file "package.json" "Initialize project first"
    ensure_dir "src/schemas"

    # Step 2: Create chat.ts
    log_step "Creating src/schemas/chat.ts"

    local chat_schema='import { z } from "zod";

/**
 * Chat-related validation schemas
 *
 * Used for validating chat messages, sessions, and AI interactions.
 */

/**
 * Message role enum
 */
export const MessageRoleSchema = z.enum(["user", "assistant", "system"]);
export type MessageRole = z.infer<typeof MessageRoleSchema>;

/**
 * Single chat message
 */
export const ChatMessageSchema = z.object({
  id: z.string().uuid().optional(),
  role: MessageRoleSchema,
  content: z.string().min(1, "Message cannot be empty").max(100000),
  createdAt: z.date().optional(),
  metadata: z.record(z.unknown()).optional(),
});
export type ChatMessage = z.infer<typeof ChatMessageSchema>;

/**
 * Send message request
 */
export const SendMessageSchema = z.object({
  sessionId: z.string().uuid(),
  content: z.string().min(1).max(10000),
});
export type SendMessageInput = z.infer<typeof SendMessageSchema>;

/**
 * Chat session state
 */
export const ChatSessionSchema = z.object({
  id: z.string().uuid(),
  projectId: z.string().uuid(),
  type: z.enum(["baseline", "retrospective"]),
  phase: z.enum(["discovery", "quantification", "validation", "synthesis"]),
  messages: z.array(ChatMessageSchema),
  createdAt: z.date(),
  updatedAt: z.date(),
});
export type ChatSession = z.infer<typeof ChatSessionSchema>;

// TODO: Add more chat-related schemas as needed
// - Emotion detection schema
// - AI response schema with structured metrics
// - Session state for LLM context injection
'

    write_file "src/schemas/chat.ts" "$chat_schema"

    # Step 3: Create metrics.ts
    log_step "Creating src/schemas/metrics.ts"

    local metrics_schema='import { z } from "zod";

/**
 * Metrics and ROI validation schemas
 *
 * Used for validating extracted metrics, ROI calculations,
 * and confidence scores.
 */

/**
 * Metric source type
 */
export const MetricSourceSchema = z.enum([
  "ai_extracted",
  "user_provided",
  "calculated",
  "imported",
]);
export type MetricSource = z.infer<typeof MetricSourceSchema>;

/**
 * Single metric value
 */
export const MetricSchema = z.object({
  id: z.string().uuid().optional(),
  sessionId: z.string().uuid(),
  name: z.string().min(1).max(255),
  value: z.number(),
  unit: z.string().max(50).optional(),
  minValue: z.number().optional(),
  maxValue: z.number().optional(),
  sourceType: MetricSourceSchema,
  confidence: z.number().min(0).max(1),
  perspectiveId: z.string().uuid().optional(),
  metadata: z.record(z.unknown()).optional(),
});
export type Metric = z.infer<typeof MetricSchema>;

/**
 * ROI calculation result
 */
export const ROIResultSchema = z.object({
  id: z.string().uuid().optional(),
  sessionId: z.string().uuid(),
  scenarioName: z.string(),
  baselineROI: z.number(),
  projectedROI: z.number(),
  roiDelta: z.number(),
  confidence: z.number().min(0).max(1),
  calculatedAt: z.date(),
  methodology: z.string().optional(),
});
export type ROIResult = z.infer<typeof ROIResultSchema>;

/**
 * Confidence snapshot
 */
export const ConfidenceSnapshotSchema = z.object({
  sessionId: z.string().uuid(),
  overallConfidence: z.number().min(0).max(1),
  attributeScores: z.record(z.number().min(0).max(1)),
  timestamp: z.date(),
});
export type ConfidenceSnapshot = z.infer<typeof ConfidenceSnapshotSchema>;

// TODO: Add more metrics-related schemas as needed
// - Value perspective schema
// - Friction point schema
// - Metric override request schema
'

    write_file "src/schemas/metrics.ts" "$metrics_schema"

    # Step 4: Create projects.ts
    log_step "Creating src/schemas/projects.ts"

    local projects_schema='import { z } from "zod";

/**
 * Project and session validation schemas
 *
 * Used for validating project CRUD operations and session management.
 */

/**
 * Session type
 */
export const SessionTypeSchema = z.enum(["baseline", "retrospective"]);
export type SessionType = z.infer<typeof SessionTypeSchema>;

/**
 * Session lifecycle state
 */
export const SessionStateSchema = z.enum([
  "draft",
  "active",
  "review",
  "completed",
  "archived",
]);
export type SessionState = z.infer<typeof SessionStateSchema>;

/**
 * Create project request
 */
export const CreateProjectSchema = z.object({
  name: z.string().min(1).max(255),
  description: z.string().max(2000).optional(),
  clientName: z.string().max(255).optional(),
  metadata: z.record(z.unknown()).optional(),
});
export type CreateProjectInput = z.infer<typeof CreateProjectSchema>;

/**
 * Update project request
 */
export const UpdateProjectSchema = CreateProjectSchema.partial().extend({
  id: z.string().uuid(),
  version: z.number().int().positive(),
});
export type UpdateProjectInput = z.infer<typeof UpdateProjectSchema>;

/**
 * Create session request
 */
export const CreateSessionSchema = z.object({
  projectId: z.string().uuid(),
  type: SessionTypeSchema,
  name: z.string().min(1).max(255).optional(),
});
export type CreateSessionInput = z.infer<typeof CreateSessionSchema>;

/**
 * Project with sessions
 */
export const ProjectSchema = z.object({
  id: z.string().uuid(),
  name: z.string(),
  description: z.string().optional(),
  clientName: z.string().optional(),
  sessions: z.array(
    z.object({
      id: z.string().uuid(),
      type: SessionTypeSchema,
      state: SessionStateSchema,
      createdAt: z.date(),
    })
  ),
  createdAt: z.date(),
  updatedAt: z.date(),
});
export type Project = z.infer<typeof ProjectSchema>;

// TODO: Add more project-related schemas as needed
// - Project list query params
// - Session update schema
// - Delta comparison schema
'

    write_file "src/schemas/projects.ts" "$projects_schema"

    # Step 5: Create settings.ts
    log_step "Creating src/schemas/settings.ts"

    local settings_schema='import { z } from "zod";

/**
 * Settings and feature flag validation schemas
 *
 * Used for validating application settings and feature toggle operations.
 */

/**
 * Feature flag
 */
export const FeatureFlagSchema = z.object({
  id: z.string().uuid().optional(),
  key: z.string().min(1).max(100).regex(/^[a-z][a-z0-9_]*$/, {
    message: "Key must be lowercase with underscores",
  }),
  name: z.string().min(1).max(255),
  description: z.string().max(1000).optional(),
  enabled: z.boolean(),
  config: z.record(z.unknown()).optional(),
});
export type FeatureFlag = z.infer<typeof FeatureFlagSchema>;

/**
 * Update feature flag request
 */
export const UpdateFeatureFlagSchema = z.object({
  id: z.string().uuid(),
  enabled: z.boolean().optional(),
  config: z.record(z.unknown()).optional(),
  version: z.number().int().positive(),
});
export type UpdateFeatureFlagInput = z.infer<typeof UpdateFeatureFlagSchema>;

/**
 * App setting value types
 */
export const SettingValueTypeSchema = z.enum([
  "string",
  "number",
  "boolean",
  "json",
]);
export type SettingValueType = z.infer<typeof SettingValueTypeSchema>;

/**
 * App setting
 */
export const AppSettingSchema = z.object({
  id: z.string().uuid().optional(),
  key: z.string().min(1).max(100),
  value: z.unknown(),
  description: z.string().max(1000).optional(),
  valueType: SettingValueTypeSchema,
});
export type AppSetting = z.infer<typeof AppSettingSchema>;

/**
 * Update app setting request
 */
export const UpdateAppSettingSchema = z.object({
  id: z.string().uuid(),
  value: z.unknown(),
  version: z.number().int().positive(),
});
export type UpdateAppSettingInput = z.infer<typeof UpdateAppSettingSchema>;

/**
 * Value perspective (Financial, Cultural, Customer, Employee)
 */
export const ValuePerspectiveSchema = z.object({
  id: z.string().uuid().optional(),
  key: z.string().min(1).max(100),
  name: z.string().min(1).max(255),
  description: z.string().max(1000).optional(),
  color: z.string().regex(/^#[0-9a-fA-F]{6}$/).optional(),
  sortOrder: z.number().int().min(0).optional(),
});
export type ValuePerspective = z.infer<typeof ValuePerspectiveSchema>;

// TODO: Add more settings-related schemas as needed
// - Bulk update schema
// - Settings export/import schema
'

    write_file "src/schemas/settings.ts" "$settings_schema"

    # Step 6: Update index.ts
    log_step "Updating src/schemas/index.ts"

    local index_content='/**
 * Zod validation schemas for Bloom2
 *
 * All input validation should use schemas from this module.
 *
 * @example
 * ```ts
 * import { SendMessageSchema } from "@/schemas";
 *
 * const result = SendMessageSchema.safeParse(input);
 * if (!result.success) {
 *   return { error: result.error.flatten() };
 * }
 * ```
 */

export * from "./chat";
export * from "./metrics";
export * from "./projects";
export * from "./settings";

// Re-export zod for convenience
export { z } from "zod";
'

    write_file "src/schemas/index.ts" "$index_content"

    log_success "Script $SCRIPT_ID completed"
}

main "$@"
