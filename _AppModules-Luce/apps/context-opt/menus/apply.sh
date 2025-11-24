#!/usr/bin/env bash
menu_apply(){ ui_clear; ui_header "Apply"; ui_info "Type a number to run; any other key returns."; echo "  1) Apply .claudeignore edits (apply.ignores)"; echo "  2) Apply settings edits      (apply.settings)"; printf "\nSelect: "; read -r c||true; case "$c" in 1) action_apply_ignores ;; 2) action_apply_settings ;; *) return ;; esac; }
action_apply_ignores(){ ui_header "Apply — .claudeignore"; dispatch_action ".claudeignore" "append_recommended_patterns"; ui_pause; dispatch_action ".claudeignore" "deduplicate_patterns"; }

action_apply_settings(){
    ui_header "Apply — .claude/settings.json"
    local settings_path="${CONTEXT_ROOT:-.}/.claude/settings.json"

    # 1. Prune alwaysInclude (Removes stale paths)
    local prune_count=0
    if [[ -f "$settings_path" ]]; then
        prune_count=$(_verb_prune_preview_json "$settings_path" | jq -r '.count // 0' 2>/dev/null || echo 0)
    fi
    dispatch_action ".claude/settings.json" "prune_alwaysInclude"
    ui_result "Pruned $prune_count non-existent paths from alwaysInclude."
    ui_pause

    # 2. Add permissions.deny (Blocks large token hogs)
    local deny_patterns=(
        "Read(./node_modules/**)"
        "Read(./.next/**)"
        "Read(./logs/**)"
        "Read(./public/export/**)"
        "Read(./docs/archive/**)"
        "Read(./_build/**)"
    )
    local added_paths=""
    if [[ -f "$settings_path" ]]; then
        added_paths=$(_verb_deny_preview "$settings_path" "${deny_patterns[@]}" | jq -r '.add[]' 2>/dev/null || true)
    fi
    dispatch_action ".claude/settings.json" "add_permissions_deny" "${deny_patterns[@]}"
    if [[ -n "$added_paths" ]]; then
        ui_result "Added the following new permissions.deny patterns:"
        echo "$added_paths" | sed 's/^/  - /'
    else
        ui_result "No new permissions.deny patterns were added (already exist)."
    fi
    ui_pause

    # 3. Tighten auto_include (Mostly informational/suggestive)
    dispatch_action ".claude/settings.json" "tighten_auto_include"
    ui_result "Completed autoInclude tightening action (review proposals separately)."
}
