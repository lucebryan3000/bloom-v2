---
id: claude-hooks-quickref
topic: claude-code-hooks
file_role: quickref
profile: full
difficulty_level: all-levels
kb_version: 3.1
prerequisites: []
related_topics: [claude-code, bash-scripting, json]
embedding_keywords: [syntax, cheat-sheet, quick-reference, hooks-syntax, examples]
last_reviewed: 2025-11-13
---

# Claude Code Hooks - Quick Reference & Cheat Sheet

**Purpose**: Fast syntax lookup for all hook types, events, and patterns.

<!-- Query: "What's the syntax for a PostToolUse hook?" -->
<!-- Query: "How do I block a tool call with a hook?" -->
<!-- Query: "What exit codes should hooks use?" -->
<!-- Query: "How do I configure hooks in settings.json?" -->

---

## 📋 Table of Contents

1. [Configuration Syntax](#configuration-syntax)
2. [All 9 Hook Events](#all-9-hook-events)
3. [Command Hook Template](#command-hook-template)
4. [Prompt Hook Template](#prompt-hook-template)
5. [Matcher Patterns](#matcher-patterns)
6. [Input/Output Reference](#inputoutput-reference)
7. [Exit Codes](#exit-codes)
8. [Environment Variables](#environment-variables)
9. [Common Patterns](#common-patterns)
10. [Troubleshooting Checklist](#troubleshooting-checklist)

---

## Configuration Syntax

### Basic Structure

```json
{
 "hooks": {
 "<EVENT_NAME>": [
 {
 "matcher": {
 "tool_name": "pattern",
 "tool_input": "pattern"
 },
 "hooks": [
 {
 "type": "command",
 "command": "path/to/script.sh",
 "timeout": 60
 }
 ]
 }
 ]
 }
}
```

### Configuration Locations

```bash
# User-wide (all projects)
~/.claude/settings.json

# Project-specific (committed to repo)
.claude/settings.json

# Local overrides (not committed)
.claude/settings.local.json
```

### Minimal Hook Example

```json
{
 "hooks": {
 "Stop": [
 {
 "hooks": [
 {
 "type": "command",
 "command": ".claude/hooks/my-hook.sh"
 }
 ]
 }
 ]
 }
}
```

---

## All 9 Hook Events

### Tool Lifecycle Events

```json
{
 "hooks": {
 "PreToolUse": [/* Before tool executes - can block */],
 "PostToolUse": [/* After tool succeeds */]
 }
}
```

**Use Cases**:
- PreToolUse: Validate inputs, block dangerous operations
- PostToolUse: Format code, run tests, update indexes

### User Interaction Events

```json
{
 "hooks": {
 "UserPromptSubmit": [/* When user submits prompt */],
 "Stop": [/* When agent finishes response */],
 "SubagentStop": [/* When subagent completes */]
 }
}
```

**Use Cases**:
- UserPromptSubmit: Start metrics tracking, validate request
- Stop: End metrics tracking, send notifications
- SubagentStop: Track subagent performance

### Session Events

```json
{
 "hooks": {
 "SessionStart": [/* Session begins/resumes */],
 "SessionEnd": [/* Session terminates */]
 }
}
```

**Use Cases**:
- SessionStart: Inject environment context, initialize state
- SessionEnd: Cleanup, generate reports

### Other Events

```json
{
 "hooks": {
 "Notification": [/* Claude sends notification */],
 "PreCompact": [/* Before context compaction */]
 }
}
```

**Use Cases**:
- Notification: Custom alerts, external integrations
- PreCompact: Save state before context is reduced

---

## Command Hook Template

### Basic Shell Script

```bash
#!/bin/bash
#.claude/hooks/my-hook.sh

# 1. Read JSON input from stdin
INPUT=$(cat)

# 2. Extract fields (using jq)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# 3. Your logic
echo "Hook executed: $TOOL_NAME on $FILE_PATH"

# 4. Exit with appropriate code
exit 0 # 0 = success, 2 = block (PreToolUse only)
```

### Make Executable

```bash
chmod +x.claude/hooks/my-hook.sh
```

### With Error Handling

```bash
#!/bin/bash
set -euo pipefail # Exit on error, undefined vars, pipe failures

INPUT=$(cat)

# Validate input
if [ -z "$INPUT" ]; then
 echo "ERROR: No input received" >&2
 exit 1
fi

# Your logic here
#...

exit 0
```

---

## Prompt Hook Template

### Only for Stop and SubagentStop Events

```json
{
 "hooks": {
 "Stop": [
 {
 "hooks": [
 {
 "type": "prompt",
 "prompt": "Based on the following hook input, decide if we should continue: {hook_input}. Respond with JSON containing 'decision' (approve/block) and 'reason'.",
 "timeout": 30
 }
 ]
 }
 ]
 }
}
```

### Expected LLM Response

```json
{
 "decision": "approve",
 "reason": "All validations passed"
}
```

**Note**: Prompt hooks are limited to Stop and SubagentStop events.

---

## Matcher Patterns

### Exact Match

```json
{
 "matcher": {
 "tool_name": "Edit"
 }
}
```

Matches only `Edit` tool calls.

### Multiple Tools (Regex)

```json
{
 "matcher": {
 "tool_name": "Edit|Write"
 }
}
```

Matches `Edit` OR `Write` tool calls.

### Wildcard Match

```json
{
 "matcher": {
 "tool_name": ".*"
 }
}
```

Matches ALL tool calls.

### Tool Input Pattern (File Extension)

```json
{
 "matcher": {
 "tool_name": "Edit|Write",
 "tool_input": ".*\\.(ts|tsx)$"
 }
}
```

Matches Edit/Write on `.ts` or `.tsx` files.

### MCP Tool Matching

```json
{
 "matcher": {
 "tool_name": "mcp__memory__.*"
 }
}
```

Matches all tools from the `memory` MCP server.

### Case Sensitivity

**Matchers are CASE-SENSITIVE!**

```json
// ✅ Correct
{"tool_name": "Edit"}

// ❌ Wrong (won't match)
{"tool_name": "edit"}
```

---

## Input/Output Reference

### Common Input Fields (All Events)

```json
{
 "session_id": "abc123",
 "transcript_path": "/path/to/transcript.md",
 "cwd": "/project/directory",
 "permission_mode": "ask",
 "hook_event_name": "PostToolUse"
}
```

### PreToolUse Input

```json
{
 "tool_name": "Edit",
 "tool_input": {
 "file_path": "/path/to/file.ts",
 "old_string": "before",
 "new_string": "after"
 },
 "session_id": "abc123",
 "hook_event_name": "PreToolUse"
}
```

### PostToolUse Input

```json
{
 "tool_name": "Edit",
 "tool_input": {
 "file_path": "/path/to/file.ts"
 },
 "tool_output": "File edited successfully",
 "session_id": "abc123",
 "hook_event_name": "PostToolUse"
}
```

### UserPromptSubmit Input

```json
{
 "user_prompt": "Refactor this function",
 "session_id": "abc123",
 "hook_event_name": "UserPromptSubmit"
}
```

### Stop Input

```json
{
 "session_id": "abc123",
 "transcript_path": "/path/to/transcript.md",
 "hook_event_name": "Stop"
}
```

### SessionStart Input

```json
{
 "session_id": "abc123",
 "is_resume": false,
 "hook_event_name": "SessionStart"
}
```

### Output Formats

**Standard (stdout/stderr)**:
```bash
echo "Success message" # Shows in transcript
echo "Error message" >&2 # Shows as error
exit 0 # Success
```

**JSON Response (for advanced control)**:
```json
{
 "continue": true,
 "reason": "Validation passed",
 "suppressOutput": false
}
```

**Blocking (PreToolUse only)**:
```bash
echo "❌ Operation blocked" >&2
exit 2
```

---

## Exit Codes

| Code | Meaning | Effect | When to Use |
|------|---------|--------|-------------|
| `0` | Success | Continue execution | Normal completion |
| `2` | Block | Stop operation | PreToolUse validation failure |
| Other (1, 3+) | Error | Logged, continues | Unexpected errors |

### Examples

```bash
# Success - continue
exit 0

# Block operation (PreToolUse only)
echo "Cannot edit this file" >&2
exit 2

# Error (logged but doesn't block)
echo "Warning: validation failed" >&2
exit 1
```

---

## Environment Variables

### Available in All Hooks

```bash
$CLAUDE_PROJECT_DIR # Project root directory
$CLAUDE_CODE_REMOTE # "true" if remote execution
```

### SessionStart Hook Only

```bash
$CLAUDE_ENV_FILE # Path to file for persisted env vars
```

**Usage** (SessionStart hook):
```bash
#!/bin/bash
# Set environment variables for all subsequent bash commands
cat >> "$CLAUDE_ENV_FILE" << EOF
export MY_VAR="value"
export DATABASE_URL="sqlite://local.db"
EOF
```

### Plugin Hooks

```bash
$CLAUDE_PLUGIN_ROOT # Plugin directory root
```

---

## Common Patterns

### Pattern 1: Auto-Format Code (PostToolUse)

**settings.json**:
```json
{
 "hooks": {
 "PostToolUse": [
 {
 "matcher": {
 "tool_name": "Edit|Write",
 "tool_input": ".*\\.(ts|tsx|js|jsx)$"
 },
 "hooks": [
 {
 "type": "command",
 "command": "npx prettier --write ${tool_input.file_path}",
 "timeout": 10
 }
 ]
 }
 ]
 }
}
```

### Pattern 2: Block Sensitive File Edits (PreToolUse)

**settings.json**:
```json
{
 "hooks": {
 "PreToolUse": [
 {
 "matcher": {
 "tool_name": "Edit|Write",
 "tool_input": "\\.(env|secrets\\.json|credentials)"
 },
 "hooks": [
 {
 "type": "command",
 "command": ".claude/hooks/block-sensitive.sh"
 }
 ]
 }
 ]
 }
}
```

**block-sensitive.sh**:
```bash
#!/bin/bash
echo "❌ Cannot edit sensitive configuration files" >&2
exit 2
```

### Pattern 3: Run Tests After Editing Test Files

**settings.json**:
```json
{
 "hooks": {
 "PostToolUse": [
 {
 "matcher": {
 "tool_name": "Edit|Write",
 "tool_input": ".*\\.test\\.(ts|tsx|js)$"
 },
 "hooks": [
 {
 "type": "command",
 "command": "npm test -- --findRelatedTests ${tool_input.file_path}",
 "timeout": 60
 }
 ]
 }
 ]
 }
}
```

### Pattern 4: Track Task Metrics (UserPromptSubmit + Stop)

**settings.json**:
```json
{
 "hooks": {
 "UserPromptSubmit": [
 {
 "hooks": [
 {
 "type": "command",
 "command": ".claude/hooks/start-tracking.sh",
 "timeout": 5
 }
 ]
 }
 ],
 "Stop": [
 {
 "hooks": [
 {
 "type": "command",
 "command": ".claude/hooks/stop-tracking.sh",
 "timeout": 10
 }
 ]
 }
 ]
 }
}
```

**start-tracking.sh**:
```bash
#!/bin/bash
METRICS_FILE="/tmp/claude-metrics.json"
cat > "$METRICS_FILE" << EOF
{
 "startTime": "$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")",
 "startTokens": ${CURRENT_TOKENS:-0}
}
EOF
exit 0
```

**stop-tracking.sh**:
```bash
#!/bin/bash
METRICS_FILE="/tmp/claude-metrics.json"

if [ -f "$METRICS_FILE" ]; then
 START_TIME=$(cat "$METRICS_FILE" | jq -r '.startTime')
 END_TIME=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

 echo "📊 Task completed"
 echo " Start: $START_TIME"
 echo " End: $END_TIME"

 rm -f "$METRICS_FILE"
fi

exit 0
```

### Pattern 5: Inject Project Context (SessionStart)

**settings.json**:
```json
{
 "hooks": {
 "SessionStart": [
 {
 "hooks": [
 {
 "type": "command",
 "command": ".claude/hooks/setup-env.sh"
 }
 ]
 }
 ]
 }
}
```

**setup-env.sh**:
```bash
#!/bin/bash
# Inject environment variables for all bash commands in this session
cat >> "$CLAUDE_ENV_FILE" << EOF
export NODE_ENV="development"
export DATABASE_URL="file:./dev.db"
export LOG_LEVEL="debug"
EOF

echo "✅ Development environment initialized"
exit 0
```

### Pattern 6: Log All Tool Calls

**settings.json**:
```json
{
 "hooks": {
 "PostToolUse": [
 {
 "matcher": {
 "tool_name": ".*"
 },
 "hooks": [
 {
 "type": "command",
 "command": ".claude/hooks/audit-log.sh"
 }
 ]
 }
 ]
 }
}
```

**audit-log.sh**:
```bash
#!/bin/bash
INPUT=$(cat)
AUDIT_LOG="$HOME/.claude/audit.log"

echo "[$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")] $INPUT" >> "$AUDIT_LOG"

exit 0
```

### Pattern 7: Custom Notification

**settings.json**:
```json
{
 "hooks": {
 "Notification": [
 {
 "hooks": [
 {
 "type": "command",
 "command": ".claude/hooks/notify.sh"
 }
 ]
 }
 ]
 }
}
```

**notify.sh**:
```bash
#!/bin/bash
INPUT=$(cat)
MESSAGE=$(echo "$INPUT" | jq -r '.message // "Notification"')

# Send to external service (Slack, webhook, etc.)
curl -X POST https://hooks.slack.com/... \
 -H 'Content-Type: application/json' \
 -d "{\"text\": \"Claude Code: $MESSAGE\"}"

exit 0
```

---

## Troubleshooting Checklist

### Hook Not Executing

- [ ] Is the hook file executable? `chmod +x hook.sh`
- [ ] Is the path correct in settings.json?
- [ ] Are you looking at the right settings.json? (user vs project vs local)
- [ ] Does the matcher match the tool name? (case-sensitive!)
- [ ] Is the hook timing right for the event?

### Matcher Not Matching

```bash
# Debug with --debug flag
claude --debug

# Check /hooks menu
# In Claude Code, type: /hooks
```

Common issues:
- Case sensitivity: `Edit` ≠ `edit`
- Regex not escaped: `.*\.ts$` not `*.ts`
- Wrong tool name: Check actual tool names in debug output

### Hook Times Out

- [ ] Increase timeout in settings.json
- [ ] Check if hook script has infinite loop
- [ ] Ensure external commands complete (npm, curl, etc.)
- [ ] Add timeout to child processes

```json
{
 "type": "command",
 "command": ".claude/hooks/slow-hook.sh",
 "timeout": 120 // Increase from default 60s
}
```

### Hook Errors

```bash
# Check hook manually
echo '{"session_id":"test"}' |.claude/hooks/my-hook.sh

# Add error handling
set -euo pipefail # Exit on errors
trap 'echo "Error on line $LINENO"' ERR
```

### Exit Code Issues

```bash
# Always exit explicitly
exit 0 # Don't rely on implicit exit code

# Block operations (PreToolUse only)
exit 2 # Not exit 1 or other codes

# Test exit codes
.claude/hooks/my-hook.sh
echo $? # Should print 0 or 2
```

### Permission Errors

```bash
# Make executable
chmod +x.claude/hooks/*.sh

# Check file ownership
ls -la.claude/hooks/

# Check if path is accessible
realpath.claude/hooks/my-hook.sh
```

### Input Not Received

```bash
# Always read stdin
INPUT=$(cat)

# Don't assume input structure
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')

# Log input for debugging
echo "Received: $INPUT" >> /tmp/hook-debug.log
```

### Multiple Hooks Conflicting

```bash
# Hooks execute in parallel
# Use file locking if they share state

(
 flock -x 200
 # Critical section
) 200>/tmp/hook.lock
```

---

## Advanced Patterns

### Conditional Execution

```bash
#!/bin/bash
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only format.ts files in src/
if [[ "$FILE_PATH" =~ ^src/.*\.ts$ ]]; then
 npx prettier --write "$FILE_PATH"
fi

exit 0
```

### Hook Chaining (Sequential)

```bash
#!/bin/bash
# master-hook.sh
set -euo pipefail

INPUT=$(cat)

# Step 1: Validate
.claude/hooks/validate.sh <<< "$INPUT" || exit 2

# Step 2: Format
.claude/hooks/format.sh <<< "$INPUT"

# Step 3: Test
.claude/hooks/test.sh <<< "$INPUT"

exit 0
```

### State Management

```bash
#!/bin/bash
STATE_FILE="/tmp/claude-hook-state.json"

# Read current state
if [ -f "$STATE_FILE" ]; then
 STATE=$(cat "$STATE_FILE")
else
 STATE='{}'
fi

# Update state
NEW_STATE=$(echo "$STATE" | jq '. + {lastRun: now}')
echo "$NEW_STATE" > "$STATE_FILE"

exit 0
```

### Modify Tool Input (PreToolUse)

```bash
#!/bin/bash
INPUT=$(cat)

# Extract and modify
OLD_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path')
NEW_PATH="${OLD_PATH}.backup"

# Return JSON with updatedInput
cat << EOF
{
 "decision": "approve",
 "updatedInput": {
 "file_path": "$NEW_PATH"
 },
 "reason": "Redirected to backup file"
}
EOF

exit 0
```

---

## Quick Syntax Lookup

### Read Input
```bash
INPUT=$(cat)
```

### Extract JSON Field
```bash
FIELD=$(echo "$INPUT" | jq -r '.field_name // "default"')
```

### Check If File Exists
```bash
if [ -f "$FILE_PATH" ]; then
 #...
fi
```

### Block Operation
```bash
echo "Blocked" >&2
exit 2
```

### Continue
```bash
exit 0
```

### Run Command with Timeout
```bash
timeout 10s npm test
```

### Suppress Output
```bash
npm test > /dev/null 2>&1
```

### Log to File
```bash
echo "Log message" >> /tmp/hook.log
```

### Current Timestamp
```bash
date -u +"%Y-%m-%dT%H:%M:%S.000Z"
```

---

## 🤖 AI Pair Programming Notes

### When to Use This File

Load this file when:
- Writing a new hook (need syntax reference)
- Debugging hook issues (check exit codes, matchers)
- Looking for hook patterns (copy-paste examples)
- Need quick reminder of event types

### Context Bundle Recommendations

**For hook creation**:
```
QUICK-REFERENCE.md (this file) + 04-COMMAND-HOOKS.md
```

**For debugging**:
```
QUICK-REFERENCE.md + 10-DEBUGGING-TROUBLESHOOTING.md
```

**For advanced patterns**:
```
QUICK-REFERENCE.md + 08-ADVANCED-PATTERNS.md
```

### Example AI Prompts

**Create a hook**:
> "Using claude-code-hooks/QUICK-REFERENCE.md, create a PostToolUse hook that runs ESLint on TypeScript files after editing."

**Fix matcher**:
> "My hook isn't matching. Using QUICK-REFERENCE.md#matcher-patterns, fix this matcher: [paste matcher]"

**Debug exit code**:
> "Using QUICK-REFERENCE.md#exit-codes, why is my PreToolUse hook not blocking? Here's the script: [paste script]"

---

## Related Files

- **Overview & Concepts**: [README.md](./README.md)
- **Navigation Hub**: [INDEX.md](./INDEX.md)
- **Real Examples**: [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md)
<!-- Future files:
- **Detailed Explanations**: 01-FUNDAMENTALS.md
- **All Event Types**: 02-HOOK-EVENTS.md
- **Configuration Guide**: 03-CONFIGURATION.md
- **Command Hooks**: 04-COMMAND-HOOKS.md
- **Debugging**: 10-DEBUGGING-TROUBLESHOOTING.md
-->

---

**Print this file or bookmark it for quick reference during hook development!**
