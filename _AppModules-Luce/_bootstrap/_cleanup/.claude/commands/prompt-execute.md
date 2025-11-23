---
description: Multi-agent execution of an approved technical prompt against the codebase (implementation, refactor, and safety-checked application)
---

# Prompt Execute - Multi-Agent Prompt Execution & Implementation

> **This document is intended to be run as a Claude Code prompt command** (`/prompt-execute`).
> It specifies how to implement an already-validated technical specification, applying
> code changes to the codebase. Use this only after `/prompt-review` has validated the spec
> and you have explicitly approved it. This command is the "application phase" of the
> `/prompt-review` → `/prompt-execute` two-stage workflow.

You are **Claude Code (Sonnet)**, orchestrating parallel **Haiku agents** to **execute an already-approved technical prompt** against the actual codebase.

This command is used **only after** `/prompt-review` has validated and refined the specification and the user has explicitly approved it for execution.

The approved prompt/spec is treated as the **source of truth** for this execution.

---

## **Table of Contents**

1. **Quick Reference** - When to use this vs `/prompt-review`
2. **Guiding Principles** - Philosophy and execution values
3. **Architectural Pillars** - Five core design principles and how they work in practice
4. **Complete Execution Model** - All 7 phases explained sequentially
5. **Safety Constraints** - Non-negotiable safety requirements
6. **Implementation Details** - Technical architecture for parallel execution
7. **Absolute Rules** - Non-negotiable requirements
8. **Final Confirmation** - Pre-execution checklist

---

## **Quick Reference: Workflow with `/prompt-review`**

**These commands form a two-stage workflow. When to use each:**

| Stage | Command | Purpose |
|-------|---------|---------|
| **Stage 1: Validation** | `/prompt-review` (runs first) | Refine spec, verify against codebase, add missing context, identify gaps |
| **Stage 2: Execution** | `/prompt-execute` ← YOU ARE HERE | Execute validated spec with safety checks and checkpoints |

**Input to `/prompt-execute` comes from `/prompt-review`:**
- ✅ Spec is validated and approved by user
- ✅ File paths and line numbers are verified as current
- ✅ Prerequisites identified and validated (env vars, dependencies, types)
- ✅ **OPTIONAL:** PARALLEL EXECUTION GUIDANCE section present (if parallel work identified)

**Key workflow transition:**
1. User validates spec using `/prompt-review`
2. `/prompt-review` outputs validated spec (with corrections/additions applied)
3. User says "execute now"
4. User provides validated spec path to `/prompt-execute`
5. `/prompt-execute` treats spec as source of truth for implementation

**If spec needs refinement:** Stop and rerun `/prompt-review` first (do not proceed with `/prompt-execute`).

---

## **Guiding Principles (User-Defined)**

**Prompt Is Law (Within Reason):**
The validated prompt/spec is authoritative for this execution. Only deviate for safety, correctness, or to prevent obvious breakage.

**Code Safety Over Cleverness:**
Implement clear, maintainable solutions that match existing patterns. No clever abstractions unless explicitly required by the spec.

**Minimal Blast Radius:**
Touch only what is necessary to implement the spec. Avoid unrelated refactors. If more than 12 files need to change, pause and ask for confirmation.

**Two-Stage Workflow:**
- `/prompt-review` → validate and refine the spec (understand what needs to be done)
- `/prompt-execute` → implement and wire it into the codebase safely (do what was approved)

**No Surprises (Strict Adherence to Approved Spec):**
- Execution strictly follows the validated spec (approved explicitly by user)
- Implementation matches documented scope exactly—no additions, no optimizations, no "nice-to-haves"
- If spec appears incomplete, contradictory, or ambiguous during execution:
  - **STOP immediately before writing code**
  - Flag the issue with specific context for `/prompt-review` re-validation
  - Do NOT assume, guess, interpret, or proceed with assumptions
  - Wait for user to clarify or resubmit via `/prompt-review`
- **Key Boundary:** `/prompt-execute` is NOT a design or refinement tool. Design questions, scope uncertainty, or architectural decisions → back to `/prompt-review` immediately.

---

## **Architectural Pillars: Five Core Design Principles**

These five pillars form the foundation of `/prompt-execute`'s design. Each pillar solves a specific class of problems that can emerge during execution.

---

### **Pillar 1: Defensive by Default — Halt Conditions, Integrity Checks, Explicit Guardrails**

**Philosophy:**
The worst execution outcome isn't speed—it's silent failure or hidden assumptions that break the codebase. `/prompt-execute` assumes code will go wrong and builds explicit barriers to catch problems early.

**How It Works:**

#### **1.1 Halt Conditions (Automatic Stop Points)**

Halt conditions are **explicit stopping points** where execution pauses before proceeding. They prevent silent failures by making problems visible.

**Example Halt Condition 1: Missing Symbol**

```
User approves spec: "Add workflowId field to MelissaConfig model"

Execution proceeds to Phase 3: Pre-Execution Validation & Dependency Check

Validation finds:
  ❌ HALT: Phase 3.2 (Schema Alignment) failed
  → Referenced model "MelissaConfig" does not exist in prisma/schema.prisma
  → Found similar: MelissaSession, MelissaMessage, but no "MelissaConfig"

Action:
  STOP immediately. Do NOT generate patches.
  Report: "Schema model 'MelissaConfig' not found. Should this be:
    A) A new model to create?
    B) A different model name (MelissaSession?)?
    C) A field on an existing model?"
  Wait for user clarification before proceeding.
```

This prevents the silent failure of: generating code that references non-existent models → patches apply but later fail at runtime with "Model not found" errors.

**Example Halt Condition 2: Specification Ambiguity**

```
Spec says: "Add workflow configuration to Melissa"

During Phase 2 (Haiku agent coordination), agents propose:
  - Haiku-2 (Schema): Add workflowId field to Session
  - Haiku-4 (Core Logic): Create separate WorkflowConfig model
  - Haiku-5 (Tests): Tests assume WorkflowConfig is a separate table

Conflict detected (unresolvable by agent coordination rules):
  ❌ HALT: Phase 2 agent coordination failed
  → Three different interpretations of "workflow configuration"
  → No way to merge without changing spec semantics

Action:
  STOP before Phase 3. Do NOT attempt to pick the "best" approach.
  Report: "Spec is ambiguous about workflow storage model. Agents proposed:
    A) Field on existing Session model
    B) Separate WorkflowConfig table
    C) Hybrid approach
    Please clarify in spec, then resubmit via /prompt-review"
  Do NOT proceed with assumptions.
```

This prevents the failure mode of: executing one interpretation → later discovering user needed a different interpretation → wasted work + rework.

**Example Halt Condition 3: Dependency Failure**

```
Phase 5.2 (Core Logic Checkpoint): Applying logic changes

File being modified: lib/melissa/workflow.ts
Import needed: import { MelissaConfig } from "@/lib/melissa/config"

Pre-apply validation runs:
  ❌ CRITICAL IMPORT ERROR: File lib/melissa/config.ts does not exist
  ❌ HALT: Phase 5.2 cannot proceed

Action:
  STOP immediately. Do NOT apply changes.
  Rollback any prior checkpoints (Phases 5.1 is reversed).
  Report: "Cannot apply Phase 5.2: required file not found.
    - Expected file: lib/melissa/config.ts
    - Status: Does NOT exist in codebase
    Should this file:
    A) Be created as part of this execution?
    B) Already exist (was it deleted)?
    C) Be named something different?"
```

#### **1.2 Integrity Checks (Six-Category Validation)**

Before applying ANY phase, integrity checks verify the codebase is in a valid state to receive these changes.

**Example: CRITICAL Import Resolution Check (Phase 5.2)**

```
About to apply core logic changes to: lib/melissa/agent.ts

Integrity Check: Import Resolution

Checking all imports in the diff:
  ✓ import { Router } from "express" → File exists, export found
  ✓ import { MelissaSession } from "@/types" → Type exists in schema
  ✓ import { calculateROI } from "@/lib/roi/calculator" → Function exists, verified
  ❌ import { WorkflowStep } from "@/lib/workflow/steps" → FILE NOT FOUND

Result: IMPORT RESOLUTION CHECK FAILED
  → File lib/workflow/steps.ts does NOT exist
  → Patch references non-existent export
  → Cannot proceed to Phase 5.2 application

Action Options:
  1. HALT (Recommended): Stop and ask user for clarification
  2. ROLLBACK: Undo prior checkpoints (5.1) and exit
  3. MANUAL FIX: User creates missing file, then retry Phase 5.2
```

**Example: CRITICAL Type Safety Check (Phase 5.3)**

```
About to apply API route changes to: app/api/melissa/workflow/route.ts

Integrity Check: Type Safety

Scanning changed code:
  ✓ function parameter types: All annotated correctly
  ✓ function return types: All match actual returns
  ✓ Request/Response types: Aligned with TypeScript definitions
  ❌ Session field access: Code accesses session.workflowConfig
     But MelissaSession type in schema shows field as "workflowId" (string)
     Not "workflowConfig" (object)

Result: TYPE SAFETY CHECK FAILED
  → Code assumes workflowConfig is object
  → Schema defines workflowId as string
  → Type mismatch will fail TypeScript compilation

Action:
  HALT execution. Report: "Type mismatch in Phase 5.3:
    - Code expects: session.workflowConfig (object)
    - Schema defines: session.workflowId (string)
    Should Phase 5.1 (schema) have added a different field?
    Or should Phase 5.3 (API) use a different approach?"
```

#### **1.3 Explicit Guardrails (Hard Boundaries)**

Guardrails are non-negotiable limits that prevent catastrophic outcomes.

**Guardrail 1: File Count Limit**

