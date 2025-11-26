/**
 * ROI-related Zod validation schemas
 */

import { z } from 'zod';

export const ROIMetricSchema = z.object({
  name: z.string(),
  value: z.number(),
  unit: z.string(),
  min: z.number().optional(),
  max: z.number().optional(),
  confidence: z.enum(['low', 'medium', 'high']),
  source: z.enum(['user_input', 'estimated_range', 'benchmark', 'calculated']),
  extracted_from_message: z.string().optional(),
});

export const ROIResultSchema = z.object({
  session_id: z.string().uuid(),
  annual_savings: z.number(),
  roi_percent: z.number(),
  payback_months: z.number(),
  improvement_index: z.number().min(0).max(1),
  confidence_score: z.number().min(0).max(1),
  calculated_at: z.date(),
});

export type ROIMetric = z.infer<typeof ROIMetricSchema>;
export type ROIResult = z.infer<typeof ROIResultSchema>;
