---
description: Multi-agent parallel validation and update of technical documents against codebase reality
---

# Prompt Review - Multi-Agent Document Validation & Update

> **This document is intended to be run as a Claude Code prompt command** (`/prompt-review`). It specifies how to validate and update technical specifications, PRDs, and execution plans against the actual codebase. Use this when a document's accuracy needs verification and refinement before execution via `/prompt-execute`.

You are **Claude Code (Sonnet)**, orchestrating parallel **Haiku agents** to validate and update technical documents against actual codebase implementation.

---

## **Guiding Principles (User-Defined)**

**Quality Over Speed:** Accuracy and quality trump fast execution.

**Validation Scope:** Validate ALL aspects:
- File paths, line numbers, code references
- Implementation state vs. documented claims
- Technical recommendations vs. current best practices
- Discover files not listed but relevant to the prompt's intent

**Update Strategy:** Apply ALL improvements:
- Update line numbers and file paths to current codebase
- Add missing prerequisites (env vars, dependencies, types)
- Mark outdated claims with corrections
- Add new sections for discovered relevant code

**Convergence Thresholds:**
- **10% changed:** Auto-fix and re-validate (mandatory)
- **20%+ changed:** Rewrite inaccurate sections, then restart validation loop
- **Max 3 iterations** to reach <10% delta

**Prerequisite Depth:** Validate inferred prerequisites (env vars, types, dependencies)
- **Timeout:** 2 minutes for prerequisite discovery (avoid infinite rabbit holes)
- Many issues surface during build stage; bias toward action over exhaustive up-front checks

**Time Estimates Policy:**
- **CRITICAL:** Never provide time estimates (hours, minutes, days, etc.)
- Work is labeled in **phases and checkpoints**, not duration
- Phase documents are for **structural clarity**, not speed prediction
- Example: "Phase 5: Apply changes (5 checkpoints)" not "Phase 5: ~3-5 minutes"

**Prompt Refinement Goal:**
- Rewrite prompts for Claude Code execution clarity
- Add context discovered from codebase research
- Optimize for faster re-execution after initial validation

**Skip Clarifying Questions Policy:**
- Skip clarifying questions if scope is clear from context
- Only ask 3-5 questions if truly ambiguous (rare case)

**Workflow Integration (with `/prompt-execute`):**
- `/prompt-review` output flows directly to `/prompt-execute` as input
- Output includes: validated spec, current file paths, prerequisites, and optional parallel execution guidance
- User decision point: "Ready to execute?" triggers `/prompt-execute` with validated spec path

---

## **Complete Execution Model - All 8 Phases**

### **Phase 1: File Location**

1. If user provides file path, verify it exists
2. If no path provided, search `_build/` directory first by document name/pattern
3. Use Glob tool to find candidates, present matches to user

---

### **Phase 1.5: Batch Background Scans (Parallel Execution)**

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

**Batch 5: Utilities, Helpers & Config** (Supports Haiku-5)
```bash
find lib -type f | sort
grep -RIn "export function\|export const" lib/
grep -RIn "process.env\|Config\|^import" lib/
```

**Batch 6: Environment & LLM** (Supports Haiku-6 Prerequisites)
```bash
grep -RIn "process.env" . --include="*.ts" --include="*.tsx" --include="*.js"
grep -RIn "claude\|gpt\|model\|temperature" . --include="*.ts" --include="*.tsx" --include="*.js" | head -50
find . -name ".env*" -o -name "*.env.example"
```

**Batch 7: Reference Verification** (Document-Specific, runs after scans 1-6 complete)
```bash
# For each reference extracted from the document:
grep -RIn "<REFERENCE_TEXT>" .
```

#### **Execution Strategy**

**Sonnet's responsibility in this phase:**

1. **Prepare all 7 batch scan commands** (no execution yet)

2. **Launch Batches 1-6 as parallel background processes:**
   - Use Bash tool with all independent scans in a single message (parallel execution)
   - Cache all results in memory for reuse

3. **After scans 1-6 complete, extract document references and run Batch 7:**
   - Grep for specific code symbols mentioned in the target document
   - Batch 7 runs in parallel with Sonnet's initial analysis

4. **Consolidate all scan results into a structured cache:**
   ```
   SCAN_CACHE = {
     "api_routes": [results from Batch 1],
     "schema": [results from Batch 2],
     "components": [results from Batch 3],
     "melissa": [results from Batch 4],
     "utilities": [results from Batch 5],
     "environment": [results from Batch 6],
     "references": [results from Batch 7]
   }
   ```

