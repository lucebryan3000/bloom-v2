# TokenHeadroom: The Cognitive Capacity Manager for Claude

TokenHeadroom is the diagnostic and optimization layer that exists between your large codebase and Claude's fixed context window. By intelligently managing your project's context, TokenHeadroom's goal is to increase the AI's effective "headroom"—the space dedicated to complex reasoning and deep problem-solving—while drastically reducing token waste and associated costs.

The tool elevates context management from a manual chore to an automated, policy-driven process, ensuring Claude only sees the most essential code for any given task.

## The Core Concept: Headroom for Thought

The TokenHeadroom metric is defined as:

```
TokenHeadroom = Raw Context Tokens - Optimized Context Tokens
```

A high TokenHeadroom means your LLM is not wasting tokens reading irrelevant data (like `node_modules/` or old build artifacts). This translates directly to reduced cognitive load for Claude, allowing it to provide more precise, insightful, and comprehensive responses without hitting budget constraints.

## Quick Start

```bash
# Interactive mode
./token_headroom.sh

# Quick analysis
./token_headroom.sh -a analyze.quick

# Apply all ignore optimizations
./token_headroom.sh -a apply.ignores --force

# CI mode with JSON report
./token_headroom.sh --ci --json-report=report.json
```

## The Four Pillars of Optimization

TokenHeadroom operates through a menu-driven Bash utility (powered by embedded Python for JSON) that provides four main functional capabilities:

### 1. Analysis: Token Cost & Relevance Diagnosis

This pillar provides Claude with the necessary diagnostic information to understand its own context footprint.

- **Quick Scans & Deep Breakdowns**: Generates immediate token cost estimates per path, helping to pinpoint the "heavy hitters" in your codebase.
- **Budget Alignment**: Compares the projected context size against your configurable token budget (`--budget=N`, default 200,000) and alerts you to potential overruns.

**Actions:**
- `analyze.quick` - High-level token and file counts
- `analyze.deep` - Full JSON report of all analyzed paths

### 2. Suggestions: Policy-Driven Optimization

TokenHeadroom uses heuristic analysis to proactively suggest improvements, maximizing the potential TokenHeadroom.

- **Ignore Pattern Recommendations**: Identifies large, unnecessary directories (like `node_modules/`, `dist/`, `logs/`) that are not yet in your `.claudeignore` and proposes appending them to reclaim space.
- **Settings Tweaks**: Offers proposals to refine `.claude/settings.json`, such as recommending ways to tighten `autoIncludePatterns` that match excessive files (>50), thus reducing unnecessary default context.
- **Archival Candidates**: Suggests documentation or large data files for archival or exclusion, preserving valuable TokenHeadroom.

**Actions:**
- `suggest.ignores` - Recommended paths for `.claudeignore`
- `suggest.settings` - Proposals for autoInclude/permissions.deny
- `suggest.commands` - Identify large command definitions
- `suggest.docs` - Find large docs for potential archival

### 3. Application: Safe, Controlled Context Transformation

This feature is the primary engine for implementing change safely across configuration files (`.claudeignore` and `.claude/settings.json`).

**Verbs with Guardrails**: Transformation actions, or "verbs" (e.g., `append_recommended_patterns`, `prune_alwaysInclude`, `deduplicate_patterns`), are executed with extreme caution.

**Safety Features**:
- **Confirmation Gates**: Requires explicit user approval (or `--yes` / `--ci` flags)
- **Dry-Run Previews** (`-n`): Shows the exact changes to be applied before writing
- **Automatic Backups**: Creates safe backups in `.claude/backups/` to prevent accidental data loss
- **Immutable Policy**: Obeys the `context_policy.json`, protecting critical paths (like `.claude/agents/**`) from accidental modification or exclusion

**Actions:**
- `apply.ignores` - Append recommends, dedupe patterns
- `apply.settings` - Prune alwaysInclude, add deny permissions

### 4. Tools: Direct Management & Validation

Provides essential utilities for direct configuration file manipulation and maintenance.

- **Config Editing & Validation**: Allows direct editing and provides JSON validation for configuration files, ensuring structural integrity before they are used by Claude.
- **CI/Automation Support**: Supports a non-interactive CI mode (`--ci`) for automated pipelines, allowing TokenHeadroom optimization to be an integrated part of your development workflow.

**Actions:**
- `tools.open_claudeignore` - Open .claudeignore in editor
- `tools.open_settings` - Open settings.json in editor
- `tools.validate_json` - Validate settings.json syntax
- `tools.rerun` - Rerun analysis with current state

## CLI Reference

