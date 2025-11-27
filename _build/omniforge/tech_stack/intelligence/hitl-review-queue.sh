#!/usr/bin/env bash
#!meta
# id: intelligence/hitl-review-queue.sh
# name: hitl review queue
# phase: 4
# phase_name: Extensions & Quality
# profile_tags:
#   - tech_stack
#   - intelligence
# uses_from_omni_config:
# uses_from_omni_settings:
#   - PROJECT_ROOT
#   - INSTALL_DIR
#   - SCHEMAS_DIR
#   - LIB_DIR
# required_vars:
#   - PROJECT_ROOT
#   - INSTALL_DIR
#   - SCHEMAS_DIR
#   - LIB_DIR
# top_flags:
# dependencies:
#   packages:
#     - zod
#   dev_packages: []
#!endmeta

# =============================================================================
# tech_stack/intelligence/hitl-review-queue.sh - HITL Review Queue
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Purpose: Set up Human-in-the-Loop review queue and governance
# Phase: 4
# Reference: PRD Section 6.8 - Human-in-the-Loop (HITL) Governance
#
# Required: PROJECT_ROOT
#
# Dependencies:
#   lib/common.sh
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"
if command -v parse_stack_flags >/dev/null 2>&1; then
    parse_stack_flags "$@"
fi

readonly SCRIPT_ID="intelligence/hitl-review-queue"
readonly SCRIPT_NAME="HITL Review Queue Setup"

if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_skip "DRY_RUN: skipping ${SCRIPT_NAME}"
    exit 0
fi

if has_script_succeeded "${SCRIPT_ID}"; then
    log_skip "${SCRIPT_NAME} (already completed)"
    exit 0
fi

log_step "${SCRIPT_NAME}"

LIB_DIR="${INSTALL_DIR}/src/lib"
ensure_dir "${LIB_DIR}" "Library directory"

# =============================================================================
# REVIEW QUEUE LOGIC
# =============================================================================

write_file "${LIB_DIR}/reviewQueue.ts" <<'EOF'
/**
 * HITL Review Queue
 * Manages review items, reviewer actions, and audit trails
 * Reference: Bloom2 PRD Section 6.8
 */

import { z } from 'zod';

/**
 * Review Item Types
 */
export type ReviewItemType =
  | 'low_confidence_metric'
  | 'contradiction'
  | 'flagged_assumption'
  | 'outlier_value'
  | 'missing_data';

/**
 * Review Item Schema
 */
export const ReviewItemSchema = z.object({
  id: z.string().uuid(),
  session_id: z.string().uuid(),
  type: z.enum([
    'low_confidence_metric',
    'contradiction',
    'flagged_assumption',
    'outlier_value',
    'missing_data',
  ]),

  // What triggered the review
  trigger_reason: z.string(),
  affected_metric: z.string().optional(),
  severity: z.enum(['info', 'warning', 'critical']),
  priority: z.number().min(1).max(100), // Higher = review first

  // Original AI suggestion
  ai_suggested_value: z.number().optional(),
  ai_suggested_text: z.string().optional(),

  // Context
  conversation_context: z.string().optional(),
  related_items: z.array(z.string()).optional(),

  // Status
  status: z.enum(['pending', 'in_review', 'resolved', 'dismissed']),
  created_at: z.date(),
});

export type ReviewItem = z.infer<typeof ReviewItemSchema>;

/**
 * Reviewer Action (what the human decided)
 */
export const ReviewerActionSchema = z.object({
  id: z.string().uuid(),
  review_item_id: z.string().uuid(),
  session_id: z.string().uuid(),

  // Who decided
  reviewer_id: z.string(),
  reviewed_at: z.date(),

  // What they decided
  action: z.enum(['accept', 'adjust', 'reject', 'replace', 'mark_as_assumption', 'escalate']),

  // New value (if adjusting/replacing)
  new_value?: z.number() | z.string(),

  // Rationale
  rationale: z.string(),

  // Impact on metrics
  metrics_affected: z.array(z.string()),
  roi_impact: z.number().optional(), // How much ROI changed (%)
});

