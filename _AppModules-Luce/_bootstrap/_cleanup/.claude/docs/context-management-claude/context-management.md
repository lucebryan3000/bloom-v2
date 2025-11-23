# Context Management Playbook

A comprehensive guide to understanding, auditing, and optimizing Claude Code context loading strategies. This playbook covers the three core strategies: **preloading**, **on-demand**, and **blocking**.

---

## <¯ Quick Reference: The Three Context Strategies

| Strategy | Usage | When to Use | Performance | Example |
|----------|-------|-----------|-------------|---------|
| **Preload** | Auto-loaded on every conversation | Essential files needed frequently | Higher context usage | `.claude/commands/*.md`, `CLAUDE.md` |
| **On-Demand** | Loaded when explicitly requested | Large files used occasionally | Optimal balance | `/agent-ui`, `/prompt-execute` |
| **Blocking** | Excluded entirely from context | Never needed or security-sensitive | Zero context overhead | `node_modules/`, `.env` files |

---

## =Ê Current Context Management Audit

### Baseline Metrics

**Before Optimization:**
- Total lines that could be loaded: ~14,830 lines
- Current actual context: ~4,000 lines
- **Reduction: 73%** 

### Breakdown by Strategy

#### 1. Preloaded Files (Always in Context)

**Purpose:** Essential project configuration and commands available immediately

