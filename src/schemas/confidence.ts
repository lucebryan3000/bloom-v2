/**
 * Confidence-related validation schemas
 */

import { z } from 'zod';

export const ConfidenceLevelSchema = z.enum(['low', 'medium', 'high']);

export const MetricConfidenceSchema = z.object({
  metric_name: z.string(),
  metric_value: z.number(),
  unit: z.string(),
  confidence_level: ConfidenceLevelSchema,
  confidence_score: z.number().min(0).max(1),
  flags: z.array(z.string()).optional(),
});

export const SessionConfidenceSnapshotSchema = z.object({
  session_id: z.string().uuid(),
  timestamp: z.string().datetime(),
  overall_confidence: z.number().min(0).max(1),
  data_completeness: z.number().min(0).max(1),
  high_uncertainty_metrics: z.array(z.string()),
  flagged_items: z.array(z.string()),
  ready_for_review: z.boolean(),
  ready_for_export: z.boolean(),
});

export type ConfidenceLevel = z.infer<typeof ConfidenceLevelSchema>;
export type MetricConfidenceInput = z.infer<typeof MetricConfidenceSchema>;
export type SessionConfidenceSnapshot = z.infer<typeof SessionConfidenceSnapshotSchema>;
