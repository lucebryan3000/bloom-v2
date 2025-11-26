/**
 * Phase Router Logic
 * Determines which phase Melissa should be in and routes questions accordingly
 */

import type { SessionState } from '../lib/sessionState';

export type MelissaPhase = 'greeting' | 'discovery' | 'quantification' | 'validation' | 'synthesis';

export function getCurrentPhase(sessionState: SessionState): MelissaPhase {
  const { messageCount, extractedMetrics, confidence } = sessionState;

  // Greeting: no messages yet
  if (messageCount === 0) {
    return 'greeting';
  }

  // Discovery: gathering qualitative understanding (0-10 messages typical)
  if (messageCount < 10 && extractedMetrics.length === 0) {
    return 'discovery';
  }

  // Quantification: extracting metrics (10-30 messages typical)
  if (extractedMetrics.length < 8 || confidence.overall < 0.65) {
    return 'quantification';
  }

  // Validation: confirming and resolving contradictions (30-50 messages)
  if (confidence.overall < 0.8) {
    return 'validation';
  }

  // Synthesis: preparing for ROI output
  return 'synthesis';
}

export function shouldAdvancePhase(currentPhase: MelissaPhase, sessionState: SessionState): boolean {
  const { extractedMetrics, confidence, unresolved_contradictions } = sessionState;

  switch (currentPhase) {
    case 'discovery':
      return extractedMetrics.length >= 3 && confidence.overall > 0.4;
    case 'quantification':
      return (
        extractedMetrics.length >= 8 &&
        confidence.overall > 0.65 &&
        unresolved_contradictions.length === 0
      );
    case 'validation':
      return confidence.overall > 0.8 && unresolved_contradictions.length === 0;
    case 'synthesis':
      return true; // Ready to calculate ROI and generate narrative
    default:
      return false;
  }
}

export function getPhasePromptSystem(phase: MelissaPhase): string {
  switch (phase) {
    case 'greeting':
      return `Welcome to Bloom! I'm Melissa. We're here to discover and quantify the real value of improving your processes.

Over the next 30–45 minutes, we'll talk through how things work today, extract key metrics, and build a defensible business case.

I'll ask specific questions (not vague ones). You can give rough estimates; ranges are perfect. There are no bad answers—just honest ones.

Ready to get started? What process or problem would you like to work on?`;
    case 'discovery':
      return 'You are in DISCOVERY phase. Build qualitative understanding.';
    case 'quantification':
      return 'You are in QUANTIFICATION phase. Extract metrics and numbers.';
    case 'validation':
      return 'You are in VALIDATION phase. Confirm and resolve contradictions.';
    case 'synthesis':
      return 'You are in SYNTHESIS phase. Summarize for ROI calculation.';
    default:
      return '';
  }
}