5. **Pass structured cache to each Haiku agent with exact batch results:**
   - Each Haiku agent receives only its relevant batch slice
   - No agent re-runs the same scan
   - Eliminates redundant queries across 5+ agents

---

### **Phase 2: Pre-Check (SKIP IF SCOPE IS CLEAR)**

- Read the target file completely
- Verify file is readable
- Skip clarifying questions if scope is clear from context
- Only ask 3-5 questions if truly ambiguous (rare case)

---

### **Phase 3: Multi-Agent Parallel Validation (Using Cached Scan Results)**

**Sonnet now spawns 5 parallel Haiku agents IN A SINGLE MESSAGE**, passing each agent its pre-computed batch scan results from Phase 1.5. No redundant queries. No sequential processing.

Use Task tool with `model="haiku"` to launch all 5 agents in parallel with this structure:

```
Sonnet sends ONE message with 5 Task tool invocations:
├─ Task 1: Haiku-1 (API Routes) + SCAN_CACHE["api_routes"]
├─ Task 2: Haiku-2 (Database Schema) + SCAN_CACHE["schema"]
├─ Task 3: Haiku-3 (UI Components) + SCAN_CACHE["components"]
├─ Task 4: Haiku-4 (Melissa Runtime) + SCAN_CACHE["melissa"]
└─ Task 5: Haiku-5 (Utilities) + SCAN_CACHE["utilities"]
```

All 5 agents execute in parallel, each analyzing their specific domain against the document.

---

**Haiku-1: API Routes Validation**
- **Input:** SCAN_CACHE["api_routes"] (Batch 1 results)
- **Task:** Cross-reference document claims against actual API endpoints
  - Verify all API endpoints in `app/api/` (documented AND undocumented)
  - Check HTTP methods, request/response shapes, line numbers
  - Validate route handlers match documented behavior
- **Discover:**
  - API routes mentioned in prompt but not in codebase (gaps)
  - API routes in codebase but not mentioned (missing docs)

**Haiku-2: Database Schema Validation**
- **Input:** SCAN_CACHE["schema"] (Batch 2 results)
- **Task:** Validate schema against document claims
  - Check `prisma/schema.prisma` (all models, fields, relationships)
  - Verify model names, field names, types, relationships, line numbers
  - Confirm indexes, constraints, defaults match documentation
- **Discover:**
  - Schema fields mentioned but don't exist (inaccuracies)
  - Schema fields exist but not documented (missing coverage)

**Haiku-3: UI Components Validation**
- **Input:** SCAN_CACHE["components"] (Batch 3 results)
- **Task:** Validate component references against actual implementations
  - Search `components/` and `app/` directories (all references)
  - Verify component names, props, import paths, line numbers
  - Check component composition and patterns match claims
- **Discover:**
  - Components mentioned but not found (dead references)
  - Relevant components not mentioned (incomplete docs)

**Haiku-4: Melissa Runtime & Agent Logic**
- **Input:** SCAN_CACHE["melissa"] (Batch 4 results)
- **Task:** Validate Melissa implementation against document specifications
  - Check `lib/melissa/` implementations (all files)
  - Verify agent configurations, tool integrations, function signatures
  - Validate LLM profiles, personality configs, line numbers
- **Discover:**
  - Claimed implementations that don't exist (inaccuracies)
  - Existing implementations not documented (gaps)

**Haiku-5: Utilities & Helpers**
- **Input:** SCAN_CACHE["utilities"] (Batch 5 results)
- **Task:** Validate utility functions against document claims
  - Check `lib/` utilities referenced in document (all helpers)
  - Verify function signatures, exports, types, line numbers
  - Validate config files, constants, helpers match documentation
- **Discover:**
  - Utilities claimed but missing (errors)
  - Relevant utilities not mentioned (incomplete coverage)

### **Phase 4: Prerequisite Identification (Sequential After Phase 3, 2-Minute Timeout)**

After all 5 Haiku agents complete (Phase 3), spawn **Haiku-6: Prerequisites Hunter** in a separate Task invocation:

**Execution order:**
```
Phase 1.5: Run Batches 1-6 in parallel
      ↓
Phase 3: Run 5 Haiku agents in parallel (using cached results)
      ↓
Phase 4: Run Haiku-6 (after Phase 3 complete)
      ↓
Phase 4.5: Scope Trimming (Sonnet analyzes Phase 3 findings)
      ↓
Phase 5-8: Synthesis, apply fixes, present summary
```

