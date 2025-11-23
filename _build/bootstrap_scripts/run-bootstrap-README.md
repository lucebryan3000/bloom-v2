# Bloom2 Bootstrap Orchestrator v2.0

**Current Status**: ✅ PRODUCTION READY
**Last Updated**: November 22, 2025

---

## Quick Start

```bash
cd _build/bootstrap_scripts

# View what would run (no execution)
DRY_RUN=true ALLOW_DIRTY=true ./run-bootstrap.sh --all

# Full bootstrap (with resume capability)
./run-bootstrap.sh --all

# Check progress
./run-bootstrap.sh --status
```

---

## Overview

The **Bootstrap Orchestrator v2.0** is a config-driven system for automatically initializing the complete Bloom2 application stack (Next.js 15 + PostgreSQL + AI + Docker + Testing).

### Key Features

- ✅ **Config-Driven Execution** - Script order defined in `bootstrap.conf`
- ✅ **Resume Capability** - Automatically resumes after interruptions
- ✅ **Environment Variable Overrides** - CLI flags take precedence over config
- ✅ **Dry-Run Mode** - Preview without side effects
- ✅ **Progress Tracking** - Shows X/Y scripts completed
- ✅ **Git Safety Checks** - Prevents running on dirty repos
- ✅ **Interactive Configuration** - First-run prompts for customization
- ✅ **JSON Logging** - Machine-parseable output for CI/CD pipelines
- ✅ **43 Complete Scripts** - All technology layers + business logic pre-configured

---

## System Architecture

### Core Components

```
_build/bootstrap_scripts/
├── run-bootstrap.sh              # v2.0 Orchestrator (main entry point)
├── lib/
│   └── common.sh                 # Shared library (42 functions, 705 lines)
├── tech_stack/                   # 43 bootstrap scripts organized by technology
│   ├── foundation/               # NextJS, TypeScript, packages (4 scripts)
│   ├── docker/                   # Docker, Compose, pnpm cache (3 scripts)
│   ├── db/                       # Drizzle ORM, migrations (4 scripts)
│   ├── env/                      # Environment validation, Zod (4 scripts)
│   ├── auth/                     # Auth.js authentication (2 scripts)
│   ├── ai/                       # Vercel AI SDK (3 scripts)
│   ├── state/                    # Zustand state management (2 scripts)
│   ├── jobs/                     # PgBoss background jobs (2 scripts)
│   ├── observability/            # Pino logging (2 scripts)
│   ├── intelligence/             # Melissa, ROI, confidence, HITL (4 scripts) NEW
│   ├── export/                   # PDF, Excel, JSON, Markdown export (5 scripts) NEW
│   ├── monitoring/               # Health, settings, feature flags (3 scripts) NEW
│   ├── ui/                       # Shadcn UI components (3 scripts)
│   ├── testing/                  # Vitest, Playwright (3 scripts)
│   └── quality/                  # ESLint, Prettier, TypeScript strict (3 scripts)
├── example/                      # Configuration templates & examples
│   ├── bootstrap.conf.example    # Bootstrap orchestrator template
│   ├── .env.example              # Runtime environment variables template
│   ├── .gitignore.example        # VCS exclusions template
│   └── .claudeignore.example     # Claude Code context optimization template
├── bootstrap.conf                # Configuration (active, customizable)
├── logs/                         # Execution logs directory
└── .bootstrap_state              # Runtime state tracking (resume capability)
```

### Execution Model

1. **Load Configuration** - Reads `bootstrap.conf` with env var override support
2. **Git Safety Check** - Verifies working tree is clean (unless `ALLOW_DIRTY=true`)
3. **Run Scripts** - Executes scripts in order defined by `BOOTSTRAP_STEPS_DEFAULT`
4. **Track State** - Records completion timestamp in `.bootstrap_state`
5. **Resume Logic** - Skips already-completed scripts on subsequent runs

---

## Configuration

