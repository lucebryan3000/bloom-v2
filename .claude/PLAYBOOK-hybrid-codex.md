# Hybrid Claude + Codex CLI Playbook

**Purpose**: Optimize token usage by routing tasks to appropriate agents (generic for any project)
**Execution Model**: Sonnet (planning) → Haiku + Codex CLI (parallel execution) → Sonnet (validation)
**Token Savings**: 60-80% (40-60% via Codex offloading, 20-30% via context optimization)
**Scope**: This playbook is project-agnostic - use it for any codebase or task

---

## Workflow Overview

```
┌─────────────────────────────────────────────────────────────┐
│ Phase 1: PLANNING (Claude Sonnet)                          │
│ - Analyze task requirements                                 │
│ - Create task breakdown with agent assignments             │
│ - Generate todo list with TodoWrite tool                   │
│ - Identify parallel work streams                           │
│ - Route tasks: Claude Haiku vs Codex CLI                   │
│ - IDENTIFY EXISTING FILES (edit-first, create only if new) │
│ - Check context usage and recommend /clear if needed       │
│ - AUTO-EXECUTE: Proceed to Phase 2 without user approval   │
│   (ONLY stop if: user input needed OR major error occurs)  │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Phase 2: EXECUTION (Mixed Agents in Parallel)              │
│                                                             │
│  ┌──────────────────────┐    ┌──────────────────────┐     │
│  │ Claude Haiku Agents  │    │ Codex CLI Tasks      │     │
│  │ - Bash orchestration │    │ - Code generation    │     │
│  │ - State management   │    │ - Type definitions   │     │
│  │ - Complex edits      │    │ - Documentation      │     │
│  │ - Config parsing     │    │ - File transforms    │     │
│  └──────────────────────┘    └──────────────────────┘     │
│                                                             │
│  Execute 3-5 Claude agents + 2-4 Codex commands            │
│  Each agent/command works on SEPARATE file (no overlap)    │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Phase 3: VALIDATION (Claude Sonnet)                        │
│ - Review all outputs (Haiku + Codex)                       │
│ - Syntax validation (bash -n, eslint, tsc, etc.)          │
│ - Consistency checks across changes                        │
│ - Integration verification                                 │
│ - Detect: placeholders, TODOs, undefined vars, orphans     │
│ - Update todo list to completed                            │
│ - Prompt user: "Large task completed. Run /clear? (Y/n)"  │
└─────────────────────────────────────────────────────────────┘
```

---

## Context Management & Session Hygiene

### When to Use /clear

**CRITICAL for token conservation**: Use `/clear` liberally to reset context between major tasks.

**Always /clear after:**
- ✅ Completing a major feature or refactoring
- ✅ Finishing all tasks in a todo list
- ✅ Switching to a different part of the codebase
- ✅ Resolving a complex bug or issue
- ✅ After validation phase of multi-agent workflow

**Prompt at end of Phase 3:**
```
🎯 Task completed! All todos marked done.

Context usage: ~40k tokens used this session.
Would you like to /clear the conversation history? (Y/n)

Benefits: Fresh context, faster responses, more sessions per day
Note: This playbook remains available after /clear
```

**User configuration updated:**
- ✅ `DISABLE_COST_WARNINGS: "0"` - Now showing token usage alerts
- ⚠️ `/compact` auto-trigger at 95% (not configurable - must use manually at 60% if desired)

---

## Task Delegation Decision Tree

```
Is the task project-specific requiring deep context?
  YES → Claude Haiku
  NO  → Continue

Is it mechanical code generation or transformation?
  YES → Codex CLI (gpt-5.1-codex-max or gpt-5.1-codex)
  NO  → Continue

Is it documentation or markdown generation?
  YES → Codex CLI (gpt-5.1-codex)
  NO  → Continue

Is it simple file operations or formatting?
  YES → Codex CLI (gpt-5.1-codex-mini)
  NO  → Claude Haiku (default)
```

---

## TodoWrite Task List Format

