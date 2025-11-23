# Bloom2 Bootstrap Orchestrator v3.0

**Current Status**: PRODUCTION READY
**Last Updated**: November 23, 2025

---

## Quick Start

```bash
cd _build/bootstrap_scripts

# View what would run (no execution)
ALLOW_DIRTY=true ./bin/bootstrap --dry-run --list

# Full bootstrap (with resume capability)
./bin/bootstrap

# Check progress
./bin/status

# Show configuration
./bin/status --config
```

---

## What's New in v3.0

### Modular Architecture
- **bin/** - Clean entry points for all operations
- **lib/** - Single-responsibility library modules
- **Phase metadata** - Configuration-driven phase discovery from `bootstrap.conf`

### New Entry Points
```bash
./bin/bootstrap    # Main bootstrap execution
./bin/compile      # Build and verify after bootstrap
./bin/status       # Show status, list phases, view config
```

### Library Modules
| Module | Functions | Purpose |
|--------|-----------|---------|
| `logging.sh` | `log_info`, `log_error`, `log_debug`, etc. | Colored and JSON logging |
| `config.sh` | `config_load`, `config_validate`, `config_apply_profile` | Configuration management |
| `phases.sh` | `phase_discover`, `phase_execute`, `phase_list_all` | Dynamic phase discovery |
| `packages.sh` | `pkg_expand`, `pkg_add_dependency`, `pkg_add_script` | Package management |
| `state.sh` | `state_mark_success`, `state_has_succeeded`, `state_clear` | Resume capability |
| `git.sh` | `git_ensure_clean`, `git_is_repo` | Git safety checks |
| `validation.sh` | `require_cmd`, `require_node_version`, `require_pnpm` | Dependency validation |
| `utils.sh` | `run_cmd`, `ensure_dir`, `write_file` | General utilities |
| `common.sh` | Loads all modules | Master loader |

---

## System Architecture

### Directory Structure

```
_build/bootstrap_scripts/
├── bin/                              # Entry point scripts
│   ├── bootstrap                     # Main bootstrap execution
│   ├── compile                       # Build/verify after bootstrap
│   └── status                        # Status, list, config display
├── lib/                              # Modular library files
│   ├── common.sh                     # Master loader (sources all modules)
│   ├── logging.sh                    # Logging functions
│   ├── config.sh                     # Configuration loading
│   ├── phases.sh                     # Phase discovery & execution
│   ├── packages.sh                   # PKG_* expansion, dependencies
│   ├── state.sh                      # Bootstrap state tracking
│   ├── git.sh                        # Git safety checks
│   ├── validation.sh                 # Requirement validation
│   └── utils.sh                      # General utilities
├── tech_stack/                       # Bootstrap scripts by technology
│   ├── foundation/                   # Next.js, TypeScript (4 scripts)
│   ├── docker/                       # Docker, Compose (3 scripts)
│   ├── db/                           # Drizzle ORM (4 scripts)
│   ├── env/                          # Environment, Zod (4 scripts)
│   ├── auth/                         # Auth.js (2 scripts)
│   ├── ai/                           # Vercel AI SDK (3 scripts)
│   ├── state/                        # Zustand (2 scripts)
│   ├── jobs/                         # PgBoss (2 scripts)
│   ├── observability/                # Pino logger (2 scripts)
│   ├── intelligence/                 # AI engines (4 scripts)
│   ├── export/                       # Multi-format export (5 scripts)
│   ├── monitoring/                   # Health, flags (3 scripts)
│   ├── ui/                           # Shadcn UI (3 scripts)
│   ├── testing/                      # Vitest, Playwright (3 scripts)
│   └── quality/                      # ESLint, Prettier (3 scripts)
├── example/                          # Configuration templates
├── bootstrap.conf                    # Active configuration
├── run-bootstrap.sh                  # Legacy wrapper (delegates to bin/)
└── .bootstrap_state                  # Runtime state tracking
```

### Configuration-Driven Phases

Phases are now defined in `bootstrap.conf` using `PHASE_METADATA_N` variables:

```bash
# Phase definition format
PHASE_METADATA_0="number:0|name:Project Foundation|description:Initialize Next.js..."
PHASE_CONFIG_00_FOUNDATION="enabled:true|timeout:300|prereq:strict|deps:node:20,pnpm:9"
PHASE_PACKAGES_00_FOUNDATION="PKG_NEXT|PKG_TYPESCRIPT|PKG_TYPES_NODE|PKG_TYPES_REACT"
BOOTSTRAP_PHASE_00_FOUNDATION="
foundation/init-nextjs.sh
foundation/init-typescript.sh
"
```

---

## Usage Guide

### Commands

```bash
# NEW: Recommended entry points
./bin/bootstrap                    # Run all phases
./bin/bootstrap --dry-run          # Preview execution
./bin/bootstrap --phase 0          # Run only phase 0
./bin/bootstrap --force            # Ignore state, re-run all
./bin/bootstrap --list             # List phases
./bin/bootstrap --status           # Show status

./bin/status                       # Show completion status
./bin/status --list                # List all phases
./bin/status --config              # Show configuration
./bin/status --clear               # Clear all state

./bin/compile                      # Build and verify
./bin/compile --skip-build         # Skip build step

# LEGACY: Still works (delegates to bin/)
./run-bootstrap.sh run             # Run all phases
./run-bootstrap.sh list            # List phases
./run-bootstrap.sh status          # Show status
```

### Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `DRY_RUN` | false | Preview mode, no execution |
| `VERBOSE` | false | Detailed debug output |
| `ALLOW_DIRTY` | false | Skip git clean check |
| `GIT_SAFETY` | true | Require clean git repo |
| `LOG_FORMAT` | plain | Output format (plain/json) |
| `STACK_PROFILE` | full | Feature profile (minimal/api-only/full) |

### Common Scenarios

**First-time setup with preview:**
```bash
ALLOW_DIRTY=true ./bin/bootstrap --dry-run
```

**Full bootstrap with dirty working tree:**
```bash
ALLOW_DIRTY=true ./bin/bootstrap
```

**CI/CD non-interactive mode:**
```bash
NON_INTERACTIVE=true ./bin/bootstrap
```

**JSON logging for CI/CD:**
```bash
LOG_FORMAT=json ./bin/bootstrap > bootstrap.json 2>&1
```

**Reset and restart:**
```bash
./bin/status --clear
./bin/bootstrap
```

---

## Bootstrap Phases (6 Phases)

### Phase 0: Project Foundation
- Next.js 15, TypeScript, directory structure
- 4 scripts

### Phase 1: Infrastructure & Database
- Docker, PostgreSQL, Drizzle ORM, environment
- 11 scripts (longest phase)

### Phase 2: Core Features
- Auth.js, AI SDK, Zustand, PgBoss, logging
- 11 scripts

### Phase 3: User Interface
- Shadcn UI, react-to-print, component structure
- 3 scripts

### Phase 4: Extensions & Quality
- Intelligence engines, export system, testing, quality
- 21 scripts

### Phase 5: User-Defined
- Custom scripts without modifying core phases
- Extendable

---

## Library API Reference

### Logging (lib/logging.sh)
```bash
log_info "Message"           # Green [INFO]
log_warn "Warning"           # Yellow [WARN]
log_error "Error"            # Red [ERROR]
log_debug "Debug"            # Cyan [DEBUG] (if VERBOSE=true)
log_step "Step name"         # Blue [STEP]
log_success "Done"           # Green [OK]
log_skip "Already done"      # Yellow [SKIP]
log_dry "Would do X"         # Cyan [DRY RUN]
log_init "script-name"       # Initialize logging
```

### Configuration (lib/config.sh)
```bash
config_load                  # Load bootstrap.conf
config_validate              # Validate required settings
config_apply_profile         # Apply STACK_PROFILE overrides
```

### Phases (lib/phases.sh)
```bash
phase_discover               # Find all PHASE_METADATA_N
phase_execute "0" "$dir"     # Execute phase 0
phase_execute_all "$dir"     # Execute all phases
phase_list_all               # Display all phases
phase_get_name "0"           # Get phase name
phase_is_enabled "0"         # Check if enabled
```

### Packages (lib/packages.sh)
```bash
pkg_expand "PKG_NEXT"        # Expand to "next@15"
pkg_is_enabled "PKG_X|enabled:false"  # Check if enabled
pkg_add_dependency "next@15" # Add to package.json
pkg_add_script "dev" "next dev"       # Add npm script
```

### State (lib/state.sh)
```bash
state_init                   # Initialize state file
state_mark_success "key"     # Mark script complete
state_has_succeeded "key"    # Check if completed
state_clear "key"            # Clear specific state
state_clear_all              # Clear all state
state_show_status            # Display status
```

### Git (lib/git.sh)
```bash
git_ensure_clean             # Check working tree
git_is_repo                  # Check if git repo
git_current_branch           # Get current branch
```

### Validation (lib/validation.sh)
```bash
require_cmd "pnpm" "Install hint"     # Require command
require_node_version "20"              # Require Node.js version
require_pnpm                           # Require pnpm
require_docker                         # Require Docker
require_file "path" "hint"            # Require file exists
require_project_root                   # Require package.json
```

### Utils (lib/utils.sh)
```bash
run_cmd "pnpm install"       # Execute with timeout
ensure_dir "/path"           # Create directory
write_file "/path" "content" # Create file
add_gitkeep "/path"          # Create .gitkeep
confirm "Continue?"          # User confirmation
```

---

## Backward Compatibility

The v3.0 architecture maintains backward compatibility:

1. **run-bootstrap.sh** - Now delegates to bin/bootstrap
2. **Legacy functions** - Aliased in common.sh:
   - `_init_config()` -> `config_load && config_validate`
   - `mark_script_success()` -> `state_mark_success()`
   - `has_script_succeeded()` -> `state_has_succeeded()`
   - `ensure_git_clean()` -> `git_ensure_clean()`
   - `add_dependency()` -> `pkg_add_dependency()`

---

## Error Handling

### Git Safety Errors
```bash
[ERROR] Git working directory is not clean
[ERROR] Use ALLOW_DIRTY=true to override this check.

# Solution:
ALLOW_DIRTY=true ./bin/bootstrap
```

### Missing Dependencies
```bash
[ERROR] Required: pnpm - Install from https://pnpm.io

# Solution: Install the dependency
```

### Script Failures
```bash
[ERROR] Phase 0 (Project Foundation) failed at: foundation/init-nextjs.sh

# Solution: Fix issue, then resume (auto-skips completed)
./bin/bootstrap
```

---

## Version History

- **v3.0** (Current) - Modular architecture with bin/lib separation
  - 8 single-responsibility library modules
  - Configuration-driven phase discovery
  - Clean entry points in bin/
  - Backward-compatible legacy wrapper

- **v2.0** - Config-driven orchestrator
  - Resume capability
  - 43 total scripts

- **v1.0** - Legacy phase-based system

---

**Status**: PRODUCTION READY
**Architecture**: Modular bin/lib pattern
**Total Scripts**: 43+
**Last Updated**: 2025-11-23
