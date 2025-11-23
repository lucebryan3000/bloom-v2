---
Context Strategy: L1 (Always Preloaded)
Tier: 1 - Core Project Context
---

# Context Management Master Index

**Purpose:** Quick navigation guide to all index files. Load this in Claude context, then reference specific indexes as needed.

**Strategy:** This master index is kept small (~2KB) to avoid context bloat. It points to detailed indexes that Claude can reference on-demand.

---

## 🎯 Quick Decision Tree (START HERE)

**"I need to find..."**

→ **An agent for specialized work?**
  - Load: [`index-agents.md`](index-agents.md)
  - Find: Agent by domain (TypeScript, Python, UI, Spec, Linux, etc.)

→ **A reusable slash command?**
  - Load: [`index-slash-commands.md`](index-slash-commands.md)
  - Find: `/command-name` for automation/workflows

→ **Technical reference (KB)?**
  - Load: [`index-kb-knowledge-base.md`](index-kb-knowledge-base.md)
  - Find: TypeScript, React, Playwright, databases, testing patterns

→ **Project setup/deployment?**
  - Load: [`docs/_BloomAppDocs/setup/README.md`](../../_BloomAppDocs/setup/README.md)
  - Find: Docker, dev server, ports, deployment guides

→ **Feature documentation?**
  - Load: [`index-docs-features.md`](index-docs-features.md)
  - Find: Melissa LLM, UI patterns, settings, monitoring

→ **API reference?**
  - Load: [`docs/_BloomAppDocs/api/api-reference.md`](../../_BloomAppDocs/api/api-reference.md)
  - Find: Endpoints, chat API, data models

→ **Database/schema info?**
  - Load: [`docs/_BloomAppDocs/database/schema.md`](../../_BloomAppDocs/database/schema.md)
  - Find: Models, fields, relationships, scheduling

→ **Troubleshooting/operations?**
  - Load: [`index-docs-operations.md`](index-docs-operations.md)
  - Find: Common issues, logging, performance, monitoring

→ **Design decisions/architecture?**
  - Load: [`ARCHITECTURE.md`](../../../ARCHITECTURE.md)
  - Find: ADRs, design decisions, system overview

→ **Build/project planning docs?**
  - Load: [`index-build-artifacts.md`](index-build-artifacts.md)
  - Find: FRDs, design specs, implementation notes, completed work

→ **Session investigations/debugging?**
  - Load: [`index-sessions-logs.md`](index-sessions-logs.md)
  - Find: Past debugging sessions, investigation notes, workarounds

---

## 📊 Tier System Overview

### **Tier 1: Always Preloaded (~16KB)**

These files are **guaranteed in every conversation** via `.claudeignore` configuration.

| File | Size | Purpose |
|------|------|---------|
| **CLAUDE.md** | ~4KB | Project configuration, tech stack, critical rules, Melissa focus |
| **_index-master.md** | ~12KB | This file - navigation guide, decision tree, tier strategy |

**Why Tier 1:**
- CLAUDE.md: Essential project config, always needed
- _index-master.md: Enables smart discovery without bloat

**Policy for extending Tier 1:**
- Only add files <500 lines AND used in 95%+ of sessions
- Must pass strict necessity test
- Keep baseline lean, push specialized content to Tier 2-4

---

### **Tier 2: Core Development Tools (Load On-Demand, ~2-4KB each)**

Quick-access indexes for common development tasks:

| Index | Items | Purpose | When to Load |
|-------|-------|---------|--------------|
| [`index-agents.md`](index-agents.md) | 15 agents | Find specialized task agents by domain | Complex multi-step work |
| [`index-slash-commands.md`](index-slash-commands.md) | 26+ commands | Workflow automation shortcuts | Seeking automation or validation |
| [`index-prompts.md`](index-prompts.md) | 20+ templates | Pre-written prompt templates | Need reusable instructions |
| [`index-gitignore-claude.ignore.md`](index-gitignore-claude.ignore.md) | 36 files | Local working directory tools | Running playbooks or scripts |

**Cost:** ~2-4KB per load + Tier 1 base

