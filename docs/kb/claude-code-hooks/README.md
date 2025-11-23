---
id: claude-hooks-readme
topic: claude-code-hooks
file_role: overview
profile: full
difficulty_level: beginner-to-advanced
kb_version: 3.1
prerequisites: [bash-scripting, json]
related_topics: [claude-code, automation, ci-cd]
embedding_keywords: [claude-code, hooks, automation, event-driven, workflow, shell-commands]
last_reviewed: 2025-11-13
---

# Claude Code Hooks - Complete Knowledge Base

Welcome to the comprehensive Claude Code hooks knowledge base. This KB covers everything from basic hook configuration to advanced automation patterns for Claude Code workflows.

## 📚 What Are Claude Code Hooks?

Claude Code hooks are **user-defined shell commands** that execute automatically at specific points in Claude Code's workflow lifecycle. They provide **deterministic control** over Claude Code's behavior, ensuring certain actions always happen rather than relying on the LLM to choose to run them.

**Key Insight**: Hooks transform suggestions into application-level code that reliably executes as intended.

## 🎯 Why Use Hooks?

### Problems Hooks Solve

1. **Reliability**: Ensure critical actions execute every time (formatting, validation, logging)
2. **Consistency**: Enforce team standards automatically (code style, commit conventions)
3. **Security**: Block dangerous operations before they execute
4. **Automation**: Reduce manual steps in development workflow
5. **Compliance**: Track and log all operations for audit trails

### Common Use Cases

- **Automatic Code Formatting**: Run Prettier/gofmt after every file edit
- **File Protection**: Block modifications to sensitive configuration files
- **Custom Notifications**: Alert external systems when Claude awaits input
- **Logging & Auditing**: Track all executed commands for compliance
- **Validation**: Enforce codebase conventions automatically
- **Context Injection**: Add environment-specific data to sessions
- **Metrics Tracking**: Measure task completion times and token usage

## 📋 Documentation Structure (11-Part Series)

### **Quick Navigation**
- **<!-- [INDEX.md](./INDEX.md) -->** - Complete topic index with navigation paths
- **<!-- [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) -->** - Cheat sheet for all hook types and syntax
- **<!-- [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md) -->** - Real-world integration examples

### **Core Topics (11 Files)**

> **Note**: Numbered files (01-11) are planned future expansions. Current KB provides comprehensive coverage via the core files (README, INDEX, QUICK-REFERENCE, FRAMEWORK-INTEGRATION-PATTERNS).

| # | Topic | File | Focus |
|---|-------|------|-------|
| 1 | **Fundamentals** | <!-- <!-- <!-- [01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md) --> (file not created) --> --> | Hook concepts, architecture, lifecycle |
| 2 | **Hook Events** | <!-- <!-- <!-- [02-HOOK-EVENTS.md](./02-HOOK-EVENTS.md) --> (file not created) --> --> | All 9 event types and when they fire |
| 3 | **Configuration** | <!-- <!-- <!-- [03-CONFIGURATION.md](./03-CONFIGURATION.md) --> (file not created) --> --> | Settings structure, matchers, schemas |
| 4 | **Command Hooks** | <!-- <!-- <!-- [04-COMMAND-HOOKS.md](./04-COMMAND-HOOKS.md) --> (file not created) --> --> | Shell script hooks, input/output patterns |
| 5 | **Prompt Hooks** | <!-- <!-- <!-- [05-PROMPT-HOOKS.md](./05-PROMPT-HOOKS.md) --> (file not created) --> --> | LLM-based hooks for context-aware decisions |
| 6 | **Tool Lifecycle** | <!-- <!-- <!-- [06-TOOL-LIFECYCLE-HOOKS.md](./06-TOOL-LIFECYCLE-HOOKS.md) --> (file not created) --> --> | PreToolUse, PostToolUse patterns |
| 7 | **Session Hooks** | <!-- <!-- <!-- [07-SESSION-HOOKS.md](./07-SESSION-HOOKS.md) --> (file not created) --> --> | SessionStart, SessionEnd, context injection |
| 8 | **Advanced Patterns** | <!-- <!-- <!-- [08-ADVANCED-PATTERNS.md](./08-ADVANCED-PATTERNS.md) --> (file not created) --> --> | Blocking, modification, chaining |
| 9 | **Security** | <!-- <!-- <!-- [09-SECURITY-BEST-PRACTICES.md](./09-SECURITY-BEST-PRACTICES.md) --> (file not created) --> --> | Input validation, secrets, sandboxing |
| 10 | **Debugging** | <!-- <!-- <!-- [10-DEBUGGING-TROUBLESHOOTING.md](./10-DEBUGGING-TROUBLESHOOTING.md) --> (file not created) --> --> | Debugging hooks, common errors |
| 11 | **Operations** | <!-- <!-- <!-- [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) --> (file not created) --> --> | Management, testing, deployment |

---

## 🚀 Quick Start

### 1. Basic Hook Setup

**Location**: `~/.claude/settings.json` (user-wide) or `.claude/settings.json` (project)

