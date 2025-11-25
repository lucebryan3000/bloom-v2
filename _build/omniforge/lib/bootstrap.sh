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

# Preserve environment overrides for Section 1 (QUICK START) values
_OF_SECTION1_VARS=(
  APP_NAME APP_VERSION APP_DESCRIPTION
  INSTALL_TARGET STACK_PROFILE
  DB_NAME DB_USER DB_PASSWORD DB_HOST DB_PORT
  ENABLE_AUTHJS ENABLE_AI_SDK ENABLE_PG_BOSS ENABLE_SHADCN
  ENABLE_ZUSTAND ENABLE_PDF_EXPORTS ENABLE_TEST_INFRA ENABLE_CODE_QUALITY
)
declare -A _OF_ENV_OVERRIDES=()
for _v in "${_OF_SECTION1_VARS[@]}"; do
  if [[ -n "${_v}" && -n "${!_v+x}" ]]; then
    _OF_ENV_OVERRIDES["$_v"]="${!_v}"
  fi
done

# Load canonical config for non-Section 1 domains (profiles, phases, advanced settings)
if [[ -f "$BOOTSTRAP_CONF" ]]; then
  set -a
  # shellcheck source=/dev/null
  . "$BOOTSTRAP_CONF"
  set +a
else
  echo "lib/bootstrap.sh: missing config at $BOOTSTRAP_CONF" >&2
  exit 1
fi

# Optional override layer for Section 1 (QUICK START) and related settings (canonical for Section 1)
OMNI_CONFIG_PATH="${OMNI_CONFIG_PATH:-${OF_ROOT_DIR}/omni.config}"
if [[ -f "$OMNI_CONFIG_PATH" ]]; then
  # shellcheck source=/dev/null
  . "$OMNI_CONFIG_PATH"
else
  echo "lib/bootstrap.sh: missing omni.config at $OMNI_CONFIG_PATH (Section 1 must live in omni.config)" >&2
  exit 1
fi

# Re-apply env overrides (env > omni.config > bootstrap.conf)
for _v in "${_OF_SECTION1_VARS[@]}"; do
  if [[ -n "${_OF_ENV_OVERRIDES[$_v]+x}" ]]; then
    export "${_v}=${_OF_ENV_OVERRIDES[$_v]}"
  fi
done
unset _OF_SECTION1_VARS _OF_ENV_OVERRIDES _v

# Load profile data (canonical) and helpers
OMNI_PROFILES_PATH="${OMNI_PROFILES_PATH:-${OF_ROOT_DIR}/omni.profiles.sh}"
if [[ -f "$OMNI_PROFILES_PATH" ]]; then
  # shellcheck source=/dev/null
  . "$OMNI_PROFILES_PATH"
else
  echo "lib/bootstrap.sh: missing omni.profiles.sh at $OMNI_PROFILES_PATH (profile data is required)" >&2
  exit 1
fi
if [[ -f "${OF_ROOT_DIR}/lib/omni_profiles.sh" ]]; then
  # shellcheck source=/dev/null
  . "${OF_ROOT_DIR}/lib/omni_profiles.sh"
fi

# Load phase metadata (canonical)
OMNI_PHASES_PATH="${OMNI_PHASES_PATH:-${OF_ROOT_DIR}/omni.phases.sh}"
if [[ -f "$OMNI_PHASES_PATH" ]]; then
  # shellcheck source=/dev/null
  . "$OMNI_PHASES_PATH"
else
  echo "lib/bootstrap.sh: missing omni.phases.sh at $OMNI_PHASES_PATH (phase metadata is required)" >&2
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