**CRITICAL**: All todo lists MUST follow this format to enable proper parallel execution:

### Format Template

```
[] Model: Action description (execution mode)
```

**Components:**
- **Model**: `Bash`, `Sonnet`, `Haiku`, or `Codex` (which agent performs the task)
- **Action**: Clear, imperative verb + object (what to do)
- **Execution mode**: `(parallel)` or `(sequential)`

### Execution Modes

**Sequential**: Tasks that depend on previous results or must run in order
- Information gathering (Bash)
- Planning and orchestration (Sonnet)
- Validation and review (Sonnet)
- Documentation generation (Codex) - requires all code complete
- Testing - requires code complete

**Parallel**: Independent tasks that can run simultaneously
- Multiple script implementations (Haiku agents on different files)
- Multiple file edits (each Haiku agent owns ONE file)
- NEVER assign same file to multiple parallel agents

### Example Todo List

```
[] Bash: Check if .claude/scripts/playbook/ exists (sequential)
[] Bash: Search for existing helper scripts to reuse (sequential)
[] Sonnet: Create implementation plan with edit-vs-create strategy (sequential)
[] Sonnet: Update TodoWrite list with Phase 1 MVP tasks (sequential)
[] Haiku: Write .claude/scripts/playbook/core/codex-parallel.sh (parallel)
[] Haiku: Write .claude/scripts/playbook/validation/validate-outputs.sh (parallel)
[] Haiku: Write .claude/scripts/playbook/utils/json-builder.sh (parallel)
[] Haiku: Edit _build/omniforge/lib/common.sh - add logging functions (parallel)
[] Codex: Generate comprehensive README for playbook scripts (sequential)
[] Bash: Test codex-parallel.sh with sample JSON (sequential)
[] Bash: Validate no placeholders/TODOs in all scripts (sequential)
[] Sonnet: Review outputs, verify integration, mark complete (sequential)
```

### Rules for Parallel Execution

1. **One agent, one file**: Never assign multiple agents to the same file
2. **No dependencies**: Parallel tasks must be independent
3. **Separate outputs**: Each agent produces distinct artifacts
4. **No shared state**: Agents don't modify common configuration during execution

### Anti-Patterns to Avoid

❌ **Bad**: Two agents editing same file
```
[] Haiku: Add function A to utils.sh (parallel)
[] Haiku: Add function B to utils.sh (parallel)  # CONFLICT!
```

✅ **Good**: Single agent handles file, or split into separate files
```
[] Haiku: Edit utils.sh - add functions A and B (parallel)
# OR
[] Haiku: Create utils-feature-a.sh (parallel)
[] Haiku: Create utils-feature-b.sh (parallel)
```

---

## Example Task Breakdown

### Scenario 1: Add TypeScript support to configuration system

**Tasks:**

```yaml
- task: "Parse configuration file and extract all sections"
  agent: haiku
  reason: "Complex parsing, project-specific knowledge required"
  duration: "2-3 min"

- task: "Generate TypeScript type definitions from parsed config"
  agent: codex
  model: gpt-5.1-codex-max
  command: |
    codex exec -m gpt-5.1-codex-max \
      --add-file config/app.conf \
      "Generate TypeScript types for all configuration sections. \
      Create src/types/app-config.d.ts with interfaces. \
      Include JSDoc comments for each field."
  reason: "Pure code generation"
  duration: "1-2 min"

- task: "Create validation functions for config types"
  agent: codex
  model: gpt-5.1-codex
  command: |
    codex exec -m gpt-5.1-codex \
      --add-file src/types/app-config.d.ts \
      "Generate Zod validation schemas for all interfaces. \
      Create src/lib/validation/config-schema.ts with runtime validation."
  reason: "Standard TS/Zod code generation"
  duration: "1-2 min"

- task: "Update documentation with TypeScript integration"
  agent: codex
  model: gpt-5.1-codex
  command: |
    codex exec -m gpt-5.1-codex \
      --add-file docs/README.md \
      --add-file src/types/app-config.d.ts \
      "Add new section titled 'TypeScript Integration'. \
      Document: how to import types, type safety benefits, validation examples."
  reason: "Documentation writing with context injection"
  duration: "1-2 min"

- task: "Integrate types into main app for autocomplete"
  agent: haiku
  reason: "Requires understanding app architecture and orchestration"
  duration: "2-3 min"

- task: "Validate TypeScript compilation and Zod schemas"
  agent: sonnet
  reason: "Critical validation requiring multi-file consistency checks"
  duration: "1 min"
```