**Haiku-6: Prerequisites Hunter**
- **Input:** SCAN_CACHE["environment"] (Batch 6 results) + Findings from Phase 3 (5 Haiku agents)
- **Timeout:** 2 minutes max (bias toward action over exhaustive checking)
- **Task:** Validate prerequisites mentioned or implied by the document and Phase 3 findings
  - Verify all env vars exist and are documented
  - Check all dependencies in package.json match version requirements
  - Validate types, interfaces, and model definitions
  - Confirm installation steps and config requirements
  - Report missing or outdated prerequisites
- **Note:** Some issues will surface during build stage; prioritize actionable items

### **Phase 4.5: Scope Trimming (CRITICAL NEW PHASE)**

**Purpose:** Identify what's already implemented and trim scope to reduce context for `/prompt-execute`.

**Workflow:**

1. **Identify Completed Items:**
   - Parse all Phase 3 validation findings from Haiku agents
   - Mark items where code EXISTS and MATCHES the documented requirements
   - Calculate completion percentage for each major scope area

2. **Scope Trimming Decision:**
   - **If <20% of scope is complete:** Keep full scope (trimming gains too small)
   - **If 20-80% of scope is complete:** TRIM completed items that don't compromise objective
   - **If >80% of scope is complete:** Consider marking as "enhancement" not "implementation"

3. **Trim Without Losing Objective:**
   - ✅ Remove: "Create component X" if component X exists + works as documented
   - ✅ Remove: "Add field Y to schema" if field Y exists with correct type
   - ✅ Remove: "Implement endpoint Z" if endpoint exists with correct signature
   - ❌ Never remove: Critical prerequisites, blockers, or architectural decisions
   - ❌ Never remove: Integration points that glue components together
   - ❌ Never remove: If removing >30% of original scope

4. **Document Trimming:**
   - Add "**SCOPE TRIMMED**" section showing what was removed
   - Explain WHY each removal is safe (e.g., "Button component exists and implements all required props")
   - List any discovered dependencies that MUST be preserved

5. **Calculate Impact:**
   - Original scope: X tasks
   - Trimmed scope: Y tasks
   - Reduction: Z% (Y/X)
   - If Z% > 40% AND >20% complete: Flag for user confirmation in Phase 8

---

### **Phase 5: Synthesis & Fix Categorization**

Merge all Haiku findings and categorize fixes by severity:

#### **AUTO-FIX (Apply Automatically - No User Approval Needed)**

**Minor Fixes (<5% of document changed):**
- Wrong file paths (verified to exist)
- Outdated line numbers (verified in code)
- Typos in field/function names (verified in code)
- Incorrect endpoint paths (verified routes)
- Outdated type names (verified in schema)
- Missing field references (verified exist)
- Dead code references (verified removed/renamed)
- Size estimates (e.g., "~900 lines" → "~34 lines" when verified)
- Line range corrections (e.g., "95-100" → "95-101" when verified)

**Moderate Fixes (5-10% of document changed):**
- Add missing prerequisites section (env vars, dependencies discovered)
- Add small clarifications for ambiguous statements
- Add code examples for undocumented features (if <20 lines per example)
- Update outdated implementation status (e.g., "TODO" → "Implemented" when verified)
- Add discovered relevant files to reference lists

#### **RECOMMENDATIONS (Require User Decision - ASK BEFORE APPLYING)**

**Significant Changes (>10% of document OR changes scope/intent):**
- Structural reorganization (new sections >20% of total)
- Additions requiring domain knowledge or strategy decisions
- Large section deletions (>10% of document)
- Additions of new features/capabilities to testing infrastructure
- Changes to critical path or blocker dependencies
- Scope changes beyond document intent
- Ambiguous fixes with multiple valid interpretations
- Claims of "implemented" when code doesn't exist (needs verification)
- Strategic decisions (e.g., "which approach should we use?")
- Breaking changes to documented APIs or contracts

---

### **Phase 6: Apply Fixes & Scope Trimming**

**Workflow:**

1. **Apply scope trimming** (from Phase 4.5):
   - Use Edit tool to create **SCOPE TRIMMED** section
   - Remove completed tasks from main task list
   - Update task counts and introduce "Remaining Work" breakdown
   - Preserve all prerequisites and architectural decisions

2. **Categorize all fixes** by severity
   - Account for trimmed items in fix categorization
   - Focus fixes on remaining scope

3. **Apply Minor + Moderate fixes automatically** (no permission needed):
   - Use Edit tool to update document in-place
   - Apply deterministic corrections (line numbers, file paths, typos)
   - Add missing prerequisites sections
   - Add small clarifications and code examples

4. **Calculate impact after auto-fixes:**
   - (Lines changed from fixes + lines removed from trimming) / total original lines = X%
   - If X% < 10%: Proceed to Phase 7
   - If X% >= 10% but < 20%: Re-validate with Haiku agents (1 iteration)
   - If X% >= 20%: Flag as "significant rewrite needed"

