/**
 * Session State Management
 * Tracks the current state of a Melissa session through the phased conversation
 */

export interface SessionState {
  session_id: string;
  current_phase: 'greeting' | 'discovery' | 'quantification' | 'validation' | 'synthesis';
  messageCount: number;
  process_name?: string;
  process_description?: string;
  department?: string;

  // Discovery phase data
  current_state?: {
    description: string;
    volume_per_period?: number;
    cycle_time?: number;
  };

  proposed_change?: {
    description: string;
    expected_improvements?: string[];
  };

  // Quantification phase data
  extractedMetrics: Array<{
    name: string;
    value: number;
    unit: string;
    confidence: 'low' | 'medium' | 'high';
  }>;

  // Validation phase data
  key_assumptions?: Array<{
    assumption: string;
    impact: 'low' | 'medium' | 'high';
    confidence: number;
  }>;

  key_risks?: Array<{
    risk: string;
    mitigation: string;
    likelihood: 'low' | 'medium' | 'high';
  }>;

  // Confidence tracking
  confidence: {
    overall: number;
    data_quality: number;
  };

  unresolved_contradictions: string[];

  // Meta
  created_at: Date;
  updated_at: Date;
}

/**
 * Initialize a new session
 */
export function createSession(session_id: string): SessionState {
  return {
    session_id,
    current_phase: 'greeting',
    messageCount: 0,
    extractedMetrics: [],
    confidence: {
      overall: 0,
      data_quality: 0,
    },
    unresolved_contradictions: [],
    created_at: new Date(),
    updated_at: new Date(),
  };
}

/**
 * Update session phase
 */
export function updatePhase(
  session: SessionState,
  phase: SessionState['current_phase']
): SessionState {
  return {
    ...session,
    current_phase: phase,
    updated_at: new Date(),
  };
}
