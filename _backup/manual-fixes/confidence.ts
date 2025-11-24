/**
 * Confidence Engine
 * Calculates and tracks confidence levels for business case metrics
 */

export interface SessionConfidenceSnapshot {
  overall_confidence: number;
  high_uncertainty_metrics: string[];
  confidence_factors: {
    data_quality: number;
    assumptions_validated: number;
    measurement_precision: number;
  };
}

/**
 * Calculate confidence snapshot for a session
 */
export function calculateConfidenceSnapshot(
  metrics: Array<{ name: string; confidence: 'low' | 'medium' | 'high' }>,
  assumptionConfidences: number[]
): SessionConfidenceSnapshot {
  // Convert confidence levels to numeric scores
  const confidenceScores = metrics.map((m) => {
    switch (m.confidence) {
      case 'high':
        return 0.9;
      case 'medium':
        return 0.6;
      case 'low':
        return 0.3;
      default:
        return 0.5;
    }
  });

  // Identify high uncertainty metrics (confidence < 0.5)
  const highUncertaintyMetrics = metrics
    .filter((m) => m.confidence === 'low')
    .map((m) => m.name);

  // Calculate overall confidence (weighted average)
  const avgMetricConfidence =
    confidenceScores.reduce((sum, score) => sum + score, 0) / Math.max(confidenceScores.length, 1);

  const avgAssumptionConfidence =
    assumptionConfidences.reduce((sum, conf) => sum + conf, 0) / Math.max(assumptionConfidences.length, 1);

  const overallConfidence = (avgMetricConfidence * 0.6 + avgAssumptionConfidence * 0.4);

  return {
    overall_confidence: overallConfidence,
    high_uncertainty_metrics: highUncertaintyMetrics,
    confidence_factors: {
      data_quality: avgMetricConfidence,
      assumptions_validated: avgAssumptionConfidence,
      measurement_precision: avgMetricConfidence * 0.9, // Simplified
    },
  };
}
