---
Context Strategy: L2 (Load on Demand, Searchable)
Tier: 3 - Specialized Reference
---

# Knowledge Base Index – docs/kb/

**Context Strategy:** L2 (On-Demand, Searchable)
**Total Categories:** 31+ technical domains
**Total Files:** ~490+ documentation files
**Status:** Comprehensive reference library, search-driven access only

---

## Overview

The Knowledge Base (`docs/kb/`) contains deep technical reference materials for libraries, frameworks, and tools used in the Bloom project. These are **intentionally excluded from preload** (L2 strategy) because:

- **Massive size**: ~490+ files would bloat context by 50K+ tokens
- **Specialized**: Most files are only needed when working with specific technologies
- **Search-driven**: Tools like `/agent-*` can search these when needed
- **Reference**: Rarely need full breadth simultaneously

**Usage:** When you need to understand a specific technology, use explicit search or load relevant KB via agent commands.

---

## Knowledge Base Categories

### Core Project Stack (Search These Frequently)

| Category | Files | Focus | When Needed |
|----------|-------|-------|------------|
| **TypeScript** | 20+ | Language patterns, strict mode, types | Writing backend/frontend code |
| **React** | 15+ | Hooks, components, patterns | Frontend development |
| **Next.js** | 15+ | App Router, API routes, middleware | Full-stack work |
| **Tailwind** | 12+ | Design system, dark mode, utilities | Styling components |
| **Prisma** | 10+ | ORM patterns, migrations, schema | Database work |

### Testing & Quality (Search When Needed)

| Category | Files | Focus | When Needed |
|----------|-------|-------|------------|
| **Playwright** | 12+ | E2E testing, page objects, assertions | Writing tests |
| **Jest** | 8+ | Unit testing, mocking, snapshots | Testing utilities |
| **Testing** | 6+ | Testing strategies, patterns | Setting up tests |

### Infrastructure & DevOps (Search When Needed)

| Category | Files | Focus | When Needed |
|----------|-------|-------|------------|
| **Docker** | 8+ | Container configuration, builds | Deployment work |
| **Linux** | 10+ | Shell scripting, system admin | Infrastructure setup |
| **PostgreSQL** | 8+ | Advanced SQL, optimization | Database tuning |
| **Redis** | 6+ | Caching, sessions, patterns | Performance optimization |

### Authentication & Authorization (Search When Needed)

| Category | Files | Focus | When Needed |
|----------|-------|-------|------------|
| **NextAuth** | 10+ | Session management, providers | Authentication features |
| **Security** | 8+ | Encryption, hashing, vulnerabilities | Security hardening |

### AI/ML & Language Models (Search When Needed)

| Category | Files | Focus | When Needed |
|----------|-------|-------|------------|
| **Anthropic** | 6+ | Claude API, models, streaming | AI integration |
| **Anthropic SDK (TS)** | 8+ | TypeScript SDK patterns | Claude implementation |
| **AI SDK** | 8+ | Vercel AI SDK utilities | AI orchestration |
| **AI Documentation** | 5+ | General AI concepts | Understanding AI features |

### External APIs & Services (Search When Needed)

| Category | Files | Focus | When Needed |
|----------|-------|-------|------------|
| **Microsoft Graph** | 8+ | OAuth, directory, calendar APIs | Microsoft integration |
| **GitHub** | 6+ | API, webhooks, authentication | GitHub integration |
| **Google Gemini** | 4+ | Alternative LLM, patterns | Evaluating alternatives |
| **OpenAI Codex** | 4+ | Legacy API reference | Historical context |

### Frontend Frameworks (Search When Needed)

| Category | Files | Focus | When Needed |
|----------|-------|-------|------------|
| **Zustand** | 6+ | State management, patterns | State work |
| **UI Components** | 8+ | shadcn/ui, Radix UI patterns | Building UI |
| **Theme** | 4+ | Color schemes, dark mode | Theming work |

### Backend & Data (Search When Needed)

