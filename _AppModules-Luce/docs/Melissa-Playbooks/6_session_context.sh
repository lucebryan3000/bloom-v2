#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${ROOT_DIR}"

TARGET_DIR="lib/melissa"
mkdir -p "${TARGET_DIR}"

SESSION_FILE="${TARGET_DIR}/sessionContext.ts"

if [[ -f "${SESSION_FILE}" ]]; then
  echo "${SESSION_FILE} already exists, skipping."
  exit 0
fi

cat > "${SESSION_FILE}" <<'EOF'
/**
 * In-memory representation of a Melissa/Bloom session context.
 * This type is used by the IFL engine and prompt builder. Persistence
 * can be implemented using existing Session/Response tables.
 */

export interface Assumption {
  id: string;
  text: string;
  confidence: number; // 0–1 or 0–100 depending on convention
  source?: string; // e.g., "user", "system", "protocol"
}

export interface SessionContext {
  sessionId: string;
  organizationId?: string;

  personaId: string;
  protocolId: string;

  activePlaybookCompiledId: string | null;
  activePlaybookSlug: string | null;

  currentPhase: string | null;
  currentQuestionId: string | null;

  // Answer storage can be normalized later; for now a simple map.
  answers: Record<string, unknown>;
  scores: Record<string, number>;
  assumptions: Assumption[];

  followupCount: number;
  totalQuestionsAsked: number;
}

/**
 * Build an initial SessionContext.
 */
export function buildInitialSessionContext(params: {
  sessionId: string;
  personaId: string;
  protocolId: string;
  activePlaybookCompiledId?: string | null;
  activePlaybookSlug?: string | null;
  organizationId?: string;
}): SessionContext {
  return {
    sessionId: params.sessionId,
    organizationId: params.organizationId,
    personaId: params.personaId,
    protocolId: params.protocolId,
    activePlaybookCompiledId: params.activePlaybookCompiledId ?? null,
    activePlaybookSlug: params.activePlaybookSlug ?? null,
    currentPhase: null,
    currentQuestionId: null,
    answers: {},
    scores: {},
    assumptions: [],
    followupCount: 0,
    totalQuestionsAsked: 0,
  };
}

/**
 * Simple helper to record an answer in the context.
 * Actual persistence to the database should be implemented separately.
 */
export function recordAnswer(
  ctx: SessionContext,
  questionId: string,
  answer: unknown
): SessionContext {
  return {
    ...ctx,
    answers: {
      ...ctx.answers,
      [questionId]: answer,
    },
    totalQuestionsAsked: ctx.totalQuestionsAsked + 1,
  };
}
EOF

echo "SessionContext type created at ${SESSION_FILE}"
