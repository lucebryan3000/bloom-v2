# Bootstrap Script Orchestrator Specification

## System Overview

Build a **master orchestrator** (`orchestrate.sh`) that manages 35 bootstrap scripts for initializing a Next.js 15 + PostgreSQL + AI application stack. The orchestrator provides interactive menus, automation modes, dry-run capabilities, LLM handoff breakpoints, and centralized logging.

---

## 1. Core Architecture

### 1.1 File Structure

```
_build/bootstrap_scripts/
├── orchestrate.sh                 # Master orchestrator (this spec)
├── lib/
│   ├── common.sh                  # Shared functions, colors, logging
│   ├── prompts.sh                 # Interactive prompt utilities
│   ├── validators.sh              # Input validation functions
│   └── state.sh                   # State management (checkpoints, resume)
├── config/
│   ├── defaults.conf              # Default configuration values
│   ├── phases.conf                # Phase definitions and dependencies
│   └── breakpoints.conf           # LLM handoff breakpoint definitions
├── logs/
│   └── run_<timestamp>.log        # Per-run centralized log files
├── state/
│   └── .checkpoint                # Resume state for interrupted runs
├── phases/
│   ├── 00-foundation/
│   │   ├── 01-init-nextjs15.sh
│   │   ├── 02-init-typescript.sh
│   │   ├── 03-init-package-engines.sh
│   │   └── 04-init-directory-structure.sh
│   ├── 01-docker/
│   │   ├── 05-docker-multistage.sh
│   │   ├── 06-docker-compose-pg.sh
│   │   └── 07-docker-pnpm-cache.sh
│   ├── 02-database/
│   │   ├── 08-drizzle-setup.sh
│   │   ├── 09-drizzle-schema-base.sh
│   │   ├── 10-drizzle-migrations.sh
│   │   └── 11-db-client-index.sh
│   ├── 03-security/
│   │   ├── 12-env-validation.sh
│   │   ├── 13-zod-schemas-base.sh
│   │   ├── 14-rate-limiter.sh
│   │   └── 15-server-action-template.sh
│   ├── 04-auth/
│   │   ├── 16-authjs-v5-setup.sh
│   │   └── 17-auth-routes.sh
│   ├── 05-ai/
│   │   ├── 18-vercel-ai-setup.sh
│   │   ├── 19-prompts-structure.sh
│   │   └── 20-chat-feature-scaffold.sh
│   ├── 06-state/
│   │   ├── 21-zustand-setup.sh
│   │   └── 22-session-state-lib.sh
│   ├── 07-jobs/
│   │   ├── 23-pgboss-setup.sh
│   │   └── 24-job-worker-template.sh
│   ├── 08-observability/
│   │   ├── 25-pino-logger.sh
│   │   └── 26-pino-pretty-dev.sh
│   ├── 09-ui/
│   │   ├── 27-shadcn-init.sh
│   │   ├── 28-react-to-print.sh
│   │   └── 29-components-structure.sh
│   ├── 10-testing/
│   │   ├── 30-vitest-setup.sh
│   │   ├── 31-playwright-setup.sh
│   │   └── 32-test-directory.sh
│   └── 11-quality/
│       ├── 33-eslint-prettier.sh
│       ├── 34-husky-lintstaged.sh
│       └── 35-ts-strict-mode.sh
└── templates/
    └── (template files referenced by scripts)
```

---

## 2. Orchestrator Modes

### 2.1 Mode Definitions

| Mode | Flag | Description |
|------|------|-------------|
| **Interactive** | (default) | Menu-driven, prompts for each decision |
| **Automated** | `--auto` | Run all scripts with defaults, stop at breakpoints |
| **Dry Run** | `--dry-run` | Show what would execute without making changes |
| **Phase Mode** | `--phase <n>` | Run specific phase only |
| **Script Mode** | `--script <n>` | Run specific script only |
| **Resume** | `--resume` | Continue from last checkpoint |
| **Headless** | `--headless` | No prompts, use config file only |

### 2.2 Command Syntax

