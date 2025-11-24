#!/usr/bin/env bash
# menus/tools.sh — TokenHeadroom: Tools (Pillar 4)

# Pillar 4: Tools Menu
menu_tools() {
  ui_clear
  ui_header "TokenHeadroom: Tools"
  ui_info "Utilities for direct config file management."
  echo
  echo "  1) Open .claudeignore     (tools.open_claudeignore)"
  echo "  2) Open settings.json     (tools.open_settings)"
  echo "  3) Validate settings.json (tools.validate_json)"
  echo "  4) Rerun analysis         (tools.rerun)"
  echo
  printf "Select (or any other key to return): "
  read -r c || true
  case "$c" in
    1) action_tools_open_claudeignore; ui_pause ;;
    2) action_tools_open_settings; ui_pause ;;
    3) action_tools_validate_json; ui_pause ;;
    4) action_tools_rerun; ui_pause ;;
    *) return ;;
  esac
  menu_tools
}

# Action: Open .claudeignore
action_tools_open_claudeignore() {
  local p
  p="$(abs_target .claudeignore)"
  if [[ ! -f "$p" ]]; then
    ui_info "Creating new .claudeignore file..."
    touch "$p"
  fi
  ${EDITOR:-nano} "$p" 2>/dev/null || cat "$p"
}

# Action: Open settings.json
action_tools_open_settings() {
  local p
  p="$(abs_target .claude/settings.json)"
  if [[ ! -f "$p" ]]; then
    ui_warn "Missing: $p"
    ui_info "Create one with: echo '{}' > $p"
    return
  fi
  ${EDITOR:-nano} "$p" 2>/dev/null || cat "$p"
}

# Action: Validate settings.json
action_tools_validate_json() {
  local p
  p="$(abs_target .claude/settings.json)"
  if [[ ! -f "$p" ]]; then
    ui_warn "File not found: $p"
    return
  fi
  if ! command -v jq &>/dev/null; then
    ui_error "jq is required for JSON validation but not found"
    return
  fi
  if jq -e . "$p" >/dev/null 2>&1; then
    ui_result "Valid JSON: $p"
  else
    ui_error "Invalid JSON in: $p"
    jq . "$p" 2>&1 || true
  fi
}

# Action: Rerun Analysis
action_tools_rerun() {
  ui_header "TokenHeadroom: Tools — Rerun Analysis"
  local ci
  ci="$(analysis_run_json 2>/dev/null || echo '{}')"
  echo "$ci" | jq '{root, budget, total_estimated_tokens, headroom, top_5_heavy_paths: (.analysis_data.unignored_paths[:5] // [])}' 2>/dev/null || echo "$ci"
}
