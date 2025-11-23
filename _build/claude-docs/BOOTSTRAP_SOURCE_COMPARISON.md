# Bootstrap Source Comparison: scripts/bootstrap/ vs _build/bootstrap_scripts/

**Status**: Comparison Analysis
**Date**: 2025-11-22 23:45 UTC

---

## 🎯 Quick Answer

**YES - `scripts/bootstrap/` has important logic we DON'T have in `_build/bootstrap_scripts/`:**

| Feature | scripts/bootstrap/ | _build/bootstrap_scripts/ |
|---------|---|---|
| Interactive first-run prompts | ✅ YES (lines 22-60) | ❌ NO |
| JSON logging support | ✅ YES (_log_json function) | ❌ NO |
| `_init_config()` function | ✅ YES (comprehensive) | ❌ NO |
| `clear_script_state()` | ✅ YES | ❌ NO |
| `ensure_file_contains()` | ✅ YES | ❌ NO |
| `write_file_if_missing()` | ✅ YES | ❌ NO |
| `_ensure_log_dir()` | ✅ YES (safer) | ❌ NO |
| `_prompt_config_value()` | ✅ YES (interactive) | ❌ NO |

---

## 📊 Detailed Function Comparison

### scripts/bootstrap/lib/common.sh (442 lines)
**Has these 26 functions:**
1. `_prompt_config_value()` - Interactive config prompts ✅
2. `_init_config()` - First-run setup with prompting ✅
3. `apply_stack_profile()` - Feature flag profiles ✅
4. `_ensure_log_dir()` - Safe log directory creation ✅
5. `_log_plain()` - Plain text logging ✅
6. `_log_json()` - JSON logging support ✅
7. `log_info()` - Info level log
8. `log_warn()` - Warn level log
9. `log_error()` - Error level log
10. `log_success()` - Success level log
11. `run_cmd()` - Command execution with timeout
12. `require_cmd()` - Check if command exists
13. `check_tool_versions()` - Version validation
14. `ensure_git_clean()` - Git safety checks ✅
15. `init_state_file()` - Initialize state tracking
16. `mark_script_success()` - Mark script completion
17. `has_script_succeeded()` - Check script state
18. `clear_script_state()` - Reset state tracking ✅
19. `parse_common_args()` - Argument parsing
20. `ensure_dir()` - Create directory
21. `ensure_file_contains()` - Ensure file has content ✅
22. `write_file_if_missing()` - Create file if missing ✅
23. `add_dependency()` - Install npm package
24. `add_npm_script()` - Add npm script
25. **Missing**: OS detection (but at module level)
26. **Missing**: Dedicated color constants

---

### _build/bootstrap_scripts/lib/common.sh (590 lines)
**Has these 31 functions (includes extras we added):**
1. `OS_TYPE` detection at module level ✅ (NEW - we added)
2. Color constants defined ✅
3. `init_logging()` - Initialize logging ✅ (NEW)
4. `_log()` - Internal logging with colors ✅
5. `log_info()` - Info level log
6. `log_warn()` - Warn level log
7. `log_error()` - Error level log
8. `log_debug()` - Debug level log ✅
9. `log_step()` - Step logging ✅
10. `log_skip()` - Skip logging ✅
11. `log_success()` - Success logging
12. `log_dry()` - Dry-run logging ✅
13. `run_cmd()` - Enhanced with timeout ✅
14. `require_cmd()` - Check command
15. `require_node_version()` - Node version check ✅
16. `require_pnpm()` - pnpm requirement ✅
17. `require_docker()` - Docker requirement ✅
18. `require_file()` - File requirement ✅
19. `require_project_root()` - Project check ✅
20. `init_state_file()` - State tracking ✅ (we added)
21. `mark_script_success()` - Mark completion ✅ (we added)
22. `has_script_succeeded()` - Check state ✅ (we added)
23. `apply_stack_profile()` - Feature profiles ✅ (we added)
24. `ensure_git_clean()` - Git safety ✅ (we added)
25. `parse_common_args()` - Arg parsing
26. `ensure_dir()` - Create directory
27. `write_file()` - Write file with options
28. `append_file()` - Append to file
29. `add_gitkeep()` - Add .gitkeep
30. `get_script_dir()` - Get script path
31. `get_project_root()` - Get project root

---

## ✅ What We Have That scripts/bootstrap/ DOESN'T

Our `_build/bootstrap_scripts/` has better:

1. **Logging functions** (more options):
   - Color-coded logging
   - log_debug(), log_step(), log_skip(), log_dry()
   - Better formatted output

2. **Requirement checks** (more specific):
   - `require_node_version()` - Version validation
   - `require_pnpm()` - Specific tool check
   - `require_docker()` - Docker check
   - `require_file()` - File existence check
   - `require_project_root()` - Project validation

3. **File operations** (more robust):
   - `write_file()` with options (force, dry-run)
   - `append_file()` with dry-run support
   - `add_gitkeep()` for directories

4. **Core functions** (new):
   - OS_TYPE detection at module level
   - Enhanced run_cmd() with timeout support
   - Better structured error handling

