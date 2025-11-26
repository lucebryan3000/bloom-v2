#!/usr/bin/env bash
#!meta
# id: intelligence/confidence-engine.sh
# name: engine.sh - Confidence & Uncertainty Engine
# phase: 4
# phase_name: Extensions & Quality
# profile_tags:
#   - tech_stack
#   - intelligence
# uses_from_omni_config:
# uses_from_omni_settings:
#   - INSTALL_DIR
#   - SCHEMAS_DIR
# top_flags:
#   - --dry-run
#   - --skip-install
#   - --dev-only
#   - --no-dev
#   - --force
#   - --no-verify
# dependencies:
#   packages:
#     -
#   dev_packages:
#     -
#!endmeta

# =============================================================================
# tech_stack/intelligence/confidence-engine.sh - Confidence & Uncertainty Engine
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Purpose: Set up confidence scoring and uncertainty quantification
# Phase: 4
# Reference: PRD Section 6.6 - Confidence & Uncertainty Engine
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

readonly SCRIPT_ID="intelligence/confidence-engine"
readonly SCRIPT_NAME="Confidence & Uncertainty Engine Setup"

if has_script_succeeded "${SCRIPT_ID}"; then
    log_skip "${SCRIPT_NAME} (already completed)"
    exit 0
fi

log_step "${SCRIPT_NAME}"

LIB_DIR="${INSTALL_DIR}/src/lib"
ensure_dir "${LIB_DIR}" "Library directory"

# =============================================================================
# CONFIDENCE ENGINE
# =============================================================================

write_file "${LIB_DIR}/confidence.ts" <<'EOF'
/**
 * Confidence & Uncertainty Engine
 * Scores data quality, identifies high-uncertainty metrics
 * Reference: Bloom2 PRD Section 6.6
 */

import { z } from 'zod';

/**
 * Confidence Factors
 */
export const ConfidenceFactors = {
  DATA_QUALITY: {
    DIRECT_MEASUREMENT: 1.0, // User measured/verified
    USER_INPUT: 0.85, // User stated (not measured)
    ESTIMATED_RANGE: 0.65, // User gave range/estimate
    BENCHMARK: 0.5, // Industry benchmark only
  },
  MEASUREMENT_PRECISION: {
    EXACT: 1.0, // Single value, precise
    NARROW_RANGE: 0.8, // Range < 20%
    WIDE_RANGE: 0.6, // Range 20-50%
    VERY_WIDE_RANGE: 0.4, // Range > 50%
  },
  STAKEHOLDER_AGREEMENT: {
    UNANIMOUS: 1.0, // All agree
    MAJORITY: 0.85, // Most agree
    SPLIT: 0.6, // Some disagreement
    CONTRADICTORY: 0.3, // Conflicting inputs
  },
  SOURCE_RELIABILITY: {
    DATA_SYSTEM: 1.0, // From system/report
    SUBJECT_MATTER_EXPERT: 0.9, // Expert knowledge
    GENERAL_STAFF: 0.7, // General employee
    GUESS: 0.4, // Unsure/guess
  },
};

/**
 * Metric Confidence Snapshot
 */
export interface MetricConfidence {
  metric_name: string;
  metric_value: number;
  unit: string;

  // Scoring factors
  data_quality_score: number; // 0-1
  measurement_precision_score: number; // 0-1
  stakeholder_agreement_score: number; // 0-1
  source_reliability_score: number; // 0-1

  // Weights
  weights: {
    data_quality: number;
    measurement_precision: number;
    stakeholder_agreement: number;
    source_reliability: number;
  };

  // Overall confidence
  confidence_score: number; // 0-1
  confidence_level: 'low' | 'medium' | 'high';

  // Uncertainty markers
  has_contradiction: boolean;
  contradiction_description?: string;
  flags: string[]; // ['wide_range', 'low_agreement', 'benchmark_only', ...]
}

/**
 * Session-Level Confidence Snapshot
 */
export interface SessionConfidenceSnapshot {
  session_id: string;
  timestamp: string;

  // Per-metric confidence
  metric_confidences: MetricConfidence[];

  // Aggregate scores
  overall_confidence: number; // Weighted average
  data_completeness: number; // How many key metrics captured? (0-1)
  assumption_clarity: number; // How clear are assumptions? (0-1)

  // Risk assessment
  high_uncertainty_metrics: string[]; // Metrics with confidence < 0.6
  flagged_items: string[]; // Items requiring review

  // Recommendation
  ready_for_review: boolean;
  ready_for_export: boolean;
  review_queue_items: number;
}

/**
 * Calculate confidence for a single metric
 */
export function calculateMetricConfidence(input: {
  metric_name: string;
  metric_value: number;
  unit: string;
  data_quality_score?: number;
  measurement_precision_score?: number;
  stakeholder_agreement_score?: number;
  source_reliability_score?: number;
}): MetricConfidence {
  const {
    metric_name,
    metric_value,
    unit,
    data_quality_score = 0.7,
    measurement_precision_score = 0.7,
    stakeholder_agreement_score = 0.8,
    source_reliability_score = 0.8,
  } = input;

  // Default weights (PRD Section 6.6)
  const weights = {
    data_quality: 0.3,
    measurement_precision: 0.25,
    stakeholder_agreement: 0.2,
    source_reliability: 0.25,
  };

  // Weighted average confidence
  const confidence_score =
    data_quality_score * weights.data_quality +
    measurement_precision_score * weights.measurement_precision +
    stakeholder_agreement_score * weights.stakeholder_agreement +
    source_reliability_score * weights.source_reliability;

  const confidence_level =
    confidence_score > 0.75 ? ('high' as const) :
    confidence_score > 0.55 ? ('medium' as const) :
    ('low' as const);

  // Identify flags
  const flags: string[] = [];
  if (measurement_precision_score < 0.5) flags.push('wide_range');
  if (stakeholder_agreement_score < 0.6) flags.push('low_agreement');
  if (data_quality_score < 0.6) flags.push('weak_data_source');
  if (source_reliability_score < 0.6) flags.push('unreliable_source');

  return {
    metric_name,
    metric_value,
    unit,
    data_quality_score,
    measurement_precision_score,
    stakeholder_agreement_score,
    source_reliability_score,
    weights,
    confidence_score: Math.max(0, Math.min(1, confidence_score)),
    confidence_level,
    has_contradiction: false,
    flags,
  };
}

