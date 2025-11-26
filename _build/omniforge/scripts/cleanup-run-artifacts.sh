#!/usr/bin/env bash
# =============================================================================
# cleanup-run-artifacts.sh - remove common local run artifacts
# =============================================================================
# Safely removes transient outputs from OmniForge runs so you can start clean.
# Targets (if they exist):
#   - full-stack-live/          (install directory created during live runs)
#   - package.json (stub)       (root stub created by earlier experiments)
#
# Usage:
#   ./_build/omniforge/scripts/cleanup-run-artifacts.sh          # prompt before deleting
#   ./_build/omniforge/scripts/cleanup-run-artifacts.sh --yes    # no prompt
#   ./_build/omniforge/scripts/cleanup-run-artifacts.sh --dry-run
#
# Environment:
#   CONFIRM_CLEANUP=true  # skip prompt (same as --yes)
#   DRY_RUN=true          # preview only (same as --dry-run)
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Resolve project root (two levels up from _build/omniforge/scripts)
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
# If inside a git repo, prefer the repo root
if command -v git >/dev/null 2>&1; then
  if git -C "${SCRIPT_DIR}" rev-parse --show-toplevel >/dev/null 2>&1; then
    PROJECT_ROOT="$(git -C "${SCRIPT_DIR}" rev-parse --show-toplevel)"
  fi
fi

CONFIRM="${CONFIRM_CLEANUP:-false}"
DRY="${DRY_RUN:-false}"

for arg in "$@"; do
  case "$arg" in
    --yes|-y) CONFIRM="true" ;;
    --dry-run) DRY="true" ;;
    *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

log() { echo "[cleanup] $*"; }
warn() { echo "[cleanup][WARN] $*" >&2; }

confirm_or_exit() {
  if [[ "$CONFIRM" == "true" || "$DRY" == "true" ]]; then
    return 0
  fi
  read -r -p "Proceed with cleanup? [y/N] " ans
  if [[ "${ans,,}" != "y" ]]; then
    log "Aborted."
    exit 0
  fi
}

remove_path() {
  local target="$1"
  local reason="$2"
  if [[ ! -e "$target" ]]; then
    return 0
  fi
  if [[ "$DRY" == "true" ]]; then
    log "[dry-run] Would remove ${reason}: ${target#$PROJECT_ROOT/}"
    return 0
  fi
  rm -rf "$target"
  log "Removed ${reason}: ${target#$PROJECT_ROOT/}"
}

log "Project root: ${PROJECT_ROOT}"

# Confirm once up front (unless dry-run)
confirm_or_exit

# 1) full-stack-live directory
remove_path "${PROJECT_ROOT}/full-stack-live" "install directory"

# 2) package.json stub (only if it looks like the stub)
PKG_JSON="${PROJECT_ROOT}/package.json"
if [[ -f "$PKG_JSON" ]]; then
  if grep -q '"name": "stub"' "$PKG_JSON" 2>/dev/null; then
    remove_path "$PKG_JSON" "stub package.json"
  else
    warn "Skipped package.json (does not look like the stub). Remove manually if intended."
  fi
fi

log "Cleanup complete."
