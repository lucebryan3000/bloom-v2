#!/usr/bin/env bash
# menus/analyze.sh — TokenHeadroom: Analysis & Main Menu

# List all available action IDs for non-interactive mode
list_actions() {
  cat <<'EOF'
analyze.quick
analyze.deep
suggest.ignores
suggest.settings
suggest.commands
suggest.docs
apply.ignores
apply.settings
tools.open_claudeignore
tools.open_settings
tools.validate_json
tools.rerun
EOF
}

# Main Menu - The Four Pillars
menu_main() {
  ui_clear
  ui_header "TokenHeadroom — The Cognitive Capacity Manager"
  ui_info "Maximize Claude's effective headroom by minimizing irrelevant token count."
  echo
  echo "The Four Pillars:"
  echo "  1) Analysis    - Diagnose token costs & relevance"
  echo "  2) Suggestions - Find optimization targets"
  echo "  3) Application - Safely apply configuration changes"
  echo "  4) Tools       - Direct config file utilities"
  echo
  printf "Select (1-4, or any other key to exit): "
  read -r c || true
  case "$c" in
    1) menu_analyze ;;
    2) menu_suggest ;;
    3) menu_apply ;;
    4) menu_tools ;;
    *) exit 0 ;;
  esac
  menu_main
}

# Pillar 1: Analysis Menu
menu_analyze() {
  ui_clear
  ui_header "TokenHeadroom: Analysis"
  ui_info "Diagnose token costs & relevance in your project context."
  echo
  echo "  1) Quick summary   (analyze.quick) - High-level token and file counts"
  echo "  2) Deep breakdown  (analyze.deep)  - Full JSON report of all analyzed paths"
  echo
  printf "Select (or any other key to return): "
  read -r c || true
  case "$c" in
    1) action_analyze_quick; ui_pause ;;
    2) action_analyze_deep; ui_pause ;;
    *) return ;;
  esac
  menu_analyze
}

# Action: Quick Analysis
action_analyze_quick() {
  ui_header "TokenHeadroom: Analysis — Quick Summary"
  local ci
  ci="$(analysis_run_json 2>/dev/null || echo '{}')"
  echo "$ci" | jq '{root, targets, budget, total_estimated_tokens, headroom}' 2>/dev/null || echo "$ci"
  echo
  ui_info "Headroom = Budget - Estimated Tokens (higher is better)"
}

# Action: Deep Analysis
action_analyze_deep() {
  ui_header "TokenHeadroom: Analysis — Deep Breakdown"
  local ci
  ci="$(analysis_run_json 2>/dev/null || echo '{}')"
  echo "$ci" | jq '.' 2>/dev/null || echo "$ci"
}
