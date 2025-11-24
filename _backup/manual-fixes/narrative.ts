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
    businessCase.confidence_snapshot.high_uncertainty_metrics.forEach((m: string) => {
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
