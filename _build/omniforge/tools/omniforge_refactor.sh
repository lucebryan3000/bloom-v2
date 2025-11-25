#!/usr/bin/env bash
#
# omniforge_refactor.sh
#
# Phase 1 – NON-DESTRUCTIVE scaffolding and staging:
#   - Auto-create a feature branch if run on main/master
#   - Require clean git state under _build/omniforge
#   - Create omni.config as a staging mirror (header + Section 1 only)
#   - Create lib/omni_profiles.sh with copied profile helper functions
#   - Create lib/bootstrap.sh as future canonical loader (NOT wired yet)
#   - Append a staging note to bootstrap.conf
#
# NO BEHAVIOR CHANGES:
#   - omni.sh and bin/* are untouched
#   - bootstrap.conf remains the only active runtime config
#
# Usage (from _build/omniforge):
#   ./tools/omniforge_refactor.sh phase1
#
set -Eeuo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OMNI_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

trap 'echo "[omniforge-refactor][ERROR] command failed at line $LINENO" >&2' ERR

log()  { printf '[omniforge-refactor] %s\n' "$*" >&2; }
warn() { printf '[omniforge-refactor][WARN] %s\n' "$*" >&2; }
err()  { printf '[omniforge-refactor][ERROR] %s\n' "$*" >&2; exit 1; }

require_dir() {
  local d="$1"
  [[ -d "$d" ]] || err "Required directory missing: $d"
}

require_file() {
  local f="$1"
  [[ -f "$f" ]] || err "Required file missing: $f"
}

validate_bash_file() {
  local f="$1"
  if [[ ! -f "$f" ]]; then
    warn "validate_bash_file: missing file $f"
    return 0
  fi

  local tmp
  tmp="$(mktemp /tmp/omniforge_bash_check.XXXXXX 2>/dev/null)" || {
    warn "validate_bash_file: could not allocate temp file; skipping bash -n for $f"
    return 1
  }

  if ! bash -n "$f" 2>"$tmp"; then
    warn "bash -n failed for $f"
    warn "---- bash -n output ----"
    sed 's/^/[bash -n] /' "$tmp" >&2 || true
    rm -f "$tmp" || true
    return 1
  fi
  rm -f "$tmp" || true
  return 0
}

ensure_git_safety_and_branch() {
  # Only do this if we’re in a git repo
  if ! git -C "$OMNI_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    warn "Not in a git repository at $OMNI_ROOT; skipping branch and clean-state checks."
    return 0
  fi

  # Ensure clean state under _build/omniforge (rooted at OMNI_ROOT)
  local dirty
  dirty="$(git -C "$OMNI_ROOT" status --porcelain .)"
  if [[ -n "$dirty" ]]; then
    err "Uncommitted changes under $OMNI_ROOT. Commit or stash before running this refactor."
  fi

  local current_branch
  current_branch="$(git -C "$OMNI_ROOT" rev-parse --abbrev-ref HEAD)"

  # If on main/master, auto-create a feature branch with numeric suffix
  if [[ "$current_branch" == "main" || "$current_branch" == "master" ]]; then
    local base="omniforge-refactor-phase1"
    local candidate="$base"
    local n=1

    while git -C "$OMNI_ROOT" rev-parse --verify --quiet "refs/heads/$candidate" >/dev/null; do
      n=$((n + 1))
      candidate="${base}-${n}"
    done

    log "Current branch is '$current_branch'. Creating feature branch '$candidate' for refactor."
    git -C "$OMNI_ROOT" checkout -b "$candidate"
    log "Now on branch: $(git -C "$OMNI_ROOT" rev-parse --abbrev-ref HEAD)"
  else
    log "Using existing branch: $current_branch"
  fi
}

