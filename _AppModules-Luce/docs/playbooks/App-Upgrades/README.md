# App Upgrades - Self-Contained Solution

Complete playbook and automation scripts for managing dependency upgrades in Appmelia Bloom.

## 📁 Contents

```
App-Upgrades/
├── README.md                      # This file
├── App-Upgrades-Process.md        # Interactive playbook (1144 lines)
└── scripts/                       # Helper automation scripts
    ├── upgrade-baseline.sh        # Save baseline state before upgrades
    ├── upgrade-scan.sh            # Discover available upgrades
    ├── upgrade-package.sh         # 🆕 Upgrade package with tracking
    ├── upgrade-history.sh         # 🆕 View upgrade history
    ├── upgrade-validate.sh        # Post-upgrade validation suite
    ├── test-bcrypt.cjs            # Test bcrypt functionality
    └── test-prisma.cjs            # Test Prisma database connectivity
```

## 🚀 Quick Start

### Automated Workflow (Recommended) 🆕

```bash
cd _AppModules-Luce/playbooks/App-Upgrades

# 1. Discover available upgrades
./scripts/upgrade-scan.sh

# 2. Upgrade a package (automatically tracks package.json changes)
./scripts/upgrade-package.sh @anthropic-ai/sdk latest

# 3. Validate changes
./scripts/upgrade-validate.sh

# 4. View upgrade history
./scripts/upgrade-history.sh
```

### Manual Workflow

### 1. Discover Available Upgrades
```bash
cd _AppModules-Luce/playbooks/App-Upgrades
./scripts/upgrade-scan.sh
```
**Output**: Scan report in `_build/upgrade-scans/` with:
- Outdated packages (npm outdated)
- Dependabot PRs (if GitHub CLI available)
- Major version upgrades
- Security vulnerabilities
- Critical package versions

### 2. Save Baseline State
```bash
./scripts/upgrade-baseline.sh
```
**Output**: Baseline snapshot in `_build/upgrade-baseline/` with:
- Node.js and npm versions
- Current package versions
- Git status
- Audit summary

### 3. Execute Upgrade
**Option A**: Use automated upgrade (with tracking)
```bash
./scripts/upgrade-package.sh <package-name> [version]
```

**Option B**: Follow the interactive playbook: `App-Upgrades-Process.md`

### 4. Validate Changes
```bash
./scripts/upgrade-validate.sh
```
**Runs**:
- ✅ TypeScript type check (`npx tsc --noEmit`)
- ✅ ESLint (`npm run lint`)
- ✅ Next.js build (`npm run build`)
- ✅ Unit tests (if available)
- ✅ Prisma schema validation
- ✅ Prisma client generation
- ✅ Security audit
- ✅ Package lock consistency

**Output**: Validation report in `_build/upgrade-validation/`

### 5. Test Critical Dependencies (Optional)
```bash
# Test bcrypt hashing/verification (run from project root)
node _AppModules-Luce/playbooks/App-Upgrades/scripts/test-bcrypt.cjs

# Test Prisma database connectivity (run from project root)
node _AppModules-Luce/playbooks/App-Upgrades/scripts/test-prisma.cjs
```

## 📖 Full Playbook

See [App-Upgrades-Process.md](App-Upgrades-Process.md) for the complete interactive workflow with:
- 5 phases (Discovery → Risk Assessment → Execution → Validation → Documentation)
- Risk categorization (LOW/MEDIUM/HIGH/CRITICAL)
- Breaking change detection
- Rollback procedures
- Templates and checklists

## 🛠️ Script Reference

### upgrade-baseline.sh
**Purpose**: Save complete baseline state before any upgrades
**Usage**: `./scripts/upgrade-baseline.sh`
**Output**: `_build/upgrade-baseline/baseline-YYYYMMDD-HHMMSS.txt`
**Captures**:
- System versions (Node, npm, TypeScript)
- Installed packages (`npm list --depth=0`)
- Outdated packages
- Git status and branch
- Dependabot PRs
- Audit summary

### upgrade-scan.sh
**Purpose**: Automated discovery of available upgrades
**Usage**: `./scripts/upgrade-scan.sh`
**Output**: `_build/upgrade-scans/scan-YYYYMMDD-HHMMSS.txt`
**Finds**:
- All outdated packages
- Major version upgrades (breaking changes likely)
- Security vulnerabilities (critical/high)
- Deprecated packages
- Critical package versions (Next.js, Anthropic, Prisma, etc.)

