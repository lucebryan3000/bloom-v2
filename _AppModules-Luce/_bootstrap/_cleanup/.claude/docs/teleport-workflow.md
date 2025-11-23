# Claude Code Teleport Workflow

## Quick Reference

```bash
# Before teleporting from CLI to web or vice versa
git add -A && git commit -m "WIP: checkpoint before teleport"
claude --teleport session_XXXXX

# No push required! Commits stay local until you're ready
```

## Understanding Sessions

- **Web Session**: Runs on Claude servers, accessed via browser
- **CLI Session**: Runs locally on your machine
- **Teleport**: Connect CLI to an existing web session

## Clean Working Directory Requirement

Teleport requires `git status` to show no uncommitted changes because:

1. Prevents confusion between local file state and remote session state
2. Ensures you have a checkpoint to return to
3. Forces intentional decision-making about work-in-progress

## Common Scenarios

### Scenario 1: Started in Web, Want to Continue in CLI

```bash
# In your local repo
git add -A
git commit -m "WIP: local changes before teleport"
claude --teleport session_011CV5EeQb4qBQkvnvABE8eX

# Continue conversation in CLI
# When done, push if needed: git push
```

### Scenario 2: Started in CLI, Switching to Web

Just switch to web interface - no teleport needed. Your CLI session stops.

### Scenario 3: Frequent Switching

Create a helper script:

```bash
#!/bin/bash
# ~/bin/teleport-bloom

SESSION_ID=$1
cd /home/luce/apps/bloom

# Auto-commit if working directory dirty
if [[ -n $(git status -s) ]]; then
    echo "📝 Auto-committing changes..."
    git add -A
    git commit -m "WIP: Auto-checkpoint $(date +'%Y-%m-%d %H:%M:%S')"
fi

# Teleport
claude --teleport "$SESSION_ID"
```

Make executable: `chmod +x ~/bin/teleport-bloom`

Use: `teleport-bloom session_011CV5EeQb4qBQkvnvABE8eX`

## What Gets Synced vs. What Doesn't

### ✅ Synced (via teleport)
- Conversation history
- Session context
- Tool calls and results

### ❌ NOT Synced
- Local file changes you made manually
- Files created by the remote session (stay on server until you run the commands locally)
- Git commits/branches

## Recovery Options

If you teleport and lose track of changes:

```bash
# View recent commits
git log --oneline -10

# View uncommitted changes (if any)
git status
git diff

# View stashed changes
git stash list
git stash show -p stash@{0}
```

## Best Practice

**Always commit before teleporting** - commits are cheap, local, and don't require pushing. It creates a safety checkpoint.

```bash
# Quick commit
git add -A && git commit -m "WIP: checkpoint"

# Teleport
claude --teleport session_XXXXX

# Later, amend or squash WIP commits if needed
git rebase -i HEAD~3
```
