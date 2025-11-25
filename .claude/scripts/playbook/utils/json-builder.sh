#!/usr/bin/env bash
# =============================================================================
# json-builder.sh - Build JSON task files from simple formats
# =============================================================================
# Part of Hybrid Claude + Codex Playbook
#
# Converts CSV, YAML, or key=value formats into JSON task files for use with
# codex-parallel.sh and other playbook orchestrators.
#
# Supported Input Formats:
#   - CSV: description,model,command (with proper quoting)
#   - Key=value: TASK_N_DESC, TASK_N_MODEL, TASK_N_CMD variables
#   - YAML: future format support (currently returns error)
#
# Output:
#   - Valid JSON to stdout (default) or file with --output
#   - Line: "✓ Generated X tasks" to stderr
#
# Usage:
#   json-builder.sh input.csv > tasks.json
#   json-builder.sh input.env --output tasks.json
#   json-builder.sh --help
#
# Exit Codes:
#   0 - Success
#   1 - Parameter or configuration error
#   2 - Runtime failure
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

# =============================================================================
# CONFIGURATION
# =============================================================================

# Color codes for logging (OmniForge conventions)
readonly LOG_BLUE=$'\033[0;34m'
readonly LOG_GREEN=$'\033[0;32m'
readonly LOG_YELLOW=$'\033[0;33m'
readonly LOG_RED=$'\033[0;31m'
readonly LOG_NC=$'\033[0m'

# Global state
SCRIPT_NAME="$(basename "$0")"
INPUT_FILE=""
OUTPUT_FILE=""
INPUT_FORMAT=""
VERBOSE="${VERBOSE:-false}"

# =============================================================================
# LOGGING FUNCTIONS
# =============================================================================

# Log informational message to stderr
_log_info() {
    local message="$1"
    echo -e "${LOG_BLUE}[INFO]${LOG_NC} ${message}" >&2
}

# Log success message to stderr
_log_success() {
    local message="$1"
    echo -e "${LOG_GREEN}[OK]${LOG_NC} ${message}" >&2
}

# Log warning message to stderr
_log_warn() {
    local message="$1"
    echo -e "${LOG_YELLOW}[WARN]${LOG_NC} ${message}" >&2
}

# Log error message to stderr
_log_error() {
    local message="$1"
    echo -e "${LOG_RED}[ERROR]${LOG_NC} ${message}" >&2
}

# Log debug message to stderr (only if VERBOSE=true)
_log_debug() {
    local message="$1"
    if [[ "${VERBOSE}" == "true" ]]; then
        echo -e "${LOG_BLUE}[DEBUG]${LOG_NC} ${message}" >&2
    fi
}

# =============================================================================
# VALIDATION FUNCTIONS
# =============================================================================

# Check if jq is installed and accessible
_require_jq() {
    if ! command -v jq &> /dev/null; then
        _log_error "Required command not found: jq"
        _log_error "Install with: apt-get install jq (Ubuntu/Debian) or brew install jq (macOS)"
        return 1
    fi
    _log_debug "Found command: jq"
    return 0
}

# Validate input file exists and is readable
_validate_input_file() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        _log_error "Input file not found: $file"
        return 1
    fi

    if [[ ! -r "$file" ]]; then
        _log_error "Input file is not readable: $file"
        return 1
    fi

    if [[ ! -s "$file" ]]; then
        _log_error "Input file is empty: $file"
        return 1
    fi

    _log_debug "Input file validated: $file ($(wc -l < "$file") lines)"
    return 0
}

# Detect input format from file extension and content
_detect_format() {
    local file="$1"
    local extension="${file##*.}"

    # Try extension-based detection first
    case "$extension" in
        csv)
            echo "csv"
            return 0
            ;;
        env|conf|config)
            echo "keyvalue"
            return 0
            ;;
        yaml|yml)
            _log_error "YAML format not yet supported. Use CSV or key=value format."
            return 1
            ;;
        json)
            _log_error "Input should not be JSON. Provide CSV or key=value format."
            return 1
            ;;
        *)
            # Fall back to content detection
            _detect_format_by_content "$file"
            return $?
            ;;
    esac
}

