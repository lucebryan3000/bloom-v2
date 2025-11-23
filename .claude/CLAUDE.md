# bloom2 Bootstrap System - Claude Code Configuration

## Project Overview
bloom2 is a sophisticated phase-based project initialization framework that orchestrates the setup of a Next.js + TypeScript + PostgreSQL + AI stack. The system uses a centralized configuration file (`bootstrap.conf`) as the single source of truth.

## Current Architecture
- **Entry Point**: `/run-bootstrap.sh` and `_build/bootstrap_scripts/run-bootstrap.sh`
- **Configuration**: `_build/bootstrap_scripts/bootstrap.conf` (451 lines, all settings)
- **Libraries**: `_build/bootstrap_scripts/lib/common.sh` (716 lines, shared functions)
- **Phase System**: 6 phases (0-5) defining sequential initialization steps
- **Tech Stacks**: 12 scripts in `_build/bootstrap_scripts/tech_stack/` (export, intelligence, monitoring)

## Code Style & Architecture Principles

### Bash Scripts
- Use `#!/usr/bin/env bash` and `set -euo pipefail` consistently
- Functions must be self-contained and testable
- Color-coded logging: INFO (blue), OK (green), WARN (yellow), ERROR (red)
- Use local variables; prefix private functions with `_`
- Validate all inputs at function entry; fail fast
- Maintain state in `.bootstrap_state` file (deterministic, idempotent execution)

### Configuration
- **bootstrap.conf** is the single source of truth for all configuration
- Never hardcode paths, versions, or credentials in scripts
- All variables must be defined in bootstrap.conf or passed as parameters
- Feature flags (ENABLE_*) control which modules are installed
- Phase metadata (PHASE_METADATA_N) defines execution order and dependencies

### Modularity
- Each script has ONE clear responsibility
- Scripts in `lib/` are utility libraries; scripts in `tech_stack/` are feature implementations
- Use `source` to load dependencies; avoid circular dependencies
- Minimize script-to-script coupling; use config for coordination

## Refactoring Goals

The current system needs modularization to address:
1. **Duplicate orchestrators** (root vs _build run-bootstrap.sh)
2. **Incomplete tech_stack** (12 scripts implemented, 39+ referenced)
3. **Monolithic bootstrap.conf** (451 lines, difficult to navigate)
4. **Missing utility libraries** (validation, error recovery, package management)

## Refactoring Constraints

- **No Python**: Keep solution pure Bash 7+
- **bootstrap.conf** remains the single source of truth for hard-coded file paths
- **Read-only execution**: No modifications to azure environment
- **Backward compatibility**: Existing scripts must continue working
- **Documentation**: Update all affected docs and playbooks

## Slash Commands

Use these slash commands to switch work modes during the session:

- `/profile-code-writer` - Focus on implementation
- `/profile-code-reviewer` - Analyze code quality and security
- `/profile-documenter` - Write clear documentation
- `/profile-debugger` - Root cause analysis and fixes
- `/profile-researcher` - Explore and understand architecture

Default mode: Code Writer (implementation focus)

## File Conventions

- **lib/*.sh** - Utility libraries with shared functions (sourced by other scripts)
- **tech_stack/*.sh** - Feature-specific implementations (called by orchestrator)
- **modules/*.sh** - Phase-specific orchestration logic
- ***.conf** - Configuration files (sourced, never modified by runtime)

## Documentation Requirements

- Update `/README.md` to reflect new modular structure
- Create `/docs/ARCHITECTURE.md` describing modules and responsibilities
- Update Claude Playbooks in `_AppModules-Luce/docs/Melissa-Playbooks/`
- Maintain inline comments only where logic is non-obvious

## Critical Safeguards

- Always validate file paths exist before sourcing
- Check script syntax: `bash -n script.sh`
- Verify no write operations in bootstrap system
- Test with `NON_INTERACTIVE=true` for CI/automation mode
- Exit codes: 0 = success, 1 = param/config error, 2 = runtime failure
