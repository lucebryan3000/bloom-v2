---
Context Strategy: L1 (Always Preloaded)
Tier: 1 - Core Project Context
---

# Context Management Complete Reference

**Comprehensive guide to all context management files, strategies, and automation scripts**

**Date Generated**: 2025-11-17
**Scope**: Bloom project context optimization and management
**Status**: Active - Fully documented system

---

## Table of Contents

1. [Overview](#overview)
2. [Configuration Files](#configuration-files)
3. [Index Files & Discovery System](#index-files--discovery-system)
4. [Automation Scripts](#automation-scripts)
5. [File References & Locations](#file-references--locations)
6. [Quick Usage Guide](#quick-usage-guide)

---

## Overview

The Bloom project uses a **tiered context management system** to balance comprehensive documentation access with practical context size limits. All files and their locations are documented below.

### Key Principles

- **Tier 1**: Always preloaded (~4KB) - Core instructions and navigation
- **Tier 2**: On-demand (lightweight) - Agent commands, slash commands, prompts, gitignore index
- **Tier 3**: Searchable reference - Specialized indexes for knowledge base, build artifacts, sessions
- **Tier 4**: Project-wide docs - General documentation and references
- **Token Savings**: 73% reduction (14,830 → 4,000 lines) through intelligent on-demand loading

---

## Configuration Files

### 1. Root-Level `.claudeignore`

**Location**: `/home/luce/apps/bloom/.claudeignore`
**Size**: 1.0 KB
**Purpose**: Excludes large files from auto-load while maintaining on-demand access

**Key Exclusions**:
- `node_modules/` - Standard exclusion
- `.next/`, `build/`, `dist/` - Build artifacts
- `*.db`, `*.db-wal`, `*.db-shm` - Database files
- `docs/kb/`, `docs/features/`, `docs/operations/` - Large documentation
- `_build/`, `logs/`, `public/export/` - Build artifacts and logs
- `**/*.test.ts`, `**/*.spec.ts` - Test files
- `components/ui/**` - UI library components

**Key Exceptions** (NOT excluded):
- `.claude/commands/*.md` - Always needed (lightweight wrappers)
- `.claude/docs/context-management-claude/index-*.md` - Index files (small catalogs)
- `!.claude/agents/backend-typescript-architect.md` - Most frequently used agent

**Configuration Style**: Gitignore-style patterns with negations

---

### 2. `.claude/.claudeignore`

**Location**: `/home/luce/apps/bloom/.claude/.claudeignore`
**Size**: ~500 bytes
**Purpose**: Excludes agents and prompts from Tier 1 auto-load

**What's Excluded**:
- All agent files except `backend-typescript-architect.md` (loaded on-demand via `/agent-*` commands)
- Prompts (loaded on-demand)

**Pattern**:
```
agents/cli-manager.md
agents/docs-manager.md
agents/linux-ubuntu-architect.md
agents/python-backend-engineer.md
agents/senior-code-reviewer.md
agents/spec-analyst.md
agents/spec-architect.md
# ... etc (14 total agent files)

prompts/comprehensive-test-plan.md
prompts/refactor-remove-aws-s3.md
```

---

### 3. `.claude/settings.json`

**Location**: `/home/luce/apps/bloom/.claude/settings.json`
**Size**: 4.6 KB
**Purpose**: Master Claude Code configuration for the project

**Key Sections**:

```json
{
  "model": "sonnet",
  "context": {
    "alwaysInclude": ["CLAUDE.md"],
    "autoIncludePatterns": [
      "lib/**/*.ts",
      "components/**/*.tsx",
      "app/api/**/*.ts",
      "prisma/schema.prisma"
    ]
  },
  "fileHeaders": { /* Applied to all generated code */ },
  "codeStyle": { /* TypeScript, React, naming conventions */ },
  "testing": { /* Jest configuration */ },
  "git": { /* Conventional commits */ },
  "hooks": { /* UserPromptSubmit, Stop events */ },
  "ai": { /* Provider: Anthropic, Model: claude-sonnet */ },
  "database": { /* SQLite + Prisma + WAL mode */ },
  "permissions": { /* Deny access to sensitive files */ }
}
```

**Files It References**:
- `CLAUDE.md` - Always included
- Pattern-matched: `lib/**/*.ts`, `components/**/*.tsx`, `app/api/**/*.ts`, `prisma/schema.prisma`
- Excluded: `node_modules/**`, `.next/**`, `*.log`, `.env*`, `*.db*`

---

### 4. `_AppModules-Luce/context-opt/context_policy.json`

**Location**: `/home/luce/apps/bloom/_AppModules-Luce/context-opt/context_policy.json`
**Size**: ~500 bytes
**Purpose**: Policy rules for context optimization tools

**Structure**:
```json
{
  "schemaVersion": 1,
  "immutable": [
    ".claude/agents/**",
    ".claude/README.md",
    ".claude/config.json"
  ],
  "editable": {
    ".claudeignore": ["append_recommended_patterns", "deduplicate_patterns"],
    ".claude/settings.json": ["prune_alwaysInclude", "add_permissions_deny"]
  },
  "exceptions": [
    "!.claude/agents/backend-typescript-architect.md"
  ]
}
```

---

## Index Files & Discovery System

### Master Index File

**Location**: `.claude/docs/context-management-claude/_index-master.md`
**Size**: 19 KB (441 lines)
**Purpose**: Central navigation for all index files across the project
**Tier**: 1 (Always Preloaded)
**Key Sections**:
1. Quick Decision Tree (12 scenarios)
2. Tier System Overview
3. Detailed Index File Reference
4. Statistics & Impact tables
5. Directory Navigation Guide
6. How the System Works (diagrams)
7. Quick Reference Tables
8. Full Statistics

---

### Index File Registry

| Index File | Location | Tier | Files Indexed | Purpose |
|---|---|---|---|---|
| **_index-master.md** | `.claude/docs/context-management-claude/` | 1 | 16 index files | Master navigation |
| **index-agents.md** | `.claude/docs/context-management-claude/` | 2 | 15 agents | Agent discovery |
| **index-slash-commands.md** | `.claude/docs/context-management-claude/` | 2 | 26 commands | Slash command reference |
| **index-prompts.md** | `.claude/docs/context-management-claude/` | 2 | 1 prompt | Prompt discovery |
| **index-gitignore-claude.ignore.md** | `.claude/docs/context-management-claude/` | 2 | 36 files | Gitignored content |
| **index-kb-knowledge-base.md** | `.claude/docs/context-management-claude/` | 3 | 100+ KB articles | Knowledge base |
| **index-build-artifacts.md** | `.claude/docs/context-management-claude/` | 3 | 150+ files | Build planning & docs |
| **index-sessions-logs.md** | `.claude/docs/context-management-claude/` | 3 | 10+ logs | Work session notes |
| **index-docs-features.md** | `.claude/docs/context-management-claude/` | 3 | 50+ docs | Feature documentation |
| **index-docs-operations.md** | `.claude/docs/context-management-claude/` | 3 | 40+ docs | Operational docs |

---

### Index File Discovery

**How Index Files Are Found**:

The `_index-master-update.sh` script performs **comprehensive project-wide scanning**:

1. Searches entire project for files matching `*index*.md`
2. Excludes: `node_modules/`, `.next/`, `build/`, `dist/`, `.git/`
3. Automatically categorizes by location (Tier 1-4)
4. Adds tier headers if missing
5. Generates summary report

**File Pattern**: Any `.md` file with "index" in the name
**Auto-Discovery**: Tier assignment based on file location

---

## Automation Scripts

### 1. Master Index Updater Script

**Location**: `.claude/docs/context-management-claude/_index-master-update.sh`
**Size**: 26 KB (750+ lines)
**Purpose**: Automatically scan and update ALL index files across the project
**Language**: Bash

**Key Capabilities**:
- Comprehensive project-wide scanning for index files
- Automatic tier categorization
- Tier header insertion/validation
- Line count tracking
- Error handling & validation
- Color-coded output
- Dry-run and verbose modes

**Usage**:
```bash
./_index-master-update.sh                    # Update all indexes & report
./_index-master-update.sh --help             # Show help
./_index-master-update.sh --verbose          # Detailed output
./_index-master-update.sh --dry-run          # Preview changes
```

**Tier Header Format** (Auto-inserted):
```yaml
---
Context Strategy: L2 (Load on Demand)
Tier: 2 - Core Development Tools
---
```

**Functions Implemented**:
- `find_all_index_files()` - Recursive project scan
- `categorize_index_files()` - Tier assignment logic
- `update_agents_index()` - Agent discovery
- `update_prompts_index()` - Prompt discovery
- `update_slash_commands_index()` - Command discovery
- `update_gitignore_index()` - Gitignored content listing
- `generate_summary_report()` - Comprehensive reporting

---

### 2. Context Analysis Script

**Location**: `scripts/analyze-context.py`
**Size**: 15 KB (~400 lines)
**Purpose**: Analyze what files are loaded in context and estimate token usage
**Language**: Python 3

**Key Capabilities**:
- File statistics (lines, chars, estimated tokens)
- Always-included file analysis
- Claude configuration analysis
- Agent discovery & analysis
- Slash command enumeration
- Prompt discovery
- Build artifact scanning
- Token usage estimation (4 chars = 1 token)

**Output Sections**:
1. Always-Loaded Files (alwaysInclude)
2. Claude Configuration Files
3. Agents (on-demand via /agent-*)
4. Slash Commands
5. Prompts
6. Build Artifacts
7. Total Token Estimate

**Run Command**:
```bash
python3 scripts/analyze-context.py
```

---

### 3. Archive Scripts (Historical Reference)

**Location**: `scripts/archive/one-time-use/`

These are one-time setup scripts that are preserved for reference:
- `analyze-context.sh` - Original bash context analyzer
- `setup-context-panel.sh` - Initial context panel setup
- `setup-context-panel-v2.sh` - Updated context panel setup

**Status**: Archived but available for reference

---

## File References & Locations

### Complete File Listing

```
/home/luce/apps/bloom/
│
├── .claude/                                 # Claude Code configuration
│   ├── .claudeignore                        # Tier 1/2 exclusion rules
│   ├── settings.json                        # Master Claude settings
│   ├── config.json                          # Configuration
│   ├── README.md                            # Claude setup guide
│   ├── index-gitignore-claude.ignore.md     # Gitignored files index
│   │
│   ├── commands/                            # Tier 2 - Slash commands
│   │   ├── agent-*.md                       # 14 agent loaders
│   │   ├── /build-backlog                   # Build backlog command
│   │   ├── /prompt-review                   # Prompt review workflow
│   │   ├── /prompt-execute                  # Prompt execution
│   │   ├── /context-audit                   # Context auditing
│   │   ├── /db-refresh                      # Database refresh
│   │   ├── /quick-test                      # Quick testing
│   │   ├── /run-tests                       # Full test suite
│   │   ├── /validate-roi                    # ROI validation
│   │   └── ... (26 total commands)
│   │
│   ├── agents/                              # Tier 2/3 - Specialized agents
│   │   ├── backend-typescript-architect.md  # (NOT excluded)
│   │   ├── cli-manager.md
│   │   ├── docs-manager.md
│   │   ├── linux-ubuntu-architect.md
│   │   ├── python-backend-engineer.md
│   │   ├── senior-code-reviewer.md
│   │   ├── spec-analyst.md
│   │   ├── spec-architect.md
│   │   ├── spec-developer.md
│   │   ├── spec-orchestrator.md
│   │   ├── spec-planner.md
│   │   ├── spec-reviewer.md
│   │   ├── spec-tester.md
│   │   ├── spec-validator.md
│   │   └── ui-engineer.md
│   │
│   ├── docs/
│   │   └── context-management-claude/       # Tier 1/2/3 - Context docs
│   │       ├── _index-master.md             # Master navigation (Tier 1)
│   │       ├── _index-master-update.sh      # Auto-update script
│   │       ├── index-agents.md              # Agent index (Tier 2)
│   │       ├── index-slash-commands.md      # Commands index (Tier 2)
│   │       ├── index-prompts.md             # Prompts index (Tier 2)
│   │       ├── index-gitignore-claude.ignore.md # Gitignored index (Tier 2)
│   │       ├── index-kb-knowledge-base.md   # KB index (Tier 3)
│   │       ├── index-build-artifacts.md     # Build index (Tier 3)
│   │       ├── index-sessions-logs.md       # Sessions index (Tier 3)
│   │       ├── index-docs-features.md       # Features index (Tier 3)
│   │       ├── index-docs-operations.md     # Operations index (Tier 3)
│   │       └── CONTEXT-MANAGEMENT-COMPLETE-REFERENCE.md (this file)
│   │
│   ├── prompts/                             # Tier 2 - Prompt templates
│   │   └── comprehensive-test-plan.md
│   │
│   ├── hooks/                               # Tier 1 - Event hooks
│   │   ├── prompt-start.sh
│   │   └── prompt-complete.sh
│   │
│   └── logs/                                # Internal logging
│
├── scripts/
│   ├── analyze-context.py                   # Token analysis (Tier 3)
│   ├── context-opt/
│   │   └── context_policy.json              # Context policy rules
│   └── archive/one-time-use/
│       ├── analyze-context.sh               # Historical context analyzer
│       ├── setup-context-panel.sh           # Historical setup
│       └── setup-context-panel-v2.sh        # Historical setup v2
│
├── .claudeignore                            # Root .claudeignore
├── CLAUDE.md                                # Project instructions (Tier 1)
└── [... rest of project ...]
```

---

## Quick Usage Guide

### Finding Things

**Need to find an agent?**
→ Load `index-agents.md` (Tier 2)
→ Or use slash command: `/agent-{name}`

**Need a slash command?**
→ Load `index-slash-commands.md` (Tier 2)
→ Or type `/` in Claude Code to see all commands

**Need KB articles?**
→ Load `index-kb-knowledge-base.md` (Tier 3)

**Need build/planning docs?**
→ Load `index-build-artifacts.md` (Tier 3)

**Need to understand context management?**
→ Start with `_index-master.md` (Quick Decision Tree)

### Running Analysis

```bash
# Analyze token usage
python3 scripts/analyze-context.py

# Update all index files
./.claude/docs/context-management-claude/_index-master-update.sh

# Dry-run preview
./.claude/docs/context-management-claude/_index-master-update.sh --dry-run

# Verbose output
./.claude/docs/context-management-claude/_index-master-update.sh --verbose
```

### File References

**To add a new agent**: Add `.md` file to `.claude/agents/` - will auto-discover
**To add new slash command**: Add `.md` file to `.claude/commands/` - will auto-discover
**To add prompt**: Add `.md` file to `.claude/prompts/` - will auto-discover
**To exclude from context**: Add pattern to `.claudeignore` - will auto-exclude

---

## Summary Statistics

| Metric | Value |
|--------|-------|
| **Total Index Files** | 10 |
| **Total Files Indexed** | 690+ |
| **Configuration Files** | 4 |
| **Automation Scripts** | 2 (active) + 3 (archived) |
| **Tier 1 Files** | 1-2 |
| **Tier 2 Files** | 4 |
| **Tier 3 Files** | 6 |
| **Tier 4 Files** | 5+ |
| **Context Reduction** | 73% (14,830 → 4,000 lines) |
| **Token Savings** | ~2,700 tokens (avg) |

---

## Document History

- **2025-11-17**: Complete reference created - All context management files documented
- **Previous**: Individual tier index files created progressively
- **Prior**: Hybrid context loading system implemented (73% reduction)

---

*Last Updated: 2025-11-17*
*Status: Complete and production-ready*
*Auto-generated by Claude per Appmelia Instruction Set v2*
