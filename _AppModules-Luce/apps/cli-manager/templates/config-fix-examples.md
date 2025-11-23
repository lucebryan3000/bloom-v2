---
name: config-fix-examples
description: Configuration violation fix patterns and examples
---

# Configuration Violation Fix Examples

Common patterns and how to fix them.

## Pattern 1: Missing Config Source

### BEFORE (Violation)
```bash
#!/usr/bin/env bash
set -euo pipefail

# Script starts without sourcing config
LOG_FILE="/tmp/axon-menu/script.log"
```

### AFTER (Fixed)
```bash
#!/usr/bin/env bash
set -euo pipefail

# Source configuration (REQUIRED)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "${PROJECT_ROOT}/axon-menu.conf"

# Now LOG_DIR is available from config
LOG_FILE="${LOG_DIR}/script.log"
```

---

## Pattern 2: Hard-Coded TEMP_DIR

### BEFORE (Violation)
```bash
# Hard-coded temporary directory
TEMP_DIR="/tmp/axon-menu"
mkdir -p "$TEMP_DIR"
temp_file="${TEMP_DIR}/processing.tmp"
```

### AFTER (Fixed)
```bash
# Config already sourced, TEMP_DIR available
mkdir -p "${TEMP_DIR}"
temp_file="${TEMP_DIR}/processing.tmp"
```

---

## Pattern 3: Hard-Coded REPORTS_DIR

### BEFORE (Violation)
```bash
# Hard-coded reports path
REPORTS_DIR="${HOME}/axon-menu/reports"
output_file="${REPORTS_DIR}/report.txt"
```

### AFTER (Fixed)
```bash
# Config already sourced, REPORTS_DIR available
output_file="${REPORTS_DIR}/report.txt"
```

---

## Pattern 4: Hard-Coded Project Path

### BEFORE (Violation)
```bash
# Hard-coded full project path
cd "/Users/luce/Library/Mobile Documents/com~apple~CloudDocs/_dev-iCloud/axon-menu"
./scripts/utils/helper.sh
```

### AFTER (Fixed)
```bash
# Use PROJECT_ROOT from config
cd "${PROJECT_ROOT}"
"${SUPPORT_DIR}/utils/helper.sh"
```

---

## Pattern 5: Relative Path to Libraries

### BEFORE (Violation)
```bash
# Relative path to library
source "./scripts/lib/common.sh"
source "../lib/common.sh"
source "$(dirname "$0")/../lib/common.sh"
```

### AFTER (Fixed)
```bash
# Use LIB_DIR from config
source "${LIB_DIR}/common.sh"
```

---

## Pattern 6: Hard-Coded LOG_DIR

### BEFORE (Violation)
```bash
# Hard-coded log directory
LOG_DIR="$HOME/Library/Logs/axon-menu"
mkdir -p "$LOG_DIR"
echo "Log entry" >> "${LOG_DIR}/script.log"
```

### AFTER (Fixed)
```bash
# Config already sourced, LOG_DIR available
mkdir -p "${LOG_DIR}"
echo "Log entry" >> "${LOG_FILE}"  # Or use LOG_FILE directly
```

---

## Pattern 7: Redefining Config Variable

### BEFORE (Violation)
```bash
# Sourced config, but then redefines variable
source "${PROJECT_ROOT}/axon-menu.conf"

# DON'T DO THIS - redefinition
REPORTS_DIR="/tmp/my-reports"
```

### AFTER (Fixed)
```bash
# Sourced config, just use the variable
source "${PROJECT_ROOT}/axon-menu.conf"

# Use it directly, don't redefine
output="${REPORTS_DIR}/my-report.txt"
```

---

## Pattern 8: Creating Variable That Should Be in Config

### BEFORE (Violation)
```bash
# Creating new directory variable in script
BACKUP_DIR="${HOME}/axon-backups"
mkdir -p "$BACKUP_DIR"
```

