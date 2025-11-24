# OmniForge Logging Examples

This directory contains example log files showing OmniForge output in different scenarios. Use these as reference for understanding logging behavior.

---

## 📋 Example Log Files

### 1. Local Development (Default) - STATUS Level
**File**: `omniforge_20251124_093015.log`
**Scenario**: Normal local development with user interaction
**Log Level**: STATUS (default)
**Duration**: 40 seconds

**Key Characteristics**:
- Friendly console output with progress indicators
- Shows INFO, STEP, OK, WARN, SKIP messages
- Full timestamps in log file
- Includes next steps and helpful information

**When to Use This**:
```bash
# Default behavior
omni run

# Or explicitly with STATUS level
LOG_LEVEL=status omni run
```

**What You'll See on Console**:
```
[STEP] Phase 0: Foundation - Verifying prerequisites
[OK] Node.js v20.10.0 installed
[OK] pnpm v9.1.0 installed
[STEP] Phase 1: Infrastructure - Setting up development environment
[WARN] PostgreSQL connection string uses localhost - local dev only
[SKIP] Feature: AI Integration - DISABLED
[OK] Bootstrap initialization completed successfully
```

**File Location**: `/home/luce/apps/bloom2/omniforge/logs/omniforge_20251124_093015.log`

---

### 2. Dry-Run Mode - Planning and Preview
**File**: `dry-run_20251124_102430.log`
**Scenario**: Preview what would be executed without making changes
**Log Level**: STATUS
**Duration**: 7 seconds

**Key Characteristics**:
- All operations prefixed with `[DRY]` indicator
- Shows what files would be created
- Shows what commands would be executed
- Shows what packages would be installed
- Ends with summary of planned changes

**When to Use This**:
```bash
# Preview without making changes
omni run --dry-run

# Or with environment variable
DRY_RUN=true omni run
```

**What You'll See on Console**:
```
[DRY] Would create directory: /home/luce/apps/bloom2/src/
[DRY] Would create directory: /home/luce/apps/bloom2/src/components
[DRY] Would execute: pnpm install
[DRY] Would write file: /home/luce/apps/bloom2/.env

DRY-RUN SUMMARY:
  Directories to create: 5
  Files to write: 8
  Commands to execute: 6
```

**Useful For**:
- Understanding what installation will do
- Validating configuration before committing
- Educational purposes (learning the bootstrap process)

**File Location**: `/home/luce/apps/bloom2/omniforge/logs/dry-run_20251124_102430.log`

---

### 3. CI/CD Pipeline - QUIET Level
**File**: `ci-cd_20251124_140815.log`
**Scenario**: Automated deployment in CI/CD pipeline
**Log Level**: QUIET
**Duration**: 67 seconds

**Key Characteristics**:
- Minimal console output (errors only)
- Log file contains all details
- One line per phase summary
- Clean, parseable output for automation
- No interactive prompts

**When to Use This**:
```bash
# CI/CD environment
LOG_LEVEL=quiet omni run

# Or with environment variable
NON_INTERACTIVE=true omni run
```

**What You'll See on Console**:
```
[INFO] Phase 0: Foundation
[OK] Phase 0 completed (1s)
[INFO] Phase 1: Infrastructure
[OK] Phase 1 completed (28s)
```

**Useful For**:
- GitHub Actions, GitLab CI, Jenkins, etc.
- Automated deployments where logs go to files
- Systems with limited console output
- Parsing structured output

**File Location**: `/home/luce/apps/bloom2/omniforge/logs/ci-cd_20251124_140815.log`

---

### 4. Verbose Debug - Full Trace
**File**: `verbose_20251124_155230.log`
**Scenario**: Detailed troubleshooting with full debug output
**Log Level**: VERBOSE
**Duration**: 41 seconds

**Key Characteristics**:
- Includes all DEBUG messages
- Shows command execution details
- Shows variable values and substitutions
- Shows parsed versions and configurations
- Comprehensive execution trace

**When to Use This**:
```bash
# Troubleshooting
omni run --verbose

# Or with environment variable
VERBOSE=true omni run

# Or with explicit log level
LOG_LEVEL=verbose omni run
```

**What You'll See in Log File**:
```
[DEBUG] SCRIPTS_DIR=/home/luce/apps/bloom2/_build/omniforge
[DEBUG] LOG_DIR=/home/luce/apps/bloom2/omniforge/logs
[DEBUG] Checking Node.js installation
[DEBUG] Running: node --version
[DEBUG] Node.js output: v20.10.0
[DEBUG] Parsed version: 20.10.0
[DEBUG] mkdir -p /home/luce/apps/bloom2/src/
[DEBUG] Directory created with permissions: drwxr-xr-x
```