### upgrade-package.sh 🆕
**Purpose**: Upgrade a package with automatic package.json tracking
**Usage**: `./scripts/upgrade-package.sh <package-name> [version]`
**Examples**:
- `./scripts/upgrade-package.sh @anthropic-ai/sdk latest`
- `./scripts/upgrade-package.sh next 16.0.3`
- `./scripts/upgrade-package.sh bcryptjs` (defaults to latest)

**What it does**:
1. Reads current version from package.json (dependencies or devDependencies)
2. Saves package.json snapshot (before upgrade)
3. Resolves target version (from npm registry if "latest")
4. Installs/upgrades the package using npm
5. Saves updated package.json snapshot (after upgrade)
6. Creates JSON tracking record with full metadata

**Output**: `_build/upgrade-tracking/upgrade-<package>-YYYYMMDD-HHMMSS.json`

**Tracking record includes**:
- Timestamp and package name
- Versions (before, after, target)
- Dependency type (dependencies vs devDependencies)
- Action (install vs upgrade)
- Git context (branch, commit)
- System info (Node.js, npm versions)
- File paths (before/after snapshots)

**Use when**: You want automated tracking of package.json changes

### upgrade-history.sh 🆕
**Purpose**: View package upgrade history from tracking records
**Usage**:
- `./scripts/upgrade-history.sh` - Show all upgrades
- `./scripts/upgrade-history.sh <package-name>` - Filter by package

**Output**: Console display of all tracked upgrades with:
- Timestamp
- Package name and versions (before → after)
- Action (INSTALL or UPGRADE)
- Dependency type
- Git context (branch, commit)
- Tracking file path

**Use when**: You want to see what packages were upgraded and when

### upgrade-validate.sh
**Purpose**: Comprehensive post-upgrade validation
**Usage**: `./scripts/upgrade-validate.sh`
**Output**: `_build/upgrade-validation/validation-YYYYMMDD-HHMMSS.txt`
**Exit code**: 0 (success), 1 (failure)
**Checks**:
1. TypeScript compilation
2. ESLint rules
3. Next.js build
4. Unit tests
5. Prisma schema
6. Prisma client generation
7. Security audit
8. Package lock consistency

### test-bcrypt.cjs
**Purpose**: Verify bcrypt hashing and verification still works
**Usage**: `node _AppModules-Luce/playbooks/App-Upgrades/scripts/test-bcrypt.cjs` (from project root)
**Tests**:
- Hash generation (cost 10 and 12)
- Password verification (correct password)
- Rejection of wrong password
- Backward compatibility (2a vs 2b formats)
- Different cost factors

**Use when**: Upgrading bcryptjs, bcrypt, or related auth packages

### test-prisma.cjs
**Purpose**: Verify Prisma database connectivity and operations
**Usage**: `node _AppModules-Luce/playbooks/App-Upgrades/scripts/test-prisma.cjs` (from project root)
**Tests**:
- Database connection
- Simple queries (count)
- Complex queries (with relations)
- Transaction support
- Schema introspection

**Use when**: Upgrading Prisma, @prisma/client, or database-related packages

## 📊 Example Workflows

### Automated Workflow (Recommended) 🆕

```bash
# 1. Discover what needs upgrading
./scripts/upgrade-scan.sh
# Review: _build/upgrade-scans/scan-20251115-210000.txt
# Found: bcryptjs 2.4.3 → 3.0.3 (MAJOR)

# 2. Upgrade with automatic tracking
./scripts/upgrade-package.sh bcryptjs latest
# === Package Upgrade Tracker ===
# Package: bcryptjs
# Current version: 2.4.3
# Target version: 3.0.3
# [1/6] Reading current package.json... ✅
# [2/6] Saving package.json snapshot... ✅
# [3/6] Resolving target version... ✅
# [4/6] Installing package... ✅
# [5/6] Reading updated package.json... ✅
# [6/6] Creating tracking record... ✅
# Tracking record saved to: _build/upgrade-tracking/upgrade-bcryptjs-20251115-210100.json

# 3. Test critical functionality (from project root)
node _AppModules-Luce/playbooks/App-Upgrades/scripts/test-bcrypt.cjs
# ✅ All bcrypt tests passed!

# 4. Run full validation suite
./scripts/upgrade-validate.sh
# [1/8] TypeScript Type Check... ✅
# [2/8] ESLint Check... ✅
# [3/8] Next.js Build... ✅
# ...
# ✅ All validation checks passed!

# 5. View upgrade history
./scripts/upgrade-history.sh
# [UPGRADE] bcryptjs
#   Time:     2025-11-15T21:01:00-05:00
#   Versions: 2.4.3 → 3.0.3
#   Type:     dependencies
#   Git:      main @ 8d27d46c

# 6. Commit changes
git add .
git commit -m "feat: upgrade bcryptjs 2.4.3 → 3.0.3"
git push
```