export type ReviewerAction = z.infer<typeof ReviewerActionSchema>;

/**
 * Audit Log Entry (immutable record)
 */
export const AuditLogEntrySchema = z.object({
  id: z.string().uuid(),
  session_id: z.string().uuid(),
  timestamp: z.date(),

  // What changed
  change_type: z.enum(['metric_extracted', 'metric_adjusted', 'assumption_added', 'contradiction_resolved']),
  target_metric: z.string().optional(),

  // Before/after
  old_value: z.any(),
  new_value: z.any(),

  // Who and why
  actor: z.string(), // 'melissa' or reviewer_id
  actor_type: z.enum(['ai', 'human']),
  reason: z.string(),

  // Traceability
  review_item_id: z.string().optional(),
});

export type AuditLogEntry = z.infer<typeof AuditLogEntrySchema>;

/**
 * Create review items from confidence snapshot
 */
export function createReviewItems(input: {
  session_id: string;
  high_uncertainty_metrics: Array<{ name: string; confidence: number }>;
  contradictions: Array<{ metric1: string; metric2: string; description: string }>;
  flagged_assumptions: Array<{ assumption: string; reason: string }>;
}): ReviewItem[] {
  const items: ReviewItem[] = [];
  const now = new Date();

  // High uncertainty metrics (priority based on impact estimate)
  input.high_uncertainty_metrics.forEach((m, idx) => {
    items.push({
      id: crypto.randomUUID(),
      session_id: input.session_id,
      type: 'low_confidence_metric',
      trigger_reason: `Confidence score (${(m.confidence * 100).toFixed(0)}%) below threshold`,
      affected_metric: m.name,
      severity: m.confidence < 0.4 ? 'critical' : 'warning',
      priority: 80 - idx * 5, // First metrics reviewed first
      status: 'pending',
      created_at: now,
    });
  });

  // Contradictions (critical priority)
  input.contradictions.forEach((c) => {
    items.push({
      id: crypto.randomUUID(),
      session_id: input.session_id,
      type: 'contradiction',
      trigger_reason: `Conflicting data: ${c.metric1} vs ${c.metric2}`,
      ai_suggested_text: c.description,
      severity: 'critical',
      priority: 90, // Review contradictions first
      status: 'pending',
      created_at: now,
    });
  });

  // Flagged assumptions
  input.flagged_assumptions.forEach((a) => {
    items.push({
      id: crypto.randomUUID(),
      session_id: input.session_id,
      type: 'flagged_assumption',
      trigger_reason: `Assumption flagged: ${a.reason}`,
      ai_suggested_text: a.assumption,
      severity: 'warning',
      priority: 70,
      status: 'pending',
      created_at: now,
    });
  });

  // Sort by priority (highest first)
  return items.sort((a, b) => b.priority - a.priority);
}

/**
 * Apply reviewer action and update session state
 */
