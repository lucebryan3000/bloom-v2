#!/usr/bin/env bash
# =============================================================================
# tech_stack/export/pdf-export.sh - PDF Export Formatter
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Purpose: Set up PDF export formatter
# Phase: 4
# Reference: PRD Section 6.12 - PDF Export
#
# Required: PROJECT_ROOT,APP_NAME,ENABLE_PDF_EXPORTS
#
# Dependencies:
#   lib/common.sh
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"

readonly SCRIPT_ID="export/pdf-export"
readonly SCRIPT_NAME="PDF Export Formatter Setup"

if has_script_succeeded "${SCRIPT_ID}"; then
    log_skip "${SCRIPT_NAME} (already completed)"
    exit 0
fi

log_step "${SCRIPT_NAME}"

EXPORT_DIR="${INSTALL_DIR}/src/lib/export"
ensure_dir "${EXPORT_DIR}" "Export directory"

# =============================================================================
# PDF EXPORT FORMATTER
# =============================================================================

write_file "${EXPORT_DIR}/pdf.ts" <<'EOF'
/**
 * PDF Export Formatter
 * Generates professional PDF reports using react-to-print and jsPDF
 */

import type { BusinessCase, ExportResult } from './types';
import { generateFilename } from './utils';
import {
  buildExecutiveSummary,
  buildCurrentStateNarrative,
  buildValueNarrative,
  buildAssumptionsNarrative,
  buildRecommendationNarrative,
} from './narrative';

/**
 * PDF Export Options
 */
export interface PDFExportOptions {
  include_logo?: boolean;
  include_charts?: boolean;
  include_appendix?: boolean;
  page_orientation?: 'portrait' | 'landscape';
  footer_text?: string;
}

/**
 * Create PDF business case
 * Note: Actual PDF generation happens in React via react-to-print
 * This function prepares the data structure
 */
export function preparePDFContent(
  businessCase: BusinessCase,
  options: PDFExportOptions = {}
): {
  title: string;
  sections: Array<{
    heading: string;
    content: string;
    type: 'narrative' | 'table' | 'chart';
  }>;
  metadata: Record<string, string>;
} {
  const {
    include_logo = true,
    include_charts = true,
    include_appendix = true,
    footer_text = 'Bloom Business Case Analysis',
  } = options;

  const sections = [
    {
      heading: 'Executive Summary',
      content: buildExecutiveSummary(businessCase),
      type: 'narrative' as const,
    },
    {
      heading: 'Current State',
      content: buildCurrentStateNarrative(businessCase),
      type: 'narrative' as const,
    },
    {
      heading: 'Value Proposition',
      content: buildValueNarrative(businessCase),
      type: 'narrative' as const,
    },
  ];

  if (include_charts) {
    sections.push({
      heading: 'ROI Analysis',
      content: formatROITable(businessCase),
      type: 'table' as const,
    });
  }

  sections.push(
    {
      heading: 'Assumptions & Confidence',
      content: buildAssumptionsNarrative(businessCase),
      type: 'narrative' as const,
    },
    {
      heading: 'Recommendation',
      content: buildRecommendationNarrative(businessCase),
      type: 'narrative' as const,
    }
  );

  if (include_appendix) {
    sections.push({
      heading: 'Appendix: Detailed Metrics',
      content: formatMetricsAppendix(businessCase),
      type: 'table' as const,
    });
  }

  return {
    title: `${businessCase.process_name} - Business Case Analysis`,
    sections,
    metadata: {
      process_name: businessCase.process_name,
      department: businessCase.department,
      generated_date: businessCase.generated_at,
      confidence: `${(businessCase.confidence_snapshot.overall_confidence * 100).toFixed(0)}%`,
      footer: footer_text,
    },
  };
}

/**
 * Format ROI table for PDF
 */
