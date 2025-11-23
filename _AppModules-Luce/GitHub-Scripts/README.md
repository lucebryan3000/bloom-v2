# GitHub Scripts Module

Collection of GitHub and Git management tools for local development.

## Scripts

### gh.sh - Git & GitHub Manager
**Location:** `/home/luce/_AppModules-Luce/GitHub-Scripts/gh.sh`
**Alias:** `cs-gh` (available via zshell)

Interactive menu-based tool for Git and GitHub operations with 22 menu options:

#### Workspace Info
1. Status snapshot - Current working tree status
2. Clean check - Verify clean state
3. Commit log - Recent commit history
4. View diff - Review changes

#### Save Work
5. Commit changes - Stage and commit
6. Stash changes - Save changes with notes

#### Restore & Discard
7. Manage stashes - List, restore, or delete stashes
8. Discard changes - Remove all/file/untracked changes

#### Branch Management
9. Branch manager - List, merge, delete branches interactively
10. Cleanup claude/* remotes - Bulk delete merged session branches

#### Claude Code Web
11. Session merge & cleanup - Automated session workflow
12. Generate PR command - Copy-paste gh pr create command
13. Help & workflow guide - Full documentation
14. GitHub CLI reference - Quick command reference

#### GitHub Actions
15. Check Actions status - View failing checks and logs
16. Check last 5 commits - Find failing actions in recent commits
17. Manage workflows - View/edit workflow files
18. **Toggle Actions CI/CD** - Enable/disable workflows (repo-level)
23. **Account-wide Actions** - Enable/disable workflows across ALL repositories

#### Configuration & Diagnostics
19. Setup Git config - Create/edit scripts/gh.config
20. Create PR template - Create/edit .github/pull_request_template.md
21. Install GitHub CLI - Install gh command-line tool
22. Git/GitHub healthcheck - Snapshot repo & remote state

## New Feature: Toggle GitHub Actions (Option 18)

### Purpose
Helps manage GitHub Actions CI/CD costs by enabling/disabling workflows without committing empty changes or using `[skip ci]` flags.

### Usage
```bash
cs-gh
# Select option 18
```

### Options
1. **Disable all workflows** - Prevents CI from running on next commits
2. **Enable all workflows** - Re-enables CI/CD pipeline
3. **Disable specific workflow** - Select individual workflow to disable
4. **Enable specific workflow** - Re-enable individual workflow

### How It Works
- Shows current workflow status (active/disabled counts)
- Uses GitHub CLI (`gh workflow`) to manage workflows
- Requires confirmation before making changes
- Provides tips on alternative methods

### Requirements
- GitHub CLI installed (`gh` command)
- Proper GitHub authentication configured
- Read/write access to repository workflows

## New Feature: Account-Wide GitHub Actions Control (Option 23)

### Purpose
Manage GitHub Actions workflows **across all repositories** in your account to handle billing costs and CI/CD resource management. Especially useful for:
- Disabling all Actions account-wide to avoid billing charges
- Re-enabling Actions after resolving payment issues
- Checking workflow status across your entire account
- Quick cost control during development freezes

### Usage
```bash
cs-gh
# Select option 23
```

### Options
1. **Disable all workflows** - Pause CI/CD across ALL repositories
2. **Enable all workflows** - Resume CI/CD across ALL repositories
3. **Show detailed status** - View workflow status for each repository

### How It Works
- Shows current status across all repositories (active vs disabled counts)
- Loops through all your repositories
- For each repo, finds active/disabled workflows using GitHub CLI
- Disables/enables each workflow by ID
- Displays summary with success/failure counts
- Warns about protected workflows (Dependabot, Dependency Submission)

### Key Differences from Option 18 (Repo-Level Control)

| Aspect | Option 18 (Repo) | Option 23 (Account) |
|--------|---|---|
| Scope | Single repository | All repositories |
| Workflow selection | Per-repo + specific workflow | All at once |
| Use case | Manage one project's CI | Pause billing-consuming Actions |
| Time to execute | <5 seconds | 30-60 seconds |
| Protected workflows | N/A | Dependabot stays active (GitHub limitation) |

### Examples

**Disable all Actions to save costs:**
```bash
cs-gh
# Option 23 → 1 → Confirm
# All workflows disabled across all 18 repositories
```

**Check status before re-enabling:**
```bash
cs-gh
# Option 23 → 3 → Show detailed status
# See: 14 disabled, 2 protected (Dependabot)
```

**Re-enable after billing is resolved:**
```bash
cs-gh
# Option 23 → 2 → Confirm
# All workflows re-enabled
```

### Requirements
- GitHub CLI installed (`gh` command)
- Proper GitHub authentication configured
- Read/write access to all repository workflows
- Network connectivity to GitHub

### Notes
- Protected workflows (Dependabot, Dependency Submission) cannot be disabled via CLI
- To manage protected workflows, use: https://github.com/settings/security_and_analysis
- Changes take effect on next commit/push to each repository
- Large accounts (15+ repos) may take 30-60 seconds to process

## Installation

The script is automatically linked via zshell alias:
```bash
alias cs-gh='/home/luce/_AppModules-Luce/GitHub-Scripts/gh.sh'
```

To use from any directory:
```bash
cs-gh
```

## Features

### Interactive Menus
- Comprehensive workflow for Git operations
- Branch management with safety checks
- Stash management utilities

### GitHub Actions Management
- View workflow status and recent failures
- Disable/enable workflows individually or in bulk
- Check last 5 commits for failing CI

### Claude Code Session Support
- Automated merge and cleanup for session branches
- PR command generation
- Session workflow documentation

### Configuration
- Editable Git configuration
- PR template creation/editing
- GitHub CLI installation helper

## Dependencies

- `git` - Version control
- `gh` - GitHub CLI (v2.0+)
- `jq` - JSON parser (for workflow operations)
- `bash` - Shell (4.0+)
- `curl` - For GitHub CLI installation

## Configuration Files

- `.github/workflows/*.yml` - Workflow definitions
- `.github/pull_request_template.md` - PR template (created on demand)
- `scripts/gh.config` - User-specific git config (created on demand)

## References

- GitHub CLI Docs: https://cli.github.com/
- Git Documentation: https://git-scm.com/doc

---

**Maintained by:** Claude Code
**Last Updated:** November 15, 2025

## Modular Bash Layout

The GitHub Scripts module is now structured as:

- `gh.sh` — thin orchestrator (menu + CLI entrypoint). Safe to alias as `cs-gh`.
- `lib/common.sh` — shared colors, logging, editor preference, git/gh preflight checks, and path/config bootstrap (`gh_bootstrap_paths`, `gh_load_config`).
- `lib/core.sh` — all operational functions (workspace helpers, branch workflows, GitHub Actions helpers, Claude session utilities, menu rendering) factored out of `gh.sh`.
- `gh.conf` — optional project-local configuration file (for now: `GH_MENU_TITLE` to control the menu heading). Can be extended later with target branch, remotes, safety flags, etc.
- (Future) `scripts/` — optional workflow scripts that can be auto-discovered and exposed as dynamic menu entries.

The whole folder can be copied into another project; `gh.sh` will locate `lib/` and `gh.conf` relative to its own path and run without additional setup.