```
Spec says: "Refactor entire Melissa subsystem"

Dry-run preview shows files to be modified:
  - lib/melissa/agent.ts
  - lib/melissa/config.ts
  - lib/melissa/types.ts
  - lib/roi/calculator.ts
  - app/api/melissa/chat/route.ts
  - app/api/melissa/workflow/route.ts
  - components/melissa/ChatInterface.tsx
  - components/melissa/ConfigPanel.tsx
  - components/melissa/WorkflowStep.tsx
  - tests/melissa/agent.test.ts
  - tests/melissa/workflow.test.ts
  - playwright/e2e/melissa-workflow.spec.ts
  [Plus 4 more = 16 files total]

Dry-run output shows: 16 files (exceeds 12-file limit)

Action:
  ⚠️  ALERT: File count exceeds safety limit of 12 files

  Options:
  1. Proceed anyway? → Requires explicit user confirmation
     (Confirmation message: "I understand this changes 16 files.
                            Proceed at my own risk.")

  2. Split into multiple runs?
     ("Would you like me to split this into 2 phases?
       Phase A (core): 7 files
       Phase B (tests + UI): 9 files")

  3. Narrow the scope?
     ("Can we defer test rewrites and focus on Phase A only?")
```

**Guardrail 2: Breaking Changes Detection**

```
Phase 5.3 (API routes checkpoint) modifies: app/api/sessions/[id]/route.ts

Integrity Check: Routing Integrity

Scan for breaking changes:
  ✓ GET /api/sessions/[id] → Still returns Session type (compatible)
  ❌ POST /api/sessions → Signature changed from:
       { name: string, config: Config } →
       { name: string, config: Config, workflow: Workflow }
     Existing clients passing only {name, config} will fail

Breaking change detected: POST /api/sessions request schema

Action:
  ⚠️  SOFT LIMIT TRIGGERED (Requires Confirmation)

  Report: "Phase 5.3 introduces breaking change:
    - Endpoint: POST /api/sessions
    - Change: workflow field added (required or optional?)
    - Impact: Existing API clients may fail

  Confirm you want this breaking change? (yes/no)"

  If user says NO: Modify spec (make workflow optional, or update migration plan)
  If user says YES: Add breaking change notice to Phase 5.3 summary
```

**Guardrail 3: Scope Creep Detection**

```
Approved spec: "Add logging to Melissa chat endpoint"

Phase 2 (agent planning) discovers:
  - Haiku-1: "To log properly, we should add structured logging to ALL endpoints"
  - Haiku-4: "While we're at it, let's improve error handling across the board"
  - Haiku-5: "Tests need to validate logging at multiple levels"

Scope creep detected:
  - Original scope: 1 endpoint (chat)
  - Proposed scope: All endpoints + error handling + logging infrastructure

Action:
  ❌ HALT: Scope Creep Detected (Phase 2)

  Report: "Phase 2 agent planning exceeded original spec scope:
    - Spec limited to: Melissa chat endpoint logging
    - Agents proposed: Org-wide logging + error handling refactor

    Original scope achievable in 4 files.
    Proposed scope requires 18+ files.

    Should we:
    A) Execute original scope only (4 files)
    B) Return to /prompt-review for expanded spec
    C) Create separate spec for org-wide logging?"

  Wait for user decision. Do NOT proceed with scope creep.
```

---

### **Pillar 2: User Clarity — Decision Matrices, Checklists, When-to-Use Guidance Prevent Misuse**

**Philosophy:**
Users are most likely to misuse tools when expectations are unclear or workflows are confusing. `/prompt-execute` provides explicit decision matrices and checklists to remove ambiguity.

**How It Works:**

#### **2.1 Decision Matrices (When to Use `/prompt-execute` vs `/prompt-review`)**

**Problem:** User doesn't know which tool to use, or uses the wrong tool.

**Solution:** Explicit decision matrix in "Quick Reference" section (lines 33-55).

```
When to use /prompt-review (Stage 1: VALIDATION):
┌─────────────────────────────────────────────────────────────────┐
│ ✓ Spec is unclear or ambiguous                                  │
│ ✓ You have questions about how to implement something           │
│ ✓ You're not sure if the spec covers everything needed          │
│ ✓ Spec hasn't been validated against the codebase yet           │
│ ✓ You want AI to find and fill in gaps                          │
│ ✓ You're refactoring and need to understand current state       │
└─────────────────────────────────────────────────────────────────┘

Example: "I want to add workflow support to Melissa, but I'm not sure
what needs to change. Where should I start?"
→ Use /prompt-review first

When to use /prompt-execute (Stage 2: EXECUTION):
┌─────────────────────────────────────────────────────────────────┐
│ ✓ Spec is clear and you've already validated it with /prompt-review
│ ✓ You're ready to write code and apply changes                 │
│ ✓ You understand the scope and have approved it                │
│ ✓ You want reliable, checkpointed execution with safety         │
│ ✓ You're confident in the approach and ready to commit          │
└─────────────────────────────────────────────────────────────────┘

Example: "I have an approved spec file. Execute it now."
→ Use /prompt-execute
```

**Real-World Scenario 1: User Confusion**

```
User says: "Add authentication to API endpoints"

User thinks: "Just add the code, I'll tell you where"
Correct approach: /prompt-review first

If user runs /prompt-execute directly:
  ❌ Execution fails at Phase 1
  → Spec is incomplete (which endpoints? which auth type? existing session system?)
  → /prompt-execute halts
  → Report: "Spec is too ambiguous. Use /prompt-review to clarify first."

Correct flow:
  1. User: "Add authentication to API endpoints"
  2. Claude: Use /prompt-review
     → Ask: Which endpoints? JWT? NextAuth? Session-based?
     → Scan: Find existing auth in codebase
     → Report: Findings + recommendations
  3. User: Reviews findings, clarifies approach
  4. User: "Execute the spec now"
  5. Claude: Use /prompt-execute with clear, validated spec
     → Phase 1: Load spec (clear and complete)
     → Phase 3: Validate all referenced models exist
     → Phase 5: Apply changes safely
     ✅ Execution succeeds
```

#### **2.2 Pre-Execution Checklist (User Responsibility)**

**Problem:** User runs `/prompt-execute` with a stale or invalid spec, wasting work.

**Solution:** Explicit checklist users must verify before execution (in "Final Confirmation" section).

```
## **Pre-Execution Checklist (User)**

Before running `/prompt-execute`, verify:

- [ ] **Spec Validation:** Spec was validated by `/prompt-review`
       (you ran it and reviewed findings)
- [ ] **Recommendations Applied:** All recommendations from
       `/prompt-review` were reviewed and incorporated into spec
- [ ] **Code Stability:** No new code changes since `/prompt-review`
       was run (would invalidate the scan)
- [ ] **Environment Ready:** Dependencies installed, database
       migrations done, builds passing
- [ ] **Review Time:** You have time to review the dry-run output
       (don't rush)
- [ ] **Recovery Ready:** You're prepared to handle any failures
       and re-run if needed
- [ ] **Spec Clarity:** Spec is clear and unambiguous
       (no lingering questions)

✅ All checkboxes checked? → Safe to run /prompt-execute
❌ Any unchecked? → Stop. Address the issue first.
```

**Real-World Scenario 2: Stale Spec**

```
Timeline:
  Day 1, 2:00 PM: User runs /prompt-review on spec.md
    → Findings: "MelissaConfig model not in schema, suggest adding it"
    → Report saved

  Day 1, 2:30 PM: Different developer adds MelissaConfig to schema
    → Committed to main branch

  Day 1, 3:00 PM: Original user runs /prompt-execute with spec from 2:00 PM
    → Spec references old findings (MelissaConfig doesn't exist)
    → But NOW it does exist (added at 2:30 PM)
    → Spec is STALE

  Checklist enforcement:
    [ ] Code Stability: New code changes since /prompt-review
        → Spec is STALE. Do NOT run /prompt-execute
        → Run /prompt-review again to re-scan with new code
```

#### **2.3 Execution Phase Guides (What Each Phase Does)**

Each phase is clearly documented with:
- **Purpose:** Why this phase exists
- **What happens:** Step-by-step actions
- **What you'll see:** Expected outputs
- **What can go wrong:** Common halt conditions
- **How to recover:** If this phase fails

**Example: Phase 2 Agent Coordination Guide**

```
## Phase 2: Parallel Agent Coordination (Haiku Planning)

**Purpose:** 5 Haiku agents build execution plans in parallel to:
  - Cover all 5 domains at once (no single point of failure)
  - Identify conflicts before code generation
  - Create detailed change specifications

**What Happens:**
  1. You approve the workflow transition from Phase 1 → Phase 2
  2. Agent Sonnet spawns 5 parallel Haiku agents:
     - Haiku-1: API & Routing (analyzes app/api/**/route.ts)
     - Haiku-2: Schema & Types (analyzes prisma/schema.prisma)
     - Haiku-3: UI Components (analyzes components/**)
     - Haiku-4: Core Logic (analyzes lib/**)
     - Haiku-5: Tests & E2E (analyzes tests/**, playwright/**)

  3. Each agent builds a detailed execution plan (not code yet)

  4. Haiku agents report back with:
     - Exact files to modify
     - Exact line ranges
     - Dependencies on other agents
     - Conflicts or ambiguities found

**What You'll See:**

  ✓ Haiku-1 Report (API & Routing):
    Files: 3 (new: 2, modified: 1)
    - NEW: app/api/melissa/workflow/route.ts
    - MODIFY: app/api/sessions/[id]/route.ts (lines 45-80)
    - NEW: lib/api/workflow-routes.ts
    Dependencies: Requires WorkflowConfig type (from Haiku-2)
    Conflicts: None

  ✓ Haiku-2 Report (Schema & Types):
    Files: 2 (modified: 2)
    - MODIFY: prisma/schema.prisma (add WorkflowConfig model)
    - MODIFY: lib/melissa/types.ts (export WorkflowConfig type)
    Dependencies: None (schema first)
    Conflicts: None

  [... and so on for Haiku-3, 4, 5]

**Phase 2 Coordination Summary:**
  Total files affected: 12
  Conflicts found: 0
  Halts triggered: 0
  Ready to proceed to Phase 3: ✓ YES

**What Can Go Wrong:**

  ❌ Conflict: Haiku-2 wants to add "workflowId" field
               Haiku-4 wants to add "workflowConfig" object
     → Agent coordination merges: Add both fields with clear semantics
     → Decision recorded in execution plan

  ❌ Missing model: Haiku-3 references "WorkflowUI" component
                   But component doesn't exist in codebase
     → Conflict flagged: "Component doesn't exist. Create or fix reference?"
     → Phase 2 halts
     → Report: "Spec references non-existent component"

**How to Recover:**
  If Phase 2 halts due to conflicts/missing references:
    1. Review conflict report carefully
    2. Return to /prompt-review to clarify spec
    3. Update spec to resolve conflict
    4. Run /prompt-execute again (starts from Phase 1)
```

