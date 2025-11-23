# Index Update Script - Documentation

## Overview

`update-indexes.sh` is an automated tool that keeps all Claude context management index files in sync with the actual directory structure.

**Location:** `.claude/docs/context-management-claude/update-indexes.sh`

**Purpose:** Eliminate manual maintenance of index files by automatically scanning and cataloging:
- `.claude/agents/` → `index-agents.md`
- `.claude/prompts/` → `index-prompts.md`
- `.claude/commands/` → `index-slash-commands.md`
- `_AppModules-Luce/` → `index-gitignore-claude.ignore.md`
- `.claude/` root files → `index-other.md`

---

## Quick Start

### Basic Usage

```bash
# Update all indexes
./update-indexes.sh

# Update only specific indexes
./update-indexes.sh agents
./update-indexes.sh prompts commands
./update-indexes.sh gitignore

# Dry-run (preview changes without modifying files)
./update-indexes.sh --dry-run

# Verbose output (shows detailed scan info)
./update-indexes.sh --verbose

# Combined options
./update-indexes.sh --dry-run --verbose agents prompts
```

### Show Help

```bash
./update-indexes.sh --help
```

---

## Options

### Positional Arguments

| Argument | Purpose |
|----------|---------|
| `agents` | Update agent index (`.claude/agents/`) |
| `prompts` | Update prompts index (`.claude/prompts/`) |
| `commands` / `slash-commands` | Update slash commands index (`.claude/commands/`) |
| `gitignore` | Update gitignored directory index (`_AppModules-Luce/`) |
| `other` | Update miscellaneous files index (`.claude/` root) |
| *(none)* | Update **all** indexes (default) |

### Flags

| Flag | Purpose |
|------|---------|
| `--help` | Display help text and exit |
| `--dry-run` | Preview changes without modifying files |
| `--verbose` | Show detailed scan information |

---

## Output

### Success Output

```
ℹ Context Management Index Updater
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Project Root: /home/luce/apps/bloom
Context Dir:  /home/luce/apps/bloom/.claude/docs/context-management-claude
Timestamp:    2025-11-17 15:52:18
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ℹ Scanning agents directory...
✓ Updated: index-agents.md (15 agents indexed)
ℹ Scanning prompts directory...
✓ Updated: index-prompts.md (1 prompts indexed)
...
✓ Index update completed!
```

### Dry-Run Output

```
ℹ Running in DRY-RUN mode (no changes will be made)
...
⚠ DRY-RUN completed. No changes were made.
Run without --dry-run to apply changes.
```

---

## How It Works

### Scanning Process

1. **Agent Files** (`.claude/agents/`)
   - Finds all `.md` files
   - Extracts filename and generates entry
   - Counts total agents

2. **Prompt Files** (`.claude/prompts/`)
   - Finds all `.md` files
   - Lists with descriptions
   - Counts total prompts

3. **Slash Commands** (`.claude/commands/`)
   - Finds all `.md` files
   - Extracts frontmatter description
   - Generates command entries

4. **Gitignored Directory** (`_AppModules-Luce/`)
   - Lists all subdirectories
   - Counts files per subdirectory
   - Generates hierarchical index

5. **Other Files** (`.claude/` root)
   - Finds all root-level `.md` files
   - Generates file listing

### Update Mechanism

Each index file is regenerated with:
- **Header**: Category-specific documentation
- **Auto-Scanned Section**: Machine-generated file list
- **Timestamp**: Last update time
- **File Counts**: Total files/entries per category

---

## Workflow Integration

### Daily Development

Run before committing changes that add/remove agents, prompts, or commands:

```bash
.claude/docs/context-management-claude/update-indexes.sh
git add .claude/docs/context-management-claude/index-*.md
git commit -m "chore: update Claude context indexes"
```

### Adding New Files

**Example:** You added a new agent `lib-security-auditor.md`

