#!/usr/bin/env bash
menu_suggest(){ ui_clear; ui_header "Suggest"; ui_info "Type a number to run; any other key returns."; echo "  1) Ignore patterns        (suggest.ignores)"; echo "  2) Settings tweaks        (suggest.settings)"; echo "  3) Command stubs trimming (suggest.commands)"; echo "  4) Docs archival          (suggest.docs)"; printf "\nSelect: "; read -r c||true; case "$c" in 1) action_suggest_ignores; ui_pause ;; 2) action_suggest_settings; ui_pause ;; 3) action_suggest_commands; ui_pause ;; 4) action_suggest_docs; ui_pause ;; *) return ;; esac; }
action_suggest_ignores(){ ui_header "Suggest — Ignore Patterns"; ui_info "Propose adding ignores for heavy directories if present & not ignored:"; cat <<EOF
  node_modules/
  .next/
  dist/
  build/
  out/
  _build/
  coverage/
  logs/
  _build/test/reports/
  test-results/
  public/export/
  docs/archive/
  docs/kb/
EOF
}
action_suggest_settings(){ ui_header "Suggest — Settings"; local ci; ci="$(analysis_run_json)"; echo "$ci" | jq '{autoInclude, note:"Review proposals; apply manually or future verb."}'; }
action_suggest_commands(){ ui_header "Suggest — Commands"; local ci; ci="$(analysis_run_json)"; echo "$ci" | jq '.largeCommands'; }
action_suggest_docs(){ ui_header "Suggest — Docs"; local ci; ci="$(analysis_run_json)"; echo "$ci" | jq '.largeDocs'; }
