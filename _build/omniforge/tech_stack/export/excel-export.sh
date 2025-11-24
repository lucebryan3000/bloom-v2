#!/usr/bin/env bash
# =============================================================================
# tech_stack/export/excel-export.sh - Excel Export Formatter
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Purpose: Set up Excel export formatter
# Phase: 4
# Reference: PRD Section 6.12 - Excel Export
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

readonly SCRIPT_ID="export/excel-export"
readonly SCRIPT_NAME="Excel Export Setup"

if has_script_succeeded "${SCRIPT_ID}"; then
    log_skip "${SCRIPT_NAME} (already completed)"
    exit 0
fi

log_step "${SCRIPT_NAME}"

EXPORT_DIR="${PROJECT_ROOT}/src/lib/export"
ensure_dir "${EXPORT_DIR}" "Export directory"

# Create Excel export module
write_file "${EXPORT_DIR}/excel.ts" <<'EOF'
/**
 * Excel Export Formatter
 * Generates multi-sheet Excel workbooks with ROI, metrics, and scenarios
 */

import type { BusinessCase, ExportResult } from './types';
import { generateFilename } from './utils';

/**
 * Prepare Excel workbook data
 */
export interface ExcelWorkbook {
  sheets: Array<{
    name: string;
    data: Array<Record<string, any>>;
    formatting?: {
      headers?: { bold: boolean; bgColor: string };
      columns?: Record<string, { width: number; format?: string }>;
    };
  }>;
}

/**
 * Create Excel workbook structure
 */
export function prepareExcelWorkbook(businessCase: BusinessCase): ExcelWorkbook {
  const roi = businessCase.roi_results;

  return {
    sheets: [
      {
        name: 'Executive Summary',
        data: [
          { Key: 'Process Name', Value: businessCase.process_name },
          { Key: 'Department', Value: businessCase.department },
          { Key: 'Generated Date', Value: businessCase.generated_at },
          { Key: '', Value: '' },
          { Key: 'Annual Savings (Base)', Value: roi.total_annual_savings.base },
          { Key: 'ROI (Base)', Value: `${Math.round(roi.roi_percent.base)}%` },
          { Key: 'Payback Period (months)', Value: Math.round(roi.payback_period_months.base) },
          { Key: 'Overall Confidence', Value: `${(businessCase.confidence_snapshot.overall_confidence * 100).toFixed(0)}%` },
        ],
      },
      {
        name: 'ROI Scenarios',
        data: [
          {
            Scenario: 'Conservative',
            'Annual Savings': roi.total_annual_savings.conservative,
            'ROI %': Math.round(roi.roi_percent.conservative),
            'Payback (months)': Math.round(roi.payback_period_months.conservative),
          },
          {
            Scenario: 'Base',
            'Annual Savings': roi.total_annual_savings.base,
            'ROI %': Math.round(roi.roi_percent.base),
            'Payback (months)': Math.round(roi.payback_period_months.base),
          },
          {
            Scenario: 'Aggressive',
            'Annual Savings': roi.total_annual_savings.aggressive,
            'ROI %': Math.round(roi.roi_percent.aggressive),
            'Payback (months)': Math.round(roi.payback_period_months.aggressive),
          },
        ],
      },
      {
        name: 'Metrics',
        data: businessCase.metrics.map((m) => ({
          'Metric Name': m.name,
          Value: m.value,
          Unit: m.unit,
          Confidence: m.confidence,
        })),
      },
      {
        name: 'Assumptions',
        data: businessCase.key_assumptions.map((a) => ({
          Assumption: a.assumption,
          Impact: a.impact,
          Confidence: `${(a.confidence * 100).toFixed(0)}%`,
        })),
      },
      {
        name: 'Risks',
        data: businessCase.key_risks.map((r) => ({
          Risk: r.risk,
          Mitigation: r.mitigation,
          Likelihood: r.likelihood,
        })),
      },
    ],
  };
}

/**
 * Generate Excel filename
 */
export function generateExcelFilename(businessCase: BusinessCase): string {
  return generateFilename(businessCase, 'xlsx');
}
EOF

log_success "Created Excel export formatter"

mark_script_success "${SCRIPT_ID}"
log_success "${SCRIPT_NAME} completed"

exit 0