---

## ❌ What scripts/bootstrap/ Has That We DON'T

Our `_build/bootstrap_scripts/` is MISSING:

### 1. **Interactive First-Run Configuration** (Lines 22-60)
```bash
_prompt_config_value() {
    local var_name="$1"
    local prompt_text="$2"
    local default_val="$3"
    local new_val

    if [[ "${NON_INTERACTIVE:-false}" == "true" ]]; then
        return 0
    fi

    read -rp "${prompt_text} [${default_val}]: " new_val
    if [[ -n "${new_val}" ]]; then
        sed -i.bak "s|^${var_name}=.*|${var_name}=\"${new_val}\"|" "${BOOTSTRAP_CONF}"
        rm -f "${BOOTSTRAP_CONF}.bak"
    fi
}
```
**Impact**: User can't interactively customize APP_NAME, PROJECT_ROOT, DB credentials on first run

### 2. **Comprehensive _init_config() Function** (Lines 39-90)
- Auto-copies .example → .conf
- Shows "=== First-Run Configuration ===" prompt
- Calls _prompt_config_value() for each setting
- Validates critical values in NON_INTERACTIVE mode
- Sets defaults for optional vars
- Detects OS

**Impact**: First-time users get guided experience, not silent config copy

### 3. **JSON Logging Support** (_log_json function, lines 147-152)
```bash
_log_json() {
    local level="$1"
    shift
    local script_name="${0##*/}"
    # Outputs structured JSON with timestamp, level, script, message
}
```
**Impact**: CI/machine parsing impossible without JSON logs

### 4. **clear_script_state() Function**
Allows resetting individual script state without deleting whole .bootstrap_state

**Impact**: Can't selectively reset scripts

### 5. **Utility Functions for Files**
- `ensure_file_contains()` - Check/add content to file
- `write_file_if_missing()` - Create file only if missing

**Impact**: Less flexible file manipulation

---

## 🔄 Recommendation: Merge the Best of Both

Since `_build/bootstrap_scripts/` is now our source of truth, we should add the missing pieces from `scripts/bootstrap/`:

### Priority 1: Critical (DO THIS FIRST)
```bash
# Add to _build/bootstrap_scripts/lib/common.sh:
✅ _prompt_config_value() - interactive prompts
✅ _init_config() - comprehensive first-run
✅ _log_json() - JSON logging support
✅ clear_script_state() - reset individual scripts
```

### Priority 2: Nice to Have
```bash
# Add to _build/bootstrap_scripts/lib/common.sh:
- ensure_file_contains() - file content checking
- write_file_if_missing() - conditional file creation
- Better _ensure_log_dir() logic
```

### Priority 3: Verify Compatibility
- Ensure both run-bootstrap.sh implementations work with merged common.sh
- Ensure all 35 scripts in tech_stack still work

---

## 📋 Implementation Plan

To make `_build/bootstrap_scripts/` the definitive source:

1. **Add interactive config prompts** to common.sh:
   - `_prompt_config_value()` (from scripts/bootstrap/)
   - `_init_config()` (from scripts/bootstrap/)
   - Integrate with load_config() in run-bootstrap.sh

2. **Add JSON logging** to common.sh:
   - `_log_json()` (from scripts/bootstrap/)
   - Update logging calls to support LOG_FORMAT="json"

3. **Add state management** to common.sh:
   - `clear_script_state()` (from scripts/bootstrap/)
   - Use in run-bootstrap.sh --reset command

4. **Add file utilities** to common.sh:
   - `ensure_file_contains()` (from scripts/bootstrap/)
   - `write_file_if_missing()` (from scripts/bootstrap/)

5. **Verify compatibility**:
   - Run all 35 scripts with merged common.sh
   - Ensure run-bootstrap.sh still works
   - Test with scripts/bootstrap/lib/common.sh still being the "other" version

---

## 📊 Side-by-Side Metrics

| Metric | scripts/bootstrap/ | _build/bootstrap_scripts/ | Better |
|--------|---|---|---|
| Total lines | 442 | 590 | _build (more features) |
| Functions | 26 | 31 | _build (5 more) |
| Logging formats | Plain + JSON | Plain + colors + more levels | _build |
| Config prompts | ✅ Interactive | ❌ None | scripts/bootstrap |
| State management | ✅ Full | ✅ Full | Tied |
| File operations | Basic | ✅ Advanced | _build |
| Error handling | Basic | ✅ Enhanced | _build |
| Documentation | Minimal | ✅ Good | _build |

---

## 🎯 Decision

**DIRECTION**: _build/bootstrap_scripts is source of truth ✅

**ACTION NEEDED**: Merge the 4 missing functions from scripts/bootstrap/ into _build/bootstrap_scripts/lib/common.sh:
1. `_prompt_config_value()` - CRITICAL
2. `_init_config()` - CRITICAL
3. `_log_json()` - IMPORTANT
4. `clear_script_state()` - NICE TO HAVE

This will make _build/bootstrap_scripts/ the complete, best-of-both-worlds implementation.