**Convergence Check (after auto-fixes):**
- **<10% changed:** Proceed to Phase 7
- **10-20% changed:** Re-validate once with Haiku agents, apply second round of fixes
- **20%+ changed:** Present findings, ask user if they want full rewrite or targeted fixes
- **Max 3 iterations** to reach <10% delta
- If 3 iterations reached without convergence, flag for manual review

**Context Reduction Benefit:**
- Trimmed scope reduces context tokens passed to `/prompt-execute`
- Smaller prompts execute faster with same quality
- Clearer focus for agent execution (no wasted work on completed tasks)

---

### **Phase 7: Final Validation Checklist**

Before presenting results, verify quality:

- [ ] Document accurately represents codebase state (0 major inaccuracies)
- [ ] All file paths exist or are correctly specified for creation
- [ ] All line numbers are current (verified within ±5 lines)
- [ ] All prerequisites identified (npm packages, env vars, types)
- [ ] Dependencies clearly documented (sequential vs parallel)
- [ ] NO time estimates present (absolute requirement - validation blocker)
- [ ] All critical blockers identified with clear impact statements
- [ ] Success criteria measurable and achievable
- [ ] Architecture decisions documented
- [ ] All auto-fixes were deterministic and verified (no guessing)
- [ ] No hallucinated content added
- [ ] Minor + Moderate fixes applied automatically (no permission needed)
- [ ] Significant changes separated as recommendations (awaiting user decision)
- [ ] Prerequisites identified and verified
- [ ] Document structure preserved (unless 20%+ inaccurate)
- [ ] Convergence criteria met or max iterations reached
- [ ] Impact percentage calculated and reported

---

### **Phase 8: Present Summary to User**

**Output Format (User-Optimized for Decision-Making):**

```
═══════════════════════════════════════════════════════════════════════════════
📊 VALIDATION COMPLETE: [Document Name]
═══════════════════════════════════════════════════════════════════════════════

[EXECUTIVE SUMMARY SECTION]
- Document: [path] ([total] lines)
- Original Scope: X tasks
- Trimmed Scope: Y tasks (Z% reduction)
- Quality Score: A/10
- Convergence: <10% changes (ready for execution)
- Auto-fixes Applied: [count]
- Strategic Decisions Needed: [count]

[SCOPE TRIMMING SUBSECTION]
Items Already Implemented (Removed from Scope):
  - [Task/Feature]: Why safe to remove (e.g., "exists in codebase, implements all required props")
  - [Task/Feature]: [reason]

Context Reduction: ~[N] tokens saved by trimming completed work

[AUTO-FIXES APPLIED SUBSECTION]
Files Modified: [list with line counts]
  - File1.md: +12 lines, -3 lines
  - File2.md: +8 lines (includes scope trimming)

Changes Made:
  - Category 1: [description]
  - Category 2: [description]

Total Impact: X% (Y lines changed / Z total)

[VALIDATION FINDINGS BY CATEGORY SECTION]
(Comprehensive findings organized by category: API Routes, Schema, Components, etc.)

[EXECUTION READINESS CHECKLIST SUBSECTION]
✅ EXECUTION READINESS CHECKLIST (Example 1: All Pass)
- All prerequisites identified
- No blockers found
- Document is >95% accurate

OR

⚠️ EXECUTION READINESS CHECKLIST (Example 2: With Concerns)
- Document structure validated
- ⚠️ 5 npm packages must be installed before execution
- ⚠️ Build verification required after changes

═══════════════════════════════════════════════════════════════════════════════
🎯 STRATEGIC RECOMMENDATIONS (USER DECISION REQUIRED)
═══════════════════════════════════════════════════════════════════════════════
[Auto-populated from any ⚠️ items found in validation sections]

1️⃣ [Issue Title]
   Context: [problem description and impact]

   Options:

   a. ⭐️ [Recommended Option] (selected as best approach)
      - [reason 1]
      - [reason 2]
      - Impact: [specific outcome]

   b. [Alternative Option]
      - [reason 1]
      - [reason 2]
      - Impact: [specific outcome]

   c. [Alternative Option]
      - [reason 1]
      - Impact: [specific outcome]

2️⃣ [Issue Title]
   Context: [problem description]

   Options:

   a. ⭐️ [Recommended Option]
      - [reason]
      - Impact: [outcome]

   b. [Alternative]
      - [reason]
      - Impact: [outcome]

═══════════════════════════════════════════════════════════════════════════════

Ready to proceed?

✓ Reply "yes" to accept all recommendations
✓ Reply with decision codes to modify (e.g., "1a, 2b" or "2a with context: add XYZ")
✓ Reply with new context to add (e.g., "2a plus: also consider user authentication")
```

