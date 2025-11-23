---
Context Strategy: L2 (Load on Demand, Searchable)
Tier: 3 - Specialized Reference
---

# Operations & Playbooks Index – docs/operations/ & docs/playbooks/

**Context Strategy:** L2 (On-Demand, Searchable)
**Total Files:** ~35+ operational documentation
**Status:** Operations guides, troubleshooting, and automation playbooks

---

## Overview

The Operations and Playbooks directories contain runbooks, troubleshooting guides, and operational procedures for Bloom. These are **intentionally excluded from preload** (L2 strategy) because:

- **Task-specific**: Only needed when performing specific operations
- **Procedural**: Contains step-by-step guides not needed constantly
- **Specialized**: Relevant for DevOps and maintenance, not every conversation
- **Reference-heavy**: For looking up procedures, not reading linearly

**Usage:** When performing maintenance, debugging, or deployment tasks, search for relevant playbooks.

---

## Operations Documentation

### Operations Categories

| Category | Files | Purpose | When Needed |
|----------|-------|---------|-----------|
| **Troubleshooting** | 3+ | Common issues and solutions | Something is broken |
| **Performance** | 2+ | Performance optimization guides | Improving responsiveness |
| **Deployment** | 2+ | Deployment procedures | Deploying to production |
| **Monitoring** | 2+ | Monitoring and alerting | System health checks |
| **Database** | 2+ | Database operations | Database maintenance |

---

## Playbooks Directory

### Playbook Categories

| Category | Files | Purpose | When Needed |
|----------|-------|---------|-----------|
| **Melissa Playbooks** | 20+ | AI agent execution playbooks | Melissa.ai operations |
| **Automation** | 3+ | Automation workflows | Automated tasks |
| **Deployment** | 3+ | Deployment automation | CI/CD operations |

---

## Directory Structure

```
docs/
├── operations/                      Operations & infrastructure docs
│   ├── troubleshooting.md          Common problems and solutions
│   ├── performance-benchmarking.md Performance tuning guide
│   ├── deployment.md               Production deployment procedures
│   ├── monitoring.md               Monitoring setup
│   └── [database files]            Database operations
│
└── playbooks/                       Automation and operational runbooks
    ├── README.md                   Playbooks overview
    ├── melissa/                    Melissa.ai automation
    │   ├── [execution playbooks]
    │   └── [configuration playbooks]
    ├── deployment/                 Deployment automation
    └── [automation scripts]
```

---

## Operations Documentation Details

### Troubleshooting Guide

**Location:** `docs/operations/troubleshooting.md`

**Covers:**
- Common errors and error messages
- Debugging strategies
- Log file locations and reading logs
- Database connection issues
- API integration problems
- Performance issues
- Session management problems
- Export generation failures

**When to use:** Application behaving unexpectedly or errors occurring

**Example searches:**
```bash
grep -n "error\|fail\|timeout" docs/operations/troubleshooting.md
grep -n "session\|database\|API" docs/operations/troubleshooting.md
```

---

### Performance Benchmarking

**Location:** `docs/operations/performance-benchmarking.md`

**Covers:**
- Performance metrics and targets
- Profiling tools and techniques
- Caching optimization strategies
- Database query optimization
- API response time improvements
- Frontend performance optimization
- Load testing procedures
- Benchmarking methodology

**When to use:** Optimizing application performance or investigating slowness

**Example searches:**
```bash
grep -n "latency\|throughput\|optimization" docs/operations/performance-benchmarking.md
grep -n "cache\|query\|profile" docs/operations/performance-benchmarking.md
```

---

### Deployment Guide

**Location:** `docs/operations/deployment.md`

**Covers:**
- Pre-deployment checklist
- Production deployment procedures
- Database migration process
- Rollback procedures
- Monitoring post-deployment
- Environment configuration
- Docker deployment
- Health check procedures

**When to use:** Deploying to production or setting up new environments

**Example usage:**
```bash
# Read full deployment guide
cat docs/operations/deployment.md

# Search for specific procedure
grep -n "docker\|migration\|rollback" docs/operations/deployment.md
```

---

### Monitoring Setup

**Location:** `docs/operations/monitoring.md`

**Covers:**
- Health check endpoints
- Metric collection setup
- Dashboard configuration
- Alert thresholds
- Log aggregation
- Performance monitoring
- Error tracking
- Uptime monitoring

**When to use:** Setting up monitoring or investigating system health

---

