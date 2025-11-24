#!/usr/bin/env bash
# registry.sh — loads libs/menus/verbs and registers them

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load additional libs first
source "${SCRIPT_DIR}/lib/dispatch.sh"
source "${SCRIPT_DIR}/lib/analysis.sh"

# Verbs
for f in "${SCRIPT_DIR}/verbs/"*.sh; do
  [[ -f "$f" ]] && source "$f"
done

# Menus
for f in "${SCRIPT_DIR}/menus/"*.sh; do
  [[ -f "$f" ]] && source "$f"
done