```bash
./orchestrate.sh [MODE] [OPTIONS]

# Examples:
./orchestrate.sh                           # Interactive mode
./orchestrate.sh --auto                    # Automated with breakpoints
./orchestrate.sh --dry-run                 # Preview all actions
./orchestrate.sh --phase 02-database       # Run database phase only
./orchestrate.sh --script 08              # Run script #08 only
./orchestrate.sh --resume                  # Continue interrupted run
./orchestrate.sh --auto --skip-breakpoints # Full automation (no stops)
./orchestrate.sh --help                    # Show help
./orchestrate.sh --list                    # List all phases/scripts
```

---

## 3. Menu System

### 3.1 Main Menu

```
╔══════════════════════════════════════════════════════════════════╗
║           BLOOM2 BOOTSTRAP ORCHESTRATOR v1.0                     ║
║           Next.js 15 + PostgreSQL + AI Stack                     ║
╠══════════════════════════════════════════════════════════════════╣
║  Project: bloom2                                                 ║
║  Target:  /home/user/bloom-v2                                    ║
║  Status:  Fresh install (no checkpoint found)                    ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  [1] 🚀 Run All (Automated with Breakpoints)                     ║
║  [2] 📋 Run Phase by Phase (Interactive)                         ║
║  [3] 🔧 Run Single Script                                        ║
║  [4] 👁️  Dry Run (Preview All)                                   ║
║  [5] 📊 View Progress / Status                                   ║
║  [6] ⚙️  Configure Settings                                      ║
║  [7] 📖 Help                                                     ║
║  [0] ❌ Exit                                                      ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝

Enter choice [1-7, 0 to exit]: _
```

### 3.2 Phase Selection Menu

```
╔══════════════════════════════════════════════════════════════════╗
║                    SELECT PHASE TO RUN                           ║
╠══════════════════════════════════════════════════════════════════╣
║  Status: ✓ = Complete, ● = In Progress, ○ = Pending, ⚠ = Error  ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  [0]  ✓  Phase 0: Foundation        (4 scripts)  [00:45]        ║
║  [1]  ✓  Phase 1: Docker            (3 scripts)  [00:32]        ║
║  [2]  ●  Phase 2: Database          (4 scripts)  [running...]   ║
║  [3]  ○  Phase 3: Security          (4 scripts)  [pending]      ║
║  [4]  ○  Phase 4: Authentication    (2 scripts)  [pending]      ║
║  [5]  ○  Phase 5: AI Integration    (3 scripts)  [LLM BREAK]    ║
║  [6]  ○  Phase 6: State Management  (2 scripts)  [pending]      ║
║  [7]  ○  Phase 7: Background Jobs   (2 scripts)  [pending]      ║
║  [8]  ○  Phase 8: Observability     (2 scripts)  [pending]      ║
║  [9]  ○  Phase 9: UI Components     (3 scripts)  [LLM BREAK]    ║
║  [10] ○  Phase 10: Testing          (3 scripts)  [pending]      ║
║  [11] ○  Phase 11: Code Quality     (3 scripts)  [pending]      ║
║                                                                  ║
║  [A] Run All Remaining    [B] Back to Main    [H] Help          ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝

Enter phase number or command: _
```

### 3.3 Script Selection Menu (within Phase)

```
╔══════════════════════════════════════════════════════════════════╗
║              PHASE 2: DATABASE LAYER (4 scripts)                 ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  [08] ✓  drizzle-setup        Install Drizzle ORM + config      ║
║  [09] ●  drizzle-schema-base  Generate base schema tables       ║
║  [10] ○  drizzle-migrations   Setup migration infrastructure    ║
║  [11] ○  db-client-index      Create DB client with pooling     ║
║                                                                  ║
║  ─────────────────────────────────────────────────────────────  ║
║  [A] Run All in Phase    [S] Skip to Next Phase                 ║
║  [R] Re-run Completed    [B] Back    [H] Help                   ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝

Enter script number or command: _
```

---

## 4. Interactive Prompts

### 4.1 Project Configuration Prompt (First Run)

