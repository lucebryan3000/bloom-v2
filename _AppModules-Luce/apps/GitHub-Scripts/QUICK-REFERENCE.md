# GitHub Scripts - Quick Reference Card

## Launch Script
```bash
cs-gh              # Opens interactive menu
```

## GitHub Actions Toggle (Advanced Menu)

### Show Status
```bash
cs-gh
→ 8 (Advanced) → 7 (View GitHub Actions status)
# Shows current workflow status
```

### Disable All Workflows
```bash
cs-gh
→ 8 → 10 → 1 → Y
# CI/CD won't run until re-enabled
```

### Enable All Workflows
```bash
cs-gh
→ 8 → 10 → 2 → Y
# CI/CD will run on next push
```

### Disable One Workflow
```bash
cs-gh
→ 8 → 10 → 3 → [select number] → Y
# Select specific workflow to disable
```

### Enable One Workflow
```bash
cs-gh
→ 8 → 10 → 4 → [select number] → Y
# Select specific workflow to enable
```

## Cost Management Workflow

### During Development (Save Money)
```bash
# 1. Disable workflows
cs-gh → 8 → 10 → 1 → Y

# 2. Make commits freely without CI running
git add .
git commit -m "wip: feature development"
git push

# 3. When ready, re-enable workflows
cs-gh → 8 → 10 → 2 → Y

# 4. Final commit for CI testing
git commit -m "feat: complete feature"
git push
```

### Alternative: Use [skip ci] Flag
```bash
# Single-line way to skip CI for one commit
git commit -m "wip: testing [skip ci]"

# Or after commit
git push origin main --force  # if allowed

# But toggle method is cleaner for batches!
```

## Common Tasks

| Task | Menu Option |
|------|-------------|
| Commit changes | 1 |
| Session merge & cleanup | 2 |
| Generate PR command | 3 |
| Claude Code Web guide | 4 |
| GitHub CLI reference | 5 |
| Git/GitHub healthcheck | 6 |
| Setup Git config | 7 |
| **Advanced menu** | **8** |
| View diff code | 8 → 1 |
| Stash changes | 8 → 2 |
| Manage stashes | 8 → 3 |
| Discard changes | 8 → 4 |
| Branch manager | 8 → 5 |
| Cleanup merged branches | 8 → 6 |
| View GitHub Actions status | 8 → 7 |
| View recent commits | 8 → 8 |
| List workflows | 8 → 9 |
| **Toggle workflows** | **8 → 10** |
| Account-wide Actions toggle | 8 → 11 |
| Check for gh CLI updates | 8 → 12 |

## Troubleshooting

### "GitHub CLI (gh) is not installed"
```bash
# The script will automatically prompt to install on first run
# Or install manually:
curl -fsSL https://cli.github.com/install.sh | bash
```

### Workflow toggle isn't working
```bash
# Verify gh CLI is authenticated
gh auth status

# Check that you're in the repo
pwd   # Should be /home/luce/apps/bloom or similar
```

### Workflows aren't showing
```bash
# Verify workflows exist
ls .github/workflows/

# List with details
gh workflow list --json name,state
```

## Key Features

✅ **Disable all** - One command to halt CI/CD costs
✅ **Enable all** - One command to resume CI/CD
✅ **Per-workflow** - Disable only specific workflows
✅ **Status display** - Always see what's active/disabled
✅ **Confirmations** - No accidental changes
✅ **Fast** - Takes seconds to toggle

## Location & Alias

- **Script:** `/home/luce/_AppModules-Luce/GitHub-Scripts/gh.sh`
- **Alias:** `cs-gh` (via zshell)
- **Config:** `/home/luce/.zshrc` (line 27)

## Need Help?

```bash
# Interactive help from script
cs-gh → 4   # Claude Code Web guide
cs-gh → 5   # GitHub CLI reference
cs-gh → 6   # Git/GitHub healthcheck
cs-gh → 8 → 12   # Check for gh CLI updates
```

---

**Last Updated:** November 15, 2025
**For detailed info:** See README.md or IMPLEMENTATION-SUMMARY.md

> **Architecture:** `cs-gh` points to `gh.sh`, which bootstraps paths via `lib/common.sh`, loads all operational helpers from `lib/core.sh`, and then enters either the interactive menu or (in future) CLI subcommands.