phase1_scaffold() {
  log "Phase 1: Non-destructive staging + scaffolding"

  require_dir "$OMNI_ROOT/lib"
  require_dir "$OMNI_ROOT/bin"
  require_file "$OMNI_ROOT/bootstrap.conf"
  require_file "$OMNI_ROOT/omni.sh"

  local BOOTSTRAP_CONF="$OMNI_ROOT/bootstrap.conf"
  local OMNI_CONFIG="$OMNI_ROOT/omni.config"
  local OMNI_PROFILES="$OMNI_ROOT/lib/omni_profiles.sh"
  local BOOTSTRAP_LIB="$OMNI_ROOT/lib/bootstrap.sh"

  # --- 1) Create omni.config if missing (staging only) ----------------------

  if [[ -f "$OMNI_CONFIG" ]]; then
    log "omni.config already exists; will NOT overwrite. Skipping staging of header + Section 1."
  else
    log "Creating omni.config staging file"
    cat >"$OMNI_CONFIG" <<'EOF'
#!/usr/bin/env bash
# =============================================================================
# OmniForge Staged Config (omni.config)
# =============================================================================
# This file is being built incrementally.
# During this refactor, bootstrap.conf remains the active runtime config.
# DO NOT wire omni.config into runtime yet.
#
# Future refactor will:
#   - Switch loaders to source omni.config
#   - Turn bootstrap.conf into a thin shim or remove it.
# =============================================================================

EOF

    log "Staging header + SECTION 1: QUICK START from bootstrap.conf into omni.config"

    # Copy header (everything before SECTION 1) from bootstrap.conf
    awk '
      /SECTION 1: QUICK START - USER CONFIGURABLE/ { exit }
      { print }
    ' "$BOOTSTRAP_CONF" >>"$OMNI_CONFIG"

    printf '\n# =============================================================================\n' >>"$OMNI_CONFIG"
    printf '# STAGED SECTION 1: QUICK START (mirror from bootstrap.conf)\n' >>"$OMNI_CONFIG"
    printf '# NOTE: bootstrap.conf remains canonical at runtime.\n' >>"$OMNI_CONFIG"
    printf '# Any changes here must be manually kept in sync until cutover.\n' >>"$OMNI_CONFIG"
    printf '# =============================================================================\n\n' >>"$OMNI_CONFIG"

    # Copy SECTION 1 body from bootstrap.conf
    awk '
      /SECTION 1: QUICK START - USER CONFIGURABLE/ { in_section=1 }
      /SECTION 2: ADVANCED SETTINGS/ { if (in_section) exit }
      in_section { print }
    ' "$BOOTSTRAP_CONF" >>"$OMNI_CONFIG"
  fi

  # --- 2) Create lib/omni_profiles.sh and copy profile functions ------------

  if [[ -f "$OMNI_PROFILES" ]]; then
    warn "lib/omni_profiles.sh already exists; not regenerating."
  else
    log "Creating lib/omni_profiles.sh (staged profile helper functions)"

    cat >"$OMNI_PROFILES" <<'EOF'
#!/usr/bin/env bash
#
# lib/omni_profiles.sh
#
# Staged copy of stack profile helper functions from bootstrap.conf.
# NOT wired into runtime yet; bootstrap.conf remains canonical.
#

EOF

    # Extract the three functions from bootstrap.conf and append to omni_profiles.sh
    # We rely on function definitions of the form: name() { ... }
    awk '
      /^[[:space:]]*apply_stack_profile[[:space:]]*\(\)[[:space:]]*\{/   { capture=1; depth=0 }
      /^[[:space:]]*get_profile_by_number[[:space:]]*\(\)[[:space:]]*\{/ { capture=1; depth=0 }
      /^[[:space:]]*get_profile_metadata[[:space:]]*\(\)[[:space:]]*\{/  { capture=1; depth=0 }

      capture {
        print
        # crude brace counter to find function end
        for (i=1; i<=NF; i++) {
          n = split($i, a, "")
          for (j=1; j<=n; j++) {
            if (a[j] == "{") depth++
            if (a[j] == "}") depth--
          }
        }
        if (depth <= 0 && /\}/) {
          print ""  # blank line between functions
          capture=0
          depth=0
        }
      }
    ' "$BOOTSTRAP_CONF" >>"$OMNI_PROFILES" || warn "Could not reliably extract profile functions; please review lib/omni_profiles.sh manually."
  fi

  # --- 3) Append a staging note to the bottom of bootstrap.conf  ------------

  if ! grep -q 'STAGING NOTE' "$BOOTSTRAP_CONF"; then
    log "Appending staging note to bootstrap.conf"
    cat >>"$BOOTSTRAP_CONF" <<'EOF'

# =============================================================================
# STAGING NOTE
# =============================================================================
# Portions of this config are being mirrored into omni.config for the upcoming
# refactor. For now, bootstrap.conf remains the active runtime config.
# Staged so far:
#   - SECTION 1: QUICK START
# Profile helper functions have been copied to lib/omni_profiles.sh for future
# wiring, but bootstrap.conf remains canonical at runtime.
# =============================================================================
EOF
  else
    log "bootstrap.conf already contains a STAGING NOTE; leaving as-is."
  fi

  # --- 4) Create lib/bootstrap.sh as staged canonical loader -----------------

  if [[ -f "$BOOTSTRAP_LIB" ]]; then
    warn "lib/bootstrap.sh already exists; not overwriting."
  else
    log "Creating lib/bootstrap.sh (future canonical loader, NOT used yet)"

    cat >"$BOOTSTRAP_LIB" <<'EOF'
#!/usr/bin/env bash
#
# lib/bootstrap.sh
#
# Future canonical Omniforge bootstrap loader.
# In this refactor phase, omni.sh does NOT use this yet.
# It is staged here so that a later refactor can safely wire omni.sh to it.
#

# Guard: only initialize once per shell
if [[ -n "${OF_BOOTSTRAP_LOADED:-}" ]]; then
  return 0 2>/dev/null || exit 0
fi
OF_BOOTSTRAP_LOADED=1

# Resolve Omniforge root directory
OF_ROOT_DIR="${OF_ROOT_DIR:-$(cd -- "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
OF_CONF_PATH="${OF_CONF_PATH:-"${OF_ROOT_DIR}/bootstrap.conf"}"

# Load canonical config (bootstrap.conf remains canonical in this phase)
if [[ -f "$OF_CONF_PATH" ]]; then
  set -a
  # shellcheck source=/dev/null
  . "$OF_CONF_PATH"
  set +a
else
  echo "lib/bootstrap.sh: missing config at $OF_CONF_PATH" >&2
  exit 1
fi

# Helper for loading libs
_of_load() {
  # shellcheck source=/dev/null
  . "${OF_ROOT_DIR}/lib/$1"
}

# Core libs (load if present)
[[ -f "${OF_ROOT_DIR}/lib/common.sh"           ]] && _of_load "common.sh"
[[ -f "${OF_ROOT_DIR}/lib/logging.sh"          ]] && _of_load "logging.sh"
[[ -f "${OF_ROOT_DIR}/lib/utils.sh"            ]] && _of_load "utils.sh"
[[ -f "${OF_ROOT_DIR}/lib/state.sh"            ]] && _of_load "state.sh"
[[ -f "${OF_ROOT_DIR}/lib/settings_manager.sh" ]] && _of_load "settings_manager.sh"
[[ -f "${OF_ROOT_DIR}/lib/scaffold.sh"         ]] && _of_load "scaffold.sh"
[[ -f "${OF_ROOT_DIR}/lib/setup.sh"            ]] && _of_load "setup.sh"
[[ -f "${OF_ROOT_DIR}/lib/log-rotation.sh"     ]] && _of_load "log-rotation.sh"

# Optional prereq helpers
[[ -f "${OF_ROOT_DIR}/lib/prereqs.sh"          ]] && _of_load "prereqs.sh"
[[ -f "${OF_ROOT_DIR}/lib/prereqs-local.sh"    ]] && _of_load "prereqs-local.sh"

# Future hook points (only run if implemented)
if declare -F of_state_init >/dev/null 2>&1; then
  of_state_init
fi
if declare -F of_prereqs_detect >/dev/null 2>&1; then
  of_prereqs_detect
fi
if declare -F of_logging_init >/dev/null 2>&1; then
  of_logging_init
fi

EOF
    chmod +x "$BOOTSTRAP_LIB"
  fi

  # --- 5) Validate staged files ---------------------------------------------

  log "Validating staged bash files with bash -n"

  validate_bash_file "$BOOTSTRAP_CONF"   || err "bootstrap.conf failed bash -n"
  validate_bash_file "$OMNI_CONFIG"      || err "omni.config failed bash -n"
  validate_bash_file "$OMNI_PROFILES"    || warn "lib/omni_profiles.sh failed bash -n; please review manually."
  validate_bash_file "$BOOTSTRAP_LIB"    || err "lib/bootstrap.sh failed bash -n"

  log "Phase 1 staging complete."

  cat <<'MSG'

=== PHASE 1 COMPLETE (NO BEHAVIOR CHANGE) ===

Staged artifacts created:

  - omni.config (header + SECTION 1: QUICK START mirror)
  - lib/omni_profiles.sh (copy of apply_stack_profile/get_profile_* helpers)
  - lib/bootstrap.sh (future canonical loader, NOT used yet)
  - bootstrap.conf annotated with a STAGING NOTE

Runtime remains unchanged:
  - omni.sh still uses the existing bootstrap chain.
  - bootstrap.conf is still the only active config.

NEXT (for Codex / you):

  1) Compare bootstrap.conf SECTION 1 vs omni.config:
       - Confirm the staged copy is accurate.
       - Decide what the eventual omni.config-only shape should be.

  2) Compare profile helpers in bootstrap.conf vs lib/omni_profiles.sh:
       - Confirm the functions are identical.
       - Plan how/when to wire lib/omni_profiles.sh into bootstrap.sh/common.sh
         in a later refactor.

  3) Review lib/bootstrap.sh:
       - Confirm it loads the correct libs.
       - Decide how omni.sh should eventually delegate to lib/bootstrap.sh
         (in a future, separate refactor phase).

This phase is intentionally NON-DESTRUCTIVE. All behavior should remain
exactly as before; only scaffolding and staging were added.
MSG
}

usage() {
  cat <<EOF
Usage:
  $(basename "$0") phase1   # scaffold omni.config, lib/omni_profiles.sh, lib/bootstrap.sh (non-destructive)
EOF
}

main() {
  local phase="${1:-}"

  case "$phase" in
    phase1)
      ensure_git_safety_and_branch
      phase1_scaffold
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
