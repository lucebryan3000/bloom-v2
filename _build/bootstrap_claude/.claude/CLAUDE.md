# Claude Code Configuration

## Work Planning & Backlog Management

**CRITICAL PRINCIPLE: The backlog is a reference tool, NOT an execution queue.**

### How to Handle Backlog Items

1. **Investigate systematically** using available tools:
   - Search codebase for existing implementations
   - Use grep and glob for pattern discovery
   - Review current state before proposing work

2. **Report findings explicitly**:
   - Show specific evidence (file paths, line numbers)
   - Highlight what's already implemented vs. missing
   - Quantify gaps: "3 integration points incomplete" (not just "needs work")

3. **Ask before planning**:
   - Never assume backlog items should be worked
   - Present findings with recommendations
   - Example: "Found 40% of feature X is done. Should we: A) complete it, B) move to priority backlog, C) defer?"

4. **Create plans explicitly**:
   - Only after user approves should you create GitHub issues or detailed plans
   - Link issues to backlog items with clear scope
   - Document decisions made during investigation

5. **Execute with clarity**:
   - Work only on items with explicit approval
   - Reference the GitHub issue or decision point
   - Update backlog to match what was actually done

### Example Investigation Report

```
🔍 Backlog Investigation: [Feature Name]

CURRENT STATE:
- Component A: 40% implemented (src/components/[file].ts:45-80)
- Component B: 0% (no code found)
- Tests: Exist but cover only partial flow (tests/[file].spec.ts)

BLOCKERS IDENTIFIED:
- Decision needed: [architectural choice]
- Design questions in notes

QUESTIONS FOR YOU:
1. Should we complete this feature?
2. What's the priority vs other work?
3. Should I create a GitHub issue to track this?

This is a reference finding. No work will proceed without your approval.
```

---

## No Fake Numbers

- Always cite actual evidence: "Found 8 test files" not "many test files"
- Use measurements from codebase: grep results, file counts, line numbers
- For performance: Show baseline + measured data, or mark as "theoretical/projected"
- If uncertain, say so: "Approximately 12-15 files" not "12 files"

---

## Code Safety Principles

- Verify before deletion using defensive checks (symlinks, dependencies, active use)
- Reference code with [filename.ts:42](src/filename.ts#L42) format for clarity
- Keep solutions simple and focused—only change what was asked
- Avoid over-engineering: don't add features or configurability beyond requirements
- Trust internal code and framework guarantees; validate only at system boundaries

---

## Claude Code 2.0 Features

- **Extended Thinking**: Enabled for complex reasoning tasks (token usage impact varies)
- **Parallel Task Execution**: Launch multiple Task agents simultaneously for independent work
- **Checkpointing**: Code state auto-saved; rewind with Esc-Esc or `/rewind`
- **Background Operations**: Use `run_in_background: true` in Bash tool for long processes
- **Specialized Agents**: Available for targeted domains (explore, audit, orchestration, etc.)

---

## Tool Usage Policy

- Prefer specialized tools over bash commands (Read for files, Edit for changes, Glob for searches)
- Use the Task tool with appropriate subagent types for complex investigations
- Make independent tool calls in parallel to maximize efficiency
- Use TodoWrite frequently to track progress on multi-step tasks
- Mark todos as completed immediately after finishing each step

---

## Performance & Measurement

When documenting improvements:
- Always show baseline metrics with sources
- Include measured data, not estimates
- Be specific: "<100ms" not "fast"
- For unknown values: "Approximately 12-15 files" not assumed numbers

Example format:
```
| Metric          | Before    | After     | Improvement |
|-----------------|-----------|-----------|------------|
| Response Time   | 500ms     | 50ms      | 90% faster  |
| Error Rate      | 2.3%      | 0%        | Eliminated  |
| Database Queries| 15/req    | 3/req     | 80% fewer   |
```

---

## Code References in Documentation

Use markdown link syntax for clarity:
- For files: [filename.ts](src/filename.ts)
- For specific lines: [filename.ts:42](src/filename.ts#L42)
- For ranges: [filename.ts:42-51](src/filename.ts#L42-L51)
- For folders: [src/utils/](src/utils/)

This makes code locations immediately accessible in your IDE.
