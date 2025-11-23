---
name: cli-manager-playbook-library
description: Master Manifest of Workflows, Checklists, Templates, and Examples for CLI Manager Agent
version: 2.0.0
---

# CLI Manager Playbook Library
**Master Manifest of Workflows, Checklists, Templates, and Examples**

**Version:** 2.0.0
**Last Updated:** 2025-10-27
**Purpose:** Definitive reference for all cli-manager agent playbooks, checklists, templates, and workflow examples

---

## Table of Contents
1. [Playbooks](#playbooks) — Structured workflows for common tasks
2. [Checklists](#checklists) — Validation and review checklists
3. [Templates](#templates) — Production-ready script templates
4. [Examples](#examples) — Common workflow examples
5. [Changelog](#changelog) — Version history and updates

---

## Playbooks

Playbooks are structured workflows that guide the agent through complex multi-step tasks.

**Location:** `.claude/agents/cli-manager/playbooks/`

### Category Configuration Playbooks

#### 0. category-config-review.yml
**Purpose:** Comprehensive review and validation of .category.conf files for dynamic menu system

**When to use:**
- Dynamic menu displaying incorrect/confusing category names
- Category counts showing as 0 or unexpected numbers
- Preview pane showing inaccurate or generic descriptions
- New category added and needs validation
- Category reorganization or directory restructure

**Validation Checks:**

**Naming Consistency:**
- CATEGORY_NAME matches directory purpose
- No technical prefixes (OS:, PHASE:, etc.)
- Name is descriptive (3-8 words)

**Description Accuracy:**
- Description matches actual directory content
- Comprehensive (2-4 sentences + bullets)
- CATEGORY_DETAILS is current and accurate

**Primary Category Grouping:**
- PRIMARY_CATEGORY is appropriate:
  - "System & Operations" — System management, config
  - "Development & Applications" — Dev tools, CLI tools
  - "Network & Media" — Network tools, media processing

**Common Fix Patterns:**

**Pattern 1: Rename Confusing Prefix**
```bash
# BEFORE:
CATEGORY_NAME="OS: Linux"

# AFTER:
CATEGORY_NAME="Modern CLI Tools"
```

**Pattern 2: Update Description**
```bash
# BEFORE:
CATEGORY_DESCRIPTION="Linux utilities"

# AFTER:
CATEGORY_DESCRIPTION="Modern command-line tools: fd, rg, bat, fzf, eza, delta.
Rust-powered replacements for traditional Unix commands with enhanced features."
```

**Pattern 3: Fix Primary Category**
```bash
# gui-apps directory
# BEFORE:
PRIMARY_CATEGORY="Development & Applications"

# AFTER:
PRIMARY_CATEGORY="System & Operations"
```

**Invocation:**
```
@cli-manager review .category.conf files
@cli-manager fix category naming in scripts/cli-tools/
@cli-manager validate category configuration
```

---

### Configuration Management Playbooks

#### 1. config-audit.yml
**Purpose:** Run comprehensive configuration compliance audit

**When to use:**
- Auditing all scripts for config violations
- Generating compliance reports
- Identifying hard-coded paths
- Detecting missing config sourcing

**Steps:**
1. Run validation script: `./scripts/test/validate_config_usage.sh`
2. Parse results (3 report formats: summary, violations, detailed)
3. Prioritize violations by severity (Critical → High → Medium)
4. Generate remediation action plan
5. Output findings with line numbers and examples

**Invocation:**
```
@cli-manager audit config compliance
@cli-manager run config audit on scripts/security/
```

---

#### 2. config-fix.yml
**Purpose:** Auto-fix safe configuration violations

**When to use:**
- Fixing missing config source statements
- Replacing hard-coded paths with config variables
- Removing duplicate variable definitions
- Batch fixing safe violations

**Auto-Fix Patterns:**

**Pattern 1: Add Missing Config Source**
```bash
# Add after set -euo pipefail:
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "${PROJECT_ROOT}/axon-menu.conf"
```

**Pattern 2: Replace Hard-Coded Paths**
```bash
# BEFORE (wrong):
REPORTS="/Users/luce/axon-menu/reports"

# AFTER (correct):
mkdir -p "${REPORTS_DIR}"  # Uses config variable
```

**Pattern 3: Use Config Variables for Libraries**
```bash
# BEFORE (wrong):
source "./scripts/lib/common.sh"

# AFTER (correct):
source "${LIB_DIR}/common.sh"
```

**Safety:**
- Conservative fixes only (obvious patterns)
- Backups created before modification
- Syntax validation with `bash -n` after each fix
- Complex cases flagged for manual review

**Invocation:**
```
@cli-manager fix config violations in scripts/security/
@cli-manager auto-fix safe config issues
```

---

#### 3. config-review.yml
**Purpose:** Review single script for configuration compliance

**When to use:**
- Reviewing a specific script
- Pre-commit validation
- Inline compliance checking
- Before submitting PRs

**Checks:**
1. ✓ Sources axon-menu.conf
2. ✓ No hard-coded paths
3. ✓ No duplicate variables
4. ✓ Uses LIB_DIR for libraries
5. ✓ Uses 200+ available config variables

**Output:**
- Line-by-line compliance analysis
- Specific violations with line numbers
- Before/after fix examples
- Validation commands to run

**Invocation:**
```
@cli-manager review scripts/network/check_dns.sh for config issues
@cli-manager check config compliance for script.sh
```

---

### Script Review & Fix Playbooks

#### 4. review_and_fix.yml (Entrypoint)
**Purpose:** Comprehensive script review and fix workflow

**When to use:**
- Reviewing existing scripts
- Standards compliance checking
- Identifying and fixing bugs
- Pre-commit validation

**Steps:**
1. Read target script
2. Run static analysis (shfmt, shellcheck, bash -n)
3. Check configuration compliance
4. Identify standards violations
5. Apply conservative auto-fixes
6. Generate test suite (if missing)
7. Validate fixes
8. Generate unified diff patch
9. Provide acceptance checklist

**Invocation:**
```
@cli-manager review and fix scripts/security/analyze_firewall.sh
@cli-manager review script.sh
```

---

## Checklists

Validation checklists for ensuring quality and compliance.

**Location:** `.claude/agents/cli-manager/checklists/`

### 0. category-config-checklist.yml
**Purpose:** Quick validation checklist for .category.conf files

**Use this checklist when:**
- Creating new .category.conf files
- Modifying existing category configurations
- Reviewing category metadata for accuracy
- Before committing category changes
- Debugging dynamic menu display issues

**Quick Validation:**

**Required Fields:**
- [ ] CATEGORY_NAME defined (3-8 words, no technical prefixes)
- [ ] PRIMARY_CATEGORY defined (System & Operations / Development & Applications / Network & Media)
- [ ] CATEGORY_DESCRIPTION defined (2-4 sentences, accurate)
- [ ] CATEGORY_ICON defined (single emoji)
- [ ] CATEGORY_ORDER defined (numeric)
- [ ] CATEGORY_ENABLED defined (true/false)

**Red Flags 🚨:**
- ❌ CATEGORY_NAME contains "OS:" or similar prefix
- ❌ CATEGORY_DESCRIPTION is generic or placeholder
- ❌ PRIMARY_CATEGORY is invalid
- ⚠️  Description doesn't match directory content
- ⚠️  CATEGORY_DETAILS references non-existent directories

**Green Lights ✅:**
- ✅ Clear, descriptive CATEGORY_NAME
- ✅ Comprehensive 3-4 sentence CATEGORY_DESCRIPTION
- ✅ Accurate CATEGORY_DETAILS documentation
- ✅ Appropriate PRIMARY_CATEGORY grouping
- ✅ Menu displays correctly, preview pane helpful

**Validation Commands:**
```bash
# Syntax check
source scripts/<category>/.category.conf && echo $CATEGORY_NAME

# Discovery test
find scripts -maxdepth 2 -name ".category.conf" -exec grep -H "^CATEGORY_NAME=" {} \;

# Index rebuild and menu test
rm -f ~/.cache/axon-menu/script-index.txt && ./menu.sh
```

---

### 1. pre-commit-checklist.yml
**Purpose:** Must-pass checks before committing code

**Critical Checks:**

#### Configuration Management (ZERO TOLERANCE)
- [ ] Script sources axon-menu.conf
- [ ] No hard-coded paths
- [ ] No duplicate variables
- [ ] Uses config variables (LIB_DIR, REPORTS_DIR, etc.)

#### Script Standards
- [ ] Proper shebang: `#!/usr/bin/env bash`
- [ ] Error handling: `set -euo pipefail`
- [ ] Header with description
- [ ] Functions use snake_case
- [ ] Variables quoted: `"${var}"`

#### Validation Commands
```bash
bash -n script.sh                              # Syntax check
./scripts/test/validate_config_usage.sh        # Config compliance
shellcheck script.sh                           # Static analysis
```

#### Red Flags 🚨
- Hard-coded user paths: `/Users/luce/...`
- Relative library sourcing: `source ./lib/common.sh`
- Missing config source
- Unquoted variables
- No error handling

#### Green Lights ✅
- Sources axon-menu.conf properly
- Uses config variables consistently
- Passes all validation checks
- Follows all standards

**When to use:**
- Before every commit
- Before creating PRs
- During code reviews
- CI/CD integration

---

### 2. script-review-checklist.yml
**Purpose:** Comprehensive review checklist for scripts

**Sections:**

#### 1. Configuration Management (CRITICAL)
- [ ] Sources axon-menu.conf
- [ ] No hard-coded paths
- [ ] Uses available config variables
- [ ] No variable duplication

#### 2. Script Standards
- [ ] Proper bootstrap (shebang, set -euo pipefail)
- [ ] Header documentation
- [ ] Naming conventions (snake_case functions, UPPER_CASE globals)
- [ ] Proper indentation (4 spaces)

#### 3. Error Handling
- [ ] Uses error_exit() for failures
- [ ] Validates inputs
- [ ] Checks command existence
- [ ] Proper trap cleanup

#### 4. Functionality
- [ ] Logic is correct
- [ ] Edge cases handled
- [ ] Dependencies checked
- [ ] Works on target platform

#### 5. Security
- [ ] No secrets in code
- [ ] Input validation
- [ ] Path validation (validate_path)
- [ ] Secure temp file handling

#### 6. Testing
- [ ] Unit tests exist (bats)
- [ ] Tests pass
- [ ] Coverage adequate
- [ ] Integration tested

---

## Templates

Production-ready templates for common script types.

**Location:** `.claude/agents/cli-manager/templates/`

### 1. script-template.sh
**Purpose:** Standard Axon Menu script template

**Complete Production Template:**

```bash
#!/usr/bin/env bash
################################################################################
# script_name.sh - Brief description of what this script does
#
# Detailed description explaining the purpose, inputs, outputs, and behavior.
# Include usage examples if applicable.
#
# Usage: script_name.sh [OPTIONS] [ARGUMENTS]
#
# Options:
#   -h, --help      Show this help message
#   -v, --verbose   Enable verbose output
#
# PERFORMANCE PROFILE:
# - Parallelization: 8 cores (CPU-bound) / 16 jobs (I/O-bound)
# - GPU Acceleration: Yes/No
# - Expected speedup: Nx vs serial
# - Memory: ~XGB peak
#
# Version: 1.0.0
# Author: Axon Menu System
# Date: YYYY-MM-DD
################################################################################

set -euo pipefail

# Source configuration (REQUIRED)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "${PROJECT_ROOT}/axon-menu.conf"
source "${LIB_DIR}/common.sh"

# AXON Metadata (for discovery)
# AXON: PHASE=X CATEGORY=CategoryName TAG=tag1,tag2,tag3

################################################################################
# Global Variables
################################################################################

readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly SCRIPT_VERSION="1.0.0"

################################################################################
# Functions
################################################################################

# Show usage information
show_usage() {
    cat << EOF
Usage: ${SCRIPT_NAME} [OPTIONS] [ARGUMENTS]

Description of what this script does.

Options:
    -h, --help      Show this help message
    -v, --verbose   Enable verbose output

Examples:
    ${SCRIPT_NAME}                    # Basic usage
    ${SCRIPT_NAME} -v arg1 arg2      # With arguments

EOF
}

# Cleanup function (called on EXIT via trap)
cleanup() {
    local exit_code=$?
    # Cleanup temporary files, restore state, etc.
    exit "$exit_code"
}

# Main script logic
main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_usage
                exit 0
                ;;
            -v|--verbose)
                set -x
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    print_header "Script Name - Version ${SCRIPT_VERSION}"

    # Validate prerequisites
    check_command "required_command" || error_exit "required_command not found"

    # Create temp directory
    local temp_dir
    temp_dir=$(create_temp_dir) || error_exit "Cannot create temp directory"

    # Main script logic here
    print_info "Doing something..."

    print_success "Script completed successfully"
}

################################################################################
# Entry Point
################################################################################

# Set up cleanup trap
trap cleanup EXIT INT TERM

# Run main function
main "$@"
```

**Key Features:**
- Complete header with usage and performance profile
- Proper config sourcing pattern
- AXON metadata for discovery
- Error handling with error_exit()
- Cleanup trap
- Argument parsing
- Uses config variables
- Help message
- Version tracking

---

### 2. config-fix-examples.md
**Purpose:** Quick reference for common fix patterns

**10 Common Violation Patterns:**

| # | Violation | Fix |
|---|-----------|-----|
| 1 | `LOG_DIR="/tmp/axon-menu"` | Use `${LOG_DIR}` from config |
| 2 | `cd "/Users/luce/axon-menu"` | Use `cd "${PROJECT_ROOT}"` |
| 3 | `REPORTS="${HOME}/reports"` | Use `${REPORTS_DIR}` |
| 4 | `source "./lib/common.sh"` | Use `source "${LIB_DIR}/common.sh"` |
| 5 | Creating `NEW_VAR="value"` | Add to axon-menu.conf first |
| 6 | `~/Library/Logs/axon.log` | Use `${LOG_FILE}` |
| 7 | `/opt/homebrew/bin/brew` | Use `${HOMEBREW_BIN}/brew` |
| 8 | `PROJECT_ROOT="$HOME/axon"` (duplicate) | Remove, use from config |
| 9 | `TEMP_DIR=/tmp` | Use `${TEMP_DIR}` |
| 10 | Relative paths to scripts | Use `${SCRIPTS_DIR}/category/script.sh` |

**Validation After Fix:**
```bash
bash -n script.sh                              # Syntax check
./scripts/test/validate_config_usage.sh        # Config compliance
shellcheck script.sh                           # Lint check
```

---

## Examples

Common workflow examples and invocations.

### Example 0: Review and Fix Category Configuration
```bash
@cli-manager review .category.conf files
```

**Scenario:**
User reports: "My menu shows 'OS: MacOS (2)' and 'OS: Linux (00)' - what does that mean?"

**Workflow:**
1. **Discovery** — Find all .category.conf files
2. **Analysis** — Read each config, identify issues:
   - scripts/cli-tools/.category.conf → `CATEGORY_NAME="OS: Linux"`
   - scripts/gui-apps/.category.conf → `CATEGORY_NAME="OS: MacOS"`
   - scripts/os-windows/.category.conf → `CATEGORY_NAME="OS: Windows"`
3. **Diagnosis** — Technical prefixes causing confusing display
4. **Fix** — Rename categories:
   - "OS: Linux" → "Modern CLI Tools"
   - "OS: MacOS" → "macOS GUI & System"
   - "OS: Windows" → "Windows PowerShell"
5. **Update** — Revise descriptions to match content
6. **Validate** — Syntax check, rebuild index, test menu
7. **Report** — Generate comprehensive fix report

**Result:**
- Clear, descriptive category names
- Accurate preview pane metadata
- Improved user experience
- Menu displays: "Modern CLI Tools (40)", "macOS GUI & System (150+)"

**Reference:** `docs/reports/CATEGORY_FIX_2025-10-29.md`

---

### Example 1: Audit All Scripts
```bash
@cli-manager audit config compliance
```

**Output:**
- Total scripts audited
- Violation counts by severity (Critical, High, Medium)
- Detailed findings with line numbers
- Remediation action plan
- 3 report files generated

---

### Example 2: Fix Configuration Violations
```bash
@cli-manager fix config violations in scripts/security/
```

**Actions:**
- Identifies safe fix patterns
- Adds missing config sourcing
- Replaces hard-coded paths with config variables
- Removes duplicate variable definitions
- Creates backups before modification
- Validates syntax after fixes

---

### Example 3: Review Single Script
```bash
@cli-manager review scripts/network/check_dns.sh for config issues
```

**Output:**
- Line-by-line compliance analysis
- Specific violations with line numbers
- Before/after code examples
- Suggested fixes
- Validation commands

---

### Example 4: Comprehensive Script Review
```bash
@cli-manager review and fix scripts/security/analyze_firewall.sh
```

**Workflow:**
1. Static analysis (shfmt, shellcheck, bash -n)
2. Configuration compliance check
3. Standards validation
4. Auto-fix safe issues
5. Generate/update tests
6. Provide unified diff
7. Acceptance checklist

---

### Example 5: Pre-Commit Validation
```bash
@cli-manager validate script.sh before commit
```

**Checks:**
- Configuration compliance
- Coding standards
- Syntax validation
- Security review
- Test coverage

---

## Changelog

### [2.1.0] - 2025-10-29

#### 🎉 Major Addition: Category Configuration Management

Added comprehensive category configuration management capabilities to review and fix `.category.conf` files for the dynamic menu system.

**New Capabilities:**
1. Review and validate .category.conf files
2. Detect naming inconsistencies and confusing prefixes
3. Audit description accuracy against directory content
4. Validate PRIMARY_CATEGORY grouping
5. Auto-fix category naming and metadata issues
6. Generate category fix reports

**New Files:**

**Playbooks:**
- `category-config-review.yml` — Comprehensive .category.conf review workflow
  - Naming consistency validation
  - Description accuracy checks
  - PRIMARY_CATEGORY grouping validation
  - Common fix patterns documented
  - Testing and reporting workflow

**Checklists:**
- `category-config-checklist.yml` — Quick validation checklist for category configs
  - Required fields validation
  - Red flags and green lights identification
  - Validation commands
  - Common fix examples

**Documentation:**
- Updated `PLAYBOOK_LIBRARY.md` with category management section
- Added Example 0 showing real-world category fix workflow
- Reference implementation: `docs/reports/CATEGORY_FIX_2025-10-29.md`

**Common Issues Fixed:**
- Technical prefixes in category names (OS:, PHASE:, TYPE:)
- Generic or outdated descriptions
- Wrong PRIMARY_CATEGORY grouping
- Outdated CATEGORY_DETAILS references
- Missing or incomplete metadata

**Integration:**
- Natural language commands: "@cli-manager review .category.conf files"
- Workflow: discovery → analysis → fix → validate → report
- Index rebuild automation for testing
- Menu display validation

**Impact:**
- User experience: Clear, descriptive category names in menus
- Consistency: Standardized naming conventions
- Accuracy: Preview pane shows current, helpful information
- Maintainability: Documentation matches reality

**Reference Fix:**
- Fixed 3 malformed categories (cli-tools, gui-apps, os-windows)
- "OS: Linux" → "Modern CLI Tools" (40 utilities)
- "OS: MacOS" → "macOS GUI & System" (150+ utilities)
- "OS: Windows" → "Windows PowerShell" (1 utility)

---

### [2.0.0] - 2025-10-27

#### 🎉 Major Addition: Configuration Management Enforcement

Added comprehensive configuration management capabilities to enforce `axon-menu.conf` as the single source of truth.

**New Capabilities:**
1. Audit configuration management compliance
2. Detect hard-coded paths and missing config sourcing
3. Auto-fix configuration violations (safe, conservative)
4. Validate scripts against 200+ available config variables
5. Generate configuration compliance reports with remediation steps

**New Files:**

**Playbooks:**
- `config-audit.yml` — Configuration compliance audit
- `config-fix.yml` — Auto-fix violations
- `config-review.yml` — Script review for config compliance

**Checklists:**
- `pre-commit-checklist.yml` — Pre-commit configuration validation
- `script-review-checklist.yml` — Comprehensive review checklist

**Templates:**
- `script-template.sh` — Standard script template with proper config sourcing
- `config-fix-examples.md` — Fix pattern examples

**Documentation:**
- Updated `cli-manager.md` with configuration management section
- Added `docs/CONFIG_MANAGEMENT_ENFORCEMENT.md` (400 lines)
- Created validation script: `scripts/test/validate_config_usage.sh` (550 lines)

**Integration Features:**
- Natural language commands for config management
- Workflow integration (authoring → review → commit → audit)
- 3 report formats (summary, violations, detailed)
- Safety features (conservative fixes, backups, syntax validation)

**Impact:**
- Code quality: Enforced consistency across 247+ scripts
- Maintainability: Centralized configuration management
- Portability: No hard-coded user-specific paths
- Onboarding: Clear standards for new contributors

---

### [1.0.0] - 2025-10-26

#### Initial Release

- Bash scripting specialist capabilities
- Script review and standards compliance
- Autonomous bug fixing
- Test execution and validation
- Error debugging and resolution

---

## References

**Configuration Management:**
- Enforcement Guide: `docs/CONFIG_MANAGEMENT_ENFORCEMENT.md`
- Config File: `axon-menu.conf` (1,828 lines, 16 sections, 200+ variables)
- Guidelines: `CLAUDE.md` (lines 63-255)
- Validation Script: `scripts/test/validate_config_usage.sh`

**Agent Documentation:**
- Agent Manifest: `.claude/agents/cli-manager.md`
- Playbooks Directory: `.claude/agents/cli-manager/playbooks/`
- Checklists Directory: `.claude/agents/cli-manager/checklists/`
- Templates Directory: `.claude/agents/cli-manager/templates/`

**External Resources:**
- Google Shell Style Guide: https://google.github.io/styleguide/shellguide.html
- Bash Hackers Wiki: https://wiki.bash-hackers.org/
- Defensive BASH Programming: http://www.kfirlavi.com/blog/2012/11/14/defensive-bash-programming/

---

**Maintained by:** CLI Manager Agent
**Version:** 2.0.0
**Status:** Production Ready