# Detect format by examining file content
_detect_format_by_content() {
    local file="$1"
    local first_line
    first_line=$(head -n 1 "$file" 2>/dev/null || echo "")

    # Check for key=value pattern (TASK_1_DESC=...)
    if [[ "$first_line" =~ ^TASK_[0-9]+_[A-Z]+= ]]; then
        echo "keyvalue"
        return 0
    fi

    # Check for CSV header pattern (description, model, command)
    if [[ "$first_line" =~ ^(description|task|cmd|model) ]]; then
        echo "csv"
        return 0
    fi

    # Default to CSV if ambiguous
    _log_warn "Could not detect format. Assuming CSV format."
    echo "csv"
    return 0
}

# Validate required CSV fields exist
_validate_csv_fields() {
    local header="$1"
    local line_num="$2"

    # Normalize header: lowercase, remove quotes
    header=$(echo "$header" | tr '[:upper:]' '[:lower:]' | tr -d '"')

    # Check for description and command (model is optional)
    if ! echo "$header" | grep -q "description"; then
        _log_error "Line $line_num: Missing required field 'description' in CSV header"
        return 1
    fi

    if ! echo "$header" | grep -q "command"; then
        _log_error "Line $line_num: Missing required field 'command' in CSV header"
        return 1
    fi

    _log_debug "CSV header validated with required fields"
    return 0
}

# =============================================================================
# CSV PARSING FUNCTIONS
# =============================================================================