```
╔══════════════════════════════════════════════════════════════════╗
║                  PROJECT CONFIGURATION                           ║
╚══════════════════════════════════════════════════════════════════╝

? Project name [bloom2]: _
? Project directory [/home/user/bloom-v2]: _
? Node.js version [20]: _
? Package manager [pnpm]: _
? Database name [bloom2_db]: _
? Database port [5432]: _
? Enable pgvector extension? [Y/n]: _
? Auth provider [credentials]: _
? AI provider [anthropic]: _

──────────────────────────────────────────────────────────────────

Configuration Summary:
  Project:    bloom2
  Directory:  /home/user/bloom-v2
  Node:       20.x LTS
  Database:   PostgreSQL 16 + pgvector @ localhost:5432
  Auth:       Credentials (Auth.js v5)
  AI:         Anthropic via @vercel/ai

? Proceed with this configuration? [Y/n]: _
```

### 4.2 Pre-Script Confirmation Prompt

```
┌──────────────────────────────────────────────────────────────────┐
│  SCRIPT: 09-drizzle-schema-base.sh                               │
├──────────────────────────────────────────────────────────────────┤
│  Description: Generate base Drizzle schema with core tables      │
│  Creates:                                                        │
│    • src/db/schema.ts                                            │
│    • Tables: users, audit_log, feature_flags, app_settings       │
│    • Includes version column for optimistic locking              │
│  Dependencies: Script 08 (drizzle-setup) ✓                       │
│  Estimated time: ~15 seconds                                     │
├──────────────────────────────────────────────────────────────────┤
│  [R] Run    [S] Skip    [P] Preview (dry-run)    [H] Help       │
└──────────────────────────────────────────────────────────────────┘
Choice: _
```

### 4.3 LLM Breakpoint Prompt

```
╔══════════════════════════════════════════════════════════════════╗
║  ⚡ LLM HANDOFF BREAKPOINT                                       ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  Phase 5 (AI Integration) has completed the scaffolding.        ║
║                                                                  ║
║  The following files require LLM customization:                  ║
║                                                                  ║
║    • src/prompts/system.ts        ← Define Melissa persona      ║
║    • src/prompts/discovery.ts     ← Discovery phase logic       ║
║    • src/prompts/quantification.ts← Metric extraction rules     ║
║    • src/prompts/validation.ts    ← Review phase prompts        ║
║    • src/prompts/synthesis.ts     ← Report narrative builder    ║
║                                                                  ║
║  RECOMMENDED NEXT STEPS:                                         ║
║  1. Hand off to Claude/LLM to populate prompt content            ║
║  2. Review and test each prompt with sample conversations        ║
║  3. Return here and run: ./orchestrate.sh --resume               ║
║                                                                  ║
╠══════════════════════════════════════════════════════════════════╣
║  [C] Continue Anyway    [S] Save & Exit    [E] Export Handoff   ║
╚══════════════════════════════════════════════════════════════════╝

Choice: _
```

### 4.4 Error Recovery Prompt

```
╔══════════════════════════════════════════════════════════════════╗
║  ❌ SCRIPT FAILED: 16-authjs-v5-setup.sh                         ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  Exit Code: 1                                                    ║
║  Error: pnpm install failed - network timeout                    ║
║                                                                  ║
║  Log excerpt:                                                    ║
║  ─────────────────────────────────────────────────────────────  ║
║  [14:32:05] Installing @auth/core...                             ║
║  [14:32:15] ERR_NETWORK: request to registry.npmjs.org failed   ║
║  [14:32:15] Retry 1/3...                                         ║
║  [14:32:25] ERR_NETWORK: request to registry.npmjs.org failed   ║
║  ─────────────────────────────────────────────────────────────  ║
║                                                                  ║
║  RECOVERY OPTIONS:                                               ║
║  [R] Retry this script                                           ║
║  [S] Skip and continue (mark as failed)                          ║
║  [M] Manual fix, then mark complete                              ║
║  [L] View full log                                               ║
║  [A] Abort run (checkpoint saved)                                ║
║  [H] Help / troubleshooting                                      ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝

Choice: _
```

---

## 5. Dry Run Mode

### 5.1 Dry Run Output Format

