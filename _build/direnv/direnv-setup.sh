#!/usr/bin/env bash
# =============================================================================
# direnv-setup.sh
# Description: Helper to install direnv and create project-local env helpers.
# Functions:
#   - action_install_direnv: Install direnv via common package managers.
#   - action_create_envrc: Create/overwrite .envrc with a validated PATH entry.
#   - action_create_env_helper: Create/overwrite env.sh helper for PATH.
# Author: Bryan Luce
# Last modified: 2025-11-27
# Contract: Simple Utility Menu v1.0
# Menu Map:
#   main_menu
#     -> submenu_advanced
# =============================================================================

set -Eeuo pipefail

SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAST_MODIFIED="2025-11-26"

PROJECT_ROOT=""
ENVRC_PATH=""
ENV_HELPER_PATH=""

on_error() {
  local exit_code=$?
  local line=${BASH_LINENO[0]:-unknown}
  printf 'ERROR: %s failed at line %s (exit=%s)\n' "${SCRIPT_NAME}" "${line}" "${exit_code}" >&2
  exit "${exit_code}"
}

cleanup() { :; }

trap cleanup EXIT
trap on_error ERR

# Color setup (tput if available, fallback to plain)
if command -v tput >/dev/null 2>&1 && [[ -t 1 ]]; then
  _NORM="$(tput sgr0 || true)"
  _BOLD="$(tput bold || true)"
  _FG_RED="$(tput setaf 1 || true)"
  _FG_GREEN="$(tput setaf 2 || true)"
  _FG_YELLOW="$(tput setaf 3 || true)"
else
  _NORM=""
  _BOLD=""
  _FG_RED=""
  _FG_GREEN=""
  _FG_YELLOW=""
fi

detect_project_root() {
  local candidate=""

  if [[ -n "${PROJECT_ROOT:-}" && -d "${PROJECT_ROOT}" ]]; then
    candidate="${PROJECT_ROOT}"
  elif command -v git >/dev/null 2>&1; then
    candidate="$(git -C "${SCRIPT_DIR}" rev-parse --show-toplevel 2>/dev/null || true)"
  fi

  if [[ -z "${candidate}" ]]; then
    candidate="${SCRIPT_DIR}/../.."
  fi

  if [[ ! -d "${candidate}" ]]; then
    candidate="${SCRIPT_DIR}"
  fi

  PROJECT_ROOT="$(cd "${candidate}" && pwd)"
  ENVRC_PATH="${PROJECT_ROOT}/.envrc"
  ENV_HELPER_PATH="${PROJECT_ROOT}/env.sh"
}

ui_clear() {
  command -v clear >/dev/null 2>&1 && clear || printf '\n'
  printf '\n'
}

ui_header() {
  local title="${1:-Menu}"
  local cols width inner_width border padded_title
  cols="$(tput cols 2>/dev/null || echo 80)"
  width=$(( cols > 40 ? cols : 80 ))
  inner_width=$(( width - 4 ))

  printf '\n'
  printf -v border '%*s' "${inner_width}" ''
  border=${border// /-}

  printf '+-%s-+\n' "${border}"
  printf -v padded_title '%*s' "${inner_width}" "${title}"
  printf '|%s|\n' "${padded_title}"
  printf '+-%s-+\n\n' "${border}"
}

ui_info() {
  printf '%s%s%s\n' "${_BOLD}" "$*" "${_NORM}"
}

ui_warn() {
  printf '%s[WARN]%s %s\n' "${_FG_YELLOW}" "${_NORM}" "$*" >&2
}

ui_error() {
  printf '%s[ERROR]%s %s\n' "${_FG_RED}" "${_NORM}" "$*" >&2
}

ui_success() {
  printf '%s[OK]%s %s\n' "${_FG_GREEN}" "${_NORM}" "$*"
}

ui_pause() {
  printf '\nPress Enter to continue…'
  local _dummy
  read -r _dummy || true
}

render_main_menu() {
  local now
  now="$(date +'%B %d, %Y at %I:%M %p')"

  ui_clear
  ui_header "direnv setup – $(basename "${PROJECT_ROOT}")"
  ui_info "Updated: ${now}"
  ui_info "Last modified: ${LAST_MODIFIED}"
  printf '\n'

  ui_info "Quick overview"
  ui_info "  Project root: ${PROJECT_ROOT}"
  ui_info "  .envrc path : ${ENVRC_PATH}"
  ui_info "  env.sh path : ${ENV_HELPER_PATH}"
  printf '\n'

  ui_header "Quick Actions"
  printf '%s  1)%s Install & enable direnv     %sAuto-detect root; prompt install only if missing%s\n' "${_FG_YELLOW}" "${_NORM}${_BOLD}" "${_NORM}" "${_NORM}"
  printf '%s  2)%s Add PATH entry to .envrc    %sGuided walk-through (keeps existing file)%s\n' "${_FG_YELLOW}" "${_NORM}${_BOLD}" "${_NORM}" "${_NORM}"
  printf '%s  3)%s Create/overwrite env.sh     %sPer-session PATH helper (alternate to direnv)%s\n' "${_FG_YELLOW}" "${_NORM}${_BOLD}" "${_NORM}" "${_NORM}"
  printf '%s  4)%s Advanced options            %sShow PATH / direnv version%s\n' "${_FG_YELLOW}" "${_NORM}${_BOLD}" "${_NORM}" "${_NORM}"
  printf '%s  5)%s Help                        %sShow usage%s\n' "${_FG_YELLOW}" "${_NORM}${_BOLD}" "${_NORM}" "${_NORM}"
  printf '%s\n' "${_NORM}"
  ui_info "Type a number to run an action; any other key exits."
  printf '\n'
}

print_help() {
  cat <<EOF
${SCRIPT_NAME} - direnv setup helper

Usage:
  ${SCRIPT_NAME} [--help]

Description:
  Installs direnv (best-effort) and creates project-local environment helpers so
  you don't have to remember direnv CLI details for this project.

Features:
  - Auto-detect project root (git-aware) and allow direnv from there.
  - Install direnv only if missing, then enable it in the project root.
  - Guided PATH additions to .envrc without overwriting existing content.
  - Generate env.sh helper to manage PATH and project root (non-direnv option).

Menu options:
  1) Install & enable direnv
  2) Add PATH entry to .envrc (guided)
  3) Create/overwrite env.sh helper (per-session PATH, alternate to direnv)
  4) Advanced options
  5) Help