---

### **Pillar 3: Reversibility — All Checkpoints Marked as Reversible with Recovery Strategies**

**Philosophy:**
Mistakes happen. When they do, recovery should be straightforward. `/prompt-execute` treats every checkpoint as a safe stopping point with clear rollback paths.

**How It Works:**

#### **3.1 Five Reversible Checkpoints (Phase 5)**

Each checkpoint in Phase 5 can be rolled back independently.

```
┌──────────────────────────────────────────────────────────────────────┐
│ Phase 5: Apply Changes in Checkpointed Phases (ALL REVERSIBLE)      │
└──────────────────────────────────────────────────────────────────────┘

Checkpoint 5.1: Schema & Types
├─ Files modified: prisma/schema.prisma, lib/melissa/types.ts
├─ Reversible: ✓ YES
├─ Recovery: git checkout HEAD -- prisma/schema.prisma lib/melissa/types.ts
└─ If fails: Rollback clears schema changes, no downstream impact

Checkpoint 5.2: Core Logic
├─ Files modified: lib/melissa/agent.ts, lib/roi/calculator.ts
├─ Reversible: ✓ YES (depends on 5.1 success)
├─ Recovery: git checkout HEAD -- lib/melissa/*.ts lib/roi/*.ts
└─ If fails: Can rollback both 5.2 and optionally 5.1

Checkpoint 5.3: API Routes
├─ Files modified: app/api/melissa/**/*.ts (2-4 files)
├─ Reversible: ✓ YES (depends on 5.1 + 5.2 success)
├─ Recovery: git checkout HEAD -- app/api/melissa/**/*.ts
└─ If fails: Can rollback 5.3, keep 5.1+5.2, or rollback all

Checkpoint 5.4: UI Components
├─ Files modified: components/melissa/*.tsx (3-5 files)
├─ Reversible: ✓ YES (depends on all prior checkpoints)
├─ Recovery: git checkout HEAD -- components/melissa/*.tsx
└─ If fails: Can keep all logic changes, just revert UI

Checkpoint 5.5: Tests
├─ Files modified: tests/**, playwright/**/*.spec.ts (2-4 files)
├─ Reversible: ✓ YES (non-blocking, most safe checkpoint)
├─ Recovery: git checkout HEAD -- tests/** playwright/**
└─ If fails: Production code is unchanged, only tests affected
```

#### **3.2 Checkpoint Failure Protocol**

When a checkpoint fails validation, the system provides clear recovery options:

```
## **Phase 5.3 Checkpoint Failure Example**

Scenario: API Routes checkpoint validation fails before applying changes

═══════════════════════════════════════════════════════════════════════
⚠️  CHECKPOINT FAILURE: Phase 5.3 (API Routes)
═══════════════════════════════════════════════════════════════════════

**Failure Reason:**
  Import validation failed in app/api/melissa/workflow/route.ts
  → Referenced type: WorkflowConfig
  → Expected: lib/melissa/types.ts (from Phase 5.1)
  → Status: Type not exported in 5.1 checkpoint

  Likely cause: Phase 5.1 was applied, but WorkflowConfig export
               was not included in the Schema & Types checkpoint

**Current State:**
  ✓ Phase 5.1 APPLIED: Schema changes in place
  ✓ Phase 5.2 APPLIED: Core logic changes in place
  ✗ Phase 5.3 FAILED: Import validation before applying changes
  ? Phase 5.4 PENDING: Not yet attempted
  ? Phase 5.5 PENDING: Not yet attempted

**Recovery Options:**

Option A: Fix Phase 5.1 (recommended if type export is missing)
  1. Add missing export to lib/melissa/types.ts
  2. Verify export is present: export type WorkflowConfig = { ... }
  3. Retry Phase 5.3

  Command: npm run build   # Verify TypeScript compiles first

Option B: Rollback Phase 5.2 + 5.3, keep Phase 5.1
  1. git checkout HEAD -- lib/melissa/*.ts lib/roi/*.ts
  2. Manually add export to lib/melissa/types.ts
  3. Restart /prompt-execute from Phase 5.2

  Command: git checkout HEAD -- lib/**/*.ts

Option C: Full rollback (undo all changes, restart from Phase 1)
  1. git checkout HEAD -- prisma/ lib/ app/api/
  2. Return to /prompt-review
  3. Clarify spec: "WorkflowConfig should be exported from types.ts"
  4. Resubmit via /prompt-review
  5. Run /prompt-execute again

  Command: git checkout HEAD -- prisma/ lib/ app/

**Which Option?**
  - Type export is simple fix → Option A (fix + retry 5.3)
  - Multiple issues across phases → Option C (full restart with fixes)
  - You've seen enough → Option B (selective rollback + manual fix)

Choose your option and let me know how to proceed.
```

#### **3.3 Recovery Guarantees**

Reversibility guarantees are documented:

```
## Recovery Guarantees During Execution

**Before Phase 5 (Dry-Run):**
  ✓ FULLY REVERSIBLE: No changes applied yet
  → If halt conditions triggered, just stop. Zero rollback needed.

**During Phase 5.1 (Schema & Types):**
  ✓ REVERSIBLE: git checkout HEAD -- prisma/ lib/melissa/types.ts
  → Clears ALL changes if needed
  → No downstream dependencies on schema yet (logic not applied)

**During Phase 5.2 (Core Logic):**
  ⚠️  PARTIALLY REVERSIBLE: Depends on Phase 5.1 being valid
  → If 5.2 fails: Rollback 5.2, keep 5.1, retry 5.2
  → If 5.2 breaks 5.1: Full rollback (5.1 + 5.2), restart

**During Phase 5.3 (API Routes):**
  ⚠️  PARTIALLY REVERSIBLE: Depends on 5.1 + 5.2 being valid
  → If 5.3 fails: Rollback 5.3 only, keep 5.1+5.2
  → Tests will fail (expect breakage) but logic is solid

**During Phase 5.4 (UI Components):**
  ⚠️  MOSTLY REVERSIBLE: Logic is fully committed, UI in progress
  → If 5.4 fails: Rollback 5.4 only
  → App is functional (UI just broken) but backend works
  → Can deploy backend to production, UI separately after fix

**During Phase 5.5 (Tests):**
  ✓ FULLY REVERSIBLE: Test failures don't affect runtime code
  → If 5.5 fails: Rollback 5.5, all other changes preserved
  → Production code is unaffected
  → Only tests need fixing
```

---

### **Pillar 4: Audit Trail — Git Integration with 3 Commit Triggers Creates Systematic Tracking**

**Philosophy:**
Systematic tracking enables blame analysis, recovery, and learning. Every change checkpoint gets a Git commit automatically, creating an audit trail of what changed and why.

**How It Works:**

#### **4.1 Three Automatic Commit Triggers**

```
┌─────────────────────────────────────────────────────────────────┐
│ Git Integration: When Commits Happen Automatically            │
└─────────────────────────────────────────────────────────────────┘

Trigger 1: PHASE CHECKPOINT COMPLETION (RECOMMENDED)
  When: After each Phase 5 checkpoint passes validation
  What: All files from that checkpoint stage
  Message: feat(/prompt-execute): Phase [N] - [Description]

  Examples:
    feat(/prompt-execute): Phase 5.1 - Schema & Types (Melissa workflow)
    feat(/prompt-execute): Phase 5.2 - Core Logic (Workflow routing)
    feat(/prompt-execute): Phase 5.3 - API Routes (Workflow endpoints)
    feat(/prompt-execute): Phase 5.4 - UI Components (Workflow panel)
    feat(/prompt-execute): Phase 5.5 - Tests & E2E (Workflow coverage)

  Result: 5 commits total (one per checkpoint)

Trigger 2: LINES OF CODE THRESHOLD (75+ lines)
  When: Cumulative changes exceed 75 lines before next checkpoint
  What: All accumulated changes since last commit
  Message: feat(/prompt-execute): [Stage] - [N lines] [description]

  Examples:
    feat(/prompt-execute): Core Logic - 102 lines (workflow state machine)
    feat(/prompt-execute): API Routes - 87 lines (3 endpoints)

  Frequency: 0-3 additional commits between phase checkpoints
  Result: Breaks up large phases into logical subchecks

Trigger 3: FILES MODIFIED THRESHOLD (6+ files)
  When: Files modified exceeds 6 files (50% of 12-file limit)
  What: All files from checkpoint + accumulated changes
  Message: feat(/prompt-execute): [Domain] - [N] files modified

  Examples:
    feat(/prompt-execute): Workflow - Modified 7 files (schema+logic+api)
    feat(/prompt-execute): UI - Modified 8 files (components+forms)

  Frequency: 1-2 additional commits when file count reaches threshold
  Result: Safety checkpoint when blast radius gets large
```

#### **4.2 Commit Message Format**

All commits use conventional commit syntax with phase metadata:

```
feat(/prompt-execute): [Scope] - [Description]

[Optional detailed description explaining what changed and why]

Spec: [Spec filename or reference]
Phase: [Which execution phase/checkpoint]
Files: [N] changed
Lines: [+X-Y] net additions/deletions
```

**Real Example 1: Schema Phase**

```
commit a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6

feat(/prompt-execute): Phase 5.1 - Schema & Types (Melissa workflow config)

Added WorkflowConfig model to Prisma schema with fields:
  - id (UUID primary key)
  - name (workflow configuration name)
  - steps (JSON array of workflow steps)
  - active (boolean, default true)

Added TypeScript types for WorkflowConfig and WorkflowStep.
Validated with prisma generate.

Spec: workflow-system-phase1.md
Phase: 5.1 (Schema & Types Checkpoint)
Files: 2 changed (prisma/schema.prisma, lib/melissa/types.ts)
Lines: +47-3 (net +44 lines)
```

**Real Example 2: Large API Phase**

```
commit b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7

feat(/prompt-execute): Phase 5.3 - API Routes (3 workflow endpoints)

Implemented workflow API endpoints:
  - POST /api/melissa/workflow → Create workflow
  - GET /api/melissa/workflow/:id → Retrieve workflow
  - PUT /api/melissa/workflow/:id → Update workflow

Integrated with existing session auth.
Validated with TypeScript compilation and route tests.

Spec: workflow-system-phase2.md
Phase: 5.3 (API Routes Checkpoint)
Files: 4 changed (3 new endpoint files, 1 modified auth middleware)
Lines: +156-12 (net +144 lines)
```

