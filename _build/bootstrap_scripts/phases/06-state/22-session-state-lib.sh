#!/usr/bin/env bash
# =============================================================================
# File: phases/06-state/22-session-state-lib.sh
# Purpose: Scaffold lib/sessionState.ts (SessionState builder for LLM prompts)
# Creates: src/lib/sessionState.ts
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

readonly SCRIPT_ID="22"
readonly SCRIPT_NAME="session-state-lib"
readonly SCRIPT_DESCRIPTION="Create SessionState builder for LLM context"

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]
$SCRIPT_DESCRIPTION
EOF
}

main() {
    parse_common_args "$@"
    init_logging "$SCRIPT_NAME"

    log_step "Creating session state builder"
    ensure_dir "src/lib"

    local session_state='import type { SessionState, ExtractedMetric, SessionPhase } from "./ai.types";

/**
 * Session State Builder
 *
 * Assembles the current session state for injection into
 * LLM system prompts. This provides context continuity.
 */

/**
 * Build session state from database/store data
 */
export async function buildSessionState(
  sessionId: string
): Promise<SessionState> {
  // TODO: Fetch from database
  // const session = await db.query.sessions.findFirst({
  //   where: eq(sessions.id, sessionId),
  //   with: { metrics: true, messages: true },
  // });

  return {
    sessionId,
    projectId: "placeholder",
    phase: "discovery",
    metrics: [],
    openQuestions: [],
    confidence: 0,
  };
}

/**
 * Calculate overall confidence from metrics
 */
export function calculateOverallConfidence(
  metrics: ExtractedMetric[]
): number {
  if (metrics.length === 0) return 0;

  const weights = {
    high: 1.0,
    medium: 0.6,
    low: 0.3,
  };

  const totalWeight = metrics.reduce((sum, m) => {
    const level = m.confidence >= 0.8 ? "high" :
                  m.confidence >= 0.5 ? "medium" : "low";
    return sum + weights[level];
  }, 0);

  return totalWeight / metrics.length;
}

/**
 * Determine phase based on session progress
 */
export function determinePhase(
  messageCount: number,
  metricCount: number,
  hasValidation: boolean
): SessionPhase {
  if (hasValidation) return "synthesis";
  if (metricCount > 5) return "validation";
  if (metricCount > 0) return "quantification";
  return "discovery";
}

/**
 * Serialize session state for prompt injection
 */
export function serializeSessionState(state: SessionState): string {
  return JSON.stringify(state, null, 2);
}
'

    write_file "src/lib/sessionState.ts" "$session_state"
    log_success "Script $SCRIPT_ID completed"
}

main "$@"
