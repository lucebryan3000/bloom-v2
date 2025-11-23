---
Context Strategy: L2 (Load on Demand, Searchable)
Tier: 3 - Specialized Reference
---

# Build Artifacts & Planning Index – _build/

**Context Strategy:** L2 (On-Demand, Searchable)
**Total Directories:** 8+ artifact categories
**Total Files:** ~150+ planning and build documentation
**Status:** Build planning, implementation notes, and completed work

---

## Overview

The Build directory (`_build/`) contains planning documents, implementation summaries, completed work archives, and build artifacts. These are **intentionally excluded from preload** (L2 strategy) because:

- **Large volume**: ~150+ files = 80K+ tokens
- **Historical**: Many files are archived/completed work
- **Planning**: Relevant when implementing, not for every conversation
- **Specialized**: Project-level planning, not production code
- **Reference**: Searchable when needed for implementation context

**Usage:** When implementing features, review relevant planning docs. When onboarding, explore completed work to understand patterns.

---

## Directory Structure

```
_build/
├── _planning/                       Active planning & design docs
│   ├── FRDs/                       Functional Requirements Documents
│   ├── design-docs/                Architectural design specifications
│   ├── decision-records/           Architecture Decision Records (ADRs)
│   └── phase-plans/                Phase implementation plans
│
├── _completed/                      Completed work & archives
│   ├── Done-[Feature]/             Archived feature implementations
│   ├── planning-archive-2025/      Historical planning from 2025
│   └── session-context-panel/      Session work archives
│
├── claude-docs/                     Claude-generated reference docs
│   ├── phase-summaries/            Phase completion summaries
│   ├── phase-validation/           Phase validation reports
│   ├── project-management/         Project state snapshots
│   ├── logging-system/             Logging documentation
│   ├── mvp-ready/                  MVP readiness assessments
│   └── [other analyses]            Additional analysis docs
│
├── Melissa-Config/                  Melissa.ai configuration
│   ├── Melissa-Config-Phase*.md    Phase-specific configs
│   └── PHASE-*-SUMMARY.md          Phase summaries
│
├── out-of-scope/                    Deferred/out-of-scope work
│   ├── Bloom-CC-Prompt-*.md        Rejected scope items
│   └── README.md                   Out-of-scope guidelines
│
├── prompts/                         Complex prompt templates
│   ├── Melissa-Playbooks/          Melissa automation playbooks
│   ├── [other large prompts]       Large implementation prompts
│   └── completed/                  Archived prompts
│
├── reference-docs/                  External reference materials
│   └── [vendor docs, specs]        Third-party documentation
│
├── test/                            Test artifacts & fixtures
│   ├── artifacts/                  Generated test data
│   └── [test materials]            Testing documentation
│
└── [other]/                         Additional build artifacts
    └── [project-specific]          Project-specific builds
```

---

## Build Categories

### Planning Documents (_planning/)

**Purpose:** Active project planning and design decisions

**Contains:**
- Functional Requirements Documents (FRDs)
- Architecture Decision Records (ADRs)
- Phase implementation plans
- Feature specifications
- Design documents
- Scope decisions

**When to use:** Planning features, understanding requirements, reviewing design decisions

**Example searches:**
```bash
# Find FRDs for specific feature
grep -l "feature-name" _build/_planning/FRDs/*.md

# Review architecture decisions
ls _build/_planning/decision-records/

# Check phase plans
grep -n "Phase [number]" _build/_planning/phase-plans/*.md
```

---

### Completed Work (_completed/)

**Purpose:** Archive of completed features and work

**Contains:**
- Archived feature implementations
- Historical planning documents
- Session notes from completed work
- Implementation summaries
- Testing results from completed phases

**When to use:** Learning from similar implementations, understanding completed features, historical context

**Structure:**
```
_completed/
├── Done-Dashboard-Widget-Customization/
│   ├── [implementation docs]
│   └── [completion notes]
├── Done-[Other Features]/
└── planning-archive-2025/
    ├── Phase-*-work/
    └── [historical docs]
```

**Example:**
```bash
# Find completed feature similar to what you're building
ls _completed/Done-*/

# Review implementation of similar feature
cat _completed/Done-[Feature]/[IMPLEMENTATION-SUMMARY].md
```

---

### Claude-Generated Docs (claude-docs/)

**Purpose:** Auto-generated reference documentation

**Contains:**
- Phase completion summaries
- Validation reports
- Project state snapshots
- Logging system documentation
- MVP readiness assessments
- Analysis documents

**When to use:** Understanding project state, reviewing phase completions, assessing readiness