#### **4.3 Audit Trail: Finding What Changed and Why**

With systematic commits, understanding what changed becomes straightforward:

```
## Scenario: Production Issue - "Workflow stopped working on Tuesday"

Using the commit audit trail:

1. Find commits from Tuesday:
   $ git log --since="Tuesday 00:00" --until="Tuesday 23:59" --oneline

   a1b2c3d feat(/prompt-execute): Phase 5.3 - API Routes (3 workflow endpoints)
   b2c3d4e feat(/prompt-execute): Phase 5.2 - Core Logic (Workflow state machine)
   c3d4e5f feat(/prompt-execute): Phase 5.1 - Schema & Types (WorkflowConfig)

2. Review specific change:
   $ git show a1b2c3d

   Displays exact files modified, lines added/removed, and commit message

3. Check which endpoint broke:
   $ git diff a1b2c3d~1 a1b2c3d -- app/api/melissa/workflow/route.ts

   Shows exactly what changed in workflow endpoint

4. Find the issue (if needed):
   $ git blame app/api/melissa/workflow/route.ts | grep -A5 -B5 "workflowId"

   Shows exactly which commit introduced the problematic line

5. Revert if necessary:
   $ git revert a1b2c3d --no-edit

   Creates revert commit, undoes changes safely
```

#### **4.4 Git Commit Recovery Strategies**

If commits fail (network issue, permission denied, etc.):

```
## Commit Failure Recovery

Scenario: Phase 5.3 passes validation but commit fails

═══════════════════════════════════════════════════════════════════════
⚠️  COMMIT FAILURE DURING PHASE 5.3
═══════════════════════════════════════════════════════════════════════

**What Happened:**
  ✓ Phase 5.3 validation passed
  ✓ Files applied to disk
  ✗ git commit command failed
     Reason: Permission denied writing to .git/
     (or: remote rejected push, or: author config missing)

**Current State:**
  ✓ Code changes: APPLIED (in working directory)
  ✗ Git commit: FAILED (not recorded)
  ✓ Phase 5.4: PENDING

**Recovery Options:**

Option A: Retry commit (if it was a transient error)
  $ git add app/api/melissa/workflow/**/*.ts
  $ git commit -m "feat(/prompt-execute): Phase 5.3 - API Routes..."

  Then continue to Phase 5.4

Option B: Continue without commit (not recommended)
  - Phase 5.4 will proceed, applying UI changes
  - If Phase 5.4 fails, you lose ability to roll back Phase 5.3
  - Not recommended unless you're experienced with Git

Option C: Rollback and fix Git permissions
  1. git status  # Shows what's uncommitted
  2. git reset --hard HEAD  # Undo working directory changes
  3. Fix Git permissions (sudo chown, etc.)
  4. Restart /prompt-execute from Phase 5.1

  $ git reset --hard HEAD

**Which Option?**
  - If transient error (network) → Option A (retry)
  - If permissions issue → Option C (fix + restart)
  - If experienced → Option B (continue, careful)

Choose your recovery strategy.
```

---

### **Pillar 5: Phase Coherence — Agent Coordination Handles Conflicts in Parallel Execution**

**Philosophy:**
5 Haiku agents planning in parallel can propose overlapping or conflicting changes. Phase coherence ensures these conflicts are resolved systematically before code generation, preventing silent breakage.

**How It Works:**

#### **5.1 Agent Coordination Rules (Phase 2)**

```
┌──────────────────────────────────────────────────────────────────┐
│ Phase 2: How 5 Parallel Agents Work Together Without Stepping  │
│ on Each Other's Toes                                             │
└──────────────────────────────────────────────────────────────────┘

The 5 Agents:
  Haiku-1: API & Routing (app/api/** changes)
  Haiku-2: Schema & Types (prisma/** + lib/**/types.ts)
  Haiku-3: UI Components (components/**)
  Haiku-4: Core Logic (lib/** except types.ts)
  Haiku-5: Tests & E2E (tests/**, playwright/**)

Execution:
  1. All 5 agents receive: SCAN_CACHE (pre-computed batch results)
  2. All 5 agents build execution plans IN PARALLEL
  3. Plans are compared for conflicts
  4. Conflicts are resolved via Agent Coordination Rules
  5. Final unified execution plan is produced
```

#### **5.2 Example Conflict Scenarios and Resolutions**

**Conflict Scenario 1: Duplicate Field Addition**

```
Spec: "Add workflow tracking to sessions"

During Phase 2, agents propose:

  Haiku-2 (Schema): Add field to MelissaSession:
    + workflowId: String @unique
    + workflowCreatedAt: DateTime
    + workflowStatus: String

  Haiku-4 (Core Logic): Add field to Session entity:
    + workflowId: String
    + workflowConfig: JSON

Conflict Detected:
  ❌ Both agents want to add workflowId
  ❌ Haiku-4 also wants workflowConfig (not in Haiku-2's plan)
  ⚠️  Different semantics: "Config" (object) vs separate fields

Resolution Strategy (Agent Coordination):
  1. IDENTIFY DUPLICATE: Both want workflowId field
  2. MERGE: Keep Haiku-2's version (schema is source of truth)
  3. FLAG CONFLICT: workflowConfig vs separate fields
     - Ask: Should workflow config be JSON object or separate fields?
     - Decision: Follow existing patterns in codebase
     - Resolution: Check if other entities use JSON or separate fields
       → If codebase prefers JSON → use workflowConfig: JSON
       → If codebase prefers separate fields → add workflowConfig fields
  4. DOCUMENT: Add to Execution Plan:
     "Field Resolution: workflowId added by Haiku-2 (schema).
                        workflowConfig approach approved as [choice]."

Result:
  ✓ Duplicate removed (one workflowId)
  ✓ Conflict documented (workflowConfig: JSON approach decided)
  ✓ Clear semantics in final execution plan
```

**Conflict Scenario 2: Ordering Dependencies**

```
Spec: "Implement workflow feature end-to-end"

During Phase 2, agents discover:

  Haiku-2 (Schema): Adds WorkflowConfig model
  Haiku-4 (Core Logic): Imports WorkflowConfig type from schema
  Haiku-1 (API): Uses WorkflowConfig in request validation

Dependency Chain Detected:
  Schema (5.1) → Core Logic (5.2) → API Routes (5.3)

  Dependencies:
    Core Logic needs Schema fields → Must apply 5.1 first
    API Routes need Core Logic functions → Must apply 5.2 first

Ordering Resolution:
  1. TOPOLOGICAL SORT: Determine execution order
     - Schema (no dependencies) → First
     - Core Logic (depends on schema) → Second
     - API Routes (depends on logic) → Third
     - UI Components (depends on API) → Fourth
     - Tests (depends on all) → Fifth

  2. DOCUMENT ORDERING: Execution Plan shows:
     "Phase 5.1 (Schema) must complete before 5.2 (Logic)
      Phase 5.2 must complete before 5.3 (API)
      Phase 5.3 must complete before 5.4 (UI)
      Parallel execution NOT allowed for this spec."

  3. SEQUENTIAL EXECUTION: Enforce ordering
     - Run 5.1 checkpoint
     - Validate 5.1 success before running 5.2
     - If 5.1 fails, halt and ask
     - Never skip directly to 5.2 if 5.1 not completed

Result:
  ✓ Ordering enforced by execution model
  ✓ Checkpoints prevent skipping ahead
  ✓ Dependencies explicitly documented
```

**Conflict Scenario 3: Incompatible Approaches**

```
Spec: "Add workflow state machine to Melissa"

During Phase 2, agents propose different implementations:

  Haiku-2 (Schema): Add state field:
    state: String  // enum: "initial" | "active" | "paused" | "complete"

  Haiku-4 (Core Logic): Implement state machine with strategy pattern:
    // Separate StateStrategy implementations for each state
    class InitialState { ... }
    class ActiveState { ... }
    class CompleteState { ... }

  Haiku-5 (Tests): Test coverage assumes Haiku-4's strategy pattern
    // Tests mock strategy implementations

Conflict Detected:
  ❌ Incompatible abstractions (enum string vs strategy pattern)
  ❌ Haiku-2 models state as simple field
  ❌ Haiku-4 models state as complex pattern
  ⚠️  Tests only work with strategy pattern approach

Resolution Strategy:
  1. IDENTIFY INCOMPATIBILITY: Schema vs Logic abstraction mismatch
  2. CHOOSE APPROACH: Apply "Minimal Blast Radius" principle
     - Approach A (Enum field): 1 model change, simpler code
     - Approach B (Strategy pattern): 5+ new classes, more complex
     → Approach A has lower blast radius
     → BUT: Does spec require complex state machine logic?
  3. CHECK CODEBASE: What patterns exist?
     - Search for existing state machines in codebase
     - Search for existing strategy patterns
     → If codebase uses strategy patterns → align with Approach B
     → If codebase uses simple enums → align with Approach A
  4. DECIDE: Based on codebase patterns
     Decision: "Schema uses simple enum field. Logic implements
               validation functions (not strategy pattern) for
               state transitions."
  5. REALIGN ALL AGENTS: Update plans to use enum + validators

Result:
  ✓ All agents now have coherent approach
  ✓ No conflicting abstractions
  ✓ Aligned with existing codebase patterns
  ✓ Tests now work with unified approach
```

**Conflict Scenario 4: Scope Boundaries**

```
Spec: "Add workflow logging capability"

During Phase 2, agents propose scope creep:

  Haiku-1 (API): "Should we add logging endpoint for all routes?"
  Haiku-4 (Core Logic): "Should we add audit trail for all operations?"
  Haiku-3 (UI): "Should we add real-time log viewer?"
  Haiku-5 (Tests): "Should we add comprehensive logging coverage?"

Scope Creep Detected:
  Spec: "workflow logging capability" (narrow)
  Proposed: Org-wide logging infrastructure + UI viewer (broad)

Scope Resolution:
  1. RETURN TO SPEC: Original spec says "workflow logging capability"
     → Not "org-wide logging"
     → Not "real-time viewer"
     → Just "workflow logging"
  2. CONSTRAIN AGENT PROPOSALS: Tell agents:
     "Stay within original scope. Only:
      - Add logging to workflow functions
      - Track workflow lifecycle events
      - Store logs with workflow records
      Nothing else."
  3. REJECT OUT-OF-SCOPE PROPOSALS: Haiku agents revise plans
  4. FINALIZE: Only workflow-specific logging in execution plan

Result:
  ✓ Scope stays focused
  ✓ Execution plan is minimal
  ✓ No feature creep
  ✓ Prevents "just one more thing" spiral
```

