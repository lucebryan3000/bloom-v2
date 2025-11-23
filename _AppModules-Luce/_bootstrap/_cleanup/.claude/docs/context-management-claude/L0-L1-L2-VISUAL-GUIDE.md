# L0/L1/L2 Context Architecture – Visual Guide

A simple visual reference for how context loading will work after optimization.

---

## Current State (Bloated)

```
┌─────────────────────────────────────────────────────────┐
│  EVERY CONVERSATION STARTS WITH...                      │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  L0 (ALWAYS LOADED)                     51,707 TOKENS  │
│  ┌─────────────────────────────────────────────┐       │
│  │  • CLAUDE.md (553 lines)                    │       │
│  │  • All .claude/commands/*.md (~2,470 lines) │       │
│  │  • All .claude/docs/*.md (~2,100 lines)     │       │
│  │  • backend-typescript-architect.md (480)    │       │
│  │  • .claude/README.md (534 lines)            │       │
│  │  • All index files (~300 lines)             │       │
│  │                                             │       │
│  │  Problem: 🔴 34x over budget!               │       │
│  │  Context used before any work:  ~70%        │       │
│  │  Multiple personas in context: Yes (bad!)   │       │
│  └─────────────────────────────────────────────┘       │
│                                                         │
│  Remaining context for actual work: ~29,000 tokens     │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## Target State (Optimized)

```
SCENARIO 1: General Work (Just L0)
┌──────────────────────────────────────────────────────┐
│  EVERY CONVERSATION STARTS WITH...                   │
├──────────────────────────────────────────────────────┤
│                                                      │
│  L0 (ALWAYS LOADED)                    ~1,200 TOKENS │
│  ┌──────────────────────────────────────────┐       │
│  │  • CLAUDE.md (trimmed 300-400 lines)     │       │
│  │  • commands-quick-reference.md (100 ln)  │       │
│  │                                          │       │
│  │  Result: ✅ On budget!                   │       │
│  │  Context used before any work:  ~3%      │       │
│  │  Multiple personas: No (clean!)          │       │
│  └──────────────────────────────────────────┘       │
│                                                      │
│  Remaining context for actual work: ~58,000 tokens  │
│  📈 2x more room than before!                        │
│                                                      │
└──────────────────────────────────────────────────────┘

SCENARIO 2: Backend Work (L0 + /session-backend)
┌──────────────────────────────────────────────────────┐
│  USER RUNS: /session-backend                         │
├──────────────────────────────────────────────────────┤
│                                                      │
│  L0 (Always there)                    ~1,200 TOKENS  │
│  ┌──────────────────────────────────────────┐       │
│  │  • CLAUDE.md (trimmed)                   │       │
│  │  • commands-quick-reference.md           │       │
│  └──────────────────────────────────────────┘       │
│                                                      │
│  L1 (Loaded on demand)                ~5,000 TOKENS  │
│  ┌──────────────────────────────────────────┐       │
│  │  • backend-typescript-architect.md       │       │
│  │  • Backend development standards         │       │
│  │  • validate-roi command snippet          │       │
│  │  • Key API/database KB excerpt           │       │
│  └──────────────────────────────────────────┘       │
│                                                      │
│  Total loaded: ~6,200 tokens                         │
│  Room for work: ~53,000 tokens                       │
│  Active persona: Backend Specialist (no conflicts!)  │
│                                                      │
└──────────────────────────────────────────────────────┘

