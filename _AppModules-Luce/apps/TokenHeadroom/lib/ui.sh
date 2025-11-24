#!/usr/bin/env bash
# lib/ui.sh — TokenHeadroom UI utilities

# Colors
_C_RESET='\033[0m'
_C_RED='\033[0;31m'
_C_GREEN='\033[0;32m'
_C_YELLOW='\033[0;33m'
_C_BLUE='\033[0;34m'
_C_CYAN='\033[0;36m'
_C_BOLD='\033[1m'

ui_clear() { printf '\033[2J\033[H'; }

ui_header() {
  local title="${1:-}"
  echo -e "${_C_BOLD}${_C_CYAN}═══════════════════════════════════════════════════════════════${_C_RESET}"
  echo -e "${_C_BOLD}${_C_CYAN}  ${title}${_C_RESET}"
  echo -e "${_C_BOLD}${_C_CYAN}═══════════════════════════════════════════════════════════════${_C_RESET}"
  echo
}

ui_info() { echo -e "${_C_BLUE}[INFO]${_C_RESET} $*"; }
ui_result() { echo -e "${_C_GREEN}[OK]${_C_RESET} $*"; }
ui_warn() { echo -e "${_C_YELLOW}[WARN]${_C_RESET} $*"; }
ui_error() { echo -e "${_C_RED}[ERR]${_C_RESET} $*" >&2; }

ui_pause() {
  echo
  read -r -p "Press Enter to continue..." || true
}

# Confirmation gate: returns 0 if confirmed, 1 if cancelled
# $1 = require_confirm (1=yes), $2 = is_critical (1=yes)
confirm_gate() {
  local require="${1:-1}" critical="${2:-0}"
  if [[ "${YES_ALL:-0}" -eq 1 ]] && [[ "$critical" -eq 0 ]]; then
    return 0
  fi
  if [[ "${FORCE:-0}" -eq 1 ]]; then
    return 0
  fi
  if [[ "$require" -eq 0 ]]; then
    return 0
  fi
  local prompt="Proceed? [y/N]: "
  [[ "$critical" -eq 1 ]] && prompt="[CRITICAL] Proceed? [y/N]: "
  printf "%s" "$prompt"
  read -r ans || true
  [[ "$ans" =~ ^[Yy]$ ]] && return 0
  return 1
}

# Double confirmation for critical operations
double_confirm_if_critical() {
  local critical="${1:-0}"
  if [[ "$critical" -eq 0 ]]; then return 0; fi
  if [[ "${FORCE:-0}" -eq 1 ]]; then return 0; fi
  printf "Type 'yes' to confirm critical operation: "
  read -r ans || true
  [[ "$ans" == "yes" ]] && return 0
  ui_warn "Aborted."
  return 1
}