### AFTER (Fixed)
```bash
# Option 1: Add to axon-menu.conf
# In axon-menu.conf:
# BACKUP_DIR="${PROJECT_ROOT}/backups"

# In script:
source "${PROJECT_ROOT}/axon-menu.conf"
mkdir -p "${BACKUP_DIR}"

# Option 2: Derive from existing config variable
BACKUP_DIR="${WORK_DIR}/backups"
mkdir -p "$BACKUP_DIR"
```

---

## Pattern 9: Editor Path Hard-Coded

### BEFORE (Violation)
```bash
# Hard-coded editor paths
EDITOR="/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl"
"$EDITOR" myfile.txt
```

### AFTER (Fixed)
```bash
# Use DEFAULT_EDITOR and SUBLIME_PATH from config
if [[ "${DEFAULT_EDITOR}" == "subl" ]]; then
    "${SUBLIME_PATH}" myfile.txt
fi
```

---

## Pattern 10: Homebrew Path Hard-Coded

### BEFORE (Violation)
```bash
# Hard-coded Homebrew paths
if [[ -f "/opt/homebrew/bin/fzf" ]]; then
    /opt/homebrew/bin/fzf
fi
```

### AFTER (Fixed)
```bash
# Use HOMEBREW_PREFIX from config (auto-detected)
if [[ -f "${HOMEBREW_BIN}/fzf" ]]; then
    "${HOMEBREW_BIN}/fzf"
fi
```

---

## Complete Example: Before vs After

### BEFORE (Multiple Violations)
```bash
#!/usr/bin/env bash
set -euo pipefail

# Missing config source
# Creating own variables
REPORTS_DIR="/Users/luce/axon-menu/reports"
TEMP_DIR="/tmp/axon-menu"
LOG_FILE="/var/log/axon-menu/script.log"

# Using relative paths
source "./scripts/lib/common.sh"

# Main logic
mkdir -p "$REPORTS_DIR" "$TEMP_DIR"
echo "Starting..." >> "$LOG_FILE"

output_file="${REPORTS_DIR}/output.txt"
echo "Results" > "$output_file"
```

### AFTER (Fully Compliant)
```bash
#!/usr/bin/env bash
set -euo pipefail

# Source configuration (REQUIRED)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "${PROJECT_ROOT}/axon-menu.conf"

# Source libraries
source "${LIB_DIR}/common.sh"

# Main logic - all variables from config
mkdir -p "${REPORTS_DIR}" "${TEMP_DIR}"
echo "Starting..." >> "${LOG_FILE}"

output_file="${REPORTS_DIR}/output.txt"
echo "Results" > "$output_file"
```

---

## Quick Reference: Variable Substitutions

| Hard-Coded | Use Instead |
|-----------|-------------|
| `/tmp/axon-menu` | `${TEMP_DIR}` |
| `$HOME/Library/Logs/axon-menu` | `${LOG_DIR}` |
| `${SCRIPT_DIR}/reports` | `${REPORTS_DIR}` |
| `${SCRIPT_DIR}/scripts` | `${SUPPORT_DIR}` |
| `${SCRIPT_DIR}/scripts/lib` | `${LIB_DIR}` |
| `${SCRIPT_DIR}/config` | `${CONFIG_DIR}` |
| `./lib/common.sh` | `${LIB_DIR}/common.sh` |
| `/opt/homebrew` or `/usr/local` | `${HOMEBREW_PREFIX}` |
| Full project path | `${PROJECT_ROOT}` |

---

## Validation After Fix

Always validate after applying fixes:

```bash
# 1. Syntax check
bash -n script.sh

# 2. Verify config sourcing
grep -n "source.*axon-menu.conf" script.sh

# 3. Check for remaining violations
./scripts/test/validate_config_usage.sh

# 4. Test the script
./script.sh --dry-run  # If it has dry-run mode
```

---

## Notes

- **Always backup before fixing:** `cp script.sh script.sh.bak`
- **Fix one pattern at a time:** Easier to debug if something breaks
- **Validate after each fix:** Don't batch fixes without testing
- **Be conservative:** When in doubt, ask for manual review

---

**Remember:** axon-menu.conf provides 200+ variables. Check it before creating new ones!
