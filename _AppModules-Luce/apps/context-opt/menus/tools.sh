#!/usr/bin/env bash
menu_tools(){ ui_clear; ui_header "Tools"; ui_info "Type a number to run; any other key returns."; echo "  1) Open .claudeignore     (tools.open_claudeignore)"; echo "  2) Open settings.json     (tools.open_settings)"; echo "  3) Validate settings.json (tools.validate_json)"; echo "  4) Rerun last analysis    (tools.rerun)"; printf "\nSelect: "; read -r c||true; case "$c" in 1) action_tools_open_claudeignore; ui_pause ;; 2) action_tools_open_settings; ui_pause ;; 3) action_tools_validate_json; ui_pause ;; 4) action_tools_rerun; ui_pause ;; *) return ;; esac; }
action_tools_open_claudeignore(){ local p; p="$(abs_target .claudeignore)"; ${EDITOR:-nano} "$p" 2>/dev/null || cat "$p"; }
action_tools_open_settings(){ local p; p="$(abs_target .claude/settings.json)"; [[ -f "$p" ]] || { ui_warn "Missing: $p"; return; }; ${EDITOR:-nano} "$p" 2>/dev/null || cat "$p"; }
action_tools_validate_json(){ local p; p="$(abs_target .claude/settings.json)"; command -v jq >/dev/null 2>&1 && jq -e . "$p" >/dev/null && ui_result "Valid JSON." || ui_error "Invalid JSON or jq missing."; }
action_tools_rerun(){ local ci; ci="$(analysis_run_json)"; echo "$ci" | jq '.'; }
