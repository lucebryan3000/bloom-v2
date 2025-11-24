#!/usr/bin/env bash
# lib/policy.sh — TokenHeadroom policy management

POLICY_FILE=""
POLICY_DATA=""

# Load policy or abort
policy_load_or_abort() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  POLICY_FILE="${script_dir}/context_policy.json"

  if [[ ! -f "$POLICY_FILE" ]]; then
    ui_error "Policy file not found: $POLICY_FILE"
    return 16
  fi

  if ! command -v jq &>/dev/null; then
    ui_warn "jq not found; policy validation limited"
    return 0
  fi

  if ! jq -e . "$POLICY_FILE" &>/dev/null; then
    ui_error "Invalid JSON in policy file: $POLICY_FILE"
    return 16
  fi

  POLICY_DATA="$(cat "$POLICY_FILE")"
  export POLICY_FILE POLICY_DATA
  ui_info "Policy loaded: $POLICY_FILE"
  return 0
}

# Check if a path is immutable
is_immutable() {
  local path="$1"
  if [[ -z "$POLICY_DATA" ]]; then return 1; fi

  local immutable
  immutable="$(echo "$POLICY_DATA" | jq -r '.immutable[]' 2>/dev/null || true)"

  for pattern in $immutable; do
    # Simple glob matching
    if [[ "$path" == $pattern ]]; then
      return 0
    fi
  done
  return 1
}

# Get allowed verbs for a target
get_allowed_verbs() {
  local target="$1"
  if [[ -z "$POLICY_DATA" ]]; then
    echo ""
    return
  fi
  echo "$POLICY_DATA" | jq -r ".editable[\"$target\"][]?" 2>/dev/null || true
}
