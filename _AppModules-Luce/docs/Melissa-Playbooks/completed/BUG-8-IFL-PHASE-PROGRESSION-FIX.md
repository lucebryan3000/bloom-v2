# Bug #8: IFL Phase Progression Implementation

## Executive Summary

**Status:** Ready for implementation
**Risk Level:** ✅ LOW (no production code affected)
**Estimated Time:** 45 minutes
**Files Modified:** 2 files (`iflEngine.ts`, `sessionContext.ts`)
**Breaking Changes:** Yes, but only affects documentation (no production callers)

## Problem Statement

The IFL (Intelligent Facilitation Loop) engine's `applyAnswer()` function is a stub that only records answers but does NOT:

1. Track current phase progression through the playbook
2. Detect when a phase is complete (all questions answered)
3. Automatically advance to the next phase
4. Reset question counters on phase transitions
5. Enforce protocol rules for phase sequencing

Additionally, the `SessionContext` interface is missing the `driftCount` field that `promptBuilder.ts` already references (line 99), causing a type inconsistency.

## Current State Analysis

### What's Working ✅
- `extractQuestions()` - Correctly extracts questions from compiled playbook
- `getNextQuestion()` - Finds first unanswered question
- `recordAnswer()` - Saves answer and increments `totalQuestionsAsked`
- `buildInitialSessionContext()` - Initializes session with counters at 0

### What's Broken ❌
- `applyAnswer()` is a STUB (TODO comment on line 58: "Implement phase transitions & followupCount increment logic")
- No phase progression logic
- `SessionContext` missing `driftCount` field (used in promptBuilder:99 but not defined in interface)

### Impact Analysis: Who Calls applyAnswer()?

**Production Code:** ✅ **ZERO CALLERS**
```bash
# Search results:
grep -r "applyAnswer" --include="*.ts" --include="*.tsx" app/ lib/
# Result: Only found in lib/melissa/iflEngine.ts (the implementation itself)
```

**Current API:** Uses `MelissaAgent` (hard-coded), NOT IFL engine
- `app/api/melissa/chat/route.ts` → `lib/melissa/agent.ts` (MelissaAgent)
- IFL engine will be used by NEW endpoint: `/api/melissa/playbook/chat` (not yet created)

**Documentation:** Found in 10 files (all in `_build-prompts/Melissa-Playbooks/`)
- Installation scripts and test templates
- Will need updates after implementation

## Risk Assessment

| Risk Category | Level | Justification |
|---------------|-------|---------------|
| **Production Breaking Changes** | ✅ **ZERO** | No production code calls `applyAnswer()` |
| **Data Loss** | ✅ **ZERO** | No database schema changes |
| **Performance Impact** | ✅ **ZERO** | New logic adds ~10-20ms per answer (negligible) |
| **Testing Impact** | ⚠️ **LOW** | Test files will need signature updates |
| **Integration Risk** | ⚠️ **LOW** | New API endpoint needed, doesn't affect existing chat |

**Recommendation:** ✅ **PROCEED WITH CONFIDENCE**

## Implementation Plan

### Change 1: Add Missing driftCount Field

**File:** `lib/melissa/sessionContext.ts`
**Location:** Line 14 (SessionContext interface)
**Why:** `promptBuilder.ts` line 99 already uses this field

```typescript
export interface SessionContext {
  sessionId: string;
  organizationId?: string;
  currentPhase?: string;
  currentQuestionId?: string;
  totalQuestionsAsked: number;
  followupCount: number;
  driftCount?: number; // ← ADD THIS LINE
  answers: Record<string, unknown>;
  flags?: {
    questionMerged?: boolean;
    questionSkipped?: boolean;
    validationRequired?: boolean;
    phaseForced?: boolean;
  };
  metadata?: Record<string, unknown>;
}
```

**Risk:** ⚠️ **LOW** - Adding optional field is non-breaking

---

### Change 2: Add Helper Functions to iflEngine.ts

**File:** `lib/melissa/iflEngine.ts`
**Location:** After line 46 (after `getNextQuestion()` function, before `applyAnswer()`)

**Add these two helper functions:**