/**
 * Create session confidence snapshot
 */
export function createSessionConfidenceSnapshot(input: {
  session_id: string;
  metric_confidences: MetricConfidence[];
  extracted_metrics_count: number;
  total_key_metrics: number; // e.g., 8
  unresolved_contradictions: number;
  assumptions_documented: boolean;
}): SessionConfidenceSnapshot {
  const {
    session_id,
    metric_confidences,
    extracted_metrics_count,
    total_key_metrics,
    unresolved_contradictions,
    assumptions_documented,
  } = input;

  // Overall confidence: average of all metrics
  const overallConfidence =
    metric_confidences.length > 0
      ? metric_confidences.reduce((sum, m) => sum + m.confidence_score, 0) / metric_confidences.length
      : 0;

  // Data completeness: how many key metrics captured?
  const dataCompleteness = Math.min(extracted_metrics_count / total_key_metrics, 1);

  // Assumption clarity: based on documentation
  const assumptionClarity = assumptions_documented ? 0.85 : 0.5;

  // High uncertainty metrics
  const highUncertaintyMetrics = metric_confidences
    .filter((m) => m.confidence_score < 0.6)
    .map((m) => m.metric_name);

  // Flagged items requiring review
  const flaggedItems: string[] = [];
  if (unresolved_contradictions > 0) {
    flaggedItems.push(`${unresolved_contradictions} unresolved contradictions`);
  }
  metric_confidences.forEach((m) => {
    if (m.has_contradiction) {
      flaggedItems.push(`${m.metric_name}: contradiction`);
    }
    m.flags.forEach((flag) => {
      flaggedItems.push(`${m.metric_name}: ${flag}`);
    });
  });

  // Readiness assessment
  const readyForReview = overallConfidence > 0.6 && unresolved_contradictions === 0;
  const readyForExport = overallConfidence > 0.75 && unresolved_contradictions === 0;

  return {
    session_id,
    timestamp: new Date().toISOString(),
    metric_confidences,
    overall_confidence: Math.max(0, Math.min(1, overallConfidence)),
    data_completeness: dataCompleteness,
    assumption_clarity: assumptionClarity,
    high_uncertainty_metrics: highUncertaintyMetrics,
    flagged_items: flaggedItems.slice(0, 10), // Limit to top 10
    ready_for_review: readyForReview,
    ready_for_export: readyForExport,
    review_queue_items: flaggedItems.length,
  };
}

/**
 * Get confidence narrative explanation
 */
export function getConfidenceNarrative(snapshot: SessionConfidenceSnapshot): string {
  const overall = (snapshot.overall_confidence * 100).toFixed(0);
  const completeness = (snapshot.data_completeness * 100).toFixed(0);

  let narrative = `## Confidence & Assumptions\n\n`;
  narrative += `**Overall Confidence: ${overall}%**\n\n`;
  narrative += `Data completeness: ${completeness}% of key metrics captured.\n\n`;

  if (snapshot.high_uncertainty_metrics.length > 0) {
    narrative += `**Areas of Uncertainty:**\n`;
    snapshot.high_uncertainty_metrics.forEach((m) => {
      narrative += `- ${m}: Low confidence (based on estimates or limited data)\n`;
    });
    narrative += `\n`;
  }

  if (snapshot.flagged_items.length > 0) {
    narrative += `**Items Requiring Attention:**\n`;
    snapshot.flagged_items.forEach((item) => {
      narrative += `- ${item}\n`;
    });
    narrative += `\n`;
  }

  narrative += `**Interpretation:**\n`;
  if (snapshot.overall_confidence > 0.8) {
    narrative += `This business case is based on solid inputs and measured data. ROI projections are reliable.`;
  } else if (snapshot.overall_confidence > 0.6) {
    narrative += `This case is based on reasonable estimates from subject matter experts. Some uncertainty remains; consider follow-up measurement.`;
  } else {
    narrative += `This case is based on limited data and high estimates. Before investing, validate key assumptions with actual measurement.`;
  }

  return narrative;
}
EOF

log_success "Created confidence engine with uncertainty quantification"

# =============================================================================
# CONFIDENCE VALIDATION SCHEMAS
# =============================================================================

SCHEMAS_DIR="${LIB_DIR}/../schemas"
ensure_dir "${SCHEMAS_DIR}" "Schemas directory"

write_file "${SCHEMAS_DIR}/confidence.ts" <<'EOF'
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
EOF

log_success "Created confidence validation schemas"

# =============================================================================
# MARK SUCCESS
# =============================================================================

mark_script_success "${SCRIPT_ID}"
log_success "${SCRIPT_NAME} completed"

exit 0
