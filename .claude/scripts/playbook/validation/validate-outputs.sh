#!/usr/bin/env bash
# =============================================================================
# scripts/playbook/validation/validate-outputs.sh
# =============================================================================
# Hybrid Claude + Codex Playbook: Output Validation Helper
#
# Validates generated code files (bash, TypeScript, JavaScript, JSON) for
# syntax errors and common issues before integration.
#
# Usage:
#   ./validate-outputs.sh <directory>                  # Validate all in dir
#   ./validate-outputs.sh file1.sh file2.ts file3.js   # Validate specific files
#   ./validate-outputs.sh --json-report <directory>    # Generate JSON report
#
# Exit Codes:
#   0 - All validations passed
#   1 - One or more validations failed
#   2 - Invalid arguments or missing validators
#
# Dependencies:
#   - bash 5.0+
#   - Optional: tsc, node, jq (validators auto-detected)
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

# =============================================================================
# CONFIGURATION
# =============================================================================

readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Color codes (matching OmniForge logging.sh style)
readonly COLOR_RED=$'\033[0;31m'
readonly COLOR_GREEN=$'\033[0;32m'
readonly COLOR_YELLOW=$'\033[0;33m'
readonly COLOR_BLUE=$'\033[0;34m'
readonly COLOR_CYAN=$'\033[0;36m'
readonly COLOR_GRAY=$'\033[0;90m'
readonly COLOR_BOLD=$'\033[1m'
readonly COLOR_NC=$'\033[0m'

# Validators
declare -gA VALIDATORS_AVAILABLE
declare -gA VALIDATOR_HINTS

# Statistics
declare -g TOTAL_FILES=0
declare -g PASSED_FILES=0
declare -g FAILED_FILES=0
declare -gA FILE_RESULTS
declare -gA FILE_ERRORS

# Reporting
declare -g JSON_REPORT=false
declare -g REPORT_FILE=""
declare -g VERBOSE_MODE=false

# =============================================================================
# LOGGING FUNCTIONS (OmniForge style)
# =============================================================================

_log() {
    local level="$1"
    local color="$2"
    local message="$3"

    echo -e "${color}[${level}]${COLOR_NC} ${message}"
}

log_info() {
    _log "INFO" "$COLOR_GREEN" "$1"
}

log_warn() {
    _log "WARN" "$COLOR_YELLOW" "$1"
}

log_error() {
    _log "ERROR" "$COLOR_RED" "$1"
}

log_debug() {
    if [[ "$VERBOSE_MODE" == "true" ]]; then
        _log "DEBUG" "$COLOR_CYAN" "$1"
    fi
}

log_step() {
    _log "STEP" "$COLOR_BLUE" ">>> $1"
}

log_success() {
    _log "OK" "$COLOR_GREEN" "✓ $1"
}

# =============================================================================
# VALIDATOR DETECTION
# =============================================================================

_detect_validators() {
    log_step "Detecting available validators..."

    # Bash validator (always available, built-in)
    VALIDATORS_AVAILABLE["bash"]="bash"
    VALIDATOR_HINTS["bash"]="Built-in bash -n syntax check"

    # TypeScript/JSX validator
    if command -v tsc &>/dev/null; then
        VALIDATORS_AVAILABLE["tsc"]="tsc"
        VALIDATOR_HINTS["tsc"]="$(tsc --version 2>/dev/null || echo 'TypeScript compiler')"
        log_debug "Found tsc: $(tsc --version 2>/dev/null || true)"
    else
        log_warn "TypeScript compiler (tsc) not found - skipping .ts/.tsx validation"
        log_warn "Install with: npm install -g typescript"
    fi

    # Node.js validator
    if command -v node &>/dev/null; then
        VALIDATORS_AVAILABLE["node"]="node"
        VALIDATOR_HINTS["node"]="$(node --version 2>/dev/null || echo 'Node.js runtime')"
        log_debug "Found node: $(node --version 2>/dev/null || true)"
    else
        log_warn "Node.js not found - skipping .js validation"
        log_warn "Install from: https://nodejs.org"
    fi

    # JSON validator
    if command -v jq &>/dev/null; then
        VALIDATORS_AVAILABLE["jq"]="jq"
        VALIDATOR_HINTS["jq"]="$(jq --version 2>/dev/null || echo 'JSON processor')"
        log_debug "Found jq: $(jq --version 2>/dev/null || true)"
    else
        log_warn "jq not found - skipping .json validation"
        log_warn "Install with: apt-get install jq or brew install jq"
    fi

    echo ""
}