```json
{
 "hooks": {
 "Stop": [
 {
 "hooks": [
 {
 "type": "command",
 "command": ".claude/hooks/my-hook.sh",
 "timeout": 5
 }
 ]
 }
 ]
 }
}
```

### 2. Create a Hook Script

```bash
#!/bin/bash
#.claude/hooks/my-hook.sh

# Read stdin (hook receives JSON input)
INPUT=$(cat)

# Your logic here
echo "Hook executed at $(date)"

# Exit 0 for success
exit 0
```

### 3. Make It Executable

```bash
chmod +x.claude/hooks/my-hook.sh
```

### 4. Test It

Run Claude Code with `--debug` flag to see hook execution:

```bash
claude --debug
```

---

## 📖 Common Patterns

### Pattern 1: Auto-Format on Edit

```json
{
 "hooks": {
 "PostToolUse": [
 {
 "matcher": {
 "tool_name": "Edit|Write"
 },
 "hooks": [
 {
 "type": "command",
 "command": "npx prettier --write $file_path",
 "timeout": 10
 }
 ]
 }
 ]
 }
}
```

### Pattern 2: Block Sensitive File Edits

```json
{
 "hooks": {
 "PreToolUse": [
 {
 "matcher": {
 "tool_name": "Edit|Write",
 "tool_input": ".env|secrets.json"
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
# Block with exit code 2
echo "❌ Cannot edit sensitive files" >&2
exit 2
```

### Pattern 3: Task Metrics Tracking

```json
{
 "hooks": {
 "UserPromptSubmit": [
 {
 "hooks": [
 {
 "type": "command",
 "command": ".claude/hooks/start-tracking.sh"
 }
 ]
 }
 ],
 "Stop": [
 {
 "hooks": [
 {
 "type": "command",
 "command": ".claude/hooks/stop-tracking.sh"
 }
 ]
 }
 ]
 }
}
```

---

## 🎓 Learning Paths

### **Beginner Path** (Getting Started)
1. <!-- [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) --> - Syntax and basic patterns
2. <!-- [INDEX.md](./INDEX.md) --> - Navigation and topic overview
3. <!-- [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md) --> - Working examples
<!-- Future files:
1. 01-FUNDAMENTALS.md - Hook concepts
2. 02-HOOK-EVENTS.md - Event types
3. 04-COMMAND-HOOKS.md - Writing hooks
-->

### **Intermediate Path** (Real-World Usage)
1. <!-- [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md) --> - Production patterns
2. <!-- [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) --> - Advanced syntax
3. <!-- [INDEX.md](./INDEX.md) --> - Deep topic navigation
<!-- Future files:
1. 03-CONFIGURATION.md - Configuration patterns
2. 06-TOOL-LIFECYCLE-HOOKS.md - Tool automation
3. 07-SESSION-HOOKS.md - Session management
-->

### **Advanced Path** (Power User)
1. <!-- [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md) --> - Complex examples
2. <!-- [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) --> - All syntax patterns
<!-- Future files:
1. 08-ADVANCED-PATTERNS.md - Complex workflows
2. 05-PROMPT-HOOKS.md - LLM-based hooks
3. 09-SECURITY-BEST-PRACTICES.md - Security hardening
4. 10-DEBUGGING-TROUBLESHOOTING.md - Expert debugging
-->

---

## 🔑 Key Concepts

### Hook Execution Model

```
User Action → Event Fires → Matchers Checked → Hooks Execute → Continue/Block
```

### Three Configuration Levels

1. **User Settings**: `~/.claude/settings.json` (global, all projects)
2. **Project Settings**: `.claude/settings.json` (committed to repo)
3. **Local Settings**: `.claude/settings.local.json` (local overrides, not committed)

### Two Hook Types

1. **Command Hooks**: Execute shell scripts/commands
2. **Prompt Hooks**: Send input to LLM for context-aware decisions (Stop/SubagentStop only)

### Exit Codes