**Useful For**:
- Debugging configuration issues
- Understanding the bootstrap process in detail
- Performance analysis (timing information)
- Reproducing issues with exact command sequences

**File Location**: `/home/luce/apps/bloom2/omniforge/logs/verbose_20251124_155230.log`

---

### 5. Error Scenario - Recovery and Diagnostics
**File**: `error_20251124_161245.log`
**Scenario**: Bootstrap encounters errors and auto-remediation
**Log Level**: STATUS
**Duration**: 68 seconds

**Key Characteristics**:
- Shows ERROR messages with context
- Demonstrates auto-remediation attempts
- Shows error recovery workflow
- Includes warning summary at end
- Bootstrap completes despite errors (graceful degradation)

**Error Scenarios Shown**:
1. **PostgreSQL Not Available** → Auto-start service
2. **pnpm Store Offline** → Fallback to offline cache
3. **Migration Already Applied** → Skip and verify instead

**When to See This**:
- When prerequisites aren't available
- When services need to be started
- When network issues occur
- When database already initialized

**Recovery Actions**:
```
[ERROR] PostgreSQL not available
[WARN] Error recovery: Attempting auto-remediation
[INFO] Auto-remediation: Starting PostgreSQL service
[OK] PostgreSQL service started successfully
[INFO] Retrying Phase 0: Foundation
```

**Useful For**:
- Understanding error recovery mechanisms
- Seeing what auto-remediation can fix
- Identifying when manual intervention needed
- Learning bootstrap resilience

**File Location**: `/home/luce/apps/bloom2/omniforge/logs/error_20251124_161245.log`

---

## 🔍 Reading Log Files

### View a Specific Log
```bash
# View most recent log
cat omniforge/logs/omniforge_*.log | tail -50

# View all logs
ls -lah omniforge/logs/

# Search for warnings
grep WARN omniforge/logs/omniforge_*.log

# Search for errors
grep ERROR omniforge/logs/omniforge_*.log

# Get summary of a run
tail -10 omniforge/logs/omniforge_*.log
```

### Parse Log Output
```bash
# Extract timing information
grep -E '^\[.*\] \[(STEP|OK|ERROR)\]' omniforge/logs/omniforge_*.log

# Count message types
grep -o '\[.*\]' omniforge/logs/omniforge_*.log | sort | uniq -c

# Extract phase completion times
grep 'Phase.*completed' omniforge/logs/omniforge_*.log
```

---

## 📊 Log Format Reference

### Timestamp Format
```
[2025-11-24 09:30:15] [LEVEL] Message
          ^           ^       ^
          |           |       +-- Message content
          |           +---------- Log level
          +---------------------- ISO 8601 timestamp (local time)
```

### Log Levels (Examples)

| Level | Format | Usage | Visibility |
|-------|--------|-------|------------|
| **INFO** | `[2025-11-24 09:30:15] [INFO] ...` | Information messages | Console & File |
| **DEBUG** | `[2025-11-24 09:30:15] [DEBUG] ...` | Detailed debug info | File only |
| **STEP** | `[2025-11-24 09:30:15] [STEP] ...` | Phase/step markers | Console & File |
| **OK** | `[2025-11-24 09:30:15] [OK] ...` | Success messages | Console & File |
| **WARN** | `[2025-11-24 09:30:15] [WARN] ...` | Warnings | Console & File |
| **ERROR** | `[2025-11-24 09:30:15] [ERROR] ...` | Error messages | Console & File |
| **SKIP** | `[2025-11-24 09:30:15] [SKIP] ...` | Skipped features | Console & File |
| **DRY** | `[2025-11-24 09:30:15] [DRY] ...` | Dry-run previews | Console & File |

---

## 🔧 Configuration Reference

All logging is configured in `bootstrap.conf`:

```bash
# Central log directory
LOG_DIR="${PROJECT_ROOT}/omniforge/logs"

# Log level (quiet, status, verbose)
LOG_LEVEL="${LOG_LEVEL:-status}"

# Log format (plain, json)
LOG_FORMAT="${LOG_FORMAT:-plain}"

# Auto-rotation after N days
LOG_ROTATE_DAYS="30"

# Auto-cleanup archived logs after N days
LOG_CLEANUP_DAYS="90"
```

### Setting Log Level at Runtime