```
╔══════════════════════════════════════════════════════════════════╗
║  🔍 DRY RUN MODE - No changes will be made                       ║
╚══════════════════════════════════════════════════════════════════╝

Phase 0: Foundation
──────────────────────────────────────────────────────────────────
[DRY] 01-init-nextjs15.sh
      WOULD CREATE: package.json
      WOULD RUN:    pnpm create next-app@latest . --typescript --tailwind --app --src-dir
      WOULD MODIFY: next.config.js (add experimental features)

[DRY] 02-init-typescript.sh
      WOULD MODIFY: tsconfig.json
      CHANGES:      strict: true, paths: {"@/*": ["./src/*"]}

[DRY] 03-init-package-engines.sh
      WOULD MODIFY: package.json
      CHANGES:      Add "engines": {"node": ">=20.0.0", "pnpm": ">=9.0.0"}

[DRY] 04-init-directory-structure.sh
      WOULD CREATE: src/features/
      WOULD CREATE: src/features/chat/
      WOULD CREATE: src/features/review/
      WOULD CREATE: src/features/report/
      WOULD CREATE: src/features/projects/
      WOULD CREATE: src/features/settings/
      WOULD CREATE: src/lib/
      WOULD CREATE: src/db/
      WOULD CREATE: src/schemas/
      WOULD CREATE: src/prompts/
      WOULD CREATE: tests/unit/
      WOULD CREATE: tests/integration/
      WOULD CREATE: tests/e2e/

Phase 1: Docker
──────────────────────────────────────────────────────────────────
[DRY] 05-docker-multistage.sh
      WOULD CREATE: Dockerfile (47 lines)
      TEMPLATE:     Multi-stage Node 20 Alpine + pnpm

...

──────────────────────────────────────────────────────────────────
DRY RUN SUMMARY
──────────────────────────────────────────────────────────────────
  Total scripts:     35
  Files to create:   52
  Files to modify:   8
  Commands to run:   23
  Estimated time:    ~8 minutes

  LLM Breakpoints:   2 (after Phase 5, after Phase 9)

? Execute this plan for real? [y/N]: _
```

---

## 6. Help System

### 6.1 Main Help

```
╔══════════════════════════════════════════════════════════════════╗
║                         HELP - OVERVIEW                          ║
╚══════════════════════════════════════════════════════════════════╝

USAGE:
  ./orchestrate.sh [options]

OPTIONS:
  --auto              Run all scripts automatically (stops at breakpoints)
  --dry-run           Preview actions without executing
  --phase <name>      Run specific phase (e.g., --phase 02-database)
  --script <num>      Run specific script (e.g., --script 08)
  --resume            Continue from last checkpoint
  --headless          No interactive prompts (uses config file)
  --skip-breakpoints  Don't stop at LLM handoff points
  --config <file>     Use custom configuration file
  --list              List all phases and scripts
  --help              Show this help message
  --version           Show version information

INTERACTIVE COMMANDS (in menus):
  A     Run All (in current context)
  B     Back to previous menu
  H     Help for current context
  Q/0   Quit / Exit
  R     Retry last failed script
  S     Skip current script/phase

KEYBOARD SHORTCUTS:
  Ctrl+C   Abort (checkpoint saved)
  Ctrl+L   Clear screen
  Ctrl+R   Refresh status

FILES:
  logs/run_<timestamp>.log    Detailed execution log
  state/.checkpoint           Resume state file
  config/defaults.conf        Default configuration

For detailed help on a specific topic:
  ./orchestrate.sh --help phases
  ./orchestrate.sh --help breakpoints
  ./orchestrate.sh --help troubleshooting
```

### 6.2 Contextual Help (Script-Level)

```
╔══════════════════════════════════════════════════════════════════╗
║  HELP: 09-drizzle-schema-base.sh                                 ║
╚══════════════════════════════════════════════════════════════════╝

PURPOSE:
  Generates the foundational Drizzle ORM schema file with core
  application tables that most apps need.

TABLES CREATED:
  • users           - Authentication and user management
  • audit_log       - Immutable change tracking
  • feature_flags   - Runtime feature toggles
  • app_settings    - Application configuration

FEATURES:
  • All tables include 'version' column for optimistic locking
  • Timestamps (createdAt, updatedAt) on all tables
  • Type-safe TypeScript definitions exported

DEPENDENCIES:
  ✓ Script 08 (drizzle-setup) must complete first

ROLLBACK:
  To undo this script:
    rm src/db/schema.ts

CUSTOMIZATION:
  After running, you may want to:
  • Add application-specific tables (projects, sessions, etc.)
  • Modify column types or constraints
  • Add indexes for query performance

TROUBLESHOOTING:
  • "Module not found" → Run script 08 first
  • "File exists" → Use --force to overwrite

Press any key to return...
```

