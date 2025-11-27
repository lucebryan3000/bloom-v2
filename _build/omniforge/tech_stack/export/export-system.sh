#!/usr/bin/env bash
#!meta
# id: export/export-system.sh
# name: export system
# phase: 4
# phase_name: Extensions & Quality
# profile_tags:
#   - tech_stack
#   - export
# uses_from_omni_config:
#   - ENABLE_PDF_EXPORTS
# uses_from_omni_settings:
#   - PROJECT_ROOT
#   - INSTALL_DIR
#   - EXPORT_DIR
# top_flags:
# dependencies:
#   packages: []
#   dev_packages: []
#!endmeta

# =============================================================================
# tech_stack/export/export-system.sh - Export System Infrastructure
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Purpose: Set up export system infrastructure (PDF, Excel, JSON, Markdown)
# Phase: 4
# Reference: PRD Section 6.12 - Export System
#
# Required: PROJECT_ROOT,ENABLE_PDF_EXPORTS,PKG_JSPDF,PKG_HTML2CANVAS,PKG_EXCELJS,PKG_MARKDOWN_IT
#
# Dependencies:
#   lib/common.sh
# =============================================================================
# Contract:
#   Inputs: PROJECT_ROOT, ENABLE_PDF_EXPORTS/ENABLE_CODE_QUALITY flags, export package pins
#   Outputs: export infrastructure files (src/export/*), updates package.json scripts/config
#   Runtime: Adds export system scaffolding; reads flags to include optional exports
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"
if command -v parse_stack_flags >/dev/null 2>&1; then
    parse_stack_flags "$@"
fi

readonly SCRIPT_ID="export/export-system"
readonly SCRIPT_NAME="Export System Infrastructure Setup"

if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_skip "DRY_RUN: skipping ${SCRIPT_NAME}"
    exit 0
fi

if has_script_succeeded "${SCRIPT_ID}"; then
    log_skip "${SCRIPT_NAME} (already completed)"
    exit 0
fi

log_step "${SCRIPT_NAME}"

# =============================================================================
# ADD EXPORT PACKAGES
# =============================================================================

log_step "Installing export dependencies (jsPDF, ExcelJS, Markdown libraries)"

if ! has_dependency "${PKG_JSPDF}"; then
    add_dependency "${PKG_JSPDF}"
    log_success "Added jsPDF"
fi

if ! has_dependency "${PKG_HTML2CANVAS}"; then
    add_dependency "${PKG_HTML2CANVAS}"
    log_success "Added html2canvas"
fi

if ! has_dependency "${PKG_EXCELJS}"; then
    add_dependency "${PKG_EXCELJS}"
    add_dependency "${PKG_TYPES_EXCELJS}"
    log_success "Added ExcelJS and types"
fi

if ! has_dependency "${PKG_MARKDOWN_IT}"; then
    add_dependency "${PKG_MARKDOWN_IT}"
    log_success "Added markdown-it"
fi

# =============================================================================
# CREATE EXPORT LIB DIRECTORY
# =============================================================================

EXPORT_DIR="${INSTALL_DIR}/src/lib/export"
ensure_dir "${EXPORT_DIR}" "Export utilities directory"

# =============================================================================
# EXPORT TYPES & SCHEMAS
# =============================================================================

write_file "${EXPORT_DIR}/types.ts" <<'EOF'
/**
 * Export System Types
 * Defines the shape of data for all export formats
 */

import { ROIOutput } from '../roi';
import { SessionConfidenceSnapshot } from '../confidence';

/**
 * Complete business case for export
 */
export interface BusinessCase {
  // Metadata
  id: string;
  session_id: string;
  generated_at: string;
  version: string;

  // Process information
  process_name: string;
  process_description: string;
  department: string;
  participants: string[];

  // Current state
  current_state: {
    description: string;
    volume_per_period: number;
    period_unit: string;
    cycle_time: number;
    team_size: number;
    annual_cost: number;
  };

  // Proposed change
  proposed_change: {
    description: string;
    change_type: string; // automation, redesign, tool_adoption, etc.
    implementation_cost: number;
    timeline_weeks: number;
  };

  // Metrics & value
  metrics: Array<{
    name: string;
    value: number;
    unit: string;
    confidence: 'low' | 'medium' | 'high';
  }>;