SCENARIO 3: Melissa Work (L0 + /session-melissa)
┌──────────────────────────────────────────────────────┐
│  USER RUNS: /session-melissa                         │
├──────────────────────────────────────────────────────┤
│                                                      │
│  L0 (Always there)                    ~1,200 TOKENS  │
│  L1 (Loaded on demand)                ~6,000 TOKENS  │
│  ├─ melissa-ai agent (persona)                      │
│  ├─ Conversation patterns                           │
│  ├─ test-melissa.md command                         │
│  ├─ KB: Melissa data extraction patterns            │
│  └─ ROI calculation hooks                           │
│                                                      │
│  Total loaded: ~7,200 tokens                         │
│  Room for work: ~52,000 tokens                       │
│  Active persona: Melissa.ai Specialist              │
│                                                      │
└──────────────────────────────────────────────────────┘
```

---

## How Files Move Between Layers

```
BEFORE (Everyone in L0)
┌─ CLAUDE.md ─────────────────┐
│ 553 lines, 27% overhead     │
├─────────────────────────────┤
│ Includes:                   │
│ • Core rules                │ ← KEEP (but trim)
│ • Full setup tutorial       │ ← MOVE to L1 (README)
│ • 50 examples              │ ← MOVE to KB (L2)
│ • Full tech stack list      │ ← MOVE to README
│ • Complete architecture     │ ← LINK to ARCHITECTURE.md
│ • Long troubleshooting      │ ← LINK to docs/operations/
└─────────────────────────────┘

AFTER (Trimmed L0)
┌─ CLAUDE.md (Trimmed) ───────┐
│ 300-400 lines, ~3% overhead │
├─────────────────────────────┤
│ Contains only:              │
│ ✅ Critical rules           │
│ ✅ Core safety policies     │
│ ✅ Links to detailed docs   │
│ ✅ Persona loading commands │
│                             │
│ Lines removed:              │
│ • 100+ lines of tutorial    │
│ • 50+ example code blocks   │
│ • Duplicate project info    │
│ • Lengthy troubleshooting   │
│                             │
│ Result: Same knowledge,     │
│ 30% the size!               │
└─────────────────────────────┘
         ↓
┌─ L1 Bundles ────────────────┐
│ Loaded on demand            │
├─────────────────────────────┤
│ /session-backend            │
│ /session-frontend           │
│ /session-melissa            │
│ /agent-reviewer             │
│ ... (per-role context)      │
└─────────────────────────────┘
         ↓
┌─ L2 On-Demand ──────────────┐
│ Loaded when searching       │
├─────────────────────────────┤
│ • Full docs/                │
│ • Prompts                   │
│ • Build backlog             │
│ • Full agent definitions    │
└─────────────────────────────┘
```

---

## Command Discovery Flow

### Old Way (Everything Preloaded)
```
Start conversation
    ↓
50K tokens of context loaded
    ↓
Ask a question
    ↓
Claude responds
    ↓
(Lots of unused context already loaded, wasted tokens)
```

### New Way (Minimal L0 + Command-Based L1)
```
Start conversation
    ↓
1.2K tokens of L0 loaded (only essentials)
    ↓
Choose a workflow
    ↓
Run /session-backend (or /agent-ui, etc.)
    ↓
~5-10K tokens of L1 context loaded (role-specific)
    ↓
Ask a question
    ↓
Claude responds with full context for that role
    ↓
