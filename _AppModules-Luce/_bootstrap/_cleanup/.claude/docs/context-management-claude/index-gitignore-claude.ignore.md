---
Context Strategy: L2 (Load on Demand)
Tier: 2 - Core Development Tools
---

# Index: _AppModules-Luce Directory

**Status:** Directory is gitignored but contents are documented here for Claude Code context management.

**Location:** `_AppModules-Luce/` (root level, not tracked in git)

**Purpose:** User working directory for app modules, playbooks, CLI manager templates, and GitHub scripts.

---

## Directory Structure & File Listing

**Last Scanned:** 2025-11-17 17:57:00
**Total Files:** 46

### Subdirectories


- **_archive-mvp-ready-refactoring/** (1 files)

- **cli-manager/** (10 files)
  - `PLAYBOOK_LIBRARY.md`

- **GitHub-Scripts/** (11 files)
  - `gh.conf`
  - `gh.original.sh`
  - `gh.sh`
  - `GitHub-Scripts-old.zip`
  - `IMPLEMENTATION-SUMMARY.md`
  - `QUICK-REFERENCE.md`
  - `README.md`
  - `REFACTORING-VALIDATION-REPORT.md`

- **context-opt/** (Context Optimization Tools - moved from scripts/)
  - **lib/** (6 library modules)
    - `analysis.sh` - Context analysis functions
    - `ci.sh` - CI mode support
    - `dispatch.sh` - Verb dispatching
    - `policy.sh` - Policy enforcement
    - `run.sh` - Execution runtime
    - `ui.sh` - User interface/colors
  - **menus/** (4 interactive menus)
    - `analyze.sh` - Analyze current context
    - `suggest.sh` - Get recommendations
    - `apply.sh` - Apply changes
    - `tools.sh` - Utility tools
  - **verbs/** (5 executable actions)
    - `add_permissions_deny.sh`
    - `append_recommended_patterns.sh`
    - `deduplicate_patterns.sh`
    - `prune_alwaysInclude.sh`
    - `tighten_auto_include.sh`
  - **logs/** (Execution logs and backups)
  - `claudeignore_optimization.sh` (Main CLI - v1.1.1)
  - `context_policy.json` (Policy rules)
  - `registry.sh` (Loader for libs/menus/verbs)

- **playbooks/** (14 files)
  - `PLAYBOOK-DOCUMENTATION-CONSOLIDATION.md`

---
*Last updated: 2025-11-17 18:00:00*
*Migration: context-opt moved from scripts/ to _AppModules-Luce/*