  // ROI
  roi_results: ROIOutput;

  // Confidence
  confidence_snapshot: SessionConfidenceSnapshot;

  // Narrative
  narrative: {
    executive_summary: string;
    current_state_narrative: string;
    proposed_change_narrative: string;
    value_breakdown: string;
    risks_and_assumptions: string;
    recommendation: string;
  };

  // Assumptions & risks
  key_assumptions: Array<{
    assumption: string;
    impact: 'low' | 'medium' | 'high';
    confidence: number;
  }>;

  key_risks: Array<{
    risk: string;
    mitigation: string;
    likelihood: 'low' | 'medium' | 'high';
  }>;
}

/**
 * Export format options
 */
export type ExportFormat = 'pdf' | 'excel' | 'json' | 'markdown';

/**
 * Export result
 */
export interface ExportResult {
  format: ExportFormat;
  filename: string;
  mime_type: string;
  size_bytes: number;
  generated_at: string;
  url?: string; // For cloud storage
}
EOF

log_success "Created export types"

# =============================================================================
# EXPORT UTILITIES
# =============================================================================

write_file "${EXPORT_DIR}/utils.ts" <<'EOF'
/**
 * Export utilities - shared across all formats
 */

import type { BusinessCase } from './types';

/**
 * Generate filename based on business case
 */
export function generateFilename(
  businessCase: BusinessCase,
  format: 'pdf' | 'xlsx' | 'json' | 'md'
): string {
  const timestamp = new Date().toISOString().split('T')[0]; // YYYY-MM-DD
  const processSlug = businessCase.process_name
    .toLowerCase()
    .replace(/\s+/g, '-')
    .replace(/[^\w-]/g, '')
    .slice(0, 30);

  const ext = {
    pdf: 'pdf',
    xlsx: 'xlsx',
    json: 'json',
    md: 'md',
  }[format];

  return `bloom-${processSlug}-${timestamp}.${ext}`;
}

/**
 * Format currency
 */
export function formatCurrency(value: number): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
  }).format(value);
}

/**
 * Format percentage
 */
export function formatPercent(value: number): string {
  return `${(value * 100).toFixed(1)}%`;
}

/**
 * Format time period
 */
export function formatTimePeriod(months: number): string {
  if (months < 1) return '< 1 month';
  if (months < 12) return `${Math.round(months)} months`;
  const years = (months / 12).toFixed(1);
  return `${years} years`;
}

/**
 * Sanitize text for export (remove HTML, control characters)
 */
export function sanitizeText(text: string): string {
  return text
    .replace(/<[^>]*>/g, '') // Remove HTML tags
    .replace(/[^\x20-\x7E\n\r\t]/g, '') // Remove control characters
    .trim();
}
EOF

log_success "Created export utilities"

# =============================================================================
# NARRATIVE BUILDER
# =============================================================================

write_file "${EXPORT_DIR}/narrative.ts" <<'EOF'
/**
 * Business Case Narrative Builder
 * Generates human-readable narrative sections
 */

import type { BusinessCase } from './types';
import { formatCurrency, formatPercent, formatTimePeriod } from './utils';

export function buildExecutiveSummary(businessCase: BusinessCase): string {
  const roi = businessCase.roi_results;
  const confidence = (businessCase.confidence_snapshot.overall_confidence * 100).toFixed(0);

  return `
This analysis evaluates the business case for: **${businessCase.process_name}**

**Key Findings:**
- **Annual Savings:** ${formatCurrency(roi.total_annual_savings.base)}
- **ROI:** ${Math.round(roi.roi_percent.base)}%
- **Payback:** ${formatTimePeriod(roi.payback_period_months.base)}
- **Confidence:** ${confidence}%

The proposed change is estimated to deliver **${formatPercent(businessCase.roi_results.improvement_index.composite)}** improvement across financial, operational, and human value dimensions.
  `.trim();
}

export function buildCurrentStateNarrative(businessCase: BusinessCase): string {
  const current = businessCase.current_state;

  return `
## Current State

The **${businessCase.process_name}** process currently:
- Handles **${current.volume_per_period}** units per **${current.period_unit}**
- Requires **${current.cycle_time}** minutes per unit, totaling significant team effort
- Engages **${current.team_size}** people (full and part-time)
- Costs approximately **${formatCurrency(current.annual_cost)}** annually in direct labor

${businessCase.narrative.current_state_narrative}
  `.trim();
}

