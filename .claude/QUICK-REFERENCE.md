# bloom2 Bootstrap - Quick Reference

## Project Location
```bash
cd /Users/luce/_dev/bloom2
```

## Key Files (Read These First)

| File | Size | Purpose |
|------|------|---------|
| `./.claude/CLAUDE.md` | 2KB | Project constraints & principles |
| `./.claude/REFACTORING-PLAN.md` | 8KB | 10-phase blueprint |
| `./.claude/SETUP-SUMMARY.md` | 5KB | What's been created |
| `_build/bootstrap_scripts/bootstrap.conf` | 451 lines | Configuration (single source of truth) |
| `_build/bootstrap_scripts/lib/common.sh` | 716 lines | Existing utilities to extract |
| `_build/bootstrap_scripts/run-bootstrap.sh` | 556 lines | Orchestrator |

## Work Mode Shortcuts

Switch profiles during a session:
```bash
/profile-researcher              # Understand the code first
/profile-code-writer             # Write the implementation
/profile-code-reviewer           # Review what we wrote
/profile-documenter              # Write documentation
/profile-debugger                # Fix issues
```

## Refactoring Phases (Quick Overview)

| # | Title | Files to Create | Effort |
|---|-------|-----------------|--------|
| 1 | Library Extraction | 5 new lib files | ★★★★☆ |
| 2 | Consolidate Orchestrators | 1 merged file | ★★☆☆☆ |
| 3 | Error Recovery | 1 lib file | ★★★☆☆ |
| 4 | Package Manager | 1 lib file | ★★★☆☆ |
| 5 | Implement 39+ Scripts | modules/ dirs | ★★★★★ |
| 6 | Config Organization | 1 new file | ★☆☆☆☆ |
| 7 | State Management | 1 lib file | ★★★☆☆ |
| 8 | Documentation | 5+ doc files | ★★★☆☆ |
| 9 | Testing | Test suites | ★★★★☆ |
| 10 | Migration & Rollback | Scripts | ★★☆☆☆ |

## Current Architecture

```
_build/bootstrap_scripts/
├── lib/
│   └── common.sh                    # Need to extract into 5 modules
├── bootstrap.conf                   # Unchanged (single source of truth)
├── run-bootstrap.sh                 # Orchestrator
└── tech_stack/
    ├── export/                      # 5 scripts
    ├── intelligence/                # 4 scripts
    └── monitoring/                  # 3 scripts
    # Missing: 27+ scripts (to be implemented)
```

## Target Architecture

```
_build/bootstrap_scripts/
├── lib/
│   ├── common.sh                    # Core utilities (source new libs)
│   ├── logging.sh                   # NEW: Logging functions
│   ├── config.sh                    # NEW: Config loading & validation
│   ├── state.sh                     # NEW: State file operations
│   ├── validation.sh                # NEW: Pre-flight checks
│   ├── platform.sh                  # NEW: OS detection
│   ├── error-handling.sh            # NEW: Retry & recovery
│   └── package-manager.sh           # NEW: pnpm/npm utilities
│
├── modules/
│   ├── foundation/                  # Phase 0 (NEW)
│   ├── infrastructure/              # Phase 1 (NEW)
│   ├── core-features/               # Phase 2 (NEW)
│   ├── ui-components/               # Phase 3 (NEW)
│   ├── extensions/                  # Phase 4 (NEW)
│   └── observability/               # Phase 4 alt (NEW)
│
├── bootstrap.conf                   # UNCHANGED
└── run-bootstrap.sh                 # Consolidated
```

## Critical Constraints

🚫 **Do NOT**
- Modify `bootstrap.conf` structure (only add clarity with comments)
- Use Python (Bash 7+ only)
- Create write operations
- Break backward compatibility

✅ **DO**
- Keep `bootstrap.conf` as single source of truth
- Maintain phase system (0-5)
- Source libraries instead of duplicating code
- Test after each phase
- Document changes

## Bootstrap System 101

### How It Works
1. User runs `./run-bootstrap.sh -SubscriptionId <ID>`
2. Loads `bootstrap.conf` (all settings)
3. Sources `lib/common.sh` (shared functions)
4. Executes phases 0-5 sequentially
5. Each phase runs multiple scripts in order
6. State tracked in `.bootstrap_state` (prevents duplicates)

### Configuration Hierarchy
```
bootstrap.conf (primary)
├── Identity & Paths
├── Runtime Versions
├── Database Config
├── Environment Variables
├── Feature Flags (ENABLE_*)
├── Package Definitions (PKG_*)
└── Phase System (PHASE_*, BOOTSTRAP_PHASE_*)

defaults.conf (fallback - NEW)
└── Default values if not in bootstrap.conf
```