---

## 7. Error Handling

### 7.1 Error Levels

| Level | Code | Behavior |
|-------|------|----------|
| **INFO** | 0 | Log only, continue |
| **WARNING** | 1 | Log, prompt user, suggest skip |
| **ERROR** | 2 | Log, stop script, offer retry/skip/abort |
| **FATAL** | 3 | Log, abort entire run, save checkpoint |

### 7.2 Error Handler Implementation

```bash
# lib/common.sh

handle_error() {
    local exit_code=$1
    local script_name=$2
    local error_msg=$3
    local line_number=$4

    case $exit_code in
        0)
            log_info "$script_name completed successfully"
            ;;
        1)
            log_warning "$script_name: $error_msg (line $line_number)"
            prompt_warning_recovery "$script_name"
            ;;
        2)
            log_error "$script_name failed: $error_msg (line $line_number)"
            prompt_error_recovery "$script_name"
            ;;
        *)
            log_fatal "$script_name: Fatal error - $error_msg"
            save_checkpoint
            exit 1
            ;;
    esac
}

# Retry logic with exponential backoff
retry_with_backoff() {
    local max_attempts=$1
    local command=$2
    local attempt=1
    local delay=2

    while [ $attempt -le $max_attempts ]; do
        if eval "$command"; then
            return 0
        fi
        log_warning "Attempt $attempt failed, retrying in ${delay}s..."
        sleep $delay
        attempt=$((attempt + 1))
        delay=$((delay * 2))
    done
    return 1
}
```

### 7.3 Validation Checks (Pre-Script)

Each script runs validation before execution:

```bash
# Example validation in 08-drizzle-setup.sh

validate_prerequisites() {
    local errors=()

    # Check Node.js version
    if ! command -v node &> /dev/null; then
        errors+=("Node.js not found")
    elif [[ $(node -v | cut -d'v' -f2 | cut -d'.' -f1) -lt 20 ]]; then
        errors+=("Node.js 20+ required, found $(node -v)")
    fi

    # Check pnpm
    if ! command -v pnpm &> /dev/null; then
        errors+=("pnpm not found - run: npm install -g pnpm")
    fi

    # Check package.json exists
    if [[ ! -f "package.json" ]]; then
        errors+=("package.json not found - run Phase 0 first")
    fi

    # Check dependencies from previous scripts
    if [[ ! -f "tsconfig.json" ]]; then
        errors+=("TypeScript not configured - run script 02 first")
    fi

    if [[ ${#errors[@]} -gt 0 ]]; then
        log_error "Prerequisites not met:"
        for err in "${errors[@]}"; do
            echo "  ✗ $err"
        done
        return 1
    fi

    log_success "All prerequisites met"
    return 0
}
```

---

## 8. Automation & Breakpoints

### 8.1 Breakpoint Configuration

```bash
# config/breakpoints.conf

# Format: PHASE_ID:BREAKPOINT_TYPE:HANDOFF_INSTRUCTIONS

05-ai:llm:Populate prompt templates with Melissa persona and phase-specific logic
09-ui:llm:Customize shadcn components and implement Bloom2-specific UI patterns
02-database:review:Review generated schema before running migrations
11-quality:test:Run full test suite before marking complete
```

### 8.2 Breakpoint Types

| Type | Behavior |
|------|----------|
| `llm` | Stop for LLM/human to complete creative work |
| `review` | Stop for human review before continuing |
| `test` | Stop to run tests, continue on pass |
| `manual` | Stop for manual steps (external tools, etc.) |
| `checkpoint` | Auto-save state, optional stop |