**Total Duration**: ~8-12 minutes (vs 15-20 minutes with Claude-only workflow)

---

### Scenario 2: Refactor API endpoints to use new auth system

**Tasks:**

```yaml
- task: "Analyze current auth middleware and identify dependencies"
  agent: haiku
  reason: "Requires deep understanding of existing architecture"
  duration: "3-4 min"

- task: "Generate new auth middleware with JWT support"
  agent: codex
  model: gpt-5.1-codex-max
  command: |
    codex exec -m gpt-5.1-codex-max \
      --add-file src/middleware/auth-old.ts \
      --add-file src/types/user.d.ts \
      "Generate new JWT auth middleware following the pattern in auth-old.ts. \
      Add: token refresh, role-based access, rate limiting. \
      Output to src/middleware/auth-jwt.ts"
  reason: "Complex code generation with context"
  duration: "2-3 min"

- task: "Update all API routes to use new middleware"
  agent: codex
  model: gpt-5.1-codex
  command: |
    codex exec -m gpt-5.1-codex --full-auto \
      --add-dir src/pages/api/ \
      --add-file src/middleware/auth-jwt.ts \
      "Replace old auth middleware imports with new auth-jwt in all API routes"
  reason: "Batch operation with pattern replacement"
  duration: "1-2 min"

- task: "Generate unit tests for new auth middleware"
  agent: codex
  model: gpt-5.1-codex
  command: |
    codex exec -m gpt-5.1-codex \
      --add-file src/middleware/auth-jwt.ts \
      "Generate Jest tests for auth-jwt middleware. \
      Cover: valid tokens, expired tokens, invalid signatures, role checks. \
      Output to src/middleware/__tests__/auth-jwt.test.ts"
  reason: "Test generation"
  duration: "2 min"

- task: "Run tests and validate no breaking changes"
  agent: sonnet
  reason: "Critical validation with test analysis"
  duration: "2 min"
```

**Total Duration**: ~10-13 minutes

---

## Codex Prompt Engineering Guide

**CRITICAL**: Codex quality depends on prompt precision. Follow these rules for 90%+ success rate.

### **Anatomy of a High-Quality Codex Prompt**

```bash
codex exec -m [MODEL] \
  [CONTEXT_FLAGS] \
  "[ACTION] [REQUIREMENTS]. [CONSTRAINTS]. [OUTPUT_SPEC]."
```

**Components:**
1. **ACTION**: Imperative verb (Generate, Convert, Extract, Refactor, Update)
2. **REQUIREMENTS**: What must be included/preserved (Use X library, Preserve Y structure)
3. **CONSTRAINTS**: What to avoid/exclude (Do NOT add extra files, IMPORTANT: exact structure)
4. **OUTPUT_SPEC**: Exact output path and format (Output to path/file.ext)

### **Codex Prompt Quality Checklist**

✅ **Good prompts have:**
- Single, clear objective
- Specific output path (`Output to exact/path.ts`)
- Framework/library versions specified
- File structure requirements
- Example format or template reference

❌ **Bad prompts are:**
- Vague ("make it better", "fix the code")
- Missing output path (Codex will guess or create unexpected files)
- Ambiguous constraints ("add error handling" → which errors? where?)
- Multiple conflicting objectives

### **Examples: Good vs Bad Prompts**

#### **❌ BAD**: Vague, no output path, ambiguous
```bash
codex exec -m gpt-5.1-codex \
  --add-file src/utils.ts \
  "Add some helper functions for validation"
```
**Problems**: "some" is vague, "validation" is broad, no output path

