# OmniForge Documentation Update Playbook

**Purpose**: Systematic workflow for updating OmniForge configuration and documentation files
**Execution Model**: Sonnet (planning) → Haiku (parallel execution) → Sonnet (validation)
**Session Scope**: Single chat session, does not override defaults

---

## Workflow Overview

```
┌─────────────────────────────────────────────────────────────┐
│ Phase 1: PLANNING (Sonnet)                                 │
│ - Analyze current state                                     │
│ - Create detailed task breakdown                           │
│ - Generate todo list                                        │
│ - Identify parallel work streams                           │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Phase 2: EXECUTION (Multiple Haiku Agents in Parallel)     │
│ - Spawn 3-5 agents for independent tasks                   │
│ - Each agent handles one specific file/task                │
│ - No dependencies between parallel tasks                   │
│ - All agents return summaries                              │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Phase 3: VALIDATION (Sonnet)                               │
│ - Review all agent outputs                                 │
│ - Validate syntax (bash -n for shell scripts)             │
│ - Verify consistency across files                          │
│ - Create comprehensive summary                             │
│ - Update todo list to completed                            │
└─────────────────────────────────────────────────────────────┘
```

---

## Task Breakdown

### 1. Configuration File Updates

**Files in Scope**:
- `_build/omniforge/bootstrap.conf` (main configuration)
- `_build/omniforge/example-files/bootstrap.conf.example` (template)
- `_build/omniforge/example-files/.env.example`
- `_build/omniforge/example-files/.nvmrc.example`
- `_build/omniforge/example-files/.eslintignore.example`

**Tasks**:
- [ ] Reorganize bootstrap.conf into clear sections (6 sections: Quick Start, Advanced, System, Phases, Profiles, Auto-Detected)
- [ ] Add section headers with ASCII separators
- [ ] Add inline comments for each setting group
- [ ] Create generalized .example template from main config
- [ ] Update .env.example with bootstrap mapping comments
- [ ] Sync version numbers across files (.nvmrc, package.json.example)
- [ ] Update ignore patterns for OmniForge-specific files (.tools/, .omniforge_state)

### 2. Documentation Updates

**Files in Scope**:
- `_build/omniforge/OMNIFORGE.md` (primary documentation)
- `_build/omniforge/README.md` (if exists)

**Tasks**:
- [ ] Create comprehensive architecture section
- [ ] Document all 26 lib modules with functions and purposes
- [ ] Document all 57 tech_stack scripts
- [ ] Add clear Quick Start section
- [ ] Document 6 stack profiles
- [ ] Document 6-phase system with metadata format
- [ ] Add extensibility guide
- [ ] Add development guide for contributors
- [ ] Include CLI reference with all commands
- [ ] Add troubleshooting section

### 3. Example Files Cleanup

**Files in Scope**:
- `_build/omniforge/example-files/` directory

**Tasks**:
- [ ] Remove obsolete Python-specific files (pyproject.toml, setup.cfg.example, .python-version.example, .venv.example)
- [ ] Ensure all config files have .example extension
- [ ] Update file headers with usage instructions
- [ ] Verify all files align with Next.js 15 + TypeScript stack

---

## Execution Instructions

### For Claude Code (Sonnet)

When executing this playbook:

1. **Start with Todo List**:
   ```
   Use TodoWrite tool to create initial task breakdown
   ```

2. **Analyze Current State**:
   - Read bootstrap.conf to understand current structure
   - Check file sizes and last modified dates
   - Review recent git commits for context
   - Identify what needs updating

3. **Create Execution Plan**:
   - Break work into 5-8 parallel tasks
   - Each task should be independent (no dependencies)
   - Assign each task to a Haiku agent
   - Specify clear deliverables for each agent

4. **Spawn Haiku Agents**:
   ```
   Use Task tool with model="haiku" and spawn 3-5 agents in a single message
   Each agent prompt should include:
   - Specific file path to modify
   - Exact changes to make
   - Expected output format
   - Validation steps
   ```

5. **Validate Results**:
   - Use bash -n for shell script syntax
   - Use Read tool to spot-check key sections
   - Verify file sizes are reasonable
   - Check for consistent formatting
   - Update todo list to mark completed

6. **Create Summary**:
   - List all files modified
   - Key improvements made
   - Before/after statistics
   - Any issues encountered

---

## Validation Checklist

### Configuration Files

- [ ] bootstrap.conf has 6 clear sections with headers
- [ ] bootstrap.conf syntax validated (`bash -n bootstrap.conf`)
- [ ] bootstrap.conf.example is generalized (no real passwords, generic names)
- [ ] .env.example includes all required variables with comments
- [ ] .nvmrc matches NODE_VERSION from bootstrap.conf
- [ ] All .example files have clear usage instructions in headers

### Documentation

- [ ] OMNIFORGE.md has complete Table of Contents
- [ ] All 26 lib modules documented with purposes and key functions
- [ ] All 6 phases documented with script counts and durations
- [ ] Architecture section includes data flow diagram
- [ ] Quick Start section has copy-paste commands
- [ ] CLI reference covers all commands with examples
- [ ] Extensibility section explains how to add custom phases