function formatROITable(businessCase: BusinessCase): string {
  const roi = businessCase.roi_results;

  return `
| Metric | Conservative | Base | Aggressive |
|--------|--------------|------|-----------|
| Annual Savings | $${Math.round(roi.total_annual_savings.conservative).toLocaleString()} | $${Math.round(roi.total_annual_savings.base).toLocaleString()} | $${Math.round(roi.total_annual_savings.aggressive).toLocaleString()} |
| ROI | ${Math.round(roi.roi_percent.conservative)}% | ${Math.round(roi.roi_percent.base)}% | ${Math.round(roi.roi_percent.aggressive)}% |
| Payback Period | ${roi.payback_period_months.conservative.toFixed(1)} months | ${roi.payback_period_months.base.toFixed(1)} months | ${roi.payback_period_months.aggressive.toFixed(1)} months |

**Improvement Index by Dimension:**
- Financial: ${(roi.improvement_index.financial * 100).toFixed(0)}%
- Operational: ${(roi.improvement_index.operational * 100).toFixed(0)}%
- Human: ${(roi.improvement_index.human * 100).toFixed(0)}%
- Composite: ${(roi.improvement_index.composite * 100).toFixed(0)}%
  `.trim();
}

/**
 * Format detailed metrics appendix
 */
function formatMetricsAppendix(businessCase: BusinessCase): string {
  const metrics = businessCase.metrics
    .map((m) => `- **${m.name}**: ${m.value} ${m.unit} (Confidence: ${m.confidence})`)
    .join('\n');

  return `
### Extracted Metrics

${metrics}

### Data Completeness
- Overall Confidence: ${(businessCase.confidence_snapshot.overall_confidence * 100).toFixed(0)}%
- Data Completeness: ${(businessCase.confidence_snapshot.data_completeness * 100).toFixed(0)}%
- Metrics Captured: ${businessCase.metrics.length} key metrics

### High Uncertainty Areas
${businessCase.confidence_snapshot.high_uncertainty_metrics.length > 0
  ? businessCase.confidence_snapshot.high_uncertainty_metrics
      .map((m) => `- ${m}`)
      .join('\n')
  : '- None'}
  `.trim();
}

/**
 * Prepare filename for PDF export
 */
export function generatePDFFilename(businessCase: BusinessCase): string {
  return generateFilename(businessCase, 'pdf');
}
EOF

log_success "Created PDF export formatter"

# =============================================================================
# PDF EXPORT COMPONENT (React)
# =============================================================================

write_file "${INSTALL_DIR}/src/components/export/PDFExport.tsx" 2>/dev/null || true <<'EOF'
/**
 * PDF Export React Component
 * Renders business case for printing/PDF export
 * Uses react-to-print for browser-native PDF generation
 */

import React, { useRef } from 'react';
import { useReactToPrint } from 'react-to-print';
import type { BusinessCase } from '@/lib/export/types';
import { preparePDFContent, generatePDFFilename } from '@/lib/export/pdf';

interface PDFExportProps {
  businessCase: BusinessCase;
  onExported?: () => void;
}

export const PDFExport: React.FC<PDFExportProps> = ({ businessCase, onExported }) => {
  const contentRef = useRef<HTMLDivElement>(null);

  const handlePrint = useReactToPrint({
    contentRef,
    documentTitle: generatePDFFilename(businessCase),
    onAfterPrint: onExported,
  });

  const pdfContent = preparePDFContent(businessCase);

  return (
    <div>
      <button onClick={() => handlePrint()} className="btn btn-primary">
        Export as PDF
      </button>

      {/* Hidden content for printing */}
      <div ref={contentRef} style={{ display: 'none' }}>
        <PDFDocument businessCase={businessCase} />
      </div>
    </div>
  );
};

/**
 * Printable PDF Document Component
 */