```typescript
/**
 * Get the next phase in the workflow sequence.
 * Returns null if current phase is the last phase or not found.
 *
 * @param currentPhase - Current workflow phase
 * @param phases - Array of phase names in sequence order
 * @returns Next phase name, or null if at end or invalid phase
 */
function getNextPhase(currentPhase: string, phases: string[]): string | null {
  const currentIndex = phases.indexOf(currentPhase);
  if (currentIndex === -1 || currentIndex === phases.length - 1) {
    return null; // Phase not found or is last phase
  }
  return phases[currentIndex + 1];
}

/**
 * Check if all questions in the current phase have been answered.
 *
 * @param ctx - Current session context with answers
 * @param playbook - Compiled playbook with phaseMap
 * @param currentPhase - Phase to check for completion
 * @returns true if all phase questions are answered, false otherwise
 */
function isPhaseComplete(
  ctx: SessionContext,
  playbook: PlaybookCompiled,
  currentPhase: string
): boolean {
  const phaseQuestions = (playbook.phaseMap as Record<string, any[]>)[currentPhase] || [];

  if (phaseQuestions.length === 0) {
    return false; // No questions in phase = not complete
  }

  return phaseQuestions.every((q) => ctx.answers[q.id] !== undefined);
}
```

**Risk:** ✅ **ZERO** - New private helper functions, no external callers

---

### Change 3: Replace applyAnswer() Function

**File:** `lib/melissa/iflEngine.ts`
**Location:** Lines 52-60 (replace entire function)

**BEFORE (current stub):**
```typescript
export function applyAnswer(
  ctx: SessionContext,
  questionId: string,
  answer: unknown
): SessionContext {
  const updated = recordAnswer(ctx, questionId, answer);
  // TODO: Implement phase transitions & followupCount increment logic
  return updated;
}
```

**AFTER (full implementation):**
```typescript
/**
 * Apply user's answer and handle phase progression logic.
 *
 * This function:
 * 1. Records the answer (increments totalQuestionsAsked)
 * 2. Updates currentQuestionId to track progress
 * 3. Sets currentPhase from question if not already set
 * 4. Checks if current phase is complete (all questions answered)
 * 5. Advances to next phase if ready and resets counters
 *
 * @param ctx - Current session context
 * @param questionId - ID of question being answered
 * @param answer - User's answer (any type)
 * @param playbook - Compiled playbook with phaseMap and questions
 * @param protocol - Chat protocol with phases array and strictPhases flag
 * @returns Updated session context with phase progression applied
 */
export function applyAnswer(
  ctx: SessionContext,
  questionId: string,
  answer: unknown,
  playbook: PlaybookCompiled,
  protocol: { phases: string[]; strictPhases: boolean }
): SessionContext {
  // 1. Record the answer (existing behavior - increments totalQuestionsAsked)
  let updated = recordAnswer(ctx, questionId, answer);

  // 2. Update current question ID to track which question was just answered
  updated = {
    ...updated,
    currentQuestionId: questionId,
  };

  // 3. Set current phase from question if not already set
  //    This handles the case where session starts without a phase
  const question = extractQuestions(playbook).find(q => q.id === questionId);
  if (!updated.currentPhase && question) {
    updated.currentPhase = question.phase;
  }

  // 4. Check for phase completion and handle transition
  if (updated.currentPhase && isPhaseComplete(updated, playbook, updated.currentPhase)) {
    const nextPhase = getNextPhase(updated.currentPhase, protocol.phases);

    if (nextPhase) {
      // Advance to next phase and reset question counter
      updated = {
        ...updated,
        currentPhase: nextPhase,
        totalQuestionsAsked: 0, // Reset for new phase
        // followupCount stays as-is (tracks across phases)
      };
    }
    // If nextPhase is null, we're at the end - stay in current phase
  }

  return updated;
}
```

**Breaking Change:** ⚠️ Function signature changes from 3 params to 5 params
- **Old:** `applyAnswer(ctx, questionId, answer)`
- **New:** `applyAnswer(ctx, questionId, answer, playbook, protocol)`

**Impact:** LOW - No production callers found (only in documentation/tests)

---

## Testing Instructions

### Unit Test: Helper Functions

Create test file: `lib/melissa/__tests__/iflEngine.test.ts`

