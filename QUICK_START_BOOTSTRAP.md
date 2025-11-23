# Quick Start: Bloom2 Bootstrap System

**Status**: Production Ready ✓
**Location**: `_build/bootstrap_scripts/`
**Latest Update**: 2025-11-22 23:32 UTC

---

## What You Have

A complete, config-driven bootstrap system for initializing Bloom2 (Next.js 15 + PostgreSQL + AI stack) projects with:

- **35 deployment scripts** organized by technology (foundation, docker, db, auth, ai, etc.)
- **Config-driven execution** (bootstrap.conf controls order, features, versions)
- **Resumable runs** (track progress, skip completed scripts)
- **Safety features** (git checks, timeouts, stack profiles)
- **Full documentation** and reference implementations

---

## Quick Start (5 minutes)

### 1. Preview the Bootstrap Plan

```bash
cd /home/luce/apps/bloom2

# Dry-run: see what will happen (no side effects)
_build/bootstrap_scripts/run-bootstrap.sh --all --dry-run
```

Output shows:
- All 35 scripts in execution order
- Config values being used
- No actual changes to your system

### 2. Customize Configuration (Optional)

```bash
# Copy example config to working config
cp _build/bootstrap_scripts/bootstrap.conf.example _build/bootstrap_scripts/bootstrap.conf

# Edit to customize
nano _build/bootstrap_scripts/bootstrap.conf

# Key settings:
# - APP_NAME="bloom2"                   # Project name
# - STACK_PROFILE="full"                # full|minimal|api-only
# - ENABLE_AUTHJS="true"                # Feature flags
# - ENABLE_AI_SDK="true"
# - GIT_SAFETY="true"                   # Require clean git tree
# - MAX_CMD_SECONDS="900"               # Command timeout (15 min)
```

### 3. Run Bootstrap

```bash
# Full run (all 35 scripts)
_build/bootstrap_scripts/run-bootstrap.sh --all

# For less typing, create alias:
alias bootstrap="_build/bootstrap_scripts/run-bootstrap.sh"
bootstrap --all
```

### 4. If Bootstrap Interrupts

```bash
# Check progress
_build/bootstrap_scripts/run-bootstrap.sh status

# Resume (skips completed scripts)
_build/bootstrap_scripts/run-bootstrap.sh --all

# Or force re-run from start
_build/bootstrap_scripts/run-bootstrap.sh --all --force
```

---

## Key Features

### Config-Driven Execution

All configuration in `bootstrap.conf`:
- Script execution order (BOOTSTRAP_STEPS_DEFAULT)
- Package versions (PKG_NEXT, PKG_REACT, etc.)
- Feature flags (ENABLE_AUTHJS, ENABLE_AI_SDK, etc.)
- Database settings (DB_NAME, DB_USER, etc.)
- Safety settings (GIT_SAFETY, ALLOW_DIRTY)

**No hardcoding in scripts** - change bootstrap.conf to customize behavior.

### Resumable Runs

If bootstrap fails at script 15/35:
1. Fix the issue
2. Run again: `bootstrap --all`
3. Scripts 1-14 are skipped automatically (`.bootstrap_state` tracks progress)
4. Bootstrap continues from script 15

### Stack Profiles

Change feature sets without editing scripts:

```bash
# Full (all features, default)
STACK_PROFILE="full"

# Minimal (just core: Next.js, DB, Env, Testing)
STACK_PROFILE="minimal"

# API only (minimal + auth, no UI)
STACK_PROFILE="api-only"
```

### Safety Features

**Git Safety**
```bash
GIT_SAFETY="true"        # Prevent running on dirty working tree
ALLOW_DIRTY="false"      # Override with true if needed
```

**Timeouts**
```bash
MAX_CMD_SECONDS="900"    # Prevent commands hanging (default 15 min)
# Set to 0 for no timeout
```

### Progress Tracking

During execution:
```
Progress: 1/35 - Running: foundation/init-nextjs.sh
Progress: 2/35 - Running: foundation/init-typescript.sh
...
```

Check status anytime:
```bash
_build/bootstrap_scripts/run-bootstrap.sh status

# Output:
# Completed: 5/35 scripts
# - foundation/init-nextjs.sh (2025-11-22 23:15:42)
# - foundation/init-typescript.sh (2025-11-22 23:16:01)
# ...
```

---

## Documentation Files

### Reference
- **BOOTSTRAP_SETUP.md** - Overview and setup guide
- **run-bootstrap-README.md** - Complete v1.0 specification
- **fix_bootstrap_scripts.md** - Implementation details

### Implementation
- **BOOTSTRAP_IMPLEMENTATION_COMPLETE.md** - What was just implemented
- **QUICK_START_BOOTSTRAP.md** - This file (you are here)

---

## Command Reference

### Config-Driven (Recommended)

```bash
# Preview
_build/bootstrap_scripts/run-bootstrap.sh --all --dry-run

# Run all
_build/bootstrap_scripts/run-bootstrap.sh --all

# Check progress
_build/bootstrap_scripts/run-bootstrap.sh status

# Re-run all (ignore previous state)
_build/bootstrap_scripts/run-bootstrap.sh --all --force

# Verbose output
_build/bootstrap_scripts/run-bootstrap.sh --all --verbose
```

### Legacy (Phase-Based)

```bash
# List all phases
_build/bootstrap_scripts/run-bootstrap.sh list

# Run specific phase
_build/bootstrap_scripts/run-bootstrap.sh phase 02-database

# Run all (legacy mode)
_build/bootstrap_scripts/run-bootstrap.sh run

# Preview legacy run
_build/bootstrap_scripts/run-bootstrap.sh run --dry-run
```