```bash
# Status level (default, friendly)
omni run                    # Uses LOG_LEVEL=status from config

# Quiet level (CI/CD)
LOG_LEVEL=quiet omni run    # Errors only

# Verbose level (debugging)
LOG_LEVEL=verbose omni run  # Full debug output
omni run --verbose          # Same as above
```

---

## 📁 Directory Structure

```
omniforge/logs/
├── omniforge_20251124_093015.log       # Local development run
├── dry-run_20251124_102430.log         # Dry-run preview
├── ci-cd_20251124_140815.log           # CI/CD deployment
├── verbose_20251124_155230.log         # Debug with verbose output
├── error_20251124_161245.log           # Error scenario with recovery
├── examples/                           # This directory
│   ├── LOG-EXAMPLES.md                 # This file
│   ├── omniforge_20251124_093015.log   # Local dev example
│   ├── dry-run_20251124_102430.log     # Dry-run example
│   ├── ci-cd_20251124_140815.log       # CI/CD example
│   ├── verbose_20251124_155230.log     # Verbose example
│   └── error_20251124_161245.log       # Error scenario example
└── archive/                            # Rotated logs (30+ days old)
    ├── omniforge_20251023_*.log
    └── (older logs auto-cleanup after 90 days)
```

---

## ⚡ Quick Reference

### For Local Development
```bash
# Run with status logging (friendly)
omni run

# Or see all debug details
omni run --verbose
```

### For CI/CD Pipeline
```bash
# Run with quiet logging (minimal console output)
LOG_LEVEL=quiet omni run

# All details go to log file
cat omniforge/logs/omniforge_*.log
```

### For Troubleshooting
```bash
# Generate verbose debug log
VERBOSE=true omni run

# Examine the detailed log
tail -100 omniforge/logs/omniforge_*.log | grep ERROR

# Or search for specific issues
grep -A 5 "ERROR" omniforge/logs/omniforge_*.log
```

### For Understanding Behavior
```bash
# Preview what would happen
omni run --dry-run

# Run for real
omni run

# Compare logs
diff <(tail -5 dry-run_*.log) <(tail -5 omniforge_*.log)
```

---

## 🎯 Scenario Decision Tree

```
Choose your logging scenario based on your use case:

Are you in CI/CD?
├─ YES → Use QUIET level (ci-cd_20251124_140815.log)
│         LOG_LEVEL=quiet omni run
│
└─ NO → Are you troubleshooting?
        ├─ YES → Use VERBOSE level (verbose_20251124_155230.log)
        │         VERBOSE=true omni run
        │
        └─ NO → Are you previewing before running?
                ├─ YES → Use DRY-RUN (dry-run_20251124_102430.log)
                │         omni run --dry-run
                │
                └─ NO → Use default STATUS level (omniforge_20251124_093015.log)
                         omni run  ← Friendly, interactive
```

---

## 📝 Example Output Summary

| File | Scenario | Duration | Log Lines | Best For |
|------|----------|----------|-----------|----------|
| `omniforge_...log` | Local Dev | 40s | 45 | Normal usage, development |
| `dry-run_...log` | Preview | 7s | 35 | Planning, validation |
| `ci-cd_...log` | Pipeline | 67s | 20 | Automated deployments |
| `verbose_...log` | Debug | 41s | 120 | Troubleshooting, details |
| `error_...log` | Error Scenario | 68s | 55 | Recovery, diagnosis |

---

## 🔗 Related Documentation

- [LOGGING.md](../LOGGING.md) - Complete logging system documentation
- [bootstrap.conf](../../bootstrap.conf) - Logging configuration
- [lib/logging.sh](../../lib/logging.sh) - Logging implementation
- [lib/log-rotation.sh](../../lib/log-rotation.sh) - Log rotation utilities

---

## ✅ Testing These Examples

To generate your own logs matching these examples:

```bash
# 1. Local development
cd /home/luce/apps/bloom2
omni run 2>&1 | tee omniforge/logs/test_local.log

# 2. Dry-run
omni run --dry-run 2>&1 | tee omniforge/logs/test_dryrun.log

# 3. CI/CD (quiet)
LOG_LEVEL=quiet omni run 2>&1 | tee omniforge/logs/test_cicd.log

# 4. Verbose debug
VERBOSE=true omni run 2>&1 | tee omniforge/logs/test_verbose.log

# Then compare with examples
diff omniforge/logs/examples/omniforge_*.log omniforge/logs/test_local.log
```

---

**Generated**: 2025-11-24
**OmniForge Version**: Latest
**Log System Version**: 1.0