#### **✅ GOOD**: Specific, constrained, clear output
```bash
codex exec -m gpt-5.1-codex \
  --add-file src/types/user.d.ts \
  "Generate Zod validation schema for User type. \
  Include: email (email format), age (min 18), role (enum). \
  Do NOT add extra fields. \
  Output to src/lib/validation/user-schema.ts"
```
**Why it works**: Specific fields, constraints, exact output path

---

#### **❌ BAD**: Multiple objectives, no structure
```bash
codex exec -m gpt-5.1-codex-max \
  --add-dir src/ \
  "Refactor the authentication system and add OAuth support"
```
**Problems**: Two separate tasks (refactor + add feature), no guidance on structure

#### **✅ GOOD**: Single objective, architectural constraints
```bash
codex exec -m gpt-5.1-codex-max \
  --add-file src/auth/session.ts \
  --add-file src/types/auth.d.ts \
  "Generate OAuth2 provider class extending BaseAuthProvider. \
  Must implement: authorize(), callback(), refresh(). \
  Use Fetch API (no axios). Follow existing BaseAuthProvider pattern. \
  Output to src/auth/providers/oauth-provider.ts"
```
**Why it works**: Single task, inheritance specified, API choice clear, pattern reference

---

#### **❌ BAD**: Missing context, assuming Codex knows project
```bash
codex exec -m gpt-5.1-codex \
  "Add tests for the API endpoints"
```
**Problems**: No context files, which endpoints? Which test framework?

#### **✅ GOOD**: Context injected, framework specified
```bash
codex exec -m gpt-5.1-codex \
  --add-file src/pages/api/users.ts \
  --add-file src/types/api.d.ts \
  "Generate Jest tests for /api/users endpoint. \
  Cover: GET (success, 404), POST (validation, duplicate), DELETE (auth). \
  Use supertest for HTTP assertions. \
  Output to src/pages/api/__tests__/users.test.ts"
```
**Why it works**: Context files, framework (Jest + supertest), scenarios enumerated

---

### **Advanced Techniques**

#### **1. Use HEREDOC for Complex Structures**
```bash
codex exec -m gpt-5.1-codex-max \
  --add-file src/types/config.d.ts \
  "$(cat <<'EOF'
Generate configuration validator using this exact structure:

export class ConfigValidator {
  validate(config: AppConfig): ValidationResult
  validateSection(section: string, data: unknown): boolean
  getErrors(): string[]
}

Requirements:
- Use Zod for runtime validation
- Return typed errors (not strings)
- Support nested config sections
- Add JSDoc for all public methods

Output to src/lib/config-validator.ts
EOF
)"
```

#### **2. Reference Existing Patterns**
```bash
codex exec -m gpt-5.1-codex \
  --add-file _build/omniforge/lib/logging.sh \
  --add-file _build/omniforge/lib/validation.sh \
  "Generate new playbook helper script following EXACT patterns from logging.sh and validation.sh. \
  Must include: double-sourcing guard, strict mode (set -euo pipefail), color-coded logging. \
  Function naming: playbook_[action]_[noun]. \
  Output to .claude/scripts/playbook/lib/helpers.sh"
```

#### **3. Specify Version Constraints**
```bash
codex exec -m gpt-5.1-codex \
  "Generate Next.js 14 App Router API route using route handlers (NOT pages router). \
  Must use: export async function GET/POST, NextRequest, NextResponse. \
  TypeScript 5.3+ features allowed. \
  Output to app/api/health/route.ts"
```

---

## Codex CLI Command Patterns

### **Pattern 1: Code Generation**

```bash
# Generate new code with context
codex exec -m gpt-5.1-codex-max \
  --add-file path/to/context.ts \
  --add-file path/to/types.d.ts \
  "Generate [description]. Use [framework/library]. Output to [path]."

# Example:
codex exec -m gpt-5.1-codex-max \
  --add-file src/types/phase.d.ts \
  "Generate Phase orchestrator class implementing PhaseInterface. \
  Must handle resume, rollback, and parallel execution. \
  Output to src/lib/phase-orchestrator.ts"
```