### Help

```bash
_build/bootstrap_scripts/run-bootstrap.sh --help
```

---

## File Structure

```
_build/bootstrap_scripts/
├── bootstrap.conf.example          # Config template (customize this)
├── run-bootstrap.sh                # Main orchestrator
├── lib/common.sh                   # Shared utility functions
├── logs/                           # Execution logs (auto-created)
└── tech_stack/                     # Bootstrap scripts by technology
    ├── foundation/                 # Next.js, TypeScript, directories
    ├── docker/                     # Docker containerization
    ├── db/                         # Database (Drizzle ORM)
    ├── env/                        # Environment validation
    ├── auth/                       # Auth.js authentication
    ├── ai/                         # Vercel AI SDK
    ├── state/                      # Zustand state management
    ├── jobs/                       # PG Boss background jobs
    ├── observability/              # Pino logging
    ├── ui/                         # shadcn/ui components
    ├── testing/                    # Vitest & Playwright
    └── quality/                    # ESLint, Prettier, Husky
```

---

## Troubleshooting

### Bootstrap Fails at Step 15

```bash
# Check what failed
tail -100 logs/bootstrap-*.log

# Check current progress
_build/bootstrap_scripts/run-bootstrap.sh status

# Resume from interruption
_build/bootstrap_scripts/run-bootstrap.sh --all
```

### Want to Ignore Previous State

```bash
# Force re-run all scripts (doesn't skip completed ones)
_build/bootstrap_scripts/run-bootstrap.sh --all --force
```

### Need Custom Feature Set

```bash
# Edit bootstrap.conf
nano _build/bootstrap_scripts/bootstrap.conf

# Change STACK_PROFILE or ENABLE_* flags

# Re-run (applies new settings)
_build/bootstrap_scripts/run-bootstrap.sh --all
```

### Git Working Tree Dirty

```bash
# Option 1: Clean it up
git add . && git commit -m "Bootstrap config"

# Option 2: Allow dirty (not recommended)
echo 'ALLOW_DIRTY="true"' >> _build/bootstrap_scripts/bootstrap.conf
_build/bootstrap_scripts/run-bootstrap.sh --all
```

### Command Timeout

```bash
# If pnpm install takes > 900 seconds, increase timeout
sed -i 's/MAX_CMD_SECONDS="900"/MAX_CMD_SECONDS="1800"/' bootstrap.conf

# Re-run
_build/bootstrap_scripts/run-bootstrap.sh --all
```

---

## What Each Phase Does

| Phase | Tech Dir | Scripts | What It Sets Up |
|-------|----------|---------|-----------------|
| **00-foundation** | foundation/ | 4 | Next.js app, TypeScript, package engines, directories |
| **01-docker** | docker/ | 3 | Dockerfile, docker-compose.yml, pnpm cache |
| **02-database** | db/ | 4 | Drizzle ORM, schema, migrations, DB client |
| **03-security** | env/ | 4 | .env validation, Zod schemas, rate limiter, server actions |
| **04-auth** | auth/ | 2 | Auth.js v5 setup, authentication routes |
| **05-ai** | ai/ | 3 | Vercel AI SDK, prompts, chat feature |
| **06-state** | state/ | 2 | Zustand setup, session state lib |
| **07-jobs** | jobs/ | 2 | PG Boss setup, job worker template |
| **08-observability** | observability/ | 2 | Pino logger, pretty printer |
| **09-ui** | ui/ | 3 | shadcn/ui, react-to-print, components |
| **10-testing** | testing/ | 3 | Vitest, Playwright, test directory |
| **11-quality** | quality/ | 3 | ESLint, Prettier, Husky, lint-staged |

**Total**: 35 scripts, ~8-10 minutes runtime + breakpoint pauses

---

## For Developers

### Modifying a Script

All 35 scripts already support:
- `mark_script_success "tech/script-name.sh"` (called automatically)
- `run_cmd "command"` (respects DRY_RUN, timeouts)
- Config variables (PKG_*, ENABLE_*, DB_*, etc.)
- Idempotent operations (safe to re-run)

### Adding a New Script

1. Create file: `_build/bootstrap_scripts/tech_stack/{category}/{name}.sh`
2. Add to `bootstrap.conf` BOOTSTRAP_STEPS_DEFAULT in correct order
3. Script automatically gets state tracking and config access
4. Run `bootstrap --all` to test

### Debugging

```bash
# Verbose output shows all commands
_build/bootstrap_scripts/run-bootstrap.sh --all --verbose

# Check logs
tail -f logs/bootstrap-*.log

# Dry-run to preview
_build/bootstrap_scripts/run-bootstrap.sh --all --dry-run
```

---

## Next Steps

1. **Review**: `BOOTSTRAP_IMPLEMENTATION_COMPLETE.md` for technical details
2. **Preview**: `_build/bootstrap_scripts/run-bootstrap.sh --all --dry-run`
3. **Customize**: Edit `bootstrap.conf` if needed
4. **Execute**: `_build/bootstrap_scripts/run-bootstrap.sh --all`
5. **Monitor**: Check `.bootstrap_state` and `logs/` as it runs

---

**Status**: ✅ Production Ready
**All 35 scripts**: Ready to deploy
**Config system**: Fully functional
**State tracking**: Working
**Resumable runs**: Enabled

Start bootstrapping! 🚀
