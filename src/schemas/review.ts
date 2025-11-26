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
