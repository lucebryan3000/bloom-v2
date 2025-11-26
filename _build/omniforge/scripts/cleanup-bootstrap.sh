#!/usr/bin/env bash
# =============================================================================
# cleanup-bootstrap.sh - reset OmniForge workspace and Docker for a fresh run
# =============================================================================
# This script:
#   - Stops and removes docker-compose services and volumes
#   - Removes bootstrap state markers
#   - Removes generated app files for a clean bootstrap (no user data)
#   - Leaves git-tracked files intact (only deletes common generated files)
#
# Options:
#   --yes / -y     : skip confirmation
#   --dry-run      : show what would be removed/stopped
#   --keep-app     : do NOT delete app files (package.json/src/etc)
#
# Usage:
#   ./_build/omniforge/scripts/cleanup-bootstrap.sh           # prompt
#   ./_build/omniforge/scripts/cleanup-bootstrap.sh --yes     # no prompt
#   ./_build/omniforge/scripts/cleanup-bootstrap.sh --dry-run # preview
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

CONFIRM="false"
DRY="false"
KEEP_APP="false"
LOG_DIR="${PROJECT_ROOT}/_build/omniforge/logs/cleanup"
LOG_FILE="${LOG_DIR}/cleanup_$(date +%Y%m%d_%H%M%S).log"
LOG_RETENTION="${LOG_RETENTION:-7}"

for arg in "$@"; do
  case "$arg" in
    --yes|-y) CONFIRM="true" ;;
    --dry-run) DRY="true" ;;
    --keep-app) KEEP_APP="true" ;;
    *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

log()  { echo "[cleanup] $*"; }
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

# Ensure log directory
mkdir -p "${LOG_DIR}"

# Always log (unless dry-run); dry-run still shows actions but does not write log
if [[ "$DRY" == "false" ]]; then
  exec > >(tee -a "$LOG_FILE") 2>&1
else
  log "[dry-run] Logging disabled in dry-run mode"
fi

log "Project root: ${PROJECT_ROOT}"
confirm_or_exit

# 1) Stop/remove docker stack and volumes
if command -v docker >/dev/null 2>&1; then
  if [[ "$DRY" == "true" ]]; then
    log "[dry-run] Would run: docker compose down --volumes"
  else
    log "Stopping docker compose stack (with volumes)..."
    if ! docker compose down --volumes >/dev/null 2>&1; then
      warn "docker compose down --volumes failed; continuing."
    fi
  fi
else
  warn "Docker not found; skipping compose down."
fi

# 2) Remove bootstrap state
remove_path "${PROJECT_ROOT}/.bootstrap_state" "bootstrap state"

# 3) Remove app artifacts (unless --keep-app)
if [[ "$KEEP_APP" != "true" ]]; then
  APP_PATHS=(
    "package.json"
    "pnpm-lock.yaml"
    "node_modules"
    "next.config.ts"
    "tsconfig.json"
    "src"
    "public"
    ".next"
    "drizzle.config.ts"
    "postcss.config.mjs"
    "tailwind.config.ts"
    "components.json"
  )
  for p in "${APP_PATHS[@]}"; do
    remove_path "${PROJECT_ROOT}/${p}" "app artifact"
  done
else
  log "Skipping app artifact removal (--keep-app)"
fi

# 4) Remove install dirs we use for runs
remove_path "${PROJECT_ROOT}/full-stack-live" "install directory"
remove_path "${PROJECT_ROOT}/workspace" "install directory (if created)"

# 5) Prune old cleanup logs
if [[ "$DRY" == "false" ]]; then
  find "${LOG_DIR}" -type f -name "cleanup_*.log" -printf '%T@ %p\n' 2>/dev/null \
    | sort -nr \
    | awk "NR>${LOG_RETENTION}" \
    | cut -d' ' -f2- \
    | while read -r oldlog; do
        rm -f "$oldlog" && log "Pruned old log: ${oldlog##*/}"
      done
fi

log "Cleanup complete."