| Category | Files | Focus | When Needed |
|----------|-------|-------|------------|
| **Node.js** | 10+ | Runtime, async patterns, modules | Backend development |
| **SQLite** | 6+ | Database, WAL mode, optimization | Database tuning |
| **Zod** | 6+ | Validation schemas, parsing | Input validation |

### Monitoring & Performance (Search When Needed)

| Category | Files | Focus | When Needed |
|----------|-------|-------|------------|
| **Performance** | 6+ | Profiling, optimization, metrics | Performance tuning |
| **EZA** | 4+ | File listing utility | Development tools |

### Specialized Tools (Search When Needed)

| Category | Files | Focus | When Needed |
|----------|-------|-------|------------|
| **Claude Code Hooks** | 3+ | Hook execution, metrics | Hook development |

---

## Directory Structure

```
docs/kb/
├── ai-documentation/          (5 files)     AI concepts & theory
├── ai-ml/                      (8 files)     Machine learning patterns
├── ai-sdk/                     (8 files)     Vercel AI SDK
├── anthropic/                  (6 files)     Claude API reference
├── anthropic-sdk-typescript/   (8 files)     TypeScript SDK
├── claude-code-hooks/          (3 files)     Hook patterns
├── docker/                     (8 files)     Containerization
├── eza/                        (4 files)     File utility
├── github/                     (6 files)     GitHub API & webhooks
├── google-gemini-nodejs/       (4 files)     Alternative LLM
├── jest-app-testing/           (8 files)     Unit testing framework
├── linux/                      (10 files)    System administration
├── microsoft-graph/            (8 files)     Microsoft APIs
├── nextauth/                   (10 files)    Authentication
├── nextjs/                     (15 files)    Next.js framework
├── nodejs/                     (10 files)    Node.js runtime
├── openai-codex/               (4 files)     Legacy API
├── performance/                (6 files)     Performance optimization
├── playwright/                 (12 files)    E2E testing
├── postgresql/                 (8 files)     PostgreSQL database
├── prisma/                     (10 files)    ORM framework
├── react/                      (15 files)    React library
├── redis/                      (6 files)     Cache/session store
├── security/                   (8 files)     Security practices
├── sqlite/                     (6 files)     SQLite database
├── tailwind/                   (12 files)    CSS framework
├── testing/                    (6 files)     Testing strategies
├── typescript/                 (20 files)    Language reference
├── ui/                         (8 files)     UI component patterns
├── zod/                        (6 files)     Data validation
└── zustand/                    (6 files)    State management
```

---

## How to Access KB Files

### Option 1: Direct Search (Recommended)
```bash
# Search for a specific topic in KB
grep -r "hook\|context\|optimization" docs/kb/react/

# Find all files matching pattern
find docs/kb/playwright -name "*page*"

# Count files in category
ls -1 docs/kb/typescript | wc -l
```

### Option 2: Agent Command + Search
```bash
# Backend agent with access to relevant KB
/session-backend
# Then ask: "Find examples of X in the KB"

# Specific agent lookup
/agent-backend
# "Search KB for database patterns"
```

### Option 3: Manual Navigation
```bash
# Open specific category
ls docs/kb/typescript/
cat docs/kb/typescript/BLOOM-SPECIFIC-PATTERNS.md
```

---

## Content Organization

### Each KB Category Contains

1. **README.md** – Overview of category
2. **Pattern files** – Specific techniques and examples
3. **Reference docs** – Comprehensive API/feature documentation
4. **Best practices** – Do's and don'ts for the technology
5. **Bloom-specific** – How this tech is used in our project

### Example: TypeScript KB

```
docs/kb/typescript/
├── README.md                          # TypeScript in Bloom overview
├── BLOOM-SPECIFIC-PATTERNS.md         # Our patterns & conventions
├── QUICK-REFERENCE.md                 # Common types & syntax
├── strict-mode-setup.md              # TypeScript strict config
├── generics-advanced.md              # Generic patterns
├── decorators.md                     # Decorators & reflection
├── type-guards.md                    # Type narrowing techniques
├── utility-types.md                  # Built-in utility types
└── error-handling.md                 # Error types & patterns
```

---

## Search Tips

