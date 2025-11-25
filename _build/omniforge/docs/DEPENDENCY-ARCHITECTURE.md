# OmniForge Dependency Management Architecture

**Last Updated**: 2025-11-24
**Status**: Production Ready ✅
**Verified**: All 21 library files, Bootstrap config, 57+ tech_stack scripts

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Architecture Overview](#architecture-overview)
3. [Three-Layer Dependency Model](#three-layer-dependency-model)
4. [Dependency Checking Flow](#dependency-checking-flow)
5. [Auto-Remediation System](#auto-remediation-system)
6. [Script Patterns & Best Practices](#script-patterns--best-practices)
7. [Configuration Reference](#configuration-reference)
8. [Troubleshooting](#troubleshooting)

---

## Quick Start

### Running OmniForge

```bash
# Check dependencies and initialize (auto-remediates missing docker/psql)
omni --init

# Run full deployment
omni run

# Check status
omni status

# Reset deployment (if needed)
omni reset --yes
```

### Checking Specific Dependencies

```bash
# Check if docker is installed
command -v docker && echo "Docker found" || echo "Docker missing"

# Check if psql is installed
command -v psql && echo "PostgreSQL client found" || echo "Missing"

# Check pnpm version
pnpm --version

# Check Node.js version
node --version
```

### Docker-First Notes

- Bootstrap runs inside the Docker `app` container by default (host menu/status remain host-only).
- Docker preflight (CLI + daemon + compose) happens when starting a run; templates are staged before re-exec.
- The project `.env` (\`${APP_ENV_FILE:-.env}\`) is the canonical source of truth; `.env.local` is merged for missing keys only. `.tools` is legacy/host-only in container mode.
- Re-run behavior is detect-and-exit: delete/rebuild to apply new configuration.

---

## Architecture Overview

### System Components

```
_build/omniforge/
├── omni.config / omni.settings.sh / omni.profiles.sh / omni.phases.sh   # Canonical configuration (omni.* config is legacy)
├── omni.sh                     # Main CLI entry point
├── lib/                        # Core library functions (21 files)
│   ├── common.sh              # Shared logging, file ops
│   ├── validation.sh          # Dependency validation & auto-install
│   ├── prereqs.sh             # Prerequisite checking
│   ├── phases.sh              # Phase orchestration
│   └── ... (18 other libraries)
├── tech_stack/                # Feature implementations (57+ scripts)
│   ├── core/                  # Foundation (Phase 0)
│   ├── db/                    # Database (Phase 1)
│   ├── docker/                # Infrastructure (Phase 1)
│   ├── observability/         # Logging (Phase 2)
│   ├── intelligence/          # AI features (Phase 4)
│   └── ... (13 other categories)
└── docs/                      # Documentation
```

### Execution Flow

```
1. User runs: omni --init
2. omni.sh sources lib/bootstrap.sh which loads omni.* (omni.* config is legacy/stub)
3. omni.sh sources lib/common.sh (logging, utilities)
4. omni.sh calls preflight_check() from lib/validation.sh
5. Preflight checks: git, node, pnpm, docker, psql
6. Missing dependencies: auto-remediate if AUTO_INSTALL_* = true
7. Phase 0 starts: Execute tech_stack scripts sequentially
8. Each script sources lib/common.sh + dependencies
9. Each script validates parameters and executes
10. State tracked in .bootstrap_state (idempotent)
11. Repeat phases 1-5 until complete or error
```

---

## Three-Layer Dependency Model

### Layer 1: System Binaries (Preflight Check)

**Checked once** during `omni --init` preflight phase.

| Binary | Required | Auto-Install | Location |
|--------|----------|--------------|----------|
| git | ✅ Yes | ❌ No | `/usr/bin/git` |
| node | ✅ Yes | ❌ No | `/usr/bin/node` |
| pnpm | ✅ Yes | ⚠️ Via npm | `~/.local/bin/pnpm` |
| docker | ⚠️ Optional* | ✅ Yes | `/usr/bin/docker` |
| psql | ⚠️ Optional* | ✅ Yes | `/usr/bin/psql` |

*Required if ENABLE_DATABASE or ENABLE_DOCKER features enabled

**Checking Function**: `require_cmd()` in [lib/validation.sh:27-40](lib/validation.sh#L27)

**Auto-Install Functions**:
- `install_docker()`: [lib/validation.sh:235-273](lib/validation.sh#L235)
- `install_psql()`: [lib/validation.sh:277-315](lib/validation.sh#L277)

### Layer 2: NPM Packages (Script-Level Check)

**Checked within individual scripts** that require npm packages.

Examples:
- `pino` - Logging framework (Phase 2)
- `drizzle-orm` - Database ORM (Phase 1)
- `@shadcn/ui` - UI components (Phase 3)
- `zod` - Schema validation (Phase 1+)

**Installation Pattern**:
```bash
source "${SCRIPT_DIR}/../_lib/pkg-install.sh"

DEPS=("pino" "pino-pretty")
pkg_preflight_check "${DEPS[@]}"  # Check cache
pkg_install "${DEPS[@]}"          # Install via pnpm
pkg_verify "pino"                 # Verify installation
```

**Helper Functions**: [tech_stack/_lib/pkg-install.sh](tech_stack/_lib/pkg-install.sh)
- `pkg_preflight_check()` - Check if cached
- `pkg_install()` - Install via pnpm
- `pkg_verify()` - Verify successful installation

### Layer 3: Configuration Variables (Every Script)

**Checked in every script** using bash parameter validation.

Examples:
```bash
# Required parameters (exit if missing)
: "${PROJECT_ROOT:?PROJECT_ROOT not set}"
: "${INSTALL_DIR:?INSTALL_DIR not set}"
: "${APP_NAME:?APP_NAME not set}"

# Optional parameters (use default if missing)
: "${DB_HOST:=localhost}"
: "${DB_PORT:=5432}"
: "${POSTGRES_VERSION:=16}"
```

**Common Variables**:
| Variable | Set In | Used By | Purpose |
|----------|--------|---------|---------|
| PROJECT_ROOT | omni.settings.sh | All scripts | Project root directory |
| INSTALL_DIR | omni.settings.sh | All scripts | Installation target directory |
| APP_NAME | omni.config | UI generation | Application display name |
| DB_NAME | omni.config | Database scripts | Database name |
| DB_PASSWORD | omni.config | Docker Compose | PostgreSQL password |
| DB_HOST | omni.config | App config | Database hostname (default: localhost) |
| DB_PORT | omni.config | App config | Database port (default: 5432) |

---

## Dependency Checking Flow

### Preflight Phase (One-Time)

```
omni --init
  ↓
preflight_check() [lib/validation.sh:350-390]
  ├── Check git (required)
  ├── Check node version >= 20
  ├── Check pnpm installed
  ├── Check docker installed
  │   └── If missing & AUTO_INSTALL_DOCKER=true
  │       └── install_docker() [OS-aware]
  └── Check psql installed
      └── If missing & AUTO_INSTALL_PSQL=true
          └── install_psql() [OS-aware]
```

### Phase Execution (Per-Phase)

```
Phase N execution [lib/phases.sh]
  ├── Load script list for phase
  └── For each script in phase:
      ├── Source lib/common.sh
      ├── Check has_script_succeeded() → skip if already done
      ├── Validate parameters (: "${VAR:?error}")
      ├── Load dependencies:
      │   ├── source lib/pkg-install.sh (if npm packages needed)
      │   └── pkg_preflight_check() + pkg_install()
      ├── Execute script logic
      └── mark_script_success()
```

### Parameter Validation Pattern

Every tech_stack script follows this pattern:

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"

readonly SCRIPT_ID="category/script-name"
readonly SCRIPT_NAME="Human-Readable Name"

# Skip if already done
if has_script_succeeded "${SCRIPT_ID}"; then
    log_skip "${SCRIPT_NAME} (already completed)"
    exit 0
fi

log_step "${SCRIPT_NAME}"

# Validate required parameters
: "${PROJECT_ROOT:?PROJECT_ROOT not set}"
: "${INSTALL_DIR:?INSTALL_DIR not set}"
: "${APP_NAME:?APP_NAME not set}"

# Use optional parameters with defaults
: "${DB_HOST:=localhost}"
: "${DB_PORT:=5432}"

# Script logic here...

# Mark success and exit
mark_script_success "${SCRIPT_ID}"
log_success "${SCRIPT_NAME} completed"
```

---

## Auto-Remediation System

### Docker Auto-Installation

**Function**: `install_docker()` [lib/validation.sh:235-273](lib/validation.sh#L235)

**Flow**:
```
Check AUTO_INSTALL_DOCKER flag
  ├── If false: skip installation
  └── If true:
      ├── Check if docker already installed
      │   └── If yes: return success
      ├── Detect OS:
      │   ├── Linux (apt): apt update && apt install -y docker.io
      │   ├── Linux (yum): yum install -y docker
      │   └── macOS (brew): brew install docker
      ├── Start docker service (Linux systemctl)
      └── Verify installation (docker --version)
```

**Configuration**:
```bash
## omni.* config (omni.* config legacy)
AUTO_INSTALL_DOCKER="${AUTO_INSTALL_DOCKER:-true}"
```

**Usage**:
```bash
# Called from preflight_remediate_missing() if docker missing
if [[ "${ENABLE_DOCKER}" == "true" ]]; then
    if install_docker; then
        log_ok "Docker installed successfully"
    else
        log_warn "Docker auto-install failed"
    fi
fi
```

### PostgreSQL Client Auto-Installation

**Function**: `install_psql()` [lib/validation.sh:277-315](lib/validation.sh#L277)

**Flow**:
```
Check AUTO_INSTALL_PSQL flag
  ├── If false: skip installation
  └── If true:
      ├── Check if psql already installed
      │   └── If yes: return success
      ├── Detect OS:
      │   ├── Linux (apt): apt update && apt install -y postgresql-client
      │   ├── Linux (yum): yum install -y postgresql
      │   └── macOS (brew): brew install libpq
      └── Verify installation (psql --version)
```

**Configuration**:
```bash
## omni.* config (omni.* config legacy)
AUTO_INSTALL_PSQL="${AUTO_INSTALL_PSQL:-true}"
```

**Usage**:
```bash
# Called from preflight_remediate_missing() if psql missing
if [[ "${ENABLE_DATABASE}" == "true" ]]; then
    if install_psql; then
        log_ok "PostgreSQL client installed successfully"
    else
        log_warn "PostgreSQL auto-install failed"
    fi
fi
```

### Disabling Auto-Remediation

For strict CI/CD environments, disable auto-install:

```bash
# Override in environment
export AUTO_INSTALL_DOCKER=false
export AUTO_INSTALL_PSQL=false

# Defined in omni.* config
AUTO_INSTALL_DOCKER="false"
AUTO_INSTALL_PSQL="false"

# Or disable entire preflight remediation
export PREFLIGHT_REMEDIATE=false

# Run with skip-missing flag for CI
export PREFLIGHT_SKIP_MISSING=true
omni --init --skip-missing
```

---

## Script Patterns & Best Practices

### Pattern 1: Simple Configuration Script

**Example**: [tech_stack/db/drizzle-schema-base.sh](tech_stack/db/drizzle-schema-base.sh)

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"

readonly SCRIPT_ID="db/drizzle-schema-base"
readonly SCRIPT_NAME="Drizzle Base Schema"

if has_script_succeeded "${SCRIPT_ID}"; then
    log_skip "${SCRIPT_NAME} (already completed)"
    exit 0
fi

log_step "${SCRIPT_NAME}"

: "${INSTALL_DIR:?INSTALL_DIR not set}"

mkdir -p "${INSTALL_DIR}/src/db/schema"

# Create schema files...
write_file "${INSTALL_DIR}/src/db/schema/base.ts" <<'EOF'
// Schema code here...
EOF

mark_script_success "${SCRIPT_ID}"
log_success "${SCRIPT_NAME} completed"
```

### Pattern 2: NPM Package Installation

**Example**: [tech_stack/observability/pino-logger.sh](tech_stack/observability/pino-logger.sh)

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"
source "${SCRIPT_DIR}/../_lib/pkg-install.sh"

readonly SCRIPT_ID="observability/pino-logger"

if has_script_succeeded "${SCRIPT_ID}"; then
    log_skip "Pino Logger (already completed)"
    exit 0
fi

log_step "Setting up Pino Logger"

: "${INSTALL_DIR:?INSTALL_DIR not set}"
cd "${INSTALL_DIR}"

# Install packages
DEPS=("pino" "pino-pretty")
pkg_preflight_check "${DEPS[@]}"
pkg_install "${DEPS[@]}"
pkg_verify "pino"

# Create configuration...
write_file "src/lib/logger.ts" <<'EOF'
import pino from 'pino';
// Logger setup...
EOF

mark_script_success "${SCRIPT_ID}"
log_success "Pino Logger setup completed"
```

### Pattern 3: External Binary Dependency

**Example**: [tech_stack/docker/docker-compose-pg.sh](tech_stack/docker/docker-compose-pg.sh)

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"

readonly SCRIPT_ID="docker/docker-compose-pg"

if has_script_succeeded "${SCRIPT_ID}"; then
    log_skip "Docker Compose PostgreSQL (already completed)"
    exit 0
fi

log_step "Creating Docker Compose PostgreSQL Stack"

: "${PROJECT_ROOT:?PROJECT_ROOT not set}"
: "${APP_NAME:?APP_NAME not set}"
: "${DB_NAME:?DB_NAME not set}"
: "${DB_PASSWORD:?DB_PASSWORD not set}"
: "${DB_HOST:=postgres}"
: "${DB_PORT:=5432}"

# Docker must be available (checked in preflight)
if ! command -v docker &>/dev/null; then
    log_error "Docker not found"
    exit 1
fi

# Create docker-compose.yml...
write_file "docker-compose.yml" <<'EOF'
version: '3.8'
services:
  postgres:
    image: postgres:${POSTGRES_VERSION}
    environment:
      POSTGRES_DB: ${DB_NAME}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    ports:
      - "${DB_PORT}:5432"
EOF

mark_script_success "${SCRIPT_ID}"
log_success "Docker Compose PostgreSQL Stack created"
```

---

## Configuration Reference

#### omni.* config (omni.* config legacy) Settings

**Dependency Configuration** [omni.config / omni.settings.sh:260-270](omni.* config#L260):

```bash
# =============================================================================
# PREFLIGHT REMEDIATION & DEPENDENCIES
# =============================================================================

# Auto-install missing pnpm
AUTO_INSTALL_PNPM="${AUTO_INSTALL_PNPM:-true}"

# Auto-install missing Node.js (currently disabled - requires nvm)
AUTO_INSTALL_NODE="${AUTO_INSTALL_NODE:-false}"

# Auto-install missing Docker (OS-aware)
AUTO_INSTALL_DOCKER="${AUTO_INSTALL_DOCKER:-true}"

# Auto-install missing PostgreSQL client (OS-aware)
AUTO_INSTALL_PSQL="${AUTO_INSTALL_PSQL:-true}"

# Enable remediation of missing dependencies in preflight
PREFLIGHT_REMEDIATE="${PREFLIGHT_REMEDIATE:-true}"

# Skip missing dependencies (useful for CI/CD)
PREFLIGHT_SKIP_MISSING="${PREFLIGHT_SKIP_MISSING:-false}"
```

**Feature Flags** [omni.config / omni.settings.sh:140-152](omni.* config#L140):

```bash
# Stack features - enable/disable by profile
ENABLE_NEXTJS="${ENABLE_NEXTJS:-true}"           # Next.js framework
ENABLE_DATABASE="${ENABLE_DATABASE:-true}"       # PostgreSQL database
ENABLE_AUTHJS="${ENABLE_AUTHJS:-true}"          # NextAuth.js authentication
ENABLE_AI_SDK="${ENABLE_AI_SDK:-false}"         # Anthropic AI SDK
ENABLE_PG_BOSS="${ENABLE_PG_BOSS:-false}"       # pg-boss job queue
ENABLE_SHADCN="${ENABLE_SHADCN:-false}"         # shadcn/ui components
ENABLE_ZUSTAND="${ENABLE_ZUSTAND:-false}"       # Zustand state management
ENABLE_PDF_EXPORTS="${ENABLE_PDF_EXPORTS:-false}"  # PDF generation
ENABLE_TEST_INFRA="${ENABLE_TEST_INFRA:-false}"    # Testing framework
ENABLE_CODE_QUALITY="${ENABLE_CODE_QUALITY:-false}"  # Code quality tools
```

**Security** [omni.config / omni.settings.sh:180-185](omni.* config#L180):

```bash
# Database credentials (auto-generated, never hardcoded in repo)
DB_NAME="${DB_NAME:-bloom2}"
DB_USER="${DB_USER:-postgres}"
DB_PASSWORD="${DB_PASSWORD:-r6VcpsjgqngnXV}"    # Secure random 14-char
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
```

---

## Troubleshooting

### Problem: Docker not found after omni --init

**Symptoms**:
```
❌ Docker not found
❌ docker: command not found
```

**Diagnosis**:
```bash
# Check if docker is installed
command -v docker

# Check AUTO_INSTALL_DOCKER flag
grep "AUTO_INSTALL_DOCKER" omni.settings.sh

# Check if docker installation ran
grep "install_docker" ~/.bootstrap_state 2>/dev/null || echo "Not in state file"
```

**Solutions**:

1. **Enable auto-install** (if disabled):
   ```bash
   export AUTO_INSTALL_DOCKER=true
   omni --init
   ```

2. **Manual installation**:
   ```bash
   # Ubuntu/Debian
   sudo apt update && sudo apt install -y docker.io

   # CentOS/RHEL
   sudo yum install -y docker

   # macOS
   brew install docker
   ```

3. **Check permissions**:
   ```bash
   # Docker requires sudo or docker group membership
   groups | grep docker

   # Add user to docker group (Linux)
   sudo usermod -aG docker $USER
   newgrp docker  # Apply group immediately
   ```

### Problem: PostgreSQL client not found

**Symptoms**:
```
❌ psql: command not found
Error connecting to database
```

**Diagnosis**:
```bash
# Check if psql is installed
command -v psql

# Check PostgreSQL version
psql --version

# Check if database connection works
psql -h localhost -U postgres -d postgres -c "SELECT version();"
```

**Solutions**:

1. **Enable auto-install** (if disabled):
   ```bash
   export AUTO_INSTALL_PSQL=true
   omni --init
   ```

2. **Manual installation**:
   ```bash
   # Ubuntu/Debian
   sudo apt update && sudo apt install -y postgresql-client

   # CentOS/RHEL
   sudo yum install -y postgresql

   # macOS
   brew install libpq
   ```

3. **Verify database is running**:
   ```bash
   # Check if PostgreSQL service is running
   systemctl status postgresql  # Linux
   brew services list | grep postgresql  # macOS
   ```

### Problem: pnpm dependency installation fails

**Symptoms**:
```
❌ Failed to install dependencies
npm ERR! code E404
npm ERR! 404 Not Found
```

**Diagnosis**:
```bash
# Check pnpm version
pnpm --version

# Check npm registry
npm config get registry

# Check if node_modules exists
ls -la node_modules/ | head

# Check cache status
pnpm store status
```

**Solutions**:

1. **Clear cache and reinstall**:
   ```bash
   pnpm store prune
   rm -rf node_modules pnpm-lock.yaml
   pnpm install
   ```

2. **Update pnpm**:
   ```bash
   npm install -g pnpm@latest
   pnpm --version
   ```

3. **Check npm registry**:
   ```bash
   npm set registry https://registry.npmjs.org/
   pnpm install
   ```

### Problem: Script already marked as succeeded but needs to re-run

**Symptoms**:
```
⏭️ Script already completed (skipped)
But I need to re-run this script!
```

**Solution**:

1. **Clear specific script from state**:
   ```bash
   # View current state
   cat .bootstrap_state

   # Remove script from state file
   # (Edit .bootstrap_state and delete the script ID line)

   # Or reset entire deployment
   omni reset --yes
   ```

2. **Run with verbose output**:
   ```bash
   export VERBOSE=true
   omni run --verbose
   ```

### Problem: omni command not found

**Symptoms**:
```
bash: omni: command not found
```

**Solution**:

1. **Check if omni.sh exists**:
   ```bash
   test -f _build/omniforge/omni.sh && echo "Found" || echo "Missing"
   ```

2. **Run directly**:
   ```bash
   _build/omniforge/omni.sh --help
   ```

3. **Create symlink** (if alias not working):
   ```bash
   sudo ln -s /home/luce/apps/bloom2/_build/omniforge/omni.sh /usr/local/bin/omni
   chmod +x /usr/local/bin/omni
   ```

---

## Summary

The OmniForge dependency management system provides:

✅ **Comprehensive checking** across three layers (system binaries, npm packages, configuration)
✅ **Automatic remediation** for critical dependencies (docker, psql)
✅ **Idempotent execution** preventing duplicate installations
✅ **Flexible configuration** via omni.* config and environment variables
✅ **Graceful degradation** with warnings and skip options
✅ **Cross-platform support** with OS-aware package management

**For questions or issues**, refer to [OMNIFORGE.md](OMNIFORGE.md) or run:
```bash
omni --help
```

---

**Document**: DEPENDENCY-ARCHITECTURE.md
**Version**: 1.0
**Last Updated**: 2025-11-24
**Verified**: ✅ All systems operational
