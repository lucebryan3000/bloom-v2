#!/usr/bin/env bash
# lib/dispatch.sh — TokenHeadroom verb dispatch system

declare -A VERB_PREVIEW_FN
declare -A VERB_APPLY_FN

# Register a verb with its preview and apply functions
verb_register() {
  local name="$1" preview_fn="$2" apply_fn="$3"
  VERB_PREVIEW_FN["$name"]="$preview_fn"
  VERB_APPLY_FN["$name"]="$apply_fn"
}

# Dispatch an action to a verb
dispatch_action() {
  local target="$1" verb="$2"
  shift 2
  local args=("$@")

  local abs_path
  abs_path="$(abs_target "$target")"

  # Check policy allows this verb on target
  local allowed
  allowed="$(get_allowed_verbs "$target")"
  if [[ -n "$allowed" ]] && ! echo "$allowed" | grep -q "^${verb}$"; then
    ui_warn "Verb '$verb' not allowed on '$target' by policy"
    return 1
  fi

  # Get functions
  local preview_fn="${VERB_PREVIEW_FN[$verb]:-}"
  local apply_fn="${VERB_APPLY_FN[$verb]:-}"

  if [[ -z "$preview_fn" ]] || [[ -z "$apply_fn" ]]; then
    ui_error "Verb not registered: $verb"
    return 1
  fi

  # Run preview
  "$preview_fn" "$target" "$abs_path" "${args[@]}"

  # In dry-run mode, skip apply
  if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
    ui_warn "(dry-run) Skipping apply for: $verb"
    return 0
  fi

  # In CI mode without force, skip apply
  if [[ "${CI_MODE:-0}" -eq 1 ]] && [[ "${FORCE:-0}" -eq 0 ]]; then
    ui_info "(CI mode) Apply skipped; use --force to apply"
    return 0
  fi

  # Run apply
  "$apply_fn" "$target" "$abs_path" "${args[@]}"
}
