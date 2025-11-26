#!/usr/bin/env bash
#!meta
# id: export/markdown-export.sh
# name: export.sh - Markdown Export Formatter
# phase: 4
# phase_name: Extensions & Quality
# profile_tags:
#   - tech_stack
#   - export
# uses_from_omni_config:
# uses_from_omni_settings:
#   - EXPORT_DIR
#   - INSTALL_DIR
#   - M
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
# tech_stack/export/markdown-export.sh - Markdown Export Formatter
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Purpose: Set up Markdown export formatter
# Phase: 4
# Reference: PRD Section 6.12 - Markdown Export
#
# Required: PROJECT_ROOT,ENABLE_PDF_EXPORTS
#
# Dependencies:
#   lib/common.sh
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"

readonly SCRIPT_ID="export/markdown-export"
readonly SCRIPT_NAME="Markdown Export Formatter Setup"

if has_script_succeeded "${SCRIPT_ID}"; then
    log_skip "${SCRIPT_NAME} (already completed)"
    exit 0
fi

log_step "${SCRIPT_NAME}"

EXPORT_DIR="${INSTALL_DIR}/src/lib/export"
ensure_dir "${EXPORT_DIR}" "Export directory"

# =============================================================================
# MARKDOWN EXPORT FORMATTER
# =============================================================================

write_file "${EXPORT_DIR}/markdown.ts" <<'EOF'
/**
 * Markdown Export Formatter
 * Generates clean, GitHub-flavored Markdown reports
 */

import type { BusinessCase, ExportResult } from './types';
import { generateFilename, formatCurrency, formatPercent, formatTimePeriod } from './utils';
import {
  buildExecutiveSummary,
  buildCurrentStateNarrative,
  buildValueNarrative,
  buildAssumptionsNarrative,
  buildRecommendationNarrative,
} from './narrative';

/**
 * Markdown Export Options
 */
export interface MarkdownExportOptions {
  include_toc?: boolean;
  include_metadata?: boolean;
  include_appendix?: boolean;
  heading_level?: 1 | 2 | 3;
  max_width?: number; // For table formatting
}

/**
 * Create Markdown document from business case
 */
export function prepareMarkdownContent(
  businessCase: BusinessCase,
  options: MarkdownExportOptions = {}
): string {
  const {
    include_toc = true,
    include_metadata = true,
    include_appendix = true,
    heading_level = 1,
  } = options;

  const h1 = '#'.repeat(heading_level);
  const h2 = '#'.repeat(heading_level + 1);
  const h3 = '#'.repeat(heading_level + 2);

  let document = '';

  // Title
  document += `${h1} ${businessCase.process_name} - Business Case Analysis\n\n`;

  // Metadata
  if (include_metadata) {
    document += `**Generated:** ${new Date(businessCase.generated_at).toLocaleDateString()}\n`;
    document += `**Department:** ${businessCase.department}\n`;
    document += `**Participants:** ${businessCase.participants.join(', ')}\n\n`;
  }

  // Table of Contents
  if (include_toc) {
    document += buildTableOfContents();
  }

  // Executive Summary
  document += `\n${h2} Executive Summary\n\n`;
  document += buildExecutiveSummary(businessCase);
  document += '\n\n';

  // Current State
  document += `${h2} Current State\n\n`;
  document += buildCurrentStateNarrative(businessCase);
  document += '\n\n';

  // Proposed Change
  document += `${h2} Proposed Change\n\n`;
  document += `**Type:** ${businessCase.proposed_change.change_type}\n\n`;
  document += `${businessCase.proposed_change.description}\n\n`;
  document += `**Implementation Cost:** ${formatCurrency(businessCase.proposed_change.implementation_cost)}\n`;
  document += `**Timeline:** ${businessCase.proposed_change.timeline_weeks} weeks\n\n`;

  // Value Proposition
  document += `${h2} Value Proposition\n\n`;
  document += buildValueNarrative(businessCase);
  document += '\n\n';

  // Financial Impact - ROI Table
  document += `${h2} Financial Impact\n\n`;
  document += buildROITable(businessCase);
  document += '\n\n';

  // Improvement Index
  document += `${h3} Improvement Index\n\n`;
  document += buildImprovementIndexSection(businessCase);
  document += '\n\n';

  // Assumptions & Confidence
  document += `${h2} Assumptions & Confidence\n\n`;
  document += buildAssumptionsNarrative(businessCase);
  document += '\n\n';

  // Key Risks
  if (businessCase.key_risks.length > 0) {
    document += `${h2} Key Risks & Mitigations\n\n`;
    document += buildRisksSection(businessCase);
    document += '\n\n';
  }

  // Recommendation
  document += `${h2} Recommendation\n\n`;
  document += buildRecommendationNarrative(businessCase);
  document += '\n\n';

  // Appendix
  if (include_appendix) {
    document += `${h2} Appendix: Detailed Metrics\n\n`;
    document += buildMetricsAppendix(businessCase);
    document += '\n\n';
  }

  // Footer
  document += `---\n\n`;
  document += `*Bloom Business Case Analysis*\n`;
  document += `*Confidence: ${(businessCase.confidence_snapshot.overall_confidence * 100).toFixed(0)}%*\n`;

  return document;
}