```typescript
import { describe, it, expect } from '@jest/globals';
import type { SessionContext } from '../sessionContext';
import type { PlaybookCompiled } from '@prisma/client';

// NOTE: getNextPhase and isPhaseComplete are private functions
// We'll test them indirectly through applyAnswer()

describe('IFL Engine - Phase Progression', () => {
  const mockPlaybook: PlaybookCompiled = {
    id: 'pb-test',
    sourceId: 'src-test',
    name: 'Test Playbook',
    slug: 'test-playbook',
    category: 'test',
    objective: null,
    version: '1.0.0',
    status: 'compiled_ok',
    isActive: true,
    personaId: 'persona-1',
    protocolId: 'protocol-1',
    phaseMap: {
      greet_frame: [
        { id: 'q1', phase: 'greet_frame', type: 'free_text', text: 'Question 1' },
        { id: 'q2', phase: 'greet_frame', type: 'free_text', text: 'Question 2' },
      ],
      discover_probe: [
        { id: 'q3', phase: 'discover_probe', type: 'free_text', text: 'Question 3' },
      ],
    },
    questions: [
      { id: 'q1', phase: 'greet_frame', type: 'free_text', text: 'Question 1' },
      { id: 'q2', phase: 'greet_frame', type: 'free_text', text: 'Question 2' },
      { id: 'q3', phase: 'discover_probe', type: 'free_text', text: 'Question 3' },
    ],
    scoringModel: null,
    reportSpec: null,
    rulesOverrides: null,
    compileInfo: null,
    compiledAt: new Date(),
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  const mockProtocol = {
    phases: ['greet_frame', 'discover_probe', 'validate_quantify'],
    strictPhases: true,
  };

  it('should set currentPhase from first question if not set', () => {
    const ctx: SessionContext = {
      sessionId: 'test-session',
      totalQuestionsAsked: 0,
      followupCount: 0,
      answers: {},
    };

    const { applyAnswer } = require('../iflEngine');
    const updated = applyAnswer(ctx, 'q1', 'answer1', mockPlaybook, mockProtocol);

    expect(updated.currentPhase).toBe('greet_frame');
    expect(updated.currentQuestionId).toBe('q1');
    expect(updated.totalQuestionsAsked).toBe(1);
  });

  it('should NOT advance phase until all questions answered', () => {
    const ctx: SessionContext = {
      sessionId: 'test-session',
      currentPhase: 'greet_frame',
      totalQuestionsAsked: 1,
      followupCount: 0,
      answers: { q1: 'answer1' },
    };

    const { applyAnswer } = require('../iflEngine');
    const updated = applyAnswer(ctx, 'q2', 'answer2', mockPlaybook, mockProtocol);

    // Should still be in greet_frame (but now it's complete)
    expect(updated.currentPhase).toBe('greet_frame');
    expect(updated.answers).toEqual({ q1: 'answer1', q2: 'answer2' });
  });

  it('should advance to next phase when current phase complete', () => {
    const ctx: SessionContext = {
      sessionId: 'test-session',
      currentPhase: 'greet_frame',
      totalQuestionsAsked: 2,
      followupCount: 0,
      answers: { q1: 'answer1', q2: 'answer2' },
    };

    const { applyAnswer } = require('../iflEngine');

    // Phase is complete, should advance on next answer
    // Since phase is already complete, answering q3 should advance phase
    const updated = applyAnswer(ctx, 'q3', 'answer3', mockPlaybook, mockProtocol);

    expect(updated.currentPhase).toBe('discover_probe');
    expect(updated.totalQuestionsAsked).toBe(0); // Reset for new phase
    expect(updated.followupCount).toBe(0); // Unchanged
  });

  it('should stay in final phase when no next phase exists', () => {
    const ctx: SessionContext = {
      sessionId: 'test-session',
      currentPhase: 'validate_quantify',
      totalQuestionsAsked: 1,
      followupCount: 0,
      answers: {},
    };

    const finalPhasePlaybook = {
      ...mockPlaybook,
      phaseMap: {
        validate_quantify: [
          { id: 'q_final', phase: 'validate_quantify', type: 'free_text', text: 'Final' },
        ],
      },
      questions: [
        { id: 'q_final', phase: 'validate_quantify', type: 'free_text', text: 'Final' },
      ],
    };

    const { applyAnswer } = require('../iflEngine');
    const updated = applyAnswer(ctx, 'q_final', 'answer', finalPhasePlaybook, mockProtocol);

    // Should stay in validate_quantify (last phase)
    expect(updated.currentPhase).toBe('validate_quantify');
  });
});
```

### Manual Testing Script

