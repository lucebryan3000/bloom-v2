#!/usr/bin/env bash
# =============================================================================
# Script: intelligence/roi-engine.sh
# Purpose: Set up ROI calculation engine
# Reference: PRD Section 6.5 - ROI Engine (Value Computation)
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"

readonly SCRIPT_ID="intelligence/roi-engine"
readonly SCRIPT_NAME="ROI Engine Setup"

if has_script_succeeded "${SCRIPT_ID}"; then
    log_skip "${SCRIPT_NAME} (already completed)"
    exit 0
fi

log_step "${SCRIPT_NAME}"

# =============================================================================
# CREATE LIB DIRECTORY & ROI CALCULATOR
# =============================================================================

LIB_DIR="${PROJECT_ROOT}/src/lib"
ensure_dir "${LIB_DIR}" "Library directory"

# ROI Engine Main File
write_file "${LIB_DIR}/roi.ts" <<'EOF'
/**
 * ROI Engine
 * Deterministic ROI and Improvement Index calculation
 * Reference: Bloom2 PRD Section 6.5, ROI Formula Spec
 */

import { z } from 'zod';

/**
 * ROI Input Schema - All metrics required for ROI calculation
 */
export const ROIInputSchema = z.object({
  // Process baseline (current state)
  volume_per_period: z.number().positive().describe('Volume per period (e.g., transactions/month)'),
  period_unit: z.enum(['week', 'month', 'year']).default('month'),
  cycle_time_minutes: z.number().positive().describe('Average cycle time in minutes per unit'),

  // Team impact
  team_size_affected: z.number().positive().describe('Number of people affected'),
  percent_time_on_process: z.number().min(0).max(100).describe('% of their time on this process'),
  labor_cost_per_hour: z.number().positive().describe('Fully-loaded labor cost per hour'),

  // Error & rework impact
  error_rate_percent: z.number().min(0).max(100).describe('Current error rate (%)'),
  rework_time_minutes: z.number().nonnegative().describe('Time to fix errors (minutes)'),
  error_cost_per_incident: z.number().nonnegative().describe('Direct cost per error ($)'),

  // Proposed improvement
  improvement_efficiency_percent: z.number().min(0).max(100).describe('Time savings from improvement (%)'),
  improvement_error_reduction_percent: z.number().min(0).max(100).describe('Error reduction (%)'),
  implementation_cost: z.number().nonnegative().describe('Cost to implement (one-time, $)'),

  // Assumptions
  assumptions: z.array(z.string()).optional(),
  confidence_score: z.number().min(0).max(1).optional(),
});

export type ROIInput = z.infer<typeof ROIInputSchema>;

/**
 * ROI Output - Calculated results
 */
export interface ROIOutput {
  // Annual savings (conservative, base, aggressive)
  annual_time_saved_hours: {
    conservative: number;
    base: number;
    aggressive: number;
  };
  annual_labor_savings: {
    conservative: number;
    base: number;
    aggressive: number;
  };
  annual_error_cost_reduction: {
    conservative: number;
    base: number;
    aggressive: number;
  };
  total_annual_savings: {
    conservative: number;
    base: number;
    aggressive: number;
  };

  // Payback & ROI
  payback_period_months: {
    conservative: number;
    base: number;
    aggressive: number;
  };
  roi_percent: {
    conservative: number;
    base: number;
    aggressive: number;
  };

  // Multi-dimensional improvement index
  improvement_index: {
    financial: number; // 0-1
    operational: number; // 0-1
    human: number; // 0-1
    composite: number; // 0-1 (weighted average)
  };

  // Metadata
  calculation_date: string;
  input_checksum: string;
  confidence: number;
}

/**
 * Calculate annual time saved (in hours)
 * Formula: (Volume × Cycle Time × Efficiency Gain) / 60 minutes
 */
function calculateTimeSaved(input: ROIInput): {
  conservative: number;
  base: number;
  aggressive: number;
} {
  const annualVolume = annualizeVolume(input.volume_per_period, input.period_unit);
  const totalMinutesPerYear = annualVolume * input.cycle_time_minutes;

  // Conservative: 80% of projected savings
  const conservative = (totalMinutesPerYear * (input.improvement_efficiency_percent * 0.8)) / 60;
  // Base: 100% of projected savings
  const base = (totalMinutesPerYear * input.improvement_efficiency_percent) / 60;
  // Aggressive: 120% of projected savings
  const aggressive = (totalMinutesPerYear * (input.improvement_efficiency_percent * 1.2)) / 60;

  return { conservative, base, aggressive };
}

/**
 * Calculate annual labor cost savings
 */
function calculateLaborSavings(input: ROIInput, timeSaved: {
  conservative: number;
  base: number;
  aggressive: number;
}): {
  conservative: number;
  base: number;
  aggressive: number;
} {
  const laborCostPerHour = input.labor_cost_per_hour;

  // Apply team size and time allocation factor
  const allocationFactor = (input.team_size_affected * input.percent_time_on_process) / 100;

  return {
    conservative: timeSaved.conservative * laborCostPerHour * allocationFactor,
    base: timeSaved.base * laborCostPerHour * allocationFactor,
    aggressive: timeSaved.aggressive * laborCostPerHour * allocationFactor,
  };
}

/**
 * Calculate error cost reduction
 */
function calculateErrorReduction(input: ROIInput): {
  conservative: number;
  base: number;
  aggressive: number;
} {
  const annualVolume = annualizeVolume(input.volume_per_period, input.period_unit);
  const currentErrorCount = annualVolume * (input.error_rate_percent / 100);

  // Cost per error = direct cost + rework time cost
  const reworkCostPerError = (input.rework_time_minutes / 60) * input.labor_cost_per_hour;
  const totalErrorCost = input.error_cost_per_incident + reworkCostPerError;
  const currentAnnualErrorCost = currentErrorCount * totalErrorCost;

  // Reduction scenarios
  const conservative = currentAnnualErrorCost * (input.improvement_error_reduction_percent * 0.7);
  const base = currentAnnualErrorCost * input.improvement_error_reduction_percent;
  const aggressive = currentAnnualErrorCost * (input.improvement_error_reduction_percent * 1.2);

  return { conservative, base, aggressive };
}