### **Pattern 2: File Transformations**

```bash
# Convert format
codex exec -m gpt-5.1-codex \
  --add-file input.conf \
  "Convert [input format] to [output format]. Preserve [requirements]. Output to [path]."

# Example:
codex exec -m gpt-5.1-codex \
  --add-file _build/omniforge/bootstrap.conf \
  "Convert to JSON. Preserve all sections as nested objects. \
  Output to _build/omniforge/bootstrap.json"
```

### **Pattern 3: Documentation**

```bash
# Generate docs from code
codex exec -m gpt-5.1-codex \
  --add-dir path/to/code/ \
  "Generate [doc type] for all [files/functions]. Include [requirements]."

# Example:
codex exec -m gpt-5.1-codex \
  --add-dir _build/omniforge/lib/ \
  "Generate API reference for all bash functions. \
  Group by file. Include parameters, return values, examples. \
  Output markdown to _build/omniforge/API-REFERENCE.md"
```

### **Pattern 4: Batch Operations**

```bash
# Automated refactoring
codex exec -m gpt-5.1-codex-mini --full-auto \
  --add-dir path/to/code/ \
  "[Simple operation] on all [file pattern]."

# Example:
codex exec -m gpt-5.1-codex-mini --full-auto \
  --add-dir src/components/ \
  "Add 'use client' directive to all .tsx files that use useState or useEffect"
```

### **Pattern 5: Information Extraction**

```bash
# Extract and analyze
codex exec -m gpt-5.1-codex \
  --add-file path/to/file \
  "Extract [information]. Format as [structure]."

# Example:
codex exec -m gpt-5.1-codex \
  --add-file _build/omniforge/OMNIFORGE.md \
  "Extract all TODO items. Create JSON array with: section, description, priority. \
  Output to _build/omniforge/todos.json"
```

---

## Model Selection Guide

| Task Complexity | Model | Use Cases | Token Cost |
|----------------|-------|-----------|------------|
| **High** | gpt-5.1-codex-max | Complex architecture, multi-file refactoring, advanced algorithms | High |
| **Medium** | gpt-5.1-codex | Standard code generation, docs, type definitions | Medium |
| **Low** | gpt-5.1-codex-mini | Formatting, simple edits, batch operations | Low |

**Rule of Thumb:**
- Start with `gpt-5.1-codex` (default)
- Upgrade to `gpt-5.1-codex-max` if task requires deep reasoning or context
- Downgrade to `gpt-5.1-codex-mini` for mechanical operations

---

## Integration with Claude Code Workflow

### **Option 1: Manual Execution (Simplest)**

1. Claude Sonnet creates task breakdown with Codex commands
2. User copies and runs Codex commands in terminal
3. User reports results back to Claude
4. Claude Sonnet validates and integrates

**Pros**: No automation needed, full control
**Cons**: Manual handoff, slower

### **Option 2: Shell Script Wrapper**

Create [_build/omniforge/codex-runner.sh](_build/omniforge/codex-runner.sh):

```bash
#!/usr/bin/env bash
# Codex CLI task runner for parallel execution

set -euo pipefail

TASKS_FILE="${1:-codex-tasks.json}"

# Read JSON task list
jq -c '.tasks[]' "$TASKS_FILE" | while read -r task; do
    cmd=$(echo "$task" | jq -r '.command')
    desc=$(echo "$task" | jq -r '.description')

    echo "Running: $desc"
    eval "$cmd" || {
        echo "ERROR: Task failed: $desc"
        exit 1
    }
    echo "✓ Completed: $desc"
done
```

Claude generates [codex-tasks.json](codex-tasks.json):

```json
{
  "tasks": [
    {
      "description": "Generate TypeScript types",
      "command": "codex exec -m gpt-5.1-codex-max --add-file _build/omniforge/bootstrap.conf \"Generate TS types...\""
    },
    {
      "description": "Generate validation schemas",
      "command": "codex exec -m gpt-5.1-codex --add-file src/types/omniforge-config.d.ts \"Generate Zod schemas...\""
    }
  ]
}
```