- `0`: Success, continue
- `2`: Block operation (PreToolUse only)
- Other non-zero: Error (logged but doesn't block)

---

## ⚠️ Security Warning

**Hooks run automatically with your environment's credentials.** They can:
- Access files and secrets
- Execute arbitrary commands
- Communicate with external services
- Exfiltrate data

**Best Practices**:
✅ Review all hook code before enabling
✅ Use absolute paths and validate inputs
✅ Quote shell variables properly
✅ Avoid running untrusted third-party hooks
✅ Test hooks in isolated environments first

<!-- See 09-SECURITY-BEST-PRACTICES.md (future file) for comprehensive security guidance. -->
See <!-- [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) --> for security patterns and <!-- [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md) --> for security examples.

---

## 🛠️ Debugging

### Enable Debug Mode

```bash
claude --debug
```

This shows:
- Hook registration status
- Matcher evaluation results
- Hook execution output
- Exit codes and errors

### View Hook Configuration

In Claude Code, type:
```
/hooks
```

This displays the current hook configuration snapshot.

### Common Issues

| Issue | Cause | Fix |
|-------|-------|-----|
| Hook not executing | Not executable | `chmod +x hook.sh` |
| Matcher not matching | Case-sensitive mismatch | Check exact tool names |
| Timeout errors | Hook too slow | Increase timeout or optimize |
| Permission denied | Missing execute permission | `chmod +x` on script |

<!-- See 10-DEBUGGING-TROUBLESHOOTING.md (future file) for detailed troubleshooting. -->
See [QUICK-REFERENCE.md#troubleshooting-checklist](./QUICK-REFERENCE.md#troubleshooting-checklist) for comprehensive debugging guidance.

---

## 📊 Real-World Examples

### Example 1: Project Metrics Hook

**Use Case**: Track task completion metrics (duration, tokens used)

**Configuration** (`.claude/settings.json`):
```json
{
 "hooks": {
 "UserPromptSubmit": [
 {
 "hooks": [
 {
 "type": "command",
 "command": ".claude/hooks/prompt-start.sh",
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
 "command": ".claude/hooks/prompt-complete.sh",
 "timeout": 10
 }
 ]
 }
 ]
 }
}
```

**Hook Scripts**: See [FRAMEWORK-INTEGRATION-PATTERNS.md - Metrics Tracking](./FRAMEWORK-INTEGRATION-PATTERNS.md#metrics-tracking)

### Example 2: Automatic Test Execution

**Use Case**: Run tests after editing test files

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
 "command": "npm test -- --findRelatedTests $file_path",
 "timeout": 60
 }
 ]
 }
 ]
 }
}
```

---

## 📚 Additional Resources

### Official Documentation
- [Claude Code Hooks Guide](https://code.claude.com/docs/en/hooks-guide.md)
- [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks.md)

### Related Topics
- **Bash Scripting**: See `docs/kb/linux/bash-scripting.md`
- **JSON Schema**: See `docs/kb/typescript/json-schema.md`
- **CI/CD Automation**: See `docs/kb/github/actions.md`

### Community Examples
- Check `.claude/hooks/` in this project for working examples
- Browse Claude Code examples repository (if available)

---

## 🤖 AI Pair Programming Notes

### When to Load This KB

Load hooks KB when:
- Setting up automated workflows
- Debugging hook execution issues
- Implementing custom validations
- Building CI/CD integrations
- Enforcing team conventions

### Recommended Context Bundle

For hook development:
```
- QUICK-REFERENCE.md (syntax reference)
- INDEX.md (topic navigation)
- FRAMEWORK-INTEGRATION-PATTERNS.md (working examples)
```

For security reviews:
```
- QUICK-REFERENCE.md (security patterns)
- FRAMEWORK-INTEGRATION-PATTERNS.md (security examples)
```

### Common AI Instructions

**To create a new hook**:
> "Using docs/kb/claude-code-hooks/QUICK-REFERENCE.md and FRAMEWORK-INTEGRATION-PATTERNS.md, create a PostToolUse hook that validates TypeScript files after editing."

**To debug a hook**:
> "Load docs/kb/claude-code-hooks/QUICK-REFERENCE.md#troubleshooting-checklist and help me debug why my hook isn't executing."

---

## 📝 File Navigation Quick Reference

**Current Files (Available Now)**:
- **Overview**: README.md (this file)
- **Navigation**: INDEX.md (topic navigation)
- **Quick Lookup**: QUICK-REFERENCE.md (syntax cheat sheet)
- **Examples**: FRAMEWORK-INTEGRATION-PATTERNS.md (production patterns)

**Future Files (Planned Expansion)**:
<!-- - **Concepts**: 01-FUNDAMENTALS.md, 02-HOOK-EVENTS.md
- **Implementation**: 04-COMMAND-HOOKS.md, 06-TOOL-LIFECYCLE-HOOKS.md
- **Advanced**: 05-PROMPT-HOOKS.md, 08-ADVANCED-PATTERNS.md
- **Operations**: 09-SECURITY-BEST-PRACTICES.md, 10-DEBUGGING-TROUBLESHOOTING.md, 11-CONFIG-OPERATIONS.md
-->

---

## 🔄 Version History

- **v3.1** (2025-11-13): Initial creation following KB v3.1 playbook
- Aligned with Claude Code hooks documentation (November 2025)

---

## 💡 Contributing

This KB follows the [KB Creation Playbook v3.1](../create-kb-v3.1.md).

**Quality Standards**:
- Minimum 24/30 on quality rubric
- All examples tested and working
- Security warnings for dangerous operations
- Clear chunking for RAG retrieval
- No time estimates, only difficulty levels

**Maintenance**:
- Review quarterly or when Claude Code updates hooks API
- Update `last_reviewed` in front-matter
- Add new patterns to FRAMEWORK-INTEGRATION-PATTERNS.md
- Document breaking changes in relevant files

---

**Ready to get started?** → <!-- [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) -->

**Need navigation?** → <!-- [INDEX.md](./INDEX.md) -->

**Want working examples?** → <!-- [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md) -->