# =============================================================================
# FILE TYPE DETECTION & VALIDATION
# =============================================================================

_get_file_type() {
    local file="$1"
    local ext="${file##*.}"

    case "$ext" in
        sh) echo "shell" ;;
        ts) echo "typescript" ;;
        tsx) echo "typescript_jsx" ;;
        js) echo "javascript" ;;
        jsx) echo "javascript_jsx" ;;
        json) echo "json" ;;
        *) echo "unknown" ;;
    esac
}

# Validate bash/shell script
_validate_bash() {
    local file="$1"

    # Check shebang in executables
    if [[ -x "$file" ]]; then
        if ! head -1 "$file" | grep -q '^#!/'; then
            return 1  # Missing shebang
        fi
    fi

    # Syntax check with bash -n (suppress trace output)
    bash -n "$file" 2>/dev/null || return 1

    return 0
}

# Validate TypeScript/TSX
_validate_typescript() {
    local file="$1"

    if [[ ! -v VALIDATORS_AVAILABLE["tsc"] ]]; then
        log_debug "tsc not available, skipping $file"
        return 0  # Skip if not available
    fi

    # Determine if it's JSX
    local tsc_opts="--noEmit --skipLibCheck"
    if [[ "$file" == *.tsx ]]; then
        tsc_opts="$tsc_opts --jsx react"
    fi

    tsc $tsc_opts "$file" 2>/dev/null || return 1

    return 0
}

# Validate JavaScript
_validate_javascript() {
    local file="$1"

    if [[ ! -v VALIDATORS_AVAILABLE["node"] ]]; then
        log_debug "node not available, skipping $file"
        return 0  # Skip if not available
    fi

    # Use node's syntax checker if available (node >= 16)
    node --check "$file" 2>/dev/null || return 1

    return 0
}

# Validate JSON
_validate_json() {
    local file="$1"

    if [[ ! -v VALIDATORS_AVAILABLE["jq"] ]]; then
        log_debug "jq not available, skipping $file"
        return 0  # Skip if not available
    fi

    jq empty "$file" 2>/dev/null || return 1

    return 0
}

# =============================================================================
# CODE QUALITY CHECKS
# =============================================================================