### bootstrap.conf - Key Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `APP_NAME` | bloom2 | Application name |
| `PROJECT_ROOT` | . | Project directory path |
| `DB_NAME` | bloom2_db | Database name |
| `DB_USER` | bloom2 | Database user |
| `DB_PASSWORD` | change_me | **MUST be changed before production** |
| `GIT_SAFETY` | true | Require clean git repo |
| `ALLOW_DIRTY` | false | Override git safety |
| `BOOTSTRAP_RESUME_MODE` | skip | Resume behavior (skip=resume, force=re-run) |
| `LOG_FORMAT` | plain | Output format (plain or json) |
| `DRY_RUN` | false | Preview mode |
| `VERBOSE` | false | Detailed output |
| `BOOTSTRAP_STEPS_DEFAULT` | [multiline] | Script execution order |

### Environment Variable Overrides

All config values can be overridden via environment variables (they take precedence):

```bash
# Override specific settings
APP_NAME=myapp DB_PASSWORD=secure ./run-bootstrap.sh --all

# Or export before running
export ALLOW_DIRTY=true
export DRY_RUN=true
./run-bootstrap.sh --all
```

---

## Usage Guide

### Commands

```bash
# Config-driven execution (recommended)
./run-bootstrap.sh --all

# Preview without executing
./run-bootstrap.sh --all --dry-run

# Resume after interruption (auto-skips completed scripts)
./run-bootstrap.sh --all

# Force re-run all scripts (ignore completion state)
./run-bootstrap.sh --all --force

# Show bootstrap progress
./run-bootstrap.sh --status

# List available phases and scripts
./run-bootstrap.sh list

# Run specific phase only
./run-bootstrap.sh phase 02-database

# Run specific script by number
./run-bootstrap.sh script 08

# Show help
./run-bootstrap.sh --help
```

### Common Scenarios

**First-time setup with preview:**
```bash
DRY_RUN=true ALLOW_DIRTY=true ./run-bootstrap.sh --all
```

**Full bootstrap with dirty working tree:**
```bash
ALLOW_DIRTY=true ./run-bootstrap.sh --all
```

**Bootstrap in CI/CD (non-interactive):**
```bash
NON_INTERACTIVE=true ./run-bootstrap.sh --all
```

**JSON logging for CI/CD aggregation:**
```bash
LOG_FORMAT=json ./run-bootstrap.sh --all > bootstrap.json 2>&1
```

**Reset and restart from scratch:**
```bash
rm .bootstrap_state
./run-bootstrap.sh --all
```

**Skip a script and retry:**
```bash
# The clear_script_state function can be sourced from common.sh
source lib/common.sh
clear_script_state "db/drizzle-setup.sh"
./run-bootstrap.sh --all
```

---

## Bootstrap Phases (15 Total)

### Infrastructure & Foundation Layers (Phases 0-8)

| # | Phase ID | Name | Scripts | Technology |
|---|----------|------|---------|-----------|
| 00 | foundation | Project Foundation | 4 | NextJS, TypeScript, packages, directory structure |
| 01 | docker | Docker Infrastructure | 3 | Docker, Docker Compose, pnpm caching |
| 02 | db | Database Layer | 4 | Drizzle ORM, schema, migrations, client |
| 03 | env | Environment & Security | 4 | Validation, Zod schemas, rate limiting |
| 04 | auth | Authentication | 2 | Auth.js v5 setup and routes |
| 05 | ai | AI Integration | 3 | Vercel AI SDK, prompts, chat scaffold |
| 06 | state | State Management | 2 | Zustand store, session state |
| 07 | jobs | Background Jobs | 2 | PgBoss queue and workers |
| 08 | observability | Observability | 2 | Pino logger, pretty dev output |

### Business Logic & Feature Layers (Phases 9-11)