### 8.3 LLM Handoff Export

When stopping at an LLM breakpoint, generate a handoff document:

```bash
# Generated: handoff_phase05_ai_<timestamp>.md

# LLM Handoff: Phase 5 - AI Integration

## Context
Bootstrap scripts have created the following structure:
- src/prompts/system.ts (empty template)
- src/prompts/discovery.ts (empty template)
- src/prompts/quantification.ts (empty template)
- src/prompts/validation.ts (empty template)
- src/prompts/synthesis.ts (empty template)

## Your Task
Populate each prompt file with appropriate content for Melissa.ai

## Requirements
1. **system.ts**: Define Melissa's core persona, safety rules, response format
2. **discovery.ts**: Questions for baseline/retrospective discovery phase
3. **quantification.ts**: Metric extraction and structured output format
4. **validation.ts**: Review and confirmation prompts
5. **synthesis.ts**: Narrative generation for final reports

## Reference Architecture
See: /docs/ARCHITECTURE.md section 3.1

## When Complete
Run: ./orchestrate.sh --resume

## Files to Edit
- [ ] src/prompts/system.ts
- [ ] src/prompts/discovery.ts
- [ ] src/prompts/quantification.ts
- [ ] src/prompts/validation.ts
- [ ] src/prompts/synthesis.ts
```

---

## 9. Logging System

### 9.1 Log Format

```
# logs/run_20250122_143052.log

[2025-01-22 14:30:52] [INFO] ══════════════════════════════════════════════
[2025-01-22 14:30:52] [INFO] ORCHESTRATOR START - Run ID: run_20250122_143052
[2025-01-22 14:30:52] [INFO] Mode: interactive
[2025-01-22 14:30:52] [INFO] Project: bloom2
[2025-01-22 14:30:52] [INFO] Target: /home/user/bloom-v2
[2025-01-22 14:30:52] [INFO] ══════════════════════════════════════════════

[2025-01-22 14:30:53] [INFO] [PHASE 0] Foundation - Starting (4 scripts)
[2025-01-22 14:30:53] [INFO] [01] init-nextjs15 - Starting
[2025-01-22 14:30:53] [DEBUG] Command: pnpm create next-app@latest . --typescript
[2025-01-22 14:31:15] [INFO] [01] init-nextjs15 - Completed (22s)
[2025-01-22 14:31:15] [INFO] [01] Files created: package.json, next.config.js, tsconfig.json
[2025-01-22 14:31:16] [INFO] [02] init-typescript - Starting
[2025-01-22 14:31:17] [INFO] [02] init-typescript - Completed (1s)
[2025-01-22 14:31:17] [INFO] [02] Files modified: tsconfig.json
...
[2025-01-22 14:35:42] [WARN] [16] authjs-v5-setup - Network timeout, retrying (1/3)
[2025-01-22 14:35:47] [INFO] [16] authjs-v5-setup - Retry successful
...
[2025-01-22 14:42:15] [INFO] [BREAKPOINT] Phase 5 complete - LLM handoff required
[2025-01-22 14:42:15] [INFO] Handoff exported: handoff_phase05_ai_20250122_144215.md
[2025-01-22 14:42:15] [INFO] Checkpoint saved: state/.checkpoint
[2025-01-22 14:42:15] [INFO] Run paused - resume with: ./orchestrate.sh --resume

[2025-01-22 14:42:15] [INFO] ══════════════════════════════════════════════
[2025-01-22 14:42:15] [INFO] RUN SUMMARY
[2025-01-22 14:42:15] [INFO] ══════════════════════════════════════════════
[2025-01-22 14:42:15] [INFO] Duration: 11m 23s
[2025-01-22 14:42:15] [INFO] Scripts run: 20/35
[2025-01-22 14:42:15] [INFO] Successful: 20
[2025-01-22 14:42:15] [INFO] Warnings: 1
[2025-01-22 14:42:15] [INFO] Errors: 0
[2025-01-22 14:42:15] [INFO] Status: PAUSED (LLM breakpoint)
```

### 9.2 Log Utilities

