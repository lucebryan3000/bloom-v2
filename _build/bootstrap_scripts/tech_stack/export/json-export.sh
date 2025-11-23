#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"

readonly SCRIPT_ID="export/json-export"
readonly SCRIPT_NAME="JSON Export Setup"

if has_script_succeeded "${SCRIPT_ID}"; then
    log_skip "${SCRIPT_NAME} (already completed)"
    exit 0
fi

log_step "${SCRIPT_NAME}"

EXPORT_DIR="${PROJECT_ROOT}/src/lib/export"
ensure_dir "${EXPORT_DIR}" "Export directory"

write_file "${EXPORT_DIR}/json.ts" <<'EOF'
/**
 * JSON Export Formatter
 * Generates machine-readable JSON for downstream integrations
 */

import type { BusinessCase, ExportResult } from './types';
import { generateFilename } from './utils';

/**
 * JSON Export Schema (per PRD Section 6.12 - FR-EXP-4)
 */
export interface JSONExport {
  version: string;
  generated_at: string;

  // Process metadata
  process: {
    name: string;
    description: string;
    department: string;
    participants: string[];
  };

  // Current and future states
  states: {
    current: {
      description: string;
      volume_per_period: number;
      period_unit: string;
      cycle_time_minutes: number;
      team_size: number;
      annual_cost: number;
    };
    proposed: {
      description: string;
      change_type: string;
      implementation_cost: number;
      timeline_weeks: number;
    };
  };

  // Metrics extracted from conversation
  metrics: Array<{
    name: string;
    value: number;
    unit: string;
    min?: number;
    max?: number;
    confidence: 'low' | 'medium' | 'high';
    source: 'user_input' | 'estimated_range' | 'benchmark';
  }>;

  // ROI results (all scenarios)
  roi: {
    annual_savings: {
      conservative: number;
      base: number;
      aggressive: number;
    };
    roi_percent: {
      conservative: number;
      base: number;
      aggressive: number;
    };
    payback_period_months: {
      conservative: number;
      base: number;
      aggressive: number;
    };
    improvement_index: {
      financial: number;
      operational: number;
      human: number;
      composite: number;
    };
  };

  // Confidence & data quality
  confidence: {
    overall_score: number;
    data_completeness: number;
    high_uncertainty_metrics: string[];
    flagged_items: string[];
  };

  // Assumptions and risks
  assumptions: Array<{
    assumption: string;
    impact: 'low' | 'medium' | 'high';
    confidence: number;
  }>;

  risks: Array<{
    risk: string;
    mitigation: string;
    likelihood: 'low' | 'medium' | 'high';
  }>;

  // Recommendation
  recommendation: {
    action: 'strong_recommend' | 'recommend' | 'consider' | 'defer' | 'not_recommended';
    rationale: string;
    confidence_level: number;
  };
}

/**
 * Convert BusinessCase to JSON Export
 */
export function convertToJSONExport(businessCase: BusinessCase): JSONExport {
  const roi = businessCase.roi_results;

  return {
    version: '1.0',
    generated_at: businessCase.generated_at,

    process: {
      name: businessCase.process_name,
      description: businessCase.process_description,
      department: businessCase.department,
      participants: businessCase.participants,
    },

    states: {
      current: {
        description: businessCase.narrative.current_state_narrative,
        volume_per_period: businessCase.current_state.volume_per_period,
        period_unit: businessCase.current_state.period_unit,
        cycle_time_minutes: businessCase.current_state.cycle_time,
        team_size: businessCase.current_state.team_size,
        annual_cost: businessCase.current_state.annual_cost,
      },
      proposed: {
        description: businessCase.narrative.proposed_change_narrative,
        change_type: businessCase.proposed_change.change_type,
        implementation_cost: businessCase.proposed_change.implementation_cost,
        timeline_weeks: businessCase.proposed_change.timeline_weeks,
      },
    },

    metrics: businessCase.metrics,

    roi: {
      annual_savings: roi.total_annual_savings,
      roi_percent: roi.roi_percent,
      payback_period_months: roi.payback_period_months,
      improvement_index: roi.improvement_index,
    },

    confidence: {
      overall_score: businessCase.confidence_snapshot.overall_confidence,
      data_completeness: businessCase.confidence_snapshot.data_completeness,
      high_uncertainty_metrics: businessCase.confidence_snapshot.high_uncertainty_metrics,
      flagged_items: businessCase.confidence_snapshot.flagged_items,
    },

    assumptions: businessCase.key_assumptions,
    risks: businessCase.key_risks,

    recommendation: {
      action: deriveRecommendationAction(roi.roi_percent.base, businessCase.confidence_snapshot.overall_confidence),
      rationale: businessCase.narrative.recommendation,
      confidence_level: businessCase.confidence_snapshot.overall_confidence,
    },
  };
}

/**
 * Derive recommendation from ROI and confidence
 */
function deriveRecommendationAction(
  roi_percent: number,
  confidence: number
): 'strong_recommend' | 'recommend' | 'consider' | 'defer' | 'not_recommended' {
  if (roi_percent > 50 && confidence > 0.75) return 'strong_recommend';
  if (roi_percent > 20 && confidence > 0.6) return 'recommend';
  if (roi_percent > 0 && confidence > 0.5) return 'consider';
  if (roi_percent > -20) return 'defer';
  return 'not_recommended';
}

/**
 * Generate JSON filename
 */
export function generateJSONFilename(businessCase: BusinessCase): string {
  return generateFilename(businessCase, 'json');
}
EOF

log_success "Created JSON export formatter"

mark_script_success "${SCRIPT_ID}"
log_success "${SCRIPT_NAME} completed"

exit 0