/**
 * Convert volume to annual
 */
function annualizeVolume(volume: number, unit: 'week' | 'month' | 'year'): number {
  switch (unit) {
    case 'week':
      return volume * 52;
    case 'month':
      return volume * 12;
    case 'year':
      return volume;
  }
}

/**
 * Calculate ROI percentage
 */
function calculateROIPercent(totalSavings: number, implementationCost: number): number {
  if (implementationCost === 0) return 100; // Free improvement
  return ((totalSavings - implementationCost) / implementationCost) * 100;
}

/**
 * Calculate payback period in months
 */
function calculatePaybackMonths(totalSavings: number, implementationCost: number): number {
  if (totalSavings === 0) return Infinity;
  return (implementationCost / (totalSavings / 12));
}

/**
 * Calculate multi-dimensional Improvement Index
 * Combines financial, operational, and human value
 */
function calculateImprovementIndex(input: ROIInput, output: ROIOutput): {
  financial: number;
  operational: number;
  human: number;
  composite: number;
} {
  // Financial: ROI percentage normalized to 0-1
  const baseROI = output.roi_percent.base;
  const financialScore = Math.min(baseROI / 100, 1); // Cap at 1.0

  // Operational: time savings + error reduction
  const timeSavingsPercent = input.improvement_efficiency_percent;
  const errorReductionPercent = input.improvement_error_reduction_percent;
  const operationalScore = (timeSavingsPercent + errorReductionPercent) / 200; // Both as %, normalize

  // Human: stress/burnout reduction (estimated from time freed + error reduction)
  // Assumption: More time + fewer errors = lower stress
  const stressReliefFactor = (input.improvement_efficiency_percent + input.improvement_error_reduction_percent) / 100;
  const humanScore = Math.min(stressReliefFactor, 1);

  // Composite: weighted average (finance 40%, operational 35%, human 25%)
  const composite = financialScore * 0.4 + operationalScore * 0.35 + humanScore * 0.25;

  return {
    financial: Math.min(financialScore, 1),
    operational: Math.min(operationalScore, 1),
    human: Math.min(humanScore, 1),
    composite: Math.min(composite, 1),
  };
}

/**
 * Main ROI calculation function
 */
export function calculateROI(input: ROIInput): ROIOutput {
  // Validate input
  const validated = ROIInputSchema.parse(input);

  // Calculate components
  const timeSaved = calculateTimeSaved(validated);
  const laborSavings = calculateLaborSavings(validated, timeSaved);
  const errorReduction = calculateErrorReduction(validated);

  // Total annual savings
  const totalSavings = {
    conservative: laborSavings.conservative + errorReduction.conservative,
    base: laborSavings.base + errorReduction.base,
    aggressive: laborSavings.aggressive + errorReduction.aggressive,
  };

  // ROI and payback
  const roiPercent = {
    conservative: calculateROIPercent(totalSavings.conservative, validated.implementation_cost),
    base: calculateROIPercent(totalSavings.base, validated.implementation_cost),
    aggressive: calculateROIPercent(totalSavings.aggressive, validated.implementation_cost),
  };

  const paybackMonths = {
    conservative: calculatePaybackMonths(totalSavings.conservative, validated.implementation_cost),
    base: calculatePaybackMonths(totalSavings.base, validated.implementation_cost),
    aggressive: calculatePaybackMonths(totalSavings.aggressive, validated.implementation_cost),
  };

  const output: ROIOutput = {
    annual_time_saved_hours: timeSaved,
    annual_labor_savings: laborSavings,
    annual_error_cost_reduction: errorReduction,
    total_annual_savings: totalSavings,
    payback_period_months: paybackMonths,
    roi_percent: roiPercent,
    improvement_index: {
      financial: 0,
      operational: 0,
      human: 0,
      composite: 0,
    },
    calculation_date: new Date().toISOString(),
    input_checksum: JSON.stringify(input),
    confidence: input.confidence_score ?? 0.75,
  };

  // Calculate improvement index
  output.improvement_index = calculateImprovementIndex(input, output);

  return output;
}

/**
 * Format ROI for narrative (business language)
 */
export function formatROIForNarrative(roi: ROIOutput): string {
  const base = roi.total_annual_savings.base;
  const roi_pct = roi.roi_percent.base;
  const payback = roi.payback_period_months.base;

  return `
Based on the metrics captured, implementing this improvement is estimated to:
- Save **$${Math.round(base).toLocaleString()}** in annual capacity
- Deliver a **${Math.round(roi_pct)}% ROI** over 3 years
- Achieve payback in **${Math.round(payback)} months**

The Improvement Index (${(roi.improvement_index.composite * 100).toFixed(0)}%) reflects financial, operational, and human value.
  `.trim();
}
EOF

log_success "Created ROI engine with deterministic calculations"

# =============================================================================
# ADD TYPES TO SCHEMA
# =============================================================================

SCHEMAS_DIR="${LIB_DIR}/../schemas"
ensure_dir "${SCHEMAS_DIR}" "Schemas directory"

write_file "${SCHEMAS_DIR}/roi.ts" <<'EOF'
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
EOF

log_success "Created ROI validation schemas"

# =============================================================================
# MARK SUCCESS
# =============================================================================

mark_script_success "${SCRIPT_ID}"
log_success "${SCRIPT_NAME} completed"

exit 0