```bash
# lib/common.sh

LOG_FILE=""
LOG_LEVEL="INFO"  # DEBUG, INFO, WARN, ERROR

init_logging() {
    local run_id="run_$(date +%Y%m%d_%H%M%S)"
    LOG_FILE="logs/${run_id}.log"
    mkdir -p logs

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] Log initialized: $LOG_FILE" | tee -a "$LOG_FILE"
}

log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"

    # Also print to console with color
    case $level in
        DEBUG) [[ "$LOG_LEVEL" == "DEBUG" ]] && echo -e "\033[90m$message\033[0m" ;;
        INFO)  echo -e "\033[37m$message\033[0m" ;;
        WARN)  echo -e "\033[33m⚠ $message\033[0m" ;;
        ERROR) echo -e "\033[31m✗ $message\033[0m" ;;
    esac
}

log_debug() { log "DEBUG" "$1"; }
log_info()  { log "INFO" "$1"; }
log_warning() { log "WARN" "$1"; }
log_error() { log "ERROR" "$1"; }
log_success() { log "INFO" "✓ $1"; }
```

---

## 10. State Management

### 10.1 Checkpoint Format

```json
// state/.checkpoint
{
  "run_id": "run_20250122_143052",
  "started_at": "2025-01-22T14:30:52Z",
  "paused_at": "2025-01-22T14:42:15Z",
  "mode": "interactive",
  "config": {
    "project_name": "bloom2",
    "target_dir": "/home/user/bloom-v2",
    "node_version": "20",
    "db_name": "bloom2_db"
  },
  "progress": {
    "current_phase": 5,
    "current_script": 20,
    "completed_scripts": [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20],
    "skipped_scripts": [],
    "failed_scripts": []
  },
  "breakpoint": {
    "type": "llm",
    "phase": "05-ai",
    "handoff_file": "handoff_phase05_ai_20250122_144215.md"
  },
  "log_file": "logs/run_20250122_143052.log"
}
```

### 10.2 Resume Logic

```bash
resume_from_checkpoint() {
    if [[ ! -f "state/.checkpoint" ]]; then
        log_error "No checkpoint found"
        return 1
    fi

    local checkpoint=$(cat state/.checkpoint)
    local run_id=$(echo "$checkpoint" | jq -r '.run_id')
    local next_script=$(echo "$checkpoint" | jq -r '.progress.current_script + 1')
    local current_phase=$(echo "$checkpoint" | jq -r '.progress.current_phase')

    log_info "Resuming run: $run_id"
    log_info "Continuing from script $next_script in phase $current_phase"

    # Restore config
    export PROJECT_NAME=$(echo "$checkpoint" | jq -r '.config.project_name')
    export TARGET_DIR=$(echo "$checkpoint" | jq -r '.config.target_dir')

    # Continue execution
    run_from_script "$next_script"
}
```

---

## 11. Script Interface Contract

Every bootstrap script MUST implement this interface:

```bash
#!/bin/bash
# Script: XX-script-name.sh
# Phase: NN-phase-name
# Description: Brief description of what this script does
# Dependencies: Script XX, Script YY
# Creates: file1.ts, file2.ts
# Modifies: file3.json
# Breakpoint: none | llm | review | test

set -euo pipefail
source "$(dirname "$0")/../../lib/common.sh"

# ============================================================
# METADATA (for orchestrator)
# ============================================================
SCRIPT_ID="XX"
SCRIPT_NAME="script-name"
SCRIPT_DESCRIPTION="What this script does"
SCRIPT_PHASE="NN-phase-name"
SCRIPT_DEPENDENCIES=("08" "09")
SCRIPT_CREATES=("src/path/file1.ts" "src/path/file2.ts")
SCRIPT_MODIFIES=("package.json")
SCRIPT_BREAKPOINT="none"
SCRIPT_ESTIMATED_TIME="15s"

# ============================================================
# VALIDATION
# ============================================================
validate() {
    check_dependency "node" "20"
    check_dependency "pnpm" "9"
    check_file_exists "package.json"
    check_script_completed "08"
    # Return 0 if valid, 1 if not
}

# ============================================================
# DRY RUN (preview mode)
# ============================================================
dry_run() {
    echo "[DRY] Would create: ${SCRIPT_CREATES[*]}"
    echo "[DRY] Would modify: ${SCRIPT_MODIFIES[*]}"
    echo "[DRY] Would run: pnpm add drizzle-orm postgres"
}

# ============================================================
# EXECUTE (actual work)
# ============================================================
execute() {
    log_info "Installing dependencies..."
    pnpm add drizzle-orm postgres

    log_info "Creating schema file..."
    cat > src/db/schema.ts << 'EOF'
    // Schema content here
EOF

    log_success "Schema created at src/db/schema.ts"
}

# ============================================================
# ROLLBACK (undo changes)
# ============================================================
rollback() {
    rm -f src/db/schema.ts
    pnpm remove drizzle-orm postgres
    log_info "Rollback complete"
}

# ============================================================
# MAIN ENTRY POINT
# ============================================================
main() {
    local mode=${1:-"execute"}

    case $mode in
        validate) validate ;;
        dry-run)  dry_run ;;
        execute)  validate && execute ;;
        rollback) rollback ;;
        metadata) print_metadata ;;
        *)        echo "Unknown mode: $mode" && exit 1 ;;
    esac
}

main "$@"
```