## Playbooks

### Melissa.ai Playbooks

**Location:** `docs/playbooks/melissa/`

**Covers:** (~20+ files)
- Conversation flow automation
- Data extraction playbooks
- ROI calculation automation
- Confidence scoring playbooks
- Workshop facilitation scripts
- Configuration playbooks
- Integration playbooks
- Testing playbooks

**When to use:** Working with Melissa.ai, automating conversations, debugging agent behavior

**Example playbooks:**
```
COMPREHENSIVE-MELISSA-IMPLEMENTATION-PLAN.md
FULL-IMPLEMENTATION-PLAN.md
MELISSA-PLAYBOOKS-IMPLEMENTATION.md
Claude-Settings-Playbook-UI.md
Claude-Tests-IFL-and-Compiler.md
```

---

### Deployment Automation

**Location:** `docs/playbooks/deployment/`

**Covers:** (~3+ files)
- Automated deployment scripts
- CI/CD workflow automation
- Docker build automation
- Database migration automation
- Rollback automation

**When to use:** Automating deployment processes, setting up CI/CD

---

### General Automation

**Location:** `docs/playbooks/`

**Covers:** (~3+ files)
- General automation patterns
- Script templates
- Workflow automation
- Task automation

**When to use:** Creating new automation, understanding automation patterns

---

## How to Access Operations Documentation

### Option 1: Read Operations Guide
```bash
# Start with operations README
cat docs/operations/README.md

# Read specific guide
cat docs/operations/troubleshooting.md

# View all operation files
ls docs/operations/*.md
```

### Option 2: Search for Specific Issue
```bash
# Find troubleshooting for specific problem
grep -n "session\|timeout\|error" docs/operations/troubleshooting.md

# Search all operations docs
grep -r "deployment\|migration" docs/operations/

# Find performance tips
grep -n "cache\|optimize\|profile" docs/operations/performance-benchmarking.md
```

### Option 3: Follow Playbook
```bash
# List available playbooks
ls docs/playbooks/melissa/*.md

# Read specific playbook
cat docs/playbooks/melissa/COMPREHENSIVE-MELISSA-IMPLEMENTATION-PLAN.md

# Execute playbook steps
# (Follow numbered steps in playbook)
```

### Option 4: Agent-Assisted Lookup
```bash
# Ask agent for operational guidance
/agent-backend
# "Find the troubleshooting guide for session issues"

# Ask for deployment help
/agent-spec-developer
# "How do I deploy this to production?"
```

---

## Common Operations Tasks

### "I see an error in the logs"
1. Read: `docs/operations/troubleshooting.md`
2. Search: `grep -n "[error message]" docs/operations/troubleshooting.md`
3. Follow: Listed solution steps

### "Application is slow"
1. Read: `docs/operations/performance-benchmarking.md`
2. Profile: Use tools listed in guide
3. Optimize: Follow recommended optimizations

### "I need to deploy changes"
1. Check: `docs/operations/deployment.md` pre-deployment checklist
2. Execute: Follow deployment procedure
3. Verify: Run health checks from guide

### "I need to set up Melissa"
1. Follow: `docs/playbooks/melissa/COMPREHENSIVE-MELISSA-IMPLEMENTATION-PLAN.md`
2. Configure: Use playbook configuration steps
3. Verify: Run testing playbook

### "I need to migrate the database"
1. Read: `docs/operations/deployment.md` migration section
2. Backup: Follow backup procedure
3. Execute: Run migration steps
4. Verify: Check health and rollback if needed

---

## Operations Checklist Templates

### Pre-Deployment Checklist
Located in: `docs/operations/deployment.md`

```
□ Code review completed
□ All tests passing
□ Database migrations prepared
□ Environment variables configured
□ Monitoring alerts active
□ Rollback plan documented
□ Team notified
□ Deployment scheduled
```

### Post-Deployment Verification
Located in: `docs/operations/deployment.md`

```
□ Health checks pass
□ APIs responding
□ Database queries working
□ Logs showing normal activity
□ Performance metrics acceptable
□ No error spikes detected
□ Users report normal operation
```

### Troubleshooting Procedure
Located in: `docs/operations/troubleshooting.md`

```
1. Check error message
2. Search troubleshooting guide
3. Follow recommended steps
4. If unresolved, check logs
5. If still unresolved, check dependencies
6. Document issue and solution
```

---

## Playbook Execution

### How to Execute a Playbook

