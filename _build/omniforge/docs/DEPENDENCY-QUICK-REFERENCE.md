# OmniForge Dependency Management - Quick Reference

**Status**: ✅ Production Ready
**Last Updated**: 2025-11-24

---

## Quick Links

### Key Files
- **bootstrap.conf** - Single source of truth for all configuration
- **lib/validation.sh** - Dependency validation & auto-remediation functions
- **lib/common.sh** - Shared logging & utility functions
- **tech_stack/_lib/pkg-install.sh** - NPM package installation helpers

### Key Functions
- **require_cmd()** - Check if command exists
- **install_docker()** - OS-aware Docker installation
- **install_psql()** - OS-aware PostgreSQL installation
- **pkg_install()** - Install npm packages via pnpm
- **has_script_succeeded()** - Check if script already executed

---

## Three-Layer Dependency Model at a Glance

```
LAYER 1: System Binaries (Preflight Check)
├── git (required, no auto-install)
├── node (required, no auto-install)
├── pnpm (required, auto-install via npm)
├── docker (optional, ✅ auto-install if enabled)
└── psql (optional, ✅ auto-install if enabled)

LAYER 2: NPM Packages (Script-Level Check)
├── pino (logging)
├── drizzle-orm (database)
├── @shadcn/ui (components)
├── zod (validation)
└── ... (40+ others)

LAYER 3: Configuration Variables (Every Script)
├── PROJECT_ROOT (required)
├── INSTALL_DIR (required)
├── APP_NAME (required)
├── DB_PASSWORD (required)
└── DB_HOST, DB_PORT, etc. (optional with defaults)
```

---

## Configuration Quick Reference

### In bootstrap.conf

**Auto-Install Flags** (lines 265-268):
```bash
AUTO_INSTALL_PNPM="${AUTO_INSTALL_PNPM:-true}"
AUTO_INSTALL_NODE="${AUTO_INSTALL_NODE:-false}"
AUTO_INSTALL_DOCKER="${AUTO_INSTALL_DOCKER:-true}"
AUTO_INSTALL_PSQL="${AUTO_INSTALL_PSQL:-true}"
```

**Preflight Flags** (lines 260-263):
```bash
PREFLIGHT_REMEDIATE="${PREFLIGHT_REMEDIATE:-true}"
PREFLIGHT_SKIP_MISSING="${PREFLIGHT_SKIP_MISSING:-false}"
```

**Feature Flags** (lines 140-152):
```bash
ENABLE_NEXTJS=true
ENABLE_DATABASE=true
ENABLE_AUTHJS=true
ENABLE_DOCKER=false
ENABLE_AI_SDK=false
# ... etc
```

---

## Common Commands

### Initialize with Dependency Checking
```bash
omni --init           # Auto-install missing docker/psql
omni status          # Show progress
omni run             # Full deployment
```

### Testing Dependencies
```bash
# Check if docker exists
command -v docker && echo "Found" || echo "Missing"

# Check if psql exists
command -v psql && echo "Found" || echo "Missing"

# Verify pnpm is installed
pnpm --version

# Check bootstrap state
cat .bootstrap_state | grep -E "docker|psql"
```

### Disable Auto-Install (for CI/CD)
```bash
export AUTO_INSTALL_DOCKER=false
export AUTO_INSTALL_PSQL=false
export PREFLIGHT_REMEDIATE=false
omni --init --skip-missing
```

---

## Dependency Checking Pattern in Scripts

Every tech_stack script follows this pattern:

```bash
#!/usr/bin/env bash
set -euo pipefail

# 1. Source libraries
source "${SCRIPT_DIR}/../../lib/common.sh"
source "${SCRIPT_DIR}/../_lib/pkg-install.sh"  # If npm needed

# 2. Define script identity
readonly SCRIPT_ID="category/script-name"
readonly SCRIPT_NAME="Display Name"

# 3. Skip if already done
if has_script_succeeded "${SCRIPT_ID}"; then
    log_skip "${SCRIPT_NAME} (already completed)"
    exit 0
fi

# 4. Validate required parameters
: "${PROJECT_ROOT:?PROJECT_ROOT not set}"
: "${INSTALL_DIR:?INSTALL_DIR not set}"

# 5. Use optional parameters with defaults
: "${DB_HOST:=localhost}"
: "${DB_PORT:=5432}"

# 6. Install npm packages (if needed)
DEPS=("pino" "pino-pretty")
pkg_preflight_check "${DEPS[@]}"
pkg_install "${DEPS[@]}"
pkg_verify "pino"

# 7. Execute script logic
log_step "${SCRIPT_NAME}"
# ... actual implementation ...

# 8. Mark success
mark_script_success "${SCRIPT_ID}"
log_success "${SCRIPT_NAME} completed"
```