**Files:**
- `CLAUDE.md` (this project's core instructions)
- `.claude/commands/*.md` (all slash commands - lightweight wrappers)
- `.claude/agents/backend-typescript-architect.md` (most frequently used agent)
- `.claude/docs/*.md` (quick reference documentation)

**Total Lines:** ~4,000 lines
**Context Cost:** 27% (baseline)

**Why:** These files are referenced in almost every conversation. Removing them would require reloading constantly.

---

#### 2. On-Demand Files (Excluded, but Accessible)

**Purpose:** Large or specialized files loaded only when explicitly requested

**Category A: Agent Definitions**
```
.claude/agents/ui-engineer.md
.claude/agents/senior-code-reviewer.md
.claude/agents/spec-orchestrator.md
.claude/agents/spec-analyst.md
... (13 more agent files)
```
- **Total Lines:** ~10,000 lines
- **Loading Method:** `/agent-*` slash commands (e.g., `/agent-ui`)
- **Use Case:** Load specialized expertise only when needed
- **Context Savings:** ~66% reduction (these aren't auto-loaded)

**Category B: Prompt Templates**
```
.claude/prompts/comprehensive-test-plan.md (~25KB)
.claude/prompts/refactor-remove-aws-s3.md (~13KB)
```
- **Total Lines:** ~25,000+ lines
- **Loading Method:** `/prompt-execute path/to/prompt.md`
- **Use Case:** Complex multi-phase implementations
- **Context Savings:** Large templates aren't in auto-context

**Category C: Build Backlog Data**
```
.claude/commands/build-backlog/*.md (data files)
```
- **Loading Method:** `/build-backlog` command loads on-demand
- **Use Case:** Task reference and dependency tracking
- **Context Savings:** Backlog data isn't auto-loaded

**Category D: Large Documentation**
```
docs/kb/ (810+ lines of patterns)
docs/out-of-scope/
_build/ (planning and build artifacts)
```
- **Loading Method:** Explicit Tool search when needed
- **Use Case:** Reference when investigating specific patterns
- **Context Savings:** Reference docs stay out of auto-context

---

#### 3. Blocked Files (Never in Context)

**Purpose:** Files that should never be loaded (security, redundancy, or irrelevance)

**Security-Critical (NEVER load):**
- `.env`, `.env.local`, `.env.*.local` - Contains API keys and secrets
- `.sentryclirc` - Tool credentials
- `scripts/docker/.env.docker.reference` - Deployment secrets

**Generated/Transient (Don't need to load):**
- `node_modules/` - 1000s of packages, use imports instead
- `.next/`, `build/`, `dist/` - Rebuilt on every build
- `coverage/`, `playwright-report/`, `test-results/` - Test artifacts
- `.db`, `.db-wal`, `.db-shm` - Runtime databases
- `logs/` - Runtime logs (except directory structure)

**Redundant (Available elsewhere):**
- `package-lock.json`, `yarn.lock` - Use `package.json` instead
- `components/ui/**` - Same files in node_modules
- `**/*.d.ts` - Search on-demand if needed
- `**/*.test.ts` - Search on-demand when investigating

**Git/System (Not relevant to code):**
- `.git/` - Version control metadata
- `.vscode/`, `.idea/` - Personal IDE settings
- `.DS_Store`, `Thumbs.db` - OS files

---

## = How to Audit Your Context

### Step 1: Check Current Context Usage

```bash
# View current .claudeignore configuration
cat .claudeignore

# Count preloaded files
ls -la .claude/docs/ | grep "\.md$" | wc -l
ls -la .claude/commands/*.md | wc -l

# Estimate lines of preloaded content
wc -l .claude/docs/*.md CLAUDE.md .claude/commands/*.md | tail -1

# Check on-demand files
du -sh .claude/agents/
du -sh .claude/prompts/
```

### Step 2: Analyze Current Strategy

**Ask yourself for each file/directory:**

1. **Is it used in every conversation?** ’ Preload
2. **Is it used occasionally/on-demand?** ’ On-demand
3. **Is it essential or security-sensitive?** ’ Block
4. **Is it large but rarely used?** ’ On-demand or block

### Step 3: Review Index Files

The `.claude/docs/context-management-claude/` directory contains metadata files:

- `index-agents.md` - Documents all 15 agents and when to use each
- `index-slash-commands.md` - Documents all commands with patterns
- `index-prompts.md` - Documents available prompts and execution methods
- `index-other.md` - Configuration files and infrastructure reference
- `index-gitignore-claude.ignore.md` - Manifest of ignored files

**These index files serve as:**
- Quick reference guides (don't auto-load in context)
- Claude Code web metadata (allows web clients to know files exist)
- Audit trail (track what's included/excluded and why)

### Step 4: Calculate Impact

```bash
# Estimate current context cost
echo "=== PRELOADED FILES ==="
wc -l .claude/docs/*.md .claude/commands/*.md CLAUDE.md 2>/dev/null | tail -1

echo "=== ON-DEMAND FILES (not counted in context) ==="
wc -l .claude/agents/*.md 2>/dev/null | tail -1
wc -l .claude/prompts/*.md 2>/dev/null | tail -1

echo "=== BLOCKED FILES (never loaded) ==="
du -sh node_modules/ .next/ build/ 2>/dev/null | awk '{sum += $1} END {print sum}'
```

---

## =à Context Optimization Workflow

### Workflow A: Add a New Preloaded Resource

When you need a file available in every conversation:

1. **Create the file** in `.claude/docs/` or `.claude/commands/`
2. **Verify it's essential** - Will it be referenced frequently?
3. **Add to index file** - Document in appropriate `index-*.md`
4. **Update `.claudeignore`** - Add negation rule if needed:
   ```
   .claude/docs/your-new-doc.md  # Auto-preloaded (in docs/)
   ```
5. **Measure impact** - Run context calculation from Step 4 above
6. **Document the decision** - Update CLAUDE.md with rationale

### Workflow B: Add an On-Demand Resource

When you have a large file used occasionally:

1. **Create the file** in `.claude/agents/`, `.claude/prompts/`, or other on-demand location
2. **Create loading mechanism** - Slash command or explicit reference
3. **Add to index file** - Document in `index-agents.md` or `index-prompts.md`
4. **Update `.claudeignore`** - Already configured for on-demand:
   ```
   .claude/agents/*              # Excluded by default
   !.claude/agents/your-agent.md # Keep only if it's most-used
   ```
5. **Test loading** - Verify command works: `/agent-your-agent`
6. **Document the loading method** - In the index file and CLAUDE.md

### Workflow C: Add a Blocked Resource

When a file should never be in context:

1. **Identify the file/pattern**
2. **Add to `.gitignore`** if it shouldn't be committed:
   ```
   my-temp-file.txt
   ```
3. **Add to `.claudeignore`** if it exists but shouldn't load:
   ```
   path/to/file-to-exclude
   ```
4. **Document in `index-gitignore-claude.ignore.md`** why it's blocked
5. **Verify it's not referenced** anywhere in active code

---

## =Ë .claudeignore Reference

### File Patterns and Their Rationale

```yaml
# PRELOAD STRATEGY - Always available
# (These are NOT in .claudeignore because they should auto-load)
.claude/commands/*.md          # Lightweight command wrappers
.claude/docs/*.md              # Project documentation
.claude/agents/backend-typescript-architect.md  # Most-used agent

# ON-DEMAND STRATEGY - Excluded but accessible
.claude/agents/*               # Large agent files (~10,000 lines)
!.claude/agents/backend-typescript-architect.md  # Exception: keep this one
.claude/prompts/               # Large prompt templates (~25KB+)
.claude/commands/build-backlog/*.md  # Backlog data files
_build/                        # Planning artifacts (large, on-demand)
docs/kb/                       # Knowledge base (810+ lines)

# BLOCKING STRATEGY - Never loaded
node_modules/                  # Dependencies (use imports)
.next/ build/ dist/           # Build artifacts (regenerated)
.env .env.local .env.*.local  # SECRETS - never load
.db *.db-wal *.db-shm         # Runtime data
coverage/ playwright-report/  # Test artifacts
.git/ .gitignore              # Version control
.vscode/ .idea/               # Personal IDE settings
```

### How .claudeignore Works

**Pattern Matching:**
- `path/to/file` - Excludes specific file
- `path/to/dir/` - Excludes directory and contents
- `**/*.pattern` - Excludes all matching files recursively

**Negation (Exceptions):**
- `!path/to/keep` - Re-include a previously excluded pattern

**Example:**
```
.claude/agents/*                      # Exclude all agents
!.claude/agents/backend-typescript-architect.md  # Except this one
```

---

## <¯ Optimization Decision Matrix

Use this matrix to decide where each file should go:

```
Is it SMALL?
  YES                             
  Is it FREQUENTLY USED?          
    YES ’ PRELOAD                
    NO ’ ON-DEMAND or BLOCK      
                                  
  NO (large file)                 $
   Is it FREQUENTLY USED?          
     YES ’ Check if essential     
             YES ’ PRELOAD       
             NO ’ ON-DEMAND      
     NO ’ ON-DEMAND or BLOCK      

SECURITY/SECRET?
  YES ’ BLOCK (CRITICAL!)

GENERATED/TRANSIENT?
  YES ’ BLOCK
```

---

## =È Impact Analysis: Current Setup

### Context Reduction Achievement

| Category | Lines | Status | Impact |
|----------|-------|--------|--------|
| Preloaded (essential docs) | ~4,000 |  Loaded | Baseline |
| Agents (~10K lines) | ~10,000 | =æ On-demand | -67% context |
| Prompts (~25K lines) | ~25,000 | =æ On-demand | -85% context |
| Build artifacts | ~50K+ | Ô Blocked | -100% context |
| Dependencies | 1000s MB | Ô Blocked | -100% context |
| Secrets | N/A | = Blocked | Security  |

**Total Reduction: 73%** (from ~14,830 to ~4,000 lines)

### Real-World Benefits

1. **Faster Conversations** - Smaller context = faster token processing
2. **Better Focus** - Fewer distracting files in context
3. **Cost Savings** - Fewer tokens = lower API costs
4. **Responsiveness** - Agents load quickly when needed
5. **Security** - Secrets never reach Claude context

---

## =€ Running the Optimization Audit

### Full Audit Workflow

#### Phase 1: Baseline Assessment (5 min)

```bash
# Get current sizes
echo "=== CURRENT CONTEXT AUDIT ==="
echo "Preloaded files:"
wc -l .claude/docs/*.md .claude/commands/*.md CLAUDE.md 2>/dev/null | tail -1

echo "On-demand files (agents):"
wc -l .claude/agents/*.md 2>/dev/null | tail -1

echo "On-demand files (prompts):"
wc -l .claude/prompts/*.md 2>/dev/null | tail -1

echo "Blocked (size only):"
du -sh node_modules/ .next/ 2>/dev/null

echo "Secrets (should be BLOCKED):"
ls -la .env* 2>/dev/null || echo " No env files in root"
```

#### Phase 2: Strategy Review (10 min)

**For each category of files, ask:**

1.  **Is it correctly categorized?**
   - Preload: Essential and used every session?
   - On-demand: Large but used occasionally?
   - Blocked: Never needed or security-sensitive?

2. =Ê **Could it be optimized?**
   - Can a preloaded file move to on-demand?
   - Can an on-demand file be better documented?
   - Should a blocked file have a `.claudeignore` entry?

3. =Ý **Is it documented?**
   - Listed in appropriate `index-*.md` file?
   - Reason for categorization explained?
   - Loading method documented (for on-demand)?

#### Phase 3: Index File Updates (10 min)

**Review and update each index file:**

```bash
# Check index files exist
ls -la .claude/docs/context-management-claude/index-*.md

# Verify each documents its category
grep -l "Quick reference\|Quick Reference\|manifest\|Manifest" \
  .claude/docs/context-management-claude/index-*.md
```

**For each index file, ensure it includes:**
- Clear categorization (preload/on-demand/blocked)
- Why each item is in that category
- How to load/access on-demand items
- Last updated date
- Status (active/archived/deprecated)

#### Phase 4: .claudeignore Verification (5 min)

```bash
# Verify .claudeignore is comprehensive
echo "=== Current .claudeignore entries ==="
grep -v "^#" .claudeignore | grep -v "^$" | sort

# Check for missing patterns
echo "=== Files that might need blocking ==="
find . -maxdepth 2 -type f -name "*.db" -o -name ".env*" \
  | grep -v node_modules | head -10
```

**Checklist:**
-  All secrets blocked (`.env*`, API keys)
-  All build artifacts blocked (`.next/`, `dist/`, `build/`)
-  All dependencies blocked (`node_modules/`)
-  All on-demand files excluded properly
-  All essential files have negation exceptions (if needed)

#### Phase 5: Documentation Check (5 min)

**Verify project documentation:**

```bash
# Check CLAUDE.md references context strategy
grep -n "Claude Code Context\|context.*management\|preload\|on-demand\|blocking" \
  CLAUDE.md | head -10

# Check .claude/README.md references context files
grep -n "context.*management" .claude/README.md
```

**Checklist:**
-  CLAUDE.md explains context strategy
-  README.md links to context management docs
-  Index files are linked from main README
-  All context strategies are documented

#### Phase 6: Report & Optimize (10 min)

**Generate optimization report:**

```bash
cat > /tmp/context-audit.txt << 'EOF'
=== CONTEXT MANAGEMENT AUDIT REPORT ===
Date: $(date)
Project: Appmelia Bloom

BASELINE METRICS:
- Files that could be loaded: [COUNT]
- Currently preloaded: [COUNT]
- On-demand files: [COUNT]
- Blocked files: [COUNT]
- Context reduction: [PERCENTAGE]%

PRELOADED (auto-load):
$(wc -l .claude/docs/*.md .claude/commands/*.md CLAUDE.md 2>/dev/null)

ON-DEMAND (excluded):
$(wc -l .claude/agents/*.md 2>/dev/null)
$(wc -l .claude/prompts/*.md 2>/dev/null)

BLOCKED (never):
$(du -sh node_modules/ .env* 2>/dev/null | grep -v "cannot access")

RECOMMENDATIONS:
1. [List any files that could be optimized]
2. [Suggest on-demand loading for large files]
3. [Recommend index file updates]
EOF

cat /tmp/context-audit.txt
```

---

## =' Common Optimization Scenarios

### Scenario 1: New Agent Too Large to Preload

**Problem:** Created a new 5KB agent but it's not in top 3 most-used

**Solution:**
```
# 1. Add to .claude/agents/your-agent.md
# 2. Create slash command loader at .claude/commands/agent-your-agent.md
# 3. Document in index-agents.md:

### Your Agent
- Purpose: [description]
- Loading: /agent-your-agent
- When to use: [specific scenarios]
# 4. Do NOT include in .claudeignore exception (it's on-demand)
# 5. Users load with /agent-your-agent when needed
```

### Scenario 2: Documentation Grows Too Large

**Problem:** `.claude/docs/roi-formulas.md` now 15KB

**Solution:**
```
# Option A: Keep in docs (if essential)
# - Small enough to keep preloaded
# - Document why in CLAUDE.md

# Option B: Move to on-demand
# 1. Move to .claude/docs/context-management-claude/
# 2. Add to .claudeignore:
   .claude/docs/roi-formulas.md  # or use negation if subset
# 3. Reference with explicit tool search when needed
# 4. Update index-other.md with new location
```

### Scenario 3: New Build Artifact Type

**Problem:** New tool generates `*.report` files

**Solution:**
```
# 1. Add to .gitignore (if shouldn't be committed):
   *.report

# 2. Add to .claudeignore (if exists but shouldn't load):
   *.report

# 3. Document in index-gitignore-claude.ignore.md:
   - Reports generated by [TOOL]
   - Excluded because: [REASON]
   - Location: [PATH]
```

---

## =Ú Reference: Index Files Overview

Each index file in `.claude/docs/context-management-claude/` serves a purpose:

| Index File | Purpose | Strategy | Use Case |
|-----------|---------|----------|----------|
| **index-agents.md** | 15 agents documented | On-demand | Choose right agent for task |
| **index-slash-commands.md** | All commands listed | Preload (metadata) | Find available commands |
| **index-prompts.md** | Complex task prompts | On-demand | Execute `/prompt-execute` |
| **index-other.md** | Configuration files | Reference | Understand project setup |
| **index-gitignore-claude.ignore.md** | Ignored files manifest | On-demand | Know what exists but isn't loaded |

### How Index Files Affect Context

- **Preloaded:** Referenced by default in `.claude/commands/` or linked in CLAUDE.md
- **On-demand:** Excluded from `.claudeignore` but linked for explicit access
- **Metadata:** Files that help Claude Code web understand project structure

---

## ™ Maintaining Optimal Context

### Weekly Audit Checklist

- [ ] Check for new files added to project
- [ ] Verify secrets aren't in tracked files
- [ ] Update index files if new features added
- [ ] Review on-demand files for usage frequency
- [ ] Test all `/agent-*` commands still work
- [ ] Check `.claudeignore` is current with project structure

### Monthly Optimization Review

- [ ] Analyze which on-demand files are actually used
- [ ] Consider preloading frequently-used on-demand files
- [ ] Look for files that could be blocked or deleted
- [ ] Update context metrics in CLAUDE.md
- [ ] Review index files for accuracy

### Quarterly Deep Audit

- [ ] Recalculate total context usage
- [ ] Review project growth and impact
- [ ] Consider major reorganization if needed
- [ ] Update this playbook with new learnings
- [ ] Share findings with team

---

## <“ Context Management Best Practices

1. **Size Matters**
   - Preload: Keep under 5KB per file
   - On-demand: Can be 25KB+ per file
   - Blocked: Gigabytes of dependencies okay (never loaded)

2. **Frequency Matters**
   - Used every session? ’ Preload
   - Used weekly? ’ On-demand
   - Used monthly? ’ On-demand with clear search method
   - Never used? ’ Consider deleting

3. **Security First**
   - Secrets in `.env` ’ Must be blocked
   - API keys in code ’ Must be blocked
   - Credentials anywhere ’ Must be blocked

4. **Documentation Second**
   - Every preloaded file ’ Reference in CLAUDE.md or index files
   - Every on-demand file ’ Document in appropriate index
   - Every blocked pattern ’ Explain in index-gitignore

5. **Measure and Iterate**
   - Know your baseline (before optimization)
   - Know your target (desired context reduction)
   - Measure impact of changes
   - Iterate based on data

---

## = Related Resources

- **Main Configuration:** [`CLAUDE.md`](../../CLAUDE.md)
- **Claude Code Docs:** [`index-slash-commands.md`](./index-slash-commands.md)
- **Agent Reference:** [`index-agents.md`](./index-agents.md)
- **Ignored Files:** [`index-gitignore-claude.ignore.md`](./index-gitignore-claude.ignore.md)
- **Configuration Guide:** [`index-other.md`](./index-other.md)

---

**Last Updated:** 2025-11-17
**Version:** 1.0.0
**Status:** Active - Core context management strategy
**Maintained By:** Claude Code Project

### Key Metrics

- **Current Context Reduction:** 73% (from ~14,830 to ~4,000 lines)
- **Preloaded Files:** ~4,000 lines (27% of potential context)
- **On-Demand Files:** ~35,000 lines (accessible via commands)
- **Blocked Files:** Gigabytes of dependencies and secrets
- **Index Files:** 5 comprehensive reference guides
- **Audit Frequency:** Weekly recommendations, monthly reviews, quarterly deep audits