```bash
# Create the file
cp agent-template.md agents/lib-security-auditor.md

# Update indexes
./.claude/docs/context-management-claude/update-indexes.sh agents

# Verify changes
git diff .claude/docs/context-management-claude/index-agents.md

# Commit
git add .claude/agents/lib-security-auditor.md \
        .claude/docs/context-management-claude/index-agents.md
git commit -m "feat: add lib-security-auditor agent"
```

### Pre-PR Checklist

```bash
# Update all indexes
cd .claude/docs/context-management-claude/
./update-indexes.sh

# Check for changes
git status

# If any index files changed, commit them
git add index-*.md
git commit -m "chore: update context indexes"
```

---

## Technical Details

### Script Architecture

| Component | Purpose |
|-----------|---------|
| **Helper Functions** | Logging, file operations, formatting |
| **Index Functions** | One function per index type |
| **Main Function** | Orchestrates updates, parses arguments |
| **Color Coding** | Visual feedback (info, success, warning, error) |

### File Operations

- **Read**: Scans directories with `find` and `grep`
- **Write**: Overwrites index files with new content
- **Safe**: Uses ANSI escape codes, proper error handling
- **Fast**: No external dependencies, pure bash

### Performance

- **Execution Time**: ~1-2 seconds (typical)
- **I/O**: Minimal file writes
- **CPU**: Light scanning overhead

---

## Maintenance

### Manual Editing

Index files can be manually edited to add:
- Custom documentation sections
- Category groupings
- Implementation notes

**However**: Manual sections ABOVE the auto-generated section are preserved across updates.

### Safe Modifications

❌ **DON'T modify** the auto-scanned section
✅ **DO add** custom documentation above the `### Auto-Scanned Files` marker

---

## Troubleshooting

### Script Not Executable

```bash
chmod +x .claude/docs/context-management-claude/update-indexes.sh
```

### Permission Denied

Ensure you have write access to `.claude/docs/context-management-claude/`:

```bash
ls -ld .claude/docs/context-management-claude/
# Should show: drwxrwxr-x (or similar with write permission)
```

### No Output

The script runs silently if no changes occur. Use `--verbose` to see details:

```bash
./update-indexes.sh --verbose
```

### Directory Not Found

Verify the project structure:

```bash
# Should exist:
ls -d .claude/agents/
ls -d .claude/prompts/
ls -d .claude/commands/
ls -d _AppModules-Luce/
```

---

## Examples

### Update All Indexes

```bash
cd /home/luce/apps/bloom/.claude/docs/context-management-claude
./update-indexes.sh
```

**Output:**
```
✓ Updated: index-agents.md (15 agents indexed)
✓ Updated: index-prompts.md (1 prompts indexed)
✓ Updated: index-slash-commands.md (26 commands indexed)
✓ Updated: index-gitignore-claude.ignore.md (36 files indexed)
✓ Updated: index-other.md (2 files indexed)
✓ Index update completed!
```

### Preview Changes Before Updating

```bash
./update-indexes.sh --dry-run --verbose agents
```

**Output:**
```
ℹ Running in DRY-RUN mode (no changes will be made)
→ Found 15 agent files
→ [DRY-RUN] Would update: index-agents.md (15 agents)
⚠ DRY-RUN completed. No changes were made.
```

### Update Single Category

```bash
./update-indexes.sh commands
```

**Output:**
```
✓ Updated: index-slash-commands.md (26 commands indexed)
✓ Index update completed!
```

---

## Related Files

- **index-agents.md** - Agent catalog (auto-generated)
- **index-prompts.md** - Prompt catalog (auto-generated)
- **index-slash-commands.md** - Command catalog (auto-generated)
- **index-gitignore-claude.ignore.md** - Gitignored directory index (auto-generated)
- **index-other.md** - Miscellaneous files index (auto-generated)
- **context-management.md** - Main context management documentation

---

*Last Updated: 2025-11-17*
