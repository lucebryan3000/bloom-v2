---
id: claude-hooks-index
topic: claude-code-hooks
file_role: navigation
profile: full
difficulty_level: all-levels
kb_version: 3.1
prerequisites: []
related_topics: [claude-code, automation]
embedding_keywords: [index, navigation, table-of-contents, hooks-map]
last_reviewed: 2025-11-13
---

# Claude Code Hooks - Complete Index & Navigation

## 📍 Quick Navigation

**First Time Here?** → [README.md](./README.md) → [QUICK-REFERENCE.md](./QUICK-REFERENCE.md)

**Need Quick Syntax?** → [QUICK-REFERENCE.md](./QUICK-REFERENCE.md)

**Looking for Examples?** → [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md)

**Debugging Issues?** → [QUICK-REFERENCE.md#troubleshooting-checklist](./QUICK-REFERENCE.md#troubleshooting-checklist)

---

## 📚 Complete File Map

### **Entry Points**

| File | Purpose | Start Here If... |
|------|---------|------------------|
| [README.md](./README.md) | Overview & getting started | You're new to hooks |
| [INDEX.md](./INDEX.md) | This file - navigation hub | You know what you need |
| [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) | Syntax cheat sheet | You need quick syntax lookup |

### **Core Topics Overview**

> **Note**: Detailed topic files (01-11) are planned future expansions. All core content is currently available in README.md, QUICK-REFERENCE.md, and FRAMEWORK-INTEGRATION-PATTERNS.md.

<!-- Future Files (Planned):

### Core Concepts (Files 01-03)
- 01-FUNDAMENTALS.md: Hook architecture, event-driven model, configuration hierarchy
- 02-HOOK-EVENTS.md: All 9 event types, timing, inputs, use cases
- 03-CONFIGURATION.md: settings.json structure, matchers, timeout config

### Implementation (Files 04-07)
- 04-COMMAND-HOOKS.md: Shell scripts, input/output, exit codes
- 05-PROMPT-HOOKS.md: LLM-based hooks, JSON responses
- 06-TOOL-LIFECYCLE-HOOKS.md: PreToolUse/PostToolUse patterns
- 07-SESSION-HOOKS.md: SessionStart/End, context injection

### Advanced Topics (Files 08-11)
- 08-ADVANCED-PATTERNS.md: Hook chaining, parallel execution, state
- 09-SECURITY-BEST-PRACTICES.md: Validation, secret protection, sandboxing
- 10-DEBUGGING-TROUBLESHOOTING.md: Debug mode, errors, testing
- 11-CONFIG-OPERATIONS.md: Management, deployment, team collaboration
-->

### **Reference & Integration**

| File | Purpose | Use When... |
|------|---------|-------------|
| [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) | Complete syntax reference | You need quick syntax lookup |
| [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md) | Real-world framework examples | You need working examples |

---

## 🗺️ Topic Graph

```
FUNDAMENTALS (01)
 ├── Hook Architecture
 ├── Event-Driven Model
 └── Configuration Hierarchy
 │
 ├─→ HOOK EVENTS (02)
 │ ├── PreToolUse / PostToolUse
 │ ├── UserPromptSubmit / Stop
 │ └── Session / Notification
 │
 └─→ CONFIGURATION (03)
 ├── settings.json
 └── Matchers
 │
 ├─→ COMMAND HOOKS (04)
 │ ├── Shell Scripts
 │ └── Input/Output
 │ │
 │ ├─→ TOOL LIFECYCLE (06)
 │ │ ├── Pre/Post patterns
 │ │ └── Blocking
 │ │
 │ └─→ SESSION HOOKS (07)
 │ ├── Start/End
 │ └── Context Injection
 │
 └─→ PROMPT HOOKS (05)
 └── LLM-based decisions
 │
 └─→ ADVANCED PATTERNS (08)
 ├── Chaining
 ├── State Management
 └── Complex Workflows
 │
 ├─→ SECURITY (09)
 │ ├── Validation
 │ └── Protection
 │
 ├─→ DEBUGGING (10)
 │ ├── Debug Mode
 │ └── Testing
 │
 └─→ OPERATIONS (11)
 ├── Management
 └── Deployment
```

---

## 🎯 Learning Paths by Goal

### Goal: "I want to auto-format code after edits"

**Path**:
1. [QUICK-REFERENCE.md#all-9-hook-events](./QUICK-REFERENCE.md#all-9-hook-events) - Learn PostToolUse event
2. [QUICK-REFERENCE.md#command-hook-template](./QUICK-REFERENCE.md#command-hook-template) - Write command hook
3. [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md) - Copy auto-formatting example

**Difficulty**: Beginner-friendly

---

### Goal: "I want to block edits to sensitive files"

**Path**:
1. [QUICK-REFERENCE.md#exit-codes](./QUICK-REFERENCE.md#exit-codes) - Understand exit code 2
2. [QUICK-REFERENCE.md#pattern-2-block-sensitive-file-edits-pretooluse](./QUICK-REFERENCE.md) - Blocking pattern
3. [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md) - Security examples

**Difficulty**: Intermediate

---

### Goal: "I want to track task completion metrics"

**Path**:
1. [README.md](./README.md) - Understand hook concepts
2. [QUICK-REFERENCE.md#pattern-4-track-task-metrics-userpromptsubmit--stop](./QUICK-REFERENCE.md) - Paired events
3. [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md) - Full metrics example

**Difficulty**: Intermediate

---

### Goal: "I want to inject environment context on session start"

**Path**:
1. [QUICK-REFERENCE.md#session-events](./QUICK-REFERENCE.md) - SessionStart event
2. [QUICK-REFERENCE.md#pattern-5-inject-project-context-sessionstart](./QUICK-REFERENCE.md) - Context injection
3. [QUICK-REFERENCE.md#environment-variables](./QUICK-REFERENCE.md) - CLAUDE_ENV_FILE usage

**Difficulty**: Intermediate-to-advanced

---

### Goal: "I want to build complex hook workflows"

**Path**:
1. [README.md](./README.md) - Master fundamentals
2. [QUICK-REFERENCE.md#advanced-patterns](./QUICK-REFERENCE.md) - Hook chaining and state
3. [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md) - Complex examples

**Difficulty**: Advanced

---

### Goal: "I need to debug why my hook isn't working"

**Path**:
1. [QUICK-REFERENCE.md#troubleshooting-checklist](./QUICK-REFERENCE.md#troubleshooting-checklist) - Start here!
2. [README.md#debugging](./README.md#debugging) - Debug mode and common issues
3. [QUICK-REFERENCE.md#matcher-patterns](./QUICK-REFERENCE.md#matcher-patterns) - Fix matchers

**Difficulty**: Beginner

---

## 📋 Quick Reference Tables

### Event Types Quick Lookup

| Event | When It Fires | Common Use Cases | File Reference |
|-------|---------------|------------------|----------------|
| **PreToolUse** | Before tool executes | Validation, blocking | [QUICK-REFERENCE.md](./QUICK-REFERENCE.md#all-9-hook-events) |
| **PostToolUse** | After tool succeeds | Formatting, testing | [QUICK-REFERENCE.md](./QUICK-REFERENCE.md#all-9-hook-events) |
| **UserPromptSubmit** | User submits prompt | Start tracking, validation | [QUICK-REFERENCE.md](./QUICK-REFERENCE.md#all-9-hook-events) |
| **Stop** | Agent finishes response | End tracking, notifications | [QUICK-REFERENCE.md](./QUICK-REFERENCE.md#all-9-hook-events) |
| **SubagentStop** | Subagent completes | Subagent metrics | [QUICK-REFERENCE.md](./QUICK-REFERENCE.md#all-9-hook-events) |
| **SessionStart** | Session begins/resumes | Context injection, setup | [QUICK-REFERENCE.md](./QUICK-REFERENCE.md#all-9-hook-events) |
| **SessionEnd** | Session terminates | Cleanup, final reports | [QUICK-REFERENCE.md](./QUICK-REFERENCE.md#all-9-hook-events) |
| **Notification** | Claude sends notification | Custom alerts | [QUICK-REFERENCE.md](./QUICK-REFERENCE.md#all-9-hook-events) |
| **PreCompact** | Before context compaction | Save state | [QUICK-REFERENCE.md](./QUICK-REFERENCE.md#all-9-hook-events) |

### Hook Types Quick Lookup

| Type | Description | Events Supported | File Reference |
|------|-------------|------------------|----------------|
| **command** | Execute shell scripts | All events | [QUICK-REFERENCE.md](./QUICK-REFERENCE.md#command-hook-template) |
| **prompt** | Send to LLM for decision | Stop, SubagentStop only | [QUICK-REFERENCE.md](./QUICK-REFERENCE.md#prompt-hook-template) |

### Exit Codes Quick Lookup

| Exit Code | Meaning | Effect | File Reference |
|-----------|---------|--------|----------------|
| `0` | Success | Continue execution | [QUICK-REFERENCE.md](./QUICK-REFERENCE.md#exit-codes) |
| `2` | Block | Stop operation (PreToolUse only) | [QUICK-REFERENCE.md](./QUICK-REFERENCE.md#exit-codes) |
| Other | Error | Logged, execution continues | [QUICK-REFERENCE.md](./QUICK-REFERENCE.md#exit-codes) |

---

## 🔍 Search by Keyword

### Automation
- Auto-formatting → [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md)
- Auto-testing → [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md)
- CI/CD integration → [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md)

### Blocking & Validation
- Block operations → [QUICK-REFERENCE.md#pattern-2-block-sensitive-file-edits-pretooluse](./QUICK-REFERENCE.md)
- Input validation → [QUICK-REFERENCE.md#advanced-patterns](./QUICK-REFERENCE.md)
- File protection → [QUICK-REFERENCE.md](./QUICK-REFERENCE.md)

### Context & State
- Context injection → [QUICK-REFERENCE.md#pattern-5-inject-project-context-sessionstart](./QUICK-REFERENCE.md)
- State management → [QUICK-REFERENCE.md#advanced-patterns](./QUICK-REFERENCE.md)
- Environment setup → [QUICK-REFERENCE.md#environment-variables](./QUICK-REFERENCE.md)

### Debugging
- Debug mode → [README.md#debugging](./README.md#debugging)
- Common errors → [QUICK-REFERENCE.md#troubleshooting-checklist](./QUICK-REFERENCE.md#troubleshooting-checklist)
- Testing hooks → [QUICK-REFERENCE.md](./QUICK-REFERENCE.md)

### Security
- Input sanitization → [QUICK-REFERENCE.md#advanced-patterns](./QUICK-REFERENCE.md)
- Secret protection → [README.md#security-warning](./README.md#security-warning)
- Path traversal → [QUICK-REFERENCE.md](./QUICK-REFERENCE.md)

### Metrics & Logging
- Metrics tracking → [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md)
- Audit logging → [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md)
- Task timing → [QUICK-REFERENCE.md#pattern-4-track-task-metrics-userpromptsubmit--stop](./QUICK-REFERENCE.md)

---

## 🤖 AI Pair Programming Notes

### Loading Strategy

**For hook creation**:
```
Load: QUICK-REFERENCE.md + FRAMEWORK-INTEGRATION-PATTERNS.md
```

**For debugging**:
```
Load: QUICK-REFERENCE.md#troubleshooting-checklist + README.md
```

**For security review**:
```
Load: README.md#security-warning + QUICK-REFERENCE.md
```

**For full implementation**:
```
Load: README.md + QUICK-REFERENCE.md + FRAMEWORK-INTEGRATION-PATTERNS.md
```

### Example AI Prompts

**Create a hook**:
> "Using claude-code-hooks/QUICK-REFERENCE.md and FRAMEWORK-INTEGRATION-PATTERNS.md, create a PostToolUse hook that runs Prettier on TypeScript files after editing."

**Debug a hook**:
> "Load claude-code-hooks/QUICK-REFERENCE.md#troubleshooting-checklist. My hook isn't executing. Here's my config: [paste config]"

**Security review**:
> "Using claude-code-hooks/README.md#security-warning, review this hook for security issues: [paste hook code]"

---

## 📊 File Statistics

**Current Files (Available)**:

| File | Approx Lines | Difficulty | Read Time |
|------|-------------|------------|-----------|
| README.md | 500 | Beginner | 15 min |
| INDEX.md | 330 | All | 10 min |
| QUICK-REFERENCE.md | 1,030 | All | 20 min |
| FRAMEWORK-INTEGRATION-PATTERNS.md | 1,040 | Intermediate-Advanced | 40 min |
| **TOTAL** | **~2,900** | Mixed | **~90 min** |

**Future Files (Planned)**:

<!--
| File | Approx Lines | Difficulty | Read Time |
|------|-------------|------------|-----------|
| 01-FUNDAMENTALS.md | 1,100 | Beginner-Intermediate | 30 min |
| 02-HOOK-EVENTS.md | 850 | Beginner-Intermediate | 25 min |
| 03-CONFIGURATION.md | 850 | Intermediate | 25 min |
| 04-COMMAND-HOOKS.md | 500 | Beginner-Intermediate | 20 min |
| 05-PROMPT-HOOKS.md | 500 | Intermediate-Advanced | 20 min |
| 06-TOOL-LIFECYCLE-HOOKS.md | 500 | Intermediate | 20 min |
| 07-SESSION-HOOKS.md | 500 | Intermediate | 20 min |
| 08-ADVANCED-PATTERNS.md | 250 | Advanced | 15 min |
| 09-SECURITY-BEST-PRACTICES.md | 250 | Intermediate-Advanced | 15 min |
| 10-DEBUGGING-TROUBLESHOOTING.md | 250 | All | 15 min |
| 11-CONFIG-OPERATIONS.md | 500 | Intermediate | 20 min |
| **Future TOTAL** | **~6,100** | Mixed | **~4 hours** |
-->

---

**Next Steps**: Choose a learning path above or jump to [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) for syntax.
