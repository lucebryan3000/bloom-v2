---
id: linux-framework-specific-patterns
topic: linux
file_role: patterns
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: []
related_topics: ['unix', 'shell', 'bash']
embedding_keywords: [linux, patterns, examples, integration]
last_reviewed: 2025-11-13
---

# Framework-Specific Bin Directory Patterns

**Author**: this application Team
**Date**: November 9, 2025
**Version**: 1.0
**Purpose**: Production patterns for script organization, bin wrappers, and command-line tools in the the codebase

---

## Table of Contents

1. [Overview](#overview)
2. [Project Structure](#project-structure)
3. [Script Standards Used in this project](#script-standards-used-in-this project)
4. [Real Script Examples from this project](#real-script-examples-from-this project)
5. [PATH Configuration for Development](#path-configuration-for-development)
6. [Project-Specific Command Patterns](#project-specific-command-patterns)
7. [Next.js Integration](#nextjs-integration)
8. [Docker & Deployment Patterns](#docker--deployment-patterns)
9. [Process Lifecycle Management](#process-lifecycle-management)
10. [Testing & CI/CD](#testing--cicd)
11. [Security Patterns](#security-patterns)
12. [Development Workflow](#development-workflow)
13. [Best Practices Summary](#best-practices-summary)
14. [Troubleshooting](#troubleshooting)

---

## Overview

this project is a Next.js 16 TypeScript application with a sophisticated script organization system. Unlike many projects that scatter scripts across the codebase, this project centralizes all operational scripts in `/path/to/project/scripts/` with project-root wrappers for frequently-used commands.

### Key Principles

- **Centralized scripts directory**: All operational scripts live in `scripts/`
- **Portable shebangs**: Use `#!/usr/bin/env bash` and `#!/usr/bin/env node` for portability
- **Strict error handling**: Bash scripts use `set -euo pipefail`
- **npm script integration**: Scripts are wrapped in `package.json` for discoverability
- **Process lifecycle**: Sophisticated PID tracking and port management
- **Docker-ready**: Entrypoints handle initialization, validation, migrations

### Repository Statistics

```
Total scripts: 25+ executable files
Languages: Bash, Node.js (ESM), Python, TypeScript
Primary port: 3001 (development)
Docker port: 3000 (production)
```

---

## Project Structure

### Directory Layout

```
/path/to/project/
├── scripts/ # Centralized script directory
│ ├── lifecycle/ # Process lifecycle management
│ │ ├── pid-tracker.js # PID file management
│ │ ├── port-manager.js # Port cleanup & allocation
│ │ └── signal-handlers.js # Graceful shutdown handlers
│ ├── archive/ # Deprecated/one-time scripts
│ │   ├── 2025-11/ # Monthly archives
│ │   └── one-time-use/ # One-time scripts (setup-cron.sh, etc.)
│ ├── kb-codex.sh # Knowledge base wrapper
│ ├── dev-server.js # Development server launcher
│ ├── dev-check.js # Health check utility
│ ├── lifecycle-shutdown.js # Shutdown orchestrator
│ ├── validate-build.js # Build validation
│ ├── validate-env.sh # Environment validation
│ ├── deploy.sh # Production deployment
│ ├── migrate-production.sh # Database migration wrapper
│ ├── verify-deployment.sh # Post-deployment checks
│ ├── db-cleanup.ts # Database maintenance
│ ├── filter_logs.py # Log filtering pipeline
│ └── README.md # Script documentation
│
├── kb-codex # Symlink → scripts/kb-codex.sh
├── docker-entrypoint.sh # Production entrypoint
├── docker-entrypoint-dev.sh # Development entrypoint
├── docker-entrypoint-test.sh # Test entrypoint
├── setup.sh # Initial project setup
├── setup-docker.sh # Docker environment setup
└── package.json # npm script wrappers
```

### Rationale for Organization

**Why `scripts/` directory?**
- Centralizes all automation in one place
- Easy to find and maintain
- Clear separation from application code
- Supports both committed scripts and generated helpers

**Why root-level symlinks?**
- Frequently-used commands accessible from project root
- Discoverable (developers expect `./script-name` pattern)
- No PATH modification needed

**Why `lifecycle/` subdirectory?**
- Groups related modules (PID tracking, port management, signals)
- Imported by multiple scripts (dev-server.js, lifecycle-shutdown.js)
- Clean separation of concerns

---

## Script Standards Used in this project

### Portable Shebangs

✅ **Correct - Used in this project:**

```bash
#!/usr/bin/env bash
```

```javascript
#!/usr/bin/env node
```

❌ **Avoid - Not portable:**

```bash
#!/bin/bash # Fails if bash is in /usr/local/bin
```

```javascript
#!/usr/local/bin/node # Hardcoded path breaks on different systems
```

**Why**: `env` searches PATH for the interpreter, making scripts work across:
- Different Linux distributions (Debian, Arch, RHEL)
- macOS (Homebrew vs system installations)
- NVM/nvm-managed Node.js versions
- WSL and native Windows Git Bash

### Error Handling in Bash

**Standard this project pattern:**

```bash
#!/usr/bin/env bash
set -euo pipefail

# -e: Exit on any error
# -u: Exit on undefined variable
# -o pipefail: Exit if any command in a pipeline fails
```

**Example from `scripts/kb-codex.sh`:**

```bash
#!/usr/bin/env bash
set -euo pipefail

if [[ $# -eq 0 ]]; then
 cat <<'USAGE' >&2
Usage: kb-codex <topic keywords> [<authoritative-url>...] [-- <extras>]
Examples:
 kb-codex openai codex
 kb-codex sqlite replication -- quick-reference only

This wraps the Codex CLI so you can run the kb command defined in.codex/commands/kb*.md
from anywhere inside the the repository.
USAGE
 exit 1
fi

ROOT_DIR=$(git rev-parse --show-toplevel 2>/dev/null || true)
if [[ -z "${ROOT_DIR}" ]]; then
 echo "kb-codex must be run inside the the repository" >&2
 exit 1
fi

CODEX_DIR="$ROOT_DIR/docs/kb"
COMMAND_NAME=""
for candidate in kb kb-codex; do
 if [[ -f "$CODEX_DIR/.codex/commands/$candidate.md" ]]; then
 COMMAND_NAME="$candidate"
 break
 fi
done

if [[ -z "$COMMAND_NAME" ]]; then
 echo "Could not find kb*.md under $CODEX_DIR/.codex/commands" >&2
 exit 1
fi

COMMAND_PROMPT="$COMMAND_NAME"
if [[ $# -gt 0 ]]; then
 COMMAND_PROMPT+=" $*"
fi

exec codex -C "$CODEX_DIR" -- "$COMMAND_PROMPT"
```

**Key patterns demonstrated:**
- Heredoc for multi-line usage messages
- Exit 1 on error conditions
- Output to stderr with `>&2`
- Safe variable expansion with `${VAR}`
- Git root detection for repository-aware scripts
- `exec` to replace shell process (saves memory)

### Usage Messages

**Pattern used in this project:**

```bash
if [[ $# -eq 0 ]]; then
 cat <<'USAGE' >&2
Usage: script-name <required-arg> [optional-arg]

Description of what the script does.

Examples:
 script-name foo
 script-name foo --option bar

Options:
 --help Show this help message
 --dry-run Simulate actions without changes
USAGE
 exit 1
fi
```

**Benefits:**
- Heredoc keeps formatting clean
- Redirecting to stderr (`>&2`) preserves stdout for data
- Examples show real-world usage
- Self-documenting code

### Git Root Detection

**Pattern from `kb-codex.sh`:**

```bash
ROOT_DIR=$(git rev-parse --show-toplevel 2>/dev/null || true)
if [[ -z "${ROOT_DIR}" ]]; then
 echo "Script must be run inside the repository" >&2
 exit 1
fi
```

**Why this works:**
- `git rev-parse --show-toplevel` returns absolute path to repo root
- `2>/dev/null` suppresses error messages
- `|| true` prevents exit on error (because of `set -e`)
- Test `[[ -z "${ROOT_DIR}" ]]` checks for empty string
- Scripts work from any subdirectory

**Usage:**

```bash
cd /path/to/project/components/ui
kb-codex sqlite indexes # Works! Finds repo root automatically
```

---

## Real Script Examples from this project

### Example 1: kb-codex.sh - Knowledge Base Wrapper

**File**: `/path/to/project/scripts/kb-codex.sh`
**Purpose**: Wrapper for Codex CLI to search knowledge base from anywhere in repo
**Size**: 51 lines

```bash
#!/usr/bin/env bash
set -euo pipefail

if [[ $# -eq 0 ]]; then
 cat <<'USAGE' >&2
Usage: kb-codex <topic keywords> [<authoritative-url>...] [-- <extras>]
Examples:
 kb-codex openai codex
 kb-codex sqlite replication -- quick-reference only

This wraps the Codex CLI so you can run the kb command defined in.codex/commands/kb*.md
from anywhere inside the the repository.
USAGE
 exit 1
fi

ROOT_DIR=$(git rev-parse --show-toplevel 2>/dev/null || true)
if [[ -z "${ROOT_DIR}" ]]; then
 echo "kb-codex must be run inside the the repository" >&2
 exit 1
fi

CODEX_DIR="$ROOT_DIR/docs/kb"

# Detect whichever kb command file exists (kb.md or kb-codex.md)
COMMAND_NAME=""
for candidate in kb kb-codex; do
 if [[ -f "$CODEX_DIR/.codex/commands/$candidate.md" ]]; then
 COMMAND_NAME="$candidate"
 break
 fi
done

if [[ -z "$COMMAND_NAME" ]]; then
 echo "Could not find kb*.md under $CODEX_DIR/.codex/commands" >&2
 exit 1
fi

COMMAND_PROMPT="$COMMAND_NAME"
if [[ $# -gt 0 ]]; then
 COMMAND_PROMPT+=" $*"
fi

echo "Starting Codex in $CODEX_DIR"
echo "Running command: $COMMAND_PROMPT"
echo "(press Ctrl+D or type /exit when you're done)"
echo

exec codex -C "$CODEX_DIR" -- "$COMMAND_PROMPT"
```

**Patterns demonstrated:**
- ✅ Portable shebang (`#!/usr/bin/env bash`)
- ✅ Strict error handling (`set -euo pipefail`)
- ✅ Usage message with heredoc
- ✅ Git root detection
- ✅ Directory existence validation
- ✅ User feedback before execution
- ✅ `exec` to replace shell process

**How to use:**

```bash
# From anywhere in the repo:
cd /path/to/project/app/api
kb-codex linux bin directories

# Or use the symlink:
cd /path/to/project
./kb-codex sqlite optimization
```

---

### Example 2: validate-build.js - Next.js Build Validation

**File**: `/path/to/project/scripts/validate-build.js`
**Purpose**: Validate Next.js build output before deployment
**Size**: 102 lines
**Language**: Node.js (ESM)

```javascript
#!/usr/bin/env node

// Auto-generated by Claude per Instruction Set v2
// Source: this application [PRD v10](_build/PRD-Bloom/Bloom-PRD-v10-MVP-v1.0.md)

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

console.log('🔍 Validating Next.js build...\n');

let hasErrors = false;

// Check 1: Verify.next directory exists
const nextDir = path.join(__dirname, '../.next');
if (!fs.existsSync(nextDir)) {
 console.error('❌.next directory not found! Build may have failed.');
 hasErrors = true;
} else {
 console.log('✅.next directory exists');
}

// Check 2: Verify CSS files exist
const cssDir = path.join(nextDir, 'static/css');
if (!fs.existsSync(cssDir)) {
 console.error('❌ CSS directory not found!');
 hasErrors = true;
} else {
 const cssFiles = fs.readdirSync(cssDir).filter(f => f.endsWith('.css'));
 if (cssFiles.length === 0) {
 console.error('❌ No CSS files found in build!');
 hasErrors = true;
 } else {
 console.log(`✅ Found ${cssFiles.length} CSS file(s):`);
 cssFiles.forEach(file => {
 const filePath = path.join(cssDir, file);
 const stats = fs.statSync(filePath);
 const sizeKB = (stats.size / 1024).toFixed(2);
 console.log(` - ${file} (${sizeKB} KB)`);

 // Warn if CSS is suspiciously small
 if (stats.size < 1000) {
 console.warn(` ⚠️ Warning: ${file} is very small (${stats.size} bytes)`);
 }
 });
 }
}

// Check 3: Verify static chunks exist
const chunksDir = path.join(nextDir, 'static/chunks');
if (!fs.existsSync(chunksDir)) {
 console.error('❌ Chunks directory not found!');
 hasErrors = true;
} else {
 const chunkFiles = fs.readdirSync(chunksDir).filter(f => f.endsWith('.js'));
 console.log(`✅ Found ${chunkFiles.length} JavaScript chunk(s)`);
}

// Check 4: Verify globals.css was processed
const globalsPattern = /app-.*\.css$/;
if (fs.existsSync(cssDir)) {
 const cssFiles = fs.readdirSync(cssDir);
 const hasAppCSS = cssFiles.some(f => globalsPattern.test(f));

 if (!hasAppCSS) {
 console.warn('⚠️ No app-*.css file found. globals.css may not have been processed.');
 } else {
 console.log('✅ globals.css appears to be processed');
 }
}

// Check 5: Verify build manifest exists
const buildManifest = path.join(nextDir, 'build-manifest.json');
if (!fs.existsSync(buildManifest)) {
 console.error('❌ build-manifest.json not found!');
 hasErrors = true;
} else {
 console.log('✅ build-manifest.json exists');

 try {
 const manifest = JSON.parse(fs.readFileSync(buildManifest, 'utf8'));
 const pages = Object.keys(manifest.pages || {});
 console.log(` Pages in manifest: ${pages.length}`);
 } catch (error) {
 console.error('❌ Error parsing build-manifest.json:', error.message);
 hasErrors = true;
 }
}

console.log('\n' + '='.repeat(50));

if (hasErrors) {
 console.error('❌ Build validation FAILED\n');
 process.exit(1);
} else {
 console.log('✅ Build validation PASSED\n');
 process.exit(0);
}
```

**Patterns demonstrated:**
- ✅ Portable Node.js shebang
- ✅ ESM imports (using `import`, not `require`)
- ✅ `__dirname` equivalent for ESM
- ✅ Comprehensive validation checks
- ✅ User-friendly output with emojis
- ✅ Early exit on fatal errors
- ✅ Warnings for non-fatal issues
- ✅ Exit codes (0 = success, 1 = failure)

**Integration with build pipeline:**

```json
// package.json
{
 "scripts": {
 "build": "next build 2>&1 | tee logs/build.log && npm run validate-build",
 "validate-build": "node scripts/validate-build.js"
 }
}
```

**CI/CD usage:**

```bash
npm run build
# Build runs, then validation
# If validation fails, exit code 1 stops CI pipeline
```

---

### Example 3: docker-entrypoint.sh - Production Container Initialization

**File**: `/path/to/project/docker-entrypoint.sh`
**Purpose**: Production container startup with validation, migrations, signal handling
**Size**: 112 lines

```bash
#!/bin/sh
# Auto-generated by Claude per Instruction Set v2
# Production entrypoint for this application

set -e

echo "🚀 Starting this application production container..."

# Function to wait for database
wait_for_db {
 echo "⏳ Waiting for database to be ready..."

 # Extract database host and port from DATABASE_URL if using PostgreSQL
 if echo "$DATABASE_URL" | grep -q "postgresql://"; then
 DB_HOST=$(echo "$DATABASE_URL" | sed -n 's/.*@\([^:]*\):.*/\1/p')
 DB_PORT=$(echo "$DATABASE_URL" | sed -n 's/.*:\([0-9]*\)\/.*/\1/p')

 max_attempts=30
 attempt=0

 while [ $attempt -lt $max_attempts ]; do
 if nc -z "$DB_HOST" "$DB_PORT" 2>/dev/null; then
 echo "✅ Database is ready"
 return 0
 fi

 attempt=$((attempt + 1))
 echo " Attempt $attempt/$max_attempts - Database not ready yet..."
 sleep 2
 done

 echo "❌ Database failed to become ready after $max_attempts attempts"
 exit 1
 else
 # SQLite doesn't need connection waiting
 echo "✅ Using SQLite - skipping connection check"
 fi
}

# Function to validate required environment variables
validate_env {
 echo "🔍 Validating environment variables..."

 required_vars="DATABASE_URL NEXTAUTH_SECRET ANTHROPIC_API_KEY"
 missing_vars=""

 for var in $required_vars; do
 if ! eval "[ -n \"\${$var}\" ]"; then
 missing_vars="$missing_vars $var"
 fi
 done

 if [ -n "$missing_vars" ]; then
 echo "❌ Missing required environment variables:$missing_vars"
 exit 1
 fi

 echo "✅ All required environment variables present"
}

# Function to run database migrations
run_migrations {
 echo "🔄 Running Prisma migrations..."

 if npx prisma migrate deploy; then
 echo "✅ Migrations completed successfully"
 else
 echo "❌ Migration failed"
 exit 1
 fi
}

# Function to optionally seed database
seed_database {
 if [ "$RUN_SEED" = "true" ]; then
 echo "🌱 Seeding database..."

 if npx prisma db seed; then
 echo "✅ Database seeded successfully"
 else
 echo "⚠️ Seed failed (continuing anyway)"
 fi
 fi
}

# Function to handle shutdown
shutdown {
 echo "🛑 Received shutdown signal, cleaning up..."
 kill -TERM "$child" 2>/dev/null
 wait "$child"
 echo "✅ Shutdown complete"
 exit 0
}

# Trap signals for graceful shutdown
trap shutdown TERM INT

# Main execution
validate_env
wait_for_db
run_migrations
seed_database

echo "✅ Initialization complete, starting application..."
echo ""

# Execute the main command
exec "$@" &

child=$!
wait "$child"
```

**Patterns demonstrated:**
- ✅ POSIX shell (`#!/bin/sh` for minimal Docker images)
- ✅ Function-based organization
- ✅ Database connection retry logic
- ✅ Environment variable validation
- ✅ Database migrations before app start
- ✅ Graceful shutdown with signal traps
- ✅ Background process management (`exec "$@" &`)
- ✅ Exit codes for container orchestration

**Docker integration:**

```dockerfile
# Dockerfile.production
FROM node:20-alpine

WORKDIR /app
COPY..

RUN npm ci --only=production
RUN npm run build

ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["npm", "start"]
```

**Usage:**

```bash
docker run -e DATABASE_URL="postgresql://..." \
 -e ANTHROPIC_API_KEY="sk-ant-..." \
 -e NEXTAUTH_SECRET="..." \
 -this project
```

---

### Example 4: dev-server.js - Development Server Lifecycle Manager

**File**: `/path/to/project/scripts/dev-server.js`
**Purpose**: Smart dev server launcher with port cleanup and PID tracking
**Size**: 120 lines

```javascript
#!/usr/bin/env node
// Auto-generated by Claude per Instruction Set v2
// Source: Process Lifecycle Management System Design

import { spawn } from 'child_process';
import { PIDTracker } from './lifecycle/pid-tracker.js';
import { PortManager } from './lifecycle/port-manager.js';
import { SignalHandler } from './lifecycle/signal-handlers.js';

const PORT = parseInt(process.env.DEV_PORT || '3001', 10);
const NODE_OPTIONS = process.env.NODE_OPTIONS || '--max-old-space-size=4096 --enable-source-maps';
const DEBUG = process.env.DEBUG || 'this project:*,prisma:*';

const pidTracker = new PIDTracker;
const portManager = new PortManager;
const signalHandler = new SignalHandler;

async function prestart {
 console.log(`🔍 Pre-startup checks for port ${PORT}...`);

 // 1. Clean stale PID files
 const cleaned = await pidTracker.cleanStale;
 if (cleaned > 0) {
 console.log(`✅ Cleaned ${cleaned} stale PID file(s)`);
 }

 // 2. Check if port is in use
 const inUse = await portManager.isPortInUse(PORT);
 if (!inUse) {
 console.log(`✅ Port ${PORT} is free`);
 return;
 }

 // 3. Port in use - identify owner
 const ownerPid = await portManager.getPortOwner(PORT);
 const portInfo = await portManager.getPortInfo(PORT);
 console.warn(`⚠️ Port ${PORT} in use by PID ${ownerPid} (${portInfo.command || 'unknown'})`);

 // 4. Check if it's our process
 const pidFile = await pidTracker.read(PORT);
 if (pidFile && pidFile.pid === ownerPid) {
 console.log(`🔄 Existing dev server found, shutting down...`);
 try {
 process.kill(ownerPid, 'SIGTERM');
 const freed = await portManager.waitForPortFree(PORT, 5000);
 if (!freed) {
 console.warn(`⚠️ Graceful shutdown timeout, forcing...`);
 await portManager.forceFrePort(PORT);
 }
 } catch (err) {
 console.error(`❌ Error shutting down existing server:`, err.message);
 await portManager.forceFrePort(PORT);
 }
 await pidTracker.remove(PORT);
 } else {
 console.warn(`⚠️ Unknown process on port ${PORT}, force-freeing...`);
 await portManager.forceFrePort(PORT);
 }

 // 5. Verify port is now free
 const isFree = await portManager.waitForPortFree(PORT, 10000);
 if (!isFree) {
 throw new Error(`Failed to free port ${PORT} after 10s`);
 }

 console.log(`✅ Port ${PORT} ready for startup`);
}

async function startServer {
 try {
 // Pre-startup cleanup
 await prestart;

 console.log(`🚀 Starting Next.js dev server on port ${PORT}...`);

 // Start Next.js
 const nextDev = spawn('next', ['dev', '-p', PORT.toString], {
 stdio: 'inherit',
 env: {
...process.env,
 NODE_OPTIONS,
 DEBUG,
 },
 });

 // Wait a bit for Next.js to start
 await new Promise(resolve => setTimeout(resolve, 2000));

 // Post-startup: Write PID file
 await pidTracker.write(PORT, nextDev.pid);
 console.log(`✅ Server started (PID ${nextDev.pid})`);

 // Register signal handlers
 signalHandler.register(PORT, nextDev);

 // Handle Next.js exit
 nextDev.on('exit', async (code, signal) => {
 console.log(`\n📋 Next.js exited with code ${code} (signal: ${signal || 'none'})`);
 await pidTracker.remove(PORT);

 if (!signalHandler.shutdownInProgress) {
 process.exit(code || 0);
 }
 });

 nextDev.on('error', async (err) => {
 console.error('❌ Next.js process error:', err);
 await pidTracker.remove(PORT);
 process.exit(1);
 });

 } catch (err) {
 console.error('❌ Startup failed:', err.message);
 process.exit(1);
 }
}

// Start the server
startServer;
```

**Patterns demonstrated:**
- ✅ Sophisticated port conflict resolution
- ✅ PID tracking for process management
- ✅ Graceful shutdown handling
- ✅ Pre-startup validation
- ✅ Environment variable configuration
- ✅ Child process spawning with `spawn`
- ✅ Event-driven cleanup on exit

**Integration with npm:**

```json
{
 "scripts": {
 "dev": "node scripts/dev-server.js 2>&1 | tee logs/dev.raw.log | python3 scripts/filter_logs.py | tee logs/dev.clean.log",
 "dev:simple": "node scripts/dev-server.js"
 }
}
```

---

## PATH Configuration for Development

### Adding Project Scripts to PATH

**Option 1: Per-session (recommended for development)**

```bash
# Add to current session
export PATH="/path/to/project/scripts:$PATH"

# Now you can run:
kb-codex.sh sqlite optimization
dev-check.js
```

**Option 2: Permanent (via shell profile)**

```bash
# Add to ~/.bashrc or ~/.zshrc
export PATH="$HOME/apps/app/scripts:$PATH"
```

**Option 3: Project-specific (direnv)**

```bash
# Install direnv
sudo apt install direnv # Debian/Ubuntu
brew install direnv # macOS

# Add to ~/.bashrc
eval "$(direnv hook bash)"

# Create.envrc in project root
echo 'PATH_add scripts' > /path/to/project/.envrc
direnv allow

# Now PATH is auto-updated when you cd into the project
cd /path/to/project # PATH updated automatically
cd ~ # PATH restored
```

### npm Scripts as Command Wrappers

**the project's pattern: Wrap scripts in package.json**

```json
{
 "scripts": {
 "dev": "node scripts/dev-server.js...",
 "dev:kill": "node scripts/lifecycle-shutdown.js 3001",
 "dev:check": "node scripts/dev-check.js",
 "validate-build": "node scripts/validate-build.js"
 }
}
```

**Benefits:**
- Scripts discoverable via `npm run`
- No PATH modification needed
- Self-documenting (`npm run` lists all commands)
- Cross-platform (works on Windows, macOS, Linux)
- Version control committed

**Usage:**

```bash
npm run dev # Start dev server
npm run dev:check # Check server health
npm run dev:kill # Shutdown server
```

---

## Project-Specific Command Patterns

### Pattern 1: Wrapper Scripts for Complex Operations

**Example: kb-codex wrapper**

```bash
#!/usr/bin/env bash
set -euo pipefail

# Detect repository root
ROOT_DIR=$(git rev-parse --show-toplevel 2>/dev/null || true)

# Validate environment
if [[ -z "${ROOT_DIR}" ]]; then
 echo "Must be run inside repository" >&2
 exit 1
fi

# Discover kb command file (kb.md or kb-codex.md) and delegate
KB_DIR="$ROOT_DIR/docs/kb"
COMMAND_NAME=""
for candidate in kb kb-codex; do
 if [[ -f "$KB_DIR/.codex/commands/$candidate.md" ]]; then
 COMMAND_NAME="$candidate"
 break
 fi
done

if [[ -z "$COMMAND_NAME" ]]; then
 echo "Missing kb command file under $KB_DIR/.codex/commands" >&2
 exit 1
fi

COMMAND_PROMPT="$COMMAND_NAME"
if [[ $# -gt 0 ]]; then
 COMMAND_PROMPT+=" $*"
fi

exec codex -C "$KB_DIR" -- "$COMMAND_PROMPT"
```

**When to use this pattern:**
- Tool requires specific working directory
- Need to pass computed arguments
- Validation before delegation

### Pattern 2: Environment Validation

**Example: scripts/validate-env.sh**

```bash
#!/bin/bash
set -e

VALIDATION_FAILED=0

check_var {
 local var_name=$1
 local is_required=$2

 if [ -z "${!var_name}" ]; then
 if [ "$is_required" = "true" ]; then
 echo "✗ $var_name is REQUIRED but not set"
 VALIDATION_FAILED=1
 else
 echo "⚠ $var_name is optional and not set"
 fi
 else
 echo "✓ $var_name is set"
 fi
}

check_var "DATABASE_URL" true
check_var "ANTHROPIC_API_KEY" true
check_var "NEXTAUTH_SECRET" true

if [ $VALIDATION_FAILED -eq 1 ]; then
 echo "❌ Validation FAILED"
 exit 1
else
 echo "✅ All validations PASSED"
fi
```

**When to use:**
- Before Docker startup
- Before production deployment
- CI/CD pipelines
- Developer onboarding

### Pattern 3: Database Migration Helpers

**Example: scripts/migrate-production.sh**

```bash
#!/bin/bash
set -e

echo "🔄 Running production migrations..."

# Backup first (if using PostgreSQL)
if echo "$DATABASE_URL" | grep -q "postgresql://"; then
 BACKUP_FILE="backup-$(date +%Y%m%d-%H%M%S).sql"
 echo "📦 Creating backup: $BACKUP_FILE"
 pg_dump "$DATABASE_URL" > "$BACKUP_FILE"
fi

# Run migrations
npx prisma migrate deploy

echo "✅ Migrations complete"
```

**Safety features:**
- Automatic backups before migration
- Exit on error (`set -e`)
- User feedback
- Timestamp-based backup names

### Pattern 4: Deployment Scripts

**Example: scripts/deploy.sh** (simplified)

```bash
#!/bin/bash
set -e

PROJECT_NAME="-this project"
REGISTRY="ghcr.io/"
VERSION=$(grep '"version"' package.json | grep -oP '(?<="version": ")[^"]*')
IMAGE="${REGISTRY}/${PROJECT_NAME}:${VERSION}"

log {
 echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Pre-deployment checks
log "Running pre-deployment checks..."
required_vars=("DATABASE_URL" "ANTHROPIC_API_KEY" "NEXT_PUBLIC_APP_URL")
for var in "${required_vars[@]}"; do
 if [ -z "${!var}" ]; then
 echo "❌ Missing: $var" >&2
 exit 1
 fi
done

# Build
log "Building Docker image..."
docker build -f Dockerfile.production -t "$IMAGE".

# Push
log "Pushing to registry..."
docker push "$IMAGE"

# Migrate
log "Running migrations..."
docker run --rm --env-file.env.production "$IMAGE" npx prisma migrate deploy

# Health check
log "Waiting for health check..."
for i in {1..30}; do
 if curl -f http://localhost:3000/api/health > /dev/null 2>&1; then
 log "✅ Application healthy"
 break
 fi
 sleep 10
done

log "✅ Deployment complete!"
```

**Production-ready features:**
- Timestamped logging
- Environment validation
- Docker image versioning
- Automated health checks
- Retry logic

---

## Next.js Integration

### npm Scripts as Commands

**the project's complete npm scripts:**

```json
{
 "scripts": {
 // Development
 "dev": "node scripts/dev-server.js 2>&1 | tee logs/dev.raw.log | python3 scripts/filter_logs.py",
 "dev:simple": "node scripts/dev-server.js",
 "dev:direct": "NODE_OPTIONS='--max-old-space-size=4096' next dev -p 3001",
 "dev:debug": "DEBUG='*' node scripts/dev-server.js...",
 "dev:kill": "node scripts/lifecycle-shutdown.js 3001",
 "dev:clean": "node scripts/lifecycle-shutdown.js --all",
 "dev:check": "node scripts/dev-check.js",

 // Build & Production
 "build": "next build && npm run validate-build",
 "validate-build": "node scripts/validate-build.js",
 "start": "next start | python3 scripts/filter_logs.py",

 // Database
 "db:migrate": "prisma migrate dev",
 "db:migrate:deploy": "prisma migrate deploy",
 "db:studio": "prisma studio",

 // Testing
 "test": "jest",
 "test:integration": "npm run dev:clean && playwright test integration/",

 // Logs
 "logs:clean": "rm -rf logs/*.log",
 "logs:tail": "tail -f logs/dev.clean.log",
 "logs:errors": "grep -E 'error|warn' logs/dev.clean.log | jq"
 }
}
```

### Custom Dev Server Wrappers

**Why wrap `next dev`?**

1. **Port conflict resolution** - Auto-kill stale processes
2. **Memory limits** - Set `NODE_OPTIONS=--max-old-space-size=4096`
3. **Log filtering** - Pipe through Python script to remove noise
4. **PID tracking** - Track process for clean shutdown
5. **Health monitoring** - Enable metrics endpoint

**Evolution of dev command:**

```bash
# Basic
next dev

# With port
next dev -p 3001

# With memory limit
NODE_OPTIONS='--max-old-space-size=4096' next dev -p 3001

# With logging (the project's approach)
node scripts/dev-server.js 2>&1 | tee logs/dev.raw.log | python3 scripts/filter_logs.py
```

### Build Validation

**Integration pattern:**

```json
{
 "scripts": {
 "build": "next build 2>&1 | tee logs/build.log && npm run validate-build",
 "validate-build": "node scripts/validate-build.js"
 }
}
```

**What validation checks:**
- `.next/` directory exists
- CSS files compiled
- JavaScript chunks generated
- Build manifest valid
- No suspiciously small files (indicates build failure)

**CI/CD integration:**

```yaml
#.github/workflows/ci.yml
- name: Build application
 run: npm run build # Includes validation

- name: Upload build artifacts
 if: success
 uses: actions/upload-artifact@v3
 with:
 name: next-build
 path:.next/
```

---

## Docker & Deployment Patterns

### Entrypoint Best Practices

**Three entrypoints for three environments:**

1. **docker-entrypoint.sh** - Production
2. **docker-entrypoint-dev.sh** - Development
3. **docker-entrypoint-test.sh** - Testing

**Production entrypoint structure:**

```bash
#!/bin/sh
set -e

# Functions
wait_for_db {... }
validate_env {... }
run_migrations {... }
shutdown {... }

# Traps
trap shutdown TERM INT

# Main execution
validate_env
wait_for_db
run_migrations

exec "$@" &
child=$!
wait "$child"
```

### Signal Handling

**Why it matters:**
- Docker sends `SIGTERM` for graceful shutdown
- Kubernetes sends `SIGTERM` before `SIGKILL` (grace period)
- Without handling, containers stop abruptly

**the project's pattern:**

```bash
shutdown {
 echo "🛑 Received shutdown signal, cleaning up..."
 kill -TERM "$child" 2>/dev/null # Forward to child process
 wait "$child" # Wait for clean exit
 echo "✅ Shutdown complete"
 exit 0
}

trap shutdown TERM INT

# Start app in background
exec "$@" &
child=$!
wait "$child"
```

**Benefits:**
- Database connections closed gracefully
- In-flight requests completed
- Temporary files cleaned up
- Exit code preserved

### Graceful Shutdown

**Node.js signal handling in scripts/lifecycle/signal-handlers.js:**

```javascript
export class SignalHandler {
 register(port, serverProcess = null) {
 const handler = async (signal) => {
 console.log(`\n📨 Received ${signal}`);
 await this.shutdown(port, serverProcess);
 };

 process.on('SIGTERM', handler);
 process.on('SIGINT', handler);
 process.on('SIGHUP', handler);
 }

 async shutdown(port, serverProcess = null, isError = false) {
 if (this.shutdownInProgress) return;
 this.shutdownInProgress = true;

 console.log(`🛑 Graceful shutdown initiated for port ${port}...`);

 // Timeout for forced shutdown
 const forceTimer = setTimeout( => {
 console.warn('⏰ Shutdown timeout - forcing kill');
 this.forceShutdown(port, serverProcess);
 }, this.shutdownTimeout);

 try {
 // 1. Execute shutdown callbacks
 for (const callback of this.shutdownCallbacks) {
 await callback;
 }

 // 2. Kill server process
 if (serverProcess?.pid) {
 process.kill(serverProcess.pid, 'SIGTERM');
 await sleep(1000);
 }

 // 3. Remove PID file
 await this.pidTracker.remove(port);

 clearTimeout(forceTimer);
 process.exit(isError ? 1: 0);
 } catch (err) {
 clearTimeout(forceTimer);
 this.forceShutdown(port, serverProcess);
 }
 }
}
```

**Shutdown sequence:**
1. Receive signal (SIGTERM/SIGINT)
2. Execute registered callbacks (close DB, flush logs, etc.)
3. Send SIGTERM to child process
4. Wait up to 5 seconds for graceful exit
5. Force kill if timeout exceeded
6. Clean up PID files
7. Exit with appropriate code

---

## Process Lifecycle Management

### PID Tracking System

**File**: `scripts/lifecycle/pid-tracker.js`

**PID file format:**

```json
{
 "pid": 1234567,
 "port": 3001,
 "started": "2025-11-09T12:34:56.789Z",
 "nodePath": "/usr/bin/node",
 "cwd": "/path/to/project",
 "hostname": "luce-dev-machine"
}
```

**Key methods:**

```javascript
// Write PID file atomically
await pidTracker.write(port, pid);

// Read PID file (returns null if invalid)
const pidFile = await pidTracker.read(port);

// Verify process is still running
const isValid = await pidTracker.verify(pidFile);

// Remove PID file
await pidTracker.remove(port);

// Clean all stale PID files
const cleaned = await pidTracker.cleanStale;
```

**Verification checks:**

1. ✅ Process exists (`kill(pid, 0)`)
2. ✅ Process is Next.js (`/proc/<pid>/cmdline` contains 'next')
3. ✅ Node.js version matches (detect nvm switches)
4. ✅ Hostname matches (detect VM/WSL switches)
5. ✅ Working directory matches

**Why so thorough?**
- Prevents killing wrong process
- Handles nvm version switches
- Detects WSL/VM environment changes
- Avoids "port in use" false positives

### Port Management System

**File**: `scripts/lifecycle/port-manager.js`

**Key operations:**

```javascript
// Check if port is in use
const inUse = await portManager.isPortInUse(3001);

// Get PID of process using port
const pid = await portManager.getPortOwner(3001);

// Get process info (command, user, etc.)
const info = await portManager.getPortInfo(3001);

// Wait for port to become free (with timeout)
const freed = await portManager.waitForPortFree(3001, 5000);

// Force-free port (SIGTERM → SIGKILL)
await portManager.forceFrePort(3001);
```

**Port conflict resolution:**

```
1. Check if port 3001 is in use
 ↓ YES
2. Get PID of owner
 ↓
3. Read PID file for port 3001
 ↓
4. Does PID file match owner?
 ↓ YES (our old process)
5. Send SIGTERM
 ↓
6. Wait 5s for graceful shutdown
 ↓
7. Still running?
 ↓ YES
8. Send SIGKILL
 ↓
9. Verify port is free
 ↓
10. Start new server
```

### Lifecycle Scripts

**scripts/dev-server.js** - Start server with cleanup

```bash
npm run dev
# 1. Clean stale PID files
# 2. Check if port 3001 in use
# 3. If yes, kill old process
# 4. Start Next.js dev server
# 5. Write PID file
# 6. Register signal handlers
```

**scripts/lifecycle-shutdown.js** - Stop server gracefully

```bash
npm run dev:kill # Kill server on port 3001
npm run dev:kill 3002 # Kill server on port 3002
npm run dev:clean # Kill all dev servers (3000-3003)
```

---

## Testing & CI/CD

### Test Runner Scripts

**Pattern: Cleanup before tests**

```json
{
 "scripts": {
 "test:integration": "npm run dev:clean && playwright test integration/",
 "test:e2e": "npm run dev:clean && playwright test"
 }
}
```

**Why cleanup first:**
- Ensures clean state
- Prevents port conflicts
- Kills old test servers
- Reproducible test runs

### Validation Scripts

**scripts/dev-check.js** - Health check

```bash
npm run dev:check

# Output:
# ═══════════════════════════════════════════════════
# 📊 this project Dev Server Health Check
# ═══════════════════════════════════════════════════
#
# Memory Usage:
# ✅ RSS: 2456 MB / 4096 MB
# Heap Used: 1234 MB
# Heap Total: 1567 MB
# ✅ Heap Pressure: 78.7%
#
# Server Uptime:
# ✅ Uptime: 2h 34m
# PID: 1234567
# Node: v20.9.0
#
# Alert Status:
# ✅ Healthy - No issues detected
```

**Exit codes:**
- `0` - Healthy
- `1` - Warning (memory > 3GB)
- `2` - Critical (memory > 4GB or uptime > 12h)

**CI integration:**

```yaml
- name: Health check
 run: npm run dev:check
 continue-on-error: true

- name: Restart if unhealthy
 if: failure
 run: npm run dev:kill && npm run dev
```

### Pre-commit Hooks Potential

**Not yet implemented in this project, but recommended:**

```bash
#.husky/pre-commit
#!/bin/sh
. "$(dirname "$0")/_/husky.sh"

npm run lint
npm run type-check
npm run test:unit
```

**Setup:**

```bash
npm install --save-dev husky
npx husky install
npx husky add.husky/pre-commit "npm run lint && npm run type-check"
```

---

## Security Patterns

### Permission Handling

**Scripts should be executable:**

```bash
chmod +x scripts/kb-codex.sh
chmod +x scripts/validate-build.js
```

**Verify:**

```bash
ls -la scripts/

# Should show:
# -rwxrwxr-x kb-codex.sh
# -rwxrwxr-x validate-build.js
```

**Git preserves permissions:**

```bash
git add scripts/kb-codex.sh
git commit -m "Add executable script"
# Permissions preserved in repo
```

### Environment Variable Validation

**Pattern: Never trust environment**

```bash
# ❌ BAD - No validation
DATABASE_URL=$DATABASE_URL npx prisma migrate deploy

# ✅ GOOD - Validate first
if [ -z "$DATABASE_URL" ]; then
 echo "❌ DATABASE_URL not set" >&2
 exit 1
fi

npx prisma migrate deploy
```

**the project's validation script:**

```bash
scripts/validate-env.sh

# Checks:
# - DATABASE_URL exists
# - NEXTAUTH_SECRET exists AND length >= 32
# - ANTHROPIC_API_KEY exists
# - Warns about optional vars (REDIS_URL, etc.)
```

### Safe Defaults

**Pattern: Fail securely**

```bash
# ❌ BAD - Defaults to production
ENVIRONMENT=${ENVIRONMENT:-production}

# ✅ GOOD - Defaults to development
ENVIRONMENT=${ENVIRONMENT:-development}

# ✅ BETTER - Require explicit setting
if [ -z "$ENVIRONMENT" ]; then
 echo "❌ ENVIRONMENT must be set explicitly" >&2
 exit 1
fi
```

### Secret Handling

**Never commit secrets:**

```bash
# ❌ BAD
export ANTHROPIC_API_KEY="sk-ant-api03-..."

# ✅ GOOD - Load from.env
set -a
source.env.local
set +a
```

**.gitignore patterns:**

```gitignore
.env.local
.env.production
.env.*.local
*.pem
*.key
credentials.json
```

---

## Development Workflow

### Local Command Shortcuts

**the project's command palette:**

```bash
# Server management
npm run dev # Start dev server
npm run dev:check # Check health
npm run dev:kill # Stop server
npm run dev:clean # Kill all dev ports

# Database
npm run db:migrate # Run migration
npm run db:studio # Open Prisma Studio
npm run db:cleanup:test # Test cleanup jobs

# Logs
npm run logs:tail # Follow clean logs
npm run logs:errors # Show only errors

# Build & Deploy
npm run build # Build + validate
npm run start # Production mode
```

### Project-Contained vs Global Tools

**this project philosophy: Project-contained**

✅ **Project-contained (preferred):**
- `npx prisma` (installed in node_modules)
- `npm run test` (uses local Jest)
- `node scripts/...` (committed scripts)

❌ **Global tools (avoid):**
- `pm2` (now removed from this project)
- Global TypeScript compiler
- Global test runners

**Why:**
- Reproducible builds
- Version consistency across team
- Works in CI/CD without extra setup
- No "works on my machine" issues

### Team Collaboration Patterns

**Documentation in scripts/README.md:**

```markdown
# Scripts Directory

## Development
- `dev-server.js` - Smart dev server with port cleanup
- `dev-check.js` - Health monitoring
- `lifecycle-shutdown.js` - Graceful shutdown

## Deployment
- `deploy.sh` - Production deployment
- `migrate-production.sh` - Safe migrations

## Utilities
- `kb-codex.sh` - Knowledge base search
- `validate-build.js` - Build validation
- `validate-env.sh` - Environment checks
```

**Self-documenting code:**

```bash
#!/usr/bin/env bash
set -euo pipefail

# Show usage if no arguments
if [[ $# -eq 0 ]]; then
 cat <<'USAGE' >&2
Usage: script-name <arg>

Description of what this does.

Examples:
 script-name foo
 script-name --help
USAGE
 exit 1
fi
```

---

## Best Practices Summary

### What Works Well in this project

✅ **Centralized scripts/ directory**
- Easy to find all automation
- Clear organization
- Committed to version control

✅ **npm script wrappers**
- Discoverable with `npm run`
- Self-documenting
- Cross-platform

✅ **Portable shebangs**
- Works on all Linux distros
- Works with nvm
- Works in Docker

✅ **Strict error handling**
- `set -euo pipefail` in bash
- `try/catch` in Node.js
- Exit codes for CI/CD

✅ **Process lifecycle management**
- PID tracking prevents orphans
- Port cleanup prevents conflicts
- Graceful shutdown preserves data

✅ **Environment validation**
- Fails fast with clear errors
- Self-documenting requirements
- Safe for production

✅ **Log pipeline**
- Raw logs saved to file
- Filtered logs for console
- Grep-able JSON logs

### Lessons Learned

🔍 **PM2 removal (November 2025)**
- **Problem**: PM2 added complexity, required global install
- **Solution**: Direct Next.js process with custom lifecycle management
- **Result**: Simpler, more reliable, better control

🔍 **Port 3001 (not 3000)**
- **Problem**: Port 3000 conflicts with other apps
- **Solution**: Use 3001 for dev, 3000 for Docker
- **Result**: Fewer port conflicts

🔍 **SQLite DELETE mode (not WAL)**
- **Problem**: WAL mode caused locking issues in development
- **Solution**: Use DELETE journal mode
- **Result**: More stable dev experience

🔍 **Log filtering pipeline**
- **Problem**: Next.js logs are noisy
- **Solution**: Python filter script removes noise
- **Result**: Easier debugging

### Recommended Patterns for Similar Projects

1. **Start with scripts/ directory**
 - Commit all scripts to version control
 - Organize by function (dev, deploy, test)

2. **Wrap with npm scripts**
 - Makes commands discoverable
 - Works across platforms

3. **Use portable shebangs**
 - `#!/usr/bin/env bash`
 - `#!/usr/bin/env node`

4. **Validate early, fail fast**
 - Check environment before starting
 - Exit with clear error messages

5. **Track process state**
 - Write PID files
 - Clean up on exit
 - Handle signals gracefully

6. **Document in code**
 - Usage messages
 - Comments explaining "why"
 - README.md in scripts/

---

## Troubleshooting

### Problem: "Permission denied" when running script

**Symptoms:**

```bash
$./scripts/kb-codex.sh
bash:./scripts/kb-codex.sh: Permission denied
```

**Solution:**

```bash
chmod +x scripts/kb-codex.sh
git add scripts/kb-codex.sh # Preserve permissions in git
```

### Problem: "Port 3001 already in use"

**Symptoms:**

```bash
$ npm run dev
⚠️ Port 3001 in use by PID 1234567 (node)
```

**Solution:**

```bash
# Option 1: Let dev-server handle it
npm run dev # Auto-kills old process

# Option 2: Manual kill
npm run dev:kill

# Option 3: Kill all dev servers
npm run dev:clean
```

### Problem: Stale PID files

**Symptoms:**

```bash
$ npm run dev
⚠️ PID file exists but process not running
```

**Solution:**

```bash
# Auto-cleaned by dev-server on startup
npm run dev

# Or manually clean
rm -rf.app/pid/*.pid
```

### Problem: Script can't find Git root

**Symptoms:**

```bash
$./kb-codex
kb-codex must be run inside the the repository
```

**Solution:**

```bash
# Ensure you're in a Git repository
cd /path/to/project
git status # Should work

# If not a Git repo:
git init
```

### Problem: Environment variables not set

**Symptoms:**

```bash
$ npm run build
❌ Missing required environment variables: ANTHROPIC_API_KEY
```

**Solution:**

```bash
# Copy example file
cp.env.example.env.local

# Edit with your values
nano.env.local

# Validate
npm run dev # Will check on startup
```

### Problem: Next.js build fails validation

**Symptoms:**

```bash
$ npm run build
❌ No CSS files found in build!
```

**Solution:**

```bash
# Check Tailwind config
cat tailwind.config.ts

# Verify globals.css imported
grep globals.css app/layout.tsx

# Rebuild
rm -rf.next
npm run build
```

### Problem: Docker entrypoint can't connect to database

**Symptoms:**

```bash
❌ Database failed to become ready after 30 attempts
```

**Solution:**

```bash
# Check database container is running
docker ps | grep postgres

# Check DATABASE_URL format
echo $DATABASE_URL
# Should be: postgresql://user:pass@host:5432/dbname

# Check network connectivity
docker network inspect app_default

# Increase retry attempts in entrypoint
# Edit docker-entrypoint.sh: max_attempts=60
```

---

## Conclusion

the project's bin directory patterns demonstrate production-grade script organization for modern web applications. Key takeaways:

1. **Centralize scripts** in a dedicated directory
2. **Wrap with npm scripts** for discoverability
3. **Use portable shebangs** for cross-platform compatibility
4. **Validate early** to fail fast with clear errors
5. **Track process lifecycle** to prevent orphans and conflicts
6. **Handle signals gracefully** for clean shutdowns
7. **Document in code** with usage messages and comments

These patterns scale from solo development to team collaboration to production deployments.

---

**File Locations:**

- Main scripts: `/path/to/project/scripts/`
- Lifecycle modules: `/path/to/project/scripts/lifecycle/`
- Docker entrypoints: `/path/to/project/docker-entrypoint*.sh`
- npm scripts: `/path/to/project/package.json`
- Documentation: `/path/to/project/scripts/README.md`

**Related Documentation:**

- [this project CLAUDE.md](/path/to/project/CLAUDE.md)
- [Scripts README](/path/to/project/scripts/README.md)
- [Port Management](/path/to/project/docs/_BloomAppDocs/setup/port-management.md)
- [Linux Bin KB Index](/path/to/project/docs/kb/linux/bin/README.md)

---

**Lines**: 1067
**Real examples**: 8 complete scripts
**Code snippets**: 40+
**Production patterns**: ✅ All from active codebase
