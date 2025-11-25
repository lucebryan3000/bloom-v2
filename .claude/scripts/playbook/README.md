# Hybrid Claude + Codex Playbook - Helper Scripts

> **Token-optimized workflow orchestration for Claude Code + Codex CLI**

Achieve **60-80% token savings** by routing tasks to appropriate agents (Claude Haiku, Codex CLI, Claude Sonnet) with these production-ready bash helper scripts.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Core Tools](#core-tools)
  - [codex-parallel.sh](#codex-parallelsh)
  - [task-router.sh](#task-routersh)
- [Validation Tools](#validation-tools)
  - [validate-outputs.sh](#validate-outputssh)
- [Utility Tools](#utility-tools)
  - [json-builder.sh](#json-buildersh)
- [Library Modules](#library-modules)
  - [lib/common.sh](#libcommonsh)
- [Complete Workflow Example](#complete-workflow-example)
- [Integration with Playbook](#integration-with-playbook)
- [Troubleshooting](#troubleshooting)

---

## Overview

These helper scripts implement the **three-phase execution model** from [PLAYBOOK-hybrid-codex.md](../../PLAYBOOK-hybrid-codex.md):

1. **Phase 1 (Sonnet)**: Plan → route tasks → generate TodoWrite list
2. **Phase 2 (Parallel)**: Execute with Haiku agents + Codex CLI simultaneously
3. **Phase 3 (Sonnet)**: Validate → integrate → report completion

**Key Benefits:**
- ⚡ **Parallel Execution**: Run 3-5 Claude agents + 2-4 Codex commands simultaneously
- 🎯 **Smart Routing**: Decision tree routes tasks to optimal agent (Haiku/Codex/Sonnet)
- ✅ **Auto-Validation**: Syntax checking for bash, TypeScript, JavaScript, JSON
- 📊 **Progress Tracking**: Real-time status, JSON reports, colored output
- 🔄 **Edit-First**: Reuses OmniForge utilities instead of duplicating code

---

## Installation

### Prerequisites

**Required:**
- Bash 5.0+ (`bash --version`)
- `jq` for JSON parsing (`sudo apt install jq` or `brew install jq`)
- Codex CLI installed and in PATH (`codex --version`)

**Optional (for validation):**
- `tsc` for TypeScript validation (`npm install -g typescript`)
- `node` for JavaScript validation (Node.js 20+)

### Setup

```bash
# 1. Verify directory structure exists (created by Haiku agents)
ls -la .claude/scripts/playbook/

# Expected structure:
# .claude/scripts/playbook/
# ├── core/
# │   ├── codex-parallel.sh
# │   └── task-router.sh
# ├── validation/
# │   └── validate-outputs.sh
# ├── utils/
# │   └── json-builder.sh
# ├── lib/
# │   └── common.sh
# └── README.md (this file)

# 2. Make scripts executable
chmod +x .claude/scripts/playbook/core/*.sh
chmod +x .claude/scripts/playbook/validation/*.sh
chmod +x .claude/scripts/playbook/utils/*.sh

# 3. Verify dependencies
.claude/scripts/playbook/validation/validate-outputs.sh --help
```

---

## Quick Start

```bash
# 1. Create task CSV
cat > tasks.csv << 'EOF'
description,model,command
"Generate TS types",gpt-5.1-codex-max,"codex exec --model gpt-5.1-codex-max 'Generate TypeScript types for User'"
"Write unit tests",gpt-5.1-codex,"codex exec --model gpt-5.1-codex 'Generate Jest tests for auth module'"
EOF

# 2. Convert to JSON
.claude/scripts/playbook/utils/json-builder.sh tasks.csv > tasks.json

# 3. Execute in parallel
.claude/scripts/playbook/core/codex-parallel.sh tasks.json

# 4. Validate outputs
.claude/scripts/playbook/validation/validate-outputs.sh .claude/logs/playbook/
```

---

## Core Tools

### codex-parallel.sh

**Purpose**: Execute multiple Codex CLI commands in parallel with progress tracking and output collection.

**Location**: `.claude/scripts/playbook/core/codex-parallel.sh`

#### Usage

```bash
./codex-parallel.sh <tasks.json>
./codex-parallel.sh <tasks.json> --no-fail-fast
```

**Flags:**
- `--no-fail-fast`: Continue execution even if tasks fail (default: stop on first failure)

#### Input Format

```json
{
  "tasks": [
    {
      "description": "Task description for logging",
      "model": "gpt-5.1-codex-max",
      "command": "codex exec --model gpt-5.1-codex-max 'Generate...'"
    },
    {
      "description": "Another task",
      "model": "gpt-5.1-codex",
      "command": "codex exec --model gpt-5.1-codex 'Create...'"
    }
  ]
}
```

#### Output

- **Logs**: `.claude/logs/playbook/task-{N}.log` (per-task stdout/stderr)
- **Summary**: `.claude/logs/playbook/parallel-summary.json`
- **Terminal**: Real-time progress with color-coded status

#### Examples

**1. Basic parallel execution:**
```bash
./codex-parallel.sh codex-tasks.json
```

**2. Continue on failure mode:**
```bash
./codex-parallel.sh codex-tasks.json --no-fail-fast
```

**3. With custom timeout:**
```bash
CODEX_TIMEOUT=600 ./codex-parallel.sh tasks.json  # 10-minute timeout
```

---

### task-router.sh

**Purpose**: Route tasks to appropriate agents (Haiku, Codex, Sonnet) using the decision tree from the playbook.

**Location**: `.claude/scripts/playbook/core/task-router.sh`

#### Usage

```bash
./task-router.sh <plan.json>
./task-router.sh <plan.json> --output routed-tasks.json
./task-router.sh --help
```

**Flags:**
- `--output FILE`: Write routed tasks to file instead of stdout
- `--debug`: Enable verbose debug output
- `--help`: Show usage information

#### Input Format

```json
{
  "tasks": [
    {
      "description": "Parse OmniForge bootstrap.conf",
      "context_required": true,
      "complexity": "high"
    },
    {
      "description": "Generate TypeScript types",
      "context_required": false,
      "complexity": "medium",
      "type": "code-gen"
    }
  ]
}
```

**Fields:**
- `description` (required): Task description
- `context_required` (optional): true/false - requires deep project knowledge
- `complexity` (optional): "low", "medium", "high"
- `type` (optional): "code-gen", "docs", "validation", "architectural"

#### Output Format

```json
{
  "tasks": [
    {
      "description": "Parse OmniForge bootstrap.conf",
      "context_required": true,
      "complexity": "high",
      "assigned_agent": "haiku",
      "assigned_model": "claude-haiku",
      "reason": "High complexity with project-specific context required"
    },
    {
      "description": "Generate TypeScript types",
      "context_required": false,
      "complexity": "medium",
      "type": "code-gen",
      "assigned_agent": "codex",
      "assigned_model": "gpt-5.1-codex",
      "reason": "Mechanical code generation without deep context"
    }
  ],
  "summary": {
    "total_tasks": 2,
    "haiku": 1,
    "codex": 1,
    "sonnet": 0
  }
}
```

#### Decision Tree Logic

```
Is task architectural? → Sonnet
  ↓ NO
Requires deep project context? → Haiku
  ↓ NO
Complex code generation? → Codex-Max
  ↓ NO
Standard code/docs? → Codex
  ↓ NO
Simple/mechanical? → Codex-Mini
```

#### Examples

**1. Route tasks to stdout:**
```bash
./task-router.sh plan.json | jq .
```

**2. Route and save:**
```bash
./task-router.sh plan.json --output routed.json
```

**3. Debug mode:**
```bash
DEBUG=1 ./task-router.sh plan.json
```

---

## Validation Tools

### validate-outputs.sh

**Purpose**: Run syntax checks on generated code files to catch errors before integration.

**Location**: `.claude/scripts/playbook/validation/validate-outputs.sh`

#### Usage

```bash
./validate-outputs.sh <directory>
./validate-outputs.sh <file1> <file2> <file3>
./validate-outputs.sh --json-report <directory>
./validate-outputs.sh --verbose <directory>
```

**Flags:**
- `--json-report`: Generate JSON report to `.claude/logs/playbook/validation-report.json`
- `--verbose`: Show detailed debug output
- `--help`: Show usage information

#### Supported File Types

| Extension | Validator | Check Performed |
|-----------|-----------|-----------------|
| `.sh` | `bash -n` | Syntax validation |
| `.ts`, `.tsx` | `tsc --noEmit` | Type checking |
| `.js`, `.jsx` | `node --check` | Syntax validation |
| `.json` | `jq empty` | Format validation |

#### Additional Checks

- **Placeholder Detection**: Fails if `TODO`, `FIXME`, `XXX`, `PLACEHOLDER` found
- **Undefined Variables** (bash): Detects unset variable references
- **Missing Shebangs**: Warns if executable scripts lack `#!/usr/bin/env bash`

#### Output

**Terminal:**
```
INFO: Validating directory: .claude/scripts/playbook/
INFO: Found 5 files to validate

[ ✓ ] codex-parallel.sh - bash syntax OK
[ ✓ ] validate-outputs.sh - bash syntax OK
[ ✗ ] broken-script.sh - bash syntax error: line 42: unexpected EOF
[ ✓ ] types.ts - TypeScript OK
[ ! ] incomplete.sh - contains placeholders: TODO, FIXME

Summary: 3/5 files passed validation
```

**JSON Report** (with `--json-report`):
```json
{
  "timestamp": "2025-01-24T10:30:45Z",
  "total_files": 5,
  "passed": 3,
  "failed": 2,
  "files": [
    {
      "path": "codex-parallel.sh",
      "type": "bash",
      "status": "pass",
      "issues": []
    },
    {
      "path": "broken-script.sh",
      "type": "bash",
      "status": "fail",
      "issues": ["Syntax error at line 42"]
    }
  ]
}
```

#### Examples

**1. Validate directory:**
```bash
./validate-outputs.sh .claude/scripts/playbook/
```

**2. Validate specific files:**
```bash
./validate-outputs.sh script1.sh script2.ts script3.js
```

**3. Generate JSON report for CI/CD:**
```bash
./validate-outputs.sh --json-report src/generated/
if [ $? -ne 0 ]; then
  echo "Validation failed"
  exit 1
fi
```

**4. Verbose output:**
```bash
./validate-outputs.sh --verbose .claude/scripts/
```

---

## Utility Tools

### json-builder.sh

**Purpose**: Build JSON task files from simple formats (CSV, key=value) for use with codex-parallel.sh.

**Location**: `.claude/scripts/playbook/utils/json-builder.sh`

#### Usage

```bash
./json-builder.sh <input.csv>
./json-builder.sh <input.env> --output tasks.json
./json-builder.sh --help
```

**Flags:**
- `-o, --output FILE`: Write JSON to file instead of stdout
- `--verbose`: Show debug output
- `--help`: Show usage information

#### Input Formats

**CSV Format:**
```csv
description,model,command
"Generate TypeScript types",gpt-5.1-codex-max,"codex exec --model gpt-5.1-codex-max 'Generate types for User model'"
"Write unit tests",gpt-5.1-codex,"codex exec --model gpt-5.1-codex 'Generate Jest tests'"
"Format code",gpt-5.1-codex-mini,"codex exec --model gpt-5.1-codex-mini 'Run prettier on all TS files'"
```

**Key=Value Format:**
```bash
TASK_1_DESC="Generate TypeScript types"
TASK_1_MODEL="gpt-5.1-codex-max"
TASK_1_CMD="codex exec --model gpt-5.1-codex-max 'Generate types'"

TASK_2_DESC="Write unit tests"
TASK_2_MODEL="gpt-5.1-codex"
TASK_2_CMD="codex exec --model gpt-5.1-codex 'Generate tests'"
```

**Note:** `model` field is optional and will be omitted from JSON if not provided.

#### Output Format

```json
{
  "tasks": [
    {
      "description": "Generate TypeScript types",
      "model": "gpt-5.1-codex-max",
      "command": "codex exec --model gpt-5.1-codex-max 'Generate types'"
    },
    {
      "description": "Write unit tests",
      "model": "gpt-5.1-codex",
      "command": "codex exec --model gpt-5.1-codex 'Generate tests'"
    }
  ]
}
```

#### Examples

**1. Convert CSV to JSON (stdout):**
```bash
./json-builder.sh tasks.csv > tasks.json
```

**2. Convert key=value to file:**
```bash
./json-builder.sh tasks.env --output codex-tasks.json
```

**3. Pipe directly to codex-parallel:**
```bash
./json-builder.sh tasks.csv | ../core/codex-parallel.sh /dev/stdin
```

**4. Verbose mode:**
```bash
./json-builder.sh --verbose tasks.csv
```

---

## Library Modules

### lib/common.sh

**Purpose**: Master loader for playbook library modules. Sources OmniForge utilities and provides playbook-specific functions.

**Location**: `.claude/scripts/playbook/lib/common.sh`

#### How to Use in Scripts

```bash
#!/usr/bin/env bash
set -euo pipefail

# Source playbook common library
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Now you have access to:
# - OmniForge logging: log_info, log_warn, log_error, log_ok, log_step, log_debug
# - OmniForge validation: require_cmd, require_file, require_dir
# - Playbook functions: verify_playbook_env, get_playbook_script_path, source_playbook_module

# Example usage:
require_cmd "jq" "Install with: sudo apt install jq"
log_info "Starting task execution..."
```

#### Exported Functions

**From OmniForge (via sourcing):**
- `log_info`, `log_warn`, `log_error`, `log_ok`, `log_step`, `log_debug` - Color-coded logging
- `require_cmd`, `require_file`, `require_dir` - Validation helpers

**Playbook-Specific:**
- `verify_playbook_env()` - Validates playbook environment setup
- `get_playbook_script_path(module_name)` - Returns absolute path to playbook module
- `source_playbook_module(module_name)` - Safely sources playbook modules

#### Exported Variables

- `PLAYBOOK_SCRIPTS_DIR` - Root of playbook scripts (`.claude/scripts/playbook/`)
- `PLAYBOOK_PROJECT_ROOT` - Project root directory
- `OMNIFORGE_LIB_DIR` - OmniForge library directory

#### Example

```bash
#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Verify environment
verify_playbook_env || exit 1

# Use OmniForge logging
log_info "Processing tasks..."

# Use OmniForge validation
require_cmd "codex" "Install Codex CLI from https://..."

# Get script path
ROUTER_PATH=$(get_playbook_script_path "core/task-router.sh")
log_debug "Router located at: $ROUTER_PATH"
```

---

## Complete Workflow Example

Here's an end-to-end scenario showing all tools in action:

### Scenario: Generate TypeScript Types + Tests for New Feature

**1. Create Task Definitions (CSV)**

```bash
cat > feature-tasks.csv << 'EOF'
description,model,command
"Generate User type definitions",gpt-5.1-codex-max,"codex exec --model gpt-5.1-codex-max 'Generate TypeScript types for User model with email, name, role. Output to src/types/user.d.ts'"
"Generate Zod validation schemas",gpt-5.1-codex,"codex exec --model gpt-5.1-codex 'Generate Zod schemas for User type. Output to src/lib/validation/user-schema.ts'"
"Generate Jest unit tests",gpt-5.1-codex,"codex exec --model gpt-5.1-codex 'Generate Jest tests for User validation. Output to src/lib/validation/__tests__/user-schema.test.ts'"
"Update documentation",gpt-5.1-codex,"codex exec --model gpt-5.1-codex 'Add User type documentation to docs/API.md'"
EOF
```

**2. Convert to JSON**

```bash
.claude/scripts/playbook/utils/json-builder.sh feature-tasks.csv --output tasks.json
```

**3. Execute in Parallel**

```bash
.claude/scripts/playbook/core/codex-parallel.sh tasks.json
```

**Output:**
```
INFO: Loaded 4 tasks from tasks.json
STEP: Starting parallel execution...

[ 1/4 ] Generate User type definitions (gpt-5.1-codex-max)
[ 2/4 ] Generate Zod validation schemas (gpt-5.1-codex)
[ 3/4 ] Generate Jest unit tests (gpt-5.1-codex)
[ 4/4 ] Update documentation (gpt-5.1-codex)

OK: All 4 tasks completed successfully (100.0% success rate)
OK: Summary report: /home/luce/apps/bloom2/.claude/logs/playbook/parallel-summary.json
```

**4. Validate Generated Files**

```bash
.claude/scripts/playbook/validation/validate-outputs.sh src/
```

**Output:**
```
INFO: Validating directory: src/
INFO: Found 3 files to validate

[ ✓ ] src/types/user.d.ts - TypeScript OK
[ ✓ ] src/lib/validation/user-schema.ts - TypeScript OK
[ ✓ ] src/lib/validation/__tests__/user-schema.test.ts - TypeScript OK

Summary: 3/3 files passed validation (100%)
```

**5. Review Summary Report**

```bash
jq . .claude/logs/playbook/parallel-summary.json
```

```json
{
  "execution_timestamp": "2025-01-24T10:35:12Z",
  "total_tasks": 4,
  "completed": 4,
  "failed": 0,
  "skipped": 0,
  "success_rate_percent": 100.0,
  "tasks": [
    {
      "task_number": 1,
      "description": "Generate User type definitions",
      "model": "gpt-5.1-codex-max",
      "status": "completed",
      "exit_code": 0,
      "duration_seconds": 23,
      "log_file": "/home/luce/apps/bloom2/.claude/logs/playbook/task-1.log"
    }
  ]
}
```

---

## Integration with Playbook

These tools implement the **three-phase workflow** from [PLAYBOOK-hybrid-codex.md](../../PLAYBOOK-hybrid-codex.md):

### Phase 1: Planning (Claude Sonnet)

**Tools Used:**
- `task-router.sh` - Route tasks to agents using decision tree

**Workflow:**
1. Sonnet analyzes user request
2. Breaks down into tasks (TodoWrite)
3. Creates task JSON with context/complexity metadata
4. Runs `task-router.sh` to assign agents
5. Generates execution plan

### Phase 2: Execution (Parallel)

**Tools Used:**
- `codex-parallel.sh` - Execute Codex tasks in parallel
- Claude spawns Haiku agents via Task tool (not covered by these scripts)

**Workflow:**
1. User/Sonnet spawns 3-5 Haiku agents for complex tasks
2. User runs `codex-parallel.sh` with Codex task JSON
3. Both execute simultaneously (parallel work streams)
4. Outputs collected to logs

### Phase 3: Validation (Claude Sonnet)

**Tools Used:**
- `validate-outputs.sh` - Syntax validation
- Manual integration checks by Sonnet

**Workflow:**
1. Sonnet runs `validate-outputs.sh` on generated files
2. Reviews validation report
3. Checks for placeholders, undefined vars, orphaned files
4. Verifies integration across Haiku + Codex outputs
5. Marks TodoWrite tasks complete
6. Reports token usage and prompts for `/clear`

### Tool Relationships

```
┌─────────────────────────────────────────────────────┐
│               Phase 1: PLANNING                      │
│                                                      │
│  User Request → Sonnet → task-router.sh             │
│                    ↓                                 │
│           Routed Task JSON                           │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│           Phase 2: EXECUTION (Parallel)              │
│                                                      │
│  ┌─────────────────┐      ┌──────────────────┐     │
│  │ Haiku Agents    │      │ Codex Tasks      │     │
│  │ (Claude Task    │      │                  │     │
│  │  tool - not     │      │ codex-parallel.sh│     │
│  │  in scripts)    │      │       ↓          │     │
│  └─────────────────┘      │  Logs + Summary  │     │
│                           └──────────────────┘     │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│            Phase 3: VALIDATION                       │
│                                                      │
│  validate-outputs.sh → Syntax Checks                │
│         ↓                                            │
│  Sonnet Review → Integration Checks                 │
│         ↓                                            │
│  TodoWrite Complete → Token Report                  │
└─────────────────────────────────────────────────────┘
```

### When to Use Which Tool

| Situation | Tool | Usage |
|-----------|------|-------|
| Have task CSV/key=value file | `json-builder.sh` | Convert to JSON format |
| Need to assign tasks to agents | `task-router.sh` | Auto-route by decision tree |
| Ready to execute Codex tasks | `codex-parallel.sh` | Parallel execution |
| Verify generated code quality | `validate-outputs.sh` | Syntax + quality checks |
| Writing new playbook script | `lib/common.sh` | Source for utilities |

---

## Troubleshooting

### Common Errors and Solutions

#### 1. `jq: command not found`

**Problem**: JSON parsing tool not installed

**Solution:**
```bash
# Ubuntu/Debian
sudo apt install jq

# macOS
brew install jq

# Verify
jq --version
```

#### 2. `codex: command not found`

**Problem**: Codex CLI not in PATH

**Solution:**
```bash
# Check if installed
which codex

# If not found, install Codex CLI
# (Follow installation instructions from Codex documentation)

# Add to PATH if needed
export PATH="$PATH:/path/to/codex"
```

#### 3. Validation Skips TypeScript Files

**Problem**: `tsc` not installed

**Solution:**
```bash
# Install TypeScript globally
npm install -g typescript

# Verify
tsc --version

# Re-run validation
.claude/scripts/playbook/validation/validate-outputs.sh src/
```

#### 4. `codex-parallel.sh` Tasks Hang

**Problem**: Task timeout or network issues

**Solution:**
```bash
# Increase timeout (default 10 minutes)
CODEX_TIMEOUT=1800 ./codex-parallel.sh tasks.json  # 30 minutes

# Check individual task logs
tail -f .claude/logs/playbook/task-1.log

# Run with --no-fail-fast to see all failures
./codex-parallel.sh tasks.json --no-fail-fast
```

#### 5. Permission Denied Errors

**Problem**: Scripts not executable

**Solution:**
```bash
# Make all scripts executable
chmod +x .claude/scripts/playbook/core/*.sh
chmod +x .claude/scripts/playbook/validation/*.sh
chmod +x .claude/scripts/playbook/utils/*.sh

# Or individually
chmod +x .claude/scripts/playbook/core/codex-parallel.sh
```

#### 6. OmniForge Validation Not Found

**Problem**: `lib/common.sh` can't source OmniForge utilities

**Solution:**
```bash
# Check OmniForge library exists
ls -la _build/omniforge/lib/validation.sh
ls -la _build/omniforge/lib/logging.sh

# If missing, verify OmniForge is installed
ls -la _build/omniforge/

# common.sh will provide minimal stubs if OmniForge unavailable
```

### Debug Mode

Enable detailed debug output for any script:

```bash
# Set DEBUG environment variable
DEBUG=1 ./codex-parallel.sh tasks.json

# Or use --verbose flag (where available)
./validate-outputs.sh --verbose src/

# Or --debug flag
./task-router.sh --debug plan.json
```

### Log File Locations

All playbook scripts write logs to:

```
.claude/logs/playbook/
├── task-1.log                  # codex-parallel.sh per-task logs
├── task-2.log
├── parallel-summary.json       # codex-parallel.sh execution summary
└── validation-report.json      # validate-outputs.sh JSON report
```

**View logs:**
```bash
# List all logs
ls -lh .claude/logs/playbook/

# View specific task log
cat .claude/logs/playbook/task-1.log

# Watch log in real-time
tail -f .claude/logs/playbook/task-3.log

# View summary
jq . .claude/logs/playbook/parallel-summary.json
```

### Getting Help

Each script includes built-in help:

```bash
.claude/scripts/playbook/core/codex-parallel.sh --help
.claude/scripts/playbook/core/task-router.sh --help
.claude/scripts/playbook/validation/validate-outputs.sh --help
.claude/scripts/playbook/utils/json-builder.sh --help
```

For playbook-level questions, see:
- [PLAYBOOK-hybrid-codex.md](../../PLAYBOOK-hybrid-codex.md) - Full playbook documentation
- OmniForge docs: `_build/omniforge/OMNIFORGE.md`

---

## Version History

- **v1.0** (2025-01-24): Initial release
  - 5 production-ready bash helper scripts
  - 2,568 lines of code
  - Full OmniForge integration
  - Comprehensive validation and testing

---

## Contributing

When adding new playbook scripts:

1. Follow OmniForge conventions (`set -euo pipefail`, color logging, guards)
2. Add entry to this README under appropriate section
3. Update [PLAYBOOK-hybrid-codex.md](../../PLAYBOOK-hybrid-codex.md) tool registry
4. Run `validate-outputs.sh` on new scripts before committing
5. Test with real Codex CLI commands
6. Include `--help` flag with usage documentation

---

**Questions?** See [PLAYBOOK-hybrid-codex.md](../../PLAYBOOK-hybrid-codex.md) for the full hybrid workflow documentation.