EOF
}

###############################################################################
# Actions
###############################################################################

ensure_envrc_exists() {
  if [[ -f "${ENVRC_PATH}" ]]; then
    return 0
  fi

  ui_info "No .envrc found. Creating a minimal template at: ${ENVRC_PATH}"
  cat > "${ENVRC_PATH}" <<EOF
# direnv configuration for $(basename "${PROJECT_ROOT}")
# Add project-specific PATH entries using PATH_add "dir"
# Example: PATH_add "${PROJECT_ROOT}/bin"
EOF
}

resolve_path_input() {
  local raw="${1:-}"
  [[ -z "${raw}" ]] && return 1

  local expanded="${raw/#\~/${HOME}}"
  local candidate=""

  if [[ "${expanded}" != /* ]]; then
    candidate="${PROJECT_ROOT}/${expanded}"
    if [[ -d "${candidate}" ]]; then
      (cd "${candidate}" && pwd)
      return 0
    fi
  fi

  if [[ -d "${expanded}" ]]; then
    (cd "${expanded}" && pwd)
    return 0
  fi

  return 1
}

action_install_direnv() {
  ui_info "Preparing direnv for project: ${PROJECT_ROOT}"
  ui_info "Project root detected: ${PROJECT_ROOT}"

  if command -v direnv >/dev/null 2>&1; then
    ui_success "direnv already installed at: $(command -v direnv)"
  else
    printf 'direnv is not installed. Install now? [Y/n] '
    local ans
    read -r ans || true
    case "${ans,,}" in
      n|no) ui_warn "Install skipped; direnv not enabled."; return 0 ;;
    esac

    if command -v apt-get >/dev/null 2>&1; then
      sudo apt-get update && sudo apt-get install -y direnv
    elif command -v brew >/dev/null 2>&1; then
      brew install direnv
    elif command -v pacman >/dev/null 2>&1; then
      sudo pacman -S --noconfirm direnv
    else
      ui_error "No supported package manager detected. Install manually from https://direnv.net/#install"
      return 1
    fi

    if command -v direnv >/dev/null 2>&1; then
      ui_success "direnv installed at: $(command -v direnv)"
    else
      ui_error "direnv still not available after install attempt."
      return 1
    fi
  fi

  ensure_envrc_exists

  ui_info "Allowing direnv in project root..."
  if (cd "${PROJECT_ROOT}" && direnv allow); then
    ui_success "direnv allowed for ${PROJECT_ROOT}"
  else
    ui_warn "direnv allow failed. Check ${ENVRC_PATH} for syntax issues."
  fi

  local shell_name
  shell_name="$(basename "${SHELL:-bash}")"
  ui_info "Shell hook (if not already set):"
  ui_info "  eval \"\$(direnv hook ${shell_name})\""
}

action_create_envrc() {
  ui_info "Add a PATH entry to: ${ENVRC_PATH}"
  ui_info "Relative paths resolve from project root: ${PROJECT_ROOT}"

  ensure_envrc_exists

  local add_path=""
  local resolved_path=""

  while [[ -z "${resolved_path}" ]]; do
    read -r -p "Enter a PATH directory to add (absolute or relative): " add_path || true
    resolved_path="$(resolve_path_input "${add_path}" || true)"
    if [[ -z "${resolved_path}" ]]; then
      ui_warn "Path is empty or does not exist. Try again."
    fi
  done

  local note=""
  read -r -p "Optional short description for this PATH entry: " note || true

  if grep -qF "PATH_add \"${resolved_path}\"" "${ENVRC_PATH}" 2>/dev/null; then
    ui_warn "PATH_add \"${resolved_path}\" already exists in ${ENVRC_PATH}."
    return 0
  fi

  printf '\nAbout to add to %s:\n' "${ENVRC_PATH}"
  printf '  PATH_add "%s"\n' "${resolved_path}"
  [[ -n "${note}" ]] && printf '  # %s\n' "${note}"
  printf 'Proceed? [Y/n] '
  local confirm
  read -r confirm || true
  case "${confirm,,}" in
    n|no) ui_info "No changes made to ${ENVRC_PATH}."; return 0 ;;
  esac

  {
    printf '\n# Added by %s on %s\n' "${SCRIPT_NAME}" "$(date +'%Y-%m-%d %H:%M:%S')"
    [[ -n "${note}" ]] && printf '# %s\n' "${note}"
    printf 'PATH_add "%s"\n' "${resolved_path}"
  } >> "${ENVRC_PATH}"

  ui_success "PATH entry added to ${ENVRC_PATH}"
  ui_info "Re-run 'direnv allow' in ${PROJECT_ROOT} to activate changes."
}

action_create_env_helper() {
  ui_info "Writing env.sh helper to: ${ENV_HELPER_PATH}"

  cat > "${ENV_HELPER_PATH}" <<'EOF'
#!/usr/bin/env bash
# Project-local environment helper
# Usage: source ./env.sh

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Dedup PATH (preserve order)
deduped_path=""
seen=""
IFS=':' read -r -a path_parts <<< "${PATH}"
for part in "${path_parts[@]}"; do
  case ":${seen}:" in
    *":${part}:"*) ;; # already seen
    *)
      seen="${seen}:${part}"
      if [[ -z "${deduped_path}" ]]; then
        deduped_path="${part}"
      else
        deduped_path="${deduped_path}:${part}"
      fi
      ;;
  esac
done

# Add project root if missing
ADDED="false"
case ":${deduped_path}:" in
  *":${PROJECT_ROOT}:"*) ;;
  *) deduped_path="${PROJECT_ROOT}:${deduped_path}"; ADDED="true" ;;
esac

export PATH="${deduped_path}"

echo "PATH updated by env.sh"
echo "  Project root added: ${PROJECT_ROOT} (${ADDED})"
echo "  PATH entries:"
echo "${PATH}" | tr ':' '\n' | sed 's/^/    - /'
EOF

  chmod +x "${ENV_HELPER_PATH}" || true
  ui_success "env.sh helper written to ${ENV_HELPER_PATH}"
  ui_info "Run 'source ./env.sh' in ${PROJECT_ROOT} to update PATH for the session (no direnv required)."
}

action_show_help_menu() {
  print_help
}

###############################################################################
# Submenu: Advanced options
###############################################################################

submenu_advanced() {
  while true; do
    ui_clear
    ui_header "direnv setup - Advanced options"
    ui_info "Type a number to run an action; any other key returns."

    echo "1) Show current PATH entries"
    echo "2) Show direnv version (if installed)"
    echo

    local choice
    read -r -p "Choose an option: " choice || return 0

    case "${choice}" in
      1)
        ui_info "Current PATH entries:"
        echo "${PATH}" | tr ':' '\n' | sed 's/^/  - /'
        ui_pause
        ;;
      2)
        if command -v direnv >/dev/null 2>&1; then
          direnv version
        else
          ui_warn "direnv is not installed."
        fi
        ui_pause
        ;;
      *)
        return 0
        ;;
    esac
  done
}

###############################################################################
# Main menu
###############################################################################

main_menu() {
  while true; do
    render_main_menu

    local choice
    read -r -p "Choose an option: " choice || break

    case "${choice}" in
      1)
        action_install_direnv
        ui_pause
        ;;
      2)
        action_create_envrc
        ui_pause
        ;;
      3)
        action_create_env_helper
        ui_pause
        ;;
      4)
        submenu_advanced
        ;;
      5)
        action_show_help_menu
        ui_pause
        ;;
      *)
        break
        ;;
    esac
  done
}

###############################################################################
# Entry point
###############################################################################

main() {
  detect_project_root

  if [[ $# -gt 0 ]]; then
    case "$1" in
      -h|--help)
        print_help
        exit 0
        ;;
      *)
        ui_error "Unknown option: $1"
        print_help
        exit 1
        ;;
    esac
  fi

  main_menu
}

main "$@"