User runs: `bash _build/omniforge/codex-runner.sh`

**Pros**: Parallel execution, reproducible
**Cons**: Requires JSON generation step

### **Option 3: Interactive Approval (Recommended)**

Claude Sonnet outputs commands like:

```markdown
## Codex Tasks Ready for Execution

Run these commands in your terminal:

1. **Generate TypeScript types** (~1 min)
   ```bash
   codex exec -m gpt-5.1-codex-max \
     --add-file _build/omniforge/bootstrap.conf \
     "Generate TypeScript types for all config sections. Output to src/types/omniforge-config.d.ts"
   ```

2. **Generate validation schemas** (~1 min)
   ```bash
   codex exec -m gpt-5.1-codex \
     --add-file src/types/omniforge-config.d.ts \
     "Generate Zod schemas. Output to src/lib/validation/config-schema.ts"
   ```

3. **Update documentation** (~1 min)
   ```bash
   codex exec -m gpt-5.1-codex \
     --add-file _build/omniforge/OMNIFORGE.md \
     "Add TypeScript Integration section after Architecture"
   ```

Once complete, paste outputs or type "done" and I'll validate.
```

**Pros**: User approval, easy to understand, copy-paste friendly
**Cons**: Sequential execution (can run in parallel manually)

---

## Token Conservation Best Practices

### **1. Edit-First Principle (CRITICAL)**

**ALWAYS prioritize editing existing files over creating new ones:**

✅ **Before creating any file:**
1. Use Bash/Grep/Glob to search for existing files with similar functionality
2. Check for partial implementations or templates in the codebase
3. Identify files that can be extended vs duplicated
4. Document in todo list: `[] Haiku: Edit existing-file.sh (add feature X)` NOT `[] Haiku: Create new-file.sh`

❌ **Common mistakes to avoid:**
- Creating `new-logger.sh` when `lib/logging.sh` exists
- Writing `validate-v2.sh` instead of updating `validate.sh`
- Generating orphaned files that duplicate existing utilities
- Building parallel implementations that need manual merging later

**TodoWrite Format for File Operations:**
```
[] Bash: Search for existing validation utilities (sequential)
[] Sonnet: Determine edit vs create strategy for each file (sequential)
[] Haiku: Edit lib/common.sh - add JSON parsing functions (parallel)
[] Haiku: Create core/new-feature.sh - no existing equivalent found (parallel)
[] Codex: Update documentation for modified files (sequential)
```

### **2. Use Codex CLI for These Tasks**

✅ **Do use Codex:**
- TypeScript type generation
- React component scaffolding
- Documentation writing (markdown, JSDoc)
- File format conversions (JSON ↔ YAML ↔ TOML)
- Simple refactoring (rename variables, extract functions)
- Test generation (unit tests, integration tests)
- Code formatting and linting fixes

❌ **Don't use Codex:**
- OmniForge state management (.omniforge_state)
- Bootstrap.conf parsing and modification
- Phase orchestration logic
- Complex bash script refactoring
- Multi-file consistency checks requiring deep context

### **3. Optimize Claude Context**

