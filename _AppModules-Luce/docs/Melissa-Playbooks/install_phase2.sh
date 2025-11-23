#!/usr/bin/env bash
set -euo pipefail

# Phase 2 installer: engine, tests, cleanup prompts.
# Run this from bloom/_build-prompts/Melissa-Playbooks directory.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
echo "==> Bloom repo root: ${ROOT_DIR}"
cd "${ROOT_DIR}"

run_step() {
  local script="$1"
  if [[ ! -x "_build-prompts/Melissa-Playbooks/${script}" ]]; then
    echo "ERROR: _build-prompts/Melissa-Playbooks/${script} not found or not executable."
    exit 1
  fi
  echo ""
  echo "────────────────────────────────────────"
  echo " Running ${script}"
  echo "────────────────────────────────────────"
  "_build-prompts/Melissa-Playbooks/${script}"
  echo "✓ ${script} completed"
}

run_step "7_ifl_and_prompt_builder.sh"
run_step "8_tests_prompt.sh"
run_step "9_cleanup_prompt.sh"

echo ""
echo "Phase 2 scripts complete. You now have stubs/prompts for engine, tests, and cleanup."
