#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${ROOT_DIR}"

TARGET_DIR="lib/melissa"
mkdir -p "${TARGET_DIR}"

PROMPT_BUILDER="${TARGET_DIR}/promptBuilder.ts"
IFL_ENGINE="${TARGET_DIR}/iflEngine.ts"

if [[ ! -f "${PROMPT_BUILDER}" ]]; then
  cat > "${PROMPT_BUILDER}" <<'EOF'
import { MelissaPersona, ChatProtocol, PlaybookCompiled } from '@prisma/client';
import { SessionContext } from './sessionContext';

/**
 * Build the prompt to send to the LLM for the next turn.
 *
 * This function is intentionally simple for v1: it focuses on merging
 * persona, protocol, playbook, and current question into a single,
 * deterministic prompt string.
 *
 * TODO: Implement the full system prompt using the FRD / Persona spec.
 */
export function buildPrompt(params: {
  persona: MelissaPersona;
  protocol: ChatProtocol;
  playbook: PlaybookCompiled;
  ctx: SessionContext;
  question: { id: string; text: string; phase: string; type?: string; options?: string[] };
}): string {
  const { persona, protocol, playbook, ctx, question } = params;

  // NOTE: This is a placeholder. You should replace this with a richer
  // system+user message structure that encodes:
  // - Melissa persona description
  // - ChatProtocol constraints (oneQuestionMode, maxQuestions, etc.)
  // - Current playbook name / objective
  // - Current phase & question
  // - Relevant prior answers from ctx.answers
  const lines: string[] = [];

  lines.push(`You are ${persona.name} (${persona.slug}), an investigative synthesist helping a business user.`);
  lines.push(`Playbook: ${playbook.name} (${playbook.slug}) — category: ${playbook.category}`);
  if (playbook.objective) {
    lines.push(`Playbook objective: ${playbook.objective}`);
  }
  lines.push('');
  lines.push(`Current phase: ${ctx.currentPhase ?? 'unknown'}`);
  lines.push(`Question ID: ${question.id}`);
  lines.push(`Question: ${question.text}`);
  lines.push('');
  lines.push('Ask ONLY this one question, and wait for the user response. Do not answer on their behalf.');

  return lines.join('\n');
}
EOF
  echo "Created ${PROMPT_BUILDER}"
else
  echo "${PROMPT_BUILDER} already exists, skipping."
fi

if [[ ! -f "${IFL_ENGINE}" ]]; then
  cat > "${IFL_ENGINE}" <<'EOF'
import { PlaybookCompiled } from '@prisma/client';
import { SessionContext, recordAnswer } from './sessionContext';

/**
 * Basic representation of a compiled question.
 * In the future this should be aligned with the shape stored in PlaybookCompiled.questions.
 */
export interface CompiledQuestion {
  id: string;
  phase: string;
  text: string;
  type?: string;
  options?: string[];
}

/**
 * Extract questions from a PlaybookCompiled.questions JSON blob.
 * For now we assume it's an array of objects with at least { id, phase, text }.
 */
export function extractQuestions(playbook: PlaybookCompiled): CompiledQuestion[] {
  const raw = playbook.questions as any;
  if (!Array.isArray(raw)) return [];
  return raw.map((q) => ({
    id: String(q.id),
    phase: String(q.phase),
    text: String(q.text ?? ''),
    type: q.type ? String(q.type) : undefined,
    options: Array.isArray(q.options) ? q.options.map(String) : undefined,
  }));
}

/**
 * Determine the next question to ask given the SessionContext and playbook.
 * This is a minimal placeholder implementation that:
 * - walks questions in order
 * - skips ones that already have answers
 */
export function getNextQuestion(ctx: SessionContext, playbook: PlaybookCompiled): CompiledQuestion | null {
  const questions = extractQuestions(playbook);
  for (const q of questions) {
    if (!(q.id in ctx.answers)) {
      return q;
    }
  }
  return null;
}

/**
 * Apply an answer to the SessionContext and determine if we should advance phase, etc.
 * For v1 this simply records the answer and leaves phase management for future refinement.
 */
export function applyAnswer(
  ctx: SessionContext,
  questionId: string,
  answer: unknown
): SessionContext {
  const updated = recordAnswer(ctx, questionId, answer);
  // TODO: Implement phase transitions & followupCount increment logic according to ChatProtocol.
  return updated;
}
EOF
  echo "Created ${IFL_ENGINE}"
else
  echo "${IFL_ENGINE} already exists, skipping."
fi

echo "IFL engine & promptBuilder stubs created."