- Use `/clear` between major tasks
- Explicitly specify files to read (don't auto-discover)
- Create task-specific CLAUDE.md files in [_build/omniforge/](_build/omniforge/)
- Use subagents for isolated subtasks

### **4. Model Selection Strategy**

```
Task requires architectural decisions? → Claude Sonnet
  ↓ NO
Task requires OmniForge domain knowledge? → Claude Haiku
  ↓ NO
Task involves complex code generation? → Codex max
  ↓ NO
Task is standard code/docs? → Codex default
  ↓ NO
Task is simple/mechanical? → Codex mini
```

---

## Playbook Helper Tools Registry

**Purpose**: Quick reference for all helper scripts created by this playbook.

### **Tool Discovery Methods**

**Option 1: Directory Reference (Recommended for Speed)**
```bash
# List all available tools
ls -1 .claude/scripts/playbook/*/*.sh

# Show tool categories
ls -d .claude/scripts/playbook/*/

# Find specific tool type
ls .claude/scripts/playbook/core/
```

**Option 2: Inline Registry (Recommended for Context)**

Maintain this list in the playbook for Claude to reference without filesystem queries.

### **Available Helper Scripts**

#### **Core Tools** (`.claude/scripts/playbook/core/`)

| Script | Purpose | Usage | Model |
|--------|---------|-------|-------|
| `codex-parallel.sh` | Execute multiple Codex commands in parallel | `./codex-parallel.sh tasks.json` | Bash wrapper |
| `task-router.sh` | Route tasks to appropriate agents using decision tree | `./task-router.sh plan.json` | Bash + decision logic |

#### **Validation Tools** (`.claude/scripts/playbook/validation/`)

| Script | Purpose | Usage | Model |
|--------|---------|-------|-------|
| `validate-outputs.sh` | Run syntax checks on generated code (bash -n, tsc, eslint) | `./validate-outputs.sh <directory>` | Bash + validators |
| `consistency-checker.sh` | Verify multi-file consistency (imports, types, refs) | `./consistency-checker.sh <files...>` | Bash + parsing |

#### **Utility Tools** (`.claude/scripts/playbook/utils/`)

| Script | Purpose | Usage | Model |
|--------|---------|-------|-------|
| `json-builder.sh` | Build JSON task files from CSV/YAML/key=value | `./json-builder.sh input.csv > tasks.json` | Bash + jq |
| `output-collector.sh` | Aggregate outputs from parallel tasks | `./output-collector.sh <task_dir>` | Bash + jq |
| `model-selector.sh` | Recommend Codex model based on task complexity | `./model-selector.sh "Generate TS types..."` | Bash heuristics |

#### **Session Tools** (`.claude/scripts/playbook/session/`)

| Script | Purpose | Usage | Model |
|--------|---------|-------|-------|
| `context-usage.sh` | Estimate token usage and recommend /clear | `./context-usage.sh` | Bash + estimation |
| `session-checkpoint.sh` | Save session state before /clear | `./session-checkpoint.sh save\|restore` | Bash + JSON |

#### **Library Modules** (`.claude/scripts/playbook/lib/`)

| Script | Purpose | Exports | Sourced By |
|--------|---------|---------|------------|
| `common.sh` | Master loader for all playbook libraries | All playbook functions | All playbook scripts |
| `logging.sh` | Color-coded logging (info, warn, error, debug) | `plog_*` functions | common.sh |
| `validators.sh` | Input validation helpers | `prequire_*` functions | common.sh |

### **Usage in Hybrid Workflow**

**Phase 1 (Sonnet Planning):**
```bash
# Reference this registry to select appropriate tools
# Example: "I need to run 4 Codex commands in parallel → use codex-parallel.sh"
```

**Phase 2 (Execution):**
```bash
# User runs the tools selected in Phase 1
./claude/scripts/playbook/core/codex-parallel.sh codex-tasks.json
```

**Phase 3 (Sonnet Validation):**
```bash
# Sonnet uses validation tools to verify outputs
./.claude/scripts/playbook/validation/validate-outputs.sh .claude/scripts/playbook/
```

### **Maintenance Strategy**

**When adding new tools:**
1. Create script in appropriate category directory
2. Update this registry table with: name, purpose, usage, model
3. Update `lib/common.sh` if the tool exports reusable functions
4. Run `validate-outputs.sh` on the new script before committing

**When to use directory discovery vs inline registry:**
- **Use `ls` discovery**: When you need real-time list (after updates, unsure of install state)
- **Use inline registry**: When Claude is planning (Phase 1) and needs quick reference without tool calls

---

## Example Session: Add Logging Framework

### **Phase 1: Planning (Claude Sonnet)**

```markdown
I'll break this into 5 tasks:

**Claude Haiku Tasks:**
1. Analyze existing logging implementation to understand current patterns

**Codex CLI Tasks:**
2. Generate TypeScript logger class with Winston integration
3. Generate log rotation config
4. Update project documentation with logging guide

**Claude Sonnet Task:**
5. Validate integration and consistency
```

### **Phase 2: Execution (Parallel)**

**Claude spawns Haiku agent:**
```
Task 1: Read and analyze src/lib/logger.ts (existing)
Report: current logging patterns, output formats, configuration
```

**User runs Codex commands:**
```bash
# Task 2
codex exec -m gpt-5.1-codex-max \
  "Generate Winston logger for Node.js app. \
  Support: console, file rotation, JSON format, log levels (debug/info/warn/error). \
  Output to src/lib/logger-winston.ts"

# Task 3
codex exec -m gpt-5.1-codex \
  "Generate Winston log rotation config. \
  Max file: 10MB, max files: 5, daily rotation. \
  Output to src/config/logger.config.ts"

# Task 4
codex exec -m gpt-5.1-codex \
  --add-file docs/README.md \
  --add-file src/lib/logger-winston.ts \
  "Add Logging Framework section to README.md. \
  Include: setup, usage examples, configuration, log levels"
```

### **Phase 3: Validation (Claude Sonnet)**

```bash
# Claude runs validation
tsc --noEmit src/lib/logger-winston.ts
eslint src/lib/logger-winston.ts
npm test src/lib/__tests__/logger.test.ts
```

Claude reviews outputs, checks consistency, marks todos complete.

**Completion prompt:**
```
🎯 Task completed! Logging framework integrated successfully.

Context usage: ~35k tokens used this session.
Would you like to /clear the conversation history? (Y/n)
```

---

## Success Metrics

| Metric | Before (Claude-only) | After (Hybrid) | Improvement |
|--------|---------------------|----------------|-------------|
| **Token usage per session** | 150k-180k | 60k-90k | 60% reduction |
| **Execution time** | 15-20 min | 8-12 min | 40% faster |
| **Sessions per day limit** | 3-4 | 8-10 | 2.5x more |
| **Code generation quality** | High | High | Same |

---

## Troubleshooting

### **Issue**: Codex output doesn't match expected format

**Solution**: Add more specific instructions in prompt:
```bash
codex exec -m gpt-5.1-codex \
  "Generate [output]. IMPORTANT: Use exactly this structure: [example]. \
  Do not add extra files. Output only to [path]."
```

### **Issue**: Codex lacks project context

**Solution**: Use `--add-file` or `--add-dir` to inject context:
```bash
codex exec -m gpt-5.1-codex-max \
  --add-file src/types/phase.d.ts \
  --add-file _build/omniforge/lib/sequencer.sh \
  "Generate Phase implementation following these patterns..."
```

### **Issue**: Task requires both Claude and Codex outputs

**Solution**: Use Claude for core logic, Codex for boilerplate:
```
1. Claude Haiku: Extract phase metadata from bootstrap.conf → JSON
2. Codex: Generate TypeScript types from JSON
3. Claude Sonnet: Integrate types into orchestrator
```

---

## Version History

- **v1.0** (2025-11-24): Initial hybrid workflow with Codex CLI integration
  - Three-tier architecture (Sonnet → Haiku + Codex → Sonnet)
  - Task delegation decision tree
  - Codex CLI command patterns
  - Model selection guide
  - Token conservation best practices

---

## Related Documentation

- [CLAUDE.md](CLAUDE.md) - Project-specific Claude instructions
- [../_build/omniforge/OMNIFORGE.md](../_build/omniforge/OMNIFORGE.md) - OmniForge comprehensive docs
- [../_build/omniforge/bootstrap.conf](../_build/omniforge/bootstrap.conf) - Configuration reference
- Codex CLI docs: Run `codex --help` for command reference
- [archive/PLAYBOOK-documentation-update.md](archive/PLAYBOOK-documentation-update.md) - Original multi-agent workflow (archived)
