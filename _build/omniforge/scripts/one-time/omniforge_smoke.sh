#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OMNI_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

cd "$OMNI_ROOT"

log()  { printf '[smoke] %s\n' "$*"; }
warn() { printf '[smoke][WARN] %s\n' "$*"; }

run_cmd() {
  local desc="$1"; shift
  log "$desc"
  if "$@"; then
    log "$desc: OK"
  else
    log "$desc: FAILED"
    exit 1
  fi
}

run_cmd "./omni.sh status" ./omni.sh status
run_cmd "./omni.sh list"   ./omni.sh list

warn "./omni.sh menu: SKIPPED (interactive)"
warn "./omni.sh reset: SKIPPED (destructive)"
warn "./omni.sh run: SKIPPED (mutating/heavy)"
warn "./omni.sh build/forge: SKIPPED (mutating/heavy)"
# warn "./omni.sh clean --path /tmp/omniforge-smoke.$$ --level 1: SKIPPED (enable manually if desired)"

log "Smoke complete."