| # | Phase ID | Name | Scripts | Technology |
|---|----------|------|---------|-----------|
| 09 | intelligence | AI Intelligence Engine | 4 | Melissa prompts, ROI engine, confidence scoring, HITL review |
| 10 | export | Export System | 5 | PDF, Excel, JSON, Markdown export with narratives |
| 11 | monitoring | Monitoring & Operations | 3 | Health endpoints, user settings, feature flags |

### Presentation & Quality Layers (Phases 12-14)

| # | Phase ID | Name | Scripts | Technology |
|---|----------|------|---------|-----------|
| 12 | ui | UI Components | 3 | Shadcn UI, react-to-print, component structure |
| 13 | testing | Testing Infrastructure | 3 | Vitest, Playwright, test directory |
| 14 | quality | Code Quality | 3 | ESLint, Prettier, TypeScript strict mode |

---

## Business Logic Layers (NEW in v2.0)

The bootstrap system now includes three new **business logic phases** that implement core Bloom2 features:

### Intelligence Phase (4 Scripts)
Set up AI-driven business case analysis with human-in-the-loop review:

1. **melissa-prompts.sh** - Multi-phase AI assistant with behavioral rules
   - Creates system persona and phase-based prompts
   - Implements: discovery, quantification, validation, synthesis phases
   - Features: metric tagging, contradiction detection, assumption tracking

2. **roi-engine.sh** - Deterministic financial impact calculation
   - Three-scenario analysis (conservative/base/aggressive)
   - Calculates: time saved, labor savings, error reduction, ROI%, payback period
   - Multi-dimensional Improvement Index (financial/operational/human)

3. **confidence-engine.sh** - Data quality and uncertainty scoring
   - Weighted confidence factors (data quality, precision, agreement, reliability)
   - Session-level snapshots with readiness assessments
   - Identifies high-uncertainty metrics and areas for review

4. **hitl-review-queue.sh** - Human-in-the-Loop governance
   - Review item creation and prioritization
   - Reviewer actions with audit trails
   - Confidence adjustments based on human decisions

**Reference:** [tech_stack/intelligence/README.md](tech_stack/intelligence/README.md)

### Export Phase (5 Scripts)
Professional multi-format export with narrative generation:

1. **export-system.sh** - Core infrastructure and shared utilities
   - BusinessCase data model definition
   - Narrative builders (executive summary, current state, value, recommendations)
   - Shared formatting utilities

2. **pdf-export.sh** - React-based PDF generation
   - Professional layout with header, sections, charts, footer
   - Uses react-to-print and jsPDF
   - Component: `PDFExport` React component

3. **excel-export.sh** - Multi-sheet Excel workbooks
   - Separate sheets: Summary, ROI Scenarios, Metrics, Assumptions, Risks
   - Formatted cells with conditional styling
   - Uses ExcelJS library

4. **json-export.sh** - Complete data export
   - Full JSON serialization of business case
   - Includes analysis context and derivatives
   - Suitable for integration and archival

5. **markdown-export.sh** - GitHub-flavored Markdown
   - Table of contents with anchors
   - Emoji indicators for confidence levels
   - Version-control friendly format

**Reference:** [tech_stack/export/README.md](tech_stack/export/README.md)

### Monitoring Phase (3 Scripts)
System health, user settings, and feature management:

1. **health-endpoints.sh** - GET /api/monitoring/health and /api/monitoring/metrics
   - System status (healthy/degraded/unhealthy)
   - Dependency checks (database, AI service)
   - Performance metrics (memory, latency, cache hits)

2. **settings-ui.sh** - User preferences management
   - Export, notification, display, and analysis preferences
   - Settings API: GET /api/settings, POST /api/settings
   - Database persistence with defaults

3. **feature-flags.sh** - Controlled feature rollout
   - Flag evaluation with percentage-based rollout
   - Explicit user targeting (enabled/disabled lists)
   - React hook: `useFeatureFlag()` and `<FeatureFlagGuard>`

