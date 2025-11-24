# OmniForge v3.0 - Infinite Architectures. Instant Foundation.

**Current Status**: PRODUCTION READY
**Last Updated**: November 23, 2025

---

## Quick Start

```bash
cd _build/omniforge

# View what would run (no execution)
ALLOW_DIRTY=true omni --dry-run --list

# Initialize project (with resume capability)
omni --init

# Check progress
omni status

# Show configuration
omni status --config
```

---

## What's New in v3.0

### Modular Architecture
- **bin/** - Clean entry points for all operations
- **lib/** - Single-responsibility library modules
- **Phase metadata** - Configuration-driven phase discovery from `omniforge.conf`

### Entry Points
```bash
omni             # Main entry point (or ./omni.sh)
./bin/omni       # Main execution
./bin/forge      # Build and verify
./bin/status     # Show status, list phases, view config
```

### Library Modules
| Module | Functions | Purpose |
|--------|-----------|---------|
| `logging.sh` | `log_info`, `log_error`, `log_debug`, etc. | Colored and JSON logging |
| `config_bootstrap.sh` | `config_load`, `config_validate`, `config_apply_profile` | Configuration management |
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
_build/omniforge/
├── bin/                              # Entry point scripts
│   ├── omni                          # Main execution
│   ├── forge                         # Build/verify after init
│   └── status                        # Status, list, config display
├── lib/                              # Modular library files
│   ├── common.sh                     # Master loader (sources all modules)
│   ├── logging.sh                    # Logging functions
│   ├── config_bootstrap.sh           # Configuration loading
│   ├── phases.sh                     # Phase discovery & execution
│   ├── packages.sh                   # PKG_* expansion, dependencies
│   ├── state.sh                      # State tracking
│   ├── git.sh                        # Git safety checks
│   ├── validation.sh                 # Requirement validation
│   └── utils.sh                      # General utilities
├── tech_stack/                       # Scripts by technology
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
├── example-files/                    # Configuration templates
├── settings-files/                   # App-specific settings
├── omni.sh                           # Main CLI entry point
├── bootstrap.conf                    # Active configuration
└── .omniforge_state                  # Runtime state tracking
```

### Configuration-Driven Phases

Phases are defined in `bootstrap.conf` using `PHASE_METADATA_N` variables:

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
# Primary CLI
omni --init                    # Initialize project
omni --help                    # Show help
omni run                       # Run all phases
omni run --dry-run             # Preview execution
omni run --phase 0             # Run only phase 0
omni run --force               # Ignore state, re-run all
omni list                      # List phases
omni status                    # Show status
omni build                     # Build and verify (alias: forge)
omni reset                     # Reset last deployment
omni reset --yes               # Reset without confirmation

# Direct bin/ access
./bin/omni                     # Main execution
./bin/omni --dry-run           # Preview all actions
./bin/omni --phase 0           # Run only phase 0
./bin/omni --list              # List all phases
./bin/omni --status            # Show status

./bin/status                   # Show completion status
./bin/status --list            # List all phases
./bin/status --config          # Show configuration
./bin/status --clear           # Clear all state

./bin/forge                    # Build and verify
./bin/forge --skip-build       # Skip build step

./bin/reset                    # Reset deployment
./bin/reset --yes              # Non-interactive reset
./bin/reset --help             # Reset help
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
ALLOW_DIRTY=true omni run --dry-run
```

**Full initialization with dirty working tree:**
```bash
ALLOW_DIRTY=true omni --init
```

**CI/CD non-interactive mode:**
```bash
NON_INTERACTIVE=true omni run
```

**JSON logging for CI/CD:**
```bash
LOG_FORMAT=json omni run > omniforge.json 2>&1
```

**Reset and redeploy:**
```bash
omni reset --yes    # Reset deployment
omni run            # Fresh initialization
omni build          # Verify build
```

---

## Resetting Deployments

OmniForge provides a safe reset system that deletes deployment artifacts while preserving the OmniForge system and all improvements.

### Reset Commands

```bash
omni reset              # Interactive mode (confirm before delete)
omni reset --yes        # Non-interactive mode (auto-confirm)
omni reset --help       # Show reset help
```

### What Gets Deleted

- **Root config files**: `package.json`, `tsconfig.json`, `next.config.ts`, etc.
- **Source directory**: `src/` (all source files)
- **Test directories**: `e2e/`
- **Build artifacts**: `.next/`, `node_modules/`
- **State files**: `.bootstrap_state`, lock files

### What Gets Preserved

- **OmniForge system**: `_build/omniforge/` (entire OmniForge system)
- **OmniForge improvements**: All enhancements and fixes
- **Claude Code config**: `.claude/`
- **Documentation**: `docs/`
- **Git repository**: `.git/`
- **Backups**: `_backup/`

### Automatic Backup

Before deletion, `omni reset` automatically creates a timestamped backup:

```
_backup/deployment-YYYYMMDD-HHMMSS/
├── manual-fixes/           # Manually created files
├── package.json            # Package manifest
├── tsconfig.json           # TypeScript config
└── .bootstrap_state        # Bootstrap state
```

### Restore from Backup

If needed, restore from the latest backup:

```bash
# Find latest backup
ls -lt _backup/

# Restore manual fixes
cp _backup/deployment-YYYYMMDD-HHMMSS/manual-fixes/*.ts src/lib/
```

### Full Reset Cycle

1. **Reset**: `omni reset --yes`
2. **Deploy**: `omni run`
3. **Build**: `omni build`
4. **Test**: `pnpm dev`

### Use Cases

- **Test different configurations**: Reset, modify `bootstrap.conf`, redeploy
- **Fix build errors**: Reset, redeploy with fixes
- **Clean slate**: Reset and start fresh
- **Development iteration**: Quick reset for testing

See [RESET-QUICKREF.md](docs/RESET-QUICKREF.md) for complete reset documentation.

---

## Phases (6 Phases)

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

### Configuration (lib/config_bootstrap.sh)
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

## Error Handling

### Git Safety Errors
```bash
[ERROR] Git working directory is not clean
[ERROR] Use ALLOW_DIRTY=true to override this check.

# Solution:
ALLOW_DIRTY=true omni --init
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
omni --init
```

---

## Version History

- **v3.0** (Current) - OmniForge rebrand with modular architecture
  - 8 single-responsibility library modules
  - Configuration-driven phase discovery
  - Clean entry points: `omni`, `forge`, `status`
  - Industrial-strength CLI

- **v2.0** - Config-driven orchestrator
  - Resume capability
  - 43 total scripts

- **v1.0** - Legacy phase-based system

---

## Docker Integration

All OmniForge solutions are built inside Docker containers, ensuring consistent development and production environments.

### Docker Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    docker-compose.yml                           │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │      app        │  │    postgres     │  │     redis       │ │
│  │  (Next.js dev)  │  │   (pgvector)    │  │   (optional)    │ │
│  │   Port: 3000    │  │   Port: 5432    │  │   Port: 6379    │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### Docker Files Created

| File | Purpose |
|------|---------|
| `Dockerfile` | Multistage production build |
| `Dockerfile.dev` | Development with hot reload |
| `.dockerignore` | Build context exclusions |
| `docker-compose.yml` | Full development stack |
| `docker-compose.prod.yml` | Production override |
| `Makefile` | Docker command shortcuts |
| `.docker/cache-config.sh` | BuildKit cache settings |

### Docker Commands

```bash
# Development
make dev                      # Start development stack
make dev-build                # Rebuild and start
make logs                     # Follow all logs
make shell                    # Shell into app container
make db-shell                 # PostgreSQL shell

# Production
make build                    # Build production image
make prod                     # Run production locally
make push                     # Push to registry

# Utilities
make clean                    # Remove containers/images
./scripts/docker-dev.sh       # Helper script menu
```

### Configuration (bootstrap.conf)

```bash
# Docker Configuration
ENABLE_DOCKER="true"
DOCKER_EXEC_MODE="container"    # host|container
ENABLE_REDIS="false"
DOCKER_REGISTRY="ghcr.io"
DOCKER_BUILDKIT="1"
```

### Validation Functions (lib/validation.sh)

```bash
require_docker                 # Check Docker installed and running
require_docker_compose         # Check Compose v2 or standalone
require_buildkit               # Check BuildKit enabled
require_docker_env             # Full Docker environment check
```

---

**Status**: PRODUCTION READY
**Architecture**: Modular bin/lib pattern with Docker-first execution
**Total Scripts**: 46+
**Last Updated**: 2025-11-24
