#!/usr/bin/env bash
# lib/run.sh — TokenHeadroom runtime utilities

CONTEXT_ROOT=""
BACKUP_DIR=""

# Detect and confirm project root
detect_and_confirm_root() {
  local hint="${1:-}"

  # Try hint first
  if [[ -n "$hint" ]] && [[ -d "$hint" ]]; then
    CONTEXT_ROOT="$hint"
  # Try git root
  elif git rev-parse --show-toplevel &>/dev/null; then
    CONTEXT_ROOT="$(git rev-parse --show-toplevel)"
  # Fallback to current directory
  else
    CONTEXT_ROOT="$(pwd)"
  fi

  # Ensure .claude directory exists for settings operations
  if [[ ! -d "${CONTEXT_ROOT}/.claude" ]]; then
    mkdir -p "${CONTEXT_ROOT}/.claude" 2>/dev/null || true
  fi

  # Setup backup directory
  BACKUP_DIR="${CONTEXT_ROOT}/.claude/backups"
  mkdir -p "$BACKUP_DIR" 2>/dev/null || true

  ui_info "Project root: ${CONTEXT_ROOT}"
  export CONTEXT_ROOT BACKUP_DIR
  return 0
}

# Get absolute path to a target file
abs_target() {
  local rel="$1"
  echo "${CONTEXT_ROOT}/${rel}"
}

# Backup a file before modification
backup_file() {
  local src="$1"
  if [[ ! -f "$src" ]]; then
    echo "(no backup needed)"
    return 0
  fi
  local name base ts bak
  name="$(basename "$src")"
  base="${name%.*}"
  ts="$(date -u +%Y%m%dT%H%M%SZ)"
  bak="${BACKUP_DIR}/${base}_${ts}.bak"
  cp -f "$src" "$bak" 2>/dev/null || true
  echo "$bak"
}

# Initialize logging
log_init() {
  local mode="${1:-off}"
  # Placeholder for log initialization
  # In full implementation, this would setup log file
  export LOG_MODE="$mode"
}

# Run a specific action by ID
run_action_id() {
  local action_id="$1"
  case "$action_id" in
    analyze.quick) action_analyze_quick ;;
    analyze.deep) action_analyze_deep ;;
    suggest.ignores) action_suggest_ignores ;;
    suggest.settings) action_suggest_settings ;;
    suggest.commands) action_suggest_commands ;;
    suggest.docs) action_suggest_docs ;;
    apply.ignores) action_apply_ignores ;;
    apply.settings) action_apply_settings ;;
    tools.open_claudeignore) action_tools_open_claudeignore ;;
    tools.open_settings) action_tools_open_settings ;;
    tools.validate_json) action_tools_validate_json ;;
    tools.rerun) action_tools_rerun ;;
    *) ui_error "Unknown action: $action_id"; return 1 ;;
  esac
}

# Preview step display
preview_step() {
  local id="$1" desc="$2" detail="$3" rollback="$4" access="$5"
  echo
  ui_info "Action: $id"
  ui_info "Description: $desc"
  echo -e "$detail"
  echo
  ui_info "Rollback: $rollback"
  ui_info "Access: $access"
  echo
}

# Cleanup function (called on exit)
cleanup_token_headroom() {
  # Cleanup temp files if needed
  :
}
