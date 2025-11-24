#!/usr/bin/env bash
# lib/ci.sh — TokenHeadroom CI/automation support

CI_REPORT=""
CI_FINDINGS=0

# Initialize CI report structure
ci_init_report() {
  CI_REPORT="{\"tool\":\"TokenHeadroom\",\"version\":\"1.1.1\",\"timestamp\":\"$(date -u +'%Y-%m-%dT%H:%M:%SZ')\",\"findings\":[]}"
  CI_FINDINGS=0
}

# Add finding to CI report
ci_add_finding() {
  local severity="$1" category="$2" message="$3"
  if [[ -z "$CI_REPORT" ]]; then return; fi

  CI_FINDINGS=$((CI_FINDINGS + 1))
  local finding
  finding="{\"id\":$CI_FINDINGS,\"severity\":\"$severity\",\"category\":\"$category\",\"message\":\"$message\"}"
  CI_REPORT="$(echo "$CI_REPORT" | jq ".findings += [$finding]" 2>/dev/null || echo "$CI_REPORT")"
}

# Finalize and write report, then exit
ci_finalize_and_exit() {
  local exit_code=0

  if [[ "$CI_FINDINGS" -gt 0 ]]; then
    exit_code=8  # Findings present
  fi

  if [[ -n "${JSON_REPORT:-}" ]]; then
    echo "$CI_REPORT" | jq '.' > "$JSON_REPORT" 2>/dev/null || echo "$CI_REPORT" > "$JSON_REPORT"
    ui_info "JSON report written: $JSON_REPORT"
  fi

  if [[ "${CI_MODE:-0}" -eq 1 ]]; then
    exit $exit_code
  fi
}
