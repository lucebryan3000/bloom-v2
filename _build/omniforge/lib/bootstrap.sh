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

set -Eeuo pipefail
IFS=$'\n\t'

# Resolve Omniforge root directory
OF_ROOT_DIR="${OF_ROOT_DIR:-$(cd -- "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# Align with common.sh expectations
SCRIPTS_DIR="${SCRIPTS_DIR:-${OF_ROOT_DIR}}"
BOOTSTRAP_CONF="${BOOTSTRAP_CONF:-${SCRIPTS_DIR}/bootstrap.conf}"
BOOTSTRAP_CONF_EXAMPLE="${BOOTSTRAP_CONF_EXAMPLE:-${SCRIPTS_DIR}/bootstrap.conf.example}"
export SCRIPTS_DIR BOOTSTRAP_CONF BOOTSTRAP_CONF_EXAMPLE

# Load canonical config (bootstrap.conf remains canonical in this phase)
if [[ -f "$BOOTSTRAP_CONF" ]]; then
  set -a
  # shellcheck source=/dev/null
  . "$BOOTSTRAP_CONF"
  set +a
else
  echo "lib/bootstrap.sh: missing config at $BOOTSTRAP_CONF" >&2
  exit 1
fi

# Delegate to common.sh for full loader stack
# shellcheck source=/dev/null
. "${SCRIPTS_DIR}/lib/common.sh"

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