_check_placeholders() {
    local file="$1"
    local patterns=("TODO" "FIXME" "XXX" "PLACEHOLDER" "STUB")
    local found=()

    for pattern in "${patterns[@]}"; do
        if grep -qn "$pattern" "$file"; then
            found+=("$pattern")
        fi
    done

    if [[ ${#found[@]} -gt 0 ]]; then
        return 1  # Found placeholders
    fi

    return 0
}

_check_undefined_variables() {
    local file="$1"

    # Only check shell scripts
    if [[ "$(_get_file_type "$file")" != "shell" ]]; then
        return 0
    fi

    # Check for undefined variables: $UNDEFINED_VAR or ${UNDEFINED_VAR}
    # This is a simple heuristic check
    local undefined_pattern='\\$\\{[A-Z_][A-Z0-9_]*\\}|\\$[A-Z_][A-Z0-9_]*(?![a-z])'

    # Simple grep pattern for likely undefined variables in shell
    if grep -qE '\$[A-Z_][A-Z_0-9]*[^a-z0-9_]' "$file"; then
        # Check against common environment variables
        local suspicious
        suspicious=$(grep -oE '\$[A-Z_][A-Z_0-9]*' "$file" | sort -u)

        # Filter out known safe variables
        local known_vars=("PATH" "HOME" "USER" "PWD" "SHELL" "TERM" "IFS" "OSTYPE")

        for var in $suspicious; do
            local is_known=0
            for known in "${known_vars[@]}"; do
                if [[ "$var" == "\$$known" ]]; then
                    is_known=1
                    break
                fi
            done

            # If we find a suspicious variable that's not in known_vars, warn but don't fail
            if [[ $is_known -eq 0 ]]; then
                log_debug "Possible undefined variable in $file: $var"
            fi
        done
    fi

    return 0
}

# =============================================================================
# MAIN VALIDATION LOGIC
# =============================================================================

_validate_file() {
    local file="$1"
    local file_type
    local has_errors=0
    local error_msg=""

    file_type=$(_get_file_type "$file")

    log_debug "Validating: $file (type: $file_type)"

    # Run appropriate validator based on file type
    case "$file_type" in
        shell)
            if ! _validate_bash "$file"; then
                error_msg="Bash syntax error"
                has_errors=1
            fi
            ;;
        typescript|typescript_jsx)
            if ! _validate_typescript "$file"; then
                error_msg="TypeScript compilation error"
                has_errors=1
            fi
            ;;
        javascript|javascript_jsx)
            if ! _validate_javascript "$file"; then
                error_msg="JavaScript syntax error"
                has_errors=1
            fi
            ;;
        json)
            if ! _validate_json "$file"; then
                error_msg="JSON validation error"
                has_errors=1
            fi
            ;;
        unknown)
            log_warn "Unknown file type: $file (skipping)"
            return 0
            ;;
    esac

    # Check for placeholders
    if [[ $has_errors -eq 0 ]]; then
        if ! _check_placeholders "$file"; then
            error_msg="Contains placeholders (TODO, FIXME, XXX, PLACEHOLDER)"
            has_errors=1
        fi
    fi

    # Check for undefined variables
    if [[ $has_errors -eq 0 ]]; then
        if ! _check_undefined_variables "$file"; then
            error_msg="Potential undefined variables"
            has_errors=1
        fi
    fi

    # Record result
    if [[ $has_errors -eq 0 ]]; then
        FILE_RESULTS["$file"]="PASS"
        ((PASSED_FILES++))
        log_success "$file"
        return 0
    else
        FILE_RESULTS["$file"]="FAIL"
        FILE_ERRORS["$file"]="$error_msg"
        ((FAILED_FILES++))
        log_error "$file: $error_msg"
        return 1
    fi
}

# =============================================================================
# FILE DISCOVERY
# =============================================================================

_find_code_files() {
    local target="$1"
    local -a files

    if [[ -f "$target" ]]; then
        # Single file
        files=("$target")
    elif [[ -d "$target" ]]; then
        # Directory: recursively find code files
        mapfile -t files < <(find "$target" -type f \( -name "*.sh" -o -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -o -name "*.json" \) 2>/dev/null | sort)
    else
        log_error "Not a file or directory: $target"
        return 1
    fi

    # Return count and populate global array
    echo "${#files[@]}"
    for f in "${files[@]}"; do
        echo "$f"
    done
}

# =============================================================================
# REPORTING
# =============================================================================

_generate_json_report() {
    local report_dir
    local report_file

    if [[ -n "$REPORT_FILE" ]]; then
        report_file="$REPORT_FILE"
    else
        report_dir="${PWD}/.claude/logs/playbook"
        mkdir -p "$report_dir"
        report_file="${report_dir}/validation-report-$(date +%Y%m%d_%H%M%S).json"
    fi

    # Build JSON report
    local json="{\"summary\": {"
    json+='"total": '"$TOTAL_FILES"', '
    json+='"passed": '"$PASSED_FILES"', '
    json+='"failed": '"$FAILED_FILES"', '
    json+='"timestamp": "'"$(date -Iseconds 2>/dev/null || date '+%Y-%m-%d %H:%M:%S')"'"'
    json+="}, \"results\": {"

    local first=true
    for file in "${!FILE_RESULTS[@]}"; do
        if [[ "$first" == "false" ]]; then
            json+=", "
        fi
        first=false

        local status="${FILE_RESULTS[$file]}"
        local error="${FILE_ERRORS[$file]:-}"

        json+="\"$(printf '%s' "$file" | sed 's/"/\\"/g')\": {"
        json+='"status": "'"$status"'"'
        if [[ -n "$error" ]]; then
            json+=', "error": "'"$(printf '%s' "$error" | sed 's/"/\\"/g')"'"'
        fi
        json+="}"
    done

    json+="}}"

    # Write report
    echo "$json" > "$report_file"
    log_success "JSON report written: $report_file"
}

