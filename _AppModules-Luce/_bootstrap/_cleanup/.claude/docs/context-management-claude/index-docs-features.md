---
Context Strategy: L2 (Load on Demand, Searchable)
Tier: 3 - Specialized Reference
---

# Feature Documentation Index – docs/features/

**Context Strategy:** L2 (On-Demand, Searchable)
**Total Features:** 8+ feature domains
**Total Files:** ~40+ documentation files
**Status:** Feature-specific technical documentation, search-driven access only

---

## Overview

The Features Directory (`docs/features/`) contains detailed technical documentation for Bloom's major feature areas. These are **intentionally excluded from preload** (L2 strategy) because:

- **Feature-specific**: Documentation is only needed when working on that feature
- **Detailed design**: Often contains lengthy implementation details
- **Reference heavy**: Not needed unless actively developing the feature
- **Organized by domain**: Easy to search when you know which feature you're working on

**Usage:** When implementing or debugging a feature, search for the specific feature documentation.

---

## Feature Categories

### Core Features

| Feature | Files | Purpose | When Needed |
|---------|-------|---------|-----------|
| **Task Scheduler** | 4+ | Admin task execution, scheduling, UI | Task system work |
| **Sessions** | 3+ | Session management, lifecycle, UI | Session feature work |
| **Reporting** | 3+ | ROI report generation, export formats | Report generation |
| **Settings** | 2+ | Configuration system, tabs, storage | Settings/config work |

### Domain-Specific Features

| Feature | Files | Purpose | When Needed |
|---------|-------|---------|-----------|
| **UI Patterns** | TBD | Component patterns, interactions | Building UI features |
| **Melissa.ai** | 2+ | AI agent integration, conversations | Melissa feature work |

### System Features

| Feature | Files | Purpose | When Needed |
|---------|-------|---------|-----------|
| **Monitoring** | 2+ | Health checks, logging, dashboards | Monitoring work |
| **Caching** | 2+ | Performance optimization, strategies | Cache implementation |

---

## Directory Structure

```
docs/features/
├── caching/                         (2 files)     Performance optimization
│   ├── README.md
│   └── [implementation files]
│
├── melissa/                         (2 files)     AI agent features
│   ├── README.md
│   └── [integration docs]
│
├── monitoring/                      (2 files)     System health & observability
│   ├── README.md
│   └── [monitoring implementation]
│
├── reporting/                       (3 files)     Report generation
│   ├── README.md
│   ├── reporting-system.md
│   └── [export format docs]
│
├── sessions/                        (3 files)     Session lifecycle
│   ├── README.md
│   ├── sessions-page-fix.md
│   └── [session management docs]
│
├── settings/                        (2 files)     Configuration system
│   ├── README.md
│   └── [settings docs]
│
├── task-scheduler/                  (4 files)     Admin task execution
│   ├── README.md
│   ├── TASK-SCHEDULER-SYSTEM.md
│   ├── TASK-TAGS-IMPLEMENTATION-PLAN.md
│   └── [scheduler implementation]
│
└── ui-patterns/                     (TBD files)   Component patterns
    ├── README.md
    └── [pattern documentation]
```

---

## Feature Details

### Task Scheduler System

**Files:**
- `task-scheduler/README.md` – Overview and quick start
- `task-scheduler/TASK-SCHEDULER-SYSTEM.md` – Complete system documentation
- `task-scheduler/TASK-TAGS-IMPLEMENTATION-PLAN.md` – Tag feature implementation plan

**Covers:**
- Task execution model
- Scheduling strategies (immediate, delayed, recurring)
- Task tagging system
- Execution history and retry logic
- UI components and admin interface
- API endpoints for task management

**When to use:** Working on background jobs, task queuing, admin features

---

### Sessions Management

**Files:**
- `sessions/README.md` – Overview of session system
- `sessions/sessions-page-fix.md` – Bug fixes and improvements
- Additional session documentation

**Covers:**
- Session lifecycle (creation, pause, resume, export)
- Session state management
- Database schema for sessions
- API endpoints for session operations
- UI for session management
- Workshop conversation tracking

**When to use:** Implementing session features, debugging session issues, session persistence

---

### Reporting System

**Files:**
- `reporting/README.md` – Overview of reporting
- `reporting/reporting-system.md` – Complete reporting architecture
- Export format documentation

**Covers:**
- Report generation pipeline
- ROI calculation integration
- Data aggregation
- Export formats (PDF, Excel, JSON)
- Report customization options
- Branding integration
- Confidence scoring

**When to use:** Implementing report features, adding export formats, customizing reports

---

### Settings System

**Files:**
- `settings/README.md` – Overview
- Settings implementation documentation

**Covers:**
- Settings UI tabs (General, Branding, Sessions, Monitoring)
- Configuration persistence
- Validation strategies
- Settings API
- Admin configuration options

**When to use:** Adding settings, modifying configuration options, UI improvements

---

### Monitoring & Health Checks

**Files:**
- `monitoring/README.md` – Overview
- Health check documentation

**Covers:**
- Health check endpoints
- Metric collection
- Real-time monitoring dashboard
- SSE log streaming
- Performance metrics
- System status indicators

**When to use:** Implementing monitoring features, adding metrics, debugging performance issues

---

### Melissa.ai Integration

**Files:**
- Melissa feature documentation
- AI agent integration patterns

**Covers:**
- Conversation flow
- Data extraction from conversations
- ROI discovery workshop integration
- LLM model configuration
- Tool calling and function execution
- Knowledge base integration

**When to use:** Implementing AI features, debugging Melissa conversations, adding new tools

---

### Caching Features

**Files:**
- Caching implementation documentation