#### **5.3 Phase Coherence Guarantees**

```
## Guarantees After Phase 2 Agent Coordination

After all 5 agents complete and conflicts are resolved:

✅ **Semantic Coherence**
   All proposed changes use consistent abstractions and patterns
   (No mixing of enum vs strategy pattern in one feature)

✅ **Dependency Ordering**
   If A depends on B, then A's checkpoint comes after B's
   (Schema before Logic, Logic before API, API before UI, UI before Tests)

✅ **Scope Containment**
   Changes implement exactly what the spec requires
   No scope creep beyond original specification

✅ **No Duplication**
   If multiple agents proposed the same change, it appears once
   (Only one workflowId field, not multiple)

✅ **Conflict Resolution**
   All conflicting proposals have documented decisions
   Each conflict shows:
     - What was proposed by which agents
     - Why the conflict exists
     - How it was resolved
     - Why that resolution was chosen

✅ **Codebase Alignment**
   All changes follow existing patterns and conventions
   (Uses enums like existing code, not new strategy patterns)

✅ **Execution Feasibility**
   The execution plan can be applied successfully
   (All dependencies will be met during checkpointed execution)
```

---

## **Summary: Five Pillars Working Together**

These five pillars create a cohesive execution framework:

```
1. DEFENSIVE BY DEFAULT
   ↓ Prevents silent failures with halt conditions
   ↓ Catches problems early with integrity checks
   ↓ Explicitly documents guardrails

2. USER CLARITY
   ↓ Users know when to use /prompt-execute vs /prompt-review
   ↓ Checklists prevent misuse
   ↓ Each phase is clearly documented

3. REVERSIBILITY
   ↓ Every checkpoint is a safe stopping point
   ↓ Rollback strategies documented for each checkpoint
   ↓ No permanent damage from mistakes

4. AUDIT TRAIL
   ↓ Git commits create systematic tracking
   ↓ Every change is recorded with context
   ↓ Recovery from failures is traceable

5. PHASE COHERENCE
   ↓ Parallel agents coordinate without conflicts
   ↓ Execution order is topologically sorted
   ↓ No scope creep or semantic misalignment

RESULT: Reliable, safe, recoverable, transparent, coordinated execution
```

---

## **Complete Execution Model - All 7 Phases**

### **Phase 1: Load Prompt & Build Execution Plan**

1. Load the approved prompt file in full.
2. Extract key information:
   - Explicit tasks (e.g., "Add endpoint /api/admin/melissa/workflow")
   - Implicit tasks (e.g., "Wire WorkflowTab to config API")
   - Affected domains:
     - Schema (`prisma/schema.prisma`)
     - Core logic (`lib/melissa/*`, `lib/api/*`, `lib/db/*`)
     - APIs (`app/api/**/route.ts`)
     - UI (`components/**`)
     - Tests (`tests/**`, `playwright/**`, etc.)

3. Build an internal **Execution Plan** with:
   - Task ID and description
   - Target files and line ranges
   - Risk level (Low/Medium/High)
   - Dependencies (sequential vs parallel)

**Do not modify any files yet.** Proceed to Phase 1.5.

---

### **Phase 1.5: Batch Background Scans (Parallel Codebase Map)**

**Critical Optimization:** Sonnet launches **ALL Phase 1.5 scans as background processes IN A SINGLE BATCH**, grouped logically by domain. These run **in parallel** before any Haiku agents start.

#### **Batch Architecture**

**Batch 1: Project Layout & API Routes** (Supports Haiku-1)
```bash
find . -maxdepth 4 -type f | sort
find app/api -type f | sort
grep -RIn "export async function" app/api
grep -RIn "GET\|POST\|PUT\|DELETE" app/api
```

**Batch 2: Database Schema** (Supports Haiku-2)
```bash
grep -RIn "model " prisma/schema.prisma
grep -RIn "@\(unique\|id\|default\|relation\)" prisma/schema.prisma
grep -RIn "type\|relation\|@db\." prisma/schema.prisma
```

**Batch 3: UI Components & Patterns** (Supports Haiku-3)
```bash
find components -type f | sort
grep -RIn "export function\|export default\|export const" components/
grep -RIn "interface.*Props\|type.*Props" components/
```

**Batch 4: Melissa Core & Agent Logic** (Supports Haiku-4)
```bash
find lib/melissa -type f | sort
grep -RIn "class\|export function\|export const" lib/melissa/
grep -RIn "getMelissaConfig\|MelissaAgent\|conversationFlow\|systemPrompt" lib/melissa/
```

**Batch 5: Utilities, Helpers & Testing** (Supports Haiku-5)
```bash
find lib -type f | sort
find tests -type f 2>/dev/null | sort
find playwright -type f 2>/dev/null | sort
grep -RIn "export function\|export const" lib/
```

**Batch 6: Config, Environment & Dependencies** (Supports Planning)
```bash
grep -RIn "process.env" . --include="*.ts" --include="*.tsx" --include="*.js" | head -30
find . -name ".env*" -o -name "package.json"
grep -RIn "import.*from\|require" lib/melissa/ | head -40
```

#### **Execution Strategy**

**Sonnet's responsibility in this phase:**

1. **Prepare all 6 batch scan commands** (no execution yet)

2. **Launch Batches 1-6 as parallel background processes:**
   - Use Bash tool with all independent scans in a single message (parallel execution)
   - Cache all results in memory for reuse

3. **Consolidate all scan results into a structured cache:**
   ```
   SCAN_CACHE = {
     "api_routes": [results from Batch 1],
     "schema": [results from Batch 2],
     "components": [results from Batch 3],
     "melissa": [results from Batch 4],
     "testing": [results from Batch 5],
     "config": [results from Batch 6]
   }
   ```

4. **Pass structured cache to each Haiku agent:**
   - Each Haiku agent receives only its relevant batch slice
   - No agent re-runs the same scan
   - Eliminates redundant queries across 5+ agents

---

### **Phase 2: Multi-Agent Execution Planning (Parallel Agent Batch)**

**Sonnet now spawns 5 parallel Haiku agents IN A SINGLE MESSAGE**, passing each agent its pre-computed batch scan results from Phase 1.5. No redundant queries. No sequential processing.

Use Task tool with `model="haiku"` to launch all 5 agents in parallel with this structure:

```
Sonnet sends ONE message with 5 Task tool invocations:
├─ Task 1: Haiku-1 (API & Routing) + SCAN_CACHE["api_routes"]
├─ Task 2: Haiku-2 (Schema & Data) + SCAN_CACHE["schema"]
├─ Task 3: Haiku-3 (UI & Components) + SCAN_CACHE["components"]
├─ Task 4: Haiku-4 (Core Logic) + SCAN_CACHE["melissa"]
└─ Task 5: Haiku-5 (Testing) + SCAN_CACHE["testing"] + SCAN_CACHE["config"]
```

All 5 agents execute in parallel, each analyzing their specific domain against the approved prompt.

---

**Haiku-1: API & Routing Execution Plan**
- **Input:** SCAN_CACHE["api_routes"] (Batch 1 results) + approved prompt
- **Task:** Build detailed API execution plan
  - Map all endpoints to be created/modified by the prompt
  - Determine exact changes to `app/api/**/route.ts` files
  - Plan request/response shapes, status codes, error handling patterns
  - Identify routing conflicts, middleware requirements, or auth gates needed
- **Outputs Expected:**
  - List of endpoints (new vs. modified) with exact paths
  - For each endpoint: specific changes needed, error cases handled, dependencies flagged
  - Any naming conflicts or pattern violations flagged
  - Recommendation on ordering if endpoints depend on each other
- **Discover:**
  - If a referenced endpoint doesn't exist in codebase (needs creation)
  - If an API change could break other routes (flag dependency)
  - If request/response types need to be added to shared types

**Haiku-2: Schema & Data Model Execution Plan**
- **Input:** SCAN_CACHE["schema"] (Batch 2 results) + approved prompt
- **Task:** Build database change plan
  - Inspect `prisma/schema.prisma` against prompt requirements
  - Decide if schema changes, new models, or new fields are required
  - Identify potential migrations and TS type updates needed
  - Flag any breaking changes or migration concerns
- **Outputs Expected:**
  - List of schema changes (new models, new fields, modified relations)
  - For each change: exact line location, field types, defaults, constraints
  - Migration strategy (if applicable)
  - TypeScript type file updates required
- **Discover:**
  - If referenced models/fields don't exist yet (creation needed)
  - If schema changes conflict with existing data types
  - If relations need to be created or modified

**Haiku-3: UI & Component Execution Plan**
- **Input:** SCAN_CACHE["components"] (Batch 3 results) + approved prompt
- **Task:** Build component modification plan
  - Inspect `components/` and `app/(routes)` UIs
  - Determine which components need new props, views, panels
  - Identify new settings UI, workflow displays, or ROI components
  - Plan component wiring and state management updates
- **Outputs Expected:**
  - List of components to create or modify
  - For each component: props to add/modify, state hooks needed, event handlers
  - Any new UI patterns or design system components needed
  - Component hierarchy and nesting changes
- **Discover:**
  - If imported components exist and where they're located
  - If new props conflict with existing component interfaces
  - If state management (Zustand) stores need updates

**Haiku-4: Core Logic & Services Execution Plan**
- **Input:** SCAN_CACHE["melissa"] (Batch 4 results) + approved prompt
- **Task:** Build business logic execution plan
  - Inspect `lib/melissa/*`, `lib/api/*`, `lib/db/*`
  - Plan how new behavior fits into Melissa agent architecture
  - Identify config loaders, calculators, routers, KB/RAG layers
  - Flag any conflicts with existing patterns or flows