**Subdirectories:**
```
claude-docs/
├── phase-summaries/          Phase completion summaries
├── phase-validation/         Phase validation reports
├── project-management/       State snapshots
├── logging-system/           Logging documentation
├── mvp-ready/               MVP readiness docs
└── [analyses]/              Other analyses
```

---

### Melissa Configuration (Melissa-Config/)

**Purpose:** Melissa.ai configuration documentation

**Contains:**
- Phase-specific configuration plans
- Melissa setup guides
- Configuration examples
- Phase completion summaries

**When to use:** Configuring Melissa.ai, understanding agent setup, reviewing phase work

**Files:**
```
Melissa-Config-Phase1.md
Melissa-Config-Phase2.md
...
Melissa-Config-Phase6.md
PHASE-*-SUMMARY.md
PHASE-*-COMPLETE-SUMMARY.md
```

---

### Out-of-Scope Work (out-of-scope/)

**Purpose:** Deferred and rejected scope items

**Contains:**
- Rejected scope items (reasons documented)
- Deferred features
- Out-of-scope guidelines
- Scope decisions

**When to use:** Understanding why features were deferred, avoiding duplicate scope discussions

**Example:**
```bash
# View out-of-scope guidelines
cat _build/out-of-scope/README.md

# See rejected scope items
ls _build/out-of-scope/Bloom-CC-Prompt-*.md
```

---

### Complex Prompts (prompts/)

**Purpose:** Large, reusable prompt templates

**Contains:**
- Melissa playbook prompts
- Implementation playbooks
- Complex multi-phase prompts
- Completed/archived prompts

**When to use:** Running `/prompt-execute`, understanding complex procedures, executing multi-phase implementations

**Structure:**
```
prompts/
├── Melissa-Playbooks/            Melissa automation
├── backup-solution/              Backup implementation
└── completed/                    Archived prompts
```

---

### Reference Documentation (reference-docs/)

**Purpose:** External reference materials

**Contains:**
- Vendor documentation
- API specifications
- External tool documentation
- Third-party references

**When to use:** Understanding external systems, reviewing API docs, vendor documentation

---

### Test Artifacts (test/)

**Purpose:** Test data and artifacts

**Contains:**
- Test data fixtures
- Generated test artifacts
- Test documentation

**When to use:** Understanding test setup, test data generation, debugging test issues

---

## Relationship Between Build Categories

```
_planning/           → Planning phase
   ↓
(Implementation)     → Active development
   ↓
_completed/          → Moved here after completion
   ↓
claude-docs/         → Analysis & documentation
   ↓
(Future phases)      → Continue cycle
```

---

## How to Navigate Build Artifacts

### Starting a New Feature

1. **Check planning**: `_build/_planning/` for FRD and ADRs
2. **Review similar features**: `_build/_completed/Done-*/` for patterns
3. **Review decisions**: `_build/_planning/decision-records/` for existing choices
4. **Follow phase plan**: `_build/_planning/phase-plans/` for structure

### During Implementation

1. **Reference FRD**: `_build/_planning/FRDs/[feature].md`
2. **Check ADRs**: `_build/_planning/decision-records/` for decisions
3. **Review similar work**: `_build/_completed/Done-[Similar]/` for code patterns
4. **Execute playbooks**: `_build/prompts/[playbook].md` for complex procedures

### After Completion

1. **Archive notes**: Move to `_build/_completed/Done-[Feature]/`
2. **Write summary**: Document what was built
3. **Capture patterns**: Record learnings for future features
4. **Update decision records**: Add ADRs for new decisions

---

## Search Strategies

### Find Planning Documents for a Feature

```bash
# Find FRDs mentioning a feature
grep -l "feature-name" _build/_planning/FRDs/*.md

# Find ADRs related to an architectural decision
grep -l "pattern\|architecture" _build/_planning/decision-records/*.md

# Find phase plans
grep -n "Phase [0-9]" _build/_planning/phase-plans/*.md
```

### Find Completed Similar Work

```bash
# List all completed features
ls -d _build/_completed/Done-*/

# Find completion summary
cat _build/_completed/Done-[Feature]/[SUMMARY].md

# Review completion notes
grep -n "implemented\|completed\|tested" _build/_completed/Done-[Feature]/*.md
```

### Find Configuration & Setup

```bash
# Find Melissa config for a phase
cat _build/Melissa-Config/Melissa-Config-Phase[N].md

# Find setup playbooks
ls _build/prompts/*/INSTALLATION*.md

# Find configuration examples
grep -r "config\|setup" _build/claude-docs/
```

### Find Validation & Readiness