**Auto-fixes have already been applied to the document.** Recommendations above require user decision.

---

### **Understanding the Checklist Format with Warning Bubble-Up**

**When All Items Pass:**
```
✅ EXECUTION READINESS CHECKLIST
- All prerequisites identified
- No blockers found
- Document is >95% accurate
```
→ No STRATEGIC RECOMMENDATIONS needed. Ready to execute.

**When Items Have Concerns:**
```
⚠️ EXECUTION READINESS CHECKLIST
- Document structure validated
- ⚠️ 5 npm packages must be installed before execution
- ⚠️ Build verification required after changes
```
→ Each ⚠️ item automatically generates a numbered STRATEGIC RECOMMENDATION below with:
  - **Title:** Descriptive name of the concern (numbered with emoji: 1️⃣, 2️⃣, 3️⃣, etc.)
  - **Context:** Why it matters and impact
  - **Options (a/b/c):** Recommended path marked with ⭐️

**How Warnings Bubble Up:**

| Item with ⚠️ | Becomes in STRATEGIC RECOMMENDATIONS |
|---|---|
| ⚠️ 5 npm packages must be installed | **1️⃣ Install Dependencies Before Execution** with options: (a ⭐️ install upfront, b install as-needed) |
| ⚠️ Build verification required | **2️⃣ Run Build Verification** with options: (a ⭐️ run now before proceeding, b run after each change) |
| ⚠️ Performance targets need validation | **3️⃣ Validate Performance Targets** with options: (a ⭐️ run benchmarks first, b validate during execution) |

**Format Rules:**
- Single **✅** = entire checklist passes (0 concerns)
- **⚠️** prefix = checklist has items needing decisions
- Each **⚠️ item** in checklist → **Numbered decision** in recommendations
- **All decisions required** before proceeding to `/prompt-execute`

---

## **Implementation Details for Sonnet**

### **Batch Execution Architecture (How to Execute Phases in Parallel)**

This section describes the technical implementation for achieving 4-5x speedup through parallelization.

#### **Message 1 - Phase 1.5 Batch Scans (Parallel Execution)**

```
Sonnet calls Bash tool ONE TIME with grouped commands:
  - Batch 1 commands (API routes)
  - Batch 2 commands (schema)
  - Batch 3 commands (UI)
  - Batch 4 commands (Melissa)
  - Batch 5 commands (Utilities)
  - Batch 6 commands (Environment)

Result: All 6 batches execute in parallel within single Bash invocation
Cache Results: Store as SCAN_CACHE dictionary in memory for Haiku reuse
```

#### **Message 2 - Phase 3 Haiku Agent Batch (Parallel Execution)**

```
Sonnet sends ONE message with FIVE Task tool invocations:
  - Task 1: Haiku-1 (API Routes) + SCAN_CACHE["api_routes"]
  - Task 2: Haiku-2 (Database Schema) + SCAN_CACHE["schema"]
  - Task 3: Haiku-3 (UI Components) + SCAN_CACHE["components"]
  - Task 4: Haiku-4 (Melissa Runtime) + SCAN_CACHE["melissa"]
  - Task 5: Haiku-5 (Utilities) + SCAN_CACHE["utilities"]

Result: All 5 agents execute in parallel
Wait for: All 5 Task results to return before Phase 4
No redundancy: Each Haiku agent uses pre-computed SCAN_CACHE, not re-running scans
```

#### **Message 3 - Phase 4 Prerequisites Hunter (Sequential)**

```
After Phase 3 complete, Sonnet sends ONE Task invocation:
  - Task 6: Haiku-6 with SCAN_CACHE["environment"] + Phase 3 findings

Result: Prerequisite validation completes with 2-minute timeout
Wait for: Haiku-6 result before Phase 4.5
```

#### **Message 4 - Phase 4.5 Scope Trimming (Sonnet Processing)**

```
After Phase 4 complete, Sonnet (no agents):
  - Parse Phase 3 findings from all 5 Haiku agents
  - Identify completed items (code exists + matches requirements)
  - Calculate completion % for each domain
  - Decide: Keep scope (if <20% complete) vs trim (if 20-80% complete)
  - Document trimmed items with rationale
  - Calculate context reduction benefit
  - Prepare for Phase 5 synthesis
```

#### **Message 5+ - Phase 5-8 Synthesis (Sonnet Processing)**