**Reference:** [tech_stack/monitoring/README.md](tech_stack/monitoring/README.md)

---

## Core Functions in lib/common.sh

### Path & Configuration Functions
- `_prompt_config_value()` - Interactive config value prompts
- `_init_config()` - First-run configuration setup
- `load_config()` - Load bootstrap.conf with environment override support

### Logging Functions
- `log_info()` - Information level
- `log_error()` - Error level
- `log_debug()` - Debug output (if VERBOSE=true)
- `log_step()` - Step markers
- `log_dry()` - Dry-run preview
- `log_success()` - Success messages
- `log_skip()` - Skip notifications
- `log_warn()` - Warnings
- `_log_json()` - JSON formatted output

### Script Execution & State
- `run_cmd()` - Execute command with timeout protection
- `run_script()` - Execute bootstrap script with logging
- `init_state_file()` - Initialize `.bootstrap_state` tracking
- `mark_script_success()` - Record script completion
- `has_script_succeeded()` - Check if script already ran
- `clear_script_state()` - Reset individual script state

### Validation & Safety
- `ensure_git_clean()` - Check working tree is clean
- `apply_stack_profile()` - Apply feature overrides
- `require_tool()` - Verify required tools available

---

## State Management

### State File Location
```
${PROJECT_ROOT}/.bootstrap_state
```

### State File Format
Each line tracks a completed script:
```
foundation/init-nextjs.sh=success:2025-11-22T23:45:00-06:00
docker/dockerfile-multistage.sh=success:2025-11-22T23:45:15-06:00
```

### Resume Behavior
By default (`BOOTSTRAP_RESUME_MODE=skip`):
- **First run**: Executes all scripts
- **Subsequent runs**: Skips already-completed scripts
- **Interrupted run**: Automatically resumes from where it stopped

### Force Re-run
To ignore state and re-run all scripts:
```bash
./run-bootstrap.sh --all --force
```

Or manually:
```bash
rm .bootstrap_state
./run-bootstrap.sh --all
```

---

## Logging Output

### Log File Location
```
_build/bootstrap_scripts/logs/bootstrap-YYYYMMDD-HHMMSS.log
```

Logs are automatically created in the `_build/bootstrap_scripts/logs/` directory. The orchestrator ensures logs are written to the correct location regardless of where the script is invoked from.

### Plain Text Format (Default)
```
[INFO] === Logging initialized: ./logs/bootstrap-20251122-235201.log ===
[INFO] Script: orchestrator
[INFO] Date: 2025-11-22 23:52:01
[INFO] User: $USER
[INFO] PWD: $PROJECT_ROOT
[INFO] DRY_RUN: false
[INFO] === Bloom2 Bootstrap Orchestrator (Config-Driven) ===
[INFO] Reading script order from bootstrap.conf...
[INFO] Found 35 scripts to execute
[STEP] >>> Running: foundation/init-nextjs.sh
[OK] ✓ init-nextjs.sh completed
[SKIP] foundation/init-typescript.sh (already completed)
```

### JSON Format (for CI/CD)
```bash
LOG_FORMAT=json ./run-bootstrap.sh --all
```

Output:
```json
{"ts":"2025-11-22T23:52:01-06:00","level":"INFO","script":"orchestrator","msg":"Logging initialized"}
{"ts":"2025-11-22T23:52:01-06:00","level":"STEP","script":"orchestrator","msg":"Running: foundation/init-nextjs.sh"}
{"ts":"2025-11-22T23:52:05-06:00","level":"OK","script":"orchestrator","msg":"foundation/init-nextjs.sh completed"}
```

---

## Error Handling

### Git Safety Errors
```bash
# If working tree is dirty:
[ERROR] Git working directory is not clean
[ERROR] Uncommitted changes found. Commit or stash before running bootstrap.
[ERROR] Use ALLOW_DIRTY=true to override this check.

# Solution:
git add . && git commit -m "WIP" && ./run-bootstrap.sh --all
# OR
ALLOW_DIRTY=true ./run-bootstrap.sh --all
```