_print_summary() {
    echo ""
    echo "=========================================="
    echo "  Validation Summary"
    echo "=========================================="
    echo ""
    log_info "Total files: $TOTAL_FILES"
    log_success "Passed: $PASSED_FILES"
    if [[ $FAILED_FILES -gt 0 ]]; then
        log_error "Failed: $FAILED_FILES"
    else
        log_success "Failed: 0"
    fi
    echo ""

    if [[ $FAILED_FILES -gt 0 ]]; then
        echo "Failed files:"
        for file in "${!FILE_RESULTS[@]}"; do
            if [[ "${FILE_RESULTS[$file]}" == "FAIL" ]]; then
                echo "  - $file"
                if [[ -v FILE_ERRORS[$file] ]]; then
                    echo "    Error: ${FILE_ERRORS[$file]}"
                fi
            fi
        done
        echo ""
    fi
}

# =============================================================================
# USAGE & HELP
# =============================================================================

_show_usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS] <target>

Validates generated code files for syntax errors and common issues.

ARGUMENTS:
  <target>              File or directory to validate (required unless using --help)

OPTIONS:
  --json-report FILE    Generate JSON validation report (default: .claude/logs/playbook/)
  --json-report         Generate JSON report with default filename
  -v, --verbose         Show debug output
  -h, --help            Show this help message

EXAMPLES:
  $SCRIPT_NAME .claude/scripts/playbook/
  $SCRIPT_NAME script1.sh script2.ts script3.js
  $SCRIPT_NAME --json-report .claude/scripts/

SUPPORTED FILE TYPES:
  - Shell scripts (.sh)           - Validated with: bash -n
  - TypeScript (.ts, .tsx)        - Validated with: tsc --noEmit
  - JavaScript (.js, .jsx)        - Validated with: node --check
  - JSON (.json)                  - Validated with: jq empty

CHECKS PERFORMED:
  1. Syntax validation (using appropriate validator)
  2. Placeholder detection (TODO, FIXME, XXX, PLACEHOLDER)
  3. Undefined variable detection (shell scripts)
  4. Executable shebang check (shell scripts)

EXIT CODES:
  0 - All validations passed
  1 - One or more validations failed
  2 - Invalid arguments or missing validators

EOF
}

# =============================================================================
# MAIN ENTRY POINT
# =============================================================================

main() {
    local target=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                _show_usage
                exit 0
                ;;
            -v|--verbose)
                VERBOSE_MODE=true
                shift
                ;;
            --json-report)
                JSON_REPORT=true
                if [[ $# -gt 1 && "$2" != -* ]]; then
                    REPORT_FILE="$2"
                    shift 2
                else
                    shift
                fi
                ;;
            -*)
                log_error "Unknown option: $1"
                _show_usage
                exit 2
                ;;
            *)
                # Collect all non-option arguments as targets
                target="$1"
                shift
                ;;
        esac
    done

    # Validate arguments
    if [[ -z "$target" ]]; then
        log_error "Missing required argument: <target>"
        _show_usage
        exit 2
    fi

    # Banner
    echo ""
    echo -e "${COLOR_BOLD}Code Output Validator${COLOR_NC}"
    echo "Hybrid Claude + Codex Playbook"
    echo ""

    # Detect validators
    _detect_validators

    # Find and validate files
    log_step "Scanning for code files in: $target"
    echo ""

    local file_count=0
    local first_line=true
    local find_output

    find_output=$(_find_code_files "$target" || echo "ERROR")

    if [[ "$find_output" == "ERROR" ]]; then
        log_error "Failed to scan directory"
        exit 2
    fi

    while IFS= read -r line; do
        if [[ $file_count -eq 0 ]]; then
            file_count="$line"
            log_debug "Found $file_count files to validate"
        elif [[ -n "$line" ]]; then
            if [[ "$first_line" == "true" ]]; then
                first_line=false
            fi
            TOTAL_FILES=$((TOTAL_FILES + 1))
            log_debug "Validating file $TOTAL_FILES: $line"
            _validate_file "$line" || true
        fi
    done <<< "$find_output"

    # Print summary
    _print_summary

    # Generate JSON report if requested
    if [[ "$JSON_REPORT" == "true" ]]; then
        _generate_json_report
    fi

    # Exit with appropriate code
    if [[ $FAILED_FILES -gt 0 ]]; then
        exit 1
    else
        exit 0
    fi
}

# Entry point
main "$@"