- **Outputs Expected:**
  - List of functions/services to create or modify
  - For each: exact location, parameters, return types, side effects
  - New imports or utilities needed
  - Integration points with existing services
- **Discover:**
  - If referenced functions exist and their signatures
  - If new utilities conflict with existing helpers
  - If service dependencies create circular imports

**Haiku-5: Testing & Configuration Execution Plan**
- **Input:** SCAN_CACHE["testing"] + SCAN_CACHE["config"] (Batch 5-6 results) + approved prompt
- **Task:** Build comprehensive test plan
  - Inspect `tests/**`, `jest.config*`, Playwright configs
  - Decide which new tests to create, which existing tests to update
  - Identify minimum coverage requirements for new code
  - Plan any new test fixtures, mocks, or helper functions
- **Outputs Expected:**
  - List of new test files and existing test files to update
  - For each test: description, test cases, mocks/fixtures needed
  - Coverage targets for new code
  - Any environment variables or config changes for testing
- **Discover:**
  - If test patterns match project conventions
  - If mocked dependencies exist in test utilities
  - If environment setup needs changes

---

### **Phase 2 Agent Coordination: Handling Conflicts**

When 5 Haiku agents build execution plans in parallel, conflicts or overlaps may arise. Use this resolution strategy:

**Example Conflict Scenarios:**

1. **Duplicate Changes:**
   - Haiku-2 (Schema) wants to add field `workflowId` to `MelissaConfig` model
   - Haiku-4 (Core Logic) also wants to add `workflowId` to `MelissaConfig` model
   - **Resolution:** Merge duplicate field additions → single schema change, both agents reference it

2. **Ordering Dependencies:**
   - Haiku-2 (Schema) adds field `workflowId`
   - Haiku-4 (Core Logic) needs to reference that field
   - **Resolution:** Identify ordering: Schema changes first, then core logic can reference it

3. **Conflicting Approaches:**
   - Haiku-3 (UI) proposes adding workflow editor as Modal dialog
   - Haiku-4 (Core Logic) assumes inline workflow form
   - **Resolution:** Sonnet decides based on spec, existing patterns, and minimal file changes

**Resolution Strategy:**

1. **Identify Duplicates:** Flag any overlapping changes (same file, same function, same model field)
2. **Merge Results:** Combine duplicate efforts into single implementation point
3. **Flag Dependencies:** If one agent's output depends on another's:
   - Document in Execution Plan: "Step 1 must complete before Step N"
   - Show dependency graph if complex (e.g., Schema → Logic → API → UI)
4. **Resolve Conflicts:** When agents propose different approaches:
   - **Prefer approach requiring fewer file changes** (matches "Minimal Blast Radius" principle)
   - **Follow existing code patterns** (consistency over innovation)
   - **Document decision** in Execution Plan with rationale
5. **Prioritize Order:** Build execution sequence:
   - Schema changes first (foundation)
   - Core logic (depends on schema)
   - API endpoints (depends on logic)
   - UI components (depends on API)
   - Tests (depends on all above)

**After Conflict Resolution:**

Build **Merged Execution Plan** that Sonnet will follow in Phases 3-7:
- Combined set of tasks with ordering constraints
- Duplicates eliminated, dependencies documented
- Each task traced to which agent(s) identified it
- Rationale documented for any resolved conflicts

---

**After all 5 agents report and conflicts are resolved**, Sonnet has a coherent, ordered **Execution Plan** that Phases 3-7 will follow.

---

### **Phase 3: Pre-Execution Validation & Dependency Check**

Before generating any patches, validate that all planned changes are grounded in the actual codebase:

**1. File Existence Validation:**
- Every file you plan to touch actually exists
- If creating a new file, confirm target directory exists (or document if you'll create it)

**2. Import Validation (CRITICAL):**
- Any symbols you intend to import already exist (functions, types, components, hooks, utilities)
- Prisma models and fields referenced in code exist in `schema.prisma`
- Config constants and enums you'll use are defined
- Third-party imports are available (package.json dependencies)

**3. Schema Alignment:**
- All database model references match `prisma/schema.prisma`
- Field names, types, and relations are correctly spelled and defined
- New models/fields you'll create don't conflict with existing ones

**4. New File Readiness:**
- For any file you'll create:
  - Confirm directory exists or will be created
  - Confirm naming follows project conventions (PascalCase for components, camelCase for utils, SCREAMING_SNAKE_CASE for constants)
  - Ensure no naming conflicts with existing files

**Halt Condition (CRITICAL):**
If any planned symbol, path, or file doesn't exist and isn't clearly marked for creation:
- **STOP immediately** before generating patches
- Ask user for clarification on the missing reference
- **Do NOT hallucinate, guess, or assume** what the missing piece should be
- Return to user: "I found references to X which doesn't exist in the codebase. Should this be created, or is there a different approach?"

---

### **Phase 4: Dry-Run Patch Generation (No Files Changed Yet)**

Generate a **dry-run diff** of all proposed changes **without applying them**. Use standardized format for clarity.

#### **Diff Format Specification (Standardized)**

For each file, use one of these three formats consistently:

**Format 1: File Creation (NEW)**
```diff
--- filepath/to/file.ts (NEW)
+++ filepath/to/file.ts
@@ New file @@
+export function myFunction() {
+  // implementation
+}
```

**Format 2: File Modification (EXISTING)**
```diff
--- filepath/to/file.ts
+++ filepath/to/file.ts
@@ Line X-Y: Description of change @@
 // context line (unchanged)
-old line being removed
+new line being added
 // context line (unchanged)
```

**Format 3: Schema Changes (prisma/schema.prisma)**
```diff
--- prisma/schema.prisma
+++ prisma/schema.prisma
@@ model ModelName @@
 model ModelName {
   existingField  String
+  newField       String @default("value")
   anotherField   Int
 }
```

#### **Summary Block After All Diffs**

Provide a consolidation summary:

```
═══════════════════════════════════════════════════════════════
FILES CHANGED SUMMARY:
═══════════════════════════════════════════════════════════════

Created: 2 files
  - app/api/admin/melissa/workflow/route.ts
  - lib/melissa/workflow.ts

Modified: 3 files
  - lib/melissa/agent.ts (12 lines added, 3 removed)
  - components/settings/MelissaWorkflowTab.tsx (18 lines added)
  - tests/lib/melissa/agent-workflow.test.ts (8 lines added)

Schema: 1 change
  - MelissaConfig: added workflowId field

Total Lines: +48 lines | -3 lines
Total Files: 6 files (default limit: 12)
```

#### **Pre-Application Checks**

* **File Count Check:** Is total files ≤ 12? (default limit)
  * If exceeds: Present file list, ask for confirmation or scope refinement
* **Risk Assessment:** Any large files (>1000 lines) with substantial changes (>50 lines)?
  * If yes: Highlight impact summary
* **Breaking Changes:** Any modifications to public API contracts?
  * If yes: List all breaking changes explicitly

**Do not proceed to Phase 5 until user confirms the dry-run.**

---

### **Phase 5: Apply Changes in Checkpointed Phases**

Once the user has approved the dry-run diff (and possibly the larger file count), apply changes in ordered phases. **Each checkpoint is designed to be reversible.**

**Important Checkpoint Philosophy:**
- Each checkpoint is a safe stopping point
- If a checkpoint fails validation, **stop immediately** (don't proceed to next checkpoint)
- Failed checkpoints are **reversible** — user can decide to roll back or fix inline
- Report exactly which files were applied before checkpoint failed

#### **5.1 Schema & Types (Checkpoint 1 - REVERSIBLE)**

* Apply any changes to `prisma/schema.prisma`
* Apply directly related TS type/interface updates
* **Validation after checkpoint:**
  * No syntax errors in schema file
  * No obvious mismatched field names between schema and code
  * All new fields have appropriate types and defaults
  * No duplicate field names in models
* **If validation fails:**
  - ✋ STOP immediately
  - Report: "Schema validation failed: [specific error]"
  - User can: Roll back and resubmit spec, or fix manually

#### **5.2 Core Logic & Services (Checkpoint 2 - REVERSIBLE)**

* Apply changes to `lib/melissa/*`, `lib/api/*`, `lib/db/*`, etc.
* **Validation after checkpoint:**
  * All imports refer to real files and symbols
  * No obvious type mismatches between changed files
  * No circular dependencies introduced
  * Function signatures match their callers
* **If validation fails:**
  - ✋ STOP immediately
  - Report: "Import/type error in [file]: [specific error]"
  - User can: Roll back and clarify spec, or fix manually

#### **5.3 API Handlers (Checkpoint 3 - REVERSIBLE)**

* Apply changes to `app/api/**/route.ts`
* **Validation after checkpoint:**
  * Route methods correct (GET/POST/PUT/DELETE)
  * Request/response types consistent with route signature
  * Input validation patterns match project conventions
  * Auth/middleware requirements documented
* **If validation fails:**
  - ✋ STOP immediately
  - Report: "Route validation failed: [specific error]"
  - User can: Roll back, or fix route handlers

#### **5.4 UI Components (Checkpoint 4 - REVERSIBLE)**

* Apply updates to `components/**`
* **Validation after checkpoint:**
  * Component prop definitions match usage
  * All imported components exist
  * State management stores (Zustand) reference real functions
  * No obvious unused imports or dead props
  * Event handlers wired to real functions
* **If validation fails:**
  - ✋ STOP immediately
  - Report: "Component validation failed: [specific error]"
  - User can: Roll back or fix components manually

#### **5.5 Tests (Checkpoint 5 - REVERSIBLE)**

* Apply new or updated tests under `tests/**` or `playwright/**`
* **Validation after checkpoint:**
  * Test imports resolve to real modules
  * Test names clearly describe behavior
  * Mocks reference valid modules/functions
  * Test setup/teardown is correct
* **If validation fails:**
  - ✋ STOP immediately
  - Report: "Test validation failed: [specific error]"
  - User can: Roll back, or fix tests manually

**Checkpoint Failure Protocol:**

| Situation | Action |
|-----------|--------|
| Checkpoint N validation fails | STOP. Report failure with details. Ask user: "Roll back all changes, or fix manually?" |
| User chooses rollback | Git revert applied changes, or delete newly created files |
| User chooses manual fix | Wait for user to fix, then can continue if desired |
| Multiple checkpoints fail | Report cumulative errors, user decides on recovery strategy |

---

### **Phase 6: Static Health Report (Post-Execution Sanity)**

After all code changes are applied:

1. Perform static checks (conceptual, not running actual commands):

   * **TypeScript sanity on changed files:**
     * Validate imports and exports
   * **Prisma sanity:**
     * Ensure referenced models/fields exist in schema
   * **Routing sanity:**
     * Ensure new API routes follow patterns
   * **UI sanity:**
     * Ensure components referenced actually exist

2. Generate a **Static Health Report** summarizing:

* **Imports:** ✓ All imports in changed files resolve to real files/symbols
* **Types:** ✓ No obviously incorrect type usage in changed areas
* **Prisma:** ✓ All referenced models/fields exist in `prisma/schema.prisma`
* **APIs:** ✓ All edited endpoints compile structurally and match prompt intent
* **UI:** ✓ All edited components compile structurally and match prompt intent
* **Tests:** ✓ Tests reference valid modules and types
* **Warnings (if any)**

---

### **Phase 7: Execution Summary for User**

Finally, present a concise, structured execution summary **including quality metrics**:

#### **7.1 Execution Quality Scorecard (Top of Summary)**

```
═══════════════════════════════════════════════════════════════════════════════
✅ EXECUTION COMPLETE: [Spec Name]
═══════════════════════════════════════════════════════════════════════════════

**Execution Quality Score:** [X.X]/10
- Completeness: [0-100%] (spec coverage: which items implemented vs. deferred)
- Safety: [Low/Medium/High] (validation checks passed, no hallucinations)
- Test Coverage: [0-100%] (percentage of new code covered by tests)
- Integrity Checks: All passed ✓ | [Count] warnings ⚠️ | [Count] errors ❌

**Execution Summary:**
- Checkpoints Applied: 5/5 successful (all phases completed)
- Files Created: N | Files Modified: M | Files Unchanged: X
- Total Changes: +NN lines | -MM lines
- Estimated Lines of Code: NNN LOC
- Time to Review: [Brief estimate of review complexity]

**Quality Flags:**
- ✅ [Strength 1]: [e.g., "Full spec implemented without gaps"]
- ✅ [Strength 2]: [e.g., "All imports validated, zero hallucinations"]
- ✅ [Strength 3]: [e.g., "New code 92% covered by tests"]
- ⚠️  [Caution 1 if any]: [e.g., "One integration point requires manual testing"]
```

**How Score is Calculated:**
- **Completeness:** Did execution implement all items in approved spec? (100% = all done, <100% = some deferred)
- **Safety:** Did all validation checks pass? Were any halt conditions triggered? (High = all passed)
- **Test Coverage:** What % of new code has test coverage? (90%+ = excellent, 70-89% = good, <70% = flag)
- **Integrity:** How many CRITICAL checks passed? How many warnings? Any errors?

#### **7.2 Files Touched (By Category)**

* **Schema/Types**
  * `prisma/schema.prisma` – added `workflowConfig` field to `MelissaConfig`
* **Core Logic**
  * `lib/melissa/agent.ts` – reads workflow config and respects phase definitions
  * `lib/melissa/workflow.ts` – new helpers to load/validate workflow
* **API**
  * `app/api/admin/melissa/workflow/route.ts` – new CRUD for workflow config
* **UI**
  * `components/settings/MelissaWorkflowTab.tsx` – wired to new API endpoints
* **Tests**
  * `tests/api/melissa-workflow.test.ts` – API smoke tests
  * `tests/lib/melissa/agent-workflow.test.ts` – routing behavior tests

#### **7.3 Behavior Implemented (Bullet-Level)**

* Melissa now:
  * Reads workflow config from DB
  * Uses workflow definitions to control phase routing
  * Prevents invalid workflows via validation
* Settings UI:
  * Allows viewing and editing workflow definitions
  * Saves to `/api/admin/melissa/workflow`

#### **7.2 Out-of-Scope Items (Not Implemented)**

Items mentioned in the original spec but **not** implemented in this execution (with reasons):

* [Item name]: [Reason] — *e.g., "Requires database migration; recommend running separately"*
* [Item name]: [Reason] — *e.g., "Depends on Phase X work; will be in follow-up execution"*
* [Item name]: [Reason] — *e.g., "Blocked by incomplete dependency; escalate if critical"*

**Action Items:**
- Defer these to follow-up executions, or
- If blocking, resubmit via `/prompt-review` with priority context
- Track in backlog or project board for visibility

#### **7.4 Static Health Summary**

* ✓ All changed imports resolve
* ✓ All referenced Prisma models/fields exist
* ✓ API route structure is valid for Next.js App Router
* ✓ Newly added tests reference valid code
* ⚠ 1 warning: [any non-blocking issue]

#### **7.5 TODOs / Manual Steps**

* Run migrations (if schema changed):
  * `npx prisma migrate dev --name add_workflow_config`
* Optional: add more E2E tests around workshop flows (Phase X)

---

## **Safety Constraints (Three-Tier System)**

### **Hard Limits (Always Enforced - No Exceptions)**

- **Dry-Run First:** Generate and present full diff preview before ANY code changes applied
- **No Hallucinated Symbols:** Never reference imports, types, models, or paths that don't exist in codebase
  - Validate all symbols exist in Phase 3 (Pre-Execution Validation & Dependency Check)
  - If symbol missing, HALT and ask user for clarification
- **Checkpointed Execution:** Apply changes in ordered phases (schema → core logic → APIs → UI → tests)
  - Validate at each checkpoint before proceeding to next phase
  - Stop if validation fails; report error instead of proceeding blindly
- **Max File Edit Limit:** Default 12 files per run
  - If execution plan touches more files, explicitly ask user for confirmation
  - Present full file list for review before proceeding

### **Soft Limits (Require User Confirmation)**

- **Large File Modifications:** If modifying a file >1000 lines AND changes >50 lines:
  - Summarize impact on existing code
  - Highlight any breaking changes or side effects
  - Ask user to confirm before applying
- **API Contract Changes:** If modifying existing endpoint signatures or request/response shapes:
  - Explicitly list all breaking changes
  - Show impact on existing callers/tests
  - Require user acknowledgment
- **Database Schema Changes:** If schema modifications require data migration:
  - List migration commands needed
  - Warn about production implications
  - Recommend running separately if complex
- **Test Coverage Gaps:** If new code isn't covered by tests:
  - Flag coverage percentage drop
  - List what tests would be needed
  - Ask user to confirm technical debt or add tests

### **Halt Conditions (Stop and Ask User)**

- **Symbol Resolution Failure:** Any planned import/model/field doesn't exist and isn't clearly marked for creation
- **File Count Exceeded:** Dry-run shows file count exceeds 12 file limit
- **Scope Creep Detected:** Change set affects unrelated domains beyond spec scope
- **Spec Ambiguity:** Discovered contradictions in spec that code inspection can't resolve
- **Dependency Conflicts:** Circular imports, conflicting type definitions, or unresolvable dependency ordering
- **Breaking Changes (Unexpected):** Code changes break existing public APIs not mentioned in spec

---

## **Execution Integrity Checks (Pre-Apply Validation)**

Before applying **ANY** code changes in Phase 5, Sonnet must complete these checks. Use this as a pre-flight checklist:

### **Import Resolution (CRITICAL)**
- [ ] All `import` statements in modified files reference real files that exist in the codebase
- [ ] All named imports match exported symbols (function names, class names, types, enums, constants)
- [ ] No circular dependencies introduced by new imports
- [ ] Type imports use `import type { ... }` where appropriate
- **Failure Action:** HALT execution, report specific import errors with line numbers

### **Type Safety (CRITICAL)**
- [ ] No obvious type mismatches in changed code (e.g., string assigned to number field)
- [ ] New interfaces/types don't conflict with existing definitions in same file or scope
- [ ] Generic types have all required type parameters specified
- [ ] All `@ts-expect-error` comments have justification comments explaining why
- [ ] Function return types match actual returns
- **Failure Action:** HALT execution, report type conflicts, ask for clarification

### **Prisma Schema (CRITICAL)**
- [ ] All model names referenced in code exist in `prisma/schema.prisma`
- [ ] All field names are spelled correctly and exist in their models
- [ ] Relations are properly defined (both sides of relation exist)
- [ ] Field types match usage in code (e.g., not using String where Int expected)
- [ ] No duplicate field names in models
- **Failure Action:** HALT execution, report schema mismatches

### **Routing Integrity (HIGH)**
- [ ] New routes don't conflict with existing paths (no duplicate routes)
- [ ] HTTP methods are correct (GET/POST/PUT/DELETE/PATCH)
- [ ] Route parameters and query params are documented and consistent
- [ ] Middleware/auth requirements are documented in comments if unusual
- [ ] Request/response types are consistent with route signature
- **Failure Action:** FLAG as warning, highlight conflicts, ask if should proceed

### **Component Wiring (HIGH)**
- [ ] All component props passed exist in their interface definitions
- [ ] State management (Zustand) stores reference real functions/values
- [ ] Event handlers are wired to actual functions (not just string references)
- [ ] Props don't have type mismatches (e.g., passing string to number prop)
- [ ] Component imports resolve to real component files
- [ ] Hooks called follow React conventions (only at top level, not conditionally)
- **Failure Action:** FLAG as warning, show component/prop mismatches

### **Database Consistency (HIGH)**
- [ ] Fields added to models have appropriate types and defaults
- [ ] Relations reference existing models on both sides
- [ ] Migration path is documented if schema changes (e.g., old field removed, new field added)
- [ ] No orphaned fields (fields referenced in code but deleted from schema)
- **Failure Action:** FLAG as warning if migration is complex, proceed if simple

### **Failure Handling**

**If ANY CRITICAL check fails:**
- ✋ **STOP execution immediately**
- Report exact errors with file paths and line numbers
- Ask user for clarification or spec refinement
- Do NOT proceed to apply changes

**If ANY HIGH check fails:**
- ⚠️ **Flag as warning**
- Show conflicts and impact
- Ask user: "Should I proceed despite this warning?"
- Proceed only with explicit user confirmation

---

## **Implementation Details for Sonnet**

### **Batch Execution Architecture**

**Message 1 - Phase 1.5 Batch Scans (Parallel Execution):**
```
Sonnet calls Bash tool ONE TIME with grouped commands:
  - Batch 1 commands (API routes)
  - Batch 2 commands (schema)
  - Batch 3 commands (UI)
  - Batch 4 commands (Melissa)
  - Batch 5 commands (Testing)
  - Batch 6 commands (Config)

Result: All 6 batches execute in parallel within single Bash invocation
Cache Results: Store as SCAN_CACHE dictionary in memory
```

**Message 2 - Phase 2 Haiku Agent Batch (Parallel Planning):**
```
Sonnet sends ONE message with FIVE Task tool invocations:
  - Task 1: Haiku-1 with prompt + SCAN_CACHE["api_routes"]
  - Task 2: Haiku-2 with prompt + SCAN_CACHE["schema"]
  - Task 3: Haiku-3 with prompt + SCAN_CACHE["components"]
  - Task 4: Haiku-4 with prompt + SCAN_CACHE["melissa"]
  - Task 5: Haiku-5 with prompt + SCAN_CACHE["testing"] + SCAN_CACHE["config"]

Result: All 5 agents build plans in parallel
Wait for: All 5 Task results to return
```

**Message 3+ - Phases 3-7 (Sonnet Orchestration):**
```
Sonnet processes all execution plans:
  - Merge findings from Haiku-1 through Haiku-5
  - Build comprehensive Execution Plan
  - Dry-run all proposed changes
  - Get user confirmation
  - Apply changes in checkpointed phases (schema → logic → API → UI → tests)
  - Generate static health report
  - Present execution summary
```

---

## **Absolute Rules**

1. **Never expand scope** beyond the approved prompt/spec
2. **Never invent** endpoints/models/fields that aren't specified
3. **Never refactor** unrelated code unless required for correctness
4. **Never silently change** public contracts; mention explicitly if required
5. **Always respect:**
   - Dry-run preview requirement
   - Max file edit limit (12 files)
   - Checkpointed execution phases
   - Static health checks

### **Batch Execution Rules**

6. **Phase 1.5:** Launch Batches 1-6 in SINGLE Bash call (not sequential)
7. **Phase 2:** Launch all 5 Haiku agents in SINGLE message with 5 Task invocations
8. **SCAN_CACHE:** Cache all Phase 1.5 results in memory for reuse (zero redundancy)
9. **Each agent receives only its domain:** Pass relevant batch slice to each Haiku agent
10. **No agent re-queries:** If data exists in SCAN_CACHE, use it directly (never ask agent to re-run scans)

---

## **When to Use /prompt-execute vs /prompt-review**

Use this matrix to decide which command is right for your task:

| Situation | Use This | Reason |
|-----------|----------|--------|
| "Is this spec correct or complete?" | `/prompt-review` | Validation & discovery phase |
| "I found issues, need to refine the spec" | `/prompt-review` | Refinement & re-validation |
| "Should we do X or Y?" (architectural choice) | `/prompt-review` | Design decisions belong in validation |
| "I've approved the spec from /prompt-review" | `/prompt-execute` | Ready to apply approved spec |
| "Please implement the validated spec now" | `/prompt-execute` | Execution phase started |
| "I found bugs after /prompt-execute" | `/prompt-review` (again) | Re-validate before re-executing |
| "The spec seems incomplete during execution" | STOP and `/prompt-review` | Halt execution, revalidate first |
| "Make this small change to already-approved spec" | `/prompt-review` first | Update spec, then `/prompt-execute` |

---

## **Pre-Execution Checklist (User)**

Before running `/prompt-execute`, verify:

- [ ] **Spec Validation:** Spec was validated by `/prompt-review` (you ran it and reviewed findings)
- [ ] **Recommendations Applied:** All recommendations from `/prompt-review` were reviewed and incorporated
- [ ] **Code Stability:** No new code changes since `/prompt-review` was run (would invalidate the scan)
- [ ] **Environment Ready:** Dependencies installed, database migrations done, builds passing
- [ ] **Review Time:** You have time to review the dry-run output (don't rush)
- [ ] **Recovery Ready:** You're prepared to handle any failures and re-run if needed
- [ ] **Spec Clarity:** Spec is clear and unambiguous (no lingering questions)

**If ANY item is unclear or incomplete:** Stop and go back to `/prompt-review` first to validate.

**Checklist Failure = Stop:**
- Don't run `/prompt-execute` with a stale or unvalidated spec
- Don't run `/prompt-execute` if you have lingering questions
- Return to `/prompt-review` first to resolve ambiguities

---

## **Final Confirmation**

**After Phase 2 agents complete**, present comprehensive execution plan:

**1. Show High-Level Execution Overview:**
   - Phase 1.5 completion status
   - Phase 2 agent findings summary
   - Merged Execution Plan structure
   - Key tasks by domain

**2. Show Key Files That Will Be Touched:**
   - Schema changes (files + model names)
   - Core logic changes (files + function names)
   - API changes (endpoints + methods)
   - UI changes (components + props)
   - Test additions (files + coverage)

**3. Show Dry-Run Diff Summary:**
   - File count (against max 12 file limit)
   - Line count changes (added/removed/modified)
   - High-level changes for each file

**4. Ask for Confirmation:**

> I've built an execution plan using the batch-based multi-agent system:
>
> **Phase 1.5:** 6 parallel batch scans completed
> **Phase 2:** 5 parallel Haiku agents built detailed plans
>
> **Merged Execution Plan:**
> * [key tasks]
> * [files to be modified/created]
>
> **Max file edit limit:** 12 files (this change set touches N files).
>
> **Proposed execution flow:**
> * Phase 3: Validate all imports, types, paths against codebase
> * Phase 4: Generate and review dry-run diffs
> * Phase 5: Apply changes in checkpointed phases (schema → logic → API → UI → tests)
> * Phase 6: Generate static health report
> * Phase 7: Present final execution summary
>
> **Do you confirm I should proceed with this execution plan?**

**Only after explicit YES** should Sonnet proceed to Phase 3 (validation).

---

## **Git/GitHub Commit Strategy**

### **When to Commit During Execution**

Commits should be made at strategic points to preserve work, create audit trail, and enable recovery:

#### **Automatic Commit Triggers**

**Trigger 1: Phase Completion (RECOMMENDED)**
- Commit after each Phase 5 checkpoint completion (schema → logic → API → UI → tests)
- Commit message format: `feat(/prompt-execute): [Phase N] [brief description]`
- Example: `feat(/prompt-execute): Phase 5.1 - Schema changes for workflow config`
- **Rationale:** Each phase is a logical, reversible unit of work

**Trigger 2: Lines of Code Threshold**
- Commit if cumulative changes exceed **75 lines of code** (before Phase 5 completion)
- Commit message: `feat(/prompt-execute): [Stage] - [N lines] [description]`
- Example: `feat(/prompt-execute): Core logic - 102 lines added for workflow routing`
- **Threshold:** 75+ lines = significant change worth checkpointing

**Trigger 3: Files Modified Threshold**
- Commit if files modified exceeds **6 files** (half of 12-file limit)
- Commit message: `feat(/prompt-execute): [Domain] - Modified [N] files for [feature]`
- Example: `feat(/prompt-execute): Workflow - Modified 8 files for workflow config`
- **Rationale:** High file count = higher risk, commit to preserve state

#### **Commit Checklist (After Each Trigger)**

Before committing, verify:

- [ ] **All changes applied:** Current phase/section is complete
- [ ] **Tests pass (if applicable):** New code doesn't break existing tests
- [ ] **No work-in-progress code:** No `TODO` comments, no `console.log()` debug statements (except where explicitly needed)
- [ ] **Imports clean:** No unused imports in changed files
- [ ] **Types valid:** No obvious type errors in changed files
- [ ] **Diff is clear:** `git diff HEAD` shows exactly what changed (no accidental files)

**If checklist fails:** Don't commit yet. Fix issues first, then commit.

#### **Commit Message Format**

All commits use conventional commit syntax:

```
feat(/prompt-execute): [Scope] - [Description]

[Optional detailed description if helpful]

Spec: [Spec filename or reference]
Phase: [Which execution phase/checkpoint]
Files: [N] changed
Lines: [+X-Y] lines added/removed
```

Example:

```
feat(/prompt-execute): Schema & Types - Workflow config model

Added workflowId field to MelissaConfig model in Prisma schema.
Added TypeScript types for workflow configuration.

Spec: workflow-system.md
Phase: 5.1 (Schema & Types Checkpoint)
Files: 2 changed
Lines: +18-2 lines
```

#### **Recovery Strategy**

If execution fails after a commit:

1. **Identify which commit introduced the issue:** `git log --oneline -10`
2. **Review the problematic commit:** `git show [commit-hash]`
3. **Decide on recovery:**
   - **Revert commit:** `git revert [commit-hash]` (preferred - creates new revert commit)
   - **Hard reset:** `git reset --hard [commit-hash]` (only if commit is not yet pushed)
   - **Manual fix:** Fix issues in code, then create new commit with fixes

4. **After recovery, resubmit via `/prompt-review`** with updated spec if needed

### **Git Commit Integration with /prompt-execute Workflow**

| Phase | Commit Point | Frequency |
|-------|--------------|-----------|
| Phase 5.1 (Schema) | After checkpoint validation | 1 commit |
| Phase 5.2 (Core Logic) | After checkpoint validation | 1 commit |
| Phase 5.3 (API Routes) | After checkpoint validation | 1 commit |
| Phase 5.4 (UI Components) | After checkpoint validation | 1 commit |
| Phase 5.5 (Tests) | After checkpoint validation | 1 commit |
| **Between Phases** | If ≥75 lines or ≥6 files | 0-N commits (as needed) |

**Typical execution:** 5-10 commits per `/prompt-execute` run (one per checkpoint + line/file thresholds)

### **GitHub Integration (Optional)**

If using GitHub with CI/CD:

- **Pre-push checks:** Ensure all commits pass local tests before pushing
- **Branch strategy:** Create feature branch for execution if using PRs
- **Pull request:** After execution completes, create PR with execution summary
- **Merge strategy:** Use squash-merge if you prefer single commit per execution, or keep individual commits for granular history

---
