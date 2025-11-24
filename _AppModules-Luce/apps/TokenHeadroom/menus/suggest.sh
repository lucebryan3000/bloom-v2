#!/usr/bin/env bash
# menus/suggest.sh — TokenHeadroom: Suggestions (Pillar 2)

# Pillar 2: Suggestions Menu
menu_suggest() {
  ui_clear
  ui_header "TokenHeadroom: Suggestions"
  ui_info "Proactively find ways to increase your Headroom (save tokens)."
  echo
  echo "  1) Ignore patterns        (suggest.ignores)  - Recommended paths for .claudeignore"
  echo "  2) Settings tweaks        (suggest.settings) - Proposals for autoInclude/permissions.deny"
  echo "  3) Command stubs trimming (suggest.commands) - Identify large command definitions"
  echo "  4) Docs archival          (suggest.docs)     - Find large docs for potential archival"
  echo
  printf "Select (or any other key to return): "
  read -r c || true
  case "$c" in
    1) action_suggest_ignores; ui_pause ;;
    2) action_suggest_settings; ui_pause ;;
    3) action_suggest_commands; ui_pause ;;
    4) action_suggest_docs; ui_pause ;;
    *) return ;;
  esac
  menu_suggest
}

# Action: Suggest Ignore Patterns
action_suggest_ignores() {
  ui_header "TokenHeadroom: Suggest — Ignore Patterns"
  local ci top_hogs
  ci="$(analysis_run_json 2>/dev/null || echo '{}')"

  ui_info "Top 5 unignored paths costing >=1000 tokens (Dynamic Analysis):"

  # Filter for heavy, unignored paths and format output
  top_hogs=$(echo "$ci" | jq -r '
    .analysis_data.unignored_paths // []
    | map(select(.token_cost >= 1000))
    | sort_by(-.token_cost)
    | .[0:5]
    | .[]
    | "  \(.path) (Tokens: \(.token_cost))"
  ' 2>/dev/null || true)

  if [[ -n "$top_hogs" ]]; then
    echo "$top_hogs"
  else
    ui_info "  (No paths exceeding 1000 tokens found)"
  fi

  echo
  ui_info "---"
  ui_info "Standard recommendations to verify (Static Fallback):"
  cat <<'PATTERNS'
  node_modules/
  .next/
  dist/
  build/
  out/
  _build/
  coverage/
  logs/
  public/export/
  docs/archive/
  docs/kb/
PATTERNS

  echo
  ui_info "Use 'Application > Apply .claudeignore edits' to append verified patterns."
}

# Action: Suggest Settings Tweaks
action_suggest_settings() {
  ui_header "TokenHeadroom: Suggest — Settings"
  local ci
  ci="$(analysis_run_json 2>/dev/null || echo '{}')"
  echo "$ci" | jq '{autoInclude, note: "Review proposals; apply via Application menu or edit manually."}' 2>/dev/null || echo "$ci"
}

# Action: Suggest Command Trimming
action_suggest_commands() {
  ui_header "TokenHeadroom: Suggest — Commands"
  local ci
  ci="$(analysis_run_json 2>/dev/null || echo '{}')"
  echo "$ci" | jq '.largeCommands // []' 2>/dev/null || echo "[]"
  echo
  ui_info "Large command definitions consume headroom. Consider trimming or stubbing."
}

# Action: Suggest Docs Archival
action_suggest_docs() {
  ui_header "TokenHeadroom: Suggest — Docs"
  local ci
  ci="$(analysis_run_json 2>/dev/null || echo '{}')"
  echo "$ci" | jq '.largeDocs // []' 2>/dev/null || echo "[]"
  echo
  ui_info "Consider moving large documentation to docs/archive/ to reclaim headroom."
}