---

## 12. Configuration Files

### 12.1 defaults.conf

```bash
# config/defaults.conf

# Project defaults
DEFAULT_PROJECT_NAME="bloom2"
DEFAULT_NODE_VERSION="20"
DEFAULT_PNPM_VERSION="9"

# Database defaults
DEFAULT_DB_NAME="bloom2_db"
DEFAULT_DB_PORT="5432"
DEFAULT_DB_USER="postgres"
DEFAULT_ENABLE_PGVECTOR="true"

# Auth defaults
DEFAULT_AUTH_PROVIDER="credentials"

# AI defaults
DEFAULT_AI_PROVIDER="anthropic"

# Behavior defaults
DEFAULT_LOG_LEVEL="INFO"
DEFAULT_AUTO_RETRY="true"
DEFAULT_RETRY_COUNT="3"
DEFAULT_STOP_ON_WARNING="false"
DEFAULT_STOP_AT_BREAKPOINTS="true"
```

### 12.2 phases.conf

```bash
# config/phases.conf

# Format: PHASE_ID:PHASE_NAME:SCRIPT_COUNT:DEPENDENCIES

00-foundation:Project Foundation:4:
01-docker:Docker Infrastructure:3:00-foundation
02-database:Database Layer:4:00-foundation
03-security:Environment & Security:4:00-foundation
04-auth:Authentication:2:00-foundation,03-security
05-ai:AI Integration:3:00-foundation,02-database
06-state:State Management:2:00-foundation
07-jobs:Background Jobs:2:02-database
08-observability:Observability:2:00-foundation
09-ui:UI Components:3:00-foundation
10-testing:Testing Infrastructure:3:00-foundation
11-quality:Code Quality:3:00-foundation
```

---

## 13. Success Criteria

The orchestrator is complete when:

1. ✓ All 35 scripts can run independently via `--script`
2. ✓ All 12 phases can run via `--phase`
3. ✓ `--auto` runs everything, stopping at breakpoints
4. ✓ `--dry-run` previews all actions without side effects
5. ✓ `--resume` correctly continues from checkpoint
6. ✓ All errors are caught, logged, and offer recovery
7. ✓ Logs capture full run history with timestamps
8. ✓ LLM handoff exports are actionable and complete
9. ✓ Interactive menus are navigable and intuitive
10. ✓ Help is available at every level

---

## 14. Token Efficiency Notes

This orchestrator design maximizes token efficiency by:

1. **Checkpoint/Resume**: Interrupted runs don't restart from zero
2. **Handoff Exports**: LLM gets focused context, not full state
3. **Dry Run**: Validate plans before spending tokens on execution
4. **Modular Scripts**: Only regenerate what's needed
5. **Metadata Interface**: Orchestrator queries scripts without parsing
6. **Central Logging**: Debug without re-running

**Estimated savings on resume**: 95% (only run remaining scripts)
**Estimated savings with handoff**: 80% (LLM gets focused task, not full context)