export function applyReviewerAction(input: {
  action: ReviewerAction;
  current_metrics: Map<string, number>;
  current_confidence: number;
}): {
  updated_metrics: Map<string, number>;
  updated_confidence: number;
  audit_log_entry: AuditLogEntry;
} {
  const { action, current_metrics, current_confidence } = input;

  // Create audit entry
  const audit_log_entry: AuditLogEntry = {
    id: crypto.randomUUID(),
    session_id: action.session_id,
    timestamp: action.reviewed_at,
    change_type: 'metric_adjusted',
    target_metric: action.metrics_affected[0],
    old_value: action.metrics_affected[0] ? current_metrics.get(action.metrics_affected[0]) : null,
    new_value: action.new_value ?? null,
    actor: action.reviewer_id,
    actor_type: 'human',
    reason: action.rationale,
    review_item_id: action.review_item_id,
  };

  // Apply action
  const updated_metrics = new Map(current_metrics);
  if (action.action === 'adjust' || action.action === 'replace') {
    action.metrics_affected.forEach((m) => {
      if (typeof action.new_value === 'number') {
        updated_metrics.set(m, action.new_value);
      }
    });
  } else if (action.action === 'reject') {
    // Remove from consideration (mark as low confidence)
    action.metrics_affected.forEach((m) => {
      updated_metrics.delete(m);
    });
  }

  // Recalculate confidence (simplified: adjust by action impact)
  let updated_confidence = current_confidence;
  if (action.action === 'accept') {
    updated_confidence = Math.min(1, current_confidence + 0.05); // Slight boost from validation
  } else if (action.action === 'adjust') {
    updated_confidence = Math.max(0, current_confidence - 0.1); // Slight penalty for correction
  }

  return {
    updated_metrics,
    updated_confidence,
    audit_log_entry,
  };
}

/**
 * Generate review summary for reviewer
 */
export function generateReviewSummary(items: ReviewItem[]): {
  total_items: number;
  critical_count: number;
  warning_count: number;
  by_type: Record<ReviewItemType, number>;
  next_review_item?: ReviewItem;
} {
  const by_type: Record<ReviewItemType, number> = {
    low_confidence_metric: 0,
    contradiction: 0,
    flagged_assumption: 0,
    outlier_value: 0,
    missing_data: 0,
  };

  items.forEach((item) => {
    if (item.status === 'pending') {
      by_type[item.type]++;
    }
  });

  const critical_count = items.filter((i) => i.severity === 'critical' && i.status === 'pending').length;
  const warning_count = items.filter((i) => i.severity === 'warning' && i.status === 'pending').length;
  const pending_items = items.filter((i) => i.status === 'pending').sort((a, b) => b.priority - a.priority);

  return {
    total_items: items.length,
    critical_count,
    warning_count,
    by_type,
    next_review_item: pending_items[0],
  };
}
EOF

log_success "Created HITL review queue with audit trail"

# =============================================================================
# REVIEW QUEUE SCHEMAS
# =============================================================================

SCHEMAS_DIR="${LIB_DIR}/../schemas"
ensure_dir "${SCHEMAS_DIR}" "Schemas directory"

write_file "${SCHEMAS_DIR}/review.ts" <<'EOF'
/**
 * Review and HITL-related validation schemas
 */

import { z } from 'zod';

export const ReviewActionTypeSchema = z.enum([
  'accept',
  'adjust',
  'reject',
  'replace',
  'mark_as_assumption',
  'escalate',
]);

export const ReviewItemTypeSchema = z.enum([
  'low_confidence_metric',
  'contradiction',
  'flagged_assumption',
  'outlier_value',
  'missing_data',
]);

export const ReviewerActionInputSchema = z.object({
  review_item_id: z.string().uuid(),
  action: ReviewActionTypeSchema,
  new_value: z.union([z.number(), z.string()]).optional(),
  rationale: z.string().min(10),
  metrics_affected: z.array(z.string()),
});

export const AuditLogQuerySchema = z.object({
  session_id: z.string().uuid().optional(),
  metric_name: z.string().optional(),
  actor_id: z.string().optional(),
  change_type: z.string().optional(),
  limit: z.number().min(1).max(100).default(50),
  offset: z.number().min(0).default(0),
});

export type ReviewActionType = z.infer<typeof ReviewActionTypeSchema>;
export type ReviewItemType = z.infer<typeof ReviewItemTypeSchema>;
export type ReviewerActionInput = z.infer<typeof ReviewerActionInputSchema>;
export type AuditLogQuery = z.infer<typeof AuditLogQuerySchema>;
EOF

log_success "Created review queue validation schemas"

# =============================================================================
# MARK SUCCESS
# =============================================================================

mark_script_success "${SCRIPT_ID}"
log_success "${SCRIPT_NAME} completed"

exit 0