### Finding Information in KB

1. **Know your technology**: "I need React patterns" → search `docs/kb/react/`
2. **Know your problem**: "Hook rendering issue" → search `docs/kb/react/` and `docs/kb/nextjs/`
3. **Know the file type**: READMEs are good entry points, specific files are detailed
4. **Use grep for scanning**: `grep -r "pattern_name" docs/kb/ --include="*.md"`

### Common Searches

```bash
# Find React hook patterns
grep -r "useEffect\|useState\|useCallback" docs/kb/react/

# Find TypeScript patterns used in Bloom
cat docs/kb/typescript/BLOOM-SPECIFIC-PATTERNS.md

# Find Playwright testing patterns
grep -r "page\|fixture\|test" docs/kb/playwright/

# Find database optimization tips
grep -r "index\|query\|performance" docs/kb/sqlite/ docs/kb/postgresql/
```

---

## Relationship to Project

### When KB Files are Loaded

| Scenario | Loading Method | Context Impact |
|----------|----------------|-----------------|
| Writing TypeScript code | Search via agent | ~2-3 KB loaded on demand |
| React component debugging | `/session-frontend` loads React KB | ~3-4 KB included in L1 |
| Database optimization | Search + agent collaboration | ~2-3 KB loaded on demand |
| Test writing | Manual search + agent | ~2-3 KB loaded on demand |

### Why KB is L2 (Never Preloaded)

1. **Massive size** – 490+ files = 50K+ tokens
2. **Specialized** – Most work doesn't need all categories
3. **Reference** – Meant for searching, not reading linearly
4. **Redundant** – Agent definitions often extract relevant KB snippets
5. **Performance** – Preloading slows down every conversation

### Alternative: L1 Bundles Load KB Subsets

```markdown
/session-backend
├─ backend-typescript-architect.md (persona)
├─ Backend development standards
├─ Key API/database patterns   ← Includes subset of KB
└─ validate-roi.md command

/session-frontend
├─ ui-engineer.md (persona)
├─ React component patterns    ← Includes subset of KB
└─ Tailwind dark mode guidelines
```

---

## Maintenance

### Keeping KB Current

**Weekly:** None required (static reference)

**Monthly:**
- Check for outdated library versions
- Update links to external APIs
- Add new patterns discovered in code

**Quarterly:**
- Reorganize categories if needed
- Archive outdated patterns
- Merge duplicate documentation

### Adding New KB Content

1. **Create file in appropriate category**: `docs/kb/typescript/new-pattern.md`
2. **Add to README** of that category
3. **Run index update**: `.claude/docs/context-management-claude/update-indexes.sh kb`
4. **Commit**: `git add docs/kb/typescript/new-pattern.md .claude/docs/context-management-claude/index-kb-knowledge-base.md`

---

## Quick Reference by Use Case

### "I need to solve a TypeScript problem"
→ Search `docs/kb/typescript/` or ask `/session-backend "Find TypeScript pattern for X"`

### "I'm writing React components"
→ Search `docs/kb/react/` or ask `/session-frontend "Show React pattern for X"`

### "I need to write a test"
→ Search `docs/kb/playwright/` or ask `/agent-spec-tester "Find Playwright example for X"`

### "I'm optimizing database queries"
→ Search `docs/kb/sqlite/` or `docs/kb/postgresql/` or ask `/session-backend "Optimize query for X"`

### "I'm implementing authentication"
→ Search `docs/kb/nextauth/` or ask `/session-backend "NextAuth pattern for X"`

---

## Integration with Index System

This index file serves as **metadata only**. It provides:

✅ **Awareness** – Know what KB exists without loading it
✅ **Navigation** – Know where to search
✅ **Discovery** – Find technologies by category
✅ **Context reduction** – KB stays L2 (excluded from preload)

---

**Last Updated:** 2025-11-17
**Total Files Cataloged:** ~490+
**Categories:** 31+
**Context Cost if Preloaded:** ~50,000+ tokens (WHY IT'S L2!)
**Current Context Cost:** ~0 tokens (indexed, not loaded)