### Cleanup

- [ ] No Python-specific files in example-files/
- [ ] All config templates have .example extension
- [ ] File count in example-files/ reduced (was 19, now 15)
- [ ] No broken symlinks or empty files

### Consistency

- [ ] Version numbers match across all files (NODE_VERSION, PNPM_VERSION)
- [ ] All file headers follow consistent format
- [ ] Comments use consistent style (# for bash, // for JS/TS)
- [ ] Path references are consistent ($PROJECT_ROOT, $OMNIFORGE_DIR)

---

## Example Agent Prompts

### Agent 1: Reorganize bootstrap.conf

```
Your task is to reorganize `/path/to/bootstrap.conf` into 6 clear sections:

SECTION 1: QUICK START - USER CONFIGURABLE
SECTION 2: ADVANCED SETTINGS
SECTION 3: SYSTEM CONFIGURATION
SECTION 4: PHASE SYSTEM CONFIGURATION
SECTION 5: STACK PROFILES
SECTION 6: AUTO-DETECTED / INTERNAL

Preserve all 882 lines of content. Add clear headers with ASCII separators.
Add inline comments for each setting group.
Use Write tool to save updated file.
```

### Agent 2: Update .env.example

```
Your task is to update `/path/to/example-files/.env.example`:

Add 3 new variables: NEXTAUTH_URL, AUTH_TRUST_HOST, POSTGRES_HOST_AUTH_METHOD
Add bootstrap mapping comments explaining which conf variables map to which env vars
Update AI model to latest: claude-sonnet-4-20250929
Add clear section headers (Database, Auth, AI, Docker, etc.)
Use Edit or Write tool to update.
```

### Agent 3: Remove obsolete Python files

```
Your task is to remove 4 obsolete Python files from `/path/to/example-files/`:

Remove: pyproject.toml, setup.cfg.example, .python-version.example, .venv.example
Reason: OmniForge is Next.js + TypeScript, not Python
Use Bash tool to remove files.
Return list of removed files.
```

---

## Success Criteria

This playbook is successful when:

1. ✅ All configuration files are well-organized with clear sections
2. ✅ All documentation is comprehensive and production-ready
3. ✅ All example files are relevant to Next.js + TypeScript stack
4. ✅ All validation checks pass
5. ✅ Todo list shows all tasks completed
6. ✅ Summary document created with before/after statistics

---

## Post-Execution

After completing this playbook:

1. **Commit Changes**:
   ```bash
   git add _build/omniforge/
   git commit -m "docs(omniforge): reorganize config and update documentation

   - Reorganize bootstrap.conf into 6 clear sections
   - Update OMNIFORGE.md with comprehensive architecture docs
   - Clean up example-files (remove Python configs)
   - Update .env.example with bootstrap mappings
   - Sync version numbers across all files"
   ```

2. **Verification**:
   ```bash
   # Validate shell scripts
   bash -n _build/omniforge/bootstrap.conf
   bash -n _build/omniforge/example-files/bootstrap.conf.example

   # Check file counts
   ls -1 _build/omniforge/example-files/ | wc -l  # Should be 15

   # Verify documentation
   wc -l _build/omniforge/OMNIFORGE.md  # Should be ~2000+ lines
   ```

3. **Tag Release** (if applicable):
   ```bash
   git tag -a v3.0.1 -m "Documentation and configuration improvements"
   git push origin v3.0.1
   ```

---

## Notes

- This playbook is optimized for parallel execution (5 agents)
- Average execution time: 3-5 minutes with Haiku agents
- Sonnet planning: ~1 minute
- Haiku execution: ~2 minutes (parallel)
- Sonnet validation: ~1 minute
- Total: ~4 minutes for complete workflow

- Always use TodoWrite to track progress
- Always validate bash syntax with `bash -n`
- Always create a summary document
- Always update the todo list at the end

---

## Troubleshooting

**Issue**: Agent fails with syntax error
**Solution**: Review the Edit/Write tool usage - ensure exact string matching for old_string

**Issue**: Parallel agents have conflicting changes
**Solution**: Ensure tasks are truly independent - no two agents should modify the same file

**Issue**: Validation fails after completion
**Solution**: Run `bash -n` on each modified script to identify syntax errors

**Issue**: File not found during Read operation
**Solution**: Verify file paths are absolute, not relative

---

## Version History

- **v1.0** (2025-11-24): Initial playbook creation
  - Configuration reorganization
  - Documentation updates
  - Example files cleanup
  - Multi-agent parallel execution

---

## Related Playbooks

- [PLAYBOOK-hybrid-codex.md](PLAYBOOK-hybrid-codex.md) - Generic hybrid Claude + Codex workflow
- [CLAUDE.md](CLAUDE.md) - Project-specific Claude instructions
- `PLAYBOOK-refactor.md` - Code refactoring workflow (future)
- `PLAYBOOK-testing.md` - Testing and validation workflow (future)
- `PLAYBOOK-release.md` - Release preparation workflow (future)