**Usage Pattern:**
```
1. Read Quick Decision Tree (in Tier 1, always available)
2. Load appropriate Tier 2 index
3. Navigate to Tier 3-4 docs as needed
```

---

### **Tier 3: Specialized Reference (Load On-Demand, ~2-20KB each)**

Detailed indexes for specific domains and patterns:

| Index | Items | Coverage | When to Load |
|-------|-------|----------|--------------|
| [`index-kb-knowledge-base.md`](index-kb-knowledge-base.md) | 490+ | TypeScript, React, Playwright, Testing, Databases, Security, UI patterns | Learning frameworks/libraries |
| [`index-build-artifacts.md`](index-build-artifacts.md) | 150+ | FRDs, design docs, implementation notes, completed phases, archives | Reviewing design or understanding patterns |
| [`index-docs-features.md`](index-docs-features.md) | 40+ | Feature implementation docs | Understanding implemented features |
| [`index-docs-operations.md`](index-docs-operations.md) | 35+ | Operations guides, troubleshooting, monitoring, playbooks | Maintenance, troubleshooting, performance |
| [`index-sessions-logs.md`](index-sessions-logs.md) | 40+ | Work session notes, debugging sessions, investigations | Learning from past debugging/research |
| [`index-other.md`](index-other.md) | Misc | Utilities, helpers, reference docs in `.claude/` | Finding specific utilities |

**Cost:** Load specific index (~2-10KB), then reference targeted docs

**Characteristics:**
- High-signal content for specific needs
- Avoid loading multiple Tier 3 at once
- Use Tier 2 index as entry point when possible

---

### **Tier 4: Project Root & Primary Directories (Load As Needed)**

Essential project-level documentation:

| File/Directory | Purpose | When to Load |
|---|---|---|
| [`docs/_BloomAppDocs/INDEX.md`](../../_BloomAppDocs/INDEX.md) | Complete documentation map | Need full project docs overview |
| [`docs/_BloomAppDocs/setup/`](../../_BloomAppDocs/setup/) | Docker, dev server, deployment | Setting up or deploying |
| [`docs/_BloomAppDocs/features/`](../../_BloomAppDocs/features/) | Feature-specific documentation | Understanding feature implementation |
| [`docs/_BloomAppDocs/api/`](../../_BloomAppDocs/api/) | API endpoints and integrations | Building API clients or endpoints |
| [`docs/_BloomAppDocs/database/`](../../_BloomAppDocs/database/) | Schema, models, architecture | Database design or queries |
| [`docs/_BloomAppDocs/operations/`](../../_BloomAppDocs/operations/) | Monitoring, troubleshooting, performance | Operations and maintenance |
| [`ARCHITECTURE.md`](../../../ARCHITECTURE.md) | System design, ADRs, technical decisions | Understanding architecture |
| [`SECURITY.md`](../../../SECURITY.md) | Security guidelines and policies | Security implementation |
| [`_build/Melissa-Config/`](../../_build/Melissa-Config/) | Melissa implementation phases | Active phase work |
| [`_build/_completed/`](../../_build/_completed/) | Completed work archive | Learning from similar implementations |

---

## 📚 Detailed Index File Reference

### **Tier 2 Files (Load on Demand)**

#### **[index-agents.md](index-agents.md)** - Specialized Agents
- **Items:** 15 domain-specific agents
- **Domains:** Backend (TypeScript), Frontend (React/UI), Python, Linux, Spec/Testing, Reviews, Docs, etc.
- **Use case:** Find right agent for complex, multi-domain work
- **Example:** "Need help with React components?" → `/agent-ui`
- **Cost:** ~3KB

#### **[index-slash-commands.md](index-slash-commands.md)** - Workflow Automation
- **Items:** 26+ custom slash commands
- **Examples:** `/build-backlog`, `/prompt-review`, `/agent-*`, `/session-*`
- **Use case:** Automate multi-step workflows and validation
- **Example:** "Need to review PRs?" → `/prompt-review`
- **Cost:** ~4KB