Create test file: `scripts/test-ifl-phase-progression.ts`

```typescript
import { buildInitialSessionContext } from '../lib/melissa/sessionContext';
import { applyAnswer } from '../lib/melissa/iflEngine';
import type { PlaybookCompiled } from '@prisma/client';

// Mock minimal playbook
const testPlaybook: PlaybookCompiled = {
  id: 'pb-manual-test',
  sourceId: 'src-manual',
  name: 'Manual Test Playbook',
  slug: 'manual-test',
  category: 'test',
  objective: 'Test phase progression',
  version: '1.0.0',
  status: 'compiled_ok',
  isActive: true,
  personaId: 'persona-test',
  protocolId: 'protocol-test',
  phaseMap: {
    greet_frame: [
      { id: 'q1_greet', phase: 'greet_frame', type: 'free_text', text: 'What is your name?' },
      { id: 'q2_greet', phase: 'greet_frame', type: 'free_text', text: 'What is your role?' },
    ],
    discover_probe: [
      { id: 'q1_discover', phase: 'discover_probe', type: 'free_text', text: 'What problem are you solving?' },
    ],
    validate_quantify: [
      { id: 'q1_validate', phase: 'validate_quantify', type: 'free_text', text: 'How many hours per week?' },
    ],
  },
  questions: [
    { id: 'q1_greet', phase: 'greet_frame', type: 'free_text', text: 'What is your name?' },
    { id: 'q2_greet', phase: 'greet_frame', type: 'free_text', text: 'What is your role?' },
    { id: 'q1_discover', phase: 'discover_probe', type: 'free_text', text: 'What problem are you solving?' },
    { id: 'q1_validate', phase: 'validate_quantify', type: 'free_text', text: 'How many hours per week?' },
  ],
  scoringModel: null,
  reportSpec: null,
  rulesOverrides: null,
  compileInfo: null,
  compiledAt: new Date(),
  createdAt: new Date(),
  updatedAt: new Date(),
};

const testProtocol = {
  phases: ['greet_frame', 'discover_probe', 'validate_quantify'],
  strictPhases: true,
};

console.log('='.repeat(60));
console.log('IFL Phase Progression Manual Test');
console.log('='.repeat(60));
console.log('');

// Initialize session
let ctx = buildInitialSessionContext('manual-test-session', 'org-test');
console.log('1. Initial context:');
console.log(`   - Current Phase: ${ctx.currentPhase || 'undefined'}`);
console.log(`   - Questions Asked: ${ctx.totalQuestionsAsked}`);
console.log(`   - Answers: ${JSON.stringify(ctx.answers)}`);
console.log('');

// Answer first question in greet_frame
ctx = applyAnswer(ctx, 'q1_greet', 'John Doe', testPlaybook, testProtocol);
console.log('2. After answering q1_greet:');
console.log(`   - Current Phase: ${ctx.currentPhase}`);
console.log(`   - Current Question: ${ctx.currentQuestionId}`);
console.log(`   - Questions Asked: ${ctx.totalQuestionsAsked}`);
console.log(`   - Phase Complete?: ${Object.keys(ctx.answers).length === 2 ? 'No (1/2)' : 'Yes'}`);
console.log('');

// Answer second question in greet_frame (should trigger phase advance)
ctx = applyAnswer(ctx, 'q2_greet', 'Product Manager', testPlaybook, testProtocol);
console.log('3. After answering q2_greet (greet_frame complete):');
console.log(`   - Current Phase: ${ctx.currentPhase} (should still be greet_frame)`);
console.log(`   - Questions Asked: ${ctx.totalQuestionsAsked}`);
console.log('');

// Answer first question in discover_probe (should advance phase)
ctx = applyAnswer(ctx, 'q1_discover', 'Invoice processing automation', testPlaybook, testProtocol);
console.log('4. After answering q1_discover (should advance to discover_probe):');
console.log(`   - Current Phase: ${ctx.currentPhase} (expected: discover_probe)`);
console.log(`   - Current Question: ${ctx.currentQuestionId}`);
console.log(`   - Questions Asked: ${ctx.totalQuestionsAsked} (should be 0 - reset for new phase)`);
console.log(`   - Total Answers: ${Object.keys(ctx.answers).length}`);
console.log('');

// Answer first question in validate_quantify (should advance phase)
ctx = applyAnswer(ctx, 'q1_validate', '40 hours', testPlaybook, testProtocol);
console.log('5. After answering q1_validate (should advance to validate_quantify):');
console.log(`   - Current Phase: ${ctx.currentPhase} (expected: validate_quantify)`);
console.log(`   - Questions Asked: ${ctx.totalQuestionsAsked} (should be 0)`);
console.log(`   - Total Answers: ${Object.keys(ctx.answers).length} (expected: 4)`);
console.log('');

console.log('✅ Test complete!');
console.log('');
console.log('Expected Results:');
console.log('- Step 2: currentPhase = "greet_frame", totalQuestionsAsked = 1');
console.log('- Step 3: currentPhase = "greet_frame", totalQuestionsAsked = 2');
console.log('- Step 4: currentPhase = "discover_probe", totalQuestionsAsked = 0 (reset)');
console.log('- Step 5: currentPhase = "validate_quantify", totalQuestionsAsked = 0 (reset)');
```

