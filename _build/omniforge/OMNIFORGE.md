# OmniForge v3.0 - Infinite Architectures. Instant Foundation.

**Codename**: OmniForge
**CLI**: `omni`
**Current Status**: PRODUCTION READY
**Last Updated**: November 24, 2025
**Architecture**: Modular bin/lib pattern with 26 library modules and 57 tech_stack scripts

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [What is OmniForge?](#what-is-omniforge)
3. [Architecture Overview](#architecture-overview)
4. [Directory Structure](#directory-structure)
5. [Configuration System](#configuration-system)
6. [Phase System](#phase-system)
7. [Library Modules (26 modules, 10,344 lines)](#library-modules)
8. [Tech Stack (57 scripts across 18 categories)](#tech-stack)
9. [CLI Reference](#cli-reference)
10. [Environment Variables](#environment-variables)
11. [Error Handling](#error-handling)
12. [Resetting Deployments](#resetting-deployments)
13. [Extensibility & Development](#extensibility--development)
14. [Version History](#version-history)

---

## Quick Start

```bash
cd _build/omniforge

# View what would run (dry-run mode)
ALLOW_DIRTY=true omni --dry-run --list

# Initialize project for the first time
omni --init

# Check progress
omni status

# View full configuration
omni status --config

# Run all phases
omni run

# Run a specific phase (e.g., phase 0)
omni run --phase 0

# Build and verify
omni build
```

### First Time Setup Recommended Path

```bash
# 1. Interactive setup wizard (recommended)
omni menu

# 2. Or direct full initialization
ALLOW_DIRTY=true omni --init

# 3. Check what was done
omni status

# 4. Build and test
omni build
pnpm dev  # Start development server
```

---

## What is OmniForge?

### Purpose

OmniForge is a **production-grade, phase-based project initialization framework** that orchestrates the setup of sophisticated Next.js + TypeScript + PostgreSQL + AI applications. It transforms a blank directory into a fully-configured, deployable application stack in minutes.

### Design Principles

- **Configuration-Driven**: Canonical config in omni.* files (`omni.config`, `omni.settings.sh`, `omni.profiles.sh`, `omni.phases.sh`) — `bootstrap.conf` is deprecated/legacy only
- **Deterministic**: Same inputs always produce identical outputs
- **Resume-Capable**: Interrupted runs resume from last successful phase via state tracking
- **Extensible**: Add custom phases, tech stacks, or profiles without modifying core
- **Self-Contained**: Project-local Node.js and pnpm installation in `.tools/` directory
- **Modular**: 26 library modules with single responsibilities, no circular dependencies
- **Idempotent**: Running the same phase multiple times is safe; skips already-completed tasks

### Functionality

OmniForge automatically:

- **Discovers** all phases from omni.phases metadata
- **Manages** 57 technology-specific scripts across 18 categories
- **Orchestrates** sequential installation with error recovery
- **Tracks** state for intelligent resume capability
- **Validates** prerequisites and remediates missing dependencies
- **Logs** all activity with color-coded, rotatable output
- **Applies** pre-configured stack profiles (6 templates for common use cases)
- **Installs** project-local tools (Node.js, pnpm) without system pollution

### Use Cases

- **Project Initialization**: Set up new applications from scratch in minutes
- **CI/CD Pipelines**: Deterministic, non-interactive initialization for automation
- **Environment Replication**: Recreate identical setups across machines
- **Development Iteration**: Quick reset/redeployment when testing configuration changes
- **Stack Composition**: Mix and match tech stacks via profiles and feature flags
- **Infrastructure as Code**: Define entire application architecture in omni.* metadata

---

## Architecture Overview

### System Design

```
┌─────────────────────────────────────────────────────────────────┐
│                   omni.sh (entry point)                         │
└──────────────────┬──────────────────────────────────────────────┘
                   │
                   ├─> [validates files & environment]
                   │
                   ├─> [shows logo & help]
                   │
                   └─> delegates to bin/omni (main orchestrator)
                           │
                           ├─> sources lib/common.sh
                           │       │
                           │       └─> loads all 26 library modules
                           │           (logging, config, phases, state, etc.)
                           │
                           ├─> phase_discover() → reads PHASE_METADATA_*
                           │
                           ├─> phase_execute_all() → runs phases in sequence
                           │       │
                           │       └─> for each phase:
                           │           - state_has_succeeded() check
                           │           - sequencer_run() with timeout
                           │           - state_mark_success() on completion
                           │
                           └─> reports results & exits

┌─────────────────────────────────────────────────────────────────┐
│              Phase Execution Flow (Detailed)                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  phase_execute(phase_number)                                    │
│      ├─> phase_is_enabled() check (enable:true/false)           │
│      │                                                          │
│      ├─> phase_get_scripts() → reads BOOTSTRAP_PHASE_XX_*       │
│      │                                                          │
│      ├─> phase_get_packages() → expands PKG_* definitions       │
│      │                                                          │
│      ├─> for each script in phase:                              │
│      │   ├─> state_has_succeeded() → SKIP if already done       │
│      │   │                                                      │
│      │   ├─> run_cmd() with phase timeout                       │
│      │   │   (sequencer handles retries, test criteria)         │
│      │   │                                                      │
│      │   └─> state_mark_success() on completion                 │
│      │                                                          │
│      └─> report phase results                                   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

Bootstrap Execution State (.bootstrap_state):
    foundation/init-nextjs.sh=success:2025-11-24T15:30:45
    foundation/init-typescript.sh=success:2025-11-24T15:31:12
    docker/docker-compose-pg.sh=success:2025-11-24T15:35:22
    ...
```

### Data Flow

```
omni.config (Section 1, top-level app settings)
    ├─ APP_NAME, APP_VERSION, INSTALL_TARGET
    ├─ STACK_PROFILE
    ├─ DB_NAME, DB_USER, DB_PASSWORD, DB_HOST, DB_PORT
    └─ ENABLE_* feature flags

omni.settings.sh (advanced/system settings & derived values)
    ├─ Preflight/logging/docker/safety flags
    ├─ Framework versions (Node, pnpm, PostgreSQL, etc.)
    ├─ Project paths & directories
    ├─ Tool locations (.tools/node, .tools/pnpm)
    └─ Derived values (INSTALL_DIR, markers, git remote)

omni.profiles.sh (profile data)
    ├─ PROFILE_* associative arrays
    └─ AVAILABLE_PROFILES ordering

omni.phases.sh (phase metadata)
    ├─ PHASE_METADATA_N (phase name, description, enabled)
    ├─ PHASE_CONFIG_NN_* (timeout, prereq, dependencies)
    ├─ PHASE_PACKAGES_NN_* (npm package list)
    └─ BOOTSTRAP_PHASE_NN_* (scripts to execute)
```

---

## Directory Structure

```
_build/omniforge/
├── bin/                                    # Entry point scripts (modular)
│   ├── omni                                # Main execution (delegates to phases)
│   ├── forge                               # Build and verify
│   ├── status                              # Show status and config
│   ├── reset                               # Safe reset system
│   ├── menu                                # Interactive setup wizard
│   └── [others...]
│
├── lib/                                    # Library modules (26 modules, 10,344 LOC)
│   ├── common.sh                           # Master loader (sources all modules)
│   ├── logging.sh                          # Logging with colors & rotation
│   ├── log-rotation.sh                     # Log cleanup & archival
│   ├── config_bootstrap.sh                 # Configuration loading
│   ├── config_validate.sh                  # Configuration validation
│   ├── config_deploy.sh                    # Deployment configuration
│   ├── phases.sh                           # Phase discovery & execution
│   ├── state.sh                            # State tracking & resume
│   ├── sequencer.sh                        # Sequential execution with timeouts
│   ├── packages.sh                         # NPM package management
│   ├── git.sh                              # Git safety checks
│   ├── validation.sh                       # Dependency validation
│   ├── utils.sh                            # General utilities
│   ├── prereqs.sh                          # System prerequisites
│   ├── prereqs-local.sh                    # Local tool installation
│   ├── setup.sh                            # One-time project setup
│   ├── setup_wizard.sh                     # Interactive configuration wizard
│   ├── auto_detect.sh                      # Project auto-detection
│   ├── scaffold.sh                         # Template deployment
│   ├── bakes.sh                            # Configuration presets
│   ├── indexer.sh                          # Script indexing & discovery
│   ├── ascii.sh                            # ASCII art & branding
│   ├── downloads.sh                        # Download caching
│   ├── settings_manager.sh                 # IDE configuration
│   ├── menu.sh                             # Interactive menu framework
│   ├── reset.sh                            # Reset system
│   └── [others...]
│
├── tech_stack/                             # 57 scripts across 18 categories
│   ├── foundation/                         # Next.js, TypeScript (4 scripts)
│   │   ├── 00-nextjs.sh
│   │   ├── init-nextjs.sh
│   │   ├── init-typescript.sh
│   │   └── init-directory-structure.sh
│   │
│   ├── core/                               # Framework core (4 scripts)
│   │   ├── init-package-engines.sh
│   │   ├── init-typescript.sh
│   │   └── [others...]
│   │
│   ├── docker/                             # Docker & Compose (3 scripts)
│   │   ├── dockerfile-multistage.sh
│   │   ├── docker-compose-pg.sh
│   │   └── docker-pnpm-cache.sh
│   │
│   ├── db/                                 # Drizzle ORM (4 scripts)
│   │   ├── drizzle-setup.sh
│   │   ├── drizzle-schema-base.sh
│   │   ├── drizzle-migrations.sh
│   │   └── db-client-index.sh
│   │
│   ├── env/                                # Environment & Zod (3 scripts)
│   │   ├── env-validation.sh
│   │   └── zod-schemas-base.sh
│   │
│   ├── auth/                               # Auth.js (2 scripts)
│   │   ├── authjs-setup.sh
│   │   └── auth-routes.sh
│   │
│   ├── ai/                                 # Vercel AI SDK (3 scripts)
│   │   ├── ai-sdk.sh
│   │   └── [others...]
│   │
│   ├── state/                              # Zustand (2 scripts)
│   │   ├── zustand-setup.sh
│   │   └── session-state-lib.sh
│   │
│   ├── jobs/                               # PgBoss (2 scripts)
│   │   ├── pgboss-setup.sh
│   │   └── job-worker-template.sh
│   │
│   ├── observability/                      # Pino logger (2 scripts)
│   │   ├── pino-logger.sh
│   │   └── pino-pretty-dev.sh
│   │
│   ├── intelligence/                       # AI engines (4 scripts)
│   │   ├── confidence-engine.sh
│   │   ├── roi-engine.sh
│   │   ├── melissa-prompts.sh
│   │   └── hitl-review-queue.sh
│   │
│   ├── export/                             # Multi-format export (5 scripts)
│   │   ├── export-system.sh
│   │   ├── pdf-export.sh
│   │   ├── excel-export.sh
│   │   ├── json-export.sh
│   │   └── markdown-export.sh
│   │
│   ├── monitoring/                         # Health & flags (3 scripts)
│   │   ├── health-endpoints.sh
│   │   ├── feature-flags.sh
│   │   └── [others...]
│   │
│   ├── ui/                                 # Shadcn UI (3 scripts)
│   │   ├── shadcn-init.sh
│   │   ├── components-structure.sh
│   │   └── settings-ui.sh
│   │
│   ├── testing/                            # Vitest, Playwright (3 scripts)
│   │   ├── vitest-setup.sh
│   │   ├── playwright-setup.sh
│   │   └── [others...]
│   │
│   ├── quality/                            # ESLint, Prettier (3 scripts)
│   │   ├── eslint-prettier.sh
│   │   ├── code-quality.sh
│   │   └── husky-lintstaged.sh
│   │
│   ├── features/                           # Application features
│   │   ├── chat-feature-scaffold.sh
│   │   ├── rate-limiter.sh
│   │   ├── prompts-structure.sh
│   │   └── [others...]
│   │
│   └── _lib/                               # Tech stack utilities
│       └── [shared functions for tech_stack]
│
├── example-files/                          # Configuration templates
│   ├── .toolsrc.example                    # Tool activation script template
│   └── [other templates...]
│
├── settings-files/                         # App-specific settings
│   └── [IDE & environment configs...]
│
├── tools/                                  # Utility scripts
│   ├── validate-templates.sh               # Validate template deployment
│   ├── refactor-install-dir.sh             # Refactor install locations
│   ├── test-local-tools.sh                 # Test local tool installation
│   └── [others...]
│
├── omni.sh                                 # Main CLI entry point (wrapper)
├── omni.config                             # Section 1 config (app-facing)
├── omni.settings.sh                        # Advanced/system settings
├── omni.profiles.sh                        # Profile data
├── omni.phases.sh                          # Phase metadata
├── example-files/*.example                 # Legacy templates (bootstrap.*) and omni.* templates
├── bootstrap.conf (deprecated stub)        # Legacy placeholder only
├── OMNIFORGE.md                            # This file
├── omniforge-refactor.md                   # Refactoring notes
│
└── .omniforge_state                        # Runtime state (generated)
    # Tracks completed scripts for resume capability
```

### Statistics

- **Library Modules**: 26 files, ~10k lines of code
- **Tech Stack Scripts**: 57 scripts across 18 technology categories
- **Configuration**: omni.config + omni.settings.sh + omni.profiles.sh + omni.phases.sh (bootstrap.conf is legacy/stub)
- **Entry Points**: 3 main scripts (omni, forge, status)
- **Phases**: 6 phases (0-5) with full metadata-driven configuration
- **Stack Profiles**: 6 pre-configured templates

---

## Configuration System

- **Canonical files (loaded by lib/bootstrap.sh)**:
  - `omni.config` – Section 1 (Quick Start) and top-level app settings.
  - `omni.settings.sh` – Advanced/system settings and derived values.
  - `omni.profiles.sh` – Profile data (PROFILE_* arrays, AVAILABLE_PROFILES).
  - `omni.phases.sh` – Phase metadata (PHASE_METADATA_*, PHASE_CONFIG_*, PHASE_PACKAGES_*, BOOTSTRAP_PHASE_*).
- **Precedence**: Environment variables → omni.* values. `bootstrap.conf` is deprecated/stub only.
- **Helpers**: Profile helpers live in `lib/omni_profiles.sh`; phase logic lives in `lib/phases.sh`.
- **Examples**: Prefer omni.* example files; bootstrap.conf.example is legacy only.

## Phase System

### Overview

OmniForge uses a **6-phase initialization model** where each phase handles a logical group of dependencies and configurations. Phases are metadata-driven (defined in bootstrap.conf) and discovered dynamically.

### Phase Discovery

```bash
# OmniForge discovers all PHASE_METADATA_N variables:
PHASE_METADATA_0="number:0|name:..."
PHASE_METADATA_1="number:1|name:..."
# ... up to PHASE_METADATA_5

# For each phase, reads associated metadata:
PHASE_CONFIG_00_FOUNDATION="enabled:true|timeout:300|..."
PHASE_PACKAGES_00_FOUNDATION="PKG_NEXT|PKG_REACT|..."
BOOTSTRAP_PHASE_00_FOUNDATION="
  foundation/init-nextjs.sh
  foundation/init-typescript.sh
"
```

### The 6 Phases

#### Phase 0: Project Foundation
- **Purpose**: Initialize Next.js 15 project structure and TypeScript configuration
- **Duration**: ~5 minutes
- **Scripts**: 4
- **Key Technologies**:
  - Next.js 15 setup
  - TypeScript configuration
  - Directory structure creation
  - Package.json initialization
- **Produces**: Minimal Next.js application ready for next phases
- **Resume**: Safe to resume; checks for existing configuration

#### Phase 1: Infrastructure & Database
- **Purpose**: Set up PostgreSQL, Docker, Drizzle ORM, and environment validation
- **Duration**: ~15 minutes (longest phase, includes Docker setup)
- **Scripts**: 11 (longest phase)
- **Key Technologies**:
  - Docker & Docker Compose
  - PostgreSQL 16 with pgvector
  - Drizzle ORM setup
  - Environment validation with Zod
  - Database client configuration
- **Produces**: Containerized PostgreSQL, ORM configuration, type-safe env
- **Resume**: Skips already-created Docker containers

#### Phase 2: Core Features
- **Purpose**: Add authentication, AI integration, job queue, and observability
- **Duration**: ~10 minutes
- **Scripts**: 11
- **Key Technologies**:
  - Auth.js for authentication
  - Vercel AI SDK integration
  - Zustand state management
  - PgBoss job queue
  - Pino logging
- **Produces**: Auth routes, AI templates, job workers, structured logging
- **Resume**: Detects and skips existing feature files

#### Phase 3: User Interface
- **Purpose**: Install UI framework and create component structure
- **Duration**: ~3 minutes
- **Scripts**: 3
- **Key Technologies**:
  - Shadcn UI components
  - react-to-print for PDF printing
  - Component structure templates
- **Produces**: Ready-to-use component library and print-to-PDF system
- **Resume**: Checks for existing component directories

#### Phase 4: Extensions & Quality
- **Purpose**: Add intelligence engines, export system, testing, and code quality
- **Duration**: ~12 minutes
- **Scripts**: 21 (most scripts, best for customization)
- **Key Technologies**:
  - Intelligence engines (confidence, ROI scoring)
  - Multi-format export system (PDF, Excel, JSON, Markdown)
  - Vitest & Playwright testing
  - ESLint, Prettier, Husky pre-commit
- **Produces**: Comprehensive quality tooling, export infrastructure, testing framework
- **Resume**: Skips already-installed quality tools

#### Phase 5: User-Defined (Extensible)
- **Purpose**: Custom scripts without modifying core phases
- **Duration**: Variable
- **Scripts**: User-defined (0 by default)
- **Key Technologies**: Whatever you add
- **Produces**: Custom application features
- **Use Case**: Add proprietary features, custom integrations, or domain-specific setup

### Phase Execution Flow

```bash
# Entry point
omni run

# Discover all phases from bootstrap.conf
phase_discover() → finds all PHASE_METADATA_N variables

# Execute phases sequentially
for phase in 0 1 2 3 4 5; do
    phase_execute "$phase"
done

# Per-phase execution
phase_execute(0) {
    if phase_is_enabled("0"); then
        scripts = phase_get_scripts("0")
        packages = phase_get_packages("0")

        for script in scripts; do
            if state_has_succeeded("$script"); then
                log_skip "$script"
            else
                run_cmd "$script" [with timeout & retries]
                state_mark_success "$script"
            fi
        done
    fi
}
```

### State Tracking

```bash
# State file: .bootstrap_state (auto-created)
# Tracks successful script completion for resume capability

# Sample state file:
foundation/init-nextjs.sh=success:2025-11-24T15:30:45
foundation/init-typescript.sh=success:2025-11-24T15:31:12
docker/docker-compose-pg.sh=success:2025-11-24T15:35:22
db/drizzle-setup.sh=success:2025-11-24T15:37:08

# If phase 1 fails midway, run it again:
# - Completed scripts are skipped automatically
# - Execution resumes from where it left off
# - No wasted time re-running successful scripts
```

### Configuration-Driven Metadata

Each phase has associated metadata variables in bootstrap.conf:

```bash
# Basic metadata
PHASE_METADATA_1="
  number:1
  name:Infrastructure & Database
  description:Set up Docker, PostgreSQL, Drizzle ORM, environment validation
"

# Configuration
PHASE_CONFIG_01_DATABASE="
  enabled:true
  timeout:900
  prereq:strict
  deps:docker:20,postgresql:16
"

# Packages to install
PHASE_PACKAGES_01_DATABASE="
  PKG_DRIZZLE_ORM
  PKG_DRIZZLE_KIT
  PKG_POSTGRES_JS
  PKG_T3_ENV
  PKG_ZOD
"

# Scripts to run
BOOTSTRAP_PHASE_01_DATABASE="
  docker/docker-compose-pg.sh
  docker/dockerfile-multistage.sh
  db/drizzle-setup.sh
  db/drizzle-schema-base.sh
  db/drizzle-migrations.sh
  db/db-client-index.sh
  env/env-validation.sh
  env/zod-schemas-base.sh
"
```

---

## Library Modules

OmniForge provides **26 modular library files** with 10,344 lines of code, each with a single responsibility and pure functions (no execution on source).

### Master Loader (lib/common.sh)

**Purpose**: Central loading point for all library modules
**Functions**: None (sources other libs)
**Dependencies**: All other lib modules
**When to use**: Source this first in any script needing OmniForge functionality

```bash
# Usage in your script:
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Automatically loads all 26 modules in dependency order:
# 1. logging.sh (colors, structured output)
# 2. log-rotation.sh (log cleanup)
# 3. validation.sh (requirement checks)
# 4. utils.sh (general utilities)
# 5. config_bootstrap.sh (configuration)
# 6. state.sh (execution tracking)
# 7. git.sh (safety checks)
# 8. packages.sh (npm management)
# 9. phases.sh (phase orchestration)
# ... and 17 more
```

### Core Infrastructure Modules

#### logging.sh (Logging System)
**Size**: 10 KB | **Functions**: 12
**Purpose**: Colored console output and file logging with auto-rotation

**Key Functions**:
```bash
log_info "Message"           # Blue [INFO]
log_ok "Success"             # Green [✓]
log_warn "Warning"           # Yellow [!]
log_error "Error"            # Red [✗]
log_debug "Debug"            # Gray [DEBUG] (if VERBOSE=true)
log_step "Phase name"        # Blue [→]
log_success "Done"           # Green [✓]
log_skip "Already done"      # Yellow [⊘]
log_dry "Would do X"         # Cyan [DRY]
log_status "Status message"  # Status update
log_file "Message" "TYPE"    # File-only logging
log_progress "Step" 3/5      # Progress indicator
```

**Configuration**:
```bash
LOG_LEVEL="status"           # Options: quiet, status, verbose
LOG_FORMAT="plain"           # Options: plain, json
LOG_FILE="/path/to/log"      # Optional file output
VERBOSE="false"              # Enable debug output
```

**Examples**:
```bash
# Basic usage
log_info "Starting application setup"
log_step "Installing dependencies"
log_success "Dependencies installed"
log_error "Failed to install package"

# Conditional debug (only if VERBOSE=true)
log_debug "Detailed system information"

# File-based logging (non-console)
log_file "Backend system event" "SYSTEM"

# Progress tracking
log_progress "Phase 1" 1/6
log_progress "Phase 2" 2/6
```

#### validation.sh (Dependency Validation)
**Size**: 12 KB | **Functions**: 12
**Purpose**: Check for required commands, tools, and versions

**Key Functions**:
```bash
require_cmd "pnpm" "Install hint"        # Require command in PATH
require_node_version "20"                # Require specific Node version
require_node_version_exact "20.18.1"     # Require exact version
require_pnpm                             # Require pnpm
require_docker                           # Require Docker installed & running
require_docker_compose                   # Require Docker Compose v2+
require_buildkit                         # Require BuildKit enabled
require_docker_env                       # Full Docker environment check
require_file "/path" "hint"              # Require file exists
require_dir "/path" "hint"               # Require directory exists
require_project_root                     # Require package.json exists
require_git_repo                         # Require .git directory
```

**Examples**:
```bash
# Check before executing
require_cmd "pnpm" "Install from: https://pnpm.io"
require_docker "Docker required for this phase"

# Check version
require_node_version "20"    # Requires Node 20+
require_pnpm                 # Requires pnpm installed

# Check project state
require_project_root         # Fails if package.json missing
require_git_repo             # Fails if not in git repo
```

#### utils.sh (General Utilities)
**Size**: 7 KB | **Functions**: 10
**Purpose**: File operations, command execution, common helpers

**Key Functions**:
```bash
run_cmd "command" [timeout]              # Execute with timeout & error handling
ensure_dir "/path"                       # Create directory, don't fail if exists
write_file "/path" "content"             # Write or create file
ensure_file_contains "/path" "text"      # Add text if not present
add_gitkeep "/path"                      # Create .gitkeep file
confirm "Continue?" "prompt"             # User confirmation prompt
is_empty_dir "/path"                     # Check if directory is empty
get_script_dir                           # Get directory of current script
backup_file "/path"                      # Create timestamped backup
cleanup_temp_files                       # Remove temporary files
```

**Examples**:
```bash
# Safe command execution
run_cmd "npm install" 300          # Run with 5-minute timeout
run_cmd "pnpm build" 600 2         # Retry up to 2 times

# File operations
ensure_dir "src/components"        # Create if doesn't exist
write_file "app.config.ts" "$content"
ensure_file_contains ".gitignore" "dist/"

# User interaction
if confirm "Deploy to production?"; then
    log_step "Deploying..."
fi
```

### Configuration Management

#### config_bootstrap.sh (Configuration Loading)
**Size**: 11 KB | **Functions**: 8
**Purpose**: Load and apply bootstrap.conf settings

**Key Functions**:
```bash
config_load                              # Load bootstrap.conf into shell
config_validate                          # Validate required settings
config_apply_profile                     # Apply STACK_PROFILE overrides
config_get_profile_features              # List features for profile
config_show_settings                     # Display all loaded settings
```

**Examples**:
```bash
# Load configuration
source "$(dirname "$0")/../lib/common.sh"
config_load

# Use settings
echo "Database: ${DB_NAME}@${DB_HOST}"
echo "Node: ${NODE_VERSION}"

# Validate before execution
config_validate || exit 1

# Apply a stack profile
STACK_PROFILE="ai_automation"
config_apply_profile
```

#### config_validate.sh (Validation)
**Size**: 14 KB | **Functions**: 10
**Purpose**: Validate bootstrap.conf values and detect issues

**Key Functions**:
```bash
config_validate_settings                 # Check all required fields
config_validate_paths                    # Verify paths exist
config_validate_database                 # Validate database settings
config_validate_docker                   # Validate Docker configuration
config_report_issues                     # Show validation errors
```

#### config_deploy.sh (Deployment Config)
**Size**: 5.6 KB | **Functions**: 6
**Purpose**: Load deployment-specific configuration

### State Management

#### state.sh (State Tracking)
**Size**: 5.2 KB | **Functions**: 8
**Purpose**: Track script completion for resume capability (the engine of resumability)

**Key Functions**:
```bash
state_init                               # Initialize state file
state_mark_success "key"                 # Mark script complete
state_has_succeeded "key"                # Check if completed
state_clear "key"                        # Clear specific state
state_clear_all                          # Reset all state
state_count_completed                    # Count completed scripts
state_list_completed                     # List completed scripts
state_show_status                        # Display status summary
```

**How It Works**:
```bash
# State file format (.bootstrap_state):
foundation/init-nextjs.sh=success:2025-11-24T15:30:45
foundation/init-typescript.sh=success:2025-11-24T15:31:12
docker/docker-compose-pg.sh=success:2025-11-24T15:35:22

# Usage in phase execution:
if state_has_succeeded "foundation/init-nextjs.sh"; then
    log_skip "Already completed"
else
    run_cmd "foundation/init-nextjs.sh"
    state_mark_success "foundation/init-nextjs.sh"
fi
```

**Examples**:
```bash
# Initialize state tracking
state_init

# Mark completion
state_mark_success "database/setup.sh"

# Check before running
if state_has_succeeded "database/setup.sh"; then
    log_info "Database already configured"
else
    log_step "Setting up database..."
    run_cmd "database/setup.sh"
    state_mark_success "database/setup.sh"
fi

# Show progress
omni status  # Uses state_show_status() internally

# Reset if needed
state_clear_all
```

### Execution Management

#### sequencer.sh (Sequential Execution)
**Size**: 13 KB | **Functions**: 8
**Purpose**: Sequential script execution with timeouts, retries, and test criteria

**Key Functions**:
```bash
sequencer_run "script.sh" [timeout] [retries]     # Run with timeout
sequencer_run_with_deps "script.sh" "deps"        # Run with dependencies
sequencer_test "test.sh"                          # Run test criteria
sequencer_set_timeout "script.sh" "seconds"       # Set timeout for script
sequencer_get_results                             # Get execution results
```

**Features**:
- Per-script timeouts (no global timeout limits)
- Automatic retry logic for transient failures
- Test criteria verification (optional checks after execution)
- Dependency ordering (run scripts in correct order)

**Examples**:
```bash
# Run with timeout
sequencer_run "build-app.sh" 300      # 5 minute timeout

# Run with retries
sequencer_run "flaky-test.sh" 120 2   # Retry up to 2 times

# Run with dependencies
sequencer_run_with_deps "deploy.sh" "build.sh,test.sh"

# Check execution results
results=$(sequencer_get_results)
echo "Completed: $results"
```

#### phases.sh (Phase Orchestration)
**Size**: 26 KB | **Functions**: 12
**Purpose**: Discover and execute phases from bootstrap.conf metadata

**Key Functions**:
```bash
phase_discover                           # Find all PHASE_METADATA_N
phase_execute "0" "$dir"                 # Execute phase 0
phase_execute_all "$dir"                 # Execute all phases 0-5
phase_list_all                           # Display all phases
phase_get_name "0"                       # Get phase name
phase_get_description "0"                # Get phase description
phase_is_enabled "0"                     # Check if enabled
phase_get_scripts "0"                    # Get scripts for phase
phase_get_packages "0"                   # Get packages for phase
```

**Execution Flow**:
```bash
# Full initialization with auto-resume
omni --init

# 1. Discover all phases
phase_discover

# 2. Execute each phase
phase_execute 0    # Project Foundation
phase_execute 1    # Infrastructure & Database
phase_execute 2    # Core Features
# ... etc

# 3. Track state for resume
# If interrupted: run omni --init again, skips completed scripts
```

### Package Management

#### packages.sh (NPM Package Management)
**Size**: 6.6 KB | **Functions**: 8
**Purpose**: Expand package definitions and manage npm dependencies

**Key Functions**:
```bash
pkg_expand "PKG_NEXT"                    # Expand to "next@15"
pkg_is_enabled "PKG_X|enabled:false"     # Check if feature enabled
pkg_add_dependency "next@15"             # Add to package.json
pkg_add_script "dev" "next dev"          # Add npm script
pkg_has_dependency "next@15"             # Check if already added
pkg_update_field "author" "name"         # Update package.json field
```

**How It Works**:
```bash
# Define packages in bootstrap.conf
PKG_NEXT="next@15"
PKG_REACT="react@19"
PKG_TYPESCRIPT="typescript@5"

# Expand in scripts
pkg_expand "PKG_NEXT"          # Returns "next@15"
pkg_expand "PKG_REACT"         # Returns "react@19"

# Conditional expansion (with feature flags)
# If ENABLE_AUTHJS="true", pkg_is_enabled PKG_AUTH expands it
# If ENABLE_AUTHJS="false", that package is skipped
```

### Git Management

#### git.sh (Git Safety)
**Size**: 2.6 KB | **Functions**: 4
**Purpose**: Ensure safe git operations before making changes

**Key Functions**:
```bash
git_ensure_clean                         # Check working directory clean
git_is_repo                              # Check if in git repo
git_current_branch                       # Get current branch name
git_has_uncommitted                      # Check for uncommitted changes
```

**Examples**:
```bash
# Ensure clean state before initialization
git_ensure_clean || {
    log_error "Commit or stash changes first"
    exit 1
}

# Safe to proceed with changes
log_step "Initializing project"
```

### Advanced Modules

#### setup.sh (Project Setup)
**Size**: 6.7 KB | **Functions**: 7
**Purpose**: One-time OmniForge project initialization (deploys templates, creates directories)

**Key Functions**:
```bash
setup_omniforge_project                  # Run all setup tasks
setup_is_complete                        # Check if setup done
setup_validate_environment               # Verify bash version, commands
setup_create_directories                 # Create project structure
setup_mark_complete                      # Mark setup as done
setup_show_status                        # Display setup status
```

#### setup_wizard.sh (Interactive Configuration)
**Size**: 86 KB | **Functions**: 20+
**Purpose**: Interactive wizard for first-time configuration

**Key Functions**:
```bash
setup_run_first_time                     # Run complete wizard
setup_interactive_profile                # Interactive profile selection
setup_interactive_features               # Enable/disable features
setup_interactive_database               # Configure database
```

#### prereqs.sh (System Prerequisites)
**Size**: 9.8 KB | **Functions**: 10
**Purpose**: Check and install system-level prerequisites (node, pnpm, docker, git)

**Key Functions**:
```bash
prereq_tool_exists "node"                # Check if installed
prereqs_check_all                        # Check all prerequisites
prereqs_install_background               # Install in background while other tasks run
prereqs_wait                             # Wait for background installation
prereqs_status                           # Show installation status
```

#### prereqs-local.sh (Local Tool Installation)
**Size**: 12 KB | **Functions**: 12
**Purpose**: Install Node.js and pnpm to project-local `.tools/` directory

**Key Functions**:
```bash
prereqs_local_node_install               # Install Node.js locally
prereqs_local_pnpm_install               # Install pnpm locally
prereqs_local_activate                   # Activate local tools
prereqs_local_check_installed            # Check what's installed locally
```

**How It Works**:
```bash
# Install Node.js and pnpm to project-local directory
# This ensures:
# - No system pollution
# - Reproducible, version-specific environment
# - Different projects can have different versions
# - Easy cleanup (just delete .tools/)

# Activation
source .toolsrc              # Sets PATH to use .tools/ versions
node --version               # Uses local Node.js
pnpm --version               # Uses local pnpm
```

#### auto_detect.sh (Auto-Detection)
**Size**: 4.2 KB | **Functions**: 6
**Purpose**: Auto-detect project settings and environment

**Key Functions**:
```bash
auto_detect_node_version                 # Find installed Node version
auto_detect_pnpm_version                 # Find installed pnpm version
auto_detect_postgres_running             # Check if PostgreSQL running
auto_detect_docker_running               # Check if Docker daemon running
```

#### scaffold.sh (Template Deployment)
**Size**: 4.6 KB | **Functions**: 6
**Purpose**: Deploy configuration templates to project root

**Key Functions**:
```bash
scaffold_deploy_all                      # Deploy all templates
scaffold_deploy_file "template" "dest"   # Deploy single template
scaffold_verify_deployment               # Check templates deployed
```

#### menu.sh (Interactive Menu)
**Size**: 86 KB | **Functions**: 30+
**Purpose**: Interactive menu system for OmniForge operations

**Key Functions**:
```bash
menu_main                                # Main menu
menu_select_phase                        # Phase selection
menu_configure_settings                  # Settings configuration
menu_view_logs                           # Log viewer
```

#### indexer.sh (Script Discovery)
**Size**: 11 KB | **Functions**: 8
**Purpose**: Index and discover available scripts in tech_stack/

**Key Functions**:
```bash
indexer_scan_tech_stack                  # Scan for all scripts
indexer_get_scripts_for_phase            # Get scripts for phase
indexer_list_all_scripts                 # List available scripts
```

#### bakes.sh (Configuration Presets)
**Size**: 9.5 KB | **Functions**: 10
**Purpose**: Pre-configured "bake" settings for common use cases

**Key Functions**:
```bash
bakes_get_profile "ai_automation"        # Get profile settings
bakes_list_profiles                      # List available profiles
bakes_apply "fpa_dashboard"              # Apply profile to config
```

#### ascii.sh (Branding)
**Size**: 10 KB | **Functions**: 8
**Purpose**: ASCII art, logos, and text formatting

**Key Functions**:
```bash
ascii_show_logo                          # Display OmniForge logo
ascii_show_banner "text"                 # Show formatted banner
ascii_underline "text"                   # Underlined text
ascii_box "text"                         # Boxed text
```

#### downloads.sh (Download Cache)
**Size**: 15 KB | **Functions**: 10
**Purpose**: Cache downloaded files to avoid re-downloading

**Key Functions**:
```bash
downloads_get_cached "url"               # Get cached or download
downloads_cache_file "url" "path"        # Cache a file
downloads_verify_checksum "path"         # Verify file integrity
```

#### settings_manager.sh (IDE Settings)
**Size**: 14 KB | **Functions**: 12
**Purpose**: Manage IDE configuration files (VSCode, etc.)

**Key Functions**:
```bash
settings_deploy_vscode                   # Deploy VSCode config
settings_deploy_all                      # Deploy all IDE configs
settings_validate                        # Check settings deployed
```

#### reset.sh (Reset System)
**Size**: 12 KB | **Functions**: 8
**Purpose**: Safe reset of deployments while preserving OmniForge

**Key Functions**:
```bash
reset_deployment                         # Reset current deployment
reset_backup_before_delete               # Create backup before reset
reset_restore_from_backup                # Restore from backup
```

---

## Tech Stack

OmniForge includes **57 technology-specific installation scripts** organized into **18 technology categories**. These scripts automate the setup of commonly-used libraries and frameworks.

### Tech Stack Categories & Scripts

#### 1. **foundation/** (4 scripts)
Project initialization and structure
- `00-nextjs.sh` - Initialize Next.js 15 project
- `init-nextjs.sh` - Next.js configuration
- `init-typescript.sh` - TypeScript strict mode setup
- `init-directory-structure.sh` - Create src/ structure

#### 2. **core/** (4 scripts)
Framework core functionality
- `init-package-engines.sh` - Set Node/pnpm versions
- Various core framework scripts

#### 3. **docker/** (3 scripts)
Containerization and orchestration
- `dockerfile-multistage.sh` - Production-ready Dockerfile
- `docker-compose-pg.sh` - Docker Compose with PostgreSQL
- `docker-pnpm-cache.sh` - BuildKit cache optimization

#### 4. **db/** (4 scripts)
Database and ORM configuration
- `drizzle-setup.sh` - Drizzle ORM initialization
- `drizzle-schema-base.sh` - Base schema definition
- `drizzle-migrations.sh` - Migration system setup
- `db-client-index.sh` - Database client exports

#### 5. **env/** (3 scripts)
Environment and validation
- `env-validation.sh` - Environment validation
- `zod-schemas-base.sh` - Base Zod schemas

#### 6. **auth/** (2 scripts)
Authentication and authorization
- `authjs-setup.sh` - Auth.js initialization
- `auth-routes.sh` - Authentication route templates

#### 7. **ai/** (3 scripts)
AI and ML integration
- `ai-sdk.sh` - Vercel AI SDK setup
- LLM integration scripts

#### 8. **state/** (2 scripts)
State management
- `zustand-setup.sh` - Zustand store initialization
- `session-state-lib.sh` - Session state utilities

#### 9. **jobs/** (2 scripts)
Background job processing
- `pgboss-setup.sh` - PgBoss job queue
- `job-worker-template.sh` - Worker template

#### 10. **observability/** (2 scripts)
Logging and monitoring
- `pino-logger.sh` - Pino logging setup
- `pino-pretty-dev.sh` - Development log formatting

#### 11. **intelligence/** (4 scripts)
Intelligence engines for AI features
- `confidence-engine.sh` - Confidence scoring
- `roi-engine.sh` - ROI calculation
- `melissa-prompts.sh` - LLM prompt templates
- `hitl-review-queue.sh` - Human-in-the-loop review

#### 12. **export/** (5 scripts)
Multi-format export system
- `export-system.sh` - Export framework
- `pdf-export.sh` - PDF generation
- `excel-export.sh` - Excel export
- `json-export.sh` - JSON export
- `markdown-export.sh` - Markdown export

#### 13. **monitoring/** (3 scripts)
Health checks and feature flags
- `health-endpoints.sh` - Health check endpoints
- `feature-flags.sh` - Feature flag system
- Additional monitoring scripts

#### 14. **ui/** (3 scripts)
UI components and styling
- `shadcn-init.sh` - Shadcn UI setup
- `components-structure.sh` - Component directory structure
- `settings-ui.sh` - Settings UI components

#### 15. **testing/** (3 scripts)
Testing frameworks and tools
- `vitest-setup.sh` - Unit testing with Vitest
- `playwright-setup.sh` - E2E testing
- Additional testing utilities

#### 16. **quality/** (3 scripts)
Code quality and linting
- `eslint-prettier.sh` - ESLint + Prettier setup
- `code-quality.sh` - Quality tools
- `husky-lintstaged.sh` - Pre-commit hooks

#### 17. **features/** (5+ scripts)
Application-specific features
- `chat-feature-scaffold.sh` - Chat system
- `rate-limiter.sh` - Rate limiting
- `prompts-structure.sh` - Prompt organization
- Additional feature scripts

#### 18. **_lib/** (1+)
Tech stack utilities and shared functions

### Tech Stack Script Format

Each tech_stack script follows a consistent format:

```bash
#!/usr/bin/env bash
# =============================================================================
# Script Name
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Purpose: Description of what this script does
# Implements: What technology/feature
# Creates: Files/directories created
# Modifies: Files modified
# Dependencies: Other scripts or tools required
#
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

# Source common libraries
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Validate prerequisites
require_cmd "pnpm"
require_file "package.json"

# Main implementation
log_step "Setting up [technology]"

# ... implementation code ...

log_success "[Technology] setup complete"
```

### Running Tech Stack Scripts

```bash
# Manual execution
cd _build/omniforge
./tech_stack/foundation/init-nextjs.sh

# Via OmniForge phase system (automatic)
omni run                   # Runs all phases, executing appropriate scripts

# Run specific phase
omni run --phase 1         # Runs phase 1 (Infrastructure & Database)

# Dry-run preview
omni run --dry-run         # Shows what would execute without making changes
```

---

## CLI Reference

### Entry Point: omni.sh

Thin wrapper that validates environment and delegates to modular bin/ scripts.

```bash
omni [command] [options]

# Help
omni --help              # Show help
omni -h                  # Short help

# Show logo
omni --logo              # Display OmniForge branding

# Version
omni --version           # Show version
omni -v                  # Short version
```

### Main Commands

#### omni --init
**Purpose**: Initialize project for the first time
**Behavior**: Runs all phases with resume capability
**Exit Code**: 0 on success, 1 on error

```bash
omni --init                    # Full initialization
ALLOW_DIRTY=true omni --init   # Skip git clean check
```

#### omni run
**Purpose**: Execute phases (main execution command)
**Behavior**: Runs specified phases with auto-resume

```bash
omni run                       # Run all phases (0-5)
omni run --phase 0             # Run only phase 0
omni run --phase 0,2,4         # Run specific phases
omni run --force               # Ignore state, re-run all
omni run --dry-run             # Preview without execution
VERBOSE=true omni run          # Detailed output
```

#### omni status
**Purpose**: Show progress and configuration

```bash
omni status                    # Show bootstrap status
omni status --list             # List all phases
omni status --config           # Show full configuration
omni status --clear            # Clear all state (reset progress)
```

#### omni build (alias: omni forge)
**Purpose**: Build and verify after initialization

```bash
omni build                     # Run build verification
omni build --skip-build        # Skip build, just verify
omni forge                     # Same as omni build
```

#### omni reset
**Purpose**: Safe reset of deployments

```bash
omni reset                     # Interactive mode (confirm)
omni reset --yes               # Non-interactive (auto-confirm)
omni reset --help              # Show reset help
```

#### omni menu
**Purpose**: Interactive setup wizard

```bash
omni menu                      # Launch interactive menu
```

### Global Options

```bash
# Environment Variables (override any setting)
ALLOW_DIRTY=true               # Skip git clean check
VERBOSE=true                   # Enable debug output
LOG_LEVEL="verbose"            # quiet, status (default), verbose
LOG_FORMAT="json"              # plain (default), json
DRY_RUN=true                   # Preview mode (no execution)
NON_INTERACTIVE=true           # CI/automation mode
STACK_PROFILE="ai_automation"  # Select profile
```

---

## Environment Variables

OmniForge respects these environment variables (overriding bootstrap.conf):

### Execution Control

| Variable | Default | Purpose |
|----------|---------|---------|
| `DRY_RUN` | false | Preview mode, no actual changes |
| `VERBOSE` | false | Enable debug output |
| `LOG_LEVEL` | status | Output verbosity: quiet, status, verbose |
| `LOG_FORMAT` | plain | Output format: plain, json |
| `NON_INTERACTIVE` | false | Skip user prompts (CI/automation) |

### Configuration Overrides

| Variable | Purpose |
|----------|---------|
| `APP_NAME` | Override application name |
| `DB_NAME` | Override database name |
| `DB_USER` | Override database user |
| `DB_PASSWORD` | Override database password |
| `STACK_PROFILE` | Select profile: ai_automation, fpa_dashboard, etc. |
| `INSTALL_TARGET` | Override install location: test, prod |

### Safety & Behavior

| Variable | Default | Purpose |
|----------|---------|---------|
| `ALLOW_DIRTY` | false | Skip git clean requirement |
| `GIT_SAFETY` | true | Require clean git repo |
| `MAX_CMD_SECONDS` | 960 | Timeout for commands (16 min) |
| `PREFLIGHT_REMEDIATE` | true | Auto-fix missing dependencies |
| `BOOTSTRAP_RESUME_MODE` | skip | skip = resume from last, force = redo all |

### Docker & Infrastructure

| Variable | Purpose |
|----------|---------|
| `ENABLE_DOCKER` | Use Docker containers (true/false) |
| `DOCKER_EXEC_MODE` | host or container |
| `ENABLE_REDIS` | Add Redis service |
| `DOCKER_REGISTRY` | Container registry (ghcr.io, etc.) |

### Example Usage

```bash
# Full initialization with all options
export APP_NAME="MyApp"
export DB_PASSWORD="secret123"
export STACK_PROFILE="ai_automation"
export ALLOW_DIRTY=true
export VERBOSE=true
omni --init

# CI/CD mode
export NON_INTERACTIVE=true
export LOG_FORMAT=json
omni run > build.log 2>&1

# Dry-run preview
export DRY_RUN=true
omni run --phase 1

# JSON output for parsing
export LOG_FORMAT=json
omni status --config | jq '.app_name'
```

---

## Error Handling

### Common Errors and Solutions

#### Git Safety Error
```
[ERROR] Git working directory is not clean
[ERROR] Use ALLOW_DIRTY=true to override this check.
```
**Solution:**
```bash
# Option 1: Commit or stash changes
git add .
git commit -m "WIP"

# Option 2: Allow dirty (if safe)
ALLOW_DIRTY=true omni --init
```

#### Missing Dependencies
```
[ERROR] Required: pnpm - Install from https://pnpm.io
[ERROR] System prerequisite not found: docker
```
**Solution:**
```bash
# Let OmniForge auto-install
AUTO_INSTALL_PNPM=true omni --init

# Or install manually
curl -fsSL https://get.pnpm.io/install.sh | sh -
```

#### Script Execution Failed
```
[ERROR] Phase 1 (Infrastructure & Database) failed at: docker/docker-compose-pg.sh
[ERROR] docker-compose: command not found
```
**Solution:**
```bash
# Install Docker if available, then resume
ALLOW_DIRTY=true omni --init  # Auto-resumes from last success
```

#### State Corruption
```bash
# Clear state and restart
omni status --clear
omni --init
```

#### Timeout During Execution
```
[ERROR] Command exceeded timeout: 300 seconds
```
**Solution:**
```bash
# Increase timeout
export MAX_CMD_SECONDS=1800  # 30 minutes
omni run --force             # Restart with longer timeout
```

### Debug Mode

```bash
# Maximum verbosity
VERBOSE=true LOG_LEVEL=verbose omni run

# JSON output for parsing
LOG_FORMAT=json omni status

# Dry-run to preview without execution
DRY_RUN=true omni run

# See exact commands being run
bash -x _build/omniforge/lib/phases.sh
```

---

## Resetting Deployments

OmniForge provides a safe reset system that deletes deployment artifacts while preserving the OmniForge system.

### Reset Commands

```bash
omni reset              # Interactive mode (confirm before delete)
omni reset --yes        # Non-interactive mode (auto-confirm)
omni reset --help       # Show reset help
```

### What Gets Deleted

```
Root config files:
  ├─ package.json
  ├─ tsconfig.json
  ├─ next.config.ts
  ├─ tailwind.config.ts
  └─ [other root configs]

Source directory:
  └─ src/            (all source files)

Test directories:
  └─ e2e/
  └─ __tests__/

Build artifacts:
  ├─ .next/          (Next.js build)
  ├─ dist/           (build output)
  ├─ node_modules/   (dependencies)
  └─ .turbo/         (cache)

State files:
  ├─ .bootstrap_state (execution tracking)
  ├─ pnpm-lock.yaml   (lock file)
  └─ package-lock.json (lock file)
```

### What Gets Preserved

```
OmniForge system:
  └─ _build/omniforge/   (entire system, all improvements)

Configuration:
  ├─ bootstrap.conf      (your settings)
  └─ .claude/            (Claude Code config)

Documentation:
  └─ docs/               (all markdown)

Repository:
  ├─ .git/               (git history)
  └─ .gitignore          (git configuration)

Backups:
  └─ _backup/            (automatic backups before reset)
```

### Automatic Backup

Before deletion, `omni reset` automatically creates a timestamped backup:

```
_backup/deployment-YYYYMMDD-HHMMSS/
├── manual-fixes/        # Manually created files
├── package.json         # Package manifest
├── tsconfig.json        # TypeScript config
└── [other configs]
```

### Full Reset Cycle

```bash
# 1. Reset deployment
omni reset --yes

# 2. Modify bootstrap.conf if desired
vim bootstrap.conf

# 3. Re-deploy
omni --init

# 4. Check status
omni status

# 5. Build and verify
omni build

# 6. Start development
pnpm dev
```

### Restore from Backup

If you need to recover files after reset:

```bash
# Find latest backup
ls -lt _backup/

# Restore specific file
cp _backup/deployment-YYYYMMDD-HHMMSS/manual-fixes/App.tsx src/

# Restore everything
cp -r _backup/deployment-YYYYMMDD-HHMMSS/* .
```

### Use Cases

- **Test different configurations**: Reset, modify bootstrap.conf, redeploy
- **Fix build errors**: Reset and redeploy with fixes
- **Clean slate**: Reset and start fresh
- **Development iteration**: Quick reset for testing changes

---

## Extensibility & Development

### Creating Custom Phases

Add custom scripts to Phase 5 (User-Defined) without modifying core:

```bash
# In bootstrap.conf, Phase 5:

PHASE_METADATA_5="number:5|name:Custom Features|description:Your custom setup"
PHASE_CONFIG_05_CUSTOM="enabled:true|timeout:600"
PHASE_PACKAGES_05_CUSTOM="PKG_CUSTOM_LIB"

# Add scripts
BOOTSTRAP_PHASE_05_CUSTOM="
  custom/my-feature.sh
  custom/my-setup.sh
"

# Create your scripts in tech_stack/custom/
mkdir -p _build/omniforge/tech_stack/custom
```

### Creating Tech Stack Scripts

Follow the standard format:

```bash
#!/usr/bin/env bash
# =============================================================================
# my-feature.sh
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Purpose: Set up my custom feature
# Dependencies: Node.js, pnpm

set -euo pipefail
IFS=$'\n\t'

# Load common libraries
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Validate prerequisites
require_cmd "pnpm"
require_file "package.json"

# Main implementation
log_step "Setting up my feature"

# Your code here...

log_success "My feature setup complete"
```

### Extending Library Modules

Create new library modules by following the pattern:

```bash
#!/usr/bin/env bash
# =============================================================================
# lib/my-module.sh - My Custom Module
# =============================================================================
# Part of OmniForge

# Guard against double-sourcing
[[ -n "${_LIB_MY_MODULE_LOADED:-}" ]] && return 0
_LIB_MY_MODULE_LOADED=1

# Exports:
# my_function_1, my_function_2

# Dependencies:
# lib/logging.sh

# Define your functions...
my_function_1() {
    log_info "Doing something"
}

# Export functions
export -f my_function_1
```

Then add to lib/common.sh:

```bash
# In lib/common.sh, add to source list:
source "${_COMMON_LIB_DIR}/my-module.sh"
```

### Adding Stack Profiles

Define new profiles in bootstrap.conf:

```bash
# In SECTION 5: STACK PROFILES

# Add to config_apply_profile() function:
"my_profile")
    ENABLE_AUTHJS=true
    ENABLE_AI_SDK=true
    ENABLE_CUSTOM_FEATURE=true
    log_info "Applied my_profile"
    ;;
```

### Testing OmniForge Changes

```bash
# Validate script syntax
bash -n _build/omniforge/lib/common.sh

# Dry-run preview
DRY_RUN=true omni run

# Single phase test
omni run --phase 0

# Full test with reset
omni reset --yes && ALLOW_DIRTY=true omni --init
```

### Development Workflow

```bash
# 1. Make changes
vim _build/omniforge/lib/my-module.sh

# 2. Test syntax
bash -n _build/omniforge/lib/my-module.sh

# 3. Preview execution
VERBOSE=true DRY_RUN=true omni run

# 4. Full test
ALLOW_DIRTY=true omni --init

# 5. Commit
git add _build/omniforge/
git commit -m "feat: improve my-module"
```

---

## Version History

### v3.0 (Current - November 2025)
**Major Release**: Complete rewrite with modular architecture

**New Features**:
- **26 library modules** (10,344 lines) with single responsibilities
- **Modular entry points** (bin/omni, bin/forge, bin/status)
- **Configuration-driven phases** from bootstrap.conf metadata
- **6 section bootstrap.conf** (451 lines) with clear organization
- **57 tech_stack scripts** across 18 categories
- **6 stack profiles** for common use cases
- **Auto-detection** and setup wizard
- **Local tool installation** (Node.js, pnpm to .tools/)
- **Improved logging** with colors, rotation, JSON output
- **Better error recovery** with state tracking

**Breaking Changes**:
- Complete rewrite; scripts must be updated for new lib/common.sh exports
- Configuration moved to structured bootstrap.conf sections
- Phase system now completely metadata-driven

**Performance**:
- Parallel prerequisite checking
- Background package downloads
- Smart resume capability (skip completed scripts)

### v2.0 (Previous - 2024)
Config-driven orchestrator with resume capability
- 43 total scripts
- Basic phase system
- State tracking

### v1.0 (Legacy)
Original phase-based system
- Monolithic design
- Manual orchestration

---

## Quick Reference

### Common Commands

```bash
# Initial setup
omni menu              # Interactive wizard (recommended)
omni --init            # Direct initialization
ALLOW_DIRTY=true omni --init  # Skip git clean check

# Check status
omni status            # Show progress
omni status --list     # List phases
omni status --config   # Show config

# Run phases
omni run               # Run all phases
omni run --phase 1     # Run phase 1
omni run --dry-run     # Preview
omni run --force       # Ignore state, re-run all

# Build & test
omni build             # Build and verify
pnpm dev               # Start dev server
pnpm test              # Run tests

# Reset
omni reset --yes       # Safe reset
```

### Key Files

| File | Purpose | Size |
|------|---------|------|
| omni.sh | Entry point | 130 lines |
| bootstrap.conf | Configuration | 451 lines |
| lib/common.sh | Master loader | 184 lines |
| lib/phases.sh | Phase orchestration | 26 KB |
| lib/logging.sh | Logging system | 10 KB |
| lib/state.sh | State tracking | 5.2 KB |

### Environment Overrides

```bash
# Settings
APP_NAME=MyApp DB_PASSWORD=secret STACK_PROFILE=ai_automation

# Behavior
ALLOW_DIRTY=true VERBOSE=true NON_INTERACTIVE=true

# Output
LOG_LEVEL=verbose LOG_FORMAT=json

# Execution
DRY_RUN=true MAX_CMD_SECONDS=1800
```

---

**OmniForge v3.0** - Infinite Architectures. Instant Foundation.
Production-ready project initialization framework for Next.js + TypeScript + PostgreSQL + AI applications.

For questions or contributions, see the project repository and documentation.