#### **[index-prompts.md](index-prompts.md)** - Prompt Templates
- **Items:** 20+ pre-written prompts
- **Use case:** Jumpstart common development tasks
- **Example:** "Need a complex analysis prompt?" → Check this index
- **Cost:** ~2KB

#### **[index-gitignore-claude.ignore.md`](index-gitignore-claude.ignore.md) - Local Tools**
- **Location:** `_AppModules-Luce/` (gitignored directory)
- **Contains:** Playbooks, CLI templates, GitHub scripts
- **Use case:** Running local automation or understanding local setup
- **Cost:** ~1KB

---

### **Tier 3 Files (Specialized Reference)**

#### **[index-kb-knowledge-base.md](index-kb-knowledge-base.md)** - Technical Knowledge Base
- **Items:** 490+ technical documentation files
- **Location:** `docs/kb/`
- **Categories:** TypeScript patterns, React components, Playwright testing, Zustand state, Tailwind CSS, Security, Database, API design
- **Use case:** Learning frameworks, libraries, design patterns
- **When:** "How do I implement X in React?" or "What's the pattern for Y?"
- **Cost:** ~8KB

#### **[index-build-artifacts.md](index-build-artifacts.md)** - Build & Planning Docs
- **Items:** 150+ files
- **Location:** `_build/`
- **Contains:** FRDs, architecture decision records, design docs, implementation notes, completed phase archives
- **Use case:** Reviewing design decisions, understanding patterns from similar work
- **When:** "What was the design decision for X?" or "How was feature Y implemented?"
- **Cost:** ~10KB

#### **[index-docs-features.md](index-docs-features.md)** - Feature Documentation
- **Items:** 40+ feature-specific docs
- **Location:** Various feature-specific directories
- **Categories:** Melissa LLM, UI patterns, monitoring, settings, caching, sessions
- **Use case:** Understanding implemented features in detail
- **When:** "How does the monitoring feature work?" or "What are the settings options?"
- **Cost:** ~5KB

#### **[index-docs-operations.md](index-docs-operations.md)** - Operations & Playbooks
- **Items:** 35+ operational guides
- **Location:** `docs/operations/` and `docs/playbooks/`
- **Categories:** Troubleshooting guides, performance optimization, deployment procedures, monitoring setup
- **Use case:** Troubleshooting issues, maintenance, performance tuning
- **When:** "How do I troubleshoot X?" or "What's the deployment process?"
- **Cost:** ~6KB

#### **[index-sessions-logs.md](index-sessions-logs.md)** - Session Investigation Logs
- **Items:** 40+ session and investigation files
- **Location:** `docs/sessions/`
- **Contains:** Past debugging sessions, research notes, investigation outcomes
- **Use case:** Learning from past debugging, finding similar issues and solutions
- **When:** "Was this issue debugged before?" or "How was problem X solved?"
- **Cost:** ~3KB

#### **[index-other.md](index-other.md)** - Miscellaneous Reference
- **Items:** Various utilities and helpers
- **Location:** `.claude/` root level
- **Contains:** Configuration files, reference docs, utilities
- **Use case:** Finding specific utilities or helpers
- **Cost:** ~1KB

---

## 📊 Statistics & Impact

### Context Efficiency Metrics

| Metric | Value | Impact |
|--------|-------|--------|
| **Tier 1 (Fixed)** | ~16KB | Always preloaded, guaranteed on every turn |
| **Tier 2 (Per-Load)** | ~2-4KB each | 4 files available, load ~1-2 as needed |
| **Tier 3 (Per-Load)** | ~2-20KB each | 6 files available, load 1-2 for deep work |
| **Tier 4 (As-Needed)** | ~5-50KB | Project docs, load specific sections |
| **Total Indexed** | 172+ items | Via metadata in Tier 2-3 indexes |
| **Full Coverage** | 140K+ tokens | On-demand access to all documentation |
| **Context Savings** | 92%+ | Index strategy vs. preloading everything |

### Discovery Performance

