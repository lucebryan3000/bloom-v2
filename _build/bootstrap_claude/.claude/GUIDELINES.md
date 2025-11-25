# Claude Code Analysis Guidelines

## Purpose

This document provides systematic frameworks to ensure thoughtful, sustainable decisions before writing code. Avoid reactive quick fixes that create technical debt.

---

## Phase 1: Problem Understanding (Required)

Before touching ANY code, answer these questions:

**What is the ACTUAL problem?**
- [ ] What specific error messages or symptoms are we seeing?
- [ ] What was working before that isn't working now?
- [ ] What recently changed in the system?
- [ ] Is this a logic issue, configuration issue, or architectural issue?

**What is the SCOPE of the problem?**
- [ ] Single file/component issue or system-wide?
- [ ] Data/state issue or just display/behavior?
- [ ] Temporary failure or fundamental incompatibility?
- [ ] Critical blocker or nice-to-have improvement?

**What are the CONSTRAINTS?**
- [ ] What patterns already exist in this codebase?
- [ ] What architectural decisions must we respect?
- [ ] What tech stack or frameworks are we locked into?
- [ ] What can't be changed without major refactoring?

---

## Phase 2: Solution Evaluation (Required)

For each potential solution, rate these dimensions:

### Solution Analysis Template

```
SOLUTION: [Brief description]

✅ Pros:
- [Benefit 1]
- [Benefit 2]

❌ Cons:
- [Risk 1]
- [Risk 2]

🔧 Complexity: [1=trivial, 5=major refactor]
⚡ Speed to implement: [1=hours, 5=weeks]
🛡️ Long-term sustainability: [1=tech debt, 5=solid foundation]
🎯 Alignment with patterns: [1=violates norms, 5=perfect fit]

📖 Documentation needed: [What changes to docs/comments]
```

**Required Solutions to Evaluate:**
1. Fix the root cause (proper solution)
2. Workaround (temporary fix)
3. Refactor existing code (preventive)
4. Downgrade/bypass (avoid the issue)

---

## Phase 3: Decision Matrix (Required)

Choose your solution based on:

- [ ] **Root cause fix** > Workaround (when feasible)
- [ ] **Sustainability** > Speed (prefer long-term health)
- [ ] **Existing patterns** > New approaches (consistency matters)
- [ ] **Simple architecture** > Complex dependencies
- [ ] **Clear tradeoffs** > Hidden technical debt

**Decision Template:**
```
CHOSEN SOLUTION: [Which option and why]

REASONING:
- Why this beats other options:
- Long-term impact if we choose this:
- Risks if this fails:
```

---

## Phase 4: Implementation Plan (Required)

Before starting ANY code:

- [ ] What files will be modified?
- [ ] What systems will be affected?
- [ ] What is the rollback plan if this fails?
- [ ] How will we verify success?
- [ ] What testing is required?
- [ ] What documentation updates are needed?

---

## Red Flags: STOP and Reconsider

If your solution involves ANY of these, re-evaluate before proceeding:

❌ **No clear root cause identified** - You're guessing, not solving
❌ **Working around instead of fixing** - Creates technical debt
❌ **Adding complexity** - More lines/dependencies than the problem warrants
❌ **Ignoring existing patterns** - Code becomes inconsistent
❌ **No rollback plan** - Can't safely test this approach
❌ **Major version downgrades** - Fixing config is better
❌ **Hardcoded values** - Should be config or constants
❌ **Skipping tests** - "I'll test it later" is unreliable
❌ **Making "quick fixes"** - These compound into technical debt

---

## Anti-Patterns to Avoid

**Based on common mistakes:**

- Don't write code until you've understood the problem completely
- Don't assume something is "old code" without checking if it's used
- Don't break working systems to experiment (sandbox first)
- Don't ignore established architecture patterns
- Don't skip the decision matrix to save time
- Don't create workarounds instead of fixing root causes
- Don't add features beyond the current scope
- Don't over-engineer simple problems

---

## Before You Start Coding

Use this checklist:

- [ ] Problem clearly identified and verified
- [ ] Root cause understood (not just symptoms)
- [ ] 2-3 solutions evaluated with pros/cons
- [ ] Best solution chosen with clear reasoning
- [ ] Complexity/speed/sustainability assessed
- [ ] Files to change identified
- [ ] Rollback plan documented
- [ ] Testing approach planned
- [ ] Documentation updates needed identified

**If you can't check all boxes, stop and investigate further.**

---

## Code Safety Principles

- **No deletion without investigation** - Verify usage, symlinks, dependencies first
- **No assumption about age** - Old files might be actively used
- **No hardcoded paths or IDs** - Use configuration or relative references
- **No breaking changes without warning** - Deprecate before removing
- **No code duplication** - Refactor to shared functions/patterns
- **No over-complexity** - Simple solutions are better than clever ones

---

## Documentation Requirements

### When Creating New Code
- Include inline comments for "why", not "what"
- Document assumptions and constraints
- Add examples for non-obvious behavior
- Update relevant docs/READMEs

### When Fixing Problems
- Document the root cause
- Explain why this solution was chosen
- Add comments preventing the same issue later
- Update troubleshooting guides if applicable

### When Creating Patterns
- Show the pattern with clear examples
- Explain when/why to use it
- Document alternatives and tradeoffs

---

## Example: Decision Framework in Action

**TASK**: Improve API response time (currently 500ms)

**PHASE 1: Understanding**
- Problem: Single endpoint is slow, others are fast
- Scope: One endpoint, affects 2% of requests
- Constraints: Must use existing database, no major refactor approved

**PHASE 2: Solutions**
```
SOLUTION 1: Add caching
- Pros: Fast, minimal changes, proven pattern
- Cons: Cache invalidation complexity
- Sustainability: 4/5
- Speed: 1/5 (hours)

SOLUTION 2: Optimize database query
- Pros: Fixes root cause, helps all similar queries
- Cons: Requires testing, may take longer
- Sustainability: 5/5
- Speed: 3/5 (few hours)

SOLUTION 3: Increase server resources
- Pros: Quick fix, immediate improvement
- Cons: Masks real problem, recurring costs
- Sustainability: 2/5
- Speed: 5/5 (minutes)
```

**PHASE 3: Decision**
- Choose SOLUTION 2: Optimize query
- Why: Highest sustainability, fixes root cause
- Risk: Need to verify query plan first

**PHASE 4: Plan**
- Files: `src/queries/endpoint.sql`, tests
- Rollback: Revert to previous query
- Verify: Load test shows <100ms response

---

*This framework enforces systematic decision-making and prevents reactive fixes that accumulate technical debt.*