/**
 * Build table of contents
 */
function buildTableOfContents(): string {
  return `## Table of Contents

- [Executive Summary](#executive-summary)
- [Current State](#current-state)
- [Proposed Change](#proposed-change)
- [Value Proposition](#value-proposition)
- [Financial Impact](#financial-impact)
- [Assumptions & Confidence](#assumptions--confidence)
- [Key Risks & Mitigations](#key-risks--mitigations)
- [Recommendation](#recommendation)
- [Appendix](#appendix-detailed-metrics)

`;
}

/**
 * Build ROI table
 */
function buildROITable(businessCase: BusinessCase): string {
  const roi = businessCase.roi_results;

  return `| Metric | Conservative | Base | Aggressive |
|--------|--------------|------|-----------|
| Annual Savings | ${formatCurrency(roi.total_annual_savings.conservative)} | ${formatCurrency(roi.total_annual_savings.base)} | ${formatCurrency(roi.total_annual_savings.aggressive)} |
| ROI | ${Math.round(roi.roi_percent.conservative)}% | ${Math.round(roi.roi_percent.base)}% | ${Math.round(roi.roi_percent.aggressive)}% |
| Payback Period | ${formatTimePeriod(roi.payback_period_months.conservative)} | ${formatTimePeriod(roi.payback_period_months.base)} | ${formatTimePeriod(roi.payback_period_months.aggressive)} |
| Time Saved (Annual) | ${roi.annual_time_saved_hours.conservative.toFixed(0)}h | ${roi.annual_time_saved_hours.base.toFixed(0)}h | ${roi.annual_time_saved_hours.aggressive.toFixed(0)}h |`;
}

/**
 * Build improvement index section
 */
function buildImprovementIndexSection(businessCase: BusinessCase): string {
  const ii = businessCase.roi_results.improvement_index;

  return `| Dimension | Score |
|-----------|-------|
| Financial | ${formatPercent(ii.financial)} |
| Operational | ${formatPercent(ii.operational)} |
| Human | ${formatPercent(ii.human)} |
| **Composite** | **${formatPercent(ii.composite)}** |`;
}

/**
 * Build risks section
 */
function buildRisksSection(businessCase: BusinessCase): string {
  let section = '';

  businessCase.key_risks.forEach((risk) => {
    const likelihood = risk.likelihood === 'high' ? '🔴' : risk.likelihood === 'medium' ? '🟡' : '🟢';
    section += `${likelihood} **${risk.risk}**\n`;
    section += `  - *Mitigation:* ${risk.mitigation}\n\n`;
  });

  return section;
}

/**
 * Build detailed metrics appendix
 */
function buildMetricsAppendix(businessCase: BusinessCase): string {
  let appendix = '';

  appendix += '### Extracted Metrics\n\n';
  businessCase.metrics.forEach((m) => {
    const confidenceEmoji = m.confidence === 'high' ? '✅' : m.confidence === 'medium' ? '⚠️' : '❌';
    appendix += `${confidenceEmoji} **${m.name}:** ${m.value} ${m.unit}\n`;
  });

  appendix += '\n### Data Quality Assessment\n\n';
  appendix += `- **Overall Confidence:** ${(businessCase.confidence_snapshot.overall_confidence * 100).toFixed(0)}%\n`;
  appendix += `- **Data Completeness:** ${(businessCase.confidence_snapshot.data_completeness * 100).toFixed(0)}%\n`;
  appendix += `- **Metrics Captured:** ${businessCase.metrics.length} key metrics\n`;

  if (businessCase.confidence_snapshot.high_uncertainty_metrics.length > 0) {
    appendix += `\n### High Uncertainty Areas\n\n`;
    businessCase.confidence_snapshot.high_uncertainty_metrics.forEach((m) => {
      appendix += `- ${m} (Confidence < 60%)\n`;
    });
  }

  return appendix.trim();
}

/**
 * Prepare filename for Markdown export
 */
export function generateMarkdownFilename(businessCase: BusinessCase): string {
  return generateFilename(businessCase, 'md');
}
EOF

log_success "Created Markdown export formatter"

# =============================================================================
# MARK SUCCESS
# =============================================================================

mark_script_success "${SCRIPT_ID}"
log_success "${SCRIPT_NAME} completed"

exit 0
