# /context-audit - Context Management Audit & Optimization

Run a comprehensive audit of Claude Code context management, including preload/on-demand/blocking strategies, and get optimization recommendations.

## Command Overview

```
/context-audit              # Full audit workflow
/context-audit baseline     # Quick baseline metrics only
/context-audit verify       # Verify .claudeignore configuration
/context-audit optimize     # Get optimization recommendations
/context-audit report       # Generate full audit report
```

## What It Does

This command executes the **Context Management Playbook** - a systematic audit of:

1. **Preloaded Files** - What's always in context and why
2. **On-Demand Files** - Large files loaded only when needed
3. **Blocked Files** - Files excluded for security or optimization
4. **Index Files** - Metadata about available resources
5. **Current Metrics** - Context reduction percentage
6. **Optimization Opportunities** - Where to improve

## Full Workflow (Default)

When you run `/context-audit`, it executes all phases:

### Phase 1: Baseline Assessment (5 min)
- Calculates current preloaded file size
- Counts on-demand resources
- Verifies blocked patterns
- Estimates context reduction percentage

### Phase 2: Strategy Review (10 min)
- Audits categorization of each file
- Identifies potential optimizations
- Checks documentation completeness
- Verifies loading mechanisms work

### Phase 3: Index File Updates (10 min)
- Reviews all `index-*.md` files
- Checks for accuracy and completeness
- Verifies files are properly documented
- Updates last-modified dates if needed

### Phase 4: .claudeignore Verification (5 min)
- Verifies all secrets are blocked
- Checks build artifacts are excluded
- Validates on-demand patterns are correct
- Looks for missing entries

### Phase 5: Documentation Check (5 min)
- Validates CLAUDE.md references strategy
- Checks .claude/README.md structure
- Confirms all index files are linked
- Updates cross-references as needed

### Phase 6: Generate Report (5 min)
- Creates comprehensive audit report
- Suggests optimization opportunities
- Identifies any misconfigurations
- Provides action items

## Quick Audits

### `/context-audit baseline`
Get just the numbers:
```
Preloaded: ~4,000 lines
On-demand: ~35,000 lines
Blocked: 1000s of MB
Context reduction: 73%
```

### `/context-audit verify`
Check .claudeignore configuration:
```
✅ All secrets blocked (.env)
✅ Build artifacts excluded (.next, dist)
✅ Dependencies excluded (node_modules)
✅ Agents properly on-demand
⚠️ [Any issues found here]
```

### `/context-audit optimize`
Get specific recommendations:
```
Optimization opportunities:
1. Consider moving X to on-demand (saves ~Y lines)
2. Update index-Z.md (last updated 3 months ago)
3. Add missing .claudeignore entry for [pattern]
```

### `/context-audit report`
Full detailed report for documentation:
```
=== CONTEXT MANAGEMENT AUDIT REPORT ===
Timestamp: [date/time]
Project: Appmelia Bloom

METRICS:
- Preloaded lines: ~4,000
- On-demand lines: ~35,000
- Potential context: ~39,000
- Current context: ~4,000
- Reduction: 73%

[Full breakdown by category]
[Optimization recommendations]
[Action items]
```

## When to Run

**Weekly:**
- `/context-audit verify` - Quick sanity check

**Monthly:**
- `/context-audit optimize` - Look for improvements

**After Major Changes:**
- `/context-audit report` - Full audit after adding/removing features

**When Onboarding:**
- `/context-audit` - Full workflow to understand project setup

## What Gets Checked

### Preloaded Files ✓
- `.claude/commands/*.md` - Slash command definitions
- `.claude/docs/*.md` - Documentation (except large subdirs)
- `.claude/agents/backend-typescript-architect.md` - Core agent
- `CLAUDE.md` - Project configuration

### On-Demand Files ✓
- `.claude/agents/*` (except above)
- `.claude/prompts/`
- `.claude/commands/build-backlog/` (data files)
- `docs/kb/`
- `_build/` directories

### Blocked Files ✓
- `.env`, `.env.local`, `.env.*.local` (SECRETS)
- `node_modules/` (dependencies)
- `.next/`, `build/`, `dist/` (build output)
- `coverage/`, `playwright-report/` (test artifacts)
- `.db`, `.db-wal`, `.db-shm` (runtime data)
- `.git/`, `.vscode/`, `.idea/` (metadata)

### Index Files ✓
- `index-agents.md` - Agent reference
- `index-slash-commands.md` - Command reference
- `index-prompts.md` - Prompt reference
- `index-other.md` - Configuration reference
- `index-gitignore-claude.ignore.md` - Ignored files manifest

## Output Examples

### Successful Audit
```
Context Management Audit: ✅ PASS
- All secrets properly blocked ✅
- All on-demand files documented ✅
- .claudeignore correctly configured ✅
- Index files up-to-date ✅
- Context reduction: 73% ✅

Recommendations:
✓ All systems optimal
```

### Audit with Recommendations
```
Context Management Audit: ⚠️ PASS WITH RECOMMENDATIONS
- All secrets properly blocked ✅
- All on-demand files documented ✅
- .claudeignore correctly configured ✅
- Index files need updates ⚠️ (3 files > 30 days old)
- Context reduction: 73% ✅

Recommendations:
1. Update index-prompts.md (last: 30+ days ago)
2. Consider adding .claude/docs/cache-notes.md to on-demand
3. Add missing .env.test pattern to .claudeignore
```

## Related Playbook

For detailed documentation on context management strategies:
→ See `.claude/docs/context-management-claude/context-management.md`

This playbook includes:
- Three-strategy overview (preload vs on-demand vs blocking)
- Decision matrix for file categorization
- Optimization scenarios and solutions
- Best practices and metrics
- Weekly/monthly/quarterly audit checklists

## Integration with Other Commands

- **After `/quick-test`:** Run audit to ensure changes don't bloat context
- **With `/prompt-execute`:** Verify on-demand files are accessible
- **Before commits:** Check context health is maintained
- **With `/build-backlog`:** Audit task-related documentation loading

## Implementation Status

This command provides:
- ✅ Full audit workflow
- ✅ Quick verification mode
- ✅ Optimization recommendations
- ✅ Comprehensive reporting
- ✅ Integration with playbook

---

**Last Updated:** 2025-11-17
**Version:** 1.0.0
**Status:** Active - Core context management utility
**Related:** `.claude/docs/context-management-claude/context-management.md`