export function buildValueNarrative(businessCase: BusinessCase): string {
  const roi = businessCase.roi_results;
  const ii = roi.improvement_index;

  return `
## Value Proposition

Implementing the proposed change will deliver value across three dimensions:

### Financial
- **Annual Savings:** ${formatCurrency(roi.total_annual_savings.base)} (range: ${formatCurrency(roi.total_annual_savings.conservative)} – ${formatCurrency(roi.total_annual_savings.aggressive)})
- **ROI:** ${Math.round(roi.roi_percent.base)}% (range: ${Math.round(roi.roi_percent.conservative)}% – ${Math.round(roi.roi_percent.aggressive)}%)
- **Payback Period:** ${formatTimePeriod(roi.payback_period_months.base)}
- **Score:** ${formatPercent(ii.financial)}

### Operational
- Reduced cycle time and increased capacity
- Fewer errors and rework cycles
- Improved consistency and visibility
- **Score:** ${formatPercent(ii.operational)}

### Human
- Reduced stress and cognitive load
- Fewer interruptions and fire-fighting moments
- Opportunity for skill development and career growth
- **Score:** ${formatPercent(ii.human)}

**Composite Improvement Index:** ${formatPercent(ii.composite)}
  `.trim();
}

export function buildAssumptionsNarrative(businessCase: BusinessCase): string {
  let narrative = '## Key Assumptions & Confidence\n\n';
  narrative += `**Overall Confidence: ${formatPercent(businessCase.confidence_snapshot.overall_confidence)}**\n\n`;

  narrative += '### Key Assumptions\n\n';
  businessCase.key_assumptions.forEach((a) => {
    const impact = a.impact === 'high' ? '⚠️' : a.impact === 'medium' ? '→' : '✓';
    narrative += `${impact} **${a.assumption}** (confidence: ${formatPercent(a.confidence)})\n`;
  });

  if (businessCase.confidence_snapshot.high_uncertainty_metrics.length > 0) {
    narrative += '\n### Areas of Uncertainty\n\n';
    businessCase.confidence_snapshot.high_uncertainty_metrics.forEach((m) => {
      narrative += `- ${m}: Consider follow-up measurement\n`;
    });
  }

  return narrative.trim();
}

export function buildRecommendationNarrative(businessCase: BusinessCase): string {
  const roi = businessCase.roi_results.roi_percent.base;
  const confidence = businessCase.confidence_snapshot.overall_confidence;

  let recommendation = '## Recommendation\n\n';

  if (roi > 50 && confidence > 0.75) {
    recommendation += `**STRONG RECOMMENDATION:** Proceed with implementation. The financial case is compelling and well-supported by data.`;
  } else if (roi > 20 && confidence > 0.6) {
    recommendation += `**RECOMMEND:** Proceed with implementation. ROI is solid; validate key assumptions with follow-up measurement.`;
  } else if (roi > 0 && confidence > 0.5) {
    recommendation += `**CONSIDER:** The case is positive but modest. Weigh against other initiatives and resource constraints.`;
  } else if (roi > -20) {
    recommendation += `**DEFER:** Current data does not support prioritization. Revisit if conditions change or uncertainty decreases.`;
  } else {
    recommendation += `**NOT RECOMMENDED:** Based on current analysis, this project does not deliver sufficient value to justify investment.`;
  }

  recommendation += `\n\n${businessCase.narrative.recommendation}`;

  return recommendation.trim();
}
EOF

log_success "Created narrative builder"

# =============================================================================
# REGISTER NPM SCRIPTS FOR EXPORTS
# =============================================================================

add_npm_script "export:pdf" "node scripts/export-pdf.js"
add_npm_script "export:excel" "node scripts/export-excel.js"
add_npm_script "export:json" "node scripts/export-json.js"
add_npm_script "export:markdown" "node scripts/export-markdown.js"

log_success "Registered export npm scripts"

# =============================================================================
# MARK SUCCESS
# =============================================================================

mark_script_success "${SCRIPT_ID}"
log_success "${SCRIPT_NAME} completed"

exit 0