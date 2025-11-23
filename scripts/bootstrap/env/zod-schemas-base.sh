#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SH="${SCRIPT_DIR%/*}/lib/common.sh"
[[ -f "${COMMON_SH}" ]] || { echo "ERROR: common.sh not found" >&2; exit 1; }
. "${COMMON_SH}"

SCRIPT_KEY="env/zod-schemas-base.sh"

main() {
    parse_common_args "$@"
    [[ "${SHOW_HELP}" == "true" ]] && { echo "Create base Zod schema files"; exit 0; }

    log_info "=== Creating Zod Schemas ==="
    cd "${PROJECT_ROOT:-.}"
    ensure_dir "src/schemas"

    local chat='import { z } from "zod";
export const MessageRoleSchema = z.enum(["user", "assistant", "system"]);
export const ChatMessageSchema = z.object({ id: z.string().uuid().optional(), role: MessageRoleSchema, content: z.string().min(1).max(100000), createdAt: z.date().optional() });
export const SendMessageSchema = z.object({ sessionId: z.string().uuid(), content: z.string().min(1).max(10000) });
export type ChatMessage = z.infer<typeof ChatMessageSchema>;
'
    write_file_if_missing "src/schemas/chat.ts" "${chat}"

    local metrics='import { z } from "zod";
export const MetricSourceSchema = z.enum(["ai_extracted", "user_provided", "calculated"]);
export const MetricSchema = z.object({ name: z.string(), value: z.number(), unit: z.string().optional(), confidence: z.number().min(0).max(1), sourceType: MetricSourceSchema });
export type Metric = z.infer<typeof MetricSchema>;
'
    write_file_if_missing "src/schemas/metrics.ts" "${metrics}"

    local projects='import { z } from "zod";
export const CreateProjectSchema = z.object({ name: z.string().min(1).max(255), description: z.string().max(2000).optional() });
export const SessionTypeSchema = z.enum(["baseline", "retrospective"]);
export type CreateProjectInput = z.infer<typeof CreateProjectSchema>;
'
    write_file_if_missing "src/schemas/projects.ts" "${projects}"

    local settings='import { z } from "zod";
export const FeatureFlagSchema = z.object({ key: z.string(), name: z.string(), enabled: z.boolean() });
export const AppSettingSchema = z.object({ key: z.string(), value: z.unknown(), valueType: z.enum(["string", "number", "boolean", "json"]) });
'
    write_file_if_missing "src/schemas/settings.ts" "${settings}"

    local index='export * from "./chat"; export * from "./metrics"; export * from "./projects"; export * from "./settings"; export { z } from "zod";'
    write_file_if_missing "src/schemas/index.ts" "${index}"

    mark_script_success "${SCRIPT_KEY}"
    log_success "Zod schemas created"
}

main "$@"
