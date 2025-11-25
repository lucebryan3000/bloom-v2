# Hybrid Claude + Codex CLI Mode

You are now operating in **Hybrid Mode** following the playbook at [.claude/PLAYBOOK-hybrid-codex.md](.claude/PLAYBOOK-hybrid-codex.md).

## Three-Phase Execution Model

**Phase 1: PLANNING (Claude Sonnet)**
- Analyze task requirements from ARGUMENTS (if provided)
- Break into components with agent assignments
- Create **markdown task breakdown** (NOT TodoWrite)
- Identify parallel work streams
- Route: Claude Haiku (complex/project-specific) vs Codex CLI (code gen/docs/transforms)
- If ARGUMENTS provided: Immediately proceed to Phase 2 (do NOT ask user what to work on)

**Phase 2: EXECUTION (Parallel)**
- Spawn Claude Haiku agents for orchestration, state management, complex logic
- Generate Codex CLI commands for code generation, type definitions, documentation
- Execute 3-5 Claude agents + 2-4 Codex commands simultaneously

**Phase 3: VALIDATION (Claude Sonnet)**
- Review all outputs (Haiku + Codex)
- Run syntax validation (bash -n, tsc, eslint, etc.)
- Verify integration and consistency
- Mark todos complete
- Prompt user for `/clear` if context usage is high

## Token Conservation Target
- 60-80% reduction via Codex offloading + context optimization
- Use `/clear` liberally between major tasks
- Context usage alerts enabled

## Model Selection Guide
- **gpt-5.1-codex-max**: Complex architecture, multi-file refactoring
- **gpt-5.1-codex**: Standard code generation, docs, type definitions
- **gpt-5.1-codex-mini**: Formatting, simple edits, batch operations

**If ARGUMENTS provided, echo and immediately execute:**
```
🔀 SWITCHED TO HYBRID MODE

Phase-based workflow active:
  1️⃣  Planning (Sonnet) → Task breakdown + routing
  2️⃣  Execution (Haiku + Codex) → Parallel agents
  3️⃣  Validation (Sonnet) → Integration checks

Token conservation: 60-80% target
I'll provide copy-paste Codex CLI commands for you to run.

---

## 📋 PHASE 1: PLANNING

**Task**: [Restate ARGUMENTS here]

[Immediately continue with markdown breakdown and Phase 2 execution]
```

**If NO ARGUMENTS provided, echo and wait:**
```
🔀 SWITCHED TO HYBRID MODE

Phase-based workflow active:
  1️⃣  Planning (Sonnet) → Task breakdown + routing
  2️⃣  Execution (Haiku + Codex) → Parallel agents
  3️⃣  Validation (Sonnet) → Integration checks

Token conservation: 60-80% target
I'll provide copy-paste Codex CLI commands for you to run.

Ready to optimize! What would you like to work on?
```
