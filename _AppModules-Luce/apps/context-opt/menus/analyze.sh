#!/usr/bin/env bash
list_actions(){ cat <<'EOF'
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
menu_main(){ ui_clear; ui_header "Context Optimizer — Main"; ui_info "Type a number to run; any other key exits."; echo "  1) Analyze"; echo "  2) Suggest"; echo "  3) Apply"; echo "  4) Tools"; printf "\nSelect: "; read -r c||true; case "$c" in 1) menu_analyze ;; 2) menu_suggest ;; 3) menu_apply ;; 4) menu_tools ;; *) exit 0 ;; esac; menu_main; }
menu_analyze(){ ui_clear; ui_header "Analyze"; ui_info "Type a number to run; any other key returns."; echo "  1) Quick summary   (analyze.quick)"; echo "  2) Deep breakdown  (analyze.deep)"; printf "\nSelect: "; read -r c||true; case "$c" in 1) action_analyze_quick; ui_pause ;; 2) action_analyze_deep; ui_pause ;; *) return ;; esac; }
action_analyze_quick(){ ui_header "Analyze — Quick"; local ci; ci="$(analysis_run_json)"; echo "$ci" | jq '{root, targets}'; }
action_analyze_deep(){ ui_header "Analyze — Deep"; local ci; ci="$(analysis_run_json)"; echo "$ci" | jq '.'; }