### Phase System
- **Phase 0**: Foundation (Next.js, TypeScript, Git hooks)
- **Phase 1**: Infrastructure (Docker, PostgreSQL, Drizzle)
- **Phase 2**: Core Features (Auth, AI/LLM, state, jobs)
- **Phase 3**: UI (shadcn/ui, Tailwind, components)
- **Phase 4**: Extensions (Intelligence, exports, testing)
- **Phase 5**: Custom (User-defined)

## Commands Reference

### Execution Modes
```bash
# Run everything (Phase 0-5)
./run-bootstrap.sh -SubscriptionId <ID>

# Run specific phase
./run-bootstrap.sh -SubscriptionId <ID> -Phase 2

# Run specific script
./run-bootstrap.sh -SubscriptionId <ID> -Script "core-features/authjs-setup.sh"

# Resume after error
./run-bootstrap.sh -SubscriptionId <ID> -Resume

# Interactive mode
./run-bootstrap.sh -SubscriptionId <ID> -Interactive
```

### Environment Variables
```bash
# Load config from file (instead of defaults)
azenv=./custom-azure.json ./run-bootstrap.sh

# Non-interactive mode (CI/automation)
NON_INTERACTIVE=true ./run-bootstrap.sh

# Verbose logging
VERBOSE_LOGGING=true ./run-bootstrap.sh

# Dry-run (show what would happen)
DRY_RUN=true ./run-bootstrap.sh
```

## Getting Started

### To Start Phase 1 (Library Extraction)
```bash
# 1. Read the current implementation
# Open: _build/bootstrap_scripts/lib/common.sh

# 2. Plan library modules (look at REFACTORING-PLAN.md Phase 1)

# 3. Use this profile
/profile-code-writer

# 4. Create lib/logging.sh with all logging functions

# 5. Mark first todo as in_progress
# (I'll manage this for you)
```

### File Operations Cheatsheet
```bash
# View current structure
ls -la _build/bootstrap_scripts/

# Check line count
wc -l _build/bootstrap_scripts/lib/common.sh

# Test bash syntax
bash -n _build/bootstrap_scripts/lib/common.sh

# View config
head -50 _build/bootstrap_scripts/bootstrap.conf

# View state
cat .bootstrap_state
```

## Troubleshooting

### Script fails to source library
**Fix**: Verify library exists and `source` path is correct

### State file gets corrupted
**Fix**: Delete `.bootstrap_state`, scripts will rerun from beginning

### Config values not loading
**Fix**: Check `bootstrap.conf` has the variable; verify file encoding is UTF-8

### Phase skipped unexpectedly
**Fix**: Check `.bootstrap_state` has incomplete entry; remove it to retry

## Profile Descriptions

### 🚀 Code Writer
- Focus on clean implementation
- Write self-documenting code
- Keep functions small and testable
- Don't refactor surrounding code

### 🔍 Code Reviewer
- Check for bugs, security, performance issues
- Verify error handling and edge cases
- Look for code duplication
- Test coverage adequate?

### 📚 Documenter
- Explain the "why" not the "what"
- Include examples and diagrams
- Clear structure and hierarchy
- Target: developers and users

### 🐛 Debugger
- Root cause analysis
- Minimal, targeted fixes
- Verify no regressions
- Explain why the bug occurred

### 🔬 Researcher
- Explore the codebase systematically
- Map architecture and dependencies
- Ask clarifying questions
- Understand context before proposing changes

---

## Resources

📄 **Documentation**
- `./.claude/CLAUDE.md` - Project principles
- `./.claude/REFACTORING-PLAN.md` - Detailed phases
- `./.claude/SETUP-SUMMARY.md` - What's been created
- `./docs/README.md` - Technology guides

🎯 **Architecture**
- `_build/bootstrap_scripts/bootstrap.conf` - Configuration
- `_build/bootstrap_scripts/lib/common.sh` - Current utilities
- `_build/bootstrap_scripts/run-bootstrap.sh` - Orchestrator

📋 **Tasks**
- Check your todo list for current phase progress
- Each task shows what to implement and test

---

## One-Minute Summary

**Project**: bloom2 Bootstrap System (sophisticated Phase-based initialization)

**Goal**: Refactor from monolithic to modular architecture

**Approach**: 10 phases over multiple Claude Code sessions

**Key Principle**: bootstrap.conf stays as single source of truth

**Constraint**: No Python, Bash 7+ only, read-only execution

**Next Step**: Phase 1 - Extract 5 focused library modules from common.sh

**Ready?** Use `/profile-code-writer` to begin Phase 1!