```bash
# Check phase validation
cat _build/claude-docs/phase-validation/phase-[N].md

# Check MVP readiness
cat _build/claude-docs/mvp-ready/*.md

# Review project state snapshot
cat _build/claude-docs/project-management/PROJECT-STATE-SNAPSHOT.md
```

---

## Using Build Information

### When Building a Feature

**Steps:**
1. Read the FRD: `_build/_planning/FRDs/[feature].md`
2. Review related ADRs: `_build/_planning/decision-records/`
3. Check similar completed features: `_build/_completed/Done-*/`
4. Follow the phase plan: `_build/_planning/phase-plans/`
5. Implement following captured patterns
6. Document in ADRs if new decisions
7. Move notes to `_build/_completed/Done-[Feature]/` when done

### When Debugging

**Steps:**
1. Find similar issue in completed work: `_build/_completed/`
2. Check validation reports: `_build/claude-docs/phase-validation/`
3. Review project state: `_build/claude-docs/project-management/`
4. Search logging documentation: `_build/claude-docs/logging-system/`

### When Planning New Work

**Steps:**
1. Review out-of-scope items: `_build/out-of-scope/` (avoid conflicts)
2. Check existing ADRs: `_build/_planning/decision-records/` (learn from past decisions)
3. Review completed similar work: `_build/_completed/Done-*/` (use as template)
4. Create new FRD: Following existing FRD patterns
5. Create new ADRs for new decisions

---

## Archive Strategy

### Active Work
- Lives in `_build/_planning/`
- Referenced during feature development
- Updated as phases progress

### Completed Work
- Moved to `_build/_completed/Done-[Feature]/`
- Kept for reference and pattern matching
- Not actively modified

### Historical Archives
- `_build/_completed/planning-archive-2025/`
- Old planning docs from completed phases
- Reference for historical context

### Deprecated/Out-of-Scope
- `_build/out-of-scope/`
- Deferred features documented with reasons
- Prevents revisiting dismissed ideas

---

## Maintenance

### Weekly
- No maintenance required (reference docs)
- Occasionally add notes to active planning docs

### Monthly
- Archive completed features: `_completed/Done-[Feature]/`
- Review planning docs for accuracy
- Clean up temporary artifacts

### Quarterly
- Archive old phase planning: `_completed/planning-archive-[YEAR]/`
- Consolidate decision records
- Create reference docs from patterns

---

## Examples

### Example 1: Find Pattern from Similar Feature

```bash
# Task: Building a new settings panel
# Solution:
# 1. Check what settings already exist
grep -r "settings" _build/_completed/

# 2. Find completed settings work
cat _build/_completed/Done-Dashboard-Settings/[SUMMARY].md

# 3. Use patterns from completed work as template
# 4. Reference ADRs for design decisions
cat _build/_planning/decision-records/settings-*.md
```

### Example 2: Understand Phase Implementation

```bash
# Task: Starting Phase 7
# Solution:
# 1. Read phase plan
cat _build/_planning/phase-plans/phase-7-plan.md

# 2. Review previous phase completion
cat _build/_completed/Done-Phase-6/COMPLETION-SUMMARY.md

# 3. Check validation
cat _build/claude-docs/phase-validation/phase-6.md

# 4. Start implementing with confidence
```

### Example 3: Avoid Out-of-Scope Work

```bash
# Task: Considering adding a new feature
# Solution:
# 1. Check if it's out-of-scope
grep -l "feature-name" _build/out-of-scope/*.md

# 2. Read the rejection reason
cat _build/out-of-scope/Bloom-CC-Prompt-[FEATURE].md

# 3. Understand why it was deferred
# 4. Decide: is it truly needed now?
```

---

## Integration with Index System

This index provides:

✅ **Awareness** – Know what planning and completed work exists
✅ **Navigation** – Know where to find artifacts
✅ **Discovery** – Find similar features and patterns
✅ **Context reduction** – Artifacts stay L2 (excluded from preload)

---

## Key Metrics

- **Active Planning**: ~30 files in `_planning/`
- **Completed Work**: ~50+ files in `_completed/`
- **Claude Docs**: ~30+ analysis documents
- **Prompts**: ~25+ prompt templates
- **Total**: ~150+ files
- **Context Cost if Preloaded**: ~80,000+ tokens
- **Current Context Cost**: ~0 tokens (indexed, not loaded)

---

**Last Updated:** 2025-11-17
**Status:** Build documentation fully indexed
**Access:** Search or navigate directly to _build/ directory
**Strategy:** L2 (On-Demand) – indexed for awareness, blocked from preload