(Efficient! Only loaded what's needed for this session.)
```

---

## File Organization After Optimization

```
.claude/
├── CLAUDE.md                    L0 (trimmed, ~300-400 lines)
│
├── docs/
│   ├── commands-quick-reference.md         L0 (one-liner per command)
│   │
│   ├── roi-formulas.md                     L1 (load when doing ROI)
│   ├── melissa-context.md                  L1 (load when on Melissa)
│   ├── api-reference.md                    L1 (load when integrating)
│   ├── teleport-workflow.md                L1 (load when switching)
│   ├── README.md                           L1 (project meta-docs)
│   │
│   └── context-management-claude/
│       ├── context-management.md           L1 (this playbook, rewritten)
│       ├── index-agents.md                 L2 (read when auditing)
│       ├── index-slash-commands.md         L2 (read when auditing)
│       ├── index-prompts.md                L2 (read when auditing)
│       ├── index-other.md                  L2 (read when auditing)
│       └── index-gitignore-claude.ignore.md   L2 (read when auditing)
│
├── commands/
│   ├── quick-test.md                       L0? (kept if essential)
│   ├── session-backend.md                  L1 (new: /session-backend)
│   ├── session-frontend.md                 L1 (new: /session-frontend)
│   ├── session-melissa.md                  L1 (new: /session-melissa)
│   ├── build-backlog.md                    L1 (specialized command)
│   ├── prompt-execute.md                   L1 (specialized command)
│   ├── validate-roi.md                     L1 (specialized command)
│   ├── test-melissa.md                     L1 (specialized command)
│   │
│   └── [other command files blocked]       L2 (on-demand)
│
├── agents/
│   ├── backend-typescript-architect.md     L1 (loaded via /session-backend)
│   ├── ui-engineer.md                      L1 (loaded via /session-frontend)
│   ├── melissa-ai.md                       L1 (loaded via /session-melissa)
│   │
│   └── [all other agents]                  L2 (load via /agent-* as needed)
│
├── prompts/
│   ├── [all prompts]                       L2 (on-demand, /prompt-execute)
│
└── scripts/
    └── check-l0-budget.sh                  Tool (enforcement)
```

---

## Budget Visualization

```
Current: 51,707 tokens in L0
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃████████████████████████████████████████████████████ (50K+)   ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
Budget: 1,500 tokens
┌─────────────────────────────────────────────────────────────┐
│█ 1500 tokens budget (✅ achievable)                         │
└─────────────────────────────────────────────────────────────┘

Overhead Comparison:
Old:  ████████████████████████████████████████████████ 70%
New:  ███ 3%

Context Saved:    ~50,000 tokens per conversation
Available for:    Code, conversation, search results, reasoning
Multiplier:       2x more room for actual work
Accuracy:         Higher (less conflicting instructions)
```

---

## Migration Timeline

```
Week 1: Phase 1 – Create L0 Core
  Day 1: Trim CLAUDE.md (553 → 300-400 lines)
  Day 2: Create commands-quick-reference.md
  Day 3: Verify budget ≤1,500 tokens
         ✅ Checkpoint 1 complete

Week 2: Phase 2 – Create L1 Bundles
  Day 1: Create /session-backend command
  Day 2: Create /session-frontend command
  Day 3: Create /session-melissa command
  Day 4: Test each bundle loads correctly
         ✅ Checkpoint 2 complete

Week 3: Phase 3 – Update .claudeignore
  Day 1: Rewrite rules for L0/L1/L2
  Day 2: Test with actual commands
  Day 3: Verify no accidental preloads
         ✅ Checkpoint 3 complete

Week 4: Phase 4 & 5 – Finalize & Document
  Day 1: Create check-l0-budget.sh script
  Day 2: Rewrite context-management.md
  Day 3: Update all references in README
  Day 4: Final testing & commit
         ✅ Checkpoint 4 complete

Result: 50x reduction in baseline context overhead
```

---

## Decision Tree: Where Does a New File Go?

```
New file to add?
│
├─ "Do I need this on EVERY conversation?"
│  │
│  ├─ YES (and < 500 tokens)
│  │  └─ "Is it a core rule or instruction?"
│  │     ├─ YES → L0 (but verify budget!)
│  │     └─ NO → Probably doesn't exist yet; reconsider
│  │
│  └─ NO
│     ├─ "Will it be used by a specific workflow/role?"
│     │  ├─ YES → L1 (create bundle or add to existing)
│     │  └─ NO → Continue below
│     │
│     └─ "Is it reference docs, examples, or specialized?"
│        ├─ YES → L2 (on-demand, search)
│        └─ NO → Consider if you really need it
```

---

## Summary: What Changes & What Stays

```
STAYS THE SAME:
  ✅ All functionality remains
  ✅ All commands still work
  ✅ All agents still available
  ✅ All docs still accessible
  ✅ Slash command interface unchanged

CHANGES:
  🔄 L0: Shrinks from 51K → ~1.2K tokens
  🔄 Loading strategy: Add /session-* bundles
  🔄 .claudeignore: Tighter rules (L0/L1/L2)
  🔄 CLAUDE.md: Trimmed (rules only, links to docs)
  🔄 Budget: Enforced via script

BENEFIT:
  📊 50x overhead reduction
  📈 2x more context for real work
  🎯 Cleaner, no conflicting instructions
  🔒 Sustainable (budget-enforced growth)
  ⚡ Faster, more accurate Claude responses
```

---

**Next:** Review this guide, then start Phase 1 if you approve!