const PDFDocument: React.FC<{ businessCase: BusinessCase }> = ({ businessCase }) => {
  return (
    <div className="pdf-document" style={{ padding: '40px', fontFamily: 'serif' }}>
      <h1>{businessCase.process_name}</h1>
      <p style={{ color: '#666' }}>Business Case Analysis</p>
      <p>Generated: {new Date(businessCase.generated_at).toLocaleDateString()}</p>

      <hr style={{ margin: '40px 0' }} />

      {/* Executive Summary */}
      <section style={{ marginBottom: '40px' }}>
        <h2>Executive Summary</h2>
        <p>{businessCase.narrative.executive_summary}</p>
      </section>

      {/* Current State */}
      <section style={{ marginBottom: '40px', pageBreakBefore: 'always' }}>
        <h2>Current State</h2>
        <p>{businessCase.narrative.current_state_narrative}</p>
      </section>

      {/* Value Proposition */}
      <section style={{ marginBottom: '40px' }}>
        <h2>Value Proposition</h2>
        <p>{businessCase.narrative.value_breakdown}</p>
      </section>

      {/* ROI Table */}
      <section style={{ marginBottom: '40px', pageBreakBefore: 'always' }}>
        <h2>Financial Impact</h2>
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead>
            <tr style={{ borderBottom: '2px solid #333' }}>
              <th style={{ textAlign: 'left', padding: '8px' }}>Metric</th>
              <th style={{ textAlign: 'right', padding: '8px' }}>Conservative</th>
              <th style={{ textAlign: 'right', padding: '8px' }}>Base</th>
              <th style={{ textAlign: 'right', padding: '8px' }}>Aggressive</th>
            </tr>
          </thead>
          <tbody>
            <tr style={{ borderBottom: '1px solid #ddd' }}>
              <td style={{ padding: '8px' }}>Annual Savings</td>
              <td style={{ textAlign: 'right', padding: '8px' }}>
                ${businessCase.roi_results.total_annual_savings.conservative.toLocaleString()}
              </td>
              <td style={{ textAlign: 'right', padding: '8px' }}>
                ${businessCase.roi_results.total_annual_savings.base.toLocaleString()}
              </td>
              <td style={{ textAlign: 'right', padding: '8px' }}>
                ${businessCase.roi_results.total_annual_savings.aggressive.toLocaleString()}
              </td>
            </tr>
            <tr style={{ borderBottom: '1px solid #ddd' }}>
              <td style={{ padding: '8px' }}>ROI</td>
              <td style={{ textAlign: 'right', padding: '8px' }}>
                {Math.round(businessCase.roi_results.roi_percent.conservative)}%
              </td>
              <td style={{ textAlign: 'right', padding: '8px' }}>
                {Math.round(businessCase.roi_results.roi_percent.base)}%
              </td>
              <td style={{ textAlign: 'right', padding: '8px' }}>
                {Math.round(businessCase.roi_results.roi_percent.aggressive)}%
              </td>
            </tr>
          </tbody>
        </table>
      </section>

      {/* Assumptions & Confidence */}
      <section style={{ marginBottom: '40px', pageBreakBefore: 'always' }}>
        <h2>Assumptions & Confidence</h2>
        <p>
          <strong>Overall Confidence:</strong>{' '}
          {(businessCase.confidence_snapshot.overall_confidence * 100).toFixed(0)}%
        </p>
        {businessCase.key_assumptions.length > 0 && (
          <>
            <h3>Key Assumptions</h3>
            <ul>
              {businessCase.key_assumptions.map((a, idx) => (
                <li key={idx}>{a.assumption}</li>
              ))}
            </ul>
          </>
        )}
      </section>

      {/* Recommendation */}
      <section style={{ marginBottom: '40px' }}>
        <h2>Recommendation</h2>
        <p>{businessCase.narrative.recommendation}</p>
      </section>

      {/* Footer */}
      <footer style={{ marginTop: '60px', borderTop: '1px solid #ddd', paddingTop: '20px', color: '#999' }}>
        <p>Bloom Business Case Analysis • Confidential</p>
      </footer>
    </div>
  );
};

export default PDFExport;
EOF

log_success "Created PDF export React component"

# =============================================================================
# MARK SUCCESS
# =============================================================================

mark_script_success "${SCRIPT_ID}"
log_success "${SCRIPT_NAME} completed"

exit 0
