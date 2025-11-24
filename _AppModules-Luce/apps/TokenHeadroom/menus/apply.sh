#!/usr/bin/env bash
# menus/apply.sh — TokenHeadroom: Application (Pillar 3)

# Pillar 3: Application Menu
menu_apply() {
  ui_clear
  ui_header "TokenHeadroom: Application"
  ui_info "Safely transform config files based on Policy."
  ui_info "All verbs have dry-run and backup capabilities."
  echo
  echo "  1) Apply .claudeignore edits (apply.ignores)  - Append recommends, dedupe patterns"
  echo "  2) Apply settings edits      (apply.settings) - Prune alwaysInclude, add deny permissions"
  echo
  printf "Select (or any other key to return): "
  read -r c || true
  case "$c" in
    1) action_apply_ignores ;;
    2) action_apply_settings ;;
    *) return ;;
  esac
  menu_apply
}

# Action: Apply .claudeignore Edits
action_apply_ignores() {
  ui_header "TokenHeadroom: Apply — .claudeignore"
  ui_info "Step 1/2: Append recommended patterns"
  dispatch_action ".claudeignore" "append_recommended_patterns"
  ui_pause
  ui_info "Step 2/2: Deduplicate patterns"
  dispatch_action ".claudeignore" "deduplicate_patterns"
  ui_pause
  ui_result "Completed .claudeignore optimization."
}

# Action: Apply Settings Edits
action_apply_settings() {
  ui_header "TokenHeadroom: Apply — .claude/settings.json"
  local settings_path="${CONTEXT_ROOT:-.}/.claude/settings.json"

  # Step 1: Prune alwaysInclude (Removes stale paths)
  ui_info "Step 1/3: Prune non-existent alwaysInclude paths"
  local prune_count=0
  if [[ -f "$settings_path" ]]; then
    prune_count=$(_verb_prune_preview_json "$settings_path" | jq -r '.count // 0' 2>/dev/null || echo 0)
  fi
  dispatch_action ".claude/settings.json" "prune_alwaysInclude"
  ui_result "Pruned $prune_count non-existent paths from alwaysInclude."
  ui_pause

  # Step 2: Add permissions.deny (Blocks large token hogs)
  ui_info "Step 2/3: Add permissions.deny entries for heavy paths"
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

  # Step 3: Tighten auto_include (Mostly informational/suggestive)
  ui_info "Step 3/3: Review autoInclude pattern proposals"
  dispatch_action ".claude/settings.json" "tighten_auto_include"
  ui_result "Completed autoInclude tightening review (manual edits may be needed)."
  ui_pause

  ui_result "Completed settings.json optimization."
}
