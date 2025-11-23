# Context Management Optimization Proposal
## From 50K+ Tokens of Preload to Surgical L0/L1/L2 Architecture

**Date:** 2025-11-17
**Current Status:** 🔴 BLOATED - 51,707 tokens preloaded (34x over budget)
**Target:** 🟢 LEAN - ≤1,500 tokens preloaded (L0 only)

---

## Executive Summary

Your current `.claudeignore` setup loads **7,107 lines (~51.7K tokens)** on every conversation. The goal of the L0/L1/L2 model is to shrink that to **≤1,500 tokens** while keeping everything accessible via commands.

**Key insight:** You don't need 50K tokens in context every turn. You need:
- A tiny instruction set (L0)
- Quick access to specialized tools (L1 - "first command load")
- Everything else on-demand (L2)

This saves context overhead and makes Claude much more responsive and accurate.

---

## Part 1: Diagnosis – What's Overkill

### Current Preload Breakdown

```
🔴 L0 PRELOADS (should be ~1,500 tokens max):
   CLAUDE.md                                          553 lines
   All .claude/commands/*.md                        2,470 lines    ← TOO MANY
   All .claude/docs/*.md                            2,100 lines    ← TOO MANY
   backend-typescript-architect.md                    480 lines    ← PERSONA, should be L1
   .claude/README.md                                  534 lines    ← META, should be L1
   ─────────────────────────────────────────────────────────────
   CURRENT TOTAL:                                    7,107 lines    ← 34x over budget
```

### Key Problems

| Issue | Impact | Example |
|-------|--------|---------|
| **All commands preloaded** | Wastes tokens on commands you're not using | Loading `/quick-test` even when doing architecture review |
| **All docs preloaded** | Verbose reference text burns context | `api-reference.md` (548 lines) loaded even for backend work |
| **Persona in preload** | Conflicts with other agents; mixing roles | backend-typescript-architect + /agent-ui loaded together |
| **Index files preloaded** | Metadata loaded but rarely used | 262 lines of index catalog on every turn |
| **No hard budget** | Creep guaranteed; no enforcement | Will grow from 7K → 20K over 6 months |

### Why This Matters

- **Every message incurs 50K token overhead** → Less room for actual work context
- **Model gets confused by multiple personas** → Mixing backend specialist + UI engineer instructions
- **Duplication in instructions** → CLAUDE.md + agent files say similar things
- **No guard rails** → New docs/commands auto-preload without questioning

---

## Part 2: The L0/L1/L2 Model

### What Each Layer Does

```
L0 – HARD PRELOAD (≤1,500 tokens)
├─ Loaded: Always, on every turn
├─ Size: Tiny. No tutorials, examples, or verbose docs.
├─ Role: Only what Claude needs to not be dumb in any Bloom conversation
└─ Examples: Core rules, pointers to more, essential context

L1 – SOFT PRELOAD (≤10,000 tokens)
├─ Loaded: Via single slash command (e.g., /session-backend)
├─ Size: Medium. Role-specific or domain-specific bundles.
├─ Role: "First-command load" - one hop to get specialized context
└─ Examples: Agent personas + small KB, commands for a specific workflow

L2 – ON-DEMAND / BLOCKING
├─ Loaded: Explicit tool call or never
├─ Size: Unlimited
├─ Role: Specialized, large, or security-sensitive
└─ Examples: Prompts, build backlog, env files, node_modules
```

### Mapping Your Current Files

| File | Current | Target Layer | Reason |
|------|---------|--------------|--------|
| `CLAUDE.md` | L0 | L0 (trimmed) | Core rules, should stay but ruthlessly cut |
| `backend-typescript-architect.md` | L0 | L1 | Persona file; load via `/session-backend` |
| `.claude/commands/*.md` | L0 | L1 (bundled) | Heavy command docs; use quick-ref in L0 |
| `.claude/docs/roi-formulas.md` | L0 | L1 | Reference; load when doing ROI work |
| `.claude/docs/melissa-context.md` | L0 | L1 | Melissa patterns; load when building Melissa |
| `.claude/docs/api-reference.md` | L0 | L1 | API guide; load when integrating |
| `.claude/docs/teleport-workflow.md` | L0 | L1 | Workflow docs; reference as needed |
| `context-management.md` (this playbook) | L0 | L1 | Meta-docs; read when optimizing context |
| Index files | L0 | L2 | Catalogs; read via `/context-audit` |
| `.claude/README.md` | L0 | L1 | Project README; meta-resource |

