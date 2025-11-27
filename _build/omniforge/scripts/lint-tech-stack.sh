#!/usr/bin/env bash
# Lint tech_stack scripts for meta completeness and basic hygiene
set -euo pipefail
IFS=$'\n\t'

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tech_stack_dir="$root_dir/tech_stack"
fail=0

check_meta_field() {
  local file="$1" field="$2"
  if ! grep -q "^# ${field}:" "$file"; then
    echo "[META] Missing field ${field}: $file" >&2
    fail=1
  fi
}

check_nonempty_list() {
  local file="$1" field="$2"
  local in_field=0
  local has_item=0
  while IFS= read -r line; do
    if [[ $line =~ ^#\ ${field}: ]]; then
      in_field=1
      continue
    fi
    if (( in_field )); then
      if [[ $line =~ ^#\ \ \ -\  ]]; then
        has_item=1
        break
      fi
      if [[ $line =~ ^#\ [A-Za-z0-9_]+: ]] || [[ $line =~ ^#!endmeta ]]; then
        break
      fi
    fi
  done < "$file"
  if (( ! has_item )); then
    echo "[META] Empty ${field} in $file" >&2
    fail=1
  fi
}

while IFS= read -r -d '' f; do
  # Required fields
  check_meta_field "$f" "id"
  check_meta_field "$f" "phase"
  check_meta_field "$f" "profile_tags"
  check_meta_field "$f" "uses_from_omni_config"
  check_meta_field "$f" "uses_from_omni_settings"
  check_meta_field "$f" "dependencies"
  # Non-empty list hints (best-effort)
  check_nonempty_list "$f" "uses_from_omni_settings"
  # Numeric phase
  phase=$(grep "^# phase:" "$f" | head -1 | awk '{print $3}')
  if ! [[ "$phase" =~ ^[0-9]+$ ]]; then
    echo "[META] Non-numeric phase in $f" >&2
    fail=1
  fi
  # parse_stack_flags usage
  if ! grep -q "parse_stack_flags" "$f"; then
    echo "[FLAGS] parse_stack_flags missing in $f" >&2
    fail=1
  fi
  # DRY_RUN guard
  if ! grep -q "DRY_RUN: skipping" "$f"; then
    echo "[DRY_RUN] skip guard missing in $f" >&2
    fail=1
  fi
  # Syntax check
  if ! bash -n "$f"; then
    echo "[SYNTAX] bash -n failed: $f" >&2
    fail=1
  fi

done < <(find "$tech_stack_dir" -name "*.sh" -type f -print0)

if [[ $fail -ne 0 ]]; then
  echo "Lint failed" >&2
  exit 1
fi

echo "Lint passed"
