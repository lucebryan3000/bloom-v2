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