---

## Part 3: Concrete Changes to Make

### 3.1 Create Trimmed L0 Core Files

#### New File: `CLAUDE.md` (Trimmed Version)
**Target:** 300-400 lines, ~800-1,200 tokens

Keep only:
- Project name & purpose (2-3 lines)
- Critical safety rules (defensive deletion, security)
- 3-4 core development standards (TypeScript strict, no browser popups, database conventions)
- **POINTERS** to where full documentation lives (not the full text)

Remove:
- Long tutorials
- Full examples (link to KB instead)
- Entire sections like "Project Structure" (it's in README)
- Repetitive rules that agents will have anyway

**Sample structure:**
```markdown
# Bloom Project Configuration

## Critical Rules
- [Defensive deletion protocol](./docs/context-management-claude/CLAUDE.md-full.md)
- [No browser popups](./docs/kb/...)
- TypeScript strict mode always

## For More
- Full config: See `.claude/README.md`
- Architecture: See `docs/ARCHITECTURE.md`
- Database: See `prisma/schema.prisma`

## Load Specialized Context
/session-backend    # For backend work
/session-frontend   # For UI/React work
/session-melissa    # For Melissa.ai work
```

#### New File: `.claude/docs/commands-quick-reference.md`
**Target:** 100-150 lines, ~250-400 tokens

One-liner per command + link to full docs:

```markdown
# Slash Commands – Quick Reference

## Core Commands
- `/quick-test` – Run all quality checks (type check, lint, build, test)
- `/db-refresh` – Reset database to clean seed state
- `/test-melissa` – Test Melissa.ai chat interface

## Specialized
- `/build-backlog` – View task backlog (→ see `.claude/commands/build-backlog.md`)
- `/validate-roi [scenario]` – Test ROI calculations
- `/prompt-execute` – Run complex implementation prompts

## Agents (Load on-demand)
- `/agent-backend` – Backend TypeScript Architect
- `/agent-ui` – UI Engineer for React
- (see `.claude/docs/context-management-claude/index-agents.md` for full list)

## Context Management
- `/context-audit` – Audit & optimize context usage
```

### 3.2 Create L1 Command Bundles

Instead of preloading all `.claude/commands/*.md`, create role-specific bundles:

#### New: `/session-backend`
Loads:
- `.claude/agents/backend-typescript-architect.md` (480 lines)
- Small backend KB snippet
- `validate-roi.md` quick command

#### New: `/session-frontend`
Loads:
- `.claude/agents/ui-engineer.md`
- React/component KB snippets

#### New: `/session-melissa`
Loads:
- Melissa agent file
- `test-melissa.md` command
- Melissa conversation patterns

**Command file structure:**
```markdown
# /session-backend

This loads the Backend TypeScript Architect persona plus backend-specific context.

When you run this, you get:
- Full backend architect agent instructions
- Backend development standards
- Key API/database patterns
- /validate-roi command for ROI work

Use this when:
- Implementing API endpoints
- Modifying database schema
- Debugging backend logic
```

### 3.3 Update `.claudeignore` to Enforce L0/L1/L2

```yaml
# .claudeignore – Three-Tier Context Strategy

# ===== L0: HARD PRELOAD (≤1,500 tokens total) =====
# Only tiny, essential files

# CLAUDE.md – Keep but only trimmed version
# (No action needed if we trim in-place)

# Commands Quick Reference – ONE file only
!.claude/docs/commands-quick-reference.md
# Block everything else in docs
.claude/docs/*

# Block all full commands (loaded via L1 bundles)
.claude/commands/*
!.claude/commands/quick-test.md  # Keep one: maybe this is your "always-on"?

# Block agent personas (load via /session-* bundles)
.claude/agents/*

# ===== L1: SOFT PRELOAD (Via slash commands) =====
# NOT in .claudeignore – loaded explicitly
# Examples:
#   /session-backend → loads backend architect + backend KB
#   /session-melissa → loads Melissa agent + patterns
#   /agent-ui → loads UI engineer (for one-off specialist work)

# ===== L2: ON-DEMAND / BLOCKING =====

# Build backlog – on-demand
.claude/commands/build-backlog/*.md
!.claude/commands/build-backlog.md

# Prompts – on-demand (large templates)
.claude/prompts/

# Security – block always
.env
.env.local
.env.*.local
.sentryclirc

# Standard ignores
node_modules/
.next/
out/
build/
dist/

# ... (rest of standard ignores)
```

### 3.4 Add Hard L0 Budget Enforcement

Create a script that runs on every commit or periodically:

**New file: `.claude/scripts/check-l0-budget.sh`**

```bash
#!/bin/bash
set -euo pipefail

L0_FILES=(
  "CLAUDE.md"
  ".claude/docs/commands-quick-reference.md"
)

TOTAL_BYTES=0
for file in "${L0_FILES[@]}"; do
  if [ -f "$file" ]; then
    bytes=$(wc -c < "$file")
    TOTAL_BYTES=$((TOTAL_BYTES + bytes))
    echo "  $(basename $file): $(( bytes / 4 )) tokens (rough)"
  fi
done

TOTAL_TOKENS=$((TOTAL_BYTES / 4))
BUDGET=1500

echo
echo "L0 Total: ~$TOTAL_TOKENS tokens"
echo "Budget: $BUDGET tokens"

if [ $TOTAL_TOKENS -gt $BUDGET ]; then
  echo "❌ OVER BUDGET by $((TOTAL_TOKENS - BUDGET)) tokens"
  exit 1
else
  HEADROOM=$((BUDGET - TOTAL_TOKENS))
  echo "✅ WITHIN BUDGET ($HEADROOM tokens headroom)"
  exit 0
fi
```

### 3.5 Document the "One Persona at a Time" Rule

Add to `CLAUDE.md` (L0 version):

```markdown
## Context Loading Rules

### Personas are Exclusive (Not Additive)
- Only ONE agent persona active per session
- When you load `/session-backend`, we're in backend mode
- Loading `/agent-ui` after that **replaces** backend mode
- No mixing personas – it confuses the model

Why: Different agents have different instructions and priorities.
Combining them creates conflicting guidance.

### Load Order Matters
1. Start with base context (CLAUDE.md only)
2. Load ONE persona bundle: `/session-backend`, `/session-melissa`, etc.
3. Specialized agents are one-off: `/agent-reviewer` for code reviews only

### Avoiding Context Conflicts
If instructions conflict, **centralize in one place** and reference:
- ❌ Don't repeat rules in multiple files
- ✅ Do centralize rules in CLAUDE.md and link from agents
```

---

## Part 4: Tightened Audit Workflow

### New Audit Checklist

When you need to audit or add files, use this:

```markdown
## File Addition Checklist

[ ] Is this file ≤500 tokens and **essential for every conversation**?
    YES → Consider for L0 (but verify L0 budget first)
    NO  → It's L1 or L2

[ ] Is this file ≤10,000 tokens and **used by specific workflows**?
    YES → Create or add to L1 bundle (/session-* command)
    NO  → It's L2 (on-demand only)

[ ] Does this file repeat rules from CLAUDE.md or other files?
    YES → Centralize; delete duplication; link instead
    NO  → OK to add as-is

[ ] Does this file need a persona? (agent, instructions, role)
    YES → It's L1 (never L0); load via command
    NO  → Reference docs are fine as L1

[ ] If it's a reference doc, will you need it every turn?
    YES → L0 (but must trim ruthlessly)
    NO  → L1 or L2 (link from L0)
```

### Monthly Audit Task

Every month, run:

```bash
# Check L0 budget
.claude/scripts/check-l0-budget.sh

# If over budget, identify culprits:
du -sh CLAUDE.md .claude/docs/commands-quick-reference.md

# Review new files added to .claude/:
git log --oneline -10 -- .claude/

# Ask: Does each file *need* to be preloaded?
# If not, move to L1 or L2
```

---

## Part 5: Migration Plan (Phased)

### Phase 1: Create L0 Core (1 day)
1. Trim `CLAUDE.md` from 553 → 300-400 lines
2. Create `commands-quick-reference.md` (100-150 lines)
3. Verify total ≤1,500 tokens

### Phase 2: Create L1 Bundles (1-2 days)
1. Create `/session-backend` command
2. Create `/session-frontend` command
3. Create `/session-melissa` command
4. Test each loads correct context

### Phase 3: Update `.claudeignore` (1 day)
1. Block all `.claude/commands/*.md` except L0 reference
2. Block `.claude/docs/*` except L0 reference
3. Block `.claude/agents/*` (load via commands)
4. Verify no accidental preloads via negation rules

### Phase 4: Add Enforcement (1 day)
1. Create `check-l0-budget.sh` script
2. Add to pre-commit hook (optional)
3. Document in README

### Phase 5: Update Playbook (1 day)
1. Rewrite context-management.md to document L0/L1/L2
2. Add audit checklist
3. Remove old "73% reduction" metrics; add new L0 budget

---

## Part 6: Expected Results

### Before Optimization
```
L0 Preload:  51,707 tokens (every turn)
Overhead:    70-75% of context used before any work
Conflicts:   Multiple agent personas in context simultaneously
Creep:       No budget, guaranteed to grow
```

### After Optimization
```
L0 Preload:  ~1,000-1,200 tokens (every turn)
Overhead:    ~3-5% of context (before any work)
Conflicts:   One active persona at a time
Creep:       Hard budget enforced; weekly audit

Result: 50x reduction in baseline overhead
        More room for actual code/conversation context
        Cleaner, less conflicted instructions
        Sustainable long-term
```

---

## Part 7: Implementation Checklist

- [ ] **Trim CLAUDE.md** to 300-400 lines
- [ ] **Create commands-quick-reference.md** (100-150 lines)
- [ ] **Verify L0 budget** ≤1,500 tokens
- [ ] **Create /session-backend** command bundle
- [ ] **Create /session-frontend** command bundle
- [ ] **Create /session-melissa** command bundle
- [ ] **Update .claudeignore** with new L0/L1/L2 rules
- [ ] **Create check-l0-budget.sh** script
- [ ] **Rewrite context-management.md** with new model
- [ ] **Update .claude/README.md** with new workflow
- [ ] **Test:** Run `/context-audit baseline` and verify ≤1,500 token L0
- [ ] **Commit** with message: "refactor: L0/L1/L2 context strategy – 50x overhead reduction"
- [ ] **Document in CLAUDE.md** how new system works

---

## Questions to Resolve

1. **Should `/quick-test` stay in L0?** It's tiny (88 lines) and you run it often. Probably yes, keep it.
2. **What about `.claude/README.md`?** It's meta; move to L1.
3. **Should backend architect always load?** No – load via `/session-backend` on-demand.
4. **How often to audit?** Weekly quick-check (budget only); monthly deep audit (file-by-file review).
5. **Should old metrics be deleted?** Update, don't delete – show "before/after" for learning.

---

## Related Files

- [context-management.md](./context-management.md) – Current playbook (to be rewritten)
- [index-agents.md](./index-agents.md) – Keep as L1 reference
- [index-slash-commands.md](./index-slash-commands.md) – Keep as L1 reference
- [CLAUDE.md](../../CLAUDE.md) – To be trimmed
- [.claudeignore](../../.claudeignore) – To be updated
- [.claude/README.md](../README.md) – To be updated

---

**Next Step:** Review this proposal, then begin Phase 1 (trim CLAUDE.md) if you approve.