---

## Troubleshooting Checklist

### Docker Not Found
- [ ] Check if installed: `command -v docker`
- [ ] Check AUTO_INSTALL_DOCKER flag in bootstrap.conf
- [ ] Check permissions: `groups | grep docker`
- [ ] Manual fix: `sudo apt install docker.io` (Ubuntu)
- [See detailed troubleshooting](DEPENDENCY-ARCHITECTURE.md#problem-docker-not-found-after-omni---init)

### PostgreSQL Client Not Found
- [ ] Check if installed: `command -v psql`
- [ ] Check AUTO_INSTALL_PSQL flag in bootstrap.conf
- [ ] Check database running: `systemctl status postgresql`
- [ ] Manual fix: `sudo apt install postgresql-client` (Ubuntu)
- [See detailed troubleshooting](DEPENDENCY-ARCHITECTURE.md#problem-postgresql-client-not-found)

### pnpm Installation Failed
- [ ] Clear cache: `pnpm store prune`
- [ ] Remove lock: `rm pnpm-lock.yaml`
- [ ] Reinstall: `pnpm install`
- [ ] Update npm: `npm install -g pnpm@latest`
- [See detailed troubleshooting](DEPENDENCY-ARCHITECTURE.md#problem-pnpm-dependency-installation-fails)

---

## File Locations Reference

```
_build/omniforge/
├── bootstrap.conf                         # Config
├── lib/
│   ├── common.sh                         # Logging, utils
│   ├── validation.sh                     # require_cmd, install_docker, install_psql
│   ├── prereqs.sh                        # Prerequisite checking
│   ├── phases.sh                         # Phase orchestration
│   └── ... (18 other libraries)
├── tech_stack/
│   ├── _lib/
│   │   └── pkg-install.sh               # pkg_install, pkg_verify functions
│   ├── core/
│   │   └── 00-nextjs.sh                 # Phase 0 foundation
│   ├── db/
│   │   ├── drizzle-schema-base.sh
│   │   └── ... (4 others)
│   ├── docker/
│   │   ├── docker-compose-pg.sh
│   │   └── ... (4 others)
│   └── ... (15 other categories)
└── docs/
    ├── DEPENDENCY-ARCHITECTURE.md        # Full documentation (this session)
    ├── DEPENDENCY-QUICK-REFERENCE.md    # This file
    └── OMNIFORGE.md                     # General OmniForge documentation
```

---

## Key Statistics

- **21 library files** - All have valid bash syntax ✅
- **57+ tech_stack scripts** - All follow consistent patterns ✅
- **6 phases** - Sequential initialization (0-5) ✅
- **18 categories** - Organized by feature/layer ✅
- **451 lines** in bootstrap.conf - Well-structured ✅
- **3 dependency layers** - Comprehensive checking ✅

---

## Security Notes

- **DB_PASSWORD**: Secure random 14-character value
- **NO hardcoded credentials**: All in bootstrap.conf
- **Parameter validation**: All required params checked
- **Fail-fast behavior**: Exit on missing required dependencies
- **Auto-install can be disabled**: Set AUTO_INSTALL_*=false for strict environments

---

## For More Information

- **Full Architecture**: [DEPENDENCY-ARCHITECTURE.md](DEPENDENCY-ARCHITECTURE.md)
- **OmniForge Docs**: [OMNIFORGE.md](OMNIFORGE.md)
- **Code examples**: Look at representative scripts:
  - Phase 0 NPM: [tech_stack/core/00-nextjs.sh](../tech_stack/core/00-nextjs.sh)
  - Phase 1 Config: [tech_stack/db/drizzle-schema-base.sh](../tech_stack/db/drizzle-schema-base.sh)
  - Phase 1 Binary: [tech_stack/docker/docker-compose-pg.sh](../tech_stack/docker/docker-compose-pg.sh)

---

**Quick Reference Document**
**Version**: 1.0
**Status**: ✅ Production Ready
