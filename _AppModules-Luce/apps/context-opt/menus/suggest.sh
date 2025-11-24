#!/usr/bin/env bash
menu_suggest(){ ui_clear; ui_header "Suggest"; ui_info "Type a number to run; any other key returns."; echo "  1) Ignore patterns        (suggest.ignores)"; echo "  2) Settings tweaks        (suggest.settings)"; echo "  3) Command stubs trimming (suggest.commands)"; echo "  4) Docs archival          (suggest.docs)"; printf "\nSelect: "; read -r c||true; case "$c" in 1) action_suggest_ignores; ui_pause ;; 2) action_suggest_settings; ui_pause ;; 3) action_suggest_commands; ui_pause ;; 4) action_suggest_docs; ui_pause ;; *) return ;; esac; }

action_suggest_ignores(){
    ui_header "Suggest — Ignore Patterns"
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

    ui_info "---"
    ui_info "Standard recommendations to verify (Static Fallback):"
    cat <<'EOF'
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
EOF
}
action_suggest_settings(){ ui_header "Suggest — Settings"; local ci; ci="$(analysis_run_json)"; echo "$ci" | jq '{autoInclude, note:"Review proposals; apply manually or future verb."}'; }
action_suggest_commands(){ ui_header "Suggest — Commands"; local ci; ci="$(analysis_run_json)"; echo "$ci" | jq '.largeCommands'; }
action_suggest_docs(){ ui_header "Suggest — Docs"; local ci; ci="$(analysis_run_json)"; echo "$ci" | jq '.largeDocs'; }
