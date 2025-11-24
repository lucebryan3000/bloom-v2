# OmniForge Logging System

**Status**: Production Ready ✅
**Last Updated**: 2025-11-24
**Version**: 1.0

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Log Directory Structure](#log-directory-structure)
3. [Log Levels & Output](#log-levels--output)
4. [Scenarios](#scenarios)
5. [Configuration](#configuration)
6. [Log Files](#log-files)
7. [Troubleshooting](#troubleshooting)

---

## Quick Start

### Default Behavior (Local Development)

```bash
$ omni run
[INFO] ========================================
[INFO]   PREFLIGHT CHECK
[INFO] ========================================

[STEP] Checking dependencies for all phases...
[OK] All preflight checks passed
[STEP] Phase 0: Project Foundation...
[STEP] Installing Next.js...
  [OK] core/00-nextjs.sh (12s)
  [OK] typescript setup (8s)
[OK] Phase 0 completed in 20s

Log: /home/luce/apps/bloom2/omniforge/logs/omniforge_20251124_143015.log
```

### Dry-Run Mode

```bash
$ omni run --dry-run
[INFO] ========================================
[INFO]   DRY RUN MODE (No changes will be made)
[INFO] ========================================

[STEP] Phase 0: Project Foundation...
[DRY] Would execute: pnpm install next react react-dom
[DRY] Would execute: npx tsc --init
[DRY] Would create: src/app/layout.tsx
...

Log: /home/luce/apps/bloom2/omniforge/logs/omniforge_20251124_143015.log
```

### Verbose Output

```bash
$ omni run --verbose
[INFO] Loading configuration from bootstrap.conf...
[DEBUG] Found 6 phases in phase-metadata
[DEBUG] Phase 0 has 5 scripts
[STEP] Checking dependencies...
[DEBUG] Checking git: /usr/bin/git (20.0.0)
[DEBUG] Checking node: /usr/bin/node (v20.11.0)
[DEBUG] Checking pnpm: /home/user/.local/bin/pnpm (9.0.0)
[STEP] Phase 0: Project Foundation...
...
```

### Quiet Mode

```bash
$ omni run --quiet
[OK] Phase 0 completed in 20s
[OK] Phase 1 completed in 45s
[ERROR] Phase 2 failed: Missing docker
```

---

## Log Directory Structure

```
omniforge/logs/
├── omniforge_20251124_143015.log      # Latest run
├── omniforge_20251124_142530.log      # Previous run
├── omniforge_20251124_141200.log      # Earlier run
├── dry-run_20251124_143000.log        # Dry-run logs
└── archive/                            # Old logs (auto-archived after 30 days)
    ├── omniforge_20251120_*.log
    ├── omniforge_20251119_*.log
    └── ...
```

### Directory Configuration

**Location**: `omniforge/logs/` (relative to project root)

**Configuration**: Set in `bootstrap.conf`

```bash
LOG_DIR="${PROJECT_ROOT}/omniforge/logs"
```

**Automatic Features**:
- ✅ Auto-created on first run
- ✅ Auto-rotation after 30 days
- ✅ Auto-cleanup of archives after 90 days
- ✅ Separated dry-run logs from production

---

## Log Levels & Output

### Console Output by Level

#### 1. QUIET Mode (`--quiet` / `LOG_LEVEL=quiet`)

**Console**: Errors only
**File**: Full details

```
[ERROR] Phase 2 failed: Missing docker
For details, see: /home/luce/apps/bloom2/omniforge/logs/omniforge_20251124_143015.log
```

**Use Case**: CI/CD pipelines, automated runs

#### 2. STATUS Mode (Default)

**Console**: Info, warnings, steps, success, skip, errors
**File**: Full details with timestamps

```
[INFO] OmniForge v3.0.0 - Project Foundation
[STEP] Checking dependencies...
[WARN] pnpm not found
[STEP] Installing pnpm...
[OK] pnpm installed successfully
[STEP] Phase 0: Project Foundation...
  [OK] core/00-nextjs.sh (12s)
  [OK] db/drizzle-schema-base.sh (8s)
  [SKIP] observability/pino-logger.sh (already completed)
[OK] Phase 0 completed in 20s
```

**Use Case**: Local development, interactive runs

#### 3. VERBOSE Mode (`--verbose` / `VERBOSE=true`)

**Console**: Everything (info, debug, trace)
**File**: Full details with timestamps

```
[INFO] Loading configuration from bootstrap.conf
[DEBUG] Found 6 phases in phase-metadata
[DEBUG] Phase 0 has 5 scripts
[DEBUG] Checking git: /usr/bin/git (20.0.0)
[DEBUG] Checking node: /usr/bin/node (v20.11.0)
[DEBUG] Checking pnpm: /home/user/.local/bin/pnpm (9.0.0)
[STEP] Checking dependencies...
[OK] All dependencies satisfied
[STEP] Phase 0: Project Foundation...
[STEP] Running: core/00-nextjs.sh
[DEBUG] Setting INSTALL_DIR=/home/luce/apps/bloom2
[DEBUG] Creating package.json
[DEBUG] Installing dependencies...
[DEBUG] pnpm install output:
  added 256 packages in 12s
[OK] core/00-nextjs.sh completed (12s)
```

**Use Case**: Debugging, detailed analysis

---

## Scenarios

### Scenario 1: Local Development (Default)

```bash
$ omni run
[INFO] ========================================
[INFO]   OmniForge v3.0.0
[INFO]   Infinite Architectures. Instant Foundation.
[INFO] ========================================

[INFO] Loading configuration...
[STEP] Validating environment...
[OK] Node.js 20.11.0 (requires 20+)
[OK] pnpm 9.0.0 (requires 9+)
[STEP] Checking for previous runs...
[OK] Found existing .bootstrap_state (resuming from phase 1)
[STEP] Phase 1: Database Foundation...
  [STEP] Running: db/drizzle-schema-base.sh
  [OK] db/drizzle-schema-base.sh (5s)
  [STEP] Running: db/seed-data.sh
  [SKIP] db/seed-data.sh (already completed)
[OK] Phase 1 completed in 5s
[STEP] Phase 2: Core Features...
  [STEP] Running: observability/pino-logger.sh
  [OK] observability/pino-logger.sh (8s)
[OK] Phase 2 completed in 8s
[INFO] ========================================
[OK] All phases completed successfully! (35s total)
[INFO] ========================================

Log: /home/luce/apps/bloom2/omniforge/logs/omniforge_20251124_143015.log
```

**Log File** (`omniforge_20251124_143015.log`):
```
[2025-11-24 14:30:15] [INIT] === OmniForge Logging Initialized ===
[2025-11-24 14:30:15] [INIT] Script: omniforge
[2025-11-24 14:30:15] [INIT] Date: 2025-11-24 14:30:15
[2025-11-24 14:30:15] [INIT] User: luce
[2025-11-24 14:30:15] [INIT] PWD: /home/luce/apps/bloom2
[2025-11-24 14:30:15] [INIT] LOG_LEVEL: status
[2025-11-24 14:30:15] [INIT] DRY_RUN: false
[2025-11-24 14:30:15] [INFO] Loading configuration from bootstrap.conf
[2025-11-24 14:30:15] [DEBUG] Loaded 451 lines of configuration
[2025-11-24 14:30:15] [STEP] Validating environment...
[2025-11-24 14:30:15] [EXEC] Running: node --version
[2025-11-24 14:30:15] [OUTPUT] v20.11.0
[2025-11-24 14:30:15] [OK] Node.js validation passed
[2025-11-24 14:30:16] [STEP] Phase 1: Database Foundation...
[2025-11-24 14:30:16] [EXEC] Starting: db/drizzle-schema-base.sh
[2025-11-24 14:30:16] [OUTPUT] Creating database schema...
[2025-11-24 14:30:21] [OK] db/drizzle-schema-base.sh (5s)
[2025-11-24 14:30:21] [STEP] Phase 2: Core Features...
[2025-11-24 14:30:21] [EXEC] Starting: observability/pino-logger.sh
[2025-11-24 14:30:29] [OK] observability/pino-logger.sh (8s)
[2025-11-24 14:30:29] [SUMMARY] All phases completed successfully in 35s
```

### Scenario 2: Dry-Run Mode

```bash
$ omni run --dry-run
[INFO] ========================================
[INFO]   DRY RUN MODE
[INFO]   No changes will be made to your system
[INFO] ========================================

[STEP] Phase 0: Project Foundation...
  [DRY] Would execute: pnpm install next react react-dom
  [DRY] Would create: tsconfig.json
  [DRY] Would create: src/app/layout.tsx
[OK] Phase 0 preview: 3 actions would be executed
[STEP] Phase 1: Database...
  [DRY] Would execute: pnpm install drizzle-orm
  [DRY] Would create: src/db/schema.ts
[OK] Phase 1 preview: 2 actions would be executed
[INFO] ========================================
[OK] Dry-run completed successfully
[INFO] Would execute: 5 actions total
[INFO] Ready to run with: omni run
[INFO] ========================================

Log: /home/luce/apps/bloom2/omniforge/logs/dry-run_20251124_143000.log
```

### Scenario 3: CI/CD Pipeline (Quiet Mode)

```bash
$ omni run --quiet 2>&1
[OK] Phase 0 completed
[OK] Phase 1 completed
[OK] Phase 2 completed
[OK] Phase 3 completed
[OK] Phase 4 completed
[OK] Phase 5 completed

For details, see: /home/luce/apps/bloom2/omniforge/logs/omniforge_20251124_143015.log
```

**Log File** provides full details for diagnostics:
```
[2025-11-24 14:30:15] [INIT] === OmniForge Logging Initialized ===
[2025-11-24 14:30:15] [DEBUG] CI_MODE=true, non-interactive, quiet logging
...
[2025-11-24 14:30:45] [OK] All phases completed (30s)
```

### Scenario 4: Verbose Debug Mode

```bash
$ omni run --verbose
[INFO] Loading configuration from bootstrap.conf...
[DEBUG] Found 6 phases in phase-metadata
[DEBUG] Phase 0 (Foundation) has 5 scripts
[DEBUG] Phase 1 (Database) has 4 scripts
[DEBUG] Phase 2 (Infrastructure) has 6 scripts
[DEBUG] Phase 3 (Core Features) has 7 scripts
[DEBUG] Phase 4 (Extensions) has 3 scripts
[DEBUG] Phase 5 (Quality) has 4 scripts
[STEP] Validating environment...
[DEBUG] Checking git: /usr/bin/git (20.0.0)
[DEBUG] Checking node: /usr/bin/node (v20.11.0)
[DEBUG] Checking pnpm: /home/user/.local/bin/pnpm (9.0.0)
[STEP] Checking for missing dependencies...
[DEBUG] Checking docker: Not found
[DEBUG] AUTO_INSTALL_DOCKER=true, attempting installation...
[DEBUG] Detected OS: Linux (ubuntu)
[DEBUG] Running: sudo apt update && sudo apt install -y docker.io
[DEBUG] Docker installed successfully
[OK] All dependencies satisfied
[STEP] Phase 0: Project Foundation...
[DEBUG] Executing 5 scripts in sequence
[STEP] Running: core/00-nextjs.sh
[DEBUG] Setting INSTALL_DIR=/home/luce/apps/bloom2
[DEBUG] Creating package.json
[DEBUG] Command: pnpm install next react react-dom
[DEBUG] Output (first 20 lines):
  added 256 packages in 12s
[OK] core/00-nextjs.sh (12s)
[STEP] Running: foundation/init-typescript.sh
[DEBUG] Command: pnpm add -D typescript @types/node @types/react
[DEBUG] Output:
  added 45 packages in 8s
[OK] foundation/init-typescript.sh (8s)
...
```

### Scenario 5: Error with Auto-Remediation

```bash
$ omni run
[INFO] OmniForge v3.0.0
[STEP] Checking dependencies...
[WARN] pnpm not found
[WARN] docker not found
[STEP] Attempting to remediate missing dependencies...
[STEP] Installing pnpm...
[OK] pnpm installed successfully
[STEP] Installing docker...
[OK] docker installed successfully
[STEP] Phase 0: Project Foundation...
  [OK] core/00-nextjs.sh (12s)
[STEP] Phase 1: Database...
  [OK] db/drizzle-schema-base.sh (5s)
  [STEP] docker-compose-pg.sh
  [ERROR] Failed to create docker-compose.yml: Permission denied
[ERROR] Phase 1 failed at: docker/docker-compose-pg.sh
[WARN] Continuing with remaining phases (PREFLIGHT_SKIP_MISSING=true)
[STEP] Phase 2: Core Features...
  [OK] observability/pino-logger.sh (8s)
[WARN] One or more phases had errors
[INFO] Completed 2 of 3 phases (14/18 scripts)

Log: /home/luce/apps/bloom2/omniforge/logs/omniforge_20251124_143015.log
For full details including errors: cat omniforge/logs/omniforge_20251124_143015.log | grep ERROR
```

---

## Configuration

### Environment Variables

**In bootstrap.conf**:
```bash
# Log directory for OmniForge runs
LOG_DIR="${PROJECT_ROOT}/omniforge/logs"

# Log level: quiet, status (default), verbose
LOG_LEVEL="status"

# Log format: plain (default), json
LOG_FORMAT="plain"

# Auto-rotate logs after this many days
LOG_ROTATE_DAYS="30"

# Auto-cleanup archived logs after this many days
LOG_CLEANUP_DAYS="90"
```

**Override via Environment**:
```bash
# Change log level
export LOG_LEVEL="verbose"
omni run

# Disable logging to file
export LOG_FILE=""
omni run

# Change log directory
export LOG_DIR="/var/log/omniforge"
omni run

# JSON output for parsing
export LOG_FORMAT="json"
omni run
```

### Log Level Quick Reference

| Level | Console | File | Use Case |
|-------|---------|------|----------|
| **quiet** | Errors only | Full | CI/CD, Automated runs |
| **status** | Info, warnings, steps | Full | Local development (default) |
| **verbose** | Everything | Full | Debugging, detailed analysis |

---

## Log Files

### File Format

**Plain Text (Default)**:
```
[YYYY-MM-DD HH:MM:SS] [LEVEL] Message
[2025-11-24 14:30:15] [INFO] Loading configuration
[2025-11-24 14:30:15] [STEP] Checking dependencies
[2025-11-24 14:30:16] [OK] All checks passed
```

**JSON Format** (`LOG_FORMAT=json`):
```json
{"ts":"2025-11-24T14:30:15Z","level":"INFO","script":"omniforge","msg":"Loading configuration"}
{"ts":"2025-11-24T14:30:15Z","level":"STEP","script":"omniforge","msg":"Checking dependencies"}
{"ts":"2025-11-24T14:30:16Z","level":"OK","script":"omniforge","msg":"All checks passed"}
```

### File Naming Convention

- **Normal runs**: `omniforge_YYYYMMDD_HHMMSS.log`
  - Example: `omniforge_20251124_143015.log`

- **Dry-run**: `dry-run_YYYYMMDD_HHMMSS.log`
  - Example: `dry-run_20251124_143000.log`

- **Archived** (> 30 days): Moved to `archive/`
  - Example: `archive/omniforge_20251020_*.log`

### File Retention

- **Current logs**: Kept in `omniforge/logs/`
- **Archived logs**: Kept in `omniforge/logs/archive/` for 90 days
- **Automatic rotation**: After 30 days, logs moved to `archive/`
- **Automatic cleanup**: After 90 days, archived logs deleted

---

## Usage Examples

### View Current Log

```bash
# View latest log
tail -f omniforge/logs/omniforge_*.log

# View with timestamps
tail -f omniforge/logs/omniforge_*.log | grep -E "STEP|ERROR|OK"

# Search for errors
grep ERROR omniforge/logs/omniforge_*.log

# See last 50 lines
tail -50 omniforge/logs/omniforge_*.log
```

### Filter Log Output

```bash
# Show only errors
grep ERROR omniforge/logs/omniforge_*.log

# Show only warnings
grep WARN omniforge/logs/omniforge_*.log

# Show execution timeline
grep -E "STEP|OK" omniforge/logs/omniforge_*.log

# Show just the summary
tail -10 omniforge/logs/omniforge_*.log
```

### Compare Runs

```bash
# Compare two recent runs
diff <(grep "STEP\|OK\|ERROR" omniforge/logs/omniforge_20251124_143015.log) \
     <(grep "STEP\|OK\|ERROR" omniforge/logs/omniforge_20251124_140530.log)

# Show what changed
grep -v "STEP\|OK" omniforge/logs/omniforge_20251124_143015.log
```

### Extract Timing Information

```bash
# Show execution times per script
grep "OK" omniforge/logs/omniforge_*.log | grep -oE '\([0-9]+s\)'

# Calculate total time
grep "completed" omniforge/logs/omniforge_*.log | tail -1
```

---

## Troubleshooting

### Problem: No logs being written

**Symptoms**:
- Log file not created
- Messages appearing on console but not in file

**Diagnosis**:
```bash
# Check if LOG_DIR exists
ls -la omniforge/logs/

# Check if LOG_FILE is set
echo $LOG_FILE

# Check file permissions
ls -la omniforge/
```

**Solutions**:

1. **Create logs directory**:
   ```bash
   mkdir -p omniforge/logs
   chmod 755 omniforge/logs
   ```

2. **Verify LOG_FILE is set**:
   ```bash
   export LOG_FILE="/path/to/omniforge/logs/omniforge_$(date +%Y%m%d_%H%M%S).log"
   omni run
   ```

3. **Check bootstrap.conf**:
   ```bash
   grep LOG_DIR bootstrap.conf
   ```

### Problem: Too much disk space used by logs

**Symptoms**:
- `omniforge/logs/` directory is large
- Running out of disk space

**Solutions**:

1. **Manual cleanup of old logs**:
   ```bash
   # Remove logs older than 30 days
   find omniforge/logs -name "*.log" -mtime +30 -delete

   # Archive old logs
   tar -czf omniforge/logs/archive_$(date +%Y%m%d).tar.gz omniforge/logs/*.log
   ```

2. **Reduce log retention** in bootstrap.conf:
   ```bash
   LOG_CLEANUP_DAYS="30"  # Changed from 90
   ```

3. **Disable file logging** (console only):
   ```bash
   export LOG_FILE=""
   omni run
   ```

### Problem: Can't find specific log entry

**Symptoms**:
- Looking for a specific error or message
- Don't know which log file to check

**Solutions**:

1. **Search all logs**:
   ```bash
   grep -r "search_term" omniforge/logs/
   ```

2. **Find by timestamp**:
   ```bash
   # If you know when something happened
   grep "2025-11-24 14:30" omniforge/logs/*.log
   ```

3. **Find by error message**:
   ```bash
   grep -r "ERROR" omniforge/logs/ | grep "specific_error"
   ```

---

## Best Practices

1. **Check logs after failed runs**:
   ```bash
   omni run || cat omniforge/logs/omniforge_*.log
   ```

2. **Save important logs**:
   ```bash
   cp omniforge/logs/omniforge_*.log backups/
   ```

3. **Archive before git operations**:
   ```bash
   # Don't commit log files
   echo "omniforge/logs/" >> .gitignore
   ```

4. **Monitor long-running deployments**:
   ```bash
   tail -f omniforge/logs/omniforge_*.log
   ```

5. **Combine verbose mode with filtering**:
   ```bash
   omni run --verbose 2>&1 | grep -E "ERROR|WARN|OK"
   ```

---

## Summary

The OmniForge logging system provides:

✅ **Three log levels**: Quiet (errors), Status (default), Verbose (debug)
✅ **Automatic log rotation**: After 30 days, moved to archive
✅ **Automatic cleanup**: After 90 days, deleted
✅ **Console + File**: Console is user-friendly, file is detailed
✅ **Scenario-specific**: Different output for development, dry-run, CI/CD
✅ **Easy filtering**: Search and extract useful information
✅ **Full configuration**: Via bootstrap.conf and environment variables

---

**Document**: LOGGING.md
**Version**: 1.0
**Status**: Production Ready ✅
**Last Updated**: 2025-11-24