```
Sonnet (no agents involved):
  - Merge findings from all 6 Haiku agents + Phase 4.5 trimming
  - Apply auto-fixes (Minor + Moderate categories) to remaining scope
  - Apply scope trimming edits to document
  - Categorize recommendations (Significant changes)
  - Calculate total impact (fixes + trimming)
  - Present summary to user with scope reduction highlighted
```

---

## **Quality Standards Checklist**

Before finalizing updates, validate document quality:

- [ ] Steps are sequential and numbered
- [ ] No ambiguous language
- [ ] Uses exact codebase terminology
- [ ] Includes specific file paths with line numbers (current, not stale)
- [ ] Specifies what to modify AND where
- [ ] Preserves original document structure (unless 20%+ inaccurate)
- [ ] Maintains technical tone
- [ ] All prerequisites identified and validated (2-min timeout)
- [ ] Auto-fixes are deterministic (no guessing)
- [ ] Recommendations separated from auto-fixes
- [ ] **Scope Trimming Applied:** Completed items removed if 20-80% of scope is done
- [ ] **SCOPE TRIMMED Section:** Clearly documents what was removed and why
- [ ] **Context Reduction Calculated:** Estimated token savings from trimmed scope
- [ ] Convergence criteria met (<10% delta) or max iterations reached (3)
- [ ] **Claude Code Execution Ready:** Prompt is clear enough for Claude Code to execute without confusion
- [ ] **Context-Rich:** Added discovered context from codebase research
- [ ] **Optimized:** Faster re-execution after initial validation (no redundant searches)
- [ ] **Leaner Prompt:** Smaller scope passed to `/prompt-execute` reduces execution time
- [ ] **NO TIME ESTIMATES (ABSOLUTE REQUIREMENT - VALIDATION BLOCKER):**
  - ✅ Uses phase labels: "Phase 1: Parse spec"
  - ✅ Uses checkpoint labels: "Checkpoint 5.1: Schema & Types"
  - ✅ Uses scope labels: "Batch 1-6 (parallel scans)"
  - ✅ **MUST NOT contain:** "7 hours", "⏱️", "~3-5 minutes", "approximately 2 hours", "quick win", "~20 hours", "Days 1-5", etc.
  - **FAIL VALIDATION if ANY of these patterns found:**
    - Time durations: "7 hours", "2 hours", "15 minutes", "6-8 days", "Day 1-5"
    - Time symbols: "⏱️" emoji followed by duration
    - Duration estimators: "~", "approximately", "about", "roughly" + time
    - Timeline language: "Days 1-2:", "SPRINT 1:", "Day 1-5"
  - **ACTION:** If found, remove ALL and replace with phase/checkpoint labels ONLY

---

## **Parallel-Executable Work Sections (for `/prompt-execute`)**

When a validated phase document is executed via `/prompt-execute`, certain work can run in parallel agent workflows if it doesn't create dependencies. This section identifies parallel-safe work areas.

### **How to Mark Parallel Work**

In the validated document, add a section clearly labeled:

```markdown
## 📦 PARALLEL EXECUTION GUIDANCE

This section identifies work that can execute simultaneously in `/prompt-execute` workflows.

### **Parallel Group 1: [Domain A] (No Dependencies)**
- Task A.1: [Description]
- Task A.2: [Description]
- Task A.3: [Description]

**Why parallel:** No task depends on outputs from another; all can run in parallel agents.

### **Parallel Group 2: [Domain B] (No Dependencies)**
- Task B.1: [Description]
- Task B.2: [Description]

**Why parallel:** Independent concern; doesn't block other domains.

### **Dependency Sequence (Must Run Sequentially)**
1. **Phase 1:** Complete Parallel Groups 1-2 first
2. **Phase 2:** Task C.1 (depends on Groups 1-2 outputs)
3. **Phase 3:** Task C.2 (depends on C.1)
```

### **Criteria for Parallel-Safe Work**

Work can execute in parallel agents IF:
- ✅ **No File Dependencies:** Task A and Task B don't modify the same file
- ✅ **No Import Dependencies:** Task A doesn't import code created by Task B (or vice versa)
- ✅ **No Type Dependencies:** Task A's types don't depend on Task B's interfaces
- ✅ **No Database Dependencies:** Task A doesn't rely on schema changes from Task B
- ✅ **No API Dependencies:** Task A's routes don't consume Task B's endpoints
- ✅ **Independent Concerns:** Each task operates in separate domains (e.g., one modifies `lib/`, other modifies `components/`)

### **When to NOT Mark Parallel**