| Scenario | Without Index | With Index | Improvement |
|----------|---|---|---|
| **Find KB pattern** | "Doesn't exist?" | <1 sec via preloaded index | Instant awareness |
| **Locate agent** | Guess/search codebase | 2 sec to load index | Clear discovery |
| **Find similar bug** | Manual search | Preloaded sessions index | Historical context |
| **Total startup cost** | 51KB bloat | 16KB baseline | 68% reduction |
| **Available work context** | 8.3K tokens | 53K+ tokens | 6.5x improvement |

### Before & After Comparison

**BEFORE (Without Tier System):**
- Preload: ~51KB (70% of context bloated)
- Available for work: ~8.3K tokens
- Awareness: None (users don't know what exists)
- Discovery: Manual search or guess

**AFTER (With Tier 1 Indexed):**
- Tier 1 preload: ~16KB (fixed, minimal)
- Available for work: ~53KB (6.5x more!)
- Awareness: 172+ indexed items via metadata
- Discovery: <1 second via preloaded indexes

---

## 📂 Directory Navigation Guide

### **Primary Documentation: `docs/_BloomAppDocs/`**

| Directory | Purpose | Key Files |
|-----------|---------|-----------|
| `setup/` | Dev environment, Docker, deployment | Docker guide, dev server setup, port management |
| `features/` | Feature-specific docs | Melissa config, UI patterns, monitoring, caching |
| `api/` | API reference, endpoints | Endpoint documentation, chat API, models |
| `database/` | Schema, models, architecture | Schema diagrams, Prisma docs, WAL configuration |
| `operations/` | Troubleshooting, monitoring, performance | Logging, debugging, performance optimization |
| `testing/` | Testing strategies | E2E, unit tests, test patterns |
| `reference/` | Standards, guidelines | Dependencies, security, best practices |

**Load via:** [`docs/_BloomAppDocs/INDEX.md`](../../_BloomAppDocs/INDEX.md) for complete map

---

### **Project Working Space: `_build/`**

| Directory | Purpose | When to Load |
|-----------|---------|--------------|
| `_planning/` | Active FRDs, design specs, ADRs | Planning or understanding design |
| `_completed/` | Finished phases, archives | Learning from similar implementations |
| `Melissa-Config/` | Melissa implementation phases | Active Melissa.ai work |
| `claude-docs/` | Generated reference docs | Understanding project state |
| `prompts/` | Complex prompt templates | Running multi-phase automations |

**Navigate via:** [`index-build-artifacts.md`](index-build-artifacts.md)

---

### **Technical Knowledge Base: `docs/kb/`**

| Category | Items | When to Load |
|----------|-------|--------------|
| TypeScript | 50+ files | TypeScript patterns, type safety |
| React | 40+ files | Component patterns, hooks, state management |
| Playwright | 30+ files | E2E testing, test patterns |
| Testing | 25+ files | Unit tests, integration tests, test fixtures |
| Database | 20+ files | Prisma, SQL, migrations, schemas |
| Tailwind CSS | 15+ files | Styling, dark mode, responsive design |
| API Design | 15+ files | REST patterns, error handling, validation |
| Security | 15+ files | Input validation, auth, XSS prevention |
| Node.js/Runtime | 10+ files | Node ecosystem, async patterns |

**Navigate via:** [`index-kb-knowledge-base.md`](index-kb-knowledge-base.md)

---

## 🔄 How the System Works

### The Discovery Flow

```
1. User: "I need to find [something]"
   ↓
2. Load: _index-master.md (Tier 1, already preloaded!)
   ↓
3. Read: Quick Decision Tree
   ↓
4. Load: One specific index (Tier 2 or 3)
   ↓
5. Navigate: From index to exact documentation file
   ↓
6. Load: That specific doc file for deep information
   ↓
RESULT: Context stays lean, information stays accessible
```

### The Cost Breakdown

```
Tier 1 Preload: 16KB (fixed)
├─ CLAUDE.md (4KB) - project config
└─ _index-master.md (12KB) - this file, enables discovery

+ Load ONE Tier 2 index when needed: +2-4KB
  ├─ agents, commands, prompts, or gitignore tools
  └─ Provides awareness of 78 indexed items

+ Load ONE Tier 3 index when needed: +2-20KB
  ├─ KB, build, features, operations, sessions, or other
  └─ Provides deep-dive reference for specific domain

+ Load specific docs from Tier 4: On-demand
  └─ Only load what you need, when you need it

Result: Responsive system with zero bloat
```

---

## 📋 Quick Reference: Which Index to Load?

### "I need to..."

| Task | Load This | Why |
|------|-----------|-----|
| Use a specialized agent | `index-agents.md` | Tier 2: 15 agents by domain |
| Find a workflow command | `index-slash-commands.md` | Tier 2: 26+ automation commands |
| Learn a technical pattern | `index-kb-knowledge-base.md` | Tier 3: 490+ technical files |
| Understand a feature | `index-docs-features.md` | Tier 3: 40+ feature docs |
| Troubleshoot an issue | `index-docs-operations.md` | Tier 3: 35+ ops guides |
| Debug a similar issue | `index-sessions-logs.md` | Tier 3: 40+ investigation logs |
| Review design decisions | `index-build-artifacts.md` | Tier 3: 150+ FRDs & design docs |
| Understand the API | `docs/_BloomAppDocs/api/` | Tier 4: Full API reference |
| Setup/deploy | `docs/_BloomAppDocs/setup/` | Tier 4: Deployment guides |
| Review architecture | `ARCHITECTURE.md` | Tier 4: ADRs & system design |

---

## 📈 Full Statistics

| Category | Count | Details |
|----------|-------|---------|
| **Total Index Files** | 16 | Across all tiers, entire project |
| **Tier 1 Files** | 2 | Always preloaded (~16KB) |
| **Tier 2 Indexes** | 4 | Core development tools (78 items indexed) |
| **Tier 3 Indexes** | 6 | Specialized reference (94 items indexed) |
| **Tier 4 Indexes** | 4+ | Project root & directories (various sizes) |
| **Total Items Indexed** | 172+ | Across all index files |
| **KB Files** | 490+ | Organized by category |
| **Build Artifacts** | 150+ | FRDs, design docs, archives |
| **Feature Docs** | 40+ | Feature-specific documentation |
| **Operations Docs** | 35+ | Guides, playbooks, troubleshooting |
| **Session Logs** | 40+ | Past debugging & investigations |
| **Tier 1 Context Cost** | ~16KB | Fixed, always loaded |
| **Tier 2+3 Available** | 140K+ | On-demand, indexed for awareness |
| **Context Savings** | 92%+ | vs. preloading all documentation |

---

## Related Files & Resources

### Tier 1 Configuration
- **[CLAUDE.md](../../../CLAUDE.md)** - Project configuration, tech stack, Melissa focus
- **[_index-master-update.sh](_index-master-update.sh)** - Script that maintains and reports on all indexes

### Documentation Maps
- **[docs/_BloomAppDocs/INDEX.md](../../_BloomAppDocs/INDEX.md)** - Full project documentation index
- **[ARCHITECTURE.md](../../../ARCHITECTURE.md)** - System design, ADRs, technical decisions
- **[SECURITY.md](../../../SECURITY.md)** - Security guidelines and policies

### Context Management
- **[context-management.md](context-management.md)** - Complete context strategy guide
- **[TIER1-INDEXED-GUIDE.md](TIER1-INDEXED-GUIDE.md)** - Deep dive on Tier 1 Indexed concept
- **[INDEX-SYSTEM-SUMMARY.md](INDEX-SYSTEM-SUMMARY.md)** - Implementation details

---

## ✅ This File: Tier 1 Master Index

**Size:** ~10-12KB (intentionally kept small)
**Purpose:** Navigation gateway for all other indexes
**Updated:** 2025-11-17
**Maintenance:** Weekly review recommended
**Auto-maintained by:** `_index-master-update.sh`

**Strategy:** Comprehensive awareness without context bloat. Every item here either:
- Is always preloaded (Tier 1), OR
- Points to a small index that provides discovery without loading all content

This file is the linchpin of the entire tier system. Keep it lean, keep it accurate, keep it as the single point of navigation.

---

*Last Updated: 2025-11-17*
*Master Index for tiered context loading strategy*
*Maintained by: _index-master-update.sh*