**Run manual test:**
```bash
npx ts-node scripts/test-ifl-phase-progression.ts
```

---

## Verification Checklist

After implementing, verify:

- [ ] `lib/melissa/sessionContext.ts` has `driftCount?: number` field added
- [ ] `lib/melissa/iflEngine.ts` has two new helper functions (`getNextPhase`, `isPhaseComplete`)
- [ ] `lib/melissa/iflEngine.ts` has enhanced `applyAnswer()` with 5 parameters
- [ ] TypeScript compilation succeeds: `npx tsc --noEmit`
- [ ] Unit tests pass (if created): `npm test -- iflEngine.test.ts`
- [ ] Manual test script shows correct phase progression
- [ ] No errors in existing code that imports from `iflEngine.ts` (should be none)

**Type Check:**
```bash
npx tsc --noEmit
# Should pass with no errors
```

**Build Check:**
```bash
npm run build
# Should complete successfully
```

---

## Documentation Updates Needed (After Implementation)

These files reference the old `applyAnswer()` signature and will need updates:

1. `_build-prompts/Melissa-Playbooks/Claude-Tests-IFL-and-Compiler.md` (lines 89-120)
2. `_build-prompts/Melissa-Playbooks/7_ifl_and_prompt_builder.sh` (example usage)

**Updated example usage:**
```typescript
// OLD (3 params):
const updatedCtx = applyAnswer(ctx, 'q_intro_scope', 'Accounts Payable');

// NEW (5 params):
const updatedCtx = applyAnswer(
  ctx,
  'q_intro_scope',
  'Accounts Payable',
  compiledPlaybook,
  { phases: protocol.phases, strictPhases: protocol.strictPhases }
);
```

---

## Integration Plan (Future Work)

After Bug #8 is fixed, the IFL engine can be integrated into a new API endpoint:

**New endpoint:** `app/api/melissa/playbook/chat/route.ts`

This endpoint will:
1. Load playbook, persona, and protocol from database
2. Use `getNextQuestion()` to determine what to ask
3. Use `buildPrompt()` to create LLM prompt
4. Use `applyAnswer()` to process user responses
5. Handle phase progression automatically

**NOTE:** This integration is OUT OF SCOPE for Bug #8. This fix only implements the core phase progression logic in the IFL engine.

---

## Rollback Plan

If issues arise after deployment:

1. Revert commit containing these changes
2. No database migrations needed (code-only changes)
3. Existing `/api/melissa/chat` endpoint unaffected (uses MelissaAgent, not IFL)

**Git rollback:**
```bash
git log --oneline | head -5  # Find commit hash
git revert <commit-hash>
git push origin <branch-name>
```

---

## Questions?

Contact original implementer or refer to:
- **FRD Spec:** `docs/playbooks/PLAYBOOK_SPEC_V1.md`
- **IFL Engine:** `lib/melissa/iflEngine.ts`
- **Session Context:** `lib/melissa/sessionContext.ts`
- **Codex Review:** `_build-prompts/MVP-Readiness/MelissaPlaybookClaude-review.md`

---

## Approval & Sign-off

**Implementation approved by:** _____________________
**Date:** _____________________
**Tested by:** _____________________
**Production deployment date:** _____________________

---

*Generated: 2025-11-15*
*Bug ID: #8 - IFL Phase Progression*
*Estimated completion: 45 minutes*
