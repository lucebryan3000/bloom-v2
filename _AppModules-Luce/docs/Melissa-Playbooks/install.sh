#!/usr/bin/env bash
set -euo pipefail

# This script should be run from the /bloom/_build-prompts/Melissa-Playbooks directory.
# It assumes the repo root is TWO directories up from this script.

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

run_step "1_schema_and_migrate.sh"
run_step "2_config_services.sh"
run_step "3_markdown_spec.sh"
run_step "4_compile_pipeline.sh"
run_step "5_settings_prompt.sh"
run_step "6_session_context.sh"

echo ""
echo "All steps completed. Review git diff, run tests, and wire remaining pieces as needed."