```
TokenHeadroom: The Cognitive Capacity Manager

USAGE
  token_headroom.sh [flags]

FLAGS
  -h, --help            Show help (The Four Pillars)
  -V, --version         Show version/build info
  -n, --dry-run         Print previews/commands; execute nothing; no logs
  -v, --verbose         Verbose output
  -l, --log=MODE        Log mode: off|on|critical (default: off)
  -a, --action=ID       Run a non-interactive action by ID (e.g., suggest.ignores)
      --list-actions    List all available non-interactive action IDs
  -f, --force           Force apply operations without interactive confirmation
      --yes             Alias for --force / Assume Yes to all questions
      --budget=N        Set token budget target (default 200000)
      --root=P          Set the source project root
      --ci              CI mode (non-interactive; no applies unless --force)
      --json-report=F   Write JSON report to file

PRECEDENCE
  --dry-run > --log > --verbose

EXIT CODES
  0   OK
  8   Findings present (CI info)
  16  Policy invalid/missing (ABORT by policy)
  32  Runtime error (I/O, parse, unexpected)
```

## Available Action IDs

```
analyze.quick          # Quick summary of token usage
analyze.deep           # Full JSON breakdown

suggest.ignores        # Suggest ignore patterns
suggest.settings       # Suggest settings tweaks
suggest.commands       # Suggest command trimming
suggest.docs           # Suggest docs archival

apply.ignores          # Apply .claudeignore edits
apply.settings         # Apply settings.json edits

tools.open_claudeignore  # Open .claudeignore
tools.open_settings      # Open settings.json
tools.validate_json      # Validate JSON syntax
tools.rerun              # Rerun analysis
```

## Directory Structure

```
context-opt/
├── token_headroom.sh      # Main entry point (CLI)
├── registry.sh            # Loads menus and verbs
├── context_policy.json    # Policy configuration
├── README.md              # This file
├── lib/
│   ├── ui.sh              # UI utilities (colors, prompts)
│   ├── run.sh             # Runtime utilities (paths, backups)
│   ├── policy.sh          # Policy management
│   ├── ci.sh              # CI/automation support
│   ├── dispatch.sh        # Verb dispatch system
│   └── analysis.sh        # Context analysis engine
├── menus/
│   ├── analyze.sh         # Pillar 1: Analysis menu
│   ├── suggest.sh         # Pillar 2: Suggestions menu
│   ├── apply.sh           # Pillar 3: Application menu
│   └── tools.sh           # Pillar 4: Tools menu
└── verbs/
    ├── append_recommended_patterns.sh
    ├── deduplicate_patterns.sh
    ├── prune_alwaysInclude.sh
    ├── add_permissions_deny.sh
    └── tighten_auto_include.sh
```

## Configuration: context_policy.json

The policy file defines which paths are immutable (protected) and which verbs are allowed on editable targets:

```json
{
  "schemaVersion": 1,
  "immutable": [
    ".claude/agents/**",
    ".claude/README.md",
    ".claude/URL-CONVENTION.md",
    ".claude/config.json"
  ],
  "editable": {
    ".claudeignore": [
      "append_recommended_patterns",
      "deduplicate_patterns"
    ],
    ".claude/settings.json": [
      "prune_alwaysInclude",
      "add_permissions_deny",
      "tighten_auto_include"
    ]
  },
  "exceptions": [
    "!.claude/agents/backend-typescript-architect.md"
  ]
}
```

## Verbs Reference

| Verb | Target | Description |
|------|--------|-------------|
| `append_recommended_patterns` | `.claudeignore` | Append verified ignore patterns that exist on disk |
| `deduplicate_patterns` | `.claudeignore` | Remove duplicate lines while preserving comments |
| `prune_alwaysInclude` | `.claude/settings.json` | Remove non-existent paths from alwaysInclude |
| `add_permissions_deny` | `.claude/settings.json` | Add permissions.deny entries to block heavy paths |
| `tighten_auto_include` | `.claude/settings.json` | Suggest narrowing high-match autoIncludePatterns |

## CI/CD Integration

TokenHeadroom supports non-interactive CI mode for automated pipelines:

```bash
# Run in CI with JSON report output
./token_headroom.sh --ci --json-report=context-report.json

# Force apply optimizations in CI
./token_headroom.sh --ci --force -a apply.ignores

# Check for findings (exit code 8 if findings present)
./token_headroom.sh --ci -a analyze.quick
```

## Requirements

- **Bash 4+** (macOS ships with older bash; use `brew install bash` for latest)
- **Python 3** (for JSON manipulation)
- **jq** (for JSON output formatting)

## License

Part of the OmniForge project. See main repository for license details.