**Step 1: Read the playbook completely**
```bash
cat docs/playbooks/[playbook].md
```

**Step 2: Understand the prerequisites**
- Required tools
- Environment variables
- Database state
- System requirements

**Step 3: Execute steps in order**
- Follow numbered steps exactly
- Verify each step completes successfully
- Record any deviations

**Step 4: Verify completion**
- Run verification steps if included
- Check health/status endpoints
- Test affected features

**Step 5: Document results**
- Note execution time
- Record any issues encountered
- Update playbook if changes needed

---

## Operations Best Practices

### When Troubleshooting

1. **Gather information**: Collect error messages, logs, timestamps
2. **Search documentation**: Look in troubleshooting guide first
3. **Check similar issues**: Multiple issues often have same root cause
4. **Follow procedure**: Don't skip steps in troubleshooting playbooks
5. **Document solution**: Add to knowledge base if new issue

### When Deploying

1. **Use checklists**: Follow pre/post-deployment checklists
2. **Test in staging**: Never deploy untested code
3. **Plan rollback**: Always have rollback procedure ready
4. **Communicate**: Notify team of deployment
5. **Monitor closely**: Watch metrics after deployment

### When Running Playbooks

1. **Read completely**: Understand full playbook before starting
2. **Verify prerequisites**: Ensure all requirements met
3. **Execute sequentially**: Don't skip or reorder steps
4. **Document changes**: Track what was done
5. **Verify results**: Confirm playbook objectives met

---

## Maintenance of Operations Documentation

### Weekly
- Monitor for new issues
- Update troubleshooting if new problems occur
- Check playbook accuracy

### Monthly
- Review operations logs
- Update performance benchmarks
- Archive old playbooks
- Verify deployment procedures

### Quarterly
- Conduct operations audit
- Update documentation for new features
- Consolidate duplicate procedures
- Create new playbooks for common operations

---

## Integration with Other Documentation

### Related Documentation

- **Features**: `docs/features/` – Feature-specific operations
- **KB**: `docs/kb/` – Technical reference for tools used
- **Architecture**: `docs/ARCHITECTURE.md` – System design and patterns
- **Codebase**: `lib/`, `app/` – Actual implementation

### Cross-References

```bash
# Find all references to a system component
grep -r "cache\|database\|api" docs/operations/ docs/playbooks/

# Map between documentation and code
grep -r "function\|class" docs/playbooks/ | grep -l "$(grep -r 'export' lib/ | awk '{print $NF}')"
```

---

## Emergency Procedures

### If Production Is Down

1. **Check monitoring**: `docs/operations/monitoring.md`
2. **Search troubleshooting**: `docs/operations/troubleshooting.md`
3. **Follow emergency procedure**: Listed under "Emergency" section
4. **Prepare rollback**: Have `docs/operations/deployment.md` rollback ready
5. **Document incident**: Note what happened and solution

### If Database Is Corrupted

1. **Stop application**: Prevent further corruption
2. **Check backup**: Verify recent backup exists
3. **Review procedure**: `docs/operations/deployment.md` database section
4. **Restore from backup**: Follow restore procedure
5. **Verify integrity**: Run health checks

### If Performance Degrades

1. **Check metrics**: `docs/operations/monitoring.md` metrics
2. **Review benchmarks**: `docs/operations/performance-benchmarking.md`
3. **Identify bottleneck**: Use profiling tools from guide
4. **Apply fix**: Follow optimization steps
5. **Monitor**: Verify performance returns to normal

---

## Relationship to Context Management

### Why Operations Docs are L2

1. **Task-specific** – Only needed for specific operations
2. **Procedural** – Not needed unless performing that task
3. **Reference-heavy** – Meant for looking up, not reading constantly
4. **Specialized** – DevOps/operations focus, not general development
5. **Large**: ~35+ files = 15K+ tokens if preloaded

### How to Access During Work

```bash
# Search from agent
/session-backend
# "Find the troubleshooting guide for [issue]"

# Direct search
grep -r "[problem]" docs/operations/

# Follow playbook
cat docs/playbooks/[playbook].md
# Execute steps 1-N
```

---

**Last Updated:** 2025-11-17
**Operations Files:** ~15 documentation files
**Playbook Files:** ~20+ playbook files
**Total Files:** ~35+
**Context Cost if Preloaded:** ~15,000+ tokens (WHY IT'S L2!)
**Current Context Cost:** ~0 tokens (indexed, not loaded)