# Parse CSV line respecting quoted fields
# Input: CSV line with potential quoted fields
# Output: JSON array of field values
_parse_csv_line() {
    local line="$1"
    local fields=()
    local current_field=""
    local in_quotes=false
    local i=0

    while [[ $i -lt ${#line} ]]; do
        local char="${line:$i:1}"

        if [[ "$char" == '"' ]]; then
            # Toggle quote state
            in_quotes=$([[ "$in_quotes" == "true" ]] && echo "false" || echo "true")
        elif [[ "$char" == "," && "$in_quotes" == "false" ]]; then
            # Found field separator outside quotes
            fields+=("$current_field")
            current_field=""
        else
            # Regular character
            current_field+="$char"
        fi

        ((i++))
    done

    # Add final field
    fields+=("$current_field")

    # Output as JSON array
    local json_array="["
    for field in "${fields[@]}"; do
        # Trim whitespace and remove surrounding quotes
        field=$(echo "$field" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//;s/^"//;s/"$//')

        # Escape special characters for JSON using jq's -Rs for raw string input
        # -Rs: read raw (no \n interpretation), -s: entire input as single string
        field=$(printf '%s' "$field" | jq -Rs .)

        json_array+="${field},"
    done

    # Remove trailing comma and close array
    json_array="${json_array%,}]"

    echo "$json_array"
}

# Parse CSV format into tasks
# Input: CSV file with header row
# Output: JSON string with tasks array
_parse_csv() {
    local input_file="$1"
    local header_line
    local field_indices=()
    local task_count=0
    local tasks_json="["

    # Read header
    header_line=$(head -n 1 "$input_file")
    if ! _validate_csv_fields "$header_line" 1; then
        return 1
    fi

    # Parse header to find field positions
    local header_lower
    header_lower=$(echo "$header_line" | tr '[:upper:]' '[:lower:]' | tr -d '"')

    # Find field indices
    local desc_idx=0
    local model_idx=-1
    local cmd_idx=0
    local idx=0

    # Simple header parsing for common patterns
    if echo "$header_line" | grep -qE "(description|task|name)"; then
        desc_idx=0
    fi

    if echo "$header_line" | grep -qE "(model|agent)"; then
        # Count commas before model to find its index
        model_idx=$(echo "$header_line" | sed 's/,/\n/g' | nl -v 0 | grep -i "model\|agent" | cut -f1 | head -1)
    fi

    if echo "$header_line" | grep -qE "(command|cmd|exec)"; then
        cmd_idx=$(echo "$header_line" | sed 's/,/\n/g' | nl -v 0 | grep -i "command\|cmd\|exec" | cut -f1 | head -1)
    fi

    _log_debug "CSV field indices: description=$desc_idx, model=$model_idx, command=$cmd_idx"

    # Read data lines (skip header)
    local line_num=1
    while IFS= read -r line; do
        ((line_num++))

        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

        # Parse line
        local parsed_fields
        parsed_fields=$(_parse_csv_line "$line")

        if [[ -z "$parsed_fields" ]]; then
            _log_warn "Line $line_num: Could not parse CSV line, skipping"
            continue
        fi

        # Extract fields using jq
        local description
        local model=""
        local command

        description=$(echo "$parsed_fields" | jq -r ".[$desc_idx]" 2>/dev/null || echo "")
        if [[ $model_idx -ge 0 ]]; then
            model=$(echo "$parsed_fields" | jq -r ".[$model_idx]" 2>/dev/null || echo "")
        fi
        command=$(echo "$parsed_fields" | jq -r ".[$cmd_idx]" 2>/dev/null || echo "")

        # Validate required fields
        if [[ -z "$description" || -z "$command" ]]; then
            _log_warn "Line $line_num: Missing required fields (description or command), skipping"
            continue
        fi

        # Handle null values from jq
        [[ "$description" == "null" ]] && description=""
        [[ "$model" == "null" ]] && model=""
        [[ "$command" == "null" ]] && command=""

        # Skip if description or command is still empty
        [[ -z "$description" || -z "$command" ]] && continue

        # Escape JSON strings
        local desc_json model_json cmd_json
        desc_json=$(jq -n --arg s "$description" '$s')
        cmd_json=$(jq -n --arg s "$command" '$s')

        if [[ -n "$model" ]]; then
            model_json=$(jq -n --arg s "$model" '$s')
            tasks_json+="$(printf '{"description":%s,"model":%s,"command":%s},' "$desc_json" "$model_json" "$cmd_json")"
        else
            tasks_json+="$(printf '{"description":%s,"command":%s},' "$desc_json" "$cmd_json")"
        fi

        ((task_count++))
    done < <(tail -n +2 "$input_file")

    # Validate we found tasks
    if [[ $task_count -eq 0 ]]; then
        _log_error "No valid tasks found in CSV file"
        return 1
    fi

    # Close JSON array
    tasks_json="${tasks_json%,}]"

    echo "$tasks_json"
    _log_debug "Parsed $task_count tasks from CSV"
    return 0
}

# =============================================================================
# KEY=VALUE PARSING FUNCTIONS
# =============================================================================

# Parse key=value format (environment variable style)
# Input: File with TASK_N_DESC, TASK_N_MODEL, TASK_N_CMD variables
# Output: JSON string with tasks array
_parse_keyvalue() {
    local input_file="$1"
    local task_count=0
    local tasks_json="["

    # Source the file in a subshell to extract variables
    declare -A task_map

    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue

        # Trim whitespace from key only
        key=$(echo "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

        # Skip if key doesn't match TASK pattern
        if [[ ! "$key" =~ ^TASK_[0-9]+_[A-Z]+$ ]]; then
            continue
        fi

        # Remove quotes from value and trim whitespace
        value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//;s/^"//;s/"$//')

        # Store in map
        task_map["$key"]="$value"
    done < "$input_file"

    # Extract task numbers
    local task_numbers=()
    for key in "${!task_map[@]}"; do
        local task_num=$(echo "$key" | sed 's/TASK_\([0-9]*\)_.*/\1/')
        task_numbers+=("$task_num")
    done

    # Remove duplicates and sort
    task_numbers=($(printf '%s\n' "${task_numbers[@]}" | sort -u))

    if [[ ${#task_numbers[@]} -eq 0 ]]; then
        _log_error "No TASK_N_* variables found in key=value format"
        return 1
    fi

    # Build JSON for each task
    for task_num in "${task_numbers[@]}"; do
        local desc_key="TASK_${task_num}_DESC"
        local model_key="TASK_${task_num}_MODEL"
        local cmd_key="TASK_${task_num}_CMD"

        # Validate required fields
        if [[ -z "${task_map[$desc_key]:-}" || -z "${task_map[$cmd_key]:-}" ]]; then
            _log_warn "Task $task_num: Missing required fields (DESC or CMD), skipping"
            continue
        fi

        local description="${task_map[$desc_key]}"
        local model="${task_map[$model_key]:-}"
        local command="${task_map[$cmd_key]}"

        # Escape JSON strings
        local desc_json cmd_json
        desc_json=$(jq -n --arg s "$description" '$s')
        cmd_json=$(jq -n --arg s "$command" '$s')

        if [[ -n "$model" ]]; then
            local model_json
            model_json=$(jq -n --arg s "$model" '$s')
            tasks_json+="$(printf '{"description":%s,"model":%s,"command":%s},' "$desc_json" "$model_json" "$cmd_json")"
        else
            tasks_json+="$(printf '{"description":%s,"command":%s},' "$desc_json" "$cmd_json")"
        fi

        ((task_count++))
    done

    # Validate we found tasks
    if [[ $task_count -eq 0 ]]; then
        _log_error "No valid tasks found in key=value format"
        return 1
    fi

    # Close JSON array
    tasks_json="${tasks_json%,}]"

    echo "$tasks_json"
    _log_debug "Parsed $task_count tasks from key=value format"
    return 0
}

# =============================================================================
# JSON GENERATION AND VALIDATION
# =============================================================================

# Build final JSON structure with tasks array
# Input: Tasks JSON array
# Output: Complete JSON object with { "tasks": [...] }
_build_json() {
    local tasks_json="$1"

    # Wrap in tasks object
    local output
    output=$(jq -n --argjson tasks "$tasks_json" '{tasks: $tasks}' 2>/dev/null)

    if [[ -z "$output" ]]; then
        _log_error "Failed to build JSON structure"
        return 1
    fi

    echo "$output"
    return 0
}

# Validate JSON structure and content
# Input: JSON file or string
# Output: Validation report to stderr, exit code 0 on success
_validate_json() {
    local json_content="$1"

    # Validate JSON syntax
    if ! echo "$json_content" | jq . > /dev/null 2>&1; then
        _log_error "Invalid JSON syntax"
        return 1
    fi

    # Validate structure: must have "tasks" key
    if ! echo "$json_content" | jq -e '.tasks' > /dev/null 2>&1; then
        _log_error "JSON missing required 'tasks' key"
        return 1
    fi

    # Validate tasks is an array
    if ! echo "$json_content" | jq -e '.tasks | type == "array"' > /dev/null 2>&1; then
        _log_error "JSON 'tasks' value must be an array"
        return 1
    fi

    # Validate each task has required fields
    local task_count
    task_count=$(echo "$json_content" | jq '.tasks | length')

    for ((i=0; i<task_count; i++)); do
        local has_desc
        local has_cmd

        has_desc=$(echo "$json_content" | jq -e ".tasks[$i].description" > /dev/null 2>&1 && echo "true" || echo "false")
        has_cmd=$(echo "$json_content" | jq -e ".tasks[$i].command" > /dev/null 2>&1 && echo "true" || echo "false")

        if [[ "$has_desc" != "true" || "$has_cmd" != "true" ]]; then
            _log_error "Task $i: Missing required fields (description or command)"
            return 1
        fi
    done

    _log_debug "JSON validation passed: $task_count tasks"
    return 0
}

# =============================================================================
# OUTPUT FUNCTIONS
# =============================================================================

# Write JSON to output (file or stdout)
_output_json() {
    local json_content="$1"
    local output_file="${2:-}"

    if [[ -n "$output_file" ]]; then
        # Validate output directory exists
        local output_dir
        output_dir=$(dirname "$output_file")

        if [[ ! -d "$output_dir" ]]; then
            _log_error "Output directory does not exist: $output_dir"
            return 1
        fi

        # Write to file
        if ! echo "$json_content" | tee "$output_file" > /dev/null; then
            _log_error "Failed to write output file: $output_file"
            return 1
        fi

        _log_success "Generated JSON file: $output_file"
    else
        # Write to stdout
        echo "$json_content"
    fi

    return 0
}

# =============================================================================
# HELP AND USAGE
# =============================================================================

# Show help message
_show_help() {
    cat <<'EOF'
json-builder.sh - Build JSON task files from simple formats

DESCRIPTION
  Converts CSV, key=value, or YAML formats into JSON task files for use with
  codex-parallel.sh and other playbook orchestrators.

USAGE
  json-builder.sh [OPTIONS] <input-file>
  json-builder.sh --help
  json-builder.sh --version

OPTIONS
  -o, --output FILE    Write JSON to FILE instead of stdout
  -v, --verbose        Show debug messages
  -h, --help          Show this help message

INPUT FORMATS

  CSV Format:
    - Header row: description,model,command (or variations)
    - Data rows: quoted fields with commas inside quotes allowed
    - Example:
        description,model,command
        "Generate types",gpt-5.1-codex-max,"codex exec -m gpt-5.1-codex-max ..."
        "Write docs",gpt-5.1-codex,"codex exec -m gpt-5.1-codex ..."

  Key=Value Format (environment variables):
    - Lines: TASK_N_DESC="...", TASK_N_MODEL="...", TASK_N_CMD="..."
    - Example:
        TASK_1_DESC="Generate types"
        TASK_1_MODEL="gpt-5.1-codex-max"
        TASK_1_CMD="codex exec -m gpt-5.1-codex-max ..."

OUTPUT FORMAT
  Valid JSON with structure:
    {
      "tasks": [
        {
          "description": "...",
          "model": "...",
          "command": "..."
        }
      ]
    }

  Note: "model" field is optional

EXAMPLES
  # Convert CSV to JSON
  json-builder.sh input.csv > tasks.json

  # Convert key=value to JSON file
  json-builder.sh input.env --output tasks.json

  # Show debug output
  json-builder.sh --verbose input.csv > tasks.json

REQUIREMENTS
  - jq: JSON processor (https://stedolan.github.io/jq/)
  - bash: 4.0+ for associative arrays

EXIT CODES
  0 - Success
  1 - Parameter or configuration error
  2 - Runtime failure

EOF
}

# Show version
_show_version() {
    echo "json-builder.sh v1.0 (Hybrid Claude + Codex Playbook)"
}

# =============================================================================
# MAIN FUNCTION
# =============================================================================

main() {
    local exit_code=0

    # Parse command-line arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                _show_help
                exit 0
                ;;
            -v|--version)
                _show_version
                exit 0
                ;;
            --verbose)
                VERBOSE="true"
                shift
                ;;
            -o|--output)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            -*)
                _log_error "Unknown option: $1"
                exit 1
                ;;
            *)
                INPUT_FILE="$1"
                shift
                ;;
        esac
    done

    # Validate required arguments
    if [[ -z "$INPUT_FILE" ]]; then
        _log_error "Missing required argument: input-file"
        echo "Use --help for usage information" >&2
        exit 1
    fi

    # Validate dependencies
    if ! _require_jq; then
        exit 1
    fi

    # Validate input file
    if ! _validate_input_file "$INPUT_FILE"; then
        exit 1
    fi

    # Detect format
    INPUT_FORMAT=$(_detect_format "$INPUT_FILE") || exit 1
    _log_info "Detected format: $INPUT_FORMAT"

    # Parse based on format
    local tasks_json
    case "$INPUT_FORMAT" in
        csv)
            tasks_json=$(_parse_csv "$INPUT_FILE") || exit 2
            ;;
        keyvalue)
            tasks_json=$(_parse_keyvalue "$INPUT_FILE") || exit 2
            ;;
        *)
            _log_error "Unsupported input format: $INPUT_FORMAT"
            exit 1
            ;;
    esac

    # Build final JSON structure
    local json_output
    json_output=$(_build_json "$tasks_json") || exit 2

    # Validate JSON
    if ! _validate_json "$json_output"; then
        exit 2
    fi

    # Get task count for summary
    local task_count
    task_count=$(echo "$json_output" | jq '.tasks | length')

    # Output JSON
    if ! _output_json "$json_output" "$OUTPUT_FILE"; then
        exit 2
    fi

    # Print success message
    _log_success "Generated $task_count tasks from $INPUT_FORMAT format"

    return $exit_code
}

# Execute main function
main "$@"