### Manual Workflow

```bash
# 1. Discover what needs upgrading
./scripts/upgrade-scan.sh
# Review: _build/upgrade-scans/scan-20251115-210000.txt

# 2. Save baseline before starting
./scripts/upgrade-baseline.sh
# Saved: _build/upgrade-baseline/baseline-20251115-210100.txt

# 3. Execute upgrade (example: bcryptjs)
npm install bcryptjs@latest

# 4. Test critical functionality (from project root)
node _AppModules-Luce/playbooks/App-Upgrades/scripts/test-bcrypt.cjs
# Output: All tests passed ✅

# 5. Run full validation suite
./scripts/upgrade-validate.sh
# [1/8] TypeScript Type Check... ✅
# [2/8] ESLint Check... ✅
# [3/8] Next.js Build... ✅
# ...
# ✅ All validation checks passed!

# 6. Commit changes
git add .
git commit -m "feat: upgrade bcryptjs 2.4.3 → 3.0.3"
git push
```

## 🎯 Risk Categories

The playbook uses risk-based prioritization:

### LOW Risk (Patch updates)
- Example: `16.0.1 → 16.0.3`
- Quick validation: Type check + build
- Safe to batch multiple LOW risk upgrades

### MEDIUM Risk (Minor updates)
- Example: `0.27.x → 0.69.x`
- Full validation required
- Check breaking changes in release notes

### HIGH Risk (Major updates)
- Example: `v2 → v3`
- Deep investigation required
- Test all usage locations
- Migration guide review

### CRITICAL Risk (Core infrastructure)
- Examples: Next.js, React, Prisma, TypeScript
- Isolated upgrade (one at a time)
- Full test suite + manual testing
- Rollback plan ready

## 📝 Output Files

All scripts create timestamped output files in `_build/`:

```
_build/
├── upgrade-baseline/
│   ├── baseline-20251115-210000.txt
│   └── latest.txt -> baseline-20251115-210000.txt
├── upgrade-scans/
│   └── scan-20251115-210100.txt
└── upgrade-validation/
    └── validation-20251115-210200.txt
```

## 🔧 Requirements

**Required**:
- Node.js (current version)
- npm
- Git

**Optional** (for enhanced features):
- GitHub CLI (`gh`) - For Dependabot PR detection
- jq - For JSON parsing in scripts

**Install optional tools**:
```bash
# GitHub CLI
sudo apt install gh
gh auth login

# jq (JSON processor)
sudo apt install jq
```

## 📚 Related Documentation

- **Playbook**: [App-Upgrades-Process.md](App-Upgrades-Process.md) - Full interactive guide
- **Project Docs**: `/home/luce/apps/bloom/docs/ARCHITECTURE.md`
- **Bloom CLAUDE.md**: `/home/luce/apps/bloom/CLAUDE.md`

## 🚨 Common Issues

### "Permission denied" when running scripts
```bash
chmod +x scripts/*.sh
```

### Scripts not found
```bash
# Run from the App-Upgrades directory
cd _AppModules-Luce/playbooks/App-Upgrades
```

### Missing _build directory
Scripts will create it automatically, but you can create manually:
```bash
mkdir -p _build/{upgrade-baseline,upgrade-scans,upgrade-validation}
```

## 📈 Version History

- **v1.1** (2025-11-15): Fixed critical issues
  - Added `mkdir -p _build` to baseline commands
  - Converted multi-line Node.js commands to single-line
  - Added helper script references
- **v1.0** (2025-11-15): Initial playbook and scripts

## 🤝 Contributing

This is a self-contained module. Updates should:
1. Test all scripts with `upgrade-validate.sh`
2. Update version in playbook and README
3. Document changes in this README

---

**Need help?** Start with the playbook: `App-Upgrades-Process.md` for step-by-step guidance.
