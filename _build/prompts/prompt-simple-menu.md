# Simple Utility Menu v1.0 — Bash Script Contract

Use this to generate a small Bash utility script with one main menu (and at most one submenu) plus a `--help` flag. Keep it lightweight for local dev utilities.

---

## File & Header

Line 1 must be:
```bash
#!/usr/bin/env bash
```

Header block (exact shape):
```bash
# =============================================================================
# {SCRIPT_NAME}.sh
# Description: {one-line what this tool does / why it exists}
# Functions:
#   - {function_or_action_1}: {short purpose}
#   - {function_or_action_2}: {short purpose}
#   - ...
# Author: Bryan Luce
# Last modified: YYYY-MM-DD
# Contract: Simple Utility Menu v1.0
# Menu Map:
#   main_menu
#     -> submenu_<name>   # optional, at most one submenu
# =============================================================================
```

Immediately after:
```bash
set -Eeuo pipefail
```

Define near the top:
```bash
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
```

---

## Error Handling

Use a simple trap:
```bash
on_error() {
  local exit_code=$?
  local line=${BASH_LINENO[0]:-unknown}
  printf 'ERROR: %s failed at line %s (exit=%s)\n' "${SCRIPT_NAME}" "${line}" "${exit_code}" >&2
  exit "${exit_code}"
}

cleanup() { :; }

trap cleanup EXIT
trap on_error ERR
```

---

## Flags & CLI Surface

Only `--help` / `-h` is supported.
- No args → launch main menu.
- `--help`/`-h` → print help, exit 0.
- Any other arg → print “Unknown option: …”, show help, exit non-zero.

Help function:
```bash
print_help() {
  cat <<EOF
${SCRIPT_NAME} - {short description}

Usage:
  ${SCRIPT_NAME} [--help]

Description:
  {1–3 short lines on what the tool does.}

Features:
  - {feature 1}
  - {feature 2}
  - {feature 3}

Menu options:
  1) {menu label 1}
  2) {menu label 2}
  3) {menu label 3}

EOF
}
```

Parse args at the start of `main` before entering menus.

---

## UI & Style Helpers

```bash
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

ui_info()    { printf '%s%s%s\n' "${_BOLD}" "$*" "${_NORM}"; }
ui_warn()    { printf '%s[WARN]%s %s\n' "${_FG_YELLOW}" "${_NORM}" "$*" >&2; }
ui_error()   { printf '%s[ERROR]%s %s\n' "${_FG_RED}" "${_NORM}" "$*" >&2; }
ui_success() { printf '%s[OK]%s %s\n' "${_FG_GREEN}" "${_NORM}" "$*"; }

ui_pause() {
  printf '\nPress Enter to continue…'
  local _dummy
  read -r _dummy || true
}
```

---

## Menu Structure & Behavior

Required menu functions:
- `main_menu` (top-level)
- Optional: `submenu_<name>` (only one submenu allowed).

Rules:
- Numeric options only.
- No explicit Back/Quit items.
- After any action, call `ui_pause` before re-rendering.

Top-level pattern:
```bash
ui_info "Type a number to run an action; any other key exits."
read -r -p "Choose an option: " choice || break
case "${choice}" in
  1) action_one; ui_pause ;;
  2) action_two; ui_pause ;;
  3) submenu_advanced ;;
  4) print_help; ui_pause ;;
  *) break ;;
esac
```

Submenu pattern:
```bash
ui_info "Type a number to run an action; any other key returns."
read -r -p "Choose an option: " choice || return 0
case "${choice}" in
  1) action_x; ui_pause ;;
  2) action_y; ui_pause ;;
  *) return 0 ;;
esac
```

Main menu rendering:
- `ui_clear`
- `ui_header "Title"`
- Show instruction line
- List numbered options
- Prompt + case block as above

Submenu: similar but returns on any other key.

---

## Function Naming

- Actions invoked from menu: `action_*`
- Menus: `main_menu`, `submenu_<name>`
- Helpers: `ui_*`, `print_help`, `on_error`, `cleanup`, etc.

Rule: if it’s directly invoked from a menu option, name it `action_*`.

---

## Entry Point

At bottom:
```bash
main() {
  if [[ $# -gt 0 ]]; then
    case "$1" in
      -h|--help) print_help; exit 0 ;;
      *) ui_error "Unknown option: $1"; print_help; exit 1 ;;
    esac
  fi
  main_menu
}

main "$@"
```

---

## Output Requirements

- Produce one Bash code block containing the entire script.
- No extra commentary.
- Keep it ShellCheck-friendly; Bash features are allowed.

---

## USER TASK

Implement `{SCRIPT_NAME}.sh` using this contract. Use the header block, helpers, and menu contract exactly as described. No additional flags beyond `--help`. Only one optional submenu. After each action, pause before re-rendering.