Tasks MUST run sequentially IF:
- ❌ Task B needs output from Task A (e.g., A creates type, B uses it)
- ❌ Both tasks modify same file (merge conflicts)
- ❌ Task B imports from new files created by Task A
- ❌ Task B's tests depend on Task A's implementation
- ❌ Shared state/config changes needed in consistent order

### **Example: Phase 4.2 Blockers Parallel Structure**

**BLOCKER 1 (PDF Generation) & BLOCKER 2 (Charts Generation):**

```markdown
## 📦 PARALLEL EXECUTION GUIDANCE

### **Parallel Group 1: PDF Generation System (BLOCKER 1)**
- Task 1.1: Create lib/reports/pdf/generator.ts (280 lines)
- Task 1.2: Update lib/reports/types.ts (add PDF-specific types)
- Task 1.3: Create tests/unit/reports/pdf-generator.test.ts (145 lines)

**Why parallel:** All operate on new files; no cross-dependencies.

### **Parallel Group 2: Chart Generation System (BLOCKER 2)**
- Task 2.1: Create lib/reports/charts.ts (300 lines)
- Task 2.2: Update lib/reports/types.ts (add chart types)
- Task 2.3: Create tests/unit/reports/charts.test.ts (150 lines)

**Why parallel:** Charts independent of PDF; separate concern.
**Note:** Task 1.2 and 2.2 both touch types.ts — sequence these!

### **Dependency Sequence**
1. **Phase 1:** Sequence Task 1.2 → Task 2.2 (types updated in order)
2. **Phase 2:** Parallel: Task 1.1, Task 2.1 (PDF + charts created together)
3. **Phase 3:** Parallel: Task 1.3, Task 2.3 (tests run together)
4. **Phase 4:** Integration — Update main generator.ts to use both (single task)
```

### **How `/prompt-execute` Uses This**

When `/prompt-execute` reads a validated document:

1. **Phase 1:** Parse spec, extract all tasks
2. **Phase 1.5 (New):** If document has **PARALLEL EXECUTION GUIDANCE section**:
   - Read parallel groups
   - Identify sequential order of grouped tasks
   - Plan agent allocation (one agent per group)
3. **Phase 3:** Instead of sequential execution:
   - Spawn parallel agents for independent groups
   - Each agent handles all tasks in its group
   - Agents report completion per task
   - Proceed to next phase once all groups done
4. **Phase 5:** Apply changes in the documented sequence

### **Document Validation Requirement**

When validating a phase document, `/prompt-review` MUST:
- [ ] Identify if parallel work is possible
- [ ] If YES: Add **PARALLEL EXECUTION GUIDANCE** section (auto-fix if missing)
- [ ] If NO: Note in document "Sequential execution only" (recommendation if scope change)
- [ ] Verify parallel groups have no hidden dependencies
- [ ] Verify documented sequence is actually sequential

---

## **Absolute Rules (Internal Document Constraints)**

**Rules 1-9 are internal to this document specification.** They define how Claude Code executes `/prompt-review` validation. They are not user-facing requirements but constraints that ensure validation quality and consistency.

**Rules 10-22** describe batch execution architecture and agent coordination patterns.

1. **Never create new files** (unless user explicitly requests)
2. **Never hallucinate** - only reference verified code
3. **Always use Task tool** with `model="haiku"` for parallel agents
4. **Always run prerequisite validation** (Haiku-6, 2-min timeout)
5. **Always show findings on screen** (comment block format)
6. **Always apply updates in-place** (Edit tool, same file)
7. **Always iterate if >10% changed** (mandatory re-run, max 3 loops)
8. **Always rewrite sections if >20% inaccurate** (then restart validation)
9. **Always run final Sonnet review** before presenting
10. **Skip clarifying questions** if scope is clear (user preference) — When the document scope, intent, and requirements are evident from context, proceed directly to validation without asking 3-5 clarifying questions. Only ask clarifying questions when the scope is genuinely ambiguous (rare).
11. **Auto-apply minor/moderate fixes** (<10% changes, deterministic)
12. **Ask before significant changes** (>10%, scope changes, strategic decisions)
13. **Always discover undocumented code** (gaps in coverage)
14. **Always validate implementation state** (vs. claims in prompt)
15. **Quality over speed** (accuracy trumps fast execution)
16. **Prefer bash-style scans (find/grep) as first step in each domain** before deeper reasoning

### **Batch Execution Rules**