**Covers:**
- Multi-tier caching (memory, Redis)
- Cache warming strategies
- ETag support
- React Query integration
- Cache invalidation
- Performance optimization patterns

**When to use:** Optimizing performance, implementing caching, debugging cache issues

---

### UI Patterns

**Files:**
- UI pattern documentation (being expanded)

**Covers:**
- Component patterns used in Bloom
- Dark mode implementation
- Responsive design patterns
- Accessibility standards
- Interactive components
- Form patterns

**When to use:** Building new UI features, maintaining component consistency

---

## How to Access Feature Documentation

### Option 1: Direct Navigation
```bash
# View feature overview
cat docs/features/task-scheduler/README.md

# Read feature implementation
cat docs/features/task-scheduler/TASK-SCHEDULER-SYSTEM.md

# View all features
ls docs/features/
```

### Option 2: Search Feature Content
```bash
# Search for specific feature topic
grep -r "task\|scheduler" docs/features/

# Find all files in a feature
find docs/features/task-scheduler/ -type f -name "*.md"

# Count documentation pages per feature
for dir in docs/features/*/; do echo "$(basename $dir): $(ls $dir/*.md 2>/dev/null | wc -l) files"; done
```

### Option 3: Agent-Assisted Search
```bash
# Ask backend agent about a feature
/session-backend
# "Explain the task scheduler system"

# Ask for implementation guidance
/agent-spec-developer
# "Find how sessions are implemented"
```

---

## Using Feature Documentation

### When Starting a Feature

1. **Read the README** – Quick overview and architecture
2. **Review implementation files** – Understand current state
3. **Check for TODOs** – Identify what's missing
4. **Search for related code** – Find actual implementation

### When Debugging a Feature

1. **Find the feature folder** – `docs/features/[feature]/`
2. **Read the system documentation** – Understand how it works
3. **Check for known issues** – Look for bug reports and fixes
4. **Search code alongside docs** – Cross-reference with implementation

### When Adding to a Feature

1. **Review existing architecture** – Maintain consistency
2. **Check for related features** – Avoid duplication
3. **Update documentation** – Add new patterns discovered
4. **Test against documentation** – Verify accuracy

---

## Feature Dependencies

### Feature Relationships

```
Melissa.ai ──────────────► Reporting System
   ↑                            ↓
   └─────── Sessions ◄─────────┘
             (data flow)

Settings System ─────► Monitoring
       ↓
Task Scheduler ────────► Caching
       ↓
UI Patterns (used everywhere)
```

### Cross-Feature Searches

When working on multiple features, you might need:

```bash
# Sessions + Reporting integration
grep -r "export" docs/features/sessions/ docs/features/reporting/

# Melissa + Caching integration
grep -r "cache\|performance" docs/features/melissa/ docs/features/caching/

# All features + Settings interaction
grep -r "config\|settings" docs/features/*/
```

---

## Documentation Standards

### Each Feature Folder Contains

1. **README.md** – Feature overview and quick links
2. **[Feature]-SYSTEM.md** – Complete implementation documentation
3. **Implementation files** – Specific technical details
4. **Related code** – Links to actual implementation in `/lib/` and `/app/`

### Documentation Includes

- Architecture overview
- Data flow diagrams
- API endpoints (if applicable)
- Database schema (if applicable)
- UI components used
- Configuration options
- Common use cases
- Known issues and fixes
- Future improvements

---

## Adding Feature Documentation

### When Creating a New Feature

1. **Create feature folder**: `docs/features/[feature-name]/`
2. **Create README**: `docs/features/[feature-name]/README.md`
3. **Add system doc**: `docs/features/[feature-name]/[FEATURE]-SYSTEM.md`
4. **Link from main features README**: `docs/features/README.md`
5. **Update this index**: Add to feature list
6. **Commit**: Include in feature implementation PR

---

## Relationship to Project Structure

### Feature Implementation Pattern

```
Feature Documentation          Implementation
─────────────────────         ────────────────

docs/features/                lib/
├── [feature]/                └── [feature]/
│   ├── README.md                ├── hooks/
│   └── [FEATURE]-SYSTEM.md      ├── utils/
                                 └── constants.ts

                            app/api/
                            └── [feature]/
                               ├── route.ts
                               └── middleware/

                            components/
                            └── [Feature]/
                               ├── [Component].tsx
                               └── [Component].module.css
```

---

## Maintenance Schedule

### Weekly
- Review feature-specific issues
- Update documentation if bugs found
- Note new patterns discovered

### Monthly
- Audit feature documentation completeness
- Check for outdated information
- Verify all features have README

### Quarterly
- Reorganize if new features added
- Archive deprecated features
- Create cross-feature documentation

---

## Quick Reference by Task

### "I need to implement a new feature"
→ Check similar feature in `docs/features/` for patterns

### "A feature is broken"
→ Read `docs/features/[feature]/SYSTEM.md` to understand architecture

### "I'm adding to an existing feature"
→ Review `docs/features/[feature]/` to understand current implementation

### "I need to optimize a feature"
→ Read feature docs + check `docs/features/caching/` for optimization patterns

### "I'm designing a new feature"
→ Study existing feature docs for consistency patterns

---

## Integration with Index System

This index file provides:

✅ **Awareness** – Know what features are documented
✅ **Navigation** – Know where to find feature docs
✅ **Discovery** – Find related features and dependencies
✅ **Context reduction** – Feature docs stay L2 (excluded from preload)

---

**Last Updated:** 2025-11-17
**Features Indexed:** 8+
**Total Documentation Files:** ~40+
**Context Cost if Preloaded:** ~20,000+ tokens (WHY IT'S L2!)
**Current Context Cost:** ~0 tokens (indexed, not loaded)