### Configuration Errors
```bash
# If bootstrap.conf missing:
[ERROR] Configuration file not found: <path>
[ERROR] Also no example file found at: <path>

# Solution:
cp example/bootstrap.conf.example bootstrap.conf
```

### Script Execution Errors
```bash
# If script fails:
[ERROR] === BOOTSTRAP FAILED ===
[ERROR] Script failed: <script-path>
[ERROR] Progress: 5/35 scripts attempted
[ERROR] Resume with: ./run-bootstrap.sh --all

# Solution:
# Fix the issue, then resume
./run-bootstrap.sh --all
```

---

## Testing & Validation

### Dry-Run Test
```bash
DRY_RUN=true ALLOW_DIRTY=true ./run-bootstrap.sh --all
# Shows all scripts that would execute, no actual changes made
```

### Status Check
```bash
./run-bootstrap.sh --status
# Shows which scripts have completed
```

### Single Script Test
```bash
./run-bootstrap.sh phase 02-database --dry-run
# Tests a specific phase safely
```

### Syntax Validation
```bash
# From project root
bash -n _build/bootstrap_scripts/run-bootstrap.sh
bash -n _build/bootstrap_scripts/lib/common.sh

# Or from _build/bootstrap_scripts directory
cd _build/bootstrap_scripts
bash -n run-bootstrap.sh
bash -n lib/common.sh
```

---

## Bug Fixes & Recent Changes

### Path Resolution Fix
**Issue**: `SCRIPT_DIR` was being recomputed when `common.sh` was sourced, breaking config lookups.

**Solution**: Made path detection conditional to respect caller's values.

### Environment Variable Override Support
**Issue**: CLI flags were being overwritten by config file settings.

**Solution**: Save environment variables before sourcing config, restore them after.

### Script Executable Permissions
**Issue**: All 35 bootstrap scripts had incorrect permissions (644 instead of 755).

**Solution**: Applied execute permissions to all scripts.

---

## Success Criteria

Bootstrap is complete when all 35 scripts execute without error. Verify with:

```bash
# Check bootstrap state
./run-bootstrap.sh --status

# Install dependencies
pnpm install

# Start services
docker compose up -d

# Run development server
pnpm dev
```

Application should be available at **http://localhost:3000**

---

## Next Steps

After successful bootstrap:

1. **Review generated files** - Check each technology layer configuration
2. **Install dependencies** - `pnpm install`
3. **Start services** - `docker compose up -d`
4. **Run development** - `pnpm dev`
5. **Test application** - Navigate to http://localhost:3000

---

## Related Documentation

- **Current Implementation**: [run-bootstrap.sh](run-bootstrap.sh)
- **Shared Library**: [lib/common.sh](lib/common.sh)
- **Configuration Templates**: [example/](example/) directory
  - [bootstrap.conf.example](example/bootstrap.conf.example)
  - [.env.example](example/.env.example)
  - [.gitignore.example](example/.gitignore.example)
  - [.claudeignore.example](example/.claudeignore.example)
- **Bootstrap Scripts**: [tech_stack/](tech_stack/) directory

---

## Version History

- **v2.0** (Current) - Config-driven orchestrator with resume capability, environment overrides, JSON logging
  - 43 total scripts (35 original + 8 new business logic scripts)
  - 3 new phases: intelligence, export, monitoring
  - Critical gap analysis implementation: Melissa prompts, ROI engine, confidence scoring, HITL review, multi-format exports, health monitoring
- **v1.0** - Legacy phase-based system (reference only)

---

**Status**: ✅ PRODUCTION READY 🚀
**Total Scripts**: 43 (4 new packages added to bootstrap.conf)
**Last Updated**: 2025-11-23
**Commits**: 66228e2, ae49ce7 (bootstrap state fixes)