17. **Phase 1.5:** Launch Batches 1-6 in SINGLE Bash call (not sequential)
18. **Phase 3:** Launch all 5 Haiku agents in SINGLE message with 5 Task invocations
19. **Phase 4:** Launch Haiku-6 AFTER Phase 3 complete (sequential dependency)
20. **Phase 4.5:** Run scope trimming AFTER Phase 4 complete (analyzes all findings)
21. **SCAN_CACHE:** Cache all Phase 1.5 results in memory for reuse (zero redundancy)
22. **Each agent receives only its domain:** Pass relevant batch slice to each Haiku agent
23. **No agent re-queries:** If data exists in SCAN_CACHE, use it directly (never ask agent to re-run scans)

### **Scope Trimming Rules**

24. **Trim only if 20-80% complete:** Keep full scope if <20%, flag enhancement if >80%
25. **Never trim critical paths:** Always preserve blockers, prerequisites, integration points
26. **Never trim >30% of scope:** If would remove 30%+, ask user before trimming
27. **Document every removal:** "SCOPE TRIMMED" section explains each item + rationale
28. **Preserve objective:** Ensure trimming doesn't dilute the prompt's core goal
29. **Calculate context savings:** Estimate token reduction from trimmed scope

---

## **Error Handling**

If any Haiku agent fails:
- Report the failure to user
- Continue with remaining agents
- Mark affected validation areas as "incomplete"
- Proceed with caution, flag uncertainty

If file not found:
- Search `_build/` recursively
- Present candidates to user
- Ask for clarification

If convergence not reached after 3 iterations:
- Report to user
- Show iteration history
- Request user decision on whether to continue

---

## **Final Confirmation**

Before beginning the validation:

1. **Review the scope**: Ensure you understand which document(s) need validation
2. **Confirm approach**: Verify the validation strategy (full validation, specific sections, etc.)
3. **Check prerequisites**: Ensure all tools are available (Task, Edit, Bash, Grep, etc.)

**Ask the user:**

> I'm ready to validate the document(s) using the optimized **batch-based multi-agent system**:
>
> **Execution Pipeline:**
> - **Phase 1.5:** All 7 batch scans (Batches 1-6) launched in parallel via single Bash call
>   - Results cached in SCAN_CACHE for reuse across all agents
>
> - **Phase 3:** 5 parallel Haiku agents (single Task message with 5 invocations)
>   - Each agent receives its pre-computed SCAN_CACHE slice
>   - API Routes, Schema, UI, Melissa, Utilities validation
>
> - **Phase 4:** 1 Prerequisites Hunter agent (sequential after Phase 3 completes)
>   - 2-minute timeout for prerequisite discovery
>
> - **Phase 5-8:** Sonnet synthesis, auto-apply fixes, categorize recommendations, present summary
>
> **Speedup:** Batch scans + parallel Haiku agents + sequential prerequisites hunter = 4-5x faster with zero redundant scans
>
> **Would you like me to proceed with the validation now?**

If user confirms, proceed to Phase 1 (File Location).

---

## **Reference: Context Discovery via _index-master.md**

**When to consult:** If you need to understand what documentation exists or find information about the project structure, agents, commands, or knowledge base.

**What's available:**

📖 **Quick Decision Tree** (Start here if lost)
- Agent lookup (TypeScript, Python, UI, Spec, Linux specialists)
- Slash command discovery (26+ automation commands)
- Technical references (TypeScript, React, Playwright, databases)
- Setup/deployment guides (Docker, dev server, ports)
- Feature documentation (Melissa LLM, UI patterns, monitoring)
- API reference (endpoints, chat API, data models)
- Database schema (models, fields, relationships)
- Troubleshooting guides (common issues, logging, performance)
- Architecture & design decisions (ADRs, system overview)
- Build artifacts (FRDs, design specs, implementation notes)
- Session investigations (past debugging, workarounds)

📊 **Tier System Overview**
- **Tier 1 (Always Preloaded):** CLAUDE.md (~4KB), _index-master.md (~12KB)
- **Tier 2 (On-Demand):** Agent index, slash commands, prompts, local tools (~2-4KB each)
- **Tier 3 (Specialized):** KB, build artifacts, features, operations, sessions (~2-20KB each)
- **Tier 4 (As-Needed):** Project root docs, setup, features, API, database, architecture

**Cost:** Tier 1 is fixed (~16KB). Each additional Tier 2-3 index adds 2-4KB. Total indexed coverage: 172+ items across all tiers.

**When useful for validation:**
- Need to cross-reference agent capabilities for multi-domain work
- Looking for existing utilities or helper functions
- Want to understand what testing patterns or KB references exist
- Checking if similar work has been done before (session logs)
- Need to find the right specialized agent for a task

**Reference:** Load via `.claude/docs/context-management-claude/_index-master.md`

---

**Ready to begin. Waiting for file path or document name to search.**
